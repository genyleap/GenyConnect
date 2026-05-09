module;
#include <QAbstractItemModel>
#include <QClipboard>
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QHostAddress>
#include <QHostInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QNetworkProxy>
#include <QPointer>
#include <QProcess>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QSet>
#include <QStandardPaths>
#include <QThread>
#include <QTimer>
#include <QTimeZone>
#include <QTcpServer>
#include <QTcpSocket>
#include <QUuid>
#include <QUrlQuery>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrentRun>

#include <algorithm>
#include <cstring>

#if defined(Q_OS_WIN)
extern "C" {
#include <windows.h>
#include <psapi.h>
#include <shellapi.h>
}
#if defined(_MSC_VER)
#pragma comment(lib, "psapi.lib")
#endif
#endif
#if defined(Q_OS_MACOS)
#include <unistd.h>
#include <signal.h>
#include <mach/mach.h>
#endif
#if defined(Q_OS_LINUX)
#include <unistd.h>
#include <signal.h>
#endif

module genyconnect.backend.vpncontroller;

using namespace Qt::StringLiterals;

import genyconnect.backend.linkparser;

namespace {
constexpr int kMaxLogLines = 200;
constexpr int kSpeedTestTickIntervalMs = 120;
constexpr int kSpeedTestPingSamples = 4;
constexpr int kSpeedTestMaxAttemptsPerPhase = 12;
constexpr int kSpeedTestHistoryMaxItems = 20;
constexpr qint64 kSpeedTestUploadPayloadBytes = 8 * 1024 * 1024;
constexpr int kProfilePingTimeoutMs = 3200;
constexpr int kProfilePingStaggerMs = 140;
constexpr int kSubscriptionFetchTimeoutMs = 15000;
constexpr const char kDefaultProfileGroup[] = "General";
constexpr int kProxySelfCheckMaxAttempts = 4;
constexpr int kProxySelfCheckRetryDelayMs = 700;
constexpr int kMaxPrivilegedTunLogLinesPerTick = 64;
constexpr int kMaxPrivilegedTunLogBufferBytes = 512 * 1024;
constexpr int kPrivilegedTunLogBufferKeepBytes = 256 * 1024;
constexpr int kProfileUsageSaveDelayMs = 2500;
constexpr int kPublicIpTimeoutMs = 6500;
constexpr const char kPublicIpEndpoint[] = "https://api.ipify.org?format=text";

struct ProxyApplyResult {
    bool enable = false;
    bool ok = false;
    QString error;
};

QString usageHourBucketKey(const QDateTime& timestamp)
{
    return timestamp.toString(u"yyyy-MM-dd HH"_s);
}

QString usageDayBucketKey(const QDateTime& timestamp)
{
    return timestamp.date().toString(u"yyyy-MM-dd"_s);
}

QString usageWeekBucketKey(const QDateTime& timestamp)
{
    int isoYear = timestamp.date().year();
    const int isoWeek = timestamp.date().weekNumber(&isoYear);
    return u"%1-W%2"_s.arg(isoYear).arg(isoWeek, 2, 10, QChar('0'));
}

QString usageMonthBucketKey(const QDateTime& timestamp)
{
    return timestamp.date().toString(u"yyyy-MM"_s);
}

void addUsageToBucket(QJsonObject *profileUsageObject,
                      const QString& bucketName,
                      const QString& bucketKey,
                      qint64 rxBytes,
                      qint64 txBytes)
{
    if (profileUsageObject == nullptr || bucketName.trimmed().isEmpty() || bucketKey.trimmed().isEmpty()) {
        return;
    }

    QJsonObject buckets = profileUsageObject->value(bucketName).toObject();
    QJsonObject entry = buckets.value(bucketKey).toObject();
    const qint64 previousRx = entry.value(u"rx"_s).toVariant().toLongLong();
    const qint64 previousTx = entry.value(u"tx"_s).toVariant().toLongLong();
    entry.insert(u"rx"_s, previousRx + qMax<qint64>(0, rxBytes));
    entry.insert(u"tx"_s, previousTx + qMax<qint64>(0, txBytes));
    buckets.insert(bucketKey, entry);
    profileUsageObject->insert(bucketName, buckets);
}

QByteArray decodeFlexibleBase64(const QByteArray& rawInput)
{
    QByteArray raw = rawInput.trimmed();
    raw.replace('-', '+');
    raw.replace('_', '/');
    const int padding = raw.size() % 4;
    if (padding > 0) {
        raw.append(QByteArray(4 - padding, '='));
    }

    QByteArray decoded = QByteArray::fromBase64(raw, QByteArray::AbortOnBase64DecodingErrors);
    if (!decoded.isEmpty()) {
        return decoded;
    }

    return QByteArray::fromBase64(rawInput.trimmed(), QByteArray::AbortOnBase64DecodingErrors);
}

QStringList extractShareLinks(const QString& text)
{
    QStringList links;
    const QString normalized = text;
    const QStringList lines = normalized.split(QRegularExpression(u"[\\r\\n]+"_s), Qt::SkipEmptyParts);
    for (QString line : lines) {
        line = line.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QStringList tokens = line.split(QRegularExpression(u"[\\s,]+"_s), Qt::SkipEmptyParts);
        for (const QString& token : tokens) {
            const QString candidate = token.trimmed();
            if (candidate.startsWith(u"vmess://"_s, Qt::CaseInsensitive)
                || candidate.startsWith(u"vless://"_s, Qt::CaseInsensitive)) {
                links.append(candidate);
            }
        }
    }
    links.removeDuplicates();
    return links;
}

QStringList extractSubscriptionLinks(const QByteArray& payload)
{
    const QString plain = QString::fromUtf8(payload).trimmed();
    QStringList links = extractShareLinks(plain);
    if (!links.isEmpty()) {
        return links;
    }

    const QByteArray decoded = decodeFlexibleBase64(payload);
    if (decoded.isEmpty()) {
        return {};
    }
    return extractShareLinks(QString::fromUtf8(decoded));
}

QString createSubscriptionId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString normalizeGroupNameValue(const QString& rawGroupName)
{
    const QString trimmed = rawGroupName.trimmed();
    if (trimmed.isEmpty()) {
        return QString::fromLatin1(kDefaultProfileGroup);
    }

    if (trimmed.compare(u"all"_s, Qt::CaseInsensitive) == 0) {
        return QString::fromLatin1(kDefaultProfileGroup);
    }

    return trimmed;
}

QString deriveSubscriptionNameFromUrl(const QString& rawUrl)
{
    const QUrl url(rawUrl.trimmed());
    QString host = url.host().trimmed();
    if (host.startsWith(u"www."_s, Qt::CaseInsensitive)) {
        host = host.mid(4);
    }
    if (!host.isEmpty()) {
        return host;
    }

    const QString path = url.path().trimmed();
    if (!path.isEmpty() && path != u"/"_s) {
        return path;
    }

    return u"Subscription"_s;
}

QString normalizeSubscriptionNameValue(const QString& rawName, const QString& fallbackUrl)
{
    const QString trimmed = rawName.trimmed();
    return trimmed.isEmpty() ? deriveSubscriptionNameFromUrl(fallbackUrl) : trimmed;
}

bool isNoisyTrafficLine(const QString& line)
{
    if (!line.contains(u" accepted "_s)) {
        return false;
    }
    // Drop high-frequency link-local broadcast noise in TUN mode
    // (for example: udp:* -> 169.254.255.255:137 [tun-in -> direct]),
    // which can flood logs and stall UI updates.
    if (line.contains(u"[tun-in -> direct]"_s)
        && (line.contains(u"udp:169.254.255.255:137"_s)
            || line.contains(u"udp:255.255.255.255:137"_s)
            || line.contains(u"udp:169.254.255.255:138"_s)
            || line.contains(u"udp:255.255.255.255:138"_s)
            || line.contains(u"from tcp:169.254."_s)
            || line.contains(u"from udp:169.254."_s)
            || line.contains(u"udp:224."_s))) {
        return true;
    }
    // Keep tun-in traffic visible for diagnostics; suppress only noisy local-proxy chatter.
    if (line.contains(u"[tun-in ->"_s)) {
        return false;
    }
    return line.contains(u">> proxy"_s)
           || line.contains(u"socks ->"_s)
           || line.contains(u"mixed-in ->"_s);
}

bool ruleHasInboundTag(const QJsonObject& rule, const QString& inboundTag)
{
    const QJsonArray tags = rule.value(u"inboundTag"_s).toArray();
    for (const QJsonValue& value : tags) {
        if (value.toString().compare(inboundTag, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

bool ruleHasIp(const QJsonObject& rule, const QString& ipCidr)
{
    const QJsonArray ips = rule.value(u"ip"_s).toArray();
    for (const QJsonValue& value : ips) {
        if (value.toString().compare(ipCidr, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

void ensureTunNoiseBlockRules(QJsonObject* config)
{
    if (config == nullptr) {
        return;
    }

    QJsonObject routing = config->value(u"routing"_s).toObject();
    QJsonArray rules = routing.value(u"rules"_s).toArray();
    if (rules.isEmpty()) {
        return;
    }

    bool hasUdpPortNoiseBlock = false;
    bool hasLinkLocalNoiseBlock = false;
    bool directPrivateRuleScoped = false;
    for (int i = 0; i < rules.size(); ++i) {
        QJsonObject rule = rules.at(i).toObject();
        if (rule.value(u"outboundTag"_s).toString() != u"direct"_s) {
            continue;
        }
        const QJsonArray ips = rule.value(u"ip"_s).toArray();
        bool looksLikePrivateDirect = false;
        for (const QJsonValue& ip : ips) {
            const QString cidr = ip.toString();
            if (cidr == u"10.0.0.0/8"_s
                || cidr == u"100.64.0.0/10"_s
                || cidr == u"127.0.0.0/8"_s
                || cidr == u"169.254.0.0/16"_s
                || cidr == u"172.16.0.0/12"_s
                || cidr == u"192.168.0.0/16"_s) {
                looksLikePrivateDirect = true;
                break;
            }
        }
        if (!looksLikePrivateDirect) {
            continue;
        }

        const QJsonArray inboundTags = rule.value(u"inboundTag"_s).toArray();
        bool onlyMixedIn = (inboundTags.size() == 1
                            && inboundTags.first().toString().compare(u"mixed-in"_s, Qt::CaseInsensitive) == 0);
        if (!onlyMixedIn) {
            rule.insert(u"inboundTag"_s, QJsonArray {u"mixed-in"_s});
            rules[i] = rule;
        }
        directPrivateRuleScoped = true;
    }
    for (const QJsonValue& value : rules) {
        const QJsonObject rule = value.toObject();
        if (rule.value(u"outboundTag"_s).toString() != u"block"_s) {
            continue;
        }
        if (!ruleHasInboundTag(rule, u"tun-in"_s)) {
            continue;
        }
        if (rule.value(u"network"_s).toString() == u"udp"_s
            && rule.value(u"port"_s).toString().contains(u"137"_s)) {
            hasUdpPortNoiseBlock = true;
        }
        if (rule.value(u"network"_s).toString() == u"udp"_s
            && (ruleHasIp(rule, u"169.254.0.0/16"_s)
                || ruleHasIp(rule, u"255.255.255.255/32"_s)
                || ruleHasIp(rule, u"224.0.0.0/4"_s))) {
            hasLinkLocalNoiseBlock = true;
        }
    }

    QJsonArray prefix;
    if (!hasUdpPortNoiseBlock) {
        prefix.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"udp"_s},
            {u"port"_s, u"137,138,5353,5355"_s},
            {u"outboundTag"_s, u"block"_s}
        });
    }
    if (!hasLinkLocalNoiseBlock) {
        prefix.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"udp"_s},
            {u"ip"_s, QJsonArray {
                u"169.254.0.0/16"_s,
                u"255.255.255.255/32"_s,
                u"224.0.0.0/4"_s
            }},
            {u"outboundTag"_s, u"block"_s}
        });
    }

    if (!prefix.isEmpty()) {
        for (const QJsonValue& value : rules) {
            prefix.append(value);
        }
        routing.insert(u"rules"_s, prefix);
        config->insert(u"routing"_s, routing);
        return;
    }

    if (directPrivateRuleScoped) {
        routing.insert(u"rules"_s, rules);
        config->insert(u"routing"_s, routing);
    }
}

bool hasRulePort53ToDnsOutForTun(const QJsonObject& rule)
{
    if (rule.value(u"outboundTag"_s).toString() != u"dns-out"_s) {
        return false;
    }
    if (!ruleHasInboundTag(rule, u"tun-in"_s)) {
        return false;
    }
    const QString port = rule.value(u"port"_s).toString();
    return port.contains(u"53"_s);
}

void ensureTunDnsSupport(QJsonObject* config, const QStringList& dnsServers)
{
    if (config == nullptr) {
        return;
    }

    QJsonArray outbounds = config->value(u"outbounds"_s).toArray();
    bool hasDnsOut = false;
    for (const QJsonValue& value : outbounds) {
        const QJsonObject outbound = value.toObject();
        if (outbound.value(u"tag"_s).toString() == u"dns-out"_s
            && outbound.value(u"protocol"_s).toString() == u"dns"_s) {
            hasDnsOut = true;
            break;
        }
    }
    if (!hasDnsOut) {
        outbounds.append(QJsonObject {
            {u"tag"_s, u"dns-out"_s},
            {u"protocol"_s, u"dns"_s},
            {u"settings"_s, QJsonObject {}}
        });
        config->insert(u"outbounds"_s, outbounds);
    }

    QJsonObject dns = config->value(u"dns"_s).toObject();
    QJsonArray serverArray;
    for (const QString& server : dnsServers) {
        const QString trimmed = server.trimmed();
        if (!trimmed.isEmpty()) {
            serverArray.append(trimmed);
        }
    }
    if (serverArray.isEmpty()) {
        serverArray = QJsonArray {
            u"1.1.1.1"_s,
            u"8.8.8.8"_s,
            u"9.9.9.9"_s
        };
    }
    dns.insert(u"servers"_s, serverArray);
    const QString queryStrategy = dns.value(u"queryStrategy"_s).toString().trimmed();
    if (queryStrategy.isEmpty()
        || queryStrategy.compare(u"UseIPv4"_s, Qt::CaseInsensitive) == 0) {
        dns.insert(u"queryStrategy"_s, u"UseIP"_s);
    }
    config->insert(u"dns"_s, dns);

    QJsonObject routing = config->value(u"routing"_s).toObject();
    QJsonArray rules = routing.value(u"rules"_s).toArray();
    bool hasTunDnsRule = false;
    for (const QJsonValue& value : rules) {
        if (hasRulePort53ToDnsOutForTun(value.toObject())) {
            hasTunDnsRule = true;
            break;
        }
    }

    if (!hasTunDnsRule) {
        QJsonArray prefixedRules;
        prefixedRules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"tcp,udp"_s},
            {u"port"_s, u"53"_s},
            {u"outboundTag"_s, u"dns-out"_s}
        });
        for (const QJsonValue& value : rules) {
            prefixedRules.append(value);
        }
        routing.insert(u"rules"_s, prefixedRules);
        config->insert(u"routing"_s, routing);
    }
}

QList<QUrl> speedTestPingUrls()
{
    return {
        QUrl(u"https://www.cloudflare.com/cdn-cgi/trace"_s),
        QUrl(u"https://www.google.com/generate_204"_s),
        QUrl(u"https://cp.cloudflare.com/generate_204"_s)
    };
}

QList<QUrl> speedTestDownloadUrls()
{
    return {
        QUrl(u"https://speed.cloudflare.com/__down?bytes=32000000"_s),
        QUrl(u"https://speed.cloudflare.com/__down?bytes=64000000"_s),
        QUrl(u"https://speed.hetzner.de/100MB.bin"_s)
    };
}

QList<QUrl> speedTestUploadUrls()
{
    return {
        QUrl(u"https://speed.cloudflare.com/__up"_s),
        QUrl(u"https://httpbin.org/post"_s)
    };
}

QUrl speedTestUrlForPhase(const QString& phase, int attempt)
{
    const int safeAttempt = qMax(0, attempt);
    if (phase == u"Ping"_s) {
        const QList<QUrl> urls = speedTestPingUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == u"Download"_s) {
        const QList<QUrl> urls = speedTestDownloadUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == u"Upload"_s) {
        const QList<QUrl> urls = speedTestUploadUrls();
        return urls.at(safeAttempt % urls.size());
    }
    return {};
}

QByteArray buildUploadPayload()
{
    QByteArray payload;
    payload.resize(kSpeedTestUploadPayloadBytes);
    payload.fill('x');
    return payload;
}

double mbpsFromBytes(qint64 bytes, qint64 elapsedMs)
{
    const qint64 safeElapsedMs = qMax<qint64>(1, elapsedMs);
    return (static_cast<double>(bytes) * 8.0 * 1000.0) / (safeElapsedMs * 1024.0 * 1024.0);
}

bool checkLocalProxyConnectivitySync(quint16 socksPort, QString *errorMessage)
{
    QTcpSocket socket;
    socket.connectToHost(QHostAddress::LocalHost, socksPort);
    if (!socket.waitForConnected(2500)) {
        if (errorMessage) {
            *errorMessage = u"Local mixed proxy port is not reachable."_s;
        }
        return false;
    }

    static const QByteArray connectRequest(
        "CONNECT 1.1.1.1:443 HTTP/1.1\r\n"
        "Host: 1.1.1.1:443\r\n"
        "Proxy-Connection: Keep-Alive\r\n\r\n"
        );

    if (socket.write(connectRequest) <= 0 || !socket.waitForBytesWritten(1500)) {
        if (errorMessage) {
            *errorMessage = u"Failed to write proxy CONNECT request."_s;
        }
        return false;
    }

    QByteArray response;
    QElapsedTimer timer;
    timer.start();

    while (!response.contains("\r\n\r\n") && timer.elapsed() < 5000) {
        const int remaining = static_cast<int>(5000 - timer.elapsed());
        if (remaining <= 0 || !socket.waitForReadyRead(remaining)) {
            break;
        }
        response.append(socket.readAll());
        if (response.size() > 4096) {
            break;
        }
    }

    const int lineEnd = response.indexOf("\r\n");
    QString firstLine;
    if (lineEnd > 0) {
        firstLine = QString::fromUtf8(response.left(lineEnd)).trimmed();
    } else {
        firstLine = QString::fromUtf8(response).trimmed();
    }

    const bool ok = firstLine.startsWith(u"HTTP/1.1 200"_s)
                    || firstLine.startsWith(u"HTTP/1.0 200"_s);

    if (!ok && errorMessage) {
        *errorMessage = firstLine.isEmpty()
        ? u"No proxy response for CONNECT test."_s
        : u"CONNECT response: %1"_s.arg(firstLine);
    }

    return ok;
}

QString quoteForShell(const QString& value)
{
    QString escaped = value;
    escaped.replace(u"'"_s, u"'\"'\"'"_s);
    return u"'"_s + escaped + u"'"_s;
}

QString joinQuotedArgsForShell(const QStringList& args)
{
    QStringList quoted;
    quoted.reserve(args.size());
    for (const QString& arg : args) {
        quoted.append(quoteForShell(arg));
    }
    return quoted.join(u" "_s);
}

QString quoteForPowerShellSingleQuoted(const QString& value)
{
    QString escaped = value;
    escaped.replace(u"'"_s, u"''"_s);
    return u"'"_s + escaped + u"'"_s;
}

QString toPowerShellArgumentArrayLiteral(const QStringList& args)
{
    QStringList parts;
    parts.reserve(args.size());
    for (const QString& arg : args) {
        parts.append(quoteForPowerShellSingleQuoted(arg));
    }
    return u"@("_s + parts.join(u","_s) + u")"_s;
}

QString escapeForAppleScriptString(const QString& value)
{
    QString out = value;
    out.replace(u"\\"_s, u"\\\\"_s);
    out.replace(u"\""_s, u"\\\""_s);
    return out;
}

bool waitForProcessFinishedResponsive(QProcess& process, int timeoutMs)
{
    QElapsedTimer timer;
    timer.start();
    while (process.state() != QProcess::NotRunning) {
        if (process.waitForFinished(40)) {
            return true;
        }
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
        if (timer.elapsed() >= timeoutMs) {
            return false;
        }
    }
    return true;
}

bool ensureExecutableFile(const QString& path, QString* errorMessage)
{
    const QString normalized = path.trimmed();
    if (normalized.isEmpty()) {
        if (errorMessage != nullptr) {
            *errorMessage = u"xray-core executable path is empty."_s;
        }
        return false;
    }

    QFileInfo info(normalized);
    if (!info.exists() || !info.isFile()) {
        if (errorMessage != nullptr) {
            *errorMessage = u"xray-core binary not found at selected path."_s;
        }
        return false;
    }

    if (info.isExecutable()) {
        return true;
    }

    QFile::Permissions permissions = QFile::permissions(normalized);
    permissions |= QFileDevice::ReadOwner | QFileDevice::ExeOwner
                   | QFileDevice::ReadGroup | QFileDevice::ExeGroup
                   | QFileDevice::ReadOther | QFileDevice::ExeOther;
    if (!QFile::setPermissions(normalized, permissions)) {
        if (errorMessage != nullptr) {
            *errorMessage = u"xray-core is not executable and permissions could not be repaired: %1"_s
                                .arg(normalized);
        }
        return false;
    }

    return QFileInfo(normalized).isExecutable();
}

quint16 selectAvailableLocalPort()
{
    for (int attempt = 0; attempt < 64; ++attempt) {
        const quint16 candidate = static_cast<quint16>(39000 + QRandomGenerator::global()->bounded(20000));
        QTcpServer probe;
        if (!probe.listen(QHostAddress::LocalHost, candidate)) {
            continue;
        }
        probe.close();
        return candidate;
    }

    QTcpServer probe;
    if (probe.listen(QHostAddress::LocalHost, 0)) {
        const quint16 fallback = probe.serverPort();
        probe.close();
        return fallback;
    }
    return 0;
}

QString selectTunInterfaceName()
{
#if defined(Q_OS_MACOS)
    QProcess process;
    process.start(u"/sbin/ifconfig"_s, {u"-l"_s});
    if (!process.waitForStarted(1000)) {
        return u"utun9"_s;
    }
    if (!process.waitForFinished(1500)) {
        process.kill();
        process.waitForFinished(200);
        return u"utun9"_s;
    }
    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    static const QRegularExpression re(u"\\butun(\\d+)\\b"_s);
    QSet<int> used;
    QRegularExpressionMatchIterator it = re.globalMatch(output);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        used.insert(m.captured(1).toInt());
    }
    for (int n = 10; n <= 64; ++n) {
        if (!used.contains(n)) {
            return u"utun%1"_s.arg(n);
        }
    }
    return u"utun9"_s;
#else
    return {};
#endif
}

bool ensureWindowsTunRuntimeReady(const QString& xrayExecutablePath,
                                  const QString& dataDirectory,
                                  QString *copiedFrom,
                                  QString *errorMessage)
{
#if defined(Q_OS_WIN)
    const QFileInfo xrayInfo(xrayExecutablePath);
    const QString xrayDir = xrayInfo.absolutePath();
    if (xrayDir.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"Cannot resolve xray directory for TUN runtime."_s;
        }
        return false;
    }

    const QString targetDll = QDir(xrayDir).filePath(u"wintun.dll"_s);
    if (QFileInfo::exists(targetDll)) {
        return true;
    }

    QStringList candidates;
    candidates << QDir(QCoreApplication::applicationDirPath()).filePath(u"wintun.dll"_s);
    candidates << QDir(dataDirectory).filePath(u"wintun.dll"_s);

    for (const QString& candidate : std::as_const(candidates)) {
        if (!QFileInfo::exists(candidate)) {
            continue;
        }
        QFile::remove(targetDll);
        if (QFile::copy(candidate, targetDll)) {
            if (copiedFrom) {
                *copiedFrom = candidate;
            }
            return true;
        }
    }

    if (errorMessage) {
        *errorMessage = u"Windows TUN dependency missing: wintun.dll was not found beside xray-core.exe."_s;
    }
    return false;
#else
    Q_UNUSED(xrayExecutablePath)
    Q_UNUSED(dataDirectory)
    Q_UNUSED(copiedFrom)
    Q_UNUSED(errorMessage)
    return true;
#endif
}

bool queryTrafficStatsFromApiSync(
    const QString& executablePath,
    quint16 apiPort,
    qint64 *uplinkBytes,
    qint64 *downlinkBytes,
    QString *errorMessage)
{
    if (uplinkBytes == nullptr || downlinkBytes == nullptr) {
        return false;
    }

    if (executablePath.trimmed().isEmpty()) {
        return false;
    }

    QProcess process;
    process.start(
        executablePath,
        {
            u"api"_s,
            u"statsquery"_s,
            u"--server=127.0.0.1:%1"_s.arg(apiPort),
            u"-pattern"_s,
            u"outbound>>>"_s
        }
        );

    if (!process.waitForStarted(1500)) {
        if (errorMessage) {
            *errorMessage = u"Failed to start xray api statsquery process."_s;
        }
        return false;
    }

    if (!process.waitForFinished(4500)) {
        process.kill();
        process.waitForFinished(500);
        if (errorMessage) {
            *errorMessage = u"xray api statsquery timed out."_s;
        }
        return false;
    }

    const QByteArray stdoutBytes = process.readAllStandardOutput();
    const QByteArray stderrBytes = process.readAllStandardError();

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        if (errorMessage) {
            const QString stderrText = QString::fromUtf8(stderrBytes).trimmed();
            *errorMessage = stderrText.isEmpty()
                                ? u"xray api statsquery failed."_s
                                : stderrText;
        }
        return false;
    }

    qint64 up = 0;
    qint64 down = 0;

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(stdoutBytes, &parseError);
    if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
        const QJsonObject root = doc.object();
        const QJsonValue statValue = root.value(u"stat"_s);
        bool foundAnyCounter = false;

        auto consumeStatObject = [&up, &down, &foundAnyCounter](const QJsonObject &statObj) {
            const QString name = statObj.value(u"name"_s).toString();
            const qint64 value = statObj.value(u"value"_s).toVariant().toLongLong();
            if (!name.startsWith(u"outbound>>>"_s)) {
                return;
            }

            const QStringList parts = name.split(u">>>"_s);
            if (parts.size() < 4) {
                return;
            }

            const QString outboundTag = parts.at(1);
            const QString direction = parts.at(3);
            if (outboundTag == u"api"_s) {
                return;
            }

            if (direction == u"uplink"_s) {
                up += value;
                foundAnyCounter = true;
            } else if (direction == u"downlink"_s) {
                down += value;
                foundAnyCounter = true;
            }
        };

        if (statValue.isObject()) {
            consumeStatObject(statValue.toObject());
        } else if (statValue.isArray()) {
            const QJsonArray statsArray = statValue.toArray();
            for (const QJsonValue &entry : statsArray) {
                if (entry.isObject()) {
                    consumeStatObject(entry.toObject());
                }
            }
        }

        if (foundAnyCounter) {
            *uplinkBytes = up;
            *downlinkBytes = down;
            return true;
        }
    }

    // Fallback parser for native xray statsquery text output:
    // stat: { name: "outbound>>>proxy>>>traffic>>>uplink" value: 12345 }
    const QString plain = QString::fromUtf8(stdoutBytes + '\n' + stderrBytes);
    static const QRegularExpression upRegex(
        u"outbound>>>([^>]+)>>>traffic>>>uplink[^0-9]*([0-9]+)"_s,
        QRegularExpression::CaseInsensitiveOption
        );
    static const QRegularExpression downRegex(
        u"outbound>>>([^>]+)>>>traffic>>>downlink[^0-9]*([0-9]+)"_s,
        QRegularExpression::CaseInsensitiveOption
        );

    bool foundAnyCounter = false;

    QRegularExpressionMatchIterator upIt = upRegex.globalMatch(plain);
    while (upIt.hasNext()) {
        const QRegularExpressionMatch match = upIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == u"api"_s) {
            continue;
        }
        up += match.captured(2).toLongLong();
        foundAnyCounter = true;
    }

    QRegularExpressionMatchIterator downIt = downRegex.globalMatch(plain);
    while (downIt.hasNext()) {
        const QRegularExpressionMatch match = downIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == u"api"_s) {
            continue;
        }
        down += match.captured(2).toLongLong();
        foundAnyCounter = true;
    }

    if (foundAnyCounter) {
        *uplinkBytes = up;
        *downlinkBytes = down;
        return true;
    }

    if (errorMessage) {
        QString snippet = plain.trimmed();
        if (snippet.size() > 200) {
            snippet = snippet.left(200) + u"..."_s;
        }
        *errorMessage = snippet.isEmpty()
                            ? u"xray api statsquery returned no traffic stats."_s
                            : u"xray api statsquery parse failed: %1"_s.arg(snippet);
    }
    return false;
}

qint64 currentProcessMemoryBytes()
{
#if defined(Q_OS_WIN)
    PROCESS_MEMORY_COUNTERS_EX memInfo;
    std::memset(&memInfo, 0, sizeof(memInfo));
    memInfo.cb = sizeof(memInfo);
    if (GetProcessMemoryInfo(
            GetCurrentProcess(),
            reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&memInfo),
            static_cast<DWORD>(sizeof(memInfo)))) {
        return static_cast<qint64>(memInfo.WorkingSetSize);
    }
    return -1;
#elif defined(Q_OS_MACOS)
    mach_task_basic_info taskInfo;
    mach_msg_type_number_t taskInfoCount = MACH_TASK_BASIC_INFO_COUNT;
    const kern_return_t result = task_info(
        mach_task_self(),
        MACH_TASK_BASIC_INFO,
        reinterpret_cast<task_info_t>(&taskInfo),
        &taskInfoCount);
    if (result == KERN_SUCCESS) {
        return static_cast<qint64>(taskInfo.resident_size);
    }
    return -1;
#elif defined(Q_OS_LINUX)
    QFile statusFile(u"/proc/self/status"_s);
    if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!statusFile.atEnd()) {
            const QByteArray line = statusFile.readLine();
            if (!line.startsWith("VmRSS:")) {
                continue;
            }
            const QList<QByteArray> parts = line.simplified().split(' ');
            if (parts.size() < 2) {
                break;
            }
            bool ok = false;
            const qint64 kb = parts.at(1).toLongLong(&ok);
            if (ok && kb >= 0) {
                return kb * 1024;
            }
            break;
        }
    }
    return -1;
#else
    return -1;
#endif
}
}

VpnController::VpnController(QObject *parent)
    : QObject(parent)
{
    m_startedWithTunElevationRequest = QCoreApplication::arguments().contains(
        u"--geny-elevated-tun"_s);

    m_dataDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(m_dataDirectory);

    m_profilesPath = QDir(m_dataDirectory).filePath(u"profiles.json"_s);
    m_subscriptionsPath = QDir(m_dataDirectory).filePath(u"subscriptions.json"_s);
    m_runtimeConfigPath = QDir(m_dataDirectory).filePath(u"xray-runtime-config.json"_s);
    m_profileUsagePath = QDir(m_dataDirectory).filePath(u"profile-traffic-usage.json"_s);
    m_privilegedTunPidPath = QDir(m_dataDirectory).filePath(u"xray-tun.pid"_s);
    m_privilegedTunLogPath = QDir(m_dataDirectory).filePath(u"xray-tun.log"_s);

    m_buildOptions.socksPort = 10808;
    m_buildOptions.httpPort = 10808;
    m_buildOptions.apiPort = 10085;
    m_buildOptions.logLevel = u"warning"_s;
    m_buildOptions.enableStatsApi = true;

    m_processManager.setWorkingDirectory(m_dataDirectory);
    m_memoryUsageTimer.setInterval(1500);
    connect(&m_memoryUsageTimer, &QTimer::timeout, this, &VpnController::updateMemoryUsage);
    m_memoryUsageTimer.start();
    m_statsPollTimer.setInterval(1000);
    connect(&m_statsPollTimer, &QTimer::timeout, this, &VpnController::pollTrafficStats);
    m_privilegedTunLogTimer.setInterval(200);
    connect(&m_privilegedTunLogTimer, &QTimer::timeout, this, &VpnController::pollPrivilegedTunLogs);
    m_profileUsageSaveTimer.setSingleShot(true);
    m_profileUsageSaveTimer.setInterval(kProfileUsageSaveDelayMs);
    connect(&m_profileUsageSaveTimer, &QTimer::timeout, this, [this]() {
        saveProfileUsage();
    });
    m_logsFlushTimer.setSingleShot(true);
    m_logsFlushTimer.setInterval(120);
    connect(&m_logsFlushTimer, &QTimer::timeout, this, [this]() {
        if (!m_logsDirty) {
            return;
        }
        m_logsDirty = false;
        emit logsChanged();
    });
    m_speedTestTimer.setInterval(kSpeedTestTickIntervalMs);
    connect(&m_speedTestTimer, &QTimer::timeout, this, &VpnController::onSpeedTestTick);

    connect(&m_processManager, &XrayProcessManager::started, this, &VpnController::onProcessStarted);
    connect(&m_processManager, &XrayProcessManager::stopped, this, &VpnController::onProcessStopped);
    connect(&m_processManager, &XrayProcessManager::errorOccurred, this, &VpnController::onProcessError);
    connect(&m_processManager, &XrayProcessManager::logLine, this, &VpnController::onLogLine);
    connect(&m_processManager, &XrayProcessManager::trafficChanged, this, &VpnController::onTrafficUpdated);
    connect(&m_updater, &Updater::systemLog, this, &VpnController::appendSystemLog);
    connect(&m_profileModel, &QAbstractItemModel::rowsInserted, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(&m_profileModel, &QAbstractItemModel::rowsRemoved, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(&m_profileModel, &QAbstractItemModel::modelReset, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(&m_profileModel, &QAbstractItemModel::dataChanged, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });

    updateMemoryUsage();

    loadSettings();
    loadProfiles();
    loadSubscriptions();
    loadProfileUsage();
    refreshProfileGroups();
    m_updater.setAppVersion(QCoreApplication::applicationVersion());

    const QString bundledXrayPath = detectDefaultXrayPath();
    if (!bundledXrayPath.isEmpty()) {
        m_xrayExecutablePath = bundledXrayPath;
    } else if (m_xrayExecutablePath.isEmpty()) {
        m_xrayExecutablePath = detectDefaultXrayPath();
    }
    detectProcessRoutingSupport();

    if (m_profileModel.rowCount() == 0) {
        m_currentProfileIndex = -1;
    } else if (!m_currentProfileId.trimmed().isEmpty()) {
        const int resolvedIndex = m_profileModel.indexOfId(m_currentProfileId.trimmed());
        if (resolvedIndex >= 0) {
            m_currentProfileIndex = resolvedIndex;
        } else if (m_currentProfileIndex < 0 || m_currentProfileIndex >= m_profileModel.rowCount()) {
            m_currentProfileIndex = 0;
        }
    } else if (m_currentProfileIndex < 0 || m_currentProfileIndex >= m_profileModel.rowCount()) {
        m_currentProfileIndex = 0;
    }
    const auto startupProfile = m_profileModel.profileAt(m_currentProfileIndex);
    m_currentProfileId = startupProfile.has_value() ? startupProfile->id.trimmed() : QString();
    recomputeProfileStats();

    QTimer::singleShot(1500, this, [this]() {
        m_updater.checkForUpdates(false);
    });
    QTimer::singleShot(900, this, [this]() {
        applyKillSwitchState();
        refreshPublicIp();
    });

    connect(qApp, &QCoreApplication::aboutToQuit, this, [this]() {
        cleanupDetachedHelpers();
    });
}

VpnController::~VpnController()
{
    cancelSpeedTest();
    finishProfileUsageSession();
    if (m_publicIpReply) {
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
    }
    m_profileUsageSaveTimer.stop();
    if (m_privilegedTunManaged) {
        m_privilegedTunLogTimer.stop();
        QString stopError;
        Q_UNUSED(stopPrivilegedTunProcess(&stopError));
    }
    stopPrivilegedTunRuntimeByPidPath();
    shutdownPrivilegedTunHelper();
    if (m_processManager.isRunning()) {
        m_processManager.stop(0);
    }
    if (m_systemProxyApplied || m_killSwitchEnabled || (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect)) {
        QString ignored;
        Q_UNUSED(m_systemProxyManager.disable(&ignored, true));
        m_systemProxyApplied = false;
    }
    saveProfileUsage();
    cleanupDetachedHelpers();
}

ConnectionState VpnController::connectionState() const
{
    return m_connectionState;
}

bool VpnController::connected() const
{
    return m_connectionState == ConnectionState::Connected;
}

bool VpnController::busy() const
{
    return m_connectionState == ConnectionState::Connecting;
}

QString VpnController::lastError() const
{
    return m_lastError;
}

QString VpnController::latestLogLine() const
{
    return m_latestLogLine;
}

QStringList VpnController::recentLogs() const
{
    return m_recentLogs;
}

qint64 VpnController::rxBytes() const
{
    return m_rxBytes;
}

qint64 VpnController::txBytes() const
{
    return m_txBytes;
}

QString VpnController::publicIpAddress() const
{
    return m_publicIpAddress;
}

bool VpnController::publicIpRefreshing() const
{
    return m_publicIpRefreshing;
}

QString VpnController::memoryUsageText() const
{
    if (m_memoryUsageBytes <= 0) {
        return u"--"_s;
    }
    return formatBytes(m_memoryUsageBytes);
}

bool VpnController::speedTestRunning() const
{
    return m_speedTestRunning;
}

QString VpnController::speedTestPhase() const
{
    return m_speedTestPhase;
}

int VpnController::speedTestElapsedSec() const
{
    return m_speedTestElapsedSec;
}

int VpnController::speedTestDurationSec() const
{
    return m_speedTestDurationSec;
}

double VpnController::speedTestCurrentMbps() const
{
    return m_speedTestCurrentMbps;
}

double VpnController::speedTestPeakMbps() const
{
    return m_speedTestPeakMbps;
}

int VpnController::speedTestPingMs() const
{
    return m_speedTestPingMs;
}

double VpnController::speedTestDownloadMbps() const
{
    return m_speedTestDownloadMbps;
}

double VpnController::speedTestUploadMbps() const
{
    return m_speedTestUploadMbps;
}

QString VpnController::speedTestError() const
{
    return m_speedTestError;
}

QStringList VpnController::speedTestHistory() const
{
    return m_speedTestHistory;
}

int VpnController::currentProfileIndex() const
{
    return m_currentProfileIndex;
}

void VpnController::setCurrentProfileIndex(int index)
{
    if (index == m_currentProfileIndex) {
        return;
    }

    if (index < -1 || index >= m_profileModel.rowCount()) {
        return;
    }

    const int previousIndex = m_currentProfileIndex;
    m_currentProfileIndex = index;
    const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
    m_currentProfileId = profile.has_value() ? profile->id.trimmed() : QString();
    emit currentProfileIndexChanged();
    emit profileUsageChanged();
    saveSettings();

    if (m_currentProfileIndex < 0) {
        m_pendingReconnectProfileIndex = -1;
        m_activeProfileUsageId.clear();
        resetPerProfileUsageSamples();
        return;
    }

    const bool runtimeActive = m_processManager.isRunning() || m_privilegedTunManaged;
    if (!busy()
        && previousIndex >= 0
        && previousIndex != m_currentProfileIndex
        && (connected() || runtimeActive)) {
        m_pendingReconnectProfileIndex = m_currentProfileIndex;
        appendSystemLog(u"[System] Switching to selected profile..."_s);
        disconnect();
    }
}

QObject *VpnController::profileModel()
{
    return &m_profileModel;
}

QObject *VpnController::updater()
{
    return &m_updater;
}

QString VpnController::xrayExecutablePath() const
{
    return m_xrayExecutablePath;
}

QString VpnController::xrayVersion() const
{
    return m_xrayVersion;
}

bool VpnController::loggingEnabled() const
{
    return m_loggingEnabled;
}

bool VpnController::autoPingProfiles() const
{
    return m_autoPingProfiles;
}

QStringList VpnController::subscriptions() const
{
    QStringList urls;
    urls.reserve(m_subscriptionEntries.size());
    for (const SubscriptionEntry& entry : m_subscriptionEntries) {
        urls.append(entry.url);
    }
    return urls;
}

QVariantList VpnController::subscriptionItems() const
{
    QVariantList out;
    out.reserve(m_subscriptionEntries.size());
    for (const SubscriptionEntry& entry : m_subscriptionEntries) {
        int profileCounter = 0;
        const auto allProfiles = m_profileModel.profiles();
        for (const ServerProfile& profile : allProfiles) {
            if (profile.sourceId.trimmed() == entry.id) {
                ++profileCounter;
            }
        }

        QVariantMap item;
        item.insert(u"id"_s, entry.id);
        item.insert(u"name"_s, entry.name);
        item.insert(u"group"_s, entry.group);
        item.insert(u"url"_s, entry.url);
        item.insert(u"profileCount"_s, profileCounter);
        out.append(item);
    }
    return out;
}

bool VpnController::subscriptionBusy() const
{
    return m_subscriptionBusy;
}

QString VpnController::subscriptionMessage() const
{
    return m_subscriptionMessage;
}

QStringList VpnController::profileGroups() const
{
    return m_profileGroups;
}

QVariantList VpnController::profileGroupItems() const
{
    QVariantList items;
    items.reserve(m_profileGroups.size());
    QSet<QString> seenKeys;
    for (const QString& groupName : m_profileGroups) {
        const ProfileGroupOptions options = profileGroupOptionsFor(groupName);
        if (seenKeys.contains(options.key)) {
            continue;
        }
        seenKeys.insert(options.key);
        QVariantMap item;
        item.insert(u"name"_s, options.name);
        item.insert(u"enabled"_s, options.enabled);
        item.insert(u"exclusive"_s, options.exclusive);
        item.insert(u"badge"_s, options.badge);
        items.append(item);
    }
    return items;
}

QString VpnController::currentProfileGroup() const
{
    return m_currentProfileGroup;
}

int VpnController::profileCount() const
{
    return m_profileCount;
}

int VpnController::filteredProfileCount() const
{
    return m_filteredProfileCount;
}

int VpnController::bestPingMs() const
{
    return m_bestPingMs;
}

int VpnController::worstPingMs() const
{
    return m_worstPingMs;
}

double VpnController::profileScore() const
{
    return m_profileScore;
}

bool VpnController::isProfileGroupEnabled(const QString& groupName) const
{
    return profileGroupOptionsFor(groupName).enabled;
}

bool VpnController::isProfileGroupExclusive(const QString& groupName) const
{
    return profileGroupOptionsFor(groupName).exclusive;
}

QString VpnController::profileGroupBadge(const QString& groupName) const
{
    return profileGroupOptionsFor(groupName).badge;
}

void VpnController::setProfileGroupEnabled(const QString& groupName, bool enabled)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        return;
    }

    ProfileGroupOptions options = profileGroupOptionsFor(normalized);
    if (options.enabled == enabled) {
        return;
    }
    options.enabled = enabled;
    if (!enabled && options.exclusive) {
        options.exclusive = false;
    }
    upsertProfileGroupOptions(options);

    if (!enabled && m_currentProfileGroup.compare(normalized, Qt::CaseInsensitive) == 0) {
        m_currentProfileGroup = u"All"_s;
        emit currentProfileGroupChanged();
    }

    recomputeProfileStats();
}

void VpnController::setProfileGroupExclusive(const QString& groupName, bool exclusive)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        return;
    }

    ProfileGroupOptions options = profileGroupOptionsFor(normalized);
    if (options.exclusive == exclusive) {
        return;
    }

    options.exclusive = exclusive;
    if (exclusive) {
        options.enabled = true;
    }

    bool changed = false;
    if (exclusive) {
        for (int i = 0; i < m_profileGroupOptions.size(); ++i) {
            ProfileGroupOptions& current = m_profileGroupOptions[i];
            if (current.key != options.key && current.exclusive) {
                current.exclusive = false;
                changed = true;
            }
        }
    }

    const int idx = profileGroupOptionsIndex(options.name);
    if (idx >= 0) {
        if (m_profileGroupOptions[idx].name != options.name
            || m_profileGroupOptions[idx].enabled != options.enabled
            || m_profileGroupOptions[idx].exclusive != options.exclusive
            || m_profileGroupOptions[idx].badge != options.badge) {
            m_profileGroupOptions[idx] = options;
            changed = true;
        }
    } else {
        m_profileGroupOptions.append(options);
        changed = true;
    }

    if (!changed) {
        return;
    }

    emit profileGroupOptionsChanged();
    saveSettings();
    recomputeProfileStats();
}

void VpnController::setProfileGroupBadge(const QString& groupName, const QString& badge)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        return;
    }

    ProfileGroupOptions options = profileGroupOptionsFor(normalized);
    const QString normalizedBadge = badge.trimmed();
    if (options.badge == normalizedBadge) {
        return;
    }
    options.badge = normalizedBadge;
    upsertProfileGroupOptions(options);
}

bool VpnController::ensureProfileGroup(const QString& groupName)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        return false;
    }

    const int existingIndex = profileGroupOptionsIndex(normalized);
    if (existingIndex >= 0) {
        if (m_profileGroups.contains(normalized, Qt::CaseInsensitive)) {
            return true;
        }
        refreshProfileGroups();
        return true;
    }

    ProfileGroupOptions options;
    options.name = normalized;
    options.key = normalizeGroupKey(normalized);
    options.enabled = true;
    options.exclusive = false;
    options.badge.clear();
    upsertProfileGroupOptions(options, false);

    refreshProfileGroups();
    saveSettings();
    appendSystemLog(u"[Group] Added group '%1'."_s.arg(normalized));
    return true;
}

bool VpnController::removeProfileGroup(const QString& groupName)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) == 0
        || normalized.compare(u"General"_s, Qt::CaseInsensitive) == 0) {
        return false;
    }

    bool changed = false;

    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        if (normalizeGroupName(entry.group).compare(normalized, Qt::CaseInsensitive) == 0) {
            entry.group = u"General"_s;
            changed = true;
        }
    }

    auto profiles = m_profileModel.profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        if (normalizeGroupName(profile.groupName).compare(normalized, Qt::CaseInsensitive) == 0) {
            profile.groupName = u"General"_s;
            profilesChanged = true;
            changed = true;
        }
    }

    for (int i = m_profileGroupOptions.size() - 1; i >= 0; --i) {
        if (m_profileGroupOptions.at(i).key == normalizeGroupKey(normalized)) {
            m_profileGroupOptions.removeAt(i);
            changed = true;
        }
    }

    if (!changed) {
        return false;
    }

    if (profilesChanged) {
        m_profileModel.setProfiles(profiles);
        saveProfiles();
    }
    saveSubscriptions();
    emit subscriptionsChanged();
    refreshProfileGroups();
    recomputeProfileStats();
    saveSettings();
    appendSystemLog(u"[Group] Removed group '%1' and moved profiles/subscriptions to General."_s
                        .arg(normalized));
    return true;
}

int VpnController::removeAllProfileGroups()
{
    int removedGroups = 0;
    for (const QString& name : m_profileGroups) {
        if (name.compare(u"All"_s, Qt::CaseInsensitive) == 0
            || name.compare(u"General"_s, Qt::CaseInsensitive) == 0) {
            continue;
        }
        ++removedGroups;
    }

    bool changed = false;
    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        const QString normalized = normalizeGroupName(entry.group);
        if (normalized.compare(u"General"_s, Qt::CaseInsensitive) != 0) {
            entry.group = u"General"_s;
            changed = true;
        }
    }

    auto profiles = m_profileModel.profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        const QString normalized = normalizeGroupName(profile.groupName);
        if (normalized.compare(u"General"_s, Qt::CaseInsensitive) != 0) {
            profile.groupName = u"General"_s;
            profilesChanged = true;
            changed = true;
        }
    }

    if (!m_profileGroupOptions.isEmpty()) {
        m_profileGroupOptions.clear();
        changed = true;
    }

    if (!changed) {
        return 0;
    }

    if (profilesChanged) {
        m_profileModel.setProfiles(profiles);
        saveProfiles();
    }
    saveSubscriptions();
    emit subscriptionsChanged();
    refreshProfileGroups();
    recomputeProfileStats();
    saveSettings();
    appendSystemLog(u"[Group] Cleared all custom groups. Everything moved to General."_s);
    return removedGroups;
}

void VpnController::setXrayExecutablePath(const QString& path)
{
    const QString normalized = path.trimmed();
    if (normalized == m_xrayExecutablePath) {
        return;
    }

    const bool hadSupport = m_processRoutingSupported;
    m_xrayExecutablePath = normalized;
    m_processRoutingSupportChecked = false;
    m_processRoutingSupported = false;
    emit xrayExecutablePathChanged();
    if (hadSupport) {
        emit processRoutingSupportChanged();
    }
    saveSettings();
    detectProcessRoutingSupport();
}

void VpnController::setLoggingEnabled(bool enabled)
{
    if (m_loggingEnabled == enabled) {
        return;
    }

    m_loggingEnabled = enabled;
    if (!m_loggingEnabled) {
        clearLogsInternal();
    }
    emit loggingEnabledChanged();
    saveSettings();
}

void VpnController::setAutoPingProfiles(bool enabled)
{
    if (m_autoPingProfiles == enabled) {
        return;
    }

    m_autoPingProfiles = enabled;
    emit autoPingProfilesChanged();
    saveSettings();

    if (m_autoPingProfiles) {
        pingAllProfiles();
    }
}

void VpnController::setCurrentProfileGroup(const QString& groupName)
{
    QString normalized = groupName.trimmed();
    if (normalized.isEmpty()) {
        normalized = u"All"_s;
    }
    if (normalized.compare(u"all"_s, Qt::CaseInsensitive) == 0) {
        normalized = u"All"_s;
    }

    if (normalized.compare(u"All"_s, Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalized)) {
        normalized = u"All"_s;
    }

    if (m_currentProfileGroup == normalized) {
        return;
    }

    m_currentProfileGroup = normalized;
    emit currentProfileGroupChanged();
    recomputeProfileStats();
    saveSettings();
}

bool VpnController::useSystemProxy() const
{
    return m_useSystemProxy;
}

bool VpnController::tunMode() const
{
    return m_tunMode;
}

bool VpnController::killSwitchEnabled() const
{
    return m_killSwitchEnabled;
}

void VpnController::setUseSystemProxy(bool enabled)
{
    if (m_useSystemProxy == enabled) {
        return;
    }

    m_useSystemProxy = enabled;
    emit useSystemProxyChanged();
    saveSettings();
    QSettings settings;
    settings.setValue(u"network/modeExplicitlyChosen"_s, true);

    if (m_connectionState == ConnectionState::Connected) {
        applySystemProxy(enabled, !enabled);
    }
}

void VpnController::setTunMode(bool enabled)
{
    if (m_tunMode == enabled) {
        return;
    }

    m_tunMode = enabled;
    emit tunModeChanged();

    if (m_tunMode && m_useSystemProxy) {
        m_useSystemProxy = false;
        emit useSystemProxyChanged();
    }

    saveSettings();
    QSettings settings;
    settings.setValue(u"network/modeExplicitlyChosen"_s, true);
}

void VpnController::setKillSwitchEnabled(bool enabled)
{
    if (m_killSwitchEnabled == enabled) {
        return;
    }

    m_killSwitchEnabled = enabled;
    emit killSwitchEnabledChanged();
    saveSettings();
    applyKillSwitchState(enabled
                             ? u"Kill Switch enabled."_s
                             : u"Kill Switch disabled."_s);
}

bool VpnController::autoDisableSystemProxyOnDisconnect() const
{
    return m_autoDisableSystemProxyOnDisconnect;
}

void VpnController::setAutoDisableSystemProxyOnDisconnect(bool enabled)
{
    if (m_autoDisableSystemProxyOnDisconnect == enabled) {
        return;
    }

    m_autoDisableSystemProxyOnDisconnect = enabled;
    emit autoDisableSystemProxyOnDisconnectChanged();
    saveSettings();
}

bool VpnController::whitelistMode() const
{
    return m_whitelistMode;
}

void VpnController::setWhitelistMode(bool enabled)
{
    if (m_whitelistMode == enabled) {
        return;
    }

    m_whitelistMode = enabled;
    emit whitelistModeChanged();
    saveSettings();
}

QString VpnController::proxyDomainRules() const
{
    return m_proxyDomainRules;
}

void VpnController::setProxyDomainRules(const QString& value)
{
    if (m_proxyDomainRules == value) {
        return;
    }

    m_proxyDomainRules = value;
    emit routingRulesChanged();
    saveSettings();
}

QString VpnController::directDomainRules() const
{
    return m_directDomainRules;
}

void VpnController::setDirectDomainRules(const QString& value)
{
    if (m_directDomainRules == value) {
        return;
    }

    m_directDomainRules = value;
    emit routingRulesChanged();
    saveSettings();
}

QString VpnController::blockDomainRules() const
{
    return m_blockDomainRules;
}

QString VpnController::customDnsServers() const
{
    return m_customDnsServers;
}

void VpnController::setBlockDomainRules(const QString& value)
{
    if (m_blockDomainRules == value) {
        return;
    }

    m_blockDomainRules = value;
    emit routingRulesChanged();
    saveSettings();
}

void VpnController::setCustomDnsServers(const QString& value)
{
    const QString normalized = parseDnsServers(value).join('\n');
    if (m_customDnsServers == normalized) {
        return;
    }

    m_customDnsServers = normalized;
    emit customDnsServersChanged();
    saveSettings();
}

QString VpnController::proxyAppRules() const
{
    return m_proxyAppRules;
}

void VpnController::setProxyAppRules(const QString& value)
{
    if (m_proxyAppRules == value) {
        return;
    }

    m_proxyAppRules = value;
    emit appRulesChanged();
    saveSettings();
}

QString VpnController::directAppRules() const
{
    return m_directAppRules;
}

void VpnController::setDirectAppRules(const QString& value)
{
    if (m_directAppRules == value) {
        return;
    }

    m_directAppRules = value;
    emit appRulesChanged();
    saveSettings();
}

QString VpnController::blockAppRules() const
{
    return m_blockAppRules;
}

void VpnController::setBlockAppRules(const QString& value)
{
    if (m_blockAppRules == value) {
        return;
    }

    m_blockAppRules = value;
    emit appRulesChanged();
    saveSettings();
}

QString VpnController::currentProfileUsageHour() const
{
    return currentProfileUsageText(u"hour"_s);
}

QString VpnController::currentProfileUsageDay() const
{
    return currentProfileUsageText(u"day"_s);
}

QString VpnController::currentProfileUsageWeek() const
{
    return currentProfileUsageText(u"week"_s);
}

QString VpnController::currentProfileUsageMonth() const
{
    return currentProfileUsageText(u"month"_s);
}

bool VpnController::processRoutingSupported() const
{
    return m_processRoutingSupported;
}

quint16 VpnController::socksPort() const
{
    return m_buildOptions.socksPort;
}

quint16 VpnController::httpPort() const
{
    return m_buildOptions.httpPort;
}

bool VpnController::importProfileLink(const QString& link)
{
    QString error;
    auto parsed = LinkParser::parse(link, &error);
    if (!parsed.has_value()) {
        setLastError(error);
        return false;
    }

    auto profile = parsed.value();
    if (profile.name.trimmed().isEmpty()) {
        profile.name = u"%1 %2"_s
        .arg(profile.protocol.toUpper(), profile.address);
    }
    profile.groupName = normalizeGroupName(m_currentProfileGroup);
    profile.sourceName = u"Manual import"_s;
    profile.sourceId = u"manual"_s;

    if (!m_profileModel.addProfile(profile)) {
        setLastError(u"Failed to add imported profile."_s);
        return false;
    }

    saveProfiles();

    const int importedIndex = m_profileModel.indexOfId(profile.id);
    setCurrentProfileIndex(importedIndex);
    if (m_autoPingProfiles && importedIndex >= 0) {
        pingProfile(importedIndex);
    }

    if (!m_lastError.isEmpty()) {
        setLastError(QString());
    }
    if (m_connectionState == ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }

    return true;
}

int VpnController::importProfileBatch(const QString& text)
{
    const QStringList links = extractSubscriptionLinks(text.toUtf8());
    if (links.isEmpty()) {
        setLastError(u"No supported VMESS/VLESS links found in input."_s);
        return 0;
    }

    int lastImportedIndex = -1;
    const QString groupName = normalizeGroupName(m_currentProfileGroup);
    const int importCount = importLinks(
        links,
        u"manual"_s,
        u"Manual import"_s,
        groupName,
        &lastImportedIndex
        );

    if (importCount <= 0) {
        setLastError(u"No valid profiles were imported from input."_s);
        return 0;
    }

    saveProfiles();
    if (m_currentProfileIndex < 0 && lastImportedIndex >= 0) {
        setCurrentProfileIndex(lastImportedIndex);
    }
    if (m_autoPingProfiles) {
        pingAllProfiles();
    }

    appendSystemLog(u"[Import] Imported %1 profile(s)."_s.arg(importCount));
    if (!m_lastError.isEmpty()) {
        setLastError(QString());
    }
    if (m_connectionState == ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }
    return importCount;
}

bool VpnController::addSubscription(const QString& url, const QString& name, const QString& group)
{
    const QString trimmedUrl = url.trimmed();
    const QUrl parsedUrl(trimmedUrl);
    if (!parsedUrl.isValid() || (parsedUrl.scheme() != u"http"_s && parsedUrl.scheme() != u"https"_s)) {
        setLastError(u"Subscription URL must be a valid http(s) link."_s);
        return false;
    }

    if (m_subscriptionBusy) {
        setLastError(u"Another subscription operation is already running."_s);
        return false;
    }

    const QString normalizedUrl = parsedUrl.toString(QUrl::FullyEncoded);
    const QString normalizedName = normalizeSubscriptionNameValue(name, normalizedUrl);
    const QString normalizedGroup = normalizeGroupName(group.isEmpty() ? m_currentProfileGroup : group);

    int existingIndex = -1;
    for (int i = 0; i < m_subscriptionEntries.size(); ++i) {
        if (m_subscriptionEntries.at(i).url.compare(normalizedUrl, Qt::CaseInsensitive) == 0) {
            existingIndex = i;
            break;
        }
    }

    SubscriptionEntry entry;
    if (existingIndex >= 0) {
        entry = m_subscriptionEntries.at(existingIndex);
        entry.url = normalizedUrl;
        entry.name = normalizedName;
        entry.group = normalizedGroup;
        m_subscriptionEntries[existingIndex] = entry;
    } else {
        entry.id = createSubscriptionId();
        entry.url = normalizedUrl;
        entry.name = normalizedName;
        entry.group = normalizedGroup;
        m_subscriptionEntries.append(entry);
    }

    saveSubscriptions();
    refreshProfileGroups();
    emit subscriptionsChanged();

    beginSubscriptionOperation(u"Fetching %1..."_s.arg(entry.name));
    startSubscriptionFetch(entry, false);
    return true;
}

int VpnController::refreshSubscriptions()
{
    if (m_subscriptionBusy) {
        appendSystemLog(u"[Subscription] Another subscription operation is already running."_s);
        return 0;
    }

    if (m_subscriptionEntries.isEmpty()) {
        const QString message = u"No saved subscriptions."_s;
        appendSystemLog(u"[Subscription] %1"_s.arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = m_subscriptionEntries;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(u"Refreshing subscriptions..."_s);
    startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
    return m_subscriptionEntries.size();
}

int VpnController::refreshSubscriptionsByGroup(const QString& group)
{
    if (m_subscriptionBusy) {
        appendSystemLog(u"[Subscription] Another subscription operation is already running."_s);
        return 0;
    }

    const QString normalizedGroup = normalizeGroupName(group);
    QList<SubscriptionEntry> filtered;
    for (const SubscriptionEntry& entry : m_subscriptionEntries) {
        if (entry.group.compare(normalizedGroup, Qt::CaseInsensitive) == 0) {
            filtered.append(entry);
        }
    }

    if (filtered.isEmpty()) {
        const QString message = u"No subscriptions in group '%1'."_s.arg(normalizedGroup);
        appendSystemLog(u"[Subscription] %1"_s.arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = filtered;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(u"Refreshing group '%1'..."_s.arg(normalizedGroup));
    startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
    return filtered.size();
}

int VpnController::importLinks(
    const QStringList& links,
    const QString& sourceId,
    const QString& sourceName,
    const QString& groupName,
    int *lastImportedIndex)
{
    const QString normalizedGroup = normalizeGroupName(groupName);
    const QString normalizedSourceName = sourceName.trimmed().isEmpty()
                                             ? u"Manual import"_s
                                             : sourceName.trimmed();
    const QString normalizedSourceId = sourceId.trimmed().isEmpty()
                                           ? u"manual"_s
                                           : sourceId.trimmed();

    int importCount = 0;
    int lastIndex = -1;
    for (const QString& linkLine : links) {
        QString parseError;
        auto parsed = LinkParser::parse(linkLine, &parseError);
        if (!parsed.has_value()) {
            continue;
        }

        auto profile = parsed.value();
        if (profile.name.trimmed().isEmpty()) {
            profile.name = u"%1 %2"_s
            .arg(profile.protocol.toUpper(), profile.address);
        }
        profile.groupName = normalizedGroup;
        profile.sourceName = normalizedSourceName;
        profile.sourceId = normalizedSourceId;
        if (m_profileModel.addProfile(profile)) {
            ++importCount;
            lastIndex = m_profileModel.indexOfId(profile.id);
        }
    }

    if (lastImportedIndex != nullptr) {
        *lastImportedIndex = lastIndex;
    }
    return importCount;
}

void VpnController::beginSubscriptionOperation(const QString& message)
{
    m_subscriptionBusy = true;
    m_subscriptionMessage = message;
    emit subscriptionStateChanged();
}

void VpnController::endSubscriptionOperation(const QString& message)
{
    m_subscriptionBusy = false;
    m_subscriptionMessage = message;
    emit subscriptionStateChanged();
}

void VpnController::startSubscriptionFetch(const SubscriptionEntry& entry, bool fromRefresh)
{
    const QString url = entry.url.trimmed();
    const QUrl parsedUrl(url);
    if (!parsedUrl.isValid()) {
        if (fromRefresh) {
            ++m_subscriptionRefreshFailCount;
            if (!m_subscriptionRefreshQueue.isEmpty()) {
                startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
            } else {
                finishRefreshSubscriptions();
            }
        } else {
            endSubscriptionOperation(u"Invalid subscription URL."_s);
        }
        return;
    }

    QNetworkRequest request(parsedUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(kSubscriptionFetchTimeoutMs);
    request.setRawHeader("User-Agent", "GenyConnect-Subscription/1.0");

    QNetworkReply* reply = m_subscriptionNetworkManager.get(request);
    auto* watchdog = new QTimer(reply);
    watchdog->setSingleShot(true);
    watchdog->setInterval(kSubscriptionFetchTimeoutMs + 2000);
    connect(watchdog, &QTimer::timeout, reply, [reply]() {
        if (reply->isFinished()) {
            return;
        }
        reply->setProperty("_geny_timeout", true);
        reply->abort();
    });
    watchdog->start();
    connect(reply, &QNetworkReply::finished, this, [this, reply, entry, url, fromRefresh]() {
        const bool hadError = (reply->error() != QNetworkReply::NoError);
        QByteArray payload;
        if (reply->isOpen()) {
            payload = reply->readAll();
        }
        const bool timedOut = reply->property("_geny_timeout").toBool();
        const QString netError = reply->errorString().trimmed();
        reply->deleteLater();

        int importedCount = 0;
        if (!hadError) {
            const QStringList links = extractSubscriptionLinks(payload);
            int lastImportedIndex = -1;
            importedCount = importLinks(links, entry.id, entry.name, entry.group, &lastImportedIndex);
            if (importedCount > 0) {
                saveProfiles();
                if (m_currentProfileIndex < 0 && lastImportedIndex >= 0) {
                    setCurrentProfileIndex(lastImportedIndex);
                }
                if (m_autoPingProfiles) {
                    pingAllProfiles();
                }
                appendSystemLog(u"[Subscription] Imported %1 profile(s) from %2 (%3)."_s
                                    .arg(importedCount)
                                    .arg(entry.name, entry.group));
                if (!m_lastError.isEmpty()) {
                    setLastError(QString());
                }
                if (m_connectionState == ConnectionState::Error) {
                    setConnectionState(ConnectionState::Disconnected);
                }
            }
        }

        if (fromRefresh) {
            if (importedCount > 0) {
                ++m_subscriptionRefreshSuccessCount;
            } else {
                ++m_subscriptionRefreshFailCount;
                appendSystemLog(u"[Subscription] Refresh failed for %1 (%2): %3"_s
                                    .arg(entry.name, entry.group, hadError ? netError : u"no valid profiles"_s));
            }
            if (!m_subscriptionRefreshQueue.isEmpty()) {
                startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
                return;
            }
            finishRefreshSubscriptions();
            return;
        }

        if (importedCount > 0) {
            endSubscriptionOperation(u"Imported %1 profile(s)."_s.arg(importedCount));
            return;
        }

        const QString message = hadError
                                    ? (timedOut
                                           ? u"Subscription fetch timed out."_s
                                           : (netError.isEmpty()
                                                  ? u"Failed to fetch subscription URL."_s
                                                  : u"Subscription fetch failed: %1"_s.arg(netError)))
                                    : u"Subscription payload has no supported VMESS/VLESS links."_s;
        appendSystemLog(u"[Subscription] %1 (%2): %3"_s
                            .arg(entry.name, entry.group, message));
        setLastError(message);
        endSubscriptionOperation(message);
    });
}

void VpnController::finishRefreshSubscriptions()
{
    const QString message = u"Refresh complete. Success: %1, failed: %2."_s
    .arg(m_subscriptionRefreshSuccessCount)
        .arg(m_subscriptionRefreshFailCount);
    appendSystemLog(u"[Subscription] %1"_s.arg(message));
    endSubscriptionOperation(message);
}

QString VpnController::normalizeGroupName(const QString& groupName)
{
    return normalizeGroupNameValue(groupName);
}

QString VpnController::normalizeGroupKey(const QString& groupName)
{
    return normalizeGroupName(groupName).toLower();
}

QString VpnController::deriveSubscriptionName(const QString& url)
{
    return deriveSubscriptionNameFromUrl(url);
}

int VpnController::profileGroupOptionsIndex(const QString& groupName) const
{
    const QString key = normalizeGroupKey(groupName);
    for (int i = 0; i < m_profileGroupOptions.size(); ++i) {
        if (m_profileGroupOptions.at(i).key == key) {
            return i;
        }
    }
    return -1;
}

VpnController::ProfileGroupOptions VpnController::profileGroupOptionsFor(const QString& groupName) const
{
    ProfileGroupOptions options;
    options.name = normalizeGroupName(groupName);
    options.key = normalizeGroupKey(options.name);
    options.enabled = true;
    options.exclusive = false;
    options.badge.clear();

    const int idx = profileGroupOptionsIndex(options.name);
    if (idx >= 0) {
        return m_profileGroupOptions.at(idx);
    }

    if (options.name.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        options.enabled = true;
        options.exclusive = false;
        options.badge.clear();
    }
    return options;
}

void VpnController::upsertProfileGroupOptions(const ProfileGroupOptions& options, bool save)
{
    ProfileGroupOptions normalized = options;
    normalized.name = normalizeGroupName(normalized.name);
    normalized.key = normalizeGroupKey(normalized.name);
    normalized.badge = normalized.badge.trimmed();

    if (normalized.name.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
        normalized.enabled = true;
        normalized.exclusive = false;
        normalized.badge.clear();
    }

    const int idx = profileGroupOptionsIndex(normalized.name);
    bool changed = false;
    if (idx >= 0) {
        const ProfileGroupOptions& old = m_profileGroupOptions.at(idx);
        if (old.name != normalized.name
            || old.enabled != normalized.enabled
            || old.exclusive != normalized.exclusive
            || old.badge != normalized.badge) {
            m_profileGroupOptions[idx] = normalized;
            changed = true;
        }
    } else {
        m_profileGroupOptions.append(normalized);
        changed = true;
    }

    if (!changed) {
        return;
    }

    emit profileGroupOptionsChanged();
    if (save) {
        saveSettings();
    }
}

void VpnController::refreshProfileGroups()
{
    QStringList groups;
    groups.append(u"All"_s);

    QSet<QString> seen;
    seen.insert(u"all"_s);

    auto appendGroupIfNeeded = [&groups, &seen](const QString& rawGroup) {
        const QString normalized = normalizeGroupName(rawGroup);
        const QString key = normalized.toLower();
        if (seen.contains(key)) {
            return;
        }
        seen.insert(key);
        groups.append(normalized);
    };

    for (const SubscriptionEntry& entry : m_subscriptionEntries) {
        appendGroupIfNeeded(entry.group);
    }

    const auto allProfiles = m_profileModel.profiles();
    for (const ServerProfile& profile : allProfiles) {
        appendGroupIfNeeded(profile.groupName);
    }

    for (const ProfileGroupOptions& options : m_profileGroupOptions) {
        appendGroupIfNeeded(options.name);
    }

    if (groups.size() > 2) {
        std::sort(groups.begin() + 1, groups.end(), [](const QString& a, const QString& b) {
            return a.localeAwareCompare(b) < 0;
        });
    }

    bool optionsChanged = false;
    for (const QString& groupName : groups) {
        ProfileGroupOptions options = profileGroupOptionsFor(groupName);
        if (options.name != groupName) {
            options.name = groupName;
            options.key = normalizeGroupKey(groupName);
            const int idx = profileGroupOptionsIndex(groupName);
            if (idx >= 0) {
                m_profileGroupOptions[idx] = options;
            } else {
                m_profileGroupOptions.append(options);
            }
            optionsChanged = true;
        } else if (profileGroupOptionsIndex(groupName) < 0) {
            m_profileGroupOptions.append(options);
            optionsChanged = true;
        }
    }

    bool exclusiveFound = false;
    for (int i = 0; i < m_profileGroupOptions.size(); ++i) {
        auto& options = m_profileGroupOptions[i];
        if (options.name.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
            if (!options.enabled || options.exclusive || !options.badge.isEmpty()) {
                options.enabled = true;
                options.exclusive = false;
                options.badge.clear();
                optionsChanged = true;
            }
            continue;
        }
        if (!options.enabled && options.exclusive) {
            options.exclusive = false;
            optionsChanged = true;
        }
        if (options.exclusive) {
            if (exclusiveFound) {
                options.exclusive = false;
                optionsChanged = true;
            } else {
                exclusiveFound = true;
            }
        }
    }

    if (m_profileGroups != groups) {
        m_profileGroups = groups;
        emit profileGroupsChanged();
        emit profileGroupOptionsChanged();
    }

    if (optionsChanged) {
        emit profileGroupOptionsChanged();
        saveSettings();
    }

    QString normalizedCurrent = m_currentProfileGroup.trimmed();
    if (normalizedCurrent.isEmpty() || normalizedCurrent.compare(u"all"_s, Qt::CaseInsensitive) == 0) {
        normalizedCurrent = u"All"_s;
    }
    bool exists = false;
    for (const QString& item : m_profileGroups) {
        if (item.compare(normalizedCurrent, Qt::CaseInsensitive) == 0) {
            normalizedCurrent = item;
            exists = true;
            break;
        }
    }
    if (!exists) {
        normalizedCurrent = u"All"_s;
    }
    if (normalizedCurrent.compare(u"All"_s, Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalizedCurrent)) {
        normalizedCurrent = u"All"_s;
    }

    if (m_currentProfileGroup != normalizedCurrent) {
        m_currentProfileGroup = normalizedCurrent;
        emit currentProfileGroupChanged();
        saveSettings();
    }
}

void VpnController::recomputeProfileStats()
{
    const int totalCount = m_profileModel.rowCount();
    const QString normalizedCurrentGroup = normalizeGroupName(m_currentProfileGroup);
    const bool allGroups = (m_currentProfileGroup.compare(u"All"_s, Qt::CaseInsensitive) == 0);

    int filteredCount = 0;
    int best = -1;
    int worst = -1;
    int successCount = 0;
    qint64 sumPing = 0;

    for (int i = 0; i < totalCount; ++i) {
        const auto profile = m_profileModel.profileAt(i);
        if (!profile.has_value()) {
            continue;
        }

        const QString profileGroup = normalizeGroupName(profile->groupName);
        if (!isProfileGroupEnabled(profileGroup)) {
            continue;
        }
        if (!allGroups && profileGroup.compare(normalizedCurrentGroup, Qt::CaseInsensitive) != 0) {
            continue;
        }

        ++filteredCount;
        if (profile->lastPingMs >= 0) {
            const int ping = profile->lastPingMs;
            best = (best < 0) ? ping : qMin(best, ping);
            worst = (worst < 0) ? ping : qMax(worst, ping);
            sumPing += ping;
            ++successCount;
        }
    }

    double score = 0.0;
    if (filteredCount > 0 && successCount > 0) {
        const double avgPing = static_cast<double>(sumPing) / static_cast<double>(successCount);
        const double availability = static_cast<double>(successCount) / static_cast<double>(filteredCount);
        const double latencyComponent = qMax(0.0, 1.0 - (avgPing / 800.0)) * 3.0;
        const double availabilityComponent = availability * 2.0;
        score = qBound(0.0, latencyComponent + availabilityComponent, 5.0);
    }

    if (m_profileCount == totalCount
        && m_filteredProfileCount == filteredCount
        && m_bestPingMs == best
        && m_worstPingMs == worst
        && qFuzzyCompare(m_profileScore, score)) {
        return;
    }

    m_profileCount = totalCount;
    m_filteredProfileCount = filteredCount;
    m_bestPingMs = best;
    m_worstPingMs = worst;
    m_profileScore = score;
    emit profileStatsChanged();
}

bool VpnController::removeProfile(int row)
{
    const int previousIndex = m_currentProfileIndex;
    if (!m_profileModel.removeAt(row)) {
        return false;
    }

    const int rowCount = m_profileModel.rowCount();
    if (rowCount == 0) {
        setCurrentProfileIndex(-1);
    } else if (previousIndex == row) {
        setCurrentProfileIndex(qMin(row, rowCount - 1));
    } else if (row < previousIndex) {
        setCurrentProfileIndex(previousIndex - 1);
    } else if (m_currentProfileIndex >= rowCount) {
        setCurrentProfileIndex(rowCount - 1);
    }

    saveProfiles();
    return true;
}

bool VpnController::updateProfileBasics(int row, const QString& name, const QString& groupName)
{
    QList<ServerProfile> profiles = m_profileModel.profiles();
    if (row < 0 || row >= profiles.size()) {
        setLastError(u"Profile is no longer available."_s);
        return false;
    }

    ServerProfile& profile = profiles[row];
    const QString cleanName = name.trimmed();
    const QString cleanGroup = normalizeGroupName(groupName);
    bool changed = false;

    if (!cleanName.isEmpty() && profile.name != cleanName) {
        profile.name = cleanName;
        changed = true;
    }
    if (!cleanGroup.isEmpty() && profile.groupName != cleanGroup) {
        profile.groupName = cleanGroup;
        changed = true;
    }

    if (!changed) {
        return true;
    }

    m_profileModel.setProfiles(profiles);
    upsertProfileGroupOptions(profileGroupOptionsFor(cleanGroup), false);
    refreshProfileGroups();
    recomputeProfileStats();
    saveProfiles();
    saveSettings();
    if (row == m_currentProfileIndex) {
        emit currentProfileIndexChanged();
    }
    appendSystemLog(u"[Profile] Updated profile '%1'."_s.arg(profile.displayLabel()));
    return true;
}

int VpnController::removeAllProfiles()
{
    const int removedCount = m_profileModel.rowCount();
    if (removedCount <= 0) {
        return 0;
    }

    m_profileModel.setProfiles({});
    setCurrentProfileIndex(-1);
    m_currentProfileId.clear();
    saveProfiles();
    saveSettings();
    appendSystemLog(u"[Profile] Removed all profiles."_s);
    return removedCount;
}

void VpnController::pingProfile(int row)
{
    const auto profile = m_profileModel.profileAt(row);
    if (!profile.has_value()) {
        return;
    }

    const QString address = profile->address.trimmed();
    const quint16 port = profile->port;
    const QString profileId = profile->id;
    const int currentRow = m_profileModel.indexOfId(profileId);
    if (currentRow < 0) {
        return;
    }

    if (address.isEmpty() || port == 0) {
        m_profileModel.setPingResult(currentRow, -1);
        return;
    }

    m_profileModel.setPinging(currentRow, true);

    auto *socket = new QTcpSocket(this);
    socket->setProperty("_geny_ping_done", false);
    socket->setProperty("_geny_ping_start_ms", QDateTime::currentMSecsSinceEpoch());

    auto finishPing = [this, socket, profileId](int pingMs) mutable {
        if (socket->property("_geny_ping_done").toBool()) {
            return;
        }
        socket->setProperty("_geny_ping_done", true);

        const int rowNow = m_profileModel.indexOfId(profileId);
        if (rowNow >= 0) {
            m_profileModel.setPingResult(rowNow, pingMs);
        }

        socket->abort();
        socket->deleteLater();
    };

    connect(socket, &QTcpSocket::connected, socket, [finishPing, socket]() mutable {
        const qint64 startedAt = socket->property("_geny_ping_start_ms").toLongLong();
        const qint64 elapsedMs = qMax<qint64>(1, QDateTime::currentMSecsSinceEpoch() - startedAt);
        finishPing(static_cast<int>(elapsedMs));
    });

    connect(socket, &QTcpSocket::errorOccurred, socket, [finishPing](QAbstractSocket::SocketError) mutable {
        finishPing(-1);
    });

    QTimer::singleShot(kProfilePingTimeoutMs, socket, [socket, finishPing]() mutable {
        if (socket->property("_geny_ping_done").toBool()) {
            return;
        }
        if (socket->state() == QAbstractSocket::ConnectedState) {
            return;
        }
        finishPing(-1);
    });

    socket->connectToHost(address, port);
}

void VpnController::pingAllProfiles()
{
    const QString normalizedCurrentGroup = normalizeGroupName(m_currentProfileGroup);
    const bool allGroups = (m_currentProfileGroup.compare(u"All"_s, Qt::CaseInsensitive) == 0);

    const int count = m_profileModel.rowCount();
    int scheduled = 0;
    for (int row = 0; row < count; ++row) {
        const auto profile = m_profileModel.profileAt(row);
        if (!profile.has_value()) {
            continue;
        }

        const QString profileGroup = normalizeGroupName(profile->groupName);
        if (!isProfileGroupEnabled(profileGroup)) {
            continue;
        }
        if (!allGroups && profileGroup.compare(normalizedCurrentGroup, Qt::CaseInsensitive) != 0) {
            continue;
        }

        const QString profileId = profile->id;
        QTimer::singleShot(scheduled * kProfilePingStaggerMs, this, [this, profileId]() {
            const int rowNow = m_profileModel.indexOfId(profileId);
            if (rowNow >= 0) {
                pingProfile(rowNow);
            }
        });
        ++scheduled;
    }
}

void VpnController::connectToProfile(int row)
{
    if (busy()) {
        return;
    }

    if (row < 0 || row >= m_profileModel.rowCount()) {
        setLastError(u"Please select a valid server profile."_s);
        setConnectionState(ConnectionState::Error);
        return;
    }

    // If runtime is alive, perform a coordinated reconnect when user selected
    // another profile instead of silently keeping stale runtime state.
    if (m_processManager.isRunning() || m_privilegedTunManaged) {
        if (row != m_currentProfileIndex || m_pendingReconnectProfileIndex >= 0) {
            m_pendingReconnectProfileIndex = row;
            appendSystemLog(u"[System] Restarting tunnel with selected profile..."_s);
            disconnect();
            return;
        }
        setConnectionState(ConnectionState::Connected);
        appendSystemLog(u"[System] Xray is already running. Disconnect first before reconnecting."_s);
        return;
    }

    if (connected() && row == m_currentProfileIndex) {
        appendSystemLog(u"[System] Selected profile is already connected."_s);
        return;
    }

    auto profile = m_profileModel.profileAt(row);
    if (!profile.has_value()) {
        setLastError(u"Please select a valid server profile."_s);
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        setLastError(u"Set the xray-core executable path first."_s);
        setConnectionState(ConnectionState::Error);
        return;
    }

    QString executableError;
    if (!ensureExecutableFile(m_xrayExecutablePath, &executableError)) {
        setLastError(executableError);
        setConnectionState(ConnectionState::Error);
        return;
    }

    setCurrentProfileIndex(row);
    m_activeProfileUsageId = profile->id.trimmed();
    resetPerProfileUsageSamples();
    m_activeProfileAddress = profile->address.trimmed();

    QString configError;
    if (!writeRuntimeConfig(profile.value(), &configError)) {
        setLastError(configError);
        setConnectionState(ConnectionState::Error);
        return;
    }

#if defined(Q_OS_WIN)
    if (m_tunMode) {
        QString copiedFrom;
        QString runtimeError;
        if (!ensureWindowsTunRuntimeReady(m_xrayExecutablePath, m_dataDirectory, &copiedFrom, &runtimeError)) {
            appendSystemLog(u"[System] %1"_s.arg(runtimeError));
            setLastError(runtimeError);
            setConnectionState(ConnectionState::Error);
            return;
        }
        if (!copiedFrom.trimmed().isEmpty()) {
            appendSystemLog(u"[System] Copied wintun.dll for TUN runtime from: %1"_s.arg(copiedFrom));
        }
    }
#endif

    if (m_tunMode) {
        setConnectionState(ConnectionState::Connecting);
        setLastError(QString());
        const QPointer<VpnController> guard(this);
        [[maybe_unused]] auto tunStartFuture = QtConcurrent::run([guard]() {
            QString elevateError;
            bool ok = false;
            if (guard) {
                ok = guard->startPrivilegedTunProcess(&elevateError);
            }
            if (!guard) {
                return;
            }
            QMetaObject::invokeMethod(guard.data(), [guard, ok, elevateError]() {
                if (!guard) {
                    return;
                }
                if (ok) {
                    guard->m_privilegedTunManaged = true;
                    guard->m_privilegedTunLogOffset = 0;
                    guard->m_privilegedTunLogBuffer.clear();
                    guard->startProfileUsageSession();
                    guard->m_privilegedTunLogTimer.start();
                    guard->setConnectionState(ConnectionState::Connected);
                    guard->setLastError(QString());
                    guard->appendSystemLog(u"[System] TUN mode active: system traffic should route through Xray TUN."_s);
                    guard->appendSystemLog(u"[System] Xray started (privileged TUN). Local proxy (mixed): 127.0.0.1:%1."_s
                                               .arg(guard->m_buildOptions.socksPort));
                    guard->m_statsPollTimer.start();
                    guard->pollTrafficStats();
                    QTimer::singleShot(700, guard.data(), [guard]() {
                        if (guard) {
                            guard->runProxySelfCheck();
                        }
                    });
                    return;
                }

                if (!elevateError.trimmed().isEmpty()) {
                    guard->appendSystemLog(u"[System] %1"_s.arg(elevateError));
                    guard->setLastError(elevateError);
                } else {
                    guard->setLastError(u"Failed to start privileged TUN runtime."_s);
                }
                guard->setConnectionState(ConnectionState::Error);
            }, Qt::QueuedConnection);
        });
        return;
    }

    m_processManager.setExecutablePath(m_xrayExecutablePath);
    m_rxBytes = 0;
    m_txBytes = 0;
    resetPerProfileUsageSamples();
    emit trafficChanged();

    setConnectionState(ConnectionState::Connecting);
    setLastError(QString());

    QString processError;
    if (!m_processManager.start(m_runtimeConfigPath, &processError)) {
        setLastError(processError);
        setConnectionState(ConnectionState::Error);
    }
}

void VpnController::connectSelected()
{
    connectToProfile(m_currentProfileIndex);
}

void VpnController::disconnect()
{
    m_statsPollTimer.stop();
    cancelSpeedTest();
    finishProfileUsageSession();
    resetPerProfileUsageSamples();

    if (m_privilegedTunManaged) {
        m_privilegedTunLogTimer.stop();
        setConnectionState(ConnectionState::Connecting);
        const QPointer<VpnController> guard(this);
        [[maybe_unused]] auto tunStopFuture = QtConcurrent::run([guard]() {
            QString stopError;
            bool stopped = false;
            if (guard) {
                stopped = guard->stopPrivilegedTunProcess(&stopError);
            }
            if (!guard) {
                return;
            }
            QMetaObject::invokeMethod(guard.data(), [guard, stopped, stopError]() {
                if (!guard) {
                    return;
                }
                guard->m_privilegedTunManaged = false;
                if (!stopped && !stopError.trimmed().isEmpty()) {
                    guard->appendSystemLog(u"[System] %1"_s.arg(stopError));
                    guard->stopPrivilegedTunRuntimeByPidPath();
                }
                guard->setConnectionState(ConnectionState::Disconnected);
                guard->maybeReconnectToPendingProfile();
            }, Qt::QueuedConnection);
        });
        return;
    }

    if (m_processManager.isRunning()) {
        m_stoppingProcess = true;
        setConnectionState(ConnectionState::Connecting);
        m_processManager.stop(0);
        return;
    }

    m_stoppingProcess = false;
    setConnectionState(ConnectionState::Disconnected);
    maybeReconnectToPendingProfile();
}

void VpnController::toggleConnection()
{
    // Use process state as source of truth for disconnect behavior.
    if (m_processManager.isRunning() || connected() || busy()) {
        disconnect();
        return;
    }

    connectSelected();
}

void VpnController::cleanSystemProxy()
{
    applySystemProxy(false, true);
}

void VpnController::refreshPublicIp()
{
    if (m_publicIpReply) {
        QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
    }

    if ((connected() && !m_tunMode) || (m_killSwitchEnabled && !connected())) {
        m_publicIpNetworkManager.setProxy(
            QNetworkProxy(QNetworkProxy::Socks5Proxy, u"127.0.0.1"_s, m_buildOptions.socksPort));
    } else {
        m_publicIpNetworkManager.setProxy(QNetworkProxy::NoProxy);
    }

    QNetworkRequest request(QUrl(QString::fromLatin1(kPublicIpEndpoint)));
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setTransferTimeout(kPublicIpTimeoutMs);
    request.setRawHeader("User-Agent", "GenyConnect-IPCheck/1.0");
    request.setRawHeader("Accept", "text/plain");

    m_publicIpRefreshing = true;
    emit publicIpAddressChanged();

    m_publicIpReply = m_publicIpNetworkManager.get(request);
    connect(m_publicIpReply, &QNetworkReply::finished, this, &VpnController::onPublicIpFinished);
}

void VpnController::setXrayExecutableFromUrl(const QUrl& url)
{
    setXrayExecutablePath(url.toLocalFile());
}

void VpnController::startSpeedTestRequest(const QUrl& url, bool upload, const QByteArray& payload)
{
    QUrl requestUrl(url);
    QUrlQuery query(requestUrl);
    query.addQueryItem(u"_gc"_s, QString::number(QDateTime::currentMSecsSinceEpoch()));
    requestUrl.setQuery(query);

    QNetworkRequest request(requestUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    request.setRawHeader("Cache-Control", "no-cache");
    request.setRawHeader("Pragma", "no-cache");
    request.setRawHeader("User-Agent", "GenyConnect-SpeedTest/1.0");
    request.setRawHeader("Accept", "*/*");
    request.setTransferTimeout(12000);
    if (upload) {
        request.setHeader(QNetworkRequest::ContentTypeHeader, u"application/octet-stream"_s);
    }

    m_speedTestUploadMode = upload;
    if (upload) {
        m_speedTestReply = m_speedTestNetworkManager.post(request, payload);
        connect(m_speedTestReply, &QNetworkReply::uploadProgress, this, &VpnController::onSpeedTestUploadProgress);
    } else {
        m_speedTestReply = m_speedTestNetworkManager.get(request);
    }
    m_speedTestRequestTimer.restart();
    connect(m_speedTestReply, &QNetworkReply::readyRead, this, &VpnController::onSpeedTestReadyRead);
    connect(m_speedTestReply, &QNetworkReply::finished, this, &VpnController::onSpeedTestFinished);
}

void VpnController::startCurrentSpeedTestRequest()
{
    if (!m_speedTestRunning) {
        return;
    }

    if (m_speedTestReply != nullptr) {
        QObject::disconnect(m_speedTestReply, nullptr, this, nullptr);
        m_speedTestReply->abort();
        m_speedTestReply->deleteLater();
        m_speedTestReply = nullptr;
    }

    const QUrl url = speedTestUrlForPhase(m_speedTestPhase, m_speedTestAttempt);
    if (!url.isValid()) {
        finishSpeedTest(false, u"Invalid speed test endpoint."_s);
        return;
    }

    const bool upload = (m_speedTestPhase == u"Upload"_s);
    const QByteArray payload = upload ? buildUploadPayload() : QByteArray();
    ++m_speedTestAttempt;
    startSpeedTestRequest(url, upload, payload);
}

void VpnController::startPingPhase()
{
    m_speedTestPhase = u"Ping"_s;
    m_speedTestDurationSec = 4;
    m_speedTestElapsedSec = 0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestAttempt = 0;
    m_speedTestPingSampleCount = 0;
    m_speedTestPingTotalMs = 0;
    m_speedTestPhaseTimer.restart();
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();

    startCurrentSpeedTestRequest();
}

void VpnController::startDownloadPhase()
{
    m_speedTestPhase = u"Download"_s;
    m_speedTestDurationSec = 10;
    m_speedTestElapsedSec = 0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestAttempt = 0;
    m_speedTestPhaseTimer.restart();
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();

    startCurrentSpeedTestRequest();
}

void VpnController::startUploadPhase()
{
    m_speedTestPhase = u"Upload"_s;
    m_speedTestDurationSec = 8;
    m_speedTestElapsedSec = 0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestAttempt = 0;
    m_speedTestPhaseTimer.restart();
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();

    startCurrentSpeedTestRequest();
}

void VpnController::finishSpeedTest(bool ok, const QString& error)
{
    if (m_speedTestReply != nullptr) {
        QObject::disconnect(m_speedTestReply, nullptr, this, nullptr);
        m_speedTestReply->abort();
        m_speedTestReply->deleteLater();
        m_speedTestReply = nullptr;
    }
    m_speedTestTimer.stop();
    m_speedTestRunning = false;
    m_speedTestCurrentMbps = ok ? qMax(m_speedTestDownloadMbps, m_speedTestUploadMbps) : 0.0;
    m_speedTestPhase = ok ? u"Done"_s : u"Error"_s;
    m_speedTestError = ok ? QString() : error;
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    emit speedTestChanged();

    if (ok) {
        const QString resultLine = u"Done: ping %1 ms, down %2 Mbps, up %3 Mbps"_s
        .arg(m_speedTestPingMs)
            .arg(QString::number(m_speedTestDownloadMbps, 'f', 1))
            .arg(QString::number(m_speedTestUploadMbps, 'f', 1));
        m_speedTestHistory.prepend(resultLine);
        while (m_speedTestHistory.size() > kSpeedTestHistoryMaxItems) {
            m_speedTestHistory.removeLast();
        }
        appendSystemLog(u"[SpeedTest] %1"_s.arg(resultLine));
    } else {
        appendSystemLog(u"[SpeedTest] Failed: %1"_s.arg(error));
    }
    emit speedTestChanged();
}

void VpnController::startSpeedTest()
{
    if (busy() && !connected()) {
        appendSystemLog(u"[SpeedTest] Wait for current connection attempt to finish."_s);
        return;
    }

    cancelSpeedTest();
    resetSpeedTestState(false);

    m_speedTestRunning = true;
    m_speedTestElapsedSec = 0;
    m_speedTestDurationSec = 3;
    m_speedTestPingMs = -1;
    m_speedTestDownloadMbps = 0.0;
    m_speedTestUploadMbps = 0.0;
    m_speedTestError.clear();
    m_speedTestPingSampleCount = 0;
    m_speedTestPingTotalMs = 0;
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    emit speedTestChanged();

    if (connected()) {
        m_speedTestNetworkManager.setProxy(
            QNetworkProxy(QNetworkProxy::Socks5Proxy, u"127.0.0.1"_s, m_buildOptions.socksPort));
        appendSystemLog(u"[SpeedTest] Started via VPN tunnel (SOCKS5 127.0.0.1:%1)."_s
                            .arg(m_buildOptions.socksPort));
    } else {
        m_speedTestNetworkManager.setProxy(QNetworkProxy::NoProxy);
        appendSystemLog(u"[SpeedTest] Started via direct internet (no VPN proxy)."_s);
    }

    m_speedTestTimer.start();
    startPingPhase();
}

void VpnController::cancelSpeedTest()
{
    if (m_speedTestReply != nullptr) {
        QObject::disconnect(m_speedTestReply, nullptr, this, nullptr);
        m_speedTestReply->abort();
        m_speedTestReply->deleteLater();
        m_speedTestReply = nullptr;
    }

    if (m_speedTestTimer.isActive()) {
        m_speedTestTimer.stop();
    }

    if (m_speedTestRunning) {
        m_speedTestRunning = false;
        m_speedTestCurrentMbps = 0.0;
        m_speedTestPhase = u"Idle"_s;
        m_speedTestPhaseTimer.invalidate();
        m_speedTestSampleTimer.invalidate();
        emit speedTestChanged();
        appendSystemLog(u"[SpeedTest] Canceled."_s);
    }
}

QString VpnController::formatBytes(qint64 bytes) const
{
    static const QStringList units {u"B"_s, u"KB"_s, u"MB"_s, u"GB"_s, u"TB"_s};

    double value = static_cast<double>(bytes);
    int unitIndex = 0;

    while (value >= 1024.0 && unitIndex < units.size() - 1) {
        value /= 1024.0;
        ++unitIndex;
    }

    return u"%1 %2"_s
        .arg(QString::number(value, unitIndex == 0 ? 'f' : 'f', unitIndex == 0 ? 0 : 2), units.at(unitIndex));
}

QString VpnController::currentProfileAddress() const
{
    const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }
    return profile->address.trimmed();
}

QString VpnController::currentProfileLabel() const
{
    const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }
    return profile->name.trimmed();
}

QString VpnController::currentProfileSubtitle() const
{
    const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }

    QString subtitle = u"%1  %2:%3"_s
                           .arg(profile->protocol.toUpper(), profile->address, QString::number(profile->port));
    if (!profile->security.trimmed().isEmpty()) {
        subtitle += u"  |  %1"_s.arg(profile->security.trimmed());
    }
    return subtitle;
}

void VpnController::copyLogsToClipboard() const
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard) {
        return;
    }

    clipboard->setText(m_recentLogs.join('\n'));
}

void VpnController::onProcessStarted()
{
    m_stoppingProcess = false;
    resetPerProfileUsageSamples();
    startProfileUsageSession();
    setConnectionState(ConnectionState::Connected);
    if (m_tunMode) {
        appendSystemLog(u"[System] TUN mode active: system traffic should route through Xray TUN."_s);
    } else if (m_useSystemProxy || m_killSwitchEnabled) {
        applySystemProxy(true);
    } else {
        appendSystemLog(u"[System] Clean mode active: system proxy stays disabled (only apps configured to 127.0.0.1:%1 use the tunnel)."_s
                            .arg(m_buildOptions.socksPort));
    }

    appendSystemLog(u"[System] Xray started. Local proxy (mixed): 127.0.0.1:%1."_s
                        .arg(m_buildOptions.socksPort));

    m_statsPollTimer.start();
    pollTrafficStats();

    QTimer::singleShot(700, this, [this]() {
        runProxySelfCheck();
    });
}

void VpnController::onProcessStopped(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    m_statsPollTimer.stop();
    cancelSpeedTest();
    finishProfileUsageSession();
    resetPerProfileUsageSamples();
    if (m_killSwitchEnabled) {
        applySystemProxy(true, true);
        appendSystemLog(u"[System] Kill Switch active: system proxy remains locked to GenyConnect."_s);
    } else if (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect) {
        applySystemProxy(false);
    }

    if (m_stoppingProcess) {
        m_stoppingProcess = false;
        setLastError(QString());
        setConnectionState(ConnectionState::Disconnected);
        maybeReconnectToPendingProfile();
        return;
    }

    if (exitStatus == QProcess::CrashExit) {
        setLastError(u"xray-core terminated unexpectedly."_s);
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_connectionState != ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }
    m_pendingReconnectProfileIndex = -1;
    m_activeProfileUsageId.clear();
}

void VpnController::onProcessError(const QString& error)
{
    if (m_stoppingProcess) {
        return;
    }

    m_statsPollTimer.stop();
    cancelSpeedTest();
    finishProfileUsageSession();
    resetPerProfileUsageSamples();
    setLastError(u"xray-core error: %1"_s.arg(error));
    setConnectionState(ConnectionState::Error);
}

void VpnController::scheduleLogsChanged()
{
    m_logsDirty = true;
    if (!m_logsFlushTimer.isActive()) {
        m_logsFlushTimer.start();
    }
}

void VpnController::onLogLine(const QString& line)
{
    if (!m_loggingEnabled) {
        return;
    }
    if (isNoisyTrafficLine(line)) {
        return;
    }
    // Hide internal Stats API polling noise from UI logs.
    if (line.contains(u"[api-in -> api]"_s)) {
        return;
    }

    m_latestLogLine = line;
    emit latestLogLineChanged();

    m_recentLogs.append(line);
    while (m_recentLogs.size() > kMaxLogLines) {
        m_recentLogs.removeFirst();
    }
    scheduleLogsChanged();
}

void VpnController::onTrafficUpdated()
{
    if (m_statsPollTimer.isActive()) {
        return;
    }

    const qint64 nextRx = m_processManager.rxBytes();
    const qint64 nextTx = m_processManager.txBytes();
    if (nextRx != m_rxBytes || nextTx != m_txBytes) {
        updatePerProfileUsageCounters(nextRx, nextTx);
        m_rxBytes = nextRx;
        m_txBytes = nextTx;
        emit trafficChanged();
    }
}

void VpnController::pollTrafficStats()
{
    if (!connected() || m_statsPolling) {
        return;
    }

    const QString executablePath = m_xrayExecutablePath;
    if (executablePath.trimmed().isEmpty()) {
        return;
    }
    const quint16 apiPort = m_buildOptions.apiPort;
    const QPointer<VpnController> guard(this);

    m_statsPolling = true;
    [[maybe_unused]] auto statsFuture = QtConcurrent::run(
        [guard, executablePath, apiPort]() {
            qint64 uplinkBytes = 0;
            qint64 downlinkBytes = 0;
            QString error;
            const bool ok = queryTrafficStatsFromApiSync(
                executablePath, apiPort, &uplinkBytes, &downlinkBytes, &error);
            if (!guard) {
                return;
            }
            QMetaObject::invokeMethod(guard.data(), [guard, ok, uplinkBytes, downlinkBytes, error]() {
                if (!guard) {
                    return;
                }

                guard->m_statsPolling = false;
                if (!guard->connected()) {
                    return;
                }

                if (!ok) {
                    ++guard->m_statsQueryFailureCount;
                    if ((guard->m_statsQueryFailureCount == 1 || guard->m_statsQueryFailureCount % 30 == 0)
                        && !error.trimmed().isEmpty()) {
                        guard->appendSystemLog(
                            u"[System] Traffic stats unavailable: %1"_s.arg(error.trimmed()));
                    }
                    return;
                }
                guard->m_statsQueryFailureCount = 0;

                if (guard->m_txBytes != uplinkBytes || guard->m_rxBytes != downlinkBytes) {
                    guard->updatePerProfileUsageCounters(downlinkBytes, uplinkBytes);
                    guard->m_txBytes = uplinkBytes;
                    guard->m_rxBytes = downlinkBytes;
                    emit guard->trafficChanged();
                }
            }, Qt::QueuedConnection);
        });
}

void VpnController::onSpeedTestTick()
{
    if (!m_speedTestRunning) {
        return;
    }

    if (m_speedTestPhaseTimer.isValid()) {
        const int nextElapsedSec = static_cast<int>(m_speedTestPhaseTimer.elapsed() / 1000);
        if (nextElapsedSec != m_speedTestElapsedSec) {
            m_speedTestElapsedSec = nextElapsedSec;
        }
    }

    if (m_speedTestPhase == u"Ping"_s) {
        qint64 elapsedMs = m_speedTestRequestTimer.isValid() ? m_speedTestRequestTimer.elapsed() : 0;
        if (elapsedMs <= 0 && m_speedTestPhaseTimer.isValid()) {
            elapsedMs = m_speedTestPhaseTimer.elapsed();
        }
        const double pingMs = static_cast<double>(qMax<qint64>(1, elapsedMs));
        m_speedTestCurrentMbps = pingMs;
        if (pingMs > m_speedTestPeakMbps) {
            m_speedTestPeakMbps = pingMs;
        }
        emit speedTestChanged();
        return;
    }

    qint64 sampleMs = m_speedTestSampleTimer.isValid() ? m_speedTestSampleTimer.restart() : kSpeedTestTickIntervalMs;
    if (sampleMs <= 0) {
        sampleMs = kSpeedTestTickIntervalMs;
    }
    const qint64 deltaBytes = qMax<qint64>(0, m_speedTestBytesReceived - m_speedTestLastBytes);
    m_speedTestLastBytes = m_speedTestBytesReceived;

    const double mbps = mbpsFromBytes(deltaBytes, sampleMs);
    m_speedTestCurrentMbps = mbps;
    if (mbps > m_speedTestPeakMbps) {
        m_speedTestPeakMbps = mbps;
    }
    emit speedTestChanged();

    if (!m_speedTestPhaseTimer.isValid()) {
        return;
    }
    if (m_speedTestPhaseTimer.elapsed() < static_cast<qint64>(m_speedTestDurationSec) * 1000) {
        return;
    }

    if (m_speedTestPhase == u"Download"_s) {
        const double averageMbps = mbpsFromBytes(m_speedTestBytesReceived, m_speedTestPhaseTimer.elapsed());
        m_speedTestDownloadMbps = qMax(m_speedTestDownloadMbps, qMax(m_speedTestPeakMbps, averageMbps));
        if (m_speedTestReply != nullptr) {
            QObject::disconnect(m_speedTestReply, nullptr, this, nullptr);
            m_speedTestReply->abort();
            m_speedTestReply->deleteLater();
            m_speedTestReply = nullptr;
        }
        emit speedTestChanged();
        startUploadPhase();
        return;
    }

    if (m_speedTestPhase == u"Upload"_s) {
        const double averageMbps = mbpsFromBytes(m_speedTestBytesReceived, m_speedTestPhaseTimer.elapsed());
        m_speedTestUploadMbps = qMax(m_speedTestUploadMbps, qMax(m_speedTestPeakMbps, averageMbps));
        finishSpeedTest(true);
    }
}

void VpnController::onSpeedTestReadyRead()
{
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (!m_speedTestRunning || m_speedTestReply == nullptr || reply == nullptr || reply != m_speedTestReply) {
        return;
    }
    if (!reply->isOpen()) {
        return;
    }

    const QByteArray chunk = reply->readAll();
    if (!chunk.isEmpty()) {
        m_speedTestBytesReceived += chunk.size();
        m_speedTestPhaseBytes += chunk.size();
    }
}

void VpnController::onSpeedTestUploadProgress(qint64 sent, qint64 total)
{
    Q_UNUSED(total)
    if (!m_speedTestRunning || !m_speedTestUploadMode) {
        return;
    }
    if (connected()) {
        return;
    }
    if (sent > m_speedTestBytesReceived) {
        const qint64 delta = sent - m_speedTestBytesReceived;
        m_speedTestBytesReceived = sent;
        m_speedTestPhaseBytes += delta;
    }
}

void VpnController::onSpeedTestFinished()
{
    if (m_speedTestReply == nullptr) {
        return;
    }

    const QString phaseAtFinish = m_speedTestPhase;
    const QString errorText = m_speedTestReply->errorString();
    const bool replyHadError = (m_speedTestReply->error() != QNetworkReply::NoError);
    m_speedTestReply->deleteLater();
    m_speedTestReply = nullptr;

    if (!m_speedTestRunning) {
        return;
    }

    if (phaseAtFinish == u"Ping"_s) {
        if (!replyHadError) {
            ++m_speedTestPingSampleCount;
            const qint64 elapsedMs = m_speedTestRequestTimer.isValid() ? m_speedTestRequestTimer.elapsed() : 0;
            m_speedTestPingTotalMs += qMax<qint64>(elapsedMs, 1);
            m_speedTestCurrentMbps = static_cast<double>(qMax<qint64>(elapsedMs, 1));
        }
        if (m_speedTestPingSampleCount >= kSpeedTestPingSamples) {
            m_speedTestPingMs = static_cast<int>(m_speedTestPingTotalMs / m_speedTestPingSampleCount);
            m_speedTestElapsedSec = 0;
            emit speedTestChanged();
            startDownloadPhase();
            return;
        }
        if (m_speedTestAttempt >= kSpeedTestMaxAttemptsPerPhase) {
            if (m_speedTestPingSampleCount > 0) {
                m_speedTestPingMs = static_cast<int>(m_speedTestPingTotalMs / m_speedTestPingSampleCount);
                emit speedTestChanged();
                startDownloadPhase();
            } else {
                finishSpeedTest(false, replyHadError ? errorText : u"Ping requests failed."_s);
            }
            return;
        }
        startCurrentSpeedTestRequest();
        return;
    }

    if (phaseAtFinish == u"Download"_s) {
        if (m_speedTestPhaseTimer.isValid()
            && m_speedTestPhaseTimer.elapsed() >= static_cast<qint64>(m_speedTestDurationSec) * 1000) {
            return;
        }

        if (m_speedTestPhaseBytes <= 0 && m_speedTestAttempt >= kSpeedTestMaxAttemptsPerPhase) {
            finishSpeedTest(
                false,
                replyHadError ? errorText : u"Download test returned no data."_s);
            return;
        }

        if (m_speedTestPhaseBytes > 0 && m_speedTestPhaseTimer.isValid()) {
            const double averageMbps = mbpsFromBytes(m_speedTestBytesReceived, m_speedTestPhaseTimer.elapsed());
            m_speedTestDownloadMbps = qMax(m_speedTestDownloadMbps, qMax(m_speedTestPeakMbps, averageMbps));
            emit speedTestChanged();
        }

        startCurrentSpeedTestRequest();
        return;
    }

    if (phaseAtFinish == u"Upload"_s) {
        if (!replyHadError) {
            const qint64 previousBytes = m_speedTestBytesReceived;
            m_speedTestBytesReceived = qMax(m_speedTestBytesReceived, kSpeedTestUploadPayloadBytes);
            m_speedTestPhaseBytes += qMax<qint64>(0, m_speedTestBytesReceived - previousBytes);
        }

        if (m_speedTestPhaseTimer.isValid()
            && m_speedTestPhaseTimer.elapsed() >= static_cast<qint64>(m_speedTestDurationSec) * 1000) {
            return;
        }

        if (m_speedTestPhaseBytes <= 0 && m_speedTestAttempt >= kSpeedTestMaxAttemptsPerPhase) {
            finishSpeedTest(
                false,
                replyHadError ? errorText : u"Upload test returned no data."_s);
            return;
        }

        if (m_speedTestPhaseBytes > 0 && m_speedTestPhaseTimer.isValid()) {
            const double averageMbps = mbpsFromBytes(m_speedTestBytesReceived, m_speedTestPhaseTimer.elapsed());
            m_speedTestUploadMbps = qMax(m_speedTestUploadMbps, qMax(m_speedTestPeakMbps, averageMbps));
            emit speedTestChanged();
        }

        startCurrentSpeedTestRequest();
        return;
    }

    if (replyHadError) {
        finishSpeedTest(false, errorText);
    } else {
        finishSpeedTest(true);
    }
}

void VpnController::onPublicIpFinished()
{
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }

    if (reply != m_publicIpReply) {
        reply->deleteLater();
        return;
    }

    const bool ok = reply->error() == QNetworkReply::NoError;
    QByteArray payload;
    if (reply->isOpen() || reply->bytesAvailable() > 0) {
        payload = reply->readAll();
    }
    const QString ipText = QString::fromUtf8(payload).trimmed();
    const QHostAddress parsed(ipText);

    if (ok && !parsed.isNull()) {
        m_publicIpAddress = ipText;
    } else if (m_publicIpAddress.isEmpty()) {
        m_publicIpAddress.clear();
    }

    m_publicIpRefreshing = false;
    m_publicIpReply = nullptr;
    reply->deleteLater();
    emit publicIpAddressChanged();
}

void VpnController::setConnectionState(ConnectionState state)
{
    if (m_connectionState == state) {
        return;
    }

    m_connectionState = state;
    emit connectionStateChanged();
    applyKillSwitchState();
    QTimer::singleShot(state == ConnectionState::Connected ? 900 : 250, this, [this]() {
        refreshPublicIp();
    });
}

void VpnController::setLastError(const QString& error)
{
    if (m_lastError == error) {
        return;
    }

    m_lastError = error;
    emit lastErrorChanged();
}

void VpnController::appendSystemLog(const QString& message)
{
    if (!m_loggingEnabled) {
        return;
    }
    const bool duplicate = !m_recentLogs.isEmpty() && m_recentLogs.last() == message;
    if (duplicate) {
        return;
    }

    m_recentLogs.append(message);
    while (m_recentLogs.size() > kMaxLogLines) {
        m_recentLogs.removeFirst();
    }
    scheduleLogsChanged();
}

void VpnController::resetSpeedTestState(bool emitSignal)
{
    m_speedTestPhase = u"Idle"_s;
    m_speedTestElapsedSec = 0;
    m_speedTestDurationSec = 0;
    m_speedTestPingMs = -1;
    m_speedTestDownloadMbps = 0.0;
    m_speedTestUploadMbps = 0.0;
    m_speedTestError.clear();
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestBytesReceived = 0;
    m_speedTestLastBytes = 0;
    m_speedTestAttempt = 0;
    m_speedTestPingSampleCount = 0;
    m_speedTestPingTotalMs = 0;
    m_speedTestUploadMode = false;
    m_speedTestPhaseBytes = 0;
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    if (emitSignal) {
        emit speedTestChanged();
    }
}

void VpnController::runProxySelfCheck()
{
    runProxySelfCheckAttempt(0);
}

void VpnController::runProxySelfCheckAttempt(int attempt)
{
    if (!connected()) {
        return;
    }
    const quint16 socksPort = m_buildOptions.socksPort;
    const bool useSystemProxyMode = m_useSystemProxy;
    const bool tunMode = m_tunMode;
    const QPointer<VpnController> guard(this);

    [[maybe_unused]] auto proxySelfCheckFuture = QtConcurrent::run([guard, socksPort, useSystemProxyMode, tunMode, attempt]() {
        QString error;
        const bool ok = checkLocalProxyConnectivitySync(socksPort, &error);
        if (!guard) {
            return;
        }

        QMetaObject::invokeMethod(guard.data(), [guard, socksPort, useSystemProxyMode, tunMode, ok, error, attempt]() {
            if (!guard || !guard->connected()) {
                return;
            }

            if (ok) {
                guard->appendSystemLog(u"[System] Proxy self-test passed (127.0.0.1:%1 is forwarding traffic)."_s
                                           .arg(socksPort));
                if (!useSystemProxyMode && !tunMode) {
                    guard->appendSystemLog(u"[System] Clean mode note: macOS system traffic is NOT auto-routed in this mode."_s);
                }
                return;
            }

            if (attempt + 1 < kProxySelfCheckMaxAttempts) {
                QTimer::singleShot(kProxySelfCheckRetryDelayMs, guard.data(), [guard, attempt]() {
                    if (guard && guard->connected()) {
                        guard->runProxySelfCheckAttempt(attempt + 1);
                    }
                });
                return;
            }

            guard->appendSystemLog(u"[System] Proxy self-test failed: %1"_s.arg(error));
            if (useSystemProxyMode) {
                guard->appendSystemLog(u"[System] Hint: verify system proxy state and retry with proper permissions."_s);
            } else {
                guard->appendSystemLog(u"[System] Hint: Clean mode requires apps to use 127.0.0.1:%1 manually."_s
                                           .arg(socksPort));
            }
        }, Qt::QueuedConnection);
    });
}

bool VpnController::checkLocalProxyConnectivity(QString *errorMessage) const
{
    return checkLocalProxyConnectivitySync(m_buildOptions.socksPort, errorMessage);
}

bool VpnController::detectProcessRoutingSupport()
{
    if (m_processRoutingSupportChecked) {
        return m_processRoutingSupported;
    }

    m_processRoutingSupportChecked = true;
    const bool previous = m_processRoutingSupported;
    m_processRoutingSupported = false;
    const QString previousVersion = m_xrayVersion;
    m_xrayVersion = u"Unknown"_s;

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        m_xrayVersion = u"Not detected"_s;
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return m_processRoutingSupported;
    }

    QProcess process;
    process.start(m_xrayExecutablePath, {u"version"_s});
    if (!process.waitForStarted(2000)) {
        m_xrayVersion = u"Unavailable"_s;
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return m_processRoutingSupported;
    }

    if (!process.waitForFinished(3000)) {
        process.kill();
        process.waitForFinished(500);
        m_xrayVersion = u"Unavailable"_s;
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return m_processRoutingSupported;
    }

    const QString output = QString::fromUtf8(process.readAllStandardOutput())
                           + QString::fromUtf8(process.readAllStandardError());

    const QRegularExpression regex(u"Xray\\s+(\\d+)\\.(\\d+)\\.(\\d+)"_s);
    const QRegularExpressionMatch match = regex.match(output);
    if (match.hasMatch()) {
        m_xrayVersion = u"%1.%2.%3"_s
        .arg(match.captured(1), match.captured(2), match.captured(3));
        const int major = match.captured(1).toInt();
        const int minor = match.captured(2).toInt();
        const int patch = match.captured(3).toInt();

        m_processRoutingSupported =
            major > 26
            || (major == 26 && minor > 1)
            || (major == 26 && minor == 1 && patch >= 23);
    } else if (process.exitCode() == 0) {
        m_xrayVersion = u"Detected"_s;
    } else {
        m_xrayVersion = u"Unavailable"_s;
    }

    if (previousVersion != m_xrayVersion) {
        emit xrayVersionChanged();
    }

    if (previous != m_processRoutingSupported) {
        emit processRoutingSupportChanged();
    }

    return m_processRoutingSupported;
}

QStringList VpnController::parseRules(const QString& value)
{
    const QString normalized = value;
    const QStringList raw = normalized.split(QRegularExpression(u"[,;\\n\\r]+"_s), Qt::SkipEmptyParts);

    QStringList out;
    QSet<QString> seen;
    for (const QString& entry : raw) {
        const QString trimmed = entry.trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }

        const QString key = trimmed.toLower();
        if (seen.contains(key)) {
            continue;
        }

        seen.insert(key);
        out.append(trimmed);
    }

    return out;
}

QString VpnController::normalizeDnsServer(const QString& value)
{
    QString candidate = value.trimmed();
    if (candidate.isEmpty()) {
        return {};
    }

    if (candidate.contains(u"://"_s)) {
        const QUrl parsed(candidate);
        if (parsed.isValid()) {
            if (parsed.host().trimmed().isEmpty()) {
                return {};
            }
            candidate = parsed.host().trimmed();
        }
    }

    if (candidate.startsWith('[') && candidate.contains("]:")) {
        const int closing = candidate.indexOf(']');
        if (closing > 1) {
            candidate = candidate.mid(1, closing - 1).trimmed();
        }
    } else {
        const int firstColon = candidate.indexOf(':');
        const int lastColon = candidate.lastIndexOf(':');
        // Keep raw IPv6, strip host:port.
        if (firstColon > 0 && firstColon == lastColon) {
            const QString hostPart = candidate.left(firstColon).trimmed();
            bool portOk = false;
            candidate.mid(firstColon + 1).toUShort(&portOk);
            if (portOk) {
                candidate = hostPart;
            }
        }
    }

    if (candidate.endsWith('.')) {
        candidate.chop(1);
    }

    if (candidate.isEmpty()) {
        return {};
    }

    QHostAddress ip;
    if (ip.setAddress(candidate)) {
        return ip.toString();
    }

    // Keep hostnames as lowercase for dedupe stability.
    return candidate.toLower();
}

QStringList VpnController::parseDnsServers(const QString& value)
{
    const QStringList raw =
        value.split(QRegularExpression(u"[,;\\n\\r\\t ]+"_s), Qt::SkipEmptyParts);

    QStringList out;
    QSet<QString> seen;
    for (const QString& entry : raw) {
        const QString normalized = normalizeDnsServer(entry);
        if (normalized.isEmpty()) {
            continue;
        }

        const QString key = normalized.toLower();
        if (seen.contains(key)) {
            continue;
        }
        seen.insert(key);
        out.append(normalized);
    }
    return out;
}

void VpnController::updateMemoryUsage()
{
    const qint64 nextBytes = currentProcessMemoryBytes();
    if (nextBytes <= 0 || nextBytes == m_memoryUsageBytes) {
        return;
    }
    m_memoryUsageBytes = nextBytes;
    emit memoryUsageChanged();
}

void VpnController::clearLogsInternal()
{
    if (m_recentLogs.isEmpty() && m_latestLogLine.isEmpty()) {
        return;
    }
    m_recentLogs.clear();
    m_latestLogLine.clear();
    m_logsDirty = false;
    m_logsFlushTimer.stop();
    emit latestLogLineChanged();
    emit logsChanged();
}

void VpnController::clearLogs()
{
    clearLogsInternal();
}

void VpnController::maybeReconnectToPendingProfile()
{
    if (m_pendingReconnectProfileIndex < 0) {
        return;
    }
    if (busy() || m_processManager.isRunning() || m_privilegedTunManaged) {
        return;
    }

    const int reconnectIndex = m_pendingReconnectProfileIndex;
    m_pendingReconnectProfileIndex = -1;
    if (reconnectIndex < 0 || reconnectIndex >= m_profileModel.rowCount()) {
        return;
    }

    QTimer::singleShot(0, this, [this, reconnectIndex]() {
        connectToProfile(reconnectIndex);
    });
}

void VpnController::resetPerProfileUsageSamples()
{
    m_profileUsageLastRxSample = -1;
    m_profileUsageLastTxSample = -1;
}

void VpnController::updatePerProfileUsageCounters(qint64 nextRx, qint64 nextTx)
{
    if (nextRx < 0 || nextTx < 0) {
        return;
    }

    QString profileId = m_activeProfileUsageId.trimmed();
    if (profileId.isEmpty()) {
        profileId = m_currentProfileId.trimmed();
    }
    if (profileId.isEmpty()) {
        const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            profileId = profile->id.trimmed();
        }
    }

    if (profileId.isEmpty()) {
        m_profileUsageLastRxSample = nextRx;
        m_profileUsageLastTxSample = nextTx;
        return;
    }

    if (m_profileUsageLastRxSample < 0 || m_profileUsageLastTxSample < 0) {
        m_profileUsageLastRxSample = nextRx;
        m_profileUsageLastTxSample = nextTx;
        return;
    }

    qint64 rxDelta = nextRx - m_profileUsageLastRxSample;
    qint64 txDelta = nextTx - m_profileUsageLastTxSample;
    m_profileUsageLastRxSample = nextRx;
    m_profileUsageLastTxSample = nextTx;

    // Counter reset/restart protection.
    if (rxDelta < 0) {
        rxDelta = qMax<qint64>(0, nextRx);
    }
    if (txDelta < 0) {
        txDelta = qMax<qint64>(0, nextTx);
    }
    if (rxDelta <= 0 && txDelta <= 0) {
        return;
    }

    recordProfileUsageDelta(profileId, rxDelta, txDelta);
}

void VpnController::recordProfileUsageDelta(const QString& profileId, qint64 rxDelta, qint64 txDelta)
{
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return;
    }

    const qint64 safeRx = qMax<qint64>(0, rxDelta);
    const qint64 safeTx = qMax<qint64>(0, txDelta);
    if (safeRx <= 0 && safeTx <= 0) {
        return;
    }

    QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
    QJsonObject usage = profiles.value(id).toObject();

    const qint64 prevTotalRx = usage.value(u"totalRx"_s).toVariant().toLongLong();
    const qint64 prevTotalTx = usage.value(u"totalTx"_s).toVariant().toLongLong();
    usage.insert(u"totalRx"_s, prevTotalRx + safeRx);
    usage.insert(u"totalTx"_s, prevTotalTx + safeTx);

    const QDateTime now = QDateTime::currentDateTimeUtc();
    addUsageToBucket(&usage, u"hour"_s, usageHourBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, u"day"_s, usageDayBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, u"week"_s, usageWeekBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, u"month"_s, usageMonthBucketKey(now), safeRx, safeTx);
    usage.insert(u"updatedAt"_s, now.toMSecsSinceEpoch());

    auto trimBuckets = [&usage](const QString& bucketName, int keepCount) {
        QJsonObject buckets = usage.value(bucketName).toObject();
        QStringList keys = buckets.keys();
        std::sort(keys.begin(), keys.end(), std::greater<QString>());
        for (int i = keepCount; i < keys.size(); ++i) {
            buckets.remove(keys.at(i));
        }
        usage.insert(bucketName, buckets);
    };
    trimBuckets(u"hour"_s, 24 * 31);
    trimBuckets(u"day"_s, 366);
    trimBuckets(u"week"_s, 104);
    trimBuckets(u"month"_s, 60);

    profiles.insert(id, usage);
    m_profileUsageRoot.insert(u"profiles"_s, profiles);
    scheduleProfileUsageSave();
    if (id.compare(m_currentProfileId.trimmed(), Qt::CaseInsensitive) == 0) {
        emit profileUsageChanged();
    }
}

void VpnController::startProfileUsageSession()
{
    m_profileUsageSessionStartedAt = QDateTime::currentDateTimeUtc();
    m_profileUsageSessionStartRx = qMax<qint64>(0, m_rxBytes);
    m_profileUsageSessionStartTx = qMax<qint64>(0, m_txBytes);
}

void VpnController::finishProfileUsageSession()
{
    const QString id = m_activeProfileUsageId.trimmed();
    if (id.isEmpty() || !m_profileUsageSessionStartedAt.isValid()) {
        return;
    }

    const qint64 rx = qMax<qint64>(0, m_rxBytes - m_profileUsageSessionStartRx);
    const qint64 tx = qMax<qint64>(0, m_txBytes - m_profileUsageSessionStartTx);
    const QDateTime endedAt = QDateTime::currentDateTimeUtc();
    const qint64 durationSec = qMax<qint64>(0, m_profileUsageSessionStartedAt.secsTo(endedAt));

    if (rx > 0 || tx > 0 || durationSec > 0) {
        QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
        QJsonObject usage = profiles.value(id).toObject();
        QJsonArray sessions = usage.value(u"sessions"_s).toArray();
        QJsonObject session;
        session.insert(u"startedAt"_s, m_profileUsageSessionStartedAt.toMSecsSinceEpoch());
        session.insert(u"endedAt"_s, endedAt.toMSecsSinceEpoch());
        session.insert(u"durationSec"_s, durationSec);
        session.insert(u"rx"_s, rx);
        session.insert(u"tx"_s, tx);
        sessions.prepend(session);
        while (sessions.size() > 100) {
            sessions.removeLast();
        }
        usage.insert(u"sessions"_s, sessions);
        profiles.insert(id, usage);
        m_profileUsageRoot.insert(u"profiles"_s, profiles);
        scheduleProfileUsageSave();
        emit profileUsageChanged();
    }

    m_profileUsageSessionStartedAt = QDateTime {};
    m_profileUsageSessionStartRx = 0;
    m_profileUsageSessionStartTx = 0;
}

QVariantMap VpnController::profileUsageSummaryForId(const QString& profileId) const
{
    QVariantMap out;
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return out;
    }

    const QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    if (usage.isEmpty()) {
        return out;
    }

    auto bucketValues = [&usage](const QString& period, const QString& key) -> QPair<qint64, qint64> {
        const QJsonObject buckets = usage.value(period).toObject();
        const QJsonObject entry = buckets.value(key).toObject();
        return {entry.value(u"rx"_s).toVariant().toLongLong(),
                entry.value(u"tx"_s).toVariant().toLongLong()};
    };

    const QDateTime now = QDateTime::currentDateTimeUtc();
    const auto hour = bucketValues(u"hour"_s, usageHourBucketKey(now));
    const auto day = bucketValues(u"day"_s, usageDayBucketKey(now));
    const auto week = bucketValues(u"week"_s, usageWeekBucketKey(now));
    const auto month = bucketValues(u"month"_s, usageMonthBucketKey(now));

    const qint64 totalRx = usage.value(u"totalRx"_s).toVariant().toLongLong();
    const qint64 totalTx = usage.value(u"totalTx"_s).toVariant().toLongLong();

    auto insertPeriod = [&out, this](const QString& name, qint64 rx, qint64 tx) {
        out.insert(name + u"RxBytes"_s, rx);
        out.insert(name + u"TxBytes"_s, tx);
        out.insert(name + u"TotalBytes"_s, rx + tx);
        out.insert(name + u"Text"_s, formatBytes(rx + tx));
    };

    insertPeriod(u"hour"_s, hour.first, hour.second);
    insertPeriod(u"day"_s, day.first, day.second);
    insertPeriod(u"week"_s, week.first, week.second);
    insertPeriod(u"month"_s, month.first, month.second);
    out.insert(u"totalRxBytes"_s, totalRx);
    out.insert(u"totalTxBytes"_s, totalTx);
    out.insert(u"totalBytes"_s, totalRx + totalTx);
    out.insert(u"totalText"_s, formatBytes(totalRx + totalTx));
    out.insert(u"updatedAt"_s,
               usage.value(u"updatedAt"_s).toVariant().toLongLong());
    return out;
}

QVariantList VpnController::profileUsageHistoryForId(const QString& profileId, const QString& period, int limit) const
{
    QVariantList out;
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return out;
    }

    const QString p = period.trimmed().toLower();
    QString bucket;
    if (p == u"hour"_s
        || p == u"day"_s
        || p == u"week"_s
        || p == u"month"_s) {
        bucket = p;
    } else {
        bucket = u"day"_s;
    }

    const QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    const QJsonObject buckets = usage.value(bucket).toObject();
    if (buckets.isEmpty()) {
        return out;
    }

    QStringList keys = buckets.keys();
    std::sort(keys.begin(), keys.end(), std::greater<QString>());

    const int safeLimit = qBound(1, limit, 500);
    const int count = qMin(safeLimit, keys.size());
    out.reserve(count);
    for (int i = 0; i < count; ++i) {
        const QString key = keys.at(i);
        const QJsonObject entry = buckets.value(key).toObject();
        const qint64 rx = entry.value(u"rx"_s).toVariant().toLongLong();
        const qint64 tx = entry.value(u"tx"_s).toVariant().toLongLong();
        QVariantMap row;
        row.insert(u"bucket"_s, bucket);
        row.insert(u"key"_s, key);
        row.insert(u"rxBytes"_s, rx);
        row.insert(u"txBytes"_s, tx);
        row.insert(u"totalBytes"_s, rx + tx);
        row.insert(u"rxText"_s, formatBytes(rx));
        row.insert(u"txText"_s, formatBytes(tx));
        row.insert(u"totalText"_s, formatBytes(rx + tx));
        out.append(row);
    }
    return out;
}

QString VpnController::currentProfileUsageText(const QString& period) const
{
    const QVariantMap summary = currentProfileUsageSummary();
    const QString key = period.trimmed().toLower() + u"Text"_s;
    const QString text = summary.value(key).toString().trimmed();
    return text.isEmpty() ? u"0 B"_s : text;
}

QVariantMap VpnController::currentProfileUsageSummary() const
{
    return profileUsageSummaryForId(currentUsageProfileId());
}

QVariantList VpnController::currentProfileUsageHistory(const QString& period, int limit) const
{
    return profileUsageHistoryForId(currentUsageProfileId(), period, limit);
}

QVariantList VpnController::currentProfileUsageSessions(int limit) const
{
    QVariantList out;
    const QString id = currentUsageProfileId();
    if (id.isEmpty()) {
        return out;
    }
    const QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    const QJsonArray sessions = usage.value(u"sessions"_s).toArray();
    const int count = qMin(qBound(1, limit, 100), sessions.size());
    out.reserve(count);
    for (int i = 0; i < count; ++i) {
        const QJsonObject session = sessions.at(i).toObject();
        const qint64 rx = session.value(u"rx"_s).toVariant().toLongLong();
        const qint64 tx = session.value(u"tx"_s).toVariant().toLongLong();
        const qint64 startedMs = session.value(u"startedAt"_s).toVariant().toLongLong();
        const qint64 endedMs = session.value(u"endedAt"_s).toVariant().toLongLong();
        QVariantMap row;
        row.insert(u"startedAt"_s, QDateTime::fromMSecsSinceEpoch(startedMs, QTimeZone::UTC).toLocalTime().toString(u"yyyy-MM-dd HH:mm"_s));
        row.insert(u"endedAt"_s, QDateTime::fromMSecsSinceEpoch(endedMs, QTimeZone::UTC).toLocalTime().toString(u"HH:mm"_s));
        row.insert(u"durationSec"_s, session.value(u"durationSec"_s).toVariant().toLongLong());
        row.insert(u"rxText"_s, formatBytes(rx));
        row.insert(u"txText"_s, formatBytes(tx));
        row.insert(u"totalText"_s, formatBytes(rx + tx));
        out.append(row);
    }
    return out;
}

void VpnController::clearCurrentProfileUsage()
{
    const QString id = currentUsageProfileId();
    if (id.isEmpty()) {
        return;
    }
    QJsonObject profiles = m_profileUsageRoot.value(u"profiles"_s).toObject();
    profiles.remove(id);
    m_profileUsageRoot.insert(u"profiles"_s, profiles);
    resetPerProfileUsageSamples();
    startProfileUsageSession();
    saveProfileUsage();
    emit profileUsageChanged();
}

void VpnController::clearAllProfileUsage()
{
    m_profileUsageRoot.insert(u"profiles"_s, QJsonObject {});
    resetPerProfileUsageSamples();
    startProfileUsageSession();
    saveProfileUsage();
    emit profileUsageChanged();
}

QVariantList VpnController::availableAppRuleItems() const
{
    QVariantList out;
    QSet<QString> seen;
    auto appendItem = [&out, &seen](const QString& process, const QString& path = QString()) {
        const QString trimmedProcess = process.trimmed();
        if (trimmedProcess.isEmpty()) {
            return;
        }
        const QString key = trimmedProcess.toLower();
        if (seen.contains(key)) {
            return;
        }
        seen.insert(key);
        QVariantMap item;
        item.insert(u"name"_s, QFileInfo(trimmedProcess).completeBaseName().isEmpty()
                                            ? trimmedProcess
                                            : QFileInfo(trimmedProcess).completeBaseName());
        item.insert(u"process"_s, trimmedProcess);
        item.insert(u"path"_s, path.trimmed());
        out.append(item);
    };

#if defined(Q_OS_WIN)
    QProcess process;
    process.start(u"tasklist"_s, {u"/FO"_s, u"CSV"_s, u"/NH"_s});
    if (process.waitForStarted(1200) && process.waitForFinished(2500)) {
        const QStringList lines = QString::fromUtf8(process.readAllStandardOutput()).split('\n', Qt::SkipEmptyParts);
        static const QRegularExpression firstCsvField(u"^\\s*\"([^\"]+)\""_s);
        for (const QString& line : lines) {
            const QRegularExpressionMatch match = firstCsvField.match(line);
            appendItem(match.hasMatch() ? match.captured(1) : line.section(',', 0, 0).remove('"'));
        }
    }
#elif defined(Q_OS_MACOS)
    QProcess process;
    process.start(u"/bin/ps"_s, {u"-axo"_s, u"comm="_s});
    if (process.waitForStarted(1200) && process.waitForFinished(2500)) {
        const QStringList lines = QString::fromUtf8(process.readAllStandardOutput()).split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            const QString path = line.trimmed();
            appendItem(QFileInfo(path).fileName(), path);
        }
    }
    const QStringList appRoots {
        u"/Applications"_s,
        QDir::home().filePath(u"Applications"_s)
    };
    for (const QString& root : appRoots) {
        const QFileInfoList apps = QDir(root).entryInfoList({u"*.app"_s}, QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QFileInfo& app : apps) {
            const QString name = app.completeBaseName();
            appendItem(name, app.absoluteFilePath());
        }
    }
#else
    QProcess process;
    process.start(u"/bin/ps"_s, {u"-eo"_s, u"comm="_s});
    if (process.waitForStarted(1200) && process.waitForFinished(2500)) {
        const QStringList lines = QString::fromUtf8(process.readAllStandardOutput()).split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            appendItem(QFileInfo(line.trimmed()).fileName(), line.trimmed());
        }
    }
#endif

    return out;
}

void VpnController::appendAppRule(const QString& target, const QString& processName)
{
    const QString process = processName.trimmed();
    if (process.isEmpty()) {
        return;
    }

    auto appendRuleText = [&process](QString current) {
        const QStringList existing = parseRules(current);
        for (const QString& item : existing) {
            if (item.compare(process, Qt::CaseInsensitive) == 0) {
                return current;
            }
        }
        if (!current.trimmed().isEmpty() && !current.endsWith('\n')) {
            current.append('\n');
        }
        current.append(process);
        return current;
    };

    const QString normalizedTarget = target.trimmed().toLower();
    if (normalizedTarget == u"proxy"_s || normalizedTarget == u"tunnel"_s) {
        setProxyAppRules(appendRuleText(m_proxyAppRules));
    } else if (normalizedTarget == u"block"_s) {
        setBlockAppRules(appendRuleText(m_blockAppRules));
    } else {
        setDirectAppRules(appendRuleText(m_directAppRules));
    }
}

QString VpnController::currentUsageProfileId() const
{
    QString id = m_currentProfileId.trimmed();
    if (id.isEmpty()) {
        const auto profile = m_profileModel.profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            id = profile->id.trimmed();
        }
    }
    return id;
}

void VpnController::loadProfileUsage()
{
    m_profileUsageRoot = QJsonObject {};
    QFile file(m_profileUsagePath);
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        return;
    }
    m_profileUsageRoot = doc.object();
    if (!m_profileUsageRoot.contains(u"profiles"_s)
        || !m_profileUsageRoot.value(u"profiles"_s).isObject()) {
        m_profileUsageRoot.insert(u"profiles"_s, QJsonObject {});
    }
}

void VpnController::saveProfileUsage() const
{
    if (m_profileUsagePath.trimmed().isEmpty()) {
        return;
    }

    QSaveFile file(m_profileUsagePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }

    file.write(QJsonDocument(m_profileUsageRoot).toJson(QJsonDocument::Compact));
    file.commit();
}

void VpnController::scheduleProfileUsageSave()
{
    if (!m_profileUsageSaveTimer.isActive()) {
        m_profileUsageSaveTimer.start();
    }
}

void VpnController::killProcessByPid(qint64 pid) const
{
    if (pid <= 0) {
        return;
    }

#if defined(Q_OS_WIN)
    QProcess::execute(
        u"taskkill"_s,
        {u"/PID"_s, QString::number(pid), u"/T"_s, u"/F"_s});
#else
    ::kill(static_cast<pid_t>(pid), SIGTERM);
    QThread::msleep(120);
    ::kill(static_cast<pid_t>(pid), SIGKILL);
#endif
}

void VpnController::stopPrivilegedTunRuntimeByPidPath()
{
    QFile pidFile(m_privilegedTunPidPath);
    if (!pidFile.exists()) {
        return;
    }
    if (!pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QFile::remove(m_privilegedTunPidPath);
        return;
    }

    bool ok = false;
    const qint64 pid = QString::fromUtf8(pidFile.readAll()).trimmed().toLongLong(&ok);
    pidFile.close();
    if (ok && pid > 0) {
        killProcessByPid(pid);
    }
    QFile::remove(m_privilegedTunPidPath);
}

void VpnController::cleanupDetachedHelpers()
{
    stopPrivilegedTunRuntimeByPidPath();

    if (m_privilegedTunHelperReady) {
        shutdownPrivilegedTunHelper();
    }
    if (m_privilegedTunHelperPid > 0) {
        killProcessByPid(m_privilegedTunHelperPid);
        m_privilegedTunHelperPid = 0;
    }
}

void VpnController::applySystemProxy(bool enable, bool force)
{
    if (!m_useSystemProxy && !m_killSwitchEnabled && enable) {
        return;
    }

    if (!force && m_systemProxyApplied == enable && !m_proxyApplyInFlight) {
        return;
    }

    if (m_proxyApplyInFlight) {
        m_pendingProxyApplyState = enable ? 1 : 0;
        m_pendingProxyApplyForce = m_pendingProxyApplyForce || force;
        return;
    }

    const bool previousAppliedState = m_systemProxyApplied;

    const auto finalizeResult = [this, previousAppliedState](const ProxyApplyResult& result) {
        m_proxyApplyInFlight = false;

        if (result.ok) {
            m_systemProxyApplied = result.enable;
            if (result.enable && (!previousAppliedState || result.enable != previousAppliedState)) {
                appendSystemLog(u"[System] System proxy enabled."_s);
            } else if (!result.enable && previousAppliedState) {
                appendSystemLog(u"[System] System proxy disabled."_s);
            }
        } else if (!result.error.trimmed().isEmpty()) {
            const QString message = result.enable
                                        ? u"Connected, but failed to enable system proxy: %1"_s
                                              .arg(result.error.trimmed())
                                        : u"Failed to disable system proxy: %1"_s
                                              .arg(result.error.trimmed());
            appendSystemLog(u"[System] %1"_s.arg(message));
            if (result.enable) {
                setLastError(message);
            } else {
                setLastError(QString());
            }
        }

        if (m_pendingProxyApplyState >= 0) {
            const bool pendingEnable = (m_pendingProxyApplyState == 1);
            const bool pendingForce = m_pendingProxyApplyForce;
            m_pendingProxyApplyState = -1;
            m_pendingProxyApplyForce = false;
            applySystemProxy(pendingEnable, pendingForce);
        }
    };

    const auto runOperation = [enable, force, socksPort = m_buildOptions.socksPort, httpPort = m_buildOptions.httpPort]() {
        ProxyApplyResult result;
        result.enable = enable;
        SystemProxyManager manager;
        QString error;
        result.ok = enable
                        ? manager.enable(socksPort, httpPort, &error)
                        : manager.disable(&error, true);
        result.error = error.trimmed();
        return result;
    };

    if (QCoreApplication::closingDown()) {
        finalizeResult(runOperation());
        return;
    }

    m_proxyApplyInFlight = true;
    QPointer<VpnController> guard(this);
    [[maybe_unused]] auto proxyApplyFuture = QtConcurrent::run([guard, runOperation, finalizeResult]() {
        const ProxyApplyResult result = runOperation();
        if (!guard) {
            return;
        }
        QMetaObject::invokeMethod(guard.data(), [guard, result, finalizeResult]() {
            if (!guard) {
                return;
            }
            finalizeResult(result);
        }, Qt::QueuedConnection);
    });
}

void VpnController::applyKillSwitchState(const QString& reason)
{
    if (!reason.trimmed().isEmpty()) {
        appendSystemLog(u"[System] %1"_s.arg(reason.trimmed()));
    }

    if (!m_killSwitchEnabled) {
        if (!connected() && !busy() && !m_useSystemProxy && m_systemProxyApplied) {
            applySystemProxy(false, true);
        }
        return;
    }

    if (connected()) {
        applySystemProxy(true);
        return;
    }

    if (!busy()) {
        applySystemProxy(true, true);
    }
}

bool VpnController::queryTrafficStatsFromApi(qint64 *uplinkBytes, qint64 *downlinkBytes, QString *errorMessage)
{
    return queryTrafficStatsFromApiSync(
        m_xrayExecutablePath,
        m_buildOptions.apiPort,
        uplinkBytes,
        downlinkBytes,
        errorMessage);
}

QString VpnController::privilegedTunHelperPath() const
{
#if defined(Q_OS_WIN)
    return QDir(QCoreApplication::applicationDirPath()).filePath(u"GenyConnectTunHelper.exe"_s);
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(u"GenyConnectTunHelper"_s);
#endif
}

bool VpnController::sendPrivilegedTunHelperRequest(
    const QJsonObject& request,
    QJsonObject *response,
    QString *errorMessage,
    int timeoutMs)
{
    const int safeTimeoutMs = qBound(1000, timeoutMs, 120000);
    if (m_privilegedTunHelperPort == 0 || m_privilegedTunHelperToken.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"Privileged helper is not initialized."_s;
        }
        return false;
    }

    QJsonObject payload = request;
    payload.insert(u"token"_s, m_privilegedTunHelperToken);

    QTcpSocket socket;
    socket.connectToHost(QHostAddress::LocalHost, m_privilegedTunHelperPort);
    {
        QElapsedTimer connectTimer;
        connectTimer.start();
        while (socket.state() != QAbstractSocket::ConnectedState && connectTimer.elapsed() < qMin(3000, safeTimeoutMs)) {
            socket.waitForConnected(40);
            QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
        }
    }
    if (socket.state() != QAbstractSocket::ConnectedState) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = u"Could not connect to privileged helper."_s;
        }
        return false;
    }

    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact) + '\n';
    if (socket.write(body) < 0) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = u"Failed to send request to privileged helper."_s;
        }
        return false;
    }
    {
        QElapsedTimer writeTimer;
        writeTimer.start();
        while (socket.bytesToWrite() > 0 && writeTimer.elapsed() < qMin(3000, safeTimeoutMs)) {
            socket.waitForBytesWritten(40);
            QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
        }
    }
    if (socket.bytesToWrite() > 0) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = u"Failed to send request to privileged helper."_s;
        }
        return false;
    }

    QByteArray replyBuffer;
    QElapsedTimer timer;
    timer.start();
    bool sawData = false;
    bool disconnectedBeforeReply = false;
    while (!replyBuffer.contains('\n') && timer.elapsed() < safeTimeoutMs) {
        if (socket.bytesAvailable() <= 0) {
            socket.waitForReadyRead(40);
            QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
            if (socket.state() == QAbstractSocket::UnconnectedState && socket.bytesAvailable() <= 0) {
                disconnectedBeforeReply = true;
                break;
            }
            if (socket.bytesAvailable() <= 0) {
                continue;
            }
        }
        const QByteArray chunk = socket.readAll();
        if (!chunk.isEmpty()) {
            sawData = true;
            replyBuffer.append(chunk);
        } else if (socket.state() == QAbstractSocket::UnconnectedState) {
            disconnectedBeforeReply = true;
            break;
        }
    }

    const int nl = replyBuffer.indexOf('\n');
    const QByteArray replyLine = (nl >= 0 ? replyBuffer.left(nl) : replyBuffer).trimmed();
    if (replyLine.isEmpty()) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            if (timer.elapsed() >= safeTimeoutMs) {
                *errorMessage = u"Timed out waiting for privileged helper response."_s;
            } else if (disconnectedBeforeReply) {
                *errorMessage = u"Privileged helper disconnected before sending a response."_s;
            } else if (!sawData) {
                *errorMessage = u"Privileged helper returned no data."_s;
            } else {
                *errorMessage = u"Privileged helper returned an empty response."_s;
            }
        }
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument replyDoc = QJsonDocument::fromJson(replyLine, &parseError);
    if (parseError.error != QJsonParseError::NoError || !replyDoc.isObject()) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            QString preview = QString::fromUtf8(replyLine);
            if (preview.size() > 180) {
                preview = preview.left(180) + u"..."_s;
            }
            *errorMessage = u"Privileged helper returned invalid JSON: %1"_s.arg(preview);
        }
        return false;
    }

    const QJsonObject responseObject = replyDoc.object();
    bool helperPidOk = false;
    const qint64 helperPid = responseObject.value(u"helper_pid"_s).toVariant().toLongLong(&helperPidOk);
    if (helperPidOk && helperPid > 0) {
        m_privilegedTunHelperPid = helperPid;
    }
    m_privilegedTunHelperReady = true;

    if (response) {
        *response = responseObject;
    }
    return true;
}

bool VpnController::ensurePrivilegedTunHelper(QString *errorMessage)
{
    auto helperResponding = [this]() -> bool {
        QJsonObject response;
        QString pingError;
        if (!sendPrivilegedTunHelperRequest(QJsonObject{{u"action"_s, u"ping"_s}},
                                            &response,
                                            &pingError,
                                            2500)) {
            return false;
        }
        return response.value(u"ok"_s).toBool(false);
    };

    if (m_privilegedTunHelperReady && helperResponding()) {
        return true;
    }

    const QString helperPath = privilegedTunHelperPath();
    if (helperPath.trimmed().isEmpty() || !QFileInfo::exists(helperPath)) {
        if (errorMessage) {
            *errorMessage = u"Privileged helper executable not found: %1"_s.arg(helperPath);
        }
        return false;
    }

    const QString tokenPartA = QString::number(QRandomGenerator::global()->generate64(), 16);
    const QString tokenPartB = QString::number(QRandomGenerator::global()->generate64(), 16);
    m_privilegedTunHelperToken = tokenPartA + tokenPartB;
    m_privilegedTunHelperReady = false;
    m_privilegedTunHelperPid = 0;

    QString launchError;
    bool started = false;
    for (int attempt = 0; attempt < 8 && !started; ++attempt) {
        m_privilegedTunHelperPort = selectAvailableLocalPort();
        if (m_privilegedTunHelperPort == 0) {
            launchError = u"Failed to allocate local port for privileged TUN helper."_s;
            continue;
        }
        const QStringList launchArgs = {
            u"--listen-port"_s, QString::number(m_privilegedTunHelperPort),
            u"--token"_s, m_privilegedTunHelperToken,
            u"--idle-timeout-ms"_s, u"604800000"_s
        };

#if defined(Q_OS_MACOS)
        const QString command = quoteForShell(helperPath)
                                + u" "_s
                                + joinQuotedArgsForShell(launchArgs)
                                + u" >/dev/null 2>&1 &"_s;
        const QString script = u"do shell script \"%1\" with administrator privileges"_s
                                   .arg(escapeForAppleScriptString(command));
        QProcess process;
        process.start(u"/usr/bin/osascript"_s, {u"-e"_s, script});
        if (!process.waitForStarted(5000)) {
            launchError = u"Failed to open macOS elevation prompt for TUN helper."_s;
            continue;
        }
        if (!waitForProcessFinishedResponsive(process, 60000)) {
            process.kill();
            waitForProcessFinishedResponsive(process, 1000);
            launchError = u"macOS elevation prompt timed out for TUN helper."_s;
            continue;
        }
        if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
            const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
            launchError = stderrText.isEmpty()
                              ? u"macOS elevation for TUN helper was canceled."_s
                              : u"macOS elevation for TUN helper failed: %1"_s.arg(stderrText);
            continue;
        }
        started = true;
#elif defined(Q_OS_WIN)
        const QString psArgArray = toPowerShellArgumentArrayLiteral(launchArgs);
        const QString command = u"Start-Process -Verb RunAs -WindowStyle Hidden -FilePath %1 -ArgumentList %2"_s
                                    .arg(quoteForPowerShellSingleQuoted(helperPath), psArgArray);
        qint64 detachedPid = 0;
        if (!QProcess::startDetached(
                u"powershell"_s,
                {u"-NoProfile"_s, u"-ExecutionPolicy"_s, u"Bypass"_s,
                 u"-Command"_s, command},
                QString(),
                &detachedPid)) {
            launchError = u"Failed to request Windows UAC for TUN helper."_s;
            continue;
        }
        if (detachedPid > 0) {
            m_privilegedTunHelperPid = detachedPid;
        }
        started = true;
#elif defined(Q_OS_LINUX)
        if (QStandardPaths::findExecutable(u"pkexec"_s).isEmpty()) {
            launchError = u"pkexec is required for TUN helper on Linux."_s;
            continue;
        }
        QStringList pkexecArgs;
        pkexecArgs << helperPath;
        pkexecArgs << launchArgs;
        qint64 detachedPid = 0;
        if (!QProcess::startDetached(u"pkexec"_s, pkexecArgs, QString(), &detachedPid)) {
            launchError = u"Failed to request elevation for Linux TUN helper."_s;
            continue;
        }
        if (detachedPid > 0) {
            m_privilegedTunHelperPid = detachedPid;
        }
        started = true;
#else
        launchError = u"Privileged TUN helper is not implemented on this platform."_s;
        Q_UNUSED(launchArgs)
#endif
    }

    if (!started) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = launchError.isEmpty()
            ? u"Failed to launch privileged TUN helper."_s
            : launchError;
        }
        return false;
    }

    bool ready = false;
    QString lastPingError;
    for (int i = 0; i < 35; ++i) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
        QThread::msleep(80);
        QJsonObject response;
        if (sendPrivilegedTunHelperRequest(QJsonObject{{u"action"_s, u"ping"_s}},
                                           &response,
                                           &lastPingError,
                                           2500)
            && response.value(u"ok"_s).toBool(false)) {
            ready = true;
            break;
        }
    }

    if (!ready) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = lastPingError.isEmpty()
            ? u"Timed out waiting for privileged TUN helper to start."_s
            : u"Privileged TUN helper did not respond: %1"_s.arg(lastPingError);
        }
        return false;
    }

    m_privilegedTunHelperReady = true;
    return true;
}

void VpnController::shutdownPrivilegedTunHelper()
{
    if (!m_privilegedTunHelperReady) {
        if (m_privilegedTunHelperPid > 0) {
            killProcessByPid(m_privilegedTunHelperPid);
            m_privilegedTunHelperPid = 0;
        }
        return;
    }
    QString ignoredError;
    QJsonObject ignoredResponse;
    const bool sent = sendPrivilegedTunHelperRequest(
        QJsonObject{{u"action"_s, u"shutdown"_s}},
        &ignoredResponse,
        &ignoredError,
        2000);
    if (!sent && m_privilegedTunHelperPid > 0) {
        killProcessByPid(m_privilegedTunHelperPid);
    }
    m_privilegedTunHelperReady = false;
    m_privilegedTunHelperPort = 0;
    m_privilegedTunHelperToken.clear();
    m_privilegedTunHelperPid = 0;
}

bool VpnController::requestElevationForTun(QString *errorMessage)
{
    const QString executablePath = QCoreApplication::applicationFilePath();
    if (executablePath.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"Cannot relaunch with elevation: executable path is empty."_s;
        }
        return false;
    }

    QStringList args = QCoreApplication::arguments();
    if (!args.isEmpty()) {
        args.removeFirst();
    }
    if (!args.contains(u"--geny-elevated-tun"_s)) {
        args.append(u"--geny-elevated-tun"_s);
    }

#if defined(Q_OS_MACOS)
    const QString command = quoteForShell(executablePath)
                            + u" "_s
                            + joinQuotedArgsForShell(args)
                            + u" >/dev/null 2>&1 &"_s;
    const QString script = u"do shell script \"%1\" with administrator privileges"_s
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(u"/usr/bin/osascript"_s, {u"-e"_s, script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = u"Failed to start macOS elevation prompt."_s;
        }
        return false;
    }
    if (!waitForProcessFinishedResponsive(process, 60000)) {
        process.kill();
        waitForProcessFinishedResponsive(process, 1000);
        if (errorMessage) {
            *errorMessage = u"macOS elevation prompt timed out."_s;
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? u"macOS elevation request was canceled or failed."_s
            : u"macOS elevation failed: %1"_s.arg(stderrText);
        }
        return false;
    }
    return true;
#elif defined(Q_OS_WIN)
    const QString argClause = args.isEmpty()
                                  ? QString()
                                  : u" -ArgumentList %1"_s.arg(toPowerShellArgumentArrayLiteral(args));
    const QString command =
        u"Start-Process -Verb RunAs -FilePath %1%2"_s
            .arg(quoteForPowerShellSingleQuoted(executablePath), argClause);
    if (!QProcess::startDetached(
            u"powershell"_s,
            {u"-NoProfile"_s, u"-ExecutionPolicy"_s, u"Bypass"_s,
             u"-Command"_s, command})) {
        if (errorMessage) {
            *errorMessage = u"Failed to request Windows UAC elevation."_s;
        }
        return false;
    }
    return true;
#elif defined(Q_OS_LINUX)
    if (QStandardPaths::findExecutable(u"pkexec"_s).isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"pkexec is not available. Install polkit tools or run GenyConnect as root for TUN mode."_s;
        }
        return false;
    }

    QStringList launchArgs;
    launchArgs << executablePath;
    launchArgs << args;
    if (!QProcess::startDetached(u"pkexec"_s, launchArgs)) {
        if (errorMessage) {
            *errorMessage = u"Failed to request Linux elevation (pkexec)."_s;
        }
        return false;
    }
    return true;
#else
    if (errorMessage) {
        *errorMessage = u"TUN elevation flow is not implemented on this platform."_s;
    }
    return false;
#endif
}

bool VpnController::startPrivilegedTunProcess(QString *errorMessage)
{
    QFile::remove(m_privilegedTunPidPath);
    QFile::remove(m_privilegedTunLogPath);
    m_privilegedTunLogOffset = 0;
    m_privilegedTunLogBuffer.clear();

    const QString serverText = m_activeProfileAddress.trimmed();
    const QHostAddress parsed(serverText);
    m_lastTunServerIp = (!parsed.isNull() && parsed.protocol() == QAbstractSocket::IPv4Protocol)
                            ? serverText
                            : QString();

    if (!ensurePrivilegedTunHelper(errorMessage)) {
        return false;
    }

    const QString tunIf = m_selectedTunInterfaceName.trimmed();
#if defined(Q_OS_MACOS)
    if (m_tunMode && tunIf.isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"TUN start failed: missing interface name."_s;
        }
        return false;
    }
#endif

    QJsonObject response;
    QString helperError;
    if (!sendPrivilegedTunHelperRequest(
            QJsonObject{
                {u"action"_s, u"start_tun"_s},
                {u"xray_path"_s, m_xrayExecutablePath},
                {u"config_path"_s, m_runtimeConfigPath},
                {u"pid_path"_s, m_privilegedTunPidPath},
                {u"log_path"_s, m_privilegedTunLogPath},
                {u"tun_if"_s, tunIf},
                {u"server_ip"_s, m_lastTunServerIp},
                {u"server_host"_s, m_activeProfileAddress.trimmed()},
                {u"dns_servers"_s, QJsonArray::fromStringList(parseDnsServers(m_customDnsServers))}
            },
            &response,
            &helperError,
            90000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? u"Privileged helper failed to start TUN runtime."_s
            : helperError;
        }
        return false;
    }

    if (!response.value(u"ok"_s).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(u"message"_s).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = u"Privileged helper rejected TUN start."_s;
            }
        }
        return false;
    }

    QFile pidFile(m_privilegedTunPidPath);
    if (!pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        if (errorMessage) {
            *errorMessage = u"TUN start failed: pid file was not created."_s;
        }
        return false;
    }
    const QString pidText = QString::fromUtf8(pidFile.readAll()).trimmed();
    pidFile.close();
    if (pidText.isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"TUN start failed: invalid process id."_s;
        }
        return false;
    }

    // Do not report Connected until xray mixed port is actually reachable.
    // This prevents false "connected" state when xray exits right after launch
    // (for example: TUN init failure / adapter creation issues).
    bool ready = false;
    QString lastCheckError;
    QElapsedTimer readyTimer;
    readyTimer.start();
    while (readyTimer.elapsed() < 12000) {
        QString checkError;
        if (checkLocalProxyConnectivitySync(m_buildOptions.socksPort, &checkError)) {
            ready = true;
            break;
        }
        lastCheckError = checkError;
        QThread::msleep(180);
    }

    if (!ready) {
        QString tailLine;
        QFile logFile(m_privilegedTunLogPath);
        if (logFile.open(QIODevice::ReadOnly)) {
            const QByteArray all = logFile.readAll();
            const QList<QByteArray> lines = all.split('\n');
            for (int i = lines.size() - 1; i >= 0; --i) {
                const QString candidate = QString::fromUtf8(lines[i]).trimmed();
                if (!candidate.isEmpty()) {
                    tailLine = candidate;
                    break;
                }
            }
        }

        QString stopError;
        Q_UNUSED(stopPrivilegedTunProcess(&stopError));
        if (errorMessage) {
            if (!tailLine.isEmpty()) {
                *errorMessage = u"TUN startup failed: %1"_s.arg(tailLine);
            } else if (!lastCheckError.trimmed().isEmpty()) {
                *errorMessage = u"TUN startup failed: %1"_s.arg(lastCheckError.trimmed());
            } else {
                *errorMessage = u"TUN startup failed: xray local mixed port was not reachable in time."_s;
            }
        }
        return false;
    }
    return true;
}

bool VpnController::stopPrivilegedTunProcess(QString *errorMessage)
{
    if (!m_privilegedTunHelperReady) {
        m_lastTunServerIp.clear();
        return true;
    }

    QJsonObject response;
    QString helperError;
    if (!sendPrivilegedTunHelperRequest(
            QJsonObject{
                {u"action"_s, u"stop_tun"_s},
                {u"pid_path"_s, m_privilegedTunPidPath},
                {u"tun_if"_s, m_selectedTunInterfaceName.trimmed()},
                {u"server_ip"_s, m_lastTunServerIp.trimmed()}
            },
            &response,
            &helperError,
            10000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? u"Privileged helper failed to stop TUN runtime."_s
            : helperError;
        }
        return false;
    }

    if (!response.value(u"ok"_s).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(u"message"_s).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = u"Privileged helper rejected TUN stop."_s;
            }
        }
        return false;
    }

    m_lastTunServerIp.clear();
    return true;
}

void VpnController::pollPrivilegedTunLogs()
{
    if (!m_privilegedTunManaged || !m_loggingEnabled) {
        return;
    }

    QFile file(m_privilegedTunLogPath);
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    if (m_privilegedTunLogOffset > file.size()) {
        m_privilegedTunLogOffset = 0;
        m_privilegedTunLogBuffer.clear();
    }
    if (!file.seek(m_privilegedTunLogOffset)) {
        return;
    }

    const QByteArray chunk = file.readAll();
    m_privilegedTunLogOffset = file.pos();
    file.close();
    if (chunk.isEmpty()) {
        return;
    }

    m_privilegedTunLogBuffer.append(chunk);
    if (m_privilegedTunLogBuffer.size() > kMaxPrivilegedTunLogBufferBytes) {
        m_privilegedTunLogBuffer = m_privilegedTunLogBuffer.right(kPrivilegedTunLogBufferKeepBytes);
        appendSystemLog(u"[System] Log stream is very busy. Older lines were trimmed to keep UI responsive."_s);
    }

    int processedLines = 0;
    int newLineIndex = m_privilegedTunLogBuffer.indexOf('\n');
    while (newLineIndex >= 0 && processedLines < kMaxPrivilegedTunLogLinesPerTick) {
        const QByteArray lineBytes = m_privilegedTunLogBuffer.left(newLineIndex).trimmed();
        m_privilegedTunLogBuffer.remove(0, newLineIndex + 1);
        if (!lineBytes.isEmpty()) {
            onLogLine(QString::fromUtf8(lineBytes));
        }
        ++processedLines;
        newLineIndex = m_privilegedTunLogBuffer.indexOf('\n');
    }
}

bool VpnController::applyMacTunRoutes(QString *errorMessage)
{
#if defined(Q_OS_MACOS)
    const QString tunIf = m_selectedTunInterfaceName.trimmed();
    if (tunIf.isEmpty()) {
        if (errorMessage) {
            *errorMessage = u"TUN route setup failed: missing interface name."_s;
        }
        return false;
    }

    QString serverIp = m_activeProfileAddress.trimmed();
    QHostAddress parsed(serverIp);
    if (parsed.isNull() || parsed.protocol() != QAbstractSocket::IPv4Protocol) {
        const QHostInfo info = QHostInfo::fromName(serverIp);
        for (const QHostAddress& addr : info.addresses()) {
            if (addr.protocol() == QAbstractSocket::IPv4Protocol) {
                serverIp = addr.toString();
                parsed = addr;
                break;
            }
        }
    }

    QString hostRouteCmd;
    if (!parsed.isNull() && parsed.protocol() == QAbstractSocket::IPv4Protocol) {
        m_lastTunServerIp = serverIp;
        hostRouteCmd =
            QString::fromUtf8("GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}'); "
                           "if [ -n \"$GW\" ]; then route -n add -host %1 \"$GW\" >/dev/null 2>&1 || true; fi;")
                .arg(serverIp);
    } else {
        m_lastTunServerIp.clear();
    }

    const QString command =
        hostRouteCmd
        + QString::fromUtf8("route -n add -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                         "route -n add -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
              .arg(tunIf);

    const QString script = u"do shell script \"%1\" with administrator privileges"_s
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(u"/usr/bin/osascript"_s, {u"-e"_s, script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = u"Failed to request permissions for TUN route setup."_s;
        }
        return false;
    }
    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished(1000);
        if (errorMessage) {
            *errorMessage = u"Timed out while applying TUN routes."_s;
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? u"Failed to apply macOS TUN routes."_s
            : u"Failed to apply macOS TUN routes: %1"_s.arg(stderrText);
        }
        return false;
    }
    return true;
#else
    Q_UNUSED(errorMessage)
    return true;
#endif
}

void VpnController::clearMacTunRoutes()
{
#if defined(Q_OS_MACOS)
    const QString tunIf = m_selectedTunInterfaceName.trimmed();
    if (tunIf.isEmpty()) {
        return;
    }
    const QString hostDelete = m_lastTunServerIp.trimmed().isEmpty()
                                   ? QString()
                                   : u"route -n delete -host %1 >/dev/null 2>&1 || true;"_s.arg(m_lastTunServerIp.trimmed());
    const QString command =
        hostDelete
        + QString::fromUtf8("route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                         "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
              .arg(tunIf);
    const QString script = u"do shell script \"%1\" with administrator privileges"_s
                               .arg(escapeForAppleScriptString(command));
    QProcess::execute(u"/usr/bin/osascript"_s, {u"-e"_s, script});
    m_lastTunServerIp.clear();
#endif
}

bool VpnController::writeRuntimeConfig(const ServerProfile& profile, QString *errorMessage)
{
    XrayConfigBuilder::BuildOptions options = m_buildOptions;
    options.enableTun = m_tunMode;
    options.tunAutoRoute = true;
    options.tunStrictRoute = true;
    options.tunInterfaceName = m_tunMode ? selectTunInterfaceName() : QString();
    options.dnsServers = parseDnsServers(m_customDnsServers);
    m_selectedTunInterfaceName = options.tunInterfaceName;
    options.whitelistMode = m_whitelistMode;
    options.proxyDomains = parseRules(m_proxyDomainRules);
    options.directDomains = parseRules(m_directDomainRules);
    options.blockDomains = parseRules(m_blockDomainRules);
    options.proxyProcesses = parseRules(m_proxyAppRules);
    options.directProcesses = parseRules(m_directAppRules);
    options.blockProcesses = parseRules(m_blockAppRules);

    const bool hasAppRules = !options.proxyProcesses.isEmpty()
                             || !options.directProcesses.isEmpty()
                             || !options.blockProcesses.isEmpty();

    options.enableProcessRouting = detectProcessRoutingSupport();
    if (hasAppRules && !options.enableProcessRouting) {
        appendSystemLog(u"[System] App rules ignored: current xray-core does not support process routing (requires Xray 26.1.23+)."_s);
    }

    QJsonObject config = XrayConfigBuilder::build(profile, options);
    if (options.enableTun) {
        ensureTunDnsSupport(&config, parseDnsServers(m_customDnsServers));
        // Ensure noisy link-local/broadcast packets are blocked in TUN mode.
        // This prevents direct-route packet loops that can spike xray CPU usage.
        ensureTunNoiseBlockRules(&config);
    }

    if (m_tunMode && !options.tunInterfaceName.trimmed().isEmpty()) {
        appendSystemLog(u"[System] TUN interface selected: %1"_s.arg(options.tunInterfaceName));
    }

    QSaveFile file(m_runtimeConfigPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (errorMessage) {
            *errorMessage = u"Failed to open config file: %1"_s.arg(m_runtimeConfigPath);
        }
        return false;
    }

    const QJsonDocument doc(config);
    file.write(doc.toJson(QJsonDocument::Indented));

    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = u"Failed to write config file to disk."_s;
        }
        return false;
    }

    return true;
}

QString VpnController::detectDefaultXrayPath() const
{
    QStringList candidates;

    const QString appDir = QCoreApplication::applicationDirPath();
#ifdef Q_OS_WIN
    candidates << QDir(appDir).filePath(u"xray-core.exe"_s);
    candidates << QDir(appDir).filePath(u"xray.exe"_s);
#else
    candidates << QDir(appDir).filePath(u"xray-core"_s);
    candidates << QDir(appDir).filePath(u"xray"_s);
#endif

    for (const QString& path : std::as_const(candidates)) {
        QFileInfo info(path);
        if (info.exists() && info.isFile()) {
            return path;
        }
    }

    const QStringList executableCandidates {
#ifdef Q_OS_WIN
        u"xray-core.exe"_s,
        u"xray.exe"_s,
#else
        u"xray-core"_s,
        u"xray"_s,
#endif
    };

    for (const QString &candidate : executableCandidates) {
        const QString path = QStandardPaths::findExecutable(candidate);
        if (!path.isEmpty()) {
            return path;
        }
    }

    return QString();
}

void VpnController::loadProfiles()
{
    QFile file(m_profilesPath);
    if (!file.exists()) {
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isArray()) {
        return;
    }

    QList<ServerProfile> loadedProfiles;
    for (const QJsonValue &value : doc.array()) {
        if (!value.isObject()) {
            continue;
        }

        auto profile = ServerProfile::fromJson(value.toObject());
        if (profile.has_value()) {
            auto normalized = profile.value();
            normalized.groupName = normalizeGroupName(normalized.groupName);
            if (normalized.sourceName.trimmed().isEmpty()) {
                normalized.sourceName = u"Manual import"_s;
            }
            if (normalized.sourceId.trimmed().isEmpty()) {
                normalized.sourceId = u"manual"_s;
            }
            loadedProfiles.append(normalized);
        }
    }

    m_profileModel.setProfiles(loadedProfiles);
    if (m_autoPingProfiles && !loadedProfiles.isEmpty()) {
        QTimer::singleShot(50, this, [this]() { pingAllProfiles(); });
    }
}

void VpnController::loadSubscriptions()
{
    QFile file(m_subscriptionsPath);
    if (!file.exists()) {
        return;
    }
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isArray()) {
        return;
    }

    QList<SubscriptionEntry> loaded;
    QSet<QString> seenUrls;

    for (const QJsonValue& value : doc.array()) {
        SubscriptionEntry entry;

        if (value.isString()) {
            const QString url = value.toString().trimmed();
            if (url.isEmpty()) {
                continue;
            }
            entry.id = createSubscriptionId();
            entry.url = url;
            entry.name = deriveSubscriptionName(url);
            entry.group = normalizeGroupName(QString());
        } else if (value.isObject()) {
            const QJsonObject obj = value.toObject();
            entry.id = obj.value(u"id"_s).toString().trimmed();
            entry.url = obj.value(u"url"_s).toString().trimmed();
            entry.name = obj.value(u"name"_s).toString().trimmed();
            entry.group = obj.value(u"group"_s).toString().trimmed();
        } else {
            continue;
        }

        if (entry.id.isEmpty()) {
            entry.id = createSubscriptionId();
        }

        entry.url = entry.url.trimmed();
        entry.name = normalizeSubscriptionNameValue(entry.name, entry.url);
        entry.group = normalizeGroupName(entry.group);

        const QString url = entry.url;
        const QUrl parsedUrl(url);
        if (!parsedUrl.isValid()
            || (parsedUrl.scheme() != u"http"_s && parsedUrl.scheme() != u"https"_s)) {
            continue;
        }

        const QString dedupKey = parsedUrl.toString(QUrl::FullyEncoded).toLower();
        if (seenUrls.contains(dedupKey)) {
            continue;
        }
        seenUrls.insert(dedupKey);

        entry.url = parsedUrl.toString(QUrl::FullyEncoded);
        loaded.append(entry);
    }

    m_subscriptionEntries = loaded;
}

void VpnController::saveProfiles() const
{
    QJsonArray arr;
    const auto allProfiles = m_profileModel.profiles();
    for (const auto &profile : allProfiles) {
        arr.append(profile.toJson());
    }

    QSaveFile file(m_profilesPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }

    file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    file.commit();
}

void VpnController::saveSubscriptions() const
{
    QJsonArray arr;
    for (const SubscriptionEntry& entry : m_subscriptionEntries) {
        QJsonObject obj;
        obj[u"id"_s] = entry.id;
        obj[u"name"_s] = entry.name;
        obj[u"group"_s] = entry.group;
        obj[u"url"_s] = entry.url;
        arr.append(obj);
    }

    QSaveFile file(m_subscriptionsPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    file.commit();
}

void VpnController::loadSettings()
{
    QSettings settings;
    m_xrayExecutablePath = settings.value(u"xray/executablePath"_s).toString().trimmed();
    m_loggingEnabled = settings.value(u"logs/enabled"_s, true).toBool();
    m_autoPingProfiles = settings.value(u"profiles/autoPing"_s, false).toBool();
    m_currentProfileIndex = settings.value(u"profiles/currentIndex"_s, -1).toInt();
    m_currentProfileId = settings.value(u"profiles/currentId"_s).toString().trimmed();

    m_profileGroupOptions.clear();
    const QString rawGroupOptions = settings.value(u"profiles/groupOptionsJson"_s).toString().trimmed();
    if (!rawGroupOptions.isEmpty()) {
        QJsonParseError parseError;
        const QJsonDocument doc = QJsonDocument::fromJson(rawGroupOptions.toUtf8(), &parseError);
        if (parseError.error == QJsonParseError::NoError && doc.isArray()) {
            const QJsonArray arr = doc.array();
            for (const QJsonValue& value : arr) {
                if (!value.isObject()) {
                    continue;
                }
                const QJsonObject obj = value.toObject();
                ProfileGroupOptions options;
                options.name = normalizeGroupName(obj.value(u"name"_s).toString());
                options.key = normalizeGroupKey(options.name);
                options.enabled = obj.value(u"enabled"_s).toBool(true);
                options.exclusive = obj.value(u"exclusive"_s).toBool(false);
                options.badge = obj.value(u"badge"_s).toString().trimmed();

                if (options.name.compare(u"All"_s, Qt::CaseInsensitive) == 0) {
                    options.enabled = true;
                    options.exclusive = false;
                    options.badge.clear();
                }
                if (!options.enabled) {
                    options.exclusive = false;
                }

                const int idx = profileGroupOptionsIndex(options.name);
                if (idx >= 0) {
                    m_profileGroupOptions[idx] = options;
                } else {
                    m_profileGroupOptions.append(options);
                }
            }
        }
    }

    m_currentProfileGroup = settings.value(u"profiles/currentGroup"_s, u"All"_s).toString().trimmed();
    if (m_currentProfileGroup.isEmpty()) {
        m_currentProfileGroup = u"All"_s;
    }
    const bool modeExplicitlyChosen = settings.value(
                                                  u"network/modeExplicitlyChosen"_s, false).toBool();
    m_tunMode = modeExplicitlyChosen
                    ? settings.value(u"network/tunMode"_s, false).toBool()
                    : true;
    m_useSystemProxy = modeExplicitlyChosen
                           ? settings.value(u"network/useSystemProxy"_s, false).toBool()
                           : false;
    if (m_tunMode) {
        m_useSystemProxy = false;
    }
    m_killSwitchEnabled = settings.value(u"network/killSwitchEnabled"_s, false).toBool();
    if (settings.contains(u"network/autoDisableSystemProxyOnDisconnect"_s)) {
        m_autoDisableSystemProxyOnDisconnect =
            settings.value(u"network/autoDisableSystemProxyOnDisconnect"_s).toBool();
    } else {
        m_autoDisableSystemProxyOnDisconnect = false;
    }
    m_whitelistMode = settings.value(u"routing/whitelistMode"_s, false).toBool();
    m_proxyDomainRules = settings.value(u"routing/proxyDomains"_s).toString();
    m_directDomainRules = settings.value(u"routing/directDomains"_s).toString();
    m_blockDomainRules = settings.value(u"routing/blockDomains"_s).toString();
    m_customDnsServers = parseDnsServers(
                             settings.value(u"routing/customDnsServers"_s).toString())
                             .join('\n');
    m_proxyAppRules = settings.value(u"routing/proxyApps"_s).toString();
    m_directAppRules = settings.value(u"routing/directApps"_s).toString();
    m_blockAppRules = settings.value(u"routing/blockApps"_s).toString();
}

void VpnController::saveSettings() const
{
    QSettings settings;
    settings.setValue(u"xray/executablePath"_s, m_xrayExecutablePath);
    settings.setValue(u"logs/enabled"_s, m_loggingEnabled);
    settings.setValue(u"profiles/autoPing"_s, m_autoPingProfiles);
    settings.setValue(u"profiles/currentIndex"_s, m_currentProfileIndex);
    settings.setValue(u"profiles/currentId"_s, m_currentProfileId);
    settings.setValue(u"profiles/currentGroup"_s, m_currentProfileGroup);

    QJsonArray groupOptionsArray;
    for (const ProfileGroupOptions& options : m_profileGroupOptions) {
        QJsonObject obj;
        obj[u"name"_s] = options.name;
        obj[u"enabled"_s] = options.enabled;
        obj[u"exclusive"_s] = options.exclusive;
        obj[u"badge"_s] = options.badge;
        groupOptionsArray.append(obj);
    }
    settings.setValue(
        u"profiles/groupOptionsJson"_s,
        QString::fromUtf8(QJsonDocument(groupOptionsArray).toJson(QJsonDocument::Compact))
        );

    settings.setValue(u"network/useSystemProxy"_s, m_useSystemProxy);
    settings.setValue(u"network/tunMode"_s, m_tunMode);
    settings.setValue(u"network/killSwitchEnabled"_s, m_killSwitchEnabled);
    settings.setValue(
        u"network/autoDisableSystemProxyOnDisconnect"_s,
        m_autoDisableSystemProxyOnDisconnect
        );
    settings.setValue(u"routing/whitelistMode"_s, m_whitelistMode);
    settings.setValue(u"routing/proxyDomains"_s, m_proxyDomainRules);
    settings.setValue(u"routing/directDomains"_s, m_directDomainRules);
    settings.setValue(u"routing/blockDomains"_s, m_blockDomainRules);
    settings.setValue(u"routing/customDnsServers"_s, m_customDnsServers);
    settings.setValue(u"routing/proxyApps"_s, m_proxyAppRules);
    settings.setValue(u"routing/directApps"_s, m_directAppRules);
    settings.setValue(u"routing/blockApps"_s, m_blockAppRules);
}

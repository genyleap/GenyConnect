module;
#include <QAbstractItemModel>
#include <QClipboard>
#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
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
#include <QSslError>
#include <QSslSocket>
#include <QStandardPaths>
#include <QThread>
#include <QTimer>
#include <QTcpServer>
#include <QTcpSocket>
#include <QTimeZone>
#include <QUuid>
#include <QUrlQuery>
#include <QVector>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrentRun>

#include <algorithm>
#include <array>
#include <cmath>
#include <cerrno>
#include <cstring>
#include <optional>
#include <string>

#include "runtime/runtimefactory.hpp"
#include "runtime/vpnruntimebackend.hpp"
#include "powermodemanager.hpp"

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

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
#include <libproc.h>
#endif
#if defined(Q_OS_LINUX)
#include <unistd.h>
#include <signal.h>
#endif

module genyconnect.backend.vpncontroller;

import genyconnect.backend.linkparser;
import genyconnect.backend.serverprofilemodel;
import genyconnect.backend.systemproxymanager;
import genyconnect.backend.updater;

void VpnController::__geny_vtable_anchor() {}

const QMetaObject& vpnControllerConnectionStateMetaObject()
{
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    return App::staticMetaObject;
#else
    return connectionStateMetaObject();
#endif
}

namespace {
constexpr int kMaxLogLines = 200;
constexpr int kSpeedTestTickIntervalMs = 100;
constexpr int kSpeedTestHistoryMaxItems = 20;
constexpr qint64 kSpeedTestUploadPayloadBytes = 8 * 1024 * 1024;
constexpr int kSpeedTestSamplingWindowMs = 280;
constexpr int kSpeedTestWarmupMs = 1200;
constexpr int kSpeedTestLatencyProbeCount = 8;
constexpr int kSpeedTestLatencyProbeTimeoutMs = 1800;
constexpr int kSpeedTestLatencyProbeGapMs = 120;
constexpr int kSpeedTestMinimumSizeMb = 5;
constexpr int kSpeedTestDefaultSizeMb = 10;
constexpr int kSpeedTestMaximumSizeMb = 25;
constexpr int kSpeedTestDownloadTimeoutBaseMs = 14000;
constexpr int kSpeedTestDownloadTimeoutPerMbMs = 1200;
constexpr int kSpeedTestNoProgressTimeoutMs = 14000;
constexpr int kSpeedTestUploadResponseIdleFinalizeMs = 1500;
constexpr double kSpeedTestDownloadCompletionRatio = 0.92;
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
constexpr int kPublicIpRetryDelayMs = 2200;
constexpr const char kPublicIpEndpoint[] = "https://api.ipify.org?format=text";
constexpr const char kManagedRuntimeRecordFile[] = "managed-runtime.json";
constexpr int kDonationBaseChainId = 8453;
constexpr const char kDonationBaseChainName[] = "Base Mainnet";
constexpr const char kDonationReceiverWallet[] = "0x24f02198f7f737552f87f889a415645a5f248917";
constexpr const char kDonationGenyContract[] = "0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B";
// Base USDC (Circle) contract.
constexpr const char kDonationUsdcContract[] = "0x833589fCD6EDB6E08f4c7C32D4f71b54bdA02913";
constexpr int kDonationGenyDecimals = 18;
constexpr int kDonationUsdcDecimals = 6;
constexpr const char kDonationBaseScanBaseUrl[] = "https://basescan.org";
constexpr const char kDonationUniswapBaseUrl[] = "https://app.uniswap.org/swap?chain=base&outputCurrency=";
constexpr const char kDonationWhitePaperUrl[] = "https://github.com/genyleap/white-paper";
constexpr const char kDonationTokenRepoUrl[] = "https://github.com/genyleap/geny-token";
constexpr const char kUint256MaxDec[] =
    "115792089237316195423570985008687907853269984665640564039457584007913129639935";
#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
#endif

struct ProxyApplyResult {
    bool enable = false;
    bool ok = false;
    QString error;
};

struct DonationTokenDefinition {
    const char* symbol;
    const char* displayName;
    const char* contract;
    int decimals;
    bool recommended;
    const char* encouragement;
    std::array<const char*, 4> presetAmounts;
};

const std::array<DonationTokenDefinition, 2>& donationTokens()
{
    static const std::array<DonationTokenDefinition, 2> tokens {{
        {
            "GENY",
            "GENY Token",
            kDonationGenyContract,
            kDonationGenyDecimals,
            true,
            "By donating with GENY, you are not only supporting GenyConnect development, you are also supporting the growth of the Geny ecosystem and its community.",
            {"256", "512", "1024", "Custom"}
        },
        {
            "USDC",
            "USD Coin (USDC)",
            kDonationUsdcContract,
            kDonationUsdcDecimals,
            false,
            "USDC is a simple stable donation option for supporting development directly.",
            {"5", "10", "25", "Custom"}
        }
    }};
    return tokens;
}

const DonationTokenDefinition* findDonationToken(const QString& symbol)
{
    const QString normalized = symbol.trimmed().toUpper();
    for (const auto& token : donationTokens()) {
        if (normalized == QString::fromUtf8(token.symbol)) {
            return &token;
        }
    }
    return nullptr;
}

QString readUtf8TextFile(const QString& path)
{
    QFile file(path);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }
    return QString::fromUtf8(file.readAll());
}

QString resolveLicenseText()
{
    const QStringList candidates = {
        QString::fromUtf8(":/LICENSE"),
        QString::fromUtf8(":/LICENSE.txt"),
        QString::fromUtf8(":/ui/Resources/text/LICENSE"),
        QString::fromUtf8(":/ui/Resources/text/LICENSE.txt"),
        QCoreApplication::applicationDirPath() + QString::fromUtf8("/LICENSE"),
        QCoreApplication::applicationDirPath() + QString::fromUtf8("/../LICENSE")
    };
    for (const QString& path : candidates) {
        const QString text = readUtf8TextFile(path).trimmed();
        if (!text.isEmpty()) {
            return text;
        }
    }
    return QString::fromUtf8("License text is unavailable in this build.");
}

QString stripLeadingZeros(const QString& value)
{
    int i = 0;
    while (i < value.size() && value.at(i) == QChar('0')) {
        ++i;
    }
    if (i >= value.size()) {
        return QString::fromUtf8("0");
    }
    return value.mid(i);
}

bool isUint256Decimal(const QString& value)
{
    const QString normalized = stripLeadingZeros(value);
    static const QString maxValue = QString::fromUtf8(kUint256MaxDec);
    if (normalized.size() < maxValue.size()) {
        return true;
    }
    if (normalized.size() > maxValue.size()) {
        return false;
    }
    return normalized <= maxValue;
}

bool parseTokenAmountToBaseUnits(const QString& rawAmount, int decimals, QString *baseUnits, QString *errorText)
{
    if (!baseUnits || !errorText) {
        return false;
    }
    *baseUnits = QString();
    *errorText = QString();

    const QString input = rawAmount.trimmed();
    if (input.isEmpty()) {
        *errorText = QString::fromUtf8("Enter a donation amount.");
        return false;
    }

    static const QRegularExpression numberPattern(
        QString::fromUtf8("^([0-9]+)(?:\\.([0-9]+))?$"));
    const QRegularExpressionMatch match = numberPattern.match(input);
    if (!match.hasMatch()) {
        *errorText = QString::fromUtf8("Amount must be a valid positive number.");
        return false;
    }

    QString integerPart = match.captured(1);
    QString fractionPart = match.captured(2);
    if (fractionPart.size() > decimals) {
        *errorText = QString::fromUtf8("Too many decimal places for selected token.");
        return false;
    }

    if (fractionPart.size() < decimals) {
        fractionPart += QString(decimals - fractionPart.size(), QChar('0'));
    }

    integerPart = stripLeadingZeros(integerPart);
    QString merged = integerPart + fractionPart;
    merged = stripLeadingZeros(merged);

    if (merged == QString::fromUtf8("0")) {
        *errorText = QString::fromUtf8("Amount must be greater than zero.");
        return false;
    }

    if (!isUint256Decimal(merged)) {
        *errorText = QString::fromUtf8("Amount is too large.");
        return false;
    }

    *baseUnits = merged;
    return true;
}

QString donationUniswapUrl(const DonationTokenDefinition& token)
{
    return QString::fromUtf8("%1%2")
        .arg(QString::fromUtf8(kDonationUniswapBaseUrl), QString::fromUtf8(token.contract));
}

QString usageHourBucketKey(const QDateTime& timestamp)
{
    return timestamp.toString(QString::fromUtf8("yyyy-MM-dd HH"));
}

bool isAndroidVpnPermissionRequiredMessage(const QString& message)
{
    return message.contains(QString::fromUtf8("Android VPN permission is required"), Qt::CaseInsensitive)
        || message.contains(QString::fromUtf8("Android VPN permission prompt is already pending"), Qt::CaseInsensitive)
        || message.contains(QString::fromUtf8("Android VPN permission is still not granted"), Qt::CaseInsensitive);
}

QString usageDayBucketKey(const QDateTime& timestamp)
{
    return timestamp.date().toString(QString::fromUtf8("yyyy-MM-dd"));
}

QString usageWeekBucketKey(const QDateTime& timestamp)
{
    int isoYear = timestamp.date().year();
    const int isoWeek = timestamp.date().weekNumber(&isoYear);
    return QString::fromUtf8("%1-W%2").arg(isoYear).arg(isoWeek, 2, 10, QChar('0'));
}

QString usageMonthBucketKey(const QDateTime& timestamp)
{
    return timestamp.date().toString(QString::fromUtf8("yyyy-MM"));
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
    const qint64 previousRx = entry.value(QString::fromUtf8("rx")).toVariant().toLongLong();
    const qint64 previousTx = entry.value(QString::fromUtf8("tx")).toVariant().toLongLong();
    entry.insert(QString::fromUtf8("rx"), previousRx + qMax<qint64>(0, rxBytes));
    entry.insert(QString::fromUtf8("tx"), previousTx + qMax<qint64>(0, txBytes));
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
    const QStringList lines = normalized.split(QRegularExpression(QString::fromUtf8("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (QString line : lines) {
        line = line.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QStringList tokens = line.split(QRegularExpression(QString::fromUtf8("[\\s,]+")), Qt::SkipEmptyParts);
        for (const QString& token : tokens) {
            const QString candidate = token.trimmed();
            if (candidate.startsWith(QString::fromUtf8("vmess://"), Qt::CaseInsensitive)
                || candidate.startsWith(QString::fromUtf8("vless://"), Qt::CaseInsensitive)) {
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

    if (trimmed.compare(QString::fromUtf8("all"), Qt::CaseInsensitive) == 0) {
        return QString::fromLatin1(kDefaultProfileGroup);
    }

    return trimmed;
}

QString deriveSubscriptionNameFromUrl(const QString& rawUrl)
{
    const QUrl url(rawUrl.trimmed());
    QString host = url.host().trimmed();
    if (host.startsWith(QString::fromUtf8("www."), Qt::CaseInsensitive)) {
        host = host.mid(4);
    }
    if (!host.isEmpty()) {
        return host;
    }

    const QString path = url.path().trimmed();
    if (!path.isEmpty() && path != QString::fromUtf8("/")) {
        return path;
    }

    return QString::fromUtf8("Subscription");
}

QString normalizeSubscriptionNameValue(const QString& rawName, const QString& fallbackUrl)
{
    const QString trimmed = rawName.trimmed();
    return trimmed.isEmpty() ? deriveSubscriptionNameFromUrl(fallbackUrl) : trimmed;
}

bool isNoisyTrafficLine(const QString& line)
{
    if (!line.contains(QString::fromUtf8(" accepted "))) {
        return false;
    }
    // Drop high-frequency link-local broadcast noise in TUN mode
    // (for example: udp:* -> 169.254.255.255:137 [tun-in -> direct]),
    // which can flood logs and stall UI updates.
    if (line.contains(QString::fromUtf8("[tun-in -> direct]"))
        && (line.contains(QString::fromUtf8("udp:169.254.255.255:137"))
            || line.contains(QString::fromUtf8("udp:255.255.255.255:137"))
            || line.contains(QString::fromUtf8("udp:169.254.255.255:138"))
            || line.contains(QString::fromUtf8("udp:255.255.255.255:138"))
            || line.contains(QString::fromUtf8("from tcp:169.254."))
            || line.contains(QString::fromUtf8("from udp:169.254."))
            || line.contains(QString::fromUtf8("udp:224.")))) {
        return true;
    }
    // Keep tun-in traffic visible for diagnostics; suppress only noisy local-proxy chatter.
    if (line.contains(QString::fromUtf8("[tun-in ->"))) {
        return false;
    }
    return line.contains(QString::fromUtf8(">> proxy"))
           || line.contains(QString::fromUtf8("socks ->"))
           || line.contains(QString::fromUtf8("mixed-in ->"));
}

bool ruleHasInboundTag(const QJsonObject& rule, const QString& inboundTag)
{
    const QJsonArray tags = rule.value(QString::fromUtf8("inboundTag")).toArray();
    for (const QJsonValue& value : tags) {
        if (value.toString().compare(inboundTag, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

bool ruleHasIp(const QJsonObject& rule, const QString& ipCidr)
{
    const QJsonArray ips = rule.value(QString::fromUtf8("ip")).toArray();
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

    QJsonObject routing = config->value(QString::fromUtf8("routing")).toObject();
    QJsonArray rules = routing.value(QString::fromUtf8("rules")).toArray();
    if (rules.isEmpty()) {
        return;
    }

    bool hasUdpPortNoiseBlock = false;
    bool hasLinkLocalNoiseBlock = false;
    bool directPrivateRuleScoped = false;
    for (int i = 0; i < rules.size(); ++i) {
        QJsonObject rule = rules.at(i).toObject();
        if (rule.value(QString::fromUtf8("outboundTag")).toString() != QString::fromUtf8("direct")) {
            continue;
        }
        const QJsonArray ips = rule.value(QString::fromUtf8("ip")).toArray();
        bool looksLikePrivateDirect = false;
        for (const QJsonValue& ip : ips) {
            const QString cidr = ip.toString();
            if (cidr == QString::fromUtf8("10.0.0.0/8")
                || cidr == QString::fromUtf8("100.64.0.0/10")
                || cidr == QString::fromUtf8("127.0.0.0/8")
                || cidr == QString::fromUtf8("169.254.0.0/16")
                || cidr == QString::fromUtf8("172.16.0.0/12")
                || cidr == QString::fromUtf8("192.168.0.0/16")) {
                looksLikePrivateDirect = true;
                break;
            }
        }
        if (!looksLikePrivateDirect) {
            continue;
        }

        const QJsonArray inboundTags = rule.value(QString::fromUtf8("inboundTag")).toArray();
        bool onlyMixedIn = (inboundTags.size() == 1
                            && inboundTags.first().toString().compare(QString::fromUtf8("mixed-in"), Qt::CaseInsensitive) == 0);
        if (!onlyMixedIn) {
            rule.insert(QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("mixed-in")});
            rules[i] = rule;
        }
        directPrivateRuleScoped = true;
    }
    for (const QJsonValue& value : rules) {
        const QJsonObject rule = value.toObject();
        if (rule.value(QString::fromUtf8("outboundTag")).toString() != QString::fromUtf8("block")) {
            continue;
        }
        if (!ruleHasInboundTag(rule, QString::fromUtf8("tun-in"))) {
            continue;
        }
        if (rule.value(QString::fromUtf8("network")).toString() == QString::fromUtf8("udp")
            && rule.value(QString::fromUtf8("port")).toString().contains(QString::fromUtf8("137"))) {
            hasUdpPortNoiseBlock = true;
        }
        if (rule.value(QString::fromUtf8("network")).toString() == QString::fromUtf8("udp")
            && (ruleHasIp(rule, QString::fromUtf8("169.254.0.0/16"))
                || ruleHasIp(rule, QString::fromUtf8("255.255.255.255/32"))
                || ruleHasIp(rule, QString::fromUtf8("224.0.0.0/4")))) {
            hasLinkLocalNoiseBlock = true;
        }
    }

    QJsonArray prefix;
    if (!hasUdpPortNoiseBlock) {
        prefix.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("udp")},
            {QString::fromUtf8("port"), QString::fromUtf8("137,138,5353,5355")},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("block")}
        });
    }
    if (!hasLinkLocalNoiseBlock) {
        prefix.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("udp")},
            {QString::fromUtf8("ip"), QJsonArray {
                QString::fromUtf8("169.254.0.0/16"),
                QString::fromUtf8("255.255.255.255/32"),
                QString::fromUtf8("224.0.0.0/4")
            }},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("block")}
        });
    }

    if (!prefix.isEmpty()) {
        for (const QJsonValue& value : rules) {
            prefix.append(value);
        }
        routing.insert(QString::fromUtf8("rules"), prefix);
        config->insert(QString::fromUtf8("routing"), routing);
        return;
    }

    if (directPrivateRuleScoped) {
        routing.insert(QString::fromUtf8("rules"), rules);
        config->insert(QString::fromUtf8("routing"), routing);
    }
}

bool hasRulePort53ToDnsOutForTun(const QJsonObject& rule)
{
    if (rule.value(QString::fromUtf8("outboundTag")).toString() != QString::fromUtf8("dns-out")) {
        return false;
    }
    if (!ruleHasInboundTag(rule, QString::fromUtf8("tun-in"))) {
        return false;
    }
    const QString port = rule.value(QString::fromUtf8("port")).toString();
    return port.contains(QString::fromUtf8("53"));
}

void ensureTunDnsSupport(QJsonObject* config, const QStringList& dnsServers)
{
    if (config == nullptr) {
        return;
    }

    QJsonArray outbounds = config->value(QString::fromUtf8("outbounds")).toArray();
    bool hasDnsOut = false;
    for (const QJsonValue& value : outbounds) {
        const QJsonObject outbound = value.toObject();
        if (outbound.value(QString::fromUtf8("tag")).toString() == QString::fromUtf8("dns-out")
            && outbound.value(QString::fromUtf8("protocol")).toString() == QString::fromUtf8("dns")) {
            hasDnsOut = true;
            break;
        }
    }
    if (!hasDnsOut) {
        outbounds.append(QJsonObject {
            {QString::fromUtf8("tag"), QString::fromUtf8("dns-out")},
            {QString::fromUtf8("protocol"), QString::fromUtf8("dns")},
            {QString::fromUtf8("settings"), QJsonObject {}}
        });
        config->insert(QString::fromUtf8("outbounds"), outbounds);
    }

    QJsonObject dns = config->value(QString::fromUtf8("dns")).toObject();
    QJsonArray serverArray;
    for (const QString& server : dnsServers) {
        const QString trimmed = server.trimmed();
        if (!trimmed.isEmpty()) {
            serverArray.append(trimmed);
        }
    }
    if (serverArray.isEmpty()) {
        serverArray = QJsonArray {
            QString::fromUtf8("1.1.1.1"),
            QString::fromUtf8("8.8.8.8"),
            QString::fromUtf8("9.9.9.9")
        };
    }
    dns.insert(QString::fromUtf8("servers"), serverArray);
    const QString queryStrategy = dns.value(QString::fromUtf8("queryStrategy")).toString().trimmed();
    if (queryStrategy.isEmpty()
        || queryStrategy.compare(QString::fromUtf8("UseIPv4"), Qt::CaseInsensitive) == 0) {
        dns.insert(QString::fromUtf8("queryStrategy"), QString::fromUtf8("UseIP"));
    }
    config->insert(QString::fromUtf8("dns"), dns);

    QJsonObject routing = config->value(QString::fromUtf8("routing")).toObject();
    QJsonArray rules = routing.value(QString::fromUtf8("rules")).toArray();
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
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("tcp,udp")},
            {QString::fromUtf8("port"), QString::fromUtf8("53")},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("dns-out")}
        });
        for (const QJsonValue& value : rules) {
            prefixedRules.append(value);
        }
        routing.insert(QString::fromUtf8("rules"), prefixedRules);
        config->insert(QString::fromUtf8("routing"), routing);
    }
}

QList<QUrl> speedTestPingUrls()
{
    return {
        QUrl(QString::fromUtf8("https://www.cloudflare.com/cdn-cgi/trace")),
        QUrl(QString::fromUtf8("https://www.google.com/generate_204")),
        QUrl(QString::fromUtf8("https://cp.cloudflare.com/generate_204"))
    };
}

QList<QUrl> speedTestDownloadUrls()
{
    return {
        QUrl(QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=32000000")),
        QUrl(QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=64000000")),
        QUrl(QString::fromUtf8("https://speed.hetzner.de/100MB.bin"))
    };
}

QList<QUrl> speedTestUploadUrls()
{
    return {
        QUrl(QString::fromUtf8("https://speed.cloudflare.com/__up")),
        QUrl(QString::fromUtf8("https://httpbin.org/post"))
    };
}

QUrl speedTestUrlForPhase(const QString& phase, int attempt)
{
    const int safeAttempt = qMax(0, attempt);
    if (phase == QString::fromUtf8("Ping")) {
        const QList<QUrl> urls = speedTestPingUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == QString::fromUtf8("Download")) {
        const QList<QUrl> urls = speedTestDownloadUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == QString::fromUtf8("Upload")) {
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
            *errorMessage = QString::fromUtf8("Local mixed proxy port is not reachable.");
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
            *errorMessage = QString::fromUtf8("Failed to write proxy CONNECT request.");
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

    const bool ok = firstLine.startsWith(QString::fromUtf8("HTTP/1.1 200"))
                    || firstLine.startsWith(QString::fromUtf8("HTTP/1.0 200"));

    if (!ok && errorMessage) {
        *errorMessage = firstLine.isEmpty()
        ? QString::fromUtf8("No proxy response for CONNECT test.")
        : QString::fromUtf8("CONNECT response: %1").arg(firstLine);
    }

    return ok;
}

QString quoteForShell(const QString& value)
{
    QString escaped = value;
    escaped.replace(QString::fromUtf8("'"), QString::fromUtf8("'\"'\"'"));
    return QString::fromUtf8("'") + escaped + QString::fromUtf8("'");
}

QString joinQuotedArgsForShell(const QStringList& args)
{
    QStringList quoted;
    quoted.reserve(args.size());
    for (const QString& arg : args) {
        quoted.append(quoteForShell(arg));
    }
    return quoted.join(QString::fromUtf8(" "));
}

QString quoteForPowerShellSingleQuoted(const QString& value)
{
    QString escaped = value;
    escaped.replace(QString::fromUtf8("'"), QString::fromUtf8("''"));
    return QString::fromUtf8("'") + escaped + QString::fromUtf8("'");
}

QString toPowerShellArgumentArrayLiteral(const QStringList& args)
{
    QStringList parts;
    parts.reserve(args.size());
    for (const QString& arg : args) {
        parts.append(quoteForPowerShellSingleQuoted(arg));
    }
    return QString::fromUtf8("@(") + parts.join(QString::fromUtf8(",")) + QString::fromUtf8(")");
}

QString escapeForAppleScriptString(const QString& value)
{
    QString out = value;
    out.replace(QString::fromUtf8("\\"), QString::fromUtf8("\\\\"));
    out.replace(QString::fromUtf8("\""), QString::fromUtf8("\\\""));
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
            *errorMessage = QString::fromUtf8("xray-core executable path is empty.");
        }
        return false;
    }

    QFileInfo info(normalized);
    if (!info.exists() || !info.isFile()) {
        if (errorMessage != nullptr) {
            *errorMessage = QString::fromUtf8("xray-core binary not found at selected path.");
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
            *errorMessage = QString::fromUtf8("xray-core is not executable and permissions could not be repaired: %1")
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
    process.start(QString::fromUtf8("/sbin/ifconfig"), {QString::fromUtf8("-l")});
    if (!process.waitForStarted(1000)) {
        return QString::fromUtf8("utun9");
    }
    if (!process.waitForFinished(1500)) {
        process.kill();
        process.waitForFinished(200);
        return QString::fromUtf8("utun9");
    }
    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    static const QRegularExpression re(QString::fromUtf8("\\butun(\\d+)\\b"));
    QSet<int> used;
    QRegularExpressionMatchIterator it = re.globalMatch(output);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        used.insert(m.captured(1).toInt());
    }
    for (int n = 10; n <= 64; ++n) {
        if (!used.contains(n)) {
            return QString::fromUtf8("utun%1").arg(n);
        }
    }
    return QString::fromUtf8("utun9");
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
            *errorMessage = QString::fromUtf8("Cannot resolve xray directory for TUN runtime.");
        }
        return false;
    }

    const QString targetDll = QDir(xrayDir).filePath(QString::fromUtf8("wintun.dll"));
    if (QFileInfo::exists(targetDll)) {
        return true;
    }

    QStringList candidates;
    candidates << QDir(QCoreApplication::applicationDirPath()).filePath(QString::fromUtf8("wintun.dll"));
    candidates << QDir(dataDirectory).filePath(QString::fromUtf8("wintun.dll"));

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
        *errorMessage = QString::fromUtf8(
            "Windows TUN dependency missing: wintun.dll was not found beside xray-core.exe.");
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
            QString::fromUtf8("api"),
            QString::fromUtf8("statsquery"),
            QString::fromUtf8("--server=127.0.0.1:%1").arg(apiPort),
            QString::fromUtf8("-pattern"),
            QString::fromUtf8("outbound>>>")
        }
        );

    if (!process.waitForStarted(1500)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to start xray api statsquery process.");
        }
        return false;
    }

    if (!process.waitForFinished(4500)) {
        process.kill();
        process.waitForFinished(500);
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("xray api statsquery timed out.");
        }
        return false;
    }

    const QByteArray stdoutBytes = process.readAllStandardOutput();
    const QByteArray stderrBytes = process.readAllStandardError();

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        if (errorMessage) {
            const QString stderrText = QString::fromUtf8(stderrBytes).trimmed();
            *errorMessage = stderrText.isEmpty()
                                ? QString::fromUtf8("xray api statsquery failed.")
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
        const QJsonValue statValue = root.value(QString::fromUtf8("stat"));
        bool foundAnyCounter = false;

        auto consumeStatObject = [&up, &down, &foundAnyCounter](const QJsonObject &statObj) {
            const QString name = statObj.value(QString::fromUtf8("name")).toString();
            const qint64 value = statObj.value(QString::fromUtf8("value")).toVariant().toLongLong();
            if (!name.startsWith(QString::fromUtf8("outbound>>>"))) {
                return;
            }

            const QStringList parts = name.split(QString::fromUtf8(">>>"));
            if (parts.size() < 4) {
                return;
            }

            const QString outboundTag = parts.at(1);
            const QString direction = parts.at(3);
            if (outboundTag == QString::fromUtf8("api")) {
                return;
            }

            if (direction == QString::fromUtf8("uplink")) {
                up += value;
                foundAnyCounter = true;
            } else if (direction == QString::fromUtf8("downlink")) {
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
        QString::fromUtf8("outbound>>>([^>]+)>>>traffic>>>uplink[^0-9]*([0-9]+)"),
        QRegularExpression::CaseInsensitiveOption
        );
    static const QRegularExpression downRegex(
        QString::fromUtf8("outbound>>>([^>]+)>>>traffic>>>downlink[^0-9]*([0-9]+)"),
        QRegularExpression::CaseInsensitiveOption
        );

    bool foundAnyCounter = false;

    QRegularExpressionMatchIterator upIt = upRegex.globalMatch(plain);
    while (upIt.hasNext()) {
        const QRegularExpressionMatch match = upIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == QString::fromUtf8("api")) {
            continue;
        }
        up += match.captured(2).toLongLong();
        foundAnyCounter = true;
    }

    QRegularExpressionMatchIterator downIt = downRegex.globalMatch(plain);
    while (downIt.hasNext()) {
        const QRegularExpressionMatch match = downIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == QString::fromUtf8("api")) {
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
            snippet = snippet.left(200) + QString::fromUtf8("...");
        }
        *errorMessage = snippet.isEmpty()
                            ? QString::fromUtf8("xray api statsquery returned no traffic stats.")
                            : QString::fromUtf8("xray api statsquery parse failed: %1").arg(snippet);
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
    QFile statusFile(QString::fromUtf8("/proc/self/status"));
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

double combinedSpeedTestAverageMbps(double downloadMbps, double uploadMbps)
{
    const double down = qMax(0.0, downloadMbps);
    const double up = qMax(0.0, uploadMbps);
    if (down > 0.0 && up > 0.0) {
        return (down + up) * 0.5;
    }
    return qMax(down, up);
}
}

VpnController::VpnController(QObject *parent)
    : QObject(parent)
{
    m_startedWithTunElevationRequest = QCoreApplication::arguments().contains(
        QString::fromUtf8("--geny-elevated-tun"));

    m_dataDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(m_dataDirectory);

    m_profilesPath = QDir(m_dataDirectory).filePath(QString::fromUtf8("profiles.json"));
    m_subscriptionsPath = QDir(m_dataDirectory).filePath(QString::fromUtf8("subscriptions.json"));
    m_runtimeConfigPath = QDir(m_dataDirectory).filePath(QString::fromUtf8("xray-runtime-config.json"));
    m_profileUsagePath = QDir(m_dataDirectory).filePath(QString::fromUtf8("profile-traffic-usage.json"));
    m_privilegedTunPidPath = QDir(m_dataDirectory).filePath(QString::fromUtf8("xray-tun.pid"));
    m_privilegedTunLogPath = QDir(m_dataDirectory).filePath(QString::fromUtf8("xray-tun.log"));
    m_managedRuntimeRecordPath = QDir(m_dataDirectory).filePath(QString::fromLatin1(kManagedRuntimeRecordFile));

    m_buildOptions.socksPort = 10808;
    m_buildOptions.httpPort = 10808;
    m_buildOptions.apiPort = 10085;
    m_buildOptions.logLevel = QString::fromUtf8("warning");
    m_buildOptions.enableStatsApi = true;

    m_runtimeBackend = createRuntimeBackend(this).release();
    if (!m_runtimeBackend) {
        appendSystemLog(QString::fromUtf8("[System] Runtime backend could not be initialized."));
        m_runtimeIsMobile = false;
        m_runtimeIsDesktop = true;
    } else {
        const VpnRuntimeCapabilities caps = m_runtimeBackend->capabilities();
        m_runtimeIsMobile = caps.isMobile;
        m_runtimeIsDesktop = caps.isDesktop;
        m_runtimeSupportsTun = caps.supportsTun;
        m_runtimeSupportsSystemProxy = caps.supportsSystemProxy;
        m_runtimeSupportsPerAppRouting = caps.supportsPerAppRouting;
        m_runtimeSupportsAutoUpdate = caps.supportsAutoUpdate;
        m_runtimeRequiresVpnPermission = caps.requiresVpnPermission;
        m_runtimeRequiresForegroundService = caps.requiresForegroundService;
        m_runtimeRequiresNetworkExtension = caps.requiresNetworkExtension;
        emit runtimeCapabilitiesChanged();
    }
    m_updater = new Updater(this);
    m_powerModeManager = new PowerModeManager(this);
    m_profileModel = new ServerProfileModel(this);
    m_systemProxyManager = new SystemProxyManager();
    m_memoryUsageTimer.setInterval(1500);
    connect(&m_memoryUsageTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("memory"));
        }
        updateMemoryUsage();
    });
    m_memoryUsageTimer.start();
    m_statsPollTimer.setInterval(1000);
    connect(&m_statsPollTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("stats"));
        }
        pollTrafficStats();
    });
    m_privilegedTunLogTimer.setInterval(200);
    connect(&m_privilegedTunLogTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("tunLog"));
        }
        pollPrivilegedTunLogs();
    });
    m_profileUsageSaveTimer.setSingleShot(true);
    m_profileUsageSaveTimer.setInterval(kProfileUsageSaveDelayMs);
    connect(&m_profileUsageSaveTimer, &QTimer::timeout, this, [this]() {
        saveProfileUsage();
    });
    m_logsFlushTimer.setSingleShot(true);
    m_logsFlushTimer.setInterval(120);
    connect(&m_logsFlushTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("logsFlush"));
        }
        if (!m_logsDirty) {
            return;
        }
        m_logsDirty = false;
        emit logsChanged();
    });
    m_speedTestTimer.setInterval(kSpeedTestTickIntervalMs);
    connect(&m_speedTestTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("speedTest"));
        }
        onSpeedTestTick();
    });
    m_publicIpRetryTimer.setSingleShot(true);
    connect(&m_publicIpRetryTimer, &QTimer::timeout, this, [this]() {
        if (m_powerModeManager) {
            m_powerModeManager->recordTimerWakeup(QString::fromUtf8("publicIpRetry"));
        }
        if (!connected()) {
            return;
        }
        refreshPublicIp();
    });

    if (m_runtimeBackend) {
        connect(m_runtimeBackend, &VpnRuntimeBackend::started, this, &VpnController::onProcessStarted);
        connect(m_runtimeBackend, &VpnRuntimeBackend::stopped, this, &VpnController::onProcessStopped);
        connect(m_runtimeBackend, &VpnRuntimeBackend::errorOccurred, this, &VpnController::onProcessError);
        connect(m_runtimeBackend, &VpnRuntimeBackend::logLine, this, &VpnController::onLogLine);
        connect(m_runtimeBackend, &VpnRuntimeBackend::trafficChanged, this, &VpnController::onTrafficUpdated);

        QString runtimeInitError;
        if (!m_runtimeBackend->initialize(&runtimeInitError) && !runtimeInitError.trimmed().isEmpty()) {
            appendSystemLog(QString::fromUtf8("[System] Runtime initialization warning: %1").arg(runtimeInitError.trimmed()));
        }
    }
    if (m_updater) {
        connect(m_updater, &Updater::systemLog, this, &VpnController::appendSystemLog);
    }
    if (m_powerModeManager) {
        connect(m_powerModeManager, &PowerModeManager::modeChanged, this, [this]() {
            emit powerModeChanged();
            emit powerPolicyChanged();
            saveSettings();
        });
        connect(m_powerModeManager, &PowerModeManager::effectivePolicyChanged, this, [this]() {
            applyPowerPolicy();
            emit powerPolicyChanged();
        });
        connect(m_powerModeManager, &PowerModeManager::diagnosticsChanged, this, &VpnController::powerDiagnosticsChanged);
        connect(m_powerModeManager, &PowerModeManager::debugLog, this, &VpnController::appendSystemLog);
        connect(m_powerModeManager, &PowerModeManager::saveModeSuggested, this, [this](const QString& reason) {
            appendSystemLog(QString::fromUtf8("[PowerMode] Save mode suggested: %1").arg(reason));
        });
        connect(m_powerModeManager, &PowerModeManager::normalModeFallbackTriggered, this, [this](const QString& reason) {
            appendSystemLog(QString::fromUtf8("[PowerMode] Fallback to Normal mode after instability: %1").arg(reason));
            saveSettings();
        });
    }
    connect(m_profileModel, &QAbstractItemModel::rowsInserted, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(m_profileModel, &QAbstractItemModel::rowsRemoved, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(m_profileModel, &QAbstractItemModel::modelReset, this, [this]() {
        recomputeProfileStats();
        refreshProfileGroups();
    });
    connect(m_profileModel, SIGNAL(dataChanged(QModelIndex,QModelIndex,QList<int>)),
            this, SLOT(onProfileModelDataChanged()));

    updateMemoryUsage();

    loadSettings();
    applyPowerPolicy();
    if (!m_runtimeSupportsSystemProxy) {
        m_useSystemProxy = false;
        m_killSwitchEnabled = false;
        m_autoDisableSystemProxyOnDisconnect = false;
    }
    if (!m_runtimeSupportsTun) {
        m_tunMode = false;
    }
    loadProfiles();
    loadSubscriptions();
    loadProfileUsage();
    refreshProfileGroups();
    if (m_updater) {
        m_updater->setAppVersion(QCoreApplication::applicationVersion());
    }

    const QString bundledXrayPath = detectDefaultXrayPath();
    if (!bundledXrayPath.isEmpty()) {
        m_xrayExecutablePath = bundledXrayPath;
    } else if (m_xrayExecutablePath.isEmpty()) {
        m_xrayExecutablePath = detectDefaultXrayPath();
    }
    detectProcessRoutingSupport();
    cleanupManagedRuntimeOnStartup();

    if (m_profileModel->rowCount() == 0) {
        m_currentProfileIndex = -1;
    } else if (!m_currentProfileId.trimmed().isEmpty()) {
        const int resolvedIndex = m_profileModel->indexOfId(m_currentProfileId.trimmed());
        if (resolvedIndex >= 0) {
            m_currentProfileIndex = resolvedIndex;
        } else if (m_currentProfileIndex < 0 || m_currentProfileIndex >= m_profileModel->rowCount()) {
            m_currentProfileIndex = 0;
        }
    } else if (m_currentProfileIndex < 0 || m_currentProfileIndex >= m_profileModel->rowCount()) {
        m_currentProfileIndex = 0;
    }
    const auto startupProfile = m_profileModel->profileAt(m_currentProfileIndex);
    m_currentProfileId = startupProfile.has_value() ? startupProfile->id.trimmed() : QString();
    recomputeProfileStats();

    if (m_runtimeSupportsAutoUpdate) {
        QTimer::singleShot(1500, this, [this]() {
            if (m_updater) {
                m_updater->checkForUpdates(false);
            }
        });
    }
    QTimer::singleShot(900, this, [this]() {
        applyKillSwitchState();
    });

    connect(qApp, &QCoreApplication::aboutToQuit, this, [this]() {
        m_shutdownInProgress.store(true);
        m_disconnectRequested.store(true);
        m_publicIpRetryTimer.stop();
        if (m_publicIpReply) {
            m_publicIpReply->abort();
            m_publicIpReply->deleteLater();
            m_publicIpReply = nullptr;
        }
        cancelSpeedTest();
        m_statsPollTimer.stop();
        endProfileUsageSession(m_activeProfileUsageId);
        if (m_privilegedTunManaged) {
            m_privilegedTunLogTimer.stop();
            QString stopError;
            if (!stopPrivilegedTunProcess(&stopError) && !stopError.trimmed().isEmpty()) {
                appendSystemLog(QString::fromUtf8("[System] %1").arg(stopError.trimmed()));
            }
            m_privilegedTunManaged = false;
        }
        if (m_runtimeBackend && m_runtimeBackend->isRunning()) {
            m_stoppingProcess = true;
            QString runtimeStopError;
            Q_UNUSED(m_runtimeBackend->disconnectRuntime(&runtimeStopError, 2200));
            m_stoppingProcess = false;
        }
        clearManagedRuntimeRecord();
        cleanupDetachedHelpers();
    });
}

VpnController::~VpnController()
{
    m_shutdownInProgress.store(true);
    m_disconnectRequested.store(true);
    m_publicIpRetryTimer.stop();
    cancelSpeedTest();
    if (m_publicIpReply) {
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
    }
    endProfileUsageSession(m_activeProfileUsageId);
    m_profileUsageSaveTimer.stop();
    if (m_privilegedTunManaged) {
        m_privilegedTunLogTimer.stop();
        QString stopError;
        Q_UNUSED(stopPrivilegedTunProcess(&stopError));
        m_privilegedTunManaged = false;
    }
    stopPrivilegedTunRuntimeByPidPath();
    shutdownPrivilegedTunHelper();
    if (m_runtimeBackend && m_runtimeBackend->isRunning()) {
        QString runtimeStopError;
        Q_UNUSED(m_runtimeBackend->disconnectRuntime(&runtimeStopError, 0));
    }
    clearManagedRuntimeRecord();
    if (m_systemProxyApplied || m_killSwitchEnabled || (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect)) {
        QString ignored;
        Q_UNUSED(m_systemProxyManager->disable(&ignored, true));
        m_systemProxyApplied = false;
    }
    delete m_systemProxyManager;
    m_systemProxyManager = nullptr;
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

QString VpnController::latestRecordedUsage() const
{
    if (connected()) {
        return formatBytes(qMax<qint64>(0, m_rxBytes) + qMax<qint64>(0, m_txBytes));
    }

    QString profileId = m_currentProfileId.trimmed();
    if (profileId.isEmpty()) {
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            profileId = profile->id.trimmed();
        }
    }
    const QVariantMap latest = latestUsageSnapshotForId(profileId);
    const QString text = latest.value(QString::fromUtf8("totalText")).toString().trimmed();
    return text.isEmpty() ? QString::fromUtf8("0 B") : text;
}

QString VpnController::memoryUsageText() const
{
    if (m_memoryUsageBytes <= 0) {
        return QString::fromUtf8("--");
    }
    return formatBytes(m_memoryUsageBytes);
}

bool VpnController::speedTestRunning() const
{
    return m_speedTestRunning;
}

QString VpnController::speedTestState() const
{
    return m_speedTestState;
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

double VpnController::speedTestProgress() const
{
    return m_speedTestProgress;
}

double VpnController::speedTestCurrentMbps() const
{
    return m_speedTestCurrentMbps;
}

double VpnController::speedTestPeakMbps() const
{
    return m_speedTestPeakMbps;
}

double VpnController::speedTestAverageMbps() const
{
    return m_speedTestAverageMbps;
}

int VpnController::speedTestPingMs() const
{
    return m_speedTestPingMs;
}

int VpnController::speedTestJitterMs() const
{
    return m_speedTestJitterMs;
}

double VpnController::speedTestPacketLossPct() const
{
    return m_speedTestPacketLossPct;
}

int VpnController::speedTestRouteStabilityPct() const
{
    return m_speedTestRouteStabilityPct;
}

int VpnController::speedTestQualityScore() const
{
    return m_speedTestQualityScore;
}

int VpnController::speedTestLatencyMinMs() const
{
    return m_speedTestLatencyMinMs;
}

int VpnController::speedTestLatencyMaxMs() const
{
    return m_speedTestLatencyMaxMs;
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

int VpnController::speedTestSelectedSizeMb() const
{
    return m_speedTestSelectedSizeMb;
}

void VpnController::setSpeedTestSelectedSizeMb(int sizeMb)
{
    const int normalized = normalizedSpeedTestSizeMb(sizeMb);
    if (m_speedTestSelectedSizeMb == normalized) {
        return;
    }
    m_speedTestSelectedSizeMb = normalized;
    emit speedTestChanged();
    saveSettings();
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

    if (index < -1 || index >= m_profileModel->rowCount()) {
        return;
    }

    const int previousIndex = m_currentProfileIndex;
    m_currentProfileIndex = index;
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
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

    const bool runtimeActive = (m_runtimeBackend && m_runtimeBackend->isRunning()) || m_privilegedTunManaged;
    if (!busy()
        && previousIndex >= 0
        && previousIndex != m_currentProfileIndex
        && (connected() || runtimeActive)) {
        m_pendingReconnectProfileIndex = m_currentProfileIndex;
        appendSystemLog(QString::fromUtf8("[System] Switching to selected profile..."));
        disconnect();
    }
}

QObject *VpnController::profileModel()
{
    return m_profileModel;
}

QObject *VpnController::updater()
{
    return m_updater;
}

QObject *VpnController::powerModeManager()
{
    return m_powerModeManager;
}

QString VpnController::powerMode() const
{
    return m_powerModeManager ? m_powerModeManager->modeName() : QString::fromUtf8("Normal");
}

void VpnController::setPowerMode(const QString& mode)
{
    if (!m_powerModeManager) {
        return;
    }
    m_powerModeManager->setModeName(mode);
}

QStringList VpnController::powerModeOptions() const
{
    return m_powerModeManager
        ? m_powerModeManager->modeOptions()
        : QStringList {QString::fromUtf8("Save"), QString::fromUtf8("Normal"), QString::fromUtf8("High Performance")};
}

QVariantMap VpnController::powerPolicy() const
{
    return m_powerModeManager ? m_powerModeManager->effectivePolicyVariant() : QVariantMap();
}

QVariantMap VpnController::visualPowerPolicy() const
{
    return m_powerModeManager ? m_powerModeManager->visualPolicyVariant() : QVariantMap();
}

QVariantMap VpnController::powerDiagnostics() const
{
    return m_powerModeManager ? m_powerModeManager->diagnosticsVariant() : QVariantMap();
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
        const auto allProfiles = m_profileModel->profiles();
        for (const ServerProfile& profile : allProfiles) {
            if (profile.sourceId.trimmed() == entry.id) {
                ++profileCounter;
            }
        }

        QVariantMap item;
        item.insert(QString::fromUtf8("id"), entry.id);
        item.insert(QString::fromUtf8("name"), entry.name);
        item.insert(QString::fromUtf8("group"), entry.group);
        item.insert(QString::fromUtf8("url"), entry.url);
        item.insert(QString::fromUtf8("profileCount"), profileCounter);
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
        item.insert(QString::fromUtf8("name"), options.name);
        item.insert(QString::fromUtf8("enabled"), options.enabled);
        item.insert(QString::fromUtf8("exclusive"), options.exclusive);
        item.insert(QString::fromUtf8("badge"), options.badge);
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
    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
        m_currentProfileGroup = QString::fromUtf8("All");
        emit currentProfileGroupChanged();
    }

    recomputeProfileStats();
}

void VpnController::setProfileGroupExclusive(const QString& groupName, bool exclusive)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
    appendSystemLog(QString::fromUtf8("[Group] Added group '%1'.").arg(normalized));
    return true;
}

bool VpnController::removeProfileGroup(const QString& groupName)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0
        || normalized.compare(QString::fromUtf8("General"), Qt::CaseInsensitive) == 0) {
        return false;
    }

    bool changed = false;

    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        if (normalizeGroupName(entry.group).compare(normalized, Qt::CaseInsensitive) == 0) {
            entry.group = QString::fromUtf8("General");
            changed = true;
        }
    }

    auto profiles = m_profileModel->profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        if (normalizeGroupName(profile.groupName).compare(normalized, Qt::CaseInsensitive) == 0) {
            profile.groupName = QString::fromUtf8("General");
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
        m_profileModel->setProfiles(profiles);
        saveProfiles();
    }
    saveSubscriptions();
    emit subscriptionsChanged();
    refreshProfileGroups();
    recomputeProfileStats();
    saveSettings();
    appendSystemLog(QString::fromUtf8("[Group] Removed group '%1' and moved profiles/subscriptions to General.")
                        .arg(normalized));
    return true;
}

int VpnController::removeAllProfileGroups()
{
    int removedGroups = 0;
    for (const QString& name : m_profileGroups) {
        if (name.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0
            || name.compare(QString::fromUtf8("General"), Qt::CaseInsensitive) == 0) {
            continue;
        }
        ++removedGroups;
    }

    bool changed = false;
    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        const QString normalized = normalizeGroupName(entry.group);
        if (normalized.compare(QString::fromUtf8("General"), Qt::CaseInsensitive) != 0) {
            entry.group = QString::fromUtf8("General");
            changed = true;
        }
    }

    auto profiles = m_profileModel->profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        const QString normalized = normalizeGroupName(profile.groupName);
        if (normalized.compare(QString::fromUtf8("General"), Qt::CaseInsensitive) != 0) {
            profile.groupName = QString::fromUtf8("General");
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
        m_profileModel->setProfiles(profiles);
        saveProfiles();
    }
    saveSubscriptions();
    emit subscriptionsChanged();
    refreshProfileGroups();
    recomputeProfileStats();
    saveSettings();
    appendSystemLog(QString::fromUtf8("[Group] Cleared all custom groups. Everything moved to General."));
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
        normalized = QString::fromUtf8("All");
    }
    if (normalized.compare(QString::fromUtf8("all"), Qt::CaseInsensitive) == 0) {
        normalized = QString::fromUtf8("All");
    }

    if (normalized.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalized)) {
        normalized = QString::fromUtf8("All");
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

bool VpnController::runtimeTunActive() const
{
    return m_connectionState == ConnectionState::Connected && m_effectiveTunMode;
}

bool VpnController::killSwitchEnabled() const
{
    return m_killSwitchEnabled;
}

void VpnController::setUseSystemProxy(bool enabled)
{
    if (enabled && !m_runtimeSupportsSystemProxy) {
        setLastError(QString::fromUtf8("System proxy management is not supported on this platform runtime."));
        appendSystemLog(QString::fromUtf8("[System] System proxy is unavailable on this runtime."));
        return;
    }

    if (m_useSystemProxy == enabled) {
        return;
    }

    m_useSystemProxy = enabled;
    emit useSystemProxyChanged();
    saveSettings();
    QSettings settings;
    settings.setValue(QString::fromUtf8("network/modeExplicitlyChosen"), true);

    if (m_connectionState == ConnectionState::Connected) {
        applySystemProxy(enabled, !enabled);
    }
}

void VpnController::setTunMode(bool enabled)
{
    if (enabled && !m_runtimeSupportsTun) {
        setLastError(QString::fromUtf8("TUN mode is not supported on this platform runtime."));
        appendSystemLog(QString::fromUtf8("[System] TUN mode is unavailable on this runtime."));
        return;
    }

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
    settings.setValue(QString::fromUtf8("network/modeExplicitlyChosen"), true);
}

void VpnController::setKillSwitchEnabled(bool enabled)
{
    if (enabled && !m_runtimeSupportsSystemProxy) {
        setLastError(QString::fromUtf8("Kill Switch requires system proxy support on this runtime."));
        appendSystemLog(QString::fromUtf8("[System] Kill Switch is unavailable on this runtime."));
        return;
    }

    if (m_killSwitchEnabled == enabled) {
        return;
    }

    m_killSwitchEnabled = enabled;
    emit killSwitchEnabledChanged();
    saveSettings();
    applyKillSwitchState(enabled
                             ? QString::fromUtf8("Kill Switch enabled.")
                             : QString::fromUtf8("Kill Switch disabled."));
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
    return currentProfileUsageText(QString::fromUtf8("hour"));
}

QString VpnController::currentProfileUsageDay() const
{
    return currentProfileUsageText(QString::fromUtf8("day"));
}

QString VpnController::currentProfileUsageWeek() const
{
    return currentProfileUsageText(QString::fromUtf8("week"));
}

QString VpnController::currentProfileUsageMonth() const
{
    return currentProfileUsageText(QString::fromUtf8("month"));
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

bool VpnController::isMobile() const
{
    return m_runtimeIsMobile;
}

bool VpnController::isDesktop() const
{
    return m_runtimeIsDesktop;
}

bool VpnController::supportsSystemProxy() const
{
    return m_runtimeSupportsSystemProxy;
}

bool VpnController::supportsTun() const
{
    return m_runtimeSupportsTun;
}

bool VpnController::supportsPerAppRouting() const
{
    return m_runtimeSupportsPerAppRouting;
}

bool VpnController::supportsAutoUpdate() const
{
    return m_runtimeSupportsAutoUpdate;
}

bool VpnController::requiresVpnPermission() const
{
    return m_runtimeRequiresVpnPermission;
}

bool VpnController::requiresForegroundService() const
{
    return m_runtimeRequiresForegroundService;
}

bool VpnController::requiresNetworkExtension() const
{
    return m_runtimeRequiresNetworkExtension;
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
        profile.name = QString::fromUtf8("%1 %2")
        .arg(profile.protocol.toUpper(), profile.address);
    }
    profile.groupName = normalizeGroupName(m_currentProfileGroup);
    profile.sourceName = QString::fromUtf8("Manual import");
    profile.sourceId = QString::fromUtf8("manual");

    if (!m_profileModel->addProfile(profile)) {
        setLastError(QString::fromUtf8("Failed to add imported profile."));
        return false;
    }

    saveProfiles();

    const int importedIndex = m_profileModel->indexOfId(profile.id);
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
        setLastError(QString::fromUtf8("No supported VMESS/VLESS links found in input."));
        return 0;
    }

    int lastImportedIndex = -1;
    const QString groupName = normalizeGroupName(m_currentProfileGroup);
    const int importCount = importLinks(
        links,
        QString::fromUtf8("manual"),
        QString::fromUtf8("Manual import"),
        groupName,
        &lastImportedIndex
        );

    if (importCount <= 0) {
        setLastError(QString::fromUtf8("No valid profiles were imported from input."));
        return 0;
    }

    saveProfiles();
    if (m_currentProfileIndex < 0 && lastImportedIndex >= 0) {
        setCurrentProfileIndex(lastImportedIndex);
    }
    if (m_autoPingProfiles) {
        pingAllProfiles();
    }

    appendSystemLog(QString::fromUtf8("[Import] Imported %1 profile(s).").arg(importCount));
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
    if (!parsedUrl.isValid() || (parsedUrl.scheme() != QString::fromUtf8("http") && parsedUrl.scheme() != QString::fromUtf8("https"))) {
        setLastError(QString::fromUtf8("Subscription URL must be a valid http(s) link."));
        return false;
    }

    if (m_subscriptionBusy) {
        setLastError(QString::fromUtf8("Another subscription operation is already running."));
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

    beginSubscriptionOperation(QString::fromUtf8("Fetching %1...").arg(entry.name));
    startSubscriptionFetch(entry, false);
    return true;
}

int VpnController::refreshSubscriptions()
{
    if (m_subscriptionBusy) {
        appendSystemLog(QString::fromUtf8("[Subscription] Another subscription operation is already running."));
        return 0;
    }

    if (m_subscriptionEntries.isEmpty()) {
        const QString message = QString::fromUtf8("No saved subscriptions.");
        appendSystemLog(QString::fromUtf8("[Subscription] %1").arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = m_subscriptionEntries;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(QString::fromUtf8("Refreshing subscriptions..."));
    startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
    return m_subscriptionEntries.size();
}

int VpnController::refreshSubscriptionsByGroup(const QString& group)
{
    if (m_subscriptionBusy) {
        appendSystemLog(QString::fromUtf8("[Subscription] Another subscription operation is already running."));
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
        const QString message = QString::fromUtf8("No subscriptions in group '%1'.").arg(normalizedGroup);
        appendSystemLog(QString::fromUtf8("[Subscription] %1").arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = filtered;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(QString::fromUtf8("Refreshing group '%1'...").arg(normalizedGroup));
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
                                             ? QString::fromUtf8("Manual import")
                                             : sourceName.trimmed();
    const QString normalizedSourceId = sourceId.trimmed().isEmpty()
                                           ? QString::fromUtf8("manual")
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
            profile.name = QString::fromUtf8("%1 %2")
            .arg(profile.protocol.toUpper(), profile.address);
        }
        profile.groupName = normalizedGroup;
        profile.sourceName = normalizedSourceName;
        profile.sourceId = normalizedSourceId;
        if (m_profileModel->addProfile(profile)) {
            ++importCount;
            lastIndex = m_profileModel->indexOfId(profile.id);
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
            endSubscriptionOperation(QString::fromUtf8("Invalid subscription URL."));
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
                appendSystemLog(QString::fromUtf8("[Subscription] Imported %1 profile(s) from %2 (%3).")
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
                appendSystemLog(QString::fromUtf8("[Subscription] Refresh failed for %1 (%2): %3")
                                    .arg(entry.name, entry.group, hadError ? netError : QString::fromUtf8("no valid profiles")));
            }
            if (!m_subscriptionRefreshQueue.isEmpty()) {
                startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
                return;
            }
            finishRefreshSubscriptions();
            return;
        }

        if (importedCount > 0) {
            endSubscriptionOperation(QString::fromUtf8("Imported %1 profile(s).").arg(importedCount));
            return;
        }

        const QString message = hadError
                                    ? (timedOut
                                           ? QString::fromUtf8("Subscription fetch timed out.")
                                           : (netError.isEmpty()
                                                  ? QString::fromUtf8("Failed to fetch subscription URL.")
                                                  : QString::fromUtf8("Subscription fetch failed: %1").arg(netError)))
                                    : QString::fromUtf8("Subscription payload has no supported VMESS/VLESS links.");
        appendSystemLog(QString::fromUtf8("[Subscription] %1 (%2): %3")
                            .arg(entry.name, entry.group, message));
        setLastError(message);
        endSubscriptionOperation(message);
    });
}

void VpnController::finishRefreshSubscriptions()
{
    const QString message = QString::fromUtf8("Refresh complete. Success: %1, failed: %2.")
    .arg(m_subscriptionRefreshSuccessCount)
        .arg(m_subscriptionRefreshFailCount);
    appendSystemLog(QString::fromUtf8("[Subscription] %1").arg(message));
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

    if (options.name.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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

    if (normalized.name.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
    groups.append(QString::fromUtf8("All"));

    QSet<QString> seen;
    seen.insert(QString::fromUtf8("all"));

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

    const auto allProfiles = m_profileModel->profiles();
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
        if (options.name.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalizedCurrent.isEmpty() || normalizedCurrent.compare(QString::fromUtf8("all"), Qt::CaseInsensitive) == 0) {
        normalizedCurrent = QString::fromUtf8("All");
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
        normalizedCurrent = QString::fromUtf8("All");
    }
    if (normalizedCurrent.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalizedCurrent)) {
        normalizedCurrent = QString::fromUtf8("All");
    }

    if (m_currentProfileGroup != normalizedCurrent) {
        m_currentProfileGroup = normalizedCurrent;
        emit currentProfileGroupChanged();
        saveSettings();
    }
}

void VpnController::recomputeProfileStats()
{
    const int totalCount = m_profileModel->rowCount();
    const QString normalizedCurrentGroup = normalizeGroupName(m_currentProfileGroup);
    const bool allGroups = (m_currentProfileGroup.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0);

    int filteredCount = 0;
    int best = -1;
    int worst = -1;
    int successCount = 0;
    qint64 sumPing = 0;

    for (int i = 0; i < totalCount; ++i) {
        const auto profile = m_profileModel->profileAt(i);
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
    if (!m_profileModel->removeAt(row)) {
        return false;
    }

    const int rowCount = m_profileModel->rowCount();
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
    return updateProfile(row, name, groupName, QString());
}

bool VpnController::updateProfile(
    int row,
    const QString& name,
    const QString& groupName,
    const QString& configLink
)
{
    QList<ServerProfile> profiles = m_profileModel->profiles();
    if (row < 0 || row >= profiles.size()) {
        setLastError(QString::fromUtf8("Profile is no longer available."));
        return false;
    }

    ServerProfile& profile = profiles[row];
    const QString cleanName = name.trimmed();
    const QString cleanGroup = normalizeGroupName(groupName);
    const bool configProvided = !configLink.isNull();
    const QString cleanLink = configLink.trimmed();
    bool changed = false;

    if (configProvided && !cleanLink.isEmpty() && cleanLink != profile.originalLink.trimmed()) {
        QString parseError;
        auto parsedProfile = LinkParser::parse(cleanLink, &parseError);
        if (!parsedProfile.has_value()) {
            setLastError(parseError.trimmed().isEmpty()
                ? QString::fromUtf8("Profile config is not valid.")
                : QString::fromUtf8("Profile config is not valid: %1").arg(parseError.trimmed()));
            return false;
        }

        ServerProfile replacement = parsedProfile.value();
        replacement.id = profile.id;
        replacement.groupName = profile.groupName;
        replacement.sourceName = profile.sourceName;
        replacement.sourceId = profile.sourceId;
        replacement.lastPingMs = profile.lastPingMs;
        replacement.pingInProgress = false;
        profile = replacement;
        changed = true;
    } else if (configProvided && cleanLink.isEmpty() && !profile.originalLink.trimmed().isEmpty()) {
        setLastError(QString::fromUtf8("Profile config cannot be empty."));
        return false;
    }

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

    m_profileModel->setProfiles(profiles);
    upsertProfileGroupOptions(profileGroupOptionsFor(cleanGroup), false);
    refreshProfileGroups();
    recomputeProfileStats();
    saveProfiles();
    saveSettings();
    if (row == m_currentProfileIndex) {
        emit currentProfileIndexChanged();
    }
    appendSystemLog(QString::fromUtf8("[Profile] Updated profile '%1'.").arg(profile.displayLabel()));
    return true;
}

int VpnController::removeAllProfiles()
{
    const auto allProfiles = m_profileModel->profiles();
    if (allProfiles.isEmpty()) {
        return 0;
    }

    QSet<QString> protectedIds;
    const QString currentId = m_currentProfileId.trimmed();
    if (!currentId.isEmpty()) {
        protectedIds.insert(currentId);
    }
    const QString activeUsageId = m_activeProfileUsageId.trimmed();
    if (!activeUsageId.isEmpty()) {
        protectedIds.insert(activeUsageId);
    }

    QList<ServerProfile> keptProfiles;
    keptProfiles.reserve(allProfiles.size());
    int removedCount = 0;

    for (const ServerProfile& profile : allProfiles) {
        const QString profileId = profile.id.trimmed();
        if (!profileId.isEmpty() && protectedIds.contains(profileId)) {
            keptProfiles.append(profile);
            continue;
        }
        ++removedCount;
    }

    if (removedCount <= 0) {
        return 0;
    }

    m_profileModel->setProfiles(keptProfiles);

    if (!keptProfiles.isEmpty()) {
        const QString keepId = keptProfiles.first().id.trimmed();
        const int keepIndex = m_profileModel->indexOfId(keepId);
        setCurrentProfileIndex(keepIndex >= 0 ? keepIndex : 0);
    } else {
        setCurrentProfileIndex(-1);
        m_currentProfileId.clear();
    }

    if (!m_currentProfileId.trimmed().isEmpty()
        && m_profileModel->indexOfId(m_currentProfileId.trimmed()) < 0) {
        m_currentProfileId = keptProfiles.isEmpty() ? QString() : keptProfiles.first().id.trimmed();
    }

    saveProfiles();
    saveSettings();
    if (keptProfiles.isEmpty()) {
        appendSystemLog(QString::fromUtf8("[Profile] Removed all profiles."));
    } else {
        appendSystemLog(
            QString::fromUtf8("[Profile] Removed %1 inactive profile(s); kept %2 active profile(s).")
                .arg(removedCount)
                .arg(keptProfiles.size()));
    }
    return removedCount;
}

void VpnController::pingProfile(int row)
{
    const auto profile = m_profileModel->profileAt(row);
    if (!profile.has_value()) {
        return;
    }

    const QString address = profile->address.trimmed();
    const quint16 port = profile->port;
    const QString profileId = profile->id.trimmed();
    int currentRow = row;
    if (!profileId.isEmpty()) {
        currentRow = m_profileModel->indexOfId(profileId);
    }
    if (currentRow < 0) {
        return;
    }

    if (address.isEmpty() || port == 0) {
        m_profileModel->setPingResult(currentRow, -1);
        return;
    }

    m_profileModel->setPinging(currentRow, true);

    auto *socket = new QTcpSocket(this);
    socket->setProperty("_geny_ping_done", false);
    socket->setProperty("_geny_ping_start_ms", QDateTime::currentMSecsSinceEpoch());

    auto finishPing = [this, socket, profileId, currentRow](int pingMs) mutable {
        if (socket->property("_geny_ping_done").toBool()) {
            return;
        }
        socket->setProperty("_geny_ping_done", true);

        int rowNow = -1;
        if (!profileId.isEmpty()) {
            rowNow = m_profileModel->indexOfId(profileId);
        }
        if (rowNow < 0) {
            rowNow = currentRow;
        }
        if (rowNow >= 0) {
            m_profileModel->setPingResult(rowNow, pingMs);
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
    const bool allGroups = (m_currentProfileGroup.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0);

    const int count = m_profileModel->rowCount();
    int scheduled = 0;
    for (int row = 0; row < count; ++row) {
        const auto profile = m_profileModel->profileAt(row);
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

        const QString profileId = profile->id.trimmed();
        const int fallbackRow = row;
        QTimer::singleShot(scheduled * kProfilePingStaggerMs, this, [this, profileId, fallbackRow]() {
            int rowNow = -1;
            if (!profileId.isEmpty()) {
                rowNow = m_profileModel->indexOfId(profileId);
            }
            if (rowNow < 0) {
                rowNow = fallbackRow;
            }
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

    if (row < 0 || row >= m_profileModel->rowCount()) {
        setLastError(QString::fromUtf8("Please select a valid server profile."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (!m_runtimeBackend) {
        setLastError(QString::fromUtf8("Runtime backend is not available."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    // If runtime is alive, perform a coordinated reconnect when user selected
    // another profile instead of silently keeping stale runtime state.
    if ((m_runtimeBackend && m_runtimeBackend->isRunning()) || m_privilegedTunManaged) {
        if (row != m_currentProfileIndex || m_pendingReconnectProfileIndex >= 0) {
            m_pendingReconnectProfileIndex = row;
            appendSystemLog(QString::fromUtf8("[System] Restarting tunnel with selected profile..."));
            disconnect();
            return;
        }
        setConnectionState(ConnectionState::Connected);
        appendSystemLog(QString::fromUtf8("[System] Xray is already running. Disconnect first before reconnecting."));
        return;
    }

    if (connected() && row == m_currentProfileIndex) {
        appendSystemLog(QString::fromUtf8("[System] Selected profile is already connected."));
        return;
    }

    auto profile = m_profileModel->profileAt(row);
    if (!profile.has_value()) {
        setLastError(QString::fromUtf8("Please select a valid server profile."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_runtimeIsDesktop && m_xrayExecutablePath.trimmed().isEmpty()) {
        setLastError(QString::fromUtf8("Set the xray-core executable path first."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    QString executableError;
    if (m_runtimeIsDesktop && !ensureExecutableFile(m_xrayExecutablePath, &executableError)) {
        setLastError(executableError);
        setConnectionState(ConnectionState::Error);
        return;
    }

    setCurrentProfileIndex(row);
    const quint64 connectAttempt = m_connectAttemptCounter.fetch_add(1) + 1;
    m_disconnectRequested.store(false);
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
    if (m_tunMode && m_runtimeIsDesktop) {
        QString copiedFrom;
        QString runtimeError;
        if (!ensureWindowsTunRuntimeReady(m_xrayExecutablePath, m_dataDirectory, &copiedFrom, &runtimeError)) {
            appendSystemLog(QString::fromUtf8("[System] %1").arg(runtimeError));
            setLastError(runtimeError);
            setConnectionState(ConnectionState::Error);
            return;
        }
        if (!copiedFrom.trimmed().isEmpty()) {
            appendSystemLog(QString::fromUtf8("[System] Copied wintun.dll for TUN runtime from: %1").arg(copiedFrom));
        }
    }
#endif

    if (m_tunMode && m_runtimeIsDesktop) {
        setConnectionState(ConnectionState::Connecting);
        setLastError(QString());
        const QPointer<VpnController> guard(this);
        [[maybe_unused]] auto tunStartFuture = QtConcurrent::run([guard, connectAttempt]() {
            QString elevateError;
            bool ok = false;
            if (guard) {
                ok = guard->startPrivilegedTunProcess(&elevateError);
            }
            if (guard
                && ok
                && (guard->m_shutdownInProgress.load()
                    || guard->m_disconnectRequested.load()
                    || guard->m_connectAttemptCounter.load() != connectAttempt)) {
                QString stopError;
                Q_UNUSED(guard->stopPrivilegedTunProcess(&stopError));
                guard->stopPrivilegedTunRuntimeByPidPath();
                guard->m_privilegedTunRuntimePid = -1;
                ok = false;
                elevateError = QString::fromUtf8("Connection attempt was cancelled.");
            }
            if (!guard) {
                return;
            }
            QMetaObject::invokeMethod(guard.data(), [guard, ok, elevateError, connectAttempt]() {
                if (!guard) {
                    return;
                }
                if (guard->m_connectAttemptCounter.load() != connectAttempt && !guard->m_shutdownInProgress.load()) {
                    return;
                }
                if (ok) {
                    if (guard->m_powerModeManager) {
                        guard->m_powerModeManager->recordReconnectSuccess();
                    }
                    guard->m_disconnectRequested.store(false);
                    guard->m_privilegedTunManaged = true;
                    guard->m_privilegedTunLogOffset = 0;
                    guard->m_privilegedTunLogBuffer.clear();
                    guard->m_privilegedTunLogTimer.start();
                    guard->writeManagedRuntimeRecord(guard->m_privilegedTunRuntimePid, QString::fromUtf8("tun"));
                    guard->beginProfileUsageSession(guard->m_activeProfileUsageId);
                    guard->setConnectionState(ConnectionState::Connected);
                    guard->setLastError(QString());
                    guard->appendSystemLog(QString::fromUtf8("[System] TUN mode active: system traffic should route through Xray TUN."));
                    guard->appendSystemLog(QString::fromUtf8("[System] Xray started (privileged TUN). Local proxy (mixed): 127.0.0.1:%1.")
                                               .arg(guard->m_buildOptions.socksPort));
                    guard->m_statsPollTimer.start();
                    guard->pollTrafficStats();
                    QTimer::singleShot(guard->startupSelfCheckDelayMs(), guard.data(), [guard]() {
                        if (guard) {
                            guard->runProxySelfCheck();
                        }
                    });
                    return;
                }

                guard->m_privilegedTunManaged = false;
                guard->m_privilegedTunRuntimePid = -1;
                if (!elevateError.trimmed().isEmpty()) {
                    guard->appendSystemLog(QString::fromUtf8("[System] %1").arg(elevateError));
                    guard->setLastError(elevateError);
                } else {
                    guard->setLastError(QString::fromUtf8("Failed to start privileged TUN runtime."));
                }
                guard->setConnectionState(ConnectionState::Error);
            }, Qt::QueuedConnection);
        });
        return;
    }

    m_rxBytes = 0;
    m_txBytes = 0;
    resetPerProfileUsageSamples();
    emit trafficChanged();

    setConnectionState(ConnectionState::Connecting);
    setLastError(QString());
    m_disconnectRequested.store(false);

    QString processError;
    if (!m_runtimeBackend->connectRuntime(
            m_xrayExecutablePath,
            m_runtimeConfigPath,
            m_dataDirectory,
            &processError)) {
        if (processError.trimmed().isEmpty()) {
            processError = m_runtimeBackend->lastError().trimmed();
        }
        if (processError.trimmed().isEmpty()) {
            processError = QString::fromUtf8("Failed to start VPN runtime.");
        }
        if (isAndroidVpnPermissionRequiredMessage(processError)) {
            appendSystemLog(QString::fromUtf8("[System] %1").arg(processError.trimmed()));
            setLastError(QString());
            setConnectionState(ConnectionState::Disconnected);
            return;
        }
        appendSystemLog(QString::fromUtf8("[System] %1").arg(processError.trimmed()));
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
    m_disconnectRequested.store(true);
    m_connectAttemptCounter.fetch_add(1);
    m_statsPollTimer.stop();
    m_publicIpRetryTimer.stop();
    if (m_publicIpReply) {
        QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
        m_publicIpRefreshing = false;
        emit publicIpAddressChanged();
    }
    cancelSpeedTest();
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
                guard->m_privilegedTunRuntimePid = -1;
                guard->clearManagedRuntimeRecord();
                guard->endProfileUsageSession(guard->m_activeProfileUsageId);
                if (!stopped && !stopError.trimmed().isEmpty()) {
                    guard->appendSystemLog(QString::fromUtf8("[System] %1").arg(stopError));
                    guard->stopPrivilegedTunRuntimeByPidPath();
                }
                guard->m_disconnectRequested.store(false);
                guard->setConnectionState(ConnectionState::Disconnected);
                guard->maybeReconnectToPendingProfile();
            }, Qt::QueuedConnection);
        });
        return;
    }

    if (m_runtimeBackend && m_runtimeBackend->isRunning()) {
        m_stoppingProcess = true;
        setConnectionState(ConnectionState::Connecting);
        QString runtimeStopError;
        Q_UNUSED(m_runtimeBackend->disconnectRuntime(&runtimeStopError, 0));
        return;
    }

    clearManagedRuntimeRecord();
    endProfileUsageSession(m_activeProfileUsageId);
    m_stoppingProcess = false;
    m_disconnectRequested.store(false);
    setConnectionState(ConnectionState::Disconnected);
    maybeReconnectToPendingProfile();
}

void VpnController::toggleConnection()
{
    // Use process state as source of truth for disconnect behavior.
    if ((m_runtimeBackend && m_runtimeBackend->isRunning()) || connected() || busy()) {
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
    if (!connected()) {
        m_publicIpRetryTimer.stop();
        if (m_publicIpReply) {
            QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
            m_publicIpReply->abort();
            m_publicIpReply->deleteLater();
            m_publicIpReply = nullptr;
        }
        if (m_publicIpRefreshing) {
            m_publicIpRefreshing = false;
            emit publicIpAddressChanged();
        }
        return;
    }

#if defined(Q_OS_ANDROID)
    if (!QSslSocket::supportsSsl()) {
        m_publicIpRetryTimer.stop();
        if (m_publicIpReply) {
            QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
            m_publicIpReply->abort();
            m_publicIpReply->deleteLater();
            m_publicIpReply = nullptr;
        }
        if (m_publicIpRefreshing) {
            m_publicIpRefreshing = false;
            emit publicIpAddressChanged();
        }
        appendSystemLog(QString::fromUtf8("[System] VPN IP lookup skipped: TLS backend is unavailable in this Android build."));
        return;
    }
#endif

    if (m_publicIpReply) {
        QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
    }
    m_publicIpNetworkManager.setProxy(
        QNetworkProxy(QNetworkProxy::Socks5Proxy, QString::fromUtf8("127.0.0.1"), m_buildOptions.socksPort));

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
    connect(m_publicIpReply, &QNetworkReply::sslErrors, this, [this](const QList<QSslError>& errors) {
        Q_UNUSED(errors)
        if (m_publicIpReply != nullptr) {
            m_publicIpReply->abort();
        }
    });
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
    query.addQueryItem(QString::fromUtf8("_gc"), QString::number(QDateTime::currentMSecsSinceEpoch()));
    requestUrl.setQuery(query);

    QNetworkRequest request(requestUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("Cache-Control", "no-cache");
    request.setRawHeader("Pragma", "no-cache");
    request.setRawHeader("User-Agent", "GenyConnect-SpeedTest/1.0");
    request.setRawHeader("Accept", "application/octet-stream,*/*");
    request.setRawHeader("Accept-Encoding", "identity");
    if (upload) {
        request.setHeader(QNetworkRequest::ContentTypeHeader, QString::fromUtf8("application/octet-stream"));
    }
    const int timeoutMs = kSpeedTestDownloadTimeoutBaseMs
                          + (normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb) * kSpeedTestDownloadTimeoutPerMbMs);
    request.setTransferTimeout(timeoutMs);

    m_speedTestUploadMode = upload;
    m_speedTestReply = upload
                           ? m_speedTestNetworkManager.post(request, payload)
                           : m_speedTestNetworkManager.get(request);
    m_speedTestReply->setProperty("gc_ready_bytes", static_cast<qlonglong>(0));
    connect(m_speedTestReply, &QNetworkReply::downloadProgress, this, &VpnController::onSpeedTestDownloadProgress);
    connect(m_speedTestReply, &QNetworkReply::uploadProgress, this, &VpnController::onSpeedTestUploadProgress);
    connect(m_speedTestReply, &QNetworkReply::sslErrors, this, [this](const QList<QSslError>& errors) {
        Q_UNUSED(errors)
        if (m_speedTestReply != nullptr) {
            m_speedTestReply->abort();
        }
    });
    m_speedTestRequestTimer.restart();
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = m_speedTestBytesReceived;
    m_speedTestLastProgressElapsedMs = 0;
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

    const bool uploadPhase = (m_speedTestPhase == QString::fromUtf8("Upload"));
    const QList<QUrl> endpoints = uploadPhase
                                      ? speedTestUploadFallbackUrls(m_speedTestSelectedSizeMb)
                                      : speedTestDownloadFallbackUrls(m_speedTestSelectedSizeMb);
    if (endpoints.isEmpty()) {
        finishSpeedTest(false, QString::fromUtf8("No speed test endpoint configured."));
        return;
    }
    if (m_speedTestAttempt >= endpoints.size()) {
        finishSpeedTest(false, QString::fromUtf8("All speed test endpoints failed."));
        return;
    }
    const QUrl url = endpoints.at(m_speedTestAttempt);
    ++m_speedTestAttempt;
    if (!url.isValid()) {
        finishSpeedTest(false, QString::fromUtf8("Invalid speed test endpoint."));
        return;
    }

    const QByteArray payload = uploadPhase ? buildUploadPayload() : QByteArray();
    startSpeedTestRequest(url, uploadPhase, payload);
}

void VpnController::startPingPhase()
{
    m_speedTestState = QString::fromUtf8("Testing");
    m_speedTestPhase = QString::fromUtf8("Latency");
    m_speedTestDurationSec = 2;
    m_speedTestElapsedSec = 0;
    m_speedTestProgress = 0.0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestAverageMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestLatencyAttemptCount = 0;
    m_speedTestLatencySuccessCount = 0;
    m_speedTestLatencySamples.clear();
    m_speedTestPingMs = -1;
    m_speedTestJitterMs = -1;
    m_speedTestLatencyMinMs = -1;
    m_speedTestLatencyMaxMs = -1;
    m_speedTestPacketLossPct = 0.0;
    m_speedTestRouteStabilityPct = 0;
    m_speedTestQualityScore = -1;
    m_speedTestMeasuredBytes = 0;
    m_speedTestMeasuredDurationMs = 0;
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = 0;
    m_speedTestWarmupUntilMs = 0;
    m_speedTestExpectedBytes = 0;
    m_speedTestPhaseTimer.restart();
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();

    QTimer::singleShot(0, this, [this]() {
        runNextSpeedTestLatencyProbe();
    });
}

void VpnController::startDownloadPhase()
{
    m_speedTestState = QString::fromUtf8("Testing");
    m_speedTestPhase = QString::fromUtf8("Download");
    m_speedTestDurationSec = qMax(4, normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb));
    m_speedTestElapsedSec = 0;
    m_speedTestProgress = 0.0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestAverageMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestMeasuredBytes = 0;
    m_speedTestMeasuredDurationMs = 0;
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = 0;
    m_speedTestAttempt = 0;
    m_speedTestExpectedBytes =
        static_cast<qint64>(normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb)) * 1024 * 1024;
    m_speedTestPhaseTimer.restart();
    m_speedTestWarmupUntilMs = kSpeedTestWarmupMs;
    m_speedTestLastProgressElapsedMs = 0;
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();

    startCurrentSpeedTestRequest();
}

void VpnController::startUploadPhase()
{
    m_speedTestState = QString::fromUtf8("Testing");
    m_speedTestPhase = QString::fromUtf8("Upload");
    m_speedTestDurationSec = qMax(3, normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb) / 2);
    m_speedTestElapsedSec = 0;
    m_speedTestProgress = 0.0;
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestAverageMbps = 0.0;
    m_speedTestPhaseBytes = 0;
    m_speedTestLastBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestMeasuredBytes = 0;
    m_speedTestMeasuredDurationMs = 0;
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = 0;
    m_speedTestAttempt = 0;
    m_speedTestExpectedBytes = kSpeedTestUploadPayloadBytes;
    m_speedTestPhaseTimer.restart();
    m_speedTestWarmupUntilMs = kSpeedTestWarmupMs;
    m_speedTestLastProgressElapsedMs = 0;
    m_speedTestSampleTimer.restart();
    emit speedTestChanged();
    startCurrentSpeedTestRequest();
}

void VpnController::startAnalyzePhase()
{
    m_speedTestState = QString::fromUtf8("Analyzing");
    m_speedTestPhase = QString::fromUtf8("Analyzing");
    m_speedTestDurationSec = 1;
    m_speedTestElapsedSec = 0;
    m_speedTestProgress = 1.0;
    finalizeSpeedTestQualityMetrics();
    emit speedTestChanged();
}

void VpnController::runNextSpeedTestLatencyProbe()
{
    if (!m_speedTestRunning || m_speedTestPhase != QString::fromUtf8("Latency")) {
        return;
    }

    if (m_speedTestLatencyAttemptCount >= kSpeedTestLatencyProbeCount) {
        finalizeSpeedTestLatencyMetrics();
        startDownloadPhase();
        return;
    }

    const QList<QUrl> endpoints = speedTestDownloadFallbackUrls(m_speedTestSelectedSizeMb);
    if (endpoints.isEmpty()) {
        finishSpeedTest(false, QString::fromUtf8("No speed test endpoint available for latency probe."));
        return;
    }

    const QUrl endpoint = endpoints.constFirst();
    const QString host = endpoint.host().trimmed();
    const int port = endpoint.port(endpoint.scheme().compare(QString::fromUtf8("https"), Qt::CaseInsensitive) == 0 ? 443 : 80);
    if (host.isEmpty() || port <= 0) {
        finishSpeedTest(false, QString::fromUtf8("Invalid endpoint host for latency probe."));
        return;
    }

    ++m_speedTestLatencyAttemptCount;
    m_speedTestProgress = qBound(
        0.0,
        static_cast<double>(m_speedTestLatencyAttemptCount) / static_cast<double>(kSpeedTestLatencyProbeCount),
        1.0);
    auto *socket = new QTcpSocket(this);
    QPointer<QTcpSocket> socketGuard(socket);
    const qint64 startedAtMs = QDateTime::currentMSecsSinceEpoch();

    auto finishProbe = [this, socketGuard, startedAtMs](bool success) {
        if (!socketGuard || socketGuard->property("gc_probe_done").toBool()) {
            return;
        }
        socketGuard->setProperty("gc_probe_done", true);
        if (!m_speedTestRunning || m_speedTestPhase != QString::fromUtf8("Latency")) {
            socketGuard->abort();
            socketGuard->deleteLater();
            return;
        }
        const qint64 elapsedRaw = QDateTime::currentMSecsSinceEpoch() - startedAtMs;
        const int elapsedMs = static_cast<int>(qMin<qint64>(qMax<qint64>(1, elapsedRaw), 60000));
        if (success) {
            ++m_speedTestLatencySuccessCount;
            m_speedTestLatencySamples.append(elapsedMs);
        }
        socketGuard->abort();
        socketGuard->deleteLater();
        finalizeSpeedTestLatencyMetrics();
        m_speedTestProgress = qBound(
            0.0,
            static_cast<double>(m_speedTestLatencyAttemptCount) / static_cast<double>(kSpeedTestLatencyProbeCount),
            1.0);
        emit speedTestChanged();
        QTimer::singleShot(kSpeedTestLatencyProbeGapMs, this, [this]() {
            runNextSpeedTestLatencyProbe();
        });
    };

    connect(socket, &QTcpSocket::connected, this, [finishProbe]() {
        finishProbe(true);
    });
    connect(socket, &QTcpSocket::errorOccurred, this, [finishProbe](QAbstractSocket::SocketError) {
        finishProbe(false);
    });

    QTimer::singleShot(kSpeedTestLatencyProbeTimeoutMs, this, [socketGuard, finishProbe]() {
        if (!socketGuard || socketGuard->property("gc_probe_done").toBool()) {
            return;
        }
        finishProbe(false);
    });

    socket->connectToHost(host, static_cast<quint16>(port));
}

void VpnController::finalizeSpeedTestLatencyMetrics()
{
    if (m_speedTestLatencySamples.isEmpty()) {
        m_speedTestPingMs = -1;
        m_speedTestJitterMs = -1;
        m_speedTestLatencyMinMs = -1;
        m_speedTestLatencyMaxMs = -1;
    } else {
        std::sort(m_speedTestLatencySamples.begin(), m_speedTestLatencySamples.end());
        m_speedTestLatencyMinMs = m_speedTestLatencySamples.constFirst();
        m_speedTestLatencyMaxMs = m_speedTestLatencySamples.constLast();
        const int p50 = percentileLatency(m_speedTestLatencySamples, 50.0);
        const int p95 = percentileLatency(m_speedTestLatencySamples, 95.0);
        m_speedTestPingMs = p50;
        m_speedTestJitterMs = qMax(0, p95 - p50);
    }

    if (m_speedTestLatencyAttemptCount > 0) {
        const int losses = qMax(0, m_speedTestLatencyAttemptCount - m_speedTestLatencySuccessCount);
        m_speedTestPacketLossPct =
            qBound(0.0, (static_cast<double>(losses) * 100.0) / static_cast<double>(m_speedTestLatencyAttemptCount), 100.0);
    } else {
        m_speedTestPacketLossPct = 0.0;
    }
}

int VpnController::percentileLatency(const QVector<int>& samples, double percentile)
{
    if (samples.isEmpty()) {
        return -1;
    }
    const QVector<int> sorted = [&samples]() {
        QVector<int> local = samples;
        std::sort(local.begin(), local.end());
        return local;
    }();
    const double ratio = qBound(0.0, percentile / 100.0, 1.0);
    const int index = qBound(0, static_cast<int>(std::round((sorted.size() - 1) * ratio)), sorted.size() - 1);
    return sorted.at(index);
}

void VpnController::finalizeSpeedTestQualityMetrics()
{
    const int latencyMs = m_speedTestPingMs >= 0 ? m_speedTestPingMs : 999;
    const int jitterMs = m_speedTestJitterMs >= 0 ? m_speedTestJitterMs : 999;
    const double lossPct = qBound(0.0, m_speedTestPacketLossPct, 100.0);

    // Conservative quality model tuned for stable UX reporting, not marketing-grade numbers.
    const double latencyPenalty = qMin(45.0, static_cast<double>(latencyMs) * 0.18);
    const double jitterPenalty = qMin(30.0, static_cast<double>(jitterMs) * 0.55);
    const double lossPenalty = qMin(40.0, lossPct * 2.2);
    const int score = static_cast<int>(qRound(qBound(0.0, 100.0 - latencyPenalty - jitterPenalty - lossPenalty, 100.0)));

    m_speedTestQualityScore = score;
    m_speedTestRouteStabilityPct = qBound(0, score, 100);
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
    m_speedTestCurrentMbps = 0.0;
    m_speedTestAverageMbps = ok ? combinedSpeedTestAverageMbps(m_speedTestDownloadMbps, m_speedTestUploadMbps) : 0.0;
    m_speedTestProgress = ok ? 1.0 : m_speedTestProgress;
    if (ok) {
        m_speedTestState = QString::fromUtf8("Completed");
        m_speedTestPhase = QString::fromUtf8("Completed");
        m_speedTestError.clear();
    } else if (m_speedTestCancelledByUser) {
        m_speedTestState = QString::fromUtf8("Cancelled");
        m_speedTestPhase = QString::fromUtf8("Cancelled");
        m_speedTestError.clear();
    } else {
        m_speedTestState = QString::fromUtf8("Failed");
        m_speedTestPhase = QString::fromUtf8("Failed");
        m_speedTestError = error;
    }
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    emit speedTestChanged();

    if (ok) {
        const double downMbps = qMax(0.0, m_speedTestDownloadMbps);
        const double upMbps = qMax(0.0, m_speedTestUploadMbps);
        const double overallMbps = qMax(0.0, m_speedTestAverageMbps);
        QString resultLine = QString::fromUtf8("Size %1 MB: DL %2 Mbps | UL %3 Mbps | AVG %4 Mbps")
                                 .arg(normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb))
                                 .arg(QString::number(downMbps, 'f', 2))
                                 .arg(QString::number(upMbps, 'f', 2))
                                 .arg(QString::number(overallMbps, 'f', 2));
        if (m_speedTestPingMs >= 0) {
            resultLine += QString::fromUtf8(" | Ping %1 ms").arg(m_speedTestPingMs);
        }
        if (m_speedTestJitterMs >= 0) {
            resultLine += QString::fromUtf8(" | Jitter %1 ms").arg(m_speedTestJitterMs);
        }
        resultLine += QString::fromUtf8(" | Loss %1%").arg(QString::number(m_speedTestPacketLossPct, 'f', 1));
        if (m_speedTestQualityScore >= 0) {
            resultLine += QString::fromUtf8(" | Quality %1/100").arg(m_speedTestQualityScore);
        }
        m_speedTestHistory.prepend(resultLine);
        while (m_speedTestHistory.size() > kSpeedTestHistoryMaxItems) {
            m_speedTestHistory.removeLast();
        }
        appendSystemLog(QString::fromUtf8("[SpeedTest] %1").arg(resultLine));
    } else if (!m_speedTestCancelledByUser) {
        appendSystemLog(QString::fromUtf8("[SpeedTest] Failed: %1").arg(error));
    } else {
        appendSystemLog(QString::fromUtf8("[SpeedTest] Cancelled."));
    }
    m_speedTestCancelledByUser = false;
    emit speedTestChanged();
}

void VpnController::startSpeedTest()
{
    if (!connected()) {
        m_speedTestError = QString::fromUtf8("Connect to VPN before running speed test.");
        m_speedTestState = QString::fromUtf8("Failed");
        m_speedTestPhase = QString::fromUtf8("Failed");
        emit speedTestChanged();
        appendSystemLog(QString::fromUtf8("[SpeedTest] %1").arg(m_speedTestError));
        return;
    }

    if (m_speedTestRunning) {
        appendSystemLog(QString::fromUtf8("[SpeedTest] A test is already in progress."));
        return;
    }

    resetSpeedTestState(false);

    m_speedTestRunning = true;
    m_speedTestCancelledByUser = false;
    m_speedTestState = QString::fromUtf8("Preparing");
    m_speedTestPhase = QString::fromUtf8("Preparing");
    m_speedTestElapsedSec = 0;
    m_speedTestDurationSec = 1;
    m_speedTestProgress = 0.0;
    m_speedTestPingMs = -1;
    m_speedTestJitterMs = -1;
    m_speedTestLatencyMinMs = -1;
    m_speedTestLatencyMaxMs = -1;
    m_speedTestPacketLossPct = 0.0;
    m_speedTestRouteStabilityPct = 0;
    m_speedTestQualityScore = -1;
    m_speedTestDownloadMbps = 0.0;
    m_speedTestUploadMbps = 0.0;
    m_speedTestAverageMbps = 0.0;
    m_speedTestError.clear();
    m_speedTestExpectedBytes = 0;
    m_speedTestBytesReceived = 0;
    m_speedTestLastBytes = 0;
    m_speedTestPhaseBytes = 0;
    m_speedTestMeasuredBytes = 0;
    m_speedTestMeasuredDurationMs = 0;
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = 0;
    m_speedTestWarmupUntilMs = 0;
    m_speedTestUsingDirectFallback = false;
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    emit speedTestChanged();

    if (m_effectiveTunMode) {
        m_speedTestNetworkManager.setProxy(QNetworkProxy::NoProxy);
    } else {
        m_speedTestNetworkManager.setProxy(
            QNetworkProxy(QNetworkProxy::Socks5Proxy, QString::fromUtf8("127.0.0.1"), m_buildOptions.socksPort));
    }

    startPingPhase();
    m_speedTestTimer.start();
    appendSystemLog(QString::fromUtf8("[SpeedTest] Starting %1 MB reliability test (latency + download + upload).")
                        .arg(normalizedSpeedTestSizeMb(m_speedTestSelectedSizeMb)));
}

void VpnController::cancelSpeedTest()
{
    const bool wasRunning = m_speedTestRunning;
    m_speedTestCancelledByUser = true;
    if (m_speedTestReply != nullptr) {
        QObject::disconnect(m_speedTestReply, nullptr, this, nullptr);
        m_speedTestReply->abort();
        m_speedTestReply->deleteLater();
        m_speedTestReply = nullptr;
    }

    if (m_speedTestTimer.isActive()) {
        m_speedTestTimer.stop();
    }

    if (wasRunning) {
        finishSpeedTest(false, QString::fromUtf8("Cancelled by user."));
        return;
    }

    resetSpeedTestState(true);
    m_speedTestState = QString::fromUtf8("Idle");
    m_speedTestCancelledByUser = false;
}

QUrl VpnController::speedTestDownloadUrlForSizeMb(int sizeMb) const
{
    const QList<QUrl> endpoints = speedTestDownloadFallbackUrls(sizeMb);
    if (endpoints.isEmpty()) {
        return {};
    }
    return endpoints.constFirst();
}

QList<QUrl> VpnController::speedTestDownloadFallbackUrls(int sizeMb) const
{
    const int normalized = normalizedSpeedTestSizeMb(sizeMb);
    const qint64 bytes = static_cast<qint64>(normalized) * 1024 * 1024;
    const int archiveSizeMb = normalized == 25 ? 20 : normalized;
    QList<QUrl> urls;
    const QString customTemplate = m_speedTestDownloadEndpointTemplate.trimmed();
    if (!customTemplate.isEmpty()) {
        const QUrl custom(customTemplate.arg(bytes));
        if (custom.isValid()) {
            urls.append(custom);
        }
    }
    urls.append(QUrl(QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=%1").arg(bytes)));
    urls.append(QUrl(QString::fromUtf8("https://ipv4.download.thinkbroadband.com/%1MB.zip").arg(archiveSizeMb)));
    urls.append(QUrl(QString::fromUtf8("http://ipv4.download.thinkbroadband.com/%1MB.zip").arg(archiveSizeMb)));
    urls.append(QUrl(QString::fromUtf8("https://speedtest.tele2.net/%1MB.zip").arg(archiveSizeMb)));
    urls.append(QUrl(QString::fromUtf8("http://speedtest.tele2.net/%1MB.zip").arg(archiveSizeMb)));
    urls.removeIf([](const QUrl& url) { return !url.isValid(); });
    return urls;
}

QList<QUrl> VpnController::speedTestUploadFallbackUrls(int sizeMb) const
{
    Q_UNUSED(sizeMb)
    QList<QUrl> urls;
    urls.append(QUrl(QString::fromUtf8("https://speed.cloudflare.com/__up")));
    urls.append(QUrl(QString::fromUtf8("https://httpbin.org/post")));
    urls.append(QUrl(QString::fromUtf8("https://postman-echo.com/post")));
    urls.removeIf([](const QUrl& url) { return !url.isValid(); });
    return urls;
}

int VpnController::normalizedSpeedTestSizeMb(int requested) const
{
    if (requested <= kSpeedTestMinimumSizeMb) {
        return kSpeedTestMinimumSizeMb;
    }
    if (requested >= kSpeedTestMaximumSizeMb) {
        return kSpeedTestMaximumSizeMb;
    }
    if (requested >= 20) {
        return 25;
    }
    if (requested >= 8) {
        return 10;
    }
    return 5;
}

QString VpnController::formatBytes(qint64 bytes) const
{
    static const QStringList units {QString::fromUtf8("B"), QString::fromUtf8("KB"), QString::fromUtf8("MB"), QString::fromUtf8("GB"), QString::fromUtf8("TB")};

    double value = static_cast<double>(bytes);
    int unitIndex = 0;

    while (value >= 1024.0 && unitIndex < units.size() - 1) {
        value /= 1024.0;
        ++unitIndex;
    }

    return QString::fromUtf8("%1 %2")
        .arg(QString::number(value, unitIndex == 0 ? 'f' : 'f', unitIndex == 0 ? 0 : 2), units.at(unitIndex));
}

QString VpnController::currentProfileAddress() const
{
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }
    return profile->address.trimmed();
}

QString VpnController::currentProfileLabel() const
{
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }
    return profile->name.trimmed();
}

QString VpnController::currentProfileSubtitle() const
{
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }

    QString subtitle = QString::fromUtf8("%1  %2:%3")
                           .arg(profile->protocol.toUpper(), profile->address, QString::number(profile->port));
    if (!profile->security.trimmed().isEmpty()) {
        subtitle += QString::fromUtf8("  |  %1").arg(profile->security.trimmed());
    }
    return subtitle;
}

QString VpnController::currentProfileGroupLabel() const
{
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return {};
    }
    return normalizeGroupName(profile->groupName);
}

int VpnController::currentProfilePingMs() const
{
    const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
    if (!profile.has_value()) {
        return -1;
    }
    return profile->lastPingMs;
}

void VpnController::copyLogsToClipboard() const
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard) {
        return;
    }

    clipboard->setText(m_recentLogs.join('\n'));
}

void VpnController::copyTextToClipboard(const QString& text) const
{
    auto *clipboard = QGuiApplication::clipboard();
    if (!clipboard) {
        return;
    }
    clipboard->setText(text);
}

bool VpnController::shareText(const QString& subject, const QString& text) const
{
    const QString message = text.trimmed();
    if (message.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject subjectObject = QJniObject::fromString(subject.trimmed());
        const QJniObject textObject = QJniObject::fromString(message);
        const jboolean shared = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "shareText",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            subjectObject.object<jstring>(),
            textObject.object<jstring>());
        if (shared) {
            return true;
        }
    }
#endif

    QUrl mailUrl(QString::fromUtf8("mailto:"));
    QUrlQuery query;
    query.addQueryItem(QString::fromUtf8("subject"),
                       subject.trimmed().isEmpty() ? QString::fromUtf8("GenyConnect") : subject.trimmed());
    query.addQueryItem(QString::fromUtf8("body"), message);
    mailUrl.setQuery(query);
    if (QDesktopServices::openUrl(mailUrl)) {
        return true;
    }

    copyTextToClipboard(message);
    return false;
}

QString VpnController::licenseText() const
{
    static QString cachedLicenseText = resolveLicenseText();
    return cachedLicenseText;
}

bool VpnController::openUrlWithChooser(const QString& url, const QString& chooserTitle) const
{
    const QUrl parsedUrl = QUrl::fromUserInput(url.trimmed());
    if (!parsedUrl.isValid() || parsedUrl.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QString chooser = chooserTitle.trimmed().isEmpty()
            ? QString::fromUtf8("Choose wallet app")
            : chooserTitle.trimmed();
        const QJniObject urlObject = QJniObject::fromString(parsedUrl.toString(QUrl::FullyEncoded));
        const QJniObject chooserObject = QJniObject::fromString(chooser);
        const jboolean opened = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "openUrlWithChooser",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            urlObject.object<jstring>(),
            chooserObject.object<jstring>());
        if (opened) {
            return true;
        }
    }
#endif

    return QDesktopServices::openUrl(parsedUrl);
}

bool VpnController::openUrlInAndroidPackage(const QString& url, const QString& packageName) const
{
    const QUrl parsedUrl = QUrl::fromUserInput(url.trimmed());
    const QString packageId = packageName.trimmed();
    if (!parsedUrl.isValid() || parsedUrl.isEmpty() || packageId.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject urlObject = QJniObject::fromString(parsedUrl.toString(QUrl::FullyEncoded));
        const QJniObject packageObject = QJniObject::fromString(packageId);
        const jboolean opened = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "openUrlInPackage",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            urlObject.object<jstring>(),
            packageObject.object<jstring>());
        if (opened) {
            return true;
        }
    }
#endif

    return false;
}

bool VpnController::isAndroidPackageInstalled(const QString& packageName) const
{
    const QString packageId = packageName.trimmed();
    if (packageId.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject packageObject = QJniObject::fromString(packageId);
        const jboolean installed = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "isPackageInstalled",
            "(Ljava/lang/String;)Z",
            packageObject.object<jstring>());
        return installed;
    }
#endif

    return false;
}

QVariantList VpnController::donationWalletTargets(const QString& transferUrl, const QString& swapUrl) const
{
    QVariantList targets;
#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject transferObject = QJniObject::fromString(transferUrl.trimmed());
        const QJniObject swapObject = QJniObject::fromString(swapUrl.trimmed());
        const QJniObject jsonObject = QJniObject::callStaticObjectMethod(
            kAndroidRuntimeBridgeClass,
            "discoverWalletTargets",
            "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
            transferObject.object<jstring>(),
            swapObject.object<jstring>());
        const QString jsonText = jsonObject.toString();
        const QJsonDocument document = QJsonDocument::fromJson(jsonText.toUtf8());
        if (document.isArray()) {
            for (const QJsonValue& value : document.array()) {
                if (value.isObject()) {
                    targets.append(value.toObject().toVariantMap());
                }
            }
        }
    }
#else
    Q_UNUSED(transferUrl);
    Q_UNUSED(swapUrl);
#endif

    if (targets.isEmpty()) {
        QVariantMap row;
        row.insert(QString::fromUtf8("id"), QString::fromUtf8("system"));
        row.insert(QString::fromUtf8("label"), QString::fromUtf8("Any Compatible Wallet"));
        row.insert(QString::fromUtf8("mode"), QString::fromUtf8("chooser"));
        row.insert(QString::fromUtf8("packageName"), QString());
        targets.append(row);
    }

    return targets;
}

QVariantMap VpnController::donationConfig() const
{
    QVariantMap config;
    config.insert(QString::fromUtf8("networkName"), QString::fromUtf8(kDonationBaseChainName));
    config.insert(QString::fromUtf8("chainId"), kDonationBaseChainId);
    config.insert(QString::fromUtf8("receiverWallet"), QString::fromUtf8(kDonationReceiverWallet));
    config.insert(QString::fromUtf8("baseScanBaseUrl"), QString::fromUtf8(kDonationBaseScanBaseUrl));
    config.insert(QString::fromUtf8("uniswapBaseUrl"), QString::fromUtf8(kDonationUniswapBaseUrl));
    config.insert(QString::fromUtf8("receiverBaseScanUrl"),
                  QString::fromUtf8("%1/address/%2")
                      .arg(QString::fromUtf8(kDonationBaseScanBaseUrl), QString::fromUtf8(kDonationReceiverWallet)));
    config.insert(QString::fromUtf8("whitePaperUrl"), QString::fromUtf8(kDonationWhitePaperUrl));
    config.insert(QString::fromUtf8("tokenRepoUrl"), QString::fromUtf8(kDonationTokenRepoUrl));
    config.insert(QString::fromUtf8("recommendedToken"), QString::fromUtf8("GENY"));
    config.insert(QString::fromUtf8("noticeText"),
                  QString::fromUtf8("Donations are voluntary contributions to support GenyConnect development. They do not represent an investment, equity, ownership, revenue share, or a promise of financial return."));
    return config;
}

QVariantList VpnController::donationTokenOptions() const
{
    QVariantList rows;
    for (const auto& token : donationTokens()) {
        QVariantMap row;
        row.insert(QString::fromUtf8("symbol"), QString::fromUtf8(token.symbol));
        row.insert(QString::fromUtf8("displayName"), QString::fromUtf8(token.displayName));
        row.insert(QString::fromUtf8("contract"), QString::fromUtf8(token.contract));
        row.insert(QString::fromUtf8("decimals"), token.decimals);
        row.insert(QString::fromUtf8("recommended"), token.recommended);
        row.insert(QString::fromUtf8("message"), QString::fromUtf8(token.encouragement));
        QVariantList presets;
        for (const auto *preset : token.presetAmounts) {
            presets.append(QString::fromUtf8(preset));
        }
        row.insert(QString::fromUtf8("presetAmounts"), presets);
        row.insert(QString::fromUtf8("baseScanUrl"),
                   QString::fromUtf8("%1/token/%2")
                       .arg(QString::fromUtf8(kDonationBaseScanBaseUrl), QString::fromUtf8(token.contract)));
        row.insert(QString::fromUtf8("uniswapUrl"), donationUniswapUrl(token));
        rows.append(row);
    }
    return rows;
}

QVariantMap VpnController::buildDonationPayload(const QString& tokenSymbol, const QString& amountText) const
{
    QVariantMap payload;
    payload.insert(QString::fromUtf8("ok"), false);

    const DonationTokenDefinition *token = findDonationToken(tokenSymbol);
    if (!token) {
        payload.insert(QString::fromUtf8("error"), QString::fromUtf8("Unsupported donation token selected."));
        return payload;
    }

    QString baseUnits;
    QString parseError;
    if (!parseTokenAmountToBaseUnits(amountText, token->decimals, &baseUnits, &parseError)) {
        payload.insert(QString::fromUtf8("error"), parseError);
        return payload;
    }

    const QString tokenContract = QString::fromUtf8(token->contract);
    const QString receiverWallet = QString::fromUtf8(kDonationReceiverWallet);
    const QString deepLink = QString::fromUtf8("ethereum:%1@%2/transfer?address=%3&uint256=%4")
                                 .arg(tokenContract,
                                      QString::number(kDonationBaseChainId),
                                      receiverWallet,
                                      baseUnits);

    payload.insert(QString::fromUtf8("ok"), true);
    payload.insert(QString::fromUtf8("tokenSymbol"), QString::fromUtf8(token->symbol));
    payload.insert(QString::fromUtf8("tokenContract"), tokenContract);
    payload.insert(QString::fromUtf8("tokenDecimals"), token->decimals);
    payload.insert(QString::fromUtf8("networkName"), QString::fromUtf8(kDonationBaseChainName));
    payload.insert(QString::fromUtf8("chainId"), kDonationBaseChainId);
    payload.insert(QString::fromUtf8("receiverWallet"), receiverWallet);
    payload.insert(QString::fromUtf8("displayAmount"), amountText.trimmed());
    payload.insert(QString::fromUtf8("amountBaseUnits"), baseUnits);
    payload.insert(QString::fromUtf8("deepLink"), deepLink);
    payload.insert(QString::fromUtf8("receiverBaseScanUrl"),
                   QString::fromUtf8("%1/address/%2")
                       .arg(QString::fromUtf8(kDonationBaseScanBaseUrl), receiverWallet));
    payload.insert(QString::fromUtf8("tokenBaseScanUrl"),
                   QString::fromUtf8("%1/token/%2")
                       .arg(QString::fromUtf8(kDonationBaseScanBaseUrl), tokenContract));
    payload.insert(QString::fromUtf8("uniswapUrl"), donationUniswapUrl(*token));
    return payload;
}

void VpnController::onProcessStarted()
{
    if (m_shutdownInProgress.load() || m_disconnectRequested.load()) {
        m_stoppingProcess = true;
        if (m_runtimeBackend) {
            QString runtimeStopError;
            Q_UNUSED(m_runtimeBackend->disconnectRuntime(&runtimeStopError, 0));
        }
        return;
    }

    m_stoppingProcess = false;
    const quint64 connectAttempt = m_connectAttemptCounter.load();

    if (m_runtimeIsMobile) {
        setConnectionState(ConnectionState::Connecting);
        gateRuntimeStartupUntilProxyReady(connectAttempt);
        return;
    }

    completeRuntimeConnectedStartup();
}

void VpnController::completeRuntimeConnectedStartup()
{
    if (m_powerModeManager) {
        m_powerModeManager->recordReconnectSuccess();
    }
    resetPerProfileUsageSamples();
    writeManagedRuntimeRecord(m_runtimeBackend ? m_runtimeBackend->processId() : -1, QString::fromUtf8("proxy"));
    beginProfileUsageSession(m_activeProfileUsageId);
    setConnectionState(ConnectionState::Connected);
    if (m_effectiveTunMode) {
        appendSystemLog(QString::fromUtf8("[System] TUN mode active: system traffic should route through Xray TUN."));
    } else if (m_useSystemProxy || m_killSwitchEnabled) {
        applySystemProxy(true);
    } else {
        if (m_runtimeIsMobile) {
            appendSystemLog(QString::fromUtf8(
                                "[System] Proxy-only mode active: Android system traffic is not auto-routed; configure apps to use 127.0.0.1:%1.")
                                .arg(m_buildOptions.socksPort));
        } else {
            appendSystemLog(QString::fromUtf8(
                                "[System] Clean mode active: system proxy stays disabled (only apps configured to 127.0.0.1:%1 use the tunnel).")
                                .arg(m_buildOptions.socksPort));
        }
    }

    appendSystemLog(QString::fromUtf8("[System] Xray started. Local proxy (mixed): 127.0.0.1:%1.")
                        .arg(m_buildOptions.socksPort));

    m_statsPollTimer.start();
    pollTrafficStats();

    QTimer::singleShot(startupSelfCheckDelayMs(), this, [this]() {
        runProxySelfCheck();
    });
}

void VpnController::gateRuntimeStartupUntilProxyReady(quint64 connectAttempt)
{
    const quint16 socksPort = m_buildOptions.socksPort;
    const bool tunMode = m_effectiveTunMode;
    const QPointer<VpnController> guard(this);

    [[maybe_unused]] auto startupReadyFuture = QtConcurrent::run([guard, socksPort, connectAttempt, tunMode]() {
        QString lastCheckError;
        bool ready = false;
        QElapsedTimer readyTimer;
        readyTimer.start();
        while (readyTimer.elapsed() < 12000) {
            if (!guard) {
                return;
            }
            if (guard->m_shutdownInProgress.load()
                || guard->m_disconnectRequested.load()
                || guard->m_connectAttemptCounter.load() != connectAttempt) {
                return;
            }

            QString checkError;
            if (checkLocalProxyConnectivitySync(socksPort, &checkError)) {
                ready = true;
                break;
            }
            lastCheckError = checkError;
            QThread::msleep(180);
        }

        if (!guard) {
            return;
        }

        QMetaObject::invokeMethod(guard.data(), [guard, ready, lastCheckError, connectAttempt, tunMode, socksPort]() {
            if (!guard) {
                return;
            }
            if (guard->m_shutdownInProgress.load()
                || guard->m_disconnectRequested.load()
                || guard->m_connectAttemptCounter.load() != connectAttempt) {
                return;
            }

            if (ready) {
                guard->appendSystemLog(
                    QString::fromUtf8("[System] Local proxy became ready on 127.0.0.1:%1; marking connection as active.")
                        .arg(socksPort));
                guard->completeRuntimeConnectedStartup();
                return;
            }

            QString runtimeStopError;
            if (guard->m_runtimeBackend && guard->m_runtimeBackend->isRunning()) {
                Q_UNUSED(guard->m_runtimeBackend->disconnectRuntime(&runtimeStopError, 0));
            }
            const QString modeLabel = tunMode ? QString::fromUtf8("TUN") : QString::fromUtf8("proxy");
            QString detail = lastCheckError.trimmed();
            if (detail.isEmpty()) {
                detail = QString::fromUtf8("Local mixed proxy port is not reachable.");
            }
            guard->appendSystemLog(
                QString::fromUtf8("[System] Android %1 startup failed readiness check: %2")
                    .arg(modeLabel, detail));
            guard->setLastError(QString::fromUtf8("Connection started but local proxy was not ready. Please retry."));
            guard->setConnectionState(ConnectionState::Error);
        }, Qt::QueuedConnection);
    });
}

void VpnController::onProcessStopped(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitCode)
    m_statsPollTimer.stop();
    cancelSpeedTest();
    endProfileUsageSession(m_activeProfileUsageId);
    clearManagedRuntimeRecord();
    resetPerProfileUsageSamples();
    if (m_killSwitchEnabled) {
        applySystemProxy(true, true);
        appendSystemLog(QString::fromUtf8("[System] Kill Switch active: system proxy remains locked to GenyConnect."));
    } else if (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect) {
        applySystemProxy(false);
    }

    if (m_stoppingProcess) {
        m_stoppingProcess = false;
        m_disconnectRequested.store(false);
        setLastError(QString());
        setConnectionState(ConnectionState::Disconnected);
        maybeReconnectToPendingProfile();
        return;
    }

    if (exitStatus == QProcess::CrashExit) {
        if (m_powerModeManager) {
            m_powerModeManager->recordRuntimeInstability(QString::fromUtf8("runtime crash"));
        }
        setLastError(QString::fromUtf8("xray-core terminated unexpectedly."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_connectionState != ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }
    m_disconnectRequested.store(false);
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
    endProfileUsageSession(m_activeProfileUsageId);
    clearManagedRuntimeRecord();
    resetPerProfileUsageSamples();
    if (m_powerModeManager) {
        m_powerModeManager->recordRuntimeInstability(error);
    }
    appendSystemLog(QString::fromUtf8("[System] Runtime error: %1").arg(error.trimmed()));
    setLastError(QString::fromUtf8("xray-core error: %1").arg(error));
    setConnectionState(ConnectionState::Error);
}

void VpnController::scheduleLogsChanged()
{
    m_logsDirty = true;
    if (!m_logsFlushTimer.isActive()) {
        m_logsFlushTimer.start();
    }
}

void VpnController::applyPowerPolicy()
{
    if (!m_powerModeManager) {
        return;
    }

    const auto policy = m_powerModeManager->effectivePolicy();
    const bool memoryActive = m_memoryUsageTimer.isActive();
    const bool statsActive = m_statsPollTimer.isActive();
    const bool tunLogActive = m_privilegedTunLogTimer.isActive();
    const bool logsFlushActive = m_logsFlushTimer.isActive();
    const bool speedTestActive = m_speedTestTimer.isActive();
    const bool publicIpRetryActive = m_publicIpRetryTimer.isActive();

    m_memoryUsageTimer.setInterval(policy.memorySampleIntervalMs);
    m_statsPollTimer.setInterval(policy.statsPollIntervalMs);
    m_privilegedTunLogTimer.setInterval(policy.privilegedTunLogIntervalMs);
    m_logsFlushTimer.setInterval(policy.logsFlushIntervalMs);
    m_speedTestTimer.setInterval(policy.speedTestTickIntervalMs);
    m_publicIpRetryTimer.setInterval(policy.publicIpRetryDelayMs);

    if (memoryActive && !m_memoryUsageTimer.isActive()) {
        m_memoryUsageTimer.start();
    }
    if (statsActive && !m_statsPollTimer.isActive()) {
        m_statsPollTimer.start();
    }
    if (tunLogActive && !m_privilegedTunLogTimer.isActive()) {
        m_privilegedTunLogTimer.start();
    }
    if (logsFlushActive && !m_logsFlushTimer.isActive()) {
        m_logsFlushTimer.start();
    }
    if (speedTestActive && !m_speedTestTimer.isActive()) {
        m_speedTestTimer.start();
    }
    if (publicIpRetryActive && !m_publicIpRetryTimer.isActive()) {
        m_publicIpRetryTimer.start();
    }
}

int VpnController::startupSelfCheckDelayMs() const
{
    if (!m_powerModeManager) {
        return 700;
    }
    return m_powerModeManager->effectivePolicy().startupSelfCheckDelayMs;
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
    if (line.contains(QString::fromUtf8("[api-in -> api]"))) {
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

    const qint64 nextRx = m_runtimeBackend ? m_runtimeBackend->rxBytes() : 0;
    const qint64 nextTx = m_runtimeBackend ? m_runtimeBackend->txBytes() : 0;
    if (nextRx != m_rxBytes || nextTx != m_txBytes) {
        updatePerProfileUsageCounters(nextRx, nextTx);
        m_rxBytes = nextRx;
        m_txBytes = nextTx;
        emit trafficChanged();
    }
}

void VpnController::onProfileModelDataChanged()
{
    recomputeProfileStats();
    refreshProfileGroups();
}

void VpnController::pollTrafficStats()
{
    if (!connected() || m_statsPolling) {
        return;
    }

    if (m_runtimeIsMobile) {
        const qint64 nextRx = m_runtimeBackend ? m_runtimeBackend->rxBytes() : 0;
        const qint64 nextTx = m_runtimeBackend ? m_runtimeBackend->txBytes() : 0;
        if (nextRx != m_rxBytes || nextTx != m_txBytes) {
            updatePerProfileUsageCounters(nextRx, nextTx);
            m_rxBytes = nextRx;
            m_txBytes = nextTx;
            emit trafficChanged();
        }
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
                            QString::fromUtf8("[System] Traffic stats unavailable: %1").arg(error.trimmed()));
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

    updateSpeedTestSampling(false);

    const bool transferPhase =
        (m_speedTestPhase == QString::fromUtf8("Download") || m_speedTestPhase == QString::fromUtf8("Upload"));
    const bool uploadPhase = (m_speedTestPhase == QString::fromUtf8("Upload"));
    const qint64 elapsedMs = m_speedTestPhaseTimer.isValid() ? m_speedTestPhaseTimer.elapsed() : 0;
    const qint64 sinceProgressMs = qMax<qint64>(0, elapsedMs - m_speedTestLastProgressElapsedMs);
    const bool uploadPayloadSent =
        uploadPhase && m_speedTestExpectedBytes > 0 && m_speedTestBytesReceived >= m_speedTestExpectedBytes;

    if (transferPhase
        && m_speedTestPhaseTimer.isValid()
        && uploadPayloadSent
        && sinceProgressMs >= kSpeedTestUploadResponseIdleFinalizeMs) {
        updateSpeedTestSampling(true);
        const qint64 elapsedForMbps = qMax<qint64>(
            1,
            m_speedTestMeasuredDurationMs > 0
                ? m_speedTestMeasuredDurationMs
                : (m_speedTestPhaseTimer.isValid()
                       ? m_speedTestPhaseTimer.elapsed()
                       : m_speedTestRequestTimer.elapsed()));
        const qint64 bytesForMbps = m_speedTestMeasuredBytes > 0 ? m_speedTestMeasuredBytes : m_speedTestBytesReceived;
        const double averageMbps = mbpsFromBytes(bytesForMbps, elapsedForMbps);
        m_speedTestUploadMbps = qMax(0.0, qMax(averageMbps, m_speedTestAverageMbps));
        m_speedTestProgress = 1.0;
        appendSystemLog(QString::fromUtf8("[SpeedTest] Upload response idle timeout reached; finalizing upload with transmitted data."));
        startAnalyzePhase();
        finishSpeedTest(true);
        return;
    }

    if (transferPhase
        && m_speedTestPhaseTimer.isValid()
        && elapsedMs >= kSpeedTestNoProgressTimeoutMs
        && sinceProgressMs >= kSpeedTestNoProgressTimeoutMs) {
        const QList<QUrl> endpoints = uploadPhase
                                          ? speedTestUploadFallbackUrls(m_speedTestSelectedSizeMb)
                                          : speedTestDownloadFallbackUrls(m_speedTestSelectedSizeMb);
        if (m_speedTestAttempt < endpoints.size()) {
            appendSystemLog(QString::fromUtf8("[SpeedTest] No transfer progress on current %1 endpoint. Trying fallback %2/%3.")
                                .arg(uploadPhase ? QString::fromUtf8("upload") : QString::fromUtf8("download"))
                                .arg(m_speedTestAttempt + 1)
                                .arg(endpoints.size()));
            startCurrentSpeedTestRequest();
            return;
        }
        if (!uploadPhase && !m_effectiveTunMode && !m_speedTestUsingDirectFallback) {
            m_speedTestUsingDirectFallback = true;
            m_speedTestAttempt = 0;
            m_speedTestNetworkManager.setProxy(QNetworkProxy::NoProxy);
            appendSystemLog(QString::fromUtf8("[SpeedTest] No transfer progress through VPN-proxy path, retrying with direct fallback."));
            startCurrentSpeedTestRequest();
            return;
        }

        // If we already sampled a usable amount, gracefully continue instead of hard failing.
        if (m_speedTestMeasuredBytes > 0 || m_speedTestBytesReceived > 0) {
            updateSpeedTestSampling(true);
            const qint64 elapsedForMbps = qMax<qint64>(
                1,
                m_speedTestMeasuredDurationMs > 0
                    ? m_speedTestMeasuredDurationMs
                    : (m_speedTestPhaseTimer.isValid()
                           ? m_speedTestPhaseTimer.elapsed()
                           : m_speedTestRequestTimer.elapsed()));
            const qint64 bytesForMbps = m_speedTestMeasuredBytes > 0 ? m_speedTestMeasuredBytes : m_speedTestBytesReceived;
            const double finalMbps = qMax(mbpsFromBytes(bytesForMbps, elapsedForMbps), m_speedTestAverageMbps);
            if (uploadPhase) {
                m_speedTestUploadMbps = qMax(0.0, finalMbps);
                m_speedTestProgress = 1.0;
                appendSystemLog(QString::fromUtf8("[SpeedTest] Upload finalized from sampled bytes after idle timeout."));
                startAnalyzePhase();
                finishSpeedTest(true);
                return;
            }
            m_speedTestDownloadMbps = qMax(0.0, finalMbps);
            m_speedTestProgress = 1.0;
            appendSystemLog(QString::fromUtf8("[SpeedTest] Download finalized from sampled bytes after idle timeout."));
            startUploadPhase();
            return;
        }

        finishSpeedTest(false, QString::fromUtf8("Speed test stalled waiting for transfer progress."));
        return;
    }
    emit speedTestChanged();
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
    if (chunk.isEmpty()) {
        return;
    }

    // Some Android/Qt network paths can emit readyRead() without reliable downloadProgress()
    // updates, especially when proxying or under certain HTTP stack behavior. Count readyRead
    // bytes as transfer progress to avoid false "stalled waiting for transfer progress" failures.
    if (!m_speedTestUploadMode) {
        qint64 readyBytes = reply->property("gc_ready_bytes").toLongLong();
        readyBytes += static_cast<qint64>(chunk.size());
        reply->setProperty("gc_ready_bytes", static_cast<qlonglong>(readyBytes));

        if (readyBytes > m_speedTestBytesReceived) {
            if (m_speedTestPingMs < 0 && m_speedTestRequestTimer.isValid()) {
                const qint64 elapsedMs = qMax<qint64>(1, m_speedTestRequestTimer.elapsed());
                m_speedTestPingMs = static_cast<int>(qMin<qint64>(elapsedMs, 60000));
            }
            m_speedTestBytesReceived = readyBytes;
            m_speedTestPhaseBytes = readyBytes;
            if (m_speedTestPhaseTimer.isValid()) {
                m_speedTestLastProgressElapsedMs = m_speedTestPhaseTimer.elapsed();
            }
            if (m_speedTestExpectedBytes > 0) {
                m_speedTestProgress = qBound(
                    0.0,
                    static_cast<double>(m_speedTestBytesReceived) / static_cast<double>(m_speedTestExpectedBytes),
                    1.0);
            }
            emit speedTestChanged();
        }
    }
}

void VpnController::onSpeedTestDownloadProgress(qint64 received, qint64 total)
{
    if (!m_speedTestRunning) {
        return;
    }
    if (m_speedTestUploadMode) {
        return;
    }

    if (received > m_speedTestBytesReceived) {
        if (m_speedTestPingMs < 0 && m_speedTestRequestTimer.isValid()) {
            const qint64 elapsedMs = qMax<qint64>(1, m_speedTestRequestTimer.elapsed());
            m_speedTestPingMs = static_cast<int>(qMin<qint64>(elapsedMs, 60000));
        }
        m_speedTestBytesReceived = received;
        m_speedTestPhaseBytes = received;
        if (m_speedTestPhaseTimer.isValid()) {
            m_speedTestLastProgressElapsedMs = m_speedTestPhaseTimer.elapsed();
        }
    }

    const qint64 expected = m_speedTestExpectedBytes > 0
                                ? m_speedTestExpectedBytes
                                : (total > 0 ? total : 0);
    if (expected > 0) {
        m_speedTestProgress = qBound(
            0.0,
            static_cast<double>(m_speedTestBytesReceived) / static_cast<double>(expected),
            1.0);
    }
    emit speedTestChanged();
}

void VpnController::onSpeedTestUploadProgress(qint64 sent, qint64 total)
{
    Q_UNUSED(total)
    if (!m_speedTestRunning || !m_speedTestUploadMode) {
        return;
    }
    if (sent > m_speedTestBytesReceived) {
        const qint64 delta = sent - m_speedTestBytesReceived;
        m_speedTestBytesReceived = sent;
        m_speedTestPhaseBytes += delta;
        if (m_speedTestPhaseTimer.isValid()) {
            m_speedTestLastProgressElapsedMs = m_speedTestPhaseTimer.elapsed();
        }
        if (m_speedTestExpectedBytes > 0) {
            m_speedTestProgress = qBound(
                0.0,
                static_cast<double>(m_speedTestBytesReceived) / static_cast<double>(m_speedTestExpectedBytes),
                1.0);
        }
    }
    emit speedTestChanged();
}

void VpnController::onSpeedTestFinished()
{
    if (m_speedTestReply == nullptr) {
        return;
    }

    const QString phaseAtFinish = m_speedTestPhase;
    const QString errorText = m_speedTestReply->errorString();
    const QNetworkReply::NetworkError replyErrorCode = m_speedTestReply->error();
    const bool replyHadError = (replyErrorCode != QNetworkReply::NoError);
    m_speedTestReply->deleteLater();
    m_speedTestReply = nullptr;

    if (!m_speedTestRunning) {
        return;
    }

    if (replyHadError && !m_speedTestCancelledByUser) {
        const bool uploadPhase = (phaseAtFinish == QString::fromUtf8("Upload"));
        const bool operationCanceled = (replyErrorCode == QNetworkReply::OperationCanceledError);
        const bool uploadPayloadSent =
            uploadPhase && m_speedTestExpectedBytes > 0 && m_speedTestBytesReceived >= m_speedTestExpectedBytes;
        const bool downloadMostlyComplete =
            !uploadPhase
            && m_speedTestExpectedBytes > 0
            && static_cast<double>(m_speedTestBytesReceived) >= (static_cast<double>(m_speedTestExpectedBytes) * kSpeedTestDownloadCompletionRatio);
        if (operationCanceled && (uploadPayloadSent || downloadMostlyComplete)) {
            updateSpeedTestSampling(true);
            const qint64 elapsedMs = qMax<qint64>(
                1,
                m_speedTestMeasuredDurationMs > 0
                    ? m_speedTestMeasuredDurationMs
                    : (m_speedTestPhaseTimer.isValid()
                           ? m_speedTestPhaseTimer.elapsed()
                           : m_speedTestRequestTimer.elapsed()));
            const double averageMbps = mbpsFromBytes(
                m_speedTestMeasuredBytes > 0 ? m_speedTestMeasuredBytes : m_speedTestBytesReceived,
                elapsedMs);
            const double finalMbps = qMax(averageMbps, m_speedTestAverageMbps);

            if (uploadPhase) {
                m_speedTestUploadMbps = qMax(0.0, finalMbps);
                m_speedTestProgress = 1.0;
                appendSystemLog(QString::fromUtf8("[SpeedTest] Upload finalized after request cancellation with full payload sent."));
                startAnalyzePhase();
                finishSpeedTest(true);
                return;
            }

            m_speedTestDownloadMbps = qMax(0.0, finalMbps);
            m_speedTestProgress = 1.0;
            if (m_speedTestPingMs < 0) {
                m_speedTestPingMs = static_cast<int>(qMin<qint64>(elapsedMs, 60000));
            }
            appendSystemLog(QString::fromUtf8("[SpeedTest] Download accepted after cancellation with sufficient sampled bytes."));
            startUploadPhase();
            return;
        }

        const QList<QUrl> endpoints = uploadPhase
                                          ? speedTestUploadFallbackUrls(m_speedTestSelectedSizeMb)
                                          : speedTestDownloadFallbackUrls(m_speedTestSelectedSizeMb);
        if (m_speedTestAttempt < endpoints.size()) {
            appendSystemLog(QString::fromUtf8("[SpeedTest] %1 endpoint failed (%2). Trying fallback %3/%4.")
                                .arg(uploadPhase ? QString::fromUtf8("Upload") : QString::fromUtf8("Download"))
                                .arg(errorText.trimmed().isEmpty() ? QString::fromUtf8("network error") : errorText.trimmed())
                                .arg(m_speedTestAttempt + 1)
                                .arg(endpoints.size()));
            startCurrentSpeedTestRequest();
            return;
        }
        if (!uploadPhase && !m_effectiveTunMode && !m_speedTestUsingDirectFallback) {
            m_speedTestUsingDirectFallback = true;
            m_speedTestAttempt = 0;
            m_speedTestNetworkManager.setProxy(QNetworkProxy::NoProxy);
            appendSystemLog(QString::fromUtf8("[SpeedTest] VPN-proxy path failed, retrying with direct fallback."));
            startCurrentSpeedTestRequest();
            return;
        }
        if (uploadPhase) {
            m_speedTestUploadMbps = 0.0;
            appendSystemLog(QString::fromUtf8("[SpeedTest] Upload phase failed across endpoints; keeping download diagnostics."));
            startAnalyzePhase();
            finishSpeedTest(true);
            return;
        }
        if (operationCanceled) {
            finishSpeedTest(false, QString::fromUtf8("Speed test request timed out or was interrupted."));
        } else {
            finishSpeedTest(false, errorText);
        }
        return;
    }

    if (phaseAtFinish != QString::fromUtf8("Download") && phaseAtFinish != QString::fromUtf8("Upload")) {
        finishSpeedTest(false, QString::fromUtf8("Speed test finished in invalid state."));
        return;
    }

    updateSpeedTestSampling(true);
    const qint64 elapsedMs = qMax<qint64>(
        1,
        m_speedTestMeasuredDurationMs > 0
            ? m_speedTestMeasuredDurationMs
            : (m_speedTestPhaseTimer.isValid()
                   ? m_speedTestPhaseTimer.elapsed()
                   : m_speedTestRequestTimer.elapsed()));
    if (m_speedTestBytesReceived <= 0) {
        finishSpeedTest(false, QString::fromUtf8("Speed test returned no transferable data."));
        return;
    }
    const double averageMbps = mbpsFromBytes(m_speedTestMeasuredBytes > 0 ? m_speedTestMeasuredBytes : m_speedTestBytesReceived, elapsedMs);
    const double finalMbps = qMax(averageMbps, m_speedTestAverageMbps);

    if (phaseAtFinish == QString::fromUtf8("Download")) {
        m_speedTestDownloadMbps = qMax(0.0, finalMbps);
        m_speedTestProgress = 1.0;
        if (m_speedTestPingMs < 0) {
            m_speedTestPingMs = static_cast<int>(qMin<qint64>(elapsedMs, 60000));
        }
        startUploadPhase();
        return;
    }

    m_speedTestUploadMbps = qMax(0.0, finalMbps);
    m_speedTestProgress = 1.0;
    startAnalyzePhase();
    finishSpeedTest(true);
}

void VpnController::updateSpeedTestSampling(bool finalizeWindow)
{
    if (!m_speedTestRunning || !m_speedTestPhaseTimer.isValid()) {
        return;
    }
    const bool transferPhase =
        (m_speedTestPhase == QString::fromUtf8("Download") || m_speedTestPhase == QString::fromUtf8("Upload"));
    if (!transferPhase) {
        return;
    }

    const qint64 elapsedMs = qMax<qint64>(1, m_speedTestPhaseTimer.elapsed());
    if (m_speedTestSampleWindowStartMs < 0) {
        m_speedTestSampleWindowStartMs = elapsedMs;
        m_speedTestSampleWindowStartBytes = m_speedTestBytesReceived;
        return;
    }

    const qint64 windowMs = elapsedMs - m_speedTestSampleWindowStartMs;
    if (!finalizeWindow && windowMs < kSpeedTestSamplingWindowMs) {
        return;
    }
    if (windowMs <= 0) {
        return;
    }

    const qint64 windowBytes = qMax<qint64>(0, m_speedTestBytesReceived - m_speedTestSampleWindowStartBytes);
    const double instantMbps = mbpsFromBytes(windowBytes, windowMs);
    const double alpha = 0.24;
    if (m_speedTestCurrentMbps <= 0.01) {
        m_speedTestCurrentMbps = instantMbps;
    } else {
        m_speedTestCurrentMbps = (m_speedTestCurrentMbps * (1.0 - alpha)) + (instantMbps * alpha);
    }
    if (m_speedTestCurrentMbps > m_speedTestPeakMbps) {
        m_speedTestPeakMbps = m_speedTestCurrentMbps;
    }

    const qint64 warmupAnchor = qMax<qint64>(0, m_speedTestWarmupUntilMs);
    qint64 effectiveBytes = windowBytes;
    qint64 effectiveMs = windowMs;
    if (elapsedMs <= warmupAnchor) {
        effectiveBytes = 0;
        effectiveMs = 0;
    } else if (m_speedTestSampleWindowStartMs < warmupAnchor) {
        const qint64 afterWarmupMs = elapsedMs - warmupAnchor;
        if (afterWarmupMs <= 0 || windowMs <= 0) {
            effectiveBytes = 0;
            effectiveMs = 0;
        } else {
            const double ratio = qBound(0.0, static_cast<double>(afterWarmupMs) / static_cast<double>(windowMs), 1.0);
            effectiveBytes = static_cast<qint64>(std::llround(static_cast<double>(windowBytes) * ratio));
            effectiveMs = afterWarmupMs;
        }
    }
    if (effectiveMs > 0 && effectiveBytes > 0) {
        m_speedTestMeasuredBytes += effectiveBytes;
        m_speedTestMeasuredDurationMs += qMax<qint64>(1, effectiveMs);
        if (m_speedTestMeasuredDurationMs > 0 && m_speedTestMeasuredBytes > 0) {
            m_speedTestAverageMbps = mbpsFromBytes(m_speedTestMeasuredBytes, m_speedTestMeasuredDurationMs);
        }
    }

    if (m_speedTestExpectedBytes > 0) {
        m_speedTestProgress = qBound(
            0.0,
            static_cast<double>(m_speedTestBytesReceived) / static_cast<double>(m_speedTestExpectedBytes),
            1.0);
    }

    m_speedTestSampleWindowStartMs = elapsedMs;
    m_speedTestSampleWindowStartBytes = m_speedTestBytesReceived;
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

    const bool success = ok && !parsed.isNull();
    if (success) {
        m_publicIpAddress = ipText;
        m_publicIpRetryCount = 0;
    } else {
        ++m_publicIpRetryCount;
        if (connected() && m_publicIpRetryCount <= m_publicIpRetryLimit) {
            const int retryDelayMs = m_powerModeManager
                ? m_powerModeManager->effectivePolicy().publicIpRetryDelayMs
                : kPublicIpRetryDelayMs;
            m_publicIpRetryTimer.start(retryDelayMs * m_publicIpRetryCount);
        } else {
            appendSystemLog(QString::fromUtf8("[System] VPN IP lookup unavailable: %1").arg(reply->errorString().trimmed()));
        }
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
    if (state == ConnectionState::Connected) {
        m_disconnectRequested.store(false);
        m_publicIpRetryCount = 0;
        QTimer::singleShot(900, this, [this]() {
            refreshPublicIp();
        });
        return;
    }

    m_publicIpRetryTimer.stop();
    if (m_publicIpReply) {
        QObject::disconnect(m_publicIpReply, nullptr, this, nullptr);
        m_publicIpReply->abort();
        m_publicIpReply->deleteLater();
        m_publicIpReply = nullptr;
    }
    if (m_publicIpRefreshing) {
        m_publicIpRefreshing = false;
        emit publicIpAddressChanged();
    }
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
    m_speedTestState = QString::fromUtf8("Idle");
    m_speedTestPhase = QString::fromUtf8("Idle");
    m_speedTestElapsedSec = 0;
    m_speedTestDurationSec = 0;
    m_speedTestProgress = 0.0;
    m_speedTestPingMs = -1;
    m_speedTestJitterMs = -1;
    m_speedTestPacketLossPct = 0.0;
    m_speedTestRouteStabilityPct = 0;
    m_speedTestQualityScore = -1;
    m_speedTestLatencyMinMs = -1;
    m_speedTestLatencyMaxMs = -1;
    m_speedTestDownloadMbps = 0.0;
    m_speedTestUploadMbps = 0.0;
    m_speedTestError.clear();
    m_speedTestCurrentMbps = 0.0;
    m_speedTestPeakMbps = 0.0;
    m_speedTestAverageMbps = 0.0;
    m_speedTestBytesReceived = 0;
    m_speedTestLastBytes = 0;
    m_speedTestAttempt = 0;
    m_speedTestPingSampleCount = 0;
    m_speedTestPingTotalMs = 0;
    m_speedTestLatencyAttemptCount = 0;
    m_speedTestLatencySuccessCount = 0;
    m_speedTestLatencySamples.clear();
    m_speedTestUploadMode = false;
    m_speedTestPhaseBytes = 0;
    m_speedTestExpectedBytes = 0;
    m_speedTestSampleWindowStartMs = -1;
    m_speedTestSampleWindowStartBytes = 0;
    m_speedTestMeasuredBytes = 0;
    m_speedTestMeasuredDurationMs = 0;
    m_speedTestLastProgressElapsedMs = 0;
    m_speedTestWarmupUntilMs = 0;
    m_speedTestCancelledByUser = false;
    m_speedTestUsingDirectFallback = false;
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
    const bool tunMode = m_effectiveTunMode;
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
                guard->appendSystemLog(QString::fromUtf8("[System] Proxy self-test passed (127.0.0.1:%1 is forwarding traffic).")
                                           .arg(socksPort));
                if (!useSystemProxyMode && !tunMode) {
                    if (guard->m_runtimeIsMobile) {
                        guard->appendSystemLog(QString::fromUtf8(
                            "[System] Proxy-only note: Android system traffic is NOT auto-routed in this mode."));
                    } else {
                        guard->appendSystemLog(QString::fromUtf8(
                            "[System] Clean mode note: system traffic is NOT auto-routed in this mode."));
                    }
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

            guard->appendSystemLog(QString::fromUtf8("[System] Proxy self-test failed: %1").arg(error));
            if (useSystemProxyMode) {
                guard->appendSystemLog(QString::fromUtf8("[System] Hint: verify system proxy state and retry with proper permissions."));
            } else {
                guard->appendSystemLog(QString::fromUtf8("[System] Hint: Clean mode requires apps to use 127.0.0.1:%1 manually.")
                                           .arg(socksPort));
            }

            if (guard->m_runtimeIsMobile) {
                guard->setLastError(QString::fromUtf8("Local proxy port is not reachable."));
                guard->setConnectionState(ConnectionState::Error);
                if (guard->m_runtimeBackend && guard->m_runtimeBackend->isRunning()) {
                    QString runtimeStopError;
                    Q_UNUSED(guard->m_runtimeBackend->disconnectRuntime(&runtimeStopError, 0));
                }
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
    m_xrayVersion = QString::fromUtf8("Unknown");

    if (!m_runtimeIsDesktop || !m_runtimeSupportsPerAppRouting) {
        m_xrayVersion = QString::fromUtf8("Managed by mobile runtime");
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return false;
    }

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        m_xrayVersion = QString::fromUtf8("Not detected");
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return m_processRoutingSupported;
    }

    QProcess process;
    process.start(m_xrayExecutablePath, {QString::fromUtf8("version")});
    if (!process.waitForStarted(2000)) {
        m_xrayVersion = QString::fromUtf8("Unavailable");
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
        m_xrayVersion = QString::fromUtf8("Unavailable");
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

    const QRegularExpression regex(QString::fromUtf8("Xray\\s+(\\d+)\\.(\\d+)\\.(\\d+)"));
    const QRegularExpressionMatch match = regex.match(output);
    if (match.hasMatch()) {
        m_xrayVersion = QString::fromUtf8("%1.%2.%3")
        .arg(match.captured(1), match.captured(2), match.captured(3));
        const int major = match.captured(1).toInt();
        const int minor = match.captured(2).toInt();
        const int patch = match.captured(3).toInt();

        const bool versionSupported =
            major > 26
            || (major == 26 && minor > 1)
            || (major == 26 && minor == 1 && patch >= 23);

#if defined(Q_OS_WIN) || defined(Q_OS_LINUX)
        m_processRoutingSupported = versionSupported;
#else
        // Xray process-name routing currently supports Windows/Linux only.
        m_processRoutingSupported = false;
#endif
    } else if (process.exitCode() == 0) {
        m_xrayVersion = QString::fromUtf8("Detected");
    } else {
        m_xrayVersion = QString::fromUtf8("Unavailable");
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
    const QStringList raw = normalized.split(QRegularExpression(QString::fromUtf8("[,;\\n\\r]+")), Qt::SkipEmptyParts);

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

    if (candidate.contains(QString::fromUtf8("://"))) {
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
        value.split(QRegularExpression(QString::fromUtf8("[,;\\n\\r\\t ]+")), Qt::SkipEmptyParts);

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

void VpnController::syncSystemBars(bool darkThemeEnabled)
{
#if defined(Q_OS_ANDROID)
    if (!QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        return;
    }
    QJniObject::callStaticMethod<void>(
        kAndroidRuntimeBridgeClass,
        "syncSystemBars",
        "(Z)V",
        static_cast<jboolean>(darkThemeEnabled));
#else
    Q_UNUSED(darkThemeEnabled);
#endif
}

QString VpnController::currentProfileTransportPowerClass() const
{
    const auto profile = m_profileModel ? m_profileModel->profileAt(m_currentProfileIndex) : std::nullopt;
    if (!profile.has_value()) {
        return QString::fromUtf8("Balanced");
    }
    return classifyTransportPower(profile->network, profile->security, profile->alpn);
}

QString VpnController::classifyTransportPower(const QString& network, const QString& security, const QString& alpn) const
{
    return m_powerModeManager
        ? m_powerModeManager->classifyTransport(network, security, alpn)
        : QString::fromUtf8("Balanced");
}

QString VpnController::transportPowerDescription(const QString& powerClass) const
{
    return m_powerModeManager
        ? m_powerModeManager->transportPowerDescription(powerClass)
        : QString();
}

void VpnController::updatePowerAdaptiveState(
    bool screenOn,
    bool charging,
    bool batterySaver,
    int batteryLevel,
    const QString& networkType)
{
    if (!m_powerModeManager) {
        return;
    }
    m_powerModeManager->setAdaptiveState(screenOn, charging, batterySaver, batteryLevel, networkType);
}

void VpnController::maybeReconnectToPendingProfile()
{
    if (m_pendingReconnectProfileIndex < 0) {
        return;
    }
    if (busy() || (m_runtimeBackend && m_runtimeBackend->isRunning()) || m_privilegedTunManaged) {
        return;
    }

    const int reconnectIndex = m_pendingReconnectProfileIndex;
    m_pendingReconnectProfileIndex = -1;
    if (reconnectIndex < 0 || reconnectIndex >= m_profileModel->rowCount()) {
        return;
    }

    int reconnectDelayMs = 0;
    if (m_powerModeManager && m_powerModeManager->mode() != PowerModeManager::Mode::Normal) {
        m_powerModeManager->recordReconnectAttempt();
        reconnectDelayMs = m_powerModeManager->nextReconnectDelayMs();
        appendSystemLog(QString::fromUtf8("[PowerMode] Reconnect backoff scheduled in %1 ms.").arg(reconnectDelayMs));
    }

    QTimer::singleShot(reconnectDelayMs, this, [this, reconnectIndex]() {
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
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
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

    if (!m_usageSessionProfileId.trimmed().isEmpty()
        && id.compare(m_usageSessionProfileId, Qt::CaseInsensitive) == 0) {
        m_usageSessionRxBytes += safeRx;
        m_usageSessionTxBytes += safeTx;
    }

    QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    QJsonObject usage = profiles.value(id).toObject();

    const qint64 prevTotalRx = usage.value(QString::fromUtf8("totalRx")).toVariant().toLongLong();
    const qint64 prevTotalTx = usage.value(QString::fromUtf8("totalTx")).toVariant().toLongLong();
    usage.insert(QString::fromUtf8("totalRx"), prevTotalRx + safeRx);
    usage.insert(QString::fromUtf8("totalTx"), prevTotalTx + safeTx);
    usage.insert(QString::fromUtf8("latestSnapshotRx"), safeRx);
    usage.insert(QString::fromUtf8("latestSnapshotTx"), safeTx);
    usage.insert(QString::fromUtf8("latestSnapshotTotal"), safeRx + safeTx);

    const QDateTime now = QDateTime::currentDateTimeUtc();
    addUsageToBucket(&usage, QString::fromUtf8("hour"), usageHourBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, QString::fromUtf8("day"), usageDayBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, QString::fromUtf8("week"), usageWeekBucketKey(now), safeRx, safeTx);
    addUsageToBucket(&usage, QString::fromUtf8("month"), usageMonthBucketKey(now), safeRx, safeTx);
    usage.insert(QString::fromUtf8("updatedAt"), now.toMSecsSinceEpoch());

    auto trimBuckets = [&usage](const QString& bucketName, int keepCount) {
        QJsonObject buckets = usage.value(bucketName).toObject();
        QStringList keys = buckets.keys();
        std::sort(keys.begin(), keys.end(), std::greater<QString>());
        for (int i = keepCount; i < keys.size(); ++i) {
            buckets.remove(keys.at(i));
        }
        usage.insert(bucketName, buckets);
    };
    trimBuckets(QString::fromUtf8("hour"), 24 * 31);
    trimBuckets(QString::fromUtf8("day"), 366);
    trimBuckets(QString::fromUtf8("week"), 104);
    trimBuckets(QString::fromUtf8("month"), 60);

    profiles.insert(id, usage);
    m_profileUsageRoot.insert(QString::fromUtf8("profiles"), profiles);
    scheduleProfileUsageSave();
    if (id.compare(m_currentProfileId.trimmed(), Qt::CaseInsensitive) == 0) {
        emit profileUsageChanged();
    }
}

void VpnController::beginProfileUsageSession(const QString& profileId)
{
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return;
    }

    if (!m_usageSessionProfileId.trimmed().isEmpty()
        && m_usageSessionProfileId.compare(id, Qt::CaseInsensitive) == 0) {
        return;
    }
    if (!m_usageSessionProfileId.trimmed().isEmpty()) {
        endProfileUsageSession(m_usageSessionProfileId);
    }

    m_usageSessionProfileId = id;
    m_usageSessionStartedAt = QDateTime::currentDateTimeUtc();
    m_usageSessionRxBytes = 0;
    m_usageSessionTxBytes = 0;
}

void VpnController::endProfileUsageSession(const QString& profileId)
{
    const QString activeId = m_usageSessionProfileId.trimmed();
    const QString requestedId = profileId.trimmed();
    if (activeId.isEmpty()) {
        return;
    }
    if (!requestedId.isEmpty() && activeId.compare(requestedId, Qt::CaseInsensitive) != 0) {
        return;
    }

    const qint64 safeRx = qMax<qint64>(0, m_usageSessionRxBytes);
    const qint64 safeTx = qMax<qint64>(0, m_usageSessionTxBytes);
    const qint64 total = safeRx + safeTx;
    const QDateTime started = m_usageSessionStartedAt.isValid()
                                  ? m_usageSessionStartedAt
                                  : QDateTime::currentDateTimeUtc();
    const QDateTime ended = QDateTime::currentDateTimeUtc();

    QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    QJsonObject usage = profiles.value(activeId).toObject();

    QJsonObject session;
    session.insert(QString::fromUtf8("startedAt"), started.toMSecsSinceEpoch());
    session.insert(QString::fromUtf8("endedAt"), ended.toMSecsSinceEpoch());
    session.insert(QString::fromUtf8("rx"), safeRx);
    session.insert(QString::fromUtf8("tx"), safeTx);
    session.insert(QString::fromUtf8("total"), total);
    usage.insert(QString::fromUtf8("latestSession"), session);
    usage.insert(QString::fromUtf8("updatedAt"), ended.toMSecsSinceEpoch());

    QJsonArray sessions = usage.value(QString::fromUtf8("sessions")).toArray();
    sessions.prepend(session);
    while (sessions.size() > 120) {
        sessions.removeLast();
    }
    usage.insert(QString::fromUtf8("sessions"), sessions);
    profiles.insert(activeId, usage);
    m_profileUsageRoot.insert(QString::fromUtf8("profiles"), profiles);
    scheduleProfileUsageSave();
    if (activeId.compare(m_currentProfileId.trimmed(), Qt::CaseInsensitive) == 0) {
        emit profileUsageChanged();
    }

    m_usageSessionProfileId.clear();
    m_usageSessionRxBytes = 0;
    m_usageSessionTxBytes = 0;
    m_usageSessionStartedAt = QDateTime();
}

QVariantMap VpnController::profileUsageSummaryForId(const QString& profileId) const
{
    QVariantMap out;
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return out;
    }

    const QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    if (usage.isEmpty()) {
        return out;
    }

    auto bucketValues = [&usage](const QString& period, const QString& key) -> QPair<qint64, qint64> {
        const QJsonObject buckets = usage.value(period).toObject();
        const QJsonObject entry = buckets.value(key).toObject();
        return {entry.value(QString::fromUtf8("rx")).toVariant().toLongLong(),
                entry.value(QString::fromUtf8("tx")).toVariant().toLongLong()};
    };

    const QDateTime now = QDateTime::currentDateTimeUtc();
    const auto hour = bucketValues(QString::fromUtf8("hour"), usageHourBucketKey(now));
    const auto day = bucketValues(QString::fromUtf8("day"), usageDayBucketKey(now));
    const auto week = bucketValues(QString::fromUtf8("week"), usageWeekBucketKey(now));
    const auto month = bucketValues(QString::fromUtf8("month"), usageMonthBucketKey(now));

    const qint64 totalRx = usage.value(QString::fromUtf8("totalRx")).toVariant().toLongLong();
    const qint64 totalTx = usage.value(QString::fromUtf8("totalTx")).toVariant().toLongLong();

    auto insertPeriod = [&out, this](const QString& name, qint64 rx, qint64 tx) {
        out.insert(name + QString::fromUtf8("RxBytes"), rx);
        out.insert(name + QString::fromUtf8("TxBytes"), tx);
        out.insert(name + QString::fromUtf8("TotalBytes"), rx + tx);
        out.insert(name + QString::fromUtf8("Text"), formatBytes(rx + tx));
    };

    insertPeriod(QString::fromUtf8("hour"), hour.first, hour.second);
    insertPeriod(QString::fromUtf8("day"), day.first, day.second);
    insertPeriod(QString::fromUtf8("week"), week.first, week.second);
    insertPeriod(QString::fromUtf8("month"), month.first, month.second);
    out.insert(QString::fromUtf8("totalRxBytes"), totalRx);
    out.insert(QString::fromUtf8("totalTxBytes"), totalTx);
    out.insert(QString::fromUtf8("totalBytes"), totalRx + totalTx);
    out.insert(QString::fromUtf8("totalText"), formatBytes(totalRx + totalTx));
    out.insert(QString::fromUtf8("updatedAt"),
               usage.value(QString::fromUtf8("updatedAt")).toVariant().toLongLong());
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
    if (p == QString::fromUtf8("hour")
        || p == QString::fromUtf8("day")
        || p == QString::fromUtf8("week")
        || p == QString::fromUtf8("month")) {
        bucket = p;
    } else {
        bucket = QString::fromUtf8("day");
    }

    const QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
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
        const qint64 rx = entry.value(QString::fromUtf8("rx")).toVariant().toLongLong();
        const qint64 tx = entry.value(QString::fromUtf8("tx")).toVariant().toLongLong();
        QVariantMap row;
        row.insert(QString::fromUtf8("bucket"), bucket);
        row.insert(QString::fromUtf8("key"), key);
        row.insert(QString::fromUtf8("rxBytes"), rx);
        row.insert(QString::fromUtf8("txBytes"), tx);
        row.insert(QString::fromUtf8("totalBytes"), rx + tx);
        row.insert(QString::fromUtf8("rxText"), formatBytes(rx));
        row.insert(QString::fromUtf8("txText"), formatBytes(tx));
        row.insert(QString::fromUtf8("totalText"), formatBytes(rx + tx));
        out.append(row);
    }
    return out;
}

QVariantList VpnController::profileUsageSessionsForId(const QString& profileId, int limit) const
{
    QVariantList out;
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return out;
    }

    const QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    const QJsonArray sessions = usage.value(QString::fromUtf8("sessions")).toArray();
    if (sessions.isEmpty()) {
        return out;
    }

    const int safeLimit = qBound(1, limit, 500);
    const int count = qMin(safeLimit, sessions.size());
    out.reserve(count);
    for (int i = 0; i < count; ++i) {
        const QJsonObject rowObj = sessions.at(i).toObject();
        const qint64 startedAt = rowObj.value(QString::fromUtf8("startedAt")).toVariant().toLongLong();
        const qint64 endedAt = rowObj.value(QString::fromUtf8("endedAt")).toVariant().toLongLong();
        const qint64 rx = rowObj.value(QString::fromUtf8("rx")).toVariant().toLongLong();
        const qint64 tx = rowObj.value(QString::fromUtf8("tx")).toVariant().toLongLong();
        const qint64 total = rowObj.value(QString::fromUtf8("total")).toVariant().toLongLong();

        QVariantMap row;
        row.insert(QString::fromUtf8("startedAtMs"), startedAt);
        row.insert(QString::fromUtf8("endedAtMs"), endedAt);
        row.insert(
            QString::fromUtf8("startedAt"),
            QDateTime::fromMSecsSinceEpoch(startedAt, QTimeZone::UTC).toLocalTime().toString(QString::fromUtf8("yyyy-MM-dd HH:mm")));
        row.insert(
            QString::fromUtf8("endedAt"),
            QDateTime::fromMSecsSinceEpoch(endedAt, QTimeZone::UTC).toLocalTime().toString(QString::fromUtf8("yyyy-MM-dd HH:mm")));
        row.insert(QString::fromUtf8("rxBytes"), rx);
        row.insert(QString::fromUtf8("txBytes"), tx);
        row.insert(QString::fromUtf8("totalBytes"), total);
        row.insert(QString::fromUtf8("rxText"), formatBytes(rx));
        row.insert(QString::fromUtf8("txText"), formatBytes(tx));
        row.insert(QString::fromUtf8("totalText"), formatBytes(total));
        out.append(row);
    }
    return out;
}

QVariantMap VpnController::latestUsageSnapshotForId(const QString& profileId) const
{
    QVariantMap out;
    const QString id = profileId.trimmed();
    if (id.isEmpty()) {
        return out;
    }

    const QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    const QJsonObject usage = profiles.value(id).toObject();
    if (usage.isEmpty()) {
        return out;
    }

    const QJsonObject latestSession = usage.value(QString::fromUtf8("latestSession")).toObject();
    qint64 rx = 0;
    qint64 tx = 0;
    qint64 total = 0;
    qint64 updatedAt = usage.value(QString::fromUtf8("updatedAt")).toVariant().toLongLong();
    if (!latestSession.isEmpty()) {
        rx = latestSession.value(QString::fromUtf8("rx")).toVariant().toLongLong();
        tx = latestSession.value(QString::fromUtf8("tx")).toVariant().toLongLong();
        total = latestSession.value(QString::fromUtf8("total")).toVariant().toLongLong();
        updatedAt = latestSession.value(QString::fromUtf8("endedAt")).toVariant().toLongLong();
    } else {
        rx = usage.value(QString::fromUtf8("latestSnapshotRx")).toVariant().toLongLong();
        tx = usage.value(QString::fromUtf8("latestSnapshotTx")).toVariant().toLongLong();
        total = usage.value(QString::fromUtf8("latestSnapshotTotal")).toVariant().toLongLong();
    }

    out.insert(QString::fromUtf8("rxBytes"), rx);
    out.insert(QString::fromUtf8("txBytes"), tx);
    out.insert(QString::fromUtf8("totalBytes"), total);
    out.insert(QString::fromUtf8("rxText"), formatBytes(rx));
    out.insert(QString::fromUtf8("txText"), formatBytes(tx));
    out.insert(QString::fromUtf8("totalText"), formatBytes(total));
    out.insert(QString::fromUtf8("updatedAt"), updatedAt);
    return out;
}

QString VpnController::currentProfileUsageText(const QString& period) const
{
    const QVariantMap summary = currentProfileUsageSummary();
    const QString key = period.trimmed().toLower() + QString::fromUtf8("Text");
    const QString text = summary.value(key).toString().trimmed();
    return text.isEmpty() ? QString::fromUtf8("0 B") : text;
}

QVariantMap VpnController::currentProfileUsageSummary() const
{
    QString id = m_currentProfileId.trimmed();
    if (id.isEmpty()) {
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            id = profile->id.trimmed();
        }
    }
    return profileUsageSummaryForId(id);
}

QVariantList VpnController::currentProfileUsageHistory(const QString& period, int limit) const
{
    QString id = m_currentProfileId.trimmed();
    if (id.isEmpty()) {
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            id = profile->id.trimmed();
        }
    }
    return profileUsageHistoryForId(id, period, limit);
}

QVariantList VpnController::currentProfileUsageSessions(int limit) const
{
    QString id = m_currentProfileId.trimmed();
    if (id.isEmpty()) {
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            id = profile->id.trimmed();
        }
    }
    return profileUsageSessionsForId(id, limit);
}

void VpnController::clearCurrentProfileUsage()
{
    QString id = m_currentProfileId.trimmed();
    if (id.isEmpty()) {
        const auto profile = m_profileModel->profileAt(m_currentProfileIndex);
        if (profile.has_value()) {
            id = profile->id.trimmed();
        }
    }
    if (id.isEmpty()) {
        return;
    }

    QJsonObject profiles = m_profileUsageRoot.value(QString::fromUtf8("profiles")).toObject();
    if (!profiles.contains(id)) {
        return;
    }

    profiles.remove(id);
    m_profileUsageRoot.insert(QString::fromUtf8("profiles"), profiles);
    if (m_usageSessionProfileId.compare(id, Qt::CaseInsensitive) == 0) {
        m_usageSessionRxBytes = 0;
        m_usageSessionTxBytes = 0;
    }
    scheduleProfileUsageSave();
    emit profileUsageChanged();
}

void VpnController::clearAllProfileUsage()
{
    m_profileUsageRoot.insert(QString::fromUtf8("profiles"), QJsonObject {});
    m_usageSessionProfileId.clear();
    m_usageSessionRxBytes = 0;
    m_usageSessionTxBytes = 0;
    m_usageSessionStartedAt = QDateTime();
    scheduleProfileUsageSave();
    emit profileUsageChanged();
}

QVariantList VpnController::availableAppRuleItems() const
{
    QVariantList out;
    QSet<QString> seen;

    auto appendName = [&out, &seen](const QString& rawName, const QString& source) {
        QString name = rawName.trimmed();
        if (name.isEmpty()) {
            return;
        }
        if (name.contains('/')) {
            name = QFileInfo(name).fileName().trimmed();
        }
        if (name.endsWith(QString::fromUtf8(".app"), Qt::CaseInsensitive)) {
            name.chop(4);
        }
        if (name.isEmpty()) {
            return;
        }
        const QString key = name.toLower();
        if (seen.contains(key)) {
            return;
        }
        if (key == QString::fromUtf8("kernel_task")
            || key == QString::fromUtf8("launchd")
            || key == QString::fromUtf8("system")
            || key == QString::fromUtf8("idle")
            || key == QString::fromUtf8("windowserver")) {
            return;
        }
        seen.insert(key);
        QVariantMap item;
        item.insert(QString::fromUtf8("process"), name);
        item.insert(QString::fromUtf8("source"), source);
        out.append(item);
    };

    QProcess process;
#if defined(Q_OS_WIN)
    process.start(QString::fromUtf8("tasklist"), {QString::fromUtf8("/FO"), QString::fromUtf8("CSV"), QString::fromUtf8("/NH")});
#elif defined(Q_OS_MACOS)
    process.start(QString::fromUtf8("/bin/ps"), {QString::fromUtf8("-axo"), QString::fromUtf8("comm=")});
#else
    process.start(QString::fromUtf8("ps"), {QString::fromUtf8("-eo"), QString::fromUtf8("comm=")});
#endif
    if (process.waitForStarted(1500) && process.waitForFinished(4000)) {
        const QString output = QString::fromUtf8(process.readAllStandardOutput());
        const QStringList lines = output.split(QRegularExpression(QString::fromUtf8("[\\r\\n]+")), Qt::SkipEmptyParts);
        for (const QString& line : lines) {
#if defined(Q_OS_WIN)
            QString trimmed = line.trimmed();
            if (!trimmed.startsWith('\"')) {
                continue;
            }
            trimmed.remove(0, 1);
            const int quoteIndex = trimmed.indexOf('\"');
            if (quoteIndex <= 0) {
                continue;
            }
            const QString imageName = trimmed.left(quoteIndex).trimmed();
            appendName(imageName, QString::fromUtf8("tasklist"));
#else
            appendName(line, QString::fromUtf8("ps"));
#endif
            if (out.size() >= 240) {
                break;
            }
        }
    }

    std::sort(out.begin(), out.end(), [](const QVariant& a, const QVariant& b) {
        return a.toMap().value(QString::fromUtf8("process")).toString().toLower()
               < b.toMap().value(QString::fromUtf8("process")).toString().toLower();
    });
    return out;
}

void VpnController::appendAppRule(const QString& target, const QString& process)
{
    const QString normalizedProcess = process.trimmed();
    if (normalizedProcess.isEmpty()) {
        return;
    }

    if (!detectProcessRoutingSupport()) {
        appendSystemLog(QString::fromUtf8(
            "[System] App rule update ignored: process routing is unsupported on this platform/runtime."));
        return;
    }

    auto removeEntry = [this, &normalizedProcess](const QString& existingText) {
        const QString key = normalizedProcess.toLower();
        QStringList rules = parseRules(existingText);
        QStringList next;
        next.reserve(rules.size());
        for (const QString& rule : std::as_const(rules)) {
            if (rule.trimmed().toLower() == key) {
                continue;
            }
            next.append(rule);
        }
        return next.join('\n');
    };

    auto appendUnique = [this, &normalizedProcess](const QString& existingText) {
        QStringList rules = parseRules(existingText);
        const QString key = normalizedProcess.toLower();
        bool exists = false;
        for (const QString& rule : std::as_const(rules)) {
            if (rule.toLower() == key) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            rules.append(normalizedProcess);
        }
        return rules.join('\n');
    };

    QString proxyRules = removeEntry(m_proxyAppRules);
    QString directRules = removeEntry(m_directAppRules);
    QString blockRules = removeEntry(m_blockAppRules);

    const QString bucket = target.trimmed().toLower();
    if (bucket == QString::fromUtf8("proxy") || bucket == QString::fromUtf8("tunnel")) {
        proxyRules = appendUnique(proxyRules);
    } else if (bucket == QString::fromUtf8("direct")) {
        directRules = appendUnique(directRules);
    } else if (bucket == QString::fromUtf8("block")) {
        blockRules = appendUnique(blockRules);
    } else {
        return;
    }

    setProxyAppRules(proxyRules);
    setDirectAppRules(directRules);
    setBlockAppRules(blockRules);
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
    if (!m_profileUsageRoot.contains(QString::fromUtf8("profiles"))
        || !m_profileUsageRoot.value(QString::fromUtf8("profiles")).isObject()) {
        m_profileUsageRoot.insert(QString::fromUtf8("profiles"), QJsonObject {});
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
        QString::fromUtf8("taskkill"),
        {QString::fromUtf8("/PID"), QString::number(pid), QString::fromUtf8("/T"), QString::fromUtf8("/F")});
#else
    ::kill(static_cast<pid_t>(pid), SIGTERM);
    QThread::msleep(120);
    ::kill(static_cast<pid_t>(pid), SIGKILL);
#endif
}

bool VpnController::isProcessAlive(qint64 pid)
{
    if (pid <= 0) {
        return false;
    }
#if defined(Q_OS_WIN)
    HANDLE handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, static_cast<DWORD>(pid));
    if (handle == nullptr) {
        return false;
    }
    DWORD exitCode = 0;
    const BOOL ok = GetExitCodeProcess(handle, &exitCode);
    CloseHandle(handle);
    return ok && exitCode == STILL_ACTIVE;
#else
    if (::kill(static_cast<pid_t>(pid), 0) == 0) {
        return true;
    }
    return errno == EPERM;
#endif
}

QString VpnController::processExecutablePath(qint64 pid)
{
    if (pid <= 0) {
        return {};
    }
#if defined(Q_OS_WIN)
    HANDLE handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, static_cast<DWORD>(pid));
    if (handle == nullptr) {
        return {};
    }
    std::wstring buffer;
    buffer.resize(32768);
    DWORD size = static_cast<DWORD>(buffer.size());
    if (!QueryFullProcessImageNameW(handle, 0, buffer.data(), &size)) {
        CloseHandle(handle);
        return {};
    }
    CloseHandle(handle);
    return QDir::cleanPath(QString::fromWCharArray(buffer.data(), static_cast<int>(size)));
#elif defined(Q_OS_MACOS)
    char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];
    std::memset(pathBuffer, 0, sizeof(pathBuffer));
    const int written = proc_pidpath(static_cast<int>(pid), pathBuffer, sizeof(pathBuffer));
    if (written <= 0) {
        return {};
    }
    return QDir::cleanPath(QString::fromUtf8(pathBuffer, written));
#elif defined(Q_OS_LINUX)
    const QByteArray path = QFile::encodeName(QString::fromUtf8("/proc/%1/exe").arg(pid));
    char resolved[4096];
    std::memset(resolved, 0, sizeof(resolved));
    const ssize_t len = ::readlink(path.constData(), resolved, sizeof(resolved) - 1);
    if (len <= 0) {
        return {};
    }
    resolved[len] = '\0';
    return QDir::cleanPath(QString::fromLocal8Bit(resolved));
#else
    return {};
#endif
}

bool VpnController::isProcessLikelyManagedXray(qint64 pid, const QString& expectedExecutablePath) const
{
    if (!isProcessAlive(pid)) {
        return false;
    }
    const QString expected = QFileInfo(expectedExecutablePath).canonicalFilePath().isEmpty()
                                 ? QDir::cleanPath(expectedExecutablePath)
                                 : QFileInfo(expectedExecutablePath).canonicalFilePath();
    const QString actualRaw = processExecutablePath(pid);
    if (actualRaw.trimmed().isEmpty()) {
        return false;
    }
    const QString actual = QFileInfo(actualRaw).canonicalFilePath().isEmpty()
                               ? QDir::cleanPath(actualRaw)
                               : QFileInfo(actualRaw).canonicalFilePath();
    return !expected.trimmed().isEmpty()
           && actual.compare(expected, Qt::CaseInsensitive) == 0;
}

void VpnController::writeManagedRuntimeRecord(qint64 pid, const QString& mode)
{
    if (pid <= 0 || m_managedRuntimeRecordPath.trimmed().isEmpty()) {
        return;
    }
    QJsonObject record;
    record.insert(QString::fromUtf8("pid"), pid);
    record.insert(QString::fromUtf8("mode"), mode.trimmed());
    record.insert(QString::fromUtf8("startedAt"), QDateTime::currentDateTimeUtc().toMSecsSinceEpoch());
    record.insert(QString::fromUtf8("executablePath"), m_xrayExecutablePath);
    record.insert(QString::fromUtf8("configPath"), m_runtimeConfigPath);
    record.insert(QString::fromUtf8("ownerPid"), static_cast<qint64>(QCoreApplication::applicationPid()));
    if (mode.compare(QString::fromUtf8("tun"), Qt::CaseInsensitive) == 0) {
        record.insert(QString::fromUtf8("pidPath"), m_privilegedTunPidPath);
    }

    QSaveFile file(m_managedRuntimeRecordPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    file.write(QJsonDocument(record).toJson(QJsonDocument::Compact));
    file.commit();
}

void VpnController::clearManagedRuntimeRecord()
{
    if (m_managedRuntimeRecordPath.trimmed().isEmpty()) {
        return;
    }
    QFile::remove(m_managedRuntimeRecordPath);
}

bool VpnController::tryLoadManagedRuntimeRecord(QJsonObject *record) const
{
    if (record == nullptr || m_managedRuntimeRecordPath.trimmed().isEmpty()) {
        return false;
    }
    QFile file(m_managedRuntimeRecordPath);
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        return false;
    }
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        return false;
    }
    *record = doc.object();
    return true;
}

bool VpnController::cleanupManagedRuntimeFromRecord(const QJsonObject& record, const QString& reason)
{
    const qint64 pid = record.value(QString::fromUtf8("pid")).toVariant().toLongLong();
    if (pid <= 0) {
        clearManagedRuntimeRecord();
        return false;
    }

    const QString expectedExecutable = record.value(QString::fromUtf8("executablePath")).toString().trimmed();
    if (!isProcessLikelyManagedXray(pid, expectedExecutable)) {
        clearManagedRuntimeRecord();
        return false;
    }

    appendSystemLog(QString::fromUtf8("[System] Cleaning stale managed Xray runtime (pid=%1): %2")
                        .arg(pid)
                        .arg(reason.trimmed().isEmpty() ? QString::fromUtf8("startup safety cleanup") : reason.trimmed()));
    killProcessByPid(pid);
    clearManagedRuntimeRecord();
    QFile::remove(m_privilegedTunPidPath);
    return true;
}

void VpnController::cleanupManagedRuntimeOnStartup()
{
    QJsonObject record;
    if (!tryLoadManagedRuntimeRecord(&record)) {
        stopPrivilegedTunRuntimeByPidPath();
        return;
    }
    cleanupManagedRuntimeFromRecord(record, QString::fromUtf8("previous session was not terminated cleanly"));
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
    if (ok && pid > 0 && isProcessLikelyManagedXray(pid, m_xrayExecutablePath)) {
        killProcessByPid(pid);
    }
    QFile::remove(m_privilegedTunPidPath);
}

void VpnController::cleanupDetachedHelpers()
{
    QJsonObject record;
    if (tryLoadManagedRuntimeRecord(&record)) {
        Q_UNUSED(cleanupManagedRuntimeFromRecord(record, QString::fromUtf8("application shutdown cleanup")));
    }
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
    if (!m_runtimeSupportsSystemProxy) {
        Q_UNUSED(force)
        if (enable) {
            const QString message = QString::fromUtf8("System proxy is not supported on this platform runtime.");
            appendSystemLog(QString::fromUtf8("[System] %1").arg(message));
            setLastError(message);
        } else {
            m_systemProxyApplied = false;
        }
        return;
    }

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
                appendSystemLog(QString::fromUtf8("[System] System proxy enabled."));
            } else if (!result.enable && previousAppliedState) {
                appendSystemLog(QString::fromUtf8("[System] System proxy disabled."));
            }
        } else if (!result.error.trimmed().isEmpty()) {
            const QString message = result.enable
                                        ? QString::fromUtf8("Connected, but failed to enable system proxy: %1")
                                              .arg(result.error.trimmed())
                                        : QString::fromUtf8("Failed to disable system proxy: %1")
                                              .arg(result.error.trimmed());
            appendSystemLog(QString::fromUtf8("[System] %1").arg(message));
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
        appendSystemLog(QString::fromUtf8("[System] %1").arg(reason.trimmed()));
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
    return QDir(QCoreApplication::applicationDirPath()).filePath(QString::fromUtf8("GenyConnectTunHelper.exe"));
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(QString::fromUtf8("GenyConnectTunHelper"));
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
            *errorMessage = QString::fromUtf8("Privileged helper is not initialized.");
        }
        return false;
    }

    QJsonObject payload = request;
    payload.insert(QString::fromUtf8("token"), m_privilegedTunHelperToken);

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
            *errorMessage = QString::fromUtf8("Could not connect to privileged helper.");
        }
        return false;
    }

    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact) + '\n';
    if (socket.write(body) < 0) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to send request to privileged helper.");
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
            *errorMessage = QString::fromUtf8("Failed to send request to privileged helper.");
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
                *errorMessage = QString::fromUtf8("Timed out waiting for privileged helper response.");
            } else if (disconnectedBeforeReply) {
                *errorMessage = QString::fromUtf8("Privileged helper disconnected before sending a response.");
            } else if (!sawData) {
                *errorMessage = QString::fromUtf8("Privileged helper returned no data.");
            } else {
                *errorMessage = QString::fromUtf8("Privileged helper returned an empty response.");
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
                preview = preview.left(180) + QString::fromUtf8("...");
            }
            *errorMessage = QString::fromUtf8("Privileged helper returned invalid JSON: %1").arg(preview);
        }
        return false;
    }

    const QJsonObject responseObject = replyDoc.object();
    bool helperPidOk = false;
    const qint64 helperPid = responseObject.value(QString::fromUtf8("helper_pid")).toVariant().toLongLong(&helperPidOk);
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
        if (!sendPrivilegedTunHelperRequest(QJsonObject{{QString::fromUtf8("action"), QString::fromUtf8("ping")}},
                                            &response,
                                            &pingError,
                                            2500)) {
            return false;
        }
        return response.value(QString::fromUtf8("ok")).toBool(false);
    };

    if (m_privilegedTunHelperReady && helperResponding()) {
        return true;
    }

    const QString helperPath = privilegedTunHelperPath();
    if (helperPath.trimmed().isEmpty() || !QFileInfo::exists(helperPath)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Privileged helper executable not found: %1").arg(helperPath);
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
            launchError = QString::fromUtf8("Failed to allocate local port for privileged TUN helper.");
            continue;
        }
        const QStringList launchArgs = {
            QString::fromUtf8("--listen-port"), QString::number(m_privilegedTunHelperPort),
            QString::fromUtf8("--token"), m_privilegedTunHelperToken,
            QString::fromUtf8("--idle-timeout-ms"), QString::fromUtf8("1800000")
        };

#if defined(Q_OS_MACOS)
        const QString command = quoteForShell(helperPath)
                                + QString::fromUtf8(" ")
                                + joinQuotedArgsForShell(launchArgs)
                                + QString::fromUtf8(" >/dev/null 2>&1 &");
        const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
                                   .arg(escapeForAppleScriptString(command));
        QProcess process;
        process.start(QString::fromUtf8("/usr/bin/osascript"), {QString::fromUtf8("-e"), script});
        if (!process.waitForStarted(5000)) {
            launchError = QString::fromUtf8("Failed to open macOS elevation prompt for TUN helper.");
            continue;
        }
        if (!waitForProcessFinishedResponsive(process, 60000)) {
            process.kill();
            waitForProcessFinishedResponsive(process, 1000);
            launchError = QString::fromUtf8("macOS elevation prompt timed out for TUN helper.");
            continue;
        }
        if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
            const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
            launchError = stderrText.isEmpty()
                              ? QString::fromUtf8("macOS elevation for TUN helper was canceled.")
                              : QString::fromUtf8("macOS elevation for TUN helper failed: %1").arg(stderrText);
            continue;
        }
        started = true;
#elif defined(Q_OS_WIN)
        const QString psArgArray = toPowerShellArgumentArrayLiteral(launchArgs);
        const QString command = QString::fromUtf8(
                                    "Start-Process -Verb RunAs -WindowStyle Hidden -FilePath %1 -ArgumentList %2")
                                    .arg(quoteForPowerShellSingleQuoted(helperPath), psArgArray);
        qint64 detachedPid = 0;
        if (!QProcess::startDetached(
                QString::fromUtf8("powershell"),
                {QString::fromUtf8("-NoProfile"), QString::fromUtf8("-ExecutionPolicy"), QString::fromUtf8("Bypass"),
                 QString::fromUtf8("-Command"), command},
                QString(),
                &detachedPid)) {
            launchError = QString::fromUtf8("Failed to request Windows UAC for TUN helper.");
            continue;
        }
        if (detachedPid > 0) {
            m_privilegedTunHelperPid = detachedPid;
        }
        started = true;
#elif defined(Q_OS_LINUX)
        if (QStandardPaths::findExecutable(QString::fromUtf8("pkexec")).isEmpty()) {
            launchError = QString::fromUtf8("pkexec is required for TUN helper on Linux.");
            continue;
        }
        QStringList pkexecArgs;
        pkexecArgs << helperPath;
        pkexecArgs << launchArgs;
        qint64 detachedPid = 0;
        if (!QProcess::startDetached(QString::fromUtf8("pkexec"), pkexecArgs, QString(), &detachedPid)) {
            launchError = QString::fromUtf8("Failed to request elevation for Linux TUN helper.");
            continue;
        }
        if (detachedPid > 0) {
            m_privilegedTunHelperPid = detachedPid;
        }
        started = true;
#else
        launchError = QString::fromUtf8("Privileged TUN helper is not implemented on this platform.");
        Q_UNUSED(launchArgs)
#endif
    }

    if (!started) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = launchError.isEmpty()
            ? QString::fromUtf8("Failed to launch privileged TUN helper.")
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
        if (sendPrivilegedTunHelperRequest(QJsonObject{{QString::fromUtf8("action"), QString::fromUtf8("ping")}},
                                           &response,
                                           &lastPingError,
                                           2500)
            && response.value(QString::fromUtf8("ok")).toBool(false)) {
            ready = true;
            break;
        }
    }

    if (!ready) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = lastPingError.isEmpty()
            ? QString::fromUtf8("Timed out waiting for privileged TUN helper to start.")
            : QString::fromUtf8("Privileged TUN helper did not respond: %1").arg(lastPingError);
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
        QJsonObject{{QString::fromUtf8("action"), QString::fromUtf8("shutdown")}},
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
            *errorMessage = QString::fromUtf8("Cannot relaunch with elevation: executable path is empty.");
        }
        return false;
    }

    QStringList args = QCoreApplication::arguments();
    if (!args.isEmpty()) {
        args.removeFirst();
    }
    if (!args.contains(QString::fromUtf8("--geny-elevated-tun"))) {
        args.append(QString::fromUtf8("--geny-elevated-tun"));
    }

#if defined(Q_OS_MACOS)
    const QString command = quoteForShell(executablePath)
                            + QString::fromUtf8(" ")
                            + joinQuotedArgsForShell(args)
                            + QString::fromUtf8(" >/dev/null 2>&1 &");
    const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(QString::fromUtf8("/usr/bin/osascript"), {QString::fromUtf8("-e"), script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to start macOS elevation prompt.");
        }
        return false;
    }
    if (!waitForProcessFinishedResponsive(process, 60000)) {
        process.kill();
        waitForProcessFinishedResponsive(process, 1000);
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("macOS elevation prompt timed out.");
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? QString::fromUtf8("macOS elevation request was canceled or failed.")
            : QString::fromUtf8("macOS elevation failed: %1").arg(stderrText);
        }
        return false;
    }
    return true;
#elif defined(Q_OS_WIN)
    const QString argClause = args.isEmpty()
                                  ? QString()
                                  : QString::fromUtf8(" -ArgumentList %1").arg(toPowerShellArgumentArrayLiteral(args));
    const QString command =
        QString::fromUtf8("Start-Process -Verb RunAs -FilePath %1%2")
            .arg(quoteForPowerShellSingleQuoted(executablePath), argClause);
    if (!QProcess::startDetached(
            QString::fromUtf8("powershell"),
            {QString::fromUtf8("-NoProfile"), QString::fromUtf8("-ExecutionPolicy"), QString::fromUtf8("Bypass"),
             QString::fromUtf8("-Command"), command})) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to request Windows UAC elevation.");
        }
        return false;
    }
    return true;
#elif defined(Q_OS_LINUX)
    if (QStandardPaths::findExecutable(QString::fromUtf8("pkexec")).isEmpty()) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8(
                "pkexec is not available. Install polkit tools or run GenyConnect as root for TUN mode.");
        }
        return false;
    }

    QStringList launchArgs;
    launchArgs << executablePath;
    launchArgs << args;
    if (!QProcess::startDetached(QString::fromUtf8("pkexec"), launchArgs)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to request Linux elevation (pkexec).");
        }
        return false;
    }
    return true;
#else
    if (errorMessage) {
        *errorMessage = QString::fromUtf8("TUN elevation flow is not implemented on this platform.");
    }
    return false;
#endif
}

bool VpnController::startPrivilegedTunProcess(QString *errorMessage)
{
    m_privilegedTunRuntimePid = -1;
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
            *errorMessage = QString::fromUtf8("TUN start failed: missing interface name.");
        }
        return false;
    }
#endif

    QJsonObject response;
    QString helperError;
    if (!sendPrivilegedTunHelperRequest(
            QJsonObject{
                {QString::fromUtf8("action"), QString::fromUtf8("start_tun")},
                {QString::fromUtf8("xray_path"), m_xrayExecutablePath},
                {QString::fromUtf8("config_path"), m_runtimeConfigPath},
                {QString::fromUtf8("pid_path"), m_privilegedTunPidPath},
                {QString::fromUtf8("log_path"), m_privilegedTunLogPath},
                {QString::fromUtf8("tun_if"), tunIf},
                {QString::fromUtf8("server_ip"), m_lastTunServerIp},
                {QString::fromUtf8("server_host"), m_activeProfileAddress.trimmed()},
                {QString::fromUtf8("owner_pid"), static_cast<qint64>(QCoreApplication::applicationPid())},
                {QString::fromUtf8("dns_servers"), QJsonArray::fromStringList(parseDnsServers(m_customDnsServers))}
            },
            &response,
            &helperError,
            90000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? QString::fromUtf8("Privileged helper failed to start TUN runtime.")
            : helperError;
        }
        return false;
    }

    if (!response.value(QString::fromUtf8("ok")).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(QString::fromUtf8("message")).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = QString::fromUtf8("Privileged helper rejected TUN start.");
            }
        }
        return false;
    }

    QFile pidFile(m_privilegedTunPidPath);
    if (!pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("TUN start failed: pid file was not created.");
        }
        return false;
    }
    const QString pidText = QString::fromUtf8(pidFile.readAll()).trimmed();
    pidFile.close();
    if (pidText.isEmpty()) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("TUN start failed: invalid process id.");
        }
        return false;
    }
    bool pidOk = false;
    const qint64 pidValue = pidText.toLongLong(&pidOk);
    if (!pidOk || pidValue <= 0) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("TUN start failed: invalid process id.");
        }
        return false;
    }
    m_privilegedTunRuntimePid = pidValue;

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
                *errorMessage = QString::fromUtf8("TUN startup failed: %1").arg(tailLine);
            } else if (!lastCheckError.trimmed().isEmpty()) {
                *errorMessage = QString::fromUtf8("TUN startup failed: %1").arg(lastCheckError.trimmed());
            } else {
                *errorMessage = QString::fromUtf8("TUN startup failed: xray local mixed port was not reachable in time.");
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
        m_privilegedTunRuntimePid = -1;
        return true;
    }

    QJsonObject response;
    QString helperError;
    if (!sendPrivilegedTunHelperRequest(
            QJsonObject{
                {QString::fromUtf8("action"), QString::fromUtf8("stop_tun")},
                {QString::fromUtf8("pid_path"), m_privilegedTunPidPath},
                {QString::fromUtf8("tun_if"), m_selectedTunInterfaceName.trimmed()},
                {QString::fromUtf8("server_ip"), m_lastTunServerIp.trimmed()}
            },
            &response,
            &helperError,
            10000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? QString::fromUtf8("Privileged helper failed to stop TUN runtime.")
            : helperError;
        }
        return false;
    }

    if (!response.value(QString::fromUtf8("ok")).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(QString::fromUtf8("message")).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = QString::fromUtf8("Privileged helper rejected TUN stop.");
            }
        }
        return false;
    }

    m_lastTunServerIp.clear();
    m_privilegedTunRuntimePid = -1;
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
        appendSystemLog(QString::fromUtf8("[System] Log stream is very busy. Older lines were trimmed to keep UI responsive."));
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
            *errorMessage = QString::fromUtf8("TUN route setup failed: missing interface name.");
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

    const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(QString::fromUtf8("/usr/bin/osascript"), {QString::fromUtf8("-e"), script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to request permissions for TUN route setup.");
        }
        return false;
    }
    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished(1000);
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Timed out while applying TUN routes.");
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? QString::fromUtf8("Failed to apply macOS TUN routes.")
            : QString::fromUtf8("Failed to apply macOS TUN routes: %1").arg(stderrText);
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
                                   : QString::fromUtf8("route -n delete -host %1 >/dev/null 2>&1 || true;").arg(m_lastTunServerIp.trimmed());
    const QString command =
        hostDelete
        + QString::fromUtf8("route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                         "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
              .arg(tunIf);
    const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess::execute(QString::fromUtf8("/usr/bin/osascript"), {QString::fromUtf8("-e"), script});
    m_lastTunServerIp.clear();
#endif
}

bool VpnController::writeRuntimeConfig(const ServerProfile& profile, QString *errorMessage)
{
    XrayConfigBuilder::BuildOptions options = m_buildOptions;
    if (m_powerModeManager) {
        const auto policy = m_powerModeManager->effectivePolicy();
        options.enableFakeDnsSniffing = !policy.reduceFakeDnsSniffing;
        if (policy.lightweightRoutingPreferred) {
            appendSystemLog(QString::fromUtf8(
                "[PowerMode] Save mode keeps routing stable and only reduces optional FakeDNS sniff override for new runtime configs."));
        }
    }
    options.enableTun = m_tunMode;
    options.tunAutoRoute = true;
    options.tunStrictRoute = true;
    options.tunInterfaceName = options.enableTun ? selectTunInterfaceName() : QString();
    options.dnsServers = parseDnsServers(m_customDnsServers);
    m_effectiveTunMode = options.enableTun;
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
        appendSystemLog(QString::fromUtf8(
            "[System] App rules ignored: current xray-core does not support process routing (requires Xray 26.1.23+)."
            ));
    }

    QJsonObject config = XrayConfigBuilder::build(profile, options);
    if (options.enableTun) {
        ensureTunDnsSupport(&config, parseDnsServers(m_customDnsServers));
        // Ensure noisy link-local/broadcast packets are blocked in TUN mode.
        // This prevents direct-route packet loops that can spike xray CPU usage.
        ensureTunNoiseBlockRules(&config);
    }

    if (options.enableTun && !options.tunInterfaceName.trimmed().isEmpty()) {
        appendSystemLog(QString::fromUtf8("[System] TUN interface selected: %1").arg(options.tunInterfaceName));
    }
    QSaveFile file(m_runtimeConfigPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to open config file: %1").arg(m_runtimeConfigPath);
        }
        return false;
    }

    const QJsonDocument doc(config);
    file.write(doc.toJson(QJsonDocument::Indented));

    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = QString::fromUtf8("Failed to write config file to disk.");
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
    candidates << QDir(appDir).filePath(QString::fromUtf8("xray-core.exe"));
    candidates << QDir(appDir).filePath(QString::fromUtf8("xray.exe"));
#else
    candidates << QDir(appDir).filePath(QString::fromUtf8("xray-core"));
    candidates << QDir(appDir).filePath(QString::fromUtf8("xray"));
#endif

    for (const QString& path : std::as_const(candidates)) {
        QFileInfo info(path);
        if (info.exists() && info.isFile()) {
            return path;
        }
    }

    const QStringList executableCandidates {
#ifdef Q_OS_WIN
        QString::fromUtf8("xray-core.exe"),
        QString::fromUtf8("xray.exe"),
#else
        QString::fromUtf8("xray-core"),
        QString::fromUtf8("xray"),
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
                normalized.sourceName = QString::fromUtf8("Manual import");
            }
            if (normalized.sourceId.trimmed().isEmpty()) {
                normalized.sourceId = QString::fromUtf8("manual");
            }
            loadedProfiles.append(normalized);
        }
    }

    m_profileModel->setProfiles(loadedProfiles);
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
            entry.id = obj.value(QString::fromUtf8("id")).toString().trimmed();
            entry.url = obj.value(QString::fromUtf8("url")).toString().trimmed();
            entry.name = obj.value(QString::fromUtf8("name")).toString().trimmed();
            entry.group = obj.value(QString::fromUtf8("group")).toString().trimmed();
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
            || (parsedUrl.scheme() != QString::fromUtf8("http") && parsedUrl.scheme() != QString::fromUtf8("https"))) {
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
    const auto allProfiles = m_profileModel->profiles();
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
        obj[QString::fromUtf8("id")] = entry.id;
        obj[QString::fromUtf8("name")] = entry.name;
        obj[QString::fromUtf8("group")] = entry.group;
        obj[QString::fromUtf8("url")] = entry.url;
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
    if (m_powerModeManager) {
        m_powerModeManager->loadSettings();
    }
    m_xrayExecutablePath = settings.value(QString::fromUtf8("xray/executablePath")).toString().trimmed();
    m_loggingEnabled = settings.value(QString::fromUtf8("logs/enabled"), true).toBool();
    m_autoPingProfiles = settings.value(QString::fromUtf8("profiles/autoPing"), false).toBool();
    m_currentProfileIndex = settings.value(QString::fromUtf8("profiles/currentIndex"), -1).toInt();
    m_currentProfileId = settings.value(QString::fromUtf8("profiles/currentId")).toString().trimmed();

    m_profileGroupOptions.clear();
    const QString rawGroupOptions = settings.value(QString::fromUtf8("profiles/groupOptionsJson")).toString().trimmed();
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
                options.name = normalizeGroupName(obj.value(QString::fromUtf8("name")).toString());
                options.key = normalizeGroupKey(options.name);
                options.enabled = obj.value(QString::fromUtf8("enabled")).toBool(true);
                options.exclusive = obj.value(QString::fromUtf8("exclusive")).toBool(false);
                options.badge = obj.value(QString::fromUtf8("badge")).toString().trimmed();

                if (options.name.compare(QString::fromUtf8("All"), Qt::CaseInsensitive) == 0) {
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

    m_currentProfileGroup = settings.value(QString::fromUtf8("profiles/currentGroup"), QString::fromUtf8("All")).toString().trimmed();
    if (m_currentProfileGroup.isEmpty()) {
        m_currentProfileGroup = QString::fromUtf8("All");
    }
    const bool modeExplicitlyChosen = settings.value(
                                                  QString::fromUtf8("network/modeExplicitlyChosen"), false).toBool();
    m_tunMode = modeExplicitlyChosen
                    ? settings.value(QString::fromUtf8("network/tunMode"), false).toBool()
                    : true;
    m_useSystemProxy = modeExplicitlyChosen
                           ? settings.value(QString::fromUtf8("network/useSystemProxy"), false).toBool()
                           : false;
    if (m_tunMode) {
        m_useSystemProxy = false;
    }
    m_killSwitchEnabled = settings.value(QString::fromUtf8("network/killSwitchEnabled"), false).toBool();
    if (settings.contains(QString::fromUtf8("network/autoDisableSystemProxyOnDisconnect"))) {
        m_autoDisableSystemProxyOnDisconnect =
            settings.value(QString::fromUtf8("network/autoDisableSystemProxyOnDisconnect")).toBool();
    } else {
        m_autoDisableSystemProxyOnDisconnect = false;
    }
    m_whitelistMode = settings.value(QString::fromUtf8("routing/whitelistMode"), false).toBool();
    m_proxyDomainRules = settings.value(QString::fromUtf8("routing/proxyDomains")).toString();
    m_directDomainRules = settings.value(QString::fromUtf8("routing/directDomains")).toString();
    m_blockDomainRules = settings.value(QString::fromUtf8("routing/blockDomains")).toString();
    m_customDnsServers = parseDnsServers(
                             settings.value(QString::fromUtf8("routing/customDnsServers")).toString())
                             .join('\n');
    m_proxyAppRules = settings.value(QString::fromUtf8("routing/proxyApps")).toString();
    m_directAppRules = settings.value(QString::fromUtf8("routing/directApps")).toString();
    m_blockAppRules = settings.value(QString::fromUtf8("routing/blockApps")).toString();
    m_speedTestSelectedSizeMb = normalizedSpeedTestSizeMb(
        settings.value(QString::fromUtf8("speedtest/sizeMb"), kSpeedTestDefaultSizeMb).toInt());
    const QString endpointTemplate = settings.value(
                                         QString::fromUtf8("speedtest/downloadEndpointTemplate"),
                                         QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=%1"))
                                         .toString()
                                         .trimmed();
    m_speedTestDownloadEndpointTemplate = endpointTemplate.isEmpty()
                                              ? QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=%1")
                                              : endpointTemplate;
}

void VpnController::saveSettings() const
{
    QSettings settings;
    if (m_powerModeManager) {
        m_powerModeManager->saveSettings();
    }
    settings.setValue(QString::fromUtf8("xray/executablePath"), m_xrayExecutablePath);
    settings.setValue(QString::fromUtf8("logs/enabled"), m_loggingEnabled);
    settings.setValue(QString::fromUtf8("profiles/autoPing"), m_autoPingProfiles);
    settings.setValue(QString::fromUtf8("profiles/currentIndex"), m_currentProfileIndex);
    settings.setValue(QString::fromUtf8("profiles/currentId"), m_currentProfileId);
    settings.setValue(QString::fromUtf8("profiles/currentGroup"), m_currentProfileGroup);

    QJsonArray groupOptionsArray;
    for (const ProfileGroupOptions& options : m_profileGroupOptions) {
        QJsonObject obj;
        obj[QString::fromUtf8("name")] = options.name;
        obj[QString::fromUtf8("enabled")] = options.enabled;
        obj[QString::fromUtf8("exclusive")] = options.exclusive;
        obj[QString::fromUtf8("badge")] = options.badge;
        groupOptionsArray.append(obj);
    }
    settings.setValue(
        QString::fromUtf8("profiles/groupOptionsJson"),
        QString::fromUtf8(QJsonDocument(groupOptionsArray).toJson(QJsonDocument::Compact))
        );

    settings.setValue(QString::fromUtf8("network/useSystemProxy"), m_useSystemProxy);
    settings.setValue(QString::fromUtf8("network/tunMode"), m_tunMode);
    settings.setValue(QString::fromUtf8("network/killSwitchEnabled"), m_killSwitchEnabled);
    settings.setValue(
        QString::fromUtf8("network/autoDisableSystemProxyOnDisconnect"),
        m_autoDisableSystemProxyOnDisconnect
        );
    settings.setValue(QString::fromUtf8("routing/whitelistMode"), m_whitelistMode);
    settings.setValue(QString::fromUtf8("routing/proxyDomains"), m_proxyDomainRules);
    settings.setValue(QString::fromUtf8("routing/directDomains"), m_directDomainRules);
    settings.setValue(QString::fromUtf8("routing/blockDomains"), m_blockDomainRules);
    settings.setValue(QString::fromUtf8("routing/customDnsServers"), m_customDnsServers);
    settings.setValue(QString::fromUtf8("routing/proxyApps"), m_proxyAppRules);
    settings.setValue(QString::fromUtf8("routing/directApps"), m_directAppRules);
    settings.setValue(QString::fromUtf8("routing/blockApps"), m_blockAppRules);
    settings.setValue(QString::fromUtf8("speedtest/sizeMb"), m_speedTestSelectedSizeMb);
    settings.setValue(QString::fromUtf8("speedtest/downloadEndpointTemplate"), m_speedTestDownloadEndpointTemplate);
}

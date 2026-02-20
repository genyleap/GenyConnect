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
#include <QTcpSocket>
#include <QUuid>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrentRun>

#include <algorithm>

#if defined(Q_OS_WIN)
extern "C" {
#include <windows.h>
#include <shellapi.h>
}
#endif
#if defined(Q_OS_MACOS)
#include <unistd.h>
#endif
#if defined(Q_OS_LINUX)
#include <unistd.h>
#endif

module genyconnect.backend.vpncontroller;

import genyconnect.backend.linkparser;

namespace {
constexpr int kMaxLogLines = 200;
constexpr int kSpeedTestTickIntervalMs = 120;
constexpr int kSpeedTestPingSamples = 4;
constexpr int kSpeedTestMaxAttemptsPerPhase = 12;
constexpr int kSpeedTestHistoryMaxItems = 20;
constexpr int kProfilePingTimeoutMs = 3200;
constexpr int kProfilePingStaggerMs = 140;
constexpr int kSubscriptionFetchTimeoutMs = 15000;
constexpr const char kDefaultProfileGroup[] = "General";
constexpr int kMaxPrivilegedTunLogLinesPerTick = 64;
constexpr int kMaxPrivilegedTunLogBufferBytes = 512 * 1024;
constexpr int kPrivilegedTunLogBufferKeepBytes = 256 * 1024;

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
    const QStringList lines = normalized.split(QRegularExpression(QStringLiteral("[\\r\\n]+")), Qt::SkipEmptyParts);
    for (QString line : lines) {
        line = line.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        const QStringList tokens = line.split(QRegularExpression(QStringLiteral("[\\s,]+")), Qt::SkipEmptyParts);
        for (const QString& token : tokens) {
            const QString candidate = token.trimmed();
            if (candidate.startsWith(QStringLiteral("vmess://"), Qt::CaseInsensitive)
                || candidate.startsWith(QStringLiteral("vless://"), Qt::CaseInsensitive)) {
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

    if (trimmed.compare(QStringLiteral("all"), Qt::CaseInsensitive) == 0) {
        return QString::fromLatin1(kDefaultProfileGroup);
    }

    return trimmed;
}

QString deriveSubscriptionNameFromUrl(const QString& rawUrl)
{
    const QUrl url(rawUrl.trimmed());
    QString host = url.host().trimmed();
    if (host.startsWith(QStringLiteral("www."), Qt::CaseInsensitive)) {
        host = host.mid(4);
    }
    if (!host.isEmpty()) {
        return host;
    }

    const QString path = url.path().trimmed();
    if (!path.isEmpty() && path != QStringLiteral("/")) {
        return path;
    }

    return QStringLiteral("Subscription");
}

QString normalizeSubscriptionNameValue(const QString& rawName, const QString& fallbackUrl)
{
    const QString trimmed = rawName.trimmed();
    return trimmed.isEmpty() ? deriveSubscriptionNameFromUrl(fallbackUrl) : trimmed;
}

bool isNoisyTrafficLine(const QString& line)
{
    if (!line.contains(QStringLiteral(" accepted "))) {
        return false;
    }
    return line.contains(QStringLiteral("-> proxy"))
           || line.contains(QStringLiteral(">> proxy"))
           || line.contains(QStringLiteral("socks ->"))
           || line.contains(QStringLiteral("mixed-in ->"));
}

QList<QUrl> speedTestPingUrls()
{
    return {
        QUrl(QStringLiteral("https://www.cloudflare.com/cdn-cgi/trace")),
        QUrl(QStringLiteral("https://www.google.com/generate_204")),
        QUrl(QStringLiteral("https://cp.cloudflare.com/generate_204"))
    };
}

QList<QUrl> speedTestDownloadUrls()
{
    return {
        QUrl(QStringLiteral("https://speed.cloudflare.com/__down?bytes=32000000")),
        QUrl(QStringLiteral("https://speed.cloudflare.com/__down?bytes=64000000")),
        QUrl(QStringLiteral("https://speed.hetzner.de/100MB.bin"))
    };
}

QList<QUrl> speedTestUploadUrls()
{
    return {
        QUrl(QStringLiteral("https://speed.cloudflare.com/__up")),
        QUrl(QStringLiteral("https://httpbin.org/post"))
    };
}

QUrl speedTestUrlForPhase(const QString& phase, int attempt)
{
    const int safeAttempt = qMax(0, attempt);
    if (phase == QStringLiteral("Ping")) {
        const QList<QUrl> urls = speedTestPingUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == QStringLiteral("Download")) {
        const QList<QUrl> urls = speedTestDownloadUrls();
        return urls.at(safeAttempt % urls.size());
    }
    if (phase == QStringLiteral("Upload")) {
        const QList<QUrl> urls = speedTestUploadUrls();
        return urls.at(safeAttempt % urls.size());
    }
    return {};
}

QByteArray buildUploadPayload()
{
    QByteArray payload;
    payload.resize(4 * 1024 * 1024);
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
            *errorMessage = QStringLiteral("Local mixed proxy port is not reachable.");
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
            *errorMessage = QStringLiteral("Failed to write proxy CONNECT request.");
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

    const bool ok = firstLine.startsWith(QStringLiteral("HTTP/1.1 200"))
                    || firstLine.startsWith(QStringLiteral("HTTP/1.0 200"));

    if (!ok && errorMessage) {
        *errorMessage = firstLine.isEmpty()
        ? QStringLiteral("No proxy response for CONNECT test.")
        : QStringLiteral("CONNECT response: %1").arg(firstLine);
    }

    return ok;
}

QString quoteForShell(const QString& value)
{
    QString escaped = value;
    escaped.replace(QStringLiteral("'"), QStringLiteral("'\"'\"'"));
    return QStringLiteral("'") + escaped + QStringLiteral("'");
}

QString joinQuotedArgsForShell(const QStringList& args)
{
    QStringList quoted;
    quoted.reserve(args.size());
    for (const QString& arg : args) {
        quoted.append(quoteForShell(arg));
    }
    return quoted.join(QStringLiteral(" "));
}

QString quoteForPowerShellSingleQuoted(const QString& value)
{
    QString escaped = value;
    escaped.replace(QStringLiteral("'"), QStringLiteral("''"));
    return QStringLiteral("'") + escaped + QStringLiteral("'");
}

QString toPowerShellArgumentArrayLiteral(const QStringList& args)
{
    QStringList parts;
    parts.reserve(args.size());
    for (const QString& arg : args) {
        parts.append(quoteForPowerShellSingleQuoted(arg));
    }
    return QStringLiteral("@(") + parts.join(QStringLiteral(",")) + QStringLiteral(")");
}

QString escapeForAppleScriptString(const QString& value)
{
    QString out = value;
    out.replace(QStringLiteral("\\"), QStringLiteral("\\\\"));
    out.replace(QStringLiteral("\""), QStringLiteral("\\\""));
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

QString selectTunInterfaceName()
{
#if defined(Q_OS_MACOS)
    QProcess process;
    process.start(QStringLiteral("/sbin/ifconfig"), {QStringLiteral("-l")});
    if (!process.waitForStarted(1000)) {
        return QStringLiteral("utun9");
    }
    if (!process.waitForFinished(1500)) {
        process.kill();
        process.waitForFinished(200);
        return QStringLiteral("utun9");
    }
    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    static const QRegularExpression re(QStringLiteral("\\butun(\\d+)\\b"));
    QSet<int> used;
    QRegularExpressionMatchIterator it = re.globalMatch(output);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        used.insert(m.captured(1).toInt());
    }
    for (int n = 10; n <= 64; ++n) {
        if (!used.contains(n)) {
            return QStringLiteral("utun%1").arg(n);
        }
    }
    return QStringLiteral("utun9");
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
            *errorMessage = QStringLiteral("Cannot resolve xray directory for TUN runtime.");
        }
        return false;
    }

    const QString targetDll = QDir(xrayDir).filePath(QStringLiteral("wintun.dll"));
    if (QFileInfo::exists(targetDll)) {
        return true;
    }

    QStringList candidates;
    candidates << QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("wintun.dll"));
    candidates << QDir(dataDirectory).filePath(QStringLiteral("wintun.dll"));

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
        *errorMessage = QStringLiteral(
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
            QStringLiteral("api"),
            QStringLiteral("statsquery"),
            QStringLiteral("--server=127.0.0.1:%1").arg(apiPort),
            QStringLiteral("-pattern"),
            QStringLiteral("outbound>>>")
        }
        );

    if (!process.waitForStarted(1500)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to start xray api statsquery process.");
        }
        return false;
    }

    if (!process.waitForFinished(4500)) {
        process.kill();
        process.waitForFinished(500);
        if (errorMessage) {
            *errorMessage = QStringLiteral("xray api statsquery timed out.");
        }
        return false;
    }

    const QByteArray stdoutBytes = process.readAllStandardOutput();
    const QByteArray stderrBytes = process.readAllStandardError();

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        if (errorMessage) {
            const QString stderrText = QString::fromUtf8(stderrBytes).trimmed();
            *errorMessage = stderrText.isEmpty()
                                ? QStringLiteral("xray api statsquery failed.")
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
        const QJsonValue statValue = root.value(QStringLiteral("stat"));
        bool foundAnyCounter = false;

        auto consumeStatObject = [&up, &down, &foundAnyCounter](const QJsonObject &statObj) {
            const QString name = statObj.value(QStringLiteral("name")).toString();
            const qint64 value = statObj.value(QStringLiteral("value")).toVariant().toLongLong();
            if (!name.startsWith(QStringLiteral("outbound>>>"))) {
                return;
            }

            const QStringList parts = name.split(QStringLiteral(">>>"));
            if (parts.size() < 4) {
                return;
            }

            const QString outboundTag = parts.at(1);
            const QString direction = parts.at(3);
            if (outboundTag == QStringLiteral("api")) {
                return;
            }

            if (direction == QStringLiteral("uplink")) {
                up += value;
                foundAnyCounter = true;
            } else if (direction == QStringLiteral("downlink")) {
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
        QStringLiteral("outbound>>>([^>]+)>>>traffic>>>uplink[^0-9]*([0-9]+)"),
        QRegularExpression::CaseInsensitiveOption
        );
    static const QRegularExpression downRegex(
        QStringLiteral("outbound>>>([^>]+)>>>traffic>>>downlink[^0-9]*([0-9]+)"),
        QRegularExpression::CaseInsensitiveOption
        );

    bool foundAnyCounter = false;

    QRegularExpressionMatchIterator upIt = upRegex.globalMatch(plain);
    while (upIt.hasNext()) {
        const QRegularExpressionMatch match = upIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == QStringLiteral("api")) {
            continue;
        }
        up += match.captured(2).toLongLong();
        foundAnyCounter = true;
    }

    QRegularExpressionMatchIterator downIt = downRegex.globalMatch(plain);
    while (downIt.hasNext()) {
        const QRegularExpressionMatch match = downIt.next();
        const QString tag = match.captured(1).toLower();
        if (tag == QStringLiteral("api")) {
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
            snippet = snippet.left(200) + QStringLiteral("...");
        }
        *errorMessage = snippet.isEmpty()
                            ? QStringLiteral("xray api statsquery returned no traffic stats.")
                            : QStringLiteral("xray api statsquery parse failed: %1").arg(snippet);
    }
    return false;
}
}

VpnController::VpnController(QObject *parent)
    : QObject(parent)
{
    m_startedWithTunElevationRequest = QCoreApplication::arguments().contains(
        QStringLiteral("--geny-elevated-tun"));

    m_dataDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(m_dataDirectory);

    m_profilesPath = QDir(m_dataDirectory).filePath(QStringLiteral("profiles.json"));
    m_subscriptionsPath = QDir(m_dataDirectory).filePath(QStringLiteral("subscriptions.json"));
    m_runtimeConfigPath = QDir(m_dataDirectory).filePath(QStringLiteral("xray-runtime-config.json"));
    m_privilegedTunPidPath = QDir(m_dataDirectory).filePath(QStringLiteral("xray-tun.pid"));
    m_privilegedTunLogPath = QDir(m_dataDirectory).filePath(QStringLiteral("xray-tun.log"));

    m_buildOptions.socksPort = 10808;
    m_buildOptions.httpPort = 10808;
    m_buildOptions.apiPort = 10085;
    m_buildOptions.logLevel = QStringLiteral("warning");
    m_buildOptions.enableStatsApi = true;

    m_processManager.setWorkingDirectory(m_dataDirectory);
    m_statsPollTimer.setInterval(1000);
    connect(&m_statsPollTimer, &QTimer::timeout, this, &VpnController::pollTrafficStats);
    m_privilegedTunLogTimer.setInterval(200);
    connect(&m_privilegedTunLogTimer, &QTimer::timeout, this, &VpnController::pollPrivilegedTunLogs);
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

    loadSettings();
    loadProfiles();
    loadSubscriptions();
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
}

VpnController::~VpnController()
{
    cancelSpeedTest();
    if (m_privilegedTunManaged) {
        m_privilegedTunLogTimer.stop();
        QString stopError;
        Q_UNUSED(stopPrivilegedTunProcess(&stopError));
    }
    shutdownPrivilegedTunHelper();
    if (m_processManager.isRunning()) {
        m_processManager.stop(0);
    }
    if (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect) {
        applySystemProxy(false);
    }
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
    saveSettings();

    if (m_currentProfileIndex < 0) {
        m_pendingReconnectProfileIndex = -1;
        return;
    }

    if (connected() && !busy() && previousIndex >= 0 && previousIndex != m_currentProfileIndex) {
        m_pendingReconnectProfileIndex = m_currentProfileIndex;
        appendSystemLog(QStringLiteral("[System] Switching to selected profile..."));
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
        item.insert(QStringLiteral("id"), entry.id);
        item.insert(QStringLiteral("name"), entry.name);
        item.insert(QStringLiteral("group"), entry.group);
        item.insert(QStringLiteral("url"), entry.url);
        item.insert(QStringLiteral("profileCount"), profileCounter);
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
        item.insert(QStringLiteral("name"), options.name);
        item.insert(QStringLiteral("enabled"), options.enabled);
        item.insert(QStringLiteral("exclusive"), options.exclusive);
        item.insert(QStringLiteral("badge"), options.badge);
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
    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
        m_currentProfileGroup = QStringLiteral("All");
        emit currentProfileGroupChanged();
    }

    recomputeProfileStats();
}

void VpnController::setProfileGroupExclusive(const QString& groupName, bool exclusive)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
    appendSystemLog(QStringLiteral("[Group] Added group '%1'.").arg(normalized));
    return true;
}

bool VpnController::removeProfileGroup(const QString& groupName)
{
    const QString normalized = normalizeGroupName(groupName);
    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0
        || normalized.compare(QStringLiteral("General"), Qt::CaseInsensitive) == 0) {
        return false;
    }

    bool changed = false;

    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        if (normalizeGroupName(entry.group).compare(normalized, Qt::CaseInsensitive) == 0) {
            entry.group = QStringLiteral("General");
            changed = true;
        }
    }

    auto profiles = m_profileModel.profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        if (normalizeGroupName(profile.groupName).compare(normalized, Qt::CaseInsensitive) == 0) {
            profile.groupName = QStringLiteral("General");
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
    appendSystemLog(QStringLiteral("[Group] Removed group '%1' and moved profiles/subscriptions to General.")
                        .arg(normalized));
    return true;
}

int VpnController::removeAllProfileGroups()
{
    int removedGroups = 0;
    for (const QString& name : m_profileGroups) {
        if (name.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0
            || name.compare(QStringLiteral("General"), Qt::CaseInsensitive) == 0) {
            continue;
        }
        ++removedGroups;
    }

    bool changed = false;
    for (SubscriptionEntry& entry : m_subscriptionEntries) {
        const QString normalized = normalizeGroupName(entry.group);
        if (normalized.compare(QStringLiteral("General"), Qt::CaseInsensitive) != 0) {
            entry.group = QStringLiteral("General");
            changed = true;
        }
    }

    auto profiles = m_profileModel.profiles();
    bool profilesChanged = false;
    for (ServerProfile& profile : profiles) {
        const QString normalized = normalizeGroupName(profile.groupName);
        if (normalized.compare(QStringLiteral("General"), Qt::CaseInsensitive) != 0) {
            profile.groupName = QStringLiteral("General");
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
    appendSystemLog(QStringLiteral("[Group] Cleared all custom groups. Everything moved to General."));
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
        m_recentLogs.clear();
        m_latestLogLine.clear();
        m_logsDirty = false;
        m_logsFlushTimer.stop();
        emit latestLogLineChanged();
        emit logsChanged();
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
        normalized = QStringLiteral("All");
    }
    if (normalized.compare(QStringLiteral("all"), Qt::CaseInsensitive) == 0) {
        normalized = QStringLiteral("All");
    }

    if (normalized.compare(QStringLiteral("All"), Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalized)) {
        normalized = QStringLiteral("All");
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

void VpnController::setUseSystemProxy(bool enabled)
{
    if (m_useSystemProxy == enabled) {
        return;
    }

    m_useSystemProxy = enabled;
    emit useSystemProxyChanged();
    saveSettings();
    QSettings settings;
    settings.setValue(QStringLiteral("network/modeExplicitlyChosen"), true);

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
    settings.setValue(QStringLiteral("network/modeExplicitlyChosen"), true);
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

void VpnController::setBlockDomainRules(const QString& value)
{
    if (m_blockDomainRules == value) {
        return;
    }

    m_blockDomainRules = value;
    emit routingRulesChanged();
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
        profile.name = QStringLiteral("%1 %2")
        .arg(profile.protocol.toUpper(), profile.address);
    }
    profile.groupName = normalizeGroupName(m_currentProfileGroup);
    profile.sourceName = QStringLiteral("Manual import");
    profile.sourceId = QStringLiteral("manual");

    if (!m_profileModel.addProfile(profile)) {
        setLastError(QStringLiteral("Failed to add imported profile."));
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
        setLastError(QStringLiteral("No supported VMESS/VLESS links found in input."));
        return 0;
    }

    int lastImportedIndex = -1;
    const QString groupName = normalizeGroupName(m_currentProfileGroup);
    const int importCount = importLinks(
        links,
        QStringLiteral("manual"),
        QStringLiteral("Manual import"),
        groupName,
        &lastImportedIndex
        );

    if (importCount <= 0) {
        setLastError(QStringLiteral("No valid profiles were imported from input."));
        return 0;
    }

    saveProfiles();
    if (m_currentProfileIndex < 0 && lastImportedIndex >= 0) {
        setCurrentProfileIndex(lastImportedIndex);
    }
    if (m_autoPingProfiles) {
        pingAllProfiles();
    }

    appendSystemLog(QStringLiteral("[Import] Imported %1 profile(s).").arg(importCount));
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
    if (!parsedUrl.isValid() || (parsedUrl.scheme() != QStringLiteral("http") && parsedUrl.scheme() != QStringLiteral("https"))) {
        setLastError(QStringLiteral("Subscription URL must be a valid http(s) link."));
        return false;
    }

    if (m_subscriptionBusy) {
        setLastError(QStringLiteral("Another subscription operation is already running."));
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

    beginSubscriptionOperation(QStringLiteral("Fetching %1...").arg(entry.name));
    startSubscriptionFetch(entry, false);
    return true;
}

int VpnController::refreshSubscriptions()
{
    if (m_subscriptionBusy) {
        appendSystemLog(QStringLiteral("[Subscription] Another subscription operation is already running."));
        return 0;
    }

    if (m_subscriptionEntries.isEmpty()) {
        const QString message = QStringLiteral("No saved subscriptions.");
        appendSystemLog(QStringLiteral("[Subscription] %1").arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = m_subscriptionEntries;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(QStringLiteral("Refreshing subscriptions..."));
    startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
    return m_subscriptionEntries.size();
}

int VpnController::refreshSubscriptionsByGroup(const QString& group)
{
    if (m_subscriptionBusy) {
        appendSystemLog(QStringLiteral("[Subscription] Another subscription operation is already running."));
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
        const QString message = QStringLiteral("No subscriptions in group '%1'.").arg(normalizedGroup);
        appendSystemLog(QStringLiteral("[Subscription] %1").arg(message));
        m_subscriptionMessage = message;
        emit subscriptionStateChanged();
        return 0;
    }

    m_subscriptionRefreshQueue = filtered;
    m_subscriptionRefreshSuccessCount = 0;
    m_subscriptionRefreshFailCount = 0;
    beginSubscriptionOperation(QStringLiteral("Refreshing group '%1'...").arg(normalizedGroup));
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
                                             ? QStringLiteral("Manual import")
                                             : sourceName.trimmed();
    const QString normalizedSourceId = sourceId.trimmed().isEmpty()
                                           ? QStringLiteral("manual")
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
            profile.name = QStringLiteral("%1 %2")
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
            endSubscriptionOperation(QStringLiteral("Invalid subscription URL."));
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
                appendSystemLog(QStringLiteral("[Subscription] Imported %1 profile(s) from %2 (%3).")
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
                appendSystemLog(QStringLiteral("[Subscription] Refresh failed for %1 (%2): %3")
                                    .arg(entry.name, entry.group, hadError ? netError : QStringLiteral("no valid profiles")));
            }
            if (!m_subscriptionRefreshQueue.isEmpty()) {
                startSubscriptionFetch(m_subscriptionRefreshQueue.takeFirst(), true);
                return;
            }
            finishRefreshSubscriptions();
            return;
        }

        if (importedCount > 0) {
            endSubscriptionOperation(QStringLiteral("Imported %1 profile(s).").arg(importedCount));
            return;
        }

        const QString message = hadError
                                    ? (timedOut
                                           ? QStringLiteral("Subscription fetch timed out.")
                                           : (netError.isEmpty()
                                                  ? QStringLiteral("Failed to fetch subscription URL.")
                                                  : QStringLiteral("Subscription fetch failed: %1").arg(netError)))
                                    : QStringLiteral("Subscription payload has no supported VMESS/VLESS links.");
        appendSystemLog(QStringLiteral("[Subscription] %1 (%2): %3")
                            .arg(entry.name, entry.group, message));
        setLastError(message);
        endSubscriptionOperation(message);
    });
}

void VpnController::finishRefreshSubscriptions()
{
    const QString message = QStringLiteral("Refresh complete. Success: %1, failed: %2.")
    .arg(m_subscriptionRefreshSuccessCount)
        .arg(m_subscriptionRefreshFailCount);
    appendSystemLog(QStringLiteral("[Subscription] %1").arg(message));
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

    if (options.name.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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

    if (normalized.name.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
    groups.append(QStringLiteral("All"));

    QSet<QString> seen;
    seen.insert(QStringLiteral("all"));

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
        if (options.name.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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
    if (normalizedCurrent.isEmpty() || normalizedCurrent.compare(QStringLiteral("all"), Qt::CaseInsensitive) == 0) {
        normalizedCurrent = QStringLiteral("All");
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
        normalizedCurrent = QStringLiteral("All");
    }
    if (normalizedCurrent.compare(QStringLiteral("All"), Qt::CaseInsensitive) != 0
        && !isProfileGroupEnabled(normalizedCurrent)) {
        normalizedCurrent = QStringLiteral("All");
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
    const bool allGroups = (m_currentProfileGroup.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0);

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
    appendSystemLog(QStringLiteral("[Profile] Removed all profiles."));
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
    const bool allGroups = (m_currentProfileGroup.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0);

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

    // If runtime process is alive but UI state got out of sync, avoid spawning
    // another xray instance and force an explicit disconnect first.
    if (m_processManager.isRunning()) {
        setConnectionState(ConnectionState::Connected);
        appendSystemLog(QStringLiteral("[System] Xray is already running. Disconnect first before reconnecting."));
        return;
    }

    if (connected() && row == m_currentProfileIndex) {
        appendSystemLog(QStringLiteral("[System] Selected profile is already connected."));
        return;
    }

    auto profile = m_profileModel.profileAt(row);
    if (!profile.has_value()) {
        setLastError(QStringLiteral("Please select a valid server profile."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        setLastError(QStringLiteral("Set the xray-core executable path first."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    QFileInfo executableInfo(m_xrayExecutablePath);
    if (!executableInfo.exists()) {
        setLastError(QStringLiteral("xray-core binary not found at selected path."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    setCurrentProfileIndex(row);
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
            appendSystemLog(QStringLiteral("[System] %1").arg(runtimeError));
            setLastError(runtimeError);
            setConnectionState(ConnectionState::Error);
            return;
        }
        if (!copiedFrom.trimmed().isEmpty()) {
            appendSystemLog(QStringLiteral("[System] Copied wintun.dll for TUN runtime from: %1").arg(copiedFrom));
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
                    guard->m_privilegedTunLogTimer.start();
                    guard->setConnectionState(ConnectionState::Connected);
                    guard->setLastError(QString());
                    guard->appendSystemLog(QStringLiteral("[System] TUN mode active: system traffic should route through Xray TUN."));
                    guard->appendSystemLog(QStringLiteral("[System] Xray started (privileged TUN). Local proxy (mixed): 127.0.0.1:%1.")
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
                    guard->appendSystemLog(QStringLiteral("[System] %1").arg(elevateError));
                    guard->setLastError(elevateError);
                } else {
                    guard->setLastError(QStringLiteral("Failed to start privileged TUN runtime."));
                }
                guard->setConnectionState(ConnectionState::Error);
            }, Qt::QueuedConnection);
        });
        return;
    }

    m_processManager.setExecutablePath(m_xrayExecutablePath);
    m_rxBytes = 0;
    m_txBytes = 0;
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
                    guard->appendSystemLog(QStringLiteral("[System] %1").arg(stopError));
                }
                guard->setConnectionState(ConnectionState::Disconnected);
                const int reconnectIndex = guard->m_pendingReconnectProfileIndex;
                guard->m_pendingReconnectProfileIndex = -1;
                if (reconnectIndex >= 0) {
                    QTimer::singleShot(0, guard.data(), [guard, reconnectIndex]() {
                        if (guard) {
                            guard->connectToProfile(reconnectIndex);
                        }
                    });
                }
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

void VpnController::setXrayExecutableFromUrl(const QUrl& url)
{
    setXrayExecutablePath(url.toLocalFile());
}

void VpnController::startSpeedTestRequest(const QUrl& url, bool upload, const QByteArray& payload)
{
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-SpeedTest/1.0");
    request.setRawHeader("Accept", "*/*");
    request.setTransferTimeout(12000);
    if (upload) {
        request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/octet-stream"));
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
        finishSpeedTest(false, QStringLiteral("Invalid speed test endpoint."));
        return;
    }

    const bool upload = (m_speedTestPhase == QStringLiteral("Upload"));
    const QByteArray payload = upload ? buildUploadPayload() : QByteArray();
    ++m_speedTestAttempt;
    startSpeedTestRequest(url, upload, payload);
}

void VpnController::startPingPhase()
{
    m_speedTestPhase = QStringLiteral("Ping");
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
    m_speedTestPhase = QStringLiteral("Download");
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
    m_speedTestPhase = QStringLiteral("Upload");
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
    m_speedTestPhase = ok ? QStringLiteral("Done") : QStringLiteral("Error");
    m_speedTestError = ok ? QString() : error;
    m_speedTestPhaseTimer.invalidate();
    m_speedTestSampleTimer.invalidate();
    emit speedTestChanged();

    if (ok) {
        const QString resultLine = QStringLiteral("Done: ping %1 ms, down %2 Mbps, up %3 Mbps")
        .arg(m_speedTestPingMs)
            .arg(QString::number(m_speedTestDownloadMbps, 'f', 1))
            .arg(QString::number(m_speedTestUploadMbps, 'f', 1));
        m_speedTestHistory.prepend(resultLine);
        while (m_speedTestHistory.size() > kSpeedTestHistoryMaxItems) {
            m_speedTestHistory.removeLast();
        }
        appendSystemLog(QStringLiteral("[SpeedTest] %1").arg(resultLine));
    } else {
        appendSystemLog(QStringLiteral("[SpeedTest] Failed: %1").arg(error));
    }
    emit speedTestChanged();
}

void VpnController::startSpeedTest()
{
    if (busy() && !connected()) {
        appendSystemLog(QStringLiteral("[SpeedTest] Wait for current connection attempt to finish."));
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
            QNetworkProxy(QNetworkProxy::Socks5Proxy, QStringLiteral("127.0.0.1"), m_buildOptions.socksPort));
        appendSystemLog(QStringLiteral("[SpeedTest] Started via VPN tunnel (SOCKS5 127.0.0.1:%1).")
                            .arg(m_buildOptions.socksPort));
    } else {
        m_speedTestNetworkManager.setProxy(QNetworkProxy::NoProxy);
        appendSystemLog(QStringLiteral("[SpeedTest] Started via direct internet (no VPN proxy)."));
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
        m_speedTestPhase = QStringLiteral("Idle");
        m_speedTestPhaseTimer.invalidate();
        m_speedTestSampleTimer.invalidate();
        emit speedTestChanged();
        appendSystemLog(QStringLiteral("[SpeedTest] Canceled."));
    }
}

QString VpnController::formatBytes(qint64 bytes) const
{
    static const QStringList units {QStringLiteral("B"), QStringLiteral("KB"), QStringLiteral("MB"), QStringLiteral("GB"), QStringLiteral("TB")};

    double value = static_cast<double>(bytes);
    int unitIndex = 0;

    while (value >= 1024.0 && unitIndex < units.size() - 1) {
        value /= 1024.0;
        ++unitIndex;
    }

    return QStringLiteral("%1 %2")
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

    QString subtitle = QStringLiteral("%1  %2:%3")
                           .arg(profile->protocol.toUpper(), profile->address, QString::number(profile->port));
    if (!profile->security.trimmed().isEmpty()) {
        subtitle += QStringLiteral("  |  %1").arg(profile->security.trimmed());
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
    setConnectionState(ConnectionState::Connected);
    if (m_tunMode) {
        appendSystemLog(QStringLiteral("[System] TUN mode active: system traffic should route through Xray TUN."));
    } else if (m_useSystemProxy) {
        applySystemProxy(true);
    } else {
        appendSystemLog(QStringLiteral(
                            "[System] Clean mode active: system proxy stays disabled (only apps configured to 127.0.0.1:%1 use the tunnel).")
                            .arg(m_buildOptions.socksPort));
    }

    appendSystemLog(QStringLiteral("[System] Xray started. Local proxy (mixed): 127.0.0.1:%1.")
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
    if (m_useSystemProxy && m_autoDisableSystemProxyOnDisconnect) {
        applySystemProxy(false);
    }

    if (m_stoppingProcess) {
        m_stoppingProcess = false;
        setLastError(QString());
        setConnectionState(ConnectionState::Disconnected);
        const int reconnectIndex = m_pendingReconnectProfileIndex;
        m_pendingReconnectProfileIndex = -1;
        if (reconnectIndex >= 0) {
            QTimer::singleShot(0, this, [this, reconnectIndex]() {
                connectToProfile(reconnectIndex);
            });
        }
        return;
    }

    if (exitStatus == QProcess::CrashExit) {
        setLastError(QStringLiteral("xray-core terminated unexpectedly."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_connectionState != ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }
    m_pendingReconnectProfileIndex = -1;
}

void VpnController::onProcessError(const QString& error)
{
    if (m_stoppingProcess) {
        return;
    }

    m_statsPollTimer.stop();
    cancelSpeedTest();
    setLastError(QStringLiteral("xray-core error: %1").arg(error));
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
    if (line.contains(QStringLiteral("[api-in -> api]"))) {
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
                            QStringLiteral("[System] Traffic stats unavailable: %1").arg(error.trimmed()));
                    }
                    return;
                }
                guard->m_statsQueryFailureCount = 0;

                if (guard->m_txBytes != uplinkBytes || guard->m_rxBytes != downlinkBytes) {
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

    if (m_speedTestPhase == QStringLiteral("Ping")) {
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

    if (m_speedTestPhase == QStringLiteral("Download")) {
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

    if (m_speedTestPhase == QStringLiteral("Upload")) {
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

    if (phaseAtFinish == QStringLiteral("Ping")) {
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
                finishSpeedTest(false, replyHadError ? errorText : QStringLiteral("Ping requests failed."));
            }
            return;
        }
        startCurrentSpeedTestRequest();
        return;
    }

    if (phaseAtFinish == QStringLiteral("Download")) {
        if (m_speedTestPhaseTimer.isValid()
            && m_speedTestPhaseTimer.elapsed() >= static_cast<qint64>(m_speedTestDurationSec) * 1000) {
            return;
        }

        if (m_speedTestPhaseBytes <= 0 && m_speedTestAttempt >= kSpeedTestMaxAttemptsPerPhase) {
            finishSpeedTest(
                false,
                replyHadError ? errorText : QStringLiteral("Download test returned no data."));
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

    if (phaseAtFinish == QStringLiteral("Upload")) {
        if (m_speedTestPhaseTimer.isValid()
            && m_speedTestPhaseTimer.elapsed() >= static_cast<qint64>(m_speedTestDurationSec) * 1000) {
            return;
        }

        if (m_speedTestPhaseBytes <= 0 && m_speedTestAttempt >= kSpeedTestMaxAttemptsPerPhase) {
            finishSpeedTest(
                false,
                replyHadError ? errorText : QStringLiteral("Upload test returned no data."));
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

void VpnController::setConnectionState(ConnectionState state)
{
    if (m_connectionState == state) {
        return;
    }

    m_connectionState = state;
    emit connectionStateChanged();
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
    m_speedTestPhase = QStringLiteral("Idle");
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
    if (!connected()) {
        return;
    }
    const quint16 socksPort = m_buildOptions.socksPort;
    const bool useSystemProxyMode = m_useSystemProxy;
    const bool tunMode = m_tunMode;
    const QPointer<VpnController> guard(this);

    [[maybe_unused]] auto proxySelfCheckFuture = QtConcurrent::run([guard, socksPort, useSystemProxyMode, tunMode]() {
        QString error;
        const bool ok = checkLocalProxyConnectivitySync(socksPort, &error);
        if (!guard) {
            return;
        }

        QMetaObject::invokeMethod(guard.data(), [guard, socksPort, useSystemProxyMode, tunMode, ok, error]() {
            if (!guard || !guard->connected()) {
                return;
            }

            if (ok) {
                guard->appendSystemLog(QStringLiteral("[System] Proxy self-test passed (127.0.0.1:%1 is forwarding traffic).")
                                           .arg(socksPort));
                if (!useSystemProxyMode && !tunMode) {
                    guard->appendSystemLog(QStringLiteral("[System] Clean mode note: macOS system traffic is NOT auto-routed in this mode."));
                }
                return;
            }

            guard->appendSystemLog(QStringLiteral("[System] Proxy self-test failed: %1").arg(error));
            if (useSystemProxyMode) {
                guard->appendSystemLog(QStringLiteral("[System] Hint: verify system proxy state and retry with proper permissions."));
            } else {
                guard->appendSystemLog(QStringLiteral("[System] Hint: Clean mode requires apps to use 127.0.0.1:%1 manually.")
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
    m_xrayVersion = QStringLiteral("Unknown");

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        m_xrayVersion = QStringLiteral("Not detected");
        if (previousVersion != m_xrayVersion) {
            emit xrayVersionChanged();
        }
        if (previous != m_processRoutingSupported) {
            emit processRoutingSupportChanged();
        }
        return m_processRoutingSupported;
    }

    QProcess process;
    process.start(m_xrayExecutablePath, {QStringLiteral("version")});
    if (!process.waitForStarted(2000)) {
        m_xrayVersion = QStringLiteral("Unavailable");
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
        m_xrayVersion = QStringLiteral("Unavailable");
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

    const QRegularExpression regex(QStringLiteral("Xray\\s+(\\d+)\\.(\\d+)\\.(\\d+)"));
    const QRegularExpressionMatch match = regex.match(output);
    if (match.hasMatch()) {
        m_xrayVersion = QStringLiteral("%1.%2.%3")
        .arg(match.captured(1), match.captured(2), match.captured(3));
        const int major = match.captured(1).toInt();
        const int minor = match.captured(2).toInt();
        const int patch = match.captured(3).toInt();

        m_processRoutingSupported =
            major > 26
            || (major == 26 && minor > 1)
            || (major == 26 && minor == 1 && patch >= 23);
    } else if (process.exitCode() == 0) {
        m_xrayVersion = QStringLiteral("Detected");
    } else {
        m_xrayVersion = QStringLiteral("Unavailable");
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
    const QStringList raw = normalized.split(QRegularExpression(QStringLiteral("[,;\\n\\r]+")), Qt::SkipEmptyParts);

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

void VpnController::applySystemProxy(bool enable, bool force)
{
    if (!m_useSystemProxy && enable) {
        return;
    }

    const bool wasEnabled = m_systemProxyManager.isEnabled();
    if (!force && wasEnabled == enable) {
        return;
    }

    QString error;
    const bool ok = enable
                        ? m_systemProxyManager.enable(m_buildOptions.socksPort, m_buildOptions.httpPort, &error)
                        : m_systemProxyManager.disable(&error, force);

    if (ok) {
        const bool nowEnabled = m_systemProxyManager.isEnabled();
        if (enable && (!wasEnabled || force)) {
            appendSystemLog(QStringLiteral("[System] System proxy enabled."));
        } else if (!enable && wasEnabled && !nowEnabled) {
            appendSystemLog(QStringLiteral("[System] System proxy disabled."));
        }
        return;
    }

    if (error.isEmpty()) {
        return;
    }

    const QString message = enable
                                ? QStringLiteral("Connected, but failed to enable system proxy: %1").arg(error)
                                : QStringLiteral("Failed to disable system proxy: %1").arg(error);

    appendSystemLog(QStringLiteral("[System] %1").arg(message));

    if (enable) {
        setLastError(message);
    } else {
        setLastError(QString());
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
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("GenyConnectTunHelper.exe"));
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("GenyConnectTunHelper"));
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
            *errorMessage = QStringLiteral("Privileged helper is not initialized.");
        }
        return false;
    }

    QJsonObject payload = request;
    payload.insert(QStringLiteral("token"), m_privilegedTunHelperToken);

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
            *errorMessage = QStringLiteral("Could not connect to privileged helper.");
        }
        return false;
    }

    const QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact) + '\n';
    if (socket.write(body) < 0) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to send request to privileged helper.");
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
            *errorMessage = QStringLiteral("Failed to send request to privileged helper.");
        }
        return false;
    }

    QByteArray replyBuffer;
    QElapsedTimer timer;
    timer.start();
    while (!replyBuffer.contains('\n') && timer.elapsed() < safeTimeoutMs) {
        if (socket.bytesAvailable() <= 0) {
            socket.waitForReadyRead(40);
            QCoreApplication::processEvents(QEventLoop::AllEvents, 10);
            if (socket.bytesAvailable() <= 0) {
                continue;
            }
        }
        replyBuffer.append(socket.readAll());
    }

    const int nl = replyBuffer.indexOf('\n');
    const QByteArray replyLine = (nl >= 0 ? replyBuffer.left(nl) : replyBuffer).trimmed();
    if (replyLine.isEmpty()) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Privileged helper returned an empty response.");
        }
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument replyDoc = QJsonDocument::fromJson(replyLine, &parseError);
    if (parseError.error != QJsonParseError::NoError || !replyDoc.isObject()) {
        m_privilegedTunHelperReady = false;
        if (errorMessage) {
            *errorMessage = QStringLiteral("Privileged helper returned invalid JSON.");
        }
        return false;
    }

    if (response) {
        *response = replyDoc.object();
    }
    return true;
}

bool VpnController::ensurePrivilegedTunHelper(QString *errorMessage)
{
    auto helperResponding = [this]() -> bool {
        QJsonObject response;
        QString pingError;
        if (!sendPrivilegedTunHelperRequest(QJsonObject{{QStringLiteral("action"), QStringLiteral("ping")}},
                                            &response,
                                            &pingError,
                                            2500)) {
            return false;
        }
        return response.value(QStringLiteral("ok")).toBool(false);
    };

    if (m_privilegedTunHelperReady && helperResponding()) {
        return true;
    }

    const QString helperPath = privilegedTunHelperPath();
    if (helperPath.trimmed().isEmpty() || !QFileInfo::exists(helperPath)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Privileged helper executable not found: %1").arg(helperPath);
        }
        return false;
    }

    const QString tokenPartA = QString::number(QRandomGenerator::global()->generate64(), 16);
    const QString tokenPartB = QString::number(QRandomGenerator::global()->generate64(), 16);
    m_privilegedTunHelperToken = tokenPartA + tokenPartB;
    m_privilegedTunHelperReady = false;

    QString launchError;
    bool started = false;
    for (int attempt = 0; attempt < 8 && !started; ++attempt) {
        m_privilegedTunHelperPort = static_cast<quint16>(39000 + QRandomGenerator::global()->bounded(20000));
        const QStringList launchArgs = {
            QStringLiteral("--listen-port"), QString::number(m_privilegedTunHelperPort),
            QStringLiteral("--token"), m_privilegedTunHelperToken,
            QStringLiteral("--idle-timeout-ms"), QStringLiteral("1800000")
        };

#if defined(Q_OS_MACOS)
        const QString command = quoteForShell(helperPath)
                                + QStringLiteral(" ")
                                + joinQuotedArgsForShell(launchArgs)
                                + QStringLiteral(" >/dev/null 2>&1 &");
        const QString script = QStringLiteral("do shell script \"%1\" with administrator privileges")
                                   .arg(escapeForAppleScriptString(command));
        QProcess process;
        process.start(QStringLiteral("/usr/bin/osascript"), {QStringLiteral("-e"), script});
        if (!process.waitForStarted(5000)) {
            launchError = QStringLiteral("Failed to open macOS elevation prompt for TUN helper.");
            continue;
        }
        if (!waitForProcessFinishedResponsive(process, 60000)) {
            process.kill();
            waitForProcessFinishedResponsive(process, 1000);
            launchError = QStringLiteral("macOS elevation prompt timed out for TUN helper.");
            continue;
        }
        if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
            const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
            launchError = stderrText.isEmpty()
                              ? QStringLiteral("macOS elevation for TUN helper was canceled.")
                              : QStringLiteral("macOS elevation for TUN helper failed: %1").arg(stderrText);
            continue;
        }
        started = true;
#elif defined(Q_OS_WIN)
        const QString psArgArray = toPowerShellArgumentArrayLiteral(launchArgs);
        const QString command = QStringLiteral(
                                    "Start-Process -Verb RunAs -WindowStyle Hidden -FilePath %1 -ArgumentList %2")
                                    .arg(quoteForPowerShellSingleQuoted(helperPath), psArgArray);
        if (!QProcess::startDetached(
                QStringLiteral("powershell"),
                {QStringLiteral("-NoProfile"), QStringLiteral("-ExecutionPolicy"), QStringLiteral("Bypass"),
                 QStringLiteral("-Command"), command})) {
            launchError = QStringLiteral("Failed to request Windows UAC for TUN helper.");
            continue;
        }
        started = true;
#elif defined(Q_OS_LINUX)
        if (QStandardPaths::findExecutable(QStringLiteral("pkexec")).isEmpty()) {
            launchError = QStringLiteral("pkexec is required for TUN helper on Linux.");
            continue;
        }
        QStringList pkexecArgs;
        pkexecArgs << helperPath;
        pkexecArgs << launchArgs;
        if (!QProcess::startDetached(QStringLiteral("pkexec"), pkexecArgs)) {
            launchError = QStringLiteral("Failed to request elevation for Linux TUN helper.");
            continue;
        }
        started = true;
#else
        launchError = QStringLiteral("Privileged TUN helper is not implemented on this platform.");
        Q_UNUSED(launchArgs)
#endif
    }

    if (!started) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = launchError.isEmpty()
            ? QStringLiteral("Failed to launch privileged TUN helper.")
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
        if (sendPrivilegedTunHelperRequest(QJsonObject{{QStringLiteral("action"), QStringLiteral("ping")}},
                                           &response,
                                           &lastPingError,
                                           2500)
            && response.value(QStringLiteral("ok")).toBool(false)) {
            ready = true;
            break;
        }
    }

    if (!ready) {
        m_privilegedTunHelperPort = 0;
        m_privilegedTunHelperToken.clear();
        if (errorMessage) {
            *errorMessage = lastPingError.isEmpty()
            ? QStringLiteral("Timed out waiting for privileged TUN helper to start.")
            : QStringLiteral("Privileged TUN helper did not respond: %1").arg(lastPingError);
        }
        return false;
    }

    m_privilegedTunHelperReady = true;
    return true;
}

void VpnController::shutdownPrivilegedTunHelper()
{
    if (!m_privilegedTunHelperReady) {
        return;
    }
    QString ignoredError;
    QJsonObject ignoredResponse;
    Q_UNUSED(sendPrivilegedTunHelperRequest(
        QJsonObject{{QStringLiteral("action"), QStringLiteral("shutdown")}},
        &ignoredResponse,
        &ignoredError,
        2000));
    m_privilegedTunHelperReady = false;
    m_privilegedTunHelperPort = 0;
    m_privilegedTunHelperToken.clear();
}

bool VpnController::requestElevationForTun(QString *errorMessage)
{
    const QString executablePath = QCoreApplication::applicationFilePath();
    if (executablePath.trimmed().isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Cannot relaunch with elevation: executable path is empty.");
        }
        return false;
    }

    QStringList args = QCoreApplication::arguments();
    if (!args.isEmpty()) {
        args.removeFirst();
    }
    if (!args.contains(QStringLiteral("--geny-elevated-tun"))) {
        args.append(QStringLiteral("--geny-elevated-tun"));
    }

#if defined(Q_OS_MACOS)
    const QString command = quoteForShell(executablePath)
                            + QStringLiteral(" ")
                            + joinQuotedArgsForShell(args)
                            + QStringLiteral(" >/dev/null 2>&1 &");
    const QString script = QStringLiteral("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(QStringLiteral("/usr/bin/osascript"), {QStringLiteral("-e"), script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to start macOS elevation prompt.");
        }
        return false;
    }
    if (!waitForProcessFinishedResponsive(process, 60000)) {
        process.kill();
        waitForProcessFinishedResponsive(process, 1000);
        if (errorMessage) {
            *errorMessage = QStringLiteral("macOS elevation prompt timed out.");
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? QStringLiteral("macOS elevation request was canceled or failed.")
            : QStringLiteral("macOS elevation failed: %1").arg(stderrText);
        }
        return false;
    }
    return true;
#elif defined(Q_OS_WIN)
    const QString argClause = args.isEmpty()
                                  ? QString()
                                  : QStringLiteral(" -ArgumentList %1").arg(toPowerShellArgumentArrayLiteral(args));
    const QString command =
        QStringLiteral("Start-Process -Verb RunAs -FilePath %1%2")
            .arg(quoteForPowerShellSingleQuoted(executablePath), argClause);
    if (!QProcess::startDetached(
            QStringLiteral("powershell"),
            {QStringLiteral("-NoProfile"), QStringLiteral("-ExecutionPolicy"), QStringLiteral("Bypass"),
             QStringLiteral("-Command"), command})) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to request Windows UAC elevation.");
        }
        return false;
    }
    return true;
#elif defined(Q_OS_LINUX)
    if (QStandardPaths::findExecutable(QStringLiteral("pkexec")).isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral(
                "pkexec is not available. Install polkit tools or run GenyConnect as root for TUN mode.");
        }
        return false;
    }

    QStringList launchArgs;
    launchArgs << executablePath;
    launchArgs << args;
    if (!QProcess::startDetached(QStringLiteral("pkexec"), launchArgs)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to request Linux elevation (pkexec).");
        }
        return false;
    }
    return true;
#else
    if (errorMessage) {
        *errorMessage = QStringLiteral("TUN elevation flow is not implemented on this platform.");
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
            *errorMessage = QStringLiteral("TUN start failed: missing interface name.");
        }
        return false;
    }
#endif

    QJsonObject response;
    QString helperError;
    if (!sendPrivilegedTunHelperRequest(
            QJsonObject{
                {QStringLiteral("action"), QStringLiteral("start_tun")},
                {QStringLiteral("xray_path"), m_xrayExecutablePath},
                {QStringLiteral("config_path"), m_runtimeConfigPath},
                {QStringLiteral("pid_path"), m_privilegedTunPidPath},
                {QStringLiteral("log_path"), m_privilegedTunLogPath},
                {QStringLiteral("tun_if"), tunIf},
                {QStringLiteral("server_ip"), m_lastTunServerIp},
                {QStringLiteral("server_host"), m_activeProfileAddress.trimmed()}
            },
            &response,
            &helperError,
            25000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? QStringLiteral("Privileged helper failed to start TUN runtime.")
            : helperError;
        }
        return false;
    }

    if (!response.value(QStringLiteral("ok")).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(QStringLiteral("message")).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = QStringLiteral("Privileged helper rejected TUN start.");
            }
        }
        return false;
    }

    QFile pidFile(m_privilegedTunPidPath);
    if (!pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("TUN start failed: pid file was not created.");
        }
        return false;
    }
    const QString pidText = QString::fromUtf8(pidFile.readAll()).trimmed();
    pidFile.close();
    if (pidText.isEmpty()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("TUN start failed: invalid process id.");
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
                {QStringLiteral("action"), QStringLiteral("stop_tun")},
                {QStringLiteral("pid_path"), m_privilegedTunPidPath},
                {QStringLiteral("tun_if"), m_selectedTunInterfaceName.trimmed()},
                {QStringLiteral("server_ip"), m_lastTunServerIp.trimmed()}
            },
            &response,
            &helperError,
            10000)) {
        if (errorMessage) {
            *errorMessage = helperError.isEmpty()
            ? QStringLiteral("Privileged helper failed to stop TUN runtime.")
            : helperError;
        }
        return false;
    }

    if (!response.value(QStringLiteral("ok")).toBool(false)) {
        if (errorMessage) {
            *errorMessage = response.value(QStringLiteral("message")).toString().trimmed();
            if (errorMessage->isEmpty()) {
                *errorMessage = QStringLiteral("Privileged helper rejected TUN stop.");
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
        appendSystemLog(QStringLiteral("[System] Log stream is very busy. Older lines were trimmed to keep UI responsive."));
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
            *errorMessage = QStringLiteral("TUN route setup failed: missing interface name.");
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
            QStringLiteral("GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}'); "
                           "if [ -n \"$GW\" ]; then route -n add -host %1 \"$GW\" >/dev/null 2>&1 || true; fi;")
                .arg(serverIp);
    } else {
        m_lastTunServerIp.clear();
    }

    const QString command =
        hostRouteCmd
        + QStringLiteral("route -n add -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                         "route -n add -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
              .arg(tunIf);

    const QString script = QStringLiteral("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess process;
    process.start(QStringLiteral("/usr/bin/osascript"), {QStringLiteral("-e"), script});
    if (!process.waitForStarted(5000)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to request permissions for TUN route setup.");
        }
        return false;
    }
    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished(1000);
        if (errorMessage) {
            *errorMessage = QStringLiteral("Timed out while applying TUN routes.");
        }
        return false;
    }
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        const QString stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (errorMessage) {
            *errorMessage = stderrText.isEmpty()
            ? QStringLiteral("Failed to apply macOS TUN routes.")
            : QStringLiteral("Failed to apply macOS TUN routes: %1").arg(stderrText);
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
                                   : QStringLiteral("route -n delete -host %1 >/dev/null 2>&1 || true;").arg(m_lastTunServerIp.trimmed());
    const QString command =
        hostDelete
        + QStringLiteral("route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                         "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
              .arg(tunIf);
    const QString script = QStringLiteral("do shell script \"%1\" with administrator privileges")
                               .arg(escapeForAppleScriptString(command));
    QProcess::execute(QStringLiteral("/usr/bin/osascript"), {QStringLiteral("-e"), script});
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
        appendSystemLog(QStringLiteral(
            "[System] App rules ignored: current xray-core does not support process routing (requires Xray 26.1.23+)."
            ));
    }

    const QJsonObject config = XrayConfigBuilder::build(profile, options);

    if (m_tunMode && !options.tunInterfaceName.trimmed().isEmpty()) {
        appendSystemLog(QStringLiteral("[System] TUN interface selected: %1").arg(options.tunInterfaceName));
    }

    QSaveFile file(m_runtimeConfigPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to open config file: %1").arg(m_runtimeConfigPath);
        }
        return false;
    }

    const QJsonDocument doc(config);
    file.write(doc.toJson(QJsonDocument::Indented));

    if (!file.commit()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Failed to write config file to disk.");
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
    candidates << QDir(appDir).filePath(QStringLiteral("xray-core.exe"));
    candidates << QDir(appDir).filePath(QStringLiteral("xray.exe"));
#else
    candidates << QDir(appDir).filePath(QStringLiteral("xray-core"));
    candidates << QDir(appDir).filePath(QStringLiteral("xray"));
#endif

    for (const QString& path : std::as_const(candidates)) {
        QFileInfo info(path);
        if (info.exists() && info.isFile()) {
            return path;
        }
    }

    const QStringList executableCandidates {
#ifdef Q_OS_WIN
        QStringLiteral("xray-core.exe"),
        QStringLiteral("xray.exe"),
#else
        QStringLiteral("xray-core"),
        QStringLiteral("xray"),
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
                normalized.sourceName = QStringLiteral("Manual import");
            }
            if (normalized.sourceId.trimmed().isEmpty()) {
                normalized.sourceId = QStringLiteral("manual");
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
            entry.id = obj.value(QStringLiteral("id")).toString().trimmed();
            entry.url = obj.value(QStringLiteral("url")).toString().trimmed();
            entry.name = obj.value(QStringLiteral("name")).toString().trimmed();
            entry.group = obj.value(QStringLiteral("group")).toString().trimmed();
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
            || (parsedUrl.scheme() != QStringLiteral("http") && parsedUrl.scheme() != QStringLiteral("https"))) {
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
        obj[QStringLiteral("id")] = entry.id;
        obj[QStringLiteral("name")] = entry.name;
        obj[QStringLiteral("group")] = entry.group;
        obj[QStringLiteral("url")] = entry.url;
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
    m_xrayExecutablePath = settings.value(QStringLiteral("xray/executablePath")).toString().trimmed();
    m_loggingEnabled = settings.value(QStringLiteral("logs/enabled"), true).toBool();
    m_autoPingProfiles = settings.value(QStringLiteral("profiles/autoPing"), true).toBool();
    m_currentProfileIndex = settings.value(QStringLiteral("profiles/currentIndex"), -1).toInt();
    m_currentProfileId = settings.value(QStringLiteral("profiles/currentId")).toString().trimmed();

    m_profileGroupOptions.clear();
    const QString rawGroupOptions = settings.value(QStringLiteral("profiles/groupOptionsJson")).toString().trimmed();
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
                options.name = normalizeGroupName(obj.value(QStringLiteral("name")).toString());
                options.key = normalizeGroupKey(options.name);
                options.enabled = obj.value(QStringLiteral("enabled")).toBool(true);
                options.exclusive = obj.value(QStringLiteral("exclusive")).toBool(false);
                options.badge = obj.value(QStringLiteral("badge")).toString().trimmed();

                if (options.name.compare(QStringLiteral("All"), Qt::CaseInsensitive) == 0) {
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

    m_currentProfileGroup = settings.value(QStringLiteral("profiles/currentGroup"), QStringLiteral("All")).toString().trimmed();
    if (m_currentProfileGroup.isEmpty()) {
        m_currentProfileGroup = QStringLiteral("All");
    }
    const bool modeExplicitlyChosen = settings.value(
                                                  QStringLiteral("network/modeExplicitlyChosen"), false).toBool();
    m_tunMode = modeExplicitlyChosen
                    ? settings.value(QStringLiteral("network/tunMode"), false).toBool()
                    : true;
    m_useSystemProxy = modeExplicitlyChosen
                           ? settings.value(QStringLiteral("network/useSystemProxy"), false).toBool()
                           : false;
    if (m_tunMode) {
        m_useSystemProxy = false;
    }
    if (settings.contains(QStringLiteral("network/autoDisableSystemProxyOnDisconnect"))) {
        m_autoDisableSystemProxyOnDisconnect =
            settings.value(QStringLiteral("network/autoDisableSystemProxyOnDisconnect")).toBool();
    } else {
        m_autoDisableSystemProxyOnDisconnect = false;
    }
    m_whitelistMode = settings.value(QStringLiteral("routing/whitelistMode"), false).toBool();
    m_proxyDomainRules = settings.value(QStringLiteral("routing/proxyDomains")).toString();
    m_directDomainRules = settings.value(QStringLiteral("routing/directDomains")).toString();
    m_blockDomainRules = settings.value(QStringLiteral("routing/blockDomains")).toString();
    m_proxyAppRules = settings.value(QStringLiteral("routing/proxyApps")).toString();
    m_directAppRules = settings.value(QStringLiteral("routing/directApps")).toString();
    m_blockAppRules = settings.value(QStringLiteral("routing/blockApps")).toString();
}

void VpnController::saveSettings() const
{
    QSettings settings;
    settings.setValue(QStringLiteral("xray/executablePath"), m_xrayExecutablePath);
    settings.setValue(QStringLiteral("logs/enabled"), m_loggingEnabled);
    settings.setValue(QStringLiteral("profiles/autoPing"), m_autoPingProfiles);
    settings.setValue(QStringLiteral("profiles/currentIndex"), m_currentProfileIndex);
    settings.setValue(QStringLiteral("profiles/currentId"), m_currentProfileId);
    settings.setValue(QStringLiteral("profiles/currentGroup"), m_currentProfileGroup);

    QJsonArray groupOptionsArray;
    for (const ProfileGroupOptions& options : m_profileGroupOptions) {
        QJsonObject obj;
        obj[QStringLiteral("name")] = options.name;
        obj[QStringLiteral("enabled")] = options.enabled;
        obj[QStringLiteral("exclusive")] = options.exclusive;
        obj[QStringLiteral("badge")] = options.badge;
        groupOptionsArray.append(obj);
    }
    settings.setValue(
        QStringLiteral("profiles/groupOptionsJson"),
        QString::fromUtf8(QJsonDocument(groupOptionsArray).toJson(QJsonDocument::Compact))
        );

    settings.setValue(QStringLiteral("network/useSystemProxy"), m_useSystemProxy);
    settings.setValue(QStringLiteral("network/tunMode"), m_tunMode);
    settings.setValue(
        QStringLiteral("network/autoDisableSystemProxyOnDisconnect"),
        m_autoDisableSystemProxyOnDisconnect
        );
    settings.setValue(QStringLiteral("routing/whitelistMode"), m_whitelistMode);
    settings.setValue(QStringLiteral("routing/proxyDomains"), m_proxyDomainRules);
    settings.setValue(QStringLiteral("routing/directDomains"), m_directDomainRules);
    settings.setValue(QStringLiteral("routing/blockDomains"), m_blockDomainRules);
    settings.setValue(QStringLiteral("routing/proxyApps"), m_proxyAppRules);
    settings.setValue(QStringLiteral("routing/directApps"), m_directAppRules);
    settings.setValue(QStringLiteral("routing/blockApps"), m_blockAppRules);
}

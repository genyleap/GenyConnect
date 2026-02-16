module;
#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSettings>
#include <QSet>
#include <QStandardPaths>
#include <QTcpSocket>
#include <QNetworkProxy>

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
}

VpnController::VpnController(QObject *parent)
    : QObject(parent)
{
    m_dataDirectory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(m_dataDirectory);

    m_profilesPath = QDir(m_dataDirectory).filePath(QStringLiteral("profiles.json"));
    m_runtimeConfigPath = QDir(m_dataDirectory).filePath(QStringLiteral("xray-runtime-config.json"));

    m_buildOptions.socksPort = 10808;
    m_buildOptions.httpPort = 10808;
    m_buildOptions.apiPort = 10085;
    m_buildOptions.logLevel = QStringLiteral("warning");
    m_buildOptions.enableStatsApi = true;

    m_processManager.setWorkingDirectory(m_dataDirectory);
    m_statsPollTimer.setInterval(1000);
    connect(&m_statsPollTimer, &QTimer::timeout, this, &VpnController::pollTrafficStats);
    m_speedTestTimer.setInterval(kSpeedTestTickIntervalMs);
    connect(&m_speedTestTimer, &QTimer::timeout, this, &VpnController::onSpeedTestTick);

    connect(&m_processManager, &XrayProcessManager::started, this, &VpnController::onProcessStarted);
    connect(&m_processManager, &XrayProcessManager::stopped, this, &VpnController::onProcessStopped);
    connect(&m_processManager, &XrayProcessManager::errorOccurred, this, &VpnController::onProcessError);
    connect(&m_processManager, &XrayProcessManager::logLine, this, &VpnController::onLogLine);
    connect(&m_processManager, &XrayProcessManager::trafficChanged, this, &VpnController::onTrafficUpdated);

    loadSettings();
    loadProfiles();

    const QString bundledXrayPath = detectDefaultXrayPath();
    if (!bundledXrayPath.isEmpty()) {
        m_xrayExecutablePath = bundledXrayPath;
    } else if (m_xrayExecutablePath.isEmpty()) {
        m_xrayExecutablePath = detectDefaultXrayPath();
    }
    detectProcessRoutingSupport();

    if (m_profileModel.rowCount() == 0) {
        m_currentProfileIndex = -1;
    } else if (m_currentProfileIndex < 0 || m_currentProfileIndex >= m_profileModel.rowCount()) {
        m_currentProfileIndex = 0;
    }
}

VpnController::~VpnController()
{
    cancelSpeedTest();
    if (m_processManager.isRunning()) {
        m_processManager.stop();
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

    m_currentProfileIndex = index;
    emit currentProfileIndexChanged();
    saveSettings();
}

QObject *VpnController::profileModel()
{
    return &m_profileModel;
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

bool VpnController::useSystemProxy() const
{
    return m_useSystemProxy;
}

void VpnController::setUseSystemProxy(bool enabled)
{
    if (m_useSystemProxy == enabled) {
        return;
    }

    m_useSystemProxy = enabled;
    emit useSystemProxyChanged();
    saveSettings();

    if (m_connectionState == ConnectionState::Connected) {
        applySystemProxy(enabled, !enabled);
    }
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
        setConnectionState(ConnectionState::Error);
        return false;
    }

    auto profile = parsed.value();
    if (profile.name.trimmed().isEmpty()) {
        profile.name = QStringLiteral("%1 %2")
            .arg(profile.protocol.toUpper(), profile.address);
    }

    if (!m_profileModel.addProfile(profile)) {
        setLastError(QStringLiteral("Failed to add imported profile."));
        setConnectionState(ConnectionState::Error);
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
    const int count = m_profileModel.rowCount();
    for (int row = 0; row < count; ++row) {
        const auto profile = m_profileModel.profileAt(row);
        if (!profile.has_value()) {
            continue;
        }
        const QString profileId = profile->id;
        QTimer::singleShot(row * kProfilePingStaggerMs, this, [this, profileId]() {
            const int rowNow = m_profileModel.indexOfId(profileId);
            if (rowNow >= 0) {
                pingProfile(rowNow);
            }
        });
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

    QString configError;
    if (!writeRuntimeConfig(profile.value(), &configError)) {
        setLastError(configError);
        setConnectionState(ConnectionState::Error);
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

    if (m_processManager.isRunning()) {
        m_processManager.stop();
    }

    if (m_processManager.isRunning()) {
        setLastError(QStringLiteral("Failed to stop xray-core process."));
        setConnectionState(ConnectionState::Error);
        return;
    }

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
    setConnectionState(ConnectionState::Connected);
    if (m_useSystemProxy) {
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

    if (exitStatus == QProcess::CrashExit) {
        setLastError(QStringLiteral("xray-core terminated unexpectedly."));
        setConnectionState(ConnectionState::Error);
        return;
    }

    if (m_connectionState != ConnectionState::Error) {
        setConnectionState(ConnectionState::Disconnected);
    }
}

void VpnController::onProcessError(const QString& error)
{
    m_statsPollTimer.stop();
    cancelSpeedTest();
    setLastError(QStringLiteral("xray-core error: %1").arg(error));
    setConnectionState(ConnectionState::Error);
}

void VpnController::onLogLine(const QString& line)
{
    if (!m_loggingEnabled) {
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
    emit logsChanged();
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

    m_statsPolling = true;

    qint64 uplinkBytes = 0;
    qint64 downlinkBytes = 0;
    QString error;
    const bool ok = queryTrafficStatsFromApi(&uplinkBytes,& downlinkBytes,& error);
    m_statsPolling = false;

    if (!ok) {
        ++m_statsQueryFailureCount;
        if ((m_statsQueryFailureCount == 1 || m_statsQueryFailureCount % 30 == 0) && !error.trimmed().isEmpty()) {
            appendSystemLog(QStringLiteral("[System] Traffic stats unavailable: %1").arg(error.trimmed()));
        }
        return;
    }
    m_statsQueryFailureCount = 0;

    if (m_txBytes != uplinkBytes || m_rxBytes != downlinkBytes) {
        m_txBytes = uplinkBytes;
        m_rxBytes = downlinkBytes;
        emit trafficChanged();
    }
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
    if (!m_speedTestRunning || m_speedTestReply == nullptr) {
        return;
    }

    const QByteArray chunk = m_speedTestReply->readAll();
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
    emit logsChanged();
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

    QString error;
    if (checkLocalProxyConnectivity(&error)) {
        appendSystemLog(QStringLiteral("[System] Proxy self-test passed (127.0.0.1:%1 is forwarding traffic).")
            .arg(m_buildOptions.socksPort));
        if (!m_useSystemProxy) {
            appendSystemLog(QStringLiteral("[System] Clean mode note: macOS system traffic is NOT auto-routed in this mode."));
        }
        return;
    }

    appendSystemLog(QStringLiteral("[System] Proxy self-test failed: %1").arg(error));
    if (m_useSystemProxy) {
        appendSystemLog(QStringLiteral("[System] Hint: verify macOS active interface proxy state and retry with admin approval."));
    } else {
        appendSystemLog(QStringLiteral("[System] Hint: Clean mode requires apps to use 127.0.0.1:%1 manually.")
            .arg(m_buildOptions.socksPort));
    }
}

bool VpnController::checkLocalProxyConnectivity(QString *errorMessage) const
{
    QTcpSocket socket;
    socket.connectToHost(QHostAddress::LocalHost, m_buildOptions.socksPort);
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
    if (uplinkBytes == nullptr || downlinkBytes == nullptr) {
        return false;
    }

    if (m_xrayExecutablePath.trimmed().isEmpty()) {
        return false;
    }

    QProcess process;
    process.start(
        m_xrayExecutablePath,
        {
            QStringLiteral("api"),
            QStringLiteral("statsquery"),
            QStringLiteral("--server=127.0.0.1:%1").arg(m_buildOptions.apiPort),
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

bool VpnController::writeRuntimeConfig(const ServerProfile& profile, QString *errorMessage)
{
    XrayConfigBuilder::BuildOptions options = m_buildOptions;
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
            loadedProfiles.append(profile.value());
        }
    }

    m_profileModel.setProfiles(loadedProfiles);
    if (m_autoPingProfiles && !loadedProfiles.isEmpty()) {
        QTimer::singleShot(50, this, [this]() { pingAllProfiles(); });
    }
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

void VpnController::loadSettings()
{
    QSettings settings;
    m_xrayExecutablePath = settings.value(QStringLiteral("xray/executablePath")).toString().trimmed();
    m_loggingEnabled = settings.value(QStringLiteral("logs/enabled"), true).toBool();
    m_autoPingProfiles = settings.value(QStringLiteral("profiles/autoPing"), true).toBool();
    m_currentProfileIndex = settings.value(QStringLiteral("profiles/currentIndex"), -1).toInt();
    m_useSystemProxy = settings.value(QStringLiteral("network/useSystemProxy"), false).toBool();
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
    settings.setValue(QStringLiteral("network/useSystemProxy"), m_useSystemProxy);
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

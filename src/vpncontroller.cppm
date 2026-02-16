/*!
 * @file        vpncontroller.cppm
 * @brief       Main backend controller for GenyConnect.
 *
 * @details
 * Exposes the core application orchestration layer to QML, including:
 * - profile import/selection
 * - Xray process lifecycle control
 * - system proxy management
 * - traffic/stat collection
 * - speed-test execution and reporting
 *
 * This controller coordinates all backend services and emits state changes
 * required by the UI.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QObject>
#include <QElapsedTimer>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkProxy>
#include <QProcess>
#include <QStringList>
#include <QTimer>
#include <QUrl>

#ifndef Q_MOC_RUN
export module genyconnect.backend.vpncontroller;
import genyconnect.backend.connectionstate;
import genyconnect.backend.serverprofile;
import genyconnect.backend.serverprofilemodel;
import genyconnect.backend.systemproxymanager;
import genyconnect.backend.xrayconfigbuilder;
import genyconnect.backend.xrayprocessmanager;
#endif

#ifdef Q_MOC_RUN
namespace App {
enum class ConnectionState;
}
struct ServerProfile;
class ServerProfileModel;
class SystemProxyManager;
class XrayProcessManager;
class XrayConfigBuilder {
public:
    struct BuildOptions;
};
#define GENYCONNECT_MODULE_EXPORT
#else
#define GENYCONNECT_MODULE_EXPORT export
#endif

/**
 * @class VpnController
 * @brief Central backend controller exposed to QML.
 *
 * @details
 * Coordinates profile management, Xray process lifecycle, system proxy
 * behavior, traffic polling, runtime config generation, and speed-test
 * workflows. This class acts as the single source of truth for UI state.
 */
GENYCONNECT_MODULE_EXPORT class VpnController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(ConnectionState connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionStateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY connectionStateChanged)

    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString latestLogLine READ latestLogLine NOTIFY latestLogLineChanged)
    Q_PROPERTY(QStringList recentLogs READ recentLogs NOTIFY logsChanged)

    Q_PROPERTY(qint64 rxBytes READ rxBytes NOTIFY trafficChanged)
    Q_PROPERTY(qint64 txBytes READ txBytes NOTIFY trafficChanged)
    Q_PROPERTY(bool speedTestRunning READ speedTestRunning NOTIFY speedTestChanged)
    Q_PROPERTY(QString speedTestPhase READ speedTestPhase NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestElapsedSec READ speedTestElapsedSec NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestDurationSec READ speedTestDurationSec NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestCurrentMbps READ speedTestCurrentMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestPeakMbps READ speedTestPeakMbps NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestPingMs READ speedTestPingMs NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestDownloadMbps READ speedTestDownloadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestUploadMbps READ speedTestUploadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(QString speedTestError READ speedTestError NOTIFY speedTestChanged)
    Q_PROPERTY(QStringList speedTestHistory READ speedTestHistory NOTIFY speedTestChanged)

    Q_PROPERTY(int currentProfileIndex READ currentProfileIndex WRITE setCurrentProfileIndex NOTIFY currentProfileIndexChanged)
    Q_PROPERTY(QObject *profileModel READ profileModel CONSTANT)

    Q_PROPERTY(QString xrayExecutablePath READ xrayExecutablePath WRITE setXrayExecutablePath NOTIFY xrayExecutablePathChanged)
    Q_PROPERTY(QString xrayVersion READ xrayVersion NOTIFY xrayVersionChanged)
    Q_PROPERTY(bool loggingEnabled READ loggingEnabled WRITE setLoggingEnabled NOTIFY loggingEnabledChanged)
    Q_PROPERTY(bool autoPingProfiles READ autoPingProfiles WRITE setAutoPingProfiles NOTIFY autoPingProfilesChanged)
    Q_PROPERTY(bool useSystemProxy READ useSystemProxy WRITE setUseSystemProxy NOTIFY useSystemProxyChanged)
    Q_PROPERTY(
        bool autoDisableSystemProxyOnDisconnect
        READ autoDisableSystemProxyOnDisconnect
        WRITE setAutoDisableSystemProxyOnDisconnect
        NOTIFY autoDisableSystemProxyOnDisconnectChanged
    )
    Q_PROPERTY(bool whitelistMode READ whitelistMode WRITE setWhitelistMode NOTIFY whitelistModeChanged)
    Q_PROPERTY(QString proxyDomainRules READ proxyDomainRules WRITE setProxyDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString directDomainRules READ directDomainRules WRITE setDirectDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString blockDomainRules READ blockDomainRules WRITE setBlockDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString proxyAppRules READ proxyAppRules WRITE setProxyAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(QString directAppRules READ directAppRules WRITE setDirectAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(QString blockAppRules READ blockAppRules WRITE setBlockAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(bool processRoutingSupported READ processRoutingSupported NOTIFY processRoutingSupportChanged)
    Q_PROPERTY(quint16 socksPort READ socksPort CONSTANT)
    Q_PROPERTY(quint16 httpPort READ httpPort CONSTANT)

public:
    /**
     * @brief Construct controller and initialize runtime state.
     * @param parent Optional QObject parent.
     */
    explicit VpnController(QObject *parent = nullptr);

    /**
     * @brief Destroy controller and release managed resources.
     */
    ~VpnController() override;

    /**
     * @brief Current connection state enum.
     * @return Connection state value.
     */
    ConnectionState connectionState() const;

    /**
     * @brief Whether tunnel is connected.
     * @return True when connected.
     */
    bool connected() const;

    /**
     * @brief Whether a connect operation is in progress.
     * @return True when currently connecting.
     */
    bool busy() const;

    /**
     * @brief Last controller/process error.
     * @return Error message string.
     */
    QString lastError() const;

    /**
     * @brief Most recent log line.
     * @return Latest emitted log line.
     */
    QString latestLogLine() const;

    /**
     * @brief Ring-buffered recent logs.
     * @return Recent log list.
     */
    QStringList recentLogs() const;

    /**
     * @brief Total received bytes from runtime stats.
     * @return RX byte counter.
     */
    qint64 rxBytes() const;

    /**
     * @brief Total transmitted bytes from runtime stats.
     * @return TX byte counter.
     */
    qint64 txBytes() const;

    /**
     * @brief Whether speed test is currently running.
     * @return Running flag.
     */
    bool speedTestRunning() const;

    /**
     * @brief Current speed-test phase.
     * @return Phase string (`Ping`, `Download`, `Upload`, ...).
     */
    QString speedTestPhase() const;

    /**
     * @brief Elapsed seconds in active phase.
     * @return Elapsed seconds.
     */
    int speedTestElapsedSec() const;

    /**
     * @brief Target duration for active phase.
     * @return Duration seconds.
     */
    int speedTestDurationSec() const;

    /**
     * @brief Instantaneous measured speed.
     * @return Current Mbps value.
     */
    double speedTestCurrentMbps() const;

    /**
     * @brief Peak measured speed in current phase.
     * @return Peak Mbps value.
     */
    double speedTestPeakMbps() const;

    /**
     * @brief Measured ping latency.
     * @return Ping milliseconds or negative when unavailable.
     */
    int speedTestPingMs() const;

    /**
     * @brief Final download test result.
     * @return Mbps value.
     */
    double speedTestDownloadMbps() const;

    /**
     * @brief Final upload test result.
     * @return Mbps value.
     */
    double speedTestUploadMbps() const;

    /**
     * @brief Last speed-test error.
     * @return Error string.
     */
    QString speedTestError() const;

    /**
     * @brief Completed speed-test history lines.
     * @return History list (newest first).
     */
    QStringList speedTestHistory() const;

    /**
     * @brief Currently selected profile row index.
     * @return Index or -1 when none selected.
     */
    int currentProfileIndex() const;

    /**
     * @brief Set selected profile row index.
     * @param index Target row index.
     */
    void setCurrentProfileIndex(int index);

    /**
     * @brief Access profile model as QObject for QML binding.
     * @return Pointer to profile model.
     */
    QObject *profileModel();

    /**
     * @brief Configured Xray executable path.
     * @return Executable path string.
     */
    QString xrayExecutablePath() const;

    /**
     * @brief Detected Xray version.
     * @return Version string.
     */
    QString xrayVersion() const;

    /**
     * @brief Whether log collection is enabled.
     * @return Logging enabled flag.
     */
    bool loggingEnabled() const;

    /**
     * @brief Whether profile list auto-pings endpoints.
     * @return Auto-ping flag.
     */
    bool autoPingProfiles() const;

    /**
     * @brief Set custom Xray executable path.
     * @param path Executable path.
     */
    void setXrayExecutablePath(const QString& path);

    /**
     * @brief Enable/disable log buffering.
     * @param enabled New logging state.
     */
    void setLoggingEnabled(bool enabled);

    /**
     * @brief Enable/disable automatic profile endpoint ping.
     * @param enabled New auto-ping state.
     */
    void setAutoPingProfiles(bool enabled);

    /**
     * @brief Whether system proxy should be managed on connect.
     * @return Proxy mode flag.
     */
    bool useSystemProxy() const;

    /**
     * @brief Set system proxy management mode.
     * @param enabled Enable or disable system proxy mode.
     */
    void setUseSystemProxy(bool enabled);

    /**
     * @brief Whether proxy is auto-disabled on disconnect.
     * @return Auto-disable flag.
     */
    bool autoDisableSystemProxyOnDisconnect() const;

    /**
     * @brief Set auto-disable behavior on disconnect.
     * @param enabled New auto-disable flag.
     */
    void setAutoDisableSystemProxyOnDisconnect(bool enabled);

    /**
     * @brief Whether whitelist routing mode is enabled.
     * @return Whitelist-mode flag.
     */
    bool whitelistMode() const;

    /**
     * @brief Set whitelist routing mode.
     * @param enabled New whitelist-mode flag.
     */
    void setWhitelistMode(bool enabled);

    /**
     * @brief Domain rules routed through proxy.
     * @return Rule text.
     */
    QString proxyDomainRules() const;

    /**
     * @brief Set proxy domain rules.
     * @param value Rule text.
     */
    void setProxyDomainRules(const QString& value);

    /**
     * @brief Domain rules routed directly.
     * @return Rule text.
     */
    QString directDomainRules() const;

    /**
     * @brief Set direct domain rules.
     * @param value Rule text.
     */
    void setDirectDomainRules(const QString& value);

    /**
     * @brief Domain rules blocked by routing.
     * @return Rule text.
     */
    QString blockDomainRules() const;

    /**
     * @brief Set blocked domain rules.
     * @param value Rule text.
     */
    void setBlockDomainRules(const QString& value);

    /**
     * @brief Process names forced through proxy.
     * @return Rule text.
     */
    QString proxyAppRules() const;

    /**
     * @brief Set proxy process rules.
     * @param value Rule text.
     */
    void setProxyAppRules(const QString& value);

    /**
     * @brief Process names forced direct.
     * @return Rule text.
     */
    QString directAppRules() const;

    /**
     * @brief Set direct process rules.
     * @param value Rule text.
     */
    void setDirectAppRules(const QString& value);

    /**
     * @brief Process names blocked by routing.
     * @return Rule text.
     */
    QString blockAppRules() const;

    /**
     * @brief Set blocked process rules.
     * @param value Rule text.
     */
    void setBlockAppRules(const QString& value);

    /**
     * @brief Whether process-based routing is supported by runtime.
     * @return Support flag.
     */
    bool processRoutingSupported() const;

    /**
     * @brief Local SOCKS port currently used by runtime config.
     * @return SOCKS port value.
     */
    quint16 socksPort() const;

    /**
     * @brief Local HTTP port currently used by runtime config.
     * @return HTTP port value.
     */
    quint16 httpPort() const;

    /**
     * @brief Import a share link and append profile.
     * @param link Raw VLESS/VMess link.
     * @return True when import succeeds.
     */
    Q_INVOKABLE bool importProfileLink(const QString& link);

    /**
     * @brief Remove profile row.
     * @param row Row index.
     * @return True when removal succeeds.
     */
    Q_INVOKABLE bool removeProfile(int row);

    /**
     * @brief Start endpoint ping for one profile row.
     * @param row Row index.
     */
    Q_INVOKABLE void pingProfile(int row);

    /**
     * @brief Start endpoint ping for all profiles.
     */
    Q_INVOKABLE void pingAllProfiles();

    /**
     * @brief Connect to profile row.
     * @param row Row index.
     */
    Q_INVOKABLE void connectToProfile(int row);

    /**
     * @brief Connect using currently selected profile.
     */
    Q_INVOKABLE void connectSelected();

    /**
     * @brief Disconnect active tunnel.
     */
    Q_INVOKABLE void disconnect();

    /**
     * @brief Toggle connected/disconnected state.
     */
    Q_INVOKABLE void toggleConnection();

    /**
     * @brief Explicitly clear OS proxy settings.
     */
    Q_INVOKABLE void cleanSystemProxy();

    /**
     * @brief Set executable path from local file URL.
     * @param url Local file URL.
     */
    Q_INVOKABLE void setXrayExecutableFromUrl(const QUrl& url);

    /**
     * @brief Start active speed-test workflow.
     */
    Q_INVOKABLE void startSpeedTest();

    /**
     * @brief Cancel active speed-test workflow.
     */
    Q_INVOKABLE void cancelSpeedTest();

    /**
     * @brief Format bytes into human-readable units.
     * @param bytes Raw byte count.
     * @return Formatted string.
     */
    Q_INVOKABLE QString formatBytes(qint64 bytes) const;

    /**
     * @brief Return selected profile endpoint address.
     * @return Address string or empty when unavailable.
     */
    Q_INVOKABLE QString currentProfileAddress() const;

    /**
     * @brief Copy buffered logs to clipboard.
     */
    Q_INVOKABLE void copyLogsToClipboard() const;

signals:
    //! Emitted when connection state changes.
    void connectionStateChanged();
    //! Emitted when last error string changes.
    void lastErrorChanged();
    //! Emitted when latest log line changes.
    void latestLogLineChanged();
    //! Emitted when recent log list changes.
    void logsChanged();
    //! Emitted when traffic counters change.
    void trafficChanged();
    //! Emitted when speed-test state/metrics change.
    void speedTestChanged();
    //! Emitted when selected profile index changes.
    void currentProfileIndexChanged();
    //! Emitted when executable path changes.
    void xrayExecutablePathChanged();
    //! Emitted when xray version string changes.
    void xrayVersionChanged();
    //! Emitted when logging flag changes.
    void loggingEnabledChanged();
    //! Emitted when profile auto-ping flag changes.
    void autoPingProfilesChanged();
    //! Emitted when system-proxy usage flag changes.
    void useSystemProxyChanged();
    //! Emitted when auto-disable proxy flag changes.
    void autoDisableSystemProxyOnDisconnectChanged();
    //! Emitted when whitelist flag changes.
    void whitelistModeChanged();
    //! Emitted when domain rules are updated.
    void routingRulesChanged();
    //! Emitted when app/process rules are updated.
    void appRulesChanged();
    //! Emitted when process-routing capability is re-evaluated.
    void processRoutingSupportChanged();

private slots:
    //! Handle process started signal from process manager.
    void onProcessStarted();
    //! Handle process stopped signal from process manager.
    void onProcessStopped(int exitCode, QProcess::ExitStatus exitStatus);
    //! Handle process/runtime error callback.
    void onProcessError(const QString& error);
    //! Handle incoming runtime log line.
    void onLogLine(const QString& line);
    //! Handle traffic-updated signal from process manager.
    void onTrafficUpdated();
    //! Poll Xray API traffic stats.
    void pollTrafficStats();
    //! Tick handler for speed-test phase timings/samples.
    void onSpeedTestTick();
    //! Read bytes during active speed-test request.
    void onSpeedTestReadyRead();
    //! Update upload counters during upload phase.
    void onSpeedTestUploadProgress(qint64 sent, qint64 total);
    //! Handle speed-test request completion.
    void onSpeedTestFinished();

private:
    /**
     * @brief Set connection state and emit change when needed.
     * @param state New state.
     */
    void setConnectionState(ConnectionState state);

    /**
     * @brief Set last error and emit change when needed.
     * @param error New error message.
     */
    void setLastError(const QString& error);

    /**
     * @brief Start one HTTP request for speed-test phase.
     * @param url Endpoint URL.
     * @param upload True for upload request.
     * @param payload Upload body data.
     */
    void startSpeedTestRequest(const QUrl& url, bool upload, const QByteArray& payload = QByteArray());

    /**
     * @brief Start request for current phase/attempt.
     */
    void startCurrentSpeedTestRequest();

    /**
     * @brief Enter ping phase and dispatch request.
     */
    void startPingPhase();

    /**
     * @brief Enter download phase and dispatch request.
     */
    void startDownloadPhase();

    /**
     * @brief Enter upload phase and dispatch request.
     */
    void startUploadPhase();

    /**
     * @brief Finalize speed-test workflow.
     * @param ok True on successful completion.
     * @param error Error message when failed.
     */
    void finishSpeedTest(bool ok, const QString& error = QString());

    /**
     * @brief Enable/disable system proxy according to settings/state.
     * @param enable Desired proxy state.
     * @param force Force operation even if state appears unchanged.
     */
    void applySystemProxy(bool enable, bool force = false);

    /**
     * @brief Append system-tagged line to recent logs.
     * @param message Log text.
     */
    void appendSystemLog(const QString& message);

    /**
     * @brief Perform local proxy self-connectivity check.
     */
    void runProxySelfCheck();

    /**
     * @brief Reset speed-test state variables.
     * @param emitSignal Emit speedTestChanged when true.
     */
    void resetSpeedTestState(bool emitSignal = true);

    /**
     * @brief Check local proxy can reach test endpoint.
     * @param errorMessage Optional error output.
     * @return True when check succeeds.
     */
    bool checkLocalProxyConnectivity(QString *errorMessage) const;

    /**
     * @brief Detect whether process-routing feature is supported.
     * @return True if supported by current runtime.
     */
    bool detectProcessRoutingSupport();

    /**
     * @brief Parse newline/comma-separated rules.
     * @param value Raw rule text.
     * @return Normalized rule list.
     */
    static QStringList parseRules(const QString& value);

    /**
     * @brief Query traffic stats through Xray API endpoint.
     * @param uplinkBytes Output uplink bytes.
     * @param downlinkBytes Output downlink bytes.
     * @param errorMessage Optional error output.
     * @return True on successful query/parse.
     */
    bool queryTrafficStatsFromApi(qint64 *uplinkBytes, qint64 *downlinkBytes, QString *errorMessage);

    /**
     * @brief Write generated runtime config file for selected profile.
     * @param profile Source profile.
     * @param errorMessage Optional error output.
     * @return True on success.
     */
    bool writeRuntimeConfig(const ServerProfile& profile, QString *errorMessage);

    /**
     * @brief Attempt to detect default Xray executable path.
     * @return Best-effort executable path.
     */
    QString detectDefaultXrayPath() const;

    /**
     * @brief Load stored profiles from disk.
     */
    void loadProfiles();

    /**
     * @brief Persist current profiles to disk.
     */
    void saveProfiles() const;

    /**
     * @brief Load persistent controller settings.
     */
    void loadSettings();

    /**
     * @brief Save persistent controller settings.
     */
    void saveSettings() const;

    ConnectionState m_connectionState = ConnectionState::Disconnected;
    QString m_lastError;
    QString m_latestLogLine;
    QStringList m_recentLogs;
    qint64 m_rxBytes = 0;
    qint64 m_txBytes = 0;
    bool m_speedTestRunning = false;
    QString m_speedTestPhase = QStringLiteral("Idle");
    int m_speedTestElapsedSec = 0;
    int m_speedTestDurationSec = 18;
    double m_speedTestCurrentMbps = 0.0;
    double m_speedTestPeakMbps = 0.0;
    int m_speedTestPingMs = -1;
    double m_speedTestDownloadMbps = 0.0;
    double m_speedTestUploadMbps = 0.0;
    QString m_speedTestError;
    QStringList m_speedTestHistory;
    qint64 m_speedTestBytesReceived = 0;
    qint64 m_speedTestLastBytes = 0;
    int m_speedTestAttempt = 0;
    int m_speedTestPingSampleCount = 0;
    qint64 m_speedTestPingTotalMs = 0;
    bool m_speedTestUploadMode = false;
    qint64 m_speedTestPhaseBytes = 0;
    QElapsedTimer m_speedTestRequestTimer;
    QElapsedTimer m_speedTestPhaseTimer;
    QElapsedTimer m_speedTestSampleTimer;

    int m_currentProfileIndex = -1;

    QString m_xrayExecutablePath;
    QString m_xrayVersion = QStringLiteral("Unknown");
    bool m_loggingEnabled = true;
    bool m_autoPingProfiles = true;
    bool m_useSystemProxy = false;
    bool m_autoDisableSystemProxyOnDisconnect = false;
    bool m_whitelistMode = false;
    QString m_proxyDomainRules;
    QString m_directDomainRules;
    QString m_blockDomainRules;
    QString m_proxyAppRules;
    QString m_directAppRules;
    QString m_blockAppRules;
    bool m_processRoutingSupported = false;
    bool m_processRoutingSupportChecked = false;

    QString m_dataDirectory;
    QString m_profilesPath;
    QString m_runtimeConfigPath;

    ServerProfileModel m_profileModel;
    SystemProxyManager m_systemProxyManager;
    XrayProcessManager m_processManager;
    XrayConfigBuilder::BuildOptions m_buildOptions;
    QTimer m_statsPollTimer;
    QTimer m_speedTestTimer;
    QNetworkAccessManager m_speedTestNetworkManager;
    QNetworkReply *m_speedTestReply = nullptr;
    bool m_statsPolling = false;
    int m_statsQueryFailureCount = 0;
};

#include "vpncontroller.moc"

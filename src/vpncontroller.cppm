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
#include <QByteArray>
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QElapsedTimer>
#include <QDateTime>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkProxy>
#include <QSet>
#include <QStringList>
#include <QTimer>
#include <QUrl>
#include <QVector>
#include <QVariantList>
#include <QVariantMap>
#include <atomic>
#include "runtime/vpnruntimebackend.hpp"
#if !defined(Q_OS_IOS)
#include <QProcess>
#endif

class ServerProfileModel;
class SystemProxyManager;
class Updater;
class PowerModeManager;

#ifndef Q_MOC_RUN
export module genyconnect.backend.vpncontroller;
import genyconnect.backend.serverprofile;
import genyconnect.backend.xrayconfigbuilder;
#endif

namespace App {
Q_NAMESPACE
enum class ConnectionState
{
    Disconnected,
    Connecting,
    Connected,
    Error
};
Q_ENUM_NS(ConnectionState)
}
using ConnectionState = App::ConnectionState;

#ifndef Q_MOC_RUN
export const QMetaObject& vpnControllerConnectionStateMetaObject();
#endif

#ifdef Q_MOC_RUN
struct ServerProfile;
class VpnRuntimeBackend;
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
public:
    Q_PROPERTY(ConnectionState connectionState READ connectionState NOTIFY connectionStateChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionStateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY connectionStateChanged)

    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString latestLogLine READ latestLogLine NOTIFY latestLogLineChanged)
    Q_PROPERTY(QStringList recentLogs READ recentLogs NOTIFY logsChanged)

    Q_PROPERTY(qint64 rxBytes READ rxBytes NOTIFY trafficChanged)
    Q_PROPERTY(qint64 txBytes READ txBytes NOTIFY trafficChanged)
    Q_PROPERTY(QString publicIpAddress READ publicIpAddress NOTIFY publicIpAddressChanged)
    Q_PROPERTY(bool publicIpRefreshing READ publicIpRefreshing NOTIFY publicIpAddressChanged)
    Q_PROPERTY(QString latestRecordedUsage READ latestRecordedUsage NOTIFY profileUsageChanged)
    Q_PROPERTY(QString memoryUsageText READ memoryUsageText NOTIFY memoryUsageChanged)
    Q_PROPERTY(bool speedTestRunning READ speedTestRunning NOTIFY speedTestChanged)
    Q_PROPERTY(QString speedTestState READ speedTestState NOTIFY speedTestChanged)
    Q_PROPERTY(QString speedTestPhase READ speedTestPhase NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestElapsedSec READ speedTestElapsedSec NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestDurationSec READ speedTestDurationSec NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestProgress READ speedTestProgress NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestCurrentMbps READ speedTestCurrentMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestPeakMbps READ speedTestPeakMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestAverageMbps READ speedTestAverageMbps NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestPingMs READ speedTestPingMs NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestJitterMs READ speedTestJitterMs NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestPacketLossPct READ speedTestPacketLossPct NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestRouteStabilityPct READ speedTestRouteStabilityPct NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestQualityScore READ speedTestQualityScore NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestLatencyMinMs READ speedTestLatencyMinMs NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestLatencyMaxMs READ speedTestLatencyMaxMs NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestDownloadMbps READ speedTestDownloadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(double speedTestUploadMbps READ speedTestUploadMbps NOTIFY speedTestChanged)
    Q_PROPERTY(QString speedTestError READ speedTestError NOTIFY speedTestChanged)
    Q_PROPERTY(QStringList speedTestHistory READ speedTestHistory NOTIFY speedTestChanged)
    Q_PROPERTY(int speedTestSelectedSizeMb READ speedTestSelectedSizeMb WRITE setSpeedTestSelectedSizeMb NOTIFY speedTestChanged)

    Q_PROPERTY(int currentProfileIndex READ currentProfileIndex WRITE setCurrentProfileIndex NOTIFY currentProfileIndexChanged)
    Q_PROPERTY(QString currentProfileAddressValue READ currentProfileAddress NOTIFY currentProfileIndexChanged)
    Q_PROPERTY(QObject *profileModel READ profileModel CONSTANT)
    Q_PROPERTY(QObject *updater READ updater CONSTANT)

    Q_PROPERTY(QString xrayExecutablePath READ xrayExecutablePath WRITE setXrayExecutablePath NOTIFY xrayExecutablePathChanged)
    Q_PROPERTY(QString xrayVersion READ xrayVersion NOTIFY xrayVersionChanged)
    Q_PROPERTY(bool loggingEnabled READ loggingEnabled WRITE setLoggingEnabled NOTIFY loggingEnabledChanged)
    Q_PROPERTY(bool autoPingProfiles READ autoPingProfiles WRITE setAutoPingProfiles NOTIFY autoPingProfilesChanged)
    Q_PROPERTY(QStringList subscriptions READ subscriptions NOTIFY subscriptionsChanged)
    Q_PROPERTY(QVariantList subscriptionItems READ subscriptionItems NOTIFY subscriptionsChanged)
    Q_PROPERTY(bool subscriptionBusy READ subscriptionBusy NOTIFY subscriptionStateChanged)
    Q_PROPERTY(QString subscriptionMessage READ subscriptionMessage NOTIFY subscriptionStateChanged)
    Q_PROPERTY(QStringList profileGroups READ profileGroups NOTIFY profileGroupsChanged)
    Q_PROPERTY(QVariantList profileGroupItems READ profileGroupItems NOTIFY profileGroupOptionsChanged)
    Q_PROPERTY(QString currentProfileGroup READ currentProfileGroup WRITE setCurrentProfileGroup NOTIFY currentProfileGroupChanged)
    Q_PROPERTY(int profileCount READ profileCount NOTIFY profileStatsChanged)
    Q_PROPERTY(int filteredProfileCount READ filteredProfileCount NOTIFY profileStatsChanged)
    Q_PROPERTY(int bestPingMs READ bestPingMs NOTIFY profileStatsChanged)
    Q_PROPERTY(int worstPingMs READ worstPingMs NOTIFY profileStatsChanged)
    Q_PROPERTY(double profileScore READ profileScore NOTIFY profileStatsChanged)
    Q_PROPERTY(bool useSystemProxy READ useSystemProxy WRITE setUseSystemProxy NOTIFY useSystemProxyChanged)
    Q_PROPERTY(bool tunMode READ tunMode WRITE setTunMode NOTIFY tunModeChanged)
    Q_PROPERTY(bool runtimeTunActive READ runtimeTunActive NOTIFY connectionStateChanged)
    Q_PROPERTY(bool killSwitchEnabled READ killSwitchEnabled WRITE setKillSwitchEnabled NOTIFY killSwitchEnabledChanged)
    Q_PROPERTY(bool autoDisableSystemProxyOnDisconnect READ autoDisableSystemProxyOnDisconnect WRITE setAutoDisableSystemProxyOnDisconnect NOTIFY autoDisableSystemProxyOnDisconnectChanged)
    Q_PROPERTY(bool whitelistMode READ whitelistMode WRITE setWhitelistMode NOTIFY whitelistModeChanged)
    Q_PROPERTY(QString proxyDomainRules READ proxyDomainRules WRITE setProxyDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString directDomainRules READ directDomainRules WRITE setDirectDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString blockDomainRules READ blockDomainRules WRITE setBlockDomainRules NOTIFY routingRulesChanged)
    Q_PROPERTY(QString customDnsServers READ customDnsServers WRITE setCustomDnsServers NOTIFY customDnsServersChanged)
    Q_PROPERTY(QString lanSharingMode READ lanSharingMode WRITE setLanSharingMode NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(bool lanSharingEnabled READ lanSharingEnabled WRITE setLanSharingEnabled NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(QString lanSharingBindAddress READ lanSharingBindAddress WRITE setLanSharingBindAddress NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(bool lanSharingAllowAnyBind READ lanSharingAllowAnyBind WRITE setLanSharingAllowAnyBind NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(QString lanSharingInterface READ lanSharingInterface WRITE setLanSharingInterface NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(bool lanGatewayExperimentalEnabled READ lanGatewayExperimentalEnabled WRITE setLanGatewayExperimentalEnabled NOTIFY lanSharingSettingsChanged)
    Q_PROPERTY(QString proxyAppRules READ proxyAppRules WRITE setProxyAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(QString directAppRules READ directAppRules WRITE setDirectAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(QString blockAppRules READ blockAppRules WRITE setBlockAppRules NOTIFY appRulesChanged)
    Q_PROPERTY(QVariantList routingRuleItems READ routingRuleItems NOTIFY routingRulesChanged)
    Q_PROPERTY(QString currentProfileUsageHour READ currentProfileUsageHour NOTIFY profileUsageChanged)
    Q_PROPERTY(QString currentProfileUsageDay READ currentProfileUsageDay NOTIFY profileUsageChanged)
    Q_PROPERTY(QString currentProfileUsageWeek READ currentProfileUsageWeek NOTIFY profileUsageChanged)
    Q_PROPERTY(QString currentProfileUsageMonth READ currentProfileUsageMonth NOTIFY profileUsageChanged)
    Q_PROPERTY(QString selectedUsageProfileId READ selectedUsageProfileId WRITE setSelectedUsageProfileId NOTIFY selectedUsageProfileIdChanged)
    Q_PROPERTY(QVariantList usageProfileOptions READ usageProfileOptions NOTIFY profileUsageChanged)
    Q_PROPERTY(bool processRoutingSupported READ processRoutingSupported NOTIFY processRoutingSupportChanged)
    Q_PROPERTY(quint16 socksPort READ socksPort NOTIFY localPortsChanged)
    Q_PROPERTY(quint16 httpPort READ httpPort NOTIFY localPortsChanged)
    Q_PROPERTY(bool isMobile READ isMobile NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool isDesktop READ isDesktop NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool supportsSystemProxy READ supportsSystemProxy NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool supportsTun READ supportsTun NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool supportsPerAppRouting READ supportsPerAppRouting NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool lanSharingSupported READ lanSharingSupported NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool supportsAutoUpdate READ supportsAutoUpdate NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool requiresVpnPermission READ requiresVpnPermission NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool requiresForegroundService READ requiresForegroundService NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(bool requiresNetworkExtension READ requiresNetworkExtension NOTIFY runtimeCapabilitiesChanged)
    Q_PROPERTY(QObject *powerModeManager READ powerModeManager CONSTANT)
    Q_PROPERTY(QString powerMode READ powerMode WRITE setPowerMode NOTIFY powerModeChanged)
    Q_PROPERTY(QStringList powerModeOptions READ powerModeOptions CONSTANT)
    Q_PROPERTY(QVariantMap powerPolicy READ powerPolicy NOTIFY powerPolicyChanged)
    Q_PROPERTY(QVariantMap visualPowerPolicy READ visualPowerPolicy NOTIFY powerPolicyChanged)
    Q_PROPERTY(QVariantMap powerDiagnostics READ powerDiagnostics NOTIFY powerDiagnosticsChanged)

    virtual void __geny_vtable_anchor();
    Q_OBJECT
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
     * @brief Current GenyConnect process memory usage.
     * @return Human-readable memory usage text.
     */
    QString memoryUsageText() const;
    QString publicIpAddress() const;
    bool publicIpRefreshing() const;
    QString latestRecordedUsage() const;

    /**
     * @brief Whether speed test is currently running.
     * @return Running flag.
     */
    bool speedTestRunning() const;
    QString speedTestState() const;

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
    double speedTestProgress() const;

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
    double speedTestAverageMbps() const;

    /**
     * @brief Measured ping latency.
     * @return Ping milliseconds or negative when unavailable.
     */
    int speedTestPingMs() const;
    int speedTestJitterMs() const;
    double speedTestPacketLossPct() const;
    int speedTestRouteStabilityPct() const;
    int speedTestQualityScore() const;
    int speedTestLatencyMinMs() const;
    int speedTestLatencyMaxMs() const;

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
    int speedTestSelectedSizeMb() const;
    void setSpeedTestSelectedSizeMb(int sizeMb);

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
     * @brief Access updater object for QML binding.
     * @return Pointer to updater service.
     */
    QObject *updater();
    QObject *powerModeManager();
    QString powerMode() const;
    void setPowerMode(const QString& mode);
    QStringList powerModeOptions() const;
    QVariantMap powerPolicy() const;
    QVariantMap visualPowerPolicy() const;
    QVariantMap powerDiagnostics() const;

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
     * @brief Saved subscription URLs (legacy-compatible list).
     * @return URL list.
     */
    QStringList subscriptions() const;

    /**
     * @brief Structured subscription entries (id/name/group/url).
     * @return Variant list of subscription maps.
     */
    QVariantList subscriptionItems() const;
    bool subscriptionBusy() const;
    QString subscriptionMessage() const;

    /**
     * @brief Available profile groups/categories.
     * @return Group names including `All`.
     */
    QStringList profileGroups() const;
    QVariantList profileGroupItems() const;

    /**
     * @brief Currently active group filter for profile listing.
     * @return Group name (`All` means unfiltered).
     */
    QString currentProfileGroup() const;
    int profileCount() const;

    /**
     * @brief Number of profiles visible under current group filter.
     * @return Filtered profile count.
     */
    int filteredProfileCount() const;
    int bestPingMs() const;
    int worstPingMs() const;
    double profileScore() const;
    Q_INVOKABLE bool isProfileGroupEnabled(const QString& groupName) const;
    Q_INVOKABLE bool isProfileGroupExclusive(const QString& groupName) const;
    Q_INVOKABLE QString profileGroupBadge(const QString& groupName) const;
    Q_INVOKABLE void setProfileGroupEnabled(const QString& groupName, bool enabled);
    Q_INVOKABLE void setProfileGroupExclusive(const QString& groupName, bool exclusive);
    Q_INVOKABLE void setProfileGroupBadge(const QString& groupName, const QString& badge);
    Q_INVOKABLE bool ensureProfileGroup(const QString& groupName);
    Q_INVOKABLE bool renameProfileGroup(const QString& oldName, const QString& newName);
    Q_INVOKABLE bool removeProfileGroup(const QString& groupName);
    Q_INVOKABLE int removeAllProfileGroups();

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
     * @brief Set active group filter for profiles/subscription actions.
     * @param groupName Group name (`All` to clear filtering).
     */
    void setCurrentProfileGroup(const QString& groupName);

    /**
     * @brief Whether system proxy should be managed on connect.
     * @return Proxy mode flag.
     */
    bool useSystemProxy() const;
    bool tunMode() const;
    bool runtimeTunActive() const;
    bool killSwitchEnabled() const;

    /**
     * @brief Set system proxy management mode.
     * @param enabled Enable or disable system proxy mode.
     */
    void setUseSystemProxy(bool enabled);
    void setTunMode(bool enabled);
    void setKillSwitchEnabled(bool enabled);

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
     * @brief Custom DNS servers used in generated runtime config.
     * @return Comma/newline-separated DNS servers.
     */
    QString customDnsServers() const;
    QString lanSharingMode() const;
    bool lanSharingEnabled() const;
    QString lanSharingBindAddress() const;
    bool lanSharingAllowAnyBind() const;
    QString lanSharingInterface() const;
    bool lanGatewayExperimentalEnabled() const;

    /**
     * @brief Set blocked domain rules.
     * @param value Rule text.
     */
    void setBlockDomainRules(const QString& value);

    /**
     * @brief Set custom DNS servers list for runtime config generation.
     * @param value Comma/newline-separated DNS servers.
     */
    void setCustomDnsServers(const QString& value);
    void setLanSharingMode(const QString& mode);
    void setLanSharingEnabled(bool enabled);
    void setLanSharingBindAddress(const QString& address);
    void setLanSharingAllowAnyBind(bool enabled);
    void setLanSharingInterface(const QString& interfaceName);
    void setLanGatewayExperimentalEnabled(bool enabled);

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
     * @brief Hourly usage summary for selected profile.
     * @return Human-readable traffic text.
     */
    QString currentProfileUsageHour() const;

    /**
     * @brief Daily usage summary for selected profile.
     * @return Human-readable traffic text.
     */
    QString currentProfileUsageDay() const;

    /**
     * @brief Weekly usage summary for selected profile.
     * @return Human-readable traffic text.
     */
    QString currentProfileUsageWeek() const;

    /**
     * @brief Monthly usage summary for selected profile.
     * @return Human-readable traffic text.
     */
    QString currentProfileUsageMonth() const;
    QString selectedUsageProfileId() const;
    void setSelectedUsageProfileId(const QString& profileId);
    QVariantList usageProfileOptions() const;
    QVariantList routingRuleItems() const;

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
    bool isMobile() const;
    bool isDesktop() const;
    bool supportsSystemProxy() const;
    bool supportsTun() const;
    bool supportsPerAppRouting() const;
    bool lanSharingSupported() const;
    bool supportsAutoUpdate() const;
    bool requiresVpnPermission() const;
    bool requiresForegroundService() const;
    bool requiresNetworkExtension() const;

    /**
     * @brief Import a share link and append profile.
     * @param link Raw VLESS/VMess link.
     * @return True when import succeeds.
     */
    Q_INVOKABLE bool importProfileLink(const QString& link);

    /**
     * @brief Import multiple profiles from plain/base64 subscription text.
     * @param text Raw text that may contain many vmess/vless links.
     * @return Number of imported/updated profiles.
     */
    Q_INVOKABLE int importProfileBatch(const QString& text);
    /**
     * @brief Add subscription URL and import its profiles.
     * @param url Subscription endpoint URL.
     * @return True when at least one profile is imported.
     */
    Q_INVOKABLE bool addSubscription(
        const QString& url,
        const QString& name = QString(),
        const QString& group = QString()
    );

    /**
     * @brief Refresh all saved subscriptions.
     * @return Number of successfully refreshed subscription URLs.
     */
    Q_INVOKABLE int refreshSubscriptions();

    /**
     * @brief Refresh only subscriptions within one group.
     * @param group Group/category name.
     * @return Number of queued subscription URLs in that group.
     */
    Q_INVOKABLE int refreshSubscriptionsByGroup(const QString& group);

    /**
     * @brief Remove profile row.
     * @param row Row index.
     * @return True when removal succeeds.
     */
    Q_INVOKABLE bool removeProfile(int row);
    Q_INVOKABLE bool updateProfileBasics(int row, const QString& name, const QString& groupName);
    Q_INVOKABLE bool updateProfile(
        int row,
        const QString& name,
        const QString& groupName,
        const QString& configLink
    );
    Q_INVOKABLE QString exportProfileLink(int row) const;
    /**
     * @brief Remove all stored profiles.
     * @return Number of removed profiles.
     */
    Q_INVOKABLE int removeAllProfiles();
    Q_INVOKABLE int removeDeadProfiles();
    Q_INVOKABLE bool removeSubscription(const QString& id);
    Q_INVOKABLE int removeSubscriptionsByGroup(const QString& group = QString());

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
    Q_INVOKABLE bool shouldShowSecurityWarningForProfile(int row) const;
    Q_INVOKABLE void setSecurityWarningDismissedForProfile(int row, bool dismissed);

    /**
     * @brief Explicitly clear OS proxy settings.
     */
    Q_INVOKABLE void cleanSystemProxy();
    Q_INVOKABLE QVariantMap clearNetworkCache();
    Q_INVOKABLE void refreshPublicIp();

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
     * @brief Return selected profile display label.
     * @return Profile name or empty when unavailable.
     */
    Q_INVOKABLE QString currentProfileLabel() const;

    /**
     * @brief Return selected profile subtitle text.
     * @return Protocol/address/security summary or empty when unavailable.
     */
    Q_INVOKABLE QString currentProfileSubtitle() const;
    Q_INVOKABLE QString currentProfileGroupLabel() const;
    Q_INVOKABLE int currentProfilePingMs() const;

    /**
     * @brief Copy buffered logs to clipboard.
     */
    Q_INVOKABLE void copyLogsToClipboard() const;
    Q_INVOKABLE void copyTextToClipboard(const QString& text) const;
    Q_INVOKABLE bool shareText(const QString& subject, const QString& text) const;
    Q_INVOKABLE QVariantMap qrCodeMatrix(const QString& text) const;
    Q_INVOKABLE QString licenseText() const;
    Q_INVOKABLE bool openSystemProxySettings() const;
    Q_INVOKABLE bool openUrlWithChooser(const QString& url, const QString& chooserTitle) const;
    Q_INVOKABLE bool openUrlInAndroidPackage(const QString& url, const QString& packageName) const;
    Q_INVOKABLE bool isAndroidPackageInstalled(const QString& packageName) const;
    Q_INVOKABLE QVariantMap systemInfo() const;
    Q_INVOKABLE QVariantMap systemSoftwareInfo() const;
    Q_INVOKABLE QVariantMap systemHardwareInfo() const;
    Q_INVOKABLE QString systemSoftwareInfoValue(const QString& key) const;
    Q_INVOKABLE QString systemHardwareInfoValue(const QString& key) const;
    Q_INVOKABLE QString systemInfoText() const;
    Q_INVOKABLE QVariantList donationWalletTargets(const QString& transferUrl, const QString& swapUrl) const;
    Q_INVOKABLE QVariantMap donationConfig() const;
    Q_INVOKABLE QVariantList donationTokenOptions() const;
    Q_INVOKABLE QVariantMap buildDonationPayload(const QString& tokenSymbol, const QString& amountText) const;

    /**
     * @brief Clear in-memory log history shown in UI.
     */
    Q_INVOKABLE void clearLogs();

    /**
     * @brief Structured usage summary for selected profile.
     * @return Map containing total/day/week/month/hour usage.
     */
    Q_INVOKABLE QVariantMap currentProfileUsageSummary() const;
    Q_INVOKABLE QVariantMap usageSummaryForProfile(const QString& profileId) const;
    Q_INVOKABLE QVariantMap globalUsageSummary() const;

    /**
     * @brief Usage history buckets for selected profile.
     * @param period Bucket period (`hour`, `day`, `week`, `month`).
     * @param limit Max number of newest rows to return.
     * @return List of usage rows.
     */
    Q_INVOKABLE QVariantList currentProfileUsageHistory(const QString& period, int limit = 20) const;
    Q_INVOKABLE QVariantList usageHistoryForProfile(const QString& profileId, const QString& period, int limit = 20) const;
    Q_INVOKABLE QVariantList currentProfileUsageSessions(int limit = 20) const;
    Q_INVOKABLE QVariantList usageSessionsForProfile(const QString& profileId, int limit = 20) const;
    Q_INVOKABLE void clearCurrentProfileUsage();
    Q_INVOKABLE void clearAllProfileUsage();
    Q_INVOKABLE QVariantMap validateRoutingRule(const QString& targetType, const QString& targetValue, const QString& action) const;
    Q_INVOKABLE QString createRoutingRule(
        const QString& targetType,
        const QString& targetValue,
        const QString& action,
        const QString& profileId = QString(),
        bool enabled = true
    );
    Q_INVOKABLE bool updateRoutingRule(
        const QString& id,
        const QString& targetType,
        const QString& targetValue,
        const QString& action,
        const QString& profileId,
        bool enabled
    );
    Q_INVOKABLE bool removeRoutingRule(const QString& id);
    Q_INVOKABLE bool duplicateRoutingRule(const QString& id);
    Q_INVOKABLE bool moveRoutingRule(const QString& id, int newIndex);
    Q_INVOKABLE bool setRoutingRuleEnabled(const QString& id, bool enabled);
    Q_INVOKABLE bool clearRoutingRules();
    Q_INVOKABLE QString exportProfile(int row) const;
    Q_INVOKABLE QString exportProfiles(const QVariantList& rows) const;
    Q_INVOKABLE QVariantList availableAppRuleItems() const;
    Q_INVOKABLE void requestAvailableAppRuleItems();
    Q_INVOKABLE void appendAppRule(const QString& target, const QString& process);
    Q_INVOKABLE QVariantList availableLanHostAddresses() const;
    Q_INVOKABLE QString effectiveLanSharingHost() const;
    Q_INVOKABLE bool applyLanSharingPreset(const QString& mode);
    Q_INVOKABLE void syncSystemBars(bool darkThemeEnabled);
    Q_INVOKABLE bool minimizeToBackground() const;
    Q_INVOKABLE QString currentProfileTransportPowerClass() const;
    Q_INVOKABLE QString classifyTransportPower(const QString& network, const QString& security, const QString& alpn = QString()) const;
    Q_INVOKABLE QString transportPowerDescription(const QString& powerClass) const;
    Q_INVOKABLE void updatePowerAdaptiveState(bool screenOn, bool charging, bool batterySaver, int batteryLevel, const QString& networkType);

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
    //! Emitted when process memory usage snapshot changes.
    void memoryUsageChanged();
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
    void subscriptionsChanged();
    void subscriptionStateChanged();
    void profileStatsChanged();
    void profileGroupsChanged();
    void profileGroupOptionsChanged();
    void currentProfileGroupChanged();
    //! Emitted when system-proxy usage flag changes.
    void useSystemProxyChanged();
    void tunModeChanged();
    void localPortsChanged();
    //! Emitted when auto-disable proxy flag changes.
    void autoDisableSystemProxyOnDisconnectChanged();
    //! Emitted when whitelist flag changes.
    void whitelistModeChanged();
    //! Emitted when domain rules are updated.
    void routingRulesChanged();
    //! Emitted when custom DNS server list is updated.
    void customDnsServersChanged();
    //! Emitted when app/process rules are updated.
    void appRulesChanged();
    //! Emitted when LAN sharing settings or selected device-mode preset changes.
    void lanSharingSettingsChanged();
    //! Emitted when per-profile traffic usage snapshots change.
    void profileUsageChanged();
    //! Emitted when process-routing capability is re-evaluated.
    void processRoutingSupportChanged();
    //! Emitted when asynchronous app-rule discovery finishes.
    void availableAppRuleItemsReady(const QVariantList& items);
    void selectedUsageProfileIdChanged();
    void runtimeCapabilitiesChanged();
    void publicIpAddressChanged();
    void killSwitchEnabledChanged();
    void powerModeChanged();
    void powerPolicyChanged();
    void powerDiagnosticsChanged();

private slots:
    //! Handle process started signal from process manager.
    void onProcessStarted();
    //! Handle process stopped signal from process manager.
    void onProcessStopped(int exitCode, VpnRuntimeBackend::ExitStatus exitStatus);
    //! Handle process/runtime error callback.
    void onProcessError(const QString& error);
    //! Handle incoming runtime log line.
    void onLogLine(const QString& line);
    //! Handle traffic-updated signal from process manager.
    void onTrafficUpdated();
    void onProfileModelDataChanged();
    //! Poll Xray API traffic stats.
    void pollTrafficStats();
    //! Tick handler for speed-test phase timings/samples.
    void onSpeedTestTick();
    //! Read bytes during active speed-test request.
    void onSpeedTestReadyRead();
    void onSpeedTestDownloadProgress(qint64 received, qint64 total);
    //! Update upload counters during upload phase.
    void onSpeedTestUploadProgress(qint64 sent, qint64 total);
    //! Handle speed-test request completion.
    void onSpeedTestFinished();
    void onPublicIpFinished();

private:
    struct SubscriptionEntry {
        QString id;
        QString name;
        QString group;
        QString url;
    };

    struct ProfileGroupOptions {
        QString key;
        QString name;
        bool enabled = true;
        bool exclusive = false;
        QString badge;
    };

    struct RoutingRule {
        QString id;
        QString targetType;
        QString targetValue;
        QString action;
        QString profileId;
        bool enabled = true;
    };

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
    void runNextSpeedTestLatencyProbe();
    void startPingPhase();
    void startDownloadPhase();
    void startUploadPhase();
    void startAnalyzePhase();

    /**
     * @brief Finalize speed-test workflow.
     * @param ok True on successful completion.
     * @param error Error message when failed.
     */
    void finishSpeedTest(bool ok, const QString& error = QString());
    QUrl speedTestDownloadUrlForSizeMb(int sizeMb) const;
    QList<QUrl> speedTestDownloadFallbackUrls(int sizeMb) const;
    QList<QUrl> speedTestUploadFallbackUrls(int sizeMb) const;
    int normalizedSpeedTestSizeMb(int requested) const;
    void updateSpeedTestSampling(bool finalizeWindow = false);
    void finalizeSpeedTestLatencyMetrics();
    void finalizeSpeedTestQualityMetrics();
    static int percentileLatency(const QVector<int>& samples, double percentile);

    /**
     * @brief Enable/disable system proxy according to settings/state.
     * @param enable Desired proxy state.
     * @param force Force operation even if state appears unchanged.
     */
    void applySystemProxy(bool enable, bool force = false);
    void applyKillSwitchState(const QString& reason = QString());

    /**
     * @brief Append system-tagged line to recent logs.
     * @param message Log text.
     */
    void appendSystemLog(const QString& message);
    void completeRuntimeConnectedStartup(bool restoredExistingMobileRuntime = false);
    void syncMobileRuntimeState(const QString& reason);
    void gateRuntimeStartupUntilProxyReady(quint64 connectAttempt);

    /**
     * @brief Perform local proxy self-connectivity check.
     */
    void runProxySelfCheck();
    void runProxySelfCheckAttempt(int attempt);

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
    void syncLegacyRoutingFieldsFromRules();
    bool parseRoutingRuleFromVariantMap(const QVariantMap& map, RoutingRule *rule, QString *errorMessage = nullptr) const;
    QVariantMap routingRuleToVariantMap(const RoutingRule& rule) const;
    QVariantMap validateRoutingRuleData(
        const QString& targetType,
        const QString& targetValue,
        const QString& action,
        const QString& profileId,
        bool enforceProfileExists) const;
    bool setRoutingRules(const QList<RoutingRule>& rules, bool persist, bool syncLegacyFields, bool emitChangeSignal);
    void loadRoutingRulesFromSettings(const QString& rawRulesJson);
    QString routingRulesJson() const;
    bool appendRoutingRuleToConfig(QJsonArray *rules,
                                   const RoutingRule& rule,
                                   const QString& activeProfileId,
                                   bool processRoutingAllowed,
                                   QString *errorMessage = nullptr) const;
    void reconnectActiveProfileForRoutingChange(const QString& reason);
    QVariantList collectAvailableAppRuleItems() const;
    QString usageScopeProfileId() const;

    /**
     * @brief Parse newline/comma-separated rules.
     * @param value Raw rule text.
     * @return Normalized rule list.
     */
    static QStringList parseRules(const QString& value);
    static QString normalizeLanSharingMode(const QString& rawMode);
    static QStringList parseDnsServers(const QString& value);
    static QString normalizeDnsServer(const QString& value);
    QString defaultLanBindAddress() const;
    QString sanitizedLanBindAddress(const QString& requestedAddress, bool allowAny) const;
    void applyLanSharingDefaultsForMode(const QString& normalizedMode, bool forceDefaults);
    void maybeReconnectForLanSharingChange(const QString& reason);
    void updateMemoryUsage();
    void clearLogsInternal();
    void maybeReconnectToPendingProfile();
    void updatePerProfileUsageCounters(qint64 nextRx, qint64 nextTx);
    void resetPerProfileUsageSamples();
    void recordProfileUsageDelta(const QString& profileId, qint64 rxDelta, qint64 txDelta);
    void beginProfileUsageSession(const QString& profileId);
    void endProfileUsageSession(const QString& profileId);
    QVariantMap profileUsageSummaryForId(const QString& profileId) const;
    QVariantList profileUsageHistoryForId(const QString& profileId, const QString& period, int limit) const;
    QVariantList profileUsageSessionsForId(const QString& profileId, int limit) const;
    QVariantMap latestUsageSnapshotForId(const QString& profileId) const;
    QString currentProfileUsageText(const QString& period) const;
    void loadProfileUsage();
    void saveProfileUsage() const;
    void scheduleProfileUsageSave();
    void cleanupDetachedHelpers();
    void stopPrivilegedTunRuntimeByPidPath();
    void killProcessByPid(qint64 pid) const;
    QList<qint64> managedRuntimePidsByConfig() const;
    void cleanupOrphanManagedRuntimeProcesses(qint64 keepPid = -1);
    void writeManagedRuntimeRecord(qint64 pid, const QString& mode);
    void clearManagedRuntimeRecord();
    bool tryLoadManagedRuntimeRecord(QJsonObject *record) const;
    bool cleanupManagedRuntimeFromRecord(const QJsonObject& record, const QString& reason);
    void cleanupManagedRuntimeOnStartup();
    bool isProcessLikelyManagedXray(qint64 pid, const QString& expectedExecutablePath) const;
    static bool isProcessAlive(qint64 pid);
    static QString processExecutablePath(qint64 pid);

    /**
     * @brief Query traffic stats through Xray API endpoint.
     * @param uplinkBytes Output uplink bytes.
     * @param downlinkBytes Output downlink bytes.
     * @param errorMessage Optional error output.
     * @return True on successful query/parse.
     */
    bool queryTrafficStatsFromApi(qint64 *uplinkBytes, qint64 *downlinkBytes, QString *errorMessage);
    QString privilegedTunHelperPath() const;
    bool ensurePrivilegedTunHelper(QString *errorMessage);
    bool sendPrivilegedTunHelperRequest(
        const QJsonObject& request,
        QJsonObject *response,
        QString *errorMessage,
        int timeoutMs = 4000
    );
    void shutdownPrivilegedTunHelper();
    bool requestElevationForTun(QString *errorMessage);
    bool startPrivilegedTunProcess(QString *errorMessage);
    bool stopPrivilegedTunProcess(QString *errorMessage);
    void pollPrivilegedTunLogs();
    bool applyMacTunRoutes(QString *errorMessage);
    void clearMacTunRoutes();

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
    void loadSubscriptions();
    void saveSubscriptions() const;
    int removeProfilesBySourceId(const QString& sourceId, bool preserveProtectedProfiles = true);
    int pruneOrphanSubscriptions();
    int importLinks(
        const QStringList& links,
        const QString& sourceId = QString(),
        const QString& sourceName = QString(),
        const QString& groupName = QString(),
        int *lastImportedIndex = nullptr
    );
    void beginSubscriptionOperation(const QString& message);
    void endSubscriptionOperation(const QString& message);
    void startSubscriptionFetch(const SubscriptionEntry& entry, bool fromRefresh);
    void finishRefreshSubscriptions();
    void refreshProfileGroups();
    static QString normalizeGroupName(const QString& groupName);
    static QString normalizeGroupKey(const QString& groupName);
    static QString deriveSubscriptionName(const QString& url);
    void recomputeProfileStats();
    void scheduleLogsChanged();
    void applyPowerPolicy();
    int startupSelfCheckDelayMs() const;
    int profileGroupOptionsIndex(const QString& groupName) const;
    ProfileGroupOptions profileGroupOptionsFor(const QString& groupName) const;
    void upsertProfileGroupOptions(const ProfileGroupOptions& options, bool save = true);

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
    qint64 m_memoryUsageBytes = 0;
    bool m_speedTestRunning = false;
    QString m_speedTestState = QString::fromUtf8("Idle");
    QString m_speedTestPhase = QString::fromUtf8("Idle");
    int m_speedTestElapsedSec = 0;
    int m_speedTestDurationSec = 18;
    double m_speedTestProgress = 0.0;
    double m_speedTestCurrentMbps = 0.0;
    double m_speedTestPeakMbps = 0.0;
    double m_speedTestAverageMbps = 0.0;
    int m_speedTestPingMs = -1;
    int m_speedTestJitterMs = -1;
    double m_speedTestPacketLossPct = 0.0;
    int m_speedTestRouteStabilityPct = 0;
    int m_speedTestQualityScore = -1;
    int m_speedTestLatencyMinMs = -1;
    int m_speedTestLatencyMaxMs = -1;
    double m_speedTestDownloadMbps = 0.0;
    double m_speedTestUploadMbps = 0.0;
    QString m_speedTestError;
    QStringList m_speedTestHistory;
    qint64 m_speedTestBytesReceived = 0;
    qint64 m_speedTestLastBytes = 0;
    int m_speedTestAttempt = 0;
    int m_speedTestPingSampleCount = 0;
    qint64 m_speedTestPingTotalMs = 0;
    int m_speedTestLatencyAttemptCount = 0;
    int m_speedTestLatencySuccessCount = 0;
    QVector<int> m_speedTestLatencySamples;
    bool m_speedTestUploadMode = false;
    qint64 m_speedTestPhaseBytes = 0;
    qint64 m_speedTestExpectedBytes = 0;
    qint64 m_speedTestSampleWindowStartMs = -1;
    qint64 m_speedTestSampleWindowStartBytes = 0;
    qint64 m_speedTestMeasuredBytes = 0;
    qint64 m_speedTestMeasuredDurationMs = 0;
    qint64 m_speedTestLastProgressElapsedMs = 0;
    qint64 m_speedTestWarmupUntilMs = 0;
    bool m_speedTestCancelledByUser = false;
    bool m_speedTestUsingDirectFallback = false;
    int m_speedTestSelectedSizeMb = 10;
    QString m_speedTestDownloadEndpointTemplate = QString::fromUtf8("https://speed.cloudflare.com/__down?bytes=%1");
    QElapsedTimer m_speedTestRequestTimer;
    QElapsedTimer m_speedTestPhaseTimer;
    QElapsedTimer m_speedTestSampleTimer;

    int m_currentProfileIndex = -1;
    QString m_currentProfileId;
    QSet<QString> m_securityWarningDismissedProfileIds;
    QString m_publicIpAddress;
    bool m_publicIpRefreshing = false;
    int m_publicIpRetryCount = 0;
    int m_publicIpRetryLimit = 2;

    QString m_xrayExecutablePath;
    QString m_xrayVersion = QString::fromUtf8("Unknown");
    bool m_loggingEnabled = true;
    bool m_autoPingProfiles = false;
    QList<SubscriptionEntry> m_subscriptionEntries;
    QList<ProfileGroupOptions> m_profileGroupOptions;
    bool m_subscriptionBusy = false;
    QString m_subscriptionMessage;
    QList<SubscriptionEntry> m_subscriptionRefreshQueue;
    int m_subscriptionRefreshSuccessCount = 0;
    int m_subscriptionRefreshFailCount = 0;
    QStringList m_profileGroups;
    QString m_currentProfileGroup = QString::fromUtf8("All");
    int m_profileCount = 0;
    int m_filteredProfileCount = 0;
    int m_bestPingMs = -1;
    int m_worstPingMs = -1;
    double m_profileScore = 0.0;
    bool m_useSystemProxy = false;
    bool m_systemProxyApplied = false;
    bool m_proxyApplyInFlight = false;
    int m_pendingProxyApplyState = -1; // -1 none, 0 disable, 1 enable
    bool m_pendingProxyApplyForce = false;
    bool m_tunMode = false;
    bool m_effectiveTunMode = false;
    bool m_killSwitchEnabled = false;
    bool m_autoDisableSystemProxyOnDisconnect = false;
    bool m_whitelistMode = false;
    QString m_proxyDomainRules;
    QString m_directDomainRules;
    QString m_blockDomainRules;
    QString m_customDnsServers;
    QString m_lanSharingMode = QString::fromUtf8("console");
    bool m_lanSharingEnabled = false;
    QString m_lanSharingBindAddress;
    bool m_lanSharingAllowAnyBind = false;
    QString m_lanSharingInterface;
    bool m_lanGatewayExperimentalEnabled = false;
    QString m_proxyAppRules;
    QString m_directAppRules;
    QString m_blockAppRules;
    QList<RoutingRule> m_routingRules;
    bool m_processRoutingSupported = false;
    bool m_processRoutingSupportChecked = false;
    QVariantList m_cachedAppRuleItems;
    std::atomic_bool m_appRuleScanInFlight {false};
    std::atomic<quint64> m_appRuleScanRequestId {0};

    QString m_dataDirectory;
    QString m_profilesPath;
    QString m_subscriptionsPath;
    QString m_runtimeConfigPath;
    QString m_profileUsagePath;
    QJsonObject m_profileUsageRoot;
    qint64 m_profileUsageLastRxSample = -1;
    qint64 m_profileUsageLastTxSample = -1;
    QString m_activeProfileUsageId;
    QString m_selectedUsageProfileId;
    QString m_usageSessionProfileId;
    qint64 m_usageSessionRxBytes = 0;
    qint64 m_usageSessionTxBytes = 0;
    QDateTime m_usageSessionStartedAt;

    ServerProfileModel *m_profileModel = nullptr;
    Updater *m_updater = nullptr;
    PowerModeManager *m_powerModeManager = nullptr;
    SystemProxyManager *m_systemProxyManager = nullptr;
    VpnRuntimeBackend *m_runtimeBackend = nullptr;
    bool m_runtimeIsMobile = false;
    bool m_runtimeIsDesktop = true;
    bool m_runtimeSupportsTun = true;
    bool m_runtimeSupportsSystemProxy = true;
    bool m_runtimeSupportsPerAppRouting = true;
    bool m_runtimeSupportsAutoUpdate = true;
    bool m_runtimeRequiresVpnPermission = false;
    bool m_runtimeRequiresForegroundService = false;
    bool m_runtimeRequiresNetworkExtension = false;
    XrayConfigBuilder::BuildOptions m_buildOptions;
    QTimer m_memoryUsageTimer;
    QTimer m_statsPollTimer;
    QTimer m_speedTestTimer;
    QNetworkAccessManager m_speedTestNetworkManager;
    QNetworkAccessManager m_subscriptionNetworkManager;
    QNetworkAccessManager m_publicIpNetworkManager;
    QNetworkReply *m_speedTestReply = nullptr;
    QNetworkReply *m_publicIpReply = nullptr;
    QTimer m_publicIpRetryTimer;
    bool m_statsPolling = false;
    quint64 m_statsPollGeneration = 0;
    int m_statsQueryFailureCount = 0;
    bool m_stoppingProcess = false;
    int m_pendingReconnectProfileIndex = -1;
    bool m_startedWithTunElevationRequest = false;
    bool m_privilegedTunManaged = false;
    bool m_privilegedTunHelperReady = false;
    quint16 m_privilegedTunHelperPort = 0;
    qint64 m_privilegedTunHelperPid = 0;
    QString m_privilegedTunHelperToken;
    QString m_privilegedTunPidPath;
    QString m_privilegedTunLogPath;
    qint64 m_privilegedTunLogOffset = 0;
    QByteArray m_privilegedTunLogBuffer;
    QTimer m_privilegedTunLogTimer;
    QTimer m_profileUsageSaveTimer;
    QString m_managedRuntimeRecordPath;
    qint64 m_privilegedTunRuntimePid = -1;
    std::atomic<quint64> m_connectAttemptCounter {0};
    std::atomic_bool m_disconnectRequested {false};
    std::atomic_bool m_shutdownInProgress {false};
    QTimer m_logsFlushTimer;
    bool m_logsDirty = false;
    QString m_selectedTunInterfaceName;
    QString m_activeProfileAddress;
    QString m_lastTunServerIp;
};

#include "vpncontroller.moc"

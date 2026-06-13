#include "powermodemanager.hpp"

#include <QCoreApplication>
#include <QGuiApplication>
#include <QNetworkInformation>
#include <QRandomGenerator>
#include <QSettings>
#include <QTimer>

#include <array>
#include <algorithm>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

namespace {
constexpr int kBatteryLowSuggestThreshold = 20;
constexpr int kInstabilityFallbackCount = 5;
constexpr qint64 kInstabilityWindowMs = 5 * 60 * 1000;
constexpr std::array<int, 6> kReconnectBackoffMs {1000, 2000, 5000, 10000, 30000, 60000};
#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
#endif

QString normalizedNetworkType(QString value)
{
    value = value.trimmed().toLower();
    if (value == QString::fromUtf8("wifi") || value == QString::fromUtf8("wi-fi") || value == QString::fromUtf8("wlan")) {
        return QString::fromUtf8("wifi");
    }
    if (value == QString::fromUtf8("cell") || value == QString::fromUtf8("cellular") || value == QString::fromUtf8("mobile")) {
        return QString::fromUtf8("cellular");
    }
    if (value == QString::fromUtf8("ethernet") || value == QString::fromUtf8("wired")) {
        return QString::fromUtf8("ethernet");
    }
    if (value == QString::fromUtf8("desktop") || value == QString::fromUtf8("vpn") || value == QString::fromUtf8("bluetooth")) {
        return value;
    }
    if (value.isEmpty()) {
        return QString::fromUtf8("unknown");
    }
    return value;
}

QVariantMap policyToVariant(const PowerModeManager::RuntimePolicy& policy)
{
    return QVariantMap {
        {QString::fromUtf8("statsPollIntervalMs"), policy.statsPollIntervalMs},
        {QString::fromUtf8("memorySampleIntervalMs"), policy.memorySampleIntervalMs},
        {QString::fromUtf8("privilegedTunLogIntervalMs"), policy.privilegedTunLogIntervalMs},
        {QString::fromUtf8("logsFlushIntervalMs"), policy.logsFlushIntervalMs},
        {QString::fromUtf8("speedTestTickIntervalMs"), policy.speedTestTickIntervalMs},
        {QString::fromUtf8("publicIpRetryDelayMs"), policy.publicIpRetryDelayMs},
        {QString::fromUtf8("startupSelfCheckDelayMs"), policy.startupSelfCheckDelayMs},
        {QString::fromUtf8("uiStatsRefreshIntervalMs"), policy.uiStatsRefreshIntervalMs},
        {QString::fromUtf8("uiGaugeRefreshIntervalMs"), policy.uiGaugeRefreshIntervalMs},
        {QString::fromUtf8("pauseDecorativeUiWhenBackgrounded"), policy.pauseDecorativeUiWhenBackgrounded},
        {QString::fromUtf8("reduceFakeDnsSniffing"), policy.reduceFakeDnsSniffing},
        {QString::fromUtf8("lightweightRoutingPreferred"), policy.lightweightRoutingPreferred},
        {QString::fromUtf8("conservativeReconnect"), policy.conservativeReconnect},
        {QString::fromUtf8("strongKeepalive"), policy.strongKeepalive},
        {QString::fromUtf8("realTimeStats"), policy.realTimeStats}
    };
}

QString networkTypeFromTransport(QNetworkInformation::TransportMedium medium, bool metered)
{
    switch (medium) {
    case QNetworkInformation::TransportMedium::Ethernet:
        return QString::fromUtf8("ethernet");
    case QNetworkInformation::TransportMedium::Cellular:
        return QString::fromUtf8("cellular");
    case QNetworkInformation::TransportMedium::WiFi:
        return QString::fromUtf8("wifi");
    case QNetworkInformation::TransportMedium::Bluetooth:
        return QString::fromUtf8("bluetooth");
    case QNetworkInformation::TransportMedium::Unknown:
    default:
        return metered ? QString::fromUtf8("cellular") : QString::fromUtf8("unknown");
    }
}

QString displayLabelForNetworkType(const QString& value)
{
    const QString normalized = normalizedNetworkType(value);
    if (normalized == QString::fromUtf8("wifi")) {
        return QString::fromUtf8("Wi-Fi");
    }
    if (normalized == QString::fromUtf8("cellular")) {
        return QString::fromUtf8("Cellular");
    }
    if (normalized == QString::fromUtf8("ethernet")) {
        return QString::fromUtf8("Ethernet");
    }
    if (normalized == QString::fromUtf8("vpn")) {
        return QString::fromUtf8("VPN");
    }
    if (normalized == QString::fromUtf8("desktop")) {
        return QString::fromUtf8("Desktop");
    }
    if (normalized == QString::fromUtf8("bluetooth")) {
        return QString::fromUtf8("Bluetooth");
    }
    return QString::fromUtf8("Unknown");
}

QString desktopBatteryStatus()
{
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    return QString::fromUtf8("Unavailable");
#else
    return QString::fromUtf8("Desktop");
#endif
}
} // namespace

PowerModeManager::PowerModeManager(QObject *parent)
    : QObject(parent)
{
    m_effectivePolicy = basePolicy(m_mode);

    if (qGuiApp) {
        m_backgrounded = qGuiApp->applicationState() != Qt::ApplicationActive;
        connect(qGuiApp, &QGuiApplication::applicationStateChanged, this, [this](Qt::ApplicationState state) {
            const bool nextBackgrounded = state != Qt::ApplicationActive;
            if (m_backgrounded == nextBackgrounded) {
                return;
            }
            m_backgrounded = nextBackgrounded;
            emitAdaptiveChanged(nextBackgrounded
                                    ? QString::fromUtf8("application backgrounded")
                                    : QString::fromUtf8("application foregrounded"));
        });
    }

    initializePlatformState();
    QTimer::singleShot(0, this, &PowerModeManager::refreshPlatformState);
}

PowerModeManager::Mode PowerModeManager::mode() const
{
    return m_mode;
}

QString PowerModeManager::modeName() const
{
    return modeToString(m_mode);
}

QString PowerModeManager::effectiveModeName() const
{
    return modeName();
}

QStringList PowerModeManager::modeOptions() const
{
    return {QString::fromUtf8("Save"), QString::fromUtf8("Normal"), QString::fromUtf8("High Performance")};
}

PowerModeManager::RuntimePolicy PowerModeManager::effectivePolicy() const
{
    return m_effectivePolicy;
}

QVariantMap PowerModeManager::effectivePolicyVariant() const
{
    return policyToVariant(m_effectivePolicy);
}

QVariantMap PowerModeManager::visualPolicyVariant() const
{
    const bool save = m_mode == Mode::Save || m_batterySaver || (!m_screenOn && !m_charging);
    const bool high = m_mode == Mode::HighPerformance && !m_batterySaver;
    return QVariantMap {
        {QString::fromUtf8("animationsEnabled"), !save},
        {QString::fromUtf8("decorativeAnimationsEnabled"), high || m_mode == Mode::Normal},
        {QString::fromUtf8("particlesEnabled"), high},
        {QString::fromUtf8("effectsEnabled"), !save},
        {QString::fromUtf8("blurEnabled"), !save},
        {QString::fromUtf8("shadowEnabled"), !save},
        {QString::fromUtf8("chartAnimationIntervalMs"), m_effectivePolicy.uiStatsRefreshIntervalMs},
        {QString::fromUtf8("gaugeRefreshIntervalMs"), m_effectivePolicy.uiGaugeRefreshIntervalMs},
        {QString::fromUtf8("pauseInBackground"), save || m_effectivePolicy.pauseDecorativeUiWhenBackgrounded}
    };
}

QVariantMap PowerModeManager::diagnosticsVariant() const
{
    return QVariantMap {
        {QString::fromUtf8("reconnectAttempts"), m_reconnectAttemptCount},
        {QString::fromUtf8("reconnectSuccesses"), m_reconnectSuccessCount},
        {QString::fromUtf8("instabilityCount"), m_instabilityCount},
        {QString::fromUtf8("timerWakeups"), QVariant::fromValue(m_timerWakeupCount)},
        {QString::fromUtf8("timerWakeupsBySource"), m_timerWakeupsBySource},
        {QString::fromUtf8("lastCpuUsagePercent"), m_lastCpuUsagePercent},
        {QString::fromUtf8("backgrounded"), m_backgrounded},
        {QString::fromUtf8("screenOn"), m_screenOn},
        {QString::fromUtf8("charging"), m_charging},
        {QString::fromUtf8("batterySaver"), m_batterySaver},
        {QString::fromUtf8("batteryOptimizationIgnored"), m_batteryOptimizationIgnored},
        {QString::fromUtf8("batteryLevel"), m_batteryLevel},
        {QString::fromUtf8("batteryStatus"), m_batteryStatus},
        {QString::fromUtf8("networkType"), m_networkType},
        {QString::fromUtf8("networkStatus"), m_networkStatus}
    };
}

bool PowerModeManager::backgrounded() const { return m_backgrounded; }
bool PowerModeManager::screenOn() const { return m_screenOn; }
bool PowerModeManager::charging() const { return m_charging; }
bool PowerModeManager::batterySaver() const { return m_batterySaver; }
int PowerModeManager::batteryLevel() const { return m_batteryLevel; }
QString PowerModeManager::networkType() const { return m_networkType; }

void PowerModeManager::loadSettings()
{
    QSettings settings;
    bool ok = false;
    const Mode loaded = modeFromString(settings.value(QString::fromUtf8("power/mode"), QString::fromUtf8("Normal")).toString(), &ok);
    setMode(ok ? loaded : Mode::Normal);
}

void PowerModeManager::saveSettings() const
{
    QSettings settings;
    settings.setValue(QString::fromUtf8("power/mode"), modeName());
}

void PowerModeManager::setMode(Mode mode)
{
    if (m_mode == mode) {
        return;
    }
    const QString previous = modeName();
    m_mode = mode;
    resetReconnectBackoff();
    emit modeChanged();
    recomputeEffectivePolicy(QString::fromUtf8("mode changed from %1 to %2").arg(previous, modeName()));
    emit debugLog(QString::fromUtf8("[PowerMode] Mode changed: %1 -> %2").arg(previous, modeName()));
}

void PowerModeManager::setModeName(const QString& value)
{
    bool ok = false;
    const Mode nextMode = modeFromString(value, &ok);
    if (ok) {
        setMode(nextMode);
    }
}

void PowerModeManager::setScreenOn(bool value)
{
    if (m_screenOn == value) {
        return;
    }
    m_screenOn = value;
    emitAdaptiveChanged(value ? QString::fromUtf8("screen on") : QString::fromUtf8("screen off"));
}

void PowerModeManager::setCharging(bool value)
{
    if (m_charging == value) {
        return;
    }
    m_charging = value;
    emitAdaptiveChanged(value ? QString::fromUtf8("charging") : QString::fromUtf8("not charging"));
}

void PowerModeManager::setBatterySaver(bool value)
{
    if (m_batterySaver == value) {
        return;
    }
    m_batterySaver = value;
    emitAdaptiveChanged(value ? QString::fromUtf8("battery saver enabled") : QString::fromUtf8("battery saver disabled"));
}

void PowerModeManager::setBatteryLevel(int value)
{
    const int normalized = value < 0 ? -1 : std::clamp(value, 0, 100);
    if (m_batteryLevel == normalized) {
        return;
    }
    m_batteryLevel = normalized;
    updateBatteryStatusLabel();
    emitAdaptiveChanged(QString::fromUtf8("battery level changed"));
}

void PowerModeManager::setNetworkType(const QString& value)
{
    const QString normalized = normalizedNetworkType(value);
    if (m_networkType == normalized) {
        return;
    }
    m_networkType = normalized;
    updateNetworkStatusLabel();
    emitAdaptiveChanged(QString::fromUtf8("network type changed to %1").arg(m_networkType));
}

void PowerModeManager::setAdaptiveState(bool screenOn, bool charging, bool batterySaver, int batteryLevel, const QString& networkType)
{
    bool changed = false;
    const int normalizedBattery = batteryLevel < 0 ? -1 : std::clamp(batteryLevel, 0, 100);
    const QString normalizedNetwork = normalizedNetworkType(networkType);
    if (m_screenOn != screenOn) { m_screenOn = screenOn; changed = true; }
    if (m_charging != charging) { m_charging = charging; changed = true; }
    if (m_batterySaver != batterySaver) { m_batterySaver = batterySaver; changed = true; }
    if (m_batteryLevel != normalizedBattery) { m_batteryLevel = normalizedBattery; changed = true; }
    if (m_networkType != normalizedNetwork) { m_networkType = normalizedNetwork; changed = true; }
    if (changed) {
        updateBatteryStatusLabel();
        updateNetworkStatusLabel();
        emitAdaptiveChanged(QString::fromUtf8("platform adaptive state updated"));
    }
}

QString PowerModeManager::classifyTransport(const QString& network, const QString& security, const QString& alpn) const
{
    const QString net = network.trimmed().toLower().isEmpty() ? QString::fromUtf8("tcp") : network.trimmed().toLower();
    const QString sec = security.trimmed().toLower();
    const QString normalizedAlpn = alpn.trimmed().toLower();

    if (net == QString::fromUtf8("quic") || normalizedAlpn.contains(QString::fromUtf8("h3"))) {
        return transportClassToString(TransportPowerClass::HighPower);
    }
    if (net == QString::fromUtf8("grpc")) {
        return transportClassToString(TransportPowerClass::HighPower);
    }
    if (net == QString::fromUtf8("xhttp") || normalizedAlpn.contains(QString::fromUtf8("h2"))) {
        return transportClassToString(TransportPowerClass::Balanced);
    }
    if (net == QString::fromUtf8("ws")) {
        return transportClassToString(sec == QString::fromUtf8("tls") || sec == QString::fromUtf8("reality")
                                          ? TransportPowerClass::Balanced
                                          : TransportPowerClass::BatteryFriendly);
    }
    if (net == QString::fromUtf8("tcp")) {
        return transportClassToString(sec == QString::fromUtf8("tls") || sec == QString::fromUtf8("reality")
                                          ? TransportPowerClass::BatteryFriendly
                                          : TransportPowerClass::Balanced);
    }
    return transportClassToString(TransportPowerClass::Balanced);
}

QString PowerModeManager::transportPowerDescription(const QString& powerClass) const
{
    const QString normalized = powerClass.trimmed().toLower();
    if (normalized.contains(QString::fromUtf8("battery"))) {
        return QString::fromUtf8("Stable stream-oriented transports usually wake the radio and CPU less often on mobile devices.");
    }
    if (normalized.contains(QString::fromUtf8("high"))) {
        return QString::fromUtf8("Multiplexed or UDP-heavy transports can improve latency or throughput but may keep radios and timers active more often.");
    }
    return QString::fromUtf8("Balanced transports trade compatibility and performance without intentionally increasing polling or keepalive pressure.");
}

void PowerModeManager::resetDiagnostics()
{
    m_reconnectAttemptCount = 0;
    m_reconnectSuccessCount = 0;
    m_instabilityCount = 0;
    m_timerWakeupCount = 0;
    m_timerWakeupsBySource.clear();
    m_lastCpuUsagePercent = -1.0;
    m_recentInstabilityEpochMs.clear();
    resetReconnectBackoff();
    emit diagnosticsChanged();
}

int PowerModeManager::nextReconnectDelayMs()
{
    const int index = std::min(m_reconnectBackoffIndex, static_cast<int>(kReconnectBackoffMs.size()) - 1);
    const int baseDelay = kReconnectBackoffMs.at(static_cast<size_t>(index));
    if (m_reconnectBackoffIndex < static_cast<int>(kReconnectBackoffMs.size()) - 1) {
        ++m_reconnectBackoffIndex;
    }
    const int jitterRange = std::max(50, baseDelay / 5);
    const int jitter = QRandomGenerator::global()->bounded(-jitterRange, jitterRange + 1);
    return std::max(250, baseDelay + jitter);
}

void PowerModeManager::resetReconnectBackoff()
{
    m_reconnectBackoffIndex = 0;
}

void PowerModeManager::recordReconnectAttempt()
{
    ++m_reconnectAttemptCount;
    emit diagnosticsChanged();
}

void PowerModeManager::recordReconnectSuccess()
{
    ++m_reconnectSuccessCount;
    resetReconnectBackoff();
    emit diagnosticsChanged();
}

void PowerModeManager::recordRuntimeInstability(const QString& reason)
{
    ++m_instabilityCount;
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    m_recentInstabilityEpochMs.append(now);
    while (!m_recentInstabilityEpochMs.isEmpty() && now - m_recentInstabilityEpochMs.front() > kInstabilityWindowMs) {
        m_recentInstabilityEpochMs.removeFirst();
    }
    emit diagnosticsChanged();
    maybeFallbackToNormal(reason);
}

void PowerModeManager::recordTimerWakeup(const QString& source)
{
    ++m_timerWakeupCount;
    const QString key = source.trimmed().isEmpty() ? QString::fromUtf8("unknown") : source.trimmed();
    m_timerWakeupsBySource.insert(key, m_timerWakeupsBySource.value(key).toULongLong() + 1ULL);
    if (m_timerWakeupCount % 25 == 0) {
        emit diagnosticsChanged();
    }
}

void PowerModeManager::recordCpuUsageSample(double percent)
{
    if (percent < 0.0) {
        return;
    }
    m_lastCpuUsagePercent = percent;
    emit diagnosticsChanged();
}

void PowerModeManager::refreshPlatformState()
{
#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const jint batteryLevel = QJniObject::callStaticMethod<jint>(
            kAndroidRuntimeBridgeClass, "batteryLevel", "()I");
        const bool charging = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass, "isCharging", "()Z");
        const bool batterySaver = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass, "isBatterySaverEnabled", "()Z");
        const bool batteryOptimizationIgnored = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass, "isIgnoringBatteryOptimizations", "()Z");
        const bool screenOn = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass, "isScreenOn", "()Z");
        const QJniObject networkObject = QJniObject::callStaticObjectMethod(
            kAndroidRuntimeBridgeClass, "networkType", "()Ljava/lang/String;");
        const QString network = networkObject.isValid() ? networkObject.toString() : QString();
        const bool optimizationChanged = m_batteryOptimizationIgnored != batteryOptimizationIgnored;
        m_batteryOptimizationIgnored = batteryOptimizationIgnored;
        setAdaptiveState(screenOn, charging, batterySaver, static_cast<int>(batteryLevel), network);
        if (optimizationChanged) {
            emit diagnosticsChanged();
        }
        return;
    }
#endif

    bool changed = false;
    QString detectedNetwork = m_networkType;
    if (QNetworkInformation::loadDefaultBackend()) {
        if (auto *info = QNetworkInformation::instance()) {
            detectedNetwork = networkTypeFromTransport(info->transportMedium(), info->isMetered());
            if (detectedNetwork == QString::fromUtf8("unknown")) {
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
                detectedNetwork = QString::fromUtf8("wifi");
#elif defined(Q_OS_MACOS) || defined(Q_OS_WIN) || defined(Q_OS_LINUX)
                detectedNetwork = QString::fromUtf8("desktop");
#endif
            }
        }
    }

#if defined(Q_OS_MACOS) || defined(Q_OS_WIN) || defined(Q_OS_LINUX)
    if (detectedNetwork == QString::fromUtf8("unknown")) {
        detectedNetwork = QString::fromUtf8("desktop");
    }
    if (m_batteryStatus != desktopBatteryStatus()) {
        m_batteryStatus = desktopBatteryStatus();
        changed = true;
    }
#endif

    const QString normalizedNetwork = normalizedNetworkType(detectedNetwork);
    if (m_networkType != normalizedNetwork) {
        m_networkType = normalizedNetwork;
        updateNetworkStatusLabel();
        changed = true;
    }
    updateBatteryStatusLabel();
    if (changed) {
        emitAdaptiveChanged(QString::fromUtf8("platform state refreshed"));
    } else {
        emit diagnosticsChanged();
    }
}

QString PowerModeManager::modeToString(Mode mode)
{
    switch (mode) {
    case Mode::Save:
        return QString::fromUtf8("Save");
    case Mode::HighPerformance:
        return QString::fromUtf8("High Performance");
    case Mode::Normal:
    default:
        return QString::fromUtf8("Normal");
    }
}

PowerModeManager::Mode PowerModeManager::modeFromString(const QString& value, bool *ok)
{
    const QString normalized = QString(value).trimmed().toLower().remove(QChar(' ')).remove(QChar('-')).remove(QChar('_'));
    if (ok) {
        *ok = true;
    }
    if (normalized == QString::fromUtf8("save") || normalized == QString::fromUtf8("powersave")) {
        return Mode::Save;
    }
    if (normalized == QString::fromUtf8("normal") || normalized == QString::fromUtf8("balanced")) {
        return Mode::Normal;
    }
    if (normalized == QString::fromUtf8("highperformance") || normalized == QString::fromUtf8("performance")) {
        return Mode::HighPerformance;
    }
    if (ok) {
        *ok = false;
    }
    return Mode::Normal;
}

QString PowerModeManager::transportClassToString(TransportPowerClass value)
{
    switch (value) {
    case TransportPowerClass::BatteryFriendly:
        return QString::fromUtf8("Battery Friendly");
    case TransportPowerClass::HighPower:
        return QString::fromUtf8("High Power");
    case TransportPowerClass::Balanced:
    default:
        return QString::fromUtf8("Balanced");
    }
}

PowerModeManager::RuntimePolicy PowerModeManager::basePolicy(Mode mode) const
{
    RuntimePolicy policy;
    switch (mode) {
    case Mode::Save:
        policy.statsPollIntervalMs = 5000;
        policy.memorySampleIntervalMs = 10000;
        policy.privilegedTunLogIntervalMs = 1000;
        policy.logsFlushIntervalMs = 500;
        policy.speedTestTickIntervalMs = 250;
        policy.publicIpRetryDelayMs = 5000;
        policy.startupSelfCheckDelayMs = 1200;
        policy.uiStatsRefreshIntervalMs = 4000;
        policy.uiGaugeRefreshIntervalMs = 250;
        policy.pauseDecorativeUiWhenBackgrounded = true;
        policy.reduceFakeDnsSniffing = true;
        policy.lightweightRoutingPreferred = true;
        policy.conservativeReconnect = true;
        policy.strongKeepalive = false;
        policy.realTimeStats = false;
        break;
    case Mode::HighPerformance:
        policy.statsPollIntervalMs = 500;
        policy.memorySampleIntervalMs = 1000;
        policy.privilegedTunLogIntervalMs = 150;
        policy.logsFlushIntervalMs = 80;
        policy.speedTestTickIntervalMs = 60;
        policy.publicIpRetryDelayMs = 1500;
        policy.startupSelfCheckDelayMs = 350;
        policy.uiStatsRefreshIntervalMs = 500;
        policy.uiGaugeRefreshIntervalMs = 16;
        policy.pauseDecorativeUiWhenBackgrounded = false;
        policy.reduceFakeDnsSniffing = false;
        policy.lightweightRoutingPreferred = false;
        policy.conservativeReconnect = false;
        policy.strongKeepalive = true;
        policy.realTimeStats = true;
        break;
    case Mode::Normal:
    default:
        break;
    }
    return policy;
}

PowerModeManager::RuntimePolicy PowerModeManager::adaptPolicy(RuntimePolicy policy) const
{
    const bool lowPowerContext = m_batterySaver || (m_batteryLevel >= 0 && m_batteryLevel <= kBatteryLowSuggestThreshold && !m_charging);
    const bool quietScreen = !m_screenOn || m_backgrounded;
    const bool cellular = m_networkType == QString::fromUtf8("cellular");

    if (lowPowerContext) {
        policy.statsPollIntervalMs = std::max(policy.statsPollIntervalMs, 6000);
        policy.memorySampleIntervalMs = std::max(policy.memorySampleIntervalMs, 10000);
        policy.uiStatsRefreshIntervalMs = std::max(policy.uiStatsRefreshIntervalMs, 5000);
        policy.uiGaugeRefreshIntervalMs = std::max(policy.uiGaugeRefreshIntervalMs, 250);
        policy.pauseDecorativeUiWhenBackgrounded = true;
        policy.reduceFakeDnsSniffing = true;
        policy.conservativeReconnect = true;
    }
    if (cellular && !m_charging) {
        policy.statsPollIntervalMs = std::max(policy.statsPollIntervalMs, 3000);
        policy.publicIpRetryDelayMs = std::max(policy.publicIpRetryDelayMs, 3500);
        policy.uiStatsRefreshIntervalMs = std::max(policy.uiStatsRefreshIntervalMs, 2500);
    }
    if (quietScreen && !m_charging) {
        policy.statsPollIntervalMs = std::max(policy.statsPollIntervalMs, 15000);
        policy.memorySampleIntervalMs = std::max(policy.memorySampleIntervalMs, 15000);
        policy.privilegedTunLogIntervalMs = std::max(policy.privilegedTunLogIntervalMs, 3000);
        policy.logsFlushIntervalMs = std::max(policy.logsFlushIntervalMs, 1000);
        policy.uiStatsRefreshIntervalMs = std::max(policy.uiStatsRefreshIntervalMs, 10000);
        policy.uiGaugeRefreshIntervalMs = std::max(policy.uiGaugeRefreshIntervalMs, 500);
        policy.pauseDecorativeUiWhenBackgrounded = true;
    }
    if (m_charging && m_mode == Mode::HighPerformance && !m_batterySaver) {
        policy.statsPollIntervalMs = std::min(policy.statsPollIntervalMs, 500);
        policy.uiGaugeRefreshIntervalMs = std::min(policy.uiGaugeRefreshIntervalMs, 16);
    }
    return policy;
}

void PowerModeManager::recomputeEffectivePolicy(const QString& reason)
{
    m_effectivePolicy = adaptPolicy(basePolicy(m_mode));
    emit effectivePolicyChanged();
    emit diagnosticsChanged();
    emit debugLog(QString::fromUtf8("[PowerMode] Policy updated (%1): stats=%2ms ui=%3ms gauge=%4ms")
                      .arg(reason)
                      .arg(m_effectivePolicy.statsPollIntervalMs)
                      .arg(m_effectivePolicy.uiStatsRefreshIntervalMs)
                      .arg(m_effectivePolicy.uiGaugeRefreshIntervalMs));
}

void PowerModeManager::emitAdaptiveChanged(const QString& reason)
{
    emit adaptiveStateChanged();
    recomputeEffectivePolicy(reason);
    maybeSuggestSaveMode();
}

void PowerModeManager::maybeSuggestSaveMode()
{
    if (m_mode == Mode::Save || m_charging) {
        return;
    }
    if (m_batterySaver) {
        emit saveModeSuggested(QString::fromUtf8("System Battery Saver is enabled."));
    } else if (m_batteryLevel >= 0 && m_batteryLevel <= kBatteryLowSuggestThreshold) {
        emit saveModeSuggested(QString::fromUtf8("Battery level is %1%. Save mode can reduce background wakeups.").arg(m_batteryLevel));
    } else if (m_networkType == QString::fromUtf8("cellular")) {
        emit saveModeSuggested(QString::fromUtf8("Cellular network detected. Save mode can reduce radio wakeups."));
    }
}

void PowerModeManager::maybeFallbackToNormal(const QString& reason)
{
    if (m_mode == Mode::Normal || m_recentInstabilityEpochMs.size() < kInstabilityFallbackCount) {
        return;
    }
    const QString fallbackReason = reason.trimmed().isEmpty()
        ? QString::fromUtf8("repeated runtime instability")
        : reason.trimmed();
    m_mode = Mode::Normal;
    resetReconnectBackoff();
    emit modeChanged();
    recomputeEffectivePolicy(QString::fromUtf8("fallback to Normal after instability"));
    emit normalModeFallbackTriggered(fallbackReason);
    emit debugLog(QString::fromUtf8("[PowerMode] Fallback to Normal: %1").arg(fallbackReason));
}

void PowerModeManager::initializePlatformState()
{
#if defined(Q_OS_MACOS) || defined(Q_OS_WIN) || defined(Q_OS_LINUX)
    m_batteryStatus = desktopBatteryStatus();
    if (m_networkType == QString::fromUtf8("unknown")) {
        m_networkType = QString::fromUtf8("desktop");
    }
#elif defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    m_batteryStatus = QString::fromUtf8("Unavailable");
#endif

    updateBatteryStatusLabel();
    updateNetworkStatusLabel();

    if (QNetworkInformation::loadDefaultBackend()) {
        if (auto *info = QNetworkInformation::instance()) {
            connect(info, &QNetworkInformation::transportMediumChanged, this, [this]() {
                refreshPlatformState();
            });
            connect(info, &QNetworkInformation::isMeteredChanged, this, [this]() {
                refreshPlatformState();
            });
        }
    }
}

void PowerModeManager::updateNetworkStatusLabel()
{
    m_networkStatus = displayLabelForNetworkType(m_networkType);
}

void PowerModeManager::updateBatteryStatusLabel()
{
    if (m_batteryLevel >= 0) {
        m_batteryStatus = QString::fromUtf8("%1%").arg(m_batteryLevel);
        return;
    }
    if (m_batteryStatus.trimmed().isEmpty() || m_batteryStatus == QString::fromUtf8("Unknown")) {
        m_batteryStatus = desktopBatteryStatus();
    }
}

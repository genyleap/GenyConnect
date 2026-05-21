#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVector>

class PowerModeManager final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString modeName READ modeName WRITE setModeName NOTIFY modeChanged)
    Q_PROPERTY(QString effectiveModeName READ effectiveModeName NOTIFY effectivePolicyChanged)
    Q_PROPERTY(QStringList modeOptions READ modeOptions CONSTANT)
    Q_PROPERTY(QVariantMap effectivePolicy READ effectivePolicyVariant NOTIFY effectivePolicyChanged)
    Q_PROPERTY(QVariantMap visualPolicy READ visualPolicyVariant NOTIFY effectivePolicyChanged)
    Q_PROPERTY(QVariantMap diagnostics READ diagnosticsVariant NOTIFY diagnosticsChanged)
    Q_PROPERTY(bool backgrounded READ backgrounded NOTIFY adaptiveStateChanged)
    Q_PROPERTY(bool screenOn READ screenOn WRITE setScreenOn NOTIFY adaptiveStateChanged)
    Q_PROPERTY(bool charging READ charging WRITE setCharging NOTIFY adaptiveStateChanged)
    Q_PROPERTY(bool batterySaver READ batterySaver WRITE setBatterySaver NOTIFY adaptiveStateChanged)
    Q_PROPERTY(int batteryLevel READ batteryLevel WRITE setBatteryLevel NOTIFY adaptiveStateChanged)
    Q_PROPERTY(QString networkType READ networkType WRITE setNetworkType NOTIFY adaptiveStateChanged)

public:
    enum class Mode {
        Save,
        Normal,
        HighPerformance
    };
    Q_ENUM(Mode)

    enum class TransportPowerClass {
        BatteryFriendly,
        Balanced,
        HighPower
    };
    Q_ENUM(TransportPowerClass)

    struct RuntimePolicy {
        int statsPollIntervalMs = 1000;
        int memorySampleIntervalMs = 1500;
        int privilegedTunLogIntervalMs = 200;
        int logsFlushIntervalMs = 120;
        int speedTestTickIntervalMs = 100;
        int publicIpRetryDelayMs = 2200;
        int startupSelfCheckDelayMs = 700;
        int uiStatsRefreshIntervalMs = 1000;
        int uiGaugeRefreshIntervalMs = 40;
        bool pauseDecorativeUiWhenBackgrounded = false;
        bool reduceFakeDnsSniffing = false;
        bool lightweightRoutingPreferred = false;
        bool conservativeReconnect = false;
        bool strongKeepalive = false;
        bool realTimeStats = false;
    };

    explicit PowerModeManager(QObject *parent = nullptr);

    Mode mode() const;
    QString modeName() const;
    QString effectiveModeName() const;
    QStringList modeOptions() const;
    RuntimePolicy effectivePolicy() const;
    QVariantMap effectivePolicyVariant() const;
    QVariantMap visualPolicyVariant() const;
    QVariantMap diagnosticsVariant() const;

    bool backgrounded() const;
    bool screenOn() const;
    bool charging() const;
    bool batterySaver() const;
    int batteryLevel() const;
    QString networkType() const;

    void loadSettings();
    void saveSettings() const;
    void setMode(Mode mode);
    void setModeName(const QString& modeName);
    void setScreenOn(bool screenOn);
    void setCharging(bool charging);
    void setBatterySaver(bool batterySaver);
    void setBatteryLevel(int batteryLevel);
    void setNetworkType(const QString& networkType);

    Q_INVOKABLE void setAdaptiveState(bool screenOn, bool charging, bool batterySaver, int batteryLevel, const QString& networkType);
    Q_INVOKABLE QString classifyTransport(const QString& network, const QString& security, const QString& alpn = QString()) const;
    Q_INVOKABLE QString transportPowerDescription(const QString& powerClass) const;
    Q_INVOKABLE void resetDiagnostics();

    int nextReconnectDelayMs();
    void resetReconnectBackoff();
    void recordReconnectAttempt();
    void recordReconnectSuccess();
    void recordRuntimeInstability(const QString& reason);
    void recordTimerWakeup(const QString& source);
    void recordCpuUsageSample(double percent);
    void refreshPlatformState();

signals:
    void modeChanged();
    void effectivePolicyChanged();
    void adaptiveStateChanged();
    void diagnosticsChanged();
    void saveModeSuggested(const QString& reason);
    void normalModeFallbackTriggered(const QString& reason);
    void debugLog(const QString& message);

private:
    static QString modeToString(Mode mode);
    static Mode modeFromString(const QString& value, bool *ok = nullptr);
    static QString transportClassToString(TransportPowerClass value);
    RuntimePolicy basePolicy(Mode mode) const;
    RuntimePolicy adaptPolicy(RuntimePolicy policy) const;
    void recomputeEffectivePolicy(const QString& reason);
    void emitAdaptiveChanged(const QString& reason);
    void maybeSuggestSaveMode();
    void maybeFallbackToNormal(const QString& reason);
    void initializePlatformState();
    void updateNetworkStatusLabel();
    void updateBatteryStatusLabel();

    Mode m_mode = Mode::Normal;
    RuntimePolicy m_effectivePolicy;
    bool m_backgrounded = false;
    bool m_screenOn = true;
    bool m_charging = false;
    bool m_batterySaver = false;
    int m_batteryLevel = -1;
    QString m_networkType = QString::fromUtf8("unknown");
    QString m_batteryStatus = QString::fromUtf8("Unknown");
    QString m_networkStatus = QString::fromUtf8("Unknown");
    int m_reconnectBackoffIndex = 0;
    int m_reconnectAttemptCount = 0;
    int m_reconnectSuccessCount = 0;
    int m_instabilityCount = 0;
    quint64 m_timerWakeupCount = 0;
    QVariantMap m_timerWakeupsBySource;
    double m_lastCpuUsagePercent = -1.0;
    QVector<qint64> m_recentInstabilityEpochMs;
};

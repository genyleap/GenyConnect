#pragma once

#include <QObject>
#include <QString>

struct VpnRuntimeCapabilities
{
    bool isMobile = false;
    bool isDesktop = true;
    bool supportsTun = true;
    bool supportsSystemProxy = true;
    bool supportsPerAppRouting = true;
    bool supportsAutoUpdate = true;
    bool requiresVpnPermission = false;
    bool requiresForegroundService = false;
    bool requiresNetworkExtension = false;
};

class VpnRuntimeBackend : public QObject
{
    Q_OBJECT

public:
    enum class ExitStatus : int {
        NormalExit = 0,
        CrashExit = 1
    };
    Q_ENUM(ExitStatus)

    explicit VpnRuntimeBackend(QObject *parent = nullptr);
    ~VpnRuntimeBackend() override;

    virtual QString backendName() const = 0;
    virtual VpnRuntimeCapabilities capabilities() const = 0;

    virtual bool initialize(QString *errorMessage) = 0;
    virtual bool connectRuntime(
        const QString& executablePath,
        const QString& configPath,
        const QString& workingDirectory,
        QString *errorMessage) = 0;
    virtual bool disconnectRuntime(QString *errorMessage, int timeoutMs = 0) = 0;

    virtual bool isRunning() const = 0;
    virtual qint64 processId() const = 0;
    virtual qint64 rxBytes() const = 0;
    virtual qint64 txBytes() const = 0;
    virtual QString lastError() const = 0;
    virtual bool startupPending() const { return false; }
    virtual bool runtimeProcessAlive() const { return isRunning(); }
    virtual QString diagnosticSummary() const { return lastError(); }

signals:
    void started();
    void stopped(int exitCode, VpnRuntimeBackend::ExitStatus exitStatus);
    void errorOccurred(const QString& error);
    void logLine(const QString& line);
    void trafficChanged();
};

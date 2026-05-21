#pragma once

#include "runtime/vpnruntimebackend.hpp"

class AndroidVpnRuntime final : public VpnRuntimeBackend
{
    Q_OBJECT

public:
    explicit AndroidVpnRuntime(QObject *parent = nullptr);
    ~AndroidVpnRuntime() override;

    QString backendName() const override;
    VpnRuntimeCapabilities capabilities() const override;

    bool initialize(QString *errorMessage) override;
    bool connectRuntime(
        const QString& executablePath,
        const QString& configPath,
        const QString& workingDirectory,
        QString *errorMessage) override;
    bool disconnectRuntime(QString *errorMessage, int timeoutMs = 0) override;

    bool isRunning() const override;
    qint64 processId() const override;
    qint64 rxBytes() const override;
    qint64 txBytes() const override;
    QString lastError() const override;

private:
    bool m_running = false;
    QString m_lastError;
};

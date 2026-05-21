#pragma once

#include "runtime/vpnruntimebackend.hpp"

class IosVpnRuntime final : public VpnRuntimeBackend
{
    Q_OBJECT

public:
    explicit IosVpnRuntime(QObject *parent = nullptr);
    ~IosVpnRuntime() override;

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
    QString m_lastError;
};


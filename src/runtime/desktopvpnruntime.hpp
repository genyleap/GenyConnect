#pragma once

#include "runtime/vpnruntimebackend.hpp"

#include <QByteArray>
#include <QProcess>

class DesktopVpnRuntime final : public VpnRuntimeBackend
{
    Q_OBJECT

public:
    explicit DesktopVpnRuntime(QObject *parent = nullptr);
    ~DesktopVpnRuntime() override;

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
    void parseAndEmitLines(QByteArray& buffer, const QByteArray& chunk);
    void handleLogLine(const QString& line);
    void parseTraffic(const QString& line);

    QProcess m_process;
    QByteArray m_stdoutBuffer;
    QByteArray m_stderrBuffer;
    qint64 m_rxBytes = 0;
    qint64 m_txBytes = 0;
    QString m_lastError;
};

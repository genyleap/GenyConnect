#include "runtime/iosvpnruntime.hpp"

IosVpnRuntime::IosVpnRuntime(QObject *parent)
    : VpnRuntimeBackend(parent)
{
}

IosVpnRuntime::~IosVpnRuntime() = default;

QString IosVpnRuntime::backendName() const
{
    return QString::fromUtf8("ios");
}

VpnRuntimeCapabilities IosVpnRuntime::capabilities() const
{
    VpnRuntimeCapabilities caps;
    caps.isMobile = true;
    caps.isDesktop = false;
    caps.supportsTun = true;
    caps.supportsSystemProxy = false;
    caps.supportsPerAppRouting = true;
    caps.supportsAutoUpdate = false;
    caps.requiresVpnPermission = true;
    caps.requiresForegroundService = false;
    caps.requiresNetworkExtension = true;
    return caps;
}

bool IosVpnRuntime::initialize(QString *errorMessage)
{
    m_lastError.clear();
    if (errorMessage) {
        errorMessage->clear();
    }
    return true;
}

bool IosVpnRuntime::connectRuntime(
    const QString& executablePath,
    const QString& configPath,
    const QString& workingDirectory,
    QString *errorMessage)
{
    Q_UNUSED(executablePath)
    Q_UNUSED(configPath)
    Q_UNUSED(workingDirectory)

    // TODO(iOS): I'll code NetworkExtension Packet Tunnel bridge.
    m_lastError = QString::fromUtf8(
        "iOS VPN runtime bridge is not wired yet. Packet Tunnel Provider integration is required.");
    if (errorMessage) {
        *errorMessage = m_lastError;
    }
    emit errorOccurred(m_lastError);
    return false;
}

bool IosVpnRuntime::disconnectRuntime(QString *errorMessage, int timeoutMs)
{
    Q_UNUSED(timeoutMs)
    if (errorMessage) {
        errorMessage->clear();
    }
    return true;
}

bool IosVpnRuntime::isRunning() const
{
    return false;
}

qint64 IosVpnRuntime::processId() const
{
    return -1;
}

qint64 IosVpnRuntime::rxBytes() const
{
    return 0;
}

qint64 IosVpnRuntime::txBytes() const
{
    return 0;
}

QString IosVpnRuntime::lastError() const
{
    return m_lastError;
}

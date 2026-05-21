module;
#include <QString>

module genyconnect.backend.systemproxymanager;

bool SystemProxyManager::enable(quint16 socksPort, quint16 httpPort, QString *errorMessage)
{
    Q_UNUSED(socksPort)
    Q_UNUSED(httpPort)
    setError(errorMessage, QString::fromUtf8("System proxy management is not available on mobile runtimes."));
    m_enabled = false;
    return false;
}

bool SystemProxyManager::disable(QString *errorMessage, bool force)
{
    Q_UNUSED(force)
    if (errorMessage) {
        errorMessage->clear();
    }
    m_enabled = false;
    return true;
}

bool SystemProxyManager::isEnabled() const
{
    return m_enabled;
}

void SystemProxyManager::setError(QString *errorMessage, const QString& message)
{
    if (errorMessage) {
        *errorMessage = message;
    }
}

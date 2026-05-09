module;
#include <QProcess>

module genyconnect.backend.systemproxymanager;

using namespace Qt::StringLiterals;

#ifdef Q_OS_MACOS
namespace {
QString shellQuote(const QString& value)
{
    QString quoted = value;
    quoted.replace(u"'"_s, u"'\\''"_s);
    return u"'"_s + quoted + u"'"_s;
}

QString appleScriptQuote(const QString& value)
{
    QString escaped = value;
    escaped.replace(u"\\"_s, u"\\\\"_s);
    escaped.replace(u"\""_s, u"\\\""_s);
    return escaped;
}
}
#endif

bool SystemProxyManager::enable(quint16 socksPort, quint16 httpPort, QString *errorMessage)
{
#ifdef Q_OS_MACOS
    const bool ok = applyOnMac(true, socksPort, httpPort, errorMessage);
    if (ok) {
        m_enabled = true;
    }
    return ok;
#else
    Q_UNUSED(socksPort)
    Q_UNUSED(httpPort)
    setError(errorMessage, u"Automatic system proxy is currently implemented only on macOS."_s);
    return false;
#endif
}

bool SystemProxyManager::disable(QString *errorMessage, bool force)
{
#ifdef Q_OS_MACOS
    if (!force && !m_enabled) {
        if (areAllServicesProxyDisabled(nullptr)) {
            return true;
        }
    }

    const bool ok = applyOnMac(false, 0, 0, errorMessage);
    if (ok) {
        m_enabled = false;
    }
    return ok;
#else
    Q_UNUSED(errorMessage)
    m_enabled = false;
    return true;
#endif
}

bool SystemProxyManager::isEnabled() const
{
    return m_enabled;
}

#ifdef Q_OS_MACOS
bool SystemProxyManager::applyOnMac(bool enable, quint16 socksPort, quint16 httpPort, QString *errorMessage)
{
    if (enable && areAllServicesConfiguredForLocalProxy(socksPort, httpPort, nullptr)) {
        m_enabled = true;
        return true;
    }

    if (!enable && areAllServicesProxyDisabled(nullptr)) {
        m_enabled = false;
        return true;
    }

    QString listError;
    const QStringList services = listActiveMacNetworkServices(&listError);
    if (services.isEmpty()) {
        setError(errorMessage, listError.isEmpty() ? u"No active macOS network services were found."_s : listError);
        return false;
    }

    QList<QStringList> commands;
    for (const QString& service : services) {
        if (enable) {
            // Keep command sequence aligned with v2rayN's known-working macOS script.
            commands.append(
                {u"-setwebproxy"_s, service, u"127.0.0.1"_s, QString::number(httpPort)}
            );
            commands.append(
                {u"-setsecurewebproxy"_s, service, u"127.0.0.1"_s, QString::number(httpPort)}
            );
            commands.append(
                {u"-setsocksfirewallproxy"_s, service, u"127.0.0.1"_s, QString::number(socksPort)}
            );
            commands.append(
                {u"-setproxybypassdomains"_s, service, u"localhost"_s, u"127.0.0.1"_s, u"::1"_s}
            );
        } else {
            commands.append({u"-setsocksfirewallproxystate"_s, service, u"off"_s});
            commands.append({u"-setwebproxystate"_s, service, u"off"_s});
            commands.append({u"-setsecurewebproxystate"_s, service, u"off"_s});
        }
    }

    for (const QStringList& command : commands) {
        QString commandError;
        if (!runNetworkSetup(command, &commandError)) {
            if (commandError.contains(u"requires admin privileges"_s, Qt::CaseInsensitive)) {
                if (!runNetworkSetupBatchAsAdmin(commands, errorMessage)) {
                    return false;
                }
                return !enable || anyProxyEnabledOnMac(socksPort, httpPort, errorMessage);
            }

            setError(errorMessage, commandError);
            return false;
        }
    }

    if (enable) {
        return anyProxyEnabledOnMac(socksPort, httpPort, errorMessage);
    }

    return true;
}

bool SystemProxyManager::runNetworkSetup(const QStringList& arguments, QString *errorMessage)
{
    QProcess process;
    process.start(u"/usr/sbin/networksetup"_s, arguments);

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, u"Failed to run networksetup."_s);
        return false;
    }

    if (!process.waitForFinished(10000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, u"networksetup command timed out."_s);
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }

        if (detail.isEmpty()) {
            detail = u"networksetup failed with exit code %1."_s.arg(process.exitCode());
        }

        setError(errorMessage, detail);
        return false;
    }

    return true;
}

bool SystemProxyManager::runNetworkSetupBatchAsAdmin(const QList<QStringList>& commands, QString *errorMessage)
{
    if (commands.isEmpty()) {
        return true;
    }

    QStringList commandLines;
    for (const QStringList& arguments : commands) {
        QStringList parts;
        parts.reserve(arguments.size() + 1);
        parts.append(u"/usr/sbin/networksetup"_s);
        for (const QString& argument : arguments) {
            parts.append(shellQuote(argument));
        }
        commandLines.append(parts.join(' '));
    }

    const QString shellCommand = commandLines.join(u" && "_s);
    const QString script = u"do shell script \"%1\" with administrator privileges"_s
        .arg(appleScriptQuote(shellCommand));

    QProcess process;
    process.start(u"/usr/bin/osascript"_s, {u"-e"_s, script});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, u"Failed to request admin privileges for proxy setup."_s);
        return false;
    }

    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, u"Admin proxy setup timed out."_s);
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }
        if (detail.isEmpty()) {
            detail = u"Admin proxy setup failed."_s;
        }
        setError(errorMessage, detail);
        return false;
    }

    return true;
}

bool SystemProxyManager::anyProxyEnabledOnMac(quint16 socksPort, quint16 httpPort, QString *errorMessage)
{
    if (areAllServicesConfiguredForLocalProxy(socksPort, httpPort, errorMessage)) {
        return true;
    }

    setError(errorMessage, u"System proxy state is not fully set to local Xray ports."_s);
    return false;
}

bool SystemProxyManager::readServiceProxyInfo(
    const QString& service,
    const QString& queryArgument,
    ProxyInfo *info,
    QString *errorMessage
)
{
    if (!info) {
        setError(errorMessage, u"Internal proxy query error."_s);
        return false;
    }

    QProcess process;
    process.start(u"/usr/sbin/networksetup"_s, {queryArgument, service});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, u"Failed to query macOS proxy state."_s);
        return false;
    }

    if (!process.waitForFinished(8000)) {
        process.kill();
        process.waitForFinished(1000);
        setError(errorMessage, u"Timed out querying macOS proxy state."_s);
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }
        setError(
            errorMessage,
            detail.isEmpty() ? u"Failed to query macOS proxy state."_s : detail
        );
        return false;
    }

    *info = ProxyInfo {};

    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    const QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();
        const int colon = line.indexOf(':');
        if (colon <= 0) {
            continue;
        }

        const QString key = line.left(colon).trimmed();
        const QString value = line.mid(colon + 1).trimmed();
        if (key.compare(u"Enabled"_s, Qt::CaseInsensitive) == 0) {
            info->enabled = value.compare(u"Yes"_s, Qt::CaseInsensitive) == 0
                || value == u"1"_s
                || value.compare(u"On"_s, Qt::CaseInsensitive) == 0;
        } else if (key.compare(u"Server"_s, Qt::CaseInsensitive) == 0) {
            info->server = value;
        } else if (key.compare(u"Port"_s, Qt::CaseInsensitive) == 0) {
            info->port = value.toInt();
        }
    }

    return true;
}

bool SystemProxyManager::areAllServicesConfiguredForLocalProxy(quint16 socksPort, quint16 httpPort, QString *errorMessage)
{
    QString listError;
    const QStringList services = listActiveMacNetworkServices(&listError);
    if (services.isEmpty()) {
        setError(errorMessage, listError.isEmpty() ? u"No active macOS network services were found."_s : listError);
        return false;
    }

    const auto hostMatches = [](const QString& host) {
        return host == u"127.0.0.1"_s || host == u"localhost"_s;
    };

    for (const QString& service : services) {
        ProxyInfo webInfo;
        ProxyInfo secureInfo;
        ProxyInfo socksInfo;
        QString queryError;
        if (!readServiceProxyInfo(service, u"-getwebproxy"_s, &webInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, u"-getsecurewebproxy"_s, &secureInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, u"-getsocksfirewallproxy"_s, &socksInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }

        const bool webOk = webInfo.enabled && hostMatches(webInfo.server) && webInfo.port == httpPort;
        const bool secureOk = secureInfo.enabled && hostMatches(secureInfo.server) && secureInfo.port == httpPort;
        const bool socksOk = socksInfo.enabled && hostMatches(socksInfo.server) && socksInfo.port == socksPort;
        if (!webOk || !secureOk || !socksOk) {
            return false;
        }
    }

    return true;
}

bool SystemProxyManager::areAllServicesProxyDisabled(QString *errorMessage)
{
    QString listError;
    const QStringList services = listActiveMacNetworkServices(&listError);
    if (services.isEmpty()) {
        setError(errorMessage, listError.isEmpty() ? u"No active macOS network services were found."_s : listError);
        return false;
    }

    for (const QString& service : services) {
        ProxyInfo webInfo;
        ProxyInfo secureInfo;
        ProxyInfo socksInfo;
        QString queryError;
        if (!readServiceProxyInfo(service, u"-getwebproxy"_s, &webInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, u"-getsecurewebproxy"_s, &secureInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, u"-getsocksfirewallproxy"_s, &socksInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }

        if (webInfo.enabled || secureInfo.enabled || socksInfo.enabled) {
            return false;
        }
    }

    return true;
}

QStringList SystemProxyManager::listActiveMacNetworkServices(QString *errorMessage)
{
    QProcess process;
    process.start(u"/usr/sbin/networksetup"_s, {u"-listallnetworkservices"_s});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, u"Failed to query macOS network services."_s);
        return {};
    }

    if (!process.waitForFinished(10000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, u"Listing network services timed out."_s);
        return {};
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }

        setError(errorMessage, detail.isEmpty() ? u"Failed to list network services."_s : detail);
        return {};
    }

    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    const QStringList lines = output.split('\n', Qt::SkipEmptyParts);

    QStringList services;
    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty() || line.startsWith(u"An asterisk"_s)) {
            continue;
        }

        if (line.startsWith('*')) {
            continue;
        }

        services.append(line);
    }

    return services;
}
#endif

void SystemProxyManager::setError(QString *errorMessage, const QString& message)
{
    if (errorMessage) {
        *errorMessage = message;
    }
}

module;
#include <QProcess>

module genyconnect.backend.systemproxymanager;

#ifdef Q_OS_MACOS
namespace {
QString shellQuote(const QString& value)
{
    QString quoted = value;
    quoted.replace(QString::fromUtf8("'"), QString::fromUtf8("'\\''"));
    return QString::fromUtf8("'") + quoted + QString::fromUtf8("'");
}

QString appleScriptQuote(const QString& value)
{
    QString escaped = value;
    escaped.replace(QString::fromUtf8("\\"), QString::fromUtf8("\\\\"));
    escaped.replace(QString::fromUtf8("\""), QString::fromUtf8("\\\""));
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
    setError(errorMessage, QString::fromUtf8("Automatic system proxy is currently implemented only on macOS."));
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
        setError(errorMessage, listError.isEmpty() ? QString::fromUtf8("No active macOS network services were found.") : listError);
        return false;
    }

    QList<QStringList> commands;
    for (const QString& service : services) {
        if (enable) {
            // Keep command sequence aligned with v2rayN's known-working macOS script.
            commands.append(
                {QString::fromUtf8("-setwebproxy"), service, QString::fromUtf8("127.0.0.1"), QString::number(httpPort)}
            );
            commands.append(
                {QString::fromUtf8("-setsecurewebproxy"), service, QString::fromUtf8("127.0.0.1"), QString::number(httpPort)}
            );
            commands.append(
                {QString::fromUtf8("-setsocksfirewallproxy"), service, QString::fromUtf8("127.0.0.1"), QString::number(socksPort)}
            );
            commands.append(
                {QString::fromUtf8("-setproxybypassdomains"), service, QString::fromUtf8("localhost"), QString::fromUtf8("127.0.0.1"), QString::fromUtf8("::1")}
            );
        } else {
            commands.append({QString::fromUtf8("-setsocksfirewallproxystate"), service, QString::fromUtf8("off")});
            commands.append({QString::fromUtf8("-setwebproxystate"), service, QString::fromUtf8("off")});
            commands.append({QString::fromUtf8("-setsecurewebproxystate"), service, QString::fromUtf8("off")});
        }
    }

    for (const QStringList& command : commands) {
        QString commandError;
        if (!runNetworkSetup(command, &commandError)) {
            if (commandError.contains(QString::fromUtf8("requires admin privileges"), Qt::CaseInsensitive)) {
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
    process.start(QString::fromUtf8("/usr/sbin/networksetup"), arguments);

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, QString::fromUtf8("Failed to run networksetup."));
        return false;
    }

    if (!process.waitForFinished(10000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, QString::fromUtf8("networksetup command timed out."));
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }

        if (detail.isEmpty()) {
            detail = QString::fromUtf8("networksetup failed with exit code %1.").arg(process.exitCode());
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
        parts.append(QString::fromUtf8("/usr/sbin/networksetup"));
        for (const QString& argument : arguments) {
            parts.append(shellQuote(argument));
        }
        commandLines.append(parts.join(' '));
    }

    const QString shellCommand = commandLines.join(QString::fromUtf8(" && "));
    const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
        .arg(appleScriptQuote(shellCommand));

    QProcess process;
    process.start(QString::fromUtf8("/usr/bin/osascript"), {QString::fromUtf8("-e"), script});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, QString::fromUtf8("Failed to request admin privileges for proxy setup."));
        return false;
    }

    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, QString::fromUtf8("Admin proxy setup timed out."));
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }
        if (detail.isEmpty()) {
            detail = QString::fromUtf8("Admin proxy setup failed.");
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

    setError(errorMessage, QString::fromUtf8("System proxy state is not fully set to local Xray ports."));
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
        setError(errorMessage, QString::fromUtf8("Internal proxy query error."));
        return false;
    }

    QProcess process;
    process.start(QString::fromUtf8("/usr/sbin/networksetup"), {queryArgument, service});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, QString::fromUtf8("Failed to query macOS proxy state."));
        return false;
    }

    if (!process.waitForFinished(8000)) {
        process.kill();
        process.waitForFinished(1000);
        setError(errorMessage, QString::fromUtf8("Timed out querying macOS proxy state."));
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }
        setError(
            errorMessage,
            detail.isEmpty() ? QString::fromUtf8("Failed to query macOS proxy state.") : detail
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
        if (key.compare(QString::fromUtf8("Enabled"), Qt::CaseInsensitive) == 0) {
            info->enabled = value.compare(QString::fromUtf8("Yes"), Qt::CaseInsensitive) == 0
                || value == QString::fromUtf8("1")
                || value.compare(QString::fromUtf8("On"), Qt::CaseInsensitive) == 0;
        } else if (key.compare(QString::fromUtf8("Server"), Qt::CaseInsensitive) == 0) {
            info->server = value;
        } else if (key.compare(QString::fromUtf8("Port"), Qt::CaseInsensitive) == 0) {
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
        setError(errorMessage, listError.isEmpty() ? QString::fromUtf8("No active macOS network services were found.") : listError);
        return false;
    }

    const auto hostMatches = [](const QString& host) {
        return host == QString::fromUtf8("127.0.0.1") || host == QString::fromUtf8("localhost");
    };

    for (const QString& service : services) {
        ProxyInfo webInfo;
        ProxyInfo secureInfo;
        ProxyInfo socksInfo;
        QString queryError;
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getwebproxy"), &webInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getsecurewebproxy"), &secureInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getsocksfirewallproxy"), &socksInfo, &queryError)) {
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
        setError(errorMessage, listError.isEmpty() ? QString::fromUtf8("No active macOS network services were found.") : listError);
        return false;
    }

    for (const QString& service : services) {
        ProxyInfo webInfo;
        ProxyInfo secureInfo;
        ProxyInfo socksInfo;
        QString queryError;
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getwebproxy"), &webInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getsecurewebproxy"), &secureInfo, &queryError)) {
            setError(errorMessage, queryError);
            return false;
        }
        if (!readServiceProxyInfo(service, QString::fromUtf8("-getsocksfirewallproxy"), &socksInfo, &queryError)) {
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
    process.start(QString::fromUtf8("/usr/sbin/networksetup"), {QString::fromUtf8("-listallnetworkservices")});

    if (!process.waitForStarted(5000)) {
        setError(errorMessage, QString::fromUtf8("Failed to query macOS network services."));
        return {};
    }

    if (!process.waitForFinished(10000)) {
        process.kill();
        process.waitForFinished(2000);
        setError(errorMessage, QString::fromUtf8("Listing network services timed out."));
        return {};
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString detail = QString::fromUtf8(process.readAllStandardError()).trimmed();
        if (detail.isEmpty()) {
            detail = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        }

        setError(errorMessage, detail.isEmpty() ? QString::fromUtf8("Failed to list network services.") : detail);
        return {};
    }

    const QString output = QString::fromUtf8(process.readAllStandardOutput());
    const QStringList lines = output.split('\n', Qt::SkipEmptyParts);

    QStringList services;
    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty() || line.startsWith(QString::fromUtf8("An asterisk"))) {
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

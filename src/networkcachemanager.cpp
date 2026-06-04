module;
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStringList>
#include <QVariantMap>

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
#include <QCoreApplication>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QProcess>
#include <QStandardPaths>
#endif

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

#if defined(Q_OS_LINUX)
#include <unistd.h>
#endif

#include <utility>

module genyconnect.backend.networkcachemanager;

namespace {

#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
#endif

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
QString escapeForAppleScriptString(const QString& value)
{
    QString out = value;
    out.replace(QString::fromUtf8("\\"), QString::fromUtf8("\\\\"));
    out.replace(QString::fromUtf8("\""), QString::fromUtf8("\\\""));
    return out;
}

bool waitForProcessFinishedResponsive(QProcess& process, int timeoutMs)
{
    QElapsedTimer timer;
    timer.start();

    while (process.state() != QProcess::NotRunning) {
        if (process.waitForFinished(40)) {
            return true;
        }

        QCoreApplication::processEvents(QEventLoop::AllEvents, 10);

        if (timer.elapsed() >= timeoutMs) {
            return false;
        }
    }

    return true;
}

bool runProcess(const QString& program, const QStringList& arguments, int timeoutMs, QString *detail)
{
    QProcess process;
    process.setProcessChannelMode(QProcess::MergedChannels);
    process.start(program, arguments);

    if (!process.waitForStarted(5000)) {
        if (detail) {
            *detail = QString::fromUtf8("Failed to start %1.").arg(program);
        }
        return false;
    }

    if (!waitForProcessFinishedResponsive(process, timeoutMs)) {
        process.kill();
        waitForProcessFinishedResponsive(process, 1000);
        if (detail) {
            *detail = QString::fromUtf8("%1 timed out.").arg(program);
        }
        return false;
    }

    const QString output = QString::fromUtf8(process.readAll()).trimmed();
    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        if (detail) {
            *detail = output.isEmpty()
                ? QString::fromUtf8("%1 exited with code %2.").arg(program).arg(process.exitCode())
                : output;
        }
        return false;
    }

    if (detail) {
        *detail = output;
    }
    return true;
}
#endif

QStringList macOSNetworkCacheDetails()
{
    return {QString::fromUtf8("DNS: dscacheutil + mDNSResponder"),
            QString::fromUtf8("IP cache: arp -a -d")};
}

QStringList windowsNetworkCacheDetails()
{
    return {QString::fromUtf8("DNS: ipconfig /flushdns"),
            QString::fromUtf8("IP cache: netsh interface ip delete arpcache")};
}

QStringList linuxNetworkCacheDetails()
{
    return {QString::fromUtf8("DNS: resolvectl/systemd-resolve/nscd when available"),
            QString::fromUtf8("IP cache: ip neigh flush all")};
}

} // namespace

NetworkCacheManager::NetworkCacheManager(Options options)
    : m_options(std::move(options))
{
}

QVariantMap NetworkCacheManager::clearNetworkCache()
{
#if defined(Q_OS_IOS)
    return finish(
        false,
        QString::fromUtf8("iOS does not expose a public API for clearing system DNS or IP neighbor cache from an app."),
        {QString::fromUtf8("Reconnect the VPN or toggle network connectivity to force iOS to rebuild resolver state.")});
#elif defined(Q_OS_ANDROID)
    if (!QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        return finish(false, QString::fromUtf8("Android runtime bridge class is missing from the APK."));
    }

    QJniObject jsonObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "clearNetworkCache",
        "()Ljava/lang/String;");
    const QString jsonText = jsonObject.isValid() ? jsonObject.toString().trimmed() : QString();
    const QJsonDocument parsed = QJsonDocument::fromJson(jsonText.toUtf8());
    if (!parsed.isObject()) {
        return finish(false, QString::fromUtf8("Android network cache refresh returned an invalid response."));
    }

    const QJsonObject object = parsed.object();
    QStringList details;
    const QJsonArray detailArray = object.value(QString::fromUtf8("details")).toArray();
    for (const QJsonValue& value : detailArray) {
        const QString detailText = value.toString().trimmed();
        if (!detailText.isEmpty()) {
            details.append(detailText);
        }
    }

    const bool ok = object.value(QString::fromUtf8("ok")).toBool(false);
    const QString message = object.value(QString::fromUtf8("message")).toString().trimmed();
    return finish(ok,
                  message.isEmpty()
                      ? QString::fromUtf8("Android network cache refresh completed.")
                      : message,
                  details);
#else
    QString detail;

#if defined(Q_OS_MACOS)
    QString helperError;
    QJsonObject helperResponse;
    if (runPrivilegedCacheClear(&helperResponse, &helperError)
        && helperResponse.value(QString::fromUtf8("ok")).toBool(false)) {
        return finish(
            true,
            QString::fromUtf8("macOS DNS resolver cache and IP neighbor cache were cleared."),
            macOSNetworkCacheDetails());
    }
    if (!helperError.trimmed().isEmpty()) {
        log(QString::fromUtf8("[System] Privileged helper cache clear fallback: %1").arg(helperError.trimmed()));
    }

    const QString command = QString::fromUtf8(
        "/usr/bin/dscacheutil -flushcache; "
        "/usr/bin/killall -HUP mDNSResponder >/dev/null 2>&1 || true; "
        "/usr/sbin/arp -a -d >/dev/null 2>&1 || true");
    const QString script = QString::fromUtf8("do shell script \"%1\" with administrator privileges")
        .arg(escapeForAppleScriptString(command));
    const bool ok = runProcess(QString::fromUtf8("/usr/bin/osascript"),
                               {QString::fromUtf8("-e"), script},
                               60000,
                               &detail);
    if (!ok) {
        return finish(
            false,
            detail.isEmpty()
                ? QString::fromUtf8("Failed to clear macOS DNS and IP neighbor caches.")
                : QString::fromUtf8("Failed to clear macOS network cache: %1").arg(detail),
            macOSNetworkCacheDetails());
    }

    return finish(
        true,
        QString::fromUtf8("macOS DNS resolver cache and IP neighbor cache were cleared."),
        macOSNetworkCacheDetails());
#elif defined(Q_OS_WIN)
    QString helperError;
    QJsonObject helperResponse;
    if (runPrivilegedCacheClear(&helperResponse, &helperError)
        && helperResponse.value(QString::fromUtf8("ok")).toBool(false)) {
        return finish(
            true,
            QString::fromUtf8("Windows DNS resolver cache and IP neighbor cache were cleared."),
            windowsNetworkCacheDetails());
    }
    if (!helperError.trimmed().isEmpty()) {
        log(QString::fromUtf8("[System] Privileged helper cache clear fallback: %1").arg(helperError.trimmed()));
    }

    const QString command = QString::fromUtf8(
        "$ErrorActionPreference='Stop'; "
        "$p=Start-Process -Verb RunAs -Wait -PassThru -WindowStyle Hidden "
        "-FilePath 'cmd.exe' "
        "-ArgumentList @('/c','ipconfig /flushdns && netsh interface ip delete arpcache'); "
        "exit $p.ExitCode");
    const bool ok = runProcess(
        QString::fromUtf8("powershell"),
        {QString::fromUtf8("-NoProfile"), QString::fromUtf8("-ExecutionPolicy"), QString::fromUtf8("Bypass"),
         QString::fromUtf8("-Command"), command},
        120000,
        &detail);
    if (!ok) {
        return finish(
            false,
            detail.isEmpty()
                ? QString::fromUtf8("Failed to clear Windows DNS and IP neighbor caches.")
                : QString::fromUtf8("Failed to clear Windows network cache: %1").arg(detail),
            windowsNetworkCacheDetails());
    }

    return finish(
        true,
        QString::fromUtf8("Windows DNS resolver cache and IP neighbor cache were cleared."),
        windowsNetworkCacheDetails());
#elif defined(Q_OS_LINUX)
    QString helperError;
    QJsonObject helperResponse;
    if (runPrivilegedCacheClear(&helperResponse, &helperError)
        && helperResponse.value(QString::fromUtf8("ok")).toBool(false)) {
        return finish(
            true,
            QString::fromUtf8("Linux DNS resolver cache and IP neighbor cache were cleared."),
            linuxNetworkCacheDetails());
    }
    if (!helperError.trimmed().isEmpty()) {
        log(QString::fromUtf8("[System] Privileged helper cache clear fallback: %1").arg(helperError.trimmed()));
    }

    const QString shellCommand = QString::fromUtf8(
        "dns_done=0; "
        "if command -v resolvectl >/dev/null 2>&1; then resolvectl flush-caches && dns_done=1; fi; "
        "if [ \"$dns_done\" -eq 0 ] && command -v systemd-resolve >/dev/null 2>&1; then systemd-resolve --flush-caches && dns_done=1; fi; "
        "if command -v nscd >/dev/null 2>&1; then nscd -i hosts >/dev/null 2>&1 || true; dns_done=1; fi; "
        "if command -v ip >/dev/null 2>&1; then ip neigh flush all >/dev/null; else echo 'ip command not found' >&2; exit 1; fi");

    QString program = QString::fromUtf8("/bin/sh");
    QStringList arguments = {QString::fromUtf8("-c"), shellCommand};
    if (geteuid() != 0) {
        const QString pkexecPath = QStandardPaths::findExecutable(QString::fromUtf8("pkexec"));
        if (pkexecPath.isEmpty()) {
            return finish(
                false,
                QString::fromUtf8("Linux IP neighbor cache clearing requires root privileges or pkexec."),
                linuxNetworkCacheDetails());
        }
        program = pkexecPath;
        arguments = {QString::fromUtf8("/bin/sh"), QString::fromUtf8("-c"), shellCommand};
    }

    const bool ok = runProcess(program, arguments, 120000, &detail);
    if (!ok) {
        return finish(
            false,
            detail.isEmpty()
                ? QString::fromUtf8("Failed to clear Linux DNS and IP neighbor caches.")
                : QString::fromUtf8("Failed to clear Linux network cache: %1").arg(detail),
            linuxNetworkCacheDetails());
    }

    return finish(
        true,
        QString::fromUtf8("Linux DNS resolver cache and IP neighbor cache were cleared."),
        linuxNetworkCacheDetails());
#else
    return finish(false, QString::fromUtf8("Network cache clearing is not implemented for this platform."));
#endif
#endif
}

QVariantMap NetworkCacheManager::finish(bool ok, const QString& message, const QStringList& details) const
{
    QVariantMap result;
    result.insert(QString::fromUtf8("ok"), ok);
    result.insert(QString::fromUtf8("message"), message);
    result.insert(QString::fromUtf8("details"), details);

    log(QString::fromUtf8("[System] %1").arg(message));
    return result;
}

bool NetworkCacheManager::runPrivilegedCacheClear(QJsonObject *response, QString *errorMessage) const
{
    if (!m_options.privilegedCommandRunner) {
        return false;
    }

    return m_options.privilegedCommandRunner(
        QJsonObject{{QString::fromUtf8("action"), QString::fromUtf8("clear_network_cache")}},
        response,
        errorMessage,
        30000);
}

void NetworkCacheManager::log(const QString& message) const
{
    if (m_options.logSink) {
        m_options.logSink(message);
    }
}

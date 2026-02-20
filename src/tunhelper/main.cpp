#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QHostInfo>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QTcpServer>
#include <QTcpSocket>
#include <QThread>
#include <QTimer>

namespace {

QString quoteForSh(const QString& value)
{
    QString escaped = value;
    escaped.replace('\'', "'\"'\"'");
    return QStringLiteral("'") + escaped + QStringLiteral("'");
}

QString quoteForPowerShell(const QString& value)
{
    QString escaped = value;
    escaped.replace('\'', "''");
    return QStringLiteral("'") + escaped + QStringLiteral("'");
}

bool runProcess(
    const QString& program,
    const QStringList& args,
    int timeoutMs,
    QString* stdoutText,
    QString* stderrText)
{
    QProcess process;
    process.start(program, args);
    if (!process.waitForStarted(5000)) {
        if (stderrText != nullptr) {
            *stderrText = QStringLiteral("Failed to start process: %1").arg(program);
        }
        return false;
    }

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(1000);
        if (stderrText != nullptr) {
            *stderrText = QStringLiteral("Process timed out: %1").arg(program);
        }
        return false;
    }

    if (stdoutText != nullptr) {
        *stdoutText = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
    }
    if (stderrText != nullptr) {
        *stderrText = QString::fromUtf8(process.readAllStandardError()).trimmed();
    }

    return process.exitStatus() == QProcess::NormalExit && process.exitCode() == 0;
}

bool runShell(const QString& shellCommand, int timeoutMs, QString* stderrText)
{
#if defined(Q_OS_WIN)
    QString ignoredOut;
    return runProcess(
        QStringLiteral("powershell"),
        {
            QStringLiteral("-NoProfile"),
            QStringLiteral("-ExecutionPolicy"), QStringLiteral("Bypass"),
            QStringLiteral("-Command"), shellCommand
        },
        timeoutMs,
        &ignoredOut,
        stderrText);
#else
    QString ignoredOut;
    return runProcess(
        QStringLiteral("/bin/sh"),
        {QStringLiteral("-lc"), shellCommand},
        timeoutMs,
        &ignoredOut,
        stderrText);
#endif
}

bool isIpv4(const QString& address)
{
    QHostAddress host(address.trimmed());
    return !host.isNull() && host.protocol() == QAbstractSocket::IPv4Protocol;
}

QString resolveIpv4ForHost(const QString& hostOrIp)
{
    const QString trimmed = hostOrIp.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }
    if (isIpv4(trimmed)) {
        return trimmed;
    }
    const QHostInfo info = QHostInfo::fromName(trimmed);
    for (const QHostAddress& addr : info.addresses()) {
        if (addr.protocol() == QAbstractSocket::IPv4Protocol) {
            return addr.toString();
        }
    }
    return {};
}

QJsonObject makeResponse(bool ok, const QString& message = QString())
{
    QJsonObject response;
    response.insert(QStringLiteral("ok"), ok);
    if (!message.trimmed().isEmpty()) {
        response.insert(QStringLiteral("message"), message.trimmed());
    }
    response.insert(QStringLiteral("time_ms"), QDateTime::currentMSecsSinceEpoch());
    return response;
}

class TunHelperServer : public QObject
{
public:
    TunHelperServer(const QString& token, quint16 port, int idleTimeoutMs, QObject* parent = nullptr)
        : QObject(parent)
        , m_token(token)
        , m_idleTimeoutMs(qMax(30000, idleTimeoutMs))
    {
        m_idleTimer.setInterval(m_idleTimeoutMs);
        m_idleTimer.setSingleShot(true);
        connect(&m_idleTimer, &QTimer::timeout, qApp, &QCoreApplication::quit);
        connect(&m_server, &QTcpServer::newConnection, this, [this]() {
            handleNewConnections();
        });

        if (!m_server.listen(QHostAddress::LocalHost, port)) {
            qFatal("Failed to listen on 127.0.0.1:%hu", port);
        }
        m_idleTimer.start();
    }

private:
    void handleNewConnections()
    {
        while (m_server.hasPendingConnections()) {
            QTcpSocket* socket = m_server.nextPendingConnection();
            if (socket == nullptr) {
                continue;
            }

            connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
                m_idleTimer.start();
                QByteArray buffer = m_buffers.value(socket);
                buffer.append(socket->readAll());
                int newline = buffer.indexOf('\n');
                while (newline >= 0) {
                    const QByteArray rawLine = buffer.left(newline).trimmed();
                    buffer.remove(0, newline + 1);
                    if (!rawLine.isEmpty()) {
                        const QJsonObject response = processLine(rawLine);
                        socket->write(QJsonDocument(response).toJson(QJsonDocument::Compact));
                        socket->write("\n");
                        socket->flush();
                    }
                    newline = buffer.indexOf('\n');
                }
                m_buffers.insert(socket, buffer);
            });

            connect(socket, &QTcpSocket::disconnected, this, [this, socket]() {
                m_buffers.remove(socket);
                socket->deleteLater();
            });
        }
    }

    QJsonObject processLine(const QByteArray& line)
    {
        QJsonParseError parseError;
        const QJsonDocument doc = QJsonDocument::fromJson(line, &parseError);
        if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
            return makeResponse(false, QStringLiteral("Invalid JSON request."));
        }

        const QJsonObject request = doc.object();
        if (request.value(QStringLiteral("token")).toString() != m_token) {
            return makeResponse(false, QStringLiteral("Unauthorized token."));
        }

        const QString action = request.value(QStringLiteral("action")).toString().trimmed();
        if (action == QStringLiteral("ping")) {
            return makeResponse(true, QStringLiteral("pong"));
        }
        if (action == QStringLiteral("shutdown")) {
            QTimer::singleShot(0, qApp, &QCoreApplication::quit);
            return makeResponse(true, QStringLiteral("Helper shutting down."));
        }
        if (action == QStringLiteral("start_tun")) {
            QString error;
            return startTun(request, &error) ? makeResponse(true, QStringLiteral("TUN started."))
                                             : makeResponse(false, error);
        }
        if (action == QStringLiteral("stop_tun")) {
            QString error;
            return stopTun(request, &error) ? makeResponse(true, QStringLiteral("TUN stopped."))
                                            : makeResponse(false, error);
        }

        return makeResponse(false, QStringLiteral("Unsupported action."));
    }

    bool startTun(const QJsonObject& request, QString* errorOut)
    {
        const QString xrayPath = request.value(QStringLiteral("xray_path")).toString().trimmed();
        const QString configPath = request.value(QStringLiteral("config_path")).toString().trimmed();
        const QString pidPath = request.value(QStringLiteral("pid_path")).toString().trimmed();
        const QString logPath = request.value(QStringLiteral("log_path")).toString().trimmed();
        const QString tunIf = request.value(QStringLiteral("tun_if")).toString().trimmed();
        const QString serverIpRequested = request.value(QStringLiteral("server_ip")).toString().trimmed();
        const QString serverHostRequested = request.value(QStringLiteral("server_host")).toString().trimmed();

        if (xrayPath.isEmpty() || configPath.isEmpty() || pidPath.isEmpty() || logPath.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Missing required start_tun fields.");
            }
            return false;
        }
        if (!QFileInfo::exists(xrayPath)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("xray executable not found.");
            }
            return false;
        }
        if (!QFileInfo::exists(configPath)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Runtime config not found.");
            }
            return false;
        }

        QDir().mkpath(QFileInfo(pidPath).absolutePath());
        QDir().mkpath(QFileInfo(logPath).absolutePath());

#if defined(Q_OS_WIN)
        QString ps = QStringLiteral("$ErrorActionPreference='Stop'; ");
        ps += QStringLiteral("$x=%1; ").arg(quoteForPowerShell(xrayPath));
        ps += QStringLiteral("$cfg=%1; ").arg(quoteForPowerShell(configPath));
        ps += QStringLiteral("$log=%1; ").arg(quoteForPowerShell(logPath));
        ps += QStringLiteral("$pidf=%1; ").arg(quoteForPowerShell(pidPath));
        ps += QStringLiteral("if (Test-Path $pidf) { "
                             "$old=(Get-Content $pidf -Raw).Trim(); "
                             "if ($old) { Stop-Process -Id ([int]$old) -Force -ErrorAction SilentlyContinue }; "
                             "Remove-Item $pidf -Force -ErrorAction SilentlyContinue }; ");
        ps += QStringLiteral("$p=Start-Process -FilePath $x -ArgumentList @('run','-config',$cfg) "
                             "-WindowStyle Hidden -RedirectStandardOutput $log -PassThru; ");
        ps += QStringLiteral("[string]$p.Id | Out-File -FilePath $pidf -Encoding ascii -Force");
        QString stderrText;
        if (!runShell(ps, 20000, &stderrText)) {
            if (errorOut != nullptr) {
                *errorOut = stderrText.isEmpty()
                    ? QStringLiteral("Failed to start Xray in privileged helper.")
                    : stderrText;
            }
            return false;
        }
#else
        const QString cmd =
            quoteForSh(xrayPath)
            + QStringLiteral(" run -config ")
            + quoteForSh(configPath)
            + QStringLiteral(" >> ")
            + quoteForSh(logPath)
            + QStringLiteral(" 2>&1 & echo $! > ")
            + quoteForSh(pidPath);
        QString stderrText;
        if (!runShell(cmd, 10000, &stderrText)) {
            if (errorOut != nullptr) {
                *errorOut = stderrText.isEmpty()
                    ? QStringLiteral("Failed to start Xray in privileged helper.")
                    : stderrText;
            }
            return false;
        }
#endif

#if defined(Q_OS_MACOS)
        if (tunIf.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Missing TUN interface name.");
            }
            return false;
        }

        // Wait until xray creates the requested utun interface to avoid first-connect route race.
        bool tunReady = false;
        for (int i = 0; i < 20; ++i) {
            QString ifErr;
            if (runShell(QStringLiteral("/sbin/ifconfig %1 >/dev/null 2>&1").arg(tunIf), 1200, &ifErr)) {
                tunReady = true;
                break;
            }
            QThread::msleep(100);
        }
        if (!tunReady) {
            const QString cleanupCmd = QStringLiteral(
                "if [ -f %1 ]; then PID=$(cat %1); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %1; fi")
                .arg(quoteForSh(pidPath));
            QString ignored;
            runShell(cleanupCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("TUN interface was not ready in time (%1).").arg(tunIf);
            }
            return false;
        }

        QString serverIp = resolveIpv4ForHost(serverIpRequested);
        if (serverIp.isEmpty()) {
            serverIp = resolveIpv4ForHost(serverHostRequested);
        }

        bool hostRouteOk = false;
        if (!serverIp.isEmpty()) {
            for (int i = 0; i < 10; ++i) {
                QString routeErr;
                const QString hostRouteCmd = QStringLiteral(
                    "GW=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}'); "
                    "if [ -n \"$GW\" ]; then route -n add -host %1 \"$GW\" >/dev/null 2>&1; else exit 1; fi")
                    .arg(serverIp);
                if (runShell(hostRouteCmd, 1800, &routeErr)) {
                    hostRouteOk = true;
                    break;
                }
                QThread::msleep(80);
            }
        } else {
            // No host route candidate (likely unresolved host). Continue with split routes best-effort.
            hostRouteOk = true;
        }

        if (!hostRouteOk) {
            const QString cleanupCmd = QStringLiteral(
                "if [ -f %1 ]; then PID=$(cat %1); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %1; fi")
                .arg(quoteForSh(pidPath));
            QString ignored;
            runShell(cleanupCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Failed to add host route for VPN server.");
            }
            return false;
        }

        bool splitRoutesOk = false;
        for (int i = 0; i < 10; ++i) {
            QString routeErr;
            const QString splitCmd = QStringLiteral(
                "route -n add -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1; "
                "route -n add -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1")
                .arg(tunIf);
            if (runShell(splitCmd, 2000, &routeErr)) {
                splitRoutesOk = true;
                break;
            }
            QThread::msleep(80);
        }

        if (!splitRoutesOk) {
            const QString rollbackCmd = QStringLiteral(
                "route -n delete -host %1 >/dev/null 2>&1 || true; "
                "if [ -f %2 ]; then PID=$(cat %2); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %2; fi")
                .arg(serverIp.isEmpty() ? QStringLiteral("0.0.0.0") : serverIp, quoteForSh(pidPath));
            QString ignored;
            runShell(rollbackCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Failed to apply macOS TUN split routes.");
            }
            return false;
        }
#else
        Q_UNUSED(tunIf)
        Q_UNUSED(serverIpRequested)
        Q_UNUSED(serverHostRequested)
#endif

        QFile pidFile(pidPath);
        if (!pidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("TUN start failed: pid file not created.");
            }
            return false;
        }
        const QString pidText = QString::fromUtf8(pidFile.readAll()).trimmed();
        if (pidText.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("TUN start failed: invalid pid.");
            }
            return false;
        }

        return true;
    }

    bool stopTun(const QJsonObject& request, QString* errorOut)
    {
        const QString pidPath = request.value(QStringLiteral("pid_path")).toString().trimmed();
        const QString tunIf = request.value(QStringLiteral("tun_if")).toString().trimmed();
        const QString serverIp = request.value(QStringLiteral("server_ip")).toString().trimmed();
        if (pidPath.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Missing pid path.");
            }
            return false;
        }

#if defined(Q_OS_MACOS)
        if (!tunIf.isEmpty()) {
            QString routeCmd;
            if (isIpv4(serverIp)) {
                routeCmd += QStringLiteral("route -n delete -host %1 >/dev/null 2>&1 || true;").arg(serverIp);
            }
            routeCmd += QStringLiteral(
                "route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
                "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
                    .arg(tunIf);
            QString routeErr;
            if (!runShell(routeCmd, 10000, &routeErr)) {
                if (errorOut != nullptr) {
                    *errorOut = routeErr.isEmpty()
                        ? QStringLiteral("Failed to clear macOS TUN routes.")
                        : routeErr;
                }
                return false;
            }
        }
#else
        Q_UNUSED(tunIf)
        Q_UNUSED(serverIp)
#endif

#if defined(Q_OS_WIN)
        QString ps = QStringLiteral("$ErrorActionPreference='SilentlyContinue'; ");
        ps += QStringLiteral("$pidf=%1; ").arg(quoteForPowerShell(pidPath));
        ps += QStringLiteral(
            "if (Test-Path $pidf) { "
            "$pidv=(Get-Content $pidf -Raw).Trim(); "
            "if ($pidv) { Stop-Process -Id ([int]$pidv) -Force -ErrorAction SilentlyContinue }; "
            "Remove-Item $pidf -Force -ErrorAction SilentlyContinue }");
        QString stopErr;
        if (!runShell(ps, 10000, &stopErr)) {
            if (errorOut != nullptr) {
                *errorOut = stopErr.isEmpty()
                    ? QStringLiteral("Failed to stop privileged TUN process.")
                    : stopErr;
            }
            return false;
        }
#else
        const QString cmd = QStringLiteral(
            "if [ -f %1 ]; then "
            "PID=$(cat %1); "
            "if [ -n \"$PID\" ]; then kill \"$PID\" >/dev/null 2>&1; sleep 0.2; kill -9 \"$PID\" >/dev/null 2>&1 || true; fi; "
            "rm -f %1; "
            "fi")
            .arg(quoteForSh(pidPath));
        QString stopErr;
        if (!runShell(cmd, 10000, &stopErr)) {
            if (errorOut != nullptr) {
                *errorOut = stopErr.isEmpty()
                    ? QStringLiteral("Failed to stop privileged TUN process.")
                    : stopErr;
            }
            return false;
        }
#endif

        return true;
    }

private:
    QTcpServer m_server;
    QString m_token;
    int m_idleTimeoutMs = 600000;
    QTimer m_idleTimer;
    QHash<QTcpSocket*, QByteArray> m_buffers;
};

} // namespace

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("GenyConnectTunHelper"));

    quint16 port = 0;
    QString token;
    int idleTimeoutMs = 15 * 60 * 1000;

    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        const QString arg = args.at(i);
        if (arg == QStringLiteral("--listen-port") && i + 1 < args.size()) {
            bool ok = false;
            const int parsed = args.at(i + 1).toInt(&ok);
            if (ok && parsed > 0 && parsed < 65536) {
                port = static_cast<quint16>(parsed);
            }
            ++i;
            continue;
        }
        if (arg == QStringLiteral("--token") && i + 1 < args.size()) {
            token = args.at(i + 1).trimmed();
            ++i;
            continue;
        }
        if (arg == QStringLiteral("--idle-timeout-ms") && i + 1 < args.size()) {
            bool ok = false;
            const int parsed = args.at(i + 1).toInt(&ok);
            if (ok && parsed >= 30000) {
                idleTimeoutMs = parsed;
            }
            ++i;
            continue;
        }
    }

    if (port == 0 || token.isEmpty()) {
        return 2;
    }

    TunHelperServer server(token, port, idleTimeoutMs);
    return app.exec();
}

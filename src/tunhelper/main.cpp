#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QHostInfo>
#include <QHostAddress>
#include <QIODevice>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTcpServer>
#include <QTcpSocket>
#include <QThread>
#include <QTimer>
#include <QVector>
#include <climits>

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

void appendLineToFile(const QString& path, const QString& line)
{
    if (path.trimmed().isEmpty() || line.trimmed().isEmpty()) {
        return;
    }
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        return;
    }
    file.write(line.toUtf8());
    file.write("\n");
    file.close();
}

bool isIpv4(const QString& address);

#if defined(Q_OS_WIN)
struct WindowsTunAdapterInfo
{
    int index = 0;
    QString alias;
    QString ipv4;
};

bool looksLikeWindowsTunAdapterName(const QString& name)
{
    const QString lower = name.toLower();
    return lower.contains(QStringLiteral("xray"))
        || lower.contains(QStringLiteral("wintun"))
        || lower.contains(QStringLiteral("genyconnect"));
}

QVector<WindowsTunAdapterInfo> collectWindowsTunAdapters()
{
    QVector<WindowsTunAdapterInfo> adapters;
    const auto interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface& iface : interfaces) {
        if (iface.flags().testFlag(QNetworkInterface::IsLoopBack)) {
            continue;
        }
        const QString human = iface.humanReadableName().trimmed();
        const QString name = iface.name().trimmed();
        if (!looksLikeWindowsTunAdapterName(human) && !looksLikeWindowsTunAdapterName(name)) {
            continue;
        }

        WindowsTunAdapterInfo info;
        info.index = iface.index();
        info.alias = human.isEmpty() ? name : human;
        for (const QNetworkAddressEntry& entry : iface.addressEntries()) {
            const QHostAddress ip = entry.ip();
            if (ip.protocol() != QAbstractSocket::IPv4Protocol) {
                continue;
            }
            const QString ipText = ip.toString().trimmed();
            if (ipText.isEmpty() || ipText == QStringLiteral("127.0.0.1")) {
                continue;
            }
            info.ipv4 = ipText;
            break;
        }

        if (info.index > 0) {
            adapters.append(info);
        }
    }
    return adapters;
}

WindowsTunAdapterInfo findWindowsTunAdapter()
{
    WindowsTunAdapterInfo best;
    int bestScore = -1;

    const QVector<WindowsTunAdapterInfo> adapters = collectWindowsTunAdapters();
    const auto interfaces = QNetworkInterface::allInterfaces();

    auto interfaceFlagsForIndex = [&interfaces](int index) {
        for (const QNetworkInterface& iface : interfaces) {
            if (iface.index() == index) {
                return iface.flags();
            }
        }
        return QNetworkInterface::InterfaceFlags{};
    };

    for (const WindowsTunAdapterInfo& info : adapters) {
        if (info.index <= 0) {
            continue;
        }

        const QNetworkInterface::InterfaceFlags flags = interfaceFlagsForIndex(info.index);
        const bool up = flags.testFlag(QNetworkInterface::IsUp)
                        && flags.testFlag(QNetworkInterface::IsRunning);
        const bool hasIpv4 = !info.ipv4.trimmed().isEmpty();

        int score = 0;
        if (up) {
            score += 1000;
        }
        if (hasIpv4) {
            score += 500;
        }
        // Prefer newest adapter instance in case stale adapters remain.
        score += info.index;

        if (score > bestScore) {
            best = info;
            bestScore = score;
        }
    }

    return best;
}

void deleteWindowsRouteBestEffort(
    const QString& destination,
    const QString& netmask,
    const QString& gateway,
    int interfaceIndex);

void deleteWindowsRouteV6BestEffort(const QString& destination, int interfaceIndex);

void cleanupSplitRoutesForAdapter(int interfaceIndex)
{
    if (interfaceIndex <= 0) {
        return;
    }
    deleteWindowsRouteBestEffort(
        QStringLiteral("0.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        interfaceIndex);
    deleteWindowsRouteBestEffort(
        QStringLiteral("128.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        interfaceIndex);
    deleteWindowsRouteV6BestEffort(QStringLiteral("::/1"), interfaceIndex);
    deleteWindowsRouteV6BestEffort(QStringLiteral("8000::/1"), interfaceIndex);
}

bool runWindowsRoute(const QStringList& args, int timeoutMs, QString* stdoutText, QString* stderrText)
{
    return runProcess(QStringLiteral("route.exe"), args, timeoutMs, stdoutText, stderrText);
}

QString mergeCommandOutput(const QString& stdoutText, const QString& stderrText)
{
    const QString merged = QStringList{stdoutText.trimmed(), stderrText.trimmed()}
                               .join(QStringLiteral("\n"))
                               .trimmed();
    return merged;
}

QStringList splitWhitespaceTokens(const QString& line)
{
    return line.split(QRegularExpression(QStringLiteral("\\s+")), Qt::SkipEmptyParts);
}

QString defaultGatewayFromRoutePrint(QString* errorOut)
{
    QString stdoutText;
    QString stderrText;
    if (!runWindowsRoute(
            {QStringLiteral("PRINT"), QStringLiteral("-4"), QStringLiteral("0.0.0.0")},
            4000,
            &stdoutText,
            &stderrText)) {
        if (errorOut != nullptr) {
            const QString reason = mergeCommandOutput(stdoutText, stderrText);
            *errorOut = reason.isEmpty()
                ? QStringLiteral("Failed to inspect default gateway route.")
                : reason;
        }
        return {};
    }

    const QStringList lines = stdoutText.split('\n');
    for (const QString& rawLine : lines) {
        const QStringList tokens = splitWhitespaceTokens(rawLine.trimmed());
        if (tokens.size() < 5) {
            continue;
        }
        if (tokens.at(0) == QStringLiteral("0.0.0.0")
            && tokens.at(1) == QStringLiteral("0.0.0.0")) {
            const QString gateway = tokens.at(2).trimmed();
            if (!gateway.isEmpty()
                && gateway.compare(QStringLiteral("On-link"), Qt::CaseInsensitive) != 0
                && gateway != QStringLiteral("0.0.0.0")) {
                return gateway;
            }
        }
    }

    if (errorOut != nullptr) {
        *errorOut = QStringLiteral("Default gateway not found in route table.");
    }
    return {};
}

bool addOrChangeWindowsRoute(
    const QString& destination,
    const QString& netmask,
    const QString& gateway,
    int interfaceIndex,
    int metric,
    QString* errorOut)
{
    auto buildArgs = [&](const QString& verb) {
        QStringList args{verb, destination, QStringLiteral("MASK"), netmask, gateway};
        if (interfaceIndex > 0) {
            args << QStringLiteral("IF") << QString::number(interfaceIndex);
        }
        if (metric > 0) {
            args << QStringLiteral("METRIC") << QString::number(metric);
        }
        return args;
    };

    QString outAdd;
    QString errAdd;
    if (runWindowsRoute(buildArgs(QStringLiteral("ADD")), 5000, &outAdd, &errAdd)) {
        return true;
    }

    QString outChange;
    QString errChange;
    if (runWindowsRoute(buildArgs(QStringLiteral("CHANGE")), 5000, &outChange, &errChange)) {
        return true;
    }

    if (errorOut != nullptr) {
        const QString reason = mergeCommandOutput(
            mergeCommandOutput(outAdd, errAdd),
            mergeCommandOutput(outChange, errChange));
        *errorOut = reason.isEmpty()
            ? QStringLiteral("Failed to configure route %1/%2").arg(destination, netmask)
            : reason;
    }
    return false;
}

bool addOrChangeWindowsRouteV6(
    const QString& destination,
    int interfaceIndex,
    int metric,
    QString* errorOut)
{
    auto buildArgs = [&](const QString& verb) {
        QStringList args{
            QStringLiteral("-6"),
            verb,
            destination,
            QStringLiteral("::")
        };
        if (interfaceIndex > 0) {
            args << QStringLiteral("IF") << QString::number(interfaceIndex);
        }
        if (metric > 0) {
            args << QStringLiteral("METRIC") << QString::number(metric);
        }
        return args;
    };

    QString outAdd;
    QString errAdd;
    if (runWindowsRoute(buildArgs(QStringLiteral("ADD")), 5000, &outAdd, &errAdd)) {
        return true;
    }

    QString outChange;
    QString errChange;
    if (runWindowsRoute(buildArgs(QStringLiteral("CHANGE")), 5000, &outChange, &errChange)) {
        return true;
    }

    if (errorOut != nullptr) {
        const QString reason = mergeCommandOutput(
            mergeCommandOutput(outAdd, errAdd),
            mergeCommandOutput(outChange, errChange));
        *errorOut = reason.isEmpty()
            ? QStringLiteral("Failed to configure IPv6 route %1").arg(destination)
            : reason;
    }
    return false;
}

void deleteWindowsRouteBestEffort(
    const QString& destination,
    const QString& netmask,
    const QString& gateway,
    int interfaceIndex)
{
    QStringList args{
        QStringLiteral("DELETE"),
        destination,
        QStringLiteral("MASK"),
        netmask,
        gateway
    };
    if (interfaceIndex > 0) {
        args << QStringLiteral("IF") << QString::number(interfaceIndex);
    }
    QString ignoredOut;
    QString ignoredErr;
    Q_UNUSED(runWindowsRoute(args, 3000, &ignoredOut, &ignoredErr));
}

void deleteWindowsRouteV6BestEffort(const QString& destination, int interfaceIndex)
{
    QStringList args{
        QStringLiteral("-6"),
        QStringLiteral("DELETE"),
        destination,
        QStringLiteral("::")
    };
    if (interfaceIndex > 0) {
        args << QStringLiteral("IF") << QString::number(interfaceIndex);
    }
    QString ignoredOut;
    QString ignoredErr;
    Q_UNUSED(runWindowsRoute(args, 3000, &ignoredOut, &ignoredErr));
}

bool routeTableHasEntry(
    const QString& routeTable,
    const QString& destination,
    const QString& netmask,
    const QString& interfaceIp)
{
    const QStringList lines = routeTable.split('\n');
    for (const QString& rawLine : lines) {
        const QStringList tokens = splitWhitespaceTokens(rawLine.trimmed());
        if (tokens.size() < 5) {
            continue;
        }
        if (tokens.at(0) != destination || tokens.at(1) != netmask) {
            continue;
        }
        if (interfaceIp.trimmed().isEmpty()) {
            return true;
        }
        if (tokens.at(3).compare(interfaceIp.trimmed(), Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

bool parseIpv4ToUInt32(const QString& value, quint32* out)
{
    if (out == nullptr) {
        return false;
    }
    const QStringList octets = value.trimmed().split('.');
    if (octets.size() != 4) {
        return false;
    }
    quint32 parsed = 0;
    for (int i = 0; i < 4; ++i) {
        bool ok = false;
        const int part = octets.at(i).toInt(&ok);
        if (!ok || part < 0 || part > 255) {
            return false;
        }
        parsed = (parsed << 8) | static_cast<quint32>(part);
    }
    *out = parsed;
    return true;
}

int ipv4PrefixLength(quint32 mask)
{
    int bits = 0;
    for (int i = 31; i >= 0; --i) {
        if ((mask & (1u << i)) == 0) {
            break;
        }
        ++bits;
    }
    return bits;
}

struct WindowsRouteEntry
{
    quint32 destination = 0;
    quint32 netmask = 0;
    QString interfaceIp;
    int metric = INT_MAX;
};

QVector<WindowsRouteEntry> parseWindowsIpv4Routes(const QString& routeTable)
{
    QVector<WindowsRouteEntry> routes;
    const QStringList lines = routeTable.split('\n');
    for (const QString& rawLine : lines) {
        const QStringList tokens = splitWhitespaceTokens(rawLine.trimmed());
        if (tokens.size() < 5) {
            continue;
        }

        quint32 destination = 0;
        quint32 netmask = 0;
        if (!parseIpv4ToUInt32(tokens.at(0), &destination)
            || !parseIpv4ToUInt32(tokens.at(1), &netmask)) {
            continue;
        }

        const QString interfaceIp = tokens.at(3).trimmed();
        quint32 parsedInterface = 0;
        if (!parseIpv4ToUInt32(interfaceIp, &parsedInterface)) {
            continue;
        }

        bool metricOk = false;
        const int metric = tokens.last().toInt(&metricOk);
        if (!metricOk) {
            continue;
        }

        WindowsRouteEntry entry;
        entry.destination = destination;
        entry.netmask = netmask;
        entry.interfaceIp = interfaceIp;
        entry.metric = metric;
        routes.append(entry);
    }
    return routes;
}

QString selectedInterfaceForDestination(
    const QVector<WindowsRouteEntry>& routes,
    const QString& destinationIp)
{
    quint32 target = 0;
    if (!parseIpv4ToUInt32(destinationIp, &target)) {
        return {};
    }

    const WindowsRouteEntry* best = nullptr;
    int bestPrefix = -1;
    int bestMetric = INT_MAX;
    for (const WindowsRouteEntry& route : routes) {
        if ((target & route.netmask) != (route.destination & route.netmask)) {
            continue;
        }
        const int prefix = ipv4PrefixLength(route.netmask);
        if (best == nullptr
            || prefix > bestPrefix
            || (prefix == bestPrefix && route.metric < bestMetric)) {
            best = &route;
            bestPrefix = prefix;
            bestMetric = route.metric;
        }
    }

    return best == nullptr ? QString() : best->interfaceIp;
}

bool hasWindowsIpv6DefaultRoute()
{
    QString stdoutText;
    QString stderrText;
    if (!runWindowsRoute(
            {QStringLiteral("PRINT"), QStringLiteral("-6")},
            3500,
            &stdoutText,
            &stderrText)) {
        Q_UNUSED(stderrText)
        return false;
    }
    static const QRegularExpression defaultRouteShort(QStringLiteral("(^|\\s)::/0(\\s|$)"),
                                                      QRegularExpression::MultilineOption);
    static const QRegularExpression defaultRouteLong(
        QStringLiteral("(^|\\s)0:0:0:0:0:0:0:0/0(\\s|$)"),
        QRegularExpression::MultilineOption);
    return defaultRouteShort.match(stdoutText).hasMatch()
        || defaultRouteLong.match(stdoutText).hasMatch();
}

bool serverRouteUsesTun(
    const QString& routeTable,
    const QString& serverIp,
    const QString& tunInterfaceIp)
{
    const QString server = serverIp.trimmed();
    const QString tunIp = tunInterfaceIp.trimmed();
    if (server.isEmpty() || tunIp.isEmpty()) {
        return false;
    }
    const QStringList lines = routeTable.split('\n');
    for (const QString& rawLine : lines) {
        const QStringList tokens = splitWhitespaceTokens(rawLine.trimmed());
        if (tokens.size() < 5) {
            continue;
        }
        if (tokens.at(0) == server
            && tokens.at(1) == QStringLiteral("255.255.255.255")
            && tokens.at(3).compare(tunIp, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

bool applyWindowsTunRoutes(const QString& serverIp, WindowsTunAdapterInfo* activeTunOut, QString* errorOut)
{
    const QString server = (isIpv4(serverIp) ? serverIp.trimmed() : QString());

    WindowsTunAdapterInfo tunInfo;
    for (int i = 0; i < 140; ++i) {
        tunInfo = findWindowsTunAdapter();
        if (tunInfo.index > 0 && !tunInfo.ipv4.trimmed().isEmpty()) {
            break;
        }
        QThread::msleep(150);
    }
    if (tunInfo.index <= 0 || tunInfo.ipv4.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Windows TUN adapter IPv4 is not ready yet.");
        }
        return false;
    }
    if (activeTunOut != nullptr) {
        *activeTunOut = tunInfo;
    }

    // Cleanup only active adapter routes before applying fresh split routes.
    cleanupSplitRoutesForAdapter(tunInfo.index);
    // Also remove non-interface-specific leftovers (best effort).
    deleteWindowsRouteBestEffort(
        QStringLiteral("0.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        0);
    deleteWindowsRouteBestEffort(
        QStringLiteral("128.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        0);

    QString routeError;
    if (!addOrChangeWindowsRoute(
            QStringLiteral("0.0.0.0"),
            QStringLiteral("128.0.0.0"),
            QStringLiteral("0.0.0.0"),
            tunInfo.index,
            3,
            &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.isEmpty()
                ? QStringLiteral("Failed to apply split default route 0.0.0.0/1.")
                : routeError;
        }
        return false;
    }

    if (!addOrChangeWindowsRoute(
            QStringLiteral("128.0.0.0"),
            QStringLiteral("128.0.0.0"),
            QStringLiteral("0.0.0.0"),
            tunInfo.index,
            3,
            &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.isEmpty()
                ? QStringLiteral("Failed to apply split default route 128.0.0.0/1.")
                : routeError;
        }
        return false;
    }

    // IPv6 leak guard: best-effort split default routes to TUN.
    QString v6Error;
    const bool v6a = addOrChangeWindowsRouteV6(QStringLiteral("::/1"), tunInfo.index, 3, &v6Error);
    const bool v6b = addOrChangeWindowsRouteV6(QStringLiteral("8000::/1"), tunInfo.index, 3, &v6Error);
    if (!v6a || !v6b) {
        // If the system has an IPv6 default route, failing to install split v6
        // routes can leak traffic outside TUN. In that case fail startup.
        if (hasWindowsIpv6DefaultRoute()) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Failed to apply mandatory IPv6 split routes for TUN (%1).")
                                .arg(v6Error.trimmed().isEmpty() ? QStringLiteral("restricted environment")
                                                                 : v6Error.trimmed());
            }
            return false;
        }
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Windows route setup warning: IPv6 split-route not fully applied (%1).")
                            .arg(v6Error.trimmed().isEmpty() ? QStringLiteral("restricted environment")
                                                             : v6Error.trimmed());
        }
    }

    if (!server.isEmpty()) {
        QString gatewayError;
        const QString gateway = defaultGatewayFromRoutePrint(&gatewayError);
        if (!gateway.isEmpty()) {
            deleteWindowsRouteBestEffort(
                server,
                QStringLiteral("255.255.255.255"),
                gateway,
                0);
            if (!addOrChangeWindowsRoute(
                    server,
                    QStringLiteral("255.255.255.255"),
                    gateway,
                    0,
                    3,
                    &routeError)) {
                if (errorOut != nullptr) {
                    *errorOut = routeError.isEmpty()
                        ? QStringLiteral("Failed to apply VPN server bypass route.")
                        : routeError;
                }
                return false;
            }
        } else if (errorOut != nullptr && !gatewayError.trimmed().isEmpty()) {
            *errorOut = QStringLiteral("Windows route setup warning: %1").arg(gatewayError.trimmed());
        }
    }

    if (errorOut != nullptr) {
        *errorOut = QStringLiteral("tun=%1;idx=%2")
                        .arg(tunInfo.alias.isEmpty() ? QStringLiteral("unknown") : tunInfo.alias)
                        .arg(tunInfo.index);
    }
    return true;
}

bool cleanupWindowsTunRoutes(const QString& serverIp, QString* errorOut)
{
    const QString server = (isIpv4(serverIp) ? serverIp.trimmed() : QString());
    const WindowsTunAdapterInfo tunInfo = findWindowsTunAdapter();
    cleanupSplitRoutesForAdapter(tunInfo.index);
    // Best effort cleanup for routes that may have been left without IF binding.
    deleteWindowsRouteBestEffort(
        QStringLiteral("0.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        0);
    deleteWindowsRouteBestEffort(
        QStringLiteral("128.0.0.0"),
        QStringLiteral("128.0.0.0"),
        QStringLiteral("0.0.0.0"),
        0);
    if (!server.isEmpty()) {
        deleteWindowsRouteBestEffort(
            server,
            QStringLiteral("255.255.255.255"),
            QStringLiteral("0.0.0.0"),
            0);
    }
    if (errorOut != nullptr) {
        errorOut->clear();
    }
    return true;
}

bool validateWindowsTunRouting(
    const QString& serverIp,
    const WindowsTunAdapterInfo& expectedTun,
    QString* errorOut)
{
    const QString server = (isIpv4(serverIp) ? serverIp.trimmed() : QString());
    QString lastError = QStringLiteral("Windows route validation failed.");
    QString selectedA;
    QString selectedB;
    const QString expectedIf = expectedTun.ipv4.trimmed();
    const int expectedIndex = expectedTun.index;
    if (expectedIf.isEmpty() || expectedIndex <= 0) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Windows TUN validation failed: active adapter info is unavailable.");
        }
        return false;
    }

    for (int attempt = 0; attempt < 120; ++attempt) {
        WindowsTunAdapterInfo tunInfo = findWindowsTunAdapter();
        if (tunInfo.index <= 0 || tunInfo.ipv4.trimmed().isEmpty()) {
            lastError = QStringLiteral("Windows TUN adapter state is not ready for validation.");
            QThread::msleep(150);
            continue;
        }

        if (tunInfo.index != expectedIndex) {
            lastError = QStringLiteral("Windows TUN adapter index changed during validation.");
            QThread::msleep(150);
            continue;
        }

        if (tunInfo.ipv4.trimmed().compare(expectedIf, Qt::CaseInsensitive) != 0) {
            lastError = QStringLiteral("Windows TUN adapter IPv4 changed during validation.");
            QThread::msleep(150);
            continue;
        }

        QString routeTable;
        QString routeError;
        if (!runWindowsRoute(
                {QStringLiteral("PRINT"), QStringLiteral("-4")},
                3500,
                &routeTable,
                &routeError)) {
            lastError = routeError.trimmed().isEmpty()
                ? QStringLiteral("Windows route probe unavailable.")
                : routeError.trimmed();
            QThread::msleep(120);
            continue;
        }

        const bool splitAReady = routeTableHasEntry(
            routeTable,
            QStringLiteral("0.0.0.0"),
            QStringLiteral("128.0.0.0"),
            expectedIf);
        const bool splitBReady = routeTableHasEntry(
            routeTable,
            QStringLiteral("128.0.0.0"),
            QStringLiteral("128.0.0.0"),
            expectedIf);

        const QVector<WindowsRouteEntry> routes = parseWindowsIpv4Routes(routeTable);
        selectedA = selectedInterfaceForDestination(routes, QStringLiteral("1.1.1.1"));
        selectedB = selectedInterfaceForDestination(routes, QStringLiteral("129.0.0.1"));
        const bool selectedToTun = !selectedA.isEmpty()
            && !selectedB.isEmpty()
            && selectedA.compare(expectedIf, Qt::CaseInsensitive) == 0
            && selectedB.compare(expectedIf, Qt::CaseInsensitive) == 0;

        if (!splitAReady || !splitBReady || !selectedToTun) {
            lastError = QStringLiteral("Windows TUN split-routes are not active yet.");
            QThread::msleep(150);
            continue;
        }

        if (serverRouteUsesTun(routeTable, server, expectedIf)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Windows TUN validation failed: server route is bound to TUN.");
            }
            return false;
        }

        if (errorOut != nullptr) {
            errorOut->clear();
        }
        return true;
    }

    if (errorOut != nullptr) {
        *errorOut = QStringLiteral("%1 Expected interface: %2, selected(1.1.1.1): %3, selected(129.0.0.1): %4")
                        .arg(lastError,
                             expectedIf.isEmpty() ? QStringLiteral("unavailable") : expectedIf,
                             selectedA.isEmpty() ? QStringLiteral("unavailable") : selectedA,
                             selectedB.isEmpty() ? QStringLiteral("unavailable") : selectedB);
    }
    return false;
}
#endif

#if defined(Q_OS_LINUX)
QString linuxIpTool()
{
    const QString ipFromPath = QStandardPaths::findExecutable(QStringLiteral("ip"));
    if (!ipFromPath.trimmed().isEmpty()) {
        return ipFromPath;
    }
    const QStringList candidates {
        QStringLiteral("/sbin/ip"),
        QStringLiteral("/usr/sbin/ip"),
        QStringLiteral("/bin/ip"),
        QStringLiteral("/usr/bin/ip")
    };
    for (const QString& candidate : candidates) {
        if (QFileInfo::exists(candidate) && QFileInfo(candidate).isExecutable()) {
            return candidate;
        }
    }
    return {};
}

QString linuxRouteDeviceFor(const QString& destination, QString* errorOut)
{
    const QString target = destination.trimmed();
    if (target.isEmpty()) {
        return {};
    }

    const QString ipTool = linuxIpTool();
    if (ipTool.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Linux route inspection failed: `ip` utility not found.");
        }
        return {};
    }

    QString stdoutText;
    QString stderrText;
    const bool ok = runProcess(
        ipTool,
        {QStringLiteral("-4"), QStringLiteral("route"), QStringLiteral("get"), target},
        1200,
        &stdoutText,
        &stderrText);
    if (!ok) {
        if (errorOut != nullptr) {
            *errorOut = stderrText.trimmed().isEmpty()
                ? QStringLiteral("Failed to inspect Linux route for %1.").arg(target)
                : stderrText.trimmed();
        }
        return {};
    }

    static const QRegularExpression devRegex(QStringLiteral("\\bdev\\s+(\\S+)"));
    const QRegularExpressionMatch match = devRegex.match(stdoutText);
    if (!match.hasMatch()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Failed to parse Linux route device for %1.").arg(target);
        }
        return {};
    }
    return match.captured(1).trimmed();
}

bool validateLinuxTunRouting(const QString& requestedTunIf, const QString& serverIp, QString* errorOut)
{
    QString lastError;
    const QString requiredTun = requestedTunIf.trimmed();
    for (int i = 0; i < 20; ++i) {
        QString errA;
        QString errB;
        const QString devA = linuxRouteDeviceFor(QStringLiteral("1.1.1.1"), &errA);
        const QString devB = linuxRouteDeviceFor(QStringLiteral("129.0.0.1"), &errB);
        if (!devA.isEmpty() && devA == devB) {
            const bool looksTun = devA.startsWith(QStringLiteral("tun"), Qt::CaseInsensitive)
                                  || devA.startsWith(QStringLiteral("tap"), Qt::CaseInsensitive)
                                  || devA.contains(QStringLiteral("xray"), Qt::CaseInsensitive);
            const bool matchesRequested = requiredTun.isEmpty()
                                          || devA.compare(requiredTun, Qt::CaseInsensitive) == 0;
            if (looksTun && matchesRequested) {
                if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
                    QString serverErr;
                    const QString serverDev = linuxRouteDeviceFor(serverIp.trimmed(), &serverErr);
                    if (!serverDev.isEmpty() && serverDev.compare(devA, Qt::CaseInsensitive) == 0) {
                        lastError = QStringLiteral("VPN server endpoint route is still pointed at TUN.");
                    } else {
                        return true;
                    }
                } else {
                    return true;
                }
            } else if (!matchesRequested) {
                lastError = QStringLiteral("Linux default route device (%1) does not match requested TUN interface (%2).")
                                .arg(devA, requiredTun);
            } else {
                lastError = QStringLiteral("Linux default route device (%1) is not a TUN interface.").arg(devA);
            }
        } else {
            lastError = !errA.isEmpty() ? errA : errB;
        }
        QThread::msleep(140);
    }

    if (errorOut != nullptr) {
        *errorOut = lastError.trimmed().isEmpty()
            ? QStringLiteral("Linux TUN routes were not applied correctly.")
            : lastError.trimmed();
    }
    return false;
}
#endif

#if defined(Q_OS_MACOS)
QString macDefaultGateway()
{
    QString stdoutText;
    QString stderrText;
    if (!runProcess(QStringLiteral("/sbin/route"),
                    {QStringLiteral("-n"), QStringLiteral("get"), QStringLiteral("default")},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }

    static const QRegularExpression gatewayRegex(QStringLiteral("\\bgateway:\\s*([^\\s]+)"));
    const QRegularExpressionMatch match = gatewayRegex.match(stdoutText);
    if (!match.hasMatch()) {
        return {};
    }
    return match.captured(1).trimmed();
}

QString macRouteInterfaceFor(const QString& destination)
{
    const QString target = destination.trimmed();
    if (target.isEmpty()) {
        return {};
    }
    QString stdoutText;
    QString stderrText;
    if (!runProcess(QStringLiteral("/sbin/route"),
                    {QStringLiteral("-n"), QStringLiteral("get"), target},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }
    static const QRegularExpression ifRegex(QStringLiteral("\\binterface:\\s*([^\\s]+)"));
    const QRegularExpressionMatch match = ifRegex.match(stdoutText);
    if (!match.hasMatch()) {
        return {};
    }
    return match.captured(1).trimmed();
}

bool cleanupMacTunRoutes(const QString& tunIf, const QString& serverIp)
{
    if (tunIf.trimmed().isEmpty()) {
        return true;
    }
    QString command;
    if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
        command += QStringLiteral("route -n delete -host %1 >/dev/null 2>&1 || true;").arg(serverIp.trimmed());
    }
    command += QStringLiteral(
        "route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
        "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
                   .arg(tunIf.trimmed());
    QString ignored;
    return runShell(command, 3000, &ignored);
}

bool applyMacTunRoutes(const QString& tunIf, const QString& serverIp, QString* errorOut)
{
    if (tunIf.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Missing TUN interface name for route setup.");
        }
        return false;
    }

    const QString gateway = macDefaultGateway();
    if (gateway.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Unable to detect macOS default gateway for TUN routing.");
        }
        return false;
    }

    QString command;
    if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
        // Keep the upstream server reachable outside tunnel to avoid route loops.
        command += QStringLiteral(
                       "route -n add -host %1 %2 >/dev/null 2>&1 || "
                       "route -n change -host %1 %2 >/dev/null 2>&1 || true;")
                       .arg(serverIp.trimmed(), gateway);
    }
    command += QStringLiteral(
        "route -n add -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
        "route -n add -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
                   .arg(tunIf.trimmed());

    QString routeError;
    if (!runShell(command, 6000, &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.trimmed().isEmpty()
                ? QStringLiteral("Failed to apply macOS TUN routes.")
                : routeError.trimmed();
        }
        return false;
    }

    // Validate split routes are really active on the target utun.
    const QString ifA = macRouteInterfaceFor(QStringLiteral("1.1.1.1"));
    const QString ifB = macRouteInterfaceFor(QStringLiteral("129.0.0.1"));
    if (ifA.compare(tunIf, Qt::CaseInsensitive) != 0
        || ifB.compare(tunIf, Qt::CaseInsensitive) != 0) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("macOS TUN split routes were not applied correctly.");
        }
        return false;
    }

    if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
        const QString serverIface = macRouteInterfaceFor(serverIp.trimmed());
        if (serverIface.compare(tunIf, Qt::CaseInsensitive) == 0) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("VPN server endpoint route is still pointed at TUN.");
            }
            return false;
        }
    }
    return true;
}
#endif

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
    response.insert(QStringLiteral("helper_pid"), static_cast<qint64>(QCoreApplication::applicationPid()));
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
        if (QFile::exists(pidPath)) {
            QFile oldPidFile(pidPath);
            if (oldPidFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                const QString oldPidText = QString::fromUtf8(oldPidFile.readAll()).trimmed();
                bool oldPidOk = false;
                const qint64 oldPid = oldPidText.toLongLong(&oldPidOk);
                if (oldPidOk && oldPid > 0) {
                    QString ignoredOut;
                    QString ignoredErr;
                    Q_UNUSED(runProcess(
                        QStringLiteral("taskkill"),
                        {QStringLiteral("/PID"), QString::number(oldPid), QStringLiteral("/T"), QStringLiteral("/F")},
                        5000,
                        &ignoredOut,
                        &ignoredErr));
                }
            }
            QFile::remove(pidPath);
        }

        const QString workingDir = QFileInfo(xrayPath).absolutePath();
        qint64 pidValue = 0;
        QProcess detachedProcess;
        detachedProcess.setProgram(xrayPath);
        detachedProcess.setArguments({QStringLiteral("run"), QStringLiteral("-config"), configPath});
        detachedProcess.setWorkingDirectory(workingDir);
        detachedProcess.setStandardOutputFile(logPath, QIODevice::Append);
        detachedProcess.setStandardErrorFile(logPath, QIODevice::Append);
        const bool started = detachedProcess.startDetached(&pidValue);
        if (!started || pidValue <= 0) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Failed to start Xray in privileged helper.");
            }
            return false;
        }

        QFile pidFileOut(pidPath);
        if (!pidFileOut.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Failed to write privileged TUN pid file.");
            }
            return false;
        }
        pidFileOut.write(QByteArray::number(pidValue));
        pidFileOut.close();
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

        // Wait until xray creates the requested utun interface.
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

        // Cleanup stale legacy split-routes from older builds (best effort).
        QString cleanupServerIp = resolveIpv4ForHost(serverIpRequested);
        if (cleanupServerIp.isEmpty()) {
            cleanupServerIp = resolveIpv4ForHost(serverHostRequested);
        }
        Q_UNUSED(cleanupMacTunRoutes(tunIf, cleanupServerIp));

        // Route system traffic through TUN and keep server endpoint direct.
        QString routeError;
        if (!applyMacTunRoutes(tunIf, cleanupServerIp, &routeError)) {
            const QString cleanupCmd = QStringLiteral(
                "if [ -f %1 ]; then PID=$(cat %1); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %1; fi")
                .arg(quoteForSh(pidPath));
            QString ignored;
            runShell(cleanupCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? QStringLiteral("Failed to apply TUN routes.")
                    : routeError.trimmed();
            }
            return false;
        }
#elif defined(Q_OS_WIN)
        QString resolvedServerIp = resolveIpv4ForHost(serverIpRequested);
        if (resolvedServerIp.isEmpty()) {
            resolvedServerIp = resolveIpv4ForHost(serverHostRequested);
        }
        QString applyRouteNote;
        WindowsTunAdapterInfo activeTun;
        if (!applyWindowsTunRoutes(resolvedServerIp, &activeTun, &applyRouteNote)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {QStringLiteral("pid_path"), pidPath},
                {QStringLiteral("tun_if"), QString()},
                {QStringLiteral("server_ip"), resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = applyRouteNote.trimmed().isEmpty()
                    ? QStringLiteral("Failed to apply Windows TUN routes.")
                    : applyRouteNote.trimmed();
            }
            return false;
        } else {
            appendLineToFile(
                logPath,
                QStringLiteral("[System] Windows route setup: %1;ip=%2")
                    .arg(applyRouteNote.trimmed(),
                         activeTun.ipv4.trimmed().isEmpty() ? QStringLiteral("unavailable")
                                                            : activeTun.ipv4.trimmed()));
        }

        QString routeError;
        if (!validateWindowsTunRouting(resolvedServerIp, activeTun, &routeError)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {QStringLiteral("pid_path"), pidPath},
                {QStringLiteral("tun_if"), QString()},
                {QStringLiteral("server_ip"), resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? QStringLiteral("Failed to validate Windows TUN routes.")
                    : routeError.trimmed();
            }
            return false;
        } else if (!routeError.trimmed().isEmpty()) {
            appendLineToFile(logPath, QStringLiteral("[System] Windows route probe warning: %1").arg(routeError.trimmed()));
        }
#elif defined(Q_OS_LINUX)
        QString resolvedServerIp = resolveIpv4ForHost(serverIpRequested);
        if (resolvedServerIp.isEmpty()) {
            resolvedServerIp = resolveIpv4ForHost(serverHostRequested);
        }
        QString routeError;
        if (!validateLinuxTunRouting(tunIf, resolvedServerIp, &routeError)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {QStringLiteral("pid_path"), pidPath},
                {QStringLiteral("tun_if"), tunIf},
                {QStringLiteral("server_ip"), resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? QStringLiteral("Failed to validate Linux TUN routes.")
                    : routeError.trimmed();
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
        Q_UNUSED(cleanupMacTunRoutes(tunIf, serverIp));
#else
        Q_UNUSED(tunIf)
        Q_UNUSED(serverIp)
#endif

#if defined(Q_OS_WIN)
        if (QFile::exists(pidPath)) {
            QFile pidFileIn(pidPath);
            if (pidFileIn.open(QIODevice::ReadOnly | QIODevice::Text)) {
                const QString pidText = QString::fromUtf8(pidFileIn.readAll()).trimmed();
                bool pidOk = false;
                const qint64 pidValue = pidText.toLongLong(&pidOk);
                if (pidOk && pidValue > 0) {
                    QString stopOut;
                    QString stopErr;
                    Q_UNUSED(runProcess(
                        QStringLiteral("taskkill"),
                        {QStringLiteral("/PID"), QString::number(pidValue), QStringLiteral("/T"), QStringLiteral("/F")},
                        7000,
                        &stopOut,
                        &stopErr));
                }
            }
            QFile::remove(pidPath);
        }
        QString cleanupError;
        if (!cleanupWindowsTunRoutes(serverIp, &cleanupError) && errorOut != nullptr && errorOut->trimmed().isEmpty()) {
            *errorOut = cleanupError.trimmed();
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

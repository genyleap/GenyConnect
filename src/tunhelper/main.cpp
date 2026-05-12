#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QHostInfo>
#include <QHostAddress>
#include <QIODevice>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QProcess>
#include <QRegularExpression>
#include <QSet>
#include <QStandardPaths>
#include <QTcpServer>
#include <QTcpSocket>
#include <QThread>
#include <QTimer>
#include <QVector>
#include <climits>
#if !defined(Q_OS_WIN)
#include <cerrno>
#include <csignal>
#include <unistd.h>
#endif
#if defined(Q_OS_WIN)
#include <windows.h>
#endif

using namespace Qt::StringLiterals;

namespace {

QString quoteForSh(const QString& value)
{
    QString escaped = value;
    escaped.replace('\'', "'\"'\"'");
    return u"'"_s + escaped + u"'"_s;
}

QString quoteForPowerShell(const QString& value)
{
    QString escaped = value;
    escaped.replace('\'', "''");
    return u"'"_s + escaped + u"'"_s;
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
            *stderrText = u"Failed to start process: %1"_s.arg(program);
        }
        return false;
    }

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(1000);
        if (stderrText != nullptr) {
            *stderrText = u"Process timed out: %1"_s.arg(program);
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
        u"powershell"_s,
        {
            u"-NoProfile"_s,
            u"-ExecutionPolicy"_s, u"Bypass"_s,
            u"-Command"_s, shellCommand
        },
        timeoutMs,
        &ignoredOut,
        stderrText);
#else
    QString ignoredOut;
    return runProcess(
        u"/bin/sh"_s,
        {u"-lc"_s, shellCommand},
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

QString lastNonEmptyLogLine(const QString& logPath)
{
    QFile logFile(logPath);
    if (!logFile.open(QIODevice::ReadOnly)) {
        return {};
    }

    const QList<QByteArray> lines = logFile.readAll().split('\n');
    for (int i = lines.size() - 1; i >= 0; --i) {
        const QString line = QString::fromUtf8(lines[i]).trimmed();
        if (!line.isEmpty()) {
            return line;
        }
    }
    return {};
}

bool isIpv4(const QString& address);
bool isIpv6(const QString& address);

#if defined(Q_OS_WIN)
struct WindowsTunAdapterInfo
{
    int index = 0;
    QString alias;
    QString ipv4;
};

QStringList defaultWindowsTunDnsServers()
{
    return {
        u"1.1.1.1"_s,
        u"8.8.8.8"_s,
        u"9.9.9.9"_s
    };
}

QString powershellListLiteral(const QStringList& values)
{
    QStringList quoted;
    for (const QString& value : values) {
        const QString trimmed = value.trimmed();
        if (!trimmed.isEmpty()) {
            quoted.append(quoteForPowerShell(trimmed));
        }
    }
    return quoted.join(u","_s);
}

QStringList stringListFromJsonArray(const QJsonArray& values)
{
    QStringList out;
    QSet<QString> seen;
    for (const QJsonValue& value : values) {
        const QString trimmed = value.toString().trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }
        QHostAddress ip;
        if (!ip.setAddress(trimmed)) {
            continue;
        }
        const QString normalized = ip.toString();
        const QString key = normalized.toLower();
        if (seen.contains(key)) {
            continue;
        }
        seen.insert(key);
        out.append(normalized);
    }
    return out;
}

bool looksLikeWindowsTunAdapterName(const QString& name)
{
    const QString lower = name.toLower();
    return lower.contains(u"xray"_s)
        || lower.contains(u"wintun"_s)
        || lower.contains(u"genyconnect"_s);
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
            if (ipText.isEmpty() || ipText == u"127.0.0.1"_s) {
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
        u"0.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        interfaceIndex);
    deleteWindowsRouteBestEffort(
        u"128.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        interfaceIndex);
    deleteWindowsRouteV6BestEffort(u"::/1"_s, interfaceIndex);
    deleteWindowsRouteV6BestEffort(u"8000::/1"_s, interfaceIndex);
}

bool runWindowsRoute(const QStringList& args, int timeoutMs, QString* stdoutText, QString* stderrText)
{
    return runProcess(u"route.exe"_s, args, timeoutMs, stdoutText, stderrText);
}

QString mergeCommandOutput(const QString& stdoutText, const QString& stderrText)
{
    const QString merged = QStringList{stdoutText.trimmed(), stderrText.trimmed()}
                               .join(u"\n"_s)
                               .trimmed();
    return merged;
}

QStringList splitWhitespaceTokens(const QString& line)
{
    return line.split(QRegularExpression(u"\\s+"_s), Qt::SkipEmptyParts);
}

QString defaultGatewayFromRoutePrint(QString* errorOut)
{
    QString stdoutText;
    QString stderrText;
    if (!runWindowsRoute(
            {u"PRINT"_s, u"-4"_s, u"0.0.0.0"_s},
            4000,
            &stdoutText,
            &stderrText)) {
        if (errorOut != nullptr) {
            const QString reason = mergeCommandOutput(stdoutText, stderrText);
            *errorOut = reason.isEmpty()
                ? u"Failed to inspect default gateway route."_s
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
        if (tokens.at(0) == u"0.0.0.0"_s
            && tokens.at(1) == u"0.0.0.0"_s) {
            const QString gateway = tokens.at(2).trimmed();
            if (!gateway.isEmpty()
                && gateway.compare(u"On-link"_s, Qt::CaseInsensitive) != 0
                && gateway != u"0.0.0.0"_s) {
                return gateway;
            }
        }
    }

    if (errorOut != nullptr) {
        *errorOut = u"Default gateway not found in route table."_s;
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
        QStringList args{verb, destination, u"MASK"_s, netmask, gateway};
        if (interfaceIndex > 0) {
            args << u"IF"_s << QString::number(interfaceIndex);
        }
        if (metric > 0) {
            args << u"METRIC"_s << QString::number(metric);
        }
        return args;
    };

    QString outAdd;
    QString errAdd;
    if (runWindowsRoute(buildArgs(u"ADD"_s), 5000, &outAdd, &errAdd)) {
        return true;
    }

    QString outChange;
    QString errChange;
    if (runWindowsRoute(buildArgs(u"CHANGE"_s), 5000, &outChange, &errChange)) {
        return true;
    }

    if (errorOut != nullptr) {
        const QString reason = mergeCommandOutput(
            mergeCommandOutput(outAdd, errAdd),
            mergeCommandOutput(outChange, errChange));
        *errorOut = reason.isEmpty()
            ? u"Failed to configure route %1/%2"_s.arg(destination, netmask)
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
            u"-6"_s,
            verb,
            destination,
            u"::"_s
        };
        if (interfaceIndex > 0) {
            args << u"IF"_s << QString::number(interfaceIndex);
        }
        if (metric > 0) {
            args << u"METRIC"_s << QString::number(metric);
        }
        return args;
    };

    QString outAdd;
    QString errAdd;
    if (runWindowsRoute(buildArgs(u"ADD"_s), 5000, &outAdd, &errAdd)) {
        return true;
    }

    QString outChange;
    QString errChange;
    if (runWindowsRoute(buildArgs(u"CHANGE"_s), 5000, &outChange, &errChange)) {
        return true;
    }

    if (errorOut != nullptr) {
        const QString reason = mergeCommandOutput(
            mergeCommandOutput(outAdd, errAdd),
            mergeCommandOutput(outChange, errChange));
        *errorOut = reason.isEmpty()
            ? u"Failed to configure IPv6 route %1"_s.arg(destination)
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
        u"DELETE"_s,
        destination,
        u"MASK"_s,
        netmask,
        gateway
    };
    if (interfaceIndex > 0) {
        args << u"IF"_s << QString::number(interfaceIndex);
    }
    QString ignoredOut;
    QString ignoredErr;
    Q_UNUSED(runWindowsRoute(args, 3000, &ignoredOut, &ignoredErr));
}

void deleteWindowsRouteV6BestEffort(const QString& destination, int interfaceIndex)
{
    QStringList args{
        u"-6"_s,
        u"DELETE"_s,
        destination,
        u"::"_s
    };
    if (interfaceIndex > 0) {
        args << u"IF"_s << QString::number(interfaceIndex);
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
            {u"PRINT"_s, u"-6"_s},
            3500,
            &stdoutText,
            &stderrText)) {
        Q_UNUSED(stderrText)
        return false;
    }
    static const QRegularExpression defaultRouteShort(u"(^|\\s)::/0(\\s|$)"_s,
                                                      QRegularExpression::MultilineOption);
    static const QRegularExpression defaultRouteLong(
        u"(^|\\s)0:0:0:0:0:0:0:0/0(\\s|$)"_s,
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
            && tokens.at(1) == u"255.255.255.255"_s
            && tokens.at(3).compare(tunIp, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

bool applyWindowsTunRoutes(
    const QString& serverIp,
    const QStringList& dnsServers,
    WindowsTunAdapterInfo* activeTunOut,
    QString* errorOut)
{
    const QString server = (isIpv4(serverIp) ? serverIp.trimmed() : QString());

    WindowsTunAdapterInfo tunInfo;
    for (int i = 0; i < 140; ++i) {
        tunInfo = findWindowsTunAdapter();
        if (tunInfo.index > 0) {
            break;
        }
        QThread::msleep(150);
    }
    if (tunInfo.index <= 0) {
        if (errorOut != nullptr) {
            *errorOut = u"Windows TUN adapter is not ready yet."_s;
        }
        return false;
    }

    const QStringList tunDnsServers = dnsServers.isEmpty()
        ? defaultWindowsTunDnsServers()
        : dnsServers;
    const QString configureCommand = QString::fromUtf8("$ErrorActionPreference='Stop';"
        "$idx=%1;"
        "Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4 -ErrorAction SilentlyContinue | "
        "Where-Object { $_.IPAddress -ne '172.19.0.1' } | "
        "Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue;"
        "if (-not (Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4 -IPAddress '172.19.0.1' -ErrorAction SilentlyContinue)) {"
        "  New-NetIPAddress -InterfaceIndex $idx -IPAddress '172.19.0.1' -PrefixLength 30 -SkipAsSource $false | Out-Null;"
        "}"
        "Set-DnsClientServerAddress -InterfaceIndex $idx -ServerAddresses @(%2);"
        "Clear-DnsClientCache;")
        .arg(QString::number(tunInfo.index), powershellListLiteral(tunDnsServers));
    QString configureError;
    if (!runShell(configureCommand, 10000, &configureError)) {
        if (errorOut != nullptr) {
            *errorOut = configureError.trimmed().isEmpty()
                ? u"Failed to configure Windows TUN adapter address/DNS."_s
                : configureError.trimmed();
        }
        return false;
    }

    for (int i = 0; i < 40; ++i) {
        tunInfo = findWindowsTunAdapter();
        if (tunInfo.index > 0
            && tunInfo.ipv4.trimmed().compare(u"172.19.0.1"_s, Qt::CaseInsensitive) == 0) {
            break;
        }
        QThread::msleep(150);
    }
    if (tunInfo.index <= 0
        || tunInfo.ipv4.trimmed().compare(u"172.19.0.1"_s, Qt::CaseInsensitive) != 0) {
        if (errorOut != nullptr) {
            *errorOut = u"Windows TUN adapter did not accept static IPv4 address."_s;
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
        u"0.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        0);
    deleteWindowsRouteBestEffort(
        u"128.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        0);

    QString routeError;
    if (!addOrChangeWindowsRoute(
            u"0.0.0.0"_s,
            u"128.0.0.0"_s,
            u"0.0.0.0"_s,
            tunInfo.index,
            3,
            &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.isEmpty()
                ? u"Failed to apply split default route 0.0.0.0/1."_s
                : routeError;
        }
        return false;
    }

    if (!addOrChangeWindowsRoute(
            u"128.0.0.0"_s,
            u"128.0.0.0"_s,
            u"0.0.0.0"_s,
            tunInfo.index,
            3,
            &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.isEmpty()
                ? u"Failed to apply split default route 128.0.0.0/1."_s
                : routeError;
        }
        return false;
    }

    // IPv6 leak guard: best-effort split default routes to TUN.
    QString v6Error;
    const bool v6a = addOrChangeWindowsRouteV6(u"::/1"_s, tunInfo.index, 3, &v6Error);
    const bool v6b = addOrChangeWindowsRouteV6(u"8000::/1"_s, tunInfo.index, 3, &v6Error);
    if (!v6a || !v6b) {
        // If the system has an IPv6 default route, failing to install split v6
        // routes can leak traffic outside TUN. In that case fail startup.
        if (hasWindowsIpv6DefaultRoute()) {
            if (errorOut != nullptr) {
                *errorOut = u"Failed to apply mandatory IPv6 split routes for TUN (%1)."_s
                                .arg(v6Error.trimmed().isEmpty() ? u"restricted environment"_s
                                                                 : v6Error.trimmed());
            }
            return false;
        }
        if (errorOut != nullptr) {
            *errorOut = u"Windows route setup warning: IPv6 split-route not fully applied (%1)."_s
                            .arg(v6Error.trimmed().isEmpty() ? u"restricted environment"_s
                                                             : v6Error.trimmed());
        }
    }

    if (!server.isEmpty()) {
        QString gatewayError;
        const QString gateway = defaultGatewayFromRoutePrint(&gatewayError);
        if (!gateway.isEmpty()) {
            deleteWindowsRouteBestEffort(
                server,
                u"255.255.255.255"_s,
                gateway,
                0);
            if (!addOrChangeWindowsRoute(
                    server,
                    u"255.255.255.255"_s,
                    gateway,
                    0,
                    3,
                    &routeError)) {
                if (errorOut != nullptr) {
                    *errorOut = routeError.isEmpty()
                        ? u"Failed to apply VPN server bypass route."_s
                        : routeError;
                }
                return false;
            }
        } else if (errorOut != nullptr && !gatewayError.trimmed().isEmpty()) {
            *errorOut = u"Windows route setup warning: %1"_s.arg(gatewayError.trimmed());
        }
    }

    if (errorOut != nullptr) {
        *errorOut = u"tun=%1;idx=%2"_s
                        .arg(tunInfo.alias.isEmpty() ? u"unknown"_s : tunInfo.alias)
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
        u"0.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        0);
    deleteWindowsRouteBestEffort(
        u"128.0.0.0"_s,
        u"128.0.0.0"_s,
        u"0.0.0.0"_s,
        0);
    if (!server.isEmpty()) {
        deleteWindowsRouteBestEffort(
            server,
            u"255.255.255.255"_s,
            u"0.0.0.0"_s,
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
    QString lastError = u"Windows route validation failed."_s;
    QString selectedA;
    QString selectedB;
    const QString expectedIf = expectedTun.ipv4.trimmed();
    const int expectedIndex = expectedTun.index;
    if (expectedIf.isEmpty() || expectedIndex <= 0) {
        if (errorOut != nullptr) {
            *errorOut = u"Windows TUN validation failed: active adapter info is unavailable."_s;
        }
        return false;
    }

    for (int attempt = 0; attempt < 120; ++attempt) {
        WindowsTunAdapterInfo tunInfo = findWindowsTunAdapter();
        if (tunInfo.index <= 0 || tunInfo.ipv4.trimmed().isEmpty()) {
            lastError = u"Windows TUN adapter state is not ready for validation."_s;
            QThread::msleep(150);
            continue;
        }

        if (tunInfo.index != expectedIndex) {
            lastError = u"Windows TUN adapter index changed during validation."_s;
            QThread::msleep(150);
            continue;
        }

        if (tunInfo.ipv4.trimmed().compare(expectedIf, Qt::CaseInsensitive) != 0) {
            lastError = u"Windows TUN adapter IPv4 changed during validation."_s;
            QThread::msleep(150);
            continue;
        }

        QString routeTable;
        QString routeError;
        if (!runWindowsRoute(
                {u"PRINT"_s, u"-4"_s},
                3500,
                &routeTable,
                &routeError)) {
            lastError = routeError.trimmed().isEmpty()
                ? u"Windows route probe unavailable."_s
                : routeError.trimmed();
            QThread::msleep(120);
            continue;
        }

        const bool splitAReady = routeTableHasEntry(
            routeTable,
            u"0.0.0.0"_s,
            u"128.0.0.0"_s,
            expectedIf);
        const bool splitBReady = routeTableHasEntry(
            routeTable,
            u"128.0.0.0"_s,
            u"128.0.0.0"_s,
            expectedIf);

        const QVector<WindowsRouteEntry> routes = parseWindowsIpv4Routes(routeTable);
        selectedA = selectedInterfaceForDestination(routes, u"1.1.1.1"_s);
        selectedB = selectedInterfaceForDestination(routes, u"129.0.0.1"_s);
        const bool selectedToTun = !selectedA.isEmpty()
            && !selectedB.isEmpty()
            && selectedA.compare(expectedIf, Qt::CaseInsensitive) == 0
            && selectedB.compare(expectedIf, Qt::CaseInsensitive) == 0;

        if (!splitAReady || !splitBReady || !selectedToTun) {
            lastError = u"Windows TUN split-routes are not active yet."_s;
            QThread::msleep(150);
            continue;
        }

        if (serverRouteUsesTun(routeTable, server, expectedIf)) {
            if (errorOut != nullptr) {
                *errorOut = u"Windows TUN validation failed: server route is bound to TUN."_s;
            }
            return false;
        }

        if (errorOut != nullptr) {
            errorOut->clear();
        }
        return true;
    }

    if (errorOut != nullptr) {
        *errorOut = u"%1 Expected interface: %2, selected(1.1.1.1): %3, selected(129.0.0.1): %4"_s
                        .arg(lastError,
                             expectedIf.isEmpty() ? u"unavailable"_s : expectedIf,
                             selectedA.isEmpty() ? u"unavailable"_s : selectedA,
                             selectedB.isEmpty() ? u"unavailable"_s : selectedB);
    }
    return false;
}
#endif

#if defined(Q_OS_LINUX)
QString linuxIpTool()
{
    const QString ipFromPath = QStandardPaths::findExecutable(u"ip"_s);
    if (!ipFromPath.trimmed().isEmpty()) {
        return ipFromPath;
    }
    const QStringList candidates {
        u"/sbin/ip"_s,
        u"/usr/sbin/ip"_s,
        u"/bin/ip"_s,
        u"/usr/bin/ip"_s
    };
    for (const QString& candidate : candidates) {
        if (QFileInfo::exists(candidate) && QFileInfo(candidate).isExecutable()) {
            return candidate;
        }
    }
    return {};
}

QString linuxRouteDeviceFor(const QString& destination, bool ipv6, QString* errorOut)
{
    const QString target = destination.trimmed();
    if (target.isEmpty()) {
        return {};
    }

    const QString ipTool = linuxIpTool();
    if (ipTool.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = u"Linux route inspection failed: `ip` utility not found."_s;
        }
        return {};
    }

    QString stdoutText;
    QString stderrText;
    const bool ok = runProcess(
        ipTool,
        {ipv6 ? u"-6"_s : u"-4"_s,
         u"route"_s,
         u"get"_s,
         target},
        1200,
        &stdoutText,
        &stderrText);
    if (!ok) {
        if (errorOut != nullptr) {
            *errorOut = stderrText.trimmed().isEmpty()
                ? u"Failed to inspect Linux %1 route for %2."_s
                      .arg(ipv6 ? u"IPv6"_s : u"IPv4"_s, target)
                : stderrText.trimmed();
        }
        return {};
    }

    static const QRegularExpression devRegex(u"\\bdev\\s+(\\S+)"_s);
    const QRegularExpressionMatch match = devRegex.match(stdoutText);
    if (!match.hasMatch()) {
        if (errorOut != nullptr) {
            *errorOut = u"Failed to parse Linux %1 route device for %2."_s
                            .arg(ipv6 ? u"IPv6"_s : u"IPv4"_s, target);
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
        const QString devA = linuxRouteDeviceFor(u"1.1.1.1"_s, false, &errA);
        const QString devB = linuxRouteDeviceFor(u"129.0.0.1"_s, false, &errB);
        if (!devA.isEmpty() && devA == devB) {
            const bool looksTun = devA.startsWith(u"tun"_s, Qt::CaseInsensitive)
                                  || devA.startsWith(u"tap"_s, Qt::CaseInsensitive)
                                  || devA.contains(u"xray"_s, Qt::CaseInsensitive);
            const bool matchesRequested = requiredTun.isEmpty()
                                          || devA.compare(requiredTun, Qt::CaseInsensitive) == 0;
            if (looksTun && matchesRequested) {
                if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
                    QString serverErr;
                    const QString serverDev = linuxRouteDeviceFor(serverIp.trimmed(), false, &serverErr);
                    if (!serverDev.isEmpty() && serverDev.compare(devA, Qt::CaseInsensitive) == 0) {
                        lastError = u"VPN server endpoint route is still pointed at TUN."_s;
                    } else {
                        return true;
                    }
                } else if (!serverIp.trimmed().isEmpty() && isIpv6(serverIp)) {
                    QString serverErr;
                    const QString serverDev = linuxRouteDeviceFor(serverIp.trimmed(), true, &serverErr);
                    if (!serverDev.isEmpty() && serverDev.compare(devA, Qt::CaseInsensitive) == 0) {
                        lastError = u"VPN server endpoint IPv6 route is still pointed at TUN."_s;
                    } else {
                        return true;
                    }
                } else {
                    return true;
                }
            } else if (!matchesRequested) {
                lastError = u"Linux default route device (%1) does not match requested TUN interface (%2)."_s
                                .arg(devA, requiredTun);
            } else {
                lastError = u"Linux default route device (%1) is not a TUN interface."_s.arg(devA);
            }
        } else {
            lastError = !errA.isEmpty() ? errA : errB;
        }
        QThread::msleep(140);
    }

    if (errorOut != nullptr) {
        *errorOut = lastError.trimmed().isEmpty()
            ? u"Linux TUN routes were not applied correctly."_s
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
    if (!runProcess(u"/sbin/route"_s,
                    {u"-n"_s, u"get"_s, u"default"_s},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }

    static const QRegularExpression gatewayRegex(u"\\bgateway:\\s*([^\\s]+)"_s);
    const QRegularExpressionMatch match = gatewayRegex.match(stdoutText);
    if (!match.hasMatch()) {
        return {};
    }
    return match.captured(1).trimmed();
}

QString macDefaultGateway6()
{
    QString stdoutText;
    QString stderrText;
    if (!runProcess(u"/sbin/route"_s,
                    {u"-n"_s, u"get"_s, u"-inet6"_s, u"default"_s},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }

    static const QRegularExpression gatewayRegex(u"\\bgateway:\\s*([^\\s]+)"_s);
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
    if (!runProcess(u"/sbin/route"_s,
                    {u"-n"_s, u"get"_s, target},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }
    static const QRegularExpression ifRegex(u"\\binterface:\\s*([^\\s]+)"_s);
    const QRegularExpressionMatch match = ifRegex.match(stdoutText);
    if (!match.hasMatch()) {
        return {};
    }
    return match.captured(1).trimmed();
}

QString macRouteInterfaceFor6(const QString& destination)
{
    const QString target = destination.trimmed();
    if (target.isEmpty()) {
        return {};
    }
    QString stdoutText;
    QString stderrText;
    if (!runProcess(u"/sbin/route"_s,
                    {u"-n"_s, u"get"_s, u"-inet6"_s, target},
                    3000,
                    &stdoutText,
                    &stderrText)) {
        Q_UNUSED(stderrText)
        return {};
    }
    static const QRegularExpression ifRegex(u"\\binterface:\\s*([^\\s]+)"_s);
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
        command += u"route -n delete -host %1 >/dev/null 2>&1 || true;"_s.arg(serverIp.trimmed());
    } else if (!serverIp.trimmed().isEmpty() && isIpv6(serverIp)) {
        command += u"route -n delete -inet6 -host %1 >/dev/null 2>&1 || true;"_s.arg(serverIp.trimmed());
    }
    command += QString::fromUtf8("route -n delete -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
        "route -n delete -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
                   .arg(tunIf.trimmed());
    QString ignored;
    return runShell(command, 3000, &ignored);
}

bool applyMacTunRoutes(const QString& tunIf, const QString& serverIp, QString* errorOut)
{
    if (tunIf.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = u"Missing TUN interface name for route setup."_s;
        }
        return false;
    }

    const QString gateway = macDefaultGateway();
    if (gateway.trimmed().isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = u"Unable to detect macOS default gateway for TUN routing."_s;
        }
        return false;
    }

    const QString gateway6 = macDefaultGateway6();

    QString command;
    if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
        // Keep the upstream server reachable outside tunnel to avoid route loops.
        command += QString::fromUtf8("route -n add -host %1 %2 >/dev/null 2>&1 || "
                       "route -n change -host %1 %2 >/dev/null 2>&1 || true;")
                       .arg(serverIp.trimmed(), gateway);
    } else if (!serverIp.trimmed().isEmpty() && isIpv6(serverIp) && !gateway6.trimmed().isEmpty()) {
        // Same bypass route guard for IPv6 endpoints.
        command += QString::fromUtf8("route -n add -inet6 -host %1 %2 >/dev/null 2>&1 || "
                       "route -n change -inet6 -host %1 %2 >/dev/null 2>&1 || true;")
                       .arg(serverIp.trimmed(), gateway6.trimmed());
    }
    command += QString::fromUtf8("route -n add -net 0.0.0.0/1 -iface %1 >/dev/null 2>&1 || true; "
        "route -n add -net 128.0.0.0/1 -iface %1 >/dev/null 2>&1 || true;")
                   .arg(tunIf.trimmed());

    QString routeError;
    if (!runShell(command, 6000, &routeError)) {
        if (errorOut != nullptr) {
            *errorOut = routeError.trimmed().isEmpty()
                ? u"Failed to apply macOS TUN routes."_s
                : routeError.trimmed();
        }
        return false;
    }

    // Validate split routes are really active on the target utun.
    const QString ifA = macRouteInterfaceFor(u"1.1.1.1"_s);
    const QString ifB = macRouteInterfaceFor(u"129.0.0.1"_s);
    if (ifA.compare(tunIf, Qt::CaseInsensitive) != 0
        || ifB.compare(tunIf, Qt::CaseInsensitive) != 0) {
        if (errorOut != nullptr) {
            *errorOut = u"macOS TUN split routes were not applied correctly."_s;
        }
        return false;
    }

    if (!serverIp.trimmed().isEmpty() && isIpv4(serverIp)) {
        const QString serverIface = macRouteInterfaceFor(serverIp.trimmed());
        if (serverIface.compare(tunIf, Qt::CaseInsensitive) == 0) {
            if (errorOut != nullptr) {
                *errorOut = u"VPN server endpoint route is still pointed at TUN."_s;
            }
            return false;
        }
    } else if (!serverIp.trimmed().isEmpty() && isIpv6(serverIp)) {
        const QString serverIface = macRouteInterfaceFor6(serverIp.trimmed());
        if (!serverIface.isEmpty() && serverIface.compare(tunIf, Qt::CaseInsensitive) == 0) {
            if (errorOut != nullptr) {
                *errorOut = u"VPN server endpoint IPv6 route is still pointed at TUN."_s;
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

bool isIpv6(const QString& address)
{
    QHostAddress host(address.trimmed());
    return !host.isNull() && host.protocol() == QAbstractSocket::IPv6Protocol;
}

QString resolveIpForHost(const QString& hostOrIp)
{
    const QString trimmed = hostOrIp.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }
    if (isIpv4(trimmed) || isIpv6(trimmed)) {
        return trimmed;
    }
    const QHostInfo info = QHostInfo::fromName(trimmed);
    QString ipv6Fallback;
    for (const QHostAddress& addr : info.addresses()) {
        if (addr.protocol() == QAbstractSocket::IPv4Protocol) {
            return addr.toString();
        }
        if (ipv6Fallback.isEmpty() && addr.protocol() == QAbstractSocket::IPv6Protocol) {
            ipv6Fallback = addr.toString();
        }
    }
    return ipv6Fallback;
}

bool isProcessAlive(qint64 pid)
{
    if (pid <= 0) {
        return false;
    }
#if defined(Q_OS_WIN)
    HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, static_cast<DWORD>(pid));
    if (process == nullptr) {
        return false;
    }
    const DWORD waitResult = WaitForSingleObject(process, 0);
    CloseHandle(process);
    return waitResult == WAIT_TIMEOUT;
#else
    if (::kill(static_cast<pid_t>(pid), 0) == 0) {
        return true;
    }
    return errno == EPERM;
#endif
}

QJsonObject makeResponse(bool ok, const QString& message = QString())
{
    QJsonObject response;
    response.insert(u"ok"_s, ok);
    if (!message.trimmed().isEmpty()) {
        response.insert(u"message"_s, message.trimmed());
    }
    response.insert(u"time_ms"_s, QDateTime::currentMSecsSinceEpoch());
    response.insert(u"helper_pid"_s, static_cast<qint64>(QCoreApplication::applicationPid()));
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
        connect(&m_idleTimer, &QTimer::timeout, this, [this]() {
            stopTrackedRuntimeBestEffort(u"Helper idle timeout cleanup."_s);
            QCoreApplication::quit();
        });
        m_ownerWatchdogTimer.setInterval(2000);
        connect(&m_ownerWatchdogTimer, &QTimer::timeout, this, [this]() {
            if (m_ownerPid <= 0 || !m_runtimeActive) {
                return;
            }
            if (isProcessAlive(m_ownerPid)) {
                return;
            }
            stopTrackedRuntimeBestEffort(u"Owner process exited unexpectedly."_s);
            QCoreApplication::quit();
        });
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
            return makeResponse(false, u"Invalid JSON request."_s);
        }

        const QJsonObject request = doc.object();
        if (request.value(u"token"_s).toString() != m_token) {
            return makeResponse(false, u"Unauthorized token."_s);
        }

        const QString action = request.value(u"action"_s).toString().trimmed();
        if (action == u"ping"_s) {
            return makeResponse(true, u"pong"_s);
        }
        if (action == u"shutdown"_s) {
            stopTrackedRuntimeBestEffort(u"Helper shutdown request cleanup."_s);
            QTimer::singleShot(0, qApp, &QCoreApplication::quit);
            return makeResponse(true, u"Helper shutting down."_s);
        }
        if (action == u"start_tun"_s) {
            QString error;
            return startTun(request, &error) ? makeResponse(true, u"TUN started."_s)
                                             : makeResponse(false, error);
        }
        if (action == u"stop_tun"_s) {
            QString error;
            return stopTun(request, &error) ? makeResponse(true, u"TUN stopped."_s)
                                            : makeResponse(false, error);
        }

        return makeResponse(false, u"Unsupported action."_s);
    }

    void clearRuntimeTracking()
    {
        m_runtimeActive = false;
        m_runtimePid = -1;
        m_runtimePidPath.clear();
        m_runtimeTunIf.clear();
        m_runtimeServerIp.clear();
        m_ownerPid = 0;
        m_ownerWatchdogTimer.stop();
    }

    void stopTrackedRuntimeBestEffort(const QString& reason)
    {
        Q_UNUSED(reason)
        if (!m_runtimeActive || m_runtimePidPath.trimmed().isEmpty()) {
            clearRuntimeTracking();
            return;
        }

        QString error;
        Q_UNUSED(stopTun(QJsonObject{
            {u"pid_path"_s, m_runtimePidPath},
            {u"tun_if"_s, m_runtimeTunIf},
            {u"server_ip"_s, m_runtimeServerIp}
        }, &error));
        clearRuntimeTracking();
    }

    bool startTun(const QJsonObject& request, QString* errorOut)
    {
        if (m_runtimeActive) {
            stopTrackedRuntimeBestEffort(u"Replacing previous runtime."_s);
        }

        const QString xrayPath = request.value(u"xray_path"_s).toString().trimmed();
        const QString configPath = request.value(u"config_path"_s).toString().trimmed();
        const QString pidPath = request.value(u"pid_path"_s).toString().trimmed();
        const QString logPath = request.value(u"log_path"_s).toString().trimmed();
        const QString tunIf = request.value(u"tun_if"_s).toString().trimmed();
        const QString serverIpRequested = request.value(u"server_ip"_s).toString().trimmed();
        const QString serverHostRequested = request.value(u"server_host"_s).toString().trimmed();
        const qint64 ownerPid = request.value(u"owner_pid"_s).toVariant().toLongLong();

        if (xrayPath.isEmpty() || configPath.isEmpty() || pidPath.isEmpty() || logPath.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = u"Missing required start_tun fields."_s;
            }
            return false;
        }
        if (!QFileInfo::exists(xrayPath)) {
            if (errorOut != nullptr) {
                *errorOut = u"xray executable not found."_s;
            }
            return false;
        }
        if (!QFileInfo::exists(configPath)) {
            if (errorOut != nullptr) {
                *errorOut = u"Runtime config not found."_s;
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
                        u"taskkill"_s,
                        {u"/PID"_s, QString::number(oldPid), u"/T"_s, u"/F"_s},
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
        detachedProcess.setArguments({u"run"_s, u"-config"_s, configPath});
        detachedProcess.setWorkingDirectory(workingDir);
        detachedProcess.setStandardOutputFile(logPath, QIODevice::Append);
        detachedProcess.setStandardErrorFile(logPath, QIODevice::Append);
        const bool started = detachedProcess.startDetached(&pidValue);
        if (!started || pidValue <= 0) {
            if (errorOut != nullptr) {
                *errorOut = u"Failed to start Xray in privileged helper."_s;
            }
            return false;
        }

        QFile pidFileOut(pidPath);
        if (!pidFileOut.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
            if (errorOut != nullptr) {
                *errorOut = u"Failed to write privileged TUN pid file."_s;
            }
            return false;
        }
        pidFileOut.write(QByteArray::number(pidValue));
        pidFileOut.close();
#else
        const QString cmd =
            quoteForSh(xrayPath)
            + u" run -config "_s
            + quoteForSh(configPath)
            + u" >> "_s
            + quoteForSh(logPath)
            + u" 2>&1 & echo $! > "_s
            + quoteForSh(pidPath);
        QString stderrText;
        if (!runShell(cmd, 10000, &stderrText)) {
            if (errorOut != nullptr) {
                *errorOut = stderrText.isEmpty()
                    ? u"Failed to start Xray in privileged helper."_s
                    : stderrText;
            }
            return false;
        }
#endif

#if defined(Q_OS_MACOS)
        if (tunIf.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = u"Missing TUN interface name."_s;
            }
            return false;
        }

        // Wait until xray creates the requested utun interface.
        bool tunReady = false;
        for (int i = 0; i < 80; ++i) {
            QString ifErr;
            if (runShell(u"/sbin/ifconfig %1 >/dev/null 2>&1"_s.arg(tunIf), 1200, &ifErr)) {
                tunReady = true;
                break;
            }
            QThread::msleep(150);
        }
        if (!tunReady) {
            const QString startupLogLine = lastNonEmptyLogLine(logPath);
            const QString cleanupCmd = u"if [ -f %1 ]; then PID=$(cat %1); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %1; fi"_s
                .arg(quoteForSh(pidPath));
            QString ignored;
            runShell(cleanupCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = startupLogLine.isEmpty()
                    ? u"TUN interface was not ready in time (%1)."_s.arg(tunIf)
                    : u"TUN interface was not ready in time (%1): %2"_s.arg(tunIf, startupLogLine);
            }
            return false;
        }

        // Cleanup stale legacy split-routes from older builds (best effort).
        QString cleanupServerIp = resolveIpForHost(serverIpRequested);
        if (cleanupServerIp.isEmpty()) {
            cleanupServerIp = resolveIpForHost(serverHostRequested);
        }
        Q_UNUSED(cleanupMacTunRoutes(tunIf, cleanupServerIp));

        // Route system traffic through TUN and keep server endpoint direct.
        QString routeError;
        if (!applyMacTunRoutes(tunIf, cleanupServerIp, &routeError)) {
            const QString cleanupCmd = u"if [ -f %1 ]; then PID=$(cat %1); [ -n \"$PID\" ] && kill \"$PID\" >/dev/null 2>&1; rm -f %1; fi"_s
                .arg(quoteForSh(pidPath));
            QString ignored;
            runShell(cleanupCmd, 3000, &ignored);
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? u"Failed to apply TUN routes."_s
                    : routeError.trimmed();
            }
            return false;
        }
#elif defined(Q_OS_WIN)
        QString resolvedServerIp = resolveIpForHost(serverIpRequested);
        if (resolvedServerIp.isEmpty()) {
            resolvedServerIp = resolveIpForHost(serverHostRequested);
        }
        const QStringList dnsServers = stringListFromJsonArray(
            request.value(u"dns_servers"_s).toArray());
        QString applyRouteNote;
        WindowsTunAdapterInfo activeTun;
        if (!applyWindowsTunRoutes(resolvedServerIp, dnsServers, &activeTun, &applyRouteNote)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {u"pid_path"_s, pidPath},
                {u"tun_if"_s, QString()},
                {u"server_ip"_s, resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = applyRouteNote.trimmed().isEmpty()
                    ? u"Failed to apply Windows TUN routes."_s
                    : applyRouteNote.trimmed();
            }
            return false;
        } else {
            appendLineToFile(
                logPath,
                u"[System] Windows route setup: %1;ip=%2"_s
                    .arg(applyRouteNote.trimmed(),
                         activeTun.ipv4.trimmed().isEmpty() ? u"unavailable"_s
                                                            : activeTun.ipv4.trimmed()));
        }

        QString routeError;
        if (!validateWindowsTunRouting(resolvedServerIp, activeTun, &routeError)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {u"pid_path"_s, pidPath},
                {u"tun_if"_s, QString()},
                {u"server_ip"_s, resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? u"Failed to validate Windows TUN routes."_s
                    : routeError.trimmed();
            }
            return false;
        } else if (!routeError.trimmed().isEmpty()) {
            appendLineToFile(logPath, u"[System] Windows route probe warning: %1"_s.arg(routeError.trimmed()));
        }
#elif defined(Q_OS_LINUX)
        QString resolvedServerIp = resolveIpForHost(serverIpRequested);
        if (resolvedServerIp.isEmpty()) {
            resolvedServerIp = resolveIpForHost(serverHostRequested);
        }
        QString routeError;
        if (!validateLinuxTunRouting(tunIf, resolvedServerIp, &routeError)) {
            QString cleanupErr;
            Q_UNUSED(stopTun(QJsonObject{
                {u"pid_path"_s, pidPath},
                {u"tun_if"_s, tunIf},
                {u"server_ip"_s, resolvedServerIp}
            }, &cleanupErr));
            if (errorOut != nullptr) {
                *errorOut = routeError.trimmed().isEmpty()
                    ? u"Failed to validate Linux TUN routes."_s
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
                *errorOut = u"TUN start failed: pid file not created."_s;
            }
            return false;
        }
        const QString pidText = QString::fromUtf8(pidFile.readAll()).trimmed();
        if (pidText.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = u"TUN start failed: invalid pid."_s;
            }
            return false;
        }
        bool pidOk = false;
        const qint64 pid = pidText.toLongLong(&pidOk);
        if (!pidOk || pid <= 0) {
            if (errorOut != nullptr) {
                *errorOut = u"TUN start failed: invalid pid."_s;
            }
            return false;
        }

        m_runtimeActive = true;
        m_runtimePid = pid;
        m_runtimePidPath = pidPath;
        m_runtimeTunIf = tunIf;
        m_runtimeServerIp = resolveIpForHost(serverIpRequested);
        if (m_runtimeServerIp.isEmpty()) {
            m_runtimeServerIp = resolveIpForHost(serverHostRequested);
        }
        m_ownerPid = ownerPid;
        if (m_ownerPid > 0) {
            m_ownerWatchdogTimer.start();
        } else {
            m_ownerWatchdogTimer.stop();
        }

        return true;
    }

    bool stopTun(const QJsonObject& request, QString* errorOut)
    {
        const QString pidPath = request.value(u"pid_path"_s).toString().trimmed();
        const QString tunIf = request.value(u"tun_if"_s).toString().trimmed();
        const QString serverIp = request.value(u"server_ip"_s).toString().trimmed();
        if (pidPath.isEmpty()) {
            if (errorOut != nullptr) {
                *errorOut = u"Missing pid path."_s;
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
                        u"taskkill"_s,
                        {u"/PID"_s, QString::number(pidValue), u"/T"_s, u"/F"_s},
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
        const QString cmd = QString::fromUtf8("if [ -f %1 ]; then "
            "PID=$(cat %1); "
            "if [ -n \"$PID\" ]; then kill \"$PID\" >/dev/null 2>&1; sleep 0.2; kill -9 \"$PID\" >/dev/null 2>&1 || true; fi; "
            "rm -f %1; "
            "fi")
            .arg(quoteForSh(pidPath));
        QString stopErr;
        if (!runShell(cmd, 10000, &stopErr)) {
            if (errorOut != nullptr) {
                *errorOut = stopErr.isEmpty()
                    ? u"Failed to stop privileged TUN process."_s
                    : stopErr;
            }
            return false;
        }
#endif

        clearRuntimeTracking();
        return true;
    }

private:
    QTcpServer m_server;
    QString m_token;
    int m_idleTimeoutMs = 600000;
    QTimer m_idleTimer;
    QTimer m_ownerWatchdogTimer;
    QHash<QTcpSocket*, QByteArray> m_buffers;
    bool m_runtimeActive = false;
    qint64 m_runtimePid = -1;
    qint64 m_ownerPid = 0;
    QString m_runtimePidPath;
    QString m_runtimeTunIf;
    QString m_runtimeServerIp;
};

} // namespace

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(u"GenyConnectTunHelper"_s);

    quint16 port = 0;
    QString token;
    int idleTimeoutMs = 15 * 60 * 1000;

    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        const QString arg = args.at(i);
        if (arg == u"--listen-port"_s && i + 1 < args.size()) {
            bool ok = false;
            const int parsed = args.at(i + 1).toInt(&ok);
            if (ok && parsed > 0 && parsed < 65536) {
                port = static_cast<quint16>(parsed);
            }
            ++i;
            continue;
        }
        if (arg == u"--token"_s && i + 1 < args.size()) {
            token = args.at(i + 1).trimmed();
            ++i;
            continue;
        }
        if (arg == u"--idle-timeout-ms"_s && i + 1 < args.size()) {
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

module;
#include <QHostAddress>
#include <QJsonArray>
#include <QStringList>
#include <QSet>
#include <QUrl>
#include <QtGlobal>

module genyconnect.backend.xrayconfigbuilder;

namespace {
QStringList defaultDnsServers()
{
    return {
        QString::fromUtf8("1.1.1.1"),
        QString::fromUtf8("8.8.8.8"),
        QString::fromUtf8("9.9.9.9")
    };
}

QJsonArray toStringArray(const QStringList& values)
{
    QJsonArray out;
    for (const QString& value : values) {
        const QString trimmed = value.trimmed();
        if (!trimmed.isEmpty()) {
            out.append(trimmed);
        }
    }
    return out;
}

QJsonArray toIntArray(const QStringList& values)
{
    QJsonArray out;
    for (const QString& value : values) {
        bool ok = false;
        const int parsed = value.trimmed().toInt(&ok);
        if (!ok) {
            continue;
        }
        out.append(parsed);
    }
    return out;
}

QStringList tunDnsServers(const QStringList& values)
{
    QStringList out;
    for (const QString& value : values) {
        const QString trimmed = value.trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }

        QHostAddress ip;
        if (!ip.setAddress(trimmed)) {
            continue;
        }
        out.append(ip.toString());
    }

    return out.isEmpty() ? defaultDnsServers() : out;
}

int defaultTunMtu()
{
#if defined(Q_OS_WIN)
    // Windows full-tunnel traffic is more sensitive to PMTU blackholes when
    // the outer proxy transport adds overhead. Keep the TUN MTU below 1500 so
    // larger modern sites do not stall on fragmented TLS/HTTP payloads.
    return 1400;
#else
    return 1500;
#endif
}

QJsonObject buildMixedInbound(
    quint16 port,
    bool enableFakeDnsSniffing,
    const QString& listenAddress,
    const QString& tag)
{
    QJsonArray destOverride {
        QString::fromUtf8("http"),
        QString::fromUtf8("tls"),
        QString::fromUtf8("quic")
    };
    if (enableFakeDnsSniffing) {
        destOverride.append(QString::fromUtf8("fakedns"));
    }

    QJsonObject sniffing {
        {QString::fromUtf8("enabled"), true},
        {QString::fromUtf8("destOverride"), destOverride},
        {QString::fromUtf8("routeOnly"), false}
    };

    QJsonObject inbound {
        {QString::fromUtf8("tag"), tag.trimmed().isEmpty() ? QString::fromUtf8("mixed-in") : tag.trimmed()},
        {QString::fromUtf8("listen"), listenAddress.trimmed().isEmpty() ? QString::fromUtf8("127.0.0.1") : listenAddress.trimmed()},
        {QString::fromUtf8("port"), static_cast<int>(port)},
        {QString::fromUtf8("protocol"), QString::fromUtf8("mixed")},
        {QString::fromUtf8("sniffing"), sniffing},
        {QString::fromUtf8("settings"), QJsonObject {
            {QString::fromUtf8("udp"), true},
            {QString::fromUtf8("auth"), QString::fromUtf8("noauth")},
            {QString::fromUtf8("allowTransparent"), false}
        }}
    };

    return inbound;
}

QString normalizedLanMixedListenAddress(const XrayConfigBuilder::BuildOptions& options)
{
    if (!options.lanSharingEnabled) {
        return QString();
    }

    const QString requested = options.lanSharingBindAddress.trimmed();
    if (requested.isEmpty()) {
        return QString();
    }

    QHostAddress parsed;
    if (!parsed.setAddress(requested)) {
        return QString();
    }

    if (parsed.protocol() != QAbstractSocket::IPv4Protocol) {
        return QString();
    }

    if (parsed.isLoopback()) {
        return QString();
    }

    if (requested == QString::fromUtf8("0.0.0.0") && !options.lanSharingAllowAnyBind) {
        return QString();
    }

    return parsed.toString();
}

QJsonObject buildTunInbound(const XrayConfigBuilder::BuildOptions& options)
{
QString tunStack = QString::fromUtf8("system");
#if defined(Q_OS_LINUX) || defined(Q_OS_ANDROID)
    tunStack = QString::fromUtf8("gvisor");
#endif

    QJsonObject settings {
        {QString::fromUtf8("address"), QJsonArray {
            QString::fromUtf8("172.19.0.1/30"),
            QString::fromUtf8("fd00:1234:5678::1/126")
        }},
        {QString::fromUtf8("stack"), tunStack},
        {QString::fromUtf8("autoRoute"), options.tunAutoRoute},
        {QString::fromUtf8("strictRoute"), options.tunStrictRoute},
        {QString::fromUtf8("sniff"), true}
    };
#if defined(Q_OS_ANDROID)
    settings.insert(QString::fromUtf8("mtu"), QJsonArray {defaultTunMtu()});
#else
    settings.insert(QString::fromUtf8("mtu"), defaultTunMtu());
#endif

#if defined(Q_OS_WIN) || defined(Q_OS_MACOS) || (defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID))
    // Keep direct/block outbounds on the physical NIC instead of re-entering
    // TUN. This avoids outbound traffic loops in full-tunnel mode.
    settings.insert(QString::fromUtf8("autoOutboundsInterface"), QString::fromUtf8("auto"));
#endif

#if defined(Q_OS_MACOS)
    // Xray on macOS requires explicit utunN naming.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? QString::fromUtf8("utun9")
        : options.tunInterfaceName.trimmed();
    settings.insert(QString::fromUtf8("name"), tunName);
#elif defined(Q_OS_WIN)
    // Keep a stable adapter name on Windows so route binding and cleanup are deterministic.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? QString::fromUtf8("genyconnect0")
        : options.tunInterfaceName.trimmed();
    settings.insert(QString::fromUtf8("name"), tunName);
    // Mirror Xray's documented Windows TUN options so the adapter gets DNS
    // servers assigned and Xray keeps its own outbound sockets on the
    // physical interface instead of chasing the tunnel.
    settings.insert(QString::fromUtf8("gateway"), QJsonArray {
        QString::fromUtf8("172.19.0.1/30"),
        QString::fromUtf8("fd00:1234:5678::1/126")
    });
    settings.insert(QString::fromUtf8("dns"), toStringArray(tunDnsServers(options.dnsServers)));
#elif defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? QString::fromUtf8("xray0")
        : options.tunInterfaceName.trimmed();
    settings.insert(QString::fromUtf8("name"), tunName);
#endif

    QJsonArray destOverride {
        QString::fromUtf8("http"),
        QString::fromUtf8("tls"),
        QString::fromUtf8("quic")
    };
    if (options.enableFakeDnsSniffing) {
        destOverride.append(QString::fromUtf8("fakedns"));
    }

    QJsonObject sniffing {
        {QString::fromUtf8("enabled"), true},
        {QString::fromUtf8("destOverride"), destOverride},
        {QString::fromUtf8("routeOnly"), false}
    };

    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("tun-in")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("tun")},
        {QString::fromUtf8("settings"), settings},
        {QString::fromUtf8("sniffing"), sniffing}
    };
}

QJsonObject buildApiInbound(quint16 port)
{
    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("api-in")},
        {QString::fromUtf8("listen"), QString::fromUtf8("127.0.0.1")},
        {QString::fromUtf8("port"), static_cast<int>(port)},
        {QString::fromUtf8("protocol"), QString::fromUtf8("dokodemo-door")},
        {QString::fromUtf8("settings"), QJsonObject {
            {QString::fromUtf8("address"), QString::fromUtf8("127.0.0.1")}
        }}
    };
}

QJsonObject buildDnsOutbound()
{
    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("dns-out")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("dns")},
        {QString::fromUtf8("settings"), QJsonObject {}}
    };
}

QJsonObject buildDnsConfig(const XrayConfigBuilder::BuildOptions& options)
{
    QStringList servers = options.dnsServers.isEmpty()
        ? defaultDnsServers()
        : options.dnsServers;
    if (options.enableTun && options.enableFakeDnsSniffing) {
        QSet<QString> seen;
        QStringList normalized;
        normalized.reserve(servers.size() + 1);
        normalized.append(QString::fromUtf8("fakedns"));
        seen.insert(QString::fromUtf8("fakedns"));
        for (const QString& rawServer : std::as_const(servers)) {
            const QString server = rawServer.trimmed();
            if (server.isEmpty()) {
                continue;
            }
            const QString key = server.toLower();
            if (seen.contains(key)) {
                continue;
            }
            seen.insert(key);
            normalized.append(server);
        }
        servers = normalized;
    }
    return QJsonObject {
        {QString::fromUtf8("servers"), toStringArray(servers)},
        {QString::fromUtf8("queryStrategy"), QString::fromUtf8("UseIP")}
    };
}

QStringList normalizeDomainRuleEntries(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }

    const QString lowered = trimmed.toLower();
    if (lowered.startsWith(QString::fromUtf8("domain:"))) {
        const QString suffix = trimmed.mid(7).trimmed();
        if (suffix.isEmpty()) {
            return {};
        }
        return {
            QString::fromUtf8("full:%1").arg(suffix),
            QString::fromUtf8("domain:%1").arg(suffix)
        };
    }

    if (trimmed.contains(':')) {
        return {trimmed};
    }

    return {
        QString::fromUtf8("full:%1").arg(trimmed),
        QString::fromUtf8("domain:%1").arg(trimmed)
    };
}

QJsonArray toDomainArray(const QStringList& values)
{
    QJsonArray out;
    QSet<QString> seen;
    for (const QString& value : values) {
        const QStringList normalizedValues = normalizeDomainRuleEntries(value);
        for (const QString& normalized : normalizedValues) {
            const QString key = normalized.toLower();
            if (normalized.isEmpty() || seen.contains(key)) {
                continue;
            }
            seen.insert(key);
            out.append(normalized);
        }
    }
    return out;
}

QJsonArray toProcessArray(const QStringList& values)
{
    QJsonArray out;
    for (const QString& value : values) {
        const QString trimmed = value.trimmed();
        if (!trimmed.isEmpty()) {
            out.append(trimmed);
        }
    }
    return out;
}

QJsonObject buildRouting(const XrayConfigBuilder::BuildOptions& options)
{
    // Avoid geoip.dat dependency by using explicit private/link-local CIDRs.
    const QJsonArray privateCidrs {
        QString::fromUtf8("10.0.0.0/8"),
        QString::fromUtf8("100.64.0.0/10"),
        QString::fromUtf8("127.0.0.0/8"),
        QString::fromUtf8("169.254.0.0/16"),
        QString::fromUtf8("172.16.0.0/12"),
        QString::fromUtf8("192.168.0.0/16"),
        QString::fromUtf8("::1/128"),
        QString::fromUtf8("fc00::/7"),
        QString::fromUtf8("fe80::/10")
    };

    QJsonArray rules;
    if (options.enableStatsApi) {
        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("api-in")}},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("api")}
        });
    }

    if (options.enableTun) {
        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("tcp,udp")},
            {QString::fromUtf8("port"), QString::fromUtf8("53")},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("dns-out")}
        });

        // Prevent local discovery/broadcast storms from looping in TUN mode
        // (notably NetBIOS/mDNS/LLMNR/link-local chatter on Windows/macOS).
        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("udp")},
            {QString::fromUtf8("port"), QString::fromUtf8("137,138,5353,5355")},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("block")}
        });
        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("tun-in")}},
            {QString::fromUtf8("network"), QString::fromUtf8("udp")},
            {QString::fromUtf8("ip"), QJsonArray {
                QString::fromUtf8("169.254.0.0/16"),
                QString::fromUtf8("255.255.255.255/32"),
                QString::fromUtf8("224.0.0.0/4")
            }},
            {QString::fromUtf8("outboundTag"), QString::fromUtf8("block")}
        });
    }

    QJsonObject privateDirectRule {
        {QString::fromUtf8("type"), QString::fromUtf8("field")},
        {QString::fromUtf8("outboundTag"), QString::fromUtf8("direct")},
        {QString::fromUtf8("ip"), privateCidrs}
    };
    if (options.enableTun) {
        QJsonArray tunPrivateInboundTags {QString::fromUtf8("mixed-in")};
        if (options.lanSharingEnabled) {
            tunPrivateInboundTags.append(QString::fromUtf8("mixed-lan-in"));
        }
        // In TUN mode, keep RFC1918/link-local direct bypass only for local mixed
        // inbound traffic. Applying this rule to tun-in can create direct loops.
        privateDirectRule.insert(QString::fromUtf8("inboundTag"), tunPrivateInboundTags);
    }
    rules.append(privateDirectRule);

    QJsonObject localhostDirectRule {
        {QString::fromUtf8("type"), QString::fromUtf8("field")},
        {QString::fromUtf8("outboundTag"), QString::fromUtf8("direct")},
        {QString::fromUtf8("domain"), QJsonArray {
            QString::fromUtf8("full:localhost"),
            QString::fromUtf8("domain:local"),
            QString::fromUtf8("regexp:.*\\.local\\.?$")
        }}
    };
    if (options.enableTun) {
        QJsonArray tunLocalhostInboundTags {QString::fromUtf8("mixed-in")};
        if (options.lanSharingEnabled) {
            tunLocalhostInboundTags.append(QString::fromUtf8("mixed-lan-in"));
        }
        localhostDirectRule.insert(QString::fromUtf8("inboundTag"), tunLocalhostInboundTags);
    }
    rules.append(localhostDirectRule);

    auto appendDomainRule = [&rules](const QStringList& entries, const QString& outboundTag) {
        const QJsonArray domains = toDomainArray(entries);
        if (domains.isEmpty()) {
            return;
        }

        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("outboundTag"), outboundTag},
            {QString::fromUtf8("domain"), domains}
        });
    };

    auto appendProcessRule = [&rules,& options](const QStringList& entries, const QString& outboundTag) {
        if (!options.enableProcessRouting) {
            return;
        }

        const QJsonArray processes = toProcessArray(entries);
        if (processes.isEmpty()) {
            return;
        }

        rules.append(QJsonObject {
            {QString::fromUtf8("type"), QString::fromUtf8("field")},
            {QString::fromUtf8("outboundTag"), outboundTag},
            {QString::fromUtf8("process"), processes}
        });
    };

    appendDomainRule(options.blockDomains, QString::fromUtf8("block"));
    appendProcessRule(options.blockProcesses, QString::fromUtf8("block"));
    appendDomainRule(options.directDomains, QString::fromUtf8("direct"));
    appendProcessRule(options.directProcesses, QString::fromUtf8("direct"));
    appendDomainRule(options.proxyDomains, QString::fromUtf8("proxy"));
    appendProcessRule(options.proxyProcesses, QString::fromUtf8("proxy"));

    // In TUN mode we expect full-tunnel behavior by default; only explicit
    // direct/block rules should bypass proxy.
    const QString defaultOutbound = options.enableTun
        ? QString::fromUtf8("proxy")
        : (options.whitelistMode ? QString::fromUtf8("direct") : QString::fromUtf8("proxy"));
    rules.append(QJsonObject {
        {QString::fromUtf8("type"), QString::fromUtf8("field")},
        {QString::fromUtf8("outboundTag"), defaultOutbound},
        {QString::fromUtf8("network"), QString::fromUtf8("tcp,udp")}
    });

    return QJsonObject {
        // Resolve destination IP only when domain match did not hit. This keeps
        // domain rules authoritative while improving fallback behavior.
        {QString::fromUtf8("domainStrategy"), QString::fromUtf8("IPIfNonMatch")},
        // Prefer deterministic linear matching to avoid MPH/hybrid edge cases
        // with small dynamic rule sets generated at runtime.
        {QString::fromUtf8("domainMatcher"), QString::fromUtf8("linear")},
        {QString::fromUtf8("rules"), rules}
    };
}

QJsonObject buildPolicy()
{
    return QJsonObject {
        {QString::fromUtf8("system"), QJsonObject {
            {QString::fromUtf8("statsInboundDownlink"), true},
            {QString::fromUtf8("statsInboundUplink"), true},
            {QString::fromUtf8("statsOutboundDownlink"), true},
            {QString::fromUtf8("statsOutboundUplink"), true}
        }}
    };
}

QJsonObject buildDirectOutbound()
{
    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("direct")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("freedom")},
        {QString::fromUtf8("settings"), QJsonObject {}}
    };
}

QJsonObject buildBlockOutbound()
{
    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("block")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("blackhole")},
        {QString::fromUtf8("settings"), QJsonObject {}}
    };
}

QJsonObject buildFragProxyOutbound()
{
    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("frag-proxy")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("freedom")},
        {QString::fromUtf8("settings"), QJsonObject {
            {QString::fromUtf8("fragment"), QJsonObject {
                {QString::fromUtf8("packets"), QString::fromUtf8("tlshello")},
                {QString::fromUtf8("length"), QString::fromUtf8("100-200")},
                {QString::fromUtf8("interval"), QString::fromUtf8("10-20")}
            }}
        }}
    };
}

QString normalizeTransportPath(const QString& path)
{
    QString normalized = path.trimmed();
    for (int i = 0; i < 3 && normalized.contains('%'); ++i) {
        const QString decoded = QUrl::fromPercentEncoding(normalized.toUtf8());
        if (decoded == normalized) {
            break;
        }
        normalized = decoded.trimmed();
    }

    if (normalized.isEmpty()) {
        return QString::fromUtf8("/");
    }
    while (normalized.startsWith(QString::fromUtf8("//"))) {
        normalized.remove(0, 1);
    }
    if (normalized.startsWith('/')) {
        return normalized;
    }
    return QString::fromUtf8("/") + normalized;
}

QString endpointHostWithPort(const QString& host, quint16 port)
{
    const QString trimmed = host.trimmed();
    if (trimmed.contains(':') && !trimmed.startsWith('[') && !trimmed.endsWith(']')) {
        return QString::fromUtf8("[%1]:%2").arg(trimmed, QString::number(port));
    }
    return QString::fromUtf8("%1:%2").arg(trimmed, QString::number(port));
}

bool alpnTokenExists(const QStringList& tokens, const QString& needle)
{
    for (const QString& token : tokens) {
        if (token.compare(needle, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

QString normalizeXhttpMode(const QString& rawMode)
{
    const QString mode = rawMode.trimmed().toLower();
    if (mode.isEmpty()) {
        return QString();
    }

    if (mode == QString::fromUtf8("auto")
        || mode == QString::fromUtf8("stream-one")
        || mode == QString::fromUtf8("stream-up")
        || mode == QString::fromUtf8("packet-up")) {
        return mode;
    }

    if (mode == QString::fromUtf8("streamone")) {
        return QString::fromUtf8("stream-one");
    }
    if (mode == QString::fromUtf8("streamup")) {
        return QString::fromUtf8("stream-up");
    }
    if (mode == QString::fromUtf8("packetup")) {
        return QString::fromUtf8("packet-up");
    }

    return QString();
}

QString effectiveXhttpMode(const ServerProfile& profile)
{
    QString mode = normalizeXhttpMode(profile.xhttpMode);
    if (mode.isEmpty()) {
        mode = QString::fromUtf8("auto");
    }

    if (mode == QString::fromUtf8("auto")
        && profile.security.compare(QString::fromUtf8("tls"), Qt::CaseInsensitive) == 0) {
        const QStringList alpnParts = profile.alpn.split(',', Qt::SkipEmptyParts);
        if (alpnTokenExists(alpnParts, QString::fromUtf8("h3"))
            && profile.xhttpExtra.isEmpty()) {
            // Several CDN-backed links advertising "h3,h2" become unstable in
            // packet-up/stream-up auto selection (observed uplink-only traffic).
            // We force stream-one even for h3-only links to keep bidirectional
            // transport compatibility.
            // Prefer stream-one for safer bidirectional behavior.
            mode = QString::fromUtf8("stream-one");
        }
    }

    return mode;
}

QJsonObject buildTlsPeerSettings(const ServerProfile& profile)
{
    QJsonObject tlsSettings;
    QString tlsServerName = profile.sni.trimmed();
    if (tlsServerName.isEmpty()) {
        const QString hostHeader = profile.hostHeader.trimmed();
        if (!hostHeader.isEmpty()) {
            const int commaIndex = hostHeader.indexOf(',');
            tlsServerName = (commaIndex > 0 ? hostHeader.left(commaIndex) : hostHeader).trimmed();
        }
    }
    if (!tlsServerName.isEmpty()) {
        tlsSettings[QString::fromUtf8("serverName")] = tlsServerName;
    }
    if (!profile.alpn.isEmpty()) {
        const QStringList alpnParts = profile.alpn.split(',', Qt::SkipEmptyParts);
        QStringList normalizedAlpn;
        normalizedAlpn.reserve(alpnParts.size());
        for (const QString& part : alpnParts) {
            QString token = part.trimmed();
            if (!token.isEmpty()) {
                if (token.compare(QString::fromUtf8("h2"), Qt::CaseInsensitive) == 0) {
                    token = QString::fromUtf8("h2");
                } else if (token.compare(QString::fromUtf8("h3"), Qt::CaseInsensitive) == 0) {
                    token = QString::fromUtf8("h3");
                } else if (token.compare(QString::fromUtf8("http/1.1"), Qt::CaseInsensitive) == 0) {
                    token = QString::fromUtf8("http/1.1");
                }
                normalizedAlpn.append(token);
            }
        }

        if (profile.network == QString::fromUtf8("xhttp")
            && effectiveXhttpMode(profile) == QString::fromUtf8("stream-one")) {
            // stream-one works best with H2/H1.1; drop explicit H3 to avoid
            // uplink-only behavior on some links.
            normalizedAlpn.removeAll(QString::fromUtf8("h3"));
        }

        QJsonArray alpnValues;
        for (const QString& token : normalizedAlpn) {
            alpnValues.append(token);
        }
        if (!alpnValues.isEmpty()) {
            tlsSettings[QString::fromUtf8("alpn")] = alpnValues;
        }
    }
    if (!profile.fingerprint.isEmpty()) {
        tlsSettings[QString::fromUtf8("fingerprint")] = profile.fingerprint;
    }
    if (!profile.pinnedPeerCertSha256.isEmpty()) {
        tlsSettings[QString::fromUtf8("pinnedPeerCertSha256")] = toStringArray(profile.pinnedPeerCertSha256);
    }
    return tlsSettings;
}
}

QJsonObject XrayConfigBuilder::build(const ServerProfile& profile, const BuildOptions& options)
{
    QJsonArray inbounds;
    inbounds.append(buildMixedInbound(
        options.socksPort,
        options.enableFakeDnsSniffing,
        QString::fromUtf8("127.0.0.1"),
        QString::fromUtf8("mixed-in")));
    const QString lanListen = normalizedLanMixedListenAddress(options);
    if (!lanListen.isEmpty()) {
        inbounds.append(buildMixedInbound(
            options.socksPort,
            options.enableFakeDnsSniffing,
            lanListen,
            QString::fromUtf8("mixed-lan-in")));
    }
    if (options.enableTun) {
        inbounds.append(buildTunInbound(options));
    }
    if (options.enableStatsApi) {
        inbounds.append(buildApiInbound(options.apiPort));
    }

    QJsonArray outbounds;
    // Keep Reality fragmentation path enabled in both proxy and TUN modes.
    // Some censored networks require this for stable outbound reachability.
    const bool enableRealityFragDialer =
        (profile.security == QString::fromUtf8("reality"));
    outbounds.append(buildMainOutbound(profile, options.enableMux, enableRealityFragDialer));
    if (options.enableTun) {
        outbounds.append(buildDnsOutbound());
    }
    outbounds.append(buildDirectOutbound());
    outbounds.append(buildBlockOutbound());
    if (enableRealityFragDialer) {
        outbounds.append(buildFragProxyOutbound());
    }

    QJsonObject config {
        {QString::fromUtf8("log"), QJsonObject {
            {QString::fromUtf8("loglevel"), options.logLevel}
        }},
        {QString::fromUtf8("inbounds"), inbounds},
        {QString::fromUtf8("outbounds"), outbounds},
        {QString::fromUtf8("routing"), buildRouting(options)},
        {QString::fromUtf8("policy"), buildPolicy()},
        {QString::fromUtf8("stats"), QJsonObject {}}
    };

    if (options.enableStatsApi) {
        config[QString::fromUtf8("api")] = QJsonObject {
            {QString::fromUtf8("tag"), QString::fromUtf8("api")},
            {QString::fromUtf8("services"), QJsonArray {QString::fromUtf8("StatsService")}}
        };
    }
    if (options.enableTun) {
        config[QString::fromUtf8("dns")] = buildDnsConfig(options);
        if (options.enableFakeDnsSniffing) {
            config[QString::fromUtf8("fakedns")] = QJsonArray {
                QJsonObject {
                    {QString::fromUtf8("ipPool"), QString::fromUtf8("198.18.0.0/15")},
                    {QString::fromUtf8("poolSize"), 65535}
                }
            };
        }
    }

    return config;
}

QJsonObject XrayConfigBuilder::buildMainOutbound(
    const ServerProfile& profile,
    bool enableMux,
    bool enableRealityFragDialer)
{
    if (profile.protocol == QString::fromUtf8("wireguard")) {
        const QStringList allowedIps = profile.wgAllowedIPs.isEmpty()
            ? QStringList {QString::fromUtf8("0.0.0.0/0"), QString::fromUtf8("::/0")}
            : profile.wgAllowedIPs;
        QJsonObject peer {
            {QString::fromUtf8("endpoint"), endpointHostWithPort(profile.address, profile.port)},
            {QString::fromUtf8("publicKey"), profile.wgPublicKey},
            {QString::fromUtf8("allowedIPs"), toStringArray(allowedIps)}
        };
        if (!profile.wgPresharedKey.trimmed().isEmpty()) {
            peer.insert(QString::fromUtf8("preSharedKey"), profile.wgPresharedKey.trimmed());
        }
        if (profile.wgPersistentKeepalive > 0) {
            peer.insert(QString::fromUtf8("keepAlive"), profile.wgPersistentKeepalive);
        }

        QJsonObject settings {
            {QString::fromUtf8("secretKey"), profile.wgSecretKey},
            {QString::fromUtf8("peers"), QJsonArray {peer}},
            {QString::fromUtf8("noKernelTun"), true},
            {QString::fromUtf8("domainStrategy"), QString::fromUtf8("ForceIP")}
        };

        if (!profile.wgAddress.isEmpty()) {
            settings.insert(QString::fromUtf8("address"), toStringArray(profile.wgAddress));
        }
        if (profile.wgMtu > 0) {
            settings.insert(QString::fromUtf8("mtu"), profile.wgMtu);
        }
        const QJsonArray reserved = toIntArray(profile.wgReserved);
        if (!reserved.isEmpty()) {
            settings.insert(QString::fromUtf8("reserved"), reserved);
        }

        return QJsonObject {
            {QString::fromUtf8("tag"), QString::fromUtf8("proxy")},
            {QString::fromUtf8("protocol"), QString::fromUtf8("wireguard")},
            {QString::fromUtf8("settings"), settings}
        };
    }

    if (profile.protocol == QString::fromUtf8("trojan")) {
        QJsonObject server {
            {QString::fromUtf8("address"), profile.address},
            {QString::fromUtf8("port"), static_cast<int>(profile.port)},
            {QString::fromUtf8("password"), profile.userId}
        };
        if (!profile.flow.trimmed().isEmpty()) {
            server.insert(QString::fromUtf8("flow"), profile.flow.trimmed());
        }

        QJsonObject outbound {
            {QString::fromUtf8("tag"), QString::fromUtf8("proxy")},
            {QString::fromUtf8("protocol"), QString::fromUtf8("trojan")},
            {QString::fromUtf8("settings"), QJsonObject {
                {QString::fromUtf8("servers"), QJsonArray {server}}
            }},
            {QString::fromUtf8("streamSettings"), buildStreamSettings(profile)}
        };

        if (enableMux) {
            outbound[QString::fromUtf8("mux")] = QJsonObject {
                {QString::fromUtf8("enabled"), true},
                {QString::fromUtf8("concurrency"), 8}
            };
        }

        return outbound;
    }

    if (profile.protocol == QString::fromUtf8("shadowsocks")) {
        QJsonObject server {
            {QString::fromUtf8("address"), profile.address},
            {QString::fromUtf8("port"), static_cast<int>(profile.port)},
            {QString::fromUtf8("method"), profile.encryption.trimmed().isEmpty()
                                              ? QString::fromUtf8("aes-128-gcm")
                                              : profile.encryption.trimmed()},
            {QString::fromUtf8("password"), profile.userId},
            {QString::fromUtf8("uot"), true}
        };

        QJsonObject outbound {
            {QString::fromUtf8("tag"), QString::fromUtf8("proxy")},
            {QString::fromUtf8("protocol"), QString::fromUtf8("shadowsocks")},
            {QString::fromUtf8("settings"), QJsonObject {
                {QString::fromUtf8("servers"), QJsonArray {server}}
            }}
        };

        if (profile.network != QString::fromUtf8("tcp")
            || profile.security != QString::fromUtf8("none")
            || !profile.hostHeader.trimmed().isEmpty()
            || !profile.path.trimmed().isEmpty()) {
            outbound.insert(QString::fromUtf8("streamSettings"), buildStreamSettings(profile));
        }

        if (enableMux) {
            outbound[QString::fromUtf8("mux")] = QJsonObject {
                {QString::fromUtf8("enabled"), true},
                {QString::fromUtf8("concurrency"), 8}
            };
        }

        return outbound;
    }

    QJsonObject user {
        {QString::fromUtf8("id"), profile.userId},
    };

    if (profile.protocol == QString::fromUtf8("vless")) {
        user[QString::fromUtf8("encryption")] = profile.encryption.isEmpty()
            ? QString::fromUtf8("none")
            : profile.encryption;
        if (!profile.flow.isEmpty()) {
            user[QString::fromUtf8("flow")] = profile.flow;
        }
    }

    if (profile.protocol == QString::fromUtf8("vmess")) {
        user[QString::fromUtf8("security")] = profile.encryption.isEmpty()
            ? QString::fromUtf8("auto")
            : profile.encryption;
        user[QString::fromUtf8("alterId")] = 0;
    }

    QJsonObject outbound {
        {QString::fromUtf8("tag"), QString::fromUtf8("proxy")},
        {QString::fromUtf8("protocol"), profile.protocol},
        {QString::fromUtf8("settings"), QJsonObject {
            {QString::fromUtf8("vnext"), QJsonArray {
                QJsonObject {
                    {QString::fromUtf8("address"), profile.address},
                    {QString::fromUtf8("port"), static_cast<int>(profile.port)},
                    {QString::fromUtf8("users"), QJsonArray {user}}
                }
            }}
        }},
        {QString::fromUtf8("streamSettings"), buildStreamSettings(profile)}
    };

    if (enableRealityFragDialer) {
        QJsonObject streamSettings = outbound.value(QString::fromUtf8("streamSettings")).toObject();
        streamSettings[QString::fromUtf8("sockopt")] = QJsonObject {
            {QString::fromUtf8("dialerProxy"), QString::fromUtf8("frag-proxy")}
        };
        outbound[QString::fromUtf8("streamSettings")] = streamSettings;
    }

    if (enableMux) {
        outbound[QString::fromUtf8("mux")] = QJsonObject {
            {QString::fromUtf8("enabled"), true},
            {QString::fromUtf8("concurrency"), 8}
        };
    }

    return outbound;
}

QJsonObject XrayConfigBuilder::buildStreamSettings(const ServerProfile& profile)
{
    QJsonObject stream {
        {QString::fromUtf8("network"), profile.network.isEmpty() ? QString::fromUtf8("tcp") : profile.network}
    };

    if (profile.network == QString::fromUtf8("ws")) {
        QJsonObject wsSettings;
        wsSettings[QString::fromUtf8("path")] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            wsSettings[QString::fromUtf8("headers")] = QJsonObject {
                {QString::fromUtf8("Host"), profile.hostHeader}
            };
        }

        stream[QString::fromUtf8("wsSettings")] = wsSettings;
    }

    if (profile.network == QString::fromUtf8("grpc")) {
        stream[QString::fromUtf8("grpcSettings")] = QJsonObject {
            {QString::fromUtf8("serviceName"), profile.serviceName}
        };
    }

    if (profile.network == QString::fromUtf8("xhttp")) {
        QJsonObject xhttpSettings;
        xhttpSettings[QString::fromUtf8("path")] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            xhttpSettings[QString::fromUtf8("host")] = profile.hostHeader;
        }
        const QString normalizedMode = effectiveXhttpMode(profile);
        if (!normalizedMode.isEmpty()) {
            // Preserve imported mode hints exactly (including "auto").
            xhttpSettings[QString::fromUtf8("mode")] = normalizedMode;
        }
        if (!profile.xhttpExtra.isEmpty()) {
            xhttpSettings[QString::fromUtf8("extra")] = profile.xhttpExtra;
        }

        stream[QString::fromUtf8("xhttpSettings")] = xhttpSettings;
        // Some cores still consume split-http key names. Keep both for
        // cross-version compatibility.
        stream[QString::fromUtf8("splithttpSettings")] = xhttpSettings;
    }

    if (profile.network == QString::fromUtf8("tcp")) {
        const QString headerType = profile.headerType.isEmpty()
            ? QString::fromUtf8("none")
            : profile.headerType;
        stream[QString::fromUtf8("tcpSettings")] = QJsonObject {
            {QString::fromUtf8("header"), QJsonObject {
                {QString::fromUtf8("type"), headerType}
            }}
        };
    }

    const QString security = profile.security.isEmpty()
        ? QString::fromUtf8("none")
        : profile.security;
    stream[QString::fromUtf8("security")] = security;

    if (security == QString::fromUtf8("tls")) {
        stream[QString::fromUtf8("tlsSettings")] = buildTlsPeerSettings(profile);
    }

    if (security == QString::fromUtf8("reality")) {
        QJsonObject realitySettings;

        if (!profile.sni.isEmpty()) {
            realitySettings[QString::fromUtf8("serverName")] = profile.sni;
        }
        if (!profile.fingerprint.isEmpty()) {
            realitySettings[QString::fromUtf8("fingerprint")] = profile.fingerprint;
        }
        if (!profile.publicKey.isEmpty()) {
            realitySettings[QString::fromUtf8("publicKey")] = profile.publicKey;
        }
        if (!profile.shortId.isEmpty()) {
            realitySettings[QString::fromUtf8("shortId")] = profile.shortId;
        }
        realitySettings[QString::fromUtf8("spiderX")] = profile.spiderX.isEmpty()
            ? QString::fromUtf8("/")
            : profile.spiderX;

        stream[QString::fromUtf8("realitySettings")] = realitySettings;
    }

    return stream;
}

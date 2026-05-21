module;
#include <QHostAddress>
#include <QJsonArray>
#include <QStringList>
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

QJsonObject buildMixedInbound(quint16 port, bool enableFakeDnsSniffing)
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
        {QString::fromUtf8("tag"), QString::fromUtf8("mixed-in")},
        {QString::fromUtf8("listen"), QString::fromUtf8("127.0.0.1")},
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
        {QString::fromUtf8("mtu"), defaultTunMtu()},
        {QString::fromUtf8("stack"), tunStack},
        {QString::fromUtf8("autoRoute"), options.tunAutoRoute},
        {QString::fromUtf8("strictRoute"), options.tunStrictRoute},
        {QString::fromUtf8("sniff"), true}
    };

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
    settings.insert(QString::fromUtf8("autoOutboundsInterface"), QString::fromUtf8("auto"));
#endif

    return QJsonObject {
        {QString::fromUtf8("tag"), QString::fromUtf8("tun-in")},
        {QString::fromUtf8("protocol"), QString::fromUtf8("tun")},
        {QString::fromUtf8("settings"), settings}
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
    const QStringList servers = options.dnsServers.isEmpty()
        ? defaultDnsServers()
        : options.dnsServers;
    return QJsonObject {
        {QString::fromUtf8("servers"), toStringArray(servers)},
        {QString::fromUtf8("queryStrategy"), QString::fromUtf8("UseIP")}
    };
}

QString normalizeDomainRuleEntry(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty()) {
        return {};
    }

    if (trimmed.contains(':')) {
        return trimmed;
    }

    return QString::fromUtf8("domain:%1").arg(trimmed);
}

QJsonArray toDomainArray(const QStringList& values)
{
    QJsonArray out;
    for (const QString& value : values) {
        const QString normalized = normalizeDomainRuleEntry(value);
        if (!normalized.isEmpty()) {
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
        // In TUN mode, keep RFC1918/link-local direct bypass only for local mixed
        // inbound traffic. Applying this rule to tun-in can create direct loops.
        privateDirectRule.insert(QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("mixed-in")});
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
        localhostDirectRule.insert(QString::fromUtf8("inboundTag"), QJsonArray {QString::fromUtf8("mixed-in")});
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
        {QString::fromUtf8("domainStrategy"), QString::fromUtf8("AsIs")},
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

QJsonObject buildTlsPeerSettings(const ServerProfile& profile)
{
    QJsonObject tlsSettings;
    if (!profile.sni.isEmpty()) {
        tlsSettings[QString::fromUtf8("serverName")] = profile.sni;
    }
    if (!profile.alpn.isEmpty()) {
        const QStringList alpnParts = profile.alpn.split(',', Qt::SkipEmptyParts);
        QJsonArray alpnValues;
        for (const QString& part : alpnParts) {
            alpnValues.append(part.trimmed());
        }
        if (!alpnValues.isEmpty()) {
            tlsSettings[QString::fromUtf8("alpn")] = alpnValues;
        }
    }
    if (!profile.fingerprint.isEmpty()) {
        tlsSettings[QString::fromUtf8("fingerprint")] = profile.fingerprint;
    }
    tlsSettings[QString::fromUtf8("allowInsecure")] = profile.allowInsecure;
    return tlsSettings;
}
}

QJsonObject XrayConfigBuilder::build(const ServerProfile& profile, const BuildOptions& options)
{
    QJsonArray inbounds;
    inbounds.append(buildMixedInbound(options.socksPort, options.enableFakeDnsSniffing));
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
    }

    return config;
}

QJsonObject XrayConfigBuilder::buildMainOutbound(
    const ServerProfile& profile,
    bool enableMux,
    bool enableRealityFragDialer)
{
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
        xhttpSettings[QString::fromUtf8("mode")] = profile.xhttpMode.isEmpty()
            ? QString::fromUtf8("auto")
            : profile.xhttpMode;
        if (!profile.xhttpExtra.isEmpty()) {
            xhttpSettings[QString::fromUtf8("extra")] = profile.xhttpExtra;
        }

        stream[QString::fromUtf8("xhttpSettings")] = xhttpSettings;
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

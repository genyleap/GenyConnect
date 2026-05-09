module;
#include <QHostAddress>
#include <QFileInfo>
#include <QJsonArray>
#include <QSet>
#include <QStringList>
#include <QUrl>
#include <QtGlobal>

module genyconnect.backend.xrayconfigbuilder;

namespace {
QStringList defaultDnsServers()
{
    return {
        QStringLiteral("1.1.1.1"),
        QStringLiteral("8.8.8.8"),
        QStringLiteral("9.9.9.9")
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

QJsonObject buildMixedInbound(quint16 port)
{
    QJsonObject sniffing {
        {QStringLiteral("enabled"), true},
        {QStringLiteral("destOverride"), QJsonArray {QStringLiteral("http"), QStringLiteral("tls"), QStringLiteral("quic"), QStringLiteral("fakedns")}},
        {QStringLiteral("routeOnly"), false}
    };

    QJsonObject inbound {
        {QStringLiteral("tag"), QStringLiteral("mixed-in")},
        {QStringLiteral("listen"), QStringLiteral("127.0.0.1")},
        {QStringLiteral("port"), static_cast<int>(port)},
        {QStringLiteral("protocol"), QStringLiteral("mixed")},
        {QStringLiteral("sniffing"), sniffing},
        {QStringLiteral("settings"), QJsonObject {
            {QStringLiteral("udp"), true},
            {QStringLiteral("auth"), QStringLiteral("noauth")},
            {QStringLiteral("allowTransparent"), false}
        }}
    };

    return inbound;
}

QJsonObject buildTunInbound(const XrayConfigBuilder::BuildOptions& options)
{
    QString tunStack = QStringLiteral("system");
#if defined(Q_OS_LINUX)
    tunStack = QStringLiteral("gvisor");
#endif

    QJsonObject settings {
        {QStringLiteral("address"), QJsonArray {
            QStringLiteral("172.19.0.1/30"),
            QStringLiteral("fd00:1234:5678::1/126")
        }},
        {QStringLiteral("mtu"), defaultTunMtu()},
        {QStringLiteral("stack"), tunStack},
        {QStringLiteral("autoRoute"), options.tunAutoRoute},
        {QStringLiteral("strictRoute"), options.tunStrictRoute},
        {QStringLiteral("sniff"), true}
    };

#if defined(Q_OS_MACOS)
    // Xray on macOS requires explicit utunN naming.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? QStringLiteral("utun9")
        : options.tunInterfaceName.trimmed();
    settings.insert(QStringLiteral("name"), tunName);
#elif defined(Q_OS_WIN)
    // Keep a stable adapter name on Windows so route binding and cleanup are deterministic.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? QStringLiteral("genyconnect0")
        : options.tunInterfaceName.trimmed();
    settings.insert(QStringLiteral("name"), tunName);
    // Mirror Xray's documented Windows TUN options so the adapter gets DNS
    // servers assigned and Xray keeps its own outbound sockets on the
    // physical interface instead of chasing the tunnel.
    settings.insert(QStringLiteral("gateway"), QJsonArray {
        QStringLiteral("172.19.0.1/30"),
        QStringLiteral("fd00:1234:5678::1/126")
    });
    settings.insert(QStringLiteral("dns"), toStringArray(tunDnsServers(options.dnsServers)));
    settings.insert(QStringLiteral("autoOutboundsInterface"), QStringLiteral("auto"));
#endif

    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("tun-in")},
        {QStringLiteral("protocol"), QStringLiteral("tun")},
        {QStringLiteral("settings"), settings}
    };
}

QJsonObject buildApiInbound(quint16 port)
{
    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("api-in")},
        {QStringLiteral("listen"), QStringLiteral("127.0.0.1")},
        {QStringLiteral("port"), static_cast<int>(port)},
        {QStringLiteral("protocol"), QStringLiteral("dokodemo-door")},
        {QStringLiteral("settings"), QJsonObject {
            {QStringLiteral("address"), QStringLiteral("127.0.0.1")}
        }}
    };
}

QJsonObject buildDnsOutbound()
{
    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("dns-out")},
        {QStringLiteral("protocol"), QStringLiteral("dns")},
        {QStringLiteral("settings"), QJsonObject {}}
    };
}

QJsonObject buildDnsConfig(const XrayConfigBuilder::BuildOptions& options)
{
    const QStringList servers = options.dnsServers.isEmpty()
        ? defaultDnsServers()
        : options.dnsServers;
    return QJsonObject {
        {QStringLiteral("servers"), toStringArray(servers)},
        {QStringLiteral("queryStrategy"), QStringLiteral("UseIP")}
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

    return QStringLiteral("domain:%1").arg(trimmed);
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
    QSet<QString> seen;
    auto appendUnique = [&out, &seen](const QString& candidate) {
        const QString trimmed = candidate.trimmed();
        if (trimmed.isEmpty()) {
            return;
        }
        const QString key = trimmed.toLower();
        if (seen.contains(key)) {
            return;
        }
        seen.insert(key);
        out.append(trimmed);
    };

    for (const QString& value : values) {
        const QString trimmed = value.trimmed();
        if (!trimmed.isEmpty()) {
            appendUnique(trimmed);
            const QFileInfo info(trimmed);
            const QString fileName = info.fileName().trimmed();
            if (!fileName.isEmpty() && fileName != trimmed) {
                appendUnique(fileName);
            }

            const QString baseName = info.completeBaseName().trimmed();
            if (!baseName.isEmpty()) {
                appendUnique(baseName);
            }

#if defined(Q_OS_WIN)
            if (!fileName.endsWith(QStringLiteral(".exe"), Qt::CaseInsensitive)
                && !baseName.isEmpty()) {
                appendUnique(baseName + QStringLiteral(".exe"));
            }
#else
            if (fileName.endsWith(QStringLiteral(".exe"), Qt::CaseInsensitive)) {
                appendUnique(fileName.left(fileName.size() - 4));
            }
#endif
        }
    }
    return out;
}

QJsonObject buildRouting(const XrayConfigBuilder::BuildOptions& options)
{
    // Avoid geoip.dat dependency by using explicit private/link-local CIDRs.
    const QJsonArray privateCidrs {
        QStringLiteral("10.0.0.0/8"),
        QStringLiteral("100.64.0.0/10"),
        QStringLiteral("127.0.0.0/8"),
        QStringLiteral("169.254.0.0/16"),
        QStringLiteral("172.16.0.0/12"),
        QStringLiteral("192.168.0.0/16"),
        QStringLiteral("::1/128"),
        QStringLiteral("fc00::/7"),
        QStringLiteral("fe80::/10")
    };

    QJsonArray rules;
    if (options.enableStatsApi) {
        rules.append(QJsonObject {
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("api-in")}},
            {QStringLiteral("outboundTag"), QStringLiteral("api")}
        });
    }

    if (options.enableTun) {
        rules.append(QJsonObject {
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("tun-in")}},
            {QStringLiteral("network"), QStringLiteral("tcp,udp")},
            {QStringLiteral("port"), QStringLiteral("53")},
            {QStringLiteral("outboundTag"), QStringLiteral("dns-out")}
        });

        // Prevent local discovery/broadcast storms from looping in TUN mode
        // (notably NetBIOS/mDNS/LLMNR/link-local chatter on Windows/macOS).
        rules.append(QJsonObject {
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("tun-in")}},
            {QStringLiteral("network"), QStringLiteral("udp")},
            {QStringLiteral("port"), QStringLiteral("137,138,5353,5355")},
            {QStringLiteral("outboundTag"), QStringLiteral("block")}
        });
        rules.append(QJsonObject {
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("tun-in")}},
            {QStringLiteral("network"), QStringLiteral("udp")},
            {QStringLiteral("ip"), QJsonArray {
                QStringLiteral("169.254.0.0/16"),
                QStringLiteral("255.255.255.255/32"),
                QStringLiteral("224.0.0.0/4")
            }},
            {QStringLiteral("outboundTag"), QStringLiteral("block")}
        });
    }

    QJsonObject privateDirectRule {
        {QStringLiteral("type"), QStringLiteral("field")},
        {QStringLiteral("outboundTag"), QStringLiteral("direct")},
        {QStringLiteral("ip"), privateCidrs}
    };
    if (options.enableTun) {
        // In TUN mode, keep RFC1918/link-local direct bypass only for local mixed
        // inbound traffic. Applying this rule to tun-in can create direct loops.
        privateDirectRule.insert(QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("mixed-in")});
    }
    rules.append(privateDirectRule);

    QJsonObject localhostDirectRule {
        {QStringLiteral("type"), QStringLiteral("field")},
        {QStringLiteral("outboundTag"), QStringLiteral("direct")},
        {QStringLiteral("domain"), QJsonArray {
            QStringLiteral("full:localhost"),
            QStringLiteral("domain:local"),
            QStringLiteral("regexp:.*\\.local\\.?$")
        }}
    };
    if (options.enableTun) {
        localhostDirectRule.insert(QStringLiteral("inboundTag"), QJsonArray {QStringLiteral("mixed-in")});
    }
    rules.append(localhostDirectRule);

    auto appendDomainRule = [&rules](const QStringList& entries, const QString& outboundTag) {
        const QJsonArray domains = toDomainArray(entries);
        if (domains.isEmpty()) {
            return;
        }

        rules.append(QJsonObject {
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("outboundTag"), outboundTag},
            {QStringLiteral("domain"), domains}
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
            {QStringLiteral("type"), QStringLiteral("field")},
            {QStringLiteral("outboundTag"), outboundTag},
            {QStringLiteral("process"), processes}
        });
    };

    appendDomainRule(options.blockDomains, QStringLiteral("block"));
    appendProcessRule(options.blockProcesses, QStringLiteral("block"));
    appendDomainRule(options.directDomains, QStringLiteral("direct"));
    appendProcessRule(options.directProcesses, QStringLiteral("direct"));
    appendDomainRule(options.proxyDomains, QStringLiteral("proxy"));
    appendProcessRule(options.proxyProcesses, QStringLiteral("proxy"));

    // In TUN mode we expect full-tunnel behavior by default; only explicit
    // direct/block rules should bypass proxy.
    const QString defaultOutbound = options.enableTun
        ? QStringLiteral("proxy")
        : (options.whitelistMode ? QStringLiteral("direct") : QStringLiteral("proxy"));
    rules.append(QJsonObject {
        {QStringLiteral("type"), QStringLiteral("field")},
        {QStringLiteral("outboundTag"), defaultOutbound},
        {QStringLiteral("network"), QStringLiteral("tcp,udp")}
    });

    return QJsonObject {
        {QStringLiteral("domainStrategy"), QStringLiteral("AsIs")},
        {QStringLiteral("rules"), rules}
    };
}

QJsonObject buildPolicy()
{
    return QJsonObject {
        {QStringLiteral("system"), QJsonObject {
            {QStringLiteral("statsInboundDownlink"), true},
            {QStringLiteral("statsInboundUplink"), true},
            {QStringLiteral("statsOutboundDownlink"), true},
            {QStringLiteral("statsOutboundUplink"), true}
        }}
    };
}

QJsonObject buildDirectOutbound()
{
    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("direct")},
        {QStringLiteral("protocol"), QStringLiteral("freedom")},
        {QStringLiteral("settings"), QJsonObject {}}
    };
}

QJsonObject buildBlockOutbound()
{
    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("block")},
        {QStringLiteral("protocol"), QStringLiteral("blackhole")},
        {QStringLiteral("settings"), QJsonObject {}}
    };
}

QJsonObject buildFragProxyOutbound()
{
    return QJsonObject {
        {QStringLiteral("tag"), QStringLiteral("frag-proxy")},
        {QStringLiteral("protocol"), QStringLiteral("freedom")},
        {QStringLiteral("settings"), QJsonObject {
            {QStringLiteral("fragment"), QJsonObject {
                {QStringLiteral("packets"), QStringLiteral("tlshello")},
                {QStringLiteral("length"), QStringLiteral("100-200")},
                {QStringLiteral("interval"), QStringLiteral("10-20")}
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
        return QStringLiteral("/");
    }
    while (normalized.startsWith(QStringLiteral("//"))) {
        normalized.remove(0, 1);
    }
    if (normalized.startsWith('/')) {
        return normalized;
    }
    return QStringLiteral("/") + normalized;
}

QJsonObject buildTlsPeerSettings(const ServerProfile& profile)
{
    QJsonObject tlsSettings;
    if (!profile.sni.isEmpty()) {
        tlsSettings[QStringLiteral("serverName")] = profile.sni;
    }
    if (!profile.alpn.isEmpty()) {
        const QStringList alpnParts = profile.alpn.split(',', Qt::SkipEmptyParts);
        QJsonArray alpnValues;
        for (const QString& part : alpnParts) {
            alpnValues.append(part.trimmed());
        }
        if (!alpnValues.isEmpty()) {
            tlsSettings[QStringLiteral("alpn")] = alpnValues;
        }
    }
    if (!profile.fingerprint.isEmpty()) {
        tlsSettings[QStringLiteral("fingerprint")] = profile.fingerprint;
    }
    tlsSettings[QStringLiteral("allowInsecure")] = profile.allowInsecure;
    return tlsSettings;
}
}

QJsonObject XrayConfigBuilder::build(const ServerProfile& profile, const BuildOptions& options)
{
    QJsonArray inbounds;
    inbounds.append(buildMixedInbound(options.socksPort));
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
        (profile.security == QStringLiteral("reality"));
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
        {QStringLiteral("log"), QJsonObject {
            {QStringLiteral("loglevel"), options.logLevel}
        }},
        {QStringLiteral("inbounds"), inbounds},
        {QStringLiteral("outbounds"), outbounds},
        {QStringLiteral("routing"), buildRouting(options)},
        {QStringLiteral("policy"), buildPolicy()},
        {QStringLiteral("stats"), QJsonObject {}}
    };

    if (options.enableStatsApi) {
        config[QStringLiteral("api")] = QJsonObject {
            {QStringLiteral("tag"), QStringLiteral("api")},
            {QStringLiteral("services"), QJsonArray {QStringLiteral("StatsService")}}
        };
    }
    if (options.enableTun) {
        config[QStringLiteral("dns")] = buildDnsConfig(options);
    }

    return config;
}

QJsonObject XrayConfigBuilder::buildMainOutbound(
    const ServerProfile& profile,
    bool enableMux,
    bool enableRealityFragDialer)
{
    QJsonObject user {
        {QStringLiteral("id"), profile.userId},
    };

    if (profile.protocol == QStringLiteral("vless")) {
        user[QStringLiteral("encryption")] = profile.encryption.isEmpty()
            ? QStringLiteral("none")
            : profile.encryption;
        if (!profile.flow.isEmpty()) {
            user[QStringLiteral("flow")] = profile.flow;
        }
    }

    if (profile.protocol == QStringLiteral("vmess")) {
        user[QStringLiteral("security")] = profile.encryption.isEmpty()
            ? QStringLiteral("auto")
            : profile.encryption;
        user[QStringLiteral("alterId")] = 0;
    }

    QJsonObject outbound {
        {QStringLiteral("tag"), QStringLiteral("proxy")},
        {QStringLiteral("protocol"), profile.protocol},
        {QStringLiteral("settings"), QJsonObject {
            {QStringLiteral("vnext"), QJsonArray {
                QJsonObject {
                    {QStringLiteral("address"), profile.address},
                    {QStringLiteral("port"), static_cast<int>(profile.port)},
                    {QStringLiteral("users"), QJsonArray {user}}
                }
            }}
        }},
        {QStringLiteral("streamSettings"), buildStreamSettings(profile)}
    };

    if (enableRealityFragDialer) {
        QJsonObject streamSettings = outbound.value(QStringLiteral("streamSettings")).toObject();
        streamSettings[QStringLiteral("sockopt")] = QJsonObject {
            {QStringLiteral("dialerProxy"), QStringLiteral("frag-proxy")}
        };
        outbound[QStringLiteral("streamSettings")] = streamSettings;
    }

    if (enableMux) {
        outbound[QStringLiteral("mux")] = QJsonObject {
            {QStringLiteral("enabled"), true},
            {QStringLiteral("concurrency"), 8}
        };
    }

    return outbound;
}

QJsonObject XrayConfigBuilder::buildStreamSettings(const ServerProfile& profile)
{
    QJsonObject stream {
        {QStringLiteral("network"), profile.network.isEmpty() ? QStringLiteral("tcp") : profile.network}
    };

    if (profile.network == QStringLiteral("ws")) {
        QJsonObject wsSettings;
        wsSettings[QStringLiteral("path")] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            wsSettings[QStringLiteral("headers")] = QJsonObject {
                {QStringLiteral("Host"), profile.hostHeader}
            };
        }

        stream[QStringLiteral("wsSettings")] = wsSettings;
    }

    if (profile.network == QStringLiteral("grpc")) {
        stream[QStringLiteral("grpcSettings")] = QJsonObject {
            {QStringLiteral("serviceName"), profile.serviceName}
        };
    }

    if (profile.network == QStringLiteral("xhttp")) {
        QJsonObject xhttpSettings;
        xhttpSettings[QStringLiteral("path")] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            xhttpSettings[QStringLiteral("host")] = profile.hostHeader;
        }
        xhttpSettings[QStringLiteral("mode")] = profile.xhttpMode.isEmpty()
            ? QStringLiteral("auto")
            : profile.xhttpMode;
        if (!profile.xhttpExtra.isEmpty()) {
            xhttpSettings[QStringLiteral("extra")] = profile.xhttpExtra;
        }

        stream[QStringLiteral("xhttpSettings")] = xhttpSettings;
    }

    if (profile.network == QStringLiteral("tcp")) {
        const QString headerType = profile.headerType.isEmpty()
            ? QStringLiteral("none")
            : profile.headerType;
        stream[QStringLiteral("tcpSettings")] = QJsonObject {
            {QStringLiteral("header"), QJsonObject {
                {QStringLiteral("type"), headerType}
            }}
        };
    }

    const QString security = profile.security.isEmpty()
        ? QStringLiteral("none")
        : profile.security;
    stream[QStringLiteral("security")] = security;

    if (security == QStringLiteral("tls")) {
        stream[QStringLiteral("tlsSettings")] = buildTlsPeerSettings(profile);
    }

    if (security == QStringLiteral("reality")) {
        QJsonObject realitySettings;

        if (!profile.sni.isEmpty()) {
            realitySettings[QStringLiteral("serverName")] = profile.sni;
        }
        if (!profile.fingerprint.isEmpty()) {
            realitySettings[QStringLiteral("fingerprint")] = profile.fingerprint;
        }
        if (!profile.publicKey.isEmpty()) {
            realitySettings[QStringLiteral("publicKey")] = profile.publicKey;
        }
        if (!profile.shortId.isEmpty()) {
            realitySettings[QStringLiteral("shortId")] = profile.shortId;
        }
        realitySettings[QStringLiteral("spiderX")] = profile.spiderX.isEmpty()
            ? QStringLiteral("/")
            : profile.spiderX;

        stream[QStringLiteral("realitySettings")] = realitySettings;
    }

    return stream;
}

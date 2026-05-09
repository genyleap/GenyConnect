module;
#include <QHostAddress>
#include <QFileInfo>
#include <QJsonArray>
#include <QSet>
#include <QStringList>
#include <QUrl>
#include <QtGlobal>

module genyconnect.backend.xrayconfigbuilder;

using namespace Qt::StringLiterals;

namespace {
QStringList defaultDnsServers()
{
    return {
        u"1.1.1.1"_s,
        u"8.8.8.8"_s,
        u"9.9.9.9"_s
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
        {u"enabled"_s, true},
        {u"destOverride"_s, QJsonArray {u"http"_s, u"tls"_s, u"quic"_s, u"fakedns"_s}},
        {u"routeOnly"_s, false}
    };

    QJsonObject inbound {
        {u"tag"_s, u"mixed-in"_s},
        {u"listen"_s, u"127.0.0.1"_s},
        {u"port"_s, static_cast<int>(port)},
        {u"protocol"_s, u"mixed"_s},
        {u"sniffing"_s, sniffing},
        {u"settings"_s, QJsonObject {
            {u"udp"_s, true},
            {u"auth"_s, u"noauth"_s},
            {u"allowTransparent"_s, false}
        }}
    };

    return inbound;
}

QJsonObject buildTunInbound(const XrayConfigBuilder::BuildOptions& options)
{
    QString tunStack = u"system"_s;
#if defined(Q_OS_LINUX)
    tunStack = u"gvisor"_s;
#endif

    QJsonObject settings {
        {u"address"_s, QJsonArray {
            u"172.19.0.1/30"_s,
            u"fd00:1234:5678::1/126"_s
        }},
        {u"mtu"_s, defaultTunMtu()},
        {u"stack"_s, tunStack},
        {u"autoRoute"_s, options.tunAutoRoute},
        {u"strictRoute"_s, options.tunStrictRoute},
        {u"sniff"_s, true}
    };

#if defined(Q_OS_MACOS)
    // Xray on macOS requires explicit utunN naming.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? u"utun9"_s
        : options.tunInterfaceName.trimmed();
    settings.insert(u"name"_s, tunName);
#elif defined(Q_OS_WIN)
    // Keep a stable adapter name on Windows so route binding and cleanup are deterministic.
    const QString tunName = options.tunInterfaceName.trimmed().isEmpty()
        ? u"genyconnect0"_s
        : options.tunInterfaceName.trimmed();
    settings.insert(u"name"_s, tunName);
    // Mirror Xray's documented Windows TUN options so the adapter gets DNS
    // servers assigned and Xray keeps its own outbound sockets on the
    // physical interface instead of chasing the tunnel.
    settings.insert(u"gateway"_s, QJsonArray {
        u"172.19.0.1/30"_s,
        u"fd00:1234:5678::1/126"_s
    });
    settings.insert(u"dns"_s, toStringArray(tunDnsServers(options.dnsServers)));
    settings.insert(u"autoOutboundsInterface"_s, u"auto"_s);
#endif

    return QJsonObject {
        {u"tag"_s, u"tun-in"_s},
        {u"protocol"_s, u"tun"_s},
        {u"settings"_s, settings}
    };
}

QJsonObject buildApiInbound(quint16 port)
{
    return QJsonObject {
        {u"tag"_s, u"api-in"_s},
        {u"listen"_s, u"127.0.0.1"_s},
        {u"port"_s, static_cast<int>(port)},
        {u"protocol"_s, u"dokodemo-door"_s},
        {u"settings"_s, QJsonObject {
            {u"address"_s, u"127.0.0.1"_s}
        }}
    };
}

QJsonObject buildDnsOutbound()
{
    return QJsonObject {
        {u"tag"_s, u"dns-out"_s},
        {u"protocol"_s, u"dns"_s},
        {u"settings"_s, QJsonObject {}}
    };
}

QJsonObject buildDnsConfig(const XrayConfigBuilder::BuildOptions& options)
{
    const QStringList servers = options.dnsServers.isEmpty()
        ? defaultDnsServers()
        : options.dnsServers;
    return QJsonObject {
        {u"servers"_s, toStringArray(servers)},
        {u"queryStrategy"_s, u"UseIP"_s}
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

    return u"domain:%1"_s.arg(trimmed);
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
            if (!fileName.endsWith(u".exe"_s, Qt::CaseInsensitive)
                && !baseName.isEmpty()) {
                appendUnique(baseName + u".exe"_s);
            }
#else
            if (fileName.endsWith(u".exe"_s, Qt::CaseInsensitive)) {
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
        u"10.0.0.0/8"_s,
        u"100.64.0.0/10"_s,
        u"127.0.0.0/8"_s,
        u"169.254.0.0/16"_s,
        u"172.16.0.0/12"_s,
        u"192.168.0.0/16"_s,
        u"::1/128"_s,
        u"fc00::/7"_s,
        u"fe80::/10"_s
    };

    QJsonArray rules;
    if (options.enableStatsApi) {
        rules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"api-in"_s}},
            {u"outboundTag"_s, u"api"_s}
        });
    }

    if (options.enableTun) {
        rules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"tcp,udp"_s},
            {u"port"_s, u"53"_s},
            {u"outboundTag"_s, u"dns-out"_s}
        });

        // Prevent local discovery/broadcast storms from looping in TUN mode
        // (notably NetBIOS/mDNS/LLMNR/link-local chatter on Windows/macOS).
        rules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"udp"_s},
            {u"port"_s, u"137,138,5353,5355"_s},
            {u"outboundTag"_s, u"block"_s}
        });
        rules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"inboundTag"_s, QJsonArray {u"tun-in"_s}},
            {u"network"_s, u"udp"_s},
            {u"ip"_s, QJsonArray {
                u"169.254.0.0/16"_s,
                u"255.255.255.255/32"_s,
                u"224.0.0.0/4"_s
            }},
            {u"outboundTag"_s, u"block"_s}
        });
    }

    QJsonObject privateDirectRule {
        {u"type"_s, u"field"_s},
        {u"outboundTag"_s, u"direct"_s},
        {u"ip"_s, privateCidrs}
    };
    if (options.enableTun) {
        // In TUN mode, keep RFC1918/link-local direct bypass only for local mixed
        // inbound traffic. Applying this rule to tun-in can create direct loops.
        privateDirectRule.insert(u"inboundTag"_s, QJsonArray {u"mixed-in"_s});
    }
    rules.append(privateDirectRule);

    QJsonObject localhostDirectRule {
        {u"type"_s, u"field"_s},
        {u"outboundTag"_s, u"direct"_s},
        {u"domain"_s, QJsonArray {
            u"full:localhost"_s,
            u"domain:local"_s,
            u"regexp:.*\\.local\\.?$"_s
        }}
    };
    if (options.enableTun) {
        localhostDirectRule.insert(u"inboundTag"_s, QJsonArray {u"mixed-in"_s});
    }
    rules.append(localhostDirectRule);

    auto appendDomainRule = [&rules](const QStringList& entries, const QString& outboundTag) {
        const QJsonArray domains = toDomainArray(entries);
        if (domains.isEmpty()) {
            return;
        }

        rules.append(QJsonObject {
            {u"type"_s, u"field"_s},
            {u"outboundTag"_s, outboundTag},
            {u"domain"_s, domains}
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
            {u"type"_s, u"field"_s},
            {u"outboundTag"_s, outboundTag},
            {u"process"_s, processes}
        });
    };

    appendDomainRule(options.blockDomains, u"block"_s);
    appendProcessRule(options.blockProcesses, u"block"_s);
    appendDomainRule(options.directDomains, u"direct"_s);
    appendProcessRule(options.directProcesses, u"direct"_s);
    appendDomainRule(options.proxyDomains, u"proxy"_s);
    appendProcessRule(options.proxyProcesses, u"proxy"_s);

    // In TUN mode we expect full-tunnel behavior by default; only explicit
    // direct/block rules should bypass proxy.
    const QString defaultOutbound = options.enableTun
        ? u"proxy"_s
        : (options.whitelistMode ? u"direct"_s : u"proxy"_s);
    rules.append(QJsonObject {
        {u"type"_s, u"field"_s},
        {u"outboundTag"_s, defaultOutbound},
        {u"network"_s, u"tcp,udp"_s}
    });

    return QJsonObject {
        {u"domainStrategy"_s, u"AsIs"_s},
        {u"rules"_s, rules}
    };
}

QJsonObject buildPolicy()
{
    return QJsonObject {
        {u"system"_s, QJsonObject {
            {u"statsInboundDownlink"_s, true},
            {u"statsInboundUplink"_s, true},
            {u"statsOutboundDownlink"_s, true},
            {u"statsOutboundUplink"_s, true}
        }}
    };
}

QJsonObject buildDirectOutbound()
{
    return QJsonObject {
        {u"tag"_s, u"direct"_s},
        {u"protocol"_s, u"freedom"_s},
        {u"settings"_s, QJsonObject {}}
    };
}

QJsonObject buildBlockOutbound()
{
    return QJsonObject {
        {u"tag"_s, u"block"_s},
        {u"protocol"_s, u"blackhole"_s},
        {u"settings"_s, QJsonObject {}}
    };
}

QJsonObject buildFragProxyOutbound()
{
    return QJsonObject {
        {u"tag"_s, u"frag-proxy"_s},
        {u"protocol"_s, u"freedom"_s},
        {u"settings"_s, QJsonObject {
            {u"fragment"_s, QJsonObject {
                {u"packets"_s, u"tlshello"_s},
                {u"length"_s, u"100-200"_s},
                {u"interval"_s, u"10-20"_s}
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
        return u"/"_s;
    }
    while (normalized.startsWith(u"//"_s)) {
        normalized.remove(0, 1);
    }
    if (normalized.startsWith('/')) {
        return normalized;
    }
    return u"/"_s + normalized;
}

QJsonObject buildTlsPeerSettings(const ServerProfile& profile)
{
    QJsonObject tlsSettings;
    if (!profile.sni.isEmpty()) {
        tlsSettings[u"serverName"_s] = profile.sni;
    }
    if (!profile.alpn.isEmpty()) {
        const QStringList alpnParts = profile.alpn.split(',', Qt::SkipEmptyParts);
        QJsonArray alpnValues;
        for (const QString& part : alpnParts) {
            alpnValues.append(part.trimmed());
        }
        if (!alpnValues.isEmpty()) {
            tlsSettings[u"alpn"_s] = alpnValues;
        }
    }
    if (!profile.fingerprint.isEmpty()) {
        tlsSettings[u"fingerprint"_s] = profile.fingerprint;
    }
    tlsSettings[u"allowInsecure"_s] = profile.allowInsecure;
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
        (profile.security == u"reality"_s);
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
        {u"log"_s, QJsonObject {
            {u"loglevel"_s, options.logLevel}
        }},
        {u"inbounds"_s, inbounds},
        {u"outbounds"_s, outbounds},
        {u"routing"_s, buildRouting(options)},
        {u"policy"_s, buildPolicy()},
        {u"stats"_s, QJsonObject {}}
    };

    if (options.enableStatsApi) {
        config[u"api"_s] = QJsonObject {
            {u"tag"_s, u"api"_s},
            {u"services"_s, QJsonArray {u"StatsService"_s}}
        };
    }
    if (options.enableTun) {
        config[u"dns"_s] = buildDnsConfig(options);
    }

    return config;
}

QJsonObject XrayConfigBuilder::buildMainOutbound(
    const ServerProfile& profile,
    bool enableMux,
    bool enableRealityFragDialer)
{
    QJsonObject user {
        {u"id"_s, profile.userId},
    };

    if (profile.protocol == u"vless"_s) {
        user[u"encryption"_s] = profile.encryption.isEmpty()
            ? u"none"_s
            : profile.encryption;
        if (!profile.flow.isEmpty()) {
            user[u"flow"_s] = profile.flow;
        }
    }

    if (profile.protocol == u"vmess"_s) {
        user[u"security"_s] = profile.encryption.isEmpty()
            ? u"auto"_s
            : profile.encryption;
        user[u"alterId"_s] = 0;
    }

    QJsonObject outbound {
        {u"tag"_s, u"proxy"_s},
        {u"protocol"_s, profile.protocol},
        {u"settings"_s, QJsonObject {
            {u"vnext"_s, QJsonArray {
                QJsonObject {
                    {u"address"_s, profile.address},
                    {u"port"_s, static_cast<int>(profile.port)},
                    {u"users"_s, QJsonArray {user}}
                }
            }}
        }},
        {u"streamSettings"_s, buildStreamSettings(profile)}
    };

    if (enableRealityFragDialer) {
        QJsonObject streamSettings = outbound.value(u"streamSettings"_s).toObject();
        streamSettings[u"sockopt"_s] = QJsonObject {
            {u"dialerProxy"_s, u"frag-proxy"_s}
        };
        outbound[u"streamSettings"_s] = streamSettings;
    }

    if (enableMux) {
        outbound[u"mux"_s] = QJsonObject {
            {u"enabled"_s, true},
            {u"concurrency"_s, 8}
        };
    }

    return outbound;
}

QJsonObject XrayConfigBuilder::buildStreamSettings(const ServerProfile& profile)
{
    QJsonObject stream {
        {u"network"_s, profile.network.isEmpty() ? u"tcp"_s : profile.network}
    };

    if (profile.network == u"ws"_s) {
        QJsonObject wsSettings;
        wsSettings[u"path"_s] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            wsSettings[u"headers"_s] = QJsonObject {
                {u"Host"_s, profile.hostHeader}
            };
        }

        stream[u"wsSettings"_s] = wsSettings;
    }

    if (profile.network == u"grpc"_s) {
        stream[u"grpcSettings"_s] = QJsonObject {
            {u"serviceName"_s, profile.serviceName}
        };
    }

    if (profile.network == u"xhttp"_s) {
        QJsonObject xhttpSettings;
        xhttpSettings[u"path"_s] = normalizeTransportPath(profile.path);

        if (!profile.hostHeader.isEmpty()) {
            xhttpSettings[u"host"_s] = profile.hostHeader;
        }
        xhttpSettings[u"mode"_s] = profile.xhttpMode.isEmpty()
            ? u"auto"_s
            : profile.xhttpMode;
        if (!profile.xhttpExtra.isEmpty()) {
            xhttpSettings[u"extra"_s] = profile.xhttpExtra;
        }

        stream[u"xhttpSettings"_s] = xhttpSettings;
    }

    if (profile.network == u"tcp"_s) {
        const QString headerType = profile.headerType.isEmpty()
            ? u"none"_s
            : profile.headerType;
        stream[u"tcpSettings"_s] = QJsonObject {
            {u"header"_s, QJsonObject {
                {u"type"_s, headerType}
            }}
        };
    }

    const QString security = profile.security.isEmpty()
        ? u"none"_s
        : profile.security;
    stream[u"security"_s] = security;

    if (security == u"tls"_s) {
        stream[u"tlsSettings"_s] = buildTlsPeerSettings(profile);
    }

    if (security == u"reality"_s) {
        QJsonObject realitySettings;

        if (!profile.sni.isEmpty()) {
            realitySettings[u"serverName"_s] = profile.sni;
        }
        if (!profile.fingerprint.isEmpty()) {
            realitySettings[u"fingerprint"_s] = profile.fingerprint;
        }
        if (!profile.publicKey.isEmpty()) {
            realitySettings[u"publicKey"_s] = profile.publicKey;
        }
        if (!profile.shortId.isEmpty()) {
            realitySettings[u"shortId"_s] = profile.shortId;
        }
        realitySettings[u"spiderX"_s] = profile.spiderX.isEmpty()
            ? u"/"_s
            : profile.spiderX;

        stream[u"realitySettings"_s] = realitySettings;
    }

    return stream;
}

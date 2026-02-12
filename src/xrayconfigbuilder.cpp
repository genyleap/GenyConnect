module;
#include <QJsonArray>
#include <QStringList>

module genyconnect.backend.xrayconfigbuilder;

namespace {
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

    rules.append(QJsonObject {
        {QStringLiteral("type"), QStringLiteral("field")},
        {QStringLiteral("outboundTag"), QStringLiteral("direct")},
        {QStringLiteral("ip"), privateCidrs}
    });

    rules.append(QJsonObject {
        {QStringLiteral("type"), QStringLiteral("field")},
        {QStringLiteral("outboundTag"), QStringLiteral("direct")},
        {QStringLiteral("domain"), QJsonArray {
            QStringLiteral("full:localhost"),
            QStringLiteral("domain:local"),
            QStringLiteral("regexp:.*\\.local\\.?$")
        }}
    });

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

    const QString defaultOutbound = options.whitelistMode
        ? QStringLiteral("direct")
        : QStringLiteral("proxy");
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
}

QJsonObject XrayConfigBuilder::build(const ServerProfile& profile, const BuildOptions& options)
{
    QJsonArray inbounds;
    inbounds.append(buildMixedInbound(options.socksPort));
    if (options.enableStatsApi) {
        inbounds.append(buildApiInbound(options.apiPort));
    }

    QJsonArray outbounds;
    outbounds.append(buildMainOutbound(profile, options.enableMux));
    outbounds.append(buildDirectOutbound());
    outbounds.append(buildBlockOutbound());
    if (profile.security == QStringLiteral("reality")) {
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

    return config;
}

QJsonObject XrayConfigBuilder::buildMainOutbound(const ServerProfile& profile, bool enableMux)
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

    if (profile.security == QStringLiteral("reality")) {
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
        wsSettings[QStringLiteral("path")] = profile.path.isEmpty() ? QStringLiteral("/") : profile.path;

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
        stream[QStringLiteral("tlsSettings")] = tlsSettings;
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

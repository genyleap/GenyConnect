module;
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QString>
#include <QUuid>
#include <QtGlobal>

#include <optional>

module genyconnect.backend.serverprofile;

namespace {
QString createProfileId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

std::optional<quint16> parseJsonPort(const QJsonValue& value)
{
    if (value.isUndefined() || value.isNull()) {
        return std::nullopt;
    }

    bool ok = false;
    int parsed = 0;
    if (value.isString()) {
        parsed = value.toString().trimmed().toInt(&ok);
    } else {
        parsed = value.toVariant().toInt(&ok);
    }

    if (!ok || parsed <= 0 || parsed > 65535) {
        return std::nullopt;
    }

    return static_cast<quint16>(parsed);
}

QStringList parseStringListValue(const QJsonValue& value)
{
    QStringList out;
    if (value.isArray()) {
        const QJsonArray array = value.toArray();
        out.reserve(array.size());
        for (const QJsonValue& item : array) {
            const QString token = item.toString().trimmed();
            if (!token.isEmpty()) {
                out.append(token);
            }
        }
        return out;
    }

    const QString asString = value.toString().trimmed();
    if (asString.isEmpty()) {
        return out;
    }
    const QStringList parts = asString.split(',', Qt::SkipEmptyParts);
    for (const QString& part : parts) {
        const QString token = part.trimmed();
        if (!token.isEmpty()) {
            out.append(token);
        }
    }
    return out;
}

QJsonArray toJsonArray(const QStringList& values)
{
    QJsonArray out;
    for (const QString& value : values) {
        const QString token = value.trimmed();
        if (!token.isEmpty()) {
            out.append(token);
        }
    }
    return out;
}

bool parseJsonBoolToken(const QJsonValue& value)
{
    if (value.isBool()) {
        return value.toBool(false);
    }
    if (value.isDouble()) {
        return value.toInt(0) != 0;
    }
    const QString token = value.toString().trimmed().toLower();
    return token == QString::fromUtf8("1")
        || token == QString::fromUtf8("true")
        || token == QString::fromUtf8("yes")
        || token == QString::fromUtf8("on");
}

QJsonValue firstJsonValue(const QJsonObject& json, const QStringList& keys)
{
    for (const QString& key : keys) {
        const QJsonValue value = json.value(key);
        if (!value.isUndefined() && !value.isNull()) {
            return value;
        }
    }
    return QJsonValue();
}
}

bool ServerProfile::isValid() const
{
    if (protocol.trimmed().compare(QString::fromUtf8("wireguard"), Qt::CaseInsensitive) == 0) {
        return !address.trimmed().isEmpty()
               && port > 0
               && !wgSecretKey.trimmed().isEmpty()
               && !wgPublicKey.trimmed().isEmpty();
    }
    return !protocol.trimmed().isEmpty()
       && !address.trimmed().isEmpty()
       && port > 0
       && !userId.trimmed().isEmpty();
}

QString ServerProfile::displayLabel() const
{
    if (!name.trimmed().isEmpty()) {
        return name.trimmed();
    }

    return QString::fromUtf8("%1:%2 (%3)")
        .arg(address.trimmed(), QString::number(port), protocol.toUpper());
}

QJsonObject ServerProfile::toJson() const
{
    QJsonObject json;
    json[QString::fromUtf8("id")] = id;
    json[QString::fromUtf8("name")] = name;
    json[QString::fromUtf8("protocol")] = protocol;
    json[QString::fromUtf8("address")] = address;
    json[QString::fromUtf8("port")] = static_cast<int>(port);

    json[QString::fromUtf8("userId")] = userId;
    json[QString::fromUtf8("encryption")] = encryption;
    json[QString::fromUtf8("flow")] = flow;
    json[QString::fromUtf8("network")] = network;
    json[QString::fromUtf8("security")] = security;

    json[QString::fromUtf8("sni")] = sni;
    json[QString::fromUtf8("alpn")] = alpn;
    json[QString::fromUtf8("fingerprint")] = fingerprint;
    json[QString::fromUtf8("publicKey")] = publicKey;
    json[QString::fromUtf8("shortId")] = shortId;
    json[QString::fromUtf8("spiderX")] = spiderX;
    json[QString::fromUtf8("pinnedPeerCertSha256")] = toJsonArray(pinnedPeerCertSha256);

    json[QString::fromUtf8("path")] = path;
    json[QString::fromUtf8("hostHeader")] = hostHeader;
    json[QString::fromUtf8("serviceName")] = serviceName;
    json[QString::fromUtf8("headerType")] = headerType;
    json[QString::fromUtf8("xhttpMode")] = xhttpMode;
    json[QString::fromUtf8("xhttpExtra")] = xhttpExtra;
    json[QString::fromUtf8("wgSecretKey")] = wgSecretKey;
    json[QString::fromUtf8("wgAddress")] = toJsonArray(wgAddress);
    json[QString::fromUtf8("wgPublicKey")] = wgPublicKey;
    json[QString::fromUtf8("wgPresharedKey")] = wgPresharedKey;
    json[QString::fromUtf8("wgAllowedIPs")] = toJsonArray(wgAllowedIPs);
    json[QString::fromUtf8("wgMtu")] = wgMtu;
    json[QString::fromUtf8("wgPersistentKeepalive")] = wgPersistentKeepalive;
    json[QString::fromUtf8("wgReserved")] = toJsonArray(wgReserved);
    json[QString::fromUtf8("wgDns")] = toJsonArray(wgDns);

    json[QString::fromUtf8("allowInsecure")] = allowInsecure;
    json[QString::fromUtf8("originalLink")] = originalLink;
    json[QString::fromUtf8("groupName")] = groupName;
    json[QString::fromUtf8("sourceName")] = sourceName;
    json[QString::fromUtf8("sourceId")] = sourceId;
    json[QString::fromUtf8("extra")] = extra;

    return json;
}

std::optional<ServerProfile> ServerProfile::fromJson(const QJsonObject& json)
{
    ServerProfile profile;
    profile.id = json.value(QString::fromUtf8("id")).toString().trimmed();
    profile.name = json.value(QString::fromUtf8("name")).toString().trimmed();
    profile.protocol = json.value(QString::fromUtf8("protocol")).toString().trimmed().toLower();
    profile.address = json.value(QString::fromUtf8("address")).toString().trimmed();
    const std::optional<quint16> port = parseJsonPort(json.value(QString::fromUtf8("port")));
    if (!port.has_value()) {
        return std::nullopt;
    }
    profile.port = *port;

    profile.userId = json.value(QString::fromUtf8("userId")).toString().trimmed();
    profile.encryption = json.value(QString::fromUtf8("encryption")).toString().trimmed();
    profile.flow = json.value(QString::fromUtf8("flow")).toString().trimmed();
    profile.network = json.value(QString::fromUtf8("network")).toString().trimmed().toLower();
    profile.security = json.value(QString::fromUtf8("security")).toString().trimmed().toLower();

    profile.sni = json.value(QString::fromUtf8("sni")).toString().trimmed();
    profile.alpn = json.value(QString::fromUtf8("alpn")).toString().trimmed();
    profile.fingerprint = json.value(QString::fromUtf8("fingerprint")).toString().trimmed();
    profile.publicKey = json.value(QString::fromUtf8("publicKey")).toString().trimmed();
    profile.shortId = json.value(QString::fromUtf8("shortId")).toString().trimmed();
    profile.spiderX = json.value(QString::fromUtf8("spiderX")).toString().trimmed();
    profile.pinnedPeerCertSha256 = parseStringListValue(firstJsonValue(json, {
        QString::fromUtf8("pinnedPeerCertSha256"),
        QString::fromUtf8("pinnedPeerCertificateChainSha256"),
        QString::fromUtf8("peerCertSha256"),
        QString::fromUtf8("certSha256")
    }));

    profile.path = json.value(QString::fromUtf8("path")).toString().trimmed();
    profile.hostHeader = json.value(QString::fromUtf8("hostHeader")).toString().trimmed();
    profile.serviceName = json.value(QString::fromUtf8("serviceName")).toString().trimmed();
    profile.headerType = json.value(QString::fromUtf8("headerType")).toString().trimmed().toLower();
    profile.xhttpMode = json.value(QString::fromUtf8("xhttpMode")).toString().trimmed().toLower();
    profile.xhttpExtra = json.value(QString::fromUtf8("xhttpExtra")).toObject();
    profile.wgSecretKey = json.value(QString::fromUtf8("wgSecretKey")).toString().trimmed();
    profile.wgAddress = parseStringListValue(json.value(QString::fromUtf8("wgAddress")));
    profile.wgPublicKey = json.value(QString::fromUtf8("wgPublicKey")).toString().trimmed();
    profile.wgPresharedKey = json.value(QString::fromUtf8("wgPresharedKey")).toString().trimmed();
    profile.wgAllowedIPs = parseStringListValue(json.value(QString::fromUtf8("wgAllowedIPs")));
    profile.wgMtu = qMax(0, json.value(QString::fromUtf8("wgMtu")).toVariant().toInt());
    profile.wgPersistentKeepalive = qMax(0, json.value(QString::fromUtf8("wgPersistentKeepalive")).toVariant().toInt());
    profile.wgReserved = parseStringListValue(json.value(QString::fromUtf8("wgReserved")));
    profile.wgDns = parseStringListValue(json.value(QString::fromUtf8("wgDns")));

    profile.allowInsecure = parseJsonBoolToken(firstJsonValue(json, {
        QString::fromUtf8("allowInsecure"),
        QString::fromUtf8("insecure"),
        QString::fromUtf8("allow_insecure"),
        QString::fromUtf8("tlsAllowInsecure"),
        QString::fromUtf8("skipCertVerify"),
        QString::fromUtf8("skipCertificateVerify")
    }));
    profile.originalLink = json.value(QString::fromUtf8("originalLink")).toString().trimmed();
    profile.groupName = json.value(QString::fromUtf8("groupName")).toString().trimmed();
    profile.sourceName = json.value(QString::fromUtf8("sourceName")).toString().trimmed();
    profile.sourceId = json.value(QString::fromUtf8("sourceId")).toString().trimmed();
    profile.extra = json.value(QString::fromUtf8("extra")).toObject();

    if (profile.id.isEmpty()) {
        profile.id = createProfileId();
    }

    if (!profile.isValid()) {
        return std::nullopt;
    }

    return profile;
}

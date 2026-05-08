module;
#include <QJsonObject>
#include <QJsonValue>
#include <QString>
#include <QUuid>

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
}

bool ServerProfile::isValid() const
{
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

    return QStringLiteral("%1:%2 (%3)")
        .arg(address.trimmed(), QString::number(port), protocol.toUpper());
}

QJsonObject ServerProfile::toJson() const
{
    QJsonObject json;
    json[QStringLiteral("id")] = id;
    json[QStringLiteral("name")] = name;
    json[QStringLiteral("protocol")] = protocol;
    json[QStringLiteral("address")] = address;
    json[QStringLiteral("port")] = static_cast<int>(port);

    json[QStringLiteral("userId")] = userId;
    json[QStringLiteral("encryption")] = encryption;
    json[QStringLiteral("flow")] = flow;
    json[QStringLiteral("network")] = network;
    json[QStringLiteral("security")] = security;

    json[QStringLiteral("sni")] = sni;
    json[QStringLiteral("alpn")] = alpn;
    json[QStringLiteral("fingerprint")] = fingerprint;
    json[QStringLiteral("publicKey")] = publicKey;
    json[QStringLiteral("shortId")] = shortId;
    json[QStringLiteral("spiderX")] = spiderX;

    json[QStringLiteral("path")] = path;
    json[QStringLiteral("hostHeader")] = hostHeader;
    json[QStringLiteral("serviceName")] = serviceName;
    json[QStringLiteral("headerType")] = headerType;
    json[QStringLiteral("xhttpMode")] = xhttpMode;
    json[QStringLiteral("xhttpExtra")] = xhttpExtra;

    json[QStringLiteral("allowInsecure")] = allowInsecure;
    json[QStringLiteral("originalLink")] = originalLink;
    json[QStringLiteral("groupName")] = groupName;
    json[QStringLiteral("sourceName")] = sourceName;
    json[QStringLiteral("sourceId")] = sourceId;
    json[QStringLiteral("extra")] = extra;

    return json;
}

std::optional<ServerProfile> ServerProfile::fromJson(const QJsonObject& json)
{
    ServerProfile profile;
    profile.id = json.value(QStringLiteral("id")).toString().trimmed();
    profile.name = json.value(QStringLiteral("name")).toString().trimmed();
    profile.protocol = json.value(QStringLiteral("protocol")).toString().trimmed().toLower();
    profile.address = json.value(QStringLiteral("address")).toString().trimmed();
    const std::optional<quint16> port = parseJsonPort(json.value(QStringLiteral("port")));
    if (!port.has_value()) {
        return std::nullopt;
    }
    profile.port = *port;

    profile.userId = json.value(QStringLiteral("userId")).toString().trimmed();
    profile.encryption = json.value(QStringLiteral("encryption")).toString().trimmed();
    profile.flow = json.value(QStringLiteral("flow")).toString().trimmed();
    profile.network = json.value(QStringLiteral("network")).toString().trimmed().toLower();
    profile.security = json.value(QStringLiteral("security")).toString().trimmed().toLower();

    profile.sni = json.value(QStringLiteral("sni")).toString().trimmed();
    profile.alpn = json.value(QStringLiteral("alpn")).toString().trimmed();
    profile.fingerprint = json.value(QStringLiteral("fingerprint")).toString().trimmed();
    profile.publicKey = json.value(QStringLiteral("publicKey")).toString().trimmed();
    profile.shortId = json.value(QStringLiteral("shortId")).toString().trimmed();
    profile.spiderX = json.value(QStringLiteral("spiderX")).toString().trimmed();

    profile.path = json.value(QStringLiteral("path")).toString().trimmed();
    profile.hostHeader = json.value(QStringLiteral("hostHeader")).toString().trimmed();
    profile.serviceName = json.value(QStringLiteral("serviceName")).toString().trimmed();
    profile.headerType = json.value(QStringLiteral("headerType")).toString().trimmed().toLower();
    profile.xhttpMode = json.value(QStringLiteral("xhttpMode")).toString().trimmed().toLower();
    profile.xhttpExtra = json.value(QStringLiteral("xhttpExtra")).toObject();

    profile.allowInsecure = json.value(QStringLiteral("allowInsecure")).toBool(false);
    profile.originalLink = json.value(QStringLiteral("originalLink")).toString().trimmed();
    profile.groupName = json.value(QStringLiteral("groupName")).toString().trimmed();
    profile.sourceName = json.value(QStringLiteral("sourceName")).toString().trimmed();
    profile.sourceId = json.value(QStringLiteral("sourceId")).toString().trimmed();
    profile.extra = json.value(QStringLiteral("extra")).toObject();

    if (profile.id.isEmpty()) {
        profile.id = createProfileId();
    }

    if (!profile.isValid()) {
        return std::nullopt;
    }

    return profile;
}

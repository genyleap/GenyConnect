module;
#include <QJsonObject>
#include <QJsonValue>
#include <QString>
#include <QUuid>

#include <optional>

module genyconnect.backend.serverprofile;

using namespace Qt::StringLiterals;

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

    return u"%1:%2 (%3)"_s
        .arg(address.trimmed(), QString::number(port), protocol.toUpper());
}

QJsonObject ServerProfile::toJson() const
{
    QJsonObject json;
    json[u"id"_s] = id;
    json[u"name"_s] = name;
    json[u"protocol"_s] = protocol;
    json[u"address"_s] = address;
    json[u"port"_s] = static_cast<int>(port);

    json[u"userId"_s] = userId;
    json[u"encryption"_s] = encryption;
    json[u"flow"_s] = flow;
    json[u"network"_s] = network;
    json[u"security"_s] = security;

    json[u"sni"_s] = sni;
    json[u"alpn"_s] = alpn;
    json[u"fingerprint"_s] = fingerprint;
    json[u"publicKey"_s] = publicKey;
    json[u"shortId"_s] = shortId;
    json[u"spiderX"_s] = spiderX;

    json[u"path"_s] = path;
    json[u"hostHeader"_s] = hostHeader;
    json[u"serviceName"_s] = serviceName;
    json[u"headerType"_s] = headerType;
    json[u"xhttpMode"_s] = xhttpMode;
    json[u"xhttpExtra"_s] = xhttpExtra;

    json[u"allowInsecure"_s] = allowInsecure;
    json[u"originalLink"_s] = originalLink;
    json[u"groupName"_s] = groupName;
    json[u"sourceName"_s] = sourceName;
    json[u"sourceId"_s] = sourceId;
    json[u"extra"_s] = extra;

    return json;
}

std::optional<ServerProfile> ServerProfile::fromJson(const QJsonObject& json)
{
    ServerProfile profile;
    profile.id = json.value(u"id"_s).toString().trimmed();
    profile.name = json.value(u"name"_s).toString().trimmed();
    profile.protocol = json.value(u"protocol"_s).toString().trimmed().toLower();
    profile.address = json.value(u"address"_s).toString().trimmed();
    const std::optional<quint16> port = parseJsonPort(json.value(u"port"_s));
    if (!port.has_value()) {
        return std::nullopt;
    }
    profile.port = *port;

    profile.userId = json.value(u"userId"_s).toString().trimmed();
    profile.encryption = json.value(u"encryption"_s).toString().trimmed();
    profile.flow = json.value(u"flow"_s).toString().trimmed();
    profile.network = json.value(u"network"_s).toString().trimmed().toLower();
    profile.security = json.value(u"security"_s).toString().trimmed().toLower();

    profile.sni = json.value(u"sni"_s).toString().trimmed();
    profile.alpn = json.value(u"alpn"_s).toString().trimmed();
    profile.fingerprint = json.value(u"fingerprint"_s).toString().trimmed();
    profile.publicKey = json.value(u"publicKey"_s).toString().trimmed();
    profile.shortId = json.value(u"shortId"_s).toString().trimmed();
    profile.spiderX = json.value(u"spiderX"_s).toString().trimmed();

    profile.path = json.value(u"path"_s).toString().trimmed();
    profile.hostHeader = json.value(u"hostHeader"_s).toString().trimmed();
    profile.serviceName = json.value(u"serviceName"_s).toString().trimmed();
    profile.headerType = json.value(u"headerType"_s).toString().trimmed().toLower();
    profile.xhttpMode = json.value(u"xhttpMode"_s).toString().trimmed().toLower();
    profile.xhttpExtra = json.value(u"xhttpExtra"_s).toObject();

    profile.allowInsecure = json.value(u"allowInsecure"_s).toBool(false);
    profile.originalLink = json.value(u"originalLink"_s).toString().trimmed();
    profile.groupName = json.value(u"groupName"_s).toString().trimmed();
    profile.sourceName = json.value(u"sourceName"_s).toString().trimmed();
    profile.sourceId = json.value(u"sourceId"_s).toString().trimmed();
    profile.extra = json.value(u"extra"_s).toObject();

    if (profile.id.isEmpty()) {
        profile.id = createProfileId();
    }

    if (!profile.isValid()) {
        return std::nullopt;
    }

    return profile;
}

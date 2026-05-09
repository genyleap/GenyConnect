module;
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QUrl>
#include <QUrlQuery>
#include <QUuid>

#include <optional>

module genyconnect.backend.linkparser;

using namespace Qt::StringLiterals;

namespace {
QString createProfileId()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString normalizePath(const QString& path)
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

std::optional<quint16> parsePort(const QJsonValue& value)
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

std::optional<QJsonObject> parseJsonObjectText(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty()) {
        return QJsonObject {};
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(trimmed.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        return std::nullopt;
    }

    return doc.object();
}
}

std::optional<ServerProfile> LinkParser::parse(const QString& rawLink, QString *errorMessage)
{
    const QString link = rawLink.trimmed();
    if (link.isEmpty()) {
        setError(errorMessage, u"Import link is empty."_s);
        return std::nullopt;
    }

    if (link.startsWith(u"vmess://"_s, Qt::CaseInsensitive)) {
        return parseVmess(link, errorMessage);
    }

    if (link.startsWith(u"vless://"_s, Qt::CaseInsensitive)) {
        return parseVless(link, errorMessage);
    }

    setError(errorMessage, u"Unsupported link format. Use VMESS or VLESS."_s);
    return std::nullopt;
}

std::optional<ServerProfile> LinkParser::parseVmess(const QString& rawLink, QString *errorMessage)
{
    QString payload = rawLink.mid(u"vmess://"_s.size()).trimmed();
    QString profileName;

    const int fragmentIdx = payload.indexOf('#');
    if (fragmentIdx >= 0) {
        profileName = QUrl::fromPercentEncoding(payload.mid(fragmentIdx + 1).toUtf8());
        payload = payload.left(fragmentIdx);
    }

    const QByteArray decoded = decodeFlexibleBase64(payload);
    if (decoded.isEmpty()) {
        setError(errorMessage, u"VMESS payload could not be Base64-decoded."_s);
        return std::nullopt;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(decoded,& parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        setError(errorMessage, u"VMESS payload is not valid JSON."_s);
        return std::nullopt;
    }

    const QJsonObject obj = doc.object();

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = u"vmess"_s;
    profile.name = profileName.isEmpty()
        ? obj.value(u"ps"_s).toString().trimmed()
        : profileName;

    profile.address = obj.value(u"add"_s).toString().trimmed();
    const std::optional<quint16> port = parsePort(obj.value(u"port"_s));
    if (!port.has_value()) {
        setError(errorMessage, u"VMESS link has an invalid port."_s);
        return std::nullopt;
    }
    profile.port = *port;
    profile.userId = obj.value(u"id"_s).toString().trimmed();
    profile.encryption = obj.value(u"scy"_s).toString().trimmed();
    if (profile.encryption.isEmpty()) {
        profile.encryption = u"auto"_s;
    }

    profile.network = obj.value(u"net"_s).toString().trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = u"tcp"_s;
    }

    profile.security = obj.value(u"tls"_s).toString().trimmed().toLower();
    if (profile.security == u"none"_s || profile.security.isEmpty()) {
        profile.security = u"none"_s;
    }

    profile.path = obj.value(u"path"_s).toString();
    if (profile.network == u"ws"_s
        || profile.network == u"xhttp"_s) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = obj.value(u"type"_s).toString().trimmed().toLower();

    profile.hostHeader = obj.value(u"host"_s).toString().trimmed();
    profile.sni = obj.value(u"sni"_s).toString().trimmed();
    profile.alpn = obj.value(u"alpn"_s).toString().trimmed();
    profile.flow = obj.value(u"flow"_s).toString().trimmed();

    profile.fingerprint = obj.value(u"fp"_s).toString().trimmed();
    profile.publicKey = obj.value(u"pbk"_s).toString().trimmed();
    profile.shortId = obj.value(u"sid"_s).toString().trimmed();
    profile.spiderX = obj.value(u"spx"_s).toString().trimmed();

    profile.serviceName = obj.value(u"serviceName"_s).toString().trimmed();
    profile.xhttpMode = obj.value(u"mode"_s).toString().trimmed().toLower();
    if (profile.network == u"xhttp"_s && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = u"auto"_s;
    }
    profile.xhttpExtra = obj.value(u"extra"_s).toObject();
    const QString allowInsecure = obj.value(u"allowInsecure"_s).toString().trimmed().toLower();
    profile.allowInsecure = (allowInsecure == u"1"_s || allowInsecure == u"true"_s);

    profile.originalLink = rawLink;
    profile.extra = obj;

    if (!profile.isValid()) {
        setError(errorMessage, u"VMESS link is missing required fields."_s);
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseVless(const QString& rawLink, QString *errorMessage)
{
    const QUrl url(rawLink);
    if (!url.isValid()) {
        setError(errorMessage, u"VLESS link is not a valid URL."_s);
        return std::nullopt;
    }

    const QUrlQuery query(url);

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = u"vless"_s;
    profile.name = QUrl::fromPercentEncoding(url.fragment().toUtf8()).trimmed();

    profile.userId = url.userName().trimmed();
    profile.address = url.host().trimmed();
    const int parsedPort = url.port(-1);
    if (parsedPort == -1) {
        profile.port = 443;
    } else if (parsedPort > 0 && parsedPort <= 65535) {
        profile.port = static_cast<quint16>(parsedPort);
    } else {
        setError(errorMessage, u"VLESS link has an invalid port."_s);
        return std::nullopt;
    }

    profile.network = query.queryItemValue(u"type"_s).trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = u"tcp"_s;
    }

    profile.security = query.queryItemValue(u"security"_s).trimmed().toLower();
    if (profile.security.isEmpty()) {
        profile.security = u"none"_s;
    }

    profile.encryption = query.queryItemValue(u"encryption"_s).trimmed().toLower();
    if (profile.encryption.isEmpty()) {
        profile.encryption = u"none"_s;
    }

    profile.flow = query.queryItemValue(u"flow"_s).trimmed();

    profile.path = query.queryItemValue(u"path"_s);
    if (profile.network == u"ws"_s
        || profile.network == u"xhttp"_s) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = query.queryItemValue(u"headerType"_s).trimmed().toLower();

    profile.hostHeader = query.queryItemValue(u"host"_s).trimmed();
    profile.serviceName = query.queryItemValue(u"serviceName"_s).trimmed();
    profile.xhttpMode = query.queryItemValue(u"mode"_s).trimmed().toLower();
    if (profile.network == u"xhttp"_s && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = u"auto"_s;
    }

    const QString extraValue = query.queryItemValue(u"extra"_s);
    if (!extraValue.trimmed().isEmpty()) {
        const std::optional<QJsonObject> xhttpExtra = parseJsonObjectText(extraValue);
        if (!xhttpExtra.has_value()) {
            setError(errorMessage, u"VLESS link has invalid XHTTP extra JSON."_s);
            return std::nullopt;
        }
        profile.xhttpExtra = *xhttpExtra;
    }

    profile.sni = query.queryItemValue(u"sni"_s).trimmed();
    if (profile.sni.isEmpty()) {
        profile.sni = query.queryItemValue(u"serverName"_s).trimmed();
    }

    profile.alpn = query.queryItemValue(u"alpn"_s).trimmed();
    profile.fingerprint = query.queryItemValue(u"fp"_s).trimmed();
    profile.publicKey = query.queryItemValue(u"pbk"_s).trimmed();
    profile.shortId = query.queryItemValue(u"sid"_s).trimmed();
    profile.spiderX = query.queryItemValue(u"spx"_s).trimmed();

    QString allowInsecure = query.queryItemValue(u"allowInsecure"_s).trimmed().toLower();
    if (allowInsecure.isEmpty()) {
        allowInsecure = query.queryItemValue(u"insecure"_s).trimmed().toLower();
    }
    profile.allowInsecure = (allowInsecure == u"1"_s || allowInsecure == u"true"_s);

    profile.originalLink = rawLink;

    if (!profile.isValid()) {
        setError(errorMessage, u"VLESS link is missing required fields."_s);
        return std::nullopt;
    }

    return profile;
}

QByteArray LinkParser::decodeFlexibleBase64(const QString& value)
{
    QByteArray raw = value.toUtf8();
    raw.replace('-', '+');
    raw.replace('_', '/');

    const int padding = raw.size() % 4;
    if (padding > 0) {
        raw.append(QByteArray(4 - padding, '='));
    }

    QByteArray decoded = QByteArray::fromBase64(raw, QByteArray::AbortOnBase64DecodingErrors);
    if (!decoded.isEmpty()) {
        return decoded;
    }

    return QByteArray::fromBase64(value.toUtf8(), QByteArray::AbortOnBase64DecodingErrors);
}

void LinkParser::setError(QString *errorMessage, const QString& error)
{
    if (errorMessage) {
        *errorMessage = error;
    }
}

module;
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QUrl>
#include <QUrlQuery>
#include <QUuid>

#include <optional>

module genyconnect.backend.linkparser;

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
        setError(errorMessage, QStringLiteral("Import link is empty."));
        return std::nullopt;
    }

    if (link.startsWith(QStringLiteral("vmess://"), Qt::CaseInsensitive)) {
        return parseVmess(link, errorMessage);
    }

    if (link.startsWith(QStringLiteral("vless://"), Qt::CaseInsensitive)) {
        return parseVless(link, errorMessage);
    }

    setError(errorMessage, QStringLiteral("Unsupported link format. Use VMESS or VLESS."));
    return std::nullopt;
}

std::optional<ServerProfile> LinkParser::parseVmess(const QString& rawLink, QString *errorMessage)
{
    QString payload = rawLink.mid(QStringLiteral("vmess://").size()).trimmed();
    QString profileName;

    const int fragmentIdx = payload.indexOf('#');
    if (fragmentIdx >= 0) {
        profileName = QUrl::fromPercentEncoding(payload.mid(fragmentIdx + 1).toUtf8());
        payload = payload.left(fragmentIdx);
    }

    const QByteArray decoded = decodeFlexibleBase64(payload);
    if (decoded.isEmpty()) {
        setError(errorMessage, QStringLiteral("VMESS payload could not be Base64-decoded."));
        return std::nullopt;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(decoded,& parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        setError(errorMessage, QStringLiteral("VMESS payload is not valid JSON."));
        return std::nullopt;
    }

    const QJsonObject obj = doc.object();

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QStringLiteral("vmess");
    profile.name = profileName.isEmpty()
        ? obj.value(QStringLiteral("ps")).toString().trimmed()
        : profileName;

    profile.address = obj.value(QStringLiteral("add")).toString().trimmed();
    const std::optional<quint16> port = parsePort(obj.value(QStringLiteral("port")));
    if (!port.has_value()) {
        setError(errorMessage, QStringLiteral("VMESS link has an invalid port."));
        return std::nullopt;
    }
    profile.port = *port;
    profile.userId = obj.value(QStringLiteral("id")).toString().trimmed();
    profile.encryption = obj.value(QStringLiteral("scy")).toString().trimmed();
    if (profile.encryption.isEmpty()) {
        profile.encryption = QStringLiteral("auto");
    }

    profile.network = obj.value(QStringLiteral("net")).toString().trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = QStringLiteral("tcp");
    }

    profile.security = obj.value(QStringLiteral("tls")).toString().trimmed().toLower();
    if (profile.security == QStringLiteral("none") || profile.security.isEmpty()) {
        profile.security = QStringLiteral("none");
    }

    profile.path = obj.value(QStringLiteral("path")).toString();
    if (profile.network == QStringLiteral("ws")
        || profile.network == QStringLiteral("xhttp")) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = obj.value(QStringLiteral("type")).toString().trimmed().toLower();

    profile.hostHeader = obj.value(QStringLiteral("host")).toString().trimmed();
    profile.sni = obj.value(QStringLiteral("sni")).toString().trimmed();
    profile.alpn = obj.value(QStringLiteral("alpn")).toString().trimmed();
    profile.flow = obj.value(QStringLiteral("flow")).toString().trimmed();

    profile.fingerprint = obj.value(QStringLiteral("fp")).toString().trimmed();
    profile.publicKey = obj.value(QStringLiteral("pbk")).toString().trimmed();
    profile.shortId = obj.value(QStringLiteral("sid")).toString().trimmed();
    profile.spiderX = obj.value(QStringLiteral("spx")).toString().trimmed();

    profile.serviceName = obj.value(QStringLiteral("serviceName")).toString().trimmed();
    profile.xhttpMode = obj.value(QStringLiteral("mode")).toString().trimmed().toLower();
    if (profile.network == QStringLiteral("xhttp") && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = QStringLiteral("auto");
    }
    profile.xhttpExtra = obj.value(QStringLiteral("extra")).toObject();
    const QString allowInsecure = obj.value(QStringLiteral("allowInsecure")).toString().trimmed().toLower();
    profile.allowInsecure = (allowInsecure == QStringLiteral("1") || allowInsecure == QStringLiteral("true"));

    profile.originalLink = rawLink;
    profile.extra = obj;

    if (!profile.isValid()) {
        setError(errorMessage, QStringLiteral("VMESS link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseVless(const QString& rawLink, QString *errorMessage)
{
    const QUrl url(rawLink);
    if (!url.isValid()) {
        setError(errorMessage, QStringLiteral("VLESS link is not a valid URL."));
        return std::nullopt;
    }

    const QUrlQuery query(url);

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QStringLiteral("vless");
    profile.name = QUrl::fromPercentEncoding(url.fragment().toUtf8()).trimmed();

    profile.userId = url.userName().trimmed();
    profile.address = url.host().trimmed();
    const int parsedPort = url.port(-1);
    if (parsedPort == -1) {
        profile.port = 443;
    } else if (parsedPort > 0 && parsedPort <= 65535) {
        profile.port = static_cast<quint16>(parsedPort);
    } else {
        setError(errorMessage, QStringLiteral("VLESS link has an invalid port."));
        return std::nullopt;
    }

    profile.network = query.queryItemValue(QStringLiteral("type")).trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = QStringLiteral("tcp");
    }

    profile.security = query.queryItemValue(QStringLiteral("security")).trimmed().toLower();
    if (profile.security.isEmpty()) {
        profile.security = QStringLiteral("none");
    }

    profile.encryption = query.queryItemValue(QStringLiteral("encryption")).trimmed().toLower();
    if (profile.encryption.isEmpty()) {
        profile.encryption = QStringLiteral("none");
    }

    profile.flow = query.queryItemValue(QStringLiteral("flow")).trimmed();

    profile.path = query.queryItemValue(QStringLiteral("path"));
    if (profile.network == QStringLiteral("ws")
        || profile.network == QStringLiteral("xhttp")) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = query.queryItemValue(QStringLiteral("headerType")).trimmed().toLower();

    profile.hostHeader = query.queryItemValue(QStringLiteral("host")).trimmed();
    profile.serviceName = query.queryItemValue(QStringLiteral("serviceName")).trimmed();
    profile.xhttpMode = query.queryItemValue(QStringLiteral("mode")).trimmed().toLower();
    if (profile.network == QStringLiteral("xhttp") && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = QStringLiteral("auto");
    }

    const QString extraValue = query.queryItemValue(QStringLiteral("extra"));
    if (!extraValue.trimmed().isEmpty()) {
        const std::optional<QJsonObject> xhttpExtra = parseJsonObjectText(extraValue);
        if (!xhttpExtra.has_value()) {
            setError(errorMessage, QStringLiteral("VLESS link has invalid XHTTP extra JSON."));
            return std::nullopt;
        }
        profile.xhttpExtra = *xhttpExtra;
    }

    profile.sni = query.queryItemValue(QStringLiteral("sni")).trimmed();
    if (profile.sni.isEmpty()) {
        profile.sni = query.queryItemValue(QStringLiteral("serverName")).trimmed();
    }

    profile.alpn = query.queryItemValue(QStringLiteral("alpn")).trimmed();
    profile.fingerprint = query.queryItemValue(QStringLiteral("fp")).trimmed();
    profile.publicKey = query.queryItemValue(QStringLiteral("pbk")).trimmed();
    profile.shortId = query.queryItemValue(QStringLiteral("sid")).trimmed();
    profile.spiderX = query.queryItemValue(QStringLiteral("spx")).trimmed();

    QString allowInsecure = query.queryItemValue(QStringLiteral("allowInsecure")).trimmed().toLower();
    if (allowInsecure.isEmpty()) {
        allowInsecure = query.queryItemValue(QStringLiteral("insecure")).trimmed().toLower();
    }
    profile.allowInsecure = (allowInsecure == QStringLiteral("1") || allowInsecure == QStringLiteral("true"));

    profile.originalLink = rawLink;

    if (!profile.isValid()) {
        setError(errorMessage, QStringLiteral("VLESS link is missing required fields."));
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

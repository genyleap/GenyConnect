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
        setError(errorMessage, QString::fromUtf8("Import link is empty."));
        return std::nullopt;
    }

    if (link.startsWith(QString::fromUtf8("vmess://"), Qt::CaseInsensitive)) {
        return parseVmess(link, errorMessage);
    }

    if (link.startsWith(QString::fromUtf8("vless://"), Qt::CaseInsensitive)) {
        return parseVless(link, errorMessage);
    }

    setError(errorMessage, QString::fromUtf8("Unsupported link format. Use VMESS or VLESS."));
    return std::nullopt;
}

std::optional<ServerProfile> LinkParser::parseVmess(const QString& rawLink, QString *errorMessage)
{
    QString payload = rawLink.mid(QString::fromUtf8("vmess://").size()).trimmed();
    QString profileName;

    const int fragmentIdx = payload.indexOf('#');
    if (fragmentIdx >= 0) {
        profileName = QUrl::fromPercentEncoding(payload.mid(fragmentIdx + 1).toUtf8());
        payload = payload.left(fragmentIdx);
    }

    const QByteArray decoded = decodeFlexibleBase64(payload);
    if (decoded.isEmpty()) {
        setError(errorMessage, QString::fromUtf8("VMESS payload could not be Base64-decoded."));
        return std::nullopt;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(decoded,& parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        setError(errorMessage, QString::fromUtf8("VMESS payload is not valid JSON."));
        return std::nullopt;
    }

    const QJsonObject obj = doc.object();

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("vmess");
    profile.name = profileName.isEmpty()
        ? obj.value(QString::fromUtf8("ps")).toString().trimmed()
        : profileName;

    profile.address = obj.value(QString::fromUtf8("add")).toString().trimmed();
    const std::optional<quint16> port = parsePort(obj.value(QString::fromUtf8("port")));
    if (!port.has_value()) {
        setError(errorMessage, QString::fromUtf8("VMESS link has an invalid port."));
        return std::nullopt;
    }
    profile.port = *port;
    profile.userId = obj.value(QString::fromUtf8("id")).toString().trimmed();
    profile.encryption = obj.value(QString::fromUtf8("scy")).toString().trimmed();
    if (profile.encryption.isEmpty()) {
        profile.encryption = QString::fromUtf8("auto");
    }

    profile.network = obj.value(QString::fromUtf8("net")).toString().trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = QString::fromUtf8("tcp");
    }

    profile.security = obj.value(QString::fromUtf8("tls")).toString().trimmed().toLower();
    if (profile.security == QString::fromUtf8("none") || profile.security.isEmpty()) {
        profile.security = QString::fromUtf8("none");
    }

    profile.path = obj.value(QString::fromUtf8("path")).toString();
    if (profile.network == QString::fromUtf8("ws")
        || profile.network == QString::fromUtf8("xhttp")) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = obj.value(QString::fromUtf8("type")).toString().trimmed().toLower();

    profile.hostHeader = obj.value(QString::fromUtf8("host")).toString().trimmed();
    profile.sni = obj.value(QString::fromUtf8("sni")).toString().trimmed();
    profile.alpn = obj.value(QString::fromUtf8("alpn")).toString().trimmed();
    profile.flow = obj.value(QString::fromUtf8("flow")).toString().trimmed();

    profile.fingerprint = obj.value(QString::fromUtf8("fp")).toString().trimmed();
    profile.publicKey = obj.value(QString::fromUtf8("pbk")).toString().trimmed();
    profile.shortId = obj.value(QString::fromUtf8("sid")).toString().trimmed();
    profile.spiderX = obj.value(QString::fromUtf8("spx")).toString().trimmed();

    profile.serviceName = obj.value(QString::fromUtf8("serviceName")).toString().trimmed();
    profile.xhttpMode = obj.value(QString::fromUtf8("mode")).toString().trimmed().toLower();
    if (profile.network == QString::fromUtf8("xhttp") && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = QString::fromUtf8("auto");
    }
    profile.xhttpExtra = obj.value(QString::fromUtf8("extra")).toObject();
    const QString allowInsecure = obj.value(QString::fromUtf8("allowInsecure")).toString().trimmed().toLower();
    profile.allowInsecure = (allowInsecure == QString::fromUtf8("1") || allowInsecure == QString::fromUtf8("true"));

    profile.originalLink = rawLink;
    profile.extra = obj;

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("VMESS link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseVless(const QString& rawLink, QString *errorMessage)
{
    const QUrl url(rawLink);
    if (!url.isValid()) {
        setError(errorMessage, QString::fromUtf8("VLESS link is not a valid URL."));
        return std::nullopt;
    }

    const QUrlQuery query(url);

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("vless");
    profile.name = QUrl::fromPercentEncoding(url.fragment().toUtf8()).trimmed();

    profile.userId = url.userName().trimmed();
    profile.address = url.host().trimmed();
    const int parsedPort = url.port(-1);
    if (parsedPort == -1) {
        profile.port = 443;
    } else if (parsedPort > 0 && parsedPort <= 65535) {
        profile.port = static_cast<quint16>(parsedPort);
    } else {
        setError(errorMessage, QString::fromUtf8("VLESS link has an invalid port."));
        return std::nullopt;
    }

    profile.network = query.queryItemValue(QString::fromUtf8("type")).trimmed().toLower();
    if (profile.network.isEmpty()) {
        profile.network = QString::fromUtf8("tcp");
    }

    profile.security = query.queryItemValue(QString::fromUtf8("security")).trimmed().toLower();
    if (profile.security.isEmpty()) {
        profile.security = QString::fromUtf8("none");
    }

    profile.encryption = query.queryItemValue(QString::fromUtf8("encryption")).trimmed().toLower();
    if (profile.encryption.isEmpty()) {
        profile.encryption = QString::fromUtf8("none");
    }

    profile.flow = query.queryItemValue(QString::fromUtf8("flow")).trimmed();

    profile.path = query.queryItemValue(QString::fromUtf8("path"));
    if (profile.network == QString::fromUtf8("ws")
        || profile.network == QString::fromUtf8("xhttp")) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = query.queryItemValue(QString::fromUtf8("headerType")).trimmed().toLower();

    profile.hostHeader = query.queryItemValue(QString::fromUtf8("host")).trimmed();
    profile.serviceName = query.queryItemValue(QString::fromUtf8("serviceName")).trimmed();
    profile.xhttpMode = query.queryItemValue(QString::fromUtf8("mode")).trimmed().toLower();
    if (profile.network == QString::fromUtf8("xhttp") && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = QString::fromUtf8("auto");
    }

    const QString extraValue = query.queryItemValue(QString::fromUtf8("extra"));
    if (!extraValue.trimmed().isEmpty()) {
        const std::optional<QJsonObject> xhttpExtra = parseJsonObjectText(extraValue);
        if (!xhttpExtra.has_value()) {
            setError(errorMessage, QString::fromUtf8("VLESS link has invalid XHTTP extra JSON."));
            return std::nullopt;
        }
        profile.xhttpExtra = *xhttpExtra;
    }

    profile.sni = query.queryItemValue(QString::fromUtf8("sni")).trimmed();
    if (profile.sni.isEmpty()) {
        profile.sni = query.queryItemValue(QString::fromUtf8("serverName")).trimmed();
    }

    profile.alpn = query.queryItemValue(QString::fromUtf8("alpn")).trimmed();
    profile.fingerprint = query.queryItemValue(QString::fromUtf8("fp")).trimmed();
    profile.publicKey = query.queryItemValue(QString::fromUtf8("pbk")).trimmed();
    profile.shortId = query.queryItemValue(QString::fromUtf8("sid")).trimmed();
    profile.spiderX = query.queryItemValue(QString::fromUtf8("spx")).trimmed();

    QString allowInsecure = query.queryItemValue(QString::fromUtf8("allowInsecure")).trimmed().toLower();
    if (allowInsecure.isEmpty()) {
        allowInsecure = query.queryItemValue(QString::fromUtf8("insecure")).trimmed().toLower();
    }
    profile.allowInsecure = (allowInsecure == QString::fromUtf8("1") || allowInsecure == QString::fromUtf8("true"));

    profile.originalLink = rawLink;

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("VLESS link is missing required fields."));
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

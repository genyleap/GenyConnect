module;
#include <QJsonDocument>
#include <QJsonObject>
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
    if (path.trimmed().isEmpty()) {
        return QStringLiteral("/");
    }

    if (path.startsWith('/')) {
        return path;
    }

    return QStringLiteral("/") + path;
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
    profile.port = static_cast<quint16>(obj.value(QStringLiteral("port")).toString().toInt());
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
    if (profile.network == QStringLiteral("ws")) {
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
    profile.port = static_cast<quint16>(url.port(443));

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
    if (profile.network == QStringLiteral("ws")) {
        profile.path = normalizePath(profile.path);
    }
    profile.headerType = query.queryItemValue(QStringLiteral("headerType")).trimmed().toLower();

    profile.hostHeader = query.queryItemValue(QStringLiteral("host")).trimmed();
    profile.serviceName = query.queryItemValue(QStringLiteral("serviceName")).trimmed();

    profile.sni = query.queryItemValue(QStringLiteral("sni")).trimmed();
    if (profile.sni.isEmpty()) {
        profile.sni = query.queryItemValue(QStringLiteral("serverName")).trimmed();
    }

    profile.alpn = query.queryItemValue(QStringLiteral("alpn")).trimmed();
    profile.fingerprint = query.queryItemValue(QStringLiteral("fp")).trimmed();
    profile.publicKey = query.queryItemValue(QStringLiteral("pbk")).trimmed();
    profile.shortId = query.queryItemValue(QStringLiteral("sid")).trimmed();
    profile.spiderX = query.queryItemValue(QStringLiteral("spx")).trimmed();

    const QString allowInsecure = query.queryItemValue(QStringLiteral("allowInsecure")).trimmed().toLower();
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

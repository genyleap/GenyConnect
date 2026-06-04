module;
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QMap>
#include <QRegularExpression>
#include <QUrl>
#include <QUrlQuery>
#include <QUuid>
#include <QtGlobal>

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

QString normalizeTransportNetwork(const QString& value)
{
    const QString network = value.trimmed().toLower();
    if (network == QString::fromUtf8("splithttp")
        || network == QString::fromUtf8("http")) {
        return QString::fromUtf8("xhttp");
    }
    if (network == QString::fromUtf8("httpupgrade")) {
        return QString::fromUtf8("ws");
    }
    return network;
}

QString firstHostToken(const QString& hostHeader)
{
    const QString trimmed = hostHeader.trimmed();
    if (trimmed.isEmpty()) {
        return QString();
    }
    const int commaIndex = trimmed.indexOf(',');
    if (commaIndex > 0) {
        return trimmed.left(commaIndex).trimmed();
    }
    return trimmed;
}

QString queryValueInsensitive(const QUrlQuery& query, const QString& key)
{
    const auto items = query.queryItems(QUrl::FullyDecoded);
    for (const auto& item : items) {
        if (item.first.compare(key, Qt::CaseInsensitive) == 0) {
            return item.second.trimmed();
        }
    }
    return QString();
}

QStringList splitCsvTokens(const QString& rawValue)
{
    QStringList out;
    const QString trimmed = rawValue.trimmed();
    if (trimmed.isEmpty()) {
        return out;
    }

    const QStringList tokens = trimmed.split(',', Qt::SkipEmptyParts);
    for (const QString& token : tokens) {
        const QString clean = token.trimmed();
        if (!clean.isEmpty()) {
            out.append(clean);
        }
    }
    return out;
}

QString decodePercentPreservingPlus(const QString& value)
{
    QByteArray raw = value.toUtf8();
    raw.replace('+', "%2B");
    return QUrl::fromPercentEncoding(raw).trimmed();
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

std::optional<quint16> parsePortString(const QString& value)
{
    bool ok = false;
    const int parsed = value.trimmed().toInt(&ok);
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

QByteArray decodeFlexibleBase64Bytes(const QString& value)
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

bool parseBoolToken(const QString& value)
{
    const QString lowered = value.trimmed().toLower();
    return lowered == QString::fromUtf8("1")
        || lowered == QString::fromUtf8("true")
        || lowered == QString::fromUtf8("yes")
        || lowered == QString::fromUtf8("on");
}

QString jsonValueTextInsensitive(const QJsonObject& object, const QStringList& keys)
{
    for (auto it = object.constBegin(); it != object.constEnd(); ++it) {
        for (const QString& key : keys) {
            if (it.key().compare(key, Qt::CaseInsensitive) != 0) {
                continue;
            }
            if (it.value().isBool()) {
                return it.value().toBool() ? QString::fromUtf8("true") : QString::fromUtf8("false");
            }
            if (it.value().isDouble()) {
                return QString::number(it.value().toInt());
            }
            if (it.value().isArray()) {
                QStringList values;
                const QJsonArray array = it.value().toArray();
                values.reserve(array.size());
                for (const QJsonValue& value : array) {
                    const QString token = value.toString().trimmed();
                    if (!token.isEmpty()) {
                        values.append(token);
                    }
                }
                return values.join(',');
            }
            return it.value().toString().trimmed();
        }
    }
    return QString();
}

QStringList certificatePinsFromValue(const QString& rawValue)
{
    QStringList out;
    const QStringList tokens = rawValue.split(QRegularExpression(QString::fromUtf8("[,;\\s]+")), Qt::SkipEmptyParts);
    out.reserve(tokens.size());
    for (const QString& token : tokens) {
        const QString clean = token.trimmed();
        if (!clean.isEmpty()) {
            out.append(clean);
        }
    }
    out.removeDuplicates();
    return out;
}

QString firstLegacyInsecureValue(const QUrlQuery& query)
{
    const QStringList keys {
        QString::fromUtf8("allowInsecure"),
        QString::fromUtf8("insecure"),
        QString::fromUtf8("allow_insecure"),
        QString::fromUtf8("tlsAllowInsecure"),
        QString::fromUtf8("skipCertVerify"),
        QString::fromUtf8("skipCertificateVerify")
    };
    for (const QString& key : keys) {
        const QString value = queryValueInsensitive(query, key);
        if (!value.trimmed().isEmpty()) {
            return value.trimmed();
        }
    }
    return QString();
}

QString firstPinnedCertValue(const QUrlQuery& query)
{
    const QStringList keys {
        QString::fromUtf8("pinnedPeerCertSha256"),
        QString::fromUtf8("pinnedPeerCertificateChainSha256"),
        QString::fromUtf8("peerCertSha256"),
        QString::fromUtf8("certSha256")
    };
    for (const QString& key : keys) {
        const QString value = queryValueInsensitive(query, key);
        if (!value.trimmed().isEmpty()) {
            return value.trimmed();
        }
    }
    return QString();
}

bool isSupportedVlessEncryptionToken(const QString& value)
{
    const QString token = value.trimmed().toLower();
    if (token.isEmpty()) {
        return false;
    }

    if (token == QString::fromUtf8("none")
        || token == QString::fromUtf8("zero")
        || token == QString::fromUtf8("auto")) {
        return true;
    }

    if (token.startsWith(QString::fromUtf8("vlessenc"))) {
        return true;
    }

    static const QRegularExpression safePattern(
        QString::fromUtf8("^[a-z0-9][a-z0-9._:+-]{1,127}$"));
    return safePattern.match(token).hasMatch();
}

bool isSupportedVlessEncryptionValue(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty()) {
        return false;
    }

    const QStringList tokens = trimmed.split(',', Qt::SkipEmptyParts);
    if (tokens.isEmpty()) {
        return false;
    }

    for (const QString& token : tokens) {
        if (!isSupportedVlessEncryptionToken(token)) {
            return false;
        }
    }
    return true;
}

bool looksLikeWireguardConfig(const QString& value)
{
    const QString lowered = value.toLower();
    return lowered.contains(QString::fromUtf8("[interface]"))
        && lowered.contains(QString::fromUtf8("[peer]"))
        && lowered.contains(QString::fromUtf8("privatekey"))
        && lowered.contains(QString::fromUtf8("publickey"));
}

bool parseEndpointHostPort(QString endpoint, QString *hostOut, quint16 *portOut)
{
    if (!hostOut || !portOut) {
        return false;
    }

    endpoint = endpoint.trimmed();
    if (endpoint.isEmpty()) {
        return false;
    }

    if (endpoint.startsWith('[')) {
        const int closeBracket = endpoint.indexOf(']');
        if (closeBracket <= 1 || closeBracket + 2 > endpoint.size() || endpoint.at(closeBracket + 1) != ':') {
            return false;
        }
        const QString host = endpoint.mid(1, closeBracket - 1).trimmed();
        const std::optional<quint16> port = parsePortString(endpoint.mid(closeBracket + 2));
        if (host.isEmpty() || !port.has_value()) {
            return false;
        }
        *hostOut = host;
        *portOut = *port;
        return true;
    }

    const int lastColon = endpoint.lastIndexOf(':');
    if (lastColon <= 0 || lastColon == endpoint.size() - 1) {
        return false;
    }

    const QString host = endpoint.left(lastColon).trimmed();
    const std::optional<quint16> port = parsePortString(endpoint.mid(lastColon + 1));
    if (host.isEmpty() || !port.has_value()) {
        return false;
    }

    *hostOut = host;
    *portOut = *port;
    return true;
}

void applyTransportQueryFields(ServerProfile *profile, const QUrlQuery& query, const QString& defaultSecurity)
{
    if (!profile) {
        return;
    }

    profile->network = normalizeTransportNetwork(query.queryItemValue(QString::fromUtf8("type")));
    if (profile->network.isEmpty()) {
        profile->network = QString::fromUtf8("tcp");
    }

    profile->security = query.queryItemValue(QString::fromUtf8("security")).trimmed().toLower();
    if (profile->security.isEmpty()) {
        profile->security = defaultSecurity;
    }

    profile->flow = query.queryItemValue(QString::fromUtf8("flow")).trimmed();

    profile->path = query.queryItemValue(QString::fromUtf8("path"));
    if (profile->network == QString::fromUtf8("ws")
        || profile->network == QString::fromUtf8("xhttp")) {
        profile->path = normalizePath(profile->path);
    }
    profile->headerType = query.queryItemValue(QString::fromUtf8("headerType")).trimmed().toLower();

    profile->hostHeader = query.queryItemValue(QString::fromUtf8("host")).trimmed();
    profile->serviceName = query.queryItemValue(QString::fromUtf8("serviceName")).trimmed();
    profile->xhttpMode = query.queryItemValue(QString::fromUtf8("mode")).trimmed().toLower();
    if (profile->network == QString::fromUtf8("xhttp") && profile->xhttpMode.isEmpty()) {
        profile->xhttpMode = QString::fromUtf8("auto");
    }

    const QString extraValue = query.queryItemValue(QString::fromUtf8("extra"));
    if (!extraValue.trimmed().isEmpty()) {
        const std::optional<QJsonObject> xhttpExtra = parseJsonObjectText(extraValue);
        if (xhttpExtra.has_value()) {
            profile->xhttpExtra = *xhttpExtra;
        }
    }

    profile->sni = query.queryItemValue(QString::fromUtf8("sni")).trimmed();
    if (profile->sni.isEmpty()) {
        profile->sni = query.queryItemValue(QString::fromUtf8("serverName")).trimmed();
    }
    if (profile->sni.isEmpty()
        && (profile->security == QString::fromUtf8("tls")
            || profile->security == QString::fromUtf8("reality"))) {
        profile->sni = firstHostToken(profile->hostHeader);
    }
    if (profile->sni.isEmpty() && profile->security == QString::fromUtf8("tls")) {
        profile->sni = profile->address.trimmed();
    }

    profile->alpn = query.queryItemValue(QString::fromUtf8("alpn")).trimmed();
    profile->fingerprint = query.queryItemValue(QString::fromUtf8("fp")).trimmed();
    profile->publicKey = query.queryItemValue(QString::fromUtf8("pbk")).trimmed();
    profile->shortId = query.queryItemValue(QString::fromUtf8("sid")).trimmed();
    profile->spiderX = query.queryItemValue(QString::fromUtf8("spx")).trimmed();

    profile->allowInsecure = parseBoolToken(firstLegacyInsecureValue(query));
    profile->pinnedPeerCertSha256 = certificatePinsFromValue(firstPinnedCertValue(query));
}

bool decodeShadowsocksCredentials(const QString& rawCredential, QString *methodOut, QString *passwordOut)
{
    if (!methodOut || !passwordOut) {
        return false;
    }

    const QString direct = decodePercentPreservingPlus(rawCredential);
    int split = direct.indexOf(':');
    if (split > 0) {
        *methodOut = direct.left(split).trimmed();
        *passwordOut = direct.mid(split + 1).trimmed();
        return !methodOut->isEmpty() && !passwordOut->isEmpty();
    }

    const QByteArray decoded = decodeFlexibleBase64Bytes(rawCredential.trimmed());
    if (decoded.isEmpty()) {
        return false;
    }
    const QString decodedText = QString::fromUtf8(decoded).trimmed();
    split = decodedText.indexOf(':');
    if (split <= 0) {
        return false;
    }

    *methodOut = decodedText.left(split).trimmed();
    *passwordOut = decodedText.mid(split + 1).trimmed();
    return !methodOut->isEmpty() && !passwordOut->isEmpty();
}

QMap<QString, QString> parseSemicolonPairs(const QString& raw)
{
    QMap<QString, QString> out;
    const QStringList tokens = raw.split(';', Qt::SkipEmptyParts);
    for (const QString& token : tokens) {
        const QString trimmed = token.trimmed();
        if (trimmed.isEmpty()) {
            continue;
        }
        const int sep = trimmed.indexOf('=');
        if (sep <= 0) {
            out.insert(trimmed.toLower(), QString());
            continue;
        }
        const QString key = trimmed.left(sep).trimmed().toLower();
        const QString value = trimmed.mid(sep + 1).trimmed();
        if (!key.isEmpty()) {
            out.insert(key, value);
        }
    }
    return out;
}
} // namespace

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

    if (link.startsWith(QString::fromUtf8("trojan://"), Qt::CaseInsensitive)) {
        return parseTrojan(link, errorMessage);
    }

    if (link.startsWith(QString::fromUtf8("ss://"), Qt::CaseInsensitive)) {
        return parseShadowsocks(link, errorMessage);
    }

    if (link.startsWith(QString::fromUtf8("wireguard://"), Qt::CaseInsensitive)
        || link.startsWith(QString::fromUtf8("wg://"), Qt::CaseInsensitive)) {
        return parseWireguard(link, errorMessage);
    }

    if (looksLikeWireguardConfig(link)) {
        return parseWireguardConfig(link, errorMessage);
    }

    setError(errorMessage,
             QString::fromUtf8("Unsupported profile format. Supported: VMESS, VLESS, Trojan, Shadowsocks, WireGuard URI/config."));
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

    profile.network = normalizeTransportNetwork(obj.value(QString::fromUtf8("net")).toString());
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
    if (profile.sni.isEmpty()) {
        profile.sni = obj.value(QString::fromUtf8("serverName")).toString().trimmed();
    }
    profile.alpn = obj.value(QString::fromUtf8("alpn")).toString().trimmed();
    profile.flow = obj.value(QString::fromUtf8("flow")).toString().trimmed();

    profile.fingerprint = obj.value(QString::fromUtf8("fp")).toString().trimmed();
    profile.publicKey = obj.value(QString::fromUtf8("pbk")).toString().trimmed();
    profile.shortId = obj.value(QString::fromUtf8("sid")).toString().trimmed();
    profile.spiderX = obj.value(QString::fromUtf8("spx")).toString().trimmed();

    profile.serviceName = obj.value(QString::fromUtf8("serviceName")).toString().trimmed();
    if (profile.sni.isEmpty()
        && (profile.security == QString::fromUtf8("tls")
            || profile.security == QString::fromUtf8("reality"))) {
        profile.sni = firstHostToken(profile.hostHeader);
    }
    profile.xhttpMode = obj.value(QString::fromUtf8("mode")).toString().trimmed().toLower();
    if (profile.network == QString::fromUtf8("xhttp") && profile.xhttpMode.isEmpty()) {
        profile.xhttpMode = QString::fromUtf8("auto");
    }
    profile.xhttpExtra = obj.value(QString::fromUtf8("extra")).toObject();
    profile.allowInsecure = parseBoolToken(jsonValueTextInsensitive(obj, {
        QString::fromUtf8("allowInsecure"),
        QString::fromUtf8("insecure"),
        QString::fromUtf8("allow_insecure"),
        QString::fromUtf8("tlsAllowInsecure"),
        QString::fromUtf8("skipCertVerify"),
        QString::fromUtf8("skipCertificateVerify")
    }));
    profile.pinnedPeerCertSha256 = certificatePinsFromValue(jsonValueTextInsensitive(obj, {
        QString::fromUtf8("pinnedPeerCertSha256"),
        QString::fromUtf8("pinnedPeerCertificateChainSha256"),
        QString::fromUtf8("peerCertSha256"),
        QString::fromUtf8("certSha256")
    }));

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

    profile.encryption = query.queryItemValue(QString::fromUtf8("encryption")).trimmed().toLower();
    if (profile.encryption.isEmpty()) {
        profile.encryption = QString::fromUtf8("none");
    }
    if (!isSupportedVlessEncryptionValue(profile.encryption)) {
        setError(errorMessage,
                 QString::fromUtf8("Unsupported VLESS encryption value '%1'.")
                     .arg(profile.encryption));
        return std::nullopt;
    }

    applyTransportQueryFields(&profile, query, QString::fromUtf8("none"));

    const QString security = profile.security.trimmed().toLower();
    if (security != QString::fromUtf8("none")
        && security != QString::fromUtf8("tls")
        && security != QString::fromUtf8("reality")) {
        setError(errorMessage,
                 QString::fromUtf8("Unsupported VLESS security value '%1'.")
                     .arg(profile.security));
        return std::nullopt;
    }
    if (security == QString::fromUtf8("reality") && profile.publicKey.trimmed().isEmpty()) {
        setError(errorMessage, QString::fromUtf8("VLESS REALITY requires a public key (pbk)."));
        return std::nullopt;
    }
    if ((security == QString::fromUtf8("tls") || security == QString::fromUtf8("reality"))
        && profile.sni.trimmed().isEmpty()) {
        setError(errorMessage, QString::fromUtf8("VLESS TLS/REALITY requires SNI/serverName/host."));
        return std::nullopt;
    }
    if (!profile.flow.trimmed().isEmpty()
        && security != QString::fromUtf8("tls")
        && security != QString::fromUtf8("reality")) {
        setError(errorMessage, QString::fromUtf8("VLESS flow requires TLS or REALITY security."));
        return std::nullopt;
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

    profile.originalLink = rawLink;

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("VLESS link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseTrojan(const QString& rawLink, QString *errorMessage)
{
    const QUrl url(rawLink);
    if (!url.isValid()) {
        setError(errorMessage, QString::fromUtf8("Trojan link is not a valid URL."));
        return std::nullopt;
    }

    const QUrlQuery query(url);

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("trojan");
    profile.name = QUrl::fromPercentEncoding(url.fragment().toUtf8()).trimmed();
    profile.userId = url.userName().trimmed(); // password
    profile.address = url.host().trimmed();

    const int parsedPort = url.port(-1);
    if (parsedPort == -1) {
        profile.port = 443;
    } else if (parsedPort > 0 && parsedPort <= 65535) {
        profile.port = static_cast<quint16>(parsedPort);
    } else {
        setError(errorMessage, QString::fromUtf8("Trojan link has an invalid port."));
        return std::nullopt;
    }

    profile.encryption = QString::fromUtf8("none");
    applyTransportQueryFields(&profile, query, QString::fromUtf8("tls"));

    profile.originalLink = rawLink;

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("Trojan link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseShadowsocks(const QString& rawLink, QString *errorMessage)
{
    QString payload = rawLink.mid(QString::fromUtf8("ss://").size()).trimmed();
    QString profileName;

    const int fragmentIdx = payload.indexOf('#');
    if (fragmentIdx >= 0) {
        profileName = QUrl::fromPercentEncoding(payload.mid(fragmentIdx + 1).toUtf8()).trimmed();
        payload = payload.left(fragmentIdx);
    }

    QString queryText;
    const int queryIdx = payload.indexOf('?');
    if (queryIdx >= 0) {
        queryText = payload.mid(queryIdx + 1);
        payload = payload.left(queryIdx);
    }

    QString credentialsPart;
    QString endpointPart;

    const int atIdx = payload.lastIndexOf('@');
    if (atIdx > 0 && atIdx < payload.size() - 1) {
        credentialsPart = payload.left(atIdx).trimmed();
        endpointPart = payload.mid(atIdx + 1).trimmed();
    } else {
        const QByteArray decoded = decodeFlexibleBase64(payload);
        if (decoded.isEmpty()) {
            setError(errorMessage, QString::fromUtf8("Shadowsocks payload could not be decoded."));
            return std::nullopt;
        }
        const QString decodedText = QString::fromUtf8(decoded).trimmed();
        const int decodedAt = decodedText.lastIndexOf('@');
        if (decodedAt <= 0 || decodedAt >= decodedText.size() - 1) {
            setError(errorMessage, QString::fromUtf8("Shadowsocks payload is not in method:password@host:port format."));
            return std::nullopt;
        }
        credentialsPart = decodedText.left(decodedAt).trimmed();
        endpointPart = decodedText.mid(decodedAt + 1).trimmed();
    }

    QString method;
    QString password;
    if (!decodeShadowsocksCredentials(credentialsPart, &method, &password)) {
        setError(errorMessage, QString::fromUtf8("Shadowsocks credentials are invalid."));
        return std::nullopt;
    }

    const QUrl endpointUrl(QString::fromUtf8("ss://") + endpointPart);
    if (!endpointUrl.isValid()) {
        setError(errorMessage, QString::fromUtf8("Shadowsocks endpoint is not a valid host:port."));
        return std::nullopt;
    }

    const QString host = endpointUrl.host().trimmed();
    const int parsedPort = endpointUrl.port(-1);
    if (host.isEmpty() || parsedPort <= 0 || parsedPort > 65535) {
        setError(errorMessage, QString::fromUtf8("Shadowsocks endpoint has an invalid host or port."));
        return std::nullopt;
    }

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("shadowsocks");
    profile.name = profileName;
    profile.address = host;
    profile.port = static_cast<quint16>(parsedPort);
    profile.userId = password;
    profile.encryption = method;
    profile.network = QString::fromUtf8("tcp");
    profile.security = QString::fromUtf8("none");

    const QUrlQuery query(queryText);
    profile.allowInsecure = parseBoolToken(firstLegacyInsecureValue(query));
    profile.pinnedPeerCertSha256 = certificatePinsFromValue(firstPinnedCertValue(query));

    const QString pluginRaw = queryValueInsensitive(query, QString::fromUtf8("plugin"));
    if (!pluginRaw.isEmpty()) {
        profile.extra.insert(QString::fromUtf8("plugin"), pluginRaw);
        const QStringList pluginTokens = pluginRaw.split(';', Qt::SkipEmptyParts);
        if (!pluginTokens.isEmpty()) {
            const QString pluginName = pluginTokens.first().trimmed().toLower();
            const QMap<QString, QString> pluginOptions = parseSemicolonPairs(pluginRaw);

            if (pluginName.contains(QString::fromUtf8("v2ray-plugin"))
                || pluginName.contains(QString::fromUtf8("xray-plugin"))) {
                QString mode = pluginOptions.value(QString::fromUtf8("mode")).trimmed().toLower();
                if (mode == QString::fromUtf8("websocket") || mode == QString::fromUtf8("ws")) {
                    profile.network = QString::fromUtf8("ws");
                    profile.path = normalizePath(pluginOptions.value(QString::fromUtf8("path")));
                    profile.hostHeader = pluginOptions.value(QString::fromUtf8("host")).trimmed();
                } else if (mode == QString::fromUtf8("grpc")) {
                    profile.network = QString::fromUtf8("grpc");
                    profile.serviceName = pluginOptions.value(QString::fromUtf8("serviceName")).trimmed();
                }

                if (pluginOptions.contains(QString::fromUtf8("tls"))
                    || pluginOptions.value(QString::fromUtf8("security")).trimmed().compare(QString::fromUtf8("tls"), Qt::CaseInsensitive) == 0) {
                    profile.security = QString::fromUtf8("tls");
                }

                profile.sni = pluginOptions.value(QString::fromUtf8("sni")).trimmed();
            }
        }
    }

    profile.originalLink = rawLink;

    if (!profile.isValid() || profile.encryption.trimmed().isEmpty()) {
        setError(errorMessage, QString::fromUtf8("Shadowsocks link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseWireguard(const QString& rawLink, QString *errorMessage)
{
    QString normalized = rawLink.trimmed();
    if (normalized.startsWith(QString::fromUtf8("wg://"), Qt::CaseInsensitive)) {
        normalized = QString::fromUtf8("wireguard://") + normalized.mid(QString::fromUtf8("wg://").size());
    }

    const QUrl url(normalized);
    if (!url.isValid()) {
        setError(errorMessage, QString::fromUtf8("WireGuard link is not a valid URL."));
        return std::nullopt;
    }

    const QUrlQuery query(url);

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("wireguard");
    profile.network = QString::fromUtf8("wireguard");
    profile.security = QString::fromUtf8("none");
    profile.encryption = QString::fromUtf8("none");
    profile.name = QUrl::fromPercentEncoding(url.fragment().toUtf8()).trimmed();

    QString host = url.host().trimmed();
    int parsedPort = url.port(-1);

    if (host.isEmpty() || parsedPort <= 0 || parsedPort > 65535) {
        QString endpoint = queryValueInsensitive(query, QString::fromUtf8("endpoint"));
        if (endpoint.isEmpty()) {
            endpoint = queryValueInsensitive(query, QString::fromUtf8("server"));
        }
        quint16 endpointPort = 0;
        if (!parseEndpointHostPort(endpoint, &host, &endpointPort)) {
            setError(errorMessage, QString::fromUtf8("WireGuard link has an invalid endpoint."));
            return std::nullopt;
        }
        parsedPort = static_cast<int>(endpointPort);
    }

    profile.address = host;
    profile.port = static_cast<quint16>(parsedPort);

    profile.wgSecretKey = url.userName().trimmed();
    if (profile.wgSecretKey.isEmpty()) {
        profile.wgSecretKey = queryValueInsensitive(query, QString::fromUtf8("privatekey"));
    }
    if (profile.wgSecretKey.isEmpty()) {
        profile.wgSecretKey = queryValueInsensitive(query, QString::fromUtf8("secretkey"));
    }

    profile.wgPublicKey = queryValueInsensitive(query, QString::fromUtf8("publickey"));
    profile.wgPresharedKey = queryValueInsensitive(query, QString::fromUtf8("presharedkey"));

    QString addressValue = queryValueInsensitive(query, QString::fromUtf8("address"));
    if (addressValue.isEmpty()) {
        addressValue = queryValueInsensitive(query, QString::fromUtf8("addresses"));
    }
    if (addressValue.isEmpty()) {
        addressValue = queryValueInsensitive(query, QString::fromUtf8("clientip"));
    }
    profile.wgAddress = splitCsvTokens(addressValue);

    QString allowedIps = queryValueInsensitive(query, QString::fromUtf8("allowedips"));
    if (allowedIps.isEmpty()) {
        allowedIps = queryValueInsensitive(query, QString::fromUtf8("allowedip"));
    }
    profile.wgAllowedIPs = splitCsvTokens(allowedIps);

    profile.wgReserved = splitCsvTokens(queryValueInsensitive(query, QString::fromUtf8("reserved")));

    QString dnsValue = queryValueInsensitive(query, QString::fromUtf8("dns"));
    if (dnsValue.isEmpty()) {
        dnsValue = queryValueInsensitive(query, QString::fromUtf8("dnss"));
    }
    profile.wgDns = splitCsvTokens(dnsValue);

    bool mtuOk = false;
    const int parsedMtu = queryValueInsensitive(query, QString::fromUtf8("mtu")).toInt(&mtuOk);
    profile.wgMtu = (mtuOk && parsedMtu > 0) ? parsedMtu : 0;

    bool keepaliveOk = false;
    int parsedKeepalive = queryValueInsensitive(query, QString::fromUtf8("persistentkeepalive")).toInt(&keepaliveOk);
    if (!keepaliveOk) {
        parsedKeepalive = queryValueInsensitive(query, QString::fromUtf8("keepalive")).toInt(&keepaliveOk);
    }
    profile.wgPersistentKeepalive = (keepaliveOk && parsedKeepalive >= 0) ? parsedKeepalive : 0;

    profile.originalLink = rawLink;
    if (!profile.wgDns.isEmpty()) {
        profile.extra.insert(QString::fromUtf8("wireguardDns"), QJsonArray::fromStringList(profile.wgDns));
    }

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("WireGuard link is missing required fields."));
        return std::nullopt;
    }

    return profile;
}

std::optional<ServerProfile> LinkParser::parseWireguardConfig(const QString& rawConfig, QString *errorMessage)
{
    enum class Section {
        None,
        Interface,
        Peer
    };

    QMap<QString, QString> interfaceValues;
    QMap<QString, QString> peerValues;
    Section section = Section::None;

    const QStringList lines = rawConfig.split(QRegularExpression(QString::fromUtf8("[\r\n]+")), Qt::SkipEmptyParts);
    for (QString line : lines) {
        line = line.trimmed();
        if (line.isEmpty()) {
            continue;
        }

        if (line.startsWith('#') || line.startsWith(';')) {
            continue;
        }

        if (line.startsWith('[') && line.endsWith(']')) {
            const QString header = line.mid(1, line.size() - 2).trimmed().toLower();
            if (header == QString::fromUtf8("interface")) {
                section = Section::Interface;
            } else if (header == QString::fromUtf8("peer")) {
                section = Section::Peer;
            } else {
                section = Section::None;
            }
            continue;
        }

        const int sep = line.indexOf('=');
        if (sep <= 0) {
            continue;
        }

        const QString key = line.left(sep).trimmed().toLower();
        const QString value = line.mid(sep + 1).trimmed();
        if (key.isEmpty() || value.isEmpty()) {
            continue;
        }

        if (section == Section::Interface) {
            interfaceValues.insert(key, value);
        } else if (section == Section::Peer) {
            if (!peerValues.contains(key)) {
                peerValues.insert(key, value);
            }
        }
    }

    if (!interfaceValues.contains(QString::fromUtf8("privatekey"))
        || !peerValues.contains(QString::fromUtf8("publickey"))
        || !peerValues.contains(QString::fromUtf8("endpoint"))) {
        setError(errorMessage, QString::fromUtf8("WireGuard config must include Interface.PrivateKey, Peer.PublicKey, and Peer.Endpoint."));
        return std::nullopt;
    }

    QString host;
    quint16 port = 0;
    if (!parseEndpointHostPort(peerValues.value(QString::fromUtf8("endpoint")), &host, &port)) {
        setError(errorMessage, QString::fromUtf8("WireGuard Peer.Endpoint is invalid."));
        return std::nullopt;
    }

    ServerProfile profile;
    profile.id = createProfileId();
    profile.protocol = QString::fromUtf8("wireguard");
    profile.network = QString::fromUtf8("wireguard");
    profile.security = QString::fromUtf8("none");
    profile.encryption = QString::fromUtf8("none");
    profile.address = host;
    profile.port = port;
    profile.wgSecretKey = interfaceValues.value(QString::fromUtf8("privatekey")).trimmed();
    profile.wgPublicKey = peerValues.value(QString::fromUtf8("publickey")).trimmed();
    profile.wgPresharedKey = peerValues.value(QString::fromUtf8("presharedkey")).trimmed();
    profile.wgAddress = splitCsvTokens(interfaceValues.value(QString::fromUtf8("address")));
    profile.wgAllowedIPs = splitCsvTokens(peerValues.value(QString::fromUtf8("allowedips")));
    profile.wgDns = splitCsvTokens(interfaceValues.value(QString::fromUtf8("dns")));
    profile.wgReserved = splitCsvTokens(interfaceValues.value(QString::fromUtf8("reserved")));

    bool mtuOk = false;
    const int parsedMtu = interfaceValues.value(QString::fromUtf8("mtu")).toInt(&mtuOk);
    profile.wgMtu = (mtuOk && parsedMtu > 0) ? parsedMtu : 0;

    bool keepaliveOk = false;
    const int parsedKeepalive = peerValues.value(QString::fromUtf8("persistentkeepalive")).toInt(&keepaliveOk);
    profile.wgPersistentKeepalive = (keepaliveOk && parsedKeepalive >= 0) ? parsedKeepalive : 0;

    profile.name = interfaceValues.value(QString::fromUtf8("name")).trimmed();
    if (profile.name.isEmpty()) {
        profile.name = QString::fromUtf8("WireGuard %1").arg(profile.address);
    }

    profile.originalLink = rawConfig;
    if (!profile.wgDns.isEmpty()) {
        profile.extra.insert(QString::fromUtf8("wireguardDns"), QJsonArray::fromStringList(profile.wgDns));
    }

    if (!profile.isValid()) {
        setError(errorMessage, QString::fromUtf8("WireGuard config is missing required fields."));
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

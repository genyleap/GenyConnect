module;
#include <QAbstractSocket>
#include <QHostAddress>
#include <QRegularExpression>
#include <QSet>
#include <QStringList>
#include <QVariantMap>

module genyconnect.backend.routingruleservice;

QVariantMap RoutingRuleService::validate(
    const QString& targetType,
    const QString& targetValue,
    const QString& action,
    const QString& profileId,
    const ValidationContext& context)
{
    QVariantMap result;
    QString normalizedType = targetType.trimmed().toLower();
    QString normalizedAction = action.trimmed().toLower();
    QString normalizedValue = targetValue.trimmed();
    QString normalizedProfileId = profileId.trimmed();

    if (normalizedProfileId.compare(QString::fromUtf8("all"), Qt::CaseInsensitive) == 0
        || normalizedProfileId.compare(QString::fromUtf8("all profiles"), Qt::CaseInsensitive) == 0) {
        normalizedProfileId.clear();
    }

    if (normalizedAction == QString::fromUtf8("vpn")
        || normalizedAction == QString::fromUtf8("proxy")
        || normalizedAction == QString::fromUtf8("tunnel")) {
        normalizedAction = QString::fromUtf8("proxy");
    } else if (normalizedAction == QString::fromUtf8("direct")) {
        normalizedAction = QString::fromUtf8("direct");
    } else if (normalizedAction == QString::fromUtf8("block")) {
        normalizedAction = QString::fromUtf8("block");
    } else {
        result.insert(QString::fromUtf8("ok"), false);
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Action must be VPN, Direct, or Block."));
        return result;
    }

    if (normalizedType == QString::fromUtf8("vpn")) {
        normalizedType = QString::fromUtf8("process");
    } else if (normalizedType == QString::fromUtf8("application")) {
        normalizedType = QString::fromUtf8("app");
    }

    const QSet<QString> allowedTypes = {
        QString::fromUtf8("domain"),
        QString::fromUtf8("ip"),
        QString::fromUtf8("app"),
        QString::fromUtf8("process"),
        QString::fromUtf8("protocol")
    };
    if (!allowedTypes.contains(normalizedType)) {
        result.insert(QString::fromUtf8("ok"), false);
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Target type must be Domain, IP, App, Process, or Protocol."));
        return result;
    }

    if (normalizedValue.isEmpty()) {
        result.insert(QString::fromUtf8("ok"), false);
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Target value cannot be empty."));
        return result;
    }

    if (!normalizedProfileId.isEmpty()
        && context.enforceProfileExists
        && !context.profileExists) {
        result.insert(QString::fromUtf8("ok"), false);
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Profile scope points to a missing profile."));
        return result;
    }

    QString warning;
    if (normalizedType == QString::fromUtf8("domain")) {
        const QString value = normalizedValue;
        const QString lowered = value.toLower();
        const QStringList allowedPrefixes = {
            QString::fromUtf8("full:"),
            QString::fromUtf8("domain:"),
            QString::fromUtf8("regexp:"),
            QString::fromUtf8("keyword:"),
            QString::fromUtf8("geosite:"),
            QString::fromUtf8("ext:")
        };
        bool prefixMatched = false;
        for (const QString& prefix : allowedPrefixes) {
            if (lowered.startsWith(prefix)) {
                prefixMatched = true;
                break;
            }
        }

        if (prefixMatched) {
            const int sep = value.indexOf(':');
            if (sep < 0 || value.mid(sep + 1).trimmed().isEmpty()) {
                result.insert(QString::fromUtf8("ok"), false);
                result.insert(QString::fromUtf8("error"), QString::fromUtf8("Domain rule has an empty matcher after prefix."));
                return result;
            }
            if (lowered.startsWith(QString::fromUtf8("full:"))) {
                warning = QString::fromUtf8(
                    "full: only matches that exact hostname. Use domain:example.com to include subdomains.");
            }
        } else {
            static const QRegularExpression domainPattern(
                QString::fromUtf8("^(?=.{1,253}$)(?!-)(?:[A-Za-z0-9-]{1,63}\\.)+[A-Za-z]{2,63}$"));
            if (!domainPattern.match(value).hasMatch()) {
                result.insert(QString::fromUtf8("ok"), false);
                result.insert(QString::fromUtf8("error"), QString::fromUtf8("Domain value is invalid."));
                return result;
            }
            normalizedValue = value.toLower();
        }
    } else if (normalizedType == QString::fromUtf8("ip")) {
        const QString value = normalizedValue;
        const QString lowered = value.toLower();
        if (lowered.startsWith(QString::fromUtf8("geoip:"))
            || lowered.startsWith(QString::fromUtf8("ext:"))
            || lowered.startsWith(QString::fromUtf8("ip:"))
            || lowered.startsWith(QString::fromUtf8("!geoip:"))
            || lowered.startsWith(QString::fromUtf8("!ip:"))) {
            normalizedValue = value;
        } else {
            const int slash = value.indexOf('/');
            QString ipPart = value;
            int cidrBits = -1;
            if (slash >= 0) {
                ipPart = value.left(slash).trimmed();
                bool ok = false;
                cidrBits = value.mid(slash + 1).trimmed().toInt(&ok);
                if (!ok) {
                    result.insert(QString::fromUtf8("ok"), false);
                    result.insert(QString::fromUtf8("error"), QString::fromUtf8("CIDR suffix must be a number."));
                    return result;
                }
            }

            QHostAddress ip;
            if (!ip.setAddress(ipPart)) {
                result.insert(QString::fromUtf8("ok"), false);
                result.insert(QString::fromUtf8("error"), QString::fromUtf8("IP/CIDR value is invalid."));
                return result;
            }

            if (cidrBits >= 0) {
                const bool isV6 = ip.protocol() == QAbstractSocket::IPv6Protocol;
                const int maxBits = isV6 ? 128 : 32;
                if (cidrBits < 0 || cidrBits > maxBits) {
                    result.insert(QString::fromUtf8("ok"), false);
                    result.insert(QString::fromUtf8("error"), QString::fromUtf8("CIDR prefix length is out of range."));
                    return result;
                }
                normalizedValue = QString::fromUtf8("%1/%2").arg(ip.toString(), QString::number(cidrBits));
            } else {
                normalizedValue = ip.toString();
            }
        }
    } else if (normalizedType == QString::fromUtf8("app")
               || normalizedType == QString::fromUtf8("process")) {
        if (normalizedValue.endsWith('/')) {
            warning = QString::fromUtf8("Folder-level process rules match all processes under that directory.");
        }
        if (!context.perAppCapableRuntime || context.processSupportBlocked) {
            result.insert(QString::fromUtf8("ok"), false);
            result.insert(QString::fromUtf8("error"),
                          QString::fromUtf8("App/process routing is unavailable on this platform/runtime."));
            return result;
        }
#if defined(Q_OS_WIN)
        normalizedValue.replace('\\', '/');
#endif
    } else if (normalizedType == QString::fromUtf8("protocol")) {
        const QStringList tokens = normalizedValue.split(QRegularExpression(QString::fromUtf8("[,\\s]+")), Qt::SkipEmptyParts);
        if (tokens.isEmpty()) {
            result.insert(QString::fromUtf8("ok"), false);
            result.insert(QString::fromUtf8("error"), QString::fromUtf8("Protocol value cannot be empty."));
            return result;
        }

        const QSet<QString> allowedProtocols = {
            QString::fromUtf8("tcp"),
            QString::fromUtf8("udp"),
            QString::fromUtf8("http"),
            QString::fromUtf8("tls"),
            QString::fromUtf8("quic"),
            QString::fromUtf8("bittorrent")
        };
        QStringList normalizedTokens;
        normalizedTokens.reserve(tokens.size());
        for (const QString& tokenRaw : tokens) {
            const QString token = tokenRaw.trimmed().toLower();
            if (!allowedProtocols.contains(token)) {
                result.insert(QString::fromUtf8("ok"), false);
                result.insert(QString::fromUtf8("error"),
                              QString::fromUtf8("Unsupported protocol token: %1").arg(tokenRaw.trimmed()));
                return result;
            }
            if (!normalizedTokens.contains(token)) {
                normalizedTokens.append(token);
            }
        }
        normalizedValue = normalizedTokens.join(',');
    }

    result.insert(QString::fromUtf8("ok"), true);
    result.insert(QString::fromUtf8("type"), normalizedType);
    result.insert(QString::fromUtf8("action"), normalizedAction);
    result.insert(QString::fromUtf8("value"), normalizedValue);
    result.insert(QString::fromUtf8("profileId"), normalizedProfileId);
    if (!warning.trimmed().isEmpty()) {
        result.insert(QString::fromUtf8("warning"), warning.trimmed());
    }
    return result;
}

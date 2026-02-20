/*!
 * @file        serverprofile.cppm
 * @brief       Server profile data model for GenyConnect.
 *
 * @details
 * Defines the `ServerProfile` value type used to represent imported
 * V2Ray/Xray profile data. The structure includes transport, security,
 * and metadata fields, plus JSON serialization and validation helpers.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QJsonObject>
#include <QString>
#include <QtTypes>

#include <optional>

export module genyconnect.backend.serverprofile;

/**
 * @struct ServerProfile
 * @brief Canonical connection profile used by GenyConnect.
 *
 * @details
 * Contains endpoint, protocol, transport and security data parsed from
 * supported share links or loaded from persistent storage.
 */
export struct ServerProfile {
    QString id;               //!< Stable profile identifier.
    QString name;             //!< Human-readable profile name.
    QString protocol;         //!< Outbound protocol (for example, vless/vmess).
    QString address;          //!< Remote host or IP address.
    quint16 port = 0;         //!< Remote port.

    QString userId;           //!< User UUID or account token.
    QString encryption;       //!< Encryption mode or cipher.
    QString flow;             //!< XTLS/flow setting when applicable.
    QString network;          //!< Transport network (tcp/ws/grpc/...).
    QString security;         //!< Stream security layer (tls/reality/...).

    QString sni;              //!< TLS/REALITY server name.
    QString alpn;             //!< ALPN list in plain string form.
    QString fingerprint;      //!< Client fingerprint hint.
    QString publicKey;        //!< REALITY public key.
    QString shortId;          //!< REALITY short-id.
    QString spiderX;          //!< REALITY spiderX value.

    QString path;             //!< HTTP/WS/GRPC path.
    QString hostHeader;       //!< Host override header.
    QString serviceName;      //!< gRPC service name.
    QString headerType;       //!< Header type override.

    bool allowInsecure = false; //!< Allow insecure certificate mode.

    QString originalLink;     //!< Original imported share link.
    QString groupName;        //!< Logical group/category name (for filtering).
    QString sourceName;       //!< Human-readable source/subscription name.
    QString sourceId;         //!< Stable source identifier.
    QJsonObject extra;        //!< Extensible free-form metadata.
    int lastPingMs = -1;      //!< Latest measured endpoint TCP latency in milliseconds.
    bool pingInProgress = false; //!< True while profile endpoint ping is in progress.

    /**
     * @brief Validate essential endpoint/profile fields.
     * @return True when minimum required fields are present.
     */
    bool isValid() const;

    /**
     * @brief Build a compact UI label for list usage.
     * @return Display-ready profile label.
     */
    QString displayLabel() const;

    /**
     * @brief Serialize the profile into JSON.
     * @return JSON object containing all known fields.
     */
    QJsonObject toJson() const;

    /**
     * @brief Deserialize profile data from JSON.
     * @param json Source object.
     * @return Parsed profile or empty optional on invalid input.
     */
    static std::optional<ServerProfile> fromJson(const QJsonObject& json);
};

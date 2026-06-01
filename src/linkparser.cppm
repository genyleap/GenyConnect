/*!
 * @file        linkparser.cppm
 * @brief       Parser interface for profile share links.
 *
 * @details
 * Declares parsing APIs for converting raw V2Ray/Xray/WireGuard profile inputs into
 * normalized `ServerProfile` objects. The module includes decoding helpers
 * and consistent error reporting entry points for import workflows.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QByteArray>
#include <QString>

#include <optional>

#ifndef Q_MOC_RUN
export module genyconnect.backend.linkparser;
import genyconnect.backend.serverprofile;
#endif

/**
 * @class LinkParser
 * @brief Parses share links into normalized server profiles.
 *
 * @details
 * Supports recognized VPN link/config formats and provides validation/error
 * messages for import workflows.
 */
export class LinkParser
{
public:
    /**
     * @brief Parse a raw share link.
     * @param rawLink Input link string.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parse(const QString& rawLink, QString *errorMessage = nullptr);

private:
    /**
     * @brief Parse a VMess link payload.
     * @param rawLink Input VMess link.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseVmess(const QString& rawLink, QString *errorMessage);

    /**
     * @brief Parse a VLESS link payload.
     * @param rawLink Input VLESS link.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseVless(const QString& rawLink, QString *errorMessage);

    /**
     * @brief Parse a Trojan link payload.
     * @param rawLink Input Trojan link.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseTrojan(const QString& rawLink, QString *errorMessage);

    /**
     * @brief Parse a Shadowsocks link payload.
     * @param rawLink Input Shadowsocks link.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseShadowsocks(const QString& rawLink, QString *errorMessage);

    /**
     * @brief Parse a WireGuard share URI.
     * @param rawLink Input WireGuard URI.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseWireguard(const QString& rawLink, QString *errorMessage);

    /**
     * @brief Parse a classic WireGuard INI config.
     * @param rawConfig Input config text containing [Interface]/[Peer] sections.
     * @param errorMessage Optional output message on failure.
     * @return Parsed profile or empty optional.
     */
    static std::optional<ServerProfile> parseWireguardConfig(const QString& rawConfig, QString *errorMessage);

    /**
     * @brief Decode URL-safe or standard base64 text.
     * @param value Encoded input.
     * @return Decoded bytes (may be empty on failure).
     */
    static QByteArray decodeFlexibleBase64(const QString& value);

    /**
     * @brief Helper to set consistent parse errors.
     * @param errorMessage Optional output pointer.
     * @param error Message value.
     */
    static void setError(QString *errorMessage, const QString& error);
};

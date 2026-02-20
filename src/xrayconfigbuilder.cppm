/*!
 * @file        xrayconfigbuilder.cppm
 * @brief       Runtime Xray configuration generator.
 *
 * @details
 * Defines build options and factory APIs that transform a selected
 * `ServerProfile` into a complete Xray JSON runtime configuration,
 * including inbounds, outbounds, routing, and optional stats/process rules.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QJsonObject>
#include <QStringList>
#include <QtTypes>

#ifndef Q_MOC_RUN
export module genyconnect.backend.xrayconfigbuilder;
import genyconnect.backend.serverprofile;
#endif

/**
 * @class XrayConfigBuilder
 * @brief Builds runtime configuration documents for Xray core.
 */
export class XrayConfigBuilder
{
public:
    /**
     * @struct BuildOptions
     * @brief High-level switches used while composing runtime JSON.
     */
    struct BuildOptions {
        quint16 socksPort = 10808;              //!< Local mixed/socks inbound port.
        quint16 httpPort = 10809;               //!< Local http inbound port.
        quint16 apiPort = 10085;                //!< Xray API inbound port.
        QString logLevel = QStringLiteral("warning"); //!< Runtime log level.
        bool enableMux = false;                 //!< Enable outbound mux.
        bool enableStatsApi = true;             //!< Enable stats API and policy.
        bool enableTun = false;                 //!< Enable system-level TUN inbound.
        bool tunAutoRoute = true;               //!< Auto-manage host routes for TUN.
        bool tunStrictRoute = true;             //!< Prevent route bypass leaks when possible.
        QString tunInterfaceName;               //!< Optional explicit interface name (macOS: utunN).
        bool whitelistMode = false;             //!< Enable whitelist-first routing mode.
        bool enableProcessRouting = false;      //!< Enable process-based rules.
        QStringList proxyDomains;               //!< Domain rules to tunnel.
        QStringList directDomains;              //!< Domain rules to bypass.
        QStringList blockDomains;               //!< Domain rules to block.
        QStringList proxyProcesses;             //!< Process names to tunnel.
        QStringList directProcesses;            //!< Process names to bypass.
        QStringList blockProcesses;             //!< Process names to block.
    };

    /**
     * @brief Build full Xray runtime JSON.
     * @param profile Selected server profile.
     * @param options Build options.
     * @return Complete configuration object.
     */
    static QJsonObject build(const ServerProfile& profile, const BuildOptions& options);

private:
    /**
     * @brief Build primary proxy outbound object.
     * @param profile Server profile.
     * @param enableMux Enable mux section.
     * @return Outbound JSON object.
     */
    static QJsonObject buildMainOutbound(const ServerProfile& profile, bool enableMux);

    /**
     * @brief Build stream settings based on profile transport/security.
     * @param profile Server profile.
     * @return Stream settings object.
     */
    static QJsonObject buildStreamSettings(const ServerProfile& profile);
};

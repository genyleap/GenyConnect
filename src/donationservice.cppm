/*!
 * @file        donationservice.cppm
 * @brief       Donation configuration and payload builder.
 *
 * @details
 * Keeps token metadata, wallet discovery, and donation deep-link payload
 * creation outside VpnController.
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QLatin1StringView>
#include <QString>
#include <QStringView>
#include <QVariantList>
#include <QVariantMap>

export module genyconnect.backend.donationservice;

/**
 * @class DonationService
 * @brief Builds donation UI data and token transfer payloads.
 */
export class DonationService
{
public:
    /**
     * @brief Discover compatible wallet targets for transfer and swap links.
     * @param transferUrl Token transfer deep link.
     * @param swapUrl Token swap URL.
     * @return Wallet rows consumable by QML.
     */
    static QVariantList walletTargets(QStringView transferUrl, QStringView swapUrl);

    /**
     * @brief Build static donation screen configuration.
     * @return Network, receiver, explorer, and notice metadata.
     */
    static QVariantMap config();

    /**
     * @brief Build selectable donation token rows.
     * @return Token metadata and preset amount options.
     */
    static QVariantList tokenOptions();

    /**
     * @brief Validate a donation amount and build a wallet transfer payload.
     * @param tokenSymbol Selected token symbol.
     * @param amountText Human-entered token amount.
     * @return Payload map with ok/error state and deep-link fields.
     */
    static QVariantMap buildPayload(QStringView tokenSymbol, QStringView amountText);
};

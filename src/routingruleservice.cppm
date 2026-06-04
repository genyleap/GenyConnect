/*!
 * @file        routingruleservice.cppm
 * @brief       Routing rule validation helpers.
 *
 * @details
 * Normalizes and validates user routing rules independently from VpnController
 * state ownership.
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QString>
#include <QVariantMap>

export module genyconnect.backend.routingruleservice;

/**
 * @class RoutingRuleService
 * @brief Pure helpers for routing rule validation and normalization.
 */
export class RoutingRuleService
{
public:
    /**
     * @brief VpnController-owned state needed to validate a routing rule.
     */
    struct ValidationContext {
        ///< True when outbound rules must reference an existing profile.
        bool enforceProfileExists = false;

        ///< True when the referenced profile exists after normalization.
        bool profileExists = true;

        ///< True when the active runtime can route by application/process.
        bool perAppCapableRuntime = false;

        ///< True when process routing was checked and is unavailable.
        bool processSupportBlocked = false;
    };

    /**
     * @brief Validate and normalize one routing rule form submission.
     * @param targetType Rule target category such as domain, CIDR, country, or process.
     * @param targetValue User-entered target value.
     * @param action Routing action selected by the user.
     * @param profileId Optional outbound profile identifier.
     * @param context Runtime capabilities and profile existence state.
     * @return Result map containing ok/error and normalized fields.
     */
    static QVariantMap validate(
        const QString& targetType,
        const QString& targetValue,
        const QString& action,
        const QString& profileId,
        const ValidationContext& context);
};

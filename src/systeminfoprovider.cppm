/*!
 * @file        systeminfoprovider.cppm
 * @brief       System diagnostics data provider.
 *
 * @details
 * Builds the software and hardware diagnostic maps consumed by QML without
 * keeping OS probing code inside VpnController.
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QString>
#include <QVariantMap>

#include <functional>

export module genyconnect.backend.systeminfoprovider;

/**
 * @class SystemInfoProvider
 * @brief Provides normalized app, OS, and hardware diagnostic information.
 */
export class SystemInfoProvider
{
public:
    /**
     * @brief Formats a byte count using the application's existing policy.
     */
    using ByteFormatter = std::function<QString(qint64)>;

    /**
     * @brief Runtime values supplied by VpnController.
     */
    struct RuntimeValues {
        ///< Xray core version string shown in diagnostics.
        QString xrayVersion;

        ///< Current process memory usage text.
        QString processMemoryText;

        ///< True when the active runtime is mobile.
        bool mobile = false;

        ///< Optional byte formatter used for memory capacity values.
        ByteFormatter byteFormatter;
    };

    /**
     * @brief Build the combined system information map.
     */
    static QVariantMap systemInfo(const RuntimeValues& values);

    /**
     * @brief Build software and runtime diagnostic values.
     */
    static QVariantMap softwareInfo(const RuntimeValues& values);

    /**
     * @brief Build hardware and host capability diagnostic values.
     */
    static QVariantMap hardwareInfo(const RuntimeValues& values);

    /**
     * @brief Read a value from a diagnostic map with a stable fallback.
     */
    static QString value(const QVariantMap& values, const QString& key);

    /**
     * @brief Build the plain-text diagnostic report shown/exported by the app.
     */
    static QString diagnosticText(const RuntimeValues& values);
};

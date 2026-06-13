/*!
 * @file        platformactionservice.cppm
 * @brief       Cross-platform UI action helpers.
 *
 * @details
 * Wraps OS-specific actions such as opening URLs, Android package targeting,
 * and platform settings screens.
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QString>

export module genyconnect.backend.platformactionservice;

/**
 * @class PlatformActionService
 * @brief Performs platform-specific UI actions.
 */
export class PlatformActionService
{
public:
    /**
     * @brief Open the host OS proxy settings screen when supported.
     * @return True when the request was handed to the platform.
     */
    static bool openSystemProxySettings();

    /**
     * @brief Open Android battery optimization exemption/settings when supported.
     * @return True when the request was handed to the platform.
     */
    static bool openBatteryOptimizationSettings();

    /**
     * @brief Check whether Android battery optimizations ignore this app.
     * @return True when exempt or when the platform has no such restriction.
     */
    static bool isIgnoringBatteryOptimizations();

    /**
     * @brief Open a URL through the platform chooser/default handler.
     * @param url URL to open.
     * @param chooserTitle Android chooser title when applicable.
     * @return True when the platform accepted the request.
     */
    static bool openUrlWithChooser(const QString& url, const QString& chooserTitle);

    /**
     * @brief Open a URL with a specific Android package when available.
     * @param url URL to open.
     * @param packageName Android package name.
     * @return True when the targeted app accepted the URL.
     */
    static bool openUrlInAndroidPackage(const QString& url, const QString& packageName);

    /**
     * @brief Check whether an Android package is installed.
     * @param packageName Android package name.
     * @return True when installed on Android; false on unsupported platforms.
     */
    static bool isAndroidPackageInstalled(const QString& packageName);
};

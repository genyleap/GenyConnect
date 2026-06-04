/*!
 * @file        networkcachemanager.cppm
 * @brief       OS network cache cleanup interface.
 *
 * @details
 * Declares a small platform-specific service for clearing DNS resolver and
 * IP neighbor cache state without exposing the implementation through
 * VpnController.
 *
 * @author      Kambiz Asadzadeh
 * @since       04 Jun 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

#include <functional>

export module genyconnect.backend.networkcachemanager;

/**
 * @class NetworkCacheManager
 * @brief Clears platform network cache state.
 */
export class NetworkCacheManager
{
public:
    /**
     * @brief Runs a privileged helper command.
     *
     * The callback keeps helper process ownership inside VpnController while
     * allowing this service to own network-cache command composition.
     */
    using PrivilegedCommandRunner = std::function<bool(const QJsonObject&, QJsonObject*, QString*, int)>;

    /**
     * @brief Receives human-readable system log messages.
     */
    using LogSink = std::function<void(const QString&)>;

    /**
     * @brief Runtime dependencies required by cache cleanup.
     */
    struct Options {
        ///< Optional privileged helper command executor.
        PrivilegedCommandRunner privilegedCommandRunner;

        ///< Optional system log sink.
        LogSink logSink;
    };

    /**
     * @brief Create a cache manager with injected runtime dependencies.
     */
    explicit NetworkCacheManager(Options options = {});

    /**
     * @brief Clear DNS resolver and IP neighbor cache state for the current OS.
     * @return Result map with ok, message, and details fields.
     */
    QVariantMap clearNetworkCache();

private:
    /**
     * @brief Build the QML-facing operation result.
     */
    QVariantMap finish(bool ok, const QString& message, const QStringList& details = QStringList()) const;

    /**
     * @brief Ask the privileged helper to clear cache on platforms that need elevation.
     */
    bool runPrivilegedCacheClear(QJsonObject *response, QString *errorMessage) const;

    /**
     * @brief Emit a system log line when a sink is available.
     */
    void log(const QString& message) const;

    Options m_options;
};

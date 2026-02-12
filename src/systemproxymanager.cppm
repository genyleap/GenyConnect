/*!
 * @file        systemproxymanager.cppm
 * @brief       System proxy control interface.
 *
 * @details
 * Declares cross-platform APIs for enabling/disabling system proxy settings
 * used by GenyConnect. Includes macOS-specific helpers for network services,
 * validation checks, and privileged batch operations.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QList>
#include <QString>
#include <QStringList>
#include <QtTypes>

export module genyconnect.backend.systemproxymanager;

/**
 * @class SystemProxyManager
 * @brief Applies and clears OS-level proxy configuration.
 */
export class SystemProxyManager
{
public:
    /**
     * @brief Enable system proxies for local tunnel ports.
     * @param socksPort Local SOCKS proxy port.
     * @param httpPort Local HTTP proxy port.
     * @param errorMessage Optional output message on failure.
     * @return True when operation succeeds.
     */
    bool enable(quint16 socksPort, quint16 httpPort, QString *errorMessage = nullptr);

    /**
     * @brief Disable system proxies.
     * @param errorMessage Optional output message on failure.
     * @param force Force disable even if state tracking disagrees.
     * @return True when operation succeeds.
     */
    bool disable(QString *errorMessage = nullptr, bool force = false);

    /**
     * @brief Whether manager believes proxy is enabled.
     * @return Tracked enabled flag.
     */
    bool isEnabled() const;

private:
#ifdef Q_OS_MACOS
    /**
     * @struct ProxyInfo
     * @brief Parsed proxy state for one macOS network service.
     */
    struct ProxyInfo {
        bool enabled = false; //!< Whether proxy is enabled for service.
        QString server;       //!< Configured proxy host.
        int port = 0;         //!< Configured proxy port.
    };

    /**
     * @brief Apply enable/disable on macOS services.
     * @param enable Enable or disable action.
     * @param socksPort SOCKS port.
     * @param httpPort HTTP/HTTPS port.
     * @param errorMessage Optional output message on failure.
     * @return True on success.
     */
    bool applyOnMac(bool enable, quint16 socksPort, quint16 httpPort, QString *errorMessage);

    /**
     * @brief Execute one `networksetup` command.
     * @param arguments Command arguments.
     * @param errorMessage Optional output message on failure.
     * @return True on success.
     */
    bool runNetworkSetup(const QStringList& arguments, QString *errorMessage);

    /**
     * @brief Execute batch of `networksetup` commands with elevation.
     * @param commands List of argument lists.
     * @param errorMessage Optional output message on failure.
     * @return True on success.
     */
    bool runNetworkSetupBatchAsAdmin(const QList<QStringList>& commands, QString *errorMessage);

    /**
     * @brief Enumerate active macOS network services.
     * @param errorMessage Optional output message on failure.
     * @return Service name list.
     */
    QStringList listActiveMacNetworkServices(QString *errorMessage);

    /**
     * @brief Check whether any service proxy is enabled.
     * @param socksPort Expected SOCKS port.
     * @param httpPort Expected HTTP port.
     * @param errorMessage Optional output message on failure.
     * @return True if any matching proxy is enabled.
     */
    bool anyProxyEnabledOnMac(quint16 socksPort, quint16 httpPort, QString *errorMessage);

    /**
     * @brief Read service proxy settings from `networksetup`.
     * @param service Service name.
     * @param queryArgument Query flag (`-getsocksfirewallproxy`, ...).
     * @param info Output info structure.
     * @param errorMessage Optional output message on failure.
     * @return True on successful parse.
     */
    bool readServiceProxyInfo(const QString& service, const QString& queryArgument, ProxyInfo *info, QString *errorMessage);

    /**
     * @brief Verify all active services point to local proxy values.
     * @param socksPort Expected SOCKS port.
     * @param httpPort Expected HTTP port.
     * @param errorMessage Optional output message on failure.
     * @return True if all services are configured as expected.
     */
    bool areAllServicesConfiguredForLocalProxy(quint16 socksPort, quint16 httpPort, QString *errorMessage);

    /**
     * @brief Verify all active services have proxies disabled.
     * @param errorMessage Optional output message on failure.
     * @return True if all services are disabled.
     */
    bool areAllServicesProxyDisabled(QString *errorMessage);
#endif

    /**
     * @brief Utility to set output error text.
     * @param errorMessage Optional output pointer.
     * @param message Error message.
     */
    static void setError(QString *errorMessage, const QString& message);

    bool m_enabled = false; //!< Last known applied proxy state.
};

/*!
 * @file        connectionstate.cppm
 * @brief       Connection state enum exports for GenyConnect.
 *
 * @details
 * Provides the canonical connection-state enum used across backend modules
 * and QML bindings. This module also exposes Qt meta-object helpers so
 * enum values are available in signal/property systems.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QObject>

#ifndef Q_MOC_RUN
export module genyconnect.backend.connectionstate;
#endif

namespace App {
Q_NAMESPACE

/**
 * @enum ConnectionState
 * @brief High-level VPN tunnel state.
 *
 * @details
 * Represents the user-visible lifecycle of a connection attempt and is used
 * by both backend logic and QML bindings.
 */
enum class ConnectionState
{
    Disconnected, //!< No active tunnel process.
    Connecting,   //!< Tunnel start is in progress.
    Connected,    //!< Tunnel process is running and ready.
    Error         //!< Last operation failed.
};

Q_ENUM_NS(ConnectionState)

} // namespace App

#ifndef Q_MOC_RUN

//! Convenience alias exported from the internal App namespace.
export using ConnectionState = App::ConnectionState;

/**
 * @brief Return Qt meta-object for the `App` namespace.
 * @return Namespace meta-object containing exported enums.
 */
export const QMetaObject& connectionStateMetaObject()
{
    return App::staticMetaObject;
}
#endif

#include "connectionstate.moc"

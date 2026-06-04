/*!
 * @file        macosappbridge.mm
 * @brief       macOS-specific application integration utilities.
 *
 * @details
 * Provides platform-specific implementations for interacting with native
 * AppKit functionality. This translation unit contains helper functions used
 * to control macOS application behavior at runtime, such as Dock visibility
 * and activation policy management.
 *
 * These implementations are compiled only on macOS and gracefully become
 * no-op stubs on other platforms.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

#include "platform/macosappbridge.hpp"
#include <QtCore/QtGlobal>

#if defined(Q_OS_MACOS)
#import <AppKit/NSApplication.h>
#endif

namespace Platform {

/**
 * @brief Controls the visibility of the application in the macOS Dock.
 *
 * On macOS, this function switches the application's activation policy
 * between a regular application (visible in the Dock) and an accessory
 * application (hidden from the Dock).
 *
 * Calling this function on non-macOS platforms has no effect.
 *
 * @param visible
 *        When @c true, the application is displayed in the Dock.
 *        When @c false, the application is hidden from the Dock.
 */

void setMacDockVisible(const bool visible)
{
#if defined(Q_OS_MACOS)
    if (NSApp == nil) {
        return;
    }
    const NSApplicationActivationPolicy policy =
        visible ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyAccessory;
    if (NSApp.activationPolicy != policy) {
        [NSApp setActivationPolicy:policy];
    }
#else
    (void)visible;
#endif
}

} // namespace Platform

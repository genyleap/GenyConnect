#include "platform/macosappbridge.hpp"
#include <QtCore/QtGlobal>

#if defined(Q_OS_MACOS)
#import <AppKit/NSApplication.h>
#endif

namespace Platform {

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

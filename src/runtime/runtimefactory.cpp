#include "runtime/runtimefactory.hpp"

#include "runtime/androidvpnruntime.hpp"
#include "runtime/desktopvpnruntime.hpp"
#include "runtime/iosvpnruntime.hpp"

#include <QtGlobal>

std::unique_ptr<VpnRuntimeBackend> createRuntimeBackend(QObject *parent)
{
#if defined(Q_OS_ANDROID)
    return std::make_unique<AndroidVpnRuntime>(parent);
#elif defined(Q_OS_IOS)
    return std::make_unique<IosVpnRuntime>(parent);
#else
    return std::make_unique<DesktopVpnRuntime>(parent);
#endif
}


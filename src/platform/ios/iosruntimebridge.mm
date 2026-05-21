#include "platform/ios/iosruntimebridge.hpp"

namespace Platform {

bool IosRuntimeBridge::startPacketTunnel(QString *errorMessage)
{
    if (errorMessage) {
        *errorMessage = QString::fromUtf8(
            "iOS Packet Tunnel bridge is not implemented yet. Add NetworkExtension IPC wiring.");
    }
    return false;
}

bool IosRuntimeBridge::stopPacketTunnel(QString *errorMessage)
{
    if (errorMessage) {
        errorMessage->clear();
    }
    return true;
}

} // namespace Platform

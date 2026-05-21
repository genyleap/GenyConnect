#pragma once

#include <QString>

namespace Platform {

class IosRuntimeBridge
{
public:
    static bool startPacketTunnel(QString *errorMessage);
    static bool stopPacketTunnel(QString *errorMessage);
};

} // namespace Platform


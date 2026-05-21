#pragma once

#include <memory>

class QObject;
class VpnRuntimeBackend;

std::unique_ptr<VpnRuntimeBackend> createRuntimeBackend(QObject *parent = nullptr);


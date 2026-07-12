// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

#include "securitystatus.hpp"

#include <QStringList>

namespace {
QString normalizedProtocol(const QString& protocol)
{
    QString value = protocol.trimmed().toLower();
    if (value == QString::fromUtf8("ss")) {
        return QString::fromUtf8("shadowsocks");
    }
    if (value == QString::fromUtf8("wg")) {
        return QString::fromUtf8("wireguard");
    }
    return value;
}
}

SecurityStatus::SecurityStatus(QObject *parent)
    : QObject(parent)
    , m_lastCheckedAt(QDateTime::currentDateTimeUtc())
{
}

SecurityStatus::KillSwitchState SecurityStatus::killSwitchState() const
{
    return m_snapshot.killSwitchState;
}

SecurityStatus::DnsLeakState SecurityStatus::dnsLeakState() const
{
    return m_snapshot.dnsLeakState;
}

SecurityStatus::Ipv6LeakState SecurityStatus::ipv6LeakState() const
{
    return m_snapshot.ipv6LeakState;
}

SecurityStatus::EncryptionState SecurityStatus::encryptionState() const
{
    return m_snapshot.encryptionState;
}

QString SecurityStatus::killSwitchLabel() const
{
    return labelFor(m_snapshot.killSwitchState);
}

QString SecurityStatus::dnsLeakLabel() const
{
    return labelFor(m_snapshot.dnsLeakState);
}

QString SecurityStatus::ipv6LeakLabel() const
{
    return labelFor(m_snapshot.ipv6LeakState);
}

QString SecurityStatus::encryptionLabel() const
{
    return labelFor(m_snapshot.encryptionState);
}

QDateTime SecurityStatus::lastCheckedAt() const
{
    return m_lastCheckedAt;
}

bool SecurityStatus::diagnosticsAvailable() const
{
    return m_snapshot.diagnosticsAvailable;
}

void SecurityStatus::update(const Inputs& inputs)
{
    m_snapshot = derive(inputs);
    m_lastCheckedAt = QDateTime::currentDateTimeUtc();
    emit changed();
}

SecurityStatus::Snapshot SecurityStatus::derive(const Inputs& inputs)
{
    Snapshot snapshot;

    if (!inputs.platformSupportsKillSwitch) {
        snapshot.killSwitchState = KillSwitchUnsupported;
    } else if (!inputs.killSwitchEnabled) {
        snapshot.killSwitchState = KillSwitchInactive;
    } else if (!inputs.killSwitchEnforcementKnown) {
        snapshot.killSwitchState = KillSwitchUnknown;
    } else {
        snapshot.killSwitchState = inputs.killSwitchEnforced
            ? KillSwitchActive
            : KillSwitchInactive;
    }

    if (inputs.dnsLeakDetected) {
        snapshot.dnsLeakState = DnsLeakLeaking;
    } else if (inputs.connected && inputs.runtimeActive && inputs.dnsRoutingKnown) {
        snapshot.dnsLeakState = inputs.dnsRoutedThroughTunnel
            ? DnsLeakProtected
            : DnsLeakLeaking;
    } else {
        snapshot.dnsLeakState = DnsLeakUnknown;
    }

    if (inputs.connected && inputs.runtimeActive && inputs.ipv6RoutingKnown) {
        if (!inputs.ipv6Available) {
            snapshot.ipv6LeakState = Ipv6LeakNotAvailable;
        } else if (inputs.ipv6BlockedOrCaptured) {
            snapshot.ipv6LeakState = Ipv6LeakBlocked;
        } else {
            snapshot.ipv6LeakState = Ipv6LeakLeaking;
        }
    } else {
        snapshot.ipv6LeakState = Ipv6LeakUnknown;
    }

    if (!inputs.connected || !inputs.runtimeActive) {
        snapshot.encryptionState = EncryptionInactive;
    } else if (protocolProvidesEncryption(inputs.activeProtocol)) {
        snapshot.encryptionState = EncryptionActive;
    } else if (protocolIsKnownPlaintext(inputs.activeProtocol)) {
        snapshot.encryptionState = EncryptionInactive;
    } else {
        snapshot.encryptionState = EncryptionUnknown;
    }

    snapshot.diagnosticsAvailable = inputs.killSwitchEnforcementKnown
        || inputs.dnsRoutingKnown
        || inputs.ipv6RoutingKnown
        || protocolProvidesEncryption(inputs.activeProtocol)
        || protocolIsKnownPlaintext(inputs.activeProtocol);
    return snapshot;
}

QString SecurityStatus::labelFor(KillSwitchState state)
{
    switch (state) {
    case KillSwitchActive:
        return QString::fromUtf8("Active");
    case KillSwitchInactive:
        return QString::fromUtf8("Inactive");
    case KillSwitchUnsupported:
        return QString::fromUtf8("Unsupported");
    case KillSwitchUnknown:
        return QString::fromUtf8("Unknown");
    }
    return QString::fromUtf8("Unknown");
}

QString SecurityStatus::labelFor(DnsLeakState state)
{
    switch (state) {
    case DnsLeakProtected:
        return QString::fromUtf8("Protected");
    case DnsLeakLeaking:
        return QString::fromUtf8("Leaking");
    case DnsLeakUnknown:
        return QString::fromUtf8("Unknown");
    }
    return QString::fromUtf8("Unknown");
}

QString SecurityStatus::labelFor(Ipv6LeakState state)
{
    switch (state) {
    case Ipv6LeakBlocked:
        return QString::fromUtf8("Blocked");
    case Ipv6LeakLeaking:
        return QString::fromUtf8("Leaking");
    case Ipv6LeakNotAvailable:
        return QString::fromUtf8("Not Available");
    case Ipv6LeakUnknown:
        return QString::fromUtf8("Unknown");
    }
    return QString::fromUtf8("Unknown");
}

QString SecurityStatus::labelFor(EncryptionState state)
{
    switch (state) {
    case EncryptionActive:
        return QString::fromUtf8("Active");
    case EncryptionInactive:
        return QString::fromUtf8("Inactive");
    case EncryptionUnknown:
        return QString::fromUtf8("Unknown");
    }
    return QString::fromUtf8("Unknown");
}

bool SecurityStatus::protocolProvidesEncryption(const QString& protocol)
{
    const QString value = normalizedProtocol(protocol);
    static const QStringList encryptedProtocols {
        QString::fromUtf8("vless"),
        QString::fromUtf8("vmess"),
        QString::fromUtf8("trojan"),
        QString::fromUtf8("shadowsocks"),
        QString::fromUtf8("wireguard")
    };
    return encryptedProtocols.contains(value);
}

bool SecurityStatus::protocolIsKnownPlaintext(const QString& protocol)
{
    const QString value = normalizedProtocol(protocol);
    static const QStringList plaintextProtocols {
        QString::fromUtf8("direct"),
        QString::fromUtf8("freedom"),
        QString::fromUtf8("http"),
        QString::fromUtf8("socks"),
        QString::fromUtf8("dokodemo-door")
    };
    return plaintextProtocols.contains(value);
}

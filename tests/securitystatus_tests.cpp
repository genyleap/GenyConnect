// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

#include "securitystatus.hpp"

#include <QtTest/QtTest>

class SecurityStatusTests : public QObject
{
    Q_OBJECT

private slots:
    void killSwitchDerivation();
    void dnsLeakDerivation();
    void ipv6LeakDerivation();
    void encryptionDerivation();
    void labelsDoNotPromoteUnknownToSafe();
};

void SecurityStatusTests::killSwitchDerivation()
{
    SecurityStatus::Inputs inputs;
    auto snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.killSwitchState, SecurityStatus::KillSwitchUnsupported);

    inputs.platformSupportsKillSwitch = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.killSwitchState, SecurityStatus::KillSwitchInactive);

    inputs.killSwitchEnabled = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.killSwitchState, SecurityStatus::KillSwitchUnknown);

    inputs.killSwitchEnforcementKnown = true;
    inputs.killSwitchEnforced = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.killSwitchState, SecurityStatus::KillSwitchActive);

    inputs.killSwitchEnforced = false;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.killSwitchState, SecurityStatus::KillSwitchInactive);
}

void SecurityStatusTests::dnsLeakDerivation()
{
    SecurityStatus::Inputs inputs;
    inputs.connected = true;
    inputs.runtimeActive = true;

    auto snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.dnsLeakState, SecurityStatus::DnsLeakUnknown);

    inputs.dnsRoutingKnown = true;
    inputs.dnsRoutedThroughTunnel = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.dnsLeakState, SecurityStatus::DnsLeakProtected);

    inputs.dnsRoutedThroughTunnel = false;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.dnsLeakState, SecurityStatus::DnsLeakLeaking);

    inputs.dnsLeakDetected = true;
    inputs.dnsRoutedThroughTunnel = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.dnsLeakState, SecurityStatus::DnsLeakLeaking);
}

void SecurityStatusTests::ipv6LeakDerivation()
{
    SecurityStatus::Inputs inputs;
    inputs.connected = true;
    inputs.runtimeActive = true;

    auto snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.ipv6LeakState, SecurityStatus::Ipv6LeakUnknown);

    inputs.ipv6RoutingKnown = true;
    inputs.ipv6Available = false;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.ipv6LeakState, SecurityStatus::Ipv6LeakNotAvailable);

    inputs.ipv6Available = true;
    inputs.ipv6BlockedOrCaptured = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.ipv6LeakState, SecurityStatus::Ipv6LeakBlocked);

    inputs.ipv6BlockedOrCaptured = false;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.ipv6LeakState, SecurityStatus::Ipv6LeakLeaking);
}

void SecurityStatusTests::encryptionDerivation()
{
    SecurityStatus::Inputs inputs;
    inputs.activeProtocol = QString::fromUtf8("vless");

    auto snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.encryptionState, SecurityStatus::EncryptionInactive);

    inputs.connected = true;
    inputs.runtimeActive = true;
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.encryptionState, SecurityStatus::EncryptionActive);

    inputs.activeProtocol = QString::fromUtf8("direct");
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.encryptionState, SecurityStatus::EncryptionInactive);

    inputs.activeProtocol = QString::fromUtf8("unknown-protocol");
    snapshot = SecurityStatus::derive(inputs);
    QCOMPARE(snapshot.encryptionState, SecurityStatus::EncryptionUnknown);
}

void SecurityStatusTests::labelsDoNotPromoteUnknownToSafe()
{
    QCOMPARE(SecurityStatus::labelFor(SecurityStatus::KillSwitchUnknown), QString::fromUtf8("Unknown"));
    QCOMPARE(SecurityStatus::labelFor(SecurityStatus::DnsLeakUnknown), QString::fromUtf8("Unknown"));
    QCOMPARE(SecurityStatus::labelFor(SecurityStatus::Ipv6LeakUnknown), QString::fromUtf8("Unknown"));
    QCOMPARE(SecurityStatus::labelFor(SecurityStatus::EncryptionUnknown), QString::fromUtf8("Unknown"));
    QVERIFY(SecurityStatus::labelFor(SecurityStatus::DnsLeakUnknown) != QString::fromUtf8("Protected"));
    QVERIFY(SecurityStatus::labelFor(SecurityStatus::Ipv6LeakUnknown) != QString::fromUtf8("Blocked"));
    QVERIFY(SecurityStatus::labelFor(SecurityStatus::KillSwitchUnknown) != QString::fromUtf8("Active"));
    QVERIFY(SecurityStatus::labelFor(SecurityStatus::EncryptionUnknown) != QString::fromUtf8("Active"));
}

QTEST_MAIN(SecurityStatusTests)
#include "securitystatus_tests.moc"

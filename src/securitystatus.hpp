// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>

class SecurityStatus : public QObject
{
    Q_OBJECT
    Q_PROPERTY(KillSwitchState killSwitchState READ killSwitchState NOTIFY changed)
    Q_PROPERTY(DnsLeakState dnsLeakState READ dnsLeakState NOTIFY changed)
    Q_PROPERTY(Ipv6LeakState ipv6LeakState READ ipv6LeakState NOTIFY changed)
    Q_PROPERTY(EncryptionState encryptionState READ encryptionState NOTIFY changed)
    Q_PROPERTY(QString killSwitchLabel READ killSwitchLabel NOTIFY changed)
    Q_PROPERTY(QString dnsLeakLabel READ dnsLeakLabel NOTIFY changed)
    Q_PROPERTY(QString ipv6LeakLabel READ ipv6LeakLabel NOTIFY changed)
    Q_PROPERTY(QString encryptionLabel READ encryptionLabel NOTIFY changed)
    Q_PROPERTY(QDateTime lastCheckedAt READ lastCheckedAt NOTIFY changed)
    Q_PROPERTY(bool diagnosticsAvailable READ diagnosticsAvailable NOTIFY changed)

public:
    enum KillSwitchState {
        KillSwitchActive,
        KillSwitchInactive,
        KillSwitchUnsupported,
        KillSwitchUnknown
    };
    Q_ENUM(KillSwitchState)

    enum DnsLeakState {
        DnsLeakProtected,
        DnsLeakLeaking,
        DnsLeakUnknown
    };
    Q_ENUM(DnsLeakState)

    enum Ipv6LeakState {
        Ipv6LeakBlocked,
        Ipv6LeakLeaking,
        Ipv6LeakNotAvailable,
        Ipv6LeakUnknown
    };
    Q_ENUM(Ipv6LeakState)

    enum EncryptionState {
        EncryptionActive,
        EncryptionInactive,
        EncryptionUnknown
    };
    Q_ENUM(EncryptionState)

    struct Inputs {
        bool platformSupportsKillSwitch = false;
        bool killSwitchEnabled = false;
        bool killSwitchEnforcementKnown = false;
        bool killSwitchEnforced = false;

        bool connected = false;
        bool runtimeActive = false;

        bool dnsRoutingKnown = false;
        bool dnsRoutedThroughTunnel = false;
        bool dnsLeakDetected = false;

        bool ipv6RoutingKnown = false;
        bool ipv6Available = false;
        bool ipv6BlockedOrCaptured = false;

        QString activeProtocol;
    };

    struct Snapshot {
        KillSwitchState killSwitchState = KillSwitchUnknown;
        DnsLeakState dnsLeakState = DnsLeakUnknown;
        Ipv6LeakState ipv6LeakState = Ipv6LeakUnknown;
        EncryptionState encryptionState = EncryptionUnknown;
        bool diagnosticsAvailable = false;
    };

    explicit SecurityStatus(QObject *parent = nullptr);

    KillSwitchState killSwitchState() const;
    DnsLeakState dnsLeakState() const;
    Ipv6LeakState ipv6LeakState() const;
    EncryptionState encryptionState() const;

    QString killSwitchLabel() const;
    QString dnsLeakLabel() const;
    QString ipv6LeakLabel() const;
    QString encryptionLabel() const;
    QDateTime lastCheckedAt() const;
    bool diagnosticsAvailable() const;

    void update(const Inputs& inputs);

    static Snapshot derive(const Inputs& inputs);
    static QString labelFor(KillSwitchState state);
    static QString labelFor(DnsLeakState state);
    static QString labelFor(Ipv6LeakState state);
    static QString labelFor(EncryptionState state);
    static bool protocolProvidesEncryption(const QString& protocol);
    static bool protocolIsKnownPlaintext(const QString& protocol);

signals:
    void changed();

private:
    Snapshot m_snapshot;
    QDateTime m_lastCheckedAt;
};

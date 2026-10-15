// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Genyleap Labs.
#pragma once

#include <QByteArray>
#include <QHostAddress>
#include <QString>
#include <QStringList>

namespace PublicIpLookup {

// Providers are independent of the tunnel lifecycle. Keep all URLs HTTPS:
// failures must never downgrade to plaintext or bypass the local SOCKS proxy.
inline const QStringList& endpoints()
{
    static const QStringList values {
        QStringLiteral("https://api.ipify.org?format=text"),
        QStringLiteral("https://checkip.amazonaws.com/"),
        QStringLiteral("https://ipv4.icanhazip.com/")
    };
    return values;
}

// Reject captive-portal HTML, HTTP errors, loopback/private answers and
// multi-line responses. An IP lookup is useful only if it is unambiguous.
inline QString parsePublicAddress(const QByteArray& payload, int statusCode)
{
    if (statusCode < 200 || statusCode >= 300 || payload.size() > 128 || payload.isEmpty()) {
        return {};
    }
    const QString response = QString::fromUtf8(payload).trimmed();
    if (response.isEmpty() || response.size() > 64 || response.contains(QLatin1Char('\n'))
        || response.contains(QLatin1Char('\r'))) {
        return {};
    }

    const QHostAddress address(response);
    if (address.isNull() || address.isLoopback() || address.isLinkLocal()
        || address.isMulticast() || !address.isGlobal()) {
        return {};
    }
    // QHostAddress::isGlobal() alone may still classify RFC1918 addresses
    // as global. The response is shown as a public VPN egress IP, so exclude
    // private, carrier-grade NAT and reserved/documentation ranges explicitly.
    const auto reserved = [&address](const char *network, int bits) {
        return address.isInSubnet(QHostAddress(QString::fromLatin1(network)), bits);
    };
    if (reserved("0.0.0.0", 8) || reserved("10.0.0.0", 8)
        || reserved("100.64.0.0", 10) || reserved("127.0.0.0", 8)
        || reserved("169.254.0.0", 16) || reserved("172.16.0.0", 12)
        || reserved("192.168.0.0", 16) || reserved("198.18.0.0", 15)
        || reserved("192.0.2.0", 24) || reserved("198.51.100.0", 24)
        || reserved("203.0.113.0", 24) || reserved("224.0.0.0", 4)
        || reserved("240.0.0.0", 4) || reserved("fc00::", 7)
        || reserved("fe80::", 10) || reserved("ff00::", 8)) {
        return {};
    }
    return address.toString();
}

} // namespace PublicIpLookup

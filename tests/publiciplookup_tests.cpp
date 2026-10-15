// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Genyleap Labs.

#include "publiciplookup.hpp"
#include <QtTest/QtTest>
#include <QSet>
#include <QUrl>

class PublicIpLookupTests : public QObject
{
    Q_OBJECT
private slots:
    void multipleIndependentSecureEndpoints();
    void acceptsGlobalAddresses();
    void rejectsUnreliableOrUnsafeAnswers();
};

void PublicIpLookupTests::multipleIndependentSecureEndpoints()
{
    QCOMPARE(PublicIpLookup::endpoints().size(), 3);
    QSet<QString> hosts;
    for (const QString& value : PublicIpLookup::endpoints()) {
        const QUrl url(value);
        QCOMPARE(url.scheme(), QStringLiteral("https"));
        QVERIFY(!url.host().isEmpty());
        hosts.insert(url.host());
    }
    QCOMPARE(hosts.size(), PublicIpLookup::endpoints().size());
}

void PublicIpLookupTests::acceptsGlobalAddresses()
{
    QCOMPARE(PublicIpLookup::parsePublicAddress("8.8.8.8\n", 200), QStringLiteral("8.8.8.8"));
    QCOMPARE(PublicIpLookup::parsePublicAddress(" 1.1.1.1 ", 200), QStringLiteral("1.1.1.1"));
    QCOMPARE(PublicIpLookup::parsePublicAddress("2606:4700:4700::1111\n", 200),
             QStringLiteral("2606:4700:4700::1111"));
}

void PublicIpLookupTests::rejectsUnreliableOrUnsafeAnswers()
{
    QVERIFY(PublicIpLookup::parsePublicAddress("8.8.8.8", 503).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("8.8.8.8", 302).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("127.0.0.1", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("10.0.0.1", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("172.20.0.10", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("192.168.1.1", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("100.64.10.2", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("203.0.113.5", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("169.254.10.2", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("fd00::1", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("<html>blocked</html>", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress("8.8.8.8\n9.9.9.9", 200).isEmpty());
    QVERIFY(PublicIpLookup::parsePublicAddress(QByteArray(), 200).isEmpty());
}

QTEST_GUILESS_MAIN(PublicIpLookupTests)
#include "publiciplookup_tests.moc"

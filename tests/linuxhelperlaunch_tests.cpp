// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

#include "linuxhelperlaunch.hpp"

#include <QtTest/QtTest>

class LinuxHelperLaunchTests : public QObject
{
    Q_OBJECT

private slots:
    void forwardsBundledQtPathWithoutAppDir();
    void launchesHelperDirectlyWithoutLibraryPath();
};

void LinuxHelperLaunchTests::forwardsBundledQtPathWithoutAppDir()
{
    const QString helperPath = QString::fromUtf8("/opt/genyconnect/bin/GenyConnectTunHelper");
    const QString libraryPath = QString::fromUtf8("/opt/genyconnect/lib");
    const QString envPath = QString::fromUtf8("/usr/bin/env");
    const QStringList helperArguments {
        QString::fromUtf8("--listen-port"),
        QString::fromUtf8("41234"),
        QString::fromUtf8("--token"),
        QString::fromUtf8("test-token")
    };

    const QStringList arguments = LinuxHelperLaunch::pkexecArguments(
        helperPath,
        helperArguments,
        libraryPath,
        envPath);

    QCOMPARE(arguments,
             QStringList({
                 envPath,
                 QString::fromUtf8("LD_LIBRARY_PATH=/opt/genyconnect/lib"),
                 helperPath,
                 QString::fromUtf8("--listen-port"),
                 QString::fromUtf8("41234"),
                 QString::fromUtf8("--token"),
                 QString::fromUtf8("test-token")
             }));
}

void LinuxHelperLaunchTests::launchesHelperDirectlyWithoutLibraryPath()
{
    const QString helperPath = QString::fromUtf8("/usr/bin/GenyConnectTunHelper");
    const QStringList helperArguments {
        QString::fromUtf8("--listen-port"),
        QString::fromUtf8("41234")
    };

    const QStringList arguments = LinuxHelperLaunch::pkexecArguments(
        helperPath,
        helperArguments,
        QString(),
        QString::fromUtf8("/usr/bin/env"));

    QCOMPARE(arguments, QStringList({helperPath, QString::fromUtf8("--listen-port"), QString::fromUtf8("41234")}));
}

QTEST_MAIN(LinuxHelperLaunchTests)
#include "linuxhelperlaunch_tests.moc"

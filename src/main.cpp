#include <QAction>
#include <QApplication>
#include <QDir>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLockFile>
#include <QMenu>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QSystemTrayIcon>
#include <QTimer>
#include <QtCore/qglobal.h>

#include "platform/macosappbridge.hpp"

import genyconnect.backend.connectionstate;
import genyconnect.backend.vpncontroller;

auto main(int argc, char *argv[]) -> int
{
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);

    QCoreApplication::setOrganizationName(QStringLiteral("GenyConnect"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("genyconnect.local"));
    QCoreApplication::setApplicationName(QStringLiteral("GenyConnect"));

#ifdef APP_VERSION
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));
#else
    QCoreApplication::setApplicationVersion(QStringLiteral("0.0.0"));
#endif

#if defined(Q_OS_WIN)
    const QIcon appIcon(QStringLiteral(":/ui/Resources/image/GenyConnect.ico"));
#else
    const QIcon appIcon(QStringLiteral(":/ui/Resources/image/favicon.png"));
#endif

    if (!appIcon.isNull()) {
        app.setWindowIcon(appIcon);
    }

    QString lockDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (lockDir.trimmed().isEmpty()) {
        lockDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    }
    if (lockDir.trimmed().isEmpty()) {
        lockDir = QDir::tempPath();
    }

    QDir().mkpath(lockDir);

    const QString instanceServerName = QStringLiteral("GenyConnectSingleInstance");
    QLockFile instanceLock(QDir(lockDir).filePath(QStringLiteral("genyconnect.instance.lock")));
    instanceLock.setStaleLockTime(0);

    if (!instanceLock.tryLock(100)) {
        QLocalSocket socket;
        socket.connectToServer(instanceServerName, QIODevice::WriteOnly);
        if (socket.waitForConnected(300)) {
            socket.write("show\n");
            socket.flush();
            socket.waitForBytesWritten(300);
        }
        return 0;
    }

    qmlRegisterUncreatableMetaObject(
        connectionStateMetaObject(),
        "GenyConnect",
        1,
        0,
        "ConnectionState",
        QStringLiteral("ConnectionState is read-only")
        );

    VpnController vpnController;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("vpnController"), &vpnController);
    engine.rootContext()->setContextProperty(QStringLiteral("updater"), vpnController.updater());

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
        );

    engine.loadFromModule(QStringLiteral("GenyConnect"), QStringLiteral("Main"));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    auto *mainWindow = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (mainWindow == nullptr) {
        return -1;
    }

    if (!appIcon.isNull()) {
        mainWindow->setIcon(appIcon);
    }

    mainWindow->setProperty("allowCloseExit", false);

    const auto setTaskbarPresence = [mainWindow](bool showInTaskbar) {
        if (mainWindow == nullptr) {
            return;
        }

#if defined(Q_OS_MACOS)
        Platform::setMacDockVisible(showInTaskbar);

        const bool makeToolWindow = !showInTaskbar;
        const bool isToolWindow = mainWindow->flags().testFlag(Qt::Tool);

        if (isToolWindow == makeToolWindow) {
            return;
        }

        const bool wasVisible = mainWindow->isVisible();
        Qt::WindowFlags flags = mainWindow->flags();

        if (makeToolWindow) {
            flags |= Qt::Tool;
        } else {
            flags &= ~Qt::Tool;
        }

        mainWindow->setFlags(flags);

        if (wasVisible) {
            mainWindow->show();
            mainWindow->raise();
            mainWindow->requestActivate();
        }
#else
        Q_UNUSED(showInTaskbar);
#endif
    };

    QLocalServer instanceServer;
    QLocalServer::removeServer(instanceServerName);

    if (instanceServer.listen(instanceServerName)) {
        QObject::connect(&instanceServer, &QLocalServer::newConnection, &app, [&]() {
            while (QLocalSocket *socket = instanceServer.nextPendingConnection()) {
                socket->deleteLater();
            }

            setTaskbarPresence(true);
            mainWindow->show();
            mainWindow->raise();
            mainWindow->requestActivate();
        });
    }

    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        mainWindow->setProperty("allowCloseExit", true);
        return app.exec();
    }

    const QIcon trayBaseIcon(QStringLiteral(":/ui/Resources/image/favicon.png"));

    QSystemTrayIcon trayIcon;
    trayIcon.setIcon(trayBaseIcon.isNull() ? app.windowIcon() : trayBaseIcon);

    QMenu trayMenu;
    QAction openAction(QStringLiteral("Open"), &trayMenu);
    QAction toggleAction(&trayMenu);
    QAction exitAction(QStringLiteral("Exit"), &trayMenu);

    trayMenu.addAction(&openAction);
    trayMenu.addAction(&toggleAction);
    trayMenu.addSeparator();
    trayMenu.addAction(&exitAction);

    trayIcon.setContextMenu(&trayMenu);

    bool disconnectThenQuit = false;

    const auto updateTrayState = [&vpnController, &toggleAction]() {
        const ConnectionState state = vpnController.connectionState();

        switch (state) {
        case ConnectionState::Connected:
            toggleAction.setText(QStringLiteral("🟢 Connected — Disconnect"));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            break;

        case ConnectionState::Connecting:
            toggleAction.setText(QStringLiteral("⚪ Connecting..."));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            break;

        case ConnectionState::Error:
            toggleAction.setText(QStringLiteral("🔴 Failed — Connect"));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            break;

        case ConnectionState::Disconnected:
        default:
            toggleAction.setText(QStringLiteral("🔴 Disconnected — Connect"));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(vpnController.currentProfileIndex() >= 0);
            break;
        }
    };

    QObject::connect(&vpnController, &VpnController::connectionStateChanged, &app, [&]() {
        updateTrayState();

        if (disconnectThenQuit && !vpnController.connected() && !vpnController.busy()) {
            disconnectThenQuit = false;
            mainWindow->setProperty("allowCloseExit", true);
            QTimer::singleShot(0, &app, &QCoreApplication::quit);
        }
    });

    QObject::connect(&vpnController, &VpnController::currentProfileIndexChanged, &app, [&]() {
        updateTrayState();
    });

    QObject::connect(&openAction, &QAction::triggered, &app, [&]() {
        setTaskbarPresence(true);
        mainWindow->show();
        mainWindow->raise();
        mainWindow->requestActivate();
    });

    QObject::connect(&toggleAction, &QAction::triggered, &app, [&]() {
        vpnController.toggleConnection();
    });

    QObject::connect(&exitAction, &QAction::triggered, &app, [&]() {
        if (vpnController.connected() || vpnController.busy()) {
            disconnectThenQuit = true;
            vpnController.disconnect();
            return;
        }

        mainWindow->setProperty("allowCloseExit", true);
        QCoreApplication::quit();
    });

    QObject::connect(&trayIcon, &QSystemTrayIcon::activated, &app, [&](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
            setTaskbarPresence(true);
            mainWindow->show();
            mainWindow->raise();
            mainWindow->requestActivate();
        }
    });

    QObject::connect(mainWindow, &QWindow::visibleChanged, &app, [mainWindow, setTaskbarPresence]() {
        setTaskbarPresence(mainWindow->isVisible());
    });

    updateTrayState();
    trayIcon.show();

    return app.exec();
}
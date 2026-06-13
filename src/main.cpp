#include <QDir>
#include <QFileInfo>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QLockFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QLibraryInfo>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QTimer>
#include <initializer_list>
#include <QtCore/qglobal.h>

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
#include <QAction>
#include <QApplication>
#include <QMenu>
#include <QStyle>
#include <QSystemTrayIcon>
#endif

#if defined(Q_OS_MACOS) && !defined(Q_OS_IOS)
#include "platform/macosappbridge.hpp"
#endif

import genyconnect.backend.vpncontroller;

namespace {
QStringList qmlImportRoots()
{
    QStringList roots;
    const QString envImports = qEnvironmentVariable("QML2_IMPORT_PATH").trimmed();
    if (!envImports.isEmpty()) {
        roots.append(envImports.split(QDir::listSeparator(), Qt::SkipEmptyParts));
    }
    roots.append(QLibraryInfo::path(QLibraryInfo::QmlImportsPath));
    const QString appDir = QCoreApplication::applicationDirPath();
    if (!appDir.isEmpty()) {
        roots.append(QDir(appDir).filePath(QString::fromUtf8("qml")));
        roots.append(QDir(appDir).filePath(QString::fromUtf8("../qml")));
    }
    roots.removeAll(QString());
    roots.removeDuplicates();
    return roots;
}

bool qmlModuleAvailable(const QString& moduleName)
{
    QString modulePath = moduleName.trimmed();
    modulePath.replace(QLatin1Char('.'), QLatin1Char('/'));
    if (modulePath.isEmpty()) {
        return false;
    }
    for (const QString& root : qmlImportRoots()) {
        const QDir rootDir(root);
        if (QFileInfo::exists(rootDir.filePath(modulePath + QString::fromUtf8("/qmldir")))) {
            return true;
        }
    }
    return false;
}

bool quickControlsStyleAvailable(const QString& style)
{
    const QString trimmed = style.trimmed();
    if (trimmed.isEmpty()) {
        return false;
    }
    const QString lowered = trimmed.toLower();
    if (lowered.contains(QString::fromUtf8("org.kde"))) {
        return qmlModuleAvailable(trimmed);
    }
    return qmlModuleAvailable(QString::fromUtf8("QtQuick.Controls.%1").arg(trimmed))
           || qmlModuleAvailable(trimmed)
           || (lowered.contains(QString::fromUtf8("breeze"))
               && qmlModuleAvailable(QString::fromUtf8("org.kde.breeze")));
}

void configureQuickControlsFallback()
{
    const QString requestedStyle = qEnvironmentVariable("QT_QUICK_CONTROLS_STYLE").trimmed();

    QQuickStyle::setFallbackStyle(QString::fromUtf8("Basic"));

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    if (requestedStyle.isEmpty()) {
        QQuickStyle::setStyle(QString::fromUtf8("Basic"));
        qInfo().noquote() << "[Qt] Quick Controls style forced to Basic on Linux to avoid host KDE/Breeze QML dependencies.";
        return;
    }
#endif

    if (!requestedStyle.isEmpty() && !quickControlsStyleAvailable(requestedStyle)) {
        QQuickStyle::setStyle(QString::fromUtf8("Basic"));
        qInfo().noquote() << "[Qt] Quick Controls style forced to Basic because requested style is not bundled:" << requestedStyle;
    }
}

void logQtRuntimeDiagnostics(const QQmlApplicationEngine *engine = nullptr)
{
    qInfo().noquote() << "[Qt] Platform plugin:" << QGuiApplication::platformName();
    qInfo().noquote() << "[Qt] Library paths:" << QCoreApplication::libraryPaths().join(QString::fromUtf8(":"));
    qInfo().noquote() << "[Qt] Qt plugin install path:" << QLibraryInfo::path(QLibraryInfo::PluginsPath);
    qInfo().noquote() << "[Qt] Qt QML install path:" << QLibraryInfo::path(QLibraryInfo::QmlImportsPath);
    qInfo().noquote() << "[Qt] QT_PLUGIN_PATH:" << qEnvironmentVariable("QT_PLUGIN_PATH");
    qInfo().noquote() << "[Qt] QML2_IMPORT_PATH:" << qEnvironmentVariable("QML2_IMPORT_PATH");
    qInfo().noquote() << "[Qt] LD_LIBRARY_PATH:" << qEnvironmentVariable("LD_LIBRARY_PATH");
    qInfo().noquote() << "[Qt] QT_QPA_PLATFORM:" << qEnvironmentVariable("QT_QPA_PLATFORM");
    qInfo().noquote() << "[Qt] QT_QUICK_CONTROLS_STYLE:" << qEnvironmentVariable("QT_QUICK_CONTROLS_STYLE");
    if (engine != nullptr) {
        qInfo().noquote() << "[Qt] QQmlApplicationEngine import paths:" << engine->importPathList().join(QString::fromUtf8(":"));
    }
}
}

auto main(int argc, char *argv[]) -> int
{
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
#else
    QGuiApplication app(argc, argv);
#if defined(Q_OS_ANDROID)
    app.setQuitOnLastWindowClosed(true);
#else
    app.setQuitOnLastWindowClosed(false);
#endif
#endif

    QCoreApplication::setOrganizationName(QString::fromUtf8("GenyConnect"));
    QCoreApplication::setOrganizationDomain(QString::fromUtf8("genyconnect.local"));
    QCoreApplication::setApplicationName(QString::fromUtf8("GenyConnect"));

#ifdef APP_VERSION
    QCoreApplication::setApplicationVersion(QString::fromUtf8(APP_VERSION));
#else
    QCoreApplication::setApplicationVersion(QString::fromUtf8("0.0.0"));
#endif

    configureQuickControlsFallback();
    logQtRuntimeDiagnostics();

    if (QCoreApplication::arguments().contains(QString::fromUtf8("--safe-network-reset"))) {
        VpnController vpnController;
        const QVariantMap result = vpnController.safeNetworkReset();
        const bool ok = result.value(QString::fromUtf8("ok")).toBool();
        const QString message = result.value(QString::fromUtf8("message")).toString();
        qInfo().noquote() << "[System]" << message;
        return ok ? 0 : 2;
    }

    const auto loadFirstAvailableIcon = [](std::initializer_list<const char *> candidates) {
        for (const char *candidate : candidates) {
            const QIcon icon(QString::fromUtf8(candidate));
            if (!icon.isNull()) {
                return icon;
            }
        }
        return QIcon();
    };

    const QIcon appIcon = loadFirstAvailableIcon({
        ":/ui/Resources/image/GenyConnect.ico",
        ":/ui/Resources/image/token-white.png",
        ":/ui/Resources/image/token-dark.png"
    });

    if (!appIcon.isNull()) {
        app.setWindowIcon(appIcon);
    }

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    QString lockDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (lockDir.trimmed().isEmpty()) {
        lockDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    }
    if (lockDir.trimmed().isEmpty()) {
        lockDir = QDir::tempPath();
    }

    QDir().mkpath(lockDir);

    const QString instanceServerName = QString::fromUtf8("GenyConnectSingleInstance");
    QLockFile instanceLock(QDir(lockDir).filePath(QString::fromUtf8("genyconnect.instance.lock")));
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
#endif

    qmlRegisterUncreatableMetaObject(
        vpnControllerConnectionStateMetaObject(),
        "GenyConnect",
        1,
        0,
        "ConnectionState",
        QString::fromUtf8("ConnectionState is read-only")
        );

    VpnController vpnController;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QString::fromUtf8("vpnController"), &vpnController);
    engine.rootContext()->setContextProperty(QString::fromUtf8("updater"), vpnController.updater());
    logQtRuntimeDiagnostics(&engine);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
        );

    engine.loadFromModule(QString::fromUtf8("GenyConnect"), QString::fromUtf8("Main"));

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

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
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
#endif

    #if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        mainWindow->setProperty("allowCloseExit", true);
        return app.exec();
    }

    const QIcon trayBaseIcon = loadFirstAvailableIcon({
        ":/ui/Resources/image/GenyConnect.ico",
        ":/ui/Resources/image/token-white.png",
        ":/ui/Resources/image/token-dark.png"
    });

    QSystemTrayIcon trayIcon;
    QIcon trayResolvedIcon = trayBaseIcon.isNull() ? app.windowIcon() : trayBaseIcon;
    if (trayResolvedIcon.isNull()) {
        trayResolvedIcon = QApplication::style()->standardIcon(QStyle::SP_ComputerIcon);
    }
    if (!trayResolvedIcon.isNull()) {
        trayIcon.setIcon(trayResolvedIcon);
    }

    QMenu trayMenu;
    QAction openAction(QString::fromUtf8("Open"), &trayMenu);
    QAction toggleAction(&trayMenu);
    QAction exitAction(QString::fromUtf8("Exit"), &trayMenu);

    trayMenu.addAction(&openAction);
    trayMenu.addAction(&toggleAction);
    trayMenu.addSeparator();
    trayMenu.addAction(&exitAction);

    trayIcon.setContextMenu(&trayMenu);

    bool disconnectThenQuit = false;

    const auto updateTrayState = [&vpnController, &toggleAction]() {
        if (vpnController.connected()) {
            toggleAction.setText(QString::fromUtf8("🟢 Connected — Disconnect"));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            return;
        }

        if (vpnController.busy()) {
            toggleAction.setText(QString::fromUtf8("⚪ Connecting..."));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            return;
        }

        if (!vpnController.lastError().trimmed().isEmpty()) {
            toggleAction.setText(QString::fromUtf8("🔴 Failed — Connect"));
            toggleAction.setIcon(QIcon());
            toggleAction.setEnabled(true);
            return;
        }

        toggleAction.setText(QString::fromUtf8("🔴 Disconnected — Connect"));
        toggleAction.setIcon(QIcon());
        toggleAction.setEnabled(vpnController.currentProfileIndex() >= 0);
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
    if (!trayIcon.icon().isNull()) {
        trayIcon.show();
    } else {
        mainWindow->setProperty("allowCloseExit", true);
    }
    #endif

    return app.exec();
}

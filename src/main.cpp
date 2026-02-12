#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

import genyconnect.backend.connectionstate;
import genyconnect.backend.vpncontroller;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName(QStringLiteral("GenyConnect"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("genyconnect.local"));
    QCoreApplication::setApplicationName(QStringLiteral("GenyConnect"));

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

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule(QStringLiteral("GenyConnect"), QStringLiteral("Main"));

    return app.exec();
}

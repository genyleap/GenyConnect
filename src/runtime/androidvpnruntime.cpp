#include "runtime/androidvpnruntime.hpp"

#include <QCoreApplication>
#include <QElapsedTimer>
#include <QFileInfo>
#include <QRegularExpression>
#include <QThread>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

namespace {
#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
constexpr const char kVpnPermissionRequiredText[] = "Android VPN permission is required";

bool bridgeAvailable()
{
    return QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass);
}

QString bridgeLastError()
{
    QJniObject errorObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "lastError",
        "()Ljava/lang/String;");
    return errorObject.isValid() ? errorObject.toString().trimmed() : QString();
}

bool bridgeIsRunning()
{
    if (!bridgeAvailable()) {
        return false;
    }
    return QJniObject::callStaticMethod<jboolean>(kAndroidRuntimeBridgeClass, "isRunning", "()Z");
}

qint64 bridgeRxBytes()
{
    if (!bridgeAvailable()) {
        return 0;
    }
    const jlong value = QJniObject::callStaticMethod<jlong>(kAndroidRuntimeBridgeClass, "rxBytes", "()J");
    return value > 0 ? static_cast<qint64>(value) : 0;
}

qint64 bridgeTxBytes()
{
    if (!bridgeAvailable()) {
        return 0;
    }
    const jlong value = QJniObject::callStaticMethod<jlong>(kAndroidRuntimeBridgeClass, "txBytes", "()J");
    return value > 0 ? static_cast<qint64>(value) : 0;
}

QString bridgeConnect(const QString& executablePath, const QString& configPath, const QString& workingDirectory)
{
    if (!bridgeAvailable()) {
        return QString::fromUtf8("Android runtime bridge class is missing from the APK.");
    }

    const QJniObject executable = QJniObject::fromString(executablePath);
    const QJniObject config = QJniObject::fromString(configPath);
    const QJniObject working = QJniObject::fromString(workingDirectory);
    QJniObject errorObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "connect",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
        executable.object<jstring>(),
        config.object<jstring>(),
        working.object<jstring>());
    return errorObject.isValid() ? errorObject.toString().trimmed() : QString();
}

QString bridgeDisconnect()
{
    if (!bridgeAvailable()) {
        return QString::fromUtf8("Android runtime bridge class is missing from the APK.");
    }

    QJniObject errorObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "disconnect",
        "()Ljava/lang/String;");
    return errorObject.isValid() ? errorObject.toString().trimmed() : QString();
}
#endif

bool isVpnPermissionRequiredMessage(const QString& message)
{
    return message.contains(QString::fromUtf8("Android VPN permission is required"), Qt::CaseInsensitive)
        || message.contains(QString::fromUtf8("Android VPN permission prompt is already pending"), Qt::CaseInsensitive)
        || message.contains(QString::fromUtf8("Android VPN permission is still not granted"), Qt::CaseInsensitive);
}

QString sanitizePermissionDiagnostic(QString message)
{
    message.replace(QRegularExpression(QString::fromUtf8("\\s*\\[attempt=[^\\]]+\\]")),
                    QString());
    return message.trimmed();
}
} // namespace

AndroidVpnRuntime::AndroidVpnRuntime(QObject *parent)
    : VpnRuntimeBackend(parent)
{
}

AndroidVpnRuntime::~AndroidVpnRuntime() = default;

QString AndroidVpnRuntime::backendName() const
{
    return QString::fromUtf8("android");
}

VpnRuntimeCapabilities AndroidVpnRuntime::capabilities() const
{
    VpnRuntimeCapabilities caps;
    caps.isMobile = true;
    caps.isDesktop = false;
    caps.supportsTun = true;
    caps.supportsSystemProxy = false;
    caps.supportsPerAppRouting = true;
    caps.supportsAutoUpdate = true;
    caps.requiresVpnPermission = true;
    caps.requiresForegroundService = true;
    caps.requiresNetworkExtension = false;
    return caps;
}

bool AndroidVpnRuntime::initialize(QString *errorMessage)
{
    m_lastError.clear();
    if (errorMessage) {
        errorMessage->clear();
    }
#if defined(Q_OS_ANDROID)
    if (!bridgeAvailable()) {
        m_lastError = QString::fromUtf8("Android runtime bridge is not packaged into the APK.");
        if (errorMessage) {
            *errorMessage = m_lastError;
        }
        emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
        return false;
    }
#endif
    return true;
}

bool AndroidVpnRuntime::connectRuntime(
    const QString& executablePath,
    const QString& configPath,
    const QString& workingDirectory,
    QString *errorMessage)
{
    const QString normalizedConfigPath = configPath.trimmed();
    if (normalizedConfigPath.isEmpty() || !QFileInfo::exists(normalizedConfigPath)) {
        m_lastError = QString::fromUtf8(
            "Generated runtime config is missing. Select a profile and retry.");
        if (errorMessage) {
            *errorMessage = m_lastError;
        }
        emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
        emit errorOccurred(m_lastError);
        return false;
    }

#if !defined(Q_OS_ANDROID)
    m_lastError = QString::fromUtf8("Android runtime backend is only available on Android targets.");
    if (errorMessage) {
        *errorMessage = m_lastError;
    }
    emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
    emit errorOccurred(m_lastError);
    return false;
#else
    const QString normalizedExecutablePath = executablePath.trimmed();
    if (!normalizedExecutablePath.isEmpty() && !QFileInfo::exists(normalizedExecutablePath)) {
        emit logLine(QString::fromUtf8(
            "[Android] Requested xray path is missing; runtime will try bundled asset fallback."));
    }

    if (bridgeIsRunning()) {
        m_running = true;
        m_lastError.clear();
        if (errorMessage) {
            errorMessage->clear();
        }
        return true;
    }

    const QString startError = bridgeConnect(normalizedExecutablePath, normalizedConfigPath, workingDirectory.trimmed());
    if (!startError.isEmpty()) {
        m_lastError = startError.trimmed();
        if (errorMessage) {
            *errorMessage = m_lastError;
        }
        if (isVpnPermissionRequiredMessage(m_lastError)) {
            emit logLine(QString::fromUtf8("[Android] %1").arg(sanitizePermissionDiagnostic(m_lastError)));
            return false;
        }
        emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
        emit errorOccurred(m_lastError);
        return false;
    }

    QElapsedTimer waitTimer;
    waitTimer.start();
    while (waitTimer.elapsed() < 5000) {
        if (bridgeIsRunning()) {
            m_running = true;
            m_lastError.clear();
            if (errorMessage) {
                errorMessage->clear();
            }
            emit logLine(QString::fromUtf8("[Android] VPN service started."));
            emit started();
            emit trafficChanged();
            return true;
        }
        QThread::msleep(80);
    }

    m_running = false;
    m_lastError = bridgeLastError();
    if (m_lastError.isEmpty()) {
        m_lastError = QString::fromUtf8("Android VPN service failed to enter running state.");
    }
    if (errorMessage) {
        *errorMessage = m_lastError;
    }
    emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
    emit errorOccurred(m_lastError);
    return false;
#endif
}

bool AndroidVpnRuntime::disconnectRuntime(QString *errorMessage, int timeoutMs)
{
    Q_UNUSED(timeoutMs)

    if (!isRunning()) {
        m_running = false;
        if (errorMessage) {
            errorMessage->clear();
        }
        return true;
    }

#if !defined(Q_OS_ANDROID)
    m_running = false;
    if (errorMessage) {
        errorMessage->clear();
    }
    emit stopped(0, QProcess::NormalExit);
    emit trafficChanged();
    return true;
#else
    const QString stopError = bridgeDisconnect();
    if (!stopError.isEmpty()) {
        m_lastError = stopError;
        if (errorMessage) {
            *errorMessage = m_lastError;
        }
        emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
        emit errorOccurred(m_lastError);
        return false;
    }

    QElapsedTimer waitTimer;
    waitTimer.start();
    while (waitTimer.elapsed() < 4000) {
        if (!bridgeIsRunning()) {
            m_running = false;
            if (errorMessage) {
                errorMessage->clear();
            }
            emit stopped(0, QProcess::NormalExit);
            emit trafficChanged();
            return true;
        }
        QThread::msleep(80);
    }

    m_lastError = QString::fromUtf8("Android VPN service did not stop cleanly.");
    if (errorMessage) {
        *errorMessage = m_lastError;
    }
    emit logLine(QString::fromUtf8("[Android] %1").arg(m_lastError));
    emit errorOccurred(m_lastError);
    return false;
#endif
}

bool AndroidVpnRuntime::isRunning() const
{
#if defined(Q_OS_ANDROID)
    return bridgeIsRunning();
#else
    return m_running;
#endif
}

qint64 AndroidVpnRuntime::processId() const
{
    return isRunning() ? static_cast<qint64>(QCoreApplication::applicationPid()) : -1;
}

qint64 AndroidVpnRuntime::rxBytes() const
{
#if defined(Q_OS_ANDROID)
    return bridgeRxBytes();
#else
    return 0;
#endif
}

qint64 AndroidVpnRuntime::txBytes() const
{
#if defined(Q_OS_ANDROID)
    return bridgeTxBytes();
#else
    return 0;
#endif
}

QString AndroidVpnRuntime::lastError() const
{
    return m_lastError;
}

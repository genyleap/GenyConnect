module;
#include <QDesktopServices>
#include <QUrl>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

module genyconnect.backend.platformactionservice;

namespace {

#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";
#endif

} // namespace

bool PlatformActionService::openSystemProxySettings()
{
#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        return QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "openSystemProxySettings",
            "()Z");
    }
#endif
    return false;
}

bool PlatformActionService::openUrlWithChooser(const QString& url, const QString& chooserTitle)
{
    const QUrl parsedUrl = QUrl::fromUserInput(url.trimmed());
    if (!parsedUrl.isValid() || parsedUrl.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QString chooser = chooserTitle.trimmed().isEmpty()
            ? QString::fromUtf8("Choose wallet app")
            : chooserTitle.trimmed();
        const QJniObject urlObject = QJniObject::fromString(parsedUrl.toString(QUrl::FullyEncoded));
        const QJniObject chooserObject = QJniObject::fromString(chooser);
        const jboolean opened = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "openUrlWithChooser",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            urlObject.object<jstring>(),
            chooserObject.object<jstring>());
        if (opened) {
            return true;
        }
    }
#endif

    return QDesktopServices::openUrl(parsedUrl);
}

bool PlatformActionService::openUrlInAndroidPackage(const QString& url, const QString& packageName)
{
    const QUrl parsedUrl = QUrl::fromUserInput(url.trimmed());
    const QString packageId = packageName.trimmed();
    if (!parsedUrl.isValid() || parsedUrl.isEmpty() || packageId.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject urlObject = QJniObject::fromString(parsedUrl.toString(QUrl::FullyEncoded));
        const QJniObject packageObject = QJniObject::fromString(packageId);
        const jboolean opened = QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "openUrlInPackage",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            urlObject.object<jstring>(),
            packageObject.object<jstring>());
        if (opened) {
            return true;
        }
    }
#else
    Q_UNUSED(parsedUrl);
#endif

    return false;
}

bool PlatformActionService::isAndroidPackageInstalled(const QString& packageName)
{
    const QString packageId = packageName.trimmed();
    if (packageId.isEmpty()) {
        return false;
    }

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        const QJniObject packageObject = QJniObject::fromString(packageId);
        return QJniObject::callStaticMethod<jboolean>(
            kAndroidRuntimeBridgeClass,
            "isPackageInstalled",
            "(Ljava/lang/String;)Z",
            packageObject.object<jstring>());
    }
#endif

    return false;
}

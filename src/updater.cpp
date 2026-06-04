module;
#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QEventLoop>
#include <QFile>
#include <QByteArrayView>
#include <QFileInfo>
#include <QFileDevice>
#include <QCryptographicHash>
#include <QFutureWatcher>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QStringList>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTemporaryFile>
#include <QTimer>
#include <QUrl>
#include <QVector>
#include <QVariantMap>
#include <QtConcurrent/QtConcurrentRun>

#include <limits>

#if defined(Q_OS_ANDROID)
#include <QJniObject>
#endif

#if defined(Q_OS_WIN)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

#if !defined(Q_OS_IOS)
#include <QProcess>
#endif

module genyconnect.backend.updater;

void Updater::__geny_vtable_anchor() {}

namespace {
const QUrl kReleaseApiUrl(QString::fromUtf8("https://api.github.com/repos/genyleap/GenyConnect/releases/latest"));
const QString kReleasesPageUrl = QString::fromUtf8("https://github.com/genyleap/GenyConnect/releases");
#if defined(Q_OS_ANDROID)
constexpr const char kAndroidRuntimeBridgeClass[] = "com/genyleap/genyconnect/AndroidRuntimeBridge";

QVariantMap parseAndroidBridgeResult(const QJniObject& jsonObject, const QString& emptyError)
{
    QVariantMap result;
    result.insert(QString::fromUtf8("ok"), false);
    result.insert(QString::fromUtf8("payload"), QString());
    result.insert(QString::fromUtf8("error"), emptyError);

    const QString jsonText = jsonObject.toString().trimmed();
    if (jsonText.isEmpty()) {
        return result;
    }

    const QJsonDocument document = QJsonDocument::fromJson(jsonText.toUtf8());
    if (!document.isObject()) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Android bridge returned an invalid response."));
        return result;
    }

    const QVariantMap parsed = document.object().toVariantMap();
    if (!parsed.contains(QString::fromUtf8("ok"))) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Android bridge returned an incomplete response."));
        return result;
    }
    return parsed;
}

QVariantMap fetchTextViaAndroidBridge(const QUrl& url, int timeoutMs)
{
    QVariantMap result;
    result.insert(QString::fromUtf8("ok"), false);
    result.insert(QString::fromUtf8("payload"), QString());

    if (!url.isValid() || url.isEmpty()) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Invalid URL."));
        return result;
    }
    if (!QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Android runtime bridge is unavailable."));
        return result;
    }

    const QJniObject urlObject = QJniObject::fromString(url.toString(QUrl::FullyEncoded));
    const jint safeTimeoutMs = static_cast<jint>(qMin(45000, qMax(2000, timeoutMs)));
    const QJniObject jsonObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "fetchSubscriptionText",
        "(Ljava/lang/String;I)Ljava/lang/String;",
        urlObject.object<jstring>(),
        safeTimeoutMs);
    return parseAndroidBridgeResult(
        jsonObject,
        QString::fromUtf8("Android bridge returned an empty response."));
}

QVariantMap downloadFileViaAndroidBridge(const QUrl& url, const QString& outputPath, int timeoutMs)
{
    QVariantMap result;
    result.insert(QString::fromUtf8("ok"), false);
    result.insert(QString::fromUtf8("error"), QString::fromUtf8("Download failed."));

    if (!url.isValid() || url.isEmpty() || outputPath.trimmed().isEmpty()) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Invalid download request."));
        return result;
    }
    if (!QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        result.insert(QString::fromUtf8("error"), QString::fromUtf8("Android runtime bridge is unavailable."));
        return result;
    }

    const QJniObject urlObject = QJniObject::fromString(url.toString(QUrl::FullyEncoded));
    const QJniObject pathObject = QJniObject::fromString(outputPath);
    const jint safeTimeoutMs = static_cast<jint>(qMin(90000, qMax(5000, timeoutMs)));
    const QJniObject jsonObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "downloadFileToPath",
        "(Ljava/lang/String;Ljava/lang/String;I)Ljava/lang/String;",
        urlObject.object<jstring>(),
        pathObject.object<jstring>(),
        safeTimeoutMs);
    return parseAndroidBridgeResult(
        jsonObject,
        QString::fromUtf8("Android bridge returned an empty download response."));
}
#endif

QString normalizeVersionToken(const QString& version)
{
    QString cleaned = version.trimmed();
    if (cleaned.startsWith(QString::fromUtf8("v"), Qt::CaseInsensitive)) {
        cleaned.remove(0, 1);
    }
    return cleaned;
}

QString normalizeSha256Digest(const QString& digest)
{
    QString value = digest.trimmed().toLower();
    if (value.startsWith(QString::fromUtf8("sha256:"))) {
        value.remove(0, QString::fromUtf8("sha256:").size());
    }
    static const QRegularExpression hex64Rx(QString::fromUtf8("^[0-9a-f]{64}$"));
    return hex64Rx.match(value).hasMatch() ? value : QString();
}

bool isLikelyChecksumAsset(const QString& lowerAssetName)
{
    return lowerAssetName.contains(QString::fromUtf8("sha256"))
        || lowerAssetName.contains(QString::fromUtf8("checksum"))
        || lowerAssetName.endsWith(QString::fromUtf8(".sha256"))
        || lowerAssetName.endsWith(QString::fromUtf8(".sha256.txt"))
        || lowerAssetName.endsWith(QString::fromUtf8("checksums.txt"));
}

QString extractSha256FromManifest(const QByteArray& content, const QString& targetAssetName)
{
    const QString targetName = QFileInfo(targetAssetName.trimmed()).fileName().toLower();
    const QString text = QString::fromUtf8(content);
    const QStringList lines = text.split('\n');
    static const QRegularExpression hashAndNameRx(
        QString::fromUtf8("^([0-9A-Fa-f]{64})\\s+\\*?(.+)$"));
    static const QRegularExpression sha256StyleRx(
        QString::fromUtf8("^SHA256\\s*\\((.+)\\)\\s*=\\s*([0-9A-Fa-f]{64})$"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression hashOnlyRx(QString::fromUtf8("^[0-9A-Fa-f]{64}$"));

    QString hashOnlyCandidate;
    int meaningfulLines = 0;
    for (const QString& raw : lines) {
        const QString line = raw.trimmed();
        if (line.isEmpty() || line.startsWith('#')) {
            continue;
        }
        ++meaningfulLines;

        const QRegularExpressionMatch pairMatch = hashAndNameRx.match(line);
        if (pairMatch.hasMatch()) {
            const QString hash = normalizeSha256Digest(pairMatch.captured(1));
            const QString fileName = QFileInfo(pairMatch.captured(2).trimmed()).fileName().toLower();
            if (!hash.isEmpty() && !fileName.isEmpty() && fileName == targetName) {
                return hash;
            }
            continue;
        }

        const QRegularExpressionMatch styleMatch = sha256StyleRx.match(line);
        if (styleMatch.hasMatch()) {
            const QString hash = normalizeSha256Digest(styleMatch.captured(2));
            const QString fileName = QFileInfo(styleMatch.captured(1).trimmed()).fileName().toLower();
            if (!hash.isEmpty() && !fileName.isEmpty() && fileName == targetName) {
                return hash;
            }
            continue;
        }

        if (hashOnlyRx.match(line).hasMatch()) {
            hashOnlyCandidate = normalizeSha256Digest(line);
        }
    }

    if (meaningfulLines == 1) {
        return hashOnlyCandidate;
    }
    return {};
}

bool fetchUrlContentSync(
    QNetworkAccessManager* manager,
    const QUrl& url,
    QByteArray *contentOut,
    QString *errorOut,
    int timeoutMs = 12000)
{
    if (manager == nullptr || contentOut == nullptr || !url.isValid() || url.isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QString::fromUtf8("Invalid checksum URL.");
        }
        return false;
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-Updater/1.0");
    request.setTransferTimeout(timeoutMs);

    QNetworkReply* reply = manager->get(request);
    QEventLoop loop;
    QTimer timer;
    timer.setSingleShot(true);
    bool timedOut = false;

    QObject::connect(&timer, &QTimer::timeout, &loop, [&]() {
        timedOut = true;
        if (reply != nullptr) {
            reply->abort();
        }
        loop.quit();
    });
    QObject::connect(reply, &QNetworkReply::finished, &loop, [&]() {
        loop.quit();
    });

    timer.start(qMax(1000, timeoutMs));
    loop.exec();

    const bool hadError = timedOut || (reply->error() != QNetworkReply::NoError);
    QString errorText;
    if (timedOut) {
        errorText = QString::fromUtf8("Checksum download timed out.");
    } else if (hadError) {
        errorText = reply->errorString().trimmed();
    }

    QByteArray payload;
    if (!hadError) {
        payload = reply->readAll();
    }
    reply->deleteLater();

    if (hadError) {
        if (errorOut != nullptr) {
            *errorOut = errorText.isEmpty()
                ? QString::fromUtf8("Checksum download failed.")
                : errorText;
        }
        return false;
    }

    *contentOut = payload;
    return true;
}

QVector<int> parseVersionParts(const QString& version)
{
    QVector<int> parts;
    const QRegularExpression numberRx(QString::fromUtf8("(\\d+)"));
    QRegularExpressionMatchIterator it = numberRx.globalMatch(version);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        parts.append(m.captured(1).toInt());
    }
    return parts;
}

QString appUpdaterHelperPath()
{
#if defined(Q_OS_IOS)
    return {};
#elif defined(Q_OS_WIN)
    return QDir(QCoreApplication::applicationDirPath()).filePath(QString::fromUtf8("GenyConnectUpdater.exe"));
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(QString::fromUtf8("GenyConnectUpdater"));
#endif
}

bool copyWithOverwrite(const QString& fromPath, const QString& toPath)
{
    if (QFileInfo::exists(toPath) && !QFile::remove(toPath)) {
        return false;
    }
    return QFile::copy(fromPath, toPath);
}

bool looksLikeManualInstaller(const QString& path)
{
    const QString lower = QFileInfo(path).fileName().toLower();
#if defined(Q_OS_WIN)
    const bool windowsInstallerExe = lower.endsWith(QString::fromUtf8(".exe"))
        && (lower.contains(QString::fromUtf8("setup"))
            || lower.contains(QString::fromUtf8("installer"))
            || lower.contains(QString::fromUtf8("install"))
            || lower.contains(QString::fromUtf8("nsis"))
            || lower.contains(QString::fromUtf8("inno")));
#else
    constexpr bool windowsInstallerExe = false;
#endif
    return lower.endsWith(QString::fromUtf8(".dmg"))
        || lower.endsWith(QString::fromUtf8(".pkg"))
        || windowsInstallerExe
        || lower.endsWith(QString::fromUtf8(".msi"))
        || lower.endsWith(QString::fromUtf8(".zip"))
        || lower.endsWith(QString::fromUtf8(".tar.gz"))
        || lower.endsWith(QString::fromUtf8(".tar.xz"))
        || lower.endsWith(QString::fromUtf8(".deb"))
        || lower.endsWith(QString::fromUtf8(".rpm"));
}

bool startUpdaterHelperDetached(const QString& helperPath, const QString& jobPath, QString *errorOut)
{
#if defined(Q_OS_IOS)
    Q_UNUSED(helperPath)
    Q_UNUSED(jobPath)

    if (errorOut != nullptr) {
        *errorOut = QString::fromUtf8("Self-update helper is not supported on iOS.");
    }
    return false;

#elif defined(Q_OS_WIN)
    const QString nativeHelper = QDir::toNativeSeparators(helperPath);
    const QString nativeJob = QDir::toNativeSeparators(jobPath);
    const bool launchedDirect = QProcess::startDetached(helperPath, {QString::fromUtf8("--job"), jobPath});
    if (launchedDirect) {
        return true;
    }

    const QString args = QString::fromUtf8("--job \"%1\"").arg(nativeJob);
    const int rc = static_cast<int>(reinterpret_cast<qintptr>(
        ShellExecuteW(
            nullptr,
            L"runas",
            reinterpret_cast<LPCWSTR>(nativeHelper.utf16()),
            reinterpret_cast<LPCWSTR>(args.utf16()),
            nullptr,
            SW_SHOWNORMAL
            )
        ));

    if (rc <= 32) {
        if (errorOut != nullptr) {
            *errorOut = (rc == 1223)
            ? QString::fromUtf8("Administrator permission was denied.")
            : QString::fromUtf8("Failed to launch updater helper (code %1).").arg(rc);
        }
        return false;
    }
    return true;

#else
    const bool launched = QProcess::startDetached(helperPath, {QString::fromUtf8("--job"), jobPath});
    if (!launched && errorOut != nullptr) {
        *errorOut = QString::fromUtf8("Failed to launch updater helper.");
    }
    return launched;
#endif
}

#if defined(Q_OS_ANDROID)
bool installDownloadedApkViaBridge(const QString& path, QString *errorOut)
{
    if (!QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        if (errorOut != nullptr) {
            *errorOut = QString::fromUtf8("Android runtime bridge is not packaged into the APK.");
        }
        return false;
    }

    const QJniObject sourcePath = QJniObject::fromString(path);
    const QJniObject errorObject = QJniObject::callStaticObjectMethod(
        kAndroidRuntimeBridgeClass,
        "installDownloadedApk",
        "(Ljava/lang/String;)Ljava/lang/String;",
        sourcePath.object<jstring>());
    const QString bridgeError = errorObject.isValid() ? errorObject.toString().trimmed() : QString();
    if (!bridgeError.isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = bridgeError;
        }
        return false;
    }
    return true;
}
#endif
}

Updater::Updater(QObject *parent)
    : QObject(parent)
{
    m_releaseUrl = kReleasesPageUrl;
    const QString runtimeVersion = QCoreApplication::applicationVersion().trimmed();
    if (!runtimeVersion.isEmpty()) {
        m_appVersion = runtimeVersion;
    }
    consumePendingUpdateStatus();
}

Updater::~Updater()
{
    if (m_checkReply != nullptr) {
        QObject::disconnect(m_checkReply, nullptr, this, nullptr);
        m_checkReply->abort();
        m_checkReply->deleteLater();
        m_checkReply = nullptr;
    }
    if (m_downloadReply != nullptr) {
        QObject::disconnect(m_downloadReply, nullptr, this, nullptr);
        m_downloadReply->abort();
        m_downloadReply->deleteLater();
        m_downloadReply = nullptr;
    }
    if (m_downloadFile != nullptr) {
        if (m_downloadFile->isOpen()) {
            m_downloadFile->close();
        }
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
    }
}

QString Updater::appVersion() const
{
    return m_appVersion;
}

void Updater::setAppVersion(const QString& version)
{
    const QString normalized = version.trimmed().isEmpty() ? QString::fromUtf8("0.0.0") : version.trimmed();
    if (m_appVersion == normalized) {
        return;
    }
    m_appVersion = normalized;
    emit changed();
}

bool Updater::checking() const
{
    return m_checking;
}

bool Updater::updateAvailable() const
{
    return m_updateAvailable;
}

QString Updater::latestVersion() const
{
    return m_latestVersion;
}

QString Updater::status() const
{
    return m_status;
}

QString Updater::error() const
{
    return m_error;
}

double Updater::downloadProgress() const
{
    if (m_downloadTotal <= 0) {
        return 0.0;
    }
    return qBound(
        0.0,
        static_cast<double>(m_downloadReceived) / static_cast<double>(m_downloadTotal),
        1.0
    );
}

QString Updater::releaseUrl() const
{
    return m_releaseUrl;
}

QString Updater::downloadedFilePath() const
{
    return m_downloadedFilePath;
}

bool Updater::canInstallDownloadedUpdate() const
{
#if defined(Q_OS_IOS)
    return false;
#elif defined(Q_OS_ANDROID)
    const QString path = m_downloadedFilePath.trimmed();
    return QFileInfo::exists(path) && path.toLower().endsWith(QString::fromUtf8(".apk"));
#else
    return isSelfInstallSupportedAsset(m_downloadedFilePath)
           && !normalizeSha256Digest(m_assetExpectedSha256).isEmpty();
#endif
}

void Updater::checkForUpdates(bool userInitiated)
{
    consumePendingUpdateStatus();

    if (m_checking || m_checkReply != nullptr || m_downloadReply != nullptr) {
        return;
    }

    m_userInitiatedCheck = userInitiated;
    m_checking = true;
    m_error.clear();
    m_status = QString::fromUtf8("Checking for updates...");
    emit changed();

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        auto* watcher = new QFutureWatcher<QVariantMap>(this);
        connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [this, watcher]() {
            const QVariantMap result = watcher->result();
            watcher->deleteLater();
            m_checking = false;

            const bool ok = result.value(QString::fromUtf8("ok")).toBool();
            const QString errorText = result.value(QString::fromUtf8("error")).toString().trimmed();
            const int statusCode = result.value(QString::fromUtf8("statusCode")).toInt();
            const QByteArray payload = result.value(QString::fromUtf8("payload")).toString().toUtf8();

            if (!ok) {
                if (statusCode == 404) {
                    m_updateAvailable = false;
                    m_latestVersion.clear();
                    m_assetUrl.clear();
                    m_assetName.clear();
                    m_assetExpectedSha256.clear();
                    m_assetChecksumUrl.clear();
                    m_downloadedFilePath.clear();
                    m_downloadReceived = 0;
                    m_downloadTotal = 0;
                    m_error.clear();
                    m_status = QString::fromUtf8("No published release yet. Current version %1.").arg(m_appVersion);
                    if (m_userInitiatedCheck) {
                        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
                    }
                    m_userInitiatedCheck = false;
                    emit changed();
                    return;
                }

                m_updateAvailable = false;
                m_assetExpectedSha256.clear();
                m_assetChecksumUrl.clear();
                m_error = errorText.isEmpty()
                    ? QString::fromUtf8("Failed to check updates.")
                    : errorText;
                m_status = QString::fromUtf8("Update check failed.");
                if (m_userInitiatedCheck) {
                    emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
                }
                m_userInitiatedCheck = false;
                emit changed();
                return;
            }

            QJsonParseError parseError;
            const QJsonDocument doc = QJsonDocument::fromJson(payload, &parseError);
            if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
                m_updateAvailable = false;
                m_assetExpectedSha256.clear();
                m_assetChecksumUrl.clear();
                m_error = QString::fromUtf8("Release metadata parse failed.");
                m_status = QString::fromUtf8("Update check failed.");
                m_userInitiatedCheck = false;
                emit changed();
                return;
            }

            const QJsonObject root = doc.object();
            const QString latestRaw = root.value(QString::fromUtf8("tag_name")).toString().trimmed();
            const QString latest = normalizeVersionToken(latestRaw);
            m_releaseUrl = root.value(QString::fromUtf8("html_url")).toString().trimmed();
            m_latestVersion = latest;
            m_error.clear();
            m_assetUrl.clear();
            m_assetName.clear();
            m_assetExpectedSha256.clear();
            m_assetChecksumUrl.clear();
            m_downloadedFilePath.clear();
            m_downloadReceived = 0;
            m_downloadTotal = 0;

            const QJsonArray assets = root.value(QString::fromUtf8("assets")).toArray();
            QStringList assetDiagnostics;
            selectBestReleaseAsset(assets, &m_assetUrl, &m_assetName, &m_assetExpectedSha256, &m_assetChecksumUrl, &assetDiagnostics);
            for (const QString& line : assetDiagnostics) {
                emit systemLog(line);
            }
            if (!m_assetName.isEmpty()) {
                emit systemLog(QString::fromUtf8("[Updater] Selected asset: %1").arg(m_assetName));
                if (!m_assetExpectedSha256.isEmpty()) {
                    emit systemLog(QString::fromUtf8("[Updater] Found release digest for selected asset."));
                } else if (!m_assetChecksumUrl.isEmpty()) {
                    emit systemLog(QString::fromUtf8("[Updater] Using checksum manifest for selected asset."));
                } else {
                    emit systemLog(QString::fromUtf8(
                        "[Updater] No checksum metadata for selected asset. Install will require a published SHA-256."));
                }
            }

            if (latest.isEmpty()) {
                m_updateAvailable = false;
                m_status = QString::fromUtf8("No version info in release feed.");
            } else if (isVersionNewer(m_appVersion, latest)) {
                m_updateAvailable = true;
                m_status = QString::fromUtf8("Update available: %1").arg(latest);
                emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
            } else {
                m_updateAvailable = false;
                m_status = QString::fromUtf8("You are up to date (%1).").arg(m_appVersion);
                if (m_userInitiatedCheck) {
                    emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
                }
            }

            m_userInitiatedCheck = false;
            emit changed();
        });
        watcher->setFuture(QtConcurrent::run([]() {
            return fetchTextViaAndroidBridge(kReleaseApiUrl, 12000);
        }));
        return;
    }
#endif

    QNetworkRequest request(kReleaseApiUrl);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-Updater/1.0");
    request.setRawHeader("Accept", "application/vnd.github+json");
    request.setTransferTimeout(12000);

    m_checkReply = m_networkManager.get(request);
    connect(m_checkReply, &QNetworkReply::finished, this, &Updater::onCheckFinished);
}

void Updater::consumePendingUpdateStatus()
{
    const QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (appDataDir.trimmed().isEmpty()) {
        return;
    }

    QDir updatesDir(QDir(appDataDir).filePath(QString::fromUtf8("updates")));
    if (!updatesDir.exists()) {
        return;
    }

    const QFileInfoList statusFiles = updatesDir.entryInfoList(
        QStringList() << QString::fromUtf8("update-job-*.json.status.json"),
        QDir::Files,
        QDir::Time | QDir::Reversed
    );
    if (statusFiles.isEmpty()) {
        return;
    }

    const QFileInfo latest = statusFiles.last();
    QFile statusFile(latest.absoluteFilePath());
    if (!statusFile.open(QIODevice::ReadOnly)) {
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(statusFile.readAll(), &parseError);
    statusFile.close();
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        QFile::remove(latest.absoluteFilePath());
        return;
    }

    const QJsonObject root = doc.object();
    const bool ok = root.value(QString::fromUtf8("ok")).toBool(false);
    const QString message = root.value(QString::fromUtf8("message")).toString().trimmed();
    if (ok) {
        m_error.clear();
        m_status = message.isEmpty()
            ? QString::fromUtf8("Update applied successfully.")
            : QString::fromUtf8("Update: %1").arg(message);
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
    } else {
        m_error = message.isEmpty()
            ? QString::fromUtf8("Updater helper failed.")
            : message;
        m_status = QString::fromUtf8("Install failed.");
        emit systemLog(QString::fromUtf8("[Updater] Install failed: %1").arg(m_error));
    }
    emit changed();

    for (const QFileInfo& fileInfo : statusFiles) {
        QFile::remove(fileInfo.absoluteFilePath());
    }
}

bool Updater::downloadUpdate()
{
    if (m_checking || m_downloadReply != nullptr) {
        return false;
    }

    if (!m_updateAvailable || m_assetUrl.trimmed().isEmpty()) {
        m_error = QString::fromUtf8("No downloadable update asset is available.");
        m_status = QString::fromUtf8("Download unavailable.");
        emit changed();
        return false;
    }

    const QString downloadsDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString baseDir = downloadsDir.isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        : downloadsDir;
    if (baseDir.isEmpty()) {
        m_error = QString::fromUtf8("Could not resolve download directory.");
        m_status = QString::fromUtf8("Download failed.");
        emit changed();
        return false;
    }

    QDir().mkpath(baseDir);
    const QString fallbackName = QString::fromUtf8("genyconnect-update-%1.bin")
        .arg(m_latestVersion.isEmpty() ? QString::fromUtf8("latest") : m_latestVersion);
    const QString fileName = m_assetName.trimmed().isEmpty() ? fallbackName : m_assetName.trimmed();
    m_downloadedFilePath = QDir(baseDir).filePath(fileName);

    if (m_downloadFile != nullptr) {
        if (m_downloadFile->isOpen()) {
            m_downloadFile->close();
        }
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
    }

    m_downloadReceived = 0;
    m_downloadTotal = 0;
    m_checking = true;
    m_error.clear();
    m_status = QString::fromUtf8("Downloading update...");
    emit changed();

#if defined(Q_OS_ANDROID)
    if (QJniObject::isClassAvailable(kAndroidRuntimeBridgeClass)) {
        emit systemLog(QString::fromUtf8("[Updater] Downloading %1").arg(fileName));

        const QString assetUrl = m_assetUrl;
        const QString outputPath = m_downloadedFilePath;
        auto* watcher = new QFutureWatcher<QVariantMap>(this);
        connect(watcher, &QFutureWatcher<QVariantMap>::finished, this, [this, watcher, outputPath]() {
            const QVariantMap result = watcher->result();
            watcher->deleteLater();
            m_checking = false;

            const bool ok = result.value(QString::fromUtf8("ok")).toBool();
            const QString errorText = result.value(QString::fromUtf8("error")).toString().trimmed();
            if (!ok || !QFileInfo::exists(outputPath)) {
                QFile::remove(outputPath);
                m_error = errorText.isEmpty()
                    ? QString::fromUtf8("Update download failed.")
                    : errorText;
                m_status = QString::fromUtf8("Download failed.");
                emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
                emit changed();
                return;
            }

            if (m_assetExpectedSha256.isEmpty() && !m_assetChecksumUrl.trimmed().isEmpty() && !m_assetName.trimmed().isEmpty()) {
                const QVariantMap checksumResult = fetchTextViaAndroidBridge(QUrl(m_assetChecksumUrl), 12000);
                if (checksumResult.value(QString::fromUtf8("ok")).toBool()) {
                    const QString extracted = extractSha256FromManifest(
                        checksumResult.value(QString::fromUtf8("payload")).toString().toUtf8(),
                        m_assetName);
                    if (!extracted.isEmpty()) {
                        m_assetExpectedSha256 = extracted;
                        emit systemLog(QString::fromUtf8("[Updater] Checksum resolved from manifest for %1.").arg(m_assetName));
                    } else {
                        emit systemLog(QString::fromUtf8("[Updater] Checksum manifest did not include %1.").arg(m_assetName));
                    }
                } else {
                    const QString checksumError = checksumResult.value(QString::fromUtf8("error")).toString().trimmed();
                    if (!checksumError.isEmpty()) {
                        emit systemLog(QString::fromUtf8("[Updater] Checksum fetch failed: %1").arg(checksumError));
                    }
                }
            }

            if (!m_assetExpectedSha256.isEmpty()) {
                const QString downloadedHash = fileSha256Hex(outputPath).toLower();
                if (downloadedHash.isEmpty() || downloadedHash != m_assetExpectedSha256) {
                    QFile::remove(outputPath);
                    m_error = QString::fromUtf8("Downloaded update hash verification failed.");
                    m_status = QString::fromUtf8("Download failed.");
                    emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
                    emit changed();
                    return;
                }
                emit systemLog(QString::fromUtf8("[Updater] Downloaded file hash verified."));
            }

            m_error.clear();
            if (m_assetExpectedSha256.isEmpty()) {
                m_status = QString::fromUtf8("Update downloaded, but release checksum is missing.");
            } else {
                m_status = QString::fromUtf8("Update downloaded. Open installer to continue.");
            }
            m_downloadReceived = 1;
            m_downloadTotal = 1;
            emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
            emit changed();
        });
        watcher->setFuture(QtConcurrent::run([assetUrl, outputPath]() {
            return downloadFileViaAndroidBridge(QUrl(assetUrl), outputPath, 60000);
        }));
        return true;
    }
#endif

    m_downloadFile = new QFile(m_downloadedFilePath, this);
    if (!m_downloadFile->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        m_error = QString::fromUtf8("Failed to create update file: %1").arg(m_downloadedFilePath);
        m_status = QString::fromUtf8("Download failed.");
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
        m_checking = false;
        emit changed();
        return false;
    }

    QNetworkRequest request {QUrl(m_assetUrl)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-Updater/1.0");
    request.setTransferTimeout(30000);

    m_downloadReply = m_networkManager.get(request);
    connect(m_downloadReply, &QNetworkReply::readyRead, this, &Updater::onDownloadReadyRead);
    connect(m_downloadReply, &QNetworkReply::downloadProgress, this, &Updater::onDownloadProgress);
    connect(m_downloadReply, &QNetworkReply::finished, this, &Updater::onDownloadFinished);

    emit systemLog(QString::fromUtf8("[Updater] Downloading %1").arg(fileName));
    return true;
}

bool Updater::openDownloadedUpdate()
{
    const QString path = m_downloadedFilePath.trimmed();
    if (path.isEmpty() || !QFileInfo::exists(path)) {
        m_error = QString::fromUtf8("Downloaded update file was not found.");
        m_status = QString::fromUtf8("Open installer failed.");
        emit changed();
        return false;
    }

#if defined(Q_OS_WIN)
    if (looksLikeManualInstaller(path)) {
        const QString nativePath = QDir::toNativeSeparators(path);
        const QString delayedLaunchCommand = QString::fromUtf8(
            "ping 127.0.0.1 -n 2 > NUL && start \"\" \"%1\"").arg(nativePath);

        bool opened = QProcess::startDetached(
            QString::fromUtf8("cmd.exe"),
            {QString::fromUtf8("/C"), delayedLaunchCommand});
        if (!opened) {
            opened = QProcess::startDetached(path, QStringList());
        }
        if (!opened) {
            opened = QDesktopServices::openUrl(QUrl::fromLocalFile(path));
        }
        if (!opened) {
            m_error = QString::fromUtf8("Failed to open installer.");
            m_status = QString::fromUtf8("Open installer failed.");
            emit changed();
            return false;
        }

        m_error.clear();
        m_status = QString::fromUtf8("Closing app and launching installer...");
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
        emit changed();
        QTimer::singleShot(120, qApp, []() { QCoreApplication::quit(); });
        return true;
    }
#endif

    const bool opened = QDesktopServices::openUrl(QUrl::fromLocalFile(path));
    if (!opened) {
        m_error = QString::fromUtf8("Failed to open downloaded update.");
        m_status = QString::fromUtf8("Open installer failed.");
        emit changed();
        return false;
    }
    m_error.clear();
    return true;
}

bool Updater::installDownloadedUpdate()
{
    const QString sourcePath = m_downloadedFilePath.trimmed();
    if (sourcePath.isEmpty() || !QFileInfo::exists(sourcePath)) {
        m_error = QString::fromUtf8("Downloaded update file was not found.");
        m_status = QString::fromUtf8("Install failed.");
        emit changed();
        return false;
    }

    if (looksLikeManualInstaller(sourcePath)) {
        m_status = QString::fromUtf8("This asset requires manual install. Opening installer...");
        m_error.clear();
        emit changed();
        return openDownloadedUpdate();
    }

    const QString expectedSha256 = normalizeSha256Digest(m_assetExpectedSha256);
#if !defined(Q_OS_ANDROID)
    if (expectedSha256.isEmpty()) {
        m_error = QString::fromUtf8(
            "Release does not provide trusted SHA-256 metadata for this asset. Publish digest/checksum first.");
        m_status = QString::fromUtf8("Install blocked.");
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }
#endif

    if (!expectedSha256.isEmpty()) {
        const QString downloadedHash = fileSha256Hex(sourcePath).toLower();
        if (downloadedHash.isEmpty() || downloadedHash != expectedSha256) {
            m_error = QString::fromUtf8("Downloaded update hash verification failed.");
            m_status = QString::fromUtf8("Install failed.");
            emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
            emit changed();
            return false;
        }
    }

#if defined(Q_OS_ANDROID)
    QString installError;
    if (!installDownloadedApkViaBridge(sourcePath, &installError)) {
        m_error = installError.isEmpty()
            ? QString::fromUtf8("Failed to open Android package installer.")
            : installError;
        m_status = QString::fromUtf8("Install failed.");
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }

    m_error.clear();
    m_status = QString::fromUtf8("Opened package installer. Confirm update to continue.");
    emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
    emit changed();
    return true;
#endif

    const QString helperPath = appUpdaterHelperPath();
    if (!QFileInfo::exists(helperPath)) {
        m_error = QString::fromUtf8("Updater helper executable not found.");
        m_status = QString::fromUtf8("Install failed.");
        emit changed();
        return false;
    }

    const QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (appDir.trimmed().isEmpty()) {
        m_error = QString::fromUtf8("Could not resolve app data directory.");
        m_status = QString::fromUtf8("Install failed.");
        emit changed();
        return false;
    }

    const QString updateDir = QDir(appDir).filePath(QString::fromUtf8("updates"));
    QDir().mkpath(updateDir);

    const QString sourceName = QFileInfo(sourcePath).fileName();
    const QString stagedPath = QDir(updateDir).filePath(QString::fromUtf8("staged-%1").arg(sourceName));
    if (!copyWithOverwrite(sourcePath, stagedPath)) {
        m_error = QString::fromUtf8("Failed to stage update file.");
        m_status = QString::fromUtf8("Install failed.");
        emit changed();
        return false;
    }

    const QString currentExe = QCoreApplication::applicationFilePath();
#if defined(Q_OS_WIN)
    bool installDirWritable = true;
    {
        const QString exeDir = QFileInfo(currentExe).absolutePath();
        QTemporaryFile probe(QDir(exeDir).filePath(QString::fromUtf8(".__geny_write_probe_XXXXXX.tmp")));
        probe.setAutoRemove(true);
        if (!probe.open()) {
            installDirWritable = false;
            emit systemLog(QString::fromUtf8(
                "[Updater] Install folder is not writable. Will request Administrator permission."));
        } else {
            probe.close();
        }
    }
#endif
    const QString backupPath = currentExe + QString::fromUtf8(".backup.old");
    const QString jobPath = QDir(updateDir).filePath(
        QString::fromUtf8("update-job-%1.json").arg(QString::number(QDateTime::currentMSecsSinceEpoch()))
    );

    QJsonObject job;
    job.insert(QString::fromUtf8("pid"), static_cast<qint64>(QCoreApplication::applicationPid()));
    job.insert(QString::fromUtf8("current_executable"), currentExe);
    job.insert(QString::fromUtf8("staged_executable"), stagedPath);
    job.insert(QString::fromUtf8("backup_executable"), backupPath);
    job.insert(QString::fromUtf8("working_directory"), QCoreApplication::applicationDirPath());
    job.insert(QString::fromUtf8("expected_sha256"), expectedSha256);
    job.insert(QString::fromUtf8("cleanup_source_on_success"), true);
    job.insert(QString::fromUtf8("timeout_ms"), 45000);
    job.insert(QString::fromUtf8("args"), QJsonArray());

    QFile jobFile(jobPath);
    if (!jobFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QFile::remove(stagedPath);
        m_error = QString::fromUtf8("Failed to write update job file.");
        m_status = QString::fromUtf8("Install failed.");
        emit changed();
        return false;
    }
    jobFile.write(QJsonDocument(job).toJson(QJsonDocument::Indented));
    jobFile.close();

    QString launchError;
    if (!startUpdaterHelperDetached(helperPath, jobPath, &launchError)) {
        QFile::remove(jobPath);
        QFile::remove(stagedPath);
        m_error = launchError.isEmpty() ? QString::fromUtf8("Failed to launch updater helper.") : launchError;
        m_status = QString::fromUtf8("Install failed.");
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }

    m_error.clear();
#if defined(Q_OS_WIN)
    if (!installDirWritable) {
        m_status = QString::fromUtf8("Waiting for Administrator approval to install update...");
    } else {
        m_status = QString::fromUtf8("Installing update and restarting...");
    }
#else
    m_status = QString::fromUtf8("Installing update and restarting...");
#endif
    emit systemLog(QString::fromUtf8("[Updater] Handed off update to helper process."));
    emit changed();

    QTimer::singleShot(250, qApp, []() { QCoreApplication::quit(); });
    return true;
}

bool Updater::openReleasePage()
{
    if (m_releaseUrl.trimmed().isEmpty()) {
        return QDesktopServices::openUrl(QUrl(kReleasesPageUrl));
    }
    return QDesktopServices::openUrl(QUrl(m_releaseUrl));
}

void Updater::onCheckFinished()
{
    if (m_checkReply == nullptr) {
        return;
    }

    QNetworkReply *reply = m_checkReply;
    m_checkReply = nullptr;
    m_checking = false;

    const bool hadError = (reply->error() != QNetworkReply::NoError);
    const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray payload;
    if (reply->isOpen()) {
        payload = reply->readAll();
    }
    const QString networkError = reply->errorString().trimmed();
    reply->deleteLater();

    if (hadError) {
        QJsonParseError statusParseError;
        const QJsonDocument statusDoc = QJsonDocument::fromJson(payload, &statusParseError);
        QString apiMessage;
        if (statusParseError.error == QJsonParseError::NoError && statusDoc.isObject()) {
            apiMessage = statusDoc.object().value(QString::fromUtf8("message")).toString().trimmed();
        }

        if (statusCode == 404 || apiMessage.compare(QString::fromUtf8("Not Found"), Qt::CaseInsensitive) == 0) {
            m_updateAvailable = false;
            m_latestVersion.clear();
            m_assetUrl.clear();
            m_assetName.clear();
            m_assetExpectedSha256.clear();
            m_assetChecksumUrl.clear();
            m_downloadedFilePath.clear();
            m_downloadReceived = 0;
            m_downloadTotal = 0;
            m_error.clear();
            m_status = QString::fromUtf8("No published release yet. Current version %1.").arg(m_appVersion);
            if (m_userInitiatedCheck) {
                emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
            }
            m_userInitiatedCheck = false;
            emit changed();
            return;
        }

        m_updateAvailable = false;
        m_assetExpectedSha256.clear();
        m_assetChecksumUrl.clear();
        m_error = networkError.isEmpty()
            ? QString::fromUtf8("Failed to check updates.")
            : networkError;
        m_status = QString::fromUtf8("Update check failed.");
        if (m_userInitiatedCheck) {
            emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
        }
        m_userInitiatedCheck = false;
        emit changed();
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(payload, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        m_updateAvailable = false;
        m_assetExpectedSha256.clear();
        m_assetChecksumUrl.clear();
        m_error = QString::fromUtf8("Release metadata parse failed.");
        m_status = QString::fromUtf8("Update check failed.");
        m_userInitiatedCheck = false;
        emit changed();
        return;
    }

    const QJsonObject root = doc.object();
    const QString latestRaw = root.value(QString::fromUtf8("tag_name")).toString().trimmed();
    const QString latest = normalizeVersionToken(latestRaw);
    m_releaseUrl = root.value(QString::fromUtf8("html_url")).toString().trimmed();
    m_latestVersion = latest;
    m_error.clear();
    m_assetUrl.clear();
    m_assetName.clear();
    m_assetExpectedSha256.clear();
    m_assetChecksumUrl.clear();
    m_downloadedFilePath.clear();
    m_downloadReceived = 0;
    m_downloadTotal = 0;

    const QJsonArray assets = root.value(QString::fromUtf8("assets")).toArray();
    QStringList assetDiagnostics;
    selectBestReleaseAsset(assets, &m_assetUrl, &m_assetName, &m_assetExpectedSha256, &m_assetChecksumUrl, &assetDiagnostics);
    for (const QString& line : assetDiagnostics) {
        emit systemLog(line);
    }
    if (!m_assetName.isEmpty()) {
        emit systemLog(QString::fromUtf8("[Updater] Selected asset: %1").arg(m_assetName));
        if (!m_assetExpectedSha256.isEmpty()) {
            emit systemLog(QString::fromUtf8("[Updater] Found release digest for selected asset."));
        } else if (!m_assetChecksumUrl.isEmpty()) {
            emit systemLog(QString::fromUtf8("[Updater] Using checksum manifest for selected asset."));
        } else {
            emit systemLog(QString::fromUtf8(
                "[Updater] No checksum metadata for selected asset. Install will require a published SHA-256."));
        }
    }

    if (latest.isEmpty()) {
        m_updateAvailable = false;
        m_status = QString::fromUtf8("No version info in release feed.");
    } else if (isVersionNewer(m_appVersion, latest)) {
        m_updateAvailable = true;
        m_status = QString::fromUtf8("Update available: %1").arg(latest);
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
    } else {
        m_updateAvailable = false;
        m_status = QString::fromUtf8("You are up to date (%1).").arg(m_appVersion);
        if (m_userInitiatedCheck) {
            emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
        }
    }

    m_userInitiatedCheck = false;
    emit changed();
}

void Updater::onDownloadReadyRead()
{
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (m_downloadReply == nullptr || m_downloadFile == nullptr || reply == nullptr || reply != m_downloadReply) {
        return;
    }
    if (!reply->isOpen()) {
        return;
    }

    const QByteArray chunk = reply->readAll();
    if (chunk.isEmpty()) {
        return;
    }

    const qint64 written = m_downloadFile->write(chunk);
    if (written != chunk.size()) {
        m_downloadReply->abort();
    }
}

void Updater::onDownloadProgress(qint64 received, qint64 total)
{
    m_downloadReceived = qMax<qint64>(0, received);
    m_downloadTotal = qMax<qint64>(0, total);
    emit changed();
}

void Updater::onDownloadFinished()
{
    if (m_downloadReply == nullptr) {
        return;
    }

    QNetworkReply *reply = m_downloadReply;
    m_downloadReply = nullptr;

    const bool hadError = (reply->error() != QNetworkReply::NoError);
    const QString errorText = reply->errorString().trimmed();
    reply->deleteLater();

    if (m_downloadFile != nullptr) {
        m_downloadFile->flush();
        m_downloadFile->close();
    }

    m_checking = false;

    if (hadError) {
        if (m_downloadFile != nullptr) {
            m_downloadFile->remove();
            m_downloadFile->deleteLater();
            m_downloadFile = nullptr;
        }
        m_error = errorText.isEmpty()
            ? QString::fromUtf8("Update download failed.")
            : errorText;
        m_status = QString::fromUtf8("Download failed.");
        emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
        emit changed();
        return;
    }

    if (m_downloadFile != nullptr) {
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
    }

    if (m_assetExpectedSha256.isEmpty() && !m_assetChecksumUrl.trimmed().isEmpty() && !m_assetName.trimmed().isEmpty()) {
        QByteArray manifestPayload;
        QString manifestError;
        if (fetchUrlContentSync(&m_networkManager, QUrl(m_assetChecksumUrl), &manifestPayload, &manifestError)) {
            const QString extracted = extractSha256FromManifest(manifestPayload, m_assetName);
            if (!extracted.isEmpty()) {
                m_assetExpectedSha256 = extracted;
                emit systemLog(QString::fromUtf8("[Updater] Checksum resolved from manifest for %1.").arg(m_assetName));
            } else {
                emit systemLog(QString::fromUtf8("[Updater] Checksum manifest did not include %1.").arg(m_assetName));
            }
        } else if (!manifestError.trimmed().isEmpty()) {
            emit systemLog(QString::fromUtf8("[Updater] Checksum fetch failed: %1").arg(manifestError.trimmed()));
        }
    }

    if (!m_assetExpectedSha256.isEmpty()) {
        const QString downloadedHash = fileSha256Hex(m_downloadedFilePath).toLower();
        if (downloadedHash.isEmpty() || downloadedHash != m_assetExpectedSha256) {
            QFile::remove(m_downloadedFilePath);
            m_error = QString::fromUtf8("Downloaded update hash verification failed.");
            m_status = QString::fromUtf8("Download failed.");
            emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_error));
            emit changed();
            return;
        }
        emit systemLog(QString::fromUtf8("[Updater] Downloaded file hash verified."));
    }

    m_error.clear();
    if (m_assetExpectedSha256.isEmpty()) {
        m_status = QString::fromUtf8("Update downloaded, but release checksum is missing.");
    } else {
        m_status = QString::fromUtf8("Update downloaded. Open installer to continue.");
    }
    m_downloadReceived = m_downloadTotal > 0 ? m_downloadTotal : m_downloadReceived;
    emit systemLog(QString::fromUtf8("[Updater] %1").arg(m_status));
    emit changed();
}

bool Updater::isVersionNewer(const QString& currentVersion, const QString& candidateVersion)
{
    const QVector<int> current = parseVersionParts(normalizeVersionToken(currentVersion));
    const QVector<int> candidate = parseVersionParts(normalizeVersionToken(candidateVersion));
    const int maxCount = qMax(current.size(), candidate.size());

    for (int i = 0; i < maxCount; ++i) {
        const int cur = (i < current.size()) ? current.at(i) : 0;
        const int next = (i < candidate.size()) ? candidate.at(i) : 0;
        if (next > cur) {
            return true;
        }
        if (next < cur) {
            return false;
        }
    }
    return false;
}

bool Updater::selectBestReleaseAsset(
    const QJsonArray& assets,
    QString *assetUrl,
    QString *assetName,
    QString *assetSha256,
    QString *checksumAssetUrl,
    QStringList *diagnostics)
{
    if (assetUrl == nullptr || assetName == nullptr) {
        return false;
    }

    *assetUrl = QString();
    *assetName = QString();
    if (assetSha256 != nullptr) {
        *assetSha256 = QString();
    }
    if (checksumAssetUrl != nullptr) {
        *checksumAssetUrl = QString();
    }
#if defined(Q_OS_ANDROID)
    const QString currentPlatform = QString::fromUtf8("android");
#elif defined(Q_OS_MACOS)
    const QString currentPlatform = QString::fromUtf8("macos");
#elif defined(Q_OS_WIN)
    const QString currentPlatform = QString::fromUtf8("windows");
#else
    const QString currentPlatform = QString::fromUtf8("linux");
#endif
    QString rawArch = QSysInfo::buildCpuArchitecture().toLower();
    if (rawArch.isEmpty()) {
        rawArch = QSysInfo::currentCpuArchitecture().toLower();
    }
    auto normalizedArchForPlatform = [&currentPlatform](const QString& arch) {
        const QString value = arch.toLower();
        if (currentPlatform == QString::fromUtf8("android")) {
            if (value.contains(QString::fromUtf8("arm64")) || value.contains(QString::fromUtf8("aarch64"))) {
                return QString::fromUtf8("arm64-v8a");
            }
            if (value.contains(QString::fromUtf8("armv7")) || value.contains(QString::fromUtf8("armeabi"))) {
                return QString::fromUtf8("armeabi-v7a");
            }
        } else if (currentPlatform == QString::fromUtf8("macos")) {
            if (value.contains(QString::fromUtf8("arm64")) || value.contains(QString::fromUtf8("aarch64"))) {
                return QString::fromUtf8("arm64");
            }
            if (value.contains(QString::fromUtf8("x86_64")) || value.contains(QString::fromUtf8("x64")) || value.contains(QString::fromUtf8("amd64"))) {
                return QString::fromUtf8("x86_64");
            }
        } else if (currentPlatform == QString::fromUtf8("windows")) {
            if (value.contains(QString::fromUtf8("arm64")) || value.contains(QString::fromUtf8("aarch64"))) {
                return QString::fromUtf8("arm64");
            }
            if (value.contains(QString::fromUtf8("x86_64")) || value.contains(QString::fromUtf8("x64")) || value.contains(QString::fromUtf8("amd64"))) {
                return QString::fromUtf8("x64");
            }
        } else {
            if (value.contains(QString::fromUtf8("arm64")) || value.contains(QString::fromUtf8("aarch64"))) {
                return QString::fromUtf8("arm64");
            }
            if (value.contains(QString::fromUtf8("x86_64")) || value.contains(QString::fromUtf8("x64")) || value.contains(QString::fromUtf8("amd64"))) {
                return QString::fromUtf8("x64");
            }
        }
        return value;
    };
    const QString currentArch = normalizedArchForPlatform(rawArch);

    if (diagnostics != nullptr) {
        diagnostics->clear();
        diagnostics->append(QString::fromUtf8("[Updater] Current platform: %1").arg(currentPlatform));
        diagnostics->append(QString::fromUtf8("[Updater] Current arch: %1").arg(currentArch.isEmpty() ? rawArch : currentArch));
    }

    int bestScore = std::numeric_limits<int>::min();
    QString bestUrl;
    QString bestName;
    QString bestDigest;
    QStringList candidateNames;

    auto reject = [diagnostics](const QString& name, const QString& reason) {
        if (diagnostics != nullptr) {
            diagnostics->append(QString::fromUtf8("[Updater] Rejected asset: %1 (%2)").arg(name, reason));
        }
    };

    auto hasAny = [](const QString& text, const QStringList& tokens) {
        for (const QString& token : tokens) {
            if (text.contains(token)) {
                return true;
            }
        }
        return false;
    };

    auto hasRequiredPlatform = [&currentPlatform, &hasAny](const QString& lower) {
        if (currentPlatform == QString::fromUtf8("linux")) {
            return lower.contains(QString::fromUtf8("linux"));
        }
        if (currentPlatform == QString::fromUtf8("android")) {
            return lower.contains(QString::fromUtf8("android"));
        }
        if (currentPlatform == QString::fromUtf8("macos")) {
            return hasAny(lower, {QString::fromUtf8("macos"), QString::fromUtf8("mac"), QString::fromUtf8("darwin"), QString::fromUtf8("osx")});
        }
        return hasAny(lower, {QString::fromUtf8("windows"), QString::fromUtf8("win")});
    };

    auto hasWrongPlatform = [&currentPlatform, &hasAny](const QString& lower) {
        const bool mentionsLinux = lower.contains(QString::fromUtf8("linux")) || lower.contains(QString::fromUtf8("appimage"));
        const bool mentionsAndroid = lower.contains(QString::fromUtf8("android")) || lower.endsWith(QString::fromUtf8(".apk"));
        const bool mentionsMac = hasAny(lower, {QString::fromUtf8("macos"), QString::fromUtf8("darwin"), QString::fromUtf8("osx"), QString::fromUtf8(".dmg")});
        const bool mentionsWin = hasAny(lower, {QString::fromUtf8("windows"), QString::fromUtf8(".exe")});
        if (currentPlatform == QString::fromUtf8("linux")) {
            return mentionsAndroid || mentionsMac || mentionsWin;
        }
        if (currentPlatform == QString::fromUtf8("android")) {
            return mentionsLinux || mentionsMac || mentionsWin;
        }
        if (currentPlatform == QString::fromUtf8("macos")) {
            return mentionsLinux || mentionsAndroid || mentionsWin;
        }
        return mentionsLinux || mentionsAndroid || mentionsMac;
    };

    auto hasRequiredExtension = [&currentPlatform](const QString& lower) {
        if (currentPlatform == QString::fromUtf8("linux")) {
            return lower.endsWith(QString::fromUtf8(".appimage"));
        }
        if (currentPlatform == QString::fromUtf8("android")) {
            return lower.endsWith(QString::fromUtf8(".apk"));
        }
        if (currentPlatform == QString::fromUtf8("macos")) {
            return lower.endsWith(QString::fromUtf8(".dmg"));
        }
        return lower.endsWith(QString::fromUtf8(".exe"));
    };

    auto hasRequiredArch = [&currentPlatform, &currentArch](const QString& lower) {
        if (currentPlatform == QString::fromUtf8("android")) {
            if (currentArch == QString::fromUtf8("arm64-v8a")) {
                return lower.contains(QString::fromUtf8("arm64-v8a"));
            }
            if (currentArch == QString::fromUtf8("armeabi-v7a")) {
                return lower.contains(QString::fromUtf8("armeabi-v7a"));
            }
            return false;
        }
        if (currentPlatform == QString::fromUtf8("macos")) {
            if (currentArch == QString::fromUtf8("arm64")) {
                return lower.contains(QString::fromUtf8("macos-arm64")) || lower.contains(QString::fromUtf8("mac-arm64"));
            }
            if (currentArch == QString::fromUtf8("x86_64")) {
                return lower.contains(QString::fromUtf8("macos-x86_64")) || lower.contains(QString::fromUtf8("mac-x86_64"));
            }
            return false;
        }
        if (currentPlatform == QString::fromUtf8("windows")) {
            if (currentArch == QString::fromUtf8("arm64")) {
                return lower.contains(QString::fromUtf8("windows-arm64")) || lower.contains(QString::fromUtf8("win-arm64"));
            }
            if (currentArch == QString::fromUtf8("x64")) {
                return lower.contains(QString::fromUtf8("windows-x64")) || lower.contains(QString::fromUtf8("win-x64"));
            }
            return false;
        }
        if (currentArch == QString::fromUtf8("arm64")) {
            return lower.contains(QString::fromUtf8("linux-arm64")) || lower.contains(QString::fromUtf8("linux-aarch64"));
        }
        if (currentArch == QString::fromUtf8("x64")) {
            return lower.contains(QString::fromUtf8("linux-x64")) || lower.contains(QString::fromUtf8("linux-x86_64"));
        }
        return false;
    };

    for (const QJsonValue& entry : assets) {
        if (!entry.isObject()) {
            continue;
        }
        const QJsonObject obj = entry.toObject();
        const QString name = obj.value(QString::fromUtf8("name")).toString().trimmed();
        const QString url = obj.value(QString::fromUtf8("browser_download_url")).toString().trimmed();
        if (name.isEmpty() || url.isEmpty()) {
            continue;
        }

        const QString lower = name.toLower();
        candidateNames.append(name);

        if (isLikelyChecksumAsset(lower)) {
            reject(name, QString::fromUtf8("checksum manifest"));
            continue;
        }
        if (!hasRequiredExtension(lower)) {
            reject(name, QString::fromUtf8("wrong file type for %1").arg(currentPlatform));
            continue;
        }
        if (hasWrongPlatform(lower)) {
            reject(name, QString::fromUtf8("wrong platform"));
            continue;
        }
        if (!hasRequiredPlatform(lower)) {
            reject(name, QString::fromUtf8("missing %1 platform marker").arg(currentPlatform));
            continue;
        }
        if (!hasRequiredArch(lower)) {
            reject(name, QString::fromUtf8("wrong architecture for %1").arg(currentArch));
            continue;
        }

        int score = 0;
        if (lower.contains(QString::fromUtf8("genyconnect"))) {
            score += 25;
        }
        if (lower.contains(QString::fromUtf8("selfupdate"))) {
            score += 500;
        }

        if (currentPlatform == QString::fromUtf8("linux")) {
            score += lower.contains(QString::fromUtf8("selfupdate-linux")) ? 300 : 100;
            score += lower.endsWith(QString::fromUtf8(".appimage")) ? 80 : 0;
        } else if (currentPlatform == QString::fromUtf8("android")) {
            score += 200;
        } else if (currentPlatform == QString::fromUtf8("macos")) {
            score += 200;
        } else {
            score += 200;
        }
        score += 50;

        if (diagnostics != nullptr) {
            diagnostics->append(QString::fromUtf8("[Updater] Candidate asset: %1 (score %2)").arg(name).arg(score));
        }

        if (score > bestScore) {
            bestScore = score;
            bestUrl = url;
            bestName = name;
            bestDigest = normalizeSha256Digest(obj.value(QString::fromUtf8("digest")).toString());
        }
    }

    if (diagnostics != nullptr) {
        diagnostics->append(QString::fromUtf8("[Updater] Release assets: %1").arg(candidateNames.join(QString::fromUtf8(", "))));
    }

    if (bestUrl.isEmpty()) {
        if (diagnostics != nullptr) {
            diagnostics->append(QString::fromUtf8("[Updater] No asset matched platform %1 arch %2.").arg(currentPlatform, currentArch));
        }
        return false;
    }

    if (checksumAssetUrl != nullptr) {
        const QString bestNameLower = bestName.toLower();
        int checksumScoreBest = std::numeric_limits<int>::min();
        QString checksumUrlCandidate;
        for (const QJsonValue& entry : assets) {
            if (!entry.isObject()) {
                continue;
            }
            const QJsonObject obj = entry.toObject();
            const QString candidateName = obj.value(QString::fromUtf8("name")).toString().trimmed();
            const QString candidateUrl = obj.value(QString::fromUtf8("browser_download_url")).toString().trimmed();
            if (candidateName.isEmpty() || candidateUrl.isEmpty()) {
                continue;
            }
            const QString candidateLower = candidateName.toLower();
            if (!isLikelyChecksumAsset(candidateLower)) {
                continue;
            }

            int score = 0;
            if (candidateLower == bestNameLower + QString::fromUtf8(".sha256")) {
                score += 300;
            } else if (candidateLower == bestNameLower + QString::fromUtf8(".sha256.txt")) {
                score += 280;
            } else if (candidateLower.contains(bestNameLower)) {
                score += 180;
            }
            if (candidateLower.contains(QString::fromUtf8("sha256"))) {
                score += 80;
            }
            if (candidateLower.contains(QString::fromUtf8("checksum"))) {
                score += 40;
            }
            if (score > checksumScoreBest) {
                checksumScoreBest = score;
                checksumUrlCandidate = candidateUrl;
            }
        }
        *checksumAssetUrl = checksumUrlCandidate;
    }

    *assetUrl = bestUrl;
    *assetName = bestName;
    if (assetSha256 != nullptr) {
        *assetSha256 = bestDigest;
    }
    return true;
}

QString Updater::fileSha256Hex(const QString& path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    QCryptographicHash hash(QCryptographicHash::Sha256);
    QByteArray buffer;
    buffer.resize(1024 * 1024);
    while (!file.atEnd()) {
        const qint64 readBytes = file.read(buffer.data(), buffer.size());
        if (readBytes < 0) {
            return {};
        }
        if (readBytes > 0) {
            hash.addData(QByteArrayView(buffer.constData(), static_cast<qsizetype>(readBytes)));
        }
    }
    return QString::fromLatin1(hash.result().toHex());
}

bool Updater::isSelfInstallSupportedAsset(const QString& path)
{
    if (path.trimmed().isEmpty()) {
        return false;
    }
    const QFileInfo info(path);
    if (!info.exists()) {
        return false;
    }
    if (info.isDir()) {
        return info.fileName().toLower().endsWith(QString::fromUtf8(".app"));
    }
    return !looksLikeManualInstaller(path);
}

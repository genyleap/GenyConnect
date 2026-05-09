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
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTemporaryFile>
#include <QTimer>
#include <QUrl>
#include <QVector>

#include <limits>

#if defined(Q_OS_WIN)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

module genyconnect.backend.updater;

using namespace Qt::StringLiterals;

namespace {
const QUrl kReleaseApiUrl(QStringLiteral("https://api.github.com/repos/genyleap/GenyConnect/releases/latest"));
const QString kReleasesPageUrl = QStringLiteral("https://github.com/genyleap/GenyConnect/releases");

QString normalizeVersionToken(const QString& version)
{
    QString cleaned = version.trimmed();
    if (cleaned.startsWith(QStringLiteral("v"), Qt::CaseInsensitive)) {
        cleaned.remove(0, 1);
    }
    return cleaned;
}

QString normalizeSha256Digest(const QString& digest)
{
    QString value = digest.trimmed().toLower();
    if (value.startsWith(QStringLiteral("sha256:"))) {
        value.remove(0, QStringLiteral("sha256:").size());
    }
    static const QRegularExpression hex64Rx(QStringLiteral("^[0-9a-f]{64}$"));
    return hex64Rx.match(value).hasMatch() ? value : QString();
}

bool isLikelyChecksumAsset(const QString& lowerAssetName)
{
    return lowerAssetName.contains(QStringLiteral("sha256"))
        || lowerAssetName.contains(QStringLiteral("checksum"))
        || lowerAssetName.endsWith(QStringLiteral(".sha256"))
        || lowerAssetName.endsWith(QStringLiteral(".sha256.txt"))
        || lowerAssetName.endsWith(QStringLiteral("checksums.txt"));
}

QString extractSha256FromManifest(const QByteArray& content, const QString& targetAssetName)
{
    const QString targetName = QFileInfo(targetAssetName.trimmed()).fileName().toLower();
    const QString text = QString::fromUtf8(content);
    const QStringList lines = text.split('\n');
    static const QRegularExpression hashAndNameRx(
        QStringLiteral("^([0-9A-Fa-f]{64})\\s+\\*?(.+)$"));
    static const QRegularExpression sha256StyleRx(
        QStringLiteral("^SHA256\\s*\\((.+)\\)\\s*=\\s*([0-9A-Fa-f]{64})$"),
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression hashOnlyRx(QStringLiteral("^[0-9A-Fa-f]{64}$"));

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
            *errorOut = QStringLiteral("Invalid checksum URL.");
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
        errorText = QStringLiteral("Checksum download timed out.");
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
                ? QStringLiteral("Checksum download failed.")
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
    const QRegularExpression numberRx(QStringLiteral("(\\d+)"));
    QRegularExpressionMatchIterator it = numberRx.globalMatch(version);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        parts.append(m.captured(1).toInt());
    }
    return parts;
}

QString appUpdaterHelperPath()
{
#if defined(Q_OS_WIN)
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("GenyConnectUpdater.exe"));
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("GenyConnectUpdater"));
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
    return lower.endsWith(QStringLiteral(".dmg"))
        || lower.endsWith(QStringLiteral(".pkg"))
        || lower.endsWith(QStringLiteral(".msi"))
        || lower.endsWith(QStringLiteral(".zip"))
        || lower.endsWith(QStringLiteral(".tar.gz"))
        || lower.endsWith(QStringLiteral(".tar.xz"))
        || lower.endsWith(QStringLiteral(".deb"))
        || lower.endsWith(QStringLiteral(".rpm"));
}

bool startUpdaterHelperDetached(const QString& helperPath, const QString& jobPath, QString *errorOut)
{
#if defined(Q_OS_WIN)
    const QString nativeHelper = QDir::toNativeSeparators(helperPath);
    const QString nativeJob = QDir::toNativeSeparators(jobPath);
    const bool launchedDirect = QProcess::startDetached(helperPath, {QStringLiteral("--job"), jobPath});
    if (launchedDirect) {
        return true;
    }

    const QString args = QStringLiteral("--job \"%1\"").arg(nativeJob);
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
                ? QStringLiteral("Administrator permission was denied.")
                : QStringLiteral("Failed to launch updater helper (code %1).").arg(rc);
        }
        return false;
    }
    return true;
#else
    const bool launched = QProcess::startDetached(helperPath, {QStringLiteral("--job"), jobPath});
    if (!launched && errorOut != nullptr) {
        *errorOut = QStringLiteral("Failed to launch updater helper.");
    }
    return launched;
#endif
}
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
    const QString normalized = version.trimmed().isEmpty() ? QStringLiteral("0.0.0") : version.trimmed();
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
    return isSelfInstallSupportedAsset(m_downloadedFilePath)
        && !normalizeSha256Digest(m_assetExpectedSha256).isEmpty();
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
    m_status = QStringLiteral("Checking for updates...");
    emit changed();

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

    QDir updatesDir(QDir(appDataDir).filePath(QStringLiteral("updates")));
    if (!updatesDir.exists()) {
        return;
    }

    const QFileInfoList statusFiles = updatesDir.entryInfoList(
        QStringList() << QStringLiteral("update-job-*.json.status.json"),
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
    const bool ok = root.value(QStringLiteral("ok")).toBool(false);
    const QString message = root.value(QStringLiteral("message")).toString().trimmed();
    if (ok) {
        m_error.clear();
        m_status = message.isEmpty()
            ? QStringLiteral("Update applied successfully.")
            : QStringLiteral("Update: %1").arg(message);
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_status));
    } else {
        m_error = message.isEmpty()
            ? QStringLiteral("Updater helper failed.")
            : message;
        m_status = QStringLiteral("Install failed.");
        emit systemLog(QStringLiteral("[Updater] Install failed: %1").arg(m_error));
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
        m_error = QStringLiteral("No downloadable update asset is available.");
        m_status = QStringLiteral("Download unavailable.");
        emit changed();
        return false;
    }

    const QString downloadsDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString baseDir = downloadsDir.isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        : downloadsDir;
    if (baseDir.isEmpty()) {
        m_error = QStringLiteral("Could not resolve download directory.");
        m_status = QStringLiteral("Download failed.");
        emit changed();
        return false;
    }

    QDir().mkpath(baseDir);
    const QString fallbackName = QStringLiteral("genyconnect-update-%1.bin")
        .arg(m_latestVersion.isEmpty() ? QStringLiteral("latest") : m_latestVersion);
    const QString fileName = m_assetName.trimmed().isEmpty() ? fallbackName : m_assetName.trimmed();
    m_downloadedFilePath = QDir(baseDir).filePath(fileName);

    if (m_downloadFile != nullptr) {
        if (m_downloadFile->isOpen()) {
            m_downloadFile->close();
        }
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
    }

    m_downloadFile = new QFile(m_downloadedFilePath, this);
    if (!m_downloadFile->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        m_error = QStringLiteral("Failed to create update file: %1").arg(m_downloadedFilePath);
        m_status = QStringLiteral("Download failed.");
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
        emit changed();
        return false;
    }

    m_downloadReceived = 0;
    m_downloadTotal = 0;
    m_checking = true;
    m_error.clear();
    m_status = QStringLiteral("Downloading update...");
    emit changed();

    QNetworkRequest request {QUrl(m_assetUrl)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-Updater/1.0");
    request.setTransferTimeout(30000);

    m_downloadReply = m_networkManager.get(request);
    connect(m_downloadReply, &QNetworkReply::readyRead, this, &Updater::onDownloadReadyRead);
    connect(m_downloadReply, &QNetworkReply::downloadProgress, this, &Updater::onDownloadProgress);
    connect(m_downloadReply, &QNetworkReply::finished, this, &Updater::onDownloadFinished);

    emit systemLog(QStringLiteral("[Updater] Downloading %1").arg(fileName));
    return true;
}

bool Updater::openDownloadedUpdate()
{
    const QString path = m_downloadedFilePath.trimmed();
    if (path.isEmpty() || !QFileInfo::exists(path)) {
        m_error = QStringLiteral("Downloaded update file was not found.");
        emit changed();
        return false;
    }
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

bool Updater::installDownloadedUpdate()
{
    const QString sourcePath = m_downloadedFilePath.trimmed();
    if (sourcePath.isEmpty() || !QFileInfo::exists(sourcePath)) {
        m_error = QStringLiteral("Downloaded update file was not found.");
        m_status = QStringLiteral("Install failed.");
        emit changed();
        return false;
    }

    if (looksLikeManualInstaller(sourcePath)) {
        m_status = QStringLiteral("This asset requires manual install. Opening installer...");
        m_error.clear();
        emit changed();
        return openDownloadedUpdate();
    }

    const QString expectedSha256 = normalizeSha256Digest(m_assetExpectedSha256);
    if (expectedSha256.isEmpty()) {
        m_error = QStringLiteral(
            "Release does not provide trusted SHA-256 metadata for this asset. Publish digest/checksum first.");
        m_status = QStringLiteral("Install blocked.");
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }

    const QString downloadedHash = fileSha256Hex(sourcePath).toLower();
    if (downloadedHash.isEmpty() || downloadedHash != expectedSha256) {
        m_error = QStringLiteral("Downloaded update hash verification failed.");
        m_status = QStringLiteral("Install failed.");
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }

    const QString helperPath = appUpdaterHelperPath();
    if (!QFileInfo::exists(helperPath)) {
        m_error = QStringLiteral("Updater helper executable not found.");
        m_status = QStringLiteral("Install failed.");
        emit changed();
        return false;
    }

    const QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (appDir.trimmed().isEmpty()) {
        m_error = QStringLiteral("Could not resolve app data directory.");
        m_status = QStringLiteral("Install failed.");
        emit changed();
        return false;
    }

    const QString updateDir = QDir(appDir).filePath(QStringLiteral("updates"));
    QDir().mkpath(updateDir);

    const QString sourceName = QFileInfo(sourcePath).fileName();
    const QString stagedPath = QDir(updateDir).filePath(QStringLiteral("staged-%1").arg(sourceName));
    if (!copyWithOverwrite(sourcePath, stagedPath)) {
        m_error = QStringLiteral("Failed to stage update file.");
        m_status = QStringLiteral("Install failed.");
        emit changed();
        return false;
    }

    const QString currentExe = QCoreApplication::applicationFilePath();
#if defined(Q_OS_WIN)
    bool installDirWritable = true;
    {
        const QString exeDir = QFileInfo(currentExe).absolutePath();
        QTemporaryFile probe(QDir(exeDir).filePath(QStringLiteral(".__geny_write_probe_XXXXXX.tmp")));
        probe.setAutoRemove(true);
        if (!probe.open()) {
            installDirWritable = false;
            emit systemLog(QStringLiteral(
                "[Updater] Install folder is not writable. Will request Administrator permission."));
        } else {
            probe.close();
        }
    }
#endif
    const QString backupPath = currentExe + QStringLiteral(".backup.old");
    const QString jobPath = QDir(updateDir).filePath(
        QStringLiteral("update-job-%1.json").arg(QString::number(QDateTime::currentMSecsSinceEpoch()))
    );

    QJsonObject job;
    job.insert(QStringLiteral("pid"), static_cast<qint64>(QCoreApplication::applicationPid()));
    job.insert(QStringLiteral("current_executable"), currentExe);
    job.insert(QStringLiteral("staged_executable"), stagedPath);
    job.insert(QStringLiteral("backup_executable"), backupPath);
    job.insert(QStringLiteral("working_directory"), QCoreApplication::applicationDirPath());
    job.insert(QStringLiteral("expected_sha256"), expectedSha256);
    job.insert(QStringLiteral("cleanup_source_on_success"), true);
    job.insert(QStringLiteral("timeout_ms"), 45000);
    job.insert(QStringLiteral("args"), QJsonArray());

    QFile jobFile(jobPath);
    if (!jobFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QFile::remove(stagedPath);
        m_error = QStringLiteral("Failed to write update job file.");
        m_status = QStringLiteral("Install failed.");
        emit changed();
        return false;
    }
    jobFile.write(QJsonDocument(job).toJson(QJsonDocument::Indented));
    jobFile.close();

    QString launchError;
    if (!startUpdaterHelperDetached(helperPath, jobPath, &launchError)) {
        QFile::remove(jobPath);
        QFile::remove(stagedPath);
        m_error = launchError.isEmpty() ? QStringLiteral("Failed to launch updater helper.") : launchError;
        m_status = QStringLiteral("Install failed.");
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
        emit changed();
        return false;
    }

    m_error.clear();
#if defined(Q_OS_WIN)
    if (!installDirWritable) {
        m_status = QStringLiteral("Waiting for Administrator approval to install update...");
    } else {
        m_status = QStringLiteral("Installing update and restarting...");
    }
#else
    m_status = QStringLiteral("Installing update and restarting...");
#endif
    emit systemLog(QStringLiteral("[Updater] Handed off update to helper process."));
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
            apiMessage = statusDoc.object().value(QStringLiteral("message")).toString().trimmed();
        }

        if (statusCode == 404 || apiMessage.compare(QStringLiteral("Not Found"), Qt::CaseInsensitive) == 0) {
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
            m_status = QStringLiteral("No published release yet. Current version %1.").arg(m_appVersion);
            if (m_userInitiatedCheck) {
                emit systemLog(QStringLiteral("[Updater] %1").arg(m_status));
            }
            m_userInitiatedCheck = false;
            emit changed();
            return;
        }

        m_updateAvailable = false;
        m_assetExpectedSha256.clear();
        m_assetChecksumUrl.clear();
        m_error = networkError.isEmpty()
            ? QStringLiteral("Failed to check updates.")
            : networkError;
        m_status = QStringLiteral("Update check failed.");
        if (m_userInitiatedCheck) {
            emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
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
        m_error = QStringLiteral("Release metadata parse failed.");
        m_status = QStringLiteral("Update check failed.");
        m_userInitiatedCheck = false;
        emit changed();
        return;
    }

    const QJsonObject root = doc.object();
    const QString latestRaw = root.value(QStringLiteral("tag_name")).toString().trimmed();
    const QString latest = normalizeVersionToken(latestRaw);
    m_releaseUrl = root.value(QStringLiteral("html_url")).toString().trimmed();
    m_latestVersion = latest;
    m_error.clear();
    m_assetUrl.clear();
    m_assetName.clear();
    m_assetExpectedSha256.clear();
    m_assetChecksumUrl.clear();
    m_downloadedFilePath.clear();
    m_downloadReceived = 0;
    m_downloadTotal = 0;

    const QJsonArray assets = root.value(QStringLiteral("assets")).toArray();
    selectBestReleaseAsset(assets, &m_assetUrl, &m_assetName, &m_assetExpectedSha256, &m_assetChecksumUrl);
    if (!m_assetName.isEmpty()) {
        emit systemLog(QStringLiteral("[Updater] Selected asset: %1").arg(m_assetName));
        if (!m_assetExpectedSha256.isEmpty()) {
            emit systemLog(QStringLiteral("[Updater] Found release digest for selected asset."));
        } else if (!m_assetChecksumUrl.isEmpty()) {
            emit systemLog(QStringLiteral("[Updater] Using checksum manifest for selected asset."));
        } else {
            emit systemLog(QStringLiteral(
                "[Updater] No checksum metadata for selected asset. Install will require a published SHA-256."));
        }
    }

    if (latest.isEmpty()) {
        m_updateAvailable = false;
        m_status = QStringLiteral("No version info in release feed.");
    } else if (isVersionNewer(m_appVersion, latest)) {
        m_updateAvailable = true;
        m_status = QStringLiteral("Update available: %1").arg(latest);
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_status));
    } else {
        m_updateAvailable = false;
        m_status = QStringLiteral("You are up to date (%1).").arg(m_appVersion);
        if (m_userInitiatedCheck) {
            emit systemLog(QStringLiteral("[Updater] %1").arg(m_status));
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
            ? QStringLiteral("Update download failed.")
            : errorText;
        m_status = QStringLiteral("Download failed.");
        emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
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
                emit systemLog(QStringLiteral("[Updater] Checksum resolved from manifest for %1.").arg(m_assetName));
            } else {
                emit systemLog(QStringLiteral("[Updater] Checksum manifest did not include %1.").arg(m_assetName));
            }
        } else if (!manifestError.trimmed().isEmpty()) {
            emit systemLog(QStringLiteral("[Updater] Checksum fetch failed: %1").arg(manifestError.trimmed()));
        }
    }

    if (!m_assetExpectedSha256.isEmpty()) {
        const QString downloadedHash = fileSha256Hex(m_downloadedFilePath).toLower();
        if (downloadedHash.isEmpty() || downloadedHash != m_assetExpectedSha256) {
            QFile::remove(m_downloadedFilePath);
            m_error = QStringLiteral("Downloaded update hash verification failed.");
            m_status = QStringLiteral("Download failed.");
            emit systemLog(QStringLiteral("[Updater] %1").arg(m_error));
            emit changed();
            return;
        }
        emit systemLog(QStringLiteral("[Updater] Downloaded file hash verified."));
    }

    m_error.clear();
    if (m_assetExpectedSha256.isEmpty()) {
        m_status = QStringLiteral("Update downloaded, but release checksum is missing.");
    } else {
        m_status = QStringLiteral("Update downloaded. Open installer to continue.");
    }
    m_downloadReceived = m_downloadTotal > 0 ? m_downloadTotal : m_downloadReceived;
    emit systemLog(QStringLiteral("[Updater] %1").arg(m_status));
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
    QString *checksumAssetUrl)
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
    if (assets.isEmpty()) {
        return false;
    }

    QString arch = QSysInfo::buildCpuArchitecture().toLower();
    if (arch.isEmpty()) {
        arch = QSysInfo::currentCpuArchitecture().toLower();
    }
#if defined(Q_OS_MACOS)
    constexpr bool isMac = true;
    constexpr bool isWin = false;
    constexpr bool isLinux = false;
#elif defined(Q_OS_WIN)
    constexpr bool isMac = false;
    constexpr bool isWin = true;
    constexpr bool isLinux = false;
#else
    constexpr bool isMac = false;
    constexpr bool isWin = false;
    constexpr bool isLinux = true;
#endif

    int bestScore = std::numeric_limits<int>::min();
    QString bestUrl;
    QString bestName;
    QString bestDigest;

    for (const QJsonValue& entry : assets) {
        if (!entry.isObject()) {
            continue;
        }
        const QJsonObject obj = entry.toObject();
        const QString name = obj.value(QStringLiteral("name")).toString().trimmed();
        const QString url = obj.value(QStringLiteral("browser_download_url")).toString().trimmed();
        if (name.isEmpty() || url.isEmpty()) {
            continue;
        }

        const QString lower = name.toLower();
        const bool mentionsMac = lower.contains(QStringLiteral("mac"))
            || lower.contains(QStringLiteral("darwin"))
            || lower.contains(QStringLiteral("osx"));
        const bool mentionsWin = lower.contains(QStringLiteral("win"))
            || lower.contains(QStringLiteral("windows"));
        const bool mentionsLinux = lower.contains(QStringLiteral("linux"))
            || lower.contains(QStringLiteral("appimage"))
            || lower.contains(QStringLiteral(".deb"))
            || lower.contains(QStringLiteral(".rpm"));

        // Hard filter when asset explicitly targets a different platform.
        if (isWin && mentionsMac) {
            continue;
        }
        if (isWin && mentionsLinux) {
            continue;
        }
        if (isMac && mentionsWin) {
            continue;
        }
        if (isMac && mentionsLinux) {
            continue;
        }
        if (isLinux && mentionsWin) {
            continue;
        }
        if (isLinux && mentionsMac) {
            continue;
        }

        const bool assetArm = lower.contains(QStringLiteral("arm64")) || lower.contains(QStringLiteral("aarch64"));
        const bool assetX86 = lower.contains(QStringLiteral("x64"))
            || lower.contains(QStringLiteral("x86_64"))
            || lower.contains(QStringLiteral("amd64"))
            || lower.contains(QStringLiteral("x86-64"));
        const bool hostArm = arch.contains(QStringLiteral("arm")) || arch.contains(QStringLiteral("aarch64"));

        // Hard filter when asset explicitly targets a different architecture.
        if (hostArm && assetX86 && !assetArm) {
            continue;
        }
        if (!hostArm && assetArm && !assetX86) {
            continue;
        }

        int score = 0;
        if (lower.contains(QStringLiteral("genyconnect"))) {
            score += 25;
        }
        if (lower.contains(QStringLiteral("selfupdate"))) {
            score += 30;
        }

        if (isMac) {
            if (mentionsMac) {
                score += 40;
            }
            if (lower.endsWith(QStringLiteral(".dmg"))) {
                score += 35;
            } else if (lower.endsWith(QStringLiteral(".pkg"))) {
                score += 25;
            } else if (lower.endsWith(QStringLiteral(".zip"))) {
                score += 10;
            }
        } else if (isWin) {
            if (mentionsWin) {
                score += 40;
            }
            if (lower.endsWith(QStringLiteral(".exe")) || lower.endsWith(QStringLiteral(".msi"))) {
                score += 35;
            } else if (lower.endsWith(QStringLiteral(".zip"))) {
                score += 10;
            }
        } else if (isLinux) {
            if (mentionsLinux) {
                score += 40;
            }
            if (lower.endsWith(QStringLiteral(".appimage")) || lower.endsWith(QStringLiteral(".deb")) || lower.endsWith(QStringLiteral(".rpm"))) {
                score += 35;
            } else if (lower.endsWith(QStringLiteral(".tar.gz")) || lower.endsWith(QStringLiteral(".zip"))) {
                score += 15;
            }
        }

        if (hostArm) {
            if (assetArm) {
                score += 25;
            }
        } else {
            if (assetX86) {
                score += 25;
            }
        }

        if (score > bestScore) {
            bestScore = score;
            bestUrl = url;
            bestName = name;
            bestDigest = normalizeSha256Digest(obj.value(QStringLiteral("digest")).toString());
        }
    }

    if (bestUrl.isEmpty()) {
        const QJsonObject firstObj = assets.first().toObject();
        bestName = firstObj.value(QStringLiteral("name")).toString().trimmed();
        bestUrl = firstObj.value(QStringLiteral("browser_download_url")).toString().trimmed();
        bestDigest = normalizeSha256Digest(firstObj.value(QStringLiteral("digest")).toString());
    }

    if (bestUrl.isEmpty()) {
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
            const QString candidateName = obj.value(QStringLiteral("name")).toString().trimmed();
            const QString candidateUrl = obj.value(QStringLiteral("browser_download_url")).toString().trimmed();
            if (candidateName.isEmpty() || candidateUrl.isEmpty()) {
                continue;
            }
            const QString candidateLower = candidateName.toLower();
            if (!isLikelyChecksumAsset(candidateLower)) {
                continue;
            }

            int score = 0;
            if (candidateLower == bestNameLower + QStringLiteral(".sha256")) {
                score += 300;
            } else if (candidateLower == bestNameLower + QStringLiteral(".sha256.txt")) {
                score += 280;
            } else if (candidateLower.contains(bestNameLower)) {
                score += 180;
            }
            if (candidateLower.contains(QStringLiteral("sha256"))) {
                score += 80;
            }
            if (candidateLower.contains(QStringLiteral("checksum"))) {
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
        return info.fileName().toLower().endsWith(QStringLiteral(".app"));
    }
    return !looksLikeManualInstaller(path);
}

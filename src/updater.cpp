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
const QUrl kReleaseApiUrl(u"https://api.github.com/repos/genyleap/GenyConnect/releases/latest"_s);
const QString kReleasesPageUrl = u"https://github.com/genyleap/GenyConnect/releases"_s;

QString normalizeVersionToken(const QString& version)
{
    QString cleaned = version.trimmed();
    if (cleaned.startsWith(u"v"_s, Qt::CaseInsensitive)) {
        cleaned.remove(0, 1);
    }
    return cleaned;
}

QString normalizeSha256Digest(const QString& digest)
{
    QString value = digest.trimmed().toLower();
    if (value.startsWith(u"sha256:"_s)) {
        value.remove(0, u"sha256:"_s.size());
    }
    static const QRegularExpression hex64Rx(u"^[0-9a-f]{64}$"_s);
    return hex64Rx.match(value).hasMatch() ? value : QString();
}

bool isLikelyChecksumAsset(const QString& lowerAssetName)
{
    return lowerAssetName.contains(u"sha256"_s)
        || lowerAssetName.contains(u"checksum"_s)
        || lowerAssetName.endsWith(u".sha256"_s)
        || lowerAssetName.endsWith(u".sha256.txt"_s)
        || lowerAssetName.endsWith(u"checksums.txt"_s);
}

QString extractSha256FromManifest(const QByteArray& content, const QString& targetAssetName)
{
    const QString targetName = QFileInfo(targetAssetName.trimmed()).fileName().toLower();
    const QString text = QString::fromUtf8(content);
    const QStringList lines = text.split('\n');
    static const QRegularExpression hashAndNameRx(
        u"^([0-9A-Fa-f]{64})\\s+\\*?(.+)$"_s);
    static const QRegularExpression sha256StyleRx(
        u"^SHA256\\s*\\((.+)\\)\\s*=\\s*([0-9A-Fa-f]{64})$"_s,
        QRegularExpression::CaseInsensitiveOption);
    static const QRegularExpression hashOnlyRx(u"^[0-9A-Fa-f]{64}$"_s);

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
            *errorOut = u"Invalid checksum URL."_s;
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
        errorText = u"Checksum download timed out."_s;
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
                ? u"Checksum download failed."_s
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
    const QRegularExpression numberRx(u"(\\d+)"_s);
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
    return QDir(QCoreApplication::applicationDirPath()).filePath(u"GenyConnectUpdater.exe"_s);
#else
    return QDir(QCoreApplication::applicationDirPath()).filePath(u"GenyConnectUpdater"_s);
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
    return lower.endsWith(u".dmg"_s)
        || lower.endsWith(u".pkg"_s)
        || lower.endsWith(u".msi"_s)
        || lower.endsWith(u".zip"_s)
        || lower.endsWith(u".tar.gz"_s)
        || lower.endsWith(u".tar.xz"_s)
        || lower.endsWith(u".deb"_s)
        || lower.endsWith(u".rpm"_s);
}

bool startUpdaterHelperDetached(const QString& helperPath, const QString& jobPath, QString *errorOut)
{
#if defined(Q_OS_WIN)
    const QString nativeHelper = QDir::toNativeSeparators(helperPath);
    const QString nativeJob = QDir::toNativeSeparators(jobPath);
    const bool launchedDirect = QProcess::startDetached(helperPath, {u"--job"_s, jobPath});
    if (launchedDirect) {
        return true;
    }

    const QString args = u"--job \"%1\""_s.arg(nativeJob);
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
                ? u"Administrator permission was denied."_s
                : u"Failed to launch updater helper (code %1)."_s.arg(rc);
        }
        return false;
    }
    return true;
#else
    const bool launched = QProcess::startDetached(helperPath, {u"--job"_s, jobPath});
    if (!launched && errorOut != nullptr) {
        *errorOut = u"Failed to launch updater helper."_s;
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
    const QString normalized = version.trimmed().isEmpty() ? u"0.0.0"_s : version.trimmed();
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
    m_status = u"Checking for updates..."_s;
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

    QDir updatesDir(QDir(appDataDir).filePath(u"updates"_s));
    if (!updatesDir.exists()) {
        return;
    }

    const QFileInfoList statusFiles = updatesDir.entryInfoList(
        QStringList() << u"update-job-*.json.status.json"_s,
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
    const bool ok = root.value(u"ok"_s).toBool(false);
    const QString message = root.value(u"message"_s).toString().trimmed();
    if (ok) {
        m_error.clear();
        m_status = message.isEmpty()
            ? u"Update applied successfully."_s
            : u"Update: %1"_s.arg(message);
        emit systemLog(u"[Updater] %1"_s.arg(m_status));
    } else {
        m_error = message.isEmpty()
            ? u"Updater helper failed."_s
            : message;
        m_status = u"Install failed."_s;
        emit systemLog(u"[Updater] Install failed: %1"_s.arg(m_error));
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
        m_error = u"No downloadable update asset is available."_s;
        m_status = u"Download unavailable."_s;
        emit changed();
        return false;
    }

    const QString downloadsDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString baseDir = downloadsDir.isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        : downloadsDir;
    if (baseDir.isEmpty()) {
        m_error = u"Could not resolve download directory."_s;
        m_status = u"Download failed."_s;
        emit changed();
        return false;
    }

    QDir().mkpath(baseDir);
    const QString fallbackName = u"genyconnect-update-%1.bin"_s
        .arg(m_latestVersion.isEmpty() ? u"latest"_s : m_latestVersion);
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
        m_error = u"Failed to create update file: %1"_s.arg(m_downloadedFilePath);
        m_status = u"Download failed."_s;
        m_downloadFile->deleteLater();
        m_downloadFile = nullptr;
        emit changed();
        return false;
    }

    m_downloadReceived = 0;
    m_downloadTotal = 0;
    m_checking = true;
    m_error.clear();
    m_status = u"Downloading update..."_s;
    emit changed();

    QNetworkRequest request {QUrl(m_assetUrl)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "GenyConnect-Updater/1.0");
    request.setTransferTimeout(30000);

    m_downloadReply = m_networkManager.get(request);
    connect(m_downloadReply, &QNetworkReply::readyRead, this, &Updater::onDownloadReadyRead);
    connect(m_downloadReply, &QNetworkReply::downloadProgress, this, &Updater::onDownloadProgress);
    connect(m_downloadReply, &QNetworkReply::finished, this, &Updater::onDownloadFinished);

    emit systemLog(u"[Updater] Downloading %1"_s.arg(fileName));
    return true;
}

bool Updater::openDownloadedUpdate()
{
    const QString path = m_downloadedFilePath.trimmed();
    if (path.isEmpty() || !QFileInfo::exists(path)) {
        m_error = u"Downloaded update file was not found."_s;
        emit changed();
        return false;
    }
    return QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

bool Updater::installDownloadedUpdate()
{
    const QString sourcePath = m_downloadedFilePath.trimmed();
    if (sourcePath.isEmpty() || !QFileInfo::exists(sourcePath)) {
        m_error = u"Downloaded update file was not found."_s;
        m_status = u"Install failed."_s;
        emit changed();
        return false;
    }

    if (looksLikeManualInstaller(sourcePath)) {
        m_status = u"This asset requires manual install. Opening installer..."_s;
        m_error.clear();
        emit changed();
        return openDownloadedUpdate();
    }

    const QString expectedSha256 = normalizeSha256Digest(m_assetExpectedSha256);
    if (expectedSha256.isEmpty()) {
        m_error = u"Release does not provide trusted SHA-256 metadata for this asset. Publish digest/checksum first."_s;
        m_status = u"Install blocked."_s;
        emit systemLog(u"[Updater] %1"_s.arg(m_error));
        emit changed();
        return false;
    }

    const QString downloadedHash = fileSha256Hex(sourcePath).toLower();
    if (downloadedHash.isEmpty() || downloadedHash != expectedSha256) {
        m_error = u"Downloaded update hash verification failed."_s;
        m_status = u"Install failed."_s;
        emit systemLog(u"[Updater] %1"_s.arg(m_error));
        emit changed();
        return false;
    }

    const QString helperPath = appUpdaterHelperPath();
    if (!QFileInfo::exists(helperPath)) {
        m_error = u"Updater helper executable not found."_s;
        m_status = u"Install failed."_s;
        emit changed();
        return false;
    }

    const QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (appDir.trimmed().isEmpty()) {
        m_error = u"Could not resolve app data directory."_s;
        m_status = u"Install failed."_s;
        emit changed();
        return false;
    }

    const QString updateDir = QDir(appDir).filePath(u"updates"_s);
    QDir().mkpath(updateDir);

    const QString sourceName = QFileInfo(sourcePath).fileName();
    const QString stagedPath = QDir(updateDir).filePath(u"staged-%1"_s.arg(sourceName));
    if (!copyWithOverwrite(sourcePath, stagedPath)) {
        m_error = u"Failed to stage update file."_s;
        m_status = u"Install failed."_s;
        emit changed();
        return false;
    }

    const QString currentExe = QCoreApplication::applicationFilePath();
#if defined(Q_OS_WIN)
    bool installDirWritable = true;
    {
        const QString exeDir = QFileInfo(currentExe).absolutePath();
        QTemporaryFile probe(QDir(exeDir).filePath(u".__geny_write_probe_XXXXXX.tmp"_s));
        probe.setAutoRemove(true);
        if (!probe.open()) {
            installDirWritable = false;
            emit systemLog(u"[Updater] Install folder is not writable. Will request Administrator permission."_s);
        } else {
            probe.close();
        }
    }
#endif
    const QString backupPath = currentExe + u".backup.old"_s;
    const QString jobPath = QDir(updateDir).filePath(
        u"update-job-%1.json"_s.arg(QString::number(QDateTime::currentMSecsSinceEpoch()))
    );

    QJsonObject job;
    job.insert(u"pid"_s, static_cast<qint64>(QCoreApplication::applicationPid()));
    job.insert(u"current_executable"_s, currentExe);
    job.insert(u"staged_executable"_s, stagedPath);
    job.insert(u"backup_executable"_s, backupPath);
    job.insert(u"working_directory"_s, QCoreApplication::applicationDirPath());
    job.insert(u"expected_sha256"_s, expectedSha256);
    job.insert(u"cleanup_source_on_success"_s, true);
    job.insert(u"timeout_ms"_s, 45000);
    job.insert(u"args"_s, QJsonArray());

    QFile jobFile(jobPath);
    if (!jobFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QFile::remove(stagedPath);
        m_error = u"Failed to write update job file."_s;
        m_status = u"Install failed."_s;
        emit changed();
        return false;
    }
    jobFile.write(QJsonDocument(job).toJson(QJsonDocument::Indented));
    jobFile.close();

    QString launchError;
    if (!startUpdaterHelperDetached(helperPath, jobPath, &launchError)) {
        QFile::remove(jobPath);
        QFile::remove(stagedPath);
        m_error = launchError.isEmpty() ? u"Failed to launch updater helper."_s : launchError;
        m_status = u"Install failed."_s;
        emit systemLog(u"[Updater] %1"_s.arg(m_error));
        emit changed();
        return false;
    }

    m_error.clear();
#if defined(Q_OS_WIN)
    if (!installDirWritable) {
        m_status = u"Waiting for Administrator approval to install update..."_s;
    } else {
        m_status = u"Installing update and restarting..."_s;
    }
#else
    m_status = u"Installing update and restarting..."_s;
#endif
    emit systemLog(u"[Updater] Handed off update to helper process."_s);
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
            apiMessage = statusDoc.object().value(u"message"_s).toString().trimmed();
        }

        if (statusCode == 404 || apiMessage.compare(u"Not Found"_s, Qt::CaseInsensitive) == 0) {
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
            m_status = u"No published release yet. Current version %1."_s.arg(m_appVersion);
            if (m_userInitiatedCheck) {
                emit systemLog(u"[Updater] %1"_s.arg(m_status));
            }
            m_userInitiatedCheck = false;
            emit changed();
            return;
        }

        m_updateAvailable = false;
        m_assetExpectedSha256.clear();
        m_assetChecksumUrl.clear();
        m_error = networkError.isEmpty()
            ? u"Failed to check updates."_s
            : networkError;
        m_status = u"Update check failed."_s;
        if (m_userInitiatedCheck) {
            emit systemLog(u"[Updater] %1"_s.arg(m_error));
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
        m_error = u"Release metadata parse failed."_s;
        m_status = u"Update check failed."_s;
        m_userInitiatedCheck = false;
        emit changed();
        return;
    }

    const QJsonObject root = doc.object();
    const QString latestRaw = root.value(u"tag_name"_s).toString().trimmed();
    const QString latest = normalizeVersionToken(latestRaw);
    m_releaseUrl = root.value(u"html_url"_s).toString().trimmed();
    m_latestVersion = latest;
    m_error.clear();
    m_assetUrl.clear();
    m_assetName.clear();
    m_assetExpectedSha256.clear();
    m_assetChecksumUrl.clear();
    m_downloadedFilePath.clear();
    m_downloadReceived = 0;
    m_downloadTotal = 0;

    const QJsonArray assets = root.value(u"assets"_s).toArray();
    selectBestReleaseAsset(assets, &m_assetUrl, &m_assetName, &m_assetExpectedSha256, &m_assetChecksumUrl);
    if (!m_assetName.isEmpty()) {
        emit systemLog(u"[Updater] Selected asset: %1"_s.arg(m_assetName));
        if (!m_assetExpectedSha256.isEmpty()) {
            emit systemLog(u"[Updater] Found release digest for selected asset."_s);
        } else if (!m_assetChecksumUrl.isEmpty()) {
            emit systemLog(u"[Updater] Using checksum manifest for selected asset."_s);
        } else {
            emit systemLog(u"[Updater] No checksum metadata for selected asset. Install will require a published SHA-256."_s);
        }
    }

    if (latest.isEmpty()) {
        m_updateAvailable = false;
        m_status = u"No version info in release feed."_s;
    } else if (isVersionNewer(m_appVersion, latest)) {
        m_updateAvailable = true;
        m_status = u"Update available: %1"_s.arg(latest);
        emit systemLog(u"[Updater] %1"_s.arg(m_status));
    } else {
        m_updateAvailable = false;
        m_status = u"You are up to date (%1)."_s.arg(m_appVersion);
        if (m_userInitiatedCheck) {
            emit systemLog(u"[Updater] %1"_s.arg(m_status));
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
            ? u"Update download failed."_s
            : errorText;
        m_status = u"Download failed."_s;
        emit systemLog(u"[Updater] %1"_s.arg(m_error));
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
                emit systemLog(u"[Updater] Checksum resolved from manifest for %1."_s.arg(m_assetName));
            } else {
                emit systemLog(u"[Updater] Checksum manifest did not include %1."_s.arg(m_assetName));
            }
        } else if (!manifestError.trimmed().isEmpty()) {
            emit systemLog(u"[Updater] Checksum fetch failed: %1"_s.arg(manifestError.trimmed()));
        }
    }

    if (!m_assetExpectedSha256.isEmpty()) {
        const QString downloadedHash = fileSha256Hex(m_downloadedFilePath).toLower();
        if (downloadedHash.isEmpty() || downloadedHash != m_assetExpectedSha256) {
            QFile::remove(m_downloadedFilePath);
            m_error = u"Downloaded update hash verification failed."_s;
            m_status = u"Download failed."_s;
            emit systemLog(u"[Updater] %1"_s.arg(m_error));
            emit changed();
            return;
        }
        emit systemLog(u"[Updater] Downloaded file hash verified."_s);
    }

    m_error.clear();
    if (m_assetExpectedSha256.isEmpty()) {
        m_status = u"Update downloaded, but release checksum is missing."_s;
    } else {
        m_status = u"Update downloaded. Open installer to continue."_s;
    }
    m_downloadReceived = m_downloadTotal > 0 ? m_downloadTotal : m_downloadReceived;
    emit systemLog(u"[Updater] %1"_s.arg(m_status));
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
        const QString name = obj.value(u"name"_s).toString().trimmed();
        const QString url = obj.value(u"browser_download_url"_s).toString().trimmed();
        if (name.isEmpty() || url.isEmpty()) {
            continue;
        }

        const QString lower = name.toLower();
        const bool mentionsMac = lower.contains(u"mac"_s)
            || lower.contains(u"darwin"_s)
            || lower.contains(u"osx"_s);
        const bool mentionsWin = lower.contains(u"win"_s)
            || lower.contains(u"windows"_s);
        const bool mentionsLinux = lower.contains(u"linux"_s)
            || lower.contains(u"appimage"_s)
            || lower.contains(u".deb"_s)
            || lower.contains(u".rpm"_s);

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

        const bool assetArm = lower.contains(u"arm64"_s) || lower.contains(u"aarch64"_s);
        const bool assetX86 = lower.contains(u"x64"_s)
            || lower.contains(u"x86_64"_s)
            || lower.contains(u"amd64"_s)
            || lower.contains(u"x86-64"_s);
        const bool hostArm = arch.contains(u"arm"_s) || arch.contains(u"aarch64"_s);

        // Hard filter when asset explicitly targets a different architecture.
        if (hostArm && assetX86 && !assetArm) {
            continue;
        }
        if (!hostArm && assetArm && !assetX86) {
            continue;
        }

        int score = 0;
        if (lower.contains(u"genyconnect"_s)) {
            score += 25;
        }
        if (lower.contains(u"selfupdate"_s)) {
            score += 30;
        }

        if (isMac) {
            if (mentionsMac) {
                score += 40;
            }
            if (lower.endsWith(u".dmg"_s)) {
                score += 35;
            } else if (lower.endsWith(u".pkg"_s)) {
                score += 25;
            } else if (lower.endsWith(u".zip"_s)) {
                score += 10;
            }
        } else if (isWin) {
            if (mentionsWin) {
                score += 40;
            }
            if (lower.endsWith(u".exe"_s) || lower.endsWith(u".msi"_s)) {
                score += 35;
            } else if (lower.endsWith(u".zip"_s)) {
                score += 10;
            }
        } else if (isLinux) {
            if (mentionsLinux) {
                score += 40;
            }
            if (lower.endsWith(u".appimage"_s) || lower.endsWith(u".deb"_s) || lower.endsWith(u".rpm"_s)) {
                score += 35;
            } else if (lower.endsWith(u".tar.gz"_s) || lower.endsWith(u".zip"_s)) {
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
            bestDigest = normalizeSha256Digest(obj.value(u"digest"_s).toString());
        }
    }

    if (bestUrl.isEmpty()) {
        const QJsonObject firstObj = assets.first().toObject();
        bestName = firstObj.value(u"name"_s).toString().trimmed();
        bestUrl = firstObj.value(u"browser_download_url"_s).toString().trimmed();
        bestDigest = normalizeSha256Digest(firstObj.value(u"digest"_s).toString());
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
            const QString candidateName = obj.value(u"name"_s).toString().trimmed();
            const QString candidateUrl = obj.value(u"browser_download_url"_s).toString().trimmed();
            if (candidateName.isEmpty() || candidateUrl.isEmpty()) {
                continue;
            }
            const QString candidateLower = candidateName.toLower();
            if (!isLikelyChecksumAsset(candidateLower)) {
                continue;
            }

            int score = 0;
            if (candidateLower == bestNameLower + u".sha256"_s) {
                score += 300;
            } else if (candidateLower == bestNameLower + u".sha256.txt"_s) {
                score += 280;
            } else if (candidateLower.contains(bestNameLower)) {
                score += 180;
            }
            if (candidateLower.contains(u"sha256"_s)) {
                score += 80;
            }
            if (candidateLower.contains(u"checksum"_s)) {
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
        return info.fileName().toLower().endsWith(u".app"_s);
    }
    return !looksLikeManualInstaller(path);
}

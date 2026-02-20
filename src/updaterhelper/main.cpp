#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QByteArrayView>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStringList>
#include <QThread>

#if defined(Q_OS_WIN)
#include <windows.h>
#else
#include <cerrno>
#include <csignal>
#endif

namespace {
struct UpdateJob {
    qint64 pid = 0;
    QString currentExecutable;
    QString stagedExecutable;
    QString backupExecutable;
    QString workingDirectory;
    QString expectedSha256;
    QStringList args;
    int timeoutMs = 45000;
    bool cleanupSourceOnSuccess = true;
};

QString sha256Hex(const QString& path)
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

void writeStatus(const QString& statusPath, bool ok, const QString& message)
{
    QFile file(statusPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return;
    }
    QJsonObject root;
    root.insert(QStringLiteral("ok"), ok);
    root.insert(QStringLiteral("message"), message);
    root.insert(QStringLiteral("time_ms"), QDateTime::currentMSecsSinceEpoch());
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

bool parseJob(const QString& jobPath, UpdateJob* jobOut, QString* errorOut)
{
    if (jobOut == nullptr) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Internal error: null output object.");
        }
        return false;
    }
    QFile file(jobPath);
    if (!file.open(QIODevice::ReadOnly)) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Could not open update job file.");
        }
        return false;
    }
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Update job file is invalid JSON.");
        }
        return false;
    }
    const QJsonObject root = doc.object();
    UpdateJob job;
    job.pid = root.value(QStringLiteral("pid")).toVariant().toLongLong();
    job.currentExecutable = root.value(QStringLiteral("current_executable")).toString().trimmed();
    job.stagedExecutable = root.value(QStringLiteral("staged_executable")).toString().trimmed();
    job.backupExecutable = root.value(QStringLiteral("backup_executable")).toString().trimmed();
    job.workingDirectory = root.value(QStringLiteral("working_directory")).toString().trimmed();
    job.expectedSha256 = root.value(QStringLiteral("expected_sha256")).toString().trimmed().toLower();
    job.timeoutMs = qMax(5000, root.value(QStringLiteral("timeout_ms")).toInt(45000));
    job.cleanupSourceOnSuccess = root.value(QStringLiteral("cleanup_source_on_success")).toBool(true);
    const QJsonArray argsArray = root.value(QStringLiteral("args")).toArray();
    for (const QJsonValue& v : argsArray) {
        job.args.append(v.toString());
    }

    if (job.pid <= 0
        || job.currentExecutable.isEmpty()
        || job.stagedExecutable.isEmpty()
        || job.backupExecutable.isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Update job missing required fields.");
        }
        return false;
    }

    *jobOut = job;
    return true;
}

bool isProcessRunning(qint64 pid)
{
    if (pid <= 0) {
        return false;
    }
#if defined(Q_OS_WIN)
    HANDLE handle = OpenProcess(SYNCHRONIZE, FALSE, static_cast<DWORD>(pid));
    if (handle == nullptr) {
        return false;
    }
    const DWORD rc = WaitForSingleObject(handle, 0);
    CloseHandle(handle);
    return rc == WAIT_TIMEOUT;
#else
    const int rc = kill(static_cast<pid_t>(pid), 0);
    if (rc == 0) {
        return true;
    }
    return errno != ESRCH;
#endif
}

bool waitForProcessExit(qint64 pid, int timeoutMs)
{
    const qint64 started = QDateTime::currentMSecsSinceEpoch();
    while (isProcessRunning(pid)) {
        if (QDateTime::currentMSecsSinceEpoch() - started > timeoutMs) {
            return false;
        }
        QThread::msleep(120);
    }
    return true;
}

bool copyWithOverwrite(const QString& fromPath, const QString& toPath)
{
    if (QFileInfo::exists(toPath) && !QFile::remove(toPath)) {
        return false;
    }
    return QFile::copy(fromPath, toPath);
}

#if defined(Q_OS_WIN)
bool removeWithRetry(const QString& path, int attempts = 40, int delayMs = 150)
{
    for (int i = 0; i < attempts; ++i) {
        if (!QFileInfo::exists(path)) {
            return true;
        }
        if (QFile::remove(path)) {
            return true;
        }
        QThread::msleep(static_cast<unsigned long>(delayMs));
    }
    return !QFileInfo::exists(path);
}

bool renameWithRetry(const QString& fromPath, const QString& toPath, int attempts = 40, int delayMs = 150)
{
    for (int i = 0; i < attempts; ++i) {
        if (QFile::rename(fromPath, toPath)) {
            return true;
        }
        QThread::msleep(static_cast<unsigned long>(delayMs));
    }
    return false;
}
#endif

bool replaceFileAtomically(const QString& currentPath, const QString& stagedPath, const QString& backupPath, QString* errorOut)
{
    if (!QFileInfo::exists(stagedPath)) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Staged file does not exist.");
        }
        return false;
    }

    if (QFileInfo::exists(backupPath)
#if defined(Q_OS_WIN)
        && !removeWithRetry(backupPath)
#else
        && !QFile::remove(backupPath)
#endif
    ) {
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Could not remove stale backup.");
        }
        return false;
    }

    bool movedCurrentToBackup = false;
#if defined(Q_OS_WIN)
    movedCurrentToBackup = renameWithRetry(currentPath, backupPath);
#else
    movedCurrentToBackup = QFile::rename(currentPath, backupPath);
#endif
    if (!movedCurrentToBackup) {
        if (!copyWithOverwrite(currentPath, backupPath) || !QFile::remove(currentPath)) {
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Could not move current executable to backup.");
            }
            return false;
        }
    }

    bool movedStagedToCurrent = false;
#if defined(Q_OS_WIN)
    movedStagedToCurrent = renameWithRetry(stagedPath, currentPath);
#else
    movedStagedToCurrent = QFile::rename(stagedPath, currentPath);
#endif
    if (!movedStagedToCurrent) {
        if (!copyWithOverwrite(stagedPath, currentPath)) {
#if defined(Q_OS_WIN)
            renameWithRetry(backupPath, currentPath);
#else
            QFile::rename(backupPath, currentPath);
#endif
            if (errorOut != nullptr) {
                *errorOut = QStringLiteral("Could not place staged executable.");
            }
            return false;
        }
#if defined(Q_OS_WIN)
        removeWithRetry(stagedPath);
#else
        QFile::remove(stagedPath);
#endif
    }

#if !defined(Q_OS_WIN)
    QFile currentFile(currentPath);
    if (!currentFile.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner
                                  | QFileDevice::ReadGroup | QFileDevice::ExeGroup
                                  | QFileDevice::ReadOther | QFileDevice::ExeOther)) {
        QFile::remove(currentPath);
        QFile::rename(backupPath, currentPath);
        if (errorOut != nullptr) {
            *errorOut = QStringLiteral("Failed to set executable permissions.");
        }
        return false;
    }
#endif

    return true;
}

bool rollback(const UpdateJob& job)
{
    if (!QFileInfo::exists(job.backupExecutable)) {
        return false;
    }
    if (QFileInfo::exists(job.currentExecutable)) {
        QFile::remove(job.currentExecutable);
    }
    if (QFile::rename(job.backupExecutable, job.currentExecutable)) {
        return true;
    }
    return copyWithOverwrite(job.backupExecutable, job.currentExecutable) && QFile::remove(job.backupExecutable);
}
}

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("GenyConnectUpdater"));

    const QStringList args = app.arguments();
    const int jobArgIndex = args.indexOf(QStringLiteral("--job"));
    if (jobArgIndex < 0 || (jobArgIndex + 1) >= args.size()) {
        return 2;
    }

    const QString jobPath = args.at(jobArgIndex + 1);
    const QString statusPath = jobPath + QStringLiteral(".status.json");

    UpdateJob job;
    QString parseError;
    if (!parseJob(jobPath, &job, &parseError)) {
        writeStatus(statusPath, false, parseError);
        return 3;
    }

    if (!waitForProcessExit(job.pid, job.timeoutMs)) {
        writeStatus(statusPath, false, QStringLiteral("Timed out waiting for app process to exit."));
        return 4;
    }

    const QString stagedHash = sha256Hex(job.stagedExecutable);
    if (stagedHash.isEmpty() || (!job.expectedSha256.isEmpty() && stagedHash.toLower() != job.expectedSha256)) {
        writeStatus(statusPath, false, QStringLiteral("Staged file hash verification failed."));
        return 5;
    }

    QString replaceError;
    if (!replaceFileAtomically(job.currentExecutable, job.stagedExecutable, job.backupExecutable, &replaceError)) {
        writeStatus(statusPath, false, replaceError);
        return 6;
    }

    const QString installedHash = sha256Hex(job.currentExecutable);
    if (installedHash.isEmpty() || installedHash.toLower() != stagedHash.toLower()) {
        rollback(job);
        writeStatus(statusPath, false, QStringLiteral("Installed file hash validation failed. Rolled back."));
        return 7;
    }

    if (!QProcess::startDetached(job.currentExecutable, job.args, job.workingDirectory)) {
        rollback(job);
        writeStatus(statusPath, false, QStringLiteral("Failed to relaunch updated application. Rolled back."));
        return 8;
    }

    if (job.cleanupSourceOnSuccess) {
        QFile::remove(job.stagedExecutable);
    }
    QFile::remove(job.backupExecutable);
    QFile::remove(jobPath);
    writeStatus(statusPath, true, QStringLiteral("Update applied successfully."));
    return 0;
}

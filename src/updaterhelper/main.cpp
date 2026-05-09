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
#include <QString>
#include <QStringList>
#include <QThread>

#if defined(Q_OS_WIN)
#include <windows.h>
#else
#include <cerrno>
#include <csignal>
#endif

using namespace Qt::StringLiterals;

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
    root.insert(u"ok"_s, ok);
    root.insert(u"message"_s, message);
    root.insert(u"time_ms"_s, QDateTime::currentMSecsSinceEpoch());
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

bool parseJob(const QString& jobPath, UpdateJob* jobOut, QString* errorOut)
{
    if (jobOut == nullptr) {
        if (errorOut != nullptr) {
            *errorOut = u"Internal error: null output object."_s;
        }
        return false;
    }
    QFile file(jobPath);
    if (!file.open(QIODevice::ReadOnly)) {
        if (errorOut != nullptr) {
            *errorOut = u"Could not open update job file."_s;
        }
        return false;
    }
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        if (errorOut != nullptr) {
            *errorOut = u"Update job file is invalid JSON."_s;
        }
        return false;
    }
    const QJsonObject root = doc.object();
    UpdateJob job;
    job.pid = root.value(u"pid"_s).toVariant().toLongLong();
    job.currentExecutable = root.value(u"current_executable"_s).toString().trimmed();
    job.stagedExecutable = root.value(u"staged_executable"_s).toString().trimmed();
    job.backupExecutable = root.value(u"backup_executable"_s).toString().trimmed();
    job.workingDirectory = root.value(u"working_directory"_s).toString().trimmed();
    job.expectedSha256 = root.value(u"expected_sha256"_s).toString().trimmed().toLower();
    job.timeoutMs = qMax(5000, root.value(u"timeout_ms"_s).toInt(45000));
    job.cleanupSourceOnSuccess = root.value(u"cleanup_source_on_success"_s).toBool(true);
    const QJsonArray argsArray = root.value(u"args"_s).toArray();
    for (const QJsonValue& v : argsArray) {
        job.args.append(v.toString());
    }

    if (job.pid <= 0
        || job.currentExecutable.isEmpty()
        || job.stagedExecutable.isEmpty()
        || job.backupExecutable.isEmpty()) {
        if (errorOut != nullptr) {
            *errorOut = u"Update job missing required fields."_s;
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
            *errorOut = u"Staged file does not exist."_s;
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
            *errorOut = u"Could not remove stale backup."_s;
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
                *errorOut = u"Could not move current executable to backup."_s;
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
                *errorOut = u"Could not place staged executable."_s;
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
            *errorOut = u"Failed to set executable permissions."_s;
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
    app.setApplicationName(u"GenyConnectUpdater"_s);

    const QStringList args = app.arguments();
    const int jobArgIndex = args.indexOf(u"--job"_s);
    if (jobArgIndex < 0 || (jobArgIndex + 1) >= args.size()) {
        return 2;
    }

    const QString jobPath = args.at(jobArgIndex + 1);
    const QString statusPath = jobPath + u".status.json"_s;

    UpdateJob job;
    QString parseError;
    if (!parseJob(jobPath, &job, &parseError)) {
        writeStatus(statusPath, false, parseError);
        return 3;
    }

    if (!waitForProcessExit(job.pid, job.timeoutMs)) {
        writeStatus(statusPath, false, u"Timed out waiting for app process to exit."_s);
        return 4;
    }

    const QString stagedHash = sha256Hex(job.stagedExecutable);
    if (stagedHash.isEmpty() || (!job.expectedSha256.isEmpty() && stagedHash.toLower() != job.expectedSha256)) {
        writeStatus(statusPath, false, u"Staged file hash verification failed."_s);
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
        writeStatus(statusPath, false, u"Installed file hash validation failed. Rolled back."_s);
        return 7;
    }

    if (!QProcess::startDetached(job.currentExecutable, job.args, job.workingDirectory)) {
        rollback(job);
        writeStatus(statusPath, false, u"Failed to relaunch updated application. Rolled back."_s);
        return 8;
    }

    if (job.cleanupSourceOnSuccess) {
        QFile::remove(job.stagedExecutable);
    }
    QFile::remove(job.backupExecutable);
    QFile::remove(jobPath);
    writeStatus(statusPath, true, u"Update applied successfully."_s);
    return 0;
}

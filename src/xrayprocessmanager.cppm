/*!
 * @file        xrayprocessmanager.cppm
 * @brief       Xray process lifecycle and log bridge.
 *
 * @details
 * Wraps `QProcess` for starting/stopping the Xray core executable and
 * streaming stdout/stderr lines to the controller. The module also parses
 * traffic counters and emits Qt signals for UI updates.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QByteArray>
#include <QObject>
#include <QProcess>
#include <QString>

#ifndef Q_MOC_RUN
export module genyconnect.backend.xrayprocessmanager;
#endif

#ifdef Q_MOC_RUN
#define GENYCONNECT_MODULE_EXPORT
#else
#define GENYCONNECT_MODULE_EXPORT export
#endif

/**
 * @class XrayProcessManager
 * @brief Manages Xray process execution and runtime log parsing.
 */
GENYCONNECT_MODULE_EXPORT class XrayProcessManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(qint64 rxBytes READ rxBytes NOTIFY trafficChanged)
    Q_PROPERTY(qint64 txBytes READ txBytes NOTIFY trafficChanged)

public:
    /**
     * @brief Construct process manager.
     * @param parent Optional QObject parent.
     */
    explicit XrayProcessManager(QObject *parent = nullptr);

    /**
     * @brief Set Xray executable path.
     * @param path Executable absolute path.
     */
    void setExecutablePath(const QString& path);

    /**
     * @brief Set working directory for launched process.
     * @param path Working directory.
     */
    void setWorkingDirectory(const QString& path);

    /**
     * @brief Current executable path.
     * @return Executable path string.
     */
    QString executablePath() const;

    /**
     * @brief Whether process is currently running.
     * @return True if process state is running.
     */
    bool isRunning() const;

    /**
     * @brief Accumulated received traffic bytes.
     * @return RX byte count.
     */
    qint64 rxBytes() const;

    /**
     * @brief Accumulated transmitted traffic bytes.
     * @return TX byte count.
     */
    qint64 txBytes() const;

    /**
     * @brief Start Xray process with runtime config.
     * @param configPath Path to generated JSON config.
     * @param errorMessage Optional output message on failure.
     * @return True on successful start dispatch.
     */
    bool start(const QString& configPath, QString* errorMessage = nullptr);

    /**
     * @brief Stop the process gracefully (with forced fallback).
     * @param timeoutMs Grace period before force kill.
     */
    void stop(int timeoutMs = 5000);

signals:
    //! Emitted when `running` state changes.
    void runningChanged();
    //! Emitted right after process start signal.
    void started();
    //! Emitted after process exits.
    void stopped(int exitCode, QProcess::ExitStatus exitStatus);
    //! Emitted when process-related error occurs.
    void errorOccurred(const QString& error);
    //! Emitted for each parsed log line.
    void logLine(const QString& line);
    //! Emitted when rx/tx counters update.
    void trafficChanged();

private slots:
    //! Handle stdout bytes from process.
    void onReadyReadStandardOutput();
    //! Handle stderr bytes from process.
    void onReadyReadStandardError();
    //! Handle QProcess started signal.
    void onProcessStarted();
    //! Handle QProcess finished signal.
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    //! Handle QProcess error signal.
    void onProcessError(QProcess::ProcessError processError);

private:
    /**
     * @brief Split chunk into full lines and emit through callback.
     * @param buffer Persistent line buffer.
     * @param chunk Newly received bytes.
     */
    void parseAndEmitLines(QByteArray& buffer, const QByteArray& chunk);

    /**
     * @brief Process one normalized log line.
     * @param line Parsed log line text.
     */
    void handleLogLine(const QString& line);

    /**
     * @brief Parse traffic stats from log line when available.
     * @param line Parsed log line text.
     */
    void parseTraffic(const QString& line);

    /**
     * @brief Utility to write error text.
     * @param errorMessage Optional output pointer.
     * @param error Error string.
     */
    void setError(QString* errorMessage, const QString& error);

    QProcess m_process;          //!< Managed Xray child process.
    QString m_executablePath;    //!< Resolved executable path.
    QString m_workingDirectory;  //!< Working directory for process.
    QByteArray m_stdoutBuffer;   //!< Buffered stdout bytes for line splitting.
    QByteArray m_stderrBuffer;   //!< Buffered stderr bytes for line splitting.

    qint64 m_rxBytes = 0;        //!< Aggregated downstream bytes.
    qint64 m_txBytes = 0;        //!< Aggregated upstream bytes.
};

#include "xrayprocessmanager.moc"

/*!
 * @file        updater.cppm
 * @brief       Self-update manager for GenyConnect.
 *
 * @details
 * Provides a GitHub Releases based updater workflow:
 * - checks latest release metadata
 * - compares semantic versions against current app version
 * - selects best asset for current platform/architecture
 * - downloads installer/archive
 * - opens release page or downloaded installer
 *
 * This class is intentionally isolated from VPN runtime orchestration so
 * UI update actions do not bloat controller responsibilities.
 *
 * @author      Kambiz Asadzadeh
 * @since       17 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QFile>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QString>

export module genyconnect.backend.updater;

/**
 * @class Updater
 * @brief Handles app update check/download lifecycle.
 */
export class Updater : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appVersion READ appVersion WRITE setAppVersion NOTIFY changed)
    Q_PROPERTY(bool checking READ checking NOTIFY changed)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY changed)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY changed)
    Q_PROPERTY(QString status READ status NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(double downloadProgress READ downloadProgress NOTIFY changed)
    Q_PROPERTY(QString releaseUrl READ releaseUrl NOTIFY changed)
    Q_PROPERTY(QString downloadedFilePath READ downloadedFilePath NOTIFY changed)

public:
    /**
     * @brief Construct updater object.
     * @param parent Optional QObject parent.
     */
    explicit Updater(QObject *parent = nullptr);

    /**
     * @brief Destroy updater and abort active requests.
     */
    ~Updater() override;

    /**
     * @brief Current app version used for comparison.
     * @return Version string.
     */
    QString appVersion() const;

    /**
     * @brief Set current app version used for comparison.
     * @param version Version string.
     */
    void setAppVersion(const QString& version);

    /**
     * @brief Whether updater is currently checking/downloading.
     * @return Busy flag.
     */
    bool checking() const;

    /**
     * @brief Whether newer version exists.
     * @return Availability flag.
     */
    bool updateAvailable() const;

    /**
     * @brief Latest discovered version.
     * @return Version string.
     */
    QString latestVersion() const;

    /**
     * @brief Human-readable updater status.
     * @return Status string.
     */
    QString status() const;

    /**
     * @brief Last updater error.
     * @return Error string.
     */
    QString error() const;

    /**
     * @brief Download progress in [0, 1].
     * @return Progress value.
     */
    double downloadProgress() const;

    /**
     * @brief Latest release page URL.
     * @return URL string.
     */
    QString releaseUrl() const;

    /**
     * @brief Local path of downloaded update asset.
     * @return File path string.
     */
    QString downloadedFilePath() const;

    /**
     * @brief Check latest release metadata.
     * @param userInitiated True if triggered manually by user.
     */
    Q_INVOKABLE void checkForUpdates(bool userInitiated = true);

    /**
     * @brief Download selected update asset.
     * @return True when download request started.
     */
    Q_INVOKABLE bool downloadUpdate();

    /**
     * @brief Open downloaded installer/archive file.
     * @return True when open request dispatched.
     */
    Q_INVOKABLE bool openDownloadedUpdate();

    /**
     * @brief Open release page in browser.
     * @return True when open request dispatched.
     */
    Q_INVOKABLE bool openReleasePage();

signals:
    //! Emitted when any updater state changes.
    void changed();
    //! Emitted for log lines that host controller can forward.
    void systemLog(const QString& line);

private slots:
    //! Handle metadata request completion.
    void onCheckFinished();
    //! Handle download stream bytes.
    void onDownloadReadyRead();
    //! Handle download progress updates.
    void onDownloadProgress(qint64 received, qint64 total);
    //! Handle download completion.
    void onDownloadFinished();

private:
    /**
     * @brief Compare semantic versions.
     * @param currentVersion Current app version.
     * @param candidateVersion Candidate version from release.
     * @return True if candidate is newer.
     */
    static bool isVersionNewer(const QString& currentVersion, const QString& candidateVersion);

    /**
     * @brief Choose best asset for current platform.
     * @param assets Release assets array.
     * @param assetUrl Output URL.
     * @param assetName Output filename.
     * @return True if an asset was selected.
     */
    static bool selectBestReleaseAsset(const QJsonArray& assets, QString *assetUrl, QString *assetName);

    QString m_appVersion = QStringLiteral("0.0.0");
    bool m_checking = false;
    bool m_updateAvailable = false;
    bool m_userInitiatedCheck = false;
    QString m_latestVersion;
    QString m_status = QStringLiteral("Idle");
    QString m_error;
    QString m_releaseUrl = QStringLiteral("https://github.com/genyleap/GenyConnect/releases");
    QString m_assetUrl;
    QString m_assetName;
    QString m_downloadedFilePath;
    qint64 m_downloadReceived = 0;
    qint64 m_downloadTotal = 0;

    QNetworkAccessManager m_networkManager;
    QNetworkReply *m_checkReply = nullptr;
    QNetworkReply *m_downloadReply = nullptr;
    QFile *m_downloadFile = nullptr;
};

#include "updater.moc"

/*!
 * @file        serverprofilemodel.cppm
 * @brief       Qt list-model wrapper for server profiles.
 *
 * @details
 * Exposes imported profiles through `QAbstractListModel` so QML views can
 * display and select connection entries. The model provides role mappings,
 * lookup helpers, and update operations used by the controller layer.
 *
 * @author      Kambiz Asadzadeh
 * @since       09 Feb 2026
 * @copyright   Copyright (c) 2026 Genyleap.
 * @license     See LICENSE in repository root.
 */

module;
#include <QAbstractListModel>
#include <QByteArray>
#include <QHash>
#include <QList>
#include <QString>
#include <QVariant>

#include <optional>

#ifndef Q_MOC_RUN
export module genyconnect.backend.serverprofilemodel;
import genyconnect.backend.serverprofile;
#endif

#ifdef Q_MOC_RUN
struct ServerProfile;
#define GENYCONNECT_MODULE_EXPORT
#else
#define GENYCONNECT_MODULE_EXPORT export
#endif

GENYCONNECT_MODULE_EXPORT class ServerProfileModel : public QAbstractListModel
{
    Q_OBJECT

public:
    /**
     * @enum Roles
     * @brief Custom model roles exposed to QML.
     */
    enum Roles {
        IdRole = Qt::UserRole + 1, //!< Profile unique id.
        NameRole,                  //!< Profile name.
        ProtocolRole,              //!< Protocol string.
        AddressRole,               //!< Host/address.
        PortRole,                  //!< Port number.
        SecurityRole,              //!< Security mode.
        DisplayLabelRole,          //!< Pre-formatted label.
        PingMsRole,                //!< Last ping in milliseconds.
        PingTextRole,              //!< Formatted ping label.
        PingingRole                //!< True while ping is in progress.
    };

    /**
     * @brief Construct an empty profile model.
     * @param parent Optional QObject parent.
     */
    explicit ServerProfileModel(QObject *parent = nullptr);

    /**
     * @brief Number of items in the model.
     * @param parent Parent index (unused for flat model).
     * @return Row count.
     */
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

    /**
     * @brief Return data for a row and role.
     * @param index Row index.
     * @param role Requested role.
     * @return QVariant payload for role.
     */
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    /**
     * @brief Expose role name mapping for QML.
     * @return Role name hash.
     */
    QHash<int, QByteArray> roleNames() const override;

    /**
     * @brief Access all profiles.
     * @return Immutable profile list reference.
     */
    const QList<ServerProfile>& profiles() const;

    /**
     * @brief Get profile at row.
     * @param row Row index.
     * @return Profile value or empty optional.
     */
    std::optional<ServerProfile> profileAt(int row) const;

    /**
     * @brief Find row by profile id.
     * @param id Profile identifier.
     * @return Matching row index or -1.
     */
    int indexOfId(const QString& id) const;

    /**
     * @brief Replace all model rows with input list.
     * @param profiles New profile collection.
     */
    void setProfiles(const QList<ServerProfile>& profiles);

    /**
     * @brief Insert one profile if non-duplicate.
     * @param profile Candidate profile.
     * @return True when insertion succeeds.
     */
    bool addProfile(const ServerProfile& profile);

    /**
     * @brief Remove profile at row.
     * @param row Row index.
     * @return True when removal succeeds.
     */
    bool removeAt(int row);

    /**
     * @brief Update profile ping state for a row.
     * @param row Row index.
     * @param pinging True while ping probe is running.
     * @return True on success.
     */
    bool setPinging(int row, bool pinging);

    /**
     * @brief Update profile ping result for a row.
     * @param row Row index.
     * @param pingMs Measured ping in ms, or negative if unavailable.
     * @return True on success.
     */
    bool setPingResult(int row, int pingMs);

private:
    /**
     * @brief Locate profile with equivalent endpoint credentials.
     * @param candidate Profile to compare.
     * @return Existing row index or -1.
     */
    int findEquivalentProfile(const ServerProfile& candidate) const;

    QList<ServerProfile> m_profiles; //!< Internal profile storage.
};

#include "serverprofilemodel.moc"

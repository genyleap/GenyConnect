module;
#include <QByteArray>
#include <QHash>
#include <QModelIndex>
#include <QString>
#include <QVariant>
#include <Qt>

#include <optional>

module genyconnect.backend.serverprofilemodel;

ServerProfileModel::ServerProfileModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ServerProfileModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_profiles.size();
}

QVariant ServerProfileModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_profiles.size()) {
        return {};
    }

    const auto& profile = m_profiles.at(index.row());

    switch (role) {
    case IdRole:
        return profile.id;
    case NameRole:
        return profile.name;
    case ProtocolRole:
        return profile.protocol;
    case AddressRole:
        return profile.address;
    case PortRole:
        return profile.port;
    case SecurityRole:
        return profile.security;
    case DisplayLabelRole:
        return profile.displayLabel();
    case GroupRole:
        return profile.groupName;
    case SourceRole:
        return profile.sourceName;
    case PingMsRole:
        return profile.lastPingMs;
    case PingTextRole:
        if (profile.pingInProgress) {
            return QStringLiteral("Pinging...");
        }
        return profile.lastPingMs >= 0
            ? QStringLiteral("%1 ms").arg(profile.lastPingMs)
            : QStringLiteral("--");
    case PingingRole:
        return profile.pingInProgress;
    default:
        return {};
    }
}

QHash<int, QByteArray> ServerProfileModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {NameRole, "name"},
        {ProtocolRole, "protocol"},
        {AddressRole, "address"},
        {PortRole, "port"},
        {SecurityRole, "security"},
        {DisplayLabelRole, "displayLabel"},
        {GroupRole, "groupName"},
        {SourceRole, "sourceName"},
        {PingMsRole, "pingMs"},
        {PingTextRole, "pingText"},
        {PingingRole, "pinging"},
    };
}

const QList<ServerProfile>& ServerProfileModel::profiles() const
{
    return m_profiles;
}

std::optional<ServerProfile> ServerProfileModel::profileAt(int row) const
{
    if (row < 0 || row >= m_profiles.size()) {
        return std::nullopt;
    }

    return m_profiles.at(row);
}

int ServerProfileModel::indexOfId(const QString& id) const
{
    if (id.trimmed().isEmpty()) {
        return -1;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        if (m_profiles.at(i).id == id) {
            return i;
        }
    }

    return -1;
}

void ServerProfileModel::setProfiles(const QList<ServerProfile>& profiles)
{
    beginResetModel();
    m_profiles = profiles;
    endResetModel();
}

bool ServerProfileModel::addProfile(const ServerProfile& profile)
{
    if (!profile.isValid()) {
        return false;
    }

    const int existingIdx = findEquivalentProfile(profile);
    if (existingIdx >= 0) {
        m_profiles[existingIdx] = profile;
        emit dataChanged(index(existingIdx), index(existingIdx));
        return true;
    }

    const int row = m_profiles.size();
    beginInsertRows(QModelIndex(), row, row);
    m_profiles.append(profile);
    endInsertRows();
    return true;
}

bool ServerProfileModel::removeAt(int row)
{
    if (row < 0 || row >= m_profiles.size()) {
        return false;
    }

    beginRemoveRows(QModelIndex(), row, row);
    m_profiles.removeAt(row);
    endRemoveRows();
    return true;
}

bool ServerProfileModel::setPinging(int row, bool pinging)
{
    if (row < 0 || row >= m_profiles.size()) {
        return false;
    }

    auto& profile = m_profiles[row];
    if (profile.pingInProgress == pinging) {
        return true;
    }

    profile.pingInProgress = pinging;
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {PingTextRole, PingingRole});
    return true;
}

bool ServerProfileModel::setPingResult(int row, int pingMs)
{
    if (row < 0 || row >= m_profiles.size()) {
        return false;
    }

    auto& profile = m_profiles[row];
    const int normalizedPing = pingMs >= 0 ? pingMs : -1;
    if (profile.lastPingMs == normalizedPing && !profile.pingInProgress) {
        return true;
    }

    profile.lastPingMs = normalizedPing;
    profile.pingInProgress = false;
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {PingMsRole, PingTextRole, PingingRole});
    return true;
}

int ServerProfileModel::findEquivalentProfile(const ServerProfile& candidate) const
{
    const QString candidateProtocol = candidate.protocol.trimmed();
    const QString candidateAddress = candidate.address.trimmed();
    const QString candidateUserId = candidate.userId.trimmed();
    const QString candidateLink = candidate.originalLink.trimmed();

    for (int i = 0; i < m_profiles.size(); ++i) {
        const auto &existing = m_profiles.at(i);
        const QString existingProtocol = existing.protocol.trimmed();
        const QString existingAddress = existing.address.trimmed();
        const QString existingUserId = existing.userId.trimmed();
        const QString existingLink = existing.originalLink.trimmed();

        const bool sameIdentity =
            existingProtocol.compare(candidateProtocol, Qt::CaseInsensitive) == 0
            && existingAddress.compare(candidateAddress, Qt::CaseInsensitive) == 0
            && existing.port == candidate.port
            && existingUserId.compare(candidateUserId, Qt::CaseInsensitive) == 0;
        const bool sameOriginalLink =
            !candidateLink.isEmpty()
            && existingLink.compare(candidateLink, Qt::CaseSensitive) == 0;

        if (sameIdentity
            || sameOriginalLink
            || (!candidate.id.isEmpty() && existing.id == candidate.id)) {
            return i;
        }
    }

    return -1;
}

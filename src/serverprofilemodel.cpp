module;
#include <QByteArray>
#include <QHash>
#include <QModelIndex>
#include <QString>
#include <QVariant>
#include <Qt>
#include <QtGlobal>

#include <optional>

module genyconnect.backend.serverprofilemodel;

void ServerProfileModel::__geny_vtable_anchor() {}

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
    case OriginalLinkRole:
        return profile.originalLink;
    case PingMsRole:
        return profile.lastPingMs;
    case PingTextRole:
        if (profile.pingInProgress) {
            return QString::fromUtf8("Pinging...");
        }
        return profile.lastPingMs >= 0
            ? QString::fromUtf8("%1 ms").arg(profile.lastPingMs)
            : QString::fromUtf8("--");
    case PacketLossPctRole:
        return profile.lastPacketLossPct;
    case PacketLossTextRole:
        return profile.lastPacketLossPct >= 0.0
            ? QString::fromUtf8("%1%").arg(QString::number(profile.lastPacketLossPct, 'f', profile.lastPacketLossPct < 1.0 ? 1 : 0))
            : QString::fromUtf8("--");
    case PingingRole:
        return profile.pingInProgress;
    case ManualOrderRole:
        return profile.manualOrder;
    case LastSuccessfulConnectionRole:
        return profile.lastSuccessfulConnectionMs;
    case FailureCountRole:
        return profile.failureCount;
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
        {OriginalLinkRole, "originalLink"},
        {PingMsRole, "pingMs"},
        {PingTextRole, "pingText"},
        {PacketLossPctRole, "packetLossPct"},
        {PacketLossTextRole, "packetLossText"},
        {PingingRole, "pinging"},
        {ManualOrderRole, "manualOrder"},
        {LastSuccessfulConnectionRole, "lastSuccessfulConnectionMs"},
        {FailureCountRole, "failureCount"},
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
    const QString needle = id.trimmed();
    if (needle.isEmpty()) {
        return -1;
    }

    for (int i = 0; i < m_profiles.size(); ++i) {
        const QString existingId = m_profiles.at(i).id.trimmed();
        if (existingId == needle) {
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

    const int existingIdx = !profile.id.trimmed().isEmpty()
        ? indexOfId(profile.id.trimmed())
        : -1;
    if (existingIdx >= 0) {
        ServerProfile updated = profile;
        const ServerProfile& existing = m_profiles.at(existingIdx);

        // Preserve stable identity and prior ping sample when the caller is
        // explicitly replacing an existing profile by id.
        if (updated.id.trimmed().isEmpty() || updated.id != existing.id) {
            updated.id = existing.id;
        }
        updated.lastPingMs = existing.lastPingMs;
        updated.lastPacketLossPct = existing.lastPacketLossPct;
        updated.manualOrder = existing.manualOrder;
        updated.lastSuccessfulConnectionMs = existing.lastSuccessfulConnectionMs;
        updated.failureCount = existing.failureCount;
        updated.pingInProgress = false;

        m_profiles[existingIdx] = updated;
        emit dataChanged(index(existingIdx), index(existingIdx));
        return true;
    }

    const int row = m_profiles.size();
    ServerProfile inserted = profile;
    inserted.manualOrder = row;
    beginInsertRows(QModelIndex(), row, row);
    m_profiles.append(inserted);
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

bool ServerProfileModel::setPingResult(int row, int pingMs, double packetLossPct)
{
    if (row < 0 || row >= m_profiles.size()) {
        return false;
    }

    auto& profile = m_profiles[row];
    const int normalizedPing = pingMs >= 0 ? pingMs : -1;
    const double normalizedLoss = packetLossPct >= 0.0
        ? qBound(0.0, packetLossPct, 100.0)
        : -1.0;
    if (profile.lastPingMs == normalizedPing
        && qFuzzyCompare(profile.lastPacketLossPct + 1.0, normalizedLoss + 1.0)
        && !profile.pingInProgress) {
        return true;
    }

    profile.lastPingMs = normalizedPing;
    profile.lastPacketLossPct = normalizedLoss;
    profile.pingInProgress = false;
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {PingMsRole, PingTextRole, PacketLossPctRole, PacketLossTextRole, PingingRole});
    return true;
}

bool ServerProfileModel::moveProfile(int fromRow, int toRow)
{
    if (fromRow < 0 || fromRow >= m_profiles.size()
        || toRow < 0 || toRow >= m_profiles.size()
        || fromRow == toRow) {
        return false;
    }

    const int destination = toRow > fromRow ? toRow + 1 : toRow;
    beginMoveRows(QModelIndex(), fromRow, fromRow, QModelIndex(), destination);
    m_profiles.move(fromRow, toRow);
    endMoveRows();

    for (int i = 0; i < m_profiles.size(); ++i) {
        m_profiles[i].manualOrder = i;
    }
    emit dataChanged(index(qMin(fromRow, toRow)), index(qMax(fromRow, toRow)), {ManualOrderRole});
    return true;
}

bool ServerProfileModel::setRuntimeStats(const QString& profileId, qint64 lastSuccessfulConnectionMs, int failureCount)
{
    const int row = indexOfId(profileId);
    if (row < 0) {
        return false;
    }

    auto& profile = m_profiles[row];
    const qint64 normalizedSuccess = qMax<qint64>(0, lastSuccessfulConnectionMs);
    const int normalizedFailures = qMax(0, failureCount);
    if (profile.lastSuccessfulConnectionMs == normalizedSuccess
        && profile.failureCount == normalizedFailures) {
        return true;
    }

    profile.lastSuccessfulConnectionMs = normalizedSuccess;
    profile.failureCount = normalizedFailures;
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {LastSuccessfulConnectionRole, FailureCountRole});
    return true;
}

int ServerProfileModel::findEquivalentProfile(const ServerProfile& candidate) const
{
    for (int i = 0; i < m_profiles.size(); ++i) {
        const auto &existing = m_profiles.at(i);
        if (!candidate.id.isEmpty() && existing.id == candidate.id) {
            return i;
        }
    }

    return -1;
}

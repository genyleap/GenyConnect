#include "runtime/desktopvpnruntime.hpp"

#include <QFileInfo>
#include <QRegularExpression>
#include <QTimer>

DesktopVpnRuntime::DesktopVpnRuntime(QObject *parent)
    : VpnRuntimeBackend(parent)
{
    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        parseAndEmitLines(m_stdoutBuffer, m_process.readAllStandardOutput());
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        parseAndEmitLines(m_stderrBuffer, m_process.readAllStandardError());
    });
    connect(&m_process, &QProcess::started, this, [this]() {
        emit started();
    });
    connect(&m_process, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        parseAndEmitLines(m_stdoutBuffer, QByteArray("\n"));
        parseAndEmitLines(m_stderrBuffer, QByteArray("\n"));
        emit stopped(exitCode, exitStatus);
    });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
        m_lastError = m_process.errorString().trimmed();
        emit errorOccurred(m_lastError);
    });
}

DesktopVpnRuntime::~DesktopVpnRuntime() = default;

QString DesktopVpnRuntime::backendName() const
{
    return QString::fromUtf8("desktop");
}

VpnRuntimeCapabilities DesktopVpnRuntime::capabilities() const
{
    VpnRuntimeCapabilities caps;
    caps.isMobile = false;
    caps.isDesktop = true;
    caps.supportsTun = true;
#if defined(Q_OS_MACOS)
    caps.supportsSystemProxy = true;
#else
    // System proxy manager is currently implemented for macOS only.
    caps.supportsSystemProxy = false;
#endif
#if defined(Q_OS_WIN) || defined(Q_OS_LINUX)
    caps.supportsPerAppRouting = true;
#else
    caps.supportsPerAppRouting = false;
#endif
    caps.supportsAutoUpdate = true;
    caps.requiresVpnPermission = false;
    caps.requiresForegroundService = false;
    caps.requiresNetworkExtension = false;
    return caps;
}

bool DesktopVpnRuntime::initialize(QString *errorMessage)
{
    m_lastError.clear();
    if (errorMessage) {
        errorMessage->clear();
    }
    return true;
}

bool DesktopVpnRuntime::connectRuntime(
    const QString& executablePath,
    const QString& configPath,
    const QString& workingDirectory,
    QString *errorMessage)
{
    m_lastError.clear();

    if (isRunning()) {
        m_lastError = QString::fromUtf8("xray-core is already running.");
    } else if (executablePath.trimmed().isEmpty()) {
        m_lastError = QString::fromUtf8("xray-core executable path is not set.");
    } else {
        QFileInfo executableInfo(executablePath);
        if (!executableInfo.exists()) {
            m_lastError = QString::fromUtf8("xray-core executable not found: %1").arg(executablePath);
        } else {
            m_rxBytes = 0;
            m_txBytes = 0;
            emit trafficChanged();

            m_stdoutBuffer.clear();
            m_stderrBuffer.clear();

            m_process.setProgram(executablePath);
            m_process.setArguments({QString::fromUtf8("run"), QString::fromUtf8("-config"), configPath});
            if (!workingDirectory.trimmed().isEmpty()) {
                m_process.setWorkingDirectory(workingDirectory);
            }
            m_process.start();
            if (errorMessage) {
                errorMessage->clear();
            }
            return true;
        }
    }

    if (errorMessage) {
        *errorMessage = m_lastError;
    }
    return false;
}

bool DesktopVpnRuntime::disconnectRuntime(QString *errorMessage, int timeoutMs)
{
    if (!isRunning()) {
        if (errorMessage) {
            errorMessage->clear();
        }
        return true;
    }

    m_process.terminate();
    if (timeoutMs <= 0) {
        QTimer::singleShot(2000, this, [this]() {
            if (isRunning()) {
                m_process.kill();
            }
        });
    } else if (!m_process.waitForFinished(timeoutMs)) {
        m_process.kill();
        m_process.waitForFinished(2000);
    }

    if (errorMessage) {
        errorMessage->clear();
    }
    return true;
}

bool DesktopVpnRuntime::isRunning() const
{
    return m_process.state() != QProcess::NotRunning;
}

qint64 DesktopVpnRuntime::processId() const
{
    if (!isRunning()) {
        return -1;
    }
    return static_cast<qint64>(m_process.processId());
}

qint64 DesktopVpnRuntime::rxBytes() const
{
    return m_rxBytes;
}

qint64 DesktopVpnRuntime::txBytes() const
{
    return m_txBytes;
}

QString DesktopVpnRuntime::lastError() const
{
    return m_lastError;
}

void DesktopVpnRuntime::parseAndEmitLines(QByteArray& buffer, const QByteArray& chunk)
{
    if (!chunk.isEmpty()) {
        buffer.append(chunk);
    }

    int newlineIndex = buffer.indexOf('\n');
    while (newlineIndex >= 0) {
        const QByteArray lineBytes = buffer.left(newlineIndex).trimmed();
        buffer.remove(0, newlineIndex + 1);

        if (!lineBytes.isEmpty()) {
            handleLogLine(QString::fromUtf8(lineBytes));
        }
        newlineIndex = buffer.indexOf('\n');
    }
}

void DesktopVpnRuntime::handleLogLine(const QString& line)
{
    emit logLine(line);
    parseTraffic(line);
}

void DesktopVpnRuntime::parseTraffic(const QString& line)
{
    static const QRegularExpression rxPattern(
        QString::fromUtf8("(?:\\brx\\b|\\bdown(?:link)?\\b)\\D*(\\d+)"));
    static const QRegularExpression txPattern(
        QString::fromUtf8("(?:\\btx\\b|\\bup(?:link)?\\b)\\D*(\\d+)"));

    bool changed = false;
    const auto rxMatch = rxPattern.match(line.toLower());
    if (rxMatch.hasMatch()) {
        const qint64 delta = rxMatch.captured(1).toLongLong();
        if (delta > 0) {
            m_rxBytes += delta;
            changed = true;
        }
    }
    const auto txMatch = txPattern.match(line.toLower());
    if (txMatch.hasMatch()) {
        const qint64 delta = txMatch.captured(1).toLongLong();
        if (delta > 0) {
            m_txBytes += delta;
            changed = true;
        }
    }
    if (changed) {
        emit trafficChanged();
    }
}

module;
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>

module genyconnect.backend.xrayprocessmanager;

XrayProcessManager::XrayProcessManager(QObject* parent)
    : QObject(parent)
{
    connect(&m_process,& QProcess::readyReadStandardOutput, this,& XrayProcessManager::onReadyReadStandardOutput);
    connect(&m_process,& QProcess::readyReadStandardError, this,& XrayProcessManager::onReadyReadStandardError);
    connect(&m_process,& QProcess::started, this,& XrayProcessManager::onProcessStarted);
    connect(&m_process,& QProcess::finished, this,& XrayProcessManager::onProcessFinished);
    connect(&m_process,& QProcess::errorOccurred, this,& XrayProcessManager::onProcessError);
}

void XrayProcessManager::setExecutablePath(const QString& path)
{
    m_executablePath = path;
}

void XrayProcessManager::setWorkingDirectory(const QString& path)
{
    m_workingDirectory = path;
}

QString XrayProcessManager::executablePath() const
{
    return m_executablePath;
}

bool XrayProcessManager::isRunning() const
{
    return m_process.state() != QProcess::NotRunning;
}

qint64 XrayProcessManager::rxBytes() const
{
    return m_rxBytes;
}

qint64 XrayProcessManager::txBytes() const
{
    return m_txBytes;
}

bool XrayProcessManager::start(const QString& configPath, QString *errorMessage)
{
    if (isRunning()) {
        setError(errorMessage, QStringLiteral("xray-core is already running."));
        return false;
    }

    if (m_executablePath.trimmed().isEmpty()) {
        setError(errorMessage, QStringLiteral("xray-core executable path is not set."));
        return false;
    }

    QFileInfo executableInfo(m_executablePath);
    if (!executableInfo.exists()) {
        setError(errorMessage, QStringLiteral("xray-core executable not found: %1").arg(m_executablePath));
        return false;
    }

    m_rxBytes = 0;
    m_txBytes = 0;
    emit trafficChanged();

    m_stdoutBuffer.clear();
    m_stderrBuffer.clear();

    m_process.setProgram(m_executablePath);
    m_process.setArguments({QStringLiteral("run"), QStringLiteral("-config"), configPath});

    if (!m_workingDirectory.trimmed().isEmpty()) {
        m_process.setWorkingDirectory(m_workingDirectory);
    }

    m_process.start();
    Q_UNUSED(errorMessage)
    return true;
}

void XrayProcessManager::stop(int timeoutMs)
{
    if (!isRunning()) {
        return;
    }

    m_process.terminate();
    if (!m_process.waitForFinished(timeoutMs)) {
        m_process.kill();
        m_process.waitForFinished(2000);
    }
}

void XrayProcessManager::onReadyReadStandardOutput()
{
    parseAndEmitLines(m_stdoutBuffer, m_process.readAllStandardOutput());
}

void XrayProcessManager::onReadyReadStandardError()
{
    parseAndEmitLines(m_stderrBuffer, m_process.readAllStandardError());
}

void XrayProcessManager::onProcessStarted()
{
    emit runningChanged();
    emit started();
}

void XrayProcessManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    parseAndEmitLines(m_stdoutBuffer, QByteArray("\n"));
    parseAndEmitLines(m_stderrBuffer, QByteArray("\n"));

    emit runningChanged();
    emit stopped(exitCode, exitStatus);
}

void XrayProcessManager::onProcessError(QProcess::ProcessError processError)
{
    Q_UNUSED(processError)
    emit errorOccurred(m_process.errorString());
}

void XrayProcessManager::parseAndEmitLines(QByteArray& buffer, const QByteArray& chunk)
{
    if (!chunk.isEmpty()) {
        buffer.append(chunk);
    }

    int newLineIndex = buffer.indexOf('\n');
    while (newLineIndex >= 0) {
        const QByteArray lineBytes = buffer.left(newLineIndex).trimmed();
        buffer.remove(0, newLineIndex + 1);

        if (!lineBytes.isEmpty()) {
            handleLogLine(QString::fromUtf8(lineBytes));
        }

        newLineIndex = buffer.indexOf('\n');
    }
}

void XrayProcessManager::handleLogLine(const QString& line)
{
    emit logLine(line);
    parseTraffic(line);
}

void XrayProcessManager::parseTraffic(const QString& line)
{
    static const QRegularExpression rxPattern(
        QStringLiteral("(?:\\brx\\b|\\bdown(?:link)?\\b)\\D*(\\d+)")
    );
    static const QRegularExpression txPattern(
        QStringLiteral("(?:\\btx\\b|\\bup(?:link)?\\b)\\D*(\\d+)")
    );

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

void XrayProcessManager::setError(QString* errorMessage, const QString& error)
{
    if (errorMessage) {
        *errorMessage = error;
    }
}

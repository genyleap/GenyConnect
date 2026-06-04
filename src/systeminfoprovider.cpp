module;
#include <QCoreApplication>
#include <QFile>
#include <QGuiApplication>
#include <QIODevice>
#include <QScreen>
#include <QSize>
#include <QStringList>
#include <QSysInfo>
#include <QtGlobal>
#include <QVariantMap>

#if defined(Q_OS_ANDROID)
#include <QtCore/qnativeinterface.h>
#endif

#if defined(Q_OS_WIN)
extern "C" {
#include <windows.h>
}
#endif

#if defined(Q_OS_MACOS)
#include <sys/sysctl.h>
#include <unistd.h>
#endif

#if defined(Q_OS_LINUX) || defined(Q_OS_ANDROID)
#include <unistd.h>
#endif

module genyconnect.backend.systeminfoprovider;

namespace {

QString formatBytesFallback(qint64 bytes)
{
    double value = static_cast<double>(qMax<qint64>(0, bytes));
    static const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    int unit = 0;
    while (value >= 1024.0 && unit < 4) {
        value /= 1024.0;
        ++unit;
    }

    if (unit == 0) {
        return QString::fromUtf8("%1 B").arg(static_cast<qint64>(value));
    }
    return QString::fromUtf8("%1 %2").arg(value, 0, 'f', value >= 10.0 ? 1 : 2).arg(QString::fromUtf8(units[unit]));
}

QString formatBytes(const SystemInfoProvider::RuntimeValues& values, qint64 bytes)
{
    if (values.byteFormatter) {
        return values.byteFormatter(bytes);
    }
    return formatBytesFallback(bytes);
}

QString cpuModelName()
{
#if defined(Q_OS_WIN)
    const QString processorIdentifier = qEnvironmentVariable("PROCESSOR_IDENTIFIER").trimmed();
    if (!processorIdentifier.isEmpty()) {
        return processorIdentifier;
    }
#endif

#if defined(Q_OS_MACOS)
    char buffer[256] = {};
    size_t size = sizeof(buffer);
    if (sysctlbyname("machdep.cpu.brand_string", buffer, &size, nullptr, 0) == 0 && size > 1) {
        return QString::fromUtf8(buffer, static_cast<int>(qMin<size_t>(size - 1, sizeof(buffer) - 1))).trimmed();
    }
#endif

#if defined(Q_OS_LINUX) || defined(Q_OS_ANDROID)
    QFile cpuInfo(QString::fromUtf8("/proc/cpuinfo"));
    if (cpuInfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        while (!cpuInfo.atEnd()) {
            const QString line = QString::fromUtf8(cpuInfo.readLine()).trimmed();
            const int separator = line.indexOf(QLatin1Char(':'));
            if (separator < 0) {
                continue;
            }

            const QString key = line.left(separator).trimmed().toLower();
            const QString value = line.mid(separator + 1).trimmed();
            if ((key == QString::fromUtf8("model name"))
                || (key == QString::fromUtf8("hardware"))
                || (key == QString::fromUtf8("processor"))) {
                if (!value.isEmpty()) {
                    return value;
                }
            }
        }
    }
#endif

    QString fallback = QSysInfo::currentCpuArchitecture().trimmed();
    if (fallback.isEmpty()) {
        fallback = QSysInfo::buildCpuArchitecture().trimmed();
    }
    return fallback.isEmpty() ? QString::fromUtf8("Unknown") : fallback;
}

QString deviceModelName()
{
    const QString hostName = QSysInfo::machineHostName().trimmed();
    return hostName.isEmpty() ? QString::fromUtf8("Unknown") : hostName;
}

quint64 systemMemoryBytes()
{
#if defined(Q_OS_WIN)
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    if (GlobalMemoryStatusEx(&status)) {
        return static_cast<quint64>(status.ullTotalPhys);
    }
#endif

#if defined(Q_OS_LINUX) || defined(Q_OS_ANDROID) || defined(Q_OS_MACOS)
    const long pages = sysconf(_SC_PHYS_PAGES);
    const long pageSize = sysconf(_SC_PAGE_SIZE);
    if (pages > 0 && pageSize > 0) {
        return static_cast<quint64>(pages) * static_cast<quint64>(pageSize);
    }
#endif

    return 0;
}

QString displaySummary()
{
    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen) {
        return QString();
    }

    const QSize size = screen->geometry().size();
    const qreal ratio = screen->devicePixelRatio();
    const QString ratioText = qFuzzyCompare(ratio, qRound64(ratio))
        ? QString::number(qRound64(ratio))
        : QString::number(ratio, 'f', 2);

    return QString::fromUtf8("%1 x %2 @ %3x")
        .arg(size.width())
        .arg(size.height())
        .arg(ratioText);
}

QString osDisplayName()
{
    const QString pretty = QSysInfo::prettyProductName().trimmed();
    if (!pretty.isEmpty()) {
        return pretty;
    }

    const QString productType = QSysInfo::productType().trimmed();
    const QString productVersion = QSysInfo::productVersion().trimmed();
    if (productType.isEmpty() && productVersion.isEmpty()) {
        return QString::fromUtf8("Unknown");
    }
    if (productType.isEmpty()) {
        return productVersion;
    }
    if (productVersion.isEmpty()) {
        return productType;
    }
    return QString::fromUtf8("%1 %2").arg(productType, productVersion);
}

QString kernelDisplayName()
{
    const QString kernelType = QSysInfo::kernelType().trimmed();
    const QString kernelVersion = QSysInfo::kernelVersion().trimmed();
    if (kernelType.isEmpty() && kernelVersion.isEmpty()) {
        return QString();
    }
    if (kernelType.isEmpty()) {
        return kernelVersion;
    }
    if (kernelVersion.isEmpty()) {
        return kernelType;
    }
    return QString::fromUtf8("%1 %2").arg(kernelType, kernelVersion);
}

QString qtRuntimeText()
{
    return QString::fromUtf8("Qt %1").arg(QString::fromUtf8(qVersion()));
}

QString languageStandardText()
{
#ifdef GENYCONNECT_CXX_STANDARD
    return QString::fromUtf8("C++%1").arg(GENYCONNECT_CXX_STANDARD);
#elif __cplusplus >= 202302L
    return QString::fromUtf8("C++23");
#elif __cplusplus >= 202002L
    return QString::fromUtf8("C++20");
#elif __cplusplus >= 201703L
    return QString::fromUtf8("C++17");
#else
    return QString::fromUtf8("Unknown");
#endif
}

QString runtimePlatformText()
{
#if defined(Q_OS_ANDROID)
    return QString::fromUtf8("Android");
#elif defined(Q_OS_IOS)
    return QString::fromUtf8("iOS");
#elif defined(Q_OS_MACOS)
    return QString::fromUtf8("macOS");
#elif defined(Q_OS_WIN)
    return QString::fromUtf8("Windows");
#elif defined(Q_OS_LINUX)
    return QString::fromUtf8("Linux");
#else
    return QString::fromUtf8("Unknown");
#endif
}

QString androidSdkApiText()
{
#if defined(Q_OS_ANDROID)
    const int sdkVersion = QNativeInterface::QAndroidApplication::sdkVersion();
    return QString::fromUtf8("Android SDK/API %1").arg(sdkVersion);
#else
    return QString();
#endif
}

void appendReportLine(QStringList& lines, const QString& label, const QString& value)
{
    const QString trimmed = value.trimmed();
    if (!trimmed.isEmpty()) {
        lines.append(QString::fromUtf8("%1: %2").arg(label, trimmed));
    }
}

} // namespace

QVariantMap SystemInfoProvider::systemInfo(const RuntimeValues& values)
{
    QVariantMap info;
    info.insert(QString::fromUtf8("software"), softwareInfo(values));
    info.insert(QString::fromUtf8("hardware"), hardwareInfo(values));
    return info;
}

QVariantMap SystemInfoProvider::softwareInfo(const RuntimeValues& values)
{
    const QString qtVersionText = qtRuntimeText();
    const QString kernelText = kernelDisplayName();
    const QString xrayVersionText = values.xrayVersion.trimmed().isEmpty()
        ? QString::fromUtf8("Unknown")
        : values.xrayVersion.trimmed();

    QVariantMap software;
    software.insert(QString::fromUtf8("appVersion"), QCoreApplication::applicationVersion().trimmed());
    software.insert(QString::fromUtf8("xrayVersion"), xrayVersionText);
    software.insert(QString::fromUtf8("qtVersion"), qtVersionText.isEmpty() ? QString::fromUtf8("Unknown") : qtVersionText);
    software.insert(QString::fromUtf8("languageStandard"), languageStandardText());
    software.insert(QString::fromUtf8("platform"), runtimePlatformText());
    software.insert(QString::fromUtf8("platformMode"), values.mobile ? QString::fromUtf8("Mobile") : QString::fromUtf8("Desktop"));
    software.insert(QString::fromUtf8("osName"), osDisplayName());
    software.insert(QString::fromUtf8("osKernel"), kernelText.isEmpty() ? QString::fromUtf8("Unknown") : kernelText);
#if defined(Q_OS_ANDROID)
    software.insert(QString::fromUtf8("sdkText"), androidSdkApiText());
    software.insert(QString::fromUtf8("apiText"), QString::fromUtf8("API %1").arg(QNativeInterface::QAndroidApplication::sdkVersion()));
#else
    software.insert(QString::fromUtf8("sdkText"), qtVersionText.isEmpty() ? QString::fromUtf8("Unknown") : qtVersionText);
    software.insert(QString::fromUtf8("apiText"), kernelText.isEmpty() ? QString::fromUtf8("Unknown") : kernelText);
#endif
    return software;
}

QVariantMap SystemInfoProvider::hardwareInfo(const RuntimeValues& values)
{
    const quint64 totalMemory = systemMemoryBytes();
    const QString totalMemoryText = totalMemory > 0
        ? formatBytes(values, static_cast<qint64>(totalMemory))
        : QString::fromUtf8("Unknown");
    const QString architectureText = QSysInfo::currentCpuArchitecture().trimmed().isEmpty()
        ? QSysInfo::buildCpuArchitecture().trimmed()
        : QSysInfo::currentCpuArchitecture().trimmed();

    QVariantMap hardware;
    hardware.insert(QString::fromUtf8("cpuName"), cpuModelName());
    hardware.insert(QString::fromUtf8("cpuArchitecture"), architectureText.isEmpty() ? QString::fromUtf8("Unknown") : architectureText);
    hardware.insert(QString::fromUtf8("memoryText"), totalMemoryText);
    const QString processMemoryText = values.processMemoryText.trimmed();
    hardware.insert(QString::fromUtf8("processMemoryText"), processMemoryText.isEmpty() ? QString::fromUtf8("Unknown") : processMemoryText);
    hardware.insert(QString::fromUtf8("deviceName"), deviceModelName());
    const QString displayText = displaySummary().trimmed();
    hardware.insert(QString::fromUtf8("displayText"), displayText.isEmpty() ? QString::fromUtf8("Unknown") : displayText);
    return hardware;
}

QString SystemInfoProvider::value(const QVariantMap& values, const QString& key)
{
    const QString trimmed = values.value(key).toString().trimmed();
    return trimmed.isEmpty() ? QString::fromUtf8("Unavailable") : trimmed;
}

QString SystemInfoProvider::diagnosticText(const RuntimeValues& values)
{
    const QVariantMap info = systemInfo(values);
    const QVariantMap software = info.value(QString::fromUtf8("software")).toMap();
    const QVariantMap hardware = info.value(QString::fromUtf8("hardware")).toMap();

    QStringList lines;
    lines.append(QString::fromUtf8("GenyConnect Diagnostic Report"));
    lines.append(QString());
    lines.append(QString::fromUtf8("Software"));
    appendReportLine(lines, QString::fromUtf8("App Version"), software.value(QString::fromUtf8("appVersion")).toString());
    appendReportLine(lines, QString::fromUtf8("xray-core"), software.value(QString::fromUtf8("xrayVersion")).toString());
    appendReportLine(lines, QString::fromUtf8("Qt Runtime"), software.value(QString::fromUtf8("qtVersion")).toString());
    appendReportLine(lines, QString::fromUtf8("Language Standard"), software.value(QString::fromUtf8("languageStandard")).toString());
    appendReportLine(lines, QString::fromUtf8("Runtime"), software.value(QString::fromUtf8("platformMode")).toString());
    appendReportLine(lines, QString::fromUtf8("Platform"), software.value(QString::fromUtf8("platform")).toString());
    appendReportLine(lines, QString::fromUtf8("OS"), software.value(QString::fromUtf8("osName")).toString());
    appendReportLine(lines, QString::fromUtf8("Kernel / API"), software.value(QString::fromUtf8("apiText")).toString());
    appendReportLine(lines, QString::fromUtf8("SDK"), software.value(QString::fromUtf8("sdkText")).toString());
    lines.append(QString());
    lines.append(QString::fromUtf8("Hardware"));
    appendReportLine(lines, QString::fromUtf8("CPU"), hardware.value(QString::fromUtf8("cpuName")).toString());
    appendReportLine(lines, QString::fromUtf8("Architecture"), hardware.value(QString::fromUtf8("cpuArchitecture")).toString());
    appendReportLine(lines, QString::fromUtf8("Memory"), QString::fromUtf8("%1 total").arg(hardware.value(QString::fromUtf8("memoryText")).toString()));
    appendReportLine(lines, QString::fromUtf8("Process Memory"), hardware.value(QString::fromUtf8("processMemoryText")).toString());
    appendReportLine(lines, QString::fromUtf8("Device"), hardware.value(QString::fromUtf8("deviceName")).toString());
    appendReportLine(lines, QString::fromUtf8("Display"), hardware.value(QString::fromUtf8("displayText")).toString());

    return lines.join('\n');
}

// Copyright (C) 2026 Genyleap Labs.
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QString>
#include <QStringList>

namespace LinuxHelperLaunch {

inline QStringList pkexecArguments(const QString& helperPath,
                                   const QStringList& helperArguments,
                                   const QString& ldLibraryPath,
                                   const QString& envExecutable)
{
    QStringList arguments;
    if (!ldLibraryPath.trimmed().isEmpty() && !envExecutable.trimmed().isEmpty()) {
        arguments << envExecutable;
        arguments << QString::fromUtf8("LD_LIBRARY_PATH=%1").arg(ldLibraryPath);
    }
    arguments << helperPath;
    arguments << helperArguments;
    return arguments;
}

} // namespace LinuxHelperLaunch

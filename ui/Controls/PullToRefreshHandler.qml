// Copyright (C) 2022 The Genyleap.
// Copyright (C) 2022 Kambiz Asadzadeh
// SPDX-License-Identifier: LGPL-3.0-only

import QtQuick

Item
{
    id: pulltorefreshhandler

    property var flickable: parent
    property int threshold: 20
    readonly property alias is_pulldown: pullObject.m_is_pulldown
    readonly property alias is_pullup: pullObject.m_is_pullup

    QtObject
    {
        id: pullObject
        property real m_content_end: (flickable.contentHeight > flickable.height) ?
                                         ((flickable.contentHeight + flickable.originY) - flickable.height) : flickable.originY;
        property int m_threshold: (threshold * flickable.height) / 100
        property real y_flag: 0
        property bool m_is_pulldown: false
        property bool m_is_pullup: false
    }

    signal pulldown()
    signal pullup()
    signal pulldownrelease()
    signal pulluprelease()

    Connections
    {
        target: flickable

        function onAtYBeginningChanged()
        {
            if(flickable.atYBeginning)
                pullObject.y_flag = flickable.contentY;
        }

        function onAtYEndChanged()
        {
            if (flickable.atYEnd)
                pullObject.y_flag = flickable.contentY;
        }

        function  onContentYChanged()
        {
            var changed_y_distance = Math.abs(pullObject.y_flag - flickable.contentY);

            if(flickable.atYBeginning)
            {
                if(changed_y_distance > pullObject.m_threshold)
                {
                    pullObject.m_is_pulldown = true;
                    pulltorefreshhandler.pulldown();
                }

                if (pullObject.m_is_pulldown && (flickable.contentY === flickable.originY))
                {
                    pullObject.m_is_pulldown = false;
                    pulltorefreshhandler.pulldownrelease();
                }
            }

            if(flickable.atYEnd)
            {
                if(changed_y_distance > pullObject.m_threshold)
                {
                    pullObject.m_is_pullup = true;
                    pulltorefreshhandler.pullup();
                }

                if (pullObject.m_is_pullup && (flickable.contentY === pullObject.m_content_end))
                {
                    pullObject.m_is_pullup = false;
                    pulltorefreshhandler.pulluprelease();
                }
            }
        }
    }

}

/*
 * Fedora Media Writer
 * Copyright (C) 2016 Martin Bříza <mbriza@redhat.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Window 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1

import "components"

ApplicationWindow {
    id: mainWindow
    visible: true
    minimumWidth: $(800)
    minimumHeight: $(480)
    title: "Fedora Media Writer"

    SystemPalette {
        id: palette
    }
    SystemPalette {
        id: disabledPalette
        colorGroup: SystemPalette.Disabled
    }

    Component.onCompleted: {
        width = $(800)
        height = $(480)
    }

    property real scalingFactor: Math.ceil(Screen.pixelDensity * 25.4) / 96 > 1 ? Math.ceil(Screen.pixelDensity * 25.4) / 96 : 1
    function $(x) {
        return x
    }

    function mixColors(color1, color2, ratio) {
        return Qt.rgba(color1.r * ratio + color2.r * (1.0 - ratio),
                       color1.g * ratio + color2.g * (1.0 - ratio),
                       color1.b * ratio + color2.b * (1.0 - ratio),
                       color1.a * ratio + color2.a * (1.0 - ratio))
    }

    property bool canGoBack: false
    property real margin: $(64) + (width - $(800)) / 4
    property real potentialMargin: $(64) + (Screen.width - $(800)) / 4

    AdwaitaNotificationBar {
        id: deviceNotification
        text: open ? qsTr("You inserted <b>%1</b> that already contains a live system.<br>Do you want to restore it to factory settings?").arg(drives.lastRestoreable.name) : ""
        open: drives.lastRestoreable
        acceptText: qsTr("Restore")
        cancelText: qsTr("Do Nothing")
        property var disk: null
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        onAccepted: restoreDialog.visible = true

        Connections {
            target: drives
            onLastRestoreableChanged: {
                if (drives.lastRestoreable != null && !dlDialog.visible)
                    deviceNotification.open = true
                if (!drives.lastRestoreable)
                    deviceNotification.open = false
            }
        }
    }

    Rectangle {
        anchors {
            top: deviceNotification.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        color: palette.window
        //radius: 8
        clip: true

        ListView {
            id: contentList
            anchors{
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            model: ["components/ImageList.qml", "components/ImageDetails.qml"]
            orientation: ListView.Horizontal
            snapMode: ListView.SnapToItem
            highlightFollowsCurrentItem: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            interactive: false
            highlightMoveVelocity: 3 * contentList.width
            highlightResizeDuration: 0
            cacheBuffer: 2*width
            delegate: Item {
                id: contentComponent
                width: contentList.width
                height: contentList.height
                Loader {
                    id: contentLoader
                    source: contentList.model[index]
                    anchors.fill: parent
                }
                Connections {
                    target: contentLoader.item
                    onStepForward: {
                        contentList.currentIndex++
                        canGoBack = true
                        releases.selectedIndex = index
                    }
                }
            }
        }
    }

    AdwaitaPopup {
        id: newVersionPopup
        open: versionChecker.newerVersion
        title: qsTr("Fedora Media Writer %1 Released").arg(versionChecker.newerVersion)
        text: qsTr("Update for great new features and bugfixes!")
        buttonText: qsTr("Open Browser")
        onAccepted: Qt.openUrlExternally(versionChecker.url)
    }

    RestoreDialog {
        id: restoreDialog
    }

    DownloadDialog {
        id: dlDialog
    }

    FileDialog {
        id: fileDialog
        folder: shortcuts.home
        nameFilters: [ qsTr("Image files") + " (*.iso *.raw *.xz)", qsTr("All files (*)")]
        onAccepted: {
            releases.setLocalFile(fileUrl)
            dlDialog.visible = true
        }
    }

    FullscreenViewer {
        id: fullscreenViewer
    }

    Rectangle {
        id: fatalErrorOverlay
        opacity: drives.isBroken ? 1.0 : 0.0
        visible: opacity > 0.1
        Behavior on opacity { NumberAnimation { } }
        anchors.fill: parent
        color: "#cc000000"
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 9
            Text {
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                text: qsTr("%1<br>Writing images will not be possible.<br>You can still view Fedora flavors and download images to your hard drive.").arg(drives.errorString)
            }
            AdwaitaButton {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Ok")
                onClicked: fatalErrorOverlay.opacity = 0.0
            }
        }
    }
}

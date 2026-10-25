import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "file:/home/aiden/nixos-dotfiles/packages/rocky-day/quickshell" as Rocky

PanelWindow {
    id: root

    anchors.top: true
	anchors.left: true
	anchors.right: true
    margins.top: 3
    implicitWidth: capsule.width
    implicitHeight: capsule.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    property date now: new Date()

	Rocky.RockyWallpaper {}

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Item {
        id: capsule
        anchors.centerIn: parent
        width: clockCapsule.x + clockCapsule.width
        height: 34

        property real extensionWidth: 48
        property real overlap: 10
        property int workspaceNumber: Hyprland.focusedWorkspace?.id === 10
            ? 0
            : (Hyprland.focusedWorkspace?.id ?? -1)
        property color workspaceColor: {
            const colors = ["#94dff7", "#f7b5c7", "#f7a967", "#cabbed"];

            if (workspaceNumber === 9)
                return "#87d6ad";
            if (workspaceNumber === 0)
                return "#87d6ad";
            if (workspaceNumber >= 1 && workspaceNumber <= 8)
                return colors[(workspaceNumber - 1) % colors.length];
            return "#cabbed";
        }

        Rectangle {
            id: clockCapsule
            x: capsule.extensionWidth - capsule.overlap
            width: clockRow.implicitWidth + 24
            height: parent.height
            radius: height / 1.7
            color: "#14191f"

            RowLayout {
                id: clockRow
                anchors.centerIn: parent
                spacing: 17

				Text {
					text: capsule.workspaceNumber
					color: capsule.workspaceColor
					font.family: "MonacoLigaturized Nerd Font"
					font.weight: 700
                    font.pixelSize: 17
				}

                Text {
                    text: Qt.formatDateTime(root.now, "HH:mm")
                    color: "#eeeeee"
                    font.family: "MonacoLigaturized Nerd Font"
                    font.pixelSize: 17
                }

                Text {
                    text: Qt.formatDateTime(root.now, "ddd, MMM d")
                    color: "#cccccc"
                    font.family: "MonacoLigaturized Nerd Font"
                    font.pixelSize: 14
                }
            }
        }
    }
}

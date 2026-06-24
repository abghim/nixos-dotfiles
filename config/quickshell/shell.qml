import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
	id: root
	exclusionMode: ExclusionMode.Reserve

    // Theme
    property color b1: "#14191f"
    property color b2: "#1C2228"
    property color b3: "#20232B"
    property color b4: "#666666"

    property color s1: "#285A6B"
    property color s2: "#3E7C8F"
    property color s3: "#5C9FB2"
    property color s4: "#7BBBD0"

    property color c1: "#A04C62"
    property color c2: "#B6677C"
    property color c3: "#CF8899"
    property color c4: "#E3A6B7"

    property color h1: "#C45A26"
    property color h2: "#D87237"
    property color h3: "#E88C4C"
    property color h4: "#F7A967"

    property color m1: "#467159"
    property color m2: "#54846B"

    property color l1: "#9F7EB5"
    property color l2: "#B2A5D0"

    property color capsuleBg: "#14191f"
    property color capsuleBorder: "#33262A30"
    property string fontFamily: "Monaco Nerd Font"
    property int fontSize: 14
    property var activeToplevel: Hyprland.activeToplevel
    property string focusedAppName: {
        const appId = activeToplevel?.appId || "";
        const title = activeToplevel?.title || "";
        const source = appId || title || "Desktop";
        return source
            .replace(/^[a-z]/, c => c.toUpperCase())
            .replace(/[-_.]+/g, " ");
    }
    property real barHorizontalMargin: 4
    property real barCapsuleSpacing: 8

    // System data
    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property bool mediaPlaying: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaPlayer: ""
    property real mediaVolume: 0.5
    property real pendingVolume: 0.5
    property real audioPhase: 0
    property string mediaDisplayText: {
        if (mediaArtist && mediaTitle)
            return mediaArtist + " - " + mediaTitle;
        return mediaTitle || mediaPlayer;
    }

    function updateCpuSample(sample) {
        const parts = sample.trim().split(/\s+/);
        if (parts.length < 5 || parts[0] !== "cpu")
            return;

        let total = 0;
        for (let i = 1; i < parts.length; i++)
            total += Number(parts[i]);

        const idle = Number(parts[4]) + (parts.length > 5 ? Number(parts[5]) : 0);

        if (root.lastCpuTotal > 0) {
            const totalDiff = total - root.lastCpuTotal;
            const idleDiff = idle - root.lastCpuIdle;

            if (totalDiff > 0)
                root.cpuUsage = Math.max(0, Math.min(100, Math.round((1 - idleDiff / totalDiff) * 100)));
        }

        root.lastCpuIdle = idle;
        root.lastCpuTotal = total;
    }

    function updateMemSample(sample) {
        const totalMatch = sample.match(/MemTotal:\s+(\d+)/);
        const availableMatch = sample.match(/MemAvailable:\s+(\d+)/);

        if (!totalMatch || !availableMatch)
            return;

        const total = Number(totalMatch[1]);
        const available = Number(availableMatch[1]);

        if (total > 0)
            root.memUsage = Math.max(0, Math.min(100, Math.round(((total - available) / total) * 100)));
    }

    function gaugeDisplayValue(value) {
        if (value <= 0)
            return 0;

        return Math.max(4, Math.min(100, value));
    }

    function updateMediaSample(sample) {
        const lines = sample.split("\n");
        const status = (lines[0] || "").trim();
        const volumeLine = (lines[1] || "").trim();
        const playerLine = (lines[2] || "").trim();
        const artistLine = (lines[3] || "").trim();
        const titleLine = (lines[4] || "").trim();

        root.mediaPlaying = status === "Playing";
        root.mediaPlayer = playerLine;
        root.mediaArtist = artistLine;
        root.mediaTitle = titleLine;

        const parsedVolume = Number(volumeLine);
        if (!Number.isNaN(parsedVolume))
            root.mediaVolume = Math.max(0, Math.min(1, parsedVolume));
    }

    function setPlayerVolume(value) {
        root.pendingVolume = Math.max(0, Math.min(1, value));
        root.mediaVolume = root.pendingVolume;
        volumeCommitTimer.restart();
    }

    function visualBarHeight(index) {
        if (!root.mediaPlaying)
            return 3;

        const primary = Math.abs(Math.sin(root.audioPhase + index * 0.58));
        const secondary = Math.abs(Math.sin(root.audioPhase * 0.72 + index * 0.31 + 1.2));
        const tertiary = Math.abs(Math.sin(root.audioPhase * 1.18 + index * 0.12 + 0.4));
        return 2 + Math.round((primary * 0.52 + secondary * 0.3 + tertiary * 0.18) * 14);
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]

        stdout: StdioCollector {
            onStreamFinished: root.updateCpuSample(this.text)
        }
    }

    Process {
        id: memProc
        command: ["sh", "-c", "cat /proc/meminfo"]

        stdout: StdioCollector {
            onStreamFinished: root.updateMemSample(this.text)
        }
    }

    Process {
        id: mediaProc
        command: ["sh", "-c", "status=$(playerctl status 2>/dev/null || true); volume=$(playerctl volume 2>/dev/null || true); player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | head -n1); artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null | head -n1); title=$(playerctl metadata --format '{{title}}' 2>/dev/null | head -n1); printf '%s\\n%s\\n%s\\n%s\\n%s\\n' \"$status\" \"$volume\" \"$player\" \"$artist\" \"$title\""]

        stdout: StdioCollector {
            onStreamFinished: root.updateMediaSample(this.text)
        }
    }

    Process {
        id: volumeProc
        command: ["playerctl", "volume", root.pendingVolume.toFixed(2)]
    }

    Timer {
        id: volumeCommitTimer
        interval: 80
        repeat: false
        onTriggered: volumeProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            memProc.running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: mediaProc.running = true
    }

    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: {
            if (root.mediaPlaying)
                root.audioPhase += 0.38;
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 46
    color: "transparent"

    Item {
        id: barFrame
        anchors.fill: parent
        anchors.margins: root.barHorizontalMargin
        anchors.topMargin: 0
        anchors.bottomMargin: 0

        Rectangle {
            id: workspaceCapsule
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            radius: 15
            color: root.capsuleBg
            border.color: root.b3
            border.width: 1

            implicitWidth: workspaceRow.implicitWidth + 24
            width: implicitWidth

            RowLayout {
                id: workspaceRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Repeater {
                    model: 9
                    delegate: Rectangle {
                        required property int index
                        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

                        color: isActive ? root.h4 : (ws ? root.l2 : root.b4)
                        Layout.preferredWidth: isActive ? 20 : 10
                        Layout.preferredHeight: 10
                        radius: 5

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                        }
                    }
                }
            }
        }

        Item {
            id: centerGroup
            anchors.centerIn: parent
            height: 30
            width: totalWidth
            property bool hovered: centerHover.containsMouse
            property real leftLimit: workspaceCapsule.x + workspaceCapsule.width + root.barCapsuleSpacing
            property real rightLimit: infoCapsule.x - root.barCapsuleSpacing
            property real availableWidth: Math.max(
                180,
                Math.min(
                    barFrame.width,
                    (Math.min(
                        barFrame.width / 2 - leftLimit,
                        rightLimit - barFrame.width / 2
                    ) * 2)
                )
            )
            property real animatedGap: root.mediaPlaying ? 10 : 0
            property real mediaWidth: root.mediaPlaying
                ? Math.min(Math.max(110, mediaText.implicitWidth + 28), availableWidth * 0.42)
                : 0
            property real appBaseWidth: Math.max(180, availableWidth / 3)
            property real appWidth: Math.max(
                140,
                Math.min(
                    availableWidth - mediaWidth - animatedGap,
                    Math.max(appBaseWidth, appText.implicitWidth + 28)
                )
            )
            property real totalWidth: appWidth + mediaWidth + animatedGap

            Behavior on width {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on animatedGap {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.InOutCubic
                }
            }

            Rectangle {
                id: appSurface
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                width: centerGroup.appWidth
                radius: 15
                clip: true
                color: "#14ffffff"
                border.color: "#52ffffff"
                border.width: 1

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#55ffffff" }
                        GradientStop { position: 0.22; color: "#24ffffff" }
                        GradientStop { position: 1.0; color: "#12ffffff" }
                    }
                    opacity: 0.32
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 2
                    }
                    height: parent.height * 0.48
                    radius: parent.radius - 2
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#6effffff" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }
                    opacity: 0.5
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "#12000000"
                    border.color: "#16ffffff"
                    border.width: 1
                }

                Text {
                    id: appText
                    anchors.centerIn: parent
                    width: parent.width - 28
                    text: root.focusedAppName
                    color: "#ffffff"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    style: Text.Outline
                    styleColor: "#22000000"
                }
            }

            Rectangle {
                id: mediaSurface
                anchors.left: appSurface.right
                anchors.leftMargin: centerGroup.animatedGap
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                width: centerGroup.mediaWidth
                radius: 15
                clip: true
                color: "#14ffffff"
                border.color: "#52ffffff"
                border.width: 1
                opacity: root.mediaPlaying ? 1 : 0
                scale: root.mediaPlaying ? 1 : 0.92
                visible: opacity > 0

                Behavior on width {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.InOutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#55ffffff" }
                        GradientStop { position: 0.22; color: "#24ffffff" }
                        GradientStop { position: 1.0; color: "#12ffffff" }
                    }
                    opacity: 0.32
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 2
                    }
                    height: parent.height * 0.48
                    radius: parent.radius - 2
                    color: "transparent"
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#6effffff" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }
                    opacity: 0.5
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: "#12000000"
                    border.color: "#16ffffff"
                    border.width: 1
                }

                Text {
                    id: mediaText
                    anchors.centerIn: parent
                    width: parent.width - 28
                    text: root.mediaDisplayText
                    color: "#ffffff"
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    style: Text.Outline
                    styleColor: "#22000000"
                }
            }

            MouseArea {
                id: centerHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }

        Rectangle {
            id: infoCapsule
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 30
            radius: 15
            color: root.capsuleBg
            border.color: root.b3
            border.width: 1

            implicitWidth: infoRow.implicitWidth + 24
            width: implicitWidth
            property bool statsHovered: statsHover.containsMouse
            property bool statsLatched: false
            property bool statsExpanded: statsHovered || statsLatched

            onStatsHoveredChanged: {
                if (statsHovered) {
                    statsLatched = true;
                    statsLinger.stop();
                } else {
                    statsLinger.restart();
                }
            }

            Timer {
                id: statsLinger
                interval: 900
                repeat: false
                onTriggered: infoCapsule.statsLatched = false
            }

            RowLayout {
                id: infoRow
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 13

                Item {
                    id: volumeReveal
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 16
                    property bool hovered: volumeArea.containsMouse || volumeArea.pressed || volumeLatched
                    property bool volumeLatched: false
                    property real targetWidth: hovered ? 108 : 18
                    property real trackWidth: Math.max(0, width - volumeButton.width - 8)
                    implicitWidth: targetWidth
                    width: targetWidth
                    clip: true

                    onHoveredChanged: {
                        if (volumeArea.containsMouse || volumeArea.pressed) {
                            volumeLatched = true;
                            volumeCollapse.stop();
                        } else {
                            volumeCollapse.restart();
                        }
                    }

                    Timer {
                        id: volumeCollapse
                        interval: 500
                        repeat: false
                        onTriggered: volumeReveal.volumeLatched = false
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Rectangle {
                        id: volumeTrack
                        anchors.left: parent.left
                        width: volumeReveal.trackWidth
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: "#22444444"
                        opacity: volumeReveal.hovered ? 1 : 0
                        visible: width > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.InOutCubic
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(6, parent.width * root.mediaVolume)
                            height: parent.height
                            radius: parent.radius
                            color: "#d8ffffff"
                        }

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            x: Math.max(0, Math.min(parent.width - width, parent.width * root.mediaVolume - width / 2))
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#ffffff"
                            border.color: "#66ffffff"
                            border.width: 1
                        }

                    }

                    Canvas {
                        id: volumeButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 16
                        opacity: root.mediaPlaying ? 1 : 0.72

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = "#ffffff";
                            ctx.beginPath();
                            ctx.moveTo(2, 6);
                            ctx.lineTo(5, 6);
                            ctx.lineTo(9, 2);
                            ctx.lineTo(9, 14);
                            ctx.lineTo(5, 10);
                            ctx.lineTo(2, 10);
                            ctx.closePath();
                            ctx.fill();

                            const level = root.mediaVolume;
                            ctx.strokeStyle = "#ffffff";
                            ctx.lineWidth = 1.4;

                            if (level > 0.01) {
                                ctx.beginPath();
                                ctx.arc(9.5, 8, 3.5, -0.8, 0.8);
                                ctx.stroke();
                            }
                            if (level > 0.45) {
                                ctx.beginPath();
                                ctx.arc(9.5, 8, 6, -0.8, 0.8);
                                ctx.stroke();
                            }
                        }
                    }

                    MouseArea {
                        id: volumeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        onPressed: function(mouse) {
                            if (volumeReveal.trackWidth > 0 && mouse.x <= volumeReveal.trackWidth)
                                root.setPlayerVolume(mouse.x / volumeReveal.trackWidth);
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed && volumeReveal.trackWidth > 0)
                                root.setPlayerVolume(mouse.x / volumeReveal.trackWidth);
                        }
                    }

                    Connections {
                        target: root
                        function onMediaVolumeChanged() {
                            volumeButton.requestPaint();
                        }
                    }
                }

                Item {
                    id: statsReveal
                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight: 16
                    property real targetWidth: infoCapsule.statsExpanded ? 104 : 42
                    property real revealProgress: infoCapsule.statsExpanded ? 1 : 0
                    implicitWidth: targetWidth
                    width: targetWidth
                    clip: true

                    Behavior on width {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Behavior on revealProgress {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Item {
                        id: gaugeStrip
                        anchors.right: parent.right
                        width: 104
                        height: parent.height

                        Item {
                            id: cpuGauge
                            width: 16
                            height: 16
                            property real collapsedX: 62
                            property real expandedX: cpuValue.x - width - 6
                            x: collapsedX + ((expandedX - collapsedX) * statsReveal.revealProgress)
                            y: 0

                            Canvas {
                                id: cpuCanvas
                                anchors.fill: parent
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();

                                    const size = Math.min(width, height);
                                    const center = size / 2;
                                    const radius = center - 2;
                                    const lineWidth = 3;
                                    const start = -Math.PI / 2;
                                    const end = start + (Math.PI * 2 * root.gaugeDisplayValue(root.cpuUsage) / 100);

                                    ctx.lineCap = "round";
                                    ctx.lineWidth = lineWidth;

                                    ctx.beginPath();
                                    ctx.strokeStyle = "#444444";
                                    ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                                    ctx.stroke();

                                    if (root.cpuUsage > 0) {
                                        ctx.beginPath();
                                        ctx.strokeStyle = root.c4;
                                        ctx.arc(center, center, radius, start, end, false);
                                        ctx.stroke();
                                    }
                                }
                            }
                        }

                        Item {
                            id: memGauge
                            width: 16
                            height: 16
                            property real collapsedX: 88
                            property real expandedX: memValue.x - width - 6
                            x: collapsedX + ((expandedX - collapsedX) * statsReveal.revealProgress)
                            y: 0

                            Canvas {
                                id: memCanvas
                                anchors.fill: parent
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();

                                    const size = Math.min(width, height);
                                    const center = size / 2;
                                    const radius = center - 2;
                                    const lineWidth = 3;
                                    const start = -Math.PI / 2;
                                    const end = start + (Math.PI * 2 * root.gaugeDisplayValue(root.memUsage) / 100);

                                    ctx.lineCap = "round";
                                    ctx.lineWidth = lineWidth;

                                    ctx.beginPath();
                                    ctx.strokeStyle = "#444444";
                                    ctx.arc(center, center, radius, 0, Math.PI * 2, false);
                                    ctx.stroke();

                                    if (root.memUsage > 0) {
                                        ctx.beginPath();
                                        ctx.strokeStyle = root.s4;
                                        ctx.arc(center, center, radius, start, end, false);
                                        ctx.stroke();
                                    }
                                }
                            }
                        }

                        Text {
                            id: cpuValue
                            property real collapsedX: cpuGauge.collapsedX
                            property real expandedX: memGauge.x - implicitWidth - 10
                            x: collapsedX + ((expandedX - collapsedX) * statsReveal.revealProgress)
                            y: 0
                            text: root.cpuUsage + "%"
                            color: root.c4
                            opacity: statsReveal.revealProgress
                            font { family: root.fontFamily; pixelSize: root.fontSize - 1; bold: true }
                        }

                        Text {
                            id: memValue
                            property real collapsedX: memGauge.collapsedX
                            property real expandedX: gaugeStrip.width - implicitWidth
                            x: collapsedX + ((expandedX - collapsedX) * statsReveal.revealProgress)
                            y: 0
                            text: root.memUsage + "%"
                            color: root.s4
                            opacity: statsReveal.revealProgress
                            font { family: root.fontFamily; pixelSize: root.fontSize - 1; bold: true }
                        }
                    }

                    MouseArea {
                        id: statsHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    Connections {
                        target: root
                        function onCpuUsageChanged() {
                            cpuCanvas.requestPaint();
                        }

                        function onMemUsageChanged() {
                            memCanvas.requestPaint();
                        }
                    }
                }

                Text {
                    id: clock
                    color: root.l2
                    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                    text: Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd, MMM dd - HH:mm")
                    }
                }
            }
        }
    }
}

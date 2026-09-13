pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme
import qs.config

Item {
    id: root
    required property var bar
    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true
    property real startRadius: 0
    property real endRadius: 0
    property bool popupOpen: false

    implicitWidth: vertical ? 36 : rowLayout.implicitWidth + 26
    implicitHeight: 36

    // Primary disk (mount pertama dari Config.system.disks)
    readonly property string primaryDiskMount: SystemResources.validDisks.length > 0 ? SystemResources.validDisks[0] : ""
    readonly property real primaryDiskUsage: SystemResources.diskUsage[root.primaryDiskMount] ?? -1
    readonly property bool primaryDiskAvailable: root.primaryDiskUsage >= 0
    readonly property string primaryDiskLevel: root.primaryDiskUsage >= 90 ? "high" : (root.primaryDiskUsage >= 75 ? "warn" : "ok")

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled
        topLeftRadius: root.startRadius
        topRightRadius: root.endRadius
        bottomLeftRadius: root.startRadius
        bottomRightRadius: root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.isHovered ? 0.15 : 0
            radius: parent.radius ?? 0
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: Icons.cheese
                font.family: Icons.font
                font.pixelSize: 18
                color: Styling.srItem("overprimary")
            }

            // Text {
            //     text: Math.round(SystemResources.ramUsage) + "%"
            //     font.family: Config.theme.font
            //     font.pixelSize: Config.theme.fontSize
            //     font.weight: Font.Bold
            //     horizontalAlignment: Text.AlignHCenter
            //     color: Colors.overBackground
            // }

            // RAM
            Text {
                text: {
                    const used = (SystemResources.ramUsed / 1024 / 1024).toFixed(1);
                    const total = (SystemResources.ramTotal / 1024 / 1024).toFixed(0);
                    return used + "/" + total + "G";
                }
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                color: Colors.overBackground
                horizontalAlignment: Text.AlignHCenter
            }

            Separator {
                id: separator
                vert: true
            }

            // CPU
            Text {
                text: Icons.cpu
                font.family: Icons.font
                font.pixelSize: 18
                color: Styling.srItem("overprimary")
            }

            // Separator {
            //     Layout.preferredHeight: 2
            //     Layout.fillWidth: true
            // }

            Text {
                text: `${Math.round(SystemResources.cpuUsage)}%`
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                color: Colors.overBackground
            }

            Separator {
                vert: true
            }

            Text {
                visible: SystemResources.cpuTemp >= 0
                text: Icons.temperature
                font.family: Icons.font
                font.pixelSize: Config.theme.fontSize
                color: Colors.red
            }

            Text {
                visible: SystemResources.cpuTemp >= 0
                text: `${SystemResources.cpuTemp}°`
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                color: Colors.overBackground
            }

            // ── Disk (mount pertama dari Config.system.disks) ──
            // ICON: sesuaikan tipe → Icons.ssd (QML:66), Icons.hdd (QML:67), Icons.disk (QML:65) di modules/theme/Icons.qml
            Separator {
                vert: true
                visible: root.primaryDiskAvailable
            }

            Text {
                visible: root.primaryDiskAvailable
                text: Icons.ssd
                font.family: Icons.font
                font.pixelSize: 18
                color: Styling.srItem("overprimary")
            }

            Text {
                visible: root.primaryDiskAvailable
                text: `${Math.round(root.primaryDiskUsage)}%`
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                color: root.primaryDiskLevel === "high" ? Colors.red : (root.primaryDiskLevel === "warn" ? Colors.yellow : Colors.overBackground)
            }

            // ── Uptime ──
            Separator {
                vert: true
                visible: SystemResources.uptimeSec > 0
            }

            Text {
                visible: root.primaryDiskAvailable
                text: Icons.android
                font.family: Icons.font
                font.pixelSize: 18
                color: Styling.srItem("overprimary")
            }


            Text {
                visible: SystemResources.uptimeSec > 0
                text: root.formatUptime(SystemResources.uptimeSec)
                font.family: Config.theme.font
                font.pixelSize: Config.theme.fontSize
                font.weight: Font.Bold
                color: Colors.overBackground
            }
        }
    }

    StyledToolTip {
        show: root.isHovered
        tooltipText: root.buildTooltip()
    }

    function formatUptime(sec) {
        const d = Math.floor(sec / 86400);
        const h = Math.floor((sec % 86400) / 3600);
        const m = Math.floor((sec % 3600) / 60);
        const parts = [];
        if (d > 0)
            parts.push(d + "d");
        if (h > 0)
            parts.push(h + "h");
        if (parts.length === 0 || m > 0)
            parts.push(m + "m");
        return parts.join(" ");
    }

    function buildTooltip() {
        const lines = [];

        if (SystemResources.cpuModel)
            lines.push("CPU: " + SystemResources.cpuModel);

        for (let i = 0; i < SystemResources.validDisks.length; i++) {
            const mount = SystemResources.validDisks[i];
            const u = SystemResources.diskUsage[mount] ?? -1;
            if (u >= 0) {
                const type = SystemResources.diskTypes[mount] ?? "unknown";
                lines.push("Disk " + mount + ": " + Math.round(u) + "% (" + type + ")");
            }
        }

        if (SystemResources.uptimeSec > 0)
            lines.push("Uptime: " + root.formatUptime(SystemResources.uptimeSec));

        if (SystemResources.loadAvg.length >= 3)
            lines.push("Load: " + SystemResources.loadAvg.map(v => v.toFixed(2)).join(" "));

        return lines.join("\n");
    }
}

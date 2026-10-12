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

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    property bool popupOpen: webcamPopup.isOpen
    readonly property bool live: AndroidWebcam.isActive

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    StyledRect {
        id: buttonBg
        variant: (root.popupOpen || root.live) ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        topLeftRadius: root.vertical ? root.startRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: (root.popupOpen || root.live) ? 0 : (root.isHovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.live ? Icons.webcam : Icons.webcamSlash
            font.family: Icons.font
            font.pixelSize: 18
            color: (root.popupOpen || root.live) ? buttonBg.item : Colors.blue

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: webcamPopup.toggle()
        }

        StyledToolTip {
            visible: root.isHovered && !root.popupOpen
            tooltipText: "Android Webcam: " + AndroidWebcam.stateText
        }
    }

    BarPopup {
        id: webcamPopup
        anchorItem: buttonBg
        bar: root.bar
        popupPadding: 16

        contentWidth: 300
        contentHeight: mainColumn.implicitHeight + webcamPopup.popupPadding * 2

        ColumnLayout {
            id: mainColumn
            anchors.fill: parent
            spacing: 8

            // Status card
            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                variant: "common"
                enableShadow: false
                radius: Styling.radius(0)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: {
                            if (AndroidWebcam.busy)
                                return Colors.outline;
                            if (AndroidWebcam.isActive)
                                return Colors.green;
                            if (AndroidWebcam.needsSetup)
                                return Colors.red;
                            return Colors.outline;
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Android Webcam"
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            color: Colors.overBackground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: AndroidWebcam.videoNode + " · " + AndroidWebcam.cameraFacing + " · " + AndroidWebcam.cameraSize
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.overBackground
                            opacity: 0.8
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: AndroidWebcam.stateText
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(0)
                        font.bold: true
                        color: AndroidWebcam.isActive ? Colors.green : Colors.overBackground
                        opacity: 0.9
                    }
                }
            }

            // Start / Stop
            StyledRect {
                id: toggleButton
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                variant: root.live ? "error" : "primary"
                enableShadow: false
                radius: Styling.radius(0)
                opacity: AndroidWebcam.busy ? 0.6 : 1.0

                Text {
                    anchors.centerIn: parent
                    text: AndroidWebcam.busy ? "Working…" : (root.live ? "Stop Stream" : "Start Stream")
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(0)
                    font.bold: true
                    color: toggleButton.item
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !AndroidWebcam.busy
                    onClicked: AndroidWebcam.toggle()
                }
            }

            // Camera facing selector
            Text {
                text: "Camera"
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overBackground
                font.bold: true
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: AndroidWebcam.availableFacings

                    delegate: StyledRect {
                        id: facingButton
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isSelected: AndroidWebcam.cameraFacing === modelData
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === AndroidWebcam.availableFacings.length - 1
                        property bool buttonHovered: false

                        readonly property real defaultRadius: Styling.radius(0)
                        readonly property real selectedRadius: Styling.radius(0) / 2

                        variant: isSelected ? "primary" : (buttonHovered ? "focus" : "common")
                        enableShadow: false

                        topLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                        bottomLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                        topRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius
                        bottomRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius

                        Text {
                            anchors.centerIn: parent
                            text: facingButton.modelData === "back" ? "Back" : "Front"
                            font.bold: true
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            color: facingButton.item
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: facingButton.buttonHovered = true
                            onExited: facingButton.buttonHovered = false
                            onClicked: AndroidWebcam.setFacing(facingButton.modelData)
                        }
                    }
                }
            }

            // Resolution selector
            Text {
                text: "Resolution"
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overBackground
                font.bold: true
                opacity: 0.7
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: AndroidWebcam.availableSizes

                    delegate: StyledRect {
                        id: sizeButton
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        readonly property bool isSelected: AndroidWebcam.cameraSize === modelData
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === AndroidWebcam.availableSizes.length - 1
                        property bool buttonHovered: false

                        readonly property real defaultRadius: Styling.radius(0)
                        readonly property real selectedRadius: Styling.radius(0) / 2

                        variant: isSelected ? "primary" : (buttonHovered ? "focus" : "common")
                        enableShadow: false

                        topLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                        bottomLeftRadius: isSelected ? (isFirst ? defaultRadius : selectedRadius) : defaultRadius
                        topRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius
                        bottomRightRadius: isSelected ? (isLast ? defaultRadius : selectedRadius) : defaultRadius

                        Text {
                            anchors.centerIn: parent
                            text: sizeButton.modelData === "1920x1080" ? "1080p" : (sizeButton.modelData === "1280x720" ? "720p" : "480p")
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            color: sizeButton.item
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: sizeButton.buttonHovered = true
                            onExited: sizeButton.buttonHovered = false
                            onClicked: AndroidWebcam.setSize(sizeButton.modelData)
                        }

                        StyledToolTip {
                            show: sizeButton.buttonHovered
                            tooltipText: sizeButton.modelData
                        }
                    }
                }
            }

            // Device / module info
            Text {
                Layout.fillWidth: true
                text: "v4l2loopback: " + (AndroidWebcam.hasModule ? "loaded" : "missing") + " · " + "device: " + (AndroidWebcam.hasDevice ? "ready" : "missing") + "\nTorch: always on"
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overBackground
                opacity: 0.7
                wrapMode: Text.WordWrap
            }

            // Error / setup hint
            Text {
                Layout.fillWidth: true
                visible: AndroidWebcam.lastError !== ""
                text: AndroidWebcam.lastError
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.red
                wrapMode: Text.WordWrap
            }
        }
    }
}

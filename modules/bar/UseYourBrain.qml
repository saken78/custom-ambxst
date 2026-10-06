import QtQuick
import QtQuick.Layouts
import qs.modules.components
import qs.modules.theme
import qs.config

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool layerEnabled: true

    property real radius: 0
    property real startRadius: radius
    property real endRadius: radius

    Layout.preferredWidth: vertical ? 36 : buttonBg.implicitWidth
    Layout.preferredHeight: vertical ? buttonBg.implicitHeight : 36

    StyledRect {
        id: buttonBg
        anchors.fill: parent
        variant: "bg"
        enableShadow: root.layerEnabled

        implicitWidth: vertical ? 36 : rowH.implicitWidth + 24
        implicitHeight: vertical ? columnV.implicitHeight + 24 : 36

        topLeftRadius: root.vertical ? root.startRadius : root.startRadius
        topRightRadius: root.vertical ? root.startRadius : root.endRadius
        bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
        bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

        RowLayout {
            id: rowH
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: Icons.brain
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.blue
            }

            Text {
                id: labelH
                textFormat: Text.RichText
                text: "Use Your Brain, It’s Not <font color=\"" + Colors.red + "\">Decorative</font>"
                color: Colors.overBackground
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(0)
                font.bold: true
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            id: columnV
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 4

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.brain
                font.family: Icons.font
                font.pixelSize: 16
                color: Colors.overBackground
            }

            Text {
                id: labelV
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 28
                text: "Use Your Brain, It’s Not Decorative."
                color: Colors.overBackground
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(0)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}

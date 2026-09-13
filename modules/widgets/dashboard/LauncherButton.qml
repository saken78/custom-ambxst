import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config
import qs.modules.components
import qs.modules.theme

ToggleButton {
    // buttonIcon: Config.bar.launcherIcon || Qt.resolvedUrl("../../../assets/ambxst/ambxst-icon.svg").toString().replace("file://", "")
    buttonIcon: Qt.resolvedUrl("../../../assets/ambxst/cat-bold.svg").toString().replace("file://", "")
    iconTint: Config.bar.launcherIconTint
    iconFullTint: Config.bar.launcherIconFullTint
    iconSize: Config.bar.launcherIconSize
    tooltipText: "Open Launcher"

    onToggle: function () {
        if (GlobalStates.launcherOpen) {
            GlobalStates.clearLauncherState();
            Visibilities.setActiveModule("");
        } else {
            GlobalStates.clearLauncherState();
            Visibilities.setActiveModule("launcher");
        }
    }
}

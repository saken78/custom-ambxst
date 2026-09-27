import QtQuick
import qs.modules.globals
import qs.modules.services
import qs.config
import qs.modules.components
import qs.modules.theme

ToggleButton {
    buttonIcon: Icons.magicWand
    tooltipText: "Open Presets Manager"
    active: GlobalStates.presetsOpen

    onToggle: function () {
        if (GlobalStates.presetsOpen) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule("presets");
        }
    }
}
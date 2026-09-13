import QtQuick
import Quickshell.Io
import qs.modules.components
import qs.modules.theme

ToggleButton {
    id: terminalButton
    buttonIcon: Icons.terminalwindow
    tooltipText: "Terminal"

    Process {
        id: terminalProcess
        running: false
    }

    onToggle: function () {
        terminalProcess.command = ["bash", "-c", "setsid kitty > /dev/null 2>&1 &"];
        terminalProcess.running = true;
    }
}

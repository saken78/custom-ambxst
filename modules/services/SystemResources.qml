pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.globals

/**
 * System resource monitoring service
 * Optimized to be lightweight and avoid waking up dGPUs.
 */
Singleton {
    id: root

    // CPU metrics
    property real cpuUsage: 0.0
    property string cpuModel: ""
    property int cpuTemp: -1

    // RAM metrics
    property real ramUsage: 0.0
    property real ramTotal: 0
    property real ramUsed: 0
    property real ramAvailable: 0

    // Disk metrics
    property var diskUsage: ({})
    property var diskTypes: ({})
    property var validDisks: []

    // Uptime & load average
    property real uptimeSec: 0.0
    property var loadAvg: [0.0, 0.0, 0.0]

    // History data
    property var cpuHistory: []
    property var ramHistory: []
    property var cpuTempHistory: []
    property int maxHistoryPoints: 50
    property int totalDataPoints: 0

    // Update interval
    property int updateInterval: 2000

    // Unified monitor process.
    // Resource-efficient: only runs when dashboard is open.
    property Process monitorProcess: Process {
        id: monitorProcess
        running: root.validDisks.length > 0

        command: {
            let cmd = ["python3", Quickshell.shellDir + "/scripts/system_monitor.py", root.updateInterval.toString()];
            return cmd.concat(root.validDisks);
        }

        stdout: SplitParser {
            onRead: data => {
                try {
                    const stats = JSON.parse(data);

                    // Static info (received once at start)
                    if (stats.static) {
                        root.cpuModel = stats.static.cpu_model || root.cpuModel;
                        root.diskTypes = stats.static.disk_types || {};
                        return;
                    }

                    // Update metrics
                    if (stats.cpu) {
                        root.cpuUsage = stats.cpu.usage;
                        root.cpuTemp = stats.cpu.temp;
                    }

                    if (stats.ram) {
                        root.ramUsage = stats.ram.usage;
                        root.ramTotal = stats.ram.total;
                        root.ramUsed = stats.ram.used;
                        root.ramAvailable = stats.ram.available;
                    }

                    if (stats.disk)
                        root.diskUsage = stats.disk.usage;

                    if (stats.uptime !== undefined)
                        root.uptimeSec = stats.uptime;

                    if (stats.loadavg)
                        root.loadAvg = stats.loadavg;

                    root.updateHistory();
                } catch (e) {
                    console.warn("SystemResources: Failed to parse monitor data: " + e);
                }
            }
        }
    }

    Component.onCompleted: validateDisks()

    Connections {
        target: Config.system
        function onDisksChanged() {
            root.validateDisks();
        }
    }

    property bool configReady: Config.initialLoadComplete
    onConfigReadyChanged: if (configReady)
        validateDisks()

    onValidDisksChanged: if (monitorProcess.running)
        restartMonitor()
    onUpdateIntervalChanged: if (monitorProcess.running)
        restartMonitor()

    function restartMonitor() {
        monitorProcess.running = false;
        Qt.callLater(() => {
            monitorProcess.running = true;
        });
    }

    function validateDisks() {
        const configuredDisks = Config.system.disks || ["/"];
        let newValidDisks = [];
        for (let i = 0; i < configuredDisks.length; i++) {
            const disk = configuredDisks[i];
            if (disk && typeof disk === 'string' && disk.trim() !== '') {
                newValidDisks.push(disk.trim());
            }
        }
        if (newValidDisks.length === 0)
            newValidDisks = ["/"];
        validDisks = newValidDisks;
    }

    function updateHistory() {
        totalDataPoints++;

        // Helper to update history arrays
        const pushHistory = (arr, val) => {
            let next = arr.slice();
            next.push(val);
            if (next.length > maxHistoryPoints)
                next.shift();
            return next;
        };

        cpuHistory = pushHistory(cpuHistory, cpuUsage / 100);
        cpuTempHistory = pushHistory(cpuTempHistory, cpuTemp);
        ramHistory = pushHistory(ramHistory, ramUsage / 100);
    }
}
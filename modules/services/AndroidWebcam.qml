pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string scriptPath: Quickshell.shellDir + "/scripts/android-webcam.sh"

    // Configurable (persisted to android-webcam.json)
    property string cameraFacing: "back"
    property string cameraSize: "1920x1080"
    property string videoNode: "/dev/video10"

    readonly property var availableFacings: ["back", "front"]
    readonly property var availableSizes: ["640x480", "1280x720", "1920x1080"]

    // Torch is always on (fixed flag in script, shown as info in UI)
    readonly property bool torchAlwaysOn: true

    // Live status
    property bool isActive: false
    property bool hasModule: false
    property bool hasDevice: false
    property string activePid: ""
    property bool busy: false
    property bool needsSetup: false
    property string lastError: ""

    readonly property string stateText: {
        if (root.busy)
            return "Working…";
        if (root.isActive)
            return "Live";
        if (root.needsSetup)
            return "Needs setup";
        return "Off";
    }

    function refresh() {
        statusProcess.command = ["bash", root.scriptPath, "status", "--node", root.videoNode];
        statusProcess.running = true;
    }

    function start() {
        if (root.busy || root.isActive)
            return;
        root.busy = true;
        root.lastError = "";
        root.needsSetup = false;
        startProcess.command = ["bash", root.scriptPath, "start", "--facing", root.cameraFacing, "--size", root.cameraSize, "--node", root.videoNode];
        startProcess.running = true;
    }

    function stop() {
        if (root.busy || !root.isActive)
            return;
        root.busy = true;
        root.lastError = "";
        stopProcess.command = ["bash", root.scriptPath, "stop", "--node", root.videoNode];
        stopProcess.running = true;
    }

    function toggle() {
        if (root.isActive)
            root.stop();
        else
            root.start();
    }

    function setFacing(value) {
        if (root.cameraFacing === value)
            return;
        root.cameraFacing = value;
        saveConfig();
        // Apply on next start; restart live stream to apply immediately
        if (root.isActive) {
            restartAfterConfig = true;
            root.stop();
        }
    }

    function setSize(value) {
        if (root.cameraSize === value)
            return;
        root.cameraSize = value;
        saveConfig();
        if (root.isActive) {
            restartAfterConfig = true;
            root.stop();
        }
    }

    property bool restartAfterConfig: false

    // ---- Persistence (plain JSON, no password ever stored) ----
    property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ambxst/android-webcam.json"
    property bool _configLoaded: false

    function saveConfig() {
        if (!root._configLoaded)
            return;
        const data = {
            "cameraFacing": root.cameraFacing,
            "cameraSize": root.cameraSize,
            "videoNode": root.videoNode
        };
        configFile.setText(JSON.stringify(data, null, 4));
    }

    property FileView configFile: FileView {
        id: configFile
        path: root.configPath
        atomicWrites: true
        watchChanges: true
        onLoaded: {
            const raw = configFile.text();
            if (!raw || raw.trim().length === 0) {
                configFile.setText(JSON.stringify({
                    "cameraFacing": root.cameraFacing,
                    "cameraSize": root.cameraSize,
                    "videoNode": root.videoNode
                }, null, 4));
            } else {
                try {
                    const data = JSON.parse(raw);
                    if (typeof data.cameraFacing === "string" && root.availableFacings.indexOf(data.cameraFacing) !== -1)
                        root.cameraFacing = data.cameraFacing;
                    if (typeof data.cameraSize === "string" && root.availableSizes.indexOf(data.cameraSize) !== -1)
                        root.cameraSize = data.cameraSize;
                    if (typeof data.videoNode === "string" && data.videoNode.length > 0)
                        root.videoNode = data.videoNode;
                } catch (e) {
                    console.warn("[AndroidWebcam] Failed to parse config:", e);
                }
            }
            root._configLoaded = true;
        }
        onFileChanged: {
            // External edit: re-read (skip while we are the writer is handled
            // implicitly since values are identical after parse)
            configFile.reload();
        }
    }

    // ---- Status polling ----
    property Timer statusTimer: Timer {
        interval: 2000
        repeat: true
        running: !SuspendManager.isSuspending
        onTriggered: root.refresh()
    }

    function parseStatus(text) {
        const lines = text.trim().split("\n");
        for (let i = 0; i < lines.length; i++) {
            const idx = lines[i].indexOf("=");
            if (idx === -1)
                continue;
            const key = lines[i].substring(0, idx).trim();
            const val = lines[i].substring(idx + 1).trim();
            if (key === "active")
                root.isActive = (val === "true");
            else if (key === "module")
                root.hasModule = (val === "true");
            else if (key === "device")
                root.hasDevice = (val === "true");
            else if (key === "pid")
                root.activePid = val;
        }
    }

    property Process statusProcess: Process {
        id: statusProcess
        running: false
        stdout: StdioCollector {}
        onExited: exitCode => {
            if (exitCode === 0)
                root.parseStatus(statusProcess.stdout.text);
        }
    }

    property Process startProcess: Process {
        id: startProcess
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => {
            const out = startProcess.stdout.text.trim();
            root.busy = false;
            if (out.indexOf("STARTED") !== -1 || out.indexOf("ALREADY_ACTIVE") !== -1) {
                root.needsSetup = false;
                notifyProcess.command = ["notify-send", "Android Webcam", "Stream started (" + root.cameraFacing + ", " + root.cameraSize + ")"];
                notifyProcess.running = true;
            } else if (out.indexOf("NEED_SETUP") !== -1) {
                root.needsSetup = true;
                root.lastError = "Cannot load v4l2loopback without password. Run once: sudo bash " + Quickshell.shellDir + "/scripts/setup-v4l2loopback-nopasswd.sh";
            } else if (out.indexOf("MISSING_SCRCPY") !== -1) {
                root.lastError = "scrcpy is not installed.";
            } else {
                root.lastError = "Failed to start. Is the phone connected (adb)? " + startProcess.stderr.text.trim();
            }
            root.refresh();
        }
    }

    property Process stopProcess: Process {
        id: stopProcess
        running: false
        stdout: StdioCollector {}
        onExited: exitCode => {
            const out = stopProcess.stdout.text.trim();
            root.busy = false;
            if (out.indexOf("STOPPED") !== -1 || out.indexOf("ALREADY_STOPPED") !== -1) {
                notifyProcess.command = ["notify-send", "Android Webcam", "Stream stopped"];
                notifyProcess.running = true;
            } else {
                root.lastError = "Failed to stop scrcpy.";
            }
            if (root.restartAfterConfig) {
                root.restartAfterConfig = false;
                Qt.callLater(() => root.start());
            } else {
                root.refresh();
            }
        }
    }

    property Process notifyProcess: Process {
        running: false
    }

    Component.onCompleted: root.refresh()
}

.pragma library

var items = [
    { "id": "launcher", "label": "Launcher" },
    { "id": "workspaces", "label": "Workspaces" },
    { "id": "layout", "label": "Layout Selector" },
    { "id": "pin", "label": "Pin Button" },
    { "id": "notch", "label": "Notch Spacer" },
    { "id": "presets", "label": "Presets" },
    { "id": "tools", "label": "Tools" },
    { "id": "systray", "label": "System Tray" },
    { "id": "controls", "label": "Controls" },
    { "id": "androidWebcam", "label": "Android Webcam" },
    { "id": "battery", "label": "Battery" },
    { "id": "clock", "label": "Clock" },
    { "id": "power", "label": "Power" },
    { "id": "separator", "label": "Separator" }
];

var itemIds = [];
for (var i = 0; i < items.length; i++) {
    itemIds.push(items[i].id);
}

// Items supported in vertical bar layout
var verticalItemIds = [
    "launcher",
    "systray",
    "tools",
    "presets",
    "layout",
    "workspaces",
    "pin",
    "controls",
    "androidWebcam",
    "battery",
    "clock",
    "power"
];

var defaultLeft = ["launcher", "workspaces", "layout", "pin"];
var defaultCenter = [];
var defaultRight = ["presets", "tools", "systray", "controls", "androidWebcam", "battery", "clock", "power"];

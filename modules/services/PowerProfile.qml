pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.theme

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────

    property var availableProfiles: [
        "power-saver",
        "balanced",
        "performance"
    ]

    property string currentProfile: ""
    property bool isAvailable: false

    signal profileChanged(string profile)


    // ── Internal state ────────────────────────────────────────

    // True while tlpctl set is still running.
    property bool _isSettingProfile: false

    // If another profile is requested while one is being applied,
    // only the latest request is kept here.
    property string _pendingProfile: ""

    // Profile that we expect TLP to have after the current set.
    // Used to ignore stale reads while TLP is still applying a change.
    property string _expectedProfile: ""


    // ── Startup ───────────────────────────────────────────────

    Component.onCompleted: {
        console.info("PowerProfile: service starting");
        checkTLP.running = true;
    }


    // ── TLP detection ─────────────────────────────────────────

    Process {
        id: checkTLP

        workingDirectory: "/"
        command: ["bash", "-c", "command -v tlp"]
        running: false

        stdout: SplitParser {}

        onExited: exitCode => {
            if (exitCode === 0) {
                console.info("PowerProfile: tlp detected");

                isAvailable = true;

                // Read the current TLP profile.
                getTLPProc.running = true;

            } else {
                console.warn(
                    "PowerProfile: TLP not found"
                );

                isAvailable = false;
            }
        }
    }


    // ── TLP: read current profile ─────────────────────────────

    Process {
        id: getTLPProc

        workingDirectory: "/"
        command: ["/sbin/tlpctl", "get"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();

                if (!line)
                    return;

                console.info(
                    "PowerProfile: tlpctl get →",
                    line
                );


                // Convert TLP output into our internal
                // profile names.
                let profile = "";

                if (
                    line.includes("power-saver") ||
                    line.includes("powersaver")
                ) {
                    profile = "power-saver";

                } else if (line.includes("balanced")) {
                    profile = "balanced";

                } else if (line.includes("performance")) {
                    profile = "performance";
                }


                // Unknown TLP output.
                if (!profile)
                    return;


                // Ignore stale reads while a profile change
                // is still being applied.
                if (
                    _isSettingProfile &&
                    profile !== _expectedProfile
                ) {
                    console.info(
                        "PowerProfile: discarding stale tlp read '" +
                        profile +
                        "', expected '" +
                        _expectedProfile +
                        "'"
                    );

                    return;
                }


                // Only notify when the profile actually changed.
                if (currentProfile !== profile) {
                    currentProfile = profile;

                    console.info(
                        "PowerProfile: current profile →",
                        profile
                    );

                    profileChanged(profile);
                }
            }
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn(
                    "PowerProfile: tlpctl get failed (exit " +
                    exitCode +
                    ")"
                );
            }
        }
    }


    // ── TLP: set profile ──────────────────────────────────────

    Process {
        id: setProc

        workingDirectory: "/"
        running: false

        stdout: SplitParser {}

        stderr: SplitParser {
            onRead: data => {
                const err = data.trim();

                if (err) {
                    console.warn(
                        "PowerProfile: stderr:",
                        err
                    );
                }
            }
        }

        onExited: exitCode => {

            // The set operation has finished.
            _isSettingProfile = false;


            if (exitCode === 0) {

                console.info(
                    "PowerProfile: profile applied successfully"
                );


                // The expected profile has now been applied,
                // so stale-read protection is no longer needed.
                _expectedProfile = "";


                // If another profile was requested while this
                // operation was running, apply the latest request.
                if (_pendingProfile !== "") {

                    const next = _pendingProfile;

                    _pendingProfile = "";

                    setProfile(next);
                }


                /*
                 * Do not immediately call tlpctl get here.
                 *
                 * TLP may still be propagating the new state.
                 * Reading immediately could return the previous
                 * profile and cause a race.
                 *
                 * currentProfile was already updated optimistically
                 * inside setProfile().
                 */

            } else {

                console.warn(
                    "PowerProfile: failed to apply profile (exit " +
                    exitCode +
                    ")"
                );


                // The pending request is discarded after failure.
                _pendingProfile = "";

                // Stop stale-read filtering.
                _expectedProfile = "";


                // Synchronize our state with the actual TLP state.
                Qt.callLater(() => {

                    if (!getTLPProc.running) {
                        getTLPProc.running = true;
                    }

                });
            }
        }
    }


    // ── Public API ────────────────────────────────────────────

    function updateCurrentProfile() {

        if (!isAvailable || _isSettingProfile)
            return;

        if (!getTLPProc.running) {
            getTLPProc.running = true;
        }
    }


    function setProfile(profileName) {

        // TLP is unavailable.
        if (!isAvailable) {
            console.warn(
                "PowerProfile: TLP is not available"
            );

            return;
        }


        // Reject profiles that we don't support.
        if (availableProfiles.indexOf(profileName) === -1) {
            console.warn(
                "PowerProfile: unknown profile '" +
                profileName +
                "'"
            );

            return;
        }


        // A profile change is already running.
        //
        // Instead of starting another Process simultaneously,
        // remember the latest requested profile.
        if (_isSettingProfile || setProc.running) {

            console.info(
                "PowerProfile: queuing '" +
                profileName +
                "' (set in progress)"
            );

            _pendingProfile = profileName;

            return;
        }


        console.info(
            "PowerProfile: applying '" +
            profileName +
            "' via TLP"
        );


        // Mark the operation as running.
        _isSettingProfile = true;

        // Remember what we expect TLP to become.
        _expectedProfile = profileName;


        // Optimistic update.
        //
        // The UI changes immediately instead of waiting for
        // another tlpctl get.
        currentProfile = profileName;

        profileChanged(profileName);


        // TLP command.
        setProc.command = [
            "/sbin/tlpctl",
            "set",
            profileName
        ];

        setProc.running = true;
    }


    // ── Helpers ───────────────────────────────────────────────

    function getProfileIcon(profileName) {

        if (profileName === "power-saver")
            return Icons.powerSave;

        if (profileName === "balanced")
            return Icons.balanced;

        if (profileName === "performance")
            return Icons.performance;

        return Icons.balanced;
    }


    function getProfileDisplayName(profileName) {

        if (profileName === "power-saver")
            return "Power Save";

        if (profileName === "balanced")
            return "Balanced";

        if (profileName === "performance")
            return "Performance";

        return profileName;
    }
}

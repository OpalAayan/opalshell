import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io

/* =============================================================================
 * WorkspaceBar.qml — Hyprland workspaces, with urgency ("this window wants
 * attention") support.
 *
 * HOW URGENCY WORKS HERE
 * Hyprland emits `urgent>>WINDOWADDRESS` on its event socket when a client
 * asks for attention (terminal bell, xdg-activation request, some XWayland
 * apps at startup). Quickshell already listens on that socket, resolves the
 * address to a window, and exposes the result as HyprlandWorkspace.urgent.
 *
 * So we never open the Hyprland request socket ourselves — that socket is
 * handled synchronously by the compositor and an unclosed connection can
 * freeze it. Nothing in this file can do that: no sockets, no polling, no
 * extra processes. Just a property binding.
 *
 * Quickshell clears `urgent` on its own once the workspace is focused.
 * ============================================================================= */

Item {
    id: wsBar
    implicitWidth: wsRow.implicitWidth + 8
    implicitHeight: 28

    property string monitorName: ""

    // ==========================================
    // TWEAK URGENCY LOOK/FEEL HERE:
    property color urgentColor: "#f38ba8"   // Catppuccin Red
    property bool  urgentPulse: true        // false = steady ring, no blinking
    property int   urgentPulseMs: 600       // one fade in / fade out leg
    property int   urgentStartupGraceMs: 3000 // ignore urgency for N ms after
                                              // launch, so autostarted apps
                                              // don't light up the bar at login.
                                              // Set to 0 to disable.
    // ==========================================

    property var allWorkspaces: Hyprland.workspaces.values
    property int activeId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    property var persistentWorkspaces: {
        if (monitorName.startsWith("LVDS") || monitorName.startsWith("eDP")) {
            return [1, 2, 3, 4];
        } else {
            return [6, 7, 8, 9]; // external monitor
        }
    }

    property var activeWorkspaces: {
        var set = {};

        // 1. Add persistent workspaces for this monitor
        for (var i = 0; i < persistentWorkspaces.length; ++i) {
            set[persistentWorkspaces[i]] = true;
        }

        // 2. Add existing ones on THIS monitor ONLY
        for (var i = 0; i < allWorkspaces.length; ++i) {
            var w = allWorkspaces[i];
            if (w.id > 0 && w.monitor && w.monitor.name === monitorName) {
                set[w.id] = true;
            }
        }

        var arr = Object.keys(set).map(function(k) { return parseInt(k); });
        arr.sort(function(a, b) { return a - b; });
        return arr;
    }

    /* — Startup grace period —
     * `armed` gates urgency. Anything that goes urgent before we arm is
     * ignored until it changes again, so a noisy login stays quiet. */
    property bool armed: urgentStartupGraceMs <= 0

    Timer {
        interval: wsBar.urgentStartupGraceMs
        running: !wsBar.armed
        repeat: false
        onTriggered: wsBar.armed = true
    }

    /* — One-time sanity check —
     * HyprlandWorkspace.urgent needs Quickshell >= 0.3.1. On an older build the
     * property is simply undefined, which would silently disable urgency
     * instead of erroring — so say so once, loudly, in the logs. */
    property bool urgentApiChecked: false

    function checkUrgentApi() {
        if (urgentApiChecked || allWorkspaces.length === 0)
            return;
        urgentApiChecked = true;
        if (typeof allWorkspaces[0].urgent === "undefined")
            console.warn("WorkspaceBar: this Quickshell build has no "
                       + "HyprlandWorkspace.urgent — urgent workspaces will "
                       + "never highlight. Update Quickshell to 0.3.1+.");
    }

    Component.onCompleted: checkUrgentApi()
    onAllWorkspacesChanged: checkUrgentApi()

    RowLayout {
        id: wsRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: wsBar.activeWorkspaces

            Rectangle {
                id: wsBtn
                property int wsId: modelData
                property bool isActive: wsBar.activeId === wsId

                // The live HyprlandWorkspace object, or null for a persistent
                // workspace that doesn't exist in Hyprland right now.
                readonly property var wsObj: {
                    var list = wsBar.allWorkspaces;
                    for (var i = 0; i < list.length; ++i) {
                        if (list[i].id === wsBtn.wsId)
                            return list[i];
                    }
                    return null;
                }

                // Live window count. `toplevels` updates on open/close/move
                // events; lastIpcObject is the stale-but-better-than-nothing
                // fallback.
                readonly property int windowCount: {
                    if (!wsObj) return 0;
                    if (wsObj.toplevels) return wsObj.toplevels.values.length;
                    var ipc = wsObj.lastIpcObject;
                    return (ipc && ipc.windows) ? ipc.windows : 0;
                }
                readonly property bool hasWindows: windowCount > 0

                // Raw urgency straight from Quickshell. `=== true` keeps this
                // false (instead of undefined) on builds without the property.
                readonly property bool wantsAttention: wsObj ? wsObj.urgent === true : false

                // Latched copy of the above, so the grace period can swallow
                // urgency raised before we armed.
                property bool urgent: false

                onWantsAttentionChanged: urgent = wantsAttention && wsBar.armed && !isActive
                onIsActiveChanged: if (isActive) urgent = false     // visited it
                onWindowCountChanged: if (windowCount === 0) urgent = false // it left

                // ==========================================
                // TWEAK WORKSPACE CIRCLE SHAPE/SIZE HERE:
                // For a perfect circle, inactive width and height MUST be equal,
                // and the radius MUST be exactly HALF of that number!
                // Example: Width 24, Height 24, Radius 12
                Layout.preferredWidth: isActive ? 30 : 28 // 30 when active, 22 when inactive
                Layout.preferredHeight: 22 // 22 tall always
                radius: 11 // Half of 22 = perfect circle!
                // ==========================================

                // Elegant highlight for active workspace, red wash when urgent
                color: isActive
                       ? Qt.rgba(203/255, 166/255, 247/255, 1.0) // Mauve solid
                       : urgent
                         ? Qt.rgba(wsBar.urgentColor.r, wsBar.urgentColor.g,
                                   wsBar.urgentColor.b, 0.20)
                         : (wsMouseArea.containsMouse ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : "transparent")

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutExpo } }

                Text {
                    anchors.centerIn: parent

                    // ==========================================
                    // TWEAK THESE VALUES TO PERFECTLY CENTER IT:
                    // Positive values move text right/down
                    // Negative values move text left/up
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: 1
                    // ==========================================

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: wsBtn.wsId
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                    // Dark when active, red when urgent, light when it has windows
                    color: wsBtn.isActive
                           ? "#11111b"
                           : wsBtn.urgent
                             ? wsBar.urgentColor
                             : (wsBtn.hasWindows ? "#cdd6f4" : "#6c7086")
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Tiny elegant dot indicator for workspaces with windows but not active
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: "#cdd6f4"
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !wsBtn.isActive && wsBtn.hasWindows && !wsBtn.urgent
                }

                // Urgent Indicator: Bottom Red Bar (inset 0 -3px #f38ba8)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    height: 3
                    radius: 2
                    color: wsBar.urgentColor
                    visible: wsBtn.urgent
                }

                // Urgent Indicator: Pulsing Outer Glow.
                // The animation drives `pulse`, never `opacity` directly — an
                // animation that writes to a property destroys that property's
                // binding for good, and we want opacity to stay bound.
                Rectangle {
                    id: urgentRing
                    property real pulse: 0

                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: wsBtn.radius + 2
                    color: "transparent"
                    border.color: wsBar.urgentColor
                    border.width: 2

                    opacity: wsBtn.urgent ? (wsBar.urgentPulse ? pulse : 0.65) : 0
                    visible: opacity > 0.001   // nothing to composite when idle

                    SequentialAnimation {
                        // Stopped entirely when nothing is urgent, so an idle
                        // bar costs zero frames.
                        running: wsBtn.urgent && wsBar.urgentPulse
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) urgentRing.pulse = 0

                        NumberAnimation {
                            target: urgentRing; property: "pulse"
                            from: 0; to: 0.65
                            duration: wsBar.urgentPulseMs
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            target: urgentRing; property: "pulse"
                            to: 0
                            duration: wsBar.urgentPulseMs
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                MouseArea {
                    id: wsMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        wsProc.command = ["hyprctl", "dispatch",
                            "hl.dsp.focus({ workspace = \"" + wsBtn.wsId + "\" })"]
                        wsProc.running = true
                    }
                }

                Process {
                    id: wsProc
                    running: false
                }
            }
        }
    }
}


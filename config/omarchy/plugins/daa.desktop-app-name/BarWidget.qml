import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Short name of the focused app: the last segment of its app id, lowercased,
// so "org.kde.dolphin" reads "dolphin" and "firefox" stays "firefox".
BarWidget {
  id: root
  moduleName: "daa.desktop-app-name"

  readonly property var toplevel: ToplevelManager.activeToplevel
  readonly property string appId: toplevel ? (toplevel.appId || "") : ""
  readonly property string appName: {
    var parts = appId.split(".")
    return parts[parts.length - 1].toLowerCase()
  }

  // Hyprland keeps focus on a scratchpad window after the scratchpad is sent
  // back, so ask it whether the focused window's workspace is still on screen.
  property bool focusHidden: false

  function refreshFocus() {
    if (!focusProc.running) focusProc.running = true
    else focusProc.stale = true
  }

  Process {
    id: focusProc
    property bool stale: false
    command: ["sh", "-c",
      "hyprctl -j activewindow | jq -r '.workspace.name // \"\"'; " +
      "hyprctl -j monitors | jq -r '[.[].specialWorkspace.name | select(. != \"\")] | join(\" \")'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.split("\n")
        var workspace = lines[0] || ""
        var shown = (lines[1] || "").split(" ")
        root.focusHidden = workspace.indexOf("special:") === 0 && shown.indexOf(workspace) === -1
      }
    }
    onExited: if (stale) { stale = false; running = true }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event.name
      if (name === "activespecial" || name === "activewindowv2" || name === "workspacev2"
          || name === "focusedmonv2" || name === "movewindowv2" || name === "closewindow")
        root.refreshFocus()
    }
  }

  Component.onCompleted: refreshFocus()

  visible: appName !== "" && !focusHidden && !vertical
  implicitWidth: visible ? labelText.implicitWidth + Style.space(16) : 0
  implicitHeight: barSize

  Behavior on implicitWidth {
    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
  }

  Text {
    id: labelText
    textFormat: Text.PlainText
    anchors.centerIn: parent
    text: root.appName
    color: root.bar ? root.bar.barForeground : Commons.Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    opacity: 0.85
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (root.bar && root.toplevel) root.bar.showTooltip(root, root.toplevel.title || root.appId)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}

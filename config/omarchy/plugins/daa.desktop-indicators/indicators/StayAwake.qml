import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

FlyoutIndicator {
  id: root

  // The idle service can't be looked up from here (firstPartyServiceFor
  // returns null for omarchy.idle, unlike nightlight), so the chip showed
  // "off" forever while its clicks did toggle. Use the same state file and
  // command as `omarchy toggle idle`, which the service watches anyway.
  readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/omarchy/indicators/stay-awake"
  property bool stayAwake: false

  active: stayAwake
  activeText: "󰅶"
  inactiveText: "󰅶"
  activeTooltipText: "Allow Idle Lock & Screensaver"
  inactiveTooltipText: "Stay Awake"

  function toggle() {
    // Flip at once so the chip responds; the next probe confirms.
    root.stayAwake = !root.stayAwake
    Quickshell.execDetached(["omarchy", "toggle", "idle"])
    probeLater.restart()
  }

  onPressed: function() { root.toggle() }

  Process {
    id: probe
    command: ["test", "-f", root.stateFile]
    onExited: function(code) { root.stayAwake = code === 0 }
  }

  Timer {
    interval: 2000
    repeat: true
    triggeredOnStart: true
    running: true
    onTriggered: if (!probe.running) probe.running = true
  }

  Timer {
    id: probeLater
    interval: 600
    onTriggered: if (!probe.running) probe.running = true
  }
}

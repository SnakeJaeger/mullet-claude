import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Tablet bar button: tap toggles auto-rotate, hold opens the orientation
// picker (omarchy menu summon tablet.orient; the hold arrives via
// triggerHold). Shows a lock glyph while ~/.local/bin/tablet-mode has
// rotation locked.
BarWidget {
  id: root
  moduleName: "daa.tablet-rotate"

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/tablet-mode"
  property bool locked: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // The lock is a marker file; poll it (cheap test -e) rather than watch a
  // file that comes and goes.
  Process {
    id: lockCheck
    command: ["test", "-e", root.stateDir + "/rotate-lock"]
    onExited: function(code) { root.locked = code === 0 }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: lockCheck.running = true
  }

  // Nerd Font glyphs paint wider than their advance, so centring the
  // character leaves the ink off-centre down a vertical bar; shift it back.
  TextMetrics {
    id: ink
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: Math.round(Style.font.body * 1.2)
    text: button.text
  }

  // Long press, forwarded by the tablet bar (daa.tablet-bar's module touch
  // area calls triggerHold()): the orientation picker.
  function triggerHold() {
    if (root.bar) root.bar.run("omarchy menu summon tablet.orient")
  }

  WidgetButton {
    id: button
    width: parent.width
    height: parent.height
    x: root.vertical ? -Math.round(ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2 - ink.advanceWidth / 2) : 0
    bar: root.bar
    text: root.locked ? "󰑸" : "󰑵"
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Math.round(Style.font.body * 1.2)
    horizontalMargin: 7.5
    tooltipText: root.locked ? "Rotation locked (hold to pick)" : "Auto-rotate (hold to pick)"
    foreground: (((root.bar && root.bar.flashModule === root.moduleName) || (button.tooltipHovered && !(root.bar && root.bar.hoverCleared))) || root.locked) ? Color.pick("tablet.accent", Color.accent) : (root.bar ? root.bar.barForeground : Color.foreground)
    // A tap, from finger (via the bar's touch area), pen or mouse.
    onPressed: function() {
      if (!root.bar) return
      root.bar.run(Quickshell.env("HOME") + "/.local/bin/tablet-mode rotate-lock")
      root.locked = !root.locked
    }
  }
}

import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Tablet bar button: tap opens the touch app grid (daa.tablet-apps-grid)
// (~/.config/omarchy/extensions/omarchy-menu.jsonc). Only the tablet bar
// (daa.tablet-bar) uses it.
BarWidget {
  id: root
  moduleName: "daa.tablet-apps"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Nerd Font glyphs paint wider than their advance, so centring the
  // character leaves the ink off-centre down a vertical bar; shift it back.
  TextMetrics {
    id: ink
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: Math.round(Style.font.body * 1.2)
    text: button.text
  }

  WidgetButton {
    id: button
    width: parent.width
    height: parent.height
    x: root.vertical ? -Math.round(ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2 - ink.advanceWidth / 2) : 0
    bar: root.bar
    text: "󰀻"
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Math.round(Style.font.body * 1.2)
    horizontalMargin: 7.5
    tooltipText: "Touch apps"
    foreground: ((root.bar && root.bar.flashModule === root.moduleName) || (button.tooltipHovered && !(root.bar && root.bar.hoverCleared))) ? Color.pick("tablet.accent", Color.accent) : (root.bar ? root.bar.barForeground : Color.foreground)
    onPressed: function() { if (root.bar) root.bar.run("omarchy-shell shell toggle daa.tablet-apps-grid") }
  }
}

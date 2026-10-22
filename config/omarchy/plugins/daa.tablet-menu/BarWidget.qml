import QtQuick
import qs.Commons
import qs.Ui

// Same behaviour as omarchy.menu's bar button, drawn with the Nerd Font
// Arch logo (nf-linux-archlinux, U+F303) instead of the Omarchy glyph.
// Turns the theme accent (same as the focused workspace dot) while hovered.
// Tablet bar copy: opens the tablet menu; the menu's back arrow leads up to
// the full Omarchy menu.
BarWidget {
  id: root
  moduleName: "daa.tablet-menu"

  // WidgetButton's own hover MouseArea (the one driving its tooltip).
  readonly property bool hovered: (bar && bar.flashModule === moduleName) || (button.tooltipHovered && !(bar && bar.hoverCleared))


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
    text: ""
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Math.round(Style.font.body * 1.2)
    horizontalMargin: 7.5
    tooltipText: "Tablet menu"
    foreground: root.hovered ? Color.pick("tablet.accent", Color.accent) : (root.bar ? root.bar.barForeground : Color.foreground)
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"tablet\"}'")
    }
  }
}

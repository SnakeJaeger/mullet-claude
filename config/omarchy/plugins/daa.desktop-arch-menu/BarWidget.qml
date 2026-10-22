import QtQuick
import qs.Commons
import qs.Ui

// Same behaviour as omarchy.menu's bar button, drawn with the Nerd Font
// Arch logo (nf-linux-archlinux, U+F303) instead of the Omarchy glyph.
// Turns the theme accent (same as the focused workspace dot) while hovered.
BarWidget {
  id: root
  moduleName: "daa.desktop-arch-menu"

  // WidgetButton's own hover MouseArea (the one driving its tooltip).
  readonly property bool hovered: button.tooltipHovered

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: Math.round(Style.font.body * 1.2)
    horizontalMargin: 7.5
    tooltipText: "Menu"
    foreground: root.hovered ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}

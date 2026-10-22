import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Touch app grid for the tablet bar's 󰀻 button: the apps listed in
// ~/.config/tablet-mode/apps as a 4-column grid, a wide scroll rail beside the
// card (flicking a touch screen is unreliable), and File browser / All apps
// buttons along the bottom. Opens against the bar like the menus do.
// Built from daa.launcher (same surface tokens, icons and launch path).
Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property var appLibrary: root.shell ? root.shell.appLibrary : null

  property bool opened: false
  property var appIds: []

  readonly property int columns: 4
  readonly property int rows: 3

  property color background: Commons.Color.menu.background
  property color foreground: Commons.Color.menu.text
  property color border: Commons.Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Commons.Color.menu.scrim
  property color selectedBackground: Commons.Color.menu.selectedBackground
  property color selectedText: Commons.Color.menu.selectedText
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int contentSpacing: Style.spacing.md
  property int footerHeight: Style.space(48)

  property int iconSize: Style.space(56)
  property int cellWidth: Style.space(124)
  property int cellHeight: iconSize + Style.font.body * 2 + Style.space(26)
  property int railWidth: Style.space(22)

  function open(payloadJson) {
    root.opened = true
    if (root.appLibrary) root.appLibrary.refreshIcons()
    appList.reload()
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "daa.tablet-apps-grid")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function iconSource(icon) {
    if (root.appLibrary) return root.appLibrary.iconSource(icon)
    var value = String(icon || "")
    if (value.charAt(0) === "/") return "file://" + value
    var themed = value ? Quickshell.iconPath(value, true) : ""
    return themed.length > 0 ? themed : Quickshell.iconPath("application-x-executable", true)
  }

  // Apps in the order the list file gives them; ids that aren't installed
  // are skipped.
  function rebuildDisplay() {
    displayModel.clear()
    var byId = ({})
    if (root.appLibrary) {
      var rows = root.appLibrary.sortedEntries("")
      for (var i = 0; i < rows.length; i++) byId[String(rows[i].entry.id || "")] = rows[i].entry
    }
    for (var j = 0; j < root.appIds.length; j++) {
      var id = root.appIds[j]
      var entry = byId[id] || DesktopEntries.byId(id)
      if (!entry) continue
      var label = root.appLibrary && byId[id] ? root.appLibrary.entryName(entry) : String(entry.name || id)
      displayModel.append({ appId: id, label: label, appIcon: String(entry.icon || "") })
    }
    resultGrid.contentY = resultGrid.originY
  }

  function launch(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.dismiss()
    if (root.appLibrary) root.appLibrary.launch(row.appId, row.label)
    else Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", row.appId + ".desktop"])
  }

  function parseIds(rawText) {
    var ids = []
    var lines = String(rawText || "").split(/\n/)
    for (var i = 0; i < lines.length; i++) {
      var id = lines[i].replace(/#.*/, "").trim()
      if (id.slice(-8) === ".desktop") id = id.slice(0, -8)
      if (id.length > 0 && ids.indexOf(id) === -1) ids.push(id)
    }
    return ids
  }

  ListModel { id: displayModel }

  FileView {
    id: appList
    path: Quickshell.env("HOME") + "/.config/tablet-mode/apps"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      root.appIds = root.parseIds(text())
      if (root.opened) root.rebuildDisplay()
    }
  }

  Connections {
    target: root.appLibrary
    function onAppsChanged() { if (root.opened) root.rebuildDisplay() }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Which edge the bar is on, read from shell.json (the scoped shell API
    // only has a startup snapshot), so the grid opens against it.
    property string barEdge: "top"
    FileView {
      path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
      watchChanges: true
      printErrors: false
      onFileChanged: reload()
      onLoaded: {
        try { panel.barEdge = String((JSON.parse(text() || "{}").bar || {}).position || "top") } catch (e) {}
      }
    }
    readonly property bool barVertical: barEdge === "left" || barEdge === "right"
    readonly property int barThickness: barVertical ? Style.bar.sizeVertical : Style.bar.sizeHorizontal + Style.space(4)

    onVisibleChanged: if (visible) cardPop.restart()

    SequentialAnimation {
      id: cardPop
      NumberAnimation { target: group; property: "scale"; from: 0.9; to: 1.05; duration: 130; easing.type: Easing.OutQuad }
      NumberAnimation { target: group; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.InOutQuad }
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    // Card plus the scroll rail, placed against the bar and centred along
    // it. The rail sits on the side nearer the screen edge (the bar side
    // when the bar is vertical), where the thumb is.
    Item {
      id: group
      width: card.width + Style.space(8) + root.railWidth
      height: card.height
      readonly property bool railLeft: panel.barEdge === "left"
        || (!panel.barVertical && x + width / 2 < panel.width / 2 - 1)
      x: panel.barEdge === "left" ? panel.barThickness + Style.gapsOut
        : panel.barEdge === "right" ? panel.width - panel.barThickness - Style.gapsOut - width
        : Math.round((panel.width - width) / 2)
      y: panel.barEdge === "top" ? panel.barThickness + Style.gapsOut
        : panel.barEdge === "bottom" ? panel.height - panel.barThickness - Style.gapsOut - height
        : Math.round((panel.height - height) / 2)

      MouseArea { anchors.fill: parent; onClicked: {} }

      BorderSurface {
        id: card
        x: group.railLeft ? root.railWidth + Style.space(8) : 0
        width: Math.min(root.cellWidth * root.columns + contentLeftInset + contentRightInset,
          panel.width - Style.gapsOut * 2 - root.railWidth - Style.space(8))
        height: Math.min(root.headerHeight + root.contentSpacing + root.cellHeight * root.rows
          + root.contentSpacing + root.footerHeight + contentTopInset + contentBottomInset,
          panel.height - Style.gapsOut * 2 - panel.barThickness)
        radius: root.cornerRadius
        color: root.background
        borderSpec: root.borderSpec
        padding: root.contentMargin

        Item {
          id: keyCatcher
          anchors.fill: parent
          focus: true
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              root.dismiss()
              event.accepted = true
            }
          }
        }

        Column {
          anchors.fill: parent
          anchors.topMargin: card.contentTopInset
          anchors.rightMargin: card.contentRightInset
          anchors.bottomMargin: card.contentBottomInset
          anchors.leftMargin: card.contentLeftInset
          spacing: root.contentSpacing

          Item {
            width: parent.width
            height: root.headerHeight

            Text {
              textFormat: Text.PlainText
              anchors.left: parent.left
              anchors.leftMargin: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              text: "Touch apps"
              color: root.foreground
              opacity: 0.58
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
            }
          }

          Item {
            width: parent.width
            height: parent.height - root.headerHeight - root.footerHeight - root.contentSpacing * 2

            GridView {
              id: resultGrid
              width: root.cellWidth * root.columns
              height: parent.height
              anchors.horizontalCenter: parent.horizontalCenter
              model: displayModel
              clip: true
              cellWidth: root.cellWidth
              cellHeight: root.cellHeight
              boundsBehavior: Flickable.StopAtBounds

              delegate: Item {
                id: cell
                required property int index
                required property string appId
                required property string label
                required property string appIcon

                width: root.cellWidth
                height: root.cellHeight

                Rectangle {
                  anchors.fill: parent
                  anchors.margins: Style.space(3)
                  radius: root.cornerRadius
                  color: cellArea.pressed || cellArea.containsMouse ? root.selectedBackground : "transparent"
                }

                Image {
                  id: icon
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.top: parent.top
                  anchors.topMargin: Style.space(12)
                  width: root.iconSize
                  height: root.iconSize
                  sourceSize.width: width * Screen.devicePixelRatio
                  sourceSize.height: height * Screen.devicePixelRatio
                  fillMode: Image.PreserveAspectFit
                  asynchronous: true
                  smooth: true
                  source: root.iconSource(cell.appIcon)
                }

                Text {
                  textFormat: Text.PlainText
                  anchors.top: icon.bottom
                  anchors.topMargin: Style.space(6)
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.leftMargin: Style.space(8)
                  anchors.rightMargin: Style.space(8)
                  text: cell.label
                  color: cellArea.pressed || cellArea.containsMouse ? root.selectedText : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.Wrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                }

                MouseArea {
                  id: cellArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.launch(cell.index)
                }
              }
            }

            Text {
              anchors.centerIn: parent
              visible: displayModel.count === 0
              textFormat: Text.PlainText
              text: "No apps listed in ~/.config/tablet-mode/apps"
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
            }
          }

          Row {
            id: footer
            width: parent.width
            height: root.footerHeight
            spacing: Style.space(8)

            Repeater {
              model: [
                // Files pops down as the SUPER + E dropdown (~/.config/hypr/dropdowns.lua).
                { icon: "󰉋", label: "File browser", command: ["sh", "-c", "sleep 0.3; hyprctl eval 'dropdown_show(\"files\")'"] },
                { icon: "󰀻", label: "All apps", command: ["omarchy-shell", "shell", "toggle", "daa.launcher"] }
              ]

              Rectangle {
                id: footerButton
                required property var modelData
                width: (footer.width - footer.spacing) / 2
                height: footer.height
                radius: root.cornerRadius
                color: buttonArea.pressed || buttonArea.containsMouse ? root.selectedBackground : Util.alpha(root.foreground, 0.06)

                Row {
                  anchors.centerIn: parent
                  spacing: Style.space(10)

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: footerButton.modelData.icon
                    color: buttonArea.pressed || buttonArea.containsMouse ? root.selectedText : root.foreground
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Style.font.heading
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: footerButton.modelData.label
                    color: buttonArea.pressed || buttonArea.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title
                  }
                }

                MouseArea {
                  id: buttonArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.dismiss()
                    Quickshell.execDetached(footerButton.modelData.command)
                  }
                }
              }
            }
          }
        }
      }

      // Scroll rail: drag the handle, or tap the rail to jump there. The
      // handle fills the rail when everything already fits.
      Rectangle {
        id: rail
        x: group.railLeft ? 0 : card.width + Style.space(8)
        width: root.railWidth
        height: card.height
        radius: width / 2
        color: Util.alpha(root.background, 0.92)
        border.width: 0  // borderless in tablet mode

        readonly property real overflow: Math.max(0, resultGrid.contentHeight - resultGrid.height)
        readonly property real inset: Style.space(4)
        readonly property real trackHeight: height - inset * 2
        readonly property real handleHeight: overflow > 0
          ? Math.max(width * 2, trackHeight * resultGrid.height / resultGrid.contentHeight) : trackHeight
        readonly property real position: overflow > 0 ? (resultGrid.contentY - resultGrid.originY) / overflow : 0

        Rectangle {
          x: rail.inset
          y: rail.inset + (rail.trackHeight - rail.handleHeight) * Math.max(0, Math.min(1, rail.position))
          width: rail.width - rail.inset * 2
          height: rail.handleHeight
          radius: width / 2
          color: railArea.pressed ? Commons.Color.pick("tablet.accent", Commons.Color.accent) : Util.alpha(root.foreground, rail.overflow > 0 ? 0.5 : 0.18)
        }

        MouseArea {
          id: railArea
          anchors.fill: parent
          preventStealing: true
          property real grab: 0

          function seek(mouseY) {
            if (rail.overflow <= 0) return
            var span = rail.trackHeight - rail.handleHeight
            var p = span > 0 ? (mouseY - rail.inset - grab) / span : 0
            resultGrid.contentY = resultGrid.originY + Math.max(0, Math.min(1, p)) * rail.overflow
          }

          onPressed: function(mouse) {
            var handleTop = rail.inset + (rail.trackHeight - rail.handleHeight) * rail.position
            grab = mouse.y >= handleTop && mouse.y <= handleTop + rail.handleHeight
              ? mouse.y - handleTop : rail.handleHeight / 2
            seek(mouse.y)
          }
          onPositionChanged: function(mouse) { if (pressed) seek(mouse.y) }
        }
      }
    }
  }
}

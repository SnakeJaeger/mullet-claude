import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// App launcher laid out as a 5 x 6 grid (scrolls past 30 apps). Type to
// search, arrows to move, Enter or click to launch, Escape to clear/close.
// Built from omarchy.emojis' grid picker. Apps come from the shell's shared
// app library when the host provides it (hidden entries, icons and launch
// feedback then match the menu), otherwise straight from DesktopEntries.
Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property var appLibrary: root.shell ? root.shell.appLibrary : null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  // Desktop ids hidden the same way the app library hides them: Omarchy's
  // launcher.hides list plus entries hidden for this desktop session.
  property var configuredHidden: ({})
  property var sessionHidden: ({})
  onConfiguredHiddenChanged: if (opened) rebuildDisplay()
  onSessionHiddenChanged: if (opened) rebuildDisplay()

  property bool opened: false
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false

  readonly property int columns: 5
  readonly property int rows: 6

  // Shares the [menu] surface tokens, like the emoji picker.
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

  property int iconSize: Style.space(48)
  property int cellWidth: Style.space(116)
  property int cellHeight: iconSize + Style.font.body * 2 + Style.space(22)

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    if (root.appLibrary) root.appLibrary.refreshIcons()
    else if (!sessionHiddenScan.running) sessionHiddenScan.running = true
    root.rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "daa.launcher")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  // Fallback app list when no app library is injected: visible desktop
  // entries, prefix matches first, then substring matches, each by name.
  function desktopEntryRows(query) {
    var q = String(query || "").trim().toLowerCase()
    var values = DesktopEntries.applications.values || []
    var rows = []
    for (var i = 0; i < values.length; i++) {
      var entry = values[i]
      if (!entry || entry.noDisplay || !entry.name) continue
      var id = String(entry.id || "")
      if (root.configuredHidden[id] || root.sessionHidden[id]) continue
      var name = String(entry.name)
      var lower = name.toLowerCase()
      var rank = 0
      if (q) {
        var generic = String(entry.genericName || "").toLowerCase()
        if (lower.indexOf(q) === 0) rank = 0
        else if (lower.indexOf(q) !== -1) rank = 1
        else if (generic.indexOf(q) !== -1) rank = 2
        else continue
      }
      rows.push({ id: id, name: name, icon: String(entry.icon || ""), rank: rank, key: lower })
    }
    rows.sort(function(a, b) {
      if (a.rank !== b.rank) return a.rank - b.rank
      return a.key < b.key ? -1 : (a.key > b.key ? 1 : 0)
    })
    return rows
  }

  function iconSource(icon) {
    if (root.appLibrary) return root.appLibrary.iconSource(icon)
    var value = String(icon || "")
    if (value.charAt(0) === "/") return "file://" + value
    var themed = value ? Quickshell.iconPath(value, true) : ""
    return themed.length > 0 ? themed : Quickshell.iconPath("application-x-executable", true)
  }

  function rebuildDisplay() {
    displayModel.clear()
    if (root.appLibrary) {
      var rows = root.appLibrary.sortedEntries(root.filterText)
      for (var i = 0; i < rows.length; i++) {
        var entry = rows[i].entry
        var appId = String(entry.id || "")
        if (!appId) continue
        displayModel.append({ appId: appId, label: root.appLibrary.entryName(entry), appIcon: String(entry.icon || "") })
      }
    } else {
      var fallback = root.desktopEntryRows(root.filterText)
      for (var j = 0; j < fallback.length; j++) {
        if (!fallback[j].id) continue
        displayModel.append({ appId: fallback[j].id, label: fallback[j].name, appIcon: fallback[j].icon })
      }
    }

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0
    cursorActive = displayModel.count > 0

    Qt.callLater(function() {
      if (displayModel.count > 0) resultGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain)
    })
  }

  function select(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function selectRow(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
      resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
      return
    }
    var newIndex = selectedIndex + delta * columns
    if (newIndex < 0) newIndex = 0
    if (newIndex >= displayModel.count) newIndex = displayModel.count - 1
    selectedIndex = newIndex
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function selectPage(delta) {
    if (displayModel.count === 0) return
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
      resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
      return
    }
    var newIndex = selectedIndex + delta * columns * rows
    if (newIndex < 0) newIndex = 0
    if (newIndex >= displayModel.count) newIndex = displayModel.count - 1
    selectedIndex = newIndex
    resultGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
  }

  function setFilter(nextFilter) {
    root.filterText = nextFilter
    root.selectedIndex = 0
    root.cursorActive = true
    root.rebuildDisplay()
  }

  function activateIndex(index) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    root.dismiss()
    if (root.appLibrary) root.appLibrary.launch(row.appId, row.label)
    // Same launch path as the app library: a scope outside the compositor's
    // service, with gtk-launch resolving the desktop id.
    else Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", row.appId + ".desktop"])
  }

  function idSet(rawText) {
    var next = ({})
    var lines = String(rawText || "").split(/\n/)
    for (var i = 0; i < lines.length; i++) {
      var id = lines[i].trim()
      if (id.slice(-8) === ".desktop") id = id.slice(0, -8)
      if (id.length > 0) next[id] = true
    }
    return next
  }

  ListModel { id: displayModel }

  // Tablet mode (~/.local/bin/tablet-mode) adds a touch scroll rail beside
  // the grid.
  property bool tabletOn: false
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/tablet-mode/state"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.tabletOn = String(text() || "").trim() === "on"
  }
  // The rail goes on the bar's side when the bar is vertical (where the thumb
  // is), otherwise on the right. Read from shell.json like the menu does.
  property bool railLeft: false
  FileView {
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.railLeft = (JSON.parse(text() || "{}").bar || {}).position === "left" } catch (e) {}
    }
  }

  FileView {
    path: root.omarchyPath + "/default/omarchy/launcher.hides"
    watchChanges: true
    printErrors: false
    onLoaded: root.configuredHidden = root.idSet(text())
    onFileChanged: reload()
  }

  Process {
    id: sessionHiddenScan
    property string output: ""
    running: true
    command: ["bash", "-c", Util.shellQuote(root.omarchyPath + "/shell/services/hidden-entries.sh") + " "
      + Util.shellQuote([Quickshell.env("XDG_CURRENT_DESKTOP"), Quickshell.env("XDG_SESSION_DESKTOP"), Quickshell.env("DESKTOP_SESSION")]
        .filter(function(v) { return String(v || "").length > 0 }).join(":"))]
    stdout: SplitParser { onRead: function(line) { sessionHiddenScan.output += line + "\n" } }
    onStarted: output = ""
    onExited: root.sessionHidden = root.idSet(output)
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

    // Pop the card in from its centre: 90% -> 105% -> 100%.
    onVisibleChanged: if (visible) cardPop.restart()

    SequentialAnimation {
      id: cardPop
      NumberAnimation { target: card; property: "scale"; from: 0.9; to: 1.05; duration: 130; easing.type: Easing.OutQuad }
      NumberAnimation { target: card; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.InOutQuad }
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      // Size from the surface's real insets (padding plus border) so all six
      // rows fit without clipping.
      width: Math.min(root.cellWidth * root.columns + contentLeftInset + contentRightInset, panel.width - Style.gapsOut * 2)
      height: Math.min(root.headerHeight + root.contentSpacing + root.cellHeight * root.rows + contentTopInset + contentBottomInset,
        panel.height - Style.gapsOut * 2)
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.dismiss()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Left) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Backtab) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.selectRow(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.selectRow(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.selectPage(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.selectPage(1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.cursorActive) root.activateIndex(root.selectedIndex)
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
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
            anchors.right: parent.right
            anchors.leftMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "Search apps…"
            color: root.foreground
            opacity: root.filterText ? 1 : 0.58
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            elide: Text.ElideRight
          }
        }

        Item {
          width: parent.width
          height: parent.height - root.headerHeight - root.contentSpacing

          GridView {
            id: resultGrid
            // Centre the 5 columns in whatever width the card ends up with.
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

              readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex

              width: root.cellWidth
              height: root.cellHeight

              Rectangle {
                anchors.fill: parent
                anchors.margins: Style.space(3)
                radius: root.cornerRadius
                color: cell.hasCursor ? root.selectedBackground : "transparent"
              }

              Image {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Style.space(12)
                width: root.iconSize
                height: root.iconSize
                // Render at device pixels so icons stay sharp on HiDPI.
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
                color: cell.hasCursor ? root.selectedText : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: if (containsMouse) {
                  root.cursorActive = true
                  root.selectedIndex = cell.index
                }
                onClicked: root.activateIndex(cell.index)
              }
            }
          }

          Column {
            anchors.centerIn: parent
            spacing: Style.space(8)
            visible: displayModel.count === 0

            Text {
              textFormat: Text.PlainText
              text: "No apps match “" + root.filterText + "”"
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }

    // Touch scroll rail (tablet mode, when the apps overflow): drag the handle
    // or tap the rail to jump.
    Rectangle {
      id: rail
      readonly property real overflow: Math.max(0, resultGrid.contentHeight - resultGrid.height)
      readonly property real inset: Style.space(4)
      readonly property real trackHeight: height - inset * 2
      readonly property real handleHeight: overflow > 0
        ? Math.max(width * 2, trackHeight * resultGrid.height / resultGrid.contentHeight) : trackHeight
      readonly property real position: overflow > 0 ? (resultGrid.contentY - resultGrid.originY) / overflow : 0

      visible: root.tabletOn && overflow > 0
      width: Style.space(22)
      height: card.height
      x: root.railLeft ? card.x - Style.space(8) - width : card.x + card.width + Style.space(8)
      y: card.y
      scale: card.scale
      radius: width / 2
      color: root.background
      border.width: 0  // borderless in tablet mode

      Rectangle {
        x: rail.inset
        y: rail.inset + (rail.trackHeight - rail.handleHeight) * Math.max(0, Math.min(1, rail.position))
        width: rail.width - rail.inset * 2
        height: rail.handleHeight
        radius: width / 2
        color: railArea.pressed ? Commons.Color.pick("tablet.accent", Commons.Color.accent) : Util.alpha(root.foreground, 0.5)
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

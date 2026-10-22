import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "daa.tablet-workspace"

  // Tablet bar copy of daa.desktop-workspaces: shows just the current workspace;
  // tapping it opens the workspace menu (switch or create).
  readonly property bool tabletOn: true


  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var focused = Hyprland.focusedWorkspace
    if (root.tabletOn) return focused && focused.id > 0 ? [focused.id] : [1]

    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  // The button for the focused workspace; the indicator springs to it.
  readonly property Item focusedButton: {
    var count = repeater.count
    var focused = Hyprland.focusedWorkspace
    if (!focused || count === 0) return null
    var index = root.workspaceIds().indexOf(focused.id)
    return index < 0 ? null : repeater.itemAt(index)
  }

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  // One shared indicator behind the numbers, centred on the painted digit
  // (not the button box, which leaves it looking off). It's a stadium like
  // the island around it: corner radius is half its height, so both share
  // the same fully rounded ends.
  //
  // Switching workspace: the trailing edge squeezes in toward the direction
  // of travel, then both edges spring over to the new workspace.
  //
  // The long edges run along the bar: "along" is x on a horizontal bar and
  // y on a vertical one, "across" the other axis.
  Rectangle {
    id: indicator
    z: -1

    readonly property real targetCenterX: !root.focusedButton ? 0 : root.vertical
      ? root.focusedButton.y + root.focusedButton.glyphCenterY : root.focusedButton.x + root.focusedButton.glyphCenterX
    readonly property real centerY: !root.focusedButton ? 0 : root.vertical
      ? root.focusedButton.x + root.focusedButton.glyphCenterX : root.focusedButton.y + root.focusedButton.glyphCenterY
    readonly property real thickness: root.focusedButton ? Math.round(Math.min(root.focusedButton.width, root.focusedButton.height) * 0.62) : 0
    readonly property real restWidth: Math.round(thickness * 1.45)

    // Edges (along the bar) are animated independently so the shape can
    // squeeze and stretch.
    property real leftEdge: 0
    property real rightEdge: 0
    property int shownId: -1
    property bool placed: false

    // Animation endpoints, set by moveTo() before each run.
    property real squeezeLeft: 0
    property real squeezeRight: 0
    property real targetLeft: 0
    property real targetRight: 0

    width: root.vertical ? thickness : rightEdge - leftEdge
    height: root.vertical ? rightEdge - leftEdge : thickness
    x: root.vertical ? centerY - thickness / 2 : leftEdge
    y: root.vertical ? leftEdge : centerY - thickness / 2
    radius: thickness / 2
    color: Color.pick("tablet.accent", Color.accent)
    visible: root.focusedButton !== null && placed

    function moveTo() {
      if (!root.focusedButton) return
      var id = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
      targetLeft = targetCenterX - restWidth / 2
      targetRight = targetCenterX + restWidth / 2

      // First placement, or the layout shifted under the same workspace: snap.
      if (!placed || id === shownId) {
        if (switchAnimation.running) return
        leftEdge = targetLeft
        rightEdge = targetRight
        shownId = id
        placed = true
        return
      }

      shownId = id
      switchAnimation.stop()
      var squeeze = (rightEdge - leftEdge) * 0.4
      var movingRight = targetCenterX > (leftEdge + rightEdge) / 2
      squeezeLeft = movingRight ? leftEdge + squeeze : leftEdge
      squeezeRight = movingRight ? rightEdge : rightEdge - squeeze
      switchAnimation.start()
    }

    onTargetCenterXChanged: moveTo()
    onRestWidthChanged: moveTo()
    Connections {
      target: Hyprland
      function onFocusedWorkspaceChanged() { indicator.moveTo() }
    }

    SequentialAnimation {
      id: switchAnimation

      ParallelAnimation {
        NumberAnimation { target: indicator; property: "leftEdge"; to: indicator.squeezeLeft; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: indicator; property: "rightEdge"; to: indicator.squeezeRight; duration: 90; easing.type: Easing.OutQuad }
      }
      ParallelAnimation {
        NumberAnimation { target: indicator; property: "leftEdge"; to: indicator.targetLeft; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        NumberAnimation { target: indicator; property: "rightEdge"; to: indicator.targetRight; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
      }
    }
  }

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      id: repeater
      model: root.workspaceIds()

      WidgetButton {
        id: button
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        // Centre of the digit's ink within this button. Text is centred by
        // line height, which leaves digits sitting 1px high (and a touch
        // right) of the box centre at this font/size; measured on screen.
        readonly property real glyphCenterX: width / 2 + 0.5
        readonly property real glyphCenterY: height / 2 - 1

        bar: root.bar
        text: modelData === 10 ? "0" : String(modelData)
        // The focused workspace keeps its number, in black on the indicator.
        foreground: focused ? "black" : (root.bar ? root.bar.barForeground : Color.foreground)
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() {
          if (root.tabletOn) { if (root.bar) root.bar.run("omarchy menu summon tablet.workspaces") }
          else root.focusWorkspace(modelData)
        }
      }
    }
  }
}

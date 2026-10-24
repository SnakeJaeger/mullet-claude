import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Indicator toggles inside a bar panel (sound, screen, calendar): one chip per
// id in `ids`, in that order. Each chip drives the clock island's own
// indicator instance, which Indicators.qml shares through the desktop bar
// window's `indicatorTiles`, so state and polling stay in one place. On bars
// that don't share them (the tablet bar) the row is empty and hidden.
// Loaded by daa.audio / daa.monitor / daa.clock Panel.qml.
Item {
  id: root

  property var barWindow: null
  property var ids: []
  property color foreground: "white"
  property string fontFamily: ""
  readonly property color accent: Commons.Color.accent

  readonly property var tiles: {
    var all = barWindow && barWindow.indicatorTiles ? barWindow.indicatorTiles : []
    var picked = []
    for (var i = 0; i < ids.length; i++) {
      for (var j = 0; j < all.length; j++) {
        if (all[j].id === ids[i] && all[j].item) picked.push(all[j])
      }
    }
    return picked
  }

  visible: tiles.length > 0
  implicitHeight: visible ? chips.implicitHeight : 0

  Row {
    id: chips
    width: parent.width
    spacing: Style.space(8)

    Repeater {
      model: root.tiles

      Rectangle {
        id: chip
        required property var modelData
        readonly property var indicator: modelData.item
        readonly property bool on: !!indicator && indicator.active === true
        readonly property bool hovered: chipArea.containsMouse

        width: (chips.width - chips.spacing * (root.tiles.length - 1)) / root.tiles.length
        height: chipColumn.implicitHeight + Style.space(16)
        radius: Style.cornerRadius
        color: on ? Util.alpha(root.accent, hovered ? 0.3 : 0.22)
          : Util.alpha(root.foreground, hovered ? 0.1 : 0.04)
        border.width: Style.spacing.hairline
        border.color: on ? Util.alpha(root.accent, 0.45) : Util.alpha(root.foreground, 0.12)

        Behavior on color { ColorAnimation { duration: 120 } }

        Column {
          id: chipColumn
          anchors.centerIn: parent
          width: parent.width - Style.space(8)
          spacing: Style.space(4)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: chip.indicator ? chip.indicator.text : ""
            color: chip.on ? root.accent : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Math.round(Style.font.heading * 1.25)
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: chip.modelData.label
            elide: Text.ElideRight
            color: root.foreground
            opacity: chip.on ? 1 : 0.75
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        MouseArea {
          id: chipArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (chip.indicator) chip.indicator.triggerPress(Qt.LeftButton)
        }
      }
    }
  }
}

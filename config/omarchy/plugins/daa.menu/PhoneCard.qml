import Quickshell
import Quickshell.Io
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Go menu phone card, under the system card: the paired KDE Connect phone's
// name, reach and battery, with Ring / Clipboard / Browse / Settings actions.
// Polls ~/.local/bin/phone-status every 3s while `active` (menu open).
// Without a paired phone it says so and Settings reads "Pair".
Item {
  id: card

  property bool active: false
  property color foreground: "white"
  property color hoverBackground: "transparent"
  property string fontFamily: ""
  property int radius: 0
  readonly property color accent: Commons.Color.pick("tablet.accent", Commons.Color.accent)
  readonly property color low: Commons.Color.urgent

  property var status: null
  readonly property var device: status ? status.device : null
  readonly property bool reachable: !!device && device.reachable === true
  readonly property bool hasBattery: reachable && device.battery !== null && device.battery >= 0

  implicitHeight: Style.space(118)

  Process {
    id: poll
    command: [Quickshell.env("HOME") + "/.local/bin/phone-status"]
    stdout: SplitParser {
      onRead: function(line) {
        try { card.status = JSON.parse(line) } catch (e) {}
      }
    }
  }

  Timer {
    interval: 3000
    repeat: true
    triggeredOnStart: true
    running: card.active
    onTriggered: if (!poll.running) poll.running = true
  }

  Rectangle {
    anchors.fill: parent
    radius: card.radius
    color: "transparent"
    border.width: Style.spacing.hairline
    border.color: Util.alpha(card.foreground, 0.15)
  }

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(10)
    spacing: Style.space(8)

    // Phone              ● Pixel 7
    Item {
      width: parent.width
      height: Style.font.body + Style.space(4)

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: "Phone"
        color: card.foreground
        opacity: 0.58
        font.family: card.fontFamily
        font.pixelSize: Style.font.body
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(6)

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(7)
          height: width
          radius: width / 2
          color: card.reachable ? card.accent : Util.alpha(card.foreground, 0.3)
        }
        Text {
          text: !card.status ? "checking…"
            : !card.device ? "not paired"
            : card.reachable ? card.device.name : card.device.name + " · away"
          color: card.foreground
          elide: Text.ElideRight
          width: Math.min(implicitWidth, Style.space(170))
          font.family: card.fontFamily
          font.pixelSize: Style.font.body
        }
      }
    }

    // Battery  ▬▬▬▬▬▬────  85% 󱐋   (or a pairing hint)
    Item {
      width: parent.width
      height: Style.font.bodySmall + Style.space(2)

      Text {
        visible: !card.hasBattery
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        elide: Text.ElideRight
        text: !card.status ? ""
          : !card.device ? "Tap Pair, then accept on the phone"
          : !card.reachable ? "Not on this network" : "Battery not shared"
        color: card.foreground
        opacity: 0.58
        font.family: card.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: batteryLabel
        visible: card.hasBattery
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(52)
        text: "Battery"
        color: card.foreground
        opacity: 0.58
        font.family: card.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        id: batteryValue
        visible: card.hasBattery
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: card.hasBattery ? card.device.battery + "%" + (card.device.charging === true ? " 󱐋" : "") : ""
        color: card.hasBattery && card.device.battery <= 15 && card.device.charging !== true ? card.low : card.foreground
        font.family: card.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Rectangle {
        visible: card.hasBattery
        anchors.left: batteryLabel.right
        anchors.right: batteryValue.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        height: Style.space(4)
        radius: height / 2
        color: Util.alpha(card.foreground, 0.12)

        Rectangle {
          width: card.hasBattery ? parent.width * Math.max(0, Math.min(1, card.device.battery / 100)) : 0
          height: parent.height
          radius: parent.radius
          color: batteryValue.color === card.low ? card.low : card.accent
          Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
      }
    }

    // 󰂞 Ring   󰅇 Clipboard   󰉋 Browse   󰒓 Settings
    Row {
      width: parent.width

      Repeater {
        model: [
          { icon: "󰂞", label: "Ring", action: "ring", needs: true, close: false },
          { icon: "󰅇", label: "Clipboard", action: "clipboard", needs: true, close: false },
          { icon: "󰉋", label: "Browse", action: "browse", needs: true, close: true },
          { icon: "󰒓", label: card.device ? "Settings" : "Pair", action: "settings", needs: false, close: true }
        ]

        Rectangle {
          id: actionButton
          required property var modelData
          readonly property bool enabled: !modelData.needs || card.reachable
          width: parent.width / 4
          height: actionColumn.implicitHeight + Style.space(8)
          radius: card.radius
          color: enabled && actionArea.containsMouse ? card.hoverBackground : "transparent"
          opacity: enabled ? 1 : 0.35

          Column {
            id: actionColumn
            anchors.centerIn: parent
            spacing: Style.space(2)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: actionButton.modelData.icon
              color: actionArea.containsMouse && actionButton.enabled ? card.accent : card.foreground
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: Math.round(Style.font.heading * 1.1)
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: actionButton.modelData.label
              color: card.foreground
              opacity: 0.8
              font.family: card.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: actionButton.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: card.requested(actionButton.modelData.action, actionButton.modelData.close)
          }
        }
      }
    }
  }

  // Menu.qml runs `phone-status <action>`, closing the menu first when asked.
  signal requested(string action, bool closeMenu)
}

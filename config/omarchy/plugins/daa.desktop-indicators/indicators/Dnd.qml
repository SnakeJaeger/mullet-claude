import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

FlyoutIndicator {
  id: root

  // Looked up until found (and again if it goes away): a one-time binding
  // stayed null when this indicator was created before the service, and the
  // panel chip then did nothing.
  property var notificationService: null

  function resolveService() {
    if (!root.notificationService && root.bar && root.bar.shell)
      root.notificationService = root.bar.shell.firstPartyServiceFor("omarchy.notifications")
    return root.notificationService
  }

  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: !root.notificationService
    onTriggered: root.resolveService()
  }
  readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

  active: dnd
  activeText: "󰂛"
  inactiveText: "󰂛"
  activeTooltipText: "Allow Notifications"
  inactiveTooltipText: "Silence Notifications"

  onPressed: function() {
    var service = root.resolveService()
    if (service) service.setDoNotDisturb(!service.doNotDisturb)
    else Quickshell.execDetached(["omarchy", "toggle", "notification", "silencing"])
  }
}

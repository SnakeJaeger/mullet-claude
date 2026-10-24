import QtQuick
import Quickshell
import qs.Ui

FlyoutIndicator {
  id: root

  // Looked up until found (and again if it goes away): a one-time binding
  // stayed null when this indicator was created before the service, and the
  // panel chip then did nothing.
  property var nightlightService: null

  function resolveService() {
    if (!root.nightlightService && root.bar && root.bar.shell)
      root.nightlightService = root.bar.shell.firstPartyServiceFor("omarchy.nightlight")
    return root.nightlightService
  }

  Timer {
    interval: 1000
    repeat: true
    triggeredOnStart: true
    running: !root.nightlightService
    onTriggered: root.resolveService()
  }

  active: nightlightService ? nightlightService.enabled : false
  activeText: "󰔎"
  inactiveText: "󰔎"
  activeTooltipText: "Day Light"
  inactiveTooltipText: "Night Light"

  function toggle() {
    var service = root.resolveService()
    if (service) service.setNightlight(!root.active)
    else Quickshell.execDetached(["omarchy", "toggle", "nightlight"])
  }

  onPressed: function() { root.toggle() }
}

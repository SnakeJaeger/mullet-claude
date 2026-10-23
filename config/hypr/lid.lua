-- Closing the lid no longer suspends (see ~/.local/bin/lid-battery-guard), so
-- turn the panel off while it's shut and back on when it opens. Omarchy's own
-- lid binds (lock + clamshell) still run alongside these.
local panel = "eDP-1"

hl.bind("switch:on:Lid Switch",  hl.dsp.dpms({ action = "disable", monitor = panel }), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "enable",  monitor = panel }), { locked = true })

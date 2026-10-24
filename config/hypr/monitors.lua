-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
-- Refresh rate follows the power profile (~/.local/bin/power-refresh):
-- "highrr" = 120 Hz on the Yoga OLED, "preferred" = 60 Hz.
local refresh_mode = "preferred"
local hz_file = io.open((os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/power-refresh/hz")
if hz_file then
  if hz_file:read("*l") == "120" then refresh_mode = "highrr" end
  hz_file:close()
end
hl.monitor({ output = "", mode = refresh_mode, position = "auto", scale = omarchy_monitor_scale })

-- Adaptive sync (48-120 Hz) for the less-balanced profile.
local vrr_file = io.open((os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/power-refresh/vrr")
if vrr_file then
  if vrr_file:read("*l") == "1" then hl.config({ misc = { vrr = 1 } }) end
  vrr_file:close()
end

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

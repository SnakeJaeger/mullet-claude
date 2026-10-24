-- Dim the display to 20% while the Omarchy screensaver runs, and bring it
-- back to 80% when it exits. The screensaver opens one window per monitor,
-- so dim on the first one and restore once the last one is gone.

local screensaver_class = "org.omarchy.screensaver"
local screensaver_windows = {} -- address -> true
local count = 0

local function brightness(level)
  -- brightness-step's scale (100% = raw 4054), same as the keys and slider.
  hl.dispatch(hl.dsp.exec_cmd("brightness-step set " .. level .. " --no-osd"))
end

hl.on("window.open", function(window)
  if not window or window.class ~= screensaver_class then return end
  screensaver_windows[window.address] = true
  count = count + 1
  if count == 1 then brightness(20) end
end)

hl.on("window.close", function(window)
  if not window or not screensaver_windows[window.address] then return end
  screensaver_windows[window.address] = nil
  count = count - 1
  if count == 0 then brightness(80) end
end)

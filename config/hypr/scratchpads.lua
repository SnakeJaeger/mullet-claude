-- Retract scratchpads (any special workspace: the Omarchy scratchpad and the
-- dropdowns) when focus moves to a regular window, e.g. by clicking off one,
-- or with SUPER + X.

-- Hiding is a toggle, and a quick double click can arrive before Hyprland has
-- registered the first hide, so the second would toggle the scratchpad back
-- open. Ignore further hides for a moment after one.
local hiding = false

-- After hiding, hand focus to the most recently used window on the regular
-- workspace underneath. Otherwise focus stays on the hidden scratchpad window
-- and Hyprland restores it (re-showing the scratchpad) as soon as a bar panel
-- or menu that took the keyboard closes.
local function focus_regular(monitor)
  local regular = monitor and monitor.active_workspace
  if not regular then return end
  local best
  for _, window in ipairs(hl.get_windows()) do
    if window.workspace and window.workspace.id == regular.id and window.mapped and not window.hidden
      and (not best or window.focus_history_id < best.focus_history_id) then
      best = window
    end
  end
  if best then hl.dispatch(hl.dsp.focus({ window = "address:" .. best.address })) end
end

-- With no regular window to take focus (e.g. an empty workspace), Hyprland's
-- last-focused window stays the hidden scratchpad, and it hands focus back
-- (re-showing the scratchpad) when a bar panel is clicked away. A scratchpad
-- can't sensibly be summoned while a bar panel is up, so any that appears
-- while one is open, or within a moment of it closing, is hidden again.
local PANEL_NS = "omarchy-keyboard-panel"
local panel_open = false
local panel_grace = false

local function toggle_special_named(name)
  hl.dispatch(hl.dsp.workspace.toggle_special((name:gsub("^special:", ""))))
end

local function hide_special(monitor)
  local special = monitor and monitor.active_special_workspace
  if not special or hiding then return end
  hiding = true
  hl.timer(function() hiding = false end, { timeout = 400, type = "oneshot" })
  -- Dropdowns that rise from the bottom slide back down before hiding.
  if not (dropdown_hide and dropdown_hide(special.name)) then
    toggle_special_named(special.name)
  end
  focus_regular(monitor)
end

hl.on("layer.opened", function(layer)
  if layer and layer.namespace == PANEL_NS then panel_open = true end
end)

hl.on("layer.closed", function(layer)
  if not (layer and layer.namespace == PANEL_NS) then return end
  panel_open = false
  panel_grace = true
  hl.timer(function() panel_grace = false end, { timeout = 200, type = "oneshot" })
end)

hl.on("window.active", function(window)
  window = window or hl.get_active_window()
  if not window or not window.workspace then return end
  if window.workspace.special then
    if panel_open or panel_grace then
      -- Checked a moment later (window.active fires before the monitor
      -- reports the special as shown), and only toggled if it really is
      -- showing, so this can never toggle one open.
      local name = window.workspace.name
      hl.timer(function()
        local monitor = hl.get_active_monitor()
        local shown = monitor and monitor.active_special_workspace
        if shown and shown.name == name then toggle_special_named(name) end
      end, { timeout = 30, type = "oneshot" })
    end
    return
  end
  hide_special(window.monitor)
end)

-- Clicking a regular window while a scratchpad is showing doesn't move focus
-- (Hyprland keeps input on the special workspace), so the hook above never
-- fires. Watch left clicks without swallowing them, and hide the scratchpad
-- when the click lands outside all of its windows.
local function xy(v)
  if type(v) ~= "table" then return nil end
  return v.x or v[1], v.y or v[2]
end

local function inside(window, pos)
  local x, y = xy(window.at)
  local w, h = xy(window.size)
  if not (x and y and w and h) then return false end
  return pos.x >= x and pos.x < x + w and pos.y >= y and pos.y < y + h
end

hl.bind("mouse:272", function()
  local pos = hl.get_cursor_pos()
  local monitor = pos and hl.get_monitor_at(pos)
  local special = monitor and monitor.active_special_workspace
  if not special then return end

  for _, window in ipairs(hl.get_windows()) do
    if window.workspace and window.workspace.name == special.name
      and window.mapped and not window.hidden and inside(window, pos) then
      return
    end
  end

  hide_special(monitor)
end, { non_consuming = true })

-- Unbind existing SUPER + X (was: Universal cut)
hl.unbind("SUPER + X")
o.bind("SUPER + X", "Hide scratchpad", function()
  hide_special(hl.get_active_monitor())
end)

-- New windows open on the focused workspace, which is the scratchpad while
-- it's showing. Send them to the regular workspace underneath instead, so
-- they don't get hidden along with the scratchpad. Dropdowns are placed on
-- their special workspace by rule, so leave those alone.
hl.on("window.open", function(window)
  if not window or not window.workspace or not window.workspace.special then return end
  if window.class and window.class:match("^dropdown%.") then return end
  if dropdown_windows and dropdown_windows[window.address] then return end

  local monitor = window.monitor
  local regular = monitor and monitor.active_workspace
  if not regular then return end

  hl.dispatch(hl.dsp.window.move({
    workspace = tostring(regular.id),
    follow = false,
    window = "address:" .. window.address,
  }))
  hide_special(monitor)
  hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
end)

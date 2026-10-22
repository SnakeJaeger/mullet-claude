-- Tablet mode: folding the screen back flips the "Lenovo Yoga Tablet Mode
-- Control switch". ~/.local/bin/tablet-mode disables the keyboard/touchpad,
-- starts edge-swipe gestures and auto-rotation, and undoes it all on unfold.
local sw = "Lenovo Yoga Tablet Mode Control switch"
local tm = os.getenv("HOME") .. "/.local/bin/tablet-mode"

hl.bind("switch:on:" .. sw,  hl.dsp.exec_cmd(tm .. " on"),  { locked = true })
hl.bind("switch:off:" .. sw, hl.dsp.exec_cmd(tm .. " off"), { locked = true })

-- Keep finger and pen input on the built-in panel.
hl.config({
  input = {
    touchdevice = { output = "eDP-1" },
    tablet = { output = "eDP-1" },
  },
})

-- After a reload or login, make sure the panel starts upright and the
-- keyboard/touchpad are enabled; the switch re-fires "on" if still folded.
hl.on("hyprland.start", function()
  hl.exec_cmd(tm .. " off force")
end)

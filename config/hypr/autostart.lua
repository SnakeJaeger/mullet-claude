-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Refresh rate follows the power profile (60 Hz saver/balanced, 120 Hz
-- less-balanced/performance).
o.launch_on_start("power-refresh watch")

-- Never start in brightness boost (raw 4095, see ~/.local/bin/brightness-step):
-- the kernel restores the last level, so cap it at 100% on login.
o.launch_on_start([[bash -c '(( $(brightness-step get) > 100 )) && brightness-step set 100 --no-osd']])

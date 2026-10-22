from gi import require_version

require_version("Nautilus", "4.1")
require_version("Gtk", "4.0")

from gi.repository import GLib, GObject, Gtk, Nautilus


# Backspace goes back a folder, like Alt+Left. The controller runs in the
# bubble phase, so text fields (rename, search, path bar) see the key first
# and still delete characters.
def _go_back(window, _args):
    focus = window.get_focus()
    if focus is None:
        return False
    return focus.activate_action("slot.back", None)


def _add_shortcut(window):
    if getattr(window, "_backspace_back", False):
        return
    window._backspace_back = True
    controller = Gtk.ShortcutController()
    controller.set_propagation_phase(Gtk.PropagationPhase.BUBBLE)
    controller.add_shortcut(Gtk.Shortcut.new(
        Gtk.ShortcutTrigger.parse_string("BackSpace"),
        Gtk.CallbackAction.new(_go_back),
    ))
    window.add_controller(controller)


def _hook_app():
    app = Gtk.Application.get_default()
    if app is None:
        return True  # not up yet, retry
    for window in app.get_windows():
        _add_shortcut(window)
    app.connect("window-added", lambda _app, window: _add_shortcut(window))
    return False


GLib.idle_add(_hook_app)


class BackspaceBack(GObject.GObject, Nautilus.MenuProvider):
    pass

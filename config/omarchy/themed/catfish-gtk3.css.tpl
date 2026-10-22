/* GTK3 theme for Catfish alone (the SUPER+D search dropdown), generated from
   the current Omarchy theme and dressed like Dolphin: one flat background,
   hairline dividers, slightly lighter fields and buttons, accent selection
   with dark text. Linked as ~/.local/share/themes/Omarchy-Catfish/gtk-3.0/
   gtk.css; the dropdown launches Catfish with GTK_THEME=Omarchy-Catfish. */

@import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");

window.background,
.background,
paned > separator,
headerbar,
.titlebar,
.sidebar,
.sidebar .view,
treeview.view,
scrolledwindow,
viewport {
  background-color: {{ background }};
  background-image: none;
  color: {{ foreground }};
  box-shadow: none;
}
headerbar,
.titlebar {
  border-bottom: 1px solid {{ lighter_background }};
}
.sidebar {
  border-right: 1px solid {{ lighter_background }};
}
treeview.view header button {
  background: {{ background }};
  color: {{ dark_foreground }};
  border-color: {{ lighter_background }};
}
entry,
button,
combobox button {
  background-color: {{ lighter_background }};
  background-image: none;
  color: {{ foreground }};
  border-color: {{ selection }};
  box-shadow: none;
  text-shadow: none;
}
button:hover {
  background-color: {{ selection }};
}
entry:focus {
  border-color: {{ accent }};
  box-shadow: inset 0 0 0 1px {{ accent }};
}
.view:selected,
treeview.view:selected,
.sidebar row:selected,
.sidebar .view:selected {
  background-color: {{ accent }};
  color: {{ background }};
}
radio:checked,
check:checked {
  background-color: {{ accent }};
  background-image: none;
  border-color: {{ accent }};
  color: {{ background }};
}
.floating-bar {
  background-color: {{ dark_background }};
  color: {{ dark_foreground }};
  border-color: {{ lighter_background }};
}
label.dim-label,
.dim-label {
  color: {{ dark_foreground }};
}
paned > separator {
  background-color: {{ lighter_background }};
  background-image: none;
  min-width: 1px;
}

/* Sidebar and header a shade darker than the results, like Nautilus. */
headerbar,
.titlebar,
.sidebar,
.sidebar .view {
  background-color: {{ dark_background }};
}

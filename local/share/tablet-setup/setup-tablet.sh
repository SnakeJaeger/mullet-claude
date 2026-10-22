#!/bin/bash
# One-time setup for using the Yoga 9 2-in-1 as a tablet. Run it in a terminal
# (not as root): it asks for your sudo password where needed.
set -e

echo "==> Apps from the Arch repos"
#   rnote      - pen-first drawing / sketching / note canvas
#   krita      - full painting app, good Wacom pressure support
#   xournalpp  - write on PDFs with the pen (annotate, sign, fill in)
#   komikku    - touch-first comic / manga reader for local CBZ/CBR/PDF
#   foliate    - touch-friendly EPUB reader
#   papers     - GNOME's touch-friendly PDF viewer (made the default for PDFs below)
#   iio-sensor-proxy - exposes the rotation sensor (once the sensor hub works)
#   libinput-tools, evtest - input debugging
omarchy pkg add rnote krita xournalpp komikku foliate papers iio-sensor-proxy libinput-tools evtest

echo "==> Open PDFs and comic archives in the touch apps"
xdg-mime default org.gnome.Papers.desktop application/pdf
xdg-mime default info.febvre.Komikku.desktop application/vnd.comicbook+zip application/vnd.comicbook-rar application/x-cbz application/x-cbr

echo "==> Apps from the AUR"
#   wvkbd - lightweight on-screen keyboard (layer-shell, works with Hyprland)
#   lisgd - edge-swipe gestures on the touchscreen
omarchy pkg aur add wvkbd lisgd

echo "==> Let your user read touch events (needed by lisgd gestures)"
sudo usermod -aG input "$USER"

echo "==> Rotation sensor: try Lenovo-signed sensor hub firmware"
# The kernel loads Intel's generic ish_ptl.bin, which this Lenovo board
# rejects ("ISH loader: cmd 2 failed"). linux-firmware has no build for the
# 83SE, but it does ship Lenovo-signed Panther Lake builds for other models.
# Installing one under the Lenovo vendor-wide name makes the kernel try it
# first. It lives only in /usr/lib/firmware/updates; delete that file to undo.
src=/usr/lib/firmware/intel/ish/ish_ptl_53c4ffad_75d6ebe2.bin.zst
sudo install -Dm644 "$src" /usr/lib/firmware/updates/intel/ish/ish_ptl_53c4ffad.bin.zst
sudo modprobe -r intel_ish_ipc 2>/dev/null || true
sudo modprobe intel_ish_ipc
sleep 3
echo "--- sensor hub log:"
sudo dmesg | grep -i 'ish' | tail -6
echo "--- iio devices:"
ls /sys/bus/iio/devices/ 2>/dev/null || echo "(none yet)"

echo
echo "Done. Log out and back in (or reboot) so the input group applies."

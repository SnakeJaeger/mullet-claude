#!/bin/bash
# Install the Yoga 9 14IPH11 (83SE) ISH firmware extracted from the Windows
# Lenovo ISH extension driver (PTL_ishS_SI.bin, ISH 5.8.1.7779).
# Undo: sudo rm /usr/lib/firmware/updates/intel/ish/ish_ptl_53c4ffad*.bin.zst
set -euo pipefail

# Usage: install-ish-yoga-fw.sh [path/to/PTL_ishS_SI.bin]
# Default: the Windows partition mounted at /mnt/win. Extract your own copy;
# don't redistribute the blob.
src=${1:-/mnt/win/Windows/System32/DriverStore/FileRepository/ishheciextensiontemplate.inf_amd64_d6b825dfe55b5d23/FwImage/0004/PTL_ishS_SI.bin}
dest=/usr/lib/firmware/updates/intel/ish

echo "6150242c19bbd32ef5b6b7c569203df9  $src" | md5sum -c -

mkdir -p "$dest"
# 53c4ffad = crc32("LENOVO"), a5d6ef13 = crc32("83SE"); the vendor-only name
# replaces the X1 Carbon experiment as a fallback.
zstd -q -f -19 "$src" -o "$dest/ish_ptl_53c4ffad_a5d6ef13.bin.zst"
cp -f "$dest/ish_ptl_53c4ffad_a5d6ef13.bin.zst" "$dest/ish_ptl_53c4ffad.bin.zst"
ls -la "$dest"
echo "Done. Reboot (hot reload of intel_ish_ipc failed last time)."

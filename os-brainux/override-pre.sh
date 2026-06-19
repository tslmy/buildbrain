#!/bin/bash

set -uex -o pipefail

SRC=$1
DST=$2

install -g root -o root -m 0644 $SRC/lib/systemd/system/boot.mount $DST/lib/systemd/system/boot.mount
install -g root -o root -m 0644 $SRC/lib/systemd/system/ethernet_gadget.service $DST/lib/systemd/system/ethernet_gadget.service
install -g root -o root -m 0755 $SRC/usr/bin/enable_ethernet_gadget $DST/usr/bin/enable_ethernet_gadget

# keyoverlay systemd unit and default config must be present before the chroot
# runs `systemctl enable keyoverlay` in setup_brainux.sh.
install -g root -o root -m 0644 -D $SRC/lib/systemd/system/keyoverlay.service \
    $DST/lib/systemd/system/keyoverlay.service
install -g root -o root -m 0644 -D $SRC/etc/default/keyoverlay \
    $DST/etc/default/keyoverlay

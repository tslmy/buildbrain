#!/bin/bash

set -uex -o pipefail

SRC=$1
DST=$2

install -g root -o root -m 0644 $SRC/etc/motd $DST/etc/motd
install -g root -o root -m 0440 $SRC/etc/sudoers $DST/etc/sudoers

install -g root -o root -m 0644 $SRC/etc/X11/xorg.conf $DST/etc/X11/xorg.conf
install -g root -o root -m 0644 $SRC/etc/X11/Xsession.d/96calibrate $DST/etc/X11/Xsession.d/96calibrate

install -g root -o root -m 0644 -D $SRC/etc/xdg/weston/weston.ini $DST/etc/xdg/weston/weston.ini

install -g 1000 -o 1000 -m 0644 $SRC/home/user/.xprofile $DST/home/user/.xprofile
install -d -o 1000 -g 1000 -m 0755 $DST/home/user/.config/fcitx
install -g 1000 -o 1000 -m 0644 $SRC/home/user/.config/fcitx/profile $DST/home/user/.config/fcitx/profile
install -d -o 1000 -g 1000 -m 0755 $DST/home/user/lxterminal
install -g 1000 -o 1000 -m 0644 $SRC/home/user/lxterminal/lxterminal.conf $DST/home/user/lxterminal/lxterminal.conf
install -g root -o root -m 0644 -D $SRC/etc/jwm/system.jwmrc $DST/etc/jwm/system.jwmrc

# keyoverlay binary: extracted from the .deb built by `make docker-brainux-keyoverlay`.
# The service unit and default config are installed by override-pre.sh so they
# exist before setup_brainux.sh runs `systemctl enable keyoverlay`.
if [ -f "$SRC/keyoverlay_armhf.deb" ]; then
    TMPDIR=$(mktemp -d)
    dpkg-deb --extract "$SRC/keyoverlay_armhf.deb" "$TMPDIR"
    install -g root -o root -m 0755 -D "$TMPDIR/usr/bin/keyoverlay" \
        "$DST/usr/bin/keyoverlay"
    rm -rf "$TMPDIR"
fi

#!/bin/bash
# Start the systemd-managed Quickshell bar in the current graphical session.

if ! command -v qs &> /dev/null; then
  if [ "${XDG_SESSION_TYPE}" = "x11" ]; then
    ~/bin/desktop/polybar-start.sh
  fi
  exit 0
fi

if [ "${XDG_SESSION_TYPE}" = "x11" ]; then
  systemctl --user unset-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE
  systemctl --user set-environment QT_QPA_PLATFORM=xcb
else
  systemctl --user set-environment QT_QPA_PLATFORM=wayland
fi
systemctl --user import-environment DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE I3SOCK
if [ "$(hostname)" = "desktop" ]; then
  systemctl --user set-environment QUICKSHELL_BAR_SCREEN=DP-2
else
  systemctl --user unset-environment QUICKSHELL_BAR_SCREEN
fi
systemctl --user restart quickshell-bar.service

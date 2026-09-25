#!/bin/bash
# Start the systemd-managed Quickshell bar on the current Wayland session.

systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE
systemctl --user restart quickshell-bar.service

#! /bin/bash

# A script to make creating i3wm window actions easier.

info=$(xprop)
title=$(echo "$info" | grep "WM_NAME(STRING)" | cut -d "\"" -f2 | cut -d "\"" -f1)
class=$(echo "$info" | grep "WM_CLASS(STRING)" | cut -d "\"" -f2 | cut -d "\"" -f1)
echo for_window [class=\"$class\" title=\"$title\"]

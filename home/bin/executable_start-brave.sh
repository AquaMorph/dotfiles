#!/bin/bash
# Restore Brave and place its windows after they finish opening.

preferences="$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences"

function enable_session_restore {
  if [ ! -f "$preferences" ] || ! command -v jq &> /dev/null; then
    return
  fi

  temp_file="$(mktemp "${preferences}.XXXXXX")"
  if jq '.session.restore_on_startup = 1 | .profile.exit_type = "Normal"' \
    "$preferences" > "$temp_file"; then
    mv "$temp_file" "$preferences"
  else
    rm -f "$temp_file"
  fi
}

enable_session_restore

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  brave-browser --restore-last-session &

  # Signal starts after Brave and can steal focus while its window is mapping.
  # Wait for both startup windows, then make Brave the final focused window.
  for _ in {1..80}; do
    sleep 0.25
    if hyprctl clients -j | jq -e '
      any(.[]; .class == "brave-browser") and
      any(.[]; .class == "org.signal.Signal")
    ' > /dev/null; then
      sleep 0.5
      break
    fi
  done
  hyprctl eval \
    'hl.dispatch(hl.dsp.focus({ workspace = "1" }))' > /dev/null
  exit 0
fi

i3-msg 'workspace 9; append_layout ~/.config/i3/brave-workspace-9.json; workspace 5'
brave-browser --restore-last-session &

# Brave creates restored windows asynchronously and after startup focus has moved.
for _ in {1..20}; do
  sleep 0.5
  i3-msg '[class="^Brave-browser$" workspace="^(?!9$).*"] move to workspace 5' \
    > /dev/null
done

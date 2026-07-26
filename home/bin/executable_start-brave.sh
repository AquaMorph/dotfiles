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
i3-msg 'workspace 9; append_layout ~/.config/i3/brave-workspace-9.json; workspace 5'
brave-browser --restore-last-session &

# Brave creates restored windows asynchronously and after startup focus has moved.
for _ in {1..20}; do
  sleep 0.5
  i3-msg '[class="^Brave-browser$" workspace="^(?!9$).*"] move to workspace 5' \
    > /dev/null
done

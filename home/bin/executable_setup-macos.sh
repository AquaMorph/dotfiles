#!/bin/bash
# Apply curated macOS preferences without copying machine-specific state.

set -euo pipefail

function usage {
  echo "Usage: ${0##*/} [--dry-run]"
  echo "Apply macOS preferences for the current user. Do not run with sudo."
}

dry_run=false
case "${1:-}" in
  --dry-run) dry_run=true ;;
  --help|-h) usage; exit 0 ;;
  "") ;;
  *) usage >&2; exit 1 ;;
esac
if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script only supports macOS." >&2
  exit 1
fi
if [[ "$EUID" -eq 0 ]]; then
  echo "Run this script as your normal user, not with sudo." >&2
  exit 1
fi

function write_preference {
  if [[ "$dry_run" == true ]]; then
    printf '%q ' defaults write "$@"
    printf '\n'
  elif ! defaults write "$@"; then
    echo "Could not write preference: $1 $2" >&2
    exit 1
  fi
}

# Existing preferences observed on this Mac. This is not a full defaults export:
# macOS also stores stock values, histories, and hardware-specific state there.

# Use dark appearance and automatically hide the Dock.
write_preference NSGlobalDomain AppleInterfaceStyle -string Dark
write_preference com.apple.dock autohide -bool true

# Use traditional scrolling and disable swipe-based back/forward navigation.
write_preference NSGlobalDomain com.apple.swipescrolldirection -bool false
write_preference NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false

# Remove the gaps around tiled windows (macOS Sequoia and later).
write_preference com.apple.WindowManager EnableTiledWindowMargins -bool false

if [[ "$dry_run" == false ]]; then
  echo "Preferences saved. Log out and back in if changes are not visible."
fi

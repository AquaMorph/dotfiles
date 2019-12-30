# Program version number comparison
function versionGreater() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

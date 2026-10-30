# Dotfiles

A collection of config files and scripts for Fedora GNU/Linux and macOS.

## Linux installation

```bash
chezmoi init --apply git@github.com:AquaMorph/dotfiles.git
```

## macOS installation

1. Install the Xcode Command Line Tools with `xcode-select --install`, then
   install [Homebrew](https://brew.sh/) and follow its `brew shellenv`
   instructions.

2. Download the dotfiles without applying them, then install dependencies:

   ```bash
   brew install chezmoi
   chezmoi init git@github.com:AquaMorph/dotfiles.git
   brew bundle --file="$(chezmoi source-path ~/.brewfile)"
   ```

3. Restore your password store to `~/.password-store` and import its GPG private
   key from a secure backup before applying the dotfiles:

   ```bash
   gpg --import /path/to/private-key-backup.asc
   ```

   If the store is kept in Git, clone it to `~/.password-store` using your
   password-store repository URL. Verify that all required secrets can be
   decrypted without printing their values:

   ```bash
   pass show self-host/token/audible-activation-bytes >/dev/null
   pass show self-host/token/aquaai >/dev/null
   pass show self-host/token/todoist >/dev/null
   ```

   `settings.conf` is rendered using `pass`, so applying it requires these
   entries and the matching private key. Never commit keys or plaintext tokens.

4. Review and apply the dotfiles, then open a new terminal:

   ```bash
   chezmoi diff
   chezmoi apply
   ```

   Linux-only configuration and scripts are automatically ignored on macOS.

To install newly added macOS dependencies later:

```bash
brew bundle --file="$(chezmoi source-path ~/.brewfile)"
```

### System preferences

Close System Settings, then review and run the optional setup script as your
normal user (not with `sudo`):

```bash
~/bin/setup-macos.sh --dry-run
~/bin/setup-macos.sh
```

It enables dark mode and Dock auto-hide, disables natural scrolling and
swipe-to-navigate, and removes window-tiling margins (macOS Sequoia and later).
Animation settings and machine-specific state, such as Dock contents and
monitor/Spaces layouts, are left unchanged.

The script is safe to rerun but does not back up previous values or run
automatically during `chezmoi apply`. Log out and back in if changes are not
visible.

### Window focus

Hover focus is disabled in AeroSpace. Leave AutoRaise stopped so moving the
pointer does not focus or raise windows:

```bash
brew services stop dimentium/autoraise/autoraise
```

Hammerspoon's `~/.hammerspoon/clickthrough.lua` focuses inactive windows on
mouse-down before passing through the original click, so the same click can
activate the clicked control. This is a workaround, not a native macOS setting;
some apps may still consume the first click. Modified clicks are left unchanged.
Use **Windows → Toggle single-click window activation** to disable it if an app
misbehaves. Hammerspoon needs Accessibility access and must be running.

Optional AutoRaise settings remain in `~/.config/AutoRaise/config`.

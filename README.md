# Dotfiles

A collection of config files and scripts for Fedora GNU/Linux and macOS.

## Linux installation

```bash
chezmoi init --apply git@github.com:AquaMorph/dotfiles.git
```

## macOS installation

1. Install the Xcode Command Line Tools with `xcode-select --install`, then
   install [Homebrew](https://brew.sh/) and follow its `brew shellenv`
   instructions. Its default prefix is `/opt/homebrew` on Apple Silicon and
   `/usr/local` on Intel Macs.

2. Download the dotfiles without applying them, then install dependencies:

   ```bash
   brew install chezmoi
   chezmoi init git@github.com:AquaMorph/dotfiles.git
    brew bundle --file="$(chezmoi source-path ~/.brewfile)"
   ```

    The Brewfile includes chezmoi, Git, Emacs, Python, jq, pass, GnuPG, Brave Browser,
    Alacritty, and Inconsolata. FFmpeg and Ollama are optional; install them separately
    if needed.

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

   The generated `~/.config/settings.conf` is private (mode `0600`) and its
   values are shell-quoted. Linux-only configuration and scripts are ignored on
   macOS; shared shell, Git, and terminal configuration remains managed.

To install newly added macOS dependencies later:

```bash
brew bundle --file="$(chezmoi source-path ~/.brewfile)"
```

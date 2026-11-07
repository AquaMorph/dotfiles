# Scripts

## AquaAI

AquaAI is bash script that interacts with OpenAI and Ollama APIs to enable terminal based interaction with LLMs.

## connect-nas.sh

Connect to long storage NAS.

## convert-mp4-to-resolve.sh

Converts mp4 video files to a video format where the audio works with the linux version of Davinci Resolve.

## frc-photo-checklist.py

Python script to generate a Todoist checklist for taking photos at an FRC event.

```sh
python frc-photo-checklist.py [Event Key]
```

## get-mouse-battery.sh

Prints out the battery percentage of a mouse and if it is charging.

## openai-usage.sh

Shows the remaining 5-hour and weekly ChatGPT Codex allowances using the current
OpenCode or Codex CLI login. Run `openai-usage --watch` to refresh every minute,
or `openai-usage --json` for machine-readable output.

## opencode-sync-models.py

Add models from AquaAI's `/v1/models` endpoint to the chezmoi OpenCode source template:

```sh
~/bin/opencode-sync-models.py --dry-run
~/bin/opencode-sync-models.py
```

Uses the provider's configured endpoint, API key, and headers. Supports
`{env:VARIABLE}` substitutions and falls back to the provider's `env` variables
or `AQUAAI_KEY` when no API key is configured. No additional Python packages
are required. Requires `chezmoi` and access to the template's password manager.
The template is rendered only in memory for the API request; rendered credentials
are never written back. Existing template value expressions are preserved.

Existing aliases, model overrides, disabled models, and unrelated settings are
preserved. Missing models are added; old models are never removed. The model
endpoint does not reliably describe tool support or context limits, so add
overrides manually when necessary. The command is manual, not a background job.

Use `--provider ID` or `--template PATH` to override the defaults. The default
template is located with `chezmoi source-path ~/.config/opencode/opencode.json`
(respecting `XDG_CONFIG_HOME`). Supports JSON with unquoted chezmoi template
value expressions, as used by this repository's API key. JSONC, template control
blocks, expressions inside strings, and templated model definitions are not
supported. Writes are atomic and preserve file permissions.

This updates the source template only, never the active config. Review the diff,
then run `chezmoi apply ~/.config/opencode/opencode.json` when ready to use the
new models. OpenCode reloads applied config changes automatically.

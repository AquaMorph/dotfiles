# AquaAI model discovery

Local OpenCode V2 server plugin. Fetches the configured provider's `/models`
endpoint and LiteLLM `/model/info` at startup and every five minutes, without
rewriting the configuration. A `/v1` suffix is removed for the model-info request;
other endpoint path prefixes are preserved.
Requires the OpenCode 2.2.6 plugin API.

Plugin setup preloads cached inventories so the first model lookup can use the
matching cache as soon as the provider is registered, without a gateway request.
Background discovery starts after setup and retries every second until the configured
provider is registered. Models are added through a model transform, and alias
deduplication also checks the fully resolved model snapshot because OpenCode's
config overrides can run after plugin source transforms. Changes to those aliases
invalidate the discovered models even when the endpoint inventory is unchanged.

The global config loads `./plugins/aquaai-models` with these options:

- `provider`: provider ID (default `AquaAI`).
- `refreshIntervalMs`: refresh interval, at least 1000 ms (default 300000).
- `apiKeyEnv`: fallback API-key environment variable (default `AQUAAI_KEY`).

Keep the endpoint and API key in the provider config. The plugin reads its
resolved `settings.apiKey`, falling back to the `apiKeyEnv` environment variable,
and includes configured provider headers. It does not log credentials or
endpoint response bodies. It does not resolve OAuth credentials.

Configured models always win and remain available, including aliases whose
`modelID` differs from their config key. Other models follow the latest successful
inventory, including removals. Failed requests preserve the previous inventory;
OpenCode's plugin storage caches model IDs, token limits, and vision flags across launches,
scoped to endpoint and credentials. Old ID-only caches remain supported. A first
launch offline has only the configured models.

LiteLLM model information is matched by `model_name` and overrides discovered
catalog/profile limits, but never explicit model configurations. Positive integer
`max_input_tokens` and `max_output_tokens` supply input and output limits. Since
their sum does not establish a shared context window, the input maximum is also
used as a conservative context budget. `max_tokens` is not treated as a total
context limit. Multiple deployments with the same name use the smallest reported
limits. Output and input limits are capped to the context budget.

An explicit boolean `model_info.supports_vision` adds or removes `image` from
the discovered model's input types without changing other capabilities. When
deployments share a name, any explicit `false` wins. Missing or invalid flags
leave catalog/profile capabilities or fallback defaults unchanged.

If `/model/info` is unauthorized, missing or malformed, discovery continues using
cached metadata or catalog defaults and logs a credential-free warning. Successful
metadata changes trigger a reload even when model IDs have not changed. Raw
LiteLLM entries (which may contain credentials) are never cached.

Unique exact model-ID matches in other provider catalogs supply names,
capabilities, and token limits. Gateway IDs prefixed with `chatgpt/` also match
the unprefixed ID in the OpenAI source catalog (even when that provider is
inactive but still present in source records). If catalog matches are absent or ambiguous, built-in
profiles for `chatgpt/gpt-6.1-sol` and `chatgpt/gpt-6-luna` provide the chat type,
tool and image support, 200000-token context, and 32000-token output limit.
Configured overrides still win. The gateway ID is kept for requests.
Routing, pricing, variants, and request settings
are not copied: they may differ on this gateway. Without metadata, unknown or
ambiguous models use text-only input, no tools, a 32768-token context, and a
4096-token output limit.
Add provider model overrides for correct limits and capabilities, for example:

```json
"models": {
  "my-model": {
    "capabilities": { "tools": true, "input": ["text"], "output": ["text"] },
    "limit": { "context": 131072, "output": 8192 }
  }
}
```

Apply the plugin directory and install its dependencies before applying the
config:

```sh
chezmoi apply ~/.config/opencode/plugins/aquaai-models
npm install --prefix ~/.config/opencode/plugins/aquaai-models --omit=dev --package-lock=false
chezmoi apply ~/.config/opencode/opencode.json
```

OpenCode watches the configuration. Use `/reload` if needed, then `/models` to
inspect the discovered inventory. The old `opencode-sync-models.py` script is
not needed for discovery; running it would pin discovered models in the config.

Run dependency-free unit tests from this directory with `npm test`.

## Home Assistant automatic installation

Copy `ha-startup.sh` to `opencode/startup.d/10-aquaai-models.sh` in your Home
Assistant configuration folder, replacing the earlier pinned installer. Enable
Startup hooks and third-party plugins in the app, keep `AQUAAI_API_KEY` in its
Environment variables, and configure the plugin package as
`/data/plugins/aquaai-models` with `provider: AquaAI` and
`apiKeyEnv: AQUAAI_API_KEY`.

At each app startup the hook resolves the latest `AquaMorph/dotfiles` `master`
commit, downloads all plugin files from that same revision, installs dependencies
with npm lifecycle scripts disabled, and runs syntax checks and unit tests before
replacing the installation. Unchanged installations are reused. Failed downloads,
installs or checks retain the previous installation when available. The app log
reports the installed commit. The hook itself is not automatically updated.

This deliberately trusts future commits on `master`: the plugin runs as root in
the app. Only pushed commits are available; local repository edits are not fetched.
Restart the app after publishing an update to install it.

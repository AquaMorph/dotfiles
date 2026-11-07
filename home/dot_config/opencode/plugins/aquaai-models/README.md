# AquaAI model discovery

Local OpenCode V2 server plugin. Fetches the configured provider's `/models`
endpoint at startup and every five minutes, without rewriting the configuration.
Requires the OpenCode 2.2.6 plugin API.

Discovery starts after plugin setup and retries every second until the configured
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
OpenCode's plugin storage caches model IDs across launches, scoped to endpoint
and credentials. A first launch offline has only the configured models.

Unique exact model-ID matches in other provider catalogs supply names,
capabilities, and token limits. Gateway IDs prefixed with `chatgpt/` also match
the unprefixed ID in the OpenAI source catalog (even when that provider is
inactive but still present in source records). If OpenAI is absent, built-in
profiles for `chatgpt/gpt-6.1-sol` and `chatgpt/gpt-6-luna` provide the chat type,
tool and image support, 200000-token context, and 32000-token output limit.
Configured overrides still win. The gateway ID is kept for requests.
Routing, pricing, variants, and request settings
are not copied: they may differ on this gateway. Unknown/ambiguous models use
text-only input, no tools, a 32768-token context, and 4096-token output limit.
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

import { createHash } from "node:crypto"

export function parseInventory(payload) {
  if (!payload || !Array.isArray(payload.data)) {
    throw new Error("Expected a models data array")
  }
  const ids = payload.data.map((model) => {
    if (typeof model?.id !== "string" || !model.id.trim()) {
      throw new Error("Invalid model ID")
    }
    return model.id
  })
  return [...new Set(ids)].sort()
}

export function mergeInventory(record, records, ids, createModel) {
  const models = new Map(record.models)
  const represented = new Set([...models.values()].flatMap((model) => [model.id, model.modelID]))
  const catalog = records.filter((item) => item.provider.id !== record.provider.id)
    .flatMap((item) => [...item.models.values()])

  for (const id of ids) {
    if (represented.has(id)) continue
    const matches = catalog.filter((model) => model.id === id || model.modelID === id)
    const metadata = matches.length === 1 ? matches[0] : undefined
    const model = createModel(record.provider.id, id)
    if (metadata) {
      // Copy descriptive metadata, never another provider's routing or request settings.
      for (const key of ["name", "family", "type", "capabilities", "time", "limit"]) {
        if (metadata[key] !== undefined) model[key] = structuredClone(metadata[key])
      }
    } else {
      model.capabilities = { tools: false, input: ["text"], output: ["text"] }
      model.limit = { context: 32768, output: 4096 }
    }
    models.set(id, model)
  }
  return [...models.values()]
}

function requestSettings(provider, apiKeyEnv) {
  const baseURL = provider.settings?.baseURL
  if (typeof baseURL !== "string") throw new Error("Missing baseURL")
  const url = new URL(baseURL.replace(/\/+$/, "") + "/models")
  if (!["http:", "https:"].includes(url.protocol)) throw new Error("Invalid baseURL")
  const headers = new Headers(provider.headers)
  headers.set("Accept", "application/json")
  const apiKey = provider.settings?.apiKey || process.env[apiKeyEnv]
  if (apiKey) headers.set("Authorization", `Bearer ${apiKey}`)
  // Scope cached inventories to the endpoint and credentials without persisting secrets.
  const key = createHash("sha256").update(JSON.stringify([provider.id, url.href, [...headers]])).digest("hex")
  return { url, headers, key: `inventory/${key}` }
}

export async function setupDiscovery(ctx, createModel, runtime = {}) {
  const fetchModels = runtime.fetch ?? globalThis.fetch
  const schedule = runtime.setTimeout ?? globalThis.setTimeout
  const cancel = runtime.clearTimeout ?? globalThis.clearTimeout
  const warn = runtime.warn ?? ((message) => console.warn(`[aquaai.models] ${message}`))
  const providerID = ctx.options.provider ?? "AquaAI"
  const interval = ctx.options.refreshIntervalMs ?? 300000
  if (typeof providerID !== "string" || !providerID ||
      !Number.isFinite(interval) || interval < 1000) {
    throw new Error("Invalid AquaAI discovery options")
  }

  let provider
  let inventory = null
  let stopped = false
  let timer
  let cacheKey
  let aliases = new Set()
  const controller = new AbortController()
  const transform = (editor) => {
    const record = editor.provider.get(providerID)
    provider = record?.provider
    if (record && inventory !== null) {
      const represented = new Set(editor.list(providerID).flatMap((model) => [model.id, model.modelID]))
      for (const model of mergeInventory(record, editor.provider.list(), inventory, createModel)) {
        if (!record.models.has(model.id) && !represented.has(model.modelID) && !aliases.has(model.id)) {
          editor.update(providerID, model.id, (draft) => Object.assign(draft, model))
        }
      }
    }
  }
  let registered = false
  const refresh = async () => {
    try {
      if (!registered) {
        await ctx.model.transform(transform)
        registered = true
      }
      // Config providers may register after this plugin's setup has completed.
      const snapshot = await ctx.model.list()
      aliases = new Set((snapshot.data ?? []).filter((model) =>
        model.providerID === providerID && model.id !== model.modelID,
      ).map((model) => model.modelID))
      if (!provider) throw new Error("Configured provider is not registered yet")
      const request = requestSettings(provider, ctx.options.apiKeyEnv ?? "AQUAAI_KEY")
      if (cacheKey !== request.key) {
        inventory = null
        cacheKey = request.key
        try {
          const cached = await ctx.storage.get(request.key)
          if (cached !== undefined) inventory = parseInventory({ data: cached.map((id) => ({ id })) })
        } catch {
          warn("Could not load cached inventory; trying the endpoint.")
        }
        await ctx.model.reload()
      }
      const response = await fetchModels(request.url, {
        headers: request.headers,
        redirect: "error",
        signal: AbortSignal.any([controller.signal, AbortSignal.timeout(15000)]),
      })
      if (!response.ok) throw new Error("Model endpoint failed")
      const next = parseInventory(await response.json())
      if (stopped) return
      const previous = inventory
      inventory = next
      if (JSON.stringify(previous) !== JSON.stringify(next)) await ctx.model.reload()
      try {
        await ctx.storage.set(request.key, next)
      } catch {
        warn("Models refreshed, but the inventory could not be cached.")
      }
    } catch {
      if (!stopped) warn("Discovery failed; retaining cached models and configured overrides.")
    } finally {
      if (!stopped) {
        timer = schedule(() => void refresh(), provider ? interval : 1000)
        timer?.unref?.()
      }
    }
  }

  // Let the remaining built-in config plugins register before reading providers.
  timer = schedule(() => void refresh(), 0)
  return () => {
    stopped = true
    controller.abort()
    cancel(timer)
  }
}

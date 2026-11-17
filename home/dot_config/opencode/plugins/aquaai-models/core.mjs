import { createHash } from "node:crypto"

// Disabled providers may be absent from source records. Keep known gateway chat
// profiles usable without requiring per-model entries in the user's config.
const CHATGPT_PROFILES = new Map([
  ["chatgpt/gpt-6.1-sol", { name: "GPT-6.1 Sol" }],
  ["chatgpt/gpt-6-luna", { name: "GPT-6 Luna" }],
].map(([id, metadata]) => [id, {
  ...metadata,
  type: "chat",
  capabilities: { tools: true, input: ["text", "image"], output: ["text"] },
  limit: { context: 200000, output: 32000 },
}]))

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

export function parseModelInfo(payload) {
  if (!payload || !Array.isArray(payload.data)) throw new Error("Invalid model information")
  const limits = {}
  const positive = (value) => Number.isSafeInteger(value) && value > 0
  for (const entry of payload.data) {
    if (typeof entry?.model_name !== "string" || !entry.model_name.trim()) continue
    const info = entry.model_info
    if (!info || typeof info !== "object") continue
    const limit = {}
    if (positive(info.max_input_tokens)) {
      limit.input = info.max_input_tokens
      // Input and output maxima do not establish a shared total context window.
      limit.context = info.max_input_tokens
    }
    if (positive(info.max_output_tokens)) limit.output = info.max_output_tokens
    if (!Object.keys(limit).length) continue
    // Multiple deployments under one name must fit the smallest reported limits.
    const previous = Object.hasOwn(limits, entry.model_name) ? limits[entry.model_name] : {}
    for (const [key, value] of Object.entries(limit)) {
      previous[key] = Math.min(previous[key] ?? value, value)
    }
    Object.defineProperty(limits, entry.model_name, { value: previous, enumerable: true, configurable: true })
  }
  return limits
}

export function mergeInventory(record, records, ids, createModel, limits = {}) {
  const models = new Map(record.models)
  const represented = new Set([...models.values()].flatMap((model) => [model.id, model.modelID]))
  const catalog = records.filter((item) => item.provider.id !== record.provider.id)
    .flatMap((item) => [...item.models.values()])

  for (const id of ids) {
    if (represented.has(id)) continue
    let matches = catalog.filter((model) => model.id === id || model.modelID === id)
    // LiteLLM's ChatGPT route uses OpenAI catalog IDs behind a gateway prefix.
    if (!matches.length && id.startsWith("chatgpt/")) {
      const upstreamID = id.slice("chatgpt/".length)
      matches = catalog.filter((model) => model.providerID === "openai" &&
        (model.id === upstreamID || model.modelID === upstreamID))
    }
    const metadata = matches.length === 1 ? matches[0] : CHATGPT_PROFILES.get(id)
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
    if (Object.hasOwn(limits, id)) {
      model.limit = { ...model.limit, ...limits[id] }
      model.limit.output = Math.min(model.limit.output, model.limit.context)
      if (model.limit.input !== undefined) {
        model.limit.input = Math.min(model.limit.input, model.limit.context)
      }
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
  const infoURL = new URL(url)
  infoURL.pathname = infoURL.pathname.replace(/\/v1\/models\/?$/, "/model/info")
  if (infoURL.pathname === url.pathname) {
    infoURL.pathname = infoURL.pathname.replace(/\/models\/?$/, "/model/info")
  }
  return { url, infoURL, headers, key: `inventory/${key}` }
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
  let limits = {}
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
      for (const model of mergeInventory(record, editor.provider.list(), inventory, createModel, limits)) {
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
      const nextAliases = new Set((snapshot.data ?? []).filter((model) =>
        model.providerID === providerID && model.id !== model.modelID,
      ).map((model) => model.modelID))
      const aliasesChanged = aliases.size !== nextAliases.size ||
        [...aliases].some((id) => !nextAliases.has(id))
      aliases = nextAliases
      if (aliasesChanged) await ctx.model.reload()
      if (!provider) throw new Error("Configured provider is not registered yet")
      const request = requestSettings(provider, ctx.options.apiKeyEnv ?? "AQUAAI_KEY")
      if (cacheKey !== request.key) {
        inventory = null
        limits = {}
        cacheKey = request.key
        try {
          const cached = await ctx.storage.get(request.key)
          if (cached !== undefined) {
            const ids = Array.isArray(cached) ? cached : cached.ids
            inventory = parseInventory({ data: ids.map((id) => ({ id })) })
            if (!Array.isArray(cached)) limits = parseModelInfo(cached.info)
          }
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
      let nextLimits = limits
      try {
        const infoResponse = await fetchModels(request.infoURL, {
          headers: request.headers,
          redirect: "error",
          signal: AbortSignal.any([controller.signal, AbortSignal.timeout(15000)]),
        })
        if (!infoResponse.ok) throw new Error("Model information endpoint failed")
        nextLimits = parseModelInfo(await infoResponse.json())
      } catch {
        if (!stopped) warn("Model information unavailable; retaining cached limits or catalog defaults.")
      }
      if (stopped) return
      const changed = JSON.stringify(inventory) !== JSON.stringify(next) ||
        JSON.stringify(limits) !== JSON.stringify(nextLimits)
      inventory = next
      limits = Object.fromEntries(next.filter((id) => Object.hasOwn(nextLimits, id))
        .map((id) => [id, nextLimits[id]]))
      if (changed) await ctx.model.reload()
      try {
        const info = { data: Object.entries(limits).map(([model_name, limit]) => ({
          model_name,
          model_info: { max_input_tokens: limit.input, max_output_tokens: limit.output },
        })) }
        await ctx.storage.set(request.key, { ids: next, info })
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

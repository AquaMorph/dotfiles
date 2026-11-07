import assert from "node:assert/strict"
import { test } from "node:test"
import { mergeInventory, parseInventory, setupDiscovery } from "./core.mjs"

const createModel = (providerID, id) => ({ providerID, id, modelID: id, name: id })
const record = (id, models = []) => ({
  provider: { id, settings: { baseURL: "https://example.test/v1", apiKey: "test-secret" } },
  models: new Map(models.map((model) => [model.id, model])),
})

test("validates the whole inventory and deduplicates IDs", () => {
  assert.deepEqual(parseInventory({ data: [{ id: "b" }, { id: "a" }, { id: "b" }] }), ["a", "b"])
  assert.deepEqual(parseInventory({ data: [] }), [])
  for (const value of [{}, null, { data: [{}] }, { data: [{ id: " " }] }]) {
    assert.throws(() => parseInventory(value))
  }
})

test("preserves configured aliases/overrides and avoids duplicate upstream IDs", () => {
  const alias = { ...createModel("AquaAI", "sol"), modelID: "chatgpt/sol", limit: { context: 500000 } }
  const source = record("AquaAI", [alias])
  const models = mergeInventory(source, [source], ["chatgpt/sol", "new"], createModel)
  assert.equal(models.length, 2)
  assert.equal(models[0], alias)
  assert.deepEqual(models[1].capabilities, { tools: false, input: ["text"], output: ["text"] })
})

test("copies only safe metadata from an unambiguous exact catalog match", () => {
  const source = record("AquaAI")
  const model = {
    ...createModel("other", "known"), name: "Known model",
    capabilities: { tools: true, input: ["text"], output: ["text"] },
    limit: { context: 100000, output: 10000 }, settings: { secret: "do not copy" },
    package: "wrong-runtime", cost: [{ input: 99 }],
  }
  const catalog = record("other", [model])
  const [matched] = mergeInventory(source, [source, catalog], ["known"], createModel)
  assert.equal(matched.providerID, "AquaAI")
  assert.equal(matched.name, "Known model")
  assert.deepEqual(matched.limit, model.limit)
  assert.notEqual(matched.limit, model.limit)
  assert.equal(matched.settings, undefined)
  assert.equal(matched.package, undefined)
  assert.equal(matched.cost, undefined)
  const [ambiguous] = mergeInventory(source, [catalog, record("third", [model])], ["known"], createModel)
  assert.equal(ambiguous.capabilities.tools, false)
})

test("ChatGPT gateway routes inherit OpenAI metadata without changing routing", () => {
  const source = record("AquaAI")
  const upstream = {
    ...createModel("openai", "gpt-6.1-sol"), name: "GPT-6.1 Sol", type: "chat",
    capabilities: { tools: true, input: ["text", "image"], output: ["text"] },
    limit: { context: 200000, output: 32000 }, settings: { apiKey: "not-for-gateway" },
  }
  const [model] = mergeInventory(source, [source, record("openai", [upstream])],
    ["chatgpt/gpt-6.1-sol"], createModel)
  assert.equal(model.id, "chatgpt/gpt-6.1-sol")
  assert.equal(model.modelID, "chatgpt/gpt-6.1-sol")
  assert.equal(model.providerID, "AquaAI")
  assert.equal(model.name, upstream.name)
  assert.equal(model.type, "chat")
  assert.deepEqual(model.capabilities, upstream.capabilities)
  assert.deepEqual(model.limit, upstream.limit)
  assert.equal(model.settings, undefined)
  const [unknown] = mergeInventory(source, [record("other", [{ ...upstream, providerID: "other" }])],
    ["chatgpt/unknown"], createModel)
  assert.equal(unknown.capabilities.tools, false)
  const exact = { ...upstream, id: "chatgpt/gpt-6.1-sol", name: "Exact gateway match" }
  const [preferred] = mergeInventory(source, [record("openai", [upstream]), record("other", [exact])],
    ["chatgpt/gpt-6.1-sol"], createModel)
  assert.equal(preferred.name, "Exact gateway match")
})

test("known ChatGPT routes are session-selectable without config models or an OpenAI catalog", () => {
  const source = record("AquaAI")
  const models = mergeInventory(source, [source],
    ["chatgpt/gpt-6.1-sol", "chatgpt/gpt-6-luna"], createModel)
  assert.deepEqual(models.map((model) => model.name), ["GPT-6.1 Sol", "GPT-6 Luna"])
  for (const model of models) {
    assert.equal(model.type, "chat")
    assert.equal(model.capabilities.tools, true)
    assert.equal(model.modelID, model.id)
    assert.equal(model.providerID, "AquaAI")
    assert.deepEqual(model.limit, { context: 200000, output: 32000 })
  }
})

function harness({ cached, responses = [] } = {}) {
  const source = record("AquaAI", [createModel("AquaAI", "pinned")])
  let transform
  let current = source
  let scheduled
  let cancelled = false
  let available = true
  const warnings = []
  const requests = []
  const writes = []
  const rebuild = () => {
    current = { ...source, models: new Map(source.models) }
    transform({
      list: () => [...current.models.values()],
      provider: { get: () => available ? source : undefined, list: () => available ? [source] : [] },
      update: (_, id, update) => {
        const draft = createModel("AquaAI", id)
        update(draft)
        current.models.set(id, draft)
      },
    })
  }
  const ctx = {
    options: {},
    model: {
      transform: async (fn) => { transform = fn },
      list: async () => { rebuild(); return { data: [...current.models.values()] } },
      reload: async () => rebuild(),
    },
    storage: { get: async () => cached, set: async (...args) => { writes.push(args) } },
  }
  const runtime = {
    fetch: async (url, options) => {
      requests.push({ url, options })
      const response = responses.shift()
      if (response instanceof Error || response === undefined) throw response ?? new Error("offline")
      return { ok: true, json: async () => response }
    },
    setTimeout: (fn) => { scheduled = fn; return 1 },
    clearTimeout: () => { cancelled = true },
    warn: (message) => warnings.push(message),
  }
  return {
    ctx, runtime, requests, writes, warnings, source,
    ids: () => [...current.models.keys()],
    tick: async () => { scheduled(); await new Promise(setImmediate) },
    cancelled: () => cancelled,
    available: (value) => { available = value },
  }
}

test("refreshes, removes stale discoveries, preserves overrides and caches IDs only", async () => {
  const h = harness({ responses: [{ data: [{ id: "old" }] }, { data: [{ id: "new" }] }, { data: [] }] })
  const cleanup = await setupDiscovery(h.ctx, createModel, h.runtime)
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "old"])
  assert.equal(h.requests[0].url.href, "https://example.test/v1/models")
  assert.equal(h.requests[0].options.headers.get("Authorization"), "Bearer test-secret")
  assert.equal(h.requests[0].options.redirect, "error")
  assert.deepEqual(h.writes[0][1], ["old"])
  assert.ok(!h.writes[0][0].includes("test-secret"))
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "new"])
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned"])
  cleanup()
  assert.equal(h.cancelled(), true)
  assert.equal(h.requests[0].options.signal.aborted, true)
})

test("offline startup uses cache and subsequent malformed responses do not erase it", async () => {
  const h = harness({ cached: ["cached"], responses: [new Error("secret error"), { data: [{}] }] })
  const cleanup = await setupDiscovery(h.ctx, createModel, h.runtime)
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "cached"])
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "cached"])
  assert.equal(h.writes.length, 0)
  assert.ok(!h.warnings.join().includes("secret error"))
  cleanup()
})

test("rejects invalid refresh configuration", async () => {
  const h = harness()
  h.ctx.options.refreshIntervalMs = 0
  await assert.rejects(setupDiscovery(h.ctx, createModel, h.runtime))
})

test("removing a configured alias restores discovery even when inventory is unchanged", async () => {
  const inventory = { data: [{ id: "chatgpt/gpt-6.1-sol" }] }
  const h = harness({ responses: [inventory, inventory] })
  h.source.models.set("sol", {
    ...createModel("AquaAI", "sol"), modelID: "chatgpt/gpt-6.1-sol",
  })
  const cleanup = await setupDiscovery(h.ctx, createModel, h.runtime)
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "sol"])
  h.source.models.delete("sol")
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "chatgpt/gpt-6.1-sol"])
  cleanup()
})

test("retries when config registers the provider after plugin setup", async () => {
  const h = harness({ responses: [{ data: [{ id: "discovered" }] }] })
  h.available(false)
  const cleanup = await setupDiscovery(h.ctx, createModel, h.runtime)
  await h.tick()
  assert.equal(h.requests.length, 0)
  h.available(true)
  await h.tick()
  assert.deepEqual(h.ids(), ["pinned", "discovered"])
  cleanup()
})

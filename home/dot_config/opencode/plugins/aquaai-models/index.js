import { Model, Plugin, Provider } from "@opencode/plugin"
import { setupDiscovery } from "./core.mjs?v=3"

export default Plugin.define({
  id: "aquaai.models",
  setup(ctx) {
    return setupDiscovery(ctx, (providerID, modelID) =>
      Model.Info.default(Provider.ID.make(providerID), Model.ID.make(modelID)),
    )
  },
})

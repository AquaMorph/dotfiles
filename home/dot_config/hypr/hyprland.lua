hl.monitor({
  output = "eDP-1",
  mode = "2256x1504@60",
  position = "auto",
  scale = 1.175,
})

require("env")

require("startup-all")
require("startup-framework")

require("general")

hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
    },
    sensitivity = 0,
  },

  xwayland = {
    force_zero_scaling = true,
  },

  misc = {
    force_default_wallpaper = 0,
  },
})

hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

require("bind-all")
require("bind-framework")

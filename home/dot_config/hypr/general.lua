hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 5,
    border_size = 2,
    col = {
      active_border = {
        colors = { "rgba(e91e63ee)", "rgba(ffcdd2ee)" },
        angle = 45,
      },
      inactive_border = "rgba(0288d1aa)",
    },
    layout = "dwindle",
    allow_tearing = false,
  },

  decoration = {
    rounding = 5,
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
    },
  },

  animations = {
    enabled = true,
  },

  dwindle = {
    preserve_split = true,
    force_split = 2,
  },

  master = {
    orientation = "right",
  },
})

hl.curve("myBezier", {
  type = "bezier",
  points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "default" })

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

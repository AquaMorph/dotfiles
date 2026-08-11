local programs = require("env")

hl.on("hyprland.start", function()
  hl.exec_cmd(programs.browser, { workspace = "1 silent" })
  hl.exec_cmd(programs.terminal, { workspace = "2 silent" })
  hl.exec_cmd("flatpak run org.signal.Signal", { workspace = "10 silent" })
end)

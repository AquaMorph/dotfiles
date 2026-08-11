local main_mod = "SUPER"

hl.on("hyprland.start", function()
  hl.exec_cmd("light -N 1")
end)

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("~/bin/system/backlight-ctl.sh -i"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/bin/system/backlight-ctl.sh -d"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("amixer set Master 3%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("amixer set Master 3%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("amixer set Master toggle"))

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))

hl.bind(main_mod .. " + escape", hl.dsp.exec_cmd("swaylock"))

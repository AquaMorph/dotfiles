-- Focus on mouse-down, before macOS delivers the original click to the app.
-- Never synthesize an extra click: controls that accept first mouse must not fire twice.
local clickthrough = {}
local ax = require("hs.axuielement")
local log = hs.logger.new("clickthrough", "warning")

local function focusClickedWindow(event)
    -- Leave modified clicks (context menus, background links, etc.) unchanged.
    if next(event:getFlags()) then return false end
    local element = ax.systemWideElement():elementAtPosition(event:location())
    if not element then return false end
    local role = element:attributeValue("AXRole")
    if role == "AXMenu" or role == "AXMenuItem" or role == "AXMenuBarItem"
        or role == "AXMenuBar" then return false end

    local windowElement = element:attributeValue("AXWindow")
    if not windowElement and role == "AXWindow" then windowElement = element end
    local window = windowElement and windowElement:asHSWindow()
    if not window or not window:isStandard() then return false end
    local focused = hs.window.focusedWindow()
    if not focused or focused:id() ~= window:id() then window:focus() end
    return false
end

clickthrough.tap = hs.eventtap.new({hs.eventtap.event.types.leftMouseDown}, function(event)
    local ok, err = pcall(focusClickedWindow, event)
    if not ok then log.w(tostring(err)) end
    return false -- Always pass through the original click, including on errors.
end)

function clickthrough.toggle()
    clickthrough.enabled = not clickthrough.enabled
    if clickthrough.enabled then clickthrough.tap:start() else clickthrough.tap:stop() end
end

clickthrough.enabled = true
clickthrough.tap:start()
-- macOS can disable event taps after sleep or a slow accessibility response.
clickthrough.watchdog = hs.timer.doEvery(5, function()
    if clickthrough.enabled and not clickthrough.tap:isEnabled() then
        clickthrough.tap:start()
    end
end)

return clickthrough

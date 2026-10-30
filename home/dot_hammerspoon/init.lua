-- Placement rules inferred from the running windows on this Mac.
require("hs.ipc")

local spaces = require("hs.spaces")
local log = hs.logger.new("placement", "info")
local monitors = {
    main = "CBBC3C70-2EE1-4D28-8B7D-DC03A186F6EB", -- DELL P2715Q (2)
    portrait = "22CE41A6-C177-4B4D-85D3-43337F9566E8", -- DELL P2715Q (1)
    right = "3C0512D4-DAFF-4EE2-8CC8-8EA148E1ECB0", -- T24i-2L
}

-- Desktop numbers are per monitor, excluding native fullscreen Spaces.
-- Frames are fractions of the entire display, including the menu bar area.
local rules = {
    {app = "com.mitchellh.ghostty", monitor = "main", desktop = 1,
        frame = {0, 30 / 1890, 1, 1860 / 1890}},
    {app = "io.robbie.HomeAssistant", monitor = "portrait", desktop = 1,
        frame = {0, 30 / 3360, 1, 1665 / 3360}},
    {app = "org.whispersystems.signal-desktop", monitor = "right", desktop = 2,
        frame = {0, 30 / 1080, 1, 1050 / 1080}},
    -- Match specialized browser windows; general browsing uses the fallback below.
    {app = "com.brave.Browser", title = "YouTube", monitor = "portrait", desktop = 1,
        frame = {0, 1695 / 3360, 1, 1665 / 3360}, singleOccupancy = true},
    -- Other browser windows start on the right; a later YouTube title moves them.
    {app = "com.brave.Browser", monitor = "right", desktop = 1,
        frame = {0, 30 / 1080, 1, 1050 / 1080}},
    -- Steam's library is owned by Steam Helper, not the launcher process.
    {app = "com.valvesoftware.steam", monitor = "right", desktop = 1,
        frame = {267 / 1920, 163 / 1080, 1010 / 1920, 1050 / 1080}},
    {name = "Steam Helper", monitor = "right", desktop = 1,
        frame = {267 / 1920, 163 / 1080, 1010 / 1920, 1050 / 1080}},
}

local applied, pending = {}, {}
local filter

local function spotOccupied(window, rule)
    if not rule.singleOccupancy or not filter then return false end
    for _, other in ipairs(filter:getWindows()) do
        local app, screen = other:application(), other:screen()
        if other:id() ~= window:id() and app and app:bundleID() == rule.app
            and other:isStandard() and not other:isMinimized() and not other:isFullScreen()
            and other:title():find(rule.title, 1, true)
            and screen and screen:getUUID() == monitors[rule.monitor] then
            local desktops = {}
            for _, space in ipairs(spaces.spacesForScreen(screen) or {}) do
                if spaces.spaceType(space) == "user" then table.insert(desktops, space) end
            end
            local current = spaces.windowSpaces(other) or {}
            local bounds, frame, actual = screen:fullFrame(), rule.frame, other:frame()
            if #current == 1 and current[1] == desktops[rule.desktop]
                and math.abs(actual.x - (bounds.x + frame[1] * bounds.w)) < 20
                and math.abs(actual.y - (bounds.y + frame[2] * bounds.h)) < 20
                and math.abs(actual.w - frame[3] * bounds.w) < 20
                and math.abs(actual.h - frame[4] * bounds.h) < 20 then
                return true
            end
        end
    end
    return false
end

local function ruleFor(window)
    local app = window:application()
    if not app or not window:isStandard() or window:isFullScreen()
        or window:isMinimized() then return end
    -- Ignore Steam's small helper/tooltip windows even if exposed as standard.
    if app:name() == "Steam Helper" and window:frame().w < 600 then return end
    for index, rule in ipairs(rules) do
        if ((rule.app and app:bundleID() == rule.app)
            or (rule.name and app:name() == rule.name))
            and (not rule.title or window:title():find(rule.title, 1, true))
            and not spotOccupied(window, rule) then
            return rule, index
        end
    end
end

local function place(window, force)
    local rule, index = ruleFor(window)
    local id = window:id()
    if not rule or not id or (not force and applied[id] == index) then return end
    local screen
    for _, candidate in ipairs(hs.screen.allScreens()) do
        if candidate:getUUID() == monitors[rule.monitor] then screen = candidate; break end
    end
    if not screen then return end -- Leave windows alone when a monitor is unplugged.
    local desktops = {}
    for _, space in ipairs(spaces.spacesForScreen(screen) or {}) do
        if spaces.spaceType(space) == "user" then table.insert(desktops, space) end
    end
    local target = desktops[rule.desktop]
    local current = spaces.windowSpaces(window) or {}
    if not target or #current ~= 1 or spaces.spaceType(current[1]) ~= "user" then return end

    window:moveToScreen(screen, false, true, 0)
    if current[1] ~= target then
        local ok, err = spaces.moveWindowToSpace(window, target)
        if not ok then
            log.w("Desktop placement failed: " .. tostring(err))
            return
        end
    end
    local bounds, frame = screen:fullFrame(), rule.frame
    window:setFrame(hs.geometry.rect(
        bounds.x + frame[1] * bounds.w, bounds.y + frame[2] * bounds.h,
        frame[3] * bounds.w, frame[4] * bounds.h
    ), 0)
    applied[id] = index
end

filter = hs.window.filter.new(true):setOverrideFilter({
    allowRoles = "AXStandardWindow", fullscreen = false,
})

local function restore()
    for _, window in ipairs(filter:getWindows()) do place(window, true) end
end

filter:subscribe({hs.window.filter.windowCreated, hs.window.filter.windowTitleChanged}, function(window)
    local id = window:id()
    if not id then return end
    if pending[id] then pending[id]:stop() end
    -- Wait for apps to finish their own initial resize and browser page loading.
    pending[id] = hs.timer.doAfter(1, function()
        pending[id] = nil
        if window:id() then place(window, false) end
    end)
end)
filter:subscribe(hs.window.filter.windowDestroyed, function(window)
    local id = window:id()
    if id then
        applied[id] = nil
        if pending[id] then pending[id]:stop(); pending[id] = nil end
    end
end)

-- Retain the filter, watchers and menu for the lifetime of the configuration.
windowPlacement = {
    rules = rules,
    restore = restore,
    filter = filter,
    menu = hs.menubar.new(),
    screenWatcher = hs.screen.watcher.new(function()
        hs.timer.doAfter(3, restore)
    end):start(),
}
windowPlacement.menu:setTitle("Windows")
windowPlacement.menu:setMenu({
    {title = "Reapply placement rules", fn = restore},
    {title = "Reload configuration", fn = hs.reload},
    {title = "Open Console", fn = hs.openConsole},
})

hs.autoLaunch(true)
if hs.accessibilityState(true) then hs.timer.doAfter(3, restore) end

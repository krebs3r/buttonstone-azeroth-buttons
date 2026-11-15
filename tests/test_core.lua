--[[ Start-up, settings, strings and slash commands, once per client ]]
local _, ns = ...
local expect = Mock.expect
local passed = 0

local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local function equal(actual, wanted, message)
	assert(actual == wanted, (message or 'value') .. ': wanted ' .. tostring(wanted) .. ', got ' .. tostring(actual))
	passed = passed + 1
end

-- The client
equal(ns.Compat.Look(), expect.look, 'look')
equal(ns.Compat.HasAddonCompartment(), expect.compartment, 'addon compartment')
equal(ns.Compat.Version(), 'dev', 'version of an unpackaged copy')
Mock.metadata.Version = '0.1.0'
equal(ns.Compat.Version(), '0.1.0', 'version of a packaged copy')
Mock.metadata.Version = '@project-version@'

-- Strings
equal(ns.L.HELP_HEADER, expect.locale == 'deDE' and 'Befehle:' or 'Commands:', 'locale')
equal(ns.L.TITLE, 'Buttonstone – Azeroth Buttons', 'a string the locale does not change')
equal(ns.L.NO_SUCH_KEY, 'NO_SUCH_KEY', 'a missing string shows its key')

-- A fresh install
check(ButtonstoneDB == nil, 'no settings before loading')
Mock.fire('ADDON_LOADED', 'SomeOtherAddon')
check(ButtonstoneDB == nil, 'another addon loading leaves the settings alone')
Mock.fire('ADDON_LOADED', 'Buttonstone')
local db = ButtonstoneDB
check(type(db) == 'table' and db == ns.db, 'settings created and shared')
equal(ns.look, expect.look, 'look kept at start-up')
equal(db.schema, ns.SCHEMA, 'schema')
equal(db.launcher.attached, true, 'on the minimap')
equal(db.launcher.angle, 215, 'lower left')
equal(db.panel.columns, 4, 'columns')
equal(db.panel.direction, 'auto', 'direction')
equal(db.panel.size, 100, 'size')
equal(db.panel.uniform, true, 'uniform slots')
equal(db.panel.header, true, 'header')
equal(db.panel.autoClose, true, 'auto-close')
equal(db.compartment, true, 'compartment entry')
check(next(db.excluded) == nil and next(db.blizzard) == nil, 'nothing excluded, no Blizzard button gathered')
check(db.panel ~= ns.defaults.panel and db.excluded ~= ns.defaults.excluded, 'settings are copies, not the defaults')

-- Saved values stay, missing ones are filled, broken ones repaired
local saved = ns.LoadSettings({
	schema = 1,
	panel = { columns = 6, direction = 'up-left', size = 'big', uniform = false },
	launcher = { angle = 400, attached = false, free = { x = 10, y = -20 } },
	excluded = { LibDBIcon10_Bagsmith = true },
	compartment = false,
})
equal(saved.panel.columns, 6, 'kept columns')
equal(saved.panel.direction, 'up-left', 'kept direction')
equal(saved.panel.uniform, false, 'kept a false value')
equal(saved.panel.size, 100, 'repaired a size of the wrong type')
equal(saved.panel.header, true, 'filled a missing value')
equal(saved.launcher.angle, 40, 'wrapped the angle')
equal(saved.launcher.free.x, 10, 'kept the free position')
equal(saved.compartment, false, 'kept the compartment off')
check(saved.excluded.LibDBIcon10_Bagsmith, 'kept an exclusion')

local broken = ns.LoadSettings({
	panel = { columns = 99, direction = 'sideways', size = 33 },
	launcher = 'oops',
	excluded = 'none',
})
equal(broken.panel.columns, 8, 'columns clamped')
equal(broken.panel.size, 60, 'size clamped')
equal(broken.panel.direction, 'auto', 'unknown direction')
equal(broken.launcher.angle, 215, 'launcher rebuilt')
equal(type(broken.excluded), 'table', 'exclusions rebuilt')
equal(ns.LoadSettings({ panel = { columns = 0 / 0 } }).panel.columns, 4, 'NaN replaced')
equal(ns.LoadSettings({ launcher = { free = 'here' } }).launcher.free, nil, 'broken free position dropped')
equal(ns.LoadSettings(nil).panel.columns, 4, 'no settings at all')

-- Slash commands
equal(SLASH_BUTTONSTONE1, '/buttonstone', 'first slash command')
equal(SLASH_BUTTONSTONE2, '/bst', 'second slash command')

Mock.printed = {}
SlashCmdList.BUTTONSTONE('version')
local line = Mock.printed[1] or ''
check(line:find('dev', 1, true) and line:find(ns.L['LOOK_' .. expect.look], 1, true), 'version line: ' .. line)

Mock.printed = {}
SlashCmdList.BUTTONSTONE('')
check(#Mock.printed == 7 and Mock.printed[1]:find(ns.L.HELP_HEADER, 1, true), 'help on a bare command')

Mock.printed = {}
SlashCmdList.BUTTONSTONE('  VERSION  ')
check((Mock.printed[1] or ''):find('dev', 1, true), 'commands ignore case and spaces')

Mock.printed = {}
SlashCmdList.BUTTONSTONE('nonsense')
check((Mock.printed[1] or ''):find(ns.L.HELP_HEADER, 1, true), 'help on an unknown command')

return passed

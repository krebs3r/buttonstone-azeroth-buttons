local addonName, ns = ...
local C, L = ns.Compat, ns.L

--[[ Settings
The defaults are the approved mockup's (docs/PLAN.md, *Mockup defaults*).
Angles are WoW's: 0° to the right, counter-clockwise, as math.atan2 on screen
coordinates gives them, so 215° is the mockup's lower left.
--]]
ns.SCHEMA = 1
ns.defaults = {
	launcher = {
		attached = true,
		angle = 215,
	},
	panel = {
		columns = 4,
		direction = 'auto',
		size = 100,
		uniform = true,
		header = true,
		autoClose = true,
	},
	compartment = true,
	excluded = {},
	blizzard = {},
}

local DIRECTIONS = {
	auto = true,
	['down-left'] = true,
	['down-right'] = true,
	['up-left'] = true,
	['up-right'] = true,
}

-- Each step lifts saved settings from schema n to n + 1. None yet; the table
-- is here so the first change of shape has a place to go.
local migrations = {}

-- Missing keys get the default, and so does a value of the wrong type (or NaN):
-- SavedVariables are a file the player can edit.
local function fill(target, defaults)
	for key, default in pairs(defaults) do
		local value = target[key]
		if type(default) == 'table' then
			if type(value) ~= 'table' then
				value = {}
				target[key] = value
			end
			fill(value, default)
		elseif type(value) ~= type(default) or value ~= value then
			target[key] = default
		end
	end
	return target
end

local function clamp(value, low, high)
	return math.max(low, math.min(high, value))
end

local function sanitize(db)
	local panel, launcher = db.panel, db.launcher
	panel.columns = clamp(math.floor(panel.columns + 0.5), 2, 8)
	panel.size = clamp(math.floor(panel.size / 5 + 0.5) * 5, 60, 160)
	if not DIRECTIONS[panel.direction] then
		panel.direction = ns.defaults.panel.direction
	end
	launcher.angle = launcher.angle % 360
	local free = launcher.free
	if free ~= nil and (type(free) ~= 'table' or type(free.x) ~= 'number' or type(free.y) ~= 'number') then
		launcher.free = nil
	end
	return db
end

function ns.LoadSettings(saved)
	if type(saved) ~= 'table' then
		saved = {}
	end
	local schema = tonumber(saved.schema) or ns.SCHEMA
	while schema < ns.SCHEMA do
		local step = migrations[schema]
		if step then
			step(saved)
		end
		schema = schema + 1
	end
	saved.schema = ns.SCHEMA
	return sanitize(fill(saved, ns.defaults))
end

--[[ Slash commands
/buttonstone and /bst. Later steps add the options and a position reset; for
now they say which build and which look this client gets.
--]]
local function chat(text)
	print('|cffffd200Buttonstone|r ' .. text)
end

local commands = {}

function commands.version()
	chat(L.VERSION:format(C.Version(), L['LOOK_' .. C.Look()]))
end

function commands.help()
	chat(L.HELP_HEADER)
	print('  ' .. L.HELP_VERSION)
	print('  ' .. L.HELP_HELP)
end

SLASH_BUTTONSTONE1 = '/buttonstone'
SLASH_BUTTONSTONE2 = '/bst'
SlashCmdList.BUTTONSTONE = function(input)
	local word = (input or ''):match('^%s*(%S*)'):lower()
	local command = commands[word] or commands.help
	command()
end

--[[ Start-up ]]
local events = CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent', function(self, event, name)
	if event == 'ADDON_LOADED' and name == addonName then
		self:UnregisterEvent('ADDON_LOADED')
		ButtonstoneDB = ns.LoadSettings(ButtonstoneDB)
		ns.db = ButtonstoneDB
		ns.look = C.Look()
	end
end)

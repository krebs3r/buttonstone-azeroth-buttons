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
/buttonstone and /bst alone open the options; with a word they do what the
help lists.
--]]
local function chat(text)
	print('|cffffd200Buttonstone|r ' .. text)
end
ns.Chat = chat

local commands = {}

function commands.version()
	chat(L.VERSION:format(C.Version(), L['LOOK_' .. C.Look()]))
end

function commands.help()
	chat(L.HELP_HEADER)
	for _, key in ipairs({ 'HELP_OPTIONS', 'HELP_LIST', 'HELP_DETACH', 'HELP_ATTACH', 'HELP_RESET', 'HELP_VERSION',
		'HELP_HELP' }) do
		print('  ' .. L[key])
	end
end

function commands.list()
	local records = {}
	for _, record in ipairs(ns.Collector.records) do
		records[#records + 1] = record
	end
	table.sort(records, function(a, b)
		return a.label:lower() < b.label:lower()
	end)
	chat(L.LIST_HEADER:format(#records))
	for _, record in ipairs(records) do
		local note = L['SOURCE_' .. record.source]
		if not record.button:IsShown() then
			note = note .. ', ' .. L.LIST_HIDDEN
		end
		print('  ' .. record.label .. ' (' .. note .. ')')
	end
end

function commands.detach()
	ns.Launcher:Detach()
	ns.Options:Refresh()
	chat(L.DETACHED)
end

function commands.attach()
	ns.Launcher:Attach()
	ns.Options:Refresh()
	chat(L.ATTACHED)
end

function commands.reset()
	ns.Launcher:Reset()
	ns.Options:Refresh()
	chat(L.RESET)
end

function ns.ShowOptions()
	ns.Options:Toggle()
end
commands[''] = ns.ShowOptions
commands.options = ns.ShowOptions
commands.config = ns.ShowOptions

SLASH_BUTTONSTONE1 = '/buttonstone'
SLASH_BUTTONSTONE2 = '/bst'
SlashCmdList.BUTTONSTONE = function(input)
	local word = (input or ''):match('^%s*(%S*)'):lower()
	if not ns.ready and word ~= 'version' then
		word = 'help'
	end
	local command = commands[word] or commands.help
	command()
end

--[[ The Addons menu
Retail and Forever list addons in a menu below the minimap clock. Buttonstone
puts itself there when the setting says so: a click shows the buttons, a
right-click the options. The client offers no way to take an entry out again,
so switching it off takes effect after /reload.
--]]
local function compartment()
	if not ns.db.compartment or not C.HasAddonCompartment() then
		return
	end
	local function mouseOf(input)
		return type(input) == 'table' and input.buttonName or input
	end
	pcall(AddonCompartmentFrame.RegisterAddon, AddonCompartmentFrame, {
		text = L.TITLE,
		icon = ns.Theme.Texture('Logo'),
		notCheckable = true,
		func = function(_, input)
			if mouseOf(input) == 'RightButton' then
				ns.ShowOptions()
			else
				ns.Bundle:Toggle()
			end
		end,
		funcOnEnter = function(button)
			ns.Launcher.ShowTooltip(type(button) == 'table' and button or AddonCompartmentFrame, true)
		end,
		funcOnLeave = function()
			if GameTooltip then
				GameTooltip:Hide()
			end
		end,
	})
end

--[[ Start-up
Settings when the addon's own files are loaded; panel, main button and the
first look for buttons at login, when the minimap and other addons are there.
--]]
local events = CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent', function(self, event, name)
	if event == 'ADDON_LOADED' then
		if name == addonName then
			ButtonstoneDB = ns.LoadSettings(ButtonstoneDB)
			ns.db = ButtonstoneDB
			ns.look = C.Look()
		elseif ns.ready then
			ns.Collector:AddonLoaded()
		end
	elseif event == 'PLAYER_LOGIN' then
		self:UnregisterEvent('PLAYER_LOGIN')
		ns.Bundle:Init()
		ns.Launcher:Init()
		ns.ready = true
		compartment()
		ns.Collector:Init()
	end
end)

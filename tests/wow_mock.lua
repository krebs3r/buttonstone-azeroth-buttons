--[[ A small stand-in for the WoW API
Only what the addon's files touch, and nothing that pretends to draw. Each
client run sets WOW_PROJECT_ID, Mock.interface and Mock.locale before the
addon's files load (tests/run.py).
--]]
Mock = {
	locale = 'enUS',
	interface = 120105,
	combat = false,
	printed = {},
	frames = {},
	metadata = { Version = '@project-version@' },
}

WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_CLASSIC = 2

function GetLocale()
	return Mock.locale
end

function GetBuildInfo()
	return '0.0.0', '0', 'Jan 1 2026', Mock.interface
end

C_AddOns = {
	GetAddOnMetadata = function(name, field)
		if name ~= 'Buttonstone' then
			return nil
		end
		return Mock.metadata[field]
	end,
}

C_Timer = {
	After = function(_, callback)
		callback()
	end,
}

function InCombatLockdown()
	return Mock.combat
end

SlashCmdList = {}

AddonCompartmentFrame = {
	registered = {},
	RegisterAddon = function(self, info)
		self.registered[#self.registered + 1] = info
	end,
}

function print(...)
	local parts = {}
	for i = 1, select('#', ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	Mock.printed[#Mock.printed + 1] = table.concat(parts, ' ')
end

local Frame = {}
Frame.__index = Frame

function Frame:RegisterEvent(event)
	self.events[event] = true
end

function Frame:UnregisterEvent(event)
	self.events[event] = nil
end

function Frame:SetScript(handler, callback)
	self.scripts[handler] = callback
end

function CreateFrame(kind, name, parent)
	local frame = setmetatable({ kind = kind, name = name, parent = parent, events = {}, scripts = {} }, Frame)
	Mock.frames[#Mock.frames + 1] = frame
	if name then
		_G[name] = frame
	end
	return frame
end

function Mock.fire(event, ...)
	for _, frame in ipairs(Mock.frames) do
		if frame.events[event] and frame.scripts.OnEvent then
			frame.scripts.OnEvent(frame, event, ...)
		end
	end
end

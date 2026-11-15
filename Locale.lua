local _, ns = ...

--[[ Strings
English is the base; a locale lists only what it changes. A key nobody wrote
shows itself, so a forgotten string is visible in the game rather than empty.
--]]
local base = {
	TITLE = 'Buttonstone – Azeroth Buttons',
	HELP_HEADER = 'Commands:',
	HELP_VERSION = '/bst version – show the version and the client look',
	HELP_HELP = '/bst help – show these commands',
	VERSION = 'Version %s, look: %s',
	LOOK_retail = 'Retail',
	LOOK_classic = 'Classic',
	LOOK_forever = 'WoW: Forever',
}

local locales = {
	deDE = {
		HELP_HEADER = 'Befehle:',
		HELP_VERSION = '/bst version – Version und Look des Clients zeigen',
		HELP_HELP = '/bst help – diese Befehle zeigen',
		VERSION = 'Version %s, Look: %s',
	},
}

local strings = {}
for key, value in pairs(base) do
	strings[key] = value
end

local locale = type(GetLocale) == 'function' and GetLocale() or 'enUS'
for key, value in pairs(locales[locale] or {}) do
	strings[key] = value
end

ns.L = setmetatable(strings, {
	__index = function(_, key)
		return key
	end,
})

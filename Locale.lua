local _, ns = ...

--[[ Strings
English is the base; a locale lists only what it changes. A key nobody wrote
shows itself, so a forgotten string is visible in the game rather than empty.
--]]
local base = {
	TITLE = 'Buttonstone – Azeroth Buttons',
	PANEL_TITLE = 'Buttonstone',
	COUNT = '%d buttons',
	EMPTY = 'No buttons found yet',
	EMPTY_RIVAL = '%s keeps the buttons',
	RIVAL = '%s is active too and gathers the same buttons. Buttonstone leaves them to it; turn one of the two off.',
	TIP_CLICK = 'Click: show buttons',
	TIP_DRAG = 'Drag: move',

	HELP_HEADER = 'Commands:',
	HELP_LIST = '/bst list – list the gathered buttons',
	HELP_DETACH = '/bst detach – place the button anywhere',
	HELP_ATTACH = '/bst attach – put the button back on the minimap',
	HELP_RESET = '/bst reset – button back to its start position',
	HELP_VERSION = '/bst version – show the version and the client look',
	HELP_HELP = '/bst help – show these commands',
	VERSION = 'Version %s, look: %s',
	LIST_HEADER = 'Gathered buttons (%d):',
	LIST_HIDDEN = 'hidden',
	DETACHED = 'The button can now be dragged anywhere.',
	ATTACHED = 'The button is back on the minimap.',
	RESET = 'The button is back at its start position.',

	SOURCE_lib = 'LibDBIcon',
	SOURCE_own = 'Minimap',
	LOOK_retail = 'Retail',
	LOOK_classic = 'Classic',
	LOOK_forever = 'WoW: Forever',
}

local locales = {
	deDE = {
		COUNT = '%d Buttons',
		EMPTY = 'Noch keine Buttons gefunden',
		EMPTY_RIVAL = '%s verwaltet die Buttons',
		RIVAL = '%s ist auch aktiv und sammelt dieselben Buttons. Buttonstone überlässt sie ihm; '
			.. 'schalte eins der beiden aus.',
		TIP_CLICK = 'Klick: Buttons zeigen',
		TIP_DRAG = 'Ziehen: verschieben',

		HELP_HEADER = 'Befehle:',
		HELP_LIST = '/bst list – eingesammelte Buttons auflisten',
		HELP_DETACH = '/bst detach – Button frei platzieren',
		HELP_ATTACH = '/bst attach – Button zurück an die Minimap',
		HELP_RESET = '/bst reset – Button an seine Startposition',
		HELP_VERSION = '/bst version – Version und Look des Clients zeigen',
		HELP_HELP = '/bst help – diese Befehle zeigen',
		VERSION = 'Version %s, Look: %s',
		LIST_HEADER = 'Eingesammelte Buttons (%d):',
		LIST_HIDDEN = 'ausgeblendet',
		DETACHED = 'Der Button lässt sich jetzt frei verschieben.',
		ATTACHED = 'Der Button sitzt wieder an der Minimap.',
		RESET = 'Der Button ist zurück an seiner Startposition.',
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

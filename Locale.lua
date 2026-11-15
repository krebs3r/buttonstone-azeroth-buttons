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
	TIP_RIGHT = 'Right-click: options',
	TIP_DRAG = 'Drag: move',

	SEC_MAIN = 'Buttonstone button',
	KEEP = 'Attach to the minimap',
	KEEP_HINT = 'Off: place it anywhere on the screen',
	COMPARTMENT = 'Show in the addon list',
	COMPARTMENT_HINT = "Blizzard's list by the clock; takes effect after /reload",
	SEC_PANEL = 'Panel',
	COLUMNS = 'Columns',
	DIRECTION = 'Direction',
	SIZE = 'Size',
	PERCENT = '%d %%',
	DIR_auto = 'Automatic',
	['DIR_down-left'] = 'Down and left',
	['DIR_down-right'] = 'Down and right',
	['DIR_up-left'] = 'Up and left',
	['DIR_up-right'] = 'Up and right',
	UNIFORM = 'Uniform slots',
	HEADER = 'Show the header',
	AUTOCLOSE = 'Close when the mouse leaves',
	SEC_BUTTONS = 'Buttons (%d found)',
	NOT_LOADED = 'not loaded',
	RESET_POSITION = 'Reset position',
	DONE = 'Done',
	FOOTER = 'v%s with',

	HELP_HEADER = 'Commands:',
	HELP_OPTIONS = '/bst – open the options',
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
		TIP_RIGHT = 'Rechtsklick: Optionen',
		TIP_DRAG = 'Ziehen: verschieben',

		SEC_MAIN = 'Buttonstone Button',
		KEEP = 'An der Minimap befestigen',
		KEEP_HINT = 'Aus: frei auf dem Bildschirm platzierbar',
		COMPARTMENT = 'In der Addon-Liste zeigen',
		COMPARTMENT_HINT = 'Blizzards Liste neben der Uhr; wirkt nach /reload',
		COLUMNS = 'Spalten',
		DIRECTION = 'Richtung',
		SIZE = 'Größe',
		DIR_auto = 'Automatisch',
		['DIR_down-left'] = 'Nach links unten',
		['DIR_down-right'] = 'Nach rechts unten',
		['DIR_up-left'] = 'Nach links oben',
		['DIR_up-right'] = 'Nach rechts oben',
		UNIFORM = 'Einheitliche Slots',
		HEADER = 'Kopfzeile zeigen',
		AUTOCLOSE = 'Schließen, wenn die Maus es verlässt',
		SEC_BUTTONS = 'Buttons (%d gefunden)',
		NOT_LOADED = 'nicht geladen',
		RESET_POSITION = 'Position zurücksetzen',
		DONE = 'Fertig',

		HELP_HEADER = 'Befehle:',
		HELP_OPTIONS = '/bst – Optionen öffnen',
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

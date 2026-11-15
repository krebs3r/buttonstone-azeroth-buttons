std = 'lua51'
max_line_length = 120

-- The addon's own files. The tests run inside a WoW stand-in of their own
-- (tests/wow_mock.lua) and are checked by running them.
exclude_files = {
	'tests/',
	'.luarocks/',
	'.venv/',
	'.release/',
	'dist/',
}

ignore = {
	'212', -- unused argument
}

globals = {
	'ButtonstoneDB',
	'SlashCmdList',
	'SLASH_BUTTONSTONE1',
	'SLASH_BUTTONSTONE2',
}

read_globals = {
	-- Client and project
	'GetBuildInfo', 'GetLocale', 'WOW_PROJECT_ID', 'WOW_PROJECT_MAINLINE', 'WOW_PROJECT_CAMELOT',
	'C_AddOns', 'GetAddOnMetadata', 'C_Timer', 'InCombatLockdown', 'issecretvalue',

	-- Frames
	'CreateFrame', 'UIParent', 'AddonCompartmentFrame',
}

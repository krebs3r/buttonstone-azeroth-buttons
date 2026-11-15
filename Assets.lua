local _, ns = ...

--[[ Sprites in Media/
The panels, plates, header close button, rivet, toggles and slider thumbs
are Soundstone's (commit ecb4109); the gear, control fields, arrow and heart
are Hourstone's (commit 5a020bc), both by the same author and MIT licensed. Each
entry gives the sprite's drawn size in source units and the sub-rectangle of
the texture it fills, as Soundstone/Assets.lua records them.
--]]
ns.Assets = {
	RetailPanel = { width = 711, height = 379, uv = { 0.00390625, 0.99609375, 0.234375, 0.763671875 } },
	ClassicPanel = { width = 710, height = 384, uv = { 0.00390625, 0.99609375, 0.23046875, 0.767578125 } },
	ActionNormal = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	ActionHover = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	ActionPressed = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	HeaderClose = { width = 128, height = 128, uv = { 0, 1, 0, 1 } },
	Rivet = { width = 42, height = 42, uv = { 0.03125, 0.96875, 0.03125, 0.96875 } },
	Toggle = { width = 155, height = 82, uv = { 0.015625, 0.984375, 0.2421875, 0.7578125 } },
	ToggleRed = { width = 159, height = 80, uv = { 0.015625, 0.984375, 0.2578125, 0.7421875 } },
	GoldThumb = { width = 56, height = 100, uv = { 0.2265625, 0.765625, 0.015625, 0.984375 } },
	SilverThumb = { width = 59, height = 100, uv = { 0.2109375, 0.78125, 0.015625, 0.984375 } },
	Gear = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	ControlRetail = { width = 256, height = 64, uv = { 0, 1, 0, 1 } },
	ControlClassic = { width = 256, height = 64, uv = { 0, 1, 0, 1 } },
	Arrow = { width = 32, height = 32, uv = { 0, 1, 0, 1 } },
	Heart = { width = 32, height = 32, uv = { 0, 1, 0, 1 } },
	Logo = { width = 256, height = 256, uv = { 0, 1, 0, 1 } },
}

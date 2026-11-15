local _, ns = ...

--[[ Sprites in Media/
The panels and action plates are Soundstone's (commit ecb4109), the gear is
Hourstone's (commit 5a020bc), both by the same author and MIT licensed. Each
entry gives the sprite's drawn size in source units and the sub-rectangle of
the texture it fills, as Soundstone/Assets.lua records them.
--]]
ns.Assets = {
	RetailPanel = { width = 711, height = 379, uv = { 0.00390625, 0.99609375, 0.234375, 0.763671875 } },
	ClassicPanel = { width = 710, height = 384, uv = { 0.00390625, 0.99609375, 0.23046875, 0.767578125 } },
	ActionNormal = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	ActionHover = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	ActionPressed = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	Gear = { width = 64, height = 64, uv = { 0, 1, 0, 1 } },
	Logo = { width = 256, height = 256, uv = { 0, 1, 0, 1 } },
}

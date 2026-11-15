local addonName, ns = ...
local C = ns.Compat

--[[ The look
Retail wears Soundstone's gold sprites, Mists, the Anniversary realms and Era
its iron and stone. WoW: Forever wears the client's own art, as Soundstone
and Hourstone do there: Blizzard's bronze window frame, its red buttons and
its action-button icon frames. Each of those pieces is checked on its own,
and a piece the client cannot draw falls back to a flat look drawn in code.
The look follows the client; there is no setting for it. A look changes
surfaces, never what the panel shows.
--]]
local T = {}
ns.Theme = T

T.MEDIA = 'Interface\\AddOns\\' .. addonName .. '\\Media\\'
T.WHITE = 'Interface\\Buttons\\WHITE8X8'

local function rgb(r, g, b, a)
	return { r / 255, g / 255, b / 255, a }
end

T.palettes = {
	-- Soundstone's palette, shared by Retail and Classic.
	sprite = {
		text = { 0.96, 0.94, 0.87 },
		title = { 1, 0.81, 0.26 },
		muted = { 0.65, 0.63, 0.58 },
		rule = { 0.67, 0.64, 0.56, 0.55 },
	},
	-- Soundstone's Forever palette; the title takes the client's gold at runtime.
	forever = {
		text = rgb(240, 233, 218),
		title = { 1, 210 / 255, 0 },
		muted = rgb(166, 160, 148),
		rule = rgb(166, 160, 148, 0.35),
		plate = rgb(21, 18, 15, 0.96),
		band = rgb(10, 8, 6),
		lineTop = rgb(154, 128, 92),
		lineSide = rgb(128, 104, 72),
		lineBottom = rgb(104, 80, 52),
		accent = rgb(240, 204, 140),
		buttonIcon = rgb(255, 230, 128),
	},
}

-- Panel metrics in UI units, as the approved mockup draws them. Forever's
-- keep clear of the frame's metal: 8.6 units at the sides, 8.3 at the bottom,
-- the title strip's separator ending 29 units below the top (Soundstone's
-- measurements).
T.metrics = {
	retail = {
		panel = 'RetailPanel', corner = 7, sourceCorner = 23, icon = 24,
		padX = 11, padTop = 11, padTopHeader = 37, padBottom = 11, minWidth = 168,
	},
	classic = {
		panel = 'ClassicPanel', corner = 10, sourceCorner = 52, icon = 24,
		padX = 13, padTop = 13, padTopHeader = 40, padBottom = 13, minWidth = 172,
	},
	forever = {
		icon = 28,
		padX = 10, padTop = 10, padTopHeader = 33, padBottom = 10, minWidth = 160,
	},
}

T.SLOT = 32
T.GAP = 4

-- Forever's own art. Other clients ship other art under some of these names,
-- so it is used on the Forever client only.
T.window = {
	layout = 'ButtonFrameTemplateNoPortrait',
	background = 'Interface\\FrameGeneral\\UI-Background-Rock',
	streaks = '_UI-Frame-TopTileStreaks',
}
T.slot = {
	normal = 'UI-HUD-ActionBar-IconFrame',
	pushed = 'UI-HUD-ActionBar-IconFrame-Down',
	highlight = 'UI-HUD-ActionBar-IconFrame-Mouseover',
}
T.GEAR = 'Interface\\WorldMap\\GEAR_64GREY'

function T.Skin()
	if C.IsForever() then
		return 'forever'
	end
	return C.IsRetail() and 'retail' or 'classic'
end

function T.Metrics()
	return T.metrics[T.Skin()]
end

function T.IconSize()
	return T.Metrics().icon
end

T.colors = T.Skin() == 'forever' and T.palettes.forever or T.palettes.sprite

-- Window titles take the client's own gold; its value comes from client data.
if T.Skin() == 'forever' and type(NORMAL_FONT_COLOR) == 'table' and type(NORMAL_FONT_COLOR.GetRGB) == 'function' then
	local ok, r, g, b = pcall(NORMAL_FONT_COLOR.GetRGB, NORMAL_FONT_COLOR)
	if ok and type(r) == 'number' and type(g) == 'number' and type(b) == 'number' then
		T.colors.title = { r, g, b }
	end
end

function T.Texture(name)
	return T.MEDIA .. name
end

function T.Color(region, key, method)
	local c = T.colors[key]
	region[method or 'SetVertexColor'](region, c[1], c[2], c[3], c[4] or 1)
end

--[[ Which of Forever's pieces the client can draw ]]
function T.AtlasInfo(name)
	if not (C_Texture and type(C_Texture.GetAtlasInfo) == 'function') then
		return nil
	end
	local ok, info = pcall(C_Texture.GetAtlasInfo, name)
	return ok and type(info) == 'table' and info or nil
end

function T.HasAtlas(name)
	return T.AtlasInfo(name) ~= nil
end

function T.WindowLayout()
	if type(NineSliceUtil) == 'table' and type(NineSliceUtil.GetLayout) == 'function' then
		local ok, layout = pcall(NineSliceUtil.GetLayout, T.window.layout)
		if ok and type(layout) == 'table' then
			return layout
		end
	end
	return type(NineSliceLayouts) == 'table' and NineSliceLayouts[T.window.layout] or nil
end

-- The window frame's pieces (cut to the panel, with or without the title
-- strip) and the icon frames. Each falls back to the flat look on its own.
function T.Art()
	local art = {}
	if T.Skin() ~= 'forever' then
		return art
	end
	local layout = T.WindowLayout()
	if type(layout) == 'table' then
		art.window = true
		for _, piece in pairs(layout) do
			if type(piece) == 'table' and piece.atlas and not T.HasAtlas(piece.atlas) then
				art.window = false
			end
		end
		-- The top pieces are cut down to the strip's end (26.4 units below the
		-- frame's top) and the bottom corners to their lowest 8 units (Forever.lua):
		-- the pieces must reach that far.
		local function reaches(key, need)
			local piece = layout[key]
			local info = type(piece) == 'table' and piece.atlas and T.AtlasInfo(piece.atlas)
			return info and type(info.height) == 'number' and type(info.width) == 'number' and info.height >= need or false
		end
		if art.window then
			local top = type(layout.TopLeftCorner) == 'table' and (layout.TopLeftCorner.y or 0) or 0
			local bottom = type(layout.BottomLeftCorner) == 'table' and (layout.BottomLeftCorner.y or 0) or 0
			local strip = top + 26.4
			art.window = reaches('TopLeftCorner', strip) and reaches('TopRightCorner', strip) and reaches('TopEdge', strip)
				and reaches('BottomLeftCorner', 8 - bottom) and reaches('BottomRightCorner', 8 - bottom)
				and reaches('BottomEdge', 1) and reaches('LeftEdge', 1) and reaches('RightEdge', 1)
		end
	end
	art.slot = T.HasAtlas(T.slot.normal) and T.HasAtlas(T.slot.pushed) and T.HasAtlas(T.slot.highlight)
	return art
end

-- One physical pixel in a region's units; one unit where the client cannot say.
function T.Pixel(region)
	local factor
	if type(PixelUtil) == 'table' and type(PixelUtil.GetPixelToUIUnitFactor) == 'function' then
		factor = PixelUtil.GetPixelToUIUnitFactor()
	end
	local scale = region:GetEffectiveScale()
	if C.IsSecret(scale) or C.IsSecret(factor) or type(factor) ~= 'number' or type(scale) ~= 'number' or scale <= 0 then
		return 1
	end
	return factor / scale
end

--[[ Nine-slice
Fixed-size corners, edges stretched between them and a stretched centre, cut
from the sprite's sub-rectangle. Anchored on both sides, so the frame can
change size without anything being laid out again.
--]]
function T.NineSlice(frame, name, corner, sourceCorner, layer, sublevel)
	local asset = ns.Assets[name]
	local u = asset.uv
	local du = (u[2] - u[1]) * sourceCorner / asset.width
	local dv = (u[4] - u[3]) * sourceCorner / asset.height
	local xs = { u[1], u[1] + du, u[2] - du, u[2] }
	local ys = { u[3], u[3] + dv, u[4] - dv, u[4] }
	local c = corner
	local pieces = {}

	for row = 1, 3 do
		for col = 1, 3 do
			local t = frame:CreateTexture(nil, layer or 'BACKGROUND', nil, sublevel)
			t:SetTexture(T.Texture(name))
			t:SetTexCoord(xs[col], xs[col + 1], ys[row], ys[row + 1])
			local left = col == 1 and 0 or (col == 2 and c or nil)
			local right = col == 3 and 0 or (col == 2 and -c or nil)
			local top = row == 1 and 0 or (row == 2 and -c or nil)
			local bottom = row == 3 and 0 or (row == 2 and c or nil)
			if col ~= 2 then
				t:SetWidth(c)
			end
			if row ~= 2 then
				t:SetHeight(c)
			end
			if top and left then t:SetPoint('TOPLEFT', frame, 'TOPLEFT', left, top) end
			if top and right then t:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', right, top) end
			if bottom and left then t:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', left, bottom) end
			if bottom and right then t:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', right, bottom) end
			pieces[#pieces + 1] = t
		end
	end
	return pieces
end

-- Four one-pixel lines on a frame's edges, the flat look's outline.
function T.Lines(frame, layer, top, side, bottom)
	local d = T.Pixel(frame)
	local lines = {}
	local function line(key, a, b, horizontal)
		local t = frame:CreateTexture(nil, layer)
		t:SetTexture(T.WHITE)
		T.Color(t, key)
		t:SetPoint(a[1], frame, a[1], a[2], a[3])
		t:SetPoint(b[1], frame, b[1], b[2], b[3])
		if horizontal then t:SetHeight(d) else t:SetWidth(d) end
		lines[#lines + 1] = t
	end
	line(top, { 'TOPLEFT', 0, 0 }, { 'TOPRIGHT', 0, 0 }, true)
	line(bottom, { 'BOTTOMLEFT', 0, 0 }, { 'BOTTOMRIGHT', 0, 0 }, true)
	line(side, { 'TOPLEFT', 0, -d }, { 'BOTTOMLEFT', 0, d }, false)
	line(side, { 'TOPRIGHT', 0, -d }, { 'BOTTOMRIGHT', 0, d }, false)
	return lines
end

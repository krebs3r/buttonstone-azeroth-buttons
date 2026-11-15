local _, ns = ...
local T = ns.Theme

--[[ WoW: Forever's own look
Ported from Soundstone 0.4, where it was measured and seen in the game:

- With the header, the panel wears the pieces of Blizzard's
  ButtonFrameTemplateNoPortrait on a frame of its own above the content, with
  the client's rock ground and top streaks, the title in the title strip and
  the gear as a red UIPanelButtonTemplate header button.
- Without the header, the same frame cut to its metal band, as Soundstone's
  compact bar wears it.
- Each slot wears the action bar's icon frame, its pressed art while held and
  its highlight on hover, on a frame above the gathered button.

Where the client lacks a piece, that piece falls back to the flat look: a
near-black plate with one-pixel bronze lines, and flat wells for the slots.
--]]
local F = {}
ns.Forever = F

-- The border's box against the frame: Blizzard's art starts 4.4 units inside
-- it on the left and 3.35 above it, and ends 0.5 / 0.35 beyond it on the
-- right and bottom, so the opaque metal ends flush with the frame.
local BORDER = { left = -4.4, top = -3.35, right = 0.5, bottom = 0.35 }
-- Forever's red button art sits 0.8 units below its rectangle's centre.
local SYMBOL_DROP = 0.8

local function newBorder(frame)
	local border = CreateFrame('Frame', nil, frame)
	border:SetPoint('TOPLEFT', frame, 'TOPLEFT', BORDER.left, BORDER.top)
	border:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', BORDER.right, BORDER.bottom)
	-- Above the content, as Blizzard's NineSlice is; the header sits above it in turn.
	border:SetFrameLevel(frame:GetFrameLevel() + 10)
	border:EnableMouse(false)
	return border
end

local function ground(frame, border, top)
	local pieces = {}
	local rock = frame:CreateTexture(nil, 'BACKGROUND', nil, -6)
	rock:SetTexture(T.window.background, 'REPEAT', 'REPEAT')
	rock:SetHorizTile(true)
	rock:SetVertTile(true)
	rock:SetPoint('TOPLEFT', border, 'TOPLEFT', 7, -top)
	rock:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -2, 2)
	pieces[#pieces + 1] = rock
	if T.HasAtlas(T.window.streaks) then
		local streaks = frame:CreateTexture(nil, 'BACKGROUND', nil, -5)
		streaks:SetAtlas(T.window.streaks)
		streaks:SetHorizTile(true)
		streaks:SetHeight(top > 10 and 43 or 4)
		streaks:SetPoint('TOPLEFT', border, 'TOPLEFT', 6, -(top > 10 and top or 2.8))
		streaks:SetPoint('TOPRIGHT', border, 'TOPRIGHT', -2, -(top > 10 and top or 2.8))
		pieces[#pieces + 1] = streaks
	end
	return pieces
end

local function group(frame, pieces)
	return {
		frame = frame,
		pieces = pieces,
		SetShown = function(self, shown)
			for _, piece in ipairs(self.pieces) do
				piece:SetShown(shown)
			end
		end,
	}
end

--[[ Blizzard's frame, cut to the panel
ButtonFrameTemplateNoPortrait is made for tall windows: its top corners hold
the title strip and are taller than a panel with one row of buttons, and
Forever then crops the bottom corners away (seen in the game on 15 November
2026: no bottom, sides running past the panel). So the frame is put together
here from the layout's own pieces, as Soundstone cuts it for its compact
bar: the top pieces keep their rows from 5 units above the box's top down to
`below` units under it; the bottom corners keep their lowest units up to 8
above the box's bottom; edges run between them. With the title strip,
`below` is 26.4, where the strip's separator has ended and the flat ground
begins (Soundstone's measurement); without it, 3, the metal band alone.
--]]
F.STRIP = 26.4
F.BAND = 3

local function cut(frame, layout, below)
	local border = newBorder(frame)
	local function piece(key, from, to, tile)
		local p = layout[key]
		local info = T.AtlasInfo(p.atlas)
		local t = border:CreateTexture(nil, 'OVERLAY')
		-- Texture coordinates set before SetAtlas apply within the atlas.
		t:SetTexCoord(0, 1, (from or 0) / info.height, (to or info.height) / info.height)
		if tile == 'h' then
			t:SetHorizTile(info.tilesHorizontally or false)
		elseif tile == 'v' then
			t:SetVertTile(info.tilesVertically or false)
		end
		t:SetAtlas(p.atlas)
		if t.SetSnapToPixelGrid then
			t:SetTexelSnappingBias(0)
			t:SetSnapToPixelGrid(false)
		end
		return t, p, info
	end
	local top = layout.TopLeftCorner.y or 0
	local height = 5 + below
	local tl, tlp, tli = piece('TopLeftCorner', top - 5, top + below)
	tl:SetSize(tli.width, height)
	tl:SetPoint('TOPLEFT', border, 'TOPLEFT', tlp.x or 0, 5)
	local tr, trp, tri = piece('TopRightCorner', top - 5, top + below)
	tr:SetSize(tri.width, height)
	tr:SetPoint('TOPRIGHT', border, 'TOPRIGHT', trp.x or 0, 5)
	local te = piece('TopEdge', top - 5, top + below, 'h')
	te:SetHeight(height)
	te:SetPoint('TOPLEFT', tl, 'TOPRIGHT')
	te:SetPoint('TOPRIGHT', tr, 'TOPLEFT')
	local function bottomCorner(key, point)
		local p = layout[key]
		local keep = 8 - (p.y or 0)
		local info = T.AtlasInfo(p.atlas)
		local t = piece(key, info.height - keep, info.height)
		t:SetSize(info.width, keep)
		t:SetPoint(point, border, point, p.x or 0, p.y or 0)
		return t, keep
	end
	local bl, keep = bottomCorner('BottomLeftCorner', 'BOTTOMLEFT')
	local br = bottomCorner('BottomRightCorner', 'BOTTOMRIGHT')
	local edgeInfo = T.AtlasInfo(layout.BottomEdge.atlas)
	local edge = math.min(edgeInfo.height, keep)
	local be = piece('BottomEdge', edgeInfo.height - edge, edgeInfo.height, 'h')
	be:SetHeight(edge)
	be:SetPoint('BOTTOMLEFT', bl, 'BOTTOMRIGHT')
	be:SetPoint('BOTTOMRIGHT', br, 'BOTTOMLEFT')
	local le, _, lei = piece('LeftEdge', nil, nil, 'v')
	le:SetWidth(lei.width)
	le:SetPoint('TOPLEFT', tl, 'BOTTOMLEFT')
	le:SetPoint('BOTTOMLEFT', bl, 'TOPLEFT')
	local re, _, rei = piece('RightEdge', nil, nil, 'v')
	re:SetWidth(rei.width)
	re:SetPoint('TOPRIGHT', tr, 'BOTTOMRIGHT')
	re:SetPoint('BOTTOMRIGHT', br, 'TOPRIGHT')
	border.pieces = {
		topLeft = tl, topRight = tr, top = te, bottomLeft = bl, bottomRight = br, bottom = be, left = le, right = re,
	}
	-- The window's ground starts under the strip; under the band, just below it.
	local pieces = ground(frame, border, below > 10 and 21 or 2)
	table.insert(pieces, 1, border)
	local g = group(frame, pieces)
	g.border = border
	return g
end

-- The flat look: a plate and one-pixel lines on a frame of their own above the content.
local function flat(frame)
	local fill = frame:CreateTexture(nil, 'BACKGROUND')
	fill:SetTexture(T.WHITE)
	fill:SetAllPoints(frame)
	T.Color(fill, 'plate')
	local edge = CreateFrame('Frame', nil, frame)
	edge:SetAllPoints(frame)
	edge:SetFrameLevel(frame:GetFrameLevel() + 10)
	edge:EnableMouse(false)
	T.Lines(edge, 'OVERLAY', 'lineTop', 'lineSide', 'lineBottom')
	return group(frame, { fill, edge })
end

--[[ The panel's surfaces and header on Forever
Returns what the panel needs: the header (title, count, gear), a rule or
none, and Decorate(header shown), which shows the right surface.
--]]
function F.BuildPanel(bundle, frame, L)
	local art = T.Art()
	local surfaces = {}
	local parts = { art = art }

	if art.window then
		local layout = T.WindowLayout()
		surfaces.strip = cut(frame, layout, F.STRIP)
		surfaces.band = cut(frame, layout, F.BAND)
	else
		surfaces.flat = flat(frame)
	end
	parts.surfaces = surfaces

	-- The header rides above the frame's title strip.
	local header = CreateFrame('Frame', nil, frame)
	header:SetFrameLevel(frame:GetFrameLevel() + 12)
	header:EnableMouse(false)
	parts.header = header

	local title = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	title:SetText(L.PANEL_TITLE)
	T.Color(title, 'title', 'SetTextColor')
	local count = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
	count:SetPoint('LEFT', title, 'RIGHT', 4, 0)
	T.Color(count, 'muted', 'SetTextColor')
	parts.title, parts.count = title, count

	local gear
	if art.window then
		-- Inside the strip: the gear as Forever's red header button, the title centred.
		local border = surfaces.strip.border
		header:SetAllPoints(border)
		gear = CreateFrame('Button', nil, header, 'UIPanelButtonTemplate')
		gear:SetSize(32, 22)
		gear:SetText('')
		gear:SetPoint('TOPLEFT', border, 'TOPLEFT', 8, 1)
		local symbol = gear:CreateTexture(nil, 'ARTWORK')
		symbol:SetTexture(T.GEAR)
		symbol:SetSize(17, 17)
		symbol:SetPoint('CENTER', gear, 'CENTER', 0, -SYMBOL_DROP)
		T.Color(symbol, 'buttonIcon')
		gear.symbol = symbol
		gear:SetFrameLevel(frame:GetFrameLevel() + 13)
		parts.centred = true
	else
		-- Flat: as the sprite header, a muted gear on the right and a rule below.
		local m = T.Metrics()
		header:SetPoint('TOPLEFT', frame, 'TOPLEFT', m.padX - 1, -(m.padX - 3))
		header:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -(m.padX - 1), -(m.padX - 3))
		header:SetHeight(20)
		local logo = header:CreateTexture(nil, 'ARTWORK')
		logo:SetTexture(T.Texture('Logo'))
		logo:SetSize(18, 18)
		logo:SetPoint('LEFT', header, 'LEFT', 0, 0)
		title:SetPoint('LEFT', logo, 'RIGHT', 5, 0)
		gear = CreateFrame('Button', nil, header)
		gear:SetSize(15, 15)
		gear:SetPoint('RIGHT', header, 'RIGHT', 0, 0)
		local symbol = gear:CreateTexture(nil, 'ARTWORK')
		symbol:SetAllPoints(gear)
		symbol:SetTexture(T.GEAR)
		T.Color(symbol, 'muted')
		gear.symbol = symbol
		local rule = frame:CreateTexture(nil, 'ARTWORK')
		rule:SetPoint('TOPLEFT', frame, 'TOPLEFT', m.padX, -(m.padTopHeader - 7))
		rule:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -m.padX, -(m.padTopHeader - 7))
		rule:SetHeight(T.Pixel(frame))
		rule:SetTexture(T.WHITE)
		T.Color(rule, 'rule')
		parts.rule = rule
	end
	gear:SetScript('OnClick', function() ns.ShowOptions() end)
	parts.gear = gear

	-- The room the header needs: gear and title clear of each other, the title centred in the strip.
	function parts.HeaderWidth()
		local text = title:GetStringWidth() + 4 + count:GetStringWidth()
		if parts.centred then
			return 2 * (8 + 32 + 6) + text
		end
		local m = T.Metrics()
		return 2 * (m.padX - 1) + 18 + 5 + text + 8 + 15
	end

	function parts.Decorate(headerShown)
		if surfaces.strip then
			surfaces.strip:SetShown(headerShown)
			surfaces.band:SetShown(not headerShown)
		end
		if parts.centred then
			-- Title and count together centred under the strip's middle.
			title:ClearAllPoints()
			title:SetPoint('TOP', surfaces.strip.border, 'TOP', -(4 + count:GetStringWidth()) / 2, -6)
		end
	end

	return parts
end

--[[ Slots on Forever ]]
function F.Slot(slot, art)
	if art.slot then
		-- The icon frame lies on a frame above the gathered button; its middle is open.
		local cover = CreateFrame('Frame', nil, slot)
		cover:SetAllPoints(slot)
		cover:SetFrameLevel(slot:GetFrameLevel() + 5)
		cover:EnableMouse(false)
		local pieces = {}
		for key, atlas in pairs(T.slot) do
			local t = cover:CreateTexture(nil, 'OVERLAY')
			t:SetAtlas(atlas)
			t:SetSize(T.SLOT * 46 / 45, T.SLOT)
			t:SetPoint('TOPLEFT', cover, 'TOPLEFT', 0, 0)
			pieces[key] = t
		end
		pieces.highlight:SetBlendMode('ADD')
		slot.frameArt = pieces
		slot.visual = { cover }
		return
	end
	-- The flat well: band ground and a one-pixel outline.
	local fill = slot:CreateTexture(nil, 'BACKGROUND')
	fill:SetTexture(T.WHITE)
	fill:SetAllPoints(slot)
	T.Color(fill, 'band')
	slot.visual = { fill }
	for _, line in ipairs(T.Lines(slot, 'BORDER', 'lineBottom', 'lineBottom', 'lineBottom')) do
		slot.visual[#slot.visual + 1] = line
	end
	slot.wellLines = { unpack(slot.visual, 2) }
end

function F.SlotState(slot, state)
	local art = slot.frameArt
	if art then
		art.normal:SetShown(state ~= 'pressed')
		art.pushed:SetShown(state == 'pressed')
		art.highlight:SetShown(state ~= 'normal')
	elseif slot.wellLines then
		for _, line in ipairs(slot.wellLines) do
			T.Color(line, state == 'normal' and 'lineBottom' or 'accent')
		end
	end
end

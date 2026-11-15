local _, ns = ...
local T, L = ns.Theme, ns.L
local try = ns.Collector.try

--[[ The panel
A grid of slots, one per gathered button that is shown, sorted by name. In
the uniform look a slot wears the client's action-button plate and the
button inside it keeps only its icon; everything hidden for that is written
down and given back when the look is switched off or the button is released.
--]]
local Bundle = { free = {} }
ns.Bundle = Bundle

local SLOT, GAP = T.SLOT, T.GAP

--[[ The uniform look
The round border, the dark disc behind the icon and the round highlight are
Blizzard's tracking-button pieces that LibDBIcon and most addons draw; they
are known by file ID (and by name where a client hands back a path).
--]]
local DECORATION_FILES = { [136430] = true, [136467] = true, [136477] = true }
local DECORATION_WORDS = { 'trackingborder', 'minimap-background', 'zoombutton-highlight' }

local function isDecoration(region, highlight)
	if region == highlight then
		return true
	end
	local id = try(region, 'GetTextureFileID')
	if type(id) == 'number' and DECORATION_FILES[id] then
		return true
	end
	local path = try(region, 'GetTexture')
	if type(path) == 'number' and DECORATION_FILES[path] then
		return true
	end
	local text = ((type(path) == 'string' and path or '') .. ' ' .. (try(region, 'GetAtlas') or '')):lower()
	for _, word in ipairs(DECORATION_WORDS) do
		if text:find(word, 1, true) then
			return true
		end
	end
	return false
end

-- The button's icon: LibDBIcon's `icon` field, or the largest texture that is
-- not a decoration, artwork layer first.
local function findIcon(button)
	local highlight = try(button, 'GetHighlightTexture')
	for _, key in ipairs({ 'icon', 'Icon' }) do
		local icon = rawget(button, key)
		if type(icon) == 'table' and try(icon, 'GetObjectType') == 'Texture' then
			return icon, highlight
		end
	end
	local best, bestScore
	for _, region in ipairs({ button:GetRegions() }) do
		if try(region, 'GetObjectType') == 'Texture' and not isDecoration(region, highlight) then
			local width, height = try(region, 'GetSize')
			local score = (tonumber(width) or 0) * (tonumber(height) or 0)
			if try(region, 'GetDrawLayer') == 'ARTWORK' then
				score = score + 10000
			end
			if not bestScore or score > bestScore then
				best, bestScore = region, score
			end
		end
	end
	return best, highlight
end

Bundle.FindIcon = findIcon

local function style(record)
	local button = record.button
	local icon, highlight = findIcon(button)
	if not icon then
		return false
	end
	local saved = { icon = icon, hidden = {}, points = {}, masks = {} }
	saved.width, saved.height = icon:GetSize()
	for i = 1, icon:GetNumPoints() do
		saved.points[i] = { icon:GetPoint(i) }
	end
	for _, region in ipairs({ button:GetRegions() }) do
		if region ~= icon and try(region, 'GetObjectType') == 'Texture' then
			saved.hidden[region] = region:GetAlpha()
			region:SetAlpha(0)
		end
	end
	if highlight and saved.hidden[highlight] == nil then
		saved.hidden[highlight] = highlight:GetAlpha()
		highlight:SetAlpha(0)
	end
	-- A round mask would leave a round icon in a square slot.
	for i = (try(icon, 'GetNumMaskTextures') or 0), 1, -1 do
		local mask = icon:GetMaskTexture(i)
		if mask then
			saved.masks[#saved.masks + 1] = mask
			icon:RemoveMaskTexture(mask)
		end
	end
	icon:ClearAllPoints()
	icon:SetPoint('CENTER', button, 'CENTER', 0, 0)
	icon:SetSize(T.IconSize(), T.IconSize())
	button:SetSize(SLOT, SLOT)
	record.style = saved
	return true
end

local function unstyle(record)
	local saved = record.style
	if not saved then
		return
	end
	local icon = saved.icon
	for region, alpha in pairs(saved.hidden) do
		region:SetAlpha(alpha)
	end
	icon:ClearAllPoints()
	for _, point in ipairs(saved.points) do
		icon:SetPoint(unpack(point))
	end
	icon:SetSize(saved.width, saved.height)
	for _, mask in ipairs(saved.masks) do
		icon:AddMaskTexture(mask)
	end
	record.button:SetSize(record.saved.width, record.saved.height)
	record.style = nil
end

--[[ Slots ]]
local function newSlot(parent)
	local slot = CreateFrame('Frame', nil, parent)
	slot:SetSize(SLOT, SLOT)
	slot.visual = {}
	if T.Skin() == 'forever' then
		ns.Forever.Slot(slot, Bundle.art)
	elseif T.Skin() == 'retail' then
		local plate = slot:CreateTexture(nil, 'BACKGROUND')
		plate:SetAllPoints(slot)
		plate:SetTexture(T.Texture('ActionNormal'))
		slot.plate = plate
		slot.visual[1] = plate
	else
		slot.visual = T.NineSlice(slot, 'ClassicPanel', 3, 52, 'BACKGROUND')
		local glow = slot:CreateTexture(nil, 'BORDER')
		glow:SetPoint('TOPLEFT', slot, 'TOPLEFT', 3, -3)
		glow:SetPoint('BOTTOMRIGHT', slot, 'BOTTOMRIGHT', -3, 3)
		glow:SetColorTexture(1, 0.82, 0, 0.16)
		glow:SetBlendMode('ADD')
		glow:Hide()
		slot.glow = glow
	end
	return slot
end

local function showVisual(slot, shown)
	for _, texture in ipairs(slot.visual) do
		texture:SetShown(shown)
	end
	if slot.glow and not shown then
		slot.glow:Hide()
	end
end

local function setState(slot, state)
	if slot.frameArt or slot.wellLines then
		ns.Forever.SlotState(slot, state)
	elseif slot.plate then
		local name = state == 'pressed' and 'ActionPressed' or state == 'hover' and 'ActionHover' or 'ActionNormal'
		slot.plate:SetTexture(T.Texture(name))
	elseif slot.glow then
		slot.glow:SetShown(state ~= 'normal')
	end
end

function Bundle:SlotState(record, script)
	local slot = record.slot
	if not slot or not record.style then
		return
	end
	if script == 'OnEnter' then
		setState(slot, 'hover')
	elseif script == 'OnLeave' then
		setState(slot, 'normal')
	elseif script == 'OnMouseDown' then
		setState(slot, 'pressed')
	else
		setState(slot, try(record.button, 'IsMouseOver') and 'hover' or 'normal')
	end
end

function Bundle:Adopt(record)
	local slot = table.remove(self.free) or newSlot(self.frame)
	record.slot = slot
	local button, methods = record.button, record.methods
	methods.SetParent(button, slot)
	methods.ClearAllPoints(button)
	methods.SetPoint(button, 'CENTER', slot, 'CENTER', 0, 0)
	methods.SetFrameStrata(button, self.frame:GetFrameStrata())
	methods.SetFrameLevel(button, slot:GetFrameLevel() + 2)
	if ns.db.panel.uniform then
		style(record)
	end
	showVisual(slot, record.style ~= nil)
	setState(slot, 'normal')
	self:Layout()
end

function Bundle:Abandon(record)
	unstyle(record)
	local slot = record.slot
	record.slot = nil
	if slot then
		slot:Hide()
		slot:ClearAllPoints()
		self.free[#self.free + 1] = slot
	end
end

--[[ Layout ]]
function Bundle:Layout()
	local frame = self.frame
	if not frame or not ns.db then
		return
	end
	local m, p = T.Metrics(), ns.db.panel
	local shown = {}
	for _, record in ipairs(ns.Collector.records) do
		local visible = record.button:IsShown() and true or false
		record.slot:SetShown(visible)
		if visible then
			shown[#shown + 1] = record
		end
	end
	table.sort(shown, function(a, b)
		local la, lb = a.label:lower(), b.label:lower()
		if la == lb then
			return a.name < b.name
		end
		return la < lb
	end)
	self.shown = shown

	local count = #shown
	local columns = math.max(1, math.min(p.columns, count))
	local rows = math.max(1, math.ceil(count / columns))
	local gridWidth = columns * SLOT + (columns - 1) * GAP
	local gridHeight = rows * SLOT + (rows - 1) * GAP
	local top = p.header and m.padTopHeader or m.padTop
	self.count:SetText(L.COUNT:format(count))
	local width = gridWidth + 2 * m.padX
	if p.header or count == 0 then
		width = math.max(width, m.minWidth)
	end
	if p.header then
		width = math.max(width, self:HeaderWidth())
	end
	frame:SetSize(width, top + gridHeight + m.padBottom)
	if self.decorate then
		self.decorate(p.header)
	end

	local left = (width - gridWidth) / 2
	for i, record in ipairs(shown) do
		local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
		record.slot:ClearAllPoints()
		record.slot:SetPoint('TOPLEFT', frame, 'TOPLEFT', left + column * (SLOT + GAP), -(top + row * (SLOT + GAP)))
	end

	self.header:SetShown(p.header)
	if self.rule then
		self.rule:SetShown(p.header)
	end
	local rival = ns.Collector.rival
	self.empty:SetText(rival and L.EMPTY_RIVAL:format(rival) or L.EMPTY)
	self.empty:SetShown(count == 0)
	self.empty:ClearAllPoints()
	self.empty:SetPoint('CENTER', frame, 'TOPLEFT', width / 2, -(top + gridHeight / 2))
end

-- Room for logo, title, count and gear side by side: the client's font can be
-- wider than the mockup's, and German counts are longer.
function Bundle:HeaderWidth()
	if self.headerWidth then
		return self.headerWidth()
	end
	local m = T.Metrics()
	return 2 * (m.padX - 1) + 18 + 5 + self.title:GetStringWidth() + 5 + self.count:GetStringWidth() + 8 + 15
end

-- Settings changed: the look of every slot, the layout, the place.
function Bundle:Refresh()
	for _, record in ipairs(ns.Collector.records) do
		unstyle(record)
		if ns.db.panel.uniform then
			style(record)
		end
		showVisual(record.slot, record.style ~= nil)
	end
	self.frame:SetScale(ns.db.panel.size / 100)
	self:Layout()
	if self.frame:IsShown() then
		self:Anchor()
	end
end

--[[ Where it opens
Next to the main button, towards the side of the screen with more room, or
the way the settings say.
--]]
function Bundle:Direction()
	local direction = ns.db.panel.direction
	if direction ~= 'auto' then
		return direction
	end
	local launcher = ns.Launcher.button
	local x, y = launcher:GetCenter()
	local cx, cy = UIParent:GetCenter()
	if not x or not cx then
		return 'down-left'
	end
	local s, u = launcher:GetEffectiveScale(), UIParent:GetEffectiveScale()
	x, y, cx, cy = x * s, y * s, cx * u, cy * u
	return (y > cy and 'down' or 'up') .. '-' .. (x > cx and 'left' or 'right')
end

local ANCHORS = {
	['down-left'] = { 'TOPRIGHT', 'BOTTOMRIGHT', 0, -3 },
	['down-right'] = { 'TOPLEFT', 'BOTTOMLEFT', 0, -3 },
	['up-left'] = { 'BOTTOMRIGHT', 'TOPRIGHT', 0, 3 },
	['up-right'] = { 'BOTTOMLEFT', 'TOPLEFT', 0, 3 },
}

function Bundle:Anchor()
	local a = ANCHORS[self:Direction()]
	self.frame:ClearAllPoints()
	self.frame:SetPoint(a[1], ns.Launcher.button, a[2], a[3], a[4])
end

--[[ Opening and closing ]]
function Bundle:Open()
	ns.Collector:Scan()
	self:Anchor()
	self.frame:Show()
end

function Bundle:Close()
	self.frame:Hide()
end

function Bundle:Toggle()
	if self.frame:IsShown() then
		self:Close()
	else
		self:Open()
	end
end

-- A menu opened from a gathered button lies outside the panel; it keeps the panel open.
local function menuOpen()
	for _, name in ipairs({ 'DropDownList1', 'L_DropDownList1' }) do
		local list = _G[name]
		if type(list) == 'table' and try(list, 'IsShown') then
			return true
		end
	end
	local manager = type(Menu) == 'table' and try(Menu, 'GetManager')
	return manager and try(manager, 'GetOpenMenu') ~= nil or false
end

local function watch(frame, elapsed)
	frame.since = (frame.since or 0) + elapsed
	if frame.since < 0.1 then
		return
	end
	local step = frame.since
	frame.since = 0
	local launcher = ns.Launcher.button
	if not ns.db.panel.autoClose or frame:IsMouseOver() or (launcher and launcher:IsMouseOver()) or menuOpen() then
		frame.away = 0
		return
	end
	frame.away = (frame.away or 0) + step
	if frame.away >= 0.6 then
		frame:Hide()
	end
end

-- Retail's and Classic's surface and header: the sprite frame, logo, title, count, gear and rule.
function Bundle:BuildSprite(frame, m)
	T.NineSlice(frame, m.panel, m.corner, m.sourceCorner, 'BACKGROUND')
	local header = CreateFrame('Frame', nil, frame)
	header:SetPoint('TOPLEFT', frame, 'TOPLEFT', m.padX - 1, -(m.padX - 3))
	header:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -(m.padX - 1), -(m.padX - 3))
	header:SetHeight(20)
	self.header = header

	local logo = header:CreateTexture(nil, 'ARTWORK')
	logo:SetTexture(T.Texture('Logo'))
	logo:SetSize(18, 18)
	logo:SetPoint('LEFT', header, 'LEFT', 0, 0)

	local title = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	title:SetPoint('LEFT', logo, 'RIGHT', 5, 0)
	title:SetText(L.PANEL_TITLE)
	T.Color(title, 'title', 'SetTextColor')
	self.title = title

	local count = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
	count:SetPoint('LEFT', title, 'RIGHT', 5, -1)
	T.Color(count, 'muted', 'SetTextColor')
	self.count = count

	local gear = CreateFrame('Button', nil, header)
	gear:SetSize(15, 15)
	gear:SetPoint('RIGHT', header, 'RIGHT', 0, 0)
	local gearTexture = gear:CreateTexture(nil, 'ARTWORK')
	gearTexture:SetAllPoints(gear)
	gearTexture:SetTexture(T.Texture('Gear'))
	gearTexture:SetAlpha(0.85)
	gear:SetScript('OnEnter', function() gearTexture:SetAlpha(1) end)
	gear:SetScript('OnLeave', function() gearTexture:SetAlpha(0.85) end)
	gear:SetScript('OnClick', function() ns.ShowOptions() end)
	self.gear = gear

	local rule = frame:CreateTexture(nil, 'ARTWORK')
	rule:SetPoint('TOPLEFT', frame, 'TOPLEFT', m.padX, -(m.padTopHeader - 7))
	rule:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -m.padX, -(m.padTopHeader - 7))
	rule:SetHeight(1)
	rule:SetColorTexture(1, 1, 1, 1)
	T.Color(rule, 'rule')
	self.rule = rule
end

function Bundle:Init()
	local m = T.Metrics()
	local frame = CreateFrame('Frame', 'ButtonstonePanel', UIParent)
	self.frame = frame
	frame:Hide()
	frame:SetFrameStrata('HIGH')
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetScale(ns.db.panel.size / 100)
	frame:SetSize(m.minWidth, m.padTopHeader + SLOT + m.padBottom)
	-- Escape closes it, as it closes Blizzard's windows.
	table.insert(UISpecialFrames, 'ButtonstonePanel')

	if T.Skin() == 'forever' then
		local parts = ns.Forever.BuildPanel(self, frame, L)
		self.art, self.surfaces = parts.art, parts.surfaces
		self.header, self.title, self.count = parts.header, parts.title, parts.count
		self.gear, self.rule = parts.gear, parts.rule
		self.decorate, self.headerWidth = parts.Decorate, parts.HeaderWidth
	else
		self:BuildSprite(frame, m)
	end

	local empty = frame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
	empty:SetText(L.EMPTY)
	T.Color(empty, 'muted', 'SetTextColor')
	self.empty = empty

	frame:SetScript('OnShow', function(shown)
		shown.away, shown.since = 0, 0
	end)
	frame:SetScript('OnUpdate', watch)
	self:Layout()
end

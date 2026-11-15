--[[ Gathering, the panel and the main button, once per client
Runs after test_core.lua in the same Lua state: the settings are loaded,
PLAYER_LOGIN has not fired yet.
--]]
local _, ns = ...
local expect = Mock.expect
local retail = expect.look == 'retail'
-- LibDBIcon picks its sizes by project ID, so the Forever beta gets Retail's.
local libIcon = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and 18 or 17
local skin = ns.Theme.Skin()
local ICON = ns.Theme.IconSize()
local m = ns.Theme.Metrics()
local passed = 0

local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local function equal(actual, wanted, message)
	assert(actual == wanted, (message or 'value') .. ': wanted ' .. tostring(wanted) .. ', got ' .. tostring(actual))
	passed = passed + 1
end

local function near(actual, wanted, message)
	assert(math.abs(actual - wanted) < 1e-6, (message or 'value') .. ': wanted ' .. tostring(wanted) .. ', got ' .. tostring(actual))
	passed = passed + 1
end

local function texturesOf(button, except)
	local list = {}
	for _, region in ipairs({ button:GetRegions() }) do
		if region ~= except and region:GetObjectType() == 'Texture' then
			list[#list + 1] = region
		end
	end
	return list
end

-- An addon's own button built like Hourstone's: disc, masked icon, border, highlight.
local function hourstoneLike(name, addon, parent)
	Mock.tainting = addon
	local button = CreateFrame('Button', name, parent or Minimap)
	Mock.tainting = nil
	button:SetSize(31, 31)
	button:SetPoint('CENTER', Minimap, 'CENTER', 52, 52)
	local ground = button:CreateTexture(nil, 'BACKGROUND')
	ground:SetTexture(136467)
	ground:SetSize(24, 24)
	ground:SetPoint('CENTER')
	local icon = button:CreateTexture(nil, 'ARTWORK')
	icon:SetTexture('Interface\\AddOns\\' .. addon .. '\\Media\\Logo')
	icon:SetSize(18, 18)
	icon:SetPoint('TOPLEFT', 7, -6)
	local mask = button:CreateMaskTexture(nil, 'ARTWORK')
	icon:AddMaskTexture(mask)
	button.icon = icon
	local border = button:CreateTexture(nil, 'OVERLAY')
	border:SetTexture(136430)
	border:SetSize(50, 50)
	border:SetPoint('TOPLEFT')
	button:SetHighlightTexture(136477, 'ADD')
	button:SetScript('OnClick', function() end)
	return button, icon, border
end

local function plainFrame(kind, name, addon, width, height, parent)
	Mock.tainting = addon
	local frame = CreateFrame(kind, name, parent or Minimap)
	Mock.tainting = nil
	frame:SetSize(width, height)
	frame:SetPoint('CENTER', Minimap, 'CENTER', 0, 0)
	return frame
end

--[[ Before login: what other addons put on the minimap ]]
local lib = Mock.NewLibDBIcon()
local bag = lib:Create('Bagsmith')
local coin = lib:Create('Coinkeeper', { label = '|cff00ff00Coin|rkeeper' })
local hidden = lib:Create('Hiddenone', { hide = true })
local fader = lib:Create('Fader', { fade = true })

local hour, hourIcon, hourBorder = hourstoneLike('HourstoneMinimapButton', 'Hourstone')
Mock.addonTitles.Hourstone = 'Hourstone - Azeroth Hours'

-- Umbra builds its textures from paths and keeps no fields.
Mock.tainting = 'UmbraUnitFrames'
local umbra = CreateFrame('Button', 'UmbraMinimapButton', Minimap)
Mock.tainting = nil
Mock.addonTitles.UmbraUnitFrames = '|cff8080ffUmbra|r Unit Frames'
umbra:SetSize(31, 31)
umbra:SetPoint('CENTER', Minimap, 'CENTER', -52, 52)
local umbraGround = umbra:CreateTexture(nil, 'BACKGROUND')
umbraGround:SetTexture('Interface\\Minimap\\UI-Minimap-Background')
umbraGround:SetSize(24, 24)
local umbraIcon = umbra:CreateTexture(nil, 'ARTWORK')
umbraIcon:SetTexture('Interface\\AddOns\\UmbraUnitFrames\\Media\\logo')
umbraIcon:SetSize(18, 18)
umbraIcon:SetPoint('CENTER')
local umbraBorder = umbra:CreateTexture(nil, 'OVERLAY')
umbraBorder:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
umbraBorder:SetSize(50, 50)
umbra:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

local backdropButton = hourstoneLike('OldStyleMinimapButton', 'Backdropper', MinimapBackdrop)

-- A LibDBIcon button another addon has already put somewhere else.
local barred = lib:Create('Barred')
local someBar = CreateFrame('Frame', 'SomeButtonBar', UIParent)
barred:SetParent(someBar)

-- Like WIM: on its own events it sets strata and level along with its place.
local wim = hourstoneLike('WIM3MinimapButton', 'WIM')
function wim:UpdatePosition()
	self:SetFrameStrata(Minimap:GetFrameStrata())
	self:SetParent(Minimap)
	self:SetFrameLevel(8)
	self:ClearAllPoints()
	self:SetPoint('CENTER', Minimap, 'CENTER', 30, -60)
end
wim:UpdatePosition()

-- Things that are not buttons, or not ours to take.
plainFrame('Button', 'HandyNotesPin12', 'HandyNotes', 12, 12)
plainFrame('Button', 'GatherMateNodeHerb', 'GatherMate2', 16, 16)
local coords = plainFrame('Frame', 'MapCoordsText', 'Coords', 80, 14)
coords:SetScript('OnMouseUp', function() end)
local decoration = plainFrame('Frame', 'PrettyMinimapGlow', 'Pretty', 30, 30)
local secure = plainFrame('Button', 'SecureThingMinimapButton', 'Secure', 31, 31)
secure._protected = true
plainFrame('Button', nil, 'Anonymous', 31, 31)
plainFrame('Button', 'ExcludedMinimapButton', 'Excluded', 31, 31)
ns.db.excluded.ExcludedMinimapButton = true

--[[ Login ]]
Mock.fire('PLAYER_LOGIN')
local panel, launcher = ButtonstonePanel, ButtonstoneLauncher
check(ns.ready, 'ready after login')
check(panel and launcher, 'panel and main button exist')
check(not panel:IsShown(), 'the panel starts closed')

local gathered = {}
for _, record in ipairs(ns.Collector.records) do
	gathered[record.name] = record
end
for _, name in ipairs({ 'LibDBIcon10_Bagsmith', 'LibDBIcon10_Coinkeeper', 'LibDBIcon10_Hiddenone', 'LibDBIcon10_Fader',
	'HourstoneMinimapButton', 'UmbraMinimapButton', 'OldStyleMinimapButton', 'WIM3MinimapButton' }) do
	check(gathered[name], 'gathered ' .. name)
end
for _, name in ipairs({ 'HandyNotesPin12', 'GatherMateNodeHerb', 'MapCoordsText', 'PrettyMinimapGlow',
	'SecureThingMinimapButton', 'ExcludedMinimapButton', 'MiniMapTracking', 'GameTimeFrame', 'ButtonstoneLauncher',
	'LibDBIcon10_Barred' }) do
	check(not gathered[name], 'left alone: ' .. name)
end
equal(#ns.Collector.records, 8, 'gathered count')
check(decoration:GetParent() == Minimap, 'a decoration without a click stays where it was')
equal(barred:GetParent(), someBar, 'a LibDBIcon button another addon moved stays with it')
equal(ns.Collector.rival, nil, 'no other collector loaded')

-- Seen with WIM on TBC Anniversary: addons read their gathered button's place on events.
check(panel:GetNumPoints() > 0, 'the panel is anchored before it is ever opened')
check(type(wim:GetLeft()) == 'number', 'a gathered button has a place on the screen while the panel is closed')

equal(gathered.LibDBIcon10_Bagsmith.label, 'Bagsmith', 'LibDBIcon name')
equal(gathered.LibDBIcon10_Coinkeeper.label, 'Coinkeeper', 'LibDataBroker label without colour codes')
equal(gathered.HourstoneMinimapButton.label, 'Hourstone - Azeroth Hours', 'title of the addon that made it')
equal(gathered.UmbraMinimapButton.label, 'Umbra Unit Frames', 'title without colour codes')
equal(gathered.OldStyleMinimapButton.label, 'Backdropper', 'addon name when there is no title')
equal(gathered.LibDBIcon10_Bagsmith.source, 'lib', 'source of a LibDBIcon button')
equal(gathered.UmbraMinimapButton.source, 'own', 'source of an own button')

--[[ Taken into the panel and kept there ]]
for name, record in pairs(gathered) do
	local button = record.button
	equal(button:GetParent(), record.slot, name .. ' sits in its slot')
	equal(record.slot:GetParent(), panel, name .. ' slot belongs to the panel')
	equal(button:GetScript('OnDragStart'), nil, name .. ' cannot be dragged')
	equal(button:GetFrameStrata(), 'HIGH', name .. ' strata')
	check(button:GetFrameLevel() > record.slot:GetFrameLevel(), name .. ' above its plate')
end
check(not bag:HasFixedFrameStrata() and not bag:HasFixedFrameLevel(), 'fixed strata and level lifted')

local slot = bag:GetParent()
bag:SetPoint('CENTER', Minimap, 'CENTER', 50, 50)
bag:ClearAllPoints()
bag:SetParent(Minimap)
lib:Refresh('Bagsmith')
equal(bag:GetParent(), slot, 'SetParent from outside does nothing')
equal(bag:GetNumPoints(), 1, 'one point')
equal(select(2, bag:GetPoint(1)), slot, 'still centred in its slot')

local wimSlot = wim:GetParent()
wim:UpdatePosition()
equal(wim:GetParent(), wimSlot, 'WIM-like button stays in its slot')
equal(wim:GetFrameStrata(), 'HIGH', 'its own SetFrameStrata does not send it behind the panel')
check(wim:GetFrameLevel() > wimSlot:GetFrameLevel(), 'its own SetFrameLevel does not either')

equal(fader.showOnMouseover, false, 'LibDBIcon fading off while gathered')
equal(fader:GetAlpha(), 1, 'faded button visible')

--[[ The uniform look ]]
equal(bag.icon:GetWidth(), ICON, 'icon at slot size')
equal((bag.icon:GetPoint(1)), 'CENTER', 'icon centred')
equal(bag:GetWidth(), 32, 'button at slot size')
for _, region in ipairs(texturesOf(bag, bag.icon)) do
	equal(region:GetAlpha(), 0, 'LibDBIcon decoration hidden')
end
equal(hourIcon:GetNumMaskTextures(), 0, 'round mask taken off')
equal(hourBorder:GetAlpha(), 0, 'own border hidden')
equal(umbraIcon:GetWidth(), ICON, 'icon found without a field')
equal(umbraGround:GetAlpha(), 0, 'disc found by its path')
equal(umbraBorder:GetAlpha(), 0, 'border found by its path')
equal(umbra:GetHighlightTexture():GetAlpha(), 0, 'round highlight hidden')
local bagSlotNow = gathered.LibDBIcon10_Bagsmith.slot
if skin == 'retail' then
	check(bagSlotNow.plate:GetTexture():find('ActionNormal', 1, true), 'Retail plate')
elseif skin == 'classic' then
	equal(#bagSlotNow.visual, 9, 'Classic plate is a nine-slice')
elseif expect.art then
	equal(bagSlotNow.frameArt.normal:GetAtlas(), 'UI-HUD-ActionBar-IconFrame', "Forever's icon frame")
	check(bagSlotNow.visual[1]:GetFrameLevel() > bag:GetFrameLevel(), 'icon frame above the button')
	check(not bagSlotNow.frameArt.pushed:IsShown() and not bagSlotNow.frameArt.highlight:IsShown(), 'icon frame at rest')
else
	equal(#bagSlotNow.wellLines, 4, 'flat well with a one-pixel outline')
end

--[[ Layout ]]
local function size()
	return panel:GetWidth(), panel:GetHeight()
end
equal(#ns.Bundle.shown, 7, 'a hidden button takes no place')
check(not gathered.LibDBIcon10_Hiddenone.slot:IsShown(), 'its slot is hidden')
local order = {}
for i, record in ipairs(ns.Bundle.shown) do
	order[i] = record.label
end
equal(table.concat(order, ', '), 'Backdropper, Bagsmith, Coinkeeper, Fader, Hourstone - Azeroth Hours, Umbra Unit Frames, WIM', 'sorted by name')
local width, height = size()
local titleWidth, countWidth = #ns.L.PANEL_TITLE * 6, #ns.Bundle.count:GetText() * 6
local headerWidth
if skin ~= 'forever' then
	headerWidth = 2 * (m.padX - 1) + 18 + 5 + titleWidth + 5 + countWidth + 8 + 15
elseif expect.art then
	headerWidth = 2 * (8 + 32 + 6) + titleWidth + 4 + countWidth
else
	headerWidth = 2 * (m.padX - 1) + 18 + 5 + titleWidth + 4 + countWidth + 8 + 15
end
equal(ns.Bundle:HeaderWidth(), headerWidth, 'header needs logo, title, count and gear side by side')
equal(width, math.max(4 * 32 + 3 * 4 + 2 * m.padX, m.minWidth, headerWidth), 'width for four columns and the header')
equal(height, m.padTopHeader + 2 * 32 + 4 + m.padBottom, 'height for two rows')
local point, relative, _, x, y = ns.Bundle.shown[1].slot:GetPoint(1)
equal(point, 'TOPLEFT', 'slot anchor')
equal(relative, panel, 'slot anchored to the panel')
equal(x, (width - 140) / 2, 'grid centred')
equal(y, -m.padTopHeader, 'first row below the header')
_, _, _, x, y = ns.Bundle.shown[5].slot:GetPoint(1)
equal(x, (width - 140) / 2, 'fifth slot starts the second row')
equal(y, -(m.padTopHeader + 36), 'second row')
equal(ns.Bundle.count:GetText(), (expect.locale == 'deDE' and '7 Buttons' or '7 buttons'), 'count in the header')

hidden:Show()
equal(#ns.Bundle.shown, 8, 'shown later, placed at once')
hidden:Hide()
equal(#ns.Bundle.shown, 7, 'hidden again, gone at once')

local late = lib:Create('Questline')
check(ns.Collector.byButton[late], 'a LibDBIcon button made after login is gathered')
equal(#ns.Bundle.shown, 8, 'and placed')

Mock.tainting = 'Ondemand'
local onDemand = hourstoneLike('OndemandMinimapButton', 'Ondemand')
Mock.tainting = nil
check(not ns.Collector.byButton[onDemand], 'not seen before anyone looks')
Mock.fire('ADDON_LOADED', 'Ondemand')
check(ns.Collector.byButton[onDemand], 'an addon loaded later is looked at')

ns.db.panel.header = false
ns.Bundle:Layout()
equal(#ns.Bundle.shown, 9, 'nine shown')
equal(select(2, size()), m.padTop + 3 * 32 + 2 * 4 + m.padBottom, 'no header, less height')
check(not ns.Bundle.header:IsShown() and not (ns.Bundle.rule and ns.Bundle.rule:IsShown()), 'header hidden')
ns.db.panel.header = true
ns.db.panel.columns = 8
ns.Bundle:Layout()
equal(select(2, size()), m.padTopHeader + 2 * 32 + 4 + m.padBottom, 'two rows with eight columns')
equal(size(), math.max(8 * 32 + 7 * 4 + 2 * m.padX, ns.Bundle:HeaderWidth()), 'eight columns wide')
ns.db.panel.columns = 4
ns.Bundle:Layout()

--[[ The surface ]]
local function regionsUsing(frame, name)
	local found = 0
	for _, region in ipairs({ frame:GetRegions() }) do
		local texture = region.GetTexture and region:GetTexture()
		if type(texture) == 'string' and texture:find(name, 1, true) then
			found = found + 1
		end
	end
	return found
end
if skin ~= 'forever' then
	equal(ns.Bundle.surfaces, nil, 'no Forever surfaces elsewhere')
	equal(regionsUsing(panel, skin == 'retail' and 'RetailPanel' or 'ClassicPanel'), 9, 'the sprite frame')
elseif expect.art then
	local surfaces = ns.Bundle.surfaces
	equal(regionsUsing(panel, 'Panel'), 0, 'no sprite frame on Forever')
	local strip, stripBand = surfaces.strip.border.pieces, surfaces.band.border.pieces
	local layout = NineSliceLayouts.ButtonFrameTemplateNoPortrait
	equal(strip.topLeft:GetAtlas(), layout.TopLeftCorner.atlas, "cut from Blizzard's own pieces")
	near(strip.topLeft:GetHeight(), 5 + ns.Forever.STRIP, 'top pieces keep the title strip')
	near(strip.top:GetHeight(), 5 + ns.Forever.STRIP, 'top edge keeps the title strip')
	equal(strip.bottomLeft:GetHeight(), 8 - layout.BottomLeftCorner.y, 'bottom corners keep their lowest 8 units')
	equal((strip.left:GetPoint(1)), 'TOPLEFT', 'left edge starts under the top corner')
	equal(select(2, strip.left:GetPoint(1)), strip.topLeft, 'left edge hangs from the top corner')
	equal(select(2, strip.left:GetPoint(2)), strip.bottomLeft, 'and ends on the bottom corner')
	equal(Mock.cropped, nil, "Blizzard's corner cropping is not needed")
	check(panel:GetHeight() > ns.Forever.STRIP + 8, 'even one row leaves room for strip and bottom')
	near(stripBand.topLeft:GetHeight(), 5 + ns.Forever.BAND, 'the band keeps 8 units')
	check(surfaces.strip.border:GetFrameLevel() > panel:GetFrameLevel() + 5, 'the frame lies above the content')
	check(surfaces.strip.border:IsShown() and not surfaces.band.border:IsShown(), 'with the header: the frame with its strip')
	equal(regionsUsing(panel, 'UI-Background-Rock'), 2, 'rock ground under strip and band')
	equal(ns.Bundle.gear._template, 'UIPanelButtonTemplate', "the gear as Forever's red header button")
	equal(ns.Bundle.gear.symbol:GetTexture(), ns.Theme.GEAR, 'with the client gear')
	equal(ns.Theme.GEAR, 'Interface\\WorldMap\\GEAR_64GREY', 'the client gear is GEAR_64GREY')
	local point, relative = ns.Bundle.title:GetPoint(1)
	equal(point, 'TOP', 'title in the strip')
	equal(relative, surfaces.strip.border, 'title on the frame')
	equal(ns.Bundle.rule, nil, "the frame's separator takes the rule's place")
	ns.db.panel.header = false
	ns.Bundle:Layout()
	check(surfaces.band.border:IsShown() and not surfaces.strip.border:IsShown(), 'without the header: the band')
	local bandPieces = 0
	for _, region in ipairs({ surfaces.band.border:GetRegions() }) do
		if region:GetAtlas() then
			bandPieces = bandPieces + 1
		end
	end
	equal(bandPieces, 8, 'the band is cut from the eight pieces of the frame')
	ns.db.panel.header = true
	ns.Bundle:Layout()
else
	local surfaces = ns.Bundle.surfaces
	check(surfaces.flat and not surfaces.strip, 'no art: the flat plate')
	check(ns.Bundle.rule and ns.Bundle.rule:IsShown(), 'flat look has a rule')
	equal(ns.Bundle.gear._template, nil, 'flat gear')
end

--[[ Giving back ]]
local hourRecord = gathered.HourstoneMinimapButton
ns.Collector:SetExcluded('HourstoneMinimapButton', true)
check(ns.db.excluded.HourstoneMinimapButton, 'exclusion saved')
check(not ns.Collector.byButton[hour], 'released')
equal(hour:GetParent(), Minimap, 'parent back')
equal(rawget(hour, 'SetPoint'), nil, 'own SetPoint shows through again')
point, relative, _, x, y = hour:GetPoint(1)
equal(relative, Minimap, 'point back')
equal(x, 52, 'offset back')
equal(hour:GetWidth(), 31, 'size back')
equal(hourIcon:GetNumMaskTextures(), 1, 'mask back')
equal(hourIcon:GetWidth(), 18, 'icon size back')
equal((hourIcon:GetPoint(1)), 'TOPLEFT', 'icon point back')
equal(hourBorder:GetAlpha(), 1, 'border back')
equal(hour:GetHighlightTexture():GetAlpha(), 1, 'highlight back')
check(hour:GetScript('OnClick'), 'click kept')
hour:SetPoint('CENTER', Minimap, 'CENTER', 1, 2)
equal(select(4, hour:GetPoint(1)), 1, 'its own methods work again')
equal(hourRecord.slot, nil, 'slot freed')

local bagRecord = gathered.LibDBIcon10_Bagsmith
local bagSlot = bagRecord.slot
ns.Collector:SetExcluded('LibDBIcon10_Bagsmith', true)
check(bag:HasFixedFrameStrata() and bag:HasFixedFrameLevel(), 'fixed strata and level back')
equal(bag:GetFrameStrata(), 'MEDIUM', 'strata back')
equal(bag:GetFrameLevel(), 8, 'level back')
check(bag:GetScript('OnDragStart'), 'drag back')
equal(bag.icon:GetWidth(), libIcon, 'LibDBIcon icon size back')
equal(bag:GetParent(), Minimap, 'LibDBIcon parent back')
check(not bagSlot:IsShown(), 'freed slot hidden')
ns.Collector:SetExcluded('LibDBIcon10_Fader', true)
equal(fader.showOnMouseover, true, 'fading back')
equal(fader:GetAlpha(), 0, 'alpha back')

ns.Collector:SetExcluded('HourstoneMinimapButton', false)
check(not ns.db.excluded.HourstoneMinimapButton, 'exclusion removed')
check(ns.Collector.byButton[hour], 'taken again')
equal(hourIcon:GetWidth(), ICON, 'uniform again')

ns.db.panel.uniform = false
ns.Bundle:Refresh()
equal(coin.icon:GetWidth(), libIcon, 'original look: icon size')
equal(coin:GetWidth(), 31, 'original look: button size')
for _, region in ipairs(texturesOf(coin, coin.icon)) do
	equal(region:GetAlpha(), 1, 'original look: decoration shown')
end
check(not gathered.LibDBIcon10_Coinkeeper.slot.visual[1]:IsShown(), 'original look: no plate')
ns.db.panel.uniform = true
ns.Bundle:Refresh()
equal(coin.icon:GetWidth(), ICON, 'uniform again')
check(gathered.LibDBIcon10_Coinkeeper.slot.visual[1]:IsShown(), 'plate again')

-- Hover and press on the plate.
local coinSlot = gathered.LibDBIcon10_Coinkeeper.slot
Mock.run(coin, 'OnEnter')
if skin == 'retail' then
	check(coinSlot.plate:GetTexture():find('ActionHover', 1, true), 'hover plate')
	Mock.run(coin, 'OnMouseDown')
	check(coinSlot.plate:GetTexture():find('ActionPressed', 1, true), 'pressed plate')
	Mock.run(coin, 'OnLeave')
	check(coinSlot.plate:GetTexture():find('ActionNormal', 1, true), 'plate back')
elseif skin == 'classic' then
	check(coinSlot.glow:IsShown(), 'hover glow')
	Mock.run(coin, 'OnLeave')
	check(not coinSlot.glow:IsShown(), 'glow off')
elseif expect.art then
	local art = coinSlot.frameArt
	check(art.highlight:IsShown() and art.normal:IsShown(), "Forever's hover highlight")
	Mock.run(coin, 'OnMouseDown')
	check(art.pushed:IsShown() and not art.normal:IsShown(), "Forever's pressed frame")
	Mock.run(coin, 'OnLeave')
	check(art.normal:IsShown() and not art.pushed:IsShown() and not art.highlight:IsShown(), 'frame at rest again')
else
	local color = { coinSlot.wellLines[1]:GetVertexColor() }
	near(color[1], 240 / 255, 'flat well lights up in the accent')
	Mock.run(coin, 'OnLeave')
	color = { coinSlot.wellLines[1]:GetVertexColor() }
	near(color[1], 104 / 255, 'and goes back to bronze')
end

--[[ The main button ]]
local rim = 70 + 5
equal(launcher:GetParent(), Minimap, 'on the minimap')
point, relative, _, x, y = launcher:GetPoint(1)
equal(relative, Minimap, 'anchored to the minimap')
near(x, math.cos(math.rad(215)) * rim, 'lower left: x')
near(y, math.sin(math.rad(215)) * rim, 'lower left: y')
equal(launcher.icon:GetTexture(), 'Interface\\AddOns\\Buttonstone\\Media\\Logo', 'logo')

Mock.shape = 'SQUARE'
ns.Launcher:Place()
_, _, _, x, y = launcher:GetPoint(1)
near(x, -rim, 'square minimap: on the left edge')
check(math.abs(y) < rim, 'square minimap: inside the corner')
Mock.shape = 'ROUND'

Mock.cursor = { 1800, 960 + 100 }
Mock.time = 100
ns.Launcher:StartDrag()
Mock.run(launcher, 'OnUpdate', 0.1)
ns.Launcher:StopDrag()
near(ns.db.launcher.angle, 90, 'dragged to the top')
Mock.run(launcher, 'OnClick', 'LeftButton')
check(not panel:IsShown(), 'the click ending a drag does not open the panel')

Mock.time = 101
Mock.run(launcher, 'OnClick', 'LeftButton')
check(panel:IsShown(), 'a click opens the panel')
point, relative = panel:GetPoint(1)
equal(point, 'TOPRIGHT', 'opens down and to the left from the top right of the screen')
equal(relative, launcher, 'next to the main button')

Mock.hover = nil
Mock.run(panel, 'OnUpdate', 0.3)
check(panel:IsShown(), 'not closed at once')
Mock.run(panel, 'OnUpdate', 0.4)
check(not panel:IsShown(), 'closed after the mouse left')

Mock.run(launcher, 'OnClick', 'LeftButton')
Mock.hover = gathered.LibDBIcon10_Coinkeeper.button
Mock.run(panel, 'OnUpdate', 1)
check(panel:IsShown(), 'kept open with the mouse over a gathered button')
Mock.hover = nil
ns.db.panel.autoClose = false
Mock.run(panel, 'OnUpdate', 1)
check(panel:IsShown(), 'kept open when auto-close is off')
ns.db.panel.autoClose = true
Mock.run(launcher, 'OnClick', 'LeftButton')
check(not panel:IsShown(), 'a second click closes it')

local escape = false
for _, name in ipairs(UISpecialFrames) do
	escape = escape or name == 'ButtonstonePanel'
end
check(escape, 'Escape closes the panel')

ns.db.panel.direction = 'up-right'
ns.Bundle:Anchor()
equal((panel:GetPoint(1)), 'BOTTOMLEFT', 'direction from the settings')
ns.db.panel.direction = 'auto'

Mock.run(launcher, 'OnClick', 'RightButton')
check(ButtonstoneOptions and ButtonstoneOptions:IsShown(), 'right-click opens the options')
Mock.run(launcher, 'OnClick', 'RightButton')
check(not ButtonstoneOptions:IsShown(), 'and closes them again')

Mock.run(launcher, 'OnEnter')
equal(GameTooltip._owner, launcher, 'tooltip on the main button')
equal(GameTooltip._lines[1], ns.L.TITLE, 'tooltip title')
equal(GameTooltip._lines[2], ns.L.TIP_CLICK, 'tooltip click line')
equal(GameTooltip._lines[3], ns.L.TIP_RIGHT, 'tooltip right-click line')
equal(GameTooltip._lines[4], ns.L.TIP_DRAG, 'tooltip drag line')

--[[ Detached ]]
SlashCmdList.BUTTONSTONE('detach')
equal(launcher:GetParent(), UIParent, 'detached onto the screen')
equal(ns.db.launcher.attached, false, 'saved as detached')
near(ns.db.launcher.free.x, 1800, 'stays where it was: x')
near(ns.db.launcher.free.y, 960 + rim, 'stays where it was: y')
ns.db.launcher.free = { x = 100, y = 100 }
ns.Launcher:Place()
ns.Bundle:Anchor()
equal((panel:GetPoint(1)), 'BOTTOMLEFT', 'lower left of the screen: opens up and to the right')
launcher._center = { 300, 200 }
ns.Launcher:StartDrag()
ns.Launcher:StopDrag()
launcher._center = nil
near(ns.db.launcher.free.x, 300, 'dragged freely: x saved')
SlashCmdList.BUTTONSTONE('attach')
equal(launcher:GetParent(), Minimap, 'back on the minimap')
SlashCmdList.BUTTONSTONE('reset')
equal(ns.db.launcher.angle, 215, 'reset angle')
equal(ns.db.launcher.free, nil, 'reset free position')

Mock.printed = {}
SlashCmdList.BUTTONSTONE('list')
check(Mock.printed[1]:find('(' .. #ns.Collector.records .. ')', 1, true), 'list header with the count')
local listed = table.concat(Mock.printed, '\n')
check(listed:find('Hiddenone (LibDBIcon, ' .. ns.L.LIST_HIDDEN .. ')', 1, true), 'hidden buttons marked')
check(listed:find('Umbra Unit Frames (Minimap)', 1, true), 'own buttons listed')

return passed

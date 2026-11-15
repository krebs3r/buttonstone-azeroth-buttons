--[[ The options window, once per client
Runs after test_collector.lua in the same Lua state: buttons are gathered,
three names are excluded (Bagsmith, Fader and ExcludedMinimapButton).
--]]
local _, ns = ...
local expect = Mock.expect
local skin = ns.Theme.Skin()
local L = ns.L
local passed = 0

local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local function equal(actual, wanted, message)
	assert(actual == wanted, (message or 'value') .. ': wanted ' .. tostring(wanted) .. ', got ' .. tostring(actual))
	passed = passed + 1
end

local options, panel, launcher = ButtonstoneOptions, ButtonstonePanel, ButtonstoneLauncher
local click = Mock.click

--[[ Opening ]]
check(options and not options:IsShown(), 'built by the earlier right-click, closed now')
SlashCmdList.BUTTONSTONE('')
check(options:IsShown(), '/bst alone opens the options')
SlashCmdList.BUTTONSTONE('')
check(not options:IsShown(), 'and closes them')
Mock.run(ns.Bundle.gear, 'OnClick')
check(options:IsShown(), "the panel's gear opens them")
local escape = false
for _, name in ipairs(UISpecialFrames) do
	escape = escape or name == 'ButtonstoneOptions'
end
check(escape, 'Escape closes the options')
equal(options:GetFrameStrata(), 'DIALOG', 'above the panel')

local c = ns.Options.controls

--[[ The look ]]
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
	equal(regionsUsing(options, skin == 'retail' and 'RetailPanel' or 'ClassicPanel'), 9, 'the sprite frame')
	equal(regionsUsing(ns.Options.close, 'HeaderClose'), 1, "Soundstone's close button")
	equal(regionsUsing(c.size, skin == 'retail' and 'ControlRetail' or 'ControlClassic'), 9, 'stepper in the control sprite')
	equal(c.done._template, nil, 'sprite push button')
	equal(c.reset:GetWidth(), math.max(100, #L.RESET_POSITION * 6 + 28), 'push button as wide as its label')
	equal(c.done.label:GetText(), L.DONE, 'push button label')
	equal(regionsUsing(options, 'Rivet'), 6, "Soundstone's grip")
elseif expect.art then
	check(ns.Options.surface.border.pieces.topLeft, "Forever's frame, cut to the window")
	equal(ns.Options.close._normalAtlas, 'RedButton-Exit', "Forever's red close button")
	local holder
	for _, region in ipairs({ c.size:GetRegions() }) do
		holder = holder or (region:GetAtlas() == 'common-dropdown-textholder' and region)
	end
	check(holder, "stepper in Forever's field art")
	equal(c.done._template, 'UIPanelButtonTemplate', "Blizzard's push button")
	equal(c.done:GetText(), L.DONE, 'push button label')
	equal((ns.Options.title:GetPoint(1)), 'TOP', 'title centred in the strip')
else
	check(ns.Options.close.cross, 'flat close button')
	equal(regionsUsing(c.size, ns.Theme.WHITE), 5, 'flat stepper: a well and four lines')
	equal(regionsUsing(options, 'Panel'), 0, 'no sprite frame')
end
equal(c.attached._template, 'UICheckButtonTemplate', "the client's own checkboxes")
equal(c.columns:GetWidth(), c.direction:GetWidth(), 'steppers as wide as the direction field')
local _, _, _, doneX = c.done:GetPoint(1)
equal(select(2, c.done:GetPoint(1)), c.reset, 'done sits right of reset')
equal(doneX, 8, 'with a gap')
check(c.footer:GetText():find('dev', 1, true), 'version in the footer')

--[[ The main button ]]
equal(c.attached:GetChecked(), true, 'keep box shows the setting')
click(c.attached)
equal(ns.db.launcher.attached, false, 'unticked: detached')
equal(launcher:GetParent(), UIParent, 'the button left the minimap')
click(c.attached)
equal(launcher:GetParent(), Minimap, 'ticked: back on the minimap')
if expect.compartment then
	check(c.compartment and c.compartment:GetChecked(), 'Addons menu box, ticked')
	click(c.compartment)
	equal(ns.db.compartment, false, 'Addons menu entry off')
	click(c.compartment)
	equal(ns.db.compartment, true, 'and on')
	local entry = AddonCompartmentFrame.registered[#AddonCompartmentFrame.registered]
	equal(entry.text, L.TITLE, 'listed in the Addons menu at login')
	entry.func(nil, 'LeftButton')
	check(panel:IsShown(), 'a click there shows the buttons')
	ns.Bundle:Close()
	entry.func(nil, { buttonName = 'RightButton' })
	check(not options:IsShown(), 'a right-click there toggles the options')
	entry.func(nil, 'RightButton')
	check(options:IsShown(), 'and back')
else
	equal(c.compartment, nil, 'no Addons menu box where the client has no menu')
end

--[[ The panel's settings ]]
equal(c.columns.text:GetText(), '4', 'columns shown')
click(c.columns.plus)
click(c.columns.plus)
equal(ns.db.panel.columns, 6, 'two steps up: six columns')
equal(c.columns.text:GetText(), '6', 'and shown')
equal(#ns.Bundle.shown >= 6 and select(2, ns.Bundle.shown[6].slot:GetPoint(1)) == panel, true, 'laid out again')
click(c.columns.plus)
click(c.columns.plus)
equal(ns.db.panel.columns, 8, 'up to eight')
check(not c.columns.plus:IsEnabled(), 'no step past eight')
click(c.columns.plus)
equal(ns.db.panel.columns, 8, 'stays at eight')
for _ = 1, 4 do
	click(c.columns.minus)
end
equal(ns.db.panel.columns, 4, 'back to four')
click(c.size.plus)
click(c.size.plus)
equal(ns.db.panel.size, 120, 'size in steps of ten')
equal(panel:GetScale(), 1.2, 'panel scaled')
equal(c.size.text:GetText(), L.PERCENT:format(120), 'size shown')
click(c.size.minus)
click(c.size.minus)
equal(ns.db.panel.size, 100, 'size back')
ns.db.panel.size = 105
ns.Options:Refresh()
click(c.size.minus)
equal(ns.db.panel.size, 100, 'from between two steps, down to the step below')
ns.db.panel.size = 105
ns.Options:Refresh()
click(c.size.plus)
equal(ns.db.panel.size, 110, 'and up to the step above')
click(c.size.minus)

if skin == 'forever' and expect.art then
	-- Forever: Blizzard's own dropdown and menu.
	local field = c.direction
	equal(field._template, 'WowStyle1DropdownTemplate', "Blizzard's dropdown on Forever")
	equal(field._override, L.DIR_auto, 'the setting shown')
	local radios = field._menu.radios
	equal(#radios, 5, 'five directions in the menu')
	equal(radios[5].text, L['DIR_up-right'], 'localised')
	check(radios[1].isSelected(radios[1].data) and not radios[5].isSelected(radios[5].data), 'the current one marked')
	equal(radios[5].setSelected(radios[5].data), MenuResponse.Close, 'choosing closes the menu')
	equal(ns.db.panel.direction, 'up-right', 'direction chosen')
	equal(field._override, L['DIR_up-right'], 'choice shown')
	check(field._menu.radios[5].isSelected('up-right'), 'and marked')
	equal((panel:GetPoint(1)), 'BOTTOMLEFT', 'panel anchored the new way')
	field._menu.radios[1].setSelected('auto')
	equal(ns.db.panel.direction, 'auto', 'back to automatic')
else
	equal(c.direction.native, nil, 'own list where Blizzard\'s menu is not used')
	click(c.direction)
	check(c.direction.popup:IsShown(), 'the direction list opens')
	click(c.direction.rows[5])
	equal(ns.db.panel.direction, 'up-right', 'direction chosen')
	check(not c.direction.popup:IsShown(), 'list closed after a choice')
	equal(c.direction.label:GetText(), L['DIR_up-right'], 'choice shown')
	equal((panel:GetPoint(1)), 'BOTTOMLEFT', 'panel anchored the new way')
	click(c.direction)
	Mock.hover = nil
	Mock.run(c.direction.popup, 'OnEvent', 'GLOBAL_MOUSE_DOWN')
	check(not c.direction.popup:IsShown(), 'a click elsewhere closes the list')
	click(c.direction)
	click(c.direction.rows[1])
	equal(ns.db.panel.direction, 'auto', 'back to automatic')
end

local coin = LibDBIcon10_Coinkeeper
click(c.uniform)
equal(ns.db.panel.uniform, false, 'uniform slots off')
equal(coin:GetWidth(), 31, 'buttons in their own look')
click(c.uniform)
equal(coin:GetWidth(), 32, 'uniform again')
click(c.header)
equal(ns.db.panel.header, false, 'header off')
check(not ns.Bundle.header:IsShown(), 'header hidden')
click(c.header)
check(ns.Bundle.header:IsShown(), 'header back')
click(c.autoClose)
equal(ns.db.panel.autoClose, false, 'auto-close off')
click(c.autoClose)
equal(ns.db.panel.autoClose, true, 'auto-close on')

--[[ The list of buttons ]]
local entries = ns.Options.entries
local excluded = 0
for name in pairs(ns.db.excluded) do
	if not ns.Collector:Find(name) then
		excluded = excluded + 1
	end
end
equal(excluded, 3, 'three names excluded')
equal(#entries, #ns.Collector.records + excluded, 'gathered and excluded buttons listed')
equal(c.buttons:GetText(), L.SEC_BUTTONS:format(#entries), 'count in the heading')
for i = 2, #entries do
	check(entries[i - 1].label:lower() <= entries[i].label:lower(), 'sorted by name')
end

local rows = ns.Options.list.rows
local function rowOf(name)
	for i, entry in ipairs(entries) do
		if entry.name == name then
			return rows[i], i
		end
	end
end
local row, index = rowOf('LibDBIcon10_Bagsmith')
check(row and index <= 6, 'Bagsmith visible in the first rows')
equal(row.name:GetText(), 'Bagsmith', 'its name')
equal(row.check:GetChecked(), false, 'excluded: unticked')
equal(row.source:GetText(), L.SOURCE_lib, 'its source')
click(row.check)
check(ns.Collector:Find('LibDBIcon10_Bagsmith'), 'ticking it gathers it again')
equal(ns.db.excluded.LibDBIcon10_Bagsmith, nil, 'exclusion removed')
entries = ns.Options.entries
row = rowOf('LibDBIcon10_Bagsmith')
equal(row.check:GetChecked(), true, 'shown ticked')
click(row)
equal(ns.db.excluded.LibDBIcon10_Bagsmith, true, 'a click on the row excludes it again')
check(not ns.Collector:Find('LibDBIcon10_Bagsmith'), 'and gives it back')
entries = ns.Options.entries

local hiddenRow = rowOf('LibDBIcon10_Hiddenone')
check(hiddenRow.source:GetText():find(L.LIST_HIDDEN, 1, true), 'a hidden button is marked')
local iconTexture = rowOf('LibDBIcon10_Coinkeeper').icon:GetTexture()
equal(iconTexture, 'Interface\\Icons\\Coinkeeper', "the button's own icon in the list")

local list = ns.Options.list
check(#entries <= 12, 'up to twelve buttons')
check(not list.bar:IsShown(), 'no scroll bar for twelve or fewer')
equal(list:GetHeight(), #entries * 22, 'the list grows with its buttons')
equal(options:GetHeight(), ns.Options.listTop + #entries * 22 + 52 + ns.Options.inset - 2, 'and the window with it')

ns.db.excluded.GoneMinimapButton = true
ns.Options:Refresh()
local gone
for _, entry in ipairs(ns.Options.entries) do
	if entry.name == 'GoneMinimapButton' then
		gone = entry
	end
end
check(gone and gone.missing, "an excluded addon that is not loaded stays listed")
equal(gone.label, 'Gone', 'by its name')
equal(c.buttons:GetText(), L.SEC_BUTTONS:format(#ns.Options.entries - 1), 'not counted as found')

for i = 1, 6 do
	ns.db.excluded['Gone' .. i .. 'MinimapButton'] = true
end
ns.Options:Refresh()
entries = ns.Options.entries
check(#entries > 12, 'more than twelve')
equal(list:GetHeight(), 12 * 22, 'the list stops growing at twelve')
check(list.bar:IsShown(), "Blizzard's scroll bar shows")
equal(list.bar._template, 'UIPanelScrollBarTemplate', "the client's own scroll bar")
equal(select(2, list.bar:GetMinMaxValues()), #entries - 12, 'it scrolls as far as the list is longer')
Mock.run(list, 'OnMouseWheel', -1)
equal(rows[1].entry, entries[2], 'the wheel scrolls down a row')
equal(list.bar:GetValue(), 1, 'the scroll bar follows')
list.bar:SetValue(3)
equal(rows[1].entry, entries[4], 'the scroll bar scrolls the list')
Mock.run(list, 'OnMouseWheel', 20)
equal(rows[1].entry, entries[1], 'and not past the top')
check(rows[1]:GetWidth() < list:GetWidth(), 'rows make room for the bar')
for i = 1, 6 do
	ns.db.excluded['Gone' .. i .. 'MinimapButton'] = nil
end
ns.db.excluded.GoneMinimapButton = nil
ns.Options:Refresh()
check(not list.bar:IsShown(), 'bar gone again')

--[[ The buttons at the bottom ]]
ns.db.launcher.angle = 90
ns.Launcher:Place()
click(c.reset)
equal(ns.db.launcher.angle, 215, 'reset position')
click(c.done)
check(not options:IsShown(), 'done closes the window')

SlashCmdList.BUTTONSTONE('detach')
SlashCmdList.BUTTONSTONE('')
equal(c.attached:GetChecked(), false, 'the window follows /bst detach')
SlashCmdList.BUTTONSTONE('attach')
equal(c.attached:GetChecked(), true, 'and /bst attach while it is open')
options:Hide()

return passed

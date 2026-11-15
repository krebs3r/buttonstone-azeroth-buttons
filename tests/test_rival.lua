--[[ Another collector loaded: MinimapButtonButton
Two collectors cannot share the buttons (on TBC Anniversary MinimapButtonButton
pulled them out of Buttonstone's slots). Buttonstone leaves every button to
the other one, says so once and shows it in the panel.
--]]
local _, ns = ...
local passed = 0

local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local function equal(actual, wanted, message)
	assert(actual == wanted, (message or 'value') .. ': wanted ' .. tostring(wanted) .. ', got ' .. tostring(actual))
	passed = passed + 1
end

Mock.fire('ADDON_LOADED', 'Buttonstone')
local lib = Mock.NewLibDBIcon()
local bag = lib:Create('Bagsmith')
Mock.tainting = 'Hourstone'
local hour = CreateFrame('Button', 'HourstoneMinimapButton', Minimap)
Mock.tainting = nil
hour:SetSize(31, 31)
hour:SetScript('OnClick', function() end)

Mock.printed = {}
Mock.fire('PLAYER_LOGIN')
equal(ns.Collector.rival, 'MinimapButtonButton', 'the other collector is noticed')
equal(#ns.Collector.records, 0, 'nothing gathered')
equal(bag:GetParent(), Minimap, 'LibDBIcon button left on the minimap')
equal(hour:GetParent(), Minimap, 'own button left on the minimap')
equal(#Mock.printed, 1, 'one line in the chat')
check(Mock.printed[1]:find('MinimapButtonButton', 1, true), 'naming the other collector')

local later = lib:Create('Later')
Mock.fire('ADDON_LOADED', 'SomeOtherAddon')
equal(later:GetParent(), Minimap, 'later buttons are left alone too')
equal(#ns.Collector.records, 0, 'still nothing gathered')
equal(#Mock.printed, 1, 'said only once')

ns.Bundle:Open()
check(ButtonstonePanel:IsShown(), 'the panel still opens')
check(ns.Bundle.empty:IsShown(), 'and says why it is empty')
equal(ns.Bundle.empty:GetText(), ns.L.EMPTY_RIVAL:format('MinimapButtonButton'), 'naming the other collector')
check(ButtonstoneLauncher:GetParent() == Minimap, 'the main button is there')

return passed

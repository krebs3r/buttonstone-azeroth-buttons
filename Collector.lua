local _, ns = ...
local C = ns.Compat

--[[ Gathering minimap buttons, and giving them back
Two sources: every button LibDBIcon made (asked through its own list and
told about new ones by its callback), and named children of the minimap that
an addon made and that look like a button. Blizzard's own frames are never
taken here.

Taking a button means moving it into the panel and keeping it there:
SetPoint, ClearAllPoints, SetAllPoints, SetParent, SetFrameStrata and
SetFrameLevel are shadowed on the button itself, because many addons put
their button back on the rim on their own events, and some (WIM) set its
strata and level there too, which would hide it behind the panel.
Everything changed is written down first, so releasing a button restores
it exactly and needs no /reload: the shadowing fields are
removed (the widget's own methods show through again), and parent, points,
size, scale, strata, level, drag scripts and fading come back.
--]]
local Collector = {
	records = {},
	byButton = {},
}
ns.Collector = Collector

local BLOCKED = { 'SetPoint', 'ClearAllPoints', 'SetAllPoints', 'SetParent', 'SetFrameStrata', 'SetFrameLevel' }

-- Frames of Buttonstone's own; never gathered.
local OWN = { ButtonstoneLauncher = true, ButtonstonePanel = true }

-- Other addons that gather minimap buttons. Two collectors cannot share the
-- buttons: MinimapButtonButton places its buttons with UIParent.SetPoint, past
-- any shadowing, and pulled them out of Buttonstone's slots on TBC Anniversary.
-- With one of them loaded, Buttonstone leaves every button to it and says so.
local RIVALS = { 'MinimapButtonButton', 'MinimapButtonFrame', 'MBB' }

-- Map pins and markers drawn on the minimap by other addons, not buttons.
local NOT_BUTTONS = { 'pin', 'node', 'questie', 'handynotes', 'gathermate', 'tomtom', 'waypoint', 'blip', 'poi' }

local function noop() end

-- Calls a widget method if it exists and does not fail; nil otherwise.
local function try(object, method, ...)
	local f = object and object[method]
	if type(f) ~= 'function' then
		return nil
	end
	local ok, a, b, c, d, e = pcall(f, object, ...)
	if ok then
		return a, b, c, d, e
	end
	return nil
end
Collector.try = try

--[[ Names ]]
local function addonOf(name)
	if type(issecurevariable) ~= 'function' then
		return nil
	end
	local ok, secure, taint = pcall(issecurevariable, name)
	if ok and not secure and type(taint) == 'string' and taint ~= '' then
		return taint
	end
	return nil
end

local function plain(text)
	return (text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
end

-- What the panel and the options call a button: the LibDataBroker label, the
-- title of the addon that made it, or its frame name without the usual suffixes.
local function labelFor(button, name, libName)
	if libName then
		local object = rawget(button, 'dataObject')
		local label = type(object) == 'table' and object.label
		if type(label) == 'string' and label ~= '' then
			return plain(label)
		end
		return libName
	end
	local addon = addonOf(name)
	if addon then
		local read = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
		local ok, title = pcall(read, addon, 'Title')
		if ok and type(title) == 'string' and title ~= '' then
			return plain(title)
		end
		return addon
	end
	local stripped = name:gsub('[_]?[Mm]ini[Mm]ap[Bb]utton$', ''):gsub('[_]?[Mm]ini[Mm]ap[Ii]con$', ''):gsub('Button$', '')
	return stripped ~= '' and stripped or name
end

--[[ Which minimap children count as buttons
Named, made by an addon (Blizzard's frames are secure variables), not a map
pin (pins are numbered or named after their addon), not protected, roughly
square at minimap-button size, and clickable.
--]]
local function looksLikeButton(button, name)
	if name:find('%d$') then
		return false
	end
	if type(issecurevariable) == 'function' then
		local ok, secure = pcall(issecurevariable, name)
		if not ok or secure then
			return false
		end
	end
	local lower = name:lower()
	for _, word in ipairs(NOT_BUTTONS) do
		if lower:find(word, 1, true) then
			return false
		end
	end
	local width, height = try(button, 'GetSize')
	if type(width) ~= 'number' or type(height) ~= 'number' or C.IsSecret(width) or C.IsSecret(height) then
		return false
	end
	if width < 14 or height < 14 or width > 48 or height > 48 then
		return false
	end
	if math.max(width, height) > 1.5 * math.min(width, height) then
		return false
	end
	if try(button, 'IsObjectType', 'Button') then
		return true
	end
	return (try(button, 'GetScript', 'OnClick') or try(button, 'GetScript', 'OnMouseUp')
		or try(button, 'GetScript', 'OnMouseDown')) ~= nil
end

--[[ Taking and giving back ]]
local function capture(button)
	local saved = {
		parent = button:GetParent(),
		points = {},
		methods = {},
		scale = button:GetScale(),
		alpha = button:GetAlpha(),
		strata = button:GetFrameStrata(),
		level = button:GetFrameLevel(),
		fixedStrata = try(button, 'HasFixedFrameStrata'),
		fixedLevel = try(button, 'HasFixedFrameLevel'),
		ignoreScale = try(button, 'IsIgnoringParentScale'),
		dragStart = button:GetScript('OnDragStart'),
		dragStop = button:GetScript('OnDragStop'),
		showOnMouseover = rawget(button, 'showOnMouseover'),
	}
	saved.width, saved.height = button:GetSize()
	for i = 1, button:GetNumPoints() do
		saved.points[i] = { button:GetPoint(i) }
	end
	for _, method in ipairs(BLOCKED) do
		saved.methods[method] = rawget(button, method)
	end
	return saved
end

-- Visibility changes of a gathered button lay the panel out again. Hooked once
-- per button, for the session: a hook cannot be removed, so it asks first.
local hooked = setmetatable({}, { __mode = 'k' })
local function watch(button)
	if hooked[button] then
		return
	end
	hooked[button] = true
	local function changed(self)
		if Collector.byButton[self] then
			ns.Bundle:Layout()
		end
	end
	for _, method in ipairs({ 'Show', 'Hide', 'SetShown' }) do
		if type(button[method]) == 'function' then
			hooksecurefunc(button, method, changed)
		end
	end
	for _, script in ipairs({ 'OnEnter', 'OnLeave', 'OnMouseDown', 'OnMouseUp' }) do
		button:HookScript(script, function(self)
			local record = Collector.byButton[self]
			if record then
				ns.Bundle:SlotState(record, script)
			end
		end)
	end
end

function Collector:Gather(button, name, source, libName)
	if self.byButton[button] then
		return self.byButton[button]
	end
	local methods = getmetatable(button)
	methods = methods and methods.__index
	if type(methods) ~= 'table' then
		return nil
	end
	for _, method in ipairs(BLOCKED) do
		if type(methods[method]) ~= 'function' then
			return nil
		end
	end
	local ok, saved = pcall(capture, button)
	if not ok then
		return nil
	end

	local record = {
		button = button,
		name = name,
		source = source,
		label = labelFor(button, name, libName),
		saved = saved,
		methods = methods,
	}
	for _, method in ipairs(BLOCKED) do
		button[method] = noop
	end
	button:SetScript('OnDragStart', nil)
	button:SetScript('OnDragStop', nil)
	if saved.showOnMouseover then
		-- LibDBIcon fades such buttons out when the mouse leaves the minimap.
		button.showOnMouseover = false
		local fade = rawget(button, 'fadeOut')
		if type(fade) == 'table' then
			try(fade, 'Stop')
		end
		button:SetAlpha(1)
	end
	if saved.fixedStrata then
		button:SetFixedFrameStrata(false)
	end
	if saved.fixedLevel then
		button:SetFixedFrameLevel(false)
	end
	if saved.ignoreScale then
		button:SetIgnoreParentScale(false)
	end
	button:SetScale(1)
	watch(button)

	self.records[#self.records + 1] = record
	self.byButton[button] = record
	ns.Bundle:Adopt(record)
	return record
end

function Collector:Release(record)
	if not record or self.byButton[record.button] ~= record then
		return
	end
	ns.Bundle:Abandon(record)

	local button, saved, methods = record.button, record.saved, record.methods
	for _, method in ipairs(BLOCKED) do
		button[method] = saved.methods[method]
	end
	methods.SetParent(button, saved.parent)
	methods.ClearAllPoints(button)
	for _, point in ipairs(saved.points) do
		methods.SetPoint(button, unpack(point))
	end
	button:SetSize(saved.width, saved.height)
	button:SetScale(saved.scale)
	if saved.ignoreScale then
		button:SetIgnoreParentScale(true)
	end
	button:SetFrameStrata(saved.strata)
	button:SetFrameLevel(saved.level)
	if saved.fixedStrata then
		button:SetFixedFrameStrata(true)
	end
	if saved.fixedLevel then
		button:SetFixedFrameLevel(true)
	end
	button:SetScript('OnDragStart', saved.dragStart)
	button:SetScript('OnDragStop', saved.dragStop)
	if saved.showOnMouseover ~= nil then
		button.showOnMouseover = saved.showOnMouseover
	end
	button:SetAlpha(saved.alpha)

	self.byButton[button] = nil
	for i, other in ipairs(self.records) do
		if other == record then
			table.remove(self.records, i)
			break
		end
	end
	ns.Bundle:Layout()
end

function Collector:Find(name)
	for _, record in ipairs(self.records) do
		if record.name == name then
			return record
		end
	end
	return nil
end

-- Excluding gives a button back at once and keeps it out; including takes it again.
function Collector:SetExcluded(name, excluded)
	ns.db.excluded[name] = excluded and true or nil
	if excluded then
		self:Release(self:Find(name))
	else
		self:Scan()
	end
end

--[[ Looking for buttons ]]
local function libDBIcon()
	if type(LibStub) ~= 'table' then
		return nil
	end
	local lib = try(LibStub, 'GetLibrary', 'LibDBIcon-1.0', true)
	return type(lib) == 'table' and lib or nil
end

function Collector:Consider(button, source, libName)
	if type(button) ~= 'table' or self.byButton[button] then
		return
	end
	local name = try(button, 'GetName')
	if type(name) ~= 'string' or C.IsSecret(name) or OWN[name] or ns.db.excluded[name] then
		return
	end
	if try(button, 'IsForbidden') or try(button, 'IsProtected') then
		return
	end
	if source == 'own' and not looksLikeButton(button, name) then
		return
	end
	-- A LibDBIcon button another addon has already moved off the minimap is that addon's.
	local parent = try(button, 'GetParent')
	if parent ~= Minimap and parent ~= MinimapBackdrop then
		return
	end
	self:Gather(button, name, source, libName)
end

function Collector:Rival()
	local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
	if type(loaded) ~= 'function' then
		return nil
	end
	for _, name in ipairs(RIVALS) do
		local ok, isLoaded = pcall(loaded, name)
		if ok and isLoaded then
			return name
		end
	end
	return nil
end

function Collector:Scan()
	if not ns.db or self.rival then
		return
	end
	local lib = libDBIcon()
	if lib then
		if not self.listening and type(lib.RegisterCallback) == 'function' then
			self.listening = true
			lib.RegisterCallback(self, 'LibDBIcon_IconCreated', function(_, button, libName)
				Collector:Consider(button, 'lib', libName)
				ns.Bundle:Layout()
			end)
		end
		local ok, names = pcall(lib.GetButtonList, lib)
		if ok and type(names) == 'table' then
			for _, libName in ipairs(names) do
				self:Consider(lib:GetMinimapButton(libName), 'lib', libName)
			end
		end
	end
	for _, parent in ipairs({ Minimap, MinimapBackdrop }) do
		if type(parent) == 'table' and type(parent.GetChildren) == 'function' then
			for _, child in ipairs({ parent:GetChildren() }) do
				self:Consider(child, 'own')
			end
		end
	end
	ns.Bundle:Layout()
end

function Collector:Init()
	self.rival = self:Rival()
	if self.rival then
		ns.Chat(ns.L.RIVAL:format(self.rival))
		ns.Bundle:Layout()
		return
	end
	-- Addons make their buttons at login or a little later; look again then.
	self:Scan()
	C.After(1, function() Collector:Scan() end)
	C.After(3, function() Collector:Scan() end)
end

-- An addon loaded on demand may bring a button; look once it had time to make it.
function Collector:AddonLoaded()
	if self.pending then
		return
	end
	self.pending = true
	C.After(0.5, function()
		Collector.pending = nil
		Collector:Scan()
	end)
end

--[[ A small stand-in for the WoW API
Only what the addon's files touch. Frames keep their points, parents,
children, regions, scripts and hooks so the tests can look at them; nothing
is drawn and every effective scale is 1. Each client run sets
WOW_PROJECT_ID, Mock.interface and Mock.locale before the addon's files load
(tests/run.py).
--]]
Mock = {
	locale = 'enUS',
	interface = 120105,
	combat = false,
	time = 0,
	cursor = { 0, 0 },
	shape = 'ROUND',
	hover = nil,
	printed = {},
	frames = {},
	metadata = { Version = '@project-version@' },
	addonTitles = {},
	loaded = {},
	secure = {},
	taint = {},
	tainting = nil,
	fileIDs = {
		['interface\\minimap\\minimap-trackingborder'] = 136430,
		['interface\\minimap\\ui-minimap-background'] = 136467,
		['interface\\minimap\\ui-minimap-zoombutton-highlight'] = 136477,
	},
}

WOW_PROJECT_MAINLINE = 1
WOW_PROJECT_CLASSIC = 2

function GetLocale()
	return Mock.locale
end

function GetBuildInfo()
	return '0.0.0', '0', 'Jan 1 2026', Mock.interface
end

function GetTime()
	return Mock.time
end

function GetCursorPosition()
	return Mock.cursor[1], Mock.cursor[2]
end

function GetMinimapShape()
	return Mock.shape
end

C_AddOns = {
	IsAddOnLoaded = function(name)
		return Mock.loaded[name] == true
	end,
	GetAddOnMetadata = function(name, field)
		if name == 'Buttonstone' then
			return Mock.metadata[field]
		end
		if field == 'Title' then
			return Mock.addonTitles[name]
		end
		return nil
	end,
}

C_Timer = {
	After = function(_, callback)
		callback()
	end,
}

function InCombatLockdown()
	return Mock.combat
end

function issecurevariable(name)
	if Mock.secure[name] then
		return true
	end
	return false, Mock.taint[name]
end

function hooksecurefunc(target, name, hook)
	if type(target) == 'string' then
		target, name, hook = _G, target, name
	end
	local original = target[name]
	target[name] = function(...)
		local results = { original(...) }
		hook(...)
		return unpack(results)
	end
end

SlashCmdList = {}
UISpecialFrames = {}

function print(...)
	local parts = {}
	for i = 1, select('#', ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	Mock.printed[#Mock.printed + 1] = table.concat(parts, ' ')
end

--[[ Regions: what frames, textures and font strings share ]]
local Region = {}

local function newObject(kind, name, parent, class)
	local object = setmetatable({
		_type = kind, _name = name, _points = {}, _regions = {}, _children = {},
		_scripts = {}, _hooks = {}, _events = {}, _masks = {},
		_shown = true, _alpha = 1, _w = 0, _h = 0, _scale = 1,
	}, class)
	if parent then
		object._parent = parent
	end
	return object
end

function Region:GetObjectType()
	return self._type
end

function Region:IsObjectType(kind)
	if kind == self._type then
		return true
	end
	return kind == 'Frame' and self._type == 'Button'
end

function Region:GetName()
	return self._name
end

function Region:IsForbidden()
	return false
end

function Region:SetPoint(point, relative, relativePoint, x, y)
	if type(relative) == 'number' then
		relative, relativePoint, x, y = nil, nil, relative, relativePoint
	elseif type(relativePoint) == 'number' then
		relativePoint, x, y = nil, relativePoint, x
	end
	for i, existing in ipairs(self._points) do
		if existing[1] == point then
			table.remove(self._points, i)
			break
		end
	end
	table.insert(self._points, { point, relative or self._parent, relativePoint or point, x or 0, y or 0 })
end

function Region:ClearAllPoints()
	self._points = {}
end

function Region:SetAllPoints(relative)
	relative = relative or self._parent
	self._points = { { 'TOPLEFT', relative, 'TOPLEFT', 0, 0 }, { 'BOTTOMRIGHT', relative, 'BOTTOMRIGHT', 0, 0 } }
end

function Region:GetNumPoints()
	return #self._points
end

function Region:GetPoint(index)
	local p = self._points[index or 1]
	if p then
		return p[1], p[2], p[3], p[4], p[5]
	end
end

function Region:SetSize(width, height)
	self._w, self._h = width, height
end

function Region:SetWidth(width)
	self._w = width
end

function Region:SetHeight(height)
	self._h = height
end

function Region:GetSize()
	return self._w, self._h
end

function Region:GetWidth()
	return self._w
end

function Region:GetHeight()
	return self._h
end

function Region:Show()
	if not self._shown then
		self._shown = true
		Mock.run(self, 'OnShow')
	end
end

function Region:Hide()
	if self._shown then
		self._shown = false
		Mock.run(self, 'OnHide')
	end
end

-- Done in the client's own code: hooks on Show and Hide do not see it.
function Region:SetShown(shown)
	if shown then
		Region.Show(self)
	else
		Region.Hide(self)
	end
end

function Region:IsShown()
	return self._shown
end

function Region:IsVisible()
	local frame = self
	while frame do
		if not frame._shown then
			return false
		end
		frame = frame._parent
	end
	return true
end

function Region:SetAlpha(alpha)
	self._alpha = alpha
end

function Region:GetAlpha()
	return self._alpha
end

function Region:GetParent()
	return self._parent
end

function Region:SetParent(parent)
	local old = self._parent
	if old and old._children then
		for i, child in ipairs(old._children) do
			if child == self then
				table.remove(old._children, i)
				break
			end
		end
	end
	self._parent = parent
	if parent and parent._children and self._isFrame then
		table.insert(parent._children, self)
	end
end

function Region:SetDrawLayer(layer)
	self._layer = layer
end

function Region:GetDrawLayer()
	return self._layer
end

local OFFSET_X = { LEFT = -1, TOPLEFT = -1, BOTTOMLEFT = -1, RIGHT = 1, TOPRIGHT = 1, BOTTOMRIGHT = 1 }
local OFFSET_Y = { TOP = 1, TOPLEFT = 1, TOPRIGHT = 1, BOTTOM = -1, BOTTOMLEFT = -1, BOTTOMRIGHT = -1 }

-- Enough geometry for the tests: the first point, relative to its frame's centre.
function Region:GetCenter()
	if self._center then
		return self._center[1], self._center[2]
	end
	local p = self._points[1]
	if not p or not p[2] then
		return nil
	end
	local rx, ry = p[2]:GetCenter()
	if not rx then
		return nil
	end
	local rw, rh = p[2]._w or 0, p[2]._h or 0
	local x = rx + (OFFSET_X[p[3]] or 0) * rw / 2 + p[4] - (OFFSET_X[p[1]] or 0) * self._w / 2
	local y = ry + (OFFSET_Y[p[3]] or 0) * rh / 2 + p[5] - (OFFSET_Y[p[1]] or 0) * self._h / 2
	return x, y
end

function Region:GetLeft()
	local x = self:GetCenter()
	return x and x - self._w / 2
end

function Region:GetTop()
	local _, y = self:GetCenter()
	return y and y + self._h / 2
end

function Region:GetEffectiveScale()
	return 1
end

--[[ Textures and font strings ]]
local Texture = setmetatable({}, { __index = Region })
local TextureClass = { __index = Texture }

function Texture:SetTexture(texture)
	self._texture = texture
end

function Texture:GetTexture()
	return self._texture
end

function Texture:GetTextureFileID()
	local texture = self._texture
	if type(texture) == 'number' then
		return texture
	end
	if type(texture) == 'string' then
		return Mock.fileIDs[texture:lower()]
	end
	return nil
end

function Texture:SetAtlas(atlas)
	self._atlas = atlas
end

function Texture:SetHorizTile(value)
	self._horizTile = value
end

function Texture:SetVertTile(value)
	self._vertTile = value
end

function Texture:SetTexelSnappingBias(value)
	self._snapBias = value
end

function Texture:SetSnapToPixelGrid(value)
	self._snap = value
end

function Texture:GetAtlas()
	return self._atlas
end

function Texture:SetTexCoord(...)
	self._coords = { ... }
end

function Texture:SetVertexColor(...)
	self._color = { ... }
end

function Texture:GetVertexColor()
	local c = self._color or { 1, 1, 1, 1 }
	return c[1], c[2], c[3], c[4]
end

function Texture:SetColorTexture(...)
	self._colorTexture = { ... }
end

function Texture:SetBlendMode(mode)
	self._blend = mode
end

function Texture:SetDesaturated(value)
	self._desaturated = value
end

function Texture:AddMaskTexture(mask)
	table.insert(self._masks, mask)
end

function Texture:RemoveMaskTexture(mask)
	for i, existing in ipairs(self._masks) do
		if existing == mask then
			table.remove(self._masks, i)
			return
		end
	end
end

function Texture:GetNumMaskTextures()
	return #self._masks
end

function Texture:GetMaskTexture(index)
	return self._masks[index]
end

function Texture:SetFontObject(font)
	self._font = font
end

function Texture:SetText(text)
	self._text = text
end

function Texture:GetText()
	return self._text
end

-- Six units a character: enough to tell a longer text from a shorter one.
function Texture:GetStringWidth()
	return #(self._text or '') * 6
end

function Texture:SetTextColor(...)
	self._textColor = { ... }
end

function Texture:SetJustifyH(value)
	self._justify = value
end

--[[ Frames and buttons ]]
local Frame = setmetatable({}, { __index = Region })
local FrameClass = { __index = Frame }

function Frame:CreateTexture(name, layer, _, sublevel)
	local texture = newObject('Texture', name, self, TextureClass)
	texture._layer, texture._sublevel = layer, sublevel
	table.insert(self._regions, texture)
	return texture
end

function Frame:CreateMaskTexture(name, layer)
	local mask = newObject('MaskTexture', name, self, TextureClass)
	mask._layer = layer
	return mask
end

function Frame:CreateFontString(name, layer, font)
	local text = newObject('FontString', name, self, TextureClass)
	text._layer, text._font = layer, font
	table.insert(self._regions, text)
	return text
end

function Frame:GetRegions()
	return unpack(self._regions)
end

function Frame:GetChildren()
	return unpack(self._children)
end

function Frame:SetFrameStrata(strata)
	self._strata = strata
end

function Frame:GetFrameStrata()
	return self._strata or (self._parent and self._parent.GetFrameStrata and self._parent:GetFrameStrata()) or 'MEDIUM'
end

function Frame:SetFrameLevel(level)
	self._level = level
end

function Frame:GetFrameLevel()
	return self._level or (self._parent and self._parent.GetFrameLevel and self._parent:GetFrameLevel() + 1) or 0
end

function Frame:SetFixedFrameStrata(value)
	self._fixedStrata = value
end

function Frame:HasFixedFrameStrata()
	return self._fixedStrata == true
end

function Frame:SetFixedFrameLevel(value)
	self._fixedLevel = value
end

function Frame:HasFixedFrameLevel()
	return self._fixedLevel == true
end

function Frame:SetScale(scale)
	self._scale = scale
end

function Frame:GetScale()
	return self._scale
end

function Frame:SetIgnoreParentScale(value)
	self._ignoreScale = value
end

function Frame:IsIgnoringParentScale()
	return self._ignoreScale == true
end

function Frame:SetScript(script, handler)
	self._scripts[script] = handler
end

function Frame:GetScript(script)
	return self._scripts[script]
end

function Frame:HookScript(script, hook)
	self._hooks[script] = self._hooks[script] or {}
	table.insert(self._hooks[script], hook)
end

function Frame:RegisterEvent(event)
	self._events[event] = true
end

function Frame:UnregisterEvent(event)
	self._events[event] = nil
end

function Frame:EnableMouse(value)
	self._mouse = value
end

function Frame:IsMouseEnabled()
	return self._mouse ~= false
end

function Frame:IsMouseOver()
	local frame = Mock.hover
	while frame do
		if frame == self then
			return true
		end
		frame = frame._parent
	end
	return false
end

function Frame:SetMovable(value)
	self._movable = value
end

function Frame:SetClampedToScreen(value)
	self._clamped = value
end

function Frame:SetToplevel(value)
	self._toplevel = value
end

function Frame:SetUserPlaced(value)
	self._userPlaced = value
end

function Frame:StartMoving()
	self._moving = true
end

function Frame:StopMovingOrSizing()
	self._moving = false
end

function Frame:RegisterForClicks(...)
	self._clicks = { ... }
end

function Frame:RegisterForDrag(...)
	self._drag = { ... }
end

function Frame:SetHighlightTexture(texture, blend)
	local highlight = self:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetTexture(texture)
	highlight:SetBlendMode(blend)
	self._highlight = highlight
end

function Frame:GetHighlightTexture()
	return self._highlight
end

-- Check buttons and sliders.
function Frame:SetChecked(value)
	self._checked = value and true or false
end

function Frame:GetChecked()
	return self._checked == true
end

function Frame:SetOrientation(value)
	self._orientation = value
end

function Frame:SetMinMaxValues(low, high)
	self._min, self._max = low, high
end

function Frame:GetMinMaxValues()
	return self._min, self._max
end

function Frame:SetValueStep(step)
	self._step = step
end

function Frame:SetObeyStepOnDrag(value)
	self._obey = value
end

-- The client fires OnValueChanged when the value changes.
function Frame:SetValue(value)
	value = math.max(self._min or value, math.min(self._max or value, value))
	if value ~= self._value then
		self._value = value
		Mock.run(self, 'OnValueChanged', value, false)
	end
end

function Frame:GetValue()
	return self._value
end

function Frame:SetThumbTexture(texture)
	self._thumb = texture
end

function Frame:GetThumbTexture()
	return self._thumb
end

function Frame:EnableMouseWheel(value)
	self._wheel = value
end

function Frame:SetNormalAtlas(atlas)
	self._normalAtlas = atlas
end

function Frame:SetPushedAtlas(atlas)
	self._pushedAtlas = atlas
end

function Frame:SetHighlightAtlas(atlas)
	self._highlightAtlas = atlas
end

function Frame:SetEnabled(value)
	self._disabled = not value
end

function Frame:Enable()
	self._disabled = false
end

function Frame:Disable()
	self._disabled = true
end

function Frame:IsEnabled()
	return not self._disabled
end

-- A click as the client delivers it: a check button flips first, a disabled button does nothing.
function Mock.click(button, mouse)
	if button._disabled then
		return
	end
	if button._type == 'CheckButton' then
		button._checked = not button._checked
	end
	Mock.run(button, 'OnClick', mouse or 'LeftButton')
end

-- UIPanelButtonTemplate's label.
function Frame:SetText(text)
	self._text = text
end

function Frame:GetText()
	return self._text
end

function Frame:IsProtected()
	return self._protected == true, self._protected == true
end

function Frame:LockHighlight() end
function Frame:UnlockHighlight() end

function Frame:CreateAnimationGroup()
	return {
		Play = function(group) group.playing = true end,
		Stop = function(group) group.playing = false end,
	}
end

function CreateFrame(kind, name, parent, template)
	local frame = newObject(kind, name, nil, FrameClass)
	frame._isFrame = true
	frame._template = template
	if parent then
		frame:SetParent(parent)
	end
	Mock.frames[#Mock.frames + 1] = frame
	if name then
		_G[name] = frame
		if Mock.tainting then
			Mock.taint[name] = Mock.tainting
		end
	end
	return frame
end

-- Runs a script the way the client does: the handler, then every hook.
function Mock.run(frame, script, ...)
	if not frame._scripts then
		return
	end
	local handler = frame._scripts[script]
	if handler then
		handler(frame, ...)
	end
	for _, hook in ipairs(frame._hooks[script] or {}) do
		hook(frame, ...)
	end
end

function Mock.fire(event, ...)
	for _, frame in ipairs(Mock.frames) do
		if frame._events[event] then
			Mock.run(frame, 'OnEvent', event, ...)
		end
	end
end

--[[ The screen, the minimap and Blizzard's frames on it ]]
local function blizzard(kind, name, parent)
	Mock.secure[name] = true
	return CreateFrame(kind, name, parent)
end

blizzard('Frame', 'UIParent')
UIParent:SetSize(1920, 1080)
UIParent._center = { 960, 540 }

blizzard('Frame', 'Minimap', UIParent)
Minimap:SetSize(140, 140)
Minimap._center = { 1800, 960 }
Minimap:SetFrameLevel(2)
blizzard('Frame', 'MinimapBackdrop', Minimap)
MinimapBackdrop:SetSize(140, 140)

local tracking = blizzard('Button', 'MiniMapTracking', Minimap)
tracking:SetSize(32, 32)
local clock = blizzard('Button', 'GameTimeFrame', Minimap)
clock:SetSize(32, 32)

blizzard('Frame', 'GameTooltip', UIParent)
function GameTooltip:SetOwner(owner, anchor)
	self._owner, self._anchor, self._lines = owner, anchor, {}
end
function GameTooltip:SetText(text)
	self._lines = { text }
end
function GameTooltip:AddLine(text)
	table.insert(self._lines, text)
end

NORMAL_FONT_COLOR = {
	GetRGB = function()
		return 1, 0.82, 0
	end,
}

--[[ The client's art: atlases, nine-slice layouts and NineSliceUtil, as the
Mainline UI has them. tests/run.py installs it for every client but the run
that checks Forever's fallback, which gets none of it.
--]]
function Mock.InstallArt()
	Mock.atlases = {
		['UI-Frame-Metal-CornerTopLeft'] = { width = 75, height = 74 },
		['UI-Frame-Metal-CornerTopRight'] = { width = 75, height = 74 },
		['UI-Frame-Metal-CornerBottomLeft'] = { width = 32, height = 32 },
		['UI-Frame-Metal-CornerBottomRight'] = { width = 32, height = 32 },
		['_UI-Frame-Metal-EdgeTop'] = { width = 32, height = 74, tilesHorizontally = true },
		['_UI-Frame-Metal-EdgeBottom'] = { width = 32, height = 32, tilesHorizontally = true },
		['!UI-Frame-Metal-EdgeLeft'] = { width = 10, height = 32, tilesVertically = true },
		['!UI-Frame-Metal-EdgeRight'] = { width = 10, height = 32, tilesVertically = true },
		['_UI-Frame-TopTileStreaks'] = { width = 256, height = 43, tilesHorizontally = true },
		['UI-HUD-ActionBar-IconFrame'] = { width = 46, height = 45 },
		['UI-HUD-ActionBar-IconFrame-Down'] = { width = 46, height = 45 },
		['UI-HUD-ActionBar-IconFrame-Mouseover'] = { width = 46, height = 45 },
		['RedButton-Exit'] = { width = 28, height = 28 },
		['RedButton-exit-pressed'] = { width = 28, height = 28 },
		['RedButton-Highlight'] = { width = 28, height = 28 },
		['Minimal_SliderBar_Left'] = { width = 11, height = 11 },
		['_Minimal_SliderBar_Middle'] = { width = 32, height = 11, tilesHorizontally = true },
		['Minimal_SliderBar_Right'] = { width = 11, height = 11 },
		['Minimal_SliderBar_Button'] = { width = 20, height = 19 },
		['common-dropdown-textholder'] = { width = 128, height = 38 },
		['common-dropdown-a-button'] = { width = 27, height = 26 },
		['common-dropdown-bg'] = { width = 128, height = 64 },
	}
	C_Texture = {
		GetAtlasInfo = function(name)
			return Mock.atlases[name]
		end,
	}
	NineSliceLayouts = {
		ButtonFrameTemplateNoPortrait = {
			TopLeftCorner = { atlas = 'UI-Frame-Metal-CornerTopLeft', x = -13, y = 16 },
			TopRightCorner = { atlas = 'UI-Frame-Metal-CornerTopRight', x = 4, y = 16 },
			BottomLeftCorner = { atlas = 'UI-Frame-Metal-CornerBottomLeft', x = -13, y = -3 },
			BottomRightCorner = { atlas = 'UI-Frame-Metal-CornerBottomRight', x = 4, y = -3 },
			TopEdge = { atlas = '_UI-Frame-Metal-EdgeTop' },
			BottomEdge = { atlas = '_UI-Frame-Metal-EdgeBottom' },
			LeftEdge = { atlas = '!UI-Frame-Metal-EdgeLeft' },
			RightEdge = { atlas = '!UI-Frame-Metal-EdgeRight' },
		},
	}
	NineSliceUtil = {
		ApplyLayoutByName = function(frame, name)
			frame._nineSlice = name
			for key, piece in pairs(NineSliceLayouts[name]) do
				local texture = frame:CreateTexture(nil, 'BORDER')
				texture:SetAtlas(piece.atlas)
				frame[key] = texture
			end
		end,
		UpdateCornerCropping = function(container, height)
			Mock.cropped = { container = container, height = height }
		end,
		GetLayout = function(name)
			return NineSliceLayouts[name]
		end,
	}
end

AddonCompartmentFrame = {
	registered = {},
	RegisterAddon = function(self, info)
		self.registered[#self.registered + 1] = info
	end,
}

--[[ LibStub and a LibDBIcon that builds its buttons as version 55 does ]]
LibStub = { libs = {} }
function LibStub:GetLibrary(major)
	return self.libs[major]
end
setmetatable(LibStub, { __call = function(self, major) return self.libs[major] end })

function Mock.NewLibDBIcon()
	local lib = { objects = {}, handlers = {} }

	function lib.RegisterCallback(owner, event, handler)
		table.insert(lib.handlers, { owner = owner, event = event, handler = handler })
	end

	function lib:GetButtonList()
		local names = {}
		for name in pairs(self.objects) do
			names[#names + 1] = name
		end
		table.sort(names)
		return names
	end

	function lib:GetMinimapButton(name)
		return self.objects[name]
	end

	function lib:Refresh(name)
		local button = self.objects[name]
		button:SetPoint('CENTER', Minimap, 'CENTER', -80, -10)
		if button.db.hide then
			button:Hide()
		else
			button:Show()
		end
	end

	function lib:Create(name, options)
		options = options or {}
		Mock.tainting = options.addon or name
		local button = CreateFrame('Button', 'LibDBIcon10_' .. name, Minimap)
		Mock.tainting = nil
		button.dataObject = { label = options.label, icon = 'Interface\\Icons\\' .. name }
		button.db = { minimapPos = 225, hide = options.hide }
		button:SetFrameStrata('MEDIUM')
		button:SetFixedFrameStrata(true)
		button:SetFrameLevel(8)
		button:SetFixedFrameLevel(true)
		button:SetSize(31, 31)
		button:RegisterForClicks('anyUp')
		button:RegisterForDrag('LeftButton')
		button:SetHighlightTexture(136477)
		local mainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
		local overlay = button:CreateTexture(nil, 'OVERLAY')
		overlay:SetSize(mainline and 50 or 53, mainline and 50 or 53)
		overlay:SetTexture(136430)
		overlay:SetPoint('TOPLEFT', button, 'TOPLEFT')
		local background = button:CreateTexture(nil, 'BACKGROUND')
		background:SetSize(mainline and 24 or 20, mainline and 24 or 20)
		background:SetTexture(136467)
		local icon = button:CreateTexture(nil, 'ARTWORK')
		icon:SetSize(mainline and 18 or 17, mainline and 18 or 17)
		icon:SetTexture(button.dataObject.icon)
		if mainline then
			background:SetPoint('CENTER', button, 'CENTER')
			icon:SetPoint('CENTER', button, 'CENTER')
		else
			background:SetPoint('TOPLEFT', 7, -5)
			icon:SetPoint('TOPLEFT', 7, -6)
		end
		button.icon = icon
		button:SetScript('OnDragStart', function() end)
		button:SetScript('OnDragStop', function() end)
		button:SetScript('OnClick', function() Mock.clicked = name end)
		button.fadeOut = button:CreateAnimationGroup()
		if options.fade then
			button.showOnMouseover = true
			button:SetAlpha(0)
		end
		self.objects[name] = button
		self:Refresh(name)
		for _, entry in ipairs(self.handlers) do
			if entry.event == 'LibDBIcon_IconCreated' then
				entry.handler('LibDBIcon_IconCreated', button, name)
			end
		end
		return button
	end

	LibStub.libs['LibDBIcon-1.0'] = lib
	return lib
end

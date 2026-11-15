local _, ns = ...
local C, T, L = ns.Compat, ns.Theme, ns.L

--[[ The main button
Blizzard's tracking-button geometry, the one LibDBIcon, Soundstone and
Hourstone use: a dark disc, the icon and the tracking border over both. The
border's transparent padding differs between Retail and the other clients,
so the sizes do too; WoW: Forever takes the Classic sizes, as LibDBIcon does
there.

On the minimap it is dragged along the rim and kept as an angle; detached it
is dragged anywhere and kept as its centre in UIParent's units.
--]]
local Launcher = {}
ns.Launcher = Launcher

local SIZE = 31
-- How far beyond the minimap's edge the button's centre sits: LibDBIcon's default.
local RIM = 5

function Launcher.RimOffset(angle)
	local a = math.rad(angle)
	local x, y = math.cos(a), math.sin(a)
	local w = Minimap:GetWidth() / 2 + RIM
	local h = Minimap:GetHeight() / 2 + RIM
	local shape = type(GetMinimapShape) == 'function' and GetMinimapShape() or 'ROUND'
	if shape == 'ROUND' then
		return x * w, y * h
	end
	-- On a square minimap the rim is a square; a point on the circle would float inside it at the corners.
	local dw, dh = math.sqrt(2 * w * w) - 10, math.sqrt(2 * h * h) - 10
	return math.max(-w, math.min(x * dw, w)), math.max(-h, math.min(y * dh, h))
end

local function showTooltip(button)
	if button.dragging or not GameTooltip then
		return
	end
	local muted = T.colors.muted
	GameTooltip:SetOwner(button, 'ANCHOR_LEFT')
	GameTooltip:SetText(L.TITLE, 1, 1, 1)
	GameTooltip:AddLine(L.TIP_CLICK, muted[1], muted[2], muted[3])
	GameTooltip:AddLine(L.TIP_DRAG, muted[1], muted[2], muted[3])
	GameTooltip:Show()
end

local function hideTooltip()
	if GameTooltip then
		GameTooltip:Hide()
	end
end

function Launcher:Init()
	local button = CreateFrame('Button', 'ButtonstoneLauncher', Minimap)
	self.button = button
	button:SetSize(SIZE, SIZE)
	local retail = C.IsRetail()

	local ground = button:CreateTexture(nil, 'BACKGROUND')
	ground:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
	ground:SetSize(retail and 24 or 20, retail and 24 or 20)
	local icon = button:CreateTexture(nil, 'ARTWORK')
	icon:SetTexture(T.Texture('Logo'))
	icon:SetSize(retail and 19 or 18, retail and 19 or 18)
	if retail then
		ground:SetPoint('CENTER', button, 'CENTER', 0, 0)
		icon:SetPoint('CENTER', button, 'CENTER', 0, 0)
	else
		ground:SetPoint('TOPLEFT', button, 'TOPLEFT', 7, -5)
		icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 6.5, -5.5)
	end
	button.icon = icon

	local border = button:CreateTexture(nil, 'OVERLAY')
	border:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder
	border:SetSize(retail and 50 or 53, retail and 50 or 53)
	border:SetPoint('TOPLEFT', button, 'TOPLEFT', 0, 0)
	button:SetHighlightTexture(136477, 'ADD') -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight

	button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	button:RegisterForDrag('LeftButton')
	button:SetScript('OnEnter', showTooltip)
	button:SetScript('OnLeave', hideTooltip)
	button:SetScript('OnMouseDown', function(frame)
		frame.icon:SetVertexColor(0.75, 0.75, 0.75)
	end)
	button:SetScript('OnMouseUp', function(frame)
		frame.icon:SetVertexColor(1, 1, 1)
	end)
	button:SetScript('OnClick', function(frame, mouse)
		if frame.suppressUntil and C.Now() < frame.suppressUntil then
			return
		end
		hideTooltip()
		if mouse == 'RightButton' then
			ns.ShowOptions()
		else
			ns.Bundle:Toggle()
		end
	end)
	button:SetScript('OnDragStart', function()
		Launcher:StartDrag()
	end)
	button:SetScript('OnDragStop', function()
		Launcher:StopDrag()
	end)
	self:Place()
end

-- The button's centre in UIParent's units, wherever it sits.
function Launcher:ScreenCenter()
	local button = self.button
	local x, y = button:GetCenter()
	if not x then
		return { x = UIParent:GetWidth() / 2, y = UIParent:GetHeight() / 2 }
	end
	local s = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return { x = x * s, y = y * s }
end

function Launcher:Place()
	local button, db = self.button, ns.db.launcher
	button:ClearAllPoints()
	if db.attached then
		button:SetParent(Minimap)
		button:SetMovable(false)
		button:SetFrameStrata('MEDIUM')
		button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
		local x, y = Launcher.RimOffset(db.angle)
		button:SetPoint('CENTER', Minimap, 'CENTER', x, y)
	else
		button:SetParent(UIParent)
		button:SetMovable(true)
		button:SetClampedToScreen(true)
		button:SetFrameStrata('MEDIUM')
		button:SetFrameLevel(10)
		local free = db.free or { x = UIParent:GetWidth() / 2, y = UIParent:GetHeight() / 2 }
		button:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', free.x, free.y)
	end
	if ns.Bundle.frame and ns.Bundle.frame:IsShown() then
		ns.Bundle:Anchor()
	end
end

local function followCursor()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	ns.db.launcher.angle = math.deg(math.atan2(py / scale - my, px / scale - mx)) % 360
	Launcher:Place()
end

function Launcher:StartDrag()
	local button = self.button
	button.dragging = true
	hideTooltip()
	if ns.db.launcher.attached then
		button:SetScript('OnUpdate', followCursor)
	else
		button:StartMoving()
	end
end

function Launcher:StopDrag()
	local button = self.button
	button.dragging = nil
	if ns.db.launcher.attached then
		button:SetScript('OnUpdate', nil)
	else
		button:StopMovingOrSizing()
		-- StartMoving would have the client keep the place itself; Buttonstone keeps it.
		if button.SetUserPlaced then
			button:SetUserPlaced(false)
		end
		ns.db.launcher.free = self:ScreenCenter()
		self:Place()
	end
	button.suppressUntil = C.Now() + 0.15
end

function Launcher:Detach()
	local db = ns.db.launcher
	if db.attached then
		db.free = self:ScreenCenter()
		db.attached = false
	end
	self:Place()
end

function Launcher:Attach()
	ns.db.launcher.attached = true
	self:Place()
end

function Launcher:Reset()
	local db, defaults = ns.db.launcher, ns.defaults.launcher
	db.attached = defaults.attached
	db.angle = defaults.angle
	db.free = nil
	self:Place()
end

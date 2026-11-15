local _, ns = ...
local C, T, L = ns.Compat, ns.Theme, ns.L

--[[ The options window
As the approved mockup has it: the main button, the panel's settings, the
list of buttons with a checkbox each, and the reset and done buttons, in the
client's look. Checkboxes are Blizzard's UICheckButtonTemplate on every
client, as in Soundstone and Hourstone, so each client draws its own. Every
change takes effect at once.

Opened by right-clicking the main button, by the panel's gear, from the
Addons menu and with /bst. Escape closes it.
--]]
local Options = {}
ns.Options = Options

local WIDTH = 344
local ROW = 23
-- The list shows up to twelve buttons and grows with them; past that it scrolls.
local LIST_MAX = 12
local LIST_ROW = 22
-- From the list's bottom to the window's: gap, push buttons, gap, footer.
local BELOW_LIST = 10 + 22 + 8 + 12
local INSET = { retail = 13, classic = 15, forever = 14 }
local DIRECTIONS = { 'auto', 'down-left', 'down-right', 'up-left', 'up-right' }

-- Forever's control art, as Hourstone wears it there.
local ART = {
	field = 'common-dropdown-textholder',
	arrow = 'common-dropdown-a-button',
	list = 'common-dropdown-bg',
}

local function forever()
	return T.Skin() == 'forever'
end

local function text(parent, template, colorKey, value)
	local fs = parent:CreateFontString(nil, 'ARTWORK', template)
	if value then
		fs:SetText(value)
	end
	if colorKey then
		T.Color(fs, colorKey, 'SetTextColor')
	end
	return fs
end

local function sprite(parent, name, layer)
	local t = parent:CreateTexture(nil, layer or 'ARTWORK')
	local asset = ns.Assets[name]
	t:SetTexture(T.Texture(name))
	t:SetTexCoord(asset.uv[1], asset.uv[2], asset.uv[3], asset.uv[4])
	return t
end

-- A dark well with a one-pixel line: Forever's flat stand-in for a control.
local function well(frame)
	local fill = frame:CreateTexture(nil, 'BACKGROUND')
	fill:SetTexture(T.WHITE)
	fill:SetAllPoints(frame)
	T.Color(fill, 'band')
	T.Lines(frame, 'BORDER', 'lineBottom', 'lineBottom', 'lineBottom')
end

--[[ Widgets ]]
local function checkbox(parent, x, y, label, onClick)
	local box = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
	box:SetSize(24, 24)
	box:SetPoint('TOPLEFT', parent, 'TOPLEFT', x - 4, -y + 2)
	box.label = text(parent, 'GameFontHighlightSmall', 'text', label)
	box.label:SetPoint('LEFT', box, 'RIGHT', 1, 0)
	box:SetScript('OnClick', function(b)
		onClick(b:GetChecked() and true or false)
	end)
	return box
end

-- A field's surface: Blizzard's dropdown field on Forever (as Hourstone wears
-- it there), the family's control sprite elsewhere, the flat well as a stand-in.
local function fieldSurface(field)
	local skin = T.Skin()
	if skin == 'forever' and T.HasAtlas(ART.field) then
		local holder = field:CreateTexture(nil, 'BACKGROUND')
		holder:SetAtlas(ART.field)
		holder:SetPoint('TOPLEFT', field, 'TOPLEFT', -8, 7)
		holder:SetPoint('BOTTOMRIGHT', field, 'BOTTOMRIGHT', 8, -9)
		return true
	elseif skin == 'forever' then
		well(field)
	else
		T.NineSlice(field, skin == 'retail' and 'ControlRetail' or 'ControlClassic', 3, 8, 'BACKGROUND')
	end
	return false
end

-- A value in fixed steps: [-] value [+] in a field, as wide as the direction field.
local function stepper(parent, x, y, width, low, high, step, format, onChange)
	local field = CreateFrame('Frame', nil, parent)
	field:SetSize(width, 22)
	field:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, -y)
	fieldSurface(field)
	field.text = text(field, 'GameFontHighlightSmall', 'text')
	field.text:SetPoint('CENTER', field, 'CENTER', 0, 0)
	local function stepButton(symbol, up, point, offset)
		local b = CreateFrame('Button', nil, field)
		b:SetSize(22, 20)
		b:SetPoint(point, field, point, offset, 0)
		b.label = text(b, 'GameFontNormal', 'title', symbol)
		b.label:SetPoint('CENTER', b, 'CENTER', 0, 0)
		local highlight = b:CreateTexture(nil, 'HIGHLIGHT')
		highlight:SetTexture(T.WHITE)
		highlight:SetAllPoints(b)
		highlight:SetVertexColor(1, 1, 1, 0.12)
		b:SetScript('OnClick', function()
			local current = field.current or low
			-- To the next step on the grid, also from a value between steps.
			local nextValue = up and (math.floor(current / step) + 1) * step or (math.ceil(current / step) - 1) * step
			onChange(math.max(low, math.min(high, nextValue)))
		end)
		return b
	end
	field.minus = stepButton('-', false, 'LEFT', 1)
	field.plus = stepButton('+', true, 'RIGHT', -1)
	function field:SetValue(value)
		self.current = value
		self.text:SetText(format(value))
		self.minus:SetEnabled(value > low)
		self.plus:SetEnabled(value < high)
		self.minus.label:SetAlpha(value > low and 1 or 0.35)
		self.plus.label:SetAlpha(value < high and 1 or 0.35)
	end
	return field
end

local function dropdown(parent, x, y, width, choices, onSelect)
	local skin = T.Skin()
	local field = CreateFrame('Button', nil, parent)
	field:SetSize(width, 22)
	field:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, -y)
	local arrow = field:CreateTexture(nil, 'OVERLAY')
	local framed = fieldSurface(field)
	if framed and T.HasAtlas(ART.arrow) then
		-- WowStyle1DropdownTemplate's arrow, as Hourstone wears it on Forever.
		arrow:SetAtlas(ART.arrow, true)
		arrow:SetPoint('RIGHT', field, 'RIGHT', 2, -1)
	else
		arrow:SetTexture(T.Texture('Arrow'))
		arrow:SetSize(10, 8)
		arrow:SetPoint('RIGHT', field, 'RIGHT', -7, 0)
		if skin == 'forever' then
			T.Color(arrow, 'accent')
		end
	end
	field.label = text(field, 'GameFontHighlightSmall', 'text')
	field.label:SetPoint('LEFT', field, 'LEFT', 8, 0)
	field.label:SetPoint('RIGHT', field, 'RIGHT', -22, 0)
	field.label:SetJustifyH('LEFT')

	local popup = CreateFrame('Frame', nil, field)
	popup:Hide()
	popup:SetFrameStrata('FULLSCREEN_DIALOG')
	popup:SetToplevel(true)
	popup:EnableMouse(true)
	popup:SetPoint('TOPLEFT', field, 'BOTTOMLEFT', 0, -2)
	popup:SetSize(width, #choices * 18 + 10)
	if skin == 'forever' and T.HasAtlas(ART.list) then
		local bg = popup:CreateTexture(nil, 'BACKGROUND')
		bg:SetAtlas(ART.list)
		bg:SetPoint('TOPLEFT', popup, 'TOPLEFT', -10, 3)
		bg:SetPoint('BOTTOMRIGHT', popup, 'BOTTOMRIGHT', 10, -3)
		bg:SetAlpha(0.925)
	elseif skin == 'forever' then
		local fill = popup:CreateTexture(nil, 'BACKGROUND')
		fill:SetTexture(T.WHITE)
		fill:SetAllPoints(popup)
		T.Color(fill, 'plate')
		T.Lines(popup, 'BORDER', 'lineTop', 'lineSide', 'lineBottom')
	else
		local m = T.Metrics()
		T.NineSlice(popup, m.panel, math.floor(m.corner / 2 + 0.5), m.sourceCorner, 'BACKGROUND')
	end
	field.popup = popup
	field.rows = {}
	for i, choice in ipairs(choices) do
		local row = CreateFrame('Button', nil, popup)
		row:SetSize(width - 10, 18)
		row:SetPoint('TOPLEFT', popup, 'TOPLEFT', 5, -5 - (i - 1) * 18)
		local hl = row:CreateTexture(nil, 'HIGHLIGHT')
		hl:SetTexture(T.WHITE)
		hl:SetAllPoints(row)
		hl:SetVertexColor(1, 1, 1, 0.12)
		row.label = text(row, 'GameFontHighlightSmall', 'text', choice.text)
		row.label:SetPoint('LEFT', row, 'LEFT', 6, 0)
		row.value = choice.value
		row:SetScript('OnClick', function()
			popup:Hide()
			onSelect(choice.value)
		end)
		field.rows[i] = row
	end
	-- A click anywhere else closes the list.
	popup:SetScript('OnShow', function(self)
		pcall(self.RegisterEvent, self, 'GLOBAL_MOUSE_DOWN')
	end)
	popup:SetScript('OnHide', function(self)
		pcall(self.UnregisterEvent, self, 'GLOBAL_MOUSE_DOWN')
	end)
	popup:SetScript('OnEvent', function(self)
		if not self:IsMouseOver() and not field:IsMouseOver() then
			self:Hide()
		end
	end)
	field:SetScript('OnClick', function()
		popup:SetShown(not popup:IsShown())
	end)

	function field:SetValue(value)
		self.value = value
		for i, choice in ipairs(choices) do
			local row = self.rows[i]
			T.Color(row.label, choice.value == value and 'title' or 'text', 'SetTextColor')
			if choice.value == value then
				self.label:SetText(choice.text)
			end
		end
	end
	return field
end

local function pushButton(parent, label, red, onClick)
	local b
	if forever() then
		b = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
		b:SetText(label)
	else
		b = CreateFrame('Button', nil, parent)
		T.NineSlice(b, red and 'ToggleRed' or 'Toggle', 4, 14, 'BACKGROUND')
		local fs = b:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
		fs:SetPoint('CENTER', b, 'CENTER', 0, 0)
		fs:SetText(label)
		if red then
			fs:SetTextColor(1, 0.94, 0.76)
		else
			T.Color(fs, 'title', 'SetTextColor')
		end
		b.label = fs
	end
	-- As wide as the label needs: German labels are long, and the client's font wider than the mockup's.
	local shown = b.label or (b.GetFontString and b:GetFontString())
	local textWidth = shown and shown:GetStringWidth() or 0
	b:SetSize(math.max(100, textWidth + 28), 22)
	b:SetScript('OnClick', onClick)
	return b
end

--[[ The list of buttons ]]
local function setIcon(texture, button)
	texture:SetTexture(nil)
	if not button then
		return
	end
	local icon = ns.Bundle.FindIcon(button)
	local atlas = icon and ns.Collector.try(icon, 'GetAtlas')
	if atlas then
		texture:SetAtlas(atlas)
	else
		texture:SetTexture(icon and ns.Collector.try(icon, 'GetTexture') or nil)
	end
end

function Options:BuildList(x, y, width)
	local frame = self.frame
	local box = CreateFrame('Frame', nil, frame)
	box:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -y)
	box:SetSize(width, LIST_ROW)
	box:EnableMouseWheel(true)
	box.offset = 0
	box.rows = {}
	for i = 1, LIST_MAX do
		local row = CreateFrame('Button', nil, box)
		row:SetSize(width, LIST_ROW)
		row:SetPoint('TOPLEFT', box, 'TOPLEFT', 0, -(i - 1) * LIST_ROW)
		row.check = CreateFrame('CheckButton', nil, row, 'UICheckButtonTemplate')
		row.check:SetSize(20, 20)
		row.check:SetPoint('LEFT', row, 'LEFT', -3, 0)
		row.icon = row:CreateTexture(nil, 'ARTWORK')
		row.icon:SetSize(16, 16)
		row.icon:SetPoint('LEFT', row.check, 'RIGHT', 2, 0)
		row.name = text(row, 'GameFontHighlightSmall', 'text')
		row.name:SetPoint('LEFT', row.icon, 'RIGHT', 6, 0)
		row.source = text(row, 'GameFontDisableSmall', 'muted')
		row.source:SetPoint('RIGHT', row, 'RIGHT', -2, 0)
		local rule = row:CreateTexture(nil, 'BORDER')
		rule:SetTexture(T.WHITE)
		rule:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', 0, 0)
		rule:SetPoint('BOTTOMRIGHT', row, 'BOTTOMRIGHT', 0, 0)
		rule:SetHeight(T.Pixel(row))
		T.Color(rule, 'rule')
		local function toggle()
			if row.entry then
				Options:SetIncluded(row.entry, not row.entry.included)
			end
		end
		row:SetScript('OnClick', toggle)
		row.check:SetScript('OnClick', toggle)
		box.rows[i] = row
	end
	box.empty = text(box, 'GameFontDisableSmall', 'muted')
	box.empty:SetPoint('LEFT', box, 'LEFT', 2, 0)

	-- Blizzard's own scroll bar, in the client's look, for more than twelve
	-- buttons. Its arrows step one row; its handler is replaced, since it would
	-- scroll a ScrollFrame parent.
	local ok, bar = pcall(CreateFrame, 'Slider', nil, box, 'UIPanelScrollBarTemplate')
	if ok and bar then
		bar:SetPoint('TOPRIGHT', box, 'TOPRIGHT', 0, -16)
		bar:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', 0, 16)
		bar:SetMinMaxValues(0, 0)
		bar:SetValueStep(1)
		if bar.SetObeyStepOnDrag then
			bar:SetObeyStepOnDrag(true)
		end
		bar.scrollStep = 1
		bar:SetScript('OnValueChanged', function(_, value)
			if Options.rendering then
				return
			end
			box.offset = math.floor(value + 0.5)
			Options:RenderList()
		end)
		bar:Hide()
		box.bar = bar
	end
	box:SetScript('OnMouseWheel', function(list, delta)
		list.offset = list.offset - delta
		Options:RenderList()
	end)
	self.list = box
	self.listTop = y
	return y
end

function Options:RenderList()
	local box = self.list
	local entries = self.entries or {}
	local scrolling = #entries > LIST_MAX
	local visible = math.min(#entries, LIST_MAX)
	box.offset = scrolling and math.max(0, math.min(box.offset, #entries - LIST_MAX)) or 0
	box:SetHeight(math.max(visible, 1) * LIST_ROW)
	local rowWidth = box:GetWidth() - ((scrolling and box.bar) and 22 or 0)
	for i, row in ipairs(box.rows) do
		local entry = i <= visible and entries[box.offset + i] or nil
		row.entry = entry
		row:SetShown(entry ~= nil)
		row:SetWidth(rowWidth)
		if entry then
			row.check:SetChecked(entry.included)
			setIcon(row.icon, entry.button)
			row.name:SetText(entry.label)
			T.Color(row.name, entry.included and 'text' or 'muted', 'SetTextColor')
			local note = L['SOURCE_' .. entry.source]
			if entry.missing then
				note = L.NOT_LOADED
			elseif entry.included and not entry.button:IsShown() then
				note = note .. ', ' .. L.LIST_HIDDEN
			end
			row.source:SetText(note)
		end
	end
	local rival = ns.Collector.rival
	box.empty:SetText(rival and L.EMPTY_RIVAL:format(rival) or L.EMPTY)
	box.empty:SetShown(#entries == 0)
	if box.bar then
		self.rendering = true
		box.bar:SetShown(scrolling)
		box.bar:SetMinMaxValues(0, math.max(0, #entries - LIST_MAX))
		box.bar:SetValue(box.offset)
		self.rendering = false
	end
	-- The window grows with the list.
	self.frame:SetHeight(self.listTop + box:GetHeight() + BELOW_LIST + self.inset - 2)
end

function Options:SetIncluded(entry, included)
	ns.Collector:SetExcluded(entry.name, not included)
	self:Refresh()
end

--[[ The window ]]
function Options:BuildFrame()
	local skin = T.Skin()
	local inset = INSET[skin]
	local frame = CreateFrame('Frame', 'ButtonstoneOptions', UIParent)
	self.frame = frame
	frame:Hide()
	frame:SetFrameStrata('DIALOG')
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetWidth(WIDTH)
	frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	table.insert(UISpecialFrames, 'ButtonstoneOptions')

	local function close()
		frame:Hide()
	end
	local top, dragArea
	if skin == 'forever' then
		local surface, border, framed = ns.Forever.Window(frame)
		self.surface = surface
		local head = CreateFrame('Frame', nil, frame)
		head:SetFrameLevel(frame:GetFrameLevel() + 12)
		head:SetAllPoints(border)
		head:EnableMouse(false)
		local title = text(head, 'GameFontNormal', 'title', L.TITLE)
		self.close = ns.Forever.CloseButton(head, border, framed, close)
		if framed then
			-- Blizzard's window title, centred, 6 units below the border's top.
			title:SetPoint('TOP', border, 'TOP', 0, -6)
			top = 33
		else
			title:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset, -(inset - 2))
			local rule = frame:CreateTexture(nil, 'ARTWORK')
			rule:SetTexture(T.WHITE)
			rule:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset, -(inset + 20))
			rule:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -inset, -(inset + 20))
			rule:SetHeight(T.Pixel(frame))
			T.Color(rule, 'rule')
			top = inset + 28
		end
		self.title = title
		dragArea = { 'TOPLEFT', frame, 'TOPLEFT', 0, 0, 22 }
	else
		local m = T.Metrics()
		T.NineSlice(frame, m.panel, m.corner, m.sourceCorner, 'BACKGROUND')
		-- Soundstone's grip: six rivets.
		for i = 0, 5 do
			local rivet = sprite(frame, 'Rivet')
			rivet:SetSize(4, 4)
			rivet:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset - 2 + (i % 2) * 7, -(inset + 1 + math.floor(i / 2) * 7))
		end
		local logo = frame:CreateTexture(nil, 'ARTWORK')
		logo:SetTexture(T.Texture('Logo'))
		logo:SetSize(20, 20)
		logo:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset + 14, -(inset - 2))
		local title = text(frame, 'GameFontNormal', 'title', L.TITLE)
		title:SetPoint('LEFT', logo, 'RIGHT', 6, 0)
		self.title = title
		local closeButton = CreateFrame('Button', nil, frame)
		closeButton:SetSize(20, 20)
		closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -(inset - 3), -(inset - 2))
		local art = sprite(closeButton, 'HeaderClose')
		art:SetAllPoints(closeButton)
		closeButton:SetScript('OnClick', close)
		closeButton:SetScript('OnEnter', function() art:SetVertexColor(1.2, 1.2, 1.2) end)
		closeButton:SetScript('OnLeave', function() art:SetVertexColor(1, 1, 1) end)
		self.close = closeButton
		local rule = frame:CreateTexture(nil, 'ARTWORK')
		rule:SetTexture(T.WHITE)
		rule:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset, -(inset + 22))
		rule:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -inset, -(inset + 22))
		rule:SetHeight(1)
		T.Color(rule, 'rule')
		top = inset + 28
		dragArea = { 'TOPLEFT', frame, 'TOPLEFT', 0, 0, inset + 22 }
	end

	-- The header drags the window.
	local drag = CreateFrame('Frame', nil, frame)
	drag:SetPoint(dragArea[1], dragArea[2], dragArea[3], dragArea[4], dragArea[5])
	drag:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -36, 0)
	drag:SetHeight(dragArea[6])
	drag:EnableMouse(true)
	drag:SetScript('OnMouseDown', function()
		frame:StartMoving()
	end)
	drag:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
		if frame.SetUserPlaced then
			frame:SetUserPlaced(false)
		end
	end)
	return inset, top
end

function Options:Build()
	if self.frame then
		return
	end
	local inset, y = self:BuildFrame()
	local frame = self.frame
	local x, width = inset, WIDTH - 2 * inset
	local c = {}
	self.controls = c

	local function section(label)
		local fs = text(frame, 'GameFontNormal', 'title', label)
		fs:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -y)
		y = y + 18
		return fs
	end
	local function hint(label)
		local fs = text(frame, 'GameFontDisableSmall', 'muted', label)
		fs:SetPoint('TOPLEFT', frame, 'TOPLEFT', x + 22, -y + 3)
		y = y + 12
		return fs
	end
	local function rowLabel(label)
		local fs = text(frame, 'GameFontHighlightSmall', 'text', label)
		fs:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -y - 5)
		return fs
	end

	section(L.SEC_MAIN)
	c.attached = checkbox(frame, x, y, L.KEEP, function(on)
		if on then ns.Launcher:Attach() else ns.Launcher:Detach() end
		Options:Refresh()
	end)
	y = y + ROW
	hint(L.KEEP_HINT)
	if C.HasAddonCompartment() then
		c.compartment = checkbox(frame, x, y, L.COMPARTMENT, function(on)
			ns.db.compartment = on
		end)
		y = y + ROW
		hint(L.COMPARTMENT_HINT)
	end
	y = y + 6

	section(L.SEC_PANEL)
	local fieldX, fieldWidth = x + 74, width - 74
	rowLabel(L.COLUMNS)
	c.columns = stepper(frame, fieldX, y, fieldWidth, 2, 8, 1, tostring, function(value)
		ns.db.panel.columns = value
		ns.Bundle:Layout()
		Options:Refresh()
	end)
	y = y + ROW + 2
	rowLabel(L.DIRECTION)
	local choices = {}
	for _, key in ipairs(DIRECTIONS) do
		choices[#choices + 1] = { value = key, text = L['DIR_' .. key] }
	end
	c.direction = dropdown(frame, fieldX, y, fieldWidth, choices, function(value)
		ns.db.panel.direction = value
		ns.Bundle:Anchor()
		Options:Refresh()
	end)
	y = y + ROW + 2
	rowLabel(L.SIZE)
	c.size = stepper(frame, fieldX, y, fieldWidth, 60, 160, 10, function(value)
		return L.PERCENT:format(value)
	end, function(value)
		ns.db.panel.size = value
		ns.Bundle:Refresh()
		Options:Refresh()
	end)
	y = y + ROW + 2
	c.uniform = checkbox(frame, x, y, L.UNIFORM, function(on)
		ns.db.panel.uniform = on
		ns.Bundle:Refresh()
	end)
	y = y + ROW
	c.header = checkbox(frame, x, y, L.HEADER, function(on)
		ns.db.panel.header = on
		ns.Bundle:Layout()
	end)
	y = y + ROW
	c.autoClose = checkbox(frame, x, y, L.AUTOCLOSE, function(on)
		ns.db.panel.autoClose = on
	end)
	y = y + ROW + 6

	c.buttons = section(L.SEC_BUTTONS:format(0))
	self.inset = inset
	self:BuildList(x, y, width)
	local list = self.list

	-- The push buttons and the footer hang below the list, which grows.
	c.reset = pushButton(frame, L.RESET_POSITION, false, function()
		ns.Launcher:Reset()
		Options:Refresh()
	end)
	c.done = pushButton(frame, L.DONE, true, function()
		frame:Hide()
	end)
	local pair = c.reset:GetWidth() + 8 + c.done:GetWidth()
	c.reset:SetPoint('TOPLEFT', list, 'BOTTOM', -pair / 2, -10)
	c.done:SetPoint('TOPLEFT', c.reset, 'TOPRIGHT', 8, 0)

	local by = text(frame, 'GameFontDisableSmall', 'muted', 'by krebs3r')
	by:SetPoint('TOPRIGHT', list, 'BOTTOMRIGHT', 0, -(10 + 22 + 8))
	local heart = frame:CreateTexture(nil, 'ARTWORK')
	heart:SetTexture(T.Texture('Heart'))
	heart:SetSize(10, 10)
	heart:SetPoint('RIGHT', by, 'LEFT', -3, 0)
	c.footer = text(frame, 'GameFontDisableSmall', 'muted', L.FOOTER:format(C.Version()))
	c.footer:SetPoint('RIGHT', heart, 'LEFT', -3, 0)

	frame:SetScript('OnShow', function()
		Options:Refresh()
	end)
end

-- Every control from the settings, as they stand now.
function Options:Refresh()
	if not self.frame then
		return
	end
	local c, db = self.controls, ns.db
	c.attached:SetChecked(db.launcher.attached)
	if c.compartment then
		c.compartment:SetChecked(db.compartment)
	end
	c.columns:SetValue(db.panel.columns)
	c.direction:SetValue(db.panel.direction)
	c.size:SetValue(db.panel.size)
	c.uniform:SetChecked(db.panel.uniform)
	c.header:SetChecked(db.panel.header)
	c.autoClose:SetChecked(db.panel.autoClose)

	self.entries = ns.Collector:Entries()
	local found = 0
	for _, entry in ipairs(self.entries) do
		if not entry.missing then
			found = found + 1
		end
	end
	c.buttons:SetText(L.SEC_BUTTONS:format(found))
	self:RenderList()
end

function Options:Toggle()
	self:Build()
	if self.frame:IsShown() then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

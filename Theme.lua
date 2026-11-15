local addonName, ns = ...
local C = ns.Compat

--[[ The look
Retail wears Soundstone's gold sprites, the Classic clients its iron and
stone. WoW: Forever gets its own look from the client's art in a later step
(docs/PLAN.md, phase 5); until then it wears the Classic sprites, as
Soundstone did before its Forever look. A look changes surfaces, never what
the panel shows.
--]]
local T = {}
ns.Theme = T

T.MEDIA = 'Interface\\AddOns\\' .. addonName .. '\\Media\\'

-- Soundstone's palette, shared by Retail and Classic.
T.colors = {
	text = { 0.96, 0.94, 0.87 },
	title = { 1, 0.81, 0.26 },
	muted = { 0.65, 0.63, 0.58 },
	rule = { 0.67, 0.64, 0.56, 0.55 },
}

-- Panel metrics in UI units, as the approved mockup draws them.
T.metrics = {
	retail = {
		panel = 'RetailPanel', corner = 7, sourceCorner = 23,
		padX = 11, padTop = 11, padTopHeader = 37, padBottom = 11, minWidth = 168,
	},
	classic = {
		panel = 'ClassicPanel', corner = 10, sourceCorner = 52,
		padX = 13, padTop = 13, padTopHeader = 40, padBottom = 13, minWidth = 172,
	},
}

T.SLOT = 32
T.GAP = 4
T.ICON = 24

function T.Skin()
	return C.IsRetail() and 'retail' or 'classic'
end

function T.Metrics()
	return T.metrics[T.Skin()]
end

function T.Texture(name)
	return T.MEDIA .. name
end

function T.Color(region, key, method)
	local c = T.colors[key]
	region[method or 'SetVertexColor'](region, c[1], c[2], c[3], c[4] or 1)
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
			if col == 1 then t:SetWidth(c) elseif col == 3 then t:SetWidth(c) end
			if row == 1 then t:SetHeight(c) elseif row == 3 then t:SetHeight(c) end
			if top and left then t:SetPoint('TOPLEFT', frame, 'TOPLEFT', left, top) end
			if top and right then t:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', right, top) end
			if bottom and left then t:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', left, bottom) end
			if bottom and right then t:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', right, bottom) end
			pieces[#pieces + 1] = t
		end
	end
	return pieces
end

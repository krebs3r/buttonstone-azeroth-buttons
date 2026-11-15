local addonName, ns = ...

--[[ What the client is, asked rather than assumed
One source tree runs on Retail, Mists of Pandaria Classic, the TBC Anniversary
realms, Classic Era and WoW: Forever. Everything that differs between them is
asked here, at runtime, so the rest of the addon never reads a project ID.
--]]
local C = {}
ns.Compat = C

-- WoW: Forever loads the Mainline UI. Its release client reports
-- WOW_PROJECT_CAMELOT (18); the beta reported MAINLINE. Both report an
-- interface number of 16xxx, so either answer is enough.
function C.IsForever()
	if WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
		return true
	end
	if type(GetBuildInfo) ~= 'function' then
		return false
	end
	local ok, _, _, _, interface = pcall(GetBuildInfo)
	return ok and type(interface) == 'number' and interface >= 16000 and interface < 17000
end

-- Modern Retail only; false on Forever, which shares Retail's project ID on its beta.
function C.IsRetail()
	return WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and not C.IsForever()
end

-- The look follows the client; there is no setting for it (docs/PLAN.md).
function C.Look()
	if C.IsForever() then
		return 'forever'
	elseif C.IsRetail() then
		return 'retail'
	end
	return 'classic'
end

-- Blizzard's Addons menu below the minimap clock: Retail and Forever have it, the Classic clients do not.
function C.HasAddonCompartment()
	return type(AddonCompartmentFrame) == 'table' and type(AddonCompartmentFrame.RegisterAddon) == 'function'
end

-- Midnight marks some values secret; comparing or reading one taints. Ask before touching.
function C.IsSecret(value)
	return type(issecretvalue) == 'function' and issecretvalue(value) == true
end

function C.Metadata(field)
	local read = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if type(read) ~= 'function' then
		return nil
	end
	local ok, value = pcall(read, addonName, field)
	if ok and type(value) == 'string' and value ~= '' then
		return value
	end
	return nil
end

-- The packager replaces @project-version@; a copy straight from the checkout is 'dev'.
function C.Version()
	local version = C.Metadata('Version')
	if not version or version:find('@', 1, true) then
		return 'dev'
	end
	return version
end

function C.Now()
	return type(GetTime) == 'function' and GetTime() or 0
end

function C.InCombat()
	return type(InCombatLockdown) == 'function' and InCombatLockdown() == true
end

function C.After(seconds, callback)
	if C_Timer and type(C_Timer.After) == 'function' then
		C_Timer.After(seconds, callback)
	else
		callback()
	end
end

C_NamePlateManager = {}

local ActiveNamePlateUnits = {}

local SecureNamePlateDriver = CreateFrame("Frame")
SecureNamePlateDriver:SetScript("OnAttributeChanged", function(self, attribute, value)
	if attribute == "nameplate-target" then
		self.nameplateTarget = value
	elseif attribute == "nameplate-target-resize" then
		if self.nameplateTarget then
			self.nameplateTarget:SetAttribute("resize", true)
		end
	elseif attribute == "nameplate-resize" then
		self:RefreshNamePlateSizes()
	elseif attribute == "smooth-stacking" then
		if value then
			self:EnableSmoothStacking()
		else
			self:DisableSmoothStacking()
		end
	end
end)

function SecureNamePlateDriver:SetNameplateSize(nameplate, width, height)
	self:SetAttribute("nameplate-target", nameplate)
	self:SetAttribute("nameplate-target-resize", true)
end

function SecureNamePlateDriver:CanResizeNamePlates()
	return self:GetAttribute("nameplate-resize")
end

SecureNamePlateDriver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
SecureNamePlateDriver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
SecureNamePlateDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
SecureNamePlateDriver:SetScript("OnEvent", OnEventToMethod)

local function NamePlateOnAttributeChanged(nameplate, attribute, value)
	if attribute == "resize" then
		local width, height = nameplate:GetSize()
		local newWidth, newHeight = C_CVar.GetNumber("nameplateWidth"), C_CVar.GetNumber("nameplateHeight")
		if width ~= newWidth or height ~= newHeight then
			nameplate:SetSize(newWidth, newHeight)
			if nameplate.UnitFrame then
				nameplate.UnitFrame:SetSize(newWidth, newHeight)
			end
		end
	end
end

function SecureNamePlateDriver:NAME_PLATE_UNIT_ADDED(unit)
	if not UnitExists(unit) then
		return
	end

	local np = C_NamePlate.GetNamePlateForUnit(unit)
	if not np then
		return
	end

	if C_CVar.GetBool("DrawNameplateClickBox") then
		if not np.ClickBoxDebug then
			np.ClickBoxDebug = np:CreateTexture(nil, "OVERLAY")
			np.ClickBoxDebug:SetTexture(1, 1, 1, 0.5)
			np.ClickBoxDebug:SetAllPoints()
		end
		np.ClickBoxDebug:Show()
	elseif np.ClickBoxDebug then
		np.ClickBoxDebug:Hide()
	end

	if not np:GetAttribute("applied-custom") then
		np:SetAttribute("applied-custom", true)
		np:HookScript("OnAttributeChanged", NamePlateOnAttributeChanged)
		np:HookScript("OnHide", function(frame)
			if frame._unit then
				self:NAME_PLATE_UNIT_REMOVED(frame._unit)
			end
			frame:SetScale(1)
		end)
	end

	ActiveNamePlateUnits[unit] = np

	if SecureNamePlateDriver:CanResizeNamePlates() then
		C_NamePlate.SetNamePlateSize(np, C_CVar.GetNumber("nameplateWidth"), C_CVar.GetNumber("nameplateHeight"))
	end
	np._unit = unit
	np._class = select(2, UnitClass(unit))
	np:SetAttribute("unit", unit)
	np:SetAttribute("class", np._class)
	EventRegistry:TriggerEvent("NamePlateManager.UnitAdded", unit, np)
end

function SecureNamePlateDriver:NAME_PLATE_UNIT_REMOVED(unit)
	local np = ActiveNamePlateUnits[unit]
	ActiveNamePlateUnits[unit] = nil
	if not np then
		return
	end
	EventRegistry:TriggerEvent("NamePlateManager.UnitRemoved", unit, np)

	np._unit = nil
	np._class = nil
	np:SetAttribute("unit", nil)
	np:SetAttribute("class", nil)
end

function SecureNamePlateDriver:PLAYER_ENTERING_WORLD()
	C_NamePlateManager.CheckNamePlateMotion()
	self:RefreshNamePlateSizes()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function SecureNamePlateDriver:RefreshNamePlateSizes()
	if SecureNamePlateDriver:CanResizeNamePlates() then
		local width, height = C_CVar.GetNumber("nameplateWidth"), C_CVar.GetNumber("nameplateHeight")
		for np in C_NamePlateManager.EnumerateActiveNamePlates() do
			C_NamePlate.SetNamePlateSize(np, width, height)
		end
	end
end

local xpos, ypos, plates = {}, {}, {}
function SecureNamePlateDriver:OnUpdate(elapsed)
	if self.updateRate and self.updateRate > elapsed then
		self.updateRate = self.updateRate - elapsed
		return
	else
		self.updateRate = 0.02
	end
	local maxHeight = WorldFrame:GetTop() * (1-C_CVar.GetNumber("nameplateCeiling"))
	local speed = self:GetAttribute("speed") or 0.6 -- just config how fast these move 
	local delta = 0.00005 * speed
	local npWidth, npHeight = C_NamePlateManager.GetNamePlateSize()
	local xspace = npWidth
	local yspace = C_CVar.GetNumber("nameplateOverlapV") * (npHeight + 10)
	local includeFriendly = C_CVar.GetBool("nameplateFriendlySmoothStacking")
	wipe(xpos)
	wipe(ypos)
	wipe(plates)

	-- first iteration to collect valid nameplates
	for nameplate in C_NamePlateManager.EnumerateActiveNamePlates() do
		local include = true
		local unit = nameplate:GetAttribute("unit")
		if not unit then
			include = false
		end
		
		if not includeFriendly then
			local reaction = UnitReaction("player", unit)
			if reaction and reaction > 4 then
				include = false
			end
		end

		if include then
			local scale = nameplate:GetEffectiveScale()
			local x, y = select(4, nameplate:GetPoint(1))
			x, y = x*scale, y*scale
			tinsert(xpos,x)
			tinsert(ypos,y)
			tinsert(plates, nameplate)
		else
			nameplate:SetScale(1)
		end
	end

	-- 🧙‍♂️🧙‍♂️🧙‍♂️🧙‍♂️🧙‍♂️🧙‍♂️
	for i, nameplate in ipairs(plates) do
		local scale = nameplate:GetEffectiveScale()
		local min = 1000
		local reset = true
		for j in ipairs(plates) do
			if j ~= i then
				local xdiff = xpos[i] - xpos[j]
				local sydiff = ypos[i] - ypos[j]
				local ydiff = ypos[i]/scale - ypos[j]
				if abs(xdiff) < xspace then
					if sydiff >= 0 and abs(sydiff) < min then
						min = abs(sydiff)
					end
					if abs(ydiff) < 1.3*yspace then
						reset = false
					end
				end
			end
		end
		local nameplateTop = nameplate:GetTop()
		
		local isOffset = scale >= 1+delta

		if isOffset and nameplateTop >= maxHeight + 4 then
			nameplate:SetScale(scale - 0.8*exp(1-0.0005/(scale-1))*delta)
		elseif nameplateTop < maxHeight - 4 then
			if isOffset and reset then
				nameplate:SetScale(scale - 0.8*exp(1-0.0005/(scale-1))*delta)
			elseif  min < yspace then
				nameplate:SetScale(scale + 0.5*exp(1-min/yspace)*delta)
			elseif (isOffset and min > yspace + 5*speed) then
				nameplate:SetScale(scale - exp(1-(yspace/min)*3)*delta)
			end
		elseif isOffset and reset then
			nameplate:SetScale(scale - 0.01*exp(1-0.0005/(scale-1))*delta)
		end
	end
end

function SecureNamePlateDriver:EnableSmoothStacking()
	-- Stretching of WorldFrame - used so that the nameplates only move in the y-direction
	-- Coordinates of the nameplates also scale with the frame <- thanks blizzard
	-- x = x*scale << y = y*scale if x << y 
	local ScreenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
	local ScreenHeight = 768
	WorldFrame:ClearAllPoints()
	WorldFrame:SetWidth(ScreenWidth*8)
	WorldFrame:SetHeight(ScreenHeight*100)
	-- Shift so that nameplates are already displayed outside the screen borders
	WorldFrame:SetPoint("TOPRIGHT", 4*ScreenWidth, 0)
	self:SetScript("OnUpdate", self.OnUpdate)
end

function SecureNamePlateDriver:DisableSmoothStacking()
	WorldFrame:ClearAllPoints()
	WorldFrame:SetAllPoints()
	self:SetScript("OnUpdate", nil)
end

function test()
	if SecureNamePlateDriver:GetScript("OnUpdate") then
		SecureNamePlateDriver:SetAttribute("smooth-stacking", false)
	else
		SecureNamePlateDriver:SetAttribute("smooth-stacking", true)
	end
end

---
--- C_NamePlateManager
---

function C_NamePlateManager.CheckNamePlateMotion()
	local smoothStackingEnabled = SecureNamePlateDriver:GetAttribute("smooth-stacking")
	local smoothStackingCVar = C_CVar.GetBool("nameplateSmoothStacking")
	local allowOverlap = C_CVar.GetBool("nameplateAllowOverlap")
	if smoothStackingEnabled then
		-- smooth stacking is currently enabled
		if smoothStackingCVar and allowOverlap then
			-- do nothing its fine how it is
			return
		else
			-- smooth stacking is enabled but the cvars are not compatible
			SecureNamePlateDriver:SetAttribute("smooth-stacking", false)
		end
	else
		-- smooth stacking is currently disabled
		if smoothStackingCVar and allowOverlap then
			-- enable smooth stacking
			SecureNamePlateDriver:SetAttribute("smooth-stacking", true)
		end
	end
end

if not C_NamePlate then
	C_NamePlate = {}

	function C_NamePlate.GetNamePlateForUnit(unit)
		return GetNamePlateForUnit(unit)
	end
	
	function C_NamePlate.SetNamePlateSize(nameplate, width, height)
	if not SecureNamePlateDriver:CanResizeNamePlates() then return end
	SecureNamePlateDriver:SetNameplateSize(nameplate, width, height)
end
end


function C_NamePlateManager.EnumerateActiveNamePlates()
	local unit
	return function()
		unit = next(ActiveNamePlateUnits, unit)
		if unit then
			return C_NamePlate.GetNamePlateForUnit(unit)
		end
	end
end

function C_NamePlateManager.SetNamePlateSize(width, height)
	C_CVar.Set("nameplateWidth", width)
	C_CVar.Set("nameplateHeight", height)
	for np in C_NamePlateManager.EnumerateActiveNamePlates() do
		C_NamePlate.SetNamePlateSize(np, width, height)
	end
end

function C_NamePlateManager.RefreshNamePlateSize()
	if SecureNamePlateDriver:CanResizeNamePlates() then
		local width = C_CVar.GetNumber("nameplateWidth")
		local height = C_CVar.GetNumber("nameplateHeight")
		for np in C_NamePlateManager.EnumerateActiveNamePlates() do
			C_NamePlate.SetNamePlateSize(np, width, height)
		end
	end
end

local function MoveNameplate(nameplate, x, y)
	nameplate.MOVING = true
	nameplate:Hide()
	nameplate:SetPoint("CENTER", WorldFrame, "BOTTOMLEFT", x, y)
	nameplate:Show()
	nameplate.MOVING = nil
	nameplate.x, nameplate.y = x, y
end

local function UpdateAlphaAndLevel(self)
	local nameplate = self.nameplate
	local parent = self.parent
	local a = parent:GetAlpha()
	if a ~= nameplate:GetAlpha() then
		nameplate:SetAlpha(a)
	end

	local level = parent:GetFrameLevel()
	if level ~= nameplate:GetFrameLevel() then
		nameplate:SetFrameLevel(level)
	end
end

local function ReduceNamePlateLag(self, x, y)
	--x, y = MRound(x), MRound(y)
	local nameplate = self.nameplate
	if nameplate.x ~= x or nameplate.y ~= y then
		MoveNameplate(nameplate, x, y)
	end

	UpdateAlphaAndLevel(self)
end

function C_NamePlateManager.IsNamePlateMoving(nameplate)
	return nameplate.MOVING
end

-- Applies fps increase to frames attached to a nameplate.
-- !!Do not!! SetPoint of this nameplate object onto the actual nameplate frame.
-- this should be an immediate child of a nameplate frame. ex WorldFrame -> Default NamePlate -> this NamePlate
function C_NamePlateManager.ApplyFPSIncrease(nameplate)
	local nameplateFrame = nameplate:GetParent()
	if C_CVar.GetBool("highPrecisionNameplates") then
		nameplate:SetPoint("BOTTOM", nameplateFrame, "BOTTOM", 0, 0)
		return
	end
	if nameplate.movementCallback then return end
	local movementCallback = CreateFrame("Frame", nil, nameplate)
	nameplate.movementCallback = movementCallback

	nameplateFrame:HookScript("OnHide", function()
		nameplate:Hide()
	end)
	nameplateFrame:HookScript("OnShow", function()
		nameplate:Show()
	end)

	movementCallback.nameplate = nameplate
	movementCallback.parent = nameplateFrame
	movementCallback:SetPoint("BOTTOMLEFT", WorldFrame)
	movementCallback:SetPoint("TOPRIGHT", nameplateFrame, "CENTER")

	RunNextFrame(function()
		nameplate:SetParent(WorldFrame) -- this causes weird flickering if run immediately
		nameplate:ClearAllPoints() -- it cannot be attached to the nameplate frame
		--movementCallback.nameplate = nameplate
		
		-- run this now so nameplates dont require camera movement to load in
		ReduceNamePlateLag(movementCallback, movementCallback:GetSize())

		movementCallback:SetScript("OnSizeChanged", ReduceNamePlateLag)
		movementCallback:RegisterEvent("PLAYER_TARGET_CHANGED")
		movementCallback:SetScript("OnEvent", function(self)
			RunNextFrame(GenerateClosure(UpdateAlphaAndLevel, self))
		end)
	end)
end

local hiddenParent = CreateFrame('Frame', nil, UIParent)
hiddenParent:Hide()

function C_NamePlateManager.DisableBlizzPlate(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if nameplate and not nameplate:GetAttribute("disabled-blizz-plate") then
		nameplate:SetAttribute("disabled-blizz-plate", true)
		-- we have to preserve the base frame since the unit frame will attach to it
		local blizzElements = {nameplate:GetRegions()}
		local healthBar, castBar = nameplate:GetChildren()
		tinsert(blizzElements, healthBar)
		tinsert(blizzElements, castBar)

		for _, child in ipairs(blizzElements) do
			if child ~= nameplate.ClickBoxDebug then
				child:SetParent(hiddenParent)
				child:SetAlpha(0)
				child:Hide()
				if child.SetTexture then
					child:SetTexture()
				elseif child.SetStatusBarTexture then
					child:SetStatusBarTexture(nil) -- this needs nil
				end
			end
		end
	end
end

function C_NamePlateManager.SetEnableResizeNamePlates(enabled)
	SecureNamePlateDriver:SetAttribute("nameplate-resize", enabled)
end

function C_NamePlateManager.GetNamePlateSize()
	local width, height = 200, 50
	if SecureNamePlateDriver:CanResizeNamePlates() then
		width, height = C_CVar.GetNumber("nameplateWidth"), C_CVar.GetNumber("nameplateHeight")
	end
	
	return width, height
end

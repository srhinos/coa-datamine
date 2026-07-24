--Widget Handlers
local OPTION_TABLE_NONE = {}
BOSS_DEBUFF_SIZE_INCREASE = 9
CUF_READY_CHECK_DECAY_TIME = 11
DISTANCE_THRESHOLD_SQUARED = 250*250
CUF_NAME_SECTION_SIZE = 15
CUF_AURA_BOTTOM_OFFSET = 2

-- Global -> Local performance increase
local wipe, tinsert = wipe, tinsert
local max, min = max, min
local ipairs, pairs, select, error = ipairs, pairs, select, error
local C_CVar_GetNumber = C_CVar.GetNumber
local GroupUtil_IsInGroup = GroupUtil.IsInGroup
local CastingBarFrame_OnLoad = CastingBarFrame_OnLoad
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local CooldownFrame_Clear = CooldownFrame_Clear
local CreateFrame = CreateFrame
local UnitExists = UnitExists
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInRaid = UnitInRaid
local UnitTargetsVehicleInRaidUI = UnitTargetsVehicleInRaidUI
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitIsConnected = UnitIsConnected
local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local UnitIsPVP = UnitIsPVP
local UnitSelectionColor = UnitSelectionColor
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPowerType = UnitPowerType
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local UnitIsUnit = UnitIsUnit
local UnitInVehicle = UnitInVehicle
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitHealthPercent = UnitHealthPercent
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitDistanceSquared = UnitDistanceSquared
local UnitInRange = UnitInRange
local PowerBarColor = PowerBarColor
local GetUnitName = GetUnitName
local GetThreatStatusColor = GetThreatStatusColor
local UnitGroupRolesAssignedKey = UnitGroupRolesAssignedKey
local UnitMissingHealth = UnitMissingHealth
local UnitClassification = UnitClassification
local UnitInParty = UnitInParty
local GetRaidRosterInfo = GetRaidRosterInfo
local GetTexCoordsForRoleSmallCircle = GetTexCoordsForRoleSmallCircle
local GetReadyCheckTimeLeft = GetReadyCheckTimeLeft
local GetReadyCheckStatus = GetReadyCheckStatus
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff
local AuraUtil_UnitShouldShowBuff = AuraUtil.UnitShouldShowBuff
local AuraUtil_IsPriorityDebuff = AuraUtil.IsPriorityDebuff
local AuraUtil_UnitShouldShowDebuff = AuraUtil.UnitShouldShowDebuff
local DebuffTypeColor = DebuffTypeColor

-- UNIT_AURA event throttle / batching
local GroupedUpdateFrame = CreateFrame("Frame")
GroupedUpdateFrame:SetScript("OnUpdate", function(self)
	if not self.updateQueue then return end
	
	-- add throttle option using number cvar raidFramesUpdateRate
	local throttle = C_CVar_GetNumber("raidFramesUpdateRate")
	if throttle and throttle > 0 then
		if self.lastUpdate then
			if self.lastUpdate:LessThan(throttle) then
				return
			else
				self.lastUpdate:ResetToNow()
			end
		else
			self.lastUpdate = TimeSince:Now()
		end
	end
	-- actually update the frames
	for updateType, frames in pairs(self.updateQueue) do
		for _, frame in ipairs(frames) do
			if frame:IsVisible() then
				frame[updateType](frame)
			end
		end
	end

	wipe(self.updateQueue)
	self:Hide()
end)

-- queues a frame to update, this is to prevent multiple updates of the same kind in the same frame or raidFramesUpdateRate
function GroupedUpdateFrame:QueueUpdate(frame, updateType)
	if not self.updateQueue then
		self.updateQueue = {}
	end
	if not self.updateQueue[updateType] then
		self.updateQueue[updateType] = {}
	end
	tinsert(self.updateQueue[updateType], frame)
	self:Show()
end

CompactUnitMixin = {}

function CompactUnitMixin:OnLoad()
	if not self:GetName() then
		self:Hide()
		error("CompactUnitFrames must have a name")	--Sorry! Don't feel like re-writing unit popups.
	end
	
	AttributesToKeyValues(self)
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_POWER_BAR_SHOW")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_CONNECTION")
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_FINISHED")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("INCOMING_RESURRECT_CHANGED")
	self:RegisterEvent("UNIT_OTHER_PARTY_CHANGED")
	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
	self:RegisterEvent("UNIT_PHASE")
	self:RegisterEvent("GROUP_JOINED")
	self:RegisterEvent("GROUP_LEFT")
	-- also see CompactUnitMixin:UpdateUnitEvents for more events
	
	self.maxBuffs = 0
	self.maxDebuffs = 0
	self.maxDispelDebuffs = 0
	self:SetOptionTable(OPTION_TABLE_NONE)

	if not self.disableMouse then
		self:SetUpClicks()
		tinsert(UnitPopupFrames, self.dropDown:GetName())
	end
end

function CompactUnitMixin:OnEvent(event, ...)
	local arg1, arg2, arg3, arg4 = ...
	if ( event == self.updateAllEvent and (not self.updateAllFilter or self.updateAllFilter(self, event, ...)) ) then
		self:UpdateAll()
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		self:UpdateAll()
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		self:UpdateSelectionHighlight()
		self:UpdateName()
		self:UpdateHealthBorder()
		self:UpdateTargetScale()
	elseif ( event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" ) then
		self:UpdateAuras()	--We filter differently based on whether the player is in Combat, so we need to update when that changes.
	elseif ( event == "PLAYER_ROLES_ASSIGNED" ) then
		self:UpdateRoleIcon()
	elseif ( event == "READY_CHECK" ) then
		self:UpdateReadyCheck()
	elseif ( event == "READY_CHECK_FINISHED" ) then
		self:FinishReadyCheck()
	elseif ( event == "PARTY_MEMBER_DISABLE" or event == "PARTY_MEMBER_ENABLE" ) then	--Alternate power info may now be available.
		self:UpdateMaxPower()
		self:UpdatePower()
		self:UpdatePowerColor()
	elseif ( event == "QUEST_LOG_UPDATE" or event == "QUEST_QUERY_COMPLETE" ) then
		self:UpdateQuestIcon()
	elseif arg1 == self.unit or arg1 == self.displayedUnit then
		if ( event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" ) then
			self:UpdateMaxHealth()
			self:UpdateHealth()
			self:UpdateStatusText()
			self:UpdateHealPrediction()
		elseif ( event == "UNIT_MAXPOWER" or event == "UNIT_MAXMANA" or event == "UNIT_MAXRAGE" or event == "UNIT_MAXENERGY" ) then
			self:UpdateMaxPower()
			self:UpdatePower()
		elseif ( event == "UNIT_POWER" or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" ) then
			self:UpdatePower()
		elseif ( event == "UNIT_DISPLAYPOWER" or event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" ) then
			self:UpdateMaxPower()
			self:UpdatePower()
			self:UpdatePowerColor()
		elseif ( event == "UNIT_NAME_UPDATE" ) then
			self:UpdateName()
			self:UpdateHealthColor()	--This may signify that we now have the unit's class (the name cache entry has been received).
		elseif ( event == "UNIT_AURA" ) then
			self:UpdateAuras()
		elseif ( event == "UNIT_THREAT_SITUATION_UPDATE" ) then
			self:UpdateAggroHighlight()
			self:UpdateAggroFlash()
			self:UpdateHealthBorder()
		elseif ( event == "UNIT_THREAT_LIST_UPDATE" ) then
			if ( self.optionTable.considerSelectionInCombatAsHostile ) then
				self:UpdateHealthColor()
				self:UpdateName()
			end
			self:UpdateAggroFlash()
			self:UpdateHealthBorder()
		elseif event == "UNIT_CONNECTION" then
			--Might want to set the health/mana to max as well so it's easily visible? This happens unless the player is out of AOI.
			self:UpdateHealthColor()
			self:UpdatePowerColor()
			self:UpdateStatusText()
			self:UpdateHealPrediction()
		elseif ( event == "UNIT_HEAL_PREDICTION" ) then
			self:UpdateHealPrediction()
		elseif ( event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" or event == "UNIT_PET" ) then
			self:UpdateAll()
		elseif ( event == "READY_CHECK_CONFIRM" ) then
			self:UpdateReadyCheck()
		elseif ( event == "INCOMING_RESURRECT_CHANGED" ) then
			self:UpdateCenterStatusIcon()
		elseif ( event == "UNIT_OTHER_PARTY_CHANGED" ) then
			self:UpdateCenterStatusIcon()
		elseif ( event == "UNIT_ABSORB_AMOUNT_CHANGED" ) then
			self:UpdateHealPrediction()
		elseif ( event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" ) then
			self:UpdateHealPrediction()
		elseif ( event == "PLAYER_FLAGS_CHANGED" ) then
			self:UpdateStatusText()
		elseif ( event == "UNIT_PHASE" ) then
			self:UpdateCenterStatusIcon()
		elseif ( event == "GROUP_JOINED" ) then
			self:UpdateAggroFlash()
			self:UpdateHealthBorder()
		elseif ( event == "GROUP_LEFT" ) then
			self:UpdateHealthBorder()
		elseif ( event == "UNIT_LEVEL" ) then
			self:UpdateLevelIndicator()
		end
	end
end

--DEBUG FIXME - We should really try to avoid having OnUpdate on every frame. An event when going in/out of range would be greatly preferred.
function CompactUnitMixin:OnUpdate(elapsed)
	self:UpdateInRange()
	self:UpdateDistance()
	self:CheckReadyCheckDecay(elapsed)
	if self.optionTable.hoverBorderColor then
		self:UpdateHealthBorder() -- nameplates use this, honestly need a better way to do this but nameplates have no onenter/onleave
	end
end

--Externally accessed functions
function CompactUnitMixin:SetUnit(unit)
	if unit ~= self.unit or self.hideCastbar ~= self.optionTable.hideCastbar then
		self.unit = unit
		self.displayedUnit = unit	--May differ from unit if unit is in a vehicle.
		self.inVehicle = false
		self.readyCheckStatus = nil
		self.readyCheckDecay = nil
		self.isTanking = nil
		self.hideCastbar = self.optionTable.hideCastbar
		self.healthBar.healthBackground = nil
		self:SetAttribute("unit", unit)
		if unit then
			self:RegisterEvents()
		else
			self:UnregisterEvents()
		end
		if unit and not self.optionTable.hideCastbar then
			if self.castBar then
				CastingBarFrame_OnLoad(self.castBar, unit, false, true)
			end
		else
			if self.castBar then
				CastingBarFrame_OnLoad(self.castBar, nil, nil, nil)
			end
		end
		self:UpdateAll()
	end
end

--PLEEEEEASE FIX ME. This makes me very very sad. (Unfortunately, there isn't a great way to deal with the lack of "raid1targettarget" events though)
function CompactUnitMixin:SetUpdateAllOnUpdate(doUpdate)
	if doUpdate then
		if not self.onUpdateFrame then
			self.onUpdateFrame = CreateFrame("Frame")	--Need to use this so UpdateAll is called even when the frame is hidden.
			self.onUpdateFrame.func = function(updateFrame, elapsed) if self.displayedUnit then self:UpdateAll() end end
		end
		self.onUpdateFrame:SetScript("OnUpdate", self.onUpdateFrame.func)
	else
		if self.onUpdateFrame then
			self.onUpdateFrame:SetScript("OnUpdate", nil)
		end
	end
end

--Things you'll have to set up to get everything looking right:
--1. Frame size
--2. Health/Mana bar positions
--3. Health/Mana bar textures (also, optionally, background textures)
--4. Name position
--5. Buff/Debuff/Dispellable positions
--6. Call CompactUnitFrame_SetMaxBuffs, _SetMaxDebuffs, and _SetMaxDispelDebuffs. (If you're setting it to greater than the default, make sure to create new buff/debuff frames and position them.)
--7. Selection highlight position and texture.
--8. Aggro highlight position and texture
--9. Role icon position
function CompactUnitMixin:SetUpFrame(func)
	func(self)
	self:UpdateAll()
end

function CompactUnitMixin:SetOptionTable(optionTable)
	self.optionTable = optionTable
	self:UpdateAll()
end

function CompactUnitMixin:RegisterEvents()
	self:SetScript("OnEvent", self.OnEvent)
	self:UpdateUnitEvents()
	self:SetScript("OnUpdate", self.OnUpdate)
end

function CompactUnitMixin:UpdateUnitEvents()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_HEALTH_FREQUENT")
	self:RegisterEvent("UNIT_MAXPOWER")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_MAXMANA")
	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_MAXRAGE")
	self:RegisterEvent("UNIT_RAGE")
	self:RegisterEvent("UNIT_MAXENERGY")
	self:RegisterEvent("UNIT_ENERGY")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UNIT_LEVEL")
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	self:RegisterEvent("UNIT_HEAL_PREDICTION")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self:RegisterEvent("PARTY_MEMBER_DISABLE")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("UNIT_FACTION")
	if self.questIcon then
		self:RegisterEvent("QUEST_LOG_UPDATE")
		self:RegisterEvent("QUEST_QUERY_COMPLETE")
	end
end

function CompactUnitMixin:UnregisterEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnUpdate", nil)
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_MAXHEALTH")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
	self:UnregisterEvent("UNIT_MAXPOWER")
	self:UnregisterEvent("UNIT_POWER")
	self:UnregisterEvent("UNIT_MAXMANA")
	self:UnregisterEvent("UNIT_MANA")
	self:UnregisterEvent("UNIT_MAXRAGE")
	self:UnregisterEvent("UNIT_RAGE")
	self:UnregisterEvent("UNIT_MAXENERGY")
	self:UnregisterEvent("UNIT_ENERGY")
	self:UnregisterEvent("UNIT_LEVEL")
	self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
	self:UnregisterEvent("UNIT_HEAL_PREDICTION")
	self:UnregisterEvent("PLAYER_FLAGS_CHANGED")
	self:UnregisterEvent("PARTY_MEMBER_DISABLE")
	self:UnregisterEvent("PARTY_MEMBER_ENABLE")
	self:UnregisterEvent("UNIT_FACTION")
	if self.questIcon then
		self:UnregisterEvent("QUEST_LOG_UPDATE")
		self:UnregisterEvent("QUEST_QUERY_COMPLETE")
	end
end

function CompactUnitMixin:SetUpClicks()
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "menu")
	--NOTE: Make sure you also change the CompactAuraTemplate. (It has to be registered for clicks to be able to pass them through.)
	self:RegisterForClicks("AnyUp")
	self:SetMenuFunc(CompactUnitFrameDropDown_Initialize)
end

function CompactUnitMixin:SetMenuFunc(menuFunc)
	UIDropDownMenu_Initialize(self.dropDown, menuFunc, "MENU")
	self.menu = function()
		ToggleDropDownMenu(1, nil, self.dropDown, self:GetName(), 0, 0)
	end
end

function CompactUnitMixin:SetMaxBuffs(numBuffs)
	self.maxBuffs = numBuffs
end

function CompactUnitMixin:SetMaxDebuffs(numDebuffs)
	self.maxDebuffs = numDebuffs
end

function CompactUnitMixin:SetMaxDispelDebuffs(numDispelDebuffs)
	self.maxDispelDebuffs = numDispelDebuffs
end

function CompactUnitMixin:SetUpdateAllEvent(updateAllEvent, updateAllFilter)
	if self.updateAllEvent then
		self:UnregisterEvent(self.updateAllEvent)
	end
	self.updateAllEvent = updateAllEvent
	self.updateAllFilter = updateAllFilter
	self:RegisterEvent(updateAllEvent)
end

--Internally accessed functions

--Update Functions
function CompactUnitMixin:UpdateAll()
	self:UpdateInVehicle()
	self:UpdateVisible()
	if UnitExists(self.displayedUnit) then
		self:QueueUpdateAuras()

		self:UpdateMaxHealth()
		self:UpdateHealth()
		self:UpdateHealthColor()
		self:UpdateMaxPower()
		self:UpdatePower()
		self:UpdatePowerColor()
		self:UpdateAggroHighlight()
		self:UpdateAggroFlash()
		self:UpdateHealthBorder()
		self:UpdateInRange()
		self:UpdateStatusText()
		self:UpdateHealPrediction()
		self:UpdateRoleIcon()
		self:UpdateReadyCheck()
		self:UpdateName()
		self:UpdateSelectionHighlight()
		self:UpdateTargetScale()
		self:UpdateCenterStatusIcon()
		self:UpdateClassificationIndicator()
		self:UpdateLevelIndicator()
		self:UpdateQuestIcon()
	end
end

function CompactUnitMixin:UpdateInVehicle()
	local shouldTargetVehicle = UnitHasVehicleUI(self.unit)
	local unitVehicleToken
	
	if shouldTargetVehicle then
		local raidID = UnitInRaid(self.unit)
		if raidID and not UnitTargetsVehicleInRaidUI(self.unit) then
			shouldTargetVehicle = false
		end
	end

	if shouldTargetVehicle then
		local prefix, id, suffix = string.match(self.unit, "([^%d]+)([%d]*)(.*)")
		unitVehicleToken = prefix.."pet"..id..suffix
		if not UnitExists(unitVehicleToken) then
			shouldTargetVehicle = false
		end
	end
	
	if shouldTargetVehicle then
		if ( not self.hasValidVehicleDisplay ) then
			self.hasValidVehicleDisplay = true
			self.displayedUnit = unitVehicleToken
			self:SetAttribute("unit", self.displayedUnit)
			self:UpdateUnitEvents()
		end
	else
		if ( self.hasValidVehicleDisplay ) then
			self.hasValidVehicleDisplay = false
			self.displayedUnit = self.unit
			self:SetAttribute("unit", self.displayedUnit)
			self:UpdateUnitEvents()
		end
	end
end

function CompactUnitMixin:UpdateVisible()
	if UnitExists(self.unit) or UnitExists(self.displayedUnit) then
		if not self.unitExists then
			self.newUnit = true
		end

		self.unitExists = true
		self:Show()
	else
		self:Hide()
		self.unitExists = false
	end
end

function CompactUnitMixin:IsTapDenied()
	return self.optionTable.greyOutWhenTapDenied and not UnitPlayerControlled(self.unit) and UnitIsTapped(self.unit) and not UnitIsTappedByPlayer(self.unit)
end

local function IsOnThreatList(threatStatus)
	return threatStatus ~= nil
end

function CompactUnitMixin:IsOnThreatListWithPlayer()
	if not self.displayedUnit or not UnitExists(self.displayedUnit) then
		return false 
	end
	local _, threatStatus = UnitDetailedThreatSituation("player", self.displayedUnit)
	return IsOnThreatList(threatStatus)
end

function CompactUnitMixin:UpdateHealthColor()
	local r, g, b
	if not UnitIsConnected(self.unit) then
		--Color it gray
		r, g, b = 0.5, 0.5, 0.5
	else
		if self.optionTable.healthBarColorOverride then
			local healthBarColorOverride = self.optionTable.healthBarColorOverride
			r, g, b = healthBarColorOverride.r, healthBarColorOverride.g, healthBarColorOverride.b
		else
			local isPlayer = UnitIsPlayer(self.displayedUnit)
			local localizedClass, englishClass = UnitClass(self.unit)
			local classColor = RAID_CLASS_COLORS[englishClass]
			-- try to color by primary stat
			if isPlayer and self.optionTable.usePrimaryStatColor and englishClass == "HERO" then
				local primaryStat = UnitPrimaryStat(self.displayedUnit)
				local primaryStatColor = STAT_COLORS[primaryStat]
				if primaryStatColor then
					r, g, b = primaryStatColor.r, primaryStatColor.g, primaryStatColor.b
				elseif classColor then
					r, g, b = classColor.r, classColor.g, classColor.b
				elseif UnitIsFriend("player", self.displayedUnit) then
					r, g, b = 0.0, 1.0, 0.0
				else
					r, g, b = 1.0, 0.0, 0.0
				end
			elseif (self.optionTable.allowClassColorsForNPCs or isPlayer) and classColor and self.optionTable.useClassColors then
				--Try to color it by class.
				-- Use class colors for players if class color option is turned on
				r, g, b = classColor.r, classColor.g, classColor.b
			elseif self:IsTapDenied() then
				-- Use grey if not a player and can't get tap on unit
				r, g, b = 0.9, 0.9, 0.9
			elseif self.optionTable.colorHealthBySelection then
				-- Use color based on the type of unit (neutral, etc.)
				if self.optionTable.considerSelectionInCombatAsHostile and self:IsOnThreatListWithPlayer() then
					r, g, b = 1.0, 0.0, 0.0
				elseif isPlayer and UnitIsFriend("player", self.displayedUnit) then
					-- We don't want to use the selection color for friendly player nameplates because
					-- it doesn't show player health clearly enough.
					if UnitIsPVP(self.displayedUnit) then
						r, g, b = 0.0, 1.0, 0.0
					else
						r, g, b = 0.667, 0.667, 1.0
					end
				else
					r, g, b = UnitSelectionColor(self.unit, self.optionTable.colorHealthWithExtendedColors)
				end
			elseif UnitIsFriend("player", self.unit) then
				if UnitIsPVP(self.displayedUnit) then
					r, g, b = 0.0, 1.0, 0.0
				else
					r, g, b = 0.667, 0.667, 1.0
				end
			else
				r, g, b = 1.0, 0.0, 0.0
			end
		end
	end
	if r ~= self.healthBar.r or g ~= self.healthBar.g or b ~= self.healthBar.b then
		self.healthBar:SetStatusBarColor(r, g, b)

		if self.optionTable.colorHealthWithExtendedColors then
			self.Elements.selectionHighlight:SetVertexColor(r, g, b)
		else
			self.Elements.selectionHighlight:SetVertexColor(1, 1, 1)
		end

		self.healthBar.r, self.healthBar.g, self.healthBar.b = r, g, b
	end
end

function CompactUnitMixin:UpdateMaxHealth()
	local maxHealth = UnitHealthMax(self.displayedUnit)
	self.healthBar:SetMinMaxValues(0, maxHealth)
end

function CompactUnitMixin:UpdateHealth()
	local health = UnitHealth(self.displayedUnit)
	self.healthBar:SetValue(health)

	if self.optionTable.onlyShowHealthWhenDamaged then
		if health < UnitHealthMax(self.displayedUnit) or UnitIsUnit(self.displayedUnit, "target") or self:IsOnThreatListWithPlayer() then
			self.healthBar:SetAlpha(1)
		else
			self.healthBar:SetAlpha(0)
		end
	else
		self.healthBar:SetAlpha(1)
	end
end

function CompactUnitMixin:GetDisplayedPowerID()
	return UnitPowerType(self.displayedUnit)
end

function CompactUnitMixin:UpdateMaxPower()	
	if self.powerBar then
		self.powerBar:SetMinMaxValues(0, UnitPowerMax(self.displayedUnit, self:GetDisplayedPowerID()))
	end
end

function CompactUnitMixin:UpdatePower()
	if self.powerBar then
		self.powerBar:SetValue(UnitPower(self.displayedUnit, self:GetDisplayedPowerID()))
	end
end

function CompactUnitMixin:UpdatePowerColor()
	if not self.powerBar then
		return
	end

	local r, g, b
	if not UnitIsConnected(self.unit) then
		--Color it gray
		r, g, b = 0.5, 0.5, 0.5
	else
		local powerType, powerToken, altR, altG, altB = UnitPowerType(self.displayedUnit)
		local prefix = _G[powerToken]
		local info = PowerBarColor[powerToken]
		if info then
			r, g, b = info.r, info.g, info.b
		else
			if not altR then
				-- couldn't find a power token entry...default to indexing by power type or just mana if we don't have that either
				info = PowerBarColor[powerType] or PowerBarColor["MANA"]
				r, g, b = info.r, info.g, info.b
			else
				r, g, b = altR, altG, altB
			end
		end
	end
	self.powerBar:SetStatusBarColor(r, g, b)
end

function CompactUnitMixin:ShouldShowName()
	if self.optionTable.displayName then
		local failedRequirement = false
		if self.optionTable.displayNameByPlayerNameRules then
			if UnitShouldDisplayName(self.unit) then
				return true
			end
			failedRequirement = true
		end

		if self.optionTable.displayNameWhenSelected then
			if UnitIsUnit(self.unit, "target") then
				return true
			end
			failedRequirement = true
		end

		return not failedRequirement
	end

	return false
end

function CompactUnitMixin:UpdateName()
	if not self:ShouldShowName() then
		self.Elements.name:Hide()
	else
		local name = self.unit and GetUnitName(self.unit, true) or UNKNOWN
		self.Elements.name:SetText(name)

		if self:IsTapDenied() then
			-- Use grey if not a player and can't get tap on unit
			self.Elements.name:SetVertexColor(0.5, 0.5, 0.5)
		elseif self.optionTable.colorNameBySelection then
			local isPlayer = UnitIsPlayer(self.unit)
			local _, englishClass = UnitClass(self.unit)
			local classColor = RAID_CLASS_COLORS[englishClass]
			local isFriend = UnitIsFriend("player", self.displayedUnit)

			if UnitIsDeadOrGhost(self.displayedUnit) and self.optionTable.colorNameDead then
				self.Elements.name:SetVertexColor(0.5, 0.5, 0.5)
			elseif UnitIsUnit("player", self.displayedUnit) and self.optionTable.playerNameColor then
				self.Elements.name:SetVertexColor(self.optionTable.playerNameColor:GetRGBA())
			elseif isPlayer and self.optionTable.usePrimaryStatColor and englishClass == "HERO" then
				local primaryStat = UnitPrimaryStat(self.displayedUnit)
				local primaryStatColor = STAT_COLORS[primaryStat]
				if primaryStatColor then
					self.Elements.name:SetVertexColor(primaryStatColor.r, primaryStatColor.g, primaryStatColor.b)
				elseif classColor then
					self.Elements.name:SetVertexColor(classColor.r, classColor.g, classColor.b)
				elseif UnitIsFriend("player", self.displayedUnit) then
					if UnitIsPVP(self.displayedUnit) then
						self.Elements.name:SetVertexColor(0.0, 1.0, 0.0)
					else
						self.Elements.name:SetVertexColor(0.667, 0.667, 1.0)
					end
				else
					self.Elements.name:SetVertexColor(1, 0, 0)
				end
			elseif isPlayer and UnitIsFriend("player", self.unit) and self.optionTable.useClassColors then
				if classColor then
					self.Elements.name:SetVertexColor(classColor.r, classColor.g, classColor.b)
				end
			elseif self.optionTable.considerSelectionInCombatAsHostile and self:IsOnThreatListWithPlayer() then
				self.Elements.name:SetVertexColor(1.0, 0.0, 0.0)
			else
				if isPlayer and isFriend then
					if UnitIsPVP(self.displayedUnit) then
						self.Elements.name:SetVertexColor(0.0, 1.0, 0.0)
					else
						self.Elements.name:SetVertexColor(0.667, 0.667, 1.0)
					end
				else
					self.Elements.name:SetVertexColor(UnitSelectionColor(self.unit, self.optionTable.colorNameWithExtendedColors))
				end
			end
		else
			self.Elements.name:SetVertexColor(1, 1, 1)
		end

		self.Elements.name:Show()
	end
end

function CompactUnitMixin:UpdateAuras()
	self:UpdateBuffs()
	self:UpdateDebuffs()
	self:UpdateDispellableDebuffs()
end

function CompactUnitMixin:QueueUpdateAuras()
	GroupedUpdateFrame:QueueUpdate(self, "UpdateAuras")
end

function CompactUnitMixin:UpdateSelectionHighlight()
	if not self.optionTable.displaySelectionHighlight then
		self.Elements.selectionHighlight:Hide()
		return
	end

	if self.displayedUnit and UnitIsUnit(self.displayedUnit, "target") or self.unit and UnitIsUnit(self.unit, "target") then
		self.Elements.selectionHighlight:Show()
	else
		self.Elements.selectionHighlight:Hide()
	end
end

function CompactUnitMixin:UpdateTargetScale()
	if self.optionTable.nameplateTargetScale then
		if UnitIsUnit(self.unit, "target") then
			self:SetScale(self.optionTable.nameplateTargetScale)
		else
			self:SetScale(1)
		end
	end
end

function CompactUnitMixin:UpdateAggroHighlight()
	if not self.optionTable.displayAggroHighlight then
		if not self.optionTable.playLoseAggroHighlight then
			self.Elements.aggroHighlight:Hide()
		end
		return
	end
	
	local status = UnitThreatSituation(self.displayedUnit)
	if status and status > 0 then
        if self.Elements.aggroHighlight.Texture then
            self.Elements.aggroHighlight.Texture:SetVertexColor(GetThreatStatusColor(status))
        else
            self.Elements.aggroHighlight:SetVertexColor(GetThreatStatusColor(status))
        end
		self.Elements.aggroHighlight:Show()
	else
		self.Elements.aggroHighlight:Hide()
	end
end

local function IsPlayerEffectivelyTank()
	local assignedRole = UnitGroupRolesAssignedKey("player")
	-- maybe we can have roles someday
	return assignedRole == "TANK" or C_Player:IsEffectivelyTank()
end

local function SetBorderColor(frame, r, g, b, a)
	frame.healthBar.border:SetVertexColor(r, g, b, a)
	if frame.castBar and frame.castBar.border then
		frame.castBar.border:SetVertexColor(r, g, b, a)
	end
end

function CompactUnitMixin:UpdateHealthBorder()
    if not self.displayedUnit then
        return
    end
    local isTarget = UnitIsUnit(self.displayedUnit, "target")
    local isMouseover = UnitIsUnit(self.displayedUnit, "mouseover")
	if self.optionTable.hoverBorderColor and isMouseover and not isTarget then
		SetBorderColor(self, self.optionTable.hoverBorderColor:GetRGBA())
		return
	end

	if self.optionTable.tankThreatBorderColor and self.optionTable.tankNoThreatBorderColor and GroupUtil_IsInGroup() then
		local isTanking, threatStatus = UnitDetailedThreatSituation("player", self.displayedUnit)
        if IsPlayerEffectivelyTank() then
            if IsOnThreatList(threatStatus) then
                if isTanking then
                    if isTarget then
                        SetBorderColor(self, self.optionTable.tankThreatTargetBorderColor:GetRGBA())
                    else
                        SetBorderColor(self, self.optionTable.tankThreatBorderColor:GetRGBA())
                    end
                    return
                else
                    if isTarget then
                        SetBorderColor(self, self.optionTable.tankNoThreatTargetBorderColor:GetRGBA())
                    else
                        SetBorderColor(self, self.optionTable.tankNoThreatBorderColor:GetRGBA())
                    end
                    return
                end
            end
        else
            if IsOnThreatList(threatStatus) then
                if isTanking then
                    if isTarget then
                        SetBorderColor(self, self.optionTable.tankThreatTargetBorderColor:GetRGBA())
                    else
                        SetBorderColor(self, self.optionTable.tankThreatBorderColor:GetRGBA())
                    end
                    return
                end
            end
        end
	end

    if self.optionTable.selectedBorderColor and isTarget then
        SetBorderColor(self, self.optionTable.selectedBorderColor:GetRGBA())
        return
    end

	if self.optionTable.defaultBorderColor then
		SetBorderColor(self, self.optionTable.defaultBorderColor:GetRGBA())
		return
	end
end

function CompactUnitMixin:UpdateAggroFlash()
	if self.optionTable.displayAggroHighlight or not self.optionTable.playLoseAggroHighlight then
		return
	end

	local isTanking = UnitDetailedThreatSituation("player", self.displayedUnit)
	if self.isTanking ~= isTanking then
        local wasTanking = self.isTanking
        self.isTanking = isTanking
        if wasTanking == nil then -- no flash for initial aggro
            return
        end
        
        local shouldBeTanking = IsPlayerEffectivelyTank()
        if self.isTanking ~= shouldBeTanking then
            -- flash if current state is not the state it should be (ex dps tanking or tank not tanking)
            self.Elements.aggroHighlight:Show()
            self.LoseAggroAnim:Play()
        end
	end

	if not self.LoseAggroAnim:IsPlaying() then
		self.Elements.aggroHighlight:Hide()
	end
end

function CompactUnitMixin:UpdateInRange()
	if not self.optionTable.fadeOutOfRange then
		return
	end
	
	local inRange = UnitInRange(self.displayedUnit)
	if not inRange and UnitIsFriend("player", self.displayedUnit) then
		self:SetAlpha(0.55)
	else
		self:SetAlpha(1)
	end
end

function CompactUnitMixin:UpdateDistance()
	local distance, checkedDistance = self.displayedUnit or self.unit and UnitDistanceSquared(self.displayedUnit or self.unit)

	if checkedDistance then
		local inDistance = distance < DISTANCE_THRESHOLD_SQUARED
		if inDistance ~= self.inDistance then
			self.inDistance = inDistance
			self:UpdateCenterStatusIcon()
		end
	end
end

function CompactUnitMixin:UpdateStatusText()
	if not self.optionTable.displayStatusText then
		self.Elements.statusText:Hide()
		return
	end
	if not UnitExists(self.displayedUnit) then
		self.Elements.statusText:SetText(UNKNOWNOBJECT)
		self.Elements.statusText:Hide()
	elseif not UnitIsConnected(self.unit) then
		self.Elements.statusText:SetText(PLAYER_OFFLINE)
		self.Elements.statusText:Show()
	elseif UnitIsDeadOrGhost(self.displayedUnit) then
		self.Elements.statusText:SetText(DEAD)
		self.Elements.statusText:Show()
	elseif self.optionTable.healthText == "health" then
		self.Elements.statusText:SetText(UnitHealth(self.displayedUnit))
		self.Elements.statusText:Show()
	elseif self.optionTable.healthText == "health-full" then
		self.Elements.statusText:SetFormattedText("%d/%d", UnitHealth(self.displayedUnit), UnitHealthMax(self.displayedUnit))
		self.Elements.statusText:Show()
	elseif self.optionTable.healthText == "losthealth" then
		local healthLost = UnitMissingHealth(self.displayedUnit)
		if healthLost > 0 then
			self.Elements.statusText:SetFormattedText(LOST_HEALTH, healthLost)
			self.Elements.statusText:Show()
		else
			self.Elements.statusText:Hide()
		end
	elseif self.optionTable.healthText == "perc" and UnitHealthMax(self.displayedUnit) > 0 then
		local perc = UnitHealthPercent(self.displayedUnit) or 0
		self.Elements.statusText:SetFormattedText("%d%%", perc)
		self.Elements.statusText:Show()
	elseif self.optionTable.healthText == "perc-full" and UnitHealthMax(self.displayedUnit) > 0 then
		local perc = UnitHealthPercent(self.displayedUnit) or 0
		self.Elements.statusText:SetFormattedText("%d/%d - %d%%", UnitHealth(self.displayedUnit), UnitHealthMax(self.displayedUnit), perc)
		self.Elements.statusText:Show()
	else
		self.Elements.statusText:Hide()
	end
end

--WARNING: This function is very similar to the function UnitFrameHealPredictionBars_Update in UnitFrame.lua.
--If you are making changes here, it is possible you may want to make changes there as well.
local MAX_INCOMING_HEAL_OVERFLOW = 1.05
function CompactUnitMixin:UpdateHealPrediction()
	local _, maxHealth = self.healthBar:GetMinMaxValues()
	local health = self.healthBar:GetValue()

	if maxHealth <= 0 or not self.optionTable.displayHealPrediction then
		self.Elements.myHealPrediction:Hide()
		self.Elements.otherHealPrediction:Hide()
		self.Elements.totalAbsorb:Hide()
		self.Elements.totalAbsorbOverlay:Hide()
		self.Elements.overAbsorbGlow:Hide()
		self.Elements.myHealAbsorb:Hide()
		self.myHealAbsorbLeftShadow:Hide()
		self.myHealAbsorbRightShadow:Hide()
		self.Elements.overHealAbsorbGlow:Hide()
		return
	end

	local myIncomingHeal = UnitGetIncomingHeals(self.displayedUnit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(self.displayedUnit) or 0
	local totalAbsorb = UnitGetTotalAbsorbs(self.displayedUnit) or 0
	local myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(self.displayedUnit) or 0
	
	--We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
	if health < myCurrentHealAbsorb then
		self.Elements.overHealAbsorbGlow:Show()
		myCurrentHealAbsorb = health
	else
		self.Elements.overHealAbsorbGlow:Hide()
	end
	
	--See how far we're going over the health bar and make sure we don't go too far out of the frame.
	if health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * MAX_INCOMING_HEAL_OVERFLOW then
		allIncomingHeal = maxHealth * MAX_INCOMING_HEAL_OVERFLOW - health + myCurrentHealAbsorb
	end
	
	local otherIncomingHeal = 0
	
	--Split up incoming heals.
	if allIncomingHeal >= myIncomingHeal then
		otherIncomingHeal = allIncomingHeal - myIncomingHeal
	else
		myIncomingHeal = allIncomingHeal
	end

	local overAbsorb = false
	--We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
	if health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth or health + totalAbsorb >= maxHealth then
		if totalAbsorb > 0 then
			overAbsorb = true
		end
		
		if allIncomingHeal > myCurrentHealAbsorb then
			totalAbsorb = max(0,maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal))
		else
			totalAbsorb = max(0,maxHealth - health)
		end
	end
	if overAbsorb then
		self.Elements.overAbsorbGlow:Show()
	else
		self.Elements.overAbsorbGlow:Hide()
	end
	
	local healthTexture = self.healthBar:GetStatusBarTexture()
	
	local myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth
	
	local healAbsorbTexture = nil
	
	--If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
	--heal absorb will be completely overlayed by the incoming heals so we don't show it.
	if myCurrentHealAbsorb > allIncomingHeal then
		local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal
		local shownHealAbsorbPercent = shownHealAbsorb / maxHealth
		healAbsorbTexture = self:UpdateFillBar(healthTexture, self.Elements.myHealAbsorb, shownHealAbsorb, -shownHealAbsorbPercent)
		
		--If there are incoming heals the left shadow would be overlayed by the incoming heals
		--so it isn't shown.
		if allIncomingHeal > 0 then
			self.myHealAbsorbLeftShadow:Hide()
		else
			self.myHealAbsorbLeftShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPLEFT", 0, 0)
			self.myHealAbsorbLeftShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMLEFT", 0, 0)
			self.myHealAbsorbLeftShadow:Show()
		end
		
		-- The right shadow is only shown if there are absorbs on the health bar.
		if totalAbsorb > 0 then
			self.myHealAbsorbRightShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPRIGHT", -8, 0)
			self.myHealAbsorbRightShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMRIGHT", -8, 0)
			self.myHealAbsorbRightShadow:Show()
		else
			self.myHealAbsorbRightShadow:Hide()
		end
	else
		self.Elements.myHealAbsorb:Hide()
		self.myHealAbsorbRightShadow:Hide()
		self.myHealAbsorbLeftShadow:Hide()
	end
	
	--Show myIncomingHeal on the health bar.
	local incomingHealsTexture = self:UpdateFillBar(healthTexture, self.Elements.myHealPrediction, myIncomingHeal, -myCurrentHealAbsorbPercent)
	--Append otherIncomingHeal on the health bar.
	incomingHealsTexture = self:UpdateFillBar(incomingHealsTexture, self.Elements.otherHealPrediction, otherIncomingHeal)
	
	--Appen absorbs to the correct section of the health bar.
	local appendTexture
	if healAbsorbTexture then
		--If there is a healAbsorb part shown, append the absorb to the end of that.
		appendTexture = healAbsorbTexture
	else
		--Otherwise, append the absorb to the end of the the incomingHeals part
		appendTexture = incomingHealsTexture
	end
	self:UpdateFillBar(appendTexture, self.Elements.totalAbsorb, totalAbsorb)
end

--WARNING: This function is very similar to the function UnitFrame_UpdateFillBar in UnitFrame.lua.
--If you are making changes here, it is possible you may want to make changes there as well.
function CompactUnitMixin:UpdateFillBar(previousTexture, bar, amount, barOffsetXPercent)
	local totalWidth, totalHeight = self.healthBar:GetSize()

	if totalWidth == 0 or amount == 0 then
		bar:Hide()
		if bar.overlay then
			bar.overlay:Hide()
		end
		return previousTexture
	end
	
	local barOffsetX = 0
	if barOffsetXPercent then
		barOffsetX = totalWidth * barOffsetXPercent
	end

	bar:SetPoint("TOPLEFT", previousTexture, "TOPRIGHT", barOffsetX, 0)
	bar:SetPoint("BOTTOMLEFT", previousTexture, "BOTTOMRIGHT", barOffsetX, 0)

	local _, totalMax = self.healthBar:GetMinMaxValues()

	local barSize = (amount / totalMax) * totalWidth
	bar:SetWidth(barSize)
	bar:Show()
	if bar.overlay then
		bar.overlay:SetTexCoord(0, barSize / bar.overlay.tileSize, 0, totalHeight / bar.overlay.tileSize)
		bar.overlay:Show()
	end
	return bar
end

function CompactUnitMixin:UpdateRoleIcon()
	if not self.roleIcon then
		return
	end

	local size = self.roleIcon:GetHeight()	--We keep the height so that it carries from the set up, but we decrease the width to 1 to allow room for things anchored to the role (e.g. name).
	local raidID = UnitInRaid(self.unit)
	if self.unit and UnitInVehicle(self.unit) and UnitHasVehicleUI(self.unit) then
		self.roleIcon:SetTexture("Interface\\Vehicles\\UI-Vehicles-Raid-Icon")
		self.roleIcon:SetTexCoord(0, 1, 0, 1)
		self.roleIcon:Show()
		self.roleIcon:SetSize(size, size)
	elseif self.optionTable.displayRaidRoleIcon and raidID and select(10, GetRaidRosterInfo(raidID)) then
		local role = select(10, GetRaidRosterInfo(raidID))
		self.roleIcon:SetTexture("Interface\\GroupFrame\\UI-Group-"..role.."Icon")
		self.roleIcon:SetTexCoord(0, 1, 0, 1)
		self.roleIcon:Show()
		self.roleIcon:SetSize(size, size)
	else
		local role = UnitGroupRolesAssignedKey(self.unit)
		if self.optionTable.displayRoleIcon and (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
			self.roleIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
			self.roleIcon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
			self.roleIcon:Show()
			self.roleIcon:SetSize(size, size)
		else
			self.roleIcon:Hide()
			self.roleIcon:SetSize(1, size)
		end
	end
end

function CompactUnitMixin:UpdateReadyCheck()
	if not self.Elements.readyCheckIcon or self.readyCheckDecay and GetReadyCheckTimeLeft() <= 0 then
		return
	end
	
	local readyCheckStatus = GetReadyCheckStatus(self.unit)
	self.readyCheckStatus = readyCheckStatus
	if readyCheckStatus == "ready" then
		self.Elements.readyCheckIcon:SetTexture(READY_CHECK_READY_TEXTURE)
		self.Elements.readyCheckIcon:Show()
	elseif readyCheckStatus == "notready" then
		self.Elements.readyCheckIcon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
		self.Elements.readyCheckIcon:Show()
	elseif readyCheckStatus == "waiting" then
		self.Elements.readyCheckIcon:SetTexture(READY_CHECK_WAITING_TEXTURE)
		self.Elements.readyCheckIcon:Show()
	else
		self.Elements.readyCheckIcon:Hide()
	end
end

function CompactUnitMixin:FinishReadyCheck()
	if not self.Elements.readyCheckIcon then
		return
	end
	if self:IsVisible() then
		self.readyCheckDecay = CUF_READY_CHECK_DECAY_TIME
		
		if self.readyCheckStatus == "waiting" then	--If you haven't responded, you are not ready.
			self.Elements.readyCheckIcon:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			self.Elements.readyCheckIcon:Show()
		end
	else
		self:UpdateReadyCheck()
	end
end

function CompactUnitMixin:CheckReadyCheckDecay(elapsed)
	if self.readyCheckDecay then
		if self.readyCheckDecay > 0 then
			self.readyCheckDecay = self.readyCheckDecay - elapsed
		else
			self.readyCheckDecay = nil
			self:UpdateReadyCheck()
		end
	end
end

function CompactUnitMixin:UpdateCenterStatusIcon()
	if self.centerStatusIcon then
		-- cant do anything without UnitHasIncomingResurrection hmm
		self.centerStatusIcon:Hide()
		
		--[[if self.optionTable.displayIncomingResurrect and UnitHasIncomingResurrection(self.unit) then
			self.centerStatusIcon.texture:SetTexture("Interface\\RaidFrame\\Raid-Icon-Rez")
			self.centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
			self.centerStatusIcon.border:Hide()
			self.centerStatusIcon.tooltip = nil
			self.centerStatusIcon:Show()
		else
			self.centerStatusIcon:Hide()
		end]]
	end
end

function CompactUnitMixin:UpdateClassificationIndicator()
	if not self.optionTable.nameOnly and self.optionTable.showClassificationIndicator and self.classificationIndicator then
		local classification = UnitClassification(self.unit)
		if classification == "elite" or classification == "worldboss" then
			self.classificationIndicator:SetAtlas("nameplates-icon-elite-gold", Const.TextureKit.IgnoreAtlasSize)
			self.classificationIndicator:Show()
		elseif classification == "rareelite" then
			self.classificationIndicator:SetAtlas("nameplates-icon-elite-silver", Const.TextureKit.IgnoreAtlasSize)
			self.classificationIndicator:Show()
		else
			self.classificationIndicator:Hide()
		end
	elseif self.classificationIndicator then
		self.classificationIndicator:Hide()
	end
end

function CompactUnitMixin:UpdateLevelIndicator()
	if self.LevelFrame then
		if self.optionTable.nameOnly then
			self.LevelFrame:Hide()
			return
		end

		local icon = self.LevelFrame.Icon
		local text = self.LevelFrame.Text
		local skull = self.LevelFrame.Skull

		local isActivePlayer = UnitIsUnit(self.unit, "player")
		if not isActivePlayer then
			-- hide if we hide player levels or npc levels
			local isPlayer = UnitIsPlayer(self.unit)
			if not self.optionTable.showPlayerLevel and isPlayer then
				self.LevelFrame:Hide()
				return
			elseif not self.optionTable.showNPCLevel and not isPlayer then
				self.LevelFrame:Hide()
				return
			end

			icon:SetShown(not self.optionTable.useClassicStyle)
			
			-- hide level text on world bosses
			local otherUnitLevel = UnitLevel(self.unit)

			if UnitClassification(self.unit) == "worldboss" and otherUnitLevel <= 0 then
				self.LevelFrame:Show()
				skull:Show()
				text:Hide()
				return
			else
				skull:Hide()
				text:Show()
			end
			

			-- show ?? in red for unknown level
			if otherUnitLevel <= 0 then
				text:SetPoint("CENTER", icon, "CENTER", 0, 0)
				local textColor = GetQuestDifficultyColor(GetMaxLevel()+3)
				text:SetText(textColor:WrapText("??"))
			else
				local xOffset = 0
				if otherUnitLevel == 1 or (otherUnitLevel >= 10 and otherUnitLevel <= 19) then
					xOffset = -1 -- account for 1 being offset weird
				end

				if self.optionTable.useClassicStyle then
					text:SetPoint("CENTER", icon, "CENTER", xOffset-1, 1)
				else
					text:SetPoint("CENTER", icon, "CENTER", xOffset, 0)
				end

				local textColor = GetQuestDifficultyColor(otherUnitLevel)

				text:SetText(textColor:WrapText(otherUnitLevel))
			end
			self.LevelFrame:Show()
		else
			self.LevelFrame:Hide()
		end
	end
end

function CompactUnitMixin:UpdateQuestIcon()
	if not self.questIcon then return end

	if not self.displayedUnit then
		self.questIcon:Hide()
		return
	end

	if not self.optionTable.showQuestIcons then
		self.questIcon:Hide()
		return
	end
	
	local questStatus, questID, talkToMe = C_QuestLog.GetUnitQuestInfo(self.displayedUnit)
	if string.isNilOrEmpty(talkToMe) and not questStatus then
		self.questIcon:Hide()
		return
	end

	if questID and questID > 0 then
		local questLogIndex = GetQuestLogIndexByID(questID)
		if questLogIndex == 0 then
			self.questIcon:Hide()
			return
		else
			local isComplete = select(7, GetQuestLogTitle(questLogIndex))
			if isComplete then
				self.questIcon:Hide()
				return
			end
		end
	end

	local atlas, desaturate

	if not string.isNilOrEmpty(talkToMe) then
		if not self.optionTable.showQuestNPCIcons then
			self.questIcon:Hide()
			return
		end
		atlas, desaturate = QuestUtil.GetTalkToMeQuestIcon(talkToMe)
		if not atlas then
			C_Logger.Error("CompactUnitMixin:UpdateQuestIcon: %s %s", "TalkToMe has no associated icon", talkToMe)
			atlas, desaturate = QuestUtil.GetQuestStatusIcon(questStatus)
			if not atlas then
				C_Logger.Error("CompactUnitMixin:UpdateQuestIcon: %s %s", "QuestStatus has no associated icon", questStatus)
			end
		end

	elseif questStatus then
		if not self.optionTable.showQuestObjectives then
			self.questIcon:Hide()
			return
		end
		atlas, desaturate = QuestUtil.GetQuestStatusIcon(questStatus)
		if not atlas then
			C_Logger.Error("CompactUnitMixin:UpdateQuestIcon: %s %s", "QuestStatus has no associated icon", questStatus)
		end
	end

	self.questIcon:SetAtlas(atlas or "questnormal", Const.TextureKit.UseAtlasSize)
	local w, h = self.questIcon:GetSize()
	local scale = self.optionTable.questIconScale
	self.questIcon:SetSize(w * scale, h * scale)
	self.questIcon:SetDesaturated(desaturate)
	self.questIcon:Show()
end

--Other internal functions
function CompactUnitMixin:UpdateBuffs()
	if not self.displayedUnit or not self.buffFrames or not self.optionTable.displayBuffs then
		self:HideAllBuffs()
		return
	end
	
	local index = 1
	local frameNum = 1
	local buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID
	while frameNum <= self.maxBuffs do
		buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID = UnitBuff(self.displayedUnit, index)
		if buffName then
			if AuraUtil_UnitShouldShowBuff(self.displayedUnit, buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID) then
				local buffFrame = self.buffFrames[frameNum]
				self:SetBuff(buffFrame, self.displayedUnit, index, buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
				frameNum = frameNum + 1
			end
		else
			break
		end
		index = index + 1
	end
	for i=frameNum, self.maxBuffs do
		local buffFrame = self.buffFrames[i]
		buffFrame:Hide()
	end
end

function CompactUnitMixin:UpdateDebuffs()
	if not self.displayedUnit or not self.debuffFrames or not self.optionTable.displayDebuffs then
		self:HideAllDebuffs()
		return
	end

	local filter
	local debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID
	--go through the debuffs with a priority (e.g. Weakened Soul and Forbearance)
	local index = 1
	local frameNum = 1
	local maxDebuffs = self.maxDebuffs
	while frameNum <= maxDebuffs do
		debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID = UnitDebuff(self.displayedUnit, index, filter)
		if debuffName then
			if AuraUtil_IsPriorityDebuff(debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID) then
				local debuffFrame = self.debuffFrames[frameNum]
				self:SetDebuff(debuffFrame, self.displayedUnit, index, debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
				frameNum = frameNum + 1
			end
		else
			break
		end
		index = index + 1
	end

	if self.optionTable.displayOnlyDispellableDebuffs then
		filter = "RAID"
	end
	
	index = 1
	--Now, we display all normal debuffs.
	if self.optionTable.displayNonBossDebuffs then
		while frameNum <= maxDebuffs do
			debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID = UnitDebuff(self.displayedUnit, index, filter)
			if debuffName then
				if AuraUtil_UnitShouldShowDebuff(self.displayedUnit, debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID) and 
						not AuraUtil_IsPriorityDebuff(debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID) then
					local debuffFrame = self.debuffFrames[frameNum]
					self:SetDebuff(debuffFrame, self.displayedUnit, index, debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
					frameNum = frameNum + 1
				end
			else
				break
			end
			index = index + 1
		end
	end
	
	for i=frameNum, self.maxDebuffs do
		local debuffFrame = self.debuffFrames[i]
		debuffFrame:Hide()
	end
end

local dispellableDebuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true}
function CompactUnitMixin:UpdateDispellableDebuffs()
	if not self.displayedUnit or not self.dispelDebuffFrames or not self.optionTable.displayDispelDebuffs then
		self:HideAllDispelDebuffs()
		return
	end
	
	--Clear what we currently have.
	for debuffType, display in pairs(dispellableDebuffTypes) do
		if display then
			self["hasDispel"..debuffType] = false
		end
	end
	
	local index = 1
	local frameNum = 1
	local filter = "RAID"	--Only dispellable debuffs.
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, consolidate, spellID
	while frameNum <= self.maxDispelDebuffs do
		name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, consolidate, spellID = UnitDebuff(self.displayedUnit, index, filter)
		if dispellableDebuffTypes[debuffType] and not self["hasDispel"..debuffType] then
			self["hasDispel"..debuffType] = true
			local dispellDebuffFrame = self.dispelDebuffFrames[frameNum]
			self:SetDispelDebuff(dispellDebuffFrame, debuffType, index)
			frameNum = frameNum + 1
		elseif not name then
			break
		end
		index = index + 1
	end
	for i=frameNum, self.maxDispelDebuffs do
		local dispellDebuffFrame = self.dispelDebuffFrames[i]
		dispellDebuffFrame:Hide()
	end
end

function CompactUnitMixin:HideAllBuffs()
	if self.buffFrames then
		for i=1, #self.buffFrames do
			self.buffFrames[i]:Hide()
		end
	end
end

function CompactUnitMixin:SetBuff(buffFrame, unit, index, buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
	buffFrame.icon:SetTexture(icon)
	if count > 1 then
		local countText = count
		if count >= 10 then
			countText = "*"
		end
		buffFrame.count:Show()
		buffFrame.count:SetText(countText)
	else
		buffFrame.count:Hide()
	end
	buffFrame:SetID(index)
	local enabled = expirationTime and expirationTime ~= 0
	if enabled then
		local startTime = expirationTime - duration
		CooldownFrame_SetTimer(buffFrame.cooldown, startTime, duration, true)
	else
		CooldownFrame_Clear(buffFrame.cooldown)
	end
	buffFrame:Show()
end

function CompactUnitMixin:HideAllDebuffs()
	if self.debuffFrames then
		for i=1, #self.debuffFrames do
			self.debuffFrames[i]:Hide()
		end
	end
end

function CompactUnitMixin:SetDebuff(debuffFrame, unit, index, debuffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID)
	-- make sure you are using the correct index here!
	debuffFrame.icon:SetTexture(icon)
	if count > 1 then
		local countText = count
		if count >= 10 then
			countText = "*"
		end
		debuffFrame.count:Show()
		debuffFrame.count:SetText(countText)
	else
		debuffFrame.count:Hide()
	end
	debuffFrame:SetID(index)
	local enabled = expirationTime and expirationTime ~= 0
	if enabled then
		local startTime = expirationTime - duration
		CooldownFrame_SetTimer(debuffFrame.cooldown, startTime, duration, true)
	else
		CooldownFrame_Clear(debuffFrame.cooldown)
	end
	
	local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
	debuffFrame.border:SetVertexColor(color.r, color.g, color.b)
	
	debuffFrame:SetSize(debuffFrame.baseSize, debuffFrame.baseSize)
	
	debuffFrame:Show()
end

function CompactUnitMixin:SetDispelDebuff(dispellDebuffFrame, debuffType, index)
	dispellDebuffFrame:Show()
	dispellDebuffFrame.icon:SetTexture("Interface\\RaidFrame\\Raid-Icon-Debuff"..debuffType)
	dispellDebuffFrame:SetID(index)
end

function CompactUnitMixin:HideAllDispelDebuffs()
	if self.dispelDebuffFrames then
		for i=1, #self.dispelDebuffFrames do
			self.dispelDebuffFrames[i]:Hide()
		end
	end
end

--Dropdown
function CompactUnitFrameDropDown_Initialize(self)
	local unit = self:GetParent().unit
	if not unit then
		return
	end
	local menu
	local name
	local id = nil
	if UnitIsUnit(unit, "player") then
		menu = "SELF"
	elseif UnitIsUnit(unit, "vehicle") then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE"
	elseif UnitIsUnit(unit, "pet") then
		menu = "PET"
	elseif UnitIsPlayer(unit) then
		id = UnitInRaid(unit)
		if id then
			menu = "RAID_PLAYER"
		elseif UnitInParty(unit) then
			menu = "PARTY"
		else
			menu = "PLAYER"
		end
	else
		menu = "TARGET"
		name = RAID_TARGET_ICON
	end
	if menu then
		UnitPopup_ShowMenu(self, menu, unit, name, id)
	end
end

------The default setup function

DefaultCompactUnitFrameOptions = {
	usePrimaryStatColor = true,
	useClassColors = true,
	displaySelectionHighlight = true,
	displayAggroHighlight = true,
	displayName = true,
	fadeOutOfRange = true,
	displayStatusText = true,
	displayHealPrediction = true,
	displayRoleIcon = true,
	displayRaidRoleIcon = true,
	displayDispelDebuffs = true,
	displayBuffs = true,
	displayDebuffs = true,
	displayOnlyDispellableDebuffs = false,
	displayNonBossDebuffs = true,
	healthText = "none",
	displayIncomingResurrect = true,
	displayInOtherGroup = true,
	displayInOtherPhase = true,

	--If class colors are enabled also show the class colors for npcs in your raid frames or
	--raid-frame-style party frames.
	allowClassColorsForNPCs = true,
}

local NATIVE_UNIT_FRAME_HEIGHT = 36
local NATIVE_UNIT_FRAME_WIDTH = 72
DefaultCompactUnitFrameSetupOptions = {
	displayPowerBar = true,
	height = NATIVE_UNIT_FRAME_HEIGHT,
	width = NATIVE_UNIT_FRAME_WIDTH,
	displayBorder = true,
}

function DefaultCompactUnitFrameSetup(frame)
	local options = DefaultCompactUnitFrameSetupOptions
	local componentScale = min(options.height / NATIVE_UNIT_FRAME_HEIGHT, options.width / NATIVE_UNIT_FRAME_WIDTH)

	frame:SetAlpha(1)
	
	frame:SetSize(options.width, options.height)
	local powerBarHeight = 8
	local powerBarUsedHeight = options.displayPowerBar and powerBarHeight or 0
	
	frame.background:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
	frame.background:SetTexCoord(0.05, 0.95, 0.05, 0.50125)
	frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	
	frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1 + powerBarUsedHeight)
	
	frame.healthBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "BORDER")

	if frame.powerBar then
		if options.displayPowerBar then
			if options.displayBorder then
				frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -2)
			else
				frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
			end
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
			frame.powerBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill", "BORDER")
			frame.powerBar.background:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
			frame.powerBar:Show()
		else
			frame.powerBar:Hide()
		end
	end
	
	frame.Elements.myHealPrediction:ClearAllPoints()
	frame.Elements.myHealPrediction:SetTexture(1,1,1)
	frame.Elements.myHealPrediction:SetGradient("VERTICAL", 8/255, 93/255, 72/255, 11/255, 136/255, 105/255)
	frame.Elements.myHealAbsorb:ClearAllPoints()
	frame.Elements.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true)
	frame.myHealAbsorbLeftShadow:ClearAllPoints()
	frame.myHealAbsorbRightShadow:ClearAllPoints()
	frame.Elements.otherHealPrediction:ClearAllPoints()
	frame.Elements.otherHealPrediction:SetTexture(1,1,1)
	frame.Elements.otherHealPrediction:SetGradient("VERTICAL", 11/255, 53/255, 43/255, 21/255, 89/255, 72/255)
	frame.Elements.totalAbsorb:ClearAllPoints()
	frame.Elements.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill")
	frame.Elements.totalAbsorb.overlay = frame.Elements.totalAbsorbOverlay
	frame.Elements.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)	--Tile both vertically and horizontally
	frame.Elements.totalAbsorbOverlay:SetAllPoints(frame.Elements.totalAbsorb)
	frame.Elements.totalAbsorbOverlay.tileSize = 32
	frame.Elements.overAbsorbGlow:ClearAllPoints()
	frame.Elements.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	frame.Elements.overAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -7, 0)
	frame.Elements.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -7, 0)
	frame.Elements.overAbsorbGlow:SetWidth(16)
	frame.Elements.overHealAbsorbGlow:ClearAllPoints()
	frame.Elements.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	frame.Elements.overHealAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMLEFT", 7, 0)
	frame.Elements.overHealAbsorbGlow:SetPoint("TOPRIGHT", frame.healthBar, "TOPLEFT", 7, 0)
	frame.Elements.overHealAbsorbGlow:SetWidth(16)

	frame.roleIcon:ClearAllPoints()
	frame.roleIcon:SetPoint("TOPLEFT", 3, -2)
	frame.roleIcon:SetSize(12, 12)
	
	frame.Elements.name:SetPoint("TOPLEFT", frame.roleIcon, "TOPRIGHT", 0, -1)
	frame.Elements.name:SetPoint("TOPRIGHT", -3, -3)
	frame.Elements.name:SetJustifyH("LEFT")
	
	local NATIVE_FONT_SIZE = 12
	local fontName, fontSize, fontFlags = frame.Elements.statusText:GetFont()
	frame.Elements.statusText:SetFont(fontName, NATIVE_FONT_SIZE * componentScale, fontFlags)
	frame.Elements.statusText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, options.height / 3 - 2)
	frame.Elements.statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, options.height / 3 - 2)
	frame.Elements.statusText:SetHeight(12 * componentScale)
	
	local readyCheckSize = 15 * componentScale
	frame.Elements.readyCheckIcon:ClearAllPoints()
	frame.Elements.readyCheckIcon:SetPoint("BOTTOM", frame, "BOTTOM", 0, options.height / 3 - 4)
	frame.Elements.readyCheckIcon:SetSize(readyCheckSize, readyCheckSize)
	
	local buffSize = 11 * componentScale
	
	frame:SetMaxBuffs(3)
	frame:SetMaxDebuffs(3)
	frame:SetMaxDispelDebuffs(3)
	
	local buffPos, buffRelativePoint, buffOffset = "BOTTOMRIGHT", "BOTTOMLEFT", CUF_AURA_BOTTOM_OFFSET + powerBarUsedHeight
	frame.buffFrames[1]:ClearAllPoints()
	frame.buffFrames[1]:SetPoint(buffPos, frame, "BOTTOMRIGHT", -3, buffOffset)
	for i=1, #frame.buffFrames do
		if i > 1 then
			frame.buffFrames[i]:ClearAllPoints()
			frame.buffFrames[i]:SetPoint(buffPos, frame.buffFrames[i - 1], buffRelativePoint, 0, 0)
		end
		frame.buffFrames[i]:SetSize(buffSize, buffSize)
	end
	
	local debuffPos, debuffRelativePoint, debuffOffset = "BOTTOMLEFT", "BOTTOMRIGHT", CUF_AURA_BOTTOM_OFFSET + powerBarUsedHeight
	frame.debuffFrames[1]:ClearAllPoints()
	frame.debuffFrames[1]:SetPoint(debuffPos, frame, "BOTTOMLEFT", 3, debuffOffset)
	for i=1, #frame.debuffFrames do
		if i > 1 then
			frame.debuffFrames[i]:ClearAllPoints()
			frame.debuffFrames[i]:SetPoint(debuffPos, frame.debuffFrames[i - 1], debuffRelativePoint, 0, 0)
		end
		frame.debuffFrames[i].baseSize = buffSize
		frame.debuffFrames[i].maxHeight = options.height - powerBarUsedHeight - CUF_AURA_BOTTOM_OFFSET - CUF_NAME_SECTION_SIZE
		--frame.debuffFrames[i]:SetSize(11, 11)
	end
	
	frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", -3, -2)
	for i=1, #frame.dispelDebuffFrames do
		if i > 1 then
			frame.dispelDebuffFrames[i]:SetPoint("RIGHT", frame.dispelDebuffFrames[i - 1], "LEFT", 0, 0)
		end
		frame.dispelDebuffFrames[i]:SetSize(12, 12)
	end
	
	frame.Elements.selectionHighlight:SetAtlas("raid-AggroHighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.Elements.selectionHighlight:SetAllPoints(frame)
	
	frame.Elements.aggroHighlight:SetAtlas("raid-TargetHighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.Elements.aggroHighlight:SetAllPoints(frame)
	
	frame.centerStatusIcon:ClearAllPoints()
	frame.centerStatusIcon:SetPoint("CENTER", frame, "BOTTOM", 0, options.height / 3 + 2)
	frame.centerStatusIcon:SetSize(buffSize * 2, buffSize * 2)
	
	if options.displayBorder then
		frame.horizTopBorder:ClearAllPoints()
		frame.horizTopBorder:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -7)
		frame.horizTopBorder:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -7)
		frame.horizTopBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizTopBorder:SetHeight(8)
		frame.horizTopBorder:Show()
		
		frame.horizBottomBorder:ClearAllPoints()
		frame.horizBottomBorder:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1)
		frame.horizBottomBorder:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1)
		frame.horizBottomBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizBottomBorder:SetHeight(8)
		frame.horizBottomBorder:Show()
		
		frame.vertLeftBorder:ClearAllPoints()
		frame.vertLeftBorder:SetPoint("TOPRIGHT", frame, "TOPLEFT", 7, 0)
		frame.vertLeftBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 7, 0)
		frame.vertLeftBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.vertLeftBorder:SetWidth(8)
		frame.vertLeftBorder:Show()
		
		frame.vertRightBorder:ClearAllPoints()
		frame.vertRightBorder:SetPoint("TOPLEFT", frame, "TOPRIGHT", -1, 0)
		frame.vertRightBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -1, 0)
		frame.vertRightBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.vertRightBorder:SetWidth(8)
		frame.vertRightBorder:Show()
		
		if options.displayPowerBar then
			frame.horizDivider:ClearAllPoints()
			frame.horizDivider:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1 + powerBarUsedHeight)
			frame.horizDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1 + powerBarUsedHeight)
			frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
			frame.horizDivider:SetHeight(8)
			frame.horizDivider:Show()
		else
			frame.horizDivider:Hide()
		end
	else
		frame.horizTopBorder:Hide()
		frame.horizBottomBorder:Hide()
		frame.vertLeftBorder:Hide()
		frame.vertRightBorder:Hide()
		
		frame.horizDivider:Hide()
	end
	
	frame:SetOptionTable(DefaultCompactUnitFrameOptions)
end

DefaultCompactMiniFrameOptions = {
	displaySelectionHighlight = true,
	displayAggroHighlight = true,
	displayName = true,
	fadeOutOfRange = true,
	--displayStatusText = true,
	displayHealPrediction = true,
	--displayDispelDebuffs = true,
}

DefaultCompactMiniFrameSetUpOptions = {
	height = 18,
	width = 72,
	displayBorder = true,
}

function DefaultCompactMiniFrameSetup(frame)
	local options = DefaultCompactMiniFrameSetUpOptions
	frame:SetAlpha(1)
	frame:SetSize(options.width, options.height)
	frame.background:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
	frame.background:SetTexCoord(0.05, 0.95, 0.05, 0.50125)
	frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
	frame.healthBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "BORDER")
	
	frame.Elements.myHealPrediction:ClearAllPoints()
	frame.Elements.myHealPrediction:SetTexture(1,1,1)
	frame.Elements.myHealPrediction:SetGradient("VERTICAL", 8/255, 93/255, 72/255, 11/255, 136/255, 105/255)
	frame.Elements.myHealAbsorb:ClearAllPoints()
	frame.Elements.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true)
	frame.myHealAbsorbLeftShadow:ClearAllPoints()
	frame.myHealAbsorbRightShadow:ClearAllPoints()
	frame.Elements.otherHealPrediction:ClearAllPoints()
	frame.Elements.otherHealPrediction:SetTexture(1,1,1)
	frame.Elements.otherHealPrediction:SetGradient("VERTICAL", 3/255, 72/255, 5/255, 2/255, 101/255, 18/255)
	frame.Elements.totalAbsorb:ClearAllPoints()
	frame.Elements.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill")
	frame.Elements.totalAbsorb.overlay = frame.Elements.totalAbsorbOverlay
	frame.Elements.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)	--Tile both vertically and horizontally
	frame.Elements.totalAbsorbOverlay:SetAllPoints(frame.Elements.totalAbsorb)
	frame.Elements.totalAbsorbOverlay.tileSize = 32
	frame.Elements.overAbsorbGlow:ClearAllPoints()
	frame.Elements.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	frame.Elements.overAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -7, 0)
	frame.Elements.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -7, 0)
	frame.Elements.overAbsorbGlow:SetWidth(16)
	frame.Elements.overHealAbsorbGlow:ClearAllPoints()
	frame.Elements.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	frame.Elements.overHealAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMLEFT", 7, 0)
	frame.Elements.overHealAbsorbGlow:SetPoint("TOPRIGHT", frame.healthBar, "TOPLEFT", 7, 0)
	frame.Elements.overHealAbsorbGlow:SetWidth(16)

	frame.Elements.name:SetPoint("LEFT", 5, 1)
	frame.Elements.name:SetPoint("RIGHT", -3, 1)
	frame.Elements.name:SetHeight(12)
	frame.Elements.name:SetJustifyH("LEFT")

	frame.Elements.selectionHighlight:SetAtlas("raid-TargetHighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.Elements.selectionHighlight:SetAllPoints(frame)
	
	frame.Elements.aggroHighlight:SetAtlas("raid-AggroHighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.Elements.aggroHighlight:SetAllPoints(frame)
	
	if options.displayBorder then
		frame.horizTopBorder:ClearAllPoints()
		frame.horizTopBorder:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, -7)
		frame.horizTopBorder:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -7)
		frame.horizTopBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizTopBorder:SetHeight(8)
		frame.horizTopBorder:Show()
		
		frame.horizBottomBorder:ClearAllPoints()
		frame.horizBottomBorder:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1)
		frame.horizBottomBorder:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1)
		frame.horizBottomBorder:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizBottomBorder:SetHeight(8)
		frame.horizBottomBorder:Show()
		
		frame.vertLeftBorder:ClearAllPoints()
		frame.vertLeftBorder:SetPoint("TOPRIGHT", frame, "TOPLEFT", 7, 0)
		frame.vertLeftBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 7, 0)
		frame.vertLeftBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.vertLeftBorder:SetWidth(8)
		frame.vertLeftBorder:Show()
		
		frame.vertRightBorder:ClearAllPoints()
		frame.vertRightBorder:SetPoint("TOPLEFT", frame, "TOPRIGHT", -1, 0)
		frame.vertRightBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -1, 0)
		frame.vertRightBorder:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.vertRightBorder:SetWidth(8)
		frame.vertRightBorder:Show()
	else
		frame.horizTopBorder:Hide()
		frame.horizBottomBorder:Hide()
		frame.vertLeftBorder:Hide()
		frame.vertRightBorder:Hide()
	end
	
	frame:SetOptionTable(DefaultCompactMiniFrameOptions)
end

DefaultCompactNamePlateFriendlyFrameOptions = {
	usePrimaryStatColor = false,
	useClassColors = true,
	displaySelectionHighlight = true,
	displayAggroHighlight = false,
	displayName = true,
	fadeOutOfRange = false,
	displayHealPrediction = true,
	colorNameBySelection = true,
	colorNameWithExtendedColors = true,
	colorHealthWithExtendedColors = true,
	colorHealthBySelection = true,
	considerSelectionInCombatAsHostile = true,
	smoothHealthUpdates = false,
	displayNameWhenSelected = false,
	displayNameByPlayerNameRules = false,
	showPlayerLevel = true,
	showNPCLevel = false,
	displayStatusText = false,
	healthText = "perc",
	showQuestIcons = true,
	showQuestNPCIcons = true,
	showQuestObjectives = true,
	colorNameDead = true,
	displayPowerBar = false,

	hoverBorderColor = CreateColor(0.8, 0.8, 0.8, 0.35),
	selectedBorderColor = CreateColor(1, 1, 1, .35),
	tankNoThreatBorderColor = CreateColor(1, 1, 0, .6),
    tankNoThreatTargetBorderColor = CreateColor(1, 1, 0, 1),
    tankThreatBorderColor = CreateColor(1, 0, 0, 0.6),
    tankThreatTargetBorderColor = CreateColor(1, 0.2, 0, 1),
	defaultBorderColor = CreateColor(0, 0, 0, .8),
}

DefaultCompactNamePlateEnemyFrameOptions = {
	displaySelectionHighlight = true,
	displayAggroHighlight = true,
	playLoseAggroHighlight = true,
	displayName = true,
	fadeOutOfRange = false,
	displayHealPrediction = true,
	colorNameBySelection = true,
	colorHealthBySelection = true,
	considerSelectionInCombatAsHostile = true,
	smoothHealthUpdates = false,
	displayNameWhenSelected = false,
	displayNameByPlayerNameRules = false,
	greyOutWhenTapDenied = true,
	showClassificationIndicator = true,
	showPlayerLevel = true,
	showNPCLevel = true,
	displayStatusText = true,
	healthText = "perc",
	showQuestIcons = true,
	showQuestNPCIcons = false,
	showQuestObjectives = true,
	colorNameDead = true,
	displayPowerBar = false,

	hoverBorderColor = CreateColor(0.8, 0.8, 0.8, 0.55),
	selectedBorderColor = CreateColor(1, 1, 1, .55),
    tankNoThreatBorderColor = CreateColor(1, 1, 0, .6),
    tankNoThreatTargetBorderColor = CreateColor(1, 1, 0, 1),
    tankThreatBorderColor = CreateColor(1, 0, 0, 0.6),
    tankThreatTargetBorderColor = CreateColor(1, 0.2, 0, 1),
	defaultBorderColor = CreateColor(0, 0, 0, .8),
}

DefaultCompactNamePlatePlayerFrameOptions = {
	displaySelectionHighlight = false,
	displayAggroHighlight = false,
	displayName = false,
	fadeOutOfRange = false,
	displayHealPrediction = true,
	colorNameBySelection = true,
	smoothHealthUpdates = false,
	displayNameWhenSelected = false,
	hideCastbar = true,
	healthBarColorOverride = CreateColor(0, 1, 0),
	displayPowerBar = true,
	nameOnly = false,

	defaultBorderColor = CreateColor(0, 0, 0, .8),
}

DefaultCompactNamePlateFrameSetUpOptions = {
	healthBarWidth = 110,
	healthBarHeight = 4,
	healthBarAlpha = 0.75,
	castBarHeight = 8,
	castBarFontHeight = 10,
	nameFont = "Fonts\\FRIZQT__.TTF",
	nameFontHeight = 8,
	nameFontFlags = "NONE",
	healthStatusBar = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
	castBarFont = "Fonts\\FRIZQT__.TTF",
	castBarStatusBar = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill",
	castBarFontFlags = "NONE",
	healthTextFont = "Fonts\\FRIZQT__.TTF",
	healthTextFontHeight = 8,
	healthTextFontFlags = "NONE",

	castBarShieldWidth = 10,
	castBarShieldHeight = 12,

	castIconWidth = 10,
	castIconHeight = 10,
}

function DefaultCompactNamePlateFrameSetup(frame, options)
	if ( not options or type(options) ~= "table" ) then
		error("Cannot setup target nameplate. Missing options table.")
	end

	frame.castBar:SetPoint("TOP", frame, "BOTTOM", 0, 0)
	frame.castBar:SetStatusBarTexture("Interface/TargetingFrame/UI-TargetingFrame-BarFill")

	frame.castBar.Text:SetAllPoints(frame.castBar)
	frame.castBar.Text:SetFontObject("SystemFont_Outline_Small")

	DefaultCompactNamePlateFrameSetupInternal(frame, DefaultCompactNamePlateFrameSetUpOptions, options)
end

function DefaultCompactNamePlateFriendlyFrameSetup(frame)
	DefaultCompactNamePlateFrameSetup(frame, DefaultCompactNamePlateFriendlyFrameOptions)
end

function DefaultCompactNamePlateEnemyFrameSetup(frame)
	DefaultCompactNamePlateFrameSetup(frame, DefaultCompactNamePlateEnemyFrameOptions)
end

function DefaultCompactNamePlatePlayerFrameSetup(frame)
	DefaultCompactNamePlateFrameSetup(frame, DefaultCompactNamePlatePlayerFrameOptions)
end

function DefaultCompactNamePlateFrameSetupInternal(frame, setupOptions, frameOptions)
	if not frameOptions.hideCastbar then
		frame.castBar:SetHeight(frameOptions.castBarHeight)
		frame.castBar.Text:SetFont(frameOptions.castBarFont, frameOptions.castBarFontHeight, frameOptions.castBarFontFlags)

		frame.castBar:SetStatusBarTexture(frameOptions.castBarStatusBar)

		frame.castBar.BorderShield:SetSize(frameOptions.castBarHeight, frameOptions.castBarHeight * 1.2)

		frame.castBar.BorderShield:ClearAllPoints()
		frame.castBar.BorderShield:SetPoint("CENTER", frame.castBar, "LEFT", 0, 0)

		frame.castBar.Icon:SetSize(frameOptions.castBarHeight, frameOptions.castBarHeight)
		frame.castBar:SetSize(frameOptions.healthWidth-12, frameOptions.castBarHeight)
		frame.castBar.Icon:ClearAllPoints()
		frame.castBar.Background:ClearAllPoints()

		if frameOptions.useClassicStyle then
			frame.castBar.Icon:SetPoint("RIGHT", frame.castBar, "LEFT", -4, 0)
			frame.castBar.Background:SetPoint("TOPLEFT", frame.castBar.Icon, "TOPLEFT", -5, 5)
			frame.castBar.Background:SetPoint("BOTTOMRIGHT", 4, -5)
			frame.castBar.Background:SetTexture("Interface\\Tooltips\\Nameplate-Border-Castbar")
			frame.castBar.Background:SetTexCoord(0, 1, 0.5, 1)
		else
			frame.castBar.Icon:SetPoint("RIGHT", frame.castBar, "LEFT", 0, 0)
			frame.castBar.Background:SetTexture(0.2, 0.2, 0.2, 0.85)
			frame.castBar.Background:SetAllPoints()
		end
	else
		frame.castBar:SetSize(frameOptions.healthWidth-12, 1)
	end

	if frameOptions.displayName then
		frame.name:SetFont(frameOptions.nameFont, frameOptions.nameFontHeight, frameOptions.nameFontFlags)
	end

	frame.healthBar.Elements.statusText:SetFont(frameOptions.healthTextFont, frameOptions.healthTextFontHeight, frameOptions.healthTextFontFlags)

	if frameOptions.nameOnly then
		frame.healthBar:Hide()
		frame.name:SetPoint("BOTTOM", frame.healthBar, "BOTTOM", 0, 4)
	else
		frame.healthBar:Show()
		frame.name:SetPoint("BOTTOM", frame.healthBar, "TOP", 0, 4)
		frame.healthBar.background:SetVertexColor(unpack(frameOptions.backgroundColor))
		frame.healthBar.border:UpdateStyle(frameOptions.useClassicStyle)
	end

	if frameOptions.useClassicStyle then
		frame.LevelFrame.Text:SetFontObject("GameFontHighlightSmall")
	else
		frame.LevelFrame.Text:SetFontObject("GameFontWhiteTiny2")
	end

	if frame.powerBar then
		if frameOptions.displayPowerBar then
			frame.powerBar:SetPoint("BOTTOM", frame.healthBar, "BOTTOM", 0, -1)
			frame.powerBar:SetSize(frameOptions.healthWidth, frameOptions.healthHeight / 2)
			frame.powerBar:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill", "BORDER")
			frame.powerBar.background:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
			frame.powerBar:Show()
			frame.healthBar:SetPoint("BOTTOM", frame.castBar, "TOP", 0, 6)	
			frame.healthBar:SetSize(frameOptions.healthWidth, frameOptions.healthHeight)
			frame.powerBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
		else
			frame.powerBar:Hide()
			frame.healthBar:SetPoint("BOTTOM", frame.castBar, "TOP", 0, 2)
			frame.healthBar:SetSize(frameOptions.healthWidth, frameOptions.healthHeight)
		end
	else
		frame.healthBar:SetSize(frameOptions.healthWidth, frameOptions.healthHeight)
		frame.healthBar:SetPoint("BOTTOM", frame.castBar, "TOP", 0, 2)
	end

	frame.healthBar:SetStatusBarTexture(frameOptions.healthStatusBar)

	frame.Elements = frame.healthBar.Elements
	frame.myHealAbsorbLeftShadow = frame.healthBar.myHealAbsorbLeftShadow
	frame.myHealAbsorbRightShadow = frame.healthBar.myHealAbsorbRightShadow
	frame.Elements.selectionHighlight = frame.selectionHighlight
	frame.Elements.aggroHighlight = frame.aggroHighlight
	frame.Elements.statusText = frame.healthBar.Elements.statusText
	frame.Elements.name = frame.name

	frame.selectionHighlight:SetParent(frame.healthBar)
	frame.selectionHighlight:SetAllPoints(frame.healthBar.barTexture)
	frame.aggroHighlight:SetParent(frame.healthBar)
	frame.aggroHighlight:SetAllPoints(frame.healthBar.barTexture)

	frame.Elements.myHealPrediction:ClearAllPoints()
	frame.Elements.myHealPrediction:SetVertexColor(0.0, 0.659, 0.608)

	frame.Elements.myHealAbsorb:ClearAllPoints()
	frame.Elements.myHealAbsorb:SetTexture("Interface\\RaidFrame\\Absorb-Fill", true, true)

	frame.myHealAbsorbLeftShadow:ClearAllPoints()
	frame.myHealAbsorbRightShadow:ClearAllPoints()

	frame.Elements.otherHealPrediction:ClearAllPoints()
	frame.Elements.otherHealPrediction:SetVertexColor(0.0, 0.659, 0.608)

	frame.Elements.totalAbsorb:ClearAllPoints()
	frame.Elements.totalAbsorb:SetTexture("Interface\\RaidFrame\\Shield-Fill")
	frame.Elements.totalAbsorb.overlay = frame.Elements.totalAbsorbOverlay

	frame.Elements.totalAbsorbOverlay:SetTexture("Interface\\RaidFrame\\Shield-Overlay", true, true)	--Tile both vertically and horizontally
	frame.Elements.totalAbsorbOverlay:SetAllPoints(frame.Elements.totalAbsorb)
	frame.Elements.totalAbsorbOverlay.tileSize = 20

	frame.Elements.overAbsorbGlow:ClearAllPoints()
	frame.Elements.overAbsorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
	frame.Elements.overAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -4, -1)
	frame.Elements.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -4, 1)
	frame.Elements.overAbsorbGlow:SetWidth(8)

	frame.Elements.overHealAbsorbGlow:ClearAllPoints()
	frame.Elements.overHealAbsorbGlow:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
	frame.Elements.overHealAbsorbGlow:SetBlendMode("ADD")
	frame.Elements.overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMLEFT", 2, -1)
	frame.Elements.overHealAbsorbGlow:SetPoint("TOPRIGHT", frame.healthBar, "TOPLEFT", 2, 1)
	frame.Elements.overHealAbsorbGlow:SetWidth(8)

	frame.classificationIndicator = frame.ClassificationFrame.classificationIndicator

	frame.LoseAggroAnim = frame.aggroHighlight.LoseAggroAnim
	frame.LoseAggroAnim:Stop()
	
	local questIconAnchor = frameOptions.questIconAnchor
	if questIconAnchor == "LEFT" then
		frame.questIcon:ClearAndSetPoint("RIGHT", frame.name, "LEFT", -2, 0)
	elseif questIconAnchor == "RIGHT" then
		frame.questIcon:ClearAndSetPoint("LEFT", frame.name, "RIGHT", 2, 0)
	else
		frame.questIcon:ClearAndSetPoint("BOTTOM", frame.name, "TOP", 0, 2)
	end

	frame:SetOptionTable(frameOptions)
end
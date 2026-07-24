MAX_RAID_GROUPS = 8

local UnitGUID = UnitGUID
local tinsert = tinsert
local strsub = strsub
local ipairs, pairs, type = ipairs, pairs, type
local GroupUtil_IsInRaid = GroupUtil.IsInRaid
local FlowContainer_RemoveAllObjects = FlowContainer_RemoveAllObjects
local FlowContainer_PauseUpdates = FlowContainer_PauseUpdates
local FlowContainer_AddLineBreak = FlowContainer_AddLineBreak
local FlowContainer_AddObject = FlowContainer_AddObject
local FlowContainer_SetOrientation = FlowContainer_SetOrientation
local FlowContainer_GetUsedBounds = FlowContainer_GetUsedBounds
local FlowContainer_BeginAtomicAdd = FlowContainer_BeginAtomicAdd
local FlowContainer_EndAtomicAdd = FlowContainer_EndAtomicAdd
local FlowContainer_ResumeUpdates = FlowContainer_ResumeUpdates
local GroupUtil_GetUsedGroups = GroupUtil.GetUsedGroups
local GroupUtil_EnumerateRaidPets = GroupUtil.EnumerateRaidPets
local GroupUtil_EnumeratePartyPets = GroupUtil.EnumeratePartyPets
local UnitExists = UnitExists
local GetRaidRosterInfo = GetRaidRosterInfo
local CreateFrame = CreateFrame

local frameCreationSpecifiers = {
	raid = { mapping = UnitGUID, setUpFunc = DefaultCompactUnitFrameSetup, updateList = "normal"},
	pet =  { setUpFunc = DefaultCompactMiniFrameSetup, updateList = "mini" },
	flagged = { mapping = UnitGUID, setUpFunc = DefaultCompactUnitFrameSetup, updateList = "normal"	},
	target = { setUpFunc = DefaultCompactMiniFrameSetup, updateList = "mini" },
}

--Widget Handlers
CompactRaidFrameContainerMixin = {}
function CompactRaidFrameContainerMixin:OnLoad()
	FlowContainer_Initialize(self)	--Congrats! We are now a certified FlowContainer.
	
	self:SetClampRectInsets(0, 200 - self:GetWidth(), 10, 0)
	
	self.raidUnits = {--[["raid1", "raid2", "raid3", ..., "raid40"]]}
	for i=1, MAX_RAID_MEMBERS do
		tinsert(self.raidUnits, "raid"..i)
	end
	self.partyUnits = { "player" }
	for i=1, MAX_PARTY_MEMBERS do
		tinsert(self.partyUnits, "party"..i)
	end
	self:UpdateDisplayedUnits(self)
	
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("UNIT_PET")
	
	local unitFrameReleaseFunc = function(frame) frame:SetUnit(nil) end
	self.frameReservations = {
		raid		= CompactRaidFrameReservation_NewManager(unitFrameReleaseFunc),
		pet			= CompactRaidFrameReservation_NewManager(unitFrameReleaseFunc),
		flagged		= CompactRaidFrameReservation_NewManager(unitFrameReleaseFunc),	--For Main Tank/Assist units
		target		= CompactRaidFrameReservation_NewManager(unitFrameReleaseFunc),	--Target of target for Main Tank/Main Assist
	}
	
	self.frameUpdateList = {
		normal = {},	--Groups are also in this normal list.
		mini = {},
		group = {},
	}

	self.unitFrameUnusedFunc = function(frame) frame.inUse = false end
	self.displayPets = true
	self.displayFlaggedMembers = true
end

function CompactRaidFrameContainerMixin:RAID_ROSTER_UPDATE()
	self:UpdateDisplayedUnits()
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:PARTY_MEMBERS_CHANGED()
	self:UpdateDisplayedUnits()
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:UNIT_PET(unit)
	if self.displayPets then
		if ( unit == "player" or strsub(unit, 1, 4) == "raid" or strsub(unit, 1, 5) == "party" ) then
			self:TryUpdate(self)
		end
	end
end

function CompactRaidFrameContainerMixin:OnSizeChanged()
	FlowContainer_DoLayout(self)
	self:UpdateBorder()
end

--Externally used functions
function CompactRaidFrameContainerMixin:SetGroupMode(groupMode)
	self.groupMode = groupMode
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:SetFlowFilterFunction(flowFilterFunc)
	--Usage: flowFilterFunc is called as flowFilterFunc("unittoken") and should return whether this frame should be displayed or not.
	self.flowFilterFunc = flowFilterFunc
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:SetGroupFilterFunction(groupFilterFunc)
	--Usage: groupFilterFunc is called as groupFilterFunc(groupNum) and should return whether this group should be displayed or not.
	self.groupFilterFunc = groupFilterFunc
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:SetFlowSortFunction(flowSortFunc)
	--Usage: Takes two tokens, should work as a Lua sort function.
	--The ordering must be well-defined, even across units that will be filtered out
	self.flowSortFunc = flowSortFunc
	self:TryUpdate()
end

function CompactRaidFrameContainerMixin:SetDisplayPets(displayPets)
	if self.displayPets ~= displayPets then
		self.displayPets = displayPets
		self:TryUpdate()
	end
end

function CompactRaidFrameContainerMixin:SetDisplayMainTankAndAssist(displayFlaggedMembers)
	if self.displayFlaggedMembers ~= displayFlaggedMembers then
		self.displayFlaggedMembers = displayFlaggedMembers
		self:TryUpdate()
	end
end

function CompactRaidFrameContainerMixin:SetBorderShown(showBorder)
	self.showBorder = showBorder
	self:UpdateBorder(self)
end

function CompactRaidFrameContainerMixin:ApplyToFrames(updateSpecifier, func, ...)
	for specifier, list in pairs(self.frameUpdateList) do
		if updateSpecifier == "all" or specifier == updateSpecifier then
			for i=1, #list do
				list[i]:applyFunc(updateSpecifier, func, ...)
			end
		end
	end
end

--Internally used functions
function CompactRaidFrameContainerMixin:TryUpdate()
	if self:ReadyToUpdate() then
		self:LayoutFrames()
	end
end

function CompactRaidFrameContainerMixin:ReadyToUpdate()
	if not self.groupMode then
		return false
	end
	if self.groupMode == "flush" and not (self.flowFilterFunc and self.flowSortFunc) then
		return false
	end
	if self.groupMode == "discrete" and not self.groupFilterFunc then
		return false
	end
	
	return true
end

function CompactRaidFrameContainerMixin:UpdateDisplayedUnits()
	if GroupUtil_IsInRaid() then
		self.units = self.raidUnits
	else
		self.units = self.partyUnits
	end
end

function CompactRaidFrameContainerMixin:LayoutFrames()
	--First, mark everything we currently use as unused. We'll hide all the ones that are still unused at the end of this function. (On release)
	for i=1, #self.flowFrames do
		if type(self.flowFrames[i]) == "table" and self.flowFrames[i].unusedFunc then
			self.flowFrames[i]:unusedFunc()
		end
	end
	
	FlowContainer_RemoveAllObjects(self)
	FlowContainer_PauseUpdates(self)	--We don't want to update it every time we add an item.
	
	if self.displayFlaggedMembers then
		self:AddFlaggedUnits()
		FlowContainer_AddLineBreak(self)
	end

	if self.groupMode == "discrete" then
		self:AddGroups()
	elseif self.groupMode == "flush" then
		self:AddPlayers()
	else
		C_Logger.Error("Unknown group mode")
		return
	end
	
	if self.displayPets then
		self:AddPets()
	end

	FlowContainer_ResumeUpdates(self)

	self:UpdateBorder()
	self:ReleaseAllReservedFrames()
end

function CompactRaidFrameContainerMixin:UpdateBorder()
	local usedX, usedY = FlowContainer_GetUsedBounds(self)
	if self.showBorder and self.groupMode ~= "discrete" and usedX > 0 and usedY > 0 then
		self.borderFrame:SetSize(usedX + 11, usedY + 13)
		self.borderFrame:Show()
	else
		self.borderFrame:Hide()
	end
end

do
	local usedGroups = {} --Enclosure to make sure usedGroups isn't used anywhere else.
	function CompactRaidFrameContainerMixin:AddGroups()
		if GroupUtil_IsInRaid() then
			GroupUtil_GetUsedGroups(usedGroups)
			
			for groupNum, isUsed in ipairs(usedGroups) do
				if isUsed and self.groupFilterFunc(groupNum) then
					self:AddGroup(groupNum)
				end
			end
		else
			self:AddGroup("PARTY")
		end
		FlowContainer_SetOrientation(self, "vertical")
	end
end

function CompactRaidFrameContainerMixin:AddGroup(id)
	local groupFrame, didCreation
	if type(id) == "number" then
		groupFrame, didCreation = CompactRaidGroup_GenerateForGroup(id)
	elseif id == "PARTY" then
		groupFrame, didCreation = CompactPartyFrame_Generate()
	else
		C_Logger.Error("CompactRaidFrameContainerMixin:AddGroup("..(id or "nil")..") - Unknown id")
	end
	
	groupFrame:SetParent(self)
	groupFrame:SetFrameStrata("LOW")
	groupFrame.unusedFunc = groupFrame.Hide
	if ( didCreation ) then
		tinsert(self.frameUpdateList.normal, groupFrame)
		tinsert(self.frameUpdateList.group, groupFrame)
	end
	FlowContainer_AddObject(self, groupFrame)
	groupFrame:Show()
end

function CompactRaidFrameContainerMixin:AddPlayers()
	--First, sort the players we're going to use
	assert(self.flowSortFunc)	--No sort function defined! Call CompactRaidFrameContainer_SetFlowSortFunction.
	assert(self.flowFilterFunc)	--No filter function defined! Call CompactRaidFrameContainer_SetFlowFilterFunction.
	
	table.sort(self.units, self.flowSortFunc)
	
	for i=1, #self.units do
		local unit = self.units[i]
		if self.flowFilterFunc(unit) then
			self:AddUnitFrame(unit, "raid")
		end
	end
	
	FlowContainer_SetOrientation(self, "vertical")
end

function CompactRaidFrameContainerMixin:AddPets()
	if GroupUtil_IsInRaid() then
		for unit in GroupUtil_EnumerateRaidPets() do
			if UnitExists(unit) then
				self:AddUnitFrame(unit, "pet")
			end
		end
	else
		for unit in GroupUtil_EnumeratePartyPets() do
			if UnitExists(unit) then
				self:AddUnitFrame(unit, "pet")
			end
		end
	end
end

do
	local flaggedRoles = { MAINTANK = true, MAINASSIST = true }
	function CompactRaidFrameContainerMixin:AddFlaggedUnits()
		if not GroupUtil_IsInRaid() then
			return
		end
		local unit, role, _
		for i=1, MAX_RAID_MEMBERS do
			unit = "raid"..i
			_, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
			if flaggedRoles[role] then
				FlowContainer_BeginAtomicAdd(self)	--We want each unit to be right next to its target and target of target.

				self:AddUnitFrame(unit, "flagged")

				--If we want to display the tank/assist target...
				local targetFrame = self:AddUnitFrame(unit.."target", "target")
				targetFrame:SetUpdateAllOnUpdate(true)

				--Target of target?
				local targetOfTargetFrame = self:AddUnitFrame(unit.."targettarget", "target")
				targetOfTargetFrame:SetUpdateAllOnUpdate(true)

				--Add some space before the next one.
				--FlowContainer_AddSpacer(self, 36)

				FlowContainer_EndAtomicAdd(self)
			end
		end
	end
end

--Utility Functions
function CompactRaidFrameContainerMixin:AddUnitFrame(unit, frameType)
	local frame = self:GetUnitFrame(unit, frameType)
	frame:SetUnit(unit)
	FlowContainer_AddObject(self, frame)
	
	return frame
end

do
	local function applyFunc(unitFrame, updateSpecifier, func, ...)
		func(unitFrame, ...)
	end

	local unitFramesCreated = 0
	function CompactRaidFrameContainerMixin:GetUnitFrame(unit, frameType)
		local info = frameCreationSpecifiers[frameType]
		assert(info)
		assert(info.setUpFunc)

		--Get the mapping for re-using frames
		local mapping
		if ( info.mapping ) then
			mapping = info.mapping(unit)
		else
			mapping = unit
		end

		local frame = CompactRaidFrameReservation_GetFrame(self.frameReservations[frameType], mapping)
		if not frame then
			unitFramesCreated = unitFramesCreated + 1
			frame = CreateFrame("Button", "CompactRaidFrame"..unitFramesCreated, self, "CompactUnitFrameTemplate")
			frame.applyFunc = applyFunc
			frame:SetUpFrame(info.setUpFunc)
			if strsub(unit, 1, 4) == "raid" then
				frame:SetUpdateAllEvent("RAID_ROSTER_UPDATE")
			else
				frame:SetUpdateAllEvent("PARTY_MEMBERS_CHANGED")
			end
			frame.unusedFunc = self.unitFrameUnusedFunc
			tinsert(self.frameUpdateList[info.updateList], frame)
			CompactRaidFrameReservation_RegisterReservation(self.frameReservations[frameType], frame, mapping)
		end
		frame.inUse = true
		return frame
	end
end

function CompactRaidFrameContainerMixin:ReleaseAllReservedFrames()
	for key, reservations in pairs(self.frameReservations) do
		CompactRaidFrameReservation_ReleaseUnusedReservations(reservations)
	end
end

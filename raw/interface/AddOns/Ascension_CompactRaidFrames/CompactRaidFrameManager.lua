local RESIZE_HORIZONTAL_OUTSETS = 4
local RESIZE_VERTICAL_OUTSETS = 7

-- Global -> Local performance increase
local FlowContainer_Initialize = FlowContainer_Initialize
local FlowContainer_RemoveAllObjects = FlowContainer_RemoveAllObjects
local FlowContainer_PauseUpdates = FlowContainer_PauseUpdates
local FlowContainer_AddObject = FlowContainer_AddObject
local FlowContainer_AddLineBreak = FlowContainer_AddLineBreak
local FlowContainer_AddSpacer = FlowContainer_AddSpacer
local FlowContainer_ResumeUpdates = FlowContainer_ResumeUpdates
local FlowContainer_GetUsedBounds = FlowContainer_GetUsedBounds
local GetDisplayedAllyFrames = GetDisplayedAllyFrames
local HasLFGRestrictions = HasLFGRestrictions

local GroupUtil_IsInRaid = GroupUtil.IsInRaid
local GroupUtil_UnitIsGroupLeader = GroupUtil.UnitIsGroupLeader
local GroupUtil_UnitIsGroupAssistant = GroupUtil.UnitIsGroupAssistant
local GroupUtil_IsInGroup = GroupUtil.IsInGroup
local GroupUtil_GetUsedGroups = GroupUtil.GetUsedGroups
local GroupUtil_GetNumGroupMembers = GroupUtil.GetNumGroupMembers
local GetRaidTargetIndex = GetRaidTargetIndex
local GetScreenHeight, GetScreenWidth = GetScreenHeight, GetScreenWidth
local GenerateClosure = GenerateClosure
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitInRaid = UnitInRaid 
local UnitGroupRolesAssignedKey = UnitGroupRolesAssignedKey
local UnitName = UnitName
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local abs, max, MClamp = abs, max, MClamp

-- Mixin
CompactRaidFrameManagerMixin = {}

function CompactRaidFrameManagerMixin:OnLoad()
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
	self.container = CompactRaidFrameContainer
	self.container:SetParent(self)
	
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")
	self:RegisterEvent("UI_SCALE_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD")
	self:RegisterEvent("UNIT_FLAGS")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("RAID_TARGET_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	
	self.containerResizeFrame:SetMinResize(self.container:GetWidth(), MINIMUM_RAID_CONTAINER_HEIGHT + RESIZE_VERTICAL_OUTSETS * 2 + 1)
	self.dynamicContainerPosition = true
	
	self.container:SetFlowFilterFunction(CRFFlowFilterFunc)
	self.container:SetGroupFilterFunction(CRFGroupFilterFunc)
	self:UpdateContainerBounds()
	self:ResizeFrame_Reanchor()
	self:AttachPartyFrames()
	
	self:Collapse()
	
	--Set up the options flow container
	FlowContainer_Initialize(self.displayFrame.optionsFlowContainer)
end

local settings = { "Locked", "SortMode", "KeepGroupsTogether", "DisplayPets", "DisplayMainTankAndAssist", "IsShown", "ShowBorders" }
function CompactRaidFrameManagerMixin:OnEvent(event, ...)
	if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
		self:UpdateContainerBounds()
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "UPDATE_ACTIVE_BATTLEFIELD" then
		self:UpdateShown()
		self:UpdateDisplayCounts()
		self:UpdateLabel()
		self:UpdateContainerLockVisibility()
	elseif event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED" then
		self:UpdateDisplayCounts()
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:UpdateShown()
		self:UpdateDisplayCounts()
		self:UpdateOptionsFlowContainer()
		self:UpdateRaidIcons()
	elseif event == "PARTY_LEADER_CHANGED" then
		self:UpdateOptionsFlowContainer()
	elseif event == "RAID_TARGET_UPDATE" then
		self:UpdateRaidIcons()
	elseif event == "PLAYER_TARGET_CHANGED" then
		self:UpdateRaidIcons()
	end
end

function CompactRaidFrameManagerMixin:UpdateShown()
	RaidOptionsFrame_UpdatePartyFrames()
	if GetDisplayedAllyFrames() then
		self:Show()
	else
		self:Hide()
	end
	self:UpdateOptionsFlowContainer()
	self:UpdateContainerVisibility()
end

function CompactRaidFrameManagerMixin:UpdateLabel()
	if GroupUtil_IsInRaid() then
		self.displayFrame.label:SetText(RAID_MEMBERS)
	else
		self.displayFrame.label:SetText(PARTY_MEMBERS)
	end
end

function CompactRaidFrameManagerMixin:Toggle()
	if self.collapsed then
		self:Expand()
	else
		self:Collapse()
	end
end

function CompactRaidFrameManagerMixin:Expand()
	self.collapsed = false
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -7, -140)
	self.displayFrame:Show()
	self.toggleButton:GetNormalTexture():SetTexCoord(0.5, 1, 0, 1)
end

function CompactRaidFrameManagerMixin:Collapse()
	self.collapsed = true
	self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -182, -140)
	self.displayFrame:Hide()
	self.toggleButton:GetNormalTexture():SetTexCoord(0, 0.5, 0, 1)
end

function CompactRaidFrameManagerMixin:UpdateOptionsFlowContainer()
	local container = self.displayFrame.optionsFlowContainer
	
	FlowContainer_RemoveAllObjects(container)
	FlowContainer_PauseUpdates(container)
	
	local allyFrames = GetDisplayedAllyFrames()
	local isInRaid = GroupUtil.IsInRaid()
	
	if allyFrames == "raid" then
		FlowContainer_AddObject(container, self.displayFrame.profileSelector)
		self.displayFrame.profileSelector:Show()
	else
		self.displayFrame.profileSelector:Hide()
	end
	
	if isInRaid then
		FlowContainer_AddObject(container, self.displayFrame.filterOptions)
		self.displayFrame.filterOptions:Show()
	else
		self.displayFrame.filterOptions:Hide()
	end
	
	local isLeader = GroupUtil_UnitIsGroupLeader("player")
	local isAssistant = GroupUtil_UnitIsGroupAssistant("player")
	
	if not isInRaid or isLeader or isAssistant then
		FlowContainer_AddObject(container, self.displayFrame.raidMarkers)
		self.displayFrame.raidMarkers:Show()
	else
		self.displayFrame.raidMarkers:Hide()
	end
	
	if not isInRaid or isLeader or isAssistant then
		FlowContainer_AddObject(container, self.displayFrame.leaderOptions)
		self.displayFrame.leaderOptions:Show()
	else
		self.displayFrame.leaderOptions:Hide()
	end
	
	if not isInRaid and isLeader and not HasLFGRestrictions() then
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddSpacer(container, 20)
		FlowContainer_AddObject(container, self.displayFrame.convertToRaid)
		self.displayFrame.convertToRaid:Show()
	else
		self.displayFrame.convertToRaid:Hide()
	end
	
	if allyFrames == "raid" then
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddSpacer(container, 20)
		FlowContainer_AddObject(container, self.displayFrame.lockedModeToggle)
		FlowContainer_AddObject(container, self.displayFrame.hiddenModeToggle)
		self.displayFrame.lockedModeToggle:Show()
		self.displayFrame.hiddenModeToggle:Show()
	else
		self.displayFrame.lockedModeToggle:Hide()
		self.displayFrame.hiddenModeToggle:Hide()
	end
	
	FlowContainer_ResumeUpdates(container)
	
	local usedX, usedY = FlowContainer_GetUsedBounds(container)
	self:SetHeight(usedY + 40)
	
	--Then, we update which specific buttons are enabled.
	local isInGroup = GroupUtil_IsInGroup()
	
	--Any sort of leader may initiate a ready check.
	if isInGroup and (isLeader or isAssistant) then
		self.displayFrame.leaderOptions.readyCheckButton:Enable()
		self.displayFrame.leaderOptions.readyCheckButton:SetAlpha(1)
	else
		self.displayFrame.leaderOptions.readyCheckButton:Disable()
		self.displayFrame.leaderOptions.readyCheckButton:SetAlpha(0.5)
	end
end

local function RaidWorldMarker_OnClick(self, arg1, arg2, checked)
	PlaceRaidMarker(arg1)
end

local function ClearRaidWorldMarker_OnClick(self, arg1, arg2, checked)
	ClearRaidMarkers()
end

function CRFManager_RaidWorldMarkerDropDown_Update()
	local info = UIDropDownMenu_CreateInfo()
	
	for i=1, NUM_WORLD_RAID_MARKERS do
		local index = WORLD_RAID_MARKER_ORDER[i]
		info.text = _G["WORLD_MARKER"..index]
		info.func = RaidWorldMarker_OnClick
		info.checked = IsRaidMarkerActive(index);
		info.arg1 = index
		UIDropDownMenu_AddButton(info)
	end

		
	info.notCheckable = 1
	info.text = REMOVE_WORLD_MARKERS
	info.func = ClearRaidWorldMarker_OnClick
	info.arg1 = nil	--Remove everything
	UIDropDownMenu_AddButton(info)
end

function CompactRaidFrameManagerMixin:UpdateDisplayCounts()
	CRF_CountStuff()
	self:UpdateHeaderInfo()
	self:UpdateFilterInfo()
end

function CompactRaidFrameManagerMixin:UpdateHeaderInfo()
	self.displayFrame.memberCountLabel:SetFormattedText("%d/%d", RaidInfoCounts.totalAlive, RaidInfoCounts.totalCount)
end

do
	local usedGroups = {}
	function CompactRaidFrameManagerMixin:UpdateFilterInfo()
		self:UpdateRoleFilterButton(self.displayFrame.filterOptions.filterRoleTank)
		self:UpdateRoleFilterButton(self.displayFrame.filterOptions.filterRoleHealer)
		self:UpdateRoleFilterButton(self.displayFrame.filterOptions.filterRoleDamager)

		GroupUtil_GetUsedGroups(usedGroups)
		for i=1, MAX_RAID_GROUPS do
			self:UpdateGroupFilterButton(self.displayFrame.filterOptions["filterGroup"..i], usedGroups)
		end
	end
end

function CompactRaidFrameManagerMixin:UpdateRoleFilterButton(button)
	local totalAlive, totalCount = RaidInfoCounts["aliveRole"..button.role], RaidInfoCounts["totalRole"..button.role]
	button:SetFormattedText("%s %d/%d", button.roleTexture, totalAlive, totalCount)
	local keepGroupsTogether = self:GetSetting("KeepGroupsTogether")
	keepGroupsTogether = keepGroupsTogether and keepGroupsTogether ~= "0"
	if ( totalCount == 0 or keepGroupsTogether ) then
		button.selectedHighlight:Hide()
		button:Disable()
		button:SetAlpha(0.5)
	else
		button:Enable()
		button:SetAlpha(1)
		local isFiltered = CRF_GetFilterRole(button.role)
		if ( isFiltered ) then
			button.selectedHighlight:Show()
		else
			button.selectedHighlight:Hide()
		end
	end
end

function CompactRaidFrameManagerMixin:ToggleRoleFilter(role)
	CRF_SetFilterRole(role, not CRF_GetFilterRole(role))
	self:UpdateFilterInfo()
	CompactRaidFrameContainer:TryUpdate()
end

function CompactRaidFrameManagerMixin:UpdateGroupFilterButton(button, usedGroups)
	local group = button:GetID()
	if usedGroups[group] then
		button:Enable()
		button:SetAlpha(1)
		local isFiltered = CRF_GetFilterGroup(group)
		if isFiltered then
			button.selectedHighlight:Show()
		else
			button.selectedHighlight:Hide()
		end
	else
		button.selectedHighlight:Hide()
		button:Disable()
		button:SetAlpha(0.5)
	end
end

function CompactRaidFrameManagerMixin:ToggleGroupFilter(group)
	CRF_SetFilterGroup(group, not CRF_GetFilterGroup(group))
	self:UpdateFilterInfo()
	CompactRaidFrameContainer:TryUpdate()
end

function CompactRaidFrameManagerMixin:UpdateRaidIcons()
	local unit = "target"
	local button
	for i=1, NUM_RAID_ICONS do
		button = _G["CompactRaidFrameManagerDisplayFrameRaidMarkersRaidMarker"..i]	--.... /cry
		if button:GetID() == GetRaidTargetIndex(unit) then
			button:GetNormalTexture():SetDesaturated(true)
			button:SetAlpha(0.7)
			button:Disable()
		else
			button:GetNormalTexture():SetDesaturated(false)
			button:SetAlpha(1)
			button:Enable()
		end
	end
	
	local removeButton = CompactRaidFrameManagerDisplayFrameRaidMarkersRaidMarkerRemove
	if not GetRaidTargetIndex(unit) then
		removeButton:GetNormalTexture():SetDesaturated(true)
		removeButton:Disable()
	else
		removeButton:GetNormalTexture():SetDesaturated(false)
		removeButton:Enable()
	end
end


--Settings stuff
local cachedSettings = {}
local isSettingCached = {}
function CompactRaidFrameManagerMixin:GetSetting(settingName)
	if ( not isSettingCached[settingName] ) then
		cachedSettings[settingName] = self:GetSettingBeforeLoad(settingName)
		isSettingCached[settingName] = true
	end
	return cachedSettings[settingName]
end

function CompactRaidFrameManagerMixin:GetSettingBeforeLoad(settingName)
	if settingName == "Locked" then
		return true
	elseif settingName == "SortMode" then
		return "role"
	elseif settingName == "KeepGroupsTogether" then
		return false
	elseif settingName == "DisplayPets" then
		return false
	elseif settingName == "DisplayMainTankAndAssist" then
		return true
	elseif settingName == "IsShown" then
		return true
	elseif settingName == "ShowBorders" then
		return true
	elseif settingName == "HorizontalGroups" then
		return false
	else
		C_Logger.Error("Unknown setting "..tostring(settingName))
	end
end

do	--Enclosure to make sure people go through SetSetting

	local function CompactRaidFrameManager_SetLocked(value)
		local manager = CompactRaidFrameManager
		if value then
			CompactRaidFrameManagerDisplayFrameLockedModeToggle:SetText(UNLOCK)
			CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode = false
			manager:UpdateContainerLockVisibility()
		else
			CompactRaidFrameManagerDisplayFrameLockedModeToggle:SetText(LOCK)
			CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode = true
			manager:UpdateContainerLockVisibility()
		end
	end

	local function CompactRaidFrameManager_SetSortMode(value)
		local manager = CompactRaidFrameManager
		if value == "group" then
			manager.container:SetFlowSortFunction(CRFSort_Group)
		elseif value == "role" then
			manager.container:SetFlowSortFunction(CRFSort_Role)
		elseif value == "alphabetical" then
			manager.container:SetFlowSortFunction(CRFSort_Alphabetical)
		elseif value == "stat" then
			manager.container:SetFlowSortFunction(CRFSort_PrimaryStat)
		else
			manager:SetSetting("SortMode", "role")
			C_Logger.Error("Unknown sort mode: "..tostring(value))
		end
	end

	local function CompactRaidFrameManager_SetKeepGroupsTogether(value)
		local manager = CompactRaidFrameManager
		local groupMode
		if not value then
			groupMode = "flush"
		else
			groupMode = "discrete"
		end

		manager.container:SetGroupMode(groupMode)
		manager:UpdateFilterInfo()
	end

	local function CompactRaidFrameManager_SetDisplayPets(value)
		local container = CompactRaidFrameManager.container
		local displayPets
		if value then
			displayPets = true
		end

		container:SetDisplayPets(displayPets)
	end

	local function CompactRaidFrameManager_SetDisplayMainTankAndAssist(value)
		local container = CompactRaidFrameManager.container
		local displayFlaggedMembers
		if value then
			displayFlaggedMembers = true
		end

		container:SetDisplayMainTankAndAssist(displayFlaggedMembers)
	end

	local function CompactRaidFrameManager_SetIsShown(value)
		local manager = CompactRaidFrameManager
		if value then
			manager.container.enabled = true
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetText(HIDE)
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode = false
		else
			manager.container.enabled = false
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle:SetText(SHOW)
			CompactRaidFrameManagerDisplayFrameHiddenModeToggle.shownMode = true
		end
		manager:UpdateContainerVisibility()
	end

	local function CompactRaidFrameManager_SetBorderShown(value)
		local manager = CompactRaidFrameManager
		local showBorder
		if value then
			showBorder = true
		end
		CUF_SHOW_BORDER = showBorder
		manager.container:SetBorderShown(showBorder)
	end

	local function CompactRaidFrameManager_SetHorizontalGroups(value)
		local horizontalGroups
		if value then
			horizontalGroups = true
		end
		CUF_HORIZONTAL_GROUPS = horizontalGroups
	end

	function CompactRaidFrameManagerMixin:SetSetting(settingName, value)
		cachedSettings[settingName] = value
		isSettingCached[settingName] = true

		--Perform the actual functions
		if  settingName == "Locked" then
			CompactRaidFrameManager_SetLocked(value)
		elseif settingName == "SortMode" then
			CompactRaidFrameManager_SetSortMode(value)
		elseif settingName == "KeepGroupsTogether" then
			CompactRaidFrameManager_SetKeepGroupsTogether(value)
		elseif settingName == "DisplayPets" then
			CompactRaidFrameManager_SetDisplayPets(value)
		elseif settingName == "DisplayMainTankAndAssist" then
			CompactRaidFrameManager_SetDisplayMainTankAndAssist(value)
		elseif settingName == "IsShown"  then
			CompactRaidFrameManager_SetIsShown(value)
		elseif settingName == "ShowBorders" then
			CompactRaidFrameManager_SetBorderShown(value)
		elseif settingName == "HorizontalGroups" then
			CompactRaidFrameManager_SetHorizontalGroups(value)
		else
			C_Logger.Error("Unknown setting "..tostring(settingName))
		end
	end
end

function CompactRaidFrameManagerMixin:UpdateContainerVisibility()
	if GetDisplayedAllyFrames() == "raid" and self.container.enabled then
		self.container:Show()
	else
		self.container:Hide()
	end
end

function CompactRaidFrameManagerMixin:AttachPartyFrames()
	PartyMemberFrame1:ClearAllPoints()
	PartyMemberFrame1:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, -20)
end

function CompactRaidFrameManagerMixin:ResetContainerPosition()
	self.dynamicContainerPosition = true
	self:UpdateContainerBounds()
	self:ResizeFrame_SavePosition()
end

function CompactRaidFrameManagerMixin:UpdateContainerBounds() --Hah, "Bounds" instead of "SizeAndPosition". WHO NEEDS A THESAURUS NOW?!	
	self.containerResizeFrame:SetMaxResize(self.containerResizeFrame:GetWidth(), GetScreenHeight() - 90)

	if self.dynamicContainerPosition then
		--Should be below the TargetFrameSpellBar at its lowest height..
		local top = GetScreenHeight() - 135
		--Should be just above the FriendsFrameMicroButton.
		local bottom = 330

		local managerTop = self:GetTop()

		self.containerResizeFrame:ClearAllPoints()
		self.containerResizeFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, top - managerTop)
		self.containerResizeFrame:SetHeight(top - bottom)

		self:ResizeFrame_UpdateContainerSize()
	end
end

function CompactRaidFrameManagerMixin:UpdateContainerLockVisibility()
	if GetDisplayedAllyFrames() ~= "raid" or not CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode then
		self:LockContainer()
	else
		self:UnlockContainer()
	end
end

function CompactRaidFrameManagerMixin:LockContainer()
	self.containerResizeFrame:Hide()
end

function CompactRaidFrameManagerMixin:UnlockContainer()
	self.containerResizeFrame:Show()
end

--ResizeFrame related functions
function CompactRaidFrameManagerMixin:ResizeFrame_Reanchor()
	self.container:SetPoint("TOPLEFT", self.containerResizeFrame, "TOPLEFT", RESIZE_HORIZONTAL_OUTSETS, -RESIZE_VERTICAL_OUTSETS)
end

function CompactRaidFrameManagerMixin:ResizeFrame_OnDragStart()
	self.dynamicContainerPosition = false

	self.containerResizeFrame:StartMoving()
end

function CompactRaidFrameManagerMixin:ResizeFrame_OnDragStop()
	self.containerResizeFrame:StopMovingOrSizing()
	self:ResizeFrame_CheckMagnetism()
	self:ResizeFrame_SavePosition()
end

function CompactRaidFrameManagerMixin:ResizeFrame_OnResizeStart()
	self.dynamicContainerPosition = false

	self.containerResizeFrame:StartSizing("BOTTOM")
	self.containerResizeFrame:SetScript("OnUpdate", GenerateClosure(self.ResizeFrame_OnUpdate, self))
end

function CompactRaidFrameManagerMixin:ResizeFrame_OnResizeStop()
	self.containerResizeFrame:StopMovingOrSizing()
	self.containerResizeFrame:SetScript("OnUpdate", nil)
	self:ResizeFrame_UpdateContainerSize()
	self:ResizeFrame_CheckMagnetism()
	self:ResizeFrame_SavePosition()
end

local RESIZE_UPDATE_INTERVAL = 0.5
function CompactRaidFrameManagerMixin:ResizeFrame_OnUpdate(resizeFrame, elapsed)
	resizeFrame.timeSinceUpdate = (resizeFrame.timeSinceUpdate or 0) + elapsed
	if resizeFrame.timeSinceUpdate >= RESIZE_UPDATE_INTERVAL then
		self:ResizeFrame_UpdateContainerSize()
		self:ResizeFrame_CheckMagnetism()
		self:ResizeFrame_SavePosition()
	end
end

function CompactRaidFrameManagerMixin:ResizeFrame_UpdateContainerSize()
	--If we're flow style, we want to make sure we exactly fit N frames.
	local keepGroupsTogether = self:GetSetting("KeepGroupsTogether")
	if keepGroupsTogether ~= "1" then
		local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
		local resizerHeight = self.containerResizeFrame:GetHeight() - RESIZE_VERTICAL_OUTSETS * 2
		local newHeight = unitFrameHeight * floor(resizerHeight / unitFrameHeight)
		self.container:SetHeight(newHeight)
	else
		self.container:SetHeight(self.containerResizeFrame:GetHeight() - RESIZE_VERTICAL_OUTSETS * 2)
	end
end

local MAGNETIC_FIELD_RANGE = 10
function CompactRaidFrameManagerMixin:ResizeFrame_CheckMagnetism()
	if abs(self.containerResizeFrame:GetLeft() - self:GetRight()) < MAGNETIC_FIELD_RANGE and
			self.containerResizeFrame:GetTop() > self:GetBottom() and self.containerResizeFrame:GetBottom() < self:GetTop() then
		self.containerResizeFrame:ClearAllPoints()
		self.containerResizeFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, self.containerResizeFrame:GetTop() - self:GetTop())
	end
end

function CompactRaidFrameManagerMixin:ResizeFrame_SavePosition()
	if self.dynamicContainerPosition then
		SetRaidProfileSavedPosition(GetActiveRaidProfile(), true)
		return
	end

	--The stuff we're actually saving
	local topPoint, topOffset
	local bottomPoint, bottomOffset
	local leftPoint, leftOffset

	local screenHeight = GetScreenHeight()
	local top = self.containerResizeFrame:GetTop()
	if top > screenHeight / 2 then
		topPoint = "TOP"
		topOffset = screenHeight - top
	else
		topPoint = "BOTTOM"
		topOffset = top
	end

	local height = self.containerResizeFrame:GetHeight()

	local isAttached = (select(2, self.containerResizeFrame:GetPoint(1)) == self)
	if isAttached then
		leftPoint = "ATTACHED"
		leftOffset = 0
	else
		local screenWidth = GetScreenWidth()
		local left = self.containerResizeFrame:GetLeft()
		if left > screenWidth / 2 then
			leftPoint = "RIGHT"
			leftOffset = screenWidth - left
		else
			leftPoint = "LEFT"
			leftOffset = left
		end
	end

	SetRaidProfileSavedPosition(GetActiveRaidProfile(), false, topPoint, topOffset, height, leftPoint, leftOffset)
end

function CompactRaidFrameManagerMixin:ResizeFrame_LoadPosition()
	local dynamic, topPoint, topOffset, height, leftPoint, leftOffset = GetRaidProfileSavedPosition(GetActiveRaidProfile())

	if dynamic then	--We are automatically placed.
		self.dynamicContainerPosition = true
		self:UpdateContainerBounds()
		return
	else
		self.dynamicContainerPosition = false
	end

	--First, let's clear the container's current anchors.
	self.containerResizeFrame:ClearAllPoints()

	height = MClamp(height, MINIMUM_RAID_CONTAINER_HEIGHT, GetScreenHeight())

	local top
	if topPoint == "TOP" then
		top = topOffset
	else
		top = topOffset
		top = max(top, height)
	end


	self.containerResizeFrame:SetHeight(height)

	if leftPoint == "ATTACHED" then
		self.containerResizeFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, top - (GetScreenHeight() - self:GetTop()))
	else
		local left
		if leftPoint == "RIGHT" then
			left = GetScreenWidth() - leftOffset
		else
			left = leftOffset
		end

		if topPoint == "TOP" then
			self.containerResizeFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, -top)
		else
			self.containerResizeFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		end
	end

	self:ResizeFrame_UpdateContainerSize()
end

-------------Utility functions-------------
--Functions used for sorting and such
function CRFSort_Group(token1, token2)
	if GroupUtil_IsInRaid() then
		local id1 = tonumber(string.sub(token1, 5))
		local id2 = tonumber(string.sub(token2, 5))
		
		if not id1 or not id2 then
			return id1
		end

		local _, _, subgroup1 = GetRaidRosterInfo(id1)
		local _, _, subgroup2 = GetRaidRosterInfo(id2)
		
		if subgroup1 and subgroup2 and subgroup1 ~= subgroup2 then
			return subgroup1 < subgroup2
		end
		
		--Fallthrough: Sort by order in Raid window.
		return id1 < id2
	else
		if token1 == "player" then
			return true
		elseif token2 == "player" then
			return false
		else
			return token1 < token2	--String compare is OK since we don't go above 1 digit for party.
		end
	end
end

local roleValues = { MAINTANK = 1, MAINASSIST = 2, TANK = 3, HEALER = 4, DAMAGER = 5, NONE = 6 }
function CRFSort_Role(token1, token2)
	local id1, id2 = UnitInRaid(token1), UnitInRaid(token2)
	local role1, role2
	if id1 then
		role1 = select(10, GetRaidRosterInfo(id1))
	end
	if id2 then
		role2 = select(10, GetRaidRosterInfo(id2))
	end
	
	role1 = role1 or UnitGroupRolesAssignedKey(token1)
	role2 = role2 or UnitGroupRolesAssignedKey(token2)
	
	local value1, value2 = roleValues[role1], roleValues[role2]
	if value1 ~= value2 then
		return value1 < value2
	end
	
	--Fallthrough: Sort alphabetically.
	return CRFSort_Alphabetical(token1, token2)
end

function CRFSort_PrimaryStat(token1, token2)
	local role1 = UnitPrimaryStat(token1)
	local role2 = UnitPrimaryStat(token2)
	if role1 and role2 and role1 ~= role2 then
		return role1 < role2
	end

	--Fallthrough: Sort role.
	return CRFSort_Role(token1, token2)
end

function CRFSort_Alphabetical(token1, token2)
	local name1, name2 = UnitName(token1), UnitName(token2)
	if name1 and name2 then
		return name1 < name2
	elseif name1 or name2 then
		return name1
	end
	
	--Fallthrough: Alphabetic order of tokens (just here to make comparisons well-ordered)
	return token1 < token2
end

--Functions used for filtering
local filterOptions = {
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
	[7] = true,
	[8] = true,
	displayRoleNONE = true,
	displayRoleTANK = true,
	displayRoleHEALER = true,
	displayRoleDAMAGER = true,
	
}
function CRF_SetFilterRole(role, show)
	filterOptions["displayRole"..role] = show
end

function CRF_GetFilterRole(role)
	return filterOptions["displayRole"..role]
end

function CRF_SetFilterGroup(group, show)
	assert(type(group) == "number")
	filterOptions[group] = show
end

function CRF_GetFilterGroup(group)
	assert(type(group) == "number")
	return filterOptions[group]
end

function CRFFlowFilterFunc(token)
	if not UnitExists(token) then
		return false
	end
	
	if not GroupUtil_IsInRaid() then	--We don't filter unless we're in a raid.
		return true
	end
	
	local role = UnitGroupRolesAssignedKey(token)
	if not filterOptions["displayRole"..role] then
		return false
	end
	
	local raidID = UnitInRaid(token)
	if raidID then
		local _, _, subgroup, _, _, _, _, _, _, raidRole = GetRaidRosterInfo(raidID)
		if not filterOptions[subgroup] then
			return false
		end
		
		local showingMTandMA = CompactRaidFrameManager:GetSetting("DisplayMainTankAndAssist")
		if raidRole and (showingMTandMA and showingMTandMA ~= "0") then	--If this character is already displayed as a Main Tank/Main Assist, we don't want to show them a second time
			return false
		end
	end
	
	return true
end

function CRFGroupFilterFunc(groupNum)
	return filterOptions[groupNum]
end

--Counting functions
RaidInfoCounts = {
	aliveRoleTANK 		= 0,
	totalRoleTANK		= 0,
	aliveRoleHEALER		= 0,
	totalRoleHEALER		= 0,
	aliveRoleDAMAGER	= 0,
	totalRoleDAMAGER	= 0,
	aliveRoleNONE		= 0,
	totalRoleNONE		= 0,
	totalCount			= 0,
	totalAlive			= 0,
}

local function CRF_ResetCountedStuff()
	for key, val in pairs(RaidInfoCounts) do
		RaidInfoCounts[key] = 0
	end
end

function CRF_CountStuff()
	CRF_ResetCountedStuff()
	if GroupUtil_IsInRaid() then
		local name, isDead, _
		for i=1, GroupUtil_GetNumGroupMembers() do
			name, _, _, _, _, _, _, _, isDead = GetRaidRosterInfo(i)
			if name then
				CRF_AddToCount(isDead, UnitGroupRolesAssignedKey("raid"..i))
			end
		end
	else
		local unit
		CRF_AddToCount(UnitIsDeadOrGhost("player") , UnitGroupRolesAssignedKey("player"))
		for i=1, GroupUtil_GetNumGroupMembers() do
			unit = "party"..i
			CRF_AddToCount(UnitIsDeadOrGhost(unit), UnitGroupRolesAssignedKey(unit))
		end
	end		
end

function CRF_AddToCount(isDead, assignedRole)
	RaidInfoCounts.totalCount = RaidInfoCounts.totalCount + 1
	RaidInfoCounts["totalRole"..assignedRole] = RaidInfoCounts["totalRole"..assignedRole] + 1
	if not isDead then
		RaidInfoCounts.totalAlive = RaidInfoCounts.totalAlive + 1
		RaidInfoCounts["aliveRole"..assignedRole] = RaidInfoCounts["aliveRole"..assignedRole] + 1
	end
end

function CompactRaidFrameManagerDisplayFrameProfileSelector_SetUp(self)
	UIDropDownMenu_SetWidth(self, 165)
	UIDropDownMenu_Initialize(self, CompactRaidFrameManagerDisplayFrameProfileSelector_Initialize)
end

function CompactRaidFrameManagerDisplayFrameProfileSelector_Initialize()
	local info = UIDropDownMenu_CreateInfo()

	local name
	for i=1, GetNumRaidProfiles() do
		name = GetRaidProfileName(i)
		info.text = name
		info.value = name
		info.func = CompactRaidFrameManagerDisplayFrameProfileSelector_OnClick
		info.checked = GetActiveRaidProfile() == info.value
		UIDropDownMenu_AddButton(info)
	end
end

function CompactRaidFrameManagerDisplayFrameProfileSelector_OnClick(self)
	local profile = self.value
	CompactUnitFrameProfiles_ActivateRaidProfile(profile)
end


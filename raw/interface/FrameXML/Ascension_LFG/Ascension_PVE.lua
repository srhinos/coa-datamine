--
-- PVE Frame Mixin
--
PVEFrameMixin = {
    categories = {
        { name = "AscensionPVEFrameLFDFrame", label = "LOOKING_FOR_DUNGEON", icon = "Interface\\Icons\\INV_Helmet_08", helpPlate = "PVE_FRAME", canUse = function() return C_LFG:CanUseLFD() end },
		{ name = "ManastormQueueFrame", loadOnDemand = Manastorm_LoadUI, label = "THE_MANASTORM", icon = "Interface\\LFGFrame\\lfgicon-arcanevaults", canUse = function() return C_LFG:CanUseManastorm() end },
	},
    tankIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:%d:64:64:0:19:22:41|t",
    healerIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:%d:64:64:20:39:1:20|t",
    damageIcon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:16:16:0:%d:64:64:20:39:22:41|t",
}

function PVEFrameMixin:OnLoad()
    LFGEventFrame:UnregisterAllEvents()
    self:RegisterEvent("LFG_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")

	self:RegisterEvent("LFG_OFFER_CONTINUE")
	self:RegisterEvent("LFG_ROLE_CHECK_ROLE_CHOSEN")

	--These just update states (roles changeable, buttons clickable, etc.)
	self:RegisterEvent("LFG_PROPOSAL_UPDATE")
	self:RegisterEvent("LFG_PROPOSAL_SHOW")
	self:RegisterEvent("LFG_ROLE_CHECK_SHOW")
	self:RegisterEvent("LFG_ROLE_CHECK_HIDE")
	self:RegisterEvent("LFG_BOOT_PROPOSAL_UPDATE")
	self:RegisterEvent("LFG_ROLE_UPDATE")
	self:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
	self:RegisterEvent("LFG_PROPOSAL_FAILED")
	self:HookBucketEvent("PLAYER_EQUIPMENT_CHANGED", 0.5)
end

function PVEFrameMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end

    LFG_UpdateRolesChangeable()
	LFG_UpdateFindGroupButtons()
	LFG_UpdateLockedOutPanels()
	self.LFDFrame:UpdateBackfill()
end

function PVEFrameMixin:OnShow()
    local parent = self:GetParent():GetParent()

    for i = 1, 3 do
        local button = parent["Button"..i]
        local category = self.categories[i]

        if not category then
            button:Hide()
        else
            button:Show()
            button.Icon:SetPortraitTexture(category.icon)
            button.Name:SetText(_G[category.label] or category.label)

            local canUse, reason = category.canUse()

            if not canUse then
                button:Disable()
                button.BG:SetDesaturated(true)
                button.Icon:SetDesaturated(true)
                button.Name:SetFontObject("GameFontDisableLarge")
                button.tooltip = _G[reason] or reason
            else
                button:Enable()
                button.BG:SetDesaturated(false)
                button.Icon:SetDesaturated(false)
                button.Name:SetFontObject("GameFontNormalLarge")
                button.tooltip = nil
            end
        end
    end

	UpdateMicroButtons()
end

function PVEFrameMixin:OnHide()
	for i = 1, 3 do
		local category = self.categories[i]

		if category then
			local frame = _G[category.name]
			if frame then frame:Hide() end
		end
	end

	HelpTip:Hide("LFD_ROLE_SELECT_HELP")
end

function PVEFrameMixin:ShowCategory(index)
	if not index or not self.categories[index] or not self.categories[index].canUse() then
		for i, category in ipairs(self.categories) do
			if category.canUse() then
				index = i
				break
			end
		end
	end

    local data = self.categories[index]
    local parent = self:GetParent():GetParent()

    if not data then return end

	if data.helpPlate then
		self.HelpPlateButton:Show()
		self.HelpPlateButton:SetAttribute("HelpPlate", data.helpPlate)
	else
		self.HelpPlateButton:Hide()
	end

	if data.loadOnDemand then
		data.loadOnDemand()
	end

	if data.changeTab then
		for i = 1, 3 do
			local button = parent["Button"..i]
			button:Hide()
			local category = self.categories[i]

			if category then
				local frame = _G[category.name]
				if frame then frame:Hide() end
				button.BG:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
			end
		end
		AscensionLFGFrame:ShowFrame(data.name)
		return
	end

    self.selectedIndex = index

    for i = 1, 3 do
        local button = parent["Button"..i]
        local category = self.categories[i]

        if category then
            local frame = _G[category.name]
            button:Show()

            if i == self.selectedIndex and category.canUse() then
                if frame then frame:Show() end
                button.BG:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188)
            else
                if frame then frame:Hide() end
                button.BG:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
            end
        else
            button:Hide()
        end
    end
end

function PVEFrameMixin:UpdateFramesIfShown()
	for _, category in ipairs(self.categories) do
        local frame = _G[category.name]
        if frame and frame.Update and frame:IsShown() then
            _G[category.name]:Update()
        end
    end
end

function PVEFrameMixin:UpdateQueuedList()
	GetLFGQueuedList(LFGQueuedForList)
	self:UpdateFramesIfShown()
	MiniMapLFG_UpdateIsShown()
end

-- Events
function PVEFrameMixin:LFG_UPDATE()
    self:UpdateQueuedList()
end

function PVEFrameMixin:PLAYER_ENTERING_WORLD()
    self:UpdateQueuedList()
	LFG_UpdateRoleCheckboxes()
end

function PVEFrameMixin:LFG_LOCK_INFO_RECEIVED()
	LFGDungeonList_Setup(true)
	self:UpdateFramesIfShown()
end

function PVEFrameMixin:PARTY_MEMBERS_CHANGED()
    self:UpdateQueuedList()
	self:UpdateFramesIfShown()
	if not CanPartyLFGBackfill() then
		StaticPopup_Hide("LFG_OFFER_CONTINUE")
	end
end

function PVEFrameMixin:LFG_OFFER_CONTINUE(displayName, lfgID, typeID)
    local dialog = StaticPopup_Show("LFG_OFFER_CONTINUE", NORMAL_FONT_COLOR_CODE..displayName.."|r")
    if dialog then
        dialog.data = lfgID
        dialog.data2 = typeID
    end
end

function PVEFrameMixin:LFG_ROLE_CHECK_ROLE_CHOSEN(player, isTank, isHealer, isDamage)
    --Yes, consecutive string concatenation == bad for garbage collection. But the alternative is either extremely unslightly or localization unfriendly. (Also, this happens fairly rarely)
    local roleList

    --Horrible hack to deal with a bug in embedded font strings. FIXME
    --The more icons with absolute sizes in a certain fontstring, the higher up the text goes. This offsets it to make the icons be in line with the text.
    local numRoles = (isTank and 1 or 0) + (isHealer and 1 or 0) + (isDamage and 1 or 0)
    local yOffset = 2 * (numRoles - 1) - 2	--Formula derived through testing.

    local tankIcon = format(self.tankIcon, yOffset)
    local healerIcon = format(self.healerIcon, yOffset)
    local damageIcon = format(self.damageIcon, yOffset)

    if isTank then
        roleList = tankIcon.." "..TANK
    end
    if isHealer then
        if roleList then
            roleList = roleList..PLAYER_LIST_DELIMITER.." "..healerIcon.." "..HEALER
        else
            roleList = healerIcon.." "..HEALER
        end
    end
    if isDamage then
        if roleList then
            roleList = roleList..PLAYER_LIST_DELIMITER.." "..damageIcon.." "..DAMAGER
        else
            roleList = damageIcon.." "..DAMAGER
        end
    end
    assert(roleList)
    SendSystemMessage(string.format(LFG_ROLE_CHECK_ROLE_CHOSEN, player, roleList))
end

function PVEFrameMixin:PLAYER_EQUIPMENT_CHANGED()
	RequestLFDPlayerLockInfo()
	RequestLFDPartyLockInfo()
end
--
-- LFD Frame Mixin
--
LFDFrameMixin = {}

local LFDRoleRequirementRoleMask = {
	TANK = Enum.LFGRoles.Tank,
	HEALER = Enum.LFGRoles.Healer,
	DAMAGER = Enum.LFGRoles.Damager,
}

local function GetLFDRoleRequirementName(conditionValue)
	local spellLink = GetSpellLink(conditionValue)
	if spellLink then
		return spellLink
	end

	local spellName = GetSpellInfo(conditionValue)
	if spellName then
		return spellName
	end

	return tostring(conditionValue)
end

local function GetLFDRoleRequirementText(requirement)
	local conditionTypeName = requirement.ConditionTypeName
	local conditionValue = requirement.ConditionValue

	if conditionTypeName == "SpellKnown" then
		return format("%s %s", REQUIRES_LABEL, GetLFDRoleRequirementName(conditionValue))
	elseif conditionTypeName == "AuraActive" then
		return format("%s %s", REQUIRES_LABEL, GetLFDRoleRequirementName(conditionValue))
	end

	return format("Requires %s: %s", conditionTypeName or UNKNOWN, tostring(conditionValue))
end

local function GetLFDRoleRequirementTooltipLines(role)
	if type(GetAdditionalRoleRequirementsByClassID) ~= "function" then
		return
	end

	local _, classID = C_Player:GetClass()
	local roleMask = LFDRoleRequirementRoleMask[role]
	if not classID or not roleMask then
		return
	end

	local ok, requirements = pcall(GetAdditionalRoleRequirementsByClassID, classID)
	if not ok or type(requirements) ~= "table" then
		return
	end

	local tooltipLines
	for _, requirement in ipairs(requirements) do
		if requirement.Role == roleMask and not requirement.Met then
			tooltipLines = tooltipLines or {}
			tinsert(tooltipLines, GetLFDRoleRequirementText(requirement))
		end
	end

	return tooltipLines
end

local function LFDRoleButton_OnEnter(button, originalOnEnter, ...)
	if originalOnEnter then
		originalOnEnter(button, ...)
	end

	if button.permDisabled then
		local tooltipLines = GetLFDRoleRequirementTooltipLines(button.role)
		if tooltipLines and #tooltipLines > 0 then
			if not GameTooltip:IsOwned(button) then
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip:SetText(_G[button.role], 1, 1, 1)
			end

			GameTooltip_AddSpacer(GameTooltip)
			for _, line in ipairs(tooltipLines) do
				GameTooltip:AddLine(line, 1, 0.82, 0, true)
			end

			GameTooltip:Show()
		end
	end
end

function LFDFrameMixin:OnLoad()
    LFDParentFrame:UnregisterAllEvents()
    self:RegisterEvent("LFG_PROPOSAL_UPDATE")
	self:RegisterEvent("LFG_PROPOSAL_SHOW")
	self:RegisterEvent("LFG_PROPOSAL_FAILED")
	self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("LFG_ROLE_CHECK_SHOW")
	self:RegisterEvent("LFG_ROLE_CHECK_HIDE")
	self:RegisterEvent("LFG_BOOT_PROPOSAL_UPDATE")
	self:RegisterEvent("VOTE_KICK_REASON_NEEDED")
	self:RegisterEvent("LFG_ROLE_UPDATE")
	self:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
	self:RegisterEvent("LFG_OPEN_FROM_GOSSIP")
	self:RegisterEvent("GOSSIP_CLOSED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")

	self:SetupRoleRequirementTooltips()
end

function LFDFrameMixin:SetupRoleRequirementTooltips()
	for _, button in ipairs({ self.Tank, self.Healer, self.Dps }) do
		if not button.roleRequirementTooltipHooked then
			local originalOnEnter = button:GetScript("OnEnter")
			button:SetScript("OnEnter", function(self, ...)
				LFDRoleButton_OnEnter(self, originalOnEnter, ...)
			end)
			button.roleRequirementTooltipHooked = true
		end
	end
end

function LFDFrameMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function LFDFrameMixin:OnShow()
	local parent = self:GetParent():GetParent():GetParent()
	parent.PortraitFrame.portrait:SetPortraitTexture("Interface\\LFGFrame\\UI-LFG-PORTRAIT")
	parent.TitleText:SetText(DUNGEONS_AND_RAIDS)
	self:UpdateBackfill(true)
	parent:SetSize(parent.BASE_WIDTH, parent.BASE_HEIGHT)

    self:SetupDropdown()
    RequestLFDPlayerLockInfo()
    RequestLFDPartyLockInfo()
    self:Update()
	self:SetShowRoleBonuses(false)
end

local function Dropdown_OnClick(self)
    local lfd = _G["AscensionPVEFrameLFDFrame"]
    lfd:SetType(self.value)
end

function LFDFrameMixin:SetType(value)
    self.type = value
	UIDropDownMenu_SetSelectedValue(self.Dropdown, value)
	if type(self.type) == "number" then
		UIDropDownMenu_SetText(self.Dropdown, GetLFGDungeonInfo(self.type))
	end

	if ( value == "specific" ) then
		self.BG:SetTexture("Interface\\LFGFrame\\UI-LFG-BACKGROUND-DUNGEONWALL")
        self.Random:Hide()
        self.Specific:Show()
		self:SetShowRoleBonuses(false)
	else
		self.BG:SetTexture("Interface\\LFGFrame\\UI-LFG-BACKGROUND-QUESTPAPER")
        self.Specific:Hide()
        self.Random:Show()
		self:SetShowRoleBonuses(true)
		self:UpdateRandom()
	end
end

function LFDFrameMixin:SetShowRoleBonuses(show)
	if self.Tank:IsEnabled() and show then
		self.Tank.ShortageBorder:Show()
		self.Tank.IncentiveIcon:Show()
	else
		self.Tank.ShortageBorder:Hide()
		self.Tank.IncentiveIcon:Hide()
	end

	if self.Healer:IsEnabled() and show then
		self.Healer.ShortageBorder:Show()
		self.Healer.IncentiveIcon:Show()
	else
		self.Healer.ShortageBorder:Hide()
		self.Healer.IncentiveIcon:Hide()
	end
end

function LFDFrameMixin:InitializeDropdown()
	local info = UIDropDownMenu_CreateInfo()

	if C_Player:IsMaxLevel() then
		info.text = SPECIFIC_DUNGEONS
		info.value = "specific"
		info.func = Dropdown_OnClick
		info.checked = self.type == info.value
		UIDropDownMenu_AddButton(info)
	elseif C_AccountInfo.GetGMLevel() > 0 then
		info.text = "(GM) "..SPECIFIC_DUNGEONS
		info.value = "specific"
		info.func = Dropdown_OnClick
		info.checked = self.type == info.value
		UIDropDownMenu_AddButton(info)
	end

	for i=1, GetNumRandomDungeons() do
		local id, name = GetLFGRandomDungeonInfo(i)
		local isAvailable = IsLFGDungeonJoinable(id)
		if  C_LFG:IsRandomDungeonDisplayable(id) then
			if isAvailable then
				info.text = name
				info.value = id
				info.isTitle = nil
				info.func = Dropdown_OnClick
				local canUse, reason = C_LFG:CanUseRandomLFD(id)
				if canUse then
				    info.disabled = nil
				    info.checked = (self.type == info.value)
				    info.tooltipWhileDisabled = nil
				    info.tooltipOnButton = nil
				    info.tooltipTitle = nil
				    info.tooltipText = nil
				else
				    info.disabled = true
				    info.checked = false
				    info.tooltipWhileDisabled = true
				    info.tooltipOnButton = true
			        info.tooltipTitle = ERR_CANNOT_QUEUE_FOR_DIFFICULTY
				    info.tooltipText = reason
				end
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

function LFDFrameMixin:SetupDropdown()
    UIDropDownMenu_SetWidth(self.Dropdown, 180)
	UIDropDownMenu_Initialize(self.Dropdown, function() self:InitializeDropdown() end)
    self:LFG_UPDATE_RANDOM_INFO()
end

function LFDFrameMixin:UpdateRandom()
	local parentFrame = self.Random.Scroll.Child

	local dungeonID = self.type

	if not dungeonID then	--We haven't gotten info on available dungeons yet.
		return
	end

	local dungeonName, _, _, _, _, _, _, _, _, textureFilename, difficulty, _, dungeonDescription, isHoliday = GetLFGDungeonInfo(dungeonID)
	local isHeroic = difficulty > 0
	local doneToday, moneyBase, moneyVar, experienceBase, experienceVar, numRewards, rewards = C_LFG:GetLFGDungeonRewards(dungeonID)
	local numRandoms = 4 - GetNumPartyMembers()
	local moneyAmount = moneyBase and moneyVar and moneyBase + moneyVar * numRandoms or 0
	local experienceGained = experienceBase + experienceVar * numRandoms

	local backgroundTexture
	if ( isHeroic ) then
		backgroundTexture = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-HEROIC"
	elseif ( isHoliday ) then
		backgroundTexture = "Interface\\LFGFrame\\UI-LFG-HOLIDAY-BACKGROUND-"..textureFilename
	else
		backgroundTexture = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-QUESTPAPER"
	end

	if not self.BG:SetTexture(backgroundTexture) then
		self.BG:SetTexture("Interface\\LFGFrame\\UI-LFG-BACKGROUND-QUESTPAPER")
	end

	local lastFrame = parentFrame.rewardsLabel
	if isHoliday then
		if doneToday then
			parentFrame.rewardsDescription:SetText(LFD_HOLIDAY_REWARD_EXPLANATION2)
		else
			parentFrame.rewardsDescription:SetText(LFD_HOLIDAY_REWARD_EXPLANATION1)
		end
		parentFrame.title:SetText(dungeonName)
		parentFrame.description:SetText(dungeonDescription)
	else
		if doneToday then
			parentFrame.rewardsDescription:SetText(LFD_RANDOM_REWARD_EXPLANATION2)
		else
			parentFrame.rewardsDescription:SetText(LFD_RANDOM_REWARD_EXPLANATION1)
		end
		parentFrame.title:SetText(LFG_TYPE_RANDOM_DUNGEON)
		parentFrame.description:SetText(LFD_RANDOM_EXPLANATION)
	end

	for i=1, numRewards do
		local frame = parentFrame["Item"..i]
		if ( not frame ) then
			frame = CreateFrame("Button", parentFrame:GetName().."Item"..i, parentFrame, "AscensionLFDRandomDungeonLootTemplate")
			frame:SetID(i)
            parentFrame["Item"..i] = frame
			NUM_LFD_RANDOM_REWARD_FRAMES = i
			if ( mod(i, 2) == 0 ) then
				frame:SetPoint("LEFT", parentFrame["Item"..(i-1)], "RIGHT", 0, 0)
			else
				frame:SetPoint("TOPLEFT", parentFrame["Item"..(i-2)], "BOTTOMLEFT", 0, -8)
			end
		end

		if self.RewardCallbacks then
			for _, cancelToken in pairs(self.RewardCallbacks) do
				cancelToken()
			end
		end
		self.RewardCallbacks = {}

		local itemId, numItems, isBonus = unpack(rewards[i])

		local item = Item:CreateFromID(itemId)
		local cancelToken = item:CancelableContinueOnLoad(function(itemId)
			local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(itemId)
			local colorStr = quality and ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffFFFFFF"
			_G[frame:GetName().."Name"]:SetText(colorStr..(name or "Unknown Item").."|r")

			if quality and quality > 1 then
				frame.IconBorder:SetAtlas(ITEM_QUALITY_BORDER_ATLAS[quality])
			else
				frame.IconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
				frame.IconBorder:SetTexCoord(0, 1, 0, 1)
			end

			texture = texture or "Interface\\Icons\\inv_misc_questionmark"
			SetItemButtonTexture(frame, texture)
			SetItemButtonCount(frame, numItems)
			frame.item = itemId
			frame:Show()

			if isBonus then
				local _, isTank, isHealer = GetLFGRoles()
				frame.IconBorder:SetAtlas("loottoast-itemborder-gold", Const.TextureKit.IgnoreAtlasSize)
				local role = 1
				if isTank then
					frame["RoleIcon"..role]:Show()
					frame["RoleIcon"..role].role = "TANK"
					frame["RoleIcon"..role].Texture:SetTexCoord(GetTexCoordsForRoleSmallCircle("TANK"))
					role = role + 1
				end

				if isHealer then
					frame["RoleIcon"..role]:Show()
					frame["RoleIcon"..role].role = "HEALER"
					frame["RoleIcon"..role].Texture:SetTexCoord(GetTexCoordsForRoleSmallCircle("HEALER"))
					role = role + 1
				end

				for _ = role, 2 do
					frame["RoleIcon"..role]:Hide()
				end
			else
				frame.RoleIcon1:Hide()
				frame.RoleIcon2:Hide()
			end

			self.RewardCallbacks[itemId] = nil
		end)
		self.RewardCallbacks[itemId] = cancelToken
		lastFrame = frame
	end

	for i = numRewards + 1, NUM_LFD_RANDOM_REWARD_FRAMES do
		parentFrame["Item"..i]:Hide()
	end

	if numRewards > 0 or (moneyVar == 0 and experienceVar == 0) and (moneyAmount > 0 or experienceGained > 0) then
		parentFrame.rewardsLabel:Show()
		parentFrame.rewardsDescription:Show()
		lastFrame = parentFrame.rewardsDescription
	else
		parentFrame.rewardsLabel:Hide()
		parentFrame.rewardsDescription:Hide()
	end

	if numRewards > 0 then
		lastFrame = parentFrame["Item"..(numRewards - mod(numRewards + 1, 2))]
	end

	if moneyVar > 0 or experienceVar > 0 then
		parentFrame.pugDescription:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -5)
		parentFrame.pugDescription:Show()
		lastFrame = parentFrame.pugDescription
	else
		parentFrame.pugDescription:Hide()
	end

	if moneyAmount > 0 then
		MoneyFrame_Update(parentFrame.moneyFrame, moneyAmount)
		parentFrame.moneyLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 20, -10)
		parentFrame.moneyLabel:Show()
		parentFrame.moneyFrame:Show()

		parentFrame.xpLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -5)

		lastFrame = parentFrame.moneyLabel
	else
		parentFrame.moneyLabel:Hide()
		parentFrame.moneyFrame:Hide()
	end

	if experienceGained > 0 then
		parentFrame.xpAmount:SetText(experienceGained)

		if lastFrame == parentFrame.moneyLabel then
			parentFrame.xpLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -5)
		else
			parentFrame.xpLabel:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 20, -10)
		end
		parentFrame.xpLabel:Show()
		parentFrame.xpAmount:Show()

		lastFrame = parentFrame.xpLabel
	else
		parentFrame.xpLabel:Hide()
		parentFrame.xpAmount:Hide()
	end

	parentFrame.spacer:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -10)
end

function LFDFrameMixin:UpdateSpecific()
    if LFGDungeonList_Setup() then
		return	--Setup will update the list.
	end
	FauxScrollFrame_Update(self.Specific.Scroll, LFDGetNumDungeons(), NUM_LFD_CHOICE_BUTTONS, 16)

	local offset = FauxScrollFrame_GetOffset(self.Specific.Scroll)

	local areButtonsBig = not self.Specific.Scroll:IsShown()

	local mode, subMode = GetLFGMode()

	for i = 1, NUM_LFD_CHOICE_BUTTONS do
		local button = self.Specific["ListButton"..i]
		local dungeonID = LFDDungeonList[i+offset]
		if dungeonID then
			button:Show()
			if areButtonsBig then
				button:SetWidth(315)
			else
				button:SetWidth(295)
			end
			self:SetSpecificListButtonDungeon(button, dungeonID, mode, subMode)
		else
			button:Hide()
		end
	end
end

function LFDFrameMixin:DungeonChoiceEnableButton_OnClick(checkButton)
	local parent = checkButton:GetParent()
	local dungeonID = parent.id
	local isChecked = checkButton:GetChecked()

	PlaySound(isChecked and "igMainMenuOptionCheckBoxOff" or "igMainMenuOptionCheckBoxOff")
	if LFGIsIDHeader(dungeonID) then
		self:SetHeaderEnabled(dungeonID, isChecked)
	else
		self:SetDungeonEnabled(dungeonID, isChecked)
		LFGListUpdateHeaderEnabledAndLockedStates(LFDDungeonList, LFGEnabledList, LFGLockList, LFDHiddenByCollapseList)
	end
	self:UpdateSpecific()
end

function LFDFrameMixin:SetDungeonEnabled(dungeonID, isEnabled)
	SetLFGDungeonEnabled(dungeonID, isEnabled)
	LFGEnabledList[dungeonID] = not not isEnabled --Change to true/false.
end

function LFDFrameMixin:SetHeaderEnabled(headerID, isEnabled)
	for _, dungeonID in pairs(LFDDungeonList) do
		if LFGGetDungeonInfoByID(dungeonID)[LFG_RETURN_VALUES.groupID] == headerID then
			LFDList_SetDungeonEnabled(dungeonID, isEnabled)
		end
	end
	for _, dungeonID in pairs(LFDHiddenByCollapseList) do
		if LFGGetDungeonInfoByID(dungeonID)[LFG_RETURN_VALUES.groupID] == headerID then
			LFDList_SetDungeonEnabled(dungeonID, isEnabled)
		end
	end
	LFGEnabledList[headerID] = not not isEnabled --Change to true/false.
end

function LFDFrameMixin:ExpandOrCollapseButton_OnClick(expandOrCollapseButton)
	local parent = expandOrCollapseButton:GetParent()
    local headerID = parent.id
    local isCollapsed = not parent.isCollapsed

    SetLFGHeaderCollapsed(headerID, isCollapsed)
	LFGCollapseList[headerID] = isCollapsed
	for _, dungeonID in pairs(LFDDungeonList) do
		if ( LFGGetDungeonInfoByID(dungeonID)[LFG_RETURN_VALUES.groupID] == headerID ) then
			LFGCollapseList[dungeonID] = isCollapsed
		end
	end
	for _, dungeonID in pairs(LFDHiddenByCollapseList) do
		if ( LFGGetDungeonInfoByID(dungeonID)[LFG_RETURN_VALUES.groupID] == headerID ) then
			LFGCollapseList[dungeonID] = isCollapsed
		end
	end
	LFDQueueFrame_Update()
end

function LFDFrameMixin:SetSpecificListButtonDungeon(button, dungeonID, mode, submode)
    local info = LFGGetDungeonInfoByID(dungeonID)
    button.id = dungeonID
    if LFGIsIDHeader(dungeonID) then
        local name = info[LFG_RETURN_VALUES.name]

        button.instanceName:SetText(name)
        button.instanceName:SetFontObject(QuestDifficulty_Header)
        button.instanceName:SetPoint("RIGHT", button, "RIGHT", 0, 0)
        button.level:Hide()

        if ( info[LFG_RETURN_VALUES.typeID] == TYPEID_HEROIC_DIFFICULTY ) then
            button.heroicIcon:Show()
            button.instanceName:SetPoint("LEFT", button.heroicIcon, "RIGHT", 0, 1)
        else
            button.heroicIcon:Hide()
            button.instanceName:SetPoint("LEFT", 40, 0)
        end

        button.expandOrCollapseButton:Show()
        local isCollapsed = LFGCollapseList[dungeonID]
        button.isCollapsed = isCollapsed
        if ( isCollapsed ) then
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        else
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        end
    else
        local name =  info[LFG_RETURN_VALUES.name]
        local minLevel, maxLevel = info[LFG_RETURN_VALUES.minLevel], info[LFG_RETURN_VALUES.maxLevel]
        local minRecLevel, maxRecLevel = info[LFG_RETURN_VALUES.minRecLevel], info[LFG_RETURN_VALUES.maxRecLevel]
        local recLevel = info[LFG_RETURN_VALUES.recLevel]

        button.instanceName:SetText(name)
        button.instanceName:SetPoint("RIGHT", button.level, "LEFT", -10, 0)

        button.heroicIcon:Hide()
        button.instanceName:SetPoint("LEFT", 40, 0)

        if minLevel == maxLevel then
            button.level:SetText(format(LFD_LEVEL_FORMAT_SINGLE, minLevel))
        else
            button.level:SetText(format(LFD_LEVEL_FORMAT_RANGE, minLevel, maxLevel))
        end
        button.level:Show()
        local difficultyColor = GetQuestDifficultyColor(recLevel)

        -- @robinsch: LFD dungeon scaling
        if C_LFG:IsScalingDungeon(dungeonID) then
            difficultyColor = GetQuestDifficultyColor(UnitLevel("player"))
        end

        button.level:SetFontObject(difficultyColor.font)

        if ( mode == "rolecheck" or mode == "queued" or mode == "listed" or not LFD_IsEmpowered()) then
            button.instanceName:SetFontObject(QuestDifficulty_Header)
        else
            button.instanceName:SetFontObject(difficultyColor.font)
        end

        button.expandOrCollapseButton:Hide()

        button.isCollapsed = false
    end

    if ( LFGLockList[dungeonID] ) then
        button.enableButton:Hide()
        button.lockedIndicator:Show()
    else
        button.enableButton:Show()
        button.lockedIndicator:Hide()
    end

    local enableState= LFGEnabledList
    if ( mode == "queued" or mode == "listed" ) then
        enableState = LFGQueuedForList[dungeonID]
    else
        enableState = LFGEnabledList[dungeonID]
    end

    if enableState == 1 then	--Some are checked, some aren't.
        button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Up")
        button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-MultiCheck-Disabled")
    else
        button.enableButton:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        button.enableButton:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    end
    button.enableButton:SetChecked(enableState and enableState ~= 0)

    if ( mode == "rolecheck" or mode == "queued" or mode == "listed" or not LFD_IsEmpowered() ) then
        button.enableButton:Disable()
    else
        button.enableButton:Enable()
    end
end

function LFDFrameMixin:GetSelectedDungeons()
	if self.type ~= "specific" then
		return tostring(self.type)
	end

	local dungeons = ""

	for _, queueId in pairs(LFDDungeonList) do
		if not LFGIsIDHeader(queueId) and LFGEnabledList[queueId] and not LFGLockList[queueId] then
			if dungeons == "" then
				dungeons = dungeons .. queueId
			else
				dungeons = dungeons .. " " .. queueId
			end
		end
	end

	for _, queueId in pairs(LFDHiddenByCollapseList) do
		if not LFGIsIDHeader(queueId) and LFGEnabledList[queueId] and not LFGLockList[queueId] then
			if dungeons == "" then
				dungeons = dungeons .. queueId
			else
				dungeons = dungeons .. " " .. queueId
			end
		end
	end

	return dungeons
end

function LFDFrameMixin:Join()
    if self.type == "specific" then
		ClearAllLFGDungeons()
		for _, queueID in pairs(LFDDungeonList) do
			LFDQueueFrame_QueueForInstanceIfEnabled(queueID)
		end
		for _, queueID in pairs(LFDHiddenByCollapseList) do
			LFDQueueFrame_QueueForInstanceIfEnabled(queueID)
		end
	else
		ClearAllLFGDungeons()
		SetLFGDungeon(self.type)
	end

	-- "Random Classic Dungeon" (258) 15-59 is buggy, so secretly just queue for every available dungeon
	if self.type == 258 and C_Player:GetLevel() < 60 then
		LFDQueueFrame_Update()
		LFGDungeonList_Setup()
		for _, dungeonID in pairs(LFDDungeonList) do
			if LFGIsIDHeader(dungeonID) then
				self:SetHeaderEnabled(dungeonID, true)
			else
				self:SetDungeonEnabled(dungeonID, true)
			end
			ClearAllLFGDungeons()
			for _, queueID in pairs(LFDDungeonList) do
				LFDQueueFrame_QueueForInstanceIfEnabled(queueID)
			end
			for _, queueID in pairs(LFDHiddenByCollapseList) do
				LFDQueueFrame_QueueForInstanceIfEnabled(queueID)
			end
		end
	end

	JoinLFG()
end

function LFDFrameMixin:UpdateQueueButton()
    local mode, subMode = GetLFGMode()
	if mode == "queued" or mode == "rolecheck" or mode == "proposal" then
		-- Path to Ascension: Dungeon Finder
		C_Quest:SendPathToAscensionEvent("ACTION_FIND_GROUP_FOR_DUNGEON_FINDER")
		self.QueueButton:SetText(LEAVE_QUEUE)
	else
		if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then
			self.QueueButton:SetText(JOIN_AS_PARTY)
		else
			self.QueueButton:SetText(FIND_A_GROUP)
		end
	end

	if LFD_IsEmpowered() and mode ~= "proposal" and mode ~= "listed" then --During the proposal, they must use the proposal buttons to leave the queue.
		if mode == "queued" or mode =="proposal" or mode == "rolecheck" or not self.Backfill:IsVisible() then
			self.QueueButton:Enable()
		else
			self.QueueButton:Disable()
		end
		self.NoLFDWhileLFR.LeaveQueue:Enable()
	else
		self.QueueButton:Disable()
		self.NoLFDWhileLFR.LeaveQueue:Disable()
	end

	if LFD_IsEmpowered() and mode ~= "proposal" and mode ~= "queued" then
		self.Backfill.StartButton:Enable()
	else
		self.Backfill.StartButton:Disable()
	end
end

function LFDFrameMixin:UpdateBackfill(forceUpdate)
    if CanPartyLFGBackfill() then
		self.Backfill.Description:SetFormattedText(LFG_OFFER_CONTINUE, HIGHLIGHT_FONT_COLOR_CODE.."Dungeon".."|r")
		local mode = GetLFGMode()
		if (forceUpdate or not self:IsVisible()) and mode ~= "queued" then
			self.Backfill:Show()
		end
	else
		self.Backfill:Hide()
	end
end

function LFDFrameMixin:SetRoles(role)
	if (role) then -- TODO: Remove when lfg is fixed. Atm it breaks if you have 2+ roles selected.
		for _, btn in pairs({self.Tank.checkButton, self.Healer.checkButton, self.Dps.checkButton}) do
			btn:SetChecked(role == btn:GetParent().role)
		end
	end

	HelpTip:Hide("LFD_ROLE_SELECT_HELP")

    SetLFGRoles(self.Leader.checkButton:GetChecked(),
                self.Tank.checkButton:GetChecked(),
                self.Healer.checkButton:GetChecked(),
                self.Dps.checkButton:GetChecked())
end

-- TODO: Remove when lfg is fixed. Atm it breaks if you have 2+ roles selected.
function HackFixLFDPopupQueue(button)
	if (button) then
		for _, btn in pairs({_G["LFDRoleCheckPopupRoleButtonTank"].checkButton, _G["LFDRoleCheckPopupRoleButtonHealer"].checkButton, _G["LFDRoleCheckPopupRoleButtonDPS"].checkButton}) do
			btn:SetChecked(btn == button)
		end
	end
end

_G["LFDRoleCheckPopupRoleButtonTank"].checkButton.onClick = HackFixLFDPopupQueue
_G["LFDRoleCheckPopupRoleButtonHealer"].checkButton.onClick = HackFixLFDPopupQueue
_G["LFDRoleCheckPopupRoleButtonDPS"].checkButton.onClick = HackFixLFDPopupQueue

function LFDFrameMixin:Update()
    LFDQueueFrame_Update()
end

-- Events
function LFDFrameMixin:LFG_PROPOSAL_UPDATE()
    LFDDungeonReadyPopup_Update()
end

function LFDFrameMixin:LFG_PROPOSAL_SHOW()
    LFDDungeonReadyPopup.closeIn = nil
    LFDDungeonReadyPopup:SetScript("OnUpdate", nil)
    LFDDungeonReadyStatus_ResetReadyStates()
    LFGDebug("Proposal Shown: LFDFrameMixin:LFG_PROPOSAL_SHOW");
    StaticPopupSpecial_Show(LFDDungeonReadyPopup)
    LFDSearchStatus:Hide()
    PlaySound("ReadyCheck")
end

function LFDFrameMixin:LFG_PROPOSAL_FAILED()
    LFDDungeonReadyPopup_OnFail()
end

function LFDFrameMixin:LFG_PROPOSAL_SUCCEEDED()
    StaticPopupSpecial_Hide(LFDDungeonReadyPopup)
end

function LFDFrameMixin:LFG_ROLE_CHECK_SHOW()
    StaticPopupSpecial_Show(LFDRoleCheckPopup)
    self:UpdateSpecific()
end

function LFDFrameMixin:LFG_ROLE_CHECK_HIDE()
    StaticPopupSpecial_Hide(LFDRoleCheckPopup)
    self:UpdateSpecific()
end

function LFDFrameMixin:LFG_BOOT_PROPOSAL_UPDATE()
    local voteInProgress, didVote, _, targetName, _, _, _, reason = GetLFGBootProposal()
    if voteInProgress and not didVote and targetName then
        StaticPopup_Show("VOTE_BOOT_PLAYER", targetName, reason)
    else
        StaticPopup_Hide("VOTE_BOOT_PLAYER")
    end
end

function LFDFrameMixin:VOTE_KICK_REASON_NEEDED(targetName)
    StaticPopup_Show("VOTE_BOOT_REASON_REQUIRED", targetName, nil, targetName)
end

function LFDFrameMixin:LFG_ROLE_UPDATE()
    LFG_UpdateRoleCheckboxes()
	if self.type ~= "specific" then
		self:UpdateRandom()
	end
end

function LFDFrameMixin:LFG_UPDATE_RANDOM_INFO()
    if not self.type or (type(self.type) == "number" and not IsLFGDungeonJoinable(self.type)) then
        self.type = GetRandomDungeonBestChoice()
		if not C_LFG:IsRandomDungeonDisplayable(self.type) or not C_LFG:CanUseRandomLFD(self.type) then
			self.type = nil
			for i=1 , GetNumRandomDungeons() do
				local id = GetLFGRandomDungeonInfo(i)
				if C_LFG:IsRandomDungeonDisplayable(id) and C_LFG:CanUseRandomLFD(id) and IsLFGDungeonJoinable(id) then
					self.type = id
				end
			end
		end
    end
    --If we still don't have a value, we should go to specific or go to 258 (random classic) if level between 15 and 59
	-- need to check for specific here because leveling from < 15 to >=15 will already be set to specific
    if not self.type or self.type == "specific" then
		local level = C_Player:GetLevel()
		if not C_Player:IsMaxLevel() and level >= 15 and not C_AccountInfo.IsGM() then
			local expansion = GetExpansionLevel()
			if expansion == Enum.Expansion.WoTLK and IsLFGDungeonJoinable(465) then
				self:SetType(465) -- random wotlk
			elseif expansion == Enum.Expansion.TBC and IsLFGDungeonJoinable(417) then
				self:SetType(417) -- random tbc
			elseif expansion == Enum.Expansion.Vanilla and IsLFGDungeonJoinable(258) then
				self:SetType(258) -- random classic
			elseif self.type ~= "specific" then
				self:SetType("specific") -- back to specific if nothing is joinable
			end
		elseif self.type ~= "specific" then
			self:SetType("specific")
		end
    elseif self.Random:IsShown() then
        self:UpdateRandom()
    end
	UIDropDownMenu_SetSelectedValue(self.Dropdown, self.type)
end

function LFDFrameMixin:LFG_OPEN_FROM_GOSSIP(dungeonID)
    self.fromGossip = true
    AscensionLFGFrame:ShowFrame("AscensionPVEFrame", 1)
    LFDQueueFrame_SetType(dungeonID)
end

function LFDFrameMixin:GOSSIP_CLOSED()
    if self.fromGossip then
        HideUIPanel(AscensionLFGFrame)
    end
end

function LFDFrameMixin:CHAT_MSG_SYSTEM(message)
	if message:find("LFG System: You have been removed from the queue") then
		self.QueueReset = true
		Timer.After(5, function() self.QueueReset = nil end)
	elseif message:find(ERR_LFG_LEFT_QUEUE) and self.QueueReset then
		self.QueueReset = nil
		Timer.After(0.5, function()
			self:Join()
			SendSystemMessage("LFG System: You have been automatically re-queued for the Dungeon Finder")
		end)
	end
end

--
-- LFD Leave Mixin
--
LFDLeaveMixin = {}

function LFDLeaveMixin:OnLoad()
	C_Hook:Register(self, "LFG_COMPLETION_REWARD, PLAYER_ENTERING_WORLD")
	self:RegisterForDrag("LeftButton")
	
	self.Background:SetTexture("Interface\\LFGFRAME\\UI-LFG-BACKGROUND-RANDOMDUNGEON")
	self.Background:SetVertexColor(0.75, 0.75, 0.75, 1)
	self.Text:SetText(DUNGEON_COMPLETED)
	self.LeaveButton:SetText(LEAVE_DUNGEON)
end

function LFDLeaveMixin:LFG_COMPLETION_REWARD()
	self:Show()
end

function LFDLeaveMixin:PLAYER_ENTERING_WORLD()
	if self.Hide then -- ?? happens before this is set for some unknown reason.
		self:Hide()
		StaticPopup_Hide("LEAVE_DUNGEON_CONFIRM")
	end
end

function LFDLeaveMixin:OnClick()
	StaticPopup_Show("LEAVE_DUNGEON_CONFIRM")
	self:Hide()
end

function LFDLeaveMixin:OnUpdate()
	if not C_Instance.IsInDungeon() then
		self:Hide()
		StaticPopup_Hide("LEAVE_DUNGEON_CONFIRM")
	end
end
--
-- Help Plates
--
HelpPlate["PVE_FRAME"] = {
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.HelpPlate_PvEFrame,
	MainTip = "PVE_FRAME_MAIN",
	{
		helpTip = "LFG_FRAME_CATEGORY",
		parent  = "AscensionLFGFrame",
		points = {
			{ "TOPLEFT", "AscensionLFGFrameMenu", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionLFGFrameMenu", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "LFG_FRAME_TABS",
		parent  = "AscensionLFGFrame",
		points = {
			{ "TOPLEFT", "AscensionLFGFrameTab1", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionLFGFrameTab2", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "TOP" }
	},
	{
		helpTip = "PVE_FRAME_ROLES",
		parent  = "AscensionPVEFrame",
		points = {
			{ "TOPLEFT", "AscensionPVEFrameLFDFrameRoleBG", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVEFrameLFDFrameRoleBG", "BOTTOMRIGHT", -186, 42 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "PVE_FRAME_DUNGEON",
		parent  = "AscensionPVEFrame",
		points = {
			{ "TOPLEFT", "AscensionPVEFrameLFDFrameDungeonBG", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVEFrameLFDFrameDungeonBG", "BOTTOMRIGHT", -186, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "PVE_FRAME_DROPDOWN",
		parent  = "AscensionPVEFrame",
		points = {
			{ "TOPLEFT", "AscensionPVEFrameLFDFrameTypeDropDown", "TOPLEFT", 18, -4 },
			{ "BOTTOMRIGHT", "AscensionPVEFrameLFDFrameTypeDropDown", "BOTTOMRIGHT", -18, 4 },
		},
		flyoutPoint = { "RIGHT" }
	},
	{
		helpTip = "PVE_FRAME_QUEUE_BUTTONS",
		parent  = "AscensionPVEFrame",
		points = {
			{ "TOPLEFT", "AscensionPVEFrameLFDFrameFindGroupButton", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVEFrameLFDFrameFindGroupButton", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
}

HelpTips["PVE_FRAME_MAIN"] = {
	text = HELP_PLATE_PVE_FRAME_MAIN,
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["PVE_FRAME_ROLES"] = {
	text = HELP_PLATE_PVE_FRAME_ROLES,
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["PVE_FRAME_DUNGEON"] = {
	text = HELP_PLATE_PVE_FRAME_DUNGEON,
	targetPoint = HelpTip.Point.TopEdgeCenter,
}

HelpTips["PVE_FRAME_DROPDOWN"] = {
	text = HELP_PLATE_PVE_FRAME_DROPDOWN,
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["PVE_FRAME_QUEUE_BUTTONS"] = {
	text = HELP_PLATE_PVE_FRAME_QUEUE_BUTTONS,
	targetPoint = HelpTip.Point.TopEdgeCenter,
}

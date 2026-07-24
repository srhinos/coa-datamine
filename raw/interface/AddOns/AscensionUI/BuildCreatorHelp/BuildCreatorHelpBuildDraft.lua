if not C_Realm.IsLive() and not C_Realm.IsDevelopment() then
    return
end

local Addon = select(2, ...)

local POPUP_STOP_LEVEL = 10
local PRIMARY_QUEST_NPCS = {
	[658] = true,
	[823] = true,
	[1568] = true,
	[1570] = true,
	[2079] = true,
	[2980] = true,
	[10176] = true,
	[15278] = true,
	[16475] = true,
	[75118] = true,
	[9780012] = true,
}

local PRIMARY_STAT_QUEST_ID = 1903511 -- TODO: to enum? Primary stat quest
-------------------------------------------------------------------------------
--                                   Menu                                    --
-------------------------------------------------------------------------------
local BuildDraftSelectMenu = CreateFrame("FRAME", "BuildDraftSelectMenu", nil, nil)
MixinAndLoad(BuildDraftSelectMenu, SelectionMixin)

BuildDraftSelectMenu.titleFrame:SetPoint("TOP", 0, 0)
BuildDraftSelectMenu.titleFrame:SetSize(524, 85)
--BuildDraftSelectMenu.titleFrame:SetSize(786, 85)
BuildDraftSelectMenu.titleFrame.text:SetText(HOW_DO_YOU_WANT_TO_PLAY)

BuildDraftSelectMenu._CreateSelectionFrame = BuildDraftSelectMenu.CreateSelectionFrame

function BuildDraftSelectMenu:CreateSelectionFrame(...)
    local frame = BuildDraftSelectMenu._CreateSelectionFrame(self, ...)

    frame:SetSize(254, 471)
    frame.BG:SetSize(254, 471)

    frame.textBlock1:SetPoint("TOP", frame.artBorder, "BOTTOM", 0, -16)
    frame.textBlock1.text:Hide()

    frame.textBlock2:ClearAndSetPoint("TOPLEFT", frame.textBlock1.icon, "BOTTOMLEFT", -7.5, -16)
    frame.textBlock2.text:Hide()

    frame.textBlock1:SetHeight(36)
    frame.textBlock2:SetHeight(36)

    return frame
end

BuildDraftSelectMenu:SetScript("OnShow", function(self)
    local totalRewards = 0

    for i = 1, #self.BuildDraft.items do
        local item = self.BuildDraft.items[i]

        if not(item.item.item) then
            if (i == 1) then
                item:SetItem(1297306)
                item.item.title:SetText("")
                totalRewards = totalRewards + 1
            else
                local itemID = C_Config.GetIntConfig("CONFIG_BUILD_DRAFT_REWARD_ITEM"..(i-1))
                if (itemID and itemID > 0) then
                    local itemAmount = C_Config.GetIntConfig("CONFIG_BUILD_DRAFT_REWARD_AMOUNT"..(i-1))

                    item:SetItem(itemID)
                    item.item.title:SetText((itemAmount and itemAmount > 1) and itemAmount or "")
                    totalRewards = totalRewards + 1
                end
            end
        end
    end

    self.BuildDraft.items[1]:SetPoint("BOTTOM", BuildDraftSelectMenu.BuildDraft.button, "TOP", -(22*(totalRewards-1)), 16)
    self.HasBeenSeen = true
    BuildDraftSelectMenu:SetScript("OnShow", nil)
end)
-------------------------------------------------------------------------------
--                                Build Draft                                --
-------------------------------------------------------------------------------
BuildDraftSelectMenu.BuildDraft = BuildDraftSelectMenu:CreateSelectionFrame("BuildDraft")
BuildDraftSelectMenu.BuildDraft:SetScale(1)
BuildDraftSelectMenu.BuildDraft:SetPoint("TOP", BuildDraftSelectMenu.titleFrame, "BOTTOM", 0, -22)

BuildDraftSelectMenu.BuildDraft.titleFrame.text:SetText(BUILDDRAFT_MODE)
BuildDraftSelectMenu.BuildDraft.art:SetTexture("Interface\\draft\\drafttut")
BuildDraftSelectMenu.BuildDraft.button:SetText(OKAY.." |cff00FF00("..RECOMMENDED..")|r")

BuildDraftSelectMenu.BuildDraft.textBlock3 = CreateFrame("FRAME", "$parent.textBlock3", BuildDraftSelectMenu.BuildDraft)
BuildDraftSelectMenu.BuildDraft:IconTextTemplate(BuildDraftSelectMenu.BuildDraft.textBlock3)
BuildDraftSelectMenu.BuildDraft.textBlock3:ClearAndSetPoint("TOPLEFT", BuildDraftSelectMenu.BuildDraft.textBlock2.icon, "BOTTOMLEFT", -7.5, -16)
BuildDraftSelectMenu.BuildDraft.textBlock3.text:Hide()
BuildDraftSelectMenu.BuildDraft.textBlock3:SetHeight(36)

BuildDraftSelectMenu.BuildDraft.textBlock1.icon:SetTexture("Interface\\icons\\inv_inscription_tarot_6ohealerdeck")
BuildDraftSelectMenu.BuildDraft.textBlock1.label:SetText(DRAFT_FEATURED_BUILD)
BuildDraftSelectMenu.BuildDraft.textBlock1.tooltipTitle = DRAFT_FEATURED_BUILD
BuildDraftSelectMenu.BuildDraft.textBlock1.tooltipText = DRAFT_FEATURED_BUILD_TOOLTIP

BuildDraftSelectMenu.BuildDraft.textBlock2.icon:SetTexture("Interface\\icons\\Inv_Custom_MysticExtract")
BuildDraftSelectMenu.BuildDraft.textBlock2.label:SetText(ENCHANCED_LEVELING)
BuildDraftSelectMenu.BuildDraft.textBlock2.tooltipTitle = ENCHANCED_LEVELING
BuildDraftSelectMenu.BuildDraft.textBlock2.tooltipText = ENCHANCED_LEVELING_TOOLTIP

BuildDraftSelectMenu.BuildDraft.textBlock3.icon:SetTexture("Interface\\icons\\ability_paladin_empoweredsealsrighteous")
BuildDraftSelectMenu.BuildDraft.textBlock3.label:SetText(END_GAME_POWER)
BuildDraftSelectMenu.BuildDraft.textBlock3.tooltipTitle = END_GAME_POWER
BuildDraftSelectMenu.BuildDraft.textBlock3.tooltipText = END_GAME_POWER_TOOLTIP

BuildDraftSelectMenu.BuildDraft.items = {}

BuildDraftSelectMenu.BuildDraft.item1 = Addon.CallBoardUI:CreateReward("item1", BuildDraftSelectMenu.BuildDraft)
table.insert(BuildDraftSelectMenu.BuildDraft.items, BuildDraftSelectMenu.BuildDraft.item1)

BuildDraftSelectMenu.BuildDraft.item2 = Addon.CallBoardUI:CreateReward("item2", BuildDraftSelectMenu.BuildDraft)
BuildDraftSelectMenu.BuildDraft.item2:SetPoint("LEFT", BuildDraftSelectMenu.BuildDraft.item1, "RIGHT", 12, 0)
table.insert(BuildDraftSelectMenu.BuildDraft.items, BuildDraftSelectMenu.BuildDraft.item2)

BuildDraftSelectMenu.BuildDraft.item3 = Addon.CallBoardUI:CreateReward("item3", BuildDraftSelectMenu.BuildDraft)
BuildDraftSelectMenu.BuildDraft.item3:SetPoint("LEFT", BuildDraftSelectMenu.BuildDraft.item2, "RIGHT", 12, 0)
table.insert(BuildDraftSelectMenu.BuildDraft.items, BuildDraftSelectMenu.BuildDraft.item3)

BuildDraftSelectMenu.BuildDraft.item4 = Addon.CallBoardUI:CreateReward("item4", BuildDraftSelectMenu.BuildDraft)
BuildDraftSelectMenu.BuildDraft.item4:SetPoint("LEFT", BuildDraftSelectMenu.BuildDraft.item3, "RIGHT", 12, 0)
table.insert(BuildDraftSelectMenu.BuildDraft.items, BuildDraftSelectMenu.BuildDraft.item4)

BuildDraftSelectMenu.BuildDraft.item5 = Addon.CallBoardUI:CreateReward("item5", BuildDraftSelectMenu.BuildDraft)
BuildDraftSelectMenu.BuildDraft.item5:SetPoint("LEFT", BuildDraftSelectMenu.BuildDraft.item4, "RIGHT", 12, 0)
table.insert(BuildDraftSelectMenu.BuildDraft.items, BuildDraftSelectMenu.BuildDraft.item5)

BuildDraftSelectMenu.BuildDraft.bonusRewards = BuildDraftSelectMenu.BuildDraft:CreateFontString(nil)
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetFontObject(GameFontNormal)
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetPoint("BOTTOM", BuildDraftSelectMenu.BuildDraft.button, "TOP", 0, 64)
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetText(BONUS_REWARDS)
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetJustifyH("CENTER")
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetJustifyV("CENTER")
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetShadowOffset(0,0)
BuildDraftSelectMenu.BuildDraft.bonusRewards:SetVertexColor(0.20, 0.1, 0.0, 1)

BuildDraftSelectMenu.BuildDraft.button:SetScript("OnClick", function(self)
    local activateFunc = function()
        ToggleBuildDraftMode(true)
    end
    BuildDraftSelectMenu:GetParent():FrameFadeOut(0.5) -- hide screen block
    StaticPopup_Show("BUILD_DRAFT_ACTIVATE_CONFIRM", nil, nil, activateFunc)
end)

BuildDraftSelectMenu.BuildDraft:Hide()
-------------------------------------------------------------------------------
--                              Featured Build                               --
-------------------------------------------------------------------------------
BuildDraftSelectMenu.FeaturedBuild = BuildDraftSelectMenu:CreateSelectionFrame("FeaturedBuild")
BuildDraftSelectMenu.FeaturedBuild:SetScale(1)
BuildDraftSelectMenu.FeaturedBuild:SetPoint("TOPLEFT", BuildDraftSelectMenu.titleFrame, "BOTTOMLEFT", 0, -22)

BuildDraftSelectMenu.FeaturedBuild.titleFrame.text:SetText(FEATURED_BUILD)
BuildDraftSelectMenu.FeaturedBuild.button:SetText(OKAY.." |cff00FF00("..RECOMMENDED..")|r")
BuildDraftSelectMenu.FeaturedBuild.art:SetTexture("Interface\\draft\\featuredtut")

BuildDraftSelectMenu.FeaturedBuild.textBlock3 = CreateFrame("FRAME", "$parent.textBlock3", BuildDraftSelectMenu.FeaturedBuild)
BuildDraftSelectMenu.FeaturedBuild:IconTextTemplate(BuildDraftSelectMenu.FeaturedBuild.textBlock3)
BuildDraftSelectMenu.FeaturedBuild.textBlock3:ClearAndSetPoint("TOPLEFT", BuildDraftSelectMenu.FeaturedBuild.textBlock2.icon, "BOTTOMLEFT", -7.5, -16)
BuildDraftSelectMenu.FeaturedBuild.textBlock3.text:Hide()
BuildDraftSelectMenu.FeaturedBuild.textBlock3:SetHeight(36)

BuildDraftSelectMenu.FeaturedBuild.textBlock1.icon:SetTexture("Interface\\icons\\timelesscoin_yellow")
BuildDraftSelectMenu.FeaturedBuild.textBlock1.label:SetText(PICK_ANY_FEATURED_BUILD)
BuildDraftSelectMenu.FeaturedBuild.textBlock1.tooltipTitle = PICK_ANY_FEATURED_BUILD
BuildDraftSelectMenu.FeaturedBuild.textBlock1.tooltipText = PICK_ANY_FEATURED_BUILD_TOOLTIP

BuildDraftSelectMenu.FeaturedBuild.textBlock2.icon:SetTexture("Interface\\icons\\Inv_Custom_MysticExtract")
BuildDraftSelectMenu.FeaturedBuild.textBlock2.label:SetText(ENCHANCED_LEVELING)
BuildDraftSelectMenu.FeaturedBuild.textBlock2.tooltipTitle = ENCHANCED_LEVELING
BuildDraftSelectMenu.FeaturedBuild.textBlock2.tooltipText = ENCHANCED_LEVELING_TOOLTIP

BuildDraftSelectMenu.FeaturedBuild.textBlock3.icon:SetTexture("Interface\\icons\\ability_paladin_empoweredsealsrighteous")
BuildDraftSelectMenu.FeaturedBuild.textBlock3.label:SetText(END_GAME_POWER)
BuildDraftSelectMenu.FeaturedBuild.textBlock3.tooltipTitle = END_GAME_POWER
BuildDraftSelectMenu.FeaturedBuild.textBlock3.tooltipText = END_GAME_POWER_TOOLTIP

BuildDraftSelectMenu.FeaturedBuild.button:SetScript("OnClick", function(self)
    BuildDraftSelectMenu:GetParent():FrameFadeOut(0.5)

    if BuildCreatorFrame then -- build creator loads in featured builds by itself, select featured builds if it is already loaded
        Collections:GoToTab(Collections.Tabs.HeroArchitect)
        BuildCreatorFrame:SelectCategory(Enum.BuildCategory.BuildDraft)
    else
        Collections:GoToTab(Collections.Tabs.HeroArchitect)
    end
end)
-------------------------------------------------------------------------------
--                               Create Build                                --
-------------------------------------------------------------------------------
BuildDraftSelectMenu.CreateBuild = BuildDraftSelectMenu:CreateSelectionFrame("CreateBuild")
BuildDraftSelectMenu.CreateBuild:SetScale(1)
BuildDraftSelectMenu.CreateBuild:SetPoint("TOPRIGHT", BuildDraftSelectMenu.titleFrame, "BOTTOMRIGHT", 0, -22)

BuildDraftSelectMenu.CreateBuild.titleFrame.text:SetText("Create Build")
BuildDraftSelectMenu.CreateBuild.button:SetText(OKAY)

BuildDraftSelectMenu.CreateBuild.desc = BuildDraftSelectMenu.CreateBuild:CreateFontString(nil)
BuildDraftSelectMenu.CreateBuild.desc:SetFontObject(GameFontNormal)
BuildDraftSelectMenu.CreateBuild.desc:SetPoint("TOPLEFT", BuildDraftSelectMenu.CreateBuild.artBorder, "BOTTOMLEFT", 0, -8)
BuildDraftSelectMenu.CreateBuild.desc:SetWidth(200)
BuildDraftSelectMenu.CreateBuild.desc:SetText("")
BuildDraftSelectMenu.CreateBuild.desc:SetJustifyH("LEFT")
BuildDraftSelectMenu.CreateBuild.desc:SetJustifyV("TOP")
BuildDraftSelectMenu.CreateBuild.desc:SetShadowOffset(0,0)
BuildDraftSelectMenu.CreateBuild.desc:SetVertexColor(0.10, 0.05, 0.0, 1)
BuildDraftSelectMenu.CreateBuild.desc:SetText(CREATE_BUILD_TOOLTIP)

BuildDraftSelectMenu.CreateBuild.textBlock1:ClearAndSetPoint("TOP", BuildDraftSelectMenu.CreateBuild.desc, "BOTTOM", -7.5, -24)
BuildDraftSelectMenu.CreateBuild.textBlock1.icon:SetTexture("Interface\\icons\\Inv_Custom_MysticExtract")
BuildDraftSelectMenu.CreateBuild.textBlock1.label:SetText("|cffFF0000No Mystic Enchants automatically applied!|r")
BuildDraftSelectMenu.CreateBuild.textBlock1.icon:SetVertexColor(1, 0, 0)
BuildDraftSelectMenu.CreateBuild.textBlock2:Hide()

BuildDraftSelectMenu.CreateBuild.button:SetScript("OnClick", function(self)
    Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
    BuildDraftSelectMenu:GetParent():FrameFadeOut(0.5)
end)
-------------------------------------------------------------------------------
--                            Featured build thing                           --
-------------------------------------------------------------------------------
local HandlerFrame = CreateFrame("FRAME")
HandlerFrame:RegisterEvent("GOSSIP_SHOW")
HandlerFrame:RegisterEvent("QUEST_DETAIL")

local function ScanQuestsForPrimaryStatQuest(questIDs)
    if (questIDs and next(questIDs)) then
        for _, v in pairs(questIDs) do
            if (v == PRIMARY_STAT_QUEST_ID) then
                return true
            end
        end
    end

    return false
end

local function ScanTargetID(ID)
	if ID and PRIMARY_QUEST_NPCS[ID] then
		return true
	end

	return false
end

HandlerFrame:SetScript("OnEvent", function(self, event, arg)
    if BuildDraftSelectMenu and BuildDraftSelectMenu.HasBeenSeen then return end
    if not C_Player:IsHero() then
        return
    end

    if (UnitLevel("player") >= POPUP_STOP_LEVEL) then
        return
    end

    if BuildCreatorUtil.GetActiveBuildID() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.BuildDraft, Enum.GameMode.WildCard, Enum.GameMode.Felforged) then
        return
    end

    local hasPrimaryStatQuest = ScanQuestsForPrimaryStatQuest(GetActiveGossipQuestIds()) or ScanQuestsForPrimaryStatQuest(GetAvailableGossipQuestIds())

    local isPrimaryStatNPC = ScanTargetID(GetCreatureIDFromUnit("NPC"))

    if not(hasPrimaryStatQuest or isPrimaryStatNPC) then
        return
    end

    Timer.AfterCombat(function()
        Timer.After(2, function()
            if BuildCreatorUtil.GetActiveBuildID() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.BuildDraft, Enum.GameMode.WildCard, Enum.GameMode.Felforged) then
                return
            end
            C_PopupQueue:Add(BuildDraftSelectMenu, 
                             function() HideUIPanel(Collections) BuildDraftSelectMenu:GetParent():FrameFadeIn(0.5) BuildDraftSelectMenu:Show() end, 
                             function() return not BuildDraftSelectMenu:IsVisible() end
            )
        end)
    end)
end)
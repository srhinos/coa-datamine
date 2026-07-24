if not C_Realm.IsLive() and not C_Realm.IsDevelopment() then
    return
end

local FORCED_TUTORIAL_LEVEL = 10

local BuildTutorialFrame = CreateFrame("FRAME", "BuildTutorialFrame", nil, "RockFrameTemplate")
MixinAndLoad(BuildTutorialFrame, SelectionMixin)

BuildTutorialFrame.createBuildFrame = BuildTutorialFrame:CreateSelectionFrame("createBuildFrame")
BuildTutorialFrame.createBuildFrame:SetScale(1)
BuildTutorialFrame.createBuildFrame.titleFrame.text:SetText(CREATE_BUILD)
BuildTutorialFrame.createBuildFrame.button:SetScript("OnClick", function(self)
    Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
    BuildTutorialFrame:GetParent():FrameFadeOut(0.5) -- hide screen block
end)
BuildTutorialFrame.createBuildFrame.button:SetText(CREATE_BUILD)

BuildTutorialFrame.chooseBuildFrame = BuildTutorialFrame:CreateSelectionFrame("chooseBuildFrame")
BuildTutorialFrame.chooseBuildFrame:SetScale(1)
BuildTutorialFrame.chooseBuildFrame.titleFrame.text:SetText(CHOOSE_BUILD)
BuildTutorialFrame.chooseBuildFrame.art:SetTexture("Interface\\Addons\\AwAddons\\Textures\\Tutorial\\BCTut")
BuildTutorialFrame.chooseBuildFrame.button:SetScript("OnClick", function(self)
    Collections:GoToTab(Collections.Tabs.HeroArchitect)
    BuildTutorialFrame:GetParent():FrameFadeOut(0.5) -- hide screen block
    if BuildCreatorFrame:GetCurrentCategory() ~= Enum.BuildCategory.BuildDraft then
        BuildCreatorFrame:SelectCategory(Enum.BuildCategory.BuildDraft)
    end
end)
BuildTutorialFrame.chooseBuildFrame.button:SetText(CHOOSE_BUILD)

BuildTutorialFrame.chooseBuildFrame:SetPoint("TOPLEFT", BuildTutorialFrame.titleFrame, "BOTTOMLEFT", 0, -22)
BuildTutorialFrame.createBuildFrame:SetPoint("TOPRIGHT", BuildTutorialFrame.titleFrame, "BOTTOMRIGHT", 0, -22)

BuildTutorialFrame.chooseBuildFrame.textBlock1.icon:SetTexture("Interface\\Icons\\ability_warrior_charge")
BuildTutorialFrame.chooseBuildFrame.textBlock1.label:SetText(EPIC_START)
BuildTutorialFrame.chooseBuildFrame.textBlock1.text:SetText(EPIC_START_DESCRIPTION)

BuildTutorialFrame.chooseBuildFrame.textBlock2:Hide()
--[[BuildTutorialFrame.chooseBuildFrame.textBlock2.icon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball02")
BuildTutorialFrame.chooseBuildFrame.textBlock2.label:SetText(TRY_NEW_BUILDS)
BuildTutorialFrame.chooseBuildFrame.textBlock2.text:SetText(TRY_NEW_BUILDS_DESCRIPTION)]]--

BuildTutorialFrame.createBuildFrame.textBlock1.icon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\misc\\spell_Paladin_divinecircle")
BuildTutorialFrame.createBuildFrame.textBlock1.label:SetText(DECIDE_YOUR_PATH)
BuildTutorialFrame.createBuildFrame.textBlock1.text:SetText(DECIDE_YOUR_PATH_DESCRIPTION)

--BuildTutorialFrame.createBuildFrame.textBlock2.text:SetText(SHARE_BUILDS_DESCRIPTION)
BuildTutorialFrame.createBuildFrame.textBlock2:Hide()

BuildTutorialFrame.illustrationRight = BuildTutorialFrame:CreateTexture(nil, "ARTWORK", nil)
BuildTutorialFrame.illustrationRight:SetPoint("RIGHT", 40, 0)
BuildTutorialFrame.illustrationRight:SetTexture("Interface\\Addons\\AwAddons\\Textures\\girlArt1")
BuildTutorialFrame.illustrationRight:SetSize(512, 512)

BuildTutorialFrame.illustrationRight2 = BuildTutorialFrame:CreateTexture(nil, "ARTWORK", nil)
BuildTutorialFrame.illustrationRight2:SetPoint("LEFT", -160, 0)
BuildTutorialFrame.illustrationRight2:SetTexture("Interface\\Addons\\AwAddons\\Textures\\girlArt2")
BuildTutorialFrame.illustrationRight2:SetSize(512, 512)

BuildTutorialFrame:SetScript("OnShow", function(self)
    self.HasBeenSeen = true
    self:SetScript("OnShow", nil)
end)

local HandlerFrame = CreateFrame("FRAME")
HandlerFrame:RegisterEvent("PLAYER_LEVEL_UP")

--[[HandlerFrame:SetScript("OnEvent", function(self, event, arg)
    if BuildTutorialFrame and BuildTutorialFrame.HasBeenSeen then return end
    if (arg ~= FORCED_TUTORIAL_LEVEL) then
        return
    end

    if not C_Player:IsHero() then
        return
    end

    if BuildCreatorUtil.GetActiveBuildID() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.BuildDraft, Enum.GameMode.WildCard, Enum.GameMode.Felforged) then
        return
    end

    Timer.AfterCombat(function()
        Timer.After(2, function()
            if BuildCreatorUtil.GetActiveBuildID() or C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.BuildDraft, Enum.GameMode.WildCard, Enum.GameMode.Felforged) then
                return
            end
            C_PopupQueue:Add(BuildTutorialFrame, 
                             function() HideUIPanel(Collections) BuildTutorialFrame:GetParent():FrameFadeIn(0.5) BuildTutorialFrame:Show() end, 
                             function() return not BuildTutorialFrame:IsVisible() and (not BuildCreatorFrame or not BuildCreatorFrame:IsVisible()) end
            )
        end)
    end)
end)]]--

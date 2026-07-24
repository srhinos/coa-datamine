-------------------------------------------------------------------------------
--                               Button Mixin                                --
-------------------------------------------------------------------------------
ForcedPrimaryStatButtonMixin = CreateFromMixins(CAPrimaryStatButtonMixin)

function ForcedPrimaryStatButtonMixin:OnLoad()
    CAPrimaryStatButtonMixin.OnLoad(self)
    self:Layout()

    self.Suggested:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Suggested", 1, 1, 1)
        GameTooltip:AddLine("This stat should fit your build well!")

        GameTooltip:Show()
    end)

    self.Suggested:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

function ForcedPrimaryStatButtonMixin:SetStat(statID)
    self.statID = statID

    self:SetEntry(C_CharacterAdvancement.GetEntryByInternalID(C_PrimaryStat:GetInternalID(statID)))
    self:GetFontString():SetPoint("BOTTOM", 0, -4)
    self.NameShadow:ClearAndSetPoint("CENTER", self:GetFontString(), 0, 0)
end

function ForcedPrimaryStatButtonMixin:GetStatID()
    return self.statID
end

function ForcedPrimaryStatButtonMixin:SetEntry(entry, statID)
    CASpellButtonBaseMixin.SetEntry(self, entry) -- calls self:SetText()

    -- SetQuality in SetCharacterAdvancementEntry overwrites border/overlay with quickslot atlas, restore ours
    self.Icon:SetBorderAtlas("talents-node-circle-gray")
    self.Icon:SetOverlayAtlas("talents-node-circle-gray")

    -- override text with stat name, not spell name
    local _, _, _, statName = C_PrimaryStat:GetPrimaryStatInfo(self:GetStatID())

    if statName and (statName ~= "") then
        self:SetText(statName)
    end
end

function ForcedPrimaryStatButtonMixin:Layout()
    self:SetSize(48, 48)
    self:SetNormalTexture("")
    self.Icon:SetNormalTexture("")
    self.Icon:SetPushedTexture("")
    self.Icon:SetBorderAtlas("talents-node-circle-gray")
    self.Icon:SetOverlayAtlas("talents-node-circle-gray")
    self.Icon:SetBorderSize(48, 48)
    self.Icon:SetOverlaySize(48, 48)
    self.Icon.KnownGlow:SetSize(48, 48)
    self.Icon.KnownGlow:SetAtlas("talents-node-circle-yellow")
    self.Icon.KnownGlow:SetBlendMode("BLEND")
    self.Icon:SetSize(46, 46)
    self.Icon:SetRounded(true)

    self.Icon:SetFrameLevel(self:GetFrameLevel()-1)

    self:SetNormalFontObject(GameFontNormal)
    self:SetHighlightFontObject(GameFontHighlight)
    self:SetPushedTextOffset(1, -1)
end

-------------------------------------------------------------------------------
--                               Frame Mixin                                 --
-------------------------------------------------------------------------------
ForcedPrimaryStatMixin = {}

local FORCED_PRIMARY_STAT_DISPLAY_ORDER = {
    Enum.PrimaryStat.Strength,
    Enum.PrimaryStat.Agility,
    Enum.PrimaryStat.Duality,
    Enum.PrimaryStat.Intellect,
    Enum.PrimaryStat.Spirit,
}

local function GetForcedPrimaryStatDisplayOrder(availableStats)
    local orderedStats = {}

    for _, statID in ipairs(FORCED_PRIMARY_STAT_DISPLAY_ORDER) do
        if not availableStats or availableStats[statID] then
            table.insert(orderedStats, statID)
        end
    end

    return orderedStats
end

function ForcedPrimaryStatMixin:OnLoad()
    local canChoosePrimaryStat = C_Player:IsHero()

    self.statPool = CreateFramePool("Button", self, "ForcedPrimaryStatButtonTemplate")
end

function ForcedPrimaryStatMixin:CheckSuggestions()
    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft) or C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        return
    end

    local topStat, topStats = C_CharacterAdvancement.GetSuggestedStats()

    if not topStat then
        return
    end

    local topStatEntry = Enum.PrimaryStat[topStat]
    local topStatsEntries = {}

    for _, stat in pairs(topStats) do
        local statID = Enum.PrimaryStat[stat]
        if statID then
            topStatsEntries[statID] = true
        end
    end

    self.statPool:ReleaseAll()

    local lastButton
    local orderedStats = GetForcedPrimaryStatDisplayOrder(topStatsEntries)

    for index, statID in ipairs(orderedStats) do
        local button = self.statPool:Acquire()

        if index == 1 then
            button:ClearAndSetPoint("CENTER", -75*((#orderedStats)-1), 16)
        else
            button:SetPoint("LEFT", lastButton, "RIGHT", 62, 0)
        end

        if statID == topStatEntry then
            button.Suggested:Show()
        else
            button.Suggested:Hide()
        end

        button:SetStat(statID)
        button:Show()

        lastButton = button
    end
end

function ForcedPrimaryStatMixin:OnPrimaryStatSelected(skipTip)
    ForcedPrimaryStatEventHandler:HookEvent("ASCENSION_KNOWN_ENTRY_UPDATED")
    
    BaseFrameFadeOut(self)

    if skipTip then
        return
    end

    -- TODO: Replace with tutorial?
    if not HelpTips["FORCED_PRIMARY_STAT_TIP"].acknowledged then
       HelpTip:Show("FORCED_PRIMARY_STAT_TIP")
       HelpTips["FORCED_PRIMARY_STAT_TIP"].acknowledged = true
   end
end

function ForcedPrimaryStatMixin:OnShow()
    if WildCard and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        WildCard:HideDicesIfIdle()
    end

    self.statPool:ReleaseAll()
    
    local lastButton
    local step = 0

    if self.crossLayout then
        self.BG2:Show()
        self.BG3:Show()
        self.BG4:Show()
        self:SetHeight(256)
        self.HintText:SetFontObject(GameFontHighlight)
        self.HintText:ClearAndSetPoint("BOTTOM", self, "CENTER", 0, 38)
        self:EnableMouse(true)
    else
        self.BG2:Hide()
        self.BG3:Hide()
        self.BG4:Hide()
        self:SetHeight(96)
        self.HintText:SetFontObject(GameFontHighlightMedium)
        self.HintText:ClearAndSetPoint("BOTTOM", 0, 4)
        self:EnableMouse(false)
    end

    for _, statID in ipairs(GetForcedPrimaryStatDisplayOrder()) do
        local button, isNew = self.statPool:Acquire()

        if isNew then
            button:HookScript("OnClick", GenerateClosure(self.OnPrimaryStatSelected, self))
        end

        if self.crossLayout then
            if statID == 6 then
                button:ClearAndSetPoint("CENTER", 0, 0)
            else
                button:ClearAndSetPoint("CENTER", 96*math.cos(step), 96*math.sin(step))
                step = step + (math.pi/2)
            end
        else
            if not lastButton then
                button:ClearAndSetPoint("CENTER", -169, 16)
            else
                button:SetPoint("LEFT", lastButton, "RIGHT", 42, 0)
            end
        end

        --button:SetParent(self:GetParent())
        button:SetFrameLevel(self:GetFrameLevel()+9)
        button:SetStat(statID)
        button.Suggested:Hide()
        button:Show()

        lastButton = button
    end

    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function ForcedPrimaryStatMixin:OnHide()
    if WildCard and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        WildCard:CheckForRolls()
    end

    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

function ForcedPrimaryStatMixin:GLOBAL_MOUSE_DOWN()
    if FrameUtil.IsDialogStyleGlobalMouseDown(self) then
        self:OnPrimaryStatSelected()
    end
end
-------------------------------------------------------------------------------
--                              Event Handler                                --
-------------------------------------------------------------------------------
ForcedPrimaryStatEventHandler = CreateFrame("FRAME")

function ForcedPrimaryStatEventHandler:ASCENSION_KNOWN_ENTRY_UPDATED(internalID)
    for _, statInternalID in pairs(C_PrimaryStat.internalIds) do
        if (internalID == statInternalID) then
            CharacterAdvancement:RefreshPrimaryStats()
            self:UnhookEvent("ASCENSION_KNOWN_ENTRY_UPDATED")
            return
        end
    end
end

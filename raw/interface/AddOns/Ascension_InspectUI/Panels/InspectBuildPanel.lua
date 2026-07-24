InspectBuildPanelMixin = {}
InspectBuildPanelMixin.OnEvent = OnEventToMethod

function InspectBuildPanelMixin:OnLoad()
    self.Background:SetAtlas("ca-background-browser", Const.TextureKit.IgnoreAtlasSize)
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + 20)
    self.SpellPool = CreateFramePool("Button", self.BuildScroll.Child, "InspectBuildSpellTemplate")
    self.TalentPool = CreateFramePool("Button", self.TalentScroll.Child, "InspectBuildTalentTemplate")

    self.Specs:SetTemplate("InspectBuildSpecTemplate")
	self.Specs:SetGetNumResultsFunction(function()
        local _, unlockedSpecs = C_CharacterAdvancement.GetInspectInfo(AscensionInspectFrame:GetUnit())
        return unlockedSpecs and #unlockedSpecs or 0
    end)

    self.Specs:SetSelectionCallback(function(index)
        self.selectedSpec = index
        self:Update()
    end)

    self.Specs:SetSelectedHighlightAtlas("pvpqueue-button-casual-selected")
    self.Specs:SetSelectedHighlightBlendMode("ADD")

    MixinAndLoadScripts(self.TalentScroll, "TabSystemMixin")
    self.TalentScroll:SetTabTemplate("SpellBookTabTopTemplate")
    self.TalentScroll:SetTabPoint("BOTTOMLEFT", self.TalentScroll, "TOPLEFT", 0, -4)
    self.TalentScroll:SetTabWidthConstraints(124, 124)
    self.TalentScroll:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB)
    self.TalentScroll:SetTabPadding(2, 0)

    local tab
    for i = 1, 3 do
        tab = self.TalentScroll:AddTab("Tab"..i)
        tab:SetFrameLevel(self.TalentScroll.Inset:GetFrameLevel()+2)
        tab:SetTextPadding(10)
    end
    
    self.TalentScroll:RegisterCallback("OnTabSelected", self.UpdateDefaultClass, self)
end

function InspectBuildPanelMixin:OnShow()
    self:RegisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT")

    C_CharacterAdvancement.InspectUnit(AscensionInspectFrame:GetUnit())
end

function InspectBuildPanelMixin:OnHide()
    self:UnregisterEvent("INSPECT_CHARACTER_ADVANCEMENT_RESULT")
    self.selectedSpec = nil
end

function InspectBuildPanelMixin:INSPECT_CHARACTER_ADVANCEMENT_RESULT(result)
    if result == "CA_INSPECT_OK" then
        self.selectedSpec = nil
        local activeSpec = C_CharacterAdvancement.GetInspectInfo(AscensionInspectFrame:GetUnit()) or 1
        self.Specs:SetSelectedIndex(activeSpec, ScrollListMixin.UpdateType.AlwaysSimulateClick)
    else
        self.ErrorFrame:SetText(BUILD_INSPECT_FAILED, _G[result] or result)
        self.ErrorFrame:Show()
    end

    self.Specs:RefreshScrollFrame()
end

function InspectBuildPanelMixin:UpdateHero(unit)
    self.SpellPool:ReleaseAll()
    self.TalentScroll:Hide()
    self.BuildScroll:Show()
    local entries = C_CharacterAdvancement.GetInspectedBuild(unit, self.activeSpec)
    if not entries then
        return
    end

    local lastEntry = nil
    local height = 0
    for i, entry in ipairs(entries) do
        local spell = self.SpellPool:Acquire()
        if lastEntry then
            spell:SetPoint("TOPLEFT", lastEntry, "BOTTOMLEFT", 0, 0)
        else
            spell:SetPoint("TOPLEFT", self.BuildScroll.Child, "TOPLEFT", 0, -2)
        end
        local alpha = i % 2 == 0 and 0.1 or 0.15
        spell:GetNormalTexture():SetTexture(0, 0, 0, alpha)
        spell:SetEntry(entry.EntryId, entry.Rank)
        spell:Show()

        lastEntry = spell
        height = height + spell:GetHeight()
    end

    self.BuildScroll.Child:SetHeight(height)
end

function InspectBuildPanelMixin:UpdateDefaultClass()
    self.BuildScroll:Hide()
    self.TalentScroll:Show()
    self.TalentPool:ReleaseAll()
    
    local unit = AscensionInspectFrame:GetUnit()
    
    local class = select(2, UnitClass(unit))

    for tabID = 1, 3 do
        local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[class][tabID]
        local classInfo = C_ClassInfo.GetSpecInfo(class, spec)
        self.TalentScroll:UpdateTabText(tabID, classInfo.Name)
    end

    local currentTab = self.TalentScroll:GetCurrentTabID()
    local currentSpec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[class][currentTab]
    
    self.TalentScroll.Background:SetAtlas(format("default-talent-%s-%s", class, currentSpec))
    
    local dbcClass = CharacterAdvancementUtil.GetClassDBCByFile(class)
    local dbcSpec = CharacterAdvancementUtil.GetSpecDBCByFile(currentSpec)

    local column, row, x, y
    local height = 12
    for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(dbcClass, dbcSpec, true)) do
        local talent = self.TalentPool:Acquire()
        column = entry.Column - 1
        row = entry.Row
        x = -108 + column * 68
        y = 22 + row * 44
        talent:SetPoint("TOP", self.TalentScroll.Child, "TOP", x, -y)
        talent:SetEntry(entry, unit, self.activeSpec)
        talent:Show()
        height = math.max(height, y + 44)
    end
    
    self.TalentScroll.Child:SetHeight(height)
end

function InspectBuildPanelMixin:GetBestTabForUnit(unit)
    local class = select(2, UnitClass(unit))
    local mostInvested, bestTab = 0, 1
    for tabID = 1, 3 do
        local spec = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[class][tabID]
        local dbcClass = CharacterAdvancementUtil.GetClassDBCByFile(class)
        local dbcSpec = CharacterAdvancementUtil.GetSpecDBCByFile(spec)
        
        local invested = 0
        for i, entry in ipairs(C_CharacterAdvancement.GetTalentsByClass(dbcClass, dbcSpec, true)) do
            if C_CharacterAdvancement.UnitKnownID(unit, entry.ID, self.activeSpec) then
                local teInvested = 0
                local currentRank = C_CharacterAdvancement.UnitTalentRankByID(unit, entry.ID, self.activeSpec)

                if currentRank then
                    local teCost = entry.TECost
                    teInvested = teInvested + (teCost * currentRank)
                else
                    local teCost = entry.TECost
                    teInvested = teInvested + teCost
                end
                invested = invested + teInvested
            end
        end

        if invested > mostInvested then
            mostInvested = invested
            bestTab = tabID
        end
    end
    
    return bestTab
end

function InspectBuildPanelMixin:Update()
    local unit = AscensionInspectFrame:GetUnit()
    local activeSpec = C_CharacterAdvancement.GetInspectInfo(unit)
    if not activeSpec then
        return
    end

    self.activeSpec = self.selectedSpec or activeSpec or 1

    if IsDefaultClass(unit) then
        self.TalentScroll.ScrollBar:SetValue(0)
        local bestTab = self:GetBestTabForUnit(unit)
        self.TalentScroll:SelectTabID(bestTab or 1)
    else
        self:UpdateHero(unit)
        self.BuildScroll.ScrollBar:SetValue(0)
    end 
end

-- 
-- Inspect Build Spell Mixin
-- 
InspectBuildSpellMixin = {}

function InspectBuildSpellMixin:OnLoad()
    self.Icon:SetOverlayBlendMode("ADD")
    self.Icon:SetBorderSize(32, 32)
    self.Icon:SetOverlaySize(32, 32)

    self:SetHighlightAtlas("options_list_hover")

    self.Class:SetRounded(true)
    self.Class:SetBorderAtlas("inspect-class-ring")
    self.Class:SetBorderSize(22, 22)
    self.Class:SetOverlayAtlas("inspect-class-ring")
    self.Class:SetOverlaySize(22, 22)
    self.Class:SetOverlayBlendMode("ADD")
end

function InspectBuildSpellMixin:SetEntry(entryID, rank)
    self.entryID = entryID
    local entry = C_CharacterAdvancement.GetEntryByInternalID(entryID)
    if not entry then
        self:SetText("")
        self.Icon:SetSpell(nil)
        return
    end

    local spellID = entry.Spells[rank]
    self.spellID = spellID
    local spellName = GetSpellInfo(spellID)

    local quality, qualityCount = C_CharacterAdvancement.GetQualityInfo(spellID)

    
    self.Icon:SetSpell(spellID)
    self:SetText(spellName)
    self.Text:FitToWidth(12, 234)

    if C_CharacterAdvancement.IsTalentID(entryID) then
        local _, maxRank = C_CharacterAdvancement.GetTalentRankByID(entryID)
        self.Icon.RankFrame:Show()
        self.Icon.RankFrame:SetRank(rank)
        self.Icon.RankFrame:SetMaxRank(maxRank)
        self.Icon.RankFrame:UpdateVisual()
        quality = rank
    else
        self.Icon.RankFrame:Hide()
    end

    if quality then
        self.Icon:SetBorderAtlas(QUICKSLOT_QUALITY_BORDER_ATLAS[quality])
        self.Icon:SetOverlayAtlas(QUICKSLOT_QUALITY_BORDER_ATLAS[quality])
    else
        self.Icon:SetBorderTexture("")
        self.Icon:SetOverlayTexture("")
    end

    local class = CharacterAdvancementUtil.GetClassFileForEntry(entry)
    self:SetClass(class)
end

function InspectBuildSpellMixin:SetClass(class)
    if class and RAID_CLASS_COLORS[class] then
        self.Class:SetIconAtlas("class-round-" .. class)
        local r, g, b, a = RAID_CLASS_COLORS[class]:GetRGBA()
        self.Class:SetBorderColor(r, g, b, a)
        self.Class:SetOverlayColor(r, g, b, 0.5)
        self.Class:Show()
    else
        self.Class:Hide()
    end
end

function InspectBuildSpellMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()
end

function InspectBuildSpellMixin:OnLeave()
    GameTooltip:Hide()
end

function InspectBuildSpellMixin:OnClick()
    if IsModifiedClick("CHATLINK") then
        local chatLink = LinkUtil:GetSpellLink(self.spellID)
        if chatLink then
            ChatEdit_InsertLink(chatLink)
        end
    end
end

--
-- Inspect Build Talent Mixin
--
InspectBuildTalentMixin = {}


function InspectBuildTalentMixin:OnLoad()
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)

    self.Icon:SetBackgroundSize(59, 59)
    self.Icon:SetBackgroundTexture("Interface\\Buttons\\UI-EmptySlot")
    self.Icon:SetBackgroundOffset(0, -1)
end

function InspectBuildTalentMixin:SetRankAndBg(entry, rank, maxRank, unit, specID)
    rank = rank or (C_CharacterAdvancement.UnitKnownID(unit, entry.ID, specID) and 1 or 0)
    maxRank = maxRank or 1

    if maxRank <= 1 and IsHeroClass(unit) then
        self.Icon.RankFrame:Hide()
    else
        self.Icon.RankFrame:Show()

        self.Icon.RankFrame:SetRank(rank)
        self.Icon.RankFrame:SetMaxRank(maxRank)
        self.Icon.RankFrame:UpdateVisual()
    end

    if rank == 0 then
        self.Icon.Background:SetDesaturated(true)
    else
        self.Icon.Background:SetDesaturated(false)
        local r, g, b = self.Icon.RankFrame.RankBorder:GetVertexColor()
        self.Icon.Background:SetVertexColor(r, g, b)
    end

end

function InspectBuildTalentMixin:SetDisabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Show()
        self.Icon.DisabledOverlay:SetAlpha(0.35)
    end

    self.Icon.Icon:SetAlpha(0.35)
    self.Icon.IconBorder:SetAlpha(0.35)
    self.Icon.Overlay:SetAlpha(0.35)
    self.Icon.RankFrame:Hide()
end

function InspectBuildTalentMixin:SetEnabledVisual()
    if self.Icon.DisabledOverlay then
        self.Icon.DisabledOverlay:Hide()
        self.Icon.DisabledOverlay:SetAlpha(1)
    end

    self.Icon.Icon:SetAlpha(1)
    self.Icon.IconBorder:SetAlpha(1)
    self.Icon.Overlay:SetAlpha(1)
    self.Icon.RankFrame:Show()
end

function InspectBuildTalentMixin:SetEntry(entry, unit, specID)
    self.unit = unit
    self.specID = specID
    self.entry = entry
    self.spellID = entry.Spells[1]
    local rank, maxRank = C_CharacterAdvancement.UnitTalentRankByID(self.unit, entry.ID, self.specID)
    if rank and rank > 0 then
        self.spellID = entry.Spells[rank]
    end

    self.Icon:SetSpell(self.spellID)
    self:SetEnabledVisual()
    self.Icon:SetAlpha(1)
    self:EnableMouse(true)

    if C_CharacterAdvancement.UnitKnownID(self.unit, entry.ID, self.specID) then
        if self.Icon.KnownGlow then
            self.Icon.KnownGlow:Show()
        end

        self.Icon:SetIconDesaturated(false)
        self.Icon:SetIconColor(1, 1, 1)
    else
        if self.Icon.KnownGlow then
            self.Icon.KnownGlow:Hide()
        end
        
        self:SetDisabledVisual()
        self.Icon:SetIconDesaturated(true)
    end


    self:SetRankAndBg(entry, rank, maxRank, self.unit, self.specID)

    if entry.RequiredLevel > UnitLevel(self.unit) then
        self:SetDisabledVisual()
    end
end

function InspectBuildTalentMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()
end

function InspectBuildTalentMixin:OnLeave()
    GameTooltip:Hide()
end

--
-- Inspect Build Spec Mixin
--
InspectBuildSpecMixin = CreateFromMixins("ScrollListItemBaseMixin")

function InspectBuildSpecMixin:OnLoad()
    self:SetNormalAtlas("pvpqueue-button-casual-up")
    self:SetHighlightAtlas("pvpqueue-button-casual-highlight")
end

function InspectBuildSpecMixin:Update()
    self:SetText(SPECIALIZATION_LABEL .. " " .. self.index)
end

function InspectBuildSpecMixin:OnSelected()
end


BuildSpellMixin = {}

function BuildSpellMixin:OnLoad()
    self.Shadow:SetAtlas("spellbook-text-background", Const.TextureKit.IgnoreAtlasSize)
    self.NotesIcon:SetNormalAtlas("poi-workorders")
    self.NotesIcon:SetFrameLevel(self.Icon:GetFrameLevel()+1)
    self.Icon:SetBorderSize(34, 34)
    self.Icon:SetOverlaySize(34, 34)
    self.Icon:UseQuality(true)
    self.Icon.Known:SetNormalAtlas("common-icon-checkmark")
    self.RarityGems:SetGemSize(16)
    -- custom orientation so spacing isnt as dramatic
    self.RarityGems:SetOrientation({ "BOTTOMLEFT", "BOTTOMRIGHT", -1, 0 })
end

function BuildSpellMixin:SetSpell(spell)
    self.type = "spell"
    self.info = spell
    local spellID = spell.Spell
    self.spellID = spellID
    local name = GetSpellInfo(spellID)
    self.Icon:SetSpell(spellID)
    self.SubText:SetText("")

    local quality, qualityCount = C_CharacterAdvancement.GetQualityInfo(spellID)
    if quality and quality >= Enum.SpellQuality.Uncommon and qualityCount and qualityCount > 0 then
        self.RarityGems:Show()
        self.RarityGems:SetGemQuality(quality)
        self.RarityGems:SetNumGems(qualityCount, qualityCount)
    else
        self.RarityGems:Hide()
    end
      
    self:SetText(name)

    if spell.Comment and spell.Comment:len() > 0 then
        self.NotesIcon:Show()
        self.NotesIcon.tooltipTitle = BUILD_SPELL_COMMENT
        self.NotesIcon.tooltipText = spell.Comment
    else
        self.NotesIcon:Hide()
    end

    self.CoreIcon:SetShown(spell.IsCoreAbility)
    self.OptimalIcon:SetShown(spell.IsOptimalAbility)
    self.EmpoweringIcon:SetShown(spell.IsEmpoweringAbility)
    self.SynergisticIcon:SetShown(spell.IsSynergisticAbility)
    
    self.Icon.Known:SetShown(C_CharacterAdvancement.IsKnownSpellID(spellID))
end

function BuildSpellMixin:SetTalent(talent)
    self.type = "talent"
    self.info = talent
    local talentInfo = C_CharacterAdvancement.GetEntryByInternalID(talent.TalentID)
    local spellID = talentInfo.Spells[talent.TalentRank]
    self.spellID = spellID
    local name = GetSpellInfo(spellID)
    self.Icon:SetSpell(spellID)
    self.Icon:SetBorderAtlas("item-border-gold")
    self.Icon:SetOverlayTexture(nil)
    self:SetText(name)
    self.RarityGems:Hide()
    if talentInfo then
        local maxRank = #talentInfo.Spells
        if talent.TalentRank ~= maxRank then
            self.SubText:SetFormattedText(GREEN_FONT_COLOR:WrapText(TOOLTIP_TALENT_RANK), talent.TalentRank, maxRank)
        else
            self.SubText:SetFormattedText(TOOLTIP_TALENT_RANK, talent.TalentRank, maxRank)
        end
    else
        self.SubText:SetText("")
    end
    
    self.CoreIcon:SetShown(talent.IsCoreAbility)
    self.OptimalIcon:SetShown(talent.IsOptimalAbility)
    self.EmpoweringIcon:SetShown(talent.IsEmpoweringAbility)
    self.SynergisticIcon:SetShown(talent.IsSynergisticAbility)

    if talent.Comment and talent.Comment:len() > 0 then
        self.NotesIcon:Show()
        self.NotesIcon.tooltipTitle = BUILD_SPELL_COMMENT
        self.NotesIcon.tooltipText = talent.Comment
    else
        self.NotesIcon:Hide()
    end
    self.Icon.Known:SetShown(C_CharacterAdvancement.IsKnownSpellID(spellID))
end

function BuildSpellMixin:SetEquipment(equipment)
    self.type = "equipment"
    self.info = equipment
    local spellID = Enum.ArmorSubClassSID[equipment.Type] or Enum.WeaponSubClassSID[equipment.Type]
    self.spellID = spellID
    local name, _, icon = GetSpellInfo(spellID)
    self.Icon:SetIcon(icon)

    if Enum.ArmorSubClassSID[equipment.Type] then
        self.Icon:SetBorderAtlas("itemupgrade_slotborder")
        self.SubText:SetText(ITEM_CLASS_4)
    else
        self.Icon:SetBorderAtlas("quickslot-border-grey")
        self.SubText:SetText(ITEM_CLASS_2)
    end

    self.Icon:SetOverlayTexture(nil)
    self.RarityGems:Hide()

    self:SetText(name)

    if equipment.Comment and equipment.Comment:len() > 0 then
        self.NotesIcon:Show()
        self.NotesIcon.tooltipTitle = BUILD_SPELL_COMMENT
        self.NotesIcon.tooltipText = equipment.Comment
    else
        self.NotesIcon:Hide()
    end

    self.CoreIcon:Hide()
    self.Icon.Known:Hide()
end

function BuildSpellMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function BuildSpellMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function BuildSpellMixin:OnEvent(event, ...)
    if event == "CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED" then
        self.Icon.Known:SetShown(C_CharacterAdvancement.IsKnownSpellID(self.spellID))
    end
end

function BuildSpellMixin:OnDisable()
    self.Icon:SetDesaturated(true)
    self.Text:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    self.Icon:SetBorderDesaturated(true)
end

function BuildSpellMixin:OnEnable()
    self.Icon:SetDesaturated(false)
    self.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    self.Icon:SetBorderDesaturated(false)
end

function BuildSpellMixin:OnEnter()
    if self.spellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.type == "equipment" then
            local name = GetSpellInfo(self.spellID)
            GameTooltip:SetText(name, 1, 1, 1)
        else
            GameTooltip:SetHyperlink("spell:"..self.spellID)
        end
        GameTooltip:Show()
    end
end

function BuildSpellMixin:OnLeave()
    GameTooltip:Hide()
end

local function BuildSpellDropDownInitialize(dropdown, level, menuList)
    local data = dropdown.data
    if not data then return end
    
    local entry = C_CharacterAdvancement.GetEntryBySpellID(dropdown.spell)
    
    local _, _, icon = GetSpellInfo(dropdown.spell)

    -- spell name + icon
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.isTitle = true
    info.text = entry.Name
    info.icon = icon
    UIDropDownMenu_AddButton(info, level)
    
    -- learn
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = LEARN
    info.disabled = not C_CharacterAdvancement.CanLearnID(entry.ID)
    info.func = function()
        if entry.Type == "Talent" then
            local currentRank, maxRank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
            if currentRank and currentRank ~= maxRank then
                local learns = {}
                for i = currentRank + 1, maxRank do
                    tinsert(learns, entry.ID)
                end
                CharacterAdvancementUtil.ConfirmOrLearnID(learns)
                return
            end
        else
            CharacterAdvancementUtil.ConfirmOrLearnID(entry.ID)
        end
    end
    UIDropDownMenu_AddButton(info, level)

    -- unlearn
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = UNLEARN
    info.disabled = not C_CharacterAdvancement.CanUnlearnID(entry.ID)
    info.func = function()
        CharacterAdvancementUtil.ConfirmOrUnlearnID(entry.ID)
    end
    UIDropDownMenu_AddButton(info, level)

    -- cancel
    info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = CANCEL
    UIDropDownMenu_AddButton(info, level)
end

function BuildSpellMixin:OnClick()
    if self.type == "spell" or self.type == "talent" then
        local dropdown = self:GetParent().DropDown
        if not dropdown then
            dropdown = CreateFrame("Frame", "$parentDropDown", self:GetParent(), "UIDropDownMenuTemplate")
            self:GetParent().DropDown = dropdown
            UIDropDownMenu_Initialize(dropdown, BuildSpellDropDownInitialize, "MENU")
        end

        dropdown.data = self.info
        dropdown.spell = self.spellID
        ToggleDropDownMenu(1, nil, dropdown, self:GetName(), 0, 0)
    end
end

--
-- Build Enchant Mixin
--
BuildEnchantMixin = {}

function BuildEnchantMixin:OnLoad()
    self.Icon:SetBorderSize(54, 54)
    self.Icon:SetRounded(true)
    self.Icon.Known:SetNormalAtlas("common-icon-checkmark")
    self.NotesIcon:SetNormalAtlas("poi-workorders")
end

function BuildEnchantMixin:SetEnchant(enchant)
    self.info = enchant
    local spellID, stacks, level = enchant.Enchant, enchant.Stacks, enchant.Level
    self.spellID = spellID
    local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
    self.enchant = enchantInfo
    if not enchantInfo then
        return C_Logger.Error("Bad Enchant in Build! %s", spellID)
    end
    local name, _, icon = GetSpellInfo(spellID)
    local quality = Enum.EnchantQualityEnum[enchantInfo.Quality]
    if enchantInfo.MaxStacks > 1 then
        if not stacks or stacks == 0 then
            stacks = 1
        end
        local stackText = format("%d/%d", stacks, enchantInfo.MaxStacks)
        if stacks ~= enchantInfo.MaxStacks then
            stackText = GREEN_FONT_COLOR:WrapText(stackText)
        end
        self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(name) .. " " .. stackText)
    else
        self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(name))
    end
    self.Icon:SetIcon(icon)
    self.Icon:SetBorderAtlas(Enum.ECSlotBorderStylesKnown[quality])
    self.Icon.Known:SetShown(enchantInfo.Known)
    self.SubText:SetText(format(UNIT_LEVEL_TEMPLATE, level))

    if enchant.Comment and enchant.Comment:len() > 0 then
        self.NotesIcon:Show()
        self.NotesIcon.tooltipTitle = BUILD_SPELL_COMMENT
        self.NotesIcon.tooltipText = enchant.Comment
    else
        self.NotesIcon:Hide()
    end
end

function BuildEnchantMixin:OnEnter()
    if self.spellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("spell:"..self.spellID)
        GameTooltip:Show()
    end
end

function BuildEnchantMixin:OnLeave()
    GameTooltip:Hide()
end

EditableBuildSpellMixin = CreateFromMixins(BuildSpellMixin)
EditableBuildSpellMixin.OnShow = nop
EditableBuildSpellMixin.OnHide = nop

function EditableBuildSpellMixin:OnLoad()
    BuildSpellMixin.OnLoad(self)
    self.EditOverlay.SettingsButton:SetNormalAtlas("mechagon-projects")
    self.EditOverlay.SettingsButton:SetHighlightAtlas("mechagon-projects")
    self.EditOverlay.DecreaseRank:SetNormalAtlas("common-icon-backarrow")
    self.EditOverlay.IncreaseRank:SetNormalAtlas("common-icon-forwardarrow")
    self.EditOverlay.DecreaseRank:SetHighlightAtlas("common-icon-backarrow")
    self.EditOverlay.IncreaseRank:SetHighlightAtlas("common-icon-forwardarrow")
    self.EditOverlay.DecreaseRank:SetDisabledAtlas("common-icon-backarrow-disable")
    self.EditOverlay.IncreaseRank:SetDisabledAtlas("common-icon-forwardarrow-disable")
    
    self:RegisterForDrag("LeftButton")
end

function EditableBuildSpellMixin:SetSpell(spell)
    BuildSpellMixin.SetSpell(self, spell)
    self.Icon.Known:Hide()
    self.EditOverlay.DecreaseRank:Hide()
    self.EditOverlay.IncreaseRank:Hide()
end

function EditableBuildSpellMixin:SetTalent(talent, hideRankControls)
    BuildSpellMixin.SetTalent(self, talent)
    self.Icon.Known:Hide()
    self.EditOverlay.DecreaseRank:SetShown(not hideRankControls)
    self.EditOverlay.IncreaseRank:SetShown(not hideRankControls)
    local talentInfo = C_CharacterAdvancement.GetEntryByInternalID(talent.TalentID)
    self.EditOverlay.DecreaseRank:SetEnabled(talent.TalentRank > 1)
    self.EditOverlay.IncreaseRank:SetEnabled(talent.TalentRank < #talentInfo.Spells)
end

function EditableBuildSpellMixin:SetEquipment(equipment)
    BuildSpellMixin.SetEquipment(self, equipment)
    self.Icon.Known:Hide()
    self.EditOverlay.DecreaseRank:Hide()
    self.EditOverlay.IncreaseRank:Hide()
end

function EditableBuildSpellMixin:Remove()
    if self.type == "equipment" then
        if Enum.ArmorSIDSubClass[self.spellID] then
            C_BuildEditor.RemoveArmorType(self.info.Type)
        elseif Enum.WeaponSIDSubClass[self.spellID] then
            C_BuildEditor.RemoveWeaponType(self.info.Type)
        end
    else
        C_BuildEditor.RemoveSpell(self.spellID)
    end

    if self:IsMouseOver() then
        self.EditOverlay:Hide()
        BuildSpellMixin.OnLeave(self)
    end

    BuildCreatorUtil.UpdatePendingBuild()
end

function EditableBuildSpellMixin:IncreaseRank()
    if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
        local nextSpell = CharacterAdvancementUtil.GetTalentRankSpellBySpellID(self.spellID, self.info.TalentRank + 1)
        if nextSpell then
            local spellInfo = C_BuildEditor.GetSpellByID(self.spellID)
            spellInfo.Spell = nextSpell
            C_BuildEditor.AddSpell(spellInfo)
        end
    end

    BuildCreatorUtil.UpdatePendingBuild()
    if self:IsMouseOver() then
        self:OnEnter()
    end
end

function EditableBuildSpellMixin:DecreaseRank()
    if C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
        C_BuildEditor.RemoveSpell(self.spellID)
    end

    BuildCreatorUtil.UpdatePendingBuild()
    if self:IsMouseOver() then
        self:OnEnter()
    end
end

function EditableBuildSpellMixin:OnClick()
    if self.type ~= "equipment" then
        if BuildCreatorUtil.GetHeldSpell() then
            return self:OnReceiveDrag()
        end
    end

    if IsShiftKeyDown() then
        C_BuildEditor.SetIsOptimalAbility(self.spellID, not self.info.IsOptimalAbility)
        BuildCreatorUtil.UpdatePendingBuild()
    elseif IsControlKeyDown() then
        C_BuildEditor.SetIsEmpoweringAbility(self.spellID, not self.info.IsEmpoweringAbility)
        BuildCreatorUtil.UpdatePendingBuild()
    elseif IsAltKeyDown() then
        C_BuildEditor.SetIsSynergisticAbility(self.spellID, not self.info.IsSynergisticAbility)
        BuildCreatorUtil.UpdatePendingBuild()
    else
        self:GetParent():ShowDropDown(self)
    end
end

function EditableBuildSpellMixin:OnEnter()
    BuildSpellMixin.OnEnter(self)
    BuildCreatorUtil.CheckHeldSpellPlacement(self.info.Level)
    self.EditOverlay:Show()
end

function EditableBuildSpellMixin:OnLeave()
    if not self.EditOverlay:IsMouseOver() then
        self.EditOverlay:Hide()
        BuildCreatorUtil.CheckHeldSpellPlacement()
        BuildSpellMixin.OnLeave(self)
    end
end

function EditableBuildSpellMixin:OnDragStart()
    if self.type == "equipment" then
        return
    end

    if self:GetParent().levelingBuild then
        BuildCreatorUtil.PickupSpell(self.info)
    end
end

function EditableBuildSpellMixin:OnReceiveDrag()
    if self.type == "equipment" then
        return
    end
    
    BuildCreatorUtil.PlaceHeldSpellAtLevel(self.info.Level)
end

EditableBuildEnchantMixin = CreateFromMixins(BuildEnchantMixin)

function EditableBuildEnchantMixin:OnLoad()
    BuildEnchantMixin.OnLoad(self)
    self.EditOverlay.SettingsButton:SetNormalAtlas("mechagon-projects")
    self.EditOverlay.SettingsButton:SetHighlightAtlas("mechagon-projects")
    self.EditOverlay.DecreaseStacks:SetNormalAtlas("common-icon-backarrow")
    self.EditOverlay.IncreaseStacks:SetNormalAtlas("common-icon-forwardarrow")
    self.EditOverlay.DecreaseStacks:SetHighlightAtlas("common-icon-backarrow")
    self.EditOverlay.IncreaseStacks:SetHighlightAtlas("common-icon-forwardarrow")
    self.EditOverlay.DecreaseStacks:SetDisabledAtlas("common-icon-backarrow-disable")
    self.EditOverlay.IncreaseStacks:SetDisabledAtlas("common-icon-forwardarrow-disable")
end

function EditableBuildEnchantMixin:SetEnchant(enchant)
    BuildEnchantMixin.SetEnchant(self, enchant)

    if self.enchant.MaxStacks > 1 then
        self.EditOverlay.DecreaseStacks:Show()
        self.EditOverlay.IncreaseStacks:Show()
        self.EditOverlay.DecreaseStacks:SetEnabled(enchant.Stacks > 1)
        self.EditOverlay.IncreaseStacks:SetEnabled(enchant.Stacks < self.enchant.MaxStacks)
    else
        self.EditOverlay.DecreaseStacks:Hide()
        self.EditOverlay.IncreaseStacks:Hide()
    end
end

function EditableBuildEnchantMixin:Remove()
    C_BuildEditor.RemoveRandomEnchant(self.spellID)

    if self:IsMouseOver() then
        self.EditOverlay:Hide()
        BuildEnchantMixin.OnLeave(self)
    end

    BuildCreatorUtil.UpdatePendingBuild()
end

function EditableBuildEnchantMixin:IncreaseRank()
    local maxStacks = self.enchant.MaxStacks
    if self.info.Stacks < maxStacks then
        C_BuildEditor.SetEnchantStacks(self.spellID, self.info.Stacks + 1)

        BuildCreatorUtil.UpdatePendingBuild()
        if self:IsMouseOver() then
            self:OnEnter()
        end
    end
end

function EditableBuildEnchantMixin:DecreaseRank()
    if self.info.Stacks > 1 then
        C_BuildEditor.SetEnchantStacks(self.spellID, self.info.Stacks - 1)

        BuildCreatorUtil.UpdatePendingBuild()
        if self:IsMouseOver() then
            self:OnEnter()
        end
    end
end

function EditableBuildEnchantMixin:OnClick()
    self:GetParent():ShowDropDown(self)
end

function EditableBuildEnchantMixin:OnEnter()
    BuildEnchantMixin.OnEnter(self)
    self.EditOverlay:Show()
end

function EditableBuildEnchantMixin:OnLeave()
    if not self.EditOverlay:IsMouseOver() then
        self.EditOverlay:Hide()
        BuildEnchantMixin.OnLeave(self)
    end
end 
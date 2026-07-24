BuildViewSectionMixin = {}

BuildViewSectionMixin.CategoryIcons = {
    [BuildCreatorUtil.DescriptionSection.Overview] = "Interface\\Icons\\inv_ascend_scroll_07_b",
    [BuildCreatorUtil.DescriptionSection.SpellsAndTalents] = "Interface\\Icons\\trade_archaeology_draenei_tome",
    [BuildCreatorUtil.DescriptionSection.MysticEnchants] = "Interface\\Icons\\inv_MysticEnchantAltar",
    [BuildCreatorUtil.DescriptionSection.ProsAndCons] = "Interface\\Icons\\achievement_guildperk_mrpopularity_rank2",
    [BuildCreatorUtil.DescriptionSection.Equipment] = "Interface\\Icons\\inv_chest_chain",
    [BuildCreatorUtil.DescriptionSection.Itemization] = "Interface\\Icons\\garrison_purplearmorupgrade",
    [BuildCreatorUtil.DescriptionSection.Rotation] = "Interface\\Icons\\inv_sword_04",
    [BuildCreatorUtil.DescriptionSection.Consumables] = "Interface\\Icons\\inv_potion_50",
    [BuildCreatorUtil.DescriptionSection.Macros] = "Interface\\MacroFrame\\MacroFrame-Icon",
    [BuildCreatorUtil.DescriptionSection.WeakAuras] = "Interface\\Icons\\trade_engineering",
    [BuildCreatorUtil.DescriptionSection.Notes] = "Interface\\Icons\\inv_misc_note_02",
}

function BuildViewSectionMixin:OnLoad()
    self.Icon:SetRounded(true)
    self.Icon:SetBorderSize(50, 50)
    self.Icon:SetBorderOffset(0, -1)
    self.Icon:SetBorderAtlas("build-draft-stat-border")
    local category = self:GetAttribute("category")
    if category then
        self:SetCategory(category)
    end
    SetParentArray(self, "sections")
end

function BuildViewSectionMixin:SetIcon(icon)
    self.Icon:SetIcon(icon)
end

function BuildViewSectionMixin:SetTitle(title)
    self.Icon.Title:SetText(title)
end

function BuildViewSectionMixin:SetCategory(category)
    self.category = category
    if category == "SPELLS_AND_TALENTS" and C_Player:IsDefaultClass() then
        self:SetTitle(_G["BUILDCREATOR_SECTION_TALENTS"])
    else
        self:SetTitle(_G["BUILDCREATOR_SECTION_"..category])
    end
    self.Icon:SetIcon(BuildViewSectionMixin.CategoryIcons[category])
end

--
-- SimpleHTML Mixin
--
BuildViewSectionHTMLMixin = {}

function BuildViewSectionHTMLMixin:OnLoad()
    self:SetJustifyH("LEFT")
    self:SetJustifyV("TOP")
    self:SetHyperlinksEnabled(true)
end

function BuildViewSectionHTMLMixin:SetDynamicText(text)
    text = text:gsub("(https://db.ascension.gg/%S+)", LinkUtil.ConvertDBUrlToHyperlink)
    self:SetHeight(2000)
    self.HiddenText:Show()
    self.HiddenText:SetText(text)
    self:SetText(text)
    local height = self.HiddenText:GetStringHeight()
    self:SetHeight(height)
    self.HiddenText:Hide()

    return height
end 

function BuildViewSectionHTMLMixin:GetText()
    return self.HiddenText:GetText()
end

function BuildViewSectionHTMLMixin:OnHyperlinkClick(link, text, button)
    LinkUtil:HandleHyperlinkClick(self, link, text, button)
end 

function BuildViewSectionHTMLMixin:OnHyperlinkEnter(link, text)
    LinkUtil:OnHyperlinkEnter(self, link, text)
end

function BuildViewSectionHTMLMixin:OnHyperlinkLeave()
    LinkUtil:OnHyperlinkLeave(self)
end

--
-- editable build sections
--
EditableBuildViewSectionMixin = CreateFromMixins(BuildViewSectionMixin)

function EditableBuildViewSectionMixin:Serialize()
    if self.Text then
        local formatString = "### %s\n%s"
        local text = self.Text:ToText()
        if text:len() == 0 then
            return
        end
        text = text:gsub("#", "{HT}")
        return format(formatString, self.category, text)
    end
end

function EditableBuildViewSectionMixin:Deserialize(text)
    if self.Text then
        if self.Text.SetText then
            self.Text:SetText(text or "")
        end
    end
end

--
-- Spell Editor Section
--
EditableBuildSpellSectionMixin = CreateFromMixins(EditableBuildViewSectionMixin)

function EditableBuildSpellSectionMixin:OnLoad()
    EditableBuildViewSectionMixin.OnLoad(self)
    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
end

local function AddHeader(self, specName, classFile, icon, index)
    local header = self.HeaderPool:Acquire()
    header.Icon:SetTexture("Interface\\Icons\\"..icon)
    header:GetNormalTexture():SetVertexColor((RAID_CLASS_COLORS[classFile] or HIGHLIGHT_FONT_COLOR):GetRGB())
    header:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    header.Text:SetFontObject(GameFontHighlight)
    header.Text:SetPoint("LEFT", header.Icon, "RIGHT", -2, 0)
    header:SetFormattedText("%s\n%s", specName, LOCALIZED_CLASS_NAMES_MALE[classFile] or classFile)
    header:Show()
    header.level = nil

    header.AbilityEssenceText:Hide()
    header.TalentEssenceText:Hide()
    header.AbilityEssenceIcon:Hide()
    header.TalentEssenceIcon:Hide()
end

local function AddLevelHeader(self, level, ae, te, index)
    local header = self.HeaderPool:Acquire()
    header.Icon:SetTexture("Interface\\Icons\\spell_holy_innerfire")
    if level % 5 == 0 then
        header:GetNormalTexture():SetVertexColor(0.4, 0.3, 0)
    else
        header:GetNormalTexture():SetVertexColor(0.3, 0.2, 0)
    end
    header:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    header:SetText(level)
    header.Text:SetFontObject(GameFontHighlightHuge)
    header.Text:SetPoint("LEFT", 6, -2)
    header:Show()
    header.level = level
    
    local hasAE = ae >= 0
    local hasTE = te >= 0
    
    header.AbilityEssenceText:SetShown(hasAE)
    header.AbilityEssenceIcon:SetShown(hasAE)
    header.TalentEssenceText:SetShown(hasTE)
    header.TalentEssenceIcon:SetShown(hasTE)

    if hasAE and hasTE then
        header.AbilityEssenceIcon:SetPoint("RIGHT", -12, 8)
        header.TalentEssenceIcon:SetPoint("RIGHT", -12, -8)
    elseif hasAE then
        header.AbilityEssenceIcon:SetPoint("RIGHT", -12, 0)
    elseif hasTE then
        header.TalentEssenceIcon:SetPoint("RIGHT", -12, 0)
    end

    header.AbilityEssenceText:SetText(ae)
    header.TalentEssenceText:SetText(te)

    if ae == 0 then
        header.AbilityEssenceText:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
        header.AbilityEssenceIcon:SetDesaturated(true)
    else
        header.AbilityEssenceText:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        header.AbilityEssenceIcon:SetDesaturated(false)
    end

    if te == 0 then
        header.TalentEssenceText:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
        header.TalentEssenceIcon:SetDesaturated(true)
    else
        header.TalentEssenceText:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
        header.TalentEssenceIcon:SetDesaturated(false)
    end
end

local function AddSpell(self, spell, index)
    local spellIcon = self.IconPool:Acquire()

    if spell.TalentID then
        spellIcon:SetTalent(spell, self.levelingBuild)
    else
        spellIcon:SetSpell(spell)
    end
    spellIcon:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    spellIcon:Show()
end

function EditableBuildSpellSectionMixin:CreateFilterButtons(build)
    self.FilterCore = CreateFrame("CheckButton", "$parentFilterCore", self, "SquareIconCheckButtonTemplate")
    self.FilterCore:SetPoint("LEFT", self.Icon.Title, "RIGHT", 8, 0)
    self.FilterCore:SetText(CORE)
    self.FilterCore:GetFontString():ClearAndSetPoint("LEFT", self.FilterCore, "RIGHT", 4, 0)
    self.FilterCore:SetChecked(true)
    self.FilterCore:SetScript("OnClick", BuildCreatorUtil.UpdatePendingBuild)

    self.FilterOptimal = CreateFrame("CheckButton", "$parentFilterOptimal", self, "SquareIconCheckButtonTemplate")
    self.FilterOptimal:SetPoint("LEFT", self.FilterCore:GetFontString(), "RIGHT", 8, 0)
    self.FilterOptimal:SetText(OPTIMAL)
    self.FilterOptimal:GetFontString():ClearAndSetPoint("LEFT", self.FilterOptimal, "RIGHT", 4, 0)
    self.FilterOptimal:SetChecked(true)
    self.FilterOptimal:SetScript("OnClick", BuildCreatorUtil.UpdatePendingBuild)

    self.FilterEmpowering = CreateFrame("CheckButton", "$parentFilterEmpowering", self, "SquareIconCheckButtonTemplate")
    self.FilterEmpowering:SetPoint("LEFT", self.FilterOptimal:GetFontString(), "RIGHT", 8, 0)
    self.FilterEmpowering:SetText(EMPOWERING)
    self.FilterEmpowering:GetFontString():ClearAndSetPoint("LEFT", self.FilterEmpowering, "RIGHT", 4, 0)
    self.FilterEmpowering:SetChecked(true)
    self.FilterEmpowering:SetScript("OnClick", BuildCreatorUtil.UpdatePendingBuild)

    self.FilterSynergistic = CreateFrame("CheckButton", "$parentFilterSynergistic", self, "SquareIconCheckButtonTemplate")
    self.FilterSynergistic:SetPoint("LEFT", self.FilterEmpowering:GetFontString(), "RIGHT", 8, 0)
    self.FilterSynergistic:SetText(SYNERGISTIC)
    self.FilterSynergistic:GetFontString():ClearAndSetPoint("LEFT", self.FilterSynergistic, "RIGHT", 4, 0)
    self.FilterSynergistic:SetChecked(true)
    self.FilterSynergistic:SetScript("OnClick", BuildCreatorUtil.UpdatePendingBuild)
end

function EditableBuildSpellSectionMixin:BuildMaxLevelEditor(build)
    if not self.FilterCore then
        self:CreateFilterButtons()
    else
        self.FilterCore:Show()
        self.FilterOptimal:Show()
        self.FilterSynergistic:Show()
        self.FilterEmpowering:Show()
    end

    local spellsByClass, spellCount = BuildCreatorUtil.GetSpellsByClass(build, self.FilterCore:GetChecked(), self.FilterOptimal:GetChecked(), self.FilterSynergistic:GetChecked(), self.FilterEmpowering:GetChecked())
    local index = 1
    local _, aeRemaining, _, teRemaining = C_BuildEditor.GetEssenceForLevel(GetMaxLevel())
    if aeRemaining > 0 or teRemaining > 0 then
        local addSpellButton = self.AddSpellPool:Acquire()
        addSpellButton.level = GetMaxLevel()
        addSpellButton:SetPoint("TOPLEFT", 21, -50)
        addSpellButton:Show()
        index = index + 1
    end

    local spells, specs, specInfo, r

    if spellsByClass["GENERAL"] then
        r = index % 4
        if r > 1 then
            index = index + (4 - r) + 1 -- new row
        elseif r == 0 then
            index = index + 1
        end
        AddHeader(self, "General", "", "classicon_hero", index)
        index = index + 4
        for _, spell in ipairs(spellsByClass["GENERAL"]["GENERAL1"]) do
            AddSpell(self, spell, index)
            index = index + 1
        end
    end

    for _, classFile in ipairs(Enum.ClassFile) do
        -- ordered by class ID
        spells = spellsByClass[classFile]
        if spells then
            specs = C_ClassInfo.GetAllSpecs(classFile)
            for _, specName in ipairs(specs) do
                -- check each spec in order (from chrspecs dbc order)
                local specSpells = spells[specName]
                if specSpells then
                    specInfo = C_ClassInfo.GetSpecInfo(classFile, specName)
                    r = index % 4
                    if r > 1 then
                        index = index + (4 - r) + 1 -- new row
                    elseif r == 0 then
                        index = index + 1
                    end
                    AddHeader(self, specInfo.Name, classFile, specInfo.SpecFilename, index)
                    index = index + 4 -- new row
                    -- list spells
                    for _, spell in ipairs(specSpells) do
                        AddSpell(self, spell, index)
                        index = index + 1
                    end
                end
            end
        end
    end

    self:SetHeight(50 + ((math.ceil(index / 4)) * 44))
end

function EditableBuildSpellSectionMixin:BuildLevelingEditor(build)
    local spells
    local index, r = 0, 0
    local isDefaultClass = C_Player:IsDefaultClass()
    -- leveling format
    local spellsByLevel, spellCount, maxLevel = BuildCreatorUtil.GetLevelingEditorSpells(build, isDefaultClass)

    for level = 1, maxLevel do
        spells = spellsByLevel[level]
        if spells.HasHeader then
            r = index % 4
            if r > 1 then
                index = index + (4 - r) + 1 -- new row
            elseif r == 0 then
                index = index + 1
            end
            AddLevelHeader(self, level, spells.AERemaining, spells.TERemaining, index)
            index = index + 1
        end

        if spells.CanAdd then
            local addSpellButton = self.AddSpellPool:Acquire()
            addSpellButton.level = level
            addSpellButton:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
            addSpellButton:Show()
            index = index + (4 - (index % 4)) + 1 -- new row
        end

        -- list spells
        for _, spell in ipairs(spells) do
            AddSpell(self, spell, index)
            index = index + 1
        end
    end

    self:SetHeight(50 + ((math.ceil(index / 4)) * 44))
end

function EditableBuildSpellSectionMixin:Serialize(build)
    self.build = build
    if not self.IconPool then
        self.IconPool = CreateFramePool("Button", self, "EditableBuildSpellTemplate")
        self.HeaderPool = CreateFramePool("Button", self, "BuildSpellHeaderTemplate")
        self.AddSpellPool = CreateFramePool("Button", self, "BuildAddSpellTemplate")
    end

    self.IconPool:ReleaseAll()
    self.HeaderPool:ReleaseAll()
    self.AddSpellPool:ReleaseAll()
    self:Show()

    if self.FilterCore then
        self.FilterCore:Hide()
        self.FilterOptimal:Hide()
        self.FilterSynergistic:Hide()
        self.FilterEmpowering:Hide()
    end

    if BuildCreatorFrameEditableBuildViewPanel:IsLevelingBuild() then
        self.levelingBuild = true
        self:BuildLevelingEditor(build)
    else
        self.levelingBuild = false
        self:BuildMaxLevelEditor(build)
    end
end

function EditableBuildSpellSectionMixin:InitializeDropDown(dropdown, level, menuList)
    if not dropdown.spell then return end
    local spellID = dropdown.spell.spellID
    local buildSpell = dropdown.spell.info
    local info

    if menuList == "flags" then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_SHOW_DRAFT
        info.tooltip = SPELL_SET_SHOW_DRAFT_TOOLTIP
        info.checked = bit.contains(buildSpell.Flags, Enum.BuildSpellFlags.NotifyOnLearn)
        info.enabled = C_BuildEditor.CanSetSpellFlags(spellID)
        info.func = function()
            C_BuildEditor.SetSpellFlags(spellID, bit.bxor(buildSpell.Flags, Enum.BuildSpellFlags.NotifyOnLearn))
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)

        return
    end

    local name, _, icon = GetSpellInfo(spellID)
    
    info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = name
    info.icon = icon
    info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = 0.1, 0.9, 0.1, 0.9
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = REMOVE
    info.notCheckable = true
    info.func = function()
        dropdown.spell:Remove()
    end
    UIDropDownMenu_AddButton(info, level)
    
    info = UIDropDownMenu_CreateInfo()
    info.text = SPELL_SET_COMMENT
    info.notCheckable = true
    info.func = function()
        StaticPopup_Show("BUILD_CREATOR_SET_COMMENT", LinkUtil:GetSpellLink(spellID), nil, spellID)
    end
    UIDropDownMenu_AddButton(info, level)

    if buildSpell.IsCoreAbility ~= nil then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_CORE_ABILITY
        info.tooltip = SPELL_SET_CORE_ABILITY_TOOLTIP
        info.checked = buildSpell.IsCoreAbility
        info.disabled = not C_BuildEditor.CanSetIsCoreAbility(spellID, not buildSpell.IsCoreAbility)
        info.func = function()
            C_BuildEditor.SetIsCoreAbility(spellID, not buildSpell.IsCoreAbility)
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    if buildSpell.IsOptimalAbility ~= nil then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_OPTIMAL_ABILITY
        info.tooltip = SPELL_SET_OPTIMAL_ABILITY_TOOLTIP
        info.checked = buildSpell.IsOptimalAbility
        info.disabled = not C_BuildEditor.CanSetIsOptimalAbility(spellID, not buildSpell.IsOptimalAbility)
        info.func = function()
            C_BuildEditor.SetIsOptimalAbility(spellID, not buildSpell.IsOptimalAbility)
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    if buildSpell.IsEmpoweringAbility ~= nil then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_EMPOWERING_ABILITY
        info.tooltip = SPELL_SET_EMPOWERING_ABILITY_TOOLTIP
        info.checked = buildSpell.IsEmpoweringAbility
        info.disabled = not C_BuildEditor.CanSetIsEmpoweringAbility(spellID, not buildSpell.IsEmpoweringAbility)
        info.func = function()
            C_BuildEditor.SetIsEmpoweringAbility(spellID, not buildSpell.IsEmpoweringAbility)
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    if buildSpell.IsSynergisticAbility ~= nil then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_SYNERGISTIC_ABILITY
        info.tooltip = SPELL_SET_SYNERGISTIC_ABILITY_TOOLTIP
        info.checked = buildSpell.IsSynergisticAbility
        info.disabled = not C_BuildEditor.CanSetIsSynergisticAbility(spellID, not buildSpell.IsSynergisticAbility)
        info.func = function()
            C_BuildEditor.SetIsSynergisticAbility(spellID, not buildSpell.IsSynergisticAbility)
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)
    end

    if C_Player:IsGM() and buildSpell.Flags then
        info = UIDropDownMenu_CreateInfo()
        info.text = BUILD_SPELL_FLAGS
        info.menuList = "flags"
        info.hasArrow = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    end

    info = UIDropDownMenu_CreateInfo()
    info.text = CLOSE
    info.notCheckable = true
    info.func = function() CloseDropDownMenus(level)  end
    UIDropDownMenu_AddButton(info, level)
end

function EditableBuildSpellSectionMixin:ShowDropDown(spell)
    self.DropDown.spell = spell
    ToggleDropDownMenu(1, nil, self.DropDown, spell:GetName(), 0, 0)
end

--
-- Enchant Editor Section
--
EditableBuildEnchantSectionMixin = CreateFromMixins(EditableBuildViewSectionMixin)

local function ShouldShowMysticEnchantSection()
    return not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
end

function EditableBuildEnchantSectionMixin:OnLoad()
    EditableBuildViewSectionMixin.OnLoad(self)
    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
end

function EditableBuildEnchantSectionMixin:Serialize(build)
    if not self.IconPool then
        self.IconPool = CreateFramePool("Button", self, "EditableBuildEnchantTemplate")
        self.AddEnchantButton = CreateFrame("Button", "$parentAddEnchantButton", self, "BuildAddEnchantTemplate")
        self.AddEnchantButton:SetPoint("TOPLEFT", 21, -50)
    end

    self.IconPool:ReleaseAll()
    self.AddEnchantButton:SetShown(ShouldShowMysticEnchantSection())

    if not ShouldShowMysticEnchantSection() then
        self:SetHeight(0)
        self:Hide()
        return
    end

    self:Show()

    local index = 1
    -- show grid of enchants
    for i, enchant in ipairs(build.RandomEnchants) do
        local enchantIcon = self.IconPool:Acquire()
        enchantIcon:SetEnchant(enchant)
        enchantIcon:SetPoint(GetGridPoint(index, self, 188, 44, 3, 21, -94))
        enchantIcon:Show()
        index = index + 1
    end

    self:SetHeight(116 + ((math.ceil(index / 4)) * 44))
end

function EditableBuildEnchantSectionMixin:InitializeDropDown(dropdown, level, menuList)
    if not dropdown.spell then return end
    local buildSpell = dropdown.spell.info
    local spellID = dropdown.spell.spellID
    
    local name, _, icon = GetSpellInfo(spellID)

    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = name
    info.icon = icon
    info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = 0.1, 0.9, 0.1, 0.9
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = REMOVE
    info.notCheckable = true
    info.func = function()
        dropdown.spell:Remove()
    end
    UIDropDownMenu_AddButton(info, level)

    if menuList == "flags" then
        info = UIDropDownMenu_CreateInfo()
        info.text = SPELL_SET_SHOW_DRAFT
        info.tooltip = SPELL_SET_SHOW_DRAFT_TOOLTIP
        info.checked = bit.contains(buildSpell.Flags, Enum.BuildSpellFlags.NotifyOnLearn)
        info.enabled = C_BuildEditor.CanSetEnchantFlags(spellID)
        info.func = function()
            C_BuildEditor.SetEnchantFlags(spellID, bit.bxor(buildSpell.Flags, Enum.BuildSpellFlags.NotifyOnLearn))
            BuildCreatorUtil.UpdatePendingBuild()
        end
        UIDropDownMenu_AddButton(info, level)

        return
    end

    info = UIDropDownMenu_CreateInfo()
    info.text = SPELL_SET_COMMENT
    info.notCheckable = true
    info.func = function()
        StaticPopup_Show("BUILD_CREATOR_SET_COMMENT", LinkUtil:GetSpellLink(spellID), nil, spellID)
    end
    UIDropDownMenu_AddButton(info, level)

    if C_Player:IsGM() then
        info = UIDropDownMenu_CreateInfo()
        info.text = "Set Level"
        info.notCheckable = true
        info.func = function()
            StaticPopup_Show("BUILD_CREATOR_SET_ENCHANT_LEVEL", LinkUtil:GetSpellLink(spellID), nil, spellID)
        end
        UIDropDownMenu_AddButton(info, level)

        if buildSpell.Flags then
            info = UIDropDownMenu_CreateInfo()
            info.text = BUILD_SPELL_FLAGS
            info.menuList = "flags"
            info.hasArrow = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    end

    info = UIDropDownMenu_CreateInfo()
    info.text = CLOSE
    info.notCheckable = true
    info.func = function() CloseDropDownMenus(level)  end
    UIDropDownMenu_AddButton(info, level)
end

function EditableBuildEnchantSectionMixin:ShowDropDown(spell)
    self.DropDown.spell = spell
    ToggleDropDownMenu(1, nil, self.DropDown, spell:GetName(), 0, 0)
end

--
-- Equipment Editor Section
--
EditableBuildEquipmentSectionMixin = CreateFromMixins(EditableBuildSpellSectionMixin)

function EditableBuildEquipmentSectionMixin:OnLoad()
    EditableBuildSpellSectionMixin.OnLoad(self)
    UIDropDownMenu_Initialize(self.AddEquipmentDropDown, GenerateClosure(self.InitializeAddEquipmentDropDown, self), "MENU")
end

function EditableBuildEquipmentSectionMixin:Serialize(build)
    if not self.IconPool then
        self.IconPool = CreateFramePool("Button", self, "EditableBuildSpellTemplate")
        self.AddEquipmentButton = CreateFrame("Button", "$parentAddEquipmentButton", self, "BuildAddEquipmentTemplate")
        self.AddEquipmentButton:SetPoint("TOPLEFT", 21, -50)
        self.AddEquipmentButton:Show()
    end

    self.IconPool:ReleaseAll()

    local index = 1

    for i, armor in ipairs(build.ArmorTypes) do
        local icon = self.IconPool:Acquire()
        icon:SetEquipment(armor)
        icon:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -94))
        icon:Show()
        index = index + 1
    end

    for i, weapon in ipairs(build.WeaponTypes) do
        local icon = self.IconPool:Acquire()
        icon:SetEquipment(weapon)
        icon:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -94))
        icon:Show()
        index = index + 1
    end

    self:SetHeight(116 + ((math.ceil(index / 4)) * 44))
end

local ArmorOrder, WeaponOrder

function EditableBuildEquipmentSectionMixin:InitializeAddEquipmentDropDown(dropdown, level, menuList)
    local class = select(2, UnitClass("player"))
    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = ITEM_CLASS_4
    UIDropDownMenu_AddButton(info, level)
    
    local armors = ArmorOrder[class] or ArmorOrder["DEFAULT"]

    for _, armorType in pairs(armors) do
        local armor = {
            Comment = "",
            Type = armorType
        }
        if C_BuildEditor.CanAddArmorType(armor) then
            local name, _, icon =  GetSpellInfo(Enum.ArmorSubClassSID[armorType])
            info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.icon = icon
            info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = 0.1, 0.9, 0.1, 0.9
            info.notCheckable = true
            info.func = function()
                C_BuildEditor.AddArmorType(armor)
                BuildCreatorUtil.UpdatePendingBuild()
            end
            
            UIDropDownMenu_AddButton(info, level)
        end
    end


    UIDropDownMenu_AddSpace(level)

    info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = ITEM_CLASS_2
    UIDropDownMenu_AddButton(info, level)
    
    local weapons = WeaponOrder[class] or WeaponOrder["DEFAULT"]

    for _, weaponType in pairs(weapons) do
        local weapon = {
            Comment = "",
            Type = weaponType
        }
        if C_BuildEditor.CanAddWeaponType(weapon) then
            local name, _, icon =  GetSpellInfo(Enum.WeaponSubClassSID[weaponType])
            info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.icon = icon
            info.tCoordLeft, info.tCoordRight, info.tCoordTop, info.tCoordBottom = 0.1, 0.9, 0.1, 0.9
            info.notCheckable = true
            info.func = function()
                C_BuildEditor.AddWeaponType(weapon)
                BuildCreatorUtil.UpdatePendingBuild()
            end

            UIDropDownMenu_AddButton(info, level)
        end
    end
end

function EditableBuildEquipmentSectionMixin:ShowEquipmentDropDown(button)
    ToggleDropDownMenu(1, nil, self.AddEquipmentDropDown, button:GetName(), button:GetWidth(), -button:GetHeight())
end

ArmorOrder = {
    ["DEFAULT"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
        "ITEM_SUBCLASS_ARMOR_PLATE",
        "ITEM_SUBCLASS_ARMOR_SHIELD",
        "ITEM_SUBCLASS_ARMOR_LIBRAM",
        "ITEM_SUBCLASS_ARMOR_IDOL",
        "ITEM_SUBCLASS_ARMOR_TOTEM",
        "ITEM_SUBCLASS_ARMOR_SIGIL",
    },
    ["WARRIOR"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
        "ITEM_SUBCLASS_ARMOR_PLATE",
        "ITEM_SUBCLASS_ARMOR_SHIELD",
    },
    ["PALADIN"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
        "ITEM_SUBCLASS_ARMOR_PLATE",
        "ITEM_SUBCLASS_ARMOR_SHIELD",
        "ITEM_SUBCLASS_ARMOR_LIBRAM",
    },
    ["DEATHKNIGHT"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
        "ITEM_SUBCLASS_ARMOR_PLATE",
        "ITEM_SUBCLASS_ARMOR_SIGIL",
    },
    ["DRUID"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_IDOL",
    },
    ["HUNTER"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
    },
    ["MAGE"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
    },
    ["PRIEST"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
    },
    ["ROGUE"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
    },
    ["SHAMAN"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
        "ITEM_SUBCLASS_ARMOR_LEATHER",
        "ITEM_SUBCLASS_ARMOR_MAIL",
        "ITEM_SUBCLASS_ARMOR_SHIELD",
        "ITEM_SUBCLASS_ARMOR_TOTEM",
    },
    ["WARLOCK"] = {
        "ITEM_SUBCLASS_ARMOR_CLOTH",
    },
}

WeaponOrder = {
    ["DEFAULT"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_SWORD2",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_BOW",
        "ITEM_SUBCLASS_WEAPON_CROSSBOW",
        "ITEM_SUBCLASS_WEAPON_GUN",
        "ITEM_SUBCLASS_WEAPON_WAND",
        "ITEM_SUBCLASS_WEAPON_THROWN",
    },
    ["WARRIOR"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_SWORD2",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_BOW",
        "ITEM_SUBCLASS_WEAPON_CROSSBOW",
        "ITEM_SUBCLASS_WEAPON_GUN",
        "ITEM_SUBCLASS_WEAPON_THROWN",
    },
    ["PALADIN"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_SWORD2",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
    },
    ["DEATHKNIGHT"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_SWORD2",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
    },
    ["DRUID"] = {
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
        "ITEM_SUBCLASS_WEAPON_STAFF",
    },
    ["HUNTER"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_SWORD2",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_POLEARM",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_BOW",
        "ITEM_SUBCLASS_WEAPON_CROSSBOW",
        "ITEM_SUBCLASS_WEAPON_GUN",
        "ITEM_SUBCLASS_WEAPON_THROWN",
    },
    ["MAGE"] = {
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_WAND",
    },
    ["PRIEST"] = {
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_WAND",
    },
    ["ROGUE"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_BOW",
        "ITEM_SUBCLASS_WEAPON_CROSSBOW",
        "ITEM_SUBCLASS_WEAPON_GUN",
        "ITEM_SUBCLASS_WEAPON_THROWN",
    },
    ["SHAMAN"] = {
        "ITEM_SUBCLASS_WEAPON_AXE",
        "ITEM_SUBCLASS_WEAPON_AXE2",
        "ITEM_SUBCLASS_WEAPON_MACE",
        "ITEM_SUBCLASS_WEAPON_MACE2",
        "ITEM_SUBCLASS_WEAPON_FIST",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_STAFF",
    },
    ["WARLOCK"] = {
        "ITEM_SUBCLASS_WEAPON_SWORD",
        "ITEM_SUBCLASS_WEAPON_DAGGER",
        "ITEM_SUBCLASS_WEAPON_STAFF",
        "ITEM_SUBCLASS_WEAPON_WAND",
    }
}

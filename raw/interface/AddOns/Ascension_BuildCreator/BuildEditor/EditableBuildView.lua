EditableBuildViewMixin = {}

local PRIMARY_STAT_STRING = {
    [1] = "STAT_STRENGTH",
    [2] = "STAT_AGILITY",
    [3] = "STAT_INTELLECT",
    [4] = "STAT_SPIRIT",
    [5] = "STAT_STAMINA",
}
local CONTENT_TOP_OFFSET = 14

local function ShouldShowMysticEnchantSection()
    return not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
end

function EditableBuildViewMixin:OnLoad()
    self.categories = {}

    self.MainFrame.Author:SetPoint("TOPLEFT", self.MainFrame.Name, "BOTTOMLEFT", 0, -2)
    self.MainFrame.Background:SetAtlas("buildcreator-view", Const.TextureKit.IgnoreAtlasSize)
    self.MainFrame.SpecIcon:SetRounded(true)
    self.MainFrame.SpecIcon:SetBorderSize(96, 96)
    self.MainFrame.Icon:SetRounded(true)
    self.MainFrame.Icon:SetBorderSize(68, 68)
    self.MainFrame.Icon:SetBorderOffset(0, -1)
    self.MainFrame.Icon:SetBorderAtlas("build-draft-border")

    self.CategoryScroll.Background:SetAtlas("professions-background-summarylist", Const.TextureKit.IgnoreAtlasSize)
    self.CategoryScroll:SetGetNumResultsFunction(function() return #self.categories end)
    self.CategoryScroll:SetTemplate("BuildViewSectionListItemTemplate")
    local selectedTexture = self.CategoryScroll:GetSelectedHighlight()
    selectedTexture:SetAtlas("Garr_ListButton-Selection", Const.TextureKit.IgnoreAtlasSize)
    selectedTexture:SetBlendMode("ADD")
    UIDropDownMenu_Initialize(self.MainFrame.DifficultyDropDown, GenerateClosure(self.InitializeDifficultyDropDown, self))
    UIDropDownMenu_Initialize(self.MainFrame.CategoryDropDown, GenerateClosure(self.InitializeCategoryDropDown, self))
end 

function EditableBuildViewMixin:InitializeDifficultyDropDown(dropdown, level, menuList)
    if not self:IsVisible() then return end
    local info, color

    info = UIDropDownMenu_CreateInfo()
    color = BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Standard]
    info.text = color:WrapText(_G[Enum.BuildDifficulty.Standard])
    info.iconAtlas = BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Standard]
    info.func = function()
        C_BuildEditor.SetDifficultyRating(Enum.BuildDifficulty.Standard)
        self:UpdatePendingBuild()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    color = BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Intermediate]
    info.text = color:WrapText(_G[Enum.BuildDifficulty.Intermediate])
    info.iconAtlas = BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Intermediate]
    info.func = function()
        C_BuildEditor.SetDifficultyRating(Enum.BuildDifficulty.Intermediate)
        self:UpdatePendingBuild()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    color = BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Advanced]
    info.text = color:WrapText(_G[Enum.BuildDifficulty.Advanced])
    info.iconAtlas = BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Advanced]
    info.func = function()
        C_BuildEditor.SetDifficultyRating(Enum.BuildDifficulty.Advanced)
        self:UpdatePendingBuild()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    color = BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Expert]
    info.text = color:WrapText(_G[Enum.BuildDifficulty.Expert])
    info.iconAtlas = BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Expert]
    info.func = function()
        C_BuildEditor.SetDifficultyRating(Enum.BuildDifficulty.Expert)
        self:UpdatePendingBuild()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    color = BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Impossible]
    info.text = color:WrapText(_G[Enum.BuildDifficulty.Impossible])
    info.iconAtlas = BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Impossible]
    info.func = function()
        C_BuildEditor.SetDifficultyRating(Enum.BuildDifficulty.Impossible)
        self:UpdatePendingBuild()
    end
    UIDropDownMenu_AddButton(info, level)
end

function EditableBuildViewMixin:InitializeCategoryDropDown(dropdown, level, menuList)
    if not self:IsVisible() then return end
    local info

    info = UIDropDownMenu_CreateInfo()
    info.text = CHANGE_BUILD_CATEGORY
    info.isTitle = true
    UIDropDownMenu_AddButton(info, level)

    if not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        info = UIDropDownMenu_CreateInfo()
        info.text = BUILD_EDITOR_CATEGORY_LEVELING
        info.func = function()
            BuildCreatorFrame:ConvertBuildEditorToCategory(Enum.BuildCreateCategory.Leveling)
        end
        UIDropDownMenu_AddButton(info, level)
    end
    
    local isLevel60 = GetMaxLevel() == 60

    info = UIDropDownMenu_CreateInfo()
    info.text = isLevel60 and BUILD_EDITOR_CATEGORY_LEVEL60PVE or BUILD_EDITOR_CATEGORY_LEVEL70PVE
    info.func = function()
        local category = isLevel60 and Enum.BuildCreateCategory.Level60PvE or Enum.BuildCreateCategory.Level70PvE
        BuildCreatorFrame:ConvertBuildEditorToCategory(category)
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = isLevel60 and BUILD_EDITOR_CATEGORY_LEVEL60PVP or BUILD_EDITOR_CATEGORY_LEVEL70PVP
    info.func = function()
        local category = isLevel60 and Enum.BuildCreateCategory.Level60PvP or Enum.BuildCreateCategory.Level70PvP
        BuildCreatorFrame:ConvertBuildEditorToCategory(category)
    end
    UIDropDownMenu_AddButton(info, level)

    if C_AccountInfo.GetGMLevel() > 0 then
        info = UIDropDownMenu_CreateInfo()
        info.text = BUILD_EDITOR_CATEGORY_BUILDDRAFT
        info.func = function()
            BuildCreatorFrame:ConvertBuildEditorToCategory(Enum.BuildCreateCategory.BuildDraft)
        end
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = BUILD_EDITOR_CATEGORY_BUILDDRAFTENDGAMEPVE
        info.func = function()
            BuildCreatorFrame:ConvertBuildEditorToCategory(Enum.BuildCreateCategory.BuildDraftEndGamePvE)
        end
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = BUILD_EDITOR_CATEGORY_BUILDDRAFTENDGAMEPVP
        info.func = function()
            BuildCreatorFrame:ConvertBuildEditorToCategory(Enum.BuildCreateCategory.BuildDraftEndGamePvP)
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

function EditableBuildViewMixin:OnShow()
    self:UpdatePendingBuild(self.deserializeNext)
    self.deserializeNext = nil
end

function EditableBuildViewMixin:OnHide()
    BuildCreatorUtil.ReleaseHeldSpell()
end

function EditableBuildViewMixin:OnVerticalScroll(offset)
    local lastIndex = 0
    offset = offset + CONTENT_TOP_OFFSET + 5
    for index, categoryData in ipairs(self.categories) do
        if not categoryData.offset or categoryData.offset <= offset then
            lastIndex = index
        else
            break
        end
    end
    self.CategoryScroll:SetSelectedIndex(lastIndex, ScrollListMixin.UpdateType.OnlyNewIndex)
end

function EditableBuildViewMixin:GetCategoryHeader(index)
    local header = self.categories[index] and self.categories[index].header
    if header == "SPELLS_AND_TALENTS" and C_Player:IsDefaultClass() then
        header = "TALENTS"
    end
    return header and (_G["BUILDCREATOR_SECTION_"..header] or "BUILD_CREATOR_SECTION_"..header) or UNKNOWN
end

function EditableBuildViewMixin:SelectCategory(index)
    local data = self.categories[index]
    if not data then return end

    if self.selectedCategory == data then return end
    self.selectedCategory = data
    local frame = self.MainFrame.ScrollFrame
    local minOffset, maxOffset = frame.ScrollBar:GetMinMaxValues()
    local offset = math.clamp(data.offset - CONTENT_TOP_OFFSET, minOffset, maxOffset)
    frame:SetVerticalScroll(offset)
end

function EditableBuildViewMixin:UpdatePendingBuild(deserialize)
    local author = UnitName("player")
    self.MainFrame.Author:SetFormattedText(BUILD_AUTHOR_S, author)
    self.build = C_BuildEditor.GetPendingBuild()

    local content = self.MainFrame.ScrollFrame.Content
    local height = CONTENT_TOP_OFFSET
    local top = content:GetTop()

    if deserialize then
        local sectionText = BuildCreatorUtil.UnpackDescriptionByKeys(self.build.Description)
        for _, section in ipairs(content.sections) do
            section:Deserialize(sectionText[section.category])
        end
        
        self.MainFrame.Name:SetText(self.build.Name)
        self.MainFrame.Icon:SelectIcon("Interface\\Icons\\"..self.build.Icon)
        self.MainFrame.Role:SetRole(self.build.Roles)
        self.MainFrame.PrimaryStat:SetStat(self.build.PrimaryStat)
    end

    self.MainFrame.PrimaryStat:SetShown(C_Player:IsHero())

    local difficulty = self.build.DifficultyRating
    local difficultyColor = BuildCreatorUtil.DifficultyColors[difficulty]
    UIDropDownMenu_SetText(self.MainFrame.DifficultyDropDown, difficultyColor:WrapText(_G[difficulty]))
    UIDropDownMenu_SetText(self.MainFrame.CategoryDropDown, _G["BUILDCREATOR_CATEGORY_"..self.build.Category:upper()])

    local equipment = content.Equipment
    equipment:ClearAllPoints()
    if ShouldShowMysticEnchantSection() then
        equipment:SetPoint("TOPLEFT", content.MysticEnchants, "BOTTOMLEFT", 0, -16)
        equipment:SetPoint("TOPRIGHT", content.MysticEnchants, "BOTTOMRIGHT", 0, -16)
    else
        equipment:SetPoint("TOPLEFT", content.Spells, "BOTTOMLEFT", 0, -16)
        equipment:SetPoint("TOPRIGHT", content.Spells, "BOTTOMRIGHT", 0, -16)
    end

    local description
    local categoryIndex = 1
    for _, section in ipairs(content.sections) do
        local text = section:Serialize(self.build)
        local shouldShowSection = section.category ~= "MYSTIC_ENCHANTS" or ShouldShowMysticEnchantSection()

        if shouldShowSection then
            height = height + section:GetHeight()
            self.categories[categoryIndex] = {
                header = section.category,
                offset = top - section:GetTop(),
            }
            categoryIndex = categoryIndex + 1

            if text then -- sections that dont return text update pending build themselves
                if not description then
                    description = text
                else
                    description = description .. "\n\n" .. text
                end
            end
        end
    end

    for index = categoryIndex, #self.categories do
        self.categories[index] = nil
    end
    self.MainFrame.ScrollFrame.Content:SetHeight(height)
    
    self:UpdateIcon()
    self:UpdateRole()
    self:UpdatePrimaryStat()
    if not deserialize then
        C_BuildEditor.SetDescription(description)
        C_BuildEditor.SetName(self.MainFrame.Name:ToText())
        C_BuildEditor.SetIcon(self.MainFrame.Icon:ToText())
        C_BuildEditor.SetRoles(self.MainFrame.Role:ToText())
        C_BuildEditor.SetPrimaryStat(self.MainFrame.PrimaryStat:ToText())
        if string.isNilOrEmpty(self.build.ID) then
            BuildCreatorFrame:SerializePendingBuild()
        end
    end

    -- update publish button
    local canPublish, failReasons = C_BuildEditor.CanPublishBuild()
    local publishButton = self.Controls.PublishBuild
    if canPublish then
        publishButton.tooltipTitle = nil
        publishButton.tooltipText = nil
        publishButton:Enable()
    else
        publishButton.tooltipTitle = CANNOT_PUBLISH_BUILD
        publishButton.tooltipText = nil
        for _, reason in ipairs(failReasons) do
            if publishButton.tooltipText then
                publishButton.tooltipText = publishButton.tooltipText .. "\n"
            else
                publishButton.tooltipText = ""
            end
            publishButton.tooltipText = publishButton.tooltipText .. (_G[reason] or reason)
        end
        publishButton.tooltipText = RED_FONT_COLOR:WrapText(publishButton.tooltipText)
        publishButton:Disable()
    end
end

function EditableBuildViewMixin:OnEditModeHide()
    self:UpdatePendingBuild()
end

function EditableBuildViewMixin:OnEditModeShow()
    self:UpdatePendingBuild()
end

function EditableBuildViewMixin:LoadPendingBuild()
    
end 

function EditableBuildViewMixin:UpdateIcon()
    local icon = self.MainFrame.Icon:ToText()
    if not icon or icon:len() == 0 then
        icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    C_BuildEditor.SetIcon(icon)
end

function EditableBuildViewMixin:UpdateRole()
    local role = self.MainFrame.Role:ToText()
    if not role or role:len() == 0 then
        role = "PLAYER_ROLE_NONE"
    end
    C_BuildEditor.SetRoles(role)
    local roleKey = BuildCreatorUtil.ConvertBuildRoleToLFGRole(role)
    if roleKey then
        self.MainFrame.ContentBackground:SetTexture("Interface\\BuildCreator\\BCBackground-"..roleKey, "REPEAT", "REPEAT")
        self.MainFrame.Role.tooltipTitle = BUILD_CREATOR_ROLE_S:format(_G[roleKey])
        self.MainFrame.Role.tooltipText = _G["BUILD_CREATOR_ROLE_"..roleKey]
    else
        self.MainFrame.ContentBackground:SetTexture(nil)
        self.MainFrame.Role.tooltipTitle = nil
        self.MainFrame.Role.tooltipText = nil
    end
    if GameTooltip:IsOwned(self.MainFrame.Role) then
        self.MainFrame.Role:CallScript("OnEnter")
    end
end

function EditableBuildViewMixin:UpdatePrimaryStat()
    local stat = self.MainFrame.PrimaryStat:ToText()
    if not stat or stat:len() == 0 then
        stat = "STAT_STRENGTH"
    end
    C_BuildEditor.SetPrimaryStat(stat)
end 

function EditableBuildViewMixin:SetCategory(category)
    self.levelingBuild = category == Enum.BuildCreateCategory.Leveling or category == Enum.BuildCreateCategory.BuildDraft
    C_BuildEditor.SetCategory(category)
end

function EditableBuildViewMixin:IsLevelingBuild()
    return self.levelingBuild
end 

function EditableBuildViewMixin:ImportCurrentBuild()
    self.MainFrame.Icon:SelectIcon("Interface\\Icons\\INV_Misc_QuestionMark")
    self.MainFrame.Role:SetRole("PLAYER_ROLE_NONE")
    local primaryStat = C_PrimaryStat:GetActivePrimaryStat()
    if not primaryStat then
        primaryStat = Enum.PrimaryStat.Strength
    end
    self.MainFrame.PrimaryStat:SetStat(PRIMARY_STAT_STRING[primaryStat])
    
    local spell = BuildCreatorUtil.CreateSpellInfo(0) -- reused
    for _, spellID in ipairs(C_CharacterAdvancement.GetKnownSpells()) do
        -- only add talents if default class, otherwise add everything
        if not C_Player:IsDefaultClass() or C_CharacterAdvancement.IsTalentSpellID(self.spellID) then
            local talentRank = C_CharacterAdvancement.GetTalentRankBySpellID(spellID)
            if talentRank then
                local entry = C_CharacterAdvancement.GetEntryBySpellID(spellID)
                for i = 1, talentRank do
                    spell.Spell = entry.Spells[i]
                    C_BuildEditor.AddSpell(spell)
                end
            else
                spell.Spell = spellID
                C_BuildEditor.AddSpell(spell)
            end
        end
    end
    
    if ShouldShowMysticEnchantSection() then
        local enchant = BuildCreatorUtil.CreateEnchantInfo(0) -- reused
        local isHero = C_Player:IsHero()
        for spellID, stacks in pairs(MysticEnchantUtil.GetAppliedEnchants("player")) do
            local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
            enchant.Enchant = spellID
            enchant.Stacks = stacks
            enchant.Level = isHero and 1 or enchantInfo.RequiredLevel
            C_BuildEditor.AddRandomEnchant(enchant)
        end
    end
    
    self:UpdatePendingBuild(true)
end

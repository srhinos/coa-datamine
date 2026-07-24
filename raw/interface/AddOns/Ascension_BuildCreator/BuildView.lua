BuildViewMixin = {}

local CONTENT_TOP_OFFSET = 52

local function ShouldShowMysticEnchantSection()
    return not C_Player:IsCustomClass() and not C_GameMode:IsGameModeActive(Enum.GameMode.WildCard)
end

function BuildViewMixin:OnLoad()
    self.categories = {}

    self.MainFrame.Background:SetAtlas("buildcreator-view", Const.TextureKit.IgnoreAtlasSize)
    self.MainFrame.SpecIcon.Icon:SetRounded(true)
    self.MainFrame.SpecIcon.Icon:SetBorderSize(48, 48)
    self.MainFrame.Role:SetBackgroundTexture("Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS")
    self.MainFrame.Role:SetBackgroundSize(82, 82)
    self.MainFrame.Role:SetBackgroundAlpha(0.6)
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
end

function BuildViewMixin:SetBuild(build)
    self.build = build

    -- check if we should load an endgame build instead
    -- gms should still go to the normal leveling build first.
    if not C_Player:IsGM() then
        -- if we're looking at a featured build draft build
        if self.build.Category == Enum.BuildCategory.BuildDraft then
            -- and this isnt our active build
            if not BuildCreatorUtil.IsActiveBuildID(self.build.ID) then
                -- and we're max level AND the build has an endgame ID, load that instead
                if C_Player:IsMaxLevel() and self.build.EndGameIDPVE and self.build.EndGameIDPVE:len() > 0 then
                    BuildCreatorFrame:ViewBuildID(self.build.EndGameIDPVE)
                    return
                end
            end
        end
    end
    C_BuildCreator.BookmarkBuild(build.ID)
    self:BuildCategories()
    self.CategoryScroll:RefreshScrollFrame()
    self.CategoryScroll:SetSelectedIndex(1, ScrollListMixin.UpdateType.AlwaysSimulateClick)
    
    self:SetBackground()
    self:SetBuildInfo()
    self:SetAlternateBuilds()
    self:UpdateControlButtons()
end

function BuildViewMixin:SetBuildInfo()
    self.MainFrame.Name:SetText(self.build.Name)
    local authorName = HIGHLIGHT_FONT_COLOR:WrapText(self.build.AuthorName)
    local howLongAgo = SecondsToTime(time() - self.build.UpdatedTime, false, true, 1)

    if self.build.Category == Enum.BuildCategory.BuildDraft then
        self.MainFrame.Author:SetFormattedText(BUILD_AUTHOR_S, authorName)
    else
        self.MainFrame.Author:SetFormattedText(BUILD_AUTHOR_S_S_AGO, authorName, "|cffffffff"..howLongAgo) -- intentional no |r so `ago` is white
    end
    self.MainFrame.Icon:SetIcon("Interface\\Icons\\"..self.build.Icon)
    local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.build.Roles)
    self.MainFrame.Role:SetIconAtlas(ROLE_ATLAS[role])
    self.MainFrame.Role.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
    self.MainFrame.Role.tooltipTitle = BUILD_CREATOR_ROLE_S:format(_G[role])
    self.MainFrame.Role.tooltipText = _G["BUILD_CREATOR_ROLE_"..role]
    if GameTooltip:IsOwned(self.MainFrame.Role) then
        self.MainFrame.Role:CallScript("OnEnter")
    end
    local statID = Enum.PrimaryStat[self.build.PrimaryStat]
    if statID then
        local statSpellID = C_PrimaryStat:GetPrimaryStatInfo(statID)
        self.MainFrame.PrimaryStat:Show()
        self.MainFrame.PrimaryStat.Icon:SetSpell(statSpellID)
        self.MainFrame.PrimaryStat.Icon:SetIconAtlas(PRIMARY_STAT_ATLAS[statID])
        self.MainFrame.PrimaryStat:SetText(GetSpellInfo(statSpellID))
    else
        self.MainFrame.PrimaryStat:Hide()
    end
    self:SetEnchant()
end

function BuildViewMixin:SetAlternateBuilds()
    local pveButton = self.MainFrame.ScrollFrame.Content.AlternateBuild1
    local pvpButton = self.MainFrame.ScrollFrame.Content.AlternateBuild2
    local levelingButton = self.MainFrame.ScrollFrame.Content.AlternateBuild3

    local endGamePVE = self.build.EndGameIDPVE
    local endGamePVP = self.build.EndGameIDPVP
    local levelingBuild = self.build.LevelingID
    
    pveButton:SetEnabled(not string.isNilOrEmpty(endGamePVE))
    pveButton.buildID = endGamePVE
    pvpButton:SetEnabled(not string.isNilOrEmpty(endGamePVP))
    pvpButton.buildID = endGamePVP
    levelingButton:SetEnabled(not string.isNilOrEmpty(levelingBuild))
    levelingButton.buildID = levelingBuild
end

function BuildViewMixin:SetEnchant()
    -- enchant
    local enchant = self.build.LegendaryEnchant
    if not enchant or enchant <= 0 then
        self.MainFrame.SpecIcon:Hide()
    else
        self.MainFrame.SpecIcon:Show()
        self.MainFrame.SpecIcon.Icon:SetSpell(enchant)
        self.MainFrame.SpecIcon.Icon:SetBorderAtlas("EnchantSlotBorderKnownLegendary")
        self.MainFrame.SpecIcon:SetText(GetSpellInfo(enchant))
        self.MainFrame.SpecIcon.Text:SetTextColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:GetRGB())
    end
end

function BuildViewMixin:BuildCategories()
    self.categories = BuildCreatorUtil.UnpackDescription(self.build.Description)
    -- we can assume overview is first
    local top = CONTENT_TOP_OFFSET
    -- insert equipment first
    if #self.build.ArmorTypes > 0 or #self.build.WeaponTypes > 0 then
        tinsert(self.categories, 2, { header = BuildCreatorUtil.DescriptionSection.Equipment })
    end

    -- insert enchants
    if ShouldShowMysticEnchantSection() and #self.build.RandomEnchants > 0 then
        tinsert(self.categories, 2, { header = BuildCreatorUtil.DescriptionSection.MysticEnchants })
    end
    -- insert spells
    if #self.build.Spells > 0 then
        tinsert(self.categories, 2, { header = BuildCreatorUtil.DescriptionSection.SpellsAndTalents })
    end


    if self.MainFrame.ScrollFrame.Content.sections then
        for _, section in ipairs(self.MainFrame.ScrollFrame.Content.sections) do
            section:Hide()
        end
    end

    for i, data in ipairs(self.categories) do
        data.offset = top
        if self["Set_"..data.header] then
            top = top + self["Set_"..data.header](self, data)
        else
            C_Logger.Error("Unknown Build Section: %s", data.header)
        end
    end

    self.MainFrame.ScrollFrame.Content:SetHeight(top)
    self.MainFrame.ScrollFrame:SetVerticalScroll(0)
end

function BuildViewMixin:OnVerticalScroll(offset)
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

function BuildViewMixin:Set_OVERVIEW(data)
    local frame = self.MainFrame.ScrollFrame.Content.Overview
    if not frame then
        -- create overview section
        frame = CreateFrame("Frame", "$parentOverview", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Overview = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end

    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local text = data.text
    if self.build.NumCoreSpells > 0 then
        text = text .. "|n|cff00d1ff" .. CORE .. ":|r " .. self.build.NumCoreSpells
        text = text .. " |cff848484(|r|cffffffff" .. TALENTS .. ":|r " .. self.build.NumCoreTalents
        text = text .. " |cffffffff" .. ABILITIES .. ":|r " .. self.build.NumCoreAbilities .. "|cff848484)|r"
    end

    if self.build.NumOptimalSpells > 0 then
        text = text .. "|n|cff00d1ff" .. OPTIMAL .. ":|r " .. self.build.NumOptimalSpells
        text = text .. " |cff848484(|r|cffffffff" .. TALENTS .. ":|r " .. self.build.NumOptimalTalents
        text = text .. " |cffffffff" .. ABILITIES .. ":|r " .. self.build.NumOptimalAbilities .. "|cff848484)|r"
    end
    
    if self.build.NumEmpoweringSpells > 0 then
        text = text .. "|n|cff00d1ff" .. EMPOWERING .. ":|r " .. self.build.NumEmpoweringSpells
        text = text .. " |cff848484(|r|cffffffff" .. TALENTS .. ":|r " .. self.build.NumEmpoweringTalents
        text = text .. " |cffffffff" .. ABILITIES .. ":|r " .. self.build.NumEmpoweringAbilities .. "|cff848484)|r"
    end
    
    if self.build.NumSynergisticSpells > 0 then
        text = text .. "|n|cff00d1ff" .. SYNERGISTIC .. ":|r " .. self.build.NumSynergisticSpells
        text = text .. " |cff848484(|r|cffffffff" .. TALENTS .. ":|r " .. self.build.NumSynergisticTalents
        text = text .. " |cffffffff" .. ABILITIES .. ":|r " .. self.build.NumSynergisticAbilities .. "|cff848484)|r"
    end
    local height = frame.Text:SetDynamicText(text) + 62
    frame:SetHeight(height)
    
    return height 
end

local function AddHeader(self, specName, classFile, icon, index)
    local header = self.HeaderPool:Acquire()
    header.Icon:SetTexture("Interface\\Icons\\"..icon)
    header:GetNormalTexture():SetVertexColor((RAID_CLASS_COLORS[classFile] or HIGHLIGHT_FONT_COLOR):GetRGB())
    header:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    header:SetFormattedText("%s\n%s", specName, LOCALIZED_CLASS_NAMES_MALE[classFile] or classFile)
    header:Show()
end

local function AddLevelHeader(self, level, currentLevel, index)
    local header = self.HeaderPool:Acquire()
    header.Icon:SetTexture("Interface\\Icons\\spell_holy_innerfire")
    header.Icon:SetDesaturated(level > currentLevel)
    local r, g, b = 0.3, 0.2, 0
    if level == currentLevel then
        r, g, b = 0, 0.4, 0.6
    elseif level > currentLevel then
        r, g, b = 0.2, 0.16, 0.1
    end
        
    header:GetNormalTexture():SetVertexColor(r, g, b)
    header:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    header:SetFormattedText("%s %s", LEVEL, level)
    header:Show()
end

local function AddSpell(self, spell, index)
    local spellIcon = self.IconPool:Acquire()

    if spell.TalentID then
        spellIcon:SetTalent(spell)
    else
        spellIcon:SetSpell(spell)
    end
    spellIcon:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    spellIcon:Show()
    spellIcon:SetEnabled(true)
end

local function AddLevelingSpell(self, spell, level, currentLevel, index)
    local spellIcon = self.IconPool:Acquire()

    if spell.TalentID then
        spellIcon:SetTalent(spell)
    else
        spellIcon:SetSpell(spell)
    end
    spellIcon:SetPoint(GetGridPoint(index, self, 178, 44, 4, 21, -50))
    spellIcon:Show()
    spellIcon:SetEnabled(level <= currentLevel)
end

function BuildViewMixin:Set_SPELLS_AND_TALENTS(data)
    local frame = self.MainFrame.ScrollFrame.Content.Spells
    if not frame then
        -- create spells section
        frame = CreateFrame("Frame", "$parentSpells", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Spells = frame
        frame.IconPool = CreateFramePool("Button", frame, "BuildSpellTemplate")
        frame.HeaderPool = CreateFramePool("Button", frame, "BuildSpellHeaderTemplate")
        frame:SetCategory(data.header)

        frame.FilterCore = CreateFrame("CheckButton", "$parentFilterCore", frame, "SquareIconCheckButtonTemplate")
        frame.FilterCore:SetPoint("LEFT", frame.Icon.Title, "RIGHT", 8, 0)
        frame.FilterCore:SetText(CORE)
        frame.FilterCore:GetFontString():ClearAndSetPoint("LEFT", frame.FilterCore, "RIGHT", 4, 0)
        frame.FilterCore:SetChecked(true)
        frame.FilterCore:SetScript("OnClick", GenerateClosure(self.BuildCategories, self))

        frame.FilterOptimal = CreateFrame("CheckButton", "$parentFilterOptimal", frame, "SquareIconCheckButtonTemplate")
        frame.FilterOptimal:SetPoint("LEFT", frame.FilterCore:GetFontString(), "RIGHT", 8, 0)
        frame.FilterOptimal:SetText(OPTIMAL)
        frame.FilterOptimal:GetFontString():ClearAndSetPoint("LEFT", frame.FilterOptimal, "RIGHT", 4, 0)
        frame.FilterOptimal:SetChecked(true)
        frame.FilterOptimal:SetScript("OnClick", GenerateClosure(self.BuildCategories, self))

        frame.FilterEmpowering = CreateFrame("CheckButton", "$parentFilterEmpowering", frame, "SquareIconCheckButtonTemplate")
        frame.FilterEmpowering:SetPoint("LEFT", frame.FilterOptimal:GetFontString(), "RIGHT", 8, 0)
        frame.FilterEmpowering:SetText(EMPOWERING)
        frame.FilterEmpowering:GetFontString():ClearAndSetPoint("LEFT", frame.FilterEmpowering, "RIGHT", 4, 0)
        frame.FilterEmpowering:SetScript("OnClick", GenerateClosure(self.BuildCategories, self))

        frame.FilterSynergistic = CreateFrame("CheckButton", "$parentFilterSynergistic", frame, "SquareIconCheckButtonTemplate")
        frame.FilterSynergistic:SetPoint("LEFT", frame.FilterEmpowering:GetFontString(), "RIGHT", 8, 0)
        frame.FilterSynergistic:SetText(SYNERGISTIC)
        frame.FilterSynergistic:GetFontString():ClearAndSetPoint("LEFT", frame.FilterSynergistic, "RIGHT", 4, 0)
        frame.FilterSynergistic:SetScript("OnClick", GenerateClosure(self.BuildCategories, self))
    end
    frame.IconPool:ReleaseAll()
    frame.HeaderPool:ReleaseAll()
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    local spells, specs, specInfo
    local index, r = 0, 0

    if self.build.Category == Enum.BuildCategory.Leveling or self.build.Category == Enum.BuildCategory.BuildDraft then
        -- leveling format
        local currentLevel = C_Player:GetLevel()
        local spellsByLevel, spellCount, maxLevel = BuildCreatorUtil.GetSpellsByLevel(self.build)
        for level = 1, maxLevel do
            spells = spellsByLevel[level]
            if spells and #spells > 0 then
                r = index % 4
                if r > 1 then
                    index = index + (4 - r) + 1 -- new row
                elseif r == 0 then
                    index = index + 1
                end
                AddLevelHeader(frame, level, currentLevel, index)
                index = index + 4

                -- list spells
                for _, spell in ipairs(spells) do
                    x, y = AddLevelingSpell(frame, spell, level, currentLevel, index)
                    index = index + 1
                end
            end
        end
    else
        -- regular format
        local spellsByClass, spellCount = BuildCreatorUtil.GetSpellsByClass(self.build, frame.FilterCore:GetChecked(), frame.FilterOptimal:GetChecked(), frame.FilterSynergistic:GetChecked(), frame.FilterEmpowering:GetChecked())

        if spellsByClass["GENERAL"] then
            r = index % 4
            if r > 1 then
                index = index + (4 - r) + 1 -- new row
            elseif r == 0 then
                index = index + 1
            end
            AddHeader(frame, "General", "", "classicon_hero", index)
            index = index + 4
            for _, spell in ipairs(spellsByClass["GENERAL"]["GENERAL1"]) do
                AddSpell(frame, spell, index)
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
                        AddHeader(frame, specInfo.Name, classFile, specInfo.SpecFilename, index)
                        index = index + 4
                        -- list spells
                        for _, spell in ipairs(specSpells) do
                            AddSpell(frame, spell, index)
                            index = index + 1
                        end
                    end
                end
            end
        end
    end
    
    local height = 50 + (44 * math.ceil(index / 4))
    frame:SetHeight(height)
    return height
end

function BuildViewMixin:Set_MYSTIC_ENCHANTS(data)
    local frame = self.MainFrame.ScrollFrame.Content.MysticEnchants
    if not frame then
        frame = CreateFrame("Frame", "$parentMysticEnchants", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.MysticEnchants = frame
        frame.IconPool = CreateFramePool("Button", frame, "BuildEnchantTemplate")
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    local index = 1

    frame.IconPool:ReleaseAll()
    -- show grid of enchants
    for i, enchant in ipairs(self.build.RandomEnchants) do
        local enchantIcon = frame.IconPool:Acquire()
        enchantIcon:SetEnchant(enchant)
        enchantIcon:SetPoint(GetGridPoint(index, frame, 198, 44, 4, 21, -50))
        enchantIcon:Show()
        index = index + 1
    end
    
    local height = 50 + (44 * math.ceil(index / 4))
    frame:SetHeight(height)
    return height
end

function BuildViewMixin:Set_EQUIPMENT(data)
    local frame = self.MainFrame.ScrollFrame.Content.Equipment
    if not frame then
        frame = CreateFrame("Frame", "$parentEquipment", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Equipment = frame
        frame.IconPool = CreateFramePool("Button", frame, "BuildSpellTemplate")
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()

    frame.IconPool:ReleaseAll()

    local index = 1
    -- show grid of armor
    for i, armor in ipairs(self.build.ArmorTypes) do
        local icon = frame.IconPool:Acquire()
        icon:SetEquipment(armor)
        icon:SetPoint(GetGridPoint(index, frame, 178, 44, 4, 21, -50))
        icon:Show()
        index = index + 1
    end

    -- show grid of weapons
    for i, weapon in ipairs(self.build.WeaponTypes) do
        local icon = frame.IconPool:Acquire()
        icon:SetEquipment(weapon)
        icon:SetPoint(GetGridPoint(index, frame, 178, 44, 4, 21, -50))
        icon:Show()
        index = index + 1
    end

    local height = 50 + (44 * math.ceil(index / 4))
    frame:SetHeight(height)
    return height
end

function BuildViewMixin:Set_PROS_AND_CONS(data)
    local frame = self.MainFrame.ScrollFrame.Content.ProsAndCons
    if not frame then
        -- create overview section
        frame = CreateFrame("Frame", "$parentProsAndCons", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.ProsAndCons = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end

    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    
    local text = BuildCreatorUtil.FormatProsAndCons(data.text)
    
    local height = frame.Text:SetDynamicText(text) + 62
    frame:SetHeight(height)

    return height
end

function BuildViewMixin:Set_ITEMIZATION(data)
    local frame = self.MainFrame.ScrollFrame.Content.Itemization
    if not frame then
        -- create itemization
        -- just a basic text display
        frame = CreateFrame("Frame", "$parentItemization", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Itemization = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height + 16
end

function BuildViewMixin:Set_ROTATION(data)
    local frame = self.MainFrame.ScrollFrame.Content.Rotation
    if not frame then
        -- create rotation section
        -- just a basic text display
        frame = CreateFrame("Frame", "$parentRotation", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Rotation = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    frame.Text:SetHeight(0)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height
end

function BuildViewMixin:Set_CONSUMABLES(data)
    local frame = self.MainFrame.ScrollFrame.Content.Consumables
    if not frame then
        -- create consumables section
        -- just a basic text display
        frame = CreateFrame("Frame", "$parentConsumables", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Consumables = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height
end

function BuildViewMixin:Set_MACROS(data)
    local frame = self.MainFrame.ScrollFrame.Content.Macros
    if not frame then
        -- create macros section
        -- code block text display
        frame = CreateFrame("Frame", "$parentMacros", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Macros = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
        
        frame.CopyButton = CreateFrame("Button", "$parentCopyButton", frame, "CopyButtonTemplate")
        frame.CopyButton:SetPoint("LEFT", frame.Icon.Title, "RIGHT", 4, 0)
        frame.CopyButton:SetSize(32, 32)
        frame.CopyButton:SetScript("OnClick", function()
            local text = frame.Text:GetText()
            if text then
                Internal_CopyToClipboard(text)
                SendSystemMessage(S_COPIED_TO_CLIPBOARD:format(BUILDCREATOR_SECTION_MACROS))
            end
        end)
        frame.CopyButton.tooltipTitle = COPY_TO_CLIPBOARD
    end

    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height
end

function BuildViewMixin:Set_WEAKAURAS(data)
    local frame = self.MainFrame.ScrollFrame.Content.WeakAuras
    if not frame then
        -- create weakauras section
        -- just a basic text display
        frame = CreateFrame("Frame", "$parentWeakAuras", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.WeakAuras = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end
    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height
end

function BuildViewMixin:Set_NOTES(data)
    local frame = self.MainFrame.ScrollFrame.Content.Notes
    if not frame then
        -- create notes section
        -- just a basic text display
        frame = CreateFrame("Frame", "$parentNotes", self.MainFrame.ScrollFrame.Content, "BuildViewSectionTemplate")
        self.MainFrame.ScrollFrame.Content.Notes = frame
        frame.Text = CreateFrame("SimpleHTML", "$parentText", frame, "BuildSimpleHTMLTemplate")
        frame.Text:SetPoint("TOPLEFT", 58, -36)
        frame.Text:SetPoint("TOPRIGHT", -58, -36)
        frame.Text:SetSize(648, 0)
        frame:SetCategory(data.header)
    end

    frame:SetPoint("TOPLEFT", 0, -data.offset)
    frame:SetPoint("TOPRIGHT", 0, -data.offset)
    frame:Show()
    frame:SetHeight(2000)
    local height = frame.Text:SetDynamicText(data.text) + 62
    frame:SetHeight(height)

    return height
end


function BuildViewMixin:GetCategoryHeader(index)
    return self.categories[index] and (_G["BUILDCREATOR_SECTION_"..self.categories[index].header] or self.categories[index].header) or UNKNOWN
end

function BuildViewMixin:SelectCategory(index)
    local data = self.categories[index]
    if not data then return end
    
    if self.selectedCategory == data then return end
    self.selectedCategory = data
    local frame = self.MainFrame.ScrollFrame
    local minOffset, maxOffset = frame.ScrollBar:GetMinMaxValues()
    local offset = math.clamp(data.offset - CONTENT_TOP_OFFSET, minOffset, maxOffset)
    frame:SetVerticalScroll(offset)
end

function BuildViewMixin:SetBackground()
    local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.build.Roles)
    self.MainFrame.ContentBackground:SetTexture("Interface\\BuildCreator\\BCBackground-"..role, "REPEAT", "REPEAT")
end

function BuildViewMixin:OnActivateButtonClicked()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        C_BuildCreator.BookmarkBuild(self.build.ID)
        Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
        WildCardRapidRollingFrame:Show()
        WildCardRapidRollingFrame:ShowImportHint()
        return
    end
    BuildCreatorUtil.ToggleBuildActive(self.build.ID, self.build.Category, self.Controls.AutoLearn:GetBoolValue())
end

function BuildViewMixin:UpdateControlButtons()
    local activateButton = self.Controls.ActivateBuildButton
    if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
        activateButton:SetText(RAPID_ROLL_THIS_BUILD)
        activateButton:SetEnabled(C_Wildcard.CanUseRapidRolling())
    elseif BuildCreatorUtil.IsActiveBuildID(self.build.ID) then
        activateButton:SetText(DEACTIVATE_BUILD)
        activateButton:Enable()
    else
        activateButton:SetText(ACTIVATE_BUILD)
        activateButton:SetEnabled(C_BuildCreator.CanActivateBuild(self.build.ID))
    end
    
    local canEdit = C_BuildCreator.IsOwnedBuild(self.build.ID)
    local isGM = C_AccountInfo.GetGMLevel() >= 4

    local editBuildButton = self.Controls.EditBuildButton
    local deleteBuildButton = self.Controls.DeleteBuildButton
    
    deleteBuildButton:SetShown(canEdit or isGM)
    editBuildButton:SetShown(canEdit or isGM)
    if not canEdit and isGM then
        editBuildButton:SetFormattedText("(GM)%s", EDIT_BUILD)
        deleteBuildButton:SetFormattedText("(GM)%s", DELETE_BUILD)
    else
        editBuildButton:SetText(EDIT_BUILD)
        deleteBuildButton:SetText(DELETE_BUILD)
    end
end

function BuildViewMixin:ToggleBuildActive(autoLearn)
    BuildCreatorUtil.ToggleBuildActive(self.build.ID, self.build.Category, autoLearn)
end 

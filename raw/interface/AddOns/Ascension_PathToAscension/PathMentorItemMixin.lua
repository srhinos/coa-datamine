PathMentorItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function PathMentorItemMixin:OnLoad()
    self.Background:SetAtlas("Rewards-Shadow", Const.TextureKit.IgnoreAtlasSize)
    self.Background2:SetAtlas("Rewards-Top", Const.TextureKit.IgnoreAtlasSize)
    self.IconBorder:SetAtlas("pvpqueue-rewardring-large", Const.TextureKit.IgnoreAtlasSize)
    self.Highlight:SetAtlas("professions_recipe_hover", Const.TextureKit.IgnoreAtlasSize)
    
    self:RegisterForClicks("RightButtonUp")
    
    self.SpecIcons = CreateFramePool("BUTTON", self, "PTAMentorSpecializationIconTemplate")

    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.GenerateDropDown, self), "MENU", 1)
end

function PathMentorItemMixin:Update()
    local name, level, class, specializations, race, sex = C_Tutorial.GetAvailableMentorAtIndex(self.index)
    self.name = name

    class = CLASS_ENUM_TO_CLASS_FILE[class] or class:sub(7)
    local classColor = RAID_CLASS_COLORS[class]
    local className = LOCALIZED_CLASS_NAMES_MALE[class]
    sex = sex:sub(8)
    race = race:sub(6)
    if race == "UNDEAD_PLAYER" then
        race = "SCOURGE"
    end
    local coords = RACE_ICON_TCOORDS[race.."_"..sex]
    self.Icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CHARACTERCREATE-RACES_Round")
    self.Icon:SetTexCoord(unpack(coords))

    local fullName = name.."  "..string.format(UNIT_TYPE_LEVEL_TEMPLATE, level, classColor:WrapText(className))
    self.Name:SetText(fullName)
    
    self.SpecIcons:ReleaseAll()
    local lastIcon
    for _, specID in ipairs(specializations) do
        local specName, atlas = C_Tutorial.GetMentorSpecializationInfo(specID)
        atlas = TutorialUtil.ConvertDynamicMentorIcon(atlas)
        local icon = self.SpecIcons:Acquire()
        icon:SetNormalAtlas(atlas)
        icon:SetHighlightAtlas(atlas)
        if lastIcon then
            icon:SetPoint("LEFT", lastIcon, "RIGHT", 4, 0)
        else
            icon:SetPoint("TOPLEFT", self.Name, "BOTTOMLEFT", 0, 0)
        end
        
        icon.tooltip = specName
        icon:Show()
        
        lastIcon = icon
    end
end 

function PathMentorItemMixin:GenerateDropDown(dropdown, level, menulist)
    if not self.name then
        CloseDropDownMenus()
        return
    end

    local info = UIDropDownMenu_CreateInfo()
    info.text = self.name
    info.isTitle = true
    UIDropDownMenu_AddButton(info)

    -- Whisper
    info = UIDropDownMenu_CreateInfo()
    info.text = WHISPER
    info.func = function() ChatFrame_SendTell(self.name) end
    UIDropDownMenu_AddButton(info)
    
    -- Cancel
    info = UIDropDownMenu_CreateInfo()
    info.text = CANCEL
    info.func = function() CloseDropDownMenus() end
    UIDropDownMenu_AddButton(info)
end

function PathMentorItemMixin:OnClick(button)
    CloseDropDownMenus()
    if button == "RightButton" then
        ToggleDropDownMenu(1, nil, self.DropDown, "cursor", 0, 0)
    end
end 
--
-- Build Icon
--

EditableBuildIconMixin = CreateFromMixins(BorderIconTemplateMixin, EditableBuildElementMixin)

function EditableBuildIconMixin:OnLoad()
    self.EditOverlay.Highlight:SetTexture("Interface\\Common\\ShadowCircle")
    self.EditOverlay.Highlight:SetPoint("TOPLEFT", -12, 12)
    self.EditOverlay.Highlight:SetPoint("BOTTOMRIGHT", 12, -12)
    self.IconSelector:RegisterCallback("IconSelected", function(_, icon)
        self:SelectIcon(icon)
    end)
    self.selectedIcon = "INV_Misc_QuestionMark"
    self:SetIcon(self.selectedIcon)
end

function EditableBuildIconMixin:ShowEditMode()
    self.IconSelector:Show()
end

function EditableBuildIconMixin:HideEditMode()
    self.IconSelector:Hide()
end

function EditableBuildIconMixin:SelectIcon(icon)
    self:SetIcon(icon)
    self.selectedIcon = icon:sub(17) -- ("Interface\\Icons\\"):len()+1
    self:HideEditModeIfEditing()
end

function EditableBuildIconMixin:IsEditMode()
    return self.IconSelector:IsShown()
end

function EditableBuildIconMixin:OnClick()
    self:StartEditing()
end

function EditableBuildIconMixin:ToText()
    return self.selectedIcon
end

--
-- Role icon
--

EditableBuildRoleMixin = CreateFromMixins(BorderIconTemplateMixin, EditableBuildElementMixin)

function EditableBuildRoleMixin:OnLoad()
    self.EditOverlay.Highlight:SetTexture("Interface\\Common\\ShadowCircle")
    self.EditOverlay.Highlight:SetPoint("TOPLEFT", -8, 8)
    self.EditOverlay.Highlight:SetPoint("BOTTOMRIGHT", 8, -8)
    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self))
    self:SetBackgroundTexture("Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS")
    self:SetBackgroundSize(82, 82)
    self:SetBackgroundAlpha(0.6)

    self.selectedRole = "PLAYER_ROLE_DAMAGE"
    local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.selectedRole)
    if role then
        self:SetIconAtlas(ROLE_ATLAS[role])
        self.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
    end
end

function EditableBuildRoleMixin:InitializeDropDown(dropdown)
    local function SetRole(button)
        self:SetRole(button.value)
        self:HideEditModeIfEditing()
    end

    -- Tank
    local info = UIDropDownMenu_CreateInfo()
    info.value = "PLAYER_ROLE_TANK"
    info.text = ROLE_TEXT_WITH_ICON["TANK"]
    info.func = SetRole
    UIDropDownMenu_AddButton(info)

    info = UIDropDownMenu_CreateInfo()
    info.value = "PLAYER_ROLE_DAMAGE"
    info.text = ROLE_TEXT_WITH_ICON["DAMAGER"]
    info.func = SetRole
    UIDropDownMenu_AddButton(info)

    info = UIDropDownMenu_CreateInfo()
    info.value = "PLAYER_ROLE_HEALER"
    info.text = ROLE_TEXT_WITH_ICON["HEALER"]
    info.func = SetRole
    UIDropDownMenu_AddButton(info)
end

function EditableBuildRoleMixin:ShowEditMode()
    ToggleDropDownMenu(1, nil, self.DropDown, self:GetName(), 0, -5)
end

function EditableBuildRoleMixin:HideEditMode()
    CloseDropDownMenus()
end

function EditableBuildRoleMixin:SetRole(role)
    self.selectedRole = role
    role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.selectedRole)
    if role then
        self:SetIconAtlas(ROLE_ATLAS[role])
        self.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
    else
        self:SetIconAtlas("ui-lfg-roleicon-pending")
        self.Background:SetTexCoord(0,0,0,0)
    end
end

function EditableBuildRoleMixin:IsEditMode()
    return UIDROPDOWNMENU_OPEN_MENU == self.DropDown and DropDownList1:IsShown()
end

function EditableBuildRoleMixin:OnClick()
    self:StartEditing()
end

function EditableBuildRoleMixin:ToText()
    return self.selectedRole
end

--
-- Stat Icon
--

EditableBuildPrimaryStatMixin = CreateFromMixins(SpellIconTemplateMixin, EditableBuildElementMixin)

function EditableBuildPrimaryStatMixin:OnLoad()
    SpellIconTemplateMixin.OnLoad(self)
    self.EditOverlay.Highlight:SetTexture("Interface\\Common\\ShadowCircle")
    self.EditOverlay.Highlight:SetPoint("TOPLEFT", -6, 6)
    self.EditOverlay.Highlight:SetPoint("BOTTOMRIGHT", 2, -2)
    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self))

    self.selectedStat = "STAT_STRENGTH"
    local statID = Enum.PrimaryStat[self.selectedStat]
    if statID then
        self:SetSpell(C_PrimaryStat:GetPrimaryStatInfo(statID))
        self:SetIconAtlas(PRIMARY_STAT_ATLAS[statID])
    end
end

function EditableBuildPrimaryStatMixin:InitializeDropDown(dropdown)
    local function SetStat(button)
        self:SetStat(button.value)
        self:HideEditModeIfEditing()
    end

    local info = UIDropDownMenu_CreateInfo()
    info.value = "STAT_STRENGTH"
    info.text = PRIMARY_STAT_TEXT_WITH_ICON["STAT_STRENGTH"]
    info.func = SetStat
    UIDropDownMenu_AddButton(info)

    info = UIDropDownMenu_CreateInfo()
    info.value = "STAT_AGILITY"
    info.text = PRIMARY_STAT_TEXT_WITH_ICON["STAT_AGILITY"]
    info.func = SetStat
    UIDropDownMenu_AddButton(info)

    info = UIDropDownMenu_CreateInfo()
    info.value = "STAT_INTELLECT"
    info.text = PRIMARY_STAT_TEXT_WITH_ICON["STAT_INTELLECT"]
    info.func = SetStat
    UIDropDownMenu_AddButton(info)

    info = UIDropDownMenu_CreateInfo()
    info.value = "STAT_SPIRIT"
    info.text = PRIMARY_STAT_TEXT_WITH_ICON["STAT_SPIRIT"]
    info.func = SetStat
    UIDropDownMenu_AddButton(info)
end

function EditableBuildPrimaryStatMixin:ShowEditMode()
    ToggleDropDownMenu(1, nil, self.DropDown, self:GetName(), 0, -5)
end

function EditableBuildPrimaryStatMixin:HideEditMode()
    CloseDropDownMenus()
end

function EditableBuildPrimaryStatMixin:SetStat(stat)
    self.selectedStat = stat
    local statID = Enum.PrimaryStat[self.selectedStat]
    if statID then
        self:SetSpell(C_PrimaryStat:GetPrimaryStatInfo(statID))
        self:SetIconAtlas(PRIMARY_STAT_ATLAS[statID])
    end
end

function EditableBuildPrimaryStatMixin:IsEditMode()
    return UIDROPDOWNMENU_OPEN_MENU == self.DropDown and DropDownList1:IsShown()
end

function EditableBuildPrimaryStatMixin:OnClick()
    self:StartEditing()
end

function EditableBuildPrimaryStatMixin:OnEnter()
    SpellIconTemplateMixin.OnEnter(self)
    EditableBuildElementMixin.OnEnter(self)
end

function EditableBuildPrimaryStatMixin:OnLeave()
    SpellIconTemplateMixin.OnLeave(self)
    EditableBuildElementMixin.OnLeave(self)
end

function EditableBuildPrimaryStatMixin:ToText()
    return self.selectedStat
end
CoASpecChoiceMixin = {}

CoASpecChoiceMixin.State = {
    Active = 1,
    Inactive = 2,
    Disabled = 3,
}

function CoASpecChoiceMixin:OnLoad()
    self.ColumnDivider:SetAtlas("spec-columndivider", Const.TextureKit.IgnoreAtlasSize)
    self.HoverBackground:SetAtlas("spec-hover-background", Const.TextureKit.IgnoreAtlasSize)
    
    self.pools = CreateFramePoolCollection()

    self.selectedBackground = {
        back  = { self.SelectedBackgroundBack1, self.SelectedBackgroundBack2 },
        left  = { self.SelectedBackgroundLeft1, self.SelectedBackgroundLeft2, self.SelectedBackgroundLeft3, self.SelectedBackgroundLeft4 },
        right = { self.SelectedBackgroundRight1, self.SelectedBackgroundRight2, self.SelectedBackgroundRight3, self.SelectedBackgroundRight4 },
    }
    
    self.activatedBackground = {
        back = { self.ActivatedBackgroundBack1, self.ActivatedBackgroundBack2 },
        left = { self.ActivatedBackgroundLeft1, self.ActivatedBackgroundLeft2, self.ActivatedBackgroundLeft3, self.ActivatedBackgroundLeft4 },
        right = { self.ActivatedBackgroundRight1, self.ActivatedBackgroundRight2, self.ActivatedBackgroundRight3, self.ActivatedBackgroundRight4 },
    }

    self.SelectedBackgroundBack1:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundBack2:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)

    self.SelectedBackgroundLeft1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundLeft4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)

    self.SelectedBackgroundRight1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)
    self.SelectedBackgroundRight1:FlipX()
    self.SelectedBackgroundRight2:FlipX()
    self.SelectedBackgroundRight3:FlipX()
    self.SelectedBackgroundRight4:FlipX()

    self.ActivatedBackgroundBack1:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundBack2:SetAtlas("spec-selected-background1", Const.TextureKit.UseAtlasSize)

    self.ActivatedBackgroundLeft1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundLeft4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)

    self.ActivatedBackgroundRight1:SetAtlas("spec-selected-background2", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight2:SetAtlas("spec-selected-background3", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight3:SetAtlas("spec-selected-background4", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight4:SetAtlas("spec-selected-background5", Const.TextureKit.UseAtlasSize)
    self.ActivatedBackgroundRight1:FlipX()
    self.ActivatedBackgroundRight2:FlipX()
    self.ActivatedBackgroundRight3:FlipX()
    self.ActivatedBackgroundRight4:FlipX()

    self.SpecInfo.Separator.topPadding = 12
    self.SpecInfo.Separator.bottomPadding = 12
end

function CoASpecChoiceMixin:OnHide()
    self:StopActiveFX()
end

function CoASpecChoiceMixin:SetSpecInfo(specInfo, width, height, isLeftMost, isRightMost)
    self.nextLayoutIndex = CreateCounter()
    self.SpecInfo.Name.layoutIndex = self.nextLayoutIndex()
    self.specInfo = specInfo
    self.descriptionWidth = width * 0.6

    self:SetSize(width, height)
    FrameUtil.SetRegionsSize(self.selectedBackground.back, width, height+24)
    FrameUtil.SetRegionsHeight(self.selectedBackground.left, height+24)
    FrameUtil.SetRegionsHeight(self.selectedBackground.right, height+24)
    FrameUtil.SetRegionsSize(self.activatedBackground.back, width, height+24)
    FrameUtil.SetRegionsHeight(self.activatedBackground.left, height+24)
    FrameUtil.SetRegionsHeight(self.activatedBackground.right, height+24)

    local atlasName = CharacterAdvancementUtil.GetThumbnailAtlas(specInfo.Class, specInfo.Spec)
    self.Banner.Image:SetAtlas(atlasName)
    self.Banner.ImageHover:SetAtlas(atlasName)

    self.isLeftMostSpec = isLeftMost
    self.isRightMostSpec = isRightMost

    self.SpecInfo.Name:SetText(specInfo.Name)
    self:CreateRoles()
    self.SpecInfo.Separator.layoutIndex = self.nextLayoutIndex()
    self.SpecInfo.Description.layoutIndex = self.nextLayoutIndex()
    self:CreateAdditionalInfo()

    self.SpecInfo.Separator:SetAtlas("spec-dividerline", Const.TextureKit.IgnoreAtlasSize)
    self.SpecInfo.ComplexitySeparator:SetAtlas("spec-dividerline", Const.TextureKit.IgnoreAtlasSize)

    self.SpecInfo.Complexity:ClearAllPoints()
    self.SpecInfo.Complexity:SetPoint("BOTTOM", self.SampleAbilities.Label, "TOP", 0, 16)
    self.SpecInfo.ComplexitySeparator:ClearAllPoints()
    self.SpecInfo.ComplexitySeparator:SetPoint("TOP", self.SpecInfo.Complexity, "BOTTOM", 0, -8)
    self.SpecInfo.Description:SetWidth(self.descriptionWidth)
    self.SpecInfo.Description:SetText(specInfo.Description)
    self.SpecInfo.Description.bottomPadding = math.max(0, 58-self.SpecInfo.Description:GetHeight())

    self.SpecInfo.fixedHeight = height -188

    local complexity = _G["SPEC_COMPLEXITY_"..specInfo.DifficultyRating:upper()]
    if not complexity then
        C_Logger.Error("Spec: %s has no DifficultyRating!", specInfo.Spec)
        self.SpecInfo.Complexity:SetText("")
    else
        self.SpecInfo.Complexity:SetText(COMPLEXITY_COLORS[specInfo.DifficultyRating]:WrapText(complexity))
    end

    self:CreateSampleAbilities()
    self.SpecInfo:MarkDirty()
end

function CoASpecChoiceMixin:LeftAlignIconText(frame)
    frame:SetWidth(self.descriptionWidth)
    frame.Icon:ClearAllPoints()
    frame.Icon:SetPoint("LEFT", 0, 0)
    frame.Text:ClearAllPoints()
    frame.Text:SetPoint("LEFT", frame.Icon, "RIGHT", 4, 0)
    frame.Text:SetJustifyH("LEFT")
end

function CoASpecChoiceMixin:CreateRoles()
    local roles = {}
    if self.specInfo.MeleeDPS then
        tinsert(roles, "MeleeDPS")
    end
    if self.specInfo.RangedDPS then
        tinsert(roles, "RangedDPS")
    end
    if self.specInfo.CasterDPS then
        tinsert(roles, "CasterDPS")
    end
    if self.specInfo.Healer then
        tinsert(roles, "Healer")
    end
    if self.specInfo.Tank then
        tinsert(roles, "Tank")
    end
    if self.specInfo.Support then
        tinsert(roles, "Support")
    end

    if #roles == 0 then
        return
    end

    local containerPool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecRoleContainerTemplate")
    local container = containerPool:Acquire()
    container.layoutIndex = self.nextLayoutIndex()
    container:Show()

    local rolePool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecRoleTemplate")
    for i, role in ipairs(roles) do
        local roleFrame = rolePool:Acquire()
        roleFrame:SetParent(container)
        roleFrame.layoutIndex = i
        roleFrame:SetRole(role)
        roleFrame:Show()
    end

    container:Layout()
end

function CoASpecChoiceMixin:CreateAdditionalInfo()
    self:CreatePrimaryStats()
end

function CoASpecChoiceMixin:CreatePrimaryStats()
    local containerPool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecStatContainerTemplate")
    local container = containerPool:Acquire()
    container:ClearAllPoints()
    container:SetPoint("BOTTOM", self.SpecInfo.Complexity, "TOP", 0, 16)
    container:Show()

    local statPool = self.pools:GetOrCreatePool("Frame", self.SpecInfo, "CoASpecStatTemplate")
    for i, primaryStat in ipairs(self.specInfo.PrimaryStats) do
        local statButton = statPool:Acquire()
        statButton:SetParent(container)
        statButton.layoutIndex = i
        statButton:SetStat(primaryStat)
        statButton:Show()
    end

    container:Layout()
end

function CoASpecChoiceMixin:CreateSampleAbilities()
    local index = 1
    local pool = self.pools:GetOrCreatePool("Button", self.SampleAbilities, "CoASampleAbilityTemplate")
    local icon = pool:Acquire()
    icon:SetSpell(self.specInfo.PassiveSpell)
    icon.layoutIndex = index
    index = index + 1
    icon:Show()

    for _, spellID in ipairs(self.specInfo.ExampleSpells) do
        icon = pool:Acquire()
        icon:SetSpell(spellID)
        icon.layoutIndex = index
        index = index + 1
        icon:Show()
    end
    
    self.SampleAbilities:MarkDirty()
end

function CoASpecChoiceMixin:UpdateVisualState(isActiveSpecID)
    if not self.specInfo then
        return self:SetVisualState(CoASpecChoiceMixin.State.Inactive)
    end

    if isActiveSpecID then
        return self:SetVisualState(CoASpecChoiceMixin.State.Active)
    end

    if not C_CharacterAdvancement.CanSwitchActiveChrSpec(self.specInfo.ID) then
        return self:SetVisualState(CoASpecChoiceMixin.State.Disabled)
    end
    
    return self:SetVisualState(CoASpecChoiceMixin.State.Inactive)
end 

function CoASpecChoiceMixin:SetVisualState(visualState)
    self.visualState = visualState
    self.SelectButton:SetEnabled(visualState ~= CoASpecChoiceMixin.State.Disabled)

    if visualState == CoASpecChoiceMixin.State.Inactive then
        self:SetInactiveVisual()
    elseif visualState == CoASpecChoiceMixin.State.Active then
        self:SetActiveVisual()
    elseif visualState == CoASpecChoiceMixin.State.Disabled then
        self:SetDisabledVisual()
    end
end 

function CoASpecChoiceMixin:PlayActiveFX()
    self.FXFrame:PlayActivateFX()

    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Play()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Play()
    end
end

function CoASpecChoiceMixin:StopActiveFX()
    self.FXFrame:StopActivateFX()

    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Stop()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Stop()
    end
end

function CoASpecChoiceMixin:SetActiveVisual()
    self.SelectButton:SetText(VIEW_TALENTS)
    self.SelectButton.ActiveText:Show()
    self:SetBannerStateActive(true)
    self:SetDesaturated(false)
    self:SetSelectedBackgroundState(true)
    
    self.FXFrame:PlayActivateFX()
    
    for _, texture in ipairs(self.activatedBackground.left) do
        texture.Flash:Play()
    end

    for _, texture in ipairs(self.activatedBackground.right) do
        texture.Flash:Play()
    end
end

function CoASpecChoiceMixin:SetInactiveVisual()
    self.SelectButton:SetText(ACTIVATE_TALENTS)
    self.SelectButton.ActiveText:Hide()
    self:SetBannerStateActive(false)
    self:SetDesaturated(false)
    self:SetSelectedBackgroundState(false)
end

function CoASpecChoiceMixin:SetDisabledVisual()
    self.SelectButton:SetText(DISABLED)
    self.SelectButton.ActiveText:Hide()
    self:SetBannerStateActive(false)
    self:SetDesaturated(true)
    self:SetSelectedBackgroundState(false)
end

function CoASpecChoiceMixin:SetSelectedBackgroundState(active)
    FrameUtil.SetRegionsShown(self.selectedBackground.back, active)
    if self.isLeftMostSpec then
        FrameUtil.SetRegionsShown(self.selectedBackground.right, active)
    elseif self.isRightMostSpec then
        FrameUtil.SetRegionsShown(self.selectedBackground.left, active)
    else
        FrameUtil.SetRegionsShown(self.selectedBackground.left, active)
        FrameUtil.SetRegionsShown(self.selectedBackground.right, active)
    end
end

function CoASpecChoiceMixin:SetBannerStateActive(active)
    local borderAtlas = "spec-thumbnailborder-"..(active and "on" or "off")
    self.Banner.BorderNormal:SetAtlas(borderAtlas)
    self.Banner.BorderHover:SetAtlas(borderAtlas)
end

function CoASpecChoiceMixin:SetDesaturated(desaturate)
    self.Banner.Image:SetDesaturated(desaturate)
    self.Banner.ImageHover:SetDesaturated(desaturate)
end

function CoASpecChoiceMixin:SetHoverStateActive(active)
    self.HoverBackground:SetShown(active)
    self.Banner.ImageHover:SetShown(active)
    self.Banner.BorderHover:SetShown(active)
end

function CoASpecChoiceMixin:OnSelected()
    if self.visualState == CoASpecChoiceMixin.State.Inactive then
        self:GetParent():GetParent():ChangeSpecID(self.specInfo.ID)
    else
        self:GetParent():GetParent():ShowTreeView()
    end
end 

function CoASpecChoiceMixin:GetSpecID()
    return self.specInfo and self.specInfo.ID
end 

function CoASpecChoiceMixin:SetDividerShown(show)
    self.ColumnDivider:SetShown(show)
end 

function CoASpecChoiceMixin:OnEnter()
    self:SetHoverStateActive(true)
end 

function CoASpecChoiceMixin:OnLeave()
    if not DoesAncestryInclude(self, GetMouseFocus()) then
        self:SetHoverStateActive(false)
    end
end 
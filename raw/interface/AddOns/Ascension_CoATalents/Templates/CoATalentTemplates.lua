CoATalentButtonMixin = CreateFromMixins("CATalentBaseMixin")

function CoATalentButtonMixin:OnLoad()
    CATalentBaseMixin.OnLoad(self)
    self.Icon:SetBackgroundInset(-20, -20, -20, -20)
    self.Icon:SetBorderInset(-2, -2, -2, -2)
    self.Icon:SetOverlayInset(-2, -2, -2, -2)
    self.Icon:SetHighlightInset(-2, -2, -2, -2)
    self:SetShowSingleRanks(true)
    self:SetShowZeroMultiRanks(true)
    self.RankFrame:ShowMaxRank(true)
    self.RankFrame:SetMaxRankSeparator("/")
end

function CoATalentButtonMixin:SetEntry(entry)
    CATalentBaseMixin.SetEntry(self, entry)
end

CoATalentButtonSquareMixin = CreateFromMixins("CoATalentButtonMixin")

function CoATalentButtonSquareMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
end

function CoATalentButtonSquareMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(0, 0, 0, 0)
        self.Icon:SetOverlayInset(0, 0, 0, 0)
        self.Icon:SetHighlightInset(0, 0, 0, 0)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
    end
end

CoATalentButtonCircleMixin = CreateFromMixins("CoATalentButtonMixin")

function CoATalentButtonCircleMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
end

function CoATalentButtonCircleMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeCircle)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
    end
end

CoATalentButtonHexMixin = CreateFromMixins("CoATalentButtonMixin")

function CoATalentButtonHexMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Choice)
end

function CoATalentButtonHexMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeCircle)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Circle)
    end
end

CoATalentButtonDiamondMixin = CreateFromMixins("CoATalentButtonMixin")

function CoATalentButtonDiamondMixin:OnLoad()
    CoATalentButtonMixin.OnLoad(self)
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Square)
end

function CoATalentButtonDiamondMixin:SetIsSubNode(isSubNode)
    CoATalentButtonMixin.SetIsSubNode(self, isSubNode)
    if isSubNode then
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-1, -1, -1, -1)
        self.Icon:SetOverlayInset(-1, -1, -1, -1)
        self.Icon:SetHighlightInset(-1, -1, -1, -1)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    else
        self.Icon:SetBackgroundInset(-20, -20, -20, -20)
        self.Icon:SetBorderInset(-2, -2, -2, -2)
        self.Icon:SetOverlayInset(-2, -2, -2, -2)
        self.Icon:SetHighlightInset(-2, -2, -2, -2)
        self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.LargeSquare)
    end
end

CoATalentChoiceButtonMixin = CreateFromMixins("CATalentChoiceBaseMixin")

function CoATalentChoiceButtonMixin:OnLoad()
    CATalentChoiceBaseMixin.OnLoad(self)
    self.Icon:SetBackgroundInset(-20, -20, -20, -20)
    self.Icon:SetBorderInset(-10, -10, -7, -7)
    self.Icon:SetOverlayInset(-10, -10, -7, -7)
    self.Icon:SetHighlightInset(-10, -10, -7, -7)
    self:SetShowSingleRanks(true)
    self:SetShowZeroMultiRanks(true)
    self.RankFrame:ShowMaxRank(true)
    self.RankFrame:SetMaxRankSeparator("/")
    self:SetArtSet(CoACharacterAdvancementUtil.NodeArtSet.Choice)
end

function CoATalentChoiceButtonMixin:AddNode(node)
    CATalentChoiceBaseMixin.AddNode(self, node)
    node:SetSize(42, 42)
end 

--
-- Gate Template
--
CoAGateMixin = CreateFromMixins("CAGateBaseMixin")

function CoAGateMixin:UpdateDisplay(investedCurrency)
    CAGateBaseMixin.UpdateDisplay(self, investedCurrency)
    local remainder = self.requiredCurrency - investedCurrency
    self.GateText:SetText(remainder)
end

function CoAGateMixin:SetLocked()
    CAGateBaseMixin.SetLocked(self)
    self.GateText:Show()
    self.LockIcon:SetAtlas("talents-gate", Const.TextureKit.IgnoreAtlasSize)
end 

function CoAGateMixin:SetUnlocked()
    CAGateBaseMixin.SetUnlocked(self)
    self.GateText:Hide()
    self.LockIcon:SetAtlas("talents-gate-open", Const.TextureKit.IgnoreAtlasSize)
end 

--
-- Spec Role Template
--
CoASpecRoleMixin = {}

function CoASpecRoleMixin:SetRole(role)
    local roleID = Enum.ClassRole[role] or role
    local name = (ROLE_TEXT_SHORT and ROLE_TEXT_SHORT[roleID]) or ROLE_TEXT[roleID]
    local atlas = ROLE_ATLAS[roleID]

    if not name or not atlas then
        C_Logger.Error("Bad role provided for CoASpecRoleMixin:SetRole(%s)", tostring(role))
        return
    end

    self.Icon:SetAtlas(atlas, Const.TextureKit.IgnoreAtlasSize)
    self.Text:SetText(name)
    local textWidth = self.Text:GetStringWidth()
    local iconWidth = self.Icon:GetWidth()
    self:SetWidth(math.max(textWidth, iconWidth))
end

--
-- Spec Stat Template
--
CoASpecStatMixin = {}

function CoASpecStatMixin:SetStat(stat)
    if not stat then
        C_Logger.Error("Bad stat provided for CoASpecStatMixin:SetStat(%s)", tostring(stat))
        return
    end

    local statID = Enum.PrimaryStat[stat] or stat
    local name = _G[PRIMARY_STAT_NAME_FORMAT:format(statID)]
    local atlas = PRIMARY_STAT_ATLAS[statID]

    if not name or not atlas then
        C_Logger.Error("Bad stat provided for CoASpecStatMixin:SetStat(%s)", tostring(stat))
        return
    end

    self.Icon:SetAtlas(atlas)
    self.Text:SetText(name)
    local textWidth = self.Text:GetStringWidth()
    local iconWidth = self.Icon:GetWidth()
    self:SetWidth(math.max(textWidth, iconWidth))
end

--
-- Spec Armor Proficiency 
--
CoASpecArmorMixin = {}

function CoASpecArmorMixin:SetArmorType(armorType)
    if not armorType then
        C_Logger.Error("Bad armor type provided for CoASpecArmorMixin:SetArmor(%s)", tostring(armorType))
        return
    end

    local armorTypeID = Enum.ClassArmorType[armorType] or armorType
    local name = ARMOR_TYPE_NAME[armorTypeID]
    local atlas = ARMOR_TYPE_ATLAS[armorTypeID]

    if not name or not atlas then
        C_Logger.Error("Bad armor type provided for CoASpecArmorMixin:SetArmor(%s)", tostring(armorType))
        return
    end

    self.Icon:SetAtlas(atlas)
    self.Text:SetText(name)
    self:SetWidth(self.Text:GetWidth())
end 

--
-- Sample Ability
--
CoASampleAbilityMixin = CreateFromMixins("SpellIconTemplateMixin")

function CoASampleAbilityMixin:OnLoad()
    SpellIconTemplateMixin.OnLoad(self)
    self:SetBorderAtlas("spec-sampleabilityring")
    self:SetBorderSize(50, 48)
    self:SetRounded(true)
end

function CoASampleAbilityMixin:OnEnter()
    SpellIconTemplateMixin.OnEnter(self)
    FrameUtil.PassOnEnterToParent(self)
end

function CoASampleAbilityMixin:OnLeave()
    SpellIconTemplateMixin.OnLeave(self)
    FrameUtil.PassOnLeaveToParent(self)
end 

--
-- Spec Choice FX
--

CoASpecChoiceFXMixin = {}

function CoASpecChoiceFXMixin:OnLoad()
    UseParentLevel(self)
    self.Child:SetSize(self:GetSize())
    
    self.Child.ActivationFX:SetAtlas("talents-animations-gridburst", Const.TextureKit.IgnoreAtlasSize)
end

function CoASpecChoiceFXMixin:OnSizeChanged(width, height)
    self.Child:SetSize(width, height)
end 

function CoASpecChoiceFXMixin:PlayActivateFX()
    self.Child.ActivationFX.Flash:Play()
end

function CoASpecChoiceFXMixin:StopActivateFX()
    self.Child.ActivationFX.Flash:Stop()
end 

--
-- Tree FX
--
CoATreeFXMixin = {}

local CLOUD_WIDTH = 1160

function CoATreeFXMixin:OnLoad()
    UseParentLevel(self)
    local width, height = self:GetSize()
    self.Child:SetSize(width, height)

    local cloudsContainer = self.Child.CloudsContainer
    cloudsContainer:SetSize(CLOUD_WIDTH * 2, height)
    cloudsContainer.Clouds1:SetSize(CLOUD_WIDTH, height)
    cloudsContainer.Clouds2:SetSize(CLOUD_WIDTH, height)
    cloudsContainer.Clouds1:SetAtlas("talents-animations-clouds", Const.TextureKit.IgnoreAtlasSize)
    cloudsContainer.Clouds2:SetAtlas("talents-animations-clouds", Const.TextureKit.IgnoreAtlasSize)

    self.Child.AirParticlesClose:SetAtlas("talents-animations-particles", Const.TextureKit.UseAtlasSize)
    self.Child.AirParticlesFar:SetAtlas("talents-animations-particles", Const.TextureKit.UseAtlasSize)
    self.Child.AirParticlesFar:FlipX()
end

function CoATreeFXMixin:OnSizeChanged(width, height)
    self.Child:SetSize(width, height)

    local cloudsContainer = self.Child.CloudsContainer
    cloudsContainer:SetSize(CLOUD_WIDTH * 2, height)
    cloudsContainer.Clouds1:SetSize(CLOUD_WIDTH, height)
    cloudsContainer.Clouds2:SetSize(CLOUD_WIDTH, height)
end

function CoATreeFXMixin:OnShow()
    self.Child.CloudsContainer.Anim:Play()
    self.Child.AirParticlesClose.Anim:Play()
    self.Child.AirParticlesFar.Anim:Play()
end

function CoATreeFXMixin:OnHide()
    self.Child.CloudsContainer.Anim:Stop()
    self.Child.AirParticlesClose.Anim:Stop()
    self.Child.AirParticlesFar.Anim:Stop()
end 

--
-- CoA Build Item 
--
CoATalentBuildScrollItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function CoATalentBuildScrollItemMixin:OnLoad()
    self.Background:SetVertexColor(0.5, 0.5, 0.5)
    self.Background:SetAtlas("buildcreator-class-header", Const.TextureKit.IgnoreAtlasSize)
    self.Role:SetBackgroundTexture("Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS")
    self.Role:SetBackgroundSize(48, 48)
    self.Role:SetBackgroundAlpha(0.6)

    self.Icon:SetRounded(true)
    self.Icon:SetBorderSize(48, 48)
    self.Icon:SetBorderOffset(0, -1)
    self.Icon:SetBorderAtlas("build-draft-border")
    self:RegisterEvent("BUILD_CREATOR_RATE_RESULT")
end

function CoATalentBuildScrollItemMixin:GetBuildListParent()
    return self:GetScrollList():GetParent()
end

function CoATalentBuildScrollItemMixin:Update()
    self.data = C_BuildCreator.GetBuildAtIndex(self.index)

    if not self.data then
        return
    end

    local name = CoACharacterAdvancementUtil.StripArchitectTag(self.data.Name)

    self.tooltipTitle = name
    self.tooltipText = self.data.Subtext.."\n"..self.data.Description

    local text = name
    self.Text:SetText(name)
    self.Icon:SetIcon("Interface\\Icons\\"..self.data.Icon)

    if BuildCreatorUtil.IsActiveBuildID(self.data.ID) then
        text = text .. "|cff00FF00("..ACTIVE..")"
        self.Text:SetText(text)
    end

    -- role update
    local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.data.Roles)
    self.Role:SetIconAtlas(ROLE_ATLAS[role])
    self.Role.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
    self.Role.tooltipTitle = BUILD_CREATOR_ROLE_S:format(_G[role])
    self.Role.tooltipText = _G["BUILD_CREATOR_ROLE_"..role]
    if GameTooltip:IsOwned(self.Role) then
        self.Role:CallScript("OnEnter")
    end

    self:UpdateRating()
end

function CoATalentBuildScrollItemMixin:UpdateRating()
    -- rating update
    local rating = self.data.Upvotes or 0
    rating = ITEM_QUALITY_COLORS[Enum.ItemQuality.Uncommon]:WrapText(rating)
    self.RatingText:SetFormattedText(BUILD_RATING_S, rating)
    self.LikeButton:SetChecked(C_BuildCreator.IsUpvotedBuild(self.data.ID))
    if self.LikeButton:GetBoolValue() then
        self.LikeButton:LockHighlight()
    else
        self.LikeButton:UnlockHighlight()
    end
end

function CoATalentBuildScrollItemMixin:OnSelected()
    self:GetBuildListParent():SelectBuild(self.data and self.data.ID)
end

function CoATalentBuildScrollItemMixin:LikeBuild()
    if C_BuildCreator.IsUpvotedBuild(self.data.ID) then
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
        C_BuildCreator.RateBuild(self.data.ID, false)
    else
        C_BuildCreator.RateBuild(self.data.ID, true)
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    end
end

function CoATalentBuildScrollItemMixin:OnEnter()
    GameTooltip_GenericTooltip(self)
end

function CoATalentBuildScrollItemMixin:OnLeave()
    GameTooltip:Hide()
end

function CoATalentBuildScrollItemMixin:BUILD_CREATOR_RATE_RESULT(result, buildID, rating)
    self.LikeButton:Enable()
    if self.data and self.data.ID == buildID then
        self.data.Upvotes = rating
        self:UpdateRating()
    end
end 

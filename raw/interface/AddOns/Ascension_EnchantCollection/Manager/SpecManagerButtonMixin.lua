ECSpecManagerButtonMixin = CreateFromMixins(OldSpecializationButtonMixin)

function ECSpecManagerButtonMixin:OnLoad()
    self:Layout()

	self.SpecIcon.Settings:SetScript("OnClick", function()
		self:GetScrollManager():EditPresetData(self.index)
	end)
end

function ECSpecManagerButtonMixin:Init()
end

function ECSpecManagerButtonMixin:Update()
    local presetData, isActive = MysticEnchantManagerUtil.GetPresetData(self.index)

    self.Text:SetText(MysticEnchantManagerUtil.GetPresetName(self.index))
    self.SpecIcon.Icon:SetTexCoord(0, 1, 0, 1) -- fix icon after using atlas
    self.SpecIcon.Icon:SetTexture(MysticEnchantManagerUtil.GetPresetIcon(self.index))
    self.Selected:Hide()

    if self.index > C_MysticEnchantPreset.GetNumPresets() then
        self:SetDisabled()
    else
        self:SetEnabled()

        if (isActive) then
            self:SetActive()
        end
    end
end

function ECSpecManagerButtonMixin:SetEnabled()
    self:Enable()
    self.Text:SetFontObject(GameFontNormal)
    self.Text_Add:SetText("|cff00FF00"..AVAILABLE.."|r")

    self.SpecIcon.Settings:Show()
    self.SpecIcon.Settings:Enable()
    self.SpecIcon.Settings:GetNormalTexture():SetVertexColor(1, 1, 1, 1)

    self.SpecIcon.Icon:SetDesaturated(false)
    self.SpecIcon.Icon:SetVertexColor(1, 1, 1, 1)

    self.SpecIcon.KnownBorder:Hide()
    self.isActive = false
end

function ECSpecManagerButtonMixin:SetUnlock()
    self.SpecIcon.Settings:Hide()
    self.SpecIcon.Icon:SetAtlas("itemupgrade_greenplusicon", Const.TextureKit.IgnoreAtlasSize)

    local colorStr = ""

    if MysticEnchantManagerUtil.HasUnlockItem() then
        self.SpecIcon.Icon:SetVertexColor(1, 1, 1, 1)
        self:Enable()
    else
        self.SpecIcon.Icon:SetDesaturated(true)
        colorStr = "|cffFF0000"
        self:Disable()
    end

    self.Text_Add:SetText(colorStr..string.format(ENCHANT_SPECIALIZATION_UNLOCK_WITH, MysticEnchantManagerUtil.GetPresetUnlockItem():GetLink()))
 end

function ECSpecManagerButtonMixin:SetDisabled()
    self:Disable()
    self.Text:SetFontObject(GameFontDisable)

    self.SpecIcon.Settings:Show()
    self.SpecIcon.Settings:Disable()
    self.SpecIcon.Settings:GetNormalTexture():SetVertexColor(1, 0, 0, 1)
    self.SpecIcon.KnownBorder:Hide()

    if self.index and self.index <= MysticEnchantManagerUtil.GetFreePresets() then
        if (MysticEnchantManagerUtil.HasUnlockItem()) then
            self:SetUnlock()
            return
        end

        self.Text_Add:SetText("|cffFF0000"..string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, GetMaxLevel()).."|r")
        self.SpecIcon.Icon:SetVertexColor(1, 0, 0, 1)
    else
        self:SetUnlock()
    end
end

function ECSpecManagerButtonMixin:SetActive()
    self.Text:SetFontObject(GameFontHighlight)
    self.Text_Add:SetText(ACTIVE)
    self.SpecIcon.KnownBorder:Show()
    self.Selected:Show()
    self.isActive = true
end

function ECSpecManagerButtonMixin:GetScrollManager()
	return self:GetParent():GetParent():GetParent():GetParent()
end

function ECSpecManagerButtonMixin:OnSelected()
	self:GetScrollManager():OnSelectPreset(self.index)
end

function ECSpecManagerButtonMixin:OnMouseDown()
    self.Text:SetPoint("CENTER", 21, 8)
    self.Text_Add:SetPoint("CENTER", 21, -8)
end

function ECSpecManagerButtonMixin:OnMouseUp()
    self.Text:SetPoint("CENTER", 20, 10)
    self.Text_Add:SetPoint("CENTER", 20, -6)
end

function ECSpecManagerButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(self.Text:GetText(), 1, 1, 1)

    if self:IsEnabled() == 1 then
        if self.isActive then
            GameTooltip:AddLine(ENCHANT_SPECIALIZATION_CURRENT_HINT, nil, nil, nil, true)
        else
            if MysticEnchantManagerUtil.HasUnlockItem() then
                GameTooltip:AddLine(ENCHANT_SPECIALIZATION_UNLOCK_HINT, nil, nil, nil, true)
            else
                GameTooltip:AddLine(ENCHANT_SPECIALIZATION_CHANGE_HINT, nil, nil, nil, true)
            end
        end
    else
        GameTooltip:AddLine(UNLOCK_MYSTIC_ENCHANT_PRESET_HINT, nil, nil, nil, true)
    end
    GameTooltip:Show()
end

function ECSpecManagerButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function ECSpecManagerButtonMixin:Layout()
    OldSpecializationButtonMixin.Layout(self)
end

ECActiveSpecButtonMixin = {}

function ECActiveSpecButtonMixin:OnLoad()
    self:Layout()
end

function ECActiveSpecButtonMixin:Update()
    local presetData, isActive = MysticEnchantManagerUtil.GetPresetData(self.index)

    self.Text:SetText(MysticEnchantManagerUtil.GetPresetName(self.index))
    self.SpecIcon.Icon:SetTexCoord(0, 1, 0, 1) -- fix icon after using atlas
    self.SpecIcon.Icon:SetTexture(MysticEnchantManagerUtil.GetPresetIcon(self.index))
end

function ECActiveSpecButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.Text:GetText(), 1, 1, 1)
    GameTooltip:AddLine(ENCHANT_SPECIALIZATION_CURRENT_HINT, nil, nil, nil, true)
    GameTooltip:AddLine(ENCHANT_SPECIALIZATION_CHANGE_HINT, nil, nil, nil, true)
    GameTooltip:Show()
    self.highlight:Show()
end

function ECActiveSpecButtonMixin:OnLeave()
    GameTooltip:Hide()
    self.highlight:Hide()
end

function ECActiveSpecButtonMixin:Layout()
    self.SpecIcon = CreateFrame("FRAME", "$parent.SpecIcon", self, "PopupButtonTemplate")
    self.SpecIcon:SetSize(32,32)
    self.SpecIcon:SetPoint("LEFT", 6, 0)
    self.SpecIcon:SetFrameLevel(self:GetFrameLevel()+3)

    self.SpecIcon.Icon = self.SpecIcon:CreateTexture(nil, "ARTWORK")
    self.SpecIcon.Icon:SetTexture("Interface\\Icons\\inv_misc_book_16")
    self.SpecIcon.Icon:SetSize(36,36)
    self.SpecIcon.Icon:SetPoint("CENTER", 0, -1)

    self.Text = self:CreateFontString(nil, "OVERLAY")
    self.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    self.Text:SetFontObject(GameFontHighlight)
    self.Text:SetPoint("LEFT", self.SpecIcon, "RIGHT", 12, 8)
    self.Text:SetShadowOffset(1,-1)
    self.Text:SetText("Enchants Set")
    self.Text:SetWidth(160)
    --self.Text:SetSize(160, 16)
    self.Text:SetJustifyH("LEFT")

    self.Text_Add = self:CreateFontString(nil, "OVERLAY")
    self.Text_Add:SetFontObject(GameFontNormalSmall)
    self.Text_Add:SetPoint("TOPLEFT", self.Text, "BOTTOMLEFT", 0, -2)
    self.Text_Add:SetText(ACTIVE)
    self.Text_Add:SetSize(160, 32)
    self.Text_Add:SetJustifyH("LEFT")
    self.Text_Add:SetJustifyV("TOP")

    self.highlight = self.SpecIcon:CreateTexture(nil, "OVERLAY")
    self.highlight:SetAtlas("PetList-ButtonHighlight", Const.TextureKit.IgnoreAtlasSize)
    self.highlight:SetSize(self:GetSize())
    self.highlight:SetPoint("CENTER", self)
    self.highlight:SetBlendMode("ADD")
    self.highlight:Hide()
end
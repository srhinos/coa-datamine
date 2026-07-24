CASpecTabMixin = CreateFromMixins(TabSystemTabMixin)

function CASpecTabMixin:UpdateSpellCounts(class, spec)
    if spec == "BROWSER" or C_CVar.GetBool("previewCharacterAdvancementChanges") then
        self.TalentCount:Hide()
        self.SpellCount:Hide()
        return
    end

    local te = C_CharacterAdvancement.GetLearnedTE(class, spec)
    local ae = C_CharacterAdvancement.GetLearnedAE(class, spec)
    self.TalentCount:SetCount(te)
    self.SpellCount:SetCount(ae)

    local showAE = ae and ae > 0
    local showTE = te and te > 0

    self.SpellCount:SetShown(showAE)
    self.TalentCount:SetShown(showTE)

    self.Text:ClearAndSetPoint("CENTER", 0, 1)

    if showAE then
        self.SpellCount:ClearAndSetPoint("LEFT", self.Text, "RIGHT", 4, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()/2), 1)
    end

    if showAE and showTE then
        self.TalentCount:ClearAndSetPoint("LEFT", self.SpellCount, "RIGHT", 0, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()), 1)
    elseif showTE then
        self.TalentCount:ClearAndSetPoint("LEFT", self.Text, "RIGHT", 4, 0)
        self.Text:ClearAndSetPoint("CENTER", -(self.SpellCount:GetWidth()/2), 1)
    end
end

function CASpecTabMixin:GetClassFile()
    return self.classFile
end

function CASpecTabMixin:OnSpellCountEnter(spellCount)
    if not self.classFile or not self.spec then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    local specInfo = C_ClassInfo.GetSpecInfo(self.classFile, self.spec)
    className = specInfo.Name .. " - " .. className
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_ABILITIES:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_ABILITIES_KNOWN:format(tonumber(spellCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

function CASpecTabMixin:OnTalentCountEnter(talentCount)
    if not self.classFile or not self.spec then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    local specInfo = C_ClassInfo.GetSpecInfo(self.classFile, self.spec)
    className = specInfo.Name .. " - " .. className
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_TALENTS:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_TALENTS_KNOWN:format(tonumber(talentCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

function CASpecTabMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 

function CASpecTabMixin:OnLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 

function CASpecTabMixin:UpdateButton(buttonState)
    local buttonState = buttonState or self:GetButtonState()
    local atlasNamePostfix = ""
    --ThreeSliceButtonMixin.UpdateButton(self, buttonState)
    if self.GetChecked and self:GetChecked() then
        atlasNamePostfix = "-Checked"
    end

    self.Left:SetAtlas(self:GetLeftAtlasName()..atlasNamePostfix, Const.TextureKit.UseAtlasSize)
    self.Center:SetAtlas(self:GetCenterAtlasName()..atlasNamePostfix)
    self.Right:SetAtlas(self:GetRightAtlasName()..atlasNamePostfix, Const.TextureKit.UseAtlasSize)

    self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName()..atlasNamePostfix)
    self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName()..atlasNamePostfix)

    local isDisabled = (self:IsEnabled() == 0 ) and not self:GetChecked()
    self.Left:SetDesaturated(isDisabled)
    self.Center:SetDesaturated(isDisabled)
    self.Right:SetDesaturated(isDisabled)

    self:UpdateScale()
end

function CASpecTabMixin:OnMouseDown()
    local buttonState = buttonState or self:GetButtonState()

    if buttonState ~= "DISABLED" then
        self:UpdateButton("PUSHED")
    end
end

function CASpecTabMixin:OnMouseUp()
    local buttonState = buttonState or self:GetButtonState()

    if buttonState ~= "DISABLED" then
        self:UpdateButton("NORMAL")
    end
end
CAClassButtonMixin = CreateFromMixins(BorderIconTemplateMixin)

function CAClassButtonMixin:OnLoad()
    self:SetRounded(true)
    self:SetBorderSize(56, 56)
    self:SetBorderAtlas("draft-ring")

    self:SetOverlayBlendMode("ADD")
    self:SetOverlayTexture("Interface\\GLUES\\CHARACTERCREATE\\IconBorderRace_H")
    self:SetOverlaySize(95, 95)
    self:SetOverlayOffset(0, 0)
    self.Overlay:Hide()

    self.Highlight:SetAtlas("bags-roundhighlight")

    self:SetHighlightFontObject(GameFontHighlightOutline)
    self:SetNormalFontObject(GameFontNormalOutline)
    self:SetPushedTextOffset(1, -1)

    -- background is not used and we need text to be over the Overlay
    self.Icon:SetDrawLayer("BACKGROUND")
    self.IconBorder:SetDrawLayer("BORDER")
    self.Overlay:SetDrawLayer("ARTWORK")
    self.Text:SetDrawLayer("OVERLAY")
end

function CAClassButtonMixin:SetClass(classFile)
    self.classFile = classFile
    self.classDBC = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    self:SetIconAtlas("class-round-"..classFile)
    self:SetText(LOCALIZED_CLASS_NAMES_MALE[classFile])
    self:UpdateSpellCounts()
end

function CAClassButtonMixin:UpdateSpellCounts()
    local te = C_CharacterAdvancement.GetLearnedTE(self.classDBC)
    local ae = C_CharacterAdvancement.GetLearnedAE(self.classDBC)
    self.TalentCount:SetCount(te)
    self.SpellCount:SetCount(ae)

    local showAE = ae and ae > 0
    local showTE = te and te > 0

    self.SpellCount:SetShown(showAE)
    self.TalentCount:SetShown(showTE)

    if showAE then
        self.SpellCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, -10)
    end

    if showAE and showTE then
        self.TalentCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, 10)
    elseif showTE then
        self.TalentCount:ClearAndSetPoint("CENTER", self, "RIGHT", 8, -10)
    end
end

function CAClassButtonMixin:OnClick()
    PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
    CharacterAdvancement:SelectClass(self.classFile)
end 

function CAClassButtonMixin:OnSelected()
    self.Overlay:Show()
end

function CAClassButtonMixin:OnDeSelected()
    self.Overlay:Hide()
end

function CAClassButtonMixin:OnSpellCountEnter(spellCount)
    if not self.classFile then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_ABILITIES:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_ABILITIES_KNOWN:format(tonumber(spellCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

function CAClassButtonMixin:OnTalentCountEnter(talentCount)
    if not self.classFile then return end
    local className = LOCALIZED_CLASS_NAMES_MALE[self.classFile]
    if not className then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(S_TALENTS:format(className), RAID_CLASS_COLORS[self.classFile]:GetRGB())
    GameTooltip:AddLine(D_TALENTS_KNOWN:format(tonumber(talentCount.Text:GetText())), 1, 1, 1, true)
    GameTooltip:Show()
    self:LockHighlight()
end

function CAClassButtonMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 
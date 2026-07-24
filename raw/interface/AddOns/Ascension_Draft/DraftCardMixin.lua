DraftCardMixin = {}

DraftCardMixin.SpellType = {
    Ability = ABILITY,
    Trait = TRAIT,
    Talent = TALENT,
    MysticEnchant = MYSTIC_ENCHANT,
}

DraftCardMixin.ArtworkStyle = {
    Paper = 1,
    Metal = 2,
}

DraftCardMixin.Action = {
    Learn = 1,
    Swap = 2,
    Sacrifice = 3,
    Dismiss = 4,
}

local function ResetParticle(pool, particle)
    particle.Anim:Stop()
    particle:Hide()
    particle:ClearAllPoints()
end

local particlePool = CreateTexturePool(UIParent, "OVERLAY", "DraftParticleTemplate", ResetParticle)

function DraftCardMixin:OnLoad()
    self.Border:SetAtlas("draft-card-border", Const.TextureKit.UseAtlasSize)
    self.Rarity.Background:SetAtlas("draft-card-rarity-background", Const.TextureKit.UseAtlasSize)
    self.Rarity.NoGemBackground:SetAtlas("draft-card-rarity-no-gem-background", Const.TextureKit.UseAtlasSize)
    self.Name.MasteryHeader:SetAtlas("draft-card-mastery-header", Const.TextureKit.UseAtlasSize)
    self.Name.MasteryHeader:SetPoint("TOP", self, "TOP", 2, 26)
    self.Name.MasteryText:SetPoint("BOTTOM", self, "TOP", 0, -20)

    self.SpellIcon:SetBackgroundTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
    self.SpellIcon:SetBackgroundSize(142, 142)
    self.SpellIcon:SetBackgroundOffset(0, -2)
    self.SpellIcon:SetBorderTexture("Interface\\AddOns\\AwAddons\\Textures\\SpellKit\\ArtifactPower-QuestBorder")
    self.SpellIcon:SetBorderSize(56, 56)
    self.SpellIcon.Highlight:SetAtlas("draft-card-spell-highlight", Const.TextureKit.UseAtlasSize)
    self.SpellIcon:EnableDrag()

    -- have to manually adjust frame levels so texture clipping doesnt happen.
    -- description needs to be the lowest level element
    local BaseLevel = self.Description:GetFrameLevel()
    self.MainButton:SetFrameLevel(BaseLevel + 1)
    -- rarity needs to be above description
    self.Rarity:SetFrameLevel(BaseLevel + 1)

    -- name needs to be above rarity
    self.Name:SetFrameLevel(BaseLevel + 2)

    -- class icon has to be above name because of mastery header
    self.ClassIcon:SetFrameLevel(BaseLevel + 3)

    -- move above all other elements
    self.CloseButton:SetFrameLevel(BaseLevel + 4)
    
    -- color accents have to be ontop of everything else
    self.ColorAccents:SetFrameLevel(BaseLevel + 10)
    self.Rarity:SetOrientation(RarityGemContainerMixin.Orientation.Centered)

    self.ColoredElements = {}
    tinsert(self.ColoredElements, self.BackgroundHover)
    tinsert(self.ColoredElements, self.ParticleSpawn.Glow)
    tinsert(self.ColoredElements, self.Cover.BackgroundGlow)
    for _, element in ipairs(self.ColorAccents:GetColoredElements()) do
        tinsert(self.ColoredElements, element)
    end
    Draft.Cards[self:GetID()] = self

    self.Children = {}
    for _, child in ipairs({self:GetChildren()}) do
        if child ~= self.Cover and child ~= self.ColorAccents then
            tinsert(self.Children, child)
        end
    end
    
    for _, region in ipairs({self:GetRegions()}) do
        if region.Hide then
            tinsert(self.Children, region)
        end
    end
end

function DraftCardMixin:OnShow()
    self.ParticleSpawn.Glow:Hide()

    if self:IsSkillCard() or self:IsLuckySkillCard() then
        DraftHelpFrame:ShowSkillCardTip(self:GetID())
    end

    self:UpdateModifierStateRegistration()
end

function DraftCardMixin:OnHide()
    particlePool:ReleaseAllWithParent(self.ParticleSpawn)
    self:EnableMouse(true)
    self.Cover:EnableMouse(true)
    self:UpdateModifierStateRegistration()
end

function DraftCardMixin:IsRevealed()
    if not self.Cover then
        return true
    end

    if not self.Cover:IsShown() then
        return true
    end

    local background = self.Cover.Background
    if background and not background:IsShown() then
        return true
    end

    return false
end

function DraftCardMixin:UpdateModifierStateRegistration()
    if self:IsShown() and self:IsRevealed() then
        if not self.modifierStateRegistered then
            self:RegisterEvent("MODIFIER_STATE_CHANGED")
            self.modifierStateRegistered = true
        end
    elseif self.modifierStateRegistered then
        self:UnregisterEvent("MODIFIER_STATE_CHANGED")
        self.modifierStateRegistered = nil
    end
end

function DraftCardMixin:RefreshSpellDescription()
    if not self.spellID then return end
    local desc = GetSpellDescription(self.spellID)
    if desc and GameTooltip_GetSpellCastReqText then
        local entry = C_CharacterAdvancement.GetEntryBySpellID(self.spellID)
        local reqText = GameTooltip_GetSpellCastReqText(entry)
        if reqText then
            desc = reqText .. "|n" .. desc
        end
    end
    self.Description:SetText(desc)
end

function DraftCardMixin:OnEvent(event, key)
    if event ~= "MODIFIER_STATE_CHANGED" then
        return
    end

    if key ~= "LSHIFT" and key ~= "RSHIFT" then
        return
    end

    if not self:IsShown() or not self:IsRevealed() then
        return
    end

    self:RefreshSpellDescription()
end

function DraftCardMixin:GetRarityGems()
    return self.rarityFrame.totalGems
end

function DraftCardMixin:SetSpellType(spellType, quality)
    if quality then
        local color = ITEM_QUALITY_COLORS[quality]
        spellType = color:WrapText(_G["ITEM_QUALITY"..quality.."_DESC"] .. " " .. spellType)

        if spellType == DraftCardMixin.SpellType.Talent then
            self.ColorAccents:SetSpellGlowType(DraftCardColorAccentsMixin.SpellGlowType.Talent)
        else
            self.ColorAccents:SetSpellGlowType(DraftCardColorAccentsMixin.SpellGlowType.Ability)
        end
    end

    self.spellType = spellType
end

function DraftCardMixin:SetClass(class, spec)
    self.spellClass = class
    self.spellSpec = spec
end

function DraftCardMixin:SetFromGeneric()
    self.Name.MasteryHeader:Hide()
    self.Name.MasteryText:Hide()
    self.ClassIcon:Hide()
end

function DraftCardMixin:SetFromClass()
    local color = RAID_CLASS_COLORS[self.spellClass]

    self:SetTitleDisplay()

    self.ClassIcon:Show()
    self.ClassIcon:SetIconAtlas("class-round-"..self.spellClass)
    self.ClassIcon:SetBorderOffset(0, -8)
    self.ClassIcon:SetBorderAtlas("draft-card-class-border", true)

    self.ClassIcon.Spell = nil

    local className = color:WrapText(LOCALIZED_CLASS_NAMES_MALE[self.spellClass] or "")
    local specName = color:WrapText(LOCALIZED_CLASS_SPEC_NAMES[self.spellClass][self.spellSpec] or "")
    self.ClassIcon.tooltipTitle = string.format(DRAFT_SPELL_FROM_CLASS, self.spellType, specName, className)
end

function DraftCardMixin:SetFromMastery(masteryInternalID)
    local masteryID = CharacterAdvancementUtil.GetSpellByID(masteryInternalID)
    local _, _, masteryIcon = GetSpellInfo(masteryID)
    local masteryLink = LinkUtil:GetSpellLink(masteryID)

    self.ClassIcon:Show()
    self.ClassIcon:SetIcon(masteryIcon)
    self.ClassIcon:SetBorderOffset(0, -12)
    self.ClassIcon:SetBorderAtlas("draft-card-class-mastery-border", true)
    self.ClassIcon:SetRounded(true)

    self.ClassIcon.Spell = masteryID

    self:SetTitleDisplay(DRAFT_OBTAINED_BY_MASTERY:format(masteryLink))
end

function DraftCardMixin:SetQuality(quality)
    self.quality = quality
    if quality and quality > Enum.ItemQuality.Common then
        self.color = ITEM_QUALITY_COLORS[quality]
        for _, element in ipairs(self.ColoredElements) do
            element:Show()
            element:SetVertexColor(self.color:GetRGBA())
        end
    else
        self.color = ITEM_QUALITY_COLORS[1]
        for _, element in ipairs(self.ColoredElements) do
            element:Hide()
            element:SetVertexColor(self.color:GetRGBA())
        end
    end

    self.Cover:SetQuality(quality)
end

function DraftCardMixin:SetArtwork(artworkStyle)
    if artworkStyle == DraftCardMixin.ArtworkStyle.Paper then
        self.IconArtwork:SetAtlas("draft-card-icon-paper-artwork", Const.TextureKit.UseAtlasSize)
    elseif artworkStyle == DraftCardMixin.ArtworkStyle.Metal then
        self.IconArtwork:SetAtlas("draft-card-icon-metal-artwork", Const.TextureKit.UseAtlasSize)
    end
    
    self.Description:SetArtwork(artworkStyle)
end

function DraftCardMixin:SetCardAction(action)
    self.action = action

    if action == DraftCardMixin.Action.Learn then
        self.MainButton:SetText(DRAFT_LEARN)
        self.Background:SetVertexColor(1, 1, 1, 1)
        self.SpellIcon:SetIconColor(1, 1, 1, 1)
    elseif action == DraftCardMixin.Action.Swap then
        self.MainButton:SetText(DRAFT_SWAP)
        self.Background:SetVertexColor(1, 1, 1, 1)
        self.SpellIcon:SetIconColor(1, 1, 1, 1)
    elseif action == DraftCardMixin.Action.Sacrifice then
        self.MainButton:SetText(DRAFT_UNLEARN)
        self.Background:SetVertexColor(1, 0, 0, 1)
        self.SpellIcon:SetIconColor(1, 0, 0, 1)
    elseif action == DraftCardMixin.Action.Dismiss then
        self.MainButton:SetText(DRAFT_DISMISS)
        self.Background:SetVertexColor(1, 1, 1, 1)
        self.SpellIcon:SetIconColor(1, 1, 1, 1)
    end
end

function DraftCardMixin:SetMainButtonTooltip(tooltipTitle)
    self.MainButton.tooltipTitle = tooltipTitle
end

function DraftCardMixin:Dismiss()
    self:MarkCardInvalid()
    self:Hide()
    Draft:DequeueCardDisplay()
end

function DraftCardMixin:DismissAll()
    Draft:InvalidateAllCards()
end

function DraftCardMixin:Learn()
    local spellLink = LinkUtil:GetSpellLink(self.spellID)
    local confirmFunc = GenerateClosure(SendDraftModeSpellSelection, self:GetID() - 1)
    local aeInvested = C_CharacterAdvancement.GetLearnedAE()
    local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(self.spellID) or 0
    if C_Player:GetLevel() >= 10 and aeInvested < 8 and aeInvested + aeCost >= 8 then
        -- check for empty skill card slots
        local hasEmptySkillCard = false
        for i = 1, C_SkillCard.GetMaxCardCount("SKILL_CARD_DEFAULT_NORMAL") do
            local normalIndex = i - 1
            if C_SkillCard.GetCardAtIndex("SKILL_CARD_DEFAULT_NORMAL", normalIndex) == 0 and not C_SkillCard.IsCardAtIndexBlocked("SKILL_CARD_DEFAULT_NORMAL", normalIndex) then
                hasEmptySkillCard = true
                break
            end

            local goldenIndex = i - 1
            if C_SkillCard.GetCardAtIndex("SKILL_CARD_DEFAULT_GOLDEN", goldenIndex) == 0 and not C_SkillCard.IsCardAtIndexBlocked("SKILL_CARD_DEFAULT_GOLDEN", goldenIndex) then
                hasEmptySkillCard = true
                break
            end
        end

        -- check for empty lucky card slots 
        if not hasEmptySkillCard then
            for i = 1, C_SkillCard.GetMaxCardCount("SKILL_CARD_LUCKY_NORMAL") do
                if C_SkillCard.GetCardAtIndex("SKILL_CARD_LUCKY_NORMAL", i-1) == 0 then
                    hasEmptySkillCard = true
                    break
                end
                
                if C_SkillCard.GetCardAtIndex("SKILL_CARD_LUCKY_GOLDEN", i-1) == 0 then
                    hasEmptySkillCard = true
                    break
                end
            end
        end

        if hasEmptySkillCard then
            StaticPopup_Show("DRAFT_MISSING_SKILLCARD_CONFIRM", nil, nil, confirmFunc)
            return
        else
            Draft:InvalidateAllCards()
            confirmFunc()
        end
    elseif (aeCost >= 8 or C_Player:GetLevel() > DraftUtil.GetConfirmLearnThreshold()) and not C_CVar.GetBool("skipDraftConfirmation") then
        StaticPopup_Show("DRAFT_CHOICE_CONFIRM", spellLink, nil, confirmFunc)
    else
        Draft:InvalidateAllCards()
        confirmFunc()
    end
end

function DraftCardMixin:Swap()
    local spellLink = LinkUtil:GetSpellLink(self.spellID)
    local confirmFunc = GenerateClosure(SendHandOfFateSpellSelection, self:GetID() - 1)
    if C_CVar.GetBool("skipDraftConfirmation") then
        Draft:InvalidateAllCards()
        confirmFunc()
        return
    end
    StaticPopup_Show("DRAFT_CHOICE_CONFIRM", spellLink, nil, confirmFunc)
end

function DraftCardMixin:Sacrifice()
    local spellLink = LinkUtil:GetSpellLink(self.spellID)
    local confirmFunc = GenerateClosure(SendHandOfFateSacrificeSpellSelection, self:GetID() - 1)
    if C_CVar.GetBool("skipDraftSacrificeConfirmation") then
        Draft:InvalidateAllCards()
        confirmFunc()
        return
    end

    local chosenID = DraftUtil.GetHandOfFateChoiceSpellID()
    local chosenLink = chosenID and LinkUtil:GetSpellLink(chosenID) or ""

    local bundleUnlearn = nil
    -- TODO: Investigate why CA2 is nil here; expected to be loaded by Character Advancement UI.
    if CA2 and CA2.ShouldUnlearnRemoveBundle then
        bundleUnlearn = CA2:ShouldUnlearnRemoveBundle(self.internalID)
    end
    if bundleUnlearn then
        chosenLink = chosenLink .. DRAFT_UNLEARN_ADDITIONAL_SPELLS
        for _, id in ipairs(bundleUnlearn) do
            if id ~= self.internalID then
                local spell = CharacterAdvancementUtil.GetSpellByID(id)

                if spell then
                    chosenLink = chosenLink .. "\n" .. LinkUtil:GetSpellLink(spell)
                end
            end
        end
    end

    local quality, cost = C_CharacterAdvancement.GetQualityInfo(self.spellID)
    if quality and quality > Enum.SpellQuality.Common and not IsCardSwap() and cost > 0 then
        local text = DRAFT_UNLEARN_INCREASE_CHANCE:format(ITEM_QUALITY_COLORS[quality]:WrapText(_G["ITEM_QUALITY" .. quality .. "_DESC"]))
        chosenLink = chosenLink .. text
    end
    if DraftUtil.IsCardSwapSacrifice() then
        StaticPopup_Show("DRAFT_SWAP_CONFIRM", spellLink, chosenLink, confirmFunc)
    else
        StaticPopup_Show("DRAFT_UNLEARN_CONFIRM", spellLink, chosenLink, confirmFunc)
    end
end

function DraftCardMixin:OnMainButtonClick()
    if not self.action then return end
    Draft:HideDraftStaticPopups()

    if C_Player:IsImmune() then
        return StaticPopup_Show("DRAFT_CANT_CHOOSE_IMMUNE")
    end

    if not self:IsValid() then return end

    if self.action == DraftCardMixin.Action.Dismiss then
        return self:Dismiss()
    elseif self.action == DraftCardMixin.Action.Learn then
        self:Learn()
    elseif self.action == DraftCardMixin.Action.Swap then
        self:Swap()
    elseif self.action == DraftCardMixin.Action.Sacrifice then
        self:Sacrifice()
    end
end

function DraftCardMixin:Close()
    Draft:HideDraftStaticPopups()
    if self.action == DraftCardMixin.Action.Dismiss then
        return self:DismissAll()
    end
    
    if self.action == DraftCardMixin.Action.Learn then
        return Draft:HideCards()
    end
    
    if self.action == DraftCardMixin.Action.Swap or self.action == DraftCardMixin.Action.Sacrifice then
        if IsCardSwap() then
            StaticPopup_Show("DRAFT_CANCEL_SWAP_CONFIRM")
        else
            StaticPopup_Show("DRAFT_CANCEL_HOF_CONFIRM")
        end
        return
    end
end

function DraftCardMixin:SetCurrencyDisplay(leftCount, rightCount)
    self.CurrencyBottomLeft:SetValue(leftCount)
    self.CurrencyBottomRight:SetValue(rightCount)
end

function DraftCardMixin:SetSpellID(spellID, spellType, artwork)
    self:MarkCardValid()
    local spellName = GetSpellInfo(spellID)

    if not spellName then
        self:MarkCardInvalid()
        SendSystemMessage("|cffFF4444[Draft"..self:GetID().."]: (" .. spellID .. ") spellID not found. Your patch is likely out of date! Try repairing your client via the launcher!")
        return C_Logger.Error("Invalid Spell ID for Draft Card. Spell ID: %s", spellID)
    end

    self:SetRarityDisplay(nil, 0, false, true)

    self.Background:SetAtlas("default-talent-warrior-arm", Const.TextureKit.IgnoreAtlasSize)
    
    self:SetSpellType(spellType or DraftCardMixin.SpellType.Ability, nil)
    self:SetArtwork(artwork or DraftCardMixin.ArtworkStyle.Paper)

    self:SetCurrencyDisplay(0, 0)

    --self:SetFromClass() -- TODO: We don't support class via CARD_SPELL_LEARNED event

    self.Name:SetText(spellName)
    self.spellID = spellID
    self:RefreshSpellDescription()
    self.SpellIcon:SetSpell(spellID)
end

function DraftCardMixin:SetCharacterAdvancementSpell(internalID, talentRank)
    if not internalID or internalID <= 0 then
        self.internalID = nil
        self.spellID = nil
        self.quality = nil
        self:MarkCardInvalid()
        return
    end

    self:MarkCardValid()

    local entry = C_CharacterAdvancement.GetEntryByInternalID(internalID)
    if not entry then
        self:MarkCardInvalid()
        self:SetBrokenCard(internalID)
        return
    end

    local spellID = CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, talentRank)
    if not spellID then
        self:MarkCardInvalid()
        self:SetBrokenCard(internalID)
        return
    end
    local aeCost = C_CharacterAdvancement.GetAbilityEssenceCost(spellID) or 0
    local teCost = C_CharacterAdvancement.GetTalentEssenceCost(spellID) or 0
    
    local spellName = GetSpellInfo(spellID)
    local spellClass, spellSpec = CharacterAdvancementUtil.GetClassFileForEntry(entry)
    local quality = Enum.SpellQuality[entry.Quality]
    if quality == nil then
        quality = tonumber(entry.Quality)
    end
    if quality == nil then
        quality = Enum.SpellQuality.Common
    end
    if quality > Enum.SpellQuality.Common then
        self:SetRarityDisplay(quality, entry.QualityCost, entry.QualityCost and entry.QualityCost > 0, DRAFT_GEMS_WONT_REDUCE_CHANCE)
    else
        self:SetRarityDisplay(nil, 0, false, true)
    end

    self:SetClass(spellClass, spellSpec)
    local bgAtlas = ("default-talent-%s-%s"):format(spellClass, spellSpec)
    if not AtlasUtil:AtlasExists(bgAtlas) then
        bgAtlas = "default-talent-warrior-arm"
    end
    self.Background:SetAtlas(bgAtlas)

    if C_CharacterAdvancement.IsTalentID(internalID) then
        self:SetSpellType(DraftCardMixin.SpellType.Talent, rarity)
        self:SetArtwork(DraftCardMixin.ArtworkStyle.Metal)
    elseif (C_CharacterAdvancement.IsTrait and C_CharacterAdvancement.IsTrait(internalID)) then
        self:SetSpellType(DraftCardMixin.SpellType.Trait, rarity)
        self:SetArtwork(DraftCardMixin.ArtworkStyle.Metal)
    elseif C_CharacterAdvancement.IsAbilityID(internalID) or C_CharacterAdvancement.IsTalentAbilityID(internalID) then
        self:SetSpellType(DraftCardMixin.SpellType.Ability, rarity)
        self:SetArtwork(DraftCardMixin.ArtworkStyle.Paper)
    else
        C_Logger.Error("Unhandled spell type: "..entry.Type.." for ID: "..internalID)
    end

    self:SetCurrencyDisplay(teCost, aeCost)
    self.Name:SetText(spellName)
    self.spellID = spellID
    self:RefreshSpellDescription()

    local masterySpell = CharacterAdvancementUtil.GetGrantingMasteryByID(internalID)
    if masterySpell then
        rarityCost = 0 -- masteries mean no rarity cost
        self:SetFromMastery(masterySpell)
    else
        self:SetFromClass()
    end
    
    self.SpellIcon:SetSpell(spellID)
    
    self.spellID = spellID
    self.internalID = internalID
end

function DraftCardMixin:SetBrokenCard(internalID)
    self.internalID = internalID
    self.spellID = nil
    self.quality = nil
    self:MarkCardInvalid()

    self:SetRarityDisplay(nil, 0, false, DRAFT_GEMS_WONT_REDUCE_CHANCE)
    self:SetSpellType(DraftCardMixin.SpellType.Ability, nil)
    self:SetArtwork(DraftCardMixin.ArtworkStyle.Paper)
    self:SetClass()
    if self.Background and self.Background.SetAtlas then
        self.Background:SetAtlas("draft-card-back")
    end

    self:SetCurrencyDisplay(0, 0)
    self.Name:SetText(DRAFT_CARD_BROKEN or "Broken Card")
    self.Description:SetText(DRAFT_CARD_BROKEN_DESC or "Unable to load this draft pick. Please roll again or contact support.")
    if self.SpellIcon then
        if self.SpellIcon.SetPortraitTexture then
            self.SpellIcon:SetPortraitTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
        elseif self.SpellIcon.SetTexture then
            self.SpellIcon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark")
        elseif self.SpellIcon.SetSpell then
            self.SpellIcon:SetSpell(nil)
        end
    end
    self:SetFromGeneric()
end

function DraftCardMixin:SetMysticEnchant(spellID)
    self:MarkCardValid()

    local mysticEnchant = C_MysticEnchant.GetEnchantInfoBySpell(spellID)
    if not mysticEnchant then
        self:MarkCardInvalid()
        SendSystemMessage("|cffFF4444[Draft"..self:GetID().."]: Invalid Mystic Enchant: " .. spellID .. ". Your patch is likely out of date! Try repairing your client via the launcher!")
        return C_Logger.Error("Invalid Mystic Enchant for Draft Card. Spell ID: %s", spellID)
    end

    local rarity = Enum.EnchantQualityEnum[mysticEnchant.Quality]
    local spellName = mysticEnchant.SpellName

    self:SetQuality(rarity)
    self:SetRarityDisplay(rarity, 0, true)
    self:SetClass()

    self.Background:SetAtlas("default-talent-shaman-elemental", Const.TextureKit.IgnoreAtlasSize)
    
    self:SetSpellType(DraftCardMixin.SpellType.MysticEnchant, rarity)
    self:SetArtwork(DraftCardMixin.ArtworkStyle.Paper)

    self:SetCurrencyDisplay(0, 0)
    self.Name:SetText(spellName)
    self.spellID = spellID
    self:RefreshSpellDescription()
    self:SetFromGeneric()
    self.SpellIcon:SetSpell(spellID)
    self:SetTitleDisplay(ITEM_QUALITY_COLORS[rarity]:WrapText(_G["MYSTIC_ENCHANT"..rarity]), "PTFontHighlightLarge")
    self.internalID = nil
end

function DraftCardMixin:SetRarityDisplay(rarity, rarityCost, showRarity, noRarityText)
    self:SetQuality(rarity)
    self.Rarity:SetNumGems(rarityCost, rarityCost)
    self.Rarity:SetGemQuality(rarity)
    if showRarity then
        self.Rarity.NoGemBackground:Hide()
        self.Rarity.NoGemText:Hide()
        self.Rarity.Background:Show()
    else
        self.Rarity.NoGemBackground:Show()
        self.Rarity.NoGemText:SetText(noRarityText)
        self.Rarity.Background:Hide()
    end
end

function DraftCardMixin:SetTitleDisplay(text, font)
    if text then
        self.Name.MasteryHeader:Show()
        self.Name.MasteryText:Show()
        self.Name.MasteryText:SetText(text)
        if font then
            self.Name.MasteryText:SetFontObject(font)
        else
            self.Name.MasteryText:SetFontObject("PTFontHighlight")
        end
    else
        self.Name.MasteryHeader:Hide()
        self.Name.MasteryText:Hide()
    end
end

function DraftCardMixin:PlaySlideInAnimation()
    local index = self:GetID() - 1
    self:StartAnimation(index * 0.25, 4, 6, -900, 0)
    self.Cover.BackgroundGlow.Anim:Stop()
    self.Cover.BackgroundGlow:Hide()
    self.MainButton:Disable()
end

function DraftCardMixin:IsAnimating()
    return self:GetScript("OnUpdate") ~= nil
end

function DraftCardMixin:StartAnimation(delay, moveSpeed, alphaSpeed, initialX, initialY)
    self:EnableMouse(false)
    self.Cover:EnableMouse(false)
    self.SpellIcon:EnableMouse(false)
    if self.AnimationDelay then
        self.AnimationDelay:Cancel()
    end
    self:SetScript("OnUpdate", nil)
    self:SetAlpha(0)
    self:SetPointOffset(initialX, initialY)
    self.initialOffsetX = initialX
    self.initialOffsetY = initialY
    self.moveTime, self.alphaTime = 0, 0
    self.moveSpeed = moveSpeed or 1
    self.alphaSpeed = alphaSpeed or 1

    self.AnimationDelay = Timer.NewTimer(delay or 0, function()
        self.AnimationDelay = nil
        self:SetScript("OnUpdate", self.AnimationOnUpdate)
    end)
end

function DraftCardMixin:AnimationOnUpdate(elapsed)
    local done = true
    local t = EaseInOut(self.moveTime, 4)
    local offsetX = math.lerp(self.initialOffsetX, 0, t)
    local offsetY = math.lerp(self.initialOffsetY, 0, t)
    self.moveTime = MClamp(self.moveTime + (elapsed * self.moveSpeed), 0, 1)
    if self.moveTime < 1 then
        self:SetPointOffset(offsetX, offsetY)
        done = false
    else
        self:SetPointOffset(0, 0)
    end
    
    local alpha = math.lerp(0, 1, EaseIn(self.alphaTime, 4))
    self.alphaTime = MClamp(self.alphaTime + (elapsed * self.alphaSpeed), 0, 1)
    if self.alphaTime < 1 then
        self:SetAlpha(alpha)
        done = false
    else
        self:SetAlpha(1)
    end

    if done then
        self:StopAnimation()
    end
end

function DraftCardMixin:StopAnimation()
    self:EnableMouse(true)
    self.Cover:EnableMouse(true)
    self.SpellIcon:EnableMouse(true)
    if self.AnimationDelay then
        self.AnimationDelay:Cancel()
    end
    if self:GetScript("OnUpdate") then
        self:SetScript("OnUpdate", nil)
    end
    self:SetAlpha(1)
    self:ResetPointsOffset()
    self.initialOffsetX = nil
    self.initialOffsetY = nil
    self.moveTime, self.alphaTime = nil, nil
    self.moveSpeed = nil
    self.alphaSpeed = nil

    if C_CVar.GetBool("autoRevealDraft") then
        self.Cover:Click()
    end

    self:StartRevealCooldown()
end 

function DraftCardMixin:StartRevealCooldown()
    self.MainButton:Disable()
    if self.MainButton.wait then
        self.MainButton.wait:Cancel()
    end
    self.MainButton.wait = Timer.NewTimer(0.5, function()
        self.MainButton:Enable()
        self.MainButton.wait = nil
    end)
end

local particlePositions = {
    { -118, 128, offset = { -32, 32 }, degrees = -60 },
    { 118, 128, offset = { 32, 32 }, degrees = 60, flipH = true },
    { -118, -128, offset = { -32, -92 }, degrees = -60, flipV = true },
    { 118, -128, offset = { 32, -32 }, degrees = 60, flipH = true, flipV = true },
    { 118, 0, offset = { 92, 0 }, degrees = 60 },
    { -118, 0, offset = { -62, 0 }, degrees = -60, flipH = true, flipV = true },
    { 0, 138, offset = { 0, 92 }, degrees = 60 },
    { 84, 128, offset = { 32, 32 }, degrees = 60 },
    { -84, 128, offset = { -32, 32 }, degrees = -60, flipH = true, flipV = true },
    { 0, -138, offset = { 0, -62 }, degrees = 60, flipH = true, flipV = true },
    { 84, -128, offset = { 32, -32 }, degrees = 60 },
    { -84, -128, offset = { -32, -62 }, degrees = -60 },
    { 84, 0, offset = { 62, 0 }, degrees = 60 },
    { -84, 0, offset = { -92, 0 }, degrees = -60, flipH = true },
}
function DraftCardMixin:PlayRevealAnimation()
    self:ShowCard()
    self:RefreshSpellDescription()
    self:UpdateModifierStateRegistration()
    if C_CVar.GetBool("autoRevealDraft") then
        self.ParticleSpawn.Glow.FadeOutLite:Play()
    else
        self.ParticleSpawn.Glow.FadeOut:Play()
    end
    particlePool:ReleaseAllWithParent(self.ParticleSpawn)

    if not self.quality or self.quality < 2 then
        return
    end

    local color = self.color or ITEM_QUALITY_COLORS[1]
    for i = 1, #particlePositions do
        local positionData = particlePositions[i]
        local particle = particlePool:Acquire()
        particle:SetParent(self.ParticleSpawn)
        particle:SetVertexColor(color:GetRGBA())
        particle:Show()
        particle:SetPoint("CENTER", self.ParticleSpawn, "CENTER", unpack(positionData))

        if i > 6 then
            particle:SetTexture("SPELLS\\t_vfx_smoke_cigarette_blackwhite")
        else
            particle:SetTexture("SPELLS\\t_vfx_freeze_c")
        end
        particle.Anim:PlayAt(positionData.offset[1], positionData.offset[2], positionData.degrees, positionData.flipH, positionData.flipV)
    end
end

function DraftCardMixin:IsLuckySkillCard()
    return self.internalID and DraftUtil.IsIndexLuckySkillCard(self:GetID())
end

function DraftCardMixin:IsSkillCard()
    return self.internalID and (DraftUtil.IsIndexSkillCard(self:GetID()))
end

function DraftCardMixin:IsGoldenSkillCard()
    return self.internalID and DraftUtil.IsSkillCardIDGold(self.internalID)
end

function DraftCardMixin:IsTalent()
    return self.internalID and C_CharacterAdvancement.IsTalentID(self.internalID)
end

function DraftCardMixin:ShowCover()
    self.ParticleSpawn.Glow:Hide()
    self.ParticleSpawn.Glow.FadeOut:Stop()
    self:HideCard()

    -- Ensure the cover visuals are restored even if the cover frame never hid.
    if self.Cover.Background then
        self.Cover.Background:Show()
    end
    if self.Cover.BackgroundGlow then
        self.Cover.BackgroundGlow.Anim:Stop()
        self.Cover.BackgroundGlow:Hide()
    end
    if self.Cover.CloseButton then
        self.Cover.CloseButton:Show()
    end

    if IsCardSwap() then
        self.Cover:SetArtStyle(DraftCardCoverMixin.ArtStyle.Darkmoon)
    elseif self:IsSkillCard() or self:IsLuckySkillCard() then
        if self:IsGoldenSkillCard() then
            self.Cover:SetArtStyle(DraftCardCoverMixin.ArtStyle.GoldSkill)
        else
            self.Cover:SetArtStyle(DraftCardCoverMixin.ArtStyle.Skill)
        end
    else
        self.Cover:SetArtStyle(DraftCardCoverMixin.ArtStyle.Default)
    end
    self.Cover:Show()
    self:UpdateModifierStateRegistration()
end

function DraftCardMixin:ShowCard()
    for _, element in ipairs(self.Children) do
        if element == self.BackgroundHover then
            element:SetShown(self.quality and self.quality > Enum.ItemQuality.Common)
        else
            element:Show()
        end
    end
end

function DraftCardMixin:HideCard()
    for _, element in ipairs(self.Children) do
        element:Hide()
    end
end

function DraftCardMixin:HideCover()
    self.Cover:Hide()
    self.ParticleSpawn.Glow:Hide()
    self:ShowCard()
    self:RefreshSpellDescription()
    self:UpdateModifierStateRegistration()
end

function DraftCardMixin:IsCoverFadingOrHidden()
    local glow = self.ParticleSpawn.Glow
    return not self.Cover:IsShown() or glow.FadeOut:IsPlaying()
end

function DraftCardMixin:IsValid()
    return self.invalidData == false
end

function DraftCardMixin:MarkCardInvalid()
    self.invalidData = true
end

function DraftCardMixin:MarkCardValid()
    self.invalidData = false
end 



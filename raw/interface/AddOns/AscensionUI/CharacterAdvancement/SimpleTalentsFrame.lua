local Addon = select(2, ...)
-------------------------------------------------------------------------------
--                              Influence Slot                               --
-------------------------------------------------------------------------------
local InfluenceSlotMixin = {
    SpellRemap = {
        [75] = 965202, -- auto shot
        [1515] = 965200, -- tame beast
    }
}

function InfluenceSlotMixin:OnReceiveDrag()
    local dragType, dragID = GetCursorInfo()
    if dragType ~= "spell" then return end

    local spellID = C_Spell:GetSpellID(dragID, BOOKTYPE_SPELL)

    if self.SpellRemap[spellID] then
        spellID = self.SpellRemap[spellID]
    end

    if spellID then
        self:SetSpell(spellID)
    end

    ClearCursor()
end

function InfluenceSlotMixin:SetSpell(spellID)
    spellID = C_Spell.GetFirstRank(spellID) or spellID
    if self.spell == spellID then return end

    if CA2.SpellInfluences[spellID] then
        return
    end

    if self.spell then
        CA2.SpellInfluences[self.spell] = nil
        CA2.CDB.SimpleTalentSlots[self:GetID()] = nil
    end

    if not spellID then
        self.Icon:SetTexture(nil)
        return
    end

    local parent = self:GetParent()

    self.spell = spellID

    local _, _, icon = GetSpellInfo(spellID)
    self.Icon:SetTexture(icon)

    if self:IsMouseOver() then
        self:CallScript("OnEnter")
    end
    
    CA2.SpellInfluences[self.spell] = true
    CA2.CDB.SimpleTalentSlots[self:GetID()] = self.spell
    parent:LoadSuggestedTalents()
end

function InfluenceSlotMixin:ClearSpell(muteSound)
	local parent = self:GetParent()

    CA2.SpellInfluences[self.spell] = nil
    CA2.CDB.SimpleTalentSlots[self:GetID()] = nil
    self.spell = nil
    self.Icon:SetTexture("")
    if not muteSound then
        PlaySound(SOUNDKIT.SPELL_ICON_DROP_75)
    end
    self:CallScript("OnLeave")
    parent:LoadSuggestedTalents()
end

function InfluenceSlotMixin:OnMouseUp(button)
	CA2:UnSelectCurrent()

    if self.spell and not GetCursorInfo() then
        self:ClearSpell()
        return
    end

    if button == "LeftButton" and GetCursorInfo() then
        self:OnReceiveDrag()
        return
    end
end

function InfluenceSlotMixin:CheckIfValid()
    if self.spell then
        if not C_Spell:IsAnyRankKnown(self.spell) then
            self:ClearSpell(true)
            return
        end
    end
end

function InfluenceSlotMixin:OnShow()
    self:CheckIfValid()
end

function InfluenceSlotMixin:OnEnter()
	self.highlight:Show()

	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	if self.spell then
		GameTooltip:SetHyperlink("spell:"..self.spell)
		GameTooltip:AddLine("Click to Remove", 0, 0.82, 1, false)
	else
        local dragType, dragID = GetCursorInfo()
        if not(dragType) or dragType ~= "spell" then 
            HelpTip:Show("CA2_SIMPLE_TALENTS_INFLUENCE_SLOT_HELP")
    		GameTooltip:AddLine("Influence Ability Slot", 1, 1, 1)
    		GameTooltip:AddLine("|cffFFFFFFDrag|r an |cffFFFFFFAbility|r from the |cffFFFFFFright side|r of the Character Advancement here.", 1, 0.82, 0, true)
        end
    end

	GameTooltip:Show()
end

function InfluenceSlotMixin:OnLeave()
    HelpTip:Hide("CA2_SIMPLE_TALENTS_INFLUENCE_SLOT_HELP")
	self.highlight:Hide()
	GameTooltip:Hide()
end

function InfluenceSlotMixin:PlayPulse()
	self.glow:Show()
	self.glow.pulse:Stop()
	self.glow.pulse:Play()
end

function InfluenceSlotMixin:HideSparkles()
	for _, v in pairs(self.sparkles) do
		v:Hide()
	end
end

function InfluenceSlotMixin:StopPulse()
	self.glow:Hide()
end

function InfluenceSlotMixin:ShowSparkles()
	for i, v in pairs(self.sparkles) do
		v.movement:Stop()
		v.movement:Play()
		v:Show()
	end
end
-------------------------------------------------------------------------------
--                               InfluenceGlow                               --
-------------------------------------------------------------------------------
local influenceGlowMixin = {}

function influenceGlowMixin:SetSize(...)
	self.texture:SetSize(...)
	self.effect:SetSize(...)
end

function influenceGlowMixin:SetPoint(...)
	self.texture:SetPoint(...)
	self.effect:SetPoint(...)
end

function influenceGlowMixin:SetTexCoord(...)
	self.texture:SetTexCoord(...)
	self.effect:SetTexCoord(...)
end

function influenceGlowMixin:StopAnim()
	self.texture.appear:Stop()
	self.effect.appear:Stop()
end

function influenceGlowMixin:PlayAnim()
	self.texture.appear:Play()
	self.effect.appear:Play()
end

function influenceGlowMixin:Show()
	self.texture:Show()
	self.effect:Show()
end

function influenceGlowMixin:Hide()
	self.texture:Hide()
	self.effect:Hide()
end

function influenceGlowMixin:SetTexture(...)
	self.texture:SetTexture(...)
	self.effect:SetTexture(...)
end

function influenceGlowMixin:IsVisible()
	return self.texture:IsVisible()
end

function influenceGlowMixin:GetParent()
	return self.texture:GetParent()
end

-------------------------------------------------------------------------------
--                                Enchant Slot                               --
-------------------------------------------------------------------------------
local enchantCheckButtonMixin = {}

function enchantCheckButtonMixin:OnShow()
    self:SetChecked(CA2.SuggestionsIncludeEnchant)
    self:HookEvent("PLAYER_EQUIPMENT_CHANGED")

    local enchant = MysticEnchantUtil.GetLegendaryEnchantID("player")
    local parent = self:GetParent()

    if enchant then
        self.fakeTooltip:Hide()
        local name, _, icon = GetSpellInfo(enchant)
        local line = format("Consider |cffFF8000[%s]|r\nin suggestions", name)
        SetPortraitToTexture(self.Icon, icon)
        self:GetNormalTexture():SetDesaturated(false)
        self:Enable()
        self.tooltip = line

        if (self.extraCheckButton) then
            self.extraCheckButton:Show()
            self.extraCheckButton:SetText(line)
        end
    else
        if (self.extraCheckButton) then
            self.extraCheckButton:Hide()
        end
        self.fakeTooltip:Show()
        self:SetChecked(false)
        self:GetNormalTexture():SetDesaturated(true)
        self:Disable()
        SetPortraitToTexture(self.Icon, "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
    end

    -- fix for: (after /reload we may have no talents loaded despite GetChecked() ~= nil)
    if CA2.SuggestionsIncludeEnchant and not(parent.hasSpell) then
        parent:LoadSuggestedTalents()
    end
end

function enchantCheckButtonMixin:OnClick()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)

    if (self.extraCheckButton) then
        self.extraCheckButton:SetChecked(self:GetChecked())
    end
    
    if self:GetChecked() then
        CA2.SuggestionsIncludeEnchant = true
    else
        CA2.SuggestionsIncludeEnchant = false
    end
    CA2.CDB.SuggestionsIncludeEnchant = CA2.SuggestionsIncludeEnchant
    self:GetParent():LoadSuggestedTalents()
end

function enchantCheckButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:AddLine(self.tooltip, 1, 1, 1)
    GameTooltip:Show()
end

function enchantCheckButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function enchantCheckButtonMixin:OnHide()
    self:UnhookEvent("PLAYER_EQUIPMENT_CHANGED")
end

function enchantCheckButtonMixin:PLAYER_EQUIPMENT_CHANGED()
    if not(self.needsUpdate) then
        self.needsUpdate = true

        -- we need to wait a bit for paper doll update
        Timer.After(0.2, function()
            self:OnShow()
            self.needsUpdate = false
            self:GetParent():UpdateInfluenceGlow()
        end)
    end
end
-------------------------------------------------------------------------------
--                          Suggested Talents Frame                          --
-------------------------------------------------------------------------------
SimpleTalentsMixin = {}

SimpleTalentsMixin.TUTORIAL_NORMAL = "|cffFFFFFFDrag|r a known |cffFFFFFFAbility|r to one of\nthe Influence |cffFFFFFFAbility Slots|r to see\nSuggested Talents"
SimpleTalentsMixin.TUTORIAL_LOCKED = "|cffFF0000"..string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, 10).."|r"
SimpleTalentsMixin.SPARKLE_PER_SLOT = 4
SimpleTalentsMixin.INFLUENCE_SLOT_COUNT = 4
SimpleTalentsMixin.MAX_SIMPLE_TALENTS = 6

function SimpleTalentsMixin:CreateEnchantCheckButton()
    local checkButton = CreateFrame("CheckButton", "$parentIncludeEnchantButton", self, nil)
    checkButton:SetSize(56, 56)
    checkButton:SetNormalTexture(Addon.AwTexPath.."EnchOverhaul\\BorderNewLeg")
    checkButton:SetHighlightTexture(Addon.AwTexPath.."enchant\\EnchantBorder_highlight")
    checkButton:GetHighlightTexture():ClearAllPoints()
    checkButton:GetHighlightTexture():SetPoint("CENTER")
    checkButton:GetHighlightTexture():SetSize(80, 80)
    checkButton:GetNormalTexture():SetDrawLayer("ARTWORK")

    checkButton.fakeTooltip = CreateFrame("FRAME", "$parent.fakeTooltip", checkButton, nil)
    checkButton.fakeTooltip:SetPoint("CENTER")
    checkButton.fakeTooltip:SetSize(56, 56)
    checkButton.fakeTooltip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:AddLine("Equip a |cffCC6600Legendary Mystic Enchant|r\nto include in suggestions", 1, 1, 1)
        GameTooltip:AddLine("Mystic Enchants can be found on gear or in Mystic Enchants Collection (Unlocks at level 60)", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    checkButton.fakeTooltip:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    checkButton.fakeTooltip:EnableMouse(true)

    checkButton.Icon = checkButton:CreateTexture(nil, "BACKGROUND")
    checkButton.Icon:SetSize(42,42)
    checkButton.Icon:SetPoint("CENTER", 0, -1)

    Mixin(checkButton, enchantCheckButtonMixin)
    checkButton:SetScript("OnClick", checkButton.OnClick)
    checkButton:SetScript("OnShow", checkButton.OnShow)
    checkButton:SetScript("OnEnter", checkButton.OnEnter)
    checkButton:SetScript("OnLeave", checkButton.OnLeave)
    checkButton:SetScript("OnHide", checkButton.OnHide)

    checkButton.extraCheckButton = CreateFrame("CheckButton", "$parentincludeEnchantCheckButton", self, "SquareIconCheckButtonTemplate")
    checkButton.extraCheckButton:SetText("Consider in suggestions")
    checkButton.extraCheckButton:GetFontString():SetPoint("LEFT", checkButton.extraCheckButton, "RIGHT", 4, 0)
    checkButton.extraCheckButton:GetFontString():SetJustifyH("LEFT")
    checkButton.extraCheckButton.SetTextOld = checkButton.extraCheckButton.SetText

    checkButton.extraCheckButton.TextShadow = checkButton.extraCheckButton:CreateTexture()
    checkButton.extraCheckButton.TextShadow:SetAtlas("common-shadow-circle", Const.TextureKit.IgnoreAtlasSize)
    checkButton.extraCheckButton.TextShadow:SetPoint("CENTER", checkButton.extraCheckButton:GetFontString(), 0, 0)
    checkButton.extraCheckButton.TextShadow:SetSize(192, 64)

    function checkButton.extraCheckButton:SetText(...)
        local fontString = self:GetFontString()

        self:SetTextOld(...)
        self:SetPoint("TOP", checkButton, "BOTTOM", -(fontString:GetWidth()/2), 8)
        self.TextShadow:SetWidth(fontString:GetWidth()+32)
    end

    checkButton.extraCheckButton:SetScript("OnShow", function(self)
        self:SetChecked(CA2.SuggestionsIncludeEnchant)
    end)

    checkButton.extraCheckButton:SetScript("OnClick", function(self)
        checkButton:Click()
    end)

    return checkButton
end

function SimpleTalentsMixin:CreateAutoCastSparkle()
	local texture = self:CreateTexture(nil, "OVERLAY")

	texture:SetSize(12,12)
	texture:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockets")
	texture:SetTexCoord(0.3984375, 0.4453125, 0.40234375, 0.44921875)
	texture:SetBlendMode("ADD")
	texture:SetVertexColor(1, 1, 0.5)

	texture.movement = texture:CreateAnimationGroup()

	texture.movement.disappear = texture.movement:CreateAnimation("Alpha")
    texture.movement.disappear:SetChange(-1)
    texture.movement.disappear:SetDuration(0)
    texture.movement.disappear:SetOrder(1)

	texture.movement.fadeIn = texture.movement:CreateAnimation("Alpha")
    texture.movement.fadeIn:SetChange(1)
    texture.movement.fadeIn:SetDuration(1)
    texture.movement.fadeIn:SetOrder(2)
    texture.movement.fadeIn:SetSmoothing("IN")

	texture.movement.translation = texture.movement:CreateAnimation("Translation")
    texture.movement.translation:SetDuration(4)
    texture.movement.translation:SetOrder(2)
    texture.movement.translation:SetSmoothing("IN_OUT")
    texture.movement.translation:SetOffset(128, 128)

	texture.movement.fadeOut = texture.movement:CreateAnimation("Alpha")
    texture.movement.fadeOut:SetChange(-1)
    texture.movement.fadeOut:SetDuration(1)
    texture.movement.fadeOut:SetOrder(2)
    texture.movement.fadeOut:SetStartDelay(3)
    texture.movement.fadeOut:SetSmoothing("OUT")

    function texture.movement:SetDuration(value)
    	self.fadeOut:SetStartDelay(value-1)
    	self.translation:SetDuration(value)
    end

    texture.movement:SetScript("OnFinished", function(self)
    	self:Play()
    end)

	return texture
end

function SimpleTalentsMixin:CreateInfluenceSlotGlowTexture()
	local texture = self:CreateTexture(nil, "ARTWORK")
	texture:SetSize(186, 186)
	texture:SetTexture("Interface\\suggestedTalents\\slot_glow")

    texture.appear = texture:CreateAnimationGroup()

    texture.appear.Alpha0 = texture.appear:CreateAnimation("Alpha")
    texture.appear.Alpha0:SetChange(-1)
    texture.appear.Alpha0:SetDuration(0)
    texture.appear.Alpha0:SetOrder(1)
    texture.appear.Alpha0:SetSmoothing("IN")

    texture.appear.Alpha1 = texture.appear:CreateAnimation("Alpha")
    texture.appear.Alpha1:SetChange(1)
    texture.appear.Alpha1:SetDuration(0.3)
    texture.appear.Alpha1:SetOrder(2)
    texture.appear.Alpha1:SetSmoothing("OUT")

	return texture
end

function SimpleTalentsMixin:CreateInfluenceSlotGlow()
	local glow = {}

	glow.texture = self:CreateInfluenceSlotGlowTexture()
	glow.effect = self:CreateInfluenceSlotGlowTexture()

	glow.effect:SetAlpha(0)
	glow.effect:SetDrawLayer("OVERLAY")

	glow.effect.appear.Alpha1:SetSmoothing("IN")
	glow.effect.appear.Alpha1:SetDuration(0.1)

    glow.effect.appear.Alpha2 = glow.effect.appear:CreateAnimation("Alpha")
    glow.effect.appear.Alpha2:SetChange(-1)
    glow.effect.appear.Alpha2:SetDuration(0.6)
    glow.effect.appear.Alpha2:SetOrder(3)
    glow.effect.appear.Alpha2:SetSmoothing("OUT")

    Mixin(glow, influenceGlowMixin)

	SetParentArray(glow, "InfluenceGlows")

	return glow
end

function SimpleTalentsMixin:CreateInfluenceSlot(name)
    local button = CreateFrame("BUTTON", "$parent."..name, self)
    SetParentArray(button, "InfluenceSlots")
    
    button:SetSize(80, 80)
    --button:SetBackdrop(GameTooltip:GetBackdrop())
    button.BG = button:CreateTexture(nil, "BACKGROUND")
    button.BG:SetTexture("Interface\\suggestedTalents\\suggestedSlotBG") 
    button.BG:SetSize(80, 80)
    button.BG:SetPoint("CENTER", 0, 0)

    button.Icon = button:CreateTexture(nil, "BORDER")
    button.Icon:SetSize(34, 34)
    button.Icon:SetPoint("CENTER", 0, 2)

    button.slot = button:CreateTexture(nil, "ARTWORK")
    button.slot:SetTexture("Interface\\BUTTONS\\UI-Quickslot2")
    button.slot:SetSize(58, 58)
    button.slot:SetPoint("CENTER", button.Icon, 0, 0)

    button.highlight = button:CreateTexture(nil, "OVERLAY")
    button.highlight:SetTexture("Interface\\suggestedTalents\\suggestedSlothighlight")
    button.highlight:SetSize(80, 80)
    button.highlight:SetPoint("CENTER", 0, 0)
    button.highlight:SetBlendMode("ADD")
    button.highlight:Hide()

    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetTexture("Interface\\suggestedTalents\\suggestedSlotGlow")
    button.glow:SetSize(80, 80)
    button.glow:SetPoint("CENTER", 0, 0)
    button.glow:SetBlendMode("ADD")
    button.glow:Hide()

    button.glow.pulse = button.glow:CreateAnimationGroup()

    button.glow.pulse.Alpha0 = button.glow.pulse:CreateAnimation("Alpha")
    button.glow.pulse.Alpha0:SetChange(-1)
    button.glow.pulse.Alpha0:SetDuration(0.75)
    button.glow.pulse.Alpha0:SetOrder(1)
    button.glow.pulse.Alpha0:SetSmoothing("IN")

    button.glow.pulse.Alpha1 = button.glow.pulse:CreateAnimation("Alpha")
    button.glow.pulse.Alpha1:SetChange(1)
    button.glow.pulse.Alpha1:SetDuration(0.75)
    button.glow.pulse.Alpha1:SetOrder(2)
    button.glow.pulse.Alpha1:SetSmoothing("OUT")

    button.glow.pulse:SetScript("OnFinished", function(self)
    	self:Play()
    end)

    Mixin(button, InfluenceSlotMixin)
    button:SetScript("OnReceiveDrag", button.OnReceiveDrag)
    button:SetScript("OnMouseUp", button.OnMouseUp)
    button:SetScript("OnShow", button.OnShow)
    button:SetScript("OnEnter", button.OnEnter)
    button:SetScript("OnLeave", button.OnLeave)

    return button
end

function SimpleTalentsMixin:CreateTalentButton(index)
    local button = CA2:CreateTalentButton(index, self, "$parentTalentButton"..index)
    button:SetScale(1)
    SetParentArray(button, "Buttons", index)

    button.glow = button:CreateTexture(nil, "BACKGROUND")
    button.glow:SetTexture("Interface\\suggestedTalents\\talent_glow")
    button.glow:SetVertexColor(1, 1, 0)
    button.glow:SetPoint("CENTER", -0.5, 0)
    button.glow:SetSize(103, 103)
    button.glow:SetBlendMode("ADD")

    return button
end

function SimpleTalentsMixin:CreateTalentButtonBestSuggestion(index)
    local button = self:CreateTalentButton(index)
    button:SetScale(1.1)

    button.bestIcon = CreateFrame("Frame", "$parent.bestIcon", button)
    button.bestIcon:EnableMouse(true)
    button.bestIcon:SetPoint("CENTER", button, "TOPLEFT", 0, -3)
    button.bestIcon:SetSize(21, 25)

    button.icon = button.bestIcon:CreateTexture("$parent,icon", "OVERLAY")
    button.icon:SetAllPoints()
    button.icon:SetAtlas("loottoast-arrow-green", Const.TextureKit.IgnoreAtlasSize)

    button.highlight = button.bestIcon:CreateTexture("$parent.highlight", "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetAtlas("loottoast-arrow-green", Const.TextureKit.IgnoreAtlasSize)
    button.highlight:SetBlendMode("ADD")

    button.bestIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("This is the best suggestion!", 1, 1, 1, 1, false)
        GameTooltip:AddLine("Try adding an influence spell if this isn't a good choice.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    
    button.bestIcon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    return button
end

function SimpleTalentsMixin:LoadSuggestedTalents()
    local suggestions = SpellSuggestions:GetRecommendedTalents(CA2.SpellInfluences, CA2.SuggestionsIncludeEnchant and { MysticEnchantUtil.GetLegendaryEnchantID("player") })
    
    local updated = {}
    -- this kinda sucks but without a major rewrite this is how it is
    -- first iteration, update any existing spell 
    if CA2:IsShown() then -- only do this if we're actively looking at talents. 
        for i = 1, #self.Buttons do
            local button = self.Buttons[i]
            for j = #suggestions, 1, -1 do
                local suggestion = suggestions[j]
                local talentID = suggestion[1]
                local hasTalent = C_CharacterAdvancement.IsKnownID(talentID)
                if hasTalent and button.Talent == talentID then
                    CA2:SetTalentButtonTalent(button, talentID)
                    button:Show()
                    updated[i] = true
                    table.remove(suggestions, j)
                    break
                end
            end
        end
    end

    -- second iteration fill the rest of the buttons with whatever is left
    for i = 1, #self.Buttons do
        if not updated[i] then
            local suggestion = suggestions[i]
            local button = self.Buttons[i]
            if suggestion then
                CA2:SetTalentButtonTalent(button, suggestion[1])
                button:Show()
            else
                button:Hide()
            end
        end
    end

    self:UpdateInfluenceGlow()
end

function SimpleTalentsMixin:UpdateTutorialText()
    if self.lowLevel then
        self.tutorialText:SetText(self.TUTORIAL_LOCKED)
        self.hasSpell = false
        self.hasEnchant = false
    else
        self.tutorialText:SetText(self.TUTORIAL_NORMAL)
    end

    if not(self.hasSpell) and not(self.hasEnchant) then
        self.autoLearn:Hide()
        self.tutorialText:Show()
        self.tutorialTextShadow:Show()
        for i = 1, #self.Buttons do
            self.Buttons[i]:Hide()
        end
    else
        self.autoLearn:Show()
        self.tutorialText:Hide()
        self.tutorialTextShadow:Hide()
    end

    self.toggleButton:UpdateMode()
end

function SimpleTalentsMixin:UpdateInfluenceGlow()
	self.hasSpell = false
	self.hasEnchant = (CA2.SuggestionsIncludeEnchant and MysticEnchantUtil.GetLegendaryEnchantID("player")) or false
    self.lowLevel = UnitLevel("player") < 10

    for k, slot in ipairs(self.InfluenceSlots) do
    	local glow = self.InfluenceGlows[k]

    	if (glow) then
	        if slot.spell then
	        	slot:StopPulse()
	        	self.hasSpell = true

	        	if not(glow:IsVisible()) then
		            glow:Show()
		            glow:StopAnim()
		            glow:PlayAnim()
					slot:ShowSparkles()
		        end
	        else
	        	slot:HideSparkles()
                if not(self.lowLevel) then
                    slot:PlayPulse()
                end
	            glow:Hide()
	        end
	    end
    end

	local enchantGlow = (#self.InfluenceSlots < #self.InfluenceGlows) and self.InfluenceGlows[#self.InfluenceGlows] -- make sure we have an extra glow for enchant

    if enchantGlow then
    	if (self.hasEnchant) then
	        enchantGlow:Show()
	        enchantGlow:StopAnim()
	        enchantGlow:PlayAnim()
			InfluenceSlotMixin.ShowSparkles(self.includeEnchant)
	    else
	    	InfluenceSlotMixin.HideSparkles(self.includeEnchant)
	    	enchantGlow:Hide()
	    end
    end

    self:UpdateTutorialText()
end

function SimpleTalentsMixin:PLAYER_LEVEL_UP()
    self:LoadSuggestedTalents()
end

function SimpleTalentsMixin:OnShow()
    self:HookEvent("PLAYER_LEVEL_UP")
    HelpTip:Show("CA2_SIMPLE_TALENTS1")
    self:UpdateInfluenceGlow()
end

function SimpleTalentsMixin:OnHide()
    HelpTip:Hide("CA2_SIMPLE_TALENTS1")
    HelpTip:Hide("CA2_SIMPLE_TALENTS2")
    HelpTip:Hide("CA2_SIMPLE_TALENTS4")
    self:UnhookEvent("PLAYER_LEVEL_UP")
end
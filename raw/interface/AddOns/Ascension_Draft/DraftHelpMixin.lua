DraftHelpMixin = {}

function DraftHelpMixin:OnHide()
	self:ClearAndSetPoint("BOTTOM", UIParent, "CENTER", 0, 185)
end

function DraftHelpMixin:SetFormattedTip(text, ...)
	self.Tip:SetFormattedText(text, ...)
end

function DraftHelpMixin:SetTip(text)
	self.Tip:SetText(text)
end

function DraftHelpMixin:SetTitle(text)
	self.Title:SetText(text)
end

function DraftHelpMixin:ShowSacrificeTip(sacrificeInternalID)
	if not sacrificeInternalID then
		return self:Hide()
	end

	local spellID = CharacterAdvancementUtil.GetSpellByID(sacrificeInternalID)

	if not spellID then
		return self:Hide()
	end

	local spellLink = LinkUtil:GetSpellLink(spellID)

	self:SetFormattedTip(DRAFT_HINT_CHOOSE_SPELL_TO_SACRIFICE, spellLink)

	if DraftUtil.IsInCardSwapSacrifice() then
		self:SetTitle(DRAFT_HINT_BONUS_CARD_SWAP)
	else
		self:SetTitle(DRAFT_HINT_HAND_OF_FATE)
	end
	self:Show()
end

function DraftHelpMixin:ShowMasteryTip(masteryInternalID)
	if self:IsShown() then return end
	if not masteryInternalID then
		return self:Hide()
	end

	local spellID = CharacterAdvancementUtil.GetSpellByID(masteryInternalID)

	if not spellID then
		return self:Hide()
	end

	local spellLink = LinkUtil:GetSpellLink(spellID)
	local pickCount = GetDraftModePickCount() or 0

	local abilityText = pickCount == 1 and ABILITY or ABILITIES

	if pickCount < 3 then
		self:SetFormattedTip(DRAFT_HINT_MASTERY_OBTAINED_EXTENDED, abilityText, spellLink, pickCount)
	else
		self:SetFormattedTip(DRAFT_HINT_MASTERY_OBTAINED, abilityText, spellLink)
	end

	self:SetTitle(DRAFT_HINT_MASTERY)
	self:Show()
end

function DraftHelpMixin:ShowSwapTip()
	if self:IsShown() then return end

	self:SetTip(DRAFT_HINT_FREE_CARD_SWAP)
	self:SetTitle(DRAFT_HINT_BONUS_CARD_SWAP)
end

function DraftHelpMixin:ShowHandOfFateTip()
	if self:IsShown() then return end

	self:SetTip(DRAFT_HINT_CHOOSE_SPELL)
	self:SetTitle(DRAFT_HINT_HAND_OF_FATE)
	self:Show()
end

function DraftHelpMixin:ShowCardSwapTip()
	if self:IsShown() then return end

	self:SetTip(DRAFT_HINT_FREE_CARD_SWAP)
	self:SetTitle(DRAFT_HINT_BONUS_CARD_SWAP)
	self:Show()
end

function DraftHelpMixin:ShowSkillCardTip(index)
	if self:IsShown() then return end
	local card = _G["Card"..index]

	local cardType = card:IsLuckySkillCard() and LUCKY_SKILL_CARD or SKILL_CARD
	local spellType = card:IsTalent() and TALENT or ABILITY
	self:SetFormattedTip(DRAFT_OBTAINED_FROM_SKILL_CARD, spellType, cardType)
	self:SetTitle(cardType)
	local _, _, _, x = card:GetPoint()
	self:ClearAndSetPoint("BOTTOM", UIParent, "CENTER", x, 185)
	self:Show()
end

function DraftHelpMixin:ShowDraftHint()
	if self:IsShown() then return end

	if C_Player:GetLevel() < 10 and GetItemCount(ItemData.ABILITY_ESSENCE) == 3 then
		self:SetTip(DRAFT_HINT_LEFTOVER_ESSENCE)
	else
		self:SetTip(DRAFT_HINT_REVEAL_CARDS)
	end
	self:SetTitle(DRAFT_HINT_DRAFT_MODE)
	self:Show()
end
-------------------------------------------------------------------------------
--                                    Tag                                    --
-------------------------------------------------------------------------------
SkillCardTagMixin = {}

function SkillCardTagMixin:OnLoad()
	self:Layout()
end

function SkillCardTagMixin:Layout()
end
-------------------------------------------------------------------------------
--                                Scroll Item                                --
-------------------------------------------------------------------------------

SkillCardsScrollItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function SkillCardsScrollItemMixin:OnLoad()
	self:Layout()

	self.LevelFrame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(string.gsub( SKILLCARD_UNLOCK_MSG:format(self.Text:GetText() or ""), "\n", " "), nil, nil, nil, true)
		GameTooltip:Show()
	end)

	self.LevelFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function SkillCardsScrollItemMixin:OnClick(button)
	if button == "RightButton" then
		local cardData = self:GetScrollParent():GetItemData(self.index)
		if cardData and C_SkillCardCollection.IsCollected(cardData.CardID) and (cardData.CollectedRank == cardData.Rank) then
			local skillCardsFrame = self:GetScrollParent():GetParent()
			local tabInsetFrame = skillCardsFrame and skillCardsFrame.TabInsetFrame
			if tabInsetFrame and tabInsetFrame.SelectCard then
				tabInsetFrame:SelectCard(cardData.CardID, cardData.Rank)
			end
		end
	else
		self:OnSelected()
	end
end

function SkillCardsScrollItemMixin:OnDragStart()
	local cardData = self:GetScrollParent():GetItemData(self.index)
	if cardData and C_SkillCardCollection.IsCollected(cardData.CardID) and (cardData.CollectedRank == cardData.Rank) then
		SkillCardUtil.DraggedCardID = cardData.CardID
		SkillCardUtil.DraggedCardRank = cardData.Rank
		local _, _, icon = GetSpellInfo(cardData.SpellID)
		PickupSpell(cardData.SpellID)
	end
end

function SkillCardsScrollItemMixin:Init()
end

function SkillCardsScrollItemMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self:GetSpellID()))
	if (IsGMClient) or (PTR_CLIENT) then
		GameTooltip:AddLine("CardID: "..self:GetCardID())
	end

	GameTooltip:Show()
end

function SkillCardsScrollItemMixin:OnLeave()
	GameTooltip:Hide()
end

function SkillCardsScrollItemMixin:SetSelected()
end

function SkillCardsScrollItemMixin:Update()
	self:SetCard(self:GetScrollParent():GetItemData(self.index))

	if (self:IsMouseOver()) then
		self:OnEnter()
	end
end

function SkillCardsScrollItemMixin:GetCardID()
	return self.cardID
end

function SkillCardsScrollItemMixin:GetSpellID()
	return self.spellID
end

function SkillCardsScrollItemMixin:GetScrollParent()
	return self:GetParent():GetParent():GetParent()
end

function SkillCardsScrollItemMixin:OnSelected()
	PlaySound(SOUNDKITEXTRA.SKILL_CARD_CLICK)
	self:GetScrollParent():OnSelectedIndex(self.index)
end

function SkillCardsScrollItemMixin:SetCard(cardData)
	--[[struct: 
	{
		Expansion,
		CollectedRank,
		IsCollected,
		Class,
		CardID,
		Type,
		ItemID,
		CollectedProgress,
		Quality,
		QualityCost,
		SpellID,
		Rank,
		CollectedRank,
	}
	]]--

	local isGolden = self:GetScrollParent():IsGolden()
	local isTalent = SkillCardUtil.IsCardTypeTalent(cardData.Type)
	local name, _, icon = GetSpellInfo(cardData.SpellID)
	local quality = Enum.SkillCardQuality[cardData.Quality]
	local r, g, b, hex = GetItemQualityColor(quality)
	local qualityCost = cardData.QualityCost or 0
	local collectedProgress = math.min(1, cardData.CollectedProgress)*100
	local entry = C_CharacterAdvancement.GetEntryBySpellID(cardData.SpellID)
	local requiredLevel = entry and entry.RequiredLevel or 1

    self.spellID = cardData.SpellID
    self.cardID = cardData.CardID

	self.SpellName:SetText(hex..(name or cardData.SpellID).."|r")
	self.SpellIcon.Icon:SetTexture(icon)

	self.SpellIcon.Slot:SetVertexColor(r,g,b)
	self.SpellIcon.SlotAdd:SetVertexColor(r,g,b)
	self.LevelFrame.Text:SetText(requiredLevel)

	self.SpellIcon.RankFrame:Hide()
    self.RarityIcon1:Hide()
    self.ProgressBar:Hide()

    if C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		if (quality > 1) and (qualityCost > 0) then
			self.RarityIcon1:Show()
			self.RarityIcon1:SetColor(ITEM_QUALITY_COLORS[quality])
			self.RarityIcon1:Enable()
			self.RarityIcon1:SetText(qualityCost)
		end
	end

    self:UpdateCostIconPositions()

	if (isGolden) then
		self.GoldenTexture:Show()
	else
		self.GoldenTexture:Hide()
	end

	if (C_SkillCardCollection.IsCollected(self:GetCardID())) and (cardData.CollectedRank == cardData.Rank) then
		self.SpellName:SetAlpha(1)
		self.SpellIcon:SetAlpha(1)
		self.RarityIcon1:SetAlpha(1)
		self.RarityCost1:SetAlpha(1)
		self.LevelFrame:SetAlpha(1)
		self.GoldenTexture:SetAlpha(0.8)

		if (isTalent) then
			self.SpellIcon.RankFrame:SetRank(cardData.CollectedRank)
			self.SpellIcon.RankFrame:SetMaxRank(cardData.MaxRank)
			self.SpellIcon.RankFrame:UpdateVisual()
			self.SpellIcon.RankFrame:Hide()
			
			if collectedProgress and (collectedProgress ~= 100) then
				self.ProgressBar:SetValue(collectedProgress)
				self.ProgressBar:Hide()
			else
				self.ProgressBar:Hide()
			end
		end
	else
		self.SpellName:SetAlpha(0.5)
		self.SpellIcon:SetAlpha(0.5)
		self.RarityIcon1:SetAlpha(0.5)
		self.RarityCost1:SetAlpha(0.5)
		self.LevelFrame:SetAlpha(0.5)
		self.GoldenTexture:SetAlpha(0.5)
	end
end

function SkillCardsScrollItemMixin:UpdateCostIconPositions()
    local x = -12

    if self.RarityIcon1:IsShown() then
        self.RarityIcon1:SetPoint("RIGHT", x, 0)
        x = x - 22
    end
end

function SkillCardsScrollItemMixin:Layout()
	self.SelectedTexture = self:CreateTexture(nil, "OVERLAY") -- required for FatButtonTemplate_OnLoad
	self.SelectedTexture:SetAllPoints(true)
	self.SelectedTexture:Hide()

	FatButtonTemplate_OnLoad(self)

	self.GoldenTexture = self:CreateTexture(nil, "OVERLAY")
	self.GoldenTexture:SetTexture("Interface\\SkillCards\\SkillCardScrollItemGoldElement")
	self.GoldenTexture:SetPoint("RIGHT")
	self.GoldenTexture:SetSize(64, 56)
	self.GoldenTexture:SetAlpha(0.8)
	self.GoldenTexture:Hide()

    self.RarityIcon1 = CreateFrame("BUTTON", "$parent.RarityIcon1", self, "RarityGemTemplate")
    self.RarityIcon1:SetSize(22, 22)
    self.RarityIcon1:Hide()

    self.RarityCost1 = self.RarityIcon1:CreateFontString("$parent.RarityCost1", "OVERLAY", "PTFontHighlightOutline")
    self.RarityCost1:SetPoint("CENTER", 0, -4)
    self.RarityCost1:SetSize(18,18)

 	self.LevelFrame = CreateFrame("BUTTON", "$parent.Level", self)
 	self.LevelFrame:SetSize(22, 22)
 	self.LevelFrame:SetPoint("RIGHT", -4, 0)

 	self.LevelFrame.BG = self.LevelFrame:CreateTexture(nil, "BACKGROUND")
 	self.LevelFrame.BG:SetPoint("TOPLEFT", 2, -2)
 	self.LevelFrame.BG:SetPoint("BOTTOMRIGHT", -2, 2)
 	self.LevelFrame.BG:SetTexture(0, 0, 0, 0.8)

 	self.LevelFrame:SetNormalTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
 	self.LevelFrame:GetNormalTexture():SetAtlas("minimap-trackingborder", Const.TextureKit.IgnoreAtlasSize)
 	self.LevelFrame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

 	self.LevelFrame.Text = self.LevelFrame:CreateFontString(nil, "OVERLAY")
 	self.LevelFrame.Text:SetPoint("CENTER")
 	self.LevelFrame.Text:SetFontObject(GameFontHighlightSmall)

	self.ProgressBar = CreateFrame("FRAME", "$parent.ProgressBar", self, "BetterStatusBarTemplate")
	self.ProgressBar:SetPoint("RIGHT", self.LevelFrame, "LEFT", -8, 0)
	MixinAndLoadScripts(self.ProgressBar, SkillCardProgressMinimizedBar)
	self.ProgressBar.Text:SetFontObject(GameFontHighlightSmall)
	self.ProgressBar:SetValue(50)

    self.SpellIcon = CreateFrame("FRAME", "$parent.SpellIcon", self, nil)
    self.SpellIcon:SetSize(33, 33)
    self.SpellIcon:SetPoint("LEFT", 6, 0)
    --self.SpellIcon:EnableMouse(true)

    self.SpellIcon.Slot = self.SpellIcon:CreateTexture(nil, "BACKGROUND")
	self.SpellIcon.Slot:SetTexture("Interface\\BUTTONS\\UI-EmptySlot-White")
	self.SpellIcon.Slot:SetPoint("CENTER")
	self.SpellIcon.Slot:SetSize(56, 56)

    self.SpellIcon.SlotAdd = self.SpellIcon:CreateTexture(nil, "BORDER")
	self.SpellIcon.SlotAdd:SetTexture("Interface\\BUTTONS\\UI-EmptySlot-White")
	self.SpellIcon.SlotAdd:SetPoint("CENTER")
	self.SpellIcon.SlotAdd:SetSize(56, 56)
	self.SpellIcon.SlotAdd:SetBlendMode("ADD")

    self.SpellIcon.Icon = self.SpellIcon:CreateTexture(nil, "ARTWORK")
	self.SpellIcon.Icon:SetAllPoints(true)

	--self.SpellIcon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

	self.SpellIcon.RankFrame = CreateFrame("FRAME", "$parent.RankFrame", self.SpellIcon)
	self.SpellIcon.RankFrame:SetPoint("CENTER", self.SpellIcon, "BOTTOMRIGHT", -5, 6)
	self.SpellIcon.RankFrame:SetSize(58, 36)
	self.SpellIcon.RankFrame:Hide()

	self.SpellIcon.RankFrame.RankBorder = self.SpellIcon.RankFrame:CreateTexture(nil, "ARTWORK")
    self.SpellIcon.RankFrame.RankBorder:SetTexture("Interface\\TalentFrame\\TalentFrame-RankBorder")
    self.SpellIcon.RankFrame.RankBorder:SetPoint("TOPLEFT")
    self.SpellIcon.RankFrame.RankBorder:SetPoint("BOTTOMRIGHT")

    self.SpellIcon.RankFrame.Rank = self.SpellIcon.RankFrame:CreateFontString(nil, "OVERLAY")
    self.SpellIcon.RankFrame.Rank:SetFontObject(GameFontNormalSmall)
    self.SpellIcon.RankFrame.Rank:SetPoint("CENTER", self.SpellIcon.RankFrame.RankBorder, 0, 1)
 	self.SpellIcon.RankFrame.Rank:SetText("3/5")

 	MixinAndLoadScripts(self.SpellIcon.RankFrame, AnimatedRankMixin)

    self.SpellName = self:CreateFontString("$parent.SpellName", "ARTWORK")
    self.SpellName:SetFontObject(GameFontNormal)
    self.SpellName:SetPoint("LEFT", self.SpellIcon, "RIGHT", 8, 0)
    self.SpellName:SetJustifyH("LEFT")
    self.SpellName:SetWidth(115)

    --[[
    self.SpellNameFrame = CreateFrame("FRAME", "$parent.SpellNameFrame", self, nil)
    self.SpellNameFrame:SetPoint("LEFT", self.SpellIcon, "RIGHT", 8, 0)
    self.SpellNameFrame:SetBackdrop(GameTooltip:GetBackdrop())
    self.SpellNameFrame:SetSize(115, 24)

	self:GetNormalTexture():ClearAllPoints()
	self:GetNormalTexture():SetPoint("LEFT", self.SpellIcon, "RIGHT", 4, 0)
	self:GetNormalTexture():SetPoint("RIGHT", 0, 0)
	self:GetNormalTexture():SetHeight(self:GetHeight())

	self:GetHighlightTexture():ClearAllPoints()
	self:GetHighlightTexture():SetPoint("LEFT", self.SpellIcon, "RIGHT", 4, 0)
	self:GetHighlightTexture():SetPoint("RIGHT", 0, 0)
	self:GetHighlightTexture():SetHeight(self:GetHeight())]]--
end


ReputationPanelMixin = {}

function ReputationPanelMixin:OnLoad()
	self.ScrollList:SetTemplate("ReputationPanelItemTemplate")
	self.ScrollList:SetGetNumResultsFunction(GetNumFactions)
	self.ScrollList:GetSelectedHighlight():SetTexture()
end

function ReputationPanelMixin:OnShow()
	SetSelectedFaction(0)
	self.ScrollList:RefreshScrollFrame()
	self:RegisterEvent("UPDATE_FACTION")
end

function ReputationPanelMixin:OnHide()
	self:UnregisterEvent("UPDATE_FACTION")
	self.DetailsFrame:Hide()
end

function ReputationPanelMixin:OnEvent()
	self.ScrollList:RefreshScrollFrame()
	self:UpdateReputationDetails()
end

function ReputationPanelMixin:ToggleAtWar(factionIndex)
	FactionToggleAtWar(factionIndex)
	self.ScrollList:RefreshScrollFrame()
end

function ReputationPanelMixin:SetWatchedFaction(factionIndex)
	SetWatchedFactionIndex(factionIndex)
	self.ScrollList:RefreshScrollFrame()
end

function ReputationPanelMixin:UpdateReputationDetails()
	local selectedFaction = GetSelectedFaction()
	if not selectedFaction or selectedFaction == 0 then
		self.DetailsFrame:Hide()
		return
	end

	local name, description, _, _, _, _, atWarWith, canToggleAtWar, isHeader, _, _, isWatched = GetFactionInfo(selectedFaction)

	if isHeader then
		SetSelectedFaction(0)
		self.DetailsFrame:Hide()
		return
	end

	self.DetailsFrame.Name:SetText(name)
	self.DetailsFrame.Description:SetText(description)

	self.DetailsFrame.AtWarToggle:SetChecked(atWarWith)
	self.DetailsFrame.AtWarToggle:SetEnabled(canToggleAtWar)

	self.DetailsFrame.InactiveToggle:SetChecked(IsFactionInactive(selectedFaction))
	
	self.DetailsFrame.WatchToggle:SetChecked(isWatched)

	self.DetailsFrame:Show()
end

-- 
-- Reputation Bar
--
ReputationBarMixin = CreateFromMixins(ScrollListItemBaseMixin)

local FACTION_BADGE_CACHE = {}

ReputationBarMixin.RowType = {
	Normal = 0,
	Child = 1,
	Header = 2,
	ChildHeader = 3,
}

function ReputationBarMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.Background:SetPoint("TOPRIGHT", self.ReputationBar.LeftTexture, "TOPLEFT", 0, 0)

	self.ReputationBar.Highlight1:SetPoint("TOPLEFT", self.Background, "TOPLEFT", -2, 4)
	self.ReputationBar.Highlight1:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -10, -4)
	self.ReputationBar.AtWarHighlight1:SetPoint("TOPLEFT", self.Background, "TOPLEFT", 3, -2)
	self.ReputationBar.AtWarHighlight2:SetPoint("TOPRIGHT", self, "TOPRIGHT", -1, -2)
	self.ReputationBar.AtWarHighlight1:SetAlpha(0.2)
	self.ReputationBar.AtWarHighlight2:SetAlpha(0.2)
end

local parentFactionBadge
function ReputationBarMixin:Update()
	local name, _, standingID, barMin, barMax, barValue, atWarWith, _, isHeader, isCollapsed, hasRep, _, isChild = GetFactionInfo(self.index)
	self.isCollapsed = isCollapsed
	if isCollapsed then
		self.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
	else
		self.ExpandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
	end
	self.FactionName:SetText(name)

	--Normalize Values
	barMax = barMax - barMin
	barValue = barValue - barMin
	barMin = 0
	self.ReputationBar:SetMinMaxValues(0, barMax)
	self.ReputationBar:SetValue(barValue)
	local color = FACTION_BAR_COLORS[standingID]
	self.ReputationBar:SetStatusBarColor(color.r, color.g, color.b)
	
	local gender = UnitSex("player")
	self.standingText = GetText("FACTION_STANDING_LABEL"..standingID, gender)
	self.tooltip = HIGHLIGHT_FONT_COLOR:WrapText(" "..barValue.." / "..barMax)

	self:SetRowType((isChild and 1 or 0) + (isHeader and 2 or 0), hasRep)

	if atWarWith then
		self.ReputationBar.AtWarHighlight1:Show()
		self.ReputationBar.AtWarHighlight2:Show()
	else
		self.ReputationBar.AtWarHighlight1:Hide()
		self.ReputationBar.AtWarHighlight2:Hide()
	end
	
	local selectedFaction = GetSelectedFaction()
	local isSelected = selectedFaction == self.index
	local isMouseOver = self:IsMouseOver()
	self.ReputationBar.Highlight1:SetShown((isSelected or isMouseOver) and not isHeader)
	self.ReputationBar.Highlight2:SetShown((isSelected or isMouseOver) and not isHeader)
	self.ReputationBar.FactionStanding:SetText(isSelected and self.tooltip or self.standingText)

	if isHeader and not isChild then
		if name == EXPANSION_NAME0 then
			parentFactionBadge = "small-logo-expansion-0"
		elseif name == EXPANSION_NAME1 then
			parentFactionBadge = "small-logo-expansion-1"
		elseif name == EXPANSION_NAME2 then
			parentFactionBadge = "small-logo-expansion-2"
		else
			parentFactionBadge = nil
		end
	end

	if FACTION_BADGE_CACHE[name] then
		parentFactionBadge = FACTION_BADGE_CACHE[name]
	end

	if parentFactionBadge then
		FACTION_BADGE_CACHE[name] = parentFactionBadge
		self.FactionBadge:SetAtlas(parentFactionBadge, Const.TextureKit.UseAtlasSize)
		self.FactionBadge:SetWidth(self.FactionBadge:GetWidth()*0.6)
		self.FactionBadge:SetHeight(self.FactionBadge:GetHeight()*0.6)
		self.FactionBadge:SetPoint("LEFT", self.FactionName, "LEFT", self.FactionName:GetStringWidth() + 4, 0)
		self.FactionBadge:Show()
	else
		self.FactionBadge:Hide()
	end
end

function ReputationBarMixin:SetRowType(rowType, hasReputation)
	self.ReputationBar.LeftTexture:SetWidth(62)
	self.ReputationBar.RightTexture:SetWidth(42)
	self.ReputationBar:SetPoint("RIGHT", self, "RIGHT", 0, 0)

	if rowType == ReputationBarMixin.RowType.Normal then
		self.ReputationBar.LeftTexture:SetHeight(21)
		self.ReputationBar.RightTexture:SetHeight(21)
		self.ReputationBar.LeftTexture:SetTexCoord(0.7578125, 1.0, 0.0, 0.328125)
		self.ReputationBar.RightTexture:SetTexCoord(0.0, 0.1640625, 0.34375, 0.671875)
		self.ReputationBar:SetWidth(101)

		self.ExpandOrCollapseButton:Hide()
		self.Background:Show()
		self.Background:SetPoint("LEFT", 14, 0)

		self.FactionName:SetPoint("LEFT", 24, 0)
		self.FactionName:SetFontObject("GameFontHighlightSmall")
		self.FactionName:SetWidth(160)

	elseif rowType == ReputationBarMixin.RowType.Child then
		self.ReputationBar.LeftTexture:SetHeight(21)
		self.ReputationBar.RightTexture:SetHeight(21)
		self.ReputationBar.LeftTexture:SetTexCoord(0.7578125, 1.0, 0.0, 0.328125)
		self.ReputationBar.RightTexture:SetTexCoord(0.0, 0.1640625, 0.34375, 0.671875)
		self.ReputationBar:SetWidth(101)

		self.ExpandOrCollapseButton:Hide()
		self.Background:SetPoint("LEFT", 44, 0)
		self.Background:Show()
		
		self.FactionName:SetPoint("LEFT", 54, 0)
		self.FactionName:SetFontObject("GameFontHighlightSmall")
		self.FactionName:SetWidth(150)

	elseif rowType == ReputationBarMixin.RowType.Header then
		self.ExpandOrCollapseButton:SetPoint("LEFT", self, "LEFT", 3, 0)
		self.ExpandOrCollapseButton:Show()

		self.ReputationBar.LeftTexture:SetHeight(15)
		self.ReputationBar.LeftTexture:SetWidth(60)
		self.ReputationBar.RightTexture:SetHeight(15)
		self.ReputationBar.RightTexture:SetWidth(39)
		self.ReputationBar.LeftTexture:SetTexCoord(0.765625, 1.0, 0.046875, 0.28125)
		self.ReputationBar.RightTexture:SetTexCoord(0.0, 0.15234375, 0.390625, 0.625)
		self.ReputationBar:SetWidth(99)
		
		self.FactionName:SetPoint("LEFT", self.ExpandOrCollapseButton, "RIGHT", 10, 0)
		self.FactionName:SetFontObject("GameFontNormalLeft")
		self.FactionName:SetWidth(145)

		self.Background:Hide()

	elseif rowType == ReputationBarMixin.RowType.ChildHeader then --Header and child
		self.ExpandOrCollapseButton:SetPoint("LEFT", self, "LEFT", 23, 0)
		self.ExpandOrCollapseButton:Show()

		self.ReputationBar.LeftTexture:SetHeight(15)
		self.ReputationBar.LeftTexture:SetWidth(60)
		self.ReputationBar.RightTexture:SetHeight(15)
		self.ReputationBar.RightTexture:SetWidth(39)
		self.ReputationBar.LeftTexture:SetTexCoord(0.765625, 1.0, 0.046875, 0.28125)
		self.ReputationBar.RightTexture:SetTexCoord(0.0, 0.15234375, 0.390625, 0.625)
		self.ReputationBar:SetWidth(99)

		self.FactionName:SetPoint("LEFT" ,self.ExpandOrCollapseButton, "RIGHT", 10, 0)
		self.FactionName:SetFontObject("GameFontNormalLeft")
		self.FactionName:SetWidth(135)

		self.Background:Hide()
	end

	if hasReputation or rowType == ReputationBarMixin.RowType.Normal or rowType == ReputationBarMixin.RowType.Child then
		self.ReputationBar.FactionStanding:Show()
		self.ReputationBar:Show()
		self.hasRep = true
	else
		self.ReputationBar.FactionStanding:Hide()
		self.ReputationBar:Hide()
		self.hasRep = false
	end
end

function ReputationBarMixin:OnSelected()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
	if (ReputationDetailFrame:IsShown() and GetSelectedFaction() == self.index) or not self.hasRep then
		SetSelectedFaction(0)
		self:GetScrollList():RefreshScrollFrame()
	elseif self.hasRep then
		SetSelectedFaction(self.index)
		self:GetScrollList():RefreshScrollFrame()
	end
	self:GetScrollList():GetParent():UpdateReputationDetails()
end

function ReputationBarMixin:OnEnter()
	self.ReputationBar.Highlight1:Show()
	self.ReputationBar.Highlight2:Show()
	self.ReputationBar.FactionStanding:SetText(self.tooltip)
end

function ReputationBarMixin:OnLeave()
	if GetSelectedFaction() ~= self.index then
		self.ReputationBar.Highlight1:Hide()
		self.ReputationBar.Highlight2:Hide()
		self.ReputationBar.FactionStanding:SetText(self.standingText)
	end
end 
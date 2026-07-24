SkillsPanelMixin = {}

function SkillsPanelMixin:OnLoad()
	self.ScrollList:SetTemplate("SkillsPanelItemTemplate")
	self.ScrollList:SetGetNumResultsFunction(GetNumSkillLines)
	self.ScrollList:GetSelectedHighlight():SetTexture()
end

function SkillsPanelMixin:OnShow()
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self.ScrollList:RefreshScrollFrame()
end

function SkillsPanelMixin:OnHide()
	self:UnregisterEvent("SKILL_LINES_CHANGED")
	self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
end

function SkillsPanelMixin:OnEvent()
	self:UpdateDetailsFrame() -- will refresh scroll
end

function SkillsPanelMixin:UpdateDetailsFrame()
	local skillID = GetSelectedSkill()
	if skillID and skillID ~= 0 then
		self.DetailsFrame:Show()
		local skillName, _, _, _, _, _, _, isAbandonable, _, _, _, _, skillDescription = GetSkillLineInfo(skillID)
		self.DetailsFrame.Title:SetText(skillName)
		self.DetailsFrame.Description:SetText(skillDescription)
		self.DetailsFrame.AbandonButton:SetEnabled(isAbandonable)
	else
		self.DetailsFrame:Hide()
	end
	
	self.ScrollList:RefreshScrollFrame() -- selecting doesn't actually update the list, so highlights can be 'sticky'
end

SkillsPanelItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function SkillsPanelItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.CategoryBackground:SetAtlas("Char-Stat-Top", Const.TextureKit.IgnoreAtlasSize)
end

function SkillsPanelItemMixin:Update()
	local skillName, isHeader, isExpanded, skillRank, _, skillModifier, skillMaxRank = GetSkillLineInfo(self.index)

	self.isHeader = isHeader
	self.isExpanded = isExpanded
	
	self.CategoryName:SetShown(isHeader)
	self.CategoryBackground:SetShown(isHeader)
	self.ExpandIcon:SetShown(isHeader)
	self.StatusBar:SetShown(not isHeader)

	if isHeader then
		self.CategoryName:SetText(skillName)
		if isExpanded then
			self.ExpandIcon:SetAtlas("Char-Stat-Minus", Const.TextureKit.IgnoreAtlasSize)
		else
			self.ExpandIcon:SetAtlas("Char-Stat-Plus", Const.TextureKit.IgnoreAtlasSize)
		end
	else
		self.StatusBar:SetMinMaxValues(0, skillMaxRank)
		self.StatusBar:SetValue(MClamp(skillRank + skillModifier, 0, skillMaxRank))
		self.StatusBar.SkillName:SetText(skillName)
		if skillRank == 1 and skillMaxRank == 1 then
			self.StatusBar.Skill:SetText("")
			self.StatusBar:SetStatusBarColor(0.1, 0.75, 0.1)
		else
			if skillModifier > 0 then
				self.StatusBar.Skill:SetFormattedText("%d(|cff00ff00+%d|r)/%d", skillRank, skillModifier, skillMaxRank)
			elseif skillModifier < 0 then
				self.StatusBar.Skill:SetFormattedText("%d(|cffff0000-%d|r)/%d", skillRank, skillModifier, skillMaxRank)
			else
				self.StatusBar.Skill:SetFormattedText("%d/%d", skillRank, skillMaxRank)
			end
			self.StatusBar:SetStatusBarColor(0.1, 0.1, 0.75)
		end
	end

	if self:IsMouseOver() and not self.isHeader then
		self.StatusBar.Highlight:Show()
	elseif GetSelectedSkill() == self.index then
		self.StatusBar.Highlight:Show()
	else
		self.StatusBar.Highlight:Hide()
	end
end 

function SkillsPanelItemMixin:OnSelected()
	if self.isHeader then
		PlaySound(SOUNDKIT.MINI_MAP_ZOOM_70)
		if self.isExpanded then
			CollapseSkillHeader(self.index)
		else
			ExpandSkillHeader(self.index)
		end
	else
		PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
		if GetSelectedSkill() == self.index then
			SetSelectedSkill(0)
		else
			SetSelectedSkill(self.index)
		end
		
		self:GetScrollList():GetParent():UpdateDetailsFrame()
	end
end

function SkillsPanelItemMixin:OnEnter()
	if not self.isHeader then
		self.StatusBar.Highlight:Show()
	end
end

function SkillsPanelItemMixin:OnLeave()
	if not self.isHeader and GetSelectedSkill() ~= self.index then
		self.StatusBar.Highlight:Hide()
	end
end
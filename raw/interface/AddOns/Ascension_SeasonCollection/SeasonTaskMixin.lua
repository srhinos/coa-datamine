SeasonTaskMixin = CreateFromMixins(ScrollListItemBaseMixin)

local IncompleteFormat = "%s\n%s"
local CompleteFormat = "%s\nCompleted: %d/%d/%d"

function SeasonTaskMixin:OnLoad()
	self:SetNormalAtlas("season-collection-task-background")
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:SetHighlightAtlas("season-collection-task-highlight")
	self:GetHighlightTexture():SetAlpha(0.5)
	self.RewardBackground:SetAtlas("GarrMission_RewardsBox_Shadow", Const.TextureKit.IgnoreAtlasSize)
	self.IconBorder:SetAtlas("collections-itemborder-collected", Const.TextureKit.IgnoreAtlasSize)
	self.CompleteCheck:SetAtlas("services-checkmark", Const.TextureKit.IgnoreAtlasSize)
end

function SeasonTaskMixin:Update()
	local task = self.parent:GetCurrentTasks()[self.index]
	if task then
		self.achievement = task.id
		local _, name, _, isComplete, month, day, year, description, _, icon, rewardText = GetAchievementInfo(task.id)

		-- Icon
		self.CompleteCheck:SetShown(isComplete)
		self.IconBorder:SetDesaturated(not isComplete)
		self.Icon:SetTexture(icon)

		-- name
		if isComplete then
			self:SetFormattedText(GREEN_FONT_COLOR:WrapText(CompleteFormat), name, month, day, year)
			self.Icon:SetVertexColor(0.4, 0.4, 0.4)
		else
			self:SetFormattedText(IncompleteFormat, NORMAL_FONT_COLOR:WrapText(name or task.id), DISABLED_FONT_COLOR:WrapText(description or ""))
			self.Icon:SetVertexColor(1, 1, 1)
		end

		-- Reward
		if rewardText and rewardText:len() > 0 then
			self.RewardBackground:Show()
			self.RewardText:SetText(rewardText)
		else
			self.RewardBackground:Hide()
			self.RewardText:SetText("")
		end
	else
		self.achievement = nil
	end
end

function SeasonTaskMixin:OnSelected()
	-- Called when this button is left clicked and highlighted by the scroll list
end

function SeasonTaskMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self.parent = args[1]
end

function SeasonTaskMixin:OnRightClick()
end

function SeasonTaskMixin:OnEnter()
	if not self.achievement then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("achievement:"..self.achievement)
	GameTooltip:Show()
end

function SeasonTaskMixin:OnLeave()
	GameTooltip:Hide()
end
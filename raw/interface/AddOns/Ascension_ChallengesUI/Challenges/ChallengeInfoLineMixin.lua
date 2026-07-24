ChallengeInfoLineMixin = CreateFromMixins(ScrollListItemBaseMixin)

function ChallengeInfoLineMixin:OnLoad()
	self:SetNormalAtlas("Rewards-Shadow")
	self:SetHighlightAtlas("professions_recipe_hover")
end

function ChallengeInfoLineMixin:Update()
	self:GetScrollList():GetParent():SetScrollItem(self.index, self)
end

function ChallengeInfoLineMixin:OnEnter()
	GameTooltip_GenericTooltip(self, "ANCHOR_TOP")
end

function ChallengeInfoLineMixin:OnLeave()
	GameTooltip:Hide()
end


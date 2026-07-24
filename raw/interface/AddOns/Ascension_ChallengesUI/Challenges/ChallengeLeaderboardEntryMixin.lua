ChallengeLeaderboardEntryMixin = CreateFromMixins(ScrollListItemBaseMixin)

function ChallengeLeaderboardEntryMixin:OnLoad()
	self.Background:SetAtlas("Rewards-Shadow", Const.TextureKit.IgnoreAtlasSize)
	self.Background2:SetAtlas("Rewards-Top", Const.TextureKit.IgnoreAtlasSize)
	self.IconBorder:SetAtlas("pvpqueue-rewardring-large", Const.TextureKit.IgnoreAtlasSize)
	self.Glow:SetAtlas("services-ring-large-glowspin", Const.TextureKit.IgnoreAtlasSize)
	self.Highlight:SetAtlas("professions_recipe_hover", Const.TextureKit.IgnoreAtlasSize)
end 

function ChallengeLeaderboardEntryMixin:Update()
	self:GetScrollList():GetParent():SetScrollItem(self.index, self)
end

function ChallengeLeaderboardEntryMixin:OnSelected()
	
end 

function ChallengeLeaderboardEntryMixin:OnEnter()
	GameTooltip_GenericTooltip(self, "ANCHOR_TOP")
end 

function ChallengeLeaderboardEntryMixin:OnLeave()
	GameTooltip:Hide()
end 
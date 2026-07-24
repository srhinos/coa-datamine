SeasonCollectionMixin = {}

function SeasonCollectionMixin:OnLoad()
	self.BackgroundRight:SetAtlas("season-collection-background", Const.TextureKit.UseAtlasSize)
	self.TitleText:SetText(SEASON_9_TITLE)
	self.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\inv_treasurechest_felfirecitadel")
	
	self.LeftGlow:SetAtlas("season-collection-glow-edge", Const.TextureKit.IgnoreAtlasSize)
	self.LeftGlow:FlipX()
	self.BottomRightGlow:SetAtlas("season-collection-glow-corner", Const.TextureKit.UseAtlasSize)

	self.CloseButton:SetScript("OnClick", function()
		HideUIPanel(Collections)
	end)

	self.SeasonInfo = GetSeasonalCollectionInfo()

	if not self.SeasonInfo then
		dprint("GetSeasonalCollectionInfo() returnd nil!")
		return
	end

	self.SeasonInfo.names[2] = SEASONAL_POINTS_AVAILABLE:format(GetItemCount(ItemData.SEASONAL_POINTS))

	self.UnlockInfo:SetInfo("", "", SEASON_COLLECTION_UNLOCK_DESC) -- filled by SetItem
	self.UnlockInfo:SetItem(ItemData.SEASONAL_PASS)
	self.DraftInfo:SetInfo(self.SeasonInfo.icons[1], self.SeasonInfo.names[1], self.SeasonInfo.descriptions[1])
	self.PointsInfo:SetInfo(self.SeasonInfo.icons[2], self.SeasonInfo.names[2], self.SeasonInfo.descriptions[2])
end

function SeasonCollectionMixin:OnShow()
end

function SeasonCollectionMixin:SelectTier(tierID)
	self.selectedTier = tierID
end 
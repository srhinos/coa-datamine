BuildListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function BuildListItemMixin:OnLoad()
	self:SetNormalAtlas("buildcreator-preview")
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:SetHighlightAtlas("buildcreator-preview-h")
	self.Border:SetAtlas("buildcreator-preview-h", Const.TextureKit.IgnoreAtlasSize)
	self.SpecIcon.Icon:SetRounded(true)
	self.SpecIcon.Icon:SetBorderSize(48, 48)
	self.Role:SetBackgroundTexture("Interface\\LFGFrame\\UI-LFG-ICONS-ROLEBACKGROUNDS")
	self.Role:SetBackgroundSize(82, 82)
	self.Role:SetBackgroundAlpha(0.6)
	self.Icon:SetRounded(true)
	self.Icon:SetBorderSize(68, 68)
	self.Icon:SetBorderOffset(0, -1)
	self.Icon:SetBorderAtlas("build-draft-border")

	self.Icon.TrophyEligible:SetBorderAtlas("build-draft-border")
	self.Icon.TrophyEligible:SetHighlightAtlas("build-draft-stat-highlight")
	self.Icon.TrophyEligible:SetRounded(true)
	self.Icon.TrophyEligible:SetBorderSize(28, 28)
	self.Icon.TrophyEligible:SetBorderOffset(0, 0)
	self.Icon.TrophyEligible:SetIcon("Interface\\Icons\\inv_misc_build_masters_trophy")
	self.Icon.TrophyEligible.tooltipTitle = BUILD_DRAFT_TROPHY_ELIGIBLE
	self.Icon.TrophyEligible.tooltipText = BUILD_DRAFT_TROPHY_ELIGIBLE_TOOLTIP
	
	self:RegisterEvent("BUILD_CREATOR_RATE_RESULT")
	
	hooksecurefunc(C_BuildCreator, "RateBuild", function()
		if self:IsVisible() then
			self.LikeButton:Disable()
		end
	end)
end

function BuildListItemMixin:Update()
	if BuildCreatorFrame.category == Enum.BuildCategory.History then
		local id = C_BuildCreator.GetBookmarkedBuildAtIndex(self.index)
		self.data = C_BuildCreator.GetBuild(id)
	else
		self.data = C_BuildCreator.GetBuildAtIndex(self.index)
	end
	self.Name:SetText(self.data.Name)
	local authorName = HIGHLIGHT_FONT_COLOR:WrapText(self.data.AuthorName)
	local howLongAgo = SecondsToTime(time() - self.data.UpdatedTime, false, true, 1)
	
	if self.data.Category == Enum.BuildCategory.Featured or self.data.AuthorName == "Ascension" then
		self.Author:SetFormattedText(BUILD_AUTHOR_S, authorName)
	else
		self.Author:SetFormattedText(BUILD_AUTHOR_S_S_AGO, authorName, "|cffffffff"..howLongAgo) -- intentional no |r so `ago` is white
	end
	self.Icon:SetIcon("Interface\\Icons\\"..self.data.Icon)
	if self:IsSelected() then
		self:LockHighlight()
	else
		self:UnlockHighlight()
	end

	-- when we add builds for different classes, we can check here
	self:UpdateEnchant()

	if self.data.NeedsRepairs then
		self.SubText:Show()
		self.SubText:SetFontObject("GameFontHighlight")
		self.SubText:SetText(BUILD_UNPUBLISHED_NEEDS_FIXES)
		self.SubText:SetTextColor(RED_FONT_COLOR:GetRGB())
	else
		self.SubText:Hide()
	end

	self:UpdateRating()
	-- role
	local role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(self.data.Roles)
	self.Role:SetIconAtlas(ROLE_ATLAS[role])
	self.Role.Background:SetTexCoord(GetBackgroundTexCoordsForRole(role))
	self.Role.tooltipTitle = BUILD_CREATOR_ROLE_S:format(_G[role])
	self.Role.tooltipText = _G["BUILD_CREATOR_ROLE_"..role]
	if GameTooltip:IsOwned(self.Role) then
		self.Role:CallScript("OnEnter")
	end
	
	-- stat
	local statID = Enum.PrimaryStat[self.data.PrimaryStat]
	if statID then
		self.PrimaryStat:Show()
		local statSpellID = C_PrimaryStat:GetPrimaryStatInfo(statID)
		self.PrimaryStat.Icon:SetSpell()
		self.PrimaryStat.Icon:SetIconAtlas(PRIMARY_STAT_ATLAS[statID])
		self.PrimaryStat:SetText(GetSpellInfo(statSpellID))
	else
		self.PrimaryStat:Hide()
	end
	
	-- difficulty
	local difficulty = self.data.DifficultyRating
	self.DifficultyIcon:SetAtlas(BuildCreatorUtil.DifficultyAtlas[difficulty])
	self.DifficultyText:SetText(_G[difficulty])
	self.DifficultyText:SetTextColor(BuildCreatorUtil.DifficultyColors[difficulty]:GetRGB())
	
	-- build draft completion
	if BuildCreatorUtil.IsCategoryBuildDraft(self.data.Category) then
		local completedBuild = C_BuildDraft.IsCompletedBuild(self.data.ID)
		self.Icon.CompletedBuild:SetShown(completedBuild)
		self.Icon.TrophyEligible:SetShown(not completedBuild)
	else
		self.Icon.CompletedBuild:Hide()
		self.Icon.TrophyEligible:Hide()
	end
	
	self:UpdateChooseButton()
end 

function BuildListItemMixin:UpdateRating()
	-- rating
	local rating = self.data.Upvotes or 0
	local ratingQuality = BuildCreatorUtil.GetRatingQuality(rating)
	local ratingColor = ITEM_QUALITY_COLORS[ratingQuality]
	rating = ITEM_QUALITY_COLORS[Enum.ItemQuality.Uncommon]:WrapText(rating)
	self.RatingText:SetFormattedText(BUILD_RATING_S, rating)
	self.LikeButton:SetChecked(C_BuildCreator.IsUpvotedBuild(self.data.ID))
	if self.LikeButton:GetBoolValue() then
		self.LikeButton:LockHighlight()
	else
		self.LikeButton:UnlockHighlight()
	end

	-- border
	if self.data.Category == Enum.BuildCategory.BuildDraft then
		self.Border:Hide()
	elseif self.data.NeedsRepairs then
		self.Border:Show()
		self.Border:SetVertexColor(RED_FONT_COLOR:GetRGB())
	else
		self.Border:SetShown(ratingQuality > Enum.ItemQuality.Common)
		self.Border:SetVertexColor(ratingColor:GetRGB())
	end
end

function BuildListItemMixin:UpdateEnchant()
	-- enchant
	local enchant = self.data.LegendaryEnchant
	if not enchant or enchant <= 0 then
		self.SpecIcon:Hide()
	else
		self.SpecIcon:Show()
		self.SpecIcon.Icon:SetSpell(enchant)
		self.SpecIcon.Icon:SetBorderAtlas("EnchantSlotBorderKnownLegendary")
		self.SpecIcon:SetText(GetSpellInfo(enchant))
		self.SpecIcon.Text:SetTextColor(ITEM_QUALITY_COLORS[Enum.ItemQuality.Legendary]:GetRGB())
	end
end

function BuildListItemMixin:OnSelected()
	if IsModifiedClick("CHATLINK") then
		local link = BuildCreatorUtil.GetBuildLink(self.data)
		if link then
			if ChatEdit_InsertLink(link) then
				return true
			end
		end
	end

    if C_Player:IsGM() and IsAltKeyDown() then
        SendChatMessage(format(".buildcreator check %s %s", UnitName("player"), self.data.ID))
        return true
    end

	self:LockHighlight()
	self:GetScrollList():GetParent():ViewBuild(self.data)
end

function BuildListItemMixin:UpdateChooseButton()
	if BuildCreatorUtil.IsActiveBuildID(self.data.ID) then
		self.ChooseButton:SetText(DEACTIVATE_BUILD)
		self.ChooseButton:Enable()
		self.ChooseButton.tooltipTitle = nil
		self.ChooseButton.tooltipText = nil
	else
		if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
			self.ChooseButton:SetText(RAPID_ROLL_THIS_BUILD)
			local canActivate = C_Wildcard.CanUseRapidRolling()
			self.ChooseButton:SetEnabled(canActivate)
			self.ChooseButton.tooltipTitle = nil
			self.ChooseButton.tooltipText = nil
			
			return
		end
		self.ChooseButton:SetText(CHOOSE_THIS_BUILD)
		local canActivate, reasons = C_BuildCreator.CanActivateBuild(self.data.ID)
		self.ChooseButton:SetEnabled(canActivate)
		if not canActivate then
			self.ChooseButton.tooltipTitle = ACTIVATE_BUILD_FAILED
			if reasons then
				for i, reason in ipairs(reasons) do
					reasons[i] = _G[reason] or reason
				end
				self.ChooseButton.tooltipText = RED_FONT_COLOR:WrapText(table.concat(reasons, "\n"))
			end
		else
			self.ChooseButton.tooltipTitle = nil
			self.ChooseButton.tooltipText = nil
		end
	end
end

function BuildListItemMixin:ChooseBuild()
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		C_BuildCreator.BookmarkBuild(self.data.ID)
		Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
		WildCardRapidRollingFrame:Show()
		WildCardRapidRollingFrame:ShowImportHint()
		return
	end
	BuildCreatorUtil.ToggleBuildActive(self.data.ID, self.data.Category, true)
end

function BuildListItemMixin:LikeBuild()
	if C_BuildCreator.IsUpvotedBuild(self.data.ID) then
		PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
		C_BuildCreator.RateBuild(self.data.ID, false)
	else
		C_BuildCreator.RateBuild(self.data.ID, true)
		PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
	end
end

function BuildListItemMixin:BUILD_CREATOR_RATE_RESULT(result, buildID, rating)
	self.LikeButton:Enable()
	if self.data and self.data.ID == buildID then
		self.data.Upvotes = rating
		self:UpdateRating()
	end
end 
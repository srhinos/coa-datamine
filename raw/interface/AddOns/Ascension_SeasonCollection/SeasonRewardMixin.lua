SeasonRewardMixin = CreateFromMixins(ModelMixin)

function SeasonRewardMixin:OnLoad()
	self:SetFacing(-0.65)
	ModelMixin.OnLoad(self)
	self:SetMinMaxDistance(-0.5, 1)
	self:SetEnableDragRotation(true)
	self:SetEnableScrollZoom(true)
	
	self.page = 1

	self.Background1.Anim:Play()
	self.Background2.Anim:Play()
end

function SeasonRewardMixin:OnShow()
	local season = C_AppearanceCollection.GetAvailableSeasons()
	season = season and season[1] or 0
	local chapter = C_AppearanceCollection.GetAvailableChapters(season)
	chapter = chapter and chapter[1] or 0

	local appearanceIDs = C_AppearanceCollection.GetSeasonalItems(season, chapter)
	if not appearanceIDs or #appearanceIDs == 0 then
		C_Logger.Error("SeasonRewardMixin:OnLoad() - No appearanceIDs found for season %d, chapter %d", season, chapter)
	end

	self.rewards = appearanceIDs or {}
	
	self:RefreshCurrentDisplay()
end

function SeasonRewardMixin:RefreshCurrentDisplay()
	self:ShowReward(self.page or 1)
end

function SeasonRewardMixin:ShowReward(index)
	if not self.rewards[index] then return end

	if self.cancelToken then
		self.cancelToken()
		self.cancelToken = nil
	end
	
	self:ResetValues()
	self:ClearModel()
	self:SetCamera(2)

	self.page = index
	local appearanceID = self.rewards[index]

	self.displayType, self.displayID, self.uiCamera, self.displayName, self.entry, self.spellVisualID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)

	self.Title:SetText(self.displayName)
	
	if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
		self:DisplayItem()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_CREATURE" then
		self:DisplayCreature()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_ENCHANT" then
		self:DisplayIllusion()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_SPELL" then
		self:DisplaySpellIcon()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_STATIC_SPELL_VISUAL" then
		self:DisplayStaticSpell()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ANIMATED_SPELL_VISUAL" then
		self:DisplayAnimatedSpell()
	elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_SET" then
		self:DisplayItemSet()
	end
end

function SeasonRewardMixin:DisplayItem()
	local item = Item:CreateFromID(self.displayID)

	local invType = GetItemInventoryType(self.displayID)
	local slot = INVTYPE_INDEX_TO_SLOT[invType]

	if slot == INVSLOT_MAINHAND or slot == INVSLOT_RANGED then
		self:SetFacing(0.78)
	elseif slot == INVSLOT_OFFHAND then
		self:SetFacing(-1.07)
	elseif slot == INVSLOT_BACK then
		self:SetFacing(3.14)
	else
		self:SetFacing(-0.65)
	end

	self.cancelToken = item:CancelableContinueOnLoad(function(displayID)
		if self.displayID == displayID then
			if self.KeepDressed:GetBoolValue() and slot ~= INVSLOT_BODY and slot ~= INVSLOT_TABARD then
				-- tabard and shirts should undress anyway so it will show. Otherwise its cut off by robes / chest armor
				self:SetUnit("player")
			else
				SetModelApplyComponents(false)
				self:SetUnit("player")
				self:Undress()
				SetModelApplyComponents(true)
			end
			self:TryOn(displayID)
		end
	end)
end

function SeasonRewardMixin:DisplayCreature()
	self:SetDisplayInfo(self.displayID, function()
		local displayItems = C_Appearance.GetCreatureDisplayItems(self.appearanceID)
		if displayItems and #displayItems > 0 then
			local appearanceID = self.appearanceID
			for _, itemID in ipairs(displayItems) do
				local item = Item:CreateFromID(itemID)
				-- fixes bug where setting the creature and TryOn in the same frame causes the camera to not apply.
				RunNextFrame(function()
					self.cancelToken = item:CancelableContinueOnLoad(function(itemID)
						if self.appearanceID ~= appearanceID then
							return -- run next frame means we might have changed appearances
						end
						self:TryOn(itemID)
					end)
				end)
			end
		end
	end)
end

function SeasonRewardMixin:DisplayIllusion()
	local itemID = GetInventoryItemTrueID("player", INVSLOT_MAINHAND) or 25
	local item = Item:CreateFromID(itemID)
	self.cancelToken = item:CancelableContinueOnLoad(function()
		self:TryOn(format("item:%s:%s", itemID, self.displayID), INVSLOT_MAINHAND)
	end)
end

function SeasonRewardMixin:DisplaySpellIcon()
	C_Logger.Error("SeasonRewardMixin:DisplaySpellIcon() - Not implemented yet")
end

function SeasonRewardMixin:DisplayStaticSpell()
	if self.KeepDressed:GetBoolValue() then
		self:SetUnit("player")
	else
		SetModelApplyComponents(false)
		self:SetUnit("player")
		self:Undress()
		SetModelApplyComponents(true)
	end

	self:SetFacing(-0.65)
	self:SetSpellVisual(self.displayID, self.spellVisualID or 0)
end

function SeasonRewardMixin:DisplayAnimatedSpell()
	if self.KeepDressed:GetBoolValue() then
		self:SetUnit("player")
	else
		SetModelApplyComponents(false)
		self:SetUnit("player")
		self:Undress()
		SetModelApplyComponents(true)
	end

	self:SetSpell(self.displayID, self.spellVisualID or 0)
	self:UpdateBorder()
	self:SetFacing(-0.65)
end

function SeasonRewardMixin:DisplayItemSet()
	if self.KeepDressed:GetBoolValue() then
		self:SetUnit("player")
	else
		SetModelApplyComponents(false)
		self:SetUnit("player")
		self:Undress()
		SetModelApplyComponents(true)
	end

	self:SetFacing(-0.65)

	local appearanceIDs = C_ItemSet.GetAppearances(self.displayID)

	-- collect which items we need to query
	local displayIDs, needsQuery = {}, {}
	for slotID, appearanceID in pairs(appearanceIDs) do
		if appearanceID ~= 0 then
			local displayType, displayID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
			if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" and displayID then
				if not GetItemInfo(displayID) then
					table.insert(needsQuery, displayID)
				end
				displayIDs[slotID] = displayID
			end
		end
	end

	-- if we need to query, query first
	if #needsQuery > 0 then
		self.cancelToken = ItemQueryListener:AddCancelableCallback(needsQuery, function()
			for slotID, displayID in pairs(displayIDs) do
				self:TryOn(displayID, slotID)
			end
		end)
	else
		-- otherwise, just try on
		for slotID, displayID in pairs(displayIDs) do
			self:TryOn(displayID, slotID)
		end
	end
end

function SeasonRewardMixin:NextReward()
	if self.page >= #self.rewards then
		self:ShowReward(1)
	else
		self:ShowReward(self.page + 1)
	end
end 

function SeasonRewardMixin:PrevReward()
	if self.page <= 1 then
		self:ShowReward(#self.rewards)
	else
		self:ShowReward(self.page - 1)
	end
end 

function SeasonRewardMixin:OpenStore()
	PlaySound(SOUNDKIT.GUILD_VAULT_OPEN)
	OpenStoreCollectionToCategory(Enum.VanityCategory.Seasonal, self.displayName)
end
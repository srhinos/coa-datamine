local Addon = select(2, ...)
local CallBoardUI = Addon.CallBoardUI

function CallBoardUI:CreateWoodenTemplate(name, parent)
	local btn = CreateFrame("BUTTON", "$parent."..name, parent)
	btn:SetSize(552, 96)

	btn.bg_left = btn:CreateTexture(nil, "BACKGROUND")
	btn.bg_left:SetTexture("Interface\\callboard\\atlas_4")
	btn.bg_left:SetSize(106.65, 98)
	btn.bg_left:SetPoint("LEFT")
	btn.bg_left:SetTexCoord(0, 0.22614, 0, 0.21289)

	btn.bg_right = btn:CreateTexture(nil, "BACKGROUND") 
	btn.bg_right:SetTexture("Interface\\callboard\\atlas_4")
	btn.bg_right:SetSize(92.25, 98)
	btn.bg_right:SetPoint("RIGHT")
	btn.bg_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)

	btn.bg = btn:CreateTexture(nil, "BACKGROUND") 
	btn.bg:SetTexture("Interface\\callboard\\atlas_4")
	btn.bg:SetPoint("TOPLEFT", btn.bg_left, "TOPRIGHT", 0, 0)
	btn.bg:SetPoint("BOTTOMRIGHT", btn.bg_right, "BOTTOMLEFT", 1, 0)
	btn.bg:SetTexCoord(0, 0.5654, 0.425781, 0.638671)

	btn.highlightTexture_left = btn:CreateTexture(nil, "OVERLAY") 
	btn.highlightTexture_left:SetTexture("Interface\\callboard\\atlas_5")
	btn.highlightTexture_left:SetSize(106.65, 98)
	btn.highlightTexture_left:SetPoint("LEFT")
	btn.highlightTexture_left:SetTexCoord(0, 0.22614, 0, 0.21289)
	btn.highlightTexture_left:SetBlendMode("ADD")
	btn.highlightTexture_left:Hide()

	btn.highlightTexture_right = btn:CreateTexture(nil, "OVERLAY")
	btn.highlightTexture_right:SetTexture("Interface\\callboard\\atlas_5")
	btn.highlightTexture_right:SetSize(92.25, 98)
	btn.highlightTexture_right:SetPoint("RIGHT")
	btn.highlightTexture_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)
	btn.highlightTexture_right:SetBlendMode("ADD")
	btn.highlightTexture_right:Hide()

	btn.highlightTexture = btn:CreateTexture(nil, "OVERLAY")
	btn.highlightTexture:SetPoint("TOPLEFT", btn.highlightTexture_left, "TOPRIGHT", 0, 0)
	btn.highlightTexture:SetPoint("BOTTOMRIGHT", btn.highlightTexture_right, "BOTTOMLEFT", 1, 0)
	btn.highlightTexture:SetBlendMode("ADD")
	btn.highlightTexture:Hide()
	btn.highlightTexture:SetTexCoord(0, 0.5654, 0.425781, 0.638671)
	btn.highlightTexture:SetTexture("Interface\\callboard\\atlas_5")

	btn.pushed_left = btn:CreateTexture(nil, "BACKGROUND") 
	btn.pushed_left:SetTexture("Interface\\callboard\\atlas_9")
	btn.pushed_left:SetSize(106.2, 98)
	btn.pushed_left:SetPoint("LEFT")
	btn.pushed_left:SetTexCoord(0, 0.22614, 0, 0.21289)
	btn.pushed_left:Hide()

	btn.pushed_right = btn:CreateTexture(nil, "BACKGROUND") 
	btn.pushed_right:SetTexture("Interface\\callboard\\atlas_9")
	btn.pushed_right:SetSize(92.25, 98)
	btn.pushed_right:SetPoint("RIGHT")
	btn.pushed_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)
	btn.pushed_right:Hide()

	btn.pushedTexture = btn:CreateTexture(nil, "BACKGROUND") 
	btn.pushedTexture:SetPoint("TOPLEFT", btn.pushed_left, "TOPRIGHT", 0, 0)
	btn.pushedTexture:SetPoint("BOTTOMRIGHT", btn.pushed_right, "BOTTOMLEFT", 1, 0)
	btn.pushedTexture:SetTexture("Interface\\callboard\\atlas_9")
	btn.pushedTexture:SetTexCoord(0, 0.5654, 0.425781, 0.638671)
	btn.pushedTexture:Hide()

	btn:HookScript("OnEnter", function(self)
		self.highlightTexture:Show()
		self.highlightTexture_right:Show()
		self.highlightTexture_left:Show()
	end)

	btn:HookScript("OnLeave", function(self)
		self.highlightTexture:Hide()
		self.highlightTexture_right:Hide()
		self.highlightTexture_left:Hide()
	end)

	btn:HookScript("OnMouseDown", function(self)
		self.bg:Hide()
		self.bg_left:Hide()
		self.bg_right:Hide()
		self.pushedTexture:Show()
		self.pushed_right:Show()
		self.pushed_left:Show()
	end)

	btn:HookScript("OnMouseUp", function(self)
		self.bg:Show()
		self.bg_left:Show()
		self.bg_right:Show()
		self.pushedTexture:Hide()
		self.pushed_right:Hide()
		self.pushed_left:Hide()
	end)

	return btn
end

function CallBoardUI:CreateAreaTemplate(name, parent)
	local frame = CallBoardUI:CreateWoodenTemplate(name, parent)
	frame:SetWidth(572)

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetTexture("Interface\\Icons\\Achievement_Zone_AlteracMountains_01")
	frame.icon:SetSize(52, 52)
	frame.icon:SetPoint("LEFT", 24, 0)

	frame.iconBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.iconBorder:SetTexture("Interface\\callboard\\atlas_4")
	frame.iconBorder:SetSize(110, 110)
	frame.iconBorder:SetPoint("CENTER", frame.icon, 0, 0)
	frame.iconBorder:SetTexCoord(0.65917, 1, 0, 0.336914)

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 16, 0)
	frame.title:SetText("Area Name")
	frame.title:SetVertexColor(1, 0.82, 0, 1)

	function frame:SetName(name)
		self.title:SetText(name)

		if (self.isInstance) then
			self.tooltipTitle = ""
		else
			self.tooltipTitle = string.format(CallBoardUI.MSGS.OPEN_WORLDMAP, name)
		end
	end

	function frame:SetIcon(icon)
		return self.icon:SetTexture(icon)
	end

	function frame:SetArea(areaID)
		if not(areaID) then
			return
		end

		local fileName = C_WorldMap.GetMapFileByAreaID(areaID)
		self.worldMapID = areaID

		if (fileName) then
			if not(self:SetIcon("Interface\\Icons\\Achievement_Zone_"..fileName.."_01")) then
				if (CallBoardUI.areaIDIcons[areaID]) then
					self:SetIcon("Interface\\Icons\\"..CallBoardUI.areaIDIcons[areaID])
				end
			end

			if (self.worldMapID) then
				self:Enable()
			else
				self:Disable()
			end
		else
			return
		end
	end

	function frame:SetInstance(gossipOption, instanceID, areaName)
		self.isInstance = true
		self:SetArea(GetAreaIdByName(areaName))

		self.gossipOption = "INSTANCE_"..gossipOption
		self:SetName("Teleport to "..areaName.." instance "..instanceID)
	end

	function frame:SetMap(areaID)
		self.isInstance = false

		self:SetArea(areaID)
		self:SetName(GetAreaName(areaID))
	end

	frame:SetScript("OnClick", function(self)
		if (self:IsEnabled() == 1) then
			if (self.isInstance) then
				CallBoardUI:ClickGossipOptionOrGoBackAndSetDelayed(self)
			else
				if (self.worldMapID) then
					WorldMapFrame.blockWorldMapUpdate = true
					ShowUIPanel(WorldMapFrame)
					SetMapByID(self.worldMapID)
					WorldMapFrame.blockWorldMapUpdate = nil
					WorldMapFrame_UpdateMap()
				end
			end
		end
	end)

	frame:HookScript("OnEnter", function(self)
		Addon.SharedGossip:OnEnterDisplayTooltip(self)
	end)

	frame:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	frame:HookScript("OnMouseDown", function(self)
		self.icon:SetPoint("LEFT", 23, -2)
	end)

	frame:HookScript("OnMouseUp", function(self)
		self.icon:SetPoint("LEFT", 24, 0)
	end)

	return frame
end

function CallBoardUI:CreateRaidTemplate(name, parent)
	local frame = self:CreateAreaTemplate(name, parent)

	frame.total = frame:CreateFontString(nil, "OVERLAY")
	frame.total:SetJustifyH("RIGHT")
	frame.total:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
	frame.total:SetJustifyH("LEFT")
	frame.total:SetFontObject(GameFontHighlightLarge)

	frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 16, 12)

	frame.difficultyName = frame:CreateFontString(nil, "OVERLAY")
	frame.difficultyName:SetFontObject(GameFontHighlightMedium)
	frame.difficultyName:SetText("Area Name")

	frame.difficultyName:SetWidth(196)
	frame.difficultyName:SetPoint("RIGHT", -24, 0)
	frame.difficultyName:SetJustifyH("RIGHT")

	function frame:SetTime(resetTime)
		if not(resetTime) or (resetTime <= 0) then
			self.title:SetPoint("LEFT", self.icon, "RIGHT", 16, 0)
			self.total:SetText("")
		else
			self.title:SetPoint("LEFT", self.icon, "RIGHT", 16, 12)
			self.total:SetText(SecondsToTime(resetTime, true, true, 3))
		end
	end

	function frame:SetDifficulty(difficulty)
		self.difficultyName:SetText(difficulty)
	end

	function frame:SetDungeon(name)
		if not(CallBoardUI.LFRUnlocalized) then
			return
		end

		local unlocalziedName = CallBoardUI.LFRUnlocalized[name]
		local areaID = GetAreaIdByName(name)

		if not(unlocalziedName) or not(self:SetIcon("Interface\\LFGFrame\\LFGICON-"..unlocalziedName)) then
			if (areaID) and (CallBoardUI.areaIDIcons[areaID]) then
				self:SetIcon("Interface\\LFGFrame\\"..CallBoardUI.areaIDIcons[areaID])
			else
				return
			end
		end
	end

	function frame:SetRaidReset(instanceName, instanceReset, difficultyName)
		self.isTimeWalking = false

		self:SetTime(instanceReset)
		self:SetDifficulty(difficultyName)
		self:SetDungeon(instanceName)
	end

	function frame:SetTimeWalking(mapID, gossipOption)
		self.isTimeWalking = true
		local mapName = GetMapName(mapID) or ""

		self:SetTime(nil)
		self:SetDifficulty("")
		self:SetName(string.format(CallBoardUI.MSGS.TELEPORT_TO, mapName))
		self:SetDungeon(mapName)
		self.gossipOption = "TIMEWALKING_"..gossipOption
	end

	hooksecurefunc(frame, "SetName", function()
		frame.tooltipTitle = ""
	end)

	frame:SetScript("OnClick", function(self)
		if (self.isTimeWalking) then
			CallBoardUI:ClickGossipOptionOrGoBackAndSetDelayed(self)
			return
		else
			if (SlashCmdList["RAID_INFO"]) then
				SlashCmdList["RAID_INFO"]()
			end
		end
	end)

	return frame
end

function CallBoardUI:CreateTimerFrame(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame:SetHeight(20)
	frame:EnableMouse(true)

	frame.title = frame:CreateFontString(nil, "OVERLAY")
	frame.title:SetFontObject(GameFontNormalSmall)
	frame.title:SetPoint("LEFT", 8, 0)
	frame.title:SetText("timer")

	frame.icon = frame:CreateTexture(nil, "OVERLAY")
	frame.icon:SetSize(14, 14)
	frame.icon:SetAtlas("auctionhouse-icon-clock", Const.TextureKit.IgnoreAtlasSize)
	frame.icon:SetPoint("RIGHT", frame.title, "LEFT", -2, -1)

	frame.total = Addon.SharedGossip:CreateTimer(frame)

	frame.highlight = frame:CreateTexture(nil, "OVERLAY")
	frame.highlight:SetAtlas("auctionhouse-ui-row-select", Const.TextureKit.IgnoreAtlasSize)
	frame.highlight:SetPoint("TOPLEFT")
	frame.highlight:SetPoint("BOTTOMRIGHT")
	frame.highlight:SetBlendMode("ADD")
	frame.highlight:Hide()

	frame:SetScript("OnEnter", function(self)
		Addon.SharedGossip:OnEnterDisplayTooltip(self)
		self.highlight:Show()
	end)

	frame:SetScript("OnLeave", function(self)
		self.highlight:Hide()
		GameTooltip:Hide()
	end)

	return frame
end

function CallBoardUI:CreateControlButton(name, parent)
	local button = CreateFrame("BUTTON", "$parent."..name, parent, "SquareIconButtonTemplate")
	button.Icon:SetTexture("Interface\\Icons\\inv_misc_coin_01")

	function button:SetNormal()
		self.unavailable = false
		self:GetNormalTexture():SetVertexColor(1, 1, 1)
		self:GetPushedTexture():SetVertexColor(1, 1, 1)
		self.Icon:SetVertexColor(1, 1, 1)
	end

	function button:SetUnavailable(msg)
		self.unavailable = msg
		self:GetNormalTexture():SetVertexColor(1, 0, 0)
		self:GetPushedTexture():SetVertexColor(1, 0, 0)
		self.Icon:SetVertexColor(1, 0, 0)
	end

	function button:SendComplete(category)
		if (self.moneyCost) then
			C_TemporalContracts.ActivateTemporalContract(category, true)
		elseif (self.tokenCost) then
			C_TemporalContracts.ActivateTemporalContract(category, false)
		end
	end

	button:SetScript("OnEnter", function(self)
		local parent = self:GetParent()
		if parent.processingActive then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if (self.unavailable) then
			GameTooltip:AddLine(self.unavailable, 1, 0, 0, true)
			GameTooltip:AddLine(REQUIRES, 1, 0, 0)
		else
			GameTooltip:AddLine(REQUIRES, 1, 0.82, 0)
		end

		if (self.moneyCost) then
			SetTooltipMoney(GameTooltip, self.moneyCost)
		elseif (self.tokenCost) then
			local _, link = GetItemInfo(CallBoardUI.BAZAAR_TOKEN)
			local icon = GetItemIcon(CallBoardUI.BAZAAR_TOKEN)
			if (icon and link) then
				GameTooltip:AddLine("|cffFFFFFF"..self.tokenCost.." |T"..icon..".blp:16:16:0:0|t "..link)
			end
		end

		local errorMessage = self:GetParent().errorMessage
		if (errorMessage) then
			GameTooltip:AddLine(errorMessage, 1, 0.82, 0, 1)
		end

		GameTooltip:Show()
	end)

	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	button:SetScript("OnClick", function(self)
		if (self.unavailable) then
			return
		end

		local parent = self:GetParent()
		if parent.processingActive then
			return
		end

		if (parent.category) then
			if (self.moneyCost) then
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].text = CallBoardUI.MSGS.CONTRACT_DIALOGUE
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].hasMoneyFrame = true
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].cost = self.moneyCost
			else
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].text = CallBoardUI.MSGS.CONTRACT_DIALOGUE.."\n\n"..self.tokenCost.." "..GetItemLink(CallBoardUI.BAZAAR_TOKEN)
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].hasMoneyFrame = false
			end

			if type(parent.category) == "table" then
				StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].OnAccept = function()
					for i = 1, #parent.category do
						self:SendComplete(parent.category[i])
					end
				end
			elseif type(parent.category) == "string" then
				if (parent.timesToComplete > 0) then
					StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].OnAccept = function()
						for i = 1, parent.timesToComplete do
							self:SendComplete(parent.category)
						end
					end
				else
					StaticPopupDialogs["ASC_TEMPORAL_CONTRACT_CONFIRM"].OnAccept = function()
						CallBoardUI:StartMassComplete(parent.category, parent)
						if (self.moneyCost) then
							C_TemporalContracts.ActivateAllTemporalContractsByContentType(parent.category, true)
						elseif (self.tokenCost) then
							C_TemporalContracts.ActivateAllTemporalContractsByContentType(parent.category, false)
						end
					end
				end
			end

			StaticPopup_Show("ASC_TEMPORAL_CONTRACT_CONFIRM")
		end
	end)

	return button
end

function CallBoardUI:CreateAutoCompleteFrame(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame:SetSize(80, 80)
	frame:EnableMouse(true)

	frame.tooltipTitle = CallBoardUI.MSGS.COMPLETE_WITH_TEXT
	frame.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP

	frame.banner = frame:CreateTexture(nil, "BACKGROUND")
	frame.banner:SetTexture("Interface\\callboard\\atlas_4")
	frame.banner:SetSize(184*0.45, 195*0.45)
	frame.banner:SetPoint("CENTER", 0, -3)
	frame.banner:SetTexCoord(0, 0.1796, 0.8105, 1)

	frame.titleCompleteButtons = frame:CreateFontString(nil, "OVERLAY")
	frame.titleCompleteButtons:SetFontObject(GameFontNormalSmall)
	frame.titleCompleteButtons:SetPoint("CENTER", 0, 16)
	frame.titleCompleteButtons:SetText(CallBoardUI.MSGS.COMPLETE_WITH)

	frame.totalCompletionsIcon = frame:CreateTexture(nil, "ARTWORK")
	frame.totalCompletionsIcon:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)
	frame.totalCompletionsIcon:SetSize(32, 32)
	frame.totalCompletionsIcon:SetPoint("CENTER", 0, 20)

	frame.totalCompletionsIconBG = frame:CreateTexture(nil, "BORDER")
	SetPortraitToTexture(frame.totalCompletionsIconBG, "Interface\\Icons\\INV_Chest_Awakening")
	frame.totalCompletionsIconBG:SetVertexColor(0, 0, 0, 1)
	frame.totalCompletionsIconBG:SetSize(24, 24)
	frame.totalCompletionsIconBG:SetPoint("CENTER", frame.totalCompletionsIcon, 0, 0)

	frame.totalCompletionsText = frame:CreateFontString(nil, "OVERLAY")
	frame.totalCompletionsText:SetFontObject(NumberFontNormal)
	frame.totalCompletionsText:SetPoint("CENTER", frame.totalCompletionsIcon, 0, 0)
	frame.totalCompletionsText:SetText("10")

	frame.highlightIcon = frame:CreateTexture(nil, "OVERLAY")
	frame.highlightIcon:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.highlightIcon:SetPoint("CENTER", frame.totalCompletionsIcon)
	frame.highlightIcon:SetSize(24, 24)
	frame.highlightIcon:SetBlendMode("ADD")
	frame.highlightIcon:Hide()

	frame.shadowBG = frame:CreateTexture(nil, "BORDER")
	frame.shadowBG:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	frame.shadowBG:SetPoint("CENTER", frame.titleCompleteButtons, 0, -3)
	frame.shadowBG:SetHeight(34)
	frame.shadowBG:SetWidth(132)
	frame.shadowBG:SetAlpha(1)

	frame.completeForGoldButton = CallBoardUI:CreateControlButton("completeForGoldButton", frame)
	frame.completeForGoldButton:SetPoint("LEFT", frame, "CENTER", 1, -8)

	frame.completeForTokenButton = CallBoardUI:CreateControlButton("completeForTokenButton", frame)
	frame.completeForTokenButton:SetPoint("RIGHT", frame, "CENTER", -1, -8)

	frame.completeForTokenButton.Icon:SetTexture("Interface\\icons\\Spell_Shadow_Teleport")

	frame.processing = CreateFrame("Frame", "$parentProcessing", frame, "InputBlockTextLoadingTemplate")
	frame.processing:SetSize(160, 90)
	frame.processing:SetPoint("CENTER", frame, 0, 0)
	frame.processing:SetFrameLevel(frame:GetFrameLevel() + 10)
	frame.processing:Hide()
	frame.processing.Title:SetFontObject(GameFontNormalSmall)
	frame.processing.SubText:SetFontObject(GameFontDisableSmall)
	frame.processing:SetText(CallBoardUI.MSGS.COMPLETING, CallBoardUI.MSGS.COMPLETING_SUBTEXT)
	frame.processing.Spinner:SetSize(36, 36)
	frame.processing.Spinner:ClearAllPoints()
	frame.processing.Spinner:SetPoint("CENTER", frame.processing, 0, -6)

	function frame:SetProcessing(isProcessing)
		self.processingActive = isProcessing

		if isProcessing then
			self.completeForGoldButton:Disable()
			self.completeForTokenButton:Disable()
			self.processing:SetText(CallBoardUI.MSGS.COMPLETING, CallBoardUI.MSGS.COMPLETING_SUBTEXT)
			self.processing:Show()
		else
			self.processing:Hide()
			self.completeForGoldButton:Enable()
			self.completeForTokenButton:Enable()
			self:BalanceCheck()
			self:LevelCheck()
		end
	end

	function frame:BalanceCheck()
		local tokenCost = self.completeForTokenButton.tokenCost or 0
		local moneyCost = self.completeForGoldButton.moneyCost or 0

		if (GetItemCount(CallBoardUI.BAZAAR_TOKEN) < tokenCost) then
			self.completeForTokenButton:SetUnavailable(CallBoardUI.MSGS.TOOLTIP_ERROR_TOKEN)
		else
			self.completeForTokenButton:SetNormal()
		end

		if (GetMoney() < moneyCost) then
			self.completeForGoldButton:SetUnavailable(CallBoardUI.MSGS.TOOLTIP_ERROR_GOLD)
		else
			self.completeForGoldButton:SetNormal()
		end
	end

	function frame:LevelCheck()
		if self.levelRestriction and (UnitLevel("player") < self.levelRestriction) then
			self.completeForTokenButton:SetUnavailable(string.format(ITEM_MIN_LEVEL, self.levelRestriction))
			self.completeForGoldButton:SetUnavailable(string.format(ITEM_MIN_LEVEL, self.levelRestriction))
		end
	end

	function frame:LoadCategory(category)
		self.category = category
		local categoryReference = CallBoardUI.TemporalContractCategoryReference[category] or category

		if (categoryReference == CallBoardUI.categories.pve) then
			self.banner:SetTexCoord(0.1796, 0.3593, 0.8105, 1)
		elseif (categoryReference == CallBoardUI.categories.pvp) then
			self.banner:SetTexCoord(0.5351, 0.7148, 0.8105, 1)
		elseif (categoryReference == CallBoardUI.categories.prof) then
			self.banner:SetTexCoord(0, 0.1796, 0.8105, 1)
		elseif (categoryReference == CallBoardUI.categories.highRisk) then
			self.banner:SetTexCoord(0.3583, 0.538, 0.8105, 1)
		else
			self.banner:SetTexCoord(0.71582, 0.8955, 0.8105, 1)
		end
	end

	function frame:LoadCompletions(remainingCompletions)
		if (remainingCompletions) then
			self.totalCompletionsIcon:Show()
			self.totalCompletionsText:Show()
			self.totalCompletionsIconBG:Show()
			self.totalCompletionsText:SetText(remainingCompletions)
			self.titleCompleteButtons:Hide()
			self.shadowBG:Hide()
			self.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP_FULL
		else
			self.titleCompleteButtons:Show()
			self.shadowBG:Show()
			self.titleCompleteButtons:SetText(CallBoardUI.MSGS.COMPLETE_WITH)
			self.totalCompletionsIcon:Hide()
			self.totalCompletionsText:Hide()
			self.totalCompletionsIconBG:Hide()
			self.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP
		end
	end

	function frame:SetUp(moneyCost, tokenCost, category, timesToComplete, levelRestriction, errorMessage, remainingCompletions)
		if not(moneyCost) or not(tokenCost) or ((moneyCost == 0) and (tokenCost == 0)) then
			self.processingActive = false
			self.processing:Hide()
			self:Hide()
			return
		else
			self:Show()
		end

		self:LoadCompletions(remainingCompletions)

		self.timesToComplete = timesToComplete or 1
		self.completeForGoldButton.moneyCost = moneyCost
		self.completeForTokenButton.tokenCost = tokenCost
		self:LoadCategory(category)

		self.levelRestriction = levelRestriction
		self.errorMessage = errorMessage or ""

		self.completeForGoldButton:SetNormal()
		self.completeForTokenButton:SetNormal()

		if self.processingActive then
			self:SetProcessing(true)
		else
			self:BalanceCheck()
			self:LevelCheck()
		end
	end

	function frame:BAG_UPDATE()
		self:BalanceCheck()
		self:LevelCheck()
	end

	frame:SetScript("OnShow", function(self)
		self:HookBucketEvent("BAG_UPDATE", 0.2)
	end)

	frame:SetScript("OnHide", function(self)
		self:UnhookEvent("BAG_UPDATE")
	end)

	frame:SetScript("OnEnter", function(self)
		Addon.SharedGossip:OnEnterDisplayTooltip(self)
		if (self.titleCompleteButtons:IsVisible()) then
			-- pass
		elseif (self.totalCompletionsIcon:IsVisible()) then
			self.highlightIcon:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self.highlightIcon:Hide()
	end)

	return frame
end

function CallBoardUI:CreateReward(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame.defaultWidth = 32
	frame:SetSize(frame.defaultWidth, 32)

	frame.item = Addon.SharedGossip:CreateItemRing("item", frame)
	frame.item:SetPoint("CENTER")

	frame.item.icon:ClearAllPoints()
	frame.item.icon:SetPoint("CENTER")
	frame.item.icon:SetSize(32, 32)

	frame.item.ring:SetSize(42, 42)
	frame.item.ring:SetPoint("CENTER", frame.item.icon, 0, -1)
	frame.item.glow:SetSize(72, 72)
	frame.item.Highlight:SetSize(44, 44)

	frame.item.title:SetFontObject(NumberFontNormal)
	frame.item.title:ClearAllPoints()
	frame.item.title:SetPoint("BOTTOMRIGHT", frame.item.icon, "BOTTOMRIGHT", 0, 0)
	frame.item.title:SetJustifyH("RIGHT")

	frame.item.arrow = frame.item:CreateTexture(nil, "OVERLAY")
	frame.item.arrow:SetAtlas("loottoast-arrow-green", Const.TextureKit.IgnoreAtlasSize)
	frame.item.arrow:SetPoint("RIGHT", frame.item.title, "LEFT", 0, 0)
	frame.item.arrow:SetSize(16, 16)
	frame.item.arrow:Hide()

	function frame:SetCacheProgressReward()
		self.item.arrow:Show()
		self.item:SetToken("TOKEN_TYPE_CALLBOARD_CACHE_POINTS")
	end

	function frame.item:SetItem(itemID)
		local item = Item:CreateFromID(itemID)

		if self.cancelToken then
			self.cancelToken()
			self.cancelToken = nil
		end

		self.cancelToken = item:CancelableContinueOnLoad(function()
			if not item:IsCached() then
				return
			end

			self.item = itemID
			SetPortraitToTexture(self.icon, GetItemIcon(self.item))
		end)
	end

	function frame:SetItem(itemID)
		self.item.arrow:Hide()
		self.item:SetItem(itemID)
	end

	return frame
end

function CallBoardUI:CreateRewardsFrame(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame:SetHeight(36)
	frame:SetWidth(128)

	function frame:LoadRewards(rewards)
		local totalRewards = 0

		if (rewards and next(rewards)) then
			for i = 1, #rewards.RewardAmount do
				local total = rewards.RewardAmount[i]
				if (total > 0) then
					local itemID = rewards.RewardItems[i]

					if itemID and (itemID ~= 0) then
						totalRewards = totalRewards + 1
						self.frames[totalRewards]:SetItem(itemID)
						if (total > 1) then
							self.frames[totalRewards].item.title:SetText(total)
						else
							self.frames[totalRewards].item.title:SetText("")
						end
					end
				end
			end

			if (rewards.CacheProgress and rewards.CacheProgress > 0) then
				totalRewards = totalRewards + 1
				self.frames[totalRewards]:SetCacheProgressReward(rewards.CacheProgress)
				self.frames[totalRewards].item.title:SetText(rewards.CacheProgress)
			end
		end

		for i = 1, #self.frames do
			if i > totalRewards then
				self.frames[i]:Hide()
			else
				self.frames[i]:Show()
			end
		end

		self.frames[1]:SetPoint("CENTER", -(22*(totalRewards-1)), 0)
		self.totalRewards = totalRewards
	end

	function frame:SetJustifyH(justifyH)
		if (justifyH == "CENTER") then
			for i = 1, #self.frames do
				if (i > 1) then
					self.frames[i]:ClearAllPoints()
					self.frames[i]:SetPoint("LEFT", self.frames[i-1], "RIGHT", 12, 0)
				end
			end
		elseif (justifyH == "RIGHT") then
			for i = 1, #self.frames do
				if (i > 1) then
					self.frames[i]:ClearAllPoints()
					self.frames[i]:SetPoint("RIGHT", self.frames[i-1], "LEFT", -12, 0)
				end
			end

			hooksecurefunc(self, "LoadRewards", function(...)
				self.frames[1]:ClearAllPoints()
				self.frames[1]:SetPoint("RIGHT", 0, 0)
			end)
		elseif (justifyH == "LEFT") then
			hooksecurefunc(self, "LoadRewards", function(...)
				self.frames[1]:ClearAllPoints()
				self.frames[1]:SetPoint("LEFT", 0, 0)
			end)
		end
	end

	return frame
end

function CallBoardUI:CreateItemRewardsFrame(name, parent, MAX_REWARDS)
	local frame = CallBoardUI:CreateRewardsFrame(name, parent)
	MAX_REWARDS = MAX_REWARDS or 12

	function frame:CreateReward()
		self.frames = self.frames or {}
		local index = #self.frames+1
		local reward = CallBoardUI:CreateReward("reward"..index, self)
		table.insert(self.frames, reward)
		return reward
	end

	for i = 1, MAX_REWARDS do
		frame:CreateReward()
	end

	frame:SetJustifyH("CENTER")
	return frame
end

function CallBoardUI:CreateSubRewardsFrame(name, parent)
	local frame = CallBoardUI:CreateRewardsFrame(name, parent)
	local MAX_REWARDS = 3

	function frame:CreateReward()
		self.frames = self.frames or {}
		local index = #self.frames+1
		local reward = CallBoardUI:CreateReward("reward"..index, self)

		reward.moneyFrame = CreateFrame("FRAME", "$parent.moneyFrame", reward, "SmallMoneyFrameTemplate")
		reward.moneyFrame:SetPoint("RIGHT", 0, 0)
		SmallMoneyFrame_OnLoad(reward.moneyFrame)
		MoneyFrame_SetType(reward.moneyFrame, "STATIC")

		reward.pvpReward = CreateFrame("FRAME", "$parent.pvpReward", reward)
		reward.pvpReward:SetPoint("RIGHT", 0, 0)
		reward.pvpReward:SetHeight(13)

		reward.pvpReward.text = reward.pvpReward:CreateFontString(nil, "OVERLAY")
		reward.pvpReward.text:SetFontObject(NumberFontNormal)
		reward.pvpReward.text:SetPoint("LEFT", 0, 0)
		reward.pvpReward.text:SetJustifyH("LEFT")

		reward.pvpReward.icon = reward.pvpReward:CreateTexture(nil, "OVERLAY")
		reward.pvpReward.icon:SetPoint("LEFT", reward.pvpReward.text, "RIGHT", 4, 0) 
		reward.pvpReward.icon:SetSize(16, 16)

		reward.cacheProgressReward = CreateFrame("Frame", "$parentCacheProgressReward", reward)
		reward.cacheProgressReward:SetPoint("RIGHT", 0, 0)
		reward.cacheProgressReward:SetHeight(13)

		reward.cacheProgressReward.text = reward.cacheProgressReward:CreateFontString(nil, "OVERLAY")
		reward.cacheProgressReward.text:SetFontObject(NumberFontNormal)
		reward.cacheProgressReward.text:SetPoint("LEFT", 0, 0)
		reward.cacheProgressReward.text:SetJustifyH("LEFT")

		reward.cacheProgressReward.icon = reward.cacheProgressReward:CreateTexture(nil, "OVERLAY")
		reward.cacheProgressReward.icon:SetPoint("LEFT", reward.cacheProgressReward.text, "RIGHT", 4, 0)
		reward.cacheProgressReward.icon:SetSize(16, 16)
		reward.cacheProgressReward.icon:SetTexture("Interface\\Icons\\inv_misc_treasurechest04b")

		function reward:SetItem(itemID)
			self.cacheProgressReward:Hide()
			self.pvpReward:Hide()
			self.item:Show()
			self.moneyFrame:Hide()
			self:SetWidth(self.defaultWidth)
			self.item:SetItem(itemID)
		end

		function reward:SetMoney(money)
			self.cacheProgressReward:Hide()
			self.pvpReward:Hide()
			self.item:Hide()
			self.moneyFrame:Show()
			MoneyFrame_Update(self.moneyFrame, money)
			self:SetWidth(self.moneyFrame:GetWidth())
		end

		function reward:SetPvPReward(rewardType, total)
			self.cacheProgressReward:Hide()
			self.pvpReward:Show()
			self.item:Hide()
			self.moneyFrame:Hide()

			if (rewardType == "HONOR") then
				local factionGroup = UnitFactionGroup("player")
				self.pvpReward.icon:SetSize(32, 32)
				self.pvpReward.icon:SetPoint("LEFT", reward.pvpReward.text, "RIGHT", 0, -4) 
				if (factionGroup) then
					self.pvpReward.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)
					self.pvpReward.icon:Show()
				else
					self.pvpReward.icon:Hide()
				end
			elseif (rewardType == "ARENA") then
				self.pvpReward.icon:SetSize(16, 16)
				self.pvpReward.icon:SetPoint("LEFT", reward.pvpReward.text, "RIGHT", 4, 2) 
				self.pvpReward.icon:SetTexture("Interface\\PVPFrame\\PVP-ArenaPoints-Icon")
				self.pvpReward.icon:Show()
			else
				self.pvpReward.icon:Hide()
			end

			self.pvpReward.text:SetText(total)
			self.pvpReward:SetWidth(self.pvpReward.text:GetWidth()+16)
			self:SetWidth(self.pvpReward:GetWidth())
		end

		function reward:SetCacheProgressReward(total)
			self.cacheProgressReward:Show()
			self.pvpReward:Hide()
			self.item:Hide()
			self.moneyFrame:Hide()
			local rewardCacheItemID = C_CallboardCache.GetCallboardCacheInfo()
			self.cacheProgressReward.icon:SetTexture("Interface\\Icons\\"..GetItemIconInstant(rewardCacheItemID))
			self.cacheProgressReward.text:SetText(total)
			self.cacheProgressReward:SetWidth(self.cacheProgressReward.text:GetWidth()+16)
			self:SetWidth(self.cacheProgressReward:GetWidth())
		end

		table.insert(self.frames, reward)
		return reward
	end

	for i = 1, MAX_REWARDS do
		frame:CreateReward()
	end

	function frame:LoadRewards(rewards)
		local totalRewards = 0
		local totalWidth = 0
		local honor = 0

		if (rewards and next(rewards)) then
			if (rewards.RewardMoney and (rewards.RewardMoney > 0)) then
				totalRewards = totalRewards + 1
				self.frames[totalRewards]:SetMoney(rewards.RewardMoney)
				totalWidth = totalWidth + self.frames[totalRewards]:GetWidth()
			end

			if (rewards.RewardHonor) then
				honor = CallBoardUI.CorrectHonorReward(rewards.RewardHonor) 
			end

			if (honor and (honor > 0)) then
				totalRewards = totalRewards + 1
				self.frames[totalRewards]:SetPvPReward("HONOR", honor)
				totalWidth = totalWidth + self.frames[totalRewards]:GetWidth()
			end

			if (rewards.RewardArenaPoints and (rewards.RewardArenaPoints > 0)) then
				totalRewards = totalRewards + 1
				self.frames[totalRewards]:SetPvPReward("ARENA", rewards.RewardArenaPoints)
				totalWidth = totalWidth + self.frames[totalRewards]:GetWidth()
			end
		end

		for i = 1, #self.frames do
			if i > totalRewards then
				self.frames[i]:Hide()
			else
				self.frames[i]:Show()
			end
		end

		self.frames[1]:SetPoint("CENTER", -(totalWidth/2), 0)
		self.totalRewards = totalRewards
	end

	frame:SetJustifyH("CENTER")
	return frame
end

function CallBoardUI:CreateQuestShield(name, parent)
	local frame = CreateFrame("FRAME", "$parent.name", parent)
	frame:SetSize(59.4, 76.8)

	frame.Shield = frame:CreateTexture(nil, "BACKGROUND")
	frame.Shield:SetTexture("Interface\\callboard\\atlas")
	frame.Shield:SetTexCoord(1, 0.784, 0, 0.2783)
	frame.Shield:SetSize(59.4, 76.8)
	frame.Shield:SetPoint("CENTER")

	frame.categoryIcon = frame:CreateTexture(nil, "BORDER")
	frame.categoryIcon:SetTexture("Interface\\callboard\\atlas")
	frame.categoryIcon:SetTexCoord(0.60156, 0.71875, 0.59765, 0.745117)
	frame.categoryIcon:SetSize(38.4, 48.32)
	frame.categoryIcon:SetPoint("CENTER", frame.Shield, 0, 4)

	frame.questMark = frame:CreateTexture(nil, "ARTWORK")
	frame.questMark:SetTexture("Interface\\callboard\\atlas")
	frame.questMark:SetSize(15.7, 44.52)
	frame.questMark:SetTexCoord(0.6923, 0.747, 0, 0.15527)
	frame.questMark:SetPoint("CENTER", frame.Shield, 0, 4)

	function frame:SetPoAIcon()
		self.isPoA = true
	end

	function frame:SetComplete(daily)
		if self.isPoA then
			self.questMark:SetTexCoord(0, 1, 0, 1)
			self.questMark:SetTexture("INTERFACE\\BUTTONS\\PoAQuestIconBLP_Complete")
			self.questMark:SetSize(72, 72)
			return
		end

		self.questMark:SetTexture("Interface\\callboard\\atlas")
		self.questMark:SetDesaturated(false)
		self.questMark:SetSize(26.6, 44.52)

		if daily then
			self.questMark:SetTexCoord(0.5996, 0.692382, 0.15527, 0.3105)
		else
			self.questMark:SetTexCoord(0.5996, 0.692382, 0, 0.15527)
		end
	end

	function frame:SetAvailable(daily)
		self.questMark:SetDesaturated(false)

		if self.isPoA then
			self.questMark:SetTexCoord(0, 1, 0, 1)
			self.questMark:SetTexture("INTERFACE\\BUTTONS\\PoAQuestIconBLP")
			self.questMark:SetSize(72, 72)
		else
			self.questMark:SetTexture("Interface\\callboard\\atlas")
			self.questMark:SetSize(15.7, 44.52)

			if daily then
				self.questMark:SetTexCoord(0.6923, 0.747, 0.15527, 0.3105)
			else
				self.questMark:SetTexCoord(0.6923, 0.747, 0, 0.15527)
			end
		end
	end

	function frame:SetActive(daily)
		self:SetComplete(daily)
		if self.isPoA then
			self.questMark:SetTexCoord(0, 1, 0, 1)
			self.questMark:SetTexture("INTERFACE\\BUTTONS\\PoAQuestIconBLP_Uncomplete")
			self.questMark:SetSize(72, 72)
			return
		end
		self.questMark:SetDesaturated(true)
	end

	return frame
end

function CallBoardUI:CreateExpandedMenu(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame:SetSize(572, 552)
	frame:EnableMouse(true)

	frame.topLeft = frame:CreateTexture(nil, "BORDER")
	frame.topLeft:SetTexture("Interface\\callboard\\atlas_10")
	frame.topLeft:SetSize(106.65, 71)
	frame.topLeft:SetPoint("TOPLEFT")
	frame.topLeft:SetTexCoord(0, 0.2314, 0, 0.15332)

	frame.topRight = frame:CreateTexture(nil, "BORDER") 
	frame.topRight:SetTexture("Interface\\callboard\\atlas_10")
	frame.topRight:SetSize(92.25, 71)
	frame.topRight:SetPoint("TOPRIGHT", 0, 0)
	frame.topRight:SetTexCoord(0, 0.199, 0.15332, 0.30664)

	frame.top = frame:CreateTexture(nil, "BORDER") 
	frame.top:SetTexture("Interface\\callboard\\atlas_10")
	frame.top:SetPoint("TOPLEFT", frame.topLeft, "TOPRIGHT", 0, 0)
	frame.top:SetPoint("BOTTOMRIGHT", frame.topRight, "BOTTOMLEFT", 1, 0)
	frame.top:SetTexCoord(0, 0.56542, 0.3066, 0.45996)

	frame.bottomRight = frame:CreateTexture(nil, "BORDER")
	frame.bottomRight:SetTexture("Interface\\callboard\\atlas_10")
	frame.bottomRight:SetSize(92.25, 48.6)
	frame.bottomRight:SetPoint("BOTTOMRIGHT")
	frame.bottomRight:SetTexCoord(0, 0.2, 0.5654, 0.6708)

	frame.bottomLeft = frame:CreateTexture(nil, "BORDER")
	frame.bottomLeft:SetTexture("Interface\\callboard\\atlas_10")
	frame.bottomLeft:SetSize(106.65, 48.6)
	frame.bottomLeft:SetPoint("BOTTOMLEFT")
	frame.bottomLeft:SetTexCoord(0.2, 0.4316, 0.5654, 0.6708)

	frame.bottom = frame:CreateTexture(nil, "BORDER") 
	frame.bottom:SetTexture("Interface\\callboard\\atlas_10")
	frame.bottom:SetPoint("TOPLEFT", frame.bottomLeft, "TOPRIGHT", 0, 0)
	frame.bottom:SetPoint("BOTTOMRIGHT", frame.bottomRight, "BOTTOMLEFT", 1, 0)
	frame.bottom:SetTexCoord(0, 0.56542, 0.4599, 0.56542)

	frame.artBottomLeft = frame:CreateTexture(nil, "OVERLAY") 
	frame.artBottomLeft:SetTexture("Interface\\callboard\\atlas_4")
	frame.artBottomLeft:SetPoint("BOTTOMLEFT", 20, 16)
	frame.artBottomLeft:SetTexCoord(0, 0.0371, 0.708, 0.745)
	frame.artBottomLeft:SetSize(32, 32)

	frame.artBottomRight = frame:CreateTexture(nil, "OVERLAY") 
	frame.artBottomRight:SetTexture("Interface\\callboard\\atlas_4")
	frame.artBottomRight:SetPoint("BOTTOMRIGHT", -20, 16)
	frame.artBottomRight:SetTexCoord(0.0371, 0, 0.708, 0.745)
	frame.artBottomRight:SetSize(32, 32)

	frame.artTopRight = frame:CreateTexture(nil, "OVERLAY") 
	frame.artTopRight:SetTexture("Interface\\callboard\\atlas_4")
	frame.artTopRight:SetPoint("TOPRIGHT", -20, -20)
	frame.artTopRight:SetTexCoord(0.0712, 0.111, 0.707, 0.7353)
	frame.artTopRight:SetSize(32, 24)

	frame.right = frame:CreateTexture(nil, "ARTWORK") 
	frame.right:SetTexture("Interface\\callboard\\atlas_10")
	frame.right:SetPoint("TOPRIGHT", 0, -16)
	frame.right:SetPoint("BOTTOMRIGHT", 0, 16)
	frame.right:SetWidth(48.6)
	frame.right:SetTexCoord(0.894, 1, 0, 0.56542)

	frame.left = frame:CreateTexture(nil, "ARTWORK") 
	frame.left:SetTexture("Interface\\callboard\\atlas_10")
	frame.left:SetPoint("TOPLEFT", 0, -16)
	frame.left:SetPoint("BOTTOMLEFT", 0, 16)
	frame.left:SetWidth(48.6)
	frame.left:SetTexCoord(1, 0.894, 0, 0.56542)

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetPoint("TOPLEFT", 16, -16)
	frame.bg:SetPoint("BOTTOMRIGHT", -16, 16)
	frame.bg:SetTexture("Interface\\callboard\\paperBG", "MIRROR", "MIRROR")
	frame.bg:SetHorizTile(true)
	frame.bg:SetVertTile(true)

	frame.completeButtons = CreateFrame("FRAME", "$parent.completeButtons", frame)
	frame.completeButtons:SetPoint("BOTTOM", frame, 0, 32)
	frame.completeButtons:SetSize(413, 64)

	frame.completeButtons.completeButtonsTexture = frame.completeButtons:CreateTexture(nil, "BACKGROUND")
	frame.completeButtons.completeButtonsTexture:SetTexture("Interface\\callboard\\atlas_4")
	frame.completeButtons.completeButtonsTexture:SetTexCoord(0, 0.4482, 0.6386, 0.708)
	frame.completeButtons.completeButtonsTexture:SetAllPoints()

	return frame
end

function CallBoardUI:CreateCategorizedQuestDetailsFrame(name, parent)
	local frame = CallBoardUI:CreateExpandedMenu(name, parent)
	frame:SetWidth(772)

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetTexture("Interface\\Icons\\Achievement_Zone_AlteracMountains_01")
	frame.icon:SetSize(42, 42)
	frame.icon:SetPoint("TOPLEFT", 24, -22)

	frame.iconBorder = frame:CreateTexture(nil, "OVERLAY")
	frame.iconBorder:SetTexture("Interface\\callboard\\atlas_4")
	frame.iconBorder:SetSize(90, 90)
	frame.iconBorder:SetPoint("CENTER", frame.icon, 0, 0)
	frame.iconBorder:SetTexCoord(0.65917, 1, 0, 0.336914)

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 16, 8)
	frame.title:SetJustifyH("LEFT")
	frame.title:SetText("Area Name")
	frame.title:SetVertexColor(1, 0.82, 0, 1)
	frame.title:SetWidth(500)

	frame.Completions = CreateFrame("FRAME", "$parentCompletions", frame)
	frame.Completions:SetSize(256, 24)
	frame.Completions:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT")
	frame.Completions:EnableMouse(true)

	frame.Completions.tooltipTitle = CallBoardUI.MSGS.COMPLETE_WITH_TEXT
	frame.Completions.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP_FULL

	frame.Completions:HookScript("OnEnter", function(self)
		self.Icon.highlightIcon:Show()
		Addon.SharedGossip:OnEnterDisplayTooltip(self)
	end)

	frame.Completions:HookScript("OnLeave", function(self)
		self.Icon.highlightIcon:Hide()
		GameTooltip:Hide()
	end)

	frame.Completions.title = frame.Completions:CreateFontString(nil)
	frame.Completions.title:SetFontObject(GameFontHighlightLarge)
	frame.Completions.title:SetPoint("LEFT", 0, 0)
	frame.Completions.title:SetJustifyH("LEFT")
	frame.Completions.title:SetText("Remaining Completions")
	frame.Completions.title:SetVertexColor(1, 0.82, 0, 1)

	frame.Completions.Icon = CreateFrame("BUTTON", "$parentIcon", frame, "BorderIconTemplate")
	frame.Completions.Icon:SetSize(19, 19)
	frame.Completions.Icon:EnableMouse(false)
	frame.Completions.Icon:SetIconAtlas("realm-select-icon-bg")
	frame.Completions.Icon.Icon:SetVertexColor(0, 0, 0)
	frame.Completions.Icon:SetBorderOffset(-1, -2)
	frame.Completions.Icon:SetRounded(true)
	frame.Completions.Icon:SetBorderAtlas("pta-icon-border")
	frame.Completions.Icon:SetBorderSize(28, 28)
	frame.Completions.Icon:SetPoint("LEFT", frame.Completions.title, "RIGHT", 8, 0)

	frame.Completions.Icon.highlightIcon = frame.Completions.Icon:CreateTexture(nil, "OVERLAY")
	frame.Completions.Icon.highlightIcon:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)
	frame.Completions.Icon.highlightIcon:SetPoint("CENTER", frame.Completions.Icon.Icon)
	frame.Completions.Icon.highlightIcon:SetSize(16, 16)
	frame.Completions.Icon.highlightIcon:SetBlendMode("ADD")
	frame.Completions.Icon.highlightIcon:Hide()

	frame.Completions.Icon.title = frame.Completions.Icon:CreateFontString(nil, "OVERLAY")
	frame.Completions.Icon.title:SetFontObject(GameFontHighlight)
	frame.Completions.Icon.title:SetPoint("CENTER", 0, 0)
	frame.Completions.Icon.title:SetJustifyH("CENTER")
	frame.Completions.Icon.title:SetText("7")
	frame.Completions.Icon.title:SetVertexColor(1, 1, 1, 1)

	frame.completeButtons:ClearAndSetPoint("BOTTOMRIGHT", frame, -4, 8)
	frame.completeButtons:SetSize(396, 36)

	frame.completeButtons.acceptButton = CreateFrame("Button", "$parent.acceptButton", frame.completeButtons, "StaticPopupButtonTemplate")
	frame.completeButtons.acceptButton:SetText(CallBoardUI.MSGS.ACCEPT_ALL_QUESTS)
	frame.completeButtons.acceptButton:SetPoint("RIGHT", frame.completeButtons, "CENTER", 0, 0)
	frame.completeButtons.acceptButton:GetFontString():SetDrawLayer("OVERLAY")
	frame.completeButtons.acceptButton:SetWidth(185)
	frame.completeButtons.acceptButton:SetHeight(22)

	frame.completeButtons.completeButton = CreateFrame("Button", "$parent.acceptButton", frame.completeButtons, "StaticPopupButtonTemplate")
	frame.completeButtons.completeButton:SetText(CallBoardUI.MSGS.TURN_IN_ALL_QUESTS)
	frame.completeButtons.completeButton:SetPoint("LEFT", frame.completeButtons, "CENTER", 0, 0)
	frame.completeButtons.completeButton:GetFontString():SetDrawLayer("OVERLAY")
	frame.completeButtons.completeButton:SetWidth(185)
	frame.completeButtons.completeButton:SetHeight(22)

	frame.completeButtons.acceptButton:SetScript("OnClick", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end
		
		for _, quest in pairs(self:GetParent():GetParent().quests) do
			AcceptAvailableGossipQuest(quest.ID)
		end
		--AcceptAllAvailableGossipQuests()
	end)

	frame.completeButtons.completeButton:SetScript("OnClick", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end
		
		for _, quest in pairs(self:GetParent():GetParent().quests) do
			if quest.isComplete then
				CompleteActiveGossipQuest(quest.ID)
			end
		end
		--AcceptAllAvailableGossipQuests()
	end)

	frame.questPool = {}

	function frame:SetSubCategoryDetails(name, quests)
		self.name = name
		self.quests = quests
		
		self.completeButtons.completeButton:Disable()
		self.completeButtons.acceptButton:Disable()

		self.title:SetText("|cffFFFFFF"..self.name)

		if self.quests[1] and self.quests[1].remainingCompletions then
			self.Completions.Icon.title:SetText(self.quests[1].remainingCompletions)
			self.Completions:Show()
		end

		local activeQuests = 0

		for _, btn in pairs(self.questPool) do
			btn:Hide()
		end

		for _, data in pairs(self.quests) do
			activeQuests = activeQuests + 1

			local btn = self.questPool[activeQuests]

			if not btn then
				btn = CallBoardUI:CreateQuestSlotCategorized(self:GetName().."Quest"..activeQuests, self)
				table.insert(self.questPool, btn)

				if activeQuests == 1 then
					btn:SetPoint("TOPLEFT", 24, -76)
					btn.bg:Show()
				elseif activeQuests%2 == 0 then
					btn:SetPoint("LEFT", self.questPool[activeQuests-1], "RIGHT", 4, 0)
				else
					btn:SetPoint("TOP", self.questPool[activeQuests-2], "BOTTOM")
				end

				if math.ceil(activeQuests/2)%2 ~= 0 then
					btn.bg:Show()
				end
			end

			btn:Show()
			btn:SetQuest(data.ID, data.name, data.isDaily, data.buttonIndex, data.isActive, data.isComplete, CallBoardUI.content.ExtraSlotsCategorized.category, data.remainingCompletions)

			-- can be removed
			if #self.quests == 1 then
				btn:SetWidth(724)
			else
				btn:SetWidth(362)
			end

			if data.isComplete then
				self.completeButtons.completeButton:Enable()
			elseif not(data.isActive) then
				self.completeButtons.acceptButton:Enable()
			end
		end

		local totalHeight = 125+65*math.ceil(activeQuests/2)
		self:SetHeight(totalHeight)
	end

	return frame
end

function CallBoardUI:CreateQuestDetailsFrame(name, parent)
	-- TODO: Move to NineSlice
	local frame = CallBoardUI:CreateExpandedMenu(name, parent)

	frame.shieldFrame = CallBoardUI:CreateQuestShield(shieldFrame, frame)
	frame.shieldFrame:SetPoint("TOPLEFT", 0, -10)
	--frame.shieldFrame:SetPoAIcon(true)
	frame.shieldFrame.categoryIcon:Hide()

	frame.artAsc = frame:CreateTexture(nil, "OVERLAY") 
	frame.artAsc:SetTexture("Interface\\callboard\\atlas_10")
	frame.artAsc:SetPoint("BOTTOMRIGHT", -20, 82)
	frame.artAsc:SetTexCoord(0.432, 1, 0.5791, 1)
	frame.artAsc:SetSize(291, 215)
	frame.artAsc:SetAlpha(0.6)

	frame.completeButtons.acceptButton = CreateFrame("Button", "$parent.acceptButton", frame.completeButtons, "RedButtonTemplate")
	frame.completeButtons.acceptButton:SetText(ACCEPT)
	frame.completeButtons.acceptButton:SetPoint("RIGHT", frame.completeButtons.completeButtonsTexture, "CENTER", -4, 0)
	frame.completeButtons.acceptButton:GetFontString():SetDrawLayer("OVERLAY")
	frame.completeButtons.acceptButton:SetWidth(172)
	frame.completeButtons.acceptButton:SetHeight(40)
	frame.completeButtons.acceptButton:SetScript("OnClick", function(self)
		local questID = self:GetParent():GetParent().ID
		local isActive = self:GetParent():GetParent().isActive
		local isComplete = self:GetParent():GetParent().isComplete

		if (questID) then
			if isComplete then
				CompleteActiveGossipQuest(questID)
			elseif not(isActive) then
				AcceptAvailableGossipQuest(questID)
			end
		end
	end)

	frame.completeButtons.declineButton = CreateFrame("Button", "$parent.declineButton", frame.completeButtons, "RedButtonTemplate")
	frame.completeButtons.declineButton:SetText("Decline")
	frame.completeButtons.declineButton:SetPoint("LEFT", frame.completeButtons.completeButtonsTexture, "CENTER", 4, 0)
	frame.completeButtons.declineButton:GetFontString():SetDrawLayer("OVERLAY")
	frame.completeButtons.declineButton:SetWidth(172)
	frame.completeButtons.declineButton:SetHeight(40)

	frame.fontString = frame:CreateFontString(nil, "OVERLAY")
	frame.fontString:SetFontObject(GameFontHighlightLarge)
	frame.fontString:SetPoint("LEFT", frame.shieldFrame, "RIGHT", 4, 0)
	frame.fontString:SetJustifyH("LEFT")
	frame.fontString:SetJustifyV("CENTER")
	frame.fontString:SetVertexColor(0, 0, 0, 1)
	frame.fontString:SetShadowOffset(0, 0)
	frame.fontString:SetWidth(192)
	frame.fontString:SetText("Path of Ascension: Quest Name Example")

	frame.questDescription = frame:CreateFontString(nil, "OVERLAY")
	frame.questDescription:SetPoint("TOPLEFT", frame.fontString, "BOTTOMLEFT", 0, -8)
	frame.questDescription:SetWidth(450)
	frame.questDescription:SetFontObject(GameFontHighlight)
	frame.questDescription:SetJustifyH("LEFT")
	frame.questDescription:SetJustifyV("TOP")
	frame.questDescription:SetText(CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP_FULL)
	frame.questDescription:SetVertexColor(0, 0, 0, 1)
	frame.questDescription:SetShadowOffset(0, 0)

	frame.questDetailsTitle = frame:CreateFontString(nil, "OVERLAY")
	frame.questDetailsTitle:SetFontObject(GameFontHighlightLarge)
	frame.questDetailsTitle:SetPoint("TOPLEFT", frame.questDescription, "BOTTOMLEFT", 0, -16)
	frame.questDetailsTitle:SetJustifyH("LEFT")
	frame.questDetailsTitle:SetJustifyV("TOP")
	frame.questDetailsTitle:SetVertexColor(0, 0, 0, 1)
	frame.questDetailsTitle:SetShadowOffset(0, 0)
	frame.questDetailsTitle:SetWidth(192)
	frame.questDetailsTitle:SetText(QUEST_OBJECTIVES)

	frame.questDetails = frame:CreateFontString(nil, "OVERLAY")
	frame.questDetails:SetPoint("TOPLEFT", frame.questDetailsTitle, "BOTTOMLEFT", 0, -8)
	frame.questDetails:SetWidth(450)
	frame.questDetails:SetFontObject(GameFontHighlight)
	frame.questDetails:SetJustifyH("LEFT")
	frame.questDetails:SetJustifyV("TOP")
	frame.questDetails:SetText(CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP_FULL)
	frame.questDetails:SetVertexColor(0, 0, 0, 1)
	frame.questDetails:SetShadowOffset(0, 0)

	frame.rewardsTitle = frame:CreateFontString(nil, "OVERLAY")
	frame.rewardsTitle:SetFontObject(GameFontHighlightLarge)
	frame.rewardsTitle:SetPoint("TOPLEFT", frame.questDetails, "BOTTOMLEFT", 0, -16)
	frame.rewardsTitle:SetJustifyH("LEFT")
	frame.rewardsTitle:SetJustifyV("TOP")
	frame.rewardsTitle:SetVertexColor(0, 0, 0, 1)
	frame.rewardsTitle:SetShadowOffset(0, 0)
	frame.rewardsTitle:SetWidth(192)
	frame.rewardsTitle:SetText("Rewards")

	frame.moneyRewardString = frame:CreateFontString(nil, "OVERLAY")
	frame.moneyRewardString:SetPoint("TOPLEFT", frame.rewardsTitle, "BOTTOMLEFT", 0, -8)
	frame.moneyRewardString:SetFontObject(GameFontHighlight)
	frame.moneyRewardString:SetJustifyH("LEFT")
	frame.moneyRewardString:SetJustifyV("TOP")
	frame.moneyRewardString:SetText("You will recieve:")
	frame.moneyRewardString:SetVertexColor(0, 0, 0, 1)
	frame.moneyRewardString:SetShadowOffset(0, 0)

	frame.moneyFrame = CreateFrame("FRAME", "$parent.moneyFrame", frame, "SmallMoneyFrameTemplate")
	frame.moneyFrame:SetPoint("LEFT", frame.moneyRewardString, "RIGHT", 10, 0)
	SmallMoneyFrame_OnLoad(frame.moneyFrame)
	MoneyFrame_SetType(frame.moneyFrame, "STATIC")

	function frame:CreateItem(id)
		local item = CreateFrame("BUTTON", "$parent.item"..id, self, "QuestItemTemplate")
		item.id = id

	    item:SetScript("OnEnter", function(self)
	    	if (self.item) then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink("item:"..self.item)
				GameTooltip:Show()
			end

		end)

		item:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		item:SetScript("OnClick", function(self)
			if ( IsModifiedClick() and self.link) then
				HandleModifiedItemClick(self.link)
			end
		end)

		function item:SetItem(itemID, total)
		    local item = Item:CreateFromID(itemID)

		    if self.cancelToken then
		        self.cancelToken()
		        self.cancelToken = nil
		    end

		    self.cancelToken = item:CancelableContinueOnLoad(function()
		        if not item:IsCached() then
		            dprint("Tried to cache Item", itemID, "but it doesn't exist?")
		            return
		        end

			    local name, link = GetItemInfo(itemID)
				local icon = GetItemIcon(itemID)

				self.item = itemID
				self.link = link

				SetItemButtonCount(self, total)
				SetItemButtonTexture(self, icon)

				_G[self:GetName().."Name"]:SetText(name)

		    end)
		end

		return item
	end

	frame.item1 = frame:CreateItem(1)
	frame.item1:SetPoint("TOPLEFT", frame.moneyRewardString, "BOTTOMLEFT", 0, -10)

	frame.item2 = frame:CreateItem(2)
	frame.item2:SetPoint("LEFT", frame.item1, "RIGHT", 2, 0)

	frame.item3 = frame:CreateItem(3)
	frame.item3:SetPoint("TOP", frame.item1, "BOTTOM", 0, -3)

	frame.item4 = frame:CreateItem(4)
	frame.item4:SetPoint("LEFT", frame.item3, "RIGHT", 2, 0)

	function frame:SetActive()
		self.shieldFrame:SetActive()
		self.isActive = true
		self.completeButtons.acceptButton:Disable()
		self.completeButtons.acceptButton:SetText(COMPLETE)
	end

	function frame:SetAvailable()
		self.shieldFrame:SetAvailable()
		self.isActive = false
		self.isComplete = false
		self.completeButtons.acceptButton:Enable()
		self.completeButtons.acceptButton:SetText(ACCEPT)
	end

	function frame:SetComplete()
		self.shieldFrame:SetComplete()
		self.isComplete = true
		self.completeButtons.acceptButton:Enable()
		self.completeButtons.acceptButton:SetText(COMPLETE)
	end

	function frame:SetQuest(questID, isActive, isComplete)
		local quest = Quest:CreateFromID(questID)

		if self.cancelToken then
	        self.cancelToken()
	        self.cancelToken = nil
	    end

	    self.cancelToken = quest:CancelableContinueOnLoad(function()
	        if not quest:IsCached() then
	            dprint("Tried to cache quest", questID, "but it doesn't exist?")
	            self.questQueue[questID] = nil
	            self:MoveQuestQueue()
	            return
	        end

	        self.ID = questID

			if (isComplete) then
				self:SetComplete()
			elseif (isActive) then
				self:SetActive()
			else
				self:SetAvailable()
			end

	        local questTemplate = GetQuestTemplate(questID)
	        self.fontString:SetText(questTemplate.Title)

	        if (isComplete or isActive) then
	        	self.questDescription:SetText(questTemplate.Objectives)
	        	self.questDetailsTitle:SetText(QUEST_DESCRIPTION)
	        	self.questDetails:SetText(questTemplate.Details)
	        else
	        	self.questDetailsTitle:SetText(QUEST_OBJECTIVES)
		        self.questDescription:SetText(questTemplate.Details)
		        self.questDetails:SetText(questTemplate.Objectives)
		    end

	        if (questTemplate.RewardMoney) then
	        	MoneyFrame_Update(self.moneyFrame, questTemplate.RewardMoney)
	        end

	        local totalHeight = 195+frame.fontString:GetHeight()+frame.questDescription:GetHeight()+frame.questDetailsTitle:GetHeight()+frame.questDetails:GetHeight()+frame.rewardsTitle:GetHeight()+frame.moneyRewardString:GetHeight()
	        local totalRewards = 0

	        for i = 1, 4 do
	        	self["item"..i]:Hide()
	        	if (questTemplate.RewardAmount[i] and (questTemplate.RewardAmount[i] > 0) and (questTemplate.RewardItems[i] ~= 0)) then
	        		totalRewards = totalRewards + 1
	        		self["item"..totalRewards]:SetItem(questTemplate.RewardItems[i], questTemplate.RewardAmount[i])
	        		self["item"..totalRewards]:Show()
	        	end
	        end

	        if (totalRewards > 0) then
	        	local rows = math.ceil(totalRewards/2)
	        	totalHeight = totalHeight + 10 + frame.item1:GetHeight()*rows + 3*(rows-1)
	        end

	        self:SetHeight(totalHeight)
	    end)
	end

	return frame
end

function CallBoardUI:CreateCategoryTemplate(name, parent)
	local frame = self:CreateWoodenTemplate(name, parent)
	frame:SetWidth(772)

	frame.normalHeight = frame:GetHeight()
	frame.subTabsTotal = 0 -- used to calculate frame size
	frame.subTabs = {}
	frame.lastSubTab = nil -- used to define which subtab is last visible

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetPoint("TOP", 0, -16)
	frame.title:SetText("Area Name")
	frame.title:SetVertexColor(1, 0.82, 0, 1)

	frame.rewards = self:CreateItemRewardsFrame("rewards", frame)
	frame.rewards:SetPoint("TOP", frame.title, "BOTTOM", 0, -12)
	frame.rewards:SetJustifyH("CENTER")

	frame.subRewards = self:CreateSubRewardsFrame("subRewards", frame)
	frame.subRewards:SetPoint("TOP", frame.rewards, "BOTTOM", 0, 8)
	frame.subRewards:SetJustifyH("LEFT")

	frame.Shield = frame:CreateTexture(nil, "BORDER")
	frame.Shield:SetTexture("Interface\\callboard\\atlas")
	frame.Shield:SetTexCoord(1, 0.784, 0, 0.2783)
	frame.Shield:SetSize(59.4, 76.8)
	frame.Shield:SetPoint("LEFT")

	frame.categoryIcon = frame:CreateTexture(nil, "ARTWORK")
	frame.categoryIcon:SetTexture("Interface\\callboard\\atlas")
	frame.categoryIcon:SetTexCoord(0.60156, 0.71875, 0.59765, 0.745117)
	frame.categoryIcon:SetSize(38.4, 48.32)
	frame.categoryIcon:SetPoint("CENTER", frame.Shield, 0, 4)

	frame.completeFrame = CallBoardUI:CreateAutoCompleteFrame("completeFrame", frame)
	frame.completeFrame:SetPoint("RIGHT", -14, 0)

	function frame:CreateSubCategory(name)
		local subCategory = CallBoardUI:CreateCategoryTemplate(name, self)

		subCategory.isSubCategory = true

		subCategory.Shield:Hide()
		subCategory.categoryIcon:Hide()

		subCategory.title:ClearAllPoints()
		subCategory.title:SetFontObject(GameFontHighlightLarge)
		subCategory.title:SetPoint("LEFT", 24, 0)
		subCategory.title:SetJustifyH("LEFT")
		subCategory.title:SetJustifyV("CENTER")
		subCategory.title:SetVertexColor(1, 0.82, 0, 1)
		subCategory.title:SetShadowOffset(1, -1)
		subCategory.title:SetWidth(192)

		subCategory.rewards:ClearAllPoints()
		subCategory.rewards:SetPoint("LEFT", subCategory.title, "RIGHT", 8, 0)
		subCategory.rewards:SetJustifyH("LEFT")

		subCategory.bg_left:SetVertexColor(0.6, 0.6, 0.6, 1)
		subCategory.bg_right:SetVertexColor(0.6, 0.6, 0.6, 1)
		subCategory.bg:SetVertexColor(0.6, 0.6, 0.6, 1)

		subCategory:EnableMouse(false)

		subCategory:Hide()

		subCategory:SetScript("OnClick", function(self)
		end)

		--[[if not(self.subTabs) then
			self.subTabs = {}
		end]]--

		self.subTabs[name] = subCategory

		return subCategory
	end

	function frame:SetName(name)
		self.name = name
		self.tooltipTitle = name
		self.title:SetText(name)
	end

	function frame:LoadRewards(rewards)
		self.rewards:LoadRewards(rewards)
		self.subRewards:LoadRewards(rewards)

		self.rewards:ClearAllPoints()
		self.subRewards:ClearAllPoints()

		if (self.isSubCategory) then
			if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
				self.subRewards:SetPoint("LEFT", self.title, "RIGHT", 8, 0)
			elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
				self.rewards:SetPoint("LEFT", self.title, "RIGHT", 8, 0)
			else
				self.rewards:SetPoint("LEFT", self.title, "RIGHT", 8, 8)
				self.subRewards:SetPoint("TOPLEFT", self.rewards, "BOTTOMLEFT", 0, 8)
			end
		else
			if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
				self.subRewards:SetPoint("TOP", self.title, "BOTTOM", 0, -12)
			elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
				self.rewards:SetPoint("TOP", self.title, "BOTTOM", 0, -12)
			else
				self.rewards:SetPoint("TOP", self.title, "BOTTOM", 0, -4)
				self.subRewards:SetPoint("TOP", self.rewards, "BOTTOM", 0, 8)
			end
		end

	end

	function frame:LoadData(data)
		self.remainingCompletions = data.remainingCompletions or 0

		--[[if (self.name) then
			self.title:SetText(self.name.." |cffFFFFFF("..self.remainingCompletions..")")
		end]]--

		if (self.isSubCategory) then
			self.completeFrame:SetUp(data.moneyCost, data.tokenCost, self.category, self.remainingCompletions, data.minimumLevel, nil, data.remainingCompletions)
		else
			self.completeFrame:SetUp(data.moneyCost, data.tokenCost, self.category, -1, data.minimumLevel)
		end

		self:LoadRewards(data.rewards)

		-- hide visible categories if 0 completions available
		if not(self.isSubCategory) or (self:IsVisible()) then
			if (self:CompletionsCheck()) then
				self:Show()
				return true
			else
				self:Hide()
				return false
			end
		end
	end

	function frame:LoadCategory(category)
		-- TODO: Move icons to atlases
		-- PVE
		if (category == CallBoardUI.categories.pve) then
			self.categoryIcon:SetTexCoord(0.60156, 0.71875, 0.59765, 0.745117)
			self.categoryIcon:SetSize(38.4, 48.32)
		-- PVP 
		elseif (category == CallBoardUI.categories.pvp) then
			self.categoryIcon:SetTexCoord(0.7167, 0.8339, 0.59765, 0.745117)
			self.categoryIcon:SetSize(38.4, 48.32)
		-- PROF
		elseif (category == CallBoardUI.categories.prof) then
			self.categoryIcon:SetTexCoord(0.8339, 0.9511, 0.59765, 0.745117)
			self.categoryIcon:SetSize(38.4, 48.32)
		-- HIGH RISK
		elseif (category == CallBoardUI.categories.highRisk) then
			self.categoryIcon:SetTexCoord(0.88281, 1, 0.4394, 0.58691)
			self.categoryIcon:SetSize(38.4, 48.32)
		else -- hide icon
			self.categoryIcon:SetTexCoord(0.86035, 0.980, 0.29199, 0.42480)
			self.categoryIcon:SetSize(33.21, 36.72)
		end

		self.category = category
	end

	function frame:ShowSubTabs(nextTab)
		for _, subTab in pairs(self.subTabs) do
			if subTab:CompletionsCheck() then
				subTab:Show()
			end
		end
		
		if (nextTab) then
			nextTab:ClearAllPoints()
			nextTab:SetPoint("TOP", self.lastSubTab, "BOTTOM", 0, -1)
		end

		self.subTabsAreVisible = true
	end

	function frame:HideSubTabs(nextTab)
		for _, subTab in pairs(self.subTabs) do
			subTab:Hide()
		end

		if (nextTab) then
			nextTab:ClearAllPoints()
			nextTab:SetPoint("TOP", self, "BOTTOM", 0, -1)
		end

		self.subTabsAreVisible = false
	end

	function frame:Minimize()
		self:SetHeight(0.01)
	end

	function frame:Restore()
		self:SetHeight(self.normalHeight)
	end

	function frame:CompletionsCheck()
		if not(self.remainingCompletions) or (self.remainingCompletions == 0) then
			self:Minimize()
			return false
		else
			self:Restore()
			return true
		end
	end

	function frame:ApplyCategoryRewardsToTooltip(frame, category)
		if self.isSubCategory then
			return
		end

		CallBoardUI:ApplyCategoryRewardsToTooltip(frame, category)
	end

	frame.completeFrame.completeForTokenButton:HookScript("OnEnter", function(self) 
		frame:ApplyCategoryRewardsToTooltip(frame.completeFrame.completeForTokenButton, frame.category)
	end)

	frame.completeFrame.completeForGoldButton:HookScript("OnEnter", function(self) 
		frame:ApplyCategoryRewardsToTooltip(frame.completeFrame.completeForTokenButton, frame.category)
	end)

	frame:SetScript("OnClick", function(self)
		self:GetParent():SelectTab(self)
	end)

	frame:HookScript("OnEnter", function(self)
		Addon.SharedGossip:OnEnterDisplayTooltip(self)
	end)

	frame:HookScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return frame
end

function CallBoardUI:CreateSlot(name, parent)
	local btn = CreateFrame("BUTTON", "$parent."..name, parent, nil)
	self.buttonIndex = 0
	self.isActive = false

	btn:SetSize(268, 96)

	btn.bg = btn:CreateTexture(nil, "BACKGROUND")
	btn.bg:SetTexture("Interface\\callboard\\atlas")
	btn.bg:SetSize(276.3, 98)
	btn.bg:SetPoint("CENTER")
	btn.bg:SetTexCoord(0, 0.59960937, 0, 0.21289)

	btn.bg.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas", texCoord = {0, 0.59960937, 0.2128, 0.42578}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		["DISABLE"] = {tex = "Interface\\callboard\\atlas", texCoord = {0, 0.59960937, 0, 0.21289}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.pve] = {tex = "Interface\\callboard\\atlas_2", texCoord = {0, 0.59960937, 0.6386, 0.8515}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.pvp] = {tex = "Interface\\callboard\\atlas_2", texCoord = {0, 0.59960937, 0.42578, 0.6386}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.prof] = {tex = "Interface\\callboard\\atlas_2", texCoord = {0, 0.59960937, 0, 0.21289}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
	}

	btn.shieldFrame = CallBoardUI:CreateQuestShield(shieldFrame, btn)
	btn.shieldFrame:SetPoint("LEFT")

	btn.shieldShadow = btn:CreateTexture(nil, "BORDER")
	btn.shieldShadow:SetAtlas("spellbook-text-background", Const.TextureKit.IgnoreAtlasSize)
	btn.shieldShadow:SetSize(334, 60)
	btn.shieldShadow:SetPoint("LEFT", btn.shieldFrame, "RIGHT", -16, 0)

	btn.shieldFrame.categoryIcon.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas", texCoord = {0, 0, 0,0}, size = {1, 1}, point = {"CENTER", btn.shieldFrame.Shield, 0, 4}}, -- no icon
		[CallBoardUI.categories.pve] = {tex = "Interface\\callboard\\atlas", texCoord = {0.60156, 0.71875, 0.59765, 0.745117}, size = {38.4, 48.32}, point = {"CENTER", btn.shieldFrame.Shield, 0, 4}},
		[CallBoardUI.categories.pvp] = {tex = "Interface\\callboard\\atlas", texCoord = {0.7167, 0.8339, 0.59765, 0.745117}, size = {38.4, 48.32}, point = {"CENTER", btn.shieldFrame.Shield, 0, 4}},
		[CallBoardUI.categories.prof] = {tex = "Interface\\callboard\\atlas", texCoord = {0.8339, 0.9511, 0.59765, 0.745117}, size = {38.4, 48.32}, point = {"CENTER", btn.shieldFrame.Shield, 0, 4}},
		[CallBoardUI.categories.highRisk] = {tex = "Interface\\callboard\\atlas", texCoord = {0.88281, 1, 0.4394, 0.58691}, size = {38.4, 48.32}, point = {"CENTER", btn.shieldFrame.Shield, 0, 4}},
	}

	btn.fontString = btn:CreateFontString(nil, "OVERLAY")
	btn.fontString:SetFontObject(GameFontHighlightMedium)
	btn.fontString:SetPoint("LEFT", btn.shieldFrame, "RIGHT", 8, 0)
	btn.fontString:SetText("Exquistie Crafts: Scroll of Enchant Weapon - Unstoppable Assault (Epic)")
	btn.fontString:SetWidth(182)
	btn.fontString:SetJustifyH("LEFT")
	btn.fontString:SetJustifyV("CENTER")
	--btn.fontString:SetHeight(64)
	btn.fontString:SetVertexColor(0.10, 0.05, 0.0, 1)
	btn.fontString:SetShadowOffset(0, 0)
	btn.fontString:Hide()

	btn.highlightTexture = btn:CreateTexture(nil, "BORDER")
	btn.highlightTexture:SetTexture("Interface\\callboard\\atlas")
	btn.highlightTexture:SetTexCoord(0, 0.59960937, 0.5996, 0.8125)
	btn.highlightTexture:SetSize(276.3, 98)
	btn.highlightTexture:SetPoint("CENTER")
	btn.highlightTexture:SetBlendMode("ADD")

	btn.pushedTexture = btn:CreateTexture(nil, "BACKGROUND")
	btn.pushedTexture:SetTexture("Interface\\callboard\\atlas_2")
	btn.pushedTexture:SetTexCoord(0, 0.59960937, 0.2128, 0.42578)
	btn.pushedTexture:SetSize(276.3, 98)
	btn.pushedTexture:SetPoint("CENTER")
	btn.pushedTexture:Hide()

	btn.pushedTexture.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_2", texCoord = {0, 0.59960937, 0.2128, 0.42578}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.pve] = {tex = "Interface\\callboard\\atlas_3", texCoord = {0, 0.59960937, 0.2128, 0.42578}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.pvp] = {tex = "Interface\\callboard\\atlas_3", texCoord = {0, 0.59960937, 0, 0.21289}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
		[CallBoardUI.categories.prof] = {tex = "Interface\\callboard\\atlas_3", texCoord = {0, 0.59960937, 0.42578, 0.6386}, size = {98, 276.3}, point = {"CENTER", 0, 0}},
	}

	btn:SetHighlightTexture(btn.highlightTexture)

	btn.editableTextures = {btn.pushedTexture, btn.bg, btn.shieldFrame.categoryIcon}

	function btn:LoadCategory(category)
		category = category or "DEFAULT"

		self.category = category

		for _, tex in pairs(self.editableTextures) do
			local categoryData = tex.categories[category]

			if not(categoryData) then
				categoryData = tex.categories["DEFAULT"]
			end

			if (categoryData.tex) then
				tex:SetTexture(categoryData.tex)
			end

			if (categoryData.size) then
				tex:SetSize(unpack(categoryData.size))
			end

			if (categoryData.texCoord) then
				tex:SetTexCoord(unpack(categoryData.texCoord))
			end

			if (categoryData.point) then
				tex:SetPoint(unpack(categoryData.point))
			end
		end
	end

	function btn:Clear()
		self.ID = nil
		self.shieldFrame:Hide()
		self.fontString:Hide()
		self:LoadCategory("DISABLE")
		self:Disable()
	end

	function btn:SetComplete(daily)
		self.shieldFrame:SetComplete(daily)
	end

	function btn:SetAvailable(daily)
		self.shieldFrame:SetAvailable(daily)
	end

	function btn:SetActive(daily)
		self.shieldFrame:SetActive(daily)
	end

	function btn:SetQuest(ID, name, isDaily, buttonIndex, isActive, isComplete, category)
		self.shieldFrame:Show()
		self.fontString:Show()
		self.fontString:SetText(name)

		self.buttonIndex = buttonIndex
		self.isActive = isActive
		self.isComplete = isComplete

		self.daily = isDaily
		
		if (isComplete) then
			self:SetComplete(isDaily)
		elseif (self.isActive) then
			self:SetActive(isDaily)
		else
			self:SetAvailable(isDaily)
		end

		self:Enable()
		self:LoadCategory(category)

		if (ID) then 
			self.ID = ID
		else
			dprint(self:GetParent():GetName()..": ERROR. No ID found for quest "..name)
		end
	end

	btn.UpdateTooltip = function(self)
		self:GetScript("OnEnter")(self)
	end

	btn:SetScript("OnClick", function(self)
		if (self:IsEnabled() == 1) then
			if not(self.ID) then
				return
			end

			
			if self.isComplete then
				-- safe check. Make sure isComplete matches with GetCompleteGossipQuestIds
				for _, questID in pairs(CallBoardUI.CompleteGossipQuestIDs) do
					if (questID == self.ID) then
						CompleteActiveGossipQuest(self.ID)
						return
					end
				end
			elseif not(self.isActive) then
				AcceptAvailableGossipQuest(self.ID)
				return
			else
				local questLogIndex = GetQuestLogIndexByID(self.ID)
				if not(questLogIndex) or (questLogIndex == 0) then -- quest is Active, but not in quest log. Means we can complete it anytime
					SelectGossipActiveQuest(self.buttonIndex)
				else -- quest is active but not completed. Just say its not complete yet
					StaticPopup_GenericError(CallBoardUI.MSGS.QUEST_IS_ACTIVE_ERROR)
				end
				return
			end

			if (self.isActive) then
				SelectGossipActiveQuest(self.buttonIndex)
			else
				SelectGossipAvailableQuest(self.buttonIndex)
			end
		end
	end)

	btn:SetScript("OnMouseDown", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end

		self.bg:Hide()
		self.pushedTexture:Show()
		self.shieldFrame:SetPoint("LEFT", -2, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end

		self.bg:Show()
		self.pushedTexture:Hide()
		self.shieldFrame:SetPoint("LEFT")
	end)

	btn:SetScript("OnEnter", function(self)
		if (self.ID) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
			GameTooltip:SetHyperlink("quest:"..self.ID)
			GameTooltip:Show()

			TooltipAddQuestRewards(self, self.ID)
		end
	end)

	btn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return btn
end

function CallBoardUI:CreateExtendedSlot(name, parent)
	local btn = CallBoardUI:CreateSlot(name, parent)
	btn:SetSize(572, 96)

	btn.bg_left = btn:CreateTexture(nil, "BACKGROUND") -- left
	btn.bg_left:SetTexture("Interface\\callboard\\atlas_4")
	btn.bg_left:SetSize(213.3, 196.2)
	btn.bg_left:SetPoint("LEFT")
	btn.bg_left:SetTexCoord(0, 0.22614, 0, 0.21289)

	btn.bg_right = btn:CreateTexture(nil, "BACKGROUND") -- right
	btn.bg_right:SetTexture("Interface\\callboard\\atlas_4")
	btn.bg_right:SetSize(184.5, 196.2)
	btn.bg_right:SetPoint("RIGHT")
	btn.bg_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)

	btn.bg:ClearAllPoints()
	btn.bg:SetPoint("TOPLEFT", btn.bg_left, "TOPRIGHT", 0, 0)
	btn.bg:SetPoint("BOTTOMRIGHT", btn.bg_right, "BOTTOMLEFT", 1, 0)

	btn.highlightTexture_left = btn:CreateTexture(nil, "OVERLAY") -- left
	btn.highlightTexture_left:SetTexture("Interface\\callboard\\atlas_5")
	btn.highlightTexture_left:SetSize(213.3, 196.2)
	btn.highlightTexture_left:SetPoint("LEFT")
	btn.highlightTexture_left:SetTexCoord(0, 0.22614, 0, 0.21289)
	btn.highlightTexture_left:SetBlendMode("ADD")
	btn.highlightTexture_left:Hide()

	btn.highlightTexture_right = btn:CreateTexture(nil, "OVERLAY") -- right
	btn.highlightTexture_right:SetTexture("Interface\\callboard\\atlas_5")
	btn.highlightTexture_right:SetSize(184.5, 196.2)
	btn.highlightTexture_right:SetPoint("RIGHT")
	btn.highlightTexture_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)
	btn.highlightTexture_right:SetBlendMode("ADD")
	btn.highlightTexture_right:Hide()

	btn.highlightTexture:ClearAllPoints()	
	btn.highlightTexture:SetPoint("TOPLEFT", btn.highlightTexture_left, "TOPRIGHT", 0, 0)
	btn.highlightTexture:SetPoint("BOTTOMRIGHT", btn.highlightTexture_right, "BOTTOMLEFT", 1, 0)
	btn.highlightTexture:SetBlendMode("ADD")

	btn:SetHighlightTexture(btn.highlightTexture)

	btn.pushed_left = btn:CreateTexture(nil, "BACKGROUND") -- left
	btn.pushed_left:SetTexture("Interface\\callboard\\atlas_8")
	btn.pushed_left:SetSize(106.2, 98)
	btn.pushed_left:SetPoint("LEFT")
	btn.pushed_left:SetTexCoord(0, 0.22614, 0, 0.21289)
	btn.pushed_left:Hide()

	btn.pushed_right = btn:CreateTexture(nil, "BACKGROUND") -- right
	btn.pushed_right:SetTexture("Interface\\callboard\\atlas_8")
	btn.pushed_right:SetSize(92.25, 98)
	btn.pushed_right:SetPoint("RIGHT")
	btn.pushed_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)
	btn.pushed_right:Hide()

	btn.pushedTexture:ClearAllPoints()
	btn.pushedTexture:SetPoint("TOPLEFT", btn.pushed_left, "TOPRIGHT", 0, 0)
	btn.pushedTexture:SetPoint("BOTTOMRIGHT", btn.pushed_right, "BOTTOMLEFT", 1, 0)
	btn.pushedTexture:SetTexture("Interface\\callboard\\atlas_8")
	btn.pushedTexture:SetTexCoord(0, 0.5654, 0.425781, 0.638671)

	btn.fontString:ClearAllPoints()
	btn.fontString:SetFontObject(GameFontHighlightLarge)
	btn.fontString:SetPoint("LEFT", btn.shieldFrame, "RIGHT", 4, 0)
	btn.fontString:SetJustifyH("LEFT")
	btn.fontString:SetJustifyV("CENTER")
	btn.fontString:SetVertexColor(1, 0.82, 0, 1)
	btn.fontString:SetShadowOffset(1, -1)
	btn.fontString:SetWidth(192)

	btn.completeFrame = CallBoardUI:CreateAutoCompleteFrame("completeFrame", btn)
	btn.completeFrame:SetPoint("RIGHT", -14, 0)

	btn.rewards = CallBoardUI:CreateItemRewardsFrame("rewards", btn, 4)
	btn.rewards:SetPoint("LEFT", btn.fontString, "RIGHT", 24, 0)
	btn.rewards:SetJustifyH("LEFT")

	btn.subRewards = CallBoardUI:CreateSubRewardsFrame("subRewards", btn)
	btn.subRewards:SetPoint("TOPLEFT", btn.rewards, "BOTTOMLEFT")
	btn.subRewards:SetJustifyH("LEFT")

	btn.bg.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_6", texCoord = {0, 0.5654, 0.425781, 0.638671}},
		["DISABLE"] = {tex = "Interface\\callboard\\atlas_4", texCoord = {0, 0.5654, 0.425781, 0.638671}},
	}

	btn.bg_left.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_6", texCoord = {0, 0.22614, 0, 0.21289}, size = {106.65, 98}, point = {"LEFT"}},
		["DISABLE"] = {tex = "Interface\\callboard\\atlas_4", texCoord = {0, 0.22614, 0, 0.21289}, size = {94.8, 87.2}, point = {"LEFT"}},
	}

	btn.bg_right.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_6", texCoord = {0, 0.2001, 0.21289, 0.42578}, size = {92.25, 98}, point = {"RIGHT"}},
		["DISABLE"] = {tex = "Interface\\callboard\\atlas_4", texCoord = {0, 0.2001, 0.21289, 0.42578}, size = {82.0, 87.2}, point = {"RIGHT"}},
	}

	btn.highlightTexture.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_5", texCoord = {0, 0.5654, 0.425781, 0.638671}},
	}

	btn.highlightTexture_left.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_5", texCoord = {0, 0.22614, 0, 0.21289}, size = {106.65, 98}, point = {"LEFT"}},
	}

	btn.highlightTexture_right.categories = {
		["DEFAULT"] = {tex = "Interface\\callboard\\atlas_5", texCoord = {0, 0.2001, 0.21289, 0.42578}, size = {92.25, 98}, point = {"RIGHT"}},
	}

	btn.editableTextures = {
		btn.bg, 
		btn.bg_left, 
		btn.bg_right, 
		btn.shieldFrame.categoryIcon, 
		btn.highlightTexture, 
		btn.highlightTexture_left, 
		btn.highlightTexture_right,
	}

	btn._Clear = btn.Clear

	function btn:Clear()
		self:_Clear()
		self.rewards:LoadRewards(nil)
	end

	function btn:LoadRewards()
		if not(self.ID) then
			dprint(self:GetName().." ID for button not found")
			return
		end

		local rewards = GetQuestRewards(self.ID)

		if not(rewards) or not(next(rewards)) then
			rewards = CallBoardUI.questRewards[self.ID]
		end

		if not(rewards) or not(next(rewards)) then
			dprint(self:GetName().." rewards for quest "..self.ID.." not found yet")
			return
		end
		
		local cacheProgress = C_CallboardCache.GetPointsForQuest(self.ID)
		if cacheProgress and cacheProgress > 0 then
			rewards.CacheProgress = cacheProgress
		else
			rewards.CacheProgress = nil
		end

		self.rewards:LoadRewards(rewards)
		self.subRewards:LoadRewards(rewards)

		self.subRewards:ClearAllPoints()
		self.rewards:ClearAllPoints()

		if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
			self.subRewards:SetPoint("LEFT", self.fontString, "RIGHT", 24, 0)
		elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
			self.rewards:SetPoint("LEFT", self.fontString, "RIGHT", 24, 0)
		else
			self.rewards:SetPoint("LEFT", self.fontString, "RIGHT", 24, 8)
			self.subRewards:SetPoint("TOPLEFT", self.rewards, "BOTTOMLEFT", 0, 8)
		end
	end

	function btn:SetUpCompleteFrame(ID, remainingCompletions)
		if not(ID) then
			self.completeFrame:Hide()
		end

		local tokenCost, moneyCost, categoryData

		categoryData, subCategory = CallBoardUI:GetCategoryQuestData(ID)

		if not(categoryData) then
			self.completeFrame:Hide()
			return
		end

		if (categoryData) then
			local count = remainingCompletions or 1
			if count < 1 then count = 1 end
			tokenCost = math.floor(categoryData.tokenCost / count)
			moneyCost = math.floor(categoryData.moneyCost / count)
		end

		self.completeFrame:SetUp(moneyCost, tokenCost, subCategory, 1, nil, nil, remainingCompletions)
	end

	btn._SetQuest = btn.SetQuest

	function btn:SetQuest(ID, name, isDaily, buttonIndex, isActive, isComplete, category, remainingCompletions)
		self:_SetQuest(ID, name, isDaily, buttonIndex, isActive, isComplete, category, remainingCompletions)

		self:LoadRewards()

		self:SetUpCompleteFrame(ID, remainingCompletions)
	end

	btn:HookScript("OnEnter", function(self)
		if self.category ~= "DISABLE" then
			self.highlightTexture:Show()
			self.highlightTexture_right:Show()
			self.highlightTexture_left:Show()
		end
	end)

	btn:HookScript("OnLeave", function(self)
		self.highlightTexture:Hide()
		self.highlightTexture_right:Hide()
		self.highlightTexture_left:Hide()
	end)

	btn:HookScript("OnMouseDown", function(self)
		self.bg_left:Hide()
		self.bg_right:Hide()
		self.pushed_right:Show()
		self.pushed_left:Show()
	end)

	btn:HookScript("OnMouseUp", function(self)
		self.bg_left:Show()
		self.bg_right:Show()
		self.pushed_right:Hide()
		self.pushed_left:Hide()
	end)

	return btn
end

function CallBoardUI:CreateExpandedCategory(name, parent)
	local btn = CallBoardUI:CreateExtendedSlot(name, parent)

	btn:SetWidth(772)

	btn.icon = btn:CreateTexture(nil, "ARTWORK")
	btn.icon:SetTexture("Interface\\Icons\\Achievement_Zone_AlteracMountains_01")
	btn.icon:SetSize(42, 42)
	btn.icon:SetPoint("LEFT", 24, 0)

	btn.iconBorder = btn:CreateTexture(nil, "OVERLAY")
	btn.iconBorder:SetTexture("Interface\\callboard\\atlas_4")
	btn.iconBorder:SetSize(90, 90)
	btn.iconBorder:SetPoint("CENTER", btn.icon, 0, 0)
	btn.iconBorder:SetTexCoord(0.65917, 1, 0, 0.336914)

	btn.title = btn:CreateFontString(nil)
	btn.title:SetFontObject(GameFontHighlightLarge)
	btn.title:SetPoint("LEFT", btn.icon, "RIGHT", 16, 0)
	btn.title:SetText("Area Name")
	btn.title:SetVertexColor(1, 0.82, 0, 1)
	btn.title:SetJustifyH("LEFT")
	btn.title:SetWidth(500)

	btn.completeFrame:Hide()

	function btn:SetSubCategory(name, quests)
		self.name = name
		self.quests = quests
		self.title:SetText(name)
		self:LoadCategory(CallBoardUI.content.ExtraSlotsCategorized.category)
		self:LoadRewards()
		self.rewards:Show()
		self:Enable()

		local contractMapInfo = CallBoardUI.TemporalContractsMap[CallBoardUI.content.ExtraSlotsCategorized.category] and CallBoardUI.TemporalContractsMap[CallBoardUI.content.ExtraSlotsCategorized.category][name]

		if contractMapInfo then
			self.title:SetText("|cffFFFFFF"..CallBoardUI:GetSubCategoryName(self.name))

			if self.quests[1] and self.quests[1].remainingCompletions then
				self.title:SetText(self.title:GetText().."\n|rRemaining Completions: |cffFFFFFF"..self.quests[1].remainingCompletions.."|r")
			end
		end
	end

	function btn:LoadRewards()
		if not(self.quests) then
			dprint(self:GetName().." ID for button not found")
			return
		end

		local rewardsCombined = {}

		for _, quest in pairs(self.quests) do
			local rewards = GetQuestRewards(quest.ID)

			if not(rewards) or not(next(rewards)) then
				rewards = CallBoardUI.questRewards[self.ID]
			end

			table.insert(rewardsCombined, rewards)
		end

		rewardsCombined = CallBoardUI:CombineRewards(rewardsCombined)

		self.rewards:LoadRewards(rewardsCombined)
		self.subRewards:LoadRewards(rewardsCombined)

		self.subRewards:ClearAllPoints()
		self.rewards:ClearAllPoints()

		if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
			self.subRewards:SetPoint("RIGHT", -24, 0)
		elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
			self.rewards:SetPoint("RIGHT", -24, 0)
		else
			self.rewards:SetPoint("RIGHT", -24, 8)
			self.subRewards:SetPoint("TOPLEFT", self.rewards, "BOTTOMLEFT", 0, 8)
		end
	end

	return btn
end

function CallBoardUI:CreateQuestSlotCategorized(name, parent)
	local btn = CallBoardUI:CreateExtendedSlot(name, parent)

	btn.shieldFrame:SetScale(0.7)
	btn:SetSize(356, 65)

	btn.editableTextures = {
		btn.bg_left, 
		btn.bg_right, 
		btn.shieldFrame.categoryIcon, 
	}

	btn.highlightTexture:ClearAllPoints()
	btn.highlightTexture:SetAllPoints()
	btn.highlightTexture:SetAtlas("search-highlight-large")
	btn.highlightTexture_left:Hide()
	btn.highlightTexture_right:Hide()

	btn.bg_left:Hide()
	btn.bg_right:Hide()

	btn.bg:ClearAllPoints()
	btn.bg:SetAllPoints()
	btn.bg:SetTexture(1, 1, 1, 0.05)
	btn.bg:SetBlendMode("ADD")
	btn.bg:Hide()

	btn.fontString:ClearAllPoints()
	btn.fontString:SetPoint("LEFT", btn.shieldFrame, "RIGHT", 6, 0)
	btn.fontString:SetWidth(140)

	btn.rewards:SetJustifyH("RIGHT")
	btn.subRewards:SetJustifyH("RIGHT")

	--[[btn.rewards:SetBackdrop(GameTooltip:GetBackdrop())
	btn.subRewards:SetBackdrop(GameTooltip:GetBackdrop())
	btn.subRewards:SetBackdrop(GameTooltip:GetBackdrop())]]--

	--btn.completeFrame:SetBackdrop(GameTooltip:GetBackdrop())
	btn.completeFrame:SetScale(0.72)
	btn.completeFrame.banner:Show()
	btn.completeFrame.totalCompletionsIcon:Hide()
	btn.completeFrame.totalCompletionsText:Hide()
	btn.completeFrame.totalCompletionsIconBG:Hide()
	btn.completeFrame.titleCompleteButtons:Show()
	btn.completeFrame.shadowBG:Hide()

	btn.completeFrame:ClearAllPoints()
	btn.completeFrame:SetPoint("RIGHT", -8, 0)

	btn.completeFrame.titleCompleteButtons:ClearAllPoints()
	btn.completeFrame.titleCompleteButtons:SetPoint("CENTER", 0, 12)
	btn.completeFrame.titleCompleteButtons:SetFontObject(GameFontNormalSmall)

	btn.completeFrame.completeForGoldButton:ClearAllPoints()
	btn.completeFrame.completeForGoldButton:SetPoint("LEFT", btn.completeFrame, "CENTER", 1, -12)

	btn.completeFrame.completeForTokenButton:ClearAllPoints()
	btn.completeFrame.completeForTokenButton:SetPoint("RIGHT", btn.completeFrame, "CENTER", -1, -12)

	function btn.completeFrame:LoadCompletions(remainingCompletions)
		if (remainingCompletions) then
			self.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP_FULL
		else
			self.tooltipText = CallBoardUI.MSGS.COMPLETE_WITH_TOOLTIP
		end
	end

	btn:SetScript("OnEnter", function(self)
		if (self.ID) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
			GameTooltip:SetHyperlink("quest:"..self.ID)
			GameTooltip:Show()

			TooltipAddQuestRewards(self, self.ID)
		end
	end)

	btn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	btn:SetScript("OnMouseDown", function(self)
		self.shieldFrame:SetPoint("LEFT", -2, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.shieldFrame:SetPoint("LEFT")
	end)

	local _LoadRewards = btn.LoadRewards

	function btn:LoadRewards(...)
		_LoadRewards(btn, ...)

		if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
			self.subRewards:ClearAndSetPoint("RIGHT", self.completeFrame, "LEFT", -12, 0)
		elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
			self.rewards:ClearAndSetPoint("RIGHT", self.completeFrame, "LEFT", -12, 0)
		else
			self.rewards:ClearAndSetPoint("RIGHT", self.completeFrame, "LEFT", -12, 8)
			self.subRewards:ClearAndSetPoint("TOPLEFT", self.rewards, "BOTTOMLEFT", 0, 8)
		end
	end

	return btn
end

function CallBoardUI:CreateTab(name, parent)
	local btn = Addon.SharedGossip:CreateTab(name, parent)

	function btn:CreateSubTabs()
		self.subTabs = {}

		function self:ShowSubTabs(nextTab)
			for i = 1, #self.subTabs do
				self.subTabs[i]:Show()
			end
			
			if (nextTab) then
				nextTab:SetPoint("TOP", self.subTabs[#self.subTabs], "BOTTOM", 0, -1)
			end
		end

		function self:HideSubTabs(nextTab)
			for _, self in pairs(self.subTabs) do
				self:Hide()
			end

			if (nextTab) then
				nextTab:SetPoint("TOP", self, "BOTTOM", 0, -1)
			end
		end

	end

	btn:SetScript("OnClick", function(self, ...)
		CallBoardUI:SelectTab(self:GetParent(), self)
		CallBoardUI:ClickGossipOptionOrGoBackAndSetDelayed(self)
	end)

	return btn
end

function CallBoardUI:CreateSubTab(name, parent, mainTab)
	local btn = CallBoardUI:CreateTab(name, parent)
	btn:Hide()

	table.remove(parent.tabs, #parent.tabs)

	btn:SetSize(180, 39)
	btn.highlight:SetSize(176, 36)
	btn.checked:SetSize(176, 36)
	btn.bg:SetSize(180, 39)
	btn.icon:Hide()
	btn.iconBorder:Hide()
	btn.text:ClearAllPoints()
	btn.text:SetPoint("LEFT", 12, 3)

	btn.bg:SetVertexColor(0.6, 0.6, 0.6)

	function btn:Enable()
		self.disabled = false
		self.bg:SetDesaturated(false)
		self.text:SetFontObject(GameFontNormal)
	end

	function btn:Disable()
		self.disabled = true
		self.bg:SetDesaturated(true)
		self.text:SetFontObject(GameFontDisable)
	end

	btn:SetScript("OnMouseDown", function(self)
		self.text:SetPoint("LEFT", 13, 1)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.text:SetPoint("LEFT", 12, 3)
	end)

	btn:SetScript("OnClick", function(self, ...) -- TODO: Set up for each specific tab
	end)

	if not(mainTab.subTabs) then
		mainTab:CreateSubTabs()
	end

	table.insert(mainTab.subTabs, btn)

	return btn
end

function CallBoardUI:CreateTotalRewardsFrame(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent, "InsetFrameTemplate")
	frame:SetSize(parent:GetWidth(), 96)

	frame:Hide()

	frame.controlFrame = CreateFrame("FRAME", "$parent.controlFrame", frame, nil)
	frame.controlFrame:SetHeight(22)
	frame.controlFrame:SetWidth(frame:GetWidth())
	frame.controlFrame:SetPoint("TOP", frame, "BOTTOM", 0, 0)

	frame.controlFrame.bg = frame.controlFrame:CreateTexture()
	frame.controlFrame.bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock", "MIRROR", "MIRROR")
	frame.controlFrame.bg:SetHorizTile(true)
	frame.controlFrame.bg:SetVertTile(true)
	frame.controlFrame.bg:SetAllPoints()

	frame.controlFrame.buttonAccept = CreateFrame("Button", "$parent.buttonAccept", frame, "StaticPopupButtonTemplate")
	frame.controlFrame.buttonAccept:SetText(CallBoardUI.MSGS.ACCEPT_ALL_QUESTS)
	frame.controlFrame.buttonAccept:SetPoint("RIGHT", frame.controlFrame, "CENTER", 0, 0)
	frame.controlFrame.buttonAccept:GetFontString():SetDrawLayer("OVERLAY")
	frame.controlFrame.buttonAccept:SetWidth(185)
	frame.controlFrame.buttonAccept:SetHeight(22)
	MagicButton_OnLoad(frame.controlFrame.buttonAccept)

	frame.controlFrame.buttonAccept:SetScript("OnClick", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end
		
		AcceptAllAvailableGossipQuests()
	end)

	frame.controlFrame.buttonComplete = CreateFrame("Button", "$parent.buttonComplete", frame, "StaticPopupButtonTemplate")
	frame.controlFrame.buttonComplete:SetText(CallBoardUI.MSGS.TURN_IN_ALL_QUESTS)
	frame.controlFrame.buttonComplete:SetPoint("LEFT", frame.controlFrame, "CENTER", 0, 0)
	frame.controlFrame.buttonComplete:GetFontString():SetDrawLayer("OVERLAY")
	frame.controlFrame.buttonComplete:SetWidth(185)
	frame.controlFrame.buttonComplete:SetHeight(22)
	MagicButton_OnLoad(frame.controlFrame.buttonComplete)

	frame.controlFrame.buttonComplete:SetScript("OnClick", function(self)
		if (self:IsEnabled() ~= 1) then
			return
		end
		
		CompleteAllActiveGossipQuests()
	end)

	frame.bottom_bg_left = frame:CreateTexture(nil, "BORDER") -- left
	frame.bottom_bg_left:SetTexture("Interface\\callboard\\atlas_7")
	frame.bottom_bg_left:SetSize(109, 111.18)
	frame.bottom_bg_left:SetPoint("LEFT", -6, 0)
	frame.bottom_bg_left:SetTexCoord(0, 0.22614, 0, 0.21289)

	frame.bottom_bg_right = frame:CreateTexture(nil, "BORDER") -- right
	frame.bottom_bg_right:SetTexture("Interface\\callboard\\atlas_7")
	frame.bottom_bg_right:SetSize(94.3, 111.18)
	frame.bottom_bg_right:SetPoint("RIGHT", 6, 0)
	frame.bottom_bg_right:SetTexCoord(0, 0.2001, 0.21289, 0.42578)

	frame.bottom_bg = frame:CreateTexture(nil, "BORDER") -- left
	frame.bottom_bg:SetTexture("Interface\\callboard\\atlas_7")
	frame.bottom_bg:SetTexCoord(0, 0.5654, 0.425781, 0.638671)
	frame.bottom_bg:SetPoint("TOPLEFT", frame.bottom_bg_left, "TOPRIGHT", 0, 0)
	frame.bottom_bg:SetPoint("BOTTOMRIGHT", frame.bottom_bg_right, "BOTTOMLEFT", 0, 0)

	-- artwork for to properly mix bottom frame and scroll for quests
	frame.cornerLeft = frame:CreateTexture(nil, "OVERLAY")
	frame.cornerLeft:SetAtlas("GeneralFrame-InsetFrame-BottomLeft", Const.TextureKit.UseAtlasSize)
	frame.cornerLeft:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")

	frame.cornerRight = frame:CreateTexture(nil, "OVERLAY")
	frame.cornerRight:SetAtlas("GeneralFrame-InsetFrame-BottomRight", Const.TextureKit.UseAtlasSize)
	frame.cornerRight:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -24, 0)

	frame.bottomLine = frame:CreateTexture(nil, "OVERLAY")
	frame.bottomLine:SetAtlas("_GeneralFrame-InsetFrame-Bottom", Const.TextureKit.UseAtlasSize)
	frame.bottomLine:SetPoint("LEFT", frame.cornerLeft, "RIGHT")
	frame.bottomLine:SetPoint("RIGHT", frame.cornerRight, "LEFT")

	frame.shadowBottom_Add = frame:CreateTexture(nil, "BORDER")
	frame.shadowBottom_Add:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
	frame.shadowBottom_Add:SetWidth(590)
	frame.shadowBottom_Add:SetHeight(64)
	frame.shadowBottom_Add:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
	frame.shadowBottom_Add:SetAlpha(1)

	frame.Shield = frame:CreateTexture(nil, "ARTWORK")
	frame.Shield:SetTexture("Interface\\callboard\\atlas")
	frame.Shield:SetTexCoord(1, 0.784, 0, 0.2783)
	frame.Shield:SetSize(49.5, 64.0)
	frame.Shield:SetPoint("LEFT", 14, 0)

	frame.categoryIcon = frame:CreateTexture(nil, "OVERLAY")
	frame.categoryIcon:SetTexture("Interface\\callboard\\atlas")
	frame.categoryIcon:SetTexCoord(0.60156, 0.71875, 0.59765, 0.745117)
	frame.categoryIcon:SetSize(32.4, 40.77)
	frame.categoryIcon:SetPoint("CENTER", frame.Shield, 0, 4)

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetWidth(573)
	frame.title:SetPoint("LEFT", frame.Shield, "RIGHT", 4, 0)
	frame.title:SetJustifyH("LEFT")

	frame.rewards = CallBoardUI:CreateItemRewardsFrame("rewards", frame)
	frame.rewards:SetPoint("CENTER", 0, -8)

	frame.subRewards = CallBoardUI:CreateSubRewardsFrame("subRewards", frame)
	frame.subRewards:SetPoint("TOP", frame.rewards, "BOTTOM", 0, 8)
	frame.subRewards:SetJustifyH("LEFT")

	frame.rewards.title = frame.rewards:CreateFontString(nil, "OVERLAY")
	frame.rewards.title:SetFontObject(GameFontNormal)
	frame.rewards.title:SetPoint("BOTTOM", frame.rewards, "TOP", 1, 8)
	frame.rewards.title:SetText(CallBoardUI.MSGS.TOTAL_REWARDS_AVAILABLE)

	frame.completeFrame = CallBoardUI:CreateAutoCompleteFrame("completeFrame", frame)
	frame.completeFrame:SetPoint("RIGHT", -24, 0)
	frame.completeFrame.banner:Hide()
	-- TODO: Properly recalculate sizes
	frame.completeFrame:SetScale(1.1)

	function frame:SetUpCompleteFrame(exceptions)
		local categoryData = CallBoardUI.TemporalContractsMap and CallBoardUI.TemporalContractsMap[self.category] and CallBoardUI.TemporalContractsMap[self.category]["TOTAL"]
		local costData = categoryData or {}

		if not(costData) then
			print(self:GetName(), "no cost data for CategoryType:",type(self.category), "Category:", self.category)
			return
		end

		self.completeFrame:SetUp(costData.moneyCost or 0, costData.tokenCost or 0, self.category, -1, false, exceptions)
	end

	function frame:LoadRewards(rewards)
		local rewardsCombined = CallBoardUI:CombineRewards(rewards)

		self.rewards:LoadRewards(rewardsCombined)
		self.subRewards:LoadRewards(rewardsCombined)

		self.rewards:ClearAllPoints()
		self.subRewards:ClearAllPoints()

		if not(self.rewards.totalRewards) or (self.rewards.totalRewards == 0) then
			self.subRewards:SetPoint("CENTER", 0, -8)
		elseif not(self.subRewards.totalRewards) or (self.subRewards.totalRewards == 0) then
			self.rewards:SetPoint("CENTER", 0, -8)
		else
			self.rewards:SetPoint("CENTER", 0, -4)
			self.subRewards:SetPoint("TOP", self.rewards, "BOTTOM", 0, 6)
		end
	end

	function frame:LoadCategory(category)
		self.category = category
		-- TODO: Move icons to atlases
		-- PVE
		if (category == CallBoardUI.categories.pve) then
			self.categoryIcon:SetTexCoord(0.60156, 0.71875, 0.59765, 0.745117)
			self.categoryIcon:SetSize(32.4, 40.77)
			self.bottom_bg_left:SetVertexColor(0.9, 1, 0)
			self.bottom_bg_right:SetVertexColor(0.9, 1, 0)
			self.bottom_bg:SetVertexColor(0.9, 1, 0)
		-- PVP 
		elseif (category == CallBoardUI.categories.pvp) then
			self.categoryIcon:SetTexCoord(0.7167, 0.8339, 0.59765, 0.745117)
			self.categoryIcon:SetSize(32.4, 40.77)
			self.bottom_bg_left:SetVertexColor(1, 0.4, 0.3)
			self.bottom_bg_right:SetVertexColor(1, 0.4, 0.3)
			self.bottom_bg:SetVertexColor(1, 0.4, 0.3)
		-- PROF
		elseif (category == CallBoardUI.categories.prof) then
			self.categoryIcon:SetTexCoord(0.8339, 0.9511, 0.59765, 0.745117)
			self.categoryIcon:SetSize(32.4, 40.77)
			self.bottom_bg_left:SetVertexColor(1, 0.6, 1)
			self.bottom_bg_right:SetVertexColor(1, 0.6, 1)
			self.bottom_bg:SetVertexColor(1, 0.6, 1)
		elseif (category == CallBoardUI.categories.highRisk) then
			self.categoryIcon:SetTexCoord(0.88281, 1, 0.4394, 0.58691)
			self.categoryIcon:SetSize(32.4, 40.77)
			self.bottom_bg:SetVertexColor(1, 0.8, 0)
			self.bottom_bg_left:SetVertexColor(1, 0.8, 0)
			self.bottom_bg_right:SetVertexColor(1, 0.8, 0)
		else -- misc
			self.categoryIcon:SetTexCoord(0.86035, 0.980, 0.29199, 0.42480)
			self.categoryIcon:SetSize(31.98, 35.36)
			self.bottom_bg:SetVertexColor(1, 1, 1)
			self.bottom_bg_left:SetVertexColor(1, 1, 1)
			self.bottom_bg_right:SetVertexColor(1, 1, 1)
		end
	end

	frame.completeFrame.completeForGoldButton:HookScript("OnEnter", function(self)
		CallBoardUI:ApplyCategoryRewardsToTooltip(self, frame.category)
	end)

	frame.completeFrame.completeForTokenButton:HookScript("OnEnter", function(self)
		CallBoardUI:ApplyCategoryRewardsToTooltip(self, frame.category)
	end)

	return frame
end
-------------------------------------------------------------------------------
--                                    UI                                     --
-------------------------------------------------------------------------------
CallBoardUI:SetSize(1024,702)
CallBoardUI:SetPoint("CENTER", 0, 0)
CallBoardUI:SetClampedToScreen(true)
CallBoardUI:RegisterForDrag("LeftButton")
CallBoardUI:SetScript("OnDragStart", CallBoardUI.StartMoving)
CallBoardUI:SetScript("OnDragStop", CallBoardUI.StopMovingOrSizing)
CallBoardUI:SetMovable(true)
CallBoardUI:EnableMouse(true)
SetPortraitToTexture(CallBoardUI.portrait, "Interface\\ICONS\\inv_inscription_81_contract_7thlegion")

-------------------------------------------------------------------------------
--                                   Tabs                                    --
-------------------------------------------------------------------------------
CallBoardUI.Tabs = Addon.SharedGossip:CreateTabMenuTemplate(CallBoardUI)
CallBoardUI.Tabs.Bg:SetTexture("Interface\\CallBoard\\bg_tiled", "MIRROR", "MIRROR")
CallBoardUI.Tabs:SetHeight(626)

CallBoardUI.Tabs.tabs = {}

CallBoardUI.Tabs.tabStatistics = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabStatistics", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabStatistics:SetPoint("TOP", 0, -4)
SetPortraitToTexture(CallBoardUI.Tabs.tabStatistics.icon, "Interface\\Icons\\INV_Chest_Awakening")
CallBoardUI.Tabs.tabStatistics.text:SetText(CallBoardUI.MSGS.STATISTICS)
CallBoardUI.Tabs.tabStatistics.menu = {"STATISTICS"}
CallBoardUI.Tabs.tabStatistics.tooltipTitle = CallBoardUI.MSGS.STATISTICS
CallBoardUI.Tabs.tabStatistics.tooltipText = CallBoardUI.MSGS.STATISTICS_TOOLTIP

CallBoardUI.Tabs.tabStatistics:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:UpdateContractsInfo()
	CallBoardUI:LoadRewards()
end)

CallBoardUI.Tabs.tabPVE = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabPVE", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabPVE:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabStatistics, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVE.icon:SetAtlas("questdaily", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.tabPVE.text:SetText(CallBoardUI.MSGS.PVE)
CallBoardUI.Tabs.tabPVE.gossipOption = "QUESTS_PVE"
CallBoardUI.Tabs.tabPVE.menu = {"SLOTS_EXTENDED_CATEGORIZED"}
CallBoardUI.Tabs.tabPVE.tooltipTitle = CallBoardUI.MSGS.PVE
CallBoardUI.Tabs.tabPVE.tooltipText = CallBoardUI.MSGS.PVE_TOOLTIP

CallBoardUI.Tabs.tabPVE:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:LoadExtraSlotsCategory(CallBoardUI.categories.pve)
end)


CallBoardUI.Tabs.tabPVERaidResets = CallBoardUI:CreateSubTab("CallBoardUI.Tabs.tabPVERaidResets", CallBoardUI.Tabs, CallBoardUI.Tabs.tabPVE)
CallBoardUI.Tabs.tabPVERaidResets:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVE, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVERaidResets.text:SetText(CallBoardUI.MSGS.RAID_RESETS)
CallBoardUI.Tabs.tabPVERaidResets.menu = "RAID_RESETS"
CallBoardUI.Tabs.tabPVERaidResets.tooltipTitle = CallBoardUI.MSGS.RAID_RESETS
CallBoardUI.Tabs.tabPVERaidResets.tooltipText = CallBoardUI.MSGS.RAID_RESETS_TOOLTIP

CallBoardUI.Tabs.tabPVERaidResets:SetScript("OnClick", function(self)
	CallBoardUI.content.raidResets:LoadSavedInstanceData()
	CallBoardUI.content.raidResets:RefreshLayout()
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:SelectMenu(self)
end)


CallBoardUI.Tabs.tabTimeWalking = CallBoardUI:CreateSubTab("CallBoardUI.Tabs.tabTimeWalking", CallBoardUI.Tabs, CallBoardUI.Tabs.tabPVE)
CallBoardUI.Tabs.tabTimeWalking:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVERaidResets, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabTimeWalking.text:SetText(CallBoardUI.MSGS.TIMEWALKING)
CallBoardUI.Tabs.tabTimeWalking.menu = "RAID_RESETS"
CallBoardUI.Tabs.tabTimeWalking.gossipOption = "BACK"
CallBoardUI.Tabs.tabTimeWalking.tooltipTitle = CallBoardUI.MSGS.TIMEWALKING
CallBoardUI.Tabs.tabTimeWalking.tooltipText = CallBoardUI.MSGS.TIMEWALKING_TOOLTIP

CallBoardUI.Tabs.tabTimeWalking:HookScript("OnClick", function(self)
	CallBoardUI:ClickGossipOptionOrGoBackAndSetDelayed(self)
	CallBoardUI.content.raidResets:LoadTimeWalkingData()
	CallBoardUI.content.raidResets:RefreshLayout()
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:SelectMenu(self)
end)

CallBoardUI.Tabs.tabPVP = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabPVP", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabPVP:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVE, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVP.icon:SetAtlas("questdaily", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.tabPVP.text:SetText(CallBoardUI.MSGS.PVP)
CallBoardUI.Tabs.tabPVP.tooltipTitle = CallBoardUI.MSGS.PVP
CallBoardUI.Tabs.tabPVP.tooltipText = CallBoardUI.MSGS.PVP_TOOLTIP

CallBoardUI.Tabs.tabPVP.gossipOption = "QUESTS_PVP"
CallBoardUI.Tabs.tabPVP.menu = {"SLOTS_EXTENDED_CATEGORIZED"}

CallBoardUI.Tabs.tabPVP:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:LoadExtraSlotsCategory(CallBoardUI.categories.pvp)
end)

CallBoardUI.Tabs.tabPVPHonorableCombat = CallBoardUI:CreateSubTab("CallBoardUI.Tabs.tabPVPHonorableCombat", CallBoardUI.Tabs, CallBoardUI.Tabs.tabPVP)
CallBoardUI.Tabs.tabPVPHonorableCombat:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVP, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVPHonorableCombat.text:SetText(CallBoardUI.MSGS.HONORABLE_COMBAT)
CallBoardUI.Tabs.tabPVPHonorableCombat.menu = "AREA_HYBRID_SCROLL"
CallBoardUI.Tabs.tabPVPHonorableCombat.tooltipTitle = CallBoardUI.MSGS.HONORABLE_COMBAT
CallBoardUI.Tabs.tabPVPHonorableCombat.tooltipText = CallBoardUI.MSGS.HONORABLE_COMBAT_TOOLTIP

CallBoardUI.Tabs.tabPVPHonorableCombat:SetScript("OnClick", function(self)
	CallBoardUI.content.AreaHybridScroll:LoadHonorableCombatData()
	CallBoardUI.content.AreaHybridScroll:RefreshLayout()
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:SelectMenu(self)
end)

--[[CallBoardUI.Tabs.tabPVPOutdoor = CallBoardUI:CreateSubTab("CallBoardUI.Tabs.tabPVPOutdoor", CallBoardUI.Tabs, CallBoardUI.Tabs.tabPVP)
CallBoardUI.Tabs.tabPVPOutdoor:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVPHonorableCombat, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVPOutdoor.text:SetText("Outdoor PvP Zones")
CallBoardUI.Tabs.tabPVPOutdoor.menu = "AREA_HYBRID_SCROLL"
CallBoardUI.Tabs.tabPVPOutdoor:SetScript("OnClick", function(self)
	CallBoardUI.content.AreaHybridScroll:LoadOutdoorPvPData()
	CallBoardUI.content.AreaHybridScroll:RefreshLayout()

	CallBoardUI:SelectMenu(self)
end)]]--

CallBoardUI.Tabs.tabPVPArenaReset = CallBoardUI:CreateSubTab("CallBoardUI.Tabs.tabPVPArenaReset", CallBoardUI.Tabs, CallBoardUI.Tabs.tabPVP)
CallBoardUI.Tabs.tabPVPArenaReset:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVPHonorableCombat, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabPVPArenaReset:Disable()
CallBoardUI.Tabs.tabPVPArenaReset.tooltipTitle = CallBoardUI.MSGS.ARENA_RESETS_TITLE
CallBoardUI.Tabs.tabPVPArenaReset.tooltipText = CallBoardUI.MSGS.ARENA_RESETS_TOOLTIP

CallBoardUI.Tabs.tabPVPArenaReset.timer = CreateFromMixins("gossipTimer")
CallBoardUI.Tabs.tabPVPArenaReset.timer.parent = CallBoardUI.Tabs.tabPVPArenaReset

function CallBoardUI.Tabs.tabPVPArenaReset.timer:onTickFunction()
	CallBoardUI.Tabs.tabPVPArenaReset.text:SetText(string.format(CallBoardUI.MSGS.ARENA_RESETS, SecondsToTime(self.endTime, true, false, 2)))
end

CallBoardUI.Tabs.tabProfessions = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabProfessions", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabProfessions:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabPVP, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabProfessions.icon:SetAtlas("questdaily", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.tabProfessions.text:SetText(CallBoardUI.MSGS.PROF)
CallBoardUI.Tabs.tabProfessions.tooltipTitle = CallBoardUI.MSGS.PROF
CallBoardUI.Tabs.tabProfessions.tooltipText = CallBoardUI.MSGS.PROF_TOOLTIP
CallBoardUI.Tabs.tabProfessions.gossipOption = "QUESTS_PROFESSION"
CallBoardUI.Tabs.tabProfessions.menu = {"SLOTS_EXTENDED_CATEGORIZED"}

CallBoardUI.Tabs.tabProfessions:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:LoadExtraSlotsCategory(CallBoardUI.categories.prof)
end)

CallBoardUI.Tabs.tabHighRisk = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabHighRisk", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabHighRisk:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabProfessions, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabHighRisk.icon:SetAtlas("questdaily", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.tabHighRisk.text:SetText(CallBoardUI.MSGS.HIGHRISK)
CallBoardUI.Tabs.tabHighRisk.tooltipTitle = CallBoardUI.MSGS.HIGHRISK
CallBoardUI.Tabs.tabHighRisk.tooltipText = CallBoardUI.MSGS.HIGHRISK_TOOLTIP
CallBoardUI.Tabs.tabHighRisk.gossipOption = "QUESTS_HIGHRISK"
CallBoardUI.Tabs.tabHighRisk.menu = {"SLOTS_EXTENDED_CATEGORIZED"}

CallBoardUI.Tabs.tabHighRisk:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:LoadExtraSlotsCategory(CallBoardUI.categories.highRisk)
end)

CallBoardUI.Tabs.tabMiscellaneous = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabMiscellaneous", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabMiscellaneous:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabHighRisk, "BOTTOMRIGHT", 0, -1)
CallBoardUI.Tabs.tabMiscellaneous.icon:SetAtlas("questdaily", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.tabMiscellaneous.text:SetText(CallBoardUI.MSGS.MISC)
CallBoardUI.Tabs.tabMiscellaneous.tooltipTitle = CallBoardUI.MSGS.MISC
CallBoardUI.Tabs.tabMiscellaneous.tooltipText = CallBoardUI.MSGS.MISC_TOOLTIP

CallBoardUI.Tabs.tabMiscellaneous.gossipOption = "QUESTS_MISCELLANEOUS"
CallBoardUI.Tabs.tabMiscellaneous.menu = {"SLOTS_EXTENDED_CATEGORIZED"}

CallBoardUI.Tabs.tabMiscellaneous:HookScript("OnClick", function(self)
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:LoadExtraSlotsCategory(CallBoardUI.categories.misc)
end)

CallBoardUI.Tabs.tabInstances = CallBoardUI:CreateTab("CallBoardUI.Tabs.tabInstances", CallBoardUI.Tabs)
CallBoardUI.Tabs.tabInstances:SetPoint("TOPRIGHT", CallBoardUI.Tabs.tabMiscellaneous, "BOTTOMRIGHT", 0, -1)
SetPortraitToTexture(CallBoardUI.Tabs.tabInstances.icon, "Interface\\Icons\\INV_Misc_Rune_01")
CallBoardUI.Tabs.tabInstances.text:SetText("Instances")
CallBoardUI.Tabs.tabInstances.tooltipTitle = CallBoardUI.MSGS.INSTANCES
CallBoardUI.Tabs.tabInstances.tooltipText = CallBoardUI.MSGS.INSTANCES_TOOLTIP

CallBoardUI.Tabs.tabInstances.gossipOption = "BACK"
CallBoardUI.Tabs.tabInstances.menu = {"AREA_HYBRID_SCROLL"}

CallBoardUI.Tabs.tabInstances:HookScript("OnClick", function(self)
	CallBoardUI.content.AreaHybridScroll:LoadInstancesData()
	CallBoardUI.content.AreaHybridScroll:RefreshLayout()
	CallBoardUI.content:LoadErrorText(self.tooltipTitle, self.tooltipText)
	CallBoardUI:SelectMenu(self)
end)
-------------------------------------------------------------------------------
--                                  Currency                                 --
-------------------------------------------------------------------------------
CallBoardUI.Tabs.BazaarTokens = CallBoardUI.Tabs:AddCurrency("BazaarTokens")
CallBoardUI.Tabs.BazaarTokens:SetPoint("BOTTOM", 0, 4)

--[[CallBoardUI.Tabs.seperator = CallBoardUI.Tabs:CreateTexture(nil, "ARTWORK")
CallBoardUI.Tabs.seperator:SetAtlas("store-receipt-line", Const.TextureKit.IgnoreAtlasSize)
CallBoardUI.Tabs.seperator:SetPoint("BOTTOM", CallBoardUI.Tabs.BazaarTokens, "TOP", 0, -1)
CallBoardUI.Tabs.seperator:SetHeight(2)
CallBoardUI.Tabs.seperator:SetWidth(195)]]--

-------------------------------------------------------------------------------
--                                 UpdateTime                                --
-------------------------------------------------------------------------------
CallBoardUI.Tabs.DailyUpdate = CallBoardUI:CreateTimerFrame("DailyUpdate", CallBoardUI)
CallBoardUI.Tabs.DailyUpdate:SetWidth(248)
CallBoardUI.Tabs.DailyUpdate.title:SetText(CallBoardUI.MSGS.DAILY_QUEST_RESET)
CallBoardUI.Tabs.DailyUpdate:SetPoint("TOPRIGHT", -12, -28)
CallBoardUI.Tabs.DailyUpdate.tooltipTitle = CallBoardUI.MSGS.DAILY_QUEST_RESET
CallBoardUI.Tabs.DailyUpdate.tooltipText = CallBoardUI.MSGS.DAILY_QUEST_RESET_TOOLTIP

CallBoardUI.Tabs.WeeklyUpdate = CallBoardUI:CreateTimerFrame("WeeklyUpdate", CallBoardUI)
CallBoardUI.Tabs.WeeklyUpdate:SetWidth(248)
CallBoardUI.Tabs.WeeklyUpdate.title:SetText(CallBoardUI.MSGS.WEEKLY_QUEST_RESET)
CallBoardUI.Tabs.WeeklyUpdate:SetPoint("TOP", CallBoardUI.Tabs.DailyUpdate, "BOTTOM")
CallBoardUI.Tabs.WeeklyUpdate.tooltipTitle = CallBoardUI.MSGS.WEEKLY_QUEST_RESET
CallBoardUI.Tabs.WeeklyUpdate.tooltipText = CallBoardUI.MSGS.WEEKLY_QUEST_RESET_TOOLTIP

-------------------------------------------------------------------------------
--                               Cache Progress                              --
-------------------------------------------------------------------------------
CallBoardUI.Tabs.CacheProgress = CreateFrame("Frame", "$parentCacheProgress", CallBoardUI, "BetterStatusBarTemplate")
CallBoardUI.Tabs.CacheProgress:SetSize(332, 20)
CallBoardUI.Tabs.CacheProgress:SetPoint("TOP", 0, -42)
CallBoardUI.Tabs.CacheProgress:SetStatusBarAtlas("ui-frame-bar-fill-green")
CallBoardUI.Tabs.CacheProgress.Background = CallBoardUI.Tabs.CacheProgress:CreateTexture(nil, "BACKGROUND")
CallBoardUI.Tabs.CacheProgress.Background:SetAllPoints()
CallBoardUI.Tabs.CacheProgress.Background:SetTexture(0, 0, 0, 0.9)

CallBoardUI.Tabs.CacheProgress.Border = CreateFrame("Frame", "$parentBorder", CallBoardUI.Tabs.CacheProgress, "BackdropTemplate")
CallBoardUI.Tabs.CacheProgress.Border:SetPoint("TOPLEFT", -5, 5)
CallBoardUI.Tabs.CacheProgress.Border:SetPoint("BOTTOMRIGHT", 5, -5)
CallBoardUI.Tabs.CacheProgress.Border:SetBackdrop(BACKDROP_TOAST_12_12_NOBG)

CallBoardUI.Tabs.CacheProgress.RewardText = CallBoardUI.Tabs.CacheProgress:CreateFontString(nil, "BACKGROUND")
CallBoardUI.Tabs.CacheProgress.RewardText:SetFontObject(GameFontNormal)
CallBoardUI.Tabs.CacheProgress.RewardText:SetPoint("BOTTOM", CallBoardUI.Tabs.CacheProgress, "TOP", 0, 4)

CallBoardUI.Tabs.TierReward = CreateFrame("Frame", "$parentTierReward", CallBoardUI, "ItemIconTemplate")
CallBoardUI.Tabs.TierReward:SetPoint("RIGHT", CallBoardUI.Tabs.CacheProgress, "LEFT", -12, 4)
CallBoardUI.Tabs.TierReward:SetRounded(true)
CallBoardUI.Tabs.TierReward:SetBorderSize(42, 42)
CallBoardUI.Tabs.TierReward:SetBorderOffset(0, -1)
CallBoardUI.Tabs.TierReward:EnableMouse(true)
CallBoardUI.Tabs.TierReward:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:SetHyperlink(self.item:GetLink())
	GameTooltip_AddSpacer(GameTooltip)
	local achievedItemLevel, currentRewardLevel, nextRewardLevel = C_CallboardCache.GetItemLevelInfo()
	GameTooltip:AddLine(NEXT_CACHE_ITEM_LEVEL.." |cffffffff"..achievedItemLevel.."|r", 1, 0.82, 0, false)
	GameTooltip:AddLine(NEXT_CACHE_ITEM_LEVEL_ABOUT:format(achievedItemLevel), 1, 1, 1, true)
	if nextRewardLevel then
		GameTooltip:AddLine(NEXT_CACHE_ITEM_LEVEL_GOAL:format(nextRewardLevel), 1, 1, 1, true)
	end
	GameTooltip:Show()
end)
CallBoardUI.Tabs.TierReward:SetScript("OnLeave", GameTooltip_Hide)

CallBoardUI.Tabs.TierReward.ProgressBar = CreateFrame("Frame", "$parentProgressBar", CallBoardUI.Tabs.TierReward, "CircularStatusBarTemplate")
CallBoardUI.Tabs.TierReward.ProgressBar:SetSize(44, 44)
CallBoardUI.Tabs.TierReward.ProgressBar:SetPoint("CENTER", 0, 0)
CallBoardUI.Tabs.TierReward.ProgressBar:SetTexture("Interface\\PVPFrame\\pvpqueue-sidebar-honorbar-fill")

CallBoardUI.Tabs.TierReward.ProgressBar.Background = CallBoardUI.Tabs.TierReward.ProgressBar:CreateTexture("$parentBackground", "BACKGROUND")
CallBoardUI.Tabs.TierReward.ProgressBar.Background:SetPoint("CENTER", 0, 0.5)
CallBoardUI.Tabs.TierReward.ProgressBar.Background:SetSize(66.5, 58)
CallBoardUI.Tabs.TierReward.ProgressBar.Background:SetAtlas("pvpqueue-sidebar-honorbar-background", Const.TextureKit.IgnoreAtlasSize)
-------------------------------------------------------------------------------
--                                  Content                                  --
-------------------------------------------------------------------------------
CallBoardUI.content = Addon.SharedGossip:CreateContent(CallBoardUI)
CallBoardUI.content:SetWidth(813)
CallBoardUI.content:SetHeight(626)

CallBoardUI.content.Bg:ClearAllPoints()
CallBoardUI.content.Bg:SetHorizTile(false)
CallBoardUI.content.Bg:SetVertTile(false)
CallBoardUI.content.Bg:SetTexture("Interface\\callboard\\alliance_bg")
CallBoardUI.content.Bg:SetWidth(812)
CallBoardUI.content.Bg:SetHeight(728)
CallBoardUI.content.Bg:SetPoint("CENTER", 0, 0)

CallBoardUI.content.errorText = CallBoardUI.content:CreateFontString(nil, "OVERLAY")
CallBoardUI.content.errorText:SetFontObject(GameFontDisableLarge)
CallBoardUI.content.errorText:SetPoint("CENTER")
CallBoardUI.content.errorText:SetText(CallBoardUI.MSGS.ERROR_TEXT_BASE)
CallBoardUI.content.errorText:SetWidth(400)
CallBoardUI.content.errorText:Hide()

function CallBoardUI.content:LoadErrorText(title, text)
	local finalString = ""

	if (title) then
		finalString = "|cffFFFFFF"..title.."\n"
	end

	if (text) then
		finalString = finalString.."|cffffd100"..text.."|r\n\n"
	end

	self.errorText:SetText(finalString..CallBoardUI.MSGS.ERROR_TEXT_BASE)

end

function CallBoardUI.content:CreateFullSizeHybridScroll(name)
	local hybridScroll = HybridScroll()

	hybridScroll.Parent = self -- Parent frame
	hybridScroll.ParentName = self:GetName()
	hybridScroll.Name = name
	hybridScroll.Width = self:GetWidth()-24
	hybridScroll.Height = self:GetHeight()-12
	hybridScroll.doNotHide = true
	hybridScroll.point = {"TOPLEFT", 0, -6}
	hybridScroll.scrollup_point = {2.5, -15}
	hybridScroll.scrolldown_point = {0, 14}

	function hybridScroll:IsVisible() -- TODO: Move to hybrid scroll
		return hybridScroll.Content:IsVisible()
	end

	hooksecurefunc(hybridScroll, "RefreshLayout", function(...)
		if not(hybridScroll.items) or not(next(hybridScroll.items)) then
			CallBoardUI.content.errorText:Show()
		else
			CallBoardUI.content.errorText:Hide()
		end
	end)

	return hybridScroll
end

function CallBoardUI.content:CreateQuestHybridScroll(name)
	local hybridScroll = CallBoardUI.content:CreateFullSizeHybridScroll(name)
	hybridScroll.Height = 496
	hybridScroll.scrolldown_point = {0, 10}

	function hybridScroll:LoadData()
	    hybridScroll.items = {}
	end

	function hybridScroll.CreateButton(self, i)
		local btn = CallBoardUI:CreateExtendedSlot("slot"..i, self)

	    if (i == 1) then
	        btn:SetPoint("TOP", 1, -1)
	    else
	        btn:SetPoint("TOP", _G[self:GetName()..".slot"..(i-1)], "BOTTOM", 0, 0)
	    end

	    return btn
	end

	function hybridScroll.SetUpButton(button, data) 
		button:Clear()
		button:SetQuest(data.ID, data.name, data.isDaily, data.buttonIndex, data.isActive, data.isComplete, hybridScroll.category, data.remainingCompletions)
	end

	function hybridScroll:LoadQuests(questList)
		hybridScroll.items = questList
		hybridScroll:RefreshLayout()
	end

	function hybridScroll:RefreshButtonRewards(questID)
		for i = 1, #self.Scroll.buttons do
			local btn = self.Scroll.buttons[i]
			if (btn:IsVisible()) then
        		self.Scroll.buttons[i]:LoadRewards()
        	end
        end
    end

	return hybridScroll
end

function CallBoardUI.content:CreateFullSizeHybridScrollForAreas(name)
	local hybridScroll = CallBoardUI.content:CreateFullSizeHybridScroll(name)

	function hybridScroll.CreateButton(self, i)
		local btn = CallBoardUI:CreateAreaTemplate("slot"..i, self)

	    if (i == 1) then
	        btn:SetPoint("TOP", 1, -1)
	    else
	        btn:SetPoint("TOP", _G[self:GetName()..".slot"..(i-1)], "BOTTOM", 0, 0)
	    end

	    return btn
	end

	return hybridScroll
end

function CallBoardUI.content:CreateScrollArtwork(parent)
	parent.scrollTop = parent:CreateTexture(nil, "ARTWORK")
	parent.scrollTop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	parent.scrollTop:SetTexCoord(0, 0.45, 0, 0.2)
	parent.scrollTop:SetSize(24, 48)
	parent.scrollTop:SetPoint("TOPRIGHT", 21, 4)

	parent.scrollBot = parent:CreateTexture(nil, "ARTWORK")
	parent.scrollBot:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	parent.scrollBot:SetTexCoord(0.515625, 0.97, 0.1440625, 0.4140625)
	parent.scrollBot:SetSize(24, 64)
	parent.scrollBot:SetPoint("BOTTOMRIGHT", 21, -3)

	parent.scrollMid = parent:CreateTexture(nil, "ARTWORK")
	parent.scrollMid:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	parent.scrollMid:SetTexCoord(0, 0.45, 0.1640625, 1)
	parent.scrollMid:SetPoint("TOPLEFT", parent.scrollTop, "BOTTOMLEFT")
	parent.scrollMid:SetPoint("BOTTOMRIGHT", parent.scrollBot, "TOPRIGHT")

	parent.scrollBG = parent:CreateTexture(nil, "BACKGROUND")
	parent.scrollBG:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", "MIRROR", "MIRROR")
	parent.scrollBG:SetPoint("TOPLEFT", parent.scrollTop, "TOPLEFT")
	parent.scrollBG:SetPoint("BOTTOMRIGHT", parent.scrollBot, "BOTTOMRIGHT")
	parent.scrollBG:SetWidth(10)
	parent.scrollBG:SetHorizTile(true)
	parent.scrollBG:SetVertTile(true)
end

function CallBoardUI.content:InitFullSizeHybridScroll(hybridScroll)
	hybridScroll.Init()

	self:CreateScrollArtwork(hybridScroll.Scroll)

	hooksecurefunc(hybridScroll, "RefreshLayout", function(...)
		if not(hybridScroll.items) or not(next(hybridScroll.items)) then
			hybridScroll.Scroll.scrollBar:Hide()
			hybridScroll.Scroll.scrollTop:Hide()
			hybridScroll.Scroll.scrollBot:Hide()
			hybridScroll.Scroll.scrollMid:Hide()
			hybridScroll.Scroll.scrollBG:Hide()
		else
			hybridScroll.Scroll.scrollBar:Show()
			hybridScroll.Scroll.scrollTop:Show()
			hybridScroll.Scroll.scrollBot:Show()
			hybridScroll.Scroll.scrollMid:Show()
			hybridScroll.Scroll.scrollBG:Show()
		end
	end)
end

function CallBoardUI.content:InitQuestHybridScroll(hybridScroll)
	self:InitFullSizeHybridScroll(hybridScroll)

	hybridScroll.Scroll.scrollBot:SetPoint("BOTTOMRIGHT", 21, -6)
end
-------------------------------------------------------------------------------
--                              Quest Statistics                             --
-------------------------------------------------------------------------------
CallBoardUI.content.TotalRewards = CallBoardUI:CreateTotalRewardsFrame("TotalRewards", CallBoardUI.content)
CallBoardUI.content.TotalRewards:SetPoint("BOTTOM", 0, 22) -- bottom buttons take 22

CallBoardUI.menus["TOTAL_REWARDS"] = CallBoardUI.content.TotalRewards
-------------------------------------------------------------------------------
--                   Honorable Combat / Outdoor pvp scroll                   --
-------------------------------------------------------------------------------
CallBoardUI.content.AreaHybridScroll = CallBoardUI.content:CreateFullSizeHybridScrollForAreas("AreaHybridScroll")

CallBoardUI.menus["AREA_HYBRID_SCROLL"] = CallBoardUI.content.AreaHybridScroll

function CallBoardUI.content.AreaHybridScroll:LoadHonorableCombatData()
	CallBoardUI.content.AreaHybridScroll.items = {}

	CallBoardUI.content.AreaHybridScroll.isInstances = false
	CallBoardUI.content.AreaHybridScroll.isOutdoor = false
	CallBoardUI.content.AreaHybridScroll.isHonorableCombat = true

	if WorldMapFrame.HonorableCombatAreas and next(WorldMapFrame.HonorableCombatAreas) then
		for fileName, _ in pairs(WorldMapFrame.HonorableCombatAreas) do
			local areaID = GetWorldMapAreaID(fileName)
			if areaID then
				table.insert(CallBoardUI.content.AreaHybridScroll.items, areaID)
			end
		end
	end
end

function CallBoardUI.content.AreaHybridScroll:LoadOutdoorPvPData()
	CallBoardUI.content.AreaHybridScroll.items = {}

	CallBoardUI.content.AreaHybridScroll.isInstances = false
	CallBoardUI.content.AreaHybridScroll.isOutdoor = true
	CallBoardUI.content.AreaHybridScroll.isHonorableCombat = false

	for _, areaData in pairs(CallBoardUI.outdoor_PvP_Zones) do
		if GameEventUtil.IsEventActive(areaData.event) then
			table.insert(CallBoardUI.content.AreaHybridScroll.items, areaData)
		end
	end
end

function CallBoardUI.content.AreaHybridScroll:LoadInstancesData()
	CallBoardUI.content.AreaHybridScroll.items = {}

	CallBoardUI.content.AreaHybridScroll.isInstances = true
	CallBoardUI.content.AreaHybridScroll.isOutdoor = false
	CallBoardUI.content.AreaHybridScroll.isHonorableCombat = false

	if next(CallBoardUI.instancesData) then
		for i = 1, #CallBoardUI.instancesData do
			table.insert(CallBoardUI.content.AreaHybridScroll.items, {unpack(CallBoardUI.instancesData[i])})
		end
	end
end

function CallBoardUI.content.AreaHybridScroll.SetUpButton(button, data, dataIndex) 
	if (CallBoardUI.content.AreaHybridScroll.isOutdoor) then
		button:SetMap(data.areaID)
	elseif (CallBoardUI.content.AreaHybridScroll.isInstances) then
		button:SetInstance(dataIndex, data[1], data[2])
	elseif (CallBoardUI.content.AreaHybridScroll.isHonorableCombat) then
		button:SetMap(data)
	end
end

CallBoardUI.content:InitFullSizeHybridScroll(CallBoardUI.content.AreaHybridScroll)
CallBoardUI.content.AreaHybridScroll:Hide()
-------------------------------------------------------------------------------
--                             Raid Reset Timers                             --
-------------------------------------------------------------------------------
CallBoardUI.content.raidResets = CallBoardUI.content:CreateFullSizeHybridScroll("raidResets")

CallBoardUI.menus["RAID_RESETS"] = CallBoardUI.content.raidResets

function CallBoardUI.content.raidResets:LoadSavedInstanceData()
	CallBoardUI.content.raidResets.items = {}

	local index = 1
	local raidInfo = {GetSavedInstanceInfo(index)}

	while (raidInfo[1]) do
		table.insert(CallBoardUI.content.raidResets.items, {unpack(raidInfo)})
		index = index + 1
		raidInfo = {GetSavedInstanceInfo(index)}
	end
end

function CallBoardUI.content.raidResets:LoadTimeWalkingData()
	CallBoardUI.content.raidResets.items = {}

	if next(CallBoardUI.timeWalkingData) then
		for i = 1, #CallBoardUI.timeWalkingData do
			table.insert(CallBoardUI.content.raidResets.items, CallBoardUI.timeWalkingData[i])
		end
	end
end

function CallBoardUI.content.raidResets.CreateButton(self, i)
	local btn = CallBoardUI:CreateRaidTemplate("slot"..i, self)

    if (i == 1) then
        btn:SetPoint("TOP", 1, -1)
    else
        btn:SetPoint("TOP", _G[self:GetName()..".slot"..(i-1)], "BOTTOM", 0, 0)
    end

    return btn
end

function CallBoardUI.content.raidResets.SetUpButton(button, data, dataIndex) 
	if (type(data) == "table") then -- saved instance data
		local instanceName, instanceID, instanceReset, instanceDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = unpack(data)
		button:SetRaidReset(instanceName, instanceReset, difficultyName)
	elseif (type(data) == "number") then -- just mapID from timewalking
		button:SetTimeWalking(data, dataIndex)
	end
end

CallBoardUI.content:InitFullSizeHybridScroll(CallBoardUI.content.raidResets)
CallBoardUI.content.raidResets:Hide()
-------------------------------------------------------------------------------
--                            Extended ExtraSlots                            --
-------------------------------------------------------------------------------
--CallBoardUI.content.ExtraSlots = CallBoardUI.content:CreateQuestHybridScroll("ExtraSlots")

--[[CallBoardUI.menus["SLOTS_EXTENDED"] = CallBoardUI.content.ExtraSlots

CallBoardUI.content:InitQuestHybridScroll(CallBoardUI.content.ExtraSlots)
--CallBoardUI.content.ExtraSlots:Hide()

CallBoardUI.content.TotalRewards:SetFrameLevel(CallBoardUI.content.ExtraSlots.Content:GetFrameLevel()+1)]]--
-------------------------------------------------------------------------------
--                                 PoA Scroll                                --
-------------------------------------------------------------------------------
CallBoardUI.content.ExtraSlotsContent = CreateFrame("FRAME", "$parent.ExtraSlotsContent", CallBoardUI.content, nil)
CallBoardUI.content.ExtraSlotsContent:SetSize(789, 612)

CallBoardUI.content.ExtraSlotsCategorized = CreateFrame("ScrollFrame", "$parent.ExtraSlotsCategorized", CallBoardUI.content, "UIPanelScrollFrameTemplate")
CallBoardUI.content.ExtraSlotsCategorized:SetSize(789, 612)
CallBoardUI.content.ExtraSlotsCategorized:SetPoint("TOPLEFT", 0, -6)
CallBoardUI.content.ExtraSlotsCategorized:EnableMouseWheel(true) -- TODO: Polish mousewheel
CallBoardUI.content.ExtraSlotsCategorized:SetScrollChild(CallBoardUI.content.ExtraSlotsContent)
CallBoardUI.content.ExtraSlotsCategorized.content = CallBoardUI.content.ExtraSlotsContent

CallBoardUI.content:CreateScrollArtwork(_G[CallBoardUI.content.ExtraSlotsCategorized:GetName().."ScrollBar"])

_G["CallBoardUI.content.ExtraSlotsCategorizedScrollBar"]:SetPoint("TOPLEFT", CallBoardUI.content.ExtraSlotsCategorized, "TOPRIGHT", 2, -15)
_G["CallBoardUI.content.ExtraSlotsCategorizedScrollBar"]:SetPoint("BOTTOMLEFT", CallBoardUI.content.ExtraSlotsCategorized, "BOTTOMRIGHT", 2, 14)
_G[CallBoardUI.content.ExtraSlotsCategorized:GetName().."ScrollBar"].scrollTop:SetPoint("TOPRIGHT", 3, 19)
_G[CallBoardUI.content.ExtraSlotsCategorized:GetName().."ScrollBar"].scrollBot:SetPoint("BOTTOMRIGHT", 3, -17)

ScrollFrame_OnLoad(CallBoardUI.content.ExtraSlotsCategorized)
CallBoardUI.menus["SLOTS_EXTENDED_CATEGORIZED"] = CallBoardUI.content.ExtraSlotsCategorized

function CallBoardUI.content.ExtraSlotsCategorized:RefreshButtonRewards()
	self:RefreshLayout()
end

function CallBoardUI.content.ExtraSlotsCategorized:RefreshLayout()
	self.buttons = self.buttons or {}

	for _, button in pairs(self.buttons) do
		button:Hide()
	end

	local i = 0

	for _, item in pairs(self.items) do
		i = i + 1

		if not self.buttons[i] then
			self.buttons[i] = CallBoardUI:CreateCategorizedQuestDetailsFrame("categoryDetailsFrame", self.content)

		    if (i == 1) then
		        self.buttons[i]:SetPoint("TOP", self.content, 1, -1)
		    else
		        self.buttons[i]:SetPoint("TOP", self.buttons[i-1], "BOTTOM", 0, 0)
		    end
		end

		self.buttons[i]:SetSubCategoryDetails(item.name, item.quests)
		self.buttons[i]:Show()
	end
end

function CallBoardUI.content.ExtraSlotsCategorized:LoadQuests(items)
	self.items = items
	self:RefreshLayout()
end

--[[hooksecurefunc(CallBoardUI.content.ExtraSlotsCategorized, "RefreshLayout", function(...)
	if not(CallBoardUI.content.ExtraSlotsCategorized.items) or not(next(CallBoardUI.content.ExtraSlotsCategorized.items)) then
		if (CallBoardUI.content.TotalRewards:IsVisible()) then
			CallBoardUI.content.TotalRewards:Hide()
		end
	else
		CallBoardUI.content.TotalRewards:Show()
	end
end)]]--

hooksecurefunc(CallBoardUI.content.ExtraSlotsCategorized, "LoadQuests", function()
	local errorMessage = ""

    for i = 1, #CallBoardUI.questList do
    	local questID = CallBoardUI.questList[i].ID
    	local questName = CallBoardUI.questList[i].name
    	local categoryData, subCategory, categoryKey = CallBoardUI:GetCategoryQuestData(questID)

    	if not(categoryData) then
    		errorMessage = errorMessage..string.format(CallBoardUI.MSGS.QUEST_NOT_COMPLETABLE_TC, questName).."\n\n"
    	else
    		local serverData = categoryData
    		local totalData = categoryKey and CallBoardUI.TemporalContractsMap[categoryKey] and CallBoardUI.TemporalContractsMap[categoryKey]["TOTAL"]
    		local remainingCompletions = (serverData.remainingCompletions and serverData.remainingCompletions > 0 and serverData.remainingCompletions)
    		                             or (totalData and totalData.remainingCompletions) or 0

    		if serverData and remainingCompletions > 0 then
    			-- TODO: Polish later
    			CallBoardUI.questList[i].remainingCompletions = remainingCompletions

    			categoryData.moneyCost = serverData.moneyCost
    			categoryData.tokenCost = serverData.tokenCost
	    	else
	    		categoryData.moneyCost = 0
    			categoryData.tokenCost = 0
	    	end
    	end
    end

    if next(CallBoardUI.availableQuests) then
    	CallBoardUI.content.TotalRewards.controlFrame.buttonAccept:Enable()
    else
    	CallBoardUI.content.TotalRewards.controlFrame.buttonAccept:Disable()
    end

    CallBoardUI.CompleteGossipQuestIDs = GetCompleteGossipQuestIds() or {}

    if next(CallBoardUI.activeQuests) and next(CallBoardUI.CompleteGossipQuestIDs) then
    	CallBoardUI.content.TotalRewards.controlFrame.buttonComplete:Enable()
    else
    	CallBoardUI.content.TotalRewards.controlFrame.buttonComplete:Disable()
    end

	CallBoardUI.content.TotalRewards:SetUpCompleteFrame(errorMessage)

	CallBoardUI.content.ExtraSlotsCategorized:RefreshLayout()
end)

-------------------------------------------------------------------------------
--                                 Statistics                                --
-------------------------------------------------------------------------------

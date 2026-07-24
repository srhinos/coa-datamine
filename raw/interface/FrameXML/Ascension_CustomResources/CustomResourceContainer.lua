CustomResourceContainerMixin = {}

function CustomResourceContainerMixin:OnLoad()
	self.PowerSegmentCollection = CreateFramePoolCollection()
	self.ActivePowerSegments = {}
	self:UpdateLockState()
	self:RegisterEvent("UNIT_POWER_ALTERNATIVE_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	if C_Player:IsHero() then
		self:SetPoint("TOP", PlayerFrameEnergyBar, "BOTTOM", 0, -4)
	end
end

function CustomResourceContainerMixin:UpdateLockState()
	--[[if C_CVar.GetBool("customResourceLocked") then
		self:RegisterForDrag("LeftButton")
	else
		self:RegisterForDrag()
	end]]
end
-- /run CustomResourceContainer:SetResourceType(Enum.CustomPowerType.ShadowOrbs3)
function CustomResourceContainerMixin:SetResourceType(resourceType)
	local needFullUpdate = self.resourceType ~= resourceType
	self.resourceType = resourceType
	if self.resourceType and self.resourceType > 0 then
		self:Show()
		self:Update(needFullUpdate)
	else
		self:Hide()
	end
end

function CustomResourceContainerMixin:GetCurrentValues()
	if not self.definition then return 0, 0 end
	local current, max = UnitAlternativePower("player") or 0, self.definition.maxValue
	return current, max
end

function CustomResourceContainerMixin:Update(fullUpdate)
	if fullUpdate or not self.definition then
		self:UpdateDefinition()
	end

	if not self.definition then
		self:Hide()
		return
	end

	local type = self.definition.type

	if type == "statusbar" then
		self:UpdateStatusBar()
	else
		self:UpdateResourceSegments()
	end
end

function CustomResourceContainerMixin:UpdateResourceSegments()
	local current, max = self:GetCurrentValues()
	for index, segment in ipairs(self.ActivePowerSegments) do
		segment:UpdateVisual(index, current, max)
	end

	if self.definition.backgroundAtlasMax or self.definition.backgroundAtlasActive then
		if self.definition.backgroundAtlasMax and current == max then
			self.Background:SetAtlas(self.definition.backgroundAtlasMax)
		elseif self.definition.backgroundAtlasActive and current > 0 then
			self.Background:SetAtlas(self.definition.backgroundAtlasActive)
		else
			self.Background:SetAtlas(self.definition.backgroundAtlas)
		end
	end
end

function CustomResourceContainerMixin:GetStatusBar()
	if not self.StatusBar then
		self.StatusBar = CreateFrame("Frame", "$parentStatusBar", self, "BetterStatusBarTemplate")
		self.StatusBar:SetFontObject(TextStatusBarText)
		self.StatusBar:SetPoint("TOPLEFT")
		self.StatusBar:SetPoint("BOTTOMRIGHT")
		self.StatusBar:Hide()

		self.StatusBar.BackdropOverlay = CreateFrame("Frame", "$parentOverlay", self.StatusBar)
		self.StatusBar.BackdropOverlay:SetPoint("TOPLEFT", -4, 4)
		self.StatusBar.BackdropOverlay:SetPoint("BOTTOMRIGHT", 4, -4)
	end
	
	return self.StatusBar
end

function CustomResourceContainerMixin:UpdateStatusBar()
	local statusBar = self:GetStatusBar()
	local currentValue, maxValue = self:GetCurrentValues()
	statusBar:SetMinMaxValues(0, maxValue)
	statusBar:SetValue(currentValue)

	if self.definition.showText then
		if C_CVar.GetBool("statusTextPercentage") then
			statusBar:SetFormattedText("%d%%", self:GetCurrentValues() / self.definition.maxValue * 100)
		else
			statusBar:SetFormattedText("%d/%d", self:GetCurrentValues())
		end
	else
		statusBar:SetText("")
	end
end

function CustomResourceContainerMixin:SetStatusBarFromDefinition()
	local def = self.definition
	local statusBar = self:GetStatusBar()
	statusBar:Show()
	statusBar:SetStatusBarColor(def.color:GetRGB())
	if def.barAtlas then
		statusBar:SetStatusBarAtlas(def.barAtlas)
	elseif def.barTexture then
		statusBar:SetStatusBarTexture(def.barTexture)
	else
		statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	end

	if def.backgroundAtlas then
		statusBar:SetBackgroundAtlas(def.backgroundAtlas)
	elseif def.backgroundTexture then
		statusBar:SetBackgroundTexture(def.backgroundTexture)
	elseif def.backgroundColor then
		statusBar:SetBackgroundTexture(def.backgroundColor:GetRGB())
	else
		statusBar:SetBackgroundTexture(0, 0, 0, 0.9)
	end

	statusBar.BackdropOverlay:SetBackdrop(def.backdrop)
end

function CustomResourceContainerMixin:SetResourceFromDefinition()
	local def = self.definition
	self:SetSize(def.width, def.height)
	if def.backgroundAtlas then
		self.Background:SetAtlas(def.backgroundAtlas)
		self.Background:Show()
	elseif def.backgroundTexture then
		self.Background:SetTexture(def.backgroundTexture)
		self.Background:Show()
	end

	local template = def.template or "CustomResourceSegmentTemplate"
	self.PowerSegmentCollection:CreatePoolIfNeeded("Frame", self, template)
	local maxValue = def.maxValue

	for i = 1, maxValue do
		local segment = self.PowerSegmentCollection:Acquire(template)
		segment:Show()
		if not def.segmentUseAtlasSize then
			if type(def.segmentWidth) == "table" then
				segment:SetWidth(def.segmentWidth[i])
			else
				segment:SetWidth(def.segmentWidth)
			end

			if type(def.segmentHeight) == "table" then
				segment:SetHeight(def.segmentHeight[i])
			else
				segment:SetHeight(def.segmentHeight)
			end
		end

		-- active textures
		if def.segmentActiveAtlas then
			if type(def.segmentActiveAtlas) == "table" then
				segment:SetActiveAtlas(def.segmentActiveAtlas[i], def.segmentUseAtlasSize)
			else
				segment:SetActiveAtlas(def.segmentActiveAtlas, def.segmentUseAtlasSize)
			end
		elseif def.segmentActiveTexture then
			if type(def.segmentActiveTexture) == "table" then
				segment:SetActiveTexture(def.segmentActiveTexture[i])
			else
				segment:SetActiveTexture(def.segmentActiveTexture)
			end
		else
			segment:SetActiveTexture(nil)
		end

		-- inactive textures
		if def.segmentInactiveAtlas then
			if type(def.segmentInactiveAtlas) == "table" then
				segment:SetInactiveAtlas(def.segmentInactiveAtlas[i], def.segmentUseAtlasSize)
			else
				segment:SetInactiveAtlas(def.segmentInactiveAtlas, def.segmentUseAtlasSize)
			end
		elseif def.segmentInactiveTexture then
			if type(def.segmentInactiveTexture) == "table" then
				segment:SetInactiveTexture(def.segmentInactiveTexture[i])
			else
				segment:SetInactiveTexture(def.segmentInactiveTexture)
			end
		else
			segment:SetInactiveTexture(nil)
		end

		if i == 1 then
			segment:SetPoint("TOPLEFT", self, "TOPLEFT", def.segmentXOffset or 0, def.segmentYOffset or 0)
		else
			segment:SetPoint("LEFT", self.ActivePowerSegments[i - 1], "RIGHT", def.segmentSpacing or 0, 0)
		end
		self.ActivePowerSegments[i] = segment
	end
end

function CustomResourceContainerMixin:UpdateDefinition()
	self.definition = GetCustomResourceInfo(self.resourceType)
	if not self.definition then
		self.definition = GetDefaultCustomResourceInfo()
	end
	if self:IsMouseOver() then
		self:OnEnter()
	end

	self.Background:Hide()
	self.PowerSegmentCollection:ReleaseAll()
	wipe(self.ActivePowerSegments)

	if self.definition.type == "statusbar" then
		self:SetStatusBarFromDefinition()
	else
		self:GetStatusBar():Hide()
		self:SetResourceFromDefinition()
	end
end

function CustomResourceContainerMixin:OnEnter()
	if not self.definition or not self.definition.tooltipTitle then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(format(self.definition.tooltipTitle, self:GetCurrentValues()), 1, 1, 1)
	if self.definition.tooltipText then
		GameTooltip:AddLine(self.definition.tooltipText, 1, 0.82, 0, true)
	end

	if C_Realm.IsDevelopment() then
		GameTooltip_AddSpacer(GameTooltip)
		local enumName = EnumUtil.ValueToString(Enum.CustomPowerType, self.resourceType) or "Default"
		GameTooltip:AddLine("Resource ID: "..ASCENSION_SECONDARY_COLOR:WrapText(self.resourceType or "Default"), ASCENSION_PRIMARY_COLOR:GetRGB())
		GameTooltip:AddLine("Resource Enum: "..ASCENSION_SECONDARY_COLOR:WrapText(enumName), ASCENSION_PRIMARY_COLOR:GetRGB())
		local currentValue, maxValue = self:GetCurrentValues()
		GameTooltip:AddLine("Value: " .. ASCENSION_SECONDARY_COLOR:WrapText(currentValue), ASCENSION_PRIMARY_COLOR:GetRGB())
		GameTooltip:AddLine("Max Value: " .. ASCENSION_SECONDARY_COLOR:WrapText(maxValue), ASCENSION_PRIMARY_COLOR:GetRGB())
	end
	GameTooltip:Show()
end

function CustomResourceContainerMixin:OnLeave()
	GameTooltip:Hide()
end

function CustomResourceContainerMixin:UNIT_POWER_ALTERNATIVE_UPDATE(resourceType)
	self:SetResourceType(resourceType)
end

function CustomResourceContainerMixin:PLAYER_ENTERING_WORLD()
	self:SetResourceType(UnitAlternativePowerType("player"))
end

if C_Realm.IsDevelopment() then
	function RefreshCustomResource()
		CustomResourceContainer:Update(true)
	end
end
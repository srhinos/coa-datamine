AddonPanelInfoMixin = {}

function AddonPanelInfoMixin:OnLoad()
	if InGlue() then
		self.Version:Hide()
		self.Author:Hide()
	end
end

function AddonPanelInfoMixin:SetAddon(addon)
	if not addon then
		self:Hide()
		return
	end

	self:Show()
	local name = addon.title and (addon.title .. " (" .. addon.name .. ")" or addon.name)
	if addon.iconTexture then
		name = CreateSquareTextureMarkup(addon.iconTexture, 24, 24, 0, 2) .. " " .. name
	end
	self.Name:SetHeader(name)

	if InGlue() then
		-- GlueXML
		if addon.loadable or addon.enabled and (addon.reason == "DEP_DEMAND_LOADED" or addon.reason == "DEMAND_LOADED") then
			if addon.enableState == 2 then
				self.Name:SetHeaderFontObject(GameFontGreenLarge)
			elseif addon.enableState == 1 then
				self.Name:SetHeaderFontObject(GameFontHighlightLarge)
			else
				self.Name:SetHeaderFontObject(GameFontDisableLarge)
			end
		elseif addon.enabled and addon.reason == "DEP_DISABLED" or addon.reason == "INTERFACE_VERSION" or addon.reason == "NOT_LAUNCHER" then
			self.Name:SetHeaderFontObject(GameFontRedLarge)
		else
			self.Name:SetHeaderFontObject(GameFontDisableLarge)
		end

		self.Notes:SetPoint("TOPLEFT", self.Loadable, "BOTTOMLEFT", 0, -24)
		
		local disabledChars = C_AddonPanel:GetAddonDisabledBy(addon)
		if disabledChars then
			self.DisabledFor:Show()
			self.DisabledFor:SetText(disabledChars)
		else
			self.DisabledFor:Hide()
		end
	else 
		-- FrameXML
		if addon.loadable and addon.enabled then
			self.Name:SetHeaderFontObject(GameFontGreenLarge)
		elseif addon.enabled and addon.reason == "DEP_DISABLED" or addon.reason == "INTERFACE_VERSION" or addon.reason == "NOT_LAUNCHER" then
			self.Name:SetHeaderFontObject(GameFontRedLarge)
		else
			self.Name:SetHeaderFontObject(GameFontDisableLarge)
		end

		self.Version:SetText(addon.version)
		self.Author:SetText(addon.author)
	end
	
	local loadableText = addon.loadable and YES or _G["ADDON_"..addon.reason]

	if addon.enabled ~= addon.initialState then
		self.Loadable:SetText(loadableText .. "\n\n" .. ADDON_RELOAD_REQUIRED)
	else
		self.Loadable:SetText(loadableText)
	end

	-- todo: hyperlinks
	local depStr
	for _, dep in ipairs(addon.dependencies) do
		if not depStr then
			depStr = dep
		else
			depStr = depStr .. ", " .. dep
		end
	end

	self.Dependencies:SetText(depStr or NONE_CAPS)

	self.Notes:SetText(addon.notes)
end
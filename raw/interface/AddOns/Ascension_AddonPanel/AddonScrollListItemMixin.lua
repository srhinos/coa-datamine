AddonScrollListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function AddonScrollListItemMixin:OnLoad()
	self:SetNormalAtlas("addons_categoryheader_2")
	self:GetNormalTexture():SetAlpha(0.5)
	self:SetHighlightAtlas("addons_list_hover")
end

function AddonScrollListItemMixin:Init(args)
	self.parent = args[1]
end

function AddonScrollListItemMixin:Update()
	local addon = self.parent.addons[self.index]
	if addon then
		self.Check:GetCheckedTexture():SetVertexColor(1, 1, 1)
		if addon.loadable or addon.enabled and (addon.reason == "DEP_DEMAND_LOADED" or addon.reason == "DEMAND_LOADED") then
			if addon.enableState == 2 then
				if addon.enabled ~= addon.initialState then
					self.Text:SetFontObject(GameFontGreenSmall)
				else
					self.Text:SetFontObject(GameFontNormalSmall)
				end
			else
				if addon.enabled ~= addon.initialState then
					self.Text:SetFontObject(GameFontRedSmall)
				else
					self.Text:SetFontObject(GameFontDisableSmall)
				end
			end
		elseif addon.enabled and addon.reason == "DEP_DISABLED" or addon.reason == "INTERFACE_VERSION" or addon.reason == "NOT_LAUNCHER" then
			self.Text:SetFontObject(GameFontRedSmall)
			self.Check:GetCheckedTexture():SetVertexColor(RED_FONT_COLOR:GetRGBA())
		else
			self.Text:SetFontObject(GameFontDisableSmall)
		end

		if addon.iconTexture then
			self:SetText(CreateSquareTextureMarkup(addon.iconTexture, 16, 16, 0, 2) .. " " .. (addon.title or addon.name))
		else
			self:SetText(addon.title or addon.name)
		end

		local checkState, enable
		if InGlue() then
			checkState = GetAddOnEnableState(self.parent.selectedCharacter, addon.id)
			enable = checkState == 2
		else
			checkState = addon.enabled and 2 or 0
			enable = addon.enabled
		end

		self.Check:SetChecked(checkState > 0)
		self.Check:GetCheckedTexture():SetDesaturated(checkState == 1)
	end
end

function AddonScrollListItemMixin:OnSelected()
	self.parent:SelectAddon(self.parent.addons[self.index])
end

function AddonScrollListItemMixin:OnRightClick()
end

function AddonScrollListItemMixin:OnEnter()
end

function AddonScrollListItemMixin:OnLeave()
end

function AddonScrollListItemMixin:OnClickCheck(checked)
	local addon = self.parent.addons[self.index]

	if InGlue() then
		local char = self.parent.selectedCharacter
		local checkState = GetAddOnEnableState(char, addon.id)
		if checked or checkState == 1 then
			EnableAddOn(char, addon.id)
		else
			DisableAddOn(char, addon.id)
		end
	else
		if checked then
			EnableAddOn(addon.id)
		else
			DisableAddOn(addon.id)
		end
	end

	self.parent:RefreshAddonList()
end
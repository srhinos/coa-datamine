-------------------------------------------------------------------------------
--                              Manager Frame                                --
-------------------------------------------------------------------------------
ECSpecManagerMixin = {}

function ECSpecManagerMixin:OnLoad()
	self:Layout()
	self:EnableMouse(true)
	self:SetFrameLevel(self:GetParent():GetFrameLevel()+20)
	self.PopupController.frame:SetFrameLevel(self:GetFrameLevel()+10)

	self.ScrollList:SetGetNumResultsFunction(MysticEnchantManagerUtil.GetNumPresets)
	self:HookEvent("ENCHANTCOLLECTION_LOADED")

	function self.PopupController.UpdateValues(popup, text, texture)
		dprint(self:GetName())
		MysticEnchantManagerUtil.UpdatePresetData(text, texture)
		self:Refresh()
	end
end

function ECSpecManagerMixin:OnSelectPreset(index)
	PlaySound("igMainMenuOptionCheckBoxOn")
	PlaySound(SOUNDKIT.MAGICCLICK)

	if (index > C_MysticEnchantPreset.GetNumPresets()) then
		MysticEnchantManagerUtil.AttemptOperation("Unlock", "CanUnlock")
	elseif (MysticEnchantManagerUtil.GetActivePreset() ~= index) then
		self:GetParent():SetPreset(index)
		self:Hide()
	end
end

function ECSpecManagerMixin:EditPresetData(index)
    MysticEnchantManagerUtil.SetEditablePreset(index)

    self.PopupController.frame:Hide()

    if MysticEnchantManagerUtil.GetActualPresetName(index) then
        self.PopupController:EditExisting(MysticEnchantManagerUtil.GetActualPresetName(index), MysticEnchantManagerUtil.GetActualPresetIcon(index))
    else
        self.PopupController:CreateNew()
    end
end

function ECSpecManagerMixin:InitScroll()
	self.ScrollList:SetTemplate("EnchantCollectionManagerListItem")
end

function ECSpecManagerMixin:OnShow()
	if not(self.ScrollList.isInitialized) then
		self:InitScroll()
	end

	self:HookEvent("MYSTIC_ENCHANT_PRESET_UNLOCK_RESULT")
	self:HookEvent("MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT")

	self:Refresh()
end

function ECSpecManagerMixin:OnHide()
	self:UnhookEvent("MYSTIC_ENCHANT_PRESET_UNLOCK_RESULT")
	self:UnhookEvent("MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT")
end

function ECSpecManagerMixin:Refresh()
	if (self.ScrollList.isInitialized) then
		self.ScrollList:RefreshScrollFrame()
	end
end

function ECSpecManagerMixin:ENCHANTCOLLECTION_LOADED()
    self:UnhookEvent("ENCHANTCOLLECTION_LOADED")
end

function ECSpecManagerMixin:MYSTIC_ENCHANT_PRESET_UNLOCK_RESULT()
	self:Refresh()
end

function ECSpecManagerMixin:MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT()
	self:Refresh()
end

function ECSpecManagerMixin:Layout()
	self:SetSize(275,416)
	self.title:SetText(ENCHANT_SPECIALIZATIONS)

	self.ScrollList = CreateFrame("FRAME", "$parent.ScrollsTab", self, "ScrollListTemplate")
	self.ScrollList:SetPoint("TOPLEFT", 8, -26)
	self.ScrollList:SetPoint("BOTTOMRIGHT", -4, 7)

	--[[self.ScrollList:GetSelectedHighlight():SetAtlas("pvpqueue-button-casual-selected", Const.TextureKit.IgnoreAtlasSize)
	self.ScrollList:GetSelectedHighlight():SetSize(240,54)
	self.ScrollList:GetSelectedHighlight():SetBlendMode("ADD")]]--
	self.ScrollList:GetSelectedHighlight():SetTexture("")

	self.PopupController = IconSelectCreateFrame(self:GetName()..".PopupController", self, {"TOPLEFT", self, "TOPRIGHT", 8, 0 })
end
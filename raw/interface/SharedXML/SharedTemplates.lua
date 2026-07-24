BorderIconTemplateMixin = {}

function BorderIconTemplateMixin:SetRounded(rounded)
	if rounded then
		self:SetIconMask(TextureUtil.DefaultMask)
	else
		self:SetIconMask()
	end
end

function BorderIconTemplateMixin:SetIconMask(mask, maskSize)
	self.iconMask = mask
	self.iconMaskSize = maskSize

	if self.iconTexture then
		if mask then
			self.Icon:SetMaskedTexture(self.iconTexture, mask, maskSize)
		else
			self.Icon:SetTexture(self.iconTexture)
		end
	end
end

function BorderIconTemplateMixin:SetIcon(icon)
	if not icon or icon:len() == 0 then
		self.icon = nil
		self.Icon:SetTexture(nil)
		self.IconBorder:SetTexture(nil)
		return
	end

	self.Icon:SetTexCoord(0, 1, 0, 1)
	self.iconTexture = icon
	if self.iconMask then
		self.Icon:SetMaskedTexture(self.iconTexture, self.iconMask, self.iconMaskSize)
	else
		self.Icon:SetTexture(self.iconTexture)
	end
end 

function BorderIconTemplateMixin:SetIconAtlas(atlas, useAtlasSize)
	self.iconTexture = nil
	self.iconMask = nil
	self.iconMaskSize = nil
	self.Icon:SetAtlas(atlas, useAtlasSize)
end

function BorderIconTemplateMixin:GetIcon()
	return self.iconTexture
end

function BorderIconTemplateMixin:SetIconDesaturated(desaturated)
	self.Icon:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetIconColor(r, g, b, a)
	self.Icon:SetVertexColor(r, g, b, a)
end

function BorderIconTemplateMixin:SetIconBlendMode(blendMode)
	self.Icon:SetBlendMode(blendMode)
end

function BorderIconTemplateMixin:SetBorderMask(mask, maskSize)
	self.borderMask = mask
	self.borderMaskSize = maskSize

	if self.borderTexture then
		if mask then
			self.IconBorder:SetMaskedTexture(self.borderTexture, mask, maskSize)
		else
			self.IconBorder:SetTexture(self.borderTexture)
		end
	end
end

function BorderIconTemplateMixin:SetBorderTexture(texture)
	self.borderTexture = texture
	if not texture then
		self.IconBorder:SetTexture(nil)
		return
	end
	self.IconBorder:SetTexCoord(0, 1, 0, 1)
	if self.borderMask then
		self.IconBorder:SetMaskedTexture(self.borderTexture, self.borderMask, self.borderMaskSize)
	else
		self.IconBorder:SetTexture(self.borderTexture)
	end
end

function BorderIconTemplateMixin:SetBorderAtlas(atlas, useAtlasSize)
	self.borderTexture = nil
	self.borderMask = nil
	self.borderMaskSize = nil
	if useAtlasSize then
		self.IconBorder:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("borderOffsetX") or 0, self:GetAttribute("borderOffsetY") or 0)
	end
	self.IconBorder:SetAtlas(atlas, useAtlasSize)
end

function BorderIconTemplateMixin:SetBorderDesaturated(desaturated)
	self.IconBorder:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetBorderColor(r, g, b, a)
	self.IconBorder:SetVertexColor(r, g, b, a)
end

function BorderIconTemplateMixin:SetBorderBlendMode(blendMode)
	self.IconBorder:SetBlendMode(blendMode)
end

function BorderIconTemplateMixin:SetBorderInset(left, right, top, bottom)
	self.IconBorder:SetPoint("TOPLEFT", left, -top)
	self.IconBorder:SetPoint("BOTTOMRIGHT", -right, bottom)
end

function BorderIconTemplateMixin:SetOverlayMask(mask, maskSize)
	self.overlayMask = mask
	self.overlayMaskSize = maskSize

	if self.overlayTexture then
		if mask then
			self.Overlay:SetMaskedTexture(self.overlayTexture, mask, maskSize)
		else
			self.Overlay:SetTexture(self.overlayTexture)
		end
	end
end

function BorderIconTemplateMixin:SetOverlayTexture(texture)
	self.overlayTexture = texture
	if not texture then
		self.Overlay:SetTexture(nil)
		return
	end
	self.Overlay:SetTexCoord(0, 1, 0, 1)
	if self.overlayMask then
		self.Overlay:SetMaskedTexture(self.overlayTexture, self.overlayMask, self.overlayMaskSize)
	else
		self.Overlay:SetTexture(self.overlayTexture)
	end
end

function BorderIconTemplateMixin:SetOverlayAtlas(atlas, useAtlasSize)
	self.overlayTexture = nil
	self.overlayMask = nil
	self.overlayMaskSize = nil
	if useAtlasSize then
		self.Overlay:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("overlayOffsetX") or 0, self:GetAttribute("overlayOffsetY") or 0)
	end
	self.Overlay:SetAtlas(atlas, useAtlasSize)
end

function BorderIconTemplateMixin:SetOverlayDesaturated(desaturated)
	self.Overlay:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetOverlayColor(r, g, b, a)
	self.Overlay:SetVertexColor(r, g, b, a)
end

function BorderIconTemplateMixin:SetOverlayBlendMode(blendMode)
	self.Overlay:SetBlendMode(blendMode)
end

function BorderIconTemplateMixin:SetOverlayInset(left, right, top, bottom)
	self.Overlay:SetPoint("TOPLEFT", left, -top)
	self.Overlay:SetPoint("BOTTOMRIGHT", -right, bottom)
end

function BorderIconTemplateMixin:SetBackgroundMask(mask, maskSize)
	self.backgroundMask = mask
	self.backgroundMaskSize = maskSize

	if self.backgroundTexture then
		if mask then
			self.Background:SetMaskedTexture(self.backgroundTexture, mask, maskSize)
		else
			self.Background:SetTexture(self.backgroundTexture)
		end
	end
end

function BorderIconTemplateMixin:SetBackgroundTexture(texture)
	self.backgroundTexture = texture
	if not texture then
		self.Background:SetTexture(nil)
		return
	end
	self.Background:SetTexCoord(0, 1, 0, 1)
	if self.backgroundMask then
		self.Background:SetMaskedTexture(self.backgroundTexture, self.backgroundMask, self.backgroundMaskSize)
	else
		self.Background:SetTexture(self.backgroundTexture)
	end
end

function BorderIconTemplateMixin:SetBackgroundAtlas(atlas, useAtlasSize)
	self.backgroundTexture = nil
	self.backgroundMask = nil
	self.backgroundMaskSize = nil
	if useAtlasSize then
		self.Background:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("backgroundOffsetX") or 0, self:GetAttribute("backgroundOffsetY") or 0)
	end
	self.Background:SetAtlas(atlas, useAtlasSize)
end

function BorderIconTemplateMixin:SetBackgroundDesaturated(desaturated)
	self.Background:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetBackgroundColor(r, g, b, a)
	self.Background:SetVertexColor(r, g, b, a)
end

function BorderIconTemplateMixin:SetBackgroundBlendMode(blendMode)
	self.Background:SetBlendMode(blendMode)
end

function BorderIconTemplateMixin:SetBackgroundInset(left, right, top, bottom)
	self.Background:SetPoint("TOPLEFT", left, -top)
	self.Background:SetPoint("BOTTOMRIGHT", -right, bottom)
end

function BorderIconTemplateMixin:SetHighlightMask(mask, maskSize)
	self.highlightMask = mask
	self.highlightMaskSize = maskSize

	if self.highlightTexture then
		if mask then
			self.Highlight:SetMaskedTexture(self.highlightTexture, mask, maskSize)
		else
			self.Highlight:SetTexture(self.highlightTexture)
		end
	end
end

function BorderIconTemplateMixin:SetHighlightTexture(texture)
	self.highlightTexture = texture
	if not texture then
		self.Highlight:SetTexture(nil)
		return
	end
	self.Highlight:SetTexCoord(0, 1, 0, 1)
	if self.highlightMask then
		self.Highlight:SetMaskedTexture(self.highlightTexture, self.highlightMask, self.highlightMaskSize)
	else
		self.Highlight:SetTexture(self.highlightTexture)
	end
end

function BorderIconTemplateMixin:SetHighlightAtlas(atlas, useAtlasSize)
	self.highlightTexture = nil
	self.highlightMask = nil
	self.highlightMaskSize = nil
	if useAtlasSize then
		self.Highlight:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("highlightOffsetX") or 0, self:GetAttribute("highlightOffsetY") or 0)
	end
	self.Highlight:SetAtlas(atlas, useAtlasSize)
end

function BorderIconTemplateMixin:SetHighlightDesaturated(desaturated)
	self.Highlight:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetHighlightColor(r, g, b, a)
	self.Highlight:SetVertexColor(r, g, b, a)
end

function BorderIconTemplateMixin:SetHighlightBlendMode(blendMode)
	self.Highlight:SetBlendMode(blendMode)
end

function BorderIconTemplateMixin:SetHighlightInset(left, right, top, bottom)
	self.Highlight:SetPoint("TOPLEFT", left, -top)
	self.Highlight:SetPoint("BOTTOMRIGHT", -right, bottom)
end

function BorderIconTemplateMixin:SetBorderSize(width, height)
	self.IconBorder:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("borderOffsetX") or 0, self:GetAttribute("borderOffsetY") or 0)
	self.IconBorder:SetSize(width, height)
end

function BorderIconTemplateMixin:SetBorderOffset(x, y)
	self:SetAttribute("borderOffsetX", x)
	self:SetAttribute("borderOffsetY", y)
	self.IconBorder:SetSize(self.IconBorder:GetSize())
	self.IconBorder:ClearAndSetPoint("CENTER", self.Icon, "CENTER", x, y)
end

function BorderIconTemplateMixin:SetOverlaySize(width, height)
	self.Overlay:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("overlayOffsetX") or 0, self:GetAttribute("overlayOffsetY") or 0)
	self.Overlay:SetSize(width, height)
end

function BorderIconTemplateMixin:SetOverlayOffset(x, y)
	self:SetAttribute("overlayOffsetX", x)
	self:SetAttribute("overlayOffsetY", y)
	self.Overlay:SetSize(self.Overlay:GetSize())
	self.Overlay:ClearAndSetPoint("CENTER", self.Icon, "CENTER", x, y)
end

function BorderIconTemplateMixin:SetBackgroundSize(width, height)
	self.Background:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("backgroundOffsetX") or 0, self:GetAttribute("backgroundOffsetY") or 0)
	self.Background:SetSize(width, height)
end

function BorderIconTemplateMixin:SetBackgroundOffset(x, y)
	self:SetAttribute("backgroundOffsetX", x)
	self:SetAttribute("backgroundOffsetY", y)
	self.Background:SetSize(self.Background:GetSize())
	self.Background:ClearAndSetPoint("CENTER", self.Icon, "CENTER", x, y)
end

function BorderIconTemplateMixin:SetHighlightSize(width, height)
	self.Highlight:ClearAndSetPoint("CENTER", self.Icon, "CENTER", self:GetAttribute("highlightOffsetX") or 0, self:GetAttribute("highlightOffsetY") or 0)
	self.Highlight:SetSize(width, height)
end

function BorderIconTemplateMixin:SetHighlightOffset(x, y)
	self:SetAttribute("highlightOffsetX", x)
	self:SetAttribute("highlightOffsetY", y)
	self.Highlight:SetSize(self.Highlight:GetSize())
	self.Highlight:ClearAndSetPoint("CENTER", self.Icon, "CENTER", x, y)
end

function BorderIconTemplateMixin:SetIconDesaturated(desaturated)
	self.Icon:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetBorderDesaturated(desaturated)
	self.IconBorder:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetOverlayDesaturated(desaturated)
	self.Overlay:SetDesaturated(desaturated)
end

function BorderIconTemplateMixin:SetOverlayAlpha(alpha)
	self.Overlay:SetAlpha(alpha)
end

function BorderIconTemplateMixin:SetBorderAlpha(alpha)
	self.IconBorder:SetAlpha(alpha)
end

function BorderIconTemplateMixin:SetBackgroundAlpha(alpha)
	self.Background:SetAlpha(alpha)
end

function BorderIconTemplateMixin:SetHighlightAlpha(alpha)
	self.Highlight:SetAlpha(alpha)
end

function BorderIconTemplateMixin:SetDesaturated(desaturated)
	self:SetIconDesaturated(desaturated)
	self:SetBorderDesaturated(desaturated)
	self:SetOverlayDesaturated(desaturated)
end

SpellIconTemplateMixin = CreateFromMixins(BorderIconTemplateMixin, CallbackRegistryMixin)

function SpellIconTemplateMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({ "OnSpellChanged" })
end

function SpellIconTemplateMixin:SetSpell(spellID)
	if not spellID or spellID <= 0 then
		self.spell = nil
		self:SetIcon()
		return
	end

	self.spell = Spell:CreateFromID(spellID)
	self:SetIcon(select(3, GetSpellInfo(spellID)))
	if self.useQuality then
		local quality = C_CharacterAdvancement.GetQualityInfo(self.spell.spellID)
		self:SetQuality(quality)
	end

	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end

	self:TriggerEvent("OnSpellChanged", self.spell)
end

function SpellIconTemplateMixin:GetSpell()
	return self.spell
end

function SpellIconTemplateMixin:GetSpellID()
	return self.spell and self.spell.spellID
end

function SpellIconTemplateMixin:SetCharacterAdvancementEntry(entry)
	if type(entry) == "number" then
		entry = C_CharacterAdvancement.GetEntryByInternalID(entry)
	end
	if not entry then
		self.spell = nil
		self:SetIcon()
		return
	end

	local spellID = entry.Spells[1]

	if entry.Type == "Talent" or entry.Type == "TalentAbility" then
		if BuildCreatorUtil.IsPickingSpells() then
			for _, entrySpellID in ipairs(entry.Spells) do
				if C_BuildEditor.DoesBuildHaveSpellID(entrySpellID) then
					spellID = entrySpellID
				else
					break
				end
			end
		else
			local rank = C_CharacterAdvancement.GetTalentRankByID(entry.ID)
			if rank and rank > 0 then
				spellID = entry.Spells[rank]
			end
		end
	end

	self.spell = Spell:CreateFromID(spellID)
	self:SetIcon("Interface\\Icons\\"..entry.Icon)
	if self.useQuality then
		local quality = C_CharacterAdvancement.GetQualityInfo(spellID)
		self:SetQuality(quality)
	end

	if GameTooltip:IsOwned(self) then
		self:OnEnter()
	end

	self:TriggerEvent("OnSpellChanged", self.spell)
end

function SpellIconTemplateMixin:SetQuality(quality)
	if quality and quality > Enum.SpellQuality.Common then
		local atlas = QUICKSLOT_QUALITY_BORDER_ATLAS[quality]
		self:SetBorderAtlas(atlas)
		self:SetOverlayAtlas(atlas)
	else
		local atlas = QUICKSLOT_QUALITY_BORDER_ATLAS[Enum.SpellQuality.Poor]
		self:SetBorderAtlas(atlas)
		self:SetOverlayAtlas(nil)
	end
end

function SpellIconTemplateMixin:OnEnter()
	if self.spell then
		local tooltip = GameTooltip or GlueTooltip
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
		tooltip:SetHyperlink("spell:" .. self.spell.spellID)
	else
		GameTooltip_GenericTooltip(self)
	end
end 

function SpellIconTemplateMixin:OnLeave()
	local tooltip = GameTooltip or GlueTooltip
	tooltip:Hide()
end

function SpellIconTemplateMixin:OnClick()
	if self.spell then
		if IsModifiedClick("CHATLINK") then
			local link = GetSpellLink(self.spell.spellID)
			if link then
				ChatEdit_InsertLink(link)
			end
		elseif self.OnClickHandler then
			self:OnClickHandler()
		end
	end
end

function SpellIconTemplateMixin:OnDragStart()
	if self.DragEnabled and self.spell.spellID then
		local entry = C_CharacterAdvancement.GetEntryBySpellID(self.spell.spellID)
		if entry then
			C_CharacterAdvancement.PickupSpell(entry.ID)
		else
			local spellName = GetSpellInfo(self.spell.spellID)
			if spellName then
				PickupSpell(spellName)
			end
		end
	end
end

function SpellIconTemplateMixin:EnableDrag()
	self:RegisterForDrag("LeftButton")
	self.DragEnabled = true
end

function SpellIconTemplateMixin:DisableDrag()
	self:RegisterForDrag()
	self.DragEnabled = nil
end

function SpellIconTemplateMixin:UseQuality(useQuality)
	self.useQuality = useQuality
	if useQuality then
		self:SetOverlayBlendMode("ADD")
	end

	if self.spell and self:IsVisible() then
		self:SetSpell(self.spell.spellID)
	end
end

ItemIconTemplateMixin = CreateFromMixins(BorderIconTemplateMixin, CallbackRegistryMixin)

function ItemIconTemplateMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({ "OnItemChanged" })
end

function ItemIconTemplateMixin:SetCount(amount)
	if not amount or amount <= 1 then
		self.Count:SetText("")
	else
		self.Count:SetText(amount)
	end
end

function ItemIconTemplateMixin:SetItem(itemID, amount)
	if not itemID or itemID <= 0 then
		self.item = nil
		self:SetIcon()
		self:SetCount(0)
		return
	end

	self.item = Item:CreateFromID(itemID)
	
	self:SetIcon(self.item:GetIcon())
	self:SetCount(amount)

	if self:IsMouseOver() then
		self:OnEnter()
	end
	self:TriggerEvent("OnItemChanged", self.item)
end

function ItemIconTemplateMixin:OnEnter()
	if self.item then
		local tooltip = GameTooltip or GlueTooltip
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
		tooltip:SetHyperlink("item:" .. self.item.itemID)
	else
		GameTooltip_GenericTooltip(self)
	end
end

function ItemIconTemplateMixin:OnLeave()
	local tooltip = GameTooltip or GlueTooltip
	tooltip:Hide()
end

function ItemIconTemplateMixin:OnClick()
	if self.item then
		if IsModifiedClick("CHATLINK") then
			local link = GetItemLink(self.item.itemID)
			if link then
				ChatEdit_InsertLink(link)
			end
		elseif self.OnClickHandler then
			self:OnClickHandler()
		end
	end
end

CooldownItemIconTemplateMixin = CreateFromMixins(ItemIconTemplateMixin)

function CooldownItemIconTemplateMixin:OnLoad()
	ItemIconTemplateMixin.OnLoad(self)
end

function CooldownItemIconTemplateMixin:SetItem(itemID, amount)
	ItemIconTemplateMixin.SetItem(self, itemID, amount)
	if self:IsShown() then
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		self:RegisterEvent("BAG_UPDATE_COOLDOWN")
		self:UpdateCooldown()
	end
end

function CooldownItemIconTemplateMixin:OnShow()
	if not self.item then return end
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:UpdateCooldown()
end

function CooldownItemIconTemplateMixin:OnHide()
	self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
end

function CooldownItemIconTemplateMixin:OnEvent()
	self:UpdateCooldown()
end

function CooldownItemIconTemplateMixin:UpdateCooldown()
	if not self.item then
		return self.Cooldown:Hide()
	end
	local start, duration, enable = GetItemCooldown(self.item:GetItemID())
	if start and start > 0 and duration and duration > 0 and enable and enable > 0 then
		self.Cooldown:SetCooldown(start, duration)
		self.Cooldown:Show()
	else
		self.Cooldown:Hide()
	end
end 

-- 
-- AnimatedMagicRingMixin
--
AnimatedMagicRingMixin = {}

function AnimatedMagicRingMixin:PlaySplash()
	self.Unlock.Splash:Stop()
	self.Unlock.Splash:Play()
	self.Splash.Splash:Stop()
	self.Splash.Splash:Play()
end 

function AnimatedMagicRingMixin:OnShow()
	self:Play()
end

function AnimatedMagicRingMixin:OnHide()
	self:Stop()
end

function AnimatedMagicRingMixin:Play()
	self.Ring.Animation:Play()
	self.Ring.Breathe:Play()
	self.Unlock.Animation:Play()
	self.Splash.Animation:Play()
	self.Add.Animation:Play()
end 

function AnimatedMagicRingMixin:Stop()
	self.Ring.Animation:Stop()
	self.Ring.Breathe:Stop()
	self.Unlock.Animation:Stop()
	self.Splash.Animation:Stop()
	self.Add.Animation:Stop()
end
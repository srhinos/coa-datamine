MysticEnchantPanelMixin = CreateFromMixins(ScrollListMixin)

local function SortEnchants(a, b)
	if a.quality == b.quality then
		if a.count == b.count then
			return (GetSpellInfo(a.spellID) or UNKNOWN) < (GetSpellInfo(b.spellID) or UNKNOWN)
		end
		return a.count > b.count
	end
	return a.quality > b.quality
end
	

function MysticEnchantPanelMixin:OnLoad()
	self.enchants = {}
	self:SetTemplate("MysticEnchantPanelItemTemplate")
	self:SetGetNumResultsFunction(function() return #self.enchants end)
	self:SetCanSelect(false)
	self.unit = "player"
end

function MysticEnchantPanelMixin:OnShow()
	self.Background:SetAtlas(GetCharacterFrameSidePanelBackgroundAtlas(self.unit))
	self:RegisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")
	self:RefreshScrollFrame()
end

function MysticEnchantPanelMixin:OnHide()
	self:UnregisterEvent("MYSTIC_ENCHANT_SLOT_UPDATE")
	wipe(self.enchants)
end

function MysticEnchantPanelMixin:OnEvent(event)
	self:RefreshScrollFrame()
end

function MysticEnchantPanelMixin:SetUnit(unit)
	self.unit = unit
	if self:IsShown() then
		self:RefreshScrollFrame()
	end
end

function MysticEnchantPanelMixin:GetEnchantInfo(index)
	local info = self.enchants[index]
	if info then
		return info.spellID, info.count, info.quality
	end
end

function MysticEnchantPanelMixin:RefreshScrollFrame()
	wipe(self.enchants)
	local enchants = MysticEnchantUtil.GetAppliedEnchantCountByQuality(self.unit or "player")
	local totalCount = 0
	for quality, spells in pairs(enchants) do
		for spellID, count in pairs(spells) do
			tinsert(self.enchants, { spellID = spellID, count = count, quality = quality })
			totalCount = totalCount + count
		end
	end

	table.sort(self.enchants, SortEnchants)

	if totalCount < NUM_MYSTIC_ENCHANT_SLOTS then
		tinsert(self.enchants, 1, { spellID = nil, count = NUM_MYSTIC_ENCHANT_SLOTS - totalCount, quality = 0 })
	end

	RunNextFrame(function()
		ScrollListMixin.RefreshScrollFrame(self)
	end)
end

--
-- Mystic Enchant Panel Item
--
MysticEnchantPanelItemMixin = CreateFromMixins(ScrollListItemBaseMixin)
MysticEnchantPanelItemMixin.OnSelected = nop

function MysticEnchantPanelItemMixin:Init()
	ScrollListItemBaseMixin.Init(self)
	self:SetHighlightAtlas("EnchantSlotBorderHighlight", true)
	self:SetNormalAtlas("UI-Character-Info-ItemLevel-Bounce")
	self:GetNormalTexture():SetVertexColor(0.5, 0.5, 1)
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
end

function MysticEnchantPanelItemMixin:Update()
	local spellID, count, quality = self:GetScrollList():GetEnchantInfo(self.index)
	self.spellID = spellID

	self:GetNormalTexture():SetAlpha(self.index % 2 == 0 and 1 or 0.4)

	if not spellID then
		-- empty slot!
		self.Icon:SetAtlas("EnchantSlotBorderUnknownNormal", Const.TextureKit.UseAtlasSize)
		self.QualityBorder:SetTexture()
		self:SetText(MYSTIC_ENCHANT_SLOT_EMPTY)
		self.Count:SetFormattedText("x%d", count)
		return
	end
	
	local name, _, icon = GetSpellInfo(spellID)
	self:SetText(ITEM_QUALITY_COLORS[quality]:WrapText(name))
	self.Count:SetFormattedText("x%d", count)
	self.Icon:SetSize(32, 32)
	self.Icon:SetPortraitTexture(icon)
	self.QualityBorder:SetAtlas(Enum.ECSlotBorderStylesKnown[quality], Const.TextureKit.UseAtlasSize)
end

function MysticEnchantPanelItemMixin:OnEnter()
	if self.spellID then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("spell:"..self.spellID)
		GameTooltip:Show()
	end
end

function MysticEnchantPanelItemMixin:OnLeave()
	GameTooltip:Hide()
end


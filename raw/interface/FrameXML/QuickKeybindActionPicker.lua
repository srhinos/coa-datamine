local ICONS_PER_ROW = 6
local ICON_SIZE = 36
local ICON_SPACING = 4
local ICON_STEP = ICON_SIZE + ICON_SPACING
local MAX_ACCOUNT_MACROS = 36
local MAX_CHARACTER_MACROS = 18
local CATEGORY_WIDTH = 155
local CATEGORY_HEIGHT = 32
local CATEGORY_SPACING = 2
local TOP_PAD = 32
local BOTTOM_PAD = 14
local MIN_ROWS = 5

local CATEGORY_TYPE_SPELL = 1
local CATEGORY_TYPE_GLOBAL_MACRO = 2
local CATEGORY_TYPE_CHARACTER_MACRO = 3
local CATEGORY_TYPE_ITEM = 4

local SELECTED_COLOR = {r = 1, g = 0.87, b = 0.3}
local NORMAL_COLOR = {r = 0.95, g = 0.85, b = 0.65}

----------------------------------------------------------------
-- Main Picker Mixin
----------------------------------------------------------------
QuickKeybindActionPickerMixin = {}

function QuickKeybindActionPickerMixin:OnLoad()
	self.categories = {}
	self.currentActions = {}
	self.targetSlot = nil
	self.targetButton = nil
	self.selectedCategoryIndex = nil
	self.categoryButtons = {}

	self.ActionGrid:SetGetNumResultsFunction(function()
		return math.ceil(#self.currentActions / ICONS_PER_ROW)
	end)

	EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", self.Hide, self)
end

function QuickKeybindActionPickerMixin:OnShow()
	PlaySound(SOUNDKIT.CHARACTER_SHEET_OPEN)
end

function QuickKeybindActionPickerMixin:OnHide()
	self:SetScript("OnUpdate", nil)
	PlaySound(SOUNDKIT.CHARACTER_SHEET_CLOSE)
	self.targetSlot = nil
	self.targetButton = nil
end

function QuickKeybindActionPickerMixin:OpenForButton(actionButton)
	local slot = actionButton.action
	if not slot or slot <= 0 then return end

	self.targetSlot = slot
	self.targetButton = actionButton

	self:ClearAllPoints()
	self:SetPoint("BOTTOM", actionButton, "TOP", 0, 4)

	self:BuildCategories()
	self:ResizeToCategories()
	self:Show()

	-- Defer grid init to next frame so anchor layout resolves for the action grid
	self:SetScript("OnUpdate", function(s)
		s:SetScript("OnUpdate", nil)

		if not s.gridInitialized then
			s.gridInitialized = true
			s.ActionGrid:SetTemplate("QuickKeybindActionGridRowTemplate")
			s.ActionGrid:GetSelectedHighlight():SetTexture("")
		end

		-- Select first or previous category
		local selectIndex = s.selectedCategoryIndex or 1
		if selectIndex > #s.categories then selectIndex = 1 end
		if #s.categories > 0 then
			s:SelectCategory(selectIndex)
		end
	end)
end

function QuickKeybindActionPickerMixin:ResizeToCategories()
	local numRows = math.max(#self.categories, MIN_ROWS)
	local rowStride = CATEGORY_HEIGHT + CATEGORY_SPACING
	self:SetHeight(TOP_PAD + numRows * rowStride - CATEGORY_SPACING + BOTTOM_PAD)
end

function QuickKeybindActionPickerMixin:BuildCategories()
	wipe(self.categories)

	-- Spellbook tabs
	for tab = 1, GetNumSpellTabs() do
		local name, texture, offset, numSpells = GetSpellTabInfo(tab)
		if name and numSpells and numSpells > 0 then
			table.insert(self.categories, {
				type = CATEGORY_TYPE_SPELL,
				name = name,
				icon = texture,
				tabOffset = offset,
				tabNumSpells = numSpells,
			})
		end
	end

	-- Global Macros
	table.insert(self.categories, {
		type = CATEGORY_TYPE_GLOBAL_MACRO,
		name = "Global Macros",
		icon = "Interface\\Icons\\INV_Misc_Note_01",
	})

	-- Character Macros
	table.insert(self.categories, {
		type = CATEGORY_TYPE_CHARACTER_MACRO,
		name = "Character Macros",
		icon = "Interface\\Icons\\INV_Misc_Note_02",
	})

	-- Items
	table.insert(self.categories, {
		type = CATEGORY_TYPE_ITEM,
		name = "Items",
		icon = "Interface\\Icons\\INV_Misc_Bag_08",
	})

	self:RefreshCategoryList()
end

function QuickKeybindActionPickerMixin:RefreshCategoryList()
	-- Create or reuse category buttons
	for i, category in ipairs(self.categories) do
		local btn = self.categoryButtons[i]
		if not btn then
			btn = CreateFrame("Button", nil, self.CategoryList)
			btn:SetSize(CATEGORY_WIDTH, CATEGORY_HEIGHT)
			btn.layoutIndex = i
			btn.bottomPadding = CATEGORY_SPACING

			-- Normal background (dark brown panel)
			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetAtlas("buildcreator-category")
			btn.Bg = bg

			-- Selected background (bright bordered panel), shown on top of normal
			local selected = btn:CreateTexture(nil, "ARTWORK")
			selected:SetAllPoints()
			selected:SetAtlas("buildcreator-category-currentbuild")
			selected:Hide()
			btn.SelectedTexture = selected

			-- Highlight overlay (golden border glow) shown on mouseover
			local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
			highlight:SetAllPoints()
			highlight:SetAtlas("buildcreator-category-highlight")
			highlight:SetBlendMode("ADD")
			highlight:SetAlpha(0.85)

			-- Rounded icon with gold ring border via BorderIconTemplate.
			-- The template layers Icon at BORDER and IconBorder above it, so
			-- the ring always renders correctly around the masked icon.
			local iconFrame = CreateFrame("Frame", nil, btn, "BorderIconTemplate")
			iconFrame:SetSize(24, 24)
			iconFrame:SetPoint("LEFT", 8, 0)
			iconFrame:SetRounded(true)
			iconFrame:SetBorderAtlas("bluemenu-Ring")
			iconFrame:SetBorderInset(-5, -5, -5, -5)
			btn.IconFrame = iconFrame

			local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			text:SetPoint("LEFT", 36, 0)
			text:SetPoint("RIGHT", -8, 0)
			text:SetJustifyH("LEFT")
			text:SetWordWrap(false)
			btn.Text = text

			btn:SetScript("OnClick", function(b)
				PlaySound("UChatScrollButton")
				QuickKeybindActionPickerFrame:SelectCategory(b.categoryIndex)
			end)

			self.categoryButtons[i] = btn
		end

		btn.categoryIndex = i
		btn.Text:SetText(category.name)
		if category.icon then
			btn.IconFrame:SetIcon(category.icon)
			btn.IconFrame:Show()
		else
			btn.IconFrame:Hide()
		end
		btn.SelectedTexture:Hide()
		btn.Text:SetTextColor(NORMAL_COLOR.r, NORMAL_COLOR.g, NORMAL_COLOR.b)
		btn:Show()
	end

	-- Hide excess buttons
	for i = #self.categories + 1, #self.categoryButtons do
		self.categoryButtons[i]:Hide()
		self.categoryButtons[i].layoutIndex = nil
	end

	self.CategoryList:Layout()
end

function QuickKeybindActionPickerMixin:SelectCategory(index)
	-- Deselect old
	if self.selectedCategoryIndex and self.categoryButtons[self.selectedCategoryIndex] then
		local oldBtn = self.categoryButtons[self.selectedCategoryIndex]
		oldBtn.SelectedTexture:Hide()
		oldBtn.Text:SetTextColor(NORMAL_COLOR.r, NORMAL_COLOR.g, NORMAL_COLOR.b)
	end

	self.selectedCategoryIndex = index

	-- Highlight new
	local btn = self.categoryButtons[index]
	if btn then
		btn.SelectedTexture:Show()
		btn.Text:SetTextColor(SELECTED_COLOR.r, SELECTED_COLOR.g, SELECTED_COLOR.b)
	end

	local category = self.categories[index]
	if category then
		self:LoadActionsForCategory(category)
	end
end

function QuickKeybindActionPickerMixin:LoadActionsForCategory(category)
	wipe(self.currentActions)

	if category.type == CATEGORY_TYPE_SPELL then
		self:LoadSpellTab(category.tabOffset, category.tabNumSpells)
	elseif category.type == CATEGORY_TYPE_GLOBAL_MACRO then
		self:LoadMacros(1, MAX_ACCOUNT_MACROS)
	elseif category.type == CATEGORY_TYPE_CHARACTER_MACRO then
		self:LoadMacros(MAX_ACCOUNT_MACROS + 1, MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS)
	elseif category.type == CATEGORY_TYPE_ITEM then
		self:LoadUsableItems()
	end

	if self.gridInitialized then
		self.ActionGrid:Reset()
		self.ActionGrid:RefreshScrollFrame()
	end
end

function QuickKeybindActionPickerMixin:LoadSpellTab(offset, numSpells)
	for i = 1, numSpells do
		local bookIndex = offset + i
		local spell, rank = GetSpellName(bookIndex, BOOKTYPE_SPELL)
		if spell then
			local isPassive = IsPassiveSpell(bookIndex, BOOKTYPE_SPELL)
			if not isPassive then
				local name, _, icon = GetSpellInfo(spell, rank)
				local spellID
				if C_Spell and C_Spell.GetSpellID then
					spellID = C_Spell:GetSpellID(spell, rank)
				end
				local quality
				if spellID and C_CharacterAdvancement and C_CharacterAdvancement.GetQualityInfo then
					quality = C_CharacterAdvancement.GetQualityInfo(spellID)
				end
				if icon then
					table.insert(self.currentActions, {
						type = "spell",
						spellID = spellID,
						bookIndex = bookIndex,
						name = name or spell,
						icon = icon,
						quality = quality,
					})
				end
			end
		end
	end
end

function QuickKeybindActionPickerMixin:LoadMacros(startIndex, endIndex)
	for i = startIndex, endIndex do
		local name, icon = GetMacroInfo(i)
		if name then
			table.insert(self.currentActions, {
				type = "macro",
				macroIndex = i,
				name = name,
				icon = icon,
			})
		end
	end
end

function QuickKeybindActionPickerMixin:LoadUsableItems()
	local seen = {}

	-- Equipped trinkets
	for _, slotID in ipairs({13, 14}) do
		local itemID = GetInventoryItemID("player", slotID)
		if itemID and not seen[itemID] then
			local name, _, itemQuality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
			if name then
				seen[itemID] = true
				table.insert(self.currentActions, {
					type = "item",
					itemID = itemID,
					name = name,
					icon = icon,
					quality = itemQuality,
				})
			end
		end
	end

	-- Bag items with use effects
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemID = GetContainerItemID(bag, slot)
			if itemID and not seen[itemID] then
				local spellName = GetItemSpell(itemID)
				if spellName then
					local name, _, itemQuality, _, _, _, _, _, _, icon = GetItemInfo(itemID)
					if name then
						seen[itemID] = true
						table.insert(self.currentActions, {
							type = "item",
							itemID = itemID,
							name = name,
							icon = icon,
							quality = itemQuality,
						})
					end
				end
			end
		end
	end
end

function QuickKeybindActionPickerMixin:PlaceActionInSlot(actionData)
	if not self.targetSlot then return end

	ClearCursor()

	if actionData.type == "spell" then
		PickupSpell(actionData.bookIndex, BOOKTYPE_SPELL)
	elseif actionData.type == "macro" then
		PickupMacro(actionData.macroIndex)
	elseif actionData.type == "item" then
		PickupItem(actionData.itemID)
	end

	PlaceAction(self.targetSlot)
	ClearCursor()

	if self.gridInitialized then
		self.ActionGrid:RefreshScrollFrame()
	end
end

function QuickKeybindActionPickerMixin:IsActionInTargetSlot(actionData)
	if not self.targetSlot then return false end

	local actionType, actionID, _, extraID = GetActionInfo(self.targetSlot)

	if actionData.type == "spell" and actionType == "spell" then
		return extraID == actionData.spellID
	elseif actionData.type == "macro" and actionType == "macro" then
		return actionID == actionData.macroIndex
	elseif actionData.type == "item" and actionType == "item" then
		return actionID == actionData.itemID
	end

	return false
end

----------------------------------------------------------------
-- Action Grid Row Mixin
----------------------------------------------------------------
QuickKeybindActionGridRowMixin = {}

function QuickKeybindActionGridRowMixin:Init()
	self.buttons = {}
	for i = 1, ICONS_PER_ROW do
		local btn = CreateFrame("Button", nil, self)
		btn:SetSize(ICON_SIZE, ICON_SIZE)
		btn:SetPoint("LEFT", (i - 1) * ICON_STEP + 4, 0)

		local icon = btn:CreateTexture(nil, "BACKGROUND")
		icon:SetAllPoints()
		btn.Icon = icon

		local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
		highlight:SetBlendMode("ADD")

		local border = btn:CreateTexture(nil, "OVERLAY")
		border:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
		border:SetPoint("CENTER")
		border:SetAtlas("quickslot-border-white")
		btn.Border = border

		btn:SetScript("OnClick", function(b)
			if b.actionData then
				QuickKeybindActionPickerFrame:PlaceActionInSlot(b.actionData)
			end
		end)

		btn:SetScript("OnEnter", function(b)
			if not b.actionData then return end
			GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
			if b.actionData.type == "spell" and b.actionData.bookIndex then
				GameTooltip:SetSpell(b.actionData.bookIndex, BOOKTYPE_SPELL)
			elseif b.actionData.type == "macro" then
				GameTooltip:SetText(b.actionData.name, 1, 1, 1)
			elseif b.actionData.type == "item" then
				local _, link = GetItemInfo(b.actionData.itemID)
				if link then
					GameTooltip:SetHyperlink(link)
				else
					GameTooltip:SetText(b.actionData.name, 1, 1, 1)
				end
			end
			GameTooltip:Show()
		end)

		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		self.buttons[i] = btn
	end
end

function QuickKeybindActionGridRowMixin:SetIndex(index)
	self.index = index
	self:Update()
end

function QuickKeybindActionGridRowMixin:Update()
	local picker = QuickKeybindActionPickerFrame
	local startIndex = (self.index - 1) * ICONS_PER_ROW

	for i = 1, ICONS_PER_ROW do
		local actionIndex = startIndex + i
		local btn = self.buttons[i]
		local actionData = picker.currentActions[actionIndex]

		if actionData then
			btn.actionData = actionData
			btn.Icon:SetTexture(actionData.icon)
			btn:Show()

			-- Set quality border
			local quality = actionData.quality
			if quality and quality > Enum.SpellQuality.Common and QUICKSLOT_QUALITY_BORDER_ATLAS[quality] then
				btn.Border:SetAtlas(QUICKSLOT_QUALITY_BORDER_ATLAS[quality])
			else
				btn.Border:SetAtlas("quickslot-border-white")
			end

			if picker:IsActionInTargetSlot(actionData) then
				btn.Icon:SetDesaturated(true)
				btn.Icon:SetAlpha(0.4)
			else
				btn.Icon:SetDesaturated(false)
				btn.Icon:SetAlpha(1.0)
			end
		else
			btn.actionData = nil
			btn:Hide()
		end
	end
end

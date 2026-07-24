local HelpUI = select(2, ...)

local MARKDOWN_FMT = "#### %s\n"

local poolCollection = CreateFramePoolCollection()
poolCollection:SetResetDisallowedIfNew(true)

local function CleanupField(field)
	field.tooltipText = nil
	field:SetRequired(false)
	field:ClearAllPoints()
	field:Hide()
end

local function ResetOneLineField(pool, frame)
	frame:SetText("")
	frame:ClearFocus()
	CleanupField(frame)
end

local function ResetMultiLineField(pool, frame)
	frame.Text:SetText("")
	frame.Text:ClearFocus()
	CleanupField(frame)
end

local function ResetDropDownField(pool, frame)
	UIDropDownMenu_SetText(frame, "")
	UIDropDownMenu_SetSelectedValue(frame, nil)
	CleanupField(frame)
end

local function ResetSpellField(pool, frame)
	frame.spellID = nil
	ResetOneLineField(pool, frame)
end

local function ResetItemField(pool, frame)
	frame.itemID = nil
	ResetOneLineField(pool, frame)
end

local function ResetAutoCompleteField(pool, frame)
	frame:SetText("")
	frame:ClearFocus()
	frame:SetDataProvider()
	CleanupField(frame)
end



function HelpUI:GetOneLineField()
	poolCollection:CreatePoolIfNeeded("EditBox", BugReportFrame, "BugReportOneLineFieldTemplate", ResetOneLineField)
	local frame = poolCollection:Acquire("BugReportOneLineFieldTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 2)
	return frame
end

function HelpUI:GetMultiLineField()
	poolCollection:CreatePoolIfNeeded("ScrollFrame", BugReportFrame, "BugReportMultiLineFieldTemplate", ResetMultiLineField)
	local frame = poolCollection:Acquire("BugReportMultiLineFieldTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 6, 4)
	return frame
end

function HelpUI:GetDropDownField()
	poolCollection:CreatePoolIfNeeded("Frame", BugReportFrame, "BugReportDropdownTemplate", ResetDropDownField)
	local frame = poolCollection:Acquire("BugReportDropdownTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 2)
	return frame
end

function HelpUI:GetSpellField()
	poolCollection:CreatePoolIfNeeded("EditBox", BugReportFrame, "BugReportSpellTemplate", ResetSpellField)
	local frame = poolCollection:Acquire("BugReportSpellTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 2)
	return frame
end

function HelpUI:GetMysticEnchantField()
	poolCollection:CreatePoolIfNeeded("EditBox", BugReportFrame, "BugReportMysticEnchantTemplate", ResetSpellField)
	local frame = poolCollection:Acquire("BugReportMysticEnchantTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 2)
	return frame
end

function HelpUI:GetItemField()
	poolCollection:CreatePoolIfNeeded("EditBox", BugReportFrame, "BugReportItemTemplate", ResetItemField)
	local frame = poolCollection:Acquire("BugReportItemTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 2)
	return frame
end

function HelpUI:GetAutoCompleteField()
	poolCollection:CreatePoolIfNeeded("EditBox", BugReportFrame, "BugReportAutoCompleteTemplate", ResetAutoCompleteField)
	local frame = poolCollection:Acquire("BugReportAutoCompleteTemplate")
	frame.Label:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -4, 2)
	return frame
end

function HelpUI:GetFieldByType(type)
	if type == "oneline" then
		return self:GetOneLineField()
	elseif type == "multiline" then
		return self:GetMultiLineField()
	elseif type == "dropdown" then
		return self:GetDropDownField()
	elseif type == "spell" then
		return self:GetSpellField()
	elseif type == "mysticenchant" then
		return self:GetMysticEnchantField()
	elseif type == "item" then
		return self:GetItemField()
	elseif type == "autocomplete" then
		return self:GetAutoCompleteField()
	end
end

BugReportFieldMixin = CreateFromMixins("CallbackRegistryMixin")

function BugReportFieldMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({
		"OnValueChanged"
	})
end


function BugReportFieldMixin:Release()
	poolCollection:Release(self)
end

function BugReportFieldMixin:InitializeFromLayout(layout)
	local key = layout.key
	self:SetLabel(_G["BUG_REPORT_LABEL_"..key])
	self:SetTooltip(_G["BUG_REPORT_TOOLTIP_"..key])
	self:SetInstruction(_G["BUG_REPORT_INSTRUCTION_"..key])
	self:SetRequired(layout.required)
	if layout.maxLetters then
		self:SetMaxLetters(layout.maxLetters)
	end
end

function BugReportFieldMixin:AttachToField(field)
	if self.type ~= "multiline" and field.type == "multiline" then
		self:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 8, -24)
	else
		self:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 0, -24)
	end

    if self.type == "item" or self.type == "spell" or self.type == "mysticenchant" then
        self:SetPoint("RIGHT", -44, 0)
    else
        self:SetPoint("RIGHT", -7, 0)
    end
end

function BugReportFieldMixin:SetRequired(required)
	self.Required:SetShown(required)
end

function BugReportFieldMixin:IsRequired()
	return self.Required:IsShown()
end

function BugReportFieldMixin:IsValid()
	return not self:IsRequired() or self:GetFieldValue() ~= "" and self:GetFieldValue() ~= nil
end

function BugReportFieldMixin:SetLabel(label)
	self.Label:SetText(label)
end

function BugReportFieldMixin:GetTextBlock(markdown)
	local text = self:GetFieldValue()
	if text:len() <= 0 and not self.Required:IsShown() then
		return ""
	end
	if self.SubFields then
		for _, field in ipairs(self.SubFields) do
			local fieldText = field:GetTextBlock(markdown)
			if fieldText and fieldText:len() > 0 or field.Required:IsShown() then
				text = text .. "\n" .. fieldText
			end
		end
	end
	if not markdown then
		return self.Label:GetText() .. ": " .. text
	end
	return string.format(MARKDOWN_FMT, self.Label:GetText()) ..  text
end

function BugReportFieldMixin:GetFieldValue()
	return self:GetText()
end

function BugReportFieldMixin:SetFieldValue(value)
	return self:SetText(value)
end

function BugReportFieldMixin:GetFieldType()
	return self.type
end

function BugReportFieldMixin:SetInstruction(instruction)
	if self.Instructions then
		self.Instructions:SetText(instruction)
	end
end

function BugReportFieldMixin:SetTooltip(tooltipText)
	self.tooltipText = tooltipText
	if self:IsMouseOver() and tooltipText then
		self:OnEnter()
	end
end

function BugReportFieldMixin:OnEnter()
	if self.tooltipText then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.Label:GetText(), 1, 1, 1, 1, true)
		GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
		GameTooltip:Show()
	end
end

function BugReportFieldMixin:OnLeave()
	GameTooltip:Hide()
end

function BugReportFieldMixin:UpdateCanSubmit()
	self:GetParent():UpdateSubmitButton()
end

function BugReportFieldMixin:UpdateValue(value)
	self:TriggerEvent("OnValueChanged", value)
	self:UpdateCanSubmit()
end

function BugReportFieldMixin:AddSubField(field)
	self.SubFields = self.SubFields or {}
	table.insert(self.SubFields, field)
	field:AttachToField(self)
end

function BugReportFieldMixin:AddOutPrefix(prefix)
	self.OutPrefix = prefix
end

function BugReportFieldMixin:SetOutSuffix(suffix)
	self.OutSuffix = suffix
end

function BugReportFieldMixin:GetFieldHeight()
	local height = self:GetHeight() + 24
	if self.SubFields then
		for _, field in ipairs(self.SubFields) do
			height = height + field:GetFieldHeight()
		end
	end
	return height
end

BugReportMultiLineFieldMixin = CreateFromMixins(BugReportFieldMixin)

function BugReportMultiLineFieldMixin:GetFieldValue()
	return self.Text:GetText()
end

function BugReportMultiLineFieldMixin:SetFieldValue(value)
	return self.Text:SetText(value)
end

function BugReportMultiLineFieldMixin:SetInstruction(instruction)
	if self.Text.Instructions then
		self.Text.Instructions:SetText(instruction)
	end
end

function BugReportMultiLineFieldMixin:AttachToField(field)
	if field.type ~= "multiline" then
		self:SetPoint("TOPLEFT", field, "BOTTOMLEFT", -8, -24)
	else
		self:SetPoint("TOPLEFT", field, "BOTTOMLEFT", 0, -24)
	end
	self:SetPoint("RIGHT", -28, 0)
end

function BugReportMultiLineFieldMixin:SetMaxLetters(maxLetters)
	self.Text:SetMaxLetters(maxLetters)
end

BugReportDropDownFieldMixin = CreateFromMixins(BugReportFieldMixin)

function BugReportDropDownFieldMixin:GetFieldValue()
	return UIDropDownMenu_GetSelectedValue(self)
end

function BugReportDropDownFieldMixin:SetFieldValue(value)
	return UIDropDownMenu_SetSelectedValue(self, value)
end

function BugReportDropDownFieldMixin:GetTextBlock()
	return UIDropDownMenu_GetSelectedName(self)
end

BugReportSpellFieldMixin = CreateFromMixins(BugReportFieldMixin)

function BugReportSpellFieldMixin:OnTextChanged()
    InputBoxInstructions_OnTextChanged(self)
	local name, spellID = C_Spell:GetNameAndID(self:GetText():trim(), true)
	self.SpellID = spellID
	if spellID then
		local _, _, icon = GetSpellInfo(spellID)
		if name then
			self.Spell.Icon:SetTexture(icon)
			self.Spell:Show()
		else
			self.Spell:Hide()
		end
	else
		self.Spell:Hide()
	end
end

function BugReportSpellFieldMixin:OnEnterIcon(icon)
	if self.SpellID then
		GameTooltip:SetOwner(icon, "ANCHOR_TOPRIGHT")
		GameTooltip:SetHyperlink("spell:"..self.SpellID)
		GameTooltip:Show()
	end
end

function BugReportSpellFieldMixin:GetTextBlock(markdown)
	local field
    if self.SpellID then
        field = GetSpellInfo(self.SpellID) or self.SpellID
    else
        field = self:GetFieldValue()
    end
	if not markdown then
		return format("Spell: %s [ID: %s]", field, self.SpellID or "Not Included")
	end
	local label = string.format(MARKDOWN_FMT, "Spell")
	return format(label.."%s %s [ID: %s]", label, field, self.SpellID or "Not Included")
end

BugReportMysticEnchantFieldMixin = CreateFromMixins(BugReportSpellFieldMixin)

function BugReportMysticEnchantFieldMixin:OnTextChanged()
    InputBoxInstructions_OnTextChanged(self)
	local name, spellID = C_Spell:GetNameAndID(self:GetText():trim(), true, true)
	self.SpellID = spellID
	if spellID then
		local _, _, icon = GetSpellInfo(spellID)
		if name then
            self:SetScript("OnTextChanged", nil)
            self:SetText(name)
            self:SetScript("OnTextChanged", self.OnTextChanged)
			self.Spell.Icon:SetTexture(icon)
			self.Spell:Show()
		else
			self.Spell:Hide()
		end
	else
		self.Spell:Hide()
	end
end

function BugReportMysticEnchantFieldMixin:GetTextBlock(markdown)
    local field
    if self.SpellID then
        field = GetSpellInfo(self.SpellID) or self.SpellID
    else
        field = self:GetFieldValue()
    end
	if not markdown then
		return format("Mystic Enchant: %s [ID: %s]", field, self.SpellID or "Not Included")
	end
	local label = string.format(MARKDOWN_FMT, "Mystic Enchant")
	return format(label.."%s %s [ID: %s]", label, field, self.SpellID or "Not Included")
end

BugReportItemFieldMixin = CreateFromMixins(BugReportFieldMixin)

function BugReportItemFieldMixin:OnTextChanged()
    InputBoxInstructions_OnTextChanged(self)
	if self.cancelLoad then
		self.cancelLoad()
		self.cancelLoad = nil
	end

	local name, itemID = C_Item:GetNameAndID(self:GetText():trim())
	self.ItemID = itemID
	if itemID then
		local icon = select(10, GetItemInfo(itemID))
		if name then
            self:SetScript("OnTextChanged", nil)
            self:SetText(name)
            self:SetScript("OnTextChanged", self.OnTextChanged)
			self.Item.Icon:SetTexture(icon)
			self.Item:Show()
		else
			self.Item:Hide()
		end
	else
		itemID = tonumber(self:GetText():trim())
		if itemID then
			self.cancelLoad = Item:CreateFromID(itemID):CancelableContinueOnLoad(function()
				local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
				if name then
					self:SetText(name)
					self.Item.Icon:SetTexture(icon)
					self.Item:Show()
				else
					self.Item:Hide()
				end

				self.cancelLoad = nil
			end)
		end
		self.Item:Hide()
	end
end

function BugReportItemFieldMixin:OnEnterIcon(icon)
	if self.ItemID then
		GameTooltip:SetOwner(icon, "ANCHOR_TOPRIGHT")
		GameTooltip:SetHyperlink("item:"..self.ItemID)
		GameTooltip:Show()
	end
end

function BugReportItemFieldMixin:GetTextBlock(markdown)
    local field
    if self.ItemID then
        field = GetItemInfo(self.ItemID) or self.ItemID
    end
	field = self:GetFieldValue()
	if not markdown then
		return format("Item: %s [ID: %s]", field, self.ItemID or "Not Included")
	end
	local label = string.format(MARKDOWN_FMT, "Item")
	return format(label.."%s %s [ID: %s]", label, field, self.ItemID or "Not Included")
end

BugReportAutoCompleteFieldMixin = CreateFromMixins(BugReportFieldMixin)

function BugReportAutoCompleteFieldMixin:InitializeFromLayout(layout)
	BugReportFieldMixin.InitializeFromLayout(self, layout)
	self.Dialog:SetFrameLevel(self:GetParent().PortraitFrame:GetFrameLevel() + 1)
	self:SetMinSearchCharacters(layout.minSearchCharacters or 1)
	if type(layout.func) == "function" then
		self:SetDataProvider(layout.func)
	end
end

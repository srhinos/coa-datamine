--
-- Extra Action Bar Button
--
ExtraActionButtonMixin = CreateFromMixins("QuickKeybindButtonMixin")

function ExtraActionButtonMixin:OnLoad()
	self.buttonType = "EXTRAACTIONBUTTON"
	SetParentArray(self, "Buttons", self:GetID())
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("AnyUp")
	self.elapsed = 0
end

function ExtraActionButtonMixin:SetAction(action, name, id, art)
	if not action or (not name and not id) then return end
	
	self:SetAttribute("action-name", name)
	self:SetAttribute("action-id", id)
	self:SetAttribute("art", art)
	self:SetAttribute("action", action)
end

function ExtraActionButtonMixin:GetAction()
	return self:GetAttribute("action-id")
end

function ExtraActionButtonMixin:SetClickAction(fn)
	if not self:HasAction() then return end
	
	self:SetAttribute("type", "function")
	self:SetAttribute("_function", fn)
end

function ExtraActionButtonMixin:OnShow()
	self:QuickKeybindButtonOnShow()
end

function ExtraActionButtonMixin:OnHide()
	self:QuickKeybindButtonOnHide()
end

function ExtraActionButtonMixin:TriggerCooldown(duration)
	self:SetAttribute("cooldown", duration)
end

function ExtraActionButtonMixin:ClearClickAction()
	self:SetAttribute("_function", nil)

	if not self:HasAction() then return end

	self:SetAttribute("type", self:GetAttribute("action"))
end

function ExtraActionButtonMixin:SetDisableTooltip(title, text)
	self:SetAttribute("disable-tooltipTitle", title)
	self:SetAttribute("disable-tooltipText", text)
end

function ExtraActionButtonMixin:SetExtraTooltip(...)
	do
		-- wipe previous tooltip first
		local tooltip = self:GetAttribute("tooltip-1")
		local i = 1

		while tooltip do
			self:SetAttribute("tooltip-"..i, nil)
			i = i + 1
			tooltip = self:GetAttribute("tooltip-"..i)
		end
	end

	for i = 1, select("#", ...) do
		self:SetAttribute("tooltip-"..i, select(i, ...))
	end
end

function ExtraActionButtonMixin:ClearAction()
	self:SetAttribute("action", nil)
end

function ExtraActionButtonMixin:HasAction()
	return self:GetAttribute("action") ~= nil
end

function ExtraActionButtonMixin:ClearFakeCooldown()
	self.FakeCooldownStart = nil
	self.FakeCooldownDuration = nil
end

function ExtraActionButtonMixin:GetCooldown(actionType)
	local hasFakeCooldown = self.FakeCooldownStart ~= nil and GetTime() < self.FakeCooldownStart + self.FakeCooldownDuration
	if hasFakeCooldown then
		return self.FakeCooldownStart, self.FakeCooldownDuration, hasFakeCooldown and 1 or 0
	else
		self:ClearFakeCooldown()
	end

	if actionType == "item" then
		return GetItemCooldown(self.actionID)
	end

	if actionType == "spell" then
		return GetSpellCooldown(self.actionID)
	end

	return 0, 0, 0
end

function ExtraActionButtonMixin:OnAttributeChanged(name, value)
	if name == "action" then
		self.actionName = nil
		self.actionID = nil

		self.actionType = value
		local icon

		if value == "ACTION_TYPE_SPELL" then
			self.actionName = self:GetAttribute("action-name")
			self.actionID = self:GetAttribute("action-id")

			if self.actionName and not self.actionID then
				self.actionID = C_Spell:GetSpellID(self.actionName)
			elseif not self.actionName and self.actionID then
				self.actionName = GetSpellInfo(self.actionID)
			end

			if self.actionName and self.actionID then
				icon = select(3, GetSpellInfo(self.actionID))
				local known = C_Spell:IsAnyRankKnown(self.actionID)
				self.Icon:SetDesaturated(not known)
				self.Art:SetDesaturated(not known)
				self:SetAttribute("type", "spell")
				self:SetAttribute("spell", self.actionID)
			end

		elseif value == "ACTION_TYPE_ITEM" then
			self.actionName = self:GetAttribute("action-name")
			self.actionID = self:GetAttribute("action-id")
			if self.actionName and not self.actionID then
				local itemLink = select(2, GetItemInfo(self.actionName))
				if itemLink then
					self.actionID = GetItemInfoFromHyperlink(itemLink)
				end
			elseif not self.item and self.actionID then
				self.actionName = GetItemName(self.actionID)
			end

			if self.actionName and self.actionID then
				icon = "Interface\\Icons\\"..GetItemIconInstant(self.actionID)
				local known = GetItemCount(self.actionID, false, true) ~= 0
				self.Icon:SetDesaturated(not known)
				self.Art:SetDesaturated(not known)
				self:SetAttribute("type", "item")
				self:SetAttribute("item", "item:"..self.actionID)
			end
		end

		if self.actionName and self.actionID then
			self.Icon:SetTexture(icon)

			if self:GetParent():IsVisible() and not self:IsShown() then
				self.FadeIn:Play()
			else
				self:Show()
			end
			return true
		end

		if not self:IsShown() then
			return false
		end

		if self:GetParent():GetVisibleButtonCount() > 1 then
			self.FadeOut:Play()
		else
			self:SetAttribute("disable-tooltipTitle", nil)
			self:SetAttribute("disable-tooltipText", nil)
			
			local i = 1
			local tooltip = self:GetAttribute("tooltip-"..i)
			while tooltip do
				self:SetAttribute("tooltip-"..i, nil)
				i = i + 1
				tooltip = self:GetAttribute("tooltip-"..i)
			end
			self:SetAttribute("type", nil)
			self:SetAttribute("spell", nil)
			self:SetAttribute("item", nil)
			self:SetAttribute("_function", nil)
			self:Hide()
		end

		return false
	elseif name == "art" then
		if value and value ~= "none" then
			self.Art.Texture = "Interface\\ExtraButton\\"..value
			self.Art:SetTexture(self.Art.Texture)
		elseif value == "none" then
			self.Art.Texture = nil
			self.Art:SetTexture(nil)
		else
			self.Art.Texture = "Interface\\ExtraButton\\Default"
			self.Art:SetTexture(self.Art.Texture)
		end
	elseif name == "cooldown" then
		if value <= 0 then
			return
		end
		self.FakeCooldownStart = GetTime()
		self.FakeCooldownDuration = value
	end
end

function ExtraActionButtonMixin:OnEnter()
	self:QuickKeybindButtonOnEnter()
	if not self.actionID then return end
	
	if self:GetParent().GetJustifyH and (self:GetParent():GetJustifyH() == "LEFT") then -- used in SkillCardBoosterActionButtonMixin
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end

	GameTooltip:SetHyperlink("|H"..self:GetAttribute("type")..":"..self.actionID)

	if self:IsEnabled() == 0 then
		local title = self:GetAttribute("disable-tooltipTitle")
		local text = self:GetAttribute("disable-tooltipText")

		if title then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(title, 1, 0, 0)
		end

		if text then
			GameTooltip:AddLine(text, nil, nil, nil, true)
		end
	else
		local i = 1
		local tooltip = self:GetAttribute("tooltip-"..i)

		if tooltip then
			GameTooltip:AddLine(" ")
			while tooltip do
				GameTooltip:AddLine(tooltip, nil, nil, nil, true)
				i = i + 1
				tooltip = self:GetAttribute("tooltip-"..i)
			end
		end
	end
	--GameTooltip:AddLine(EXTRA_ACTION_BUTTON_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function ExtraActionButtonMixin:OnLeave()
	self:QuickKeybindButtonOnLeave()
	GameTooltip:Hide()
end

function ExtraActionButtonMixin:OnHide()
	local parent = self:GetParent()
	if IsLayoutFrame(parent) then
		parent:Layout()
	end
end

function ExtraActionButtonMixin:OnUpdate(elapsed)
	self.elapsed = self.elapsed + elapsed
	
	if self.elapsed < 0.1 then return end

	local count = 0

	local actionType = self:GetAttribute("type")
	local start, duration, enable = self:GetCooldown(actionType)

	if actionType == "spell" and self.actionID then
		count = GetSpellCount(self.actionID) or 0
		self:SetEnabled(C_Spell:IsAnyRankKnown(self.actionID))
	elseif actionType == "item" and self.actionID then
		count = GetItemCount(self.actionID, false, true) or 0
		self:SetEnabled(count and count > 0)
	elseif actionType == "function" then
		self.Icon:SetDesaturated(enable == 1)
		self.Art:SetDesaturated(enable == 1)
		self:SetEnabled(enable == 0)
	else
		count = 0
		self:SetEnabled(false)
	end

	self.Count:SetShown(count and count > 0)

	if count and count > 1 then
		self.Count:SetText(count)
	else
		self.Count:SetText("")
	end

	if start and start > 0 and duration and duration > 0 and enable and enable > 0 then
		self.Cooldown:SetCooldown(start, duration)
		local timeLeft = (start + duration) - GetTime()
		self.Cooldown.Text:SetText(format(SecondsToTimeAbbrevPrecise(timeLeft)))
		self.Cooldown:Show()
	else
		self.Cooldown:Hide()
	end

	self:SetChecked(false)

	self.elapsed = 0
end

function ExtraActionButtonMixin:OnDragStart()
	if self.actionType == "ACTION_TYPE_SPELL" then
		local spellName = GetSpellInfo(self.actionID)
		if spellName then
			PickupSpell(spellName)
		end
	elseif self.actionType == "ACTION_TYPE_ITEM" then
		local itemName = GetItemInfo(self.actionID)
		if itemName then
			PickupItem(itemName)
		end
	end
end

function ExtraActionButtonMixin:OnClick(button)
	SecureActionButton_OnClick(self, button)
end

function ExtraActionButtonMixin:OnEnable()
	self.Icon:SetDesaturated(false)
	self.Art:SetDesaturated(false)
end

function ExtraActionButtonMixin:OnDisable()
	self.Icon:SetDesaturated(true)
	self.Art:SetDesaturated(true)
end

--
-- Extra Action Bar
--
local function ClearExtraActionButton(pool, button)
	button:ClearAllPoints()
	button:Hide()
	button:ClearAction()
end
ExtraActionBarMixin = CreateFromMixins("HorizontalLayoutMixin")

function ExtraActionBarMixin:OnLoad()
	HorizontalLayoutMixin.OnLoad(self)
	self:SetUserPlaced(false)
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("UPDATE_BINDINGS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("EXTRA_ACTION_BUTTON_ADDED")
	self:RegisterEvent("EXTRA_ACTION_BUTTON_REMOVED")
	self:RegisterEvent("HIDE_ALL_EXTRA_ACTION_BUTTONS")
	self.Buttons = CreateFramePool("CheckButton", self, "ExtraActionButtonTemplate", ClearExtraActionButton)
	self.ButtonsByID = {}
end

function ExtraActionBarMixin:IgnoreLayoutIndex()
	return true
end

function ExtraActionBarMixin:GetVisibleButtonCount()
	return self.Buttons:GetNumActive()
end

function ExtraActionBarMixin:GetAvailableActionSlot()
	for button in self.Buttons:EnumerateActive() do
		if not button:HasAction() or button.FadeOut:IsPlaying() then
			return button
		end
	end

	local button, isNew = self.Buttons:Acquire()
	if isNew then
		local id = self.Buttons.frameCount
		button:SetID(id)
		self.ButtonsByID[id] = button
	end
	return button
end

function ExtraActionBarMixin:SetAvailableActionSlot(action, name, id, art)
	local button = self:GetAvailableActionSlot()
	if button then
		button:SetAction(action, name, id, art)
		button:Show()
		self:Layout()
		return button
	end
end

function ExtraActionBarMixin:AddSpell(spell, art)
	if not spell then return end
	if self:HasSpell(spell) then return end

	if ActionBarUtil:FindSpellOnActionBar(spell) then return end

	local spellID = tonumber(spell)

	if not spellID then
		spellID = C_Spell:GetSpellID(spell)
	else
		spell = GetSpellInfo(spellID)
	end
	
	if not spellID or not spell then return end
	
	return self:SetAvailableActionSlot("ACTION_TYPE_SPELL", spell, spellID, art)
end

function ExtraActionBarMixin:AddItem(item, art, force)
	if not item then return end
	if self:HasItem(item) then return end

	if ActionBarUtil:FindItemOnActionBar(item) then return end

	local itemID = tonumber(item)

	if not itemID then
		local itemLink = select(2, GetItemInfo(item))
		if itemLink then
			itemID = GetItemInfoFromHyperlink(itemLink)
		end
	else
		item = GetItemName(itemID)
	end

	if not itemID or not item then return end
	
	return self:SetAvailableActionSlot("ACTION_TYPE_ITEM", item, itemID, art)
end

function ExtraActionBarMixin:AddLazyAction()
	local button = self:GetAvailableActionSlot()
	if button then
		button:SetAction()
		button:Show()
		self:Layout()
		return button
	end
end

function ExtraActionBarMixin:HasAction(actionType, action)
	if not action then return end
	for button in self.Buttons:EnumerateActive() do
		if button:HasAction() and not button.FadeOut:IsPlaying() and button.actionType == actionType then
			if button.actionName == action or button.actionID == action then
				return true
			end
		end
	end

	return false
end

function ExtraActionBarMixin:GetActionButton(actionType, action)
	if not action then return end
	for button in self.Buttons:EnumerateActive() do
		if button:HasAction() and not button.FadeOut:IsPlaying() and button.actionType == actionType then
			if button.actionName == action or button.actionID == action then
				return button
			end
		end
	end
end

function ExtraActionBarMixin:HasItem(item)
	return self:HasAction("ACTION_TYPE_ITEM", item)
end

function ExtraActionBarMixin:HasSpell(spell)
	return self:HasAction("ACTION_TYPE_SPELL", spell)
end

function ExtraActionBarMixin:RemoveAction(actionType, action)
	if not action then return end
	local button = self:GetActionButton(actionType, action)
	if button then
		button:ClearAction()
		self:Layout()
		return true
	end
end

function ExtraActionBarMixin:RemoveItem(item)
	return self:RemoveAction("ACTION_TYPE_ITEM", item)
end

function ExtraActionBarMixin:RemoveSpell(spell)
	return self:RemoveAction("ACTION_TYPE_SPELL", spell)
end

function ExtraActionBarMixin:ClearAll()
	self.Buttons:ReleaseAll()
	self:Layout()
end

function ExtraActionBarMixin:OnUpdate()
	if not IsShiftKeyDown() or not self:IsMouseOver() then
		if self.Movable then
			self.Movable = false
			self.MoveBackground:Hide()
			self:StopMovingOrSizing()
		end
		return
	end

	self.Movable = true
	self.MoveBackground:Show()
end

function ExtraActionBarMixin:OnHide()
	self:StopMovingOrSizing()
	self.Movable = false
end

function ExtraActionBarMixin:UpdateBindings()
	for button in self.Buttons:EnumerateActive() do
		local key = GetBindingKey("EXTRAACTIONBUTTON"..button:GetID())
		local text = GetBindingText(key, "KEY_", 1)

		button.HotKey:SetShown(text and text ~= "")
		button.HotKey:SetText(text)
	end
end

function ExtraActionBarMixin:OnEvent(event, ...)
	if event == "UPDATE_BINDINGS" then
		self:UpdateBindings()
	elseif event == "PLAYER_ENTERING_WORLD" then
		local numButtons = C_ExtraActionButton.GetNumExtraActionButtons()
		for i = 1, numButtons do
			local buttonID = C_ExtraActionButton.GetExtraActionButtonAtIndex(i)
			if buttonID then
				local actionType, actionName, actionID, art = C_ExtraActionButton.GetExtraActionButtonInfo(buttonID)
				if actionType then
					self:SetAvailableActionSlot(actionType, actionName, actionID, art)
				end
			end
		end
	elseif event == "EXTRA_ACTION_BUTTON_ADDED" then
		local buttonID = ...
		local actionType, actionName, actionID, art = C_ExtraActionButton.GetExtraActionButtonInfo(buttonID)
		if actionType then
			self:SetAvailableActionSlot(actionType, actionName, actionID, art)
		end
	elseif event == "EXTRA_ACTION_BUTTON_REMOVED" then
		local buttonID = ...
		local actionType, actionName, actionID = C_ExtraActionButton.GetExtraActionButtonInfo(buttonID)
		if actionType then
			self:RemoveAction(actionType, actionID or actionName)
		end
	end
end

function ExtraActionBarMixin:ButtonDown(id)
	if not self:IsVisible() or not id then return end
	
	local button = self.ButtonsByID[id]
	if not button or not button:IsShown() or not button:HasAction() then return end

	if button:GetButtonState() == "NORMAL"  then
		button:SetButtonState("PUSHED")
	end
	-- button:Click()
end

function ExtraActionBarMixin:ButtonUp(id)
	if not self:IsVisible() or not id then return end
	
	local button = self.ButtonsByID[id]
	if not button or not button:IsShown() or not button:HasAction() then return end

	if button:GetButtonState() == "PUSHED" then
		button:SetButtonState("NORMAL")
		button:Click()
	end
end
local COA_MULTICAST_BINDINGS =
{
	"COA_MULTICAST1",
	"COA_MULTICAST2",
	"COA_MULTICAST3",
	"COA_MULTICAST4",
	"COA_MULTICAST5",
	"COA_MULTICAST6",
}

BINDING_HEADER_COA_MULTICAST = BINDING_HEADER_COA_MULTICAST or "CoA Multicast Bindings"

for i = 1, #COA_MULTICAST_BINDINGS do
	_G["BINDING_NAME_"..COA_MULTICAST_BINDINGS[i]] = _G["BINDING_NAME_"..COA_MULTICAST_BINDINGS[i]] or "CoA Multicast Button "..i
end

local function CoA_SendNecroMulticastSelection()
	if not C_CoA or not C_CoA.SendMulticastSelection then
		return -- bridge not available yet
	end

	local selection = {}
	for i, cvar in ipairs(COA_MULTICAST_BINDINGS) do
		selection[i] = C_CVar.GetNumber(cvar) or 0
	end

	C_CoA.SendMulticastSelection(selection)
end

local MULTI_CAST_FLYOUT_BUTTON_INITIAL_OFFSET = 4
local MULTI_CAST_FLYOUT_BUTTON_OFFSET = 2
local MULTI_CAST_FLYOUT_CLOSE_SEC = 3
--
-- Action button
--
CoAMultiCastActionButtonMixin = CreateFromMixins(ExtraActionButtonMixin, CallbackRegistryMixin)

function CoAMultiCastActionButtonMixin:OnLoad()
	ExtraActionButtonMixin.OnLoad(self)
	CallbackRegistryMixin.OnLoad(self)

	self:GenerateCallbackEvents(
	{
		"OnEnterActionButton",
		"OnLeaveActionButton",
	})

	self:RegisterForClicks("AnyUp")
	self:Layout()

	self.FadeOut.Play = function() end
	self.FadeIn.Play = function() end
end

function CoAMultiCastActionButtonMixin:GetDefaultTexture()
	return self.defaultTexture
end

function CoAMultiCastActionButtonMixin:SetDefaultTexture(value)
	self.defaultTexture = value
end

function CoAMultiCastActionButtonMixin:GetCVar()
	return self.cvar
end

function CoAMultiCastActionButtonMixin:SetCVar(value)
	self.cvar = value
end

function CoAMultiCastActionButtonMixin:Update(cvar)
	local spellID = C_CVar.GetNumber(cvar)

	local key = GetBindingKey(cvar)
	local text = GetBindingText(key, "KEY_", 1)
	self.HotKey:SetText(text)

	self:SetCVar(cvar)

	if (spellID) and (spellID ~= 0) and IsSpellKnown(spellID) then
		self.HotKey:Show()
		self:SetAction("ACTION_TYPE_SPELL", GetSpellInfo(spellID), spellID)
	else
		self.HotKey:Hide()
		self:SetAttribute("type", nil)
		self:ClearAction()
		self.Icon:SetTexture(self:GetDefaultTexture())
	end

	self:Show()
end

function CoAMultiCastActionButtonMixin:OnEnter()
	ExtraActionButtonMixin.OnEnter(self)
	self:TriggerEvent("OnEnterActionButton", self)
end

function CoAMultiCastActionButtonMixin:OnLeave()
	ExtraActionButtonMixin.OnLeave(self)
	self:TriggerEvent("OnLeaveActionButton")
end

function CoAMultiCastActionButtonMixin:Layout()
	self.Icon:ClearAllPoints()
	self.Icon:SetSize(30, 30)
	self.Icon:SetPoint("CENTER", 0, 0)

	self.NormalTexture:ClearAllPoints()
	self.NormalTexture:SetPoint("CENTER", 0, 0)
	self.NormalTexture:SetSize(50, 50)
	--self.NormalTexture:Hide()
	--self:SetNormalTexture(nil)

    self.Art:Hide()

    self.Cooldown.Text:SetFontObject(GameFontNormal)
end

-- 
-- Flyout button
--
CoAMultiCastFlyoutButtonMixin = {}

function CoAMultiCastFlyoutButtonMixin:OnLoad()
end

function CoAMultiCastFlyoutButtonMixin:SetSpellID(value)
	self.spellID = value
end

function CoAMultiCastFlyoutButtonMixin:GetSpellID()
	return self.spellID
end

function CoAMultiCastFlyoutButtonMixin:Update(spellID, defaultTexture)
	self:SetSpellID(spellID)

	if spellID then
		local _, _, icon = GetSpellInfo(spellID)
		self.Icon:SetTexture(icon)
	else
		self.Icon:SetTexture(defaultTexture)
	end
end

function CoAMultiCastFlyoutButtonMixin:OnEnter()
	if ( GetCVarBool("UberTooltips") ) then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end

	if not(self:GetSpellID()) then
		GameTooltip:AddLine("No Action", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b) -- TODO: Localize
		self.UpdateTooltip = nil
	else
		if GameTooltip:SetHyperlink("spell:"..self:GetSpellID()) then
			self.UpdateTooltip = CoAMultiCastFlyoutButtonMixin.OnEnter(self)
		else
			self.UpdateTooltip = nil
		end
	end

	GameTooltip:Show()
end

function CoAMultiCastFlyoutButtonMixin:OnLeave()
	GameTooltip:Hide()
end

-- 
-- Flyout menu
--
CoAMultiCastFlyoutMixin = {}

function CoAMultiCastFlyoutMixin:OnLoad()
	self.flyoutButtonsPool = CreateFramePool("CheckButton", self, "CoAMultiCastFlyoutButtonTemplate")
	self.CloseButton:SetScript("OnClick", function() self:Hide() end)
end

function CoAMultiCastFlyoutMixin:ClearButtons()
	self.flyoutButtonsPool:ReleaseAll()
end

function CoAMultiCastFlyoutMixin:AcquireButton()
	return self.flyoutButtonsPool:Acquire()
end

--
-- Flyout open button
--
CoAMultiCastFlyoutOpenButtonMixin = {}

function CoAMultiCastFlyoutOpenButtonMixin:OnLeave()
	self:Hide()
end

function CoAMultiCastFlyoutOpenButtonMixin:Init(parent)
	self:SetParent(parent)
	self:SetPoint("BOTTOM", parent, "TOP", 0, 0)
	self:Show()
end

--
-- Action bar
--
CoAMultiCastActionBarMixin = CreateFromMixins(CallbackRegistryMixin)

CoAMultiCastActionBarMixin.events = {
	"PLAYER_ENTERING_WORLD",
	"UPDATE_MULTI_CAST_ACTIONBAR",
}

function CoAMultiCastActionBarMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:SetScript("OnEvent", OnEventToMethod)
	self:RegisterForDrag("LeftButton") -- TODO: Replace with lock

	for _, event in pairs(self.events) do
		self:RegisterEvent(event)
	end

	self:GenerateCallbackEvents({
		"OnButtonsUpdated",
		"OnResourceUpdated",
		"OnSetShowText",
		"OnSetLocked",
	})

	self.FlyoutFrameOpenButton:SetScript("OnClick", GenerateClosure(self.OnClickFlyoutOpenButton, self))

	self.actionButtonsPool = CreateFramePool("CheckButton", self, "CoAMultiCastActionButtonTemplate")
	self.Buttons = {}
	self.numButtons = 0
	self.spells = {}
	self.defaultTexture = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"

	-- TODO: Replace if used both multicast + custom resource thing, atm use same cvars for both
	self.cvarLocked = "coaResourceBarLocked"
	self.cvarSize = "coaResourceBarSize"
	self.cvarShowText = "coaResourceBarShowText"

	self:LoadCVars()

	self.DropDown.initialize = CoAResourceMixin.InitializeDropDown
	self.DropDown.displayMode = "MENU"
end

function CoAMultiCastActionBarMixin:UpdateResource(value, maxValue)
	local progress = math.min(100, math.abs(math.ceil(value*100/maxValue)))
	self:TriggerEvent("OnResourceUpdated", progress, value, maxValue)
end

function CoAMultiCastActionBarMixin:GetVisibleButtonCount()
	return #self.Buttons
end

function CoAMultiCastActionBarMixin:OnShow()
	self:RegisterEvent("UPDATE_BINDINGS")
end

function CoAMultiCastActionBarMixin:OnHide()
	self:UnregisterEvent("UPDATE_BINDINGS")
end

function CoAMultiCastActionBarMixin:SetDefaultTexture(value)
	self.defaultTexture = value

	for button in self.actionButtonsPool:EnumerateActive() do
		button:SetDefaultTexture(value)
	end

	self:Update()
end

function CoAMultiCastActionBarMixin:GetDefaultTexture()
	return self.defaultTexture
end

function CoAMultiCastActionBarMixin:SetSpells(value)
	self.spells = value
end

function CoAMultiCastActionBarMixin:GetSpells()
	return self.spells
end

function CoAMultiCastActionBarMixin:SetNumButtons(value)
	self.numButtons = math.min(value or 0, #COA_MULTICAST_BINDINGS)
end

function CoAMultiCastActionBarMixin:GetNumButtons()
	return self.numButtons
end

function CoAMultiCastActionBarMixin:HasMultiCastActionBar()
	return self:GetNumButtons() > 0
end

function CoAMultiCastActionBarMixin:GetActionInfo(index)
	-- TODO: Load action data from memory
	return COA_MULTICAST_BINDINGS[index]
end

function CoAMultiCastActionBarMixin:ActionButtonDown(id)
	if not self:IsVisible() or not id then return end

	local button = self.Buttons[id]
	if not button or not button:HasAction() then return end

	if button:GetButtonState() == "NORMAL"  then
		button:SetButtonState("PUSHED")
	end
	-- button:Click()
end

function CoAMultiCastActionBarMixin:ActionButtonUp(id)
	if not self:IsVisible() or not id then return end

	local button = self.Buttons[id]
	if not button or not button:HasAction() then return end

	if button:GetButtonState() == "PUSHED" then
		button:SetButtonState("NORMAL")
		button:Click()
	end
end

function CoAMultiCastActionBarMixin:Update()
	self.actionButtonsPool:ReleaseAll()
	wipe(self.Buttons)
	self.Buttons = {}

	for i = 1, self:GetNumButtons() do
		local button, isNew = self.actionButtonsPool:Acquire()

		if isNew then
			button:RegisterCallback("OnEnterActionButton", self.OnEnterActionButton, self)
			button:RegisterCallback("OnLeaveActionButton", self.OnLeaveActionButton, self)
			button:SetDefaultTexture(self:GetDefaultTexture())
		end

		button:Update(self:GetActionInfo(i))

		if (i ~= 1) then
			button:ClearAndSetPoint("LEFT", self.Buttons[i-1], "RIGHT", 8, 0)
		end

		self.Buttons[i] = button
	end

	--[[if self.Buttons[1] then
		self.Buttons[1]:ClearAndSetPoint("CENTER", -19*((#self.Buttons)-1), 0)
	end]]--
	self:TriggerEvent("OnButtonsUpdated")
end

function CoAMultiCastActionBarMixin:OnEnterActionButton(button)
	self.FlyoutFrameOpenButton:Init(button)
end

function CoAMultiCastActionBarMixin:OnLeaveActionButton(button, force)
	if ( force or (not self.FlyoutFrameOpenButton:IsMouseOver() and not self.FlyoutFrameOpenButton:GetParent():IsMouseOver()) ) then
		self.FlyoutFrameOpenButton:Hide()
	end
end

function CoAMultiCastActionBarMixin:OnClickFlyoutButton(button)
	-- TODO: Perhabs better saving/loading logic than this
	local spellID = button:GetSpellID()
	local cvar = button:GetParent():GetParent():GetCVar()

	if cvar and C_CVar.Exists(cvar) then
		C_CVar.Set(cvar, spellID)
	--else
		--dprint("ERROR attempt to call cvar "..(cvar or "NO CVAR"))
	end

	CoA_SendNecroMulticastSelection()

	self:HideFlyout(true)

	self:Update()
end

function CoAMultiCastActionBarMixin:LoadFlyoutSpells()
	if not next(self.spells) then
		return
	end

	local totalHeight = 0
	local lastButton

	self.FlyoutFrame:ClearButtons()

	for i = 1, (#self.spells + 1) do
		local button, isNew = self.FlyoutFrame:AcquireButton()

		if isNew then
			button:SetScript("OnClick", GenerateClosure(self.OnClickFlyoutButton, self, button))
		end

		if (i == 1) or IsSpellKnown(self.spells[i-1]) then
			if i == 1 then
				button:Update(nil, self:GetDefaultTexture())
				button:SetPoint("BOTTOM", self.FlyoutFrame, "BOTTOM", 0, MULTI_CAST_FLYOUT_BUTTON_INITIAL_OFFSET)
				totalHeight = totalHeight + MULTI_CAST_FLYOUT_BUTTON_INITIAL_OFFSET
			else
				button:Update(self.spells[i-1])
				button:SetPoint("BOTTOM", lastButton, "TOP", 0, MULTI_CAST_FLYOUT_BUTTON_OFFSET)
				totalHeight = totalHeight + MULTI_CAST_FLYOUT_BUTTON_OFFSET
			end

			button:Show()
			totalHeight = totalHeight + button:GetHeight()
			lastButton = button
		end
	end

	self.FlyoutFrame:SetHeight(totalHeight + 2 + self.FlyoutFrame.CloseButton:GetHeight())
end

function CoAMultiCastActionBarMixin:HideFlyout(forceHide)
	local parent = self.FlyoutFrame:GetParent()

	if ( forceHide or not self.FlyoutFrame:IsMouseOver() ) then
		if ( parent ) then
			if ( parent:IsMouseOver() ) then
				self.FlyoutFrameOpenButton:Init(parent)
			--else
				--self.parent:UnregisterEvent("MODIFIER_STATE_CHANGED")
			end
		end

		self.FlyoutFrame:Hide()
	end
end

function CoAMultiCastActionBarMixin:ToggleFlyout(button)
	if ( self.FlyoutFrame:IsShown() and self.FlyoutFrame:GetParent() == button ) then
		self:HideFlyout(true)
		return
	end

	self:LoadFlyoutSpells()
	self.FlyoutFrame:SetParent(button)
	self.FlyoutFrame:ClearAndSetPoint("BOTTOM", button, "TOP", 0, 0)
	self.FlyoutFrame:Show()
end

function CoAMultiCastActionBarMixin:OnClickFlyoutOpenButton()
	self:ToggleFlyout(self.FlyoutFrameOpenButton:GetParent())
end

-- Settings/Dropdown
function CoAMultiCastActionBarMixin:OnMouseUp(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAMultiCastActionBarMixin:LoadCVars()
	self:SetLocked(C_CVar.GetBool(self.cvarLocked))
	self:SetSizeOption(C_CVar.GetNumber(self.cvarSize))
	self:SetShowText(C_CVar.GetBool(self.cvarShowText))
end

function CoAMultiCastActionBarMixin:SetLocked(locked)
	CoAResourceMixin.SetLocked(self, locked)
	self:TriggerEvent("OnSetLocked", locked)
end

function CoAMultiCastActionBarMixin:SetSizeOption(index)
	CoAResourceMixin.SetSizeOption(self, index)
end

function CoAMultiCastActionBarMixin:ShowDropDown()
	CoAResourceMixin.ShowDropDown(self)
end

function CoAMultiCastActionBarMixin:SavePosition()
	CoAResourceMixin.SavePosition(self)
end

function CoAMultiCastActionBarMixin:RestorePosition()
	return CoAResourceMixin.RestorePosition(self)
end

function CoAMultiCastActionBarMixin:SetShowText(show)
	self.AlwaysShowText = show

	self:TriggerEvent("OnSetShowText", show)

	C_CVar.Set(self.cvarShowText, show)
end

-- Events
function CoAMultiCastActionBarMixin:PLAYER_ENTERING_WORLD()
	self:Update()
	CoA_SendNecroMulticastSelection()

	if self:HasMultiCastActionBar() then
		self:RestorePosition()
		self:Show()
	else
		self:Hide()
	end
end

function CoAMultiCastActionBarMixin:UPDATE_MULTI_CAST_ACTIONBAR()
	self:PLAYER_ENTERING_WORLD()
end

function CoAMultiCastActionBarMixin:UPDATE_BINDINGS()
	self:Update()
end

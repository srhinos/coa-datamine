DurabilityManIconMixin = {}

function DurabilityManIconMixin:OnLoad()
	AttributesToKeyValues(self)
	self.slot = ItemLocation:CreateFromEquipmentSlot(_G[self.slot])

	SetParentArray(self, "Icons")
	self.Icon:SetAtlas(self.atlas, Const.TextureKit.UseAtlasSize)
	self.Pulse:SetAtlas(self.atlas, Const.TextureKit.UseAtlasSize)
	self:SetSize(self.Icon:GetSize())
end

function DurabilityManIconMixin:Play(looping)
	self.Pulse:Show()
	self.Pulse.Anim:Stop()
	self.Pulse.LoopingAnim:Stop()
	if looping then
		self.Pulse.LoopingAnim:Play()
	else
		self.Pulse.Anim:Play()
	end
end

function DurabilityManIconMixin:Stop()
	self.Pulse.Anim:Stop()
	self.Pulse.LoopingAnim:Stop()
	self.Pulse:Hide()
end

function DurabilityManIconMixin:SetColor(r, g, b, a)
	self.Icon:SetVertexColor(r, g, b, a)
end

function DurabilityManIconMixin:SetPulseColor(r, g, b, a)
	self.Pulse:SetVertexColor(r, g, b, a)
end

function DurabilityManIconMixin:HasItem()
	return self.slot:IsValid()
end

DurabilityManMixin = {}

function DurabilityManMixin:OnLoad()
end

function DurabilityManMixin:PlayPulse(looping)
	self.looping = looping
	for _, icon in ipairs(self.Icons) do
		icon:Play(looping)
	end
end

function DurabilityManMixin:StopPulse()
	self.looping = nil
	if self.pulseTimer then
		self.pulseTimer:Cancel()
		self.pulseTimer = nil
	end
	for _, icon in ipairs(self.Icons) do
		icon:Stop()
	end
end

function DurabilityManMixin:SetColor(r, g, b, a)
	for _, icon in ipairs(self.Icons) do
		icon:SetColor(r, g, b, a)
	end
end

function DurabilityManMixin:SetPulseColor(r, g, b, a)
	for _, icon in ipairs(self.Icons) do
		icon:SetPulseColor(r, g, b, a)
	end
end

FelCommGearWarningMixin = CreateFromMixins(DurabilityManMixin)

local function InitializeDropDown()
	if FelCommGearWarningFrame.type then
		local info = UIDropDownMenu_CreateInfo()
		info.text = CLOSE
		info.func = function()
			FelCommGearWarningFrame:Hide()
		end
		UIDropDownMenu_AddButton(info)
	end
end

function FelCommGearWarningMixin:OnLoad()
	DurabilityManMixin.OnLoad(self)
	self:SetColor(0.5, 0.85, 0.12)
	self:SetPulseColor(0.54, 0.12, 0)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterForClicks("RightButtonUp")

	UIDropDownMenu_Initialize(self.DropDown, InitializeDropDown, "MENU", 1)
end

function FelCommGearWarningMixin:OnShow()
	self:ClearAndSetPoint("RIGHT", -320, 180)
	self:SetAlpha(1)
	self:UpdateShownIcons()
	HelpTip:Show("FEL_COMM_DISABLED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function FelCommGearWarningMixin:StartHiding(hideNow)
	if self.FadeTimer then
		self.FadeTimer:Cancel()
		self.FadeTimer = nil
	end
	UIFrameFadeRemoveFrame(self)
	self:SetAlpha(1)

	if hideNow then
		local fadeInfo = {}
		fadeInfo.mode = "OUT"
		fadeInfo.timeToFade = 6
		fadeInfo.startAlpha = 1
		fadeInfo.endAlpha = 0
		fadeInfo.finishedArg1 = self
		fadeInfo.finishedFunc = self.Hide
		UIFrameFade(self, fadeInfo)
		return
	end

	self.FadeTimer = Timer.NewTimer(11, function()
		local fadeInfo = {}
		fadeInfo.mode = "OUT"
		fadeInfo.timeToFade = 6
		fadeInfo.startAlpha = 1
		fadeInfo.endAlpha = 0
		fadeInfo.finishedArg1 = self
		fadeInfo.finishedFunc = self.Hide
		UIFrameFade(self, fadeInfo)
	end)
end

function FelCommGearWarningMixin:StopHiding()
	if self.FadeTimer then
		self.FadeTimer:Cancel()
		self.FadeTimer = nil
	end
	UIFrameFadeRemoveFrame(self)
	self:SetAlpha(1)
end

function FelCommGearWarningMixin:UpdateShownIcons()
	local isLooping = self.looping
	local isPulseTimer = self.pulseTimer ~= nil
	self:StopPulse()
	for _, icon in ipairs(self.Icons) do
		if icon.slot:GetEquipmentSlot() ~= INVSLOT_OFFHAND then
			icon:SetShown(icon:HasItem())
		elseif icon:HasItem() then
			if self.Shield == icon then
				icon:SetShown(not OffhandHasWeapon())
			else
				icon:SetShown(OffhandHasWeapon())
			end
		else
			icon:Hide()
		end
	end

	if isLooping then
		self:PlayPulse(true)
	elseif isPulseTimer then
		self.pulseTimer = Timer.NewTicker(6, function()
			self:PlayPulse()
		end)
	end
end

function FelCommGearWarningMixin:OnHide()
	self:StopPulse()
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end 

function FelCommGearWarningMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(WARN_FEL_COMM_NOT_APPLIED, 1, 1, 1, 1)
	GameTooltip:AddLine(self.reason, nil, nil, nil, true)
	GameTooltip:Show()
end

function FelCommGearWarningMixin:OnLeave()
	GameTooltip:Hide()
end 

function FelCommGearWarningMixin:OnEvent(event, ...)
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		return self:UpdateShownIcons()
	end
	
	if not C_Player:IsHighRisk() then
		self.reason = nil
		self.type = nil
		self:Hide()
		return
	end

	local isHighRisk = C_PVP:GetIsCurrentMapHighRisk()

	if not isHighRisk then
		self.reason = nil
		self.type = nil
		self:Hide()
		return
	end
	
	local cost = C_HighRisk.GetInsuranceCostPerSlot()
	if not C_HighRisk.IsFelCommutationActive() then
		self.reason = FEL_COMM_DISABLE_NO_ITEMS
		self.type = 2
		self:Show()
		self:PlayPulse(true)

	elseif cost > GetMoney() then
		if self.reason == FEL_COMM_DISABLE_COST then return end

		-- play looping anim if we cant afford
		self.reason = FEL_COMM_DISABLE_COST
		self.type = 3
		self:Show()
		self:PlayPulse(true)
	else
		self:Hide()
	end
end

function FelCommGearWarningMixin:OnClick()
	CloseDropDownMenus()
	ToggleDropDownMenu(1, nil, self.DropDown, self, 0, 0)
end

HelpTips["FEL_COMM_DISABLED"] = {
	parent = "FelCommGearWarningFrame",
	text = WARN_FEL_COMM_NOT_APPLIED,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.FelComm_Disabled,
	textJustifyH = "CENTER",
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}
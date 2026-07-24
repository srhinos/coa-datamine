GhostFrameMixin = {}

function GhostFrameMixin:OnLoad()
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function GhostFrameMixin:OnEvent(event, ...)
	if event == "PLAYER_ALIVE" or event == "PLAYER_ENTERING_WORLD" then
		if self:CanShow() then
			self:Show()
		else
			self:Hide()
		end
	elseif event == "PLAYER_UNGHOST" then
		self:Hide()
	end
end

function GhostFrameMixin:OnClick()
	PlaySound(SOUNDKIT.UI_MAIN_MENU_BUTTONA_70)
	StaticPopup_Show("RETURN_GRAVEYARD_CONFIRM")
end

function GhostFrameMixin:CanShow()
	return UnitIsGhost("player") == 1 and PortGraveyard
end

function GhostFrameMixin:OnShow()
	if C_Instance.IsInPVP() then
		if ClosestResFrame:IsVisible() then
			ClosestResFrame:SetPoint("TOP", 200, -90)
			self:SetPoint("TOP", -200, -90)
		else
			self:SetPoint("TOP", -200, -90)
		end
	else
		if ClosestResFrame:IsVisible() then
			ClosestResFrame:SetPoint("TOP", 70, -90)
			self:SetPoint("TOP", -70, -90)
		else
			self:SetPoint("TOP", 0, -90)
		end
	end
end

function GhostFrameMixin:OnHide()
	if C_Instance.IsInPVP() then
		if ClosestResFrame:IsVisible() then
			ClosestResFrame:SetPoint("TOP", 200, -90)
		end
		self:SetPoint("TOP", 0, -90)
	else
		if ClosestResFrame:IsVisible() then
			ClosestResFrame:SetPoint("TOP", 0, -90)
		end
		self:SetPoint("TOP", 0, -90)
	end
	
end

ClosestResFrameMixin = CreateFromMixins(GhostFrameMixin)

function ClosestResFrameMixin:CanShow()
	if not UnitIsGhost("player") then
		return false
	end

	if C_GameMode:IsGameModeActive(Enum.GameMode.Felforged, Enum.GameMode.Ironman, Enum.GameMode.Survivalist) then
		return false
	end

	local _, instanceType = IsInInstance()
	if not instanceType or instanceType ~= "none" then
		return false
	end

	return true
end 

function ClosestResFrameMixin:OnClick()
	PlaySound(SOUNDKIT.UI_MAIN_MENU_BUTTONA_70)
	StaticPopup_Show("SAFE_RESURRECT_DIALOG")
end

function ClosestResFrameMixin:OnShow()
	self.ContentsFrame.Text:SetText(RESURRECT_IN_SAFE_ZONE)
	self.ContentsFrame.Icon:SetTexture("Interface\\Icons\\inv_misc_rune_01")
	if C_Instance.IsInPVP() then
		if GhostFrame:IsVisible() then
			GhostFrame:SetPoint("TOP", -200, -90)
			self:SetPoint("TOP", 200, -90)
		else
			self:SetPoint("TOP", 200, -90)
		end
	else
		if GhostFrame:IsVisible() then
			GhostFrame:SetPoint("TOP", -70, -90)
			self:SetPoint("TOP", 70, -90)
		else
			self:SetPoint("TOP", 0, -90)
		end
	end
	
end 

function ClosestResFrameMixin:OnHide()
	if C_Instance.IsInPVP() then
		if GhostFrame:IsVisible() then
			GhostFrame:SetPoint("TOP", -200, -90)
		end
		self:SetPoint("TOP", 0, -90)
	else
		if GhostFrame:IsVisible() then
			GhostFrame:SetPoint("TOP", 0, -90)
		end
		self:SetPoint("TOP", 0, -90)
	end
end

IronSoulNotificationMixin = {}

function IronSoulNotificationMixin:OnClick()
	StaticPopup_Show("IRON_SOUL_CONFIRM", nil, nil, function()
		CastSpellByID(84423)
		self:Hide()
	end)
end

function IronSoulNotificationMixin:OnShow()
	self.ClosestTownButton:SetWidth(self.ClosestTownButton:GetFontString():GetStringWidth()+20)
	PlaySound(SOUNDKIT.FX_HOLY_MAGIC_CAST_LARGE_03)
end
ADDITIONAL_POWER_BAR_NAME = "MANA";
ADDITIONAL_POWER_BAR_INDEX = 0;

function AlternatePowerBar_OnLoad(self)
	self.textLockable = 1;
	self.cvar = "playerStatusText";
	self.cvarLabel = "STATUS_TEXT_PLAYER";
	AlternatePowerBar_Initialize(self);
	TextStatusBar_Initialize(self);
end

function AlternatePowerBar_Initialize(self)
	local class = select(2, UnitClass("player"))
	local powerType = CLASS_ALTERNATE_POWERS[class]
	if powerType then
		self.powerName = powerType
		self.powerIndex = Enum.PowerType[powerType]
		ADDITIONAL_POWER_BAR_NAME = powerType
		ADDITIONAL_POWER_BAR_INDEX = self.powerIndex
	elseif ( not self.powerName ) then
		self.powerName = ADDITIONAL_POWER_BAR_NAME;
		self.powerIndex = ADDITIONAL_POWER_BAR_INDEX;
	end
	
	self.UnitEvent = "UNIT_"..self.powerName
	self.UnitMaxEvent = "UNIT_MAX"..self.powerName
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("UNIT_DISPLAYPOWER");
	self:RegisterEvent(self.UnitEvent)
	self:RegisterEvent(self.UnitMaxEvent)

	SetTextStatusBarText(self, _G[self:GetName().."Text"])

	local info = PowerBarColor[self.powerName];
	self:SetStatusBarColor(info.r, info.g, info.b);
end

function AlternatePowerBar_OnEvent(self, event, arg1)
	local parent = self:GetParent();
	if ( event == "UNIT_DISPLAYPOWER" ) then
		AlternatePowerBar_UpdatePowerType(self);
	elseif ( event=="PLAYER_ENTERING_WORLD" ) then
		AlternatePowerBar_UpdateMaxValues(self);
		AlternatePowerBar_UpdateValue(self);
		AlternatePowerBar_UpdatePowerType(self);
	elseif( (event == self.UnitMaxEvent) and (arg1 == parent.unit) ) then
		AlternatePowerBar_UpdateMaxValues(self);
	elseif ( self:IsShown() ) then
		if ( (event == self.UnitEvent) and (arg1 == parent.unit) ) then
			AlternatePowerBar_UpdateValue(self);
		end
	end
end

function AlternatePowerBar_OnUpdate(self, elapsed)
	AlternatePowerBar_UpdateValue(self);
end

function AlternatePowerBar_UpdateValue(self)
	local curPower = UnitPower(self:GetParent().unit, self.powerIndex);
	self:SetValue(curPower);
	self.value = curPower
end

function AlternatePowerBar_UpdateMaxValues(self)
	local maxPower = UnitPowerMax(self:GetParent().unit, self.powerIndex);
	self:SetMinMaxValues(0, maxPower);
end

function AlternatePowerBar_UpdatePowerType(self)
	if ( (UnitPowerType(self:GetParent().unit) ~= self.powerIndex) and (UnitPowerMax(self:GetParent().unit,self.powerIndex) ~= 0) ) then
		self.pauseUpdates = false;
		self:Show();
	else
		self.pauseUpdates = true;
		self:Hide();
	end
end
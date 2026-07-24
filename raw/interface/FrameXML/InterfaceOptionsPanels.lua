local next = next;
local function SecureNext(elements, key)
	return securecall(next, elements, key);
end


--
-- Set Custom Interface CVar Defaults
--

-- Option must be defined by CVar Name in PanelOptions. Ex: ControlsPanelOptions
-- Text in PanelOptions should be NAME_OF_CVAR_TEXT
-- Define GlobalString `OPTION_TOOLTIP_NAME_OF_CVAR` and `NAME_OF_CVAR_TEXT`
-- append |TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0:0:0:-1|t for new features

local function CustomCVarsLoaded()
	SetCameraFoV(C_CVar.GetNumber("camerafov"))
	--[[local angle = C_CVar.GetNumber("tabTargetAngle")
	SetTabTargetAngle(MDegToRad(angle)/2)]]
	SetNamePlateCastBarMode(C_CVar.GetNumber("showVKeyCastbar"))
end

local function OnCVarUpdate(cvar, value)
	if cvar == "SHOW_TARGET_CASTBAR_IN_V_KEY" then
		value = tonumber(value)
		if value ~= nil then
			SetNamePlateCastBarMode(value)
		end
	end
end

local function InitializeInterfaceOptions()
	CustomCVarsLoaded()
	local control = Options.GetControlForCVar("showClock");
	if control then 
		control.setFunc(GetCVar(control.cvar))
	end

	control = Options.GetControlForCVar("rotateMinimap")
	if control then
		control.setFunc(GetCVar(control.cvar));
	end

	control = Options.GetControlForCVar("chatHoverDelay")
	if control then	
		control.setFunc(GetCVar(control.cvar));
	end
	InterfaceOptionsSocialPanelProfanityFilter_UpdateDisplay();

	control = Options.GetControlForCVar("enableCombatText")
	if control then
		control.setFunc(GetCVar(control.cvar));
	end

	-- fix for bug 106687: self button can no longer be enabled if you're not a rogue or a druid
	control = Options.GetControlForCVar("fctComboPoints")
	if control then	
		control.SetChecked =
			function (self, checked)
			local _, class = UnitClass("player");
			if ( class ~= "ROGUE" and class ~= "DRUID" and class ~= "HERO" ) then
				checked = false;
			end
			getmetatable(self).__index.SetChecked(self, checked);
		end
		control.Enable =
			function (self)
			local _, class = UnitClass("player");
			if ( class ~= "ROGUE" and class ~= "DRUID" and class ~= "HERO" ) then
				return;
			end
			getmetatable(self).__index.Enable(self);
			local text = _G[self:GetName().."Text"];
			local fontObject = text:GetFontObject();
			_G[self:GetName().."Text"]:SetTextColor(fontObject:GetTextColor());
		end
		control.setFunc(GetCVar(control.cvar));
	end

	if ( GetCVar("cameraSmoothStyle") == "0" ) then
		control = Options.GetControlForCVar("cameraYawSmoothSpeed")
		if control then
			BlizzardOptionsPanel_Slider_Disable(control);
		end
		control = Options.GetControlForCVar("cameraTerrainTilt")
		if control then
			control:Disable();
		end
	end

	control = Options.GetControlForCVar("buffDurations")
	if control then
		control.setFunc(GetCVar(control.cvar));
	end

	InterfaceOptionsSocialPanelChatStyle_SetChatStyle(GetCVar("chatStyle"));
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", InitializeInterfaceOptions)
EventRegistry:RegisterFrameEventAndCallback("CVAR_UPDATE", OnCVarUpdate)

-- [[ Generic Interface Options Panel ]] --

function InterfaceOptionsPanel_Slider_OnValueChanged(slider)
	if slider.uvar then
		_G[slider.uvar] = slider:GetValue()
	end
	if slider.cvar then
		BlizzardOptionsPanel_SetCVarSafe(slider.cvar, slider:GetValue(), slider.event)
	end
	if slider.setFunc then
		slider.setFunc(slider:GetValue())
	end
end

function InterfaceOptionsPanel_CheckButton_OnClick (checkButton)
	if ( checkButton:GetChecked() and checkButton.interruptCheck ) then
		checkButton.interruptCheck(checkButton);
		checkButton:SetChecked(false);	--Make it look like the button wasn't changed, but after the interrupt function has had a chance to look at what it was set to.
		return;
	elseif ( not checkButton:GetChecked() and checkButton.interruptUncheck ) then
		checkButton.interruptUncheck(checkButton);
		checkButton:SetChecked(true);	--Make it look like the button wasn't changed, but after the interrupt function has had a chance to look at what it was set to.
		return;
	end

	InterfaceOptionsPanel_CheckButton_Update(checkButton);
end
	
function InterfaceOptionsPanel_CheckButton_Update (checkButton)
	local setting = "0";
	if ( checkButton:GetChecked() ) then
		if ( not checkButton.invert ) then
			setting = "1"
		end
	elseif ( checkButton.invert ) then
		setting = "1"
	end
	
	if ( checkButton.cvar ) then
		BlizzardOptionsPanel_SetCVarSafe(checkButton.cvar, setting, checkButton.event);
	end

	if ( checkButton.uvar ) then
		_G[checkButton.uvar] = setting;
	end

	if ( checkButton.dependentControls ) then
		if ( checkButton:GetChecked() ) then
			for _, control in SecureNext, checkButton.dependentControls do
				control:Enable();
			end
		else
			for _, control in SecureNext, checkButton.dependentControls do
				control:Disable();
			end
		end
	end

	if ( checkButton.invertedDependentControls ) then
		if ( checkButton:GetChecked() ) then
			for _, control in SecureNext, checkButton.invertedDependentControls do
				control:Disable();
			end
		else
			for _, control in SecureNext, checkButton.invertedDependentControls do
				control:Enable();
			end
		end
	end

	if ( checkButton.setFunc ) then
		checkButton.setFunc(setting);
	end

	-- addons can taint this i guess
	if ( setting == checkButton.value ) then
		checkButton.newValue = nil;
	else
		checkButton.newValue = setting;
	end
end


local function InterfaceOptionsPanel_CancelControl (control)
	if ( control.oldValue ) then
		if ( control.value and control.value ~= control.oldValue ) then
			control:SetValue(control.oldValue);
		end
	elseif ( control.value ) then
		if ( control:GetValue() ~= control.value ) then
			control:SetValue(control.value);
		end
	end
end

local function InterfaceOptionsPanel_DefaultControl (control)
	if ( control.defaultValue and control.value ~= control.defaultValue ) then
		control:SetValue(control.defaultValue);
		control.value = control.defaultValue;
	end
end

function InterfaceOptionsPanel_Okay (self)
	for _, control in SecureNext, self.controls do
		securecall(BlizzardOptionsPanel_OkayControl, control);
	end
end

function InterfaceOptionsPanel_Cancel (self)
	for _, control in SecureNext, self.controls do
		securecall(InterfaceOptionsPanel_CancelControl, control);
		if ( control.setFunc ) then
			control.setFunc(control:GetValue());
		end
	end
end

function InterfaceOptionsPanel_Default (self)
	for _, control in SecureNext, self.controls do
		securecall(InterfaceOptionsPanel_DefaultControl, control);
		if ( control.setFunc ) then
			control.setFunc(control:GetValue());
		end
	end
end

function InterfaceOptionsPanel_Refresh (self)
	for _, control in SecureNext, self.controls do
		securecall(BlizzardOptionsPanel_RefreshControl, control);
		-- record values so we can cancel back to this state
		control.oldValue = control.value;
	end
end


function InterfaceOptionsPanel_OnLoad (self)
	BlizzardOptionsPanel_OnLoad(self, nil, InterfaceOptionsPanel_Cancel, InterfaceOptionsPanel_Default, InterfaceOptionsPanel_Refresh);
	InterfaceOptions_AddCategory(self);
end


-- [[ Controls Options Panel ]] --

ControlsPanelOptions = {
	deselectOnClick = { text = "GAMEFIELD_DESELECT_TEXT" },
	autoDismountFlying = { text = "AUTO_DISMOUNT_FLYING_TEXT" },
	autoClearAFK = { text = "CLEAR_AFK" },
	blockTrades = { text = "BLOCK_TRADES" },
	lootUnderMouse = { text = "LOOT_UNDER_MOUSE_TEXT" },
	autoLootDefault = { text = "AUTO_LOOT_DEFAULT_TEXT" }, -- When this gets changed, the function SetAutoLootDefault needs to get run with its value.
	autoLootKey = { text = "AUTO_LOOT_KEY_TEXT", default = "NONE" },
	holdToCast = { text = "HOLD_TO_CAST_TEXT" },
	tabTargetFacing = { text = "TAB_TARGET_FACING_TEXT" },
	tabTargetPriorityCombat = { text = "TAB_TARGET_PRIO_COMBAT_TEXT" },
	tabTargetRange = { text = "TAB_TARGET_RANGE_TEXT", minValue = 5, maxValue = 100, valueStep = 5 },
	tabTargetAngle = { text = "TAB_TARGET_ANGLE_TEXT", minValue = 10, maxValue = 360, valueStep = 5 },
	tabTargetPriorityPlayers = { text = "TAB_TARGET_PRIO_PLAYERS_TEXT" },
	tabTargetIgnoreNotLOS = { text = "TAB_TARGET_IGNORE_NOT_LOS_TEXT" },
	tabTargetPriorityInLOS = { text = "TAB_TARGET_PRIO_LOS_TEXT" }
}

function InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnLoad(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("AUTOLOOTTOGGLE");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_AUTO_LOOT_"..self.value.."_KEY"];

	UIDropDownMenu_SetWidth(self, 110);
	UIDropDownMenu_Initialize(self, InterfaceOptionsControlsPanelAutoLootKeyDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			UIDropDownMenu_SetSelectedValue(self, value);
			SetModifiedClick("AUTOLOOTTOGGLE", value);
			SaveBindings(GetCurrentBindingSet());
			self.tooltip = _G["OPTION_TOOLTIP_AUTO_LOOT_"..value.."_KEY"];
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsControlsPanelAutoLootKeyDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end

	if ( GetCVar("autoLootDefault") == "1" ) then
		self.Label:SetText(LOOT_KEY_TEXT);
	else
		self.Label:SetText(AUTO_LOOT_KEY_TEXT);
	end
end

function InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnShow(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("AUTOLOOTTOGGLE");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_AUTO_LOOT_"..self.value.."_KEY"];
	UIDropDownMenu_SetSelectedValue(self, self.value);
	InterfaceOptionsControlsPanelAutoLootKeyDropDown_Update(self.value)

	if ( GetCVar("autoLootDefault") == "1" ) then
		self.Label:SetText(LOOT_KEY_TEXT);
	else
		self.Label:SetText(AUTO_LOOT_KEY_TEXT);
	end
end

function InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnClick(self)
	InterfaceOptionsControlsPanelAutoLootKeyDropDown:SetValue(self.value);
end

function InterfaceOptionsControlsPanelAutoLootKeyDropDown_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsControlsPanelAutoLootKeyDropDown);
	local info = UIDropDownMenu_CreateInfo();

	info.text = ALT_KEY;
	info.func = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnClick;
	info.value = "ALT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALT_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_LOOT_ALT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = CTRL_KEY;
	info.func = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnClick;
	info.value = "CTRL";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CTRL_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_LOOT_CTRL_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = SHIFT_KEY;
	info.func = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnClick;
	info.value = "SHIFT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = SHIFT_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_LOOT_SHIFT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = NONE_KEY;
	info.func = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnClick;
	info.value = "NONE";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NONE_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_LOOT_NONE_KEY;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsControlsPanelAutoLootKeyDropDown_Update(value)
	if value == "1" then
		InterfaceOptionsControlsPanelAutoLootKeyDropDownLabel:SetText(LOOT_KEY_TEXT);
	else
		InterfaceOptionsControlsPanelAutoLootKeyDropDownLabel:SetText(AUTO_LOOT_KEY_TEXT);
	end
end

-- [[ Combat Options Panel ]] --

CombatPanelOptions = {
	assistAttack = { text = "ASSIST_ATTACK" },
	autoRangedCombat = { text = "AUTO_RANGED_COMBAT_TEXT" },
	autoSelfCast = { text = "AUTO_SELF_CAST_TEXT" },
	stopAutoAttackOnTargetChange = { text = "STOP_AUTO_ATTACK" },
	showTargetOfTarget = { text = "SHOW_TARGET_OF_TARGET_TEXT" },
	showTargetCastbar = { text = "SHOW_TARGET_CASTBAR" },
	showVKeyCastbar = { text = "SHOW_TARGET_CASTBAR_IN_V_KEY" },
	SpellActivationOverlayAlpha = { text = "SPELL_ACTIVATION_OVERLAY", minValue = 0, maxValue = 1, valueStep = 0.05 },
	aoeRadiusIndicatorSelf = { text = "AOE_RADIUS_INDICATOR_SELF" },
	aoeRadiusIndicatorEnemy = { text = "AOE_RADIUS_INDICATOR_ENEMY" },
	aoeRadiusIndicatorFriendly = { text = "AOE_RADIUS_INDICATOR_FRIEND" },
	SpellShadowShowBad = { text = "SPELL_SHADOW_SHOW_BAD" },
}

function InterfaceOptionsCombatPanelTOTDropDown_OnLoad(self)
	self.cvar = "targetOfTargetMode";

	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_TOOLTIP_TARGETOFTARGET" .. value];
	_G[self.uvar] = value;

	UIDropDownMenu_SetWidth(self, 110);	
	UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelTOTDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue =
		function (self, value)
			self.value = value;
			SetCVar(self.cvar, value);
			_G[self.uvar] = value;
			UIDropDownMenu_SetSelectedValue(self, value);
			self.tooltip = _G["OPTION_TOOLTIP_TARGETOFTARGET" .. value];
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelTOTDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsCombatPanelTOTDropDown_OnShow(self)
	self.defaultValue = GetCVarDefault(self.cvar);
	self.oldValue = GetCVar(self.cvar);
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_TARGETOFTARGET" .. self.value];
	UIDropDownMenu_SetSelectedValue(self, self.value);
end


function InterfaceOptionsCombatPanelTOTDropDown_OnEvent (self, event, ...)
end

function InterfaceOptionsCombatPanelTOTDropDown_OnClick(self)
	InterfaceOptionsCombatPanelTOTDropDown:SetValue(self.value);
end

function InterfaceOptionsCombatPanelTOTDropDown_Initialize(self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();

	info.text = RAID;
	info.func = InterfaceOptionsCombatPanelTOTDropDown_OnClick;
	info.value = "1"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = RAID;
	info.tooltipText = OPTION_TOOLTIP_TARGETOFTARGET_RAID;
	UIDropDownMenu_AddButton(info);

	info.text = PARTY;
	info.func = InterfaceOptionsCombatPanelTOTDropDown_OnClick;
	info.value = "2"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = PARTY;
	info.tooltipText = OPTION_TOOLTIP_TARGETOFTARGET_PARTY;
	UIDropDownMenu_AddButton(info);

	info.text = SOLO;
	info.func = InterfaceOptionsCombatPanelTOTDropDown_OnClick;
	info.value = "3"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = SOLO;
	info.tooltipText = OPTION_TOOLTIP_TARGETOFTARGET_SOLO;
	UIDropDownMenu_AddButton(info);

	info.text = RAID_AND_PARTY;
	info.func = InterfaceOptionsCombatPanelTOTDropDown_OnClick;
	info.value = "4"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = RAID_AND_PARTY;
	info.tooltipText = OPTION_TOOLTIP_TARGETOFTARGET_RAID_AND_PARTY;
	UIDropDownMenu_AddButton(info);

	info.text = ALWAYS;
	info.func = InterfaceOptionsCombatPanelTOTDropDown_OnClick;
	info.value = "5"
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_TARGETOFTARGET_ALWAYS;
	UIDropDownMenu_AddButton(info);
end

-- [[ Self Cast key dropdown ]] --
function InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnLoad(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("SELFCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_AUTO_SELF_CAST_"..self.value.."_KEY"];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelSelfCastKeyDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);

	self.SetValue = 
		function (self, value) 
			self.value = value;
			UIDropDownMenu_SetSelectedValue(self, value);
			SetModifiedClick("SELFCAST", value);
			SaveBindings(GetCurrentBindingSet());
			self.tooltip = _G["OPTION_TOOLTIP_AUTO_SELF_CAST_"..value.."_KEY"];
		end;
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelSelfCastKeyDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnShow(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("SELFCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_AUTO_SELF_CAST_"..self.value.."_KEY"];
	UIDropDownMenu_SetSelectedValue(self, self.value);
end


function InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnClick(self)
	InterfaceOptionsCombatPanelSelfCastKeyDropDown:SetValue(self.value);
end

function InterfaceOptionsCombatPanelSelfCastKeyDropDown_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsCombatPanelSelfCastKeyDropDown);
	local info = UIDropDownMenu_CreateInfo();

	info.text = ALT_KEY;
	info.func = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnClick;
	info.value = "ALT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALT_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_SELF_CAST_ALT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = CTRL_KEY;
	info.func = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnClick;
	info.value = "CTRL";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CTRL_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_SELF_CAST_CTRL_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = SHIFT_KEY;
	info.func = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnClick;
	info.value = "SHIFT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = SHIFT_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_SELF_CAST_SHIFT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = NONE_KEY;
	info.func = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnClick;
	info.value = "NONE";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NONE_KEY;
	info.tooltipText = OPTION_TOOLTIP_AUTO_SELF_CAST_NONE_KEY;
	UIDropDownMenu_AddButton(info);
end

-- [[ Focus Cast key dropdown ]] --

function InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnLoad(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("FOCUSCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_FOCUS_CAST_"..self.value.."_KEY"];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelFocusCastKeyDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);

	self.SetValue =
		function (self, value)
			self.value = value;
			UIDropDownMenu_SetSelectedValue(self, value);
			SetModifiedClick("FOCUSCAST", value);
			SaveBindings(GetCurrentBindingSet());
			self.tooltip = _G["OPTION_TOOLTIP_FOCUS_CAST_"..value.."_KEY"];
		end;
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsCombatPanelFocusCastKeyDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnShow(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("FOCUSCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_FOCUS_CAST_"..self.value.."_KEY"];
	UIDropDownMenu_SetSelectedValue(self, self.value);
end



function InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnEvent (self, event, ...)
end

function InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnClick(self)
	InterfaceOptionsCombatPanelFocusCastKeyDropDown:SetValue(self.value);
end

function InterfaceOptionsCombatPanelFocusCastKeyDropDown_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsCombatPanelFocusCastKeyDropDown);
	local info = UIDropDownMenu_CreateInfo();

	info.text = ALT_KEY;
	info.func = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnClick;
	info.value = "ALT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALT_KEY;
	info.tooltipText = OPTION_TOOLTIP_FOCUS_CAST_ALT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = CTRL_KEY;
	info.func = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnClick;
	info.value = "CTRL";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CTRL_KEY;
	info.tooltipText = OPTION_TOOLTIP_FOCUS_CAST_CTRL_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = SHIFT_KEY;
	info.func = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnClick;
	info.value = "SHIFT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = SHIFT_KEY;
	info.tooltipText = OPTION_TOOLTIP_FOCUS_CAST_SHIFT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = NONE_KEY;
	info.func = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnClick;
	info.value = "NONE";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NONE_KEY;
	info.tooltipText = OPTION_TOOLTIP_FOCUS_CAST_NONE_KEY;
	UIDropDownMenu_AddButton(info);
end


-- [[ Display Options Panel ]] --

DisplayPanelOptions = {
	rotateMinimap = { text = "ROTATE_MINIMAP" },
	screenEdgeFlash = { text = "SHOW_FULLSCREEN_STATUS_TEXT" },
	showLootSpam = { text = "SHOW_LOOT_SPAM" },
	displayFreeBagSlots = { text = "DISPLAY_FREE_BAG_SLOTS" },
	showClock = { text = "SHOW_CLOCK" },
	movieSubtitle = { text = "CINEMATIC_SUBTITLES" },
	threatShowNumeric = { text = "SHOW_NUMERIC_THREAT" },
	threatPlaySounds = { text = "PLAY_AGGRO_SOUNDS" },
	colorblindMode = { text = "USE_COLORBLIND_MODE" },
	showItemLevel = { text = "SHOW_ITEM_LEVEL" },
	HighlightNewItems = { text = "SHOW_NEW_ITEMS" },
	showInGameNavigation = { text = "SHOW_IN_GAME_NAVIGATION" },
}

function InterfaceOptionsDisplayPanel_OnLoad (self)
	self.name = DISPLAY_LABEL;
	self.options = DisplayPanelOptions;
	InterfaceOptionsPanel_OnLoad(self);

	self:SetScript("OnEvent", InterfaceOptionsDisplayPanel_OnEvent);
end

function InterfaceOptionsDisplayPanel_OnEvent (self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		local control;

		control = InterfaceOptionsDisplayPanelShowClock;
		control.setFunc(GetCVar(control.cvar));

		control = InterfaceOptionsDisplayPanelRotateMinimap;
		control.setFunc(GetCVar(control.cvar));
	end
end

function InterfaceOptionsDisplayPanelShowClock_SetFunc(value)
	if ( value == "1" ) then
		TimeManager_LoadUI();
		if ( TimeManagerClockButton_Show ) then
			TimeManagerClockButton_Show();
		end
	else
		if ( TimeManagerClockButton_Hide ) then
			TimeManagerClockButton_Hide();
		end
	end
end

function InterfaceOptionsDisplayPanelShowAggroPercentage_SetFunc()
	UnitFrame_Update(TargetFrame);
	UnitFrame_Update(FocusFrame);
end

function InterfaceOptionsDisplayPanelPreviewTalentChanges_SetFunc()
	if ( PlayerTalentFrame and PlayerTalentFrame:IsShown() and PlayerTalentFrame_Refresh ) then
		PlayerTalentFrame_Refresh();
	end
end

function InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		self.cvar = "displayWorldPVPObjectives";

		local value = GetCVar(self.cvar);
		self.defaultValue = GetCVarDefault(self.cvar);
		self.oldValue = value;
		self.value = value;
		self.tooltip = _G["OPTION_TOOLTIP_WORLD_PVP_DISPLAY"..value];

		UIDropDownMenu_SetWidth(self, 90);
		UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_Initialize);
		UIDropDownMenu_SetSelectedValue(self, value);

		WORLD_PVP_OBJECTIVES_DISPLAY = value;
		WorldStateAlwaysUpFrame_Update();

		self.SetValue = 
			function (self, value)
				self.value = value;
				SetCVar(self.cvar, value, self.event);
				self.tooltip = _G["OPTION_TOOLTIP_WORLD_PVP_DISPLAY"..value];
				UIDropDownMenu_SetSelectedValue(self, value);
				WORLD_PVP_OBJECTIVES_DISPLAY = value;
				WorldStateAlwaysUpFrame_Update();
			end
		self.GetValue =
			function (self)
				return UIDropDownMenu_GetSelectedValue(self);
			end
		self.RefreshValue =
			function (self)
				UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_Initialize);
				UIDropDownMenu_SetSelectedValue(self, self.value);
			end
			
		self:UnregisterEvent(event);
	end
end

function InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_OnClick(self)
	InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay:SetValue(self.value);
end

function InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay);
	local info = UIDropDownMenu_CreateInfo();

	info.text = ALWAYS;
	info.func = InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_OnClick;
	info.value = "1";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_WORLD_PVP_DISPLAY_ALWAYS;
	UIDropDownMenu_AddButton(info);

	info.text = DYNAMIC;
	info.func = InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_OnClick;
	info.value = "2";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = DYNAMIC;
	info.tooltipText = OPTION_TOOLTIP_WORLD_PVP_DISPLAY_DYNAMIC;
	UIDropDownMenu_AddButton(info);

	info.text = NEVER;
	info.func = InterfaceOptionsDisplayPanelWorldPVPObjectiveDisplay_OnClick;
	info.value = "3";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NEVER;
	info.tooltipText = OPTION_TOOLTIP_WORLD_PVP_DISPLAY_NEVER;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsDisplayPanelAggroWarningDisplay_OnEvent (self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		self.cvar = "threatWarning";

		local value = GetCVar(self.cvar);
		self.defaultValue = GetCVarDefault(self.cvar);
		self.value = value;
		self.oldValue = value;
		self.tooltip = _G["OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY"..(value+1)];

		UIDropDownMenu_SetWidth(self, 90);
		UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelAggroWarningDisplay_Initialize);
		UIDropDownMenu_SetSelectedValue(self, value);

		self.SetValue = 
			function (self, value)
				self.value = value;
				SetCVar(self.cvar, value, self.event);
				UIDropDownMenu_SetSelectedValue(self, value);
				self.tooltip = _G["OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY"..(value+1)];
			end
		self.GetValue =
			function (self)
				return UIDropDownMenu_GetSelectedValue(self);
			end
		self.RefreshValue =
			function (self)
				UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelAggroWarningDisplay_Initialize);
				UIDropDownMenu_SetSelectedValue(self, self.value);
			end
			
		self:UnregisterEvent(event);
	end
end

function InterfaceOptionsDisplayPanelAggroWarningDisplay_OnClick(self)
	InterfaceOptionsDisplayPanelAggroWarningDisplay:SetValue(self.value);
end

function InterfaceOptionsDisplayPanelAggroWarningDisplay_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsDisplayPanelAggroWarningDisplay);
	local info = UIDropDownMenu_CreateInfo();
	info.tooltipOnButton = 1;

	info.text = ALWAYS;
	info.func = InterfaceOptionsDisplayPanelAggroWarningDisplay_OnClick;
	info.value = "3";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY4;
	UIDropDownMenu_AddButton(info);

	info.text = AGGRO_WARNING_IN_INSTANCE;
	info.func = InterfaceOptionsDisplayPanelAggroWarningDisplay_OnClick;
	info.value = "1";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = AGGRO_WARNING_IN_INSTANCE;
	info.tooltipText = OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY2;
	UIDropDownMenu_AddButton(info);

	info.text = AGGRO_WARNING_IN_PARTY;
	info.func = InterfaceOptionsDisplayPanelAggroWarningDisplay_OnClick;
	info.value = "2";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = AGGRO_WARNING_IN_PARTY;
	info.tooltipText = OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY3;
	UIDropDownMenu_AddButton(info);

	info.text = NEVER;
	info.func = InterfaceOptionsDisplayPanelAggroWarningDisplay_OnClick;
	info.value = "0";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NEVER;
	info.tooltipText = OPTION_TOOLTIP_AGGRO_WARNING_DISPLAY1;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsDisplayPanelSelectionCircle_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsDisplayPanelSelectionCircle);
	local info = UIDropDownMenu_CreateInfo();
	info.tooltipOnButton = 1;
	info.func = InterfaceOptionsDisplayPanelSelectionCircle_OnClick;

	info.text = OPTION_SELECTION_CIRCLE_0;
	info.value = "0";
	info.checked = info.value == selectedValue and 1 or nil
	info.tooltipTitle = OPTION_SELECTION_CIRCLE_0;
	info.tooltipText = OPTION_TOOLTIP_SELECTION_CIRCLE_0;
	UIDropDownMenu_AddButton(info);

	info.text = OPTION_SELECTION_CIRCLE_1;
	info.value = "1";
	info.checked = info.value == selectedValue and 1 or nil
	info.tooltipTitle = OPTION_SELECTION_CIRCLE_1;
	info.tooltipText = OPTION_TOOLTIP_SELECTION_CIRCLE_1;
	UIDropDownMenu_AddButton(info);

	info.text = OPTION_SELECTION_CIRCLE_2;
	info.value = "2";
	info.checked = info.value == selectedValue and 1 or nil
	info.tooltipTitle = OPTION_SELECTION_CIRCLE_2;
	info.tooltipText = OPTION_TOOLTIP_SELECTION_CIRCLE_2;
	UIDropDownMenu_AddButton(info);

	info.text = OPTION_SELECTION_CIRCLE_3;
	info.value = "3";
	info.checked = info.value == selectedValue and 1 or nil
	info.tooltipTitle = OPTION_SELECTION_CIRCLE_3;
	info.tooltipText = OPTION_TOOLTIP_SELECTION_CIRCLE_3;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsDisplayPanelSelectionCircle_OnLoad (self)
	self.cvar = "ObjectSelectionCircleTexture";

	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_SELECTION_CIRCLE_"..strupper(value)];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelSelectionCircle_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue =
	function (self, value)
		self.value = value;
		SetCVar(self.cvar, self.value);
		self.tooltip = _G["OPTION_SELECTION_CIRCLE_"..strupper(value)];
		UIDropDownMenu_SetSelectedValue(self, self.value);
	end
	self.GetValue =
	function (self)
		return UIDropDownMenu_GetSelectedValue(self);
	end
	self.RefreshValue =
	function (self)
		UIDropDownMenu_Initialize(self, InterfaceOptionsDisplayPanelSelectionCircle_Initialize);
		UIDropDownMenu_SetSelectedValue(self, self.value);
	end
end

function InterfaceOptionsDisplayPanelSelectionCircle_OnShow (self)
	local value = GetCVar(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_SELECTION_CIRCLE_"..strupper(value)];
	UIDropDownMenu_SetSelectedValue(self, value);
end

function InterfaceOptionsDisplayPanelSelectionCircle_OnClick(self)
	InterfaceOptionsDisplayPanelSelectionCircle:SetValue(self.value);
end

-- [[ Objectives Options Panel ]] --

ObjectivesPanelOptions = {
	questFadingDisable = { text = "SHOW_QUEST_FADING_TEXT" },
	autoQuestWatch = { text = "AUTO_QUEST_WATCH_TEXT" },
	autoQuestProgress = { text = "AUTO_QUEST_PROGRESS_TEXT" },
	mapQuestDifficulty = { text = "MAP_QUEST_DIFFICULTY_TEXT" },
	advancedWorldMap = { text = "ADVANCED_WORLD_MAP_TEXT" },
	watchFrameWidth = { text = "WATCH_FRAME_WIDTH_TEXT" },
	ptaAutoQuestEnabled = { text = "POPUP_PTA_QUESTS_TEXT", disableTooltip = format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, GetMaxLevel()) },
}

function InterfaceOptionsObjectivesPanel_OnLoad (self)
	self.name = OBJECTIVES_LABEL;
	self.options = ObjectivesPanelOptions;
	InterfaceOptionsPanel_OnLoad(self);
	
	self:SetScript("OnEvent", InterfaceOptionsObjectivesPanel_OnEvent);
end

function InterfaceOptionsObjectivesPanel_OnEvent (self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);
end

-- [[ Social Options Panel ]] --

SocialPanelOptions = {
	profanityFilter = { text = "PROFANITY_FILTER" },	--The tooltip text is also directly set in InterfaceOptionsSocialPanelProfanityFilter_UpdateDisplay
	chatBubbles = { text="CHAT_BUBBLES_TEXT" },
	chatBubblesNameplate = { text = "CHAT_BUBBLES_NAMEPLATE" },
	chatBubblesParty = { text="PARTY_CHAT_BUBBLES_TEXT" },
	spamFilter = { text="DISABLE_SPAM_FILTER" },
	removeChatDelay = { text="REMOVE_CHAT_DELAY_TEXT" },
	guildMemberNotify = { text="GUILDMEMBER_ALERT" },
	guildRecruitmentChannel = { text="AUTO_JOIN_GUILD_CHANNEL" },
	showChatIcons = { text="SHOW_CHAT_ICONS" },	
	wholeChatWindowClickable = { text = "CHAT_WHOLE_WINDOW_CLICKABLE" },
	chatMouseScroll = { text = "CHAT_MOUSE_WHEEL_SCROLL" },
}

function InterfaceOptionsSocialPanel_OnLoad (self)
	if ( not BNFeaturesEnabled() ) then
		local conversationCheckBox = InterfaceOptionsSocialPanelConversationMode;
		local timestampCheckBox = InterfaceOptionsSocialPanelTimestamps;
		conversationCheckBox:UnregisterEvent("VARIABLES_LOADED");
		conversationCheckBox:Hide();
		timestampCheckBox:ClearAllPoints();
		timestampCheckBox:SetPoint("TOPLEFT", conversationCheckBox);
	end
	self.name = SOCIAL_LABEL;
	self.options = SocialPanelOptions;
	InterfaceOptionsPanel_OnLoad(self);

	self.okay = function (self)
		InterfaceOptionsPanel_Okay(self);
	end

	self:RegisterEvent("BN_DISCONNECTED");
	self:RegisterEvent("BN_CONNECTED");
	self:SetScript("OnEvent", InterfaceOptionsSocialPanel_OnEvent);
end

function InterfaceOptionsSocialPanel_OnEvent(self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		local control;

		control = InterfaceOptionsSocialPanelChatHoverDelay;
		control.setFunc(GetCVar(control.cvar));
		InterfaceOptionsSocialPanelProfanityFilter_UpdateDisplay();
	elseif ( event == "BN_DISCONNECTED" or event == "BN_CONNECTED" ) then
		InterfaceOptionsSocialPanelProfanityFilter_UpdateDisplay();
	end
end

--If the option won't be saved due to Battle.net being down, we want to warn the person.
function InterfaceOptionsSocialPanelProfanityFilter_UpdateDisplay()
	if ( not BNFeaturesEnabled() or BNConnected() ) then
		InterfaceOptionsSocialPanelProfanityFilterText:SetFontObject(GameFontHighlight);
		InterfaceOptionsSocialPanelProfanityFilter.tooltipText = OPTION_TOOLTIP_PROFANITY_FILTER;
	else
		InterfaceOptionsSocialPanelProfanityFilterText:SetFontObject(GameFontRed);
		InterfaceOptionsSocialPanelProfanityFilter.tooltipText = OPTION_TOOLTIP_PROFANITY_FILTER_WITH_WARNING;
	end
end

function InterfaceOptionsSocialPanelProfanityFilter_SyncWithBattlenet()
	local button = InterfaceOptionsSocialPanelProfanityFilter;
	if ( BNFeaturesEnabledAndConnected() ) then
		local isEnabled = BNGetMatureLanguageFilter();
		button:SetChecked(isEnabled);
		SetCVar(button.cvar, isEnabled and "1" or "0");
		InterfaceOptionsPanel_CheckButton_Update(button);
	end
end

function InterfaceOptionsSocialPanelChatMouseScroll_SetScrolling(receiveMouseScroll)
	if ( receiveMouseScroll == "1" ) then
		for _, frameName in pairs(CHAT_FRAMES) do
			local frame = _G[frameName];
			frame:SetScript("OnMouseWheel", FloatingChatFrame_OnMouseScroll);
			frame:EnableMouseWheel(true);
		end
	else
		for _, frameName in pairs(CHAT_FRAMES) do
			local frame = _G[frameName];
			frame:SetScript("OnMouseWheel", nil);
			frame:EnableMouseWheel(false);
		end
	end
end

function InterfaceOptionsSocialPanelChatStyle_OnLoad (self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_CHAT_STYLE_"..strupper(value)];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelChatStyle_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			InterfaceOptionsSocialPanelChatStyle_SetChatStyle(value);
			self.tooltip = _G["OPTION_CHAT_STYLE_"..strupper(value)];
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelChatStyle_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsSocialPanelChatStyle_OnShow (self)
	local value = GetCVar(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_CHAT_STYLE_"..strupper(value)];

	UIDropDownMenu_SetSelectedValue(self, value);
	InterfaceOptionsSocialPanelChatStyle_SetChatStyle(value);
end	

function InterfaceOptionsSocialPanelChatStyle_OnEvent (self, event, ...)
end

function InterfaceOptionsSocialPanelChatStyle_OnClick(self)
	InterfaceOptionsSocialPanelChatStyle:SetValue(self.value);
end

function InterfaceOptionsSocialPanelChatStyle_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsSocialPanelChatStyle);
	local info = UIDropDownMenu_CreateInfo();

	info.text = IM_STYLE;
	info.func = InterfaceOptionsSocialPanelChatStyle_OnClick;
	info.value = "im";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	
	info.tooltipTitle = IM_STYLE;
	info.tooltipText = OPTION_CHAT_STYLE_IM;
	UIDropDownMenu_AddButton(info);

	info.text = CLASSIC_STYLE;
	info.func = InterfaceOptionsSocialPanelChatStyle_OnClick;
	info.value = "classic";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CLASSIC_STYLE;
	info.tooltipText = OPTION_CHAT_STYLE_CLASSIC;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsSocialPanelChatStyle_SetChatStyle(chatStyle)
	SetCVar("chatStyle", chatStyle, "chatStyle");
	
	if ( chatStyle == "classic" ) then
		DEFAULT_CHAT_FRAME.editBox:SetParent(UIParent);
		InterfaceOptionsSocialPanelWholeChatWindowClickable:Hide();
	elseif ( chatStyle == "im" ) then
		DEFAULT_CHAT_FRAME.editBox:SetParent(DEFAULT_CHAT_FRAME);
		InterfaceOptionsSocialPanelWholeChatWindowClickable:Show();
	else
		error("Unhandled chat style: "..tostring(chatStyle));
	end
	
	for _, frameName in pairs(CHAT_FRAMES) do
		local frame = _G[frameName];
		ChatEdit_DeactivateChat(frame.editBox);
	end
	ChatEdit_ActivateChat(FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK).editBox);
	ChatEdit_DeactivateChat(FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK).editBox);
	
	UIDropDownMenu_SetSelectedValue(InterfaceOptionsSocialPanelChatStyle,chatStyle);
end

function InterfaceOptionsSocialPanelConversationMode_OnLoad (self)
	self.cvar = "conversationMode";

	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_CONVERSATION_MODE_"..strupper(value)];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelConversationMode_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			SetCVar(self.cvar, self.value);
			self.tooltip = _G["OPTION_CONVERSATION_MODE_"..strupper(value)];
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelConversationMode_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsSocialPanelConversationMode_OnShow (self)
	local value = GetCVar(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_CONVERSATION_MODE_"..strupper(value)];
	UIDropDownMenu_SetSelectedValue(self, value);
end

function InterfaceOptionsSocialPanelConversationMode_OnEvent (self, event, ...)
end

function InterfaceOptionsSocialPanelConversationMode_OnClick(self)
	InterfaceOptionsSocialPanelConversationMode:SetValue(self.value);
end

function InterfaceOptionsSocialPanelConversationMode_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsSocialPanelConversationMode);
	local info = UIDropDownMenu_CreateInfo();

	info.text = CONVERSATION_MODE_POPOUT;
	info.func = InterfaceOptionsSocialPanelConversationMode_OnClick;
	info.value = "popout";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	
	info.tooltipTitle = CONVERSATION_MODE_POPOUT;
	info.tooltipText = OPTION_CONVERSATION_MODE_POPOUT;
	UIDropDownMenu_AddButton(info);

	info.text = CONVERSATION_MODE_INLINE;
	info.func = InterfaceOptionsSocialPanelConversationMode_OnClick;
	info.value = "inline";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CONVERSATION_MODE_INLINE;
	info.tooltipText = OPTION_CONVERSATION_MODE_INLINE;
	UIDropDownMenu_AddButton(info);
end

function InterfaceOptionsSocialPanelTimestamps_OnLoad (self)
	self.cvar = "showTimestamps";

	local value = GetCVar(self.cvar);
	if ( value == "none" ) then
		CHAT_TIMESTAMP_FORMAT = nil;
	else
		CHAT_TIMESTAMP_FORMAT = value;
	end
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = OPTION_TOOLTIP_TIMESTAMPS;

	UIDropDownMenu_SetWidth(self, 110);
	UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelTimestamps_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			SetCVar(self.cvar, self.value);
			if ( value == "none" ) then
				CHAT_TIMESTAMP_FORMAT = nil;
			else
				CHAT_TIMESTAMP_FORMAT = value;
			end
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsSocialPanelTimestamps_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsSocialPanelTimestamps_OnShow (self)
	local value = GetCVar(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = _G["OPTION_CONVERSATION_MODE_"..strupper(value)];
	UIDropDownMenu_SetSelectedValue(self, value);
end

function InterfaceOptionsSocialPanelTimestamps_OnEvent (self, event, ...)
end

function InterfaceOptionsSocialPanelTimestamps_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsSocialPanelTimestamps);
	local info = UIDropDownMenu_CreateInfo();
	
	info.func = InterfaceOptionsSocialPanelTimestamps_OnClick;
	info.value = "none";
	info.text = TIMESTAMP_FORMAT_NONE;
	info.checked = info.value == selectedValue;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMM, info, selectedValue);
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMMSS, info, selectedValue);
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMM_AMPM, info, selectedValue);
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMMSS_AMPM, info, selectedValue);
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMM_24HR, info, selectedValue);
	InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(TIMESTAMP_FORMAT_HHMMSS_24HR, info, selectedValue);
end

local exampleTime = {
	year = 2010,
	month = 12,
	day = 15,
	hour = 15,
	min = 27,
	sec = 32,
}

function InterfaceOptionsSocialPanelTimestamps_AddTimestampFormat(timestampFormat, infoTable, selectedValue)
	assert(infoTable);
	infoTable.func = InterfaceOptionsSocialPanelTimestamps_OnClick;
	infoTable.value = timestampFormat;
	infoTable.text = BetterDate(timestampFormat, time(exampleTime));
	infoTable.checked = (selectedValue == timestampFormat);
	UIDropDownMenu_AddButton(infoTable, UIDROPDOWNMENU_MENU_LEVEL);
end

function InterfaceOptionsSocialPanelTimestamps_OnClick(self)
	InterfaceOptionsSocialPanelTimestamps:SetValue(self.value);
end

-- [[ ActionBars Options Panel ]] --

ActionBarsPanelOptions = {
	bottomLeftActionBar = { text = "SHOW_MULTIBAR1_TEXT", default = "0" },
	bottomRightActionBar = { text = "SHOW_MULTIBAR2_TEXT", default = "0" },
	rightActionBar = { text = "SHOW_MULTIBAR3_TEXT", default = "0" },
	rightTwoActionBar = { text = "SHOW_MULTIBAR4_TEXT", default = "0" },
	lockActionBars = { text = "LOCK_ACTIONBAR_TEXT" },
	alwaysShowActionBars = { text = "ALWAYS_SHOW_MULTIBARS_TEXT" },
	secureAbilityToggle = { text = "SECURE_ABILITY_TOGGLE" },
}

function InterfaceOptions_UpdateMultiActionBars ()
	if ( SHOW_MULTI_ACTIONBAR_1 == "0" ) then
		SHOW_MULTI_ACTIONBAR_1 = nil;
	end

	if ( SHOW_MULTI_ACTIONBAR_2 == "0" ) then
		SHOW_MULTI_ACTIONBAR_2 = nil;
	end

	if ( SHOW_MULTI_ACTIONBAR_3 == "0" ) then
		SHOW_MULTI_ACTIONBAR_3 = nil;
	end

	if ( SHOW_MULTI_ACTIONBAR_4 == "0" ) then
		SHOW_MULTI_ACTIONBAR_4 = nil;
	end

	if ( ALWAYS_SHOW_MULTIBARS == "0" ) then
		ALWAYS_SHOW_MULTIBARS = nil;
	end

	if ( LOCK_ACTIONBAR == "0" ) then
		LOCK_ACTIONBAR = nil;
	end

	SetActionBarToggles(SHOW_MULTI_ACTIONBAR_1, SHOW_MULTI_ACTIONBAR_2, SHOW_MULTI_ACTIONBAR_3, SHOW_MULTI_ACTIONBAR_4, ALWAYS_SHOW_MULTIBARS);
	MultiActionBar_Update();
	UIParent_ManageFramePositions();
end

-- [[ Names Options Panel ]] --

NamePanelOptions = {
	UnitNameOwn = { text = "UNIT_NAME_OWN" },
	UnitNameNPC = { text = "UNIT_NAME_NPC" },
	UnitNameNonCombatCreatureName = { text = "UNIT_NAME_NONCOMBAT_CREATURE" },
	UnitNamePlayerGuild = { text = "UNIT_NAME_GUILD" },
	UnitNamePlayerPVPTitle = { text = "UNIT_NAME_PLAYER_TITLE" },
	
	UnitNameFriendlyPlayerName = { text = "UNIT_NAME_FRIENDLY" },
	UnitNameFriendlyPetName = { text = "UNIT_NAME_FRIENDLY_PETS" },
	UnitNameFriendlyGuardianName = { text = "UNIT_NAME_FRIENDLY_GUARDIANS" },
	UnitNameFriendlyTotemName = { text = "UNIT_NAME_FRIENDLY_TOTEMS" },
	
	UnitNameEnemyPlayerName = { text = "UNIT_NAME_ENEMY" },
	UnitNameEnemyPetName = { text = "UNIT_NAME_ENEMY_PETS" },
	UnitNameEnemyGuardianName = { text = "UNIT_NAME_ENEMY_GUARDIANS" },
	UnitNameEnemyTotemName = { text = "UNIT_NAME_ENEMY_TOTEMS" },
}

-- [[ NamePlate Options Panel ]] --

NamePlatePanelOptions = {
	ShowClassColorInNameplate = { text = "SHOW_CLASS_COLOR_IN_V_KEY" },
	highPrecisionNameplates = { text = "UNIT_NAMEPLATES_HIGH_PRECISION" },
	nameplateShowFriends = { text = "UNIT_NAMEPLATES_SHOW_FRIENDS" },
	nameplateShowFriendlyPets = { text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_PETS" },
	nameplateShowFriendlyGuardians = { text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_GUARDIANS" },
	nameplateShowFriendlyTotems = { text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_TOTEMS" },
	nameplateShowEnemies = { text = "UNIT_NAMEPLATES_SHOW_ENEMIES" },
	nameplateShowEnemyPets = { text = "UNIT_NAMEPLATES_SHOW_ENEMY_PETS" },
	nameplateShowEnemyGuardians = { text = "UNIT_NAMEPLATES_SHOW_ENEMY_GUARDIANS" },
	nameplateShowEnemyTotems = { text = "UNIT_NAMEPLATES_SHOW_ENEMY_TOTEMS" },
	nameplateSmoothStacking = { text = "UNIT_NAMEPLATES_SMOOTH_STACKING" },
	nameplateFriendlySmoothStacking = { text = "UNIT_NAMEPLATES_FRIENDLY_SMOOTH_STACKING" },
	nameplateOverlapV = { text = "UNIT_NAMEPLATES_OVERLAP_V", minValue = 0.5, maxValue = 2, valueStep = 0.1 },
	nameplateIntersectOpacity = { text = "NAMEPLATE_INTERSECT_OPACITY", minValue = 0, maxValue = 1, valueStep = 0.05 },
	nameplateIntersectUseCamera = { text = "NAMEPLATE_INTERSECT_USE_CAMERA" },
	nameplateDistance = { text = "NAMEPLATE_DISTANCE", minValue = 5, maxValue = 60, valueStep = 1 },
	nameplateVerticalOffset = { text = "NAMEPLATE_Z", minValue = 0.2, maxValue = 5, valueStep = 0.01 },
	nameplateFixedVerticalOffset = { text = "NAMEPLATE_FIXED_VERTICAL_OFFSET" },
	useNewNameplates = { text = "USE_CLASSIC_NAMEPLATES" },
	nameplateShowPersonal = { text = "UNIT_NAMEPLATES_SHOW_PERSONAL" },
}

-- [[ Combat Text Options Panel ]] --

FCTPanelOptions = {
	enableCombatText = { text = "SHOW_COMBAT_TEXT_TEXT" },
	fctCombatState = { text = "COMBAT_TEXT_SHOW_COMBAT_STATE_TEXT" },
	fctDodgeParryMiss = { text = "COMBAT_TEXT_SHOW_DODGE_PARRY_MISS_TEXT" },
	fctDamageReduction = { text = "COMBAT_TEXT_SHOW_RESISTANCES_TEXT" },
	fctRepChanges = { text = "COMBAT_TEXT_SHOW_REPUTATION_TEXT" },
	fctReactives = { text = "COMBAT_TEXT_SHOW_REACTIVES_TEXT" },
	fctFriendlyHealers = { text = "COMBAT_TEXT_SHOW_FRIENDLY_NAMES_TEXT" },
	fctComboPoints = { text = "COMBAT_TEXT_SHOW_COMBO_POINTS_TEXT" },
	fctLowManaHealth = { text = "COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT" },
	fctEnergyGains = { text = "COMBAT_TEXT_SHOW_ENERGIZE_TEXT" },
	fctPeriodicEnergyGains = { text = "COMBAT_TEXT_SHOW_PERIODIC_ENERGIZE_TEXT" },
	fctHonorGains = { text = "COMBAT_TEXT_SHOW_HONOR_GAINED_TEXT" },
	fctAuras = { text = "COMBAT_TEXT_SHOW_AURAS_TEXT" },
	CombatDamage = { text = "SHOW_DAMAGE_TEXT" },
	CombatLogPeriodicSpells = { text = "LOG_PERIODIC_EFFECTS" },
	PetMeleeDamage = { text = "SHOW_PET_MELEE_DAMAGE" },
	CombatHealing = { text = "SHOW_COMBAT_HEALING" },
	fctSpellMechanics = { text = "SHOW_TARGET_EFFECTS" },
	fctSpellMechanicsOther = { text = "SHOW_OTHER_TARGET_EFFECTS" },
}

function BlizzardOptionsPanel_UpdateCombatText ()
	-- Fix for bug 106938. CombatText_UpdateDisplayedMessages only exists if the Blizzard_CombatText AddOn is loaded.
	-- We need CombatText options to have their setFunc actually _exist_, so this function is used instead of CombatText_UpdateDisplayedMessages.
	if ( CombatText_UpdateDisplayedMessages ) then
		CombatText_UpdateDisplayedMessages();
	end
end

function InterfaceOptionsCombatTextPanel_OnLoad (self)
	self.name = COMBATTEXT_LABEL;
	self.options = FCTPanelOptions;
	InterfaceOptionsPanel_OnLoad(self);

	self:SetScript("OnEvent", InterfaceOptionsCombatTextPanel_OnEvent);
end

function InterfaceOptionsCombatTextPanel_OnEvent (self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		local control;

		-- run the enable FCT button's set func to refresh floating combat text and make sure the addon is loaded
		control = InterfaceOptionsCombatTextPanelEnableFCT;
		control.setFunc(GetCVar(control.cvar));

		-- fix for bug 106687: self button can no longer be enabled if you're not a rogue or a druid
		control = InterfaceOptionsCombatTextPanelComboPoints;
		control.SetChecked =
			function (self, checked)
				local _, class = UnitClass("player");
				if ( class ~= "ROGUE" and class ~= "DRUID" and class ~= "HERO" ) then
					checked = false;
				end
				getmetatable(self).__index.SetChecked(self, checked);
			end
		control.Enable =
			function (self)
				local _, class = UnitClass("player");
				if ( class ~= "ROGUE" and class ~= "DRUID" and class ~= "HERO" ) then
					return;
				end
				getmetatable(self).__index.Enable(self);
				local text = _G[self:GetName().."Text"];
				local fontObject = text:GetFontObject();
				_G[self:GetName().."Text"]:SetTextColor(fontObject:GetTextColor());
			end
		control.setFunc(GetCVar(control.cvar));
	end
end

function InterfaceOptionsCombatTextPanelFCTDropDown_OnLoad(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.oldValue = value;
	self.value = value;
	self.tooltip = OPTION_TOOLTIP_COMBAT_TEXT_MODE;

	UIDropDownMenu_SetWidth(self, 110);
	UIDropDownMenu_Initialize(self, InterfaceOptionsCombatTextPanelFCTDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	COMBAT_TEXT_FLOAT_MODE = value;
	if ( CombatText_UpdateDisplayedMessages ) then
		-- If the CombatText AddOn has already been loaded, we need to reinit it to pick up the previous COMBAT_TEXT_FLOAT_MODE.
		CombatText_UpdateDisplayedMessages();
	end

	self.SetValue = 
		function (self, value) 
			self.value = value;
			SetCVar(self.cvar, value, self.event);
			UIDropDownMenu_SetSelectedValue(self, value);

			COMBAT_TEXT_FLOAT_MODE = value;
			if ( CombatText_UpdateDisplayedMessages ) then
				CombatText_UpdateDisplayedMessages();
			else
				UIParentLoadAddOn("Blizzard_CombatText");
				CombatText_UpdateDisplayedMessages();
			end
		end;	
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsCombatTextPanelFCTDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsCombatTextPanelFCTDropDown_OnShow(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.oldValue = value;
	self.value = value;
	self.tooltip = OPTION_TOOLTIP_COMBAT_TEXT_MODE;
	UIDropDownMenu_SetSelectedValue(self, value);
end

function InterfaceOptionsCombatTextPanelFCTDropDown_OnClick(self)
	InterfaceOptionsCombatTextPanelFCTDropDown:SetValue(self.value);
end

function InterfaceOptionsCombatTextPanelFCTDropDown_Initialize(self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();

	info.text = COMBAT_TEXT_SCROLL_UP;
	info.func = InterfaceOptionsCombatTextPanelFCTDropDown_OnClick;
	info.value = "1";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = COMBAT_TEXT_SCROLL_UP;
	info.tooltipText = OPTION_TOOLTIP_SCROLL_UP;
	UIDropDownMenu_AddButton(info);

	info.text = COMBAT_TEXT_SCROLL_DOWN;
	info.func = InterfaceOptionsCombatTextPanelFCTDropDown_OnClick;
	info.value = "2";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = COMBAT_TEXT_SCROLL_DOWN;
	info.tooltipText = OPTION_TOOLTIP_SCROLL_DOWN;
	UIDropDownMenu_AddButton(info);

	info.text = COMBAT_TEXT_SCROLL_ARC;
	info.func = InterfaceOptionsCombatTextPanelFCTDropDown_OnClick;
	info.value = "3";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = COMBAT_TEXT_SCROLL_ARC;
	info.tooltipText = OPTION_TOOLTIP_SCROLL_ARC;
	UIDropDownMenu_AddButton(info);
end

-- [[ Status Text Options Panel ]] --

StatusTextPanelOptions = {
	xpBarText = { text = "XP_BAR_TEXT" },
	playerStatusText = { text = "STATUS_TEXT_PLAYER" },
	petStatusText = { text = "STATUS_TEXT_PET" },
	partyStatusText = { text = "STATUS_TEXT_PARTY" },
	targetStatusText = { text = "STATUS_TEXT_TARGET" },
	statusTextPercentage = { text = "STATUS_TEXT_PERCENT" },
}

-- [[ UnitFrame Options Panel ]] --

UnitFramePanelOptions = {
	showPartyBackground = { text = "SHOW_PARTY_BACKGROUND_TEXT" },
	hidePartyInRaid = { text = "HIDE_PARTY_INTERFACE_TEXT" },
	showPartyPets = { text = "SHOW_PARTY_PETS_TEXT" },
	showRaidRange = { text = "SHOW_RAID_RANGE_TEXT" },
	showArenaEnemyFrames = { text = "SHOW_ARENA_ENEMY_FRAMES_TEXT" },
	showArenaEnemyCastbar = { text = "SHOW_ARENA_ENEMY_CASTBAR_TEXT" },
	showArenaEnemyPets = { text = "SHOW_ARENA_ENEMY_PETS_TEXT" },
	fullSizeFocusFrame = { text = "FULL_SIZE_FOCUS_FRAME_TEXT" },
}

function BlizzardOptionsPanel_UpdateRaidPullouts ()
	if ( type(NUM_RAID_PULLOUT_FRAMES) ~= "number" ) then
		return;
	end

	local frame;
	for i = 1, NUM_RAID_PULLOUT_FRAMES do
		frame = _G["RaidPullout" .. i];
		if ( frame and frame:IsShown() ) then
			RaidPullout_Update(frame);
		end
	end
end

-- [[ Camera Options Panel ]] --

CameraPanelOptions = {
	cameraTerrainTilt = { text = "FOLLOW_TERRAIN" },
	cameraBobbing = { text = "HEAD_BOB" },
	cameraWaterCollision = { text = "WATER_COLLISION" },
	cameraPivot = { text = "SMART_PIVOT" },
	cameraM2Collision = { text = "M2_COLLISION" },
	cameraYawSmoothSpeed = { text = "AUTO_FOLLOW_SPEED", minValue = 90, maxValue = 270, valueStep = 10 },
	cameraDistanceMaxFactor = { text = "MAX_FOLLOW_DIST", minValue = 1, maxValue = 4, valueStep = 0.1 },
	camerafov = { text = "CAMERA_FOV", minValue = GetCVarMin("camerafov"), maxValue = GetCVarMax("camerafov"), valueStep = 0.01 },
}

function InterfaceOptionsCameraPanel_OnLoad (self)
	self.name = CAMERA_LABEL;
	self.options = CameraPanelOptions;
	InterfaceOptionsPanel_OnLoad(self)

	self:SetScript("OnEvent", InterfaceOptionsCameraPanel_OnEvent);
end

function InterfaceOptionsCameraPanel_OnEvent (self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( GetCVar("cameraSmoothStyle") == "0" ) then
			BlizzardOptionsPanel_Slider_Disable(InterfaceOptionsCameraPanelFollowSpeedSlider);
			InterfaceOptionsCameraPanelFollowTerrain:Disable();
		end
	end
end

function InterfaceOptionsCameraPanelStyleDropDown_OnLoad(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	if ( value == "0" ) then
		--For the purposes of tooltips and the dropdown list, value "0" in the CVar cameraSmoothStyle is actually "3".
		self.tooltip = OPTION_TOOLTIP_CAMERA3;
	else
		self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
	end	

	UIDropDownMenu_SetWidth(self, 180);
	UIDropDownMenu_Initialize(self, InterfaceOptionsCameraPanelStyleDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			SetCVar(self.cvar, value, self.event);
			UIDropDownMenu_SetSelectedValue(self, value);
			if ( value == "0" ) then
				--For the purposes of tooltips and the dropdown list, value "0" in the CVar cameraSmoothStyle is actually "3".
				self.tooltip = OPTION_TOOLTIP_CAMERA3;
				local yawSpeed = Options.GetControlForCVar("cameraYawSmoothSpeed")
				local followTerrain = Options.GetControlForCVar("cameraTerrainTilt")
				if yawSpeed and followTerrain then
					BlizzardOptionsPanel_Slider_Disable(yawSpeed);
					followTerrain:Disable();
				end
			else
				self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
				local yawSpeed = Options.GetControlForCVar("cameraYawSmoothSpeed")
				local followTerrain = Options.GetControlForCVar("cameraTerrainTilt")
				if yawSpeed and followTerrain then
					BlizzardOptionsPanel_Slider_Enable(yawSpeed);
					followTerrain:Enable();
				end
			end	
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsCameraPanelStyleDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsCameraPanelStyleDropDown_OnShow(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	if ( value == "0" ) then
		--For the purposes of tooltips and the dropdown list, value "0" in the CVar cameraSmoothStyle is actually "3".
		self.tooltip = OPTION_TOOLTIP_CAMERA3;
		local yawSpeed = Options.GetControlForCVar("cameraYawSmoothSpeed")
		local followTerrain = Options.GetControlForCVar("cameraTerrainTilt")
		if yawSpeed and followTerrain then
			BlizzardOptionsPanel_Slider_Disable(yawSpeed);
			followTerrain:Disable();
		end
	else
		self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
		local yawSpeed = Options.GetControlForCVar("cameraYawSmoothSpeed")
		local followTerrain = Options.GetControlForCVar("cameraTerrainTilt")
		if yawSpeed and followTerrain then
			BlizzardOptionsPanel_Slider_Enable(yawSpeed);
			followTerrain:Enable();
		end
	end	
end


function InterfaceOptionsCameraPanelStyleDropDown_OnEvent(self, event, ...)
end

function InterfaceOptionsCameraPanelStyleDropDown_OnClick(self)
	InterfaceOptionsCameraPanelStyleDropDown:SetValue(self.value);
end

function InterfaceOptionsCameraPanelStyleDropDown_Initialize(self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();
	info.tooltipOnButton = 1;

	info.text = CAMERA_SMART;
	info.func = InterfaceOptionsCameraPanelStyleDropDown_OnClick;
	info.value = "1";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_SMART;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMART;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_SMARTER;
	info.func = InterfaceOptionsCameraPanelStyleDropDown_OnClick;
	info.value = "4";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_SMARTER;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMARTER;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_ALWAYS;
	info.func = InterfaceOptionsCameraPanelStyleDropDown_OnClick;
	info.value = "2";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_ALWAYS;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_NEVER;
	info.func = InterfaceOptionsCameraPanelStyleDropDown_OnClick;
	info.value = "0";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_NEVER;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_NEVER;
	UIDropDownMenu_AddButton(info);
end

-- [[ Buffs Options Panel ]] --

BuffsPanelOptions = {
	buffDurations = { text = "SHOW_BUFF_DURATION_TEXT" },
	showDispelDebuffs = { text = "SHOW_DISPELLABLE_DEBUFFS_TEXT" },
	showCastableBuffs = { text = "SHOW_CASTABLE_BUFFS_TEXT" },	
	consolidateBuffs = { text = "CONSOLIDATE_BUFFS_TEXT" },	
	showCastableDebuffs = { text = "SHOW_CASTABLE_DEBUFFS_TEXT" },
}

function InterfaceOptionsBuffsPanel_OnLoad (self)
	self.name = BUFFOPTIONS_LABEL;
	self.options = BuffsPanelOptions;
	InterfaceOptionsPanel_OnLoad(self);

	self:SetScript("OnEvent", InterfaceOptionsBuffsPanel_OnEvent);
end

function InterfaceOptionsBuffsPanel_OnEvent (self, event, ...)
	BlizzardOptionsPanel_OnEvent(self, event, ...);

	if ( event == "PLAYER_ENTERING_WORLD" ) then
		local control;
		control = InterfaceOptionsBuffsPanelBuffDurations;
		control.setFunc(GetCVar(control.cvar));
	end
end

-- [[ Battle.net Options Panel ]] --

BattlenetPanelOptions = {
	showToastOnline = { text = "SHOW_TOAST_ONLINE_TEXT" },
	showToastOffline = { text = "SHOW_TOAST_OFFLINE_TEXT" },
	showToastBroadcast = { text = "SHOW_TOAST_BROADCAST_TEXT" },
	showToastFriendRequest = { text = "SHOW_TOAST_FRIEND_REQUEST_TEXT" },
	showToastConversation = { text = "SHOW_TOAST_CONVERSATION_TEXT" },
	showToastWindow = { text = "SHOW_TOAST_WINDOW_TEXT" },
	toastDuration = { text = "TOAST_DURATION_TEXT", minValue = 0, maxValue = 10, valueStep = 0.5 },
}

function InterfaceOptionsBattlenetPanel_OnLoad (self)
	if ( BNFeaturesEnabled() ) then
		self.name = BATTLENET_OPTIONS_LABEL;
		self.options = BattlenetPanelOptions;
		InterfaceOptionsPanel_OnLoad(self);
	end
end

-- [[ Mouse Options Panel ]] --

MousePanelOptions = {
	mouseInvertPitch = { text = "INVERT_MOUSE" },
	enableWoWMouse = { text = "WOW_MOUSE" },
	autointeract = { text = "CLICK_TO_MOVE" },
	mouseSpeed = { text = "MOUSE_SENSITIVITY", minValue = 0.5, maxValue = 1.5, valueStep = 0.05 },
	cameraYawMoveSpeed = { text = "MOUSE_LOOK_SPEED", minValue = 90, maxValue = 270, valueStep = 10 },
}

function InterfaceOptionsMousePanelClickMoveStyleDropDown_OnLoad(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.oldValue = value;
	self.value = value;
	if ( value == "0" ) then
		--For the purposes of tooltips and dropdown lists, "0" in the CVar cameraSmoothTrackingStyle is "3".
		self.tooltip = OPTION_TOOLTIP_CAMERA3;
	else
		self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
	end

	UIDropDownMenu_SetWidth(self, 180);
	UIDropDownMenu_Initialize(self, InterfaceOptionsMousePanelClickMoveStyleDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			self.value = value;
			SetCVar(self.cvar, value, self.event);
			UIDropDownMenu_SetSelectedValue(self, value);
			if ( value == "0" ) then
				--For the purposes of tooltips and dropdown lists, "0" in the CVar cameraSmoothTrackingStyle is "3".
				self.tooltip = OPTION_TOOLTIP_CAMERA3;
			else
				self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
			end
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsMousePanelClickMoveStyleDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsMousePanelClickMoveStyleDropDown_OnShow(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	if ( value == "0" ) then
		--For the purposes of tooltips and dropdown lists, "0" in the CVar cameraSmoothTrackingStyle is "3".
		self.tooltip = OPTION_TOOLTIP_CAMERA3;
	else
		self.tooltip = _G["OPTION_TOOLTIP_CAMERA"..value];
	end
end	

function InterfaceOptionsMousePanelClickMoveStyleDropDown_OnEvent(self, event, ...)
end

function InterfaceOptionsMousePanelClickMoveStyleDropDown_OnClick(self)
	InterfaceOptionsMousePanelClickMoveStyleDropDown:SetValue(self.value);
end

function InterfaceOptionsMousePanelClickMoveStyleDropDown_Initialize(self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();

	info.text = CAMERA_SMART;
	info.func = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnClick;
	info.value = "1";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_SMART;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMART;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_SMARTER;
	info.func = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnClick;
	info.value = "4";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_SMARTER;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_SMARTER;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_ALWAYS;
	info.func = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnClick;
	info.value = "2";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_ALWAYS;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_ALWAYS;
	UIDropDownMenu_AddButton(info);

	info.text = CAMERA_NEVER;
	info.func = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnClick;
	info.value = "0";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CAMERA_NEVER;
	info.tooltipText = OPTION_TOOLTIP_CAMERA_NEVER;
	UIDropDownMenu_AddButton(info);
end

-- [[ Features Panel ]] --

FeaturesPanelOptions = {
	equipmentManager = { text = "USE_EQUIPMENT_MANAGER" },
	previewTalents = { text = "PREVIEW_TALENT_CHANGES" },
}

-- [[ Help Options Panel ]] --

HelpPanelOptions = {
	showGameTips = { text = "SHOW_TIPOFTHEDAY_TEXT" },
	UberTooltips = { text = "USE_UBERTOOLTIPS" },
	showNewbieTips = { text = "SHOW_NEWBIE_TIPS_TEXT" },
	scriptErrors = { text = "SHOW_LUA_ERRORS" },
	extendedTooltips = { text = "SHOW_EXTENDED_TOOLTIPS" },
}

-- [[ Languages Options Panel ]] --

LanguagesPanelOptions = {
	useEnglishAudio = { text = "USE_ENGLISH_AUDIO" },
}

-- [[ Ascension Help ]] --

AscensionHelpPanelOptions = {
	npeEnabled = { text = "SHOW_NEW_PLAYER_EXPERIENCE" },
	HelpTipEnabled = { text = "SHOW_HELP_TIPS" },
}

-- [[ Draft Options ]] --
DraftPanelOptions = {
	autoPopupDraft = { text = "AUTO_POPUP_DRAFT"},
	autoRevealDraft = { text = "AUTO_REVEAL_DRAFT"},
	skipDraftConfirmation = { text = "SKIP_DRAFT_CONFIRMATION"},
	skipDraftSacrificeConfirmation = { text = "SKIP_DRAFT_SACRIFICE_CONFIRMATION"},
	buildDraftShowSpellCards = { text = "SHOW_BUILD_DRAFT_SPELLS"},
}

-- [[ Draft Options ]] --
ActionCamPanelOptions = {
	ActionCam = { text = "ENABLE_ACTION_CAM"},
	cameraActionAngle = { text = "ACTION_CAM_ANGLE", minValue = 0, maxValue = 6, valueStep = 0.0025 },
	cameraActionDist = {  text = "ACTION_CAM_DISTANCE", minValue = 0.25, maxValue = 2, valueStep = 0.0025 },
	cameraActionZ = { text = "ACTION_CAM_HEIGHT", minValue = -1.25, maxValue = 0.75, valueStep = 0.0025 },
	cameraActionMaxPitch = { text = "ACTION_CAM_MAX_PITCH", minValue = 0, maxValue = 1.55, valueStep = 0.0025 },
	cameraActionMinPitch = { text = "ACTION_CAM_MIN_PITCH", minValue = -1.55, maxValue = 0, valueStep = 0.0025 },
	cameraTargetFocusTurnSpeed = { text = "ACTION_CAM_TURN_SPEED", minValue = 0.5, maxValue = 16.5, valueStep = 0.0025 },
	cameraActionHeadBobs = { text = "ACTION_CAM_HEAD_BOB" },
	cameraTargetFocusInteractEnable = { text = "ACTION_CAM_FOCUS_INTERACT" },
	cameraTargetFocusEnemyEnable = { text = "ACTION_CAM_FOCUS_TARGET" },
}

-- [[ Mouseover Casting Options ]] --
MouseoverCastPanelOptions = {
	enableMouseoverCast = { text = "MOUSEOVER_CAST" },
	enableMouseoverCastHarm = { text = "MOUSEOVER_CAST_HARM" },
}

function InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnLoad(self)
	self.defaultValue = "NONE";
	self.oldValue = GetModifiedClick("MOUSEOVERCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_MOUSEOVER_CAST_"..self.value.."_KEY"];

	UIDropDownMenu_SetWidth(self, 90);
	UIDropDownMenu_Initialize(self, InterfaceOptionsMouseoverCastPanelHotkeyDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);

	self.SetValue =
	function (self, value)
		self.value = value;
		UIDropDownMenu_SetSelectedValue(self, value);
		SetModifiedClick("MOUSEOVERCAST", value);
		SaveBindings(GetCurrentBindingSet());
		self.tooltip = _G["OPTION_TOOLTIP_MOUSEOVER_CAST_"..value.."_KEY"];
	end
	self.GetValue =
	function (self)
		return UIDropDownMenu_GetSelectedValue(self);
	end
	self.RefreshValue =
	function (self)
		UIDropDownMenu_Initialize(self, InterfaceOptionsMouseoverCastPanelHotkeyDropDown_Initialize);
		UIDropDownMenu_SetSelectedValue(self, self.value);
	end
end

function InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnShow(self)
	self.oldValue = GetModifiedClick("MOUSEOVERCAST");
	self.value = self.oldValue or self.defaultValue;
	self.tooltip = _G["OPTION_TOOLTIP_MOUSEOVER_CAST_"..self.value.."_KEY"];
	UIDropDownMenu_SetSelectedValue(self, self.value);
end


function InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnEvent (self, event, ...)
end



function InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnClick(self)
	InterfaceOptionsMouseoverCastPanelHotkeyDropDown:SetValue(self.value);
end

function InterfaceOptionsMouseoverCastPanelHotkeyDropDown_Initialize()
	local selectedValue = UIDropDownMenu_GetSelectedValue(InterfaceOptionsMouseoverCastPanelHotkeyDropDown);
	local info = UIDropDownMenu_CreateInfo();

	info.text = ALT_KEY;
	info.func = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnClick;
	info.value = "ALT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = ALT_KEY;
	info.tooltipText = OPTION_TOOLTIP_MOUSEOVER_CAST_ALT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = CTRL_KEY;
	info.func = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnClick;
	info.value = "CTRL";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = CTRL_KEY;
	info.tooltipText = OPTION_TOOLTIP_MOUSEOVER_CAST_CTRL_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = SHIFT_KEY;
	info.func = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnClick;
	info.value = "SHIFT";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = SHIFT_KEY;
	info.tooltipText = OPTION_TOOLTIP_MOUSEOVER_CAST_SHIFT_KEY;
	UIDropDownMenu_AddButton(info);

	info.text = NONE_KEY;
	info.func = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnClick;
	info.value = "NONE";
	if ( info.value == selectedValue ) then
		info.checked = 1;
	else
		info.checked = nil;
	end
	info.tooltipTitle = NONE_KEY;
	info.tooltipText = OPTION_TOOLTIP_MOUSEOVER_CAST_NONE_KEY;
	UIDropDownMenu_AddButton(info);
end

-- [[ Ascension Notifications ]] --
AscensionNotificationPanelOptions = {
	showLootToasts = { text = "SHOW_LOOT_TOAST" },
	lootToastMaximum = { text = "LOOT_TOAST_MAX", minValue = 1, maxValue = 6, valueStep = 1 },
	flashWindow = { text = "FLASH_WINDOW" },
}

-- [[ Ascension Lose Control ]] --
AscensionLoseControlPanelOptions = {
	showLossOfControl = { text = "SHOW_LOSE_CONTROL", event = "showLossOfControl" },
}

function InterfaceOptionsLanguagesPanel_OnLoad (panel)
	-- Check and see if we have more than one locale. If we don't, then don't register this panel.
	if ( #({GetExistingLocales()}) <= 1 ) then
		return;
	end

	InterfaceOptionsPanel_OnLoad(panel);
end

function InterfaceOptionsLanguagesPanelLocaleDropDown_OnLoad(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.oldValue = value;
	self.value = value;
	self.tooltip = OPTION_TOOLTIP_LOCALE;

	UIDropDownMenu_SetWidth(self, 120);
	UIDropDownMenu_Initialize(self, InterfaceOptionsLanguagesPanelLocaleDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue = 
		function (self, value)
			UIDropDownMenu_SetSelectedValue(self, value);
			SetCVar("locale", value, self.event);
			self.value = value;
			if ( self.oldValue ~= value ) then
				InterfaceOptionsFrame.gameRestart = true;
			end
		end
	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end
	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsLanguagesPanelLocaleDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsLanguagesPanelLocaleDropDown_OnShow(self)
	local value = GetCVar(self.cvar);
	self.defaultValue = GetCVarDefault(self.cvar);
	self.value = value;
	self.oldValue = value;
	self.tooltip = OPTION_TOOLTIP_LOCALE;
end


function InterfaceOptionsLanguagesPanelLocaleDropDown_OnEvent (self, event, ...)
end

function InterfaceOptionsLanguagesPanelLocaleDropDown_OnClick (self)
	InterfaceOptionsLanguagesPanelLocaleDropDown:SetValue(self.value);
end

function InterfaceOptionsLanguagesPanelLocaleDropDown_Initialize (self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self);
	local info = UIDropDownMenu_CreateInfo();

	InterfaceOptionsLanguagesPanelLocaleDropDown_InitializeHelper(info, selectedValue, GetExistingLocales());
end

function InterfaceOptionsLanguagesPanelLocaleDropDown_InitializeHelper (createInfo, selectedValue, ...)
	for i = 1, select("#", ...) do
		local value = select(i, ...);
		if (value) then
			createInfo.text = _G[strupper(value)];
			createInfo.func = InterfaceOptionsLanguagesPanelLocaleDropDown_OnClick;
			createInfo.value = value;
			if ( createInfo.value == selectedValue ) then
				createInfo.checked = 1;
			else
				createInfo.checked = nil;
			end
			UIDropDownMenu_AddButton(createInfo);
		end
	end
end

function InterfaceOptionsNPCNamesDropDown_OnLoad(self)
	InterfaceOptionsNPCNamesDropDown_OnShow(self)
	
	UIDropDownMenu_SetWidth(self, 180);
	UIDropDownMenu_Initialize(self, InterfaceOptionsCameraPanelStyleDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, self.value);

	self.SetValue =
		function (self, value)
			self.value = value;
			UIDropDownMenu_SetSelectedValue(self, value);
			local interactive = false
			local quest = false
			local hostile = false
			local all = false
			if value == 4 then
				all = true
			elseif value == 3 then
				interactive = true
				quest = true
				hostile = true
			elseif value == 2 then
				quest = true
				hostile = true
			elseif value == 1 then
				quest = true
			end
			C_CVar.Set("UnitNameInteractiveNPC", interactive);
			C_CVar.Set("UnitNameQuestNPC", quest);
			C_CVar.Set("UnitNameHostileNPC", hostile);
			C_CVar.Set("UnitNameAllNPC", all);
		end

	self.GetValue =
		function (self)
			return UIDropDownMenu_GetSelectedValue(self);
		end

	self.RefreshValue =
		function (self)
			UIDropDownMenu_Initialize(self, InterfaceOptionsNPCNamesDropDown_Initialize);
			UIDropDownMenu_SetSelectedValue(self, self.value);
		end
end

function InterfaceOptionsNPCNamesDropDown_OnShow(self)
	local interactive = C_CVar.GetBool("UnitNameInteractiveNPC")
	local quest = C_CVar.GetBool("UnitNameQuestNPC")
	local hostile = C_CVar.GetBool("UnitNameHostileNPC")
	local all = C_CVar.GetBool("UnitNameAllNPC")
	local value = 0
	if all then
		value = 4
	elseif interactive and quest and hostile then
		value = 3
	elseif quest and hostile then
		value = 2
	elseif quest then
		value = 1
	end

	local defaultInteractive = C_CVar.GetDefaultBool("UnitNameInteractiveNPC")
	local defaultQuest = C_CVar.GetDefaultBool("UnitNameQuestNPC")
	local defaultHostile = C_CVar.GetDefaultBool("UnitNameHostileNPC")
	local defaultAll = C_CVar.GetDefaultBool("UnitNameAllNPC")
	local defaultValue = 0
	if defaultAll then
		defaultValue = 4
	elseif defaultInteractive and defaultQuest and defaultHostile then
		defaultValue = 3
	elseif defaultQuest and defaultHostile then
		defaultValue = 2
	elseif defaultQuest then
		defaultValue = 1
	end

	self.value = value
	self.defaultValue = defaultValue
	self.oldValue = value;
	self.tooltipTitle = UNIT_NAME_NPC
	self.tooltipText = _G["OPTION_TOOLTIP_NPCNAMES"]
end

function InterfaceOptionsNPCNamesDropDown_OnClick(self)
	InterfaceOptionsNamesPanelNPCNamesDropDown:SetValue(self.value);
end

function InterfaceOptionsNPCNamesDropDown_Initialize(self)
	local selectedValue = UIDropDownMenu_GetSelectedValue(self)
	local info = UIDropDownMenu_CreateInfo()
	info.tooltipOnButton = 1
	
	info.text = NPCNAMES_QUESTNPCS
	info.func = InterfaceOptionsNPCNamesDropDown_OnClick
	info.value = 1
	info.checked = info.value == selectedValue
	info.tooltipTitle = NPCNAMES_QUESTNPCS
	info.tooltipText = OPTION_TOOLTIP_NPCNAMES_QUESTNPCS
	UIDropDownMenu_AddButton(info)

	info.text = NPCNAMES_HOSTILE_AND_QUEST
	info.func = InterfaceOptionsNPCNamesDropDown_OnClick
	info.value = 2
	info.checked = info.value == selectedValue
	info.tooltipTitle = NPCNAMES_HOSTILE_AND_QUEST
	info.tooltipText = OPTION_TOOLTIP_NPCNAMES_HOSTILE_AND_QUEST
	UIDropDownMenu_AddButton(info)

	info.text = NPCNAMES_HOSTILE_AND_QUEST_AND_INTERACTIVE
	info.func = InterfaceOptionsNPCNamesDropDown_OnClick
	info.value = 3
	info.checked = info.value == selectedValue
	info.tooltipTitle = NPCNAMES_HOSTILE_AND_QUEST_AND_INTERACTIVE
	info.tooltipText = OPTION_TOOLTIP_NPCNAMES_HOSTILE_AND_QUEST_AND_INTERACTIVE
	UIDropDownMenu_AddButton(info)

	info.text = NPCNAMES_ALL
	info.func = InterfaceOptionsNPCNamesDropDown_OnClick
	info.value = 4
	info.checked = info.value == selectedValue
	info.tooltipTitle = NPCNAMES_ALL
	info.tooltipText = OPTION_TOOLTIP_NPCNAMES_ALL
	UIDropDownMenu_AddButton(info)

	info.text = NPCNAMES_NONE
	info.func = InterfaceOptionsNPCNamesDropDown_OnClick
	info.value = 0
	info.checked = info.value == selectedValue
	info.tooltipTitle = NPCNAMES_NONE
	info.tooltipText = OPTION_TOOLTIP_NPCNAMES_NONE
	UIDropDownMenu_AddButton(info)
end
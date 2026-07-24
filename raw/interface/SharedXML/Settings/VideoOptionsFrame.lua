-- if you change something here you probably want to change the glue version too

function VideoOptionsFrame_Toggle ()
	if ( VideoOptionsFrame:IsShown() ) then
		VideoOptionsFrame:Hide();
	else
		VideoOptionsFrame:Show();
	end
end

function VideoOptionsFrame_SetAllToDefaults ()
	OptionsFrame_SetAllToDefaults(VideoOptionsFrame);
	VideoOptionsFrameApply:Disable();
end

function VideoOptionsFrame_SetCurrentToDefaults ()
	OptionsFrame_SetCurrentToDefaults(VideoOptionsFrame);
	VideoOptionsFrameApply:Disable();
end

function VideoOptionsFrame_OnLoad (self)
	OptionsFrame_OnLoad(self);

	_G[self:GetName().."HeaderText"]:SetText(VIDEOOPTIONS_MENU);
end

function VideoOptionsFrame_OnShow(self)
	self:SetScript("OnShow", OptionsFrame_OnShow)
	OptionsFrame_OnShow(self)
	GraphicsPresets.FixupQualityPresets()
end

function VideoOptionsFrame_OnHide (self)
	OptionsFrame_OnHide(self);

	if ( VideoOptionsFrame.gameRestart ) then
		StaticPopup_Show("CLIENT_RESTART_ALERT");
		VideoOptionsFrame.gameRestart = nil;
	elseif ( VideoOptionsFrame.logout ) then
		StaticPopup_Show("CLIENT_LOGOUT_ALERT");
		VideoOptionsFrame.logout = nil;
	end
end

function VideoOptionsFrameOkay_OnClick (self, button, apply)
	OptionsFrameOkay_OnClick(VideoOptionsFrame, apply);

	if ( VideoOptionsFrame.gxRestart ) then
		VideoOptionsFrame.gxRestart = nil;
		RestartGx();
	end

	if ( not apply ) then
		VideoOptionsFrame_Toggle();
	end
end

function VideoOptionsFrameCancel_OnClick (self, button)
	OptionsFrameCancel_OnClick(VideoOptionsFrame);

	VideoOptionsFrame.gxRestart = nil;

	VideoOptionsFrame.logout = nil;
	VideoOptionsFrame.gameRestart = nil;

	VideoOptionsFrame_Toggle();
end

function VideoOptionsFrameDefault_OnClick (self, button)
	OptionsFrameDefault_OnClick(VideoOptionsFrame);

	StaticPopup_Show("CONFIRM_RESET_VIDEO_SETTINGS");
end

--
-- Video Option Panel Functions
--
function VideoOptionsPanel_Okay (self)
	for ctr, control in next, self.controls do
		if ( control.newValue ) then
			if ( control.value ~= control.newValue ) then
				if ( control.gameRestart ) then
					VideoOptionsFrame.gameRestart = true;
				end
				if ( control.logout ) then
					VideoOptionsFrame.logout = true;
				end
				if ( control.restart ) then
					VideoOptionsFrame.gxRestart = true;
				end
				control:SetValue(control.newValue);
				control.value = control.newValue;
				control.newValue = nil;
			end
		elseif ( control.value ) then
			control:SetValue(control.value);
		end
	end
end

function VideoOptionsPanel_Cancel (self)
	for _, control in next, self.controls do
		if ( control.newValue ) then
			if ( control.value and control.value ~= control.newValue ) then
				if ( control.restart ) then
					VideoOptionsFrame.gxRestart = true;
				end
				-- we need to force-set the value here just in case the control was doing dynamic updating
				control:SetValue(control.value);
				control.newValue = nil;
			end
		elseif ( control.value ) then
			control:SetValue(control.value);
		end
	end
end

function VideoOptionsPanel_Default (self)
	for _, control in next, self.controls do
		if ( control.defaultValue and control.value ~= control.defaultValue ) then
			if ( control.restart ) then
				VideoOptionsFrame.gxRestart = true;
			end
			control:SetValue(control.defaultValue);
			control.newValue = nil;
		end
	end
end

function VideoOptionsPanel_OnLoad (self, okay, cancel, default, refresh)
	okay = okay or VideoOptionsPanel_Okay;
	cancel = cancel or VideoOptionsPanel_Cancel;
	default = default or VideoOptionsPanel_Default;
	refresh = refresh or BlizzardOptionsPanel_Refresh;
	BlizzardOptionsPanel_OnLoad(self, okay, cancel, default, refresh);

	OptionsFrame_AddCategory(VideoOptionsFrame, self);
end

--
-- Screen Resolution Dropdown
--
function VideoOptionsResolutionDropDown_OnLoad(self)
	Options.SetCVarControl("_resolution", self)
	local value = GetCurrentResolution();

	self.value = value;
	self.defaultValue = 2;
	self.restart = true;

	UIDropDownMenu_SetWidth(self, 110);
	UIDropDownMenu_Initialize(self, VideoOptionsResolutionDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, value, 1);

	self.SetValue =
	function (self, value)
		SetScreenResolution(value);
	end;
	self.GetValue =
	function (self)
		return GetCurrentResolution();
	end
	self.RefreshValue =
	function (self)
		local value = GetCurrentResolution();
		UIDropDownMenu_Initialize(self, VideoOptionsResolutionDropDown_Initialize);
		UIDropDownMenu_SetSelectedID(self, value, 1);
		self.value = value;
		self.newValue = value;
	end
end

function VideoOptionsResolutionDropDown_Initialize()
	VideoOptionsResolutionDropDown_LoadResolutions(GetScreenResolutions());
end

function VideoOptionsResolutionDropDown_LoadResolutions(...)
	local info = UIDropDownMenu_CreateInfo();
	local resolution, xIndex, width, height;
	for i=1, select("#", ...) do
		resolution = (select(i, ...));
		xIndex = strfind(resolution, "x");
		width = strsub(resolution, 1, xIndex-1);
		height = strsub(resolution, xIndex+1, strlen(resolution));
		if ( width/height > 4/3 ) then
			resolution = resolution.." "..WIDESCREEN_TAG;
		end
		info.text = resolution;
		info.value = resolution;
		info.func = VideoOptionsResolutionDropDown_OnClick;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function VideoOptionsResolutionDropDown_OnClick(self)
	local value = self:GetID();
	local dropdown = Options.GetControlForCVar("_resolution");
	UIDropDownMenu_SetSelectedID(dropdown, value, 1);
	if ( dropdown.value == value ) then
		dropdown.newValue = nil;
	else
		dropdown.newValue = value;
	end
	VideoOptionsFrameApply:Enable();
end

function VideoOptionsRefreshDropDown_OnLoad(self)
	self.cvar = "gxRefresh";
	Options.SetCVarControl("gxRefresh", self)

	local value = BlizzardOptionsPanel_GetCVarSafe(self.cvar);

	self.defaultValue = BlizzardOptionsPanel_GetCVarDefaultSafe(self.cvar);
	self.value = value;
	self.restart = true;

	UIDropDownMenu_SetWidth(self, 110);
	UIDropDownMenu_Initialize(self, VideoOptionsRefreshDropDown_Initialize);
	UIDropDownMenu_SetSelectedValue(self, value);

	self.SetValue =
	function (self, value)
		BlizzardOptionsPanel_SetCVarSafe(self.cvar, value);
	end;
	self.GetValue =
	function (self)
		return BlizzardOptionsPanel_GetCVarSafe(self.cvar);
	end
	self.RefreshValue =
	function (self)
		local value = BlizzardOptionsPanel_GetCVarSafe(self.cvar);
		UIDropDownMenu_Initialize(self, VideoOptionsRefreshDropDown_Initialize);
		UIDropDownMenu_SetSelectedValue(self, value);
		self.value = value;
		self.newValue = value;
	end
end

function VideoOptionsRefreshDropDown_Initialize()
	VideoOptionsRefreshDropDown_GetRefreshRates(GetRefreshRates());
end

function VideoOptionsRefreshDropDown_GetRefreshRates(...)
	local info = UIDropDownMenu_CreateInfo();
	local checked;
	local control = Options.GetControlForCVar("gxRefresh");
	local controlName = control:GetName();
	if ( select("#", ...) == 1 and select(1, ...) == 0 ) then
		_G[controlName .. "Button"]:Disable();
		_G[controlName .. "Label"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		_G[controlName .. "Text"]:SetVertexColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		return;
	end
	for i=1, select("#", ...) do
		info.text = select(i, ...)..HERTZ;
		info.func = VideoOptionsRefreshDropDown_OnClick;

		if ( UIDropDownMenu_GetSelectedValue(control) and tonumber(UIDropDownMenu_GetSelectedValue(control)) == select(i, ...) ) then
			checked = 1;
			UIDropDownMenu_SetText(control, info.text);
		else
			checked = nil;
		end
		info.value = select(i, ...)
		info.checked = checked;
		UIDropDownMenu_AddButton(info);
	end
end

function VideoOptionsRefreshDropDown_OnClick(self)
	local value = self.value;
	local dropdown = Options.GetControlForCVar("gxRefresh");
	UIDropDownMenu_SetSelectedValue(dropdown, value);
	if ( dropdown.value == value ) then
		dropdown.newValue = nil;
	else
		dropdown.newValue = value;
	end
	VideoOptionsFrameApply:Enable();
end

function VideoOptionsMultiSampleDropDown_OnLoad(self)
	local value = GetCurrentMultisampleFormat();
	Options.SetCVarControl("_multisampling", self)

	self.defaultValue = 1;
	self.value = value;
	self.restart = true;

	UIDropDownMenu_SetWidth(self, 160);
	UIDropDownMenu_SetAnchor(self, 0, 23, "TOPRIGHT", "VideoOptionsResolutionPanelMultiSampleDropDownRight", "BOTTOMRIGHT");
	UIDropDownMenu_Initialize(self, VideoOptionsMultiSampleDropDown_Initialize);
	UIDropDownMenu_SetSelectedID(self, value);

	self.SetValue =
	function (self, value)
		SetMultisampleFormat(value);
	end;
	self.GetValue =
	function (self)
		return GetCurrentMultisampleFormat();
	end
	self.RefreshValue =
	function (self)
		local value = GetCurrentMultisampleFormat();
		UIDropDownMenu_Initialize(self, VideoOptionsMultiSampleDropDown_Initialize);
		UIDropDownMenu_SetSelectedID(self, value);
		self.value = value;
		self.newValue = value;
	end
end

function VideoOptionsMultiSampleDropDown_Initialize()
	VideoOptionsMultiSampleDropDown_GetMultisampleFormats(GetMultisampleFormats());
end

function VideoOptionsMultiSampleDropDown_GetMultisampleFormats(...)
	local colorBits, depthBits, multiSample;
	local info = UIDropDownMenu_CreateInfo();
	local index = 1;
	local control = Options.GetControlForCVar("_multisampling");
	for i=1, select("#", ...), 3 do
		colorBits, depthBits, multiSample = select(i, ...);
		info.text = format(MULTISAMPLING_FORMAT_STRING, colorBits, depthBits, multiSample);
		info.func = VideoOptionsMultiSampleDropDown_OnClick;

		if ( index == UIDropDownMenu_GetSelectedID(control) ) then
			info.checked = 1;
			UIDropDownMenu_SetText(control, info.text);
		else
			info.checked = nil;
		end
		UIDropDownMenu_AddButton(info);
		index = index + 1;
	end
end

function VideoOptionsMultiSampleDropDown_OnClick(self)
	local value = self:GetID();
	local dropdown = Options.GetControlForCVar("_multisampling");
	UIDropDownMenu_SetSelectedID(dropdown, value);
	if ( dropdown.value == value ) then
		dropdown.newValue = nil;
	else
		dropdown.newValue = value;
	end
	VideoOptionsFrameApply:Enable();
end

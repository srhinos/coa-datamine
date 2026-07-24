-- if you change something here you probably want to change the glue version too

function AudioOptionsFrame_Toggle ()
    if ( AudioOptionsFrame:IsShown() ) then
        AudioOptionsFrame:Hide();
    else
        AudioOptionsFrame:Show();
    end
end

function AudioOptionsFrame_SetAllToDefaults ()
    OptionsFrame_SetAllToDefaults(AudioOptionsFrame);

    if ( AudioOptionsFrame.audioRestart ) then
        AudioOptionsFrame_AudioRestart();
    end
end

function AudioOptionsFrame_SetCurrentToDefaults ()
    OptionsFrame_SetCurrentToDefaults(AudioOptionsFrame);

    if ( AudioOptionsFrame.audioRestart ) then
        AudioOptionsFrame_AudioRestart();
    end
end

function AudioOptionsFrame_AudioRestart ()
    AudioOptionsFrame.audioRestart = nil;
    Sound_GameSystem_RestartSoundSystem();
end

function AudioOptionsFrame_OnLoad (self)
    OptionsFrame_OnLoad(self);

    AudioOptionsFrame:SetHeight(540);
    AudioOptionsFrameCategoryFrame:SetHeight(449);
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
end

function AudioOptionsFrame_OnEvent (self, event, ...)
    if ( IsVoiceChatAllowedByServer() ) then
        _G[self:GetName().."HeaderText"]:SetText(SOUNDOPTIONS_MENU);
    else
        _G[self:GetName().."HeaderText"]:SetText(VOICE_SOUND);
    end
end

function AudioOptionsFrame_OnHide (self)
    OptionsFrame_OnHide(self);

    if ( AudioOptionsFrame.gameRestart ) then
        StaticPopup_Show("CLIENT_RESTART_ALERT");
        AudioOptionsFrame.gameRestart = nil;
    elseif ( AudioOptionsFrame.logout ) then
        StaticPopup_Show("CLIENT_LOGOUT_ALERT");
        AudioOptionsFrame.logout = nil;
    end
end

function AudioOptionsFrameCancel_OnClick (self, button)
    OptionsFrameCancel_OnClick(AudioOptionsFrame);

    if ( AudioOptionsFrame.audioRestart ) then
        AudioOptionsFrame_AudioRestart();
    end

    AudioOptionsFrame.gameRestart = nil;
    AudioOptionsFrame.logout = nil;

    AudioOptionsFrame_Toggle();
end

function AudioOptionsFrameOkay_OnClick (self, button)
    OptionsFrameOkay_OnClick(AudioOptionsFrame);

    if ( AudioOptionsFrame.audioRestart ) then
        AudioOptionsFrame_AudioRestart();
    end

    AudioOptionsFrame_Toggle();
end

function AudioOptionsFrameDefault_OnClick ()
    OptionsFrameDefault_OnClick(AudioOptionsFrame);

    StaticPopup_Show("CONFIRM_RESET_AUDIO_SETTINGS");
end

local function AudioOptionsPanel_Okay (self)
    for ctr, control in next, self.controls do
        if ( control.newValue ) then
            if ( control.value ~= control.newValue ) then
                if ( control.restart ) then
                    AudioOptionsFrame.audioRestart = true;
                end
                control:SetValue(control.newValue);
                control.value = control.newValue;
                control.newValue = nil;
            end
        elseif ( control.value ) then
            control:SetValue(control.value);
        end
    end

    if MiniMapVoiceChat_Update then
        MiniMapVoiceChat_Update()
    end
end

local function AudioOptionsPanel_Cancel (self)
    for _, control in next, self.controls do
        if ( control.newValue ) then
            if ( control.value and control.value ~= control.newValue ) then
                if ( control.restart ) then
                    AudioOptionsFrame.audioRestart = true;
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

local function AudioOptionsPanel_Default (self)
    for _, control in next, self.controls do
        if ( control.defaultValue and control.value ~= control.defaultValue ) then
            if ( control.restart ) then
                AudioOptionsFrame.audioRestart = true;
            end
            control:SetValue(control.defaultValue);
            control.newValue = nil;
        end
    end
    if MiniMapVoiceChat_Update then
        MiniMapVoiceChat_Update()
    end
end

function AudioOptionsPanel_OnLoad (self, okay, cancel, default, refresh)
    okay = okay or AudioOptionsPanel_Okay;
    cancel = cancel or AudioOptionsPanel_Cancel;
    default = default or AudioOptionsPanel_Default;
    refresh = refresh or BlizzardOptionsPanel_Refresh;
    BlizzardOptionsPanel_OnLoad(self, okay, cancel, default, refresh);
    OptionsFrame_AddCategory(AudioOptionsFrame, self);
end


function AudioOptionsHardwareDropDown_OnLoad (self)
    self.cvar = "Sound_OutputDriverIndex";
    Options.SetCVarControl(self.cvar, self)
    local selectedDriverIndex = BlizzardOptionsPanel_GetCVarSafe(self.cvar);
    local deviceName = Sound_GameSystem_GetOutputDriverNameByIndex(selectedDriverIndex);
    self.defaultValue = BlizzardOptionsPanel_GetCVarDefaultSafe(self.cvar);
    self.value = selectedDriverIndex;
    self.newValue = selectedDriverIndex;
    self.restart = true;

    UIDropDownMenu_SetWidth(self, 136);
    UIDropDownMenu_SetSelectedValue(self, selectedDriverIndex);
    UIDropDownMenu_Initialize(self, AudioOptionsHardwareDropDown_Initialize);

    self.SetValue =
    function (self, value)
        self.value = value;
        self.newValue = value;
        BlizzardOptionsPanel_SetCVarSafe(self.cvar, value);
    end
    self.GetValue =
    function (self)
        return BlizzardOptionsPanel_GetCVarSafe(self.cvar);
    end
    self.RefreshValue =
    function (self)
        local selectedDriverIndex = BlizzardOptionsPanel_GetCVarSafe(self.cvar);
        local deviceName = Sound_GameSystem_GetOutputDriverNameByIndex(selectedDriverIndex);
        self.value = selectedDriverIndex;
        self.newValue = selectedDriverIndex;

        UIDropDownMenu_SetSelectedValue(self, selectedDriverIndex);
        UIDropDownMenu_Initialize(self, AudioOptionsHardwareDropDown_Initialize);
    end
end

function AudioOptionsHardwareDropDown_Initialize(self)
    local selectedValue = UIDropDownMenu_GetSelectedValue(self);
    local num = Sound_GameSystem_GetNumOutputDrivers();
    local info = UIDropDownMenu_CreateInfo();
    for index=0,num-1,1 do
        info.text = Sound_GameSystem_GetOutputDriverNameByIndex(index);
        info.value = index;
        info.checked = nil;
        if (selectedValue and index == selectedValue) then
            UIDropDownMenu_SetText(self, info.text);
            info.checked = 1;
        else
            info.checked = nil;
        end
        info.func = AudioOptionsHardwareDropDown_OnClick;

        UIDropDownMenu_AddButton(info);
    end
end

function AudioOptionsHardwareDropDown_OnClick(self)
    local value = self.value;
    local dropdown = Options.GetControlForCVar("Sound_OutputDriverIndex");
    UIDropDownMenu_SetSelectedValue(dropdown, value);

    local prevValue = dropdown:GetValue();
    dropdown:SetValue(value);
    if ( dropdown.restart and prevValue ~= value ) then
        AudioOptionsFrame_AudioRestart();
    end
end
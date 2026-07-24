local function OnCheckCallback(self)
    local setting = BlizzardOptionsPanel_CheckButton_OnClick(self);
    if ( self.restart and self:GetValue() ~= setting ) then
        AudioOptionsFrame_AudioRestart();
    end
end

local function OnValueChangedCallback(self)
    local value = self:GetValue()
    if self.cvar then
        -- sound sliders should update immediately
        BlizzardOptionsPanel_SetCVarSafe(self.cvar, value)
    end
    if self:GetParent():IsShown() and self.restart and self.value and self.value ~= value then
        AudioOptionsFrame_AudioRestart();
    end
end

--
-- SOUND SETTING
--
do
    local category = Options.CreateCategory("AudioOptionsSoundPanel", AudioOptionsFramePanelContainer, SOUND_LABEL, SOUND_SUBTEXT, OnCheckCallback, OnValueChangedCallback)
    category:AddOption("EnableSound", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "Sound_EnableAllSound",
        text = "ENABLE_SOUND",
    })


    category:AddSpace(-12, Options.Column.Center) -- move up to align with checkbox
    category:AddOption("MasterVolume", "slider", Options.Column.Center, Options.Width.FullSingle, {
        cvar = "Sound_MasterVolume",
        text = "MASTER_VOLUME",
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.01,
        displayPrecision = 0,
        displayAsPercent = true,
    })
    category:AlignColumns()
    category:AddSpace(24)

    -- GENERAL SETTINGS
    category:StartGroup(SOUND_OPTION_GROUP_GENERAL, Options.Column.Left)

    category:AddOption("HardwareDropDown", "dropdown", Options.Column.Left, Options.Width.FullSingle, {
        init = AudioOptionsHardwareDropDown_OnLoad,
        text = "GAME_SOUND_OUTPUT",
        tooltip = OPTION_TOOLTIP_SOUND_OUTPUT,
    })

    category:AddOption("SoundChannels", "slider", Options.Column.Left, Options.Width.FullSingle, {
        cvar = "Sound_NumChannels",
        text = "SOUND_CHANNELS",
        minValue = 32,
        maxValue = 64,
        minText = LOW,
        maxText = HIGH,
        valueStep = 32,
        displayPrecision = 0,
        restart = true,
    })

    category:AddOption("SoundQuality", "slider", Options.Column.Left, Options.Width.FullSingle, {
        cvar = "Sound_OutputQuality",
        text = "SOUND_QUALITY",
        minValue = 0,
        maxValue = 2,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
        restart = true,
    })

    category:AddOption("SoundInBG", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "Sound_EnableSoundWhenGameIsInBG",
        text = "ENABLE_BGSOUND",
    })

    category:AddOption("HRTF", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "Sound_EnableSoftwareHRTF",
        text = "ENABLE_SOFTWARE_HRTF",
        restart = true,
    })

    category:AddOption("UseHardware", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "Sound_EnableHardware",
        text = "ENABLE_HARDWARE",
        restart = true,
    })

    category:CloseGroup(Options.Column.Left)
    
    -- SOUND EFFECTS
    category:StartGroup(SOUND_OPTION_GROUP_EFFECTS, Options.Column.Center)
    local soundEffects = category:AddOption("SoundEffects", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnableSFX",
        text = "ENABLE_SOUNDFX",
    })

    category:AddSpace(-20, Options.Column.Center) -- we hide the title of these sliders
    category:AddOption("SoundVolume", "slider", Options.Column.Center, Options.Width.FullSingle, {
        cvar = "Sound_SFXVolume",
        text = "",
        tooltip = OPTION_TOOLTIP_SOUND_VOLUME,
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.01,
        displayPrecision = 0,
        displayAsPercent = true,
        dependentControl = soundEffects,
    })

    category:AddOption("ErrorSpeech", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnableErrorSpeech",
        text = "ENABLE_ERROR_SPEECH",
        indentLevel = Options.Indent.Single,
        dependentControl = soundEffects,
    })

    category:AddOption("EmoteSounds", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnableEmoteSounds",
        text = "ENABLE_EMOTE_SOUNDS",
        indentLevel = Options.Indent.Single,
        dependentControl = soundEffects,
    })

    category:AddOption("PetSounds", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnablePetSounds",
        text = "ENABLE_PET_SOUNDS",
        indentLevel = Options.Indent.Single,
        dependentControl = soundEffects,
    })

    category:AddOption("EnableDSPs", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnableDSPEffects",
        text = "ENABLE_DSP_EFFECTS",
        indentLevel = Options.Indent.Single,
        restart = true,
        dependentControl = soundEffects,
    })
    
    category:AddOption("Reverb", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "Sound_EnableReverb",
        text = "ENABLE_REVERB",
        dependentControl = soundEffects,
    })

    category:CloseGroup(Options.Column.Center)

    -- MUSIC AND AMBIENCE
    category:StartGroup(SOUND_OPTION_GROUP_MUSIC, Options.Column.Right)
    local music = category:AddOption("Music", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "Sound_EnableMusic",
        text = "ENABLE_MUSIC",
    })
    
    category:AddSpace(-20, Options.Column.Right) -- we hide the title of these sliders
    category:AddOption("MusicVolume", "slider", Options.Column.Right, Options.Width.FullSingle, {
        cvar = "Sound_MusicVolume",
        text = "",
        tooltip = OPTION_TOOLTIP_MUSIC_VOLUME,
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.01,
        displayPrecision = 0,
        displayAsPercent = true,
        dependentControl = music,
    })

    category:AddOption("LoopMusic", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "Sound_ZoneMusicNoDelay",
        text = "ENABLE_MUSIC_LOOPING",
        indentLevel = Options.Indent.Single,
        dependentControl = music,
    })

    category:AddSpace(10, Options.Column.Right)

    local ambience = category:AddOption("AmbientSounds", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "Sound_EnableAmbience",
        text = "ENABLE_AMBIENCE",
    })

    category:AddSpace(-20, Options.Column.Right) -- we hide the title of these sliders
    category:AddOption("AmbienceVolume", "slider", Options.Column.Right, Options.Width.FullSingle, {
        cvar = "Sound_AmbienceVolume",
        text = "",
        tooltip = OPTION_TOOLTIP_AMBIENCE_VOLUME,
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.01,
        displayPrecision = 0,
        displayAsPercent = true,
        dependentControl = ambience,
    })
    category:CloseGroup(Options.Column.Right)

    AudioSettings_AddCategory(category, nil, nil, nil, nil)
end

--
-- VOICE CHAT
--
-- voice chat remains in AudioOptionsVoice since it is currently disabled and pointless to spend time upgrading.

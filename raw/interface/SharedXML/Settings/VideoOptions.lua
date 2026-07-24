local OnCheckCallback = function(self)
    BlizzardOptionsPanel_CheckButton_OnClick(self);
    if self:GetParent().UpdateQualitySlider then
        self:GetParent():UpdateQualitySlider()
    end
    VideoOptionsFrameApply:Enable();
end
local OnValueChangedCallback = function(self)
    if self:GetParent().UpdateQualitySlider then
        self:GetParent():UpdateQualitySlider()
    end
    VideoOptionsFrameApply:Enable();
end
--
-- Display Options
--
do
    local category = Options.CreateCategory("VideoOptionsResolutionPanel", VideoOptionsFramePanelContainer, RESOLUTION_LABEL, RESOLUTION_SUBTEXT, OnCheckCallback, OnValueChangedCallback)

    category:AddOption("ResolutionDropDown", "dropdown", Options.Column.Left, Options.Width.FullSingle, {
        init = VideoOptionsResolutionDropDown_OnLoad,
        text = "RESOLUTION",
        tooltip = OPTION_TOOLTIP_USE_RESOLUTION,
    })

    category:AddOption("RefreshDropDown", "dropdown", Options.Column.Center, Options.Width.Single, {
        init = VideoOptionsRefreshDropDown_OnLoad,
        text = "REFRESH_RATE",
        tooltip = OPTION_TOOLTIP_USE_REFRESH,
    })

    category:AddOption("MultiSampleDropDown", "dropdown", Options.Column.Left, Options.Width.FullSingle, {
        init = VideoOptionsMultiSampleDropDown_OnLoad,
        text = "MULTISAMPLE",
        tooltip = OPTION_TOOLTIP_MULTISAMPLING,
    })
    
    category:AddSpace(6, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    -- left column
    local windowed = category:AddOption("Windowed", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "gxWindow",
        text = "WINDOWED_MODE",
        restart = true,
        setFunc = function(_, self)
            self:GetParent():RefreshGammaControls()
            local value
            local gammaControl = Options.GetControlForCVar("desktopGamma")
            if self:GetChecked() or gammaControl:GetChecked() then
                value = 1
            else
                value = 0
            end
            BlizzardOptionsPanel_SetCVarSafe("desktopGamma", value)
        end
    })

    category:AddOption("Maximized", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "gxMaximize",
        text = "WINDOWED_MAXIMIZED",
        restart = true,
        indentLevel = 1,
        dependentControl = windowed,
    })

    category:AddOption("DisableResize", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "windowResizeLock",
        text = "WINDOW_LOCK",
        restart = true,
        indentLevel = Options.Indent.Single,
        windowsOnly = true,
        dependentControl = windowed,
    })

    -- center column
    local vsync = category:AddOption("VSync", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "gxVSync",
        text = "VERTICAL_SYNC",
        restart = true,
    })

    category:AddOption("TripleBuffer", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "gxTripleBuffer",
        text = "TRIPLE_BUFFER",
        restart = true,
        indentLevel = 1,
        dependentControl = vsync,
    })
    
    -- right column
    local hwCursor = category:AddOption("HardwareCursor", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "gxCursor",
        text = "HARDWARE_CURSOR",
        restart = true,
    })
    hwCursor:SetScript("OnShow", function(self)
        local canUseHardwareCursor = select(7, GetVideoCaps())
        if canUseHardwareCursor then
            self:Enable()
            self.disableTooltipText = nil
        else
            self:Disable()
            self:SetChecked(false)
        end
    end)

    category:AddOption("FixInputLag", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "gxFixLag",
        text = "FIX_LAG",
        restart = true,
    })

    category:AddSpace(12, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    local useUiScale = category:AddOption("UseUIScale", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "useUiScale",
        text = "USE_UISCALE",
        restart = true
    })
    category:AddSpace(-16, Options.Column.Left)
    category:AddOption("UIScaleSlider", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "uiScale",
        text = "",
        restart = true,
        minValue = 0.64,
        maxValue = 1,
        displayPrecision = 2,
        valueStep = 0.01,
        dependentControl = useUiScale,
    })

    category:AddSpace(12, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    category:AddOption("MaxFPS", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "MaxFPS",
        text = "MAX_FOREGROUND_FPS",
        minValue = 15,
        maxValue = 300,
        displayPrecision = 0,
        valueStep = 1,
    })

    category:AddOption("MaxFPSBK", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "MaxFPSBK",
        text = "MAX_BACKGROUND_FPS",
        minValue = 15,
        maxValue = 60,
        displayPrecision = 0,
        valueStep = 1,
    })

    category:AddSpace(40, Options.Column.Left)
    category:AlignColumns() -- bring all columns down
    
    -- START BRIGHTNESS GROUP
    category:StartGroup(OPTIONS_BRIGHTNESS, Options.Column.Left)
    category:AddOption("DesktopGamma", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "desktopGamma",
        setFunc = function(value, self)
            self:GetParent():RefreshGammaControls()
            BlizzardOptionsPanel_SetCVarSafe("desktopGamma", value)
        end,
        text = "DESKTOP_GAMMA",
    })

    category:AddOption("GammaSlider", "slider", Options.Column.Center, Options.Width.Single, {
        label = "gamma",
        setValue = function(self, value) SetGamma(value) end,
        getCurrentValue = GetGamma,
        text = "GAMMA",
        minValue = -0.5,
        maxValue = 0.5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.1,
        displayPrecision = 2,
        indentLevel = Options.Indent.Double,
    })
    category:AddSpace(58, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    local group = category:CloseGroup(Options.Column.Center)
    
    -- add brightness texture
    local brightnessTexture = group:CreateTexture("VideoOptionsResolutionPanelBrightnessGrayScale", "ARTWORK")
    brightnessTexture:SetTexture("Interface\\OptionsFrame\\21stepgrayscale")
    brightnessTexture:SetPoint("BOTTOMLEFT", 8, 8)
    brightnessTexture:SetPoint("BOTTOMRIGHT", -8, 8)
    brightnessTexture:SetHeight(32)
    -- END BRIGHTNESS GROUP
    
    category.RefreshGammaControls = function(self)
        local windowedControl = Options.GetControlForCVar("gxWindow")
        local gammaControl = Options.GetControlForCVar("desktopGamma")
        local gammaSlider = Options.GetControlForCVar("gamma")
        if windowedControl:GetChecked() then
            gammaControl:SetChecked(false)
            gammaControl:Disable()
            BlizzardOptionsPanel_Slider_Disable(gammaSlider)
        else
            gammaControl:Enable()
            if gammaControl:GetChecked() then
                BlizzardOptionsPanel_Slider_Enable(gammaSlider)
            else
                BlizzardOptionsPanel_Slider_Disable(gammaSlider)
            end
        end
    end
    
    local function RefreshDisplaySettings(self)
        BlizzardOptionsPanel_Refresh(self)
        self:RefreshGammaControls()
    end

    VideoSettings_AddCategory(category, nil, nil, nil, RefreshDisplaySettings)
end

do -- Graphics Options
    local category = Options.CreateCategory("VideoOptionsEffectsPanel", VideoOptionsFramePanelContainer, EFFECTS_LABEL, EFFECTS_SUBTEXT, OnCheckCallback, OnValueChangedCallback)

    category:StartGroup("", Options.Column.Left)
    category:AddSpace(42)
    -- QUALITY SLIDER
    local qualitySlider = category:AddOption("QualitySlider", "slider", Options.Column.Left, Options.Width.Full, {
        text = "",
        label = "quality",
        minValue = 1,
        maxValue = 6,
        minText = LOW,
        maxText = CUSTOM,
        valueStep = 1,
        displayPrecision = 0,
        hideValue = true,
        getCurrentValue = GraphicsPresets.GetCurrentGlobalPreset,
        setValue = function(self, value)
            self.Label:SetFormattedText(VIDEO_QUALITY_S, _G["VIDEO_QUALITY_LABEL"..value])
            self.SubText:SetFormattedText(VIDEO_QUALITY_S, _G["VIDEO_QUALITY_SUBTEXT" .. value])
            if value <= 5 then
                GraphicsPresets.ApplyGlobalPreset(value)
            end
        end,
    })
    local qualityGroup = category:CloseGroup(Options.Column.Right)
    -- make quality title
    qualityGroup.Label = qualityGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    qualityGroup.Label:SetPoint("TOPLEFT", 16, -8)
    qualityGroup.Label:SetPoint("RIGHT", -16, 0)
    qualityGroup.Label:SetJustifyH("LEFT")
    qualitySlider.Label = qualityGroup.Label

    -- quality subtext
    qualityGroup.SubText = qualityGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlightExtraSmall")
    qualityGroup.SubText:SetHeight(42)
    qualityGroup.SubText:SetPoint("TOPLEFT", qualityGroup.Label, "BOTTOMLEFT", 0, -2)
    qualityGroup.SubText:SetPoint("TOPRIGHT", qualityGroup.Label, "BOTTOMRIGHT", 0, -2)
    qualityGroup.SubText:SetJustifyH("LEFT")
    qualityGroup.SubText:SetJustifyV("TOP")
    qualitySlider.SubText = qualityGroup.SubText
    
    -- END OF QUALITY SLIDER

    category:AddSpace(16)

    -- TOP ROW = NON DYNAMIC OPTIONS
    category:AddOption("TextureResolution", "slider", Options.Column.Left, Options.Width.Single, {
        text = "TEXTURE_DETAIL",
        cvar = "BaseMip",
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        restart = 1,
        displayPrecision = 0,
        inverted = true,
    })
    
    category:AddOption("TextureFiltering", "slider", Options.Column.Center, Options.Width.Single, {
        text = "ANISOTROPIC",
        cvar = "textureFilteringMode",
        minValue = 0,
        maxValue = 5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
        gameRestart = 1,
        tooltipRequirement = OPTION_RESTART_REQUIREMENT
    })

    category:AddOption("PlayerTexture", "slider", Options.Column.Right, Options.Width.Single, {
        text = "PLAYER_DETAIL",
        cvar = "componentTextureLevel",
        minValue = 8,
        maxValue = 9,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
        gameRestart = 1,
        tooltipRequirement = OPTION_RESTART_REQUIREMENT,
        onShow = function(self)
            if not IsPlayerResolutionAvailable() then
                self:Disable()
            else
                self:Enable()
            end
        end
    })
    
    category:AddOption("TerrainDetail", "slider", Options.Column.Left, Options.Width.Single, {
        text = "TERRAIN_MIP",
        label = "TerrainMip",
        minValue = 0,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
        setValue = function(self, value) SetTerrainMip(value) end,
        getCurrentValue = GetTerrainMip,
        logout = 1,
        tooltip = OPTION_TOOLTIP_TERRAIN_TEXTURE,
        tooltipRequirement = OPTION_LOGOUT_REQUIREMENT,
    })

    category:AddOption("WeatherIntensity", "slider", Options.Column.Center, Options.Width.Single, {
        text = "WEATHER_DETAIL",
        cvar = "weatherDensity",
        minValue = 0,
        maxValue = 3,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
    })

    category:AddSpace(12, Options.Column.Right)
    category:AddOption("LODObjectCulling", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "lodObjectCull",
        text = "LOD_OBJECT_CULL",
    })

    category:AlignColumns() -- bring all columns down

    category:AddOption("SpecularLighting", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "TERRAIN_HIGHLIGHTS",
        cvar = "specular",
    })

    if InGlue() then -- glue screen cannot register this 
        local glowEffect = category:AddOption("FullScreenGlow", "checkbox", Options.Column.Center, Options.Width.Single, {
            text = "FULL_SCREEN_GLOW",
            label = "ffxGlow",
            disableTooltip = CANNOT_BE_CHANGED_IN_GLUE,
        })
        BlizzardOptionsPanel_CheckButton_Disable(glowEffect)
    else
        category:AddOption("FullScreenGlow", "checkbox", Options.Column.Center, Options.Width.Single, {
            text = "FULL_SCREEN_GLOW",
            cvar = "ffxGlow",
        })
    end

    if InGlue() then -- glue screen cannot register this 
        local glowEffect = category:AddOption("DeathEffect", "checkbox", Options.Column.Right, Options.Width.Single, {
            text = "DEATH_EFFECT",
            label = "ffxDeath",
            disableTooltip = CANNOT_BE_CHANGED_IN_GLUE,
        })
        BlizzardOptionsPanel_CheckButton_Disable(glowEffect)
    else
        category:AddOption("DeathEffect", "checkbox", Options.Column.Right, Options.Width.Single, {
            text = "DEATH_EFFECT",
            cvar = "ffxDeath",
        })
    end
    
    category:AddSpace(28, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    --
    -- OPEN WORLD SETTINGS
    --
    category:StartGroup(VIDEO_OPTION_GROUP_GLOBAL, Options.Column.Left)
    category:AlignColumns() -- bring all columns down
    
    -- FIRST ROW
    category:AddOption("ViewDistance", "slider", Options.Column.Left, Options.Width.Single, {
        text = "FARCLIP",
        cvar = "farclip",
        minValue = 177,
        maxValue = 1277,
        minText = LOW,
        maxText = HIGH,
        valueStep = 110,
        displayPrecision = 0,
    })
    
    category:AddOption("ShadowQuality", "slider", Options.Column.Center, Options.Width.Single, {
        text = "SHADOW_QUALITY",
        cvar = "extShadowQuality",
        minValue = 0,
        maxValue = 5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
    })

    category:AddOption("EnvironmentDetail", "slider", Options.Column.Right, Options.Width.Single, {
        text = "ENVIRONMENT_DETAIL",
        cvar = "environmentDetail",
        minValue = 0.5,
        maxValue = 1.5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.25,
        displayPrecision = 2,
    })

    -- SECOND ROW
    category:AddOption("ParticleDensity", "slider", Options.Column.Center, Options.Width.Single, {
        text = "PARTICLE_DENSITY",
        cvar = "particleDensity",
        minValue = 0.1,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.1,
        displayPrecision = 2,
    })
    
    category:AddOption("ClutterDensity", "slider", Options.Column.Right, Options.Width.Single, {
        text = "GROUND_DENSITY",
        cvar = "groundEffectDensity",
        minValue = 16,
        maxValue = 64,
        minText = LOW,
        maxText = HIGH,
        valueStep = 8,
        displayPrecision = 0,
    })

    -- THIRD ROW
    category:AddSpace(12, Options.Column.Left)
    category:AddOption("EntityShadows", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "ENTITY_SHADOWS",
        cvar = "entityShadows",
    })

    category:AddSpace(12, Options.Column.Center)
    category:AddOption("ProjectedTextures", "checkbox", Options.Column.Center, Options.Width.Single, {
        text = "PROJECTED_TEXTURES",
        cvar = "projectedTextures",
    })

    category:AddOption("ClutterRadius", "slider", Options.Column.Right, Options.Width.Single, {
        text = "GROUND_RADIUS",
        cvar = "groundEffectDist",
        minValue = 70,
        maxValue = 140,
        minText = LOW,
        maxText = HIGH,
        valueStep = 10,
        displayPrecision = 0,
    })
    
    -- FOURTH ROW
    category:AddSpace(12, Options.Column.Center)
    category:AddOption("StaticLOD", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "STATIC_LOD",
        cvar = "animateClouds",
    })


    category:AlignColumns() -- bring all columns down
    category:CloseGroup(Options.Column.Right)

    category.UpdateQualitySlider = function()
        local qualityLevel = GraphicsPresets.GetCurrentGlobalPreset()
        _G[qualitySlider:GetName().."Value"]:SetText(MTrunc(qualityLevel, 0))
        qualitySlider:SetValue(qualityLevel)
    end

    local function SetControlDisabledIfInRaid(index, control, useRaidSettings, inInstance, instanceType)
        if inInstance and (instanceType == "raid" or instanceType == "pvp") then
            if useRaidSettings then
                control:Disable()
                control.disableTooltipText = CANNOT_BE_CHANGED_IN_RAID
            else
                control:Enable()
                control.disableTooltipText = nil
            end
        else
            control:Enable()
            control.disableTooltipText = nil
        end
    end
    
    category:SetScript("OnShow", function(self)
        self:UpdateQualitySlider()
        if InGlue() then return end
        local useRaidSettings = C_CVar.GetBool("useRaidVideoSettings")
        secureexecuterange(self.controls, SetControlDisabledIfInRaid, useRaidSettings, IsInInstance())
    end)
    VideoSettings_AddCategory(category, nil, nil, nil, nil)
end

do -- Raid Options
    local category = Options.CreateCategory("VideoOptionsRaidEffectsPanel", VideoOptionsFramePanelContainer, RAID_EFFECTS_LABEL, RAID_EFFECTS_SUBTEXT, OnCheckCallback, OnValueChangedCallback)

    local useRaidSettings = category:AddOption("UseRaidSettings", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "USE_RAID_SETTINGS",
        cvar = "useRaidVideoSettings",
    })
    
    category:AddSpace(12, Options.Column.Left)
    category:StartGroup("", Options.Column.Left)
    category:AddSpace(42)
    -- QUALITY SLIDER
    local qualitySlider = category:AddOption("QualitySlider", "slider", Options.Column.Left, Options.Width.Full, {
        text = "",
        label = "quality",
        minValue = 1,
        maxValue = 6,
        minText = LOW,
        maxText = CUSTOM,
        valueStep = 1,
        displayPrecision = 0,
        hideValue = true,
        getCurrentValue = GraphicsPresets.GetCurrentRaidPreset,
        setValue = function(self, value)
            self.Label:SetFormattedText(VIDEO_QUALITY_S, _G["VIDEO_QUALITY_LABEL"..value])
            self.SubText:SetFormattedText(VIDEO_QUALITY_S, _G["VIDEO_QUALITY_SUBTEXT" .. value])
            if value <= 5 then
                GraphicsPresets.ApplyRaidPreset(value)
            end
        end,
        dependentControl = useRaidSettings,
    })
    local qualityGroup = category:CloseGroup(Options.Column.Right)
    -- make quality title
    qualityGroup.Label = qualityGroup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    qualityGroup.Label:SetPoint("TOPLEFT", 16, -8)
    qualityGroup.Label:SetPoint("RIGHT", -16, 0)
    qualityGroup.Label:SetJustifyH("LEFT")
    qualitySlider.Label = qualityGroup.Label

    -- quality subtext
    qualityGroup.SubText = qualityGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlightExtraSmall")
    qualityGroup.SubText:SetHeight(42)
    qualityGroup.SubText:SetPoint("TOPLEFT", qualityGroup.Label, "BOTTOMLEFT", 0, -2)
    qualityGroup.SubText:SetPoint("TOPRIGHT", qualityGroup.Label, "BOTTOMRIGHT", 0, -2)
    qualityGroup.SubText:SetJustifyH("LEFT")
    qualityGroup.SubText:SetJustifyV("TOP")
    qualitySlider.SubText = qualityGroup.SubText

    -- END OF QUALITY SLIDER

    category:AddSpace(32)
    category:StartGroup(VIDEO_OPTION_GROUP_RAID, Options.Column.Left)
    category:AlignColumns() -- bring all columns down

    -- FIRST ROW
    category:AddOption("ViewDistanceRaid", "slider", Options.Column.Left, Options.Width.Single, {
        text = "FARCLIP",
        cvar = "farclip_raid",
        minValue = 177,
        maxValue = 1277,
        minText = LOW,
        maxText = HIGH,
        valueStep = 110,
        displayPrecision = 0,
        dependentControl = useRaidSettings,
    })

    category:AddOption("ShadowQualityRaid", "slider", Options.Column.Center, Options.Width.Single, {
        text = "SHADOW_QUALITY",
        cvar = "extShadowQuality_raid",
        minValue = 0,
        maxValue = 5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
        dependentControl = useRaidSettings,
    })

    category:AddOption("EnvironmentDetailRaid", "slider", Options.Column.Right, Options.Width.Single, {
        text = "ENVIRONMENT_DETAIL",
        cvar = "environmentDetail_raid",
        minValue = 0.5,
        maxValue = 1.5,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.25,
        displayPrecision = 2,
        dependentControl = useRaidSettings,
    })

    -- SECOND ROW
    category:AddOption("ParticleDensityRaid", "slider", Options.Column.Center, Options.Width.Single, {
        text = "PARTICLE_DENSITY",
        cvar = "particleDensity_raid",
        minValue = 0.1,
        maxValue = 1,
        minText = LOW,
        maxText = HIGH,
        valueStep = 0.1,
        displayPrecision = 2,
        dependentControl = useRaidSettings,
    })

    category:AddOption("ClutterDensityRaid", "slider", Options.Column.Right, Options.Width.Single, {
        text = "GROUND_DENSITY",
        cvar = "groundEffectDensity_raid",
        minValue = 16,
        maxValue = 64,
        minText = LOW,
        maxText = HIGH,
        valueStep = 8,
        displayPrecision = 0,
        dependentControl = useRaidSettings,
    })

    -- THIRD ROW
    category:AddSpace(12, Options.Column.Left)
    category:AddOption("EntityShadowsRaid", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "ENTITY_SHADOWS",
        cvar = "entityShadows_raid",
        dependentControl = useRaidSettings,
    })

    category:AddSpace(12, Options.Column.Center)
    local projectedTextures = category:AddOption("ProjectedTexturesRaid", "checkbox", Options.Column.Center, Options.Width.Single, {
        text = "PROJECTED_TEXTURES",
        cvar = "projectedTextures_raid",
        disableTooltip = PROJECTED_TEXTURES_ALWAYS_ENABLED,
        --dependentControl = useRaidSettings,
    })
    -- this is just always disabled, players should not be able to disable projected textures in raids.
    BlizzardOptionsPanel_CheckButton_Disable(projectedTextures)

    category:AddOption("ClutterRadiusRaid", "slider", Options.Column.Right, Options.Width.Single, {
        text = "GROUND_RADIUS",
        cvar = "groundEffectDist_raid",
        minValue = 70,
        maxValue = 140,
        minText = LOW,
        maxText = HIGH,
        valueStep = 10,
        displayPrecision = 0,
        dependentControl = useRaidSettings,
    })
    
    -- FOURTH ROW
    category:AddSpace(12, Options.Column.Center)
    category:AddOption("StaticLOD", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "STATIC_LOD",
        cvar = "animateClouds_raid",
        dependentControl = useRaidSettings,
    })


    category:AlignColumns() -- bring all columns down
    category:CloseGroup(Options.Column.Right)

    category.UpdateQualitySlider = function()
        local qualityLevel = GraphicsPresets.GetCurrentRaidPreset()
        _G[qualitySlider:GetName().."Value"]:SetText(MTrunc(qualityLevel, 0))
        qualitySlider:SetValue(qualityLevel)
    end

    category:SetScript("OnShow", category.UpdateQualitySlider)
    
    VideoSettings_AddCategory(category, nil, nil, nil, nil)
end

do -- stereo video settings
    local category = Options.CreateCategory("VideoOptionsStereoPanel", VideoOptionsFramePanelContainer, STEREO_VIDEO_LABEL, STEREO_VIDEO_SUBTEXT, OnCheckCallback, OnValueChangedCallback)

    local stereoEnabled = category:AddOption("Enabled", "checkbox", Options.Column.Left, Options.Width.Single, {
        text = "ENABLE_STEREO_VIDEO",
        cvar = "gxStereoEnabled",
        restart = true,
    })

    category:AddOption("Convergence", "slider", Options.Column.Left, Options.Width.Single, {
        text = "DEPTH_CONVERGENCE",
        cvar = "gxStereoConvergence",
        minValue = 0.2,
        maxValue = 50,
        valueStep = 0.1,
        tooltip = OPTION_STEREO_CONVERGENCE,
        dependentControl = stereoEnabled
    })

    category:AddOption("EyeSeparation", "slider", Options.Column.Left, Options.Width.Single, {
        text = "EYE_SEPARATION",
        cvar = "gxStereoSeparation",
        minValue = 0,
        maxValue = 100,
        valueStep = 1,
        tooltip = OPTION_STEREO_SEPARATION,
        dependentControl = stereoEnabled
    })

    if IsStereoVideoAvailable() then
        -- we dont check this first because some stuff might depend on these buttons existing even if hidden
        VideoSettings_AddCategory(category, nil, nil, nil, nil)
    end
end

--[[
local testCategory = Options.CreateCategory("Test", VideoOptionsFramePanelContainer, "Test", "Test", function() end, function() VideoOptionsFrameApply:Enable() end)
testCategory:AddOption("TestSlider", "slider", 1, 2, {
    text = "MAX_FOREGROUND_FPS",
    cvar = "maxFPS",
    minValue = 15,
    maxValue = 300,
    valueStep = 1,
    displayPrecision = 2,
})
VideoSettings_AddCategory(testCategory)

category:AddOption("WeatherIntensity", "slider", Options.Column.Right, Options.Width.Single, {
        text = "WEATHER_DETAIL",
        cvar = "weatherDensity",
        minValue = 0,
        maxValue = 3,
        minText = LOW,
        maxText = HIGH,
        valueStep = 1,
        displayPrecision = 0,
    })
]]

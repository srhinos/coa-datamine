GraphicsPresets = {}

GraphicsPresets.Quality = {
    Low = 1,
    Fair = 2,
    Good = 3,
    High = 4,
    Ultra = 5,
    Custom = 6,
}

local function GetPreset(group)
    -- check if settings match, if they dont match any of the presets, return custom
    for i = 1, 5 do
        local preset = group[i]
        local match = true
        for cvar, value in pairs(preset) do
            local control = Options.GetControlForCVar(cvar)
            if control then
                --ffxGlow isnt registered in glue and ffxDeath is registered too late in glue.
                if not InGlue() or (cvar ~= "ffxGlow" and cvar ~= "ffxDeath") then
                    if control.type == CONTROLTYPE_CHECKBOX then
                        if control:GetChecked() and not value or not control:GetChecked() and value then
                            match = false
                            break
                        end
                    else
                        local controlValue = tonumber(control:GetValue())
                        if not math.NearlyEquals(controlValue, value, 0.000001) then
                            match = false
                            break
                        end
                    end
                end
            end
        end
        if match then
            return i
        end
    end

    return GraphicsPresets.Quality.Custom
end

function GraphicsPresets.GetCurrentGlobalPreset()
    return GetPreset(GraphicsPresets.Global)
end

function GraphicsPresets.GetCurrentRaidPreset()
    return GetPreset(GraphicsPresets.Raid)
end

function GraphicsPresets.ApplyGlobalPreset(preset)
    if not preset then return end
    local group = GraphicsPresets.Global[preset]
    if not group then return end
    for cvar, value in pairs(group) do
        local control = Options.GetControlForCVar(cvar)
        if control then
            if control.type == CONTROLTYPE_CHECKBOX then
                control:SetChecked(value)
                BlizzardOptionsPanel_CheckButton_SetNewValue(control)
            else
                control:SetDisplayValue(value)
            end
        end
    end
    VideoOptionsFrameApply:Enable()
end

function GraphicsPresets.ApplyRaidPreset(preset)
    if not preset then return end
    local group = GraphicsPresets.Raid[preset]
    if not group then return end
    for cvar, value in pairs(group) do
        local control = Options.GetControlForCVar(cvar)
        if control then
            if control.type == CONTROLTYPE_CHECKBOX then
                control:SetChecked(value)
                BlizzardOptionsPanel_CheckButton_SetNewValue(control)
            else
                control:SetDisplayValue(value)
            end
        end
    end
    VideoOptionsFrameApply:Enable()
end

function GraphicsPresets.FixupQualityPresets()
    -- set the lowest and highest
    -- some systems have different maximum / minimum values for cvars
    for quality, cvars in pairs(GraphicsPresets.Global) do
        for cvar, value in pairs(cvars) do
            if GetCVarInfo(cvar) then -- check if its a cvar or custom control (TerrainMip is a custom control)
                local minValue = BlizzardOptionsPanel_GetCVarMinSafe(cvar)
                local maxValue = BlizzardOptionsPanel_GetCVarMaxSafe(cvar)

                -- ensure min settings are at the minimum preset
                -- and max settings are at the maximum preset
                if quality == GraphicsPresets.Quality.Low and minValue then
                    cvars[cvar] = minValue
                elseif quality == GraphicsPresets.Quality.Ultra and maxValue then
                    cvars[cvar] = maxValue
                else
                    if minValue and value < minValue then
                        cvars[cvar] = minValue
                    elseif maxValue and value > maxValue then
                        cvars[cvar] = maxValue
                    end
                end
            end
        end
    end

    for quality, cvars in pairs(GraphicsPresets.Raid) do
        for cvar, value in pairs(cvars) do
            local parentCVar = cvar:match("(.+)_raid$")
            if parentCVar then
                if GetCVarInfo(parentCVar) then -- check if its a cvar or custom control
                    local minValue = BlizzardOptionsPanel_GetCVarMinSafe(parentCVar)
                    local maxValue = BlizzardOptionsPanel_GetCVarMaxSafe(parentCVar)

                    -- ensure min settings are at the minimum preset
                    -- and max settings are at the maximum preset
                    if quality == GraphicsPresets.Quality.Low and minValue then
                        cvars[cvar] = minValue
                    elseif quality == GraphicsPresets.Quality.Ultra and maxValue then
                        cvars[cvar] = maxValue
                    else
                        if minValue and value < minValue then
                            cvars[cvar] = minValue
                        elseif maxValue and value > maxValue then
                            cvars[cvar] = maxValue
                        end
                    end
                end
            end
        end
    end
end

GraphicsPresets.Global = {
    [GraphicsPresets.Quality.Low] = {
        farclip                 = 177, -- view distance
        TerrainMip              = 0, -- terrain detail 
        particleDensity         = 0.1, -- particle density
        environmentDetail       = 0.5, -- environment detail
        groundEffectDensity     = 16, -- clutter density
        groundEffectDist        = 70, -- clutter radius
        extShadowQuality        = 0, -- shadow quality
        BaseMip                 = 0, -- texture resolution
        textureFilteringMode    = 0, -- texture filtering
        weatherDensity          = 0, -- weather intensity
        componentTextureLevel   = 8, -- player texture
        specular                = false, -- specular lighting
        ffxGlow                 = false, -- full screen glow
        ffxDeath                = false, -- death effect
        projectedTextures       = false, -- projected textures
        entityShadows           = false, -- entity shadows
        animateClouds           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Fair] = {
        farclip                 = 507, -- view distance
        TerrainMip              = 0, -- terrain detail 
        particleDensity         = 0.4, -- particle density
        environmentDetail       = 0.75, -- environment detail
        groundEffectDensity     = 24, -- clutter density
        groundEffectDist        = 80, -- clutter radius
        extShadowQuality        = 0, -- shadow quality
        BaseMip                 = 0, -- texture resolution
        textureFilteringMode    = 1, -- texture filtering
        weatherDensity          = 0, -- weather intensity
        componentTextureLevel   = 8, -- player texture
        specular                = false, -- specular lighting
        ffxGlow                 = false, -- full screen glow
        ffxDeath                = false, -- death effect
        projectedTextures       = true, -- projected textures
        entityShadows           = false, -- entity shadows
        animateClouds           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Good] = {
        farclip                 = 727, -- view distance
        TerrainMip              = 0, -- terrain detail 
        particleDensity         = 0.6, -- particle density
        environmentDetail       = 1.0, -- environment detail
        groundEffectDensity     = 48, -- clutter density
        groundEffectDist        = 120, -- clutter radius
        extShadowQuality        = 1, -- shadow quality
        BaseMip                 = 1, -- texture resolution
        textureFilteringMode    = 2, -- texture filtering
        weatherDensity          = 2, -- weather intensity
        componentTextureLevel   = 9, -- player texture
        specular                = true, -- specular lighting
        ffxGlow                 = true, -- full screen glow
        ffxDeath                = true, -- death effect
        projectedTextures       = true, -- projected textures
        entityShadows           = false, -- entity shadows
        animateClouds           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.High] = {
        farclip                 = 1057, -- view distance
        TerrainMip              = 1, -- terrain detail 
        particleDensity         = 0.8, -- particle density
        environmentDetail       = 1.25, -- environment detail
        groundEffectDensity     = 56, -- clutter density
        groundEffectDist        = 130, -- clutter radius
        extShadowQuality        = 4, -- shadow quality
        BaseMip                 = 1, -- texture resolution
        textureFilteringMode    = 4, -- texture filtering
        weatherDensity          = 3, -- weather intensity
        componentTextureLevel   = 9, -- player texture
        specular                = true, -- specular lighting
        ffxGlow                 = true, -- full screen glow
        ffxDeath                = true, -- death effect
        projectedTextures       = true, -- projected textures
        entityShadows           = true, -- entity shadows
        animateClouds           = true, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Ultra] = {
        farclip                 = 1277, -- view distance
        TerrainMip              = 1, -- terrain detail 
        particleDensity         = 1.0, -- particle density
        environmentDetail       = 1.5, -- environment detail
        groundEffectDensity     = 64, -- clutter density
        groundEffectDist        = 140, -- clutter radius
        extShadowQuality        = 5, -- shadow quality
        BaseMip                 = 1, -- texture resolution
        textureFilteringMode    = 5, -- texture filtering
        weatherDensity          = 3, -- weather intensity
        componentTextureLevel   = 9, -- player texture
        specular                = true, -- specular lighting
        ffxGlow                 = true, -- full screen glow
        ffxDeath                = true, -- death effect
        projectedTextures       = true, -- projected textures
        entityShadows           = true, -- entity shadows
        animateClouds           = true, -- dynamic clouds
    }
}


GraphicsPresets.Raid = {
    [GraphicsPresets.Quality.Low] = {
        farclip_raid                 = 177, -- view distance
        particleDensity_raid         = 0.1, -- particle density
        environmentDetail_raid       = 0.5, -- environment detail
        groundEffectDensity_raid     = 16, -- clutter density
        groundEffectDist_raid        = 70, -- clutter radius
        extShadowQuality_raid        = 0, -- shadow quality
        projectedTextures_raid       = true, -- projected textures
        entityShadows_raid           = false, -- entity shadows
        animateClouds_raid           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Fair] = {
        farclip_raid                 = 507, -- view distance
        particleDensity_raid         = 0.4, -- particle density
        environmentDetail_raid       = 0.75, -- environment detail
        groundEffectDensity_raid     = 24, -- clutter density
        groundEffectDist_raid        = 80, -- clutter radius
        extShadowQuality_raid        = 0, -- shadow quality
        projectedTextures_raid       = true, -- projected textures
        entityShadows_raid           = false, -- entity shadows
        animateClouds_raid           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Good] = {
        farclip_raid                 = 727, -- view distance
        particleDensity_raid         = 0.6, -- particle density
        environmentDetail_raid       = 1.0, -- environment detail
        groundEffectDensity_raid     = 48, -- clutter density
        groundEffectDist_raid        = 120, -- clutter radius
        extShadowQuality_raid        = 1, -- shadow quality
        projectedTextures_raid       = true, -- projected textures
        entityShadows_raid           = false, -- entity shadows
        animateClouds_raid           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.High] = {
        farclip_raid                 = 1057, -- view distance
        particleDensity_raid         = 0.8, -- particle density
        environmentDetail_raid       = 1.25, -- environment detail
        groundEffectDensity_raid     = 56, -- clutter density
        groundEffectDist_raid        = 130, -- clutter radius
        extShadowQuality_raid        = 4, -- shadow quality
        projectedTextures_raid       = true, -- projected textures
        entityShadows_raid           = false, -- entity shadows
        animateClouds_raid           = false, -- dynamic clouds
    },
    [GraphicsPresets.Quality.Ultra] = {
        farclip_raid                 = 1277, -- view distance
        particleDensity_raid         = 1.0, -- particle density
        environmentDetail_raid       = 1.5, -- environment detail
        groundEffectDensity_raid     = 64, -- clutter density
        groundEffectDist_raid        = 140, -- clutter radius
        extShadowQuality_raid        = 5, -- shadow quality
        projectedTextures_raid       = true, -- projected textures
        entityShadows_raid           = true, -- entity shadows
        animateClouds_raid           = true, -- dynamic clouds
    }
}
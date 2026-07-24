local cvarControlMap = {}

Options = {}

Options.Column = {
    Left = 1,
    Center = 2,
    Right = 3,
}

-- Single with will take up a single column, leaving some space on the right for another setting
-- FullSingle will stretch dropdowns and sliders to take up the full width of a single column. 
-- Double with take up the full with of 2 columns
-- Full will take up the full width of all 3 columns
Options.Width = {
    Single = 0,
    FullSingle = 1,
    Double = 2,
    Full = 3,
}

Options.Indent = {
    None = 0,
    Single = 1,
    Double = 2,
}

function Options.CreateCategory(name, parent, label, subText, onCheckButton, onValueChanged)
    local category = CreateFrame("Frame", name , parent, "OptionsPanelTemplate")
    category:SetTitle(label, subText)
    category:SetCheckButtonCallback(onCheckButton)
    category:SetValueChangedCallback(onValueChanged)
    category:Hide()
    return category
end

function Options.SetCVarControl(cvar, control)
    cvarControlMap[cvar] = control
end

function Options.GetControlForCVar(cvar)
    return cvarControlMap[cvar]
end

function VideoSettings_AddCategory(category, okay, cancel, default, refresh)
    if category then
        VideoOptionsPanel_OnLoad(category, okay, cancel, default, refresh)
    end
end

function AudioSettings_AddCategory(category, okay, cancel, default, refresh)
    if category then
        AudioOptionsPanel_OnLoad(category, okay, cancel, default, refresh)
    end
end

if not InGlue() then -- game only
    function InterfaceSettings_AddCategory(category, okay, cancel, default, refresh)
        if category then
            okay = okay or InterfaceOptionsPanel_Okay
            cancel = cancel or InterfaceOptionsPanel_Cancel
            default = default or InterfaceOptionsPanel_Default
            refresh = refresh or InterfaceOptionsPanel_Refresh
            BlizzardOptionsPanel_OnLoad(category, okay, cancel, default, refresh)
            InterfaceOptions_AddCategory(category)
        end
    end
end
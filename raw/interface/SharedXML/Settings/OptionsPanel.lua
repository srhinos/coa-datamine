--
-- An easy way to create a new category in the video, audio, or interface options panel.
-- This is meant to conform to default blizzard options, without being destructive to the original code.
-- 
-- CreateCategory -> AddOption(s) -> AddCategory
--
local COLUMN_WIDTH = 200

OptionsPanelMixin = {}

--
-- Control Types
--
local function AddSlider(panel, name, optionTable)
    local control = CreateFrame("Slider", "$parent"..name, panel, "OptionsSliderTemplate")
    local controlName = control:GetName()
    control.type = CONTROLTYPE_SLIDER
    control.displayPrecision = optionTable.displayPrecision or 0
    control.displayAsPercent = optionTable.displayAsPercent
    control.invert = optionTable.inverted
    control.SetDisplayValue = control.SetValue
    control.valueTextFunc = optionTable.valueTextFunc
    control.SetValue = function(self, value)
        self:SetDisplayValue(value)
        if self.cvar then
            if self.invert then
                local minValue, maxValue = self:GetMinMaxValues()
                BlizzardOptionsPanel_SetCVarSafe(self.cvar, maxValue - value + minValue)
            else
                BlizzardOptionsPanel_SetCVarSafe(self.cvar, value)
            end
        end
    end

    if control.invert then
        control.GetCurrentValue = function(self)
            local value = BlizzardOptionsPanel_GetCVarSafe(self.cvar)
            local min, max = self:GetMinMaxValues()
            return max - value + min
        end
    end

    local low = _G[controlName.."Low"]
    local high = _G[controlName.."High"]
    
    if optionTable.minText then
        low:SetText(optionTable.minText)
    elseif optionTable.minValue then
        low:SetText(optionTable.minValue)
    else
        low:SetText("")
    end
    
    if optionTable.maxText then
        high:SetText(optionTable.maxText)
    elseif optionTable.maxValue then
        high:SetText(optionTable.maxValue)
    else
        high:SetText("")
    end
    
    control:SetScript("OnValueChanged", function(self, value)
        self.newValue = value;
        if optionTable.setValue then
            optionTable.setValue(self, value)
        end
        if self:GetParent().OnValueChanged then
            self:GetParent():OnValueChanged(self)
        end
        if not optionTable.hideValue then
            if optionTable.valueTextFunc then
                _G[self:GetName().."Value"]:SetText(optionTable.valueTextFunc(self, value))
            elseif optionTable.displayAsPercent then
                _G[self:GetName().."Value"]:SetText(MTrunc(value * 100, self.displayPrecision).."%")
            else
                _G[self:GetName().."Value"]:SetText(MTrunc(value, self.displayPrecision))
            end
        else
            _G[self:GetName().."Value"]:SetText("")
        end
    end)
    
    return control
end

local function AddCheckBox(panel, name, optionTable)
    local control = CreateFrame("CheckButton", "$parent"..name, panel, "OptionsSmallDescriptionCheckButtonTemplate")
    control.type = CONTROLTYPE_CHECKBOX
    control.invert = optionTable.inverted
    control:SetScript("OnClick", function(self)
        if self:GetChecked() then
            PlaySound("igMainMenuOptionCheckBoxOn")
        else
            PlaySound("igMainMenuOptionCheckBoxOff")
        end
        self:GetParent():OnCheckButton(self)
    end)

    if optionTable.text then
        control.Text:SetText(_G[optionTable.text] or optionTable.text)
    end

    if optionTable.description then
        control.Description:Show()
        control.Description:SetText(_G[optionTable.description] or optionTable.description)
    else
        control.Description:Hide()
    end

    return control
end

local function AddDropDown(panel, name, optionTable)
    local control = CreateFrame("Frame", "$parent"..name, panel, "OptionUIDropDownMenuTemplate")
    control.type = CONTROLTYPE_DROPDOWN
    control.Label:SetText(_G[optionTable.text] or optionTable.text)

    return control
end
--
-- End Control Types
--

function OptionsPanelMixin:OnLoad()
    self.options = {}
    self.columns = { 82, 82, 82 }
end

function OptionsPanelMixin:SetTitle(label, subText)
    self.Title:SetText(label)
    self.SubText:SetText(subText)
    self.name = label
end

function OptionsPanelMixin:AddButton(name, text, column, width, callback, tooltipTitle, tooltipText)
    local button = CreateFrame("Button", "$parent"..name, self, "StandardButtonTemplate")
    button:SetText(text)
    button:SetHeight(24)
    if width and width > 1 then
        button:SetWidth((COLUMN_WIDTH - 24) + (COLUMN_WIDTH * (width - 1)))
    else
        button:SetWidth(COLUMN_WIDTH - 24)
    end
    button:SetPoint("TOPLEFT", self, "TOPLEFT", 8 + (column - 1) * COLUMN_WIDTH, -self.columns[column])
    button:SetScript("PreClick", function() PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70) end)
    button:SetScript("OnClick", callback)
    button.tooltipTitle = tooltipTitle
    button.tooltipText = tooltipText
    button:SetScript("OnEnter", GameTooltip_GenericTooltip)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:Show()
    self.columns[column] = self.columns[column] + 26
    return button
end

function OptionsPanelMixin:AddOption(name, controlType, column, width, optionTable)
    if optionTable.cvar or optionTable.label then -- some options wont have a cvar
        self.options[optionTable.cvar or optionTable.label] = optionTable
    end

    -- create control
    -- see: Options.Width definition for why they are this way
    local control
    if controlType == "slider" then
        control = AddSlider(self, name, optionTable)
        if width and width > 1 then
            control:SetWidth(140 + (COLUMN_WIDTH * (width - 1)))
        elseif width == 1 then
            control:SetWidth(COLUMN_WIDTH - 24)
        else
            control:SetWidth(140)
        end
    elseif controlType == "checkbox" then
        control = AddCheckBox(self, name, optionTable)
    elseif controlType == "dropdown" then
        control = AddDropDown(self, name, optionTable)
    end


    -- setup values
    control.bitCVar = optionTable.bitCVar
    control.bit = optionTable.bit
    control.cvar = optionTable.cvar
    control.uvar = optionTable.uvar
    control.label = optionTable.label
    control.restart = optionTable.restart
    control.reload = optionTable.reload
    control.setFunc = optionTable.setFunc
    control.GetCurrentValue = optionTable.getCurrentValue or control.GetCurrentValue
    control.onShow = optionTable.onShow
    control.GetValue = optionTable.GetValue or control.GetValue
    control.interruptCheck = optionTable.interruptCheck
    control.interruptUncheck = optionTable.interruptUncheck

    if optionTable.init then
        optionTable.init(control)
        if controlType == "dropdown" and width then
            -- this has to be done here because init will set dropdown width
            if width > 1 then
                UIDropDownMenu_SetWidth(control, 140 + (COLUMN_WIDTH * (width - 1)))
            elseif width == 1 then
                UIDropDownMenu_SetWidth(control, COLUMN_WIDTH - 38)
            else
                UIDropDownMenu_SetWidth(control, 140)
            end
        end
    end
    
    BlizzardOptionsPanel_RegisterControl(control, self)
    
    if optionTable.cvar or optionTable.label then
        Options.SetCVarControl(optionTable.cvar or optionTable.uvar or optionTable.label, control)
    end
    
    -- dependent control
    if optionTable.dependentControl then
        local dependentControl = optionTable.dependentControl
        if type(dependentControl) ~= "table" then
            dependentControl = _G[dependentControl]
        end
        if dependentControl then
            BlizzardOptionsPanel_SetupDependentControl(dependentControl, control)
        end
    end

    -- inverse dependent control
    if optionTable.inverseDependentControl then
        local inverseDependentControl = optionTable.inverseDependentControl
        if type(inverseDependentControl) ~= "table" then
            inverseDependentControl = _G[inverseDependentControl]
        end
        if inverseDependentControl then
            BlizzardOptionsPanel_SetupInverseDependentControl(inverseDependentControl, control)
        end
    end

    -- set position
    local indent = ((optionTable.indentLevel or 0) * 8)
    if controlType == "checkbox" then
        indent = indent + 16
    elseif controlType == "slider" then
        indent = indent + 20
    end
    
    if controlType == "slider" or controlType == "dropdown" and (optionTable.text and optionTable.text:len() > 0) then
        -- sliders & dropdowns have a title and need some extra space above
        self:AddSpace(16, column)
    end
    control:SetPoint("TOPLEFT", self, "TOPLEFT", indent + ((column - 1) * COLUMN_WIDTH), -self.columns[column])
    local height = control:GetHeight()
    if controlType == "dropdown" then
        height = height + 8
    elseif controlType == "slider" then
        height = height + 16 -- extra space for low/high text 
    elseif controlType == "checkbox" and control.Description:IsShown() then
        height = height + control.Description:GetHeight() + 4
    else
        height = height + 4
    end
    
    -- set column next position
    self.columns[column] = self.columns[column] + height
    
    -- if taking up multiple columns, copy next position to other columns
    if width and width > 1 then
        if width == 2 and column < 3 then
            self.columns[column + 1] = self.columns[column]
        elseif width == 3 and column == 1 then
            self.columns[2] = self.columns[1]
            self.columns[3] = self.columns[1]
        else
            C_Logger.Error("Width for control: %s [%s] is too wide for its column.", name, optionTable.cvar)
        end
    end
    
    -- hide windows settings from mac
    if optionTable.windowsOnly and IsMacClient() then
        control:Hide()
    else
        control:Show()
    end
    
    return control
end

function OptionsPanelMixin:AddSpace(height, column)
    if not column then
        for i = 1, 3 do
            self.columns[i] = self.columns[i] + height
        end
    else
        self.columns[column] = self.columns[column] + height
    end
end

function OptionsPanelMixin:AlignColumns()
    local max = 0
    for i = 1, 3 do
        if self.columns[i] > max then
            max = self.columns[i]
        end
    end
    for i = 1, 3 do
        self.columns[i] = max
    end
end

function OptionsPanelMixin:StartGroup(title, column)
    self.pendingOptionsBox = {
        startColumn = column,
        startHeight = self.columns[column],
        title = title,
    }
    self.pendingOptionsBox.point = { "TOPLEFT", self, "TOPLEFT", 8 + ((column - 1) * COLUMN_WIDTH), -self.columns[column] + 4 }
    self.columns[column] = self.columns[column] + 6
end

function OptionsPanelMixin:CloseGroup(column)
    if not self.pendingOptionsBox then return end
    if column < self.pendingOptionsBox.startColumn then return end
    if column > 3 then return end
    if self.columns[column] < self.pendingOptionsBox.startHeight then return end 
    local box = CreateFrame("Frame", nil, self, "OptionsBoxTemplate")
    box:SetBackdropColor(0.15, 0.15, 0.15)
    box:SetPoint(unpack(self.pendingOptionsBox.point))
    box:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 8 + (column * COLUMN_WIDTH), -self.columns[column])
    box.Title:SetText(self.pendingOptionsBox.title)
    
    return box
end

function OptionsPanelMixin:SetValueChangedCallback(callback)
    self.onValueChangedCallback = callback
end

function OptionsPanelMixin:OnValueChanged(slider)
    if self.onValueChangedCallback then
        self.onValueChangedCallback(slider)
    end
end

function OptionsPanelMixin:SetCheckButtonCallback(callback)
    self.onCheckButtonCallback = callback
end

function OptionsPanelMixin:OnCheckButton(button)
    if self.onCheckButtonCallback then
        self.onCheckButtonCallback(button)
    end
end
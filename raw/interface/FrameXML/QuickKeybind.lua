QuickKeybindButtonMixin = {}

function QuickKeybindButtonMixin:GetCommand()
    local buttonType, id = self.buttonType, self:GetID()
    if ( not buttonType ) then
        buttonType = "ACTIONBUTTON";
    else
        if ( buttonType == "MULTICASTACTIONBUTTON" ) then
            id = self.buttonIndex
        end
    end
    
    return buttonType .. id
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnShow()
    EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeEnabled", self.UpdateMouseWheelHandler, self)
    EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", self.UpdateMouseWheelHandler, self)
    
    self:UpdateMouseWheelHandler();
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnHide()
    EventRegistry:UnregisterCallback("QuickKeybindFrame.QuickKeybindModeEnabled", self.UpdateMouseWheelHandler)
    EventRegistry:UnregisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", self.UpdateMouseWheelHandler)
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnClick(button, down)
    if IsQuickKeybinding() then
        if button == "LeftButton" then
            -- Open picker for any button with a valid action slot
            -- (action buttons and multi-bar buttons have self.action set via ActionButton_UpdateAction;
            -- shapeshift/pet buttons do not, so they're naturally excluded)
            if self.action and self.action > 0 and QuickKeybindActionPickerFrame then
                QuickKeybindActionPickerFrame:OpenForButton(self)
                return true
            end
        elseif button ~= "RightButton" then
            QuickKeybindFrame:OnKeyDown(button);
            return true
        end
    end
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnEnter()
    if IsQuickKeybinding() then
        QuickKeybindFrame:SetSelected(self:GetCommand(), self)
        self:QuickKeybindButtonSetTooltip()
        self.oldUpdateScript = self:GetScript("OnUpdate")
        self:SetScript("OnUpdate", self.QuickKeybindButtonOnUpdate)
        self.changedUpdateScript = true
        self.QuickKeybindHighlightTexture:SetAlpha(1)
    end
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnLeave()
    if IsQuickKeybinding() then
        QuickKeybindFrame:SetSelected(nil, nil)
        local idleAlpha = 0.5
        self.QuickKeybindHighlightTexture:SetAlpha(idleAlpha)
    end
    QuickKeybindTooltip:Hide()
    if self.changedUpdateScript then
        self:SetScript("OnUpdate", self.oldUpdateScript)
        self.changedUpdateScript = nil
    end
end

function QuickKeybindButtonMixin:QuickKeybindButtonOnMouseWheel(delta)
    if IsQuickKeybinding() then
        QuickKeybindFrame:OnMouseWheel(delta);
    end
end

function QuickKeybindButtonMixin:QuickKeybindButtonSetTooltip()
    if self:GetCommand() and IsQuickKeybinding() then
        QuickKeybindTooltip:SetOwner(self,	GameTooltip_AutoAnchor(self))
        QuickKeybindTooltip:SetText(self:GetName() or self:GetCommand(), 1, 1, 1)
        local hasBinding = false
        for index, key in ipairs({GetBindingKey(self:GetCommand())}) do
            if key then
                local bindingText = GetBindingText(key, "KEY_")
                if bindingText ~= "" then
                    if not hasBinding then
                        QuickKeybindTooltip:AddDoubleLine(QUICK_KEYBIND_KEY, QUICK_KEYBIND_BINDING, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4)
                        hasBinding = true
                    end
                    QuickKeybindTooltip:AddDoubleLine(key, index,  1, 0.82, 0, 1, 0.82, 0)
                end
            end
        end
        if not hasBinding then
            QuickKeybindTooltip:AddLine(NOT_BOUND, RED_FONT_COLOR:GetRGB())
            QuickKeybindTooltip:AddLine(QUICK_KEYBIND_NO_BINDING_HINT, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        else
            GameTooltip_AddSpacer(QuickKeybindTooltip)
            QuickKeybindTooltip:AddLine(QUICK_KEYBIND_ADDITIONAL_HINT, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        QuickKeybindTooltip:Show()
    end
end

function QuickKeybindButtonMixin:UpdateMouseWheelHandler()
    self:DoModeChange()
    local quickKeybindEnabled = IsQuickKeybinding()
    if quickKeybindEnabled and self:GetScript("OnMouseWheel") == nil then
        if not self:IsMouseWheelEnabled() then
            self:EnableMouseWheel(true)
            self.quickKeybindEnabledMouseWheel = true
        end
        self:SetScript("OnMouseWheel", self.QuickKeybindButtonOnMouseWheel)
    elseif not quickKeybindEnabled and self:GetScript("OnMouseWheel") == self.QuickKeybindButtonOnMouseWheel then
        self:SetScript("OnMouseWheel", nil)
        if self.quickKeybindEnabledMouseWheel then
            self:EnableMouseWheel(false)
            self.quickKeybindEnabledMouseWheel = nil
        end
    end
end

function QuickKeybindButtonMixin:DoModeChange()
    local isBinding = IsQuickKeybinding()
    self.QuickKeybindHighlightTexture:SetShown(isBinding)

    if isBinding then
        local atlas = self.quickKeybindHighlightAtlas or "bags-glow-artifact"
        self.QuickKeybindHighlightTexture:SetAtlas(atlas)
    end
end

QuickKeybindFrameMixin = {};

function QuickKeybindFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self:SetUserPlaced(false)

    self.CancelButton:SetText(CANCEL)
    self.CancelButton:SetScript("OnClick", function(button, buttonName, down)
        self:CancelBinding()
    end)

    self.OkayButton:SetText(OKAY);
    self.OkayButton:SetScript("OnClick", function(button, buttonName, down)
        KeybindListener:Commit()
        HideUIPanel(self)
    end)

    self.DefaultsButton:SetText(RESET_TO_DEFAULT)
    self.DefaultsButton:SetScript("OnClick", function(button, buttonName, down)
        StaticPopup_Show("CONFIRM_RESET_TO_DEFAULT_KEYBINDINGS")
    end)

    self.UseCharacterBindingsButton.Text:SetText(HIGHLIGHT_FONT_COLOR_CODE..CHARACTER_SPECIFIC_KEYBINDINGS..FONT_COLOR_CODE_CLOSE);
    self.UseCharacterBindingsButton:SetScript("OnClick", function(button, buttonName, down)
        if button:GetChecked() then
            -- Save the account settings so that they're correctly copied over to character.
            LoadBindings(1)
            SaveBindings(1)
            -- Load the character bindings.
            LoadBindings(2)
            -- Save the copy of the character settings so that the current binding set is updated.
            SaveBindings(2)
        else
            LoadBindings(1)
            SaveBindings(1)
        end
    end)
    EventRegistry:RegisterCallback("KeybindListener.UnbindFailed", self.OnKeybindUnbindFailed, self)
    EventRegistry:RegisterCallback("KeybindListener.RebindFailed", self.OnKeybindRebindFailed, self)
    EventRegistry:RegisterCallback("KeybindListener.RebindSuccess", self.OnKeybindRebindSuccess, self)
end

function QuickKeybindFrameMixin:OnCharacterBindingsChanged(setting, value)
    self.UseCharacterBindingsButton:SetChecked(value)
end

function QuickKeybindFrameMixin:OnShow()
    -- KEY_BINDING_MODE must be set before firing QuickKeybindModeEnabled, otherwise
    -- listeners that gate on IsQuickKeybinding() (e.g. each action button's wheel/highlight
    -- setup in UpdateMouseWheelHandler) see false and never install themselves.
    local isCharacterSet = GetCurrentBindingSet() == 2
    KEY_BINDING_MODE = isCharacterSet and 2 or 1

    EventRegistry:TriggerEvent("ActionBar.ShowGrid")
    EventRegistry:TriggerEvent("QuickKeybindFrame.QuickKeybindModeEnabled")
    self.escMenuWasShown = EscapeMenu:IsShown()
    HideUIPanel(EscapeMenu)

    self.UseCharacterBindingsButton:SetChecked(isCharacterSet)

    self:ClearOutputText()

    self.mouseOverButton = nil
end

function QuickKeybindFrameMixin:OnHide()
    KEY_BINDING_MODE = nil
    EventRegistry:TriggerEvent("ActionBar.HideGrid")
    EventRegistry:TriggerEvent("QuickKeybindFrame.QuickKeybindModeDisabled")

    if not EscapeMenu:IsShown() and self.escMenuWasShown then
        self.escMenuWasShown = nil
        ShowUIPanel(EscapeMenu)
    end
end

function QuickKeybindFrameMixin:CancelBinding()
    LoadBindings(GetCurrentBindingSet())
    KeybindListener:StopListening()
    HideUIPanel(self)
end

function QuickKeybindFrameMixin:SetSelected(command, actionButton)
    self.mouseOverButton = actionButton

    if command == nil then
        KeybindListener:StopListening()
    else
        local slotIndex = 1
        KeybindListener:StartListening(command, slotIndex)
    end
end

function QuickKeybindFrameMixin:OnKeyDown(input)
    -- Close action picker first if it's open
    if QuickKeybindActionPickerFrame and QuickKeybindActionPickerFrame:IsShown() then
        local gmkey1, gmkey2 = GetBindingKey("TOGGLEGAMEMENU")
        if input == "ESCAPE" or input == gmkey1 or input == gmkey2 then
            QuickKeybindActionPickerFrame:Hide()
            return
        end
    end

    local listening = KeybindListener:IsListening();

    local gmkey1, gmkey2 = GetBindingKey("TOGGLEGAMEMENU");
    if (input == gmkey1 or input == gmkey2) and not listening then
        self:CancelBinding()
    elseif input == "ESCAPE" and listening then
        KeybindListener:ClearActionPrimaryBinding()
    else
        KeybindListener:OnKeyDown(input)
    end

    if self.mouseOverButton then
        self.mouseOverButton:QuickKeybindButtonSetTooltip()

        local slotIndex = 1
        KeybindListener:StartListening(self.mouseOverButton:GetCommand(), slotIndex)
    end
end

function QuickKeybindFrameMixin:OnMouseWheel(delta)
    KeybindListener:OnMouseWheel(delta)

    if self.mouseOverButton then
        self.mouseOverButton:QuickKeybindButtonSetTooltip()
        -- Reselect hovered button
        local slotIndex = 1
        KeybindListener:StartListening(self.mouseOverButton:GetCommand(), slotIndex)
    end
end

function QuickKeybindFrameMixin:SetOutputText(text)
    self.OutputText:SetText(text)
end

function QuickKeybindFrameMixin:ClearOutputText()
    self.OutputText:SetText(nil)
end

function QuickKeybindFrameMixin:OnKeybindUnbindFailed(action, unbindAction)
    self:SetOutputText(KEY_UNBOUND_ERROR:format(GetBindingName(unbindAction)))
end

function QuickKeybindFrameMixin:OnKeybindRebindFailed(action)
    self:SetOutputText(KEYBINDINGFRAME_MOUSEWHEEL_ERROR)
end

function QuickKeybindFrameMixin:OnKeybindRebindSuccess(action)
    self:SetOutputText(KEY_BOUND)
end

function QuickKeybindFrameMixin:OnDragStart()
    self:StartMoving()
end

function QuickKeybindFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end

KeybindListener = CreateFrame("Button");

function KeybindListener:OnKeyDown(key)
    self:ProcessInput(key);
end

function KeybindListener:OnGamePadButtonDown(key)
    self:ProcessInput(key);
end

function KeybindListener:OnClick(key)
end

function KeybindListener:OnMouseWheel(delta)
    self:OnKeyDown(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
end

function KeybindListener:OnForwardMouseWheel(delta)
    if self:IsListening() then
        self:OnMouseWheel(delta)
        return true
    end
    return false
end

function KeybindListener:SetListening(listen)
    if listen then
        self:SetScript("OnKeyDown", self.OnKeyDown)
        self:SetScript("OnClick", self.OnClick)
        self:SetScript("OnMouseWheel", self.OnMouseWheel)
    else
        self:SetScript("OnKeyDown", nil)
        self:SetScript("OnClick", nil)
        self:SetScript("OnMouseWheel", nil)
    end
end

function KeybindListener:StartListening(action, slotIndex)
    self.pending = { action = action, slotIndex = slotIndex }
    self:SetListening(true)

    EventRegistry:TriggerEvent("KeybindListener.StartedListening", action, slotIndex)
end

function KeybindListener:StopListening()
    if not self:IsListening() then
        return
    end

    local oldAction, oldSlotIndex
    if self.pending then
        oldAction = self.pending.action
        oldSlotIndex = self.pending.slotIndex
    end
    self.pending = nil
    self:SetListening(false)

    EventRegistry:TriggerEvent("KeybindListener.StoppedListening", oldAction, oldSlotIndex)
end

function KeybindListener:IsListening()
    return self.pending ~= nil
end

local function ClearBindingsForKeys(...)
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if key then
            SetBinding(key, nil)
        end
    end
end

function KeybindListener:ProcessInput(input)
    local pending = self.pending
    if not pending then
        return false
    end

    local currentAction = GetBindingFromClick(input)
    if currentAction == "SCREENSHOT" then
        RunBinding("SCREENSHOT")
        return false
    end

    local action = pending.action
    if input == "ESCAPE" and currentAction == "TOGGLEGAMEMENU" then
        self:StopListening()
        return false
    end

    local key = GetConvertedKeyOrButton(input)
    if IsKeyPressIgnoredForBinding(key) then
        return false
    end

    self:StopListening()

    -- Unbind the current action
    local slotIndex = pending.slotIndex
    local key1, key2 = GetBindingKey(action)
    ClearBindingsForKeys(key1, key2)

    local newKey = CreateKeyChordStringUsingMetaKeyState(key)
    local unbindUnconflicted, unbindSlotIndex, unbindAction = self:UnbindKey(newKey, action)
    local rebindSuccess = self:RebindKeysInOrder(newKey, slotIndex, action, key1, key2)

    if not unbindUnconflicted then
        EventRegistry:TriggerEvent("KeybindListener.UnbindFailed", action, unbindAction, unbindSlotIndex)
    elseif not rebindSuccess then
        EventRegistry:TriggerEvent("KeybindListener.RebindFailed", action)
    else
        EventRegistry:TriggerEvent("KeybindListener.RebindSuccess", action)
    end

    return true
end

function KeybindListener:UnbindKey(newKey, action)
    local conflicted, conflictedSlotIndex
    local oldAction = GetBindingAction(newKey)
    if oldAction ~= "" and oldAction ~= action then
        local key1, key2 = GetBindingKey(oldAction)
        if key1 == newKey and key2 then
            conflicted = true
            conflictedSlotIndex = 1
        elseif (not key1 or key1 == newKey) and (not key2 or key2 == newKey) then
            conflicted = true
            conflictedSlotIndex = 2
        end
    end
    SetBinding(newKey, nil)

    return not conflicted, conflictedSlotIndex, oldAction
end

function KeybindListener:Commit()
    SaveBindings(GetCurrentBindingSet())
end

function KeybindListener:ClearActionPrimaryBinding()
    if not self:IsListening() then
        return;
    end

    local action = self.pending.action;
    local key1, key2 = GetBindingKey(action)
    if key1 then
        SetBinding(key1, nil)
    end

    if key2 then
        SetBinding(key2, action)
    end
end

function KeybindListener:SetBinding(newKey, action, oldKey)
    local failed
    if not SetBinding(newKey, action) then
        if oldKey then
            SetBinding(oldKey, action)
        end
        failed = true
    end
    return not failed
end

function KeybindListener:RebindKeysInOrder(key, slotIndex, action, ...)
    local failed
    for i = 1, select("#", ...) do
        local currentKey = select(i, ...)
        local keyToBind = (i == slotIndex) and key or currentKey
        if keyToBind then
            if not self:SetBinding(keyToBind, action, currentKey) then
                failed = true
            end
        end
    end
    return not failed
end

function KeybindListener:ResetBindingsToDefault()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    self:StopListening()

    LoadBindings(0)
    SaveBindings(GetCurrentBindingSet())
end
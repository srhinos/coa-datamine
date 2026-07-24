local _, NPE = ...

local StoredPopups = {}

function NPE:GetDialogPopup()
    if not self.Popup then
        self.Popup = CreateFrame("Button", "NPEDialog", UIParent, "NPEDialogPopupTemplate")
    end
    
    return self.Popup
end

function NPE:IsDialogShown(popupKey)
    if self.Popup and self.Popup:IsShown() then
        if popupKey and self.Popup.info then
            if self.Popup.info.key == popupKey or self.Popup.info.text == popupKey then
                return true
            else
                if NPE:GetStoredPopupIndex(popupKey) then
                    return true, true
                end
            end
        else
            return true
        end
    end
    return false
end

function NPE:GetStoredPopupIndex(popupKey)
    for index, popupInfo in ipairs(StoredPopups) do
        if popupInfo.key == popupKey or popupInfo.text == popupKey then
            return index
        end
    end
end

function NPE:ClearDialogPopup(popupKey)
    if self.Popup then
        if popupKey and self.Popup.info then
            if self.Popup.info.key == popupKey or self.Popup.info.text == popupKey then
                self.Popup:Clear()
                self:CheckStoredPopups()
            else
                for i = #StoredPopups, 1, -1 do
                    local popupInfo = StoredPopups[i]
                    if popupInfo.key == popupKey or popupInfo.text == popupKey then
                        tremove(StoredPopups, i)
                    end
                end
            end
        else
            self.Popup:Clear()
            self:CheckStoredPopups()
        end
    end
end

function NPE:CheckStoredPopups()
    local numPopups = #StoredPopups
    if numPopups > 0 then
        local popupInfo = tremove(StoredPopups, numPopups)
        if popupInfo then
            self:ShowDialogPopup(popupInfo)
        end
    end
    -- this always follows a Popup:Clear() so the popup is already hidden.
end

--[[ Popup Dialog Info Table: (all are optional)
key: string [default: nil]
    * a key to identify the dialog, NPE:ClearDialogPopup will look for this first, then check by `text`
text: string
textPosition: string [default: "CENTER"] -- "CENTER", "TOP", "BOTTOM"
    * center will be to the right of icons, top or bottom will appear above or below icons and add some extra height to the dialog.
fontSize: number [default: 16]
width: number [default: 320]
height: number [default: 100]
input: input key [nil, RightButton, LeftButton, MoveMouse, WASD, KeyboardMouse]
    * you can also pass a single character for a generic key
inputScale: number [default: 0.4]
    * scale the input hint atlas. This scales using SetSize not SetScale
icon: texture
iconAtlas: texture
iconWidth: number [default: 64]
    * this width is added to the dialog width
iconHeight: number [default: 64]
iconDesaturated: boolean [default: false]
unit: unitToken or creatureID
unitWidth: number [default: 64]
    * this width is added to the dialog width
unitHeight: number [default: 64]
unitAnimation: number [default: -1]
    * if the unit should repeat an animation. -1 means no animation / idle
priority: number [default: 0]
    * higher number means the dialog will overwrite lower number dialogs (permanently) 
hideOnGossip: boolean [default: false]
    * hide the dialog when the gossip (or quest) frame is shown
closeButton: boolean [default: true]
    * show a close button
onClose: function
    * callback if/when the player clicks the close button
okButton: boolean [default: false]
    * show an ok button
onOkButtonClick: function
    * callback if/when the player clicks the ok button
end
offsetY: number [default: -256]
    * shifts window along Y axis
]]--

--[[
-- Example:
dialogTest1 = {
    text = "Position your left hand to use WASD for moving, and your right hand on the mouse, using the mouse buttons to look around.",
    width = 500,
    textPosition = "BOTTOM",
    input = "KeyboardMouse",
}
NPE:ShowDialogPopup(dialogTest1)

dialogTest2 = {
    text = "Talk to Deputy Willem",
    input = "RightButton",
    unit = 823,
}
NPE:ShowDialogPopup(dialogTest2)

dialogTest3 = {
    text = "Kill Wolves",
    textPosition = "TOP",
    unit = 299,
}
NPE:ShowDialogPopup(dialogTest3)
]]--

function NPE:ShowDialogPopup(dialogInfo)
    if NPE:GetStoredPopupIndex(dialogInfo.text) then
        -- we already have a popup with this text. Ignore and warn
        dprint("NPE:ShowDialogPopup:", "Popup already stored with text:", dialogInfo.text)
        return
    end
    local popup = self:GetDialogPopup()
    
    -- if we hide on gossip and its already open then dont bother
    -- might want to hide existing gossip though if this happens? weird behavior? idk
    if dialogInfo.hideOnGossip and (GossipFrame:IsShown() or QuestFrame:IsShown()) then
        table.insert(StoredPopups, dialogInfo)
        return
    end
    
    -- check priority
    local currentPriority = self.Popup.info and self.Popup.info.priority or -1
    local incomingPriority = dialogInfo.priority or 0

    if currentPriority > incomingPriority then
        table.insert(StoredPopups, dialogInfo)
        return
    else
        table.insert(StoredPopups, self.Popup.info)
    end
    
    dialogInfo.priority = incomingPriority
    
    -- clear last popup info
    popup:Clear()
    
    -- set text
    popup.Text:SetText(dialogInfo.text or "")
    popup.Text:SetFontSize(dialogInfo.fontSize or 16)

    
    -- show input hint if any
    popup:ShowInputHint(dialogInfo.input, dialogInfo.inputScale)
    
    local extraWidth = dialogInfo.input and popup.InputHint:GetWidth() or 0
    local extraHeight = dialogInfo.input and math.max(popup.InputHint:GetHeight()-64, 0) or 0
    
    -- show icon or unit portrait
    if dialogInfo.icon then
        popup:SetIconTexture(dialogInfo.icon, dialogInfo.iconWidth, dialogInfo.iconHeight, dialogInfo.iconDesaturated)
        extraWidth = dialogInfo.iconWidth or 64
        extraHeight = (dialogInfo.iconHeight or 64) - 64
    elseif dialogInfo.iconAtlas then
        popup:SetIconAtlas(dialogInfo.iconAtlas, dialogInfo.iconWidth, dialogInfo.iconHeight, dialogInfo.iconDesaturated)
        extraWidth = dialogInfo.iconWidth or 64
        extraHeight = (dialogInfo.iconHeight or 64) - 64
    elseif dialogInfo.unit then
        popup:SetUnitPortrait(dialogInfo.unit, dialogInfo.unitWidth, dialogInfo.unitHeight)
        extraWidth = dialogInfo.unitWidth or 64
        extraHeight = (dialogInfo.unitHeight or 64) - 64
        if dialogInfo.unitAnimation then
            popup:SetUnitSequence(dialogInfo.unitAnimation or -1)
        end
    else
        popup:HideTexture()
        popup:HideModel()
    end
    
    -- show close button
    if dialogInfo.closeButton == false then
        popup.CloseButton:Hide()
    else
        popup.CloseButton:Show()
    end

    -- show ok button
    if dialogInfo.okButton then
        extraHeight = extraHeight + 15
        popup.OkayButton:Show()
    else
        popup.OkayButton:Hide()
    end

    -- update size
    if not dialogInfo.textPosition or dialogInfo.textPosition == "CENTER" then
        popup:SetSize((dialogInfo.width or 320) + extraWidth, (dialogInfo.height or 100) + extraHeight)
    else
        popup:SetSize((dialogInfo.width or 320), (dialogInfo.height or 100) + extraHeight + 40)
    end

    -- show popup

    if dialogInfo.offsetY then
        popup:SetPoint("CENTER", 0, -256+dialogInfo.offsetY)
    else
        popup:SetPoint("CENTER", 0, -256)
    end

    popup.info = dialogInfo
    popup:Show()
    
    popup.AnimIn:Play()
    
    -- if we hide on gossip, listen for gossip being shown
    if dialogInfo.hideOnGossip and (GossipFrame:IsShown() or QuestFrame:IsShown()) then
        popup:SetScript("OnUpdate", function()
            if GossipFrame:IsShown() or QuestFrame:IsShown() then
                popup:Clear()
                self:CheckStoredPopups()
            end
        end)
    end
    return popup
end

function NPE:SetPopupComplete(popupKey, clearRightAfter)
    if self.Popup then
        if popupKey and self.Popup.info then
            if self.Popup.info.key == popupKey or self.Popup.info.text == popupKey then
                self.Popup:SetComplete()

                if clearRightAfter and not(self.Popup.clearRightAfter) then
                    self.Popup.clearRightAfter = true

                    Timer.After(0.5, function()
                        NPE:ClearDialogPopup(popupKey)
                    end)
                end
                return
            end
        end
    end
end

NPEDialogPopupMixin = CreateFromMixins("NineSlicePanelMixin")

function NPEDialogPopupMixin:SetComplete()
    self.AnimIn:Stop()
    self.Model:Hide()
    self.Texture:Hide()
    self.InputHint:Hide()
    self.Text:SetText("")
    self.OkayButton:Hide()
    self:SetScript("OnUpdate", nil)

    self.CompleteTex.AnimIn:Play()
    self.CompleteTexAnim.AnimInOut:Play()
    self.CompleteTex:Show()
    self.CompleteText:Show()

    PlaySound(SOUNDKIT.UI_QUEST_OBJECTIVECOMPLETE_01)
end

function NPEDialogPopupMixin:Clear()
    self.AnimIn:Stop()
    self.Model:Hide()
    self.Texture:Hide()
    self.InputHint:Hide()
    self.Text:SetText("")
    self.CompleteTex.AnimIn:Stop()
    self.CompleteTexAnim.AnimInOut:Stop()
    self.CompleteTex:Hide()
    self.CompleteText:Hide()
    self:SetScript("OnUpdate", nil)
    self.info = nil
    self.clearRightAfter = nil
    self:Hide()
end

function NPEDialogPopupMixin:SetUnitPortrait(unit, sizeX, sizeY)
    self.Texture:Hide()
    if not unit then
        self.Model:Hide()
        self:Layout()
        return
    end

    self.Model:Show()
    self.Model:StopSequence()

    if sizeX and sizeX > 0 and sizeY and sizeY > 0 then
        self.Model:SetSize(sizeX, sizeY)
    else
        self.Model:SetSize(64, 64)
    end

    if type(unit) == "number" then
        self.Model:SetDisplayInfo(unit, function()
            RunNextFrame(function() self.Model:SetCamera(0) end)
        end)
    else
        self.Model:SetUnit(unit)
        self.Model:SetCamera(0)
    end
end

function NPEDialogPopupMixin:SetUnitSequence(animationID)
    if not self.Model:IsShown() then return end
    if animationID == -1 then
        self.Model:StopSequence()
        return
    end
    self.Model:SetSequence(animationID, true)
end

function NPEDialogPopupMixin:SetIconTexture(icon, width, height, isDesaturated)
    self.Model:Hide()
    if not icon then
        self.Texture:Hide()
        self:Layout()
        return
    end
    self.Texture:Show()
    self.Texture:SetTexture(icon)
    self.Texture:SetTexCoord(0, 1, 0, 1)
    if width and width > 0 and height and height > 0 then
        self.Texture:SetSize(width, height)
    else
        self.Texture:SetSize(64, 64)
    end

    self.Texture:SetDesaturated(isDesaturated and true or false)
    self:Layout()
end 

function NPEDialogPopupMixin:SetIconAtlas(atlas, width, height, isDesaturated)
    self.Model:Hide()
    self.Texture:Show()
    if type(width) == "boolean" then
        self.Texture:SetAtlas(atlas, width)
    else
        self.Texture:SetAtlas(atlas)
        if width and width > 0 and height and height > 0 then
            self.Texture:SetSize(width, height)
        else
            self.Texture:SetSize(64, 64)
        end
    end
    
    self.Texture:SetDesaturated(isDesaturated and true or false)
    self:Layout()
end 

function NPEDialogPopupMixin:HideTexture()
    self.Texture:Hide()
    self:Layout()
end 

function NPEDialogPopupMixin:HideModel()
    self.Model:Hide()
    self:Layout()
end

local buttonAtlas = {
    RightButton = { atlas = "newplayertutorial-icon-mouse-rightbutton", scale = 0.4 },
    LeftButton = { atlas = "newplayertutorial-icon-mouse-leftbutton", scale = 0.4, },
    MoveMouse = { atlas = "newplayertutorial-icon-mouse-turn", scale = 0.4, },
    WASD = { atlas = "newplayertutorial-KEYBOARD", scale = 0.8, },
    KeyboardMouse = { atlas = "newplayertutorial-keyboard", scale = 0.4, },
    Generic = { atlas = "newplayertutorial-icon-key", scale = 0.4 },
}
function NPEDialogPopupMixin:ShowInputHint(input, scale)
    local buttonInfo = input and buttonAtlas[input]

    if not buttonInfo and input and strlen(input) == 1 then
        buttonInfo = buttonAtlas.Generic
    end

    if buttonInfo then
        scale = scale or buttonInfo.scale or 1
        self.InputHint:Show()
        self.InputHint:SetAtlas(buttonInfo.atlas, Const.TextureKit.UseAtlasSize)
        local w, h = self.InputHint:GetSize()
        self.InputHint:SetSize(w * scale, h * scale)

        if buttonInfo == buttonAtlas.Generic then
            self.InputText:SetText(input)
        else
            self.InputText:SetText("")
        end
    else
        self.InputHint:Hide()
    end
    self:Layout()
end 

function NPEDialogPopupMixin:OnShow()
    self:Layout()
end 

function NPEDialogPopupMixin:Layout()
    if not self:IsShown() then return end
    local text = self.Text
    local width = self:GetWidth() - 60
    
    local shownElement

    if self.Texture:IsShown() then
        shownElement = self.Texture
    elseif self.Model:IsShown() then
        shownElement = self.Model
    end

    text:ClearAllPoints()
    -- top aligned text
    if self.info and self.info.textPosition == "TOP" then
        -- center shownElement and inputHint if there is one
        if shownElement then
            local xOffset = 0
            if self.InputHint:IsShown() then
                xOffset = ((shownElement:GetWidth() / 2) + (self.InputHint:GetWidth() / 2) + 5) / 2
                self.InputHint:ClearAndSetPoint("LEFT", shownElement, "RIGHT", 10, 0)
            end
            shownElement:ClearAndSetPoint("CENTER", -xOffset, -12)
            text:SetPoint("TOP", 0, -12)
        else
            if self.InputHint:IsShown() then
                self.InputHint:ClearAndSetPoint("CENTER", 0, -12)
                text:SetPoint("TOP", 0, -12)
            else
                text:SetPoint("CENTER", 0, 0)
            end
        end
    -- bottom aligned text
    elseif self.info and self.info.textPosition == "BOTTOM" then
        -- center shownElement and inputHint if there is one
        if shownElement then
            local xOffset = 0
            if self.InputHint:IsShown() then
                xOffset = ((shownElement:GetWidth() / 2) + (self.InputHint:GetWidth() / 2) + 5) / 2
                self.InputHint:ClearAndSetPoint("LEFT", shownElement, "RIGHT", 10, 0)
            end
            shownElement:ClearAndSetPoint("CENTER", -xOffset, 12)
            text:SetPoint("BOTTOM", 0, 12)
        else
            if self.InputHint:IsShown() then
                self.InputHint:ClearAndSetPoint("CENTER", 0, 12)
                text:SetPoint("BOTTOM", 0, 12)
            else
                text:SetPoint("CENTER", 0, 0)
            end
        end
    -- center aligned text
    else
        text:SetPoint("RIGHT", -40, 0)

        if shownElement then
            width = width - (shownElement:GetWidth() / 2) - 10
            shownElement:ClearAndSetPoint("LEFT", 20, 0)
            text:SetPoint("LEFT", shownElement, "RIGHT", 10, 0)
        else
            text:SetPoint("LEFT", 20, 0)
        end

        if self.InputHint:IsShown() then
            width = width - (self.InputHint:GetWidth() / 2) - 10

            if shownElement then
                self.InputHint:ClearAndSetPoint("LEFT", shownElement, "RIGHT", 10, 0)
            else
                self.InputHint:ClearAndSetPoint("LEFT", 20, 0)
            end

            text:SetPoint("LEFT", self.InputHint, "RIGHT", 10, 0)
        end
    end

    self.Text:SetWidth(width)
end 

function NPEDialogPopupMixin:OnSizeChanged()
    RunNextFrame(GenerateClosure(self.Layout, self))
end
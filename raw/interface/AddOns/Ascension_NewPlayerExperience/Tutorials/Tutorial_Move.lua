local _, NPE = ...

local POPUP_DIALOGUE_DEVICES = "POPUP_DIALOGUE_DEVICES"
local POPUP_DIALOGUE_CAMERA = "POPUP_DIALOGUE_CAMERA"
local POPUP_DIALOGUE_KEYBOARD = "POPUP_DIALOGUE_KEYBOARD"

local PopupDevices = {
    key = POPUP_DIALOGUE_DEVICES,
    text = NPE_MOVE_HANDS_POSITION or "Position your hands and click |cffFFFF00Okay|r",
    textPosition = "TOP",
    input = "KeyboardMouse",
    width = 512,
    okButton = true,
    onOkButtonClick = function(self) 
        self:SetComplete() 
        Timer.After(0.5, function() 
            if self.info.onClose then
                self.info.onClose(self)
            end
        end) 
    end,
    priority = NPE.Const.PopupPriority.MAX,
    offsetY = 64,
}

local PopupCamera = {
    key = POPUP_DIALOGUE_CAMERA,
    text = NPE_MOVE_LOOK_AROUND or "|cffFFFF00Look around|r",
    input = "MoveMouse",
    priority = NPE.Const.PopupPriority.MAX,
    closeButton = false,
}

local PopupKeyBoard = {
    key = POPUP_DIALOGUE_KEYBOARD,
    text = NPE_MOVE_WALK_AROUND or "|cffFFFF00Walk around|r",
    input = "WASD",
    priority = NPE.Const.PopupPriority.MAX,
    closeButton = false,
}

local function MoveTutorialStopped()
    NPE:ClearDialogPopup(POPUP_DIALOGUE_DEVICES)
    NPE:ClearDialogPopup(POPUP_DIALOGUE_CAMERA)

    if not NPE:IsTutorialComplete(NPE.Const.Tutorials.MOVE_TUTORIAL) then -- if tutorial is complete keyboard hint will hide itself
        NPE:ClearDialogPopup(POPUP_DIALOGUE_KEYBOARD)
    end
end

-------
-- Move Tutorial
-------
do
    local moveTutorial = NPE:NewTutorial(NPE.Const.Tutorials.MOVE_TUTORIAL)
    -- setting a min max level means this will setup/destroy based on player level
    moveTutorial:SetMinMaxLevel(1, 1)
    -- auto start will start this tutorial when it is setup
    moveTutorial:SetAutoStart(true)

    moveTutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

    moveTutorial:RegisterCallback("TutorialFinished", MoveTutorialStopped)

    local step1 = moveTutorial:AddStep()

    PopupDevices.onClose = function() step1.complete = true end

    step1:SetCompletionCondition(function(self)
        return self.complete
    end)

    step1:RegisterCallback("StepStarted", function()
        NPE:ShowDialogPopup(PopupDevices)
    end)

    local step2 = moveTutorial:AddStep()
    step2:SetCompletionCondition(function(self)
        self.hasMouseLooked = self.hasMouseLooked or IsMouselooking()
        if self.hasMouseLooked then
            self.counter = (self.counter or 0) + 1
            -- 2 seconds after looking around since this is checked every 0.1s
            return self.counter > 10
        end
        
        return false
    end)

    step2:RegisterCallback("StepStarted", function()
        NPE:ClearDialogPopup(POPUP_DIALOGUE_DEVICES)
        NPE:ShowDialogPopup(PopupCamera)
    end)

    local step3 = moveTutorial:AddStep()
    step3:SetCompletionCondition(function(self)
        if self.hasMoved then
            self.counter = (self.counter or 0) + 1
            -- 2 seconds after moving  around since this is checked every 0.1s
            return self.counter > 10
        end
        if not self.position then
            self.position = { GetCurrentPlayerPosition() }
        elseif self.position then
            local x, y, z = GetCurrentPlayerPosition()
            if x ~= self.position[1] or y ~= self.position[2] or z ~= self.position[3] then
                self.hasMoved = true
            end
        end
        
        return false
    end)

    step3:RegisterCallback("StepStarted", function()
        NPE:SetPopupComplete(POPUP_DIALOGUE_CAMERA)

        Timer.After(0.5, function() 
            NPE:ClearDialogPopup(POPUP_DIALOGUE_CAMERA)
            NPE:ShowDialogPopup(PopupKeyBoard)
        end)
    end)

    step3:RegisterCallback("StepFinished", function()
        dprint("keyboard complete")
        NPE:SetPopupComplete(POPUP_DIALOGUE_KEYBOARD)

        Timer.After(0.5, function() 
            NPE:ClearDialogPopup(POPUP_DIALOGUE_KEYBOARD)
        end)
    end)

    NPE:AddTutorial(moveTutorial)
end

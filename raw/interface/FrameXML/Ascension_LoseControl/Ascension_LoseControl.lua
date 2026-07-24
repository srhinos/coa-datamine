AscensionLoseControlMixin = {
    Stack = {},
}

function AscensionLoseControlMixin:OnLoad()
    self:SetUserPlaced(true)
    self:SetFrameLevel(UIParent:GetFrameLevel()+1)
    self:HookEvent("VARIABLES_LOADED")
    self:HookEvent("CVAR_UPDATE")
end

function AscensionLoseControlMixin:VARIABLES_LOADED()
    local scale = C_CVar.GetNumber("lossOfControlScale")
    scale = math.RemapToRange(scale, 0, 1, 0, 0.8)
    self:SetScale(scale)
    if C_CVar.GetBool("showLossOfControl") then
        self:HookEvent("CROWD_CONTROL_ADDED")
        self:HookEvent("CROWD_CONTROL_UPDATED")
        self:HookEvent("CROWD_CONTROL_REMOVED")
    end
end

function AscensionLoseControlMixin:CVAR_UPDATE(event)
    if event == "showLossOfControl" then
        if C_CVar.GetBool("showLossOfControl") then
            self:HookEvent("CROWD_CONTROL_ADDED")
            self:HookEvent("CROWD_CONTROL_UPDATED")
            self:HookEvent("CROWD_CONTROL_REMOVED")
        else
            self:UnhookEvent("CROWD_CONTROL_ADDED")
            self:UnhookEvent("CROWD_CONTROL_UPDATED")
            self:UnhookEvent("CROWD_CONTROL_REMOVED")
            self:Hide()
        end
    end
end

function AscensionLoseControlMixin:IsTypeEnabled(spellId)
    return C_CVar.GetBitfield("lossOfControlMask", CROWD_CONTROL_DATA[spellId].ccType)
end

function AscensionLoseControlMixin:CROWD_CONTROL_ADDED(spellId)
    if not self:IsTypeEnabled(spellId) then
        return
    end

    local name, icon, duration, expirationTime, startTime, priority, displayName, lockoutSchool = C_CrowdControl:GetCrowdControlInfo(spellId)
    self.Stack[spellId] = {
        name = name,
        icon = icon,
        duration = duration,
        expirationTime = expirationTime,
        startTime = startTime,
        priority = priority,
        displayName = displayName,
        lockoutSchool = lockoutSchool
    }
    self:UpdateDisplay()
end

function AscensionLoseControlMixin:CROWD_CONTROL_UPDATED(spellId)
    if not self.Stack[spellId] then return end

    local _, _, duration, expirationTime, startTime, _, _, lockoutSchool = C_CrowdControl:GetCrowdControlInfo(spellId)

    self.Stack[spellId].duration = duration
    self.Stack[spellId].expirationTime = expirationTime
    self.Stack[spellId].lockoutSchool = lockoutSchool
    self.Stack[spellId].startTime = startTime
    self:UpdateDisplay()
end

function AscensionLoseControlMixin:CROWD_CONTROL_REMOVED(spellId)
    if not self.Stack[spellId] then return end

    self.Stack[spellId] = nil
    if self.spellId == spellId then
        self.spellId = nil
    end
    self:UpdateDisplay()
end

function AscensionLoseControlMixin:OnUpdate()
    if self.unlocked and UnitAffectingCombat("player") then
        self:Lock()
        return
    end

    if self.spellId and self.Stack[self.spellId] then
        local data = self.Stack[self.spellId]
        local startTime = data.startTime or 0
        local duration = data.duration or 0
        CooldownFrame_SetTimer(self.Cooldown, startTime, duration, 1)
        self:SetTimeLeft(data.expirationTime - GetTime())
    end
end

function AscensionLoseControlMixin:UpdateDisplay()
    if next(self.Stack) then
        -- find highest priority
        for spellId, data in pairs(self.Stack) do
            if not self.spellId or data.priority > self.Stack[self.spellId].priority then
                self.spellId = spellId
            elseif data.priority == self.Stack[self.spellId].priority and data.expirationTime > self.Stack[self.spellId].expirationTime  then
                self.spellId = spellId
            end
        end

        -- Setup Display
        local data = self.Stack[self.spellId]
        if data.lockoutSchool then
            self.AbilityName:SetFormattedText(data.displayName, SCHOOL_STRING_TABLE[data.lockoutSchool])
        else
            self.AbilityName:SetText(data.displayName)
        end

        self.Icon:SetTexture(data.icon)
        self:SetTimeLeft(data.expirationTime - GetTime())

        local startTime = data.startTime or 0
        local duration = data.duration or 0
        CooldownFrame_SetTimer(self.Cooldown, startTime, duration, 1)

        -- check if we need to show frame
        if not self:IsVisible() then
            self:Show()
            self:PlayAnimation()
            self:SetScript("OnUpdate", self.OnUpdate)
        end
    else
        -- hide frame
        self:SetScript("OnUpdate", nil)
        self.spellId = nil
        self:Hide()
    end
end

function AscensionLoseControlMixin:SetTimeLeft(timeleft)
    if timeleft then
        self.SecondsText:SetShown(timeleft > 0)
        if timeleft > 10 then
            self.SecondsText:SetFormattedText("%d "..SECONDS_PLURAL, timeleft)
        else
            self.SecondsText:SetFormattedText("%.1F "..SECONDS_PLURAL, timeleft)
        end
    else
        self.SecondsText:Hide()
    end
end

function AscensionLoseControlMixin:PlayAnimation()
    self.RedLineTop.Anim:Stop()
    self.RedLineBottom.Anim:Stop()
    self.Icon.Anim:Stop()

    self.RedLineTop.Anim:Play()
    self.RedLineBottom.Anim:Play()
    self.Icon.Anim:Play()
end

function AscensionLoseControlMixin:Unlock()
    self:EnableMouse(true)
    self:EnableMouseWheel(true)
    self:RegisterForDrag("LeftButton")
    self.unlocked = true

    local timer = Timer.NewTimer(5, function()
        self:Lock()
    end)

    self.Stack["UNLOCK"] = {
        name = "UNLOCK",
        icon = "Interface\\ICONS\\Spell_Frost_Stun",
        duration = 5,
        expirationTime = GetTime() + 5,
        startTime = GetTime(),
        priority = 100,
        displayName = DRAG_TO_MOVE_SCROLL_TO_SIZE,
        timer = timer
    }

    self:SetScript("OnDragStart", function(self)
        self:StartMoving()
        local data = self.Stack["UNLOCK"]

        if data.timer then
            data.timer:Cancel()
            data.timer = nil
        end

        data.duration = 0
        data.startTime = 0
        data.expirationTime = 0
        self:UpdateDisplay()
    end)

    self:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local data = self.Stack["UNLOCK"]

        if data.timer then
            data.timer:Cancel()
            data.timer = nil
        end

        local timer = Timer.NewTimer(5, function()
            self:Lock()
        end)

        data.timer = timer

        data.duration = 5
        data.startTime = GetTime()
        data.expirationTime = GetTime() + data.duration
        self:UpdateDisplay()
    end)

    self:SetScript("OnMouseWheel", function(self, value)
        if value ~= 0 then
            local scale = self:GetScale()
            if value > 0 then
                self:SetScale(scale + 0.05)
            elseif value < 0 then
                self:SetScale(scale - 0.05)
            end

            local data = self.Stack["UNLOCK"]

            if data.timer then
                data.timer:Cancel()
                data.timer = nil
            end

            local timer = Timer.NewTimer(5, function()
                self:Lock()
            end)

            data.timer = timer

            data.duration = 5
            data.startTime = GetTime()
            data.expirationTime = GetTime() + data.duration
            self:UpdateDisplay()
        end
    end)

    self:UpdateDisplay()
end

function AscensionLoseControlMixin:Lock()
    self:EnableMouse(false)
    self:EnableMouseWheel(false)
    self:RegisterForDrag()
    self.unlocked = nil

    if self.Stack["UNLOCK"] then
        local data = self.Stack["UNLOCK"]
        if data.timer then
            data.timer:Cancel()
            data.timer = nil
        end
    end

    self.Stack["UNLOCK"] = nil
    if self.spellId == "UNLOCK" then
        self.spellId = nil
    end
    self:SetScript("OnDragStart", nil)
    self:SetScript("OnDragStop", nil)
    self:SetScript("OnMouseWheel", nil)
    self:UpdateDisplay()

    if not UnitAffectingCombat("player") then
        InterfaceOptionsFrame_Show()
    end
end

function AscensionLoseControlMixin:ResetPositionAndSize()
    self:ClearAndSetPoint("CENTER", UIParent, "CENTER", 0, 20)
    local scale = 1
    scale = math.RemapToRange(scale, 0, 1, 0, 0.8)
    self:SetScale(scale)
    C_CVar.Set("lossOfControlScale", "1")
end
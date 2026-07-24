--[[
    HelpPlate["MY_HELP_PLATE"] = {
        MainTip,        = HelpTips[MainTip]
        cvar,           = if CVar is set, check if = to cvarValue or cvarBit is set, if not, open plates on show.
        cvarValue,      = auto show if cvar is != to this
        cvarBit,        = auto show if bit is not set on this cvar
        { -- Each Plate is just a table
            helpTip     = HelpTips[helpTip]
            parent      = Parent Frame
            points = {
                { point, relativeTo, relativePoint, x, y },
                { point, relativeTo, relativePoint },
                { point }
            }
            flyoutPoint = { point, relativePoint, x, y }
        }
    }
]]
HelpPlate = CreateFromMixins("TutorialPopupContainerMixin")

HelpPlate._pool = CreateFramePool("Frame", UIParent, "HelpPlateTemplate", function(_, obj) obj:Reset() end)
HelpPlate._pool.disallowResetIfNew = true
--
-- Main Help Plate Button
--
HelpPlateButtonMixin = {}

function HelpPlateButtonMixin:OnLoad()
    self.HelpPlate  = self:GetAttribute("HelpPlate")
end

function HelpPlateButtonMixin:OnShow()
    if not self.HelpPlate then
        self:Hide()
        return
    end

    local info = HelpPlate[self.HelpPlate]
    if not info then
        self:Hide()
        return
    end

    self.info = info

    local mainTip = HelpTips[info.MainTip]
    if mainTip then
        mainTip.text = mainTip.text or _G["HELP_PLATE_"..info.MainTip]
        mainTip.isFlyout = true
    end

    -- Flash icon if we've never opened it before and tips are enabled
    if C_CVar.GetBool("HelpTipEnabled") then
        if info.cvar ~= nil then
            if info.cvarValue ~= nil then
                if info.cvarValue ~= C_CVar.GetBool(info.cvar) then
                    Timer.After(0.5, function()
                        if self:IsVisible() then
                            UIFrameFlash(self.IGlow, 0.4, 0.8, -1, false, 0.4, 0, 4)
                            UIFrameFlash(self.Glow, 0.4, 0.8, -1, false, 0.4, 0, 4)
                        end
                    end)
                    return
                end
            elseif info.cvarBit ~= nil then
                if not C_CVar.GetBitfield(info.cvar, info.cvarBit) then
                    Timer.After(0.5, function()
                        if self:IsVisible() then
                            UIFrameFlash(self.IGlow, 0.4, 0.8, -1, false, 0.4, 0, 4)
                            UIFrameFlash(self.Glow, 0.4, 0.8, -1, false, 0.4, 0, 4)
                        end
                    end)
                    return
                end
            else
                error("HelpPlate " .. self.HelpPlate .. " has `cvar` set but no cvarValue or cvarBit set")
            end
        end
    end
end

function HelpPlateButtonMixin:OnHide()
    self:SetButtonState("NORMAL", false)
    self:UnlockHighlight()
    self.IGlow:Hide()
    self.Glow:Hide()

    self.IsShowing = false
    if UIFrameIsFlashing(self.IGlow) then
        UIFrameFlashStop(self.IGlow)
        UIFrameFlashStop(self.Glow)
    end
    HelpPlate._pool:ReleaseAll()
end

function HelpPlateButtonMixin:OnEnter()
    if self.HelpPlate and not self.IsShowing then
        HelpTips[HelpPlate[self.HelpPlate].MainTip].parent = self
        HelpTip:Show(HelpPlate[self.HelpPlate].MainTip)
    end
end

function HelpPlateButtonMixin:OnLeave()
    if self.HelpPlate then
        HelpTip:Hide(HelpPlate[self.HelpPlate].MainTip)
    end
end

function HelpPlateButtonMixin:OnClick()
    if self.IsShowing then
        HelpPlate._pool:ReleaseAll()
        self:SetButtonState("NORMAL", false)
        self:UnlockHighlight()
        self.IGlow:Hide()
        self.Glow:Hide()
        self.IsShowing = false
        return
    end

    if self.HelpPlate and not self.IsShowing then
        self:SetButtonState("PUSHED", true)
        self:LockHighlight()

        local plates = HelpPlate[self.HelpPlate]
        -- Setup plates
        for _, plateInfo in ipairs(plates) do
            if type(plateInfo) == "table" then
               local plate = HelpPlate._pool:Acquire()
               plate.button = self
               plate:Setup(plateInfo)
            end
        end

        self.IsShowing = true

        -- Hide main tip
        local mainTip = HelpPlate[self.HelpPlate].MainTip
        HelpTip:Hide(mainTip)

        -- Set CVar so we never auto-popup
        if self.info.cvar then
            if self.info.cvarValue ~= nil then
                C_CVar.Set(self.info.cvar, self.info.cvarValue)
            elseif self.info.cvarBit ~= nil then
                C_CVar.SetBitfield(self.info.cvar, self.info.cvarBit, true)
            end
            if UIFrameIsFlashing(self.IGlow) then
                UIFrameFlashStop(self.IGlow)
                UIFrameFlashStop(self.Glow)
            end
        end

        self.IGlow:Show()
        self.Glow:Show()
    end
end

--
-- Help Plate
--
HelpPlateMixin = {}

function HelpPlateMixin:Setup(plateInfo)
    self.HelpTip = plateInfo.helpTip

    local tip = HelpTips[self.HelpTip]
    tip.parent = self.Flyout
    tip.useParentStrata = true
    tip.text = tip.text or _G["HELP_PLATE_"..self.HelpTip]
    tip.isFlyout = true

    local flyoutPoint = plateInfo.flyoutPoint
    self.Flyout.button = self.button
    self.Flyout:ClearAndSetPoint(flyoutPoint[1], self, flyoutPoint[2], flyoutPoint[3], flyoutPoint[4])
    self.Flyout:Show()

    self:SetParent(plateInfo.parent)

    self:SetFrameStrata("FULLSCREEN_DIALOG")
    self:SetFrameLevel(1)

    for _, point in ipairs(plateInfo.points) do
        self:SetPoint(unpack(point))
    end

    self:Show()
end

function HelpPlateMixin:Reset()
    self.Flyout.button = nil
    self.button = nil
    self.HelpTip = nil
    self:Hide()
end

function HelpPlateMixin:OnEnter()
    if self.HelpTip then
        HelpTip:Show(self.HelpTip)
        self.Flyout.IGlow:Show()
        self.Flyout.Glow:Show()
        self.Flyout.Highlight:Show()
        self.BG:SetTexture(0, 0, 0, 0.3)
    end
end

function HelpPlateMixin:OnLeave()
    if self.HelpTip then
        HelpTip:Hide(self.HelpTip)
        self.Flyout.IGlow:Hide()
        self.Flyout.Glow:Hide()
        self.Flyout.Highlight:Hide()
        self.BG:SetTexture(0, 0, 0, 0.7)
    end
end


--
-- Help Plate Flyouts (the I icon)
--
HelpPlateFlyoutMixin = {}

function HelpPlateFlyoutMixin:OnShow()
    self.AnimStart:Stop()
    local buttonX, buttonY = self.button:GetLeft(), self.button:GetTop()
    local myX, myY = self:GetLeft(), self:GetTop()
    local scale = self:GetEffectiveScale()

    local xOffset = (myX - buttonX) * scale
    local yOffset = (myY - buttonY) * scale

    self.AnimStart.TStart:SetOffset(-xOffset, -yOffset)
    self.AnimStart.TEnd:SetOffset(xOffset, yOffset)
    self.AnimStart:Play()
end

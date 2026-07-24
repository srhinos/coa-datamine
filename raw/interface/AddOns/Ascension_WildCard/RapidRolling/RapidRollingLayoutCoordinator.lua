-- RapidRollingLayoutCoordinator.lua
-- Spatial coordination, parenting, and frame-level management for Rapid Rolling UI.

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

-- Centralized Layout Constants
local LAYOUT_CONSTANTS = {
    FRAME_LEVEL_OFFSET = 5,
    ERROR_FRAME_LEVEL_OFFSET = 40,
    DICE_FRAME_LEVEL_OFFSET = 5,
}

-- Initialize layout and frame levels
function WildCardRapidRollingMixin:CoordinateLayout()
    -- Safe anchoring to parent container
    if not self.initialized then
        if not CharacterAdvancement then
            return
        end
        self.initialized = true
        self:SetParent(CharacterAdvancement)
        self:ClearAllPoints()
        self:SetPoint("CENTER", CharacterAdvancement, "CENTER")
        if CharacterAdvancement.InputBlocker then
            self:SetFrameLevel(CharacterAdvancement.InputBlocker:GetFrameLevel() + LAYOUT_CONSTANTS.FRAME_LEVEL_OFFSET)
        end
    end

    -- Handle nested container strata and levels
    if self.RollingFrame and self.RollingFrame.ErrorFrame then
        self.RollingFrame.ErrorFrame:SetFrameLevel(self:GetFrameLevel() + LAYOUT_CONSTANTS.ERROR_FRAME_LEVEL_OFFSET)
    end
end

-- Safely attach WildCardDice to the Rolling Frame container
function WildCardRapidRollingMixin:AttachDice()
    if self.RollingFrame and self.RollingFrame.DiceFrame then
        WildCardDice:ClearAllPoints()
        WildCardDice:SetRapidRolling(self.RollingFrame.DiceFrame)
        -- Ensure frame level of dice is above the container but below interactive overlays
        WildCardDice:SetFrameLevel(self.RollingFrame.DiceFrame:GetFrameLevel() + LAYOUT_CONSTANTS.DICE_FRAME_LEVEL_OFFSET)
    end
end

-- Safely detach WildCardDice and restore it to stock UI parent
function WildCardRapidRollingMixin:DetachDice()
    WildCardDice:SetNotRapidRolling()
end

-- Walkthrough visual anchoring
function WildCardRapidRollingMixin:TriggerWalkthrough()
    local cdb = self:GetRapidRollingCDB()
    if not cdb or cdb.CompletedWalkthrough then
        return
    end

    if not HelpTip:IsShowingAnyInSystem("RapidRollWalkthrough") then
        HelpTip:Show("TIP_RAPID_ROLL_WALKTHROUGH1")
    end
end

CAGateBaseMixin = {}

function CAGateBaseMixin:OnLoad()
end 

function CAGateBaseMixin:SetGateInfo(gateInfo)
    self.requiredCurrency = gateInfo.requiredCurrency
    self.nodes = gateInfo.nodes
end 

function CAGateBaseMixin:UpdateDisplay(investedCurrency)
    self.investedCurrency = investedCurrency
    if investedCurrency < self.requiredCurrency then
        self:SetLocked()
    else
        self:SetUnlocked()
    end
end

function CAGateBaseMixin:SetPosition(point, relative, relativePoint, x, y)
    self:ClearAndSetPoint(point, relative, relativePoint, x, y)
end

function CAGateBaseMixin:SetLocked()
    self.isLocked = true
end

function CAGateBaseMixin:SetUnlocked()
    self.isLocked = false
end 

function CAGateBaseMixin:IsLocked()
    return self.isLocked
end 

function CAGateBaseMixin:IsUnlocked()
    return not self.isLocked
end 

function CAGateBaseMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 4, -4)
    local remainder = self.requiredCurrency - self.investedCurrency
    local r, g, b = RED_FONT_COLOR:GetRGB()
    GameTooltip:AddLine(TALENT_FRAME_GATE_TOOLTIP_FORMAT:format(remainder), r, g, b, true)
    GameTooltip:Show()
end 

function CAGateBaseMixin:OnLeave()
    GameTooltip:Hide()
end 
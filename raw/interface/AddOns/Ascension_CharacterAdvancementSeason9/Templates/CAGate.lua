CA_GATE_TOOLTIP_FORMAT_LOCAL = "Spend |cffFFFFFF%d|r more Talent Essence in |cffFFFFFFcurrent|r tree to unlock this row"
CA_GATE_TOOLTIP_FORMAT_GLOBAL = "Spend |cffFFFFFF%d|r more Talent Essence points in |cffFFFFFFany|r tree to unlock rows below"
-------------------------------------------------------------------------------
--                                Gate Mixin                                 --
-------------------------------------------------------------------------------
CATalentGateMixin = {}

function CATalentGateMixin:OnLoad()
    self.tooltip = CA_GATE_TOOLTIP_FORMAT_LOCAL
end

function CATalentGateMixin:Init(gateInfo)
    self.gateInfo = gateInfo

    --self.GateText:SetText(gateInfo.requiresTree.."/"..gateInfo.requiresGlobal)
    self.GateText:SetText(gateInfo.requiresTree)
end

function CATalentGateMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_LEFT", 4, -4)
    GameTooltip:AddLine(self.tooltip:format(self.gateInfo.requiresTree, self.gateInfo.requiresGlobal), 1, 0, 0, true)
    GameTooltip:Show()
end

function CATalentGateMixin:OnLeave()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
--                            Global Gate Mixin                              --
-------------------------------------------------------------------------------
CATalentGateGlobalMixin = CreateFromMixins(CATalentGateMixin)

function CATalentGateGlobalMixin:OnLoad()
    self.tooltip = CA_GATE_TOOLTIP_FORMAT_GLOBAL
end

function CATalentGateGlobalMixin:Init(gateInfo)
    self.gateInfo = gateInfo

    self.GateText:SetText(string.format(SPELL_REQUIRED_FORM, gateInfo.requiresGlobal))
end
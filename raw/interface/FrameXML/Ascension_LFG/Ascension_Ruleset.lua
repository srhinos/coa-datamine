RulesetFrameMixin = {
    selected = 0,

    Width = 871,
    Height = 576,
    RulesetStrings = {
        [Enum.Ruleset.HighRiskPvP] = HIGH_RISK_PVP_COLORED,
        [Enum.Ruleset.NoRiskPvP] = NO_RISK_PVP_COLORED,
        [Enum.Ruleset.NoRiskPvE] = NO_RISK_PVE_COLORED,
    },
}
local function OnShowGossip()
    if C_Player:InCombat() then
        return CloseGossip()
    end

    if C_Player:GetLevel() < 15 then
        SendSystemMessage(format(ERR_MUST_BE_LEVEL_D_TO_SELECT_RULESET, PVP_RULESET_CHOICE_LEVEL))
        return CloseGossip()
    end

    AscensionLFGFrame:ShowFrame("AscensionRulesetFrame")
    AscensionRulesetFrame.FromGossip = true
end

local function OnHideGossip()
    AscensionRulesetFrame.FromGossip = false
    HideUIPanel(AscensionLFGFrame)
end

function RulesetFrameMixin:OnLoad()
    C_Hook:Register(self, "PLAYER_ENTERING_WORLD")
    
    local rulesetNPCs = C_Gossip:MakeGroup(75110, 100031, 100030, 499991, 499970, 100032)
    C_Gossip:RedirectNPCs(rulesetNPCs, OnShowGossip, OnHideGossip)
    self.InputBlock:SetFrameLevel(self:GetFrameLevel() + 10)
end

function RulesetFrameMixin:PLAYER_ENTERING_WORLD()
    self:UpdateSelection()
end

function RulesetFrameMixin:UNIT_AURA(unit)
    if unit ~= "player" then return end
    self:UpdateSelection()
end

function RulesetFrameMixin:OnShow()
    C_Hook:Register(self, "UNIT_AURA")
    local parent = self:GetParent():GetParent()
    parent:SetWidth(self.Width)
    parent:SetHeight(self.Height)
    parent.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\warrior_skullbanner")
    parent.TitleText:SetText(PVP_RULESET)
    
    RunNextFrame(function()
        self:UpdateSelection()
    end)
end

function RulesetFrameMixin:OnHide()
    if self.FromGossip then
        CloseGossip()
    end
    self.FromGossip = false
    C_Hook:Unregister(self, "UNIT_AURA")
end

function RulesetFrameMixin:OnUpdate(dt)
    self.time = (self.time or 0) + dt
    if self.time > 1 then
        self:UpdateEnabled()
        self.time = 0
    end
end

function RulesetFrameMixin:UpdateEnabled()
    local cooldown = C_Player:GetRulesetCooldown()
    self.Enabled = cooldown == 0

    self.InputBlock:SetShown(not self.Enabled)

    if not self.Enabled then
        if cooldown <= 900 then
            self.InputBlock:SetText(ERR_CANNOT_CHANGE_RULESET, ITEM_COOLDOWN_TIME:format(SecondsToTime(cooldown, false, true, 2)))
        else
            self.InputBlock:SetText(ERR_CANNOT_CHANGE_RULESET, ERR_RULESET_MUST_BE_IN_CAPITAL_CITY)
        end
    end
end

function RulesetFrameMixin:UpdateSelection(ruleset)
    self.selected = ruleset or C_Player:GetRuleset()

    -- check if we can even change risk here

    self:UpdateEnabled()

    for i = 1, 3 do
        local panel = self["Ruleset"..i]
        local desaturate = false
        if self.selected ~= Enum.Ruleset.None then
            desaturate = i ~= self.selected
        end

        panel:SetDesaturated(desaturate, desaturate or self.selected == Enum.Ruleset.None)
    end
end

function RulesetFrameMixin:SelectRuleset(banner)
    local id = banner:GetID()
    local dialog = StaticPopup_Show("POPUP_SELECT_RULESET", self.RulesetStrings[id], nil, self)
    dialog.ruleset = id
end

RulesetPanelMixin = {}

function RulesetPanelMixin:OnLoad()
    local text = self:GetAttribute("text")
    if not text then return end
    for i = 1, 3 do
        local title = GetRealmSpecificGlobalString(text.."_TITLE"..i, true)
        local line = GetRealmSpecificGlobalString(text.."_TEXT"..i, true)
        self["Info"..i].Title:SetText(title)
        self["Info"..i].Text:SetText(line)
        self["Info"..i].Icon:SetTexture("Interface\\Icons\\"..self:GetAttribute("icon"..i))
    end
end

function RulesetPanelMixin:OnEnter()
    self.Highlight.AnimIn:Stop()
    self.Highlight.AnimOut:Stop()
    self.Highlight:Show()
    self.Highlight.AnimIn:Play()
    if self.desaturated then
        self.Banner.TextDesaturated:Hide()
        self.Banner.Background:SetDesaturated(false)
        self.Banner.Text:Show()

        for i = 1, 3 do
            self["Info"..i].Title:SetVertexColor(NORMAL_FONT_COLOR:GetRGBA())
            self["Info"..i].Icon:SetDesaturated(false)
            self["Info"..i].IconBorder:SetDesaturated(false)
            self["Info"..i].Text:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGBA())
        end
    end
end

function RulesetPanelMixin:OnLeave()
    self.Highlight.AnimIn:Stop()
    self.Highlight.AnimOut:Stop()
    self.Highlight:Show()
    self.Highlight.AnimOut:Play()
    self.Background:SetVertexColor(1, 1, 1)
    self.Highlight:SetVertexColor(1, 1, 1)
    if self.desaturated then
        self.Banner.TextDesaturated:Show()
        self.Banner.Background:SetDesaturated(true)
        self.Banner.Text:Hide()

        for i = 1, 3 do
            self["Info"..i].Title:SetVertexColor(NORMAL_FONT_DESATURATED:GetRGBA())
            self["Info"..i].Icon:SetDesaturated(true)
            self["Info"..i].IconBorder:SetDesaturated(true)
            self["Info"..i].Text:SetVertexColor(DISABLED_FONT_COLOR:GetRGBA())
        end
    end
end

function RulesetPanelMixin:OnMouseDown()
    if self:IsEnabled() == 1 then
        self.Background:SetVertexColor(0.85, 0.85, 0.85)
        self.Highlight:SetVertexColor(0.85, 0.85, 0.85)
        self.Banner:SetPoint("BOTTOM", 0, 46)
    end
end

function RulesetPanelMixin:OnMouseUp()
    self.Background:SetVertexColor(1, 1, 1)
    self.Highlight:SetVertexColor(1, 1, 1)
    self.Banner:SetPoint("BOTTOM", 0, 48)
end

function RulesetPanelMixin:OnClick()
    self:GetParent():SelectRuleset(self)
end

function RulesetPanelMixin:SetDesaturated(desaturate, canInteract)
    self:SetEnabled(canInteract)
    self.desaturated = desaturate
    self.Background:SetDesaturated(desaturate)
    self.Banner.Background:SetDesaturated(desaturate)
    self.Banner.Text:SetShown(not desaturate)
    self.Banner.TextDesaturated:SetShown(desaturate)
    self.Select:SetEnabled(canInteract)

    if self.Select:IsEnabled() == 1 then
        self.Select:SetText(SELECT)
    else
        self.Select:SetText(SELECTED)
    end
    
    local titleColor = desaturate and NORMAL_FONT_DESATURATED or NORMAL_FONT_COLOR
    local color = desaturate and DISABLED_FONT_COLOR or HIGHLIGHT_FONT_COLOR
    for i = 1, 3 do
        self["Info"..i].Title:SetVertexColor(titleColor:GetRGBA())
        self["Info"..i].Icon:SetDesaturated(desaturate)
        self["Info"..i].IconBorder:SetDesaturated(desaturate)
        self["Info"..i].Text:SetVertexColor(color:GetRGBA())
    end
end
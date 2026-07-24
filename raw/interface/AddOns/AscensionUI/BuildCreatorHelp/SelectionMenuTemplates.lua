SelectionFrameMixin = {}

-- TODO: move SelectionFrameMixin:IconTextTemplate to virtual templates, SelectionFrameMixin as well

-- TODO: Fix size of IconTextTemplate
function SelectionFrameMixin:IconTextTemplate(frame)
    frame:SetSize(210, 128)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(32,32)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, 0)
    frame.icon:SetTexture("Interface\\Icons\\vas_guildnamechange")

    frame.BG = frame:CreateTexture(nil, "BORDER")
    frame.BG:SetSize(53,53)
    frame.BG:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
    frame.BG:SetPoint("CENTER", frame.icon, 8.5, -8.5)

    frame.iconHighlight = frame:CreateTexture(nil, "OVERLAY")
    frame.iconHighlight:SetSize(36,36)
    frame.iconHighlight:SetPoint("CENTER", frame.icon)
    frame.iconHighlight:SetTexture("Interface\\BUTTONS\\ButtonHilight-Square")
    frame.iconHighlight:Hide()
    frame.iconHighlight:SetBlendMode("ADD")

    frame.label = frame:CreateFontString(nil)
    frame.label:SetFontObject(SystemFont_Large)
    frame.label:SetPoint("LEFT", frame.icon, "RIGHT", 8, 0)
    frame.label:SetWidth(164)
    frame.label:SetText(SHARE_BUILDS)
    frame.label:SetJustifyH("LEFT")
    frame.label:SetJustifyV("CENTER")
    frame.label:SetShadowOffset(0,0)
    frame.label:SetVertexColor(0.20, 0.1, 0.0, 1)

    frame.text = frame:CreateFontString(nil)
    frame.text:SetFontObject(GameFontNormal)
    frame.text:SetPoint("TOPLEFT", frame.icon, "BOTTOMLEFT", -5, -8)
    frame.text:SetWidth(220)
    frame.text:SetText("")
    frame.text:SetJustifyH("LEFT")
    frame.text:SetJustifyV("TOP")
    frame.text:SetShadowOffset(0,0)
    frame.text:SetVertexColor(0.10, 0.05, 0.0, 1)

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        local hasTooltip = false

        if (self.tooltipTitle) then
            GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1, true)
            hasTooltip = true
        elseif (self.item) then
            GameTooltip:SetHyperlink("item:"..self.item)
            hasTooltip = true
        end

        if (self.tooltipText) then
            GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
            hasTooltip = true
        end

        if (hasTooltip) then
            self.iconHighlight:Show()
        end

        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function(self)
        self.iconHighlight:Hide()
        GameTooltip:Hide()
    end)
end

function SelectionFrameMixin:OnLoad()
    self:SetSize(254, 439)

    self.titleFrame = CreateFrame("FRAME", "$parent.titleFrame", self)
    self.titleFrame:SetSize(self:GetWidth(), 32)
    self.titleFrame:SetPoint("TOP", 0, 0)

    self.titleFrame.BG = self.titleFrame:CreateTexture(nil, "BACKGROUND", nil)
    self.titleFrame.BG:SetPoint("TOP", 0, 24)
    self.titleFrame.BG:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.titleFrame.BG:SetSize(284, 84)
    self.titleFrame.BG:SetTexCoord(0.633789, 0.908203, 0.578125, 0.660156)

    self.titleFrame.text = self.titleFrame:CreateFontString(nil, "OVERLAY")
    self.titleFrame.text:SetFontObject(GameFontHighlightLarge)
    self.titleFrame.text:SetText("Create Build")
    self.titleFrame.text:SetJustifyH("CENTER")
    self.titleFrame.text:SetPoint("CENTER")
    self.titleFrame.text:SetShadowOffset(0,0)
    self.titleFrame.text:SetVertexColor(0, 0, 0, 1)

    self.BG = self:CreateTexture(nil, "BACKGROUND", nil)
    self.BG:SetPoint("CENTER", 0, 0)
    self.BG:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.BG:SetSize(254, 439)
    self.BG:SetTexCoord(0.000976562, 0.249023, 0.148438, 0.577148)

    self.button = CreateFrame("BUTTON", "$parent.okayButton", self, "RedButtonTemplate")
    self.button:SetPoint("BOTTOM", 0, 32)
    self.button:SetSize(185, 44)
    self.button:SetText(OKAY)

    -- option 1:
    self.artBorder = self:CreateTexture(nil, "ARTWORK", nil)
    self.artBorder:SetPoint("TOP", self.titleFrame, "BOTTOM", 0, -16)
    self.artBorder:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.artBorder:SetSize(205, 109)
    self.artBorder:SetTexCoord(0.000976562, 0.201172, 0.612305, 0.71875)

    self.art = self:CreateTexture(nil, "BORDER", nil)
    self.art:SetPoint("TOP", self.titleFrame, "BOTTOM", 0, -24)
    self.art:SetTexture("Interface\\Addons\\AwAddons\\Textures\\Tutorial\\CATut")
    self.art:SetSize(185, 93)

    -- text block
    self.textBlock1 = CreateFrame("FRAME", "$parent.textBlock1", self)
    self:IconTextTemplate(self.textBlock1)
    self.textBlock1:SetPoint("TOP", self.artBorder, "BOTTOM", 0, -8)

    self.textBlock2 = CreateFrame("FRAME", "$parent.textBlock2", self)
    self:IconTextTemplate(self.textBlock2)
    self.textBlock2:SetPoint("TOP", self.textBlock1.text, "BOTTOM", -7.5, -8)
end

local ScreenBlockFrame = CreateFrame("FRAME", "ScreenBlockFrame", nil, nil)
ScreenBlockFrame:SetBackdrop(StaticPopup1:GetBackdrop())
ScreenBlockFrame:SetPoint("CENTER")
local sizex, sizey = UIParent:GetSize()
ScreenBlockFrame:SetSize(sizex+100, sizey+100)
ScreenBlockFrame:EnableMouse(true)
ScreenBlockFrame:EnableKeyboard(true)
ScreenBlockFrame:SetFrameStrata("FULLSCREEN")
ScreenBlockFrame:Hide()

ScreenBlockFrame.childs = {}

function ScreenBlockFrame:ClearChilds()
    for _, v in pairs(self.childs) do
        v:Hide()
    end
end

SelectionMixin = {}

function SelectionMixin:OnLoad()
    self:SetParent(ScreenBlockFrame)
    table.insert(ScreenBlockFrame.childs, self)
    self:SetSize(1108, 615)
    --BuildTutorialFrame:SetSize(608, 615)
    self:SetPoint("CENTER",0, 0)
    --self:SetMovable(true)
    --self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetClampedToScreen(true)
    --self:SetScript("OnDragStart", self.StartMoving)
    --self:SetScript("OnDragStop", self.StopMovingOrSizing)
    self:SetScript("OnShow", function(self)
        self:SetScale(UIParent:GetEffectiveScale())
    end)

    self.titleFrame = CreateFrame("FRAME", "$parent.titleFrame", self, nil)
    self.titleFrame:SetSize(524, 85)
    self.titleFrame:SetPoint("TOP", 0, -32)

    self.titleFrame.L = self.titleFrame:CreateTexture(nil, "BACKGROUND", nil)
    self.titleFrame.L:SetPoint("LEFT", 0, 0)
    self.titleFrame.L:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.titleFrame.L:SetSize(202, 85)
    self.titleFrame.L:SetTexCoord(0.755859, 0.953125, 0.148438, 0.231445)

    self.titleFrame.R = self.titleFrame:CreateTexture(nil, "BACKGROUND", nil)
    self.titleFrame.R:SetPoint("RIGHT", 0, 0)
    self.titleFrame.R:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.titleFrame.R:SetSize(202, 85)
    self.titleFrame.R:SetTexCoord(0.755859, 0.953125, 0.233398, 0.316406)

    self.titleFrame.M = self.titleFrame:CreateTexture(nil, "BACKGROUND", nil)
    self.titleFrame.M:SetPoint("TOPLEFT", self.titleFrame.L, "TOPRIGHT", -64, 0)
    self.titleFrame.M:SetPoint("BOTTOMRIGHT", self.titleFrame.R, "BOTTOMLEFT", 64, 0)
    self.titleFrame.M:SetTexture("Interface\\FrameGeneral\\UIFrameNeutral")
    self.titleFrame.M:SetTexCoord(0, 0.125, 0.0322266, 0.115234)

    self.titleFrame.text = self.titleFrame:CreateFontString(nil, "OVERLAY")
    self.titleFrame.text:SetFontObject(GameFontHighlightLarge)
    self.titleFrame.text:SetText(CHOOSE_OR_CREATE_BUILD)
    self.titleFrame.text:SetJustifyH("CENTER")
    self.titleFrame.text:SetPoint("CENTER")

    self._Show = self.Show

    function self:Show()
        ScreenBlockFrame:ClearChilds()
        ScreenBlockFrame:Show()
        self._Show(self)
    end
end

function SelectionMixin:CreateSelectionFrame(name)
    local frame = CreateFrame("FRAME", "$parent."..name, self)
    MixinAndLoad(frame, SelectionFrameMixin)

    return frame
end
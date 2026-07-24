WarModeMapFrameMixin = {}

local ICONS = {
    ["WARMODE_TOOLTIP_LINE1"] = "Interface\\Icons\\inv_misc_bag_18",
    ["HIGH_RISK_TOOLTIP_LINE1"] = "Interface\\Icons\\inv_misc_bag_18",
    ["HIGH_RISK_TOOLTIP_LINE2"] = "Interface\\Icons\\_WetBag2_Blood3",
    ["HIGH_RISK_TOOLTIP_LINE3"] = "Interface\\Icons\\INV_Ascend_RpgLoot_314",
    ["HIGH_RISK_TOOLTIP_LINE4"] = "Interface\\Icons\\INV_Ascend_RpgLoot_391",
    ["HIGH_RISK_TOOLTIP_LINE5"] = "Interface\\Icons\\_WetBag2_Blood3",
}
local END_GAME_ZONE_COORDINATES = {
    Expansion01 = { -- Outland
        { 0.65, 0.79 }, -- Shadowmoon Valley
        { 0.58, 0.19 }, -- Netherstorm
    },
    Azeroth = { -- Eastern Kingdoms
        { 0.49, 0.70 }, -- Burning Steppes
        { 0.55, 0.32 }, -- Eastern Plaguelands
        { 0.49, 0.33 }, -- Western Plaguelands
        { 0.52, 0.84 }, -- BlastedLands
    },
    Kalimdor = {
        { 0.60, 0.38 }, -- Azshara
        { 0.50, 0.81 }, -- Ungoro Crater
        { 0.43, 0.81 }, -- Silithus
        { 0.58, 0.24 }, -- Winterspring
    },
    Northrend = {
        { 0.24, 0.58 }, -- Borean Tundra
        { 0.76, 0.72 }, -- Howling Fjord
        { 0.51, 0.42 }, -- Crystalsong Forest
        { 0.36, 0.48 }, -- Wintergrasp
        { 0.48, 0.55 }, -- Dragonblight
        { 0.68, 0.41 }, -- Zul'Drak
        { 0.70, 0.55 }, -- Grizzly Hills
        { 0.57, 0.27 }, -- Storm Peaks
        { 0.38, 0.27 }, -- Icecrown
        { 0.48, 0.06 }, -- Hrothgar's Landing
    },
}

function WarModeMapFrameMixin:OnLoad()
    self.Tooltip.Background:SetAtlas("UI-Frame-Neutral-CardParchment", Const.TextureKit.IgnoreAtlasSize)
    self.HighlightPool = CreateTexturePool(self, "OVERLAY")
    self.Lines = CreateFramePool("Frame", self.Tooltip, "WarmodeLineTemplate")
end

function WarModeMapFrameMixin:SetActive(active)
    self.active = active
    if active then
        self.Banner.Text:SetText(END_GAME_PVP)
        self.Banner.Text:SetVertexColor(RED_FONT_COLOR:GetRGBA())
    else
        if C_Player:IsNoRiskPvP() then
            self.Banner.Text:SetText(NO_RISK_PVP)
        else
            self.Banner.Text:SetText(HIGH_RISK_PVP)
        end
        self.Banner.Text:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGBA())
    end
    self:UpdateTooltip()
end

function WarModeMapFrameMixin:UpdateZoneHighlight()
    self.HighlightPool:ReleaseAll()
    local map = GetMapInfo()
    if END_GAME_ZONE_COORDINATES[map] then
        local width = WorldMapButton:GetWidth()
        local height = WorldMapButton:GetHeight()

        for _, coords in ipairs(END_GAME_ZONE_COORDINATES[map]) do
            local _, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = UpdateMapHighlight(unpack(coords))
            if fileName then
                local tex = self.HighlightPool:Acquire()
                tex:SetBlendMode("ADD")
                tex:SetTexCoord(0, texPercentageX, 0, texPercentageY)
                tex:SetTexture("Interface\\WorldMap\\"..fileName.."\\"..fileName.."Highlight")
                local x = textureX * width
                local y = textureY * height
                scrollChildX = scrollChildX * width
                scrollChildY = -scrollChildY * height

                if x > 0 and y > 0 then
                    tex:SetWidth(x)
                    tex:SetHeight(y)
                    tex:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT" , scrollChildX, scrollChildY)

                    tex:SetVertexColor(RED_FONT_COLOR:GetRGBA())
                    tex:Show()
                else
                    self.HighlightPool:Release(tex)
                end
            end
        end
    end
end

function WarModeMapFrameMixin:UpdateTooltip()
    self.Lines:ReleaseAll()

    local i = 1
    
    local line = self.Lines:Acquire()
    line:SetText(WARMODE_TOOLTIP_HEADER)
    line:SetIcon()
    line.layoutIndex = i
    line.topPadding = 10
    line:Show()
    
    i = i + 1
    local lineIndex = 1
    
    local text = _G["WARMODE_TOOLTIP_LINE"..lineIndex]
    while text do
        line = self.Lines:Acquire()
        line:SetText(text)
        line:SetIcon(ICONS["WARMODE_TOOLTIP_LINE"..lineIndex])
        line.layoutIndex = i
        line:Show()
        i = i + 1
        lineIndex = lineIndex + 1
        text = _G["WARMODE_TOOLTIP_LINE"..lineIndex]
    end

    line = self.Lines:Acquire()
    line:SetText(HIGH_RISK_TOOLTIP_HEADER)
    line:SetIcon()
    line.layoutIndex = i
    line.topPadding = 10
    line:Show()
    
    i = i + 1
    lineIndex = 1

    text = _G["HIGH_RISK_TOOLTIP_LINE"..lineIndex]
    while text do
        line = self.Lines:Acquire()
        line:SetText(text)
        line:SetIcon(ICONS["HIGH_RISK_TOOLTIP_LINE"..lineIndex])
        line.layoutIndex = i
        line:Show()
        i = i + 1
        lineIndex = lineIndex + 1
        text = _G["HIGH_RISK_TOOLTIP_LINE"..lineIndex]
    end

    self.Tooltip:MarkDirty()
end

function WarModeMapFrameMixin:ToggleTooltip()
    if self:IsTooltipShown() then
        self.ToggleInfo:SetText(MORE_INFO)
        self.Tooltip:Hide()
        return
    end

    self.ToggleInfo:SetText(LESS_INFO)

    self:UpdateTooltip()

    self.Tooltip:Show()
end

function WarModeMapFrameMixin:IsTooltipShown()
    return self.Tooltip:IsShown()
end

function WarModeMapFrameMixin:HideInfo()
    self:ToggleTooltip(false)
    local isHighRisk = C_PVP:GetMapIsHighRisk(GetMapInfo())
    self:SetActive(isHighRisk)
end
WarModeMapFrameMixin = {}

local ICONS = {
    { -- Tier 1
        [Enum.Expansion.Vanilla] = {
            "Interface\\Icons\\achievement_pvp_g_01", -- Tier Name
            "Interface\\Icons\\inv_misc_bag_10", -- Drop bag items / gear 
            "Interface\\Icons\\inv_helmet_71", -- (dont) drop gear / fel comm 
            "Interface\\Icons\\tainted_twisted_lode", -- collect core mats from events, demon mats from rares
            "Interface\\Icons\\_BathSkull_Blue", -- get bloodforged gear
        },
        [Enum.Expansion.TBC] = {
            "Interface\\Icons\\achievement_pvp_g_01", -- Tier Name
            "Interface\\Icons\\inv_misc_bag_10", -- Drop bag items / gear 
            "Interface\\Icons\\inv_helmet_98", -- (dont) drop gear / fel comm 
            "Interface\\Icons\\twisted_geode", -- high risk materials
            "Interface\\Icons\\_BathSkull_Blue", -- get bloodforged gear
        },
        [Enum.Expansion.WoTLK] = {
            "Interface\\Icons\\achievement_pvp_g_01", -- Tier Name
            "Interface\\Icons\\inv_misc_bag_10", -- Drop bag items / gear 
            "Interface\\Icons\\inv_helmet_98", -- (dont) drop gear / fel comm 
            "Interface\\Icons\\twisted_geode", -- high risk materials
            "Interface\\Icons\\_BathSkull_Blue", -- get bloodforged gear
        }
    },
    { -- Tier 2
        [Enum.Expansion.Vanilla] = {
            "Interface\\Icons\\achievement_pvp_o_02", -- Tier Name
            "Interface\\Icons\\_WetBag_Blood1", -- Drop bag or equipped
            "Interface\\Icons\\inv_custom_demonstears", -- fel comm protects gear
            "Interface\\Icons\\twisted_geode", -- collect core & demon mats from events (more core)
            "Interface\\Icons\\_BathSkull_Blue", -- get bloodforged gear
        },
        [Enum.Expansion.TBC] = {
            "Interface\\Icons\\achievement_pvp_o_02", -- Tier Name
            "Interface\\Icons\\_WetBag_Blood1", -- drpo bag or equipped
            "Interface\\Icons\\inv_custom_demonstears", -- fel comm protects gear
            "Interface\\Icons\\large_dread_geode", -- high risk materials
            "Interface\\Icons\\_BathSkull_Purple", -- get heroic bf gear
        },
        [Enum.Expansion.WoTLK] = {
            "Interface\\Icons\\achievement_pvp_o_02", -- Tier Name
            "Interface\\Icons\\_WetBag_Blood1", -- drpo bag or equipped
            "Interface\\Icons\\inv_custom_demonstears", -- fel comm protects gear
            "Interface\\Icons\\large_dread_geode", -- high risk materials
            "Interface\\Icons\\_BathSkull_Purple", -- get heroic bf gear
        },
    },
    { -- Tier 3
        [Enum.Expansion.Vanilla] = {
            "Interface\\Icons\\achievement_pvp_h_03", -- Tier Name
            "Interface\\Icons\\_WetBag2_Blood3", -- drop bag or equipped
            "Interface\\Icons\\inv_archaeology_ogres_irongob", -- fel comm __doesnt__ protect gear
            "Interface\\Icons\\large_void_geode", -- get core & demon mats from events (more demon)
            "Interface\\Icons\\_BathSkull_Purple", -- get heroic bf gear
        },
        [Enum.Expansion.TBC] = {
            "Interface\\Icons\\achievement_pvp_h_03", -- Tier Name
            "Interface\\Icons\\_WetBag2_Blood3", -- drop bag or equipped
            "Interface\\Icons\\inv_custom_demonstears", -- fel comm protects gear
            "Interface\\Icons\\large_void_geode", -- high risk materials to upgrade
            "Interface\\Icons\\_BathSkull_Red", -- ascended bf gear materials
        },
        [Enum.Expansion.WoTLK] = {
            "Interface\\Icons\\achievement_pvp_h_03", -- Tier Name
            "Interface\\Icons\\_WetBag2_Blood3", -- drop bag or equipped
            "Interface\\Icons\\inv_custom_demonstears", -- fel comm protects gear
            "Interface\\Icons\\large_void_geode", -- high risk materials to upgrade
            "Interface\\Icons\\_BathSkull_Red", -- ascended bf gear materials
        },
    },
}

local END_GAME_ZONE_COORDINATES = {
    Expansion01 = { -- Outland
        { -- Tier 1
            { 0.34, 0.48 }, -- Zangarmarsh
            { 0.32, 0.65 }, -- Nagrand
            { 0.49, 0.73 }, -- Terokkar
        },
        { -- Tier 2
            { 0.39, 0.27 }, -- Blades Edge
            { 0.65, 0.79 }, -- Shadowmoon Valley
            { 0.58, 0.19 }, -- Netherstorm
        },
        {
        }
    },
    Azeroth = { -- Eastern Kingdoms
        { -- Tier 1
            { 0.49, 0.70 } -- Burning Steppes
        },
        { -- Tier 2
            { 0.55, 0.32 }, -- Eastern Plaguelands
            { 0.49, 0.33 } -- Western Plaguelands
        },
    },
    Kalimdor = {
        { -- Tier 1
            { 0.60, 0.38 }, -- Azshara
            { 0.50, 0.81 } -- Azshara
        },
        [3] = { -- Tier 3
            { 0.43, 0.81 }, -- Silithus
            { 0.58, 0.24 } -- Winterspring
        },
    },
    Northrend = {
        { -- Tier 1
            { 0.24, 0.58 }, -- Borean Tundra
            { 0.76, 0.72 }, -- Howling Fjord
            { 0.51, 0.42 }, -- Crystalsong Forest
        },
        { -- Tier 2
            { 0.36, 0.48 }, -- Wintergrasp
            { 0.48, 0.55 }, -- Dragonblight
            { 0.68, 0.41 }, -- Zul'Drak
            { 0.70, 0.55 }, -- Grizzly Hills
        },
        { -- Tier 3
            { 0.57, 0.27 }, -- Storm Peaks
            { 0.38, 0.27 }, -- Icecrown
            { 0.48, 0.06 }, -- Hrothgar's Landing
        }
    },
}

function WarModeMapFrameMixin:OnLoad()
    self.Tooltip.Background:SetAtlas("UI-Frame-Neutral-CardParchment", Const.TextureKit.IgnoreAtlasSize)
    self.HighlightPool = CreateTexturePool(self, "OVERLAY")
    self.Lines = CreateFramePool("Frame", self.Tooltip, "WarmodeLineTemplate")
end

function WarModeMapFrameMixin:SetActive(tierID)
    self:SetTier(tierID)
    if tierID > 0 then
        self:ShowTooltip()
    else
        self:HideTooltip()
    end
end

function WarModeMapFrameMixin:SetTier(tierID)
    if self.Tier and self.Tier > 0 then
        self.Buttons[self.Tier]:UnlockHighlight()
    end

    self.Banner.Text:SetText(_G["HIGH_RISK_TIER_"..tierID])
    self.Banner.Text:SetVertexColor(GetHighRiskTierColor(tierID))

    if tierID ~= 0 then
        self.Buttons[tierID]:LockHighlight()
    end

    self.Tier = tierID
end

function WarModeMapFrameMixin:HighlightTierZones(map, tierID)
    if END_GAME_ZONE_COORDINATES[map] and END_GAME_ZONE_COORDINATES[map][tierID] then
        local width = WorldMapButton:GetWidth()
        local height = WorldMapButton:GetHeight()

        for _, coords in ipairs(END_GAME_ZONE_COORDINATES[map][tierID]) do
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

                    tex:SetVertexColor(GetHighRiskTierColor(tierID))
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

    local tier = self.Tier
    if tier <= 0 then
        tier = 1
    end
    if tier > 0 then
        local expansion = GetMapExpansion()
        local tierString = "TOOLTIP_HIGH_RISK_TIER_"..tier.."_%s_"..expansion

        local icons = ICONS[tier][expansion]

        local line
        for i = 1, 5 do
            local icon = icons[i]

            line = self.Lines:Acquire()
            line.topPadding = 20
            line:SetIcon(icon)
            line:SetText(_G[format(tierString, i)])
            line.layoutIndex = i
            line:Show()
        end
    end

    self.Tooltip:MarkDirty()
end

function WarModeMapFrameMixin:ShowTooltip()
    self.ToggleInfo:SetText(LESS_INFO)
    self:UpdateTooltip()
    self.Tooltip:Show()
end

function WarModeMapFrameMixin:HideTooltip()
    self.ToggleInfo:SetText(MORE_INFO)
    self.Tooltip:Hide()
end

function WarModeMapFrameMixin:ToggleTooltip()
    if self:IsTooltipShown() then
        self:HideTooltip()
        return
    end

    self:ShowTooltip()
end

function WarModeMapFrameMixin:IsTooltipShown()
    return self.Tooltip:IsShown()
end

function WarModeMapFrameMixin:HideInfo()
    if self.MouseoverInfo then return end -- update will hide this if we don't do this
    self:HideTooltip()
    local currentTier = C_PVP:GetMapIsHighRisk(GetMapInfo())
    self:SetTier(currentTier)
    self.HighlightPool:ReleaseAll()
end
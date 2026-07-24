MapPoiPinMixin = {}

function MapPoiPinMixin:SetPOI(data, x, y)
    self.data = data
    if data.OnClickFunction then
        local func, err = loadstring("return function(self, button) " .. data.OnClickFunction .. " end")
        if func then
            self.OnClickFunction = func()
        else
            C_Logger.Error("POI Has OnClickFunction but it is invalid: %s", err)
        end
    end

    local width, height = 16, 16
    if data.TextureID and data.TextureID > 0 then
        self:SetNormalTexture("Interface\\Minimap\\POIIcons")
        self:SetHighlightTexture("Interface\\Minimap\\POIIcons")
        local l, r, t, b = WorldMap_GetPOITextureCoords(data.TextureID)
        self:GetNormalTexture():SetTexCoord(l, r, t, b)
        self:GetHighlightTexture():SetTexCoord(l, r, t, b)
    else
        if self:IsEventActive() then
            local atlas = data.TextureAtlas .. "-active"
            self:SetNormalAtlas(atlas)
            self:SetHighlightAtlas(atlas)
            width, height = AtlasUtil:GetSize(atlas)
        else
            self:SetNormalAtlas(data.TextureAtlas)
            self:SetHighlightAtlas(data.TextureAtlas)
            width, height = AtlasUtil:GetSize(data.TextureAtlas)
        end
    end

    -- check if teleport and we don't know the spell
    if self.data.Type == Enum.POIType.Teleport and self.data.Extra and not IsSpellKnown(self.data.Extra) then
        self:GetNormalTexture():SetDesaturated(true)
    else
        self:GetNormalTexture():SetDesaturated(false)
    end
    
    local scale = data.Scale or 1
    if C_WorldMap.IsOnContinentMap() then
        scale = scale * 0.5
    end
    self:SetSize(width * scale, height * scale)
    self:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, y)
end

function MapPoiPinMixin:IsEventActive()
    if self.data.Type == Enum.POIType.HighRiskEvent then
        if type(self.data.Events) == "table" then
            for _, event in ipairs(self.data.Events) do
                if not GameEventUtil.IsEventActive(event) then
                    return false
                end
            end
            
            return true
        else
            return GameEventUtil.IsEventActive(self.data.Events)
        end
    end
    
    return false
end

function MapPoiPinMixin:Clear()
    self.data = nil
    self.OnClickFunction = nil
end

function MapPoiPinMixin:OnClick(button)
    if not self.data then return end
    if IsControlKeyDown() and C_Realm.IsDevelopment() then
        return DumpNow(self.data)
    end

    if self.data.Type == Enum.POIType.Teleport then
        if IsShiftKeyDown() and self.data.Extra and IsSpellKnown(self.data.Extra) then
            CastSpellByID(self.data.Extra)
            if WorldMapFrame:IsShown() then
                HideUIPanel(WorldMapFrame)
            end
            return
        end
    end

    if self.OnClickFunction then
        return self.OnClickFunction(self, button)
    end

    WorldMapPOI_OnClick(self, button)
end

function MapPoiPinMixin:OnDisable()
    self:GetNormalTexture():SetDesaturated(true)
end

function MapPoiPinMixin:OnEnable()
    self:GetNormalTexture():SetDesaturated(false)
end

function MapPoiPinMixin:HasTooltip()
    return self.data and bit.contains(self.data.Flags, Enum.POIFlags.HasTooltip)
end

function MapPoiPinMixin:OnEnter()
    local description
    if self.data.Type == Enum.POIType.Teleport and self.data.Extra then
        -- teleport show cooldown / click to tele text
        if IsSpellKnown(self.data.Extra) then
            local start, duration = GetSpellCooldown(self.data.Extra)
            if start > 0 and duration > 0 then
                description = RED_FONT_COLOR:WrapText(format(TOOLTIP_POI_USABLE_IN_S, SecondsToTime(start+duration - GetTime())))
            else
                description = ITEM_QUALITY_COLORS[8]:WrapText(TOOLTIP_POI_CLICK_TO_TELEPORT)
            end
        else
            description = RED_FONT_COLOR:WrapText(VANITY_NOT_OWNED)
            description = description .. "|n" .. DISABLED_FONT_COLOR:WrapText(TOOLTIP_POI_CLICK_TO_TELEPORT .. "|n" .. TOOLTIP_POI_PURCHASE_REQUIRED)
        end
    elseif type(self.data.Description) == "function" then
        description = self.data.Description()
    else
        description = self.data.Description
    end

    if self:HasTooltip() then
        WorldMapPOIFrame.allowBlobTooltip = false
        WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
        WorldMapTooltip:AddLine(self.data.Name, 1, 1, 1, false)
        WorldMapTooltip:AddLine(description, nil, nil, nil, true)
        if self:IsEventActive() and not bit.contains(self.data.Flags, Enum.POIFlags.HighRiskGearEvent) then
            WorldMapTooltip:AddLine(EVENT_HR_ACTIVE_EXTRA, nil, nil, nil, true)
        end
        WorldMapTooltip:Show()
    else
        WorldMapFrame.poiHighlight = 1
        if ( self.data.Description and strlen(self.data.Description) > 0 ) then
            WorldMapFrameAreaLabel:SetText(self.data.Name)
            WorldMapFrameAreaDescription:SetText(description)
        else
            WorldMapFrameAreaLabel:SetText(self.data.Name)
            WorldMapFrameAreaDescription:SetText("")
        end
    end
end

function MapPoiPinMixin:OnLeave()
    if WorldMapTooltip:IsOwned(self) then
        WorldMapPOIFrame.allowBlobTooltip = true
        WorldMapTooltip:Hide()
    else
        WorldMapFrame.poiHighlight = nil
        WorldMapFrameAreaLabel:SetText(WorldMapFrame.areaName)
        WorldMapFrameAreaDescription:SetText(WorldMapFrame.honorableCombatText)
    end
end

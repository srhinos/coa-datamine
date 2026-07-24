C_WorldMap = C_WorldMap or {}

local continentAreaIDs = {
    [0] = true, -- Azeroth / Cosmic 
    [14] = true, -- Kalimdor
    [15] = true, -- Eastern Kingdoms
    [467] = true, -- Outland
    [486] = true, -- Northrend
}
local cityAreaIDs = {
    [302] = true, -- Stormwind
    [322] = true, -- Ogrimmar
    [342] = true, -- Ironforge
    [363] = true, -- ThunderBluff
    [382] = true, -- Darnassis
    [383] = true, -- Undercity
    [472] = true, -- TheExodar
    [481] = true, -- SilvermoonCity
    [482] = true, -- ShattrathCity
    [505] = true, -- Dalaran
    [801] = true, -- Stormwind
    [802] = true, -- Ogrimmar
    [2011] = true, -- Glorious Azzar Faire
    [2051] = true, -- MinigamesVerticalAscend
    [2052] = true, -- MinigamesKulTiranAscent
    [2053] = true, -- MinigamesMechagnomicAscent
    [2054] = true, -- MinigamesVolcanicAscent
    [2055] = true, -- MinigamesNagaAscent
    [2056] = true, -- MinigamesZandalariAscent
    [2057] = true, -- MinigamesLegionAscent
    [2058] = true, -- MinigamesDarkIronAscent
    [2059] = true, -- MinigamesEmeraldAscent
    [2060] = true, -- MinigamesTitanicAscent
}

MAP_POI_FILTERS = {}

RegisterForSave("MAP_POI_FILTERS")

-- Everything is wrapped in `if not C_WorldMap.xyz then` to prevent overwriting dll functions if ever added

if not C_WorldMap.GetVisiblePOI then
    function C_WorldMap.GetVisiblePOI()
        local currentMapID = C_WorldMap.GetCurrentMapID()
        
        if currentMapID == nil then
            return {}
        end
    
        return DB_MapPOI.GetPOIsByMapID(currentMapID)
    end 
end

if not C_WorldMap.GetCurrentMapID then
    function C_WorldMap.GetCurrentMapID()
        local currentAreaID = GetCurrentMapAreaID()
        return currentAreaID and C_WorldMap.GetMapIDByAreaID(currentAreaID) or -1
    end
end

local isAlliance

if not C_WorldMap.CanShowPOI then
    function C_WorldMap.CanShowPOI(poi)
        if isAlliance == nil then
            isAlliance = UnitFactionGroup("player") == "Alliance"
        end

        if bit.contains(poi.Flags, Enum.POIFlags.Timed) and poi.Extra then
            if poi.TimeSinceCreated(poi.Extra) then
                RunNextFrame(function()
                    DB_MapPOI.RemovePOI(poi.ID)
                end)
                return false
            end
        end

        if poi.Type ~= Enum.POIType.None and not MAP_POI_FILTERS[poi.Type] then
            return false
        end

        if poi.Type == Enum.POIType.Teleport and MAP_POI_FILTERS["HideUnknownTeleport"] then
            if poi.Extra and not IsSpellKnown(poi.Extra) then
                return false
            end
        end

        if poi.Flags == Enum.POIFlags.None then
            return true
        end

        if bit.contains(poi.Flags, Enum.POIFlags.Disabled) then
            return false
        end

        if bit.contains(poi.Flags, Enum.POIFlags.OnlyInCity) and not C_WorldMap.IsOnCityMap() then
            return false
        end

        if bit.contains(poi.Flags, Enum.POIFlags.HideOnContinent) and C_WorldMap.IsOnContinentMap() then
            return false
        end

        if bit.contains(poi.Flags, Enum.POIFlags.AllianceOnly) and not isAlliance then
            return false
        end

        if bit.contains(poi.Flags, Enum.POIFlags.HordeOnly) and isAlliance then
            return false
        end

        local ruleset
        if bit.contains(poi.Flags, Enum.POIFlags.NoRiskOnly) then
            ruleset = ruleset or C_Player:GetRuleset()
            if ruleset == Enum.Ruleset.HighRiskPvP then
                return false
            end
        end

        if bit.contains(poi.Flags, Enum.POIFlags.HighRiskOnly) then
            ruleset = ruleset or C_Player:GetRuleset()
            if ruleset ~= Enum.Ruleset.HighRiskPvP then
                return false
            end
        end

        if bit.contains(poi.Flags, Enum.POIFlags.HighRiskGearEvent) then
            if not GameEventUtil.IsEventActive(Enum.GameEvent.HighRiskZG) and not GameEventUtil.IsEventActive(Enum.GameEvent.TBCHighRiskMaterials) then
                return false
            end
        end

        if bit.contains(poi.Flags, Enum.POIFlags.EventRequired) then
            if type(poi.Events) == "table" then
                local pass = true
                for _, eventID in ipairs(poi.Events) do
                    if GameEventUtil.IsEventActive(eventID) then
                        pass = false
                        break
                    end
                end
                if not pass then
                    return false
                end
            elseif not GameEventUtil.IsEventActive(poi.Events) then
                return false
            end
        end

        return true
    end
end

if not C_WorldMap.IsOnContinentMap then
    function C_WorldMap.IsOnContinentMap()
        local currentAreaID = GetCurrentMapAreaID()
        return continentAreaIDs[currentAreaID] == true
    end
end

if not C_WorldMap.IsOnCityMap then
    function C_WorldMap.IsOnCityMap()
        local currentAreaID = GetCurrentMapAreaID()
        return cityAreaIDs[currentAreaID] == true
    end
end

if not C_WorldMap.SetPOIFilters then
    function C_WorldMap.SetPOIFilters(filters)
        MAP_POI_FILTERS = filters
        WorldMapFrame_Update()
    end
end

if not C_WorldMap.SetPOIFilter then
    function C_WorldMap.SetPOIFilter(key, value)
        MAP_POI_FILTERS[key] = value
        WorldMapFrame_Update()
    end
end

if not C_WorldMap.GetPOIFilter then
    function C_WorldMap.GetPOIFilter(key)
        return MAP_POI_FILTERS[key]
    end
end

C_Map = C_Map or {}
if not C_Map.GetBestMapForUnit then
    function C_Map.GetBestMapForUnit(unit)
        local playerX, playerY = GetPlayerMapPosition(unit)
        if playerX and playerX > 0 and playerY and playerY > 0 then
            return GetCurrentMapAreaID()
        elseif UnitIsUnit("player", unit) and not WorldMapFrame:IsShown() then
            SetMapToCurrentZone()
            return GetCurrentMapAreaID()
        end
    end
end 

EventRegistry:RegisterFrameEventAndCallback("VARIABLES_LOADED", function()
    for k in pairs(Enum.POIType) do
        if k ~= "None" and MAP_POI_FILTERS[k] == nil then
            MAP_POI_FILTERS[k] = true
        end
    end
end)


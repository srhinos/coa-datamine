DB_MapPOI = {}

local poiByID = {}
local poiByMapID = {}

--[[
ID = string
X = number
Y = number
Z = number
TextureID = number (if -1, TextureAtlas is used)
TextureAtlas = string (if blank, TextureID is used)
Scale = number (defaults to 1)
TextureWidth = number (defaults to 32)
TextureHeight = number (defaults to 32)
OnClickFunction = string (lua function body)
MapID = number
events = table of event ids or single event id
extra = any extra value passed
]]
--]]
function DB_MapPOI.GetPOIsByMapID(mapID)
    return poiByMapID[mapID] or {}
end

function DB_MapPOI.GetPOIByID(id)
    return poiByID[id]
end

function DB_MapPOI.RemovePOIByID(id)
    if poiByID[id] then
        local poi = poiByID[id]
        if poiByMapID[poi.MapID] then
            table.RemoveItem(poiByMapID[poi.MapID], poi)
        end
        poiByID[id] = nil
    end
end

function DB_MapPOI.CreatePOI(id, name, description, x, y, z, type, flags, textureID, scale, onClickFunction, mapID, events, extra)
    local poi = {}
    poi.Name = name
    poi.Description = description
    poi.X = x
    poi.Y = y
    poi.Z = z
    poi.Type = type or Enum.POIType.None
    poi.Flags = flags
    poi.TextureID = tonumber(textureID) or -1
    poi.TextureAtlas = textureID
    poi.Scale = scale
    poi.OnClickFunction = onClickFunction
    poi.MapID = mapID
    poi.ID = id
    poi.Events = events or {}
    poi.Extra = extra
    poi.TimeSinceCreated = TimeSince:Now()
    
    DB_MapPOI.RemovePOIByID(id)
    
    poiByID[id] = poi
    if not poiByMapID[mapID] then
        poiByMapID[mapID] = {}
    end
    table.insert(poiByMapID[mapID], poi)
end

C_Hook:Register(DB_MapPOI, "PLAYER_ENTERING_WORLD")
C_Hook:Register(DB_MapPOI, "AREA_POI_PAYLOAD")

function DB_MapPOI:PLAYER_ENTERING_WORLD()
    for _, json in pairs(GetJsonCacheCategory("AREA_POI_PAYLOAD")) do
        if json ~= "" then
            self:AREA_POI_PAYLOAD(json)
        end
    end
end

function DB_MapPOI:AREA_POI_PAYLOAD(json)
    if not json then return end
    local obj = C_Serialize:FromJSON(json)
    if not obj then return end

    if obj.Apply then
        local mapID =  C_WorldMap.GetMapIDByZoneID(obj.ZoneId)
        if mapID == nil then
            dprint(json, "Failed to get mapID for zoneID", obj.ZoneId)
        end
        local poiType = Enum.POIType.None
        if obj.TextureId == "demoninvasion4" then
            poiType = Enum.POIType.Invasion
        elseif obj.TextureId == "warfront-neutralhero" or obj.TextureId == "warfront-hordehero" then
            poiType = Enum.POIType.WorldBoss
        elseif obj.TextureId == "hotspot-xp" or obj.TextureId == "hotspot-fishing" or obj.TextureId == "hotspot-honor" or obj.TextureId == "hotspot-quest" then
            poiType = Enum.POIType.Hotspot
        elseif obj.TextureId == "miningblob" or obj.TextureId == "herbblob" then
            poiType = Enum.POIType.Event
        end
        DB_MapPOI.CreatePOI(obj.ID, obj.Name, obj.Description, obj.X, obj.Y, obj.Z or 0, poiType, obj.POIFlags, obj.TextureId, obj.Scale, obj.OnClickFunction, mapID, obj.Duration)
    else
        DB_MapPOI.RemovePOIByID(obj.ID)
    end
end
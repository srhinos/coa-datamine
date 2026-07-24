ZoneUtil = {}

function ZoneUtil.IsOnMap(mapID)
    return mapID == select(4, GetCurrentPlayerPosition())
end

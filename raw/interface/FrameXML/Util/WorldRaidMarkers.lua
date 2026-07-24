local SecureMarkerHandler = CreateFrame("Frame")
SecureMarkerHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
SecureMarkerHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

local markers = {
    499595, -- square
    499588, -- triangle
    499592, -- diamond
    499593, -- cross
    499589, -- star
    499594, -- circle
    499591, -- moon
    499590, -- skull
}
local markerNameLookup = {}
for i = 1, #markers do
    markerNameLookup[GetSpellInfo(markers[i])] = i 
end

local removeMarker = 499587
local removeMarkerName = GetSpellInfo(removeMarker)

local activeMarkers = {}

SecureMarkerHandler:SetScript("OnAttributeChanged", function(self, attribute, value)
    if attribute == "place-marker" then
        if value then
            CastSpellByID(markers[value])
        end
    elseif attribute == "clear-markers" then
        CastSpellByID(removeMarker)
    end
end)

SecureMarkerHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        wipe(activeMarkers)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spellName = ...
        if unit ~= "player" then
            return
        end

        local index = markerNameLookup[spellName]
        if not index then
            if spellName == removeMarkerName then
                wipe(activeMarkers)
            end
            return
        end
        
        activeMarkers[index] = true
    end
end)

function SecureMarkerHandler:PlaceMarker(index)
    if not type(index) == "number" then return end
    if index < 1 or index > #markers then return end
    self:SetAttribute("place-marker", index)
end 

function SecureMarkerHandler:ClearMarkers()
    self:SetAttribute("clear-markers")
end

function IsRaidMarkerActive(index)
    return activeMarkers[index]
end

function CanUseWorldRaidMarkers()
    if not C_VanityCollection.IsCollectionItemOwned(499428) then
        return false, "NOT_OWNED"
    end
    
    for _, spellID in ipairs(markers) do
        if not IsSpellKnown(spellID) then
            return false, "NOT_LEARNED"
        end
    end
    
    if not IsSpellKnown(removeMarker) then
        return false, "NOT_LEARNED"
    end
    
    return true
end

function PlaceRaidMarker(index)
    SecureMarkerHandler:PlaceMarker(index)
end

function ClearRaidMarkers()
    SecureMarkerHandler:ClearMarkers()
end

--
-- C_Item
--
-- Item info related functions

C_Item = C_Item or {}

C_Item.lastUsedItem = { time = TimeSince:Now() }

function C_Item:GetCacheTooltip()
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", "C_ItemTooltip", UIParent, "GameTooltipTemplate")
        self.tooltip:Hide()
    end
    
    return self.tooltip
end

local ratingMatch = ITEM_REQ_ARENA_RATING:gsub("%%d", "(%%d*)")
local arenaTeamIDs = {
    [2] = 1, -- 2v2
    [3] = 2, -- 3v3
    [1] = 3, -- 1v1
}
function C_Item:GetMerchantItemRatingRequirement(itemIndex)
    local tooltip = self:GetCacheTooltip()
    tooltip:SetOwner(UIParent,"ANCHOR_NONE")
    tooltip:SetMerchantItem(itemIndex)
    tooltip:Show()
    for i = 1, tooltip:NumLines() do
        local text = _G[tooltip:GetName().."TextLeft"..i] and _G[tooltip:GetName().."TextLeft"..i]:GetText()
        if text and text ~= "" then
            local rating = text:match(ratingMatch)
            local teamSize1, teamSize2 = text:match("(%d)%s?%w%s?%d%D*(%d)%s?%w%d")
            if rating then
                tooltip:Hide()
                if teamSize1 then
                    teamSize1 = arenaTeamIDs[tonumber(teamSize1)]
                end
                if teamSize2 then
                    teamSize2 = arenaTeamIDs[tonumber(teamSize2)]
                end
                return tonumber(rating), teamSize1, teamSize2
            end
        end
    end
    tooltip:Hide()
end

function C_Item:GetSlotItemPower(slot)
    local itemID = GetInventoryItemID("player", slot)
    local name, link, _, ilvl, _, _, _, _, equipLoc = GetItemInfo(itemID)
    if not name then
        return 0, 0, 0
    end

    local pvePower = 0
    local pvpPower = 0

    local allStats = GetItemStats(link)

    if allStats then
        pvePower = pvePower + (allStats["PVE_POWER"] or 0)
        pvpPower = pvpPower + (allStats["PVP_POWER"] or 0)
    end

    if ILVL_INVALID_SLOTS[slot] then
        ilvl = 0
    end

    return pvePower, pvpPower, ilvl
end 

function C_Item:ITEM_USED_PAYLOAD(itemEntry, bag, slot)
    if not itemEntry then return end

    self.lastUsedItem.time:ResetToNow()
    self.lastUsedItem.itemID = itemEntry
end

function C_Item:GetLastUsedItemID()
    return self.lastUsedItem.itemID, self.lastUsedItem.time
end 

function C_Item:GetNameAndID(item)
    if not item or item == "" or item == 0 then return end
    local name, link = GetItemInfo(item)
    if not name then return item end
    
    local id = link:match("item:(%d*)")
    id = id and tonumber(id)
    
    return name, id
end

function C_Item.GetColoredItemName(itemID)
    local item = Item:CreateFromID(itemID)
    if not item then
        return "|cffff0000BAD ITEM ID|r"
    end
    return ITEM_QUALITY_COLORS[item:GetQuality()]:WrapText("[" .. item:GetName() .. "]")
end

C_Hook:Register(C_Item, "ITEM_USED_PAYLOAD")

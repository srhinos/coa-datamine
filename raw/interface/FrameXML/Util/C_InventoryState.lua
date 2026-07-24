-- Tracks Inventory state

-- Events
-- ITEM_UNEQUIPPED: INVSLOT, ItemID -- When an item was removed from a filled equip slot
-- ITEM_EQUIPPED: INVSLOT, NewItemID, OldItemID (or nil) -- When an item is added to an equip slot
-- BAG_ITEM_COUNT_CHANGED: Bag, Slot, ItemID, ItemCount, CountChangedAmount -- When the count of an item in a slot was changed
-- BAG_ITEM_REPLACED: Bag, Slot, OldItemID, OldItemCount, NewItemID, NewItemCount -- When a slot had an item but was replaced with a different item
-- BAG_ITEM_ADDED: Bag, Slot, ItemID, ItemCount -- When a slot previously had no item but now has one
-- BAG_ITEM_REMOVED: Bag, Slot, ItemID, ItemCount -- When a slot previously had an item but no longer has an item
-- NEW_BAG_ITEM_ADDED: Bag, Slot, ItemID, ItemCount -- When a new item from ITEM_PUSH is found (loot / craft)
C_InventoryState = {
    NewItems = {},
    Equipped = {},
    Inventory = {},
    RecentPush = {},
}

function C_InventoryState:ClearAllNewItems()
    wipe(self.NewItems)
end

function C_InventoryState:IsNewItem(bag, slot)
    return self.NewItems[bag] and self.NewItems[bag][slot]
end

function C_InventoryState:RemoveNewItem(bag, slot)
    if self.NewItems[bag] then
        self.NewItems[bag][slot] = nil
    end
end

C_Hook:RegisterBucket(C_InventoryState, "BAG_UPDATE, UNIT_INVENTORY_CHANGED",  0.2, "ItemUpdate")
C_Hook:Register(C_InventoryState, "ITEM_PUSH")
C_Hook:Register(C_InventoryState, "PLAYER_ENTERED_WORLD")

function C_InventoryState:ITEM_PUSH(bag, icon)
    if bag > 19 then
        bag = bag - 19
    end

    self.RecentPush[bag] = self.RecentPush[bag] or {}

    tinsert(self.RecentPush[bag], icon)
end
function C_InventoryState:ItemUpdate()
    if not PLAYER_ENTERED_WORLD then return end
    self:UpdateCurrentItems()
end

function C_InventoryState:PLAYER_ENTERED_WORLD()
    self:UpdateCurrentItems()
end

function C_InventoryState:UpdateCurrentItems()
    -- Iterate Inventory
    for i = 0, 19 do
        local id = GetInventoryItemID("player", i)
        if self.Equipped[i] ~= id then
            if id == nil then
                EventRegistry:TriggerEvent("Inventory.ItemUnequipped", i, self.Equipped[i])
                C_Hook:SendEvent("ITEM_UNEQUIPPED", i, self.Equipped[i])
            else
                EventRegistry:TriggerEvent("Inventory.ItemEquipped", i, id, self.Equipped[i])
                C_Hook:SendEvent("ITEM_EQUIPPED", i, id, self.Equipped[i])
            end
        end
        self.Equipped[i] = id
    end

    -- Iterate Bags
    for bag = 0, NUM_BAG_SLOTS do
        self.Inventory[bag] = self.Inventory[bag] or {}
        for slot = 1, GetContainerNumSlots(bag) do
            local id  = GetContainerItemID(bag, slot)

            local count = id and select(2, GetContainerItemInfo(bag, slot)) or 0
            local slotData = self.Inventory[bag][slot]

            if slotData then
                -- this inventory slot had an item in it
                if slotData.item == id then
                    -- it was the current item, check if count changed
                    if count ~= slotData.count then
                        -- count changed
                        local diff = count - slotData.count
                        if PLAYER_ENTERED_WORLD then
                            EventRegistry:TriggerEvent("Inventory.ItemUpdate", bag, slot, id, count, diff)
                            C_Hook:SendEvent("BAG_ITEM_COUNT_CHANGED", bag, slot, id, count, diff)
                        end
                        slotData.count = count

                        -- Send new bag item added if this was a recently looted item
                        if self.RecentPush[bag] then
                            local icon = GetContainerItemInfo(bag, slot)
                            if tcontains(self.RecentPush[bag], icon) then
                                self.NewItems[bag] = self.NewItems[bag] or {}
                                self.NewItems[bag][slot] = true
                                tremoveItem(self.RecentPush[bag], icon)
                                if #self.RecentPush[bag] == 0 then
                                    self.RecentPush[bag] = nil
                                end

                                if PLAYER_ENTERED_WORLD then
                                    EventRegistry:TriggerEvent("Inventory.NewItemPushed", bag, slot, id, count)
                                    C_Hook:SendEvent("NEW_BAG_ITEM_ADDED", bag, slot, id, count)
                                end
                            end
                        end
                    end
                else
                    -- Slot data doesn't match the current item
                    if id then
                        -- We have an entirely different item
                        if PLAYER_ENTERED_WORLD then
                            EventRegistry:TriggerEvent("Inventory.ItemReplaced", bag, slot, slotData.item, slotData.count, id, count)
                            C_Hook:SendEvent("BAG_ITEM_REPLACED", bag, slot, slotData.item, slotData.count, id, count)
                        end
                        self.Inventory[bag][slot] = { item = id, count = count }
                    else
                        -- We removed the item
                        if PLAYER_ENTERED_WORLD then
                            EventRegistry:TriggerEvent("Inventory.RemovedItem", bag, slot, slotData.item, slotData.count)
                            C_Hook:SendEvent("BAG_ITEM_REMOVED", bag, slot, slotData.item, slotData.count)
                        end
                        self.Inventory[bag][slot] = nil
                    end

                    if self:IsNewItem(bag, slot) then
                        self:RemoveNewItem(bag, slot)
                    end
                end
            else
                -- We had an empty slot
                if id then
                    -- We have a new item added to an empty slot
                    self.Inventory[bag][slot] = { item = id, count = count }
                    if PLAYER_ENTERED_WORLD then
                        EventRegistry:TriggerEvent("Inventory.NewItem", bag, slot, id, count)
                        C_Hook:SendEvent("BAG_ITEM_ADDED", bag, slot, id, count)
                    end

                    if self.RecentPush[bag] then
                        local icon = GetContainerItemInfo(bag, slot)
                        if tcontains(self.RecentPush[bag], icon) then
                            self.NewItems[bag] = self.NewItems[bag] or {}
                            self.NewItems[bag][slot] = true
                            tremoveItem(self.RecentPush[bag], icon)
                            if #self.RecentPush[bag] == 0 then
                                self.RecentPush[bag] = nil
                            end

                            if PLAYER_ENTERED_WORLD then
                                EventRegistry:TriggerEvent("Inventory.NewItemPushed", bag, slot, id, count)
                                C_Hook:SendEvent("NEW_BAG_ITEM_ADDED", bag, slot, id, count)
                            end
                        end
                    end
                else
                    self.Inventory[bag][slot] = nil
                end
            end
        end
    end
end
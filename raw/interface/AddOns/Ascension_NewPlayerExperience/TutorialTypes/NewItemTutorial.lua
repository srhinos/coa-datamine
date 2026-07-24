local _, NPE = ...

NewItemTutorialMixin = CreateFromMixins(NPEEventTutorial)

function NPE:NewItemTutorial(name, ...)
    local tutorial = CreateFromMixins(NewItemTutorialMixin)
    CallbackRegistryMixin.OnLoad(tutorial)
    tutorial:Initialize(name, "Inventory.NewItemPushed", GenerateClosure(tutorial.InitializationCheck, tutorial))
    return tutorial
end

function NewItemTutorialMixin:GetOpenBag()
    if IsAddOnLoaded("AdiBags") then
        local openBag = self:IsAnyBagOpen()
        return openBag and _G["AdiBagsContainer"..openBag] or nil
    else
        return _G["ContainerFrame"..IsAnyBagOpen()]
    end
end

function NewItemTutorialMixin:IsAnyBagOpen()
    if IsAddOnLoaded("AdiBags") then
        local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
        for i, bag in addon:IterateBags() do
            if bag:IsOpen() then
                return i
            end
        end
    else
        return IsAnyBagOpen()
    end
end

function NewItemTutorialMixin:ValidateItems(...)
     -- set up for each
     return false
end

function NewItemTutorialMixin:GetItemAvailableForUse(bag, slot)
    local tooltip = C_Item:GetCacheTooltip()
    tooltip:SetOwner(UIParent,"ANCHOR_NONE")
    tooltip:SetHyperlink(GetContainerItemLink(bag, slot))
    tooltip:Show()

    if tooltip:NumLines() >= 1 then
        for i = 1, tooltip:NumLines() do
            local text = _G[tooltip:GetName().."TextLeft"..i]
            if text and text ~= "" then
                local vertexColor = {_G[tooltip:GetName().."TextLeft"..i]:GetTextColor()}
                if (vertexColor[1] > 0.99) and (vertexColor[2] < 0.15) and (vertexColor[3] < 0.15) then
                    tooltip:Hide()
                    return false
                end
            end
        end
    end

    tooltip:Hide()

    return true
end

function NewItemTutorialMixin:GetValidItemPosition()
    if not self.validItemPosition then
        return false
    end

    return unpack(self.validItemPosition)
end

function NewItemTutorialMixin:InitializationCheck(...)
    local isValid, bag, slot = self:ValidateItems(...)

    if isValid then
        self.validItemPosition = {bag, slot}
        NPE:StartTutorial(self:GetName())
    end
end

function NewItemTutorialMixin:GetBagParent()
    return self:DefineBagByItemPos(self:GetValidItemPosition())
end

function NewItemTutorialMixin:DefineBagByItemPos(bag)
    if not bag then
        return
    end

    if (bag == 0) then
        return "MainMenuBarBackpackButton"
    else
        return "CharacterBag"..(bag-1).."Slot"
    end
end

function NewItemTutorialMixin:DefineParentByItemPos(bag, slot)
    if not bag then 
        return false
    end

    if IsAddOnLoaded("AdiBags") then
        local addon = LibStub('AceAddon-3.0'):GetAddon('AdiBags')
        local pool = addon:GetPool("ItemButton")

        if pool then
            for button in pool:IterateActiveObjects() do
                local iter, data, previous = button:IterateSlots()
                local slotId, buttonBag, buttonSlot, itemId, count = iter(data, previous)
                if (bag == buttonBag) and (buttonSlot == slot) then
                    return button:GetName()
                end
            end
        end
        return false
    end

    if (ContainerFrame1:IsVisible() and (ContainerFrame1:GetID() == bag)) then
        return "ContainerFrame1Item"..(GetContainerNumSlots(bag)-(slot-1))
    elseif (ContainerFrame2:IsVisible() and (ContainerFrame2:GetID() == bag)) then
        return "ContainerFrame2Item"..(GetContainerNumSlots(bag)-(slot-1))
    elseif (ContainerFrame3:IsVisible() and (ContainerFrame3:GetID() == bag)) then
        return "ContainerFrame3Item"..(GetContainerNumSlots(bag)-(slot-1))
    elseif (ContainerFrame4:IsVisible() and (ContainerFrame4:GetID() == bag)) then
        return "ContainerFrame4Item"..(GetContainerNumSlots(bag)-(slot-1))
    elseif (ContainerFrame5:IsVisible() and (ContainerFrame5:GetID() == bag)) then
        return "ContainerFrame5Item"..(GetContainerNumSlots(bag)-(slot-1))
    end

    return false
end

function NewItemTutorialMixin:DefineContainerItemByItemPos()
    return self:DefineParentByItemPos(self:GetValidItemPosition())
end
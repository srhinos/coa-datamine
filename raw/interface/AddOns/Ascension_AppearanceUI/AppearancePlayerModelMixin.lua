AppearancePlayerModelMixin = CreateFromMixins("ModelMixin", "NineSlicePanelMixin")

local VisualSlots = {
    INVSLOT_HEAD,
    INVSLOT_SHOULDER,
    INVSLOT_BACK,
    INVSLOT_CHEST,
    INVSLOT_BODY,
    INVSLOT_TABARD,
    INVSLOT_WRIST,
    INVSLOT_HAND,
    INVSLOT_WAIST,
    INVSLOT_LEGS,
    INVSLOT_FEET,
    INVSLOT_MAINHAND,
    INVSLOT_OFFHAND,
}

local InventoryLayout = {
    { "TOPLEFT", 12, -56, categoryID = 1 },
    { categoryID = 2 },
    { categoryID = 3 },
    { categoryID = 4 },
    { categoryID = 6 },
    { categoryID = 5 },
    { categoryID = 7 },
    { "TOPRIGHT", -12, -128, categoryID = 8 },
    { categoryID = 9 },
    { categoryID = 10 },
    { categoryID = 11 },
    { "BOTTOM", 53, 28, categoryID = 12 },
    { "BOTTOM", -53, 28, categoryID = 13, illusionCategoryID = 15 },
    { "BOTTOM", 0, 28, categoryID = 14, illusionCategoryID = 16 },
}

local SlotLayout = {
    ["APPEARANCE_TYPE_ITEM"] = InventoryLayout,
    ["APPEARANCE_TYPE_ITEM_SET"] = InventoryLayout,
    ["APPEARANCE_TYPE_OUTFIT"] = InventoryLayout,
    ["APPEARANCE_TYPE_ILLUSION"] = InventoryLayout,
    ["APPEARANCE_TYPE_INCARNATION"] = {
        [1] = { "TOPLEFT", 12, -44 },
        [9] = { "TOPRIGHT", -12, -44 },
    },
    ["APPEARANCE_TYPE_SPELL_VISUAL"] = "GRID",
    ["APPEARANCE_TYPE_COSMETIC_PET"] = "GRID",
    ["APPEARANCE_TYPE_COSMETIC"] = "GRID",
    ["APPEARANCE_TYPE_MOUNT"] = "GRID",
    ["APPEARANCE_TYPE_COMPANION"] = "GRID",
    ["APPEARANCE_TYPE_TOY"] = "GRID",
}

local function ResetSlotButton(pool, button)
    button:Hide()
    button:SetScale(1)
    button:ClearAllPoints()
    button:SetFrameLevel(button:GetParent():GetFrameLevel()+1)
end
function AppearancePlayerModelMixin:OnLoad()
    self:SetPosition(0, 0.12, 0)
    ModelMixin.OnLoad(self)
    self:SetEnableDragRotation(true)
    self:SetEnableScrollZoom(true)
    self:SetEnableDragMove(true)
    self:SetDragScale(0.001)
    self:SetMaxPosOffset(0.2, 0.18)
    self:SetMinMaxDistance(-1, 1)
    
    self.ErrorFrame:SetFrameLevel(self:GetFrameLevel()+10)
    
    self:SetUnit("player")
    self:SetCamera(1)
    self.Background:SetAtlas(AppearanceUtil.GetBackgroundAtlas())
    
    self.SlotButtons = CreateFramePool("CheckButton", self, "AppearanceCategorySlotButtonTemplate", ResetSlotButton)
    
    AppearanceUI:RegisterCallback("OnAppearanceTypeSelected", self.SetAppearanceType, self)
    AppearanceUI:RegisterCallback("OnCategorySelected", self.SetCategory, self)
end

function AppearancePlayerModelMixin:OnShow()
    self:RegisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:RegisterEvent("PENDING_APPEARANCE_CHANGED")
    self:RegisterEvent("VIEWABLE_APPEARANCES_RESET")
    self:RegisterEvent("APPEARANCE_OUTFIT_SAVED_RESULT")
    self:Refresh()
end

function AppearancePlayerModelMixin:OnHide()
    self:UnregisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:UnregisterEvent("PENDING_APPEARANCE_CHANGED")
    self:UnregisterEvent("VIEWABLE_APPEARANCES_RESET")
    self:UnregisterEvent("APPEARANCE_OUTFIT_SAVED_RESULT")
end

function AppearancePlayerModelMixin:InternalUndress()
    SetModelApplyComponents(false)
    self:SetUnit("player")
    SetModelApplyComponents(true)
    self:Undress()
end

function AppearancePlayerModelMixin:APPLY_PENDING_APPEARANCE_RESULT(applied, result)
    self:Refresh()
    if applied then
        self.ErrorFrame:Clear()
        self.ErrorFrame:AddMessage(_G[result] or result, GREEN_FONT_COLOR:GetRGB())
    elseif result == "APPLY_APPEARANCES_COSMETIC_PET_APPEARANCE_CONFIRMATION" then
        self.ErrorFrame:Clear()
        StaticPopup_Show("CONFIRM_APPLY_COSMETIC_PET")
    else
        self.ErrorFrame:AddMessage(_G[result] or result, RED_FONT_COLOR:GetRGB())
    end
end

function AppearancePlayerModelMixin:APPEARANCE_OUTFIT_SAVED_RESULT(applied, result)
    self:Refresh()
    if applied then
        self.ErrorFrame:Clear()
        self.ErrorFrame:AddMessage(_G[result] or result, GREEN_FONT_COLOR:GetRGB())
    else
        self.ErrorFrame:AddMessage(_G[result] or result, RED_FONT_COLOR:GetRGB())
    end
end

function AppearancePlayerModelMixin:PENDING_APPEARANCE_CHANGED()
    self:Refresh()
end

function AppearancePlayerModelMixin:VIEWABLE_APPEARANCES_RESET()
    self:Refresh()
end

function AppearancePlayerModelMixin:Dress()
    self:InternalUndress()
    for _, slotID in ipairs(VisualSlots) do
        if slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND then
            if self.IsRanged then
                if slotID == INVSLOT_MAINHAND then
                    local displayID = self:GetSlotDisplayID(INVSLOT_RANGED)
                    if displayID then
                        self:TryOn(displayID)
                    end
                end
            else
                local displayID, illusionID = self:GetSlotDisplayID(slotID), self:GetSlotIllusionDisplayID(slotID)
                if displayID then
                    self:TryOn(format("item:%d:%d", displayID, illusionID or 0), slotID)
                end
            end
        else
            local displayID = self:GetSlotDisplayID(slotID)
            if displayID then
                self:TryOn(displayID)
            end
        end
    end
    
    if self.categoryID > INVSLOT_LAST_EQUIPPED then
        local displayType, displayID, _, _, _, spellVisualID = AppearanceUtil.GetCategoryDisplayInfo(self.categoryID)
        if displayType == "APPEARANCE_DISPLAY_TYPE_ANIMATED_SPELL_VISUAL" or displayType == "APPEARANCE_DISPLAY_TYPE_STATIC_SPELL_VISUAL" then
            self:SetSpellVisual(displayID, spellVisualID or 0)
        end
    end
end

function AppearancePlayerModelMixin:UndressSlot(undressSlotID)
    self:InternalUndress()
    for _, slotID in ipairs(VisualSlots) do
        if slotID ~= undressSlotID then
            if slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND then
                if self.IsRanged then
                    if slotID == INVSLOT_MAINHAND then
                        local displayID = self:GetSlotDisplayID(INVSLOT_RANGED)
                        if displayID then
                            self:TryOn(displayID)
                        end
                    end
                else
                    local displayID, illusionID = self:GetSlotDisplayID(slotID), self:GetSlotIllusionDisplayID(slotID)
                    if displayID then
                        self:TryOn(format("item:%d:%d", displayID, illusionID or 0), slotID)
                    end
                end
            else
                local displayID = self:GetSlotDisplayID(slotID)
                if displayID then
                    self:TryOn(displayID)
                end
            end
        end
    end
end

function AppearancePlayerModelMixin:GetSlotDisplayID(slotID)
    return AppearanceUtil.GetSlotDisplayID(slotID)
end

function AppearancePlayerModelMixin:GetSlotIllusionDisplayID(slotID)
    return AppearanceUtil.GetSlotIllusionDisplayID(slotID)
end

function AppearancePlayerModelMixin:GetCategoryDisplayID(categoryID)
    return AppearanceUtil.GetCategoryDisplayID(categoryID)
end

function AppearancePlayerModelMixin:ShowRanged()
    self.IsRanged = true
    local displayID = self:GetSlotDisplayID(INVSLOT_RANGED)
    if displayID then
        self:TryOn(displayID)
    end
end


function AppearancePlayerModelMixin:ShowMelee()
    self.IsRanged = false
    local displayID, illusionID = self:GetSlotDisplayID(INVSLOT_MAINHAND), self:GetSlotIllusionDisplayID(INVSLOT_MAINHAND)
    if displayID then
        self:TryOn(format("item:%d:%d", displayID, illusionID or 0), INVSLOT_MAINHAND)
    end
    displayID, illusionID = self:GetSlotDisplayID(INVSLOT_OFFHAND), self:GetSlotIllusionDisplayID(INVSLOT_OFFHAND)
    if displayID then
        self:TryOn(format("item:%d:%d", displayID, illusionID or 0), INVSLOT_OFFHAND)
    end
end

function AppearancePlayerModelMixin:SetAppearanceType(appearanceType)
    self.appearanceType = appearanceType
    self:UpdateSlotLayout()
end 

function AppearancePlayerModelMixin:SetCategory(categoryID)
    self.categoryID = categoryID
    local slotID = AppearanceUtil.GetCategorySlotID(categoryID)
    if slotID == INVSLOT_RANGED then
        self:ShowRanged()
    elseif slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND then
        self:ShowMelee()
    end
    self:UpdateSelectedCategory()
end 

function AppearancePlayerModelMixin:UpdateSlotLayout()
    self.SlotButtons:ReleaseAll()
    local layout = SlotLayout[self.appearanceType]
    local categories
    if self.appearanceType == "APPEARANCE_TYPE_OUTFIT" or self.appearanceType == "APPEARANCE_TYPE_ITEM_SET" or self.appearanceType == "APPEARANCE_TYPE_ILLUSION" then
        categories = C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_ITEM")
    else
        categories = C_AppearanceCollection.GetCategoriesForType(self.appearanceType)
    end
    if layout == "GRID" then
        local x, y = 20, 38
        for i, categoryID in ipairs(categories) do
            local button = self.SlotButtons:Acquire()
            button:SetPoint("BOTTOMLEFT", x, y)
            button:SetCategory(categoryID)
            button:Show()
            x = x + 72
            if i % 5 == 0 then
                x = 20
                y = y + 58
            end
        end
    else
        local lastButton
        for i, categoryID in ipairs(categories) do
            local button = self.SlotButtons:Acquire()
            local slotLayout = layout[i]
            local point, x, y
            if slotLayout then
                point, x, y = unpack(slotLayout)
            end
            if point then
                button:SetPoint(point, x, y)
            else
                button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -10)
            end
            lastButton = button
            button:SetCategory(slotLayout and slotLayout.categoryID or categoryID)
            button:Show()
            
            if slotLayout and slotLayout.illusionCategoryID then
                button = self.SlotButtons:Acquire()
                button:SetPoint("CENTER", lastButton, "BOTTOM", 0, -8)
                button:SetCategory(slotLayout.illusionCategoryID)
                button:SetScale(0.5)
                button:SetFrameLevel(lastButton:GetFrameLevel()+5)
                button:Show()
            end
        end
    end
end 

function AppearancePlayerModelMixin:UpdateModel()
    if self.cancelToken then
        self.cancelToken()
    end

    if self.appearanceType == "APPEARANCE_TYPE_ITEM" then
        self:SetUnit("player")
        self:Dress()
    elseif self.appearanceType == "APPEARANCE_TYPE_ITEM_SET" then
        self:SetUnit("player")
        self:Dress()
    elseif self.appearanceType == "APPEARANCE_TYPE_OUTFIT" then
        self:SetUnit("player")
        self:Dress()
    elseif self.appearanceType == "APPEARANCE_TYPE_ILLUSION" then
        self:SetUnit("player")
        self:Dress()
    elseif self.appearanceType == "APPEARANCE_TYPE_INCARNATION" then
        self:SetCreatureDisplay(self:GetCategoryDisplayID(self.categoryID))
    elseif self.appearanceType == "APPEARANCE_TYPE_SPELL_VISUAL" then
        self:SetUnit("player")
        self:Dress()
    elseif self.appearanceType == "APPEARANCE_TYPE_COSMETIC_PET" then
        self:SetCreatureDisplay(self:GetCategoryDisplayID(self.categoryID))
    elseif self.appearanceType == "APPEARANCE_TYPE_COSMETIC" then
        self:SetUnit("player")
        self:Dress()
    end
end

function AppearancePlayerModelMixin:SetCreatureDisplay(creatureID)
    self:SetDisplayInfo(creatureID, function()
        local appearanceID = AppearanceUtil.GetCategoryAppearanceID(self.categoryID)
        local displayItems = C_Appearance.GetCreatureDisplayItems(appearanceID)
        if displayItems and #displayItems > 0 then
            for _, itemID in ipairs(displayItems) do
                self:TryOn(itemID)
            end
        end
    end)
end

function AppearancePlayerModelMixin:UpdateSelectedCategory()
    self:UpdateModel()
    for button in self.SlotButtons:EnumerateActive() do
        button:SetChecked(button.categoryID == self.categoryID)
    end
end

function AppearancePlayerModelMixin:Refresh()
    local hasPending = C_Appearance.HasPendingAppearances()

    local canApply, reason = C_Appearance.CanApplyPendingAppearances()
    local hasInvalid = hasPending and not canApply

    if hasInvalid then
        self.ApplyButton:SetPoint("TOP", -126, -14)
        self.CancelButton:SetPoint("TOP", 126, -14)
    else
        self.ApplyButton:SetPoint("TOP", -64, -14)
        self.CancelButton:SetPoint("TOP", 64, -14)
    end

    self.ApplyButton:SetShown(hasPending)
    self.ApplyButton:SetEnabled(canApply)
    if self.appearanceType == "APPEARANCE_TYPE_COSMETIC_PET" then
        self.ApplyButton:SetText(SUMMON_PET)
    else
        self.ApplyButton:SetText(APPLY)
    end

    self.ApplyError:SetShown(hasInvalid)
    self.ApplyError:SetText(_G[reason] or reason)

    self.ClearInvalidButton:SetShown(hasInvalid)
    self.ClearInvalidButton:SetEnabled(not canApply)
    
    self.CancelButton:SetShown(hasPending)
    self.CancelButton:Enable()
    
    local hasOutfit = C_AppearanceOutfit.GetCurrentOutfitName() ~= nil
    self.SaveOutfitButton:SetShown(not hasPending and not hasOutfit)
    
    self:UpdateModel()
end 
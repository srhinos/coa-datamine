local WARDROBE_MODEL_SETUP = {
    [INVSLOT_HEAD]          = { CHESTSLOT = true,   HANDSSLOT = false,  LEGSSLOT = false,   FEETSLOT = false    },
    [INVSLOT_SHOULDER]      = { CHESTSLOT = true,   HANDSSLOT = false,  LEGSSLOT = false,   FEETSLOT = false    },
    [INVSLOT_BACK]          = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = true,    FEETSLOT = false    },
    [INVSLOT_CHEST]         = { CHESTSLOT = false,  HANDSSLOT = false,  LEGSSLOT = true,    FEETSLOT = true     },
    [INVSLOT_TABARD]        = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = true,    FEETSLOT = false    },
    [INVSLOT_BODY]          = { CHESTSLOT = false,  HANDSSLOT = false,  LEGSSLOT = true,    FEETSLOT = false    },
    [INVSLOT_WRIST]         = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = true,    FEETSLOT = false    },
    [INVSLOT_HAND]          = { CHESTSLOT = true,   HANDSSLOT = false,  LEGSSLOT = true,    FEETSLOT = true     },
    [INVSLOT_WAIST]         = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = true,    FEETSLOT = false    },
    [INVSLOT_LEGS]          = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = false,   FEETSLOT = true     },
    [INVSLOT_FEET]          = { CHESTSLOT = false,  HANDSSLOT = false,  LEGSSLOT = true,    FEETSLOT = false    },
    ["SPELL"]               = { CHESTSLOT = true,   HANDSSLOT = true,   LEGSSLOT = true,    FEETSLOT = true     },
}

local WARDROBE_MODEL_SETUP_GEAR = {
	["CHESTSLOT"] = 135522,
	["LEGSSLOT"]  = 135548,
	["FEETSLOT"]  = 135550,
	["HANDSSLOT"] = 135549,
}

ItemQueryListener:AddCallback({ 135522, 135548, 135550, 135549 }, nop)

AppearanceModelMixin = {}

function AppearanceModelMixin:OnLoad()
    MixinAndLoadScripts(self, "ModelMixin")
    self:SetEnableDragRotation(true)
    SetParentArray(self, "Models")

    self:HookScript("OnMouseUp", function(self)
        if self:IsMouseOver() then
            self:OnClick()
        end
    end)
    local frameLevel = self:GetFrameLevel()
    self.Loading:SetFrameLevel(frameLevel + 10)
    self:SetLight(1, 0, -1, 1, -1, 1.05, 1, 1, 1, 0, 1, 1, 1)
    self.SpellIcon:SetTexCoord(TextureUtil.ZoomTexCoords(0.1, TextureUtil.GetCoverTexCoords(self:GetSize())))
    self.Textures.ViewItemSetButton:SetFrameLevel(frameLevel + 12)
    self.Textures.StoreButton:SetFrameLevel(frameLevel + 12)
    self.Textures.BazaarButton:SetFrameLevel(frameLevel + 12)
end 

function AppearanceModelMixin:OnShow()
    self:RegisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:RegisterEvent("PENDING_APPEARANCE_CHANGED")

    if self.appearanceID or self.outfitName then
        self:RefreshDisplay()
    end
end

function AppearanceModelMixin:OnHide()
    self:UnregisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:UnregisterEvent("PENDING_APPEARANCE_CHANGED")
end

function AppearanceModelMixin:APPLY_PENDING_APPEARANCE_RESULT()
    self:UpdateBorder()
end

function AppearanceModelMixin:PENDING_APPEARANCE_CHANGED()
    self:UpdateBorder()
end

function AppearanceModelMixin:TryOnTransmogGear(slot)
    self:Undress()
    if slot then
        local setup = WARDROBE_MODEL_SETUP[slot]
        if setup then
            for slot, show in pairs(setup) do
                if show then
                    local itemID = WARDROBE_MODEL_SETUP_GEAR[slot]
                    self:TryOn(itemID)
                end
            end
        end
    end
end

function AppearanceModelMixin:UpdateBorder()
    self.Textures.Border:SetVertexColor(1, 1, 1, 1)
    if self.isCollected and self.isCollected > 0 then
        self:SetAlpha(1)
        if self.canApply then
            if self.isCollected == 1 then
                self.Textures.Border:SetAtlas("transmog-wardrobe-border-collected", Const.TextureKit.UseAtlasSize)
            else
                self.Textures.Border:SetAtlas("transmog-wardrobe-border-uncollected", Const.TextureKit.UseAtlasSize)
                self.Textures.Border:SetVertexColor(0.5, 0.5, 0.5, 1)
            end
        else
            self.Textures.Border:SetAtlas("transmog-wardrobe-border-unusable", Const.TextureKit.UseAtlasSize)
        end
    else
        self.Textures.Border:SetAtlas("transmog-wardrobe-border-uncollected", Const.TextureKit.UseAtlasSize)
        self:SetAlpha(0.7)
    end

    if self.appearanceID then
        local currentAppearance = C_Appearance.GetAppearanceForCategory(self.categoryID)
        local pendingAppearance = C_Appearance.GetPendingAppearance(self.categoryID)

        local slotID = AppearanceUtil.GetCategorySlotID(self.categoryID)
        local currentEquipped = slotID and GetInventoryItemTrueID("player", slotID)
        currentEquipped = currentEquipped and C_Appearance.GetItemAppearanceID(currentEquipped)
        
        -- check if appearance is our currently equipped item (only applies to inventory)
        if currentEquipped == self.appearanceID then
            -- if we are trying to transmog to our current equip, show purple transmog border
            if pendingAppearance == currentEquipped or currentAppearance == currentEquipped then
                self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-current-transmogged", Const.TextureKit.UseAtlasSize)
            else -- show gold border for current equip
                self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-current", Const.TextureKit.UseAtlasSize)
            end
            self.Textures.StateTexture:Show()
        -- check if we have a pending appearance at all in this slot, we dont want multiple purple borders
        elseif pendingAppearance then
            -- if this is the pending appearance, show purple transmog border
            if pendingAppearance == self.appearanceID then
                self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-current-transmogged", Const.TextureKit.UseAtlasSize)
                self.Textures.StateTexture:Show()
            else -- hide even if this might be our current appearance
                self.Textures.StateTexture:Hide()
            end
        -- check if this is our current appearance (different from current equipped)
        elseif currentAppearance == self.appearanceID then
            -- show purple border for current appearance
            self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-current", Const.TextureKit.UseAtlasSize)
            self.Textures.StateTexture:Show()
        else
            self.Textures.StateTexture:Hide()
        end
    elseif self.outfitName then
        if self.outfitName == NEW_OUTFIT then
            self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-new-outfit", Const.TextureKit.UseAtlasSize)
            self.Textures.StateTexture:Show()
            return
        end
        if C_AppearanceOutfit.GetCurrentOutfitName() == self.outfitName then
            self.Textures.StateTexture:SetAtlas("transmog-wardrobe-border-current-transmogged", Const.TextureKit.UseAtlasSize)
            self.Textures.StateTexture:Show()
        else
            self.Textures.StateTexture:Hide()
        end
    end
end

function AppearanceModelMixin:RefreshDisplay()
    self:SetPosition(0, 0, 0)
    self:SetFacing(-0.3)
    self:StopSequence()
    self:ClearModel()
    self:SetCamera(1)
    self.SpellIcon:Hide()
    self.Textures.NameText:Hide()
    self.Textures.CollectedText:Hide()
    self.Textures.AddIcon:Hide()
    self.Textures.BazaarButton:Hide()
    self.Textures.StoreButton:Hide()
    self.DeleteButton:Hide()
    self.OverwriteButton:Hide()

    if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
        self:DisplayItem()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_CREATURE" then
        self:DisplayCreature()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_ENCHANT" then
        self:DisplayIllusion()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_SPELL" then
        self:DisplaySpellIcon()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_STATIC_SPELL_VISUAL" then
        self:DisplayStaticSpell()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ANIMATED_SPELL_VISUAL" then
        self:DisplayAnimatedSpell()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_OUTFIT" then
        self:DisplayOutfit()
    elseif self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_SET" then
        self:DisplayItemSet()
    end

    self:UpdateDiscount()
    self:UpdateItemSetButton()
end

function AppearanceModelMixin:SetAppearanceID(appearanceID, categoryID)
    self.outfitName = nil
    self.setID = nil
    if appearanceID and categoryID and self.appearanceID == appearanceID and self.categoryID == categoryID then
        self:UpdateBorder()
        return
    end
    self.appearanceID = appearanceID
    self.categoryID = categoryID
    self.displayType, self.displayID, self.uiCamera, self.displayName, self.entry, self.spellVisualID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)

    self.canApply, self.cannotApplyReason = C_Appearance.CanSetAppearance(categoryID, appearanceID)

    if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_SET" then
        local numCollected, numPieces = C_ItemSet.GetItemSetNumCollected(self.displayID)
        self.isCollected = numPieces and numPieces > 0 and (numCollected / numPieces) or 0
    else
        self.isCollected = C_AppearanceCollection.IsAppearanceCollected(self.appearanceID) and 1 or 0
    end

    self:UpdateBorder()

    if self.cancelToken then
        self.cancelToken()
        self.cancelToken = nil
    end

    if self.displayType then
        self:Show()
    else
        self:Hide()
        return
    end

    self:RefreshDisplay()

    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function AppearanceModelMixin:SetOutfitDisplay(outfitName, categoryID)
    self.appearanceID = nil
    if outfitName and self.outfitName == outfitName and self.outfitName ~= NEW_OUTFIT then
        self:UpdateBorder()
        return
    end

    self.outfitName = outfitName
    self.categoryID = categoryID
    self.displayType = "APPEARANCE_DISPLAY_TYPE_OUTFIT"
    self.displayName = outfitName
    self.displayID = nil
    self.uiCamera = nil
    self.canApply = true
    self.isCollected = 1
    
    self:UpdateBorder()

    if self.outfitName then
        self:Show()
    else
        self:Hide()
        return
    end
    
    self:RefreshDisplay()

    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function AppearanceModelMixin:DisplayItem()
    local invType = GetItemInventoryType(self.displayID)
    local slot = INVTYPE_INDEX_TO_SLOT[invType]

    if slot == INVSLOT_MAINHAND or slot == INVSLOT_OFFHAND or slot == INVSLOT_RANGED then
        self:DisplayWeapon()
        return
    end

    SetModelApplyComponents(false)
    self:SetUnit("player")
    SetModelApplyComponents(true)
    self:TryOnTransmogGear(slot)
    
    local item = Item:CreateFromID(self.displayID)
    self:ShowLoadingAfterDelay()
    if self.uiCamera then
        self:ApplyUICamera(self.uiCamera, true)
        self:FreezeSequence() -- this will be jittery if the animation has a lot of movement.
    end
    self.cancelToken = item:CancelableContinueOnLoad(function()
        self:TryOn(self.displayID)
        self:CancelLoading()
        self:UpdateBorder()
    end)

    if self.isCollected < 1 then
        local url = C_Appearance.GetAppearanceWebURL(self.appearanceID)
        if url then
            self.Textures.StoreButton:Show()
            self.Textures.StoreButton.url = url
        elseif C_Appearance.IsEtherealBazaarAppearance(self.appearanceID) then
            self.Textures.BazaarButton:Show()
            self.Textures.BazaarButton.url = C_Appearance.GetEtherealBazaarWebURL()
        end
    end
end

function AppearanceModelMixin:DisplayWeapon()
    self:ShowLoadingAfterDelay()
    self:SetDisplayInfo(44472, function()
        local item = Item:CreateFromID(self.displayID)
        -- fixes bug where setting the creature, TryOn and uicamera in the same frame causes the camera to not apply.
        RunNextFrame(function()
            self.cancelToken = item:CancelableContinueOnLoad(function()
                if self.displayID ~= item:GetItemID() then
                    return -- run next frame means we might have changed appearances
                end
                self:TryOn(self.displayID)

                if self.uiCamera then
                    self:ApplyUICamera(self.uiCamera, true)
                end
                self:FreezeSequence() -- this will be jittery if the animation has a lot of movement.
                self:CancelLoading()
            end)
        end)
    end)
end

function AppearanceModelMixin:DisplayCreature()
    self:ShowLoadingAfterDelay()
    if type(self.displayID) ~= "number" or self.displayID <= 0 then
        C_Logger.Error("No DisplayID given, but display type is APPEARANCE_DISPLAY_TYPE_CREATURE. AppearanceID: %s", self.appearanceID)
        self:CancelLoading()
        return
    end
    self:SetDisplayInfo(self.displayID, function()
        local displayItems = C_Appearance.GetCreatureDisplayItems(self.appearanceID)
        if displayItems and #displayItems > 0 then
            local appearanceID = self.appearanceID
            for _, itemID in ipairs(displayItems) do
                local item = Item:CreateFromID(itemID)
                -- fixes bug where setting the creature, TryOn and uicamera in the same frame causes the camera to not apply.
                RunNextFrame(function()
                    self.cancelToken = item:CancelableContinueOnLoad(function(itemID)
                        if self.appearanceID ~= appearanceID then
                            return -- run next frame means we might have changed appearances
                        end
                        self:TryOn(itemID)

                        if self.uiCamera then
                            self:ApplyUICamera(self.uiCamera, true)
                        end
                        self:FreezeSequence() -- this will be jittery if the animation has a lot of movement.
                    end)
                end)
            end
        else
            if self.uiCamera then
                self:ApplyUICamera(self.uiCamera, true)
            end
            self:FreezeSequence() -- this will be jittery if the animation has a lot of movement.
        end
        self:CancelLoading()
        self:UpdateBorder()
    end)
end


function AppearanceModelMixin:DisplayIllusion()
    self:ShowLoadingAfterDelay()
    self:SetDisplayInfo(44472, function()
        local slotID = AppearanceUtil.GetIllusionCategorySlotID(self.categoryID)
        local itemID = GetInventoryItemTrueID("player", slotID) or GetInventoryItemTrueID("player", INVSLOT_MAINHAND) or 25
        self.uiCamera = C_UICamera.GetItemCameraID(itemID)
        local item = Item:CreateFromID(itemID)
        self.cancelToken = item:CancelableContinueOnLoad(function()
            self:TryOn(format("item:%s:%s", itemID, self.displayID), slotID or INVSLOT_MAINHAND)
            self:CancelLoading()
            self:UpdateBorder()
        end)

        if self.uiCamera then
            self:ApplyUICamera(self.uiCamera, true)
        end
        self:UpdateBorder()
        self:FreezeSequence() -- this will be jittery if the animation has a lot of movement.
    end)
end

function AppearanceModelMixin:DisplayStaticSpell()
    SetModelApplyComponents(false)
    self:SetUnit("player")
    SetModelApplyComponents(true)
    self:TryOnTransmogGear("SPELL")

    self:UpdateBorder()
    self:SetFacing(-0.65)
    self:SetPosition(-0.12, 0.00, -0.05)
    self:SetSpellVisual(self.displayID, self.spellVisualID or 0)
    self:PlaySequence(3, true)
    self:FreezeSequence()
end

function AppearanceModelMixin:DisplayAnimatedSpell()
    SetModelApplyComponents(false)
    self:SetUnit("player")
    SetModelApplyComponents(true)
    self:TryOnTransmogGear("SPELL")

    self:SetSpell(self.displayID, self.spellVisualID or 0)
    self:UpdateBorder()
    self:SetFacing(-0.65)
    self:SetPosition(-0.12, 0.00, -0.05)
end

function AppearanceModelMixin:DisplaySpellIcon()
    self:ClearModel()
    self.SpellIcon:Show()
    self.Textures.NameText:Show()
    local _, _, icon = GetSpellInfo(self.displayID)
    self.SpellIcon:SetTexture(icon)

    self.Textures.NameText:ClearAndSetPoint("CENTER", 0, 2)
    self.Textures.NameText:SetText(self.displayName)
    self.Textures.NameText:SetJustifyV("MIDDLE")
    self:UpdateBorder()
end

function AppearanceModelMixin:DisplayOutfit()
    SetModelApplyComponents(false)
    self:SetUnit("player")
    self:Undress()
    SetModelApplyComponents(true)
    self:SetFacing(0)
    self:SetPosition(0.58, 0.00, -0.05)
    self:PlaySequence(3, true)
    self:FreezeSequence()

    if self.outfitName == NEW_OUTFIT then
        -- new outfit setup
        self:Dress()
        self.Textures.NameText:ClearAndSetPoint("BOTTOM", 0, 8)
        self.Textures.NameText:SetJustifyV("BOTTOM")
        self.Textures.NameText:Show()
        self.Textures.NameText:SetText(NEW_OUTFIT)
        self.DeleteButton:Hide()
        self.OverwriteButton:Hide()
        self.Textures.AddIcon:Show()
        self:UpdateBorder()
        return
    end

    self:ShowLoadingAfterDelay()
    local appearanceIDs = C_AppearanceOutfit.GetOutfitInfo(self.outfitName)

    -- collect which items we need to query
    local displayIDs, needsQuery = {}, {}
    for categoryID, appearanceID in pairs(appearanceIDs) do
        local displayType, displayID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
        if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" and displayID then
            if not GetItemInfo(displayID) then
                table.insert(needsQuery, displayID)
            end
            displayIDs[categoryID] = displayID
        end
    end

    -- if we need to query, query first
    if #needsQuery > 0 then
        self.cancelToken = ItemQueryListener:AddCancelableCallback(needsQuery, function()
            for categoryID, displayID in pairs(displayIDs) do
                local slotID = AppearanceUtil.GetCategorySlotID(categoryID)
                self:TryOn(displayID, slotID)
            end
            self:CancelLoading()
            self:UpdateBorder()
        end)
    else
        -- otherwise, just try on
        for categoryID, displayID in pairs(displayIDs) do
            local slotID = AppearanceUtil.GetCategorySlotID(categoryID)
            self:TryOn(displayID, slotID)
        end
        self:CancelLoading()
        self:UpdateBorder()
    end
    
    self.DeleteButton:Show()
    self.OverwriteButton:Show()

    self.Textures.NameText:ClearAndSetPoint("BOTTOM", 0, 8)
    self.Textures.NameText:SetJustifyV("BOTTOM")
    self.Textures.NameText:Show()
    self.Textures.NameText:SetText(self.outfitName)
end


function AppearanceModelMixin:DisplayItemSet()
    if self.cancelToken then
        self.cancelToken()
    end
    self:ShowLoadingAfterDelay()
    SetModelApplyComponents(false)
    self:SetUnit("player")
    self:Undress()
    SetModelApplyComponents(true)

    self:SetFacing(0)
    self:SetPosition(0.58, 0.00, -0.05)
    self:PlaySequence(3, true)
    self:FreezeSequence()

    local appearanceIDs = C_ItemSet.GetAppearances(self.displayID)
    if not appearanceIDs then
        return C_Logger.Error("Appearance Set DisplayID [%s] does not return any appearances from C_ItemSet.GetAppearances(displayID)", self.displayID)
    end

    -- collect which items we need to query
    local displayIDs, needsQuery = {}, {}
    for slotID, appearanceID in pairs(appearanceIDs) do
        if appearanceID ~= 0 then
            local displayType, displayID = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
            if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" and displayID then
                if not GetItemInfo(displayID) then
                    table.insert(needsQuery, displayID)
                end
                displayIDs[slotID] = displayID
            end
        end
    end

    -- if we need to query, query first
    if #needsQuery > 0 then
        self.cancelToken = ItemQueryListener:AddCancelableCallback(needsQuery, function()
            for slotID, displayID in pairs(displayIDs) do
                self:TryOn(displayID, slotID)
            end
            self:CancelLoading()
            self:UpdateBorder()
        end)
    else
        -- otherwise, just try on
        for slotID, displayID in pairs(displayIDs) do
            self:TryOn(displayID, slotID)
        end
        self:CancelLoading()
        self:UpdateBorder()
    end

    self.Textures.NameText:ClearAndSetPoint("BOTTOM", 0, 8)
    self.Textures.NameText:SetJustifyV("BOTTOM")
    self.Textures.NameText:Show()
    self.Textures.NameText:SetText(self.displayName)
    
    self.Textures.CollectedText:SetFormattedText("%s/%s", C_ItemSet.GetItemSetNumCollected(self.displayID))
    self.Textures.CollectedText:Show()

    

    if self.isCollected < 1 then
        local url = C_Appearance.GetAppearanceWebURL(self.appearanceID)
        if url then
            self.Textures.StoreButton:Show()
            self.Textures.StoreButton.url = url
        elseif C_Appearance.IsEtherealBazaarAppearance(self.appearanceID) then
            self.Textures.BazaarButton:Show()
        end
    end
end


function AppearanceModelMixin:OnClick()
    if self.appearanceID then
        if IsControlKeyDown() and C_Player:IsGM() and not UnitExists("target") and not C_AppearanceCollection.IsAppearanceCollected(self.appearanceID) then
            if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM_SET" then
                for _, appearanceID in pairs(C_ItemSet.GetAppearances(self.displayID)) do
                    if appearanceID ~= 0 and not C_AppearanceCollection.IsAppearanceCollected(appearanceID) then
                        SendChatMessage(".collection appearance add " .. UnitName("player") .. " " .. appearanceID)
                    end
                end
            else
                SendChatMessage(".collection appearance add " .. UnitName("player") .. " " .. self.appearanceID)
            end
            return
        end
        if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(AppearanceUtil.GetAppearanceLink(self.appearanceID))
            return
        end
        PlaySound(SOUNDKIT.UI_VOIDSTORAGE_REDO)
        if C_Appearance.IsTransmogable(self.categoryID, self.appearanceID) then
            C_Appearance.SetPendingAppearance(self.categoryID, self.appearanceID)
        end
    elseif self.outfitName then
        if self.outfitName == NEW_OUTFIT then
            StaticPopup_Show("CONFIRM_SAVE_APPEARANCE_OUTFIT")
            return
        end

        if IsControlKeyDown() and C_Player:IsGM() and not UnitExists("target") then
            for _, appearanceID in pairs(C_AppearanceOutfit.GetOutfitInfo(self.outfitName)) do
                if appearanceID ~= 0 and not C_AppearanceCollection.IsAppearanceCollected(self.appearanceID) then
                    SendChatMessage(".collection appearance add " .. appearanceID)
                end
            end
            return
        end
        if C_AppearanceOutfit.GetCurrentOutfitName() ~= self.outfitName then
            PlaySound(SOUNDKIT.UI_VOIDSTORAGE_REDO)
            C_AppearanceOutfit.SetPendingOutfit(self.outfitName)
        end
    end
end 

function AppearanceModelMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local color
    if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
        color = ITEM_QUALITY_COLORS[GetItemQuality(self.displayID)] or HIGHLIGHT_FONT_COLOR
    else
        color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]
    end
    GameTooltip:SetText(self.displayName or "", color:GetRGB())

    if self.appearanceID then
        if self.isCollected > 0 then
            local r, g, b = TRANSMOG_UNLOCK_COLOR:GetRGB()
            GameTooltip:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN, r, g, b, false)
        else
            local r, g, b = APPEARANCE_NOT_COLLECTED_COLOR:GetRGB()
            GameTooltip:AddLine(TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN, r, g, b, false)
        end

        if C_Appearance.IsEtherealBazaarAppearance(self.appearanceID) then
            GameTooltip:AddLine(TRANSMOG_AVAILABLE_ON_BAZAAR, GREEN_FONT_COLOR:GetRGB())
        end

        if C_Appearance.GetAppearanceWebURL(self.appearanceID) then
            GameTooltip:AddLine(TRANSMOG_AVAILABLE_ON_WEB, LINK_COLOR:GetRGB())
        end

        local additionalTooltip = C_Appearance.GetAppearanceDetails(self.appearanceID)
        if additionalTooltip then
            GameTooltip:AddLine(additionalTooltip, 1, 0.82, 0, true)
        end

        local alternativeIDs = C_Appearance.GetAlternativeIDs(self.appearanceID, self.entry)
        if alternativeIDs and #alternativeIDs > 0 then
            local shownNames = {}
            GameTooltip_AddSpacer(GameTooltip)
            GameTooltip:AddLine(TRANSMOG_SHARES_APPEARANCE_TOOLTIP, 1, 0.82, 0, false)
            for _, altItemID in ipairs(alternativeIDs) do
                local name = GetItemName(altItemID)
                if not name then
                    C_Logger.Error("Bad Alternative ItemID from C_Appearance.GetAlternativeIDs for appearanceID: %s, altItemID: %s", self.appearanceID, altItemID)
                elseif not shownNames[name] then
                    shownNames[name] = true
                    GameTooltip:AddLine(name, ITEM_QUALITY_COLORS[GetItemQuality(altItemID)]:GetRGB())
                end
            end
        end
        if C_Player:IsGM() then
            GameTooltip_AddSpacer(GameTooltip)
            GameTooltip_AddIDLine(GameTooltip, "Appearance ID", self.appearanceID)
            GameTooltip_AddIDLine(GameTooltip, "Category ID", self.categoryID)
            GameTooltip_AddIDLine(GameTooltip, "Display Entry", self.displayID)
            GameTooltip_AddIDLine(GameTooltip, "Display Type", self.displayType)
            GameTooltip_AddIDLine(GameTooltip, "UI Camera", self.uiCamera or "none")

            if self.displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
                local itemTemplate = GetItemTemplate(self.displayID)
                if itemTemplate then
                    GameTooltip_AddIDLine(GameTooltip, "Display ID", itemTemplate.DisplayInfoID)
                end
                GameTooltip_AddIDLine(GameTooltip, "Inventory Type", INVTYPE_INDEX_TO_STRING[GetItemInventoryType(self.displayID)] .. " (" .. GetItemInventoryType(self.displayID) .. ")")
                GameTooltip_AddIDLine(GameTooltip, "Equip Slot", INVTYPE_INDEX_TO_SLOT[GetItemInventoryType(self.displayID)])
                GameTooltip_AddIDLine(GameTooltip, "Item Class", GetItemClassID(self.displayID))
                GameTooltip_AddIDLine(GameTooltip, "Item SubClass", GetItemSubClassID(self.displayID))
            end
        end
    elseif self.outfitName then
        if C_Player:IsGM() then
            GameTooltip_AddSpacer(GameTooltip)
            GameTooltip_AddIDLine(GameTooltip, "Category ID", self.categoryID)
        end
    end
    
    GameTooltip:Show()
end 

function AppearanceModelMixin:OnLeave()
    GameTooltip:Hide()
end 

function AppearanceModelMixin:UpdateDiscount()
    if self.appearanceID then
        local discount, url = C_Appearance.GetActiveDiscount(self.appearanceID)
        self.Textures.Discount:SetShown(discount)
        self.Textures.Discount.url = url
    else
        self.Textures.Discount:Hide()
    end
end

function AppearanceModelMixin:UpdateItemSetButton()
    local setName = C_Appearance.GetAppearanceItemSet(self.appearanceID)
    self.Textures.ViewItemSetButton:SetShown(setName ~= nil)
    self.Textures.ViewItemSetButton.setName = setName

    if setName ~= nil then
        local tip = {
            text = TIP_VIEW_FULL_ITEM_SET,
            textJustifyH = "CENTER",
            targetPoint = HelpTip.Point.BottomEdgeCenter,
            buttonStyle = HelpTip.ButtonStyle.Okay,
            cvar    = "HelpTipBitfield",
            system = "AppearanceTip",
            systemPriority = 1,
            cvarBit = HelpTips.Bits.AppearanceViewFullItemSet,
        }
        HelpTip:Show(self.Textures.ViewItemSetButton, tip)
    end
end

function AppearanceModelMixin:ShowLoadingAfterDelay()
    self:CancelLoading()
    self.cancelLoading = Timer.NewTimer(0.5, function() self.Loading:Show() end)
end

function AppearanceModelMixin:CancelLoading()
    if self.cancelLoading then
        self.cancelLoading:Cancel()
        self.cancelLoading = nil
    end
    self.Loading:Hide()
end
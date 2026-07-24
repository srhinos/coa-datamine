AppearanceCategorySlotButtonMixin = {}

function AppearanceCategorySlotButtonMixin:OnLoad()
    self:RegisterForClicks("RightButtonUp", "LeftButtonUp")
    self.Border:SetAtlas("transmog-frame", Const.TextureKit.UseAtlasSize)
    self.NoItemTexture:SetAtlas("transmog-no-item", Const.TextureKit.IgnoreAtlasSize)
    self.StatusBorder:SetAtlas("transmog-frame-pink", Const.TextureKit.UseAtlasSize)
    self.HiddenVisualCover:SetAtlas("transmog-frame-blackcover", Const.TextureKit.UseAtlasSize)
    self.HiddenVisualIcon:SetAtlas("transmog-icon-hidden", Const.TextureKit.UseAtlasSize)
    self:SetCheckedAtlas("transmog-frame-selected", true)
    self:SetHighlightAtlas("transmog-frame-highlighted")
end

function AppearanceCategorySlotButtonMixin:OnShow()
    self:RegisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:RegisterEvent("PENDING_APPEARANCE_CHANGED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self.AnimFrame:Hide()
    self:Refresh()
end

function AppearanceCategorySlotButtonMixin:OnHide()
    self:UnregisterEvent("APPLY_PENDING_APPEARANCE_RESULT")
    self:UnregisterEvent("PENDING_APPEARANCE_CHANGED")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end

function AppearanceCategorySlotButtonMixin:APPLY_PENDING_APPEARANCE_RESULT()
    self:Refresh()
end

function AppearanceCategorySlotButtonMixin:PENDING_APPEARANCE_CHANGED()
    self:Refresh()
end

function AppearanceCategorySlotButtonMixin:PLAYER_EQUIPMENT_CHANGED()
    self:Refresh()
end

function AppearanceCategorySlotButtonMixin:Refresh()
    if self.categoryID then
        self:SetCategory(self.categoryID)
    end
end

function AppearanceCategorySlotButtonMixin:SetCategory(categoryID)
    self.categoryID = categoryID
    
    local invSlot = AppearanceUtil.GetCategorySlotID(categoryID)
    if invSlot then
        local displayID = AppearanceUtil.GetSlotDisplayID(invSlot)
        if displayID then
            self:SetActiveItemDisplay(displayID)
        else
            local _, icon = GetInventorySlotInfoByID(invSlot)
            self:SetInactiveIconDisplay(icon)
        end
        
        if GetInventoryItemTrueID("player", invSlot) then
            self.NoItemTexture:Hide()
        else
            self.NoItemTexture:Show()
        end
    else
        self.NoItemTexture:Hide()
        local displayID = AppearanceUtil.GetCategoryDisplayID(categoryID)
        local _, icon = C_AppearanceCollection.GetCategoryInfo(categoryID)
        if displayID then
            self:SetActiveIconDisplay("Interface\\Icons\\"..icon)
        else
            self:SetInactiveIconDisplay("Interface\\Icons\\"..icon)
        end
    end
    
    self:UpdateBorder()
    if GameTooltip:IsOwned(self) then
        self:OnEnter()
    end
end

function AppearanceCategorySlotButtonMixin:SetActiveItemDisplay(displayID)
    local icon = "Interface\\Icons\\"..(GetItemIconInstant(displayID) or "INV_Misc_QuestionMark")
    self.Icon:SetTexture(icon)
    self.Icon:SetDesaturated(false)
end

function AppearanceCategorySlotButtonMixin:SetActiveIconDisplay(icon)
    self.Icon:SetTexture(icon)
    self.Icon:SetDesaturated(false)
end

function AppearanceCategorySlotButtonMixin:SetInactiveIconDisplay(icon)
    self.Icon:SetTexture(icon)
    self.Icon:SetDesaturated(true)
end

function AppearanceCategorySlotButtonMixin:UpdateBorder()
    local showStatusBorder = false
    local showPendingFrame = false
    local showPendingUndo = false
    local canApply = true
    
    local pendingAppearanceID = C_Appearance.GetPendingAppearance(self.categoryID)
    if pendingAppearanceID then
        showPendingFrame = true
        showPendingUndo = pendingAppearanceID == 0
        canApply = showPendingUndo or C_Appearance.CanSetAppearance(self.categoryID, pendingAppearanceID)
    end
    
    if C_Appearance.GetAppearanceForCategory(self.categoryID) then
        showStatusBorder = true
    end
    
    self.StatusBorder:SetShown(showStatusBorder)
    self.PendingFrame:SetShown(showPendingFrame)
    self.PendingFrame.Undo:SetShown(showPendingUndo)

    self.StoreButton:Hide()
    self.StoreButton.url = nil
    self.BazaarButton:Hide()

    if canApply then
        self.PendingFrame.Ants:SetVertexColor(1, 1, 1)
        self.PendingFrame.Glow:SetVertexColor(1, 1, 1)

        self.StoreButton:Hide()
        self.StoreButton.url = nil
    else
        self.PendingFrame.Ants:SetVertexColor(1, 0, 0)
        self.PendingFrame.Glow:SetVertexColor(1, 0, 0)

        local url = C_Appearance.GetAppearanceWebURL(pendingAppearanceID)

        if url then
            self.StoreButton:Show()
            self.StoreButton.url = url
            local tip = {
                text = TIP_APPEARANCE_AVAILABLE_ON_WEB_STORE,
                textJustifyH = "CENTER",
                targetPoint = HelpTip.Point.RightEdgeCenter,
                buttonStyle = HelpTip.ButtonStyle.Okay,
                cvar    = "HelpTipBitfield",
                system = "AppearanceTip",
                systemPriority = 3,
                cvarBit = HelpTips.Bits.AppearanceAvailableOnWebStore,
            }
            HelpTip:Show(self.StoreButton, tip)
        else
            if C_Appearance.IsEtherealBazaarAppearance(pendingAppearanceID) then
                self.BazaarButton:Show()
                local tip = {
                    text = TIP_APPEARANCE_AVAILABLE_ON_BAZAAR,
                    textJustifyH = "CENTER",
                    targetPoint = HelpTip.Point.RightEdgeCenter,
                    buttonStyle = HelpTip.ButtonStyle.Okay,
                    cvar    = "HelpTipBitfield",
                    system = "AppearanceTip",
                    systemPriority = 2,
                    cvarBit = HelpTips.Bits.AppearanceAvailableOnBazaar,
                }
                HelpTip:Show(self.BazaarButton, tip)
            end
        end
    end
end

function AppearanceCategorySlotButtonMixin:OnClick(button)
    self:SetChecked(self.categoryID == self:GetParent().categoryID) -- click will remove check status
    if button == "LeftButton" then
        local appearanceType = select(3, C_AppearanceCollection.GetCategoryInfo(self.categoryID))
        PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
        if appearanceType ~= self:GetParent().appearanceType then
            AppearanceUI:TriggerEvent("OnAppearanceTypeSelected", appearanceType)
        end
        AppearanceUI:TriggerEvent("OnCategorySelected", self.categoryID)

    elseif button == "RightButton" then
        if C_Appearance.GetPendingAppearance(self.categoryID) then
            PlaySound(SOUNDKIT.UI_VOIDSTORAGE_UNDO)
            C_Appearance.ClearPendingAppearance(self.categoryID)
        elseif C_Appearance.GetAppearanceForCategory(self.categoryID) then
            PlaySound(SOUNDKIT.UI_VOIDSTORAGE_UNDO)
            C_Appearance.SetPendingAppearance(self.categoryID, 0)
        else
            return
        end
    end
end

function AppearanceCategorySlotButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(C_AppearanceCollection.GetCategoryInfo(self.categoryID), 1, 1, 1)
    
    local pendingAppearanceID = C_Appearance.GetPendingAppearance(self.categoryID)
    local appearanceID = pendingAppearanceID or C_Appearance.GetAppearanceForCategory(self.categoryID)
    if appearanceID then
        local displayType,  displayID, _, displayName = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
        if displayName then
            local color
            if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" then
                color = ITEM_QUALITY_COLORS[GetItemQuality(displayID) or 1]
            else
                color = ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]
            end
            displayName = color:WrapText(displayName)
            GameTooltip:AddLine(format(TRANSMOGRIFIED_HEADER, displayName), 1, 0.82, 0)
        end
    end

    if pendingAppearanceID and pendingAppearanceID ~= 0 then
        local canApply, reason = C_Appearance.CanSetAppearance(self.categoryID, pendingAppearanceID)
        if not canApply then
            GameTooltip:AddLine(_G[reason] or reason, RED_FONT_COLOR:GetRGB())
        end
    end

    GameTooltip:Show()
    self.UndoButton:SetShown(C_Appearance.GetAppearanceForCategory(self.categoryID) ~= nil)
end

function AppearanceCategorySlotButtonMixin:OnLeave()
    if not self.UndoButton:IsMouseOver() then
        self.UndoButton:Hide()
    end
    GameTooltip:Hide()
end

function AppearanceCategorySlotButtonMixin:Animate()
    if not self:IsShown() then
        return
    end
    self.AnimFrame:Show()
end

function AppearanceCategorySlotButtonMixin:OnAnimFinished()
    self.AnimFrame:Hide()
end


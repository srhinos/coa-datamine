RealmScrollListItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function RealmScrollListItemMixin:Update(newIndex)
    local scrollList = self:GetScrollList()
    local realms = scrollList and scrollList.realmList
    local info = realms and realms[self.index]
    if not info then return end

    self.info = info

    -- Realm name
    local displayName = info.name
    if info.subName then
        displayName = displayName .. " - " .. info.subName
    end
    self.Name:SetText(displayName)

    -- Expansion icon badge, positioned right after the name text
    local expansionID = info.expansionID
    local expansionAtlas
    if expansionID then
        if AtlasUtil:AtlasExists("small-logo-expansion-"..expansionID) then
            expansionAtlas = "small-logo-expansion-"..expansionID
        elseif AtlasUtil:AtlasExists("realm-expansion-icon-"..expansionID) then
            expansionAtlas = "realm-expansion-icon-"..expansionID
        end
    end
    if expansionAtlas then
        self.Expansion:SetAtlas(expansionAtlas, Const.TextureKit.UseAtlasSize)
        local w, h = self.Expansion:GetSize()
        self.Expansion:SetSize(w * 0.8, h * 0.8)
        self.Expansion:Show()
        self.Expansion:ClearAndSetPoint("LEFT", self.Name, "LEFT", (self.Name:GetStringWidth() or 0) + 4, 0)
    else
        self.Expansion:Hide()
    end

    -- Character count
    self.Characters:SetText(info.characters or 0)

    -- Status icon and colors
    if not info.online then
        self.StatusIcon:SetAtlas("realm-status-offline", Const.TextureKit.IgnoreAtlasSize)
        self.Name:SetTextColor(REALM_OFFLINE_COLOR:GetRGBA())
        self.Characters:SetTextColor(REALM_OFFLINE_COLOR:GetRGBA())
    else
        local icon = "realm-status-online"
        local color = REALM_ONLINE_COLOR

        if scrollList and scrollList.forceDev then
            icon = "realm-status-dev"
            color = REALM_DEV_COLOR
        elseif info.invalid then
            icon = "realm-status-invalid"
            color = REALM_INVALID_COLOR
        elseif info.dev then
            icon = "realm-status-dev"
            color = REALM_DEV_COLOR
        end

        self.StatusIcon:SetAtlas(icon, Const.TextureKit.IgnoreAtlasSize)
        self.Name:SetTextColor(color:GetRGBA())
        self.Characters:SetTextColor(1, 0.82, 0.5)
    end
end

function RealmScrollListItemMixin:OnSelected()
end

function RealmScrollListItemMixin:Select()
    local info = self.info
    if not info or not info.online then return end
    if not info.tab or not info.realm then return end

    RealmList:Hide()
    if info.purchaseRequired then
        LaunchURL("https://ascension.gg/shop")
    else
        PlaySound(SOUNDKIT.UI_MAIN_MENU_BUTTONA_75)
        ChangeRealm(info.tab, info.realm)
    end
end

function RealmScrollListItemMixin:OnDoubleClick()
    self:Select()
end

function RealmScrollListItemMixin:OnEnter()
    local info = self.info
    if not info then return end

    local displayName = info.name
    if info.subName then
        displayName = displayName .. " - " .. info.subName
    end

    GlueTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GlueTooltip:SetText(displayName, 1, 1, 1, true)
    if info.description and info.description ~= "" then
        GlueTooltip:AddLine(info.description, nil, nil, nil, true)
    end
    GlueTooltip:Show()
end

function RealmScrollListItemMixin:OnLeave()
    GlueTooltip:Hide()
end

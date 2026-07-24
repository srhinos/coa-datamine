RealmMixin = {}

local function GetPurchaseRequiredNotice(info)
    if info.expansionID == 2 then
        return WOTLK_PURCHASE_REQUIRED
    end
end

function RealmMixin:OnLoad()
    Mixin(self.Background, "TextureDollyMixin")
    self.Background:SetDollyFinishCallback(function()
        self:SetScript("OnUpdate", nil)
    end)
end

function RealmMixin:OnShow()
end

function RealmMixin:UpdateNotice()
    local notice = GetPurchaseRequiredNotice(self.info)
    if notice then
        self.Notice:SetText(notice)
        self.Notice:Show()
    else
        self.Notice:Hide()
    end
end

function RealmMixin:UpdateGameMode()
    local modeID = self.info.modeID
    self.GameMode:SetText(GAME_MODE_COLON, self.info.mode)
    self.GameMode:Show()

    self.GameMode.tooltipTitle = _G["TOOLTIP_GAMEMODE"..modeID.."_TITLE"] or "TOOLTIP_GAMEMODE"..modeID.."_TITLE"
    self.GameMode.tooltipText = _G["TOOLTIP_GAMEMODE"..modeID.."_TEXT"] or "TOOLTIP_GAMEMODE"..modeID.."_TEXT"

    if AtlasUtil:AtlasExists("realm-game-mode-"..modeID) then
        self.GameMode:SetBackground("realm-game-mode-"..modeID)
    else
        self.GameMode:SetIcon("realm-game-mode-icon")
    end
end

function RealmMixin:UpdateExpansion()
    local expansionID = self.info.expansionID
    self.Expansion:SetText(EXPANSION_COLON, self.info.expansion)
    self.Expansion:Show()

    if expansionID < 2 then
        self.Expansion.tooltipTitle = TOOLTIP_PROGRESSIVE_TITLE
        self.Expansion.tooltipText = TOOLTIP_PROGRESSIVE_TEXT
        if self.info.page == 1 then
            self.Expansion.tooltipText = self.Expansion.tooltipText .. "\n\n" .. TOOLTIP_TIMELINE_TEXT
        end
    end

    if AtlasUtil:AtlasExists("realm-expansion-icon-"..expansionID) then
        if AtlasUtil:AtlasExists("small-logo-expansion-"..expansionID) then
            self.Expansion:SetBadge("small-logo-expansion-"..expansionID, 0.55)
        end
        self.Expansion:SetBackground("realm-expansion-icon-"..expansionID)
    else
        self.Expansion:SetIcon("realm-expansion-icon-0")
    end
end

function RealmMixin:UpdateCharacters()
    local characters = self.info.characters
    if not characters then
        characters = 0
        self.info.characters = 0
    end

    self.Characters:SetText(CHARACTERS_COLON.." |cffFFFFFF"..characters.."|r")

    if characters > 1 then
        self.Characters:SetIcon("realm-many-character")
    elseif characters == 1 then
        self.Characters:SetIcon("realm-one-character")
    else
        self.Characters:SetIcon("realm-no-character")
        self.Characters:DesaturateIcon(true)
    end
end

function RealmMixin:UpdateOnline()
    local shouldDisable = false
    -- prevent ptr client from selecting live realms
    if PTR_CLIENT and self.info.page == 1 then
        shouldDisable = true
        self.WrongClient:Show()
        self.WrongClient:SetText(DOWNLOAD_LIVE_CLIENT)
        self.SelectButton:SetText(USE_LIVE_CLIENT)
        
    -- prevent live client from selecting ptr realms
        -- allow GMs though
    elseif not PTR_CLIENT and not IsGMClient and (self.info.page == 2) and self.info.modeID ~= Enum.RealmGameMode.WarcraftReborn then
        shouldDisable = true
        local notice = GetPurchaseRequiredNotice(self.info)
        if notice then
            self.Notice:SetText(notice)
            self.Notice:Show()
        else
            self.Notice:Hide()
        end

        self.WrongClient:Show()
        self.WrongClient:SetText(DOWNLOAD_PTR_CLIENT)

        self.StatusIcon:Hide()
        self.Status:Hide()
        self.Notice:ClearAndSetPoint("TOP", 0, -22)
        self.SelectButton:SetText(USE_PTR_CLIENT)
        
    -- all other realms
    else
        self.WrongClient:Hide()
        self.SelectButton:SetText(SELECT_REALM)
        shouldDisable = not self.info.online
        if self.info.isCurrent then
            self:Focus()
        end
    end

    if shouldDisable then
        if self:IsEnabled() == 1 then
            self:Disable()
        else
            self:OnDisable()
        end
    else
        if self:IsEnabled() == 0 then
            self:Enable()
        else
            self:OnEnable()
        end
    end
end

function RealmMixin:SetRealm(info)
    self.info = info
    self:SetTitle(info.name, info.image)
    self.SubName:SetText(info.subName)
    self:SetBackground(info.image)

    self.realm = info.realm
    self.tab = info.tab

    self:UpdateNotice()
    self:UpdateGameMode()
    self:UpdateExpansion()
    self:UpdateCharacters()
    self:UpdateOnline()

    if self.OnSetRealm then
        self:OnSetRealm(info)
    end
end

function RealmMixin:Select()
    RealmList:Hide()
    if self.info.purchaseRequired then
        LaunchURL("https://ascension.gg/shop")
    else
        PlaySound(SOUNDKIT.UI_MAIN_MENU_BUTTONA_75)
        ChangeRealm(self.tab, self.realm)
    end
end

function RealmMixin:Focus()
    RealmList:Focus(self)
end

function RealmMixin:SetTitle(name, nameKey)
    self.NameTexture:SetTexture("Interface\\Glues\\RealmList\\RealmTitles\\"..nameKey)
    if self.NameTexture:GetTexture() then
        self.Name:Hide()
        self.NameTexture:Show()
        self.SubName:SetPoint("TOP", self.NameTexture, "BOTTOM", 0, 8)
    else
        self.Name:SetText(name)
        self.Name:Show()
        self.NameTexture:Hide()
        self.SubName:SetPoint("TOP", self.Name, "BOTTOM", 0, -1)
    end
end

function RealmMixin:SetBackground(image)
    if self.image == image then return end

    self.Background:SetTexture("Interface\\Glues\\RealmList\\"..image)

    self.image = image

    local left, right, top, bottom = TextureUtil.GetCoverTexCoords(self:GetSize())
    self.Background:SetTexCoord(left, right, top, bottom)
    self.Background:SetDollyStartCoords(left, right, top, bottom)
    self.Background:SetDollyEndCoords(TextureUtil.ZoomTexCoords(0.02, left, right, top, bottom))
end

function RealmMixin:OnClick()
    self:Focus()
end

function RealmMixin:OnDoubleClick()
    self:Select()
end

function RealmMixin:OnDisable()
    self.SelectButton:Disable()

    self.StatusIcon:SetAtlas("realm-status-offline", Const.TextureKit.IgnoreAtlasSize)
    self.Status:SetText(format(REALM_IS_S, OFFLINE))

    self.Name:SetVertexColor(REALM_OFFLINE_COLOR:GetRGBA())
    self.NameTexture:SetVertexColor(REALM_OFFLINE_COLOR:GetRGBA())
    self.SubName:SetVertexColor(REALM_OFFLINE_COLOR:GetRGBA())

    self.Status:SetFontObject(GlueFontDisable)

    self.Background:SetVertexColor(0.2, 0.2, 0.2)
    self.Banner:SetVertexColor(0.2, 0.2, 0.2)
end

function RealmMixin:OnEnable()
    self.SelectButton:Enable()

    local color = REALM_ONLINE_COLOR
    local icon = "realm-status-online"
    local status = format(REALM_IS_S, ONLINE)

    if self.info.invalid then
        color = REALM_INVALID_COLOR
        icon = "realm-status-invalid"
        status = format(REALM_IS_S, STARTING)
    end

    if self.info.page == 3 or self.info.page == 4 then
        color = REALM_DEV_COLOR
        icon = "realm-status-dev"
        status = color:WrapText(REALM_IS_DEVELOPMENT)
    end

    self.Status:SetText(status)
    self.Name:SetVertexColor(color:GetRGBA())
    self.NameTexture:SetVertexColor(color:GetRGBA())
    self.SubName:SetVertexColor(color:GetRGBA())
    self.StatusIcon:SetAtlas(icon)

    self.Status:SetFontObject(GameFontNormalOutline)

    self.Background:SetVertexColor(0.6, 0.6, 0.6)
    self.Banner:SetVertexColor(0.4, 0.4, 0.4)
end

function RealmMixin:OnEnter()
    if not self.Background:GetTexture() then return end
    self.Background:SetDollyTimeScale(0.5)
    self:SetScript("OnUpdate", function(self, elapsed)
        self.Background:MoveDollyForward(elapsed)
    end)
end

function RealmMixin:OnLeave()
    if not self.Background:GetTexture() then return end
    self.Background:SetDollyTimeScale(1.2)
    self:SetScript("OnUpdate", function(self, elapsed)
        self.Background:MoveDollyBackward(elapsed)
    end)
end


function RealmMixin:OnSetRealm(info)
    self.OverviewText:SetText(info.description)
end

SmallRealmMixin = CreateFromMixins(RealmMixin)

function SmallRealmMixin:OnLoad()
    RealmMixin.OnLoad(self)
    self.Selected:SetAtlas("realm-select-banner-small-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Selected:SetVertexColor(1, 0.8, 0)

    self.Highlight:SetAtlas("realm-select-banner-small-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Highlight:SetVertexColor(0.2, 0.4, 0.7)

    self.Banner:SetAtlas("realm-select-banner-small", Const.TextureKit.IgnoreAtlasSize)

    self.Background:ClearAndSetPoint("BOTTOMRIGHT", -12, 44)
    self.Background:SetPoint("TOPLEFT", 12, -2)

    self.Name:ClearAndSetPoint("TOPRIGHT", -10, -18)
    self.Name:SetJustifyH("RIGHT")
    self.Name:SetFontObject(GameFontHighlightOutlineLarge)
    self.SubName:ClearAndSetPoint("TOPRIGHT", self.Name, "BOTTOMRIGHT", 0, 0)
    self.SubName:SetJustifyH("RIGHT")
    self.SubName:SetFontObject(GameFontHighlightOutlineLarge)
    self.Status:ClearAndSetPoint("RIGHT", -20, -8)
    self.Status:SetJustifyH("RIGHT")

    self.SelectButton:SetPoint("BOTTOM", 0, 0)
end

function SmallRealmMixin:SetRealm(info)
    self.info = info
    self.Name:SetText(info.name)
    self.SubName:SetText(info.subName)
    self:SetBackground(info.image)

    self.realm = info.realm
    self.tab = info.tab

    self.Overview:SetShown(info.description ~= nil)

    self:UpdateExpansion()
    self:UpdateCharacters()

    self.StatusIcon:Hide()
    self.Status:Hide()

    self:UpdateOnline()

    if self.OnSetRealm then
        self:OnSetRealm(info)
    end
end

LargeRealmMixin = CreateFromMixins(RealmMixin)

function LargeRealmMixin:OnLoad()
    RealmMixin.OnLoad(self)
    self.Selected:SetAtlas("realm-select-banner-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Selected:SetVertexColor(1, 0.8, 0)

    self.Highlight:SetAtlas("realm-select-banner-highlight", Const.TextureKit.IgnoreAtlasSize)
    self.Highlight:SetVertexColor(0.2, 0.4, 0.7)

    self.Banner:SetAtlas("realm-select-banner", Const.TextureKit.IgnoreAtlasSize)
end

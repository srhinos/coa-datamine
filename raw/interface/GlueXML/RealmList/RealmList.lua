local RealmInfo = {}
local TAB_MAP = {}
local FIRST_PAGE = 1

local SMALL_CARD_LAYOUTS = {
    [6] = {
        { "CENTER", -335, 279 },
        { "CENTER", 0, 279 },
        { "CENTER", 335, 279 },
        { "CENTER", -335, -263 },
        { "CENTER", 0, -263 },
        { "CENTER", 335, -263 },
        scale = 0.6,
    },
    [5] = {
        { "LEFT", 0, 0 },
        { "CENTER", -310, 0 },
        { "CENTER", 0, 0 },
        { "CENTER", 310, 0 },
        { "RIGHT", 0, 0 },
        scale = 0.65,
    },
    [4] = {
        { "LEFT", 0, 0 },
        { "CENTER", -158, 0 },
        { "CENTER", 158, 0 },
        { "RIGHT", 0, 0 },
        scale = 0.8,
    },
    [3] = {
        { "LEFT", 0, 0 },
        { "CENTER", 0, 0 },
        { "RIGHT", 0, 0 },
    },
    [2] = {
        { "CENTER", -170, 0 },
        { "CENTER", 170, 0 },
    },
    [1] = {
        {"CENTER", 0, 0 },
    }
}

local WIDE_CARD_LAYOUTS = {
    [6] = {
        { "CENTER", -400, 303 },
        { "CENTER", 0, 303 },
        { "CENTER", 400, 303 },
        { "CENTER", -400, -241 },
        { "CENTER", 0, -241 },
        { "CENTER", 400, -241 },
        scale = 0.63,
    },
    [5] = {
        { "LEFT", 0, 0 },
        { "CENTER", -340, 0 },
        { "CENTER", 0, 0 },
        { "CENTER", 340, 0 },
        { "RIGHT", 0, 0 },
        scale = 0.8,
    },
    [4] = {
        { "LEFT", 0, 0 },
        { "CENTER", -170, 0 },
        { "CENTER", 170, 0 },
        { "RIGHT", 0, 0 },
    },
    [3] = {
        { "LEFT", 70, 0 },
        { "CENTER", 0, 0 },
        { "RIGHT", -70, 0 },
    },
    [2] = {
        { "CENTER", -240, 0 },
        { "CENTER", 240, 0 },
    },
    [1] = {
        {"CENTER", 0, 0 },
    }
}

RealmListMixin = {}

local MAX_REALMS = 50

function RealmListMixin:OnLoad()
    self.enabledTabs = {}
    self.page4Realms = {}
    self.page5Realms = {}
    self:HookEvent("OPEN_REALM_LIST")
    self:HookEvent("DISPLAY_SIZE_CHANGED")
    self:ScrollPage(FIRST_PAGE)
end

function RealmListMixin:OPEN_REALM_LIST()
    self:Refresh()
    self:Show()
    self.hasLoaded = true
end

function RealmListMixin:OnShow()
    if RealmMerge then
        RealmMerge.HideChoiceDialog()
        RealmMerge.HideChangeTarget()
    end
    if self.ticker then return end
    self.ticker = Timer.NewTicker(RealmListUpdateRate(), function()
        if not self:IsShown() and self.ticker then
            self.ticker:Cancel()
            self.ticker = nil
            return
        end

        RequestRealmList()
    end)

    if PTR_CLIENT then
        self:ScrollPage(2)
    elseif self.currentTab then
        if TAB_MAP[self.currentTab] and TAB_MAP[self.currentTab][self.currentRealm] then
            local page = TAB_MAP[self.currentTab][self.currentRealm].page
            if page ~= self.page then
                self:ScrollPage(page)
            end
        end
    end

    if AddonPanel:IsShown() then
        AddonPanel:Close()
    end
end

function RealmListMixin:OnHide()
    CancelRealmListQuery()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end

    if self.selected then
        self.selected.Selected:Hide()
        self.selected.info.isCurrent = false
    end
    self.currentTab = nil
    self.currentRealm = nil
    self.selected = nil
end

function RealmListMixin:Refresh()
    wipe(self.enabledTabs)
    for realm, info in pairs(RealmInfo) do
        info.wasOnline = info.online
        info.online = false
    end

    for realmIndex = 1, MAX_REALMS do
        local realmInfo, characters = GetRealmInfo(select("#", GetRealmCategories()), realmIndex)

        if realmInfo and realmInfo:find("!", 1, true) then
            realmInfo = realmInfo:SplitToTable("!")
            local name, expansionID, gamemodeID, image, unlocked, page, index, descriptionSpell = unpack(realmInfo)
            expansionID = tonumber(expansionID)
            gamemodeID = tonumber(gamemodeID)
            descriptionSpell = tonumber(descriptionSpell)
            unlocked = toboolean(unlocked)

            RealmInfo[name] = RealmInfo[name] or {}

            local info = RealmInfo[name]

            name = name:gsub("%s?%-%s?", "-")
            info.name, info.subName = string.split("-", name, 2)
            info.characters = tonumber(characters) or 0
            info.page = tonumber(page) or info.page
            info.index = tonumber(index) or info.index
            info.color = EXPANSION_COLORS[expansionID] or info.color or CreateColor(1, 0.82, 0.5)
            info.mode = _G["GAMEMODE"..gamemodeID]
            info.modeID = gamemodeID
            info.expansionID = expansionID
            info.expansion = EXPANSION_COLORS[expansionID]:WrapText(_G["EXPANSION"..expansionID])
            info.image = image or "Default"
            info.description = descriptionSpell and descriptionSpell > 0 and GetSpellDescription(descriptionSpell)
            info.purchaseRequired = not unlocked and gamemodeID ~= Enum.RealmGameMode.ConquestOfAzeroth
        end
    end

    for tabIndex = 1, select("#", GetRealmCategories()) - 1 do
        for realmIndex = 1, MAX_REALMS do
            local name, characters, invalid, offline, isCurrent, pvp, rp, load, locked, major, minor, revision, build, types = GetRealmInfo(tabIndex, realmIndex)
            if name then
                local info
                if RealmInfo[name] then
                    info = RealmInfo[name]
                else
                    RealmInfo[name] = {}
                    info = RealmInfo[name]
                    info.dev = true
                    info.color = CreateColor(1, 0.82, 0.5)
                    info.name = name
                    info.mode = GAMEMODE0
                    info.modeID = 0
                    info.expansion = EXPANSION_COLORS[0]:WrapText(EXPANSION0)
                    info.expansionID = 0
                    info.purchaseRequired = false
                end

                info.characters = tonumber(characters) or info.characters or 0
                info.invalid = invalid

                if not info.wasOnline and not offline and self.hasLoaded then
                    info.flash = true
                else
                    info.flash = nil
                end

                if not info.image or info.image == "" then
                    info.image = "Default"
                end

                info.online = not offline

                if isCurrent and not (self.currentTab and self.currentRealm) then
                    info.isCurrent = isCurrent
                    self.currentRealm = realmIndex
                    self.currentTab = tabIndex
                end

                info.pvp = pvp
                info.rp = rp
                info.load = load
                info.locked = locked
                info.major = major
                info.minor = minor
                info.revision = revision
                info.build = build
                info.types = types

                info.tab = tabIndex
                info.realm = realmIndex
            end
        end
    end

    wipe(self.page4Realms)
    wipe(self.page5Realms)
    local nextPage5AutoIndex = 1000

    for _, info in pairs(RealmInfo) do
        if info.dev or not info.index or not info.page then
            info.page = 5
            if not info.index then
                info.index = nextPage5AutoIndex
                nextPage5AutoIndex = nextPage5AutoIndex + 1
            end
        end

        if info.tab and info.realm then
            TAB_MAP[info.tab] = TAB_MAP[info.tab] or {}
            TAB_MAP[info.tab][info.realm] = { page = info.page, index = info.index }
        end

        if info.page == 4 then
            tinsert(self.page4Realms, info)
        elseif info.page == 5 then
            tinsert(self.page5Realms, info)
        else
            local section = self.Scroll.Content["Page"..info.page]
            if section then
                local card = section["Realm"..info.index]
                if card and info.tab and info.realm then
                    card:Show()
                    card:SetRealm(info)
                end
            end
        end

        if info.page ~= 5 or IsGMClient then
            self.enabledTabs[info.page] = true
        end
    end

    local function sortByIndex(a, b)
        return (a.index or 0) < (b.index or 0)
    end
    table.sort(self.page4Realms, sortByIndex)
    table.sort(self.page5Realms, sortByIndex)

    local tabsWidth = 0

    local lastTab
    for page = 1, 5 do
        if page ~= 4 and page ~= 5 then
            for realm = 1, 12 do
                local card = self.Scroll.Content["Page"..page]["Realm"..realm]
                if not card then break end

                if not card.info then
                    card:Hide()
                end
            end
        end
        local button = self.Tabs.Buttons[page]

        if self.enabledTabs[page] then
            tabsWidth = tabsWidth + button:GetWidth()
            button:Show()
            if lastTab then
                button:ClearAndSetPoint("LEFT", lastTab, "RIGHT", 0, 0)
            else
                button:ClearAndSetPoint("LEFT", self.Tabs, "LEFT", 0, 0)
            end
            lastTab = button
        else
            button:ClearAllPoints()
            button:Hide()
        end
    end

    self.Tabs:SetWidth(tabsWidth)

    local page4ScrollList = self.Scroll.Content.Page4.RealmScrollList
    page4ScrollList.realmList = self.page4Realms
    page4ScrollList.forceDev = true
    page4ScrollList:SetGetNumResultsFunction(function()
        return #self.page4Realms
    end)
    page4ScrollList:SetTemplate("RealmScrollListItemTemplate")
    if page4ScrollList:IsInitialized() then
        page4ScrollList:RefreshScrollFrame()
    end

    local page5ScrollList = self.Scroll.Content.Page5.RealmScrollList
    page5ScrollList.realmList = self.page5Realms
    page5ScrollList:SetGetNumResultsFunction(function()
        return #self.page5Realms
    end)
    page5ScrollList:SetTemplate("RealmScrollListItemTemplate")
    if page5ScrollList:IsInitialized() then
        page5ScrollList:RefreshScrollFrame()
    end

    local layout

    local aspect = GetScreenWidth() / GetScreenHeight()
    local smallAspect = 1.3333333333333333 -- 4/3
    local page3 = self.Scroll.Content.Page3

    if math.NearlyEquals(aspect, smallAspect, 0.1) then
        layout = SMALL_CARD_LAYOUTS
        page3.Realm1:SetPoint("TOPLEFT", 0, -15)
        page3.Realm3:SetPoint("TOPRIGHT", 0, -15)
    else
        layout = WIDE_CARD_LAYOUTS
        page3.Realm1:SetPoint("TOPLEFT", 70, -15)
        page3.Realm3:SetPoint("TOPRIGHT", -70, -15)
    end

    for page = 1, 2 do
        local cards = {}
        for realm = 1, 6 do
            local card = self.Scroll.Content["Page"..page]["Realm"..realm]
            if card and card:IsShown() then
                tinsert(cards, card)
            end
        end

        for index, card in ipairs(cards) do
            local cardNumLayout = layout[#cards]
            card:ClearAndSetPoint(unpack(cardNumLayout[index]))
            if cardNumLayout.scale then
                card:SetScale(cardNumLayout.scale)
            else
                card:SetScale(1)
            end
        end
    end
end

function RealmListMixin:DISPLAY_SIZE_CHANGED()
    for _, category in ipairs(self.Scroll.Content.Pages) do
        category:SetWidth(GlueParent:GetWidth())
    end

    self.Scroll.Content:SetWidth(GlueParent:GetWidth() * #self.Scroll.Content.Pages)
end

function RealmListMixin:Cancel()
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self:Hide()
    PlaySound(SOUNDKIT.UI_MAIN_MENU_BUTTONA)
    RealmListDialogCancelled()
end

function RealmListMixin:ScrollPage(page)
    self.targetPage = math.clamp(page, 1, 5)

    if self.targetPage == self.page then return end

    for _, button in pairs(self.Tabs.Buttons) do
        button:SetSelected(button:GetID() == self.targetPage)
    end

    self.time = 0
    self.start = self.Scroll:GetHorizontalScroll()
    self.stop = (self.targetPage - 1) * GlueParent:GetWidth()
    self.page = self.targetPage

    self.isScrolling = true
    self:SetScript("OnUpdate", self.OnUpdate)
end

function RealmListMixin:OnMouseWheel(delta)
    if self.isScrolling then return end

    if delta >= 1 then
        RealmList:ScrollPage(self.page - 1)
    else
        RealmList:ScrollPage(self.page + 1)
    end
end

function RealmListMixin:OnUpdate(elapsed)
    if self.time >= 1 then
        self.Scroll:SetHorizontalScroll(self.stop)
        self.time = nil
        self.start = nil
        self.stop = nil
        self:SetScript("OnUpdate", nil)

        if self.isScrolling then
            self.isScrolling = false
        end
        return
    end

    local scroll = math.lerp(self.start, self.stop, EaseInOut(self.time, 2))

    self.Scroll:SetHorizontalScroll(scroll)

    self.time = self.time + elapsed * 2
end

function RealmListMixin:OnKeyDown(key)
    if key == "LEFT" then
        self:MoveFocus(-1)
    elseif key == "RIGHT" then
        self:MoveFocus(1)
    elseif key == "ESCAPE" then
        self:Hide()
        RealmListDialogCancelled()
    elseif key == "PRINTSCREEN"  then
        Screenshot()
    elseif key == "ENTER" then
        if self.page == 4 or self.page == 5 then
            local scrollList = self.Scroll.Content["Page"..self.page].RealmScrollList
            local selectedButton = scrollList:GetSelectedButton()
            if selectedButton and selectedButton.Select then
                selectedButton:Select()
            end
        elseif self.currentTab and self.currentRealm then
            if self.selected then
                if self.selected.SelectButton:IsEnabled() == 0 then
                    return
                end

                if self.ticker then
                    self.ticker:Cancel()
                    self.ticker = nil
                end
                self.selected:Select()
            end
        end
    end
end

function RealmListMixin:Focus(frame)
    if self.selected == frame then
        return
    end

    self.currentTab = frame.tab
    self.currentRealm = frame.realm

    if self.selected then
        self.selected.info.isCurrent = false
        self.selected.Selected:Hide()
    end

    frame.info.isCurrent = true
    self.selected = frame

    frame.Selected:Show()
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
end

function RealmListMixin:MoveFocus(direction)
    local current = self.selected
    local card

    if not current then
        card = self.Scroll.Content.Page1.Realm1
    else
        local page, realm = current.info.page, current.info.index

        local maxCards = page >= 3 and 12 or 6

        local canMoveLeft = page > 1 or realm > 1
        local canMoveRight = page < 5 or realm < maxCards

        local canFocus = card and card.info and card:IsVisible() and card.info.online

        while not canFocus and (canMoveLeft or canMoveRight) do
            if realm + direction >= 1 and realm + direction <= maxCards then
                realm = realm + direction

            elseif page + direction >= 1 and page + direction <= 5 then
                page = page + direction
                maxCards = page >= 3 and 12 or 6

                if direction > 0 then
                    realm = 1
                else
                    realm = maxCards
                end
            else
                break
            end

            canMoveLeft = page > 1 or realm > 1
            canMoveRight = page < 5 or realm < maxCards
            card = self.Scroll.Content["Page"..page]["Realm"..realm]
            canFocus = card and card.info and card:IsVisible() and card.info.online
        end
    end

    if card and card.info and card:IsVisible() and card.info.online then
        self:ScrollPage(card.info.page)
        self:Focus(card)
    end
end

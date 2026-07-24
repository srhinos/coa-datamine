local Addon = select(2, ...)

local Recap = Addon.DeathRecap

local f = CreateFrame("Frame", "DeathRecapFrame", UIParent, "UIPanelDialogTemplate")
f:Hide()
tinsert(UISpecialFrames, f:GetName())
Recap.Frame = f

f.Entries = {}

f:SetSize(380, 326)
f:SetPoint("CENTER")

f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetToplevel(true)
f:SetFrameStrata("DIALOG")

f:SetScript("OnHide", function(self)
    self.CurrentId = nil
    self.CurrentPlayer = nil
end)

f.title:SetText("Death Recap")

do
    local bg = _G[f:GetName().."DialogBG"]
    bg:SetTexture(0, 0, 0,0.6)

    local bgOverlay = f:CreateTexture(nil, "ARTWORK")
    bgOverlay:SetPoint("TOPLEFT", 10, -6)
    bgOverlay:SetPoint("BOTTOMRIGHT", -4,10)
    bgOverlay:SetTexture("Interface\\AddOns\\AscensionUI\\Textures\\DeathRecap")
    bgOverlay:SetTexCoord(0.00195312, 0.580078, 0.00390625, 0.996094)

    local titleBg = _G[f:GetName().."TitleBG"]
    titleBg:SetTexture(0, 0, 0, 0.8)

    local link = CreateFrame("BUTTON", f:GetName().."LinkButton", f, "UIPanelButtonTemplate")
    link:SetPoint("TOPLEFT", 9, -5)
    link:SetSize(50, 19)
    link:SetText("Link")

    link:SetScript("OnClick", function()
        local link = Recap:GetHyperlink(f.CurrentPlayer, f.CurrentId)
        if not ChatEdit_GetActiveWindow() then
            ChatFrame_OpenChat(link, DEFAULT_CHAT_FRAME)
        else
            ChatEdit_InsertLink(link)
        end
    end)

    link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Click here to link this death in chat")
        GameTooltip:Show()
    end)

    link:SetScript("OnLeave", GameTooltip_Hide)
end

for i = 1, 14 do
    local entry = Recap:CreateRecapEntry(f:GetName().."Entry"..i, f)
    tinsert(f.Entries, entry)
    entry:SetID(i)
    entry:SetPoint("LEFT", 10, 0)
    entry:SetPoint("RIGHT", -6, 0)
    if i == 1 then
        entry:SetPoint("BOTTOM", 0, 15)
        entry.Gravestone:Show()
        entry.TimeText:Hide()
    else
        entry:SetPoint("BOTTOM", f.Entries[i - 1], "TOP", 0, 0)
    end

    entry:Hide()
end

function Recap:OpenRecap(player, id) 
    if not player then
        player = UnitName("player")
    end
    if not id then
        id = Recap.CurrentRecap
    end

    if f:IsVisible() and f.CurrentPlayer == player and f.CurrentId == id then
        f:Hide()
        return
    end

    local events = Recap.Events[id]
    local lastEventTime

    if player and player ~= UnitName("player") then
        events = Recap.StoredEvents[player] and Recap.StoredEvents[player][id]
        f.title:SetText(format("Death Recap for %s", player))
    else
        f.title:SetText("Death Recap")
    end

    if not events then
        SendSystemMessage("Could not open Death Recap")
        SendSystemMessage("Reason: Death Recap Expired.")
        return
    else
        local lastEvent = events[#events]
        if lastEvent then
            lastEventTime = tonumber(lastEvent.eventTime)
            local timestamp = date("%I:%M:%S %p", lastEventTime)
            f.title:SetText(format("%s [%s]", f.title:GetText(), timestamp))
        end
    end

    for i = 1, 14 do
        local event = events[#events - (i - 1)]
        local entry = f.Entries[i]
        if event then
            -- eventTime, spell, attacker, damage, school, periodic, crit, healthPercent, lastEventTime
            entry:SetEvent(event.spell, event.school, event.periodic, event.attacker, event.isPlayer, event.eventTime, event.damage, event.crit, event.healthPercent, lastEventTime)
            entry:Show()
        else
            entry:Hide()
        end
    end
    f.CurrentPlayer = player
    f.CurrentId = id
    f:Show()
end
--
-- PVP Frame Mixin
--
local BG_QUEUE_ALERT_THRESHOLD_SECONDS = 10 * 60

PVPFrameMixin = {
    categories = {
        { name = "AscensionPVPFrameCasualFrame", label = "QUICK_MATCH", icon = "Interface\\Icons\\achievement_bg_winwsg", width = 788, canUse = function() return C_PVP:CanQueueCasual() end },
        { name = "AscensionPVPFrameRatedFrame", label = "RATED", label2 = "[ARENA_POINTS]", icon = "Interface\\Icons\\achievement_bg_killxenemies_generalsroom", width = 788, canUse = function() return C_PVP:CanQueueRated() end },
    },
    selectedIndex = 1,
    BONUS_BUTTON_TOOLTIPS = {
        RandomBG = {
            tooltipKey = "RANDOM_BG",
        },
        Holiday = {
            tooltipKey = "HOLIDAY_BG",
        },
        Skirmish = {
            tooltipKey = "SKIRMISH",
        },
        RandomBrawl = {
            tooltipKey = "RANDOM_BRAWL"
        },
        SpecialEvent = {
            func = function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(PVP_SPECIAL_EVENT_BUTTON_TT_TITLE, 1, 1, 1)
                GameTooltip:AddLine(PVP_SPECIAL_EVENT_BUTTON_TT_DESC, nil, nil, nil, true)
                GameTooltip:Show()
            end,
        }
    },
    RATED_BUTTON_TOOLTIPS = {
        [3] = {
            func = function(self)
                local _, _, _, teamPlayed, teamWins, seasonTeamPlayed, seasonTeamWins, _, _, teamRank = GetArenaTeam(3)
                if teamRank == 0 then
                    teamRank = PVP_TIER_UNRANKED
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if C_Player:IsDefaultClass() then
                    GameTooltip:SetText(ARENA_TEAM_3V3)
                else
                    GameTooltip:SetText(ARENA_TEAM_1V1)
                end
                if not toboolean(self:IsEnabled()) then
                    GameTooltip:AddLine(ARENA_ONLY_ACTIVE_DURING_FRENZY, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true)
                    GameTooltip_AddSpacer(GameTooltip)
                end
                GameTooltip:AddLine(ARENA_TEAM_RANK..teamRank, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_WEEKLY_STATS)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..teamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..teamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(teamPlayed - teamWins), 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_SEASONAL_STATS, nil, nil, nil, false)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..seasonTeamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..seasonTeamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(seasonTeamPlayed - seasonTeamWins), 1, 1, 1)
                GameTooltip:Show()
            end,
        },
        [2] = {
            func = function(self)
                local _, _, _, teamPlayed, teamWins, seasonTeamPlayed, seasonTeamWins, _, _, teamRank, personalRating = GetArenaTeam(2)
                if teamRank == 0 then
                    teamRank = PVP_TIER_UNRANKED
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(ARENA_TEAM_3V3)
                GameTooltip:AddLine(ARENA_TEAM_RANK..teamRank, 1, 1, 1)
                GameTooltip:AddLine(ARENA_TEAM_PERSONAL_RATING..personalRating, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_WEEKLY_STATS)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..teamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..teamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(teamPlayed - teamWins), 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_SEASONAL_STATS, nil, nil, nil, false)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..seasonTeamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..seasonTeamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(seasonTeamPlayed - seasonTeamWins), 1, 1, 1)
                GameTooltip:Show()
            end,
        },
        [1] = {
            func = function(self)
                local _, _, _, teamPlayed, teamWins, seasonTeamPlayed, seasonTeamWins, _, _, teamRank, personalRating = GetArenaTeam(1)
                if teamRank == 0 then
                    teamRank = PVP_TIER_UNRANKED
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(ARENA_TEAM_2V2)
                GameTooltip:AddLine(ARENA_TEAM_RANK..teamRank, 1, 1, 1)
                GameTooltip:AddLine(ARENA_TEAM_PERSONAL_RATING..personalRating, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_WEEKLY_STATS)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..teamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..teamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(teamPlayed - teamWins), 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(ARENA_SEASONAL_STATS, nil, nil, nil, false)
                GameTooltip:AddLine(ARENA_GAMES_PLAYED_COLON..seasonTeamPlayed, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_WON_COLON..seasonTeamWins, 1, 1, 1)
                GameTooltip:AddLine(ARENA_GAMES_LOST_COLON..(seasonTeamPlayed - seasonTeamWins), 1, 1, 1)
                GameTooltip:AddLine(" ")
                if self.FrenzyActive then
                    GameTooltip:AddLine(TOOLTIP_ARENA_FRENZY_ACTIVE, 1, 0.5, 0, true)
                end
                GameTooltip:Show()
            end,
        }
    },
    MIN_LEVEL = 10,
}

function PVPFrameMixin:OnLoad()
    ArenaFrame:UnregisterAllEvents()
    PVPBattlegroundFrame:UnregisterAllEvents()
    PVPFrame:UnregisterAllEvents()
    ArenaRegistrarFrame:UnregisterAllEvents()

    -- We still depend on the BattlefieldFrame for minmap icon and stuff inside bgs
    BattlefieldFrame:UnregisterEvent("BATTLEFIELDS_SHOW")
    BattlefieldFrame:UnregisterEvent("BATTLEFIELDS_CLOSED")

    self:HookEvent("NPC_PVPQUEUE_ANYWHERE")
    self:HookEvent("UPDATE_BATTLEFIELD_STATUS")
    self:HookEvent("PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE")
    self:HookEvent("PLAYER_ENTERING_WORLD")
    self:HookEvent("PETITION_VENDOR_SHOW")
    self:HookEvent("PETITION_VENDOR_CLOSED")
    self:HookEvent("ASCENSION_BG_QUEUE_ALERT")
    --self:HookEvent("BATTLEFIELDS_SHOW")
    --self:HookEvent("BATTLEFIELDS_CLOSED") -- GetBattlefieldList sends this event just before BATTLEFIELDS_SHOW, which creates an endless loop of open / close

    self.HonorBar.type = "honor"
    self.HonorBar.IconFrame.Icon:SetAtlas("pvpqueue-sidebar-honorbar-badge-"..strlower(UnitFactionGroup("player", Const.TextureKit.IgnoreAtlasSize)))
    self.HonorBar.IconFrame.IconBG:SetAtlas("pvpqueue-sidebar-honorbar-background-"..strlower(UnitFactionGroup("player", Const.TextureKit.IgnoreAtlasSize)))
    self.HonorBar.IconFrame.tooltip = {
        HONOR_POINTS,
        TOOLTIP_HONOR_POINTS,
    }
    self.HonorBar:Update()

    self.ArenaBar.type = "arena"
    self.ArenaBar.IconFrame.Icon:SetTexture("Interface\\PVPFrame\\PVP-ArenaPoints-Icon")
    self.ArenaBar.IconFrame.IconBG:SetAtlas("pvpqueue-sidebar-honorbar-background-horde", Const.TextureKit.IgnoreAtlasSize) -- horde because the red matches the arena point icon better
    self.ArenaBar.IconFrame.tooltip = {
        ARENA_POINTS,
        TOOLTIP_ARENA_POINTS_TOTAL,
    }
    self.ArenaBar:Update()
end

function PVPFrameMixin:OnShow()
    if C_Player:GetLevel() < self.MIN_LEVEL then
        self:Hide()
        return
    end
    local parent = self:GetParent():GetParent()
    if (UnitFactionGroup("player") == "Horde") then
		parent.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\INV_BannerPVP_01")
	else
		parent.PortraitFrame.portrait:SetPortraitTexture("Interface\\Icons\\INV_BannerPVP_02")
	end
	parent.TitleText:SetText(PLAYER_V_PLAYER)
    
    parent:SetSize(parent.BASE_WIDTH, parent.BASE_HEIGHT)

    for i = 1, 3 do
        local button = parent["Button"..i]
        local category = self.categories[i]

        if not category then
            button:Hide()
        else
            button:Show()
            button.Icon:SetPortraitTexture(category.icon)
            if category.label2 then
                local label = _G[category.label] or category.label
                local label2 = _G[category.label2] or category.label2

                -- might want to expand this in the future but theres only arena points for now.
                label2 = label2:gsub("%[ARENA_POINTS%]", "|TInterface\\PVPFrame\\PVP-ArenaPoints-Icon:18:18:0:-4|t |cffFFFFFF"..GetArenaCurrency().."|r")

                label = label .. "\n" .. label2
                button.Name:SetText(label)
            else
                button.Name:SetText(_G[category.label] or category.label)
            end

            local canUse, reason = category.canUse()

            if not canUse then
                button:Disable()
                button.BG:SetDesaturated(true)
                button.Icon:SetDesaturated(true)
                button.Name:SetFontObject("GameFontDisableLarge")
                button.tooltip = _G[reason] or reason
            else
                button:Enable()
                button.BG:SetDesaturated(false)
                button.Icon:SetDesaturated(false)
                button.Name:SetFontObject("GameFontNormalLarge")
                button.tooltip = nil
            end
        end
    end

    self:ShowCategory(self.selectedIndex)
    UpdateMicroButtons()
end

function PVPFrameMixin:OnHide()
    if self.fromGossip then
        ClosePetitionVendor()
        self.fromGossip = false
    end
end

function PVPFrameMixin:ShowCategory(index)
    index = index or 1
    local data = self.categories[index]
    local parent = self:GetParent():GetParent()

    if not data then return end

    self.selectedIndex = index

    for i = 1, 3 do
        local button = parent["Button"..i]
        local category = self.categories[i]

        if category then
            local frame = _G[category.name]
            button:Show()

            if i == self.selectedIndex and category.canUse() then
                if frame then frame:Show() end
                button.BG:SetTexCoord(0.00390625, 0.87890625, 0.59179688, 0.66992188)
                if category.width then
                    parent:SetWidth(category.width)
                else
                    parent:SetWidth(parent.BASE_WIDTH)
                end
            else
                if frame then frame:Hide() end
                button.BG:SetTexCoord(0.00390625, 0.87890625, 0.75195313, 0.83007813)
            end
        else
            button:Hide()
        end
    end
end

function PVPFrameMixin:NPC_PVPQUEUE_ANYWHERE()
    PlaySound("igCharacterInfoTab")
    AscensionLFGFrame:ShowFrame("AscensionPVPFrame", 1)
end

function PVPFrameMixin:UPDATE_BATTLEFIELD_STATUS()
    PVPBattleground_UpdateQueueStatus()
    self.CasualFrame:UpdateQueueButton()
    self.RatedFrame:UpdateQueueButton()
end

function PVPFrameMixin:PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE()
    RequestBattlegroundInstanceInfo(1)
end

function PVPFrameMixin:PLAYER_ENTERING_WORLD()
    self:UnhookEvent("PLAYER_ENTERING_WORLD")
    RequestBattlegroundInstanceInfo(1)
end

function PVPFrameMixin:PETITION_VENDOR_SHOW()
    PlaySound("igCharacterInfoTab")
    AscensionLFGFrame:ShowFrame("AscensionPVPFrame", 2)
    self.fromGossip = true
end

function PVPFrameMixin:PETITION_VENDOR_CLOSED()
    HideUIPanel(AscensionLFGFrame)
end

function PVPFrameMixin:ASCENSION_BG_QUEUE_ALERT(timeInQueue, currentQueueID, suggestedQueueID)
    if not timeInQueue or timeInQueue < BG_QUEUE_ALERT_THRESHOLD_SECONDS then
        return
    end

    StaticPopup_Show("BATTLEGROUND_EXPAND_SEARCH", nil, nil, suggestedQueueID)
end
--
-- Casual PVP Mixin
--
CasualPVPMixin = {
    InlineSkirmishes = false,
}

function CasualPVPMixin:OnLoad()
    self:HookEvent("PARTY_LEADER_CHANGED")
    self:HookEvent("PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE")

    local bonusFrame = self.BonusFrame
    self.buttons = {
        bonusFrame.RandomBGButton,
        bonusFrame.CallToArmsButton1,
        bonusFrame.CallToArmsButton2,
        bonusFrame.RandomBrawlButton,
        bonusFrame.Skirmish1v1Button,
        bonusFrame.Skirmish2v2Button,
        bonusFrame.Skirmish3v3Button,
    }

    local button = bonusFrame.RandomBGButton
    button.Title:SetText(BONUS_BUTTON_RANDOM_BG_TITLE)
    button.tooltipTableKey = "RandomBG"

    button = bonusFrame.CallToArmsButton1
    button.tooltipTableKey = "Holiday"

    button = bonusFrame.CallToArmsButton2
    button.tooltipTableKey = "Holiday"

    button = bonusFrame.RandomBrawlButton
    button.tooltipTableKey = "RandomBrawl"

    -- Arena frames need some special changes
    button = bonusFrame.Skirmish1v1Button
    button.Title:SetText(format(PVP_TEAMTYPE, 1, 1))
    button.Title:ClearAndSetPoint("LEFT", button.Anchor, 0, 6)
    button.Title:SetPoint("RIGHT", button.Anchor, 0, 6)
    button.Title:SetJustifyH("CENTER")

    button.LevelRequirement:SetText(ARENA_SKIRMISH_SOLO_QUEUE)
    button.LevelRequirement:ClearAndSetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -1)
    button.LevelRequirement:SetPoint("TOPRIGHT", button.Title, "BOTTOMRIGHT", 0, -1)
    button.LevelRequirement:SetJustifyH("CENTER")
    button.LevelRequirement:Show()

    button.bgIndex = 3
    button.teamSize = 1
    button.tooltipTableKey = "Skirmish"
    button.tooltipFormat = { 1, 1 }

    button = bonusFrame.Skirmish2v2Button
    button.Title:SetText(format(PVP_TEAMTYPE, 2, 2))
    button.Title:ClearAndSetPoint("LEFT", button.Anchor, 0, 6)
    button.Title:SetPoint("RIGHT", button.Anchor, 0, 6)
    button.Title:SetJustifyH("CENTER")

    button.LevelRequirement:SetText(ARENA_SKIRMISH_SOLO_QUEUE)
    button.LevelRequirement:ClearAndSetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -1)
    button.LevelRequirement:SetPoint("TOPRIGHT", button.Title, "BOTTOMRIGHT", 0, -1)
    button.LevelRequirement:SetJustifyH("CENTER")
    button.LevelRequirement:Show()

    button.bgIndex = 1
    button.teamSize = 2
    button.tooltipTableKey = "Skirmish"
    button.tooltipFormat = { 2, 2 }

    button = bonusFrame.Skirmish3v3Button
    button.Title:SetText(format(PVP_TEAMTYPE, 3, 3))
    button.Title:ClearAndSetPoint("LEFT", button.Anchor, 0, 6)
    button.Title:SetPoint("RIGHT", button.Anchor, 0, 6)
    button.Title:SetJustifyH("CENTER")

    button.LevelRequirement:SetText(ARENA_SKIRMISH_SOLO_QUEUE)
    button.LevelRequirement:ClearAndSetPoint("TOPLEFT", button.Title, "BOTTOMLEFT", 0, -1)
    button.LevelRequirement:SetPoint("TOPRIGHT", button.Title, "BOTTOMRIGHT", 0, -1)
    button.LevelRequirement:SetJustifyH("CENTER")
    button.LevelRequirement:Show()

    button.bgIndex = 2
    button.teamSize = 3
    button.tooltipTableKey = "Skirmish"
    button.tooltipFormat = { 3, 3 }
end

function CasualPVPMixin:OnShow()
    self:HookEvent("BATTLEFIELDS_SHOW")
    if self.selectedButton then
        for i, targetButton in ipairs(self.buttons) do
            if targetButton == self.selectedButton then
                if i > 4 then
                    GetBattlefieldList(6, 0, 0)
                else
                    GetBattlefieldList(targetButton.bgID)
                end
                break
            end
        end
    end

    local honorInset = self:GetParent().HonorInset
    honorInset.RoleSelect:Hide()
    honorInset.HonorLevelDisplay:SetPoint("TOP", honorInset.RoleSelect, "TOP", 0, -24)
    self:Update()
end

function CasualPVPMixin:OnHide()
    self:UnhookEvent("BATTLEFIELDS_SHOW")
end

function CasualPVPMixin:Update()
    -- Update Queue Buttons
    local bonusFrame = self.BonusFrame
    local lastButton = nil

    for _, button in ipairs(self.buttons) do
        button:SetEnabled(true)
    end

    -- Setup Random BG button
    do
        local bgName, canQueue, battleGroundIndex, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, minLevel = C_PVP:GetRandomBGInfo()
        local button = bonusFrame.RandomBGButton
        button.canQueue = canQueue -- this is always true for random BGs
        button.bgIndex = battleGroundIndex
        button.bgID = battleGroundID
        button.name = bgName
        lastButton = button

        local offsetX = -16
        local parent = button.Anchor
        local relativePoint = "RIGHT"

        if winHonorAmount and winHonorAmount > 0 then
            button.RewardHonor:Show()
            button.RewardHonor:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
            button.RewardHonor.winHonor = winHonorAmount
            button.RewardHonor.lossHonor = lossHonorAmount

            offsetX = -1
            parent = button.RewardHonor
            relativePoint = "LEFT"
        else
            button.RewardHonor:Hide()
            button.RewardHonor.winHonor = nil
            button.RewardHonor.lossHonor = nil
        end

        if winArenaAmount and winArenaAmount > 0 then
            button.RewardArena:Show()
            button.RewardArena:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
            button.RewardArena.winArenaPoints = winArenaAmount
            button.RewardArena.lossArenaPoints = lossArenaAmount

            offsetX = -1
            parent = button.RewardArena
            relativePoint = "LEFT"
        else
            button.RewardArena:Hide()
            button.RewardArena.winArenaPoints = nil
            button.RewardArena.lossArenaPoints = nil
        end
    end

    -- reset inline skirmishes
    self.InlineSkirmishes = false

    -- Setup Call To Arms
    do
        local holidays = C_PVP:GetHolidayBGInfo()

        for i = 1, 2 do
            local button = bonusFrame["CallToArmsButton"..i]
            if holidays[i] and holidays[i][2] then -- [2] = canEnter
                local bgName, canEnter, battleGroundIndex, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, minLevel = unpack(holidays[i])
                button.canQueue = canEnter
                button.bgIndex = battleGroundIndex
                button.bgID = battleGroundID
                button.name = bgName
                button:SetEnabled(true)
                button:Show()
                button.Title:SetText(format(PVP_CALL_TO_ARMS, bgName))

                local offsetX = -16
                local parent = button.Anchor
                local relativePoint = "RIGHT"

                if winHonorAmount and winHonorAmount > 0 then
                    button.RewardHonor:Show()
                    button.RewardHonor:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
                    button.RewardHonor.winHonor = winHonorAmount
                    button.RewardHonor.lossHonor = lossHonorAmount

                    offsetX = -1
                    parent = button.RewardHonor
                    relativePoint = "LEFT"
                else
                    button.RewardHonor:Hide()
                    button.RewardHonor.winHonor = nil
                    button.RewardHonor.lossHonor = nil
                end

                if winArenaAmount and winArenaAmount > 0 then
                    button.RewardArena:Show()
                    button.RewardArena:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
                    button.RewardArena.winArenaPoints = winArenaAmount
                    button.RewardArena.lossArenaPoints = lossArenaAmount

                    offsetX = -1
                    parent = button.RewardArena
                    relativePoint = "LEFT"
                else
                    button.RewardArena:Hide()
                    button.RewardArena.winArenaPoints = nil
                    button.RewardArena.lossArenaPoints = nil
                end

                button:ClearAndSetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)
                lastButton = button

                -- We have at least one CTA, make skirmishes inline
                -- default classes dont have 1v1 so we never need to inline
                self.InlineSkirmishes = not IsDefaultClass("player")
            else
                button.canQueue = false
                button.Title:SetText(PVP_CALL_TO_ARMS_DISABLED)
                button:SetEnabled(false)

                button.RewardHonor:Hide()
                button.RewardHonor.winHonor = nil
                button.RewardHonor.lossHonor = nil

                button.RewardArena:Hide()
                button.RewardArena.winArenaPoints = nil
                button.RewardArena.lossArenaPoints = nil

                button:Hide()

                if self.selectedButton == button then
                    self.selectedButton = nil
                end
            end
        end
    end

    -- setup brawl button
    do
        local bgName, canQueue, battleGroundIndex, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, minLevel = C_PVP:GetRandomBrawlBGInfo()
        local button = bonusFrame.RandomBrawlButton
        button.canQueue = canQueue
        button.bgIndex = battleGroundIndex
        button.bgID = battleGroundID
        button.name = bgName

        if canQueue then
            local offsetX = -16
            local parent = button.Anchor
            local relativePoint = "RIGHT"

            button.Title:SetText(bgName)
            button.tooltipFormat = { bgName }

            if winHonorAmount and winHonorAmount > 0 then
                button.RewardHonor:Show()
                button.RewardHonor:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
                button.RewardHonor.winHonor = winHonorAmount
                button.RewardHonor.lossHonor = lossHonorAmount

                offsetX = -1
                parent = button.RewardHonor
                relativePoint = "LEFT"
            else
                button.RewardHonor:Hide()
                button.RewardHonor.winHonor = nil
                button.RewardHonor.lossHonor = nil
            end

            if winArenaAmount and winArenaAmount > 0 then
                button.RewardArena:Show()
                button.RewardArena:ClearAndSetPoint("RIGHT", parent, relativePoint, offsetX, 0)
                button.RewardArena.winArenaPoints = winArenaAmount
                button.RewardArena.lossArenaPoints = lossArenaAmount

                offsetX = -1
                parent = button.RewardArena
                relativePoint = "LEFT"
            else
                button.RewardArena:Hide()
                button.RewardArena.winArenaPoints = nil
                button.RewardArena.lossArenaPoints = nil
            end
            button:ClearAndSetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)
            lastButton = button
            button:Show()

            -- we have a brawl, so make skirmishes inline
            self.InlineSkirmishes = not IsDefaultClass("player")
        else
            button.Title:SetText(PVP_RANDOM_BRAWL_CLOSED)
            button:SetEnabled(false)
            button:Hide()

            button.RewardHonor:Hide()
            button.RewardHonor.winHonor = nil
            button.RewardHonor.lossHonor = nil

            button.RewardArena:Hide()
            button.RewardArena.winArenaPoints = nil
            button.RewardArena.lossArenaPoints = nil

            if self.selectedButton == button then
                self.selectedButton = nil
            end
        end
    end



    if self.InlineSkirmishes then -- inline
        for i = 1, 3 do
            local button = bonusFrame["Skirmish"..i.."v"..i.."Button"]
            if button:IsShown() then
                if i == 1 then
                    button:ClearAndSetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)
                else
                    button:ClearAndSetPoint("TOPLEFT", lastButton, "TOPRIGHT", 1, 0)
                end
                button:SetWidth(118)
                button.Title:SetPoint("LEFT", button.Anchor, "LEFT", 0, 6)
                button.Title:SetJustifyH("CENTER")
                button.LevelRequirement:SetJustifyH("CENTER")
                lastButton = button
            end
        end
    else -- stacked
        for i = 1, 3 do
            local button = bonusFrame["Skirmish"..i.."v"..i.."Button"]
            if button:IsShown() then
                button:ClearAndSetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -1)

                button:SetWidth(365)
                button.Title:SetPoint("LEFT", button.Anchor, "LEFT", 20, 6)
                button.Title:SetJustifyH("LEFT")
                button.LevelRequirement:SetJustifyH("LEFT")
                lastButton = button
            end
        end
    end

    self:UpdateButtons()

    if not self.selectedButton then
        self:SelectButton(bonusFrame.RandomBGButton)
    else
        self:UpdateQueueButton()
    end
end

function CasualPVPMixin:UpdateButtons()
    local numButtons = 0

    if self.InlineSkirmishes then
        numButtons = numButtons - (IsDefaultClass("player") and 1 or 2)
    end

    for _, button in ipairs(self.buttons) do
        if button:IsVisible() then
            numButtons = numButtons + 1
        end
    end

    local totalHeight = self.BonusFrame:GetHeight() - numButtons - 9
    local buttonHeight = floor(totalHeight / numButtons)

    for _, button in ipairs(self.buttons) do
        button:SetHeight(buttonHeight)
        local rewardSize = min(buttonHeight / 2, 38)
        button.RewardHonor:SetSize(rewardSize, rewardSize)
        button.RewardArena:SetSize(rewardSize, rewardSize)
    end

    if GameEventUtil.IsAnyEventActive(Enum.GameEvent.ArenaFrenzySunday, Enum.GameEvent.ArenaFrenzyThursday) then
        self.BonusFrame.Skirmish2v2Button.FrenzyTexture:Show()
        self.BonusFrame.Skirmish2v2Button.FrenzyActive = true
    else
        self.BonusFrame.Skirmish2v2Button.FrenzyTexture:Hide()
        self.BonusFrame.Skirmish2v2Button.FrenzyActive = false
    end

    local isMaxLevel = C_Player:IsMaxLevel()
    local isDefaultClass = IsDefaultClass("player")
    local can1v1 = not isDefaultClass
    local lvlReqFont = "GameFontNormalMed3"
    local titleFont = "GameFontHighlightLarge"
    -- scale down size for skrimishes for it to fit the frame if there are more than 5 (3) buttons
    if (numButtons > 3) then
        lvlReqFont = "GameFontDisableSmall"
        titleFont = "GameFontHighlight"
    end
    
    for i = 1, 3 do
        local button = self.BonusFrame["Skirmish"..i.."v"..i.."Button"]
        button.LevelRequirement:SetFontObject(lvlReqFont)
        button.Title:SetFontObject(titleFont)
        if i == 1 and not (can1v1) then
            button:Hide()
        else
            button:Show()
            button:SetEnabled(isMaxLevel)
        end
    end
end

function CasualPVPMixin:SelectButton(button)
    if self.selectedButton then
        self.selectedButton.SelectedTexture:Hide()
        if self.selectedButton.FrenzyActive then
            self.selectedButton.FrenzyTexture:Show()
        end
    end

    button.SelectedTexture:Show()
    button.FrenzyTexture:Hide()
    self.selectedButton = button

    for i, targetButton in ipairs(self.buttons) do
        if targetButton == button then
            if i > 4 then
                GetBattlefieldList(6, 0, 0)
            else
                if button.bgID then
                    GetBattlefieldList(button.bgID, 0, 0)
                end
            end
            break
        end
    end

    self:UpdateQueueButton()
end

function CasualPVPMixin:UpdateQueueButton()
    if self.selectedButton then
        for i = 1, MAX_BATTLEFIELD_QUEUES do
            local status, mapName, _, _, _, teamSize, ratedMatch = GetBattlefieldStatus(i)
            if status ~= "none" then
                if mapName == self.selectedButton.name or (teamSize == self.selectedButton.teamSize and not ratedMatch) then
                    self.QueueButton:Hide()
                    self.SoloQueueButton:Hide()
                    self.leaveQueueIndex = i
                    self.LeaveQueueButton:Show()
                    return
                end
            end
        end
    end

    self.QueueButton:Show()
    self.SoloQueueButton:Show()
    self.leaveQueueIndex = nil
    self.LeaveQueueButton:Hide()

    local partyMembers = GetNumPartyMembers()
    local raidMembers = GetNumRaidMembers()
    local groupMembers = max(partyMembers, raidMembers)
    local pvpPower = C_Player:GetPvPPower()
    local disableReason, soloDisableReason
    local isArena = false

    if self.selectedButton == self.BonusFrame.Skirmish1v1Button then -- 1v1 queue
        disableReason = PVP_ARENA_NO_GROUP_IN_SOLO_QUEUE

        if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
            soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
        end
        isArena = true
    end

    if self.selectedButton == self.BonusFrame.Skirmish2v2Button then -- 2v2 queue
        disableReason = PVP_ARENA_NO_GROUP_IN_SOLO_QUEUE
        if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
            soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
        end
        isArena = true
    end

    if self.selectedButton == self.BonusFrame.Skirmish3v3Button then -- 3v3 queue
        disableReason = PVP_ARENA_NO_GROUP_IN_SOLO_QUEUE
        if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
            soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
        end
        isArena = true
    end

    if isArena and not ChallengeUtil.CanQueueArenas() then
        soloDisableReason = CHALLENGES_NO_ARENAS
        disableReason = soloDisableReason
    elseif not isArena and not ChallengeUtil.CanQueueBattlegrounds() then
        soloDisableReason = CHALLENGES_NO_BATTLEGROUNDS
        disableReason = soloDisableReason
    end

    self.QueueButton:UpdateDisableReason(disableReason)
    self.SoloQueueButton:UpdateDisableReason(soloDisableReason)
end

function CasualPVPMixin:PARTY_LEADER_CHANGED()
    self:UpdateQueueButton()
end

function CasualPVPMixin:PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE()
    self:Update()
end

function CasualPVPMixin:BATTLEFIELDS_SHOW()
    self:Update()
end
--
-- Casual Activity Button Mixin
--
PVPCasualActivityButtonMixin = {}

function PVPCasualActivityButtonMixin:OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn")
	self:GetParent():GetParent():SelectButton(self)
end

function PVPCasualActivityButtonMixin:OnEnter()
	if not self.tooltipTableKey then
		return
	end

	local tooltipTbl = PVPFrameMixin.BONUS_BUTTON_TOOLTIPS[self.tooltipTableKey]

	if not tooltipTbl then
		return
	end

	if (tooltipTbl.func) then
		tooltipTbl.func(self)
	else
        local title = _G["BONUS_BUTTON_"..tooltipTbl.tooltipKey.."_TITLE"]
        local desc = _G["BONUS_BUTTON_"..tooltipTbl.tooltipKey.."_DESC"]

        if self.tooltipFormat then
            title = format(title, unpack(self.tooltipFormat))
            desc = format(desc, unpack(self.tooltipFormat))
        end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(title, 1, 1, 1)
		GameTooltip:AddLine(desc, nil, nil, nil, true)
        if self.FrenzyActive then
            GameTooltip:AddLine(TOOLTIP_ARENA_FRENZY_ACTIVE, 1, 0.5, 0, true)
        end
		GameTooltip:Show()
	end
end

function PVPCasualActivityButtonMixin:OnMouseDown()
	if self:IsEnabled() == 1 then
		self.Anchor:SetPoint("TOPLEFT", -1, -1)
	end
end

function PVPCasualActivityButtonMixin:OnMouseUp()
	self.Anchor:SetPoint("TOPLEFT", 0, 0)
end

function PVPCasualActivityButtonMixin:OnLeave()
	GameTooltip_Hide()
end

function PVPCasualActivityButtonMixin:SetEnabled(enabled)
    if enabled then
        self.Title:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
        self.NormalTexture:SetDesaturated(false)
        self:Enable()
    else
        self.Title:SetTextColor(DISABLED_FONT_COLOR.r, DISABLED_FONT_COLOR.g, DISABLED_FONT_COLOR.b)
        self.NormalTexture:SetDesaturated(true)
        self:Disable()
    end
end

--
-- PVP Rated Frame Mixin
--
RatedPVPMixin = {}

local function OnShowGossip()
    AscensionLFGFrame:ShowFrame("AscensionPVPFrame", 2)
    CloseGossip()
end

function RatedPVPMixin:OnLoad()
    self:HookEvent("ASCENSION_CUSTOM_PVP_REWARD_INFO_AVAILABLE")
    self:HookEvent("PARTY_LEADER_CHANGED")
    self:HookEvent("ARENA_TEAM_UPDATE")

    self.buttons = {
        self.BonusFrame.Arena1v1,
        self.BonusFrame.Arena2v2,
        self.BonusFrame.Arena3v3,
    }

    local isDefaultClass = C_Player:IsDefaultClass()
    self.BonusFrame.Arena1v1.teamSize = isDefaultClass and 3 or 1
    self.BonusFrame.Arena2v2.teamSize = 2
    self.BonusFrame.Arena3v3.teamSize = 3

    local arenaNPCs = C_Gossip:MakeGroup(18897, 19856, 19861, 29534, 30611,
                                         32329, 500751, 18439, 18895, 19858,
                                         19859, 19909, 19911, 19912, 19915,
                                         19923, 19925, 20497, 20499, 21235,
                                         26760, 29533, 29568, 30610, 32330,
                                         32332, 32333)

    C_Gossip:RedirectNPCs(arenaNPCs, OnShowGossip)
end

function RatedPVPMixin:OnShow()
    if GameEventUtil.IsAnyEventActive(Enum.GameEvent.ArenaFrenzySunday,
            Enum.GameEvent.ArenaFrenzyThursday,
            Enum.GameEvent.ArenaFrenzySundayLate,
            Enum.GameEvent.ArenaFrenzyThursdayLate)
    then
        self.BonusFrame.Arena2v2.FrenzyTexture:Show()
        self.BonusFrame.Arena2v2.FrenzyActive = true
    else
        self.BonusFrame.Arena2v2.FrenzyTexture:Hide()
        self.BonusFrame.Arena2v2.FrenzyActive = false
    end

    local has3v3Frenzy = IsDefaultClass("player")
    if has3v3Frenzy then
        self.BonusFrame.Arena2v2:ClearAndSetPoint("TOP", self.BonusFrame, "TOP", 0, -9)
        self.BonusFrame.Arena3v3:ClearAndSetPoint("TOP", self.BonusFrame.Arena2v2, "BOTTOM", 0, -1)
        self.BonusFrame.Arena1v1:ClearAndSetPoint("TOP", self.BonusFrame.Arena3v3, "BOTTOM", 0, -1)
    else
        self.BonusFrame.Arena1v1:ClearAndSetPoint("TOP", self.BonusFrame, "TOP", 0, -9)
        self.BonusFrame.Arena2v2:ClearAndSetPoint("TOP", self.BonusFrame.Arena1v1, "BOTTOM", 0, -1)
        self.BonusFrame.Arena3v3:ClearAndSetPoint("TOP", self.BonusFrame.Arena2v2, "BOTTOM", 0, -1)
    end

    if not has3v3Frenzy or GameEventUtil.IsAnyEventActive(Enum.GameEvent.ArenaFrenzySundayLate,
            Enum.GameEvent.ArenaFrenzyThursdayLate)
    then
        self.BonusFrame.Arena1v1:SetEnabled(true)
        self.BonusFrame.Arena1v1:SetAlpha(1)
    else
        self.BonusFrame.Arena1v1:SetEnabled(false)
        self.BonusFrame.Arena1v1:SetAlpha(0.4)
    end

    if not self.selectedButton then
        self:SelectButton(self.BonusFrame.Arena2v2)
    else
        self:UpdateQueueButton()
    end

    local honorInset = self:GetParent().HonorInset
    honorInset.RoleSelect:Show()
    honorInset.HonorLevelDisplay:SetPoint("TOP", honorInset.RoleSelect, "BOTTOM", 0, 0)
    GetBattlefieldList(6, 0, 0) -- Update to use Arena JoinBattlefield
end

function RatedPVPMixin:SelectButton(button)
    if self.selectedButton then
        self.selectedButton.SelectedTexture:Hide()

        if self.selectedButton.FrenzyActive then
            self.selectedButton.FrenzyTexture:Show()
        end
    end

    button.SelectedTexture:Show()
    button.FrenzyTexture:Hide()
    self.selectedButton = button

    self:UpdateQueueButton()
end

function RatedPVPMixin:UpdateQueueButton()
    if self.selectedButton then
        for i = 1, MAX_BATTLEFIELD_QUEUES do
            local status, mapName, _, _, _, teamSize, ratedMatch = GetBattlefieldStatus(i)
            if status ~= "none" then
                if mapName == self.selectedButton.name or teamSize == self.selectedButton.teamSize and ratedMatch then
                    self.QueueButton:Hide()
                    self.SoloQueueButton:Hide()
                    self.leaveQueueIndex = i
                    self.LeaveQueueButton:Show()
                    return
                end
            end
        end
    end

    self.QueueButton:Show()
    self.SoloQueueButton:Show()
    self.leaveQueueIndex = nil
    self.LeaveQueueButton:Hide()

    local partyMembers = GetNumPartyMembers()
    local raidMembers = GetNumRaidMembers()
    local groupMembers = max(partyMembers, raidMembers)
    local pvpPower = C_Player:GetPvPPower()

    local disableReason, soloDisableReason
    local isArena = false

    if C_Player:IsDefaultClass() then
        if self.selectedButton == self.BonusFrame.Arena1v1 then -- 3v3 group frenzy
            soloDisableReason = PVP_ARENA_NO_SOLO_IN_GROUP_QUEUE
            if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
                disableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
            end
            isArena = true
        end
    else
        if self.selectedButton == self.BonusFrame.Arena1v1 then -- 1v1 queue
            disableReason = PVP_ARENA_NO_GROUP_IN_SOLO_QUEUE
            if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
                soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
            end
            isArena = true
        end
    end

    if self.selectedButton == self.BonusFrame.Arena2v2 then -- 2v2 queue
        if groupMembers > 1 then
            disableReason = PVP_ARENA_NEED_LESS:format(groupMembers - 1)
        elseif groupMembers < 1 then
            disableReason = PVP_ARENA_NEED_MORE:format(1 - groupMembers)
        end

        if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
            soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
            disableReason = soloDisableReason
        end
        isArena = true
    end

    if self.selectedButton == self.BonusFrame.Arena3v3 then -- 3v3 queue
        if C_Player:IsDefaultClass() then
            disableReason = PVP_ARENA_NO_GROUP_IN_SOLO_QUEUE
        else
            if groupMembers > 2 then
                disableReason = PVP_ARENA_NEED_LESS:format(groupMembers - 2)
            elseif groupMembers < 2 then
                disableReason = PVP_ARENA_NEED_MORE:format(2 - groupMembers)
            end
        end

        if pvpPower < 250 and not C_Realm.IsDevelopment() and not IsCustomClass() then
            soloDisableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
            disableReason = PVP_ARENA_LOW_POWER:format(pvpPower, 250)
        end
        isArena = true
    end

    if isArena and not ChallengeUtil.CanQueueArenas() then
        soloDisableReason = CHALLENGES_NO_ARENAS
        disableReason = soloDisableReason
    elseif not isArena and not ChallengeUtil.CanQueueBattlegrounds() then
        soloDisableReason = CHALLENGES_NO_BATTLEGROUNDS
        disableReason = soloDisableReason
    end

    self.QueueButton:UpdateDisableReason(disableReason)
    self.SoloQueueButton:UpdateDisableReason(soloDisableReason)
end

function RatedPVPMixin:PARTY_LEADER_CHANGED()
    self:UpdateQueueButton()
end

function RatedPVPMixin:ARENA_TEAM_UPDATE()
    if self:IsVisible() then
        for _, button in ipairs(self.buttons) do
            button:Update()
        end
    end
end

function RatedPVPMixin:ASCENSION_CUSTOM_PVP_REWARD_INFO_AVAILABLE()
    local _, _, _, lossPoints, loss1v1Points, winPoints, win1v1Points = Ascension_GetArenaRewardInfo()
    local reward = self.BonusFrame.Arena1v1.Reward

    reward.winArenaPoints = win1v1Points
    reward.lossArenaPoints = loss1v1Points
    reward:Show()

    reward = self.BonusFrame.Arena2v2.Reward
    reward.winArenaPoints = winPoints
    reward.lossArenaPoints = lossPoints
    reward:Show()

    reward = self.BonusFrame.Arena3v3.Reward
    reward.winArenaPoints = winPoints
    reward.lossArenaPoints = lossPoints
    reward:Show()
end

--
-- PVP Rated Activity Button Mixin
--
PVPRatedActivityButtonMixin = {}

function PVPRatedActivityButtonMixin:OnClick()
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:GetParent():GetParent():SelectButton(self)
end

function PVPRatedActivityButtonMixin:OnEnter()
    local tooltipTbl = PVPFrameMixin.RATED_BUTTON_TOOLTIPS[self:GetID()]

	if not tooltipTbl then
		return
	end

	if tooltipTbl.func then
		tooltipTbl.func(self)
	end
end

function PVPRatedActivityButtonMixin:Update()
    self.Tier:OnShow()
end

--
-- PVP Queue Button Mixin
--
PVPQueueButtonMixin = {}

function PVPQueueButtonMixin:UpdateDisableReason(disableReason)
    local inInstance, instanceType = IsInInstance()

    if inInstance and instanceType == "arena" or instanceType == "pvp" then
        disableReason = SPELL_FAILED_NOT_IN_BATTLEGROUND
    end

    if not C_PVP:CanQueueInHighRisk() then
        disableReason = ERR_CANT_QUEUE_PVP_HIGH_RISK
    end

    local queued = 0
    for i = 1, MAX_BATTLEFIELD_QUEUES do
        if GetBattlefieldStatus(i) ~= "none" then
            queued = queued + 1
        end
    end

    if queued == MAX_BATTLEFIELD_QUEUES then
        disableReason = format(ERR_TOO_MANY_QUEUED_BATTLEGROUND, MAX_BATTLEFIELD_QUEUES)
    end

    if not C_PrimaryStat:GetActivePrimaryStat() and not C_Realm.IsDevelopment() and C_Player:IsHero() then
        disableReason = MUST_CHOOSE_PRIMARY_STAT_TO_QUEUE
    end

    if disableReason then
        self:Disable()
        self.tooltip = disableReason

        --[[if not(self.originalText) then self.originalText = self:GetText() end

        self:SetText(self.originalText.."\n|cffFF0000"..disableReason.."|r")]]--
        if self.ErrorMessage then -- disable it, overlaps with stat frame
            self.ErrorMessage:SetText(disableReason)
        end
    else
        self:Enable()

        -- exception for PVP power
        self.tooltip = nil

        --[[if (self.originalText) then
            self:SetText(self.originalText)
        end]]--
        if self.ErrorMessage then
            self.ErrorMessage:SetText("")
        end
    end
end

--
-- PVP Group Queue Button Mixin
--
PVPGroupQueueButtonMixin = CreateFromMixins("PVPQueueButtonMixin")

function PVPGroupQueueButtonMixin:UpdateDisableReason(disableReason)
    local partyMembers = GetNumPartyMembers()
    local raidMembers = GetNumRaidMembers()
    local groupMembers = max(partyMembers, raidMembers)

    if groupMembers > 0 then
        if (partyMembers > 0 and not UnitIsPartyLeader("player")) or (raidMembers > 0 and not IsRaidLeader()) then
            disableReason = ERR_NOT_LEADER
        elseif not C_PrimaryStat:GetActivePrimaryStat() and C_Player:IsHero() then
            disableReason = MUST_CHOOSE_PRIMARY_STAT_TO_QUEUE
        end
    else
        disableReason = ERR_NOT_IN_GROUP
    end

    PVPQueueButtonMixin.UpdateDisableReason(self, disableReason)
end

--
-- PVP Currency Bar Mixin
--
PVPCurrencyBarMixin = {
    ArenaColor = CreateColor(255, 180, 0),
    HordeColor = CreateColor(255, 30, 0),
    AllianceColor = CreateColor(0, 128, 255),
 }

 local currencyBars = {}

function PVPCurrencyBarMixin:OnLoad()
    self:HookEvent("CURRENCY_DISPLAY_UPDATE")
    self:HookEvent("ASCENSION_CUSTOM_PVP_REWARD_INFO_AVAILABLE")
    tinsert(currencyBars, self)
end

function PVPCurrencyBarMixin:CURRENCY_DISPLAY_UPDATE()
    if self:IsVisible() then
        self:Update()
    end
end

function PVPCurrencyBarMixin:ASCENSION_CUSTOM_PVP_REWARD_INFO_AVAILABLE()
    self:Update()
end

function PVPCurrencyBarMixin:OnShow()
	self:Update()
end

function PVPCurrencyBarMixin:OnMouseDown()
    local label = self.Label

    local id = self:GetID()
    if not id or id < 1 then
        id = 1
    end

    if label:GetDrawLayer() == "HIGHLIGHT" then
        label:SetDrawLayer("OVERLAY")
        C_CVar.SetBitfield("showPvPCurrencyText", id, true)
    else
        label:SetDrawLayer("HIGHLIGHT")
        C_CVar.SetBitfield("showPvPCurrencyText", id, false)
    end
end

function PVPCurrencyBarMixin:Update()
    if self.type == "arena" then
        local curArena, maxArena = Ascension_GetArenaRewardInfo()
        self:SetMinMaxValues(0, maxArena)
        self:SetValue(curArena)

        self:SetStatusBarColor(self.ArenaColor:GetRGB())

        self.Label:SetText(format(ARENA_POINTS.." %d/%d", curArena, maxArena))

        if curArena == maxArena then
            self.IconFrame.Ring:SetAtlas("pvpqueue-rewardring-black", Const.TextureKit.IgnoreAtlasSize)
            self.IconFrame.CheckMark:Show()
        else
            self.IconFrame.Ring:SetAtlas("pvpqueue-rewardring", Const.TextureKit.IgnoreAtlasSize)
            self.IconFrame.CheckMark:Hide()
        end

    elseif self.type == "honor" then
        local curHonor, maxHonor = GetHonorCurrency()
        self:SetMinMaxValues(0, maxHonor)
        self:SetValue(curHonor)

        if UnitFactionGroup("player") == "Alliance" then
            self:SetStatusBarColor(self.AllianceColor:GetRGB())
        else
            self:SetStatusBarColor(self.HordeColor:GetRGB())
        end

        self.Label:SetText(format(HONOR_POINTS.." %d/%d", curHonor, maxHonor))

        if curHonor == maxHonor then
            self.IconFrame.Ring:SetAtlas("pvpqueue-rewardring-black", Const.TextureKit.IgnoreAtlasSize)
            self.IconFrame.CheckMark:Show()
        else
            self.IconFrame.Ring:SetAtlas("pvpqueue-rewardring", Const.TextureKit.IgnoreAtlasSize)
            self.IconFrame.CheckMark:Hide()
        end
    end

    local id = self:GetID()
    if not id or id < 1 then
        id = 1
    end

    local showText = C_CVar.GetBitfield("showPvPCurrencyText", id)

    if showText then
        self.Label:SetDrawLayer("OVERLAY")
    elseif showText == nil then
        -- HACK: No easy way to set bit defaults, so just set all bars defaults to true the first time we update.
        for _, bar in ipairs(currencyBars) do
            local barId = bar:GetID()
            if not barId or barId < 1 then
                barId = 1
            end
            C_CVar.SetBitfield("showPvPCurrencyText", barId, true)
            bar.Label:SetDrawLayer("OVERLAY")
        end
    else
        self.Label:SetDrawLayer("HIGHLIGHT")
    end
end

function PVPCurrencyBarMixin:SetDisabled(disabled)
	if self.disabled ~= disabled then
		self.Border:SetDesaturated(disabled)
		self.Background:SetDesaturated(disabled)
		self.Reward.Ring:SetDesaturated(disabled)
		self.Reward.Icon:SetDesaturated(disabled)
		self.Label:SetAlpha(disabled and 0 or 1)
		local alpha = disabled and 0.6 or 1
		self.Border:SetAlpha(alpha)
		self.Background:SetAlpha(alpha)
		self.disabled = disabled
	end
end

--
-- PVP Rated Tier Mixin
--
PVPRatedTierMixin = {}

function PVPRatedTierMixin:OnShow()
    self:Update()
end

function PVPRatedTierMixin:Update()
    local teamId = self:GetID() > 0 and self:GetID() or self:GetParent():GetID()

    if not teamId or teamId == 0 or teamId > 3 then
        return
    end

    local _, _, rating, _, _, _, _, _, _, teamRank = GetArenaTeam(teamId)
    self.CurrentRating:SetText(rating)

    local eliteName, eliteMinRating, elitePrevTier, eliteIcon = C_PVP:GetEliteTierInfo()

    local isElite = false

    if rating >= eliteMinRating then
        isElite = select(3, Ascension_GetArenaRewardInfo()) == "BRACKET_GLADIATOR"
    end

    if not isElite then
        self.TeamRank:Hide()
        local name, minRating, maxRating, prevTier, nextTier, icon = C_PVP:GetPVPTierInfo(rating)
        self.Ranking:SetText(name)
        self.Icon:SetTexture(icon)
    else
        self.Ranking:SetText(eliteName)
        self.Icon:SetTexture(eliteIcon)
        self.TeamRank:Show()
        self.TeamRank:SetText(teamRank)
    end
end
--
-- PVP Stats Mixin
--
PVPStatsMixin = {}

function PVPStatsMixin:LoadPvPPowerTooltip()
    self.PvPPower:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local level = UnitLevel("player")
        local maxLevel = GetMaxLevel()

        local pvpPower = C_Player:GetPvPPower()
        GameTooltip:SetText(PVP_POWER_LABEL .. " " .. pvpPower .. "/" .. PVP_POWER_CAP, 1, 1, 1, 1)
        GameTooltip:AddLine(PVP_POWER_TOOLTIP1:format(pvpPower * PVP_POWER_DAMAGE_MULTIPLIER), nil, nil, nil, true)
        GameTooltip:AddLine(PVP_POWER_TOOLTIP2:format(pvpPower * PVP_POWER_HEALING_MULTIPLIER), nil, nil, nil, true)
        GameTooltip:AddLine(PVP_POWER_TOOLTIP3, nil, nil, nil, true)
        GameTooltip:AddLine(PVP_POWER_TOOLTIP4:format(pvpPower * PVE_POWER_DAMAGE_MULTIPLIER), nil, nil, nil, true)
        GameTooltip:AddLine(PVP_POWER_TOOLTIP5:format(pvpPower * PVE_POWER_DAMAGE_TAKEN_MULTIPLIER), nil, nil, nil, true)

        GameTooltip:Show()
    end)
end

function PVPStatsMixin:OnLoad()
    self:LoadPvPPowerTooltip()
end

function PVPStatsMixin:OnShow()
    local statID = C_PrimaryStat:GetActivePrimaryStat()
    local pvpPower = C_Player:GetPvPPower()
    if not C_Player:IsHero() then
        self.PrimaryStat:Hide()
    elseif not(statID) then
        self.PrimaryStat.tooltipTitle = MUST_CHOOSE_PRIMARY_STAT_TO_QUEUE
        self.PrimaryStat.tooltipText = ""
        self.PrimaryStat.Value:SetText("No Primary Stat")
        self.PrimaryStat.Value:SetVertexColor(1, 0, 0, 1)
    else
        local _, _, _, name = C_PrimaryStat:GetPrimaryStatInfo(statID)
        self.PrimaryStat.Value:SetText(name)
        self.PrimaryStat.Value:SetVertexColor(1, 1, 1, 1)
        self.PrimaryStat.tooltipTitle = name
        self.PrimaryStat.tooltipText = "Make sure to pick proper Primary Stat to show your best results in PvP battles!"
    end


    self.PvPPower.Value:SetText(pvpPower)
    self.PvPPower.Alert:Hide()

    if UnitLevel("player") >= GetMaxLevel() then
        if pvpPower < 250 then
            self.PvPPower.Value:SetVertexColor(1, 0, 0, 1)
            self.PvPPower.Alert:Show()
        else
            self.PvPPower.Value:SetVertexColor(1, 1, 1, 1)
        end
    else
        self.PvPPower.Value:SetVertexColor(0.5, 0.5, 0.5, 1)
    end
end

--
-- PVP Honor Level Mixin
--
PVPHonorLevelMixin = { }

function PVPHonorLevelMixin:OnLoad()
    CircularStatusBarMixin.OnLoad(self)
	if UnitFactionGroup("player") == "Horde" then
		self.Background:SetAtlas("pvpqueue-sidebar-honorbar-background-horde", Const.TextureKit.IgnoreAtlasSize)
	else
		self.Background:SetAtlas("pvpqueue-sidebar-honorbar-background-alliance", Const.TextureKit.IgnoreAtlasSize)
	end

    self:SetDrawLayer("OVERLAY")
    self:SetTexture("Interface\\PVPFrame\\pvpqueue-sidebar-honorbar-fill")
end

function PVPHonorLevelMixin:OnShow()
	self:HookEvent("HONOR_CURRENCY_UPDATE")
	self:Update()
end

function PVPHonorLevelMixin:OnHide()
    self:UnhookEvent("HONOR_CURRENCY_UPDATE")
end

function PVPHonorLevelMixin:HONOR_CURRENCY_UPDATE()
    self:Update()
end

function PVPHonorLevelMixin:Update()
    self:UpdateWedgeSize()
    local glory = GetGloryPoints("player")
    local level, currentIcon, currentGloryReq, nextIcon, nextGloryReq = C_PVP:GetHonorRank(glory)

    -- hk requirements
    if nextGloryReq then
        self.NextRewardLevel.nextRank = nextGloryReq
        self.NextRewardLevel.Rank:SetTexture(nextIcon)
    else
        self.NextRewardLevel.nextRank = nil
        self.NextRewardLevel.Border:SetAtlas("pvpqueue-rewardring-black", Const.TextureKit.IgnoreAtlasSize)
        self.NextRewardLevel.Rank:SetTexture()
    end

    self:GetParent().HonorableKills.HKValue:SetText(glory)

    -- Progress bar
    local percent = math.RemapToRange(glory, currentGloryReq, nextGloryReq, 0, 1)
	self:SetProgress(0, 360, percent, true)

	-- honor level
	self.LevelLabel:SetFormattedText(HONOR_LEVEL_LABEL, level)

	-- badge icon
	self.FactionBadge:Show()
    self.FactionBadge:SetTexture(currentIcon)
end

--
-- PVP Leave Mixin
--
PVPLeaveMixin = {}

function PVPLeaveMixin:OnLoad()
    C_Hook:Register(self, "UPDATE_BATTLEFIELD_STATUS, PLAYER_ENTERING_WORLD")
    self:RegisterForDrag("LeftButton")
    self.Background:SetAtlas("honorsystem-talents-bg", Const.TextureKit.IgnoreAtlasSize)
    self.IconFrame.Icon:SetPortraitTexture("Interface\\Icons\\Achievement_BG_KillFlagCarriers_grabFlag_CapIt")
end

function PVPLeaveMixin:UPDATE_BATTLEFIELD_STATUS()
    local winner = GetBattlefieldWinner()

    if winner and GetBattlefieldInstanceExpiration() > 0 and not self:IsVisible() then
        if C_Instance.IsInArena() then
            self.Text:SetText(ARENA_COMPLETED)
            self.LeaveButton:SetText(LEAVE_ARENA)
        else
            self.Text:SetText(BATTLEGROUND_COMPLETED)
            self.LeaveButton:SetText(LEAVE_BATTLEGROUND)
        end
        self:Show()
    end
end

function PVPLeaveMixin:PLAYER_ENTERING_WORLD()
    if self.Hide then -- ?? happens before this is set for some unknown reason.
        self:Hide()
    end
end

function PVPLeaveMixin:OnClick()
    LeaveBattlefield()
    self:Hide()
end

function PVPLeaveMixin:OnUpdate()
    if not C_Instance.IsInPVP() then
        self:Hide()
    end
end

--
-- Help Plates
--
HelpPlate["PVP_FRAME"] = {
    cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.HelpPlate_PvPFrame,
	MainTip = "PVP_FRAME_MAIN",
	{
		helpTip = "LFG_FRAME_CATEGORY",
		parent  = "AscensionLFGFrame",
		points = {
			{ "TOPLEFT", "AscensionLFGFrameMenu", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionLFGFrameMenu", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "LFG_FRAME_TABS",
		parent  = "AscensionLFGFrame",
		points = {
			{ "TOPLEFT", "AscensionLFGFrameTab1", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionLFGFrameTab2", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "TOP" }
	},
	{
		helpTip = "PVP_FRAME_HONOR",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOPLEFT", "AscensionPVPFrameHonorBar", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVPFrameHonorBar", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "PVP_FRAME_ARENA_POINTS",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOPLEFT", "AscensionPVPFrameArenaBar", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVPFrameArenaBar", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip = "PVP_FRAME_QUEUE",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOPLEFT", "AscensionPVPFrame", "TOPLEFT", 8, -85 },
			{ "BOTTOMRIGHT", "AscensionPVPFrameHonorInset", "BOTTOMLEFT", -5, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
    {
		helpTip = "PVP_FRAME_HONOR_LEVEL",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOPLEFT", "AscensionPVPFrameHonorInsetHonorLevelDisplay", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "AscensionPVPFrameHonorInsetHonorLevelDisplay", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
    {
		helpTip = "PVP_FRAME_BEST_RATING",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOP", "AscensionPVPFrameHonorInsetTierBestRating", "TOP", 0, 8 },
            { "LEFT", "AscensionPVPFrameHonorInset", "LEFT", 10, 0 },
            { "RIGHT", "AscensionPVPFrameHonorInset", "RIGHT", -10, 0 },
			{ "BOTTOM", "AscensionPVPFrameHonorInsetTierRanking", "BOTTOM", 0, -8 },
		},
		flyoutPoint = { "CENTER" }
	},
    {
		helpTip = "PVP_FRAME_QUEUE_BUTTONS",
		parent  = "AscensionPVPFrame",
		points = {
			{ "TOPLEFT", "AscensionPVPFrame", "BOTTOM", -204, 22 },
			{ "BOTTOMRIGHT", "AscensionPVPFrame", "BOTTOM", 36, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
}

HelpTips["PVP_FRAME_MAIN"] = {
	text = HELP_PLATE_PVP_FRAME_MAIN,
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["PVP_FRAME_HONOR"] = {
	text = HELP_PLATE_PVP_FRAME_HONOR,
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["PVP_FRAME_ARENA_POINTS"] = {
	text = HELP_PLATE_PVP_FRAME_ARENA_POINTS,
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["PVP_FRAME_QUEUE"] = {
	text = HELP_PLATE_PVP_FRAME_QUEUE,
	targetPoint = HelpTip.Point.TopEdgeCenter,
}

HelpTips["PVP_FRAME_HONOR_LEVEL"] = {
	text = HELP_PLATE_PVP_FRAME_HONOR_LEVEL,
	targetPoint = HelpTip.Point.LeftEdgeCenter,
}

HelpTips["PVP_FRAME_BEST_RATING"] = {
	text = HELP_PLATE_PVP_FRAME_BEST_RATING,
	targetPoint = HelpTip.Point.LeftEdgeCenter,
}

HelpTips["PVP_FRAME_QUEUE_BUTTONS"] = {
	text = HELP_PLATE_PVP_FRAME_QUEUE_BUTTONS,
	targetPoint = HelpTip.Point.TopEdgeCenter,
}

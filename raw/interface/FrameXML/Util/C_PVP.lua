C_PVP = {}

function C_PVP:CanQueueCasual()
    return C_Player:GetLevel() >= PVPFrameMixin.MIN_LEVEL, FEATURE_BECOMES_AVAILABLE_AT_LEVEL:format(PVPFrameMixin.MIN_LEVEL)
end

function C_PVP:CanQueueRated()
    return C_Player:IsMaxLevel(), FEATURE_BECOMES_AVAILABLE_AT_LEVEL:format(GetMaxLevel())
end

function C_PVP:GetRandomBGInfo()
    local bgName, isRandom, battleGroundID, battleGroundIndex
    for i = 1, GetNumBattlegroundTypes() do
        bgName, _, _, isRandom, battleGroundID  = GetBattlegroundInfo(i)
        battleGroundIndex = i
        if isRandom then
            break
        end
    end

    if isRandom and bgName then
        local hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount = GetRandomBGHonorCurrencyBonuses()
        return bgName, true, battleGroundIndex, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, 10
    end
end

function C_PVP:GetHolidayBGInfo()
    local bgName, canEnter, isHoliday, battleGroundID
    local data = {}
    for i = 1, GetNumBattlegroundTypes() do
        bgName, canEnter, isHoliday, _, battleGroundID  = GetBattlegroundInfo(i)
        if isHoliday and canEnter then
            local hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount = GetHolidayBGHonorCurrencyBonuses()
            tinsert(data, { bgName, canEnter, i, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, 10 })
        end
    end

    return data
end

function C_PVP:GetRandomBrawlBGInfo()
    local bgName, canEnter, isBrawl, battleGroundID, battleGroundIndex
    for i = 1, GetNumBattlegroundTypes() do
        bgName, canEnter, _, _, battleGroundID = GetBattlegroundInfo(i)
        isBrawl = battleGroundID == 33
        battleGroundIndex = i
        if isBrawl then
            break
        end
    end

    if isBrawl and bgName then
        canEnter = canEnter and C_Player:IsMaxLevel() and GameEventUtil.IsEventActive(1601)
        local hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount = GetRandomBGHonorCurrencyBonuses()
        return bgName, canEnter, battleGroundIndex, battleGroundID, hasWon, winHonorAmount, winArenaAmount, lossHonorAmount, lossArenaAmount, 10
    end
end

function C_PVP:CanQueueInHighRisk()
    if C_Player:IsHighRisk() then
        return not C_Player:IsWorldPVP()
    else
        return true
    end
end

function C_PVP:IsLegacyWarmode()
    local realmID = GetRealmId()
    return realmID == 11 or realmID == 4
end

function C_PVP:GetMapIsHighRisk(currentMap)
    if not currentMap then
        if C_PVP:IsLegacyWarmode() then
            return 0
        end
        return false
    end

    if AscensionPOI and AscensionPOI.CrowsCacheZone == currentMap and GameEventUtil.IsEventActive(Enum.GameEvent.CrowsCache) then
        if C_PVP:IsLegacyWarmode() then
            return 3
        end
        return true
    end

    if C_PVP:IsLegacyWarmode() then
        if Enum.HighRiskZoneTiers[currentMap] then
            return Enum.HighRiskZoneTiers[currentMap]
        end

        return 0
    else
        if Enum.HighRiskZones[currentMap] then
            return Enum.HighRiskZones[currentMap]
        end

        return false
    end
end

function C_PVP:GetIsCurrentMapHighRisk()
    if not C_Player:IsHighRisk() then return 0 end
    local map = C_Player:GetCurrentMapInfo()
    
    return C_PVP:GetMapIsHighRisk(map)
end

function C_PVP:GetMaxGearDropAmount()
    if not C_Player:IsHighRisk() then return 0 end
    if C_Player:IsMaxLevel() then
        return 2
    end

    return 1
end

local tierInfo = {
    {
        -- Elite is a special tier reserved for players in the top X AND above 2400. 
        -- to check if we should be elite, check `select(3, Ascension_GetArenaRewardInfo()) == "BRACKET_GLADIATOR"` and rating is over 2400
        rating = -1,
        name = PVP_TIER_ELITE,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_07Mod",
    },
    {
        rating = 0,
        name = PVP_TIER_UNRANKED,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_01",
    },
    {
        rating = 1400,
        name = PVP_TIER_COMBATANT,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_02",
    },
    {
        rating = 1600,
        name = PVP_TIER_CHALLENGER,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_03",
    },
    {
        rating = 1800,
        name = PVP_TIER_RIVAL,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_04",
    },
    {
        rating = 2100,
        name = PVP_TIER_DUELIST,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_05",
    },
    {
        rating = 2400,
        name = PVP_TIER_GLADIATOR,
        icon = "Interface\\PVPFrame\\Icons\\UI_RankedPvP_06",
    },
}

if Ascension_GetArenaBracketCutoffs then -- Update with actual bracket cutoffs
    for i = 2, #tierInfo do
        tierInfo[i].rating = select(i - 1, Ascension_GetArenaBracketCutoffs()) or tierInfo[i].rating
    end
end

function C_PVP:GetPVPTierInfo(rating)
    rating = max(rating, 0)
    local name, minRating, maxRating, prevTier, nextTier, icon

    local currentInfo = tierInfo[2]
    minRating = 0

    for i = 2, #tierInfo do
        local info = tierInfo[i]

        if rating >= info.rating then
            currentInfo = info
            minRating = info.rating
        else
            maxRating = info.rating
            break
        end
    end

    name = currentInfo.name
    prevTier = max(minRating - 1, 0)
    nextTier = maxRating and maxRating + 1
    icon = currentInfo.icon

    return name, minRating, maxRating, prevTier, nextTier, icon
end

function C_PVP:GetEliteTierInfo()
    local info = tierInfo[1]

    local name = info.name
    local minRating = tierInfo[#tierInfo].rating
    local prevTier = minRating - 1
    local icon = info.icon

    return name, minRating, prevTier, icon
end

local hkRanks = {
    {
        glory = 0,
        icon = "Interface\\PvPRankBadges\\PvPRank01"
    },
    {
        glory = 250,
        icon = "Interface\\PvPRankBadges\\PvPRank02"
    },
    {
        glory = 500,
        icon = "Interface\\PvPRankBadges\\PvPRank03"
    },
    {
        glory = 1000,
        icon = "Interface\\PvPRankBadges\\PvPRank04"
    },
    {
        glory = 2000,
        icon = "Interface\\PvPRankBadges\\PvPRank05"
    },
    {
        glory = 4000,
        icon = "Interface\\PvPRankBadges\\PvPRank06"
    },
    {
        glory = 8000,
        icon = "Interface\\PvPRankBadges\\PvPRank07"
    },
    {
        glory = 15000,
        icon = "Interface\\PvPRankBadges\\PvPRank08"
    },
    {
        glory = 25000,
        icon = "Interface\\PvPRankBadges\\PvPRank09"
    },
    {
        glory = 40000,
        icon = "Interface\\PvPRankBadges\\PvPRank10"
    },
    {
        glory = 60000,
        icon = "Interface\\PvPRankBadges\\PvPRank11"
    },
    {
        glory = 90000,
        icon = "Interface\\PvPRankBadges\\PvPRank12"
    },
    {
        glory = 125000,
        icon = "Interface\\PvPRankBadges\\PvPRank13"
    },
    {
        glory = 175000,
        icon = "Interface\\PvPRankBadges\\PvPRank14"
    },
    {
        glory = 250000,
        icon = "Interface\\PvPRankBadges\\PvPRank15"
    },
}
function C_PVP:GetHonorRank(glory)
    local currentIcon = hkRanks[1].icon
    local nextIcon
    local nextGloryReq    = 2
    local currentGloryReq = 0
    local level             = 1

    for lvl, info in ipairs(hkRanks) do
        if glory >= info.glory then
            level = lvl
            currentIcon     = info.icon
            currentGloryReq = info.glory
        else
            nextGloryReq = info.glory
            nextIcon     = info.icon
            break
        end
    end

    return level, currentIcon, currentGloryReq, nextIcon, nextGloryReq
end

function C_PVP:GetCurrentBestRating()
    local index, name
    local best = -1
    for i = 1, 3 do
        local _, _, rating = GetArenaTeam(i)
        if rating > best then
            best = rating
            index = i
            name = RATED_SIZE_STRINGS[i]
        end
    end

    return best, name, index
end

function C_PVP:GetRequiredItemLevelForEvents()
    return HIGH_RISK_EVENT_MIN_ILVL[GetMaxLevel(GetMapExpansion())]
end

function C_PVP:ZONE_CHANGED_NEW_AREA()
    if self.HighRiskNotificationTimer then
        self.HighRiskNotificationTimer:Cancel()
    end
    
    self.HighRiskNotificationTimer = Timer.NewTimer(1, function()
        if IsInInstance() then
            self.IsHighRisk = false
            return
        end

        if C_Player:IsHighRisk() and C_Player:IsWorldPVP() then
            if not self.IsHighRisk then
                self.IsHighRisk = true
                C_TrackerHeader:Show(C_Player:GetFaction(), "WARN_ENTER_HIGH_RISK", "WARN_ENTER_HIGH_RISK_SUBTEXT_TIER_2", "PVP_Warning",
                        0.75, 2.5, 4)
            end
        else
            self.InHighRisk = false
        end
        
        self.HighRiskNotificationTimer = nil
    end)
end

function C_PVP:GetBattlegroundFaction()
    if C_Instance.IsInPVP() then
        if C_Player:HasAura(86475) then
            return "Alliance"
        elseif C_Player:HasAura(86476) then
            return "Horde"
        end
    end
    
    return C_Player:GetFaction()
end

function C_PVP:PLAYER_ENTERING_WORLD()
    Timer.After(0.5, function() self:ZONE_CHANGED_NEW_AREA() end)
    C_Hook:Unregister(self, "PLAYER_ENTERING_WORLD")
    C_Hook:Register(self, "ZONE_CHANGED_NEW_AREA")
end

C_Hook:Register(C_PVP, "PLAYER_ENTERING_WORLD")
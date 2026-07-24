ManastormUtil = {}

ManastormUtil.RewardVisibilityUpdatedEvent = "MANASTORM_REWARD_VISIBILITY_UPDATED"

ManastormUtil.RewardDisplayAction = {
    Hide = "HIDE",
    LockedRateLimitExhausted = "LOCKED_RATE_LIMIT_EXHAUSTED",
}

function ManastormUtil.GetRewardVisibilityContext()
    return C_Manastorm.GetActiveManastormID()
end

function ManastormUtil.GetRewardVisibility(context, itemID)
    if not context then
        return
    end

    local action, remainingSeconds, reason = C_Manastorm.GetRewardVisibility(context, itemID)
    if type(action) == "table" then
        local visibility = action
        action = visibility.displayAction or visibility.action
        remainingSeconds = visibility.remainingSeconds or visibility.remainingTime or visibility.timeRemaining
        reason = visibility.reason
    end

    return action, remainingSeconds, reason
end

function ManastormUtil.GetRewardLimitProgress(context, itemID)
    if not context then
        return
    end

    return C_Manastorm.GetRewardLimitProgress(context, itemID)
end

function ManastormUtil.GetRewardVisibilityAction(context, itemID)
    local action, remainingSeconds, reason = ManastormUtil.GetRewardVisibility(context, itemID)
    if action == ManastormUtil.RewardDisplayAction.LockedRateLimitExhausted then
        return action, remainingSeconds, reason
    elseif action == ManastormUtil.RewardDisplayAction.Hide then
        return action, remainingSeconds, reason
    end
end

function ManastormUtil.GetManastormType()
    if C_Manastorm.IsInManastorm() then
        return C_Manastorm.GetActiveManastormType()
    else
        local groupCount = GroupUtil.GetNumGroupMembers()
        if groupCount == 1 then
            return "SOLO"
        elseif groupCount == 2 then
            return "DUO"
        elseif groupCount == 3 then
            return "TRIO"
        else
            return "GROUP"
        end
    end
end

function ManastormUtil.GetEndGamePlayerLevel()
    return math.max(GetMaxLevel(), 60)
end

function ManastormUtil.GetManastormDifficulty()
    local difficulty = 0 -- no max level players
    local endGamePlayerLevel = ManastormUtil.GetEndGamePlayerLevel()
    for unit in GroupUtil.EnumerateGroupMembers() do
        local level = UnitLevel(unit)
        if level and level >= endGamePlayerLevel then
            difficulty = 2
            break
        end
    end
    
    return difficulty
end

function ManastormUtil.ShowLeaveManastormDialog()
    if C_Manastorm.IsInManastorm() then
        local level = C_Manastorm.GetActiveLevel()
        local remainder = (level - 1) % 5
        if remainder == 0 then
            StaticPopup_Show("LEAVE_THE_MANASTORM_CONFIRM")
        else
            local lastCheckpoint = level - remainder
            StaticPopup_Show("LEAVE_THE_MANASTORM_CHECKPOINT_CONFIRM", lastCheckpoint)
        end
    end
end

function ManastormUtil.HasAnyAvailableLoadoutSpells()
    if not C_Config.GetBoolConfig("CONFIG_MANASTORM_LOADOUTS_ENABLED") then
        return false
    end

    local availableSpells, _ = C_Manastorm.GetAvailableLoadoutSpells()
    return #availableSpells > 0
end

function ManastormUtil.IsLoadoutFilled()
    if not C_Config.GetBoolConfig("CONFIG_MANASTORM_LOADOUTS_ENABLED") then
        return true
    end

    if not ManastormUtil.HasAnyAvailableLoadoutSpells() then
        return true
    end

    local numSlots = C_Manastorm.GetNumLoadoutSlots()
    for i = 1, numSlots do
        if not C_Manastorm.GetLoadoutSpellAtIndex(i) then
            return false
        end
    end
    
    return true
end

MythicPlusUtil = {}

-- returns similar to C_ChallengeMode.GetCompletionInfo()
function MythicPlusUtil.GetCompletionInfo(onTime)
    if not C_MythicPlus.IsKeystoneActive() then
        return
    end

    local keystone = C_MythicPlus.GetActiveKeystoneInfo()
    local finalTime, totalTime = C_MythicPlus.GetActiveKeystoneTime()
    local mapID = keystone.dungeonID
    local level = keystone.keystoneLevel
    local time = totalTime - finalTime
    local percentTime = finalTime / totalTime
    local keystoneUpgradeLevels
    if percentTime >= MYTHIC_PLUS_BONUS_LEVEL_PERCENT[1] then
        keystoneUpgradeLevels = 3
    elseif percentTime >= MYTHIC_PLUS_BONUS_LEVEL_PERCENT[2] then
        keystoneUpgradeLevels = 2
    else
        keystoneUpgradeLevels = 1
    end
    
    local members = {}
    for unitID in GroupUtil.EnumerateGroupMembers() do
        tinsert(members, { memberGUID = UnitGUID(unitID), name = UnitName(unitID) })
    end
    
    return mapID, level, time, onTime, keystoneUpgradeLevels, members
end

function MythicPlusUtil.GetActiveKeystoneLevel()
    local activeKeystone = C_MythicPlus.IsKeystoneActive() and C_MythicPlus.GetActiveKeystoneInfo()
    local mythicLevel = activeKeystone and activeKeystone.keystoneLevel
    return mythicLevel
end 
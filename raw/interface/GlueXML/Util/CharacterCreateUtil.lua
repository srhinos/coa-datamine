CharacterCreateUtil = {}

function CharacterCreateUtil.GetRandomAvailableClassForRace(race)
    if C_CharacterCreate.CanCreateClass(Enum.Class.HERO) and IsRaceClassValid(race, Enum.Class.HERO) then
        return Enum.Class.HERO
    end

    local validClassIDs = {}
    for i = 1, 32 do
        if CharacterCreateUtil.IsRaceClassEnabledAndValid(race, i) then
            table.insert(validClassIDs, i)
        end
    end
    
    if #validClassIDs == 0 then
        C_Logger.Error("No Valid Class IDs! Check C_CharacterCreate.CanCreateClass!")
        return Enum.Class.HERO
    end

    return validClassIDs[math.random(1, #validClassIDs)]
end

function CharacterCreateUtil.IsRaceClassEnabledAndValid(race, classID)
    return IsRaceClassValid(race, classID) and C_CharacterCreate.CanCreateClass(classID)
end
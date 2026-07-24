local function FixRangeCheck(elvui)
    local spellRangeCheck = elvui.global.unitframe.spellRangeCheck
    for class in pairs(RAID_CLASS_COLORS) do
        if not spellRangeCheck[class] then
            spellRangeCheck[class] = {
                enemySpells = {}, -- Damage Spells
                longEnemySpells = {}, -- Dots
                friendlySpells = {}, -- Heals
                resSpells = {}, -- Rez Spells
                petSpells = {}, -- Pet Abilities
            }
        end
    end
end

local function FixClassRoles(elvui)
    local roles = elvui.ClassRole
    if not roles then return end

    for class in pairs(RAID_CLASS_COLORS) do
        if not roles[class] then
            roles[class] = {
                [0] = "Caster" -- Specs don't exist so everything will return 0. Just assume everyone is a caster.
            }
        end
    end
end

local function OnLoad()
    local elv = unpack(_G["ElvUI"])

    FixClassRoles(elv)

    Timer.After(0.1, function()
        FixRangeCheck(elv)
    end)
end

AddonCompatibility:Register("ElvUI", OnLoad)
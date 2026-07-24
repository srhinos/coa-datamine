local Addon = select(2, ...)
local Recap = Addon.DeathRecap

local SOURCE_FRIENDLY_PLAYER_FORMAT = "%s, (|cff85FF85%s|r)"
local SOURCE_ENEMY_PLAYER_FORMAT = "%s (|cffFF7C0A%s|r)"
local SOURCE_ENEMY_NPC_FORMAT = "%s (|cffFF6B6B%s|r)"
local SOURCE_FRIENDLY_NPC_FORMAT = "%s (|cff85FF85%s|r)"
local HEALTH_PERCENT_FORMAT = "[|cff85FF85%s%%|r]"
local TOOLTIP_DAMAGE_FORMAT = "%s %s %s"
local TOOLTIP_SOURCE_FORMAT = "%s by %s"
local TOOLTIP_TIMESTAMP_FORMAT = "%s sec before death at %s%% health"
local TOOLTIP_DEATH_FORMAT = "%s - Killing blow at %s%% health"

local DAMAGE_NORMAL_SIZE = 12
local DAMAGE_CRIT_SIZE = 16

local function EntryOnEnter(entry)
    GameTooltip:SetOwner(entry:GetParent(), "ANCHOR_TOP")
    if entry.damage < 0 then
        local dmg = DAMAGE
        if entry.crit then
            dmg = CRIT_ABBR .. " " .. DAMAGE
        end
        GameTooltip:AddLine(format(TOOLTIP_DAMAGE_FORMAT, BreakUpLargeNumbers(abs(entry.damage)), SCHOOL_STRING_TABLE[entry.school] or STRING_SCHOOL_PHYSICAL, dmg), 1, 0, 0, false)
    else
        local heal = SHOW_COMBAT_HEALING
        if entry.crit then
            heal = CRIT_ABBR .. " " .. SHOW_COMBAT_HEALING
        end
        GameTooltip:AddLine(format(TOOLTIP_DAMAGE_FORMAT, BreakUpLargeNumbers(entry.damage), SCHOOL_STRING_TABLE[entry.school] or STRING_SCHOOL_PHYSICAL, heal), 0, 1, 0, false)
    end
    GameTooltip:AddLine(format(TOOLTIP_SOURCE_FORMAT, entry.spellName, entry.attacker), 1, 1, 1, true)
    if entry.Gravestone:IsVisible() then
        GameTooltip:AddLine(format(TOOLTIP_DEATH_FORMAT, date("%I:%M:%S %p", tonumber(entry.eventTimeSeconds)), entry.healthPercent))
    else
        GameTooltip:AddLine(format(TOOLTIP_TIMESTAMP_FORMAT, entry.eventTime:sub(2), entry.healthPercent))
    end
    GameTooltip:Show()
end

local function EntryOnLeave(entry)
    GameTooltip:Hide()
end

local function EntrySetEvent(entry, spell, school, periodic, attacker, isPlayer, eventTime, damage, crit, healthPercent, finalEventTime)
    if not attacker or attacker == "" then
        attacker = "Environment"
    end

    local spellName, _, spellIcon = GetSpellInfo(spell)
    if not spellName then
        if attacker ~= "Environment" then
            if spell == -1 then
                spellName = "Melee"
                spellIcon = "Interface\\ICONS\\INV_Sword_04"
            else
                spellName = "Unknown"
                spellIcon = "Interface\\Icons\\Inv_misc_questionmark"
            end
        else -- Environmental Death
            local environmentalType = crit
            local texture = "Spell_Nature_Earthquake"
            if ( environmentalType == "DROWNING" ) then
                texture = "spell_shadow_demonbreath"
            elseif ( environmentalType == "FALLING" ) then
                texture = "Spell_Magic_FeatherFall"
            elseif ( environmentalType == "FIRE" or environmentalType == "LAVA" ) then
                texture = "spell_fire_fire"
            elseif ( environmentalType == "SLIME" ) then
                texture = "inv_misc_slime_01"
            elseif ( environmentalType == "FATIGUE" ) then
                texture = "ability_creature_cursed_05"
            end
            spellName = _G["ACTION_ENVIRONMENTAL_DAMAGE_"..environmentalType]
            spellIcon = "Interface\\Icons\\"..texture
        end
    end

    entry.spell = spell
    entry.spellName = spellName
    entry.school = school
    entry.periodic = periodic
    entry.attacker = attacker
    entry.isPlayer = isPlayer
    entry.eventTime = format("-%02.1fs", finalEventTime - eventTime)
    entry.eventTimeSeconds = eventTime
    entry.damage = damage
    entry.crit = crit
    entry.healthPercent = floor(healthPercent * 100)

    -- Update Health Bar
    local hb = entry.HealthBar
    local offset
    if entry.healthPercent <= 0 then
        offset = entry:GetWidth()
    else
        offset = floor(entry:GetWidth() * (1 - healthPercent))
    end
    hb:SetPoint("RIGHT", -offset, 0)

    if damage > 0 then
        if crit then
            hb:SetTexture(0, 1, 0, 0.4)
        else
            hb:SetTexture(0, 0.7, 0, 0.4)
        end
    else
        if crit then
            hb:SetTexture(1, 0, 0, 0.4)
        else
            hb:SetTexture(0.7, 0, 0, 0.4)
        end
    end

    -- Update Timestamp
    entry.TimeText:SetText(entry.eventTime)

    -- Update Source Info
    entry.SpellSlot:EnableMouse(GetSpellInfo(spell) ~= nil)
    entry.SpellIcon:SetTexture(spellIcon)
    if periodic then
        if damage < 0 then
            spellName = spellName .. " (DoT)"
        else
            spellName = spellName .. " (HoT)"
        end
    end
    if entry.isPlayer then
        if damage < 0 then
            entry.SourceText:SetText(format(SOURCE_ENEMY_PLAYER_FORMAT, spellName, attacker))
        else
            entry.SourceText:SetText(format(SOURCE_FRIENDLY_PLAYER_FORMAT, spellName, attacker))
        end
    else
        if damage < 0 then
            entry.SourceText:SetText(format(SOURCE_ENEMY_NPC_FORMAT, spellName, attacker))
        else
            entry.SourceText:SetText(format(SOURCE_FRIENDLY_NPC_FORMAT, spellName, attacker))
        end
    end

    -- Update Damage
    entry.DamageText:SetText(BreakUpLargeNumbers(damage))
    if damage < 0 then
        entry.DamageText:SetVertexColor(1, 0, 0, 1)
    else
        entry.DamageText:SetVertexColor(0, 1, 0, 1)
    end
    if crit then
        entry.DamageText:SetFont(entry.DamageText:GetFont(), DAMAGE_CRIT_SIZE)
    else
        entry.DamageText:SetFont(entry.DamageText:GetFont(), DAMAGE_NORMAL_SIZE)
    end

    -- Update Health Percent
    entry.HealthText:SetText(format(HEALTH_PERCENT_FORMAT, entry.healthPercent))
end

function Recap:CreateRecapEntry(name, parent)
    local entry = CreateFrame("Frame", name, parent)
    entry:SetHeight(20)
    entry:EnableMouse(true)

    -- Health Bar
    local healthBar = entry:CreateTexture(nil, "BACKGROUND")
    healthBar:SetTexture(1, 0, 0, 0.4)
    healthBar:SetAllPoints()
    entry.HealthBar = healthBar

    -- Time Offset "-9.9s"
    local timeText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("LEFT", 2, 0)
    timeText:SetSize(48, 20)
    timeText:SetVertexColor(0.4, 0.4, 0.4, 0.9)
    timeText:SetText("-9.9s")
    timeText:SetJustifyH("LEFT")
    entry.TimeText = timeText

    -- Time Offset Death Icon (Gravestone)
    local gravestone = entry:CreateTexture(nil, "OVERLAY")
    gravestone:SetPoint("CENTER", timeText, -4, 0)
    gravestone:SetTexture("Interface\\AddOns\\AscensionUI\\Textures\\DeathRecap")
    gravestone:SetTexCoord(0.658203, 0.6875, 0.00390625, 0.0820312)
    gravestone:SetSize(12, 17)
    gravestone:Hide()
    entry.Gravestone = gravestone

    local spell = CreateFrame("Frame", entry:GetName().."Spell", entry)
    spell:SetSize(20, 20)
    spell:SetPoint("LEFT", timeText, "RIGHT", 0, 0)
    spell:EnableMouse(true)
    entry.SpellSlot = spell

    spell:SetScript("OnEnter", function(self)
        if entry.spell and GetSpellInfo(entry.spell) then
            GameTooltip:SetOwner(spell, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(format("spell:%s", entry.spell))
            GameTooltip:Show()
            entry.Highlight:SetDrawLayer("OVERLAY")
        end
    end)

    spell:SetScript("OnLeave", function()
        entry.Highlight:SetDrawLayer("HIGHLIGHT")
        GameTooltip:Hide()
    end)

    -- Spell Icon
    local spellIcon = spell:CreateTexture(nil, "ARTWORK")
    spellIcon:SetSize(18, 18)
    spellIcon:SetPoint("CENTER")
    spellIcon:SetTexture("Interface\\Icons\\Inv_misc_questionmark")
    entry.SpellIcon = spellIcon

    local spellIconOverlay = spell:CreateTexture(nil, "OVERLAY")
    spellIconOverlay:SetSize(20, 20)
    spellIconOverlay:SetPoint("CENTER")
    spellIconOverlay:SetTexture("Interface\\AddOns\\AscensionUI\\Textures\\DeathRecap")
    spellIconOverlay:SetTexCoord(0.583984, 0.654297, 0.00390625, 0.144531)

    -- Source Text "Spell Name (Attacker)"
    local sourceText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceText:SetPoint("LEFT", spellIcon, "RIGHT", 12, 0)
    sourceText:SetPoint("RIGHT", -2, 0)
    sourceText:SetJustifyH("LEFT")
    sourceText:SetText(format(SOURCE_FRIENDLY_PLAYER_FORMAT, "Spell Entry", "Attacker"))
    entry.SourceText = sourceText

    local healthText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthText:SetSize(40, 20)
    healthText:SetPoint("RIGHT", -2, 0)
    healthText:SetJustifyH("RIGHT")
    entry.HealthText = healthText

    -- Damage Text "-1,000"
    local damageText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageText:SetVertexColor(1, 0, 0, 1)
    damageText:SetPoint("LEFT", spellIcon, "RIGHT", 12, 0)
    damageText:SetPoint("RIGHT", healthText, "LEFT", 0, 0)
    damageText:SetJustifyH("RIGHT")
    entry.DamageText = damageText

    local highlight = entry:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\Gradient_Highlight")
    highlight:SetPoint("TOPLEFT", entry, "TOPLEFT", -10, 10)
    highlight:SetPoint("BOTTOMRIGHT", entry, "BOTTOMRIGHT", 10, -10)
    highlight:SetBlendMode("ADD")
    entry.Highlight = highlight

    entry.SetEvent = EntrySetEvent
    entry:SetScript("OnEnter", EntryOnEnter)
    entry:SetScript("OnLeave", EntryOnLeave)

    return entry
end
C_Spell = C_Spell or {}
C_Spell.knownSpellNames = {}
C_Spell.AutoPlaceIgnored = {
    [84423] = true, -- Ressurrect in Closest Town
    [84433] = true, -- Resurrect in Capital City
    [976240] = true, -- Incantation of Friendship
    [976241] = true, -- Incantation of Experience
    [84864] = true, -- Primary Stat: Strength
    [84865] = true, -- Primary Stat: Agility
    [84866] = true, -- Primary Stat: Intellect
    [84867] = true, -- Primary Stat: Spirit
}

C_Hook:Register(C_Spell, "PLAYER_ENTERING_WORLD")
C_Hook:RegisterBucket(C_Spell, "PLAYER_LEVEL_UP", 0.1)
       
function C_Spell:GetNameAndID(spell, searchEverywhere, prioritizeMysticEnchants)
    if type(spell) == "string" and spell == "" then
        return
    end
    -- check for spell ID passed
    local name
    local spellID = spell and tonumber(spell)
    if spellID and spellID > 0 then
        name = GetSpellInfo(spellID)
        if name then
            return name, spellID
        end
    -- check for spell link passed
    elseif spell:sub(1, 1) == "\124" then
        local link = spell
        spellID = link:match("spell:(%d+)")
        spellID = spellID and tonumber(spellID)
        if spellID and spellID > 0 then
            name = GetSpellInfo(spellID)
            if name then
                return name, spellID
            end
        end
    -- check for spell name passed
    else
        -- check if spell link
        local link = GetSpellLink(spell)
        if link then
            spellID = link:match("spell:(%d+)")
            spellID = spellID and tonumber(spellID)
            if spellID and spellID > 0 then
                name = GetSpellInfo(spellID)
                if name then
                    return name,spellID
                end
            end
        end

        -- if we found a spell name then return that
        if name and spellID then
            return name, spellID
        end
    end
end

function C_Spell:GetSpellDescription(spellID, forceExpand)
    local description, embeds =  GetSpellDescription(spellID, forceExpand)
    if description then
        return description, embeds
    else
        return ""
    end
end

function C_Spell:IsCastAlmostDone(ms)
    if not ms then
        ms = (select(3, GetNetStats()) or 300) / 2
    end
    local endTime = select(6, UnitCastingInfo("player"))
    if not endTime then 
        endTime = select(6, UnitChannelInfo("player"))
    end

    if not endTime then return true end
    local timeLeft = endTime -(GetTime() * 1000)
    return timeLeft <= ms
end

function C_Spell:IsActionAlmostReady(action, ms)
    if not ms then
        ms = (select(3, GetNetStats()) or 300) / 2
    end
    
    local start, duration, enabled = GetActionCooldown(action)
    if enabled and start > 0 and duration > 0 then
        return (((start + duration) - GetTime()) * 1000) <= ms
    end
    
    return true
end

function C_Spell:GetSpellID(name, rank)
    if type(name) ~= "number" and type(name) ~= "string" then return end
    if type(name) == "number" and name <= 0 then return end
    local link = GetSpellLink(name, rank)
    if not link then return end

    return tonumber(link:match("spell:(%d*)"))
end

function C_Spell:ShouldHoldToCast(name, rank)
    if not C_CVar.GetBool("holdToCast") then return false end
    if not name then return false end
    
    local spellID = tonumber(name) or C_Spell:GetSpellID(name, rank)

    if spellID then
        return IsSpellHoldToCast(spellID)
    end
end

function C_Spell:GetSpecSpell(index)
    return SPEC_SWAP_SPELLS[index]
end

function C_Spell:IsSpecSpell(spellId)
    return IS_SPEC_SWAP_SPELL[spellId]
end

function C_Spell:IsActiveSpec(spellId)
    if not self:IsSpecSpell(spellId) then return end

    local activeId = C_CharacterAdvancement.GetActiveSpecID()
    return self:GetSpecSpell(activeId) == spellId
end

function C_Spell:IsPresetSpell(spellId)
    return IS_PRESET_CHANGE_SPELL[spellId] or IS_PRESET_SAVE_SPELL[spellId]
end

function C_Spell:GetPresetSpell(index)
    return PRESET_CHANGE_SPELLS[index], PRESET_SAVE_SPELLS[index]
end

function C_Spell:IsActivePreset(spellId)
    if not self:IsPresetSpell(spellId) then return end

    local setId, saveId = self:GetPresetSpell(GetREPreset())

    return spellId == setId or spellId == saveId
end

function C_Spell:IsAnyRankKnown(spellID, checkName)
    local internalID = C_CharacterAdvancement.GetInternalID(spellID)
    if internalID then
        local isKnown = C_CharacterAdvancement.IsKnownID(internalID)
        if isKnown ~= nil then
            return isKnown
        end
    end

    if IsSpellKnown(spellID) or IsSpellIDKnown(spellID) then
        return true
    elseif checkName then
        local name = GetSpellInfo(spellID)
        return name and GetSpellInfo(name) ~= nil
    else
        return false
    end
end

local actionBarButtons = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarLeftButton", "MultiBarRightButton"}
local actionBars = {"MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight"}

function C_Spell:GetFreeActionButton(maximumSlots)
    local slot = 0
    for id, button in ipairs(actionBarButtons) do
        if _G[actionBars[id]]:IsVisible() or id == 1 then -- only check visible bars. (Always check main 1-12 bar)
            for i = 1, 12 do
                slot = slot + 1
                if maximumSlots and slot > maximumSlots then
                    return
                end
                local frame = _G[button .. i]
                if frame then
                    local slotType = GetActionInfo(frame.action)
                    if not slotType then
                        return frame
                    end
                end
            end
        end
    end
end

local MAX_ACTION_BUTTONS = 144
local POSSESSION_START = 121
local POSSESSION_END = 132

function C_Spell:GetFreeActionID(maximumSlots, startingSlot)
    local slot = 0
    for i = startingSlot or 1, MAX_ACTION_BUTTONS do
        if i < POSSESSION_START or i > POSSESSION_END then
            slot = slot + 1
            if maximumSlots and slot > maximumSlots then
                return
            end
            if not GetActionInfo(i) then
                return i
            end
        end
    end
end

function C_Spell:GetSpellActionID(spellId, maximumSlots)
    local slot = 0
    for i = 1, MAX_ACTION_BUTTONS do
        if i < POSSESSION_START or i > POSSESSION_END then
            slot = slot + 1
            if maximumSlots and slot > maximumSlots then
                return
            end
            local _, _, _, slotSpellId = GetActionInfo(i)
            if slotSpellId and slotSpellId == spellId then
                return i
            end
        end
    end
end

function C_Spell:TabHasNotMaxedRanks(tabID)
    local level = UnitLevel("player")
    local name, _, offset, numSpells = GetSpellTabInfo(tabID)

    if not name then
       return false
    end

    if name ~= "Internal" then
        for j = offset + 1, offset + numSpells do
            local spell, rank = GetSpellInfo(j, BOOKTYPE_SPELL);

            if spell then
                local spellID = C_Spell:GetSpellID(spell, rank)

                if spellID then
                    local maxSpellID = C_Spell.GetMaxLearnableRank(spellID, level)

                    if maxSpellID and not IsSpellKnown(maxSpellID) and not IsSpellIDKnown(maxSpellID) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function C_Spell:HasNotMaxedRanks()
    for tabID = 1, MAX_SKILLLINE_TABS do
        local name = GetSpellTabInfo(tabID)

        if not name then
            break
        end

        if C_Spell:TabHasNotMaxedRanks(tabID) then
            return true
        end
    end

    return false
end

function C_Spell:PLAYER_LEVEL_UP(levels)
    local level = unpack(levels[#levels])
    local showAllRanks = GetCVar("ShowAllSpellRanks")
    SetCVar("ShowAllSpellRanks", "0")
    for i = 1, MAX_SKILLLINE_TABS do
        local name, _, _, _, offset, numSpells = GetSpellTabInfo(i);

        if not name then
           break
        end

        if name ~= "Internal" then
            for j = offset + 1, offset + numSpells do
                local slot = GetKnownSlotFromHighestRankSlot(j)
                local spell, rank = GetSpellInfo(slot, BOOKTYPE_SPELL);

                if spell then
                    local spellID = C_Spell:GetSpellID(spell, rank)

                    if spellID then
                        local maxSpellID = C_Spell.GetMaxLearnableRank(spellID, level)

                        if maxSpellID and not IsSpellKnown(maxSpellID) and not IsSpellIDKnown(maxSpellID) then
                            --HelpTip:Show("HELP_TIP_NEW_SPELL_RANK")
                            EventRegistry:TriggerEvent("NewSpellRankAvailable", spellID, maxSpellID)
                            -- Send system message to alert spells are ready to rank up
                            -- wont send at level 1, In pvp, in combat, or in twisting nether
                            if level > 1 and not C_Instance.IsInPVP() and not ZoneUtil.IsOnMap(806) and not C_Player:InCombat()then
                                SendSystemMessage(format(SPELL_READY_TO_RANK_UP, GetSpellRankLink(spellID)))
                            end
                        end
                    end
                end
            end
        end
    end
    SetCVar("ShowAllSpellRanks", showAllRanks)
end

function C_Spell:PLAYER_ENTERING_WORLD()
	for i = 1, MAX_SKILLLINE_TABS do
        local name, _, offset, numSpells = GetSpellTabInfo(i);

        if not name then
           break
        end

        if name ~= "Internal" and name ~= "Ascension Vanity Items" then
            for j = offset + 1, offset + numSpells do
            local spell = GetSpellInfo(j, BOOKTYPE_SPELL);

                if spell then
					self.knownSpellNames[spell] = true
                end
            end
        end
    end
	C_Hook:RegisterBucket(self, "SPELLS_CHANGED", 0.1)
    C_Hook:Register(self, "SEND_ACTION_BUTTONS_PAYLOAD")
    C_Hook:Register(self, "SET_ACTION_BUTTON_SPELL_PAYLOAD")
end

function C_Spell:SPELLS_CHANGED(data)
    local currentKnown = tcopy(self.knownSpellNames)
    self.knownSpellNames = {}
    for tab = 2, GetNumSpellTabs() do
        local name, _, offset, numSpells = GetSpellTabInfo(tab)

        if name and name ~= "Internal" and name ~= "Ascension Vanity Items" then
            for i = offset + 1, offset + numSpells do
                local spell = GetSpellInfo(i, BOOKTYPE_SPELL)

                if spell then
                    self.knownSpellNames[spell] = true
                    if not currentKnown[spell] then
                        local id = self:GetSpellID(spell)
                        if id and C_PrimaryStat:GetPrimaryStatID(id) then
                            C_Hook:SendEvent("PRIMARY_STAT_CHANGED", C_PrimaryStat:GetPrimaryStatID(id))
                        end
                        C_Hook:SendEvent("LEARNED_NEW_SPELL", spell, tab, i)
                        -- place new spells on the action bar
                        if data and #data <= 1 then -- idk why this is 0 for a single event call, it should be 1
                            self:PlaceSpellOnActionBar(spell)
                        end
                    end
                end
            end
        end
    end

    for spellName in pairs(currentKnown) do
        if not self.knownSpellNames[spellName] then
            C_Hook:SendEvent("UNLEARNED_SPELL", spellName)
            -- Remove unlearned spells(?)
            -- self:RemoveSpellFromActionBar(spellName)
        end
    end
end

function C_Spell:SET_ACTION_BUTTON_SPELL_PAYLOAD(button, spell)
    if button == nil or spell == nil then return end

    local newSpellName, newSpellRank = GetSpellInfo(spell)
    
    if not newSpellName then
        if spell == 0 then
            local soundToggle = GetCVar("Sound_EnableAllSound")
            SetCVar("Sound_EnableAllSound", 0)
            PickupAction(button + 1)
            ClearCursor()
            SetCVar("Sound_EnableAllSound", soundToggle)
            return
        end
    end

    local soundToggle = GetCVar("Sound_EnableAllSound")
    SetCVar("Sound_EnableAllSound", 0)
    ClearCursor()
    PickupSpell(newSpellName, newSpellRank)
    PlaceAction(button + 1)
    ClearCursor()
    SetCVar("Sound_EnableAllSound", soundToggle)
end

function C_Spell:PlaceSpellOnActionBar(spellName)
    if C_Player:GetLevel() < 11 then return end
    local id = self:GetSpellID(spellName)
    if not id then return end

    if IsPassiveSpellID(id) then return end

    if self.AutoPlaceIgnored[id] then return end

    if VanityCollectionUtil.GetItemByLearnedSpell(id) then return end

    if self:IsSpecSpell(id) then return end

    if self:IsPresetSpell(id) then return end

    if C_Spell:GetSpellActionID(id) then
        return
    end

    local action = self:GetFreeActionID(12)
    if not action then
        -- check bottom left & bottom right bars
        action = self:GetFreeActionID(24, 49)
    end
    if action then
        PickupSpell(spellName)
        PlaceAction(action)
        ClearCursor()
    end
end

function C_Spell:RemoveSpellFromActionBar(spellName)
    local id = self:GetSpellID(spellName)
    if not id then return end

    if self.AutoPlaceIgnored[id] then return end

    if VanityCollectionUtil.GetItemByLearnedSpell(id) then return end

    if self:IsSpecSpell(id) then return end

    if self:IsPresetSpell(id) then return end

    local action = self:GetSpellActionID(id)
    if action then
        PickupAction(action)
        ClearCursor()
    end
end

function C_Spell.HasMultipleSpellRanks()
    local numTabs = GetNumSpellTabs()
    local id = 1
    for i = 1, 19 do
        local _, icon = GetSpellTabInfo(id)

        -- skip internal tab
        if icon == "Interface\\Icons\\Mail_GMIcon" then
            id = id + 1
            icon = select(2, GetSpellTabInfo(id))
        end

        if i <= numTabs and id <= GetNumSpellTabs() then
            local _, _, _, numSpells, _, highestRankNumSpells = GetSpellTabInfo(id)
            if numSpells ~= highestRankNumSpells then
                return true
            end
        end
        id = id + 1
    end
    
    return false
end

if not C_Spell.IsTrainerSpell then
    C_Spell.IsTrainerSpell = IsTrainerSpell
end

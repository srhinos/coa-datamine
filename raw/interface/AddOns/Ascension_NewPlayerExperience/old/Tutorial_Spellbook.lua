local T = {
    name = "Spellbook",
    cvar = "npeUseSpellbookTutorial",
    classless = true,
    priority = 100,
    minLevel = 10,
    maxLevel = 59,

    events = {
        "LEARNED_NEW_SPELL"
    },

    sequences = {
        ["LEARNED_NEW_SPELL"] = {
            "LEARN_NEW_SPELL1",
            "LEARN_NEW_SPELL2",
            "LEARN_NEW_SPELL3",
            "LEARN_NEW_SPELL4",
            "LEARN_NEW_SPELL5",
        }
    }
}

NPE:RegisterTutorial(T)

local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

function T:SUBSCRIBED_EVENT(event, ...)
    local action = C_Spell:GetFreeActionID()
    if action and action >= 25 then -- 1-12 is filled automatically. Only show tutorial if we have a spell that couldn't be auto added to bars.
        local spellName, tab = ...

        self.spellName = spellName
        self.tab = tab
        _SUBSCRIBED_EVENT(self, event, ...)
    else
        if not SHOW_MULTI_ACTIONBAR_1 then
            SHOW_MULTI_ACTIONBAR_1 = "1"
            InterfaceOptions_UpdateMultiActionBars()
            self:SUBSCRIBED_EVENT(event, ...)
            return
        elseif not SHOW_MULTI_ACTIONBAR_2 then
            SHOW_MULTI_ACTIONBAR_2 = "1"
            InterfaceOptions_UpdateMultiActionBars()
            self:SUBSCRIBED_EVENT(event, ...)
            return
        end
        -- we likely have a custom ui, they probably know how to put spells on their bar if they have a custom ui
    end
end

NPEPopups["LEARN_NEW_SPELL1"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -100,
    offsetY = 0,
    point = "RIGHT",
}

NPEPopups["LEARN_NEW_SPELL2"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -150,
    offsetY = 50,
    point = "RIGHT",
    helpTip = "OPEN_SPELLBOOK",
    condition = function() return SpellBookFrame:IsVisible() == 1 end,
}

NPEPopups["LEARN_NEW_SPELL3"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -100,
    offsetY = -50,
    point = "RIGHT",
    event = "SPELLS_CHANGED",
    onShow = function()
        HelpTips["SPELLBOOK_TAB"].parent = "SpellBookSkillLineTab"..T.tab
        HelpTip:Show("SPELLBOOK_TAB")
    end,
}

NPEPopups["LEARN_NEW_SPELL4"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -200,
    offsetY = 50,
    point = "RIGHT",
    event = "ACTIONBAR_SLOT_CHANGED",
    onShow = function()
        local target = C_Spell:GetFreeActionButton()
        if not target then return end

        local origin, icon

        local name, _, offset, numSpells = GetSpellTabInfo(T.tab);
        if not name or name == "Internal" then return end

        local buttonOrder = {1,3,5,7,9,11,2,4,6,8,10,12};

        for i = offset + 1, offset + numSpells do
            local spell, _, spellIcon = GetSpellInfo(i, BOOKTYPE_SPELL)

            if spell and spell == T.spellName then
                local spellIndex = i - offset
				local page = 1
				if spellIndex > SPELLS_PER_PAGE then
					page = math.ceil(spellIndex / SPELLS_PER_PAGE)
					spellIndex = spellIndex - ((page - 1) * SPELLS_PER_PAGE)
				end
                icon = spellIcon
                origin = _G["SpellButton" .. buttonOrder[spellIndex]]
                break
            end
        end

        if not origin then return end

        NPE:ShowDrag(origin, target, icon)
    end,
    onHide = function()
        NPE:StopDrag()
    end,
}

NPEPopups["LEARN_NEW_SPELL5"] = {
    cvar = T.cvar,
    cvarBit = T:NextBit(),
    offsetX = -150,
    offsetY = 50,
    point = "RIGHT",
}
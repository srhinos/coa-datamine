SpellBookUtil = {}

function GetSpellBookIndex(spellID, spellType)
    if not spellID then return end
    spellType = spellType or BOOKTYPE_SPELL
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for i = offset + 1, offset + numSpells do
            local spell = GetSpellInfo(i, BOOKTYPE_SPELL)

            if spell then
                local id = C_Spell:GetSpellID(i, "spell")
                if id and id == spellID then
                    return i
                end
            end
        end
    end
end
-------------------------------------------------------------------------------
--                           Loot window tutorial                            --
-------------------------------------------------------------------------------

local max_level = 15

local default_ae_count = 9

local spell_wrath = 5176 -- TODO: Make it work with all spells

local stat_allocation_quest = 1903511

local SHADOW_GRAVE_START_NPC_1 = 1568
local SHADOW_GRAVE_START_NPC_2 = 1569
local SHADOW_GRAVE_QUEST_1 = 363
local SHADOW_GRAVE_QUEST_2 = 364

local AMMENVALE_START_NPC_1 = 16475
local AMMENVALE_START_NPC_2 = 16477
local AMMENVALE_QUEST_1 = 9279
local AMMENVALE_QUEST_2 = 9280

local COLDRIDGE_START_NPC_1 = 658
local COLDRIDGE_QUEST_1 = 179

local SHADOWGLEN_START_NPC_1 = 2079
local SHADOWGLEN_QUEST_1 = 456

local NARACHE_START_NPC_1 = 2980
local NARACHE_QUEST_1 = 747

local SUNSTRIDER_START_NPC_1 = 15278
local SUNSTRIDER_QUEST_1 = 8325

local minimap_tutorial_trigger_quests = {
    [783] = true, -- NORTHSHIRE_START
    [4641] = true, -- VALLEY_OF_TRIALS_START, Your Place In The World
}

local CA2ForceTutorialOnShow_Quests = {
    [SHADOWGLEN_QUEST_1] = true,
    [NARACHE_QUEST_1] = true,
    [SUNSTRIDER_QUEST_1] = true,
    [COLDRIDGE_QUEST_1] = true,
    [SHADOW_GRAVE_QUEST_2] = true,
    [AMMENVALE_QUEST_2] = true,
    [7] = true, -- human start
    [788] = true, -- orc start
}

--[[local CA_Advanced_Trigger_Quest = {
    COLDRIDGE_QUEST_1
    SHADOWGLEN_QUEST_1
    NARACHE_QUEST_1
    SUNSTRIDER_QUEST_1
    AMMENVALE_QUEST_2
    SHADOW_GRAVE_QUEST_2
}]]--

local LIFETIME_TEMP_TIPS = 14
local LIFETIME_TEMP_TIPS_SHORT = 10


local tamable = {
    ["Beast"] = 1515,
    ["Undead"] = 891,
    ["Dragonkin"] = 91634,
    ["Demon"] = 890,
} 

local damage_spells = { -- probably remove dots from this list. SIMPLEST damage spells
    [5176] = true,
    [8921] = true,
    [686] = true,
    [1978] = true,
    [3044] = true,
    [1495] = true,
    [2973] = true,
    [2136] = true,
    [133] = true,
    [5143] = true,
    [116] = true,
    [53408] = true,
    [20271] = true,
    [585] = true,
    --[589] = true, -- shadow word: pain
    [1752] = true,
    [1776] = true,
    [403] = true,
    [8042] = true,
    --[980] = true, -- curse of agony
    --[172] = true, -- corruption
    [686] = true,
    [348] = true,
    [1715] = true,
    [78] = true,
    [772] = true,
    [34428] = true,
}

local heal_spells = {
    [5185] = true,
    [774] = true,
    [635] = true,
    [2050] = true,
    [139] = true,
    [331] = true,
}

local ActionBars = { "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "BonusActionBarFrame"}

local function GetCreatureIDFromGUID(unitGUID)
    local guidType = tonumber(unitGUID:sub(5, 5), 16)

    if (guidType == 3) then
        local ID = tonumber(unitGUID:sub(8, 12), 16)
        return ID
    end
end

local function GetActionButtonBySpellID(sID)
    for _, barName in pairs(ActionBars) do
        for i = 1, 12 do
            if (_G[barName]:IsVisible()) then
                local buttonName = barName .. "Button" .. i
                if (barName == "BonusActionBarFrame") then
                    buttonName = "BonusActionButton" .. i
                elseif (barName == "MainMenuBar") then
                    buttonName = "ActionButton" .. i
                end
                local button = _G[buttonName]
                local slot = ActionButton_GetPagedID(button) or ActionButton_CalculateAction(button) or button:GetAttribute("action") or 0
                if HasAction(slot) then
                    local actionType, id, subType, spellID = GetActionInfo(slot)
                    if actionType == "spell" and spellID and (spellID == sID) then
                        return button
                    end
                end
            end
        end
    end
end

-- helper for inital sqeuence of tutorials (devices, movement, camera)
local function DeviceTutorialSequenceConditions()
    local x, y, z = GetCurrentPlayerPosition()
    
    if not( (NPEPopups["MOVEMENT"].positionX == x) and (NPEPopups["MOVEMENT"].positionY == y) and (NPEPopups["MOVEMENT"].positionZ == z)) then
        NPEPopups["MOVEMENT"].done = true
    end
end

local function IsTargetStartingAreaCreature()
    local unitGUID = UnitGUID("target")

    if not(unitGUID) then
        return
    end

    if (UnitIsPlayer("target")) then
        return
    end

    local ID = GetCreatureIDFromGUID(unitGUID)

    if (ID and (starting_area_creatures[ID])) then
        return true
    end
end

local function GetActionButtonKey(button)
    local hotkey = _G[button:GetName().."HotKey"]

    if hotkey and (hotkey:GetText() ~= RANGE_INDICATOR) then
        return hotkey:GetText()
    end

    return nil
end

local function CompareSpellInfo(tA, tB)
    if (#tA ~= #tB) then
        return false
    end

    for i = 1, #tA do
        if (tA[i] ~= tB[i]) then
            return false
        end
    end

    return true
end

local function ReturnGossipButtonByQuestID(questID)
    local gossipDataAvailable = {GetGossipAvailableQuests()}
    local buttonIndex = 1

    local questName = C_Quest:GetQuestNameByID(questID)
    
    if not(questName) then
        return
    end

    if next(gossipDataAvailable) then
        for i=1, #gossipDataAvailable, 2 do
            local questText = gossipDataAvailable[i]
            
            if (questText == questName) then
                return _G["GossipTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end

    if next(gossipDataAvailable) then
        buttonIndex =  buttonIndex + 1 -- skip 1 entry for active quests
    end

    local gossipDataActive = {GetGossipActiveQuests()}

    if next(gossipDataActive) then
        for i=1, #gossipDataActive, 2 do
            local questText = gossipDataActive[i]
            
            if (questText == questName) then
                return _G["GossipTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end
end

local function ReturnQuestButtonByQuestID(questID)
    local buttonIndex = 1
    local questName = C_Quest:GetQuestNameByID(questID)
    -- first scan active quests
    local totalActive = GetNumActiveQuests()

    if totalActive then
        for i= 1, totalActive do
            local questText = GetActiveTitle(i)
            
            if (questText == questName) then
                return _G["QuestTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end

    -- then scan available quests
    local totalAvailable = GetNumAvailableQuests()
    
    if not(questName) then
        return
    end

    if totalAvailable then
        for i= 1, totalAvailable do
            local questText = GetAvailableTitle(i)
            
            if (questText == questName) then
                return _G["QuestTitleButton"..buttonIndex]
            end

            buttonIndex =  buttonIndex + 1
        end
    end
end

local function DecideParentForGossipHelper(quest, event)
    if not(NPE) then
        return false
    end

    if not(NPE.info) then
        return false
    end

    if (type(NPE.info.helpTip) == "table") then
        for _, v in pairs(NPE.info.helpTip) do
            if (v == "GOSSIP_SELECT_HELPER") then
                HelpTip:Hide("GOSSIP_SELECT_HELPER")

                local btn = ReturnGossipButtonByQuestID(quest)
                if (event == "QUEST_GREETING") then
                    btn = ReturnQuestButtonByQuestID(quest)
                end

                if (btn) then
                    HelpTips["GOSSIP_SELECT_HELPER"].parent = btn:GetName()
                    HelpTip:Show("GOSSIP_SELECT_HELPER")
                    return true
                end
                return false
            end
        end

    elseif (type(NPE.info.helpTip) == "string") then
        if not(NPE.info.helpTip == "GOSSIP_SELECT_HELPER") then
            return
        end
        HelpTip:Hide("GOSSIP_SELECT_HELPER")

        local btn = ReturnGossipButtonByQuestID(quest)
        if (event == "QUEST_GREETING") then
            btn = ReturnQuestButtonByQuestID(quest)
        end

        if (btn) then
            HelpTips["GOSSIP_SELECT_HELPER"].parent = btn:GetName()
            HelpTip:Show("GOSSIP_SELECT_HELPER")
            return true
        end
    end

    return false
end


-------------------------------------------------------------------------------
--                             CA2 Main tutorial                             --
-------------------------------------------------------------------------------
local MAX_TREES = 3
local MAX_BUTTONS_PER_TREE = 30
local MAX_CLASSES = 10
local AE_DEFAULT = 9

local function UpdateCAText()
    HelpTip:Hide("ABILITY_ESSENCE_ADVANCED")
    
    local newText = string.format(HelpTips["ABILITY_ESSENCE_ADVANCED"].text_blank, GetItemCount(ItemData.ABILITY_ESSENCE))
    HelpTips["ABILITY_ESSENCE_ADVANCED"].text = newText
    HelpTip:Show("ABILITY_ESSENCE_ADVANCED")
end


local function PrepareCAButtons()
    for treeNum = 1, MAX_TREES do
        for buttonNum = 1, MAX_BUTTONS_PER_TREE do
            local btn = _G["CA2.CharacterAdvancementMain.Main.Tree"..treeNum..".Content.Spells.Button"..buttonNum]
            if (btn) then
                function btn:Matches(spellType)
                    if self.Spell then
                        if (spellType == "DAMAGE") then
                            if (damage_spells[self.Spell]) then
                                return true
                            end
                        elseif (spellType == "HEAL") then
                            if (heal_spells[self.Spell]) then
                                return true
                            end
                        end
                    end
                end

            end
        end
    end
end

function LoadCAHighlights(spellType)
    if (CA2 and CA2._glows) then
        CA2._glows:ReleaseAll()
    else
        return
    end

    for treeNum = 1, MAX_TREES do
        for buttonNum = 1, MAX_BUTTONS_PER_TREE do
            local btn = _G["CA2.CharacterAdvancementMain.Main.Tree"..treeNum..".Content.Spells.Button"..buttonNum]
            if btn and btn:Matches(spellType) then
                local highlight = CA2._glows:Acquire()
                highlight:SetParent(btn)
                highlight:SetFrameLevel(100)
                local left, right, top, bottom = unpack{-10, 10, 10, -10}
                highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", left, top)
                highlight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", right, bottom)
                highlight:Show()
                highlight.Box:Show()
                highlight.Box.Anim:Play()
            end

        end
    end
end

local function ClearOnClickHooksCA()
    for j = 1, MAX_CLASSES do
        local b = _G["CA2CharacterAdvancementMainClassButton"..j]
        if (b.clickHandler) then
            b:SetScript("OnClick", b.clickHandler)
            b.clickHandler = nil
        end
    end
end

HelpTips["CA2_PICK_HEAL"] = {
    parent = "CA2",
    relativeRegion = "CA2CharacterAdvancementMainMainTree1ContentSpells",
    text = "Double click on |cff00FF00Healing Ability|r or any other Ability to |cffFFFF00learn|r it",
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.RightEdgeTop,
    offsetY = -80,
    cvar = "npePickHealTutorial",
    cvarValue = true,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    next = "CA2_PICK_SPELLS3",
    onInitCallback = function(self)
        LoadCAHighlights("HEAL")
        for i = 1, MAX_CLASSES do -- hook ca2 class buttons to acknowledge this popup
            local button = _G["CA2CharacterAdvancementMainClassButton"..i]
            local clickHandler = button:GetScript("OnClick")
            button.clickHandler = clickHandler
            button:SetScript("OnClick", function()
                clickHandler(button)
                LoadCAHighlights("HEAL")
            end)
        end
    end,

    onAcknowledgeCallback = function(self)
        ClearOnClickHooksCA()
        CA2._glows:ReleaseAll()
    end,
}

HelpTips["CA2_PICK_DAMAGE"] = {
    parent = "CA2",
    relativeRegion = "CA2CharacterAdvancementMainMainTree1ContentSpells",
    text = "Double click on |cffFF0000Damage Ability|r or any other Ability to |cffFFFF00learn|r it",
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.RightEdgeTop,
    offsetY = -80,
    cvar = "npePickDamageTutorial",
    cvarValue = true,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    next = "CA2_PICK_HEAL",
    onInitCallback = function(self)
        LoadCAHighlights("DAMAGE")
        for i = 1, MAX_CLASSES do -- hook ca2 class buttons to acknowledge this popup
            local button = _G["CA2CharacterAdvancementMainClassButton"..i]
            local clickHandler = button:GetScript("OnClick")
            button.clickHandler = clickHandler
            button:SetScript("OnClick", function()
                clickHandler(button)
                LoadCAHighlights("DAMAGE")
            end)
        end
    end,
    onAcknowledgeCallback = function(self)
        ClearOnClickHooksCA()
        CA2._glows:ReleaseAll()
    end,
}

HelpTips["CA2_PICK_SPELLS2"].next = "CA2_PICK_DAMAGE"

HelpTips["ABILITY_ESSENCE_ADVANCED"] = {
    parent = "CA2.CharacterAdvancementMain.Main.BottomFrame.CurrencyAE",
    text = "Ability Essence left: 9",
    text_blank = "Ability Essence left: |cffFFFF00%i|r",
    textSize = 12,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = false,
    dontReleaseUntilAcknowledged = true,
    offsetX = 8,
}

HelpTips["RESET_SPELLS_DETAILED"] = {
    parent = "CA2.CharacterAdvancementMain.Main.BottomFrame.ResetSpellsButton",
    text = "You can |cffFFFF00reset|r Abilities up to level 10 for free",
    textSize = 16,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    offsetX = 8,
    strata = "TOOLTIP"
}

local CA2AdvancedTutorial = {
    name = "CA2_advanced_tutorial",
    cvar = "npeCA2AdvancedTutorial",
    classless = true,
    maxLevel = max_level,
    priority = 998,

    events = {
        "BAG_UPDATE",
        "C_QUEST_ACCEPTED",
        "LEARNED_SPELL_IN_TAB",
    },

    sequences = {
        ["MAIN_SEQUENCE"] = {
            "LEARN_SPELLS",
        },
    }
}

NPE:RegisterTutorial(CA2AdvancedTutorial)

local _SUBSCRIBED_EVENT = CA2AdvancedTutorial.SUBSCRIBED_EVENT

function CA2AdvancedTutorial:SUBSCRIBED_EVENT(event, ...)
    if (event == "C_QUEST_ACCEPTED") then
        local id = select(1, ...)
        if id and CA2ForceTutorialOnShow_Quests[id] then
            NPE:QueueTutorialSequence(CA2AdvancedTutorial, "MAIN_SEQUENCE") 
        end

        return
    elseif (event == "BAG_UPDATE") then
        if (NPE and NPE.info and (NPE.info == NPEPopups["LEARN_SPELLS"]) ) then
            local AECurrent = GetItemCount(ItemData.ABILITY_ESSENCE)
            if (NPEPopups["LEARN_SPELLS"].AE > AECurrent) then
                UpdateCAText() -- will show ABILITY_ESSENCE_ADVANCED after 1st ability is learned
            elseif (NPEPopups["LEARN_SPELLS"].AE < AECurrent) then -- may happen after reset
                NPEPopups["LEARN_SPELLS"].AE = AECurrent
            end
        end
        return
    elseif (event == "LEARNED_SPELL_IN_TAB") then
        if (NPE and NPE.info and (NPE.info == NPEPopups["LEARN_SPELLS"]) ) then
            if HelpTips:IsTipAcknowleged("CA2_PICK_DAMAGE") then
                HelpTip:Acknowledge("CA2_PICK_HEAL")
            else
                HelpTip:Acknowledge("CA2_PICK_DAMAGE")
            end
        end
        return
    end
end

NPEPopups["LEARN_SPELLS"] = { -- add creature model from different camera in future
    cvar = CA2AdvancedTutorial.cvar,
    cvarBit = CA2AdvancedTutorial:NextBit(),
    text = "LEARN_SPELLS",
    invisible = true,
    textSize = 16,
    offsetX = 0,
    offsetY = -256,
    helpTip = {"CA2_OPEN", "CA2_PICK_SPELLS1", "ABILITY_ESSENCE_ADVANCED"},
    condition = function()
        if GetItemCount(ItemData.ABILITY_ESSENCE) <= 1 then
            return true
        end
    end,
    onShow = function() 
        SetCVar(HelpTips["CA2_PICK_HEAL"].cvar, false)
        SetCVar(HelpTips["CA2_PICK_DAMAGE"].cvar, false)
        CA2._glows = CreateFramePool("Frame", UIParent, "HighlightFrameTemplate", function(_, highlight) HelpTip:ResetHighlight(highlight) end)
        PrepareCAButtons()
        NPEPopups["LEARN_SPELLS"].AE = GetItemCount(ItemData.ABILITY_ESSENCE)
        HelpTip:Hide("ABILITY_ESSENCE_ADVANCED")
    end,
    onHide = function()  
        ClearOnClickHooksCA()
        CA2._glows:ReleaseAll()        
        --[[HelpTip:Show("RESET_SPELLS_DETAILED")
        HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS, function()
            HelpTip:Hide("RESET_SPELLS_DETAILED")
        end)]]--
    end,
}
-------------------------------------------------------------------------------
--                         Stat allocation tutorial                          --
-------------------------------------------------------------------------------
-- works when you accept quest for stat allocation of when you target an enemy without stat allocated
local StatAllocationTutorial = {
    name = "stat_allocation_basics",
    cvar = "npeStateAllocationTutorial",
    classless = true,
    maxLevel = max_level,
    priority = 999,

    events = {
        "C_QUEST_ACCEPTED",
    },

    sequences = {
        ["C_QUEST_ACCEPTED"] = {
            "CA2_ALLOC1",
        },
    }
}

NPE:RegisterTutorial(StatAllocationTutorial)

local _SUBSCRIBED_EVENT = StatAllocationTutorial.SUBSCRIBED_EVENT

function StatAllocationTutorial:SUBSCRIBED_EVENT(event, ...)
    if (event == "C_QUEST_ACCEPTED") then
        local id = select(1, ...)
        if id and (id == stat_allocation_quest) then
            _SUBSCRIBED_EVENT(StatAllocationTutorial, event, ...)
        end
    end
end

NPEPopups["CA2_ALLOC1"] = {
    cvar = StatAllocationTutorial.cvar,
    cvarBit = StatAllocationTutorial:NextBit(),
    text = "CA2_ALLOC1",
    offsetX = 100,
    offsetY = 100,
    point = "LEFT",
    helpTip = {"CA2_OPEN", "CA2_PICK_STAT"},
    invisible = true,
    onHide = function() 
        if CA2 then 
            HideUIPanel(Collections) 
        end 
    end,
    condition = function() return C_PrimaryStat:GetActivePrimaryStat() end
}
-------------------------------------------------------------------------------
--                         Main quest chain tutorial                         --
-------------------------------------------------------------------------------
do
    HelpTips["GOSSIP_SELECT_HELPER"] = {
    parent = nil,
    text = TIP_QUEST_FRAME_SELECT,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    highlightTarget = HelpTip.TargetType.Box,
    strata = "TOOLTIP",
    }

    HelpTips["MINIMAP_COMPLETE_QUEST"] = {
        parent = "Minimap",
        text = "To complete your Quest, please visit the place marked as |cffFFFF00Question Mark|r at your |cffFFFF00Minimap|r",
        textSize = 16,
        textJustifyH = "CENTER",
        targetPoint = HelpTip.Point.LeftEdgeCenter,
        acknowledgeOnHide = false,
        animatePointer = true,
        dontReleaseUntilAcknowledged = true,
        offsetX = -16,
    }

    HelpTips["CA2_OPEN"] = {
        parent = "TalentMicroButton",
        text = "Click to open the Character Advancement",
        textSize = 16,
        textJustifyH = "CENTER",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        acknowledgeOnHide = false,
        animatePointer = true,
        dontReleaseUntilAcknowledged = true,
        highlightTarget = HelpTip.TargetType.Box,
    }

    HelpTips["XP_BAR"] = {
        parent = "MainMenuExpBar",
        text = "You've gained |cffFFFF00experience|r! You'll |cffFFFF00level up|r when this bar is filled",
        textSize = 16,
        textJustifyH = "CENTER",
        targetPoint = HelpTip.Point.TopEdgeCenter,
        acknowledgeOnHide = false,
        animatePointer = true,
        dontReleaseUntilAcknowledged = true,
        lifetime = LIFETIME_TEMP_TIPS,
        strata = "TOOLTIP",
    }

    local T = {
        name = "FirstLogin_new",
        cvar = "npeFirstLoginTutorial",
        classless = true,
        maxLevel = 15,
        priority = 105,

        spheres = {
           { -8902.076171875, -120.88389587402, 82.026931762695, 384.46034822273, 0, "NORTHSHIRE_START" },
           { -614.88433837891, -4252.9028320313, 38.956047058105, 388.0596908607, 1, "VALLEY_OF_TRIALS_START" },
           { 1675.1284179688, 1676.91796875, 121.67044830322, 541.09544797407, 0, "SHADOW_GRAVE_START" },
           { -3961.9919433594, -13930.590820313, 100.60817718506, 648.97354817455, 530, "AMMENVALE_START" },
           { -6231.3081054688, 334.51699829102, 383.19473266602, 253.30291609563, 0, "COLDRIDGE_START" }, -- start with 1 quest
           { -2917.580078125, -257.98001098633, 52.996799468994, 536.95998883767, 1, "NARACHE_START" },
           { 10311.299804688, 831.46301269531, 1326.4100341797, 406.73116864943, 1, "SHADOWGLEN_START" },
           { 10350.400390625, -6358.0600585938, 33.584270477295, 435.90241171342, 530, "SUNSTRIDER_START" },
        },

        events = {
            "PLAYER_LEVEL_UP",
            "C_QUEST_ACCEPTED",
            "QUEST_GREETING",
            "GOSSIP_SHOW",
            "CA2_ONSHOW",
        },

       sequences = {
            ["NORTHSHIRE_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "NORTHSHIRE_INTRO1", -- starts stat allocation quest
                "NORTHSHIRE_COMPLETE_ALLOCATION",
                "NORTHSHIRE_RETURN_TO_DEPUTY_WILLEM",
                "NORTHSHIRE_COMPLETE_QUEST_1",
                "NORTHSHIRE_ACCEPT_QUEST_2",
                "NORTHSHIRE_PROGRESS_QUEST_2_TARGET_COBOLD",
                "NORTHSHIRE_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["SUNSTRIDER_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "SUNSTRIDER_INTRO1", -- starts stat allocation quest
                "SUNSTRIDER_COMPLETE_ALLOCATION",
                "SUNSTRIDER_RETURN_TO_NPC",
                "SUNSTRIDER_PROGRESS_QUEST_1",
                "SUNSTRIDER_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["SHADOWGLEN_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "SHADOWGLEN_INTRO1", -- starts stat allocation quest
                "SHADOWGLEN_COMPLETE_ALLOCATION",
                "SHADOWGLEN_RETURN_TO_NPC",
                "SHADOWGLEN_PROGRESS_QUEST_1",
                "SHADOWGLEN_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["COLDRIDGE_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "COLDRIDGE_INTRO1", -- starts stat allocation quest
                "COLDRIDGE_COMPLETE_ALLOCATION",
                "COLDRIDGE_RETURN_TO_NPC",
                "COLDRIDGE_PROGRESS_QUEST_1",
                "COLDRIDGE_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["VALLEY_OF_TRIALS_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "VALLEY_OF_TRIALS_INTRO1", -- starts stat allocation quest
                "VALLEY_OF_TRIALS_COMPLETE_ALLOCATION",
                "VALLEY_OF_TRIALS_RETURN_TO_NPC",
                "VALLEY_OF_TRIALS_COMPLETE_QUEST_1",
                "VALLEY_OF_TRIALS_ACCEPT_QUEST_2",
                "VALLEY_OF_TRIALS_PROGRESS_QUEST_2",
                "VALLEY_OF_TRIALS_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["SHADOW_GRAVE_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "SHADOW_GRAVE_INTRO1", -- starts stat allocation quest
                "SHADOW_GRAVE_COMPLETE_ALLOCATION",
                "SHADOW_GRAVE_RETURN_TO_NPC",
                "SHADOW_GRAVE_COMPLETE_QUEST_1",
                "SHADOW_GRAVE_ACCEPT_QUEST_2",
                "SHADOW_GRAVE_PROGRESS_QUEST_2",
                "SHADOW_GRAVE_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["AMMENVALE_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "AMMENVALE_INTRO1", -- starts stat allocation quest
                "AMMENVALE_COMPLETE_ALLOCATION",
                "AMMENVALE_RETURN_TO_NPC",
                "AMMENVALE_COMPLETE_QUEST_1",
                "AMMENVALE_ACCEPT_QUEST_2",
                "AMMENVALE_PROGRESS_QUEST_2",
                "AMMENVALE_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
            ["NARACHE_START"] = {
                "DEVICES", 
                "CAMERA", 
                "MOVEMENT",
                "NARACHE_INTRO1", -- starts stat allocation quest
                "NARACHE_COMPLETE_ALLOCATION",
                "NARACHE_RETURN_TO_NPC",
                "NARACHE_PROGRESS_QUEST_1",
                "NARACHE_RETURN_TO_QUESTGIVER",
                "GENERIC_PTA_GET_LEVELUP_EDITED",
            },
        }
    }

    NPE:RegisterTutorial(T)

    local _SUBSCRIBED_EVENT = T.SUBSCRIBED_EVENT

    function T:SUBSCRIBED_EVENT(event, ...)
        if (event == "PLAYER_LEVEL_UP") and not(T.XP_Done) then
            T.XP_Done = true
            HelpTip:Show("XP_BAR")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("XP_BAR")
            end)
        elseif (event == "C_QUEST_ACCEPTED") then
            local id = select(1, ...)
            if id and (minimap_tutorial_trigger_quests[id]) then
                HelpTip:Show("MINIMAP_COMPLETE_QUEST")
                HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS, function()
                    HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
                end)
            end
        elseif (event == "QUEST_GREETING") or (event == "GOSSIP_SHOW") then
            if (NPE and NPE.info and (NPE.info.questAccept or NPE.info.questTurnIn)) then 
                local quest = NPE.info.questAccept or NPE.info.questTurnIn
                
                if (type(quest) == "table") then
                    for _, qID in pairs(quest) do
                        if (type(qID) == "number") then
                            if DecideParentForGossipHelper(qID, event) then 
                                return 
                            end
                        end
                    end
                elseif (type(quest) == "number") then
                    if DecideParentForGossipHelper(quest, event) then 
                        return 
                    end
                end

            end
        elseif (event == "CA2_ONSHOW") then
            if not(C_PrimaryStat:GetActivePrimaryStat()) then
                NPE:QueueTutorialSequence(StatAllocationTutorial, "C_QUEST_ACCEPTED")
            end

            for quest, _ in pairs(CA2ForceTutorialOnShow_Quests) do
                if (C_Quest:IsOnQuestID(quest)) then
                    NPE:QueueTutorialSequence(CA2AdvancedTutorial, "MAIN_SEQUENCE") 
                    return
                end
            end
        else
            _SUBSCRIBED_EVENT(T, event, ...)
        end
    end
    -------------------------------------------------------------------------------
    --                                General tips                               --
    -------------------------------------------------------------------------------
    T:SetBit(20)

    NPEPopups["DEVICES"] = {
        text = "Position your hands and |cffFFFF00Click|r",
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        justifyH = "CENTER",
        point = "CENTER",
        offsetX = 0,
        offsetY = -192,

        image1 = {
            atlas = "newplayertutorial-keyboard",
            width = 480,
            height = 169,
        },
    }

    NPEPopups["CAMERA"] = { -- needs support for camera movement without IsMouselooking. Needs protected code hook
        text = "|cffFFFF00Look around|r",
        textSize = 16,
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        justifyH = "CENTER",
        point = "CENTER",
        offsetX = 0,
        offsetY = -192,
        condition = function() if (IsMouselooking()) then return true end end,

        image1 = {
            atlas = "newplayertutorial-icon-mouse-turn",
            width = 64,
            height = 64,
        },
    }

    NPEPopups["MOVEMENT"] = {
        text = "|cffFFFF00Walk around|r",
        textSize = 16,
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        justifyH = "CENTER",
        point = "CENTER",
        offsetX = 0,
        offsetY = -192,

        onShow = function() NPEPopups["MOVEMENT"].positionX, NPEPopups["MOVEMENT"].positionY, NPEPopups["MOVEMENT"].positionZ = GetCurrentPlayerPosition() end,

        condition = function() DeviceTutorialSequenceConditions() return NPEPopups["MOVEMENT"].done end,

        image1 = {
            atlas = "newplayertutorial-KEYBOARD",
            width = 172,
            height = 123,
        },
    }

    NPEPopups["GENERIC_PTA_GET_LEVELUP_EDITED"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        textSize = 16,
        text = "Visit |cffFFFF00Book of Acension|r to continue your Path to Ascension Quests|r",
        justifyH = "CENTER",
        point = "CENTER",
        offsetX = 0,
        offsetY = -256,
        creature = 75118,
        buff = "Spotlight",
        usePortraitCamera = true,
        maxLevel = 6,
        questAccept = { 1903537, 1903558, 1903559, 1903560, 1903561, 1903562, 1903563, 1903564 },
    }

    -------------------------------------------------------------------------------
    --                               SUNSTRIDER tips                              --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["SUNSTRIDER_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Magistrix Erona",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SUNSTRIDER_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        hideIfGossip = true,
    }

    NPEPopups["SUNSTRIDER_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Magistrix Erona",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SUNSTRIDER_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" }, 
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        hideIfGossip = true,
    }

    NPEPopups["SUNSTRIDER_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Magistrix Erona",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SUNSTRIDER_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = SUNSTRIDER_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        hideIfGossip = true,
        
    }

   NPEPopups["SUNSTRIDER_PROGRESS_QUEST_1"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 15274,
        text = "Kill |cffFFFF00Mana Wyrms|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        questFinish = SUNSTRIDER_QUEST_1, -- just works bad, better use condition
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
    }

    NPEPopups["SUNSTRIDER_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Magistrix Erona",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SUNSTRIDER_START_NPC_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = SUNSTRIDER_QUEST_1,
        usePortraitCamera = true,
        onShow = function()    
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        hideIfGossip = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }


    -------------------------------------------------------------------------------
    --                               NARACHE tips                              --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["NARACHE_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Grull Hawkwind",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = NARACHE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["NARACHE_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Grull Hawkwind",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = NARACHE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" }, 
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["NARACHE_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Grull Hawkwind",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = NARACHE_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = NARACHE_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        
    }

   NPEPopups["NARACHE_PROGRESS_QUEST_1"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 2955,
        text = "Collect |cffFFFF00Plainstrider Feathers|r and |cffFFFF00Plainstrider Meat|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        questFinish = NARACHE_QUEST_1,
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
    }

    NPEPopups["NARACHE_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Grull Hawkwind",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = NARACHE_START_NPC_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = NARACHE_QUEST_1,
        usePortraitCamera = true,
        onShow = function()            
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }

    -------------------------------------------------------------------------------
    --                               SHADOWGLEN tips                              --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["SHADOWGLEN_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Conservator Ilthalaine",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOWGLEN_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["SHADOWGLEN_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Conservator Ilthalaine",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOWGLEN_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" }, 
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["SHADOWGLEN_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Conservator Ilthalaine",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOWGLEN_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = SHADOWGLEN_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        
    }

   NPEPopups["SHADOWGLEN_PROGRESS_QUEST_1"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 1984,
        text = "Kill |cffFFFF00Young Nightsabers|r and |cffFFFF00Young Thistle Boars|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        questFinish = SHADOWGLEN_QUEST_1, -- just works bad, better use condition
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
    }

    NPEPopups["SHADOWGLEN_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Conservator Ilthalaine",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOWGLEN_START_NPC_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = SHADOWGLEN_QUEST_1,
        usePortraitCamera = true,
        onShow = function()         
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }

    -------------------------------------------------------------------------------
    --                               Coldridge tips                              --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["COLDRIDGE_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Sten Stoutarm",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = COLDRIDGE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT2", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["COLDRIDGE_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Sten Stoutarm",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = COLDRIDGE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT2", "QUEST_FRAME_COMPLETE" }, 
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["COLDRIDGE_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r to Sten Stoutarm",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = COLDRIDGE_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = COLDRIDGE_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
        
    }

   NPEPopups["COLDRIDGE_PROGRESS_QUEST_1"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 705,
        text = "Kill |cffFFFF00Ragged Young Wolves|r to collect |cffFFFF00Tough Wolf Meat|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        questFinish = COLDRIDGE_QUEST_1, -- just works bad, better use condition
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
    }

    NPEPopups["COLDRIDGE_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Sten Stoutarm",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = COLDRIDGE_START_NPC_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = COLDRIDGE_QUEST_1,
        usePortraitCamera = true,
        onShow = function()           
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }
    -------------------------------------------------------------------------------
    --                               AMMENVALE tips                              --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["AMMENVALE_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Megelon",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = AMMENVALE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["AMMENVALE_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Megelon",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = AMMENVALE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" },
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["AMMENVALE_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Megelon",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = AMMENVALE_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = AMMENVALE_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true
    }

    NPEPopups["AMMENVALE_COMPLETE_QUEST_1"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Proenitus",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        creature = AMMENVALE_START_NPC_2,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        buff = "Spotlight",
        questTurnIn = AMMENVALE_QUEST_1,
        usePortraitCamera = true,
    }

    NPEPopups["AMMENVALE_ACCEPT_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Proenitus",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = AMMENVALE_START_NPC_2,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT"},
        buff = "Spotlight",
        questAccept = AMMENVALE_QUEST_2, -- clutting teeth
        usePortraitCamera = true,
        
    }

   NPEPopups["AMMENVALE_PROGRESS_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 16520,
        text = "Kill |cffFFFF00Vale Moths|r to collect |cffFFFF00Vial of Moth Blood|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        usePortraitCamera = true,
        questFinish = AMMENVALE_QUEST_2,
    }

    NPEPopups["AMMENVALE_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Proenitus",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = AMMENVALE_START_NPC_2,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = AMMENVALE_QUEST_2,
        usePortraitCamera = true,
        onShow = function()             
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }
    -------------------------------------------------------------------------------
    --                            Valley of trials tips                          --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["VALLEY_OF_TRIALS_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Kaltunk",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 10176,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["VALLEY_OF_TRIALS_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Kaltunk",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 10176,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" },
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["VALLEY_OF_TRIALS_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Kaltunk",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 10176,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = 4641,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true
    }

    NPEPopups["VALLEY_OF_TRIALS_COMPLETE_QUEST_1"] = { 
        text = "VALLEY_OF_TRIALS_COMPLETE_QUEST_1",
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        offsetX = -300,
        offsetY = 100,
        creature = 3143,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        buff = "Spotlight",
        questTurnIn = 4641,
        invisible = true,
        usePortraitCamera = true
    }

    NPEPopups["VALLEY_OF_TRIALS_ACCEPT_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Gornek",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 3143,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT"},
        buff = "Spotlight",
        questAccept = 788, -- clutting teeth
        usePortraitCamera = true,
        
    }

   NPEPopups["VALLEY_OF_TRIALS_PROGRESS_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 3098,
        text = "Kill |cffFFFF00Mottled Boar|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
        questFinish = 788, 
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
    }

    NPEPopups["VALLEY_OF_TRIALS_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Gornek",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 3143,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = 788,
        usePortraitCamera = true,
        onShow = function()             
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
    }
    -------------------------------------------------------------------------------
    --                             Shadow grave tips                             --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["SHADOW_GRAVE_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Undertaker Mordo",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["SHADOW_GRAVE_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Undertaker Mordo",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_1,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" },
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["SHADOW_GRAVE_RETURN_TO_NPC"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Undertaker Mordo",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_1,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = SHADOW_GRAVE_QUEST_1,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["SHADOW_GRAVE_COMPLETE_QUEST_1"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Shadow Priest Sarvis",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_2,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        buff = "Spotlight",
        questTurnIn = SHADOW_GRAVE_QUEST_1,
        usePortraitCamera = true,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        invisible = true,
    }

    NPEPopups["SHADOW_GRAVE_ACCEPT_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Shadow Priest Sarvis",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_2,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT"},
        buff = "Spotlight",
        questAccept = SHADOW_GRAVE_QUEST_2, -- clutting teeth
        usePortraitCamera = true,
    }

   NPEPopups["SHADOW_GRAVE_PROGRESS_QUEST_2"] = { -- TODO: Make it support 2 models
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 1501,
        text = "Kill |cffFFFF00Mindless Zombies|r and  |cffFFFF00Wretched Ghouls|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        questFinish = SHADOW_GRAVE_QUEST_2, -- just works bad, better use condition
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
        invisible = true,
    }

    NPEPopups["SHADOW_GRAVE_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Shadow Priest Sarvis",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = SHADOW_GRAVE_START_NPC_2,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = SHADOW_GRAVE_QUEST_2,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        usePortraitCamera = true,
        onShow = function()           
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
    }
    -------------------------------------------------------------------------------
    --                               Northshire tips                             --
    -------------------------------------------------------------------------------
    T:ResetBit()

    NPEPopups["NORTHSHIRE_INTRO1"] = { -- TODO: Scan gossip for proper quest
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Deputy Willem",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 823,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["NORTHSHIRE_COMPLETE_ALLOCATION"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "Complete the Quest and\n|cffFFFF00return|r to Deputy Willem",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 823,
        helpTip = { "GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE" },
        buff = "Spotlight",
        questTurnIn = stat_allocation_quest,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true,
    }

    NPEPopups["NORTHSHIRE_RETURN_TO_DEPUTY_WILLEM"] = { 
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Talk|r to Deputy Willem",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 823,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT" },
        buff = "Spotlight",
        questAccept = 783,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        usePortraitCamera = true
    }

    NPEPopups["NORTHSHIRE_COMPLETE_QUEST_1"] = { 
        text = "NORTHSHIRE_COMPLETE_QUEST_1",
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        offsetX = -300,
        offsetY = 100,
        creature = 197,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        buff = "Spotlight",
        questTurnIn = 783,
        invisible = true,
        usePortraitCamera = true,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
    }

    NPEPopups["NORTHSHIRE_ACCEPT_QUEST_2"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Get Quest|r from Marshal McBride",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 197,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_ACCEPT"},
        buff = "Spotlight",
        questAccept = 7,
        usePortraitCamera = true,
    }

    NPEPopups["NORTHSHIRE_PROGRESS_QUEST_2_TARGET_COBOLD"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        creature = 6,
        text = "Kill |cffFFFF00Kobold Vermin|r",
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        questFinish = 7, -- just works bad, better use condition
        dontRestoreOnExitCombat = true,
        usePortraitCamera = true,
        invisible = true,
        --condition = function() return (C_Quest:IsQuestComplete(7) or not(C_Quest:IsOnQuestID(7))) end,
    }

    NPEPopups["NORTHSHIRE_RETURN_TO_QUESTGIVER"] = {
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        text = "|cffFFFF00Return|r to Marshal McBride",
        hideIfGossip = true,
        textSize = 16,
        offsetX = 0,
        offsetY = -256,
        creature = 197,
        image1 = {
            atlas = "newplayertutorial-icon-mouse-rightbutton",
            width = 42,
            height = 64,
            offsetX = 64,
            offsetY = -4,
        },
        buff = "Spotlight",
        questTurnIn = 7,
        helpTip = {"GOSSIP_SELECT_HELPER", "QUEST_FRAME_COMPLETE"},
        usePortraitCamera = true,
        onShow = function()            
            HelpTip:Show("MINIMAP_COMPLETE_QUEST")
            HelpTip.Timeout = Timer.After(LIFETIME_TEMP_TIPS_SHORT, function()
                HelpTip:Hide("MINIMAP_COMPLETE_QUEST")
            end)
        end,
        invisible = true,
    }
    --[[NPEPopups["NORTHSHIRE_INTRO10"] = { -- how to leave goldshire??
        cvar = T.cvar,
        cvarBit = T:NextBit(),
        offsetX = 200,
        offsetY = 100,
        point = "LEFT",
    }]]--
end

-------------------------------------------------------------------------------
--                         How to use spells tutorial                        --
-------------------------------------------------------------------------------
HelpTips["CAST_SPELL_TAME"] = { -- TODO: localize
    parent = "UIParent",
    text = "",

    text_tame = "Use to tame %s",
    text_cast = "Hit |cffFFFF00(%s)|r to cast |cff71d5ff[%s]|r",
    text_cast_nobind = "Click to cast |cff71d5ff[%s]|r",
    text_cast_tame_special = "Great! Keep |cff71d5ff[%s]|r active until you tame %s",

    textSize = 14,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    offsetX = 8,
    highlightTarget = HelpTip.TargetType.Box,
}

HelpTips["CAST_SPELL_DAMAGE"] = { -- TODO: localize
    parent = "UIParent",
    text = "",

    text_damage = "Use to cause damage to your target",
    text_gtg = "Great! Cast Ability once again!",
    text_cast = "Hit |cffFFFF00(%s)|r to cast |cff71d5ff[%s]|r",
    text_cast_nobind = "Click to cast |cff71d5ff[%s]|r",
    text_cast_tame_special = "Great! Keep |cff71d5ff[%s]|r active until you tame %s",

    textSize = 14,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    offsetX = 8,
    highlightTarget = HelpTip.TargetType.Box,
}
-------------------------------------------------------------------------------
--                               Tame tutorial                               --
-------------------------------------------------------------------------------
local TameActionBarTutorial = {
    name = "action_bar_tutorial_tame",
    cvar = "npeTameActionBarTutorial",
    classless = true,
    maxLevel = max_level,
    priority = 1000,
    internalQueue = {},

    events = {
        "UNIT_TARGET", -- for tame beast
        "UNIT_SPELLCAST_SENT",
        "UNIT_PET",
    },

    sequences = {
        ["TAME"] = {
            "SPELL_TEACH_TAME",
        },
    }
}

NPE:RegisterTutorial(TameActionBarTutorial)

local _SUBSCRIBED_EVENT = TameActionBarTutorial.SUBSCRIBED_EVENT

local _PLAYER_REGEN_DISABLED = TameActionBarTutorial.PLAYER_REGEN_DISABLED

function TameActionBarTutorial:PLAYER_REGEN_DISABLED() -- we entered combat
end

function TameActionBarTutorial:PLAYER_REGEN_ENABLED()
    if NPE and NPE.info and (NPE.info == NPEPopups["SPELL_TEACH_TAME"]) then -- reset tame beast when leave combat
        --NPEPopups:ResetCVar("SPELL_TEACH_TAME")
        NPE:ClearTutorialSequence()
        NPE:ClearPopup()
        NPE:GoToNext()
    end
end

function TameActionBarTutorial:SUBSCRIBED_EVENT(event, ...)
    if (event == "UNIT_TARGET") then
        local tameSpell = nil

        if IsTargetStartingAreaCreature() then
            tameSpell = tamable[UnitCreatureType("target")]
        else
            if (NPE and NPE.info and (NPE.info == NPEPopups["SPELL_TEACH_TAME"])) then
                --NPEPopups:ResetCVar("SPELL_TEACH_TAME")
                NPE:ClearTutorialSequence()
                NPE:ClearPopup()
                NPE:GoToNext()
            end
            return
        end

        local tameSpellName = GetSpellInfo(tameSpell)

        if not(tameSpell) then
            return
        end

        local actionButton = GetActionButtonBySpellID(tameSpell)

        if not(actionButton) then
            return
        end

        local tameLine = string.format(HelpTips["CAST_SPELL_TAME"].text_tame, UnitName("target"))
        local castLine = string.format(HelpTips["CAST_SPELL_TAME"].text_cast_nobind, tameSpellName)
        local channelingLine = string.format(HelpTips["CAST_SPELL_TAME"].text_cast_tame_special, tameSpellName, UnitName("target"))
        local hotKey = GetActionButtonKey(actionButton)
        local isChannelingTame = UnitChannelInfo("player")

        if (hotKey) then
            castLine = string.format(HelpTips["CAST_SPELL_TAME"].text_cast, hotKey, tameSpellName)
        end

        if (isChannelingTame) then
            sInfoCast = {GetSpellInfo(isChannelingTame)}
            if CompareSpellInfo({GetSpellInfo(tameSpell)}, sInfoCast) then
                isChannelingTame = true
            else
                isChannelingTame = false
            end
        end

        if NPE then
            if NPE.info and (NPE.info == NPEPopups["SPELL_TEACH_TAME"]) then
                return
            end

            if (UnitName("pet")) then
                return
            end

            HelpTip:Hide("CAST_SPELL_TAME")
            NPEPopups["SPELL_TEACH_TAME"].spell = tameSpell
            HelpTips["CAST_SPELL_TAME"].parent = actionButton

            if (isChannelingTame) then
                HelpTips["CAST_SPELL_TAME"].text = channelingLine
            else
                HelpTips["CAST_SPELL_TAME"].text = tameLine.."\n\n"..castLine
            end

            NPE:QueueTutorialSequence(TameActionBarTutorial, "TAME")
        end

        return
    elseif (event == "UNIT_SPELLCAST_SENT") then
        local caster, spellName, _, target = ...

        if (caster ~= "player") then
            return
        end

        local sInfoCast = {GetSpellInfo(spellName)}

        -- handle tame
        if NPE and NPE.info and (NPE.info == NPEPopups["SPELL_TEACH_TAME"]) then
            local sInfoTame = {GetSpellInfo(NPEPopups["SPELL_TEACH_TAME"].spell)}

            if (CompareSpellInfo(sInfoTame, sInfoCast)) then
                HelpTip:Hide("CAST_SPELL_TAME")
                HelpTips["CAST_SPELL_TAME"].text = string.format(HelpTips["CAST_SPELL_TAME"].text_cast_tame_special, sInfoTame[1], target)
                HelpTip:Show("CAST_SPELL_TAME")
                return
            end
        end
    elseif (event == "UNIT_PET") then
        local arg1 = select(1, ...)

        if (arg1 == "player") then
            if NPE and NPE.info and (NPE.info == NPEPopups["SPELL_TEACH_TAME"]) then
                NPE:CompletePopup()
            end
            return
        end
    end
end

NPEPopups["SPELL_TEACH_TAME"] = {
    cvar = TameActionBarTutorial.cvar,
    cvarBit = TameActionBarTutorial:NextBit(),
    text = "SPELL_TEACH_TAME",
    offsetX = 100,
    offsetY = 100,
    point = "LEFT",
    helpTip = {"CAST_SPELL_TAME"},
    invisible = true,
    condition = function() return  end,
}
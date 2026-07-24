--
-- C_Quest
C_Quest = {
    activeQuests = {},
    lastQuery = 0,
    isQuerying = true,
    queryIds = {},
    turnedInQuests = {},
    completedQuests = {},
}

C_Hook:Register(C_Quest, "QUEST_LOG_UPDATE, QUEST_ACCEPTED, PLAYER_LOGIN, QUEST_QUERY_COMPLETE, ASCENSION_CUSTOM_QUEST_REWARDED")

function C_Quest:QUEST_LOG_UPDATE()
    if self.lastQuery + 10 < GetTime() then
        self.lastQuery = GetTime()
        QueryQuestsCompleted()
    end
end

function C_Quest:ASCENSION_CUSTOM_QUEST_REWARDED(id)
    self.turnedInQuests[id] = true
end

function C_Quest:QUEST_QUERY_COMPLETE()
    local prevCompleteQuests = tcopy(self.completedQuests)

    self:GetCurrentQuests()

    for k, v in pairs(GetQuestsCompleted()) do
        if v then
            self.turnedInQuests[k] = true
        end
    end

    for id in pairs(self.completedQuests) do
        if not prevCompleteQuests[id] then
            C_Hook:SendEvent("C_QUEST_COMPLETED", id)
        end
    end
    
    self.isQuerying = false
    EventRegistry:TriggerEvent("Quest.OnQuestQueryComplete")
end

function C_Quest:PLAYER_LOGIN()
    Timer.After(0.1, function()
        self:GetCurrentQuests(true)
        QueryQuestsCompleted()
    end)
end

function C_Quest:QUEST_ACCEPTED(index)
    local id = self:GetQuestID(index)
    self.activeQuests[id] = true
    
    if self:IsFelforgedChallenge(id) then
        -- decline / leave group on starting a felforged challenge
        DeclineGroup()
        LeaveParty()
    end

    EventRegistry:TriggerEvent("Quest.Accepted", id, index)
end

function C_Quest:IsQuerying()
    return self.isQuerying
end

function C_Quest:GetQuestNameByID(id)
    local title = GetTitleForQuestID(id)
    if title and title ~= "" then
        return title
    end

    local questIndex = GetQuestLogIndexByID(id)
    title = GetQuestLogTitle(questIndex)

    if title and title ~= "" then
        return title
    end

    if self.titles[id] then return self.titles[id] end

    if not self._scanner then
        self._scanner = CreateFrame("GameTooltip", "C_QuestScanner", UIParent, "GameTooltipTemplate")
    end

    self._scanner:SetOwner(UIParent, "ANCHOR_NONE")
    self._scanner:SetHyperlink("quest:"..id)
    title = _G[self._scanner:GetName().."TextLeft1"]:GetText()
    self._scanner:Hide()

    if title ~= RETRIEVING_DATA then
        self.titles[id] = title
    end

    return title
end

function C_Quest:IsQuestCachedByID(id)
    if not id then return false end
    local title = GetTitleForQuestID(id)
    return title and title ~= "" and true or false
end

-- Returns true if a quest or table of quests is completed.
-- Must call QueryQuestsCompleted() sometime before this.
function C_Quest:IsQuestTurnedIn(id)
    if not id then return end

    if type(id) ~= "table" then
        id = { id }
    end

    for _, questId in ipairs(id) do
        if self.turnedInQuests[questId] then
            return true
        end
    end

    return false
end

function C_Quest:GetQuestID(index)
    local link = GetQuestLink(index)
    if link then
        local id = tonumber(link:match("quest:(%d+)"))
        return id
    end
end

-- check if the player is currently on the quest id
-- if a table of ids is passed, returns true if the player is on ANY of the quests in the array
function C_Quest:IsOnQuestID(id)
    if type(id) == "number" then
        return self.activeQuests[id] == true
    end

    if type(id) == "string" then
        id = tonumber(id)
        if id then
            return self.activeQuests[id] == true
        end
        return false
    end

    if type(id) == "table" then
        for _, id in ipairs(id) do
            if self:IsOnQuestID(id) then
                return true
            end
        end
    end

    return false
end

-- check if the player is ready to turn in the quest id
-- if a table of ids is passed, returns true if the player is ready to turn in ANY of the quests in the array
function C_Quest:IsQuestComplete(id)
    if type(id) == "number" then
        return IsQuestComplete(id)
    end

    if type(id) == "string" then
        id = tonumber(id)
        if id then
            return IsQuestComplete(id)
        end
        return false
    end

    if type(id) == "table" then
        for _, id in ipairs(id) do
            if IsQuestComplete(id) then
                return true
            end
        end
    end

    return false
end

function C_Quest:GetCurrentQuests(forceTrack)
    local _, numQuests = GetNumQuestLogEntries()

    self.activeQuests = {}
    self.completedQuests = {}
    local toCollapse = {}
    while numQuests > 0 do
        for i = 1, GetNumQuestLogEntries() do
            local title, _, _, _, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i);
            if isHeader then
                if isCollapsed then
                    tinsert(toCollapse, title)
                    ExpandQuestHeader(i)
                end
            else
                if forceTrack and GetNumQuestWatches() < MAX_WATCHABLE_QUESTS then
                    if title:lower():find("path to ascension:") then
                        AddQuestWatch(i)
                    end
                end
                local id = self:GetQuestID(i)
                self.activeQuests[id] = true
                if isComplete then
                    self.completedQuests[id] = true
                end
                numQuests = numQuests - 1
            end
        end
    end

    while #toCollapse > 0 do
        for i = 1, GetNumQuestLogEntries() do
            local header = toCollapse[1]
            local title, _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i);
            if header == title and isHeader and not isCollapsed then
                CollapseQuestHeader(i)
                tremove(toCollapse, 1)
            end
        end
    end

    return self.activeQuests, self.completedQuests
end

function C_Quest:GetQuestIndexByID(id)
    return GetQuestLogIndexByID(id)
end

function C_Quest:ExpandAllQuestHeaders()
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, isHeader = GetQuestLogTitle(i);
        if isHeader then
            if isCollapsed then
                ExpandQuestHeader(i)
            end
        end
    end
end

function C_Quest:HasOrHasDoneQuest(questId)
    if not questId then return false end
    return self:IsOnQuestID(questId) or self:IsQuestTurnedIn(questId) or WatchFrame_HasAutoQuestPopUp(questId)
end

function C_Quest:IsFelforgedChallenge(questId)
    return self.felforgedChallenges[questId] or false
end

function C_Quest:SendPathToAscensionEvent(message)
    SendAddonMessage("ASC_PATH_TO_ASCENSION", message, "WHISPER", UnitName("player"))
end

function C_Quest:AddAutoQuestPopUp(questId, includeFelforged)
    if not includeFelforged and C_GameMode:IsGameModeActive(Enum.GameMode.Felforged) then
        return
    end

    if self:HasOrHasDoneQuest(questId) then
        return
    end

    local quest = Quest:CreateFromID(questId)
    quest:ContinueOnLoad(function(questId)
        if self:HasOrHasDoneQuest(questId) then
            return
        end
        local name = quest:GetName()
        if not name or name:lower():find("path to ascension") and not C_CVar.GetBool("ptaAutoQuestEnabled") then return end
        AddAutoQuestPopUp(questId, "OFFER")
        WatchFrame_Update(WatchFrame)
    end)

    return true
end

function C_Quest:GetPortraitData(questID)
    local questData = nil

    if not(questID) then
        local questTitle = GetTitleText()
        if (questTitle) then
            for quest, data in pairs(self.PortraitData) do
                local name = C_Quest:GetQuestNameByID(quest)
                if name and (name == questTitle) then
                    questID = quest
                    questData = data
                    break
                end
            end
        end
    else
        questData = self.PortraitData[questID]
    end

    if not(questData) then
        return
    end

    return questData.creature, questData.subText, questData.creatureName, questData.forceDisplayWatchFrame, questID
end

function C_Quest.GetTitleByID(questID)
    local quest = Quest:CreateFromID(questID)
    if not quest then
        return "|cffff0000BAD QUEST ID|r"
    end
    quest:Query()
    return quest:GetName() or RED_FONT_COLOR:WrapText(RETRIEVING_DATA)
end

C_Quest.PortraitData = { -- TODO: Support for multiple creatures
    --[[ 
    [questID] = {
        creature = id,
        creatureName = text,
        subText = text,
        forceDisplayWatchFrame = false, -- will be shown near watch frame if questlog or questframe is closed
    },
    ]]--
    --[[[376] = {
    	creature = 1513,
    	creatureName = "Mangy Duskbat",
    	subText = "Collect 6 Scavenger Paw and 6 Duskbat Wing",
    	forceDisplayWatchFrame = true,
    }
    [7] = {
        creature = 6,
        creatureName = "Kobold Vermin",
        subText = "Kill Kobold Vermin",
        forceDisplayWatchFrame = true,
    },

    [783] = {
        creature = 197,
        creatureName = "Marshal McBride",
        subText = "Talk to Marshal McBride in the Northshire Abbey",
        forceDisplayWatchFrame = true,
    },
      
    [364] = {
        creature = 1501,
        creatureName = "Mindless Zombie",
        subText = "Kill Mindless Zombies and Wretched Ghouls",
        forceDisplayWatchFrame = true,
    },

    [363] = {
        creature = 1569,
        creatureName = "Shadow Priest Sarvis",
        subText = "Find a way out of the crypt and talk to Shadow Priest Sarvis in the chapel at the base of the hill",
        forceDisplayWatchFrame = true,
    },

    [788] = {
        creature = 3098,
        creatureName = "Mottled Boar",
        subText = "Kill Mottled Boars",
        forceDisplayWatchFrame = true,
    },

    [4641] = {
        creature = 3143,
        creatureName = "Gornek",
        subText = "Go to the Den and Talk to Gornek",
        forceDisplayWatchFrame = true,
    },

    [9280] = {
        creature = 16520,
        creatureName = "Vale Moth",
        subText = "Kill Vale Moths to collect Vials of Moth Blood",
        forceDisplayWatchFrame = true,
    },

    [9279] = {
        creature = 16477,
        creatureName = "Proenitus",
        subText = "Go down the road to find Proenitus and talk to him",
        forceDisplayWatchFrame = true,
    },

    [179] = {
        creature = 705,
        creatureName = "Ragged Young Wolf",
        subText = "Kill Ragged Young Wolves to collect Tough Wolf Meat",
        forceDisplayWatchFrame = true,
    },

    [456] = {
        creature = 1984,
        creatureName = "Young Thistle Boar",
        subText = "Kill Young Nightsabers and Young Thistle Boars",
        forceDisplayWatchFrame = true,
    },

    [8325] = {
        creature = 15274,
        creatureName = "Mana Wyrm",
        subText = "Kill Mana Wyrms",
        forceDisplayWatchFrame = true,
    },

    [747] = {
        creature = 2955,
        creatureName = "Plainstrider",
        subText = "Kill Plainstriders to collect Plainstrider Feathers and Plainstrider Meat",
        forceDisplayWatchFrame = true,
    },]]--
}

C_Quest.titles = {
    [580134] = "Path to Ascension: Mystic Extracts",
    [580135] = "Path to Ascension: Mystic Enchant Collection",
    [580136] = "Path to Ascension: Vanity Auctions",
    [580137] = "Path to Ascension: Transmogrify Your Appearance",
    [580138] = "Path to Ascension: End Game Builds",
    [580139] = "Path to Ascension: PvE Power",
    [580140] = "Path to Ascension: PvP Power",
    [580141] = "Path to Ascension: Gear Up!",
    [580142] = "Path to Ascension: Epic Mystic Enchant Collecting",
    [580143] = "Path to Ascension: Legendary Mystic Enchant Collecting",
    [580144] = "Path to Ascension: Dungeon Diving",
    [580145] = "Path to Ascension: Heroic Dungeons",
    [580146] = "Path to Ascension: Flex Raiding",
    [580147] = "Path to Ascension: Mythic Dungeons",
    [580148] = "Path to Ascension: Mythic+ Dungeons",
    [580149] = "Path to Ascension: Heroic Raiding",
    [580162] = "Path to Ascension: Ascended Raiding",
    [580163] = "Path to Ascension: Bloodforging",
    [580164] = "Path to Ascension: Bloodforged Auctions",
    [580165] = "Path to Ascension: Battlegrounds!",
    [580166] = "Path to Ascension: 2v2 Solo Que",
    [580167] = "Path to Ascension: Talk to an Arena Vendor.",
    [580168] = "Path to Ascension: Less Running, More Ressing",
    [580169] = "Path to Ascension: Mystic Enchant Collector",
    [580170] = "Path to Ascension: Epic Riding",
    [580171] = "Path to Ascension: Specialization II",
    [580172] = "Path to Ascension: Bazaar Token",
    [580173] = "Path to Ascension: Ethereal Bazaar",
    [580174] = "Path to Ascension: First Class Experimental Teleporter",
    [580175] = "Path to Ascension: Wargames",
    [580176] = "Path to Ascension: Titan Scrolls",
    [580177] = "Path to Ascension: Speak with a Mentor Recruiter.",
    [580178] = "Path to Ascension: Take Down a Faction Leader",
    [580179] = "Path to Ascension: Take Down a World Boss",
    [580180] = "Path to Ascension: Blood Bowl",
    [580181] = "Path to Ascension: Complete an Invasion",
    [580182] = "Path to Ascension: Apply an Item Enchantment",
    [967171] = "Path to Ascension: Beast Nest Home Wrecker",
    [967172] = "Path to Ascension: A Tempting Hunt",
    [967173] = "Path to Ascension: An Alluring Hunt",
    [967174] = "Path to Ascension: An Irresistible Hunt",
    [967175] = "Path to Ascension: Smashing Hidden Caches",
    [967176] = "Path to Ascension: Key to Treasure",
    [967177] = "Path to Ascension: Locked and Looted",
    [967178] = "Path to Ascension: Epic Keys, Epic Rewards",
    [1903511] = "Path to Ascension: Choose Your Primary Stat",
    [1903512] = "Path to Ascension: Collection and Capitals",
    [1903513] = "Path to Ascension: Seeking Power",
    [1903514] = "Path to Ascension: Fel Commute Your Gear",
    [1903516] = "Path to Ascension: Bloodforged",
    [1903517] = "Path to Ascension: Temporal Contracts",
    [1903518] = "Path to Ascension: Building Your Class Fantasy",
    [1903520] = "Path to Ascension: Rank Up Your Spells",
    [1903521] = "Path to Ascension: Capital of the Horde!",
    [1903522] = "Path to Ascension: Capital of the Alliance!",
    [1903523] = "Path to Ascension: Journey to the Capital",
    [1903524] = "Path to Ascension: Journey to the Capital",
    [1903525] = "Path to Ascension: Journey to the Capital",
    [1903526] = "Path to Ascension: Journey to the Capital",
    [1903527] = "Path to Ascension: Journey to the Capital",
    [1903528] = "Path to Ascension: Journey to the Capital",
    [1903529] = "Path to Ascension: Journey to the Capital",
    [1903530] = "Path to Ascension: Journey to the Capital",
    [1903531] = "Path to Ascension: Journey to the Capital",
    [1903532] = "Path to Ascension: Journey to the Capital",
    [1903533] = "Path to Ascension: Journey to the Capital",
    [1903534] = "Path to Ascension: Journey to the Capital",
    [1903535] = "Path to Ascension: Journey to the Capital",
    [1903536] = "Path to Ascension: Journey to the Capital",
    [1903538] = "Path to Ascension: Reach Level 10!",
    [1903539] = "Path to Ascension: Building Your Class Fantasy",
    [1903540] = "Path to Ascension: Visit an Innkeeper",
    [1903541] = "Path to Ascension: Set Your Hearthstone",
    [1903542] = "Path to Ascension: Power of Professions",
    [1903543] = "Path to Ascension: Call Boards",
    [1903544] = "Path to Ascension: Reach Level 15!",
    [1903545] = "Path to Ascension: Call Boards",
    [1903546] = "Path to Ascension: Flightmaster",
    [1903547] = "Path to Ascension: Flightmaster",
    [1903548] = "Path to Ascension: Reach Level 20!",
    [1903549] = "Path to Ascension: Hybrid Risk",
    [1903550] = "Path to Ascension: Hybrid Risk",
    [1903551] = "Path to Ascension: Fel Commutation Portal",
    [1903552] = "Path to Ascension: Fel Commutation Portal",
    [1903553] = "Path to Ascension: Dungeon Finder",
    [1903554] = "Path to Ascension: Learning to Ride!",
    [1903555] = "Path to Ascension: Learning to Ride!",
    [1903556] = "Path to Ascension: Mount Up!",
    [1903557] = "Path to Ascension: Mount Up!",
    [1903537] = "Path to Ascension: Level Up!",
    [1903558] = "Path to Ascension: Level Up!",
    [1903559] = "Path to Ascension: Level Up!",
    [1903560] = "Path to Ascension: Level Up!",
    [1903561] = "Path to Ascension: Level Up!",
    [1903562] = "Path to Ascension: Level Up!",
    [1903563] = "Path to Ascension: Level Up!",
    [1903564] = "Path to Ascension: Level Up!",
    [1903565] = "Path to Ascension: Reach Level 60!",
    [1903566] = "Path to Ascension: Level Up in Outlands!",
    [1903567] = "Path to Ascension: Level Up in Outlands!",
    [1903568] = "Path to Ascension: Reach Level 70!",
    [2004006] = "Path to Ascension: Mystic Scrolls",
    [2004008] = "Path to Ascension: Mystic Scrolls",
    [2004011] = "Path to Ascension: Daily Reforging",
}

C_Quest.felforgedChallenges = {
    [80147] = true,
    [80165] = true,
    [80166] = true,
    [80167] = true,
    [80185] = true,
    [80186] = true,
    [80187] = true,
    [80205] = true,
    [80206] = true,
    [80207] = true,
    [80456] = true,
    [80457] = true,
    [80458] = true,
    [80459] = true,
    [80460] = true,
    [80461] = true,
    [80462] = true,
    [80463] = true,
    [80464] = true,
    [80465] = true,
    [80466] = true,
    [80467] = true,
    [80468] = true,
    [80469] = true,
    [80470] = true,
    [80266] = true,
    [80267] = true,
    [80268] = true,
    [80269] = true,
    [80270] = true,
    [80271] = true,
    [80272] = true,
    [80273] = true,
    [80274] = true,
    [80275] = true,
    [80636] = true,
    [80637] = true,
    [80638] = true,
    [80639] = true,
    [80640] = true,
    [80641] = true,
    [80642] = true,
    [80643] = true,
    [80644] = true,
    [80645] = true,
    [80646] = true,
    [80647] = true,
    [80648] = true,
    [80649] = true,
    [80650] = true,
    [80036] = true,
    [80056] = true,
    [80076] = true,
    [80096] = true,
    [80116] = true,
    [80136] = true,
    [80156] = true,
    [80176] = true,
    [80196] = true,
    [80216] = true,
    [80501] = true,
    [80502] = true,
    [80503] = true,
    [80504] = true,
    [80505] = true,
    [80506] = true,
    [80507] = true,
    [80508] = true,
    [80509] = true,
    [80510] = true,
    [80511] = true,
    [80512] = true,
    [80513] = true,
    [80514] = true,
    [80515] = true,
    [80233] = true,
    [80234] = true,
    [80235] = true,
    [80236] = true,
    [80237] = true,
    [80238] = true,
    [80239] = true,
    [80240] = true,
    [80241] = true,
    [80242] = true,
    [80591] = true,
    [80592] = true,
    [80593] = true,
    [80594] = true,
    [80595] = true,
    [80596] = true,
    [80597] = true,
    [80598] = true,
    [80599] = true,
    [80600] = true,
    [80601] = true,
    [80602] = true,
    [80603] = true,
    [80604] = true,
    [80605] = true,
    [80085] = true,
    [80086] = true,
    [80087] = true,
    [80105] = true,
    [80106] = true,
    [80107] = true,
    [80125] = true,
    [80126] = true,
    [80127] = true,
    [80145] = true,
    [80441] = true,
    [80442] = true,
    [80443] = true,
    [80444] = true,
    [80445] = true,
    [80446] = true,
    [80447] = true,
    [80448] = true,
    [80449] = true,
    [80450] = true,
    [80451] = true,
    [80452] = true,
    [80453] = true,
    [80454] = true,
    [80455] = true,
    [80028] = true,
    [80048] = true,
    [80068] = true,
    [80088] = true,
    [80108] = true,
    [80128] = true,
    [80148] = true,
    [80168] = true,
    [80188] = true,
    [80208] = true,
    [80396] = true,
    [80397] = true,
    [80398] = true,
    [80399] = true,
    [80400] = true,
    [80401] = true,
    [80402] = true,
    [80403] = true,
    [80404] = true,
    [80405] = true,
    [80406] = true,
    [80407] = true,
    [80408] = true,
    [80409] = true,
    [80410] = true,
    [80033] = true,
    [80053] = true,
    [80073] = true,
    [80093] = true,
    [80113] = true,
    [80133] = true,
    [80153] = true,
    [80173] = true,
    [80193] = true,
    [80213] = true,
    [80321] = true,
    [80322] = true,
    [80323] = true,
    [80324] = true,
    [80325] = true,
    [80326] = true,
    [80327] = true,
    [80328] = true,
    [80329] = true,
    [80330] = true,
    [80331] = true,
    [80332] = true,
    [80333] = true,
    [80334] = true,
    [80335] = true,
    [80040] = true,
    [80060] = true,
    [80080] = true,
    [80100] = true,
    [80120] = true,
    [80140] = true,
    [80160] = true,
    [80180] = true,
    [80200] = true,
    [80220] = true,
    [80561] = true,
    [80562] = true,
    [80563] = true,
    [80564] = true,
    [80565] = true,
    [80566] = true,
    [80567] = true,
    [80568] = true,
    [80569] = true,
    [80570] = true,
    [80571] = true,
    [80572] = true,
    [80573] = true,
    [80574] = true,
    [80575] = true,
    [80032] = true,
    [80052] = true,
    [80072] = true,
    [80092] = true,
    [80112] = true,
    [80132] = true,
    [80152] = true,
    [80172] = true,
    [80192] = true,
    [80212] = true,
    [80306] = true,
    [80307] = true,
    [80308] = true,
    [80309] = true,
    [80310] = true,
    [80311] = true,
    [80312] = true,
    [80313] = true,
    [80314] = true,
    [80315] = true,
    [80316] = true,
    [80317] = true,
    [80318] = true,
    [80319] = true,
    [80320] = true,
    [80035] = true,
    [80055] = true,
    [80075] = true,
    [80095] = true,
    [80115] = true,
    [80135] = true,
    [80155] = true,
    [80175] = true,
    [80195] = true,
    [80215] = true,
    [80486] = true,
    [80487] = true,
    [80488] = true,
    [80489] = true,
    [80490] = true,
    [80491] = true,
    [80492] = true,
    [80493] = true,
    [80494] = true,
    [80495] = true,
    [80496] = true,
    [80497] = true,
    [80498] = true,
    [80499] = true,
    [80500] = true,
    [80030] = true,
    [80050] = true,
    [80070] = true,
    [80090] = true,
    [80110] = true,
    [80130] = true,
    [80150] = true,
    [80170] = true,
    [80190] = true,
    [80210] = true,
    [80276] = true,
    [80277] = true,
    [80278] = true,
    [80279] = true,
    [80280] = true,
    [80281] = true,
    [80282] = true,
    [80283] = true,
    [80284] = true,
    [80285] = true,
    [80286] = true,
    [80287] = true,
    [80288] = true,
    [80289] = true,
    [80290] = true,
    [80022] = true,
    [80042] = true,
    [80062] = true,
    [80082] = true,
    [80102] = true,
    [80122] = true,
    [80142] = true,
    [80162] = true,
    [80182] = true,
    [80202] = true,
    [80351] = true,
    [80352] = true,
    [80353] = true,
    [80354] = true,
    [80355] = true,
    [80356] = true,
    [80357] = true,
    [80358] = true,
    [80359] = true,
    [80360] = true,
    [80361] = true,
    [80362] = true,
    [80363] = true,
    [80364] = true,
    [80365] = true,
    [80222] = true,
    [80223] = true,
    [80224] = true,
    [80225] = true,
    [80226] = true,
    [80227] = true,
    [80228] = true,
    [80229] = true,
    [80230] = true,
    [80231] = true,
    [80576] = true,
    [80577] = true,
    [80578] = true,
    [80579] = true,
    [80580] = true,
    [80581] = true,
    [80582] = true,
    [80583] = true,
    [80584] = true,
    [80585] = true,
    [80586] = true,
    [80587] = true,
    [80588] = true,
    [80589] = true,
    [80590] = true,
    [80006] = true,
    [80007] = true,
    [80025] = true,
    [80026] = true,
    [80027] = true,
    [80045] = true,
    [80046] = true,
    [80047] = true,
    [80065] = true,
    [80066] = true,
    [80426] = true,
    [80427] = true,
    [80428] = true,
    [80429] = true,
    [80430] = true,
    [80431] = true,
    [80432] = true,
    [80433] = true,
    [80434] = true,
    [80435] = true,
    [80436] = true,
    [80437] = true,
    [80438] = true,
    [80439] = true,
    [80440] = true,
    [80255] = true,
    [80256] = true,
    [80257] = true,
    [80258] = true,
    [80259] = true,
    [80260] = true,
    [80261] = true,
    [80262] = true,
    [80263] = true,
    [80264] = true,
    [80621] = true,
    [80622] = true,
    [80623] = true,
    [80624] = true,
    [80625] = true,
    [80626] = true,
    [80627] = true,
    [80628] = true,
    [80629] = true,
    [80630] = true,
    [80631] = true,
    [80632] = true,
    [80633] = true,
    [80634] = true,
    [80635] = true,
    [80039] = true,
    [80059] = true,
    [80079] = true,
    [80099] = true,
    [80119] = true,
    [80139] = true,
    [80159] = true,
    [80179] = true,
    [80199] = true,
    [80219] = true,
    [80546] = true,
    [80547] = true,
    [80548] = true,
    [80549] = true,
    [80550] = true,
    [80551] = true,
    [80552] = true,
    [80553] = true,
    [80554] = true,
    [80555] = true,
    [80556] = true,
    [80557] = true,
    [80558] = true,
    [80559] = true,
    [80560] = true,
    [80037] = true,
    [80057] = true,
    [80077] = true,
    [80097] = true,
    [80117] = true,
    [80137] = true,
    [80157] = true,
    [80177] = true,
    [80197] = true,
    [80217] = true,
    [80516] = true,
    [80517] = true,
    [80518] = true,
    [80519] = true,
    [80520] = true,
    [80521] = true,
    [80522] = true,
    [80523] = true,
    [80524] = true,
    [80525] = true,
    [80526] = true,
    [80527] = true,
    [80528] = true,
    [80529] = true,
    [80530] = true,
    [80244] = true,
    [80245] = true,
    [80246] = true,
    [80247] = true,
    [80248] = true,
    [80249] = true,
    [80250] = true,
    [80251] = true,
    [80252] = true,
    [80253] = true,
    [80606] = true,
    [80607] = true,
    [80608] = true,
    [80609] = true,
    [80610] = true,
    [80611] = true,
    [80612] = true,
    [80613] = true,
    [80614] = true,
    [80615] = true,
    [80616] = true,
    [80617] = true,
    [80618] = true,
    [80619] = true,
    [80620] = true,
    [80034] = true,
    [80054] = true,
    [80074] = true,
    [80094] = true,
    [80114] = true,
    [80134] = true,
    [80154] = true,
    [80174] = true,
    [80194] = true,
    [80214] = true,
    [80471] = true,
    [80472] = true,
    [80473] = true,
    [80474] = true,
    [80475] = true,
    [80476] = true,
    [80477] = true,
    [80478] = true,
    [80479] = true,
    [80480] = true,
    [80481] = true,
    [80482] = true,
    [80483] = true,
    [80484] = true,
    [80485] = true,
    [80031] = true,
    [80051] = true,
    [80071] = true,
    [80091] = true,
    [80111] = true,
    [80131] = true,
    [80151] = true,
    [80171] = true,
    [80191] = true,
    [80211] = true,
    [80291] = true,
    [80292] = true,
    [80293] = true,
    [80294] = true,
    [80295] = true,
    [80296] = true,
    [80297] = true,
    [80298] = true,
    [80299] = true,
    [80300] = true,
    [80301] = true,
    [80302] = true,
    [80303] = true,
    [80304] = true,
    [80305] = true,
    [80024] = true,
    [80044] = true,
    [80064] = true,
    [80084] = true,
    [80104] = true,
    [80124] = true,
    [80144] = true,
    [80164] = true,
    [80184] = true,
    [80204] = true,
    [80381] = true,
    [80382] = true,
    [80383] = true,
    [80384] = true,
    [80385] = true,
    [80386] = true,
    [80387] = true,
    [80388] = true,
    [80389] = true,
    [80390] = true,
    [80391] = true,
    [80392] = true,
    [80393] = true,
    [80394] = true,
    [80395] = true,
    [80029] = true,
    [80049] = true,
    [80069] = true,
    [80089] = true,
    [80109] = true,
    [80129] = true,
    [80149] = true,
    [80169] = true,
    [80189] = true,
    [80209] = true,
    [80411] = true,
    [80412] = true,
    [80413] = true,
    [80414] = true,
    [80415] = true,
    [80416] = true,
    [80417] = true,
    [80418] = true,
    [80419] = true,
    [80420] = true,
    [80421] = true,
    [80422] = true,
    [80423] = true,
    [80424] = true,
    [80425] = true,
    [80023] = true,
    [80043] = true,
    [80063] = true,
    [80083] = true,
    [80103] = true,
    [80123] = true,
    [80143] = true,
    [80163] = true,
    [80183] = true,
    [80203] = true,
    [80366] = true,
    [80367] = true,
    [80368] = true,
    [80369] = true,
    [80370] = true,
    [80371] = true,
    [80372] = true,
    [80373] = true,
    [80374] = true,
    [80375] = true,
    [80376] = true,
    [80377] = true,
    [80378] = true,
    [80379] = true,
    [80380] = true,
    [80021] = true,
    [80041] = true,
    [80061] = true,
    [80081] = true,
    [80101] = true,
    [80121] = true,
    [80141] = true,
    [80161] = true,
    [80181] = true,
    [80201] = true,
    [80336] = true,
    [80337] = true,
    [80338] = true,
    [80339] = true,
    [80340] = true,
    [80341] = true,
    [80342] = true,
    [80343] = true,
    [80344] = true,
    [80345] = true,
    [80346] = true,
    [80347] = true,
    [80348] = true,
    [80349] = true,
    [80350] = true,
    [80038] = true,
    [80058] = true,
    [80078] = true,
    [80098] = true,
    [80118] = true,
    [80138] = true,
    [80158] = true,
    [80178] = true,
    [80198] = true,
    [80218] = true,
    [80531] = true,
    [80532] = true,
    [80533] = true,
    [80534] = true,
    [80535] = true,
    [80536] = true,
    [80537] = true,
    [80538] = true,
    [80539] = true,
    [80540] = true,
    [80541] = true,
    [80542] = true,
    [80543] = true,
    [80544] = true,
    [80545] = true,
}
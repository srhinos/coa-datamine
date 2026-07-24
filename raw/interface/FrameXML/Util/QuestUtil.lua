QuestUtil = {}

PTA_TUTORIALS_SEEN = {}
RegisterForSave("PTA_TUTORIALS_SEEN")

local TalkToMeIcons

function QuestUtil.GetTalkToMeQuestIcon(talkToMeM2)
    if not talkToMeM2 then return end
    talkToMeM2 = talkToMeM2:lower():gsub("interface\\buttons\\", "")
    
    local info = TalkToMeIcons[talkToMeM2]
    if info then
        return info.atlas, info.desaturate
    end
end

-- returns: atlas, desaturated
function QuestUtil.GetQuestStatusIcon(status)
    if not status then return end
    if status == Enum.QuestStatus.Collect then
        return "banker", false
    elseif status == Enum.QuestStatus.Objective then
        return "questkill", false
    elseif status == Enum.QuestStatus.Unavailable then
        return "questnormal", true
    elseif status == Enum.QuestStatus.PickUp then
        return "questnormal", false
    elseif status == Enum.QuestStatus.Trivial then
        return "trivialquests", false
    elseif status == Enum.QuestStatus.Complete then
        return "questturnin", false
    elseif status == Enum.QuestStatus.Incomplete then
        return "questnormal", true
    else
        return "questnormal", false
    end
end

function QuestUtil.IsQuestOnCurrentMap(questID)
    local numQuests = QuestMapUpdateAllQuests()
    for i = 1, numQuests do
        if QuestPOIGetQuestIDByVisibleIndex(i) == questID then
            return true
        end
    end
    
    return false
end

function QuestUtil.GetQuestIDForIndex(questIndex)
    return select(9, GetQuestLogTitle(questIndex))
end

function QuestUtil.IsQuestComplete(questID)
    local questIndex = GetQuestLogIndexByID(questID)
    if not questIndex then
        return false
    end
    local playerMoney = GetMoney()
    local isComplete = select(7, GetQuestLogTitle(questIndex))
    local requiredMoney = GetQuestLogRequiredMoney(questIndex)
    local numObjectives = GetNumQuestLeaderBoards(questIndex)
    if isComplete and isComplete < 0 then
        return false
    elseif numObjectives == 0 and playerMoney >= requiredMoney then
        return true
    end
end

function QuestUtil.IsOnQuestID(questID)
    local questIndex = GetQuestLogIndexByID(questID)
    if questIndex and questIndex ~= 0 then
        return true, questIndex
    end
end

function QuestUtil.IsQuestTurnedIn(questID)
    local quests = GetQuestsCompleted()
    return quests and quests[questID]
end

TalkToMeIcons = {
    ["talktome.m2"] = { atlas = "questnormal" },
    ["talktomeblue.m2"] = { atlas = "questdaily" },
    ["talktomegreen.m2"] = { atlas = "flightpath" },
    ["talktomegrey.m2"] = { atlas = "questnormal", desaturate = true },
    ["talktomequestion_grey.m2"] = { atlas = "questturnin", desaturate = true },
    ["talktomequestion_ltblue.m2"] = { atlas = "questrepeatableturnin" },
    ["talktomequestion_white.m2"] = { atlas = "questturnin-white" },
    ["talktomequestionmark.m2"] = { atlas = "questturnin" },
    ["talktomered.m2"] = { atlas = "questnormal-red" },
    ["talktometrainerclass.m2"] = { atlas = "class" },
    ["talktome_chat.m2"] = { atlas = "chaticon" },
    ["talktome_gears.m2"] = { atlas = "mechagon-projects" },
    ["talktome_petbattles.m2"] = { atlas = "wildbattlepetcapturable" },
    ["talktome_legendary.m2"] = { atlas = "questartifact" },
    ["talktome_questionlegendary.m2"] = { atlas = "questartifactturnin" },
    ["talktome_petbattles_gold.m2"] = { atlas = "wildbattlepet" },
    ["talktomefaded.m2"] = { atlas = "trivialquests" },
    ["talktomeblue_faded.m2"] = { atlas = "map-icon-ignored-blueexclaimation" },
    ["talktomequestionltblue_faded.m2"] = { atlas = "map-icon-ignored-bluequestion" },
    ["talktome_new.m2"] = { atlas = "questnormal" },
    ["talktomequestionmark_new.m2"] = { atlas = "questturnin" },
    ["talktomequestionmark_new_grey.m2"] = { atlas = "questturnin", desaturate = true },
    ["talktome_journey.m2"] = { atlas = "quest-campaign-available" },
    ["talktomequestion_journey.m2"] = { atlas = "quest-campaign-turnin" },
    ["talktomequestion_journey_grey.m2"] = { icon = "quest-campaign-turnin", desaturate = true },
    ["talktomegreen_new.m2"] = { atlas = "flightpath" },
    ["talktomeblue_new.m2"] = { atlas = "questdaily" },
    ["talktomeorange_new.m2"] = { atlas = "quest-legendary-available" },
    ["talktomequestion_new_ltblue.m2"] = { atlas = "questrepeatableturnin" },
    ["talktome_new_questionlegendary.m2"] = { atlas = "quest-legendary-turnin" },
    ["talktomequestion_new_white.m2"] = { atlas = "questturnin-white" },
    ["talktomequestionltblue_new_faded.m2"] = { atlas = "map-icon-ignored-bluequestion" },
    ["talktome_callings.m2"] = { atlas = "quest-dailycampaign-available" },
    ["talktome_callingsquestion.m2"] = { atlas = "quest-dailycampaign-turnin" },
    ["talktome_journey_faded.m2"] = { atlas = "quest-campaign-available-trivial" },
    ["talktome_new_questionlegendary_grey.m2"] = { atlas = "quest-legendary-available", desaturate = true },
    ["talktomeorange_new_grey.m2"] = { atlas = "quest-legendary-available", desaturate = true },
    ["talktomeorange_new_faded.m2"] = { atlas = "quest-legendary-available-trivial" },
    ["talktomeorange_new_trivial.m2"] = { atlas = "quest-legendary-available-trivial" },
    ["talktome_new_questionlegendary_trivial.m2"] = { atlas = "quest-legendary-available-trivial" },
    ["talktome_important.m2"] = { atlas = "quest-important-available" },
    ["talktome_important_faded.m2"] = { atlas = "quest-important-available-trivial" },
    ["talktomequestion_important.m2"] = { atlas = "quest-important-turnin" },
    ["talktomequestion_important_grey.m2"] = { atlas = "quest-important-turnin", desaturate = true },
    ["talktome_asc.m2"] = { atlas = "ascension-questnormal" },
    ["talktome_daily_asc.m2"] = { atlas = "ascension-questnormal-daily" },
    ["talktome_questionmark_asc.m2"] = { atlas = "ascension-questturnin" },
    ["talktome_questionmark_daily_asc.m2"] = { atlas = "ascension-questturnin-daily" },
    ["talktome_questionmark_grey_asc.m2"] = { atlas = "ascension-questturnin", desaturate = true },
}
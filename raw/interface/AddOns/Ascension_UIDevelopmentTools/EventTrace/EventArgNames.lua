local EventArgNames = {}

function EventTrace.GetArgName(event, index)
    return EventArgNames[event] and EventArgNames[event][index] or "arg"..index
end

function EventTrace.GetCombatLogSubEventArgName(subEvent, index)
    return EventArgNames[subEvent] and EventArgNames[subEvent][index-8] or "arg"..index
end

function EventTrace.SetArgNames(event, ...)
    EventArgNames[event] = {...}
end

EventArgNames["CHAT_MSG_SAY"] = {
    "message",
    "senderName",
    "language",
    "channel",
    "recipientName",
    "specialFlags",
    "zoneChannelID",
    "channelIndex",
    "channelBaseName",
    "languageID",
    "chatLineID",
    "senderGUID",
    "presenceID (not used)",
}
EventArgNames["CHAT_MSG_AFK"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BATTLEGROUND"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BATTLEGROUND_LEADER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BG_SYSTEM_ALLIANCE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BG_SYSTEM_HORDE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BG_SYSTEM_NEUTRAL"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BN_CONVERSATION"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_BN_WHISPER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL_JOIN"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL_LEAVE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL_LIST"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL_NOTICE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_CHANNEL_NOTICE_USER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_COMBAT_FACTION_CHANGE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_COMBAT_HONOR_GAIN"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_COMBAT_MISC_INFO"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_COMBAT_XP_GAIN"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_DND"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_EMOTE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_FILTERED"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_GUILD"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_GUILD_ACHIEVEMENT"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_IGNORED"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_LOOT"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONEY"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONSTER_EMOTE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONSTER_SAY"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONSTER_WHISPER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONSTER_PARTY"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_MONSTER_YELL"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_OFFICER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_OPENING"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_PARTY"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_PARTY_LEADER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_PET_INFO"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_RAID"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_RAID_LEADER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_RAID_WARNING"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_RAID_BOSS_EMOTE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_RESTRICTED"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_ACHIEVEMENT"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_SYSTEM"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_SKILL"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_TRADESKILLS"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_TARGETICONS"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_TEXT_EMOTE"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_WHISPER"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_WHISPER_INFORM"] = EventArgNames["CHAT_MSG_SAY"]
EventArgNames["CHAT_MSG_YELL"] = EventArgNames["CHAT_MSG_SAY"]


EventArgNames["CHAT_MSG_ADDON"] = {
    "prefix",
    "message",
    "channel",
    "sender"
}

EventArgNames["COMBAT_LOG_EVENT_UNFILTERED"] = {
    "epochTimestamp",
    "event",
    "sourceGUID",
    "sourceName",
    "sourceFlags",
    "destGUID",
    "destName",
    "destFlags",
}
EventArgNames["COMBAT_LOG_EVENT"] = EventArgNames["COMBAT_LOG_EVENT_UNFILTERED"]

--- START COMBAT LOG SUB EVENTS --- 
EventArgNames["SWING_DAMAGE"] = {
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["SWING_MISSED"] = {
    "missType",
    "amountMissed"
}
EventArgNames["SPELL_DAMAGE"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["SPELL_BUILDING_DAMAGE"] = EventArgNames["SPELL_DAMAGE"]
EventArgNames["SPELL_PERIODIC_DAMAGE"] = EventArgNames["SPELL_DAMAGE"]
EventArgNames["SPELL_MISSED"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "missType",
    "amountMissed"
}
EventArgNames["SPELL_PERIODIC_MISSED"] = EventArgNames["SPELL_MISSED"]
EventArgNames["SPELL_HEAL"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "overhealing",
    "absorbed",
    "critical"
}
EventArgNames["SPELL_BUILDING_HEAL"] = EventArgNames["SPELL_HEAL"]
EventArgNames["SPELL_PERIODIC_HEAL"] = EventArgNames["SPELL_HEAL"]
EventArgNames["SPELL_ENERGIZE"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "powerType",
}
EventArgNames["SPELL_PERIODIC_ENERGIZE"] = EventArgNames["SPELL_ENERGIZE"]
EventArgNames["SPELL_DRAIN"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "powerType",
    "extraAmount",
}
EventArgNames["SPELL_PERIODIC_DRAIN"] = EventArgNames["SPELL_DRAIN"]
EventArgNames["SPELL_LEECH"] = EventArgNames["SPELL_DRAIN"]
EventArgNames["SPELL_PERIODIC_LEECH"] = EventArgNames["SPELL_DRAIN"]
EventArgNames["SPELL_CAST_START"] = {
    "spellID",
    "spellName",
    "spellSchool",
}
EventArgNames["SPELL_CAST_SUCCESS"] = EventArgNames["SPELL_CAST_START"]
EventArgNames["SPELL_CAST_FAILED"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "missType",
}
EventArgNames["SPELL_INTERRUPT"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "extraSpellId",
    "extraSpellName",
    "extraSpellSchool",
}
EventArgNames["SPELL_EXTRA_ATTACKS"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
}
EventArgNames["SPELL_DISPEL_FAILED"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "extraSpellId",
    "extraSpellName",
    "extraSpellSchool",
}
EventArgNames["SPELL_STOLEN"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "extraSpellId",
    "extraSpellName",
    "extraSpellSchool",
    "auraType",
}
EventArgNames["SPELL_DISPEL"] = EventArgNames["SPELL_STOLEN"]
EventArgNames["SPELL_AURA_BROKEN"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "auraType",
}
EventArgNames["SPELL_AURA_BROKEN_SPELL"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "extraSpellId",
    "extraSpellName",
    "extraSpellSchool",
    "auraType",
}
EventArgNames["SPELL_AURA_APPLIED"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "auraType",
}
EventArgNames["SPELL_AURA_REMOVED"] = EventArgNames["SPELL_AURA_APPLIED"]
EventArgNames["SPELL_AURA_REFRESH"] = EventArgNames["SPELL_AURA_APPLIED"]
EventArgNames["SPELL_AURA_APPLIED_DOSE"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "auraType",
    "amount"
}
EventArgNames["SPELL_AURA_REMOVED_DOSE"] = EventArgNames["SPELL_AURA_APPLIED_DOSE"]
EventArgNames["RANGE_DAMAGE"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["RANGE_MISSED"] = {
    "missType",
    "amountMissed"
}
EventArgNames["ENVIRONMENTAL_DAMAGE"] = {
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["DAMAGE_SHIELD"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["DAMAGE_SHIELD_MISSED"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "missType",
}
EventArgNames["ENCHANT_APPLIED"] = {
    "spellName",
    "itemID",
    "itemName",
}
EventArgNames["ENCHANT_REMOVED"] = EventArgNames["ENCHANT_APPLIED"]
EventArgNames["ENVIRONMENTAL_DAMAGE"] = {
    "environmentalType",
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
EventArgNames["DAMAGE_SPLIT"] = {
    "spellID",
    "spellName",
    "spellSchool",
    "amount",
    "overkill",
    "school",
    "resisted",
    "blocked",
    "absorbed",
    "critical",
    "glancing",
    "crushing"
}
--- END COMBAT LOG SUB EVENTS ---
EventArgNames["ENTER_MANASTORM_RESULT"] = {
    "resultStrKey"
}
EventArgNames["MAX_COMPLETED_MANASTORM_LEVEL_UPDATED"] = {
    "oldLevel",
    "newLevel"
}
EventArgNames["MANASTORM_LEVEL_COMPLETED"] = {
    "level",
}
EventArgNames["ACTIVE_MANASTORM_UPDATED"] = {
    "previousLevel",
    "currentLevel",
}
EventArgNames["MANASTORM_LEVEL_UNLOCKED"] = {
    "icon",
    "title",
    "description",
}
EventArgNames["TALKING_HEAD_FRAME_DISPLAY"] = {
    "headerText",
    "bodyText",
    "headerFontSize",
    "bodyFontSize",
    "duration",
    "portrait",
    "textureKit",
    "animationID",
    "loopAnimation",
}

EventArgNames["GLOBAL_MOUSE_DOWN"] = {
    "mouseButton",
}
EventArgNames["GLOBAL_MOUSE_UP"] = EventArgNames["GLOBAL_MOUSE_DOWN"]


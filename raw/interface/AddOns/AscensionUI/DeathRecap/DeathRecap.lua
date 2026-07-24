local Addon = select(2, ...)

local Recap = {}
local RECAP_HYPERLINK_TYPE = "death"
local EXPECTED_PLAYER
local REQUESTED_ID

local COMM_REQ = "ASC_RECAP_REQ"
local COMM_SEND = "ASC_RECAP_SEND"
local COMM_ERR = "ASC_RECAP_ERR"

Addon.DeathRecap = Recap

Recap.CurrentRecap = 0
Recap.Events = {}
Recap.StoredEvents = {
	[0] = {}
}

--
-- Ace Functions
--
function Recap:OnRequestReceived(prefix, text, channel, sender)
	local id = tonumber(text)
	if not id or not Recap.Events[id] then
		Recap:SendCommMessage(COMM_ERR, "Death Recap Link Expired.", channel, sender)
		return
	end

	-- We already encoded this data
	if Recap.StoredEvents[0][id] then
		Recap:SendCommMessage(COMM_SEND, Recap.StoredEvents[0][id], channel, sender)
		return
	end

	-- Serialize -> Compress -> Encode -> Save Encode str -> Send
	local events = Recap.Events[id]
	local serialized = AscensionUI:Serialize(events)

	if serialized then
		local compressed = AscensionUI.Libs.Deflate:CompressDeflate(serialized)

		if compressed then
		local encoded = AscensionUI.Libs.Deflate:EncodeForPrint(compressed)

			if encoded then
				-- Send Data
				Recap.StoredEvents[0][id] = encoded
				Recap:SendCommMessage(COMM_SEND, encoded, channel, sender)
				return
			else
				-- Could not Encode
				Recap:SendCommMessage(COMM_ERR, "Could not Encode Recap", channel, sender)
			end
		else
			-- Could not Compress
			Recap:SendCommMessage(COMM_ERR, "Could not Compress Recap", channel, sender)
		end
	else
		-- Couldn't Serialize
		Recap:SendCommMessage(COMM_ERR, "Could not Serialize Recap", channel, sender)
	end
end

function Recap:OnDataReceived(prefix, text, channel, sender)
	if sender ~= EXPECTED_PLAYER then return end
	EXPECTED_PLAYER = nil
	-- Decode -> Decompress -> Deserialize -> Save -> Open Recap
	local decoded = AscensionUI.Libs.Deflate:DecodeForPrint(text)

	if decoded then
		local decompressed = AscensionUI.Libs.Deflate:DecompressDeflate(decoded)

		if decompressed then
			local deserialized, data = AscensionUI:Deserialize(decompressed)

			if deserialized then
				self.StoredEvents[sender] = self.StoredEvents[sender] or {}
				self.StoredEvents[sender][REQUESTED_ID] = data
				Recap:OpenRecap(sender, REQUESTED_ID)
			else
				-- Could not Deserialize
				self:OnErrReceived(prefix, "Could not Deserialize Recap", channel, sender)
			end
		else
			-- Could not Decompress
			self:OnErrReceived(prefix, "Could not Decompress Recap", channel, sender)
		end
	else
		-- Could not Decode
		self:OnErrReceived(prefix, "Could not Decode Recap", channel, sender)
	end
end

function Recap:OnErrReceived(prefix, text, channel, sender)
	if sender ~= EXPECTED_PLAYER then return end
	EXPECTED_PLAYER = nil
	SendSystemMessage(format("There was an error receiving %s's Death Recap.", sender))
	if text then
		SendSystemMessage(format("Reason: %s", text))
	end
end

-- Register Ace Stuff
LibStub("AceComm-3.0"):Embed(Recap)
Recap:RegisterComm("ASC_RECAP_REQ", "OnRequestReceived")
Recap:RegisterComm("ASC_RECAP_SEND", "OnDataReceived")
Recap:RegisterComm("ASC_RECAP_ERR", "OnErrReceived")

--
-- Functions
--
function Recap:IncrementRecap()
	Recap.CurrentRecap = Recap.CurrentRecap + 1
	Recap.Events[Recap.CurrentRecap] = {}
end

function Recap:GetLastRecap()
	return math.max(Recap.CurrentRecap - 1, 0)
end

function Recap:GetHyperlink(player, id)
	local link
	if player and id then
		link = format("|cff71d5ff|H%s:%s:%s|h[Death Recap for %s]|h|r", RECAP_HYPERLINK_TYPE, player, id, player)
	else
		link = format("|cff71d5ff|H%s:%s:%s|h[You died.]|h|r", RECAP_HYPERLINK_TYPE, UnitName("player"), Recap.CurrentRecap)
	end
	return link
end

function Recap:GetHyperlinkData(link)
	local linkType, player, recapId = strsplit(":", link)
	if linkType == RECAP_HYPERLINK_TYPE then
		return player, tonumber(recapId)
	end
end

--
-- Local Functions
--
local function AddEvent(eventTime, spellId, attacker, isPlayer, damage, school, periodic, crit)
    local e = {}
    e.eventTime = eventTime
    e.spell = spellId
    e.attacker = attacker
    e.isPlayer = isPlayer
    e.damage = damage
    e.school = school
    e.periodic = periodic
    e.crit = crit
	e.healthPercent = (UnitHealth("player") / UnitHealthMax("player"))

    tinsert(Recap.Events[Recap.CurrentRecap], e)
    while #Recap.Events[Recap.CurrentRecap] > 14 do
		tremove(Recap.Events[Recap.CurrentRecap], 1)
	end
end

local function IsPlayer(casterFlags)
	if not casterFlags then return false end
	return bit.band(COMBATLOG_OBJECT_TYPE_PLAYER, casterFlags) == COMBATLOG_OBJECT_TYPE_PLAYER
end

local log = CreateFrame("Frame")

log:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--
-- Events
--
function log:SPELL_PERIODIC_DAMAGE(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, _, damage, _, school, _, _, absorbed, critical)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), -damage, school, true, critical)
end

function log:SPELL_DAMAGE(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, _, damage, _, school, _, _, absorbed, critical)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), -damage, school, false, critical)
end

function log:SWING_DAMAGE(eventTime, _, casterName, casterFlags, _, _, _, damage, _, school, _, _, absorbed, critical)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, -1, casterName, IsPlayer(casterFlags), -damage, school, false, critical)
end

function log:RANGE_DAMAGE(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, _, damage, _, school, _, _, absorbed, critical)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), -damage, school, false, critical)
end

function log:DAMAGE_SPLIT(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, _, damage, _, school, _, _, absorbed, critical)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), -damage, school, false, critical)
end

function log:ENVIRONMENTAL_DAMAGE(eventTime, _, casterName, _, _, _, _, damageType, damage, _, school, _, _, absorbed, _)
    if absorbed then
        damage = damage + absorbed
    end
    AddEvent(eventTime, 0, "Environment", false, -damage, school, false, damageType)
end

function log:SPELL_HEAL(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, school, heal, _, absorbed, critical)
    if absorbed then
        heal = heal + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), heal, school, false, critical)
end

function log:SPELL_PERIODIC_HEAL(eventTime, _, casterName, casterFlags, _, _, _, spellId, _, school, heal, _, absorbed, critical)
    if absorbed then
        heal = heal + absorbed
    end
    AddEvent(eventTime, spellId, casterName, IsPlayer(casterFlags), heal, school, true, critical)
end

-- casterGuid, casterName, casterFlags, targetGuid, targetName, targetFlags, ...
log:SetScript("OnEvent", function(self, event, eventTime, token, ...)
	local isTargetingMe = false
	local target = select(4, ...) -- GUID
	if not target then
		target = select(5, ...) -- fallback to name if no GUID passed. Possible fix for no entries on death.
		isTargetingMe = target == UnitName("player")
	else
		isTargetingMe = target == UnitGUID("player")
	end
    if self[token] and isTargetingMe then
        self[token](self, eventTime, ...)
    end
end)

local listener = CreateFrame("Frame")
listener:SetScript("OnEvent", OnEventToMethod)
listener:RegisterEvent("PLAYER_ALIVE")
listener:RegisterEvent("PLAYER_UNGHOST")
listener:RegisterEvent("PLAYER_DEAD")
listener:RegisterEvent("MANASTORM_FAILED")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("CHAT_MSG_ADDON")

function listener:PLAYER_ALIVE()
	if not UnitIsGhost("player") then
		Recap:IncrementRecap()
		Recap.Frame:Hide()
	end
end

function listener:PLAYER_UNGHOST()
	Recap:IncrementRecap()
	Recap.Frame:Hide()
end

function listener:PLAYER_DEAD()
	SendSystemMessage(Recap:GetHyperlink())
end

function listener:PLAYER_ENTERING_WORLD()
	Recap:IncrementRecap()
end

function listener:MANASTORM_FAILED()
	CloseAllWindows(1)
	SendSystemMessage(Recap:GetHyperlink())
	StaticPopup_Show("MANASTORM_FAILED", nil, nil, Recap.CurrentRecap)
	-- PLAYER_ENTERING_WORLD will increment 
end

-- Hyperlink Overwrite
--
local Original_ChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
function ChatFrame_OnHyperlinkShow(frame, link, text, button)
	local player, id = Recap:GetHyperlinkData(link)
	if player and id then
		if IsModifiedClick("CHATLINK") then
			local hyperlink = Recap:GetHyperlink(player, id)
			ChatEdit_InsertLink(hyperlink)
		else
			if player == UnitName("player") or Recap.StoredEvents[player] and Recap.StoredEvents[player][id] then
				Recap:OpenRecap(player, id)
			else
				SendSystemMessage(format("Requesting Death Recap from %s", player))
				EXPECTED_PLAYER = player
				REQUESTED_ID = id
				Recap:SendCommMessage(COMM_REQ, tostring(id), "WHISPER", player)
			end
		end
	else
		Original_ChatFrame_OnHyperlinkShow(frame, link, text, button)
	end
end
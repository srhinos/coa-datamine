--
-- Hook tooltips to overwrite lines of text in a more readable and maintainable format
--

ModTooltipSetItem = {}

function ModTooltipSetItem:RemapTradeTime(left)
    local text = left:GetText()
    local timeStr = text:match("BIND_TRADE_TIME_REMAINING:(.*)")

    if not timeStr then return end

    local hours = tonumber(timeStr:match("(%d+) hour"))
    local minutes = tonumber(timeStr:match("(%d+) min"))
    local seconds = tonumber(timeStr:match("(%d+) sec"))

    local orig_max = 2 * 60 * 60
    local new_max = 2 * 60 * 60
    local orig_timespan = 0

    if hours and hours > 0 then
        orig_timespan = orig_timespan + (hours * 3600)
    end

    if minutes and minutes > 0 then
        orig_timespan = orig_timespan + (minutes * 60)
    end

    if seconds and seconds > 0 then
        orig_timespan = orig_timespan + seconds
    end

    local new_timespan = math.RemapToRange(orig_timespan, 0, orig_max, 0, new_max)
    local newTimeStr = "|cff71d5ff"..BIND_TRADE_TIME_REMAINING_REPLACEMENT
    if new_timespan >= 3600 then
        hours = floor(new_timespan / 3600)
        new_timespan = new_timespan - (3600 * tonumber(hours))
        newTimeStr = newTimeStr .. hours .. (hours > 1 and " hours" or " hour")
    end

    if new_timespan >= 60 then
        minutes = floor(new_timespan / 60)
        new_timespan = new_timespan - (60 * tonumber(minutes))
        newTimeStr = newTimeStr .. " " .. minutes .. (minutes > 1 and " mins" or " min")
    end

    if new_timespan > 0 then
        seconds = floor(new_timespan)
        newTimeStr = newTimeStr .. " " .. seconds .. (seconds > 1 and " seconds" or " sec")
    end

    newTimeStr = newTimeStr .. ".|r"
    left:SetText(newTimeStr)
end

local ITEM_MOD_FERAL_ATTACK_POWER_SPECIAL = string.gsub(ITEM_MOD_FERAL_ATTACK_POWER, "%%d", "%%d%+")
local ITEM_MOD_FERAL_ATTACK_POWER_EDITED = "Increases attack power by %d in Cat, Bear and Dire Bear forms only."
local ITEM_REQ_ARENA_RATING_SPECIAL = string.gsub(ITEM_REQ_ARENA_RATING, "%%d", "")

function ModTooltipSetItem:OverwriteDruidStats(left)
	if C_Player:GetClass() ~= "HERO" then return end
    local text = left:GetText()
	if (string.gsub(text, ITEM_MOD_FERAL_ATTACK_POWER_SPECIAL, "") == "") then -- fix moonkin and other forms thing
		local val = string.match(text, "%d+")
		val = val and tonumber(val)
		if val then
			left:SetText(string.format(ITEM_MOD_FERAL_ATTACK_POWER_EDITED, math.floor(val/14)))
		end
	end
end

function ModTooltipSetItem:OverwriteArenaRatingRequirement(left)
    local text = left:GetText()
	if (string.find(text,ITEM_REQ_ARENA_RATING_SPECIAL)) then -- fix moonkin and other forms thing
		local newstr = string.gsub(text, "5v5", "3v3")
		left:SetText(newstr)
	end
end

function ModTooltipSetItem:DoCustomFormatters(left)
	if not left:GetFont() or not left:GetText() or not left:GetText():find("%b@@") then return end
	local lineText = left:GetText()
	if lineText:find("%b@@") then
		local _, link = self:GetItem()
		if not link then
			return
		end
		if lineText:startswith("\"") then
			lineText = lineText:sub(2, -2)
		end
		local newText, lines = C_Format.Format(lineText, true, GetItemInfoFromHyperlink(link))
		left:SetText(newText:len() > 0 and "\""..newText.."\"" or "")
		if lines then
			for _, line in ipairs(lines) do
				self:AddLine(line, 1, 0.82, 0, true)
			end
		end
		self:SetMinimumWidth(380, true)
	end
end

--
-- Spell Mods
--
ModTooltipSetSpell = {}

function ModTooltipSetSpell:EmbedSpell(left, right, spellID)
	local lineText = left:GetText()
	if lineText:find("%b@@") then
		local newText, lines = C_Format.Format(lineText, self == ItemRefTooltip, 0, spellID)
		left:SetText(newText)
		local shouldExpand = false
		if lines then
			for _, line in ipairs(lines) do
				shouldExpand = true
				self:AddLine(line, 1, 0.82, 0, true)
			end
		end
		if shouldExpand then
			self:SetMinimumWidth(300, true)
		end
	end
end

if C_Player:IsCustomClass() then
    local isGuardian = C_Player:GetClass() == "GUARDIAN"
    local waterTotemName = BINDING_NAME_MULTICASTACTIONBUTTON3 or "BINDING_NAME_MULTICASTACTIONBUTTON3"

    function ModTooltipSetSpell:CoATotemRename(left, right, spellID)
        local lineText = left:GetText()
        if lineText:startswith(SPELL_TOTEMS) then
            if isGuardian and lineText == SPELL_TOTEMS .. waterTotemName then
                left:SetText(STANDARD)
                return
            end

            local rename = spellID and COA_TOTEM_NAME_REMAP[spellID]
            if not rename then
                return
            end

            left:SetText(rename)
        end
    end
end

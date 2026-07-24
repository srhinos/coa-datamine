if C_AccountInfo.GetGMLevel() < 1 then return end
local positiveLink = "|cff44FF44|Hgmexec:%s:%s|h[%s]|h"
local negativeLink = "|cffFF4444|Hgmexec:%s:%s|h[%s]|h"

local function CmdGetCount(misc)
	if not misc then return 0 end
	
	local count = misc:match("count: (%d+)")
	return count and tonumber(count) or 0
end

local function CmdIsAura(misc1)
	return misc1 == "passive"
end

local function CmdIsAuraActive(misc1, misc2)
	return misc1 == "passive" and misc2 == "active"
end

local function CmdIsSpellKnown(id)
	return IsSpellIDKnown(id)
end

-- area
-- faction
-- object
-- quest
-- player ...
-- skill
-- taxinode
-- title
-- map
local commands = {
	["itemset"] = {
		{
			exec = ".additemset %d",
			label = "Add",
			format = positiveLink,
		},
	},
	["item"] = {
		{
			exec = ".additem %d",
			undo = ".additem %d -1",
			label = "+1x",
			format = positiveLink,
		},
		{
			exec = ".additem %d 10",
			undo = ".additem %d -10",
			label = "+10x",
			format = positiveLink
		},
		{
			exec = ".additem %d -1",
			undo = ".additem %d 1",
			label = "-1x",
			format = negativeLink,
			func = function(id, link, misc) return CmdGetCount(misc) > 0 end,
		},
		{
			exec = ".additem %d -10",
			undo = ".additem %d 10",
			label = "-10x",
			format = negativeLink,
			func = function(id, link, misc) return CmdGetCount(misc) >= 10 end,
		},
		{
			exec = ".additem %d -9999999999",
			label = "-all",
			format = negativeLink,
			func = function(id, link, misc) return CmdGetCount(misc) > 10 end,
		},
	},
	["spell"] = {
		{
			exec = ".learn %d",
			undo = ".unlearn %d",
			label = "learn",
			format = positiveLink,
			func = function(id, link, misc1) return not CmdIsAura(misc1) and not CmdIsSpellKnown(id) end
		},
		{
			exec = ".unlearn %d",
			undo = ".learn %d",
			label = "unlearn",
			format = negativeLink,
			func = function(id, link, misc1) return not CmdIsAura(misc1) and CmdIsSpellKnown(id) end
		},
		{
			exec = ".aura %d",
			undo = ".unaura %d",
			label = "aura",
			format = positiveLink,
			func = function(id, link, misc1, misc2) return CmdIsAura(misc1) and not CmdIsAuraActive(misc1, misc2) end,
		},
		{
			exec = ".unaura %d",
			undo = ".aura %d",
			label = "unaura",
			format = negativeLink,
			func = function(id, link, misc1, misc2) return CmdIsAura(misc1) and CmdIsAuraActive(misc1, misc2)  end,
		},
	},
	["gameevent"] = {
		{
			exec = ".event start %d",
			undo = ".event stop %d",
			label = "Start",
			format = positiveLink,
			func = function(id, link, misc1) return misc1 ~= "active" end
		},
		{
			exec = ".event stop %d",
			undo = ".event start %d",
			label = "Stop",
			format = negativeLink,
			func = function(id, link, misc1) return misc1 == "active" end
		},
	},
	["achievement"] = {
		{
			exec = ".achievement add achievement "..UnitName("player").." %d", -- .. adds confirmation
			label = "Add",
			format = positiveLink,
			func = function(id, link, misc1) return select(4, GetAchievementInfo(id)) == false end
		},
	},
}

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
	-- match (id - [hyperlink] [misc1] [misc2])
	local id, link, misc1, misc2 = msg:match("(%d-) %- (.*)%s*%[([^%]]-)%] %[([^%]]-)%]")

	-- match (id - [hyperlink] [misc1])
	if not id or not link or not misc1 or not misc2 then
		id, link, misc1 = msg:match("(%d-) %- (.*)%s*%[([^%]]-)%]")
	end

	-- match (id - [hyperlink])
	if not id or not link or not misc1 then
		id, link = msg:match("(%d-) %- (.+)")
	end

	id = id and tonumber(id)

	if not id or not link or not link:find("|H") then
		return false
	end

	local hyperlink = LinkUtil:CreateHyperlink(link)
	local type = hyperlink:GetType()

	if not commands[type] then
		return false
	end

	msg = msg:gsub("(%d+)", "|cffFFD100|Hcopy:%1|h[%1]|h", 1)
	for _, command in ipairs(commands[type]) do
		if not command.func or command.func(id, link, misc1, misc2) then
			msg = msg .. " " .. format(command.format, format(command.exec, id), command.undo and format(command.undo, id) or "", command.label)
		end
	end

	return false, msg, ...
end)
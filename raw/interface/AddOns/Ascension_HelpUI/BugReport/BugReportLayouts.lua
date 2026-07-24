local HelpUI = select(2, ...)

HelpUI.BugReportLayouts = {
	[Enum.BugReport.Category.Abilities] = {
		{
			type = "spell",
			key = "SPELL",
			required = true,
		}
	},
	[Enum.BugReport.Category.Talents] = {
		{
			type = "spell",
			key = "TALENT",
			required = true,
		}
	},
	[Enum.BugReport.Category.MysticEnchants] = {
		{
			type = "mysticenchant",
			key = "MYSTICENCHANT",
			required = true,
		}
	},
	[Enum.BugReport.Category.Dungeons] = {
		{
			type = "oneline",
			maxLetters = 255,
			key = "DUNGEON",
			required = true,
		}
	},
	[Enum.BugReport.Category.Raids] = {
		{
			type = "oneline",
			maxLetters = 255,
			key = "RAID",
			required = true,
		}
	},
	[Enum.BugReport.Category.Quests] = {
		{
			type = "oneline",
			maxLetters = 255,
			key = "QUEST",
			required = true,
		}
	},
	[Enum.BugReport.Category.Items] = {
		{
			type = "item",
			maxLetters = 255,
			key = "ITEM",
			required = true,
		}
	},
	[Enum.BugReport.Category.Interface] = {
		{
			type = "autocomplete",
			func = function(searchText)
				local ret = {}
				for _, addon in C_AddonPanel:EnumerateAddOns() do
					if addon.name:lower():find(searchText:lower(), 1, true) then
						tinsert(ret, addon.name)
					end
				end
				return ret
			end,
			maxLetters = 255,
			key = "ADDON",
		}
	},
	[Enum.BugReport.Category.WebsiteAndLauncher] = {
		{
			type = "oneline",
			key = "URL",
		}
	},
	[Enum.BugReport.Category.Other] = {
		
	},
}

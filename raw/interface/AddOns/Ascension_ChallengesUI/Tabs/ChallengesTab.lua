local ChallengesUI = select(2, ...)

ChallengesTabMixin = {}

function ChallengesTabMixin:OnLoad()
	self.filters = {}
	self.Challenges:SetTemplate(self.template or "ChallengeItemTemplate")
	self.Challenges:SetGetNumResultsFunction(C_Challenge.GetNumChallenges)
	self.Challenges.Divider:SetAtlas("activities-divider", Const.TextureKit.IgnoreAtlasSize)
	self.FilterDropDown:Initialize(GenerateClosure(self.InitializeFilterDropDown, self))
	
	self.FilterDropDown.ClearFilters = function()
		self:ClearFilters()
	end

	local highlight = self.Challenges:GetSelectedHighlight()
	highlight:SetTexture() -- disable

	self:RegisterEvent("CHALLENGE_PATCHED")
	self.Refresh = self.UpdateFilteredChallenges
end

function ChallengesTabMixin:OnShow()
	self.Search:SetText("")
	-- if not filters set, set prestige to true if max lvl or prestiged
	if self.filters and not next(self.filters) then
		local isPrestiged = C_Player:IsPrestiged()
		local isMaxLevel = C_Player:IsMaxLevel()
		if isPrestiged or isMaxLevel then 
			self:SetSingleFilter(Enum.ChallengeFilter.Prestige)
		else 
			self:SetSingleFilter(Enum.ChallengeFilter.NotPrestige)
		end
	end
	self:UpdateChallengeList()
end

function ChallengesTabMixin:OnHide()
	ChallengesUI:ClearEditModeChallengeSelection()
end

function ChallengesTabMixin:CheckChallengeExclusiveGroup(challenge)
	if challenge.ExclusiveGroup and challenge.ExclusiveGroup ~= 0 then
		local isActive = C_Challenge.IsChallengeActive(challenge.ID)
		if isActive then
			ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup] = challenge.ID
		elseif ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup] == challenge.ID then
			ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup] = nil
		end
	end
end

function ChallengesTabMixin:IsChallengeExclusiveGroupTaken(challenge)
	if challenge.ExclusiveGroup and challenge.ExclusiveGroup ~= 0 then
		if ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup] ~= nil then
			if ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup] == challenge.ID then
				return false
			else
				return ChallengesUI.activeChallengesByExclusiveGroup[challenge.ExclusiveGroup]
			end
		else
			return false
		end
	end
	return false
end

function ChallengesTabMixin:IsPartOfCustomChallenge()
	return false
end

function ChallengesTabMixin:UpdateChallengeList()
	self:UpdateFilteredChallenges()
end

function ChallengesTabMixin:CanActivateChallenge(challengeID)
	return C_Challenge.CanActivateChallenge(challengeID)
end

function ChallengesTabMixin:UpdateFilteredChallenges()
	self:SetFilter(Enum.ChallengeFilter.Trial, nil)
	self:SetFilter(Enum.ChallengeFilter.DungeonTrial, nil)
	self:SetFilter(Enum.ChallengeFilter.Challenge, true)
	local searchText = self.Search:GetText():trim()
	C_Challenge.SetChallengeFilter(searchText, self.filters)
	self.Challenges:RefreshScrollFrame()
end


function ChallengesTabMixin:ClearFilters()
	wipe(self.filters)
	self:UpdateFilteredChallenges()
end

function ChallengesTabMixin:ToggleFilter(filterKey)
	if self.filters[filterKey] then
		self.filters[filterKey] = nil
	else
		self.filters[filterKey] = true
	end

	self:UpdateFilteredChallenges()
end

function ChallengesTabMixin:SetSingleFilter(filterKey)
	wipe(self.filters)
	self.filters[filterKey] = true
end

function ChallengesTabMixin:SetFilter(filterKey, value)
	self.filters[filterKey] = value
end

local function CreateFilterInfo(self, key, atlas, color)
	local info = UIDropDownMenu_CreateInfo()
	info.text = color and color:WrapText(_G["CHALLENGES_"..key]) or _G["CHALLENGES_"..key]
	info.arg1 = key
	info.checked = self.filters[key]
	info.iconAtlas = atlas
	info.func = function()
		self:ToggleFilter(key)
	end
	UIDropDownMenu_AddButton(info)
end

function ChallengesTabMixin:InitializeFilterDropDown(dropdown, level, menuList)
	CreateFilterInfo(self, Enum.ChallengeFilter.CanActivate)

	UIDropDownMenu_AddSpace(level)
	CreateFilterInfo(self, Enum.ChallengeFilter.Prestige)
	CreateFilterInfo(self, Enum.ChallengeFilter.NotPrestige)

	UIDropDownMenu_AddSpace(level)
	CreateFilterInfo(self, Enum.ChallengeFilter.PvE)
	CreateFilterInfo(self, Enum.ChallengeFilter.PvP)

	UIDropDownMenu_AddSpace(level)
	CreateFilterInfo(self, Enum.ChallengeFilter.Solo)
	CreateFilterInfo(self, Enum.ChallengeFilter.Group)

	UIDropDownMenu_AddSpace(level)
	CreateFilterInfo(self, Enum.ChallengeFilter.Easy, BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Standard], BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Standard])
	CreateFilterInfo(self, Enum.ChallengeFilter.Normal, BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Intermediate], BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Intermediate])
	CreateFilterInfo(self, Enum.ChallengeFilter.Hard, BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Advanced], BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Advanced])
	CreateFilterInfo(self, Enum.ChallengeFilter.VeryHard, BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Expert], BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Expert])
	CreateFilterInfo(self, Enum.ChallengeFilter.Impossible, BuildCreatorUtil.DifficultyAtlas[Enum.BuildDifficulty.Impossible], BuildCreatorUtil.DifficultyColors[Enum.BuildDifficulty.Impossible])
end

function ChallengesTabMixin:GetChallengeInfoByIndex(index, isExpanded)
	return C_Challenge.GetChallengeAtIndex(index, isExpanded)
end

function ChallengesTabMixin:GetChallengeIDByIndex(index)
	return C_Challenge.GetChallengeIDByIndex(index)
end

function ChallengesTabMixin:CHALLENGE_PATCHED()
	self:UpdateChallengeList()
end

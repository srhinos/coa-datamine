C_TrackerHeader = {
	Horde = { Banner = "HordeScenario-TitleBG" },
	Alliance = { Banner = "AllianceScenario-TitleBG" },
	ChallengeDeath = { Banner = "challenges-death-titleBG", titleY = -56, subTextY = 22 },
	ChallengeRedemption = { Banner = "challenges-redemption-titleBG", titleY = -56, subTextY = 22 },
	ChallengeCriteriaFailed = { Banner = "challenges-red-titleBG", titleY = -56, subTextY = 22 },
	ChallengeCriteriaSuccess = { Banner = "challenges-green-titleBG", titleY = -56, subTextY = 22 },
	ChallengeCompleted = { Banner = "challenges-green-flag-titleBG", titleY = -56, subTextY = 22 },
	ChallengeFailed = { Banner = "challenges-red-flag-titleBG", titleY = -56, subTextY = 22 },
}

function C_TrackerHeader:Show(template, title, subText, sound, fadeInDuration, holdTime, fadeOutDuration)
	if type(template) == "string" then
		template = C_TrackerHeader[template] or _G[template]
	end

	if not template then return end
	if not title then return end
	
	title = _G[title] or title
	subText = subText and _G[subText] or subText
	
	fadeInDuration = fadeInDuration or 0.75
	holdTime = holdTime or 2
	fadeOutDuration = fadeOutDuration or 1

	if not self.Frame then
		self.Frame = Ascension_TrackerHeader
	end

	-- C_PopupQueue ensures we will only have 1 visible at a time
	C_PopupQueue:Add(self.Frame, function()
		self.Frame.Title:SetText(title)
		self.Frame.SubText:SetText(subText)
		
		self.Frame.Banner:SetAtlas(template.Banner, Const.TextureKit.UseAtlasSize)
		
		self.Frame.Title:SetPointOffset(template.titleX or 0, template.titleY or 0)
		self.Frame.SubText:SetPointOffset(template.subTextX or 0, template.subTextY or 0)

		self.Frame:FrameFadeIn(fadeInDuration)

		if sound then
			PlaySound(sound)
		end

		self.HoldTimer = Timer.NewTimer(fadeInDuration + holdTime, function()
			self.HoldTimer = nil
			self.Frame:FrameFadeOut(fadeOutDuration)
		end)
	end)
end

function C_TrackerHeader:Hide()
	if self.Frame then
		if self.HoldTimer then
			self.HoldTimer:Cancel()
			self.HoldTimer = nil
		end
		UIFrameFadeRemoveFrame(self.Frame)
		self.Frame:Hide()
	end
end

function C_TrackerHeader:CHALLENGE_DEATH_UPDATE(challengeID, remainingLives, totalLives)
	local challenge = C_Challenge.GetChallengeInfo(challengeID)
	if not challenge then return end
	local challengeName = challenge.Name
	
	--C_TrackerHeader:Show(template, title, subText, sound, fadeInDuration, holdTime, fadeOutDuration)
	if remainingLives == 0 then
		C_TrackerHeader:Show("ChallengeDeath", challengeName, CHALLENGES_YOU_DIED:format(UnitLevel("player")), SOUNDKIT.UI_PROVINGGROUNDS_TRIAL_FAIL, 0.75, 6, 2)
	else
		C_TrackerHeader:Show("ChallengeRedemption", challengeName, CHALLENGES_YOU_DIED_LIVES_REMAINING:format(remainingLives, totalLives), SOUNDKIT.UI_GARRISON_MISSION_COMPLETE_MISSIONFAIL_STINGER, 0.75, 12, 2)
	end
end

function C_TrackerHeader:CHALLENGE_CRITERIA_COMPLETED(challengeID, level, requirementType, value1, value2, value3)
	local challenge = C_Challenge.GetChallengeInfo(challengeID)
	if not challenge then return end
	local challengeName = challenge.Name
	if not challengeName then return end
	
	local name, description, _, _, formatter1, formatter2, formatter3 = ChallengeUtil.GetRequirementLocalization(requirementType)
	value1, value2, value3 = ChallengeUtil.ApplyMiscValueFormatting(value1, value2, value3, formatter1, formatter2, formatter3)
	name = name:format(value1, value2, value3)
	description = description:format(value1, value2, value3)
	C_TrackerHeader:Show("ChallengeCriteriaSuccess", challengeName, CHALLENGES_CRITERIA_SUCCESS:format(name, description), SOUNDKIT.UI_SCENARIO_BONUSOBJECTIVE_SUCCESS, 0.75, 4, 1)
end

function C_TrackerHeader:CHALLENGE_CRITERIA_FAILED(challengeID, level, requirementType, value1, value2, value3)
	local challenge = C_Challenge.GetChallengeInfo(challengeID)
	if not challenge then return end
	local challengeName = challenge.Name
	if not challengeName then return end
	local name, description, _, _, formatter1, formatter2, formatter3 = ChallengeUtil.GetRequirementLocalization(requirementType)
	value1, value2, value3 = ChallengeUtil.ApplyMiscValueFormatting(value1, value2, value3, formatter1, formatter2, formatter3)
	name = name:format(value1, value2, value3)
	description = description:format(value1, value2, value3)
	C_TrackerHeader:Show("ChallengeCriteriaFailed", challengeName, CHALLENGES_CRITERIA_FAILED:format(name, description), SOUNDKIT.UI_GARRISON_MISSION_COMPLETE_MISSIONFAIL_STINGER, 0.75, 4, 1)
end


function C_TrackerHeader:CHALLENGE_COMPLETED(challengeID, level)
	local challenge = C_Challenge.GetChallengeInfoByLevel(challengeID, level)
	if not challenge then return end
	local challengeName = challenge.Name
	C_TrackerHeader:Show("ChallengeCompleted", format("%s (Level: %s)", challengeName, level), CHALLENGES_CHALLENGE_COMPLETED, SOUNDKIT.UI_PROVINGGROUNDS_TRIAL_SUCCESS, 0.75, 5, 1)
end

function C_TrackerHeader:CHALLENGE_FAILURE_ADDED(challengeID, level)
	local challenge = C_Challenge.GetChallengeInfoByLevel(challengeID, level)
	if not challenge then return end
	local challengeName = challenge.Name
	C_TrackerHeader:Show("ChallengeFailed", format("%s (Level: %s)", challengeName, level), CHALLENGES_CHALLENGE_FAILED, SOUNDKIT.UI_PROVINGGROUNDS_TRIAL_FAIL, 0.75, 4, 1)
end

C_Hook:Register(C_TrackerHeader, "CHALLENGE_DEATH_UPDATE")
C_Hook:Register(C_TrackerHeader, "CHALLENGE_CRITERIA_COMPLETED")
C_Hook:Register(C_TrackerHeader, "CHALLENGE_CRITERIA_FAILED")
C_Hook:Register(C_TrackerHeader, "CHALLENGE_COMPLETED")
C_Hook:Register(C_TrackerHeader, "CHALLENGE_FAILURE_ADDED")
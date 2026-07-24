ChallengeUtil = {}
ChallengeUtil.FormatFunctionSignature = "return function(value) %s end"

function ChallengeUtil.GetRequirementLocalization(RequirementType)
	local name, description, atlas, altAtlas, formatter1, formatter2, formatter3 = C_Challenge.GetRequirementLocalization(RequirementType)
	if not name then
		name = RequirementType
		description = ""
		atlas = "mechagon-projects"
	end

	if formatter1 and formatter1 ~= "" then
		formatter1 = assert(loadstring(ChallengeUtil.FormatFunctionSignature:format(formatter1)))()
	else
		formatter1 = nil
	end

	if formatter2 and formatter2 ~= "" then
		formatter2 = assert(loadstring(ChallengeUtil.FormatFunctionSignature:format(formatter2)))()
	else
		formatter2 = nil
	end

	if formatter3 and formatter3 ~= "" then
		formatter3 = assert(loadstring(ChallengeUtil.FormatFunctionSignature:format(formatter3)))()
	else
		formatter3 = nil
	end
	
	return name, description, atlas, altAtlas, formatter1, formatter2, formatter3
end

function ChallengeUtil.ApplyMiscValueFormatting(miscValue1, miscValue2, miscValue3, formatter1, formatter2, formatter3)
	if formatter1 and miscValue1 then
		miscValue1 = formatter1(miscValue1)
	end

	if formatter2 and miscValue2 then
		miscValue2 = formatter2(miscValue2)
	end

	if formatter3 and miscValue3 then
		miscValue3 = formatter3(miscValue3)
	end

	return miscValue1, miscValue2, miscValue3
end

function ChallengeUtil.AreConditionsEqual(conditionA, conditionB)
	if conditionA.ConditionType ~= conditionB.ConditionType then
		return false
	end

	if conditionA.ConditionValue1 ~= conditionB.ConditionValue1 then
		return false
	end

	if conditionA.ConditionValue2 ~= conditionB.ConditionValue2 then
		return false
	end

	if conditionA.ConditionValue3 ~= conditionB.ConditionValue3 then
		return false
	end

	if conditionA.ElseGroup ~= conditionB.ElseGroup then
		return false
	end

	if conditionA.NegativeCondition ~= conditionB.NegativeCondition then
		return false
	end

	if conditionA.ConditionMet ~= conditionB.ConditionMet then
		return false
	end

	return true
end

function ChallengeUtil.CanGroup()
	return not C_Challenge.HasChallengeRule("CHALLENGE_RULES_TYPE_NO_GROUP")
end

function ChallengeUtil.CanUseGroupFinder()
	return not C_Challenge.HasChallengeRule("CHALLENGE_RULES_TYPE_NO_DUNGEON_FINDER")
end

function ChallengeUtil.CanQueueBattlegrounds()
	return not C_Challenge.HasChallengeRule("CHALLENGE_RULES_TYPE_NO_BATTLEGROUND_FINDER")
end

function ChallengeUtil.CanQueueArenas()
	return not C_Challenge.HasChallengeRule("CHALLENGE_RULES_TYPE_NO_ARENA_FINDER")
end

TrialCreatorUtil = {}

function TrialCreatorUtil.ContinueOnLoad(trialID, callback)
	local trial = C_TrialCreator.GetTrialInfo(trialID)
	if trial then
		callback(trial)
		return
	end
	
	Timer.AfterEvent("TRIAL_QUERY_RESULT", function()
		local trial = C_TrialCreator.GetTrialInfo(trialID)
		if trial then
			callback(trial)
			return
		end
	end)
	C_TrialCreator.QueryTrials()
end

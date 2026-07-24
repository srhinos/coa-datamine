MythicPlusObjectiveTrackerMixin = CreateFromMixins(ObjectiveTrackerBaseMixin)

function MythicPlusObjectiveTrackerMixin:OnLoad()
	ObjectiveTrackerBaseMixin.OnLoad(self)
	self.ObjectiveBlock.Encounters:SetSubObjectiveTemplate("MythicPlusTextObjectiveTemplate")
	local timerWidth = self.MainBlock.Timer:GetWidth()
	local bonusOffset = MYTHIC_PLUS_BONUS_LEVEL_PERCENT[1] * timerWidth
	self.MainBlock.Timer.PlusThreeNotch:SetPoint("CENTER", self.MainBlock.Timer, "LEFT", bonusOffset, 2)

	bonusOffset = MYTHIC_PLUS_BONUS_LEVEL_PERCENT[2] * timerWidth
	self.MainBlock.Timer.PlusTwoNotch:SetPoint("CENTER", self.MainBlock.Timer, "LEFT", bonusOffset, 2)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:HookEvent("MYTHIC_PLUS_COUNTDOWN_STARTED")
	self:HookEvent("MYTHIC_PLUS_STARTED")

	if C_MythicPlus.IsKeystoneActive() then
		self:Show()
	end
	
	self:RegisterCallback("OnCollapse", GenerateClosure(self.OnCollapse, self))
	self:RegisterCallback("OnExpand", GenerateClosure(self.OnExpand, self))
	
	-- need solution to summons first
	--GameTooltip:HookScript("OnTooltipSetUnit", GenerateClosure(self.OnTooltipSetUnit, self))
end

function MythicPlusObjectiveTrackerMixin:OnShow()
	self:HookEvent("MYTHIC_PLUS_ENCOUNTER_UPDATE")
	self:HookEvent("MYTHIC_PLUS_CHAMPIONS_UPDATE")
	self:HookEvent("MYTHIC_PLUS_TRASH_UPDATE")
	self:HookEvent("MYTHIC_PLUS_TIMER_UPDATE")
	self:HookEvent("MYTHIC_PLUS_COMPLETE")

	if C_MythicPlus.IsKeystoneActive() then
		self:SetupActiveKeystone()
	end
	self:UpdateHeight()
end

function MythicPlusObjectiveTrackerMixin:OnHide()
	self:UnhookEvent("MYTHIC_PLUS_ENCOUNTER_UPDATE")
	self:UnhookEvent("MYTHIC_PLUS_CHAMPIONS_UPDATE")
	self:UnhookEvent("MYTHIC_PLUS_TRASH_UPDATE")
	self:UnhookEvent("MYTHIC_PLUS_TIMER_UPDATE")
	self:UnhookEvent("MYTHIC_PLUS_COMPLETE")
end

function MythicPlusObjectiveTrackerMixin:SetupActiveKeystone()
	if not C_MythicPlus.IsKeystoneActive() then return end
	local activeKeystone = C_MythicPlus.GetActiveKeystoneInfo()
	self:SetupLevel(activeKeystone.keystoneLevel)
	self:SetAffixes(activeKeystone.activeAffixes)
	self:SetupTimer()
	
	local dungeonID = activeKeystone.dungeonID
	self:SetupDungeonName(dungeonID)
	self.finalEncounter = C_MythicPlus.GetMapFinalEncounter(dungeonID)
	self:UpdateEncounters(C_MythicPlus.GetMapEncounters(dungeonID))
	self:UpdateFinalEncounter(self.finalEncounter)

	local trash = C_MythicPlus.GetActiveKeystoneTrash()
	self:SetupEnemyForces(trash.trashDead, trash.trashRequired)
	
	self.MainBlock.BottomRightText:SetFormattedText(MYTHIC_PLUS_S_PCT_LOOT, math.round((activeKeystone.rewardMultiplier or 1) * 100))

	if activeKeystone.keystoneLevel >= 14 then
		self.ObjectiveBlock.Champions:Show()
		self.ObjectiveBlock.EnemyForces:SetPoint("TOP", self.ObjectiveBlock.Champions, "BOTTOM", 0, -8)
		local champions = C_MythicPlus.GetActiveKeystoneChampions()
		self:SetupChampions(champions.championsDead, champions.championsRequired)
	else
		self.ObjectiveBlock.Champions:Hide()
		self.ObjectiveBlock.EnemyForces:SetPoint("TOP", self.ObjectiveBlock.FinalEncounter, "BOTTOM", 0, -8)
	end
	
	local ObjectiveBlocks = {
		self.ObjectiveBlock.FinalEncounter,
		self.ObjectiveBlock.Encounters,
		self.ObjectiveBlock.Champions,
		self.ObjectiveBlock.EnemyForces,
	}
	
	local lastVisibleObjective
	for _, objective in ipairs(ObjectiveBlocks) do
		if objective:IsShown() then
			if lastVisibleObjective then
				local y = objective == self.ObjectiveBlock.EnemyForces and -8 or -4
				objective:SetPoint("TOP", lastVisibleObjective, "BOTTOM", 0, y)
			else
				objective:SetPoint("TOP", self.ObjectiveBlock, "TOP", 0, -2)
			end
			lastVisibleObjective = objective
		end
	end
end

function MythicPlusObjectiveTrackerMixin:SetupLevel(level)
	self.MainBlock.Level:SetFormattedText(UNIT_LEVEL_TEMPLATE, level)
end

function MythicPlusObjectiveTrackerMixin:SetAffixes(affixes)
	for index, button in ipairs(self.MainBlock.AffixButtons) do
		local affixID = affixes[index]
		button:SetShown(affixID ~= nil)
		button:SetAffix(affixID)
	end
end

function MythicPlusObjectiveTrackerMixin:SetupTimer()
	local _, totalTime = C_MythicPlus.GetActiveKeystoneTime()
	self.totalTime = totalTime
	self.MainBlock.Timer:SetMinMaxValues(0, totalTime)
	self.MainBlock.Timer:SetStatusBarColor(1, 1, 1)
	self:UpdateTimer(totalTime) -- use total time here because if the key is running it will be updated soon enough.
end

function MythicPlusObjectiveTrackerMixin:SetupDungeonName(dungeonID)
	local dungeonName = GetLFGDungeonInfo(dungeonID)
	self:SetHeaderText(dungeonName)
end

function MythicPlusObjectiveTrackerMixin:UpdateEncounters(encounterIDs)
	self.encounters = encounterIDs
	self.ObjectiveBlock.Encounters:ClearSubObjectives()
	local numEncounters = #encounterIDs
	if numEncounters == 0 or numEncounters == 1 and encounterIDs[1] == self.finalEncounter then
		self.ObjectiveBlock.Encounters:Hide()
		return
	end
	local encountersInfo = C_MythicPlus.GetActiveKeystoneEncounters()
	local dead, required = encountersInfo.encountersCompleted, encountersInfo.encountersRequired

	if required == 0 then
		self.ObjectiveBlock.Encounters:Hide()
		return
	elseif required == numEncounters then
		self.ObjectiveBlock.Encounters:LockExpanded()
	else
		self.ObjectiveBlock.Encounters:UnlockExpanded()
	end

	self.ObjectiveBlock.Encounters:Show()

	self.ObjectiveBlock.Encounters:SetObjective(MYTHIC_PLUS_DEFEAT_ADDITIONAL_BOSSES, dead, required)
	for _, encounterID in ipairs(encounterIDs) do
		if encounterID ~= self.finalEncounter then
			local encounterName, _, _, _, _, _, isDead = GetEncounterInfo(encounterID)
			self.ObjectiveBlock.Encounters:SetSubObjective(encounterName, isDead and 1 or 0, 1)
		end
	end
end

function MythicPlusObjectiveTrackerMixin:UpdateFinalEncounter(encounterID)
	local encounterName, _, _, _, _, _, isDead = GetEncounterInfo(encounterID)
	self.ObjectiveBlock.FinalEncounter:SetObjective(encounterName, isDead and 1 or 0, 1)
end

function MythicPlusObjectiveTrackerMixin:SetupEnemyForces(trashDead, maximumTrash)
	if not maximumTrash or maximumTrash <= 0 then
		self.ObjectiveBlock.EnemyForces:Hide()
	end
	self.ObjectiveBlock.EnemyForces:Show()
	self.ObjectiveBlock.EnemyForces:SetObjective(MYTHIC_PLUS_DEFEAT_ENEMY_FORCES, trashDead, maximumTrash)
end

function MythicPlusObjectiveTrackerMixin:UpdateEnemyForces(trashDead)
	self.ObjectiveBlock.EnemyForces:SetProgress(trashDead)
end

function MythicPlusObjectiveTrackerMixin:SetupChampions(championsDead, maximumChampions)
	if not maximumChampions or maximumChampions <= 0 then
		self.ObjectiveBlock.Champions:Hide()
	end
	self.ObjectiveBlock.Champions:Show()
	self.ObjectiveBlock.Champions:SetObjective(MYTHIC_PLUS_DEFEAT_CHAMPIONS, championsDead, maximumChampions)
end

function MythicPlusObjectiveTrackerMixin:UpdateChampions(championsDead)
	self.ObjectiveBlock.Champions:SetProgress(championsDead)
end

function MythicPlusObjectiveTrackerMixin:UpdateTimer(timeLeft)
	self.MainBlock.Timer:SetValue(timeLeft)
	self:UpdateTimerFlipbook()
	self.MainBlock.TimeLeft:SetText(SecondsToClock(timeLeft))

	local bonusTwoTimeLeft = timeLeft - (self.totalTime * (1 - MYTHIC_PLUS_BONUS_LEVEL_PERCENT[1]))
	if bonusTwoTimeLeft > 0 then
		self.MainBlock.TimeLeft2:Show()
		self.MainBlock.TimeLeft2:SetText(SecondsToClock(bonusTwoTimeLeft))

		local bonusThreeTimeLeft = timeLeft - (self.totalTime * (1 - MYTHIC_PLUS_BONUS_LEVEL_PERCENT[2]))
		if bonusThreeTimeLeft > 0 then
			self.MainBlock.TimeLeft3:Show()
			self.MainBlock.TimeLeft3:SetText(SecondsToClock(bonusThreeTimeLeft))
		else
			self.MainBlock.TimeLeft3:Hide()
		end
	else
		self.MainBlock.TimeLeft2:Hide()
		self.MainBlock.TimeLeft3:Hide()
	end
end

-- updates the timer flipbook / plays animation if changing tiers
function MythicPlusObjectiveTrackerMixin:UpdateTimerFlipbook()
	local percent = self.MainBlock.Timer:GetPercentage()
	local atlas = self.timerAtlas
	local flipbook

	if percent > MYTHIC_PLUS_BONUS_LEVEL_PERCENT[1] then
		flipbook = "quality-barfill-flipbook-t5-x2"
		if atlas == flipbook then return end
	elseif percent > MYTHIC_PLUS_BONUS_LEVEL_PERCENT[2] then
		flipbook = "quality-barfill-flipbook-t2-x2"
		if atlas == flipbook then return end
	else
		flipbook = "quality-barfill-flipbook-t1-x2"
		if atlas == flipbook then return end
	end

	self.timerAtlas = flipbook
	self.MainBlock.Timer:SetStatusBarFlipbookAtlas(flipbook, 374, 54, 60, 30, true)
	self.MainBlock.Timer:PlayFlipbook()
end

function MythicPlusObjectiveTrackerMixin:GetDesiredHeight()
	local height = ObjectiveTrackerBaseMixin.GetDesiredHeight(self)
	if not self.collapsed then
		height = height + self.MainBlock:GetHeight() + self.ObjectiveBlock:GetHeight()
	end
	return height
end

function MythicPlusObjectiveTrackerMixin:OnCollapse()
	self.MainBlock:Hide()
	self.ObjectiveBlock:Hide()
end

function MythicPlusObjectiveTrackerMixin:OnExpand()
	self.MainBlock:Show()
	self.ObjectiveBlock:Show()
end

function MythicPlusObjectiveTrackerMixin:OnTooltipSetUnit(tooltip)
	if not C_MythicPlus.IsKeystoneActive() then return end
	if not self:IsShown() then return end
	
	local _, unit = tooltip:GetUnit()
	if not unit then return end

	if UnitReaction(unit, "player") > 4 then return end
	
	local classification = UnitClassification(unit)

	if classification == "trivial" or classification == "minus" then return end
	local unitCount = math.max(classification == "normal" and 1 or 2, (math.max(60, (UnitLevel(unit) % 10)) * 2))
	local trash = C_MythicPlus.GetActiveKeystoneTrash()
	local percent =  unitCount / trash.trashRequired
	tooltip:AddLine(format("Enemy Forces: %.2f%% (count: %d)", percent * 100, unitCount), 1, 0.82, 0)
end

function MythicPlusObjectiveTrackerMixin:PLAYER_ENTERING_WORLD()
	if C_MythicPlus.IsKeystoneActive() and C_Instance.IsInDungeon() then
		self:Show()
	else
		self:Hide()
	end
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_STARTED()
	if not self:IsShown() then
		self:Show()
	end
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_COUNTDOWN_STARTED()
	if not self:IsShown() then
		self:Show()
	else
		self:SetupActiveKeystone()
	end
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_TIMER_UPDATE(timeLeft)
	self:UpdateTimer(timeLeft)
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_TRASH_UPDATE(trashDead)
	self:UpdateEnemyForces(trashDead)
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_CHAMPIONS_UPDATE(championsDead)
	self:UpdateChampions(championsDead)
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_ENCOUNTER_UPDATE(encounterID)
	if encounterID == self.finalEncounter then
		self:UpdateFinalEncounter(self.finalEncounter)
	else
		self:UpdateEncounters(self.encounters)
	end
end

function MythicPlusObjectiveTrackerMixin:MYTHIC_PLUS_COMPLETE(onTime)
	local color = onTime and NECROLORD_GREEN_COLOR or VENTHYR_RED_COLOR
	self.timerAtlas = "quality-barfill-flipbook-t2-x2"
	self.MainBlock.Timer:SetStatusBarFlipbookAtlas("quality-barfill-flipbook-t2-x2", 374, 54, 60, 30, true)
	self.MainBlock.Timer:SetStatusBarColor(color:GetRGB())
	self.MainBlock.Timer:PlayFlipbook()
end
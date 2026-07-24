Quest = {}
QuestMixin = {}

function Quest:CreateFromID(questID)
	local quest = CreateFromMixins(QuestMixin)
	quest:SetQuestID(questID)
	return quest
end

function QuestMixin:Query()
	if not self:IsCached() then
		QuestQueryListener:Query(self.questID)
	end
end

function QuestMixin:SetQuestID(questID)
	self.questID = questID
end

function QuestMixin:Clear()
	self.questID = nil
end

function QuestMixin:IsEmpty()
	return not self.questID or type(self.questID) ~= "number" or self.questID <= 0
end

function QuestMixin:IsCached()
	if self:IsEmpty() then return false end
	return C_Quest:IsQuestCachedByID(self.questID)
end

function QuestMixin:GetName()
	if self:IsEmpty() then return end
	return C_Quest:GetQuestNameByID(self.questID)
end

function QuestMixin:HasOrHasDoneQuest()
	if self:IsEmpty() then return false end
	return C_Quest:HasOrHasDoneQuest(self.questID)
end

function QuestMixin:GetQuestLogIndex()
	if self:IsEmpty() then return end
	return C_Quest:GetQuestIndexByID(self.questID)
end

function QuestMixin:GetLink()
	if self:IsEmpty() then return end
	-- we cant actually get the quest level I dont think
	return "|cffffff00|Hquest:"..self.questID..":"..UnitLevel("player").."|h["..self:GetName().."]|h|r"
end

-- adds a callback to be executed when this quest data is available, executes immediately if already loaded.
function QuestMixin:ContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyQuest:ContinueOnLoad", 2)
	end

	if self:IsCached() then
		func(self.questID)
		return
	end

	QuestQueryListener:AddCallback(self.questID, func)
end

-- returns a function that will cancel this callback when called
function QuestMixin:CancelableContinueOnLoad(func)
	if type(func) ~= "function" or self:IsEmpty() then
		error("Usage: NonEmptyQuest:ContinueOnLoad", 2)
	end

	if self:IsCached() then
		func(self.questID)
		return
	end

	return QuestQueryListener:AddCancelableCallback(self.questID, func)
end 


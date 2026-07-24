local AddonName, Addon = ...

--
-- Mass reveal statistics base
--
SkillCardsMassRevealStatisticsMixin = {}

SkillCardsMassRevealStatisticsMixin.rewardItemIDs = {
	ItemData.DARKMOON_TICKET, ItemData.GOLDEN_DARKMOON_TICKET, 
	ItemData.GOLDEN_TALENT_SEALED_CARD_PACK, ItemData.GOLDEN_ABILITY_SEALED_CARD_PACK,
	ItemData.ABILITY_SEALED_CARD_PACK,
	ItemData.TALENT_SEALED_CARD_PACK,
}

function SkillCardsMassRevealStatisticsMixin:Init(boosterCount)
	self:SetProcessing(true)

	--self.cardsAdded = 0
	self.boostersRevealed = boosterCount
	self.duplicatesRevealed = 0

	for _, v in pairs(self.rewardItemIDs) do
		self.rewardItems[v] = 0
	end
end

function SkillCardsMassRevealStatisticsMixin:OnLoad()
	self.isProcessing = false

	--self.cardsAdded = 0
	self.boostersRevealed = 0
	self.duplicatesRevealed = 0

	self.rewardItems = {}
end

function SkillCardsMassRevealStatisticsMixin:SetProcessing(value)
	self.isProcessing = value
end

function SkillCardsMassRevealStatisticsMixin:IsProcessing()
	return self.isProcessing
end

function SkillCardsMassRevealStatisticsMixin:SetDuplicates(value)
	self.duplicatesRevealed = value
end

function SkillCardsMassRevealStatisticsMixin:AddRewardItem(itemID, count)
	if (self.rewardItems[itemID]) then
		self.rewardItems[itemID] = self.rewardItems[itemID] + count
	end
end
--
-- SkillCardsUI
--
SkillCardsUI = CreateFrame("FRAME")
SkillCardsUI:SetScript("OnEvent", OnEventToMethod)

--[[function SkillCardsUI:SetAutoReveal(autoReveal)
	self.DB.autoRevealStatus = autoReveal
end]]--

function SkillCardsUI:GetAutoReveal()
	return true -- auto reveal is always on
	--return self.DB and self.DB.autoRevealStatus
end

function SkillCardsUI:GetStatistics()
	return self.DB and self.DB.massRevealStats
end

function SkillCardsUI:IsMassRevealProcessing()
	local statistics = self:GetStatistics()
	local result = statistics and statistics:IsProcessing()

	if not result then -- safe check for if user removed saved variables
		if not statistics then
			return result
		end

		local pendingCards = SkillCardUtil.GetNumPendingCards()

		if pendingCards > 5 then
			SkillCardsUI:InitStatistics(math.ceil(pendingCards/5)) -- ugly but will work
			result = statistics:IsProcessing()

			dprint("SkillCardsUI:IsMassRevealProcessing POSTFIX")
		end
	end

	return result
end

function SkillCardsUI:SetMassRevealProcessing(value)
	local statistics = self:GetStatistics()

	if (statistics) then
		statistics:SetProcessing(value)
	end
end

function SkillCardsUI:SetMassRevealDuplicates(value)
	local statistics = self:GetStatistics()

	if (statistics) then
		statistics:SetDuplicates(value)
	end
end

function SkillCardsUI:AddMassRevealRewardItem(itemID, count)
	local statistics = self:GetStatistics()

	if statistics and statistics:IsProcessing() then
		statistics:AddRewardItem(itemID, count)

		if SkillCardsFrame.UnlockFrame.MassRevealStatisticsFrame and SkillCardsFrame.UnlockFrame.MassRevealStatisticsFrame:IsVisible() then
			SkillCardsFrame.UnlockFrame.MassRevealStatisticsFrame:UpdateVisual()
		end
	end
end

function SkillCardsUI:InitStatistics(boosterCount)
	local statistics = self:GetStatistics()

	if (statistics) then
		statistics:Init(boosterCount)
		SkillCardsFrame.UnlockFrame:InitStatistics()
	end
end

function SkillCardsUI:IsWaitingToRevealMultiplePacks()
	return self.waitingForToOpenPacks and true or false
end

function SkillCardsUI:SetWaitingForToOpenPacks(value)
	self.waitingForToOpenPacks = value
	self:RegisterEvent("PURCHASE_SEALED_CARD_RESULT")
end

SkillCardsUI:RegisterEvent("ADDON_LOADED")

--
-- Events
--

function SkillCardsUI:PURCHASE_SEALED_CARD_RESULT(result) -- in perfect replace with its own unique event or arg inside of this event
	if result == "PURCHASE_SEALED_CARD_OK" then
		if (self:IsWaitingToRevealMultiplePacks()) then
			dprint("SkillCardsUI:PURCHASE_SEALED_CARD_RESULT OK")
			self:InitStatistics(self.waitingForToOpenPacks)
		end
	end

	self.waitingForToOpenPacks = nil
	self:UnregisterEvent("PURCHASE_SEALED_CARD_RESULT")
end

function SkillCardsUI:ADDON_LOADED(addon)
	if addon ~= AddonName then return end

	-- DB is a realm specified data
	Ascension_SkillCard_RDB = Ascension_SkillCard_RDB or {}

	local realmName = GetRealmName() or ""

	Ascension_SkillCard_RDB[realmName] = Ascension_SkillCard_RDB[realmName] or {}

	self.DB = Ascension_SkillCard_RDB[realmName]

	if not(self.DB.massRevealStats) then
		self.DB.massRevealStats = CreateFromMixinsAndLoad(SkillCardsMassRevealStatisticsMixin)
		dprint("SkillCardsUI:ADDON_LOADED CREATE db for "..realmName)
	elseif not(self.DB.massRevealStats.IsProcessing) then
		Mixin(self.DB.massRevealStats, SkillCardsMassRevealStatisticsMixin) -- saved variables don't store functions
		dprint("SkillCardsUI:ADDON_LOADED LOAD db for "..realmName)
	end

	self:UnregisterEvent("ADDON_LOADED")

	-- replace
	C_Gossip:RedirectNPC(10031, ShowSkillCards)
end

-------------------------------------------------------------------------------
--                                    UI                                     --
-------------------------------------------------------------------------------
SkillCardsFrame = CreateFrame("FRAME", "SkillCardsFrame", Collections, "PortraitFrameTemplate")
SkillCardsFrame:SetPoint("BOTTOM", 0, 8)
SkillCardsFrame:Hide()
MixinAndLoadScripts(SkillCardsFrame, SkillCardsFrameMixin)
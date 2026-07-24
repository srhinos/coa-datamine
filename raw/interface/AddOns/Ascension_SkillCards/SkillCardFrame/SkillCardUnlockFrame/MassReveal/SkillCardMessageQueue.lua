local CARDS_PER_BOOSTER = 5
local DUPLICATE_REVEAL_DELAY = 2
local MAX_DUPLICATES_PER_REQUEST = 100

local REVEALING_CARDS = "Revealing Duplicates %i/%i"
-- 
-- Reward mixin
-- 
SkillCardStatisticRewardItemMixin = {}

function SkillCardStatisticRewardItemMixin:OnLoad()
	self:Layout()
	self.Glow.AnimG:Play()
end

function SkillCardStatisticRewardItemMixin:Init(itemID, total)
	self.item = Item:CreateFromID(itemID)

	SetPortraitToTexture(self.Icon, self.item:GetIcon())

	self:UpdateTotal(total)
	self:Show()
end

function SkillCardStatisticRewardItemMixin:UpdateTotal(value)
	self.Total:SetText(value)
end

function SkillCardStatisticRewardItemMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
	GameTooltip:SetHyperlink(self.item:GetLink())
	GameTooltip:Show()
end

function SkillCardStatisticRewardItemMixin:OnLeave()
	GameTooltip:Hide()
end

function SkillCardStatisticRewardItemMixin:Layout()
	self:SetSize(64, 64)

	self.Icon = self:CreateTexture(nil, "BORDER")
    self.Icon:SetPoint("CENTER", 0, 0)
    self.Icon:SetSize(38, 38)

	self.Total = self:CreateFontString(nil, "OVERLAY")
	self.Total:SetFontObject(NumberFontNormal)
	self.Total:SetPoint("BOTTOMRIGHT", self.Icon, 0, -4)
	self.Total:SetJustifyH("RIGHT")

    self.Ring = self:CreateTexture(nil, "ARTWORK")
    self.Ring:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
    self.Ring:SetPoint("CENTER", self.Icon, 0, -2)
    self.Ring:SetSize(48, 48)

    self.Glow = self:CreateTexture(nil, "BACKGROUND")
    self.Glow:SetAtlas("services-ring-large-glowspin", Const.TextureKit.IgnoreAtlasSize)
    self.Glow:SetSize(96, 96)
    self.Glow:SetPoint("CENTER", self.Icon, 0, 0)

	self.Glow.AnimG = self.Glow:CreateAnimationGroup()

	self.Glow.AnimG.Rotation = self.Glow.AnimG:CreateAnimation("Rotation")
	self.Glow.AnimG.Rotation:SetDuration(60)
	self.Glow.AnimG.Rotation:SetOrder(1)
	self.Glow.AnimG.Rotation:SetEndDelay(0)
	self.Glow.AnimG.Rotation:SetSmoothing("NONE")
	self.Glow.AnimG.Rotation:SetDegrees(-360)

	self.Glow.AnimG:SetLooping("REPEAT")

    self.Highlight = self:CreateTexture(nil, "OVERLAY")
    self.Highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    self.Highlight:SetSize(48, 48)
    self.Highlight:SetPoint("CENTER", self.Icon, 0, 0)
    self.Highlight:SetBlendMode("ADD")
    self.Highlight:Hide()

    self:SetHighlightTexture(self.Highlight)
end

-- 
-- Menu
--
SkillCardMassRevealStatsMixin = CreateFromMixins(CallbackRegistryMixin)

function SkillCardMassRevealStatsMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:Layout()
	
	self:GenerateCallbackEvents(
	{
		"OnStatisticsExit",
		"OnMassRevealAnimationFinished",
	})

	self.rewardsIDToFrame = {}
	self.rewardsFramesPool = CreateFramePool("Button", self.StatisticsFrame, "SkillCardStatisticRewardItemFrame")

	self.duplicateUUIDs = {}
	self.totalDuplicateRequests = 0
	self.duplicateRevealTimer = 0
	self.hasClaimResponse = false

	self:SetScript("OnEvent", OnEventToMethod)

	self.OkButton:SetScript("OnClick", GenerateClosure(self.OkButtonOnClick, self))
	self.ProgressText.AG:Play()

	self.AnimatedFrame.AnimatedCards[17].AnimationGroupAppear.FadeIn:SetScript("OnFinished", GenerateClosure(self.PlayExplosion, self))
end

function SkillCardMassRevealStatsMixin:OnShow()
	if next(self.duplicateUUIDs) then -- safe guard
		self:RegisterOnUpdate(self.duplicateUUIDs)
	end
end

function SkillCardMassRevealStatsMixin:Init()
	self:ClearRewards()
	self.StatisticsFrame:Hide()
	self.AnimatedFrame:PlayCardsAnimation()
end

function SkillCardMassRevealStatsMixin:ClearRewards()
	self.rewardsFramesPool:ReleaseAll()
	wipe(self.rewardsIDToFrame)
	self.rewardsIDToFrame = {}
end

function SkillCardMassRevealStatsMixin:OnHide()
	self:UnhookAllEvents()
end

function SkillCardMassRevealStatsMixin:OkButtonOnClick()
	self:TriggerEvent("OnStatisticsExit")
end

function SkillCardMassRevealStatsMixin:PlayExplosion()
	self.AnimatedFrame:PlayExplosion()
	-- Go back to revealing cards
	 self:TriggerEvent("OnMassRevealAnimationFinished")
end

function SkillCardMassRevealStatsMixin:ShowStatistics()
	self.StatisticsFrame:Show()
	self:UpdateVisual()
end

function SkillCardMassRevealStatsMixin:SetCardStyle(isGolden)
	self.AnimatedFrame:SetCardStyle(isGolden)
end

function SkillCardMassRevealStatsMixin:UpdateVisual()
	local height = 0
	local lastVisibleReward, firstVisibleReward
	local totalItems = 0
	local statistics = SkillCardsUI:GetStatistics()

	if next(statistics) then
		self.StatisticsFrame.BoostersTotal:SetText(statistics.boostersRevealed)
		self.StatisticsFrame.RevealedCardsTotal:SetText(statistics.boostersRevealed*CARDS_PER_BOOSTER)
		self.StatisticsFrame.DuplicateCardsTotal:SetText(statistics.duplicatesRevealed)
	end

	if (statistics.duplicatesRevealed > 0) then
		self.StatisticsFrame.DuplicateCardsText:Show()
		self.StatisticsFrame.DuplicateCardsTotal:Show()
		height = (self.StatisticsFrame.BoostersTotal:GetHeight()*3)+8
	else
		height = (self.StatisticsFrame.BoostersTotal:GetHeight()*2)+8
		self.StatisticsFrame.DuplicateCardsTotal:Hide()
		self.StatisticsFrame.DuplicateCardsText:Hide()
	end

	for itemID, originalCount in pairs(statistics.rewardItems) do
		if (originalCount > 0) then
			if self.rewardsIDToFrame[itemID] then
				self.rewardsIDToFrame[itemID]:UpdateTotal(originalCount)
			else
				self.rewardsIDToFrame[itemID] = self.rewardsFramesPool:Acquire()
				self.rewardsIDToFrame[itemID]:Init(itemID, originalCount)
			end

			local button = self.rewardsIDToFrame[itemID]

			-- init rewards
			if totalItems == 0 then
				self.StatisticsFrame.RewardsLabel:Show()
				height = height + 24 + self.StatisticsFrame.RewardsLabel:GetHeight()

				firstVisibleReward = button
				firstVisibleReward:ClearAndSetPoint("TOP", self.StatisticsFrame.RewardsLabel, "BOTTOM", 0, -12)
			else
				button:ClearAndSetPoint("LEFT", lastVisibleReward, "RIGHT", 0, 0)
			end

			lastVisibleReward = button
			totalItems = totalItems + 1
		end
	end

	if (firstVisibleReward) then
		height = height + 64
		firstVisibleReward:SetPoint("TOP", self.StatisticsFrame.RewardsLabel, "BOTTOM", -32*(totalItems-1), -12)
	else
		self.StatisticsFrame.RewardsLabel:Hide()
	end

	self.StatisticsFrame:SetHeight(height+64)

	local duplicateRequestsLeft = self:GetTotalDuplicateRequestsToSend()

	if duplicateRequestsLeft > 0 then
		self.OkButton:Hide()
		self.ProgressText:Show()
		self.ProgressText:SetText(string.format(REVEALING_CARDS, self.totalDuplicateRequests-duplicateRequestsLeft, self.totalDuplicateRequests))
	else
		self.ProgressText:Hide()
		self.OkButton:Show()
	end
end

-- 
-- Reveal request queue
--
function SkillCardMassRevealStatsMixin:GetForceRevealCollected()
	local UUIDs = {}
	local UUIDsRequestTable = nil
	local cardsPerRequest = 0

	for pendingIndex = 1, SkillCardUtil.GetNumPendingCards() do
		local UUID, cardID = SkillCardUtil.GetPendingSkillCardAtIndex(pendingIndex)

		if C_SkillCardCollection.IsCollected(cardID) then
			cardsPerRequest = cardsPerRequest + 1

			if (cardsPerRequest > MAX_DUPLICATES_PER_REQUEST) then
				cardsPerRequest = 1
			end

			if (cardsPerRequest == 1) then
				UUIDs[#UUIDs+1] = {}
				UIDsRequestTable = UUIDs[#UUIDs]
			end

			table.insert(UIDsRequestTable, UUID)
		end
	end

	if next(UUIDs) then
		-- we need to send 1 by 1, waiting for server reply with 1 second interval between requests. 
		-- use special queue in SkillCards for that
		return UUIDs
	end
end

function SkillCardMassRevealStatsMixin:RegisterOnUpdate()
	local UUIDs = self:GetForceRevealCollected()

	if not UUIDs then
		dprint("SkillCardMassRevealStatsMixin:RegisterOnUpdate no uuids")
		self:ClearOnUpdate()
		return
	end

	self.duplicateUUIDs = UUIDs or {}
	self.totalDuplicateRequests = #self.duplicateUUIDs
	self.duplicateRevealTimer = DUPLICATE_REVEAL_DELAY
	self.hasClaimResponse = true

	self:SetScript("OnUpdate", self.OnUpdateDuplicatesCheck)
	self:RegisterEvent("CLAIM_SKILL_CARD_RESULT")

	self:UpdateVisual()
end

function SkillCardMassRevealStatsMixin:ClearOnUpdate()
	dprint("SkillCardMassRevealStatsMixin:ClearOnUpdate")

	self:SetScript("OnUpdate", nil)
	self:UnregisterEvent("CLAIM_SKILL_CARD_RESULT")

	self:UpdateVisual()
end

function SkillCardMassRevealStatsMixin:GetTotalDuplicateRequestsToSend()
	return self.duplicateUUIDs and #self.duplicateUUIDs or 0
end

function SkillCardMassRevealStatsMixin:OnUpdateDuplicatesCheck(elapsed)
	self.duplicateRevealTimer = self.duplicateRevealTimer + elapsed

	if self.duplicateRevealTimer <= DUPLICATE_REVEAL_DELAY then
		return
	end

	if not(self.hasClaimResponse) then
		return
	end

	local UUIDs = self.duplicateUUIDs and self.duplicateUUIDs[#self.duplicateUUIDs]

	if not UUIDs then
		dprint("SkillCardMassRevealStatsMixin:OnUpdateDuplicatesCheck no uuids")
		self:ClearOnUpdate()
	end

	self.hasClaimResponse = false
	self.duplicateRevealTimer = 0

	SkillCardUtil.ClaimSkillCard(UUIDs)

	self.duplicateUUIDs[#self.duplicateUUIDs] = nil
end

-- 
-- Events
--
function SkillCardMassRevealStatsMixin:CLAIM_SKILL_CARD_RESULT(result)
	if result == "CLAIM_SKILL_CARD_OK" then
		self.hasClaimResponse = true
	else
		dprint("SkillCardMassRevealStatsMixin:CLAIM_SKILL_CARD_RESULT result ~= CLAIM_SKILL_CARD_OK")
		self:ClearOnUpdate()
	end
end

function SkillCardMassRevealStatsMixin:Layout()
	self:SetPoint("TOPLEFT")
	self:SetPoint("BOTTOMRIGHT")
	self:EnableMouse(true)
	
	self.BG = self:CreateTexture(nil, "BACKGROUND")
	self.BG:SetTexture(0, 0, 0, 0.5)
	self.BG:SetAllPoints(true)

	self.StatisticsFrame = CreateFrame("FRAME", "$parent.StatisticsFrame", self)
	self.StatisticsFrame:SetPoint("CENTER", 0, 0)
	self.StatisticsFrame:SetSize(384, 128)
	self.StatisticsFrame:Hide()

	self.StatisticsFrame.ArtTop = self.StatisticsFrame:CreateTexture(nil, "ARTWORK")
	self.StatisticsFrame.ArtTop:SetAtlas("draft-header-art-top", Const.TextureKit.UseAtlasSize)
	self.StatisticsFrame.ArtTop:SetPoint("BOTTOM", self.StatisticsFrame, "TOP", 0, -32)

	self.StatisticsFrame.Icon = self.StatisticsFrame:CreateTexture(nil, "BORDER")
	self.StatisticsFrame.Icon:SetSize(48, 48)
	SetPortraitToTexture(self.StatisticsFrame.Icon, "Interface\\Icons\\inv_inscription_darkmooncard_putrescence")
	self.StatisticsFrame.Icon:SetPoint("CENTER", self.StatisticsFrame.ArtTop, 0, 16)

	self.StatisticsFrame.ArtBottom = self.StatisticsFrame:CreateTexture(nil, "ARTWORK")
	self.StatisticsFrame.ArtBottom:SetAtlas("draft-header-extra-button-art-bottom", Const.TextureKit.UseAtlasSize)
	self.StatisticsFrame.ArtBottom:SetPoint("TOP", self.StatisticsFrame, "BOTTOM", 0, 16)

	self.StatisticsFrame.StatisticsText = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.StatisticsText:SetPoint("CENTER", self.StatisticsFrame.ArtTop, 0, -24)
	self.StatisticsFrame.StatisticsText:SetJustifyH("CENTER")
	self.StatisticsFrame.StatisticsText:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.StatisticsText:SetVertexColor(1, 1, 1, 1)
	self.StatisticsFrame.StatisticsText:SetText(STATISTICS)

	self.StatisticsFrame.LineUp = self.StatisticsFrame:CreateTexture(nil, "BORDER", nil, 2)
	self.StatisticsFrame.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.StatisticsFrame.LineUp:SetSize(524, 7)
	self.StatisticsFrame.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.StatisticsFrame.LineUp:SetVertexColor(1, 1, 1)
	self.StatisticsFrame.LineUp:SetPoint("TOP", 0, 6)

	self.StatisticsFrame.LineDown = self.StatisticsFrame:CreateTexture(nil, "BORDER", nil, 2)
	self.StatisticsFrame.LineDown:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.StatisticsFrame.LineDown:SetSize(524, 7)
	self.StatisticsFrame.LineDown:SetPoint("BOTTOM", 0, -1)
	self.StatisticsFrame.LineDown:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.StatisticsFrame.LineDown:SetVertexColor(1, 1, 1)

	self.StatisticsFrame.Shadow = self.StatisticsFrame:CreateTexture(nil, "BACKGROUND")
	self.StatisticsFrame.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.StatisticsFrame.Shadow:SetHeight(512)
	self.StatisticsFrame.Shadow:SetWidth(512)
	self.StatisticsFrame.Shadow:SetPoint("CENTER")
	self.StatisticsFrame.Shadow:SetAlpha(1)

	self.StatisticsFrame.BoostersText = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.BoostersText:SetPoint("TOPLEFT", 32, -32)
	self.StatisticsFrame.BoostersText:SetJustifyH("LEFT")
	self.StatisticsFrame.BoostersText:SetWidth(320)
	self.StatisticsFrame.BoostersText:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.BoostersText:SetVertexColor(1, 0.82, 0, 1)
	self.StatisticsFrame.BoostersText:SetText(SKILLCARD_STATISTICS_BOOSTERS_TOTAL)

	self.StatisticsFrame.BoostersTotal = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.BoostersTotal:SetPoint("RIGHT", self.StatisticsFrame.BoostersText, 0, 0)
	self.StatisticsFrame.BoostersTotal:SetJustifyH("RIGHT")
	self.StatisticsFrame.BoostersTotal:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.BoostersTotal:SetVertexColor(1, 1, 1, 1)

	self.StatisticsFrame.RevealedCardsText = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.RevealedCardsText:SetPoint("TOP", self.StatisticsFrame.BoostersText, "BOTTOM", 0, -4)
	self.StatisticsFrame.RevealedCardsText:SetWidth(320)
	self.StatisticsFrame.RevealedCardsText:SetJustifyH("LEFT")
	self.StatisticsFrame.RevealedCardsText:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.RevealedCardsText:SetVertexColor(1, 0.82, 0, 1)
	self.StatisticsFrame.RevealedCardsText:SetText(SKILLCARD_STATISTICS_REVEALED_TOTAL)

	self.StatisticsFrame.RevealedCardsTotal = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.RevealedCardsTotal:SetPoint("RIGHT", self.StatisticsFrame.RevealedCardsText, 0, 0)
	self.StatisticsFrame.RevealedCardsTotal:SetJustifyH("RIGHT")
	self.StatisticsFrame.RevealedCardsTotal:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.RevealedCardsTotal:SetVertexColor(1, 1, 1, 1)

	self.StatisticsFrame.DuplicateCardsText = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.DuplicateCardsText:SetPoint("TOP", self.StatisticsFrame.RevealedCardsText, "BOTTOM", 0, -4)
	self.StatisticsFrame.DuplicateCardsText:SetJustifyH("LEFT")
	self.StatisticsFrame.DuplicateCardsText:SetWidth(320)
	self.StatisticsFrame.DuplicateCardsText:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.DuplicateCardsText:SetVertexColor(1, 0.82, 0, 1)
	self.StatisticsFrame.DuplicateCardsText:SetText(SKILLCARD_STATISTICS_DUPLICATES_TOTAL)

	self.StatisticsFrame.DuplicateCardsTotal = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.DuplicateCardsTotal:SetPoint("RIGHT", self.StatisticsFrame.DuplicateCardsText, 0, 0)
	self.StatisticsFrame.DuplicateCardsTotal:SetJustifyH("RIGHT")
	self.StatisticsFrame.DuplicateCardsTotal:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.DuplicateCardsTotal:SetVertexColor(1, 1, 1, 1)

	self.StatisticsFrame.RewardsLabel = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.StatisticsFrame.RewardsLabel:SetPoint("TOP", self.StatisticsFrame.DuplicateCardsText, "BOTTOM", 0, -24)
	self.StatisticsFrame.RewardsLabel:SetJustifyH("CENTER")
	self.StatisticsFrame.RewardsLabel:SetWidth(320)
	self.StatisticsFrame.RewardsLabel:SetFontObject(GameFontDisableLarge)
	self.StatisticsFrame.RewardsLabel:SetVertexColor(1, 0.82, 0, 1)
	self.StatisticsFrame.RewardsLabel:SetText(LFD_REWARDS..":")
	self.StatisticsFrame.RewardsLabel:Hide()

	self.AnimatedFrame = CreateFrame("FRAME", "$parent.AnimatedFrame", self)
	self.AnimatedFrame:SetPoint("TOPLEFT")
	self.AnimatedFrame:SetPoint("BOTTOMRIGHT")
	MixinAndLoadScripts(self.AnimatedFrame, SkillCardMassRevealAnimationMixin)

	self.OkButton = CreateFrame("BUTTON", "$parent.OkButton", self, "RedButtonTemplate")
	self.OkButton:SetSize(128, 44)
	self.OkButton:SetText(OKAY)
	self.OkButton:SetParent(self.StatisticsFrame)
	self.OkButton:SetPoint("TOP", self.StatisticsFrame, "BOTTOM", 0, -16)
	self.OkButton:Hide()

	self.ProgressText = self.StatisticsFrame:CreateFontString(nil, "OVERLAY")
	self.ProgressText:SetPoint("CENTER", self.OkButton, 0, 0)
	self.ProgressText:SetJustifyH("CENTER")
	self.ProgressText:SetWidth(320)
	self.ProgressText:SetFontObject(GameFontDisableLarge)
	self.ProgressText:Hide()

	self.ProgressText.AG = self.ProgressText:CreateAnimationGroup()
	self.ProgressText.AG:SetLooping("REPEAT")

	self.ProgressText.AG.Pluse1 = self.ProgressText.AG:CreateAnimation("ALPHA")
	self.ProgressText.AG.Pluse1:SetChange(-1)
	self.ProgressText.AG.Pluse1:SetDuration(1)
	self.ProgressText.AG.Pluse1:SetOrder(1)

	self.ProgressText.AG.Pluse2 = self.ProgressText.AG:CreateAnimation("ALPHA")
	self.ProgressText.AG.Pluse2:SetChange(1)
	self.ProgressText.AG.Pluse2:SetDuration(1)
	self.ProgressText.AG.Pluse2:SetOrder(2)
end
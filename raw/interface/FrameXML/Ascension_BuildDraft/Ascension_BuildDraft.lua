BuildDraft = {
	Positions      = {
		{ "CENTER", 0, 0 }, -- 1 center
		{ "CENTER", 240, 0 }, -- 2 right
		{ "CENTER", -240, 0 }, -- 3 left
	},
	CyclePositions = {
		["left"]  = {
			{ startX = -240, endX = 0, startScale = 0.9, endScale = 1, level = 30 }, -- left to center
			{ startX = 0, endX = 240, startScale = 1, endScale = 0.9, level = 20 }, -- center to right
			{ startX = 240, endX = -240, startScale = 0.9, endScale = 0.9, level = 10 }, -- right to left
		},
		["right"] = {
			{ startX = 240, endX = 0, startScale = 0.9, endScale = 1, level = 30 }, -- right to center
			{ startX = -240, endX = 240, startScale = 0.9, endScale = 0.9, level = 10 }, -- left to right
			{ startX = 0, endX = -240, startScale = 1, endScale = 0.9, level = 20 }, -- center to left
		}
	},
	Cards          = {},
	LearnedPopupQueue = {},
}

local function ResetCard(framePool, frame)
	--frame.CloseButton:Hide()
	frame:SetFrameStrata("HIGH")
	frame:SetFrameLevel(1)
	frame:SetScale(1)
	frame.Main = nil
	frame.SelectButton:Disable()
	FramePool_HideAndClearAnchors(framePool, frame)
end

BuildDraft._pool = CreateFramePool("Frame", BuildDraftFrame, "BuildDraftCardTemplate", ResetCard)

local function RequestBuildData(id)
	C_BuildCreator.QueryBuild(id)
end

function BuildDraft:ShowCards()
	BuildDraftFrame:Show()
	self._pool:ReleaseAll()
	PlaySound(SOUNDKIT.UI_REFORGING_REFORGE, true)

	if not self.ArrowLeft then
		self.ArrowLeft = CreateFrame("Button", "BuildDraftLeft", BuildDraftFrame, "BuildDraftCycleArrowTemplate")
		self.ArrowLeft:ClearAndSetPoint("CENTER", -221, 16)
		self.ArrowLeft:SetDirection("left")

		self.ArrowRight = CreateFrame("Button", "BuildDraftRight", BuildDraftFrame, "BuildDraftCycleArrowTemplate")
		self.ArrowRight:ClearAndSetPoint("CENTER", 221, 16)
	end

	self.ArrowLeft:Show()
	self.ArrowRight:Show()

	local buildCount = C_BuildDraft.GetNumDraftableBuilds()
	BuildDraftFrame.HintFrame:Show()
	BuildDraftFrame.HintFrame:SetBuildCount(buildCount)

		for i = 1, 3 do
			local card = self._pool:Acquire()

			-- card 3 (left) should be last build
			if i == 3 then
				card:SetBuild(C_BuildDraft.GetDraftableBuild(buildCount), buildCount)
			else
				card:SetBuild(C_BuildDraft.GetDraftableBuild(i), i)
			end

			card:ClearAndSetPoint(unpack(self.Positions[i]))
			card:SetFrameLevel(11 - i)
			card:Show()
			card.Position = i

			self.Cards[i] = card

			if i ~= 1 then
				card:SetScale(0.9)
			else
				card:SetFrameStrata("DIALOG")
				--card.CloseButton:Show()
				card.SelectButton:Enable()
				card:SetFrameLevel(30)

				card.Main = true
			end
		end
	end

function BuildDraft:HideCards()
	self._pool:ReleaseAll()
	if self.ArrowLeft then
		self.ArrowLeft:Hide()
		self.ArrowRight:Hide()
	end
end

function BuildDraft:GetNextBuild(id)
	local nextCard
	if self.direction == "left" then
		nextCard = id - 1
	else
		nextCard = id + 1
	end

	nextCard = math.Wrap(nextCard, 1, C_BuildDraft.GetNumDraftableBuilds())

	return C_BuildDraft.GetDraftableBuild(nextCard), nextCard
end

function BuildDraft:Cycle(direction)
	StaticPopup_Hide("BUILD_DRAFT_BUILD_CONFIRM")
	self.direction = direction
	local dir = direction == "left" and 1 or -1

	self.ArrowLeft:Disable()
	self.ArrowRight:Disable()

	local cardsByPosition = {}
	for card in self._pool:EnumerateActive() do
		cardsByPosition[card.Position] = card
		local position = self.CyclePositions[direction][card.Position]
		card:PlayMove(position)
	end

	local midCard = cardsByPosition[1]
	local rightCard = cardsByPosition[2]
	local leftCard = cardsByPosition[3]
	if direction == "left" then
		rightCard:SetBuild(midCard.buildID, midCard:GetID())
		midCard:SetBuild(leftCard.buildID, leftCard:GetID())
		leftCard:SetBuild(self:GetNextBuild(leftCard:GetID()))
	else
		leftCard:SetBuild(midCard.buildID, midCard:GetID())
		midCard:SetBuild(rightCard.buildID, rightCard:GetID())
		rightCard:SetBuild(self:GetNextBuild(rightCard:GetID()))
	end
end

function BuildDraft:BUILD_DRAFT_ROLE_PROMPT()
	if BuildCreatorUtil.GetActiveBuildID() then return end
	if not C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then return end
	BuildDraftFrame:Show()
	BuildDraftSelectRoleFrame:Show()
end

function BuildDraft:BUILD_DRAFT_PICK_PROMPT()
	if BuildCreatorUtil.GetActiveBuildID() then return end
	if not C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then return end
	StaticPopup_Hide("BUILD_DRAFT_BUILD_CONFIRM")

	if not self.BatchedShowCards then
		self.BatchedShowCards = Timer.NewTimer(0.2, function()
			self.BatchedShowCards = nil
			self:ShowCards()
		end)
	end
end

function BuildDraft:PLAYER_ENTERING_WORLD()
	if BuildCreatorUtil.GetActiveBuildID() then return end
	if not C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then return end
	if C_BuildDraft.IsAwaitingRolePrompt() then
		self:BUILD_DRAFT_ROLE_PROMPT()
	elseif not BuildCreatorUtil.GetDraftedBuildID() then
		self:BUILD_DRAFT_PICK_PROMPT()
	end
end

function BuildDraft:ASCENSION_CUSTOM_GAME_MODE_CHANGED(modes)
	if not bit.contains(modes, Enum.GameMode.BuildDraft) then
		self:HideCards()
		BuildDraftFrame:Hide()
		BuildDraftSelectRoleFrame:Hide()
	else
		if C_BuildDraft.IsAwaitingRolePrompt() then
			self:BUILD_DRAFT_ROLE_PROMPT()
		end
	end
end

function BuildDraft:PLAYER_LEVEL_UP(level)
	if not BuildCreatorUtil.GetActiveBuildID() then return end
	if not C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then return end
	local draftedBuildID = BuildCreatorUtil.GetDraftedBuildID()
	if not draftedBuildID then return end
	if GetMaxLevel() == level then
		BuildCreatorUtil.ContinueOnLoad(draftedBuildID, function(build)
			local endGamePvE = not string.isNilOrEmpty(build.EndGameIDPVE) and build.EndGameIDPVE or nil
			local endGamePvP = not string.isNilOrEmpty(build.EndGameIDPVP) and build.EndGameIDPVP or nil
			if endGamePvE or endGamePvP then
				StaticPopup_Show("BUILD_DRAFT_MAX_LEVEL_UPGRADE", nil, nil, { pve = endGamePvE, pvp = endGamePvP })
			end
		end)
	end
end

C_Hook:Register(BuildDraft, "BUILD_DRAFT_ROLE_PROMPT")
C_Hook:Register(BuildDraft, "BUILD_DRAFT_SELECT_ROLE_RESULT")
C_Hook:Register(BuildDraft, "BUILD_DRAFT_PICK_PROMPT")
C_Hook:Register(BuildDraft, "PLAYER_ENTERING_WORLD")
C_Hook:Register(BuildDraft, "ASCENSION_CUSTOM_GAME_MODE_CHANGED")
C_Hook:Register(BuildDraft, "PLAYER_LEVEL_UP")

BuildDraftHintMixin = {}

function BuildDraftHintMixin:OnLoad()
	self.Item:SetItem(ItemData.BUILD_MASTERS_DECK)
	self.Item:SetBorderAtlas(ITEM_QUALITY_BORDER_ATLAS[Enum.ItemQuality.Legendary])
	self.Item:SetBorderSize(72, 72)
	
	function self.Item:OnClickHandler()
		local name = GetItemName(ItemData.BUILD_MASTERS_DECK)
		if name then
			UseItemByName(name)
		end
	end
end

function BuildDraftHintMixin:SetBuildCount(buildCount)
	self.buildCount = buildCount
	self:SetupItem(buildCount)
	self.Title:SetFormattedText(BUILD_DRAFT_TOTAL_BUILD_COUNT, buildCount, 16)
end 

function BuildDraftHintMixin:OnShow()
	self:RegisterEvent("BAG_UPDATE")
end

function BuildDraftHintMixin:OnHide()
	self:UnregisterEvent("BAG_UPDATE")
end

function BuildDraftHintMixin:OnEvent()
	if self.buildCount then
		self:SetBuildCount(self.buildCount)
	end
end

function BuildDraftHintMixin:SetupItem(buildCount)
	self.Item.tooltipTitle = nil
	self.Item.tooltipText = nil
	if buildCount >= 16 then
		self.Item:Disable()
		self.Item:SetDesaturated(true)
		self.Item:SetCount(0)
		self.Item.About:SetText(BUILD_DRAFT_UNLOCKED_ALL_CARDS)
		self.Item.About:SetVertexColor(GREEN_FONT_COLOR:GetRGB())
	else
		if GetItemCount(ItemData.BUILD_MASTERS_DECK) > 0 then
			self.Item:Enable()
			self.Item:SetDesaturated(false)
			self.Item:SetCount(GetItemCount(ItemData.BUILD_MASTERS_DECK))
			self.Item.About:SetText(BUILD_DRAFT_USE_MASTERS_CARD)
			self.Item.About:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		else
			self.Item:Disable()
			self.Item:SetDesaturated(true)
			self.Item:SetCount(0)
			self.Item.About:SetFormattedText(BUILD_DRAFT_ACQUIRE_MASTERS_CARD, 16 - buildCount)
			self.Item.About:SetVertexColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		end
	end
end 
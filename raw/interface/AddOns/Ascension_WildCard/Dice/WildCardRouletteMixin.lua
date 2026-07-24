-------------------------------------------------------------------------------
--                            Roulette Icon Mixin                            --
-------------------------------------------------------------------------------
WildCardRouletteIconMixin = {}

function WildCardRouletteIconMixin:OnLoad()
	self:Layout()
end

function WildCardRouletteIconMixin:SetInternalID(internalID, rank)
	-- safe check
	if not(rank) or (rank == 0) then
		dprint("WildCardRouletteIconMixin: Recieved nil or 0 rank")
		rank = 1
	end

	if not(internalID) or (internalID == 0) then
		dprint("WildCardRouletteIconMixin: Recieved nil or 0 internalID")
		internalID = 1
	end

	local spellID = CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, rank) or 1
	spellID = (spellID ~= 0) and spellID or 1

	local icon = select(3, GetSpellInfo(spellID))
	local quality = C_CharacterAdvancement.GetQualityInfo(spellID) or 1

	-- todo: check with kale if talent qualities are implemented into GetQualityInfo and remove this
	if rank and (rank > 1) then
		quality = rank
	end

	self:SetTexture(icon)

	if quality and (quality >= 2) then
		self.border:SetVertexColor(ITEM_QUALITY_COLORS[quality]:GetRGB())
		self.borderAdd:SetVertexColor(ITEM_QUALITY_COLORS[quality]:GetRGB())
		self.borderAdd:Show()
	else
		self.border:SetVertexColor(1, 1, 1)
		self.borderAdd:Hide()
	end
end

function WildCardRouletteIconMixin:Layout()
	self:SetSize(46,46)

	self.border = self:GetParent():CreateTexture(nil, "ARTWORK")
	self.border:SetSize(46,46)
	self.border:SetPoint("CENTER", self, 0, 0)
	self.border:SetTexture("Interface\\Addons\\AwAddons\\Textures\\SpellKit\\ArtifactPower-QuestBorder")

	self.borderAdd = self:GetParent():CreateTexture(nil, "OVERLAY")
	self.borderAdd:SetSize(46,46)
	self.borderAdd:SetPoint("CENTER", self, 0, 0)
	self.borderAdd:SetTexture("Interface\\Addons\\AwAddons\\Textures\\SpellKit\\ArtifactPower-QuestBorder")
	self.borderAdd:SetBlendMode("ADD")
	self.borderAdd:Hide()
end

-------------------------------------------------------------------------------
--                               Roulette Mixin                              --
-------------------------------------------------------------------------------
WildCardScrollFrameRouletteMixin = CreateFromMixins(CallbackRegistryMixin)
WildCardScrollFrameRouletteMixin.iconsTotal = 70

function WildCardScrollFrameRouletteMixin:OnLoad()
	MixinAndLoad(self, CallbackRegistryMixin)

	self.icons = {}
	self:Layout()

	self:GenerateCallbackEvents({
		"OnRouletteFinished",
	})

	self.Content.AnimationGroup:SetScript("OnFinished", function() self:TriggerEvent("OnRouletteFinished") end)
end

function WildCardScrollFrameRouletteMixin:RandomizeIcons()
	local fakeInternalIDs = C_Wildcard.GetRollIcons(self.iconsTotal)

	for i = 1, #fakeInternalIDs do
		self.icons[i]:SetInternalID(fakeInternalIDs[i], 1)
	end

	--[[local fakeInternalIDs = {1}
	--local fakeInternalIDs = WildCardUtil.GetFakeIDTable(UnitLevel("player"))

	for i = 1, self.iconsTotal do
		local internalID = fakeInternalIDs[math.random(1, #fakeInternalIDs)]
		self.icons[i]:SetInternalID(internalID, 1)
	end]]--
end

function WildCardScrollFrameRouletteMixin:UpdateInternalIDs()
	local data = WildCardDice.pendingReveal

	if not(data) then
		dprint("WildCardScrollFrameRouletteMixin:UpdateInternalIDs failed because of no internalID")
		return
	end

	local index = (self.iconsTotal/2)
	self.icons[index]:SetInternalID(unpack(data))
end

function WildCardScrollFrameRouletteMixin:Play(isSoFRoll)
	local _, _, _, translationX = self.icons[14]:GetPoint()
	translationX = translationX + math.random(-75, 75)
	local translationDestination = translationX

	--self.time = 1
	BaseFrameFadeIn(self)

	self.Content.AnimationGroup.Rotation0:SetOffset(translationX, 0)
	self.Content.AnimationGroup.Rotation1:SetOffset(-translationDestination, 0)
	if WildCardUtil.IsRapidRolling() then
		self.Content.AnimationGroup.Rotation1:SetDuration(0.5)
	else
		self.Content.AnimationGroup.Rotation1:SetDuration(DEBUG_WC_ROULETTE_DURATION or 2)
	end
	--self.Content.AnimationGroup.Rotation1:SetDuration(isSoFRoll and 1.75 or 3.5)

	self.Content.AnimationGroup:Play()

	self.soundProgress = 0
end

-- TODO: Dirty, fix later
function WildCardScrollFrameRouletteMixin:OnUpdate(elapsed)
	local progress = self.Content.AnimationGroup:GetProgress()/2

	if (progress == 0) then
		return
	end

	if not(self.soundProgress >= progress) then
		self.soundProgress = self.soundProgress + elapsed
		return
	end

	self.soundProgress = 0
	PlaySound(SOUNDKITEXTRA.WILDCARD_CLICK)
end

function WildCardScrollFrameRouletteMixin:Layout()
	self.Content = CreateFrame("FRAME", "$parent.Content", self)
	self.Content:SetSize(self:GetSize())
	self.Content:SetPoint("CENTER", 0, 0)

	for i = 1, self.iconsTotal do -- TODO: To collection, mixin
		local icon = self.Content:CreateTexture(nil, "BORDER")
		icon:SetPoint("CENTER", -46*(i-self.iconsTotal/2), 0)
		MixinAndLoadScripts(icon, WildCardRouletteIconMixin)
		table.insert(self.icons, icon)
	end

	self.Content.AnimationGroup = self.Content:CreateAnimationGroup()

	self.Content.AnimationGroup.Rotation0 = self.Content.AnimationGroup:CreateAnimation("Translation")
	self.Content.AnimationGroup.Rotation0:SetDuration(0)
	self.Content.AnimationGroup.Rotation0:SetOrder(1)
	self.Content.AnimationGroup.Rotation0:SetEndDelay(0)
	self.Content.AnimationGroup.Rotation0:SetSmoothing("OUT")
	self.Content.AnimationGroup.Rotation0:SetOffset(596, 0)

	self.Content.AnimationGroup.Rotation1 = self.Content.AnimationGroup:CreateAnimation("Translation")
	self.Content.AnimationGroup.Rotation1:SetDuration(5)
	self.Content.AnimationGroup.Rotation1:SetOrder(2)
	self.Content.AnimationGroup.Rotation1:SetEndDelay(0.15)
	self.Content.AnimationGroup.Rotation1:SetSmoothing("OUT")
	self.Content.AnimationGroup.Rotation1:SetOffset(-596, 0)

	self.NavigatorFrame = CreateFrame("FRAME", "$parent.NavigatorFrame", self)

	self.Navigator = self.NavigatorFrame:CreateTexture(nil, "OVERLAY") -- for to overlay self.Content (scrollFrames are strange)
	self.Navigator:SetAtlas("WildCardRouletteGlowx1", Const.TextureKit.UseAtlasSize)
	self.Navigator:SetPoint("CENTER", self, 0, 0)

	self:SetScrollChild(self.Content)
end

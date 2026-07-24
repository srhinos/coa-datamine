MythicPlusBannerPartyMemberMixin = {}

function MythicPlusBannerPartyMemberMixin:OnLoad()
	self.Border:SetAtlas("BossBanner-PortraitBorder", Const.TextureKit.IgnoreAtlasSize)
end

function MythicPlusBannerPartyMemberMixin:SetUp(unitToken)
	SetPortraitTexture(self.Portrait, unitToken)

	local name = UnitName(unitToken)
	local _, class = UnitClass(unitToken)

	local classColorName = RAID_CLASS_COLORS[class]:WrapText(name)
	self.Name:SetText(classColorName)

	local role = UnitGroupRolesAssignedKey(unitToken)
	if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
		self.RoleIcon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		self.RoleIcon:Show()
	else
		self.RoleIcon:Hide()
	end

	self:Show()
	self.AnimIn:Play()
end

MythicPlusCompleteBannerMixin = {}

function MythicPlusCompleteBannerMixin:OnLoad()
	self.timeToHold = 8
	self.BannerTop:SetAtlas("BossBanner-BgBanner-Top", Const.TextureKit.UseAtlasSize)
	self.BannerTopGlow:SetAtlas("BossBanner-BgBanner-Top", Const.TextureKit.UseAtlasSize)
	
	self.BannerBottom:SetAtlas("BossBanner-BgBanner-Bottom", Const.TextureKit.UseAtlasSize)
	self.BannerBottomGlow:SetAtlas("BossBanner-BgBanner-Bottom", Const.TextureKit.UseAtlasSize)
	
	self.BannerMiddle:SetAtlas("BossBanner-BgBanner-Mid", Const.TextureKit.UseAtlasSize)
	self.BannerMiddleGlow:SetAtlas("BossBanner-BgBanner-Mid", Const.TextureKit.UseAtlasSize)
	
	self.SkullCircle:SetAtlas("ChallengeMode-SpikeyStar", Const.TextureKit.IgnoreAtlasSize)
	
	self.BottomFillagree:SetAtlas("BossBanner-BottomFillagree", Const.TextureKit.UseAtlasSize)
	self.RightFillagree:SetAtlas("BossBanner-RightFillagree", Const.TextureKit.UseAtlasSize)
	self.LeftFillagree:SetAtlas("BossBanner-LeftFillagree", Const.TextureKit.UseAtlasSize)
	
	self.Glow:SetAtlas("ChallengeMode-SoftYellowGlow", Const.TextureKit.IgnoreAtlasSize)
	
	C_Hook:Register(self, "MYTHIC_PLUS_COMPLETE")
end

function MythicPlusCompleteBannerMixin:PlayBanner(onTime)
	local activeKeystone = C_MythicPlus.GetActiveKeystoneInfo()
	if not activeKeystone then
		return
	end

	self.Title:SetText(GetLFGDungeonInfo(activeKeystone.dungeonID))

	self.Level:SetText(activeKeystone.keystoneLevel)
	local lvlStr = tostring(activeKeystone.keystoneLevel)
	if tonumber(lvlStr:sub(1,1)) == 1 then
		self.Level:SetPoint("CENTER", self.SkullCircle, -4, 0)
	else
		self.Level:SetPoint("CENTER", self.SkullCircle, 0, 0)
	end

	self.Level:Show()

	local timeLeft, timeLimit = C_MythicPlus.GetActiveKeystoneTime()
	local timeRemaining = timeLimit - timeLeft
	local timeText = SecondsToClock(timeRemaining, true)

	if onTime then
		self.DescriptionLineOne:SetText(MYTHIC_PLUS_COMPLETE_BEAT_TIMER)
		local upgradeLevel = 1
		local ThreeChestTime = timeLeft > (timeLimit * MYTHIC_PLUS_BONUS_LEVEL_PERCENT[1])
		if ThreeChestTime then
			upgradeLevel = 3
		else
			local TwoChestTime = timeLeft > (timeLimit * MYTHIC_PLUS_BONUS_LEVEL_PERCENT[2])
			if TwoChestTime then
				upgradeLevel = 2
			end
		end
		self.DescriptionLineTwo:SetFormattedText(MYTHIC_PLUS_COMPLETE_KEYSTONE_UPGRADED, upgradeLevel)
		self.DescriptionLineThree:SetText(GREEN_FONT_COLOR:WrapText(timeText))
		PlaySound(SOUNDKIT.UI_GARRISON_TOAST_INVASIONALERT)
	else
		self.DescriptionLineOne:SetText(MYTHIC_PLUS_COMPLETE_TIME_EXPIRED)
		self.DescriptionLineTwo:SetText(MYTHIC_PLUS_COMPLETE_TRY_AGAIN)
		self.DescriptionLineThree:SetText(RED_FONT_COLOR:WrapText(timeText))
		PlaySound(SOUNDKIT.UI_CHALLENGEMODE_WARNING)
	end

	local units = self:GetPartyMembers()

	self:Show()
	self:PlayAnimIn()

	self:CreateAndPositionPartyMembers(#units)
	for i, unit in ipairs(units) do
		self.PartyMembers[i]:SetUp(unit)
	end

	self.AnimOutTimer = Timer.NewTimer(self.timeToHold, GenerateClosure(self.PlayAnimOut, self))
end

function MythicPlusCompleteBannerMixin:GetPartyMembers()
	local members = { "player" }
	for i = 1, 4 do
		local unit = "party"..i
		if UnitExists(unit) then
			tinsert(members, unit)
		end
	end
	
	return members
end

function MythicPlusCompleteBannerMixin:CreateAndPositionPartyMembers(num)
	local frameWidth, spacing, distance = 61, 22, -131

	CreateFrames(self, "PartyMembers", num, "MythicPlusBannerPartyMemberTemplate")
	LineUpFrames(self.PartyMembers, 5, "TOPLEFT", self.Title, "TOP", frameWidth, spacing, distance)
end

function MythicPlusCompleteBannerMixin:MYTHIC_PLUS_COMPLETE(onTime)
	self:PlayBanner(onTime)
end

function MythicPlusCompleteBannerMixin:StopAnim()
	self.AnimOut:Stop()
	self.SkullCircle.AnimIn:Stop()
	self.BannerTop.AnimIn:Stop()
	self.BannerMiddle.AnimIn:Stop()
	self.BannerBottom.AnimIn:Stop()
	self.BottomFillagree.AnimIn:Stop()
	self.RightFillagree.AnimIn:Stop()
	self.LeftFillagree.AnimIn:Stop()
	self.BannerTopGlow.AnimIn:Stop()
	self.BannerBottomGlow.AnimIn:Stop()
	self.BannerMiddleGlow.AnimIn:Stop()
	self.Title.AnimIn:Stop()
	self.DescriptionLineOne.AnimIn:Stop()
	self.DescriptionLineTwo.AnimIn:Stop()
	self.DescriptionLineThree.AnimIn:Stop()
end

function MythicPlusCompleteBannerMixin:PlayAnimIn()
	self:StopAnim()
	self.SkullCircle.AnimIn:Play()
	self.BannerTop.AnimIn:Play()
	self.BannerMiddle.AnimIn:Play()
	self.BannerBottom.AnimIn:Play()
	self.BottomFillagree.AnimIn:Play()
	self.RightFillagree.AnimIn:Play()
	self.LeftFillagree.AnimIn:Play()
	self.BannerTopGlow.AnimIn:Play()
	self.BannerBottomGlow.AnimIn:Play()
	self.BannerMiddleGlow.AnimIn:Play()
	self.Title.AnimIn:Play()
	self.DescriptionLineOne.AnimIn:Play()
	self.DescriptionLineTwo.AnimIn:Play()
	self.DescriptionLineThree.AnimIn:Play()
end 

function MythicPlusCompleteBannerMixin:PlayAnimOut()
	self:StopAnim()
	self.AnimOut:Play()
end 
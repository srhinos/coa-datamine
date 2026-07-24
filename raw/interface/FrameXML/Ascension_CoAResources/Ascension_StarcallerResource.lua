if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "STARCALLER" then return end

CoAResourceOrbMixinStarcaller = {}

CoAResourceOrbMixinStarcaller.ProgressTypes = {
	[4] = {
		"StarcallerMoonProgress0",
		"StarcallerMoonProgress41",
		"StarcallerMoonProgress42",
		"StarcallerMoonProgress43",
		"StarcallerMoonProgressFull",
	},

	[6] = {
		"StarcallerMoonProgress0",
		"StarcallerMoonProgress61",
		"StarcallerMoonProgress62",
		"StarcallerMoonProgress63",
		"StarcallerMoonProgress64",
		"StarcallerMoonProgress65",
		"StarcallerMoonProgressFull",
	},

	[8] = {
		"StarcallerMoonProgress0",
		"StarcallerMoonProgress81",
		"StarcallerMoonProgress82",
		"StarcallerMoonProgress83",
		"StarcallerMoonProgress84",
		"StarcallerMoonProgress85",
		"StarcallerMoonProgress86",
		"StarcallerMoonProgress87",
		"StarcallerMoonProgressFull",
	},
}

function CoAResourceOrbMixinStarcaller:OnLoad()
	self.maxOverlayFrames = 60
	self.moonPhaseFrames = 30

	self:Layout()
	self.ResourceOverlayFlipBook:Init()

	self:SetSpellID(802985) -- TODO: to constants
	self:RegisterForClicks("AnyUp")

	self.cvarLocked = "coaResourceBarLocked"
	self.cvarSize = "coaResourceBarSize"
	self.cvarShowText = "coaResourceBarShowText"
	Mixin(self, CoAResourceMixin)

	self:LoadCVars()
	self:SetShowText(C_CVar.GetBool(self.cvarShowText))

	self.DropDown.initialize = CoAResourceMixin.InitializeDropDown
	self.DropDown.displayMode = "MENU"

	self.init = true
end

-- overwritten
function CoAResourceOrbMixinStarcaller:OnUpdate(elapsed)

	local hasMoonCycle = IsSpellIDKnown(500206)
	local hasFullMoon = AuraUtil.GetDebuff("player", 800393, true, AuraUtil.Predicate.MatchesSpellID)
	local hasNewMoon = AuraUtil.GetDebuff("player", 800394, true, AuraUtil.Predicate.MatchesSpellID)

	if hasMoonCycle and (hasFullMoon or hasNewMoon) then
		self.ResourceFlipBook:Show()
		local moonPhaseProgress = hasFullMoon and 100 or 0
		local overlayProgress = math.ceil(self.ResourceFlipBook.frame*100/self.moonPhaseFrames)

		if math.abs(overlayProgress - moonPhaseProgress) >= self.eps then
			local progressStep = 1
			self.ResourceFlipBook.frame = math.ceil(self.ResourceFlipBook.frame + ((overlayProgress > moonPhaseProgress) and -progressStep or progressStep))
		end

		if self.ResourceFlipBook.frame == 0 then
			self.ResourceFlipBook.frame = 1
		end

		AtlasVerticalFlipbookMixin.SetFrame(self.ResourceFlipBook, self.ResourceFlipBook.frame)
	else
		self.ResourceFlipBook.frame = 1
		AtlasVerticalFlipbookMixin.SetFrame(self.ResourceFlipBook, self.ResourceFlipBook.frame)
		self.ResourceFlipBook:Hide()
	end

	local result = AuraUtil.GetBuff("player", 800386, true, AuraUtil.Predicate.MatchesSpellID)

	if not result then
		self.ResourceOverlayFlipBook:Hide()
		return
	else
		self.ResourceOverlayFlipBook:Show()
	end

	AtlasVerticalFlipbookMixin.Update(self.ResourceOverlayFlipBook, elapsed)

	if self.ResourceOverlayFlipBook.frame > self.ResourceOverlayFlipBook.frames then
		self.ResourceOverlayFlipBook.frame = 1
	end
end

function CoAResourceOrbMixinStarcaller:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

function CoAResourceOrbMixinStarcaller:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinStarcaller:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinStarcaller:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbMixinStarcaller:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinStarcaller:SetProgress(progress, value, maxValue)
	progress = (progress*100/maxValue)

	self.progress = progress

	self:SetValue(value, maxValue)

	self.Text:SetText(self.value)

	self.ArtWork:SetAtlas(self.ProgressTypes[maxValue][value+1])

	if value >= 4 then
		self.ReadyGlow:Show()
	else
		self.ReadyGlow:Hide()
	end
end

function CoAResourceOrbMixinStarcaller:Layout()
	self.ResourceFlipBook:Hide()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(36, 36)
	self.ResourceFlipBook:SetPoint("CENTER", 6.5, 22.5)
	self.ResourceFlipBook:SetAtlas("StarcallerMoonPhaseFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "StarcallerMoonPhaseFlipBook", 128, 128, self.moonPhaseFrames, 16, false)
	self.ResourceFlipBook:SetDrawLayer("BACKGROUND")

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(72, 72)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, 24)
	self.ResourceOverlayFlipBook:SetAtlas("StarcallerActiveOverlayFlipbook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "StarcallerActiveOverlayFlipbook", 128, 128, self.maxOverlayFrames, 16, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BORDER")
	self.ResourceOverlayFlipBook:SetBlendMode("ADD")
	self.ResourceOverlayFlipBook:Hide()

	self.ArtWork:ClearAllPoints()
	self.ArtWork:SetSize(100, 100)
	self.ArtWork:SetPoint("CENTER", 0, 0)
	self.ArtWork:SetDrawLayer("BORDER")

	self.ReadyGlow = self:CreateTexture(nil, "OVERLAY")
	self.ReadyGlow:SetAtlas("StarcallerMoonProgressReady", Const.TextureKit.IgnoreAtlasSize)
	self.ReadyGlow:SetSize(100, 100)
	self.ReadyGlow:SetPoint("CENTER", 0, 0)
	self.ReadyGlow:SetBlendMode("ADD")
	self.ReadyGlow:Hide()

	self.ReadyGlow.Pulse = self.ReadyGlow:CreateAnimationGroup()

	self.ReadyGlow.Pulse.AlphaDown = self.ReadyGlow.Pulse:CreateAnimation("ALPHA")
	self.ReadyGlow.Pulse.AlphaDown:SetChange(-1)
	self.ReadyGlow.Pulse.AlphaDown:SetDuration(0.5)
	self.ReadyGlow.Pulse.AlphaDown:SetSmoothing("IN")
	self.ReadyGlow.Pulse.AlphaDown:SetOrder(1)

	self.ReadyGlow.Pulse.AlphaUp = self.ReadyGlow.Pulse:CreateAnimation("ALPHA")
	self.ReadyGlow.Pulse.AlphaUp:SetChange(1)
	self.ReadyGlow.Pulse.AlphaUp:SetDuration(0.5)
	self.ReadyGlow.Pulse.AlphaUp:SetSmoothing("OUT")
	self.ReadyGlow.Pulse.AlphaUp:SetOrder(2)

	self.ReadyGlow.Pulse:SetLooping("REPEAT")
	self.ReadyGlow.Pulse:Play()

	self.Text:SetPoint("CENTER", 0, -28)
end
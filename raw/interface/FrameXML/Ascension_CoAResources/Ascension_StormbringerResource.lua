if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "STORMBRINGER" then return end

local STATIC_AURA = 803102

--
-- Controller
--
ClassMixinStormbringer = {}

function ClassMixinStormbringer:OnLoad()
	MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinStatic)
	CoAResourceOrb:RestorePosition()
	CoAResourceOrb:Show()
end

function ClassMixinStormbringer:OnPlayerAura()
	local stacks = select(4, AuraUtil.GetDebuff("player", STATIC_AURA, true, AuraUtil.Predicate.MatchesSpellID)) or 0
	CoAResourceOrb:SetProgress(stacks, stacks, 100)
end

--
-- Controller
--
CoAResourceOrbMixinStatic = {}

function CoAResourceOrbMixinStatic:OnLoad()
	self.maxOverlayFrames = 64

	self:Layout()
	self.ResourceFlipBook:Init()
	self.ResourceOverlayFlipBook:Init()

	self:SetSpellID(STATIC_AURA) -- TODO: to constants
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

function CoAResourceOrbMixinStatic:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

-- TODO: ResourceFlipBook is not used
function CoAResourceOrbMixinStatic:OnUpdate(elapsed)
	if self.progress == 100 then
		self.ResourceOverlayFlipBook:Show()

		AtlasVerticalFlipbookMixin.Update(self.ResourceOverlayFlipBook, elapsed)
		if self.ResourceOverlayFlipBook.frame > self.ResourceOverlayFlipBook.frames then
			self.ResourceOverlayFlipBook.frame = 1
		end
	elseif self.ResourceOverlayFlipBook:IsVisible() then
		self.ResourceOverlayFlipBook:Hide()
	end
	
	local overlayProgress = math.ceil(self.ResourceFlipBook.frame*100/self.maxOverlayFrames)

	if math.abs(overlayProgress - self.progress) < self.eps then
		return
	else
		local progressStep = 1
		self.ResourceFlipBook.frame = math.ceil(self.ResourceFlipBook.frame + ((overlayProgress > self.progress) and -progressStep or progressStep))
	end

	if self.ResourceFlipBook.frame == 0 then 
		self.ResourceFlipBook.frame = 1
	end

	AtlasVerticalFlipbookMixin.SetFrame(self.ResourceFlipBook, self.ResourceFlipBook.frame)
end


function CoAResourceOrbMixinStatic:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinStatic:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinStatic:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbMixinStatic:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinStatic:SetProgress(progress, value, maxValue)
	CoAResourceOrbMixin.SetProgress(self, progress, value, maxValue)
end

function CoAResourceOrbMixinStatic:Layout()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(160, 80)
	self.ResourceFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceFlipBook:SetAtlas("StaticFlipBookFill", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "StaticFlipBookFill", 256, 128, self.maxOverlayFrames, 60, false)
	self.ResourceFlipBook:SetDrawLayer("BACKGROUND")

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(176, 90)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", -3, 5)
	self.ResourceOverlayFlipBook:SetAtlas("StaticFlipBookOverpower", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "StaticFlipBookOverpower", 256, 128, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BORDER")
	self.ResourceOverlayFlipBook:Hide()

	self.ArtWork:Hide()

	self.Text:SetPoint("CENTER", 0, 3)

	self:SetWidth(128)
end
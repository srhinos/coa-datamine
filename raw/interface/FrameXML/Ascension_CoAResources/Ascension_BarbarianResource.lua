if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "BARBARIAN" then return end

CoAResourceOrbMixinBarbarian = {}

function CoAResourceOrbMixinBarbarian:OnLoad()
	self.maxOverlayFrames = 64

	self:Layout()
	self.ResourceOverlayFlipBook:Init()

	self:SetSpellID(805813) -- TODO: to constants
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

function CoAResourceOrbMixinBarbarian:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

-- TODO: ResourceFlipBook is not used
function CoAResourceOrbMixinBarbarian:OnUpdate(elapsed)
	local overlayProgress = math.ceil(self.ResourceOverlayFlipBook.frame*100/self.maxOverlayFrames)

	if math.abs(overlayProgress - self.progress) < self.eps then
		return
	else
		local progressStep = 1
		self.ResourceOverlayFlipBook.frame = math.ceil(self.ResourceOverlayFlipBook.frame + ((overlayProgress > self.progress) and -progressStep or progressStep))
	end

	if self.ResourceOverlayFlipBook.frame == 0 then 
		self.ResourceOverlayFlipBook.frame = 1
	end

	AtlasVerticalFlipbookMixin.SetFrame(self.ResourceOverlayFlipBook, self.ResourceOverlayFlipBook.frame)
end


function CoAResourceOrbMixinBarbarian:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinBarbarian:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinBarbarian:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbMixinBarbarian:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinBarbarian:SetProgress(progress, value, maxValue)
	CoAResourceOrbMixin.SetProgress(self, progress, value, maxValue)
end

function CoAResourceOrbMixinBarbarian:Layout()
	self.ResourceFlipBook:Hide()

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(112, 112)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 10, 10)
	self.ResourceOverlayFlipBook:SetAtlas("BarbarianMugFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "BarbarianMugFlipBook", 128, 128, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BACKGROUND")

	self.ArtWork:Hide()

	self.Text:SetPoint("CENTER", -4, -28)


end
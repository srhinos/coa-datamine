if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "CULTIST" then return end

CoAResourceOrbMixinCultist = {}

function CoAResourceOrbMixinCultist:OnLoad()
	self.maxOverlayFrames = 64

	self:Layout()
	self.ResourceFlipBook:Init()
	self.ResourceFlipBook.fps = 0.05
	self.ResourceOverlayFlipBook:Init()

	self:SetSpellID(500706) -- TODO: to constants
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

function CoAResourceOrbMixinCultist:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

function CoAResourceOrbMixinCultist:OnUpdate(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.ResourceFlipBook, elapsed)

	if self.ResourceFlipBook.frame > self.ResourceFlipBook.frames then
		self.ResourceFlipBook.frame = 1
	end

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


function CoAResourceOrbMixinCultist:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinCultist:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinCultist:SetShowText(show)
	-- Cultist uses a button-based orb, so leaving the text on the HIGHLIGHT layer
	-- makes the value disappear until hover. Keep it on a normal layer instead.
	self.AlwaysShowText = true
	self.Text:SetDrawLayer("OVERLAY")
end

function CoAResourceOrbMixinCultist:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinCultist:SetProgress(progress, value, maxValue)
	CoAResourceOrbMixin.SetProgress(self, progress, value, maxValue)

	if progress >= 80 then
		self.ResourceFlipBook:SetVertexColor(1, 0.4, 0.8)
	else
		self.ResourceFlipBook:SetVertexColor(1, 1, 1)
	end
end

function CoAResourceOrbMixinCultist:Layout()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(173, 43)
	self.ResourceFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceFlipBook:SetAtlas("InsanityNewEffectFlipbook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "InsanityNewEffectFlipbook", 512, 128, 64, 60, false)
	self.ResourceFlipBook:SetDrawLayer("BORDER")

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(173, 43)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceOverlayFlipBook:SetAtlas("InsanityNewFillFlipbook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "InsanityNewFillFlipbook", 512, 128, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("ARTWORK")

	self.ArtWork:ClearAllPoints()
	self.ArtWork:SetPoint("CENTER", 0, 0)
	self.ArtWork:SetTexture("INTERFACE\\CoAResource\\cultistInsanityBorder")
	self.ArtWork:SetSize(256, 64)
	self.ArtWork:SetDrawLayer("BACKGROUND")

	self.Text:SetPoint("CENTER", 0, 0)

	self:SetWidth(128)
end

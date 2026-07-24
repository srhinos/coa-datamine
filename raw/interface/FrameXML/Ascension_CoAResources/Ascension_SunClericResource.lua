if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "SUNCLERIC" then return end

CoAResourceOrbSunCleric = {}

function CoAResourceOrbSunCleric:OnLoad()
	self.maxOverlayFrames = 64

	self:Layout()
	self.ResourceFlipBook:Init()
	self.ResourceFlipBook.fps = 0.05
	self.ResourceOverlayFlipBook:Init()

	self.EmpoweredFlipBook.fps = 0.05
	self.EmpoweredFlipBook:Init()

	self:SetSpellID(500149) -- TODO: to constants
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

function CoAResourceOrbSunCleric:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

function CoAResourceOrbMixin:OnUpdate(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.ResourceFlipBook, elapsed)
	AtlasVerticalFlipbookMixin.Update(self.EmpoweredFlipBook, elapsed)

	if self.ResourceFlipBook.frame > self.ResourceFlipBook.frames then
		self.ResourceFlipBook.frame = 1
	end

	if self.EmpoweredFlipBook.frame > self.EmpoweredFlipBook.frames then
		self.EmpoweredFlipBook.frame = 1
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

function CoAResourceOrbSunCleric:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbSunCleric:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbSunCleric:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbSunCleric:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbSunCleric:SetProgress(progress, value, maxValue)
	progress = (progress*100/maxValue)

	CoAResourceOrbMixin.SetProgress(self, progress, value, maxValue)

	if progress == 100 or self.isSunset then
		self.EmpoweredFlipBook:Show()
	else
		self.EmpoweredFlipBook:Hide()
	end
end

function CoAResourceOrbSunCleric:SetSunset(isSunset)
	self.isSunset = isSunset

	if isSunset then
		self.ResourceOverlayFlipBook:SetVertexColor(1, 0.5, 0)
		self.ResourceFlipBook:SetVertexColor(1, 0.5, 0)
		self.EmpoweredFlipBook:SetVertexColor(1, 0.5, 0)
	else
		self.ResourceOverlayFlipBook:SetVertexColor(1, 1, 1)
		self.ResourceFlipBook:SetVertexColor(1, 1, 1)
		self.EmpoweredFlipBook:SetVertexColor(1, 1, 1)
	end
end


function CoAResourceOrbSunCleric:Layout()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(44, 44)
	self.ResourceFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceFlipBook:SetAtlas("SunPowerOrbFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "SunPowerOrbFlipBook", 128, 128, 64, 60, false)
	self.ResourceFlipBook:SetDrawLayer("BORDER")

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(64, 64)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, -2)
	self.ResourceOverlayFlipBook:SetAtlas("SunPowerFillFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "SunPowerFillFlipBook", 128, 128, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("ARTWORK")

	self.EmpoweredFlipBook = self:CreateTexture(nil, "OVERLAY")
	MixinAndLoad(self.EmpoweredFlipBook, AtlasVerticalFlipbookMixin)
	self.EmpoweredFlipBook:SetSize(96, 96)
	self.EmpoweredFlipBook:SetPoint("CENTER", 0, 0)
	self.EmpoweredFlipBook:SetAtlas("SunPowerEmpoweredFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.EmpoweredFlipBook, "SunPowerEmpoweredFlipBook", 256, 256, 64, 60, false)
	self.EmpoweredFlipBook:SetBlendMode("ADD")
	self.EmpoweredFlipBook:Hide()

	self.ArtWork:ClearAllPoints()
	self.ArtWork:SetPoint("CENTER", 0, 0)
	self.ArtWork:SetTexture("INTERFACE\\CoAResource\\sunpwr_art")
	self.ArtWork:SetSize(128, 128)
	self.ArtWork:SetDrawLayer("BACKGROUND")

	self.Text:SetPoint("CENTER", 0, 0)
end
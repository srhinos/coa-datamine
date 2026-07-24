if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "SONOFARUGAL" then return end

CoAResourceOrbMixinWorgen = {}

function CoAResourceOrbMixinWorgen:OnLoad()
	self.maxOverlayFrames = 64

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

function CoAResourceOrbMixinWorgen:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

function CoAResourceOrbMixinWorgen:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinWorgen:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinWorgen:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbMixinWorgen:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinWorgen:NormalizeStackValue(value, maxValue)
	value = tonumber(value) or 0
	maxValue = tonumber(maxValue) or 0

	if maxValue > 0 and value > maxValue then
		local normalized = math.floor(value % 256)
		if normalized <= maxValue then
			value = normalized
		end
	end

	return math.clamp(math.floor(value + 0.5), 0, maxValue)
end

function CoAResourceOrbMixinWorgen:GetDisplayedProgress()
	local frame = self.ResourceOverlayFlipBook.frame or self.maxOverlayFrames
	frame = math.clamp(frame, 1, self.maxOverlayFrames)

	if self:GetSpellID() == 706613 then
		return math.clamp(math.ceil(frame * 100 / self.maxOverlayFrames), 0, 100)
	end

	return math.clamp(math.ceil(((self.maxOverlayFrames - frame) * 100) / self.maxOverlayFrames), 0, 100)
end

function CoAResourceOrbMixinWorgen:GetFrameForProgress(progress)
	progress = math.clamp(progress or 0, 0, 100)

	if self:GetSpellID() == 706613 then
		return math.clamp(math.ceil(progress * self.maxOverlayFrames / 100), 1, self.maxOverlayFrames)
	end

	return math.clamp(math.ceil(self.maxOverlayFrames - (progress * self.maxOverlayFrames / 100)), 1, self.maxOverlayFrames)
end

function CoAResourceOrbMixinWorgen:UpdateDisplayedState()
	local maxValue = self.maxValue or 0
	local displayValue = 0

	if maxValue > 0 then
		displayValue = math.clamp(math.floor((self:GetDisplayedProgress() * maxValue / 100) + 0.5), 0, maxValue)
	end

	self.Text:SetText(displayValue .. "/" .. maxValue)
	self.ResourceFlipBook:SetShown(maxValue > 0 and displayValue >= maxValue)
end

function CoAResourceOrbMixinWorgen:SetProgress(progress, value, maxValue)
	maxValue = tonumber(maxValue) or 0
	value = self:NormalizeStackValue(value, maxValue)
	progress = (maxValue > 0) and math.clamp(math.floor((value * 100 / maxValue) + 0.5), 0, 100) or 0

	CoAResourceOrbMixin.SetProgress(self, progress, value, maxValue)

	if self.snapNextProgress then
		self.ResourceOverlayFlipBook.frame = self:GetFrameForProgress(progress)
		AtlasVerticalFlipbookMixin.SetFrame(self.ResourceOverlayFlipBook, self.ResourceOverlayFlipBook.frame)
		self.snapNextProgress = nil
	end

	self:UpdateDisplayedState()
end

function CoAResourceOrbMixinWorgen:SetWorgen()	
	self:LayoutWorgen()
	self.ResourceFlipBook:Init()
	self.ResourceFlipBook.fps = 0.05
	self.ResourceOverlayFlipBook:Init()
	self.snapNextProgress = true

	self:SetSpellID(680687) -- TODO: to constants
end

function CoAResourceOrbMixinWorgen:SetThirst()	
	self:LayoutThirst()
	self.ResourceFlipBook:Init()
	self.ResourceFlipBook.fps = 0.05
	self.ResourceOverlayFlipBook:Init()
	self.snapNextProgress = true

	self:SetSpellID(706613) -- TODO: to constants
end

function CoAResourceOrbMixinWorgen:OnUpdate(elapsed)
	if CoAResourceOrb:GetSpellID() == 706613 then
		AtlasVerticalFlipbookMixin.Update(self.ResourceFlipBook, elapsed)

		if self.ResourceFlipBook.frame > self.ResourceFlipBook.frames then
			self.ResourceFlipBook.frame = 1
		end
	
		local overlayProgress = math.ceil(self.ResourceOverlayFlipBook.frame * 100 / self.maxOverlayFrames)

		if math.abs(overlayProgress - self.progress) >= self.eps then
			local progressStep = 1
			self.ResourceOverlayFlipBook.frame = math.ceil(self.ResourceOverlayFlipBook.frame + ((overlayProgress > self.progress) and -progressStep or progressStep))
		end

		if self.ResourceOverlayFlipBook.frame == 0 then 
			self.ResourceOverlayFlipBook.frame = 1
		end

		AtlasVerticalFlipbookMixin.SetFrame(self.ResourceOverlayFlipBook, self.ResourceOverlayFlipBook.frame)
		self:UpdateDisplayedState()
	else
		CoAResourceOrbMixin.OnUpdate(self, elapsed)
		self:UpdateDisplayedState()
	end
end

function CoAResourceOrbMixinWorgen:LayoutThirst()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(170, 85)
	self.ResourceFlipBook:SetPoint("CENTER", 0, -6)
	self.ResourceFlipBook:SetAtlas("BloodMageFlipBookOverpower", Const.TextureKit.IgnoreAtlasSize)
	self.ResourceFlipBook:SetTexture("Interface\\CoAResource\\atlas_full_bloodmage")
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "BloodMageFlipBookOverpower", 256, 128, 64, 60, false)
	self.ResourceFlipBook:SetDrawLayer("ARTWORK")
	self.ResourceFlipBook:SetBlendMode("BLEND")
	self.ResourceFlipBook:Hide()

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(170, 85)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, -6)
	self.ResourceOverlayFlipBook:SetAtlas("BloodMageFlipBookFill", Const.TextureKit.IgnoreAtlasSize)
	self.ResourceOverlayFlipBook:SetTexture("Interface\\CoAResource\\atlas_full_bloodmage")
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "BloodMageFlipBookFill", 256, 128, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BACKGROUND")
	self.ResourceOverlayFlipBook:Show()

	self.ArtWork:Hide()

	self.Text:SetPoint("CENTER", 0, 0)
end

function CoAResourceOrbMixinWorgen:LayoutWorgen()
	self.ResourceFlipBook:ClearAllPoints()
	self.ResourceFlipBook:SetSize(104, 104)
	self.ResourceFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceFlipBook:SetAtlas("WorgenEmpoveredFlipBook", Const.TextureKit.IgnoreAtlasSize)
	self.ResourceFlipBook:SetTexture("Interface\\CoAResource\\SoA_Empovered_flipbook")
	C_Flipbook:CreateAtlasFlipbook(self.ResourceFlipBook, "WorgenEmpoveredFlipBook", 128, 128, 64, 60, false)
	self.ResourceFlipBook:SetDrawLayer("ARTWORK")
	self.ResourceFlipBook:SetBlendMode("ADD")
	self.ResourceFlipBook:Hide()

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(104, 104)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceOverlayFlipBook:SetAtlas("WorgenOrbFillFlipBook", Const.TextureKit.IgnoreAtlasSize)
	self.ResourceOverlayFlipBook:SetTexture("Interface\\CoAResource\\SoA_Flipbook_filling")
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "WorgenOrbFillFlipBook", 256, 256, self.maxOverlayFrames, 60, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BACKGROUND")
	self.ResourceOverlayFlipBook:Show()

	self.ArtWork:SetDrawLayer("BORDER")
	self.ArtWork:ClearAllPoints()
	self.ArtWork:SetPoint("CENTER", 0, 0)
	self.ArtWork:SetTexture("INTERFACE\\CoAResource\\SoA_Wolf")
	self.ArtWork:SetSize(104, 104)
	self.ArtWork:Show()

	self.Text:SetPoint("CENTER", 0, 6)
end

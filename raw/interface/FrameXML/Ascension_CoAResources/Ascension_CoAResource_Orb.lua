CoAResourceOrbMixin = {}

function CoAResourceOrbMixin:OnLoad()
	--self:Layout()

	self.value = 0
	self.maxValue = 0
	self.progress = 100

	self.eps = 2
	self.maxOverlayFrames = 48

	MixinAndLoad(self.ResourceFlipBook, AtlasVerticalFlipbookMixin)
	MixinAndLoad(self.ResourceOverlayFlipBook, AtlasVerticalFlipbookMixin)
	
	self:SetScript("OnEvent", OnEventToMethod)
end

function CoAResourceOrbMixin:OnShow()
	self:RegisterEvent("CVAR_UPDATE")
end

function CoAResourceOrbMixin:OnHide()
	self:UnregisterEvent("CVAR_UPDATE")
end

function CoAResourceOrbMixin:SetSpellID(value)
	self.spellID = value
end

function CoAResourceOrbMixin:GetSpellID()
	return self.spellID
end

function CoAResourceOrbMixin:OnLeave()
	GameTooltip:Hide()
end

function CoAResourceOrbMixin:OnUpdate(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.ResourceFlipBook, elapsed)

	if self.ResourceFlipBook.frame > self.ResourceFlipBook.frames then
		self.ResourceFlipBook.frame = 1
	end

	local overlayProgress = math.ceil(((self.maxOverlayFrames-self.ResourceOverlayFlipBook.frame)*100)/self.maxOverlayFrames)

	if math.abs(overlayProgress - self.progress) < self.eps then
		return
	else
		local progressStep = 1
		self.ResourceOverlayFlipBook.frame = math.ceil(self.ResourceOverlayFlipBook.frame + ((overlayProgress > self.progress) and progressStep or -progressStep))
	end

	AtlasVerticalFlipbookMixin.SetFrame(self.ResourceOverlayFlipBook, self.ResourceOverlayFlipBook.frame)
end

function CoAResourceOrbMixin:SetProgress(progress, value, maxValue)
	self.progress = progress

	self:SetValue(value, maxValue)

	self.Text:SetText(self.value.."/"..self.maxValue)
end

function CoAResourceOrbMixin:SetValue(value, maxValue)
	self.value = value
	self.maxValue = maxValue
end

function CoAResourceOrbMixin:CVAR_UPDATE(cvar)
	if (cvar == "STATUS_TEXT_PERCENT") then
		self:SetProgress(self.progress, self.value, self.maxValue)
	end
end
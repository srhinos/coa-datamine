if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "WILDWALKER" then return end

CoAResourceOrbMixinPrimalist = {}

function CoAResourceOrbMixinPrimalist:OnLoad()
	self.maxOverlayFrames = 16

	self:Layout()
	self.ResourceOverlayFlipBook:Init()

	self:SetSpellID(680441) -- TODO: to constants
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

function CoAResourceOrbMixinPrimalist:OnEnter()
	CoAMultiCastFlyoutButtonMixin.OnEnter(self)
	GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
	GameTooltip:Show()
end

-- overwritten
function CoAResourceOrbMixinPrimalist:OnUpdate(elapsed)
	local diff

	for i = 1, BUFF_MAX_DISPLAY do
		local _, _, _, _, _, _, expirationTime, _, _, _, spellID = UnitBuff("player", i)
		if spellID == self:GetSpellID() then
			diff = expirationTime - GetTime()
			break
		end
	end

	if not diff then
		return
	end

	self:SetProgress(self.progress, self.value, self.maxValue)

	self.Text:SetText(self.Text:GetText().."("..string.format(SECOND_ONELETTER_ABBR, math.ceil(diff))..")")

	if diff and (diff <= 5) then 
		self.ArtWork:Show()
	else
		self.ArtWork:Hide()
	end
end


function CoAResourceOrbMixinPrimalist:OnDragStart()
	self:StartMoving()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinPrimalist:OnDragStop()
	self:StopMovingOrSizing()
	self:SavePosition()
	HideDropDownMenu(1)
end

function CoAResourceOrbMixinPrimalist:SetShowText(show)
	print("CoAResourceOrbMixinPrimalist:SetShowText")
	CoAResourceBarMixin.SetShowText(self, show)
end

function CoAResourceOrbMixinPrimalist:OnClick(button)
	CoAResourceMixin.OnClick(self, button)
end

function CoAResourceOrbMixinPrimalist:SetProgress(progress, value, maxValue)
	progress = (progress*100/maxValue)

	self.progress = progress

	self:SetValue(value, maxValue)

	self.Text:SetText(self.value)

	AtlasVerticalFlipbookMixin.SetFrame(self.ResourceOverlayFlipBook, value+1)
end

function CoAResourceOrbMixinPrimalist:Layout()
	self.ResourceFlipBook:Hide()

	self.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceOverlayFlipBook:SetSize(112, 112)
	self.ResourceOverlayFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceOverlayFlipBook:SetAtlas("GeomancerGeodeAtlas", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceOverlayFlipBook, "GeomancerGeodeAtlas", 256, 256, self.maxOverlayFrames, 16, false)
	self.ResourceOverlayFlipBook:SetDrawLayer("BACKGROUND")

	self.ArtWork:SetAtlas("GeomancerGeodeAtlas", Const.TextureKit.IgnoreAtlasSize)
	self.ArtWork:SetTexCoord(0, 0.25, 0, 0.25)
	self.ArtWork:ClearAllPoints()
	self.ArtWork:SetPoint("CENTER", 0, 0)
	self.ArtWork:SetSize(112, 112)

	self.ArtWork.Pulse = self.ArtWork:CreateAnimationGroup()

	self.ArtWork.Pulse.AlphaDown = self.ArtWork.Pulse:CreateAnimation("ALPHA")
	self.ArtWork.Pulse.AlphaDown:SetChange(-1)
	self.ArtWork.Pulse.AlphaDown:SetDuration(0.5)
	self.ArtWork.Pulse.AlphaDown:SetSmoothing("IN")
	self.ArtWork.Pulse.AlphaDown:SetOrder(1)

	self.ArtWork.Pulse.AlphaUp = self.ArtWork.Pulse:CreateAnimation("ALPHA")
	self.ArtWork.Pulse.AlphaUp:SetChange(1)
	self.ArtWork.Pulse.AlphaUp:SetDuration(0.5)
	self.ArtWork.Pulse.AlphaUp:SetSmoothing("OUT")
	self.ArtWork.Pulse.AlphaUp:SetOrder(2)

	self.ArtWork.Pulse:SetLooping("REPEAT")
	self.ArtWork.Pulse:Play()

	self.ArtWork:Hide()

	self.Text:SetPoint("CENTER", 0, -28)
end
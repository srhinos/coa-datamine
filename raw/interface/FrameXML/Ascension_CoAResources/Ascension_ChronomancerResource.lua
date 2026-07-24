if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "CHRONOMANCER" then return end

local ORB_OF_FATE_AURA = 804455
local ORB_OF_FATE_INTERNALID = 31183

local LOCAL_AURA_DURATION = 0

--
-- Controller
--
ClassMixinChronomancer = {}

function ClassMixinChronomancer:OnLoad()
	self:OnPlayerAura()
	MixinAndLoadScripts(CoASpellActivationOverlay, "CoASpellActivationOverlayMixinChronomancer")
end

function ClassMixinChronomancer:OnPlayerAura()
	if not C_CharacterAdvancement.IsKnownID(ORB_OF_FATE_INTERNALID) then
		return
	end

	local _, _, _, stacks, _, _, durTime = AuraUtil.GetBuff("player", ORB_OF_FATE_AURA, true, AuraUtil.Predicate.MatchesSpellID)
	stacks = stacks or 0
	local totalShown = CoASpellActivationOverlay:GetTotalShownLocations(ORB_OF_FATE_AURA) or 0

	if not CoASpellActivationOverlay or not CoASpellActivationOverlay.listening then
		if totalShown > 0 then
			CoASpellActivationOverlay:HideAllOverlays()
		end

		return
	end
		
	if (totalShown > 0) and (stacks == 0) then
		CoASpellActivationOverlay:HideAllOverlays()
		return
	end

	LOCAL_AURA_DURATION = durTime

	local nextItem = totalShown+1

	for i = 1, stacks-totalShown do
		local location

		if nextItem == 1 then
			location = "LEFT"
		elseif nextItem == 2 then
			location = "TOPLEFT"
		elseif nextItem == 3 then
			location = "TOP"
		elseif nextItem == 4 then
			location = "TOPRIGHT"
		elseif nextItem == 5 then
			location = "RIGHT"
		end

		if not location then
			return
		end

		CoASpellActivationOverlay:SPELL_ACTIVATION_SHOW(ORB_OF_FATE_AURA, location, 1, 255, 255, 255)
	end
end

--
-- CoASpellOverlayMixin overwrites
--
CoASpellOverlayMixinChronomancer = {}

function CoASpellOverlayMixinChronomancer:OnLoad()
	self.init = true
	MixinAndLoad(self.Texture, AtlasVerticalFlipbookMixin)

	self.Texture:ClearAllPoints()
	self.Texture:SetPoint("CENTER", 0, 0)
	self.Texture:SetAtlas("ChronomancerOrbFlipBook", Const.TextureKit.IgnoreAtlasSize)
	self.Texture:SetSize(88, 88)
	C_Flipbook:CreateAtlasFlipbook(self.Texture, "ChronomancerOrbFlipBook", 256, 256, 64, 60, false)

	self.Texture.fps = 0.01
	self.Texture:Init()
	self.Texture:Show()

	self:SetSize(128, 128)

	self.Texture.AlphaPulse = self.Texture:CreateAnimationGroup()

	self.Texture.AlphaPulse.AlphaDown = self.Texture.AlphaPulse:CreateAnimation("ALPHA")
	self.Texture.AlphaPulse.AlphaDown:SetChange(-1)
	self.Texture.AlphaPulse.AlphaDown:SetDuration(0.5)
	self.Texture.AlphaPulse.AlphaDown:SetSmoothing("IN")
	self.Texture.AlphaPulse.AlphaDown:SetOrder(1)

	self.Texture.AlphaPulse.AlphaUp = self.Texture.AlphaPulse:CreateAnimation("ALPHA")
	self.Texture.AlphaPulse.AlphaUp:SetChange(1)
	self.Texture.AlphaPulse.AlphaUp:SetDuration(0.5)
	self.Texture.AlphaPulse.AlphaUp:SetSmoothing("OUT")
	self.Texture.AlphaPulse.AlphaUp:SetOrder(2)
	self.Texture.AlphaPulse:SetLooping("REPEAT")
end

function CoASpellOverlayMixinChronomancer:OnUpdate(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.Texture, elapsed)

	if self.Texture.frame > self.Texture.frames then
		self.Texture.frame = 1
	end

	local diff = LOCAL_AURA_DURATION - GetTime()

	if diff <= 5 then
		self.Texture.AlphaPulse:Play()
	elseif self.Texture.AlphaPulse:IsPlaying() then
		self.Texture.AlphaPulse:Stop()
	end
end

function CoASpellOverlayMixinChronomancer:FrameFadeOut(duration)
	self.Texture.AlphaPulse:Stop()
	CoASpellOverlayMixin.FrameFadeOut(self, duration)
end

--
-- CoASpellActivationOverlay overwrites
--
CoASpellActivationOverlayMixinChronomancer = {}

-- overwrites GetOverlay
function CoASpellActivationOverlayMixinChronomancer:GetOverlay(spellID, position)
	local overlay = CoASpellActivationOverlayMixin.GetOverlay(self, spellID, position)

	if overlay and not overlay.init then
		MixinAndLoadScripts(overlay, CoASpellOverlayMixinChronomancer)
	end

	return overlay
end

-- overwrites ShowOverlay
function CoASpellActivationOverlayMixinChronomancer:ShowOverlay(spellID, position, scale, r, g, b, vFlip, hFlip)
	local overlay = self:GetOverlay(spellID, position)
	
	overlay:ClearAllPoints()
	
	if position == "CENTER" then
		overlay:SetPoint("CENTER", self, "CENTER", 0, 0)
	elseif position == "LEFT" then
		overlay:SetPoint("RIGHT", self, "LEFT", 0, 0)
	elseif position == "RIGHT" then
		overlay:SetPoint("LEFT", self, "RIGHT", 0, 0)
	elseif position == "TOP" then
		overlay:SetPoint("BOTTOM", self, "TOP")
	elseif position == "BOTTOM" then
		overlay:SetPoint("TOP", self, "BOTTOM")
	elseif position == "TOPRIGHT" then
		overlay:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", -64, -64)
	elseif position == "TOPLEFT" then
		overlay:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 64, -64)
	elseif position == "BOTTOMRIGHT" then
		overlay:SetPoint("TOPLEFT", self, "BOTTOMRIGHT", 0, 0)
	elseif position == "BOTTOMLEFT" then
		overlay:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
	else
		return
	end
	
	PlaySound(SOUNDKIT.UI_PETBATTLE_CAMERAROTATE)
	overlay:FrameFadeIn(0.1)
	overlay.Pulse:Play()
end
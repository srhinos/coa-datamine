DraftCardCoverMixin = {}

local CoverMinScale = 0.85
local CoverMaxScale = 0.91

DraftCardCoverMixin.ArtStyle = {
	Default = 1,
	Darkmoon = 2,
	Skill = 3,
	GoldSkill = 4,
}

local sparklePool = CreateTexturePool(UIParent, "BACKGROUND", "SparkleTemplate")

local qualitySounds = {
	[0] = SOUNDKIT.COMMON_UI_MISSION_SELECT,
	[2] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[3] = SOUNDKIT.RARE_UI_ORDERHALL_TALENT_READY_TOAST,
	[4] = SOUNDKIT.EPIC_UI_MISSION_200PERCENT,
	[5] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
	[6] = SOUNDKIT.LEGENDARY_UI_LEGENDARY_ITEM_TOAST,
}

function DraftCardCoverMixin:OnLoad()
	self.SparklePool = sparklePool
	self:SetScale(CoverMinScale)
end

function DraftCardCoverMixin:SetQuality(quality)
	self.quality = quality
end 

function DraftCardCoverMixin:OnEnter()
	if self:GetParent():IsCoverFadingOrHidden() then return end
	if self:GetParent():IsAnimating() then return end
	PlaySound(SOUNDKIT.HOVER_BIRDFLAP5)
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow:Hide()
	self.SparklePool:ReleaseAll()

	self.AnimationTime = 0
	self.CurrentScale = self:GetScale()
	self.TargetScale = CoverMaxScale

	self:SetScript("OnUpdate", self.UpdateScale)

	if not self.quality or self.quality < 2 then
		return
	end

	self.BackgroundGlow.Anim:Play()
	local color = ITEM_QUALITY_COLORS[self.quality]

	for i = 1, 50 do
		local sparkle = self.SparklePool:Acquire()
		sparkle:SetSize(32, 32)
		sparkle.Anim:SetTranslationRange(-118, 118, -128, 128)
		sparkle:SetParent(self)
		sparkle:ClearAndSetPoint("CENTER", math.sin(i) * 120, math.cos(i) * 240)
		sparkle.Anim:SetLifetimeRange(6, 16)
		sparkle:SetVertexColor(color:GetRGBA())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end
end

function DraftCardCoverMixin:OnLeave()
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow:Hide()
	self.SparklePool:ReleaseAll()
	if self:GetParent():IsCoverFadingOrHidden() then return end
	self.AnimationTime = 0
	self.CurrentScale = self:GetScale()
	self.TargetScale = CoverMinScale
	self:SetScript("OnUpdate", self.UpdateScale)
end

function DraftCardCoverMixin:OnHide()
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow:Hide()
	self:SetScript("OnUpdate", nil)
	self:SetScale(CoverMinScale)
	self.AnimationTime = 0
	self.TargetScale = CoverMinScale
end

function DraftCardCoverMixin:OnShow()
	self.Background:Show()
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow:Hide()
	self.CloseButton:Show()
end

function DraftCardCoverMixin:UpdateScale(elapsed)
	if self.AnimationTime >= 1 then
		self:SetScale(self.TargetScale)
		self:SetScript("OnUpdate", nil)
		return
	end
	
	self:SetScale(math.lerp(self.CurrentScale, self.TargetScale, self.AnimationTime))
	self.AnimationTime = self.AnimationTime + (elapsed * 5)
end

function DraftCardCoverMixin:OnClick()
	if self:GetParent():IsCoverFadingOrHidden() then return end
	PlaySound(qualitySounds[self.quality or 0])
	Draft:SetRevealedCard(self:GetParent():GetID())
	self.Background:Hide()
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow:Hide()
	self.CloseButton:Hide()
	self:GetParent():StartRevealCooldown()
	self:GetParent():PlayRevealAnimation()
end

function DraftCardCoverMixin:SetArtStyle(artStyle)
	if artStyle == DraftCardCoverMixin.ArtStyle.Default then
		self.Background:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CardFrame\\CardBack2")
		self.BackgroundGlow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CardFrame\\hover")
	elseif artStyle == DraftCardCoverMixin.ArtStyle.Darkmoon then
		self.Background:SetTexture("Interface\\Draft\\Darkmoon")
		self.BackgroundGlow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CardFrame\\hover")
	elseif artStyle == DraftCardCoverMixin.ArtStyle.GoldSkill then
		self.Background:SetTexture("Interface\\Draft\\cardcover_Lucky_gold")
		self.BackgroundGlow:SetTexture("Interface\\Draft\\hoverSkillCard")
	elseif artStyle == DraftCardCoverMixin.ArtStyle.Skill then
		self.Background:SetTexture("Interface\\Draft\\cardcover_Lucky")
		self.BackgroundGlow:SetTexture("Interface\\Draft\\hoverSkillCard")
	end
end

DraftUnlockAnimationMixin = {}

function DraftUnlockAnimationMixin:OnLoad()
	self.MagicAdd.Anim.RotationIn:SetDegrees(-15)
	self.MagicAdd.Anim.RotationMid:SetDegrees(-90)
	self.MagicAdd.Anim.RotationOut:SetDegrees(-30)

	self.MagicAdd3.Anim.ScaleOut:SetScale(3, 3)
	self.MagicAdd3.Anim.ScaleOut:SetDuration(1.5)
end

function DraftUnlockAnimationMixin:Play()
	self.Magic.Anim:Stop()
	self.MagicAdd.Anim:Stop()
	self.MagicAdd2.Anim:Stop()
	self.MagicAdd3.Anim:Stop()
	
	self.Magic.Anim:Play()
	self.MagicAdd.Anim:Play()
	self.MagicAdd2.Anim:Play()
	self.MagicAdd3.Anim:Play()
end 

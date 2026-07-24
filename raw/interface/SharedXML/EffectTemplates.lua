SparkleAnimationMixin = {
	enableRotation = true
}

function SparkleAnimationMixin:OnLoad()
	SetParentArray(self:GetParent(), "ColoredEffects")

	if self.Rotation then
		self:GetParent():SetRotation(math.random(0, 360))
	end
	
	self:SetTranslationRange(-118, 118, -118, 118)
	self:SetLifetimeRange(4, 8)
end

function SparkleAnimationMixin:SetTranslationRange(minX, maxX, minY, maxY)
	self.minX = minX
	self.maxX = maxX
	self.minY = minY
	self.maxY = maxY
end

function SparkleAnimationMixin:SetLifetimeRange(minValue, maxValue)
	self.minLife = math.abs(minValue)
	self.maxLife = math.abs(maxValue)
end

function SparkleAnimationMixin:Refresh()
	local x = math.random(self.minX, self.maxX)
	local y = math.random(self.minY, self.maxY)

	local lifetime = math.random(self.minLife, self.maxLife)

	self.Translation:SetOffset(x, y)
	self.Translation:SetDuration(lifetime)
	if self.Rotation then
		self.Rotation:SetDuration(lifetime)
	end

	local fourth = lifetime / 4
	self.Alpha1:SetDuration(fourth)
	self.Alpha2:SetStartDelay(fourth)
	self.Alpha2:SetDuration(lifetime - fourth)
	self:Play()
end

ParticleAnimationMixin = {}

function ParticleAnimationMixin:OnLoad()
	SetParentArray(self:GetParent(), "ColoredEffects")
	self:GetParent():SetRotation(math.random(0, 360))
end

function ParticleAnimationMixin:PlayAt(x, y, offsetX, offsetY, flipH, flipV, degrees)
	local texture = self:GetParent()

	texture:ClearAndSetPoint("CENTER", x, y)

	local left, right, top, bottom = 0, 1, 0, 1
	if flipH then
		left, right = right, left
	end

	if flipV then
		top, bottom = bottom, top
	end

	self.Translation:SetOffset(offsetX, offsetY)
	self.Rotation:SetDegrees(degrees)

	self:Play()
end

SmokeParticleAnimationMixin = {}

function SmokeParticleAnimationMixin:PlayAt(offsetX, offsetY, degrees, flipH, flipV)
	self.Translation:SetOffset(offsetX, offsetY)
	self.Rotation:SetDegrees(degrees)

	local left, right, top, bottom = 0, 1, 0, 1
	if flipH then
		left, right = right, left
	end

	if flipV then
		top, bottom = bottom, top
	end

	local texture = self:GetParent()
	texture:SetTexCoord(left, right, top, bottom)

	self:Play()
end

LoopingParticleAnimationMixin = {}

function LoopingParticleAnimationMixin:OnLoad()
	SetParentArray(self:GetParent(), "ColoredEffects")
	self.Rotation = math.random(0, 360)
	self:GetParent():SetRotation(self.Rotation)
end

function LoopingParticleAnimationMixin:OnUpdate(elapsed)
	if not self:IsPlaying() then return end
	if not self.time or self.time >= 1 then
		self.time = 0
		self.StartAlpha = self.TargetAlpha or 1
		self.TargetAlpha = math.random(0.2, 0.8)
	else
		self.Rotation = self.Rotation + (elapsed * 0.05)

		if self.Rotation > 360 then
			self.Rotation = self.Rotation - 360
		end
		self.time = self.time + (elapsed * 0.25)
	end

	self:GetParent():SetAlpha(math.lerp(self.StartAlpha, self.TargetAlpha, EaseInOut(self.time)))
	self:GetParent():SetRotation(self.Rotation)
end 
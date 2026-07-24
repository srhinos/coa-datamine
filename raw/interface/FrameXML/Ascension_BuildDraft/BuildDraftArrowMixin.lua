BuildDraftArrowMixin = {}

function BuildDraftArrowMixin:OnLoad()
	self:SetDirection("right")
	self._sparkles = CreateTexturePool(self, "OVERLAY", "SparkleTemplate")
end

function BuildDraftArrowMixin:SetDirection(direction)
	self.Arrow:SetAtlas("build-draft-cycle-arrow", Const.TextureKit.UseAtlasSize)
	self.Highlight:SetAtlas("build-draft-cycle-arrow", Const.TextureKit.UseAtlasSize)

	if direction == "left" then
		self.Arrow:FlipX()
		self.Highlight:FlipX()
		self.Shadow:SetPoint("CENTER", 45, 0)
	else
		self.Shadow:SetPoint("CENTER", -45, 0)
	end

	self.direction = direction
end

function BuildDraftArrowMixin:SetTarget(target)
	self.Target = target
end

function BuildDraftArrowMixin:OnMouseDown()
	if self.direction == "left" then
		BuildDraft.Cards[3]:SetPoint("CENTER", -241, -2)
		self.Arrow:SetPoint("CENTER", -1, -2)
		self.Highlight:SetPoint("CENTER", -1, -2)
	else
		BuildDraft.Cards[2]:SetPoint("CENTER", 241, -2)
		self.Arrow:SetPoint("CENTER", 1, -2)
		self.Highlight:SetPoint("CENTER", 1, -2)
	end
end

function BuildDraftArrowMixin:OnMouseUp()
	if self.direction == "left" then
		BuildDraft.Cards[3]:SetPoint("CENTER", -240, 0)
	else
		BuildDraft.Cards[2]:SetPoint("CENTER", 240, 0)
	end
	self.Arrow:SetPoint("CENTER")
	self.Highlight:SetPoint("CENTER")
end

function BuildDraftArrowMixin:OnShow()
	self.Arrow:SetPoint("CENTER")
	self.Highlight:SetPoint("CENTER")
	self.time = 1
	self.Shadow:SetAlpha(1)
end

function BuildDraftArrowMixin:OnClick()
	PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)
	BuildDraft:Cycle(self.direction)
end

function BuildDraftArrowMixin:OnDisable()
	self.Arrow:SetDesaturated(true)
end

function BuildDraftArrowMixin:OnEnable()
	self.Arrow:SetDesaturated(false)
end

function BuildDraftArrowMixin:Animate(elapsed)
	if self.time >= 1 then
		self.Shadow:SetAlpha(self.targetAlpha)

		if self.targetAlpha == 1 then
			self._sparkles:ReleaseAll()
		end

		self.targetAlpha = nil
		self.currentAlpha = nil
		self:SetScript("OnUpdate", nil)
		return
	end

	local alpha = math.lerp(self.currentAlpha, self.targetAlpha, self.time)
	self.Shadow:SetAlpha(alpha)
	self.time = self.time + elapsed * 3
end

function BuildDraftArrowMixin:OnEnter()
	PlaySound(SOUNDKIT.HOVER_BIRDFLAP5)
	self.targetAlpha = 0.4
	self.currentAlpha = 1
	self.time = 0
	local color
	if self.direction == "left" then
		color = BuildDraft.Cards[3].Color
	else
		color = BuildDraft.Cards[2].Color
	end

	for i = 1, 50 do
		local sparkle = self._sparkles:Acquire()
		sparkle:SetSize(24, 24)

		if self.direction == "left" then
			sparkle.Anim:SetTranslationRange(-120, 40, -80, 80)
			sparkle:ClearAndSetPoint("CENTER", math.random(-140, 100), math.random(-220, 220))
		else
			sparkle.Anim:SetTranslationRange(-40, 120, -80, 80)
			sparkle:ClearAndSetPoint("CENTER", math.random(-100, 140), math.random(-220, 220))
		end
		sparkle.Anim:SetLifetimeRange(6, 16)
		sparkle:SetVertexColor(color:GetRGBA())
		sparkle:Show()
		sparkle.Anim:Refresh()
	end

	self:SetScript("OnUpdate", self.Animate)
end

function BuildDraftArrowMixin:OnLeave()
	self.targetAlpha = 1
	self.currentAlpha = 0.4
	self.time = 0

	for sparkle in self._sparkles:EnumerateActive() do
		sparkle.FadeOut:Play()
	end
	self:SetScript("OnUpdate", self.Animate)
end

if C_Realm.IsDevelopment() then
	SlashCmdList["BDRAFT"] = function()
		print("|cffFFD100[Left Card] = |r" .. BuildDraft.Cards[3].Build)
		print("|cffFFD100[Middle Card] = |r" .. BuildDraft.Cards[1].Build)
		print("|cffFFD100[Right Card] = |r" .. BuildDraft.Cards[2].Build)
	end

	SLASH_BDRAFT1 = "/bdraft"
end
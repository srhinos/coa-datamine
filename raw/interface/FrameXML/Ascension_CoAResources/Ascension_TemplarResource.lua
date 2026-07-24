if not IsCustomClass() then return end
local class = C_Player:GetClass()
if class ~= "MONK" then return end

local CHASTISE_SPELL = 803157
local COMBO_AURAS = {
    804903, -- Holy Cleave
    804904, -- Righteous Lunge
    804922, -- Tyr's Hammer
    804924, -- Retribution
    805332, -- Sanctified Smash
}
local AURA_ORDER = { "TOPLEFT", "TOP", "TOPRIGHT" }
local COMBO_CHAIN_AURA = 704576
local LOCAL_AURA_DURATION = 0

--
-- Controller
--
ClassMixinTemplar = {}

local function PositionTemplarResourceBar()
    CoAResourceSegmentBar:ClearAllPoints()
    CoAResourceSegmentBar:SetPoint("BOTTOM", MainMenuBar, "TOP", 0, 45)
    CoAResourceSegmentBar:RestorePosition()
end

local function EnsureChastiseKnown()
    if C_Spell:IsAnyRankKnown(CHASTISE_SPELL, true) then
        return true
    end
    if CoAResourceSegmentBar.init then
        CoAResourceSegmentBar:ClearActive()
    end
    CoAResourceSegmentBar:Hide()
    return false
end

function ClassMixinTemplar:OnLoad()
    if not EnsureChastiseKnown() then
        return
    end

    PositionTemplarResourceBar()

    if not CoAResourceSegmentBar:IsShown() then
        if not CoAResourceSegmentBar.init then
            MixinAndLoadScripts(CoAResourceSegmentBar, "CoAResourceSegmentBarTemplarMixin")
            CoAResourceSegmentBar.init = true
        end
    end

    self:OnPlayerAura()
end

function ClassMixinTemplar:OnPlayerAura()
    if not EnsureChastiseKnown() then
        return
    end

    PositionTemplarResourceBar()

    -- lazy init so the bar appears as soon as Chastise is learned (no relog)
    if not CoAResourceSegmentBar.init then
        MixinAndLoadScripts(CoAResourceSegmentBar, "CoAResourceSegmentBarTemplarMixin")
        CoAResourceSegmentBar.init = true
    end

    local _, _, _, _, _, _, durTime = AuraUtil.GetBuff("player", COMBO_CHAIN_AURA, true, AuraUtil.Predicate.MatchesSpellID)
    LOCAL_AURA_DURATION = durTime or 0
    CoAResourceSegmentBar:ShowTemplate("Templar", 0, 3, COMBO_CHAIN_AURA)
    CoAResourceSegmentBar:Show()
    CoAResourceSegmentBar:Update()

    if not durTime then
        CoAResourceSegmentBar:ClearActive()
        return
    end

    for _, spellID in pairs(COMBO_AURAS) do
        local stacks = select(4, AuraUtil.GetBuff("player", spellID, true, AuraUtil.Predicate.MatchesSpellID))
        if stacks and stacks > 0 then
            local diff = stacks - CoAResourceSegmentBar:GetTotalAuras(spellID)
            if diff > 0 then
                for i = 1, diff do
                    local resourceShown = CoAResourceSegmentBar:SetNextActiveAura(spellID)
                    if resourceShown == 3 then
                        CoAResourceSegmentBar:ShowGlow()
                    end
                end
            end
        end
    end
end

--
-- CoAResourceSegmentBarMixin overwrites
--
CoAResourceSegmentBarTemplarMixin = {}

function CoAResourceSegmentBarTemplarMixin:GetTotalAuras(spellID)
	local total = 0

	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
			if segment.activeAuraID and (segment.activeAuraID == spellID) then
				total = total + 1
			end
		end
	end

	return total
end

function CoAResourceSegmentBarTemplarMixin:ClearActive()
	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
			segment:ClearActive()
		end
	end
end

function CoAResourceSegmentBarTemplarMixin:ShowGlow()
	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
			segment.BorderGlowTexture:Show()
		end
	end
end

function CoAResourceSegmentBarTemplarMixin:SetNextActiveAura(spellID)
	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
			if not segment.activeAuraID then
				segment:SetActiveAura(spellID)
				return i
			end
		end
	end
end

function CoAResourceSegmentBarTemplarMixin:Update()
	local elementSize = 40

	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
		else
			segment = self.pool:Acquire()
			MixinAndLoadScripts(segment, "CoAResourceSegmentMixinTemplar")

			tinsert(self.segments, segment)

			if i == 1 then
				segment.BorderGlowTexture:SetAtlas("TemplarLeftGlow", Const.TextureKit.UseAtlasSize)
				segment.BorderTexture:SetAtlas("TemplarLeft", Const.TextureKit.UseAtlasSize)
				segment.Fill:SetPoint("CENTER", -24, 0)
				segment:ClearAndSetPoint("LEFT")
			elseif i == 2 then
				segment.BorderGlowTexture:SetAtlas("TemplarMiddleGlow", Const.TextureKit.UseAtlasSize)
				segment.BorderTexture:SetAtlas("TemplarMiddle", Const.TextureKit.UseAtlasSize)
				segment.Fill:SetPoint("CENTER", 0, 32)
				segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 0, -8)
			elseif i == 3 then
				segment.BorderGlowTexture:SetAtlas("TemplarRightGlow", Const.TextureKit.UseAtlasSize)
				segment.BorderTexture:SetAtlas("TemplarRight", Const.TextureKit.UseAtlasSize)
				segment.Fill:SetPoint("CENTER", 24, 0)
				segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 0, 8)
			end
		end

		segment:SetFrameLevel(self:GetFrameLevel()+self.maxValue-i+1)
		segment:Show()
	end

	while #self.segments > self.maxValue do
		self.pool:Release(self.segments[#self.segments])
	end

	self:SetWidth(self.maxValue * elementSize)
end
--
-- CoASpellOverlayMixin overwrites
--
CoAResourceSegmentMixinTemplar = {}

function CoAResourceSegmentMixinTemplar:ClearActive()
	self.BorderGlowTexture:Hide()
	self.activeAuraID = nil
	self.Fill:SetTexture(0, 0, 0, 1)
end

function CoAResourceSegmentMixinTemplar:SetActiveAura(spellID)
	local _, _, icon = GetSpellInfo(spellID)

	if icon then
		self.Fill:SetPortraitTexture(icon)
	end

	self.activeAuraID = spellID
end

function CoAResourceSegmentMixinTemplar:OnLoad()
	self:SetScale(0.5)

	self.init = true

	self.BorderTexture = self:CreateTexture(nil, "OVERLAY")
	self.BorderTexture:SetPoint("CENTER", 0, 0)
	self.BorderTexture:SetSize(128, 128)
	self.BorderTexture:SetTexture(0, 0, 0, 1)

	self.BorderGlowTexture = self:CreateTexture(nil, "OVERLAY")
	self.BorderGlowTexture:SetPoint("CENTER", 0, 0)
	self.BorderGlowTexture:SetSize(128, 128)
	self.BorderGlowTexture:SetTexture(0, 0, 0, 1)
	self.BorderGlowTexture:SetBlendMode("ADD")
	
	self.Fill:ClearAllPoints()
	self.Fill:SetPoint("CENTER", 0, 0)
	self.Fill:SetSize(42, 42)
	self.Fill:SetTexture(0, 0, 0, 1)

	self.Fill:Show()

	self:SetSize(80, 80)

	self.Fill.AlphaPulse = self.Fill:CreateAnimationGroup()

	self.Fill.AlphaPulse.AlphaDown = self.Fill.AlphaPulse:CreateAnimation("ALPHA")
	self.Fill.AlphaPulse.AlphaDown:SetChange(-1)
	self.Fill.AlphaPulse.AlphaDown:SetDuration(0.5)
	self.Fill.AlphaPulse.AlphaDown:SetSmoothing("IN")
	self.Fill.AlphaPulse.AlphaDown:SetOrder(1)

	self.Fill.AlphaPulse.AlphaUp = self.Fill.AlphaPulse:CreateAnimation("ALPHA")
	self.Fill.AlphaPulse.AlphaUp:SetChange(1)
	self.Fill.AlphaPulse.AlphaUp:SetDuration(0.5)
	self.Fill.AlphaPulse.AlphaUp:SetSmoothing("OUT")
	self.Fill.AlphaPulse.AlphaUp:SetOrder(2)
	self.Fill.AlphaPulse:SetLooping("REPEAT")

	self.BorderGlowTexture.AlphaPulse = self.BorderGlowTexture:CreateAnimationGroup()

	self.BorderGlowTexture.AlphaPulse.AlphaDown = self.BorderGlowTexture.AlphaPulse:CreateAnimation("ALPHA")
	self.BorderGlowTexture.AlphaPulse.AlphaDown:SetChange(-1)
	self.BorderGlowTexture.AlphaPulse.AlphaDown:SetDuration(0.5)
	self.BorderGlowTexture.AlphaPulse.AlphaDown:SetSmoothing("IN")
	self.BorderGlowTexture.AlphaPulse.AlphaDown:SetOrder(1)

	self.BorderGlowTexture.AlphaPulse.AlphaUp = self.BorderGlowTexture.AlphaPulse:CreateAnimation("ALPHA")
	self.BorderGlowTexture.AlphaPulse.AlphaUp:SetChange(1)
	self.BorderGlowTexture.AlphaPulse.AlphaUp:SetDuration(0.5)
	self.BorderGlowTexture.AlphaPulse.AlphaUp:SetSmoothing("OUT")
	self.BorderGlowTexture.AlphaPulse.AlphaUp:SetOrder(2)
	self.BorderGlowTexture.AlphaPulse:SetLooping("REPEAT")

	self.BorderGlowTexture.AlphaPulse:Play()
end

function CoAResourceSegmentMixinTemplar:OnUpdate(elapsed)
	local diff = LOCAL_AURA_DURATION - GetTime()

	if (diff <= 5) and (diff > 0) and not self.Fill.AlphaPulse:IsPlaying() then
		self.Fill.AlphaPulse:Play()
	elseif self.Fill.AlphaPulse:IsPlaying() then
		self.Fill.AlphaPulse:Stop()
	end
end

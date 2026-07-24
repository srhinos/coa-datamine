if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "SPIRITMAGE" then return end

local sigilTemplates = {
	[500282] = {
		["LEFT"] = "Interface\\SpellActivationOverlay\\arcanesigil_left",
		["TOP"] = "Interface\\SpellActivationOverlay\\ArcaneSigil_top",
	}, -- arcane sigil

	[500271] = {
		["LEFT"] = "Interface\\SpellActivationOverlay\\fireSigil_left",
		["TOP"] = "Interface\\SpellActivationOverlay\\firesigil_top",
	}, -- fire sigil

	[500285] = {
		["LEFT"] = "Interface\\SpellActivationOverlay\\frostSigil_left",
		["TOP"] = "Interface\\SpellActivationOverlay\\frostSigil_top",
	}, -- frost sigil
}

local function DefineSigilTexture(sigil, position)
	if position ~= "TOP" then -- use left texture for fliped right
		position = "LEFT"
	end

	return sigilTemplates[sigil][position]
end

--
-- Controller
--
ClassMixinRuneMaster = {}

function ClassMixinRuneMaster:OnLoad()
	--Mixin(CoAResourceSegmentBar, CoAResourceSegmentBarMixinRuneMaster)
	--CoAResourceSegmentBar:ShowTemplate("SpiritCrystals", 0, 4, 800305)
end

function ClassMixinRuneMaster:OnPlayerAura()
	--local stacks = select(4, AuraUtil.GetBuff("player", 800305, true, AuraUtil.Predicate.MatchesSpellID))
	--CoAResourceSegmentBar:SetValue(stacks or 0)

	if CoASpellActivationOverlay and CoASpellActivationOverlay.listening then
		for spellID, _ in pairs(sigilTemplates) do
			local sigilStacks = select(4, AuraUtil.GetBuff("player", spellID, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			local sigilDiff = sigilStacks - CoASpellActivationOverlay:GetTotalShownLocations(spellID)

			if sigilDiff > 0 then
				for i = 1, sigilDiff do
					local location = CoASpellActivationOverlay:GetNextFreeClockwisePosition()

					if location == "RIGHT" then
						location = "RIGHT(FLIPPED)"
					end

					if location then
						CoASpellActivationOverlay:SPELL_ACTIVATION_SHOW(spellID, DefineSigilTexture(spellID, location), location, 1, 255, 255, 255)
					end
				end
			elseif sigilDiff < 0 then
				CoASpellActivationOverlay:HideNextCounterClockwise(spellID, math.abs(sigilDiff))
			end
		end
	end
end

--
-- CoAResourceSegmentBar
--
CoAResourceSegmentBarMixinRuneMaster = {}

function CoAResourceSegmentBarMixinRuneMaster:Update()
	CoAResourceSegmentBarMixin.Update(self)

	local x_spacing = 20.8

	self:SetHeight(48)
	self:SetWidth(182)

	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]

			if i == 1 then
				segment:ClearAndSetPoint("CENTER", -(self.maxValue-1)*(self.template.ElementSize/2)-(x_spacing/2), 4)
			elseif (i-1) == (self.maxValue/2) then
				segment:ClearAndSetPoint("LEFT", self.segments[i-1], "RIGHT", x_spacing, 0)
			else
				segment:ClearAndSetPoint("LEFT", self.segments[i-1], "RIGHT", 0, 0)
			end
		end
	end
end
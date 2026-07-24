if not IsCustomClass() then return end

local class = C_Player:GetClass()

local ClassMixin = {
	minLevel = 1
}

if class == "CULTIST" then
	ClassMixin.minLevel = 1

	function ClassMixin:OnLoad()
		MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinCultist)
		CoAResourceOrb:ClearAllPoints()
		CoAResourceOrb:SetPoint("TOP", CoAResourceSegmentBar, "BOTTOM", 0, -6)
		CoAResourceOrb:RestorePosition()
		CoAResourceOrb:Show()
		--CoAResourceSegmentBar:ShowTemplate("DoomVoid", 0, 6, 800431)
	end

	function ClassMixin:OnPlayerAura()
		local stacks = select(4, AuraUtil.GetDebuff("player", 500706, true, AuraUtil.Predicate.MatchesSpellID))

		local max = 100 --GetSpellMaxStack(500706)
		local value = math.min(100, stacks or 0)
		--local pct = (value*100)/max
		CoAResourceOrb:SetProgress(value, value, max)

		stacks = select(4, AuraUtil.GetBuff("player", 800431, true, AuraUtil.Predicate.MatchesSpellID))
		--CoAResourceSegmentBar:SetValue(stacks or 0)
	end

elseif class == "FLESHWARDEN" then -- Knight of Xoroth
	function ClassMixin:OnLoad()
		local maxOrbs = 6
		CoAResourceSegmentBar:ShowTemplate("FleshOrbs", 0, maxOrbs, 500906)
		CoAResourceSegmentBar:ClearAllPoints()
		CoAResourceSegmentBar:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 86, -4)
		CoAResourceSegmentBar:RestorePosition()
	end

	function ClassMixin:OnPlayerAura()
		local stacks = select(4, AuraUtil.GetBuff("player", 500906, true, AuraUtil.Predicate.MatchesSpellID))
		CoAResourceSegmentBar:SetValue(stacks or 0)

		--[[if C_Player:GetLevel() >= 25 then
			CoAResourceSegmentBar:SetMaxValue(6)
		else
			CoAResourceSegmentBar:SetMaxValue(4)
		end]]--
	end
	
elseif class == "PYROMANCER" then
	local PyromancerResourceBarMixin = {}

	function PyromancerResourceBarMixin:LoadAtlas()
		self.Background:SetAtlas("PyroHeatFlipbook")
		AtlasFlipbookMixin.SetCoordInsets(self.Background)
		AtlasFlipbookMixin.SetAtlas(self.Background, "PyroHeatFlipbook")
		AtlasFlipbookMixin.SetFrameSize(self.Background, 512, 128)
		AtlasFlipbookMixin.Initialize(self.Background)
		self.Text:SetPoint("CENTER", 0, -2)
	end
		
	function PyromancerResourceBarMixin:ShowTemplate(template, value, maxValue)
		maxValue = maxValue or 0
		self:SetMinMaxValues(0, maxValue)
		self:SetValue(value)
		--self:SetTemplate(template)
		self:SetStatusBarColor(0, 0, 0, 0)
		self:Show()
		self.init = true
	end

	function PyromancerResourceBarMixin:Update()
		local pct = self:GetValue() / select(2, self:GetMinMaxValues())
		pct = math.min( math.clamp(pct, 0, 1) * 100, 100)

		local frameNum = math.ceil(pct*64/100)


		if frameNum == 0 then
			frameNum = 1
		end

		self.Text:SetText(format(self.defaultFormat, pct))

		if self.Background.Rows then
			AtlasVerticalFlipbookMixin.SetFrame(self.Background, frameNum)
		end
	end 

	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		local embersDeBuff = 807533
		local heatDeBuff = 807389

		if not CoAResourceSegmentBar:IsShown() then
			CoAResourceSegmentBar:ShowTemplate("PyroEmber", 0, GetSpellMaxStack(embersDeBuff))
			CoAResourceSegmentBar:ClearAllPoints()
			CoAResourceSegmentBar:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 86, 32)
			CoAResourceSegmentBar:RestorePosition()
		end

		if not CoAResourceBar:IsShown() then
			if not CoAResourceBar.init then
				MixinAndLoadScripts(CoAResourceBar, PyromancerResourceBarMixin)
				CoAResourceBar:LoadAtlas()
			end

			--CoAResourceBar:ShowTemplate("PyroHeat", 0, GetSpellMaxStack(heatDeBuff))
			CoAResourceBar:ShowTemplate("PyroHeat", 0, 100) -- heatDeBuff can go over 100
			CoAResourceBar:ClearAllPoints()
			CoAResourceBar:SetPoint("TOP", CoAResourceSegmentBar, "BOTTOM", 0, -6)
			CoAResourceBar:RestorePosition()
		end

		local stacks = select(4, AuraUtil.GetDebuff("player", heatDeBuff, true, AuraUtil.Predicate.MatchesSpellID))
		CoAResourceBar:SetValue(stacks or 0)

		local stacks = select(4, AuraUtil.GetDebuff("player", embersDeBuff, true, AuraUtil.Predicate.MatchesSpellID))
		CoAResourceSegmentBar:SetValue(stacks or 0)
	end

elseif class == "RANGER" then
	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
        if IsSpellIDKnown(802036) then
            if not CoAResourceSegmentBar:IsShown() then
                CoAResourceSegmentBar:ShowTemplate("RangerCombo", 0, 5, 804329)
            end

            local stacks = select(4, AuraUtil.GetBuff("player", 804329, true, AuraUtil.Predicate.MatchesSpellID))
            CoAResourceSegmentBar:SetValue(stacks or 0)
        else
            CoAResourceSegmentBar:HideTemplate("RangerCombo")
        end
	end
elseif class == "TINKER" then
	ClassMixin.minLevel = 10
	Mixin(ClassMixin, ClassMixinTinker)
elseif class == "REAPER" then
	ClassMixin.minLevel = 1
	Mixin(ClassMixin, ClassMixinReaper)
elseif class == "SPIRITMAGE" then
	Mixin(ClassMixin, ClassMixinRuneMaster)
elseif class == "STORMBRINGER" then
	ClassMixin.minLevel = 1
	Mixin(ClassMixin, ClassMixinStormbringer)
elseif class == "NECROMANCER" then
	ClassMixin.minLevel = 1
	local lifeForceVisualSpellID = 525004
	local lifeForceSpellID = 805011

	function ClassMixin:OnPlayerAura()
		local visualMax = (GetSpellMaxStack and GetSpellMaxStack(lifeForceVisualSpellID)) or 0
		local coreMax = (GetSpellMaxStack and GetSpellMaxStack(lifeForceSpellID)) or 0
		local maxStacks = math.max(visualMax, coreMax, 1)

		-- Life Force visuals can be provided as either a helpful or harmful aura depending on spell data flags,
		-- so check both to avoid silently reading 0 stacks.
		local stacks = select(4, AuraUtil.GetBuff("player", lifeForceVisualSpellID, true, AuraUtil.Predicate.MatchesSpellID))
			or select(4, AuraUtil.GetDebuff("player", lifeForceVisualSpellID, true, AuraUtil.Predicate.MatchesSpellID))
			or 0

		-- Keep UI in sync with the actual stack amount; do not force +1.
		if stacks > maxStacks then
			maxStacks = stacks
		end
		local displayStacks = math.min(maxStacks, math.max(0, stacks))

		CoAMultiCastActionBarFrame:SetNumButtons(maxStacks)
		CoAMultiCastActionBarFrame:UpdateResource(displayStacks, maxStacks)
		CoAMultiCastActionBarFrame:UPDATE_MULTI_CAST_ACTIONBAR()
	end

	function ClassMixin:OnLoad()
		MixinAndLoadScripts(CoAMultiCastActionBarFrame, CoANecromancerMultiCastMixin)
		CoAMultiCastActionBarFrame:SetSpells(NECROMANCER_SUMMON_SPELLS)
		CoAMultiCastActionBarFrame:SetDefaultTexture("Interface\\Icons\\inv_necro_life_force_empty")
		CoAMultiCastActionBarFrame:RestorePosition()
		self:OnPlayerAura()
	end
elseif class == "DEMONHUNTER" then
	local buff = 800058

	function ClassMixin:OnLoad()
		CoAResourceSegmentBar:ShowTemplate("DHCharges", 0, GetSpellMaxStack(buff), buff)
		CoAResourceSegmentBar:ClearAllPoints()
		CoAResourceSegmentBar:SetPoint("TOP", PlayerFrame, "BOTTOMLEFT", 131, -4)
		CoAResourceSegmentBar:RestorePosition()
	end

	function ClassMixin:OnPlayerAura()
		local stacks = select(4, AuraUtil.GetBuff("player", buff, true, AuraUtil.Predicate.MatchesSpellID))
		CoAResourceSegmentBar:SetMaxValue(GetSpellMaxStack(buff) or 4)
		CoAResourceSegmentBar:SetValue(stacks or 0)
	end
elseif class == "SONOFARUGAL" then
	ClassMixin.minLevel = 10

	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if C_CharacterAdvancement.IsKnownID(9905) then
			if not CoAResourceOrb:IsShown() then
				if not(CoAResourceOrb.init) then
					MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinWorgen)
				end

				CoAResourceOrb:SetWorgen()
				CoAResourceOrb:RestorePosition()
				CoAResourceOrb:Show()
			end

			local stacks = select(4, AuraUtil.GetDebuff("player", 680687, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			CoAResourceOrb:SetProgress(stacks*10, stacks, 10)
		elseif IsSpellKnown(92112) then -- TODO: Replace with proper check
			if not CoAResourceOrb:IsShown() then
				if not(CoAResourceOrb.init) then
					MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinWorgen)
				end

				CoAResourceOrb:SetThirst()
				CoAResourceOrb:RestorePosition()
				CoAResourceOrb:Show()
			end

			local stacks = select(4, AuraUtil.GetDebuff("player", 706613, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			CoAResourceOrb:SetProgress(stacks*10, stacks, 10)
		else
			CoAResourceOrb:Hide()
			return
		end
	end
elseif class == "SUNCLERIC" then
	ClassMixin.minLevel = 2
	
	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if not CoAResourceOrb.init then
			MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbSunCleric)
		end

		if not IsSpellIDKnown(804584) then
			CoAResourceOrb:Hide()
			return
		end

		if not CoAResourceOrb:IsShown() then
			CoAResourceOrb:ClearAllPoints()
			CoAResourceOrb:SetPoint("TOP", CoAResourceSegmentBar, "BOTTOM", 0, -6)
			CoAResourceOrb:RestorePosition()
			CoAResourceOrb:Show()
		end

		local stacks = select(4, AuraUtil.GetBuff("player", 500149, true, AuraUtil.Predicate.MatchesSpellID)) or 0
		local sunsetStacks = select(4, AuraUtil.GetDebuff("player", 804584, true, AuraUtil.Predicate.MatchesSpellID)) or 0

		if sunsetStacks and (sunsetStacks ~= 0) then
			CoAResourceOrb:SetSunset(true)
			local max = C_CharacterAdvancement.GetTalentRankByID(29182)
			CoAResourceOrb:SetProgress(sunsetStacks, sunsetStacks, 5+max) -- TODO: Properly define max sunset
		else
			CoAResourceOrb:SetSunset(false)
			CoAResourceOrb:SetProgress(stacks, stacks, GetSpellMaxStack(500149))
		end
	end
elseif class == "BARBARIAN" then
	ClassMixin.minLevel = 10

	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if IsSpellIDKnown(92083) then
			if not CoAResourceOrb:IsShown() then
				if not(CoAResourceOrb.init) then
					MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinBarbarian)
				end
				CoAResourceOrb:RestorePosition()
				CoAResourceOrb:Show()
			end

			local stacks = select(4, AuraUtil.GetBuff("player", 805813, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			CoAResourceOrb:SetProgress(stacks*10, stacks, 10)
		else
			CoAResourceOrb:Hide()
			return
		end
	end
elseif class == "WILDWALKER" then
	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if not CoAResourceOrb.init then
			MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinPrimalist)
		end

		if C_CharacterAdvancement.IsKnownID(4059) then
			if not CoAResourceOrb:IsShown() then
				CoAResourceOrb:RestorePosition()
			end
			CoAResourceOrb:Show()
			local stacks = select(4, AuraUtil.GetBuff("player", 680441, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			CoAResourceOrb:SetProgress(stacks, stacks, 15)
		else
			CoAResourceOrb:Hide()
			return
		end
	end
elseif class == "PROPHET" then 
	local buff = 804972

	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if C_CharacterAdvancement.IsKnownID(4053) then
			if not CoAResourceSegmentBar:IsShown() then
				CoAResourceSegmentBar:ShowTemplate("Venomancer", 0, GetSpellMaxStack(buff), buff)
			end
		else
			CoAResourceSegmentBar:HideTemplate("Venomancer")
			return
		end
		local stacks = select(4, AuraUtil.GetBuff("player", buff, true, AuraUtil.Predicate.MatchesSpellID))

		if stacks then
			CoAResourceSegmentBar:SetValue(stacks)
		else
			CoAResourceSegmentBar:ShowTemplate("Venomancer", 0, GetSpellMaxStack(buff))
		end
	end
elseif class == "STARCALLER" then
	function ClassMixin:OnLoad()
		self:OnPlayerAura()
	end

	function ClassMixin:OnPlayerAura()
		if not CoAResourceOrb.init then
			MixinAndLoadScripts(CoAResourceOrb, CoAResourceOrbMixinStarcaller)
		end

		local hasLunarEclipse = IsSpellIDKnown(800386)
		local hasLunarPhasePassive = IsSpellIDKnown(524781)

		if hasLunarEclipse or hasLunarPhasePassive then
			if not CoAResourceOrb:IsShown() then
				CoAResourceOrb:RestorePosition()
			end
			CoAResourceOrb:Show()
			local stacks = select(4, AuraUtil.GetBuff("player", 802985, true, AuraUtil.Predicate.MatchesSpellID)) or 0
			local maxStacks = GetSpellMaxStack(802985) or 4

			--[[if C_CharacterAdvancement.IsKnownID(29662) then
				local currentRank, maxRanks = C_CharacterAdvancement.GetTalentRankByID(29662)
				maxStacks = maxStacks + currentRank*2
			end]]--
			
			CoAResourceOrb:SetProgress(stacks, stacks, maxStacks)
		else
			CoAResourceOrb:Hide()
			return
		end
	end
end

local EventHandler = {
	Mixin = ClassMixin
}

function EventHandler:UNIT_AURA(unit)
	if unit == "player" then
		if self.Mixin and self.Mixin.OnPlayerAura then
			self.Mixin:OnPlayerAura()
		end
	elseif unit == "target" then
		if self.Mixin and self.Mixin.OnTargetAura then
			self.Mixin:OnTargetAura()
		end
	end
end

function EventHandler:RefreshPlayerResources()
	if self.Mixin and self.Mixin.OnPlayerAura then
		self.Mixin:OnPlayerAura()
	end
end

function EventHandler:ASCENSION_SPELLS_UPDATED()
    self:RefreshPlayerResources()
end

function EventHandler:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
	self:RefreshPlayerResources()
end

function EventHandler:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
	self:RefreshPlayerResources()
end

function EventHandler:PLAYER_SPECIALIZATION_CHANGED()
	self:RefreshPlayerResources()
end

function EventHandler:ASCENSION_HIDDEN_SPELL_LEARNED()
	self:RefreshPlayerResources()
end

function EventHandler:ASCENSION_HIDDEN_SPELL_UNLEARNED()
	self:RefreshPlayerResources()
end

function EventHandler:PLAYER_TARGET_CHANGED()
	if self.Mixin and self.Mixin.OnTargetAura then
		self.Mixin:OnTargetAura()
	end
end

function EventHandler:PLAYER_LEVEL_UP(level)
	if not self.Mixin or not self.Mixin.minLevel then
		return
	end

	if level >= self.Mixin.minLevel then
		if self.Mixin.OnLoad then
			self.Mixin:OnLoad()
		end
		C_Hook:Unregister(self, "PLAYER_LEVEL_UP")
	end
end

function EventHandler:PLAYER_ENTERING_WORLD()
	if self.Mixin and self.Mixin.OnLoad then
		if self.Mixin.minLevel and C_Player:GetLevel() >= self.Mixin.minLevel then
			self.Mixin:OnLoad()
		else
			C_Hook:Register(self, "PLAYER_LEVEL_UP")
		end
	end
	
	C_Hook:Unregister(self, "PLAYER_ENTERING_WORLD")
end

C_Hook:Register(EventHandler, "UNIT_AURA, PLAYER_TARGET_CHANGED, PLAYER_ENTERING_WORLD, CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED, ASCENSION_SPELLS_UPDATED")
C_Hook:RegisterBucket(EventHandler, {"SPELLS_CHANGED", "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "ASCENSION_HIDDEN_SPELL_LEARNED", "ASCENSION_HIDDEN_SPELL_UNLEARNED"}, 0.1, "RefreshPlayerResources")

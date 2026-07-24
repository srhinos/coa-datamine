if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "TINKER" then return end

local AMMO_SPELL_ID = 500238
local SCRAP_CA_ENTRY_ID = 4051
local SCRAP_SPELL_ID = 801816

--
-- Controller
--
local TinkerResourceSegmentBarMixin = {}

function TinkerResourceSegmentBarMixin:SetValue(value)
	self.exactValue = value
	self.value = math.floor((value or 0)/10)
	self:Update()
end

function TinkerResourceSegmentBarMixin:OnLoad()
	self.defaultFormat = "%d%%"
	self.cvarLocked = "coaResourceBarLocked"
	self.cvarSize = "coaResourceBarSize"
	self.cvarShowText = "coaResourceBarShowText"
	self:LoadCVars()

	self.DropDown.initialize = CoAResourceMixin.InitializeDropDown
	self.DropDown.displayMode = "MENU"

	self.Text:SetPoint("CENTER", 0, -14)
end

function TinkerResourceSegmentBarMixin:ON_CVARS_LOADED()
	CoAResourceBarMixin.ON_CVARS_LOADED(self)
end

function TinkerResourceSegmentBarMixin:SetShowText(show)
	CoAResourceBarMixin.SetShowText(self, show)
end

function TinkerResourceSegmentBarMixin:Update()
	CoAResourceSegmentBarMixin.Update(self)

	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]

			if i == 1 then
				local elementSize = self.template.ElementSize or 5
				segment:ClearAndSetPoint("CENTER", -((elementSize/2)+1)*(self.maxValue-1), -13)
			end

			if i <= self.value then
				segment.Background:Show()
				segment.Background:SetAtlas("ScrapFill10")
			elseif i == (self.value+1) then
				local diff = (self.exactValue or 0)-(self.value*10)

				if diff and (diff > 0) and AtlasUtil:AtlasExists("ScrapFill"..diff) then
					segment.Background:Show()
					segment.Background:SetAtlas("ScrapFill"..diff)
				else
					segment.Background:Hide()
				end
			else
				segment.Background:Hide()
			end
		end
	end

	self.segments[self.maxValue]:SetFrameLevel(self:GetFrameLevel()+10)
	self.Text:SetParent(self.segments[self.maxValue])
	self.Text:SetText(format(self.defaultFormat, (self.exactValue or 0)))
end
--
-- Controller
--
ClassMixinTinker = {}

function ClassMixinTinker:OnLoad()
	self:OnPlayerAura()
end

function ClassMixinTinker:OnPlayerAura()
	if C_CharacterAdvancement.IsKnownID(SCRAP_CA_ENTRY_ID) then
		if not CoAResourceSegmentBar:IsVisible() then

			if not CoAResourceSegmentBar.init then
				MixinAndLoadScripts(CoAResourceSegmentBar, TinkerResourceSegmentBarMixin)
				CoAResourceSegmentBar.init = true
			end

			CoAResourceSegmentBar:ShowTemplate("TinkerScrap", 0, GetSpellMaxStack(SCRAP_SPELL_ID)/10)
		end

		local scrapStacks = select(4, AuraUtil.GetBuff("player", SCRAP_SPELL_ID, true, AuraUtil.Predicate.MatchesSpellID))

		CoAResourceSegmentBar:SetValue(scrapStacks)
	else
		CoAResourceSegmentBar:Hide()
	end
end
-- TODO: To globalstrings
WC_RAPID_ROLL_DESIRED = WC_RAPID_ROLL_DESIRED or "|cffFFFFFFDesired|r"
-------------------------------------------------------------------------------
--                                Name Object                                --
-------------------------------------------------------------------------------
WildCardNameFrameButtonMixin = {}

function WildCardNameFrameButtonMixin:OnLoad()
	self:Layout()
end

function WildCardNameFrameButtonMixin:SetInternalID(internalID, rank, isDesired)
	if not(rank) or (rank == 0) then
		dprint("WildCardNameFrameButtonMixin: Recieved nil or 0 rank")
		rank = 1
	end

	if not(internalID) or (internalID == 0) then
		dprint("WildCardNameFrameButtonMixin: Recieved nil or 0 internalID")
		internalID = 1
	end

	local spellID = CharacterAdvancementUtil.GetTalentRankSpellByID(internalID, rank) or 1
	spellID = (spellID ~= 0) and spellID or 1
	
	local name = GetSpellInfo(spellID)

	if C_CharacterAdvancement.IsTalentAbilitySpellID(spellID) then
	elseif C_CharacterAdvancement.IsTalentSpellID(spellID) then
		if isDesired then
			self.SubText:SetText(WILDCARD_DESIRED_TALENT_UNLOCKED)
		else
			self.SubText:SetText(WILDCARD_TALENT_UNLOCKED)
		end
	else
		if isDesired then
			self.SubText:SetText(WILDCARD_DESIRED_ABILITY_UNLOCKED)
		else
			self.SubText:SetText(WILDCARD_ABILITY_UNLOCKED)
		end
	end

	if C_CharacterAdvancement.IsTalentAbilitySpellID(spellID) or C_CharacterAdvancement.IsTalentSpellID(spellID) then
		self.Text:SetText((name or "").." ("..RANK.." "..rank..")")
	else
		self.Text:SetText(name or "")
	end
end

function WildCardNameFrameButtonMixin:Layout()
	--self:SetBackdrop(GameTooltip:GetBackdrop())
	self:SetSize(192, 42)

	self.Text = self:CreateFontString(nil, "OVERLAY")
	self.Text:SetFontObject(GameFontDisableLarge)
	self.Text:SetVertexColor(1, 1, 1, 1)
	self.Text:SetJustifyH("CENTER")
	self.Text:SetJustifyV("TOP")
	self.Text:SetWidth(350)
	self.Text:SetText("Spell Name Example")
	self.Text:SetPoint("CENTER", 0, (self.Text:GetHeight()/2)+2)

	self.SubText = self:CreateFontString(nil, "OVERLAY")
	self.SubText:SetFontObject(GameFontNormal)
	self.SubText:SetPoint("TOP", self.Text, "BOTTOM", 0, -4)
	self.SubText:SetWidth(256)
	self.SubText:SetJustifyH("TOP")
	self.SubText:SetJustifyV("CENTER")
	self.SubText:SetText("Ability Revealed!")
end

-------------------------------------------------------------------------------
--                                Name frame                                 --
-------------------------------------------------------------------------------
WildCardNameFrameMixin = CreateFromMixins(CallbackRegistryMixin)

function WildCardNameFrameMixin:OnLoad()
	self.disappearAfter = 5

	self:Layout()
	self.spellCollection = CreateFramePoolCollection()

	CallbackRegistryMixin.OnLoad(self)

	self:GenerateCallbackEvents({
		"OnFinished",
	})
end

function WildCardNameFrameMixin:ReleaseAllButtons()
	self.buttonIDToButton = {}
	self.spellCollection:ReleaseAll()
end

function WildCardNameFrameMixin:AcquireButton()
	local pool, isNewPool = self.spellCollection:GetOrCreatePool("BUTTON", self, "WildCardSpellTextButton", nil)

	local button, isNew = pool:Acquire()

	return button
end

function WildCardNameFrameMixin:SetInternalID(internalID, rank, isDesired)
	self:ReleaseAllButtons()

	local button = self:AcquireButton()
	button:Show()
	button:SetInternalID(internalID, rank, isDesired)
	button:SetPoint("TOP", self.LineUp, "BOTTOM", 0, -16)
	self.buttonIDToButton[1] = button

	self.LineDown:SetPoint("TOP", self.buttonIDToButton[#self.buttonIDToButton].SubText, "BOTTOM", 0, -12)
end

function WildCardNameFrameMixin:FadeIn()
	BaseFrameFadeIn(self)
	self:Play()
end

function WildCardNameFrameMixin:IsPlaying()
	if self:GetScript("OnUpdate") then
		return true
	end

	return false
end

function WildCardNameFrameMixin:Play()
	self:SetScript("OnUpdate", self.OnUpdate)
	self.endDelay = self.disappearAfter
end

function WildCardNameFrameMixin:Pause()
	self:SetScript("OnUpdate", nil)
end

function WildCardNameFrameMixin:OnUpdate(elapsed)
	self.endDelay = self.endDelay - elapsed

	if (self.endDelay <= 0) then
		self:TriggerEvent("OnFinished")
		BaseFrameFadeOut(self)
		self:SetScript("OnUpdate", nil)
	end
end

function WildCardNameFrameMixin:Layout()
	self.LineUp = self:CreateTexture(nil, "BORDER", nil, 2)
	self.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.LineUp:SetSize(324, 7)
	self.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.LineUp:SetVertexColor(1, 1, 1)

	self.LineDown = self:CreateTexture(nil, "BORDER", nil, 2)
	self.LineDown:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.LineDown:SetSize(324, 7)
	self.LineDown:SetPoint("TOP", self.Button1, "BOTTOM", 0, -8)
	self.LineDown:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
	self.LineDown:SetVertexColor(1, 1, 1)

	self.Texture = self:CreateTexture(nil, "BACKGROUND", nil, 2)
	self.Texture:SetTexture("Interface\\LevelUp\\LevelUpTex")
	self.Texture:SetSize(354, 115)
	self.Texture:SetPoint("BOTTOM", self.LineDown, "TOP", 0, -6)
	self.Texture:SetPoint("TOP", self.LineUp, "BOTTOM", 0, -6)
	self.Texture:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
	self.Texture:SetVertexColor(1, 1, 1, 0.6)
end
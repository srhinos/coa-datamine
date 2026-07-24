DraftActionContainerMixin = {}

function DraftActionContainerMixin:SetupActions()
	if C_CharacterAdvancement.GetLearnedAE() < 8 or C_Player:GetLevel() < 10 then
		self.Button1:Show()
		self.Button1:SetAction(DraftActionButtonMixin.Action.FullDraft)

		if C_VanityCollection.IsCollectionItemOwned(ItemData.DEALERS_DRAFT_DECK) then
			self.Button1:SetPointOffset(106, 0)
			self.Button2:Show()
			self.Button2:SetAction(DraftActionButtonMixin.Action.Redraft)
			self.Button2:SetPointOffset(-106, 0)
		else
			self.Button1:ResetPointsOffset()
			self.Button2:Hide()
		end
		self:Show()
	else
		self:ClearActions()
	end
end

function DraftActionContainerMixin:ClearActions()
	self.Button1:Hide()
	self.Button2:Hide()
	self:Hide()
end

DraftActionButtonMixin = {}

DraftActionButtonMixin.Action = {
	FullDraft = 1,
	Redraft = 2,
}

function DraftActionButtonMixin:OnLoad()
	self.Art:SetAtlas("draft-header-extra-button-art", Const.TextureKit.UseAtlasSize)
end

function DraftActionButtonMixin:OnEnable()
	self.Icon:SetDesaturated(false)
	self.Art:SetDesaturated(false)
	self.Name:SetFontObject(GameFontNormal)
end

function DraftActionButtonMixin:OnDisable()
	self.Icon:SetDesaturated(true)
	self.Art:SetDesaturated(true)
	self.Name:SetFontObject(GameFontDisable)
end

function DraftActionButtonMixin:SetAction(action)
	self.action = action
	if action == DraftActionButtonMixin.Action.FullDraft then
		self.Icon:SetTexture("Interface\\Icons\\misc_draftmode")
		self.Name:SetText(DRAFT_SPELL_DRAFT_DECK)
		self.Description:SetText(DRAFT_SPELL_DRAFT_DECK_DESCRIPTION)
	elseif action == DraftActionButtonMixin.Action.Redraft then
		self.Icon:SetTexture("Interface\\Icons\\inv_inscription_80_deck_blockades")
		self.Name:SetText(DRAFT_DEALERS_DRAFT_DECK)
		self.Description:SetText(DRAFT_DEALERS_DRAFT_DECK_DESCRIPTION)
	end
end

function DraftActionButtonMixin:TriggerCooldown(value)
	if value <= 0 then return end
	self.CooldownStart = GetTime()
	self.CooldownDuration = value
end

function DraftActionButtonMixin:ClearCooldown()
	self.CooldownStart = nil
	self.CooldownDuration = nil
end

function DraftActionButtonMixin:GetCooldown()
	local hasCooldown = self.CooldownStart ~= nil and GetTime() < self.CooldownStart + self.CooldownDuration
	if hasCooldown then
		return self.CooldownStart, self.CooldownDuration, hasCooldown and 1 or 0
	else
		self:ClearCooldown()
		return 0, 0, 0
	end
end

function DraftActionButtonMixin:OnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed < 0.1 then return end

	local count

	local actionType = self:GetAttribute("type")
	local start, duration, enable = self:GetCooldown(actionType)
	self:SetEnabled(enable == 0)
	if start and start > 0 and duration and duration > 0 and enable and enable > 0 then
		self.Cooldown:SetCooldown(start, duration)
		local timeLeft = (start + duration) - GetTime()
		self.Cooldown.Text:SetText(format(SecondsToTimeAbbrevPrecise(timeLeft)))
		self.Cooldown:Show()
	else
		self.Cooldown:Hide()
	end

	self:SetChecked(false)

	self.elapsed = 0
end

-- @Kalethuzad: TODO: draft skip isn't meant to be called for both of these actions
function DraftActionButtonMixin:OnClick()
	self:TriggerCooldown(1)
	if self.action == DraftActionButtonMixin.Action.FullDraft then
		RedraftAbilities()
	elseif self.action == DraftActionButtonMixin.Action.Redraft then
		SendDraftSkip()
	end
end 

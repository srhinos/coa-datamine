RealmMerge = {}

local function ResetMergeChoice(pool, button)
	button:ClearAllPoints()
	button:Hide()
end

RealmMerge.Pool = CreateFramePool("Button", GlueParent, "RealmMergeChoiceTemplate", ResetMergeChoice)

function RealmMerge.ShowChoiceDialog()
	local choices = C_RealmMerge.GetAvailableOptions()
	local numChoices = #choices
	if numChoices == 0 then
		return
	end
	
	for index, realm in ipairs(choices) do
		local choice = RealmMerge.Pool:Acquire()
		local x = 0

		if numChoices > 1 then
			x = (index - 1) * 304 - (numChoices - 1) * 152
		end
		choice:SetPoint("BOTTOM", x, 80)
		choice:Show()
		if index % 2 == 0 then
			choice.NineSlice:SetBorderColor(ASCENSION_PRIMARY_COLOR:GetRGBA())
		else
			choice.NineSlice:SetBorderColor(ASCENSION_SECONDARY_COLOR:GetRGBA())
		end
		choice:SetRealm(realm)
	end
	RealmMergeFrame:Show()
	PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_TOAST_TRAITAVAILABLE)
end

function RealmMerge.HideChoiceDialog()
	RealmMerge.Pool:ReleaseAll()
	RealmMergeFrame:Hide()
end

function RealmMerge.HideChangeTarget()
	RealmMergeChangeChoiceFrame:Hide()
end

function RealmMerge.ShowChangeTarget()
	local targetRealm = C_RealmMerge.GetTargetRealm()
	if targetRealm and targetRealm ~= "None" then
		local choiceFrame = RealmMergeChangeChoiceFrame
		choiceFrame:Show()
		GlueFrameFadeIn(choiceFrame, 0.5)
		local name, _, _, image = C_RealmSelect.GetRealmInfo(targetRealm)

		choiceFrame.Current:SetFormattedText(REALM_MERGE_AVAILABLE_CURRENT, name)
		if not choiceFrame.Background:SetTexture("Interface\\Glues\\RealmList\\"..image) then
			choiceFrame.Background:SetTexture("Interface\\Glues\\RealmList\\Default")
		end

		choiceFrame.Background:SetVertexColor(0.3, 0.3, 0.3, 1)
		local left, right, top, bottom = TextureUtil.GetCoverTexCoords(choiceFrame:GetSize())
		choiceFrame.Background:SetTexCoord(left, right, top, bottom)
		choiceFrame.Background:SetDollyStartCoords(left, right, top, bottom)
		choiceFrame.Background:SetDollyEndCoords(TextureUtil.ZoomTexCoords(0.02, left, right, top, bottom))

		choiceFrame.NineSlice:SetBorderColor(ASCENSION_SECONDARY_COLOR:GetRGBA())
	end
end

function RealmMerge.OnSelectTargetCallback(result)
	if result == "REALM_MERGE_SET_TARGET_REALM_OK" then
		if CharacterSelect:IsShown() then
			RealmMerge.ShowChangeTarget()
		end
		return
	end

	message(_G[result] or result)
end

function RealmMerge.CheckForRealmMerge()
	if not C_RealmMerge.IsMergeAvailable() then
		RealmMerge.HideChoiceDialog()
		RealmMerge.HideChangeTarget()
		return false
	else
		if C_RealmMerge.NeedsSetTargetRealm() then
			RealmMerge.ShowChoiceDialog()
		else
			RealmMerge.ShowChangeTarget()
		end

		return true
	end
end

C_Hook:Register("RealmMerge", "REALM_MERGE_SET_TARGET_RESULT", RealmMerge.OnSelectTargetCallback)
C_Hook:Register("RealmMerge", "CHARACTER_LIST_UPDATE", RealmMerge.CheckForRealmMerge)

--
-- Realm Merge Choice 
--
RealmMergeChoiceMixin = {}

function RealmMergeChoiceMixin:OnLoad()
	Mixin(self.Background, "TextureDollyMixin")
	self.Background:SetDollyTimeScale(0.5)
	self.Background:SetDollyFinishCallback(function()
		self:SetScript("OnUpdate", nil)
	end)
end

function RealmMergeChoiceMixin:OnShow()
	GlueFrameFadeIn(self, 0.5)
end

function RealmMergeChoiceMixin:OnHide()
	GlueFrameFadeRemoveFrame(self)
	self:SetAlpha(1)
end

function RealmMergeChoiceMixin:SetRealm(realm)
	self.realm = realm
	local name, expansionID, gamemodeID, image, _, _, _, descriptionSpell = C_RealmSelect.GetRealmInfo(realm)
	if not name then
		return
	end
	
	self:SetName(name)
	self:SetExpansion(expansionID)
	self:SetGameMode(gamemodeID)
	self:SetBackground(image)
	self:SetDescription(GetSpellDescription(descriptionSpell))
	self.SelectButton:SetEnabled(C_RealmMerge.GetTargetRealm() ~= realm)
end

function RealmMergeChoiceMixin:SetName(name)
	self.Name:SetText(name)
end

function RealmMergeChoiceMixin:SetExpansion(expansionID)
	local expansionText = EXPANSION_COLORS[expansionID]:WrapText(_G["EXPANSION"..expansionID])
	self.Expansion:SetText(EXPANSION_COLON, expansionText)

	if expansionID < 2 then
		self.Expansion.tooltipTitle = TOOLTIP_PROGRESSIVE_TITLE
		self.Expansion.tooltipText = TOOLTIP_PROGRESSIVE_TEXT
	end

	if AtlasUtil:AtlasExists("realm-expansion-icon-"..expansionID) then
		if AtlasUtil:AtlasExists("small-logo-expansion-"..expansionID) then
			self.Expansion:SetBadge("small-logo-expansion-"..expansionID, 0.55)
		end
		self.Expansion:SetBackground("realm-expansion-icon-"..expansionID)
	else
		self.Expansion:SetIcon("realm-expansion-icon-0")
	end
end

function RealmMergeChoiceMixin:SetGameMode(gamemodeID)
	self.GameMode:SetText(GAME_MODE_COLON, _G["GAMEMODE"..gamemodeID])

	self.GameMode.tooltipTitle = _G["TOOLTIP_GAMEMODE"..gamemodeID.."_TITLE"] or "TOOLTIP_GAMEMODE"..gamemodeID.."_TITLE"
	self.GameMode.tooltipText = _G["TOOLTIP_GAMEMODE"..gamemodeID.."_TEXT"] or "TOOLTIP_GAMEMODE"..gamemodeID.."_TEXT"

	if AtlasUtil:AtlasExists("realm-game-mode-"..gamemodeID) then
		self.GameMode:SetBackground("realm-game-mode-"..gamemodeID)
	else
		self.GameMode:SetIcon("realm-game-mode-icon")
	end
end

function RealmMergeChoiceMixin:SetBackground(image)
	if not self.Background:SetTexture("Interface\\Glues\\RealmList\\"..image) then
		self.Background:SetTexture("Interface\\Glues\\RealmList\\Default")
	end

	local r, g, b = 0.3, 0.3, 0.3
	self.Background:SetVertexColor(r, g, b, 1)
	local left, right, top, bottom = TextureUtil.GetCoverTexCoords(self:GetSize())
	self.Background:SetTexCoord(left, right, top, bottom)
	self.Background:SetDollyStartCoords(left, right, top, bottom)
	self.Background:SetDollyEndCoords(TextureUtil.ZoomTexCoords(0.02, left, right, top, bottom))
	self.Background:SetDollyStartColor(r, g, b)
	self.Background:SetDollyEndColor(r+0.2, g+0.2, b+0.3, 1)
end

function RealmMergeChoiceMixin:SetDescription(description)
	self.OverviewText:SetText(description)
end

function RealmMergeChoiceMixin:ChooseRealm()
	if not self.realm then return end
	if not C_RealmMerge.SetTargetRealm(self.realm) then
		message("Client failed to set target realm")
	end
	PlaySound(SOUNDKIT.UI_ORDERHALL_TALENT_SELECT)
	RealmMerge.HideChoiceDialog()
end

function RealmMergeChoiceMixin:OnEnter()
	if not self.Background:GetTexture() then return end
	self.Background:SetDollyTimeScale(0.5)
	self:SetScript("OnUpdate", function(self, elapsed)
		self.Background:MoveDollyForward(elapsed)
	end)
end

function RealmMergeChoiceMixin:OnLeave()
	if not self.Background:GetTexture() then return end
	self.Background:SetDollyTimeScale(1.2)
	self:SetScript("OnUpdate", function(self, elapsed)
		self.Background:MoveDollyBackward(elapsed)
	end)
end
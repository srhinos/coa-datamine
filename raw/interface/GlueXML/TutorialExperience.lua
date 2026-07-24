STARTING_EXPERIENCE_SELECT_TEXT = STARTING_EXPERIENCE_SELECT_TEXT or "Choose your starting experience"
STARTING_EXPERIENCE_NEW_TO_WOW = STARTING_EXPERIENCE_NEW_TO_WOW or "New to WoW"
STARTING_EXPERIENCE_NEW_TO_WOW_DESC = STARTING_EXPERIENCE_NEW_TO_WOW_DESC or "Enables game basics and custom systems tutorials"
STARTING_EXPERIENCE_VETERAN = STARTING_EXPERIENCE_VETERAN or "New to Ascension"
STARTING_EXPERIENCE_VETERAN_DESC = STARTING_EXPERIENCE_VETERAN_DESC or "Enables only the custom systems tutorials"
STARTING_EXPERIENCE_NO_TUT = STARTING_EXPERIENCE_NO_TUT or "Ascension Veteran"
STARTING_EXPERIENCE_NO_TUT_DESC = STARTING_EXPERIENCE_NO_TUT_DESC or "Disables all tutorials"

HelpTips["CHARACTER_CREATE_ENTER_WORLD_BUTTON"] = {
    text = "You can go to the next step",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    highlightTarget = HelpTip.TargetType.Box,
    --offsetX = -16,
}

TutorialExperienceEventListener = CreateFrame("FRAME")
TutorialExperienceEventListener:RegisterEvent("UPDATE_STATUS_DIALOG")

TutorialExperienceEventListener:SetScript("OnEvent", function(self, event, arg)
	if arg == CHAR_CREATE_SUCCESS and self.frame then
		self:Hide()
		self.frame:Initialize(function()
			if CharSelectEnterWorldButton and (CharSelectEnterWorldButton:IsEnabled()) then
				CharacterSelect_EnterWorld()
			end
		end)
	end
end)

--
-- round button mixin
--
ExperienceRoundIconMixin = {}

function ExperienceRoundIconMixin:OnLoad()
	self.NameFrame.ShadowText:SetAtlas("common-shadow-circle", Const.TextureKit.IgnoreAtlasSize)
	self.Background:SetAtlas("ExperienceIconBG", Const.TextureKit.IgnoreAtlasSize)
	self.Checked:SetAtlas("ExperienceIconChecked", Const.TextureKit.IgnoreAtlasSize)
	self.Highlight:SetAtlas("ExperienceIconHighlight", Const.TextureKit.IgnoreAtlasSize)

	self.NameFrame.Desc:SetPoint("TOP", self.NameFrame.Text, "BOTTOM", 0, -2)
	self.NameFrame.Desc:SetWidth(256)
	self.NameFrame.Desc:SetJustifyV("TOP")
end

function ExperienceRoundIconMixin:OnEnter()
	self.Highlight:Show()
	self.NameFrame.Text:SetFontObject(self.highlightFontObject or GameFontHighlightOutlineLarge)
end

function ExperienceRoundIconMixin:OnLeave()
	self.Highlight:Hide()
	self.NameFrame.Text:SetFontObject(self.normalFontObject or GameFontNormalOutlineLarge)
	GlueTooltip:Hide()
end

function ExperienceRoundIconMixin:UpdateText(title, subtitle)
	self.NameFrame.Text:SetText(title)
	self.NameFrame.Desc:SetText(subtitle)
end

function ExperienceRoundIconMixin:SetIconNormal(atlas)
	atlas = atlas or self.normalIconAtlas

	if AtlasUtil:AtlasExists(atlas) then
		self.Icon:SetAtlas(atlas, Const.TextureKit.IgnoreAtlasSize)
	end

	self.normalIconAtlas = atlas
end

function ExperienceRoundIconMixin:SetBasicIcon(texture)
	self.Icon:SetTexCoord(0, 1, 0, 1)
	self.Icon:SetTexture(texture)
end

function ExperienceRoundIconMixin:SetIconHighlighted(atlas)
	atlas = atlas or self.highlightIconAtlas

	if AtlasUtil:AtlasExists(atlas) then
		self.Icon:SetAtlas(atlas, Const.TextureKit.IgnoreAtlasSize)
	end
	
	self.highlightIconAtlas = atlas
end

function ExperienceRoundIconMixin:GetHighlightedIcon()
	return self.highlightIconAtlas
end

function ExperienceRoundIconMixin:OnDisable()
	self:OnLeave()
	self.NameFrame.Text:SetFontObject(self.highlightFontObject or GameFontHighlightOutlineLarge)
	self.Checked:Show()

	if self:GetHighlightedIcon() then
		self:SetIconHighlighted()
	end
end

function ExperienceRoundIconMixin:OnEnable()
	self.Checked:Hide()

	self:SetIconNormal()
end
--
-- "portal" mixin
--
TutorialExperienceButtonMixin = {}

function TutorialExperienceButtonMixin:Layout()
    self.Border:SetAtlas("ExperienceChoiceBorder", Const.TextureKit.IgnoreAtlasSize)

    self:GetCheckedTexture():ClearAndSetPoint("CENTER", 0, -10)
    self:GetCheckedTexture():SetSize(304.85, 580.22)
    self:GetHighlightTexture():ClearAndSetPoint("CENTER", 0, -10)
    self:GetHighlightTexture():SetSize(304.85, 580.22)

    self:GetCheckedTexture():SetAtlas("ExperienceChoiceChecked", Const.TextureKit.IgnoreAtlasSize)
    self:GetHighlightTexture():SetAtlas("ExperienceChoiceHighlight", Const.TextureKit.IgnoreAtlasSize)
end

function TutorialExperienceButtonMixin:OnLoad()
	self:Layout()

	SetParentArray(self, "experienceTabs")
	self.experienceLevel = 0

	self.PortalVFX:SetAtlas("ExperienceArtPortalVFXFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.PortalVFX, "ExperienceArtPortalVFXFlipBook", 512, 512, 64, 60, false)
	MixinAndLoad(self.PortalVFX, AtlasVerticalFlipbookMixin)

	self.PortalVFX:Init()
	self.PortalVFX.fps = 1/120

	self.PortalVFX.AnimOut:SetScript("OnFinished", function()
		self.PortalVFX:Hide()
	end)

	self.ArtOverlay.AnimOut:SetScript("OnFinished", function()
		self.ArtOverlay:Hide()
	end)
end

function TutorialExperienceButtonMixin:OnUpdateAtlas(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.PortalVFX, elapsed)

	if self.PortalVFX.frame > self.PortalVFX.frames then
		self.PortalVFX.frame = 1
	end
end

function TutorialExperienceButtonMixin:OnEnter()
	self.ArtOverlay.AnimIn:Stop()
	self.ArtOverlay.AnimOut:Play()

	self.Icon:OnEnter()
end

function TutorialExperienceButtonMixin:OnLeave()
	self.ArtOverlay.AnimOut:Stop()
	self.ArtOverlay:Show()
	self.ArtOverlay.AnimIn:Play()

	self.Icon:OnLeave()
end

function TutorialExperienceButtonMixin:OnDisable()
	self:OnEnter()

	self.PortalVFX:Show()
	self.PortalVFX.AnimIn:Play()

	self:SetScript("OnUpdate", self.OnUpdateAtlas)
	self.Icon:OnDisable()
end

function TutorialExperienceButtonMixin:OnEnable()
	if not self.ArtOverlay:IsVisible() then
		self:OnLeave()
	end

	if self.PortalVFX:IsVisible() then
		self.PortalVFX.AnimOut:Play()
	end

	self:SetScript("OnUpdate", nil)
	self.Icon:OnEnable()
end

function TutorialExperienceButtonMixin:OnClick()
	self:GetParent():SelectExperience(self:GetExperience())
	TutorialUtil.SetTutorialExperience(self:GetExperience())
end

function TutorialExperienceButtonMixin:SetExperience(level)
	self.experienceLevel = level

	if level == Enum.TutorialExperience.NewToWoW then
		self.Icon:SetIconHighlighted("ExperienceIconBeginnerHighlight")
		self.Icon:SetIconNormal("ExperienceIconBeginner")
		self.Background:SetAtlas("ExperienceArtBeginner", Const.TextureKit.IgnoreAtlasSize)
		self.Icon:UpdateText(STARTING_EXPERIENCE_NEW_TO_WOW, STARTING_EXPERIENCE_NEW_TO_WOW_DESC)
	elseif level == Enum.TutorialExperience.NewToAscension then
		self.Icon:SetIconHighlighted("ExperienceIconVeteranHighlight")
		self.Icon:SetIconNormal("ExperienceIconVeteran")
		self.Background:SetAtlas("ExperienceArtVeteran", Const.TextureKit.IgnoreAtlasSize)
		self.Icon:UpdateText(STARTING_EXPERIENCE_VETERAN, STARTING_EXPERIENCE_VETERAN_DESC)
	else
		self.Icon:SetIconHighlighted("ExperienceIconAscensionHighlight")
		self.Icon:SetIconNormal("ExperienceIconAscension")
		self.Background:SetAtlas("ExperienceArtAscension", Const.TextureKit.IgnoreAtlasSize)
		self.Icon:UpdateText(STARTING_EXPERIENCE_NO_TUT, STARTING_EXPERIENCE_NO_TUT_DESC)
	end
end

function TutorialExperienceButtonMixin:GetExperience()
	return self.experienceLevel
end

-- 
-- menu mixin
--
TutorialExperienceFrameMixin = CreateFromMixins(CallbackRegistryMixin)

function TutorialExperienceFrameMixin:Initialize(okScript)
	self:Show()
	GlueFrameFadeIn(self, 0.5)
	self.okScript = okScript
end

function TutorialExperienceFrameMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self.Experience1:SetExperience(Enum.TutorialExperience.NewToWoW)
	self.Experience2:SetExperience(Enum.TutorialExperience.NewToAscension)
	self.Experience3:SetExperience(Enum.TutorialExperience.NoTutorials)

	self.ArtworkFrame:SetFrameLevel(self.Experience3:GetFrameLevel()+1)
	self.OkayButton:SetFrameLevel(self.ArtworkFrame:GetFrameLevel()+1)

	self.OkayButton:SetScript("OnClick", GenerateClosure(self.OkButtonOnClick, self))
	self.OkayButton:SetScript("OnEnter", function() 
		HelpTip:Hide("CHARACTER_CREATE_ENTER_WORLD_BUTTON")
	end)

	TutorialExperienceEventListener.frame = self

	HelpTips["CHARACTER_CREATE_ENTER_WORLD_BUTTON"].parent = self.OkayButton

	self:GenerateCallbackEvents({ "OnIndexSelected"})
end

function TutorialExperienceFrameMixin:OkButtonOnClick()
	self:Hide()

	if self.okScript then 
		self.okScript()
	end
end

function TutorialExperienceFrameMixin:NextStep()
	if self.step == "LEVELSCALING" then
		self.step = "TMOG"

		GlueFrameFadeOut(self.LevelScalingSelect, 0.5, function() self.LevelScalingSelect:Hide() end)

		self.TransmogSelect:Show()
		GlueFrameFadeIn(self.TransmogSelect, 0.5, function() self.TransmogSelect:Show() end)
		self.Text:SetText(CHANGE_TRANSMOG_ANYTIME)
	elseif self.step == "TMOG" then
		self.step = "EXPERIENCE"

		GlueFrameFadeOut(self.TransmogSelect, 0.5, function() self.TransmogSelect:Hide() end)
		
		self.Text:SetText(STARTING_EXPERIENCE_SELECT_TEXT)
		self.ArtworkFrame:Show()
		self.Experience1:Show()
		self.Experience2:Show()
		self.Experience3:Show()
		self.OkayButton:Show()

		GlueFrameFadeIn(self.ArtworkFrame, 0.5)
		GlueFrameFadeIn(self.Experience1, 0.5)
		GlueFrameFadeIn(self.Experience2, 0.5)
		GlueFrameFadeIn(self.Experience3, 0.5)
		GlueFrameFadeIn(self.OkayButton, 0.5)

		if HelpTips["CHARACTER_CREATE_ENTER_WORLD_BUTTON"].parent then
			HelpTip:Show("CHARACTER_CREATE_ENTER_WORLD_BUTTON")
		end
	end

end

function TutorialExperienceFrameMixin:OnShow()
	if not TutorialUtil.HasPickedTutorialExperience() then
		print("auto-select new tutorial level")
		TutorialUtil.SetTutorialExperience(Enum.TutorialExperience.NewToWoW)
	end

	self.step = "LEVELSCALING"

	self:SelectExperience(TutorialUtil.GetTutorialExperience())

	self.Text:SetText(LEVEL_SCALING_TEXT)

	self.LevelScalingSelect:Show()
	self.TransmogSelect:Hide()
	self.ArtworkFrame:Hide()
	self.Experience1:Hide()
	self.Experience2:Hide()
	self.Experience3:Hide()
	self.OkayButton:Hide()
end

function TutorialExperienceFrameMixin:SelectExperience(level)
	for _, tab in pairs(self.experienceTabs) do
		if tab:GetExperience() ~= level then
			tab:SetChecked(false)
			tab:Enable()
		else
			self:TriggerEvent("OnIndexSelected", tab.Icon.normalIconAtlas, tab.Icon.NameFrame.Text:GetText())
			tab:SetChecked(true)
			tab:Disable()
		end
	end
end

function TutorialExperienceFrameMixin:GetSelectedTutorialInfo()
	for _, tab in pairs(self.experienceTabs) do
		if tab:GetChecked() then
			return tab.Icon.normalIconAtlas, tab.Icon.NameFrame.Text:GetText()
		end
	end
end
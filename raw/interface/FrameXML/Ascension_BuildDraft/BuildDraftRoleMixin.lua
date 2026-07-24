BuildDraftRoleMixin = CreateFromMixins(BorderIconTemplateMixin)

function BuildDraftRoleMixin:OnLoad()
	SetParentArray(self, "Buttons")
	AttributesToKeyValues(self)

	self.roleMask = Enum.LFGRoles[self.role]
	self:SetIconAtlas("UI-LFG-Role-" .. self.role)
	self:SetBorderAtlas("build-draft-border")
	self.BackgroundGlow:SetAtlas("Garr_BuildFX-Glow", Const.TextureKit.IgnoreAtlasSize)
	self.BackgroundGlow2:SetAtlas("Garr_BuildFX-Glow", Const.TextureKit.IgnoreAtlasSize)
	self.BackgroundGlow2:FlipX()
	local color = ROLE_COLORS[self.roleMask]
	self.BackgroundGlow:SetVertexColor(color:GetRGBA())
	self.BackgroundGlow2:SetVertexColor(color:GetRGBA())

	self.bgX, self.bgY = self.BackgroundGlow:GetSize()
	self:SetText(_G[self.role:upper()])
	self:GetFontString():SetFontFlags("OUTLINE")
end

function BuildDraftRoleMixin:GetBackgroundScale()
	local x = self.BackgroundGlow:GetWidth()

	return x / self.bgX
end

function BuildDraftRoleMixin:SetBackgroundScale(scale)
	local x, y = self.bgX * scale, self.bgY * scale
	self.BackgroundGlow:SetSize(x, y)
	self.BackgroundGlow2:SetSize(x, y)
end

function BuildDraftRoleMixin:OnShow()
	self.BackgroundGlow.Anim:Play()
	self.BackgroundGlow2.Anim:Play()
end

function BuildDraftRoleMixin:OnHide()
	self.BackgroundGlow.Anim:Stop()
	self.BackgroundGlow2.Anim:Stop()
	self:SetSelected(false)
end

function BuildDraftRoleMixin:SetSelected(selected)
	self.selected = selected
	self:SetIconDesaturated(not selected)
	self:SetBorderDesaturated(not selected)

	self.bgScale = self:GetBackgroundScale()
	self.time = 0

	if selected then
		self.duration = 1.5
		self.targetBGScale = 1
		self:GetFontString():SetVertexColor(1, 0.82, 0)
	else
		self.duration = 2
		self.targetBGScale = 0.2
		self:GetFontString():SetVertexColor(1, 1, 1)
	end

	self:SetScript("OnUpdate", self.Animate)
end

function BuildDraftRoleMixin:OnClick()
	self.clicked = true
	StaticPopup_Hide("BUILD_DRAFT_SELECT_ROLES_CONFIRM")
	if self.selected then
		PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_TRAIT_RANKUP)
	else
		PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_APPEARANCE_COLORSELECT)
	end
	self:GetParent():SetRole(not self.selected and self.roleMask)
end

function BuildDraftRoleMixin:OnEnter()
	self.clicked = nil

	if not self.selected then
		self.bgScale = self:GetBackgroundScale()
		self.time = 0
		self.targetBGScale = 0.6
		self.duration = 1.4
		self:GetFontString():SetVertexColor(1, 0.82, 0)
		self:SetScript("OnUpdate", self.Animate)
	end

	self:SetIconDesaturated(false)
end

function BuildDraftRoleMixin:OnLeave()
	if not self.selected and not self.clicked then
		self.bgScale = self:GetBackgroundScale()
		self.time = 0
		self.targetBGScale = 0.2
		self.duration = 1
		self:GetFontString():SetVertexColor(1, 1, 1)
		self:SetScript("OnUpdate", self.Animate)
	end

	self:SetIconDesaturated(not self.selected)
	self.clicked = nil
end

function BuildDraftRoleMixin:Animate(elapsed)
	if self.time >= 1 then
		self:SetBackgroundScale(self.targetBGScale)
		self:SetScript("OnUpdate", nil)
		return
	end

	local scale = MLerp(self.bgScale, self.targetBGScale, EaseInOut(self.time))
	self.time = self.time + (elapsed / self.duration)

	self:SetBackgroundScale(scale)
end
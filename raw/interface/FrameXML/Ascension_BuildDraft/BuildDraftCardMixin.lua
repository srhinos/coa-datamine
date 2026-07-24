BuildDraftCardMixin = {}

function BuildDraftCardMixin:OnLoad()
	self._spellPool = CreateFramePool("Button", self, "BuildDraftSpellTemplate")
	self.Background:SetAtlas("build-draft-bg", Const.TextureKit.IgnoreAtlasSize)
	self.Role:SetBorderAtlas("build-draft-border")
	self.BuildIcon:SetBorderAtlas("build-draft-border")
	self.BuildIcon:SetHighlightAtlas("build-draft-stat-highlight")
	self.BuildIcon:SetRounded(true)
	self.BuildIcon:SetBorderSize(84, 84)
	self.BuildIcon:SetBorderOffset(0, -1)

	self.BuildIcon.TrophyEligible:SetBorderAtlas("build-draft-border")
	self.BuildIcon.TrophyEligible:SetHighlightAtlas("build-draft-stat-highlight")
	self.BuildIcon.TrophyEligible:SetRounded(true)
	self.BuildIcon.TrophyEligible:SetBorderSize(28, 28)
	self.BuildIcon.TrophyEligible:SetBorderOffset(0, 0)
	self.BuildIcon.TrophyEligible:SetIcon("Interface\\Icons\\inv_misc_build_masters_trophy")
	self.BuildIcon.TrophyEligible.tooltipTitle = BUILD_DRAFT_TROPHY_ELIGIBLE
	self.BuildIcon.TrophyEligible.tooltipText = BUILD_DRAFT_TROPHY_ELIGIBLE_TOOLTIP

	self.BuildIcon.StatButton:SetBorderAtlas("build-draft-border")
	self.BuildIcon.StatButton:SetHighlightAtlas("build-draft-stat-highlight")
	self.BuildIcon.StatButton:SetRounded(true)
	self.BuildIcon.StatButton:SetBorderSize(46, 46)
	self.BuildIcon.StatButton:SetBorderOffset(0, -1)

	self.BuildIcon.Enchant:SetHighlightAtlas("build-draft-stat-highlight")
	self.BuildIcon.Enchant:SetBorderAtlas("build-draft-enchant-orange")
	self.BuildIcon.Enchant:SetRounded(true)
	self.BuildIcon.Enchant:SetBorderSize(52, 52)

	self.Info.Background:SetAtlas("build-draft-info", Const.TextureKit.IgnoreAtlasSize)
end

BuildDraftCardMixin.RoleBanners = {
	TANK = "build-draft-flag-blue",
	DAMAGER = "build-draft-flag-red",
	HEALER = "build-draft-flag-green",
}

function BuildDraftCardMixin:ActivateBuild()
	PlaySound(SOUNDKIT.UI_70_ARTIFACT_FORGE_TOAST_TRAITAVAILABLE)
	self._spellPool:ReleaseAll()
	C_BuildCreator.ActivateBuild(self.build.ID, true, true)
	BuildDraftFrame:Hide()
	BuildDraft:HideCards()
end

function BuildDraftCardMixin:Select()
	StaticPopup_Show("BUILD_DRAFT_BUILD_CONFIRM", SPELL_LINK_COLOR:WrapText(self.build.Name), GetMaxLevel(), GenerateClosure(self.ActivateBuild, self))
end

function BuildDraftCardMixin:SetIcon(icon)
	self.BuildIcon:SetIcon(icon)
end

function BuildDraftCardMixin:SetStat(primaryStat)
	local spellID, _, _, name = C_PrimaryStat:GetPrimaryStatInfo(Enum.PrimaryStat[primaryStat])
	self.BuildIcon.StatButton:SetSpell(spellID)
	self.BuildIcon.StatButton:SetText(name)
end

function BuildDraftCardMixin:SetTitle(title)
	self.Title:SetText(title)
end

function BuildDraftCardMixin:SetDifficulty(difficulty)
	local color = difficulty and BuildCreatorUtil.DifficultyColors[difficulty]
	difficulty = color and _G[difficulty]
	if difficulty then
		self.Difficulty:SetText(difficulty)
		self.Difficulty:SetTextColor(color:GetRGB())
	else
		self.Difficulty:SetText("")
	end
end

function BuildDraftCardMixin:SetDescription(description)
	description = description or ""

	local overview = BuildCreatorUtil.GetOverviewFromDescription(description)
	self.Info.Description:ResetToTop()
	self.Info.Description:SetText(overview)
end

function BuildDraftCardMixin:SetRole(role)
	role = BuildCreatorUtil.ConvertBuildRoleToLFGRole(role)
	self.Role:SetIconAtlas(ROLE_ATLAS[role])
	self.Banner:SetAtlas(self.RoleBanners[role])
	self.Color = ROLE_COLORS[role]
end

function BuildDraftCardMixin:SetSpells(spells)
	self._spellPool:ReleaseAll()
	local frame = self.Info.Spells

	if not spells then
		print("[Build Draft]", self.Build, "Has no level 1 spells to display!")
		return
	end

	local pos = 1
	local y = -8
	local x = 17

	local buildSpell, spellID
	for i = 1, 4 do
		buildSpell = spells[i]
		spellID = buildSpell.Spell
		if buildSpell.Level <= 1 and not C_CharacterAdvancement.IsMastery(spellID) then
			local name = GetSpellInfo(spellID)

			if name then
				local spell = self._spellPool:Acquire()

				spell:SetSpell(spellID)
				spell:SetText(name)

				if pos % 2 == 1 then
					spell:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
					x = 172
				else
					spell:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
					x = 21
					y = y - 52
				end

				spell:Show()

				pos = pos + 1
			end
		end
	end
end

function BuildDraftCardMixin:SetEnchant(enchantID)
	if not enchantID then
		self.BuildIcon.Enchant:Hide()
		return
	end
	self.BuildIcon.Enchant:Show()
	local name = GetSpellInfo(enchantID)
	self.BuildIcon.Enchant:SetSpell(enchantID)
	self.BuildIcon.Enchant:SetText(name)
end

function BuildDraftCardMixin:SetBuild(buildID, index)
	self:SetID(index)
	self.buildID = buildID
	BuildCreatorUtil.ContinueOnLoad(buildID, function(build)
		if self:GetID() ~= index or build.ID ~= buildID then
			return
		end
		if not build then
			C_Logger.Error("Build Draft has an invalid build ID: ".. (buildID or "nil") .. " Index: "..(index or "nil"))
			return
		end
		self.build = build
		self.BuildIndex:SetFormattedText(BUILD_DRAFT_CARD_NUMBER_S, index)
		self:SetTitle(build.Name)
		self:SetDifficulty(build.DifficultyRating)
		self:SetIcon("Interface\\Icons\\"..build.Icon)
		self:SetRole(build.Roles)
		self:SetStat(build.PrimaryStat)
		self:SetSpells(build.Spells)
		self:SetDescription(build.Description)
		self:SetEnchant(build.LegendaryEnchant)

		local completedBuild = C_BuildDraft.IsCompletedBuild(build.ID)
		self.BuildIcon.CompletedBuild:SetShown(completedBuild)
		self.BuildIcon.TrophyEligible:SetShown(not completedBuild)
		local color = completedBuild and GRAY_FONT_COLOR or WHITE_FONT_COLOR
		self.BuildIcon:SetIconColor(color:GetRGB())
	end)
end

function BuildDraftCardMixin:Close()
	BuildDraft:HideCards()
	BuildDraftFrame:Hide()
end

function BuildDraftCardMixin:Animate(elapsed)
	if self.time >= 1 then
		self:SetPoint("CENTER", self.endX, 0)
		self:SetScale(self.endScale)
		self.startX = nil
		self.endX = nil
		self.endScale = nil
		self.startScale = nil
		self:SetScript("OnUpdate", nil)

		BuildDraft.ArrowRight:Enable()
		BuildDraft.ArrowLeft:Enable()
		return
	end

	local x = math.lerp(self.startX, self.endX, EaseInOut(self.time))
	self:SetPoint("CENTER", x, 0)

	local scale = math.lerp(self.startScale, self.endScale, EaseInOut(self.time))
	self:SetScale(scale)
	self.time = self.time + elapsed * 4
end

function BuildDraftCardMixin:PlayMove(position)
	self.startX = position.startX
	self.endX = position.endX
	self.startScale = position.startScale
	self.endScale = position.endScale

	self.time = 0
	self:SetFrameLevel(position.level)
	self:SetPoint("CENTER", self.startX, 0)
	self:SetScale(self.startScale)
	self:SetScript("OnUpdate", self.Animate)
end
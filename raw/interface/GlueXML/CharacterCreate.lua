CHAR_CREATE_HELP_NEXT_BUTTON = CHAR_CREATE_HELP_NEXT_BUTTON or "You can go to the next step\n\nYou can change these choices at any time"
CHAR_CREATE_CUSTOMIZE_YOUR_APPEARANCE = CHAR_CREATE_CUSTOMIZE_YOUR_APPEARANCE or "Customize Your Appearance "
CHAR_CREATE_CHANGE_ANY_TIME = CHAR_CREATE_CHANGE_ANY_TIME or "You can change these choices at any time!"
CHAR_CREATE_HELP_CHOOSE_CLASS = CHAR_CREATE_HELP_CHOOSE_CLASS or "Help Me Choose"
CLASS_GUIDE_ROLE_SELECT_TEXT = CLASS_GUIDE_ROLE_SELECT_TEXT or "Select Role"
CLASS_GUIDE_CATEGORY_SELECT_TEXT = CLASS_GUIDE_CATEGORY_SELECT_TEXT or "Select Category"
CLASS_GUIDE_CLASS_SELECT_TEXT = CLASS_GUIDE_CLASS_SELECT_TEXT or "Select Class"
CLASS_GUIDE_ROLE_SELECTED_TEXT = CLASS_GUIDE_ROLE_SELECTED_TEXT or "Selected Role:\n%s"
CLASS_GUIDE_CATEGORY_SELECTED_TEXT = CLASS_GUIDE_CATEGORY_SELECTED_TEXT or "Selected Category:\n%s"
CLASS_GUIDE_CLASS_SELECTED_TEXT = CLASS_GUIDE_CLASS_SELECTED_TEXT or "Selected Class:\n%s"

function C_CharacterCreate.CanCreateArchetype()
	return GetRealmName() == "Area 52 - Free-Pick" and C_Config.GetBoolConfig("CONFIG_CHARACTER_CREATION_ARCHETYPES_ENABLED")
end

CHARACTER_FACING_INCREMENT = 2;
MAX_RACES = 11;
MAX_CLASSES_PER_RACE = 32;
NUM_CHAR_CUSTOMIZATIONS = 5;
MIN_CHAR_NAME_LENGTH = 2;
CHARACTER_CREATE_ROTATION_START_X = nil;
CHARACTER_CREATE_INITIAL_FACING = nil;
NUM_PREVIEW_FRAMES = 14;

CUSTOM_CLASSES_START_INDEX = 12
HERO_CLASS_ID = 10

IS_ZOOMED = false
local featureIndex = 1
local FeatureType = 1

PAID_CHARACTER_CUSTOMIZATION = 1;
PAID_RACE_CHANGE = 3;
PAID_FACTION_CHANGE = 2;
PAID_SERVICE_CHARACTER_ID = nil;
PAID_SERVICE_TYPE = nil;

PREVIEW_FRAME_HEIGHT = 130;
PREVIEW_FRAME_X_OFFSET = 19;
PREVIEW_FRAME_Y_OFFSET = -7;

FACTION_SHADOW_COLORS = {
	Horde = CreateColor(0.90, 0.05, 0.07),
	Alliance = CreateColor(0.29, 0.33, 0.91),
	Player = CreateColor(1, 1, 1),
}

FACTION_BACKDROP_COLOR_TABLE = {
	["Alliance"] = {0.5, 0.5, 0.5, 0.09, 0.09, 0.19, 0, 0, 0.2, 0.29, 0.33, 0.91},
	["Horde"] = {0.5, 0.2, 0.2, 0.19, 0.05, 0.05, 0.2, 0, 0, 0.90, 0.05, 0.07},
	["Player"] = {0.2, 0.5, 0.2, 0.05, 0.2, 0.05, 0.05, 0.2, 0.05, 1, 1, 1},
};

FRAMES_TO_BACKDROP_COLOR = {
	"CharacterCreateCharacterRace",
	"CharacterCreateCharacterClass",
--	"CharacterCreateCharacterFaction",
	"CharacterCreateNameEdit",
};

BANNER_DEFAULT_TEXTURE_COORDS = {0.109375, 0.890625, 0.201171875, 0.80078125};
BANNER_DEFAULT_SIZE = {200, 308};

CHAR_CUSTOMIZE_HAIR_COLOR = 4;

COA_CLASS_ORDER = {
	"NECROMANCER",
	"PYROMANCER",
	"CULTIST",
	"STARCALLER",
	"SUNCLERIC",
	"TINKER",
	"SPIRITMAGE",
	"WILDWALKER",
	"REAPER",
	"PROPHET",
	"CHRONOMANCER",
	"SONOFARUGAL",
	"GUARDIAN",
	"STORMBRINGER",
	"DEMONHUNTER",
	"BARBARIAN",
	"WITCHDOCTOR",
	"WITCHHUNTER",
	"FLESHWARDEN",
	"MONK",
	"RANGER",
}

CLASSIC_CLASS_ORDER = {
	"WARRIOR",
	"PALADIN",
	"HUNTER",
	"ROGUE",
	"PRIEST",
	"DEATHKNIGHT",
	"SHAMAN",
	"MAGE",
	"WARLOCK",
	"DRUID",
	"HERO"
}

--
-- Character create steps:
--

CHAR_CREATE_STEPS_DEFAULT = {
	Enum.CharCreateSteps.ClassRace,
	Enum.CharCreateSteps.Customization,
}

CHAR_CREATE_STEPS_CLASS_GUIDE = {
	Enum.CharCreateSteps.ClassRace,
	Enum.CharCreateSteps.NameEdit,
}

CHAR_CREATE_STEPS_EXTEND = {
	Enum.CharCreateSteps.ClassRace,
	Enum.CharCreateSteps.Customization,
	Enum.CharCreateSteps.Role,
	Enum.CharCreateSteps.Subrole,
	Enum.CharCreateSteps.Archetype,
	Enum.CharCreateSteps.NameEdit,
}

CHAR_CREATE_CAMERA_ZOOM_IN = {
	["Human"] = HD_PATCH_ENABLED and 3 or 1.5,
	["Orc"] = 1.5,
	["Troll"] = 2.5,
	["Scourge"] = 1,
	["BloodElf"] = 2.5,
	["Tauren"] = 1.5,
}

CHAR_CREATE_ZOOM = 2

--
-- Zoom/model change
--
local ZoomController = CreateFrame("FRAME")
ZoomController.zoom = 0

ZoomController:SetScript("OnUpdate", function(self, elapsed)
	local _, fileString = GetNameForRace()
	local zoomInValue = self.manualZoomIn or CHAR_CREATE_CAMERA_ZOOM_IN[fileString] or CHAR_CREATE_ZOOM
	local zoomOutValue = self.manualZoomOut or 0 

	if IS_ZOOMED and (self.zoom < zoomInValue) then
		local step = (zoomInValue-self.zoom)*0.02
		C_CharacterCreate.ZoomIn(step)
		self.zoom = self.zoom + step

		if math.NearlyEquals(self.zoom, zoomInValue, 0.1) then
			self:Hide()
		end
	elseif not(IS_ZOOMED) and (self.zoom > zoomOutValue) then
		local step = self.zoom*0.02
		C_CharacterCreate.ZoomOut(step)
		self.zoom = self.zoom - step

		if math.NearlyEquals(self.zoom, 0, 0.1) then
			self:Hide()
		end
	else
		self:Hide()
	end
end)

ZoomController:Hide()

local function CharCreate_ResetCamera()
	C_CharacterCreate.ResetCameraPosition()
	ZoomController.zoom = 0
	ZoomController.manualZoomIn = nil
	ZoomController.manualZoomOut = nil
	ZoomController:Hide()
	IS_ZOOMED = false
end

local CLASS_GUIDE_CHOICE_BUTTON_WIDTH = 96
local CLASS_GUIDE_CHOICE_BUTTON_HEIGHT = 128
local CLASS_GUIDE_CHOICE_BUTTON_SPACING = 56
local CLASS_GUIDE_CHOICE_BUTTON_Y_OFFSET = -28
local CLASS_GUIDE_FALLBACK_ATLAS = "ExperienceIconAscension"
local CLASS_GUIDE_COMBAT_HEALER_ATLAS = "ExperienceIconBattleHeal"
local CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TITLE = "Combat Healer"
local CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TEXT = "Restores allies by actively fighting and weaving offensive abilities in between healing casts."
local CLASS_GUIDE_ROLE_ATLAS = {
	TANK = "ExperienceIconTank",
	HEALER = "ExperienceIconHeal",
	DAMAGE = "ExperienceIconDamage",
	SUPPORT = "ExperienceIconFreepick",
}
local CLASS_GUIDE_SUBROLE_ATLAS = {
	MELEE_DPS = "ExperienceIconMeleeDD",
	RANGED_DPS = "ExperienceIconRanged",
	CASTER_DPS = "ExperienceIconMagic",
	HYBRID = "ExperienceIconHybridDD",
	TANK = "ExperienceIconTank",
	PURE_HEALER = "ExperienceIconSuperHeal",
	HEALER = "ExperienceIconHeal",
	COMBAT_HEALER = "ExperienceIconBattleHeal",
	SUPPORT = "ExperienceIconFreepick",
}
local CLASS_GUIDE_COMBAT_HEALER_CLASS_FILES = {
	CULTIST = true,
	STARCALLER = true,
}

local function CharacterCreate_CreateClassGuideButton(parent)
	local button = CreateFrame("CheckButton", nil, parent, "CharacterCreateArchetypeCoiceButtonTemplate")
	button:SetSize(CLASS_GUIDE_CHOICE_BUTTON_WIDTH, CLASS_GUIDE_CHOICE_BUTTON_HEIGHT)

	return button
end

local function CharacterCreate_LayoutClassGuideButtons(buttons, count, yOffset)
	local width = CLASS_GUIDE_CHOICE_BUTTON_WIDTH
	local spacing = CLASS_GUIDE_CHOICE_BUTTON_SPACING
	local totalWidth = count * width + math.max(count - 1, 0) * spacing
	local startX = -totalWidth / 2 + width / 2

	for i = 1, count do
		local button = buttons[i]
		button:ClearAllPoints()
		button:SetPoint("TOP", CharCreateClassGuideFrame, "TOP", startX + (i - 1) * (width + spacing), yOffset)
		button:Show()
	end
end

local function CharacterCreate_HideClassGuide()
	if CharCreateClassGuideFrame then
		CharCreateClassGuideFrame:Hide()
	end
end

local function CharacterCreate_HasClassGuideAPI()
	return C_CharacterCreate.GetClassGuideRoles
		and C_CharacterCreate.GetClassGuideRoleInfo
		and C_CharacterCreate.GetClassGuideSubroles
		and C_CharacterCreate.GetClassGuideSubroleInfo
		and C_CharacterCreate.GetClassGuideSubroleClasses
end

local function CharacterCreate_SetClassGuideEntryShown(shown)
	if CharCreateClassGuideEntryButton then
		CharCreateClassGuideEntryButton:SetEnabled(CharacterCreate_HasClassGuideAPI() and true or false)
		CharCreateClassGuideEntryButton:SetShown(shown)
	end
end

local function CharacterCreate_HasClassGuideData()
	if not CharacterCreate_HasClassGuideAPI() then
		return false
	end

	local roles = C_CharacterCreate.GetClassGuideRoles()
	return roles and #roles > 0
end

local function CharacterCreate_SetClassGuideRaceLocked(locked)
	for i = 1, MAX_RACES do
		local button = _G["CharCreateRaceButton"..i]
		if button then
			button:EnableMouse(not locked)
		end
	end
end

local function CharacterCreate_ClassMatchesGuideSubrole(classID, classFileName, subroleID)
	if not subroleID or not C_CharacterCreate.GetClassGuideSubroleInfo then
		return true
	end

	local _, _, classRoleKey = C_CharacterCreate.GetClassGuideSubroleInfo(subroleID)
	if not classRoleKey then
		return false
	end

	if C_CharacterCreate.GetClassGuideSubroleClasses then
		local classes = C_CharacterCreate.GetClassGuideSubroleClasses(subroleID)
		if classes and #classes > 0 then
			for _, guideClassID in ipairs(classes) do
				if guideClassID == classID then
					return true
				end
			end

			return false
		end
	end

	if classRoleKey == "Hybrid" then
		if not C_CharacterCreate.GetClassGuideSubroleClasses then
			return false
		end

		local classes = C_CharacterCreate.GetClassGuideSubroleClasses(subroleID)
		for _, guideClassID in ipairs(classes) do
			if guideClassID == classID then
				return true
			end
		end

		return false
	end

	local roles = ClassInfoUtil.GetClassRoles(classFileName)
	return roles and roles[classRoleKey]
end

local function CharacterCreate_ClassPassesGuideFilter(classID, classFileName)
	if not CharacterCreate.classGuideActive then
		return true
	end

	if CharacterCreate.selectedClassGuideSubroleID then
		return CharacterCreate_ClassMatchesGuideSubrole(classID, classFileName, CharacterCreate.selectedClassGuideSubroleID)
	end

	return false
end

local function CharacterCreate_IsClassGuideHealerSubrole(subroleID)
	if not CharacterCreate.selectedClassGuideRoleID
		or not subroleID
		or not C_CharacterCreate.GetClassGuideRoleInfo
		or not C_CharacterCreate.GetClassGuideSubroleInfo then
		return false
	end

	local roleKey = C_CharacterCreate.GetClassGuideRoleInfo(CharacterCreate.selectedClassGuideRoleID)
	if roleKey ~= "HEALER" then
		return false
	end

	local _, subroleKey = C_CharacterCreate.GetClassGuideSubroleInfo(subroleID)
	return subroleKey == "HEALER" or subroleKey == "PURE_HEALER"
end

local function CharacterCreate_IsClassGuideCombatHealer(classFileName)
	return CLASS_GUIDE_COMBAT_HEALER_CLASS_FILES[classFileName] and true or false
end

local function CharacterCreate_ClassGuideClassIsAvailableForRace(classID, raceID)
	if not classID or not CharacterCreate.selectedClassGuideSubroleID then
		return false
	end

	if not C_CharacterCreate.CanCreateClass(classID)
		or not CharacterCreateUtil.IsRaceClassEnabledAndValid(raceID or CharacterCreate.selectedRace, classID) then
		return false
	end

	local _, classFileName = GetClassInfo(classID)
	return classFileName and CharacterCreate_ClassMatchesGuideSubrole(classID, classFileName, CharacterCreate.selectedClassGuideSubroleID)
end

local function CharacterCreate_GetFirstAvailableClassGuideClassForRace(raceID)
	if not CharacterCreate.selectedClassGuideSubroleID then
		return nil
	end

	for i = 1, 21 do
		local classID = Enum.Class[COA_CLASS_ORDER[i]]
		if CharacterCreate_ClassGuideClassIsAvailableForRace(classID, raceID) then
			return classID
		end
	end
end

local function CharacterCreate_GetSingleClassGuideSubrole(roleID)
	if not roleID or not C_CharacterCreate.GetClassGuideSubroles or not C_CharacterCreate.GetClassGuideSubroleInfo then
		return nil
	end

	local singleSubroleID
	local subroleCount = 0
	local subroles = C_CharacterCreate.GetClassGuideSubroles(roleID)
	for _, subroleID in ipairs(subroles) do
		local _, _, _, _, name = C_CharacterCreate.GetClassGuideSubroleInfo(subroleID)
		if name then
			subroleCount = subroleCount + 1
			singleSubroleID = subroleID
		end
	end

	if subroleCount == 1 then
		return singleSubroleID
	end
end

local function CharacterCreate_SelectClassGuideRole(roleID)
	CharacterCreate.selectedClassGuideRoleID = roleID
	CharacterCreate.selectedClassGuideSubroleID = CharacterCreate_GetSingleClassGuideSubrole(roleID)
	CharacterCreate.selectedClassGuideClassID = nil
	CharCreateOkayButton:Disable()
	CharacterCreate_RefreshClassButtons(CharacterCreate)
end

local function CharacterCreate_SelectClassGuideSubrole(subroleID)
	CharacterCreate.selectedClassGuideSubroleID = subroleID
	CharacterCreate.selectedClassGuideClassID = nil
	CharCreateOkayButton:Disable()
	CharacterCreate_RefreshClassButtons(CharacterCreate)
end

local function CharacterCreate_OpenClassGuide()
	if not CharacterCreate_HasClassGuideData() then
		return
	end

	CharacterCreate.classGuideActive = true
	CharacterCreate.selectedClassGuideRoleID = nil
	CharacterCreate.selectedClassGuideSubroleID = nil
	CharacterCreate.selectedClassGuideClassID = nil
	CharCreateOkayButton:SetText(CONTINUE)
	CharCreateOkayButton:Disable()
	CharacterCreate_SetClassGuideRaceLocked(true)
	CharacterCreate_RefreshClassButtons(CharacterCreate)
end

local function CharacterCreate_CloseClassGuide()
	CharacterCreate.classGuideActive = false
	CharacterCreate.selectedClassGuideRoleID = nil
	CharacterCreate.selectedClassGuideSubroleID = nil
	CharacterCreate.selectedClassGuideClassID = nil
	CharCreateOkayButton:SetText(CUSTOMIZE)
	CharCreate_EnableNextButton(true)
	CharacterCreate_SetClassGuideRaceLocked(false)
	if CharacterCreateFrame.state == Enum.CharCreateSteps.ClassRace and CharacterCreate_LoadNavigation then
		CharacterCreate_LoadNavigation(CHAR_CREATE_STEPS_DEFAULT)
		CharacterCreateNavigationFrame:GoToIndex(Enum.CharCreateSteps.ClassRace, true)
	end
	CharacterCreate_RefreshClassButtons(CharacterCreate)
end

local function CharacterCreate_ClassGuideBack()
	if CharacterCreate.selectedClassGuideSubroleID then
		CharacterCreate.selectedClassGuideSubroleID = nil
		CharacterCreate.selectedClassGuideClassID = nil
		if CharacterCreate_GetSingleClassGuideSubrole(CharacterCreate.selectedClassGuideRoleID) then
			CharacterCreate.selectedClassGuideRoleID = nil
		end
	elseif CharacterCreate.selectedClassGuideRoleID then
		CharacterCreate.selectedClassGuideRoleID = nil
	else
		CharacterCreate_CloseClassGuide()
		return
	end

	CharCreateOkayButton:Disable()
	CharacterCreate_RefreshClassButtons(CharacterCreate)
end

local function CharacterCreate_CreateClassGuideFrame()
	if not CharCreateClassGuideEntryButton then
		CharCreateClassGuideEntryButton = CreateFrame("Button", "CharCreateClassGuideEntryButton", CharacterCreateFrame, "CharCreateNavButtonTemplate")
		CharCreateClassGuideEntryButton:SetSize(150, 50)
		CharCreateClassGuideEntryButton:SetPoint("BOTTOM", CharCreateBackButton, "TOP", 0, 8)
		CharCreateClassGuideEntryButton:SetText(CHAR_CREATE_HELP_CHOOSE_CLASS)
		CharCreateClassGuideEntryButton:SetScript("OnClick", CharacterCreate_OpenClassGuide)
		CharCreateClassGuideEntryButton:Hide()
	end

	if not CharCreateClassGuideFrame then
		CharCreateClassGuideFrame = CreateFrame("Frame", "CharCreateClassGuideFrame", CharCreateClassFrame)
		CharCreateClassGuideFrame:SetSize(760, 184)
		CharCreateClassGuideFrame:SetPoint("CENTER", CharCreateClassFrame, "CENTER", 0, 0)
		CharCreateClassGuideFrame.roleButtons = {}
		CharCreateClassGuideFrame.subroleButtons = {}

		CharCreateClassGuideFrame.BackButton = CreateFrame("Button", nil, CharCreateClassGuideFrame, "CharCreateNavButtonTemplate")
		CharCreateClassGuideFrame.BackButton:SetSize(150, 50)
		CharCreateClassGuideFrame.BackButton:SetPoint("BOTTOMLEFT", CharCreateClassGuideFrame, "TOPLEFT", 0, 8)
		CharCreateClassGuideFrame.BackButton:SetText(BACK)
		CharCreateClassGuideFrame.BackButton:SetScript("OnClick", CharacterCreate_ClassGuideBack)
		CharCreateClassGuideFrame.BackButton:Hide()
		CharCreateClassGuideFrame:Hide()
	end
end

local function CharacterCreate_GetClassGuideAtlas(atlas)
	if atlas and AtlasUtil:AtlasExists(atlas) then
		return atlas
	end

	return CLASS_GUIDE_FALLBACK_ATLAS
end

local function CharacterCreate_SetClassGuideButton(button, id, text, atlas, description, onClick)
	local normalAtlas = CharacterCreate_GetClassGuideAtlas(atlas)

	button:SetID(id)
	button.step = id
	button:Enable()
	button:SetChecked(false)
	button:SetIconNormal(normalAtlas)
	button:SetIconHighlighted(normalAtlas)
	button.Highlight:Hide()
	button.Checked:Hide()

	button:UpdateText(text, "")
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(self)
		self.NameFrame.Text:SetFontObject(self.highlightFontObject or GameFontHighlightOutlineLarge)
		if text then
			GlueTooltip:SetOwner(self, "ANCHOR_TOP")
			GlueTooltip:AddLine(text, 1, 1, 1, 1, true)
			if description and description ~= "" then
				GlueTooltip:AddLine(description, 1, 0.82, 0, 1, true)
			end
			GlueTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function(self)
		self.Highlight:Hide()
		self:SetIconNormal()
		self.NameFrame.Text:SetFontObject(self.normalFontObject or GameFontNormalOutlineLarge)
		GlueTooltip:Hide()
	end)
end

local function CharacterCreate_HideClassGuideButtons(buttons)
	for _, button in ipairs(buttons) do
		button:Hide()
	end
end

local function CharacterCreate_UpdateClassGuideFrame()
	if not CharacterCreate.classGuideActive or not CharCreateClassGuideFrame or not CharacterCreate_HasClassGuideData() then
		CharacterCreate_HideClassGuide()
		return
	end

	local roles = C_CharacterCreate.GetClassGuideRoles()
	CharCreateClassGuideFrame:Show()
	if CharCreateClassGuideFrame.BackButton then
		CharCreateClassGuideFrame.BackButton:Hide()
	end

	if CharacterCreate.selectedClassGuideSubroleID then
		CharacterCreate_SetClassGuideRaceLocked(false)
		CharacterCreate_HideClassGuideButtons(CharCreateClassGuideFrame.roleButtons)
		CharacterCreate_HideClassGuideButtons(CharCreateClassGuideFrame.subroleButtons)
		return
	end

	CharacterCreate_SetClassGuideRaceLocked(true)

	local roleCount = 0
	if not CharacterCreate.selectedClassGuideRoleID then
		for _, roleID in ipairs(roles) do
			local roleKey, atlas, name, description = C_CharacterCreate.GetClassGuideRoleInfo(roleID)
			if name then
				roleCount = roleCount + 1
				local button = CharCreateClassGuideFrame.roleButtons[roleCount]
				if not button then
					button = CharacterCreate_CreateClassGuideButton(CharCreateClassGuideFrame)
					CharCreateClassGuideFrame.roleButtons[roleCount] = button
				end

				CharacterCreate_SetClassGuideButton(button, roleID, name, CLASS_GUIDE_ROLE_ATLAS[roleKey] or atlas, description, function(self)
					CharacterCreate_SelectClassGuideRole(self:GetID())
				end)
			end
		end
	end

	for i = roleCount + 1, #CharCreateClassGuideFrame.roleButtons do
		CharCreateClassGuideFrame.roleButtons[i]:Hide()
	end

	if roleCount > 0 then
		CharacterCreate_LayoutClassGuideButtons(CharCreateClassGuideFrame.roleButtons, roleCount, CLASS_GUIDE_CHOICE_BUTTON_Y_OFFSET)
	end

	local subroleCount = 0
	if CharacterCreate.selectedClassGuideRoleID and C_CharacterCreate.GetClassGuideSubroles then
		local subroles = C_CharacterCreate.GetClassGuideSubroles(CharacterCreate.selectedClassGuideRoleID)
		for _, subroleID in ipairs(subroles) do
			local _, subroleKey, _, atlas, name, description = C_CharacterCreate.GetClassGuideSubroleInfo(subroleID)
			if name then
				subroleCount = subroleCount + 1
				local button = CharCreateClassGuideFrame.subroleButtons[subroleCount]
				if not button then
					button = CharacterCreate_CreateClassGuideButton(CharCreateClassGuideFrame)
					CharCreateClassGuideFrame.subroleButtons[subroleCount] = button
				end

				CharacterCreate_SetClassGuideButton(button, subroleID, name, CLASS_GUIDE_SUBROLE_ATLAS[subroleKey] or atlas, description, function(self)
					CharacterCreate_SelectClassGuideSubrole(self:GetID())
				end)
			end
		end
	end

	for i = subroleCount + 1, #CharCreateClassGuideFrame.subroleButtons do
		CharCreateClassGuideFrame.subroleButtons[i]:Hide()
	end

	if subroleCount > 0 then
		CharacterCreate_LayoutClassGuideButtons(CharCreateClassGuideFrame.subroleButtons, subroleCount, CLASS_GUIDE_CHOICE_BUTTON_Y_OFFSET)
	end
end

local function CharacterCreate_SetGuideClassButtonPoint(button, index, rowCount, yOffset)
	local width = 52
	local spacing = 36
	local totalWidth = rowCount * width + math.max(rowCount - 1, 0) * spacing
	local startX = -totalWidth / 2 + width / 2

	button:ClearAllPoints()
	button:SetPoint("TOP", CharCreateClassGuideFrame, "TOP", startX + (index - 1) * (width + spacing), yOffset)
end

local function CharacterCreate_UpdateClassGuideClassButtonSelection(self)
	if not self or not self.classButtonPool then
		return
	end

	for button in self.classButtonPool:EnumerateActive() do
		button:SetSelected(button:GetID() == CharacterCreate.selectedClassGuideClassID)
	end
end

local function CharacterCreate_GetClassGuideExplicitClassOrder(subroleID)
	local classOrder = {}
	if C_CharacterCreate.GetClassGuideSubroleClasses then
		local classes = C_CharacterCreate.GetClassGuideSubroleClasses(subroleID)
		if classes then
			for index, classID in ipairs(classes) do
				classOrder[classID] = index
			end
		end
	end

	return classOrder
end

local function CharacterCreate_ShowClassGuideClasses(self)
	if not CharacterCreate.selectedClassGuideSubroleID then
		return
	end

	local pool = self.classButtonPool
	local classes = {}
	local selectedClassIsAvailable = false
	local explicitClassOrder = CharacterCreate_GetClassGuideExplicitClassOrder(CharacterCreate.selectedClassGuideSubroleID)
	local isHealerSubrole = CharacterCreate_IsClassGuideHealerSubrole(CharacterCreate.selectedClassGuideSubroleID)

	for i = 1, 21 do
		local classID = Enum.Class[COA_CLASS_ORDER[i]]
		if classID
			and C_CharacterCreate.CanCreateClass(classID) then
			local className, classFile = GetClassInfo(classID)
			if className
				and classFile
				and CharacterCreate_ClassPassesGuideFilter(classID, classFile) then
				if CharacterCreateUtil.IsRaceClassEnabledAndValid(CharacterCreate.selectedRace, classID) then
					classes[#classes + 1] = {
						id = classID,
						name = className,
						file = classFile,
						order = explicitClassOrder[classID] or i,
						isCombatHealer = isHealerSubrole and CharacterCreate_IsClassGuideCombatHealer(classFile),
					}
					if classID == CharacterCreate.selectedClassGuideClassID then
						selectedClassIsAvailable = true
					end
				end
			end
		end
	end

	if CharacterCreate.selectedClassGuideClassID and not selectedClassIsAvailable then
		CharacterCreate.selectedClassGuideClassID = nil
	end

	CharCreate_EnableNextButton(CharacterCreate.selectedClassGuideClassID and true or false)
	table.sort(classes, function(left, right)
		if left.isCombatHealer ~= right.isCombatHealer then
			return not left.isCombatHealer
		end

		if left.order ~= right.order then
			return left.order < right.order
		end

		return left.id < right.id
	end)

	local firstRowCount = math.min(#classes, 10)
	local secondRowCount = math.max(#classes - firstRowCount, 0)
	for index, classInfo in ipairs(classes) do
		local button = pool:Acquire()
		button:SetID(classInfo.id)
		button:SetParent(CharCreateClassGuideFrame)
		button:SetClass(classInfo.name, classInfo.file, true)
		button:SetClassGuideCombatHealer(classInfo.isCombatHealer)
		button:SetSelected(classInfo.id == CharacterCreate.selectedClassGuideClassID)
		button:Show()

		if index <= firstRowCount then
			CharacterCreate_SetGuideClassButtonPoint(button, index, firstRowCount, -124)
		else
			CharacterCreate_SetGuideClassButtonPoint(button, index - firstRowCount, secondRowCount, -182)
		end
	end

	CharacterCreate_UpdateClassGuideClassButtonSelection(self)
end

local function CharacterCreate_IsCustomizationOptionLocked(customizationId)
	if not C_CharacterCustomizationUnlocks or not C_CharacterCustomizationUnlocks.GetCurrentOptionInfo then
		return false
	end

	local hasRequirement, isUnlocked = C_CharacterCustomizationUnlocks.GetCurrentOptionInfo(customizationId)
	return hasRequirement and not isUnlocked
end

local function HandleFactionBackground()
	local name, faction = GetFactionForRace(CharacterCreate.selectedRace);

	if not C_CharacterCreate.CanCreateCoA() then
		faction = faction.."REGULAR"
	end

	SetBackgroundModel(CharacterCreate, string.upper(faction));
	IS_ZOOMED = false
	--SetBackgroundModel(CharacterCreate, string.upper(faction));
end

local function SetFaceCustomizeCamera(flag)
	ZoomController.manualZoomIn = nil 
	ZoomController.manualZoomOut = nil
	if (flag) and not(IS_ZOOMED) then
		ZoomController:Show()
		IS_ZOOMED = true
	elseif not(flag) and (IS_ZOOMED) then
		ZoomController:Show()
		IS_ZOOMED = false
	end
end

local function CharacterCreate_UndressCustomizationHeadSlot()
	if CharacterCreateFrame.state ~= Enum.CharCreateSteps.Customization
		and not (CharacterCreate.classGuideActive and CharacterCreateFrame.state == Enum.CharCreateSteps.NameEdit) then
		return
	end

	if not CharCreateShowEquipmentToggle or not CharCreateShowEquipmentToggle:GetChecked() then
		return
	end

	if not CharacterCreate or type(CharacterCreate.UndressSlot) ~= "function" then
		return
	end

	pcall(CharacterCreate.UndressSlot, CharacterCreate, INVSLOT_HEAD)
end

function CharacterCreate_UpdateCustomizationEquipment()
	if CharacterCreateFrame.state ~= Enum.CharCreateSteps.Customization
		and not (CharacterCreate.classGuideActive and CharacterCreateFrame.state == Enum.CharCreateSteps.NameEdit) then
		return
	end

	if CharCreateShowEquipmentToggle and CharCreateShowEquipmentToggle:GetChecked() then
		C_CharacterCreate.Dress()
	else
		C_CharacterCreate.Undress()
	end

	CharacterCreate_UndressCustomizationHeadSlot()
end

function CharCreate_ZoomOutArchetypes()
	local x, y, z = C_CharacterCreate.GetCameraPosition()

	local shiftX, shiftY, shiftZ

	local _, fileString = GetNameForRace()
	local zoomData = CHAR_CREATE_CAMERA_ZOOM_OUTS[fileString]

	if HD_PATCH_ENABLED and fileString == "Human" then -- in HD patch don't change human camera
		zoomData = nil
	end

	if zoomData then
		C_CharacterCreate.SetCameraPosition(unpack(zoomData))
	end

	CHAR_CREATE_ZOOMED_OUT = true
end

--
-- Navigation logic
--
function CharacterCreate_LoadStep()
	CharCreateRoleSelectFrame:Hide()
	CharCreateSubroleSelectFrame:Hide()
	CharCreateArchetypeSelectFrame:Hide()

	CharCreateArchetypeFrame:Hide()
	CharCreateCustomizationFrame:Hide();
	CharCreatePreviewFrame:Hide();
	CharacterCreateNameEdit:Hide();
	CharacterCreateRandomName:Hide();
	CustomizationBG:Hide()
	CharCreateRandomizeButton:Hide()
	CharCreateClassFrame:Hide();
	CharCreateRaceFrame:Hide();
	CharCreateSwapClassesButton:Hide()
	CharacterTemplateConfirmDialog:Hide();
	CharCreateMaleButton:Hide()
	CharCreateFemaleButton:Hide()
	CustomizationLogoAlliance:Hide()
	CustomizationTextAlliance:Hide()
	CustomizationLogoHorde:Hide()
	CustomizationTextHorde:Hide()
	CharCreateDescriptionFrame:Hide()
	CharacterCreateNavigationFrame:Hide()
	CharCreateOkayButton:SetText(CONTINUE)
	CharCreateOkayButton:Enable()

	CharacterCreateFrame.StepName:Show()
	CharacterCreateFrame.StepSubText:Show()
	
	CharCreateMovieFrame:StopMovie()
	if CharCreateMovieFrame:IsShown() then
		CharCreateMovieFrame:Hide()
	end

	CharCreateDescriptionFrame:ClearAndSetPoint("TOPRIGHT", -32, -64)
	CharCreateDescriptionFrame:SetHeight(545)
	C_CharacterCreate.Dress()
	
	CharCreate_ResetCamera()
	local _, classFileName = GetSelectedClass()
	local isHero = classFileName == "HERO"

	if CharacterCreateFrame.state == Enum.CharCreateSteps.ClassRace then
		CharacterCreateFrame.StepName:Hide()
		CharacterCreateFrame.StepSubText:Hide()

		CharCreateClassFrame:Show();
		CharCreateRaceFrame:Show();
		CharCreateMaleButton:Show()
		CharCreateFemaleButton:Show()
		CharCreateOkayButton:SetText(CUSTOMIZE);
		CustomizationLogoAlliance:Show()
		CustomizationTextAlliance:Show()
		CustomizationLogoHorde:Show()
		CustomizationTextHorde:Show()
		if CharacterCreate.classGuideActive then
			CharCreateOkayButton:SetText(CONTINUE)
			CharacterCreate_RefreshClassButtons(CharacterCreate)
			CharCreate_EnableNextButton(CharacterCreate.selectedClassGuideClassID and true or false)
			CharacterCreate_SetClassGuideRaceLocked(not CharacterCreate.selectedClassGuideSubroleID)
		else
			CharacterCreate_RefreshClassButtons(CharacterCreate)
			CharCreate_EnableNextButton(true)
		end
		if isHero then
			C_CharacterCreate.ClearClassPreview()
			C_CharacterCreate.SetSelectedArchetype(0, 0, 0)
		else
			C_CharacterCreate.PreviewClassOutfit(classFileName)
		end
	elseif ( CharacterCreateFrame.state == Enum.CharCreateSteps.Customization ) then
		CharacterCreateFrame.StepName:SetText(CHAR_CREATE_CUSTOMIZE_YOUR_APPEARANCE)

		CharacterCreateNavigationFrame:Show()
		CharCreateCustomizationFrame:Show();
		CharacterCreate_UpdateHairCustomization()
		CharCreate_PrepPreviewModels();
		if ( CharacterCreateFrame.customizationType ) then
			CharCreate_ResetFeaturesDisplay();
		else
			CharCreateSelectCustomizationType(1);
		end

		if not CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.NameEdit) then
			CharacterCreateNameEdit:Show()
			if ( ALLOW_RANDOM_NAME_BUTTON ) then
				CharacterCreateRandomName:Show();
			end
		end
		
		CustomizationBG:Show()
		CharCreateRandomizeButton:Show()
		CharCreate_EnableNextButton(true)
		CHAR_CREATE_ZOOMED_OUT = false

		C_CharacterCreate.SetSelectedArchetype(0, 0, 0)
		CharacterCreate_UpdateCustomizationEquipment()
	elseif ( CharacterCreateFrame.state == Enum.CharCreateSteps.Role ) then
		if CharacterCreate.classGuideActive then
			CharacterCreateFrame.StepName:SetText(CLASS_GUIDE_ROLE_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateClassFrame:Show()
			CharCreateClassContainer:Hide()
			CharacterCreate_SetClassGuideEntryShown(false)
			CharacterCreate_UpdateClassGuideFrame()
			CharCreateOkayButton:Disable()
		else
			CharacterCreateFrame.StepName:SetText(ROLE_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateRoleSelectFrame:Show()

			local roleID = CharCreateRoleSelectFrame:GetCurrentIndex()

			if not roleID then
				CharCreateDescriptionFrame:Hide()
				CharCreateOkayButton:Disable()
			else
				C_CharacterCreate.SetSelectedArchetype(roleID, 0, 0)
				CharCreateDescriptionFrame:SetRole(roleID)
				CharCreateDescriptionFrame:Show()
				CharCreate_EnableNextButton(true)
			end
		end

		CharCreate_ZoomOutArchetypes()
	elseif ( CharacterCreateFrame.state == Enum.CharCreateSteps.Subrole ) then
		if CharacterCreate.classGuideActive then
			CharacterCreateFrame.StepName:SetText(CLASS_GUIDE_CATEGORY_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateClassFrame:Show()
			CharCreateClassContainer:Hide()
			CharacterCreate_SetClassGuideEntryShown(false)
			CharacterCreate_UpdateClassGuideFrame()
			CharCreateOkayButton:Disable()
		else
			CharacterCreateFrame.StepName:SetText(SUBROLE_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateSubroleSelectFrame:Show()

			local categoryID = CharCreateSubroleSelectFrame:GetCurrentIndex()
			if not categoryID then
				CharCreateDescriptionFrame:Hide()
				CharCreateOkayButton:Disable()
			else
				CharCreateDescriptionFrame:SetCategory(categoryID)
				CharCreateDescriptionFrame:Show()
				CharCreate_EnableNextButton(true)

				local roleID = CharCreateRoleSelectFrame:GetCurrentIndex()
				C_CharacterCreate.SetSelectedArchetype(roleID, categoryID, 0)
			end
		end

		CharCreate_ZoomOutArchetypes()
	elseif ( CharacterCreateFrame.state == Enum.CharCreateSteps.Archetype ) then
		if CharacterCreate.classGuideActive then
			CharacterCreateFrame.StepName:SetText(CLASS_GUIDE_CLASS_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateClassFrame:Show()
			CharCreateClassContainer:Hide()
			CharacterCreate_SetClassGuideRaceLocked(false)
			CharacterCreate_SetClassGuideEntryShown(false)
			CharacterCreate_UpdateClassGuideFrame()
			CharacterCreate.classButtonPool:ReleaseAll()
			CharacterCreate_ShowClassGuideClasses(CharacterCreate)
			CharCreate_EnableNextButton(CharacterCreate.selectedClassGuideClassID and true or false)
		else
			CharacterCreateFrame.StepName:SetText(ARCHETYPE_SELECT_TEXT)

			CharacterCreateNavigationFrame:Show()
			CharCreateArchetypeSelectFrame:Show()

			local archetypeID = CharCreateArchetypeSelectFrame:GetCurrentIndex()

			if not archetypeID then
				CharCreateDescriptionFrame:Hide()
				CharCreateOkayButton:Disable()
			else
				CharacterCreate_OnSelectArchetype(nil, archetypeID)
				CharCreate_EnableNextButton(true)
			end
		end

		CharCreate_ZoomOutArchetypes()
	elseif CharacterCreateFrame.state == Enum.CharCreateSteps.NameEdit then
		CharacterCreateNavigationFrame:Show()
		CharacterCreateNameEdit:Show()
		if ( ALLOW_RANDOM_NAME_BUTTON ) then
			CharacterCreateRandomName:Show();
		end

		if CharacterCreate.classGuideActive then
			CharCreateCustomizationFrame:Show()
			CharacterCreate_UpdateHairCustomization()
			CharCreate_PrepPreviewModels();
			if ( CharacterCreateFrame.customizationType ) then
				CharCreate_ResetFeaturesDisplay();
			else
				CharCreateSelectCustomizationType(1);
			end

			CustomizationBG:Show()
			CharCreateRandomizeButton:Show()
			CharCreate_EnableNextButton(true)
			CHAR_CREATE_ZOOMED_OUT = false
			CharacterCreate_UpdateCustomizationEquipment()
		else
			if not isHero then
				C_CharacterCreate.PreviewClassOutfit(classFileName)
			else
				C_CharacterCreate.ClearClassPreview()
			end
			CharCreate_ZoomOutArchetypes()
		end
	end

	CharacterCreate_UndressCustomizationHeadSlot()

	if not CharacterCreateNavigationFrame:GetNextIndex() then
		CharCreateOkayButton:SetText(FINISH)
	end
end

function CharCreate_CheckExtraSteps()
	if CharacterCreate.classGuideActive then
		return
	end

	local rolesButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Role)
	local subRolesButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Subrole)
	local archeTypeButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Archetype)
	local nameButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.NameEdit)

	if rolesButton and not(CharCreateRoleSelectFrame:GetCurrentIndex()) then
		rolesButton:SetText(ROLE_SELECT_TEXT)

		if subRolesButton then
			subRolesButton:Disable()
		end

		rolesButton.IconAdd:SetAtlas("ExperienceIconBeginner", Const.TextureKit.IgnoreAtlasSize)
	end

	if subRolesButton and not(CharCreateSubroleSelectFrame:GetCurrentIndex()) then
		subRolesButton:SetText(SUBROLE_SELECT_TEXT)

		if archeTypeButton then
			archeTypeButton:Disable()
		end

		subRolesButton.IconAdd:SetAtlas("ExperienceIconBeginner", Const.TextureKit.IgnoreAtlasSize)
	end

	if archeTypeButton and not(CharCreateArchetypeSelectFrame:GetCurrentIndex()) then
		archeTypeButton:SetText(ARCHETYPE_SELECT_TEXT)

		if nameButton then
			nameButton:Disable()
		end

		archeTypeButton:SetUp()
	end
end

function CharacterCreate_UpdateNavigtationRaceButton()
	local button = _G["CharCreateRaceButton"..CharacterCreate.selectedRace]

	if button then
		local raceButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.ClassRace)
		if not raceButton then
			return
		end

		raceButton.IconAdd:Hide()

		raceButton:SetText(string.format(RACE_SELECTED_TEXT, button.Text:GetText() or ""))

		local texture = button:GetNormalTexture():GetTexture()
		local ULx,ULy,LLx,LLy,URx,URy,LRx,LRy = button:GetNormalTexture():GetTexCoord()

		raceButton.Icon:SetTexture(texture)
		raceButton.Icon:SetTexCoord(ULx,ULy,LLx,LLy,URx,URy,LRx,LRy)
	end
end

function CharacterCreate_LoadNavigation(steps)
	CharacterCreateNavigationFrame:ClearAll()

	for i = 1, #steps do
		CharacterCreateNavigationFrame:AddIndex(steps[i])
	end

	CharacterCreate_UpdateNavigtationRaceButton()

	local customizationButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Customization)
	if customizationButton then
		customizationButton.IconAdd:SetSize(56, 56)
		customizationButton.IconAdd:SetTexture("interface\\glues\\charactercreate\\CharacterCreate")
		customizationButton.IconAdd:SetTexCoord(0.29150390625, 0.357421875, 0.7880859375, 0.919921875)
		customizationButton:SetText(CUSTOMIZE)
	end

	local nameEditButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.NameEdit)

	if nameEditButton then
		nameEditButton.IconAdd:SetSize(56, 56)
		nameEditButton.IconAdd:SetTexture("interface\\glues\\charactercreate\\CharacterCreate")
		nameEditButton.IconAdd:SetTexCoord(0.42431640625, 0.47314453125, 0.8408203125, 0.94140625)
		nameEditButton:SetText(CHARACTER_NAME)
	end

	CharCreateRoleSelectFrame:ClearSelected()
	CharCreateSubroleSelectFrame:ClearAll()
	CharCreateArchetypeSelectFrame:ClearAll()

	CharCreate_CheckExtraSteps()
end

function CharacterCreate_OnStepChanged(_, step, isForced)
	print("CharacterCreate_OnStepChanged "..step)
	if CharacterCreateFrame.state == Enum.CharCreateSteps.Archetype then
		CharCreateMovieFrame:StopMovie()
		if CharCreateMovieFrame:IsShown() then
			CharCreateMovieFrame:Hide()
		end
	end

	CharacterCreateFrame.state = step

	if (step == Enum.CharCreateSteps.NameEdit) or isForced then -- don't flash light for name edit
		CharacterCreate_LoadStep()
		return
	end

	GlueFrameFadeIn(CharacterCreateFrameFade, 0.3, function()
		if step == Enum.CharCreateSteps.ClassRace then
			HandleFactionBackground()
		else
			local race, fileString = GetNameForRace()
			SetBackgroundModel(CharacterCreate, string.upper(fileString))
		end

		GlueFrameFadeOut(CharacterCreateFrameFade, 0.25)
		CharacterCreate_LoadStep()
	end)
end

function CharacterCreate_OnArchetypeBaseChanged(_, archetypeChoice)
	if archetypeChoice == Enum.CharCreateArchetypeBases.Freepick then
		CharacterCreate_LoadNavigation(CHAR_CREATE_STEPS_DEFAULT)
	elseif archetypeChoice == Enum.CharCreateArchetypeBases.UseArchetype then
		CharacterCreate_LoadNavigation(CHAR_CREATE_STEPS_EXTEND)
	end

	if not CharacterCreateNavigationFrame:GetCurrentIndex() or (CharacterCreateNavigationFrame:GetCurrentIndex() ~= CHAR_CREATE_STEPS_DEFAULT[1]) then
		CharacterCreateNavigationFrame:GoToIndex(CHAR_CREATE_STEPS_DEFAULT[1], true)
	end
end

function CharacterCreate_OnSelectRole(self, roleID)
	if not roleID then
		return
	end

	-- clear subrole/architect 
	CharCreateSubroleSelectFrame:ClearSelected()
	CharCreateArchetypeSelectFrame:ClearSelected()
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Archetype):Disable()

	CharCreateSubroleSelectFrame:LoadSubroles(roleID)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Subrole):Enable()

	if (CharCreateOkayButton:IsEnabled() == 0) then
		CharCreate_EnableNextButton(true)
	end

	local artwork, name = C_CharacterCreate.GetArchetypeRoleInfo(roleID)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Role).IconAdd:SetAtlas(artwork)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Role):SetText(string.format(ROLE_SELECTED_TEXT, name))

	CharCreateDescriptionFrame:SetRole(roleID)
	CharCreateDescriptionFrame:Show()

	CharCreate_CheckExtraSteps()

	C_CharacterCreate.SetSelectedArchetype(roleID, 0, 0)
end

function CharacterCreate_OnSelectCategory(self, categoryID)
	CharCreateArchetypeSelectFrame:ClearSelected()

	CharCreateArchetypeSelectFrame:LoadArchetypes(categoryID)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Archetype):Enable()

	if (CharCreateOkayButton:IsEnabled() == 0) then
		CharCreate_EnableNextButton(true)
	end

	local iconArtwork, _, name = C_CharacterCreate.GetArchetypeCategoryInfo(categoryID)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Subrole).IconAdd:SetAtlas(iconArtwork)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Subrole):SetText(string.format(SUBROLE_SELECTED_TEXT, name))

	CharCreateDescriptionFrame:SetCategory(categoryID)
	CharCreateDescriptionFrame:Show()

	CharCreate_CheckExtraSteps()

	C_CharacterCreate.SetSelectedArchetype(CharCreateRoleSelectFrame:GetCurrentIndex(), categoryID, 0)
end

function CharacterCreate_OnSelectArchetype(_, archetypeID)
	CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.NameEdit):Enable()

	if (CharCreateOkayButton:IsEnabled() == 0) then
		CharCreate_EnableNextButton(true)
	end

	local _, _, _, _, _, icon, _, _, _, name = C_CharacterCreate.GetArchetypeInfo(archetypeID)
	local archetypeButton = CharacterCreateNavigationFrame:GetButtonByIndex(Enum.CharCreateSteps.Archetype)

	if name and archetypeButton then
		archetypeButton.IconAdd:Hide()
		archetypeButton:SetText(string.format(ARCHETYPE_SELECTED_TEXT, name))
		archetypeButton.Icon:SetPortraitTexture("Interface\\Icons\\"..icon)
		archetypeButton.Icon:SetTexCoord(0, 1, 0, 1)
	end

	CharCreateDescriptionFrame:ClearAndSetPoint("TOP", CharCreateMovieFrame, "BOTTOM", 0, -16)
	CharCreateDescriptionFrame:SetHeight(361)
	CharCreateDescriptionFrame:SetArchetype(archetypeID)
	CharCreateDescriptionFrame:Show()

	-- @andrew Disabled because the videos just crash the game for a bunch of people.
	--[[CharCreateMovieFrame:Show()
	CharCreateMovieFrame:StartMovieForArchetype(archetypeID)]]

	C_CharacterCreate.SetSelectedArchetype(CharCreateRoleSelectFrame:GetCurrentIndex(), CharCreateSubroleSelectFrame:GetCurrentIndex(), archetypeID)
end

function CharacterCreate_OnLoad(self)
	self.classButtonPool = CreateFramePool("CheckButton", CharCreateClassFrame, "CharCreateClassButtonTemplate")
	CharacterCreate_CreateClassGuideFrame()
	self:RegisterEvent("RANDOM_CHARACTER_NAME_RESULT");
	self:RegisterEvent("GLUE_UPDATE_EXPANSION_LEVEL");

	self:SetSequence(0);
	self:SetCamera(0);

	CharacterCreate.numRaces = 0;
	CharacterCreate.selectedRace = 0;
	CharacterCreate.numClasses = 0;
	CharacterCreate.selectedClass = 0;
	CharacterCreate.selectedGender = 0;

	SetCharCustomizeFrame("CharacterCreate");

	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		_G["CharCreateCustomizationButton"..i].text:SetText(_G["CHAR_CUSTOMIZATION"..i.."_DESC"]);
	end

	CharacterCreateRandomName:SetParent(CharacterCreateNameEdit)

	-- Color edit box backdrop
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE["Alliance"];
	CharacterCreateNameEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	CharacterCreateNameEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	--[[CharacterCreateNameEdit:SetParent(CharacterCreateFrame)
	CharacterCreateNameEdit:SetPoint("TOPLEFT", CharacterCreateFrame, 635, -30)]]--
	CharCreateCustomizationFrame:SetPoint("RIGHT", CharacterCreateFrame, -50, -10)

	-- load navigation
	CharacterCreateNavigationFrame:RegisterCallback("OnIndexSelected", CharacterCreate_OnStepChanged, self)
	CharacterCreateNavigationFrame:Hide()
	CharCreateArchetypeFrame:RegisterCallback("OnIndexSelected", CharacterCreate_OnArchetypeBaseChanged, self)

	-- set up extra menus
	CharCreateRoleSelectFrame:RegisterCallback("OnIndexSelected", CharacterCreate_OnSelectRole, self)
	CharCreateSubroleSelectFrame:RegisterCallback("OnIndexSelected", CharacterCreate_OnSelectCategory, self)
	CharCreateArchetypeSelectFrame:RegisterCallback("OnIndexSelected", CharacterCreate_OnSelectArchetype, self)

	CharCreatePreviewFrame.previews = { };

	-- custom Lua
	_G["CharCreateMaleButtonNormalTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharCreateFemaleButtonNormalTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharCreateMaleButtonPushedTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharCreateFemaleButtonPushedTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharCreateRandomizeButtonNormalTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharacterCreateRandomNameNormalTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharCreateRandomizeButtonPushedTexture"]:SetDrawLayer("BACKGROUND")
	_G["CharacterCreateRandomNamePushedTexture"]:SetDrawLayer("BACKGROUND")
	--CharCreateMaleButton:Hide()
	--CharCreateFemaleButton:Hide()

	CustomizationBG = CharacterCreateFrame:CreateTexture("CustomizationBG", "BACKGROUND")
	CustomizationBG:SetSize(512, GlueParent:GetHeight())
    CustomizationBG:SetTexture("Interface\\Glues\\CharacterCreate\\Shadowv")
    CustomizationBG:SetPoint("RIGHT")
    CustomizationBG:Hide()

    CharacterCreateFrameFade = CreateFrame("FRAME", "CharacterCreateFrameFade", CharacterCreateFrame)
    CharacterCreateFrameFade:SetPoint("CENTER", 0, 0)
    CharacterCreateFrameFade:SetSize(GlueParent:GetWidth(), GlueParent:GetHeight())
    CharacterCreateFrameFade:SetFrameStrata("DIALOG")
    CharacterCreateFrameFade:SetFrameLevel(10)
    --CharacterCreateFrameFade:Hide()

    --[[CharacterCreateTopNavi = CreateFrame("FRAME", "CharacterCreateTopNavi", CharacterCreateFrame)
    CharacterCreateTopNavi:SetPoint("BOTTOM", 0, 4)
    CharacterCreateTopNavi:SetSize(GlueParent:GetWidth(), 128)

    CharCreateBackButton:Hide()
	CharCreateOkayButton:Hide()

	CharCreateBackButtonTopNavi = CreateFrame("Button", "CharCreateBackButtonTopNavi", CharacterCreateTopNavi, "CharCreateNavButtonTemplate")
	CharCreateBackButtonTopNavi:SetPoint("BOTTOMLEFT", 54, -6)
	CharCreateBackButtonTopNavi:SetText(BACK)
	CharCreateBackButtonTopNavi:SetScript("OnClick", function(self)
		CharCreateBackButton:GetScript("OnClick")(CharCreateBackButton)
	end)

	CharCreateOkayButtonTopNavi = CreateFrame("Button", "CharCreateOkayButtonTopNavi", CharacterCreateTopNavi, "CharCreateNavButtonTemplate")
	CharCreateOkayButtonTopNavi:SetPoint("BOTTOMRIGHT", -52, -6)
	CharCreateOkayButtonTopNavi:SetText("Customize")
	CharCreateOkayButtonTopNavi:SetScript("OnClick", function(self)
		CharCreateOkayButton:GetScript("OnClick")(CharCreateOkayButton)
	end)

	CharacterCreateTopNaviBG = CharacterCreateTopNavi:CreateTexture("CharacterCreateTopNaviBG", "BACKGROUND")
	CharacterCreateTopNaviBG:SetSize(1360, 85)
    CharacterCreateTopNaviBG:SetTexture("Interface\\Glues\\CharacterCreate\\TopNavi")
    CharacterCreateTopNaviBG:SetPoint("BOTTOM")
    CharacterCreateTopNaviBG:SetTexCoord(1,0,1,0)

	CharacterCreateTopNavi.Text = CharacterCreateTopNavi:CreateFontString("CharacterCreateTopNavi.Text", "OVERLAY")
    CharacterCreateTopNavi.Text:SetFontObject(GlueFontNormal)
    CharacterCreateTopNavi.Text:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CharacterCreateTopNavi.Text:SetText("CHARACTER CREATION - |cffFFFFFFSELECT RACE/CLASS|r")
    CharacterCreateTopNavi.Text:SetPoint("BOTTOM", 0, 8)]]--

    --CharacterCreateTopNavi:SetFrameStrata("DIALOG")
    --CharacterCreateTopNavi:SetFrameLevel(10)

	CustomizationBG2 = CharacterCreateFrame:CreateTexture("CustomizationBG2", "BACKGROUND")
	CustomizationBG2:SetSize(GlueParent:GetWidth(), GlueParent:GetHeight())
    CustomizationBG2:SetTexture("Interface\\Glues\\CharacterCreate\\MainShadow")
    CustomizationBG2:SetPoint("CENTER")
    CustomizationBG2:SetAlpha(1)

    CustomizationBGAddRight = CharacterCreateFrame:CreateTexture("CustomizationBGAddRight", "BACKGROUND")
	CustomizationBGAddRight:SetSize(300, GlueParent:GetHeight())
    CustomizationBGAddRight:SetTexture("Interface\\Glues\\CharacterCreate\\Shadowv")
    CustomizationBGAddRight:SetPoint("RIGHT")
    CustomizationBGAddRight:SetAlpha(1)

    CustomizationBGAddRight = CharacterCreateFrame:CreateTexture("CustomizationBGAddRight2", "BACKGROUND")
	CustomizationBGAddRight:SetSize(300, GlueParent:GetHeight())
    CustomizationBGAddRight:SetTexture("Interface\\Glues\\CharacterCreate\\Shadowv")
    CustomizationBGAddRight:SetPoint("RIGHT")
    CustomizationBGAddRight:SetAlpha(1)

    CustomizationBGAddLeft = CharacterCreateFrame:CreateTexture("CustomizationBGAddLeft", "BACKGROUND")
	CustomizationBGAddLeft:SetSize(300, GlueParent:GetHeight())
    CustomizationBGAddLeft:SetTexture("Interface\\Glues\\CharacterCreate\\Shadowv")
    CustomizationBGAddLeft:SetPoint("LEFT")
    CustomizationBGAddLeft:SetTexCoord(1, 0, 1, 0)
    CustomizationBGAddLeft:SetAlpha(1)

	CharacterCreateFrameFadeBG = CharacterCreateFrameFade:CreateTexture("CharacterCreateFrameFadeBG", "OVERLAY")
	CharacterCreateFrameFadeBG:SetSize(GlueParent:GetWidth(), GlueParent:GetHeight())
    CharacterCreateFrameFadeBG:SetTexture("Interface\\Glues\\CharacterCreate\\Black")
    CharacterCreateFrameFadeBG:SetPoint("CENTER")

	CustomizationLogoAlliance = CharacterCreateFrame:CreateTexture("CustomizationLogoAlliance", "ARTWORK")
	CustomizationLogoAlliance:SetSize(100, 100)
    CustomizationLogoAlliance:SetTexture("Interface\\Glues\\CharacterCreate\\AllianceLogo")
    CustomizationLogoAlliance:SetPoint("TOPLEFT", -16, 16)

	CustomizationTextAlliance = CharacterCreateFrame:CreateFontString("CustomizationTextAlliance", "OVERLAY")
    CustomizationTextAlliance:SetFontObject(GlueFontNormal)
    CustomizationTextAlliance:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CustomizationTextAlliance:SetText(string.upper(ALLIANCE))
    CustomizationTextAlliance:SetPoint("LEFT", CustomizationLogoAlliance, "RIGHT", -24, 0)

	CustomizationLogoHorde = CharacterCreateFrame:CreateTexture("CustomizationLogoHorde", "ARTWORK")
	CustomizationLogoHorde:SetSize(100, 100)
    CustomizationLogoHorde:SetTexture("Interface\\Glues\\CharacterCreate\\HordeLogo")
    CustomizationLogoHorde:SetPoint("TOPRIGHT", 16, 16)

	CustomizationTextHorde = CharacterCreateFrame:CreateFontString("CustomizationTextHorde", "OVERLAY")
    CustomizationTextHorde:SetFontObject(GlueFontNormal)
    CustomizationTextHorde:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CustomizationTextHorde:SetText(string.upper(HORDE))
    CustomizationTextHorde:SetPoint("RIGHT", CustomizationLogoHorde, "LEFT", 24, 0)

	CharCreateMaleButton.nameFrame.text:SetText(MALE)
	CharCreateMaleButton.nameFrame:Show()

	CharCreateFemaleButton.nameFrame.text:SetText(FEMALE)
	CharCreateFemaleButton.nameFrame:Show()

	--[[CustomizationLogoClass = CharacterCreateFrame:CreateTexture("CustomizationLogoClass", "ARTWORK")
	CustomizationLogoClass:SetSize(100, 100)
    --CustomizationLogoClass:SetTexture("Interface\\Glues\\CharacterCreate\\ClassLogo")
    CustomizationLogoClass:SetPoint("TOP", -16, 16)

	CustomizationTextClass = CharacterCreateFrame:CreateFontString("CustomizationTextClass", "OVERLAY")
    CustomizationTextClass:SetFontObject(GlueFontHighlight)
    CustomizationTextClass:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CustomizationTextClass:SetText(string.upper("class"))
    CustomizationTextClass:SetPoint("CENTER", CustomizationLogoClass, "RIGHT", -24, 0)]]--

	CustomizationLineBottom = CharacterCreateFrame:CreateTexture("CustomizationLineBottom", "ARTWORK")
	CustomizationLineBottom:SetSize(GlueParent:GetWidth(), 96)
    CustomizationLineBottom:SetTexture("Interface\\Glues\\CharacterCreate\\bottomline")
    CustomizationLineBottom:SetPoint("BOTTOM", 0, 0)

	CustomizationLineTop = CharacterCreateFrame:CreateTexture("CustomizationLineTop", "ARTWORK")
	CustomizationLineTop:SetSize(GlueParent:GetWidth(), 96)
    CustomizationLineTop:SetTexture("Interface\\Glues\\CharacterCreate\\bottomline")
    CustomizationLineTop:SetPoint("TOP", 0, 0)
    CustomizationLineTop:SetTexCoord(1,0,1,0)

    --CharacterCreateNameEdit:SetScript("OnTextChanged", CharCreationNameCheck)
    --GlueFrameFadeOut(CharacterCreateFrameFade, 0.5)
end

function CharCustomizeButtonClick(id, button)
	if (button == 'LeftButton') then
		for i = 1, math.random(1, 5) do
			CharacterCustomization_Left(id)
		end
	elseif (button == 'RightButton') then
		for i = 1, math.random(1, 5) do
			CharacterCustomization_Right(id)
		end
	end

	if (id > 1) then
		SetFaceCustomizeCamera(true)
	else
		SetFaceCustomizeCamera(false)
	end

	-- CycleCharCustomization(id, 1);
	--[[FeatureType = id
	for i=1,5 do
		_G["CharCreateCustomizationButton"..i]:SetChecked(0);
	end
	_G["CharCreateCustomizationButton"..id]:SetChecked(1);]]

end

function CharacterCreate_RefreshClassButtons(self)
	local isCoA = C_CharacterCreate.CanCreateCoA()
	local isClassicClass = C_CharacterCreate.CanCreateWCR()
	local canCreateHero = C_CharacterCreate.CanCreateHero()

	CharCreateSwapClassesButton:SetShown(C_Realm.IsDevelopment() and isCoA and (isClassicClass or canCreateHero))

	if isCoA and isClassicClass then
		local _, _, classIndex = GetSelectedClass()

		if (classIndex == Enum.Class.HERO) then
			CharacterCreate_ShowFreepickClasses(self)
		elseif classIndex >= Enum.Class.CustomStart then
			CharacterCreate_ShowCoAClasses(self)
		else
			CharacterCreate_ShowRegularClasses(self)
		end
	elseif isCoA then
		CharacterCreate_ShowCoAClasses(self)
	elseif isClassicClass then
		CharacterCreate_ShowRegularClasses(self)
	elseif canCreateHero then
		CharacterCreate_ShowFreepickClasses(self)
	end
end

function RefreshSelectedClass()
	local classID = select(3, GetSelectedClass())
	if not CharacterCreateUtil.IsRaceClassEnabledAndValid(CharacterCreate.selectedRace, classID) then
		classID = CharacterCreateUtil.GetRandomAvailableClassForRace(CharacterCreate.selectedRace)
		SetSelectedClass(classID)
		SetCharacterClass(classID)
	end
    
	--CharacterCreate_RefreshClassButtons(CharacterCreate) -- TODO: Review, causes crash?
end

function CharacterCreate_OnShow()
	NewCharacterSetupUtil.ClearPendingData()
	for i=1, MAX_RACES, 1 do
		local button = _G["CharCreateRaceButton"..i]
		button:EnableMouse(true)
		button:Enable()
		SetButtonDesaturated(button, false)
	end

	if ( PAID_SERVICE_TYPE ) then
		CustomizeExistingCharacter( PAID_SERVICE_CHARACTER_ID );
		CharacterCreateNameEdit:SetText( PaidChange_GetName() );
		CharCreateArchetypeFrame:GoToIndex(Enum.CharCreateArchetypeBases.Freepick)
	else
		NewCharacterSetupUtil.SetPendingKeyValue("enableTransmog", true)
        NewCharacterSetupUtil.SetPendingKeyValue("enableLevelScaling", true)
		--randomly selects a combination
		ResetCharCustomize();
		CharacterCreateNameEdit:SetText("");
		CharCreateRandomizeButton:Show();
	end

	CharCreateShowEquipmentToggle:SetChecked(true)

	if not CharCreateArchetypeFrame:GetCurrentIndex() or (CharCreateArchetypeFrame:GetCurrentIndex() ~= Enum.CharCreateArchetypeBases.Freepick) then
		CharCreateArchetypeFrame:GoToIndex(Enum.CharCreateArchetypeBases.Freepick)
	end

	CharacterCreateEnumerateRaces(GetAvailableRaces());
	SetCharacterRace(GetSelectedRace());
	HandleFactionBackground()
	GlueFrameFadeOut(CharacterCreateFrameFade, 0.5)

	CharacterCreate_RefreshClassButtons(CharacterCreate)

	if C_CharacterCreate.CanCreateHero() then
		SetSelectedClass(HERO_CLASS_ID)
		SetCharacterClass(HERO_CLASS_ID)

		if not PAID_SERVICE_TYPE then
			if C_CharacterCreate.CanCreateArchetype() then
				CharCreateArchetypeFrame:GoToIndex(Enum.CharCreateArchetypeBases.UseArchetype)
			else
				CharCreateArchetypeFrame:GoToIndex(Enum.CharCreateArchetypeBases.Freepick)
			end
		end
	else
		local _,_,index = GetSelectedClass()
		SetCharacterClass(index)
	end

	SetCharacterGender(GetSelectedSex());
	--end

	-- Hair customization stuff
	CharacterCreate_UpdateHairCustomization();
	SetCharacterCreateFacing(-15);
	
	CharacterChangeFixup(); -- this will fix class if druid is a wrong class for this realm

	CharCreateRoleSelectFrame:ClearSelected()
	CharCreateSubroleSelectFrame:ClearAll()
	CharCreateArchetypeSelectFrame:ClearAll()

	if CharacterCreateFrame.state and (CharacterCreateFrame.state ~= CHAR_CREATE_STEPS_DEFAULT[1]) then
		CharacterCreateNavigationFrame:GoToIndex(CHAR_CREATE_STEPS_DEFAULT[1])
	end
end

function CharacterCreate_OnHide()
	PAID_SERVICE_CHARACTER_ID = nil;
	PAID_SERVICE_TYPE = nil;
	if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
		CharacterCreate_Back();
	end
	-- character previews will need to be redone if coming back to character create. One reason is all the memory used for
	-- tracking the frames (on the c side) will get released if the user returns to the login screen
	CharCreatePreviewFrame.rebuildPreviews = true;
	CharCreate_ResetCamera()
end

function CharacterCreate_OnEvent(event, arg1, arg2, arg3)
	if ( event == "RANDOM_CHARACTER_NAME_RESULT" ) then
		if ( arg1 == 0 ) then
			-- Failed.  Generate a random name locally.
			CharacterCreateNameEdit:SetText(GenerateRandomName());
		else
			-- Succeeded.  Use what the server sent.
			CharacterCreateNameEdit:SetText(arg2);
		end
		CharacterCreateRandomName:Enable();
		CharCreateOkayButton:Enable();
		PlaySound("gsCharacterCreationLook");
	elseif ( event == "GLUE_UPDATE_EXPANSION_LEVEL" ) then
		-- Expansion level changed while online, so enable buttons as needed
		if ( CharacterCreateFrame:IsShown() ) then
			CharacterCreateEnumerateRaces(GetAvailableRaces());
			CharacterCreate_RefreshClassButtons(CharacterCreate)
		end
	end
end

function CharacterCreateFrame_OnMouseWheel(delta)
	if CharacterCreateFrame.state ~= Enum.CharCreateSteps.Customization then
		return
	end

	local _, fileString = GetNameForRace()
	local zoomInValue = math.abs(ZoomController.zoom - (CHAR_CREATE_CAMERA_ZOOM_IN[fileString] or CHAR_CREATE_ZOOM))*0.5
	local zoomOutValue = ZoomController.zoom*0.5

	if delta > 0 then
		ZoomController.manualZoomOut = nil
		ZoomController.manualZoomIn = ZoomController.zoom + zoomInValue
		IS_ZOOMED = true
	else
		ZoomController.manualZoomIn = nil 
		ZoomController.manualZoomOut = math.max(0, ZoomController.zoom - zoomOutValue)
		IS_ZOOMED = false
	end
	
	ZoomController:Show()
end

function CharacterCreateFrame_OnMouseDown(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = GetCursorPosition();
		CHARACTER_CREATE_INITIAL_FACING = GetCharacterCreateFacing();
	end
end

function CharacterCreateFrame_OnMouseUp(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = nil
	end
end

function CharacterCreateFrame_OnUpdate(self, elapsed)
	if ( CHARACTER_CREATE_ROTATION_START_X ) then
		local x = GetCursorPosition();
		local diff = (x - CHARACTER_CREATE_ROTATION_START_X) * CHARACTER_ROTATION_CONSTANT;
		CHARACTER_CREATE_ROTATION_START_X = GetCursorPosition();
		SetCharacterCreateFacing(GetCharacterCreateFacing() + diff);
		CharCreate_RotatePreviews();
	end
	CharacterCreateWhileMouseDown_Update(elapsed);
end

function CharacterCreateEnumerateRaces(...)
	CharacterCreate.numRaces = select("#", ...)/3;
	if ( CharacterCreate.numRaces > MAX_RACES ) then
		message("Too many races!  Update MAX_RACES");
		return;
	end
	local button, gender;
	local index = 1;
	local selectedSex = GetSelectedSex();
	if ( selectedSex == SEX_MALE ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end

	for i=1, select("#", ...), 3 do
		local raceName, raceEnglishName, enabled = select(i, ...)
		enabled = toboolean(enabled)
		raceEnglishName = raceEnglishName:upper()
		button = _G["CharCreateRaceButton"..index]
		
		button:SetRace(raceName, raceEnglishName, gender, enabled)
		index = index + 1
	end

	for i = CharacterCreate.numRaces + 1, MAX_RACES, 1 do
		_G["CharCreateRaceButton"..i]:Hide()
	end
end

function CharacterCreate_ShowRegularClasses(self)
	CharCreateClassFrame:Show()
	CharCreateArchetypeFrame:Hide()
	CharacterCreate.classGuideActive = false
	CharacterCreate_SetClassGuideEntryShown(false)
	CharacterCreate_HideClassGuide()
	CharCreateClassContainer:Show()

	local pool = self.classButtonPool
	pool:ReleaseAll()

	CharCreateClassContainer.Row2:Hide()

	local layoutIndex = 0
	local classID, button, className, classFile, enabled
	for i = 1, 11 do
		classID = Enum.Class[CLASSIC_CLASS_ORDER[i]]
		if C_CharacterCreate.CanCreateClass(classID) then
			layoutIndex = layoutIndex + 1
			button = pool:Acquire()
			button:SetID(classID)
			button.layoutIndex = layoutIndex
			button:SetParent(CharCreateClassContainer.Row1)
			button:Show()
			className, classFile = GetClassInfo(classID)
			button:SetClass(className, classFile, true)
		end
	end
	
	CharCreateClassContainer.Row1:MarkDirty()
	CharCreateClassContainer.Row2:MarkDirty()
	CharCreateClassContainer:MarkDirty()

	CharacterCreate.classesVisible = "REGULAR"
end

function CharacterCreate_ShowCoAClasses(self)
	CharCreateClassFrame:Show()
	CharCreateArchetypeFrame:Hide()

	local pool = self.classButtonPool
	pool:ReleaseAll()

	if CharacterCreate.classGuideActive and CharacterCreate_HasClassGuideData() then
		CharacterCreate_SetClassGuideEntryShown(false)
		CharCreateClassContainer:Hide()
		CharacterCreate_UpdateClassGuideFrame()
		CharacterCreate_ShowClassGuideClasses(self)
		self.classesVisible = "COA"
		return
	end

	CharacterCreate.classGuideActive = false
	CharacterCreate_SetClassGuideEntryShown(true)
	CharacterCreate_HideClassGuide()
	CharCreateClassContainer:Show()

	CharCreateClassContainer.Row2:Show()

	local numInRow1 = 10
	local layoutIndex = 0
	local classID, row, button, className, classFile, enabled
	for i = 1, 21 do
		classID = Enum.Class[COA_CLASS_ORDER[i]]
		if classID and C_CharacterCreate.CanCreateClass(classID) then
			className, classFile, enabled = GetClassInfo(classID)
			if className and classFile then
				layoutIndex = layoutIndex + 1
				button = pool:Acquire()
				if numInRow1 > 0 then
					row = CharCreateClassContainer.Row1
					numInRow1 = numInRow1 - 1
					button.layoutIndex = layoutIndex
				else
					row = CharCreateClassContainer.Row2
					button.layoutIndex = layoutIndex - 10
				end
				button:SetID(classID)
				button:SetParent(row)
				button:Show()
				button:SetClass(className, classFile, enabled)
			end
		end
	end

	CharCreateClassContainer.Row1:MarkDirty()
	CharCreateClassContainer.Row2:MarkDirty()
	CharCreateClassContainer:MarkDirty()

	self.classesVisible = "COA"
end

function CharacterCreate_ShowFreepickClasses(self)
	CharCreateClassFrame:Hide()
	CharacterCreate.classGuideActive = false
	CharacterCreate_SetClassGuideEntryShown(false)
	CharacterCreate_HideClassGuide()
	
	if C_CharacterCreate.CanCreateArchetype() then
		CharCreateArchetypeFrame:Show()
	else
		CharCreateArchetypeFrame:Hide()
	end

	CharacterCreate.classesVisible = "FREEPICK"
end

function CharacterCreate_SwapClasses()
	if (CharacterCreate.classesVisible == "FREEPICK") then
		CharacterCreate_ShowRegularClasses(CharacterCreate)
		return
	elseif (CharacterCreate.classesVisible == "REGULAR") then
		CharacterCreate_ShowCoAClasses(CharacterCreate)
	elseif (CharacterCreate.classesVisible == "COA") then
		CharacterCreate_ShowFreepickClasses(CharacterCreate)
	end
end

function SetCharacterRace(id)

	CharacterCreate.selectedRace = id;
	for i=1, CharacterCreate.numRaces, 1 do
		local button = _G["CharCreateRaceButton"..i];
		if ( i == id ) then
			button:SetChecked(1);
		else
			button:SetChecked(0);
		end
	end

	local name, faction = GetFactionForRace(CharacterCreate.selectedRace);

	if faction == nil then
		faction = "Alliance";
	end

	-- Set background

	--HandleFactionBackground()

	-- Set backdrop colors based on faction
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE[faction];
	--CharCreateRaceFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);
	--CharCreateClassFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);
	--CharCreateCustomizationFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);
	--harCreatePreviewFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);
	CharCreateCustomizationFrameBanner:SetVertexColor(backdropColor[10], backdropColor[11], backdropColor[12]);
	CharacterCreateNameEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	--CharCreateRaceInfoFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);
	--CharCreateClassInfoFrame.factionBg:SetGradient("VERTICAL", 0, 0, 0, backdropColor[7], backdropColor[8], backdropColor[9]);

	-- race info
	local frame = CharCreateRaceInfoFrame;
	local race, fileString = GetNameForRace();
	frame.title:SetText(race);
	fileString = strupper(fileString);
	local gender;
	if ( GetSelectedSex() == SEX_MALE ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end
	local raceText = _G["RACE_INFO_"..fileString];
	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
	abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
	end
	CharCreateRaceInfoFrameScrollFrameScrollBar:SetValue(0);
	local text
	text = GetFlavorText("RACE_INFO_"..strupper(fileString), GetSelectedSex())
	if not text then
		text = "Not in GlueXML."
	end
	CharCreateRaceInfoFrame.scrollFrame.scrollChild.infoText:SetText(text.."|n|n");
	if ( abilityText and abilityText ~= "" ) then
		CharCreateRaceInfoFrame.scrollFrame.scrollChild.bulletText:SetText(abilityText);
	else
		CharCreateRaceInfoFrame.scrollFrame.scrollChild.bulletText:SetText("");
	end

	CharacterCreate_UpdateNavigtationRaceButton()
end

function SetCharacterClass(id)
	CharacterCreate.selectedClass = id;
	EventRegistry:TriggerEvent("CharacterCreate.ClassChanged", id)

	-- class info
	local frame = CharCreateClassInfoFrame;
	local className, classFileName, classIndex, tank, healer, damage = GetSelectedClass();
	local abilityIndex = 0;
	if not classFileName then
		classFileName = "WARRIOR"
	end
	if classFileName ~= "HERO" then
		C_CharacterCreate.PreviewClassOutfit(classFileName)
	else
		C_CharacterCreate.ClearClassPreview()
	end
	local tempText = _G["CLASS_INFO_"..classFileName..abilityIndex];
	abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["CLASS_INFO_"..classFileName..abilityIndex];
	end
	CharCreateClassInfoFrame.title:SetText(className);
	CharCreateClassInfoFrame.scrollFrame.scrollChild.bulletText:SetText(abilityText);
	CharCreateClassInfoFrame.scrollFrame.scrollChild.infoText:SetText(GetFlavorText("CLASS_"..strupper(classFileName), GetSelectedSex()).."|n|n");
	CharCreateClassInfoFrameScrollFrameScrollBar:SetValue(0);

	if (classIndex ~= Enum.Class.HERO) then
		CharCreateArchetypeFrame:GoToIndex(Enum.CharCreateArchetypeBases.Freepick)
	end
end

function CharacterCreate_OnChar()
end

function CharacterCreate_OnKeyDown(key)
	if ( key == "ESCAPE" ) then
		CharacterCreate_Back();
	elseif ( key == "ENTER" ) then
		CharacterCreate_Forward();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function CharacterCreate_UpdateModel(self)
	UpdateCustomizationScene();
	self:AdvanceTime();
end

function CharacterCreate_Finish()
	PlaySound("gsCharacterCreationCreateChar");

	-- If something disabled this button, ignore this message.
	-- This can happen if you press enter while it's disabled, for example.
	if ( not CharCreateOkayButton:IsEnabled() ) then
		return;
	end

	if ( PAID_SERVICE_TYPE ) then
		GlueDialog_Show("CONFIRM_PAID_SERVICE");
	else
		-- if using templates, pandaren must pick a faction
		--local _, faction = GetFactionForRace(CharacterCreate.selectedRace);

		CreateCharacter(CharacterCreateNameEdit:GetText());

		TutorialExperienceEventListener:Show()
		
		local archetypeID = CharCreateArchetypeSelectFrame:GetCurrentIndex()

		if archetypeID then
			local buildID = C_CharacterCreate.GetArchetypeInfo(archetypeID)
			if buildID then
				NewCharacterSetupUtil.SetPendingKeyValue("archetypeBuildID", buildID)
			end
		end
	end
end

function CharacterCreate_Back()
	local prevStep = CharacterCreateNavigationFrame:GetPrevIndex()

	if CharacterCreate.classGuideActive and CharacterCreateFrame.state == Enum.CharCreateSteps.NameEdit and not prevStep then
		PlaySound("gsCharacterCreationCancel");
		CharacterCreateNavigationFrame:GoToIndex(Enum.CharCreateSteps.ClassRace)
		return;
	end

	if CharacterCreate.classGuideActive and CharacterCreateFrame.state == Enum.CharCreateSteps.ClassRace then
		PlaySound("gsCharacterCreationCancel");
		CharacterCreate_ClassGuideBack()
		return;
	end

	if (prevStep) then
		PlaySound("gsCharacterCreationCancel");
		CharacterCreateNavigationFrame:GoToIndex(prevStep)
		return;
	end

	PlaySound("gsCharacterCreationCancel");
	CHARACTER_SELECT_BACK_FROM_CREATE = true;
	NewCharacterSetupUtil.ClearPendingData()
	SetGlueScreen("charselect");
end

function CharacterCreate_UpdateFacialHairCustomization()
	if ( GetFacialHairCustomization() == "NONE" ) then
		CharacterCustomizationButtonFrame5:Hide();
		--CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -5);
	else
		CharacterCustomizationButtonFrame5Text:SetText(_G["FACIAL_HAIR_"..GetFacialHairCustomization()]);
		CharacterCustomizationButtonFrame5:Show();
		--CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -5);
	end
end

function CharacterCreate_UpdateHairCustomization()
	if not _G["HAIR_"..GetHairCustomization().."_STYLE"] or _G["HAIR_"..GetHairCustomization().."_STYLE"] == "" then
		CharCreateCustomizationButton3:Hide()
		CharCreateCustomizationButton4:SetPoint("TOP", CharCreateCustomizationButton2, "BOTTOM", 0, -20)
	else
		CharCreateCustomizationButton3:Show()
		CharCreateCustomizationButton3.text:SetText(_G["HAIR_"..GetHairCustomization().."_STYLE"])
		--CharCreateCustomizationButton4:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, -20)
	end

	if not _G["HAIR_"..GetHairCustomization().."_COLOR"] or _G["HAIR_"..GetHairCustomization().."_COLOR"] == "" then
		CharCreateCustomizationButton4:Hide()
		if CharCreateCustomizationButton3:IsShown() then
			CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
		else
			CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, 0)
		end
	else
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText(_G["HAIR_"..GetHairCustomization().."_COLOR"])
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
	end

	if not _G["FACIAL_HAIR_"..GetFacialHairCustomization()] or _G["FACIAL_HAIR_"..GetFacialHairCustomization()] == "" then
		CharCreateCustomizationButton5:Hide()
	else
		CharCreateCustomizationButton5:Show()
		CharCreateCustomizationButton5.text:SetText(_G["FACIAL_HAIR_"..GetFacialHairCustomization()])
	end

end

function CharacterCreate_Forward()
	local nextStep = CharacterCreateNavigationFrame:GetNextIndex()

	if CharCreateOkayButton:IsEnabled() == 0 then
		return
	end

	if CharacterCreate.classGuideActive and CharacterCreateFrame.state == Enum.CharCreateSteps.ClassRace then
		if not CharacterCreate.selectedClassGuideClassID then
			return
		end

		PlaySound("gsCharacterSelectionCreateNew");
		CharCreateOkayButton:Disable()
		CharacterCreate_LoadNavigation(CHAR_CREATE_STEPS_CLASS_GUIDE)
		CharacterCreateNavigationFrame:GoToIndex(Enum.CharCreateSteps.NameEdit)
		return
	end

	if (nextStep) then
		PlaySound("gsCharacterSelectionCreateNew");
		CharCreateOkayButton:Disable()
		CharacterCreateNavigationFrame:GoToIndex(nextStep)
		return;
	end

	CharacterCreate_Finish()
end

function CharCreateCustomizationFrame_OnShow ()
	-- reset size/tex coord to default to facilitate switching between genders for Pandaren
	CharCreateCustomizationFrameBanner:SetSize(BANNER_DEFAULT_SIZE[1], BANNER_DEFAULT_SIZE[2]);
	CharCreateCustomizationFrameBanner:SetTexCoord(BANNER_DEFAULT_TEXTURE_COORDS[1], BANNER_DEFAULT_TEXTURE_COORDS[2], BANNER_DEFAULT_TEXTURE_COORDS[3], BANNER_DEFAULT_TEXTURE_COORDS[4]);

	-- check each button and hide it if there are no values select
	local resize = 0;
	local lastGood = 0;
	local isSkinVariantHair = false --GetSkinVariationIsHairColor(CharacterCreate.selectedRace);
	local isDefaultSet = 0;
	local checkedButton = 1;

	-- check if this was set, if not, default to 1
	if ( CharacterCreateFrame.customizationType == 0 or CharacterCreateFrame.customizationType == nil ) then
		CharacterCreateFrame.customizationType = 1;
	end
	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		if ( ( --[[GetNumFeatureVariationsForType(i)]]5 <= 1 ) or ( isSkinVariantHair and i == CHAR_CUSTOMIZE_HAIR_COLOR ) ) then
			resize = resize + 1;
			_G["CharCreateCustomizationButton"..i]:Hide();
		else
			_G["CharCreateCustomizationButton"..i]:Show();
			--_G["CharCreateCustomizationButton"..i]:SetChecked(0); -- we will handle default selection
			-- this must be done since a selected button can 'disappear' when swapping genders
			if ( isDefaultSet == 0 and CharacterCreateFrame.customizationType == i) then
				isDefaultSet = 1;
				checkedButton = i;
			end
			-- set your anchor to be the last good, this currently means button 1 HAS to be shown
			if (i > 1) then
				_G["CharCreateCustomizationButton"..i]:SetPoint( "TOP",_G["CharCreateCustomizationButton"..lastGood]:GetName() , "BOTTOM");
			end
			lastGood = i;
		end
	end

	if (isDefaultSet == 0) then
		CharacterCreateFrame.customizationType = lastGood;
		checkedButton = lastGood;
	end
	--_G["CharCreateCustomizationButton"..checkedButton]:SetChecked(1);

	if (resize > 0) then
	-- we need to resize and remap the banner texture
		local buttonx, buttony = CharCreateCustomizationButton1:GetSize()
		local screenamount = resize*buttony;
		print(screenamount);
		local frameX, frameY = CharCreateCustomizationFrameBanner:GetSize();
		local pctShrink = .2*resize;
		local uvXDefaultSize = BANNER_DEFAULT_TEXTURE_COORDS[2] - BANNER_DEFAULT_TEXTURE_COORDS[1];
		local uvYDefaultSize = BANNER_DEFAULT_TEXTURE_COORDS[4] - BANNER_DEFAULT_TEXTURE_COORDS[3];
		local newYUV = pctShrink*uvYDefaultSize + BANNER_DEFAULT_TEXTURE_COORDS[3];
		-- end coord stay the same
		CharCreateCustomizationFrameBanner:SetTexCoord(BANNER_DEFAULT_TEXTURE_COORDS[1], BANNER_DEFAULT_TEXTURE_COORDS[2], newYUV, BANNER_DEFAULT_TEXTURE_COORDS[4]);
		print(pctShrink);
		CharCreateCustomizationFrameBanner:SetSize(frameX, frameY - screenamount);
		print(CharCreateCustomizationFrameBanner:GetTexCoord());
	end

	--CharCreateRandomizeButton:SetPoint("TOP", _G["CharCreateCustomizationButton"..lastGood]:GetName(), "BOTTOM", 0, 0);
end

function CharacterClass_OnClick(self, id)
	if( self:IsEnabled() ) then
		PlaySound("gsCharacterCreationClass");
		local _,_,currClass = GetSelectedClass();
		if ( currClass ~= id ) then
			SetSelectedClass(id);
			SetCharacterClass(id);
			SetCharacterRace(GetSelectedRace());
			CharacterChangeFixup();
		else
			self:SetChecked(1);
		end
	else
		self:SetChecked(0);
	end
end

function CharacterRace_OnClick(self, id, forceSelect)
	if( self:IsEnabled() == 1 ) then
		PlaySound("gsCharacterCreationClass");
		if ( GetSelectedRace() ~= id or forceSelect ) then
			local isClassGuideClassSelection = C_CharacterCreate.CanCreateCoA()
				and CharacterCreate.classGuideActive
				and CharacterCreate.selectedClassGuideSubroleID
				and (CharacterCreateFrame.state == Enum.CharCreateSteps.ClassRace
					or CharacterCreateFrame.state == Enum.CharCreateSteps.Archetype)
			local selectedGuideClassID = CharacterCreate.selectedClassGuideClassID

			SetSelectedRace(id);
			SetCharacterRace(id);
			if isClassGuideClassSelection then
				CharacterCreateEnumerateRaces(GetAvailableRaces());
				SetCharacterRace(GetSelectedRace());
				SetCharacterCreateFacing(-15);

				if selectedGuideClassID and CharacterCreate_ClassGuideClassIsAvailableForRace(selectedGuideClassID, CharacterCreate.selectedRace) then
					CharacterCreate.selectedClassGuideClassID = selectedGuideClassID
					SetSelectedClass(selectedGuideClassID)
					SetCharacterClass(selectedGuideClassID)
					CharCreate_EnableNextButton(true)
				else
					local fallbackClassID = CharacterCreate_GetFirstAvailableClassGuideClassForRace(CharacterCreate.selectedRace)
					CharacterCreate.selectedClassGuideClassID = fallbackClassID
					if fallbackClassID then
						SetSelectedClass(fallbackClassID)
						SetCharacterClass(fallbackClassID)
						CharCreate_EnableNextButton(true)
					else
						local _,_,classIndex = GetSelectedClass();
						SetCharacterClass(classIndex)
						CharCreateOkayButton:Disable()
					end
				end

				CharacterCreate_RefreshClassButtons(CharacterCreate)
				CharacterCreate_UpdateHairCustomization();
				CharacterChangeFixup();
				return
			end

			SetCharacterGender(GetSelectedSex());
			SetCharacterCreateFacing(-15);
			CharacterCreate_RefreshClassButtons(CharacterCreate)
			local _,_,classIndex = GetSelectedClass();
			if ( PAID_SERVICE_TYPE ) then
				classIndex = PaidChange_GetCurrentClassIndex();
				SetSelectedClass(classIndex);	-- selecting a race would have changed class to default
			end
			SetCharacterClass(classIndex);

			-- Hair customization stuff
			CharacterCreate_UpdateHairCustomization();

			CharacterChangeFixup();
		else
			self:SetChecked(1);
		end
	else
		self:SetChecked(0);
	end
end

function SetCharacterGender(sex)
	local gender;

	if ( sex == SEX_MALE ) then
		CharCreateMaleButton:SetChecked(1);
		CharCreateFemaleButton:SetChecked(0);
	else
		CharCreateMaleButton:SetChecked(0);
		CharCreateFemaleButton:SetChecked(1);
	end
	SetSelectedSex(sex);

	-- Update race images to reflect gender
	CharacterCreateEnumerateRaces(GetAvailableRaces());
	CharacterCreate_RefreshClassButtons(CharacterCreate)
 	SetCharacterRace(GetSelectedRace());

	local _,_,classIndex = GetSelectedClass();
	if ( PAID_SERVICE_TYPE ) then
		classIndex = PaidChange_GetCurrentClassIndex();
		-- PandarenFactionButtons_SetTextures();
	end
	SetCharacterClass(classIndex);

	CharacterCreate_UpdateHairCustomization();
	CharacterChangeFixup();

	-- Update preview models if on customization step
	if ( CharCreatePreviewFrame:IsShown() ) then
		CharCreateCustomizationFrame_OnShow(); -- buttons may need to reset for dirty Pandarens
		CharCreate_PrepPreviewModels();
		CharCreate_ResetFeaturesDisplay();
	end
end

local function CharacterCustomization_Cycle(id, direction)
	C_CharacterCreate.CycleCustomizationSkipLocked(id, direction)
end

function CharacterCustomization_Left(id)
	PlaySound("gsCharacterCreationLook");
	CharacterCustomization_Cycle(id, -1);
	CharacterCreate_UndressCustomizationHeadSlot()
	if (id > 1) then
		SetFaceCustomizeCamera(true)
	else
		SetFaceCustomizeCamera(false)
	end
end

function CharacterCustomization_Right(id)
	PlaySound("gsCharacterCreationLook");
	CharacterCustomization_Cycle(id, 1);
	CharacterCreate_UndressCustomizationHeadSlot()
	if (id > 1) then
		SetFaceCustomizeCamera(true)
	else
		SetFaceCustomizeCamera(false)
	end
end

function CharacterCreate_GenerateRandomName(button)
	CharacterCreateNameEdit:SetText(GetRandomName());
end

function CharacterCreate_Randomize()
	PlaySound("gsCharacterCreationLook");
	RandomizeCharCustomization();
	CharCreate_ResetFeaturesDisplay();
	CharacterCreate_UpdateCustomizationEquipment();
end

function CharacterCreateRotateRight_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterCreateFacing(GetCharacterCreateFacing() + CHARACTER_FACING_INCREMENT);
		CharCreate_RotatePreviews();
	end
end

function CharacterCreateRotateLeft_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterCreateFacing(GetCharacterCreateFacing() - CHARACTER_FACING_INCREMENT);
		CharCreate_RotatePreviews();
	end
end

function SetButtonDesaturated(button, desaturated)
	if ( not button ) then
		return;
	end
	local icon = button:GetNormalTexture();
	if ( not icon ) then
		return;
	end

	icon:SetDesaturated(desaturated);
end

function GetFlavorText(tagname, sex)
	local primary, secondary;
	if ( sex == SEX_MALE ) then
		primary = "";
		secondary = "_FEMALE";
	else
		primary = "_FEMALE";
		secondary = "";
	end
	local text = _G[tagname..primary];
	if ( (text == nil) or (text == "") ) then
		text = _G[tagname..secondary];
	end
	return text;
end

function CharacterChangeFixup()
	if ( PAID_SERVICE_TYPE ) then
		-- no class changing as a paid service
		EventRegistry:TriggerEvent("CharacterCreate.PaidServiceActive")
		for i=1, MAX_RACES, 1 do
			local allow = false;
			if ( PAID_SERVICE_TYPE == PAID_FACTION_CHANGE ) then
				local faction = GetFactionForRace(PaidChange_GetCurrentRaceIndex());
				if ( (i == PaidChange_GetCurrentRaceIndex()) or ((GetFactionForRace(i) ~= faction) and (IsRaceClassValid(i,CharacterCreate.selectedClass))) ) then
					allow = true;
				end
			elseif ( PAID_SERVICE_TYPE == PAID_RACE_CHANGE ) then
				local faction = GetFactionForRace(PaidChange_GetCurrentRaceIndex());
				if ( (i == PaidChange_GetCurrentRaceIndex()) or ((GetFactionForRace(i) == faction) and (IsRaceClassValid(i,CharacterCreate.selectedClass))) ) then
					allow = true
				end
			elseif ( PAID_SERVICE_TYPE == PAID_CHARACTER_CUSTOMIZATION ) then
				if ( i == CharacterCreate.selectedRace ) then
					allow = true
				end
			end

			if (not allow) then
				local button = _G["CharCreateRaceButton"..i];
				button:Disable();
				SetButtonDesaturated(button, true)
			end
		end
	end

	RefreshSelectedClass()
end

function CharCreateSelectCustomizationType(newType)
	-- deselect previous type selection
	if ( CharacterCreateFrame.customizationType and CharacterCreateFrame.customizationType ~= newType ) then
		--_G["CharCreateCustomizationButton"..CharacterCreateFrame.customizationType]:SetChecked(0);
	end
	--_G["CharCreateCustomizationButton"..newType]:SetChecked(1);
	CharacterCreateFrame.customizationType = newType;
	CharCreate_ResetFeaturesDisplay();

	--[[if (newType > 1) then
		SetFaceCustomizeCamera(true);
	else
		SetFaceCustomizeCamera(false);
	end]]
end

function CharCreate_ResetFeaturesDisplay()
	--SetPreviewFramesFeature(CharacterCreateFrame.customizationType);
	-- set the previews scrollframe container height
	-- since the first and the last previews need to be in the center position when scrolled all the way
	-- to the top or to the bottom, there will be gaps of height equal to 2 previews on each side
	local numTotalButtons = 4--GetNumFeatureVariations() + 4;
	CharCreatePreviewFrame.scrollFrame.container:SetHeight(numTotalButtons * PREVIEW_FRAME_HEIGHT - PREVIEW_FRAME_Y_OFFSET);

	for _, previewFrame in pairs(CharCreatePreviewFrame.previews) do
		previewFrame.featureType = 0;
	end

	CharCreate_DisplayPreviewModels();
end

function CharCreate_PrepPreviewModels(reloadModels)
	local displayFrame = CharCreatePreviewFrame;

	-- clear models if rebuildPreviews got flagged
	local rebuildPreviews = displayFrame.rebuildPreviews;
	displayFrame.rebuildPreviews = nil;

	-- need to reload models class was swapped to or from DK
	local classSwap = false;
	local _, class = GetSelectedClass();
	--[[if ( class == "DEATHKNIGHT" or displayFrame.lastClass == "DEATHKNIGHT" ) and ( class ~= displayFrame.lastClass ) then
		classSwap = true;
	end]]

	-- always clear the featureType
	for index, previewFrame in pairs(displayFrame.previews) do
		previewFrame.featureType = 0;
		-- force model reload if class changed
		if ( classSwap ) then
			previewFrame.race = nil;
			previewFrame.gender = nil;
		end
		if ( rebuildPreviews ) then
			--SetPreviewFrame(previewFrame.model:GetName(), index);
		end
	end
end

function CharCreate_DisplayPreviewModels(selectionIndex)
	if ( not selectionIndex ) then
		selectionIndex = featureIndex--GetSelectedFeatureVariation();
	end

	local displayFrame = CharCreatePreviewFrame;
	local previews = displayFrame.previews;
	local numVariations = 8--GetNumFeatureVariations();
	local currentFeatureType = CharacterCreateFrame.customizationType;

	local race = GetSelectedRace();
	local gender = GetSelectedSex();

	-- selection index is the center preview
	-- there are 2 previews above and 2 below, and will pad it out to 1 more on each side, for a total of 7 previews to set up
	for index = selectionIndex - 3, selectionIndex + 3 do
		-- there is empty space both at the beginning and at end of the list, each gap the height of 2 previews
		if ( index > 0 and index <= numVariations ) then
			local previewFrame = previews[index];
			-- create button if we don't have it yet
			if ( not previewFrame ) then
				previewFrame = CreateFrame("BUTTON", "PreviewFrame"..index, displayFrame.scrollFrame.container, "CharCreatePreviewFrameTemplate");
				-- index + 1 because of 2 gaps at the top and -1 for the current preview
				previewFrame:SetPoint("TOPLEFT", PREVIEW_FRAME_X_OFFSET, (index + 1) * -PREVIEW_FRAME_HEIGHT + PREVIEW_FRAME_Y_OFFSET);
				previewFrame.button.index = index;
				previews[index] = previewFrame;
				--SetPreviewFrame(previewFrame.model:GetName(), index);
				-- no texture as of yet
				--previewFrame:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			end
			-- load model if needed, may have been cleared by different race/gender selection
			if ( previewFrame.race ~= race or previewFrame.gender ~= gender ) then
				--SetPreviewFrameModel(index);
				previewFrame.race = race;
				previewFrame.gender = gender;
				-- apply settings
				local model = previewFrame.model;
				--model:SetCustomCamera(cameraID);
				local scale = 1--model:GetWorldScale();
				--model:SetCameraTarget(config.tx * scale, config.ty * scale, config.tz * scale);
				--model:SetCameraDistance(config.distance * scale);
				local cx, cy, cz = model:GetPosition();
				-- model:SetPosition(cx-15, cy, cz)
				--model:SetCameraPosition(cx, cy, config.cz * scale);
				previewFrame.model:SetLight(1, 0, 0, 0, 0, 1, 1.0, 1.0, 1.0);
			end
			-- need to reset the model if it was last used to preview a different feature
			if ( previewFrame.featureType ~= currentFeatureType ) then
				--ResetPreviewFrameModel(index);
				--ShowPreviewFrameVariation(index);
				previewFrame.featureType = currentFeatureType;
			end
			previewFrame:Show();
		else
			-- need to hide tail previews when going to features with fewer styles
			if ( previews[index] ) then
				previews[index]:Hide();
			end
		end
	end
	displayFrame.border.number:SetText("Option "..selectionIndex.."                     ");
	displayFrame.selectionIndex = selectionIndex;
	CharCreate_RotatePreviews();
	CharCreatePreviewFrame_UpdateStyleButtons();
	-- scroll to center the selection
	if ( not displayFrame.animating ) then
		displayFrame.scrollFrame:SetVerticalScroll((selectionIndex - 1) * PREVIEW_FRAME_HEIGHT);
	end
end


function CharCreate_RotatePreviews()
	if ( CharCreatePreviewFrame:IsShown() ) then
		local facing = ((GetCharacterCreateFacing())/ -180) * math.pi;
		local previews = CharCreatePreviewFrame.previews;
		--CharCreatePreviewFrame.selectionIndex = 0;
		for index = CharCreatePreviewFrame.selectionIndex - 3, CharCreatePreviewFrame.selectionIndex + 3 do
			local previewFrame = previews[index];
			if ( previewFrame ) then -- and previewFrame.model:HasCustomCamera()
				--previewFrame.model:SetCameraFacing(facing);
			end
		end
	end
end

function CharCreate_ChangeFeatureVariation(delta)
	local numVariations = 8--GetNumFeatureVariations();
	local startIndex = featureIndex--GetSelectedFeatureVariation();
	local endIndex = startIndex + delta;
	if ( endIndex < 1 or endIndex > numVariations ) then
		return;
	end
	PlaySound("gsCharacterCreationClass");
	featureIndex = endIndex
	CharCreatePreviewFrame_SelectFeatureVariation(endIndex);
end

function CharCreatePreviewFrameButton_OnClick(self)
	PlaySound("gsCharacterCreationClass");
	CharCreatePreviewFrame_SelectFeatureVariation(self.index);
end

function CharCreatePreviewFrame_SelectFeatureVariation(endIndex)
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		if ( not self.queuedIndex ) then
			self.queuedIndex = endIndex;
		end
	else
		local startIndex = featureIndex--GetSelectedFeatureVariation();
		--SelectFeatureVariation(endIndex);
		for i=1,endIndex do
			CycleCharCustomization(FeatureType, 1);
		end
		CharacterCreate_UndressCustomizationHeadSlot()
		CharCreatePreviewFrame_UpdateStyleButtons();
		featureIndex = endIndex
		CharCreatePreviewFrame_StartAnimating(startIndex, endIndex);
	end
end

function CharCreatePreviewFrame_StartAnimating(startIndex, endIndex)
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		return;
	else
		self.startIndex = startIndex;
		self.currentIndex = startIndex;
		self.endIndex = endIndex;
		self.queuedIndex = nil;
		self.direction = 1;
		if ( self.startIndex > self.endIndex ) then
			self.direction = -1;
		end
		self.movedTotal = 0;
		self.moveUntilUpdate = PREVIEW_FRAME_HEIGHT;
		self.animating = true;
	end
end

function CharCreatePreviewFrame_StopAnimating()
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		self.animating = false;
	end
end

local ANIMATION_SPEED = 5;
function CharCreatePreviewFrame_OnUpdate(self, elapsed)
	if ( self.animating ) then
		local moveIncrement = PREVIEW_FRAME_HEIGHT * elapsed * ANIMATION_SPEED;
		self.movedTotal = self.movedTotal + moveIncrement;
		self.scrollFrame:SetVerticalScroll((self.startIndex - 1) * PREVIEW_FRAME_HEIGHT + self.movedTotal * self.direction);
		self.moveUntilUpdate = self.moveUntilUpdate - moveIncrement;
		if ( self.moveUntilUpdate <= 0 ) then
			self.currentIndex = self.currentIndex + self.direction;
			self.moveUntilUpdate = PREVIEW_FRAME_HEIGHT;
			-- reset movedTotal to account for rounding errors
			self.movedTotal = abs(self.startIndex - self.currentIndex) * PREVIEW_FRAME_HEIGHT;
			CharCreate_DisplayPreviewModels(self.currentIndex);
		end
		if ( self.currentIndex == self.endIndex ) then
			self.animating = false;
			CharCreate_DisplayPreviewModels();
			if ( self.queuedIndex ) then
				local newIndex = self.queuedIndex;
				self.queuedIndex = nil;
				--SelectFeatureVariation(newIndex);
				featureIndex = newIndex
				CycleCharCustomization(FeatureType, featureIndex);
				CharacterCreate_UndressCustomizationHeadSlot()
				CharCreatePreviewFrame_UpdateStyleButtons();
				CharCreatePreviewFrame_StartAnimating(self.endIndex, newIndex);
			end
		end
	end
end

function CharCreatePreviewFrame_UpdateStyleButtons()
	local selectionIndex = math.random(1,5)--GetSelectedFeatureVariation();
	local numVariations = 8--GetNumFeatureVariations();
	if ( selectionIndex == 1 ) then
		CharCreateStyleUpButton:Enable();
		CharCreateStyleUpButton.arrow:SetDesaturated(true);
	else
		CharCreateStyleUpButton:Enable();
		CharCreateStyleUpButton.arrow:SetDesaturated(false);
	end
	if ( selectionIndex == numVariations ) then
		CharCreateStyleDownButton:Disable();
		CharCreateStyleDownButton.arrow:SetDesaturated(true);
	else
		CharCreateStyleDownButton:Disable(true);
		CharCreateStyleDownButton.arrow:SetDesaturated(false);
	end
end

local TotalTime = 0;
local KeepScrolling = nil;
local TIME_TO_SCROLL = 0.5;
function CharacterCreateWhileMouseDown_OnMouseDown(direction)
	TIME_TO_SCROLL = 0.5;
	TotalTime = 0;
	KeepScrolling = direction;
end
function CharacterCreateWhileMouseDown_OnMouseUp()
	KeepScrolling = nil;
end
function CharacterCreateWhileMouseDown_Update(elapsed)
	if ( KeepScrolling ) then
		TotalTime = TotalTime + elapsed;
		if ( TotalTime >= TIME_TO_SCROLL ) then
			CharCreate_ChangeFeatureVariation(KeepScrolling);
			TIME_TO_SCROLL = 0.25;
			TotalTime = 0;
		end
	end
end

function CharCreate_EnableNextButton(enabled)
	local button = CharCreateOkayButton;
	if enabled then
		button:Enable();
	else
		button:Disable();
	end
	button.arrow:SetDesaturated(not enabled);

	--[[if enabled then
		button.TopGlow:Hide();
		button.BottomGlow:Hide();
	else
		button.TopGlow:Show();
		button.BottomGlow:Show();
	end]]--
end

CharCreateButtonMixin = {}

function CharCreateButtonMixin:OnEnter()
	GlueTooltip_GenericTooltip(self)
end

function CharCreateButtonMixin:OnLeave()
	GlueTooltip:Hide()
end

CharCreateRaceButtonMixin = CreateFromMixins(CharCreateButtonMixin)

function CharCreateRaceButtonMixin:OnLoad()
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:GetPushedTexture():SetDrawLayer("BACKGROUND")

	local _, faction = GetFactionForRace(self:GetID())

	if faction == nil then
		faction = "Alliance"
	end
	
	self:SetFaction(faction)
end

function CharCreateRaceButtonMixin:OnClick()
	local _, factionSelected = GetFactionForRace(CharacterCreate.selectedRace)

	local _, faction = GetFactionForRace(self:GetID())

	if (factionSelected ~= faction) then
		if not C_CharacterCreate.CanCreateCoA() then
			faction = faction.."REGULAR"
		end
		GlueFrameFadeIn(CharacterCreateFrameFade, 0.3, function()
			SetBackgroundModel(CharacterCreate, string.upper(faction));
			CharacterRace_OnClick(self, self:GetID());
			GlueFrameFadeOut(CharacterCreateFrameFade, 0.5)
		end);
	else
		CharacterRace_OnClick(self, self:GetID());
	end
end

function CharCreateRaceButtonMixin:OnEnable()
	self.Text:SetFontObject("GameFontNormal")
end

function CharCreateRaceButtonMixin:OnDisable()
	self.Text:SetFontObject("GameFontDisable")
end

function CharCreateRaceButtonMixin:OnEnter()
	GlueTooltip_GenericTooltip(self, "ANCHOR_NONE")
	if self.faction == "Alliance" then
		GlueTooltip:SetPoint("LEFT", self, "RIGHT", 0, 0)
	else
		GlueTooltip:SetPoint("RIGHT", self, "LEFT", 0, 0)
	end
end

function CharCreateRaceButtonMixin:SetFaction(faction)
	self.faction = faction
	local backdropColor = FACTION_SHADOW_COLORS[faction]
	self.Shadow:SetVertexColor(backdropColor:GetRGB())

	if (faction == "Alliance") then
		self.Shadow:SetTexCoord(0, 1, 0, 1)
		self.Shadow:ClearAndSetPoint("LEFT", self, "RIGHT", -8, -8)
		self.Text:ClearAndSetPoint("LEFT", self, "RIGHT", 16, 0)
	else
		self.Shadow:SetTexCoord(1, 0, 0, 1)
		self.Shadow:ClearAndSetPoint("RIGHT", self, "LEFT", 8, -8)
		self.Text:ClearAndSetPoint("RIGHT", self, "LEFT", -16, 0)
	end
end

function CharCreateRaceButtonMixin:SetRace(raceName, raceEnglishName, gender, enabled)
	local coords = RACE_ICON_TCOORDS[raceEnglishName.."_"..gender]

	self:GetNormalTexture():SetTexCoord(unpack(coords))
	self:GetPushedTexture():SetTexCoord(unpack(coords))

	self:SetText(raceName)
	self.tooltipText = {}

	self:SetEnabled(enabled)
	SetButtonDesaturated(self, not enabled)

	self.tooltipTitle = raceName
	if not enabled then
		local disabledReason = _G[raceEnglishName.."_".."DISABLED"]
		if disabledReason then
			tinsert(self.tooltipText, disabledReason)
		else
			self.tooltipTitle = nil
			self.tooltipText = nil
		end
	end

	local abilityIndex = 1
	local text = GetRealmSpecificGlobalString("ABILITY_INFO_"..raceEnglishName..abilityIndex)
	local spell = CHAR_CREATE_PASSIVES[raceEnglishName] and CHAR_CREATE_PASSIVES[raceEnglishName][abilityIndex]

	if text and spell then
		local _, _, spellIconPath = GetSpellData(spell, false, true)
		text = "|T"..spellIconPath..":24:24:0:0|t"..text.."\n"
	end

	while text do
		tinsert(self.tooltipText, text)
		abilityIndex = abilityIndex + 1
        
		text = GetRealmSpecificGlobalString("ABILITY_INFO_"..raceEnglishName..abilityIndex)
		spell = CHAR_CREATE_PASSIVES[raceEnglishName] and CHAR_CREATE_PASSIVES[raceEnglishName][abilityIndex]

		if text and spell then
			local _, _, spellIconPath = GetSpellData(spell, false, true)
			text = "|T"..spellIconPath..":24:24:0:0|t"..text.."\n"
		end
	end

	tinsert(self.tooltipText, 1, GetFlavorText("RACE_INFO_"..raceEnglishName, gender).."\n\n")
end

function CharCreateRaceButtonMixin:SetText(text)
	self.Text:SetText(text)
end

CharCreateClassButtonMixin = CreateFromMixins(CharCreateButtonMixin)

function CharCreateClassButtonMixin:OnLoad()
	self:GetNormalTexture():SetDrawLayer("BACKGROUND")
	self:GetPushedTexture():SetDrawLayer("BACKGROUND")
	EventRegistry:RegisterCallback("CharacterCreate.PaidServiceActive", self.RefreshEnabled, self)
	EventRegistry:RegisterCallback("CharacterCreate.ClassChanged", function(self, classID)
		self:SetSelected(classID == self:GetID())
	end, self)

end

function CharCreateClassButtonMixin:RefreshEnabled()
	self:SetEnabled(not PAID_SERVICE_TYPE)
end

function CharCreateClassButtonMixin:OnEnable()
	self.Text:SetFontObject("GameFontNormal")
	self.Border:SetVertexColor(1, 1, 1, 1)
	self:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
end

function CharCreateClassButtonMixin:OnDisable()
	self.Text:SetFontObject("GameFontDisable")
	self.Border:SetVertexColor(0.5, 0.5, 0.5, 1)
	self:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5, 1)
end

function CharCreateClassButtonMixin:SetClassGuideCombatHealer(isCombatHealer)
	self.classGuideCombatHealer = isCombatHealer and true or false

	if not self.ClassGuideCombatHealerBadge then
		local badge = CreateFrame("Button", nil, self)
		badge:SetSize(38, 38)
		badge:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 11, -11)
		badge:SetFrameLevel(self:GetFrameLevel() + 3)
		badge:SetScript("OnClick", function(badgeSelf)
			badgeSelf:GetParent():Click()
		end)
		badge:SetScript("OnEnter", function(badgeSelf)
			GlueTooltip:SetOwner(badgeSelf, "ANCHOR_TOP")
			GlueTooltip:AddLine(CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TITLE, 1, 1, 1, 1, true)
			GlueTooltip:AddLine(CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TEXT, 1, 0.82, 0, 1, true)
			GlueTooltip:Show()
		end)
		badge:SetScript("OnLeave", function()
			GlueTooltip:Hide()
		end)

		local icon = badge:CreateTexture(nil, "OVERLAY")
		icon:SetAllPoints()
		icon:SetAtlas(CharacterCreate_GetClassGuideAtlas(CLASS_GUIDE_COMBAT_HEALER_ATLAS))
		badge.Icon = icon
		self.ClassGuideCombatHealerBadge = badge
	end

	self.ClassGuideCombatHealerBadge:SetShown(self.classGuideCombatHealer)
end

function CharCreateClassButtonMixin:OnClick()
	CharacterClass_OnClick(self, self:GetID())

	if CharacterCreate.classGuideActive then
		CharacterCreate.selectedClassGuideClassID = self:GetID()
		CharCreate_EnableNextButton(true)
		CharacterCreate_UpdateClassGuideClassButtonSelection(CharacterCreate)
	end
end

local function WrapResourceTooltipText(resource, text)
	local color = POWER_COLORS and POWER_COLORS[resource]
	if color then
		return color:WrapText(text)
	end

	return text
end

function CharCreateClassButtonMixin:OnEnter()
	GlueTooltip:SetOwner(self, "ANCHOR_TOP")
	GlueTooltip:SetText(self.tooltipTitle)
	GlueTooltip:SetMinWidth(340)

	-- Role
	do
		local roles = ClassInfoUtil.GetClassRoles(self.class)

		if roles.MeleeDPS then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.MELEE_DAMAGER)
		end

		if roles.RangedDPS then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.RANGED_DAMAGER)
		end

		if roles.CasterDPS then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.CASTER_DAMAGER)
		end

		if roles.Tank then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.TANK)
		end

		if roles.Healer then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.HEALER)
		end

		if roles.Support then
			GlueTooltip:AddLine(ROLE_TEXT_WITH_ICON.SUPPORT)
		end

		GlueTooltip:AddLine(" ")
	end

	if self.classGuideCombatHealer then
		GlueTooltip:AddLine(CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TITLE, 1, 0.82, 0, 1, true)
		GlueTooltip:AddLine(CLASS_GUIDE_COMBAT_HEALER_TOOLTIP_TEXT, 1, 1, 1, 1, true)
		GlueTooltip:AddLine(" ")
	end

	-- Primary
	local hasResource = false
	do
		local resources = ClassInfoUtil.GetClassPrimaryResources(self.class)
		local string
		for _, resource in ipairs(resources) do
			local text = _G[resource]
			if text then
				if string then
					string = string.." / "
				else
					string = ""
				end
				text = WrapResourceTooltipText(resource, text)
				string = string..text
			end
		end

		if string then
			hasResource = true
			GlueTooltip:AddLine(PRIMARY_RESOURCE:format(string), 1, 0.82, 0, 1, true)
		end
	end

	-- Secondary
	do
		local resources = ClassInfoUtil.GetClassSecondaryResources(self.class)
		local string
		for _, resource in ipairs(resources) do
			local text = _G[resource]
			if text then
				if string then
					string = string.." / "
				else
					string = ""
				end
				text = WrapResourceTooltipText(resource, text)
				string = string..text
			end
		end

		if string then
			hasResource = true
			GlueTooltip:AddLine(SECONDARY_RESOURCE:format(string), 1, 0.82, 0, 1, true)
		end
	end

	-- Special Perks
	do
		local combined
		local i = 1
		while true do
			local perk = _G["CLASS_SPECIAL_PERKS_"..self.class..i]
			if not perk then
				break
			end
			if combined then
				combined = combined..", "..perk
			else
				combined = perk
			end
			i = i + 1
		end

		if combined then
			hasResource = true
			GlueTooltip:AddLine(CLASS_SPECIAL_PERKS:format(combined), 1, 1, 1, 1, true)
		end
	end

	if hasResource then
		GlueTooltip:AddLine(" ")
	end

	-- Armor Proficiency
	do
		local armorTypes = ClassInfoUtil.GetClassArmorProficiency(self.class)

		if armorTypes.Plate then
			GlueTooltip:AddLine(ARMOR_TYPE_WITH_ICON.PLATE, 1, 1, 1, 1, true)
		end

		if armorTypes.Mail then
			GlueTooltip:AddLine(ARMOR_TYPE_WITH_ICON.MAIL, 1, 1, 1, 1, true)
		end

		if armorTypes.Leather then
			GlueTooltip:AddLine(ARMOR_TYPE_WITH_ICON.LEATHER, 1, 1, 1, 1, true)
		end

		if armorTypes.Cloth then
			GlueTooltip:AddLine(ARMOR_TYPE_WITH_ICON.CLOTH, 1, 1, 1, 1, true)
		end

		GlueTooltip:AddLine(" ")
	end

	-- Combat Style
	do
		local text = _G["CLASS_COMBAT_STYLE_"..self.class.."0"]
		if text then
			GlueTooltip:AddLine(COMBAT_STYLE, 1, 0.82, 0)

			local i = 0
			while text do
				GlueTooltip:AddLine("- " .. text, 1, 1, 1, 1, true)
				i = i + 1
				text = _G["CLASS_COMBAT_STYLE_"..self.class..i]
			end
		end
	end

	GlueTooltip:AddLine(" ")
	GlueTooltip:AddLine(GetFlavorText("CLASS_"..self.class, "MALE"), 1, 0.82, 0, 1, true)
	GlueTooltip:Show()
	
	self:HighlightValidRaces()
end

function CharCreateClassButtonMixin:OnLeave()
	CharCreateButtonMixin.OnLeave(self)
	self:StopHighlightingRaces()
end

function CharCreateClassButtonMixin:HighlightValidRaces()
	for i = 1, 10 do
		local button = _G["CharCreateRaceButton"..i]
		if button:IsEnabled() then
			if IsRaceClassValid(button:GetID(), self:GetID()) then
				button.Glow.Anim:Play()
			else
				button.Glow.Anim:Stop()
			end
		end
	end
end

function CharCreateClassButtonMixin:StopHighlightingRaces()
	for i = 1, 10 do
		local button = _G["CharCreateRaceButton"..i]
		button.Glow.Anim:Stop()
	end
end

function CharCreateClassButtonMixin:SetText(text)
	self.Text:SetText(text)
end

function CharCreateClassButtonMixin:SetSelected(selected)
	self:SetChecked(selected)
end

function CharCreateClassButtonMixin:SetClass(className, classFileName, enabled)
	self.class = classFileName
	local coords = CLASS_ICON_TCOORDS_ROUND[classFileName]
	local classColor = RAID_CLASS_COLORS[classFileName] or HIGHLIGHT_FONT_COLOR
	
	enabled = enabled and CharacterCreateUtil.IsRaceClassEnabledAndValid(CharacterCreate.selectedRace, self:GetID()) and not PAID_SERVICE_TYPE

	self:GetNormalTexture():SetTexCoord(unpack(coords))
	self:GetPushedTexture():SetTexCoord(unpack(coords))
	
	self:SetText(className:gsub(" ([^ ]*)$", "\n%1", 1))
	local textColor = enabled and NORMAL_FONT_COLOR or DISABLED_FONT_COLOR
	self.Text:SetTextColor(textColor:GetRGB())

	self.tooltipTitle = classColor:WrapText(className)

	self:SetEnabled(enabled)
	SetButtonDesaturated(self, not enabled)
	self.DisableTexture:SetShown(not enabled)
	self:SetClassGuideCombatHealer(false)
	self:SetSelected(CharacterCreate.selectedClass == self:GetID())
end


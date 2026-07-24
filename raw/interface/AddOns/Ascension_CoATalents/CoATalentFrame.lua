COA_RESET_TREES = COA_RESET_TREES or "Reset Trees"
COA_CHANGE_ACTIVE_SPECIALIZATION = COA_CHANGE_ACTIVE_SPECIALIZATION or "Change Active Specialization"
COA_SHARE_BUILD = COA_SHARE_BUILD or "Share Build"
COA_SHARE_BUILD_TOOLTIP = COA_SHARE_BUILD_TOOLTIP or "Click to copy a link to your current CoA build.\n\nGenerates a URL with its own unique key."
COA_IMPORT_BUILD = COA_IMPORT_BUILD or "Import Build"
COA_IMPORT_BUILD_TOOLTIP = COA_IMPORT_BUILD_TOOLTIP or "Import a Conquest of Azeroth build from its URL."

CoATalentFrameMixin = {}
CoATalentFrameMixin.OnEvent = OnEventToMethod

local RefreshFromCancel = false
local FOOTER_LAYOUT_VERSION = 4
local FOOTER_LAYOUT_DEFAULTS = {
    specY = -7,
    buildY = -34,
    shareY = 2.75,
    importY = 1.75,
    shareX = -16,
    importX = -16,
}

local FOOTER_LAYOUT_KEYS = {
    spec = { key = "specY", axis = "y" },
    build = { key = "buildY", axis = "y" },
    share = { key = "shareY", axis = "y" },
    import = { key = "importY", axis = "y" },
    sharex = { key = "shareX", axis = "x" },
    importx = { key = "importX", axis = "x" },
}

local function PrintFooterLayoutMessage(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cfffe8c00CoA Footer:|r %s", message))
    end
end

local function GetFooterLayoutDB()
    CoATalentFooterLayoutDB = CoATalentFooterLayoutDB or {}

    if CoATalentFooterLayoutDB.version ~= FOOTER_LAYOUT_VERSION then
        for key, value in pairs(FOOTER_LAYOUT_DEFAULTS) do
            CoATalentFooterLayoutDB[key] = value
        end
        CoATalentFooterLayoutDB.version = FOOTER_LAYOUT_VERSION
    end

    for key, value in pairs(FOOTER_LAYOUT_DEFAULTS) do
        if CoATalentFooterLayoutDB[key] == nil then
            CoATalentFooterLayoutDB[key] = value
        end
    end

    return CoATalentFooterLayoutDB
end

local function ApplyFooterLayout()
    if CoATalentFrame and CoATalentFrame.TreeView and CoATalentFrame.TreeView.ApplyFooterLayout then
        CoATalentFrame.TreeView:ApplyFooterLayout()
    end
end

local function PrintFooterLayoutState()
    local layout = GetFooterLayoutDB()
    PrintFooterLayoutMessage(string.format(
        "specY=%d, buildY=%d, shareY=%d, importY=%d, shareX=%d, importX=%d",
        layout.specY,
        layout.buildY,
        layout.shareY,
        layout.importY,
        layout.shareX,
        layout.importX
    ))
end

local function PrintFooterLayoutUsage()
    PrintFooterLayoutMessage("Usage: /coatfooter report | reset | <spec|build|share|import> <up|down|set> <amount>")
    PrintFooterLayoutMessage("Usage: /coatfooter <sharex|importx> <left|right|set> <amount>")
    PrintFooterLayoutMessage("share/import adjust tag-on button Y offsets. sharex/importx adjust their horizontal spacing.")
end

local function ReportFooterLayout(includeUsage)
    PrintFooterLayoutState()
    if includeUsage then
        PrintFooterLayoutUsage()
    end
end

local function HandleFooterLayoutCommand(msg)
    local normalizedMsg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local command, action, amount = string.match(normalizedMsg, "^(%S*)%s*(%S*)%s*(.-)$")
    command = string.lower(command or "")
    action = string.lower(action or "")
    amount = amount ~= "" and tonumber(amount) or nil

    if command == "" or command == "report" or command == "help" then
        return ReportFooterLayout(true)
    end

    local layout = GetFooterLayoutDB()

    if command == "reset" then
        for key, value in pairs(FOOTER_LAYOUT_DEFAULTS) do
            layout[key] = value
        end
        ApplyFooterLayout()
        PrintFooterLayoutMessage("Reset footer offsets to defaults.")
        return ReportFooterLayout(false)
    end

    local layoutInfo = FOOTER_LAYOUT_KEYS[command]
    if not layoutInfo then
        PrintFooterLayoutMessage("Unknown footer target.")
        return ReportFooterLayout(true)
    end

    if not amount then
        PrintFooterLayoutMessage("Missing footer offset amount.")
        return ReportFooterLayout(true)
    end

    if layoutInfo.axis == "y" then
        if action == "up" then
            layout[layoutInfo.key] = layout[layoutInfo.key] + amount
        elseif action == "down" then
            layout[layoutInfo.key] = layout[layoutInfo.key] - amount
        elseif action == "set" then
            layout[layoutInfo.key] = amount
        else
            PrintFooterLayoutMessage("Unknown footer action.")
            return ReportFooterLayout(true)
        end
    else
        if action == "right" then
            layout[layoutInfo.key] = layout[layoutInfo.key] + amount
        elseif action == "left" then
            layout[layoutInfo.key] = layout[layoutInfo.key] - amount
        elseif action == "set" then
            layout[layoutInfo.key] = amount
        else
            PrintFooterLayoutMessage("Unknown footer action.")
            return ReportFooterLayout(true)
        end
    end

    ApplyFooterLayout()
    ReportFooterLayout(false)
end

SLASH_COATALENTFOOTER1 = "/coatalentfooter"
SLASH_COATALENTFOOTER2 = "/coatfooter"
SlashCmdList["COATALENTFOOTER"] = HandleFooterLayoutCommand

if C_CharacterAdvancement and C_CharacterAdvancement.CancelPendingBuild then
    hooksecurefunc(C_CharacterAdvancement, "CancelPendingBuild", function()
        RefreshFromCancel = true
    end)
end

function CoATalentFrameMixin:OnLoad()
    self.class = select(2, UnitClass("player"))
    PortraitFrame_SetTitle(self, COA_CA_TITLE)
    self.CloseButton:SetScript("OnClick", function()
        HideUIPanel(Collections)
    end)
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end 

function CoATalentFrameMixin:GetFooterLayout()
    return GetFooterLayoutDB()
end

function CoATalentFrameMixin:OnShow()
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    StaticPopup_Hide("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
    self:UpdateActiveSpec()
end 

function CoATalentFrameMixin:OnHide()
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")

    if C_CharacterAdvancement.IsPending() then
        StaticPopup_Show("CLOSE_CHARACTER_ADVANCEMENT_UNSAVED_PENDING_CHANGES")
    end
end

function CoATalentFrameMixin:UpdateActiveSpec()
    local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    self.activeSpecID = activeSpecID
    self:UpdatePortrait(activeSpecID)
    if not activeSpecID then
        self:ShowSpecView()
    else
        self:ShowTreeView()
        self.TreeView:SetSpecID(activeSpecID)
    end
end

function CoATalentFrameMixin:UpdatePortrait(activeSpecID)
    activeSpecID = activeSpecID or C_CharacterAdvancement.GetActiveChrSpec()
    local icon
    if activeSpecID then
        local specInfo = C_ClassInfo.GetSpecInfoByID(activeSpecID)
        if specInfo and specInfo.SpecFilename then
            icon = "Interface\\Icons\\"..specInfo.SpecFilename
        end
    end

    if icon then
        PortraitFrame_SetIcon(self, icon)
    else
        PortraitFrame_SetClassIcon(self, self.class)
    end
end

function CoATalentFrameMixin:ShowTreeView()
    self.SpecView:Hide()
    if self.TreeView:IsShown() then
        self.TreeView:MarkTreesDirty()
    else
        self.TreeView:Show()
    end
end 

function CoATalentFrameMixin:ShowSpecView()
    self.TreeView:Hide()
    self.SpecView:Show()
end 

function CoATalentFrameMixin:ChangeSpecID(specID)
    self.expectingNewSpec = true
    C_CharacterAdvancement.SwitchActiveChrSpec(specID)
end 

function CoATalentFrameMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    if self.expectingNewSpec then
        self.expectingNewSpec = false
        self:UpdateActiveSpec()
    end

    if RefreshFromCancel then
        RefreshFromCancel = false
        self:UpdateActiveSpec()
    end
end

function CoATalentFrameMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    self:UpdateActiveSpec()
end 

--
-- Build Creator Menu
--
CoABuildCreatorMenuMixin = {}
CoABuildCreatorMenuMixin.OnEvent = OnEventToMethod

function CoABuildCreatorMenuMixin:OnLoad()
    self.title:SetText(HERO_ARCHITECT)
    self.BuildList:SetGetNumResultsFunction(C_BuildCreator.GetNumBuilds)
    self.BuildList:SetSelectedHighlightTexture()
    self.BuildList:SetTemplate("CoATalentBuildTemplate")
    self:RegisterEvent("BUILD_CREATOR_CATEGORY_RESULT")
    self.Loading:SetFrameLevel(self:GetFrameLevel()+10)
end 

function CoABuildCreatorMenuMixin:OnShow()
    self:RefreshBuilds()
    self:GetParent().SpecializationMenu:Hide()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function CoABuildCreatorMenuMixin:OnHide()
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

function CoABuildCreatorMenuMixin:RefreshBuilds()
    self.Loading:Show()
    C_BuildCreator.QueryAllBuilds(Enum.BuildCategory.Leveling)
end 

function CoABuildCreatorMenuMixin:SelectBuild(buildID)
    BuildCreatorUtil.ImportPendingBuildID(buildID)
end

function CoABuildCreatorMenuMixin:GLOBAL_MOUSE_DOWN()
    FrameUtil.DialogStyleGlobalMouseDown(self, self:GetParent().BuildDropDown)
end

function CoABuildCreatorMenuMixin:BUILD_CREATOR_CATEGORY_RESULT(category)
    self.Loading:Hide()
    local specID = C_CharacterAdvancement.GetActiveChrSpec()
    if not specID then
        return
    end
    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
    local searchTag = CoACharacterAdvancementUtil.FormatArchitectTag(specInfo.Spec)
    if searchTag then
        C_BuildCreator.UpdateFilter(searchTag, table.empty, table.empty)
    end

    self.NoItemText:SetShown(C_BuildCreator.GetNumBuilds() == 0)
    self.BuildList:RefreshScrollFrame()
end 

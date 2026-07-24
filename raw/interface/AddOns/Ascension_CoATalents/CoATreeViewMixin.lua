CoATreeViewMixin = {}
CoATreeViewMixin.OnEvent = OnEventToMethod

local FOOTER_LAYOUT_FALLBACKS = {
    specY = -7,
    buildY = -34,
    shareY = 2.75,
    importY = 1.75,
    shareX = -16,
    importX = -16,
}

local function SetDropDownButtonDirectionUp(dropDown)
    local button = dropDown.Button
    button:GetNormalTexture():SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    button:GetPushedTexture():SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    button:GetDisabledTexture():SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
    button:GetHighlightTexture():SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
end

local function GetFooterLayout(frame)
    local parent = frame:GetParent()
    if parent and parent.GetFooterLayout then
        return parent:GetFooterLayout()
    end

    CoATalentFooterLayoutDB = CoATalentFooterLayoutDB or {}
    for key, value in pairs(FOOTER_LAYOUT_FALLBACKS) do
        if CoATalentFooterLayoutDB[key] == nil then
            CoATalentFooterLayoutDB[key] = value
        end
    end

    return CoATalentFooterLayoutDB
end

function CoATreeViewMixin:ApplyFooterLayout()
    local layout = GetFooterLayout(self)

    self.BottomBar.SpecDropDown:ClearAllPoints()
    self.BottomBar.SpecDropDown:SetPoint("TOPLEFT", self.BottomBar, "TOPLEFT", 4, layout.specY)

    self.BottomBar.BuildDropDown:ClearAllPoints()
    self.BottomBar.BuildDropDown:SetPoint("TOPLEFT", self.BottomBar, "TOPLEFT", 4, layout.buildY)

    self.BottomBar.ShareBuildButton:ClearAllPoints()
    self.BottomBar.ShareBuildButton:SetPoint("LEFT", self.BottomBar.SpecDropDown, "RIGHT", layout.shareX, layout.shareY)

    self.BottomBar.ImportBuildButton:ClearAllPoints()
    self.BottomBar.ImportBuildButton:SetPoint("LEFT", self.BottomBar.BuildDropDown, "RIGHT", layout.importX, layout.importY)

    self.BottomBar.SpecializationMenu:ClearAllPoints()
    self.BottomBar.SpecializationMenu:SetPoint("BOTTOMLEFT", self.BottomBar.SpecDropDown, "TOPLEFT", 12, 2)

    self.BottomBar.BuildCreatorMenu:ClearAllPoints()
    self.BottomBar.BuildCreatorMenu:SetPoint("BOTTOMLEFT", self.BottomBar.BuildDropDown, "TOPLEFT", 12, 2)
end

function CoATreeViewMixin:OnLoad()
    local class = select(2, UnitClass("player"))
    local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(class)
    self.ClassTree:SetClassTab(classDBC, "Class")
    self.ClassTree.Label:SetText(LOCALIZED_CLASS_NAMES_MALE[class]:upper())
    self.SpecTree.PassivesBackground:SetAtlas("ca-passive-bg", Const.TextureKit.IgnoreAtlasSize)
    local popupFrameLevel = self.BottomBar:GetFrameLevel() + 20
    self.BottomBar.SpecializationMenu:SetFrameLevel(popupFrameLevel)
    self.BottomBar.BuildCreatorMenu:SetFrameLevel(popupFrameLevel)
    UIDropDownMenu_SetWidth(self.BottomBar.SpecDropDown, 180)
    UIDropDownMenu_SetWidth(self.BottomBar.BuildDropDown, 180)
    UIDropDownMenu_JustifyText(self.BottomBar.SpecDropDown, "LEFT")
    UIDropDownMenu_JustifyText(self.BottomBar.BuildDropDown, "LEFT")
    SetDropDownButtonDirectionUp(self.BottomBar.SpecDropDown)
    SetDropDownButtonDirectionUp(self.BottomBar.BuildDropDown)
    self:ApplyFooterLayout()
    UIDropDownMenu_SetAnchor(self.BottomBar.ResetButton.DropDown, 0, 0, "BOTTOM", self.BottomBar.ResetButton, "TOP")
    UIDropDownMenu_Initialize(self.BottomBar.ResetButton.DropDown, GenerateClosure(self.InitializeResetDropDown, self), "MENU")
end

function CoATreeViewMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT")
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:RegisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:RegisterEvent("BUILD_CREATOR_ACTIVATE_RESULT")
    self:RegisterEvent("BUILD_CREATOR_DEACTIVATE_RESULT")
    self:ApplyFooterLayout()
    self:UpdateCommitButtons()
    self:UpdatePoints()
    self:UpdateDropDowns()
    self.Background3.Anim:Play()
end 

function CoATreeViewMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT")
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
    self:UnregisterEvent("ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
    self:UnregisterEvent("BUILD_CREATOR_ACTIVATE_RESULT")
    self:UnregisterEvent("BUILD_CREATOR_DEACTIVATE_RESULT")
    self.Background3.Anim:Stop()
end

function CoATreeViewMixin:MarkTreesDirty()
    self.ClassTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
    self.SpecTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Nodes)
end

function CoATreeViewMixin:InitializeResetDropDown(dropdown, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_TITLE
    info.isTitle = true
    UIDropDownMenu_AddButton(info, level)
    
    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_LEFT
    info.func = function()
        self.ClassTree:ResetTree()
    end
    UIDropDownMenu_AddButton(info, level)

    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_RIGHT
    info.func = function()
        self.SpecTree:ResetTree()
    end
    UIDropDownMenu_AddButton(info, level)

    UIDropDownMenu_CreateInfo()
    info.text = TALENT_FRAME_RESET_BUTTON_DROPDOWN_ALL
    info.func = function()
        C_CharacterAdvancement.ClearPendingBuild(Const.CharacterAdvancement.OnlyClearAllowed)
    end
    UIDropDownMenu_AddButton(info, level)
end

function CoATreeViewMixin:ShowResetDropDown()
    ToggleDropDownMenu(1, nil, self.BottomBar.ResetButton.DropDown);
end

function CoATreeViewMixin:CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT(success, reason)
    if success then
        PlaySound(SOUNDKIT.UI_CLASS_TALENT_APPLY_COMPLETE)
    end
end

function CoATreeViewMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:UpdateCommitButtons()
    self:UpdatePoints()
end

function CoATreeViewMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED()
    self:UpdateDropDowns()
end

function CoATreeViewMixin:BUILD_CREATOR_ACTIVATE_RESULT()
    self:UpdateDropDowns()
end

function CoATreeViewMixin:BUILD_CREATOR_DEACTIVATE_RESULT()
    self:UpdateDropDowns()
    self:UpdateDeactivateBuildButton(BuildCreatorUtil.GetActiveBuildID())
end

function CoATreeViewMixin:UpdateDropDowns()
    UIDropDownMenu_SetText(self.BottomBar.SpecDropDown, COA_CHANGE_ACTIVE_SPECIALIZATION)
    
    local activeBuildID = BuildCreatorUtil.GetActiveBuildID()
    self:UpdateDeactivateBuildButton(activeBuildID)
    if activeBuildID == self.activeBuildID then
        return
    end
    
    self.activeBuildID = activeBuildID

    if activeBuildID then
        BuildCreatorUtil.ContinueOnLoad(activeBuildID, function(build)
            if build then
                UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, CoACharacterAdvancementUtil.StripArchitectTag(build.Name))
            else
                UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, TALENTS_IMPORT_HERO_ARCHITECT)
            end
        end)
    end
    UIDropDownMenu_SetText(self.BottomBar.BuildDropDown, TALENTS_IMPORT_HERO_ARCHITECT)
end

function CoATreeViewMixin:UpdateDeactivateBuildButton(activeBuildID)
    local hasActiveBuild = activeBuildID and activeBuildID ~= false
    self.BottomBar.DeactivateBuild:SetShown(hasActiveBuild)
    self.BottomBar.DeactivateBuild:SetEnabled(hasActiveBuild)
end

function CoATreeViewMixin:UpdatePoints()
    local remainingClass = C_CharacterAdvancement.GetPendingRemainingAE()
    local remainingSpec = C_CharacterAdvancement.GetPendingRemainingTE()
    
    self.ClassTree.Points:SetText(remainingClass)
    if remainingClass > 0 then
        self.ClassTree.Points:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        self.ClassTree.Points:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end

    self.SpecTree.Points:SetText(remainingSpec)
    if remainingSpec > 0 then
        self.SpecTree.Points:SetTextColor(GREEN_FONT_COLOR:GetRGB())
    else
        self.SpecTree.Points:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end
end

function CoATreeViewMixin:UpdateCommitButtons()
    local hasPendingChanges = C_CharacterAdvancement.IsPending()
    self.BottomBar.UndoButton:SetShown(hasPendingChanges)
    self.BottomBar.SaveChanges.YellowGlow:SetShown(hasPendingChanges)
    self.BottomBar.ResetButton:SetShown(not hasPendingChanges)

    local canApplyPendingChanges, reason, traversalError, entryID, entryRank, marksCost, goldCost, tokenType, tokenCost = C_CharacterAdvancement.CanApplyPendingBuild()
    self.BottomBar.SaveChanges:SetEnabled(canApplyPendingChanges)
    if hasPendingChanges then
        self.BottomBar.SaveChanges.tooltipTitle = CA_UNABLE_TO_SAVE_PENDING_BUILD
        local error = _G[reason] or reason or ""
        local entry = entryID and C_CharacterAdvancement.GetEntryByInternalID(entryID)
        error = error:format(entry and entry.Name or entryID, entryRank or "", traversalError and _G[traversalError] or traversalError or "")
        self.BottomBar.SaveChanges.tooltipText = RED_FONT_COLOR:WrapText(error)
    else
        self.BottomBar.SaveChanges.tooltipTitle = nil
        self.BottomBar.SaveChanges.tooltipText = nil
    end
end

function CoATreeViewMixin:SetSpecID(specID)
    if self.specID == specID then
        return
    end

    self.specID = specID
    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
    local specFile = specInfo.Spec
    local specDBC = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)
    local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(specInfo.Class)
    self.SpecTree.Label:SetText(specInfo.Name:upper())
    local specArt = CharacterAdvancementUtil.GetBackgroundAtlas(specInfo.Class, specInfo.Spec)
    self.Background1:SetAtlas(specArt)
    --self.Background2:SetAtlas(specArt)
    self.Background3:SetAtlas(specArt)
    self.SpecTree:SetClassTab(classDBC, specDBC)
end 

function CoATreeViewMixin:UpdateSearch()
    local search = self.BottomBar.Search:GetText()
    C_CharacterAdvancement.SetFilteredEntries(search, table.empty)
    self.ClassTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Search)
    self.SpecTree:MarkDirty(TalentTreeBaseMixin.DirtyReason.Search)
end 

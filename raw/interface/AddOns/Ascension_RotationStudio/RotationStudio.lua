ROTATION_STUDIO_DEFAULT_PROFILE = ROTATION_STUDIO_DEFAULT_PROFILE or "%s's Rotation"
RotationStudio = {}

RotationStudio.Mode = {
    Rotation = 1,
    Priority = 2,
}

RotationStudio.Configurability = {
    Basic = 1,
}

RotationStudio.ActionConditions = {
    FakeCooldown = 1,
    TargetMissingDebuff = 2,
    PlayerMissingBuff = 3,
}

RotationStudioMixin = {}
RotationStudioMixin.OnEvent = OnEventToMethod

-- ACTION CONDITIONS
--self.selectedAction.fakeCooldown = fakeCooldown
--self.selectedAction.targetMissingDebuff = missingDebuff
--self.selectedAction.playerMissingBuff = missingBuff

function RotationStudioMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    BasicFrame_SetTitle(self, "ROTATION_STUDIO")
    self.Background:SetAtlas("collections-background-tile", Const.TextureKit.IgnoreAtlasSize)
    self.ActionList.Background:SetAtlas("professions-background-summarylist", Const.TextureKit.IgnoreAtlasSize)

    self.ActionList:SetGetNumResultsFunction(GenerateClosure(self.GetNumActions, self))
    self.ActionList:SetTemplate("RotationStudioActionItemTemplate")

    self.ActionList:SetSelectionCallback(GenerateClosure(self.OnActionSelected, self))
    self.ActionList:SetAllowSelectingSelected(true)

    self.ActionList:SetSelectedHighlightAtlas("pvpqueue-button-casual-selected")
    self.ActionList:SetSelectedHighlightBlendMode("ADD")
    
    self:RegisterEvent("ADDON_LOADED")
    
    self.ActiveRotation = {
        LastIndex = 0,
        Cooldowns = {},
    }
    
    self.MyGUID = UnitGUID("player")
end 

function RotationStudioMixin:GetNumActions()
    if not RotationStudio.ActiveProfile then
        return 0
    end
    
    return #RotationStudio.ActiveProfile.Actions + 1
end

function RotationStudioMixin:GetActionAtIndex(index)
    return RotationStudio.ActiveProfile and RotationStudio.ActiveProfile.Actions[index - 1]
end

function RotationStudioMixin:OnActionSelected(index)
    if index == 1 then
        return self:OpenSpellbook()
    end
    
    local action = self:GetActionAtIndex(index)
    self:SetSelectedAction(action)
end

function RotationStudioMixin:SetSelectedAction(action)
    self.selectedAction = action

    if action == nil then
        self.RightPanel.SpellSettings:Hide()
        return
    end
    
    self.RightPanel.SpellSettings:Show()

    local spellSettings = self.RightPanel.SpellSettings
    local name, _, icon = GetSpellInfo(action.SpellID)
    spellSettings.Label:SetText(name)
    spellSettings.Icon:SetTexture(icon)
    spellSettings.FakeCooldown:SetText(action[RotationStudio.ActionConditions.FakeCooldown] or "")
    spellSettings.MissingDebuff:SetChecked(action[RotationStudio.ActionConditions.TargetMissingDebuff])
    spellSettings.MissingBuff:SetChecked(action[RotationStudio.ActionConditions.PlayerMissingBuff])
end

function RotationStudioMixin:RefreshSelectedAction()
    if self.selectedAction then
        local spellSettings = self.RightPanel.SpellSettings
        
        local fakeCooldown = tonumber(spellSettings.FakeCooldown:GetText()) or 0
        local missingDebuff = spellSettings.MissingDebuff:GetCheckedBool()
        local missingBuff = spellSettings.MissingBuff:GetCheckedBool()
        
        self.selectedAction[RotationStudio.ActionConditions.FakeCooldown] = fakeCooldown > 0 and fakeCooldown or nil
        self.selectedAction[RotationStudio.ActionConditions.TargetMissingDebuff] = missingDebuff
        self.selectedAction[RotationStudio.ActionConditions.PlayerMissingBuff] = missingBuff
        
        self.ActionList:RefreshScrollFrame()
    end
end

function RotationStudioMixin:AddAction(index, id)
    local action = {
        SpellID = id,
    }
    
    table.insert(RotationStudio.ActiveProfile.Actions, index, action)
    self:Refresh()
end

function RotationStudioMixin:RemoveActionAtIndex(index)
    table.remove(RotationStudio.ActiveProfile.Actions, math.max(index - 1, 1))
    self:Refresh()
end

function RotationStudioMixin:OnShow()
    if RotationStudio_Profile then
        self:LoadProfile(RotationStudio_Profile)
    end
end

function RotationStudioMixin:SetConfigurability(mode)
    if RotationStudio.ActiveProfile then
        RotationStudio.ActiveProfile.Configurability = mode
    end
    
    self:Layout()
end

function RotationStudioMixin:Refresh()
    self.ActionList:RefreshScrollFrame()
end 

function RotationStudioMixin:Layout()
    self:Refresh()
end 

function RotationStudioMixin:LoadProfile(profile)
    local profileData = RotationStudio_Saved[profile]
    if not profileData then
        profileData = {}
        profileData.Name = profile
        profileData.Mode = RotationStudio.Mode.Priority
        profileData.Configurability = RotationStudio.Configurability.Basic
        profileData.Actions = {}
        RotationStudio_Saved[profile] = profileData
    end
    
    RotationStudio.ActiveProfile = profileData
    self:Layout()
end 

function RotationStudioMixin:OpenSpellbook()
    if not AscensionSpellbookFrame:IsShown() then
        ToggleSpellBook(BOOKTYPE_SPELL)
    end
end

function RotationStudioMixin:ADDON_LOADED(addonName)
    if addonName == "Ascension_RotationStudio" then
        RotationStudio_Saved = RotationStudio_Saved or {}
        RotationStudio_Profile = RotationStudio_Profile or ROTATION_STUDIO_DEFAULT_PROFILE:format(UnitName("player"))
        if self:IsShown() then
            self:LoadProfile(RotationStudio_Profile)
        end
    end
end

function RotationStudioMixin:EnableSingleButton()
    self.ActiveRotation.LastIndex = 0
    wipe(self.ActiveRotation.Cooldowns)
    if not self.SingleButton then
        self.SingleButton = ExtraActionBar:AddLazyAction()
    end
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:UpdateNextBestAction()
end 

function RotationStudioMixin:DisableSingleButton()
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end 

function RotationStudioMixin:UNIT_SPELLCAST_SUCCEEDED(unit, spellName, spellRank)
    if unit ~= "player" then
        return
    end

    if self.SingleButton then
        local spellID = C_Spell:GetSpellID(spellName, spellRank)

        if RotationStudio.ActiveProfile.Mode == RotationStudio.Mode.Priority then
            for _, action in ipairs(RotationStudio.ActiveProfile.Actions) do
                if action.SpellID == spellID then
                    local fakeCD = action[RotationStudio.ActionConditions.FakeCooldown]
                    if fakeCD then
                        self.ActiveRotation.Cooldowns[spellID] = fakeCD + GetTime()
                    end
                end
            end
        end

        if self.SingleButton:GetAction() == spellID then
            self:UpdateNextBestAction()
        end
    end
end

function RotationStudioMixin:SPELL_UPDATE_COOLDOWN()
    local profile = RotationStudio.ActiveProfile
    if profile.Mode == RotationStudio.Mode.Priority then
        self:UpdateNextBestActionPriority()
    end
end

function RotationStudioMixin:UNIT_AURA(unit)
    if unit ~= "player" and unit ~= "target" then
        return
    end

    local profile = RotationStudio.ActiveProfile
    if profile.Mode == RotationStudio.Mode.Priority then
        self:UpdateNextBestActionPriority()
    end
end

function RotationStudioMixin:PLAYER_TARGET_CHANGED()
    local profile = RotationStudio.ActiveProfile
    if profile.Mode == RotationStudio.Mode.Priority then
        self:UpdateNextBestActionPriority()
    end
end

function RotationStudioMixin:OnDragStart()
    self:StartMoving()
end

function RotationStudioMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function RotationStudioMixin:UpdateNextBestAction()
    if not self.SingleButton then
        return
    end
    
    local profileMode = RotationStudio.ActiveProfile.Mode

    if profileMode == RotationStudio.Mode.Priority then
        self:UpdateNextBestActionPriority()
    elseif profileMode == RotationStudio.Mode.Rotation then
        self:UpdateNextBestActionRotation()
    end 
end 

function RotationStudioMixin:UpdateNextBestActionRotation()
    local profile = RotationStudio.ActiveProfile
    local button = self.SingleButton

    local nextIndex = self.ActiveRotation.LastIndex + 1

    local nextAction = profile.Actions[nextIndex]
    if not nextAction then
        nextIndex = 1
        nextAction = profile.Actions[nextIndex]
    end
    local spellID = nextAction.SpellID
    local name = GetSpellInfo(spellID)
    button:SetAction("ACTION_TYPE_SPELL", name, spellID, "none")
    self.ActiveRotation.LastIndex = nextIndex
end 

function RotationStudioMixin:UpdateNextBestActionPriority()
    local profile = RotationStudio.ActiveProfile
    local button = self.SingleButton
    local currentAction = button:GetAction()
    local now = GetTime()
    button:ClearFakeCooldown()
    
    local nextBestAction

    for _, action in ipairs(profile.Actions) do
        local spellID = action.SpellID
        local name = GetSpellInfo(spellID)

        local fakeCooldownTime = action[RotationStudio.ActionConditions.FakeCooldown]
        if fakeCooldownTime then
            local currentCooldown = self.ActiveRotation.Cooldowns[spellID]
            if not currentCooldown or self.ActiveRotation.Cooldowns[spellID] < now then
                if currentAction ~= spellID then
                    dprint("[RotationStudio.Priority] Conditioned to", spellID, "Reason: Fake Cooldown is over")
                    button:SetAction("ACTION_TYPE_SPELL", name, spellID, "none")
                end
                return
            end
        end
        
        local requiresDebuff = action[RotationStudio.ActionConditions.TargetMissingDebuff]
        if requiresDebuff then
            if not C_Aura.UnitHasAura("target", spellID) then
                if currentAction ~= spellID then
                    dprint("[RotationStudio.Priority] Conditioned to", spellID, "Reason: Target Missing Debuff")
                    button:SetAction("ACTION_TYPE_SPELL", name, spellID, "none")
                end
                return
            end
        end
        
        local requiresBuff = action[RotationStudio.ActionConditions.PlayerMissingBuff]
        if requiresBuff then
            if not C_Aura.UnitAura("player", spellID) then
                if currentAction ~= spellID then
                    dprint("[RotationStudio.Priority] Conditioned to", spellID, "Reason: Player Missing Buff")
                    button:SetAction("ACTION_TYPE_SPELL", name, spellID, "none")
                end
                return
            end
        end

        if not nextBestAction and not fakeCooldownTime and not requiresDebuff and not requiresBuff then
            local startTime, duration, enabled = GetSpellCooldown(spellID)
            if enabled == 0 or duration <= 1.5 then
                nextBestAction = action
            end
        end
    end

    local action = nextBestAction or profile.Actions[1]
    local spellID = action.SpellID
    local name = GetSpellInfo(spellID)
    local fakeCooldownTime = action[RotationStudio.ActionConditions.FakeCooldown]

    if button:GetAction() ~= spellID then
        dprint("[RotationStudio.Priority] Conditioned to", spellID, "Reason: Highest Priority")
        button:SetAction("ACTION_TYPE_SPELL", name, spellID, "none")
        if fakeCooldownTime then
            local currentCooldownEnd = self.ActiveRotation.Cooldowns[spellID]
            if currentCooldownEnd then
                button:TriggerCooldown(currentCooldownEnd - GetTime())
            else
                button:ClearFakeCooldown()
            end
        end
    end
end 
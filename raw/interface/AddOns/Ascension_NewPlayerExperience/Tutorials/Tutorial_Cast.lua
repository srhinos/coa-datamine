local _, NPE = ...

DAMAGE_TIP_BASIC = DAMAGE_TIP_BASIC or "Use to cause damage to your target"
DAMAGE_TIP_SECONDARY = DAMAGE_TIP_SECONDARY or "Great! Cast Ability once again!"
DAMAGE_TIP_SECONDARY_HOTKEY = DAMAGE_TIP_SECONDARY_HOTKEY or "Great! Hit |cffFFFF00(%s)|r to cast Ability once again!"
DAMAGE_TIP_HOTKEY = DAMAGE_TIP_HOTKEY or "Hit |cffFFFF00(%s)|r to cast |cff71d5ff[%s]|r"
DAMAGE_TIP_NOBIND = DAMAGE_TIP_NOBIND or "Click to cast |cff71d5ff[%s]|r"
DAMAGE_TIP_TAME = DAMAGE_TIP_TAME or "Great! Keep |cff71d5ff[%s]|r active until you tame %s"

local castInfo = {
	actionButton = nil,
	spellName = nil,
	timesCasted = 0,
	timesToCast = 2,
	spellIcon = "",
}


local CAST_SPELL_DAMAGE_KEY = "PopupLootCorpse"

local PopupCastSpellCorpse = {
    key = CAST_SPELL_DAMAGE_KEY,
    iconWidth = 48,
    iconHeight = 48,
    priority = NPE.Const.PopupPriority.HIGH,
    fontSize = 16,
}

--[[HelpTips["CAST_SPELL_DAMAGE"] = {
    parent = "UIParent",
    text = "",
    textSize = 14,
    textJustifyH = "CENTER",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    offsetX = 8,
    highlightTarget = HelpTip.TargetType.Box,
}]]--

local function ShowCastPopup()
    if NPE:IsTutorialComplete(NPE.Const.Tutorials.CAST_TUTORIAL) then
        return
    end

	PopupCastSpellCorpse.icon = castInfo.spellIcon
	NPE:ClearDialogPopup(CAST_SPELL_DAMAGE_KEY)
	NPE:ShowDialogPopup(PopupCastSpellCorpse)
end

local function GetActionButtonKey(button)
    local hotkey = _G[button:GetName().."HotKey"]

    if hotkey and (hotkey:GetText() ~= RANGE_INDICATOR) then
        return hotkey:GetText()
    end

    return nil
end

local function DefineHelpTipText()
	if not(castInfo.spellName) then
		return ""
	end

	local hotKey = castInfo.actionButton and GetActionButtonKey(castInfo.actionButton)

	if castInfo.timesCasted == 1 then

		if hotKey then
			PopupCastSpellCorpse.text = string.format(DAMAGE_TIP_SECONDARY_HOTKEY, hotKey)
		else
			PopupCastSpellCorpse.text = DAMAGE_TIP_SECONDARY
		end
		return
	end

    local castLine = string.format(DAMAGE_TIP_NOBIND, castInfo.spellName)

    if (hotKey) then
        castLine = string.format(DAMAGE_TIP_HOTKEY, hotKey, castInfo.spellName)
    end

    PopupCastSpellCorpse.text = castLine
end

local function OnLeaveCombat()
	NPE:StopTutorial(NPE.Const.Tutorials.CAST_TUTORIAL)
	NPE:ClearDialogPopup(CAST_SPELL_DAMAGE_KEY)
end

local function UnregiserHandlers(self)
    dprint("UnregiserHandlers, "..self:GetName())
    if self.eventHandleOnLeaveCombat then
        self.eventHandleOnLeaveCombat:Unregister()
        self.eventHandleOnLeaveCombat = nil
    end

    if self.eventHandleSpellCast then
        self.eventHandleSpellCast:Unregister()
        self.eventHandleSpellCast = nil
    end

    if self.eventHandleOnEnterCombat then
        self.eventHandleOnEnterCombat:Unregister()
        self.eventHandleOnEnterCombat = nil
    end
end

local function OnEnterCombat(self)
	dprint("OnEnterCombatCheck")

    if not self:IsAppropriateLevel() then
        self:Stop()
        UnregiserHandlers(self)
        return
    end

    for _, barName in pairs(NPE.Const.ActionBars) do
        for i = 1, 12 do
            if (_G[barName]:IsVisible()) then
                local buttonName = barName .. "Button" .. i
                if (barName == "BonusActionBarFrame") then
                    buttonName = "BonusActionButton" .. i
                elseif (barName == "MainMenuBar") then
                    buttonName = "ActionButton" .. i
                end
                local button = _G[buttonName]
                local slot = ActionButton_GetPagedID(button) or ActionButton_CalculateAction(button) or button:GetAttribute("action") or 0
                if HasAction(slot) then
                    local actionType, id, subType, spellID = GetActionInfo(slot)
                    if actionType == "spell" and spellID and NPE.Const.DamageSpells[spellID] then
                        castInfo.actionButton = button
			    		castInfo.spellName, _, castInfo.spellIcon = GetSpellInfo(spellID)
			    		NPE:StartTutorial(NPE.Const.Tutorials.CAST_TUTORIAL)
			    		return
                    end
                end
            end
        end
    end
end

local function OnSpellCast(self, ...)
    local caster, spellName, rankLine, target = ...

    if (caster ~= "player") then
        return
    end

    if spellName == castInfo.spellName then
		castInfo.timesCasted = castInfo.timesCasted + 1
	end
end

--
-- How to cast basic tutorial
--
do
    local tutorial = NPE:NewTutorial(NPE.Const.Tutorials.CAST_TUTORIAL)

    tutorial:SetFinalStepCompletes(true)
    tutorial:SetAutoStart(true)
    tutorial:SetMinMaxLevel(1, 10)
    tutorial:SetMinTutorialExperience(Enum.TutorialExperience.NewToWoW)

    tutorial:RegisterCallback("TutorialStarted", function()
        dprint(tutorial:GetName().." started!")

        if not tutorial.eventHandleOnEnterCombat then
            dprint("register handles")
            tutorial.eventHandleOnEnterCombat = tutorial:RegisterEventCallbackWithHandle("PLAYER_REGEN_DISABLED", OnEnterCombat, tutorial)
            tutorial.eventHandleOnLeaveCombat = tutorial:RegisterEventCallbackWithHandle("PLAYER_REGEN_ENABLED", OnLeaveCombat, tutorial)
        end
    end)

    tutorial:RegisterCallback("TutorialCompleted", function()
    	dprint(tutorial:GetName().." TutorialCompleted!")

    	UnregiserHandlers(tutorial)

	    NPE:SetPopupComplete(CAST_SPELL_DAMAGE_KEY, true)
    end)

    tutorial:RegisterCallback("TutorialFinished", function()
        dprint(tutorial:GetName().." Finished!")
        castInfo.actionButton = nil

        --HelpTip:Hide("CAST_SPELL_DAMAGE")

        if tutorial.eventHandleSpellCast then
        	tutorial.eventHandleSpellCast:Unregister()
        	tutorial.eventHandleSpellCast = nil
        end
    end)

	-- step 1: Wait for to enter combat
    local step1 = tutorial:AddStep()
    step1:SetShouldSaveProgress(false)
    step1:SetCompletionCondition(function()
        return castInfo.actionButton
    end)

    -- step 2: Show help tip for casting damage
    local step2 = tutorial:AddStep()
    step2:SetShouldSaveProgress(false)
    step2:SetCompletionCondition(function()
        return castInfo.timesCasted >= 1
    end)

    step2:RegisterCallback("StepStarted", function()
    	dprint(tutorial:GetName().." step 2!")
    	if not tutorial.eventHandleSpellCast then
    		tutorial.eventHandleSpellCast = tutorial:RegisterEventCallbackWithHandle("UNIT_SPELLCAST_SUCCEEDED", OnSpellCast, tutorial)
    	end
    	
    	DefineHelpTipText()
    	ShowCastPopup()
    	--HelpTips["CAST_SPELL_DAMAGE"].parent = castInfo.actionButton
    	--HelpTip:Show("CAST_SPELL_DAMAGE")
	end)

    -- step 3: Show help for to second time cast ability
    local step3 = tutorial:AddStep()
    step3:SetShouldSaveProgress(true)
    step3:SetCompletionCondition(function()
        return castInfo.timesCasted >= castInfo.timesToCast
    end)

    step3:RegisterCallback("StepStarted", function()
    	castInfo.timesCasted = 1
    	dprint(tutorial:GetName().." step 3!")

    	if not tutorial.eventHandleSpellCast then
    		tutorial.eventHandleSpellCast = tutorial:RegisterEventCallbackWithHandle("UNIT_SPELLCAST_SUCCEEDED", OnSpellCast, tutorial)
    	end

    	--HelpTip:Hide("CAST_SPELL_DAMAGE")
    	DefineHelpTipText()

    	NPE:SetPopupComplete(CAST_SPELL_DAMAGE_KEY)
    	Timer.After(0.5, ShowCastPopup)

    	--HelpTips["CAST_SPELL_DAMAGE"].parent = castInfo.actionButton
    	--HelpTip:Show("CAST_SPELL_DAMAGE")
	end)

    NPE:AddTutorial(tutorial)
end
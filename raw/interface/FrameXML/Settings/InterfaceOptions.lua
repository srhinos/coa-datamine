--
-- How To: Adding New Options
--
--[[
    - Copy an existing option and modify it to your needs.
    - Text is a reference to _G[text]. The tooltip of the option will be _G["OPTION_TOOLTIP_"..text]
    - - For example: text = "SHOW_HELP_TIPS" -> tooltip = OPTION_TOOLTIP_SHOW_HELP_TIPS
    - if your option does not have a cvar, use a label instead. Label is just a stand-in for cvar when none exists. 
    - - This is so blizz options can find the config table for the option, and Option.GetControlForCVar can find the control by cvar / label.

]]--
-------------------------------------------------------------------------------------------------
-- 
-- Controls Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsControlsPanel", InterfaceOptionsFramePanelContainer, CONTROLS_LABEL, CONTROLS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)
    
    category:AddOption("StickyTargeting", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "deselectOnClick",
        text = "GAMEFIELD_DESELECT_TEXT",
        inverted = true,
    })

    category:AddOption("AutoDismount", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoDismountFlying",
        text = "AUTO_DISMOUNT_FLYING_TEXT",
    })

    category:AddOption("AutoClearAFK", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoClearAFK",
        text = "CLEAR_AFK",
    })

    category:AddOption("BlockTrades", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "blockTrades",
        text = "BLOCK_TRADES",
    })

    category:AddOption("AutoAcceptTrades", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoAcceptTrades",
        text = "AUTO_ACCEPT_TRADES",
    })
    
    category:StartGroup(LOOT_OPTIONS, Options.Column.Center)

    category:AddOption("AutoLootDefault", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "autoLootDefault",
        text = "AUTO_LOOT_DEFAULT_TEXT",
        setFunc = function() InterfaceOptionsControlsPanelAutoLootKeyDropDown_Update() end,
    })

    category:AddOption("LootUnderMouse", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "lootUnderMouse",
        text = "LOOT_UNDER_MOUSE_TEXT",
    })

    category:AddOption("AutoLootKeyDropDown", "dropdown", Options.Column.Center, Options.Width.Single, {
        label = "autoLootKey",
        init = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnLoad,
        onShow = InterfaceOptionsControlsPanelAutoLootKeyDropDown_OnShow,
        text = "AUTO_LOOT_KEY_TEXT",
    })

    category:CloseGroup(Options.Column.Center)

    InterfaceSettings_AddCategory(category)
end

--
-- Display Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsDisplayPanel", InterfaceOptionsFramePanelContainer, DISPLAY_LABEL, DISPLAY_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)
    
    category:AddOption("ShowHelm", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showHelm",
        text = "SHOW_HELM",
        setFunc = function(value) ShowHelm(value) end,
        GetValue = function() return ShowingHelm() and "1" or "0" end,
    })

    category:AddOption("ShowCloak", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showCloak",
        text = "SHOW_CLOAK",
        setFunc = function(value) ShowCloak(value) end,
        GetValue = function() return ShowingCloak() and "1" or "0" end,
    })

    category:AddOption("RotateMinimap", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "rotateMinimap",
        text = "ROTATE_MINIMAP",
        setFunc = function() Minimap_UpdateRotationSetting() end,
    })

    category:AddOption("ShowClock", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showClock",
        text = "SHOW_CLOCK",
        setFunc = function(value) InterfaceOptionsDisplayPanelShowClock_SetFunc(value) end,
    })

    category:AddOption("ScreenEdgeFlash", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "screenEdgeFlash",
        text = "SHOW_FULLSCREEN_STATUS_TEXT",
    }) 

    category:AddOption("ShowLootSpam", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showLootSpam",
        text = "SHOW_LOOT_SPAM",
    })

    category:AddOption("DisplayFreeBagSlots", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "displayFreeBagSlots",
        text = "DISPLAY_FREE_BAG_SLOTS",
    })

    category:AddOption("MovieSubtitle", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "movieSubtitle",
        text = "CINEMATIC_SUBTITLES",
    })

    category:AddOption("ShowAggroPercentage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "threatShowNumeric",
        setFunc = function(value) InterfaceOptionsDisplayPanelShowAggroPercentage_SetFunc() end,
        text = "SHOW_NUMERIC_THREAT",
    })

    category:AddOption("ThreatPlaySounds", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "threatPlaySounds",
        text = "PLAY_AGGRO_SOUNDS",
    })

    category:AddOption("ColorblindMode", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "colorblindMode",
        uvar = "ENABLE_COLORBLIND_MODE",
        setFunc = function() WatchFrame_Update() if ( IsAddOnLoaded("Blizzard_AchievementUI") ) then AchievementFrame_ForceUpdate() end end,
        text = "USE_COLORBLIND_MODE",
    })

    category:AddOption("ShowItemLevel", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showItemLevel",
        text = "SHOW_ITEM_LEVEL",
    })

    category:AddOption("HighlightNewItems", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "HighlightNewItems",
        text = "SHOW_NEW_ITEMS",
    })

    category:AddOption("SelectionCircleMode", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "ObjectSelectionCircleMode",
        text = "SELECTION_CIRCLE_MODE",
    })

    --[[category:AddOption("SelectionCircleOpacity", "slider", Options.Column.Center, Options.Width.FullSingle, {
        cvar = "ObjectSelectionCircleOpacity",
        text = "SELECTION_CIRCLE_OPACITY",
        minValue = 0,
        maxValue = 1,
        valueStep = 0.05,
        displayAsPercent = true,
    })]]

    category:AddOption("SelectionCircle", "dropdown", Options.Column.Center, Options.Width.FullSingle, {
        cvar = "ObjectSelectionCircleTexture",
        init = InterfaceOptionsDisplayPanelSelectionCircle_OnLoad,
        onShow = InterfaceOptionsDisplayPanelSelectionCircle_OnShow,
        text = "SELECTION_CIRCLE_LABEL",
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Combat Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsCombatPanel", InterfaceOptionsFramePanelContainer, COMBAT_LABEL, COMBAT_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("AttackOnAssist", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "assistAttack",
        text = "ASSIST_ATTACK",
    })

    category:AddOption("AutoRange", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoRangedCombat",
        text = "AUTO_RANGED_COMBAT_TEXT",
    })

    category:AddOption("StopAutoAttack", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "stopAutoAttackOnTargetChange",
        text = "STOP_AUTO_ATTACK",
    })

    category:AddOption("AutoSelfCast", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoSelfCast",
        text = "AUTO_SELF_CAST_TEXT",
    })

    category:AddOption("SelfCastKeyDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
        label = "autoSelfCastKey",
        init = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnLoad,
        onShow = InterfaceOptionsCombatPanelSelfCastKeyDropDown_OnShow,
        text = "AUTO_SELF_CAST_KEY_TEXT",
    })

    category:AddOption("TargetOfTarget", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showTargetOfTarget",
        uvar = "SHOW_TARGET_OF_TARGET",
        text = "SHOW_TARGET_OF_TARGET_TEXT",
    })

    category:AddOption("TOTDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
        label = "showTargetOfTarget",
        uvar = "SHOW_TARGET_OF_TARGET_STATE",
        init = InterfaceOptionsCombatPanelTOTDropDown_OnLoad,
        onShow = InterfaceOptionsCombatPanelTOTDropDown_OnShow,
        text = "SHOW_TARGET_OF_TARGET_TEXT",
    })

    category:AddOption("FocusCastKeyDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
        label = "focusCastKey",
        init = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnLoad,
        onShow = InterfaceOptionsCombatPanelFocusCastKeyDropDown_OnShow,
        text = "FOCUS_CAST_KEY_TEXT",
    })

    category:AddOption("AutoAssistCast", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoAssistCast",
        text = "AUTO_ASSIST_CAST",
    })
    
    category:AddOption("HoldToCast", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "holdToCast",
        text = "HOLD_TO_CAST_TEXT",
    })

    category:StartGroup(SHOW_ENEMY_CAST, Options.Column.Right)

    category:AddOption("EnemyCastBarsOnPortrait", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "showTargetCastbar",
        text = "SHOW_TARGET_CASTBAR",
    })

    category:AddOption("EnemyCastBarsOnNameplates", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "showVKeyCastbar",
        text = "SHOW_TARGET_CASTBAR_IN_V_KEY",
    })

    category:CloseGroup(Options.Column.Right)

    category:AddOption("SpellQueue", "slider", Options.Column.Right, Options.Width.Single, {
        cvar = "SpellQueueWindow",
        text = "SPELL_QUEUE_WINDOW",
        minValue = 1,
        maxValue = 1000,
        valueStep = 10,
        indentLevel = Options.Indent.Double,
    })

    category:StartGroup(AOE_RADIUS_INDICATORS, Options.Column.Center)

    category:AddOption("Self", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "aoeRadiusIndicatorSelf",
        text = "AOE_RADIUS_INDICATOR_SELF",
    })

    category:AddOption("Enemies", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "aoeRadiusIndicatorEnemy",
        text = "AOE_RADIUS_INDICATOR_ENEMY",
    })

    category:AddOption("Friendly", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "aoeRadiusIndicatorFriendly",
        text = "AOE_RADIUS_INDICATOR_FRIEND",
    })

    category:CloseGroup(Options.Column.Center)

    local enableOverlays = category:AddOption("SpellActivationOverlayEnabled", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "SpellActivationOverlayEnabled",
        uvar = "SPELL_ACTIVATION_OVERLAY_ENABLED",
        text = "ENABLE_SPELL_ACTIVATION_OVERLAY",
    })

    category:AddOption("SpellActivationOverlays", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "SpellActivationOverlayAlpha",
        text = "SPELL_ACTIVATION_OVERLAY",
        indent = Options.Indent.Double,
        minValue = 0,
        maxValue = 1,
        valueStep = 0.05,
        displayAsPercent = true,
        dependentControl = enableOverlays,
    })


    InterfaceSettings_AddCategory(category)
end

--
-- Objectives Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsObjectivesPanel", InterfaceOptionsFramePanelContainer, OBJECTIVES_LABEL, OBJECTIVES_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("InstantQuestText", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "questFadingDisable",
        uvar = "QUEST_FADING_DISABLE",
        text = "SHOW_QUEST_FADING_TEXT",
    })

    category:AddOption("AutoQuestTracking", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoQuestWatch",
        uvar = "AUTO_QUEST_WATCH",
        text = "AUTO_QUEST_WATCH_TEXT",
    })

    category:AddOption("AutoQuestProgress", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoQuestProgress",
        uvar = "AUTO_QUEST_PROGRESS",
        text = "AUTO_QUEST_PROGRESS_TEXT",
    })

    category:AddOption("MapQuestDifficulty", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "mapQuestDifficulty",
        uvar = "MAP_QUEST_DIFFICULTY",
        setFunc = function () WorldMapFrame_ResetQuestColors() end,
        text = "MAP_QUEST_DIFFICULTY_TEXT",
    })

    category:AddOption("AdvancedWorldMap", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "advancedWorldMap",
        text = "ADVANCED_WORLD_MAP_TEXT",
        setFunc = function() WorldMapFrame_ToggleAdvanced() end,
    })

    category:AddOption("WatchFrameWidth", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "watchFrameWidth",
        uvar = "WATCH_FRAME_WIDTH",
        text = "WATCH_FRAME_WIDTH_TEXT",
        setFunc = function() WatchFrame_SetWidth(WATCH_FRAME_WIDTH) end,
    })

    category:AddOption("PTAQuests", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "ptaAutoQuestEnabled",
        text = "POPUP_PTA_QUESTS_TEXT",
        init = function(self)
            local isNew = C_NoviceNetwork:IsNewcomer()
            self:SetEnabled(not isNew or C_Player:IsPrestiged() or C_Player:GetLevel() >= GetMaxLevel())
        end,
    })

    category:AddOption("InGameNavigation", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showInGameNavigation",
        text = "SHOW_IN_GAME_NAVIGATION",
        setFunc = function() SuperTrackerUtil.SetToBestSuperTrackingType() end
    })

    category:AddOption("ShowQuestUnitCircles", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showQuestUnitCircles",
        text = "SHOW_QUEST_UNIT_CIRCLES",
    }) 

    --lootArtScale slider
    category:AddOption("LootArtScale", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "lootArtScale",
        text = "LOOT_ART_SCALE",
        minValue = 1,
        maxValue = 3,
        valueStep = 1,
    })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Social Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsSocialPanel", InterfaceOptionsFramePanelContainer, SOCIAL_LABEL, SOCIAL_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("ProfanityFilter", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "profanityFilter",
        text = "PROFANITY_FILTER",
    })

    category:AddOption("ChatBubbles", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "chatBubbles",
        text = "CHAT_BUBBLES_TEXT",
    })

    category:AddOption("NameplateChatBubbles", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "chatBubblesNameplate",
        text = "CHAT_BUBBLES_NAMEPLATE",
    })

    category:AddOption("PartyChat", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "chatBubblesParty",
        text = "PARTY_CHAT_BUBBLES_TEXT",
    })

    category:AddOption("SpamFilter", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "spamFilter",
        text = "DISABLE_SPAM_FILTER",
        inverted = true,
    })

    category:AddOption("ChatHoverDelay", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "removeChatDelay",
        uvar = "REMOVE_CHAT_DELAY",
        text = "REMOVE_CHAT_DELAY_TEXT",
        setFunc = function(value) SetChatMouseOverDelay(value) end,
    })

    category:AddOption("GuildMemberAlert", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "guildMemberNotify",
        text = "GUILDMEMBER_ALERT",
    })

    category:AddOption("GuildRecruitment", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "guildRecruitmentChannel",
        text = "AUTO_JOIN_GUILD_CHANNEL",
    })

    category:AddOption("ChatMouseScroll", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "chatMouseScroll",
        text = "CHAT_MOUSE_WHEEL_SCROLL",
        setFunc = function(value) InterfaceOptionsSocialPanelChatMouseScroll_SetScrolling(value) end
    })

    category:AddOption("ChatStyle", "dropdown", Options.Column.Center, Options.Width.Single, {
        cvar = "chatStyle",
        init = InterfaceOptionsSocialPanelChatStyle_OnLoad,
        onShow = InterfaceOptionsSocialPanelChatStyle_OnShow,
        text = "CHAT_STYLE",
    })

    category:AddSpace(-8, Options.Column.Center)
    
    category:AddOption("WholeChatWindowClickable", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "wholeChatWindowClickable",
        text = "CHAT_WHOLE_WINDOW_CLICKABLE",
        indentLevel = Options.Indent.Single,
    })

    category:AddSpace(22, Options.Column.Center)

    if BNFeaturesEnabled() then
        category:AddOption("ConversationMode", "dropdown", Options.Column.Center, Options.Width.Single, {
            label = "conversationMode",
            init = InterfaceOptionsSocialPanelConversationMode_OnLoad,
            onShow = InterfaceOptionsSocialPanelConversationMode_OnShow,
            text = "CONVERSATION_MODE",
        })
    end

    category:AddOption("Timestamps", "dropdown", Options.Column.Center, Options.Width.Single, {
        label = "showTimestamps",
        init = InterfaceOptionsSocialPanelTimestamps_OnLoad,
        onShow = InterfaceOptionsSocialPanelTimestamps_OnShow,
        text = "TIMESTAMPS_LABEL",
    })

    InterfaceSettings_AddCategory(category)
end

do
    local category = Options.CreateCategory("InterfaceOptionsActionBarsPanel", InterfaceOptionsFramePanelContainer, ACTIONBARS_LABEL, ACTIONBARS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("BottomLeft", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "bottomLeftActionBar",
        uvar = "SHOW_MULTI_ACTIONBAR_1",
        setFunc = function() InterfaceOptions_UpdateMultiActionBars() end,
        GetValue = function (self) return self.value or ((select(1, GetActionBarToggles()) and "1") or "0") end,
        text = "SHOW_MULTIBAR1_TEXT",
    })

    category:AddOption("BottomRight", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "bottomRightActionBar",
        uvar = "SHOW_MULTI_ACTIONBAR_2",
        setFunc = function() InterfaceOptions_UpdateMultiActionBars() end,
        GetValue = function (self) return self.value or ((select(2, GetActionBarToggles()) and "1") or "0") end,
        text = "SHOW_MULTIBAR2_TEXT",
    })

    local rightBar1 = category:AddOption("Right", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "rightActionBar",
        uvar = "SHOW_MULTI_ACTIONBAR_3",
        setFunc = function() InterfaceOptions_UpdateMultiActionBars() end,
        GetValue = function (self) return self.value or ((select(3, GetActionBarToggles()) and "1") or "0") end,
        text = "SHOW_MULTIBAR3_TEXT",
    })

    category:AddOption("RightTwo", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "rightTwoActionBar",
        uvar = "SHOW_MULTI_ACTIONBAR_4",
        setFunc = function() InterfaceOptions_UpdateMultiActionBars() end,
        GetValue = function (self) return self.value or ((select(4, GetActionBarToggles()) and "1") or "0") end,
        text = "SHOW_MULTIBAR4_TEXT",
        dependentControl = rightBar1,
    })

    category:AddOption("LockActionBars", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "lockActionBars",
        uvar = "LOCK_ACTIONBAR",
        setFunc = function() InterfaceOptions_UpdateMultiActionBars() end,
        text = "LOCK_ACTIONBAR_TEXT",
    })

    category:AddOption("AlwaysShowActionBars", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "alwaysShowActionBars",
        uvar = "ALWAYS_SHOW_MULTIBARS",
        setFunc = function (value) MultiActionBar_UpdateGridVisibility() InterfaceOptions_UpdateMultiActionBars() end,
        text = "ALWAYS_SHOW_MULTIBARS_TEXT",
    })

    category:AddOption("SecureAbilityToggle", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "secureAbilityToggle",
        text = "SECURE_ABILITY_TOGGLE",
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Names Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsNamesPanel", InterfaceOptionsFramePanelContainer, NAMES_LABEL, NAMES_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("MyName", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "UnitNameOwn",
        text = "UNIT_NAME_OWN",
    })

    category:AddOption("NPCNames", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "UnitNameNPC",
        text = "UNIT_NAME_NPC",
    })

    category:AddOption("NPCNamesDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
        text = "UNIT_NAME_NPC",
        init = InterfaceOptionsNPCNamesDropDown_OnLoad,
        onShow = InterfaceOptionsNPCNamesDropDown_OnShow,
    })

    category:AddOption("NonCombatCreature", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "UnitNameNonCombatCreatureName",
        text = "UNIT_NAME_NONCOMBAT_CREATURE",
    })

    category:AddOption("Guilds", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "UnitNamePlayerGuild",
        text = "UNIT_NAME_GUILD",
    })

    category:AddOption("Titles", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "UnitNamePlayerPVPTitle",
        text = "UNIT_NAME_PLAYER_TITLE",
    })

    category:AddOption("FriendlyPlayerNames", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "UnitNameFriendlyPlayerName",
        text = "UNIT_NAME_FRIENDLY",
    })

    category:AddOption("FriendlyPets", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "UnitNameFriendlyPetName",
        text = "UNIT_NAME_FRIENDLY_PETS",
        indentLevel = Options.Indent.Single,
    })

    category:AddOption("FriendlyGuardians", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "UnitNameFriendlyGuardianName",
        text = "UNIT_NAME_FRIENDLY_GUARDIANS",
        indentLevel = Options.Indent.Single,
    })

    category:AddOption("FriendlyTotems", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "UnitNameFriendlyTotemName",
        text = "UNIT_NAME_FRIENDLY_TOTEMS",
        indentLevel = Options.Indent.Single,
    })

    category:AddOption("EnemyPlayerNames", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "UnitNameEnemyPlayerName",
        text = "UNIT_NAME_ENEMY",
    })

    category:AddOption("EnemyPets", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "UnitNameEnemyPetName",
        text = "UNIT_NAME_ENEMY_PETS",
        indentLevel = Options.Indent.Single,
    })  

    category:AddOption("EnemyGuardians", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "UnitNameEnemyGuardianName",
        text = "UNIT_NAME_ENEMY_GUARDIANS",
        indentLevel = Options.Indent.Single,
    })

    category:AddOption("EnemyTotems", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "UnitNameEnemyTotemName",
        text = "UNIT_NAME_ENEMY_TOTEMS",
        indentLevel = Options.Indent.Single,
    })

    InterfaceSettings_AddCategory(category)
end

do
    local category = Options.CreateCategory("InterfaceOptionsNamePlatesPanel", InterfaceOptionsFramePanelContainer, NAMEPLATE_LABEL, NAMEPLATE_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("UseNewNameplates", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "useNewNameplates",
        text = "USE_CLASSIC_NAMEPLATES",
        reload = true,
    })

    if C_CVar.GetBool("useNewNameplates") then
        category:AddButton("ConfigureNamPlates", CONFIGURE_NAMEPLATES, Options.Column.Right, Options.Width.Single, function()
            InterfaceOptionsFrame_OpenToCategory("Ascension NamePlates")
        end)
    end

    category:AddOption("NameplatePersonal", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "nameplateShowPersonal",
        text = "UNIT_NAMEPLATES_SHOW_PERSONAL",
    })

    category:AddOption("CombatOnly", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateInCombatOnly",
        text = "NAMEPLATE_IN_COMBAT_ONLY",
        inverted = true,
    })

    local smoothStacking = category:AddOption("UseSmoothStacking", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateSmoothStacking",
        text = "UNIT_NAMEPLATES_SMOOTH_STACKING",
        reload = true,
        setFunc = function() C_NamePlateManager.CheckNamePlateMotion() end,
    })

    category:AddOption("UseFriendlySmoothStacking", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateFriendlySmoothStacking",
        text = "UNIT_NAMEPLATES_FRIENDLY_SMOOTH_STACKING",
        indentLevel = Options.Indent.Single,
        dependentControl = smoothStacking,
    })

    category:AddOption("OverlapV", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateOverlapV",
        text = "UNIT_NAMEPLATES_OVERLAP_V",
        minValue = 0.5,
        maxValue = 2,
        valueStep = 0.1,
        indentLevel = Options.Indent.Double,
        dependentControl = smoothStacking,
    })

    category:AlignColumns()
    category:StartGroup(SHOW_NAMEPLATES_FOR, Options.Column.Center)
    category:AlignColumns()
    
    local friends = category:AddOption("Friends", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "nameplateShowFriends",
        text = "UNIT_NAMEPLATES_SHOW_FRIENDS",
    })

    category:AddOption("FriendlyPets", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "nameplateShowFriendlyPets",
        text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_PETS",
        indentLevel = Options.Indent.Single,
        dependentControl = friends,
    })

    category:AddOption("FriendlyGuardians", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "nameplateShowFriendlyGuardians",
        text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_GUARDIANS",
        indentLevel = Options.Indent.Single,
        dependentControl = friends,
    })

    category:AddOption("FriendlyTotems", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "nameplateShowFriendlyTotems",
        text = "UNIT_NAMEPLATES_SHOW_FRIENDLY_TOTEMS",
        indentLevel = Options.Indent.Single,
        dependentControl = friends,
    })

    local enemies = category:AddOption("Enemies", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "nameplateShowEnemies",
        text = "UNIT_NAMEPLATES_SHOW_ENEMIES",
    })

    category:AddOption("EnemyPets", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "nameplateShowEnemyPets",
        text = "UNIT_NAMEPLATES_SHOW_ENEMY_PETS",
        indentLevel = Options.Indent.Single,
        dependentControl = enemies,
    })

    category:AddOption("EnemyGuardians", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "nameplateShowEnemyGuardians",
        text = "UNIT_NAMEPLATES_SHOW_ENEMY_GUARDIANS",
        indentLevel = Options.Indent.Single,
        dependentControl = enemies,
    })

    category:AddOption("EnemyTotems", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "nameplateShowEnemyTotems",
        text = "UNIT_NAMEPLATES_SHOW_ENEMY_TOTEMS",
        indentLevel = Options.Indent.Single,
        dependentControl = enemies,
    })

    category:CloseGroup(Options.Column.Right)

    category:AddOption("NameplateHighPrecision", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "highPrecisionNameplates",
        text = "UNIT_NAMEPLATES_HIGH_PRECISION",
        reload = true,
    })

    if not C_CVar.GetBool("useNewNameplates") then -- dont show to ascension nameplates. unused.
        category:AddOption("NameplateClassColors", "checkbox", Options.Column.Left, Options.Width.Single, {
            cvar = "showClassColorInNameplate",
            text = "SHOW_CLASS_COLOR_IN_V_KEY",
        })
    end

    category:AddOption("IntersectOpacity", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateIntersectOpacity",
        text = "NAMEPLATE_INTERSECT_OPACITY",
        minValue = 0,
        maxValue = 1,
        valueStep = 0.05,
        displayAsPercent = true,
    })

    category:AddOption("IntersectUseCamera", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateIntersectUseCamera",
        text = "NAMEPLATE_INTERSECT_USE_CAMERA",
    })

    category:AddOption("NameplateDistance", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateDistance",
        text = "NAMEPLATE_DISTANCE",
        minValue = 5,
        maxValue = 60,
        valueStep = 1,
    })

    local fixedZ = category:AddOption("FixedVerticalOffset", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateFixedVerticalOffset",
        text = "NAMEPLATE_FIXED_VERTICAL_OFFSET",
    })

    category:AddOption("NameplateZ", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "nameplateVerticalOffset",
        text = "NAMEPLATE_Z",
        indentLevel = Options.Indent.Double,
        minValue = 0.2,
        maxValue = 5,
        valueStep = 0.01,
        inverseDependentControl = fixedZ,
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Combat Text Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsCombatTextPanel", InterfaceOptionsFramePanelContainer, COMBATTEXT_LABEL, COMBATTEXT_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    local targetDamage = category:AddOption("TargetDamage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "CombatDamage",
        text = "SHOW_DAMAGE_TEXT",
    })

    category:AddOption("PeriodicDamage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "CombatLogPeriodicSpells",
        text = "LOG_PERIODIC_EFFECTS",
        indentLevel = Options.Indent.Single,
        dependentControl = targetDamage,
    })

    category:AddOption("PetDamage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "PetMeleeDamage",
        text = "SHOW_PET_MELEE_DAMAGE",
        setFunc = function (value) SetCVar("PetSpellDamage", value) end,
        indentLevel = Options.Indent.Single,
        dependentControl = targetDamage,
    })

    category:AddOption("Healing", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "CombatHealing",
        text = "SHOW_COMBAT_HEALING",
    })

    local targetEffects = category:AddOption("TargetEffects", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctSpellMechanics",
        text = "SHOW_TARGET_EFFECTS",
    })

    category:AddOption("OtherTargetEffects", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctSpellMechanicsOther",
        text = "SHOW_OTHER_TARGET_EFFECTS",
        indentLevel = Options.Indent.Single,
        dependentControl = targetEffects,
    })

    local enableFCT = category:AddOption("EnableFCT", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "enableCombatText",
        uvar = "SHOW_COMBAT_TEXT",
        text = "SHOW_COMBAT_TEXT_TEXT",
        setFunc = function (value)
            if ( value == "1" and not IsAddOnLoaded("Blizzard_CombatText") ) then
                UIParentLoadAddOn("Blizzard_CombatText")
            end
            BlizzardOptionsPanel_UpdateCombatText()
        end,
    })

    category:AlignColumns()

    category:AddOption("IncomingDamage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctIncomingDamage",
        uvar = "COMBAT_TEXT_SHOW_INCOMING_DAMAGE",
        text = "COMBAT_TEXT_SHOW_INCOMING_DAMAGE_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    --[[category:AddOption("OutgoingDamage", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctOutgoingDamage",
        uvar = "COMBAT_TEXT_SHOW_OUTGOING_DAMAGE",
        text = "COMBAT_TEXT_SHOW_OUTGOING_DAMAGE_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })]]

    category:AddOption("DodgeParryMiss", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctDodgeParryMiss",
        uvar = "COMBAT_TEXT_SHOW_DODGE_PARRY_MISS",
        text = "COMBAT_TEXT_SHOW_DODGE_PARRY_MISS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    category:AddOption("DamageReduction", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctDamageReduction",
        uvar = "COMBAT_TEXT_SHOW_RESISTANCES",
        text = "COMBAT_TEXT_SHOW_RESISTANCES_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })
    
    category:AddOption("RepChanges", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctRepChanges",
        uvar = "COMBAT_TEXT_SHOW_REPUTATION",
        text = "COMBAT_TEXT_SHOW_REPUTATION_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    category:AddOption("ReactiveAbilities", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctReactives",
        uvar = "COMBAT_TEXT_SHOW_REACTIVES",
        text = "COMBAT_TEXT_SHOW_REACTIVES_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    category:AddOption("FriendlyHealerNames", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctFriendlyHealers",
        uvar = "COMBAT_TEXT_SHOW_FRIENDLY_NAMES",
        text = "COMBAT_TEXT_SHOW_FRIENDLY_NAMES_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    category:AddOption("CombatState", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctCombatState",
        uvar = "COMBAT_TEXT_SHOW_COMBAT_STATE",
        text = "COMBAT_TEXT_SHOW_COMBAT_STATE_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })
    
    category:AddOption("ComboPoints", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fctComboPoints",
        uvar = "COMBAT_TEXT_SHOW_COMBO_POINTS",
        text = "COMBAT_TEXT_SHOW_COMBO_POINTS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        indentLevel = Options.Indent.Single,
        dependentControl = enableFCT,
    })

    category:AddOption("LowManaHealth", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctLowManaHealth",
        uvar = "COMBAT_TEXT_SHOW_LOW_HEALTH_MANA",
        text = "COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        dependentControl = enableFCT,
    })
    
    category:AddOption("EnergyGains", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctEnergyGains",
        uvar = "COMBAT_TEXT_SHOW_ENERGIZE",
        text = "COMBAT_TEXT_SHOW_ENERGIZE_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        dependentControl = enableFCT,
    })

    category:AddOption("PeriodicEnergyGains", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctPeriodicEnergyGains",
        uvar = "COMBAT_TEXT_SHOW_PERIODIC_ENERGIZE",
        text = "COMBAT_TEXT_SHOW_PERIODIC_ENERGIZE_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        dependentControl = enableFCT,
    })

    category:AddOption("HonorGains", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctHonorGains",
        uvar = "COMBAT_TEXT_SHOW_HONOR_GAINED",
        text = "COMBAT_TEXT_SHOW_HONOR_GAINED_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        dependentControl = enableFCT,
    })
    
    category:AddOption("Auras", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "fctAuras",
        uvar = "COMBAT_TEXT_SHOW_AURAS",
        text = "COMBAT_TEXT_SHOW_AURAS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        dependentControl = enableFCT,
    })

    category:AddOption("FCTDropDown", "dropdown", Options.Column.Center, Options.Width.Single, {
        cvar = "combatTextFloatMode",
        uvar = "COMBAT_TEXT_MODE",
        text = "MODE",
        setFunc = function() BlizzardOptionsPanel_UpdateCombatText() end,
        init = InterfaceOptionsCombatTextPanelFCTDropDown_OnLoad,
        onShow = InterfaceOptionsCombatTextPanelFCTDropDown_OnShow,
        dependentControl = enableFCT,
    })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Status Text
--
do
    local category = Options.CreateCategory("InterfaceOptionsStatusTextPanel", InterfaceOptionsFramePanelContainer, STATUSTEXT_LABEL, STATUSTEXT_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("Player", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "playerStatusText",
        text = "STATUS_TEXT_PLAYER",
    })

    category:AddOption("Pet", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "petStatusText",
        text = "STATUS_TEXT_PET",
    })

    category:AddOption("Party", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "partyStatusText",
        text = "STATUS_TEXT_PARTY",
    })

    category:AddOption("Target", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "targetStatusText",
        text = "STATUS_TEXT_TARGET",
    })

    category:AddOption("Percentages", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "statusTextPercentage",
        text = "STATUS_TEXT_PERCENT",
    })

    category:AddOption("XP", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "xpBarText",
        text = "XP_BAR_TEXT",
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Unit Frames
--
do
    local category = Options.CreateCategory("InterfaceOptionsUnitFramePanel", InterfaceOptionsFramePanelContainer, UNITFRAME_LABEL, UNITFRAME_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("PartyBackground", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showPartyBackground",
        text = "SHOW_PARTY_BACKGROUND_TEXT",
        uvar = "SHOW_PARTY_BACKGROUND",
        setFunc = function (value)
            UpdatePartyMemberBackground()
            if UpdateArenaEnemyBackground then
                UpdateArenaEnemyBackground()
            end
        end,
    })
    
    category:AddOption("HidePartyInRaid", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "hidePartyInRaid",
        uvar = "HIDE_PARTY_INTERFACE",
        text = "HIDE_PARTY_INTERFACE_TEXT",
        setFunc = function() RaidOptionsFrame_UpdatePartyFrames() end,
    })

    category:AddOption("PartyPets", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showPartyPets",
        text = "SHOW_PARTY_PETS_TEXT",
        uvar = "SHOW_PARTY_PETS",
        setFunc = function (value)
            for i=1, MAX_PARTY_MEMBERS do
                PartyMemberFrame_UpdatePet("PartyMemberFrame" .. i, i)
            end
        end,
    })

    category:AddOption("RaidRange", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showRaidRange",
        text = "SHOW_RAID_RANGE_TEXT",
        uvar = "SHOW_RAID_RANGE",
        setFunc = function (value)
            RaidFrame.showRange = value == "1" and 1 or nil
        end,
    })

    local arenaEnemies = category:AddOption("ArenaEnemyFrames", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showArenaEnemyFrames",
        text = "SHOW_ARENA_ENEMY_FRAMES_TEXT",
        uvar = "SHOW_ARENA_ENEMY_FRAMES",
    })

    category:AddOption("ArenaEnemyCastBar", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showArenaEnemyCastbar",
        text = "SHOW_ARENA_ENEMY_CASTBAR_TEXT",
        uvar = "SHOW_ARENA_ENEMY_CASTINGBAR",
        setFunc = function (value)
            if ArenaEnemyFrames then
                local frame;
                for i=1, MAX_ARENA_ENEMIES do
                    frame = _G["ArenaEnemyFrame" .. i .. "CastingBar"]
                    frame.showCastbar = value == "1"
                    CastingBarFrame_UpdateIsShown(frame)
                end
            end
        end,
        indentLevel = Options.Indent.Single,
        dependentControl = arenaEnemies,
    })

    category:AddOption("ArenaEnemyPets", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showArenaEnemyPets",
        text = "SHOW_ARENA_ENEMY_PETS_TEXT",
        uvar = "SHOW_ARENA_ENEMY_PETS",
        setFunc = function (value)
            if ArenaEnemyFrames then
                for i=1, MAX_ARENA_ENEMIES do
                    ArenaEnemyFrame_UpdatePet(_G["ArenaEnemyFrame" .. i .. "CastingBar"], i)
                end
            end
        end,
        indentLevel = Options.Indent.Single,
        dependentControl = arenaEnemies,
    })

    category:AddOption("FullSizeFocusFrame", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "fullSizeFocusFrame",
        text = "FULL_SIZE_FOCUS_FRAME_TEXT",
        uvar = "FULL_SIZE_FOCUS_FRAME",
        setFunc = function (value)
            FocusFrame_SetSmallSize(value ~= "1", true)
        end,
    })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Buffs and Debuffs
--
do
    local category = Options.CreateCategory("InterfaceOptionsBuffsPanel", InterfaceOptionsFramePanelContainer, BUFFOPTIONS_LABEL, BUFFOPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("BuffDurations", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "buffDurations",
        uvar = "SHOW_BUFF_DURATIONS",
        text = "SHOW_BUFF_DURATION_TEXT",
        setFunc = function() BuffFrame_UpdatePositions() end,
    })

    category:AddOption("DispellableDebuffs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showDispelDebuffs",
        text = "SHOW_DISPELLABLE_DEBUFFS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateRaidPullouts() end,
    })

    category:AddOption("CastableBuffs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showCastableBuffs",
        text = "SHOW_CASTABLE_BUFFS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateRaidPullouts() end,
    })

    category:AddOption("ConsolidateBuffs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "consolidateBuffs",
        uvar = "CONSOLIDATE_BUFFS",
        text = "CONSOLIDATE_BUFFS_TEXT",
        setFunc = function() BuffFrame_Update() end,
    })

    category:AddOption("ConsolidateVanityBuffs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "consolidateVanityBuffs",
        text = "CONSOLIDATE_VANITY_BUFFS",
        setFunc = function() BuffFrame_Update() end,
    })

    category:AddOption("ShowCastableDebuffs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showCastableDebuffs",
        text = "SHOW_CASTABLE_DEBUFFS_TEXT",
        setFunc = function() BlizzardOptionsPanel_UpdateRaidPullouts() end,
    })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Camera
--
do
    local category = Options.CreateCategory("InterfaceOptionsCameraPanel", InterfaceOptionsFramePanelContainer, CAMERA_LABEL, CAMERA_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("MaxDistanceSlider", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraDistanceMaxFactor",
        text = "MAX_FOLLOW_DIST",
        minValue = 1,
        maxValue = 4,
        valueStep = 0.1,
    })

    category:AddOption("ZoomSpeed", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraDistanceMoveSpeed",
        text = "CAMERA_ZOOM_SPEED",
        minValue = 1,
        maxValue = 40,
        valueStep = 0.1,
        displayPrecision = 1,
    })

    category:AddOption("FoV", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "camerafov",
        text = "CAMERA_FOV",
        minValue = GetCVarMin("camerafov"),
        maxValue = GetCVarMax("camerafov"),
        minText = "20%",
        maxText = "130%",
        setFunc = function (value)
            SetCameraFoV(value)
        end,
        valueTextFunc = function(self, value)
            return MTrunc(math.ceil((value - 0.8) * 100), self.displayPrecision).."%"
        end,
        valueStep = 0.01,
    })

    category:AddOption("StyleDropDown", "dropdown", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraSmoothStyle",
        text = "CAMERA_FOLLOWING_STYLE",
        init = InterfaceOptionsCameraPanelStyleDropDown_OnLoad,
        onShow = InterfaceOptionsCameraPanelStyleDropDown_OnShow,
    })

    category:AddOption("FollowTerrain", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraTerrainTilt",
        text = "FOLLOW_TERRAIN",
    })
    
    category:AddOption("FollowSpeedSlider", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraYawSmoothSpeed",
        text = "AUTO_FOLLOW_SPEED",
        minValue = 90,
        maxValue = 270,
        valueStep = 10,
    })

    category:AddOption("HeadBob", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraBobbing",
        text = "HEAD_BOB",
    })

    category:AddOption("WaterCollision", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraWaterCollision",
        text = "WATER_COLLISION",
    })

    category:AddOption("SmartPivot", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraPivot",
        text = "SMART_PIVOT",
    })

    local m2Collision = category:AddOption("M2Collision", "checkbox", Options.Column.Right, Options.Width.Single, {
        cvar = "cameraM2Collision",
        text = "M2_COLLISION",
    })

    category:AddOption("M2CollisionAlpha", "slider", Options.Column.Right, Options.Width.Single, {
        cvar = "cameraM2CollisionAlpha",
        text = "M2_COLLISION_ALPHA",
        minValue = 0,
        maxValue = 1,
        valueStep = 0.05,
        displayAsPercent = true,
        inverseDependentControl = m2Collision,
        indentLevel = Options.Indent.Double,
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Action Camera
--
do
    local category = Options.CreateCategory("InterfaceOptionsActionCamera", InterfaceOptionsFramePanelContainer, ACTION_CAM_OPTIONS_LABEL, ACTION_CAM_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)
    
    local enabled = category:AddOption("EnableActionCam", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "ActionCam",
        text = "ENABLE_ACTION_CAM",
    })

    category:AddOption("HeadBob", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraActionHeadBobs",
        text = "ACTION_CAM_HEAD_BOB",
        dependentControl = enabled,
    })

    category:AlignColumns()

    -- focus interact
    category:AddOption("FocusInteract", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraTargetFocusInteractEnable",
        text = "ACTION_CAM_FOCUS_INTERACT",
        dependentControl = enabled,
    })

    -- focus target
    category:AddOption("FocusTarget", "checkbox", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraTargetFocusEnemyEnable",
        text = "ACTION_CAM_FOCUS_TARGET",
        dependentControl = enabled,
    })

    category:AddOption("Angle", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraActionAngle",
        text = "ACTION_CAM_TURN_SPEED",
        minValue = 0,
        maxValue = 6,
        valueStep = 0.0025,
        dependentControl = enabled,
    })

    category:AddOption("Distance", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraActionDist",
        text = "ACTION_CAM_DISTANCE",
        minValue = 0.25,
        maxValue = 2,
        valueStep = 0.0025,
        dependentControl = enabled,
    })
    
    category:AddOption("Height", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraActionZ",
        text = "ACTION_CAM_HEIGHT",
        minValue = -1.25,
        maxValue = 0.75,
        valueStep = 0.0025,
        dependentControl = enabled,
    })
    
    category:AddOption("TurnSpeed", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "cameraTargetFocusTurnSpeed",
        text = "ACTION_CAM_TURN_SPEED",
        minValue = 0.5,
        maxValue = 16.5,
        valueStep = 0.0025,
        dependentControl = enabled,
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Mouse Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsMousePanel", InterfaceOptionsFramePanelContainer, MOUSE_LABEL, MOUSE_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("InvertMouse", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "mouseInvertPitch",
        text = "INVERT_MOUSE",
    })

    category:AddOption("MouseSensitivitySlider", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "mouseSpeed",
        text = "MOUSE_SENSITIVITY",
        minValue = 0.5,
        maxValue = 1.5,
        valueStep = 0.05,
    })  
    
    category:AddOption("MouseLookSpeedSlider", "slider", Options.Column.Left, Options.Width.Single, {
        cvar = "cameraYawMoveSpeed",
        text = "MOUSE_LOOK_SPEED",
        minValue = 90,
        maxValue = 270,
        valueStep = 10,
    })

    category:AddOption("WoWMouse", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "enableWoWMouse",
        text = "WOW_MOUSE",
    })

    -- category:AddOption("ClickMoveStyleDropDown", "dropdown", Options.Column.Right, Options.Width.Single, {
    --     cvar = "cameraSmoothTrackingStyle",
    --     text = "CLICK_CAMERA_STYLE",
    --     init = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnLoad,
    --     onShow = InterfaceOptionsMousePanelClickMoveStyleDropDown_OnShow,
    -- })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Help Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsHelpPanel", InterfaceOptionsFramePanelContainer, HELP_LABEL, HELP_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("LoadingScreenTips", "checkbox", Options.Column.Left, Options.Width.Single, { 
        cvar = "showGameTips",
        text = "SHOW_TIPOFTHEDAY_TEXT",
    })

    category:AddOption("BeginnerTooltips", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showNewbieTips",
        uvar = "SHOW_NEWBIE_TIPS",
        text = "SHOW_NEWBIE_TIPS_TEXT",
    })

    category:AddOption("ShowLuaErrors", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "popupScriptErrors",
        text = "SHOW_LUA_ERRORS",
    })

    category:AddOption("ExtendedTooltips", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "extendedTooltips",
        text = "SHOW_EXTENDED_TOOLTIPS",
    })

    category:AddOption("ShowTooltipIDs", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showTooltipID",
        text = "SHOW_TOOLTIP_IDS",
    })

    category:AddOption("ShowLayerPicker", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showLayerPicker",
        text = "SHOW_LAYER_PICKER",
    })

    InterfaceSettings_AddCategory(category)
end

--
-- Language Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsLanguagesPanel", InterfaceOptionsFramePanelContainer, LANGUAGES_LABEL, LANGUAGES_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)
    -- we still have to make the category frame 
    if #({GetExistingLocales()}) > 1 then
            category:AddOption("LocaleDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
            cvar = "locale",
            text = "LANGUAGE_LABEL",
            init = InterfaceOptionsLanguagesPanelLocaleDropDown_OnLoad,
            onShow = InterfaceOptionsLanguagesPanelLocaleDropDown_OnShow,
        })

        category:AddOption("UseEnglishAudio", "checkbox", Options.Column.Left, Options.Width.Single, {
            cvar = "useEnglishAudio",
            text = "USE_ENGLISH_AUDIO",
        })

        InterfaceSettings_AddCategory(category)
    end
end

--
-- Ascension Notification Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsAscensionNotificationPanel", InterfaceOptionsFramePanelContainer, ASCENSION_NOTIFICATION_OPTIONS_LABEL, ASCENSION_NOTIFICATION_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    local showLootToasts = category:AddOption("LootToast", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showLootToasts",
        text = "SHOW_LOOT_TOAST",
    })

    category:AddOption("LootToastMaximum", "slider", Options.Column.Center, Options.Width.Single, {
        cvar = "lootToastMaximum",
        text = "LOOT_TOAST_MAX",
        minValue = 1,
        maxValue = 6,
        valueStep = 1,
        dependentControl = showLootToasts,
    })  

    category:AlignColumns()

    category:AddOption("EnableItems", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showEpicLootToasts",
        bitCVar = "disabledToastBitfield",
        bit = Enum.LootToastBit.EpicItem,
        text = "SHOW_TOAST_EPIC_ITEM",
        inverted = true,
        dependentControl = showLootToasts,
    })

    category:AddOption("EnableLegendaryItems", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showLegendaryLootToasts",
        bitCVar = "disabledToastBitfield",
        bit = Enum.LootToastBit.LegendaryItem,
        text = "SHOW_TOAST_LEGENDARY_ITEM",
        inverted = true,
        dependentControl = showLootToasts,
    })

    category:AddOption("EnableNewSpellRanks", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showNewSpellRankToasts",
        bitCVar = "disabledToastBitfield",
        bit = Enum.LootToastBit.NewSpellRank,
        text = "SHOW_TOAST_NEW_SPELL_RANK",
        inverted = true,
        dependentControl = showLootToasts,
    })

    category:AddOption("EnableNewSpells", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showNewSpellsToasts",
        bitCVar = "disabledToastBitfield",
        bit = Enum.LootToastBit.SpellLearned,
        text = "SHOW_TOAST_NEW_SPELL",
        inverted = true,
        dependentControl = showLootToasts,
    })

    category:AddSpace(24, Options.Column.Left)
    category:AlignColumns()

    category:AddOption("FlashWindow", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "flashWindow",
        text = "FLASH_WINDOW",
    })
    
    InterfaceSettings_AddCategory(category)
end

--
-- Lose Control Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsLoseControlPanel", InterfaceOptionsFramePanelContainer, ASCENSION_LOSE_CONTROL_OPTIONS_LABEL, ASCENSION_LOSE_CONTROL_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("Enabled", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "showLossOfControl",
        text = "SHOW_LOSE_CONTROL",
    })

    category:AlignColumns()

    category:AddButton("MoveWindow", MOVE_WINDOW, Options.Column.Left, Options.Width.Single, function()
        PlaySound("gsTitleOptionOK")
        InterfaceOptionsFrame_Show()
        HideUIPanel(EscapeMenu)
        LoseControlFrame:Unlock()
    end, MOVE_LOSE_CONTROL_TOOLTIP_LABEL, MOVE_LOSE_CONTROL_TOOLTIP1 .. "|n" ..MOVE_LOSE_CONTROL_TOOLTIP2)

    category:AddButton("ResetWindow", RESET_POSITION_AND_SIZE, Options.Column.Center, Options.Width.Single, function()
        PlaySound("gsTitleOptionOK")
        LoseControlFrame:ResetPositionAndSize()
    end)

    category:AddSpace(24, Options.Column.Left)
    category:AlignColumns()

    category:AddOption("EnableRoots", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showLoseControlRoots",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_ROOTS,
        text = "SHOW_LOSE_CONTROL_ROOTS",
    })

    category:AddOption("EnableIncap", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showLoseControlIncap",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_INCAPACITATE,
        text = "SHOW_LOSE_CONTROL_INCAPACITATE",
    })

    category:AddOption("EnableDisorient", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showLoseControlDisorient",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_DISORIENT,
        text = "SHOW_LOSE_CONTROL_DISORIENT",
    })

    category:AddOption("EnableStun", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showLoseControlStun",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_STUN,
        text = "SHOW_LOSE_CONTROL_STUN",
    })

    category:AddOption("EnableSilence", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showLoseControlSilence",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_SILENCE,
        text = "SHOW_LOSE_CONTROL_SILENCE",
    })

    category:AddOption("EnableDisarm", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showLoseControlDisarm",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_DISARM,
        text = "SHOW_LOSE_CONTROL_DISARM",
    })

    category:AddOption("EnableSlow", "checkbox", Options.Column.Left, Options.Width.Single, {
        label = "showLoseControlSlow",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_SLOW,
        text = "SHOW_LOSE_CONTROL_SLOW",
    })

    category:AddOption("EnablePacify", "checkbox", Options.Column.Center, Options.Width.Single, {
        label = "showLoseControlPacify",
        bitCVar = "lossOfControlMask",
        bit = CROWD_CONTROL_TYPE_PACIFY,
        text = "SHOW_LOSE_CONTROL_PACIFY",
    }) 

    InterfaceSettings_AddCategory(category)
end

--
-- Ascension Help Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsAscensionHelpPanel", InterfaceOptionsFramePanelContainer, ASCENSION_HELP_OPTIONS_LABEL, ASCENSION_HELP_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("NewPlayerExperience", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "npeEnabled",
        text = "SHOW_NEW_PLAYER_EXPERIENCE",
    })

    category:AddOption("HelpTips", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "HelpTipEnabled",
        text = "SHOW_HELP_TIPS",
    })

    category:AddButton("ResetHelpTips", RESET_TIPS, Options.Column.Left, Options.Width.Single, function()
        PlaySound("gsTitleOptionOK")
        StaticPopup_Show("HELPTIP_RESET_ALL")
    end)

    InterfaceSettings_AddCategory(category)
end

--
-- Draft Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsDraftPanel", InterfaceOptionsFramePanelContainer, DRAFT_OPTIONS_LABEL, DRAFT_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    category:AddOption("AutoPopupDraft", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoPopupDraft",
        text = "AUTO_POPUP_DRAFT",
        description = "OPTION_AUTO_POPUP_DRAFT_DESCRIPTION",
    })

    category:AddOption("AutoRevealDraft", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "autoRevealDraft",
        text = "AUTO_REVEAL_DRAFT",
        description = "OPTION_AUTO_REVEAL_DRAFT_DESCRIPTION",
    })

    category:AddOption("SkipDraftConfirmation", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "skipDraftConfirmation",
        text = "SKIP_DRAFT_CONFIRMATION",
        description = "OPTION_SKIP_DRAFT_CONFIRMATION_DESCRIPTION",
    })

    category:AddOption("SkipDraftSacrificeConfirmation", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "skipDraftSacrificeConfirmation",
        text = "SKIP_DRAFT_SACRIFICE_CONFIRMATION",
        description = "OPTION_SKIP_DRAFT_SACRIFICE_CONFIRMATION_DESCRIPTION",
    })

    category:AddOption("BuildDraftShowSpellCards", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "buildDraftShowSpellCards",
        text = "SHOW_BUILD_DRAFT_SPELLS",
        description = "OPTION_SHOW_BUILD_DRAFT_SPELLS_DESCRIPTION",
    })

    --InterfaceSettings_AddCategory(category) todo: maybe find a way to condition this better? InterfaceOptionsFrame_OnShow controls if this is added or not atm
end

--
-- Mouseover Cast Options
--
do
    local category = Options.CreateCategory("InterfaceOptionsMouseoverCastPanel", InterfaceOptionsFramePanelContainer, MOUSEOVER_CAST_OPTIONS_LABEL, MOUSEOVER_CAST_OPTIONS_SUBTEXT, InterfaceOptionsPanel_CheckButton_OnClick, InterfaceOptionsPanel_Slider_OnValueChanged)

    local friendly = category:AddOption("MouseoverCastFriendly", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "enableMouseoverCast",
        text = "MOUSEOVER_CAST",
    })

    category:AddOption("MouseoverCastHarm", "checkbox", Options.Column.Left, Options.Width.Single, {
        cvar = "enableMouseoverCastHarm",
        text = "MOUSEOVER_CAST_HARM",
        dependentControl = friendly,
    })

    category:AddOption("HotkeyDropDown", "dropdown", Options.Column.Left, Options.Width.Single, {
        label = "mouseoverCastHotkey",
        text = "MOUSEOVER_CAST_HOTKEY",
        init = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnLoad,
        onShow = InterfaceOptionsMouseoverCastPanelHotkeyDropDown_OnShow,
        dependentControl = friendly,
    })

    InterfaceSettings_AddCategory(category)
end

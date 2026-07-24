-- Force Equipment Manager to always be active.
C_CVar.Set("equipmentManager", "1")

-- Force scriptErrors always on
C_CVar.Set("scriptErrors", true)

-- Tooltips just disappear without this
C_CVar.Set("UberTooltips", true)

-- disabling this is just dumb
C_CVar.Set("showQuestTrackingTooltips", true)

-- Settings
C_CVar.RegisterSavedCVar("SpellActivationOverlayAlpha", "0.8", 0, 1)
C_CVar.RegisterSavedCVar("SpellActivationOverlayEnabled", "1")
C_CVar.RegisterSavedCVar("AutoHideFelCommWarning", "1")
C_CVar.RegisterSavedCVar("HighlightNewItems", "1")
C_CVar.RegisterSavedCVar("showLootToasts", "1")
C_CVar.RegisterSavedCVar("lootToastMaximum", "3")
C_CVar.RegisterSavedCVar("disabledToastBitfield", "")
C_CVar.RegisterSavedCVar("SkillCardExchangeSkip", "")
C_CVar.RegisterSavedCVar("professionsUseCompactUI", "1")
C_CVar.RegisterSavedCVar("ptaAutoQuestEnabled", "1")
C_CVar.RegisterSavedCVar("autoSellJunk", "0")
C_CVar.RegisterSavedCVar("autoRepair", "0")
C_CVar.RegisterSavedCVar("popupScriptErrors", "0")
C_CVar.RegisterSavedCVar("consolidateVanityBuffs", "1")

C_CVar.RegisterSavedCVar("camerafov", "1.95", 1, 2.1)
C_CVar.RegisterSavedCVar("tabTargetAngle", "30", 10, 360)

C_CVar.RegisterSavedCVar("showPortraitDragon", "1")

C_CVar.RegisterSavedCVar("coaResourceLocked", "1")
C_CVar.RegisterSavedCVar("coaResourceSize", "3")
C_CVar.RegisterSavedCVar("coaResourceBarLocked", "1")
C_CVar.RegisterSavedCVar("coaResourceBarSize", "3")
C_CVar.RegisterSavedCVar("coaResourceBarShowText", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST1", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST2", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST3", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST4", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST5", "0")
C_CVar.RegisterSavedCharacterCVar("COA_MULTICAST6", "0")

C_CVar.RegisterSavedCVar("showPvPCurrencyText", "0")

C_CVar.RegisterSavedCVar("showLossOfControl", "1")
C_CVar.RegisterSavedCVar("lossOfControlMask", "\191") -- Immobilizes / Silences / Incapacitates / Disorients / Disarms / Stuns / Pacify
C_CVar.RegisterSavedCVar("lossOfControlScale", "1", 0.1, 2)

C_CVar.RegisterSavedCVar("disabledPOIBitfield", "")

C_CVar.RegisterSavedCVar("showLayerPicker", "1")

C_CVar.RegisterSavedCharacterCVar("enableMouseoverCast", "0")
C_CVar.RegisterSavedCharacterCVar("enableMouseoverCastHarm", "0")

C_CVar.RegisterSavedCharacterCVar("heroArchitectAutoLearn", "1")

C_CVar.RegisterSavedCharacterCVar("caLastClass", "")
C_CVar.RegisterSavedCharacterCVar("caLastSpec", "")

C_CVar.RegisterSavedCharacterCVar("fctIncomingDamage", "0")
C_CVar.RegisterSavedCharacterCVar("fctOutgoingDamage", "0")

-- Draft
C_CVar.RegisterSavedCVar("autoPopupDraft", "1")
C_CVar.RegisterSavedCVar("autoRevealDraft", "0")
C_CVar.RegisterSavedCVar("skipDraftConfirmation", "0")
C_CVar.RegisterSavedCVar("skipDraftSacrificeConfirmation", "0")
C_CVar.RegisterSavedCVar("buildDraftShowSpellCards", "1")

-- LFG
C_CVar.RegisterSavedCharacterCVar("lfgRoles", "0")
C_CVar.RegisterSavedCharacterCVar("pvpRole", "0")

-- Help Tips
C_CVar.RegisterSavedCVar("HelpTipBitfield", "")
C_CVar.RegisterSavedCVar("HelpTipEnabled", "1")

-- Unlockables
C_CVar.RegisterSavedCVar("ShowFullBuildCreator", "0")
C_CVar.RegisterSavedCVar("allowMysticEnchantingUI", "0")

-- Tutorials
C_CVar.RegisterSavedCVar("npeEnabled", "1")
SetCVar("showTutorials", "0") -- disable default tutorials
C_CVar.RegisterSavedCVar("showInGameNavigation", "1")
C_CVar.RegisterSavedCharacterCVar("joinedDefaultChats", "0")
C_CVar.RegisterSavedCharacterCVar("coloredLocaleNewcomersChat", "0")

-- NamePlates
C_CVar.RegisterSavedCVar("useNewNameplates", "1")
C_CVar.RegisterSavedCVar("nameplateWidth", "110", 40, 200)
C_CVar.RegisterSavedCVar("nameplateHeight", "30", 18, 60)
C_CVar.RegisterSavedCVar("nameplateShowOnlyNames", "0")
C_CVar.RegisterSavedCVar("nameplateSmoothStacking", "0")
C_CVar.RegisterSavedCVar("nameplateOverlapV", "1", 0.5, 2)
C_CVar.RegisterSavedCVar("nameplateFriendlySmoothStacking", "0")
C_CVar.RegisterSavedCVar("DrawNameplateClickBox", "0")
C_CVar.RegisterSavedCVar("highPrecisionNameplates", "0")
C_CVar.RegisterSavedCVar("nameplateCeiling", "0.065")

-- Raid Frames
C_CVar.RegisterSavedCVar("useCompactPartyFrames", "0")
C_CVar.RegisterSavedCVar("raidFramesUpdateRate", "0.05")
C_CVar.RegisterSavedCharacterCVar("raidProfile", "")

-- Tooltip IDs
C_CVar.RegisterSavedCVar("showTooltipID", (C_Realm.IsPTR() or C_Realm.IsDevelopment()) and "1" or "0")

-- CharacterAdvancement
C_CVar.RegisterSavedCVar("previewCharacterAdvancementChanges", "0")

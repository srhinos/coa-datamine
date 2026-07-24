--[[ https://github.com/Gethe/wow-ui-source/blob/53eff055dcffff98029f0438f9b0da421e4dad70/Interface/SharedXML/HelpTip.lua
	HelpTips["TIP_NAME"] = {
        parent,                                 -- parent frame to attach this to
        relativeRegion,                         -- relative point to attach to and highlight
        strata,                                 -- Frame Strata of this tip
        level,                                  -- Frame Level
		text,									-- also acts as a key for various API, MUST BE SET
		textColor = HIGHLIGHT_FONT_COLOR,
		textJustifyH = "LEFT",
		buttonStyle = HelpTip.ButtonStyle.None	-- button to close the helptip, or no button at all
		targetPoint = HelpTip.Point.BottomEdgeCenter,	-- where at the parent/relativeRegion the helptip should point
		alignment = HelpTip.Alignment.Center,	-- alignment of the helptip relative to the parent/relativeRegion (basically where the arrow is located)
		hideArrow = false,						-- whether to hide the arrow
		offsetX = 0,
		offsetY	= 0,
		cvar, cvarValue, cvarBit				-- cvar to set when closed by user or from HelpTip:Acknowledge()
		onInitCallback                          -- callback whenever the helptip is initialized
		onHideCallback, callbackArg,			-- callback whenever the helptip is closed:  onHideCallback(acknowledged, callbackArg)
		onAcknowledgeCallback					-- callback whenever the helptip is closed by the user clicking its button: onAcknowledgeCallback(callbackArg)
		autoEdgeFlipping = false,				-- on: will flip helptip to opposite edge based on relative region's center vs helptip's center during OnUpdate
		autoHorizontalSlide = false,			-- on: will change the alignment to fit helptip on screen during OnUpdate
		system = ""								-- reference string
		systemPriority = 0,						-- if a system and a priority is specified, higher priority helptips will close another helptip in that system
		extraRightMarginPadding = 0,			--  extra padding on the right side of the helptip
		acknowledgeOnHide = false,				-- whether to treat a hide as an acknowledge
        highlightTarget,						-- Highlight the target see HelpTip.TargetType
		highlightOffset {left, right, top, bottom}, -- offset of highlight. nil = 10 for Box and 4 for circle.
        highlightBlockInput = false             -- Dim the screen and block input outside the designated frame
		animatePointer = false,					-- Show the pointer animation
		isFlyout,								-- If true this will bypass cvar EnableHelpTips. Needed for flyout helptips on frame tutorials.
        dontReleaseUntilAcknowledged            -- if true this help tip will be 'sticky' and wont disappear until acknowledged, even if its parent is closed.
        next,                                   -- reference to the next helptip to display on acknowledge
	}
]]--

HelpTips.Bits = { -- DO NOT REORDER THESE
	FelComm_Disabled             = 1,
	CancelHoFTip                 = 2,
	HelpPlate_SkillCards         = 3,
	HelpPlate_Vanity             = 4,
	SimpleTalentsTip1            = 5,
	SimpleTalentsTip2            = 6,
	SimpleTalentsTip3            = 7,
	SimpleTalentsTip4            = 8,
	MinimapMailHint              = 9,
	WatchFramePing               = 10,
	UseAbilities                 = 11,
	EquipStaff                   = 12,
	UnspentTalentEssence         = 13,
	NewEquipmentManagerBankItems = 14,
	HelpPlate_MysticEnchants     = 15,
	HelpPlate_PvEFrame           = 16,
	HelpPlate_PvPFrame           = 17,
	--HelpPlate_CA2                = 18,
	TradeSkillCompactMode        = 19,
	--HelpPlate_GroupFinder        = 20,
	BuildCreatorSeenFeatured     = 21,
	CASpellHotkeyHint1			 = 22,
	CASpellHotkeyHint2			 = 23,
	CASpellHotkeyHint3			 = 24,
	HeroArchitectFeatured		 = 25,
	NewTutorialTip				 = 26,
	TicketTabSelectMultiClass	 = 27,
	AppearanceAvailableOnWebStore = 28,
	AppearanceAvailableOnBazaar	 = 29,
	AppearanceViewFullItemSet	 = 30,
	UnspentAbilityEssence 		= 31,
	WardrobeHint1 				= 32,
	WardrobeHint2 				= 33,
    LayerPicker                 = 34,
}

--
-- Quest Selection
--
HelpTips["QUEST_FRAME_SELECT1"] = {
	parent                       = "QuestTitleButton1",
	text                         = TIP_QUEST_FRAME_SELECT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["QUEST_FRAME_SELECT2"] = {
	parent                       = "QuestTitleButton2",
	text                         = TIP_QUEST_FRAME_SELECT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["GOSSIP_SELECT1"] = {
	parent                       = "GossipTitleButton1",
	text                         = TIP_QUEST_FRAME_SELECT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["GOSSIP_SELECT2"] = {
	parent                       = "GossipTitleButton2",
	text                         = TIP_QUEST_FRAME_SELECT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["QUEST_FRAME_ACCEPT"] = {
	parent                       = "QuestFrameAcceptButton",
	text                         = TIP_QUEST_FRAME_ACCEPT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	alignment                    = HelpTip.Alignment.Left,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["GOSSIP_FRAME_SELECT1"] = {
	parent                       = "GossipTitleButton1",
	text                         = TIP_QUEST_FRAME_SELECT,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["QUEST_FRAME_COMPLETE"] = {
	parent                       = "QuestFrameCompleteQuestButton",
	text                         = TIP_QUEST_FRAME_COMPLETE,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottomEdgeCenter,
	alignment                    = HelpTip.Alignment.Left,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["OPEN_QUEST_LOG"] = {
	parent          = "QuestLogMicroButton",
	text            = TIP_QUEST_LOG_OPEN,
	buttonStyle     = HelpTip.ButtonStyle.Okay,
	textJustifyH    = "CENTER",
	targetPoint     = HelpTip.Point.TopEdgeCenter,
	animatePointer  = true,
	highlightTarget = HelpTip.TargetType.Box,
	system          = "micromenu",
	systemPriority  = 30,
}

HelpTips["CLICK_TRACK_QUEST"] = {
	parent                       = "QuestLogFrameTrackButton",
	text                         = TIP_QUEST_LOG_TRACK,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.BottmEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
	highlightTarget              = HelpTip.TargetType.Box,
}

HelpTips["WATCH_FRAME_PING"] = {
	parent         = "WatchFrameLinkButton1",
	text           = TIP_WATCH_FRAME_PING,
	cvar           = "HelpTipBitfield",
	cvarBit        = HelpTips.Bits.WatchFramePing,
	textJustifyH   = "CENTER",
	targetPoint    = HelpTip.Point.LeftEdgeCenter,
	buttonStyle    = HelpTip.ButtonStyle.GotIt,
	animatePointer = true,
}

--
-- World Map
--
HelpTips["QUEST_POI_GO_TO"] = {
	parent                       = "poiWorldMapPOIFrame1_1",
	text                         = TIP_QUEST_POI_GO_TO,
	textJustifyH                 = "CENTER",
	targetPoint                  = HelpTip.Point.RightEdgeCenter,
	acknowledgeOnHide            = false,
	animatePointer               = true,
	dontReleaseUntilAcknowledged = true,
}

--
-- Action Bar
--
HelpTips["USE_ABILITIES"] = {
	parent            = "MainMenuBar",
	text              = TIP_USE_ABILITIES,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeLeft,
	buttonStyle       = HelpTip.ButtonStyle.GotIt,
	offsetX           = 120,
	cvar              = "HelpTipBitfield",
	cvarBit           = HelpTips.Bits.UseAbilities,
	acknowledgeOnHide = true,
	animatePointer    = true,
	onInitCallback    = function(self)
		C_Hook:Register(self, "UNIT_SPELLCAST_SENT", function(unit)
			if unit == "player" then
				C_Hook:Unregister(self, "UNIT_SPELLCAST_SENT")
				self:Acknowledge()
			end
		end)
	end,
}

HelpTips["HARDCAST_EQUIP_STAFF"] = {
	parent            = "MainMenuBarBackpackButton",
	text              = TIP_HARDCAST_EQUIP_STAFF,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	buttonStyle       = HelpTip.ButtonStyle.GotIt,
	alignment         = HelpTip.Alignment.Right,
	cvar              = "HelpTipBitfield",
	cvarBit           = HelpTips.Bits.EquipStaff,
	acknowledgeOnHide = true,
	animatePointer    = true,
	onInitCallback    = function(self)
		C_Hook:Register(self, "PLAYER_EQUIPMENT_CHANGED", function(slot, hasEquipped)
			if slot == INVSLOT_MAINHAND and hasEquipped then
				C_Hook:Unregister(self, "PLAYER_EQUIPMENT_CHANGED")
				self:Acknowledge()
			end
		end)
	end,
}

--
-- Spellbook
--
HelpTips["SPELLBOOK_TAB"] = {
	parent          = "SpellBookSkillLineTab1",
	text            = TIP_CLICK,
	targetPoint     = HelpTip.Point.RightEdgeCenter,
	highlightTarget = HelpTip.TargetType.Box,
	animatePointer  = true,
}

HelpTips["OPEN_SPELLBOOK"] = {
	parent          = "SpellbookMicroButton",
	text            = TIP_SPELLBOOK_OPEN,
	buttonStyle     = HelpTip.ButtonStyle.Okay,
	system          = "micromenu",
	systemPriority  = 31,
	textJustifyH    = "CENTER",
	targetPoint     = HelpTip.Point.TopEdgeCenter,
	animatePointer  = true,
	highlightTarget = HelpTip.TargetType.Box,
}

--
-- Minimap
--
HelpTips["SHOW_MINIMAP_MAIL"] = {
	parent          = "MiniMapMailFrame",
	strata          = "FULLSCREEN_DIALOG",
	text            = TIP_SHOW_MINIMAP_MAIL,
	cvar            = "HelpTipBitfield",
	cvarBit         = HelpTips.Bits.MinimapMailHint,
	textJustifyH    = "CENTER",
	targetPoint     = HelpTip.Point.LeftEdgeCenter,
	alignment       = HelpTip.Alignment.Top,
	buttonStyle     = HelpTip.ButtonStyle.GotIt,
	highlightTarget = HelpTip.TargetType.Circle,
	animatePointer  = true,
}

--
-- Talent Micro Button
--
HelpTips["UNSPENT_TALENT_ESSENCE_NEW"] = {
	parent            = "TalentMicroButton",
	text              = TIP_UNSPENT_TALENT_ESSENCE,
	--buttonStyle       = HelpTip.ButtonStyle.Okay,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	acknowledgeOnHide = false,
	system			  = "micromenu",
	systemPriority    = 50,
}

HelpTips["UNSPENT_ABILITY_ESSENCE_NEW"] = {
	parent            = "TalentMicroButton",
	text              = TIP_UNSPENT_ABILITY_ESSENCE,
	--buttonStyle       = HelpTip.ButtonStyle.Okay,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	acknowledgeOnHide = false,
	system			  = "micromenu",
	systemPriority    = 51,
}

--
-- Equipment Manager
--
HelpTips["EQUIPMENT_MANAGER_BANK_ITEMS"] = {
	parent            = "GearManagerDialogSendToBankToggle",
	textJustifyH      = "CENTER",
	text              = "New!\nUnequip items directly into your bank!",
	targetPoint       = HelpTip.Point.RightEdgeCenter,
	buttonStyle       = HelpTip.ButtonStyle.Okay,
	acknowledgeOnHide = true,
	cvar              = "HelpTipBitfield",
	cvarBit           = HelpTips.Bits.NewEquipmentManagerBankItems,
}

--
-- Character Advancement
--
HelpTips["SPELL_HINT_LEARN_HOTKEYS1"] = {
	parent = "CharacterAdvancement",
	text = SPELL_HINT_LEARN_HOTKEYS1,
	system = "CharacterAdvancement",
	systemPriority = 1,
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.CASpellHotkeyHint1,
	textJustifyH = "CENTER",
	targetPoint = HelpTip.Point.TopEdgeCenter,
	buttonStyle = HelpTip.ButtonStyle.Next,
	next = "SPELL_HINT_LEARN_HOTKEYS2",
	nextUsesRelativeRegion = true,
}

HelpTips["SPELL_HINT_LEARN_HOTKEYS2"] = {
	parent = "CharacterAdvancement",
	text = SPELL_HINT_LEARN_HOTKEYS2,
	system = "CharacterAdvancement",
	systemPriority = 1,
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.CASpellHotkeyHint2,
	textJustifyH = "CENTER",
	targetPoint = HelpTip.Point.TopEdgeCenter,
	buttonStyle = HelpTip.ButtonStyle.Next,
	next = "SPELL_HINT_LEARN_HOTKEYS3",
	nextUsesRelativeRegion = true,
}

HelpTips["SPELL_HINT_LEARN_HOTKEYS3"] = {
	parent = "CharacterAdvancement",
	text = SPELL_HINT_LEARN_HOTKEYS3,
	system = "CharacterAdvancement",
	systemPriority = 1,
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.CASpellHotkeyHint3,
	textJustifyH = "CENTER",
	targetPoint = HelpTip.Point.TopEdgeCenter,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
}

HelpTips["BUILD_CREATOR_FEATURED_HINT"] = {
	parent = "BuildCreatorFrame",
	text = BUILD_CREATOR_FEATURED_HINT,
	cvar = "HelpTipBitfield",
	cvarBit = HelpTips.Bits.HeroArchitectFeatured,
	textJustifyH = "LEFT",
	targetPoint = HelpTip.Point.RightEdgeCenter,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
	highlightTarget = HelpTip.TargetType.Box,
	highlightOffset = { -2, 2, 4, 0 },
}

HelpTips["HELP_TIP_NEW_PTA_TUTORIAL"] = {
	parent            = "PathToAscensionMicroButton",
	strata			  = "TOOLTIP",
	text              = NEW_TUTORIAL_TIP,
	animatePointer	  = true,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	system			  = "micromenu",
	systemPriority    = 80,
}

do
	local icon = CreateAtlasMarkup("pta-loot-normal-focused", 0.2, -8, 8)
	HelpTips["HELP_TIP_PTA_REWARD_PENDING"] = {
		parent            = "PathToAscensionMicroButton",
		strata			  = "TOOLTIP",
		text              = icon .. " " ..TUTORIAL_REWARD_PENDING,
		textJustifyH      = "CENTER",
		targetPoint       = HelpTip.Point.TopEdgeCenter,
		system			  = "micromenu",
		systemPriority    = 70,
	}
end

HelpTips["HELP_TIP_NEW_SPELL_RANK"] = {
	parent            = "TalentMicroButton",
	strata			  = "TOOLTIP",
	text              = HELP_TIP_NEW_SPELL_RANK_TEXT or "You have new spell ranks available! Visit trainer or Book of Ascension to upgrade",
	animatePointer	  = true,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	system			  = "micromenu",
	systemPriority    = 60,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
}

HelpTips["HELP_TIP_UNSPENT_ESSENCE"] = {
	parent            = "TalentMicroButton",
	strata			  = "TOOLTIP",
	text              = HELP_TIP_UNSPENT_ESSENCE_TEXT or "You can obtain new Ability or Talent using\n|cffFFFF00[Ability Essence]|r or |cffFFFF00[Talent Essence]|r",
	animatePointer	  = true,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	system			  = "micromenu",
	systemPriority    = 40,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
}

HelpTips["HELP_TIP_UNSPENT_ESSENCE_DEFAULT_CLASS"] = {
	parent            = "TalentMicroButton",
	strata			  = "TOOLTIP",
	text              = HELP_TIP_UNSPENT_ESSENCE_DEFAULT_CLASS_TEXT or "HELP_TIP_UNSPENT_ESSENCE_DEFAULT_CLASS_TEXT",
	animatePointer	  = true,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	system			  = "micromenu",
	systemPriority    = 41,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
}

HelpTips["HELP_TIP_UNSPENT_ESSENCE_CUSTOM_CLASS"] = {
	parent            = "TalentMicroButton",
	strata			  = "TOOLTIP",
	text              = HELP_TIP_UNSPENT_ESSENCE_CUSTOM_CLASS_TEXT or "HELP_TIP_UNSPENT_ESSENCE_CUSTOM_CLASS_TEXT",
	animatePointer	  = true,
	textJustifyH      = "CENTER",
	targetPoint       = HelpTip.Point.TopEdgeCenter,
	system			  = "micromenu",
	systemPriority    = 42,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
}

HelpTips["FORCED_PRIMARY_STAT_TIP"] = {
    text = FORCED_PRIMARY_STAT_HELP_TIP,
    parent  = "TalentMicroButton",
    targetPoint = HelpTip.Point.TopEdgeCenter,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    acknowledgeOnHide = true,
	system			  = "micromenu",
	systemPriority    = 90,
	strata = "FULLSCREEN",
}

HelpTips["CA_WCMR_SEARCH_DESIRED_HELP"] = {
    text = CA_WCMR_SEARCH_HELP_TEXT or "Search for spells you wish to obtain and mark them as desired spells.",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    highlightTarget = HelpTip.TargetType.Box,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    animatePointer	  = true,
}

HelpTips["CA_WCMR_SEARCH_UNLEARN_HELP"] = {
    text = CA_WCMR_SEARCH_HELP_TEXT or "Search for spells you know to mark them as unlearn spells.",
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    highlightTarget = HelpTip.TargetType.Box,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    animatePointer	  = true,
}

HelpTips["MINIMAP_COMPLETE_QUEST"] = {
	parent = "Minimap",
	text = "To complete your Quest, please visit the place marked as |cffFFFF00Question Mark|r at your |cffFFFF00Minimap|r",
	targetPoint = HelpTip.Point.LeftEdgeCenter,
	buttonStyle = HelpTip.ButtonStyle.GotIt,
	offsetX = -16,
}

HelpTips["GOSSIP_REWARDS_HELPER"] = {
    parent = "QuestInfoItem1",
    text = ERR_QUEST_MUST_CHOOSE,
    targetPoint = HelpTip.Point.TopEdgeRight,
    animatePointer = true,
    --highlightTarget = HelpTip.TargetType.Box,
}

HelpTips["GOSSIP_SELECT_HELPER"] = {
    parent = nil,
    text = TIP_QUEST_FRAME_SELECT,
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    acknowledgeOnHide = false,
    animatePointer = true,
    dontReleaseUntilAcknowledged = true,
    highlightTarget = HelpTip.TargetType.Box,
}

HelpTips["LFD_ROLE_SELECT_HELP"] = {
    parent = function() return _G["AscensionPVEFrameLFDFrameRoleFrameHelper"] end,
    text = ERR_LFG_NO_ROLES_SELECTED,
    targetPoint = HelpTip.Point.BottomEdgeCenter,
    buttonStyle = HelpTip.ButtonStyle.GotIt,
    highlightTarget = HelpTip.TargetType.Box,
    --offsetX = -16,
}

HelpTips["WARDROBE_CHANGE_TRANSMOG_HINT"] = {
	parent         = "TalentMicroButton",
	system 		   = "micromenu",
	systemPriority = 20,
	text           = TIP_OPEN_WARDROBE_TO_CHANGE_TRANSMOG,
	cvar           = "HelpTipBitfield",
	cvarBit        = HelpTips.Bits.WardrobeHint1,
	textJustifyH   = "CENTER",
	targetPoint    = HelpTip.Point.TopEdgeCenter,
	buttonStyle 	= HelpTip.ButtonStyle.GotIt,
}

HelpTips["WARDROBE_CHANGE_TRANSMOG"] = {
	parent         = "AppearanceWardrobeFrameDisableTransmogButton",
	text           = TIP_WARDROBE_CHANGE_TRANSMOG,
	cvar           = "HelpTipBitfield",
	cvarBit        = HelpTips.Bits.WardrobeHint2,
	textJustifyH   = "CENTER",
	targetPoint    = HelpTip.Point.BottomEdgeCenter,
	buttonStyle 	= HelpTip.ButtonStyle.GotIt,
}

HelpTips["LAYER_PICKER"] = {
    parent                          = "LayerPickerFrame",
    text                            = TIP_LAYER_PICKER,
    textJustifyH                    = "CENTER",
    cvar                            = "HelpTipBitfield",
    cvarBit                         = HelpTips.Bits.LayerPicker,
    targetPoint                     = HelpTip.Point.LeftEdgeCenter,
    acknowledgeOnHide               = false,
    animatePointer                  = true,
    dontReleaseUntilAcknowledged    = true,
    buttonStyle                     = HelpTip.ButtonStyle.GotIt,
}

HelpTips["UNANSWERED_PLAYER_POLL_QUESTIONS"] = {
    parent            = "HelpMicroButton",
    text              = TIP_UNANSWERED_PLAYER_POLL_QUESTIONS,
    buttonStyle       = HelpTip.ButtonStyle.Okay,
    textJustifyH      = "CENTER",
    targetPoint       = HelpTip.Point.TopEdgeCenter,
    acknowledgeOnHide = false,
    system            = "micromenu",
    systemPriority    = 10,
}

local Addon = select(2, ...)
local PrestigeModeUI = CreateFrame("FRAME", "PrestigeModeUI", UIParent, "PortraitFrameTemplate")
PrestigeModeUI:Hide()

Addon.PrestigeModeUI = PrestigeModeUI

-------------------------------------------------------------------------------
--                                 Variables                                 --
-------------------------------------------------------------------------------
PrestigeModeUI.NPC 			= 178081
PrestigeModeUI.CURRENCY 	= 90004
PrestigeModeUI.MAX_LEVEL 	= 60 -- prestige any level above 60

PrestigeModeUI.DEFAULT_SPEC_ICON = "Interface\\Icons\\inv_misc_book_16"

PrestigeModeUI.MSGS = {
	UNLOCK_CURRENT_SPEC			= PRESTIGE_UI_UNLOCK_CURRENT_SPEC or "Unlock specialization (Character Advancement)",
	DELETE_HOF_ACTIVE_SPEC		= PRESTIGE_UI_DELETE_HOF_ACTIVE_SPEC or "Delete Hands of Fate for Active Specialization",
	DELETE_SOF_ACTIVE_SPEC		= PRESTIGE_UI_DELETE_SOF_ACTIVE_SPEC or "Delete %s for Active Specialization",
	PRESTIGE_MODE 				= PRESTIGE_UI_PRESTIGE_MODE or "Prestige Mode",
	PRESTIGE_MODE_TEXT			= PRESTIGE_UI_PRESTIGE_MODE_TEXT or "Reset your character to level 1, adventure, and earn reward!",
	STEP_1 						= PRESTIGE_UI_STEP_1 or "Step 1: Meet Requirements",
	STEP_1_TEXT					= PRESTIGE_UI_STEP_1_TEXT or "Achieve level %i or greater",
	REACH_LEVEL					= PRESTIGE_UI_REACH_LEVEL or "Reach Level %i or greater",
	RESET_TITLE					= PRESTIGE_UI_RESET_TITLE or "Step 2: Reset your Specialization",
	STEP_2_TEXT					= PRESTIGE_UI_STEP_2_TEXT or "Activate Prestige Mode and go back to level 1",
	RESET_SUBTITLE1 			= PRESTIGE_UI_RESET_SUBTITLE1 or "|cffFF0000What is RESET",
	RESET_SUBTITLE2				= PRESTIGE_UI_RESET_SUBTITLE2 or "|cff00FF00What you will keep",
	SPEC_LOCK 					= PRESTIGE_UI_SPEC_LOCK or "|cffFF0000Specialization lock|r",
	SPEC_LOCK_TEXT				= PRESTIGE_UI_SPEC_LOCK_TEXT or "Once Prestige Mode is activated you will not be able to change specialization until reaching level %i.",
	DRAFT_RESET 				= PRESTIGE_UI_DRAFT_RESET or "|cffFF0000Draft Mode Reset|r",
	DRAFT_RESET_TEXT			= PRESTIGE_UI_DRAFT_RESET_TEXT or "Resets your |cffFF0000CURRENT SPECIALIZATION ONLY|r. This is a complete reset of all abilities. Slot new Skillcards on your run to unlock your build. Resets your current specializations Hand of Fate quest chain.",
	WILDCARD_RESET 				= PRESTIGE_UI_WILDCARD_RESET or "|cffFF0000Wild Card Reset|r",
	WILDCARD_RESET_TEXT			= PRESTIGE_UI_WILDCARD_RESET_TEXT or "Resets your |cffFF0000CURRENT SPECIALIZATION ONLY|r. This is a complete reset of all abilities. Slot new Skillcards on your run to unlock your build. Resets your current specializations Scroll of Fortune quest chain.",
	STEP_3						= PRESTIGE_UI_STEP_3 or "Step 3: Earn Rewards!",
	STEP_3_TEXT					= PRESTIGE_UI_STEP_3_TEXT or "Achieve level %i or higher again and gain Prestigious Rewards!",
	CHECK_OUT_REWARDS			= PRESTIGE_UI_CHECK_OUT_REWARDS or "Check out Prestigious Rewards!",
	TOKENS_OF_PRESTIGE			= PRESTIGE_UI_TOKENS_OF_PRESTIGE or "Gain |cffFFFFFFTokens of Prestige|r to spend them on unique rewards!",
	ACTIVATION_TEXT				= PRESTIGE_UI_ACTIVATION_TEXT or "Are you ready to Prestige?",
	NO_ACTIVE_HOF				= PRESTIGE_UI_NO_ACTIVE_HOF or "Have no Hand of Fate for the specialization you wish to prestige in your bags, bank or personal bank.",
	NO_ACTIVE_COF				= PRESTIGE_UI_NO_ACTIVE_COF or "Have no Cases or Scrolls of Fortune for the specialization you wish to prestige in your bags, bank or personal bank.",
	EXOTIC_PETS 				= PRESTIGE_UI_EXOTIC_PETS or "Exotic Pets\n|cffFF0000(This will remove ALL Exotic Pets across ALL specializations)|r",
	RESET_SPEC					= PRESTIGE_UI_RESET_SPEC or "Reset %s and\nActivate Prestige Mode",
	DAILY_QUEST_TITLE			= PRESTIGE_UI_DAILY_QUEST_TITLE or "Prestige Daily:",
	DAILY_QUEST_TEXT			= PRESTIGE_UI_DAILY_QUEST_TEXT or 'The Prestige daily today is "%s". You will gain bonus experience and other rewards for participating.',
	REWARDS 					= PRESTIGE_UI_REWARDS or "Prestigious Rewards",
	REWARDS_TEXT				= PRESTIGE_UI_REWARDS_TEXT or "Cosmetics to show off your prestigious achievements!",
	TEMPORAL_CONTRACTS			= PRESTIGE_UI_TEMPORAL_CONTRACTS or "Temporal Contracts",
	TEMPORAL_CONTRACTS_TEXT		= PRESTIGE_UI_TEMPORAL_CONTRACTS_TEXT or "Running out of time? Complete Call Board Quests for gold instead!",
	DAILY_QUEST 				= PRESTIGE_UI_DAILY_QUEST or "Today's Prestige Quest:\n%s",
	GOSSIP_CURRENT_QUEST		= PRESTIGE_UI_GOSSIP_CURRENT_QUEST or "^Today's Prestige Quest is (.*)$", -- don't locale
	GOSSIP_OPTION_REWARDS		= PRESTIGE_UI_GOSSIP_OPTION_REWARDS or "I would like to purchase Prestige items!", -- don't locale
	GOSSIP_OPTION_CONTRACTS		= PRESTIGE_UI_GOSSIP_OPTION_CONTRACTS or "I would like to purchase Temporal contracts to complete my Callboard Quests!",
	GOSSIP_OPTION_PRESTIGE		= PRESTIGE_UI_GOSSIP_OPTION_PRESTIGE or "I would like to prestige!", -- don't locale
	GOSSIP_OPTION_CLEAR_HOF		= PRESTIGE_UI_GOSSIP_OPTION_CLEAR_HOF or "GOSSIP_ACTION_DESTROY_HANDS_OF_FATE", -- don't locale
	GOSSIP_OPTION_CLEAR_SOF     = PRESTIGE_UI_GOSSIP_OPTION_CLEAR_SOF or "GOSSIP_ACTION_DESTROY_SCROLLS_OF_FORTUNE", -- don't locale
	GOSSIP_OPTION_BUY_EXP		= PRESTIGE_UI_GOSSIP_OPTION_BUY_EXP or "GOSSIP_ACTION_EXPERIENCE_ITEMS", -- don't locale
	POPUP_TEXT_STEP_1			= PRESTIGE_UI_POPUP_TEXT_STEP_1 or "This action will set you |cffFF0000BACK TO LEVEL 1|r.\nAre you sure you want to activate Prestige Mode?",
	POPUP_TEXT_STEP_2_BLANK		= PRESTIGE_UI_POPUP_TEXT_STEP_2_BLANK or "This action will |cffFF0000PURGE TALENTS AND ABILITIES|r for:\n\n|T%s.blp:32:32:0:-12|t |cffffd100%s|r\n\n|cffFF0000YOU CAN NOT UNDO THIS ACTION.|r\n\nAre you sure you want to activate Prestige Mode?",
	POPUP_TEXT_STEP_2 		 	= PRESTIGE_UI_POPUP_TEXT_STEP_2 or "",
	ERROR_LEVEL					= PRESTIGE_UI_ERROR_LEVEL or "You must be level %i or higher to participate in Prestige Mode",
	ERROR_HOF					= PRESTIGE_UI_ERROR_HOF or "You must have no Hands of Fate to participate in Prestige Mode",
	ERROR_COF 					= PRESTIGE_UI_ERROR_COF or "You must have no %s to participate in Prestige Mode",
	PRESTIGE_REWARDS 			= PRESTIGE_UI_PRESTIGE_REWARDS or "Prestige and get following rewards!",
	POPUP_CLEAR_HOF_STEP_1  	= PRESTIGE_UI_POPUP_CLEAR_HOF_STEP_1 or "This action will |cffFF0000DELETE|r Hand of Fate items from your inventory and bank. Are you sure you want to delete those items? ",
	POPUP_CLEAR_HOF_STEP_1_SOF  = PRESTIGE_UI_POPUP_CLEAR_HOF_STEP_1_SOF or "This action will |cffFF0000DELETE|r from your inventory and bank:|cffFF0000\n\n|TInterface\\Icons\\Inv_custom_scrollofunlearning_seasonal.blp:18:18:0:-2|t Scrolls of Fortune\n|TInterface\\Icons\\trade_archaeology_apexisscroll.blp:18:18:0:-2|t Cases of Fortune\n|TInterface\\Icons\\INV_Chest_Awakening.blp:18:18:0:-2|t Bonus Manastorm Caches\n\n|rAre you sure you want to delete those items? ",
	POPUP_CLEAR_HOF_STEP_2      = PRESTIGE_UI_POPUP_CLEAR_HOF_STEP_2 or "This action will |cffFF0000DELETE ALL|r your Hands of Fate for %s\n\n|cffFF0000YOU CAN NOT UNDO THIS ACTION.|r\n\nAre you sure you want to delete Hands of Fate?",
	POPUP_CLEAR_HOF_STEP_2_SOF  = PRESTIGE_UI_POPUP_CLEAR_HOF_STEP_2_SOF or "This action will |cffFF0000DELETE ALL\n\n|TInterface\\Icons\\Inv_custom_scrollofunlearning_seasonal.blp:18:18:0:-2|t Scrolls of Fortune\n|TInterface\\Icons\\trade_archaeology_apexisscroll.blp:18:18:0:-2|t Cases of Fortune\n|TInterface\\Icons\\INV_Chest_Awakening.blp:18:18:0:-2|t Bonus Manastorm Caches\n|rfor %s\n\n|cffFF0000YOU CAN NOT UNDO THIS ACTION.|r\n\nAre you sure you want to delete Cases of Fortune, Scrolls of Fortune and Bonus Manastorm Caches?",
	BUY_EXP 					= PRESTIGE_UI_BUY_EXP or "Experience Items",
	BUY_EXP_TEXT				= PRESTIGE_UI_BUY_EXP_TEXT or "Buy Experience items using Bazaar tokens to speed up you and your parties leveling experience!",
	ERROR_SPEC_LOCKED 			= PRESTIGE_UI_ERROR_SPEC_LOCKED or "Your active specialization is prestige locked."
}

PrestigeModeUI.gossipOptions = {
	ACTIVATE 	= 0,
	REWARDS 	= 0,
	CONTRACTS 	= 0,
	CLEAR_HOF 	= 0,
	BUY_EXP 	= 0,
}

PrestigeModeUI.MAX_AVAILABLE_QUESTS = 2

PrestigeModeUI.QUEST_REWARDS = { -- TODO: Add json support
	[60] = {
		{itemID = 97304, amount = 1},
		{itemID = 375250, amount = 100000},
		},
	[70] = {
		{itemID = 1297304, amount = 1},
		{itemID = 375250, amount = 50000},
	},
	[80] = {
		{itemID = 1297305, amount = 1},
		{itemID = 375250, amount = 100000},
	},
}

StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_1"] = {
    text = PrestigeModeUI.MSGS.POPUP_TEXT_STEP_1,
    button1 = OKAY,
    button2 = CANCEL,
    whileDead = true,
    timeout = 0,
    hideOnEscape = true,
    --[[OnAccept = function(self)
	end,]]--
	OnAccept = function (self)
		StaticPopup_Hide("ASC_PRESTIGE_ACTIVATION_1")
		StaticPopup_Show("ASC_PRESTIGE_ACTIVATION_2")
	end,
}

StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_2"] = {
    --text = PrestigeModeUI.MSGS.POPUP_TEXT_STEP_2,
	button1 = OKAY,
	button2 = CANCEL,
    whileDead = true,
    timeout = 0,
    hideOnEscape = true,
    showAlert = true,
}
-------------------------------------------------------------------------------
--                                UI Classes                                 --
-------------------------------------------------------------------------------
function PrestigeModeUI.ClickGossipOption(button) -- from SharedCode. TODO: Merge current UI with shared
	if (button.gossipOption) then
		local option = PrestigeModeUI.gossipOptions[button.gossipOption]
		if (option and (option ~= 0) ) then
			SelectGossipOption(option)
		end
	end
end

function PrestigeModeUI:CreateQuest(name, parent)
	local button = CreateFrame("BUTTON", "$parent."..name, parent)
	button:SetSize(180, 42)
	button:EnableMouse(true)

	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetPoint("CENTER", 0, 0)
	button.bg:SetAtlas("pvpqueue-button-selected", Const.TextureKit.IgnoreAtlasSize)
	button.bg:SetAllPoints()
	button.bg:SetBlendMode("ADD")

	button.questIcon = button:CreateTexture(nil, "ARTWORK")
	button.questIcon:SetPoint("LEFT", 4, 0)
	button.questIcon:SetAtlas("quest-dailycampaign-available", Const.TextureKit.IgnoreAtlasSize)
	button.questIcon:SetSize(24, 24)

	button.text = button:CreateFontString(nil, "OVERLAY")
	button.text:SetFontObject(GameFontNormal)
	button.text:SetPoint("LEFT", button.questIcon, "RIGHT", 4, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetJustifyV("CENTER")
	button.text:SetWidth(148)

	button:SetScript("OnEnter", function(self)
		if self.tooltipTitle or self.tooltipText then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)

			if (self.tooltipTitle) then
				GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1, 1)
			end

			if (self.tooltipText) then
				GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, 1)
			end

			GameTooltip:Show()
		end

		self.text:SetFontObject(GameFontHighlight)
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self.text:SetFontObject(GameFontNormal)
	end)

	return button
end

function PrestigeModeUI:CreateAvailableQuest(name, parent)
	local button = PrestigeModeUI:CreateQuest(name, parent)
	button.text:SetFontObject(GameFontHighlightMedium)
	button.text:SetText("Prestige: Open World")

	button.questIcon:SetAtlas("questturnin", Const.TextureKit.IgnoreAtlasSize)

	button.buttonTexture = button:CreateTexture(nil, "BACKGROUND")
	button.buttonTexture:SetPoint("CENTER", 0, 0)
	button.buttonTexture:SetAtlas("pvpqueue-button-casual-up", Const.TextureKit.IgnoreAtlasSize)
	button.buttonTexture:SetAllPoints()
	button.buttonTexture:SetBlendMode("ADD")

	button.bg:SetDrawLayer("BORDER")

	button.highlight = button:CreateTexture(nil, "OVERLAY")
	button.highlight:SetPoint("CENTER", 0, 0)
	button.highlight:SetAtlas("pvpqueue-button-casual-highlight", Const.TextureKit.IgnoreAtlasSize)
	button.highlight:SetAllPoints()
	button.highlight:SetBlendMode("ADD")
	button.highlight:Hide()

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)

		if (self.tooltipTitle) then
			GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1, 1)
		end

		GameTooltip:AddLine("Click to complete Quest", 1, 0.82, 0, 1)

		GameTooltip:Show()

		self.highlight:Show()
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self.highlight:Hide()
	end)


	button:SetScript("OnClick", function(self)
		if self.ID and (self.ID ~= 0) then
			SelectGossipActiveQuest(self.ID)
		end
	end)

	return button
end

function PrestigeModeUI:CreateTab(name, parent)
	if not(parent.tabs) then
		parent.tabs = {}
	end

	local btn = CreateFrame("BUTTON", name, parent)
	table.insert(parent.tabs, btn)

    btn:SetSize(180, 39)

    btn.highlight = btn:CreateTexture(nil, "OVERLAY")
    btn.highlight:SetSize(176, 36)
    btn.highlight:SetPoint("CENTER", 0, 2)
    btn.highlight:SetAtlas("store-category-selected", Const.TextureKit.IgnoreAtlasSize)
    btn.highlight:SetBlendMode("ADD")
    btn.highlight:Hide()

    btn.checked = btn:CreateTexture(nil, "OVERLAY")
    btn.checked:SetSize(176, 36)
    btn.checked:SetPoint("CENTER", 0, 2)
    btn.checked:SetAtlas("store-category-hover", Const.TextureKit.IgnoreAtlasSize)
    btn.checked:SetBlendMode("ADD")
    btn.checked:Hide()

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("CENTER", 0, 0)
    btn.bg:SetAtlas("store-category", Const.TextureKit.IgnoreAtlasSize)
    btn.bg:SetSize(180, 39)

    btn.icon = btn:CreateTexture(nil, "BORDER")
    btn.icon:SetSize(26, 26)
    btn.icon:SetPoint("LEFT", 6, 3)
    SetPortraitToTexture(btn.icon, "Interface\\Icons\\inv_custom_trainerBook")

    btn.iconBorder = btn:CreateTexture(nil, "ARTWORK")
    btn.iconBorder:SetSize(44, 44)
    btn.iconBorder:SetPoint("LEFT", -3, 2)
    btn.iconBorder:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)

    btn.text = btn:CreateFontString(nil, "ARTWORK")
    btn.text:SetJustifyH("LEFT")
    btn.text:SetJustifyV("CENTER")
    btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 12, 0)

    btn.text:SetWordWrap(true)
    btn.text:SetNonSpaceWrap(true)
    btn.text:SetFontObject(GameFontNormal)
    btn.text:SetText("Category Name")

    btn:SetScript("OnEnter", function(self)
    	if (self.tooltipTitle and self.tooltipText) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
			GameTooltip:AddLine(self.tooltipTitle, 1, 1, 1, 1)
			GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, 1)
		end

		if self.disabled and (self.disableLine) then
			GameTooltip:AddLine(self.disableLine, 1, 0, 0, 1)
		else
			self.text:SetFontObject(GameFontHighlight)
		end

		GameTooltip:Show()
    	self.highlight:Show()
	end)

	btn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		if not(self.disabled) then
			self.text:SetFontObject(GameFontNormal)
		end
		self.highlight:Hide()
	end)

	btn:SetScript("OnMouseDown", function(self)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", 14, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", 12, 0)
	end)

	btn:SetScript("OnClick", PrestigeModeUI.ClickGossipOption)

	function btn:Enable()
		self.disabled = false

		self.bg:SetDesaturated(false)
		self.icon:SetDesaturated(false)
		self.iconBorder:SetDesaturated(false)
		self.text:SetFontObject(GameFontNormal)
	end

	function btn:Disable()
		self.disabled = true

		self.bg:SetDesaturated(true)
		self.icon:SetDesaturated(true)
		self.iconBorder:SetDesaturated(true)
		self.text:SetFontObject(GameFontDisable)
	end

    return btn
end

function PrestigeModeUI:CreateTextBlock(parent)
	local frameID = (parent.blocks and (#parent.blocks+1)) or 1
	local frame = CreateFrame("FRAME", parent:GetName()..".block"..frameID, parent)

	function frame:AddDividerTexture()
		local tex = self:CreateTexture(nil, "ARTWORK")
		tex:SetTexture("Interface\\Prestige\\seperator_export_withShadow", "MIRROR", "MIRROR")
		tex:SetHorizTile(true)
		tex:SetHeight(64)

		local shadowLeft = self:CreateTexture(nil, "OVERLAY")
		shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
		shadowLeft:SetWidth(200)
		shadowLeft:SetHeight(32)
		shadowLeft:SetPoint("LEFT", tex, 0, 0)
		shadowLeft:SetAlpha(0.7)

		local shadowRight = self:CreateTexture(nil, "OVERLAY")
		shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
		shadowRight:SetWidth(200)
		shadowRight:SetHeight(32)
		shadowRight:SetPoint("RIGHT", tex, 0, 0)
		shadowRight:SetAlpha(0.7)

		self.separator = tex

		return tex
	end

	function frame:AddStepBlock()
		local object = {}

		local number = self:CreateTexture(nil, "ARTWORK")
	    number:SetAtlas("services-number-1", Const.TextureKit.IgnoreAtlasSize)
	    --number:SetSize(71, 79)
	    number:SetSize(53, 59)

	    local ring = self:CreateTexture(nil, "ARTWORK")
	    ring:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
	    ring:SetPoint("CENTER", number)
	    --ring:SetSize(80, 82)
	    ring:SetSize(60, 61)

	   	--[[local bg = self:CreateTexture(nil, "BORDER")
	    bg:SetAtlas("services-ring-large-glow", Const.TextureKit.IgnoreAtlasSize)
	    bg:SetPoint("CENTER", number)
	    --bg:SetSize(253, 256)
	    bg:SetSize(190, 192)]]--

		local fontString = self:CreateFontString(nil)
		fontString:SetFontObject(GameFontNormal)
		fontString:SetText("")
		fontString:SetWidth(160)
		fontString:SetPoint("TOP", number, "BOTTOM", 0, -8)

	    function object:SetPoint(...)
	    	self.number:SetPoint(...)
	    end

	    function object:SetText(...)
	    	self.fontString:SetText(...)
	    end

	    object.fontString = fontString
	    object.number = number
	    object.ring = ring
	    object.bg = bg

	    return object
	end

	function frame:AddIconBlockShort(texture, text)
		local object = {}

		local icon = self:CreateTexture(nil, "ARTWORK")
	    icon:SetSize(32,32)
	    icon:SetTexture(texture)

	    local slot = self:CreateTexture(nil, "BORDER")
	    slot:SetSize(53,53)
	    slot:SetTexture("Interface\\Spellbook\\UI-Spellbook-SpellBackground")
	    slot:SetPoint("CENTER", icon, 8.5, -8.5)

	    local fontString = self:CreateFontString(nil)
    	fontString:SetFontObject(GameFontNormal)
	    fontString:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	    fontString:SetWidth(192)
	    fontString:SetHeight(64)
    	fontString:SetJustifyH("LEFT")
    	fontString:SetJustifyV("CENTER")
    	fontString:SetText(text)

    	object.icon = icon
    	object.slot = slot
    	object.fontString = fontString

    	function object:SetPoint(...)
    		object.icon:SetPoint(...)
    	end

    	function object:SetText(...)
    		object.fontString:SetText(...)
    	end

		function object:SetIcon(...)
			object.icon:SetTexture(...)
		end

    	return object
	end

	function frame:AddIconBlockLong(texture, title, text)
		local object = self:AddIconBlockShort(texture, text)

		local titleFontString = self:CreateFontString(nil)
    	titleFontString:SetFontObject(GameFontNormalLarge)
	    titleFontString:SetPoint("TOPLEFT", object.icon, "TOPRIGHT", 8, 0)
	    titleFontString:SetWidth(256)
	    titleFontString:SetHeight(18)
    	titleFontString:SetJustifyH("LEFT")
    	titleFontString:SetJustifyV("TOP")
    	titleFontString:SetText(title)

    	object.fontString:ClearAllPoints()
    	object.fontString:SetPoint("TOPLEFT", titleFontString, "BOTTOMLEFT")
    	object.fontString:SetJustifyV("TOP")
    	object.fontString:SetHeight(0)
    	object.fontString:SetWidth(384)

    	object.titleFontString = titleFontString
		
		function object:SetTitle(...)
			object.titleFontString:SetText(...)
		end

    	return object
	end

	if not(parent.blocks) then
		parent.blocks = {}
		frame:SetPoint("TOP", 0, 0)
	else
		frame:SetPoint("TOP", parent.blocks[frameID-1], "BOTTOM", 0, 0)
	end

	table.insert(parent.blocks, frame)
	--frame:SetBackdrop(GameTooltip:GetBackdrop())
	frame:SetWidth(parent:GetWidth())

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetWidth(frame:GetWidth())

	frame.bg = frame:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetTexture("Interface\\Prestige\\paperbg", "MIRROR", "MIRROR")
	frame.bg:SetAllPoints(true)
	frame.bg:SetVertTile(true)
	frame.bg:SetHorizTile(true)

	frame.shadowLeft = frame:CreateTexture(nil, "BORDER")
	frame.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
	frame.shadowLeft:SetWidth(200)
	frame.shadowLeft:SetHeight(frame:GetHeight())
	frame.shadowLeft:SetPoint("LEFT")
	frame.shadowLeft:SetAlpha(0.6)

	frame.shadowRight = frame:CreateTexture(nil, "BORDER")
	frame.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
	frame.shadowRight:SetWidth(200)
	frame.shadowRight:SetHeight(frame:GetHeight())
	frame.shadowRight:SetPoint("RIGHT")
	frame.shadowRight:SetAlpha(0.6)

	frame:SetScript("OnSizeChanged", function(self, width, height)
		self.title:SetWidth(self:GetWidth())
		self.shadowLeft:SetHeight(self:GetHeight())
		self.shadowRight:SetHeight(self:GetHeight())

		if (self.separator) then
			self.separator:SetWidth(self:GetWidth())
		end
	end)

	function frame:HideBG()
		self.shadowLeft:Hide()
		self.shadowRight:Hide()
		self.bg:Hide()
	end

	return frame
end

-------------------------------------------------------------------------------
--                                    UI                                     --
-------------------------------------------------------------------------------
PrestigeModeUI:SetSize(784,512)
PrestigeModeUI:SetPoint("CENTER", 0, 0)
PrestigeModeUI:SetClampedToScreen(true)
PrestigeModeUI:RegisterForDrag("LeftButton")
PrestigeModeUI:SetScript("OnDragStart", PrestigeModeUI.StartMoving)
PrestigeModeUI:SetScript("OnDragStop", PrestigeModeUI.StopMovingOrSizing)
PrestigeModeUI:SetMovable(true)
PrestigeModeUI:EnableMouse(true)
SetPortraitToTexture(PrestigeModeUI.portrait, "Interface\\ICONS\\ability_mage_timewarp")
PrestigeModeUI.TitleText:SetText(PrestigeModeUI.MSGS.PRESTIGE_MODE)

PrestigeModeUI.Tabs = CreateFrame("FRAME", "PrestigeModeUI.Tabs", PrestigeModeUI, "InsetFrameTemplate")
PrestigeModeUI.Tabs:SetPoint("BOTTOMLEFT", 4, 6)
PrestigeModeUI.Tabs:SetSize((PrestigeModeUI:GetWidth()*0.25)-4, 436)
PrestigeModeUI.Tabs.Bg:SetTexture("Interface\\Prestige\\bg", "MIRROR", "MIRROR")

-- shadow for tabs
PrestigeModeUI.Tabs.cornerTopLeft = PrestigeModeUI.Tabs:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.Tabs.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.Tabs.cornerTopLeft:SetSize(73, 74)
PrestigeModeUI.Tabs.cornerTopLeft:SetPoint("TOPLEFT")

PrestigeModeUI.Tabs.cornerTopRight = PrestigeModeUI.Tabs:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.Tabs.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.Tabs.cornerTopRight:SetSize(73, 74)
PrestigeModeUI.Tabs.cornerTopRight:SetPoint("TOPRIGHT")
PrestigeModeUI.Tabs.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)
	
PrestigeModeUI.Tabs.shadowTop = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
PrestigeModeUI.Tabs.shadowTop:SetWidth(PrestigeModeUI.Tabs:GetWidth()-(PrestigeModeUI.Tabs.cornerTopLeft:GetWidth()*2))
PrestigeModeUI.Tabs.shadowTop:SetHeight(100)
PrestigeModeUI.Tabs.shadowTop:SetPoint("TOP")
PrestigeModeUI.Tabs.shadowTop:SetAlpha(0.6)

PrestigeModeUI.Tabs.cornerBottomLeft = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.Tabs.cornerBottomLeft:SetSize(73, 74)
PrestigeModeUI.Tabs.cornerBottomLeft:SetPoint("BOTTOMLEFT")
PrestigeModeUI.Tabs.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)

PrestigeModeUI.Tabs.cornerBottomRight = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.Tabs.cornerBottomRight:SetSize(73, 74)
PrestigeModeUI.Tabs.cornerBottomRight:SetPoint("BOTTOMRIGHT")
PrestigeModeUI.Tabs.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)

PrestigeModeUI.Tabs.shadowBottom = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
PrestigeModeUI.Tabs.shadowBottom:SetWidth(PrestigeModeUI.Tabs:GetWidth()-(PrestigeModeUI.Tabs.cornerTopLeft:GetWidth()*2))
PrestigeModeUI.Tabs.shadowBottom:SetHeight(100)
PrestigeModeUI.Tabs.shadowBottom:SetPoint("BOTTOM")
PrestigeModeUI.Tabs.shadowBottom:SetAlpha(0.6)

PrestigeModeUI.Tabs.shadowLeft = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
PrestigeModeUI.Tabs.shadowLeft:SetWidth(100)
PrestigeModeUI.Tabs.shadowLeft:SetHeight(PrestigeModeUI.Tabs:GetHeight()-(PrestigeModeUI.Tabs.cornerTopLeft:GetHeight()*2))
PrestigeModeUI.Tabs.shadowLeft:SetPoint("LEFT")
PrestigeModeUI.Tabs.shadowLeft:SetAlpha(0.6)

PrestigeModeUI.Tabs.shadowRight = PrestigeModeUI.Tabs:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.Tabs.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
PrestigeModeUI.Tabs.shadowRight:SetWidth(100)
PrestigeModeUI.Tabs.shadowRight:SetHeight(PrestigeModeUI.Tabs:GetHeight()-(PrestigeModeUI.Tabs.cornerTopRight:GetHeight()*2))
PrestigeModeUI.Tabs.shadowRight:SetPoint("RIGHT")
PrestigeModeUI.Tabs.shadowRight:SetAlpha(0.6)

-- token art
PrestigeModeUI.Tabs.tokenArt = PrestigeModeUI.Tabs:CreateTexture(nil, "BORDER")
PrestigeModeUI.Tabs.tokenArt:SetSize(220, 220)
PrestigeModeUI.Tabs.tokenArt:SetTexture("Interface\\Prestige\\prestige_tokens")
PrestigeModeUI.Tabs.tokenArt:SetPoint("BOTTOM", 0, 0)

PrestigeModeUI.Tabs.tokenString = PrestigeModeUI.Tabs:CreateFontString(nil)
PrestigeModeUI.Tabs.tokenString:SetFontObject(SystemFont_Huge1)
PrestigeModeUI.Tabs.tokenString:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
PrestigeModeUI.Tabs.tokenString:SetPoint("BOTTOM", 0, 100)
PrestigeModeUI.Tabs.tokenString:SetWidth(264)
PrestigeModeUI.Tabs.tokenString:SetHeight(18)
PrestigeModeUI.Tabs.tokenString:SetJustifyH("CENTER")
PrestigeModeUI.Tabs.tokenString:SetJustifyV("CENTER")
PrestigeModeUI.Tabs.tokenString:SetText(350)
PrestigeModeUI.Tabs.tokenString:SetShadowOffset(1,-1)

PrestigeModeUI.Tabs.tokenTitle = PrestigeModeUI.Tabs:CreateFontString(nil)
PrestigeModeUI.Tabs.tokenTitle:SetFontObject(GameFontNormalLarge)
PrestigeModeUI.Tabs.tokenTitle:SetPoint("BOTTOM", PrestigeModeUI.Tabs.tokenString, "TOP", 0, 56)
PrestigeModeUI.Tabs.tokenTitle:SetJustifyH("CENTER")
PrestigeModeUI.Tabs.tokenTitle:SetJustifyV("TOP")
PrestigeModeUI.Tabs.tokenTitle:SetText(TOKEN_OF_PRESTIGE)

-- buttons
PrestigeModeUI.Tabs.questComplete1 = PrestigeModeUI:CreateAvailableQuest("questComplete1", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.questComplete1:SetPoint("TOP", 0, -8)

PrestigeModeUI.Tabs.questComplete2 = PrestigeModeUI:CreateAvailableQuest("questComplete2", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.questComplete2:SetPoint("TOP", PrestigeModeUI.Tabs.questComplete1, "BOTTOM", 0, -1)

PrestigeModeUI.availableQuestButtons = {PrestigeModeUI.Tabs.questComplete1, PrestigeModeUI.Tabs.questComplete2}

PrestigeModeUI.Tabs.tabPrestigeDescription = PrestigeModeUI:CreateTab("PrestigeModeUI.Tabs.tabPrestigeDescription", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.tabPrestigeDescription:SetPoint("TOP", PrestigeModeUI.Tabs.questComplete2, "BOTTOM", 0, -8)
SetPortraitToTexture(PrestigeModeUI.Tabs.tabPrestigeDescription.icon, "Interface\\Icons\\ability_mage_timewarp")
PrestigeModeUI.Tabs.tabPrestigeDescription.checked:Show()
PrestigeModeUI.Tabs.tabPrestigeDescription.text:SetText(PrestigeModeUI.MSGS.PRESTIGE_MODE)
PrestigeModeUI.Tabs.tabPrestigeDescription.tooltipTitle = PrestigeModeUI.MSGS.PRESTIGE_MODE
PrestigeModeUI.Tabs.tabPrestigeDescription.tooltipText = PrestigeModeUI.MSGS.PRESTIGE_MODE_TEXT

PrestigeModeUI.Tabs.tabRewards = PrestigeModeUI:CreateTab("PrestigeModeUI.Tabs.tabRewards", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.tabRewards:SetPoint("TOP", PrestigeModeUI.Tabs.tabPrestigeDescription, "BOTTOM", 0, -1)
PrestigeModeUI.Tabs.tabRewards.text:SetText(PrestigeModeUI.MSGS.REWARDS)
SetPortraitToTexture(PrestigeModeUI.Tabs.tabRewards.icon, "Interface\\Icons\\inv_helm_plate_raidpaladin_n_01")
PrestigeModeUI.Tabs.tabRewards.tooltipTitle = PrestigeModeUI.MSGS.REWARDS
PrestigeModeUI.Tabs.tabRewards.tooltipText = PrestigeModeUI.MSGS.REWARDS_TEXT
PrestigeModeUI.Tabs.tabRewards.gossipOption = "REWARDS"

--[[PrestigeModeUI.Tabs.tabTemporalContracts = PrestigeModeUI:CreateTab("PrestigeModeUI.Tabs.tabTemporalContracts", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.tabTemporalContracts:SetPoint("TOP", PrestigeModeUI.Tabs.tabRewards, "BOTTOM", 0, -1)
PrestigeModeUI.Tabs.tabTemporalContracts.text:SetText(PrestigeModeUI.MSGS.TEMPORAL_CONTRACTS)
SetPortraitToTexture(PrestigeModeUI.Tabs.tabTemporalContracts.icon, "Interface\\Icons\\inv_inscription_80_scroll")
PrestigeModeUI.Tabs.tabTemporalContracts.tooltipTitle = PrestigeModeUI.MSGS.TEMPORAL_CONTRACTS
PrestigeModeUI.Tabs.tabTemporalContracts.tooltipText = PrestigeModeUI.MSGS.TEMPORAL_CONTRACTS_TEXT
PrestigeModeUI.Tabs.tabTemporalContracts.gossipOption = "CONTRACTS"
PrestigeModeUI.Tabs.tabTemporalContracts.disableLine = string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, PrestigeModeUI.MAX_LEVEL)]]--

PrestigeModeUI.Tabs.tabBuyExp = PrestigeModeUI:CreateTab("PrestigeModeUI.Tabs.tabBuyExp", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.tabBuyExp:SetPoint("TOP", PrestigeModeUI.Tabs.tabRewards, "BOTTOM", 0, -1)
PrestigeModeUI.Tabs.tabBuyExp.text:SetText(PrestigeModeUI.MSGS.BUY_EXP)
SetPortraitToTexture(PrestigeModeUI.Tabs.tabBuyExp.icon, "Interface\\Icons\\xp_icon")
PrestigeModeUI.Tabs.tabBuyExp.tooltipTitle = PrestigeModeUI.MSGS.BUY_EXP
PrestigeModeUI.Tabs.tabBuyExp.tooltipText = PrestigeModeUI.MSGS.BUY_EXP_TEXT
PrestigeModeUI.Tabs.tabBuyExp.gossipOption = "BUY_EXP"
--PrestigeModeUI.Tabs.tabBuyExp.disableLine = string.format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, PrestigeModeUI.MAX_LEVEL)

-- daily quests
PrestigeModeUI.Tabs.dailyQuest = PrestigeModeUI:CreateQuest("dailyQuest", PrestigeModeUI.Tabs)
PrestigeModeUI.Tabs.dailyQuest:SetPoint("BOTTOM", 0, 6)
PrestigeModeUI.Tabs.dailyQuest.tooltipTitle = PrestigeModeUI.MSGS.DAILY_QUEST_TITLE
PrestigeModeUI.Tabs.dailyQuest.tooltipText = PrestigeModeUI.MSGS.DAILY_QUEST_TEXT
-------------------------------------------------------------------------------
--                     Right Panel. Prestige Activation                      --
-------------------------------------------------------------------------------
PrestigeModeUI.contentFrame = CreateFrame("FRAME", "PrestigeModeUI.contentFrame", PrestigeModeUI, nil)
PrestigeModeUI.contentFrame:SetPoint("CENTER",0,0)
PrestigeModeUI.contentFrame:SetWidth(558)
PrestigeModeUI.contentFrame:SetHeight(1)

PrestigeModeUI.scroll = CreateFrame("ScrollFrame", "PrestigeModeUI.scroll", PrestigeModeUI, "InsetFrameTemplate")
PrestigeModeUI.scroll:SetSize(558,436)
PrestigeModeUI.scroll:SetPoint("BOTTOMRIGHT",-30,6)
PrestigeModeUI.scroll:EnableMouseWheel(true)
PrestigeModeUI.scroll.Bg:SetTexture("Interface\\Prestige\\bg", "MIRROR", "MIRROR")

PrestigeModeUI.scroll.ScrollBar = CreateFrame("Slider", "PrestigeModeUI.scrollScrollBar", PrestigeModeUI.scroll, "UIPanelScrollBarTemplate") 
PrestigeModeUI.scroll.ScrollBar:SetPoint("TOPLEFT", PrestigeModeUI.scroll, "TOPRIGHT", 3.5, -20)  
PrestigeModeUI.scroll.ScrollBar:SetPoint("BOTTOMLEFT", PrestigeModeUI.scroll, "BOTTOMRIGHT", 3.5, 18.5) 
-- artwork for scroll
PrestigeModeUI.scroll.topArt = PrestigeModeUI.scroll:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.scroll.topArt:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
PrestigeModeUI.scroll.topArt:SetSize(31,256)
PrestigeModeUI.scroll.topArt:SetPoint("TOPLEFT", PrestigeModeUI.scroll, "TOPRIGHT",  -4, 0)
PrestigeModeUI.scroll.topArt:SetTexCoord(0, 0.484375, 0, 1)

PrestigeModeUI.scroll.centerArt = PrestigeModeUI.scroll:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.scroll.centerArt:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
PrestigeModeUI.scroll.centerArt:SetSize(31,256)
PrestigeModeUI.scroll.centerArt:SetPoint("LEFT", PrestigeModeUI.scroll, "RIGHT",  -4, 0)
PrestigeModeUI.scroll.centerArt:SetTexCoord(0, 0.484375, 0.1, 1)

PrestigeModeUI.scroll.botArt = PrestigeModeUI.scroll:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.scroll.botArt:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
PrestigeModeUI.scroll.botArt:SetSize(31,106)
PrestigeModeUI.scroll.botArt:SetPoint("BOTTOMLEFT", PrestigeModeUI.scroll, "BOTTOMRIGHT",  -4, 0)
PrestigeModeUI.scroll.botArt:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

PrestigeModeUI.scroll.bgArt = PrestigeModeUI.scroll:CreateTexture(nil, "BACKGROUND")
PrestigeModeUI.scroll.bgArt:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
PrestigeModeUI.scroll.bgArt:SetSize(20, PrestigeModeUI.scroll:GetHeight()-4)
PrestigeModeUI.scroll.bgArt:SetPoint("LEFT", PrestigeModeUI.scroll, "RIGHT", 0, 0)
PrestigeModeUI.scroll.bgArt:SetHorizTile(true)
PrestigeModeUI.scroll.bgArt:SetVertTile(true)

PrestigeModeUI.scroll:SetScrollChild(PrestigeModeUI.contentFrame)
--PrestigeModeUI.scroll:SetScript("OnLoad", ScrollFrame_OnLoad)
--PrestigeModeUI.scroll:SetScript("OnScrollRangeChanged", ScrollFrame_OnScrollRangeChanged)
PrestigeModeUI.scroll:SetScript("OnMouseWheel", function(self, ...) self.targetY = nil ScrollFrameTemplate_OnMouseWheel(self, ...) end)
PrestigeModeUI.scroll:SetScript("OnVerticalScroll", function(self, offset)
	local scrollbar = _G[self:GetName().."ScrollBar"];
	scrollbar:SetValue(offset);
	local min;
	local max;
	min, max = scrollbar:GetMinMaxValues();

	if ( offset == 0 ) then
		_G[scrollbar:GetName().."ScrollUpButton"]:Disable();
	else
		_G[scrollbar:GetName().."ScrollUpButton"]:Enable();
	end

	if ((scrollbar:GetValue() - max) == 0) then
		_G[scrollbar:GetName().."ScrollDownButton"]:Disable();
	else
		_G[scrollbar:GetName().."ScrollDownButton"]:Enable();
	end
end)

function PrestigeModeUI.scroll:SetValue(value)
	local min, max = self.ScrollBar:GetMinMaxValues()

    if (value <= min) then
    	value = min
    	self.targetY = nil
    end

   	if (value >= max) then
    	value = max
    	self.targetX = nil
    end

    self:SetVerticalScroll(value)
end

PrestigeModeUI.scroll:SetScript("OnUpdate", function(self)
    if ( self.targetY ) then
    	local currentPosition = self:GetVerticalScroll()
    	local diff = math.abs(currentPosition - self.targetY)*0.025

		if (currentPosition < (self.targetY - 1)) then
			self:SetValue(currentPosition+diff)
		elseif (currentPosition > (self.targetY + 1)) then
			self:SetValue(currentPosition-diff)
		else
			self.targetY = nil
		end
    end
end)

-- shadow for inner left window
PrestigeModeUI.scroll.cornerTopLeft = PrestigeModeUI.scroll:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.scroll.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.scroll.cornerTopLeft:SetSize(147, 149)
PrestigeModeUI.scroll.cornerTopLeft:SetPoint("TOPLEFT")

PrestigeModeUI.scroll.cornerTopRight = PrestigeModeUI.scroll:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.scroll.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.scroll.cornerTopRight:SetSize(147, 149)
PrestigeModeUI.scroll.cornerTopRight:SetPoint("TOPRIGHT")
PrestigeModeUI.scroll.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)

PrestigeModeUI.scroll.shadowTop = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
PrestigeModeUI.scroll.shadowTop:SetWidth(PrestigeModeUI.scroll:GetWidth()-(PrestigeModeUI.scroll.cornerTopLeft:GetWidth()*2))
PrestigeModeUI.scroll.shadowTop:SetHeight(200)
PrestigeModeUI.scroll.shadowTop:SetPoint("TOP")
PrestigeModeUI.scroll.shadowTop:SetAlpha(0.6)

PrestigeModeUI.scroll.cornerBottomLeft = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.scroll.cornerBottomLeft:SetSize(147, 149)
PrestigeModeUI.scroll.cornerBottomLeft:SetPoint("BOTTOMLEFT")
PrestigeModeUI.scroll.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)

PrestigeModeUI.scroll.cornerBottomRight = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
PrestigeModeUI.scroll.cornerBottomRight:SetSize(147, 149)
PrestigeModeUI.scroll.cornerBottomRight:SetPoint("BOTTOMRIGHT")
PrestigeModeUI.scroll.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)

PrestigeModeUI.scroll.shadowBottom = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
PrestigeModeUI.scroll.shadowBottom:SetWidth(PrestigeModeUI.scroll:GetWidth()-(PrestigeModeUI.scroll.cornerTopLeft:GetWidth()*2))
PrestigeModeUI.scroll.shadowBottom:SetHeight(200)
PrestigeModeUI.scroll.shadowBottom:SetPoint("BOTTOM")
PrestigeModeUI.scroll.shadowBottom:SetAlpha(0.6)

PrestigeModeUI.scroll.shadowLeft = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
PrestigeModeUI.scroll.shadowLeft:SetWidth(200)
PrestigeModeUI.scroll.shadowLeft:SetHeight(PrestigeModeUI.scroll:GetHeight()-(PrestigeModeUI.scroll.cornerTopLeft:GetHeight()*2))
PrestigeModeUI.scroll.shadowLeft:SetPoint("LEFT")
PrestigeModeUI.scroll.shadowLeft:SetAlpha(0.6)

PrestigeModeUI.scroll.shadowRight = PrestigeModeUI.scroll:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.scroll.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
PrestigeModeUI.scroll.shadowRight:SetWidth(200)
PrestigeModeUI.scroll.shadowRight:SetHeight(PrestigeModeUI.scroll:GetHeight()-(PrestigeModeUI.scroll.cornerTopRight:GetHeight()*2))
PrestigeModeUI.scroll.shadowRight:SetPoint("RIGHT")
PrestigeModeUI.scroll.shadowRight:SetAlpha(0.6)

-------------------------------------------------------------------------------
--                  Right Panel. Prestige Activation Content                 --
-------------------------------------------------------------------------------
-- models and main description
PrestigeModeUI.block1 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.contentFrame)
PrestigeModeUI.block1:SetHeight(392)
PrestigeModeUI.block1:HideBG()

PrestigeModeUI.block1.title:SetText(PrestigeModeUI.MSGS.PRESTIGE_MODE)
PrestigeModeUI.block1.title:SetPoint("TOP", 0, -16)

PrestigeModeUI.block1.step2 = PrestigeModeUI.block1:AddStepBlock()
PrestigeModeUI.block1.step2:SetPoint("TOP", PrestigeModeUI.block1.title, "BOTTOM", 0, -16)
PrestigeModeUI.block1.step2:SetText(PrestigeModeUI.MSGS.STEP_2_TEXT)
PrestigeModeUI.block1.step2.number:SetAtlas("services-number-2", Const.TextureKit.IgnoreAtlasSize)

PrestigeModeUI.block1.step1 = PrestigeModeUI.block1:AddStepBlock()
PrestigeModeUI.block1.step1:SetPoint("RIGHT", PrestigeModeUI.block1.step2.number, "LEFT", -120, 0)
PrestigeModeUI.block1.step1:SetText(string.format(PrestigeModeUI.MSGS.STEP_1_TEXT, PrestigeModeUI.MAX_LEVEL))
PrestigeModeUI.block1.step1.number:SetAtlas("services-number-1", Const.TextureKit.IgnoreAtlasSize)

PrestigeModeUI.block1.step3 = PrestigeModeUI.block1:AddStepBlock()
PrestigeModeUI.block1.step3:SetPoint("LEFT", PrestigeModeUI.block1.step2.number, "RIGHT", 120, 0)
PrestigeModeUI.block1.step3:SetText(string.format(PrestigeModeUI.MSGS.STEP_3_TEXT, PrestigeModeUI.MAX_LEVEL))
PrestigeModeUI.block1.step3.number:SetAtlas("services-number-3", Const.TextureKit.IgnoreAtlasSize)

PrestigeModeUI.block1.BGArt = PrestigeModeUI.block1:CreateTexture(nil, "BACKGROUND")
PrestigeModeUI.block1.BGArt:SetSize(530, 530)
PrestigeModeUI.block1.BGArt:SetTexture("Interface\\Prestige\\guys")
PrestigeModeUI.block1.BGArt:SetPoint("BOTTOM", 0, -100)
-------------------------------------------------------------------------------
--                       Right Panel. Requirements Block                     --
-------------------------------------------------------------------------------
PrestigeModeUI.block2 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.contentFrame)
PrestigeModeUI.block2:SetHeight(160)

PrestigeModeUI.block2.corner = PrestigeModeUI.block2:CreateTexture(nil, "BORDER")
PrestigeModeUI.block2.corner:SetTexture("Interface\\Prestige\\paper_corner", "MIRROR", "MIRROR")
PrestigeModeUI.block2.corner:SetHorizTile(true)
PrestigeModeUI.block2.corner:SetHeight(128)
PrestigeModeUI.block2.corner:SetWidth(PrestigeModeUI.block2:GetWidth())
PrestigeModeUI.block2.corner:SetPoint("TOPLEFT", 0, 58)

PrestigeModeUI.block2.title:SetText(PrestigeModeUI.MSGS.STEP_1)
PrestigeModeUI.block2.title:SetPoint("TOP", 0, -32)

PrestigeModeUI.block2.icon1 = PrestigeModeUI.block2:AddIconBlockShort("Interface\\Icons\\achievement_level_70", string.format(PrestigeModeUI.MSGS.REACH_LEVEL, PrestigeModeUI.MAX_LEVEL))
PrestigeModeUI.block2.icon1:SetPoint("TOPLEFT", PrestigeModeUI.block2.title, "BOTTOMLEFT", 32, -16)

if C_Player:IsHero() then
	PrestigeModeUI.block2.icon2 = PrestigeModeUI.block2:AddIconBlockShort("Interface\\Icons\\inv_inscription_tarot_6otankdeck", PrestigeModeUI.MSGS.NO_ACTIVE_HOF)
	PrestigeModeUI.block2.icon2:SetPoint("TOP", PrestigeModeUI.block2.icon1.icon, "BOTTOM", 0, -16)
	PrestigeModeUI.block2.icon2.fontString:SetWidth(400)
else
	PrestigeModeUI.block2:SetHeight(120)
end
-------------------------------------------------------------------------------
--                          Right Panel. Reset Block                         --
-------------------------------------------------------------------------------
PrestigeModeUI.block3 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.contentFrame)
PrestigeModeUI.block3:SetHeight(420)

PrestigeModeUI.block3.separator = PrestigeModeUI.block3:AddDividerTexture()
PrestigeModeUI.block3.separator:SetPoint("TOP", 0, 12)

PrestigeModeUI.block3.title:SetText(PrestigeModeUI.MSGS.RESET_TITLE)
PrestigeModeUI.block3.title:SetPoint("TOP", 0, -52)

-- what gonna reset
PrestigeModeUI.block3.block1 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.block3)
PrestigeModeUI.block3.block1:ClearAllPoints()
PrestigeModeUI.block3.block1:SetPoint("TOPLEFT", PrestigeModeUI.block3.title, "BOTTOMLEFT", 0, 0)
PrestigeModeUI.block3.block1:SetWidth(279)
PrestigeModeUI.block3.block1:SetHeight(176)
PrestigeModeUI.block3.block1:HideBG()

PrestigeModeUI.block3.block1.title:SetText(PrestigeModeUI.MSGS.RESET_SUBTITLE1)
PrestigeModeUI.block3.block1.title:SetPoint("TOP", 0, -16)

PrestigeModeUI.block3.block1.icon1 = PrestigeModeUI.block3.block1:AddIconBlockShort("Interface\\Icons\\achievement_quests_completed_06", QUESTS_LABEL)
PrestigeModeUI.block3.block1.icon1:SetPoint("TOPLEFT", PrestigeModeUI.block3.block1.title, "BOTTOMLEFT", 32, -16)

PrestigeModeUI.block3.block1.icon2 = PrestigeModeUI.block3.block1:AddIconBlockShort("Interface\\Icons\\Ability_Hunter_Pet_Chimera", PrestigeModeUI.MSGS.EXOTIC_PETS)
PrestigeModeUI.block3.block1.icon2:SetPoint("TOP", PrestigeModeUI.block3.block1.icon1.icon, "BOTTOM", 0, -16)

PrestigeModeUI.block3.block1.icon3 = PrestigeModeUI.block3.block1:AddIconBlockShort("Interface\\Icons\\spell_magic_greaterblessingofkings", BUFFOPTIONS_LABEL)
PrestigeModeUI.block3.block1.icon3:SetPoint("TOP", PrestigeModeUI.block3.block1.icon2.icon, "BOTTOM", 0, -16)

PrestigeModeUI.block3.block1.icon1.icon:SetVertexColor(1, 0, 0, 1)
PrestigeModeUI.block3.block1.icon2.icon:SetVertexColor(1, 0, 0, 1)
PrestigeModeUI.block3.block1.icon3.icon:SetVertexColor(1, 0, 0, 1)
-- what you will keep
PrestigeModeUI.block3.block2 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.block3)
PrestigeModeUI.block3.block2:ClearAllPoints()
PrestigeModeUI.block3.block2:SetPoint("TOPRIGHT", PrestigeModeUI.block3.title, "BOTTOMRIGHT", 0, 0)
PrestigeModeUI.block3.block2:SetWidth(279)
PrestigeModeUI.block3.block2:SetHeight(176)
PrestigeModeUI.block3.block2:HideBG()

PrestigeModeUI.block3.block2.title:SetText(PrestigeModeUI.MSGS.RESET_SUBTITLE2)
PrestigeModeUI.block3.block2.title:SetPoint("TOP", 0, -16)

PrestigeModeUI.block3.block2.icon1 = PrestigeModeUI.block3.block2:AddIconBlockShort("Interface\\Icons\\inv_misc_bag_08", ITEMS)
PrestigeModeUI.block3.block2.icon1:SetPoint("TOPLEFT", PrestigeModeUI.block3.block2.title, "BOTTOMLEFT", 32, -16)

PrestigeModeUI.block3.block2.icon2 = PrestigeModeUI.block3.block2:AddIconBlockShort("Interface\\Icons\\inv_misc_coin_01", GUILDCONTROL_OPTION16..", "..CURRENCY)
PrestigeModeUI.block3.block2.icon2:SetPoint("TOP", PrestigeModeUI.block3.block2.icon1.icon, "BOTTOM", 0, -16)

PrestigeModeUI.block3.block2.icon3 = PrestigeModeUI.block3.block2:AddIconBlockShort("Interface\\Icons\\achievement_reputation_01", REPUTATION)
PrestigeModeUI.block3.block2.icon3:SetPoint("TOP", PrestigeModeUI.block3.block2.icon2.icon, "BOTTOM", 0, -16)

-- reset block continue
PrestigeModeUI.block3.specLock = PrestigeModeUI.block3:AddIconBlockLong("Interface\\Icons\\INV_custom_spectome", PrestigeModeUI.MSGS.SPEC_LOCK, string.format(PrestigeModeUI.MSGS.SPEC_LOCK_TEXT, PrestigeModeUI.MAX_LEVEL))
PrestigeModeUI.block3.specLock.icon:SetPoint("TOPLEFT", PrestigeModeUI.block3.block1, "BOTTOMLEFT", 32, -32)

-- only in draft mode
if C_Player:IsHero() then
	PrestigeModeUI.block3.draftReset = PrestigeModeUI.block3:AddIconBlockLong("Interface\\Icons\\inv_misc_dmc_destructiondeck", PrestigeModeUI.MSGS.DRAFT_RESET, PrestigeModeUI.MSGS.DRAFT_RESET_TEXT)
	PrestigeModeUI.block3.draftReset.icon:SetPoint("TOPRIGHT", PrestigeModeUI.block3.specLock.fontString, "BOTTOMLEFT", -8, -16)
else
	PrestigeModeUI.block3:SetHeight(350)
end
-------------------------------------------------------------------------------
--                         Right Panel. Rewards Block                        --
-------------------------------------------------------------------------------
PrestigeModeUI.block4 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.contentFrame)
PrestigeModeUI.block4:SetHeight(307)

PrestigeModeUI.block4.separator = PrestigeModeUI.block4:AddDividerTexture()
PrestigeModeUI.block4.separator:SetPoint("TOP", 0, 12)

PrestigeModeUI.block4.title:SetText(PrestigeModeUI.MSGS.STEP_3)
PrestigeModeUI.block4.title:SetPoint("TOP", 0, -52)

PrestigeModeUI.block4.button = CreateFrame("Button", "$parent.button", PrestigeModeUI.block4, "RedButtonTemplate")
PrestigeModeUI.block4.button:SetPoint("TOP", PrestigeModeUI.block4.title, "BOTTOM", 0, -64)
PrestigeModeUI.block4.button:SetText(PrestigeModeUI.MSGS.CHECK_OUT_REWARDS)
PrestigeModeUI.block4.button:SetWidth(240)
PrestigeModeUI.block4.button:SetHeight(54)
PrestigeModeUI.block4.button.gossipOption = "REWARDS"

PrestigeModeUI.block4.fontString = PrestigeModeUI.block4:CreateFontString(nil, "OVERLAY")
PrestigeModeUI.block4.fontString:SetFontObject(GameFontNormal)
PrestigeModeUI.block4.fontString:SetPoint("TOP", PrestigeModeUI.block4.button, "BOTTOM", 0, -16)
PrestigeModeUI.block4.fontString:SetJustifyV("TOP")
PrestigeModeUI.block4.fontString:SetWidth(240)
PrestigeModeUI.block4.fontString:SetText(PrestigeModeUI.MSGS.TOKENS_OF_PRESTIGE)

PrestigeModeUI.block4.corner = PrestigeModeUI.block4:CreateTexture(nil, "BORDER")
PrestigeModeUI.block4.corner:SetTexture("Interface\\Prestige\\paper_corner", "MIRROR", "MIRROR")
PrestigeModeUI.block4.corner:SetHorizTile(true)
PrestigeModeUI.block4.corner:SetHeight(128)
PrestigeModeUI.block4.corner:SetWidth(PrestigeModeUI.block4:GetWidth())
PrestigeModeUI.block4.corner:SetPoint("BOTTOM", 0, -58)
PrestigeModeUI.block4.corner:SetTexCoord(1, 0, 1, 0)

PrestigeModeUI.block4.BGArt = PrestigeModeUI.block4:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.block4.BGArt:SetSize(350, 350)
PrestigeModeUI.block4.BGArt:SetTexture("Interface\\Prestige\\girl")
PrestigeModeUI.block4.BGArt:SetPoint("BOTTOMLEFT", -44, -52)
-------------------------------------------------------------------------------
--                        Right Panel. Activate Block                        --
-------------------------------------------------------------------------------
PrestigeModeUI.block5 = PrestigeModeUI:CreateTextBlock(PrestigeModeUI.contentFrame)
PrestigeModeUI.block5:HideBG()
PrestigeModeUI.block5:SetHeight(360)

PrestigeModeUI.block5.items = {}

function PrestigeModeUI.block5:CreateReward(name)
	local item = Addon.SharedGossip:CreateItemRing(name, self)
	item.icon:ClearAllPoints()
	item.icon:SetPoint("LEFT", 4, 0)

	item.total = item:CreateFontString(nil, "OVERLAY")
	item.total:SetFontObject(NumberFontNormal)
	item.total:SetPoint("BOTTOMRIGHT", item.icon, 0, -4)
	item.total:SetJustifyH("RIGHT")

	item.title:SetVertexColor(1, 1, 1, 1)
	item.title:ClearAllPoints()
	item.title:SetPoint("LEFT", item.icon, "RIGHT", 12, 0)
	item.title:SetFontObject(GameFontHighlightMedium)
	item.title:SetWidth(158)
	item.title:SetJustifyH("LEFT")

	item:SetWidth(224)

	item.icon:SetSize(38, 38)
	item.ring:SetSize(47, 47)
	item.glow:SetSize(106, 106)
	item.Highlight:SetSize(47, 47)

	function item:SetTotal(value)
		self.total:SetText(tostring(value))
	end

	table.insert(self.items, item)

	return item
end

PrestigeModeUI.block5.reward1 = PrestigeModeUI.block5:CreateReward("reward1")
PrestigeModeUI.block5.reward1:SetPoint("RIGHT", PrestigeModeUI.block5, "CENTER", -2, 64)

PrestigeModeUI.block5.reward2 = PrestigeModeUI.block5:CreateReward("reward2")
PrestigeModeUI.block5.reward2:SetPoint("LEFT", PrestigeModeUI.block5, "CENTER", 2, 64)

PrestigeModeUI.block5.reward3 = PrestigeModeUI.block5:CreateReward("reward3")
PrestigeModeUI.block5.reward3:SetPoint("TOP", PrestigeModeUI.block5.reward1, "BOTTOM", 0, -2)

PrestigeModeUI.block5.reward4 = PrestigeModeUI.block5:CreateReward("reward4")
PrestigeModeUI.block5.reward4:SetPoint("TOP", PrestigeModeUI.block5.reward2, "BOTTOM", 0, -2)

PrestigeModeUI.block5.reward5 = PrestigeModeUI.block5:CreateReward("reward5")
PrestigeModeUI.block5.reward5:SetPoint("TOP", PrestigeModeUI.block5.reward3, "BOTTOM", 0, -2)
PrestigeModeUI.block5.reward5.buybackHeader = PrestigeModeUI.block5.reward5:CreateFontString(nil, "OVERLAY")
PrestigeModeUI.block5.reward5.buybackHeader:SetFontObject(GameFontGreen)
PrestigeModeUI.block5.reward5.buybackHeader:SetPoint("BOTTOMLEFT", PrestigeModeUI.block5.reward5.title, "TOPLEFT", 0, 2)
PrestigeModeUI.block5.reward5.buybackHeader:SetText(REPURCHASEABLE)

PrestigeModeUI.block5.reward6 = PrestigeModeUI.block5:CreateReward("reward6")
PrestigeModeUI.block5.reward6:SetPoint("TOP", PrestigeModeUI.block5.reward4, "BOTTOM", 0, -2)
PrestigeModeUI.block5.reward6.buybackHeader = PrestigeModeUI.block5.reward6:CreateFontString(nil, "OVERLAY")
PrestigeModeUI.block5.reward6.buybackHeader:SetFontObject(GameFontGreen)
PrestigeModeUI.block5.reward6.buybackHeader:SetPoint("BOTTOMLEFT", PrestigeModeUI.block5.reward6.title, "TOPLEFT", 0, 2)
PrestigeModeUI.block5.reward6.buybackHeader:SetText(REPURCHASEABLE)

PrestigeModeUI.block5.subtitle = PrestigeModeUI.block5:CreateFontString(nil)
PrestigeModeUI.block5.subtitle:SetFontObject(GameFontNormal)
PrestigeModeUI.block5.subtitle:SetPoint("TOP", PrestigeModeUI.block5.title, "BOTTOM", 0, -4)
PrestigeModeUI.block5.subtitle:SetText(PrestigeModeUI.MSGS.PRESTIGE_REWARDS)

PrestigeModeUI.block5.title:SetText(PrestigeModeUI.MSGS.ACTIVATION_TEXT)
PrestigeModeUI.block5.title:SetPoint("TOP", 0, -32)

PrestigeModeUI.block5.button = CreateFrame("Button", "$parent.button", PrestigeModeUI.block5, "RedButtonTemplate")
PrestigeModeUI.block5.button:SetPoint("TOP", PrestigeModeUI.block5.reward5, "BOTTOM", -16, -18)
PrestigeModeUI.block5.button:SetText(PrestigeModeUI.MSGS.RESET_SPEC)
PrestigeModeUI.block5.button:SetWidth(240)
PrestigeModeUI.block5.button:SetHeight(54)
PrestigeModeUI.block5.button.gossipOption = "ACTIVATE"

PrestigeModeUI.block5.buttonBuyExp = CreateFrame("Button", "$parent.buttonBuyExp", PrestigeModeUI.block5, "RedButtonTemplate")
PrestigeModeUI.block5.buttonBuyExp:SetPoint("TOP", PrestigeModeUI.block5.reward6, "BOTTOM", 16, -18)
PrestigeModeUI.block5.buttonBuyExp:SetText(PrestigeModeUI.MSGS.BUY_EXP)
PrestigeModeUI.block5.buttonBuyExp:SetWidth(240)
PrestigeModeUI.block5.buttonBuyExp:SetHeight(54)
PrestigeModeUI.block5.buttonBuyExp.gossipOption = "BUY_EXP"
PrestigeModeUI.block5.buttonBuyExp:SetScript("OnClick", PrestigeModeUI.ClickGossipOption)

PrestigeModeUI.block5.button.errorText = PrestigeModeUI.block5.button:CreateFontString(nil)
PrestigeModeUI.block5.button.errorText:SetFontObject(GameFontHighlightMedium)
PrestigeModeUI.block5.button.errorText:SetPoint("TOP", PrestigeModeUI.block5.button, "BOTTOM", 120, -5)
PrestigeModeUI.block5.button.errorText:SetJustifyH("CENTER")
PrestigeModeUI.block5.button.errorText:SetJustifyV("TOP")
PrestigeModeUI.block5.button.errorText:SetText("Example text")
PrestigeModeUI.block5.button.errorText:SetVertexColor(1, 0, 0, 1)

PrestigeModeUI.block5.button.unlockSpecButton = CreateFrame("BUTTON", "$parent.unlockSpecButton", PrestigeModeUI.block5.button, "RefreshButtonTemplate")
PrestigeModeUI.block5.button.unlockSpecButton.Icon:SetAtlas("spell-list-unlocked", Const.TextureKit.IgnoreAtlasSize)

PrestigeModeUI.block5.button.unlockSpecButton.text = PrestigeModeUI.block5.button.unlockSpecButton:CreateFontString(nil)
PrestigeModeUI.block5.button.unlockSpecButton.text:SetFontObject(GameFontNormal)
PrestigeModeUI.block5.button.unlockSpecButton.text:SetJustifyH("LEFT")
PrestigeModeUI.block5.button.unlockSpecButton.text:SetPoint("LEFT", PrestigeModeUI.block5.button.unlockSpecButton, "RIGHT", 4, 0)
PrestigeModeUI.block5.button.unlockSpecButton:SetFontString(PrestigeModeUI.block5.button.unlockSpecButton.text)

PrestigeModeUI.block5.button.unlockSpecButton:SetNormalFontObject(GameFontNormal)
PrestigeModeUI.block5.button.unlockSpecButton:SetHighlightFontObject(GameFontHighlight)
PrestigeModeUI.block5.button.unlockSpecButton:SetDisabledFontObject(GameFontDisable)
PrestigeModeUI.block5.button.unlockSpecButton:SetPushedTextOffset(1, -2)
PrestigeModeUI.block5.button.unlockSpecButton:Hide()

PrestigeModeUI.block5.button.unlockSpecButton:SetPoint("TOPLEFT", PrestigeModeUI.block5.button, "BOTTOMLEFT", 120, -20)
PrestigeModeUI.block5.button.unlockSpecButton:SetText(PrestigeModeUI.MSGS.UNLOCK_CURRENT_SPEC)
PrestigeModeUI.block5.button.unlockSpecButton:SetScript("OnClick", function()
	if Collections then
		Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
	end

	if (CharacterAdvancement) then
		CharacterAdvancement.SideBar:SelectTabID(CharacterAdvancement.SideBar.SpecTab)
	end
end)

PrestigeModeUI.block5.BGArt = PrestigeModeUI.block5:CreateTexture(nil, "BACKGROUND")
PrestigeModeUI.block5.BGArt:SetSize(800, 400)
PrestigeModeUI.block5.BGArt:SetTexture("Interface\\Prestige\\prestige_art")
PrestigeModeUI.block5.BGArt:SetPoint("BOTTOM", 0, 0)

-------------------------------------------------------------------------------
--                                 Spec Block                                --
-------------------------------------------------------------------------------
PrestigeModeUI.specFrame = CreateFrame("FRAME", "PrestigeModeUI.specFrame", PrestigeModeUI, nil)
PrestigeModeUI.specFrame:SetSize(800, 48)
PrestigeModeUI.specFrame:SetPoint("BOTTOM", PrestigeModeUI.scroll, "TOP", 0, 0)

PrestigeModeUI.specFrame.specName = PrestigeModeUI.specFrame:CreateFontString(nil)
PrestigeModeUI.specFrame.specName:SetFontObject(GameFontHighlightLarge)
PrestigeModeUI.specFrame.specName:SetPoint("CENTER", 0, -5)
PrestigeModeUI.specFrame.specName:SetJustifyH("CENTER")
PrestigeModeUI.specFrame.specName:SetText("Specialization I")

PrestigeModeUI.specFrame.subHeader = PrestigeModeUI.specFrame:CreateFontString(nil)
PrestigeModeUI.specFrame.subHeader:SetFontObject(GameFontNormal)
PrestigeModeUI.specFrame.subHeader:SetPoint("BOTTOM", PrestigeModeUI.specFrame.specName, "TOP", 0, 0)
PrestigeModeUI.specFrame.subHeader:SetJustifyV("BOTTOM")
PrestigeModeUI.specFrame.subHeader:SetText(ACTIVE_SPECIALIZATION)

PrestigeModeUI.specFrame.Icon = PrestigeModeUI.specFrame:CreateTexture(nil, "ARTWORK")
PrestigeModeUI.specFrame.Icon:SetTexture("Interface\\Icons\\inv_misc_book_16")
PrestigeModeUI.specFrame.Icon:SetSize(36,36)
PrestigeModeUI.specFrame.Icon:SetPoint("RIGHT", PrestigeModeUI.specFrame.specName, "LEFT", -32, 4)

PrestigeModeUI.specFrame.KnownBorder = PrestigeModeUI.specFrame:CreateTexture(nil, "OVERLAY")
PrestigeModeUI.specFrame.KnownBorder:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\Known_Highlight")
PrestigeModeUI.specFrame.KnownBorder:SetSize(80,80)
PrestigeModeUI.specFrame.KnownBorder:SetPoint("CENTER", PrestigeModeUI.specFrame.Icon, 0, 0)
PrestigeModeUI.specFrame.KnownBorder:SetBlendMode("ADD")

PrestigeModeUI.specFrame.Slot = PrestigeModeUI.specFrame:CreateTexture(nil, "BORDER")
PrestigeModeUI.specFrame.Slot:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
PrestigeModeUI.specFrame.Slot:SetSize(45,45)
PrestigeModeUI.specFrame.Slot:SetPoint("CENTER", PrestigeModeUI.specFrame.Icon, 0, 0)
PrestigeModeUI.specFrame.Slot:SetTexCoord(0.140625, 0.84375, 0.140625, 0.84375)
PrestigeModeUI.specFrame.Slot:SetBlendMode("ADD")

PrestigeModeUI.specFrame.prestigeLevel = PrestigeModeUI.specFrame:CreateFontString(nil)
PrestigeModeUI.specFrame.prestigeLevel:SetFontObject(GameFontNormal)
PrestigeModeUI.specFrame.prestigeLevel:SetPoint("TOPLEFT", 72, -12)
PrestigeModeUI.specFrame.prestigeLevel:SetFormattedText(STAT_FORMAT, PRESTIGE_LEVEL_LABEL)

PrestigeModeUI.specFrame.accountPrestigeLevel = PrestigeModeUI.specFrame:CreateFontString(nil)
PrestigeModeUI.specFrame.accountPrestigeLevel:SetFontObject(GameFontNormal)
PrestigeModeUI.specFrame.accountPrestigeLevel:SetPoint("TOPLEFT", PrestigeModeUI.specFrame.prestigeLevel, "BOTTOMLEFT", 0, -1)
PrestigeModeUI.specFrame.accountPrestigeLevel:SetFormattedText(STAT_FORMAT, ACCOUNT_PRESTIGE_LEVEL_LABEL)
-------------------------------------------------------------------------------
--                                 Rest of UI                                --
-------------------------------------------------------------------------------
PrestigeModeUI.block5.button:SetScript("OnClick", function(self)
	if (self:IsEnabled() ~= 0) then
		local name = SpecializationUtil.GetCurrentSpecializationInfo()
		local text1 = C_GameMode:IsGameModeActive(Enum.GameMode.Draft) and PrestigeModeUI.MSGS.POPUP_CLEAR_HOF_STEP_1 or PrestigeModeUI.MSGS.POPUP_CLEAR_HOF_STEP_1_SOF
		local text2 = C_GameMode:IsGameModeActive(Enum.GameMode.Draft) and string.format(PrestigeModeUI.MSGS.POPUP_CLEAR_HOF_STEP_2, name) or string.format(PrestigeModeUI.MSGS.POPUP_CLEAR_HOF_STEP_2_SOF, name)

		StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_2"].OnAccept = function() PrestigeModeUI.ClickGossipOption(self) end
		StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_1"].text = text1 .. "|n|n" .. text2
		StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_2"].text = PrestigeModeUI.MSGS.POPUP_TEXT_STEP_1 .. "|n|n" .. PrestigeModeUI.MSGS.POPUP_TEXT_STEP_2
		
		if C_Player:IsHero() then
			StaticPopup_Show("ASC_PRESTIGE_ACTIVATION_1")
		else
			StaticPopup_Show("ASC_PRESTIGE_ACTIVATION_2")
		end
	end
end)

PrestigeModeUI.block4.button:SetScript("OnClick", PrestigeModeUI.ClickGossipOption)

PrestigeModeUI:SetScript("OnHide", function()
	CloseGossip()
	StaticPopup_Hide("ASC_PRESTIGE_ACTIVATION_1")
	StaticPopup_Hide("ASC_PRESTIGE_ACTIVATION_2")
end)

PrestigeModeUI:SetScript("OnShow", function(self)
	if not(self.init) then
		self.init = true

		-- fix range
		local _, y_range = self.scroll.ScrollBar:GetMinMaxValues()
		if not(y_range) or (y_range == 0) then
			if C_Player:IsHero() then
				y_range = 1321
			else
				y_range = 1211
			end
		end
		self.scroll.ScrollBar:SetMinMaxValues(0, y_range-32)

		-- scroll down and play animation
		self.scroll:SetValue(9999)
		self.scroll.ScrollBar:Disable()
		Timer.After(1, function()
			self.scroll.targetY = 0
			Timer.After(2, function()
				self.scroll.ScrollBar:Enable()
		    end)
		end)
	end

	local maxLevel = GetMaxLevel()

	PrestigeModeUI.QUEST_REWARDS[maxLevel][5] = nil
	PrestigeModeUI.QUEST_REWARDS[maxLevel][6] = nil
	-- setup buyback scrolls
	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		local buybackScrolls, buybackAbilityScrolls, buybackTalentScrolls = GetWildcardPrestigeInfo()
		local index = 5 -- buyback scroll starting index
		if buybackScrolls and buybackScrolls > 0 then
			PrestigeModeUI.QUEST_REWARDS[maxLevel][index] = { itemID = CostUtil:GetScrollOfFortuneForSpec(), amount = "+" .. buybackScrolls }
			index = index + 1
		end

		if buybackTalentScrolls and buybackTalentScrolls > 0 then
			PrestigeModeUI.QUEST_REWARDS[maxLevel][index] = { itemID = CostUtil:GetScrollOfFortuneTalentsForSpec(), amount = "+" .. buybackTalentScrolls }
		end
	end

	-- load proper max level
	for i = 1, #self.block5.items do
		local item = self.block5.items[i]

		if self.QUEST_REWARDS[maxLevel][i] then
			item:Show()
			item:SetItem(self.QUEST_REWARDS[maxLevel][i].itemID)
			item:SetTotal(self.QUEST_REWARDS[maxLevel][i].amount)
		else
			item:Hide()
		end
	end

	PrestigeModeUI.Tabs.tokenString:SetText(GetItemCount(self.CURRENCY))
end)

function PrestigeModeUI:SetUpQuest(quest)
	PrestigeModeUI.Tabs.dailyQuest.text:SetText(string.format(self.MSGS.DAILY_QUEST, quest))
	PrestigeModeUI.Tabs.dailyQuest.tooltipText = string.format(self.MSGS.DAILY_QUEST_TEXT, quest)
end

function PrestigeModeUI:UpdateSpecialization()
	local name, icon, _, _, isPrestigeLocked = SpecializationUtil.GetCurrentSpecializationInfo()

    self.specFrame.specName:SetText(name)
    self.MSGS.POPUP_TEXT_STEP_2 = string.format(self.MSGS.POPUP_TEXT_STEP_2_BLANK, icon, name)
    self.block5.button:SetText(string.format(self.MSGS.RESET_SPEC, name))
    self.specFrame.Icon:SetTexture(icon)
	
	local prestigeLevel, accountPrestigeLevel = GetPrestigeLevel()
	self.specFrame.prestigeLevel:SetText(string.format(STAT_FORMAT, PRESTIGE_LEVEL_LABEL) .. " " .. HIGHLIGHT_FONT_COLOR:WrapText(prestigeLevel))
	self.specFrame.accountPrestigeLevel:SetText(string.format(STAT_FORMAT, ACCOUNT_PRESTIGE_LEVEL_LABEL) .. " " .. HIGHLIGHT_FONT_COLOR:WrapText(accountPrestigeLevel))

    self.isPrestigeLocked = isPrestigeLocked
end

function PrestigeModeUI:HasHoF()
	return (GetItemCount(CostUtil:GetHandOfFateForSpec(SpecializationUtil.GetActiveSpecialization())) > 0) or HasHandOfFatePick() or (GetHandOfFatePickSpellAtIndex(0) ~= 0) or HasHandOfFateSacrificePick() or (GetHandOfFateSacrificePickSpellAtIndex(0) ~= 0)
end

function PrestigeModeUI:HasCaseOfFortune()
	local specID = SpecializationUtil.GetActiveSpecialization()
	local talentSoF = CostUtil:GetScrollOfFortuneTalentsForSpec(specID)
	local abilitiesSof = CostUtil:GetScrollOfFortuneAbilitiesForSpec(specID)
	local SoF = CostUtil:GetScrollOfFortuneForSpec(specID)

	if GetItemCount(talentSoF) > 0 or GetItemCount(abilitiesSof) > 0 or GetItemCount(SoF) > 0 then
		return "Scrolls of Fortune"
	end

	if GetTokenCount(TokenUtil.GetScrollOfFortuneAbilitiesForSpec()) > 0 or GetTokenCount(TokenUtil.GetScrollOfFortuneTalentsForSpec()) > 0 or GetTokenCount(TokenUtil.GetScrollOfFortuneForSpec()) > 0 then
		return "Scrolls of Fortune"
	end

	if GetItemCount(ItemData.CASE_OF_FORTUNE_TALENTS) > 0 or GetItemCount(ItemData.CASE_OF_FORTUNE_ABILITIES) > 0 then
		return "Cases of Fortune"
	end

	if GetItemCount(ItemData.ITEM_LEVELING_CASE_OF_FORTUNE_TALENTS) > 0 or GetItemCount(ItemData.ITEM_LEVELING_CASE_OF_FORTUNE) > 0 then
		return "Cases of Fortune"
	end

	if GetItemCount(ItemData.ITEM_LEGACY_CASE_OF_FORTUNE_TALENTS) > 0 or GetItemCount(ItemData.ITEM_LEGACY_CASE_OF_FORTUNE) > 0 then
		return "Cases of Fortune"
	end

	if GetItemCount(ItemData.ITEM_LEGACY_CASE_OF_FORTUNE_TALENTS) > 0 or GetItemCount(ItemData.ITEM_LEGACY_CASE_OF_FORTUNE) > 0 then
		return "Cases of Fortune"
	end

	if GetItemCount(BONUS_MANASTORM_CACHE) > 0 or GetItemCount(ItemData.BONUS_MANASTORM_CACHE_2) > 0 then
		return "Bonus Manastorm Caches"
	end
end

function PrestigeModeUI:UpdateActivateButton()
	local option = self.gossipOptions.ACTIVATE
	local success = true

	StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_2"].OnAccept = nil
	self.block5.button.errorText:SetText("Internal Error")
	self.block5.button.unlockSpecButton:Hide()

	if (UnitLevel("player") < self.MAX_LEVEL) then
		self.block5.button.errorText:SetText(string.format(self.MSGS.ERROR_LEVEL, self.MAX_LEVEL))
		self.block5.button:Disable()
		self.block2.icon1:SetText(string.format(self.MSGS.REACH_LEVEL, self.MAX_LEVEL).." |cffFF0000("..INCOMPLETE..")|r")
		success = false
	elseif self.isPrestigeLocked and not(C_Player:IsCustomClass()) then
		self.block5.button.errorText:SetText(self.MSGS.ERROR_SPEC_LOCKED)
		self.block5.button:Disable()
		self.block5.button.unlockSpecButton:Show()
		success = false
	else
		self.block2.icon1:SetText(string.format(self.MSGS.REACH_LEVEL, self.MAX_LEVEL).." |cff00FF00("..COMPLETE..")|r")
	end

	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
		PrestigeModeUI.block2.icon2:SetIcon("Interface\\Icons\\trade_archaeology_apexisscroll")
		PrestigeModeUI.block2.icon2:SetText(PrestigeModeUI.MSGS.NO_ACTIVE_COF)
		PrestigeModeUI.block3.draftReset:SetIcon("Interface\\Icons\\misc_rune_pvp_random")
		PrestigeModeUI.block3.draftReset:SetTitle(PrestigeModeUI.MSGS.WILDCARD_RESET)
		PrestigeModeUI.block3.draftReset:SetText(PrestigeModeUI.MSGS.WILDCARD_RESET_TEXT)

	elseif C_GameMode:IsGameModeActive(Enum.GameMode.Draft) then
		PrestigeModeUI.block2.icon2:SetIcon("Interface\\Icons\\inv_inscription_tarot_6otankdeck")
		PrestigeModeUI.block2.icon2:SetText(PrestigeModeUI.MSGS.NO_ACTIVE_HOF)
		PrestigeModeUI.block3.draftReset:SetIcon("Interface\\Icons\\inv_misc_dmc_destructiondeck")
		PrestigeModeUI.block3.draftReset:SetTitle(PrestigeModeUI.MSGS.DRAFT_RESET)
		PrestigeModeUI.block3.draftReset:SetText(PrestigeModeUI.MSGS.DRAFT_RESET_TEXT)
	end

	if not(option) or (option == 0) or not(success) then
		self.block5.button:Disable()
		return
	end

	self.block5.button.errorText:SetText("")

	self.block5.button:Enable()
	StaticPopupDialogs["ASC_PRESTIGE_ACTIVATION_2"].OnAccept = function (self)
		SelectGossipOption(option)
	end

end

--[[function PrestigeModeUI:UpdateContractsButton()
	if (self.gossipOptions.CONTRACTS) and (self.gossipOptions.CONTRACTS ~= 0) then
		PrestigeModeUI.Tabs.tabTemporalContracts:Enable()
	else
		PrestigeModeUI.Tabs.tabTemporalContracts:Disable()
	end
end]]--

function PrestigeModeUI:UpdateBuyExpButton()
	if (self.gossipOptions.BUY_EXP) and (self.gossipOptions.BUY_EXP ~= 0) then
		PrestigeModeUI.Tabs.tabBuyExp:Enable()
		PrestigeModeUI.block5.buttonBuyExp:Enable()
	else
		PrestigeModeUI.block5.buttonBuyExp:Disable()
		PrestigeModeUI.Tabs.tabBuyExp:Disable()
	end
end

function PrestigeModeUI:ScanGossipOptions(...)
	self.gossipOptions = {
		ACTIVATE 	= 0,
		REWARDS 	= 0,
		CONTRACTS 	= 0,
		CLEAR_HOF 	= 0,
	}

	local buttonIndex = 1

	for i=1, select("#", ...), 2 do
		local text = select(i, ...)

		local quest = string.match(text, self.MSGS.GOSSIP_CURRENT_QUEST)

		if (quest) then
			self:SetUpQuest(quest)
		elseif (text == self.MSGS.GOSSIP_OPTION_REWARDS) then
			self.gossipOptions.REWARDS = buttonIndex
		elseif (text == self.MSGS.GOSSIP_OPTION_CONTRACTS) then
			self.gossipOptions.CONTRACTS = buttonIndex
		elseif (text == self.MSGS.GOSSIP_OPTION_PRESTIGE) then
			self.gossipOptions.ACTIVATE = buttonIndex
		elseif (text == self.MSGS.GOSSIP_OPTION_BUY_EXP) then
			self.gossipOptions.BUY_EXP = buttonIndex
		end

		buttonIndex = buttonIndex + 1
	end

	self:UpdateBuyExpButton()
	--self:UpdateContractsButton()
	self:UpdateSpecialization()
	self:UpdateActivateButton()
end

function PrestigeModeUI:ScanActiveQuests(...) -- TODO: To GossipShared
	self.Tabs.tabPrestigeDescription:ClearAllPoints()
	self.Tabs.tabPrestigeDescription:SetPoint("TOP", 0, -8)

	for i = 1, #self.availableQuestButtons do
		self.availableQuestButtons[i]:Hide()
		self.availableQuestButtons[i].ID = 0
	end

	local name, isTrivial, isDaily, isRepeatable, uiButton
	local buttonIndex = 1

	for i=1, select("#", ...), 5 do
		if (buttonIndex > self.MAX_AVAILABLE_QUESTS) then
			return
		end

		uiButton = self.availableQuestButtons[buttonIndex]
		uiButton:Show()

		self.Tabs.tabPrestigeDescription:ClearAllPoints()
		self.Tabs.tabPrestigeDescription:SetPoint("TOP", uiButton, "BOTTOM", 0, -8)

		name = select(i, ...)

		uiButton.tooltipTitle = name
		uiButton.text:SetText(name)
		uiButton.ID = buttonIndex

		buttonIndex = buttonIndex + 1
	end

end

function PrestigeModeUI:OnGossipShow()
	C_Gossip:SilentHideGossip()
	ShowUIPanel(PrestigeModeUI)
	PrestigeModeUI:ScanGossipOptions(GetGossipOptions())
	PrestigeModeUI:ScanActiveQuests(GetGossipActiveQuests())
end

function PrestigeModeUI:OnGossipHide()
	C_Gossip:RestoreGossip()
	HideUIPanel(PrestigeModeUI)
end

C_Gossip:RedirectNPC(PrestigeModeUI.NPC, PrestigeModeUI.OnGossipShow, PrestigeModeUI.OnGossipHide)

-- TODO: Move to UIParent
UIPanelWindows["PrestigeModeUI"] = { area = "center", pushable = 0, whileDead = 1, allowOtherPanels = true, dontCloseForNonCenterPanels = true }
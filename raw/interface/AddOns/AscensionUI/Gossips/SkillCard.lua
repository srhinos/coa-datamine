local Addon = select(2, ...)
local SkillCardExchangeUI = Addon.SharedGossip:CreateGossipFrame("SkillCardExchangeUI")
Addon.SkillCardExchangeUI = SkillCardExchangeUI
SkillCardExchangeUI:Hide()

SkillCardExchangeUI.hooks = {
	{
		event = "BAG_UPDATE",
		triggerOnShow = true,
	},
	{
		event = "GOSSIP_CONFIRM_CANCEL",
		triggerOnShow = false,
	},
}

SkillCardExchangeUI.TOTAL_TO_EXCHANGE 						= 5

SkillCardExchangeUI.TRIGGER_ANIM_LOOT = {
	[777997] = true, -- SEALED_CARD
	[778999] = true, -- GOLDEN_SEALED_CARD
	[97395] = true, -- LUCKY_SEALED_CARD
	[97396] = true, -- GOLDEN_LUCKY_SEALED_CARD
}

SkillCardExchangeUI.MSGS = {
	EXCHANGE_RATES_TEXT 									= "5x |cffFFFFFFCommon|r = |cffFFFFFF1 Card|r\n5x |cff1eff00Uncommon|r = |cffFFFFFF1 Card|r\n|cff0070ddRare|r = |cffFFFFFF1 Card|r\n|cffa335eeEpic|r = |cffFFFFFF5 Cards|r\n|cffff8000Legendary|r = |cffFFFFFF25 Cards|r",
	CARD_EXCHANGE_TITLE										= "Skill Cards",
	CARD_EXCHANGE_TEXT										= "Exchange your left over Skills Cards for new Sealed Packs!",
	GOLD_CARD_EXCHANGE_TITLE								= "Golden Skill Cards",
	GOLD_CARD_EXCHANGE_TEXT									= "Exchange your leftover Golden Skill Cards for new Golden sealed packs!",
	CARD_EXCHANGE_TITLE_LUCKY								= "Lucky Cards",
	CARD_EXCHANGE_TEXT_LUCKY								= "Exchange your left over Lucky Skill Cards for new Sealed Packs!",
	GOLD_CARD_EXCHANGE_TITLE_LUCKY							= "Golden Lucky Cards",
	GOLD_CARD_EXCHANGE_TEXT_LUCKY							= "Exchange your leftover Golden Lucky Skill Cards for new Golden Sealed Packs!",
	BOOSTER_TITLE 											= "Golden Skill Cards",
	BOOSTER_TEXT 											= "Get new Golden Sealed Packs for gold!",
	BUYBACK_TITLE											= "Buyback Cards",
	BUYBACK_TEXT 											= "Accidently exchange a Skillcard you needed? You can purchase that skillcard back here for gold!",
	EXCHANGE_TITLE_NORMAL 								    = "Skill Card Exchange",
	EXCHANGE_TITLE_NORMAL_LUCKY 							= "Lucky Card Exchange",
	EXCHANGE_SUBTITLE_NORMAL 								= "Exchange 5 Skill Cards to Sealed Cards",
	EXCHANGE_SUBTITLE_NORMAL_LUCKY 							= "Exchange 5 Lucky Cards to Lucky Sealed Cards",
	EXCHANGE_TITLE_GOLDEN 								    = "Golden Skill Card Exchange",
	EXCHANGE_TITLE_GOLDEN_LUCKY 						    = "Golden Lucky Card Exchange",
	EXCHANGE_SUBTITLE_GOLDEN 								= "Exchange 5 Golden Skill Cards to Lucky Sealed Cards",
	EXCHANGE_SUBTITLE_GOLDEN_LUCKY 							= "Exchange 5 Golden Lucky Cards to Lucky Sealed Cards",
	ERROR_EXCHANGE_NORMAL									= "Requires at least 5 Skill Cards in your inventory (%d/5)",
	ERROR_EXCHANGE_GOLDEN									= "Requires at least 5 Golden Skill Cards in your inventory (%d/5)",
	ERROR_EXCHANGE_NORMAL_LUCKY								= "Requires at least 5 Lucky Cards in your inventory (%d/5)",
	ERROR_EXCHANGE_GOLDEN_LUCKY								= "Requires at least 5 Golden Lucky Cards in your inventory (%d/5)",
	BUTTON_NORMAL_TEXT										= "Exchange 5 Skill Cards\nto Sealed Cards",
	BUTTON_GOLDEN_TEXT 										= "Exchange 5 Golden\nSkill Cards to Sealed Cards",
	BUTTON_NORMAL_TEXT_LUCKY								= "Exchange 5 Lucky Cards\nto Lucky Sealed Cards",
	BUTTON_GOLDEN_TEXT_LUCKY 								= "Exchange 5 Golden\nLucky Cards to Lucky Sealed Cards",
	CONFIRM_DIALOGUE_NORMAL 								= "Are you sure that you want to exchange 5 Skill Cards you have to Sealed Cards?\n\nHigher quality skill cards grant more Sealed Cards!\n\n|cffE73017You will recycle 5 random skill cards from your inventory when you press accept.|r",
	CONFIRM_DIALOGUE_GOLD 									= "Are you sure that you want to exchange 5 Golden Skill Cards you have to Golden Sealed Cards?\n\nHigher quality skill cards grant more Sealed Cards!\n\n|cffE73017You will recycle 5 random golden skill cards from your inventory when you press accept.|r",
	CONFIRM_DIALOGUE_NORMAL_LUCKY 							= "Are you sure that you want to exchange 5 Lucky Skill Cards you have to Sealed Cards?\n\nHigher quality skill cards grant more Sealed Cards!\n\n|cffE73017You will recycle 5 random skill cards from your inventory when you press accept.|r",
	CONFIRM_DIALOGUE_GOLD_LUCKY 							= "Are you sure that you want to exchange 5 Skill Cards you have to Sealed Cards?\n\nHigher quality skill cards grant more Sealed Cards!\n\n|cffE73017You will recycle 5 random golden skill cards from your inventory when you press accept.|r",
}

SkillCardExchangeUI.gossipOptions = {
	SKILL_CARD_EXCHANGE 									= 0,
	GOLDEN_CARD_EXCHANGE 									= 0,
	LUCKY_CARD_EXCHANGE 									= 0,
	LUCKY_GOLD_CARD_EXCHANGE 								= 0,
	BOOSTER													= 0,
	BUYBACK 												= 0,
	BUYBACK_ITEM_1											= 0,
	BUYBACK_ITEM_2											= 0,
	BUYBACK_ITEM_3											= 0,
	BUYBACK_ITEM_4											= 0,
	BUYBACK_ITEM_5											= 0,
	BUYBACK_ITEM_6											= 0,
	BUYBACK_ITEM_7											= 0,
	BUYBACK_ITEM_8											= 0,
	BUYBACK_ITEM_9											= 0,
	BUYBACK_ITEM_10											= 0,
	NEXT_PAGE												= 0,
	PREV_PAGE												= 0,
	BACK 													= 0,
}

SkillCardExchangeUI.buyBack_Gossip_text						= "^(%d+):(%d+)$"

SkillCardExchangeUI.internalGossipOptions = {
	["exchange: 5 cards to sealed cards"] 					= "SKILL_CARD_EXCHANGE",
	["golden: 5 cards to sealed cards"] 					= "GOLDEN_CARD_EXCHANGE",
	["exchange: 5 lucky cards to lucky sealed cards"]		= "LUCKY_CARD_EXCHANGE",
	["golden: 5 lucky cards to lucky sealed cards"]			= "LUCKY_GOLD_CARD_EXCHANGE",
	["golden skill cards"]									= "BOOSTER",
	["skill card buyback"]									= "BUYBACK",
	["next page"]											= "NEXT_PAGE",
	["previous page"]										= "PREV_PAGE",
	["back"]												= "BACK",
}

SkillCardExchangeUI.menus = {
	["EXCHANGE"]											= nil,
	["BUYBACK"]											    = nil,
}

SkillCardExchangeUI.MAX_ITEMS								= 10
SkillCardExchangeUI.totalItems 								= 0 -- used for buyback
SkillCardExchangeUI.isOnBagUpdate 							= false -- to prevent spam from BAG_UPDATE

SkillCardExchangeUI.skipConfirmNormal 						= false 

local ExchangeCVarBits = {
	Normal = 1,
	Gold = 2,
	LuckyNormal = 3,
	LuckyGold = 4,
}

StaticPopupDialogs["ASC_SKILLCARD_EXCHANGE_CONFIRM"] = {
    text = "",
    button1 = "Okay",
    button2 = "Cancel",
    whileDead = true,
    timeout = 0,
    hideOnEscape = true,
}
-------------------------------------------------------------------------------
--                                  Scripts                                  --
-------------------------------------------------------------------------------
function SkillCardExchangeUI.ClickExchangeButton(self)
	if self:IsEnabled() ~= 1 then return end

	if (self.skipConfirm:GetChecked()) then
		SkillCardExchangeUI:ClickGossipOption(self)
	else
		StaticPopupDialogs["ASC_SKILLCARD_EXCHANGE_CONFIRM"].text = self.confirmationText
		StaticPopupDialogs["ASC_SKILLCARD_EXCHANGE_CONFIRM"].OnAccept = function() SkillCardExchangeUI:ClickGossipOption(self) end
		StaticPopup_Show("ASC_SKILLCARD_EXCHANGE_CONFIRM")
	end
end

function SkillCardExchangeUI:HandleConfirmationBool(cvar, bit, btn)
	local result = C_CVar.GetBitfield(cvar, bit)
	btn:SetChecked(result)
	--return result
end

function SkillCardExchangeUI.HandleCVars()
	SkillCardExchangeUI:HandleConfirmationBool("SkillCardExchangeSkip", ExchangeCVarBits.Normal, SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm)
	SkillCardExchangeUI:HandleConfirmationBool("SkillCardExchangeSkip", ExchangeCVarBits.Gold, SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm)
	SkillCardExchangeUI:HandleConfirmationBool("SkillCardExchangeSkip", ExchangeCVarBits.LuckyNormal, SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm)
	SkillCardExchangeUI:HandleConfirmationBool("SkillCardExchangeSkip", ExchangeCVarBits.LuckyGold, SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm)
end

function SkillCardExchangeUI.CHAT_MSG_LOOT(_, msg)
	local itemID = tonumber(string.match(msg, "item:(%d+)"))
	if (SkillCardExchangeUI.TRIGGER_ANIM_LOOT[itemID]) then
		SkillCardExchangeUI.content.exchange.magic:PlaySplash()
		C_Hook:Unregister(SkillCardExchangeUI, "CHAT_MSG_LOOT")
	end
end

function SkillCardExchangeUI.GOSSIP_CONFIRM_CANCEL()
	C_Hook:Register(SkillCardExchangeUI, "CHAT_MSG_LOOT")
end

function SkillCardExchangeUI:HasEnoughCards(isGolden, isLucky) 
	local cards = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
			if link then
				local itemID = tonumber(string.match(link, "item:(%d+)"))
				local card = nil

				if (isLucky) then
					card = GetLuckyCard(itemID)
				else
					card = GetSkillCard(itemID)
				end

				if ( itemID and card ) then
					if (isGolden and card.isGolden) then
						cards = cards + count
					elseif (not(isGolden) and not(card.isGolden)) then
						cards = cards + count
					end
				end
			end
		end
	end

	return cards >= self.TOTAL_TO_EXCHANGE, cards
end

function SkillCardExchangeUI:ScanCards(isGolden, isLucky)
	local enough, total = SkillCardExchangeUI:HasEnoughCards(isGolden, isLucky)
	local button, text, msg, tab, tabTitle

	if (isGolden and isLucky) then
		tab = self.Tabs.tabGoldCardExchangeLucky
		tabTitle = self.MSGS.GOLD_CARD_EXCHANGE_TITLE_LUCKY
		button = self.content.exchange.buttonGoldLucky
		msg = self.MSGS.ERROR_EXCHANGE_GOLDEN_LUCKY
	elseif (isGolden) then
		tab = self.Tabs.tabGoldCardExchange
		tabTitle = self.MSGS.GOLD_CARD_EXCHANGE_TITLE
		button = self.content.exchange.buttonGold
		msg = self.MSGS.ERROR_EXCHANGE_GOLDEN
	elseif (isLucky) then
		tab = self.Tabs.tabCardExchangeLucky
		tabTitle = self.MSGS.CARD_EXCHANGE_TITLE_LUCKY
		button = self.content.exchange.buttonNormalLucky
		msg = self.MSGS.ERROR_EXCHANGE_NORMAL_LUCKY
	else
		tab = self.Tabs.tabCardExchange
		tabTitle = self.MSGS.CARD_EXCHANGE_TITLE
		button = self.content.exchange.buttonNormal
		msg = self.MSGS.ERROR_EXCHANGE_NORMAL
	end

	text = button.errorText

	if (enough) then
		button:Enable()
		text:Hide()
		button.skipConfirm:Show()
	else
		button:Disable()
		text:Show()
		button.skipConfirm:Hide()
		text:SetText(string.format(msg, total))
	end

	tab.text:SetText(tabTitle.." |cffFFFFFF("..total..")|r")
end

function SkillCardExchangeUI.BAG_UPDATE()
	if SkillCardExchangeUI.isOnBagUpdate then
		return
	end

	SkillCardExchangeUI.isOnBagUpdate = true

	Timer.After(0.3, function()
		SkillCardExchangeUI:ScanCards(true, true)
		SkillCardExchangeUI:ScanCards(true, false)
		SkillCardExchangeUI:ScanCards(false, true)
		SkillCardExchangeUI:ScanCards(false, false)

		SkillCardExchangeUI.isOnBagUpdate = false
	end)
end

function SkillCardExchangeUI:LoadExchange(isGolden, isLucky)
	self.content.exchange.buttonNormal:Hide()
	self.content.exchange.buttonGold:Hide()

	self.content.exchange.buttonNormalLucky:Hide()
	self.content.exchange.buttonGoldLucky:Hide()

	if (isGolden and isLucky) then
		self.content.exchange.title:SetText(self.MSGS.EXCHANGE_TITLE_GOLDEN_LUCKY)
		self.content.exchange.subText:SetText(self.MSGS.EXCHANGE_SUBTITLE_GOLDEN_LUCKY)
		self.content.exchange.art:SetTexture("Interface\\darkmoon\\gold_card")
		self.content.exchange.buttonGoldLucky:Show()
	elseif (isGolden) then
		self.content.exchange.title:SetText(self.MSGS.EXCHANGE_TITLE_GOLDEN)
		self.content.exchange.subText:SetText(self.MSGS.EXCHANGE_SUBTITLE_GOLDEN)
		self.content.exchange.art:SetTexture("Interface\\darkmoon\\gold_card")
		self.content.exchange.buttonGold:Show()
	elseif (isLucky) then
		self.content.exchange.title:SetText(self.MSGS.EXCHANGE_TITLE_NORMAL_LUCKY)
		self.content.exchange.subText:SetText(self.MSGS.EXCHANGE_SUBTITLE_NORMAL_LUCKY)
		self.content.exchange.art:SetTexture("Interface\\darkmoon\\normal_card")
		self.content.exchange.buttonNormalLucky:Show()
	else
		self.content.exchange.title:SetText(self.MSGS.EXCHANGE_TITLE_NORMAL)
		self.content.exchange.subText:SetText(self.MSGS.EXCHANGE_SUBTITLE_NORMAL)
		self.content.exchange.art:SetTexture("Interface\\darkmoon\\normal_card")
		self.content.exchange.buttonNormal:Show()
	end
end

function SkillCardExchangeUI:SelectMenu(tab) -- TODO: to gossipShared
	local frame = self.menus[tab.menu]

	if not(frame) then
		return
	end

	for _, frame in pairs(self.menus) do
		frame:Hide()
	end

	frame:FrameFadeIn(0.2)
end

function SkillCardExchangeUI:SelectTab(frame, button) -- TODO: to gossipShared
	if (self.disabled) then
		return
	end

	for _, tab in pairs(frame.tabs) do
		if (button ~= tab) then
			tab.checked:Hide()
		else
			tab.checked:Show()
			if (tab.menu) then
				self:SelectMenu(tab)
			end
		end
	end
end

function SkillCardExchangeUI:CreateTab(name, parent)
	local btn = Addon.SharedGossip:CreateTab(name, parent)

	btn:SetScript("OnClick", function(self, ...)
		SkillCardExchangeUI:SelectTab(self:GetParent(), self)
	end)

	return btn
end

function SkillCardExchangeUI:DefineGossipOption(text, buttonIndex)
	local itemID, cost = string.match(text, self.buyBack_Gossip_text)
	local optionInternal = self.internalGossipOptions[text]

	if (optionInternal) then
		self.gossipOptions[optionInternal] = buttonIndex
	elseif (itemID) then 
		self.totalItems = self.totalItems + 1
		self.gossipOptions["BUYBACK_ITEM_"..self.totalItems] = buttonIndex
		self.content.buyBack.items[self.totalItems]:Enable()
		self.content.buyBack.items[self.totalItems]:SetItem(itemID)
		MoneyFrame_Update(self.content.buyBack.items[self.totalItems].cost, tonumber(cost))
	else
		dprint(self:GetName()..": Gossip option "..text.." not found")
	end
end

function SkillCardExchangeUI:FormatGossipOptionText(text)
	-- TODO: Ask core devs to make it more unified. Atm its messy
	text = string.gsub(text, "^|.*|t", "")
	text = string.gsub(text, "^|r", "")
	text = string.gsub(text, "^|cff......", "")
	text = string.gsub(text, "^ ", "")
	text = string.gsub(text, "|.$", "")
	return text
end

function SkillCardExchangeUI:ClearBuyBackItems()
	self.totalItems = 0
	for i = 1, self.MAX_ITEMS do
		self.content.buyBack.items[i]:Disable()
	end
end

function SkillCardExchangeUI.OnGossipHide()
	C_Gossip:RestoreGossip()
	HideUIPanel(SkillCardExchangeUI)
	StaticPopup_Hide("ASC_SKILLCARD_EXCHANGE_CONFIRM")
end

function SkillCardExchangeUI.OnGossipShow()
	C_Gossip:SilentHideGossip()
	ShowUIPanel(SkillCardExchangeUI)
	SkillCardExchangeUI.HandleCVars()
	SkillCardExchangeUI:ClearBuyBackItems()
	SkillCardExchangeUI:ScanGossip()

	if (SkillCardExchangeUI.content.buyBack:IsVisible() and (SkillCardExchangeUI.gossipOptions["BACK"] == 0)) then
		SkillCardExchangeUI.Tabs.tabBuyBack:GetScript("OnClick")(SkillCardExchangeUI.Tabs.tabBuyBack)
		return
	end
end
-------------------------------------------------------------------------------
--                                    UI                                     --
-------------------------------------------------------------------------------
function SkillCardExchangeUI:CreatePageSwitchButton(name, parent, direction) -- TODO: To shared code
	local button = CreateFrame("Button", "$parent."..name, parent, nil)
	button:SetSize(32, 32)
	button:EnableMouse(true)
	button.direction = direction
	button.text = button:CreateFontString()

	button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	if (button.direction == -1) then
		button.text:SetPoint("LEFT", button, "RIGHT", 0, 0)
		button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-prevPage-Up")
		button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-prevPage-Down")
		button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-prevPage-Disabled")
		button:SetScript("OnMouseDown", function(self)
			if (self:IsEnabled() == 1) then
				self.text:SetPoint("LEFT", self, "RIGHT", 1, -2)
			end
		end)
		button:SetScript("OnMouseUp", function(self)
			if (self:IsEnabled() == 1) then
				self.text:SetPoint("LEFT", self, "RIGHT", 0, 0)
			end
		end)
	elseif (button.direction == 1) then
		button.text:SetPoint("RIGHT", button, "LEFT", 0, 0)
		button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
		button:SetScript("OnMouseDown", function(self)
			if (self:IsEnabled() == 1) then
				self.text:SetPoint("RIGHT", self, "LEFT", 1, -2)
			end
		end)
		button:SetScript("OnMouseUp", function(self)
			if (self:IsEnabled() == 1) then
				self.text:SetPoint("RIGHT", self, "LEFT", 0, 0)
			end
		end)
	end

	button.text:SetFontObject(GameFontNormal)
	button.text:SetJustifyH("LEFT")

	button:SetScript("OnEnter", function(self)
		self.text:SetFontObject(GameFontHighlight)
	end)
	button:SetScript("OnLeave", function(self)
		self.text:SetFontObject(GameFontNormal)
	end)
	button:SetScript("OnDisable", function(self)
		self.text:SetFontObject(GameFontDisable)
	end)
	button:SetScript("OnEnable", function(self)
		self.text:SetFontObject(GameFontNormal)
	end)

	--[[button:SetScript("OnClick", function(self)
		if (self:IsEnabled() == 1) then
			button:GetParent():SwitchPage(button.direction)
		end
	end)]]--

	return button
end

function SkillCardExchangeUI:CreateSlot(name, parent)
	local btn = CreateFrame("CheckButton", "$parent.name", parent, nil)
	btn:SetSize(42, 42)

	btn:SetNormalTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2")
	btn:SetCheckedTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
	btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	btn:SetPushedTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Pushed")
	btn:SetDisabledTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2")
	btn:GetDisabledTexture():SetDesaturated(true)

	btn:GetHighlightTexture():ClearAllPoints()
	btn:GetHighlightTexture():SetPoint("CENTER", 0, 0)
	btn:GetHighlightTexture():SetSize(36, 36)

	btn.BG = btn:CreateTexture(nil, "BACKGROUND")
	btn.BG:SetSize(36,36)
	btn.BG:SetPoint("CENTER", 0, 0)
	btn.BG:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")

	btn.Icon = btn:CreateTexture(nil, "BORDER")
	btn.Icon:SetSize(36,36)
	btn.Icon:SetPoint("CENTER", 0, 0)
	btn.Icon:SetTexture("Interface\\Icons\\inv_misc_book_09")
	btn.Icon:Hide()

	return btn
end

SkillCardExchangeUI:SetSize(784,512)
SkillCardExchangeUI:SetPoint("CENTER", 0, 0)
SkillCardExchangeUI:SetClampedToScreen(true)
SkillCardExchangeUI:RegisterForDrag("LeftButton")
SkillCardExchangeUI:SetScript("OnDragStart", SkillCardExchangeUI.StartMoving)
SkillCardExchangeUI:SetScript("OnDragStop", SkillCardExchangeUI.StopMovingOrSizing)
SkillCardExchangeUI:SetMovable(true)
SkillCardExchangeUI:EnableMouse(true)
SetPortraitToTexture(SkillCardExchangeUI.portrait, "Interface\\ICONS\\ability_mage_timewarp")

-------------------------------------------------------------------------------
--                                   Tabs                                    --
-------------------------------------------------------------------------------
SkillCardExchangeUI.Tabs = Addon.SharedGossip:CreateTabMenuTemplate(SkillCardExchangeUI)
SkillCardExchangeUI.Tabs.Bg:SetTexture("Interface\\darkmoon\\bg_256", "MIRROR", "MIRROR")

SkillCardExchangeUI.Tabs.tabCardExchange = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabCardExchange", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabCardExchange:SetPoint("TOP", 0, -8)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabCardExchange.icon, "Interface\\Icons\\inv_inscription_tarot_6otankdeck")
SkillCardExchangeUI.Tabs.tabCardExchange.checked:Show()
SkillCardExchangeUI.Tabs.tabCardExchange.text:SetText(SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TITLE)
SkillCardExchangeUI.Tabs.tabCardExchange.menu = "EXCHANGE"
SkillCardExchangeUI.Tabs.tabCardExchange.tooltipTitle = SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TITLE
SkillCardExchangeUI.Tabs.tabCardExchange.tooltipText = SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TEXT

SkillCardExchangeUI.Tabs.tabGoldCardExchange = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabGoldCardExchange", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabGoldCardExchange:SetPoint("TOP", SkillCardExchangeUI.Tabs.tabCardExchange, "BOTTOM", 0, -1)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabGoldCardExchange.icon, "Interface\\Icons\\inv_inscription_tooltip_darkmooncard_mop")
SkillCardExchangeUI.Tabs.tabGoldCardExchange.text:SetText(SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TITLE)
SkillCardExchangeUI.Tabs.tabGoldCardExchange.menu = "EXCHANGE"
SkillCardExchangeUI.Tabs.tabGoldCardExchange.tooltipTitle = SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TITLE
SkillCardExchangeUI.Tabs.tabGoldCardExchange.tooltipText = SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TEXT

SkillCardExchangeUI.Tabs.tabCardExchangeLucky = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabCardExchangeLucky", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabCardExchangeLucky:SetPoint("TOP", SkillCardExchangeUI.Tabs.tabGoldCardExchange, "BOTTOM", 0, -1)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabCardExchangeLucky.icon, "Interface\\Icons\\inv_inscription_tarot_6otankdeck")
SkillCardExchangeUI.Tabs.tabCardExchangeLucky.text:SetText(SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TITLE_LUCKY)
SkillCardExchangeUI.Tabs.tabCardExchangeLucky.menu = "EXCHANGE"
SkillCardExchangeUI.Tabs.tabCardExchangeLucky.tooltipTitle = SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TITLE_LUCKY
SkillCardExchangeUI.Tabs.tabCardExchangeLucky.tooltipText = SkillCardExchangeUI.MSGS.CARD_EXCHANGE_TEXT_LUCKY

SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky:SetPoint("TOP", SkillCardExchangeUI.Tabs.tabCardExchangeLucky, "BOTTOM", 0, -1)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky.icon, "Interface\\Icons\\inv_inscription_tooltip_darkmooncard_mop")
SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky.text:SetText(SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TITLE_LUCKY)
SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky.menu = "EXCHANGE"
SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky.tooltipTitle = SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TITLE_LUCKY
SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky.tooltipText = SkillCardExchangeUI.MSGS.GOLD_CARD_EXCHANGE_TEXT_LUCKY

SkillCardExchangeUI.Tabs.tabBuyBack = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabBuyBack", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabBuyBack:SetPoint("TOP", SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky, "BOTTOM", 0, -1)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabBuyBack.icon, "Interface\\Icons\\_Reverse_Acid")
SkillCardExchangeUI.Tabs.tabBuyBack.text:SetText(SkillCardExchangeUI.MSGS.BUYBACK_TITLE)
SkillCardExchangeUI.Tabs.tabBuyBack.tooltipTitle = SkillCardExchangeUI.MSGS.BUYBACK_TITLE
SkillCardExchangeUI.Tabs.tabBuyBack.tooltipText = SkillCardExchangeUI.MSGS.BUYBACK_TEXT
SkillCardExchangeUI.Tabs.tabBuyBack.menu = "BUYBACK"
--SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.Tabs.tabBuyBack, "BUYBACK", true)

SkillCardExchangeUI.Tabs.tabBooster = SkillCardExchangeUI:CreateTab("SkillCardExchangeUI.Tabs.tabBooster", SkillCardExchangeUI.Tabs)
SkillCardExchangeUI.Tabs.tabBooster:SetPoint("TOP", SkillCardExchangeUI.Tabs.tabBuyBack, "BOTTOM", 0, -1)
SetPortraitToTexture(SkillCardExchangeUI.Tabs.tabBooster.icon, "Interface\\Icons\\inv_inscription_tarot_6otankdeck")
SkillCardExchangeUI.Tabs.tabBooster.text:SetText(SkillCardExchangeUI.MSGS.BOOSTER_TITLE)
SkillCardExchangeUI.Tabs.tabBooster.tooltipTitle = SkillCardExchangeUI.MSGS.BOOSTER_TITLE
SkillCardExchangeUI.Tabs.tabBooster.tooltipText = SkillCardExchangeUI.MSGS.BOOSTER_TEXT
SkillCardExchangeUI.Tabs.tabBooster.gossipOption = "BOOSTER"
--SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.Tabs.tabBooster, "BOOSTER", true)

SkillCardExchangeUI.Tabs.tabCardExchange:SetScript("OnClick", function(self, ...)
	SkillCardExchangeUI:SelectTab(self:GetParent(), self)
	SkillCardExchangeUI:LoadExchange(false, false)
	if (SkillCardExchangeUI.gossipOptions["BACK"] ~= 0) then -- go back from buyback
		SelectGossipOption(SkillCardExchangeUI.gossipOptions["BACK"])
	end
end)

SkillCardExchangeUI.Tabs.tabGoldCardExchange:SetScript("OnClick", function(self, ...)
	SkillCardExchangeUI:SelectTab(self:GetParent(), self)
	SkillCardExchangeUI:LoadExchange(true, false)
	if (SkillCardExchangeUI.gossipOptions["BACK"] ~= 0) then -- go back from buyback
		SelectGossipOption(SkillCardExchangeUI.gossipOptions["BACK"])
	end
end)

SkillCardExchangeUI.Tabs.tabCardExchangeLucky:SetScript("OnClick", function(self, ...)
	SkillCardExchangeUI:SelectTab(self:GetParent(), self)
	SkillCardExchangeUI:LoadExchange(false, true)
	if (SkillCardExchangeUI.gossipOptions["BACK"] ~= 0) then -- go back from buyback
		SelectGossipOption(SkillCardExchangeUI.gossipOptions["BACK"])
	end
end)

SkillCardExchangeUI.Tabs.tabGoldCardExchangeLucky:SetScript("OnClick", function(self, ...)
	SkillCardExchangeUI:SelectTab(self:GetParent(), self)
	SkillCardExchangeUI:LoadExchange(true, true)
	if (SkillCardExchangeUI.gossipOptions["BACK"] ~= 0) then -- go back from buyback
		SelectGossipOption(SkillCardExchangeUI.gossipOptions["BACK"])
	end
end)

SkillCardExchangeUI.Tabs.tabBooster:SetScript("OnClick", function(self)
	SkillCardExchangeUI:SelectTab(self:GetParent(), SkillCardExchangeUI.Tabs.tabCardExchange)
	SkillCardExchangeUI:LoadExchange(false, false)

	SkillCardExchangeUI:ClickGossipOptionOrGoBackAndSetDelayed(self)
end)

SkillCardExchangeUI.Tabs.tabBuyBack:SetScript("OnClick", function(self, ...)
	SkillCardExchangeUI:SelectTab(self:GetParent(), self)

	if (SkillCardExchangeUI.gossipOptions["BUYBACK"] ~= 0) then -- go back from buyback
		SelectGossipOption(SkillCardExchangeUI.gossipOptions["BUYBACK"])
	end
end)
-------------------------------------------------------------------------------
--                                  Content                                  --
-------------------------------------------------------------------------------
SkillCardExchangeUI.content = Addon.SharedGossip:CreateContent(SkillCardExchangeUI)
SkillCardExchangeUI.content.Bg:SetTexture("Interface\\darkmoon\\bg", "MIRROR", "MIRROR")

SkillCardExchangeUI.content.Artmain = SkillCardExchangeUI.content:CreateTexture(nil, "BORDER")
SkillCardExchangeUI.content.Artmain:SetTexture("Interface\\darkmoon\\art_bottom")
SkillCardExchangeUI.content.Artmain:SetWidth(590)
SkillCardExchangeUI.content.Artmain:SetHeight(295)
SkillCardExchangeUI.content.Artmain:SetPoint("BOTTOM")
SkillCardExchangeUI.content.Artmain:SetTexCoord(1, 0, 0, 1)

SkillCardExchangeUI.content.ArtTop = SkillCardExchangeUI.content:CreateTexture(nil, "BORDER")
SkillCardExchangeUI.content.ArtTop:SetTexture("Interface\\darkmoon\\art_top")
SkillCardExchangeUI.content.ArtTop:SetWidth(502)
SkillCardExchangeUI.content.ArtTop:SetHeight(125.5)
SkillCardExchangeUI.content.ArtTop:SetPoint("TOP", 0, -12)
-------------------------------------------------------------------------------
--                                 Exchange                                  --
-------------------------------------------------------------------------------
SkillCardExchangeUI.content.exchange = CreateFrame("FRAME", "SkillCardExchangeUI.content.exchange", SkillCardExchangeUI.content)
SkillCardExchangeUI.menus["EXCHANGE"] = SkillCardExchangeUI.content.exchange
SkillCardExchangeUI.menus["EXCHANGE_GOLD"] = SkillCardExchangeUI.content.exchange

SkillCardExchangeUI.content.exchange:SetPoint("CENTER", 0, 0)
SkillCardExchangeUI.content.exchange:SetSize(SkillCardExchangeUI.content:GetSize())

SkillCardExchangeUI.content.exchange.title = SkillCardExchangeUI.content.exchange:CreateFontString(nil)
SkillCardExchangeUI.content.exchange.title:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.exchange.title:SetWidth(573)
SkillCardExchangeUI.content.exchange.title:SetPoint("TOP", 0, -32)

SkillCardExchangeUI.content.exchange.subText = SkillCardExchangeUI.content.exchange:CreateFontString(nil, "OVERLAY")
SkillCardExchangeUI.content.exchange.subText:SetFontObject(GameFontNormal)
SkillCardExchangeUI.content.exchange.subText:SetPoint("TOP", SkillCardExchangeUI.content.exchange.title, "BOTTOM", 0, -4)

SkillCardExchangeUI.content.exchange.art = SkillCardExchangeUI.content.exchange:CreateTexture(nil, "OVERLAY")
SkillCardExchangeUI.content.exchange.art:SetTexture("Interface\\darkmoon\\normal_card")
--SkillCardExchangeUI.content.exchange.art:SetTexture("Interface\\darkmoon\\gold_card")
SkillCardExchangeUI.content.exchange.art:SetSize(300, 300)
SkillCardExchangeUI.content.exchange.art:SetPoint("CENTER", -4, 12)

SkillCardExchangeUI.content.exchange.recipeFrame = CreateFrame("FRAME", "$parent.recipeFrame", SkillCardExchangeUI.content.exchange)
SkillCardExchangeUI.content.exchange.recipeFrame:SetSize(138, 108)
SkillCardExchangeUI.content.exchange.recipeFrame:SetPoint("LEFT", 32, 18)
--SkillCardExchangeUI.content.exchange.recipeFrame:SetBackdrop(GameTooltip:GetBackdrop())

SkillCardExchangeUI.content.exchange.recipeFrame.art = SkillCardExchangeUI.content.exchange.recipeFrame:CreateTexture(nil, "BACKGROUND")
SkillCardExchangeUI.content.exchange.recipeFrame.art:SetTexture("Interface\\darkmoon\\darkmoonPaper")
SkillCardExchangeUI.content.exchange.recipeFrame.art:SetSize(186, 206)
SkillCardExchangeUI.content.exchange.recipeFrame.art:SetPoint("CENTER", 0, 0)

SkillCardExchangeUI.content.exchange.recipeFrame.text = SkillCardExchangeUI.content.exchange.recipeFrame:CreateFontString(nil, "OVERLAY")
SkillCardExchangeUI.content.exchange.recipeFrame.text:SetFontObject(GameFontNormal)
SkillCardExchangeUI.content.exchange.recipeFrame.text:SetPoint("CENTER", 0, 0)
SkillCardExchangeUI.content.exchange.recipeFrame.text:SetSize(138, 108)
SkillCardExchangeUI.content.exchange.recipeFrame.text:SetText(SkillCardExchangeUI.MSGS.EXCHANGE_RATES_TEXT)
SkillCardExchangeUI.content.exchange.recipeFrame.text:SetJustifyH("LEFT")
-------------------------------------------------------------------------------
--                                   Magic                                   --
-------------------------------------------------------------------------------
SkillCardExchangeUI.content.exchange.magic = Addon.SharedGossip:CreateMagic(SkillCardExchangeUI.content.exchange)
SkillCardExchangeUI.content.exchange.magic:SetPoint("CENTER", SkillCardExchangeUI.content.exchange.art, 0, 0)
-------------------------------------------------------------------------------
--                                     UI                                    --
-------------------------------------------------------------------------------
SkillCardExchangeUI.content.exchange.buttonNormal = CreateFrame("Button", "$parent.button", SkillCardExchangeUI.content.exchange, "RedButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonNormal:SetText(SkillCardExchangeUI.MSGS.BUTTON_NORMAL_TEXT)
SkillCardExchangeUI.content.exchange.buttonNormal:SetWidth(240)
SkillCardExchangeUI.content.exchange.buttonNormal:SetHeight(54)
SkillCardExchangeUI.content.exchange.buttonNormal:SetPoint("BOTTOM", 0, 32)
SkillCardExchangeUI.content.exchange.buttonNormal:GetFontString():SetDrawLayer("OVERLAY")

SkillCardExchangeUI.content.exchange.buttonNormal.confirmationText = SkillCardExchangeUI.MSGS.CONFIRM_DIALOGUE_NORMAL
SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.exchange.buttonNormal, "SKILL_CARD_EXCHANGE")
SkillCardExchangeUI.content.exchange.buttonNormal:SetScript("OnClick", SkillCardExchangeUI.ClickExchangeButton)

SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm = CreateFrame("CheckButton", "$parent.skipConfirm", SkillCardExchangeUI.content.exchange.buttonNormal, "SquareIconCheckButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm:SetPoint("TOPLEFT", SkillCardExchangeUI.content.exchange.buttonNormal, "BOTTOMLEFT", 0, -2)
SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm:SetSize(24, 24)

SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm:SetText("Skip exchange confirmation dialogue")
SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm:GetFontString():SetPoint("LEFT", SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm, "RIGHT", 4, 0)

SkillCardExchangeUI.content.exchange.buttonNormal.skipConfirm:SetScript("OnClick", function(self)
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    if self:GetChecked() then
        C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.Normal, true)
    else
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.Normal, false)
    end
end)

SkillCardExchangeUI.content.exchange.buttonGold = CreateFrame("Button", "$parent.button", SkillCardExchangeUI.content.exchange, "RedButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonGold:SetText(SkillCardExchangeUI.MSGS.BUTTON_GOLDEN_TEXT)
SkillCardExchangeUI.content.exchange.buttonGold:SetWidth(240)
SkillCardExchangeUI.content.exchange.buttonGold:SetHeight(54)
SkillCardExchangeUI.content.exchange.buttonGold:SetPoint("BOTTOM", 0, 32)
SkillCardExchangeUI.content.exchange.buttonGold:GetFontString():SetDrawLayer("OVERLAY")
SkillCardExchangeUI.content.exchange.buttonGold:Hide()

SkillCardExchangeUI.content.exchange.buttonGold.confirmationText = SkillCardExchangeUI.MSGS.CONFIRM_DIALOGUE_GOLD
SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.exchange.buttonGold, "GOLDEN_CARD_EXCHANGE")
SkillCardExchangeUI.content.exchange.buttonGold:SetScript("OnClick", SkillCardExchangeUI.ClickExchangeButton)

SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm = CreateFrame("CheckButton", "$parent.skipConfirm", SkillCardExchangeUI.content.exchange.buttonGold, "SquareIconCheckButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm:SetPoint("TOPLEFT", SkillCardExchangeUI.content.exchange.buttonGold, "BOTTOMLEFT", 0, -2)
SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm:SetSize(24, 24)

SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm:SetText("Skip exchange confirmation dialogue")
SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm:GetFontString():SetPoint("LEFT", SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm, "RIGHT", 4, 0)

SkillCardExchangeUI.content.exchange.buttonGold.skipConfirm:SetScript("OnClick", function(self)
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    if self:GetChecked() then
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.Gold, true)
    else
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.Gold, false)
    end
end)

SkillCardExchangeUI.content.exchange.buttonNormal.errorText = SkillCardExchangeUI.content.exchange.buttonNormal:CreateFontString(nil)
SkillCardExchangeUI.content.exchange.buttonNormal.errorText:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.exchange.buttonNormal.errorText:SetWidth(573)
SkillCardExchangeUI.content.exchange.buttonNormal.errorText:SetPoint("TOP", SkillCardExchangeUI.content.exchange.buttonNormal, "BOTTOM", 0, -6)
SkillCardExchangeUI.content.exchange.buttonNormal.errorText:SetText("Internal Error Normal")
SkillCardExchangeUI.content.exchange.buttonNormal.errorText:SetVertexColor(1, 0, 0, 1)

SkillCardExchangeUI.content.exchange.buttonGold.errorText = SkillCardExchangeUI.content.exchange.buttonGold:CreateFontString(nil)
SkillCardExchangeUI.content.exchange.buttonGold.errorText:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.exchange.buttonGold.errorText:SetWidth(573)
SkillCardExchangeUI.content.exchange.buttonGold.errorText:SetPoint("TOP", SkillCardExchangeUI.content.exchange.buttonNormal, "BOTTOM", 0, -6)
SkillCardExchangeUI.content.exchange.buttonGold.errorText:SetText("Internal Error Gold")
SkillCardExchangeUI.content.exchange.buttonGold.errorText:SetVertexColor(1, 0, 0, 1)
SkillCardExchangeUI.content.exchange.buttonGold.errorText:Hide()

SkillCardExchangeUI.content.exchange.buttonNormalLucky = CreateFrame("Button", "$parent.button", SkillCardExchangeUI.content.exchange, "RedButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonNormalLucky:SetText(SkillCardExchangeUI.MSGS.BUTTON_NORMAL_TEXT)
SkillCardExchangeUI.content.exchange.buttonNormalLucky:SetWidth(240)
SkillCardExchangeUI.content.exchange.buttonNormalLucky:SetHeight(54)
SkillCardExchangeUI.content.exchange.buttonNormalLucky:SetPoint("BOTTOM", 0, 32)
SkillCardExchangeUI.content.exchange.buttonNormalLucky:GetFontString():SetDrawLayer("OVERLAY")

SkillCardExchangeUI.content.exchange.buttonNormalLucky.confirmationText = SkillCardExchangeUI.MSGS.CONFIRM_DIALOGUE_NORMAL_LUCKY
SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.exchange.buttonNormalLucky, "LUCKY_CARD_EXCHANGE")
SkillCardExchangeUI.content.exchange.buttonNormalLucky:SetScript("OnClick", SkillCardExchangeUI.ClickExchangeButton)

SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm = CreateFrame("CheckButton", "$parent.skipConfirm", SkillCardExchangeUI.content.exchange.buttonNormalLucky, "SquareIconCheckButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm:SetPoint("TOPLEFT", SkillCardExchangeUI.content.exchange.buttonNormalLucky, "BOTTOMLEFT", 0, -2)
SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm:SetSize(24, 24)

SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm:SetText("Skip exchange confirmation dialogue")
SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm:GetFontString():SetPoint("LEFT", SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm, "RIGHT", 4, 0)

SkillCardExchangeUI.content.exchange.buttonNormalLucky.skipConfirm:SetScript("OnClick", function(self)
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    if self:GetChecked() then
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.LuckyNormal, true)
    else
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.LuckyNormal, false)
    end
end)

SkillCardExchangeUI.content.exchange.buttonGoldLucky = CreateFrame("Button", "$parent.button", SkillCardExchangeUI.content.exchange, "RedButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonGoldLucky:SetText(SkillCardExchangeUI.MSGS.BUTTON_GOLDEN_TEXT)
SkillCardExchangeUI.content.exchange.buttonGoldLucky:SetWidth(240)
SkillCardExchangeUI.content.exchange.buttonGoldLucky:SetHeight(54)
SkillCardExchangeUI.content.exchange.buttonGoldLucky:SetPoint("BOTTOM", 0, 32)
SkillCardExchangeUI.content.exchange.buttonGoldLucky:GetFontString():SetDrawLayer("OVERLAY")

SkillCardExchangeUI.content.exchange.buttonGoldLucky:Hide()

SkillCardExchangeUI.content.exchange.buttonGoldLucky.confirmationText = SkillCardExchangeUI.MSGS.CONFIRM_DIALOGUE_GOLD_LUCKY
SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.exchange.buttonGoldLucky, "LUCKY_GOLD_CARD_EXCHANGE")
SkillCardExchangeUI.content.exchange.buttonGoldLucky:SetScript("OnClick", SkillCardExchangeUI.ClickExchangeButton)

SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm = CreateFrame("CheckButton", "$parent.skipConfirm", SkillCardExchangeUI.content.exchange.buttonGoldLucky, "SquareIconCheckButtonTemplate")
SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm:SetPoint("TOPLEFT", SkillCardExchangeUI.content.exchange.buttonGoldLucky, "BOTTOMLEFT", 0, -2)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm:SetSize(24, 24)

SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm:SetText("Skip exchange confirmation dialogue")
SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm:GetFontString():SetPoint("LEFT", SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm, "RIGHT", 4, 0)

SkillCardExchangeUI.content.exchange.buttonGoldLucky.skipConfirm:SetScript("OnClick", function(self)
    PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
    if self:GetChecked() then
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.LuckyGold, true)
    else
	    C_CVar.SetBitfield("SkillCardExchangeSkip", ExchangeCVarBits.LuckyGold, false)
    end
end)

SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText = SkillCardExchangeUI.content.exchange.buttonNormalLucky:CreateFontString(nil)
SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText:SetWidth(573)
SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText:SetPoint("TOP", SkillCardExchangeUI.content.exchange.buttonNormalLucky, "BOTTOM", 0, -6)
SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText:SetText("Internal Error Normal Lucky")
SkillCardExchangeUI.content.exchange.buttonNormalLucky.errorText:SetVertexColor(1, 0, 0, 1)

SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText = SkillCardExchangeUI.content.exchange.buttonGoldLucky:CreateFontString(nil)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:SetWidth(573)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:SetPoint("TOP", SkillCardExchangeUI.content.exchange.buttonNormalLucky, "BOTTOM", 0, -6)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:SetText("Internal Error Gold Lucky")
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:SetVertexColor(1, 0, 0, 1)
SkillCardExchangeUI.content.exchange.buttonGoldLucky.errorText:Hide()
-------------------------------------------------------------------------------
--                                  BuyBack                                  --
-------------------------------------------------------------------------------
SkillCardExchangeUI.content.buyBack = CreateFrame("FRAME", "SkillCardExchangeUI.content.buyBack", SkillCardExchangeUI.content)
SkillCardExchangeUI.content.buyBack.items = {}
SkillCardExchangeUI.content.buyBack:Hide()

SkillCardExchangeUI.menus["BUYBACK"] = SkillCardExchangeUI.content.buyBack

SkillCardExchangeUI.content.buyBack:SetPoint("CENTER", 0, 0)
SkillCardExchangeUI.content.buyBack:SetSize(SkillCardExchangeUI.content:GetSize())

SkillCardExchangeUI.content.buyBack.title = SkillCardExchangeUI.content.buyBack:CreateFontString(nil)
SkillCardExchangeUI.content.buyBack.title:SetFontObject(GameFontHighlightLarge)
SkillCardExchangeUI.content.buyBack.title:SetWidth(573)
SkillCardExchangeUI.content.buyBack.title:SetPoint("TOP", 0, -32)
SkillCardExchangeUI.content.buyBack.title:SetText(SkillCardExchangeUI.MSGS.BUYBACK_TITLE)

SkillCardExchangeUI.content.buyBack.subText = SkillCardExchangeUI.content.buyBack:CreateFontString(nil, "OVERLAY")
SkillCardExchangeUI.content.buyBack.subText:SetFontObject(GameFontNormal)
SkillCardExchangeUI.content.buyBack.subText:SetPoint("TOP", SkillCardExchangeUI.content.buyBack.title, "BOTTOM", 0, -4)
SkillCardExchangeUI.content.buyBack.subText:SetText(SkillCardExchangeUI.MSGS.BUYBACK_TEXT)
SkillCardExchangeUI.content.buyBack.subText:SetWidth(456)

for i = 1, SkillCardExchangeUI.MAX_ITEMS do
	local item = CreateFrame("FRAME", "$parent.item"..i, SkillCardExchangeUI.content.buyBack, nil)
	item:SetSize(153, 44)
	--item:EnableMouse(true)

	-- duplicating merchant frame here
	item.slot = item:CreateTexture(nil, "BACKGROUND")
	item.slot:SetTexture("Interface\\Buttons\\UI-EmptySlot")
	item.slot:SetSize(64, 64)
	item.slot:SetPoint("TOPLEFT", -13, 13)

	item.nameFrame = item:CreateTexture(nil, "BACKGROUND")
	item.nameFrame:SetTexture("Interface\\MerchantFrame\\UI-Merchant-LabelSlots")
	item.nameFrame:SetSize(128, 78)
	item.nameFrame:SetPoint("LEFT", item.slot, "RIGHT", -9, -18)

	item.name = item:CreateFontString(nil, "ARTWORK")
	item.name:SetFontObject(GameFontNormalSmall)
	item.name:SetJustifyH("LEFT")
	item.name:SetSize(100, 30)
	item.name:SetPoint("LEFT", item.slot, "RIGHT", -5, 7)

	item.btn = CreateFrame("BUTTON", "$parent.btn", item, nil)
	item.btn:SetSize(37, 37)
	item.btn:SetPoint("TOPLEFT", item)

	item.btn.icon = item.btn:CreateTexture(nil, "BORDER")
	item.btn.icon:SetAllPoints(true)

	item.btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
	item.btn:GetNormalTexture():ClearAllPoints()
	item.btn:GetNormalTexture():SetSize(64, 64)
	item.btn:GetNormalTexture():SetPoint("CENTER", 0, -1)

	item.btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	item.btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

	item.cost = CreateFrame("FRAME", "$parent.cost", item, "SmallMoneyFrameTemplate")
	item.cost:SetPoint("BOTTOMLEFT", item.nameFrame, "BOTTOMLEFT", 2, 31)
	item.cost:SetScript("OnLoad", function(self)
		SmallMoneyFrame_OnLoad(self);
		MoneyFrame_SetType(self, "STATIC");
	end)

	item.btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink("item:"..self:GetParent().item)
		GameTooltip:Show()
	end)


	item.btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	function item:Enable()
		self.name:Show()
		self.cost:Show()
		self.nameFrame:SetVertexColor(0.5, 0.5, 0.5)
		self.slot:SetVertexColor(1.0, 1.0, 1.0)
		self.btn.icon:SetVertexColor(1.0, 1.0, 1.0)
		self.btn:GetNormalTexture():SetVertexColor(1.0, 1.0, 1.0)
	end

	function item:Disable()
		self.name:Hide()
		self.cost:Hide()
		self.nameFrame:SetVertexColor(0.5, 0.5, 0.5);
		self.slot:SetVertexColor(0.5, 0.5, 0.5);
		self.btn.icon:SetVertexColor(0.5, 0.5, 0.5);
		self.btn:GetNormalTexture():SetVertexColor(0.5, 0.5, 0.5);
		self.btn.icon:SetTexture("")
	end

	function item:SetItem(itemID)
		local item = Item:CreateFromID(itemID)

		if self.cancelToken then
			self.cancelToken()
			self.cancelToken = nil
		end

		self.cancelToken = item:CancelableContinueOnLoad(function()
			if not item:IsCached() then
				dprint("Tried to cache Item", itemID, "but it doesn't exist?")
				return
			end

			self.item = itemID
			itemInfo = {GetItemInfo(itemID)}
			self.btn.icon:SetTexture(itemInfo[10])
			self.name:SetText(string.gsub(itemInfo[2], "([%[%]])", ""))
		end)
	end

	item:Disable()

	SkillCardExchangeUI:SetGossipOption(item.btn, "BUYBACK_ITEM_"..i, true)

	SkillCardExchangeUI.content.buyBack.items[i] = item

	if (i == 1) then
		item:SetPoint("TOPLEFT", SkillCardExchangeUI.content.buyBack.title, "BOTTOMLEFT", 128, -42)
	elseif (i == 6) then
		item:SetPoint("TOPRIGHT", SkillCardExchangeUI.content.buyBack.title, "BOTTOMRIGHT", -128, -42)
	else
		item:SetPoint("TOP", SkillCardExchangeUI.content.buyBack.items[i-1], "BOTTOM", 0, -8)
	end
end

SkillCardExchangeUI.content.buyBack.nextPage = SkillCardExchangeUI:CreatePageSwitchButton("nextPage", SkillCardExchangeUI.content.buyBack, 1)
SkillCardExchangeUI.content.buyBack.nextPage:SetPoint("BOTTOM", 142, 48)
SkillCardExchangeUI.content.buyBack.nextPage.text:SetText(NEXT)

SkillCardExchangeUI.content.buyBack.prevPage = SkillCardExchangeUI:CreatePageSwitchButton("prevPage", SkillCardExchangeUI.content.buyBack, -1)
SkillCardExchangeUI.content.buyBack.prevPage:SetPoint("BOTTOM", -142, 48)
SkillCardExchangeUI.content.buyBack.prevPage.text:SetText(PREV)

SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.buyBack.nextPage, "NEXT_PAGE", true)
SkillCardExchangeUI:SetGossipOption(SkillCardExchangeUI.content.buyBack.prevPage, "PREV_PAGE", true)
-------------------------------------------------------------------------------
--                                  Scripts                                  --
-------------------------------------------------------------------------------
--SkillCardExchangeUI:LoadExchange(false, false)
--SkillCardExchangeUI:RegisterGossip(10031)
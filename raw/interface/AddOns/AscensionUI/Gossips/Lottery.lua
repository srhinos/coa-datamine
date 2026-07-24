local Addon = select(2, ...)
local LotteryUI = Addon.SharedGossip:CreateGossipFrame("LotteryUI")
Addon.LotteryUI = LotteryUI

LotteryUI.hooks = {
	{
		event = "PLAYER_MONEY",
		triggerOnShow = true,
	},
}

LotteryUI.MSGS = {
	DAY 										= LOTTERY_UI_DAY or "Day",
	DAYS 										= LOTTERY_UI_DAYS or "Days",
	HOUR 										= LOTTERY_UI_HOUR or "Hour",
	HOURS 										= LOTTERY_UI_HOURS or "Hours",
	MINUTE 										= LOTTERY_UI_MINUTE or "Minute",
	MINUTES 									= LOTTERY_UI_MINUTES or "Minutes",
	SECOND 										= LOTTERY_UI_SECOND or "Second",
	SECONDS 									= LOTTERY_UI_SECONDS or "Seconds",
	END_TIMER 									= LOTTERY_UI_END_TIMER or "Lottery Ends In:",
	TOTAL_TICKETS								= LOTTERY_UI_TOTAL_TICKETS or "Your tickets:",
	TOTAL_JACKPOT 								= LOTTERY_UI_TOTAL_JACKPOT or "TOTAL JACKPOT:",
	BONUS_REWARD 								= LOTTERY_UI_BONUS_REWARD or "BONUS REWARD:",
}

LotteryUI.gossipText = {
	JACKPOT_OLD 								= "total jackpot: (%d+)g(%d+)s(%d+)c",
	JACKPOT 									= "total jackpot: (%d+)g(%d+)s(%d+)c and (%d+) bazaar tokens",
	BONUS_REWARD 								= "bonus reward: (%d+)",
	TICKETS 									= "your gold tickets: (%d+)",
	TICKETS_TOKEN 								= "your token tickets: (%d+)",
	TICKETS_OLD 								= "your tickets: (%d+)",
	ENDS_IN_GOLD								= "gold lottery ends in: (%d+)d(%d+)h(%d+)m(%d+)s",
	ENDS_IN_OLD 								= "lottery ends in: (%d+)d(%d+)h(%d+)m(%d+)s",
	ENDS_IN_TOKEN								= "token lottery ends in: (%d+)d(%d+)h(%d+)m(%d+)s",
}

LotteryUI.gossipOptions = {
	TICKET_1 									= 0,
	TICKET_2 									= 0,
	TICKET_3 									= 0,
	TICKET_4									= 0,
}

LotteryUI.internalGossipOptions = {
	["get golden ticket x1 (10g0s0c)"] 						= "TICKET_1",
	["get golden ticket x10 (100g0s0c)"] 					= "TICKET_2",
	["get golden ticket x100 (1000g0s0c)"]					= "TICKET_3",
	["get golden ticket x1000 (10000g0s0c)"]				= "TICKET_4",
	["get golden ticket x1 (5 bazaar tokens)"] 				= "TICKET_5",
	["get golden ticket x10 (50 bazaar tokens)"] 			= "TICKET_6",
	["get golden ticket x100 (500 bazaar tokens)"]			= "TICKET_7",
	["get golden ticket x1000 (5000 bazaar tokens)"]		= "TICKET_8",
}

LotteryUI.Atlases = {

}

LotteryUI.bonusRewards = {
	[97393] = {creaturePreview = 80541}
}
-------------------------------------------------------------------------------
--                                UI Templates                               --
-------------------------------------------------------------------------------
function LotteryUI:CreateItem(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent, nil)
	frame:SetWidth(192)
	frame:SetHeight(64)
	frame:EnableMouse(true)
	--frame:SetBackdrop(GameTooltip:GetBackdrop())

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("LEFT", 4, 0)
    frame.icon:SetSize(48, 48)
   	SetPortraitToTexture(frame.icon, "Interface\\ICONS\\ability_mage_timewarp")

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 16, 8)

    frame.ring = frame:CreateTexture(nil, "OVERLAY")
    frame.ring:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
    frame.ring:SetPoint("CENTER", frame.icon, 0, -2)
    frame.ring:SetSize(56, 56)

    frame.glow = frame:CreateTexture(nil, "BORDER")
    frame.glow:SetAtlas("services-ring-large-glowspin", Const.TextureKit.IgnoreAtlasSize)
    frame.glow:SetSize(128, 128)
    frame.glow:SetPoint("CENTER", frame.icon, 0, 0)

	frame.glow.AnimG = frame.glow:CreateAnimationGroup()
	frame.glow.AnimG.Rotation = frame.glow.AnimG:CreateAnimation("Rotation")
	frame.glow.AnimG.Rotation:SetDuration(60)
	frame.glow.AnimG.Rotation:SetOrder(1)
	frame.glow.AnimG.Rotation:SetEndDelay(0)
	frame.glow.AnimG.Rotation:SetSmoothing("NONE")
	frame.glow.AnimG.Rotation:SetDegrees(-360)

	frame.glow.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	frame.glow.AnimG:Play()

    frame.Highlight = frame:CreateTexture(nil, "OVERLAY")
    frame.Highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    frame.Highlight:SetSize(56, 56)
    frame.Highlight:SetPoint("CENTER", frame.icon, 0, 0)
    frame.Highlight:SetBlendMode("ADD")
    frame.Highlight:Hide()

	function frame:SetText(text)
		self.title:SetText(text)
		self:SetWidth(self.title:GetWidth()+56+16)
	end

	function frame:SetItem(itemID)
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
			SetPortraitToTexture(self.icon, GetItemIcon(self.item))
			self:SetText(item:GetInfo())
		end)
    end

    frame:SetScript("OnEnter", function(self)
    	self.Highlight:Show()
    	if (self.item) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:"..self.item)
			GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self)
		self.Highlight:Hide()
		GameTooltip:Hide()
	end)

    return frame
end

function LotteryUI:CreateRewardItem(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent, nil)
	frame:SetWidth(192)
	frame:SetHeight(64)
	--frame:SetBackdrop(GameTooltip:GetBackdrop())

	frame.icon = frame:CreateTexture(nil, "BORDER")
    frame.icon:SetPoint("RIGHT", -4, 0)
    frame.icon:SetSize(56, 56)
   	frame.icon:SetTexture("Interface\\lottery\\coin_gold")

	frame.digitBox = Addon.SharedGossip:CreateDigitBox("totalHoF", parent)
	frame.digitBox:SetPoint("RIGHT", frame.icon, "LEFT", 0, 0)
	--frame.digitBox:SetBackdrop(GameTooltip:GetBackdrop())

    function frame.digitBox:OnValueChanged(value)
    	frame:SetWidth(frame.icon:GetWidth()+frame.digitBox:GetWidth())
	end

	function frame:SetValue(value)
		frame.digitBox:SetValue(value)
	end

    return frame
end

-------------------------------------------------------------------------------
--                               Frame Templates                             --
-------------------------------------------------------------------------------
-- TODO: those are actually virtual templates, move to XML later or maybe move from mixins to just methods
--LotteryJackPotMixin = {}

local function LotteryJackPotMixin_OnLoad(self)
	self:SetSize(776,128)

	self.title = self:CreateFontString(nil, "OVERLAY")
	self.title:SetFontObject(GameFontNormalHuge)
	self.title:SetPoint("CENTER", 0, 32)
	self.title:SetVertexColor(1, 1, 1, 1)
	self.title:SetText(LotteryUI.MSGS.TOTAL_JACKPOT)

	self.Shadow = self:CreateTexture(nil, "BACKGROUND")
	self.Shadow:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\Collections\\Shadow")
	self.Shadow:SetPoint("CENTER", 0, 0)
	self.Shadow:SetHeight(128)
	self.Shadow:SetWidth(712)
	self.Shadow:SetAlpha(0.7)
end

--LotterySubFrameMixin = {}

local function LotterySubFrameMixin_OnLoad(self)
	self:SetSize(196, 64)

	self.icon = self:CreateTexture(nil, "BORDER")
	self.icon:SetPoint("LEFT", 4, 0)
	self.icon:SetSize(24, 24)
	self.icon:SetAtlas("bags-greenarrow", Const.TextureKit.IgnoreAtlasSize)

	self.title = self:CreateFontString(nil, "OVERLAY")
	self.title:SetFontObject(GameFontHighlightLarge)
	self.title:SetPoint("LEFT", self.icon, "RIGHT", 8, 8)
	self.title:SetText("TEXT")

	-- TODO: Replace variable name via subtitle
	self.total = self:CreateFontString(nil, "OVERLAY")
	self.total:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -4)
	self.total:SetFontObject(GameFontNormal)
	self.total:SetJustifyH("LEFT")
end

LotteryTabFrameMixin = {}

function LotteryTabFrameMixin:SetTimer(totalTime)
	self.lotteryTimer.timer:Run(totalTime)
end

function LotteryTabFrameMixin:SetTicketCount(ticketCount)
	self.ticketsFrame.total:SetText(ticketCount)
end

function LotteryTabFrameMixin:OnLoad()
	self.jackPot = CreateFrame("FRAME", "$parent.jackPot", self, nil)
	self.jackPot:SetPoint("CENTER", 0, 84)
	LotteryJackPotMixin_OnLoad(self.jackPot)

	self.lotteryTimer = CreateFrame("FRAME", "$parent.lotteryTimer", self)
	self.lotteryTimer:SetPoint("BOTTOMRIGHT", -18, 96)
	LotterySubFrameMixin_OnLoad(self.lotteryTimer)

	self.lotteryTimer.title:SetText(LotteryUI.MSGS.END_TIMER)

	self.lotteryTimer.icon:SetAtlas("auctionhouse-icon-clock", Const.TextureKit.UseAtlasSize)

	self.lotteryTimer.total = Addon.SharedGossip:CreateTimer(self.lotteryTimer)
	self.lotteryTimer.total:SetPoint("TOPLEFT", self.lotteryTimer.title, "BOTTOMLEFT", 0, -4)
	self.lotteryTimer.total:SetFontObject(GameFontNormal)
	self.lotteryTimer.total:SetJustifyH("LEFT")

	self.ticketsFrame = CreateFrame("FRAME", "$parent.ticketsFrame", self)
	self.ticketsFrame:SetPoint("BOTTOM", self.lotteryTimer, "TOP", 0, 0)
	LotterySubFrameMixin_OnLoad(self.ticketsFrame)

	self.ticketsFrame.title:SetText(LotteryUI.MSGS.TOTAL_TICKETS)

	self.button1 = CreateFrame("Button", "$parent.button1", self, "RedButtonTemplate")
	self.button1:SetWidth(172)
	self.button1:SetHeight(40)
	self.button1:SetPoint("BOTTOM", -(188/2)*3, 18)
	self.button1:GetFontString():SetDrawLayer("OVERLAY")

	self.button2 = CreateFrame("Button", "$parent.button2", self, "RedButtonTemplate")
	self.button2:SetWidth(172)
	self.button2:SetHeight(40)
	self.button2:SetPoint("LEFT", self.button1, "RIGHT", 16, 0)
	self.button2:GetFontString():SetDrawLayer("OVERLAY")

	self.button3 = CreateFrame("Button", "$parent.button3", self, "RedButtonTemplate")
	self.button3:SetWidth(172)
	self.button3:SetHeight(40)
	self.button3:SetPoint("LEFT", self.button2, "RIGHT", 16, 0)
	self.button3:GetFontString():SetDrawLayer("OVERLAY")

	self.button4 = CreateFrame("Button", "$parent.button4", self, "RedButtonTemplate")
	self.button4:SetWidth(172)
	self.button4:SetHeight(40)
	self.button4:SetPoint("LEFT", self.button3, "RIGHT", 16, 0)
	self.button4:GetFontString():SetDrawLayer("OVERLAY")

	self.buttons = {
		self.button1,
		self.button2,
		self.button3,
		self.button4,
	}
end
-------------------------------------------------------------------------------
--                                    UI                                     --
-------------------------------------------------------------------------------
LotteryUINineSlice:SetFrameLevel(LotteryUI:GetFrameLevel()+10)
LotteryUI:SetSize(943,632)
LotteryUI:SetPoint("CENTER", 0, 0)
LotteryUI:SetClampedToScreen(true)
LotteryUI:RegisterForDrag("LeftButton")
LotteryUI:SetScript("OnDragStart", LotteryUI.StartMoving)
LotteryUI:SetScript("OnDragStop", LotteryUI.StopMovingOrSizing)
LotteryUI:SetMovable(true)
LotteryUI:EnableMouse(true)
SetPortraitToTexture(LotteryUI.portrait, "Interface\\ICONS\\ability_mage_timewarp")
LotteryUI.portrait:SetParent(LotteryUINineSlice)

LotteryUI.Bg:SetTexture(0.04, 0.075, 0.09, 1)

LotteryUI.ArtBG = LotteryUI:CreateTexture(nil, "BORDER")
LotteryUI.ArtBG:SetTexture("Interface\\lottery\\lotteryAtlas")
LotteryUI.ArtBG:SetSize(942, 411)
LotteryUI.ArtBG:SetTexCoord(0, 1, 0.5, 0.997)
LotteryUI.ArtBG:SetPoint("BOTTOM", 0, 128)

LotteryUI.RewardModel = CreateFrame("DressUpModel", "$parent.RewardModel", LotteryUI)
LotteryUI.RewardModel:SetSize(376, 524)
--LotteryUI.RewardModel:SetBackdrop(GameTooltip:GetBackdrop())
LotteryUI.RewardModel:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
LotteryUI.RewardModel:SetPoint("BOTTOMLEFT", LotteryUI.ArtBG, 4, -116)
LotteryUI.RewardModel:SetFacing(-0.5)
MixinAndLoad(LotteryUI.RewardModel, ModelMixin)
LotteryUI.RewardModel:SetMinMaxDistance(-0.5, 1.2)
LotteryUI.RewardModel:SetEnableDragRotation(true)
LotteryUI.RewardModel:SetEnableScrollZoom(true)

LotteryUI.OverlayTextures = CreateFrame("FRAME", "$parent.OverlayTextures", LotteryUI)
LotteryUI.OverlayTextures:SetFrameLevel(LotteryUI.RewardModel:GetFrameLevel()+1)

LotteryUI.ArtChest = LotteryUI.OverlayTextures:CreateTexture(nil, "BORDER")
LotteryUI.ArtChest:SetTexture("Interface\\lottery\\lotteryAtlas")
LotteryUI.ArtChest:SetSize(737, 462)
LotteryUI.ArtChest:SetTexCoord(0, 0.799, 0, 0.501)
LotteryUI.ArtChest:SetPoint("BOTTOM", LotteryUI.ArtBG, 0, 0)

LotteryUI.ArtBottom = LotteryUI.OverlayTextures:CreateTexture(nil, "BACKGROUND")
LotteryUI.ArtBottom:SetPoint("TOPLEFT", LotteryUI, "BOTTOMLEFT", 0, 128)
LotteryUI.ArtBottom:SetPoint("BOTTOMRIGHT", LotteryUI, "BOTTOMRIGHT")
LotteryUI.ArtBottom:SetTexture(0.06, 0.09, 0.13, 1)

-- shadow for inner window
LotteryUI.cornerTopLeft = LotteryUI.OverlayTextures:CreateTexture(nil, "ARTWORK")
LotteryUI.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
LotteryUI.cornerTopLeft:SetSize(147, 149)
LotteryUI.cornerTopLeft:SetPoint("TOPLEFT", LotteryUI, 0, -24)

LotteryUI.cornerTopRight = LotteryUI.OverlayTextures:CreateTexture(nil, "ARTWORK")
LotteryUI.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
LotteryUI.cornerTopRight:SetSize(147, 149)
LotteryUI.cornerTopRight:SetPoint("TOPRIGHT", LotteryUI, 0, -24)
LotteryUI.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)

LotteryUI.cornerBottomLeft = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
LotteryUI.cornerBottomLeft:SetSize(147, 149)
LotteryUI.cornerBottomLeft:SetPoint("BOTTOMLEFT", LotteryUI, 0, 0)
LotteryUI.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)
				
LotteryUI.cornerBottomRight = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
LotteryUI.cornerBottomRight:SetSize(147, 149)
LotteryUI.cornerBottomRight:SetPoint("BOTTOMRIGHT", LotteryUI, 0, 0)
LotteryUI.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)


LotteryUI.shadowTop = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
LotteryUI.shadowTop:SetPoint("TOPLEFT", LotteryUI.cornerTopLeft, "TOPRIGHT", 0, 0)
LotteryUI.shadowTop:SetPoint("BOTTOMRIGHT", LotteryUI.cornerTopRight, "BOTTOMLEFT", 0, 0)
LotteryUI.shadowTop:SetAlpha(0.6)

LotteryUI.shadowBottom = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
LotteryUI.shadowBottom:SetPoint("TOPLEFT", LotteryUI.cornerBottomLeft, "TOPRIGHT", 0, 0)
LotteryUI.shadowBottom:SetPoint("BOTTOMRIGHT", LotteryUI.cornerBottomRight, "BOTTOMLEFT", 0, 0)
LotteryUI.shadowBottom:SetAlpha(0.6)

LotteryUI.shadowLeft = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
LotteryUI.shadowLeft:SetPoint("TOPLEFT", LotteryUI.cornerTopLeft, "BOTTOMLEFT", 0, 0)
LotteryUI.shadowLeft:SetPoint("BOTTOMRIGHT", LotteryUI.cornerBottomLeft, "TOPRIGHT", 0, 0)
LotteryUI.shadowLeft:SetAlpha(0.6)

LotteryUI.shadowRight = LotteryUI.OverlayTextures:CreateTexture(nil, "OVERLAY")
LotteryUI.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
LotteryUI.shadowRight:SetPoint("TOPRIGHT", LotteryUI.cornerTopRight, "BOTTOMRIGHT", 0, 0)
LotteryUI.shadowRight:SetPoint("BOTTOMLEFT", LotteryUI.cornerBottomRight, "TOPLEFT", 0, 0)
LotteryUI.shadowRight:SetAlpha(0.6)
-------------------------------------------------------------------------------
--                         Content Additional Reward                         --
-------------------------------------------------------------------------------
LotteryUI.AdditionalReward = LotteryUI:CreateItem("AdditionalReward", LotteryUI)
LotteryUI.AdditionalReward:SetPoint("BOTTOMLEFT", LotteryUI.ArtChest, -56, -32)
LotteryUI.AdditionalReward:SetFrameLevel(LotteryUI.OverlayTextures:GetFrameLevel()+1)

LotteryUI.AdditionalReward.rewardText = LotteryUI.AdditionalReward:CreateFontString(nil, "OVERLAY")
LotteryUI.AdditionalReward.rewardText:SetFontObject(GameFontNormal)
LotteryUI.AdditionalReward.rewardText:SetPoint("TOPLEFT", LotteryUI.AdditionalReward.title, "BOTTOMLEFT", 0, -4)
LotteryUI.AdditionalReward.rewardText:SetText("Bonus Reward")

-------------------------------------------------------------------------------
--                               Lottery Gold                                --
-------------------------------------------------------------------------------
LotteryUI.GoldTab = CreateFrame("FRAME", "$parent.GoldTab", LotteryUI, nil)
LotteryUI.GoldTab:SetFrameLevel(LotteryUI.OverlayTextures:GetFrameLevel()+1)
LotteryUI.GoldTab:SetSize(LotteryUI:GetSize())
LotteryUI.GoldTab:SetPoint("CENTER")

MixinAndLoad(LotteryUI.GoldTab, LotteryTabFrameMixin)

LotteryUI.GoldTab.jackPot.total = CreateFrame("FRAME", "$parent.total", LotteryUI.GoldTab.jackPot, nil)
LotteryUI.GoldTab.jackPot.total:SetSize(1,64)
LotteryUI.GoldTab.jackPot.total:SetPoint("TOP", LotteryUI.GoldTab.jackPot.title, "BOTTOM", 0, 0)

LotteryUI.GoldTab.jackPot.total.bronze = LotteryUI:CreateRewardItem("bronze", LotteryUI.GoldTab.jackPot.total)
LotteryUI.GoldTab.jackPot.total.bronze:SetPoint("RIGHT", LotteryUI.GoldTab.jackPot.total, 0, 0)
LotteryUI.GoldTab.jackPot.total.bronze:SetValue(80)
LotteryUI.GoldTab.jackPot.total.bronze.icon:SetTexture("Interface\\lottery\\coin_bronze")

LotteryUI.GoldTab.jackPot.total.silver = LotteryUI:CreateRewardItem("silver", LotteryUI.GoldTab.jackPot.total)
LotteryUI.GoldTab.jackPot.total.silver:SetPoint("RIGHT", LotteryUI.GoldTab.jackPot.total.bronze, "LEFT", 0, 0)
LotteryUI.GoldTab.jackPot.total.silver:SetValue(36)
LotteryUI.GoldTab.jackPot.total.silver.icon:SetTexture("Interface\\lottery\\coin_silver")

LotteryUI.GoldTab.jackPot.total.gold = LotteryUI:CreateRewardItem("gold", LotteryUI.GoldTab.jackPot.total)
LotteryUI.GoldTab.jackPot.total.gold:SetPoint("RIGHT", LotteryUI.GoldTab.jackPot.total.silver, "LEFT", 0, 0)
LotteryUI.GoldTab.jackPot.total.gold:SetValue(234560)

function LotteryUI.GoldTab.jackPot.total:SetValue(g, s, c)
	g = g or 0
	s = s or 0
	c = c or 0

	self.gold:SetValue(g)
	self.silver:SetValue(s)
	self.bronze:SetValue(c)

	self:SetWidth(self.bronze:GetWidth()+self.silver:GetWidth()+self.gold:GetWidth())
end

function LotteryUI.GoldTab:SetJackPot(...)
	self.jackPot.total:SetValue(...)
end

-- TODO: cost can be scanned from gossip text
LotteryUI.GoldTab.button1:SetText("|cffFFFFFF|TInterface\\MONEYFRAME\\UI-GoldIcon.blp:16:16:0:0|t 10|r x1 Ticket")
LotteryUI.GoldTab.button1.cost = 100000

LotteryUI.GoldTab.button2:SetText("|cffFFFFFF|TInterface\\MONEYFRAME\\UI-GoldIcon.blp:16:16:0:0|t 100|r x10 Tickets")
LotteryUI.GoldTab.button2.cost = 1000000

LotteryUI.GoldTab.button3:SetText("|cffFFFFFF|TInterface\\MONEYFRAME\\UI-GoldIcon.blp:16:16:0:0|t 1000|r x100 Tickets")
LotteryUI.GoldTab.button3.cost = 10000000

LotteryUI.GoldTab.button4:SetText("|cffFFFFFF|TInterface\\MONEYFRAME\\UI-GoldIcon.blp:16:16:0:0|t 10000|r x1000 Tickets")
LotteryUI.GoldTab.button4.cost = 100000000

LotteryUI:SetGossipOption(LotteryUI.GoldTab.button1, "TICKET_1", true)
LotteryUI:SetGossipOption(LotteryUI.GoldTab.button2, "TICKET_2", true)
LotteryUI:SetGossipOption(LotteryUI.GoldTab.button3, "TICKET_3", true)
LotteryUI:SetGossipOption(LotteryUI.GoldTab.button4, "TICKET_4", true)

function LotteryUI.GoldTab:PLAYER_MONEY()
	local coinage = GetMoney()
	for i = 1, #self.buttons do
		local button = self.buttons[i]
		if (button.cost <= coinage) then
			button:Enable()
		else
			button:Disable()
		end
	end
end
-------------------------------------------------------------------------------
--                               jackpot tokens                              --
-------------------------------------------------------------------------------
LotteryUI.TokenTab = CreateFrame("FRAME", "$parent.TokenTab", LotteryUI, nil)
LotteryUI.TokenTab:SetFrameLevel(LotteryUI.OverlayTextures:GetFrameLevel()+1)
LotteryUI.TokenTab:SetSize(LotteryUI:GetSize())
LotteryUI.TokenTab:SetPoint("CENTER")
LotteryUI.TokenTab:Hide()

MixinAndLoad(LotteryUI.TokenTab, LotteryTabFrameMixin)

LotteryUI.TokenTab.jackPot.item = LotteryUI:CreateRewardItem("item", LotteryUI.TokenTab.jackPot)
LotteryUI.TokenTab.jackPot.item:SetPoint("CENTER", 0, -10)
LotteryUI.TokenTab.jackPot.item:SetValue(0404)
LotteryUI.TokenTab.jackPot.item.icon:SetTexture("Interface\\Icons\\Spell_Shadow_Teleport")
LotteryUI.TokenTab.jackPot.item.icon:SetSize(36, 36)

LotteryUI.TokenTab.button1:SetText("|cffFFFFFF|TInterface\\Icons\\Spell_Shadow_Teleport.blp:16:16:0:0|t 5|r x1 Ticket")
LotteryUI.TokenTab.button1.cost = 5

LotteryUI.TokenTab.button2:SetText("|cffFFFFFF|TInterface\\Icons\\Spell_Shadow_Teleport.blp:16:16:0:0|t 50|r x10 Tickets")
LotteryUI.TokenTab.button2.cost = 50

LotteryUI.TokenTab.button3:SetText("|cffFFFFFF|TInterface\\Icons\\Spell_Shadow_Teleport.blp:16:16:0:0|t 500|r x100 Tickets")
LotteryUI.TokenTab.button3.cost = 500

LotteryUI.TokenTab.button4:SetText("|cffFFFFFF|TInterface\\Icons\\Spell_Shadow_Teleport.blp:16:16:0:0|t 5000|r x1000 Tickets")
LotteryUI.TokenTab.button4.cost = 5000

LotteryUI:SetGossipOption(LotteryUI.TokenTab.button1, "TICKET_5", true)
LotteryUI:SetGossipOption(LotteryUI.TokenTab.button2, "TICKET_6", true)
LotteryUI:SetGossipOption(LotteryUI.TokenTab.button3, "TICKET_7", true)
LotteryUI:SetGossipOption(LotteryUI.TokenTab.button4, "TICKET_8", true)

function LotteryUI.TokenTab:SetJackPot(...)
	self.jackPot.item:SetValue(...)
end

function LotteryUI.TokenTab:BAG_UPDATE()
	local itemCount = GetItemCount(ItemData.BAZAAR_TOKENS)

	for i = 1, #self.buttons do
		local button = self.buttons[i]
		if (button.cost <= itemCount) then
			button:Enable()
		else
			button:Disable()
		end
	end
end

LotteryUI.TokenTab:SetScript("OnShow", function(self)
	self:HookBucketEvent("BAG_UPDATE", 0.1)
	self:BAG_UPDATE()
end)

LotteryUI.TokenTab:SetScript("OnHide", function(self)
	self:UnhookEvent("BAG_UPDATE")
end)
-------------------------------------------------------------------------------
--                                    Tabs                                   --
-------------------------------------------------------------------------------
LotteryUI.Tab1 = CreateFrame("BUTTON", "$parentTab1", LotteryUI, "CharacterFrameTabButtonTemplate")
LotteryUI.Tab1:SetText("Gold Lottery")
LotteryUI.Tab1:SetPoint("TOPLEFT", LotteryUI, "BOTTOMLEFT", 0, 2)
LotteryUI.Tab1:SetID(1)
LotteryUI.Tab1:SetScript("OnClick", function(self)
	self:GetParent():OnTabClick(self)
end)

LotteryUI.Tab1:SetFrameLevel(LotteryUINineSlice:GetFrameLevel()+1)

LotteryUI.Tab2 = CreateFrame("BUTTON", "$parentTab2", LotteryUI, "CharacterFrameTabButtonTemplate")
LotteryUI.Tab2:SetText("Bazaar Token Lottery")
LotteryUI.Tab2:SetPoint("LEFT", LotteryUI.Tab1, "RIGHT", -14, 0)
LotteryUI.Tab2:SetID(2)
LotteryUI.Tab2:SetScript("OnClick", function(self)
	self:GetParent():OnTabClick(self)
end)

LotteryUI.Tab2:SetFrameLevel(LotteryUINineSlice:GetFrameLevel()+1)
LotteryUI.Tab2:Hide()

LotteryUI.Tabs = {
	{tab = LotteryUI.Tab1, menu = LotteryUI.GoldTab},
	--{tab = LotteryUI.Tab2, menu = LotteryUI.TokenTab},
}

PanelTemplates_SetNumTabs(LotteryUI, #LotteryUI.Tabs)

LotteryUI:Hide()
-------------------------------------------------------------------------------
--                               Communication                               --
-------------------------------------------------------------------------------
LotteryUI:SetScript("OnShow", function(self)
	if not PanelTemplates_GetSelectedTab(self) then
		self:OpenTab(1)
	end
end)

function LotteryUI:OnTabClick(tabButton)
	PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
	self:OpenTab(tabButton:GetID())
end

function LotteryUI:OpenTab(index)
	if PanelTemplates_IsTabEnabled(self, index) then
		PanelTemplates_SetTab(self, index)
		for i, tab in ipairs(self.Tabs) do
			if i == index then
				BaseFrameFadeIn(tab.menu)
				--self[tab.key]:Show()
				--self.NineSlice.Title:SetText(self["Tab"..i]:GetText())
			else
				BaseFrameFadeOut(tab.menu)
				--self[tab.key]:Hide()
			end
		end
	else
		local hasSelected = false
		for i, tab in ipairs(self.Tabs) do
			if PanelTemplates_IsTabEnabled(self, i) and not hasSelected then
				PanelTemplates_SetTab(self, i)
				BaseFrameFadeIn(tab.menu)
				hasSelected = true
			else
				BaseFrameFadeOut(tab.menu)
			end
		end
	end
end

-- TODO: supports only creatures atm. If needs to support player, implement
function LotteryUI:ShowReward(itemID)
	self.AdditionalReward:SetItem(itemID)

	local previewData = self.bonusRewards[itemID] or VanityCollectionUtil.GetItem(itemID)
	local creatureID = nil

	if previewData and (previewData.creaturePreview) and (previewData.creaturePreview ~= 0) then
		creatureID = previewData.creaturePreview
	end

	if not(creatureID) then
		return
	end

	self.RewardModel:SetDisplayInfo(creatureID)
	self.RewardModel:ResetValues()
end

function LotteryUI.PLAYER_MONEY()
	LotteryUI.GoldTab:PLAYER_MONEY()
end

function LotteryUI:FormatGossipOptionText(text)
	return text
	--return string.gsub(text, ".%(.*%)$", "") -- remove ticket cost line from the end of the line
end

local function TimeToSeconds(endsDays, endsHours, endsMinutes, endsSeconds)
	local totalTime = 0

	endsDays = tonumber(endsDays)*86400
	endsHours = tonumber(endsHours)*3600
	endsMinutes = tonumber(endsMinutes)*60
	endsSeconds = tonumber(endsSeconds)

	totalTime = endsDays + endsHours + endsMinutes + endsSeconds

	return totalTime
end

function LotteryUI:ScanGossipText(text)
	local bonusItem = string.match(text, self.gossipText.BONUS_REWARD) 
	
	if (bonusItem) then
		local item = tonumber(bonusItem)
		self:ShowReward(item)
	else
		dprint(self:GetName().." Bonus reward is missing")
		self:ShowReward(next(self.bonusRewards))
	end

	local jackpotGold, jackpotSilver, jackpotCopper, jackpotTokens = string.match(text, self.gossipText.JACKPOT)

	if not(jackpotGold) then
		jackpotGold, jackpotSilver, jackpotCopper = string.match(text, self.gossipText.JACKPOT_OLD)
	end

	if (jackpotGold) then
		jackpotGold = tonumber(jackpotGold)
		jackpotSilver = tonumber(jackpotSilver)
		jackpotCopper = tonumber(jackpotCopper)

		self.GoldTab:SetJackPot(jackpotGold, jackpotSilver, jackpotCopper)
	else
		dprint(self:GetName().." jackpot is missing")
		self.jackPot.total:SetValue(0, 0, 0)
	end

	if (jackpotTokens) then
		jackpotTokens = tonumber(jackpotTokens)

		self.TokenTab:SetJackPot(jackpotTokens)
	else
		PanelTemplates_DisableTab(LotteryUI, 2)
		dprint(self:GetName().." jackpot tokens is missing")
	end
	
	local totalTicketsGold = string.match(text, self.gossipText.TICKETS) or string.match(text, self.gossipText.TICKETS_OLD) or 0
	self.GoldTab:SetTicketCount(totalTicketsGold)

	local totalTicketsToken = string.match(text, self.gossipText.TICKETS_TOKEN) or 0
	self.TokenTab:SetTicketCount(totalTicketsToken)

	local endsDays, endsHours, endsMinutes, endsSeconds = string.match(text, self.gossipText.ENDS_IN_GOLD)

	if not(endsDays) then -- TODO: Remove
	 endsDays, endsHours, endsMinutes, endsSeconds = string.match(text, self.gossipText.ENDS_IN_OLD)
	end

	if (endsDays) then
		self.GoldTab:SetTimer(TimeToSeconds(endsDays, endsHours, endsMinutes, endsSeconds))
	else
		dprint(self:GetName().." Time for gold lottery is not found")
	end

	endsDays, endsHours, endsMinutes, endsSeconds = string.match(text, self.gossipText.ENDS_IN_TOKEN)

	if (endsDays) then
		self.TokenTab:SetTimer(TimeToSeconds(endsDays, endsHours, endsMinutes, endsSeconds))
	else
		dprint(self:GetName().." Time for token lottery is not found")
	end
	
end

LotteryUI:RegisterGossip(80539)

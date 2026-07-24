local TokenObjectMixin = {}

function TokenObjectMixin:Init(tokenType)
	self.tokenType = tokenType
	if not self.tokenType then
		C_Logger.Error("TokenObjectMixin:Init() - tokenType is nil")
		return
	end
	self.name, self.description, self.tooltip, self.icon, self.toastStyle, self.showToast, self.quality = C_Token.GetTokenInfo(self.tokenType)

	if not self.name then
		self.name = RED_FONT_COLOR:WrapText("NO TOKEN NAME FOR: "..self.tokenType)
	end

	if not self.description then
		self.description = ""
	end

	if not self.tooltip then
		self.tooltip = ""
	end

	if not self.icon then
		self.icon = "inv_misc_questionmark"
	end
	
	self.icon = "Interface\\Icons\\"..self.icon
end

function TokenObjectMixin:GetName()
	return self.name
end

function TokenObjectMixin:GetIcon()
	return self.icon
end

function TokenObjectMixin:GetDescription()
	return self.description
end

function TokenObjectMixin:GetTooltip()
	return self.tooltip
end

function TokenObjectMixin:GetTokenType()
	return self.tokenType
end

function TokenObjectMixin:GetCount()
	if not self.tokenType then return 0 end
	return GetTokenCount(self.tokenType)
end

function TokenObjectMixin:GetToastStyle()
	return self.toastStyle or "Token"
end

function TokenObjectMixin:ShouldShowToast()
	return self.showToast
end

function TokenObjectMixin:GetQuality()
	return self.quality or Enum.ItemQuality.Common
end

function TokenObjectMixin:GetLink()
	local quality = ITEM_QUALITY_COLORS[self:GetQuality()]
	return  quality:WrapText("|Htoken:"..self.tokenType.."|h["..self.name.."]|h")
end

--
-- Token util
--
--[[
	C_Token.GetTokenAmount(string type) -> int amount
	C_Token.GetTokenInfo(string type) -> string name, string description, string tooltip, string icon
	C_Token.GetTokenTypes() -> array types
	TOKEN_UPDATED(string type, int oldAmount, int newAmount)
]]--

TokenUtil = {}
TokenUtil.Cache = {}
TokenUtil.caseOfFortuneUsedTimestamp = nil

function TokenUtil.GetTokenCount(tokenType)
	return C_Token.GetTokenAmount(tokenType) or 0
end

function TokenUtil.CreateFromTokenType(tokenType)
	local obj = TokenUtil.Cache[tokenType]
	if not obj then
		obj = Mixin({}, TokenObjectMixin)
		obj:Init(tokenType)
		TokenUtil.Cache[tokenType] = obj
	end

	return obj
end

function TokenUtil.GetTokenLink(tokenType)
	if not tokenType then return end
	local token = TokenUtil.CreateFromTokenType(tokenType)
	return token:GetLink()
end

function TokenUtil.GetScrollOfFortuneTalentsForSpec(specID)
	return Enum.ScrollsOfFortuneTalents[specID or SpecializationUtil.GetActiveSpecialization()] or Enum.ScrollsOfFortuneTalents[1]
end

function TokenUtil.GetScrollOfFortuneAbilitiesForSpec(specID)
	return Enum.ScrollsOfFortuneAbilities[specID or SpecializationUtil.GetActiveSpecialization()] or Enum.ScrollsOfFortuneAbilities[1]
end

function TokenUtil.GetScrollOfFortuneForSpec(specID)
	return Enum.ScrollsOfFortune[specID or SpecializationUtil.GetActiveSpecialization()] or Enum.ScrollsOfFortune[1]
end

function TokenUtil.GetSpecIDByToken(tokenType)
	for k, v in pairs(Enum.ScrollsOfFortune) do
		if v == tokenType then
			return k
		end
	end
	
	for k, v in pairs(Enum.ScrollsOfFortuneTalents) do
		if v == tokenType then
			return k
		end
	end

	for k, v in pairs(Enum.ScrollsOfFortuneAbilities) do
		if v == tokenType then
			return k
		end
	end
end

function TokenUtil.IsScrollOfFortuneTokenForInactiveSpec(tokenType)
	local specID = TokenUtil.GetSpecIDByToken(tokenType)
	local activeSpecID = SpecializationUtil.GetActiveSpecialization()
	return specID and activeSpecID and specID ~= activeSpecID
end

function TokenUtil.RecentlyUsedCaseOfFortune()
	return TokenUtil.TimeSinceCaseOfFortuneUsed and TokenUtil.TimeSinceCaseOfFortuneUsed:LessThan(1)
end

local showCANextUpdate = false
function TokenUtil:TOKEN_UPDATED(tokenType, oldAmount, newAmount)
	local count = newAmount - oldAmount

	if count < 0 then
		return
	end

	if C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) and not TokenUtil.RecentlyUsedCaseOfFortune() then
		local specID = TokenUtil.GetSpecIDByToken(tokenType)

		if not(specID) then
			return
		end
		
		local shouldOpen = showCANextUpdate and (not CharacterAdvancement or not CharacterAdvancement:IsVisible()) -- dont open if already open

		if shouldOpen then
			showCANextUpdate = false
			if Collections then
				Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
			end
		end

		if CharacterAdvancement and CharacterAdvancement:IsVisible() then
			CharacterAdvancement:PlayAnimationForToken(tokenType, specID, count)
		end
	end

	local token = TokenUtil.CreateFromTokenType(tokenType)
	SendLootMessage(token:GetLink(), newAmount-oldAmount)
end

function TokenUtil:SCROLL_OF_FORTUNE_USED()
	showCANextUpdate = true
	EventRegistry:UnregisterFrameEventAndCallback("SCROLL_OF_FORTUNE_USED", TokenUtil.SCROLL_OF_FORTUNE_USED)
end

function TokenUtil:CASE_OF_FORTUNE_USED()
	TokenUtil.TimeSinceCaseOfFortuneUsed = TimeSince:Now()
end

GetTokenCount = TokenUtil.GetTokenCount
GetTokenLink = TokenUtil.GetTokenLink

EventRegistry:RegisterFrameEventAndCallback("TOKEN_UPDATED", TokenUtil.TOKEN_UPDATED)
EventRegistry:RegisterFrameEventAndCallback("CASE_OF_FORTUNE_USED", TokenUtil.CASE_OF_FORTUNE_USED)
EventRegistry:RegisterFrameEventAndCallback("SCROLL_OF_FORTUNE_USED", TokenUtil.SCROLL_OF_FORTUNE_USED)

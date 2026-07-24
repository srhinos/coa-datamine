-- functions to manage tab interfaces where only one tab of a group may be selected
function PanelTemplates_Tab_OnClick(self, frame)
	PanelTemplates_SetTab(frame, self:GetID())
end

function PanelTemplates_SetTab(frame, id)
	frame.selectedTab = id;
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_GetSelectedTab(frame)
	return frame.selectedTab;
end

function PanelTemplates_UpdateTabs(frame)
	if ( frame.selectedTab ) then
		local tab;
		for i=1, frame.numTabs, 1 do
			tab = _G[frame:GetName().."Tab"..i];
			if ( tab.isDisabled ) then
				PanelTemplates_SetDisabledTabState(tab);
			elseif ( i == frame.selectedTab ) then
				PanelTemplates_SelectTab(tab);
			else
				PanelTemplates_DeselectTab(tab);
			end
		end
	end
end

function PanelTemplates_GetTabWidth(tab)
	local tabName = tab:GetName();

	local sideWidths = 2 * _G[tabName.."Left"]:GetWidth();
	return tab:GetTextWidth() + sideWidths;
end

function PanelTemplates_TabResize(tab, padding, absoluteSize, maxWidth, absoluteTextSize)
	local tabName = tab:GetName();
	
	local buttonMiddle = _G[tabName.."Middle"];
	local buttonMiddleDisabled = _G[tabName.."MiddleDisabled"];
	local sideWidths = 2 * _G[tabName.."Left"]:GetWidth();
	local tabText = _G[tab:GetName().."Text"];
	local width, tabWidth;
	local textWidth;
	if ( absoluteTextSize ) then
		textWidth = absoluteTextSize;
	else
		textWidth = tabText:GetWidth();
	end
	-- If there's an absolute size specified then use it
	if ( absoluteSize ) then
		if ( absoluteSize < sideWidths) then
			width = 1;
			tabWidth = sideWidths
		else
			width = absoluteSize - sideWidths;
			tabWidth = absoluteSize
		end
		tabText:SetWidth(width);
	else
		-- Otherwise try to use padding
		if ( padding ) then
			width = textWidth + padding;
		else
			width = textWidth + 24;
		end
		-- If greater than the maxWidth then cap it
		if ( maxWidth and width > maxWidth ) then
			if ( padding ) then
				width = maxWidth + padding;
			else
				width = maxWidth + 24;
			end
			tabText:SetWidth(width);
		else
			tabText:SetWidth(0);
		end
		tabWidth = width + sideWidths;
	end
	
	if ( buttonMiddle ) then
		buttonMiddle:SetWidth(width);
	end
	if ( buttonMiddleDisabled ) then
		buttonMiddleDisabled:SetWidth(width);
	end
	
	tab:SetWidth(tabWidth);
	local highlightTexture = _G[tabName.."HighlightTexture"];
	if ( highlightTexture ) then
		highlightTexture:SetWidth(tabWidth);
	end
end

function PanelTemplates_SetNumTabs(frame, numTabs)
	frame.numTabs = numTabs;
end

function PanelTemplates_DisableTab(frame, index)
	_G[frame:GetName().."Tab"..index].isDisabled = 1;
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_IsTabEnabled(frame, index)
	return not _G[frame:GetName().."Tab"..index].isDisabled;
end

function PanelTemplates_HideTab(frame, index)
	local tab = _G[frame:GetName().."Tab"..index];
	tab:Hide();
end

function PanelTemplates_ShowTab(frame, index)
	local tab = _G[frame:GetName().."Tab"..index];
	tab:Show();
end

function PanelTemplates_EnableTab(frame, index)
	local tab = _G[frame:GetName().."Tab"..index];
	tab.isDisabled = nil;
	-- Reset text color
	tab:SetDisabledFontObject(GameFontHighlightSmall);
	PanelTemplates_UpdateTabs(frame);
end

function PanelTemplates_DeselectTab(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Show();
	_G[name.."Middle"]:Show();
	_G[name.."Right"]:Show();
	--tab:UnlockHighlight();
	tab:Enable();
	_G[name.."LeftDisabled"]:Hide();
	_G[name.."MiddleDisabled"]:Hide();
	_G[name.."RightDisabled"]:Hide();
end

function PanelTemplates_SelectTab(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Hide();
	_G[name.."Middle"]:Hide();
	_G[name.."Right"]:Hide();
	--tab:LockHighlight();
	tab:Disable();
	tab:SetDisabledFontObject(GameFontHighlightSmall);
	_G[name.."LeftDisabled"]:Show();
	_G[name.."MiddleDisabled"]:Show();
	_G[name.."RightDisabled"]:Show();
	
	if ( GameTooltip:IsOwned(tab) ) then
		GameTooltip:Hide();
	end
end

function PanelTemplates_SetDisabledTabState(tab)
	local name = tab:GetName();
	_G[name.."Left"]:Show();
	_G[name.."Middle"]:Show();
	_G[name.."Right"]:Show();
	--tab:UnlockHighlight();
	tab:Disable();
	tab.text = tab:GetText();
	-- Gray out text
	tab:SetDisabledFontObject(GameFontDisableSmall);
	_G[name.."LeftDisabled"]:Hide();
	_G[name.."MiddleDisabled"]:Hide();
	_G[name.."RightDisabled"]:Hide();
end

UIFrameCache = CreateFrame("FRAME");
local caches = {};
function UIFrameCache:New (frameType, baseName, parent, template)
	if ( self ~= UIFrameCache ) then
		error("Attempt to run factory method on class member");
	end
	
	local frameCache = {};

	setmetatable(frameCache, self);
	self.__index = self;
	
	frameCache.frameType = frameType;
	frameCache.baseName = baseName;
	frameCache.parent = parent;
	frameCache.template = template;
	frameCache.frames = {};
	frameCache.usedFrames = {};
	frameCache.numFrames = 0;
	frameCache.shitFrameCache = true

	tinsert(caches, frameCache);
	
	return frameCache;
end

function UIFrameCache:GetFrame ()
	local frame = self.frames[1];
	if ( frame ) then
		tremove(self.frames, 1);
		tinsert(self.usedFrames, frame);
		return frame;
	end
	
	frame = CreateFrame(self.frameType, self.baseName .. self.numFrames + 1, self.parent, self.template);
	frame.frameCache = self;
	self.numFrames = self.numFrames + 1;
	tinsert(self.usedFrames, frame);
	return frame;
end

function UIFrameCache:ReleaseFrame (frame)
	for k, v in next, self.frames do
		if ( v == frame ) then
			return;
		end
	end
	
	for k, v in next, self.usedFrames do
		if ( v == frame ) then
			tinsert(self.frames, frame);
			tremove(self.usedFrames, k);
			break;
		end
	end	
end

-- positionFunc = Callback to determine the visible buttons.
--		arguments: scroll value
--		must return: index of the topmost visible button (or nil if there are no buttons)
--					 the total height used by all buttons prior to topmost
--					 the total height of all the buttons
-- buttonFunc = Callback to configure each button
--		arguments: button, button index, first button
--			NOTE: first button is true if this is the first button in a rendering pass. For scrolling optimization, positionFunc may be called without subsequent calls to buttonFunc.
--		must return: height of button
function DynamicScrollFrame_CreateButtons(self, buttonTemplate, minButtonHeight, buttonFunc, positionFunc)
	if ( self.buttons ) then
		return;
	end

	local scrollChild = self.scrollChild;
	local scrollHeight = self:GetHeight();
	local buttonName = self:GetName().."Button";
	local buttons = { };
	local numButtons;
	
	local button = CreateFrame("BUTTON", buttonName.."1", scrollChild, buttonTemplate);
	button:SetPoint("TOPLEFT", 0, 0);
	tinsert(buttons, button);
	numButtons = math.ceil(scrollHeight / minButtonHeight) + 3;
	for i = 2, numButtons do
		button = CreateFrame("BUTTON", buttonName..i, scrollChild, buttonTemplate);
		button:SetPoint("TOPLEFT", buttons[i-1], "BOTTOMLEFT", 0, 0);
		tinsert(buttons, button);
	end
	self.buttons = buttons;
	self.numButtons = numButtons;
	self.usedButtons = 0;
	self.buttonFunc = buttonFunc;
	self.positionFunc = positionFunc;
	self.scrollHeight = scrollHeight;
	-- optimization vars
	self.lastOffset = -1;
	self.topIndex = -1;
	self.nextButtonOffset = -1;
end

function DynamicScrollFrame_OnVerticalScroll(self, offset)
	offset = math.floor(offset + 0.5);
	if ( offset ~= self.lastOffset ) then
		local scrollBar = self.scrollBar;
		local min, max = scrollBar:GetMinMaxValues();
		scrollBar:SetValue(offset);
		if ( offset == 0 ) then
			_G[scrollBar:GetName().."ScrollUpButton"]:Disable();
		else
			_G[scrollBar:GetName().."ScrollUpButton"]:Enable();
		end
		if ( offset == math.floor(max + 0.5) ) then
			_G[scrollBar:GetName().."ScrollDownButton"]:Disable();
		else
			_G[scrollBar:GetName().."ScrollDownButton"]:Enable();
		end
		self.lastOffset = offset;
		DynamicScrollFrame_Update(self, offset, true);
	end
end

function DynamicScrollFrame_Update(self, scrollValue, isScrollUpdate)
	if ( not self.positionFunc ) then
		return;
	end
	if ( not scrollValue ) then
		scrollValue = floor(self.scrollBar:GetValue() + 0.5);
	end
	local buttonIndex = 0;
	local buttons = self.buttons;
	local topIndex, heightUsed, totalHeight = self.positionFunc(scrollValue);
	if ( topIndex ) then
		if ( isScrollUpdate and self.topIndex == topIndex and ( self.nextButtonOffset == 0 or scrollValue < self.nextButtonOffset ) ) then
			return;
		end
		self.allowedRange = totalHeight - self.scrollHeight;		-- temp fix to jitter scroll (see task 39261)
		self.topIndex = topIndex;
		local button;
		local buttonFunc = self.buttonFunc;
		local buttonHeight;
		local visibleRange = scrollValue + self.scrollHeight;
		if ( topIndex > 1 ) then
			buttons[1]:SetHeight(heightUsed);
			buttons[1]:Show();
			buttonIndex = 1;
		end
		for dataIndex = topIndex, topIndex + self.numButtons - 1 do
			buttonIndex = buttonIndex + 1;
			button = buttons[buttonIndex];
			buttonHeight = buttonFunc(button, dataIndex, (dataIndex == topIndex));
			button:SetHeight(buttonHeight);
			heightUsed = heightUsed + buttonHeight;
			if ( heightUsed >= totalHeight ) then
				self.nextButtonOffset = 0;
				break;
			elseif ( heightUsed >= visibleRange ) then
				buttonIndex = buttonIndex + 1;
				button = buttons[buttonIndex];
				button:SetHeight(totalHeight - heightUsed);
				button:Show();
				self.nextButtonOffset = floor(scrollValue + heightUsed - visibleRange);
				break;
			end
		end
	end
	for i = buttonIndex + 1, self.numButtons do
		buttons[i]:Hide();
	end
	self.usedButtons = buttonIndex;
end

function DynamicScrollFrame_UnlockAllHighlights(self)
	local buttons = self.buttons;
	for i = 1, self.usedButtons do
		buttons[i]:UnlockHighlight();
	end
end

QuestAlertMixin = {}

function QuestAlertMixin:SetQuest(id)
	self.quest = id
	if C_Quest:HasOrHasDoneQuest(self.quest) then
		self:Hide()
	end
end

function QuestAlertMixin:SetQuestLevel(level)
	self.level = level
	self:SetEnabled(C_Player:GetLevel() >= self.level)
end

function QuestAlertMixin:OnClick()
	if self.quest then
		if C_Quest:AddAutoQuestPopUp(self.quest) then
			self:Hide()
		end
	end
end

function QuestAlertMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self:IsEnabled() == 1 then
		GameTooltip:SetText(QUEST_AVAILABLE)
	elseif self.level then
		GameTooltip:SetText(format(QUEST_UNLOCKS_AT, self.level), 1, 0, 0)
	else
		GameTooltip:SetText(QUEST_DONT_MEET_REQUIREMENTS, 1, 0, 0)
	end
	GameTooltip:Show()
end 

function QuestAlertMixin:OnLeave()
	GameTooltip:Hide()
end

function QuestAlertMixin:OnDisable()
	self.Icon:SetDesaturated(true)
	self.Border:SetDesaturated(true)
	self.Glow:Hide()
end

function QuestAlertMixin:OnEnable()
	self.Icon:SetDesaturated(false)
	self.Border:SetDesaturated(false)
	self.Glow:Show()
end

function QuestAlertMixin:OnShow()
	if self.level then
		self:SetEnabled(C_Player:GetLevel() >= self.level)
	end

	if self.quest and C_Quest:HasOrHasDoneQuest(self.quest) then
		self:Hide()
	end
end

IconSelectorMixin = CreateFromMixins(CallbackRegistryMixin)
local ICONS_NUM_COLUMNS = 9
local ICONS_TOTAL = 81
local ICON_SIZE = 36
function IconSelectorMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({
		"IconSelected",
	})
	local iconSize = tonumber(self:GetAttribute("icon-size")) or ICON_SIZE
	local totalIcons = tonumber(self:GetAttribute("icon-total")) or ICONS_TOTAL
	local numColumns = tonumber(self:GetAttribute("num-columns")) or ICONS_NUM_COLUMNS
	self.iconSize = iconSize
	self.totalIcons = totalIcons
	self.numColumns = numColumns

	for i = 1, totalIcons do
		local button = CreateFrame("BUTTON", "$parentIcon"..i, self, "BorderIconTemplate")
		button:SetID(i)
		button:SetSize(iconSize, iconSize)
		button:SetScript("OnClick", function(button)
			self:SelectIcon(button.index)
		end)

		if i % numColumns == 1 then
			button:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, -iconSize * math.floor(i / numColumns))
		else
			button:SetPoint("LEFT", "$parentIcon"..(i-1), "RIGHT", 0, 0)
		end
	end
end 

function IconSelectorMixin:OnShow()
	self:Update()
end

function IconSelectorMixin:SetSelectedIcon(iconTexture)
	self.selectedIndex = nil
	for i = 1, self.iconCountProvider and self.iconCountProvider() or GetNumMacroIcons() do
		local texture = self.iconProvider and self.iconProvider(i) or GetMacroIconInfo(i)
		if texture == iconTexture then
			self.selectedIndex = i
			break
		end
	end
	
	self:Update()
end

function IconSelectorMixin:SelectIcon(index)
	local texture = self.iconProvider and self.iconProvider(index) or GetMacroIconInfo(index)
	self:SetSelectedIcon(texture)

	if self:GetAttribute("dont-auto-close") == true then
		return
	end

	self:TriggerEvent("IconSelected", texture, index)
	self:Hide()
end 

function IconSelectorMixin:GetSelectedIndex()
	return self.selectedIndex
end

function IconSelectorMixin:Update()
	local numMacroIcons = self.iconCountProvider and self.iconCountProvider() or GetNumMacroIcons()
	local offset = FauxScrollFrame_GetOffset(self.ScrollFrame)
	local texture, icon, index

	for i=1, self.totalIcons do
		icon = _G[self:GetName().."Icon"..i]
		index = (offset * self.numColumns) + i
		texture = self.iconProvider and self.iconProvider(index) or GetMacroIconInfo(index)
		if index <= numMacroIcons then
			icon:SetIcon(texture)
			icon:Show()
			if self.selectedIndex == index then
				icon:SetBorderAtlas("bags-glow-artifact")
			else
				icon:SetBorderTexture(nil)
			end
		else
			icon:Hide()
		end
		icon.index = index
	end
	FauxScrollFrame_Update(self.ScrollFrame, math.ceil(numMacroIcons / self.numColumns), self.totalIcons, self.iconSize)
end

function IconSelectorMixin:SetIconProvider(provider)
	self.iconProvider = provider
end

function IconSelectorMixin:SetIconCountProvider(provider)
	self.iconCountProvider = provider
end

ScrollableTextMixin = {}

function ScrollableTextMixin:OnLoad()
	self.ScrollFrame.Child:SetHyperlinksEnabled(true)
	self.ScrollFrame.Child:SetJustifyH("LEFT")
	self.ScrollFrame.Child:SetJustifyV("TOP")
	self.ScrollFrame.Child:SetWidth(self.ScrollFrame:GetWidth())
	self.ScrollFrame.Child.HiddenText:SetWidth(self.ScrollFrame:GetWidth())
	self.ScrollFrame.Child:SetHeight(self.ScrollFrame.Child.HiddenText:GetStringHeight())
	local font = self:GetAttribute("font")
	if font and font ~= "" then
		self:SetFontObject(font)
	end
end

function ScrollableTextMixin:OnSizeChanged(x)
	x = MClamp(x-33, 0, x)
	self.ScrollFrame.Child:SetWidth(x)
	self.ScrollFrame.Child.HiddenText:SetWidth(x)
	self.ScrollFrame.Child:SetHeight(self.ScrollFrame.Child.HiddenText:GetStringHeight())
end

function ScrollableTextMixin:SetText(text)
	text = text:gsub("(https://db.ascension.gg/%S+)", LinkUtil.ConvertDBUrlToHyperlink)
	self.ScrollFrame.Child:SetHeight(2000)
	self.ScrollFrame.Child.HiddenText:Show()
	self.ScrollFrame.Child.HiddenText:SetText(text)
	self.ScrollFrame.Child:SetText(text)
	local height = self.ScrollFrame.Child.HiddenText:GetStringHeight()
	self.ScrollFrame.Child:SetHeight(height)
	self.ScrollFrame.Child.HiddenText:Hide()

	if height > self.ScrollFrame:GetHeight() then
		self.ScrollFrame.ScrollBar:Show()
	else
		self.ScrollFrame.ScrollBar:Hide()
	end
end 

function ScrollableTextMixin:SetFontObject(fontObject)
	self.ScrollFrame.Child:SetFontObject(fontObject)
end

function ScrollableTextMixin:SetTextColor(r, g, b, a)
	self.ScrollFrame.Child:SetTextColor(r, g, b, a)
end 

function ScrollableTextMixin:ResetToTop()
	self.ScrollFrame.ScrollBar:SetValue(0)
end

local function ResetRarityGem(pool, frame)
	frame.AnimateOnShow = nil
	frame:Hide()
	frame:SetParent(nil)
	frame:ClearAllPoints()
end

local RarityGemPool = CreateFramePool("BUTTON", nil, "RarityGemTemplate", ResetRarityGem)

RarityGemContainerMixin = {}

RarityGemContainerMixin.Orientation = {
	VerticalBottomToTop = { "BOTTOMLEFT", "TOPLEFT", 0, 0 },
	VerticalTopToBottom = { "TOPLEFT", "BOTTOMLEFT", 0, 0 },
	HorizontalLeftToRight = { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 0 },
	HorizontalRightToLeft = { "BOTTOMRIGHT", "BOTTOMLEFT", 0, 0 },
}

-- centered moves the offset of the container to center gems.
-- they still fill left to right
RarityGemContainerMixin.Orientation.Centered = RarityGemContainerMixin.Orientation.HorizontalLeftToRight

function RarityGemContainerMixin:OnLoad()
	self.gemSize = 22
	self.numGems = 0
	self.numActiveGems = 0
	self.quality = Enum.ItemQuality.Common
	self.orientation = RarityGemContainerMixin.Orientation.HorizontalLeftToRight
end

function RarityGemContainerMixin:SetOrientation(orientation)
	self.orientation = orientation
	self:Update()
end

function RarityGemContainerMixin:SetGemSize(size)
	self.gemSize = size
	if self:IsShown() then
		self:Update()
	end
end

function RarityGemContainerMixin:OnShow()
	self:Update()
end

function RarityGemContainerMixin:OnHide()
	RarityGemPool:ReleaseAllWithParent(self)
end

function RarityGemContainerMixin:PlayAnimation()
	for gem in RarityGemPool:EnumerateActiveWithParent(self) do
		gem:PlayAnimation()
	end
end

function RarityGemContainerMixin:Update()
	self:UpdateGems()
end

function RarityGemContainerMixin:UpdateGems()
	RarityGemPool:ReleaseAllWithParent(self)
	self:ResetPointsOffset()

	local orientation = self.orientation
	local size = math.max(self.gemSize * self.numGems, 1)

	if orientation == RarityGemContainerMixin.Orientation.Centered then
		self:SetSize(size, self.gemSize)
	elseif orientation ==  RarityGemContainerMixin.Orientation.VerticalBottomToTop then
		self:SetSize(self.gemSize, size)
	elseif orientation == RarityGemContainerMixin.Orientation.VerticalTopToBottom then
		self:SetSize(self.gemSize, size)
	elseif orientation == RarityGemContainerMixin.Orientation.HorizontalLeftToRight then
		self:SetSize(size, self.gemSize)
	elseif orientation == RarityGemContainerMixin.Orientation.HorizontalRightToLeft then
		self:SetSize(size, self.gemSize)
	else -- assume horizontal
		self:SetSize(size, self.gemSize)
	end
	local point, relPoint, xAdd, yAdd = unpack(orientation)
	
	local lastGem
	for i = 1, self.numGems do
		local gem = RarityGemPool:Acquire()
		gem:SetParent(self)
		gem:SetSize(self.gemSize, self.gemSize)
		if not lastGem then
			gem:SetPoint(point, self, point, 0, 0)
		else
			gem:SetPoint(point, lastGem, relPoint, xAdd, yAdd)
		end

		gem:SetQuality(self.quality)
		gem:SetActive(i <= self.numActiveGems)
		gem:SetScript("OnClick", self.clickHandler)
		gem:SetScript("OnEnter", self.onEnterHandler)
		gem:SetScript("OnLeave", self.onLeaveHandler)
		
		gem:Show()
		lastGem = gem
	end
	
	if self.orientation == RarityGemContainerMixin.Orientation.Centered then
		local offset = ((self.numGems - 1) * xAdd) / 2
		self:SetPointOffset(-offset, 0)
	end
end

function RarityGemContainerMixin:SetNumGems(numGems, numActiveGems)
	self.numGems = numGems or 0
	self.numActiveGems = numActiveGems or 0
	if self:IsVisible() then
		self:Update()
	end
end

function RarityGemContainerMixin:SetGemQuality(quality)
	self.quality = quality
	if self:IsVisible() then
		self:Update()
	end
end

function RarityGemContainerMixin:SetGemClickHandler(handler)
	self.clickHandler = handler
end

function RarityGemContainerMixin:SetGemOnEnterHandler(handler)
	self.onEnterHandler = handler
end

function RarityGemContainerMixin:SetGemOnLeaveHandler(handler)
	self.onLeaveHandler = handler
end

RarityGemMixin = {}

function RarityGemMixin:OnLoad()
	self.Border:SetAtlas("rarity-gem-border", Const.TextureKit.IgnoreAtlasSize)
	self:SetNormalAtlas("rarity-gem")
	self.Sparkle:SetAtlas("rarity-gem-flash", Const.TextureKit.IgnoreAtlasSize)
end 

function RarityGemMixin:OnShow()
	if self.AnimateOnShow then
		self:PlayAnimation()
	end
end

function RarityGemMixin:PlayAnimation()
	if not self:IsVisible() then
		self.AnimateOnShow = true
		return
	end
	self.AnimateOnShow = nil
	self.Sparkle.Anim:Stop()
	self.Flash.Anim:Stop()
	self.Sparkle.Anim:Play()
	self.Flash.Anim:Play()
end

function RarityGemMixin:SetQuality(quality)
	self:SetColor(ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1])
end

function RarityGemMixin:SetColor(color)
	self.color = color
	if self:IsEnabled() == 1 then
		self:GetNormalTexture():SetVertexColor(self.color.r, self.color.g, self.color.b)
		self.Sparkle:SetVertexColor(self.color.r, self.color.g, self.color.b)
		self.Flash:SetVertexColor(self.color.r, self.color.g, self.color.b)
	end
end 

function RarityGemMixin:SetActive(active)
	if active then
		local r, g, b = self.color.r, self.color.g, self.color.b
		self:GetNormalTexture():SetVertexColor(r, g, b)
		self.Sparkle:SetVertexColor(r, g, b)
		self.Flash:SetVertexColor(r, g, b)
		self.Sparkle:Show()
	else
		self:GetNormalTexture():SetVertexColor(0, 0, 0)
		self.Sparkle:SetVertexColor(0.1, 0.1, 0.1)
		self.Flash:SetVertexColor(0.1, 0.1, 0.1)
	end
end

SmallLockButtonMixin = CreateFromMixins(CallbackRegistryMixin)

function SmallLockButtonMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:GenerateCallbackEvents({
		"OnLocked",
		"OnUnlocked",
	})
end

function SmallLockButtonMixin:OnEnter()
	self.Highlight:Show()
end

function SmallLockButtonMixin:OnLeave()
	self.Highlight:Hide()
	GameTooltip:Hide()
end

function SmallLockButtonMixin:OnClick()
	if self:GetChecked() then
		self:SetLocked()
		self:TriggerEvent("OnLocked")
		PlaySound("igMainMenuOptionCheckBoxOn")
	else
		self:SetUnlocked()
		self:TriggerEvent("OnUnlocked")
		PlaySound("igMainMenuOptionCheckBoxOff")
	end

	if (self:IsMouseOver()) then
		self:OnEnter()
	end
end

function SmallLockButtonMixin:SetLocked()
	self.UnlockedTexture:Hide()
	self.LockedTexture:Show()
end

function SmallLockButtonMixin:SetUnlocked()
	self.UnlockedTexture:Show()
	self.LockedTexture:Hide()
end

AnimatedRankMixin = CreateFromMixins(CallbackRegistryMixin)

function AnimatedRankMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)

	self:GenerateCallbackEvents({
		"OnRankChange",
		"OnRankChangeFinished",
	})

	self:RegisterCallback("OnRankChange", self.OnRankChange, self)

	local rankFontObject = self:GetAttribute("rankFontObject")

	if (rankFontObject) then
		self.Rank:SetFontObject(rankFontObject)
	end
end

function AnimatedRankMixin:SetRank(value)
	self.rank = value
end

function AnimatedRankMixin:SetMaxRank(value)
	self.maxRank = value
end

function AnimatedRankMixin:SetNextRank(value)
	self.nextRank = value
end

function AnimatedRankMixin:GetRank()
	return self.rank or 0
end

function AnimatedRankMixin:GetMaxRank()
	return self.maxRank
end

function AnimatedRankMixin:GetNextRank()
	return self.nextRank
end

function AnimatedRankMixin:OnRankChange(oldRank, nextRank)
	if (nextRank) then
		self:SetNextRank(nil)
		self:SetRank(nextRank)
		self:UpdateVisual()
	end
end

function AnimatedRankMixin:UpdateVisual()
	local rank = self:GetRank()
	local maxRank = self:GetMaxRank()
	local color = NORMAL_FONT_COLOR
	local text

	if (maxRank) then
		if rank < maxRank then
			color = GREEN_FONT_COLOR
		end

		text = rank.."/"..maxRank
		self:SetWidth(58)
	else
		self:SetWidth(36)
	end

	if (rank == 0) then
		color = DISABLED_FONT_COLOR
	end

	if (color == DISABLED_FONT_COLOR) then
		self.RankBorder:SetDesaturated(true)
	else
		self.RankBorder:SetDesaturated(false)
		self.RankBorder:SetVertexColor(color:GetRGB())
	end

	self.Rank:SetTextColor(color:GetRGB())
	self.Rank:SetText(text)
end

function AnimatedRankMixin:StopAnim()
	self.RankGlow.Anim:Stop()
	self.RankQualityOutline.Anim:Stop()
	self.Rank.Fade:Stop()
	self.Jiggle:Stop()
	self.Reveal:Stop()
end

function AnimatedRankMixin:PlayAnim()
	self:StopAnim()
	self.Reveal:Play()
end

SimpleRankMixin = {}

function SimpleRankMixin:OnLoad()
	self.showMaxRank = true
	self.maxRankSeparator = " / "
end

function SimpleRankMixin:ShowMaxRank(showMaxRank)
	self.showMaxRank = showMaxRank
	self:UpdateVisual()
end

function SimpleRankMixin:SetMaxRankSeparator(separator)
	self.maxRankSeparator = separator or " / "
	self:UpdateVisual()
end

function SimpleRankMixin:SetRank(rank)
	self.rank = rank
	self:UpdateVisual()
end

function SimpleRankMixin:SetMaxRank(rank)
	self.maxRank = rank
	self:UpdateVisual()
end

function SimpleRankMixin:UpdateVisual()
	if self.maxRank and self.showMaxRank then
		self.Rank:SetText((self.rank or 0)..self.maxRankSeparator..self.maxRank)
	else
		self.Rank:SetText(self.rank or "")
	end
end

AnimatedFontChildMixin = {}

function AnimatedFontChildMixin:InitAnimation(animTime, animatedFontObject, fontHeight)
	self.animTime = animTime or 0.5
	self.timer = 0
	self.animatedFontObject = animatedFontObject

	self.fontHeight = fontHeight 

	if not(self.fontHeight) then
		local _, fontHeight = GameFontHighlight:GetFont()
		self.fontHeight = fontHeight
	end
end

function AnimatedFontChildMixin:PlayFontObjectAnimation()
	self.timer = 0
	self:SetScript("OnUpdate", AnimatedFontChildMixin.OnUpdateScaleChange)
end

function AnimatedFontChildMixin:ExitAnimation()
	self.animatedFontObject:SetTextHeight(self.fontHeight)
	self.animatedFontObject:SetAlpha(1)
	self:SetScript("OnUpdate", nil)
end

-- Scale down effect becuase font string does not support Scale animations
function AnimatedFontChildMixin:OnUpdateScaleChange(elapsed)
	if not(self.animatedFontObject) then
		self:SetScript("OnUpdate", nil)
		return
	end

	if (self.timer <= self.animTime) then
		self.timer = self.timer + elapsed

		local modifier = self.timer/self.animTime
		self.animatedFontObject:SetAlpha(math.min(1, modifier))
		self.animatedFontObject:SetTextHeight(math.max(self.fontHeight, self.fontHeight*(2-(modifier*2.5))))
		return
	end

	AnimatedFontChildMixin.ExitAnimation(self)
end

GarrisonFollowerLevelUpMixin = {}

function GarrisonFollowerLevelUpMixin:OnLoad()
	self.LevelupLines1:SetAtlas("Garr_MissionFX-Lines", Const.TextureKit.UseAtlasSize)
	self.LevelupLines2:SetAtlas("Garr_MissionFX-Lines", Const.TextureKit.UseAtlasSize)
	self.LevelupLines3:SetAtlas("Garr_MissionFX-Lines", Const.TextureKit.UseAtlasSize)
	self.Banner:SetAtlas("GarrMission_LevelUpBanner", Const.TextureKit.UseAtlasSize)
	self.BannerGlow:SetAtlas("GarrMission_LevelUpBanner", Const.TextureKit.UseAtlasSize)
	self.LevelupGlow:SetAtlas("Garr_MissionFX-Glow", Const.TextureKit.UseAtlasSize)
end

RatingButtonBaseMixin = {}

function RatingButtonBaseMixin:OnLoad()
end

function RatingButtonBaseMixin:SetActive(active)
	self.active = active
end

function RatingButtonBaseMixin:SetRatingIndex(index)
	self.layoutIndex = index
end

function RatingButtonBaseMixin:GetRatingIndex()
	return self.layoutIndex
end

function RatingButtonBaseMixin:OnClick()
	self:GetParent():SetRating(self:GetRatingIndex())
end

HorizontalRatingMixin = CreateFromMixins("HorizontalLayoutMixin")

function HorizontalRatingMixin:OnLoad()
	HorizontalLayoutMixin.OnLoad(self)
	AttributesToKeyValues(self)
end

function HorizontalRatingMixin:GetPool()
	self.pool = self.pool or CreateFramePool("BUTTON", self, self.ratingTemplate)
	return self.pool
end

function HorizontalRatingMixin:EnumerateRatings()
	return self.pool:EnumerateActive()
end

function HorizontalRatingMixin:OnShow()
	self:SetRating(self.rating or 1, self.maxRating or 1)
end

function HorizontalRatingMixin:SetRating(rating, maxRating)
	self.rating = rating
	if maxRating then
		-- remake only if max rating changes
		self.maxRating = maxRating
		local pool = self:GetPool()
		pool:ReleaseAll()

		local ratingButton
		for i = 1, maxRating do
			ratingButton = pool:Acquire()
			ratingButton:SetRatingIndex(i)
			ratingButton:SetActive(i <= rating)
			ratingButton:Show()
		end
	else
		for ratingButton in self:EnumerateRatings() do
			ratingButton:SetActive(ratingButton:GetRatingIndex() <= rating)
		end
	end
	
	self:MarkDirty()
end

function HorizontalRatingMixin:GetRating()
	return self.rating, self.maxRating
end

StarRatingButtonMixin = CreateFromMixins("RatingButtonBaseMixin")

function StarRatingButtonMixin:OnLoad()
	RatingButtonBaseMixin.OnLoad(self)
	self:SetNormalAtlas("auctionhouse-icon-favorite")
	self:SetHighlightAtlas("auctionhouse-icon-favorite")
end

function StarRatingButtonMixin:SetActive(active)
	RatingButtonBaseMixin.SetActive(self, active)

	if active then
		self:SetNormalAtlas("auctionhouse-icon-favorite")
		self:SetHighlightAtlas("auctionhouse-icon-favorite")
	else
		self:SetNormalAtlas("auctionhouse-icon-favorite-off")
		self:SetHighlightAtlas("auctionhouse-icon-favorite-off")
	end
end 

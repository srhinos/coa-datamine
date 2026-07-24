local QUEST_POI_BUTTONS_MAX = { };				-- max of a button created
local QUEST_POI_BUTTONS_SELECTED = { };			-- selected button
QUEST_POI_SWAP_BUTTONS = { };				-- buttons that need to swap in (for QUEST_POI_COMPLETE_SWAP type)
QUEST_POI_ICONS_PER_ROW = 8;
QUEST_POI_ICON_SIZE = 0.125;

-- POI types
local QUEST_POI_MAX_TYPES = 4;
QUEST_POI_NUMERIC = 1;				-- number within a circle
QUEST_POI_COMPLETE_IN = 2;			-- completed quest icon within a normal circle
QUEST_POI_COMPLETE_OUT = 3;			-- completed quest icon within a darker circle (quest outside current zone)
QUEST_POI_COMPLETE_SWAP = 4;		-- completed quest icon without a circle that needs to be swapped on selection (for map)

-- POI text colors (offsets into texture)
local QUEST_POI_COLOR_BLACK = 0;
local QUEST_POI_COLOR_YELLOW = 0.5;

QUEST_POI_TYPES = {
	Normal = 1,
	Campaign = 2,
	Important = 3,
}


local function QuestPOIButton_GetTextureInfoNormal(poiButton)
	if poiButton.isSelected then
		return "Interface/WorldMap/UI-QuestPoi-NumberIcons", 0.500, 0.625, 0.375, 0.5;
	else
		return "Interface/WorldMap/UI-QuestPoi-NumberIcons", 0.500, 0.625, 0.875, 1.0;
	end
end

local function QuestPOIButton_GetTextureInfoPushed(poiButton)
	if poiButton.isSelected then
		return "Interface/WorldMap/UI-QuestPoi-NumberIcons", 0.375, 0.500, 0.375, 0.5;
	else
		return "Interface/WorldMap/UI-QuestPoi-NumberIcons", 0.375, 0.500, 0.875, 1.0;
	end
end

local function QuestPOIButton_GetTextureInfoHighlight(poiButton)
	return "Interface/WorldMap/UI-QuestPoi-NumberIcons", 0.625, 0.750, 0.375, 0.5;
end

local function QuestPOIButton_GetCampaignAtlasInfoNormal(poiButton)
	if poiButton.isSelected then
		return "UI-QuestPoiCampaign-QuestNumber-SuperTracked";
	else
		return "UI-QuestPoiCampaign-QuestNumber";
	end
end

local function QuestPOIButton_GetCampaignAtlasInfoPushed(poiButton)
	if poiButton.isSelected then
		return "UI-QuestPoiCampaign-QuestNumber-Pressed-SuperTracked";
	else
		return "UI-QuestPoiCampaign-QuestNumber-Pressed";
	end
end

local function QuestPOIButton_GetImportantAtlasInfoNormal(poiButton)
	if poiButton.isSelected then
		return "UI-QuestPoiImportant-QuestNumber-SuperTracked";
	else
		return "UI-QuestPoiImportant-QuestNumber";
	end
end

local function QuestPOIButton_GetImportantAtlasInfoPushed(poiButton)
	if poiButton.isSelected then
		return "UI-QuestPoiImportant-QuestNumber-Pressed-SuperTracked";
	else
		return "UI-QuestPoiImportant-QuestNumber-Pressed";
	end
end

local function POIButton_GetQuestCompleteAtlas(poiButton)
	local questID = poiButton.questId
	local isLegendaryQuest = --[[questID and C_QuestLog.IsLegendaryQuest(questID) or]] false;
	return isLegendaryQuest and "UI-QuestPoiLegendary-QuestBangTurnIn" or "UI-QuestIcon-TurnIn-Normal";
end

local function QuestPOIButton_SetTextureSize(texture, width, height)
	if texture then
		texture:SetSize(width, height);
	end
end

local function QuestPOIButton_SetTexture(texture, width, height, file, texLeft, texRight, texTop, texBottom)
	if texture then
		texture:SetTexture(file);
		texture:SetTexCoord(texLeft or 0, texRight or 1, texTop or 0, texBottom or 1);
		QuestPOIButton_SetTextureSize(texture, width, height);
	end
end

local function QuestPOIButton_SetAtlas(texture, width, height, atlas)
	-- Using this with shared controls that may not have all the same children
	if texture then
		local useAtlasSize = not width and not height;
		texture:SetTexCoord(0, 1, 0, 1);
		texture:SetAtlas(atlas, useAtlasSize);

		if not useAtlasSize then
			QuestPOIButton_SetTextureSize(texture, width, height);
		end
	end
end

function QuestPOIButton_UpdateNumericTextures(poiButton)
	poiButton.turnin:Hide()
	poiButton.number:Show()
	local  questType = C_QuestLog.GetQuestType(poiButton.questId)
	if questType == QUEST_POI_TYPES.Campaign or questType == QUEST_POI_TYPES.Calling then
		QuestPOIButton_SetAtlas(poiButton.normalTexture, 32, 32, QuestPOIButton_GetCampaignAtlasInfoNormal(poiButton));
		QuestPOIButton_SetAtlas(poiButton.pushedTexture, 32, 32, QuestPOIButton_GetCampaignAtlasInfoPushed(poiButton));
		QuestPOIButton_SetAtlas(poiButton.highlightTexture, 32, 32, "UI-QuestPoiCampaign-InnerGlow");
	elseif questType == QUEST_POI_TYPES.Important then
		QuestPOIButton_SetAtlas(poiButton.normalTexture, 32, 36, QuestPOIButton_GetImportantAtlasInfoNormal(poiButton));
		QuestPOIButton_SetAtlas(poiButton.pushedTexture, 32, 36, QuestPOIButton_GetImportantAtlasInfoPushed(poiButton));
		QuestPOIButton_SetAtlas(poiButton.highlightTexture, 32, 36, "UI-QuestPoiImportant-InnerGlow");
	else
		QuestPOIButton_SetTexture(poiButton.normalTexture, 32, 32, QuestPOIButton_GetTextureInfoNormal(poiButton));
		QuestPOIButton_SetTexture(poiButton.pushedTexture, 32, 32, QuestPOIButton_GetTextureInfoPushed(poiButton));
		QuestPOIButton_SetTexture(poiButton.highlightTexture, 32, 32, QuestPOIButton_GetTextureInfoHighlight(poiButton));
	end

	QuestPOI_SetTextColor(poiButton, poiButton.isSelected and QUEST_POI_COLOR_BLACK or QUEST_POI_COLOR_YELLOW);
end

function QuestPOIButton_UpdateNormalTextures(poiButton)
	poiButton.number:Hide()
	local questPOIType = C_QuestLog.GetQuestType(poiButton.questId);
	if questPOIType == QUEST_POI_TYPES.Campaign then
		poiButton.Display:SetAtlas(32, 32, "UI-QuestPoiCampaign-QuestBangTurnIn", Const.TextureKit.IgnoreAtlasSize);
	elseif questPOIType == QUEST_POI_TYPES.Calling then
		poiButton.Display:SetAtlas(32, 32, "UI-DailyQuestPoiCampaign-QuestBangTurnIn", Const.TextureKit.IgnoreAtlasSize);
	elseif questPOIType == QUEST_POI_TYPES.Important then
		poiButton.Display:SetAtlas(32, 36, "UI-QuestPoiImportant-QuestBangTurnIn", Const.TextureKit.IgnoreAtlasSize);
	end

	if not questPOIType or (questPOIType == QUEST_POI_TYPES.Normal) then
		QuestPOIButton_SetAtlas(poiButton.turnin, 24, 24, POIButton_GetQuestCompleteAtlas(poiButton));
		poiButton.turnin:Show()
		QuestPOIButton_SetTexture(poiButton.normalTexture, 32, 32, QuestPOIButton_GetTextureInfoNormal(poiButton));
		QuestPOIButton_SetTexture(poiButton.pushedTexture, 32, 32, QuestPOIButton_GetTextureInfoPushed(poiButton));
		QuestPOIButton_SetTexture(poiButton.highlightTexture, 32, 32, QuestPOIButton_GetTextureInfoHighlight(poiButton));
	elseif questPOIType == POIButtonUtil.QuestTypes.Important then
		poiButton.turnin:Hide()
		QuestPOIButton_SetAtlas(poiButton.normalTexture, 32, 36, QuestPOIButton_GetImportantAtlasInfoNormal(poiButton));
		QuestPOIButton_SetAtlas(poiButton.pushedTexture, 32, 36, QuestPOIButton_GetImportantAtlasInfoPushed(poiButton));
		QuestPOIButton_SetAtlas(poiButton.highlightTexture, 32, 36, "UI-QuestPoiImportant-InnerGlow");
	else
		poiButton.turnin:Hide()
		QuestPOIButton_SetAtlas(poiButton.normalTexture, 32, 32, QuestPOIButton_GetCampaignAtlasInfoNormal(poiButton));
		QuestPOIButton_SetAtlas(poiButton.pushedTexture, 32, 32, QuestPOIButton_GetCampaignAtlasInfoPushed(poiButton));
		QuestPOIButton_SetAtlas(poiButton.highlightTexture, 32, 32, "UI-QuestPoiCampaign-InnerGlow");
	end
end

function QuestPOIButton_UpdateButtonStyle(poiButton, buttonType)
	if ( buttonType == QUEST_POI_COMPLETE_IN or buttonType == QUEST_POI_COMPLETE_OUT ) then
		QuestPOIButton_UpdateNormalTextures(poiButton);
	elseif ( buttonType == QUEST_POI_NUMERIC ) then
		QuestPOIButton_UpdateNumericTextures(poiButton);
	end
end

function QuestPOI_DisplayButton(parentName, buttonType, buttonIndex, questId)
	local buttonName = "poi"..parentName..buttonType.."_"..buttonIndex;
	local poiButton = _G[buttonName];
	local swapButton;
	
	if ( not poiButton ) then
		if ( buttonType == QUEST_POI_COMPLETE_SWAP ) then
			poiButton = CreateFrame("Button", buttonName, _G[parentName], "QuestPOICompletedTemplate");
			if ( not QUEST_POI_SWAP_BUTTONS[parentName] ) then
				swapButton = true;
			end
		else
			poiButton = CreateFrame("Button", buttonName, _G[parentName], "QuestPOITemplate");
		end
		-- frame-specific stuff
		if ( parentName == "WatchFrameLines" ) then
			poiButton:SetScale(0.9);
			poiButton:SetScript("OnClick", WatchFrameQuestPOI_OnClick);
		elseif ( parentName == "WorldMapPOIFrame" ) then
			poiButton:SetScript("OnEnter", WorldMapQuestPOI_OnEnter);
			poiButton:SetScript("OnLeave", WorldMapQuestPOI_OnLeave);
			poiButton:SetScript("OnClick", WorldMapQuestPOI_OnClick);
			if ( swapButton ) then
				swapButton = CreateFrame("Button", "poi"..parentName.."_Swap", _G[parentName], "QuestPOITemplate");
				QUEST_POI_SWAP_BUTTONS[parentName] = swapButton;
				swapButton.type = buttonType;
				swapButton:SetScript("OnEnter", WorldMapQuestPOI_OnEnter);
				swapButton:SetScript("OnLeave", WorldMapQuestPOI_OnLeave);
				swapButton:SetScript("OnClick", WorldMapQuestPOI_OnClick);
				swapButton:SetFrameLevel(poiButton:GetFrameLevel() + 2);
				swapButton.selectionGlow:Show();
				swapButton.normalTexture:SetTexCoord(0.500, 0.625, 0.375, 0.5);
				swapButton.pushedTexture:SetTexCoord(0.375, 0.500, 0.375, 0.5);
				swapButton.highlightTexture:SetTexCoord(0.625, 0.750, 0.375, 0.5);
				swapButton.turnin:Show();
				swapButton.number:Hide();		
			end
		end
		-- *
		poiButton.index = buttonIndex;
		poiButton.type = buttonType;
		poiButton.parentName = parentName;
		QUEST_POI_BUTTONS_MAX[parentName..buttonType] = buttonIndex;
	end
	poiButton.questId = questId;
	poiButton.buttonIndex = buttonIndex;
	QuestPOIButton_UpdateButtonStyle(poiButton, buttonType);
	poiButton:Show();
	return poiButton;
end

function QuestPOI_FindButtonByQuestId(parentName, questId)
	local poiButton;
	local numButtons;
		
	for i = 1, QUEST_POI_MAX_TYPES do
		numButtons = QUEST_POI_BUTTONS_MAX[parentName..i];
		if ( numButtons ) then
			for j = 1, numButtons do
				poiButton = _G["poi"..parentName..i.."_"..j];
				if ( poiButton.questId == questId ) then
					return poiButton;
				end
			end
		end
	end
end

function QuestPOI_SelectButtonByIndex(parentName, buttonType, buttonIndex)
	QuestPOI_SelectButton(_G["poi"..parentName..buttonType.."_"..buttonIndex]);
end

function QuestPOI_SelectButtonByQuestId(parentName, questId, deselectOnFail)
	local poiButton = QuestPOI_FindButtonByQuestId(parentName, questId);
	if ( poiButton ) then
		QuestPOI_SelectButton(poiButton);
	elseif ( deselectOnFail ) then
		poiButton = QUEST_POI_BUTTONS_SELECTED[parentName];
		if ( poiButton ) then
			QuestPOI_DeselectButton(poiButton);
		end
	end
end

function QuestPOI_SelectButton(poiButton)
	if ( poiButton ) then
		local parentName = poiButton.parentName;
		if ( QUEST_POI_BUTTONS_SELECTED[parentName] ) then
			-- return if already selected
			if ( QUEST_POI_BUTTONS_SELECTED[parentName] == poiButton ) then
				return;
			else
				QuestPOI_DeselectButton(QUEST_POI_BUTTONS_SELECTED[parentName]);
			end		
		end
		-- select
		QUEST_POI_BUTTONS_SELECTED[parentName] = poiButton;
		poiButton.isSelected = true;
		if ( poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
			local swapButton = QUEST_POI_SWAP_BUTTONS[parentName];
			swapButton:ClearAllPoints();
			swapButton:SetPoint("CENTER", poiButton);
			swapButton.quest = poiButton.quest;
			swapButton:Show();
			poiButton:Hide();
		else
			QuestPOIButton_UpdateButtonStyle(poiButton, poiButton.type);
		end
	end
end

function QuestPOI_DeselectButtonByParent(parentName)
	QuestPOI_DeselectButton(QUEST_POI_BUTTONS_SELECTED[parentName]);
end

function QuestPOI_DeselectButton(poiButton)
	if ( poiButton and poiButton.isSelected ) then
		if ( poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
			poiButton:Show();
			QUEST_POI_SWAP_BUTTONS[poiButton.parentName]:Hide();
		end
		QUEST_POI_BUTTONS_SELECTED[poiButton.parentName] = nil;
		poiButton.isSelected = false;
		QuestPOIButton_UpdateButtonStyle(poiButton, poiButton.type);
	end
end

function QuestPOI_SetTextColor(poiButton, yOffset)
	local index = poiButton.index - 1
	yOffset = yOffset + floor(index / QUEST_POI_ICONS_PER_ROW) * QUEST_POI_ICON_SIZE;
	local xOffset = mod(index, QUEST_POI_ICONS_PER_ROW) * QUEST_POI_ICON_SIZE;
	poiButton.number:SetTexCoord(xOffset, xOffset + QUEST_POI_ICON_SIZE, yOffset, yOffset + QUEST_POI_ICON_SIZE);	
end

function QuestPOI_HideButtons(parentName, buttonType, buttonIndex)
	local numButtons;
		
	numButtons = QUEST_POI_BUTTONS_MAX[parentName..buttonType];
	if ( numButtons ) then
		local poiButton;
		local buttonName = "poi"..parentName..buttonType.."_";
		for i = buttonIndex, numButtons do
			poiButton = _G[buttonName..i];
			if poiButton then
				if ( poiButton.isSelected and poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
					QuestPOI_DeselectButton(poiButton);
				end
				poiButton:Hide();
			end
		end
	end
end

function QuestPOI_HideAllButtons(parentName)
	local numButtons;
	
	for i = 1, QUEST_POI_MAX_TYPES do
		numButtons = QUEST_POI_BUTTONS_MAX[parentName..i];
		if ( numButtons ) then
			local poiButton;
			local buttonName = "poi"..parentName..i.."_";
			for j = 1, numButtons do
				poiButton = _G[buttonName..j];
				if ( poiButton.isSelected and poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
					QuestPOI_DeselectButton(poiButton);
				end
				poiButton:Hide();
			end
		end
	end
end

function QuestPOIButton_OnMouseDown(self)
	if ( self.isComplete ) then
		self.turnin:SetPoint("CENTER", 0, -1);
	else
		self.number:SetPoint("CENTER", 1, -1);
	end
end

function QuestPOIButton_OnMouseUp(self)
	if ( self.isComplete ) then
		self.turnin:SetPoint("CENTER", -1, 0);
	else
		self.number:SetPoint("CENTER", 0, 0);
	end
end
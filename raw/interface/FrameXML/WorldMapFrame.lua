NUM_WORLDMAP_POIS = 0;
NUM_WORLDMAP_POI_COLUMNS = 14;
WORLDMAP_POI_TEXTURE_WIDTH = 256;
NUM_WORLDMAP_OVERLAYS = 0;
NUM_WORLDMAP_FLAGS = 2;
NUM_WORLDMAP_DEBUG_ZONEMAP = 0;
NUM_WORLDMAP_DEBUG_OBJECTS = 0;
WORLDMAP_COSMIC_ID = -1;
WORLDMAP_WORLD_ID = 0;
WORLDMAP_OUTLAND_ID = 3;
WORLDMAP_WINTERGRASP_ID = 502;
WORLDMAP_CHALLENGE_FAIL_LIMIT = 20

QUESTFRAME_MINHEIGHT = 34;
QUESTFRAME_PADDING = 19;
WORLDMAP_POI_FRAMELEVEL = 100;		-- needs to be one the highest frames in the MEDIUM strata
WORLDMAP_WINDOWED_SIZE = 0.573;		-- size corresponds to ratio value
WORLDMAP_QUESTLIST_SIZE = 0.691;
WORLDMAP_FULLMAP_SIZE = 1.0;

local WORLDMAP_POI_MIN_X = 12;
local WORLDMAP_POI_MIN_Y = -12;
local WORLDMAP_POI_MAX_X;			-- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds
local WORLDMAP_POI_MAX_Y;			-- changes based on current scale, see WorldMapFrame_SetPOIMaxBounds

BAD_BOY_UNITS = {};
BAD_BOY_COUNT = 0;

MAP_VEHICLES = {};
VEHICLE_TEXTURES = {};
VEHICLE_TEXTURES["Drive"] = {
	"Interface\\Minimap\\Vehicle-Ground-Unoccupied",
	"Interface\\Minimap\\Vehicle-Ground-Occupied",
	width=45,
	height=45,
};
VEHICLE_TEXTURES["Fly"] = {
	"Interface\\Minimap\\Vehicle-Air-Unoccupied",
	"Interface\\Minimap\\Vehicle-Air-Occupied",
	width=45,
	height=45,
};
VEHICLE_TEXTURES["Airship Horde"] = {
	"Interface\\Minimap\\Vehicle-Air-Horde",
	"Interface\\Minimap\\Vehicle-Air-Horde",
	width=64,
	height=64,
};
VEHICLE_TEXTURES["Airship Alliance"] = {
	"Interface\\Minimap\\Vehicle-Air-Alliance",
	"Interface\\Minimap\\Vehicle-Air-Alliance",
	width=64,
	height=64,
};

WORLDMAP_DEBUG_ICON_INFO = {};
WORLDMAP_DEBUG_ICON_INFO[1] = { size =  6, r = 0.0, g = 1.0, b = 0.0 };
WORLDMAP_DEBUG_ICON_INFO[2] = { size = 16, r = 1.0, g = 1.0, b = 0.5 };
WORLDMAP_DEBUG_ICON_INFO[3] = { size = 32, r = 1.0, g = 1.0, b = 0.5 };
WORLDMAP_DEBUG_ICON_INFO[4] = { size = 64, r = 1.0, g = 0.6, b = 0.0 };

WORLDMAP_SETTINGS = {
	opacity = 0,
	locked = false,
	advanced = nil,
	selectedQuest = nil,
	selectedQuestId = 0,
	size = WORLDMAP_QUESTLIST_SIZE
};

-- using GetCurrentMapAreaID()
-- [SubZoneAreaID-1] -> ParentZoneAreaID-1
WORLDMAP_SUBZONE_ZOOMOUT_TARGET = {
	[321] = 4,
	[301] = 30,
	[341] = 27,
	[362] = 9,
	[381] = 41,
	[382] = 20,
	[480] = 462,
	[471] = 464,
	[1237] = 30,
	[1238] = 27,
	[1239] = 20,
	[1240] = 462,
	[1241] = 464,
	[1242] = 41,
	[1243] = 4,
	[1244] = 9,
	[1200] = 11,
	[1201] = 20,
	[1202] = 161,
	[1203] = 161,
	[1204] = 29,
	[1205] = 29,
	[1206] = 29,
	[1207] = 101,
	[1208] = 101,
	[1209] = 17,
	[1210] = 464,
	[1211] = 464,
	[1212] = 1239,
	[1213] = 27,
	[1214] = 27,
	[1215] = 27,
	[1216] = 1243,
	[1217] = 4,
	[1218] = 4,
	[1219] = 30,
	[1220] = 30,
	[1221] = 30,
	[1222] = 463,
	[1223] = 9,
	[1224] = 9,
	[1225] = 1237,
	[1226] = 261,
	[1227] = 161,
	[1228] = 161,
	[1229] = 41,
	[1230] = 41,
	[1231] = 41,
	[1232] = 1242,
	[1233] = 201,
	[1234] = 39,
	[1235] = 39,
	[1236] = 39,
	[2010] = 2009,
	[2028] = 1237,
	[2027] = 30,
	[2029] = 1243,
	[2030] = 1242,
	[2000] = 14,
	[2034] = 13,
	[2035] = 16,
	[2036] = 19,
	[2037] = 42,
	[2038] = 121,
	[2039] = 121,
	[2040] = 13,
	[2041] = 13,
	[2042] = 14,
	[2043] = 14,
	[2044] = 2010,
	[2045] = 2010,
	[2046] = 2010,
	[2047] = 2010,
	[2048] = 2010,
	[2049] = 2010,
	[2050] = 2010,
	[2051] = 2010,
	[2052] = 2010,
	[2053] = 2010,
	[2054] = 2010,
	[2055] = 2010,
	[2056] = 2010,
	[2057] = 2010,
	[2058] = 2010,
	[2059] = 2010,
	[2060] = 281,
	[2061] = 14,
	[2066] = 2062,
}

local function ResetWorldMapPOI(pool, frame)
	frame:Hide()
	frame:Clear()
	frame:ClearAllPoints()
end

local WorldMapPOIPool = CreateFramePoolCollection()

function WorldMapFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("CLOSE_WORLD_MAP");
	self:RegisterEvent("WORLD_MAP_NAME_UPDATE");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("PARTY_MEMBERS_CHANGED");
	self:RegisterEvent("RAID_ROSTER_UPDATE");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("CHALLENGE_FAILURE_LIST_CHANGED");
	self:RegisterEvent("QUEST_POI_UPDATE");
	C_Hook:Register(self, "HONORABLE_COMBAT_ZONES_PAYLOAD", function()
		WorldMapFrame_OnEvent(self, "HONORABLE_COMBAT_ZONES_PAYLOAD")
	end)
	C_Hook:Register(self, "GAME_EVENT_STARTED", function()
		WorldMapFrame_OnEvent(self, "GAME_EVENT_STARTED")
	end)
	C_Hook:Register(self, "GAME_EVENT_ENDED", function()
		WorldMapFrame_OnEvent(self, "GAME_EVENT_ENDED")
	end)
	self:SetClampRectInsets(0, 0, 0, -60);				-- don't overlap the xp/rep bars
	self.poiHighlight = nil;
	self.areaName = nil;
	CreateWorldMapArrowFrame(WorldMapFrame);
	WorldMapFrameTexture18:SetVertexColor(0, 0, 0);		-- this texture just needs to be a black line
	InitWorldMapPing(WorldMapFrame);
	WorldMapFrame_Update();

	--[[ Hide the world behind the map when we're in widescreen mode
	local width = GetScreenWidth();
	local height = GetScreenHeight();
	
	if ( width / height < 4 / 3 ) then
		width = width * 1.25;
		height = height * 1.25;
	end
	
	BlackoutWorld:SetWidth( width );
	BlackoutWorld:SetHeight( height );
	]]

	-- setup the zone minimap button
	UIDropDownMenu_Initialize(WorldMapZoneMinimapDropDown, WorldMapZoneMinimapDropDown_Initialize);
	UIDropDownMenu_SetWidth(WorldMapZoneMinimapDropDown, 150);
	WorldMapZoneMinimapDropDown_Update();
	WorldMapLevelDropDown_Update();

	-- PlayerArrowEffectFrame is created in code: CWorldMap::CreatePlayerArrowFrame()
	PlayerArrowEffectFrame:SetAlpha(0.65);

	-- font stuff for objectives text
	local refFrame = WorldMapFrame_GetQuestFrame(0);
	local _, fontHeight = refFrame.objectives:GetFont();
	refFrame.lineSpacing = refFrame.objectives:GetSpacing();
	refFrame.lineHeight = fontHeight + refFrame.lineSpacing;
	
	WorldMapFrame_ResetFrameLevels();
	WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapFrame_SetPOIMaxBounds();
	WorldMapQuestDetailScrollChildFrame:SetScale(0.9);
	WorldMapQuestRewardScrollChildFrame:SetScale(0.9);
	WorldMapFrame.numQuests = 0;
	WatchFrame.showObjectives = WorldMapQuestShowObjectives:GetChecked();
	WorldMapPOIFrame.allowBlobTooltip = true;
	WorldMapQuestDetailScrollFrame.scrollBarHideable = true;
	WorldMapQuestRewardScrollFrame.scrollBarHideable = true;
	WorldMapQuestDetailScrollFrame.haveTrack = true;
	WorldMapQuestRewardScrollFrame.haveTrack = true;
end

function WorldMapFrame_OnShow(self)
	if not self.LastChallengeQuery or self.LastChallengeQuery:GreaterThan(60) then
		C_Challenge.QueryChallengeFailures()
		self.LastChallengeQuery = self.LastChallengeQuery and self.LastChallengeQuery:ResetToNow() or TimeSince:Now()
	end
	self:RegisterEvent("WORLD_MAP_UPDATE");
	if ( WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE ) then
		SetupFullscreenScale(self);
		WorldMap_LoadTextures();
		if ( not WatchFrame.showObjectives and WORLDMAP_SETTINGS.size ~= WORLDMAP_FULLMAP_SIZE ) then
			WorldMapFrame_SetFullMapView();
		end		
	end
	
	UpdateMicroButtons();
	SetMapToCurrentZone();
	PlaySound("igQuestLogOpen");
	CloseDropDownMenus();
	WorldMapFrame_PingPlayerPosition();	
	WorldMapFrame_UpdateUnits("WorldMapRaid", "WorldMapParty");
end

function WorldMapFrame_OnHide(self)
	self:UnregisterEvent("WORLD_MAP_UPDATE");
	if ( OpacityFrame:IsShown() and OpacityFrame.saveOpacityFunc and OpacityFrame.saveOpacityFunc == WorldMapFrame_SaveOpacity ) then
		WorldMapFrame_SaveOpacity();
		OpacityFrame.saveOpacityFunc = nil;
		OpacityFrame:Hide();
	end
	
	UpdateMicroButtons();
	CloseDropDownMenus();
	PlaySound("igQuestLogClose");
	securecallfunction(WorldMap_ClearTextures); -- can be tainted
	if ( self.showOnHide ) then
		ShowUIPanel(self.showOnHide);
		self.showOnHide = nil;
	end
	-- forces WatchFrame event via the WORLD_MAP_UPDATE event, needed to restore the POIs in the tracker to the current zone
	SetMapToCurrentZone();
	WorldMapPOIPool:ReleaseAll();
end

function WorldMapFrame_OnEvent(self, event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		if ( self:IsShown() ) then
			HideUIPanel(WorldMapFrame);
		end
		self.HonorableCombatAreas = {}
		local zones = GetHonorableCombatZones()
		if zones then
			for _, zoneID in ipairs(zones) do
				local fileName = C_WorldMap.GetMapFileByZoneID(zoneID)
				if fileName then
					self.HonorableCombatAreas[fileName] = true
				end
			end
		end
	elseif event == "HONORABLE_COMBAT_ZONES_PAYLOAD" then
		self.HonorableCombatAreas = {}
		local zones = GetHonorableCombatZones()
		if zones then
			for _, zoneID in ipairs(zones) do
				local fileName = C_WorldMap.GetMapFileByZoneID(zoneID)
				if fileName then
					self.HonorableCombatAreas[fileName] = true
				end
			end
		end
	elseif event == "GAME_EVENT_STARTED" or event == "GAME_EVENT_ENDED" then
		if self:IsShown() then
			WorldMapFrame_Update()
		end
	elseif ( event == "WORLD_MAP_UPDATE" ) then
		if ( not self.blockWorldMapUpdate and self:IsShown() ) then
			WorldMapFrame_UpdateMap();
		end
	elseif ( event == "CLOSE_WORLD_MAP" ) then
		HideUIPanel(self);
	elseif ( event == "VARIABLES_LOADED" ) then
		WorldMapZoneMinimapDropDown_Update();
		WORLDMAP_SETTINGS.advanced = GetCVarBool("advancedWorldMap");
		WORLDMAP_SETTINGS.opacity = (tonumber(GetCVar("worldMapOpacity")));
		if ( GetCVarBool("miniWorldMap") ) then
			WorldMap_ToggleSizeDown();
		else
			WorldMapBlobFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
		end
		WorldMapQuestShowObjectives:SetChecked(GetCVarBool("questPOI"));
		WorldMapQuestShowObjectives_Toggle();
	elseif ( event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" ) then
		if ( self:IsShown() ) then
			WorldMapFrame_UpdateUnits("WorldMapRaid", "WorldMapParty");
		end
	elseif ( event == "DISPLAY_SIZE_CHANGED" ) then
		WorldMapQuestShowObjectives_AdjustPosition();
		if ( WatchFrame.showObjectives and self:IsShown() ) then
			WorldMapFrame_UpdateQuests();
		end
	elseif ( ( event == "QUEST_LOG_UPDATE" or event == "QUEST_POI_UPDATE" ) and self:IsShown() ) then
		WorldMapFrame_DisplayQuests();
		WorldMapQuestFrame_UpdateMouseOver();
	elseif event == "CHALLENGE_FAILURE_LIST_CHANGED" then
		if self:IsShown() then
			WorldMapFrame_Update()
		end
	end
end

function WorldMapFrame_OnUpdate(self)
	RequestBattlefieldPositions();

	local nextBattleTime = GetWintergraspWaitTime();
	if ( nextBattleTime and (GetCurrentMapAreaID() == WORLDMAP_WINTERGRASP_ID) and not IsInInstance()) then
		local battleSec = mod(nextBattleTime, 60);
		local battleMin = mod(floor(nextBattleTime / 60), 60);
		local battleHour = floor(nextBattleTime / 3600);
		WorldMapZoneInfo:SetFormattedText(NEXT_BATTLE, battleHour, battleMin, battleSec);
		WorldMapZoneInfo:Show();
	else
		WorldMapZoneInfo:Hide();
	end
end

function WorldMapFrame_OnKeyDown(self, key)
	local binding = GetBindingFromClick(key)
	if ((binding == "TOGGLEWORLDMAP") or (binding == "TOGGLEGAMEMENU")) then
		RunBinding("TOGGLEWORLDMAP");
	elseif ( binding == "SCREENSHOT" ) then
		RunBinding("SCREENSHOT");
	elseif ( binding == "MOVIE_RECORDING_STARTSTOP" ) then
		RunBinding("MOVIE_RECORDING_STARTSTOP");
	elseif ( binding == "TOGGLEWORLDMAPSIZE" ) then
		RunBinding("TOGGLEWORLDMAPSIZE");
	end
end

function WorldMapFrame_UpdateOverlays()
    -- Setup the overlays
    local textureCount = 0;
    for i=1, GetNumMapOverlays() do
        local textureName, textureWidth, textureHeight, offsetX, offsetY, mapPointX, mapPointY = GetMapOverlayInfo(i);
        if ( textureName and textureName ~= "" ) then
            local numTexturesWide = ceil(textureWidth/256);
            local numTexturesTall = ceil(textureHeight/256);
            local neededTextures = textureCount + (numTexturesWide * numTexturesTall);
            if ( neededTextures > NUM_WORLDMAP_OVERLAYS ) then
                for j=NUM_WORLDMAP_OVERLAYS+1, neededTextures do
                    WorldMapDetailFrame:CreateTexture("WorldMapOverlay"..j, "ARTWORK");
                end
                NUM_WORLDMAP_OVERLAYS = neededTextures;
            end
            local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight;
            for j=1, numTexturesTall do
                if ( j < numTexturesTall ) then
                    texturePixelHeight = 256;
                    textureFileHeight = 256;
                else
                    texturePixelHeight = mod(textureHeight, 256);
                    if ( texturePixelHeight == 0 ) then
                        texturePixelHeight = 256;
                    end
                    textureFileHeight = 16;
                    while(textureFileHeight < texturePixelHeight) do
                        textureFileHeight = textureFileHeight * 2;
                    end
                end
                for k=1, numTexturesWide do
                    textureCount = textureCount + 1;
                    local texture = _G["WorldMapOverlay"..textureCount];
                    if ( k < numTexturesWide ) then
                        texturePixelWidth = 256;
                        textureFileWidth = 256;
                    else
                        texturePixelWidth = mod(textureWidth, 256);
                        if ( texturePixelWidth == 0 ) then
                            texturePixelWidth = 256;
                        end
                        textureFileWidth = 16;
                        while(textureFileWidth < texturePixelWidth) do
                            textureFileWidth = textureFileWidth * 2;
                        end
                    end
                    texture:SetWidth(texturePixelWidth);
                    texture:SetHeight(texturePixelHeight);
                    texture:SetTexCoord(0, texturePixelWidth/textureFileWidth, 0, texturePixelHeight/textureFileHeight);
                    texture:SetPoint("TOPLEFT", offsetX + (256 * (k-1)), -(offsetY + (256 * (j - 1))));
                    texture:SetTexture(textureName..(((j - 1) * numTexturesWide) + k));
                    texture:Show();
                end
            end
        end
    end
    for i=textureCount+1, NUM_WORLDMAP_OVERLAYS do
        _G["WorldMapOverlay"..i]:Hide();
    end
end

function WorldMapFrame_Update()
	local isVisible = WorldMapFrame:IsVisible()
	WorldMapPOIPool:ReleaseAll();
	local mapFileName, textureHeight = GetMapInfo();

	if ( not mapFileName ) then
		if ( GetCurrentMapContinent() == WORLDMAP_COSMIC_ID ) then
			mapFileName = "Cosmic";
			OutlandButton:Show();
			AzerothButton:Show();
		else
			-- Temporary Hack (Temporary meaning 2 yrs, haha)
			mapFileName = "World";
			OutlandButton:Hide();
			AzerothButton:Hide();
		end
	else
		OutlandButton:Hide();
		AzerothButton:Hide();
	end

	local texName;
	local dungeonLevel = GetCurrentMapDungeonLevel();
	if (DungeonUsesTerrainMap()) then
		dungeonLevel = dungeonLevel - 1;
	end
	local completeMapFileName;
	if ( dungeonLevel > 0 ) then
		completeMapFileName = mapFileName..dungeonLevel.."_";
	else
		completeMapFileName = mapFileName;
	end
	for i=1, NUM_WORLDMAP_DETAIL_TILES do
		texName = "Interface\\WorldMap\\"..mapFileName.."\\"..completeMapFileName..i;
		_G["WorldMapDetailTile"..i]:SetTexture(texName);
	end		
	--WorldMapHighlight:Hide();
	
	-- Enable/Disable zoom out button
	if ( IsZoomOutAvailable() ) then
		WorldMapZoomOutButton:Enable();
	else
		WorldMapZoomOutButton:Disable();
	end
	
	local mapWidth, mapHeight = WorldMapButton:GetSize()

	-- Setup the POI's
	local numPOIs = GetNumMapLandmarks();
	if ( NUM_WORLDMAP_POIS < numPOIs ) then
		for i=NUM_WORLDMAP_POIS+1, numPOIs do
			WorldMap_CreatePOI(i);
		end
		NUM_WORLDMAP_POIS = numPOIs;
	end
	for i=1, NUM_WORLDMAP_POIS do
		local worldMapPOIName = "WorldMapFramePOI"..i;
		local worldMapPOI = _G[worldMapPOIName];
		if ( i <= numPOIs ) then
			local name, description, textureIndex, x, y, mapLinkID = GetMapLandmarkInfo(i);
			local x1, x2, y1, y2 = WorldMap_GetPOITextureCoords(textureIndex);
			_G[worldMapPOIName.."Texture"]:SetTexCoord(x1, x2, y1, y2);
			x = x * mapWidth;
			y = -y * mapHeight;
			worldMapPOI:SetPoint("CENTER", "WorldMapButton", "TOPLEFT", x, y );
			worldMapPOI.name = name;
			worldMapPOI.description = description;
			worldMapPOI.mapLinkID = mapLinkID;
			worldMapPOI:Show();
			if textureIndex == 0 then
				worldMapPOI:SetFrameLevel(WorldMapButton:GetFrameLevel()+1);
			else
				worldMapPOI:SetFrameLevel(WorldMapButton:GetFrameLevel()+10);
			end
		else
			worldMapPOI:Hide();
		end
	end

	if isVisible then
		local currentMapAreaID = GetCurrentMapAreaID()
		local currentMapZoneID = C_WorldMap.GetZoneIDByAreaID(currentMapAreaID)
		local pool
		local x, y, z

		if currentMapZoneID then
			if C_WorldMap.GetPOIFilter(Enum.POIType.ChallengeDeath) then
				-- failure pois
				pool = WorldMapPOIPool:GetOrCreatePool("BUTTON", "WorldMapButton", "WorldMapChallengeFailPOITemplate", ResetWorldMapPOI)
				local challengeFailures = C_Challenge.GetChallengeFailures(currentMapZoneID, WORLDMAP_CHALLENGE_FAIL_LIMIT) or {}
				for _, death in ipairs(challengeFailures) do
					x, y = death.X, death.Y
					if x and y then
						x = x * mapWidth
						y = -y * mapHeight
						local poi = pool:Acquire()
						poi:SetFailure(death, x, y)
						poi:Show()
					end
				end
			end
		end

		do -- regular pois 
			pool = WorldMapPOIPool:GetOrCreatePool("BUTTON", "WorldMapButton", "MapPoiPinTemplate", ResetWorldMapPOI)
			local poi
			local frameLevel = WorldMapButton:GetFrameLevel()+5
			for _, data in ipairs(C_WorldMap.GetVisiblePOI()) do
				if C_WorldMap.CanShowPOI(data) then
					x, y, z = data.X, data.Y, data.Z
					if x and y and z then
						x, y = C_WorldMap.GetMapPosition(data.MapID, x, y, z)
						if x ~= 0 and y ~= 0 then
							x = x * mapWidth
							y = -y * mapHeight
							poi = pool:Acquire()
							poi:SetPOI(data, x, y)
							poi:SetFrameLevel(frameLevel)
							poi:Show()
						end
					end
				end
			end
		end
	end

    securecallfunction(WorldMapFrame_UpdateOverlays) -- this can be tainted by addons!
    
	-- Show debug zone map if available
	local numDebugZoneMapTextures = 0;
	if ( HasDebugZoneMap() ) then
		local ZONEMAP_SIZE = 32;
		local mapW = WorldMapDetailFrame:GetWidth();
		local mapH = WorldMapDetailFrame:GetHeight();
		for y=1, ZONEMAP_SIZE do
			for x=1, ZONEMAP_SIZE do
				local id, minX, minY, maxX, maxY, r, g, b, a = GetDebugZoneMap(x, y);
				if ( id ) then
					if ( not WorldMapDetailFrame.zoneMap ) then
						WorldMapDetailFrame.zoneMap = {};
					end

					numDebugZoneMapTextures = numDebugZoneMapTextures + 1;
					local texture = WorldMapDetailFrame.zoneMap[numDebugZoneMapTextures];
					if ( not texture ) then
						texture = WorldMapDetailFrame:CreateTexture(nil, "OVERLAY");
						texture:SetTexture(1, 1, 1);
						WorldMapDetailFrame.zoneMap[numDebugZoneMapTextures] = texture;
					end

					texture:SetVertexColor(r, g, b, a);
					minX = minX * mapW;
					minY = -minY * mapH;
					texture:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", minX, minY);
					maxX = maxX * mapW;
					maxY = -maxY * mapH;
					texture:SetPoint("BOTTOMRIGHT", "WorldMapDetailFrame", "TOPLEFT", maxX, maxY);
					texture:Show();
				end
			end
		end
	end
	for i=numDebugZoneMapTextures+1, NUM_WORLDMAP_DEBUG_ZONEMAP do
		WorldMapDetailFrame.zoneMap[i]:Hide();
	end
	NUM_WORLDMAP_DEBUG_ZONEMAP = numDebugZoneMapTextures;
	
	-- Setup any debug objects
	local baseLevel = WorldMapButton:GetFrameLevel() + 1;
	local numDebugObjects = GetNumMapDebugObjects();
	if ( NUM_WORLDMAP_DEBUG_OBJECTS < numDebugObjects ) then
		for i=NUM_WORLDMAP_DEBUG_OBJECTS+1, numDebugObjects do
			CreateFrame("Frame", "WorldMapDebugObject"..i, WorldMapButton, "WorldMapDebugObjectTemplate");
		end
		NUM_WORLDMAP_DEBUG_OBJECTS = numDebugObjects;
	end
	textureCount = 0;
	for i=1, numDebugObjects do
		local name, size, x, y = GetMapDebugObjectInfo(i);
		if ( (x ~= 0 or y ~= 0) and (size > 1 or GetCurrentMapZone() ~= WORLDMAP_WORLD_ID) ) then
			textureCount = textureCount + 1;
			local frame = _G["WorldMapDebugObject"..textureCount];
			frame.index = i;
			frame.name = name;

			local info = WORLDMAP_DEBUG_ICON_INFO[size];
			if ( GetCurrentMapZone() == WORLDMAP_WORLD_ID ) then
				frame:SetWidth(info.size / 2);
				frame:SetHeight(info.size / 2);
			else
				frame:SetWidth(info.size);
				frame:SetHeight(info.size);
			end
			frame.texture:SetVertexColor(info.r, info.g, info.b, 0.5);

			x = x * WorldMapDetailFrame:GetWidth();
			y = -y * WorldMapDetailFrame:GetHeight();
			frame:SetFrameLevel(baseLevel + (4 - size));
			frame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", x, y);
			frame:Show();
		end
	end
	for i=textureCount+1, NUM_WORLDMAP_DEBUG_OBJECTS do
		_G["WorldMapDebugObject"..i]:Hide();
	end
	
	-- High Risk Tier Stuff
    if WarmodeMapFrame then
        local continent = GetCurrentMapContinent()
        if C_Player:IsHighRisk() and continent <= 4 and continent >= 1 then
            local isHighRisk = C_PVP:GetMapIsHighRisk(GetMapInfo())
            WarmodeMapFrame:SetActive(isHighRisk)
            WarmodeMapFrame:Show()
        else
            WarmodeMapFrame:Hide()
        end
    end
end

function WorldMapFrame_UpdateUnits(raidUnitPrefix, partyUnitPrefix)
	for i=1, MAX_RAID_MEMBERS do
		local partyMemberFrame = _G["WorldMapRaid"..i];
		if ( partyMemberFrame:IsShown() ) then
			WorldMapUnit_Update(partyMemberFrame);
		end
	end
	for i=1, MAX_PARTY_MEMBERS do
		local partyMemberFrame = _G["WorldMapParty"..i];
		if ( partyMemberFrame:IsShown() ) then
			WorldMapUnit_Update(partyMemberFrame);
		end
	end
end

function WorldMapPOI_OnEnter(self)
	WorldMapFrame.poiHighlight = 1;
	if ( self.description and strlen(self.description) > 0 ) then
		WorldMapFrameAreaLabel:SetText(self.name);
		WorldMapFrameAreaDescription:SetText(self.description);
	else
		WorldMapFrameAreaLabel:SetText(self.name);
		WorldMapFrameAreaDescription:SetText("");
	end
end

function WorldMapPOI_OnLeave()
	WorldMapFrame.poiHighlight = nil;
	WorldMapFrameAreaLabel:SetText(WorldMapFrame.areaName);
	WorldMapFrameAreaDescription:SetText(WorldMapFrame.honorableCombatText);
end

function WorldMapPOI_OnClick(self, button)
	if ( self.mapLinkID ) then
		ClickLandmark(self.mapLinkID);
	else
		WorldMapButton_OnClick(WorldMapButton, button);
	end
end

function WorldMap_CreatePOI(index)
	local button = CreateFrame("Button", "WorldMapFramePOI"..index, WorldMapButton);
	button:SetFrameLevel(WorldMapButton:GetFrameLevel()+10)
	button:SetWidth(32);
	button:SetHeight(32);
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	button:SetScript("OnEnter", WorldMapPOI_OnEnter);
	button:SetScript("OnLeave", WorldMapPOI_OnLeave);
	button:SetScript("OnClick", WorldMapPOI_OnClick);

	local texture = button:CreateTexture(button:GetName().."Texture", "BACKGROUND");
	texture:SetWidth(16);
	texture:SetHeight(16);
	texture:SetPoint("CENTER", 0, 0);
	texture:SetTexture("Interface\\Minimap\\POIIcons");
end

function WorldMap_GetPOITextureCoords(index)
	local worldMapPixelsPerIcon = 18;
	local worldMapIconDimension = 16;
	
	local offsetPixelsPerSide = (worldMapPixelsPerIcon - worldMapIconDimension)/2;
	local normalizedOffsetPerSide = offsetPixelsPerSide * 1/WORLDMAP_POI_TEXTURE_WIDTH;
	local xCoord1, xCoord2, yCoord1, yCoord2; 
	local coordIncrement = worldMapPixelsPerIcon / WORLDMAP_POI_TEXTURE_WIDTH;
	local xOffset = mod(index, NUM_WORLDMAP_POI_COLUMNS);
	local yOffset = floor(index / NUM_WORLDMAP_POI_COLUMNS);
	
	xCoord1 = xOffset * coordIncrement + normalizedOffsetPerSide;
	xCoord2 = xCoord1 + coordIncrement - normalizedOffsetPerSide;
	yCoord1 = yOffset * coordIncrement + normalizedOffsetPerSide;
	yCoord2 = yCoord1 + coordIncrement - normalizedOffsetPerSide;
	
	return xCoord1, xCoord2, yCoord1, yCoord2;
end

function WorldMapContinentsDropDown_Update()
	UIDropDownMenu_Initialize(WorldMapContinentDropDown, WorldMapContinentsDropDown_Initialize);
	UIDropDownMenu_SetWidth(WorldMapContinentDropDown, 130);

	if ( (GetCurrentMapContinent() == 0) or (GetCurrentMapContinent() == WORLDMAP_COSMIC_ID) ) then
		UIDropDownMenu_ClearAll(WorldMapContinentDropDown);
	else
		UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown,GetCurrentMapContinent());
	end
end

function WorldMapContinentsDropDown_Initialize()
	WorldMapFrame_LoadContinents(GetMapContinents());
end

function WorldMapFrame_LoadContinents(...)
	local info = UIDropDownMenu_CreateInfo();

	for i=1, select("#", ...), 1 do
		-- Hackfix, we dont want AzzarFaire to show up in the continents list, in the future it'll be added as Azzar Archipelago
		if i <= 4 then
			info.text = select(i, ...);
			info.func = WorldMapContinentButton_OnClick;
			info.checked = nil;
			UIDropDownMenu_AddButton(info);
		end
	end
	   
end



function WorldMapZoneDropDown_Update()
	UIDropDownMenu_Initialize(WorldMapZoneDropDown, WorldMapZoneDropDown_Initialize);
	UIDropDownMenu_SetWidth(WorldMapZoneDropDown, 130);

	if ( (GetCurrentMapContinent() == 0) or (GetCurrentMapContinent() == WORLDMAP_COSMIC_ID) ) then
		UIDropDownMenu_ClearAll(WorldMapZoneDropDown);
	else
		UIDropDownMenu_SetSelectedValue(WorldMapZoneDropDown, GetCurrentMapZone());
	end
end

function WorldMapZoneDropDown_Initialize()
	WorldMapFrame_LoadZones(GetMapZones(GetCurrentMapContinent()));
end

function WorldMapFrame_LoadZones(...)
	local info = UIDropDownMenu_CreateInfo();
	for i=1, select("#", ...), 1 do
		local name = select(i, ...);
		if not IsAreaHidden(name) then
			info.text = name;
			info.func = WorldMapZoneButton_OnClick;
			info.arg1 = i
			info.value = i
			info.checked = nil;
			UIDropDownMenu_AddButton(info);
		end
	end
end

function WorldMapLevelDropDown_Update()
	UIDropDownMenu_Initialize(WorldMapLevelDropDown, WorldMapLevelDropDown_Initialize);
	UIDropDownMenu_SetWidth(WorldMapLevelDropDown, 130);

	if ( (GetNumDungeonMapLevels() == 0) ) then
		UIDropDownMenu_ClearAll(WorldMapLevelDropDown);
		WorldMapLevelDropDown:Hide();
		WorldMapLevelUpButton:Hide();
		WorldMapLevelDownButton:Hide();
	else
		UIDropDownMenu_SetSelectedID(WorldMapLevelDropDown, GetCurrentMapDungeonLevel());
		WorldMapLevelDropDown:Show();
		if ( WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE ) then
			WorldMapLevelUpButton:Show();
			WorldMapLevelDownButton:Show();
		end
	end
end

function WorldMapLevelDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	local level = GetCurrentMapDungeonLevel();
	
	local mapname = strupper(GetMapInfo() or "");
	
	local usesTerrainMap = DungeonUsesTerrainMap();

	for i=1, GetNumDungeonMapLevels() do
		local floorNum = i;
		if (usesTerrainMap) then
			floorNum = i - 1;
		end
		local floorname =_G["DUNGEON_FLOOR_" .. mapname .. floorNum];
		info.text = floorname or string.format(FLOOR_NUMBER, i);
		info.func = WorldMapLevelButton_OnClick;
		info.checked = (i == level);
		UIDropDownMenu_AddButton(info);
	end
end

function WorldMapLevelButton_OnClick(self)
	UIDropDownMenu_SetSelectedID(WorldMapLevelDropDown, self:GetID());
	SetDungeonMapLevel(self:GetID());
end

function WorldMapLevelUp_OnClick(self)
	SetDungeonMapLevel(GetCurrentMapDungeonLevel() - 1);
	UIDropDownMenu_SetSelectedID(WorldMapLevelDropDown, GetCurrentMapDungeonLevel());
	PlaySound("UChatScrollButton");
end

function WorldMapLevelDown_OnClick(self)
	SetDungeonMapLevel(GetCurrentMapDungeonLevel() + 1);
	UIDropDownMenu_SetSelectedID(WorldMapLevelDropDown, GetCurrentMapDungeonLevel());
	PlaySound("UChatScrollButton");
end

function WorldMapContinentButton_OnClick(self)
	UIDropDownMenu_SetSelectedID(WorldMapContinentDropDown, self:GetID());
	SetMapZoom(self:GetID());
end

function WorldMapZoneButton_OnClick(self, arg1)
	UIDropDownMenu_SetSelectedValue(WorldMapZoneDropDown, arg1);
	SetMapZoom(GetCurrentMapContinent(), arg1);
end

function WorldMapZoomOutButton_OnClick()
	WorldMapTooltip:Hide();
	
	--Hackfix for zooming out to zone map instead of continent map, and then out to Azeroth map
	local mapID = GetCurrentMapAreaID() - 1;
	
	if WORLDMAP_SUBZONE_ZOOMOUT_TARGET[mapID] then
		SetMapByID(WORLDMAP_SUBZONE_ZOOMOUT_TARGET[mapID])
	elseif ( GetCurrentMapZone() ~= WORLDMAP_WORLD_ID ) then
		SetMapZoom(GetCurrentMapContinent());
	elseif ( GetCurrentMapContinent() == WORLDMAP_WORLD_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	elseif ( GetCurrentMapDungeonLevel() > 0 ) then
		ZoomOut();
	elseif ( GetCurrentMapContinent() == WORLDMAP_COSMIC_ID ) then
		ZoomOut();
	elseif ( GetCurrentMapContinent() == WORLDMAP_OUTLAND_ID ) then
		SetMapZoom(WORLDMAP_COSMIC_ID);
	else
		SetMapZoom(WORLDMAP_WORLD_ID);
	end
end

function WorldMapZoneMinimapDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	local value = GetCVar("showBattlefieldMinimap");

	info.value = "0";
	info.text = WorldMapZoneMinimapDropDown_GetText(info.value);
	info.func = WorldMapZoneMinimapDropDown_OnClick;
	if ( value == info.value ) then
		info.checked = 1;
		UIDropDownMenu_SetText(WorldMapZoneMinimapDropDown, info.text);
	else
		info.checked = nil;
	end
	UIDropDownMenu_AddButton(info);

	info.value = "1";
	info.text = WorldMapZoneMinimapDropDown_GetText(info.value);
	info.func = WorldMapZoneMinimapDropDown_OnClick;
	if ( value == info.value ) then
		info.checked = 1;
		UIDropDownMenu_SetText(WorldMapZoneMinimapDropDown, info.text);
	else
		info.checked = nil;
	end
	UIDropDownMenu_AddButton(info);

	info.value = "2";
	info.text = WorldMapZoneMinimapDropDown_GetText(info.value);
	info.func = WorldMapZoneMinimapDropDown_OnClick;
	if ( value == info.value ) then
		info.checked = 1;
		UIDropDownMenu_SetText(WorldMapZoneMinimapDropDown, info.text);
	else
		info.checked = nil;
	end
	UIDropDownMenu_AddButton(info);
end

function WorldMapZoneMinimapDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedValue(WorldMapZoneMinimapDropDown, self.value);
	SetCVar("showBattlefieldMinimap", self.value);

	if ( WorldStateFrame_CanShowBattlefieldMinimap() ) then
		if ( not BattlefieldMinimap ) then
			BattlefieldMinimap_LoadUI();
		end
		BattlefieldMinimap:Show();
	else
		if ( BattlefieldMinimap ) then
			BattlefieldMinimap:Hide();
		end
	end
end

function WorldMapZoneMinimapDropDown_GetText(value)
	if ( value == "0" ) then
		return BATTLEFIELD_MINIMAP_SHOW_NEVER;
	end
	if ( value == "1" ) then
		return BATTLEFIELD_MINIMAP_SHOW_BATTLEGROUNDS;
	end
	if ( value == "2" ) then
		return BATTLEFIELD_MINIMAP_SHOW_ALWAYS;
	end

	return nil;
end

function WorldMapZoneMinimapDropDown_Update()
	UIDropDownMenu_SetSelectedValue(WorldMapZoneMinimapDropDown, GetCVar("showBattlefieldMinimap"));
	UIDropDownMenu_SetText(WorldMapZoneMinimapDropDown, WorldMapZoneMinimapDropDown_GetText(GetCVar("showBattlefieldMinimap")));
end

function WorldMapButton_OnClick(button, mouseButton)
	CloseDropDownMenus();
	if ( mouseButton == "LeftButton" ) then
		local x, y = GetCursorPosition();
		x = x / button:GetEffectiveScale();
		y = y / button:GetEffectiveScale();

		local centerX, centerY = button:GetCenter();
		local width = button:GetWidth();
		local height = button:GetHeight();
		local adjustedY = (centerY + (height/2) - y) / height;
		local adjustedX = (x - (centerX - (width/2))) / width;
		if QATool and QAToolDB and QAToolDB.WorldMapTeleport and IsShiftKeyDown() then
			local cmd = "go groundxy %s %s %s"
			cmd = cmd:format(adjustedX*100, adjustedY*100, GetCurrentMapAreaID() - 1)
			QATool.ExecuteCommand(cmd)
		else
			ProcessMapClick( adjustedX, adjustedY);
		end
	elseif ( mouseButton == "RightButton" ) then
		WorldMapZoomOutButton_OnClick();
	elseif ( GetBindingFromClick(mouseButton) ==  "TOGGLEWORLDMAP" ) then
		ToggleFrame(WorldMapFrame);
	end
end

function WorldMapButton_OnUpdate(self, elapsed)
	local x, y = GetCursorPosition();
	x = x / self:GetEffectiveScale();
	y = y / self:GetEffectiveScale();

	local centerX, centerY = self:GetCenter();
	local width = self:GetWidth();
	local height = self:GetHeight();
	local adjustedY = (centerY + (height/2) - y ) / height;
	local adjustedX = (x - (centerX - (width/2))) / width;
	
	local name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY
	if ( self:IsMouseOver() ) then
		name, fileName, texPercentageX, texPercentageY, textureX, textureY, scrollChildX, scrollChildY = UpdateMapHighlight( adjustedX, adjustedY );
	end
	if fileName then
		local minLevel, maxLevel = GetMapLevelRange(fileName)
		if minLevel and maxLevel then
			local currentLevel = C_Player:GetLevel()
			local levelText = format("(%d-%d)", minLevel, maxLevel)
			if currentLevel > maxLevel then
				levelText = GetQuestDifficultyColor(maxLevel):WrapText(levelText)
			elseif currentLevel < minLevel then
				levelText = GetQuestDifficultyColor(minLevel):WrapText(levelText)
			else
				levelText = GetQuestDifficultyColor(currentLevel):WrapText(levelText)
			end
			if C_PVP:GetMapIsHighRisk(fileName) and C_Player:IsNoRiskPvPOrHigher() then
				name = RED_FONT_COLOR:WrapText(name .. " " .. END_GAME_PVP_ZONE)
			end
			name = format("%s %s", name, levelText)
		end
	end

	WorldMapFrame.areaName = name;
	if ( not WorldMapFrame.poiHighlight ) then
		WorldMapFrameAreaLabel:SetText(name);
		WorldMapFrame.honorableCombatText = ""
		WorldMapFrameAreaDescription:SetText(WorldMapFrame.honorableCombatText);
	end
	if ( fileName ) then
		WorldMapHighlight:SetTexCoord(0, texPercentageX, 0, texPercentageY);
		WorldMapHighlight:SetTexture("Interface\\WorldMap\\"..fileName.."\\"..fileName.."Highlight");
		textureX = textureX * width;
		textureY = textureY * height;
		scrollChildX = scrollChildX * width;
		scrollChildY = -scrollChildY * height;
		if ( (textureX > 0) and (textureY > 0) ) then
			WorldMapHighlight:SetWidth(textureX);
			WorldMapHighlight:SetHeight(textureY);
			WorldMapHighlight:SetPoint("TOPLEFT", "WorldMapDetailFrame", "TOPLEFT", scrollChildX, scrollChildY);
			WorldMapHighlight:Show();
			--WorldMapFrameAreaLabel:SetPoint("TOP", "WorldMapHighlight", "TOP", 0, 0);
		end
		
		if WorldMapFrame.HonorableCombatAreas[fileName] then
			WorldMapFrame.honorableCombatText = "|cff00FF00"..HONORABLE_COMBAT_ZONE.."|r"
			WorldMapFrameAreaDescription:SetText(WorldMapFrame.honorableCombatText);
		end

		if WarmodeMapFrame and WarmodeMapFrame:IsShown() then
			local isHighRisk = C_PVP:GetMapIsHighRisk(fileName)
            if C_PVP:IsLegacyWarmode() then
                WarmodeMapFrame:SetActive(isHighRisk)
                if isHighRisk > 0 then
                    WorldMapHighlight:SetVertexColor(GetHighRiskTierColor(isHighRisk))
                else
                    WorldMapHighlight:SetVertexColor(1, 1, 1)
                end
            elseif isHighRisk then
				WorldMapHighlight:SetVertexColor(RED_FONT_COLOR:GetRGBA())
			else
				WorldMapHighlight:SetVertexColor(1, 1, 1)
			end
		else
            if WarmodeMapFrame and C_PVP:IsLegacyWarmode() then
                WarmodeMapFrame:HideInfo()
            end
			WorldMapHighlight:SetVertexColor(1, 1, 1)
		end
	else
		WorldMapHighlight:Hide();
	end

	if WarmodeMapFrame and WarmodeMapFrame:IsShown() then
        if WarmodeMapFrame.UpdateZoneHighlight then
            WarmodeMapFrame:UpdateZoneHighlight()
        end
	end
	
	--Position player
	UpdateWorldMapArrowFrames();
	local playerX, playerY = GetPlayerMapPosition("player");
	if ( (playerX == 0 and playerY == 0) ) then
		ShowWorldMapArrowFrame(nil);
		WorldMapPing:Hide();
		WorldMapPlayer:Hide();
	else
		playerX = playerX * WorldMapDetailFrame:GetWidth();
		playerY = -playerY * WorldMapDetailFrame:GetHeight();
		PositionWorldMapArrowFrame("CENTER", "WorldMapDetailFrame", "TOPLEFT", playerX * WORLDMAP_SETTINGS.size, playerY * WORLDMAP_SETTINGS.size);
		ShowWorldMapArrowFrame(1);

		-- Position clear button to detect mouseovers
		WorldMapPlayer:Show();
		WorldMapPlayer:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", playerX, playerY);

		-- Position player ping if its shown
		if ( WorldMapPing:IsShown() ) then
			WorldMapPing:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", playerX, playerY);
			-- If ping has a timer greater than 0 count it down, otherwise fade it out
			if ( WorldMapPing.timer > 0 ) then
				WorldMapPing.timer = WorldMapPing.timer - elapsed;
				if ( WorldMapPing.timer <= 0 ) then
					WorldMapPing.fadeOut = 1;
					WorldMapPing.fadeOutTimer = MINIMAPPING_FADE_TIMER;
				end
			elseif ( WorldMapPing.fadeOut ) then
				WorldMapPing.fadeOutTimer = WorldMapPing.fadeOutTimer - elapsed;
				if ( WorldMapPing.fadeOutTimer > 0 ) then
					WorldMapPing:SetAlpha(255 * (WorldMapPing.fadeOutTimer/MINIMAPPING_FADE_TIMER))
				else
					WorldMapPing.fadeOut = nil;
					WorldMapPing:Hide();
				end
			end
		end
	end

	--Position groupmates
	local playerCount = 0;
	if ( GetNumRaidMembers() > 0 ) then
		for i=1, MAX_PARTY_MEMBERS do
			local partyMemberFrame = _G["WorldMapParty"..i];
			partyMemberFrame:Hide();
		end
		for i=1, MAX_RAID_MEMBERS do
			local unit = "raid"..i;
			local partyX, partyY = GetPlayerMapPosition(unit);
			local partyMemberFrame = _G["WorldMapRaid"..(playerCount + 1)];
			if ( (partyX == 0 and partyY == 0) or UnitIsUnit(unit, "player") ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * WorldMapDetailFrame:GetWidth();
				partyY = -partyY * WorldMapDetailFrame:GetHeight();
				partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
				partyMemberFrame.name = nil;
				partyMemberFrame.unit = unit;
				partyMemberFrame:Show();
				playerCount = playerCount + 1;
			end
		end
	else
		for i=1, MAX_PARTY_MEMBERS do
			local partyX, partyY = GetPlayerMapPosition("party"..i);
			local partyMemberFrame = _G["WorldMapParty"..i];
			if ( partyX == 0 and partyY == 0 ) then
				partyMemberFrame:Hide();
			else
				partyX = partyX * WorldMapDetailFrame:GetWidth();
				partyY = -partyY * WorldMapDetailFrame:GetHeight();
				partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
				partyMemberFrame:Show();
			end
		end
	end
	-- Position Team Members
	local numTeamMembers = GetNumBattlefieldPositions();
	for i=playerCount+1, MAX_RAID_MEMBERS do
		local partyX, partyY, name = GetBattlefieldPosition(i - playerCount);
		local partyMemberFrame = _G["WorldMapRaid"..i];
		if ( partyX == 0 and partyY == 0 ) then
			partyMemberFrame:Hide();
		else
			partyX = partyX * WorldMapDetailFrame:GetWidth();
			partyY = -partyY * WorldMapDetailFrame:GetHeight();
			partyMemberFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", partyX, partyY);
			partyMemberFrame.name = name;
			partyMemberFrame.unit = nil;
			partyMemberFrame:Show();
		end
	end

	-- Position flags
	local numFlags = GetNumBattlefieldFlagPositions();
	for i=1, numFlags do
		local flagX, flagY, flagToken = GetBattlefieldFlagPosition(i);
		local flagFrameName = "WorldMapFlag"..i;
		local flagFrame = _G[flagFrameName];
		if ( flagX == 0 and flagY == 0 ) then
			flagFrame:Hide();
		else
			flagX = flagX * WorldMapDetailFrame:GetWidth();
			flagY = -flagY * WorldMapDetailFrame:GetHeight();
			flagFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", flagX, flagY);
			local flagTexture = _G[flagFrameName.."Texture"];
			flagTexture:SetTexture("Interface\\WorldStateFrame\\"..flagToken);
			flagFrame:Show();
		end
	end
	for i=numFlags+1, NUM_WORLDMAP_FLAGS do
		local flagFrame = _G["WorldMapFlag"..i];
		flagFrame:Hide();
	end

	-- Position corpse
	local corpseX, corpseY = GetCorpseMapPosition();
	if ( corpseX == 0 and corpseY == 0 ) then
		WorldMapCorpse:Hide();
	else
		corpseX = corpseX * WorldMapDetailFrame:GetWidth();
		corpseY = -corpseY * WorldMapDetailFrame:GetHeight();
		
		WorldMapCorpse:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", corpseX, corpseY);
		WorldMapCorpse:Show();
	end

	-- Position Death Release marker
	local deathReleaseX, deathReleaseY = GetDeathReleasePosition();
	if ((deathReleaseX == 0 and deathReleaseY == 0) or UnitIsGhost("player")) then
		WorldMapDeathRelease:Hide();
	else
		deathReleaseX = deathReleaseX * WorldMapDetailFrame:GetWidth();
		deathReleaseY = -deathReleaseY * WorldMapDetailFrame:GetHeight();
		
		WorldMapDeathRelease:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", deathReleaseX, deathReleaseY);
		WorldMapDeathRelease:Show();
	end
	
	-- position vehicles
	local numVehicles;
	if ( GetCurrentMapContinent() == WORLDMAP_WORLD_ID or (GetCurrentMapContinent() ~= -1 and GetCurrentMapZone() == 0) ) then
		-- Hide vehicles on the worldmap and continent maps
		numVehicles = 0;
	else
		numVehicles = GetNumBattlefieldVehicles();
	end
	local totalVehicles = #MAP_VEHICLES;
	local index = 0;
	for i=1, numVehicles do
		if (i > totalVehicles) then
			local vehicleName = "WorldMapVehicles"..i;
			MAP_VEHICLES[i] = CreateFrame("FRAME", vehicleName, WorldMapButton, "WorldMapVehicleTemplate");
			MAP_VEHICLES[i].texture = _G[vehicleName.."Texture"];
		end
		local vehicleX, vehicleY, unitName, isPossessed, vehicleType, orientation, isPlayer, isAlive = GetBattlefieldVehicleInfo(i);
		if ( vehicleX and isAlive and not isPlayer and VEHICLE_TEXTURES[vehicleType]) then
			local mapVehicleFrame = MAP_VEHICLES[i];
			vehicleX = vehicleX * WorldMapDetailFrame:GetWidth();
			vehicleY = -vehicleY * WorldMapDetailFrame:GetHeight();
			mapVehicleFrame.texture:SetRotation(orientation);
			mapVehicleFrame.texture:SetTexture(WorldMap_GetVehicleTexture(vehicleType, isPossessed));
			mapVehicleFrame:SetPoint("CENTER", "WorldMapDetailFrame", "TOPLEFT", vehicleX, vehicleY);
			mapVehicleFrame:SetWidth(VEHICLE_TEXTURES[vehicleType].width);
			mapVehicleFrame:SetHeight(VEHICLE_TEXTURES[vehicleType].height);
			mapVehicleFrame.name = unitName;
			mapVehicleFrame:Show();
			index = i;	-- save for later
		else
			MAP_VEHICLES[i]:Hide();
		end
		
	end
	if (index < totalVehicles) then
		for i=index+1, totalVehicles do
			MAP_VEHICLES[i]:Hide();
		end
	end	
end

function WorldMapFrame_PingPlayerPosition()
	WorldMapPing:SetAlpha(255);
	WorldMapPing:Show();
	--PlaySound("MapPing");
	WorldMapPing.timer = 1;
end

function WorldMap_GetVehicleTexture(vehicleType, isPossessed)
	if ( not vehicleType ) then
		return;
	end
	if ( not isPossessed ) then
		isPossessed = 1;
	else
		isPossessed = 2;
	end
	if ( not VEHICLE_TEXTURES[vehicleType]) then
		return;
	end
	return VEHICLE_TEXTURES[vehicleType][isPossessed];
end

local WORLDMAP_TEXTURES_TO_LOAD = {
	{	
		name="WorldMapFrameTexture1", 
		file="Interface\\WorldMap\\UI-WorldMap-Top1",
	},
	{	
		name="WorldMapFrameTexture2", 
		file="Interface\\WorldMap\\UI-WorldMap-Top2",
	},
	{	
		name="WorldMapFrameTexture3", 
		file="Interface\\WorldMap\\UI-WorldMap-Top3",
	},
	{	
		name="WorldMapFrameTexture4", 
		file="Interface\\WorldMap\\UI-WorldMap-Top4",
	},
	{	
		name="WorldMapFrameTexture5", 
		file="Interface\\WorldMap\\UI-WorldMap-Middle1",
	},
	{	
		name="WorldMapFrameTexture6", 
		file="Interface\\WorldMap\\UI-WorldMap-Middle2",
	},
	{	
		name="WorldMapFrameTexture7", 
		file="Interface\\WorldMap\\UI-WorldMap-Middle3",
	},
	{	
		name="WorldMapFrameTexture8", 
		file="Interface\\WorldMap\\UI-WorldMap-Middle4",
	},
	{	
		name="WorldMapFrameTexture9", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom1",
	},
	{	
		name="WorldMapFrameTexture10", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom2",
	},
	{	
		name="WorldMapFrameTexture11", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom3",
	},
	{	
		name="WorldMapFrameTexture12", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom4",
	},
	{	
		name="WorldMapFrameTexture13", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom1-full",
	},
	{	
		name="WorldMapFrameTexture14", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom3-full",
	},
	{	
		name="WorldMapFrameTexture15", 
		file="Interface\\WorldMap\\UI-WorldMap-Bottom4-full",
	},
	{	
		name="WorldMapFrameTexture16", 
		file="Interface\\WorldMap\\UI-WorldMap-Top3-full",
	},
	{	
		name="WorldMapFrameTexture17", 
		file="Interface\\WorldMap\\UI-WorldMap-Top4-full",
	},
	{	
		name="WorldMapFrameTexture18", 
		file="Interface\\WorldMap\\UI-WorldMap-Top3-full",	-- vertex color is set to 0 in WorldMapFrame_OnLoad
	},	
}

function WorldMap_LoadTextures()
	for k, v in pairs(WORLDMAP_TEXTURES_TO_LOAD) do
		_G[v.name]:SetTexture(v.file);
	end
end

function WorldMap_ClearTextures()
	for i=1, NUM_WORLDMAP_OVERLAYS do
		_G["WorldMapOverlay"..i]:SetTexture(nil);
	end
	for i=1, NUM_WORLDMAP_DETAIL_TILES do
		_G["WorldMapFrameTexture"..i]:SetTexture(nil);
		_G["WorldMapDetailTile"..i]:SetTexture(nil);
	end
	for i = NUM_WORLDMAP_DETAIL_TILES + 1, NUM_WORLDMAP_DETAIL_TILES + NUM_WORLDMAP_PATCH_TILES do
		_G["WorldMapFrameTexture"..i]:SetTexture(nil);
	end
end


function WorldMapUnit_OnLoad(self)
	self:SetFrameLevel(self:GetFrameLevel() + 1);
end

function WorldMapUnit_OnEnter(self, motion)
	WorldMapPOIFrame.allowBlobTooltip = false;
	-- Adjust the tooltip based on which side the unit button is on
	local x, y = self:GetCenter();
	local parentX, parentY = self:GetParent():GetCenter();
	if ( x > parentX ) then
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT");
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end

	-- See which POI's are in the same region and include their names in the tooltip
	local unitButton;
	local newLineString = "";
	local tooltipText = "";

	-- Check player
	if ( WorldMapPlayer:IsMouseOver() ) then
		if ( PlayerIsPVPInactive(WorldMapPlayer.unit) ) then
			tooltipText = format(PLAYER_IS_PVP_AFK, UnitName(WorldMapPlayer.unit));
		else
			tooltipText = UnitName(WorldMapPlayer.unit);
		end
		newLineString = "\n";
	end
	-- Check party
	for i=1, MAX_PARTY_MEMBERS do
		unitButton = _G["WorldMapParty"..i];
		if ( unitButton:IsVisible() and unitButton:IsMouseOver() ) then
			if ( PlayerIsPVPInactive(unitButton.unit) ) then
				tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, UnitName(unitButton.unit));
			else
				tooltipText = tooltipText..newLineString..UnitName(unitButton.unit);
			end
			newLineString = "\n";
		end
	end
	-- Check Raid
	for i=1, MAX_RAID_MEMBERS do
		unitButton = _G["WorldMapRaid"..i];
		if ( unitButton:IsVisible() and unitButton:IsMouseOver() ) then
			if ( unitButton.name ) then
				-- Handle players not in your raid or party, but on your team
				if ( PlayerIsPVPInactive(unitButton.name) ) then
					tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, unitButton.name);
				else
					tooltipText = tooltipText..newLineString..unitButton.name;		
				end
			else
				if ( PlayerIsPVPInactive(unitButton.unit) ) then
					tooltipText = tooltipText..newLineString..format(PLAYER_IS_PVP_AFK, UnitName(unitButton.unit));
				else
					tooltipText = tooltipText..newLineString..UnitName(unitButton.unit);
				end
			end
			newLineString = "\n";
		end
	end
	-- Check Vehicles
	local numVehicles = GetNumBattlefieldVehicles();
	for _, v in pairs(MAP_VEHICLES) do
		if ( v:IsVisible() and v:IsMouseOver() ) then
			if ( v.name ) then
				tooltipText = tooltipText..newLineString..v.name;
			end
			newLineString = "\n";
		end
	end
	-- Check debug objects
	for i = 1, NUM_WORLDMAP_DEBUG_OBJECTS do
		unitButton = _G["WorldMapDebugObject"..i];
		if ( unitButton:IsVisible() and unitButton:IsMouseOver() ) then
			tooltipText = tooltipText..newLineString..unitButton.name;
			newLineString = "\n";
		end
	end
	WorldMapTooltip:SetText(tooltipText);
	WorldMapTooltip:Show();
end

function WorldMapUnit_OnLeave(self, motion)
	WorldMapPOIFrame.allowBlobTooltip = true;
	WorldMapTooltip:Hide();
end

function WorldMapUnit_OnEvent(self, event, ...)
	if ( event == "UNIT_AURA" ) then
		if ( self.unit ) then
			local unit = ...;
			if ( self.unit == unit ) then
				WorldMapUnit_Update(self);
			end
		end
	end
end

function WorldMapUnit_OnMouseUp(self, mouseButton, raidUnitPrefix, partyUnitPrefix)
	if ( GetCVar("enablePVPNotifyAFK") == "0" ) then
		return;
	end

	if ( mouseButton == "RightButton" ) then
		BAD_BOY_COUNT = 0;

		local inInstance, instanceType = IsInInstance();
		if ( instanceType == "pvp" ) then
			--Check Raid
			local unitButton;
			for i=1, MAX_RAID_MEMBERS do
				unitButton = _G[raidUnitPrefix..i];
				if ( unitButton.unit and unitButton:IsVisible() and unitButton:IsMouseOver() and
					 not PlayerIsPVPInactive(unitButton.unit) ) then
					BAD_BOY_COUNT = BAD_BOY_COUNT + 1;
					BAD_BOY_UNITS[BAD_BOY_COUNT] = unitButton.unit;
				end
			end
			if ( BAD_BOY_COUNT > 0 ) then
				-- Check party
				for i=1, MAX_PARTY_MEMBERS do
					unitButton = _G[partyUnitPrefix..i];
					if ( unitButton.unit and unitButton:IsVisible() and unitButton:IsMouseOver() and
						 not PlayerIsPVPInactive(unitButton.unit) ) then
						BAD_BOY_COUNT = BAD_BOY_COUNT + 1;
						BAD_BOY_UNITS[BAD_BOY_COUNT] = unitButton.unit;
					end
				end
			end
		end

		if ( BAD_BOY_COUNT > 0 ) then
			UIDropDownMenu_Initialize( WorldMapUnitDropDown, WorldMapUnitDropDown_Initialize, "MENU");
			ToggleDropDownMenu(1, nil, WorldMapUnitDropDown, self:GetName(), 0, -5);
		end
	end
end

function WorldMapUnit_OnShow(self)
	self:RegisterEvent("UNIT_AURA");
	WorldMapUnit_Update(self);
end

function WorldMapUnit_OnHide(self)
	self:UnregisterEvent("UNIT_AURA");
end

function WorldMapUnit_Update(self)
	-- check for pvp inactivity (pvp inactivity is a debuff so make sure you call this when you get a UNIT_AURA event)
	local player = self.unit or self.name;

	if player and PlayerIsPVPInactive(player) then
		self.icon:SetVertexColor(0.5, 0.5, 0.5)
	else
		local _, class = UnitClass(player)
		if class then
			local color = RAID_CLASS_COLORS[class]
			self.icon:SetVertexColor(color:GetRGBA())
		else
			self.icon:SetVertexColor(1.0, 1.0, 1.0)
		end
	end
end

function WorldMapUnitDropDown_Initialize()
	local info = UIDropDownMenu_CreateInfo();
	info.text = PVP_REPORT_AFK;
	info.notClickable = 1;
	info.isTitle = 1;
	UIDropDownMenu_AddButton(info);

	if ( BAD_BOY_COUNT > 0 ) then
		for i=1, BAD_BOY_COUNT do
			info = UIDropDownMenu_CreateInfo();
			info.func = WorldMapUnitDropDown_OnClick;
			info.arg1 = BAD_BOY_UNITS[i];
			info.text = UnitName( BAD_BOY_UNITS[i] );
			UIDropDownMenu_AddButton(info);
		end
		
		if ( BAD_BOY_COUNT > 1 ) then
			info = UIDropDownMenu_CreateInfo();
			info.func = WorldMapUnitDropDown_ReportAll_OnClick;
			info.text = PVP_REPORT_AFK_ALL;
			UIDropDownMenu_AddButton(info);
		end
	end

	info = UIDropDownMenu_CreateInfo();
	info.text = CANCEL;
	UIDropDownMenu_AddButton(info);
end

function WorldMapUnitDropDown_OnClick(self, unit)
	ReportPlayerIsPVPAFK(unit);
end

function WorldMapUnitDropDown_ReportAll_OnClick()
	if ( BAD_BOY_COUNT > 0 ) then
		for i=1, BAD_BOY_COUNT do
			ReportPlayerIsPVPAFK(BAD_BOY_UNITS[i]);
		end
	end
end

function WorldMapFrame_ToggleWindowSize()
	local continentID, dungeonLevel;
	local mapID = GetCurrentMapAreaID() - 1;
	if ( mapID < 0 ) then
		continentID = GetCurrentMapContinent();
	else
		dungeonLevel = GetCurrentMapDungeonLevel();
	end
	-- close the frame first so the UI panel system can do its thing	
	ToggleFrame(WorldMapFrame);
	-- apply magic
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		SetCVar("miniWorldMap", 0);
		WorldMap_ToggleSizeUp();
	else
		SetCVar("miniWorldMap", 1);
		WorldMap_ToggleSizeDown();
	end
	-- reopen the frame
	WorldMapFrame.blockWorldMapUpdate = true;
	ToggleFrame(WorldMapFrame);
	if ( continentID ) then
		SetMapZoom(continentID);
	else
		SetMapByID(mapID);
		if ( dungeonLevel > 0 ) then
			SetDungeonMapLevel(dungeonLevel);
		end
	end
	WorldMapFrame.blockWorldMapUpdate = nil;
	WorldMapFrame_UpdateMap();
end

function WorldMap_ToggleSizeUp()
	WORLDMAP_SETTINGS.size = WORLDMAP_QUESTLIST_SIZE;
	-- adjust main frame
	WorldMapFrame:SetParent(nil);
	WorldMapFrame_ResetFrameLevels();
	WorldMapFrame:ClearAllPoints();
	WorldMapFrame:SetAllPoints();
	WorldMapFrame:SetAttribute("UIPanelLayout-area", "full");
	WorldMapFrame:SetAttribute("UIPanelLayout-allowOtherPanels", false);
	WorldMapFrame:EnableMouse(true);
	WorldMapFrame:EnableKeyboard(true);
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints();
	WorldMapPositioningGuide:SetPoint("CENTER");		
	WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99);
	WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapBlobFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapBlobFrame.xRatio = nil;		-- force hit recalculations
	-- show big window elements
	BlackoutWorld:Show();
	WorldMapZoneMinimapDropDown:Show();
	WorldMapZoomOutButton:Show();
	WorldMapZoneDropDown:Show();
	WorldMapContinentDropDown:Show();
	WorldMapQuestScrollFrame:Show();
	WorldMapQuestDetailScrollFrame:Show();
	WorldMapQuestRewardScrollFrame:Show();		
	WorldMapFrameSizeDownButton:Show();
	-- hide small window elements
	WorldMapTitleButton:Hide();
	WorldMapFrameMiniBorderLeft:Hide();
	WorldMapFrameMiniBorderRight:Hide();		
	WorldMapFrameSizeUpButton:Hide();
	ToggleMapFramerate();
	-- floor dropdown
	WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -50, -35);
	WorldMapLevelDropDown.header:Show();
	-- tiny adjustments	
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, 4, 4);
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapPositioningGuide, -16, 4);
	WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapPositioningGuide, "BOTTOMLEFT", 16, 4);
	WorldMapFrameTitle:ClearAllPoints();
	WorldMapFrameTitle:SetPoint("CENTER", 0, 372);
	WorldMapTooltip:SetFrameStrata("TOOLTIP");
	
	WorldMapFrame_SetOpacity(0);
	WorldMapFrame_SetPOIMaxBounds();
	WorldMapQuestShowObjectives_AdjustPosition();
	WorldMapFrame_DisplayQuests(WORLDMAP_SETTINGS.selectedQuestId)
end

function WorldMap_ToggleSizeDown()
	WORLDMAP_SETTINGS.size = WORLDMAP_WINDOWED_SIZE;
	-- adjust main frame
	WorldMapFrame:SetParent(UIParent);
	WorldMapFrame_ResetFrameLevels();
	WorldMapFrame:EnableMouse(false);
	WorldMapFrame:EnableKeyboard(false);
	-- adjust map frames
	WorldMapPositioningGuide:ClearAllPoints();
	WorldMapPositioningGuide:SetAllPoints();		
	WorldMapDetailFrame:SetScale(WORLDMAP_WINDOWED_SIZE);
	WorldMapButton:SetScale(WORLDMAP_WINDOWED_SIZE);
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_WINDOWED_SIZE);
	WorldMapBlobFrame:SetScale(WORLDMAP_WINDOWED_SIZE);
	WorldMapBlobFrame.xRatio = nil;		-- force hit recalculations
	-- hide big window elements
	BlackoutWorld:Hide();
	WorldMapZoneMinimapDropDown:Hide();
	WorldMapZoomOutButton:Hide();
	WorldMapZoneDropDown:Hide();
	WorldMapContinentDropDown:Hide();
	WorldMapLevelUpButton:Hide();
	WorldMapLevelDownButton:Hide();
	WorldMapQuestScrollFrame:Hide();
	WorldMapQuestDetailScrollFrame:Hide();
	WorldMapQuestRewardScrollFrame:Hide();		
	WorldMapFrameSizeDownButton:Hide();
	WorldMapFrameStoryHeader:Hide();
	ToggleMapFramerate();	
	-- show small window elements
	WorldMapTitleButton:Show();
	WorldMapFrameMiniBorderLeft:Show();
	WorldMapFrameMiniBorderRight:Show();		
	WorldMapFrameSizeUpButton:Show();
	-- floor dropdown
	WorldMapLevelDropDown:SetPoint("TOPRIGHT", WorldMapPositioningGuide, "TOPRIGHT", -441, -35);
	WorldMapLevelDropDown:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL + 2);
	WorldMapLevelDropDown.header:Hide();
	-- tiny adjustments
	WorldMapFrameCloseButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -44, 5);
	WorldMapFrameSizeDownButton:SetPoint("TOPRIGHT", WorldMapFrameMiniBorderRight, "TOPRIGHT", -66, 5);
	WorldMapTrackQuest:SetPoint("BOTTOMLEFT", WorldMapDetailFrame, "BOTTOMLeft", 2, -26);
	WorldMapFrameTitle:ClearAllPoints();
	WorldMapFrameTitle:SetPoint("TOP", WorldMapDetailFrame, 0, 20);
	WorldMapTooltip:SetFrameStrata("TOOLTIP");
	-- managed or user-placed?
	WorldMapFrame_SetMiniMode();
	
	WorldMapFrame_SetOpacity(WORLDMAP_SETTINGS.opacity);
	WorldMapFrame_SetPOIMaxBounds();
	WorldMapQuestShowObjectives_AdjustPosition();
end

function WorldMapFrame_ResetFrameLevels()
	WorldMapFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL - 13);
	WorldMapDetailFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL - 12);
	WorldMapBlobFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL - 11);
	WorldMapButton:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL - 10);
	WorldMapPOIFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL);
	-- PlayerArrowEffectFrame is created in code: CWorldMap::CreatePlayerArrowFrame()
	PlayerArrowEffectFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL + 100);
end

function WorldMapQuestShowObjectives_Toggle()
	if ( WorldMapQuestShowObjectives:GetChecked() ) then
		WatchFrame.showObjectives = true;
		QuestLogFrameShowMapButton:Show();		
	else
		WatchFrame.showObjectives = nil;
		WatchFrame_Update();
		QuestLogFrameShowMapButton:Hide();	
	end
end

function WorldMapQuestShowObjectives_AdjustPosition()
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", -3 - WorldMapQuestShowObjectivesText:GetWidth(), -26);
	else
		WorldMapQuestShowObjectives:SetPoint("BOTTOMRIGHT", WorldMapPositioningGuide, "BOTTOMRIGHT", -15 - WorldMapQuestShowObjectivesText:GetWidth(), 4);
	end
end

function WorldMapFrame_DisplayQuests(selectQuestId)
	WorldMapQuestRewardScrollFrameAbandonFrame:Hide()
	local mapID = GetCurrentMapAreaID() - 1;
	local storyAchievementID = C_QuestLog.GetZoneStoryInfo(mapID);
	local numQuests = WorldMapFrame_UpdateQuests()
	if ( numQuests > 0 or storyAchievementID ) then
		if ( numQuests > 0 and selectQuestId ) then
			-- select the requested quest
			WorldMapFrame_SelectQuestById(selectQuestId);
		elseif ( numQuests > 0 and WORLDMAP_SETTINGS.selectedQuestId and WORLDMAP_SETTINGS.selectedQuestId > 0 ) then
			-- try to select previously selected quest
			WorldMapFrame_SelectQuestById(WORLDMAP_SETTINGS.selectedQuestId);
		elseif _G["WorldMapQuestFrame1"] ~= nil and numQuests > 0 then
			-- select the first quest
			WorldMapFrame_SelectQuestFrame(_G["WorldMapQuestFrame1"]);
		end
		if ( WORLDMAP_SETTINGS.size == WORLDMAP_FULLMAP_SIZE ) then
			WorldMapFrame_SetQuestMapView();
		end
		if numQuests > 0 then
			WorldMapBlobFrame:Show();
			WorldMapPOIFrame:Show();
			WorldMapTrackQuest:Show();
		else
			WorldMapBlobFrame:Hide();
			WorldMapPOIFrame:Hide();
			WorldMapTrackQuest:Hide();
		end

		if storyAchievementID and WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE then
			WorldMapFrameStoryHeader:Show();
		else
			WorldMapFrameStoryHeader:Hide();
		end
	else
		if ( WORLDMAP_SETTINGS.size == WORLDMAP_QUESTLIST_SIZE ) then
			WorldMapFrame_SetFullMapView();
		end
		WorldMapBlobFrame:Hide();
		WorldMapPOIFrame:Hide();
		WorldMapTrackQuest:Hide();
	end
end

function WorldMapFrame_SelectQuestById(questId)
	local questFrame;
	for i = 1, MAX_NUM_QUESTS do
		questFrame = _G["WorldMapQuestFrame"..i];
		if ( not questFrame ) then
			break
		elseif ( questFrame.questId == questId ) then
			WorldMapFrame_SelectQuestFrame(questFrame);
			return;
		end
	end
	-- failed to find quest by id
	WorldMapFrame_SelectQuestFrame(_G["WorldMapQuestFrame1"]);
end

function WorldMapFrame_SetQuestMapView()
	WORLDMAP_SETTINGS.size = WORLDMAP_QUESTLIST_SIZE;
	WorldMapDetailFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapButton:SetScale(WORLDMAP_QUESTLIST_SIZE);
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_QUESTLIST_SIZE);			
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -726, -99);
	WorldMapQuestDetailScrollFrame:Show();
	WorldMapQuestRewardScrollFrame:Show();
	WorldMapQuestScrollFrame:Show();
	for i = NUM_WORLDMAP_DETAIL_TILES + 1, NUM_WORLDMAP_DETAIL_TILES + NUM_WORLDMAP_PATCH_TILES do
		_G["WorldMapFrameTexture"..i]:Hide();
	end
end

function WorldMapFrame_SetFullMapView()
	WORLDMAP_SETTINGS.size = WORLDMAP_FULLMAP_SIZE;
	WorldMapDetailFrame:SetScale(WORLDMAP_FULLMAP_SIZE);
	WorldMapButton:SetScale(WORLDMAP_FULLMAP_SIZE);
	WorldMapFrameAreaFrame:SetScale(WORLDMAP_FULLMAP_SIZE);			
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -502, -69);
	WorldMapQuestDetailScrollFrame:Hide();
	WorldMapQuestRewardScrollFrame:Hide();
	WorldMapQuestScrollFrame:Hide();
	WorldMapFrameStoryHeader:Hide();
	for i = NUM_WORLDMAP_DETAIL_TILES + 1, NUM_WORLDMAP_DETAIL_TILES + NUM_WORLDMAP_PATCH_TILES do
		_G["WorldMapFrameTexture"..i]:Show();
	end
end

function WorldMapFrame_UpdateMap(questId)
	WorldMapFrame_Update();
	WorldMapContinentsDropDown_Update();
	WorldMapZoneDropDown_Update();
	WorldMapLevelDropDown_Update();
	WorldMapFrame_SetMapName();
	if ( WatchFrame.showObjectives ) then
		WorldMapFrame_DisplayQuests(questId);
	end
end

function WorldMapFrame_UpdateQuests()
	local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily;
	local questId, questLogIndex;
	local questFrame;
	local lastFrame;
	local refFrame = WorldMapQuestFrame0;
	local questCount = 0;
	local numObjectives;
	local playerMoney = GetMoney();
	
	local numPOINumeric = 0;
	local numPOICompleteSwap = 0;

	local mapID = GetCurrentMapAreaID() - 1;
	local storyAchievementID, atlasName = C_QuestLog.GetZoneStoryInfo(mapID);
	
	local numEntries = QuestMapUpdateAllQuests();
	WorldMapFrame_ClearQuestPOIs();
	QuestPOIUpdateIcons();
	if ( WorldMapQuestScrollFrame.highlightedFrame ) then
		WorldMapQuestScrollFrame.highlightedFrame.ownPOI:UnlockHighlight();
	end
	QuestPOI_HideAllButtons("WorldMapQuestScrollChildFrame");
	-- populate quest frames
	for i = 1, numEntries do
		questId, questLogIndex = QuestPOIGetQuestIDByVisibleIndex(i);
		if ( questLogIndex and questLogIndex > 0 ) then
			questCount = questCount + 1;
			title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questLogIndex);
			local requiredMoney = GetQuestLogRequiredMoney(questLogIndex);
			numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			if ( isComplete and isComplete < 0 ) then
				isComplete = false;
			elseif ( numObjectives == 0 and playerMoney >= requiredMoney ) then
				isComplete = true;
			end
			questFrame = WorldMapFrame_GetQuestFrame(questCount, isComplete);
			if ( lastFrame ) then
				questFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, 0);
			else
				questFrame:SetPoint("TOPLEFT", WorldMapQuestScrollChildFrame, "TOPLEFT", 2, storyAchievementID and -50 or 0);
			end
			-- set up indexes
			questFrame.questId = questId;
			questFrame.questLogIndex = questLogIndex;
			questFrame.completed = isComplete;
			questFrame.level = level;		-- for difficulty color
			-- display map POI and turn off blob
			WorldMapFrame_DisplayQuestPOI(questFrame, isComplete);
			WorldMapBlobFrame:DrawQuestBlob(questFrame.questId, false);
			-- set quest text
			questFrame.title:SetText(title);
			if ( IsQuestWatched(questLogIndex) ) then
				questFrame.title:SetWidth(224);
				questFrame.check:Show();
			else
				questFrame.title:SetWidth(240);
				questFrame.check:Hide();
			end
			numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			if ( isComplete ) then
				numPOICompleteSwap = numPOICompleteSwap + 1;
				questFrame.objectives:SetText(GetQuestLogCompletionText(questLogIndex));
				questFrame.dashes:SetText(QUEST_DASH);
			else
				numPOINumeric = numPOINumeric + 1;
				local questText = "";
				local dashText = "";
				local numLines;
				for j = 1, numObjectives do
					local text, _, finished = GetQuestLogLeaderBoard(j, questLogIndex);
					if ( text and not finished ) then
						questText = questText..WorldMapFrame_ReverseQuestObjective(text).."|n";
					end
					refFrame.objectives:SetText(text);
					-- need to add 1 spacing's worth to height because for n number of lines there are n-1 spacings
					numLines = (refFrame.objectives:GetHeight() + refFrame.lineSpacing) / refFrame.lineHeight;
					-- round numLines to the closest integer
					numLines = floor(numLines + 0.5);
					dashText = dashText..QUEST_DASH..string.rep("|n", numLines);
				end
				if ( requiredMoney > playerMoney ) then
					questText = questText.."- "..GetMoneyString(playerMoney).." / "..GetMoneyString(requiredMoney);
					dashText = dashText..QUEST_DASH;
				end				
				questFrame.objectives:SetText(questText);
				questFrame.dashes:SetText(dashText);
			end
			-- difficulty
			if ( MAP_QUEST_DIFFICULTY == "1" ) then
				local color
				if GetQuestScaling(questId) then
					color = QuestDifficultyColors["standard"]
				else
					color = GetQuestDifficultyColor(level);
				end
				questFrame.title:SetTextColor(color.r, color.g, color.b);
			end
			-- size and show
			questFrame:SetHeight(max(questFrame.title:GetHeight() + questFrame.objectives:GetHeight() + QUESTFRAME_PADDING, QUESTFRAME_MINHEIGHT));
			questFrame:Show();
			lastFrame = questFrame;
		end
	end
	WorldMapFrame.numQuests = questCount;
	-- hide frames not being used for this map
	for i = questCount + 1, MAX_NUM_QUESTS do
		questFrame = _G["WorldMapQuestFrame"..i];
		if ( not questFrame ) then
			break;
		end		
		questFrame:Hide();
		WorldMapBlobFrame:DrawQuestBlob(questFrame.questId, false);
		questFrame.questId = 0;
	end
	QuestPOI_HideButtons("WorldMapPOIFrame", QUEST_POI_NUMERIC, numPOINumeric + 1);
	QuestPOI_HideButtons("WorldMapPOIFrame", QUEST_POI_COMPLETE_SWAP, numPOICompleteSwap + 1);

	-- Display the zone story stuff if appropriate, updating separators as necessary...
	if storyAchievementID then
		local _, achievementName = GetAchievementInfo(storyAchievementID)
		WorldMapFrameStoryHeaderText:SetText(achievementName);
		local numCriteria = GetAchievementNumCriteria(storyAchievementID);
		local completedCriteria = 0;
		for i = 1, numCriteria do
			local _, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i);
			if ( completed ) then
				completedCriteria = completedCriteria + 1;
			end
		end
		WorldMapFrameStoryHeaderProgressCount:SetFormattedText(STORY_CHAPTERS, completedCriteria, numCriteria);
		WorldMapFrameStoryHeaderBackground:SetAtlas(atlasName);
	end

	return questCount;
end

function WorldMapFrame_SelectQuestFrame(questFrame)
	WorldMapQuestRewardScrollFrameAbandonFrame:Hide()
	local poiIcon;
	local color;
	-- clear current selection	
	if ( WORLDMAP_SETTINGS.selectedQuest ) then
		local currentSelection = WORLDMAP_SETTINGS.selectedQuest;
		poiIcon = currentSelection.poiIcon;
		QuestPOI_DeselectButton(poiIcon);
		QuestPOI_DeselectButtonByParent("WorldMapQuestScrollChildFrame");
		WorldMapBlobFrame:DrawQuestBlob(currentSelection.questId, false);
		if ( MAP_QUEST_DIFFICULTY == "1" ) then
			if GetQuestScaling(currentSelection.questId) then
				color = QuestDifficultyColors["standard"]
			else
				color = GetQuestDifficultyColor(currentSelection.level);
			end
			currentSelection.title:SetTextColor(color.r, color.g, color.b);
		end
		poiIcon:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL);
	end
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		PlayerArrowEffectFrame:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL + 100);
	end
	
	WORLDMAP_SETTINGS.selectedQuest = questFrame;
	WORLDMAP_SETTINGS.selectedQuestId = questFrame.questId;
	WorldMapQuestSelectedFrame:SetPoint("TOPLEFT", questFrame, "TOPLEFT", -10, 0);
	WorldMapQuestSelectedFrame:SetHeight(questFrame:GetHeight());
	WorldMapQuestSelectedFrame:Show();
	poiIcon = questFrame.poiIcon;
	QuestPOI_SelectButton(poiIcon);
	QuestPOI_SelectButton(questFrame.ownPOI);
	poiIcon:SetFrameLevel(WORLDMAP_POI_FRAMELEVEL + 1);
	SelectQuestLogEntry(questFrame.questLogIndex);
	SetAbandonQuest()
	-- colors
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		questFrame.title:SetTextColor(1, 1, 1);
		if GetQuestScaling(questFrame.questId) then
			color = QuestDifficultyColors["standard"]
		else
			color = GetQuestDifficultyColor(questFrame.level);
		end
		WorldMapQuestSelectBar:SetVertexColor(color.r, color.g, color.b);
	end
	-- only display quest info if worldmap frame is embiggened
	if ( WORLDMAP_SETTINGS.size ~= WORLDMAP_WINDOWED_SIZE ) then
		QuestInfo_Display(QUEST_TEMPLATE_MAP1, WorldMapQuestDetailScrollChildFrame);
		WorldMapQuestDetailScrollFrameScrollBar:SetValue(0);
		ScrollFrame_OnScrollRangeChanged(WorldMapQuestDetailScrollFrame);
		QuestInfo_Display(QUEST_TEMPLATE_MAP2, WorldMapQuestRewardScrollChildFrame);
		WorldMapQuestRewardScrollFrameScrollBar:SetValue(0);
		ScrollFrame_OnScrollRangeChanged(WorldMapQuestRewardScrollFrame);
	else
		-- need to select the appropriate poi in the objectives tracker
		QuestPOI_SelectButtonByQuestId("WatchFrameLines", questFrame.questId, true);
	end
	-- track quest checkbark
	WorldMapTrackQuest:SetChecked(IsQuestWatched(questFrame.questLogIndex));
	-- quest blob
	if ( questFrame.completed ) then
		WorldMapBlobFrame:DrawQuestBlob(questFrame.questId, false);
	else
		WorldMapBlobFrame:DrawQuestBlob(questFrame.questId, true);
	end
end

local numCompletedQuests = 0;
function WorldMapFrame_ClearQuestPOIs()
	QuestPOI_HideButtons("WorldMapPOIFrame", QUEST_POI_NUMERIC, 1);
	QuestPOI_HideButtons("WorldMapPOIFrame", QUEST_POI_COMPLETE_SWAP, 1);
	numCompletedQuests = 0;
end

function WorldMapFrame_DisplayQuestPOI(questFrame, isComplete)
	local index = questFrame.index;
	local poiButton;
	if ( isComplete ) then
		poiButton = QuestPOI_DisplayButton("WorldMapPOIFrame", QUEST_POI_COMPLETE_SWAP, index, questFrame.questId);
	else
		poiButton = QuestPOI_DisplayButton("WorldMapPOIFrame", QUEST_POI_NUMERIC, index - numCompletedQuests, questFrame.questId);
	end
	questFrame.poiIcon = poiButton;
	local _, posX, posY, objective = QuestPOIGetIconInfo(questFrame.questId);
	if ( posX and posY ) then
		local POIscale;
		if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
			POIscale = WORLDMAP_WINDOWED_SIZE;
		else
			POIscale = WORLDMAP_QUESTLIST_SIZE;
		end
		posX = posX * WorldMapDetailFrame:GetWidth() * POIscale;
		posY = -posY * WorldMapDetailFrame:GetHeight() * POIscale;
		-- keep outlying POIs within map borders
		if ( posY > WORLDMAP_POI_MIN_Y ) then
			posY = WORLDMAP_POI_MIN_Y;
		elseif ( posY < WORLDMAP_POI_MAX_Y ) then
			posY = WORLDMAP_POI_MAX_Y
		end
		if ( posX < WORLDMAP_POI_MIN_X ) then
			posX = WORLDMAP_POI_MIN_X;
		elseif ( posX > WORLDMAP_POI_MAX_X ) then
			posX = WORLDMAP_POI_MAX_X;
		end
		poiButton:SetPoint("CENTER", "WorldMapPOIFrame", "TOPLEFT", posX, posY);
	end
	poiButton.quest = questFrame;
end

function WorldMapFrame_SetPOIMaxBounds()
	WORLDMAP_POI_MAX_Y = WorldMapDetailFrame:GetHeight() * -WORLDMAP_SETTINGS.size + 12;
	WORLDMAP_POI_MAX_X = WorldMapDetailFrame:GetWidth() * WORLDMAP_SETTINGS.size + 12;
end

function WorldMapFrame_GetQuestFrame(index, isComplete)
	local frame = _G["WorldMapQuestFrame"..index];
	if ( not frame ) then
		frame = CreateFrame("Frame", "WorldMapQuestFrame"..index, WorldMapQuestScrollChildFrame, "WorldMapQuestFrameTemplate");
		frame.index = index;
	end
	
	local poiButton;
	if ( isComplete ) then
		numCompletedQuests = numCompletedQuests + 1;
		poiButton = QuestPOI_DisplayButton("WorldMapQuestScrollChildFrame", QUEST_POI_COMPLETE_IN, numCompletedQuests, 0);
	else
		poiButton = QuestPOI_DisplayButton("WorldMapQuestScrollChildFrame", QUEST_POI_NUMERIC, index - numCompletedQuests, 0);
	end
	poiButton:SetPoint("TOPLEFT", frame, 4, 0);
	frame.ownPOI = poiButton;
	return frame;
end

function WorldMapFrame_ReverseQuestObjective(text)
	local _, _, arg1, arg2 = string.find(text, "(.*):%s(.*)");
	if ( arg1 and arg2 ) then
		return arg2.." "..arg1;
	else
		return text;
	end
end

function WorldMapQuestFrame_OnEnter(self)
	self.ownPOI:LockHighlight();
	WorldMapQuestScrollFrame.highlightedFrame = self;
	if ( WORLDMAP_SETTINGS.selectedQuest == self ) then
		return;
	end
	WorldMapQuestHighlightedFrame:SetPoint("TOPLEFT", self, "TOPLEFT", -10, -1);
	WorldMapQuestHighlightedFrame:SetHeight(self:GetHeight() - 2);
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		local color
		if GetQuestScaling(self.questId) then
			color = QuestDifficultyColors["standard"]
		else
			color = GetQuestDifficultyColor(self.level);
		end
		self.title:SetTextColor(1, 1, 1);
		WorldMapQuestHighlightBar:SetVertexColor(color.r, color.g, color.b);
	end	
	WorldMapQuestHighlightedFrame:Show();
	if ( not self.completed ) then
		WorldMapBlobFrame:DrawQuestBlob(self.questId, true);
	end
end

function WorldMapQuestFrame_OnLeave(self)
	self.ownPOI:UnlockHighlight();
	WorldMapQuestScrollFrame.highlightedFrame = nil;
	if ( WORLDMAP_SETTINGS.selectedQuest == self ) then
		return;
	end
	if ( MAP_QUEST_DIFFICULTY == "1" ) then
		local color
		if GetQuestScaling(self.questId) then
			color = QuestDifficultyColors["standard"]
		else
			color = GetQuestDifficultyColor(self.level);
		end
		self.title:SetTextColor(color.r, color.g, color.b);
	end		
	WorldMapQuestHighlightedFrame:Hide();
	if ( not self.completed ) then
		WorldMapBlobFrame:DrawQuestBlob(self.questId, false);
	end
end

function WorldMapQuestFrame_OnMouseDown(self)
	self.title:SetPoint("TOPLEFT", 35, -9);
	self.ownPOI:SetButtonState("PUSHED");
	QuestPOIButton_OnMouseDown(self.ownPOI);	
end

function WorldMapQuestFrame_OnMouseUp(self)
	self.title:SetPoint("TOPLEFT", 34, -8);
	self.ownPOI:SetButtonState("NORMAL");
	QuestPOIButton_OnMouseUp(self.ownPOI);
	if ( self:IsMouseOver() ) then
		if ( WORLDMAP_SETTINGS.selectedQuest ~= self ) then
			WorldMapQuestHighlightedFrame:Hide();
			PlaySound("igMainMenuOptionCheckBoxOn");
			WorldMapFrame_SelectQuestFrame(self);
		end
		if ( IsShiftKeyDown() ) then
			local isChecked = not WorldMapTrackQuest:GetChecked();
			WorldMapTrackQuest:SetChecked(isChecked);		
			WorldMapTrackQuest_Toggle(isChecked);
			WorldMapQuestFrame_UpdateMouseOver();			
		end		
	end
end

function WorldMapQuestFrame_UpdateMouseOver()
	if ( WorldMapQuestScrollFrame:IsMouseOver() ) then
		for i = 1, WorldMapFrame.numQuests do
			questFrame = _G["WorldMapQuestFrame"..i];
			if ( questFrame:IsMouseOver() ) then
				WorldMapQuestFrame_OnEnter(questFrame);
				break;
			end
		end
	end
end

function WorldMapQuestPOI_OnClick(self)
	PlaySound("igMainMenuOptionCheckBoxOn");
	if ( self.quest ~= WORLDMAP_SETTINGS.selectedQuest ) then
		if ( WORLDMAP_SETTINGS.selectedQuest ) then
			WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, false);
		end
		WorldMapFrame_SelectQuestFrame(self.quest);
	end
	if ( IsShiftKeyDown() ) then
		local isChecked = not WorldMapTrackQuest:GetChecked();
		WorldMapTrackQuest:SetChecked(isChecked);		
		WorldMapTrackQuest_Toggle(isChecked);
	end
end

function WorldMapQuestPOI_OnEnter(self)
	WorldMapPOIFrame.allowBlobTooltip = false;
	WorldMapQuestPOI_SetTooltip(self, self.quest.questLogIndex);	
end

function WorldMapQuestPOI_OnLeave(self)
	WorldMapPOIFrame.allowBlobTooltip = true;
end

function WorldMapQuestPOI_SetTooltip(poiButton, questLogIndex, numObjectives)
	local title = GetQuestLogTitle(questLogIndex);
	WorldMapTooltip:SetOwner(WorldMapFrame, "ANCHOR_CURSOR_RIGHT", 5, 2);
	WorldMapTooltip:SetText(title);
	if ( poiButton and poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
		if ( poiButton.type == QUEST_POI_COMPLETE_SWAP ) then
			WorldMapTooltip:AddLine("- "..GetQuestLogCompletionText(questLogIndex), 1, 1, 1, 1);
		else
			local numObjectives = GetNumQuestLeaderBoards(questLogIndex);
			for i = 1, numObjectives do
				local text, _, finished = GetQuestLogLeaderBoard(i, questLogIndex);
				if ( text and not finished ) then
					WorldMapTooltip:AddLine("- "..WorldMapFrame_ReverseQuestObjective(text), 1, 1, 1, 1);
				end
			end
		end
	else
		local text, finished;
		local numItemDropTooltips = GetNumQuestItemDrops(questLogIndex);
		if(numItemDropTooltips and numItemDropTooltips > 0) then
			for i = 1, numItemDropTooltips do
				text, _, finished = GetQuestLogItemDrop(i, questLogIndex);
				if ( text and not finished ) then
					WorldMapTooltip:AddLine("- "..WorldMapFrame_ReverseQuestObjective(text), 1, 1, 1, 1);
				end
			end
		else
			local numPOITooltips = WorldMapBlobFrame:GetNumTooltips();
			numObjectives = numObjectives or GetNumQuestLeaderBoards(questLogIndex);
			for i = 1, numObjectives do
				if(numPOITooltips and (numPOITooltips == numObjectives)) then
					local questPOIIndex = WorldMapBlobFrame:GetTooltipIndex(i);
					text, _, finished = GetQuestPOILeaderBoard(questPOIIndex, questLogIndex);
				else
					text, _, finished = GetQuestLogLeaderBoard(i, questLogIndex);
				end
				if ( text and not finished ) then
					WorldMapTooltip:AddLine("- "..WorldMapFrame_ReverseQuestObjective(text), 1, 1, 1, 1);
				end
			end		
		end
	end	
	WorldMapTooltip:Show();
end

function WorldMapBlobFrame_OnLoad(self)
	self:SetFillTexture("Interface\\WorldMap\\UI-QuestBlob-Inside");
	self:SetBorderTexture("Interface\\WorldMap\\UI-QuestBlob-Outside");
	self:SetFillAlpha(128);
	self:SetBorderAlpha(192);
	self:SetBorderScalar(1.0);
end

function WorldMapBlobFrame_OnUpdate(self)
	if ( not WorldMapPOIFrame.allowBlobTooltip or not WorldMapDetailFrame:IsMouseOver() ) then
		return;
	end
	if ( not self.xRatio ) then
		WorldMapBlobFrame_CalculateHitTranslations();
	end
	local x, y = GetCursorPosition();
	local adjustedX = x / self.xRatio - self.xOffset;
	local adjustedY = self.yOffset - y / self.yRatio;
	local questLogIndex, numObjectives = self:UpdateMouseOverTooltip(adjustedX, adjustedY);
	if(numObjectives) then
		WorldMapTooltip:SetOwner(WorldMapFrame, "ANCHOR_CURSOR");
		WorldMapQuestPOI_SetTooltip(nil, questLogIndex, numObjectives);
	else
		WorldMapTooltip:Hide();
	end
end

function WorldMapBlobFrame_CalculateHitTranslations()
	local self = WorldMapBlobFrame;
	local centerX, centerY = self:GetCenter();
	local width = self:GetWidth();
	local height = self:GetHeight();
	local scale = self:GetEffectiveScale();
	self.yOffset = centerY / height + 0.5;
	self.yRatio = height * scale;
	self.xOffset = centerX / width - 0.5;
	self.xRatio = width * scale;
end

function WorldMapFrame_ResetQuestColors()
	if ( MAP_QUEST_DIFFICULTY == "0" ) then
		WorldMapQuestSelectBar:SetVertexColor(1, 0.824, 0);
		WorldMapQuestHighlightBar:SetVertexColor(0.243, 0.570, 1);
		for i = 1, MAX_NUM_QUESTS do
			local questFrame = _G["WorldMapQuestFrame"..i];
			if ( not questFrame ) then
				break;
			end
			questFrame.title:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		end
	end
end

function WorldMap_OpenToQuest(questID, frameToShowOnClose)
	WORLDMAP_SETTINGS.selectedQuestId = questID;
	WorldMapFrame.blockWorldMapUpdate = true;
	ShowUIPanel(WorldMapFrame);	
	local mapID, floorNumber = GetQuestWorldMapAreaID(questID);
	if ( mapID ~= 0 ) then
		SetMapByID(mapID);
		if ( floorNumber ~= 0 ) then
			SetDungeonMapLevel(floorNumber);
		end
	end
	WorldMapFrame.blockWorldMapUpdate = nil;
	WorldMapFrame_UpdateMap(questID);	
end

function WorldMapFrame_SetMapName()
	local mapName = WORLD_MAP;
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		local zoneId = UIDropDownMenu_GetSelectedID(WorldMapZoneDropDown);
		-- zoneId is nil for instances, Azeroth, or the cosmic view, in which case we'll keep the "World Map" title
		if ( zoneId ) then
			if ( zoneId > 0 ) then
				mapName = UIDropDownMenu_GetText(WorldMapZoneDropDown);
			elseif ( UIDropDownMenu_GetSelectedID(WorldMapContinentDropDown) > 0 ) then
				mapName = UIDropDownMenu_GetText(WorldMapContinentDropDown);
			end
		end
	end
	WorldMapFrameTitle:SetText(mapName);
end

--- advanced options ---
function WorldMapFrame_ToggleAdvanced()
	WORLDMAP_SETTINGS.advanced = GetCVarBool("advancedWorldMap");
	WorldMapScreenAnchor:StartMoving();
	WorldMapScreenAnchor:SetPoint("TOPLEFT", 10, -118);
	WorldMapScreenAnchor:StopMovingOrSizing();	
	if ( WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE ) then
		WorldMapFrame_SetMiniMode();
	end
end

function WorldMapFrame_SetMiniMode()
	WorldMapFrame:ClearAllPoints();
	if ( WORLDMAP_SETTINGS.advanced ) then
		if ( not WorldMapFrame:GetAttribute("UIPanelLayout-defined") ) then
			UIPanelWindows["WorldMapFrame"].area = "center";
			UIPanelWindows["WorldMapFrame"].allowOtherPanels = true;
		else
			WorldMapFrame:SetAttribute("UIPanelLayout-area", "center");
			WorldMapFrame:SetAttribute("UIPanelLayout-allowOtherPanels", true);
		end
		WorldMapFrame:SetMovable("true");
		WorldMapFrame:SetWidth(593);		
		WorldMapFrame:SetPoint("TOPLEFT", WorldMapScreenAnchor, 0, 0);
		WorldMapFrameMiniBorderLeft:SetPoint("TOPLEFT", 0, 0);		
		WorldMapDetailFrame:SetPoint("TOPLEFT", 19, -42);
	else
		if ( not WorldMapFrame:GetAttribute("UIPanelLayout-defined") ) then
			UIPanelWindows["WorldMapFrame"].area = "doublewide";
			UIPanelWindows["WorldMapFrame"].allowOtherPanels = false;
		else
			WorldMapFrame:SetAttribute("UIPanelLayout-area", "doublewide");
			WorldMapFrame:SetAttribute("UIPanelLayout-allowOtherPanels", false);
		end
		WorldMapFrame:SetMovable("false");
		WorldMapFrame:SetWidth(623);	-- extra width so it tiles nicely
		WorldMapFrameMiniBorderLeft:SetPoint("TOPLEFT", 10, -14);		
		WorldMapDetailFrame:SetPoint("TOPLEFT", 37, -66);
	end
	WorldMapFrame:SetHeight(437);	
end

function WorldMapTitleButton_OnLoad(self)
	self:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonUp");
	self:RegisterForDrag("LeftButton");
	UIDropDownMenu_Initialize(WorldMapTitleDropDown, WorldMapTitleDropDown_Initialize, "MENU");
end

function WorldMapTitleButton_OnClick(self, button)
	PlaySound("UChatScrollButton");

	-- hide the opacity frame on any click
	if ( OpacityFrame:IsShown() and OpacityFrame.saveOpacityFunc and OpacityFrame.saveOpacityFunc == WorldMapFrame_SaveOpacity ) then
		WorldMapFrame_SaveOpacity();
		OpacityFrame.saveOpacityFunc = nil;
		OpacityFrame:Hide();
	end
	
	-- If Rightclick bring up the options menu
	if ( button == "RightButton" ) then
		ToggleDropDownMenu(1, nil, WorldMapTitleDropDown, "cursor", 0, 0);
		return;
	end

	-- Close all dropdowns
	CloseDropDownMenus();
end

function WorldMapTitleButton_OnDragStart()
	if ( WORLDMAP_SETTINGS.advanced and not WORLDMAP_SETTINGS.locked ) then
		if ( WORLDMAP_SETTINGS.selectedQuest ) then
			WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, false);
		end
		WorldMapScreenAnchor:ClearAllPoints();
		WorldMapFrame:ClearAllPoints();
		WorldMapFrame:StartMoving();	
	end
end

function WorldMapTitleButton_OnDragStop()
	if ( WORLDMAP_SETTINGS.advanced and not WORLDMAP_SETTINGS.locked ) then
		WorldMapFrame:StopMovingOrSizing();
		WorldMapBlobFrame_CalculateHitTranslations();
		if ( WORLDMAP_SETTINGS.selectedQuest and not WORLDMAP_SETTINGS.selectedQuest.completed ) then
			WorldMapBlobFrame:DrawQuestBlob(WORLDMAP_SETTINGS.selectedQuestId, true);
		end		
		-- move the anchor
		WorldMapScreenAnchor:StartMoving();
		WorldMapScreenAnchor:SetPoint("TOPLEFT", WorldMapFrame);
		WorldMapScreenAnchor:StopMovingOrSizing();
	end
end

function WorldMapTitleDropDown_Initialize()
	local checked;
	local info = UIDropDownMenu_CreateInfo();

	-- Lock/Unlock
	if ( WORLDMAP_SETTINGS.advanced ) then
		info.text = LOCK_WINDOW;
		info.func = WorldMapTitleDropDown_ToggleLock;
		info.checked = WORLDMAP_SETTINGS.locked;
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);
	end
	
	-- Opacity
	info.text = CHANGE_OPACITY;
	info.func = WorldMapTitleDropDown_ToggleOpacity;
	info.checked = nil;
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL);	
end

function WorldMapTitleDropDown_ToggleLock()
	WORLDMAP_SETTINGS.locked = not WORLDMAP_SETTINGS.locked;
end

function WorldMapTitleDropDown_ToggleOpacity()
	if ( OpacityFrame:IsShown() ) then
		OpacityFrame:Hide();
		return;
	end
	OpacityFrame:ClearAllPoints();
	if ( WorldMapFrame:GetCenter() < GetScreenWidth() / 2 ) then
		OpacityFrame:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPRIGHT", 5, 10);
	else
		OpacityFrame:SetPoint("TOPRIGHT", WorldMapDetailFrame, "TOPLEFT", -5, 10);
	end
	OpacityFrame.opacityFunc = WorldMapFrame_ChangeOpacity;
	OpacityFrame.saveOpacityFunc = WorldMapFrame_SaveOpacity;
	OpacityFrame:Show();
	OpacityFrameSlider:SetValue(WORLDMAP_SETTINGS.opacity);	
end

function WorldMapFrame_ChangeOpacity()
	WORLDMAP_SETTINGS.opacity = OpacityFrameSlider:GetValue();
	WorldMapFrame_SetOpacity(WORLDMAP_SETTINGS.opacity);
end

function WorldMapFrame_SaveOpacity()
	SetCVar("worldMapOpacity", OpacityFrameSlider:GetValue());
end

function WorldMapFrame_SetOpacity(opacity)
	local alpha;
	-- set border alphas
	alpha = 0.5 + (1.0 - opacity) * 0.50;
	WorldMapFrameMiniBorderLeft:SetAlpha(alpha);
	WorldMapFrameMiniBorderRight:SetAlpha(alpha);
	WorldMapFrameSizeUpButton:SetAlpha(alpha);
	WorldMapFrameCloseButton:SetAlpha(alpha);
	-- set map alpha
	alpha = 0.35 + (1.0 - opacity) * 0.65;
	WorldMapDetailFrame:SetAlpha(alpha);
	-- set blob alpha
	alpha = 0.45 + (1.0 - opacity) * 0.55;
	WorldMapPOIFrame:SetAlpha(alpha);
	WorldMapBlobFrame:SetFillAlpha(128 * alpha);
	WorldMapBlobFrame:SetBorderAlpha(192 * alpha);
end

function WorldMapTrackQuest_Toggle(isChecked)
	local questIndex = WORLDMAP_SETTINGS.selectedQuest.questLogIndex;
	if ( isChecked ) then
		if ( GetNumQuestWatches() > MAX_WATCHABLE_QUESTS ) then
			UIErrorsFrame:AddMessage(format(QUEST_WATCH_TOO_MANY, MAX_WATCHABLE_QUESTS), 1.0, 0.1, 0.1, 1.0);
			WorldMapTrackQuest:SetChecked(false);
			return;
		end
		if ( LOCAL_MAP_QUESTS["zone"] == GetCurrentMapZone() ) then
			LOCAL_MAP_QUESTS[WORLDMAP_SETTINGS.selectedQuestId] = true;
		end
		AddQuestWatch(questIndex);	
	else
		LOCAL_MAP_QUESTS[WORLDMAP_SETTINGS.selectedQuestId] = nil;
		RemoveQuestWatch(questIndex);
	end
	WatchFrame_Update();
	WorldMapFrame_DisplayQuests(WORLDMAP_SETTINGS.selectedQuestId);	
end

function WorldMapFrame_ShowStoryTooltip(self)
	local mapID = GetCurrentMapAreaID() - 1;
	local storyAchievementID = C_QuestLog.GetZoneStoryInfo(mapID);
	local maxWidth = 0;
	local totalHeight = 20;

	-- Clear out old quest criteria
	for i = 1, 12 do
		_G["WorldMapFrameStoryTooltipLine"..i]:Hide();
	end
	for i = 1, 12 do
		_G["WorldMapFrameStoryTooltipCheckMark"..i]:Hide();
	end

	local numCriteria = GetAchievementNumCriteria(storyAchievementID);
	local completedCriteria = 0;
	for i = 1, min(numCriteria, 12) do
		local title, _, completed = GetAchievementCriteriaInfo(storyAchievementID, i);
		if ( completed ) then
			completedCriteria = completedCriteria + 1;
		end
		if ( not _G["WorldMapFrameStoryTooltipLine"..i] ) then
			local fontString = WorldMapFrameStoryTooltip:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
			fontString:SetPoint("TOP", _G["WorldMapFrameStoryTooltipLine"..i-1], "BOTTOM", 0, -6);
			_G["WorldMapFrameStoryTooltipLine"..i] = fontString;
		end
		if ( completed ) then
			_G["WorldMapFrameStoryTooltipLine"..i]:SetText(GREEN_FONT_COLOR_CODE..title..FONT_COLOR_CODE_CLOSE);
			_G["WorldMapFrameStoryTooltipLine"..i]:SetPoint("LEFT", 30, 0);
			_G["WorldMapFrameStoryTooltipCheckMark"..i]:SetTexture("Interface\\Scenarios\\ScenarioIcon-Check" );
			_G["WorldMapFrameStoryTooltipCheckMark"..i]:ClearAllPoints();
			_G["WorldMapFrameStoryTooltipCheckMark"..i]:SetPoint("RIGHT", _G["WorldMapFrameStoryTooltipLine"..i], "LEFT", -4, -1);
			_G["WorldMapFrameStoryTooltipCheckMark"..i]:Show();
			maxWidth = max(maxWidth, _G["WorldMapFrameStoryTooltipLine"..i]:GetWidth() + 20);
		else
			_G["WorldMapFrameStoryTooltipLine"..i]:SetText(GRAY_FONT_COLOR_CODE..title..FONT_COLOR_CODE_CLOSE);
			_G["WorldMapFrameStoryTooltipLine"..i]:SetPoint("LEFT", 10, 0);
			_G["WorldMapFrameStoryTooltipCheckMark"..i]:Hide();
			maxWidth = max(maxWidth, _G["WorldMapFrameStoryTooltipLine"..i]:GetWidth());
		end
		_G["WorldMapFrameStoryTooltipLine"..i]:Show();
		totalHeight = totalHeight + _G["WorldMapFrameStoryTooltipLine"..i]:GetHeight() + 4.25;
	end

	maxWidth = max(maxWidth, WorldMapFrameStoryTooltipProgressLabel:GetWidth());
	totalHeight = totalHeight + WorldMapFrameStoryTooltipProgressLabel:GetHeight();

	WorldMapFrameStoryTooltip:ClearAllPoints();
	local tooltipWidth = max(240, maxWidth + 20);
	WorldMapFrameStoryTooltip:SetPoint("TOPRIGHT", WorldMapDetailFrame, "TOPRIGHT", -25, -25);
	WorldMapFrameStoryTooltip:SetSize(tooltipWidth, totalHeight);
	WorldMapFrameStoryTooltip:Show();
end

function WorldMapFrame_HideStoryTooltip(self)
	WorldMapFrameStoryTooltip:Hide();
end

--
-- Filter button mixin
--

WorldMapFilterButtonMixin = {}

function WorldMapFilterButtonMixin:OnLoad()
	self.Highlight:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)
	UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
end

function WorldMapFilterButtonMixin:InitializeDropDown(dropdown, level, menuList)
	if not self:IsVisible() then return end
	if not level or level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = WORLD_MAP_FILTER_TITLE
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)

		info = UIDropDownMenu_CreateInfo()
		info.keepShownOnClick = true
		info.func = function(self, filter, _, checked)
			C_WorldMap.SetPOIFilter(filter, not C_WorldMap.GetPOIFilter(filter))
		end

		for key, poiType in pairs(Enum.POIType) do
			if poiType ~= Enum.POIType.None then
				info.text = _G["WORLD_MAP_FILTER_"..key:upper()] or "WORLD_MAP_FILTER_"..key:upper()
				info.arg1 = poiType
				info.checked = C_WorldMap.GetPOIFilter(poiType)
				if info.checked and poiType == Enum.POIType.Teleport then
					info.hasArrow = true
					info.menuList = "teleport"
				else
					info.hasArrow = nil
					info.menuList = nil
				end
				UIDropDownMenu_AddButton(info, level)
			end
		end

		info = UIDropDownMenu_CreateInfo()
		info.text = CLOSE
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
		if menuList == "teleport" then
			local info = UIDropDownMenu_CreateInfo()
			info.text = WORLD_MAP_FILTER_TELEPORT_ONLY_KNOWN
			info.checked = C_WorldMap.GetPOIFilter("HideUnknownTeleport")
			info.keepShownOnClick = true
			info.func = function(self, _, _, checked)
				C_WorldMap.SetPOIFilter("HideUnknownTeleport", not not C_WorldMap.GetPOIFilter(filter))
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function WorldMapFilterButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(WORLD_MAP_FILTER, 1, 1, 1)
	GameTooltip:Show()
end 

function WorldMapFilterButtonMixin:OnLeave()
	GameTooltip:Hide()
end

function WorldMapFilterButtonMixin:OnClick()
	ToggleDropDownMenu(1, nil, self.DropDown, self, 0, 0)
end 

MINIMAPPING_TIMER = 5.5;
MINIMAPPING_FADE_TIMER = 0.5;

MINIMAP_RECORDING_INDICATOR_ON = false;

MINIMAP_EXPANDER_MAXSIZE = 28;

MINIMAP_IS_OUTSIDE = false;

local MinimapShapes = {
	-- { upper-left, lower-left, upper-right, lower-right }
	["SQUARE"]                = { false, false, false, false },
	["CORNER-TOPLEFT"]        = { true,  false, false, false },
	["CORNER-TOPRIGHT"]       = { false, false, true,  false },
	["CORNER-BOTTOMLEFT"]     = { false, true,  false, false },
	["CORNER-BOTTOMRIGHT"]    = { false, false, false, true },
	["SIDE-LEFT"]             = { true,  true,  false, false },
	["SIDE-RIGHT"]            = { false, false, true,  true },
	["SIDE-TOP"]              = { true,  false, true,  false },
	["SIDE-BOTTOM"]           = { false, true,  false, true },
	["TRICORNER-TOPLEFT"]     = { true,  true,  true,  false },
	["TRICORNER-TOPRIGHT"]    = { true,  false, true,  true },
	["TRICORNER-BOTTOMLEFT"]  = { true,  true,  false, true },
	["TRICORNER-BOTTOMRIGHT"] = { false, true,  true,  true },
}

function MinimapPing_OnLoad(self)
	-- self:SetFrameLevel(self:GetFrameLevel() + 1);
	self.fadeOut = nil;
	Minimap:SetPlayerTextureHeight(40);
	Minimap:SetPlayerTextureWidth(40);
	self:RegisterEvent("MINIMAP_PING");
	self:RegisterEvent("MINIMAP_UPDATE_ZOOM");
end

function ToggleMinimap()
	if(Minimap:IsShown()) then
		PlaySound("igMiniMapClose");
		Minimap:Hide();
	else
		PlaySound("igMiniMapOpen");
		Minimap:Show();
	end
	UpdateUIPanelPositions();
end

function Minimap_Update()
	MinimapZoneText:SetText(GetMinimapZoneText());

	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo();
	if ( pvpType == "sanctuary" ) then
		MinimapZoneText:SetTextColor(0.41, 0.8, 0.94);
	elseif ( pvpType == "arena" ) then
		MinimapZoneText:SetTextColor(1.0, 0.1, 0.1);
	elseif ( pvpType == "friendly" ) then
		MinimapZoneText:SetTextColor(0.1, 1.0, 0.1);
	elseif ( pvpType == "hostile" ) then
		MinimapZoneText:SetTextColor(1.0, 0.1, 0.1);
	elseif ( pvpType == "contested" ) then
		MinimapZoneText:SetTextColor(1.0, 0.7, 0.0);
	else
		MinimapZoneText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end

	Minimap_SetTooltip( pvpType, factionName );
end

function Minimap_SetTooltip( pvpType, factionName )
	if ( GameTooltip:IsOwned(MinimapZoneTextButton) ) then
		GameTooltip:SetOwner(MinimapZoneTextButton, "ANCHOR_LEFT");
		local zoneName = GetZoneText();
		local subzoneName = GetSubZoneText();
		if ( subzoneName == zoneName ) then
			subzoneName = "";	
		end
		GameTooltip:AddLine( zoneName, 1.0, 1.0, 1.0 );
		if ( pvpType == "sanctuary" ) then
			GameTooltip:AddLine( subzoneName, 0.41, 0.8, 0.94 );	
			GameTooltip:AddLine(SANCTUARY_TERRITORY, 0.41, 0.8, 0.94);
		elseif ( pvpType == "arena" ) then
			GameTooltip:AddLine( subzoneName, 1.0, 0.1, 0.1 );	
			GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1);
		elseif ( pvpType == "friendly" ) then
			GameTooltip:AddLine( subzoneName, 0.1, 1.0, 0.1 );	
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1);
		elseif ( pvpType == "hostile" ) then
			GameTooltip:AddLine( subzoneName, 1.0, 0.1, 0.1 );	
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1);
		elseif ( pvpType == "contested" ) then
			GameTooltip:AddLine( subzoneName, 1.0, 0.7, 0.0 );	
			GameTooltip:AddLine(CONTESTED_TERRITORY, 1.0, 0.7, 0.0);
		elseif ( pvpType == "combat" ) then
			GameTooltip:AddLine( subzoneName, 1.0, 0.1, 0.1 );	
			GameTooltip:AddLine(COMBAT_ZONE, 1.0, 0.1, 0.1);
		else
			GameTooltip:AddLine( subzoneName, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );	
		end
		GameTooltip:Show();
	end
end

function MinimapPing_OnEvent(self, event, ...)
	if ( event == "MINIMAP_PING" ) then
		local arg1, arg2, arg3 = ...;
		Minimap_SetPing(arg2, arg3, 1);
		self.timer = MINIMAPPING_TIMER;
	elseif ( event == "MINIMAP_UPDATE_ZOOM" ) then
		MinimapZoomIn:Enable();
		MinimapZoomOut:Enable();
		local zoom = Minimap:GetZoom();
		if ( zoom == (Minimap:GetZoomLevels() - 1) ) then
			MinimapZoomIn:Disable();
		elseif ( zoom == 0 ) then
			MinimapZoomOut:Disable();
		end
	end
end

function MinimapPing_OnUpdate(self, elapsed)
	local timer = self.timer or 0;
	if ( timer > 0 ) then
		timer = timer - elapsed;
		if ( not self.fadeOut and timer <= MINIMAPPING_FADE_TIMER ) then
			MinimapPing_FadeOut();
		end
		local percentage = timer - floor(timer)
		MinimapPingSpinner:SetRotation(percentage * math.pi/2);
		-- We want about 7 expansions per ping to match the old animation. 
		percentage = mod(timer, MINIMAPPING_TIMER/7);
		MinimapPingExpander:SetHeight(MINIMAP_EXPANDER_MAXSIZE * (1 - percentage));
		MinimapPingExpander:SetWidth(MINIMAP_EXPANDER_MAXSIZE * (1 - percentage));

		self.timer = timer;
	end
	if ( self.fadeOut ) then
		local fadeOutTimer = self.fadeOutTimer - elapsed;

		if ( fadeOutTimer > 0 ) then
			MinimapPing:SetAlpha(fadeOutTimer/MINIMAPPING_FADE_TIMER);
		else
			MinimapPing.fadeOut = nil;
			MinimapPing:Hide();
		end
		self.fadeOutTimer = fadeOutTimer;
	end
end

function Minimap_SetPing(x, y, playSound)
	x = x * Minimap:GetWidth();
	y = y * Minimap:GetHeight();
	
	if ( sqrt(x * x + y * y) < (Minimap:GetWidth() / 2) ) then
		MinimapPing:SetPoint("CENTER", "Minimap", "CENTER", x, y);
		MinimapPing:SetAlpha(1);
		MinimapPing:Show();
		if ( playSound ) then
			PlaySound("MapPing");
		end
	else
		MinimapPing:Hide();
	end
end

function MiniMapBattlefieldFrame_OnUpdate (self, elapsed)
	if ( GameTooltip:IsOwned(self) ) then
		BattlefieldFrame_UpdateStatus(1);
		if ( self.tooltip ) then
			GameTooltip:SetText(self.tooltip);
		end
	end
end

function MinimapPing_FadeOut()
	MinimapPing.fadeOut = 1;
	MinimapPing.fadeOutTimer = MINIMAPPING_FADE_TIMER;
end

function Minimap_ZoomInClick()
	MinimapZoomOut:Enable();
	PlaySound("igMiniMapZoomIn");
	Minimap:SetZoom(Minimap:GetZoom() + 1);
	if(Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
		MinimapZoomIn:Disable();
	end
end

function Minimap_ZoomOutClick()
	MinimapZoomIn:Enable();
	PlaySound("igMiniMapZoomOut");
	Minimap:SetZoom(Minimap:GetZoom() - 1);
	if(Minimap:GetZoom() == 0) then
		MinimapZoomOut:Disable();
	end
end

function Minimap_OnClick(self)
	local x, y = GetCursorPosition();
	x = x / self:GetEffectiveScale();
	y = y / self:GetEffectiveScale();

	local cx, cy = self:GetCenter();
	x = x - cx;
	y = y - cy;
	if ( sqrt(x * x + y * y) < (self:GetWidth() / 2) ) then
		Minimap:PingLocation(x, y);
	end
end

function Minimap_ZoomIn()
	MinimapZoomIn:Click();
end

function Minimap_ZoomOut()
	MinimapZoomOut:Click();
end

function EyeTemplate_OnUpdate(self, elapsed)
	AnimateTexCoords(self.texture, 512, 256, 64, 64, 29, elapsed)
end

function EyeTemplate_StartAnimating(eye)
	eye:SetScript("OnUpdate", EyeTemplate_OnUpdate);
end

function EyeTemplate_StopAnimating(eye)
	eye:SetScript("OnUpdate", nil);
	if ( eye.texture.frame ) then
		eye.texture.frame = 1;	--To start the animation over.
	end
	eye.texture:SetTexCoord(0, 0.125, 0, .25);
end

function MiniMapLFG_UpdateIsShown()
	local mode, submode = GetLFGMode();
	local inManastorm = C_Manastorm.IsInManastorm()
	if ( mode or inManastorm ) then
		MiniMapLFGFrame:Show();
		if ( mode == "queued" or mode == "listed" or mode == "rolecheck" ) then
			EyeTemplate_StartAnimating(MiniMapLFGFrame.eye);
		else
			EyeTemplate_StopAnimating(MiniMapLFGFrame.eye);
		end
	else
		MiniMapLFGFrame:Hide();
	end
end

function MiniMapLFGFrame_UpdateGlow(self)
	local enabled = false;
	for k, v in pairs(self.glowLocks) do
		if ( v ) then
			enabled = true;
			break;
		end
	end

	self.Highlight:SetShown(enabled);
	if ( enabled ) then
		self.Highlight.Anim:Play();
	else
		self.Highlight.Anim:Stop();
	end
end

function MiniMapLFGFrame_SetGlowLock(lock, enabled, numPingSounds)
	self = MiniMapLFGFrame;
	self.glowLocks[lock] = enabled and (numPingSounds or -1);
	MiniMapLFGFrame_UpdateGlow(self);
end

function MiniMapLFGFrame_OnGlowPulse(self)
	local playSounds = false;
	for k, v in pairs(self.glowLocks) do
		if ( type(v) == "number" ) then
			-- < 0 means play sounds forever
			-- > 0 means play sounds n times
			-- == 0 means no longer playing sounds
			if ( v < 0 ) then
				playSounds = true;
			elseif ( v > 0 ) then
				self.glowLocks[k] = v - 1;
				playSounds = true;
			end
		end
	end

	if playSounds then
		PlaySound(SOUNDKIT.MAP_PING)
	end
end

function MiniMapLFGFrame_TeleportIn()
	LFGTeleport(false);
end

function MiniMapLFGFrame_TeleportOut()
	LFGTeleport(true);
end

function MiniMapLFGFrameDropDown_Update()
	local info = UIDropDownMenu_CreateInfo();
	
	local mode, submode = GetLFGMode();

	--This one can appear in addition to others, so we won't just check the mode.
	if ( IsPartyLFG() ) then
		local addButton = false;
		if ( IsInLFGDungeon() ) then
			info.text = TELEPORT_OUT_OF_DUNGEON;
			info.func = MiniMapLFGFrame_TeleportOut;
			addButton = true;
		elseif ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) then
			info.text = TELEPORT_TO_DUNGEON;
			info.func = MiniMapLFGFrame_TeleportIn;
			addButton = true;
		end
		if ( addButton ) then
			UIDropDownMenu_AddButton(info);
		end
	end
	
	if ( mode == "proposal" and submode == "unaccepted" ) then
		info.text = ENTER_DUNGEON;
		info.func = AcceptProposal;
		UIDropDownMenu_AddButton(info);
		
		info.text = LEAVE_QUEUE;
		info.func = RejectProposal;
		UIDropDownMenu_AddButton(info);
	elseif ( mode == "queued" ) then
		info.text = LEAVE_QUEUE;
		info.func = LeaveLFG;
		info.disabled = (submode == "unempowered");
		UIDropDownMenu_AddButton(info);
	elseif ( mode == "listed" ) then
		if ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) then
			info.text = UNLIST_MY_GROUP;
		else
			info.text = UNLIST_ME;
		end
		info.func = LeaveLFG;
		info.disabled = (submode == "unempowered");
		UIDropDownMenu_AddButton(info);
	end

	if C_Manastorm.IsInManastorm() then
		info.text = THE_MANASTORM
		info.isTitle = true
		info.func = nil
		UIDropDownMenu_AddButton(info);
		info.text = LEAVE_THE_MANASTORM
		info.isTitle = nil
		info.func = function()
			ManastormUtil.ShowLeaveManastormDialog()
		end
		info.disabled = not C_Manastorm.CanLeave()
		UIDropDownMenu_AddButton(info);
	end
end

function MiniMapLFGFrame_OnClick(self, button)
	local mode, submode = GetLFGMode();
	if ( button == "RightButton" or mode == "lfgparty" or mode == "abandonedInDungeon") then
		--Display dropdown
		PlaySound("igMainMenuOpen");
		--Weird hack so that the popup isn't under the queued status window (bug 184001)
		local yOffset;
		if ( mode == "queued" ) then
			MiniMapLFGFrameDropDown.point = "BOTTOMRIGHT";
			MiniMapLFGFrameDropDown.relativePoint = "TOPLEFT";
			yOffset = 0;
		else
			MiniMapLFGFrameDropDown.point = nil;
			MiniMapLFGFrameDropDown.relativePoint = nil;
			yOffset = -5;
		end
		ToggleDropDownMenu(1, nil, MiniMapLFGFrameDropDown, "MiniMapLFGFrame", 0, yOffset);
	elseif ( mode == "proposal" ) then
		if ( not LFDDungeonReadyPopup:IsShown() ) then
			PlaySound("igCharacterInfoTab");
            LFGDebug("Proposal Shown: Minimap Button.");
			StaticPopupSpecial_Show(LFDDungeonReadyPopup);
		end
	elseif ( mode == "queued" or mode == "rolecheck" ) then
		ToggleLFDParentFrame();
	elseif ( mode == "listed" ) then
		ToggleLFRParentFrame();
	end
end

function MiniMapLFGFrame_OnEnter(self)
	local mode, submode = GetLFGMode();
	if ( mode == "queued" ) then
		LFDSearchStatus:Show();
	elseif ( mode == "proposal" ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(LOOKING_FOR_DUNGEON);
		GameTooltip:AddLine(DUNGEON_GROUP_FOUND_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		GameTooltip:AddLine(" ");
		GameTooltip:AddLine(CLICK_HERE_FOR_MORE_INFO, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		GameTooltip:Show();
	elseif ( mode == "rolecheck" ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(LOOKING_FOR_DUNGEON);
		GameTooltip:AddLine(ROLE_CHECK_IN_PROGRESS_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		GameTooltip:Show();
	elseif ( mode == "listed" ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(LOOKING_FOR_RAID);
		GameTooltip:AddLine(YOU_ARE_LISTED_IN_LFR, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		GameTooltip:Show();
	elseif ( mode == "lfgparty" ) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT");
		GameTooltip:SetText(LOOKING_FOR_DUNGEON);
		GameTooltip:AddLine(YOU_ARE_IN_DUNGEON_GROUP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		GameTooltip:Show();
	end
end

function MiniMapLFGFrame_OnLeave(self)
	GameTooltip:Hide();
	LFDSearchStatus:Hide();
end

function MinimapButton_OnMouseDown(self, button)
	if ( self.isDown ) then
		return;
	end
	local button = _G[self:GetName().."Icon"];
	local point, relativeTo, relativePoint, offsetX, offsetY = button:GetPoint();
	button:SetPoint(point, relativeTo, relativePoint, offsetX+1, offsetY-1);
	self.isDown = 1;
end
function MinimapButton_OnMouseUp(self)
	if ( not self.isDown ) then
		return;
	end
	local button = _G[self:GetName().."Icon"];
	local point, relativeTo, relativePoint, offsetX, offsetY = button:GetPoint();
	button:SetPoint(point, relativeTo, relativePoint, offsetX-1, offsetY+1);
	self.isDown = nil;
end

function Minimap_UpdateRotationSetting()
	if ( GetCVar("rotateMinimap") == "1" ) then
		MinimapCompassTexture:Show();
		MinimapNorthTag:Hide();
	else
		MinimapCompassTexture:Hide();
		MinimapNorthTag:Show();
	end
end

function ToggleMiniMapRotation()
	local rotate = GetCVar("rotateMinimap");
	if ( rotate == "1" ) then
		rotate = "0";
	else
		rotate = "1";
	end
	SetCVar("rotateMinimap", rotate);
	Minimap_UpdateRotationSetting();
end

function MinimapMailFrameUpdate()
	local sender1,sender2,sender3 = GetLatestThreeSenders();
	local toolText;
	
	if( sender1 or sender2 or sender3 ) then
		toolText = HAVE_MAIL_FROM;
	else
		toolText = HAVE_MAIL;
	end
	
	if( sender1 ) then
		toolText = toolText.."\n"..sender1;
	end
	if( sender2 ) then
		toolText = toolText.."\n"..sender2;
	end
	if( sender3 ) then
		toolText = toolText.."\n"..sender3;
	end
	GameTooltip:SetText(toolText);
end

function MiniMapTracking_Update()
	local texture = GetTrackingTexture();
	if ( MiniMapTrackingIcon:GetTexture() ~= texture ) then
		MiniMapTrackingIcon:SetTexture(texture);
		MiniMapTrackingShineFadeIn();
	end
end

function MiniMapTrackingDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, MiniMapTrackingDropDown_Initialize, "MENU");
end

function MiniMapTracking_SetTracking (self, id)
	SetTracking(id);
end

function MiniMapTrackingDropDown_Initialize()
	local name, texture, active, category;
	local anyActive, checked;
	local count = GetNumTrackingTypes();
	local info;
	for id=1, count do
		name, texture, active, category  = GetTrackingInfo(id);
        if name ~= nil then
			info = UIDropDownMenu_CreateInfo();
			info.text = name;
			info.checked = active;
			info.func = MiniMapTracking_SetTracking;
			info.icon = texture;
			info.arg1 = id;
			if ( category == "spell" ) then
				info.tCoordLeft = 0.0625;
				info.tCoordRight = 0.9;
				info.tCoordTop = 0.0625;
				info.tCoordBottom = 0.9;
			else
				info.tCoordLeft = 0;
				info.tCoordRight = 1;
				info.tCoordTop = 0;
				info.tCoordBottom = 1;
			end
			UIDropDownMenu_AddButton(info);
			if ( active ) then
				anyActive = active;
			end
		end
	end
	
	if ( anyActive ) then
		checked = nil;
	else
		checked = 1;
	end

	info = UIDropDownMenu_CreateInfo();
	info.text = NONE;
	info.checked = checked;
	info.func = MiniMapTracking_SetTracking;
	info.arg1 = nil;
	UIDropDownMenu_AddButton(info);
	
	EventRegistry:TriggerEvent("MiniMapTrackingDropDown_Initialize")
end

function MiniMapTrackingShineFadeIn()
	-- Fade in the shine and then fade it out with the ComboPointShineFadeOut function
	local fadeInfo = {};
	fadeInfo.mode = "IN";
	fadeInfo.timeToFade = 0.5;
	fadeInfo.finishedFunc = MiniMapTrackingShineFadeOut;
	UIFrameFade(MiniMapTrackingButtonShine, fadeInfo);
end

function MiniMapTrackingShineFadeOut()
	UIFrameFadeOut(MiniMapTrackingButtonShine, 0.5);
end
						
local selectedRaidDifficulty;
local allowedRaidDifficulty;
function MiniMapInstanceDifficulty_OnEvent(self)
	local _, instanceType, difficulty, _, maxPlayers, playerDifficulty, isDynamicInstance = GetInstanceInfo();
	if ( ( instanceType == "party" or instanceType == "raid" ) and not ( difficulty == 1 and maxPlayers == 5 ) ) then		
		local isHeroic = false;
		local isMythic = false;
		if ( instanceType == "party" and difficulty == 2 ) then
			isHeroic = true;
		elseif ( instanceType == "raid" ) then
			if ( isDynamicInstance ) then
				selectedRaidDifficulty = difficulty;
				if ( playerDifficulty == 1 ) then
					if ( selectedRaidDifficulty <= 2 ) then
						selectedRaidDifficulty = selectedRaidDifficulty + 2;
					end
					isHeroic = true;
				end
				-- if modified difficulty is normal then you are allowed to select heroic, and vice-versa
				if ( selectedRaidDifficulty == 1 ) then
					allowedRaidDifficulty = 3;
				elseif ( selectedRaidDifficulty == 2 ) then
					allowedRaidDifficulty = 4;
				elseif ( selectedRaidDifficulty == 3 ) then
					allowedRaidDifficulty = 1;
				elseif ( selectedRaidDifficulty == 4 ) then
					allowedRaidDifficulty = 2;
				end
				allowedRaidDifficulty = "RAID_DIFFICULTY"..allowedRaidDifficulty;
			elseif ( difficulty > 2 ) then
				isHeroic = true;
			end
		end
		
		-- @HelloKitty: A hack because GetInstanceInfo returns incorrect info for some reason. DBCs seemed correct in MapDifficulty and Map etc.
		-- See for numbers: https://wowwiki.fandom.com/wiki/API_GetInstanceDifficulty
		if ( (maxPlayers == 0) and (difficulty > 1)) then
			if ( ( difficulty == 3) and not (instanceType == "party") ) then
				maxPlayers = 10;
			elseif ( difficulty == 4) then
				maxPlayers = 25;
			elseif ( ( difficulty == 2) and (instanceType == "party") ) then
				maxPlayers = 5;
				isHeroic = true;
			elseif ( ( difficulty == 3) and (instanceType == "party") ) then
				maxPlayers = 5;
				isMythic = true;
			end
		end

		-- @HelloKitty: This makes it so Flex shows instead
		if ( (instanceType == "raid") and (difficulty < 3) ) then -- Less than heroic 10man
			MiniMapInstanceDifficultyText:SetText("Flex");
		else
			MiniMapInstanceDifficultyText:SetText(maxPlayers);
		end
		
		-- the 1 looks a little off when text is centered
		local xOffset = 0;
		if ( maxPlayers >= 10 and maxPlayers <= 19 ) then
			xOffset = -1;
		end
		if (( isHeroic ) or ( isMythic )) then
			MiniMapInstanceDifficultyTexture:SetTexCoord(0, 0.25, 0.0703125, 0.4140625);
			MiniMapInstanceDifficultyText:SetPoint("CENTER", xOffset, -9);
		else
			MiniMapInstanceDifficultyTexture:SetTexCoord(0, 0.25, 0.5703125, 0.9140625);
			MiniMapInstanceDifficultyText:SetPoint("CENTER", xOffset, 5);
		end
		self:Show();
	else
		self:Hide();
	end
end

function _GetPlayerDifficultyMenuOptions()
	return selectedRaidDifficulty, allowedRaidDifficulty;
end

function Minimap_UpdateSuperTrackPOI(self)
	if C_CVar.GetBool("showInGameNavigation") then
		local x, y = C_SuperTrack.GetSuperTrackedWorldPosition()
		if not x or not y then
			self.SuperTrackPOI:Hide()
			return
		end

		local locationVector = Vector2D(x, y)

		local playerX, playerY = GetCurrentPlayerPosition()
		local playerVector = Vector2D(playerX, playerY)
		
		locationVector = playerVector:DistanceVector(locationVector)
		local distance = locationVector:Length()
	
		if distance > 233 then
			self.SuperTrackPOI:Hide()
			return
		end
	
		local xDist = locationVector.x
		local yDist = locationVector.y
	
		-- Astrolabe function
		local mapRadius = self:GetViewRadius()
		local mapDiameter = mapRadius * 2

		local width, height = self:GetSize()

		local xScale = mapDiameter / width
		local yScale = mapDiameter / height
		local iconDiameter = ((self.SuperTrackPOI:GetWidth() / 2) + 3) * xScale
		local iconOnEdge
		local isRound = true

		local enableRotation = C_CVar.GetBool("rotateMinimap")
	
		if enableRotation then
			local facing = GetPlayerFacing()
			local sinTheta = math.sin(facing)
			local cosTheta = math.cos(facing)
			local dx, dy = xDist, yDist
			xDist = (dx * sinTheta) - (dy * cosTheta)
			yDist = (dx * cosTheta) + (dy * sinTheta)
		end

		local shape = GetMinimapShape and MinimapShapes[GetMinimapShape()]
	
		if shape and not (xDist == 0 or yDist == 0) then
			isRound = (xDist < 0) and 1 or 3
			if yDist < 0 then
				isRound = shape[isRound]
			else
				isRound = shape[isRound + 1]
			end
		end
	
		-- for non-circular portions of the Minimap edge
		if not isRound then
			distance = math.max(math.abs(xDist), math.abs(yDist))
		end
	
		if (distance + iconDiameter) > mapRadius then
			-- position along the outside of the Minimap
			iconOnEdge = true
			local factor = (mapRadius - iconDiameter) / distance
			xDist = xDist * factor
			yDist = yDist * factor
		end
	
		if enableRotation then
			self.SuperTrackPOI:SetPoint("CENTER", Minimap, "CENTER", xDist/xScale, yDist/yScale)
		else
			self.SuperTrackPOI:SetPoint("CENTER", Minimap, "CENTER", -yDist/yScale, xDist/xScale)
		end
		
		self.SuperTrackPOI:Show()
	else
		self.SuperTrackPOI:Hide()
	end
end

LayerPickerMixin = CreateFromMixins("BackdropTemplateMixin")

function LayerPickerMixin:OnLoad()
    self:SetBackdrop(BACKDROP_TOOLTIP_8_8_1111)
    self:SetBackdropColor(0.09, 0.09, 0.09, 0.8)
    self:RegisterForDrag("LeftButton")
    UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
    
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_INSTANCE_LIST")
end

function LayerPickerMixin:OnShow()
    -- do not give tip at lvl 1 because its just way too much login information.
    if UnitLevel("player") > 1 then
        HelpTip:Show("LAYER_PICKER")
    else
        self:RegisterEvent("PLAYER_LEVEL_UP")
    end
end

function LayerPickerMixin:OnEvent(event, ...)
    if event == "PLAYER_LEVEL_UP" then
        -- show tip whenever we lvl 
        HelpTip:Show("LAYER_PICKER")
        self:UnregisterEvent("PLAYER_LEVEL_UP")
        return
    end
    self:UpdateVisible()
end

function LayerPickerMixin:OnDragStart()
    CloseDropDownMenus()
    self:StartMoving()
end

function LayerPickerMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function LayerPickerMixin:UpdateVisible()
    if not C_CVar.GetBool("showLayerPicker") then
        self:Hide()
        return
    end

    if self:GetNumLayers() <= 1 then
        self:Hide()
        return
    end
    
    self:Show()
    self:Update()
end

function LayerPickerMixin:GetNumLayers()
    return GetZoneInstanceList() or 0
end

function LayerPickerMixin:ChooseLayer(index)
    if index then
        SetZoneInstanceID(index)
    end
end

function LayerPickerMixin:GetLayer()
    return GetZoneInstanceID() or 1
end

function LayerPickerMixin:Update()
    self.Text:SetFormattedText(LAYER_PICKER_LABEL_S, self:GetLayer())
    self:SetWidth(self.Text:GetStringWidth()+10)
end 

function LayerPickerMixin:OnEnter()
    CloseDropDownMenus()
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(format(LAYER_PICKER_TOOLTIP_TITLE_S, self:GetLayer()), NORMAL_FONT_COLOR:GetRGB())
    GameTooltip:AddLine(LAYER_PICKER_TOOLTIP_TEXT, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, true)
    GameTooltip:Show()
end 

function LayerPickerMixin:OnLeave()
    GameTooltip:Hide()
end 

function LayerPickerMixin:InitializeDropDown(dropdown, level, menuList)
    if not self:IsVisible() then
        return
    end

    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = LAYER_PICKER_CHOOSE_LAYER
    UIDropDownMenu_AddButton(info)

    for i = 1, self:GetNumLayers() do
        info = UIDropDownMenu_CreateInfo()
        info.text = format(LAYER_PICKER_LABEL_S, i)
        info.arg1 = i
        info.func = function(button, arg1) self:ChooseLayer(arg1) end
        info.disabled = i == self:GetLayer()
        UIDropDownMenu_AddButton(info)
    end

    info = UIDropDownMenu_CreateInfo()
    info.text = RESET_POSITION
    info.func = function()
        self:SetUserPlaced(false)
        self:ClearAndSetPoint("BOTTOM", Minimap, "BOTTOM", 0, 12)
    end
    UIDropDownMenu_AddButton(info)
end

function LayerPickerMixin:OnClick()
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
    ToggleDropDownMenu(1, nil, self.DropDown, self, 0, 0)
end 
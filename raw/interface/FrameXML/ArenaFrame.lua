MAX_ARENA_BATTLES = 6;
NO_ARENA_SEASON = 0;
function ArenaFrame_OnLoad (self)
	self:RegisterEvent("BATTLEFIELDS_SHOW");
	self:RegisterEvent("BATTLEFIELDS_CLOSED");
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
	self:RegisterEvent("PARTY_LEADER_CHANGED");
end

function ArenaFrame_OnEvent (self, event, ...)
	if ( IsBattlefieldArena() ) then
		if ( event == "BATTLEFIELDS_SHOW" ) then
			ShowUIPanel(ArenaFrame);
			if ( GetCurrentArenaSeason()~=NO_ARENA_SEASON ) then
				if ( not ArenaFrame.selection ) then
					ArenaFrame.selection = 1;
				end
			else
				if ( (not ArenaFrame.selection) or (ArenaFrame.selection < 4) ) then
					ArenaFrame.selection = 4;
				end
			end
            
            if ( GetCurrentArenaSeason()==NO_ARENA_SEASON ) then
                ArenaFrameZoneDescription:SetText(ARENA_MASTER_NO_SEASON_TEXT);
            else
                ArenaFrameZoneDescription:SetText("Let the games begin! The door is open to all who wish to find glory in the arena, and the Steamwheedle Cartel is prepared to accept your entry into the games.")
            end
            
			if ( not ArenaFrame:IsShown() ) then
				CloseBattlefield();
				return;
			end
			ArenaFrame_Update(self);
		elseif ( event == "BATTLEFIELDS_CLOSED" ) then
			HideUIPanel(ArenaFrame);
		elseif ( event == "UPDATE_BATTLEFIELD_STATUS" ) then
			ArenaFrame_Update(self);
		end
		if ( event == "PARTY_LEADER_CHANGED" ) then
			ArenaFrame_Update(self);
		end
	end
end

function ArenaButton_OnClick(self)
	local id = self:GetID();
	_G["ArenaZone"..id]:LockHighlight();
	ArenaFrame.selection = id;
	ArenaFrame_Update();
end

function ArenaFrame_Update (self)
	local ARENA_TEAMS = {};
	ARENA_TEAMS[1] = {size = 2};
	ARENA_TEAMS[2] = {size = 3};
	ARENA_TEAMS[3] = {size = 1}; -- @robinsch: Ascension replaced 5v5 by 1v1 queue
	
	local button, battleType, teamSize;
	
	for i=1, MAX_ARENA_BATTLES, 1 do
		button = _G["ArenaZone"..i];
		battleType = ARENA_RATED;
		teamSize = i;
		-- if buttons begin a second set of buttons for casual games, change text elements.
		button:Enable();
		if ( i > MAX_ARENA_TEAMS ) then
			teamSize = teamSize - MAX_ARENA_TEAMS;
			battleType = ARENA_CASUAL;
		elseif ( GetCurrentArenaSeason()==NO_ARENA_SEASON ) then
			button:Disable();
		end
		-- build text string to populate each element.
		-- @robinsch: Solo Queue
		-- CanJoinRatedArenaWithoutGroup(i) broken atm
		if ( (GetNumPartyMembers() == 0) and i == 1 ) then
			button:SetText(format(PVP_TEAMTYPE, ARENA_TEAMS[teamSize].size, ARENA_TEAMS[teamSize].size).." "..battleType.." (Solo Queue)");
		else
			button:SetText(format(PVP_TEAMTYPE, ARENA_TEAMS[teamSize].size, ARENA_TEAMS[teamSize].size).." "..battleType);
		end
		-- Set selected instance
		if ( i == ArenaFrame.selection ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
	end

	if ( ArenaFrame.selection > MAX_ARENA_TEAMS ) then
		ArenaFrameJoinButton:Enable();
	else
		ArenaFrameJoinButton:Disable();
	end

	if ( CanJoinBattlefieldAsGroup() ) then
		if ( ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) and IsPartyLeader() and GetCurrentArenaSeason()~=NO_ARENA_SEASON ) then
			-- If this is true then can join as a group
			ArenaFrameGroupJoinButton:Enable();
		else
			ArenaFrameGroupJoinButton:Disable();
		end
		ArenaFrameGroupJoinButton:Show();
	else
		ArenaFrameGroupJoinButton:Hide();
	end

	-- Enable or disable the group join button
	if ( CanJoinBattlefieldAsGroup() ) then
		if ( ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) and IsPartyLeader() ) then
			-- If this is true then can join as a group
			BattlefieldFrameGroupJoinButton:Enable();
		else
			BattlefieldFrameGroupJoinButton:Disable();
		end
		BattlefieldFrameGroupJoinButton:Show();
	else
		BattlefieldFrameGroupJoinButton:Hide();
	end

	-- @robinsch: Solo Queue (2v2, 1v1)
	-- CanJoinRatedArenaWithoutGroup(ArenaFrame.selection) -- Broken atm. 12/9/2021
	if ( ArenaFrame.selection == 1 or ArenaFrame.selection == 3 or ArenaFrame.selection > 3 ) then
		ArenaFrameJoinButton:Enable();
	else
		ArenaFrameJoinButton:Disable();
	end

	-- @robinsch: 1v1
	if ( ArenaFrame.selection == 3 ) then
		BattlefieldFrameGroupJoinButton:Disable();
	end
end

function ArenaFrameJoinButton_OnClick(self)
	local GROUPJOIN_BUTTONID = 2;
	if ( ArenaFrame.selection < 4 ) then
		if ( self:GetID() == GROUPJOIN_BUTTONID ) then
			JoinBattlefield(ArenaFrame.selection, 1, 1);
		else -- @robinsch: Solo Queue (2v2, 1v1)
			JoinBattlefield(ArenaFrame.selection, 0, 1);
		end
	elseif ( ArenaFrame.selection > 3 and self:GetID() == GROUPJOIN_BUTTONID ) then
		JoinBattlefield(ArenaFrame.selection - 3, 1);
	else
		JoinBattlefield(ArenaFrame.selection - 3);
	end
	HideUIPanel(ArenaFrame);
end

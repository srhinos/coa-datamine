
NUMGOSSIPBUTTONS = 40;

function GossipFrame_OnLoad(self)
	self:RegisterEvent("GOSSIP_SHOW");
	self:RegisterEvent("GOSSIP_CLOSED");
end

function GossipFrame_OnEvent(self, event, ...)end

function GossipFrameUpdate()
	GossipFrame.buttonIndex = 1;
	GossipGreetingText:SetText(GetGossipText());
	GossipFrameAvailableQuestsUpdate(GetGossipAvailableQuests());
	GossipFrameActiveQuestsUpdate(GetGossipActiveQuests());
	GossipFrameOptionsUpdate(GetGossipOptions());
	for i=GossipFrame.buttonIndex, NUMGOSSIPBUTTONS do
		_G["GossipTitleButton" .. i]:Hide();
	end
	GossipFrameNpcNameText:SetText(UnitName("npc"));
	if ( UnitExists("npc") ) then
		SetPortraitTexture(GossipFramePortrait, "npc");
	else
		GossipFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
	end

	-- Set Spacer
	if ( GossipFrame.buttonIndex > 1 ) then
		GossipSpacerFrame:SetPoint("TOP", "GossipTitleButton"..GossipFrame.buttonIndex-1, "BOTTOM", 0, 0);
		GossipSpacerFrame:Show();
	else
		GossipSpacerFrame:Hide();
	end

	-- Update scrollframe
	GossipGreetingScrollFrame:SetVerticalScroll(0);
end

function GossipTitleButton_OnClick(self, button)
	if ( self.type == "Available" ) then
		SelectGossipAvailableQuest(self:GetID());
	elseif ( self.type == "Active" ) then
		SelectGossipActiveQuest(self:GetID());
	else
		SelectGossipOption(self:GetID());
	end
end

function GossipFrameAvailableQuestsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	local isTrivial, isDaily, isRepeatable;
	for i=1, select("#", ...), 5 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			titleButton = CreateFrame("Button", "GossipTitleButton"..GossipFrame.buttonIndex, GossipGreetingScrollChildFrame, "GossipTitleButtonTemplate")
			titleButton:SetPoint("TOPLEFT", "GossipTitleButton"..(GossipFrame.buttonIndex - 1), "BOTTOMLEFT", 0, -3)
			NUMGOSSIPBUTTONS = NUMGOSSIPBUTTONS + 1
		else
			titleButton = _G["GossipTitleButton" .. GossipFrame.buttonIndex];
		end
		titleButtonIcon = _G[titleButton:GetName() .. "GossipIcon"];
		isTrivial = select(i+2, ...);
		isDaily = select(i+3, ...);
		isRepeatable = select(i+4, ...);
		if ( isDaily ) then
			titleButtonIcon:SetTexture("Interface\\GossipFrame\\DailyQuestIcon");
		elseif ( isRepeatable ) then
			titleButtonIcon:SetTexture("Interface\\GossipFrame\\DailyActiveQuestIcon");
		else
			titleButtonIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon");
		end
		if ( isTrivial ) then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(0.5,0.5,0.5);
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(1,1,1);
		end
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Available";
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
	if ( GossipFrame.buttonIndex > 1 ) then
		titleButton = _G["GossipTitleButton" .. GossipFrame.buttonIndex];
		titleButton:Hide();
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
	end
end

function GossipFrameActiveQuestsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	for i=1, select("#", ...), 4 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			titleButton = CreateFrame("Button", "GossipTitleButton"..GossipFrame.buttonIndex, GossipGreetingScrollChildFrame, "GossipTitleButtonTemplate")
			titleButton:SetPoint("TOPLEFT", "GossipTitleButton"..(GossipFrame.buttonIndex - 1), "BOTTOMLEFT", 0, -3)
			NUMGOSSIPBUTTONS = NUMGOSSIPBUTTONS + 1
		else
			titleButton = _G["GossipTitleButton" .. GossipFrame.buttonIndex];
		end
		titleButtonIcon = _G[titleButton:GetName() .. "GossipIcon"];
		if ( select(i+2, ...) ) then
			titleButton:SetFormattedText(TRIVIAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(0.5,0.5,0.5);
		else
			titleButton:SetFormattedText(NORMAL_QUEST_DISPLAY, select(i, ...));
			titleButtonIcon:SetVertexColor(1,1,1);
		end
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Active";
		if ( select(i+3, ...) ) then
			titleButtonIcon:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon");
		else
			titleButtonIcon:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon");
		end		
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
	if ( titleIndex > 1 ) then
		titleButton = _G["GossipTitleButton" .. GossipFrame.buttonIndex];
		titleButton:Hide();
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
	end
end

function GossipFrameOptionsUpdate(...)
	local titleButton;
	local titleIndex = 1;
	local titleButtonIcon;
	for i=1, select("#", ...), 2 do
		if ( GossipFrame.buttonIndex > NUMGOSSIPBUTTONS ) then
			titleButton = CreateFrame("Button", "GossipTitleButton"..GossipFrame.buttonIndex, GossipGreetingScrollChildFrame, "GossipTitleButtonTemplate")
			titleButton:SetPoint("TOPLEFT", "GossipTitleButton"..(GossipFrame.buttonIndex - 1), "BOTTOMLEFT", 0, -3)
			NUMGOSSIPBUTTONS = NUMGOSSIPBUTTONS + 1
		else
			titleButton = _G["GossipTitleButton" .. GossipFrame.buttonIndex];
		end
		titleButton:SetText(select(i, ...));
		GossipResize(titleButton);
		titleButton:SetID(titleIndex);
		titleButton.type="Gossip";
		titleButtonIcon = _G[titleButton:GetName() .. "GossipIcon"];
		titleButtonIcon:SetTexture("Interface\\GossipFrame\\" .. select(i+1, ...) .. "GossipIcon");
		titleButtonIcon:SetVertexColor(1, 1, 1, 1);
		GossipFrame.buttonIndex = GossipFrame.buttonIndex + 1;
		titleIndex = titleIndex + 1;
		titleButton:Show();
	end
end

function GossipResize(titleButton)
	titleButton:SetHeight( titleButton:GetTextHeight() + 2);
end

if not C_Realm.IsDevelopment() then return end

local distance_s_s = 75
local distance_n_s = 64
local distance_ss_s = 86
local distance_s_n = 145

--[[local example_progress_data = {
	[1] = {sID = -1, parentID = 0, distance = 0, Anchor = nil, size = 217, color = "NO", x = 0, y = 0}, -- sID = -1 creates empty circilar node 
	[2] = {sID = 16814, parentID = 1, distance = 138, Anchor = "LEFT", isSpecialSpell = true, color = "GREEN"}, -- druid
	[3] = {sID = 11222, parentID = 1, distance = 138, direction = "TOP", isSpecialSpell = true, color = "TEAL"}, -- mage
	[4] = {sID = 14162, parentID = 1, distance = 138, direction = "BOTTOM", isSpecialSpell = true, color = "ORANGE"}, -- rogue
	[5] = {sID = 16850, parentID = 2, distance = distance_ss_s, direction = "LEFT", color = "GREEN"}, -- druid
	[6] = {sID = 33597, parentID = 5, distance = distance_s_s, direction = "BOTTOM", color = "GREEN"}, -- druid
	[7] = {sID = -1, parentID = 6, distance = distance_s_n, direction = "BOTTOMLEFT", size = 128, color = "GREEN"}, -- druid
	[8] = {sID = 33831, parentID = 7, distance = distance_n_s, direction = "TOP", color = "GREEN"}, -- druid
	[27] = {sID = 48516, parentID = 7, distance = distance_n_s, direction = "LEFT", color = "GREEN"}, -- druid
	[9] = {sID = 14156, parentID = 4, distance = distance_ss_s, direction = "BOTTOMRIGHT", color = "ORANGE"}, -- rogue
	[10] = {sID = 51632, parentID = 9, distance = distance_s_s, direction = "BOTTOMRIGHT", color = "ORANGE"}, -- rogue
	[11] = {sID = -1, parentID = 10, distance = distance_s_n, direction = "BOTTOMRIGHT", size = 128, color = "ORANGE"}, -- rogue
	[12] = {sID = 14168, parentID = 11, distance = distance_n_s, direction = "TOP", color = "ORANGE"}, -- rogue
	[13] = {sID = 29441, parentID = 3, distance = distance_ss_s, direction = "TOP", color = "TEAL"}, -- mage
	[16] = {sID = 14177, parentID = 11, distance = distance_n_s, direction = "BOTTOM", color = "ORANGE"}, -- rogue
	[17] = {sID = 58426, parentID = 11, distance = distance_n_s, direction = "RIGHT", color = "ORANGE"}, -- rogue
	[14] = {sID = 11237, parentID = 13, distance = distance_s_s, direction = "TOPRIGHT", color = "TEAL"}, -- mage
	[15] = {sID = 11213, parentID = 14, distance = distance_s_s, direction = "TOPLEFT", color = "TEAL"}, -- mage
	[18] = {sID = 18827, parentID = 1, distance = 138, direction = "RIGHT", isSpecialSpell = true, color = "PURPLE"}, -- warlock
	[19] = {sID = -1, parentID = 18, distance = distance_s_n, direction = "RIGHT", size = 128, color = "PURPLE"}, -- warlock
	[20] = {sID = 18179, parentID = 19, distance = distance_n_s, direction = "TOP", color = "PURPLE"}, -- warlock
	[21] = {sID = 53754, parentID = 19, distance = distance_n_s, direction = "RIGHT", color = "PURPLE"}, -- warlock
	[22] = {sID = 18094, parentID = 19, distance = distance_n_s, direction = "BOTTOM", color = "PURPLE"}, -- warlock
	[23] = {sID = 32385, parentID = 21, distance = distance_s_n, direction = "RIGHT", color = "PURPLE"}, -- warlock
	[24] = {sID = 54037, parentID = 23, distance = distance_s_s, direction = "TOPRIGHT", color = "PURPLE"}, -- warlock
	[25] = {sID = 47195, parentID = 23, distance = distance_s_s, direction = "BOTTOMRIGHT", color = "PURPLE"}, -- warlock
	[26] = {sID = 47198, parentID = 25, distance = distance_s_s, direction = "BOTTOMRIGHT", color = "PURPLE"}, -- warlock
	[27] = {sID = 11213, parentID = 15, distance = 150, direction = "TOP", color = "TEAL"}, -- mage
}]]--

--
-- Locals
--
local COLORS = {
	["PURPLE"] = {1, 0.2, 0.8, 1},
	["TEAL"] = {0, 0.8, 1, 1},
	["ORANGE"] = {1, 0.6, 0, 1},
	["GREEN"] = {0.6, 1, 0, 1},
}

local CONTENT_SIZE = 3900

--
-- Local functions
--

local function CalcPos(fi, radius)
    return radius*cos(fi), radius*sin(fi)
end

local function ShowUnlearnDialogue(spells) -- TODO: Add cost line
    local text = "Are you sure you want to |cffFF0000Unlearn|r following spells:\n"

    -- handle spells
    for _, spell in pairs(spells) do
		local entry = C_CharacterAdvancement.GetEntryByInternalID(spell)
		if entry then
			text = text .. "\n"..LinkUtil:GetSpellLink(entry.Spells[1])
		end
    end

    StaticPopupDialogs["ASC_SPELL_UNLEARN_CONFIRM"].OnAccept = function()
        if not C_CharacterAdvancement.UnlearnID(spells) and C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) then
            aprint("|cffFF0000[WILDCARD] Unlearn request dropped by client (reveal pending). Try again in a moment.|r")
        end
    end

    StaticPopupDialogs["ASC_SPELL_UNLEARN_CONFIRM"].text = text
    StaticPopup_Show("ASC_SPELL_UNLEARN_CONFIRM")
end

--
-- Templates
--
local function BgCircleSmallTemplate(parent)
	local tex = parent:CreateTexture(nil, "ARTWORK")
	tex:SetSize(335, 335)
	tex:SetTexture("Interface\\SkillTree\\ring_small_dark")
	tex:SetAlpha(1,1,1,1)
	return tex
end

local function BgCircleBigTemplate(parent)
	local tex = parent:CreateTexture(nil, "BORDER")
	tex:SetSize(690, 690)
	tex:SetTexture("Interface\\SkillTree\\disk_stone_dark")
	return tex
end

local function AutoCastSparkleTemplate(parent)
	local tex = parent:CreateTexture(nil, "OVERLAY")
	tex:SetSize(12,12)
	tex:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockets")
	tex:SetTexCoord(0.3984375, 0.4453125, 0.40234375, 0.44921875)
	tex:SetBlendMode("ADD")
	return tex
end

local function SkillTreeSquareButtonTemplate(parent, name)
	local btn = CreateFrame("BUTTON", "$parent."..name, parent, nil)

	local textures = {
		["DOWN"] = {
			normal = "Interface\\skillTree\\bottom",
			disabled = "Interface\\skillTree\\bottom_disabled",
			pushed = "Interface\\skillTree\\bottom_pushed",
		},
		["UP"] = {
			normal = "Interface\\skillTree\\top",
			disabled = "Interface\\skillTree\\top_disabled",
			pushed = "Interface\\skillTree\\top_pushed",
		},
		["LEFT"] = {
			normal = "Interface\\skillTree\\left",
			disabled = "Interface\\skillTree\\left_disabled",
			pushed = "Interface\\skillTree\\left_pushed",
		},
		["RIGHT"] = {
			normal = "Interface\\skillTree\\right",
			disabled = "Interface\\skillTree\\right_disabled",
			pushed = "Interface\\skillTree\\right_pushed",
		},
		["ZOOM_IN"] = {
			normal = "Interface\\skillTree\\zoomin",
			disabled = "Interface\\skillTree\\zoomin_disabled",
			pushed = "Interface\\skillTree\\zoomin_pushed",
		},
		["ZOOM_OUT"] = {
			normal = "Interface\\skillTree\\zoomout",
			disabled = "Interface\\skillTree\\zoomout_disabled",
			pushed = "Interface\\skillTree\\zoomout_pushed",
		},
	}
	btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	btn:GetHighlightTexture():ClearAllPoints()
	btn:GetHighlightTexture():SetPoint("CENTER", 0, 0)
	btn:GetHighlightTexture():SetSize(32, 32)
	btn:SetNormalTexture("Interface\\skillTree\\bottom")
	btn:SetSize(46, 46)

	function btn:SetTemplate(templateName)
		local template = textures[templateName]
		if (template) then
			btn:SetNormalTexture(template.normal)
			btn:SetDisabledTexture(template.disabled)
			btn:SetPushedTexture(template.pushed)
		end
	end

	return btn
end

--
-- Line template
--
local function CreateLine(frame)
	--local line = parent:CreateTexture(nil, "OVERLAY")
	local line = frame

	line.custom_shine_timers = {0, 0, 0, 0}

	local function CalcCheck(self) -- not a perfect solution but CalcPointAndSize requires elements to be visible
		if (self:CalcPointAndSize()) then
			self:SetScript("OnShow", nil)
		else
			Timer.After(0.4, function() CalcCheck(self) end)
		end
	end

	local function AddRotationAnimation(region)
		region.rotation = region:CreateAnimationGroup()
		region.rotation.rotate = region.rotation:CreateAnimation("Rotation")
		region.rotation.rotate:SetDuration(0.001)
		region.rotation.rotate:SetEndDelay(3600)
		region.rotation:SetScript("OnFinished", function(self)
			self:Play()
		end)
		region.rotation:SetScript("OnStop", function(self)
			self:Play()
		end)
	end

	local function AutoCastShine_Update(self, elapsed)
		if not(line.angle) then
			return
		end

		local speeds = { 8, 9, 12, 16}

		for i in next, self.custom_shine_timers do
			self.custom_shine_timers[i] = self.custom_shine_timers[i] + elapsed;
			if ( self.custom_shine_timers[i] > speeds[i]*4 ) then
				self.custom_shine_timers[i] = 0;
			end
		end

		for i = 1, 4 do
			local timer = self.custom_shine_timers[i];
			local speed = speeds[i];
			local basePosition = timer/speed*self.length;

			if ( timer <= speed ) then
				basePosition = timer/speed*self.length;
			elseif ( timer <= speed*2 ) then
				basePosition = (timer-speed)/speed*self.length;
			elseif ( timer <= speed*3 ) then
				basePosition = (timer-speed*2)/speed*self.length;
			else
				basePosition = (timer-speed*3)/speed*self.length;
			end

			basePosition = {CalcPos(line.angle, basePosition)}

			if (line.x_direction ~= 0) then
				basePosition[1] = basePosition[1]*line.x_direction
			end

			if (line.y_direction ~= 0) then
				basePosition[2] = basePosition[2]*line.y_direction
			end

			self.shine[0+i]:SetPoint("CENTER", self.startPoint, unpack(basePosition))
		end	
	end

	line.tex = {
		filler = ProgressionFrame.spellTree.content.nodes:CreateTexture(nil, "BORDER"),
		glow = ProgressionFrame.spellTree.content.nodes:CreateTexture(nil, "ARTWORK"),
		glowAdd = ProgressionFrame.spellTree.content.nodes:CreateTexture(nil, "OVERLAY"),
	}
	line.tex.filler:SetTexture("Interface\\SkillTree\\node_connector")
	line.tex.filler:SetPoint("CENTER", line, 0, 0)

	line.tex.glow:SetTexture("Interface\\SkillTree\\node_connector")
	line.tex.glow:SetPoint("CENTER", line, 0, 0)
	line.tex.glow:SetBlendMode("ADD")

	line.tex.glowAdd:SetTexture("Interface\\SkillTree\\node_connector")
	line.tex.glowAdd:SetPoint("CENTER", line, 0, 0)
	line.tex.glowAdd:SetBlendMode("ADD")

	line.shine = {}

	for i = 1, 4 do
		table.insert(line.shine, AutoCastSparkleTemplate(ProgressionFrame.spellTree.content.nodes))
	end

	AddRotationAnimation(line)

	for _, tex in pairs(line.tex) do
		AddRotationAnimation(tex)
	end

	function line:Enable()
		line.tex.glow:Show()
		line.tex.glowAdd:Show()
		line.tex.filler:SetAlpha(1)
		for _, shine in pairs(line.shine) do
			shine:Show()
		end
		line:SetScript("OnUpdate", AutoCastShine_Update)
	end

	function line:Preload()
		line.tex.glowAdd:Show()
		for _, shine in pairs(line.shine) do
			shine:Show()
		end
		line:SetScript("OnUpdate", AutoCastShine_Update)
	end

	function line:Disable()
		line.tex.glow:Hide()
		line.tex.glowAdd:Hide()
		line.tex.filler:SetAlpha(0.5)
		for _, shine in pairs(line.shine) do
			shine:Hide()
		end
		line:SetScript("OnUpdate", nil)
	end

	function line:Rotate(angle)
		line.rotation.rotate:SetDegrees(angle)
		line.rotation:Stop()
		line.rotation:Play()

		for _, tex in pairs(line.tex) do
			tex.rotation.rotate:SetDegrees(angle)
			tex.rotation:Stop()
			tex.rotation:Play()
		end
	end

	function line:SetVertexColor(r, g, b, a)
		for _, tex in pairs(line.tex) do
			tex:SetVertexColor(r, g, b, a)
		end
		line.tex.glowAdd:SetVertexColor(1,1,1,0.3)

		for _, shine in pairs(line.shine) do
			shine:SetVertexColor(r+0.2, g+0.2, b+0.2, a)
		end
	end

	function line:CalcPointAndSize()
		if not(line.startPoint) or not(line.endPoint) then -- TODO: Can be improved to support additional coords
			return false
		end

		local start_x, start_y = line.startPoint:GetCenter()
		local end_x, end_y = line.endPoint:GetCenter()
		local parent_x, parent_y = line:GetParent():GetCenter()

		if not(end_x or start_x) then
			return false
		end

		local x_size = end_x - start_x
		local y_size = end_y - start_y

		local x_point = start_x+(x_size/2)-parent_x
		local y_point = start_y+(y_size/2)-parent_y

		local width = math.sqrt((x_size^2) + (y_size^2))
		local angle = math.deg(math.atan(y_size/x_size))
		--local relativePoint_x, relativePoint_y = line:GetParent():GetCenter()

		line.length = width -- used in shine
		line.angle = math.abs(angle) -- used in shine, abs because we define - or + by looking at end point's position
		line.x_direction = ((x_size ~= 0) and x_size/math.abs(x_size) or 0)
		line.y_direction = ((y_size ~= 0) and y_size/math.abs(y_size) or 0)

		line:SetWidth(width)
		line:SetPoint("CENTER", x_point, y_point)
		line:Rotate(angle)

		for _, tex in pairs(line.tex) do
			tex:SetWidth(width)
		end

		return true
	end

	function line:SetStartPoint(parent)
		line.startPoint = parent
	end

	function line:SetEndPoint(parent)
		line.endPoint = parent
	end

	function line:SetThickness(size)
		line:SetHeight(size)
		for _, tex in pairs(line.tex) do
			tex:SetHeight(size)
		end
	end

	line:SetScript("OnShow", CalcCheck)

	return line
end

--
-- Node template
--
local function FakeNodeTemplate(frame, radius)
	frame:SetSize(radius, radius)
	frame.center = ProgressionFrame.spellTree.content.nodes:CreateTexture(nil, "OVERLAY")
	frame.center:SetSize(32, 32)
	frame.center:SetTexture("Interface\\AddOns\\awgm\\BCNew\\StatBorder")
	frame.center:SetPoint("CENTER", frame, 0, 0)

	frame.bg = ProgressionFrame.spellTree.content.nodes:CreateTexture(nil, "BACKGROUND")
	frame.bg:SetSize(radius*1.42, radius*1.42)
	frame.bg:SetTexture("Interface\\SkillTree\\node_stone")
	frame.bg:SetPoint("CENTER", frame, 0, 0)
	frame:EnableMouse(false)
end

local function SpellNodeTemplate(frame)
    frame:SetSize(58, 58)
    frame:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    frame:RegisterForClicks("AnyUp")
    frame.icon = frame:CreateTexture(nil, "BACKGROUND")
    frame.icon:SetSize(46,46)
    frame.icon:SetPoint("CENTER", 0, 2)
    SetPortraitToTexture(frame.icon, "Interface\\Icons\\spell_deathknight_bloodpresence")

    frame.borderMetal = frame:CreateTexture(nil, "ARTWORK")
    frame.borderMetal:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\IconBorderRace") 
    frame.borderMetal:SetSize(94, 94)
    frame.borderMetal:SetPoint("CENTER", 0, 0)

    frame.borderMetal_Runes = frame:CreateTexture(nil, "OVERLAY")
    frame.borderMetal_Runes:SetTexture("Interface\\SkillTree\\spell_metal_border_runes") 
    frame.borderMetal_Runes:SetSize(94, 94)
    frame.borderMetal_Runes:SetPoint("CENTER", 0, 0)
    frame.borderMetal_Runes:SetBlendMode("ADD")
    frame.borderMetal_Runes:Hide()

    frame.borderOutline = frame:CreateTexture(nil, "BACKGROUND")
    frame.borderOutline:SetTexture("Interface\\SkillTree\\spellborder") 
    frame.borderOutline:SetSize(66, 66)
    frame.borderOutline:SetPoint("CENTER", 0, 0)

    frame.borderOutlineAdd = frame:CreateTexture(nil, "BORDER")
    frame.borderOutlineAdd:SetTexture("Interface\\SkillTree\\spellborder")
    frame.borderOutlineAdd:SetSize(65, 65)
    frame.borderOutlineAdd:SetPoint("CENTER", 0, 0)
    frame.borderOutlineAdd:SetBlendMode("ADD")

    frame.borderOutlineGlow = frame:CreateTexture(nil, "OVERLAY")
    frame.borderOutlineGlow:SetTexture("Interface\\SkillTree\\spellborder")
    frame.borderOutlineGlow:SetSize(65, 65)
    frame.borderOutlineGlow:SetPoint("CENTER", 0, 0)
    frame.borderOutlineGlow:SetBlendMode("ADD")
    frame.borderOutlineGlow:SetAlpha(0.6)

    for _, tex in pairs({frame.borderOutlineAdd, frame.borderOutlineGlow, frame.borderMetal_Runes}) do
    	tex.Pulse = tex:CreateAnimationGroup()
	    tex.Pulse.Alpha0 = tex.Pulse:CreateAnimation("Alpha")
	    tex.Pulse.Alpha0:SetChange(-0.6)
	    tex.Pulse.Alpha0:SetDuration(0.7)
	    tex.Pulse.Alpha0:SetOrder(1)
	    tex.Pulse.Alpha0:SetSmoothing("OUT")

	    tex.Pulse.Alpha1 = tex.Pulse:CreateAnimation("Alpha")
	    tex.Pulse.Alpha1:SetChange(0.6)
	    tex.Pulse.Alpha1:SetDuration(0.7)
	    tex.Pulse.Alpha1:SetOrder(2)
	    tex.Pulse.Alpha1:SetSmoothing("IN")

	    tex.Pulse:SetScript("OnFinished", function(self)
	    	self:Play()
	    end)
	end

	function frame:MakeSpecial() -- TODO: Make set back to normal?
		frame:SetSize(75, 75)
		frame.borderMetal:SetTexture("Interface\\SkillTree\\spell_metal_border") 
		frame.borderMetal_Runes:Show()
		frame.icon:SetSize(60,60)
		frame.borderMetal:SetSize(122, 122)
		frame.borderMetal_Runes:SetSize(122, 122)
		frame.borderOutline:SetSize(86, 86)
		frame.borderOutlineAdd:SetSize(84.5, 84.5)
		frame.borderOutlineGlow:SetSize(84.5, 84.5)
	end

	function frame:Pulse()
		frame.borderMetal_Runes.Pulse:Stop()
		frame.borderOutlineAdd.Pulse:Stop()
		frame.borderOutlineGlow.Pulse:Stop()
		frame.borderOutlineAdd.Pulse:Play()
		frame.borderOutlineGlow.Pulse:Play()
		frame.borderMetal_Runes.Pulse:Play()
	end

	function frame:StopPulse()
		frame.borderMetal_Runes.Pulse:Stop()
		frame.borderOutlineAdd.Pulse:Stop()
		frame.borderOutlineGlow.Pulse:Stop()
	end

    function frame:SetVertexColor(r, g, b, a)
		frame.borderOutline:SetVertexColor(r, g, b, a)
		frame.borderOutlineAdd:SetVertexColor(r, g, b, a)
		frame.borderMetal_Runes:SetVertexColor(r, g, b, a)
    end

    function frame:SetSpell(spellID)
    	if not(spellID) then
    		spellID = frame.spell
    	end

    	if not(spellID) then
    		return
    	end

    	local name, _, icon = GetSpellInfo(spellID)
    	SetPortraitToTexture(frame.icon, icon)
    end

    frame:SetScript("OnEnter", function(self)
	    if (self.spell) then
	        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
	        GameTooltip:SetHyperlink("spell:"..self.spell)
	        --TooltipAddData(self) -- TODO: Develop specifically for new nodes
	        GameTooltip:Show()
	    end
	end)

    frame:SetScript("OnLeave", function()
	    GameTooltip:Hide()
	end)

	frame:SetScript("OnClick", function(self) -- TODO: handles both learn and unlearn, TEMP
		if not(self.nodeID) then
			return
		end

		if C_CharacterAdvancement.IsKnownID(self.nodeID) then
			nodeController:TryUnlearn(self.nodeID)
		else
			CA_LearnSpell(self.nodeID)
		end
	end)

end

local function NodeTemplate(sID, nodeID, size)
	local frame = CreateFrame("BUTTON", "$parent.node"..nodeID, ProgressionFrame.spellTree.content.nodes)
	frame.spell = sID
	frame.nodeID = nodeID
	frame.lines = {}
	frame.status = "LOCKED"

	function frame:EnableLines()
    	if next(frame.lines) then 
    		for _, line in pairs(frame.lines) do
    			line:Enable()
    		end
    	end
    end

	function frame:DisableLines()
    	if next(frame.lines) then 
    		for _, line in pairs(frame.lines) do
    			line:Disable()
    		end
    	end
    end

    function frame:PreloadLines()
    	if next(frame.lines) then 
    		for _, line in pairs(frame.lines) do
    			line:Preload()
    		end
    	end
    end

    function frame:SetUnknown()
    	frame.status = "UNKNOWN"

    	if (nodeController:IsFakeNode(frame)) then
    		frame:PreloadLines()
    		return
    	end
    	frame.icon:SetVertexColor(1,1,1,1)
    	frame.icon:SetDesaturated(true)
    	frame.borderOutlineGlow:Show()
    	frame.borderOutlineAdd:Show()
    	frame.borderOutline:SetAlpha(0.5)
    	frame.borderOutlineAdd:SetAlpha(1) -- TODO: Add pulse
    	frame.borderOutlineGlow:SetAlpha(0.6)
    	frame:Pulse()

    	frame:PreloadLines()
    end

    function frame:SetKnown()
    	frame.status = "KNOWN"

    	if (nodeController:IsFakeNode(frame)) then
	    	frame:EnableLines()
    		return
    	end
    	frame:StopPulse()
    	frame.icon:SetVertexColor(1,1,1,1)
    	frame.icon:SetDesaturated(false)
    	frame.borderOutlineGlow:Show()
    	frame.borderOutlineAdd:Show()
    	frame.borderOutline:SetAlpha(1)
    	frame.borderOutlineAdd:SetAlpha(1)
    	frame.borderOutlineGlow:SetAlpha(0.3)

    	frame:EnableLines()
    end

    function frame:SetLocked()
    	frame.status = "LOCKED"

    	if (nodeController:IsFakeNode(frame)) then
    		frame:DisableLines()
    		return
    	end

    	frame:StopPulse()
    	frame.icon:SetVertexColor(1,0,0,1)
    	frame.icon:SetDesaturated(false)
    	frame.borderOutlineGlow:Hide()
    	frame.borderOutlineAdd:Hide()

    	frame:DisableLines()
    end

	-- nodes can be "fake" and real (based on spellID)
	-- for fake node just create a point and BG texture

	if nodeController:IsFakeNode(frame) then
		local size = size or 128
		FakeNodeTemplate(frame, size) -- TODO: Make adjustable default fake node size
		--[[if (nodeID == 1) then -- TODO: hackfix
			frame.bg:Hide()
		end]]--
	else
		SpellNodeTemplate(frame)
		frame:SetSpell()
		frame:SetLocked()
	end

	return frame
end

--
-- Node Controller
--
local function NodeController() -- TODO: Make a child of main frame
	local self = CreateFrame("FRAME")
	local fakeNodeSpellEntry = -1
	self.nodes = {}
	self.startingNodes = {}
	self.visitedList = {}
	self.unlearnedCollector = {}

	function self:IsFakeNode(node) -- can work with values from self.nodes or frame
		if (node.frame) then
			if (node.frame.spell and (node.frame.spell == 1) ) then
				return true
			end
		elseif (node.spell and (node.spell == 1) ) then
			return true
		end
		return false
	end

	function self:Connect(startPoint, endPoint) -- TODO: Probably move line to a child of starting point
		local line = CreateFrame("FRAME", nil, ProgressionFrame.spellTree.content.nodes)
		CreateLine(line)
		line:SetStartPoint(startPoint) -- TODO: probably rework this with better logic
		line:SetEndPoint(endPoint)
		line:SetThickness(36)
		return line
	end

	function self:PlaceAndConnectNode(frame, parentFrame, distance, anchor, x, y, color)
		--{sID = 33331, parentID = 1, distance = 64, anchor = "LEFT", color = "RED"}, 

		if (distance and (distance ~= 0) ) and parentFrame then
			local angle = 0 -- RIGHT

			if (anchor == "TOPRIGHT") then
				angle = 45
			elseif (anchor == "TOP") then
				angle = 90
			elseif (anchor == "TOPLEFT") then
				angle = 135
			elseif (anchor == "LEFT") then
				angle = 180
			elseif (anchor == "BOTTOMLEFT") then
				angle = 225
			elseif (anchor == "BOTTOM") then
				angle = 270
			elseif (anchor == "BOTTOMRIGHT") then
				angle = 315
			end

			frame:SetPoint("CENTER", parentFrame, CalcPos(angle, distance))
		elseif (x and y) ~= nil then
			frame:SetPoint("CENTER", x, y)
		end

		if (parentFrame) then
			if not(self:IsFakeNode(parentFrame)) then
				local line = self:Connect(parentFrame, frame)
				line:SetVertexColor(unpack(COLORS[color]))
				line:Disable()
				table.insert(frame.lines, line)
			end
		end

		if not(self:IsFakeNode(frame)) then
			frame:SetVertexColor(unpack(COLORS[color]))
		end
	end

	function self:FormNodes(inputData) -- input goes from CHARACTER_ADVANCEMENT_NODES
		self.nodes = {}
		local childList = {}

		for nodeID, data in pairs(inputData) do

			local size = ((data.SizeX ~= 0) and data.SizeX) or 128
			local spells = 1

			if (data.Spells) then -- Support exist only for records with 1 entry
				if (type(data.Spells) == "table") then
					spells = data.Spells[1]
				else
					spells = data.Spells
				end
	        end

	        if (bit.contains(data.Flags, Enum.CharacterAdvancementFlag.ConnectingNode)) then -- TODO: Probably rework, just set spell 1 to make system think its connection node
	        	spells = 1
	        end

			self.nodes[nodeID] = {frame = NodeTemplate(spells, nodeID, size), parent = data.ParentNode, childs = {}, data = data}
			local node = self.nodes[nodeID]
			local parent = self.nodes[data.ParentNode]

			if (parent) then -- parent node already exists
				table.insert(parent.childs, nodeID)
				self:PlaceAndConnectNode(node.frame, parent.frame, data.Distance, data.Anchor, data.PositionX, data.PositionY, data.Color)
			elseif (data.ParentNode == 0) then -- no parent
				self:PlaceAndConnectNode(node.frame, nil, data.Distance, data.Anchor, data.PositionX, data.PositionY, data.Color)
				table.insert(self.startingNodes, nodeID)
			else -- parent node doesn't exist yet
				childList[data.ParentNode] = childList[data.ParentNode] or {}
				table.insert(childList[data.ParentNode], nodeID)
			end

			if (childList[nodeID]) then -- if node is a parent to different nodes which were already made
				node.childs = {unpack(childList[nodeID])}
				childList[nodeID] = nil

				for _, v in pairs(node.childs) do
					local child = self.nodes[v]
					self:PlaceAndConnectNode(child.frame, node.frame, child.data.Distance, child.data.Anchor, child.data.PositionX, child.data.PositionY, child.data.Color)
				end
			end

		end
	end

	function self:IsParentKnownOrStartingNode(node)
		local parent = self.nodes[node.parent]

		if (node.parent == 0) or not(parent) then
			return true
		end


		if (self:CheckIfNodeKnown(parent)) then
			return true
		end

		return false
	end

	function self:CheckIfNodeKnown(node)
		if (self:IsFakeNode(node)) then -- fake node is known if its parent is known or its a starting node
			if (self:IsParentKnownOrStartingNode(node)) then
				return true
			end

			return false
		end

		if node.frame and node.frame.spell and C_CharacterAdvancement.IsKnownID(node.frame.nodeID) then 
			return true
		end

		return false
	end

	function self:dfs(nodeID, Condition, IsTureFunction, IsFalseFunction)
		--Timer.After(1, function() -- timer can be used for visualisation/debug
		local node = self.nodes[nodeID]
		
		if Condition(node) then
			if (IsTureFunction) then
				IsTureFunction(node)
			end
			return true
		else
			self.visitedList[nodeID] = true
			for _, child in pairs(node.childs) do
				if not(self.visitedList[child]) then
					self:dfs(child, Condition, IsTureFunction, IsFalseFunction)
				end
			end
		end

		if (IsFalseFunction) then
			IsFalseFunction(node)
		end
		return false
		--end)
	end

	function self:ScanCorrectKnownStatus(nodeID)
		self.visitedList = {}

		local function Check(node) -- stop at properly locked node
			return not(self:CheckIfNodeKnown(node))
		end

		local function True(node)
			if (node.frame.status == "KNOWN") or (node.frame.status == "UNKNOWN") then
				node.frame:SetLocked()
				for _, child in pairs(node.childs) do
					self:ScanCorrectKnownStatus(child)
				end
			end
			
			if (self:IsParentKnownOrStartingNode(node)) then -- if we end up having a known node before set unknown
				node.frame:SetUnknown()
				return
			end
		end

		local function False(node)
			node.frame:SetKnown()
		end

		self:dfs(nodeID, Check, True, False)
	end

	function self:TryUnlearn(nodeID) -- TODO: probably better use logic with CHARACTER_ADVANCEMENT_REQUIRED_FOR
		local nodesToUnlearn = {}
		self.visitedList = {}

		local function False(node)
			if not(self:IsFakeNode(node)) then
				table.insert(nodesToUnlearn, node.frame.nodeID) 
			end 
		end

		local function Check(node)
			return (not(self:CheckIfNodeKnown(node)) and not(self:IsFakeNode(node)))
		end

		self:dfs(nodeID, Check, nil, False)
		
		ShowUnlearnDialogue(nodesToUnlearn)
	end

	function self:InitialScan() 
		for _, nodeID in pairs(self.startingNodes) do
			local node = self.nodes[nodeID]
			if node then
				self:ScanCorrectKnownStatus(nodeID)

				-- make spell special if its a starting node or make childs special if they're childs of starting node
				if (self:IsFakeNode(node)) then
					for _, v in pairs(node.childs) do
						local child = self.nodes[v]
						if not(self:IsFakeNode(child)) then
							child.frame:MakeSpecial()
						end
					end
					-- TODO: Make an option to pick node's BG. Just hide BG for starting node for now
					node.frame.bg:Hide()
				else
					node.frame:MakeSpecial()
				end
			end
		end
	end

	function self:ASCENSION_KNOWN_ENTRY_ADDED(nodeID)
		local node = self.nodes[nodeID]

		if not(node) then
			return
		end

		self:ScanCorrectKnownStatus(nodeID)
	end

	-- TODO: Collect unknown into table and then do proper scan?
	function self:ASCENSION_KNOWN_ENTRY_REMOVED(nodeID)
		local node = self.nodes[nodeID]

		if not(node) then
			return
		end

		if not(next(self.unlearnedCollector)) then
			Timer.After(0.5, function()

				for i = #self.unlearnedCollector, 1, -1 do
					local nodeID = self.unlearnedCollector[i]
					local node = self.nodes[nodeID]
					self:ScanCorrectKnownStatus(nodeID)
					table.remove(self.unlearnedCollector, i)
				end
			end)
		end

		table.insert(self.unlearnedCollector, nodeID)
	end

	self:HookEvent("ASCENSION_KNOWN_ENTRY_ADDED")
	self:HookEvent("ASCENSION_KNOWN_ENTRY_REMOVED")

	return self
end

--
-- UI
--

local ProgressionFrame = CreateFrame("FRAME", "ProgressionFrame", UIParent, "PortraitFrameTemplate")
ProgressionFrame:SetPoint("CENTER", 0, 0)
ProgressionFrame:SetFrameStrata("DIALOG")
ProgressionFrame:SetClampedToScreen(true)
ProgressionFrame:SetSize(1380, 776)
ProgressionFrame:SetMovable(true)
ProgressionFrame:EnableMouse(true)
ProgressionFrame:RegisterForDrag("LeftButton")
ProgressionFrame:SetScript("OnDragStart", ProgressionFrame.StartMoving)
ProgressionFrame:SetScript("OnDragStop", ProgressionFrame.StopMovingOrSizing)
ProgressionFrame:SetScript("OnMouseDown", function()
    --SetSpellButtonSelected(0)
    CloseDropDownMenus()
end)

ProgressionFrame.spellTree = CreateFrame("FRAME", "ProgressionFrame.spellTree", ProgressionFrame)
ProgressionFrame.spellTree:SetWidth(CONTENT_SIZE)
ProgressionFrame.spellTree:SetHeight(CONTENT_SIZE)

-- I don't know why. I tried to figure out why but I couldn't. Scroll frame's child sizes properly only if you change absolute sizes of a child changed. 
-- not by using setscale
ProgressionFrame.spellTree.content = CreateFrame("FRAME", "ProgressionFrame.spellTree.content", ProgressionFrame.spellTree)
ProgressionFrame.spellTree.content:SetPoint("CENTER", ProgressionFrame.spellTree)
ProgressionFrame.spellTree.content:SetSize(CONTENT_SIZE, CONTENT_SIZE)

-- some basic logic.
-- ScrollChild doesn't support SetFrameLevel or SetFrameStrata to handle frame order inside of it
-- instead used 2 basic frames: 
-- ProgressionFrame.spellTree.content -- mostly for artworks
-- ProgressionFrame.spellTree.content.nodes -- for usable stuff, goes above ProgressionFrame.spellTree.content
-- all of the textures created inside of nodes have ProgressionFrame.spellTree.content.nodes as a parent

-- example of artworks
ProgressionFrame.spellTree.content.BGCircleCenter = BgCircleBigTemplate(ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.BGCircleCenter:SetPoint("CENTER", 0, 0)
ProgressionFrame.spellTree.content.BGCircleCenter:SetDrawLayer("ARTWORK")

ProgressionFrame.spellTree.content.BGCicleCenterSmall = BgCircleSmallTemplate(ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.BGCicleCenterSmall:SetPoint("CENTER", 0, 0)
ProgressionFrame.spellTree.content.BGCicleCenterSmall:SetDrawLayer("OVERLAY")

ProgressionFrame.spellTree.content.Star = BgCircleBigTemplate(ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.Star:SetPoint("CENTER", 0, 0)
ProgressionFrame.spellTree.content.Star:SetDrawLayer("OVERLAY")
ProgressionFrame.spellTree.content.Star:SetTexture("Interface\\SkillTree\\star_center_v2")
ProgressionFrame.spellTree.content.Star:SetSize(256, 256)

--[[ProgressionFrame.spellTree.content.BGClouds = BgCircleBigTemplate(ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.BGClouds:SetDrawLayer("BORDER")
ProgressionFrame.spellTree.content.BGClouds:SetTexture("Interface\\SkillTree\\CloudsOfStone")
ProgressionFrame.spellTree.content.BGClouds:SetPoint("CENTER", 0, 0)
ProgressionFrame.spellTree.content.BGClouds:SetSize(1370,1370)]]--

ProgressionFrame.spellTree.content.BG1 = ProgressionFrame.spellTree.content:CreateTexture(nil, "BACKGROUND")
ProgressionFrame.spellTree.content.BG1:SetSize(2750, 2750)
ProgressionFrame.spellTree.content.BG1:SetTexture("Interface\\SkillTree\\BG_painting")
ProgressionFrame.spellTree.content.BG1:SetPoint("BOTTOMRIGHT", ProgressionFrame.spellTree.content, "CENTER", 0, 0)

ProgressionFrame.spellTree.content.BG2 = ProgressionFrame.spellTree.content:CreateTexture(nil, "BACKGROUND")
ProgressionFrame.spellTree.content.BG2:SetSize(2750, 2750)
ProgressionFrame.spellTree.content.BG2:SetTexture("Interface\\SkillTree\\BG_painting")
ProgressionFrame.spellTree.content.BG2:SetPoint("BOTTOMLEFT", ProgressionFrame.spellTree.content, "CENTER", 0, 0)
ProgressionFrame.spellTree.content.BG2:SetTexCoord(1, 0, 0, 1)

ProgressionFrame.spellTree.content.BG3 = ProgressionFrame.spellTree.content:CreateTexture(nil, "BACKGROUND")
ProgressionFrame.spellTree.content.BG3:SetSize(2750, 2750)
ProgressionFrame.spellTree.content.BG3:SetTexture("Interface\\SkillTree\\BG_painting")
ProgressionFrame.spellTree.content.BG3:SetPoint("TOPLEFT", ProgressionFrame.spellTree.content, "CENTER", 0, 0)
ProgressionFrame.spellTree.content.BG3:SetTexCoord(1, 0, 1, 0)

ProgressionFrame.spellTree.content.BG4 = ProgressionFrame.spellTree.content:CreateTexture(nil, "BACKGROUND")
ProgressionFrame.spellTree.content.BG4:SetSize(2750, 2750)
ProgressionFrame.spellTree.content.BG4:SetTexture("Interface\\SkillTree\\BG_painting")
ProgressionFrame.spellTree.content.BG4:SetPoint("TOPRIGHT", ProgressionFrame.spellTree.content, "CENTER", 0, 0)
ProgressionFrame.spellTree.content.BG4:SetTexCoord(0, 1, 1, 0)

-- ProgressionFrame.spellTree.content.nodes -- for usable stuff, goes above ProgressionFrame.spellTree.content
ProgressionFrame.spellTree.content.nodes = CreateFrame("FRAME", "ProgressionFrame.spellTree.content.nodes", ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.nodes:SetPoint("CENTER", ProgressionFrame.spellTree.content)
ProgressionFrame.spellTree.content.nodes:SetSize(CONTENT_SIZE, CONTENT_SIZE)

ProgressionFrame.scroll = CreateFrame("ScrollFrame", "ProgressionFrame.scroll", ProgressionFrame, "InsetFrameTemplate")
ProgressionFrame.scroll:SetSize(1105, 690) -- TODO: Make it fit different resolutions, too long
ProgressionFrame.scroll:EnableMouseWheel(true)
ProgressionFrame.scroll:RegisterForDrag("LeftButton")
ProgressionFrame.scroll:EnableMouse(true)
ProgressionFrame.scroll:SetScrollChild(ProgressionFrame.spellTree)
ProgressionFrame.scroll:SetPoint("BOTTOMLEFT", ProgressionFrame, 4, 6)

ProgressionFrame.spellTree:SetPoint("CENTER", ProgressionFrame.scroll, 0, 0)

ProgressionFrame.controlFrame = CreateFrame("FRAME", "ProgressionFrame.controlFrame", ProgressionFrame)
ProgressionFrame.controlFrame:SetSize(1105, 690) -- TODO: Make it fit different resolutions, too long
ProgressionFrame.controlFrame:SetPoint("BOTTOMLEFT", ProgressionFrame, 4, 6)
ProgressionFrame.controlFrame:SetFrameLevel(ProgressionFrame.scroll:GetFrameLevel()+1)

ProgressionFrame.controlFrame.cornerTopLeft = ProgressionFrame.controlFrame:CreateTexture(nil, "OVERLAY")
ProgressionFrame.controlFrame.cornerTopLeft:SetSize(202, 202)
ProgressionFrame.controlFrame.cornerTopLeft:SetTexture("Interface\\SkillTree\\corners")
ProgressionFrame.controlFrame.cornerTopLeft:SetTexCoord(0, 0.5, 0, 0.5)
ProgressionFrame.controlFrame.cornerTopLeft:SetPoint("TOPLEFT", 0, 0)

ProgressionFrame.controlFrame.cornerBottomRight = ProgressionFrame.controlFrame:CreateTexture(nil, "OVERLAY")
ProgressionFrame.controlFrame.cornerBottomRight:SetSize(202, 202)
ProgressionFrame.controlFrame.cornerBottomRight:SetTexture("Interface\\SkillTree\\corners")
ProgressionFrame.controlFrame.cornerBottomRight:SetTexCoord(0.5, 1, 0.5, 1)
ProgressionFrame.controlFrame.cornerBottomRight:SetPoint("BOTTOMRIGHT", 0, 0)

ProgressionFrame.controlFrame.navigation = CreateFrame("FRAME", "ProgressionFrame.controlFrame.navigation", ProgressionFrame.controlFrame)
ProgressionFrame.controlFrame.navigation:SetSize(128, 128)
ProgressionFrame.controlFrame.navigation:SetPoint("BOTTOMLEFT", ProgressionFrame, 16, 16)

ProgressionFrame.controlFrame.navigation.scrollLeft = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "scrollLeft")
ProgressionFrame.controlFrame.navigation.scrollLeft:SetPoint("LEFT", 0, 0)
ProgressionFrame.controlFrame.navigation.scrollLeft:SetTemplate("LEFT")
ProgressionFrame.controlFrame.navigation.scrollLeft:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = nil
	ProgressionFrame.scroll.targetX = ProgressionFrame.scroll:GetHorizontalScroll() - ProgressionFrame.scroll.maxHorizontalScroll*0.25
end)

ProgressionFrame.controlFrame.navigation.scrollDown = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "scrollDown")
ProgressionFrame.controlFrame.navigation.scrollDown:SetPoint("BOTTOM", 0, 0)
ProgressionFrame.controlFrame.navigation.scrollDown:SetTemplate("DOWN")
ProgressionFrame.controlFrame.navigation.scrollDown:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = nil
	ProgressionFrame.scroll.targetY = ProgressionFrame.scroll:GetVerticalScroll() + ProgressionFrame.scroll.maxVerticalScroll*0.25
end)

ProgressionFrame.controlFrame.navigation.scrollUp = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "scrollUp")
ProgressionFrame.controlFrame.navigation.scrollUp:SetPoint("TOP", 0, 0)
ProgressionFrame.controlFrame.navigation.scrollUp:SetTemplate("UP")
ProgressionFrame.controlFrame.navigation.scrollUp:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = nil
	ProgressionFrame.scroll.targetY = ProgressionFrame.scroll:GetVerticalScroll() - ProgressionFrame.scroll.maxVerticalScroll*0.25
end)

ProgressionFrame.controlFrame.navigation.scrollRight = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "scrollRight")
ProgressionFrame.controlFrame.navigation.scrollRight:SetPoint("RIGHT", 0, 0)
ProgressionFrame.controlFrame.navigation.scrollRight:SetTemplate("RIGHT")
ProgressionFrame.controlFrame.navigation.scrollRight:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = nil
	ProgressionFrame.scroll.targetX = ProgressionFrame.scroll:GetHorizontalScroll() + ProgressionFrame.scroll.maxHorizontalScroll*0.25
end)

ProgressionFrame.controlFrame.navigation.zoomOut = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "zoomOut")
ProgressionFrame.controlFrame.navigation.zoomOut:SetPoint("BOTTOMLEFT", ProgressionFrame.controlFrame.navigation, "BOTTOMRIGHT", 0, 0)
ProgressionFrame.controlFrame.navigation.zoomOut:SetTemplate("ZOOM_OUT")
ProgressionFrame.controlFrame.navigation.zoomOut:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = ProgressionFrame.spellTree.content:GetScale() - 0.25
    ProgressionFrame.scroll.targetX = nil
    ProgressionFrame.scroll.targetY = nil
end)

ProgressionFrame.controlFrame.navigation.zoomIn = SkillTreeSquareButtonTemplate(ProgressionFrame.controlFrame.navigation, "zoomIn")
ProgressionFrame.controlFrame.navigation.zoomIn:SetPoint("LEFT", ProgressionFrame.controlFrame.navigation.zoomOut, "RIGHT", 0, 0)
ProgressionFrame.controlFrame.navigation.zoomIn:SetTemplate("ZOOM_IN")
ProgressionFrame.controlFrame.navigation.zoomIn:SetScript("OnClick", function(self)
	ProgressionFrame.scroll.targetZoom = ProgressionFrame.spellTree.content:GetScale() + 0.25
    ProgressionFrame.scroll.targetX = nil
    ProgressionFrame.scroll.targetY = nil
end)

--
-- UI Scripts
--
function ProgressionFrame:OnShow()
	if not(self.init) then
		self.scroll:SetHorizontalScroll((self.spellTree:GetWidth() - self.scroll:GetWidth())/2) 
		self.scroll:SetVerticalScroll((self.spellTree:GetHeight() - self.scroll:GetHeight())/2) 
		self.scroll.maxVerticalScroll = self.spellTree:GetHeight() - self.scroll:GetHeight()
		self.scroll.maxHorizontalScroll = self.spellTree:GetWidth() - self.scroll:GetWidth()

		Timer.After(1, function() -- kind of hello to user
			self.scroll.targetZoom = 1
		end)

		nodeController:InitialScan() 
		self.init = true
	end
end

ProgressionFrame:SetScript("OnShow", ProgressionFrame.OnShow)

function ProgressionFrame.spellTree:GetCoursorModifier()
	local x, y = GetCursorPosition()
	x = x*UIParent:GetEffectiveScale()
	y = y*UIParent:GetEffectiveScale()

	local s = self:GetEffectiveScale()
	local left = self:GetLeft()*s
	local right = self:GetRight()*s
	local top = self:GetTop()*s
	local bottom = self:GetBottom()*s

	return (x-left)/(right-left), (1-(y-bottom)/(top-bottom))
end

function ProgressionFrame.scroll:CorrectScroll()
	local h = self:GetHorizontalScroll()
	local v = self:GetVerticalScroll()

    if (h < 0) then
    	self:SetHorizontalScroll(0)
    	self.targetX = nil
    end

    if (v < 0) then
    	self:SetVerticalScroll(0)
    	self.targetY = nil
    end

    if (v > self.maxVerticalScroll) then
    	self:SetVerticalScroll(self.maxVerticalScroll)
    	self.targetY = nil
    end

    if (h > self.maxHorizontalScroll) then
    	self:SetHorizontalScroll(self.maxHorizontalScroll)
    	self.targetX = nil
    end

    if (self:GetHorizontalScroll() == 0) then
    	ProgressionFrame.controlFrame.navigation.scrollLeft:Disable()
    else
    	ProgressionFrame.controlFrame.navigation.scrollLeft:Enable()
    end

    if (self:GetHorizontalScroll() >= (self.maxHorizontalScroll-1)) then
    	ProgressionFrame.controlFrame.navigation.scrollRight:Disable()
    else
    	ProgressionFrame.controlFrame.navigation.scrollRight:Enable()
    end

    if (self:GetVerticalScroll() == 0) then
    	ProgressionFrame.controlFrame.navigation.scrollUp:Disable()
    else
    	ProgressionFrame.controlFrame.navigation.scrollUp:Enable()
    end

    if (self:GetVerticalScroll() >= (self.maxVerticalScroll-1)) then
    	ProgressionFrame.controlFrame.navigation.scrollDown:Disable()
    else
    	ProgressionFrame.controlFrame.navigation.scrollDown:Enable()
    end
end

function ProgressionFrame.scroll:Zoom(delta, speed, coursorPosition)
	local spellTree = self:GetParent().spellTree
	local content = self:GetParent().spellTree.content

	local change = delta*(speed or 0.05)
	local scale = content:GetScale()
	local sizeWidth, sizeHeight = content:GetSize()
	local newScale = scale+change
	local newWidth = sizeWidth*newScale
	local newHeight = sizeHeight*newScale
	local coursorModifiers = coursorPosition or {spellTree:GetCoursorModifier()}

	if ((scale >= 1) and (delta > 0)) or (newScale < 0) then -- don't let to zoom too close
		ProgressionFrame.controlFrame.navigation.zoomIn:Disable()
		return
	else
		ProgressionFrame.controlFrame.navigation.zoomIn:Enable()
	end

	if (newHeight < self:GetHeight()) or (newWidth < self:GetWidth()) then -- don't let zoom too far
		ProgressionFrame.controlFrame.navigation.zoomOut:Disable()
		return
	else
		ProgressionFrame.controlFrame.navigation.zoomOut:Enable()
	end

	local newScrollV = self:GetVerticalScroll() + ((newHeight-spellTree:GetHeight())*coursorModifiers[2])
	local newscrollH = self:GetHorizontalScroll() + ((newWidth-spellTree:GetWidth())*coursorModifiers[1])

    content:SetScale(newScale)
    spellTree:SetSize(newWidth, newHeight)

	self.maxVerticalScroll = spellTree:GetHeight() - self:GetHeight()
	self.maxHorizontalScroll = spellTree:GetWidth() - self:GetWidth()

	self:SetVerticalScroll(newScrollV)
	self:SetHorizontalScroll(newscrollH)
    self:CorrectScroll()
end

ProgressionFrame.scroll:Zoom(-1, 0.7, {0.5, 0.5})

ProgressionFrame.scroll:SetScript("OnDragStart", function(self, ...)
    self.Start_X, self.Start_Y = GetCursorPosition()
    self.targetX = nil
    self.targetY = nil
end)
ProgressionFrame.scroll:SetScript("OnDragStop", function(self, ...)
    self.Start_X = nil
    self.Start_Y = nil
end)

ProgressionFrame.scroll:SetScript("OnMouseWheel", function(self, delta)
    self.targetX = nil
    self.targetY = nil
	self.targetZoom = nil
	ProgressionFrame.scroll:Zoom(delta)
end)

ProgressionFrame.scroll:SetScript("OnUpdate", function(self)
    if ( self.Start_X ) then
        local x = GetCursorPosition();
        local diff = -((x - self.Start_X) * 1);
        local newScroll = self:GetHorizontalScroll() + diff
        self.Start_X = GetCursorPosition();

        self:SetHorizontalScroll(newScroll)
        self:CorrectScroll()
    end

    if ( self.Start_Y ) then
        local x, y = GetCursorPosition();
        local diff = ((y - self.Start_Y) * 1);
        local newScroll = self:GetVerticalScroll() + diff
        _, self.Start_Y = GetCursorPosition()

        self:SetVerticalScroll(newScroll)
        self:CorrectScroll()
    end

    if ( self.targetX ) then
    	local currentPosition = self:GetHorizontalScroll()
    	local diff = math.abs(currentPosition - self.targetX)*0.1

		if (currentPosition < (self.targetX - 1)) then
			self:SetHorizontalScroll(currentPosition+diff)
		elseif (currentPosition > (self.targetX + 1)) then
			self:SetHorizontalScroll(currentPosition-diff)
		else
			self.targetX = nil
		end

		self:CorrectScroll()
    end

    if ( self.targetY ) then
    	local currentPosition = self:GetVerticalScroll()
    	local diff = math.abs(currentPosition - self.targetY)*0.1

		if (currentPosition < (self.targetY - 1)) then
			self:SetVerticalScroll(currentPosition+diff)
		elseif (currentPosition > (self.targetY + 1)) then
			self:SetVerticalScroll(currentPosition-diff)
		else
			self.targetY = nil
		end

		self:CorrectScroll()
    end

    if ( self.targetZoom ) then
    	local content = self:GetParent().spellTree.content
		local scale = content:GetScale()
		local diff = math.abs(self.targetZoom - scale)*0.02

		if (scale < (self.targetZoom - 0.02)) then
			ProgressionFrame.scroll:Zoom(1, diff, {0.5, 0.5})
		elseif (scale > (self.targetZoom + 0.02)) then
			ProgressionFrame.scroll:Zoom(-1, diff, {0.5, 0.5})
		else
			self.targetZoom = nil
		end
	end
end)

nodeController = NodeController()
nodeController:FormNodes(CHARACTER_ADVANCEMENT_NODES)

ProgressionFrame:Hide()
--Timer.After(0.5, function() ProgressionFrame:Show() end)
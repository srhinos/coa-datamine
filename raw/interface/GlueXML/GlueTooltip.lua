function GlueTooltip_SetOwner(self, tooltip, xOffset, yOffset, myPoint, ownerPoint)
	if ( not self ) then
		return;
	end
	if ( not tooltip ) then
		tooltip = GlueTooltip;
	end
	if ( not xOffset ) then
		xOffset = 0;
	end
	if ( not yOffset ) then
		yOffset = 0;
	end
	if ( not myPoint ) then
		myPoint = "BOTTOMLEFT";
	end
	if ( not ownerPoint ) then
		ownerPoint = "TOPRIGHT";
	end
	tooltip:ClearAndSetPoint(myPoint, self, ownerPoint, xOffset, yOffset);
	tooltip:Show();
end

function GlueTooltip_SetText(text, tooltip, r, g, b, a, wrapText)
	if ( not tooltip ) then
		tooltip = GlueTooltip;
	end
	tooltip:SetText(text, r, g, b, a, wrapText)
end

function GlueTooltip_SetFont(tooltip, font)
	if ( not tooltip ) then
		tooltip = GlueTooltip;
	end

	for i = 1, tooltip.numLines do
		local leftText = _G[tooltip:GetName().."TextLeft"..i];
		local rightText = _G[tooltip:GetName().."TextRight"..i];
		leftText:SetFontObject(font);
		rightText:SetFontObject(font);
	end
end

function GlueTooltip_Hide()
	GlueTooltip:Hide()
end
GameTooltip_Hide = GlueTooltip_Hide

function GlueTooltip_AutoAnchor(self)
	local x, y = self:GetCenter()
	local midY = GetScreenHeight() / 2
	local midX = GetScreenWidth() / 2

	local xPos = x >= midX and "LEFT" or "RIGHT"
	local yPos = y >= midY and "BOTTOM" or ""

	return "ANCHOR_"..yPos..xPos
end

function GlueTooltip_AddSpacer(self)
	self = self or GlueTooltip
	self:AddLine(" ")
end

function GlueTooltip_GenericTooltip(frame, anchor, minWidth)
	if frame.tooltipTitle then
		if not anchor then anchor = GlueTooltip_AutoAnchor(frame) end
		GlueTooltip:SetOwner(frame, anchor)
		GlueTooltip:SetText(frame.tooltipTitle, 1, 1, 1, 1)
		GlueTooltip:SetMinWidth(minWidth)
		if frame.tooltipText then
			if type(frame.tooltipText) == "table" then
				for _, line in ipairs(frame.tooltipText) do
					local text, r, g, b, wrap
					if type(line) == "table" then
						text, r, g, b, wrap = unpack(line)
					else
						text = line
						r, g, b = NORMAL_FONT_COLOR:GetRGB()
					end
					GlueTooltip:AddLine(text, r, g, b, 1, true, wrap)
				end
			else
				GlueTooltip:AddLine(frame.tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
			end
		end
		GlueTooltip:Show()
	end
end

GlueTooltipMixin = {}

function GlueTooltipMixin:OnLoad()
	self:SetBackdropBorderColor(1.0, 1.0, 1.0)
	self:SetBackdropColor(0.09, 0.09, 0.19 )
	self.numLines = 4
end

function GlueTooltipMixin:OnHide()
	self.owner = nil
	self:StopFrameStack()
	self:Clear()
end

function GlueTooltipMixin:SetOwner(owner, anchor, ofsX, ofsY)
	if not owner then
		owner = GlueParent
	end

	if not ofsX then
		ofsX = 0
	end

	if not ofsY then
		ofsY = 0
	end

	if anchor == "ANCHOR_TOP" then
		self:ClearAndSetPoint("BOTTOM", owner, "TOP", ofsX, ofsY)
	elseif anchor == "ANCHOR_RIGHT" then
		self:ClearAndSetPoint("BOTTOMLEFT", owner, "TOPRIGHT", ofsX, ofsY)
	elseif anchor == "ANCHOR_BOTTOM" then
		self:ClearAndSetPoint("TOP", owner, "BOTTOM", ofsX, ofsY)
	elseif anchor == "ANCHOR_LEFT" then
		self:ClearAndSetPoint("BOTTOMRIGHT", owner, "TOPLEFT", ofsX, ofsY)
	elseif anchor == "ANCHOR_TOPRIGHT" then
		self:ClearAndSetPoint("BOTTOMRIGHT", owner, "TOPRIGHT", ofsX, ofsY)
	elseif anchor == "ANCHOR_BOTTOMRIGHT" then
		self:ClearAndSetPoint("TOPLEFT", owner, "BOTTOMRIGHT", ofsX, ofsY)
	elseif anchor == "ANCHOR_TOPLEFT" then
		self:ClearAndSetPoint("BOTTOMLEFT", owner, "TOPLEFT", ofsX, ofsY)
	elseif anchor == "ANCHOR_BOTTOMLEFT" then
		self:ClearAndSetPoint("TOPRIGHT", owner, "BOTTOMLEFT", ofsX, ofsY)
	elseif anchor == "ANCHOR_CURSOR" then
		local x, y = GetCursorPosition()
		x = (x - (GetScreenWidth() - GlueParent:GetWidth()) / 2) / GlueParent:GetEffectiveScale()
		y = (y - (GetScreenHeight() - GlueParent:GetHeight()) / 2) / GlueParent:GetEffectiveScale()
		self:ClearAndSetPoint("BOTTOMLEFT", GlueParent, "BOTTOMLEFT", x, y)
	elseif anchor == "ANCHOR_NONE" then
		self:ClearAllPoints()
	else
		self:ClearAndSetPoint("BOTTOMLEFT", GlueParent, "BOTTOMLEFT")
	end
	
	self.owner = owner
end

function GlueTooltipMixin:GetOwner()
	return self.owner
end

function GlueTooltipMixin:IsOwned(target)
	return self.owner == target
end

function GlueTooltipMixin:SetText(text, r, g, b, a, wrap)
	self:Clear()
	self:AddLine(text, r, g, b, a, wrap)
	self:Show()
end 

function GlueTooltipMixin:Clear()
	for i = 1, self.numLines do
		local text = _G[self:GetName().."TextLeft"..i]
		text:SetText("")
		text:Hide()
		text:SetWidth(0)
		
		text = _G[self:GetName().."TextRight"..i]
		text:SetText("")
		text:Hide()
		text:SetWidth(0)
	end
	
	self:SetMinWidth()
	self:SetSize(1, 1)
end

function GlueTooltipMixin:AddLine(text, r, g, b, a, wrap, indentWrap)
	r = r or NORMAL_FONT_COLOR.r
	g = g or NORMAL_FONT_COLOR.g
	b = b or NORMAL_FONT_COLOR.b
	if type(a) == "boolean" then
		wrap = a
		a = 1
	else
		a = a or NORMAL_FONT_COLOR.a
		wrap = wrap or false
	end
	
	local nextLine, nextRightLine

	for i = 1, self.numLines do
		local line = _G[self:GetName().."TextLeft"..i]
		if not line:IsShown() then
			nextLine = line
			nextRightLine = _G[self:GetName().."TextRight"..i]
			break
		end
	end
	
	if not nextLine then
		nextLine = self:CreateFontString("$parentTextLeft"..(self.numLines+1), "ARTWORK", "GlueFontNormalSmall")
		nextLine:SetJustifyH("LEFT")
		local previousLine = _G[self:GetName().."TextLeft"..self.numLines]
		nextLine:SetPoint("TOPLEFT", previousLine, "BOTTOMLEFT", 0, -2)
		
		nextRightLine = self:CreateFontString("$parentTextRight"..(self.numLines+1), "ARTWORK", "GlueFontNormalSmall")
		nextRightLine:SetJustifyH("RIGHT")
		local previousLineRight = _G[self:GetName().."TextRight"..self.numLines]
		nextRightLine:SetPoint("TOPRIGHT", previousLineRight, "BOTTOMRIGHT", 0, -2)

		self.numLines = self.numLines + 1
		nextLine:Hide()
	end

	local minWidth = self.minWidth
	if minWidth then
		self:SetWidth(minWidth)
	end
	
	nextLine:SetTextColor(r, g, b, a)
	nextLine:SetWidth(0)
	nextLine:Show()
	nextLine:SetIndentedWordWrap(indentWrap)
	nextLine:SetText(text)

	nextRightLine:SetText("")
	nextRightLine:SetHeight(nextLine:GetStringHeight())
	nextRightLine:Hide()
	

	minWidth = minWidth or 230
	if wrap and nextLine:GetWidth() > minWidth then
		nextLine:SetWidth(minWidth)
		self:SetWidth(max(self:GetWidth(), minWidth+20))
	else
		self:SetWidth(max(self:GetWidth(), nextLine:GetWidth()+20))
	end
	
	local height = 18

	for i = 1, self.numLines do
		local line = _G[self:GetName().."TextLeft"..i]
		local right = _G[self:GetName().."TextRight"..i]
		if not right:IsShown() then
			line:SetWidth(self:GetWidth()-20)
		end

		if line:IsShown() then
			height = height + line:GetHeight() + 2
		end
	end
	
	self:SetHeight(height)
end


function GlueTooltipMixin:AddDoubleLine(lText, rText, lr, lg, lb, rr, rg, rb)
	lr = lr or NORMAL_FONT_COLOR.r
	lg = lg or NORMAL_FONT_COLOR.g
	lb = lb or NORMAL_FONT_COLOR.b

	rr = rr or NORMAL_FONT_COLOR.r
	rg = rg or NORMAL_FONT_COLOR.g
	rb = rb or NORMAL_FONT_COLOR.b

	local nextLine, nextRightLine

	for i = 1, self.numLines do
		local line = _G[self:GetName().."TextLeft"..i]
		if not line:IsShown() then
			nextLine = line
			nextRightLine = _G[self:GetName().."TextRight"..i]
			break
		end
	end

	if not nextLine then
		nextLine = self:CreateFontString("$parentTextLeft"..(self.numLines+1), "ARTWORK", "GlueFontNormalSmall")
		nextLine:SetJustifyH("LEFT")
		local previousLine = _G[self:GetName().."TextLeft"..self.numLines]
		nextLine:SetPoint("TOPLEFT", previousLine, "BOTTOMLEFT", 0, -2)

		nextRightLine = self:CreateFontString("$parentTextRight"..(self.numLines+1), "ARTWORK", "GlueFontNormalSmall")
		nextRightLine:SetJustifyH("RIGHT")
		local previousLineRight = _G[self:GetName().."TextRight"..self.numLines]
		nextRightLine:SetPoint("TOPRIGHT", previousLineRight, "BOTTOMRIGHT", 0, -2)

		self.numLines = self.numLines + 1
		nextLine:Hide()
		nextRightLine:Hide()
	end

	local minWidth = self.minWidth
	if minWidth then
		self:SetWidth(minWidth)
	end

	-- there is some issue where adding a double line after any amount of normal lines will just be broken
	-- idk how to fix right now and we dont use it at all so its a future problem lmao
	nextLine:SetTextColor(lr, lg, lb, 1)
	nextLine:SetHeight(0)
	nextLine:SetWidth(0)
	nextLine:SetText(lText)
	nextLine:Show()
	nextLine:SetIndentedWordWrap(false)

	nextRightLine:SetTextColor(rr, rg, rb, 1)
	nextRightLine:SetHeight(0)
	nextRightLine:SetWidth(0)
	nextRightLine:SetText(rText)
	nextRightLine:Show()
	nextRightLine:SetIndentedWordWrap(false)


	local rHeight = nextRightLine:GetHeight()
	local lHeight = nextLine:GetHeight()

	if rHeight > lHeight then
		nextLine:SetHeight(rHeight)
	else
		nextRightLine:SetHeight(lHeight)
	end

	self:SetWidth(max(self:GetWidth(), nextLine:GetWidth()+nextRightLine:GetWidth()+20))

	local height = 18

	for i = 1, self.numLines do
		local line = _G[self:GetName().."TextLeft"..i]
		local right = _G[self:GetName().."TextRight"..i]
		if not right:IsShown() then
			line:SetWidth(self:GetWidth()-20)
		end

		if line:IsShown() then
			height = height + line:GetHeight() + 2
		end
	end

	self:SetHeight(height)
end

function GlueTooltipMixin:SetMinWidth(minWidth)
	self.minWidth = minWidth
end

local FrameStrataOrder = {
	"TOOLTIP",
	"FULLSCREEN_DIALOG",
	"FULLSCREEN",
	"DIALOG",
	"HIGH",
	"MEDIUM",
	"LOW",
	"BACKGROUND",
	"PARENT"
}

local function BuildFrameStackTable(showHidden)
	local frame = EnumerateFrames()
	local frameStack = {}
	-- build frame list
	while frame do
		if (showHidden or frame:IsVisible()) and frame:IsMouseOver() and frame:GetName() then
			local strata = frame:GetFrameStrata()
			frameStack[strata] = frameStack[strata] or {}
			tinsert(frameStack[strata], 1, frame)
		end
		frame = EnumerateFrames(frame)
	end
	
	return frameStack
end

local function FormatFrameStack(stack)
	local str
	local hasMouseFocus
	for _, strata in ipairs(FrameStrataOrder) do
		if stack[strata] then
			if str then str = str .. "\n\n" else str = "" end
			str = str .. format("|cffFFFFFF[|cff0088FF%s|cffFFFFFF]|r", strata)

			for _, frame in ipairs(stack[strata]) do
				str = str .. "\n"
				if not hasMouseFocus and frame:IsMouseEnabled() and (not frame.IsEnabled or frame:IsEnabled()) then
					hasMouseFocus = true
					str = str .. "|cff00FF00-->|r "
				end
				
				str = str .. format("|cff00DDFF%s|r |cffFFFFFF(%d)|r", frame:GetName(), frame:GetFrameLevel())
			end
		end
	end
	
	return str
end

function GlueTooltipMixin:AutoPositionFStack()
	local x, y = GetCursorPosition()
	local midY = GetScreenHeight() / 2
	local midX = GetScreenWidth() / 2

	local xAnchor = x >= midX and "LEFT" or "RIGHT"
	local yAnchor = y >= midY and "BOTTOM" or "TOP"
	local anchor = yAnchor .. xAnchor
	self:ClearAndSetPoint(anchor, self.owner, anchor, 0, 0)
end

function GlueTooltipMixin:SetFrameStack(showHidden)
	self:StopFrameStack()
	self.FStackTicker = Timer.NewTicker(0.2, function()
		if self:IsMouseOver() then
			self:AutoPositionFStack()
		end
		local stack = BuildFrameStackTable(showHidden)
		self:SetText(FormatFrameStack(stack))
	end)
	self:Show()
end 

function GlueTooltipMixin:StopFrameStack()
	if self.FStackTicker then
		self.FStackTicker:Cancel()
		self.FStackTicker = nil
	end
end 
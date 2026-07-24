--[[
	HelpTip:Show("TIP_NAME")
	HelpTip:Hide("TIP_NAME")
]]


HelpTip = { };

HelpTip._glows = CreateFramePool("Frame", UIParent, "HighlightFrameTemplate", function(_, highlight) HelpTip:ResetHighlight(highlight) end)
-- external use enums

HelpTip.Point = {
	TopEdgeLeft = 1,
	TopEdgeCenter = 2,
	TopEdgeRight = 3,
	BottomEdgeLeft = 4,	
	BottomEdgeCenter = 5,
	BottomEdgeRight = 6,
	RightEdgeTop = 7,
	RightEdgeCenter = 8,
	RightEdgeBottom = 9,
	LeftEdgeTop = 10,
	LeftEdgeCenter = 11,
	LeftEdgeBottom = 12,
};

HelpTip.TargetType = {
	Box = 1,
	Circle = 2,
}

HelpTip.Alignment = {
	Left = 1,
	Center = 2,
	Right = 3,
	-- Intentional re-use of indices, really just need 3 settings but 5 makes it easier to visualize
	Top = 1,
	Bottom = 3,
};

HelpTip.ButtonStyle = {
	None = 1,
	Close = 2,
	Okay = 3,
	GotIt = 4,
	Next = 5,
	DontShowAgain = 6,
};

-- internal use enums

HelpTip.ArrowRotation = {
	Down = 1,
	Left = 2,
	Up = 3,
	Right = 4,
};

-- data

HelpTip.PointInfo = {
	[HelpTip.Point.TopEdgeLeft]		= { arrowRotation = HelpTip.ArrowRotation.Down,	 relativeAnchor = "TOPLEFT",	oppositePoint = HelpTip.Point.BottomEdgeLeft },
	[HelpTip.Point.TopEdgeCenter]	= { arrowRotation = HelpTip.ArrowRotation.Down,  relativeAnchor = "TOP",		oppositePoint = HelpTip.Point.BottomEdgeCenter },
	[HelpTip.Point.TopEdgeRight]	= { arrowRotation = HelpTip.ArrowRotation.Down,  relativeAnchor = "TOPRIGHT",	oppositePoint = HelpTip.Point.BottomEdgeRight },

	[HelpTip.Point.RightEdgeTop]	= { arrowRotation = HelpTip.ArrowRotation.Left,  relativeAnchor = "TOPRIGHT",	oppositePoint = HelpTip.Point.LeftEdgeTop },
	[HelpTip.Point.RightEdgeCenter] = { arrowRotation = HelpTip.ArrowRotation.Left,  relativeAnchor = "RIGHT",		oppositePoint = HelpTip.Point.LeftEdgeCenter },
	[HelpTip.Point.RightEdgeBottom] = { arrowRotation = HelpTip.ArrowRotation.Left,  relativeAnchor = "BOTTOMRIGHT",oppositePoint = HelpTip.Point.LeftEdgeBottom },

	[HelpTip.Point.BottomEdgeRight] = { arrowRotation = HelpTip.ArrowRotation.Up,	 relativeAnchor = "BOTTOMRIGHT",oppositePoint = HelpTip.Point.TopEdgeRight },
	[HelpTip.Point.BottomEdgeCenter]= { arrowRotation = HelpTip.ArrowRotation.Up,	 relativeAnchor = "BOTTOM",		oppositePoint = HelpTip.Point.TopEdgeCenter },
	[HelpTip.Point.BottomEdgeLeft]	= { arrowRotation = HelpTip.ArrowRotation.Up,	 relativeAnchor = "BOTTOMLEFT",	oppositePoint = HelpTip.Point.TopEdgeLeft },

	[HelpTip.Point.LeftEdgeBottom]	= { arrowRotation = HelpTip.ArrowRotation.Right, relativeAnchor = "BOTTOMLEFT",	oppositePoint = HelpTip.Point.RightEdgeBottom },
	[HelpTip.Point.LeftEdgeCenter]	= { arrowRotation = HelpTip.ArrowRotation.Right, relativeAnchor = "LEFT",		oppositePoint = HelpTip.Point.RightEdgeCenter },
	[HelpTip.Point.LeftEdgeTop]		= { arrowRotation = HelpTip.ArrowRotation.Right, relativeAnchor = "TOPLEFT",	oppositePoint = HelpTip.Point.RightEdgeTop },
};

HelpTip.ArrowOffsets = {
	[HelpTip.Alignment.Center]	= { 0,	 15 };
	[HelpTip.Alignment.Left]	= { 35,  15 };
	[HelpTip.Alignment.Right]	= { -35, 15 };
};

HelpTip.ArrowGlowOffsets = { 0, 4 };
HelpTip.ArrowAnimationOffsets = { 0, -25 };

HelpTip.DistanceOffsets = {
	[HelpTip.Alignment.Center]	= { 0,	 -30 };
	[HelpTip.Alignment.Left]	= { -35, -30 };
	[HelpTip.Alignment.Right]	= { 35,  -30 };
};

HelpTip.Rotations = {
	[HelpTip.ArrowRotation.Down]	= { modOffsetX = 1,  modOffsetY = -1, swapOffsets = false,	degrees = 0,	anchors = { "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" } },
	[HelpTip.ArrowRotation.Left]	= { modOffsetX = -1, modOffsetY = -1, swapOffsets = true,	degrees = 90,	anchors = { "TOPLEFT", "LEFT", "BOTTOMLEFT" } },
	[HelpTip.ArrowRotation.Up]		= { modOffsetX = 1,	 modOffsetY = 1,  swapOffsets = false,	degrees = 180,	anchors = { "TOPLEFT", "TOP", "TOPRIGHT"}  },
	[HelpTip.ArrowRotation.Right]	= { modOffsetX = 1,	 modOffsetY = -1, swapOffsets = true,	degrees = 270,	anchors = { "TOPRIGHT", "RIGHT", "BOTTOMRIGHT" } },
};

HelpTip.Buttons = {
	[HelpTip.ButtonStyle.None]			= { textWidthAdj = 0,	heightAdj = 0,	parentKey = nil },
	[HelpTip.ButtonStyle.Close]			= { textWidthAdj = -6,	heightAdj = 0,	parentKey = "CloseButton" },
	[HelpTip.ButtonStyle.Okay]			= { textWidthAdj = 0,	heightAdj = 30,	parentKey = "OkayButton", text = OKAY },
	[HelpTip.ButtonStyle.GotIt]			= { textWidthAdj = 0,	heightAdj = 30,	parentKey = "OkayButton", text = GOT_IT },
	[HelpTip.ButtonStyle.Next]			= { textWidthAdj = 0,	heightAdj = 30,	parentKey = "OkayButton", text = NEXT },
	[HelpTip.ButtonStyle.DontShowAgain] = { textWidthAdj = 0,	heightAdj = 30,	parentKey = "OkayButton", text = DONT_SHOW_AGAIN },
};

HelpTip.verticalPadding	 = 31;
HelpTip.minimumHeight	 = 72;
HelpTip.defaultTextWidth = 228;
HelpTip.width = 258;
HelpTip.halfWidth = HelpTip.width / 2;

HelpTip.supressHelpTips = {};

local function HelpTipReset(framePool, frame)
	frame:ClearAllPoints();
	frame:Hide();
	frame:Reset();
end

HelpTip.Pools = CreateFramePoolCollection()

function HelpTip:SetHelpTipsEnabled(flag, enabled)
	HelpTip.supressHelpTips[flag] = enabled or false;
end

function HelpTip:AreHelpTipsEnabled()
	return C_CVar.GetBool("HelpTipEnabled")
end

function HelpTip:Show(parent, info, relativeRegion)
	parent = _G[parent] or parent
	relativeRegion = _G[relativeRegion] or relativeRegion
	if type(parent) == "function" then
		parent = parent()
	end
	if type(parent) == "string" then
		local tip = HelpTips[parent]
		if tip then
			relativeRegion = info or _G[tip.relativeRegion] or tip.relativeRegion
			parent = _G[tip.parent] or tip.parent
			if type(parent) == "function" then
				parent = parent()
			end
			info = tip
		else
			return
		end
	end
	assert(info and info.text, "Invalid helptip info");

	if not parent then
		return false
	end

	if not self:CanShow(info) then
		if info.next then
			HelpTip:Show(info.next, info.nextUsesRelativeRegion and relativeRegion)
		end

		return false;
	end

	if self:IsShowing(parent, info.text) then
		return true;
	end

	local pool = HelpTip.Pools:GetOrCreatePool("Frame", nil, info.template or "HelpTipTemplate", HelpTipReset)
	local frame = pool:Acquire()
	frame.width = HelpTip.width + (info.extraRightMarginPadding or 0);
	frame:SetWidth(frame.width);
	frame:Init(parent, info, relativeRegion or parent);
	frame:Show();

	return true;
end

function HelpTip:CanShow(info)

	if not self:AreHelpTipsEnabled() and not info.isFlyout then
		return false;
	end

	if info.cvar then
		if info.cvarValue ~= nil then
			if C_CVar.GetBool(info.cvar) == info.cvarValue then
				return false;
			end
		else
			if info.cvarBit ~= nil then
				if C_CVar.GetBitfield(info.cvar, info.cvarBit) then
					return false
				end
			end
		end
	end

	-- priority
	if info.system and info.systemPriority then
		for frame in self.Pools:EnumerateActive() do
			if frame.info.system == info.system and frame.info.systemPriority then
				if info.systemPriority > frame.info.systemPriority then
					frame:Close();
					-- by design there can only be one such frame, no need to keep going
					break;
				else
					-- higher or equal priority is already shown
					return false;
				end
			end
		end
	end

	return true;
end

function HelpTip:ForceHideAll()
	self:SetHelpTipsEnabled("ForceHideAll", false);
	self.Pools:ReleaseAll();
	self:SetHelpTipsEnabled("ForceHideAll", true);
end

function HelpTip:HideAllSystem(system, text)
	local framesToClose = { };

	for frame in self.Pools:EnumerateActive() do
		if frame:MatchesSystem(system, text) then
			tinsert(framesToClose, frame);
		end
	end

	for i, frame in ipairs(framesToClose) do
		frame:Close();
	end	
end

function HelpTip:HideAll(parent)
	local framesToClose = { };

	for frame in self.Pools:EnumerateActive() do
		if frame:Matches(parent) then
			tinsert(framesToClose, frame);
		end
	end

	for i, frame in ipairs(framesToClose) do
		frame:Close();
	end
end

function HelpTip:Hide(parent, text)
	parent = _G[parent] or parent
	if type(parent) == "function" then
		parent = parent()
	end
	if type(parent) == "string" then
		local tip = HelpTips[parent]
		if tip then
			parent = tip.parent
			if type(parent) == "function" then
				parent = parent()
			end
			text = tip.text
		else
			return
		end
	end
	for frame in self.Pools:EnumerateActive() do
		if frame:Matches(parent, text) then
			frame:Close();
			break;
		end
	end
end

function HelpTip:IsShowing(parent, text)
	parent = _G[parent] or parent
	if type(parent) == "function" then
		parent = parent()
	end
	if type(parent) == "string" then
		local tip = HelpTips[parent]
		if tip then
			parent = tip.parent
			if type(parent) == "function" then
				parent = parent()
			end
			text = tip.text
		else
			return false
		end
	end
	for frame in self.Pools:EnumerateActive() do
		if frame:Matches(parent, text) then
			return true;
		end
	end
	return false;
end

function HelpTip:IsShowingAny(parent)
	for frame in self.Pools:EnumerateActive() do
		if frame:Matches(parent) then
			return true;
		end
	end
	return false;
end

function HelpTip:IsShowingAnyInSystem(system)
	for frame in self.Pools:EnumerateActive() do
		if frame.info.system == system then
			return true;
		end
	end
	return false;
end

function HelpTip:Acknowledge(parent, text)
	parent = _G[parent] or parent
	if type(parent) == "function" then
		parent = parent()
	end
	if type(parent) == "string" then
		local tip = HelpTips[parent]
		if tip then
			parent = tip.parent
			if type(parent) == "function" then
				parent = parent()
			end
			text = tip.text
		else
			return
		end
	end
	for frame in self.Pools:EnumerateActive() do
		if frame:Matches(parent, text) then
			frame:Acknowledge();
			break;
		end
	end
end

function HelpTip:AcknowledgeSystem(system, text)
	for frame in self.Pools:EnumerateActive() do
		if frame:MatchesSystem(system, text) then
			frame:Acknowledge();
		end
	end
end

function HelpTip:Release(helpTip)
	self.Pools:Release(helpTip);
end

function HelpTip:IsPointVertical(point)
	return point <= HelpTip.Point.BottomEdgeRight;
end

function HelpTip:ResetHighlight(highlight)
	highlight:ClearAllPoints()
	highlight.InputBlocker:Hide()
	highlight.Circle.Anim:Stop()
	highlight.Circle:Hide()
	highlight.Box.Anim:Stop()
	highlight.Box:Hide()
	highlight:Hide()
end

HelpTipTemplateMixin = CreateFromMixins("NineSlicePanelMixin");

local function TransformOffsetsForRotation(offsets, rotationInfo)
	local offsetX = offsets[1];
	local offsetY = offsets[2];
	if rotationInfo.swapOffsets then
		offsetX, offsetY = offsetY, offsetX;
	end
	offsetX = offsetX * rotationInfo.modOffsetX;
	offsetY = offsetY * rotationInfo.modOffsetY;
	return offsetX, offsetY;
end

function HelpTipTemplateMixin:OnLoad()
	NineSlicePanelMixin.OnLoad(self)
	self.Arrow.Arrow:ClearAllPoints();
	self.Arrow.Arrow:SetPoint("CENTER");
	self.Arrow.Animation:ClearAllPoints()
	self.Arrow.Animation:SetPoint("CENTER")
	self.Arrow.Animation2:ClearAllPoints()
	self.Arrow.Animation2:SetPoint("CENTER")
	self.Arrow.Glow:ClearAllPoints();
	self.acknowledged = false;
end

function HelpTipTemplateMixin:OnShow()
	self:RegisterEvent("UI_SCALE_CHANGED");
	self:RegisterEvent("DISPLAY_SIZE_CHANGED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	
end

function HelpTipTemplateMixin:OnHide()
	self:UnregisterEvent("UI_SCALE_CHANGED");
	self:UnregisterEvent("DISPLAY_SIZE_CHANGED");
	C_Hook:Unregister(self)

	local info = self.info;
	local relativeRegion = info.nextUsesRelativeRegion and self.relativeRegion;
	if not self.acknowledged and info.acknowledgeOnHide then
		self:HandleAcknowledge();
	end
	if info.onHideCallback then
		info.onHideCallback(self.acknowledged, info.callbackArg);
	end

	local acknowledged = self.acknowledged

	if acknowledged and info.onAcknowledgeCallback then
		info.onAcknowledgeCallback(info.callbackArg);
	end

	if not acknowledged and info.dontReleaseUntilAcknowledged then
		return
	end

	HelpTip:Release(self);

	if acknowledged and info.next then
		HelpTip:Show(info.next, relativeRegion)
	end

end

function HelpTipTemplateMixin:OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		self:Close()
		return
	end
	self:Layout();
end

function HelpTipTemplateMixin:Close()
	self.Glow:Hide()
	HelpTip._glows:Release(self.TargetGlow)
	self.TargetGlow = nil
	self:Hide();
end

function HelpTipTemplateMixin:OnUpdate()
	local rx, ry = self.relativeRegion:GetCenter();
	local targetPoint = self.info.targetPoint;
	local targetAlignment = self.info.alignment;

	if self.info.autoHorizontalSlide then
		-- check right edge first
		local rightEdge = UIParent:GetRight();
		local canFitOnRight = rx + self.width + HelpTip.ArrowOffsets[HelpTip.Alignment.Right][1] < rightEdge;
		if not canFitOnRight then
			if rx + HelpTip.halfWidth < rightEdge then
				targetAlignment = HelpTip.Alignment.Center;
			else
				targetAlignment = HelpTip.Alignment.Right;
			end
		else
			-- left edge
			local leftEdge = UIParent:GetLeft();
			local canFitOnLeft = rx - self.width + HelpTip.ArrowOffsets[HelpTip.Alignment.Left][1] > leftEdge;
			if not canFitOnLeft then
				if rx - HelpTip.halfWidth > leftEdge then
					targetAlignment = HelpTip.Alignment.Center;
				else
					targetAlignment = HelpTip.Alignment.Left;
				end
			end
		end
	end

	if self.info.autoEdgeFlipping then
		local ux, uy = UIParent:GetCenter();
		local useMin;
		if HelpTip:IsPointVertical(targetPoint) then
			useMin = ry <= uy;
		else
			useMin = rx <= ux;
		end
		if useMin then
			targetPoint = min(self.flippedTargetPoint, targetPoint);
		else
			targetPoint = max(self.flippedTargetPoint, targetPoint);
		end
	end

	self:AnchorAndRotate(targetPoint, targetAlignment);
end

function HelpTipTemplateMixin:Init(parent, info, relativeRegion)
	parent = _G[parent] or parent
	relativeRegion = _G[relativeRegion] or relativeRegion
	self:SetParent(parent);
	self:SetFrameLevel(info.level or 1000)

	self:SetFrameStrata(info.strata or parent:GetFrameStrata())
	self.info = info;
	self.relativeRegion = relativeRegion;

	if info.autoEdgeFlipping then
		local targetPoint = self:GetTargetPoint();
		local pointInfo = HelpTip.PointInfo[targetPoint];
		self.flippedTargetPoint = pointInfo.oppositePoint;
		self:SetScript("OnUpdate", function() self:OnUpdate(); end);
	end
	if info.autoHorizontalSlide then
		self:SetScript("OnUpdate", function() self:OnUpdate(); end);
	end

	self:EnableMouse(info.buttonStyle and info.buttonStyle ~= 1)

	if info.animatePointer then
		self.Arrow.Animation:Show()
		self.Arrow.Animation2:Show()
	else
		self.Arrow.Animation:Hide()
		self.Arrow.Animation2:Hide()
	end

	if info.highlightSelf then
		self.Glow:Show()
		self.Glow.Anim:Play()
	else
		self.Glow:Hide()
		self.Glow.Anim:Stop()
	end

    if info.highlightTarget then
		local target = self.relativeRegion or parent
		if self.TargetGlow then
			HelpTip._glows:Release(self.TargetGlow)
			self.TargetGlow = nil
		end
		local highlight = HelpTip._glows:Acquire()
		self.TargetGlow = highlight
		highlight:SetParent(parent)
		highlight:SetFrameLevel(100)
		if info.highlightTarget == HelpTip.TargetType.Box then
			local offset = info.highlightOffset or {-8, 8, 8, -8}
			local left, right, top, bottom = offset[1], offset[2], offset[3], offset[4]
			highlight:SetPoint("TOPLEFT", target, "TOPLEFT", left, top)
			highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", right, bottom)
			highlight:Show()
			highlight.Box:Show()
			highlight.Box.Anim:Play()

			if info.highlightBlockInput then
				highlight.InputBlocker:Show()
			end
		elseif info.highlightTarget == HelpTip.TargetType.Circle then
			local offset = info.highlightOffset or {-2, 2, 2, -2}
			local left, right, top, bottom = offset[1], offset[2], offset[3], offset[4]
			highlight:SetPoint("TOPLEFT", target, "TOPLEFT", left, top)
			highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", right, bottom)
			highlight:Show()
			highlight.Circle:Show()
			highlight.Circle.Anim:Play()
		end
    end

	if info.onInitCallback then
		info.onInitCallback(self)
	end

	self:AnchorAndRotate(nil, nil, info.animatePointer);
	self:Layout();
end

function HelpTipTemplateMixin:GetTargetPoint()
	return self.info.targetPoint or HelpTip.Point.BottomEdgeCenter;
end

function HelpTipTemplateMixin:GetAlignment()
	return self.info.alignment or HelpTip.Alignment.Center;
end

function HelpTipTemplateMixin:GetButtonInfo()
	local buttonStyle = self.info.buttonStyle or HelpTip.ButtonStyle.None;
	return HelpTip.Buttons[buttonStyle];
end

function HelpTipTemplateMixin:AnchorAndRotate(overrideTargetPoint, overrideAlignment, shouldOffsetY)
	shouldOffsetY = shouldOffsetY or self.Arrow.Animation:IsVisible()
	local baseTargetPoint = self:GetTargetPoint();
	local targetPoint = overrideTargetPoint or baseTargetPoint;
	local alignment = overrideAlignment or self:GetAlignment();
	if targetPoint == self.appliedTargetPoint and alignment == self.appliedAlignment then
		return;
	end

	local pointInfo = HelpTip.PointInfo[targetPoint];
	local rotationInfo = HelpTip.Rotations[pointInfo.arrowRotation];
	-- anchor
	local arrowAnchor = rotationInfo.anchors[alignment];
	local distX, distY = unpack(HelpTip.DistanceOffsets[alignment])
	if shouldOffsetY then
		distY = distY - 25
	end
	local offsetX, offsetY = TransformOffsetsForRotation({ distX, distY }, rotationInfo);
	local baseOffsetX = self.info.offsetX or 0;
	local baseOffsetY = self.info.offsetY or 0;
	if overrideTargetPoint and overrideTargetPoint ~= baseTargetPoint then
		if HelpTip:IsPointVertical(targetPoint) then
			baseOffsetY = -baseOffsetY;
		else
			baseOffsetX = -baseOffsetX;
		end
	end
	offsetX = offsetX + baseOffsetX;
	offsetY = offsetY + baseOffsetY;
	self:ClearAllPoints();
	self:SetPoint(arrowAnchor, self.relativeRegion, pointInfo.relativeAnchor, offsetX, offsetY);
	-- arrow
	if self.info.hideArrow then
		self.Arrow:Hide();
	else
		self.Arrow:Show();
		self:RotateArrow(pointInfo.arrowRotation);
		self:AnchorArrow(rotationInfo, alignment);
	end
	self.appliedAlignment = alignment;
	self.appliedTargetPoint = targetPoint;
end

function HelpTipTemplateMixin:Layout()
	local targetPoint = self:GetTargetPoint();
	local pointInfo = HelpTip.PointInfo[targetPoint];
	local buttonInfo = self:GetButtonInfo();

	-- starting defaults
	local textOffsetX = 15;
	local textOffsetY = 1;
	local textWidth = HelpTip.defaultTextWidth;
	local height = HelpTip.verticalPadding;
	-- button
	textWidth = textWidth + buttonInfo.textWidthAdj;
	textOffsetY = textOffsetY + buttonInfo.heightAdj / 2;
	height = height + buttonInfo.heightAdj;
	if buttonInfo.parentKey then
		self[buttonInfo.parentKey]:Show();

		if buttonInfo.text then
			self[buttonInfo.parentKey]:SetText(buttonInfo.text);
		end
	end
	-- set height based on the text
	self:ApplyText();
	self.TextFrame.Text:SetWidth(textWidth);
	self.TextFrame.Text:SetPoint("LEFT", textOffsetX, textOffsetY);
	height = height + self.TextFrame.Text:GetHeight();
	if pointInfo.arrowRotation == HelpTip.ArrowRotation.Left or pointInfo.arrowRotation == HelpTip.ArrowRotation.Right then
		height = max(height, HelpTip.minimumHeight);
	end
	self:SetHeight(height);
end

function HelpTipTemplateMixin:ApplyText()
	local info = self.info;

	self.TextFrame.Text:SetText(info.text);

	local color = info.textColor or HIGHLIGHT_FONT_COLOR;
	self.TextFrame.Text:SetTextColor(color.r, color.g, color.b);
	local justifyH = info.textJustifyH;
	if not justifyH then
		if self.TextFrame.Text:GetStringHeight() < 13 then
			justifyH = "CENTER";
		else
			justifyH = "LEFT";
		end
	end
	self.TextFrame.Text:SetJustifyH(justifyH);
end

function HelpTipTemplateMixin:AnchorArrow(rotationInfo, alignment)
	local arrowAnchor = rotationInfo.anchors[alignment];
	local offsetX, offsetY = TransformOffsetsForRotation(HelpTip.ArrowOffsets[alignment], rotationInfo);
	self.Arrow:ClearAllPoints();
	self.Arrow:SetPoint("CENTER", self, arrowAnchor, offsetX, offsetY);

	self.Arrow.Animation:ClearAllPoints()
	self.Arrow.Animation:SetPoint("CENTER")

	self.Arrow.Animation2:ClearAllPoints()
	self.Arrow.Animation2:SetPoint("CENTER")
end

function HelpTipTemplateMixin:RotateArrow(rotation)
	if self.Arrow.rotation == rotation then
		return;
	end

	local rotationInfo = HelpTip.Rotations[rotation];
	SetClampedTextureRotation(self.Arrow.Arrow, rotationInfo.degrees);
	SetClampedTextureRotation(self.Arrow.Glow, rotationInfo.degrees);

	SetClampedTextureRotation(self.Arrow.Animation.Glow, rotationInfo.degrees);
	SetClampedTextureRotation(self.Arrow.Animation2.Glow, rotationInfo.degrees);

	local offsetX, offsetY = TransformOffsetsForRotation(HelpTip.ArrowGlowOffsets, rotationInfo);
	local animOffsetX, animOffsetY = TransformOffsetsForRotation(HelpTip.ArrowAnimationOffsets, rotationInfo);
	self.Arrow.Glow:SetPoint("CENTER", self.Arrow.Arrow, "CENTER", offsetX, offsetY);

	self.Arrow.Animation:SetPoint("CENTER", self.Arrow.Arrow, "CENTER", animOffsetX, animOffsetY);
	self.Arrow.Animation2:SetPoint("CENTER", self.Arrow.Arrow, "CENTER", animOffsetX, animOffsetY);

	self.Arrow.rotation = rotation;

	local translation = self.Arrow.Animation.Anim.Translation
	local translation2 = self.Arrow.Animation2.Anim.Translation
	if rotation == 1 then
		translation:SetOffset(0, -25)
		translation2:SetOffset(0, -25)
	elseif rotation == 2 then
		translation:SetOffset(-25, 0)
		translation2:SetOffset(-25, 0)
	elseif rotation == 3 then
		translation:SetOffset(0, 25)
		translation2:SetOffset(0, 25)
	elseif rotation == 4 then
		translation:SetOffset(25, 0)
		translation2:SetOffset(25, 0)
	end
end

function HelpTipTemplateMixin:Acknowledge()
	self:HandleAcknowledge();
	self:Close();
end

function HelpTipTemplateMixin:HandleAcknowledge()
	local info = self.info;
	if info.cvar then
		if info.cvarValue ~= nil then
			C_CVar.Set(info.cvar, info.cvarValue);
		elseif info.cvarBit ~= nil then
			C_CVar.SetBitfield(info.cvar, info.cvarBit, true)
		end
	end
	self.acknowledged = true;
end

function HelpTipTemplateMixin:Reset()
	self.info = nil;
	self.relativeRegion = nil;
	self.acknowledged = false;
	self.CloseButton:Hide();
	self.OkayButton:Hide();
	-- flippity flip settings
	self.appliedTargetPoint = nil;
	self.flippedTargetPoint = nil;
	self.appliedAlignment = nil;
	self:SetScript("OnUpdate", nil);
end

function HelpTipTemplateMixin:Matches(parent, text)
	local textMatched = not text or self.info and self.info.text == text;
	return textMatched and (self:GetParent() == _G[parent] or self:GetParent() == parent);
end

function HelpTipTemplateMixin:MatchesSystem(system, text)
	local textMatched = not text or self.info.text == text;
	return textMatched and self.info.system == system;
end

--
-- Meta Tutorial Popup Functions
--

TutorialPopupContainerMixin = {}

function TutorialPopupContainerMixin:ResetCVar(name)
	if not name then return end
    local popup = self[name]
    if not popup then return end

    if popup.cvar then
        if popup.cvarValue ~= nil then
            C_CVar.Set(popup.cvar, false)
        elseif popup.cvarBit ~= nil then
            C_CVar.SetBitfield(popup.cvar, popup.cvarBit, false)
        end
    end
end

function TutorialPopupContainerMixin:ResetAllCVars()
	for k, v in pairs(self) do
		if type(v) == "table" and v.cvar then
			C_CVar.Set(v.cvar, "0")
		end
	end
end

HelpTips = CreateFromMixins("TutorialPopupContainerMixin")

function HelpTips:IsTipAcknowleged(tip)
	local cvar = self[tip] and self[tip].cvar
	if not cvar then return false end

	if self[tip].cvarValue ~= nil then
		return C_CVar.GetBool(cvar) == self[tip].cvarValue
	end

	if self[tip].cvarBit ~= nil then
		return C_CVar.GetBitfield(cvar, self[tip].cvarBit)
	end
	
	return false
end

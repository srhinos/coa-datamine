--[[-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------]]--

local round = function (num) return math.floor(num + .5); end

function HybridScrollFrame_OnLoad (self)
	self.hybridScroll = true
	self.isHorizontal = false

	self:EnableMouse(true);
end

function HybridScrollFrame_IsPartOfHybridScroll(self)
	local frame = self
	repeat
		if frame.hybridScroll then return true end
		frame = frame:GetParent()
	until frame == nil
	return false
end

function HybridScrollFrame_OnValueChanged (self, value)
	HybridScrollFrame_SetOffset(self, value);
	HybridScrollFrame_UpdateButtonStates(self, value);
end
	
function HybridScrollFrame_UpdateButtonStates(self, currValue)
	if ( not currValue ) then
		currValue = self.scrollBar:GetValue();
	end

	if self.scrollUp then
		self.scrollUp:Enable();
	end

	if self.scrollDown then
		self.scrollDown:Enable();
	end

	local minVal, maxVal = self.scrollBar:GetMinMaxValues();
	if ( currValue >= maxVal ) then
		self.scrollBar:GetThumbTexture():Show();
		if ( self.scrollDown ) then
			self.scrollDown:Disable()
		end
	end
	if ( currValue <= minVal ) then
		self.scrollBar:GetThumbTexture():Show();
		if ( self.scrollUp ) then
			self.scrollUp:Disable();
		end
	end

	if currValue > maxVal then
		self.scrollBar:SetValue(maxVal);
	elseif currValue < minVal then
		self.scrollBar:SetValue(minVal);
	end
end

function HybridScrollFrame_OnMouseWheel (self, delta, stepSize)
	if ( not self.scrollBar:IsVisible() ) then
		return;
	end
	
	local minVal, maxVal = 0, self.range;
	stepSize = stepSize or self.stepSize or self.buttonHeight;
	if ( delta == 1 ) then
		self.scrollBar:SetValue(max(minVal, self.scrollBar:GetValue() - stepSize));
	else
		self.scrollBar:SetValue(min(maxVal, self.scrollBar:GetValue() + stepSize));
	end
end

function HybridScrollFrameScrollButton_OnUpdate (self, elapsed)
	self.timeSinceLast = self.timeSinceLast + elapsed;
	if ( self.timeSinceLast >= ( self.updateInterval or 0.08 ) ) then
		if ( not IsMouseButtonDown("LeftButton") ) then
			self:SetScript("OnUpdate", nil);
		elseif ( self:IsMouseOver() ) then
			local parent = self.parent or self:GetParent():GetParent();
			HybridScrollFrame_OnMouseWheel (parent, self.direction, (self.stepSize or parent.buttonHeight/3));
			self.timeSinceLast = 0;
		end
	end
end

function HybridScrollFrameScrollButton_OnClick (self, button, down)
	local parent = self
	repeat
		parent = parent:GetParent()
	until parent.scrollBar ~= nil
	
	if ( down ) then
		self.timeSinceLast = (self.timeToStart or -0.2);
		self:SetScript("OnUpdate", HybridScrollFrameScrollButton_OnUpdate);
		HybridScrollFrame_OnMouseWheel (parent, self.direction);
		PlaySound("UChatScrollButton");
	else
		self:SetScript("OnUpdate", nil);
	end
end

function HybridScrollFrame_Update (self, totalHeight, displayedHeight)
	local expandedIndex, expandedHeight = HybridScrollFrame_GetExpandedButton(self)

	if expandedIndex then
		local lastDisplayedOffset = 0
		for i = #self.buttons, 1 do
			if self.buttons[i]:IsVisible() then
				lastDisplayedOffset = i
				break
			end
		end
		local extraHeight = expandedHeight - self.buttonHeight
		if lastDisplayedOffset >= expandedIndex and HybridScrollFrame_GetOffset(self) <= expandedIndex then
			displayedHeight = displayedHeight + extraHeight
		end
		totalHeight = totalHeight + extraHeight
	end

	local range = floor(totalHeight - self:GetHeight() + 0.5);
	if ( range > 0 and self.scrollBar ) then
		local minVal, maxVal = self.scrollBar:GetMinMaxValues();
		if ( math.floor(self.scrollBar:GetValue()) >= math.floor(maxVal) ) then
			self.scrollBar:SetMinMaxValues(0, range);
			if ( range < maxVal ) then
				if ( math.floor(self.scrollBar:GetValue()) ~= math.floor(range) ) then
					self.scrollBar:SetValue(range, true);
				else
					HybridScrollFrame_SetOffset(self, range); -- If we've scrolled to the bottom, we need to recalculate the offset.
				end
			end
		else
			self.scrollBar:SetMinMaxValues(0, range)
		end
		self.scrollBar:Enable();
		HybridScrollFrame_UpdateButtonStates(self);
		self.scrollBar:Show();

		if self.scrollUp then
			self.scrollUp:Show();
		end

		if self.scrollDown then
			self.scrollDown:Show();
		end
	elseif ( self.scrollBar ) then
		range = 0
		self.scrollBar:SetValue(0);
		self.scrollBar:SetMinMaxValues(0, range)
		if ( self.scrollBar.doNotHide ) then
			self.scrollBar:Disable();
			if self.scrollUp then
				self.scrollUp:Disable();
			end

			if self.scrollDown then
				self.scrollDown:Disable();
			end
			if not self.scrollBar.doNotHideThumb then
				self.scrollBar:GetThumbTexture():Hide();
			end
		else
			self.scrollBar:Hide();

			if self.scrollUp then
				self.scrollUp:Hide();
			end

			if self.scrollDown then
				self.scrollDown:Hide();
			end
		end
	end

	self.range = range;
	self.scrollChild:SetHeight(displayedHeight);
	self:UpdateScrollChildRect();
end

function HybridScrollFrame_GetOffset (self)
	return math.floor(self.offset or 0), (self.offset or 0);
end

function HybridScrollFrameScrollChild_OnLoad (self)
	self:GetParent().scrollChild = self;
end

function HybridScrollFrame_ExpandButton (self, index, height)
	self.largeButtonIndex = index;
	self.largeButtonHeight = round(height)
	HybridScrollFrame_SetOffset(self, self.scrollBar:GetValue());
end

function HybridScrollFrame_CollapseButton (self)
	self.largeButtonIndex = nil;
	self.largeButtonHeight = nil;
end

function HybridScrollFrame_GetExpandedButton(self)
	return self.largeButtonIndex, self.largeButtonHeight
end

function HybridScrollFrame_SetOffset (self, offset)
	local buttons = self.buttons
	local buttonHeight = self.buttonHeight;
	local element, overflow;

	local scrollHeight = 0;

	local largeButtonTop = self.largeButtonIndex and (self.largeButtonIndex - 1) * buttonHeight
	if ( self.dynamic ) then --This is for frames where buttons will have different heights
		if ( offset < buttonHeight ) then
			-- a little optimization
			element = 0;
			scrollHeight = offset;
		else
			element, scrollHeight = self.dynamic(offset);
		end
	elseif ( largeButtonTop and offset >= largeButtonTop ) then
		local largeButtonHeight = self.largeButtonHeight;
		-- Initial offset...
		element = largeButtonTop / buttonHeight;

		if ( offset >= (largeButtonTop + largeButtonHeight) ) then
			element = element + 1;

			local leftovers = (offset - (largeButtonTop + largeButtonHeight) );

			element = element + ( leftovers / buttonHeight );
			overflow = element - math.floor(element);
			scrollHeight = overflow * buttonHeight;
		else
			scrollHeight = math.abs(offset - largeButtonTop);
		end
	else
		element = offset / buttonHeight;
		overflow = element - math.floor(element);
		scrollHeight = overflow * buttonHeight;
	end

	-- this used to infinite loop, check back if it does
	if (math.floor(self.offset or 0) ~= math.floor(element) and self.update) then
		self.offset = element;
		self:update();
	else
		self.offset = element;
	end

	if self.isHorizontal then
		self:SetHorizontalScroll(scrollHeight)
	else
		self:SetVerticalScroll(scrollHeight);
	end
end

function HybridScrollFrame_CreateButtons (self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
	local scrollChild = self.scrollChild;
	local button, buttonLength, buttons, numButtons;
	
	local buttonName = self:GetName() .. "Button";
	
	initialPoint = initialPoint or "TOPLEFT";
	initialRelative = initialRelative or "TOPLEFT";
	point = point or "TOPLEFT";
	relativePoint = relativePoint or "BOTTOMLEFT";
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;
	
	if ( self.buttons ) then
		buttons = self.buttons;
		buttonLength = self.buttonHeight or (self.isHorizontal and buttons[1]:GetWidth() or buttons[1]:GetHeight());
	else
		button = CreateFrame("BUTTON", buttonName .. 1, scrollChild, buttonTemplate);
		buttonLength = self.isHorizontal and button:GetWidth() or button:GetHeight();
		button:SetPoint(initialPoint, scrollChild, initialRelative, initialOffsetX, initialOffsetY);
		buttons = {}
		tinsert(buttons, button);
	end
	
	local inactiveButtons = self.inactiveButtons or {}
	
	self.buttonHeight = round(buttonLength);
	
	if self.isHorizontal then
		numButtons = math.ceil(self:GetWidth() / buttonLength) + 1;
	else
		numButtons = math.ceil(self:GetHeight() / buttonLength) + 1;
	end

	local currentButtonCount = #buttons;
	if numButtons < currentButtonCount then
		for i = currentButtonCount, numButtons + 1, -1 do
			buttons[i]:Hide();
			tinsert(inactiveButtons, buttons[i])
			tremove(buttons, i)
		end
	else
		for i = currentButtonCount + 1, numButtons do
			if inactiveButtons[1] then
				button = inactiveButtons[1]
				tremove(inactiveButtons, 1)
			else
				button = CreateFrame("BUTTON", buttonName .. i, scrollChild, buttonTemplate);
			end
			button:SetPoint(point, buttons[i-1], relativePoint, offsetX, offsetY);
			tinsert(buttons, button);
		end
	end
	local length = numButtons * buttonLength;
	
	if self.isHorizontal then
		scrollChild:SetWidth(length)
		scrollChild:SetHeight(self:GetHeight());
		self:SetHorizontalScroll(0);
	else
		scrollChild:SetWidth(self:GetWidth())
		scrollChild:SetHeight(length);
		self:SetVerticalScroll(0);
	end

	self:UpdateScrollChildRect();
	
	self.buttons = buttons;
	local scrollBar = self.scrollBar;	
	scrollBar:SetMinMaxValues(0, length)
	scrollBar:SetValueStep(.005);
	scrollBar:SetValue(0);
end


function HybridScrollFrame_GetButtons (self)
	return self.buttons;
end

function HybridScrollFrame_SetDoNotHideScrollBar (self, doNotHide)
	if not self.scrollBar or self.scrollBar.doNotHide == doNotHide then
		return;
	end

	self.scrollBar.doNotHide = doNotHide;
end

function HybridScrollFrame_SetDoNotHideScrollThumb(self, doNotHide)
	if not self.scrollBar or self.scrollBar.doNotHideThumb == doNotHide then
		return
	end

	self.scrollBar.doNotHideThumb = doNotHide
	if self.buttonHeight then
		HybridScrollFrame_Update(self, self.totalHeight or 0, self.scrollChild:GetHeight())
	end
end

local function DefaultGetHeightFunc(self, index)
	local expandedIndex, expandedHeight = HybridScrollFrame_GetExpandedButton(self)
	if expandedIndex and index == expandedIndex then
		return expandedHeight
	end
	return self.buttonHeight
end

function HybridScrollFrame_ScrollToIndex(self, index, getHeightFunc)
    local totalHeight = 0
    local scrollFrameHeight = self.isHorizontal and self:GetWidth() or self:GetHeight()
    getHeightFunc = getHeightFunc or DefaultGetHeightFunc
    local minOffset, maxOffset = self.scrollBar:GetMinMaxValues()
    local currentOffset = self.scrollBar:GetValue()

    for i = 1, index do
        local entryHeight = getHeightFunc(self, i)
        totalHeight = totalHeight + entryHeight

        if i == index then
            local offset = (totalHeight - scrollFrameHeight) + entryHeight

            -- Ensure the entire button height is visible within the scroll frame
            if offset < 0 then
                offset = 0
            end

            -- Ensure the offset does not exceed the maximum offset
            if offset > maxOffset then
                offset = maxOffset
            end

            -- Only adjust the offset if the current offset is not adequate to show the button
            if currentOffset + scrollFrameHeight < totalHeight or currentOffset > totalHeight - entryHeight then
                self.scrollBar:SetValue(offset)
            end
            break
        end
    end
end
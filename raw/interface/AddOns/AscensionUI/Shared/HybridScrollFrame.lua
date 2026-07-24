function HybridScroll()
	local self = {
		Parent = UIParent, -- Parent frame
		ParentName = "",
		Name = "HybridScroll",
		Width = 256,
		Height = 256,
		items = {},
		doNotHide = true,
		point = {"CENTER", 0, 0},
		scrollup_point = {0, 0},
		scrolldown_point = {0, 0},
	}

	local function CreateContent() -- basically an xml part. Creates content frame, scroll frame, scroll bar.
		self.Content = CreateFrame("FRAME", self.ParentName.."."..self.Name..".Content", self.Parent)
		self.Content:SetSize(self.Width, self.Height)
		self.Content:SetPoint(unpack(self.point))

		self.Scroll = CreateFrame("ScrollFrame", self.ParentName.."."..self.Name..".Scroll", self.Parent )
		self.Scroll:SetSize(self.Width, self.Height)
		self.Scroll:SetPoint(unpack(self.point))
		self.Scroll:EnableMouseWheel(true)
		--self.Scroll:SetBackdrop(GameTooltip:GetBackdrop())
		self.Scroll.update = function() self.RefreshLayout(); end
		self.Scroll.scrollChild = self.Content
		self.Scroll:SetScript("OnMouseWheel", HybridScrollFrame_OnMouseWheel)

		self.Scroll.scrollBar = CreateFrame("Slider", self.ParentName.."."..self.Name..".Scroll.scrollBar", self.Scroll, "UIPanelScrollBarTemplate") 
		self.Scroll.scrollBar:SetPoint("TOPLEFT", self.Scroll, "TOPRIGHT", unpack(self.scrollup_point))    
		self.Scroll.scrollBar:SetPoint("BOTTOMLEFT", self.Scroll, "BOTTOMRIGHT", unpack(self.scrolldown_point)) 
		self.Scroll.scrollBar.doNotHide = self.doNotHide
		self.Scroll.scrollBar:SetWidth(16) 
		self.Scroll.scrollBar:SetScript("OnValueChanged", function(self, value) 
			HybridScrollFrame_OnValueChanged(self:GetParent(), value)
		end) 
		self.Scroll:SetScrollChild(self.Content)

		self.Scroll.scrollBar.thumbTexture = _G[self.ParentName.."."..self.Name..".Scroll.scrollBarThumbTexture"]

		self.Scroll.scrollDown = _G[self.ParentName.."."..self.Name..".Scroll.scrollBarScrollDownButton"]
		self.Scroll.scrollDown:Disable();
		self.Scroll.scrollDown:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
		self.Scroll.scrollDown.direction = -1;
		self.Scroll.scrollDown:SetScript("OnClick", HybridScrollFrameScrollButton_OnClick)
		self.Scroll.scrollDown.parent = self.Scroll

		self.Scroll.scrollUp = _G[self.ParentName.."."..self.Name..".Scroll.scrollBarScrollUpButton"]
		self.Scroll.scrollUp:Disable();
		self.Scroll.scrollUp:RegisterForClicks("LeftButtonUp", "LeftButtonDown");
		self.Scroll.scrollUp.direction = 1;
		self.Scroll.scrollUp:SetScript("OnClick", HybridScrollFrameScrollButton_OnClick)
		self.Scroll.scrollUp.parent = self.Scroll
	end

	function self.CreateButton(self, i) -- function to create button
		-- Needs to be set for each scroll
	end

	function self.LoadData()
	    local data = {};
	    -- Needs to be set for each scroll
	    self.items = data
	end

	function self.SetUpButton(button, item)
		-- Needs to be set for each scroll
	end

	function self:Show()
		if (self.Content) then
			self.Content:Show()
			self.Scroll:Show()
		end
	end

	function self:Hide()
		if (self.Content) then
			self.Content:Hide()
			self.Scroll:Hide()
		end
	end

	function self.RefreshLayout()
	    local offset = HybridScrollFrame_GetOffset(self.Scroll);
	    local buttons = self.Scroll.buttons
		local buttonHeight = self.Scroll.buttonHeight

		local expandedIndex, expandedHeight = HybridScrollFrame_GetExpandedButton(self.Scroll)

	    for buttonIndex = 1, #buttons do
	        local button = buttons[buttonIndex];
	        local itemIndex = buttonIndex + offset;

	        if itemIndex <= #self.items then
	            local item = self.items[itemIndex]
	            button.itemIndex = itemIndex
	            self.SetUpButton(button, item, itemIndex)

				if expandedIndex == itemIndex then
					button:SetHeight(expandedHeight)
				else
					if button:GetHeight() ~= buttonHeight then
						button:SetHeight(buttonHeight)
					end
				end

	            button:Show();
	        else
	            button:Hide();
	        end
	    end

	    local totalHeight = #self.items * buttonHeight
	    local shownHeight = #buttons * buttonHeight

	    HybridScrollFrame_Update(self.Scroll, totalHeight, shownHeight);
	end

	function self.DisplaySearchResults(searchResults)
		self.items = searchResults
		self.RefreshLayout()
	end

	function self.CreateButtons (contentFrame) -- basically an init function. Call when settings are there
		if self.Scroll.buttons then
			self.numButtons = math.ceil(contentFrame:GetHeight()/self.Scroll.buttonHeight)+1

			for i = (#self.Scroll.buttons+1), self.numButtons do
				local btn = self.CreateButton(contentFrame, i)
				table.insert(self.Scroll.buttons, btn)
			end
			return
		end

		local InitButton = self.CreateButton(contentFrame, 1)

		self.Scroll.buttons = {}
		self.Scroll.buttonHeight = InitButton:GetHeight()

	    local buttons = self.Scroll.buttons
		local buttonHeight = self.Scroll.buttonHeight

		self.numButtons = math.ceil(contentFrame:GetHeight()/buttonHeight)+1

		table.insert(buttons, InitButton)

		for i = (#buttons+1), self.numButtons do
			local btn = self.CreateButton(contentFrame, i)
			table.insert(buttons, btn)
		end

		-- inital settings for scroll
		self.Scroll.stepSize = buttonHeight
		self.Scroll.scrollBar:SetValueStep(.005) 
		self.Content:SetSize(self.Width, buttonHeight*self.numButtons)
		self.Scroll.scrollBar:SetMinMaxValues(0, buttonHeight*self.numButtons) 
		self.Scroll.scrollBar:SetValue(0) 

		self.RefreshLayout()
	end

	function self.Init()
		self.LoadData()
		CreateContent()

		self.CreateButtons(self.Content)
		self.initialized = true
	end

	return self
end

--print(string.format("|cFFFFFF00Loaded Hybrid Scroll v%.2f|r", version))

-- Example: 
--[[local UIParentHybridScroll = HybridScroll()

UIParentHybridScroll.Parent = UIParent
UIParentHybridScroll.ParentName = UIParentHybridScroll.Parent:GetName()
UIParentHybridScroll.Name = "UIParentHybridScroll"
UIParentHybridScroll.Width = 256
UIParentHybridScroll.Height = 512

function UIParentHybridScroll.LoadData()
    local listModel = {};

    for index = 1, 50 do -- listModel[index].text, listModel[index].icon
        table.insert(listModel, {
            text = string.format("List Item %1$d", index),
                30 + (index % 30)),
        });
    end

    return listModel; -- this will go to UIParentHybridScroll.items
end

function UIParentHybridScroll.SetUpButton(button, item) -- just change icon/text
	-- Needs to be set for each scroll
	button.SpecIcon.Icon:SetTexture(item.icon or nil);
	button.Text:SetText(item.text or "");
end

function UIParentHybridScroll.CreateButton(self, i) -- Button can be anything. With any elements. Just follow the logic of names.
	local parent = self
	local parentName = parent:GetName()

    BuildButton = CreateFrame("Button", parentName.."Button"..i, parent)
    if (i == 1) then
        BuildButton:SetPoint("TOP", 0, -3)
    else
        BuildButton:SetPoint("BOTTOM", _G[parentName.."Button"..(i-1)], 0, -50)
    end

    BuildButton:SetSize(210, 54)

    BuildButton.Border = BuildButton:CreateTexture(parentName.."Button"..i..".Border", "BACKGROUND")
    BuildButton.Border:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\2\\SpecButton")
    BuildButton.Border:SetSize(256,64)
    BuildButton.Border:SetPoint("CENTER", 0, 0)

    BuildButton.Text = BuildButton:CreateFontString(parentName.."Button"..i..".Text")
    BuildButton.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    BuildButton.Text:SetFontObject(GameFontHighlight)
    BuildButton.Text:SetPoint("CENTER", 10, 10)
    BuildButton.Text:SetShadowOffset(1,-1)
    BuildButton.Text:SetSize(140, 16)
    BuildButton.Text:SetJustifyH("LEFT")

    BuildButton.SpecIcon = CreateFrame("BUTTON", parentName.."Button"..i..".SpecIcon", BuildButton, "PopupButtonTemplate")
    BuildButton.SpecIcon:SetSize(32,32)
    BuildButton.SpecIcon:SetPoint("LEFT", 0, 2)
    BuildButton.SpecIcon:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    BuildButton.SpecIcon:GetHighlightTexture():ClearAllPoints()
    BuildButton.SpecIcon:GetHighlightTexture():SetPoint("CENTER", 0, 0)
    BuildButton.SpecIcon:GetHighlightTexture():SetSize(36,36)

    BuildButton.SpecIcon.Icon = BuildButton.SpecIcon:CreateTexture(parentName.."Button"..i..".SpecIcon.Icon", "ARTWORK")
    BuildButton.SpecIcon.Icon:SetSize(36,36)
    BuildButton.SpecIcon.Icon:SetPoint("CENTER", 0, -1)
    BuildButton.SpecIcon.Icon:SetDesaturated(true)

    return BuildButton
end

UIParentHybridScroll.Init()]]--
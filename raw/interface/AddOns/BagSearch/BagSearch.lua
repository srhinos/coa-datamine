local frame = CreateFrame("Frame");

local function CheckSearchItem(item, filter)
    return string.find(string.lower(item), string.lower(filter))
end

local function CheckHideItem(bag, slot, filter)
    -- check if filter is set
    if filter == nil or filter == "" or filter == SEARCH then
        return false
    end

    -- check if item slot contains item
    local item = GetContainerItemLink(bag, slot)
    if item == nil then
        return false
    end

    -- check if item name matches filter
    local itemName = select(1, GetItemInfo(item))
    if CheckSearchItem(itemName, filter) then
        return false
    end

    return true
end

local function SearchContainers(filter)
    for bag = 0, NUM_BAG_SLOTS do
        local frame = _G["ContainerFrame"..bag+1]
	    local name = frame:GetName().."Item";
	    local itemButton;
        local hideItem = true;
	
	    for slot = 1, GetContainerNumSlots(bag) do
            -- @robinsch: ContainerFrameN.ItemN is flipped
		    itemButton = _G[name..(GetContainerNumSlots(bag) - slot + 1)];
            if not CheckHideItem(bag, slot, filter) then 
                itemButton:SetAlpha(1)
            else
                itemButton:SetAlpha(0.25)
            end
        end
    end
end

local function CreateSearchBox(name, parent, x, y)
    -- parent
    parent.searchBox = CreateFrame("EditBox", name, parent, "InputBoxTemplate");
    parent.parentFrame = parent;
    parent.searchBox:SetWidth(130);
    parent.searchBox:SetHeight(20);
    parent.searchBox:SetPoint("TOPRIGHT", parent, "TOPRIGHT", x, y);
    parent.searchBox:SetTextInsets(16, 0, 0, 0)
    parent.searchBox:SetAutoFocus(false)
    parent.searchBox:SetFontObject("GameFontDisable")
    parent.searchBox:SetText(SEARCH)

    -- searchIcon
    parent.searchBox.searchIcon = parent.searchBox:CreateTexture("SearchBoxSearchIcon", "OVERLAY")
    parent.searchBox.searchIcon:SetSize(14, 14)
    parent.searchBox.searchIcon:SetPoint("LEFT", 1, -1)
    parent.searchBox.searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    parent.searchBox.searchIcon:SetVertexColor(0.6, 0.6, 0.6)

    -- clearButton
    parent.searchBox.clearButton = CreateFrame("Button", nil,  parent.searchBox, "")
    parent.searchBox.clearButton:SetSize(26, 26)
    parent.searchBox.clearButton:SetPoint("RIGHT", 0, 0)
    do
        local tex = parent.searchBox.clearButton:CreateTexture(nil, "ARTWORK")
        tex:SetTexture("Interface\\Buttons\\CancelButton-Up")
        tex:SetSize(26, 26)
        tex:SetPoint("TOPLEFT", 3, -3)
    end
    parent.searchBox.clearButton:SetScript("OnClick", function()
            parent.searchBox:ClearFocus()
            parent.searchBox:SetFontObject("GameFontDisable")
            parent.searchBox.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
            parent.searchBox:SetText(SEARCH)

            SearchContainers(nil)
    end)

    -- scripts
    parent.searchBox:SetScript("OnEnterPressed", function(self)
        PlaySound("igMainMenuOptionCheckBoxOn")
        EditBox_ClearFocus(self)
    end)

    parent.searchBox:SetScript("OnEscapePressed", EditBox_ClearFocus)
    parent.searchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
        if self:GetText() == SEARCH then
            self:SetFontObject("ChatFontSmall")
            self.searchIcon:SetVertexColor(1, 1, 1)
        end
    end)
    parent.searchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        if self:GetText() == "" or self:GetText() == SEARCH then
            EditBox_ClearFocus(self)
            self:SetFontObject("GameFontDisable")
            self.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
            self:SetText(SEARCH)

            SearchContainers(nil)
        end
    end)
    parent.searchBox:SetScript("OnTextChanged", function(self)
        if self:GetText() and self:GetText() ~= SEARCH then
            SearchContainers(self:GetText())
        else
            SearchContainers(nil)
        end
    end)
end

function BS_MainFrame_OnLoad(self)
    BS = {};
    CreateSearchBox("ContainerFrame1SearchBox", _G["ContainerFrame1"], -10, -26);

    self:SetScript("OnShow", function()
        self:RegisterEvent("BAG_UPDATE");
    end)

    self:SetScript("OnHide", function()
        self:UnregisterEvent("BAG_UPDATE");
    end)

    self:SetScript("OnEvent", function(self, event)
        if (event == "BAG_UPDATE") then
            local filter = _G["ContainerFrame1"].searchBox:GetText()
            if filter ~= nil and filter ~= "" and filter ~= SEARCH then
                SearchContainers(filter)
            end
        end
    end)
end

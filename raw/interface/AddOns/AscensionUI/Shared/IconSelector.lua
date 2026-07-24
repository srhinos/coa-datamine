function IconSelectCreateFrame(name, parent, point)
    local self = {
        name = name,
        parent = parent,
        point = point,
    }

    local NUM_ICONS_SHOWN = 20
    local NUM_ICONS_PER_ROW = 5
    local NUM_ICON_ROWS = 4
    local ICON_ROW_HEIGHT = 36

    -------------------------------------------------------------------------------
    --                                Functions                                  --
    -------------------------------------------------------------------------------
    local function Update()
        local numMacroIcons = GetNumMacroIcons()
        local PopupIcon, PopupButton
        local PopupOffset = FauxScrollFrame_GetOffset(_G[self.name..".ScrollFrame"])
        local index
        
        if ( self.mode == "new" ) then
            _G[self.name..".EditBox"]:SetText("")
        end
        
        -- Icon list
        local texture
        for i=1, NUM_ICONS_SHOWN do
            PopupIcon = _G[self.name..".CheckButton"..i.."Icon"]
            PopupButton = _G[self.name..".CheckButton"..i] 
            index = (PopupOffset * NUM_ICONS_PER_ROW) + i
            texture = GetMacroIconInfo(index)
            if ( index <= numMacroIcons ) then
                PopupIcon:SetTexture(texture)
                PopupButton:Show()
            else
                PopupIcon:SetTexture("")
                PopupButton:Hide()
            end
            if ( _G[self.name].selectedIcon and (index == _G[self.name].selectedIcon) ) then
                PopupButton:SetChecked(1)
            elseif ( _G[self.name].selectedIconTexture ==  texture ) then
                PopupButton:SetChecked(1)
                _G[self.name].selectedIcon = index
            else
                PopupButton:SetChecked(nil)
            end
        end
        
        -- Scrollbar stuff
        FauxScrollFrame_Update(_G[self.name..".ScrollFrame"], ceil(numMacroIcons / NUM_ICONS_PER_ROW) , NUM_ICON_ROWS, ICON_ROW_HEIGHT )
    end

    local function PopupOkayButton_Update()
        if ( (strlen(_G[self.name..".EditBox"]:GetText()) > 0) and _G[self.name].selectedIcon ) then
            _G[self.name..".OkayButton"]:Enable();
        else
            _G[self.name..".OkayButton"]:Disable();
        end
        if ( _G[self.name].mode == "edit" and (strlen(_G[self.name..".EditBox"]:GetText()) > 0) ) then
            _G[self.name..".OkayButton"]:Enable();
        end
    end

    local function SelectTexture(selectedIcon)
        _G[self.name].selectedIcon = selectedIcon
        -- Clear out selected texture
        _G[self.name].selectedIconTexture = nil

        PopupOkayButton_Update()
        local mode = _G[self.name].mode

        _G[self.name].mode = nil -- funny part
        Update(_G[self.name])
        _G[self.name].mode = mode
    end

    local function PopupButton_OnClick(button)
        SelectTexture(button.id + (FauxScrollFrame_GetOffset(_G[self.name..".ScrollFrame"]) * NUM_ICONS_PER_ROW));
    end 

    local function PopupFrame_CancelEdit()
        _G[self.name]:Hide()
        Update()
        _G[self.name].selectedIcon = nil;
    end

    local function PopupOkayButton_OnClick()
        local index = 1
        
        if not(_G[self.name].selectedIcon) then
            self:UpdateValues(_G[self.name..".EditBox"]:GetText(), _G[self.name].selectedIconTexture)
        else
            self:UpdateValues(_G[self.name..".EditBox"]:GetText(), GetMacroIconInfo(_G[self.name].selectedIcon))
        end

        _G[self.name]:Hide();
    end

    local function PopupFrame_OnShow()
        PlaySound("igCharacterInfoOpen")
        
        PopupOkayButton_Update()

        if ( _G[self.name].mode == "new" ) then
            SelectTexture(1);
        end

        Update()
    end

    -------------------------------------------------------------------------------
    --                                 External                                  --
    -------------------------------------------------------------------------------
    function self:CreateNew() -- use to change internal settings
        PopupFrame_CancelEdit()
        _G[self.name..".EditBox"]:SetText("")
        _G[self.name].mode = "new"
        _G[self.name]:Show()
    end

    function self:EditExisting(text, texture) -- use to change internal settings
        PopupFrame_CancelEdit()
        _G[self.name].mode = "edit"
        _G[self.name].selectedIconTexture = texture
        _G[self.name..".EditBox"]:SetText(text)
        _G[self.name]:Show()
    end

    function self:UpdateValues(text, texture) -- this one is called when user clicks OK button or enter
        -- set up for each call
    end

    -------------------------------------------------------------------------------
    --                                 Frames                                    --
    -------------------------------------------------------------------------------

    self.frame = CreateFrame("FRAME", self.name, self.parent)
    self.frame:EnableMouse()
    self.frame:SetSize(297, 298)
    self.frame:SetPoint(unpack(self.point))
    self.frame:SetScript("OnShow", PopupFrame_OnShow)
    self.frame:Hide()

    --<Layers>
    self.frame.BG = self.frame:CreateTexture(nil, "BACKGROUND")
    self.frame.BG:SetTexture("Interface\\MacroFrame\\MacroPopup-TopLeft")
    self.frame.BG:SetSize(256, 256)
    self.frame.BG:SetPoint("TOPLEFT")

    self.frame.BG = self.frame:CreateTexture(nil, "BACKGROUND")
    self.frame.BG:SetTexture("Interface\\MacroFrame\\MacroPopup-TopRight")
    self.frame.BG:SetSize(64, 256)
    self.frame.BG:SetPoint("TOPLEFT", 256, 0)

    self.frame.BG = self.frame:CreateTexture(nil, "BACKGROUND")
    self.frame.BG:SetTexture("Interface\\MacroFrame\\MacroPopup-BotLeft")
    self.frame.BG:SetSize(256, 64)
    self.frame.BG:SetPoint("TOPLEFT", 0, -256)

    self.frame.BG = self.frame:CreateTexture(nil, "BACKGROUND")
    self.frame.BG:SetTexture("Interface\\MacroFrame\\MacroPopup-BotRight")
    self.frame.BG:SetSize(64, 64)
    self.frame.BG:SetPoint("TOPLEFT", 256, -256)

    self.frame.Text = self.frame:CreateFontString(nil, "ARTWORK")
    self.frame.Text:SetFontObject(GameFontHighlightSmall)
    self.frame.Text:SetPoint("TOPLEFT", 24, -21)
    self.frame.Text:SetText("Enter Name (Max 32 Characters)")

    self.frame.Text = self.frame:CreateFontString(nil, "ARTWORK")
    self.frame.Text:SetFontObject(GameFontHighlightSmall)
    self.frame.Text:SetPoint("TOPLEFT", 24, -69)
    self.frame.Text:SetText(MACRO_POPUP_CHOOSE_ICON)

    --<Frames>
        --<EditBox>
    self.frame.EditBox = CreateFrame("EditBox", self.name..".EditBox", self.frame)
    self.frame.EditBox:SetMaxLetters(32)
    self.frame.EditBox:SetSize(182, 20)
    self.frame.EditBox:SetPoint("TOPLEFT", 29, -35)
    self.frame.EditBox:SetFontObject(ChatFontNormal)
    self.frame.EditBox:ClearFocus(self)
    self.frame.EditBox:SetAutoFocus(false)

    self.frame.EditBox:SetScript("OnTextChanged", function(self)
        PopupOkayButton_Update()
        --MacroFrameSelectedMacroName:SetText(self:GetText())
    end)

    self.frame.EditBox:SetScript("OnEscapePressed", PopupFrame_CancelEdit)

    self.frame.EditBox:SetScript("OnEnterPressed", function()
        if ( _G[self.name..".OkayButton"]:IsEnabled() ~= 0 ) then
            PopupOkayButton_OnClick(_G[self.name..".OkayButton"])
        end
    end)


    self.frame.EditBox.BG_Left = self.frame.EditBox:CreateTexture(self.name..".EditBox.BG_Left", "BACKGROUND")
    self.frame.EditBox.BG_Left:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
    self.frame.EditBox.BG_Left:SetSize(12, 29)
    self.frame.EditBox.BG_Left:SetPoint("TOPLEFT", -11, 0)
    self.frame.EditBox.BG_Left:SetTexCoord(0, 0.09375, 0, 1.0)

    self.frame.EditBox.BG_Middle = self.frame.EditBox:CreateTexture(self.name..".EditBox.BG_Middle", "BACKGROUND")
    self.frame.EditBox.BG_Middle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
    self.frame.EditBox.BG_Middle:SetSize(175, 29)
    self.frame.EditBox.BG_Middle:SetPoint("LEFT", self.name..".EditBox.BG_Left", "RIGHT")
    self.frame.EditBox.BG_Middle:SetTexCoord(0.09375, 0.90625, 0, 1.0)

    self.frame.EditBox.BG_Right = self.frame.EditBox:CreateTexture(self.name..".EditBox.BG_Right", "BACKGROUND")
    self.frame.EditBox.BG_Right:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-FilterBorder")
    self.frame.EditBox.BG_Right:SetSize(12, 29)
    self.frame.EditBox.BG_Right:SetPoint("LEFT", self.name..".EditBox.BG_Middle", "RIGHT")
    self.frame.EditBox.BG_Right:SetTexCoord(0.90625, 1.0, 0, 1.0)

        --<Scroll>
    self.frame.ScrollFrame = CreateFrame("ScrollFrame", self.name..".ScrollFrame", self.frame, "ClassTrainerListScrollFrameTemplate")
    self.frame.ScrollFrame:SetSize(296, 195)
    self.frame.ScrollFrame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -39, -67)
    self.frame.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ICON_ROW_HEIGHT, Update())
        Update()
    end)

        --<Buttons>
            --<CheckButtons>
    for index = 1, 20 do
        local point = nil

        if (index == 1) then -- proper positioning
            point = {"TOPLEFT", 24, -85}
        elseif (index == 6) then
            point = {"TOPLEFT", self.name..".CheckButton1", "BOTTOMLEFT", 0, -8}
        elseif (index == 11) then
            point = {"TOPLEFT", self.name..".CheckButton6", "BOTTOMLEFT", 0, -8}
        elseif (index == 16) then
            point = {"TOPLEFT", self.name..".CheckButton11", "BOTTOMLEFT", 0, -8}
        end

        self.frame.CheckButton = CreateFrame("CheckButton", self.name..".CheckButton"..index, self.frame, "SimplePopupButtonTemplate")
        if not(point) then
            self.frame.CheckButton:SetPoint("LEFT", self.name..".CheckButton"..(index-1), "RIGHT", 10, 0)
        else
            self.frame.CheckButton:SetPoint(unpack(point))
        end

        self.frame.CheckButton.NormalTexture = self.frame.CheckButton:CreateTexture(self.frame.CheckButton:GetName().."Icon", "ARTWORK")
        self.frame.CheckButton.NormalTexture:SetSize(36,36)
        self.frame.CheckButton.NormalTexture:SetPoint("CENTER", 0, -1)

        self.frame.CheckButton:SetNormalTexture(self.frame.CheckButton.NormalTexture)
        self.frame.CheckButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        self.frame.CheckButton:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")

        self.frame.CheckButton:SetScript("OnClick", PopupButton_OnClick)

        _G[self.name..".CheckButton"..index].id = index
    end

            --<Buttons>
    self.frame.CancelButton = CreateFrame("Button", self.name..".CancelButton", self.frame, "UIPanelButtonTemplate")
    self.frame.CancelButton:SetText(CANCEL)
    self.frame.CancelButton:SetSize(78, 22)
    self.frame.CancelButton:SetPoint("BOTTOMRIGHT", -11, 13)
    self.frame.CancelButton:SetScript("OnClick", function()
        PopupFrame_CancelEdit()
        PlaySound("gsTitleOptionOK")
    end)

    self.frame.OkayButton = CreateFrame("Button", self.name..".OkayButton", self.frame, "UIPanelButtonTemplate")
    self.frame.OkayButton:SetText(OKAY)
    self.frame.OkayButton:SetSize(78, 22)
    self.frame.OkayButton:SetPoint("RIGHT", self.name..".CancelButton", "LEFT", -2, 0)
    self.frame.OkayButton:SetScript("OnClick", function()
        PopupOkayButton_OnClick()
        PlaySound("gsTitleOptionOK")
    end)

    return self
end

-------------------------------------------------------------------------------
--                                 Example                                   --
-------------------------------------------------------------------------------
--[[
local ExampleSpecButton = CreateFrame("Button", "ExampleSpecButton", UIParent)
ExampleSpecButton:SetPoint("CENTER", 0, -50)
ExampleSpecButton:SetSize(210, 54)

-- name, parent, SetPoint
local IconNameSelectFrame = IconSelectCreateFrame("TestIconSelectCreateFrame", UIParent, {"LEFT", ExampleSpecButton, "RIGHT", 16, 16})

function IconNameSelectFrame:UpdateValues(text, texture) -- this one is called when user clicks OK button or enter
    ExampleSpecButton.SpecIcon.Icon:SetTexture(texture)
    ExampleSpecButton.Text:SetText(text)
end

ExampleSpecButton.Border = ExampleSpecButton:CreateTexture("ExampleSpecButton.Border", "BORDER")
ExampleSpecButton.Border:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\2\\SpecButton")
ExampleSpecButton.Border:SetSize(256,64)
ExampleSpecButton.Border:SetPoint("CENTER", 0, 0)

ExampleSpecButton.H = ExampleSpecButton:CreateTexture("ExampleSpecButton.H", "OVERLAY")
ExampleSpecButton.H:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\Gradient_Highlight")
ExampleSpecButton.H:SetSize(256,86)
ExampleSpecButton.H:SetPoint("CENTER", 3, 3)
ExampleSpecButton:SetHighlightTexture(ExampleSpecButton.H)

ExampleSpecButton.Text = ExampleSpecButton:CreateFontString("ExampleSpecButton.Text")
ExampleSpecButton.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
ExampleSpecButton.Text:SetFontObject(GameFontNormal)
ExampleSpecButton.Text:SetPoint("CENTER", 20, 10)
ExampleSpecButton.Text:SetShadowOffset(1,-1)
ExampleSpecButton.Text:SetText("TEST")
ExampleSpecButton.Text:SetSize(160, 16)
ExampleSpecButton.Text:SetJustifyH("LEFT")

ExampleSpecButton.Text_Add = ExampleSpecButton:CreateFontString("ExampleSpecButton.Text_Add")
ExampleSpecButton.Text_Add:SetFont("Fonts\\FRIZQT__.TTF", 10)
ExampleSpecButton.Text_Add:SetFontObject(GameFontNormal)
ExampleSpecButton.Text_Add:SetPoint("CENTER", 20, -6)
ExampleSpecButton.Text_Add:SetShadowOffset(1,-1)
ExampleSpecButton.Text_Add:SetText("|cff00FF00Active")
ExampleSpecButton.Text_Add:SetSize(160, 16)
ExampleSpecButton.Text_Add:SetJustifyH("LEFT")

ExampleSpecButton.SpecIcon = CreateFrame("FRAME", "ExampleSpecButton.SpecIcon", ExampleSpecButton, "PopupButtonTemplate")
ExampleSpecButton.SpecIcon:SetSize(32,32)
ExampleSpecButton.SpecIcon:SetPoint("LEFT", 0, 2)

ExampleSpecButton.SpecIcon.Settings = CreateFrame("Button", "ExampleSpecButton.SpecIcon.Settings", ExampleSpecButton.SpecIcon)
ExampleSpecButton.SpecIcon.Settings:SetPoint("BOTTOMRIGHT", 12, -8)
ExampleSpecButton.SpecIcon.Settings:SetSize(26, 26)
ExampleSpecButton.SpecIcon.Settings:SetNormalTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\GearIcon")
ExampleSpecButton.SpecIcon.Settings:SetHighlightTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\GearIcon_H")
ExampleSpecButton.SpecIcon.Settings:SetScript("OnClick", function(self)
    if (ExampleSpecButton.SpecIcon.Icon:GetTexture() ~= "Interface\\Icons\\inv_misc_book_16") then
        IconNameSelectFrame:EditExisting(ExampleSpecButton.Text:GetText(), ExampleSpecButton.SpecIcon.Icon:GetTexture())
    else
        IconNameSelectFrame:CreateNew()
    end
end)

ExampleSpecButton.SpecIcon.Settings:SetScript("OnEnter", function(self)
    if (self:IsEnabled() == 1) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:AddLine("|cffFFFFFFCustomize specialization|r")
        GameTooltip:AddLine("Click here to change icon or name of your specialization.")
        GameTooltip:Show()
    end
end)

ExampleSpecButton.SpecIcon.Settings:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

ExampleSpecButton.SpecIcon.Icon = ExampleSpecButton.SpecIcon:CreateTexture("ExampleSpecButton.SpecIcon.Icon", "ARTWORK")
ExampleSpecButton.SpecIcon.Icon:SetTexture("Interface\\Icons\\inv_misc_book_16")
ExampleSpecButton.SpecIcon.Icon:SetSize(36,36)
ExampleSpecButton.SpecIcon.Icon:SetPoint("CENTER", 0, -1)]]--
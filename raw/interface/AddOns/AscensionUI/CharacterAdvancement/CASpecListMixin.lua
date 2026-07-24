local Addon = select(2, ...)



CASpecListMixin = {}
CASpecListMixin.DB = {}
CASpecListMixin.ACTIVESPECIALIZATION = 1

CASpecListMixin.DEFAULT_SPEC_NAMES = { -- TODO: To globals
    "Spec I",
    "Spec II",
    "Spec III",
    "Spec IV",
    "Spec V",
    "Spec VI",
    "Spec VII",
    "Spec VIII",
    "Spec IX",
    "Spec X",
    "Spec XI",
    "Spec XII",
    "Spec XIII",
    "Spec XIV",
    "Spec XV",
    "Spec XVI",
    "Spec XVII",
    "Spec XVIII",
    "Spec XVIX",
    "Spec XX",
}

function CASpecListMixin:OnLoad()
    C_Hook:Register(self, "ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED")
end

function CASpecListMixin:RefreshActiveSpecID()
    self.ACTIVESPECIALIZATION = SpecializationUtil.GetActiveSpecialization()
    self:UpdateSpecButtons()
end

function CASpecListMixin:ASCENSION_CA_SPECIALIZATION_ACTIVE_ID_CHANGED(specID)
    if not PLAYER_ENTERED_WORLD then return end
    self:EquipSetForSpecID(specID+1)
    self:ApplyEnchantPresetForSpecID(specID+1)
    self:RefreshActiveSpecID()
end

function CASpecListMixin:EditBuild(i)
    self.scrollFrame.EquipmentSetPopup:Hide()
    self.scrollFrame.EnchantPresetPopup:Hide()
    self.frame.SelectedBuild = i
    self.scrollFrame.PopupController.frame:Hide()

    if self.DB.SpecNamesCustom and self.DB.SpecNamesCustom[i] then
        self.scrollFrame.PopupController:EditExisting(self.DB.SpecNamesCustom[i], self.DB.SpecIconsCustom[i])
    else
        self.scrollFrame.PopupController:CreateNew()
    end
end

function CASpecListMixin:EquipSetForSpecID(specID)
    if self.DB.SpecEquipmentSet and self.DB.SpecEquipmentSet[specID] then
        local setName = self.DB.SpecEquipmentSet[specID]
        if setName then
            if not EquipmentManager_EquipSet(setName) then
                return
            end
        end
    end
end

function CASpecListMixin:SelectEquipmentSet(setID)
    local setName = type(setID) == "number" and GetEquipmentSetInfo(setID)
    self.DB.SpecEquipmentSet = self.DB.SpecEquipmentSet or {}
    if setName then
        self.DB.SpecEquipmentSet[self.frame.SelectedBuild] = setName
    else
        self.DB.SpecEquipmentSet[self.frame.SelectedBuild] = nil
    end
    self.scrollFrame.EquipmentSetPopup:Hide()
    self:UpdateSpecButtons()
end

function CASpecListMixin:EditEquipmentSet(index)
    self.scrollFrame.EnchantPresetPopup:Hide()
    self.scrollFrame.EquipmentSetPopup:Hide()
    self.frame.SelectedBuild = index
    self.scrollFrame.EquipmentSetPopup:Show()
end

function CASpecListMixin:SelectEnchantPreset(presetID)
    self.DB.SpecEnchantPreset = self.DB.SpecEnchantPreset or {}
    if self.DB.SpecEnchantPreset[self.frame.SelectedBuild] == presetID then
        self.DB.SpecEnchantPreset[self.frame.SelectedBuild] = nil
    else
        self.DB.SpecEnchantPreset[self.frame.SelectedBuild] = presetID
    end
    self.scrollFrame.EnchantPresetPopup:Hide()
    self:UpdateSpecButtons()
end

function CASpecListMixin:EditEnchantPreset(index)
    self.scrollFrame.EquipmentSetPopup:Hide()
    self.scrollFrame.EnchantPresetPopup:Hide()
    self.frame.SelectedBuild = index
    self.scrollFrame.EnchantPresetPopup:Show()
end

function CASpecListMixin:ApplyEnchantPresetForSpecID(specID)
    local presetID = self.DB.SpecEnchantPreset and self.DB.SpecEnchantPreset[specID]
    if presetID then
        if MysticEnchantManagerUtil.GetActivePreset() ~= presetID then
            MysticEnchantManagerUtil.AttemptOperation("Activate", "CanActivate", presetID)
        end
    end
end

function CASpecListMixin:UpdateSpecButtons()
    self.ACTIVESPECIALIZATION = SpecializationUtil.GetActiveSpecialization()

    for id, spellId in ipairs(SPEC_SWAP_SPELLS) do
        local button = self.frame.specButtons[id]

        if (IsSpellKnown(spellId)) then -- if player has that spec
            button:EnableSpecButton()
            local BuildName = GetSpellInfo(spellId)

            if self.DB.SpecNamesCustom and self.DB.SpecNamesCustom[id] then
                BuildName = self.DB.SpecNamesCustom[id]
            end

            if self.DB.SpecIconsCustom and self.DB.SpecIconsCustom[id] then
                button:SetSpecIcon(self.DB.SpecIconsCustom[id])
            end

            if self.DB.SpecEquipmentSet and self.DB.SpecEquipmentSet[id] then
                button:SetEquipmentSet(self.DB.SpecEquipmentSet[id])
            else
                button:SetEquipmentSet()
            end

            if self.DB.SpecEnchantPreset and self.DB.SpecEnchantPreset[id] then
                button:SetEnchantPreset(self.DB.SpecEnchantPreset[id])
            else
                button:SetEnchantPreset()
            end

            button:SetSpecName(BuildName)
            if ( self.ACTIVESPECIALIZATION == id) then -- if spec is currently in use
                button:ActiveSpecButton()
                --RefreshScrollOfUnlearning() -- TODO: Fix
            end

        else
            button:DisableSpecButton()
        end
    end
end

function CASpecListMixin:UpdateSpecIconName(text, texture)
    self.DB.SpecNamesCustom[self.frame.SelectedBuild] = text
    self.DB.SpecIconsCustom[self.frame.SelectedBuild] = texture
    self:UpdateSpecButtons()
end

function CASpecListMixin:CreateFrame(name, parent)
    local frame = CreateFrame("FRAME", "$parent."..name, parent)
    frame:SetSize(228, 437)
    --frame:SetBackdrop(GameTooltip:GetBackdrop())

    frame.SelectedBuild = 1

    for i = 1, 20 do
        local button = self:CreateSpecButton("SpecButton"..i, frame)
        button.Text:SetText(string.upper(self.DEFAULT_SPEC_NAMES[i]))
        button:SetID(i)

        frame.specButtons = frame.specButtons or {}
        table.insert(frame.specButtons, button)

        if (i == 1) then
            button:SetPoint("TOP", 0, -3)
        else
            button:SetPoint("BOTTOM", frame.specButtons[i-1], 0, -50)
        end
    end

    return frame
end

function CASpecListMixin:CreateScrollFrame(name, parent)
    local scrollFrame = CreateFrame("ScrollFrame", "$parent."..name, parent)
    scrollFrame:SetSize(228, 437)
    scrollFrame:EnableMouseWheel(true)

    scrollFrame.ScrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate") 
    scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 5, -15)    
    scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 15) 

    scrollFrame.ScrollBar:SetMinMaxValues(1, 566) 
    scrollFrame.ScrollBar:SetValueStep(1) 
    scrollFrame.ScrollBar.scrollStep = 1
    scrollFrame.ScrollBar:SetValue(1) 
    scrollFrame.ScrollBar:SetWidth(16) 
    scrollFrame.ScrollBar:SetScript("OnValueChanged", function (self, value) 
        scrollFrame:SetVerticalScroll(value) 
    end)
    
    scrollFrame.PopupController = IconSelectCreateFrame(scrollFrame:GetName()..".PopupController", scrollFrame, {"TOPRIGHT", scrollFrame, "TOPLEFT", -8, 0 })
    scrollFrame.PopupController.frame:SetFrameLevel(scrollFrame.ScrollBar:GetFrameLevel()+10)

    scrollFrame.EquipmentSetPopup = CreateFrame("Frame", "$parentEquipmentSetPopup", scrollFrame, "UIPanelDialogTemplate")
    scrollFrame.EquipmentSetPopup:SetSize(261, 63)
    scrollFrame.EquipmentSetPopup:EnableMouse(true)
    scrollFrame.EquipmentSetPopup:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 14, 0)
    scrollFrame.EquipmentSetPopup:Hide()
    scrollFrame.EquipmentSetPopup.title:SetText("Equipment Sets")
    scrollFrame.EquipmentSetPopup:SetFrameLevel(scrollFrame.ScrollBar:GetFrameLevel()+2)

    scrollFrame.EquipmentSetPopup.ClearButton = CreateFrame("Button", "$parentClearButton", scrollFrame.EquipmentSetPopup, "UIPanelButtonTemplate")
    scrollFrame.EquipmentSetPopup.ClearButton:SetSize(98, 22)
    scrollFrame.EquipmentSetPopup.ClearButton:SetText(REMOVE)
    scrollFrame.EquipmentSetPopup.ClearButton:SetPoint("BOTTOM", 0, 13)

    scrollFrame.EquipmentSetPopup.ClearButton:SetScript("OnClick", function()
        self:SelectEquipmentSet()
    end)

    scrollFrame.EquipmentSetPopup.buttons = {};

    scrollFrame.EquipmentSetPopup:SetScript("OnShow", function(popup)
        popup:GetParent().PopupController.frame:Hide()

        local selectedBuild = self.frame.SelectedBuild
        for index = 1, #popup.buttons do
            local button = popup.buttons[index]
            local setName, setIcon = GetEquipmentSetInfo(index)
            button.icon:SetTexture(setIcon)
            button.text:SetText(setName)
            local isSelected = self.DB.SpecEquipmentSet and self.DB.SpecEquipmentSet[selectedBuild] == index
            button:SetChecked(isSelected)
        end
    end)

    scrollFrame.EquipmentSetPopup:SetScript("OnHide", function()
        self.frame.SelectedBuild = 1
    end)

    local button;
    local height = 63 + (46 * math.ceil(MAX_EQUIPMENT_SETS_PER_PLAYER / NUM_GEARSETS_PER_ROW))
    scrollFrame.EquipmentSetPopup:SetHeight(height)
    for i = 1, MAX_EQUIPMENT_SETS_PER_PLAYER do
        button = CreateFrame("CheckButton", "$parentButton" .. i, scrollFrame.EquipmentSetPopup, "GearSetButtonTemplate");
        if ( i == 1 ) then
            button:SetPoint("TOPLEFT", scrollFrame.EquipmentSetPopup, "TOPLEFT", 16, -32);
        elseif ( mod(i, NUM_GEARSETS_PER_ROW) == 1 ) then
            button:SetPoint("TOP", scrollFrame.EquipmentSetPopup.buttons[(i-NUM_GEARSETS_PER_ROW)], "BOTTOM", 0, -10);
        else
            button:SetPoint("LEFT", scrollFrame.EquipmentSetPopup.buttons[i-1], "RIGHT", 13, 0);
        end
        button.icon = _G[button:GetName() .. "Icon"];
        button.text = _G[button:GetName() .. "Name"];
        
        button:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.SPELL_ICON_DROP_75)
            self:SelectEquipmentSet(i)
        end)
        tinsert(scrollFrame.EquipmentSetPopup.buttons, button);
    end

    function scrollFrame.PopupController.UpdateValues(controller, text, texture) -- set up from outside
        self:UpdateSpecIconName(text, texture)
    end

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        if (scrollFrame.ScrollBar:IsVisible()) and (scrollFrame.ScrollBar:IsEnabled() == 1) then
            local value = scrollFrame.ScrollBar:GetValue()
            scrollFrame.ScrollBar:SetValue(value-delta*32)
        end
    end)
    
    scrollFrame.EnchantPresetPopup = CreateFrame("Frame", "$parentEnchantPresetPopup", scrollFrame, "StandardProportionalScrollListTemplate")
    scrollFrame.EnchantPresetPopup:SetSize(228, 400)
    scrollFrame.EnchantPresetPopup:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 32, 0)
    scrollFrame.EnchantPresetPopup:Hide()
    
    scrollFrame.EnchantPresetPopup.Background = scrollFrame.EnchantPresetPopup:CreateTexture("$parentBackground", "BACKGROUND")
    scrollFrame.EnchantPresetPopup.Background:SetPoint("TOPLEFT", -8, 8)
    scrollFrame.EnchantPresetPopup.Background:SetPoint("BOTTOMRIGHT", 24, -8)
    scrollFrame.EnchantPresetPopup.Background:SetTexture(0, 0, 0, 0.85)

    scrollFrame.EnchantPresetPopup.CloseButton = CreateFrame("Button", "$parentCloseButton", scrollFrame.EnchantPresetPopup, "UIPanelCloseButton")
    scrollFrame.EnchantPresetPopup.CloseButton:SetPoint("TOPRIGHT", 0, 0)
    scrollFrame.EnchantPresetPopup.CloseButton:SetFrameLevel(scrollFrame.EnchantPresetPopup:GetFrameLevel()+10)

    scrollFrame.EnchantPresetPopup.NineSlice = CreateFrame("Frame", "$parentNineSlice", scrollFrame.EnchantPresetPopup, "NineSlicePanelTemplate2")
    scrollFrame.EnchantPresetPopup.NineSlice:SetLayout("Dialog")
    scrollFrame.EnchantPresetPopup.NineSlice:SetPoint("TOPLEFT", -12, 14)
    scrollFrame.EnchantPresetPopup.NineSlice:SetPoint("BOTTOMRIGHT", 28, -14)
    
    scrollFrame.EnchantPresetPopup:SetGetNumResultsFunction(MysticEnchantManagerUtil.GetNumPresets)

    scrollFrame.EnchantPresetPopup:SetSelectionCallback(function(index)
        PlaySound(SOUNDKIT.SPELL_ICON_DROP_75)
        self:SelectEnchantPreset(index)
    end)

    scrollFrame.EnchantPresetPopup:SetScript("OnShow", function(popup)
        x = popup
        local selectedBuild = self.frame.SelectedBuild
        if not popup:IsInitialized() then
            popup:SetTemplate("SelectPresetPopupItemTemplate")
        end
        popup:SetSelectedIndex(self.DB.SpecEnchantPreset and self.DB.SpecEnchantPreset[selectedBuild])
        popup:RefreshScrollFrame()
    end)

    return scrollFrame
end

function CASpecListMixin:CreateSpecButton(name, parent)
    local button = CreateFrame("Button", "$parent."..name, parent)
    button:SetSize(210, 54)
    button.Hint = "Click to change specialization"
    button:SetMotionScriptsWhileDisabled(true)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:AddLine(self.Text:GetText())
        GameTooltip:AddLine(self.Hint)
        GameTooltip:Show()
        if self:IsEnabled() == 1 then
            self.H:Show()
        end
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.H:Hide()
    end)

    button.Border = button:CreateTexture("$parent.Border", "BORDER")
    button.Border:SetTexture(Addon.AwTexPath.."CAOverhaul\\2\\SpecButton")
    button.Border:SetSize(256,64)
    button.Border:SetPoint("CENTER", 0, 0)

    button.SpecIcon = CreateFrame("FRAME", "$parent.SpecIcon", button, "PopupButtonTemplate")
    button.SpecIcon:SetSize(32,32)
    button.SpecIcon:SetPoint("LEFT", 0, 2)

    button.Text = button:CreateFontString("$parent.Text")
    button.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    button.Text:SetFontObject(GameFontNormal)
    button.Text:SetPoint("LEFT", button.SpecIcon, "RIGHT", 8, 10)
    button.Text:SetPoint("RIGHT", button, "RIGHT", -82, 10)
    button.Text:SetShadowOffset(1,-1)
    button.Text:SetJustifyH("LEFT")

    button.Text_Add = button:CreateFontString("$parent.Text_Add")
    button.Text_Add:SetFont("Fonts\\FRIZQT__.TTF", 10)
    button.Text_Add:SetFontObject(GameFontNormal)
    button.Text_Add:SetPoint("LEFT", button.SpecIcon, "RIGHT", 8, -6)
    button.Text_Add:SetPoint("RIGHT", button, "RIGHT", -82, -6)
    button.Text_Add:SetShadowOffset(1,-1)
    button.Text_Add:SetText("|cff00FF00Active")
    button.Text_Add:SetJustifyH("LEFT")

    button.KnownBorder = button.SpecIcon:CreateTexture("$parent.KnownBorder", "ARTWORK")
    button.KnownBorder:SetTexture(Addon.AwTexPath.."CAOverhaul\\Known_Highlight")
    button.KnownBorder:SetSize(80,80)
    button.KnownBorder:SetPoint("CENTER",button.SpecIcon, 0, 0)
    button.KnownBorder:SetBlendMode("ADD")

    button.SpecIcon.Settings = CreateFrame("Button", "$parent.SpecIcon.Settings", button.SpecIcon)
    button.SpecIcon.Settings:SetPoint("BOTTOMRIGHT", 12, -8)
    button.SpecIcon.Settings:SetSize(26, 26)
    button.SpecIcon.Settings:SetNormalTexture(Addon.AwTexPath.."CAOverhaul\\GearIcon")
    button.SpecIcon.Settings:SetHighlightTexture(Addon.AwTexPath.."CAOverhaul\\GearIcon_H")

    button.SpecIcon.Settings:SetScript("OnEnter", function(self)
        if (self:IsEnabled() == 1) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:AddLine("|cffFFFFFFCustomize specialization|r")
            GameTooltip:AddLine("Click here to change icon or name of your specialization.")
            GameTooltip:Show()
        end
    end)

    button.SpecIcon.Settings:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    button.SpecIcon.Icon = button.SpecIcon:CreateTexture("$parent.SpecIcon.Icon", "ARTWORK")
    button.SpecIcon.Icon:SetTexture("Interface\\Icons\\inv_misc_book_16")
    button.SpecIcon.Icon:SetSize(36,36)
    button.SpecIcon.Icon:SetPoint("CENTER", 0, -1)
    
    button.EquipmentSet = CreateFrame("Button", "$parentEquipmentSet", button, "PopupButtonTemplate")
    button.EquipmentSet.Icon = _G[button.EquipmentSet:GetName().."Icon"]
    button.EquipmentSet.Name = _G[button.EquipmentSet:GetName().."Name"]
    button.EquipmentSet:SetSize(36, 36)
    button.EquipmentSet:SetPoint("RIGHT", 0, 4)
    button.EquipmentSet:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.EquipmentSet:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.equipmentSetName then
            GameTooltip:SetText(format("Bound Equipment Set: |cffffd100%s|r", self.equipmentSetName), 1, 1, 1)
            GameTooltip:AddLine(format("Automatically equips |cffFFFFFF%s|r when this spec is activated.", self.equipmentSetName), 1, 0.82, 0, true)
        else
            GameTooltip:SetText("Bind Equipment Set", 1, 1, 1)
            GameTooltip:AddLine("Set an equipment set to switch to when activating this specialization", 1, 0.82, 0, true)
        end
        
        GameTooltip:Show()
    end)

    button.EquipmentSet:SetScript("OnLeave", GameTooltip_Hide)

    button.EnchantPreset = CreateFrame("Button", "$parentEnchantPreset", button, "PopupButtonTemplate")
    button.EnchantPreset.Icon = _G[button.EnchantPreset:GetName().."Icon"]
    button.EnchantPreset.Name = _G[button.EnchantPreset:GetName().."Name"]
    button.EnchantPreset:SetSize(36, 36)
    button.EnchantPreset:SetPoint("RIGHT", button.EquipmentSet, "LEFT", -8, 0)
    button.EnchantPreset:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.EnchantPreset:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.presetID and MysticEnchantManagerUtil.GetPresetName(self.presetID) then
            local presetName = MysticEnchantManagerUtil.GetPresetName(self.presetID)
            GameTooltip:SetText(format("Bound Mystic Enchant Preset: |cffffd100%s|r", presetName), 1, 1, 1)
            GameTooltip:AddLine(format("Automatically apply |cffFFFFFF%s|r when this spec is activated.", presetName), 1, 0.82, 0, true)
        else
            GameTooltip:SetText("Bind Mystic Enchant Preset", 1, 1, 1)
            GameTooltip:AddLine("Set Mystic Enchant preset to switch to when activating this specialization", 1, 0.82, 0, true)
        end

        GameTooltip:Show()
    end)

    button.EnchantPreset:SetScript("OnLeave", GameTooltip_Hide)

    button.HighlightOverlay = CreateFrame("Frame", "$parentHighlightOverlay", button)
    button.HighlightOverlay:SetAllPoints()
    
    button.HighlightOverlay:SetFrameLevel(button.EnchantPreset:GetFrameLevel()+5) -- highlight above set buttons

    button.H = button.HighlightOverlay:CreateTexture("$parentH", "OVERLAY")
    button.H:SetTexture(Addon.AwTexPath.."CAOverhaul\\Gradient_Highlight")
    button.H:SetSize(256,86)
    button.H:SetPoint("CENTER", 3, 3)
    button.H:SetBlendMode("ADD")
    button.H:Hide()

    function button:EnableSpecButton()
        self:Enable()
        self.Text:SetFontObject(GameFontNormal)
        self.Text_Add:SetText("|cff00FF00Known|r")
        self.Hint = "Click to change specialization"

        self.SpecIcon.Settings:Enable()
        self.SpecIcon.Settings:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
        self.SpecIcon.Icon:SetDesaturated(false)
        self.SpecIcon.Icon:SetVertexColor(1, 1, 1, 1)
        self.KnownBorder:Hide()
        self.disabled = false
        self.EquipmentSet:Show()
        self.EnchantPreset:Show()
    end

    function button:ActiveSpecButton()
        self:Disable()
        self.Text:SetFontObject(GameFontHighlight)
        self.Text_Add:SetText("|cffFFFFFFActive|r")
        self.KnownBorder:Show()
        self.Hint = "This is your current specialization!"
        self.disabled = false
    end

    function button:DisableSpecButton()
        self:Disable()
        self.Text:SetFontObject(GameFontDisable)
        self.Text_Add:SetText("|cffFF0000Unknown|r")
        self.Hint = "Unlock this specialization by purchasing a Tome of Specialization\nThese can be bought for Donation Points at Ascension.gg/shop\nor purchased from the Auction House"

        self.SpecIcon.Settings:Disable()
        self.SpecIcon.Settings:GetNormalTexture():SetVertexColor(1, 0, 0, 1)
        self.SpecIcon.Icon:SetVertexColor(1, 0, 0, 1)
        self.KnownBorder:Hide()
        self.disabled = true
        self.EquipmentSet:Hide()
        self.EnchantPreset:Hide()
    end

    function button:SetSpecName(SpecName)
        self.Text:SetText(SpecName)
    end

    function button:SetSpecIcon(Icon)
        self.SpecIcon.Icon:SetTexture(Icon)
    end
    
    function button:SetEquipmentSet(setName)
        if setName then
            local setIcon = GetEquipmentSetInfoByName(setName)
            if setName and setIcon then
                self.EquipmentSet.equipmentSetName = setName
                self.EquipmentSet.Icon:SetTexture("Interface\\Icons\\"..setIcon)
                self.EquipmentSet.Name:SetText(setName)
            end
        else
            self.EquipmentSet.Icon:SetTexture("")
            self.EquipmentSet.Name:SetText("")
        end
    end
    
    function button:GetEquipmentSet()
        return self.EquipmentSet.equipmentSetName
    end

    function button:SetEnchantPreset(presetID)
        self.EnchantPreset.presetID = presetID
        if presetID then
            local presetName = MysticEnchantManagerUtil.GetPresetName(presetID)
            local presetIcon = MysticEnchantManagerUtil.GetPresetIcon(presetID)
            if presetName then
                self.EnchantPreset.Icon:SetTexture(presetIcon)
                self.EnchantPreset.Name:SetText(presetName)
            end
        else
            self.EnchantPreset.Icon:SetTexture("")
            self.EnchantPreset.Name:SetText("")
        end
    end

    function button:GetEnchantPreset()
        return self.EnchantPreset.presetID
    end

    return button
end

function CASpecListMixin:Create(frameName, scrollName, parent)
    self.frame = self:CreateFrame(frameName, parent)
    self.scrollFrame = self:CreateScrollFrame(scrollName, parent)


    self.scrollFrame:SetScrollChild(self.frame)

    self.frame:Hide()
    self.scrollFrame:Hide()

    self.frame:SetScript("OnShow", function()
        self:UpdateSpecButtons()
    end)

    for i = 1, #self.frame.specButtons do
        local button = self.frame.specButtons[i]
        button:SetScript("OnClick", function()
            SpecializationUtil.ActivateSpecialization(i)
        end)

        button.SpecIcon.Settings:SetScript("OnClick", function()
            self:EditBuild(i)
        end)

        button.EquipmentSet:SetScript("OnClick", function(setButton, mouseButton)
            if mouseButton == "RightButton" then
                PlaySound(SOUNDKIT.SPELL_ICON_DROP_75)
                self.frame.SelectedBuild = button:GetID()
                self:SelectEquipmentSet()
            else
                PlaySound(SOUNDKIT.CHARACTER_SHEET_OPEN_70)
                self:EditEquipmentSet(button:GetID())
            end
        end)

        button.EnchantPreset:SetScript("OnClick", function(presetButton, mouseButton)
            if mouseButton == "RightButton" then
                PlaySound(SOUNDKIT.SPELL_ICON_DROP_75)
                self.frame.SelectedBuild = button:GetID()
                self:SelectEnchantPreset()
            else
                PlaySound(SOUNDKIT.CHARACTER_SHEET_OPEN_70)
                self:EditEnchantPreset(button:GetID())
            end
        end)
    end

    return self.frame, self.scrollFrame
end

local NUM_ICONS_SHOWN = 20
local NUM_ICONS_PER_ROW = 5
local NUM_ICON_ROWS = 4
local ICON_ROW_HEIGHT = 36

--
-- Button Mixin
--
IconSelectorButtonMixin = CreateFromMixins(CallbackRegistryMixin)

function IconSelectorButtonMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:GenerateCallbackEvents({
        "OnSelectTexture",
    })
end

function IconSelectorButtonMixin:OnClick()
    self:TriggerEvent("OnSelectTexture", self:GetID())
end

--
-- Frame Mixin
--
IconSelectorFrameMixin = CreateFromMixins(CallbackRegistryMixin)

function IconSelectorFrameMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)

    self:GenerateCallbackEvents({
        "OnTextAndIconChange",
    })

    self.buttons = {}

    self.EditBox:SetScript("OnTextChanged", GenerateClosure(self.EditBoxOnTextChanged, self))
    self.EditBox:SetScript("OnEscapePressed", GenerateClosure(self.CancelEdit, self))
    self.EditBox:SetScript("OnEnterPressed", GenerateClosure(self.EditBoxOnEnterPressed, self))

    self.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        local parent = self:GetParent()
        FauxScrollFrame_OnVerticalScroll(self, offset, ICON_ROW_HEIGHT, GenerateClosure(parent.Update, parent))
    end)

    self.CancelButton:SetScript("OnClick", GenerateClosure(self.CancelEdit, self))
    self.OkayButton:SetScript("OnClick", GenerateClosure(self.OkayButtonOnClick, self))

    for i = 1, NUM_ICONS_SHOWN do
        self["Button"..i]:RegisterCallback("OnSelectTexture", self.OnSelectTexture, self)
        SetParentArray(self["Button"..i], "buttons")
    end
    
    self.getNumIcons = GetNumMacroIcons
    self.getIconInfo = GetMacroIconInfo
end

function IconSelectorFrameMixin:SetIconProvider(provider)
    self.getIconInfo = provider
end

function IconSelectorFrameMixin:SetIconCountProvider(provider)
    self.getNumIcons = provider
end

function IconSelectorFrameMixin:Update(skipEditBoxUpdate)
    local numMacroIcons = self.getNumIcons()
    local PopupIcon, PopupButton
    local PopupOffset = FauxScrollFrame_GetOffset(self.ScrollFrame)
    local index
    
    if not(skipEditBoxUpdate) then
        if ( self:GetMode() == "new" ) then
            self.EditBox:SetText("")
        end
    end
    
    -- Icon list
    local texture
    for i=1, NUM_ICONS_SHOWN do
        PopupButton = self.buttons[i]
        PopupIcon = PopupButton.Icon

        index = (PopupOffset * NUM_ICONS_PER_ROW) + i
        texture = self.getIconInfo(index)
        if ( index <= numMacroIcons ) then
            PopupIcon:SetTexture(texture)
            PopupButton:Show()
        else
            PopupIcon:SetTexture("")
            PopupButton:Hide()
        end
        if ( self:GetSelectedIcon() and (index == self:GetSelectedIcon()) ) then
            PopupButton:SetChecked(1)
        elseif ( self:GetSelectedTexture() ==  texture ) then
            PopupButton:SetChecked(1)
            self:SetSelectedIcon(index)
        else
            PopupButton:SetChecked(nil)
        end
    end
    
    -- Scrollbar stuff
    FauxScrollFrame_Update(self.ScrollFrame, ceil(numMacroIcons / NUM_ICONS_PER_ROW) , NUM_ICON_ROWS, ICON_ROW_HEIGHT )
end

function IconSelectorFrameMixin:OnSelectTexture(selectedIcon)
    self:SetSelectedIcon(selectedIcon + (FauxScrollFrame_GetOffset(self.ScrollFrame) * NUM_ICONS_PER_ROW))
    -- Clear out selected texture
    self:SetSelectedTexture(nil)
    self:OkayButtonUpdate()
    self:Update(true)
end

function IconSelectorFrameMixin:CancelEdit()
    PlaySound("gsTitleOptionOK")
    self:Hide()
    self:Update()
    self:SetSelectedIcon(nil)
end

function IconSelectorFrameMixin:EditBoxOnEnterPressed()
    if ( self.OkayButton:IsEnabled() ~= 0 ) then
        self:OkayButtonOnClick()
    end
end

function IconSelectorFrameMixin:EditBoxOnTextChanged()
    self:OkayButtonUpdate()
    --TODO: callback?
    --MacroFrameSelectedMacroName:SetText(self:GetText())
end

function IconSelectorFrameMixin:OkayButtonOnClick()
    PlaySound("gsTitleOptionOK")
    local index = 1
    
    if not(self:GetSelectedIcon()) then
        self:TriggerEvent("OnTextAndIconChange", self.EditBox:GetText(), self:GetSelectedTexture(), 1)
    else
        self:TriggerEvent("OnTextAndIconChange", self.EditBox:GetText(), self.getIconInfo(self:GetSelectedIcon()), self:GetSelectedIcon())
    end

    self:Hide()
end

function IconSelectorFrameMixin:OkayButtonUpdate()
    if ( (strlen(self.EditBox:GetText()) > 0) and self:GetSelectedIcon() ) then
        self.OkayButton:Enable()
    else
        self.OkayButton:Disable()
    end
    if ( self:GetMode() == "edit" and (strlen(self.EditBox:GetText()) > 0) ) then
        self.OkayButton:Enable()
    end
end

function IconSelectorFrameMixin:SetMode(value)
    self.mode = value
end

function IconSelectorFrameMixin:GetMode()
    return self.mode or "new"
end

function IconSelectorFrameMixin:SetSelectedIcon(value)
    self.selectedIcon = value
end

function IconSelectorFrameMixin:GetSelectedIcon()
    return self.selectedIcon
end

function IconSelectorFrameMixin:SetSelectedTexture(value)
    self.selectedIconTexture = value
end

function IconSelectorFrameMixin:GetSelectedTexture()
    return self.selectedIconTexture
end

function IconSelectorFrameMixin:OnShow()
    self.EditBox:SetFocus()

    PlaySound("igCharacterInfoOpen")
    self:Update()
    self:OkayButtonUpdate()

    if ( self:GetMode() == "new" ) then
        --TODO: Callback?
        self:OnSelectTexture(1)
    end
end

function IconSelectorFrameMixin:CreateNew()
    self:CancelEdit()
    self.EditBox:SetText("")
    self:SetMode("new")
    self:Show()
end

function IconSelectorFrameMixin:EditExisting(text, texture)
    self:CancelEdit()
    self:SetMode("edit")
    self.selectedIconTexture = texture
    self.EditBox:SetText(text)
    self:Show()
end

function IconSelectorFrameMixin:OnHide()
    -- TODO: Callback?
end
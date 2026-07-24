function EditBox_HandleTabbing(self, tabList)
    local editboxName = self:GetName();
    local index;
    for i=1, #tabList do
        if ( editboxName == tabList[i] ) then
            index = i;
            break;
        end
    end
    if ( IsShiftKeyDown() ) then
        index = index - 1;
    else
        index = index + 1;
    end

    if ( index == 0 ) then
        index = #tabList;
    elseif ( index > #tabList ) then
        index = 1;
    end

    local target = tabList[index];
    _G[target]:SetFocus();
end

function EditBox_ClearFocus (self)
    self:ClearFocus();
end

function EditBox_SetFocus (self)
    self:SetFocus();
end

function EditBox_HighlightText (self)
    self:HighlightText();
end

function EditBox_ClearHighlight (self)
    self:HighlightText(0, 0);
end

function EditBox_OnShow(self)
    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
end

function EditBox_OnHide(self)
    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
end

function EditBox_OnEvent(self, event, ...)
    if event == "GLOBAL_MOUSE_DOWN" then
        if FrameUtil.IsDialogStyleGlobalMouseDown(self) then
            self:ClearFocus()
        end
    end
end

function EditBox_OnModifierChanged(self, key, isDown)
    C_Hook:SendEvent("EDIT_BOX_MODIFIER_CHANGED", key, isDown)
end

function FatButtonTemplate_OnLoad(self)
    self:GetNormalTexture():SetAtlas("PetList-ButtonBackground", Const.TextureKit.IgnoreAtlasSize)
    self:GetHighlightTexture():SetAtlas("PetList-ButtonHighlight", Const.TextureKit.IgnoreAtlasSize)
    self:GetDisabledTexture():SetAtlas("PetList-ButtonBackground", Const.TextureKit.IgnoreAtlasSize)
    self.SelectedTexture:SetAtlas("PetList-ButtonSelect", Const.TextureKit.IgnoreAtlasSize)
end

--
-- Square Icon Button Mixin
--
SquareIconButtonMixin = {}

function SquareIconButtonMixin:OnLoad()
    local icon = self:GetAttribute("icon")
    local atlas = self:GetAttribute("icon-atlas")
    if icon then
        local flipH = self:GetAttribute("icon-mirror-h")
        local flipV = self:GetAttribute("icon-mirror-v")
        
        local left, right, top, bottom = 0, 1, 0, 1
        if flipH then
            left, right = right, left
        end

        if flipV then
            top, bottom = bottom, top
        end

        self:SetIcon(icon)
        self.Icon:SetTexCoord(left, right, top, bottom)
    elseif atlas then
        self:SetAtlas(atlas)
    end
    
    self:SetOnClickHandler(self:GetAttribute("on-click-handler"), self:GetAttribute("on-click-handler-table"))
    self:SetTooltipInfo(self:GetAttribute("tooltip-title"), self:GetAttribute("tooltip-text"))
end

function SquareIconButtonMixin:SetIcon(icon)
    self.Icon:SetTexture(icon)
end

function SquareIconButtonMixin:SetAtlas(atlas)
    self.Icon:SetAtlas(atlas)
end

function SquareIconButtonMixin:SetOnClickHandler(onClickHandler, parent)
    if not onClickHandler then
        self.onClickHandler = nil
        return
    end

    onClickHandler = _G[onClickHandler] or onClickHandler
    if parent then
        parent = parent == "parent" and self:GetParent() or _G[parent] or parent
        self.onClickHandler = function(...)
            parent[onClickHandler](parent, ...)
        end
        
        return
    end
    self.onClickHandler = onClickHandler
end

function SquareIconButtonMixin:SetTooltipInfo(tooltipTitle, tooltipText)
    if not tooltipTitle then return end

    self.tooltipTitle = _G[tooltipTitle] or tooltipTitle

    if tooltipText then
        self.tooltipText = _G[tooltipText] or tooltipText
    else
        self.tooltipText = nil
    end

    local tooltip = GameTooltip or GlueTooltip
    if tooltip:IsVisible() and tooltip:GetOwner() == self then
        self:OnLeave()
        self:OnEnter()
    end
end

function SquareIconButtonMixin:OnMouseDown()
    if self:IsEnabled() == 1 then
        -- Square icon button template still uses down-to-the-left depress behavior to match the existing art.
        self.Icon:SetPoint("CENTER", self, "CENTER", -2, -1)
    end
end

function SquareIconButtonMixin:OnMouseUp()
    self.Icon:SetPoint("CENTER", self, "CENTER", -1, 0)
end

function SquareIconButtonMixin:OnEnter()
    if self.tooltipTitle then
        local tooltip = GameTooltip or GlueTooltip
        tooltip:SetOwner(self, "ANCHOR_RIGHT", -8, -8)
        tooltip:SetText(self.tooltipTitle)

        if self.tooltipText then
            tooltip:AddLine(self.tooltipText, 1, 1, 1, true)
        end

        tooltip:Show()
    end
end

function SquareIconButtonMixin:OnLeave()
    local tooltip = GameTooltip or GlueTooltip
    tooltip:Hide()
end

function SquareIconButtonMixin:OnClick(...)
    PlaySound("igMainMenuOptionCheckBoxOn")
    if self.onClickHandler then
        self.onClickHandler(self, ...)
    end
end

function SquareIconButtonMixin:SetEnabledState(enabled)
    self:SetEnabled(enabled)
end

function SquareIconButtonMixin:OnDisable()
    self.Icon:SetDesaturated(true)
end

function SquareIconButtonMixin:OnEnable()
    self.Icon:SetDesaturated(false)
end

--
-- Instruction Input Box
--
function InputBoxInstructions_OnLoad(self)
    local disabledColor = self:GetAttribute("disabled-color")
    local enabledColor = self:GetAttribute("enabled-color")
    local instruction = self:GetAttribute("instruction")
    local instructionFont = self:GetAttribute("instruction-font")
    instruction = instruction and (_G[instruction] or instruction) or ""

    self.disabledColor = disabledColor and _G[disabledColor] or GRAY_FONT_COLOR
    self.enabledColor = enabledColor and _G[enabledColor] or HIGHLIGHT_FONT_COLOR

    if self.Left then
        self.Left:SetAtlas("common-search-border-left", Const.TextureKit.IgnoreAtlasSize)
        self.Right:SetAtlas("common-search-border-right", Const.TextureKit.IgnoreAtlasSize)
        self.Middle:SetAtlas("common-search-border-middle", Const.TextureKit.IgnoreAtlasSize)
    end

    self.Instructions:SetText(instruction)
    if instructionFont then
        self.Instructions:SetFontObject(instructionFont)
    end
end

function InputBoxInstructions_OnTextChanged(self)
    self.Instructions:SetShown(self:GetText() == "")
end

function InputBoxInstructions_UpdateColorForEnabledState(self, color)
    if color then
        self:SetTextColor(color:GetRGBA())
    end
end

function InputBoxInstructions_OnDisable(self)
    InputBoxInstructions_UpdateColorForEnabledState(self, self.disabledColor)
end

function InputBoxInstructions_OnEnable(self)
    InputBoxInstructions_UpdateColorForEnabledState(self, self.enabledColor)
end

--
-- Search Box Template
--
function SearchBoxTemplate_OnLoad(self)
    InputBoxInstructions_OnLoad(self)
    self.searchIcon:SetAtlas("common-search-magnifyingglass", Const.TextureKit.IgnoreAtlasSize)
    self.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
    self:SetTextInsets(16, 20, 0, 0)
    self.Instructions:SetText(SEARCH)
    self.Instructions:ClearAllPoints()
    self.Instructions:SetPoint("TOPLEFT", self, "TOPLEFT", 16, 0)
    self.Instructions:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -20, 0)
    self.focusCommand = KeyCommand_Create(function() if self:IsVisible() then EditBox_SetFocus(self) end end, KeyCommand.RUN_ON_UP, KeyCommand_CreateKey("CTRL", "F"))
    self.allowHotkeys = true
    
    self.modifierCommands = {
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "SHIFT", 1) end, KeyCommand.RUN_ON_DOWN, KeyCommand_CreateKey("SHIFT")),
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "SHIFT", 0) end, KeyCommand.RUN_ON_UP, KeyCommand_CreateKey("SHIFT")),
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "CTRL", 1) end, KeyCommand.RUN_ON_DOWN, KeyCommand_CreateKey("CTRL")),
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "CTRL", 0) end, KeyCommand.RUN_ON_UP, KeyCommand_CreateKey("CTRL")),
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "ALT", 1) end, KeyCommand.RUN_ON_DOWN, KeyCommand_CreateKey("ALT")),
        KeyCommand_Create(function() EditBox_OnModifierChanged(self, "ALT", 0) end, KeyCommand.RUN_ON_UP, KeyCommand_CreateKey("ALT")),
    }
end

function SearchBoxTemplate_EnableHotkeys(self)
    self.allowHotkeys = true
end

function SearchBoxTemplate_DisableHotkeys(self)
    self.allowHotkeys = false
end

function SearchBoxTemplate_OnEditFocusLost(self)
    if ( self:GetText() == "" ) then
        self.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
        self.clearButton:Hide()
    end
end

function SearchBoxTemplate_OnEditFocusGained(self)
    self.searchIcon:SetVertexColor(1.0, 1.0, 1.0)
    self.clearButton:Show()
end

function SearchBoxTemplate_OnTextChanged(self)
    if ( not self:HasFocus() and self:GetText() == "" ) then
        self.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
        self.clearButton:Hide()
    else
        self.searchIcon:SetVertexColor(1.0, 1.0, 1.0)
        self.clearButton:Show()
    end
    InputBoxInstructions_OnTextChanged(self)
end

function SearchBoxTemplate_OnUpdate(self)
    if self.allowHotkeys then
        KeyCommand_Update(self.focusCommand)
    end
    KeyCommand_Update(self.modifierCommands)
end

function SearchBoxTemplateClearButton_OnClick(self)
    PlaySound("igMainMenuOptionCheckBoxOn")
    local editBox = self:GetParent()
    editBox:SetText("")
    editBox:ClearFocus()
end

--
-- UI Button Mixin
--
UIButtonMixin = {}
function UIButtonMixin:OnLoad()
    self:OnAttributeChanged()
end

function UIButtonMixin:OnAttributeChanged()
    self.atlasName = self:GetAttribute("atlasName") or ""
    self.tooltip = self:GetAttribute("tooltip")
    self.desaturate = self:GetAttribute("desaturate")
end

function UIButtonMixin:InitButton()
    self:SetNormalAtlas(self.atlasName)
    self:GetNormalTexture():SetDesaturated(self.desaturate)
    self:SetPushedAtlas(self.atlasName.."-Pressed")
    self:GetPushedTexture():SetDesaturated(self.desaturate)
    self:SetDisabledAtlas(self.atlasName.."-Disabled")
    self:GetDisabledTexture():SetDesaturated(self.desaturate)
    self:SetHighlightAtlas(self.atlasName.."-Highlight")
    self:GetHighlightTexture():SetDesaturated(self.desaturate)
    if self.SetCheckedAtlas then
        self:SetCheckedAtlas(self.atlasName.."-Checked")
        self:GetCheckedTexture():SetDesaturated(self.desaturate)
    end
end

function UIButtonMixin:GetAppropriateTooltip()
    return GameTooltip or GlueTooltip
end

function UIButtonMixin:OnEnter()
    local tooltipText = self.tooltip
    if tooltipText then
        local tooltip = self:GetAppropriateTooltip()
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
        tooltip:SetText(tooltipText)
    end
end

function UIButtonMixin:OnLeave()
    local tooltip = self:GetAppropriateTooltip()
    tooltip:Hide()
end

--
-- Three Slice Button Mixin
--
ThreeSliceButtonMixin = CreateFromMixins(UIButtonMixin)

function ThreeSliceButtonMixin:OnAttributeChanged()
    UIButtonMixin.OnAttributeChanged(self)
    self.useThreeSliceHighlight = self:GetAttribute("useThreeSliceHighlight")

    if self.useThreeSliceHighlight and not self.LeftHighlight then
        self.CenterHighlight = self:CreateTexture("$parentCenterHighlight", "HIGHLIGHT")
        self.LeftHighlight = self:CreateTexture("$parentLeftHighlight", "HIGHLIGHT")
        self.RightHighlight = self:CreateTexture("$parentRightHighlight", "HIGHLIGHT")
        self.CenterHighlight:SetBlendMode("ADD")
        self.LeftHighlight:SetBlendMode("ADD")
        self.RightHighlight:SetBlendMode("ADD")
        self.LeftHighlight:SetPoint("TOPLEFT", self.Left, "TOPLEFT")
        self.LeftHighlight:SetPoint("BOTTOMRIGHT", self.Left, "BOTTOMRIGHT")
        self.RightHighlight:SetPoint("TOPLEFT", self.Right, "TOPLEFT")
        self.RightHighlight:SetPoint("BOTTOMRIGHT", self.Right, "BOTTOMRIGHT")
        self.CenterHighlight:SetPoint("TOPLEFT", self.Center, "TOPLEFT")
        self.CenterHighlight:SetPoint("BOTTOMRIGHT", self.Center, "BOTTOMRIGHT")
    end
end

function ThreeSliceButtonMixin:GetLeftAtlasName()
    return self.atlasName.."-Left"
end

function ThreeSliceButtonMixin:GetRightAtlasName()
    return self.atlasName.."-Right"
end

function ThreeSliceButtonMixin:GetCenterAtlasName()
    return "_"..self.atlasName.."-Center"
end

function ThreeSliceButtonMixin:GetHighlightAtlasName()
    return self.atlasName.."-Highlight"
end

function ThreeSliceButtonMixin:InitButton()
    self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName())
    self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName())

    if not self.useThreeSliceHighlight then
        local highlightAtlasName = self:GetHighlightAtlasName()
        self:SetHighlightAtlas(highlightAtlasName)
    else
        self.leftHighlightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName().."-Highlight")
        self.rightHighlightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName().."-Highlight")
        self:SetHighlightTexture(nil)
    end
end

function ThreeSliceButtonMixin:UpdateScale()
    local buttonHeight = self:GetHeight()
    local buttonWidth = self:GetWidth()
    local scale = buttonHeight / self.leftAtlasInfo.height
    self.Left:SetHeight(self.leftAtlasInfo.height * scale)
    self.Right:SetHeight(self.rightAtlasInfo.height * scale)

    local leftWidth = self.leftAtlasInfo.width * scale
    local rightWidth = self.rightAtlasInfo.width * scale
    local leftAndRightWidth = leftWidth + rightWidth

    if leftAndRightWidth > buttonWidth then
        -- At the current buttonHeight, the left and right textures are too big to fit within the button width
        -- So slice some width off of the textures and adjust texture coords accordingly
        local extraWidth = leftAndRightWidth - buttonWidth
        local newLeftWidth = leftWidth
        local newRightWidth = rightWidth

        -- If one of the textures is sufficiently larger than the other one, we can remove all of the width from there
        if (leftWidth - extraWidth) > rightWidth then
            -- left is big enough to take the whole thing...deduct it all from there
            newLeftWidth = leftWidth - extraWidth
        elseif (rightWidth - extraWidth) > leftWidth then
            -- right is big enough to take the whole thing...deduct it all from there
            newRightWidth = rightWidth - extraWidth
        else
            -- neither side is sufficiently larger than the other to take the whole extra width
            if leftWidth ~= rightWidth then
                -- so set both widths equal to the smaller size and subtract the difference from extraWidth
                local unevenAmount = math.abs(leftWidth - rightWidth)
                extraWidth = extraWidth - unevenAmount
                newLeftWidth = math.min(leftWidth, rightWidth)
                newRightWidth = newLeftWidth
            end
            -- newLeftWidth and newRightWidth are now equal and we just need to remove half of extraWidth from each
            local equallyDividedExtraWidth = extraWidth / 2
            newLeftWidth = newLeftWidth - equallyDividedExtraWidth
            newRightWidth = newRightWidth - equallyDividedExtraWidth
        end

        -- Now set the tex coords and widths of both textures
        
        local leftPercentage = newLeftWidth / leftWidth
        self.Left:SetTexCoord(self.leftAtlasInfo.leftTexCoord, self.leftAtlasInfo.rightTexCoord, self.leftAtlasInfo.topTexCoord, self.leftAtlasInfo.bottomTexCoord)
        self.Left:ScaleTexCoord(0, leftPercentage, 0, 1)
        self.Left:SetWidth(newLeftWidth)
        if self.LeftHighlight then
            self.LeftHighlight:SetTexCoord(self.leftHighlightAtlasInfo.leftTexCoord, self.leftHighlightAtlasInfo.rightTexCoord, self.leftHighlightAtlasInfo.topTexCoord, self.leftHighlightAtlasInfo.bottomTexCoord)
            self.LeftHighlight:ScaleTexCoord(0, leftPercentage, 0, 1)
        end

        local rightPercentage = newRightWidth / rightWidth
        self.Right:SetTexCoord(self.rightAtlasInfo.leftTexCoord, self.rightAtlasInfo.rightTexCoord, self.rightAtlasInfo.topTexCoord, self.rightAtlasInfo.bottomTexCoord)
        self.Right:ScaleTexCoord(1 - rightPercentage, 1, 0, 1)
        self.Right:SetWidth(newRightWidth)
        if self.RightHighlight then
            self.RightHighlight:SetTexCoord(self.rightHighlightAtlasInfo.leftTexCoord, self.rightHighlightAtlasInfo.rightTexCoord, self.rightHighlightAtlasInfo.topTexCoord, self.rightHighlightAtlasInfo.bottomTexCoord)
            self.RightHighlight:ScaleTexCoord(1 - rightPercentage, 1, 0, 1)
        end
    else
        self.Left:SetTexCoord(self.leftAtlasInfo.leftTexCoord, self.leftAtlasInfo.rightTexCoord, self.leftAtlasInfo.topTexCoord, self.leftAtlasInfo.bottomTexCoord)
        self.Left:SetWidth(leftWidth)
        if self.LeftHighlight then
            self.LeftHighlight:SetTexCoord(self.leftHighlightAtlasInfo.leftTexCoord, self.leftHighlightAtlasInfo.rightTexCoord, self.leftHighlightAtlasInfo.topTexCoord, self.leftHighlightAtlasInfo.bottomTexCoord)
        end
        self.Right:SetTexCoord(self.rightAtlasInfo.leftTexCoord, self.rightAtlasInfo.rightTexCoord, self.rightAtlasInfo.topTexCoord, self.rightAtlasInfo.bottomTexCoord)
        if self.RightHighlight then
            self.RightHighlight:SetTexCoord(self.rightHighlightAtlasInfo.leftTexCoord, self.rightHighlightAtlasInfo.rightTexCoord, self.rightHighlightAtlasInfo.topTexCoord, self.rightHighlightAtlasInfo.bottomTexCoord)
        end
        self.Right:SetWidth(rightWidth)
    end
end

function ThreeSliceButtonMixin:UpdateButton(buttonState)
    buttonState = buttonState or self:GetButtonState()
    
    if self:IsEnabled() ~= 1 then
        buttonState = "DISABLED"
    end

    local atlasNamePostfix = ""
    if buttonState == "DISABLED" then
        if self.GetChecked and self:GetChecked() then
            atlasNamePostfix = "-Checked"
        else
            atlasNamePostfix = "-Disabled"
        end
    elseif buttonState == "PUSHED" then
        if self.GetChecked and self:GetChecked() then
            atlasNamePostfix = "-Checked-Pressed"
        else
            atlasNamePostfix = "-Pressed"
        end
    elseif buttonState == "NORMAL" and self.GetChecked then
        if self:GetChecked() then
            atlasNamePostfix = "-Checked"
        end
    end

    local useAtlasSize = true
    self.Left:SetAtlas(self:GetLeftAtlasName()..atlasNamePostfix, useAtlasSize)
    self.Center:SetAtlas(self:GetCenterAtlasName()..atlasNamePostfix)
    self.Right:SetAtlas(self:GetRightAtlasName()..atlasNamePostfix, useAtlasSize)

    if self.useThreeSliceHighlight then
        if self.CenterHighlight then
            self.CenterHighlight:SetAtlas(self:GetCenterAtlasName().."-Highlight", Const.TextureKit.IgnoreAtlasSize)
        end

        if self.LeftHighlight then
            self.LeftHighlight:SetAtlas(self:GetLeftAtlasName().."-Highlight", useAtlasSize)
        end

        if self.RightHighlight then
            self.RightHighlight:SetAtlas(self:GetRightAtlasName().."-Highlight", useAtlasSize)
        end
    else
        self:SetHighlightAtlas(self:GetHighlightAtlasName())
    end

    self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName()..atlasNamePostfix)
    self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName()..atlasNamePostfix)

    self.Left:SetDesaturated(self.desaturate)
    self.Center:SetDesaturated(self.desaturate)
    self.Right:SetDesaturated(self.desaturate)
    self:UpdateScale()
end

function ThreeSliceButtonMixin:OnMouseDown()
    self:UpdateButton("PUSHED")
end

function ThreeSliceButtonMixin:OnMouseUp()
    self:UpdateButton("NORMAL")
end

CustomColorThreeSliceButtonMixin = CreateFromMixins(ThreeSliceButtonMixin)
CustomColorThreeSliceButtonMixin.Color = CreateColor(1, 1, 1)

function CustomColorThreeSliceButtonMixin:UpdateButton(buttonState)
    buttonState = buttonState or self:GetButtonState()

    if self:IsEnabled() ~= 1 then
        buttonState = "DISABLED"
        self.Left:SetVertexColor(1, 1, 1, 1)
        self.Center:SetVertexColor(1, 1, 1, 1)
        self.Right:SetVertexColor(1, 1, 1, 1)
        self:GetHighlightTexture():SetVertexColor(1, 1, 1, 1)
    else
        self.Left:SetVertexColor(self.Color:GetRGBA())
        self.Center:SetVertexColor(self.Color:GetRGBA())
        self.Right:SetVertexColor(self.Color:GetRGBA())
        self:GetHighlightTexture():SetVertexColor(self.Color:GetRGBA())
    end

    local atlasNamePostfix = ""
    if buttonState == "DISABLED" then
        atlasNamePostfix = "-Disabled"
    elseif buttonState == "PUSHED" then
        atlasNamePostfix = "-Pressed"
    end

    local useAtlasSize = true
    self.Left:SetAtlas(self:GetLeftAtlasName()..atlasNamePostfix, useAtlasSize)
    self.Center:SetAtlas(self:GetCenterAtlasName()..atlasNamePostfix)
    self.Right:SetAtlas(self:GetRightAtlasName()..atlasNamePostfix, useAtlasSize)

    self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetLeftAtlasName()..atlasNamePostfix)
    self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self:GetRightAtlasName()..atlasNamePostfix)

    self:UpdateScale()
end

function CustomColorThreeSliceButtonMixin:SetColor(color, ...)
    if type(color) == "number" then
        color = CreateColor(color, ...)
    end
    
    self.Color = color

    if self:IsEnabled() == 1 then
        self.Left:SetVertexColor(self.Color:GetRGBA())
        self.Center:SetVertexColor(self.Color:GetRGBA())
        self.Right:SetVertexColor(self.Color:GetRGBA())
    end
end

-- Allows inheriting buttons to override OnLoad and OnShow
ButtonControllerMixin = {}

function ButtonControllerMixin:OnLoad()
    if self:GetParent().InitButton then
        self:GetParent():InitButton()
    end
end

function ButtonControllerMixin:OnShow()
    if self:GetParent().UpdateButton then
        self:GetParent():UpdateButton()
    end
end

SecureBasicAttributeHandlerMixin = {}

function SecureBasicAttributeHandlerMixin:SecureSetValues(attribute, values)
    if not attribute or not values then return end

    if type(values) ~= "table" then
        return
    end

    attribute = attribute:lower()
    self:ClearValues(attribute)

    for k, v in pairs(values) do
        local name = k:lower()
        local value = v
        if type(v) == "table" then
            value = "__JSON__" .. C_Serialize:ToJSON(v)
        end
        self:SetAttribute(attribute .. "-" .. k, value)
    end
    
    self:SetAttribute(attribute.."-update", true)
end

function SecureBasicAttributeHandlerMixin:SecureSetValue(attribute, key, value)
    if not attribute or not key then return end
    key = key:lower()
    attribute = attribute:lower()
    self:ClearValues(attribute)

    local v = value
    if type(v) == "table" then
        v = "__JSON__" .. C_Serialize:ToJSON(v)
    end
    
    self:SetAttribute(attribute .. "-" .. key, v)
    self:SetAttribute(attribute.."-update", true)
end

function SecureBasicAttributeHandlerMixin:ClearValues(attribute)
    self:SetAttribute(attribute:lower() .. "-wipe", true)
end

function SecureBasicAttributeHandlerMixin:OnAttributeChanged(name, value)
    local attribute, key = name:match("([%w_]*)%-([%w_]*)")
    
    if not attribute or not key then return end

    if key == "update" then
        local attr = attribute:upper()
        if self[attr.."_Update"] then
            self[attr.."_Update"](self, self[attribute])
        end
    elseif key == "wipe" then
        if self[attribute] then
            wipe(self[attribute])
        end
    else
        self[attribute] = self[attribute] or {}
        if value and type(value) == "string" and value:sub(1, 8) == "__JSON__" then
            self[attribute][key] = C_Serialize:FromJSON(value:sub(9))
        end
        self[attribute][key] = value
    end
end


--
-- Basic Scroll Mixin
--
BasicSharedScrollMixin = {}

function BasicSharedScrollMixin:OnLoad()
    self.ScrollBar.DownButton:Disable()
    self.ScrollBar.UpButton:Disable()
    self:UpdateScrollView()
end

function BasicSharedScrollMixin:OnVerticalScroll(offset)
    self.ScrollBar:SetValue(offset)
    self:UpdateScrollView()
end

function BasicSharedScrollMixin:OnMouseWheel(delta)
    self.ScrollBar:SetValue(self.ScrollBar:GetValue() - delta * 6)

end

function BasicSharedScrollMixin:UpdateScrollView()
    self.scrollBarHideable = self.scrollBarHideable or self:GetAttribute("scroll-bar-hideable")
    self.neverShowScroll = self.neverShowScroll or self:GetAttribute("never-show-scroll")

    local yrange = max(0, self:GetScrollChild():GetHeight() - self:GetHeight())

    local value = self.ScrollBar:GetValue()

    value = math.clamp(value, 0, yrange)

    self.ScrollBar:SetMinMaxValues(0, yrange)
    self.ScrollBar:SetValue(value)

    local range = floor(yrange)

    local show = true

    if range == 0 and self.scrollBarHideable then
        show = false
    end

    if show and self.neverShowScroll then
        show = false
    end

    self.ScrollBar:SetShown(show)
    self.ScrollBar.UpButton:SetShown(show)
    self.ScrollBar.DownButton:SetShown(show)
    self.ScrollBar.UpButton:SetEnabled(value > 0 and range > 0)
    self.ScrollBar.DownButton:SetEnabled(value < range and range > 0)
end

--
-- Stretch Button Template
--
UIMenuButtonStretchMixin = {}

function UIMenuButtonStretchMixin:SetTextures(texture)
    self.TopLeft:SetTexture(texture)
    self.TopRight:SetTexture(texture)
    self.BottomLeft:SetTexture(texture)
    self.BottomRight:SetTexture(texture)
    self.TopMiddle:SetTexture(texture)
    self.MiddleLeft:SetTexture(texture)
    self.MiddleRight:SetTexture(texture)
    self.BottomMiddle:SetTexture(texture)
    self.MiddleMiddle:SetTexture(texture)
end

function UIMenuButtonStretchMixin:OnMouseDown()
    if self:IsEnabled() == 1 then
        self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Down")
        if self.Icon then
            self.Icon:SetPointOffset(1, -1)
        end
    end
end

function UIMenuButtonStretchMixin:OnMouseUp()
    if self:IsEnabled() == 1 then
        self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up")
        if self.Icon then
            self.Icon:SetPointOffset(0, 0)
        end
    end
end

function UIMenuButtonStretchMixin:OnShow()
    -- we need to reset our textures just in case we were hidden before a mouse up fired
    self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up")
end

function UIMenuButtonStretchMixin:OnEnable()
    self:SetTextures("Interface\\Buttons\\UI-Silver-Button-Up")
end

function UIMenuButtonStretchMixin:OnEnter()
    if self.tooltipText ~= nil then
        local tooltip = GameTooltip or GlueTooltip
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
        tooltip:SetText(self.tooltipText)
        tooltip:Show()
    end
end

function UIMenuButtonStretchMixin:OnLeave()
    if self.tooltipText ~= nil then
        local tooltip = GameTooltip or GlueTooltip
        tooltip:Hide()
    end
end

--
-- Better Status Bar Mixin
--
BetterStatusBarMixin = {
    minValue = 0,
    maxValue = 100,
    value = 0,
}

function BetterStatusBarMixin:OnLoad()
    if self:GetAttribute("bar-texture") and strlen(self:GetAttribute("bar-texture")) > 0 then
        self:SetStatusBarTexture(self:GetAttribute("bar-texture"))
    elseif self:GetAttribute("bar-atlas") and strlen(self:GetAttribute("bar-atlas")) > 0 then
        self:SetStatusBarAtlas(self:GetAttribute("bar-atlas"))
    end

    if self:GetAttribute("bar-color") and strlen(self:GetAttribute("bar-color")) > 0 then
        local r, g, b, a = string.split(",", self:GetAttribute("bar-color"):gsub("%s*", ""))
        r = tonumber(r)
        g = tonumber(g)
        b = tonumber(b)
        a = tonumber(a)
        if r and g and b then
            self:SetStatusBarColor(r, g, b, a or 1)
        end
    end

    if self:GetAttribute("background-texture") and strlen(self:GetAttribute("background-texture")) > 0 then
        self:SetBackgroundTexture(self:GetAttribute("background-texture"))
    elseif self:GetAttribute("background-atlas") and strlen(self:GetAttribute("background-atlas")) > 0 then
        self:SetBackgroundAtlas(self:GetAttribute("background-atlas"))
    end

    if self:GetAttribute("spark-texture") and strlen(self:GetAttribute("spark-texture")) > 0 then
        self:SetSparkTexture(self:GetAttribute("spark-texture"))
    elseif self:GetAttribute("spark-atlas") and strlen(self:GetAttribute("spark-atlas")) > 0 then
        self:SetSparkAtlas(self:GetAttribute("spark-atlas"), true)
    end

    self:SetText(self:GetAttribute("text"))

    if self:GetAttribute("font") then
        self:SetFontObject(self:GetAttribute("font"))
    end
end 

function BetterStatusBarMixin:Update()
    local percent = self:GetPercentage()

    if percent == 0 then
        self.Spark:Hide()
        self.BarTexture:Hide()
        return
    elseif not self.BarTexture:IsShown() then
        self.BarTexture:Show()
    end

    local left, right, top, bottom

    if self.flipbook then
        left = self.barAtlas.leftTexCoord
        right = math.RemapToRange(1-percent, 0, 1, left, left + self.flipbook.CoordWidth)
        self.flipbook:SetCoordInsets(0, right, 0, 0)
        self.flipbook:Update(self.flipbook.fps)
    elseif self.barAtlas then
        local a = self.barAtlas
        left, right, top, bottom = a.leftTexCoord, a.rightTexCoord, a.topTexCoord, a.bottomTexCoord
        right = math.RemapToRange(percent, 0, 1, left, right)
        self.BarTexture:SetTexCoord(left, right, top, bottom)
    else
        left, right, top, bottom = 0, percent, 0, 1
        self.BarTexture:SetTexCoord(left, right, top, bottom)
    end

    if percent == 1 then
        self.BarTexture:SetPoint("RIGHT")
        self.Spark:Show()
        return
    end

    if not self:GetRight() or not self:GetLeft() then return end

    local width = self:GetRight() - self:GetLeft()
    right = width * (1 - percent)
    
    self.BarTexture:SetPoint("RIGHT", self, "RIGHT", -right, 0)

    -- should probably crop this properly some day
    if width * percent < self.Spark:GetWidth() then
        self.Spark:Hide()
    else
        self.Spark:Show()
    end
end 

function BetterStatusBarMixin:SetStatusBarTexture(...)
    self.BarTexture:SetTexCoord(0, 1, 0, 1)
    self.barAtlas = nil
    self.BarTexture:SetTexture(...)
end

function BetterStatusBarMixin:SetStatusBarAtlas(atlas)
    self.BarTexture:SetAtlas(atlas)
    self.barAtlas = AtlasUtil:GetAtlasInfo(atlas)
end

function BetterStatusBarMixin:SetStatusBarFlipbookAtlas(atlas, frameWidth, frameHeight, frameCount, fps, oneShot)
    self:SetStatusBarAtlas(atlas)
    self.flipbook = C_Flipbook:CreateAtlasFlipbook(self.BarTexture, atlas, frameWidth, frameHeight, frameCount, fps, oneShot)
end

function BetterStatusBarMixin:PlayFlipbook()
    if self.flipbook then
        self.flipbook:Play()
    end
end

function BetterStatusBarMixin:GetStatusBarAtlas()
    return self.barAtlas and self.BarTexture.atlas
end

function BetterStatusBarMixin:SetStatusBarColor(r, g, b, a)
    self.BarTexture:SetVertexColor(r, g, b, a)
end

function BetterStatusBarMixin:SetBackgroundTexture(...)
    self.Background:SetTexCoord(0, 1, 0, 1)
    self.backgroundAtlas = nil
    self.Background:SetTexture(...)
end

function BetterStatusBarMixin:SetBackgroundAtlas(atlas)
    self.Background:SetAtlas(atlas)
    self.backgroundAtlas = AtlasUtil:GetAtlasInfo(atlas)
end

function BetterStatusBarMixin:SetBackgroundColor(r, g, b, a)
    self.Background:SetVertexColor(r, g, b, a)
end

function BetterStatusBarMixin:SetSparkTexture(...)
    self.Spark:SetTexture(...)
    self.sparkAtlas = nil
end

function BetterStatusBarMixin:SetSparkAtlas(atlas, useAtlasSize)
    self.Spark:SetAtlas(atlas, useAtlasSize)
    self.sparkAtlas = AtlasUtil:GetAtlasInfo(atlas)
end

function BetterStatusBarMixin:SetSparkSize(width, height)
    self.Spark:SetSize(width, height)
end

function BetterStatusBarMixin:SetSparkWidth(width)
    self.Spark:SetWidth(width)
end

function BetterStatusBarMixin:SetSparkHeight(height)
    self.Spark:SetHeight(height)
end

function BetterStatusBarMixin:SetSparkPoint(point, relativePoint, x, y)
    self.Spark:ClearAndSetPoint(point, self.BarTexture, relativePoint or point, x or 0, y or 0)
end

function BetterStatusBarMixin:SetSparkColor(r, g, b, a)
    self.Spark:SetVertexColor(r, g, b, a)
end

function BetterStatusBarMixin:SetText(text)
    self.Text:SetText(text)
end 

function BetterStatusBarMixin:SetFormattedText(...)
    self.Text:SetFormattedText(...)
end

function BetterStatusBarMixin:SetFontObject(font)
    self.Text:SetFontObject(font)
end

function BetterStatusBarMixin:SetTextColor(r, g, b, a)
    self.Text:SetVertexColor(r,g, b, a)
end

function BetterStatusBarMixin:SetValue(value)
    if self.value == value then
        self:Update()
        return
    end

    self.value = math.clamp(value, self.minValue, self.maxValue)
    self:Update()
    if self.OnValueChanged then
        self:OnValueChanged(value)
    end
end

function BetterStatusBarMixin:SetMinMaxValues(minValue, maxValue)
    if self.minValue == minValue and self.maxValue == maxValue then return end
    self.minValue = minValue
    self.maxValue = maxValue
    self:Update()
    if self.OnMinMaxValuesChanged then
        self:OnMinMaxValuesChanged(minValue, maxValue)
    end
end

function BetterStatusBarMixin:GetValue()
    return self.value
end

function BetterStatusBarMixin:GetMinMaxValues()
    return self.minValue, self.maxValue
end

function BetterStatusBarMixin:GetPercentage()
    return math.clamp(math.RemapToRange(self.value, self.minValue, self.maxValue, 0, 1), 0, 1)
end

function FactionFrameTemplate_SetFaction(self, faction)
    self.NineSlice:SetLayout(faction.."FrameLayout")
    self.Header:SetAtlas("UI-Frame-"..faction.."-Header", Const.TextureKit.UseAtlasSize)
    self.Background:SetTexture("Interface\\FrameGeneral\\UIFrame"..faction.."Background", true)

    if faction == "Horde" then
        self.Header:SetPoint("CENTER", self, "TOP", 0, 0)
    else
        self.Header:SetPoint("CENTER", self, "TOP", 0, 39)
    end
end

function FactionFrameTemplate_SetToPlayerFaction(self)
    local faction = UnitFactionGroup("player")
    FactionFrameTemplate_SetFaction(self, faction)
end

function SettingsGearButtonTemplate_OnLoad(self)
    self:SetNormalAtlas("mechagon-projects")
    self:SetHighlightAtlas("mechagon-projects")
end

function ReadOnlyEditBox_OnLoad(self)
    self._text = ""
end

function ReadOnlyEditBox_OnTextSet(self)
    self._text = self:GetText()
end

function ReadOnlyEditBox_OnTextChanged(self)
    if self._text then
        self:SetText(self._text)
        EditBox_ClearFocus(self)
    end
end

--
-- Expand Collapse Button
--
ExpandCollapseButtonMixin = CreateFromMixins(CallbackRegistryMixin)

function ExpandCollapseButtonMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self.expanded = true
    self:GenerateCallbackEvents({ "OnStateChanged" })
end

function ExpandCollapseButtonMixin:UpdateTexture()
    self:GetNormalTexture():SetTexture(self.expanded and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    self:GetPushedTexture():SetTexture(self.expanded and "Interface\\Buttons\\UI-MinusButton-Down" or "Interface\\Buttons\\UI-PlusButton-Down")
end

function ExpandCollapseButtonMixin:IsExpanded()
    return self.expanded
end

function ExpandCollapseButtonMixin:SetExpanded(expanded, triggerUpdate)
    if self.expanded == expanded then return end
    self.expanded = expanded
    self:UpdateTexture()
    if triggerUpdate then
        self:TriggerEvent("OnStateChanged", self.expanded)
    end
end

function ExpandCollapseButtonMixin:OnClick()
    self:SetExpanded(not self:IsExpanded(), true)
end

--
-- Basic Frame
--
function BasicFrame_SetTitle(self, title)
    self.TitleText:SetText(title)
end

--
-- Portrait Frame
--
function PortraitFrame_SetClassIcon(self, class)
    local portrait
    if self.PortraitFrame then
        portrait = self.PortraitFrame.portrait
    else
        portrait = self.portrait
    end
    portrait:SetTexture("Interface\\Glues\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES-ROUND")
    portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS_ROUND[class]))
end

function PortraitFrame_SetIcon(self, icon)
    if self.PortraitFrame then
        self.PortraitFrame.portrait:SetPortraitTexture(icon)
    else
        self.portrait:SetPortraitTexture(icon)
    end
end

function PortraitFrame_SetUnitPortrait(self, unit) 
    if self.PortraitFrame then
        self.PortraitFrame.portrait:SetPortraitUnit(unit)
    else
        self.portrait:SetPortraitUnit(unit)
    end
end

PortraitFrame_SetTitle = BasicFrame_SetTitle

CollapsibleButtonMixin = {}

function CollapsibleButtonMixin:OnLoad()
    self.Left:SetAtlas("collapse-button-left", Const.TextureKit.IgnoreAtlasSize)
    self.Right:SetAtlas("collapse-button-right", Const.TextureKit.IgnoreAtlasSize)
    self.Middle:SetAtlas("collapse-button-middle", Const.TextureKit.IgnoreAtlasSize)
end

function CollapsibleButtonMixin:OnDisable()
    self.Left:SetDesaturated(true)
    self.Right:SetDesaturated(true)
    self.Middle:SetDesaturated(true)
end

function CollapsibleButtonMixin:OnEnable()
    self.Left:SetDesaturated(false)
    self.Right:SetDesaturated(false)
    self.Middle:SetDesaturated(false)
end

function CollapsibleButtonMixin:SetIsCollapsed(isCollapsed)
    self.ExpandOrCollapseIcon:SetTexCoord(isCollapsed and 0 or 0.5, isCollapsed and 0.5 or 1, 0, 0.5)
end

--
-- Three Slice Template
--
ThreeSliceMixin = {}

function ThreeSliceMixin:OnLoad()
    self:OnAttributeChanged()
end

function ThreeSliceMixin:OnAttributeChanged()
    self.atlasName = self:GetAttribute("atlasName")
    if self.atlasName then
        self.leftAtlasInfo = AtlasUtil:GetAtlasInfo(self.atlasName.."-Left")
        self.rightAtlasInfo = AtlasUtil:GetAtlasInfo(self.atlasName.."-Right")
        self.centerAtlasInfo = AtlasUtil:GetAtlasInfo("_"..self.atlasName.."-Center")
        
        self.Left:SetAtlas(self.atlasName.."-Left", Const.TextureKit.UseAtlasSize)
        self.Right:SetAtlas(self.atlasName.."-Right", Const.TextureKit.UseAtlasSize)
        self.Center:SetAtlas("_"..self.atlasName.."-Center", Const.TextureKit.UseAtlasSize)
        self:RefreshTexture()
    end
end

function ThreeSliceMixin:OnSizeChanged()
    self:RefreshTexture()
end

function ThreeSliceMixin:RefreshTexture()
    local buttonHeight = self:GetHeight()
    local buttonWidth = self:GetWidth()
    local scale = buttonHeight / self.leftAtlasInfo.height
    self.Left:SetHeight(self.leftAtlasInfo.height * scale)
    self.Right:SetHeight(self.rightAtlasInfo.height * scale)

    local leftWidth = self.leftAtlasInfo.width * scale
    local rightWidth = self.rightAtlasInfo.width * scale
    local leftAndRightWidth = leftWidth + rightWidth

    if leftAndRightWidth > buttonWidth then
        -- At the current buttonHeight, the left and right textures are too big to fit within the button width
        -- So slice some width off of the textures and adjust texture coords accordingly
        local extraWidth = leftAndRightWidth - buttonWidth
        local newLeftWidth = leftWidth
        local newRightWidth = rightWidth

        -- If one of the textures is sufficiently larger than the other one, we can remove all of the width from there
        if (leftWidth - extraWidth) > rightWidth then
            -- left is big enough to take the whole thing...deduct it all from there
            newLeftWidth = leftWidth - extraWidth
        elseif (rightWidth - extraWidth) > leftWidth then
            -- right is big enough to take the whole thing...deduct it all from there
            newRightWidth = rightWidth - extraWidth
        else
            -- neither side is sufficiently larger than the other to take the whole extra width
            if leftWidth ~= rightWidth then
                -- so set both widths equal to the smaller size and subtract the difference from extraWidth
                local unevenAmount = math.abs(leftWidth - rightWidth)
                extraWidth = extraWidth - unevenAmount
                newLeftWidth = math.min(leftWidth, rightWidth)
                newRightWidth = newLeftWidth
            end
            -- newLeftWidth and newRightWidth are now equal and we just need to remove half of extraWidth from each
            local equallyDividedExtraWidth = extraWidth / 2
            newLeftWidth = newLeftWidth - equallyDividedExtraWidth
            newRightWidth = newRightWidth - equallyDividedExtraWidth
        end

        -- Now set the tex coords and widths of both textures

        local leftPercentage = newLeftWidth / leftWidth
        self.Left:SetTexCoord(self.leftAtlasInfo.leftTexCoord, self.leftAtlasInfo.rightTexCoord, self.leftAtlasInfo.topTexCoord, self.leftAtlasInfo.bottomTexCoord)
        self.Left:ScaleTexCoord(0, leftPercentage, 0, 1)
        self.Left:SetWidth(newLeftWidth)

        local rightPercentage = newRightWidth / rightWidth
        self.Right:SetTexCoord(self.rightAtlasInfo.leftTexCoord, self.rightAtlasInfo.rightTexCoord, self.rightAtlasInfo.topTexCoord, self.rightAtlasInfo.bottomTexCoord)
        self.Right:ScaleTexCoord(1 - rightPercentage, 1, 0, 1)
        self.Right:SetWidth(newRightWidth)
    else
        self.Left:SetTexCoord(self.leftAtlasInfo.leftTexCoord, self.leftAtlasInfo.rightTexCoord, self.leftAtlasInfo.topTexCoord, self.leftAtlasInfo.bottomTexCoord)
        self.Left:SetWidth(leftWidth)
        self.Right:SetTexCoord(self.rightAtlasInfo.leftTexCoord, self.rightAtlasInfo.rightTexCoord, self.rightAtlasInfo.topTexCoord, self.rightAtlasInfo.bottomTexCoord)
        self.Right:SetWidth(rightWidth)
    end
end

function ThreeSliceMixin:SetAtlas(atlasName)
    self:SetAttribute("atlasName", atlasName)
    self:OnAttributeChanged()
end

function InputBlockText_OnLoad(self)
    local title = self:GetAttribute("title")
    local subtext = self:GetAttribute("subtext")

    self.SetText = InputBlockText_SetText
    self.SetTextColor = InputBlockText_SetTextColor
    self.SetSubTextColor = InputBlockText_SetSubTextColor

    if title then
        title = _G[title] or title
        subtext = subtext and _G[subtext] or subtext
        self:SetText(title, subtext)
    end

    local alpha = self:GetAttribute("alpha")
    if alpha then
        self.BG:SetTexture(0, 0, 0, alpha)
    end
    
    local width = self:GetWidth()
    self.Title:SetWidth(width - 20)
    self.SubText:SetWidth(width - 20)
end

function InputBlockText_SetText(self, title, subtext)
    if not subtext or subtext == "" then
        self.Title:SetPoint("CENTER", 0, 0)
    else
        self.Title:SetPoint("CENTER", 0, 8)
    end

    self.Title:SetText(title)
    self.SubText:SetText(subtext)

    local width = self:GetWidth()
    self.Title:SetWidth(width - 20)
    self.SubText:SetWidth(width - 20)
end

function InputBlockText_SetTextColor(self, r, g, b, a)
    self.Title:SetTextColor(r, g, b, a)
end

function InputBlockText_SetSubTextColor(self, r, g, b, a)
    self.SubText:SetTextColor(r, g, b, a)
end

function InputBlockLoading_OnLoad(self)
    local alpha = self:GetAttribute("alpha")
    if alpha then
        self.BG:SetTexture(0, 0, 0, alpha)
    end

    self.Spinner:SetAtlas("specdial_edgeshine", Const.TextureKit.IgnoreAtlasSize)

    local size = self:GetAttribute("size")
    if size then
        self.Spinner:SetSize(size, size)
    end
end

function InputBlockLoading_OnShow(self)
    self.Spinner.Anim:Play()
end

function InputBlockLoading_OnHide(self)
    self.Spinner.Anim:Stop()
end

function InputBlockTextLoading_OnLoad(self)
    InputBlockText_OnLoad(self)
    InputBlockLoading_OnLoad(self)
end

function InputBlockSoftEdgeText_OnLoad(self)
    MixinAndLoad(self, "NineSlicePanelMixin")
    local title = self:GetAttribute("title")
    local subtext = self:GetAttribute("subtext")

    self.SetText = InputBlockText_SetText
    self.SetTextColor = InputBlockText_SetTextColor
    self.SetSubTextColor = InputBlockText_SetSubTextColor

    if title then
        title = _G[title] or title
        subtext = subtext and _G[subtext] or subtext
        self:SetText(title, subtext)
    end
    
    local width = self:GetWidth()
    self.Title:SetWidth(width - 20)
    self.SubText:SetWidth(width - 20)
end

function InputBlockSoftEdgeLoading_OnLoad(self)
    MixinAndLoad(self, "NineSlicePanelMixin")
    self.Spinner:SetAtlas("specdial_edgeshine", Const.TextureKit.IgnoreAtlasSize)

    local size = self:GetAttribute("size")
    if size then
        self.Spinner:SetSize(size, size)
    end
end

function InputBlockSoftEdgeTextLoading_OnLoad(self)
    InputBlockSoftEdgeText_OnLoad(self)
    InputBlockSoftEdgeLoading_OnLoad(self)
end

function GlowBox_RefreshGradient(self)
    self.GradientBG:SetGradientAlpha("VERTICALUP", 0, 0, 0, 1, 0.23, 0.19, 0, 1)
end

DynamicSimpleHTMLMixin = {}

function DynamicSimpleHTMLMixin:OnLoad()
    self:SetJustifyH("LEFT")
    self:SetJustifyV("TOP")
    self.HiddenText:SetJustifyH("LEFT")
    self.HiddenText:SetJustifyV("TOP")
    self.HiddenText.ignoreInLayout = true
    self:SetHyperlinksEnabled(true)
end

function DynamicSimpleHTMLMixin:SetDynamicText(text)
    text = text:gsub("(https://db.ascension.gg/%S+)", LinkUtil.ConvertDBUrlToHyperlink)
    self:SetHeight(4000)
    self.HiddenText:SetFontObject(self:GetFontObject())
    self.HiddenText:Show()
    self.HiddenText:SetSize(self:GetSize())
    self.HiddenText:SetText(text)
    self:SetText(text)
    local height = self.HiddenText:GetStringHeight()
    self:SetHeight(height)
    self.HiddenText:Hide()

    return height
end

function DynamicSimpleHTMLMixin:GetText()
    return self.HiddenText:GetText()
end

function DynamicSimpleHTMLMixin:OnHyperlinkClick(link, text, button)
    LinkUtil:HandleHyperlinkClick(self, link, text, button)
end

function DynamicSimpleHTMLMixin:OnHyperlinkEnter(link, text)
    LinkUtil:OnHyperlinkEnter(self, link, text)
end

function DynamicSimpleHTMLMixin:OnHyperlinkLeave()
    LinkUtil:OnHyperlinkLeave(self)
end

BigDigitBoxMixin = CreateFromMixins("CallbackRegistryMixin")

function BigDigitBoxMixin:OnLoad()
    CallbackRegistryMixin.OnLoad(self)
    self:GenerateCallbackEvents({ "OnValueChanged" })
    self.digits = {}

    for i = 1, 4 do
        self:CreateDigit()
    end
end

function BigDigitBoxMixin:CreateDigit()
    local index = #self.digits + 1
    local digit = self:CreateTexture("$parentDigit"..index, "OVERLAY", "AnimatedBigDigitTemplate")
    digit.layoutIndex = index
    digit:Hide()
    tinsert(self.digits, digit)
end

function BigDigitBoxMixin:SetValue(value)
    self.value = value
    for _, digit in ipairs(self.digits) do
        digit.Anim:Stop()
        digit:Hide()
    end
    
    local numDigits = #tostring(value)
    while numDigits > #self.digits do
        self:CreateDigit()
    end

    for i = #tostring(value), 1, -1 do
        local digit = self.digits[i]
        local number = value%10
        value = math.floor(value/10)

        digit.Anim:Stop()
        digit:SetAtlas("services-number-"..number)
        digit:Show()
        if self.animated then
            digit.Anim:Play()
        end
    end
    
    self:TriggerEvent("OnValueChanged", value)
    self:MarkDirty()
end 

function BigDigitBoxMixin:SetAnimated(animated)
    self.animated = animated
end

function BigDigitBoxMixin:GetValue()
    return self.value
end

--
-- Simple Info Template
--
SimpleInformationBubbleMixin = {}

function SimpleInformationBubbleMixin:OnLoad()
    AttributesToKeyValues(self)
    if self.tooltipTitle then
        self.tooltipTitle = _G[self.tooltipTitle] or self.tooltipTitle
    end

    if self.tooltipText then
        self.tooltipText = _G[self.tooltipText] or self.tooltipText
    end
end

SimpleInformationBubbleMixin.OnEnter = GameTooltip_GenericTooltip
SimpleInformationBubbleMixin.OnLeave = GameTooltip_Hide
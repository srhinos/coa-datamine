CurrencyBarMixin = CreateFromMixins(ThreeSliceMixin)

local function ResetCurrencyItem(pool, button)
    button.item = nil
    button.itemID = nil
    button.tokenType = nil
    button.token = nil
    button.count = 0
    button:ClearAllPoints()
    button:Hide()
end

function CurrencyBarMixin:OnLoad()
    ThreeSliceMixin.OnLoad(self)
    self.justify = "CENTER"
    self.buttons = {}
    self.ItemButtonPool = CreateFramePool("BUTTON", self, self:GetAttribute("ItemTemplate") or "CurrencyBarItemTemplate", ResetCurrencyItem)
end 

function CurrencyBarMixin:OnShow()
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:RegisterEvent("BAG_UPDATE")
    self:Update()
end 

function CurrencyBarMixin:OnHide()
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
    self:UnregisterEvent("BAG_UPDATE")
end

function CurrencyBarMixin:Update()
    if not self:IsVisible() then
        return
    end

    local totalWidth = 0

    for _, button in ipairs(self.buttons) do
        button:UpdateDisplay()
        totalWidth = totalWidth + button:GetWidth()
    end

    if self.dynamicWidth then
        self:SetWidth(math.clamp(totalWidth + 8, self.minWidth or 0, self.maxWidth or math.huge))
    end

    local xPos, point, direction
    local spaceBetweenButtons = 0
    if self.justify == "CENTER" then
        local totalSpace = self:GetWidth() - totalWidth
        spaceBetweenButtons = totalSpace / (#self.buttons + 1)
        xPos = spaceBetweenButtons
        point = "LEFT"
        direction = 1
    elseif self.justify == "LEFT" then
        xPos = 4
        point = "LEFT"
        direction = 1
    elseif self.justify == "RIGHT" then
        xPos = -4
        point = "RIGHT"
        direction = -1
    end

    for _, button in ipairs(self.buttons) do
        button:ClearAndSetPoint(point, self, point, xPos, 0)
        xPos = xPos + (button:GetWidth() + spaceBetweenButtons) * direction
    end
end

function CurrencyBarMixin:CURRENCY_DISPLAY_UPDATE()
    self:Update()
end

function CurrencyBarMixin:BAG_UPDATE()
    self:Update()
end

function CurrencyBarMixin:UseDynamicWidth(dynamicWidth)
    self.dynamicWidth = dynamicWidth
    self:Update()
end

function CurrencyBarMixin:SetMinMaxWidth(minWidth, maxWidth)
    self.minWidth = minWidth
    self.maxWidth = maxWidth
    self:Update()
end

function CurrencyBarMixin:SetJustify(justify)
    self.justify = justify
end

function CurrencyBarMixin:AddCurrency(itemID, fullWidth)
    local button = self.ItemButtonPool:Acquire()
    button:SetItem(itemID, fullWidth)
    button:Show()
    tinsert(self.buttons, button)
    self:Update()
end 

function CurrencyBarMixin:RemoveCurrency(itemID)
    for _, button in ipairs(self.buttons) do
        if button.itemID == itemID then
            self.ItemButtonPool:Release(button)
            self:Update()
            return
        end
    end
end

function CurrencyBarMixin:ClearCurrencies()
    self.ItemButtonPool:ReleaseAll()
    wipe(self.buttons)
    self:Update()
end

function CurrencyBarMixin:AddQuality(quality)
    local button = self.ItemButtonPool:Acquire()
    button:SetQuality(quality)
    button:Show()
    tinsert(self.buttons, button)
    self:Update()
end

function CurrencyBarMixin:AddToken(tokenType)
    local button = self.ItemButtonPool:Acquire()
    button:SetToken(tokenType)
    button:Show()
    tinsert(self.buttons, button)
    self:Update()
end

function CurrencyBarMixin:RemoveQuality(quality)
    for _, button in ipairs(self.buttons) do
        if button.qualityID == quality then
            self.ItemButtonPool:Release(button)
            self:Update()
            return
        end
    end
end

function CurrencyBarMixin:PlayCountAnimation(value, count)
    for _, button in pairs(self.buttons) do
        if (button.tokenType and (button.tokenType == value)) or (button.itemID and (button.itemID == value)) then
            if not(button.fontHeight) then
                local _, fontHeight = button.Text:GetFont()
                AnimatedFontChildMixin.InitAnimation(button, 0.5, button.Text, fontHeight)
            end

            AnimatedFontChildMixin.PlayFontObjectAnimation(button)
            button.AnimatedText:SetText("+"..(count or 1))
            button.AnimatedText.Animation:Stop()
            button.AnimatedText.Animation:Play()
        end
    end
end

function CurrencyBarMixin:StopCountAnimation()
    for _, button in pairs(self.buttons) do
        if button.fontHeight then
            AnimatedFontChildMixin.ExitAnimation(button)
        end
        button.AnimatedText.Animation:Stop()
    end
end

CurrencyBarItemMixin = {}

function CurrencyBarItemMixin:SetItem(itemID, fullWidth)
    self.itemID = itemID
    self.item = Item:CreateFromID(itemID)
    self.fullWidth = fullWidth
end 

function CurrencyBarItemMixin:SetQuality(quality)
    self.qualityID = quality
    self.fullWidth = false
end

function CurrencyBarItemMixin:SetToken(tokenType)
    self.tokenType = tokenType
    self.token = TokenUtil.CreateFromTokenType(tokenType)
    self.fullWidth = fullWidth
end 

function CurrencyBarItemMixin:OnClick()
    if self.item then
        HandleModifiedItemClick(self.item:GetLink())
    elseif self.token then
        HandleModifiedItemClick(self.token:GetLink())
    end
end

function CurrencyBarItemMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.item then
        GameTooltip:SetHyperlink(self.item:GetLink())
    elseif self.qualityID then
        local qualityName = _G["ITEM_QUALITY" .. self.qualityID .. "_DESC"]
        qualityName = NORMAL_FONT_COLOR:WrapText(qualityName)
        GameTooltip:SetText(qualityName)
        GameTooltip:AddLine(CA_RARITY_TOOLTIP:format(2 .. "/" .. 18, qualityName))
        GameTooltip:Show()
    elseif self.token then
        GameTooltip:SetToken(self.token:GetTokenType())
    end
end

function CurrencyBarItemMixin:OnLeave()
    GameTooltip:Hide()
end

function CurrencyBarItemMixin:UpdateDisplay()
    local fixedWidth = self:GetAttribute("fixedWidth")
    if not fixedWidth then
        self:SetWidth(800)
    end

    local padding = 0

    if self.itemID then
        local text
        local amount = GetItemCount(self.itemID)
        self.count = amount
        text = SeparateBigNumber(amount)
        if self.fullWidth then
            text = NORMAL_FONT_COLOR:WrapText(self.item:GetName() .. ": ") .. text
            self.Icon:SetTexCoord(0, 1, 0, 1)
            self.Icon:SetTexture(self.item:GetIcon())
            padding = 30
        else
            if AccessibilityUtil.IsColorBlind() then
                self.Icon:SetTexture(nil)
                text = amount .. " " .. NORMAL_FONT_COLOR:WrapText(self.item:GetAbbreviation())
                padding = 12
            else
                self.Icon:SetTexCoord(0, 1, 0, 1)
                self.Icon:SetTexture(self.item:GetIcon())
                padding = 30
            end
        end

        self:SetText(text)

    elseif self.qualityID then
        local amount
        if BuildCreatorUtil.IsPickingSpells() then
            amount = select(self.qualityID, C_BuildEditor.GetQualityInfoForLevel()) or 0
        else
            amount = C_CharacterAdvancement.GetQualityCount(self.qualityID)
        end

        self.count = amount

        local limit = C_CharacterAdvancement.GetQualityLimit(self.qualityID)
        local text
        if limit and limit > 0 then
            text = amount .. " / " .. limit
        else
            text = amount
        end
        if AccessibilityUtil.IsColorBlind() then
            self.Icon:SetTexture(nil)
            text = text .. " " .. _G["ITEM_QUALITY".. self.qualityID .. "_SHORT"]
            padding = 12
        else
            self.Icon:SetAtlas("rarity-gem"..self.qualityID)
            padding = 30
        end
        
        self:SetText(text)
    elseif (self.tokenType) then
        local text
        local amount = GetTokenCount(self.tokenType)

        self.count = amount
        
        text = SeparateBigNumber(amount)
        if self.fullWidth then
            text = NORMAL_FONT_COLOR:WrapText(self.token:GetName() .. ": ") .. text
            self.Icon:SetTexCoord(0, 1, 0, 1)
            self.Icon:SetTexture(self.token:GetIcon())
            padding = 30
        else
            --[[if AccessibilityUtil.IsColorBlind() then
                self.Icon:SetTexture(nil)
                text = amount .. " " .. NORMAL_FONT_COLOR:WrapText(self.item:GetAbbreviation())
                padding = 12
            else]]--
                self.Icon:SetTexCoord(0, 1, 0, 1)
                self.Icon:SetTexture(self.token:GetIcon())
                padding = 30
            --end
        end

        self:SetText(text)
    end

    if not fixedWidth then
        self:SetWidth(self.Text:GetStringWidth() + padding)
    end
end

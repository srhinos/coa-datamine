-- Base Toast Mixin, should probably make your own implementation for other data types
-- ex:
-- MyToastMixin = CreateFromMixins(ToastMixin)
-- Must Overwrite: SetNotification
-- Ensure you call the base function to handle generic notifications
-- function MyToastMixin:SetNotification(notification)
--     if ToastMixin.SetNotification(self, notification) then
--         return
--     end
--     -- do something with notification
-- end
--
-- Must Overwrite: CanCombineNotification
-- SetNotification will still be called if something is combined, but you can handle that differently then
-- See ItemToastMixin:SetNotification for an example
-- function MyToastMixin:CanCombineNotification(notification)
--     return -- true if you do not want to create a new notification and instead refresh this one
-- end

-- Should Overwrite: Reset
-- just important to clean up your frame incase its used for a generic toast or something later
-- function MyToastMixin:Reset()
--     ToastMixin.Reset(self)
--     -- do something else
-- end
--
--
-- Your frame must have:
-- Background <Texture>
-- Icon <Texture>
-- (optional) IconBorder <Texture>
-- Label <FontString>
-- ItemName <FontString>
-- Count <FontString>
-- AnimIn <AnimationGroup>
-- AnimOut <AnimationGroup>
-- Glow <Texture>
-- Shine <Texture>
--
-- See: ItemToastTemplate for everything needed. Inherit from ToastBaseTemplate for AnimIn / AnimOut
-- You must also set a default background atlas using attribute "backgroundAtlas"
-- lua: self:SetAttribute("backgroundAtlas", "loottoast-item")
-- xml: <Attribute name="backgroundAtlas" value="loottoast-item"/>

ToastMixin = {}

local DEFAULT_HOLD_TIME = 1.25

function ToastMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.Glow:SetAtlas("loottoast-glow", Const.TextureKit.IgnoreAtlasSize)
    self.Shine:SetAtlas("loottoast-sheen", Const.TextureKit.IgnoreAtlasSize)
end

function ToastMixin:SetStyle(style)
    self.style = style
    local useAtlasSize = self:GetAttribute("useAtlasSize")
    if useAtlasSize == nil then
        useAtlasSize = true
    end
    self.Background:SetAtlas(style.atlas or self:GetAttribute("backgroundAtlas", Const.TextureKit.IgnoreAtlasSize), useAtlasSize)
    self.Label:SetText(style.label)
    self.AnimOut.Alpha:SetStartDelay(style.holdTime or DEFAULT_HOLD_TIME)
end

function ToastMixin:SetNotification(notification)
    if notification.type == "generic" then
        self.Icon:SetTexture(notification.icon)
        if self.IconBorder then
            if notification.quality then
                self.IconBorder:SetAtlas(ITEM_QUALITY_BORDER_ATLAS[notification.quality])
            else
                self.IconBorder:SetAtlas(self.iconBorderAtlas or "item-border-gold", Const.TextureKit.IgnoreAtlasSize)
            end
        end
        self.ItemName:SetText(notification.name)
        self:SetCount(notification.count or 1)

        if notification.label then
            self.Label:SetText(notification.label)
        else
            self.Label:SetText(self.style.label)
        end

        self.tooltip = notification.tooltip
        self.tooltipText = notification.tooltipText
        return true
    end
end

function ToastMixin:CanCombineNotification(notification)
    return false
end

function ToastMixin:OnShow()
    if self.style and self.style.soundkit then
        if type(self.style.soundkit) == "number" then
            PlaySound(self.style.soundkit)
        else
            PlaySound(SOUNDKIT[self.style.soundkit])
        end
    end
    
    self.AnimIn:Play()
end

function ToastMixin:Reset()
    self.count = nil
    self.paused = nil
    self.pendingFadeOut = nil
    self.tooltip = nil
    self.tooltipText = nil
end

function ToastMixin:SetCount(count)
    local hadCount = self.count ~= nil
    self.count = count
    if count and count > 1 then
        self.Count:SetText("x" .. count)
        if hadCount then
            self.Count.ChangedAnim:Play()
            self.Glow.AnimIn:Stop()
            self.Glow.AnimIn:Play()
            self:RestartFadeOut()
        end
    else
        self.Count:SetText("")
    end
end

function ToastMixin:OnHide()
    self:Reset()
    EventRegistry:TriggerEvent("ToastNotification.Complete", self)
end

function ToastMixin:OnEnter()
    self:PauseFadeOut()
    if self.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltip, 1, 1, 1)
        if self.tooltipText then
            GameTooltip:AddLine(self.tooltipText, 1, 0.82, 0, true)
        end
        GameTooltip:Show()
        
        return true
    end
end

function ToastMixin:OnLeave()
    self:ResumeFadeOut()
    GameTooltip:Hide()
end

function ToastMixin:OnClick(button)
    if button == "RightButton" then
        self:Hide()
        return true
    end
end

function ToastMixin:FadeIn()
    self.AnimOut:Stop()
    self.AnimIn:Play()
end

function ToastMixin:PauseFadeOut()
    self.AnimOut:Stop()
    self.paused = true
end

function ToastMixin:StopFadeOut()
    self.AnimOut:Stop()
    self.paused = nil
end

function ToastMixin:ResumeFadeOut()
    self.paused = false
    self:PlayFadeOut()
end

function ToastMixin:PlayFadeOut()
    if not self.paused then
        self.AnimOut:Play()
    end
end

function ToastMixin:RestartFadeOut()
    self:StopFadeOut()
    self:PlayFadeOut()
end

--
-- Item Toast
--
ItemToastMixin = CreateFromMixins(ToastMixin)

function ItemToastMixin:OnLoad()
    ToastMixin.OnLoad(self)
end

function ItemToastMixin:Reset()
    ToastMixin.Reset(self)
    self.itemID = nil
    self.itemLink = nil
end

function ItemToastMixin:CanCombineNotification(notification)
    return self.itemID and self.itemID == notification.itemID
end

function ItemToastMixin:OnEnter()
    ToastMixin.OnEnter(self)
    if self.itemLink then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end
end

function ItemToastMixin:OnClick(button)
    if ToastMixin.OnClick(self, button) then
        return
    end

    if IsModifiedClick("CHATLINK") then
        if self.itemLink then
            ChatEdit_InsertLink(self.itemLink)
        end
        return true
    end
end

function ItemToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end
    local itemID = notification.itemID
    local itemLink = notification.itemLink
    local count = notification.count or 1
    if self.itemID == itemID then
        self:SetCount(self.count + (count))
        return
    end
    self.itemID = itemID
    self.itemLink = itemLink or select(2, GetItemInfo(itemID))
    self:SetCount(count)

    local icon = "Interface\\Icons\\"..(GetItemIconInstant(itemID) or "INV_Misc_QuestionMark")
    self.Icon:SetTexture(icon)
    local quality = GetItemQuality(itemID)
    self.IconBorder:SetAtlas(ITEM_QUALITY_BORDER_ATLAS[quality])
    self.ItemName:SetText(self.itemLink)
end

--
-- Legendary Item Toast
--
LegendaryItemToastMixin = CreateFromMixins(ItemToastMixin)

function LegendaryItemToastMixin:OnLoad()
    ToastMixin.OnLoad(self)
end

function LegendaryItemToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end
    local itemID = notification.itemID
    local itemLink = notification.itemLink
    local count = notification.count or 1
    if self.itemID == itemID then
        self:SetCount(self.count + (count))
        return
    end
    self.itemID = itemID
    self.itemLink = itemLink or select(2, GetItemInfo(itemID))
    self:SetCount(count)

    local icon = "Interface\\Icons\\"..(GetItemIconInstant(itemID) or "INV_Misc_QuestionMark")
    self.Icon:SetTexture(icon)
    self.ItemName:SetText(self.itemLink)
end

SpellToastMixin = CreateFromMixins(ToastMixin)

function SpellToastMixin:OnLoad()
    ToastMixin.OnLoad(self)
    self:RegisterForDrag("LeftButton")
end

function SpellToastMixin:Reset()
    ToastMixin.Reset(self)
    self.spellID = nil
end

function SpellToastMixin:CanCombineNotification(notification)
    return self.spellID and self.spellID == notification.spellID
end

function SpellToastMixin:OnEnter()
    ToastMixin.OnEnter(self)
    if self.spellID then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(LinkUtil:GetSpellLink(self.spellID))
        GameTooltip:Show()
    end
end

function SpellToastMixin:OnClick(button)
    if ToastMixin.OnClick(self, button) then
        return
    end

    if IsModifiedClick("CHATLINK") then
        if self.spellID then
            ChatEdit_InsertLink(LinkUtil:GetSpellLink(self.spellID))
        end
        return true
    end
end

function SpellToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end
    local spellID = notification.spellID
    local rank = notification.rank
    self.spellID = spellID
    local name, _, icon = GetSpellInfo(spellID)

    self.Icon:SetTexture(icon)
    self.IconBorder:SetAtlas("item-border-gold", Const.TextureKit.IgnoreAtlasSize)
    if rank then
        self.ItemName:SetFormattedText("%s (%s %s)", name, RANK_COLON, rank)
    else
        self.ItemName:SetText(name)
    end
end

function SpellToastMixin:OnDragStart()
    if not IsPassiveSpellID(self.spellID) and IsSpellIDKnown(self.spellID) then
        local name = GetSpellInfo(self.spellID)
        PickupSpell(name)
    end
end

--
-- Token Toast
--
TokenToastMixin = CreateFromMixins(ToastMixin)

function TokenToastMixin:OnLoad()
    ToastMixin.OnLoad(self)
end

function TokenToastMixin:Reset()
    ToastMixin.Reset(self)
    self.tokenType = nil
end

function TokenToastMixin:CanCombineNotification(notification)
    return self.tokenType and self.tokenType == notification.tokenType
end

function TokenToastMixin:OnEnter()
    ToastMixin.OnEnter(self)
    if self.tokenType then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetToken(self.tokenType)
        GameTooltip:Show()
    end
end

function TokenToastMixin:OnClick(button)
    if ToastMixin.OnClick(self, button) then
        return
    end

    if IsModifiedClick("CHATLINK") then
        if self.tokenType then
            ChatEdit_InsertLink(TokenUtil.GetTokenLink(self.tokenType))
        end
        return true
    end
end

function TokenToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end
    local tokenType = notification.tokenType
    local count = notification.count or 1
    
    local token = TokenUtil.CreateFromTokenType(tokenType)
    if not token then
        self:Hide()
        return
    end

    if self.tokenType == tokenType then
        self:SetCount(self.count + (count))
        return
    end

    self.tokenType = tokenType

    self:SetCount(count)
    self.Icon:SetTexture(token:GetIcon())
    self.IconBorder:SetAtlas(ITEM_QUALITY_BORDER_ATLAS[token:GetQuality()])
    self.ItemName:SetText(token:GetLink())
end

--
-- Manastorm Toast
--
ManastormToastMixin = CreateFromMixins(ToastMixin)

function ManastormToastMixin:CanCombineNotification()
    return false
end

--
-- Mystic Enchant Toast
--
MysticEnchantToastMixin = CreateFromMixins(ToastMixin)

function MysticEnchantToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end

    self.spellID = notification.spellID

    local enchant = C_MysticEnchant.GetEnchantInfoBySpell(self.spellID)

    if not enchant then
        return
    end

    local rarity = Enum.EnchantQualityEnum[enchant.Quality]
    local color = ITEM_QUALITY_COLORS[rarity]
    local border = Enum.ECSlotBorderStylesKnown[rarity] or "EnchantSlotBorderKnownEpic"
    local name, _, icon = GetSpellInfo(enchant.SpellID)

    SetPortraitToTexture(self.Icon, icon)
    self.IconBorder:SetAtlas(border)
    self.ItemName:SetText(color:WrapText(name))
    self.Label:SetText(color:WrapText(_G["MYSTIC_ENCHANT"..rarity]))
end

function MysticEnchantToastMixin:OnDragStart()
    SpellToastMixin.OnDragStart(self)
end

function MysticEnchantToastMixin:OnEnter()
    SpellToastMixin.OnEnter(self)
end

--
-- Achievement Toast
--
AchievementToastMixin = CreateFromMixins(ToastMixin)

function AchievementToastMixin:OnLoad()
    ToastMixin.OnLoad(self)
    self.Glow:SetAtlas("ui-achievement-alert-glow-glow", Const.TextureKit.UseAtlasSize)
    self.Shine:SetAtlas("ui-achievement-alert-glow-shine", Const.TextureKit.UseAtlasSize)
    self.Shield:SetAtlas("ui-achievement-shield-1", Const.TextureKit.UseAtlasSize)
end

function AchievementToastMixin:SetCount(count)
    self.count = count
    if count and count > 1 then
        self.Shield:Show()
        self.Count:SetText(count)
        self.Label:SetPoint("TOP", 7, -23)
    else
        self.Shield:Hide()
        self.Count:SetText("")
        self.Label:SetPoint("TOP", 27, -23)
    end
end

function AchievementToastMixin:OnClick(button)
    if ToastMixin.OnClick(self, button) then
        return
    end

    if button == "RightButton" then
		self:Hide()
		return
	end

	local id = self.achievementID
	if not id then
		return
	end

    UIParentLoadAddOn("Blizzard_AchievementUI")
	
	CloseAllWindows();
	ShowUIPanel(AchievementFrame)
	
	local _, _, _, achCompleted = GetAchievementInfo(id)
	if achCompleted and (ACHIEVEMENTUI_SELECTEDFILTER == AchievementFrameFilters[ACHIEVEMENT_FILTER_INCOMPLETE].func) then
		AchievementFrame_SetFilter(ACHIEVEMENT_FILTER_ALL)
	elseif (not achCompleted) and (ACHIEVEMENTUI_SELECTEDFILTER == AchievementFrameFilters[ACHIEVEMENT_FILTER_COMPLETE].func) then
		AchievementFrame_SetFilter(ACHIEVEMENT_FILTER_ALL)
	end
	
	AchievementFrame_SelectAchievement(id)
end

function AchievementToastMixin:SetNotification(notification)
    if ToastMixin.SetNotification(self, notification) then
        return
    end

    self.achievementID = notification.achievementID

    local _, name, points, _, _, _, _, description, _, icon = GetAchievementInfo(self.achievementID)

    self.Icon:SetTexture(icon)
    self.IconBorder:SetAtlas("ui-achievement-iconframe", Const.TextureKit.IgnoreAtlasSize)
    self.ItemName:SetText(name)
    self:SetCount(points)
    self.Label:SetText(self.style.label)

    self.tooltip = name
    self.tooltipText = description
    return true
end

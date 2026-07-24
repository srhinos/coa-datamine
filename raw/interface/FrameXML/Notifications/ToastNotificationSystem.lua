ToastNotificationSystem = {}
ToastNotificationSystem.IgnoredItems = {}
ToastNotificationSystem.SpecialItemStyles = {}

local SecureFrame = CreateFrame("Frame")
local Notifications = {}
local Styles = {}
local EnqueueNotification, PopNextNotification, OnNotificationComplete, OnNotificationAdded

local achievementToastSuppressUntil = 0
local achievementToastLoginFrame = CreateFrame("Frame")
achievementToastLoginFrame:RegisterEvent("PLAYER_LOGIN")
achievementToastLoginFrame:SetScript("OnEvent", function()
    achievementToastSuppressUntil = GetTime() + 10
end)

local function ShouldShowAchievementToast(achievementID)
    if GetTime() < achievementToastSuppressUntil then
        return false
    end

    return not CanShowAchievementToast or CanShowAchievementToast(achievementID)
end

function ToastNotificationSystem:AddToastStyle(name, template, label, soundkit, atlas, holdTime)
    SecureFrame:SetAttribute("style-name", name)
    SecureFrame:SetAttribute("style-template", template)
    SecureFrame:SetAttribute("style-label", label)
    SecureFrame:SetAttribute("style-soundkit", soundkit)
    SecureFrame:SetAttribute("style-atlas", atlas)
    SecureFrame:SetAttribute("style-holdtime", holdTime)
    SecureFrame:SetAttribute("new-style", true)
end

function ToastNotificationSystem:GetStyle(name)
    return Styles[name] or Styles.Item
end

function ToastNotificationSystem:IgnoreItem(itemID)
    self.IgnoredItems[itemID] = true
end

function ToastNotificationSystem:IsItemIgnored(itemID)
    return self.IgnoredItems[itemID]
end

function ToastNotificationSystem:SetSpecialItemStyle(itemID, style)
    self.SpecialItemStyles[itemID] = style
end

function ToastNotificationSystem:GetSpecialItemStyle(itemID)
    return self.SpecialItemStyles[itemID]
end

EnqueueNotification = function(notification)
    if ToastContainer:GetActiveToastForNotification(notification.info) then
        ToastContainer:AddToast(notification.style, notification.info)
        return
    end
    
    -- check if we already have a notification for this item
    for _, existingNotification in ipairs(Notifications) do
        if existingNotification.info.type == notification.info.type then
            if existingNotification.info.type == "item" then
                if existingNotification.info.itemID == notification.info.itemID then
                    existingNotification.info.count = existingNotification.info.count + notification.info.count
                    existingNotification.style = notification.style
                    return
                end
            elseif existingNotification.info.type == "token" then
                if existingNotification.info.tokenType == notification.info.tokenType then
                    existingNotification.info.count = existingNotification.info.count + notification.info.count
                    existingNotification.style = notification.style
                    return
                end
            elseif existingNotification.info.type == "spell" then
                if existingNotification.info.spellID == notification.info.spellID then
                    existingNotification.style = notification.style
                    return
                end
            end
        end
    end
    
    -- we dont have a notification
    tinsert(Notifications, notification)
    if ToastNotificationSystem:CanPopNextNotification() then
        PopNextNotification()
    end
end

PopNextNotification = function()
    local notification = tremove(Notifications, 1)
    if notification then
        ToastContainer:AddToast(notification.style, notification.info)
    end
end

OnNotificationComplete = function()
    if ToastNotificationSystem:CanPopNextNotification() then
        PopNextNotification()
    end
end

OnNotificationAdded = function()
    if ToastNotificationSystem:CanPopNextNotification() then
        PopNextNotification()
    end
end

function ToastNotificationSystem:CanPopNextNotification()
    return ToastContainer:CanAddToast()
end

function ToastNotificationSystem:EnqueueItemNotification(style, itemID, itemLink, count)
    if self:IsItemIgnored(itemID) then return end
    SecureFrame:SetAttribute("type", "item")
    SecureFrame:SetAttribute("style", style)
    SecureFrame:SetAttribute("itemID", itemID)
    SecureFrame:SetAttribute("itemLink", itemLink)
    SecureFrame:SetAttribute("count", count)
    SecureFrame:SetAttribute("add-item", true)
end

-- /run ToastNotificationSystem:EnqueueTokenNotification("Token", "TOKEN_TYPE_SCROLL_OF_FORTUNE_I_TALENTS", 1)
function ToastNotificationSystem:EnqueueTokenNotification(style, tokenType, count)
    SecureFrame:SetAttribute("type", "token")
    SecureFrame:SetAttribute("style", style)
    SecureFrame:SetAttribute("tokenType", tokenType)
    SecureFrame:SetAttribute("count", count)
    SecureFrame:SetAttribute("add-token", true)
end

function ToastNotificationSystem:EnqueueSpellNotification(style, spellID, rank)
    SecureFrame:SetAttribute("type", "spell")
    SecureFrame:SetAttribute("style", style)
    SecureFrame:SetAttribute("spellID", spellID)
    SecureFrame:SetAttribute("rank", rank)
    SecureFrame:SetAttribute("add-spell", true)
end

--/run ToastNotificationSystem:EnqueueGenericNotification("LegendaryItem", "My Cool Item", 1000, "Interface\\Icons\\inv_misc_questionmark", 1)
function ToastNotificationSystem:EnqueueGenericNotification(style, label, name, count, icon, quality, tooltip, tooltipText)
    SecureFrame:SetAttribute("type", "generic")
    SecureFrame:SetAttribute("style", style)
    SecureFrame:SetAttribute("label", label)
    SecureFrame:SetAttribute("name", name)
    SecureFrame:SetAttribute("count", count)
    SecureFrame:SetAttribute("icon", icon)
    SecureFrame:SetAttribute("quality", quality)
    SecureFrame:SetAttribute("tooltip", tooltip)
    SecureFrame:SetAttribute("tooltipText", tooltipText)
    SecureFrame:SetAttribute("add-generic", true)
end

function ToastNotificationSystem:EnqueueAchievementNotification(style, achievementID, criteriaID)
    if not ShouldShowAchievementToast(achievementID) then
        return
    end

    SecureFrame:SetAttribute("type", "achievement")
    SecureFrame:SetAttribute("style", style)
    SecureFrame:SetAttribute("achievementID", achievementID)
    SecureFrame:SetAttribute("criteriaID", criteriaID)
    SecureFrame:SetAttribute("add-achievement", true)
end

function ToastNotificationSystem:CHAT_MSG_LOOT(msg)
    if not (msg:find(LOOT_ITEM_SELF:sub(1, 11)) or msg:find(LOOT_ITEM_CREATED_SELF:sub(1, 11))) then
        return
    end
    local itemID, count = msg:match("|Hitem:(%d+).*x(%d+)")
    if not itemID then
        itemID = msg:match("|Hitem:(%d+)")
    end

    itemID = tonumber(itemID)
    if not itemID then
        return
    end

    -- mystic scrolls flood the ui if not
    if Collections:IsOnTab(Collections.Tabs.MysticEnchants) then
        if C_MysticEnchant.GetEnchantInfoByItem(itemID) then
            return
        end
    end

    -- avoid skill card statistics flood when mass revealing a ton of packs
    if SkillCardsFrame and SkillCardsFrame.UnlockFrame:GetMassRevealStatistics():IsVisible() then
        if SkillCardsUI:GetStatistics() and SkillCardsUI:GetStatistics().rewardItems[itemID] then
            return
        end
    end

    local link = msg:match("(|c.-|r)")
    count = count or 1
    
    local quality = GetItemQuality(itemID)

    if not quality or quality < Enum.ItemQuality.Epic then
        return
    end

    local style = "EpicItem"
    local specialStyle = self:GetSpecialItemStyle(itemID)
    if quality == Enum.ItemQuality.Legendary then
        style = "LegendaryItem"
        if C_CVar.GetBitfield("disabledToastBitfield", Enum.LootToastBit.LegendaryItem) then
            return
        end
    else
        if C_CVar.GetBitfield("disabledToastBitfield", Enum.LootToastBit.EpicItem) then
            return
        end
    end
    
    self:EnqueueItemNotification(specialStyle or style, itemID, link, count)
end

function ToastNotificationSystem:TOKEN_UPDATED(tokenType, oldAmount, newAmount)
    if TokenUtil.RecentlyUsedCaseOfFortune() then
        return
    end

    if C_CVar.GetBitfield("disabledToastBitfield", Enum.LootToastBit.EpicItem) then
        return
    end

    if oldAmount > newAmount then
        return
    end

    if TokenUtil.IsScrollOfFortuneTokenForInactiveSpec(tokenType) then
        return
    end
    
    local token = TokenUtil.CreateFromTokenType(tokenType)
    if not token then
        return
    end

    if not token:ShouldShowToast() then
        return
    end

    self:EnqueueTokenNotification(token:GetToastStyle(), tokenType, newAmount - oldAmount)
end

function ToastNotificationSystem:PLAYER_LEVEL_UP(level)
    local activeBuild = BuildCreatorUtil.GetActiveBuildID()

    if not activeBuild then return end

    BuildCreatorUtil.ContinueOnLoad(activeBuild, function(build)
        if not build then return end
        for _, buildEnchant in ipairs(build.RandomEnchants) do
            if buildEnchant.Level == level and bit.contains(buildEnchant.Flags or 0, Enum.BuildSpellFlags.NotifyOnLearn) then
                self:EnqueueSpellNotification("MysticEnchant", buildEnchant.Enchant, nil)
            end
        end
    end)
end

function ToastNotificationSystem:NOTABLE_SPELL_LEARNED(spellID)
    if C_Player:GetLevel() <= 1 then return end
    if C_CVar.GetBitfield("disabledToastBitfield", Enum.LootToastBit.SpellLearned) then
        return
    end
    self:EnqueueSpellNotification("NewSpell", spellID)
end

function ToastNotificationSystem:SpellRankAvailable(spellID, learnableID)
    if C_CVar.GetBitfield("disabledToastBitfield", Enum.LootToastBit.NewSpellRank) then
        return
    end
    
    if not C_Spell.IsTrainerSpell(learnableID) then
        return
    end
    
    local _, companionName = C_Player:GetCurrentCompanion()
    if companionName and companionName:lower():find("book of ascension") then
        return
    end

    local _, rank = GetSpellInfo(learnableID)
    if rank and rank ~= "" then
        rank = rank:match("%d")
    end

    if rank == "" then
        rank = nil
    end
    
    self:EnqueueSpellNotification("NewSpellRankAvailable", learnableID, rank)
end

function ToastNotificationSystem:MAX_COMPLETED_MANASTORM_LEVEL_UPDATED(oldLevel, newLevel)
    self:EnqueueGenericNotification("ManastormLevel", nil, MANASTORM_TOAST_CHECKPOINT:format(newLevel), 1, "Interface\\Icons\\inv_misc_enggizmos_08", nil, MANASTORM_TOAST_TOOLTIP_TITLE, MANASTORM_TOAST_TOOLTIP)
end

function ToastNotificationSystem:MANASTORM_LEVEL_UNLOCKED(icon, title, description)
    title = _G[title] or title
    description = _G[description] or description
    self:EnqueueGenericNotification("ManastormLevel", title, description, 1, "Interface\\Icons\\"..icon)
end
--/run ToastNotificationSystem:ACHIEVEMENT_EARNED(16566)
function ToastNotificationSystem:ACHIEVEMENT_EARNED(achievementID)
    self:EnqueueAchievementNotification("Achievement", achievementID)
end

SecureFrame:SetScript("OnAttributeChanged", function(self, attribute)
    if attribute:startswith("add") then
        if not C_CVar.GetBool("showLootToasts") then
            return
        end
        local info = {}
        info.type = self:GetAttribute("type")
        if attribute == "add-item" then
            info.itemID = tonumber(self:GetAttribute("itemID"))
            if not info.itemID then return end
            info.itemLink = self:GetAttribute("itemLink")
            info.count = tonumber(self:GetAttribute("count"))
        elseif attribute == "add-token" then
            info.tokenType = self:GetAttribute("tokenType")
            if not info.tokenType then return end
            info.count = tonumber(self:GetAttribute("count"))
        elseif attribute == "add-spell" then
            info.spellID = tonumber(self:GetAttribute("spellID"))
            if not info.spellID then return end
            info.rank = tonumber(self:GetAttribute("rank"))
        elseif attribute == "add-achievement" then
            info.achievementID = tonumber(self:GetAttribute("achievementID"))
            if not info.achievementID then return end
        elseif attribute == "add-generic" then
            info.name = self:GetAttribute("name")
            info.count = tonumber(self:GetAttribute("count"))
            info.icon = self:GetAttribute("icon")
            info.quality = tonumber(self:GetAttribute("quality"))
            info.label = self:GetAttribute("label")
            info.tooltip = self:GetAttribute("tooltip")
            info.tooltipText = self:GetAttribute("tooltipText")
        else
            return
        end
        local style = ToastNotificationSystem:GetStyle(self:GetAttribute("style"))
        if not style then return end
        EnqueueNotification({ style = style, info = info })
    elseif attribute == "new-style" then
        local style = self:GetAttribute("style-name")
        local template = self:GetAttribute("style-template")
        local label = self:GetAttribute("style-label")
        local soundkit = self:GetAttribute("style-soundkit")
        soundkit = tonumber(soundkit) or soundkit
        local atlas = self:GetAttribute("style-atlas")
        local holdTime = tonumber(self:GetAttribute("style-holdtime"))
        Styles[style] = {template = template, label = label, soundkit = soundkit, atlas = atlas, holdTime = holdTime}
    end
end)

ToastNotificationSystem:AddToastStyle("Item", "ItemToastTemplate", YOU_RECEIVED)
ToastNotificationSystem:AddToastStyle("EpicItem", "ItemToastTemplate", YOU_RECEIVED, "UI_EPICLOOT_TOAST_01")
ToastNotificationSystem:AddToastStyle("LegendaryItem", "LegendaryItemToastTemplate", YOU_RECEIVED, "UI_LEGENDARY_ITEM_TOAST")
ToastNotificationSystem:AddToastStyle("VanityItem", "ItemToastTemplate", YOU_RECEIVED, "UI_WARFORGED_ITEM_TOAST_BANNER")
ToastNotificationSystem:AddToastStyle("NewSpell", "SpellToastTemplate", NEW_SPELL_LEARNED, "UI_70_ARTIFACT_FORGE_TOAST_TRAITAVAILABLE", nil, 2.5)
ToastNotificationSystem:AddToastStyle("ScrollToken", "TokenToastTemplate", YOU_RECEIVED, "UI_EPICLOOT_TOAST_01", "loottoast-nzoth")
ToastNotificationSystem:AddToastStyle("Token", "TokenToastTemplate", YOU_RECEIVED, "UI_EPICLOOT_TOAST_01")
ToastNotificationSystem:AddToastStyle("NewSpellRankAvailable", "SpellToastTemplate", SPELL_RANK_AVAILABLE, "UI_BLIZZARDSTORE_TOAST")
ToastNotificationSystem:AddToastStyle("SealedCard", "ItemToastTemplate", YOU_RECEIVED, "PICK_UP_PARCHMENT_PAPER")
ToastNotificationSystem:AddToastStyle("ManastormLevel", "ManastormToastTemplate", MANASTORM_TOAST_LABEL, "UI_TRADESKILL_LEVELUP_01_63", nil, 5)
ToastNotificationSystem:AddToastStyle("MysticEnchant", "MysticEnchantToastTemplate", NEW_SPELL_LEARNED, "UI_70_ARTIFACT_FORGE_TOAST_TRAITAVAILABLE", nil, 5)
ToastNotificationSystem:AddToastStyle("Achievement", "AchievementToastTemplate", ACHIEVEMENT_UNLOCKED, nil, nil, 5)

ToastNotificationSystem:IgnoreItem(1201244) -- Rune of Experience
ToastNotificationSystem:IgnoreItem(383080) -- Ability Essence
ToastNotificationSystem:IgnoreItem(383081) -- Talent Essence
ToastNotificationSystem:IgnoreItem(101399) -- ITEM_SCROLL_OF_FORTUNE_CREDIT
ToastNotificationSystem:IgnoreItem(375250) -- Mark of Ascension
ToastNotificationSystem:IgnoreItem(400750) -- Raider's Commendation
ToastNotificationSystem:IgnoreItem(98462) -- Mystic Rune
ToastNotificationSystem:IgnoreItem(98570) -- Mystic Orb
ToastNotificationSystem:IgnoreItem(102177) -- Mark of Mentorship

-- Sealed Card Packs
ToastNotificationSystem:SetSpecialItemStyle(97395, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(97396, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(777997, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(778999, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(779000, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(779002, "SealedCard")
ToastNotificationSystem:SetSpecialItemStyle(1033042, "SealedCard")

EventRegistry:RegisterCallback("ToastNotification.Complete", OnNotificationComplete)
EventRegistry:RegisterCallback("ToastNotification.Added", OnNotificationAdded)
EventRegistry:RegisterCallback("NewSpellRankAvailable", ToastNotificationSystem.SpellRankAvailable, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_LOOT", ToastNotificationSystem.CHAT_MSG_LOOT, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("TOKEN_UPDATED", ToastNotificationSystem.TOKEN_UPDATED, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("NOTABLE_SPELL_LEARNED", ToastNotificationSystem.NOTABLE_SPELL_LEARNED, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("MAX_COMPLETED_MANASTORM_LEVEL_UPDATED", ToastNotificationSystem.MAX_COMPLETED_MANASTORM_LEVEL_UPDATED, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("MANASTORM_LEVEL_UNLOCKED", ToastNotificationSystem.MANASTORM_LEVEL_UNLOCKED, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_LEVEL_UP", ToastNotificationSystem.PLAYER_LEVEL_UP, ToastNotificationSystem)
EventRegistry:RegisterFrameEventAndCallback("ACHIEVEMENT_EARNED", ToastNotificationSystem.ACHIEVEMENT_EARNED, ToastNotificationSystem)

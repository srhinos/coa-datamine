--
-- Profession Tab
--
ProfessionTabMixin = CreateFromMixins(SpellbookPageMixin)

local ProfessionOrder = {
    Enum.Profession.Blacksmithing,
    Enum.Profession.Alchemy,
    Enum.Profession.Enchanting,
    Enum.Profession.Engineering,
    --Enum.Profession.Jewelcrafting,
    Enum.Profession.Leatherworking,
    Enum.Profession.Tailoring,
    Enum.Profession.Woodworking,
    --Enum.Profession.Inscription,
    Enum.Profession.Herbalism,
    Enum.Profession.Mining,
    Enum.Profession.Skinning,
    Enum.Profession.Woodcutting,
    Enum.Profession.Cooking,
    Enum.Profession.FirstAid,
    Enum.Profession.Fishing,
    Enum.Profession.Bushcraft,
}

if GetExpansionLevel() >= Enum.Expansion.TBC then
    tinsert(ProfessionOrder, 5, Enum.Profession.Jewelcrafting)
end

if GetExpansionLevel() >= Enum.Expansion.WoTLK then
    tinsert(ProfessionOrder, 8, Enum.Profession.Inscription)
end

function ProfessionTabMixin:OnLoad()
    self.professionButtons = {}
    SpellbookPageMixin.OnLoad(self)
    for index, skillID in ipairs(ProfessionOrder) do
        local professionButton = CreateFrame("Button", "$parentProfession"..index, self, "SpellbookProfessionTemplate")
        professionButton:SetID(index)
        professionButton:SetProfession(skillID)
        professionButton:SetPoint("TOPLEFT", 70 + 108 * ((index - 1) % 4), -40 - 108 * floor((index - 1) / 4))
        tinsert(self.professionButtons, professionButton)
    end
end

function ProfessionTabMixin:UpdateProfessions()
    for i, professionButton in ipairs(self.professionButtons) do
        professionButton:SetProfession(ProfessionOrder[i])
    end
end

--
-- Spellbook Profession
--
SpellbookProfessionMixin = {}

function SpellbookProfessionMixin:OnLoad()
    SecureActionButton_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:SetAttribute("type", "spellbook")
    self.IconBorder:SetAtlas("professionbook-icon-border", Const.TextureKit.IgnoreAtlasSize)
    self.Highlight:SetAtlas("bags-roundhighlight", Const.TextureKit.IgnoreAtlasSize)
    self.ExtraButtonPool = CreateFramePool("Button", self, "SpellbookProfessionExtraTemplate")
end

function SpellbookProfessionMixin:OnShow()
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterEvent("TRADE_SKILL_CLOSE")
end

function SpellbookProfessionMixin:OnHide()
    self:UnregisterEvent("TRADE_SKILL_SHOW")
    self:UnregisterEvent("TRADE_SKILL_CLOSE")
end

function SpellbookProfessionMixin:OnEvent(event, ...)
    if event == "TRADE_SKILL_SHOW" then
        self:UpdatePressed()
    elseif event == "TRADE_SKILL_CLOSE" then
        self:UpdatePressed()
    end
end

function SpellbookProfessionMixin:UpdatePressed()
    if self.spellIndex and IsSelectedSpell(self.spellIndex, BOOKTYPE_SPELL) then
        self:LockHighlight()
    else
        self:UnlockHighlight()
    end
end

function SpellbookProfessionMixin:SetProfession(skillID)
    self.skillID = skillID
    local name, rankText, icon, rank, modifier, maxRank, craftingSpellID, currentRankSpellID, isAbandonable, description = ProfessionUtil.GetProfessionByID(skillID)
    local hideUnavailable = skillID == Enum.Profession.Bushcraft and (not maxRank or not rank)

    self:SetShown(not hideUnavailable)
    if hideUnavailable then
        return
    end

    self.Icon:SetPortraitTexture(icon)
    self:SetText(name)
    self.Rank:SetText(rankText)
    self.description = description
    if not maxRank or not rank then
        self:Disable()
        self:SetAttribute("bookType", nil)
        self:SetAttribute("spell", nil)
        self.ExtraButtonPool:ReleaseAll()
        self.AbandonButton:Hide()
    else
        self:Enable()
        if modifier then
            rank = rank + modifier
        end
        -- setup progress bar
        self.ProgressBar.RankText:SetText(rank.."/"..maxRank)
        self.ProgressBar:SetMinMaxValues(0, maxRank)
        self.ProgressBar:SetValue(rank)
        self.ProgressBar.CapRight:SetShown(rank == maxRank)
        
        -- setup click handler
        self.spellIndex = craftingSpellID and GetSpellBookIndex(craftingSpellID, BOOKTYPE_SPELL)

        if self.spellIndex then
            self:SetAttribute("bookType", BOOKTYPE_SPELL)
            self:SetAttribute("spell", self.spellIndex)
        else
            self:SetAttribute("bookType", nil)
            self:SetAttribute("spell", nil)
        end
        self:UpdatePressed()
        
        -- setup extra buttons 
        self:SetupExtraButtons()
        
        -- update abandon button
        self.AbandonButton:SetShown(isAbandonable)
    end
end

function SpellbookProfessionMixin:SetupExtraButtons()
    self.ExtraButtonPool:ReleaseAll()
    local spells = {}
    local specialization = ProfessionUtil.GetSpecialization(self.skillID)
    if specialization then
        tinsert(spells, specialization)
    end

    local utilitySpells = ProfessionUtil.GetKnownUtilitySpells(self.skillID)
    for _, spellID in ipairs(utilitySpells) do
        tinsert(spells, spellID)
    end
    
    local passives = ProfessionUtil.GetKnownPassives(self.skillID)
    for _, spellID in ipairs(passives) do
        tinsert(spells, spellID)
    end

    local numSpells = #spells
    local buttonRadius = (self.Icon:GetHeight() / 2)
    local angleStep = (math.pi / numSpells) / 2


    for i, spellID in ipairs(spells) do
        local extraButton = self.ExtraButtonPool:Acquire()
        extraButton:SetID(i)
        local angle = ((i - 1) - ((numSpells - 1) / 2)) * angleStep
        local x = math.sin(angle) * buttonRadius
        local y = math.cos(angle) * buttonRadius
        extraButton:SetPoint("CENTER", self, "CENTER", x, -y+22)
        extraButton:Show()
        
        local icon = select(3, GetSpellInfo(spellID))
        extraButton.Icon:SetPortraitTexture(icon)
        local isPassive = IsPassiveSpellID(spellID)
        extraButton:SetEnabled(not isPassive)
        extraButton.spellID = spellID

        if isPassive then
            extraButton:SetAttribute("bookType", nil)
            extraButton:SetAttribute("spell", nil)
        else
            extraButton:SetAttribute("bookType", BOOKTYPE_SPELL)
            extraButton:SetAttribute("spell", GetSpellBookIndex(spellID, BOOKTYPE_SPELL))
        end
    end
end

function SpellbookProfessionMixin:OnEnable()
    self.ProgressBar:Show()
    self.TextShadow:Show()
    self.Icon:SetAlpha(1)
    self.Icon:SetDesaturated(false)
end 

function SpellbookProfessionMixin:OnDisable()
    self.ProgressBar:Hide()
    self.TextShadow:Hide()
    self.Icon:SetAlpha(0.7)
    self.Icon:SetDesaturated(true)
end 

function SpellbookProfessionMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -24, -18)
    GameTooltip:SetMinimumWidth(260, true)
    GameTooltip:AddDoubleLine(self:GetText(), self.Rank:GetText(), 1, 1, 1, 0.4, 0.4, 0.4)
    GameTooltip:AddLine(self.description, 1, 0.82, 0, true)
    if self:IsEnabled() == 0 then
        GameTooltip_AddSpacer(GameTooltip)
        GameTooltip:AddLine(PROFESSION_WHERE_TO_LEARN:format(self:GetText()), 1, 0.82, 0, true)
        local numProfessions = ProfessionUtil.GetNumProfessions()
        if numProfessions >= 2 and ProfessionUtil.GetProfessionType(self.skillID) == "primary" then
            GameTooltip_AddSpacer(GameTooltip)
            local codex = Item:CreateFromID(ItemData.CRAFTSMANS_CODEX)
            GameTooltip:AddLine(PROFESSION_WHERE_TO_LEARN_MORE:format(codex:GetLink()), 0.1, 1, 0.1, true)
        end
    end
    GameTooltip:Show()
end 

function SpellbookProfessionMixin:OnLeave()
    GameTooltip:Hide()
end

function SpellbookProfessionMixin:OnDragStart()
    if self:IsEnabled() == 0 then
        return
    end
    if self.spellIndex and not IsPassiveSpell(self.spellIndex, BOOKTYPE_SPELL) then
        PickupSpell(self.spellIndex, BOOKTYPE_SPELL)
    end
end 
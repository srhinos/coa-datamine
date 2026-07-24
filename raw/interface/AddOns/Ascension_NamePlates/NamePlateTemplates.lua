local Addon = select(2, ...)[1]

NamePlateBorderTemplateMixin = {}

function NamePlateBorderTemplateMixin:OnLoad()
    UseParentLevel(self)
end
function NamePlateBorderTemplateMixin:SetVertexColor(r, g, b, a)
    self.color = { r, g, b, a }
    self.Texture:SetVertexColor(r, g, b, a)
end

function NamePlateBorderTemplateMixin:UpdateStyle(useClassicBorder)
    if useClassicBorder then
        self.classicBorder = true
        if self.Overlay then
            self.Overlay:Show()
        end

        self.Texture:SetAtlas("bonusobjectives-bar-glow")
        if self.color then
            self.Texture:SetVertexColor(unpack(self.color))
        end

        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", -4, 3)
        self:SetPoint("BOTTOMRIGHT", 18, -3)
        self.Texture:SetPoint("TOPLEFT", -2, 2)
        self.Texture:SetPoint("BOTTOMRIGHT", 2, -2)
    else
        self.classicBorder = nil
        if self.Overlay then
            self.Overlay:Hide()
        end

        self.Texture:SetAtlas("nameplates-bar-background-white")
        if self.color then
            self.Texture:SetVertexColor(unpack(self.color))
        end
        self:ClearAllPoints()
        self:SetAllPoints()
        self.Texture:SetPoint("TOPLEFT", -1, 1)
        self.Texture:SetPoint("BOTTOMRIGHT", 1, -1)
    end
end

NamePlateUnitMixin = CreateFromMixins(CompactUnitMixin)

function NamePlateUnitMixin:OnLoad()
    CompactUnitMixin.OnLoad(self)
    self.LevelFrame:SetFrameLevel(self:GetFrameLevel() + 4)
    self:RegisterEvent("RAID_TARGET_UPDATE")
end

function NamePlateUnitMixin:OnEvent(event, ...)
    CompactUnitMixin.OnEvent(self, event, ...)
    if event == "RAID_TARGET_UPDATE" then
        self:UpdateRaidTarget()
    elseif event == "PLAYER_TARGET_CHANGED" then
        local unit = self.unit or self.displayedUnit
        if unit and UnitIsUnit(unit, "target") then
            self:UpdateBuffs()
        end
    end
end

function NamePlateUnitMixin:UpdateRaidTarget()
    local icon = self.RaidTargetFrame.RaidTargetIcon
    local unit = self.displayedUnit or self.unit
    local index = GetRaidTargetIndex(unit)
    if index and not UnitIsUnit("player", unit) then
        SetRaidTargetIconTexture(icon, index)
        icon:Show()
    else
        icon:Hide()
    end
end

NamePlateUnitMixin.UpdateDebuffs = nop -- update buffs handles debuffs
function NamePlateUnitMixin:UpdateBuffs()
    local unit = self.displayedUnit or self.unit
    local filter
    if unit then
        if UnitIsUnit("player", unit) then
            filter = "HELPFUL|PLAYER"
        else
            local reaction = UnitReaction("player", unit)
            if reaction and reaction <= 4 then
                -- Reaction 4 is neutral and less than 4 becomes increasingly more hostile
                if self.optionTable.onlyPlayerDebuffs then
                    filter = "HARMFUL|PLAYER"
                else
                    filter = "HARMFUL"
                end
            else
                if self.optionTable.showDebuffs then
                    -- dispellable debuffs
                    filter = "HARMFUL|RAID"
                else
                    filter = "NONE"
                end
            end
        end
    else
        filter = "NONE"
    end
    
    self.BuffFrame:UpdateBuffs(unit, filter, self.optionTable.allowList)
end
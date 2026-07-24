NameplateBuffContainerMixin = {}

function NameplateBuffContainerMixin:OnLoad()
    self.buffList = {}
    self.targetYOffset = 0
    self.baseYOffset = 0
    self.BuffFrameUpdateTime = 0
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function NameplateBuffContainerMixin:OnEvent(event, ...)
    if event == "PLAYER_TARGET_CHANGED" then
        self:UpdateAnchor()
    end
end

function NameplateBuffContainerMixin:OnUpdate(elapsed)
    if ( self.BuffFrameUpdateTime > 0 ) then
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime - elapsed
    else
        self.BuffFrameUpdateTime = self.BuffFrameUpdateTime + TOOLTIP_UPDATE_TIME
    end
end

function NameplateBuffContainerMixin:SetTargetYOffset(targetYOffset)
    self.targetYOffset = targetYOffset
end

function NameplateBuffContainerMixin:GetTargetYOffset()
    return self.targetYOffset
end

function NameplateBuffContainerMixin:SetBaseYOffset(baseYOffset)
    self.baseYOffset = baseYOffset
end

function NameplateBuffContainerMixin:GetBaseYOffset()
    return self.baseYOffset
end

function NameplateBuffContainerMixin:UpdateAnchor()
    local isTarget = self:GetParent().unit and UnitIsUnit(self:GetParent().unit, "target")
    local targetYOffset = self:GetBaseYOffset() + (isTarget and self:GetTargetYOffset() or 0.0)
    if self:GetParent().unit and self:GetParent():ShouldShowName() then
        self:SetPoint("BOTTOM", self:GetParent().name, "TOP", 0, 5 + targetYOffset)
    else
        self:SetPoint("BOTTOM", self:GetParent().healthBar, "TOP", 0, targetYOffset)
    end
end

function NameplateBuffContainerMixin:SetActive(isActive)
    self.isActive = isActive
end

function NameplateBuffContainerMixin:UpdateBuffs(unit, filter, allowList)
    if not self.isActive then
        for i = 1, BUFF_MAX_DISPLAY do
            if self.buffList[i] then
                self.buffList[i]:Hide()
            end
        end

        return
    end

    self.unit = unit
    self.filter = filter
    self:UpdateAnchor()

    if filter == "NONE" then
        for i, buff in ipairs(self.buffList) do
            buff:Hide()
        end
    else
        -- Some buffs may be filtered out, use this to create the buff frames.
        local buffIndex = 1

        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID
        for i = 1, BUFF_MAX_DISPLAY do
            name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID = UnitAura(unit, i, filter)
            if name then
                if AuraUtil.UnitShouldShowBuff(unit, name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellID) then
                    if (not self.buffList[buffIndex]) then
                        self.buffList[buffIndex] = CreateFrame("Frame", self:GetParent():GetName() .. "Buff" .. buffIndex, self, "NameplateBuffButtonTemplate")
                        self.buffList[buffIndex].layoutIndex = buffIndex
                    end
                    local buff = self.buffList[buffIndex]
                    buff:EnableMouse(false)
                    buff:SetID(i)
                    buff.name = name
                    buff.Icon:SetTexture(icon)
                    if (count > 1) then
                        buff.CountFrame.Count:SetText(count)
                        buff.CountFrame.Count:Show()
                    else
                        buff.CountFrame.Count:Hide()
                    end
                    
                    buff.expireTime = expirationTime
                    buff:Show()
                    buffIndex = buffIndex + 1
                end
            else
                break
            end
        end

        for i = buffIndex, BUFF_MAX_DISPLAY do
            if self.buffList[i] then
                self.buffList[i]:Hide()
            end
        end
    end
    self:Layout()
end

NameplateBuffButtonTemplateMixin = {}

function NameplateBuffButtonTemplateMixin:OnUpdate(elapsed)
    if self:GetParent().BuffFrameUpdateTime > 0 then
        return
    end

    local timeLeft = self.expireTime - GetTime()
    if timeLeft > 60 then
        self.CooldownText:SetText("")
    elseif timeLeft < 3 then
        self.CooldownText:SetFormattedText("%.1f", timeLeft)
    else
        self.CooldownText:SetFormattedText("%d", timeLeft)
    end
end
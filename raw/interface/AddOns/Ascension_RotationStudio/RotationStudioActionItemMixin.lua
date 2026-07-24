RotationStudioActionItemMixin = CreateFromMixins("ScrollListItemBaseMixin")

function RotationStudioActionItemMixin:OnLoad()
    self.RemoveButton:SetFrameLevel(self.Icon:GetFrameLevel() + 2)
end

function RotationStudioActionItemMixin:Update()
    -- temp for previewing
    self.UpButton:SetShown(self.index > 2)
    self.DownButton:SetShown(self.index ~=1)

    if self.index == 1 then
        self.Icon:SetIconAtlas("itemupgrade_greenplusicon")
        self.About:SetText("")
        self.Name:SetText("Add Spell")
        self.RemoveButton:Hide()
        return
    end
    
    self.RemoveButton:Show()

    local action = self:GetScrollList():GetParent():GetActionAtIndex(self.index)
    
    self.Icon:SetSpell(action.SpellID)
    self.Name:SetText(GetSpellInfo(action.SpellID))
    
    local fakeCooldown = action[RotationStudio.ActionConditions.FakeCooldown]
    local targetMissingDebuff = action[RotationStudio.ActionConditions.TargetMissingDebuff]
    local playerMissingBuff = action[RotationStudio.ActionConditions.PlayerMissingBuff]
    
    local aboutText
    if fakeCooldown and fakeCooldown > 0 then
        aboutText = (aboutText and aboutText .. "\n" or "") .. string.format("Fake Cooldown: %s", SecondsToTime(fakeCooldown, false, false, 1))
    end

    if targetMissingDebuff then
        aboutText = (aboutText and aboutText .. "\n" or "") .. "Requires Missisng Debuff"
    end

    if playerMissingBuff then
        aboutText = (aboutText and aboutText .. "\n" or "") .. "Requires Missing Buff"
    end
    
    self.About:SetText(aboutText)
end 

function RotationStudioActionItemMixin:OnSelected()
    
end 

function RotationStudioActionItemMixin:MoveUp()
    
end

function RotationStudioActionItemMixin:MoveDown()
    
end 

function RotationStudioActionItemMixin:Remove()
    self:GetScrollList():GetParent():RemoveActionAtIndex(self.index)
end

function RotationStudioActionItemMixin:OnEnter()
    self.RemoveButton:SetAlpha(1)
end

function RotationStudioActionItemMixin:OnLeave()
    self.RemoveButton:SetAlpha(0.4)
end

function RotationStudioActionItemMixin:OnReceiveDrag()
    local type, id, info = GetCursorInfo()
    if type ~= "spell" then
        return
    end

    local link = GetSpellLink(id, info)
    local spellID = link and tonumber(link:match("spell:(%d+)"))

    if not spellID then
        return
    end

    self:GetScrollList():GetParent():AddAction(self.index, spellID)
    ClearCursor()
end 
ManastormLoadoutMixin = {}

function ManastormLoadoutMixin:OnLoad()
    self.slotPool = CreateFramePool("Button", self, "ManastormLoadoutSlotTemplate")
end

function ManastormLoadoutMixin:OnShow()
    self:RegisterEvent("MANASTORM_LOADOUT_UPDATE")
    self:Refresh()
end

function ManastormLoadoutMixin:OnHide()
    self:UnregisterEvent("MANASTORM_LOADOUT_UPDATE")
end

function ManastormLoadoutMixin:Refresh()
    self.slotPool:ReleaseAll()
    
    local numSlots = C_Manastorm.GetNumLoadoutSlots()
    local slot
    for i = 1, numSlots do
        slot = self.slotPool:Acquire()
        slot:SetLoadoutSlot(i)
        slot:Show()
    end

    self:MarkDirty()
end 

ManastormLoadoutSlotMixin = CreateFromMixins("SpellIconTemplateMixin")

function ManastormLoadoutSlotMixin:OnLoad()
    SpellIconTemplateMixin.OnLoad(self)
    self:SetBackgroundAtlas("itemupgrade_greenplusicon")
    self:SetBorderSize(40, 40)
    self:SetBorderAtlas("talents-node-choiceflyout-square-gray")
    self:SetHighlightAtlas("itemupgrade_fx_slotinnerglow")
    self:SetHighlightBlendMode("ADD")
    self:SetOverlayBlendMode("ADD")
end

function ManastormLoadoutSlotMixin:OnShow()
    self:RegisterEvent("MANASTORM_LOADOUT_RESULT")
end

function ManastormLoadoutSlotMixin:OnHide()
    self:UnregisterEvent("MANASTORM_LOADOUT_RESULT")
end

function ManastormLoadoutSlotMixin:SetLoadoutSlot(index)
    self:SetID(index)
    self.layoutIndex = index
    
    local spell = C_Manastorm.GetLoadoutSpellAtIndex(index)
    self:SetSpell(spell)
    if self.spell then
        self:RegisterForDrag("LeftButton")
        self:SetBorderAtlas("talents-node-choiceflyout-square-green")
        self:SetOverlayAtlas("itemupgrade_fx_slotinnerglow")
    else
        self:RegisterForDrag()
        self:SetBorderAtlas("talents-node-choiceflyout-square-gray")
        self:SetOverlayTexture(nil)
    end
end

function ManastormLoadoutSlotMixin:OnClick()
    if self.spell and IsModifiedClick("CHATLINK") then
        ChatEdit_InsertLink(LinkUtil:GetSpellLink(self.spell.spellID))
    else
        if ManastormLoadoutFlyoutFrame:IsOwnedBy(self) then
            ManastormLoadoutFlyoutFrame:Hide()
        else
            ManastormLoadoutFlyoutFrame:Open(self)
        end
    end
end

function ManastormLoadoutSlotMixin:OnDragStart()
    if self.spell then
        local name = self.spell:GetInfo()
        PickupSpell(name)
    end
end

function ManastormLoadoutSlotMixin:OnMouseDown()
    self:SetBackgroundAtlas("itemupgrade_greenplusicon_pressed")
end

function ManastormLoadoutSlotMixin:OnMouseUp()
    if self.selected then
        return
    end
    self:SetBackgroundAtlas("itemupgrade_greenplusicon")
end

function ManastormLoadoutSlotMixin:SetSelected()
    self.selected = true
    self:LockHighlight()
    self:SetBackgroundAtlas("itemupgrade_greenplusicon_pressed")
end

function ManastormLoadoutSlotMixin:ClearSelected()
    self.selected = false
    self:UnlockHighlight()
    self:SetBackgroundAtlas("itemupgrade_greenplusicon")
end

function ManastormLoadoutSlotMixin:MANASTORM_LOADOUT_RESULT(index, result)
    if index == self:GetID() then
        self:SetLoadoutSlot(self:GetID())
    end
end 
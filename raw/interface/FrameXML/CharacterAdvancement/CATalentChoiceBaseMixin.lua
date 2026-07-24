--
-- Talent Choice Base
--
CATalentChoiceBaseMixin = CreateFromMixins("CATalentBaseMixin")

function CATalentChoiceBaseMixin:OnLoad()
    CATalentBaseMixin.OnLoad(self)
    self.nodes = {}

    self.Icon.SplitLeft = self.Icon:CreateTexture("$parentSplitLeft", "BORDER")
    self.Icon.SplitLeft:SetAllPoints()

    self.Icon.SplitRight = self.Icon:CreateTexture("$parentSplitRight", "BORDER")
    self.Icon.SplitRight:SetAllPoints()

    self.Icon.SplitLeft:Hide()
    self.Icon.SplitRight:Hide()

    -- overwrite set icon desaturated to also desaturate splitleft/right
    local setIconDesaturated = self.Icon.SetIconDesaturated
    self.Icon.SetIconDesaturated = function(self, desaturated)
        setIconDesaturated(self, desaturated)
        self.SplitRight:SetDesaturated(desaturated)
        self.SplitLeft:SetDesaturated(desaturated)
    end

    local setIconColor = self.Icon.SetIconColor
    self.Icon.SetIconColor = function(self, r, g, b, a)
        setIconColor(self, r, g, b, a)
        self.SplitRight:SetVertexColor(r, g, b, a)
        self.SplitLeft:SetVertexColor(r, g, b, a)
    end
end

function CATalentChoiceBaseMixin:AddNode(node)
    node:SetParent(self:GetSelectionFrame())
    node:SetIsSubNode(true)
    tinsert(self.nodes, node)
    self:GetSelectionFrame():MarkDirty()
    if #self.nodes > 1 then
        self:UpdateDisplay()
    end
end

function CATalentChoiceBaseMixin:GetSelectedNodeInfo()
    local rank, maxRank
    for _, node in ipairs(self.nodes) do
        rank, maxRank = C_CharacterAdvancement.GetPendingRankByEntryID(node.entry.ID)
        if rank > 0 then
            return node
        end
    end
end

function CATalentChoiceBaseMixin:UpdateIcon()
    local node = self:GetSelectedNodeInfo()
    if node then
        self.Icon.SplitLeft:Hide()
        self.Icon.SplitRight:Hide()
        if self.Icon:GetSpellID() ~= self.spellID or self.Icon.iconMask ~= self.artSet.iconMask then
            self.Icon:SetIconMask(self.artSet.iconMask, TextureUtil.MaskSize.Small)
            self.Icon:SetSpell(self.spellID)
        end
    else
        if self.Icon.SplitLeft:IsShown() then
            return
        end

        self.Icon.SplitLeft:Show()
        self.Icon.SplitRight:Show()
        self.Icon:SetSpell(nil)
        local left, right = self.nodes[1], self.nodes[2]
        if not right then
            return
        end

        if self.artSet.leftIconMask then
            self.Icon.SplitLeft:SetMaskedTexture("Interface\\Icons\\"..left.entry.Icon, self.artSet.leftIconMask, TextureUtil.MaskSize.Small)
            self.Icon.SplitRight:SetMaskedTexture("Interface\\Icons\\"..right.entry.Icon, self.artSet.rightIconMask, TextureUtil.MaskSize.Small)
        end
    end
    self.Icon:SetBackgroundAtlas(self.artSet.shadow)
end

function CATalentChoiceBaseMixin:UpdateDisplay()
    local node = self:GetSelectedNodeInfo()

    for _, subNode in ipairs(self.nodes) do
        subNode:UpdateDisplay()
    end

    self.entry = node and node.entry
    if self.entry then
        CATalentBaseMixin.UpdateDisplay(self)
    else
        local numRanks = 1
        if #self.nodes > 1 then
            self.canLearn = false
            for _, subNode in ipairs(self.nodes) do
                if C_CharacterAdvancement.CanAddByEntryID(subNode.entry.ID, numRanks) then
                    self.canLearn = true
                    break
                end
            end
        end
        self:UpdateRank()
        self:UpdateIcon()
        self.visualState = self:CalculateVisualState()
        self:UpdateConnectionVisual(self.visualState)
        self:ApplyVisualState(self.visualState)
        if GameTooltip:IsOwned(self) then
            self:OnEnter()
        end
    end
end

function CATalentChoiceBaseMixin:IsGated()
    if self.entry then
        return CATalentBaseMixin.IsGated(self)
    end

    for _, node in ipairs(self.nodes) do
        if not node:IsGated() then
            return false
        end
    end

    return true
end

function CATalentChoiceBaseMixin:ShouldBeVisible()
    return #self.nodes > 1
end

function CATalentChoiceBaseMixin:IsLocked()
    if self.entry then
        return not self.canLearn
    end

    for _, node in ipairs(self.nodes) do
        if not node:IsLocked() then
            return false
        end
    end
    
    return true
end

function CATalentChoiceBaseMixin:IsSelectable()
    if self.entry then
        return self.canLearn
    end

    for _, node in ipairs(self.nodes) do
        if node:IsSelectable() then
            return true
        end
    end

    return false
end

function CATalentChoiceBaseMixin:GetSelectionFrame()
    if not self.SelectionFrame then
        self.SelectionFrame = CreateFrame("Frame", "$parentSelectionFrame", self, "CATalentChoiceSelectionTemplate")
        self.SelectionFrame:SetPoint("BOTTOM", self, "TOP", 0, -4)
        self.SelectionFrame:SetFrameLevel(self:GetFrameLevel() + 10)
        self.SelectionFrame:Hide()
    end

    return self.SelectionFrame
end

function CATalentChoiceBaseMixin:SetSelectionFrame(selectionFrame)
    self.SelectionFrame = selectionFrame
    selectionFrame:SetFrameLevel(self:GetFrameLevel() + 10)
end

function CATalentChoiceBaseMixin:Reset()
    CATalentBaseMixin.Reset(self)
    wipe(self.nodes)
    self.isMouseOver = false
    self:SetScript("OnUpdate", nil)
    self:GetSelectionFrame():Hide()
    -- nodes themselves will be cleaned up by parent tree
end

function CATalentChoiceBaseMixin:UpdateSearchMarker()
    for _, node in ipairs(self.nodes) do
        if C_CharacterAdvancement.IsFiltered(node.entry.ID) then
            self.Icon.LocationIcon:Show()
            return
        end
    end

    self.Icon.LocationIcon:Hide()
end

function CATalentChoiceBaseMixin:OnEnter()
    self.isMouseOver = true
    self.timeSinceMouseOver = 0
    self.mouseOverTime = 0
    self:SetScript("OnUpdate", self.SelectionVisibleOnUpdate)
    if C_Realm.IsDevelopment() and self.visualState == TalentButtonUtil.BaseVisualState.Invalid then
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Group with only 1 member!")
        GameTooltip_AddIDLine(GameTooltip, "GroupID", self.nodes[1].entry.Group)
        GameTooltip:Show()
    end
end

function CATalentChoiceBaseMixin:OnLeave()
    GameTooltip:Hide()
    self.isMouseOver = false
end

local TimeToHideSeconds = 0.15
local TimeToShowSelections = 0

function CATalentChoiceBaseMixin:SelectionVisibleOnUpdate(dt)
    local selectionFrame = self:GetSelectionFrame()
    if not DoesAncestryInclude(self, GetMouseFocus()) then
        self.timeSinceMouseOver = self.timeSinceMouseOver + dt
        if self.timeSinceMouseOver > TimeToHideSeconds then
            selectionFrame:Hide()
            self:SetScript("OnUpdate", nil)
        end
    end

    if self.isMouseOver then
        self.mouseOverTime = self.mouseOverTime + dt
        if (self.mouseOverTime > TimeToShowSelections) and not selectionFrame:IsShown() then
            selectionFrame:Show()
            selectionFrame.AnimIn:Play()
        end
    end
end

function CATalentChoiceBaseMixin:CanConnect(otherEntryID)
    for _, node in ipairs(self.nodes) do
        if C_CharacterAdvancement.IsConnectionAllowed(otherEntryID, node.entry.ID) then
            return true
        end
    end
    return false
end

function CATalentChoiceBaseMixin:IsChoiceNode()
    return true
end
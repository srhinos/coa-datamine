CABranchMixin = {}
CABranchMixin.OnEvent = OnEventToMethod

local HORIZONTAL_END_OFFSET = 14
local HORIZONTAL_END_ARROW_OFFSET = HORIZONTAL_END_OFFSET + 2
local VERTICAL_END_OFFSET = 14
local VERTICAL_END_ARROW_OFFSET = VERTICAL_END_OFFSET + 2

function CABranchMixin:Reset()
    self.Left:Hide()
    self.Right:Hide()
    self.Up:Hide()
    self.Down:Hide()
    self.Center:Hide()
    self.LeftArrow:Hide()
    self.RightArrow:Hide()
    self.UpArrow:Hide()
    self.DownArrow:Hide()
    self.OuterLeftArrow:Hide()
    self.OuterRightArrow:Hide()
    self.OuterUpArrow:Hide()
    self.OuterDownArrow:Hide()


    self.Left:SetPoint("RIGHT", self, "CENTER", -4, 0)
    self.Right:SetPoint("LEFT", self, "CENTER", 4, 0)
    self.Up:SetPoint("BOTTOM", self, "CENTER", 0, 4)
    self.Down:SetPoint("TOP", self, "CENTER", 0, -4)
    self.LeftArrow:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.RightArrow:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.UpArrow:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.DownArrow:SetPoint("CENTER", self, "CENTER", 0, 0)
    self.node = nil
    self.nodeID = nil
end

function CABranchMixin:OnShow()
    self:RegisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CABranchMixin:OnHide()
    self:UnregisterEvent("CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED")
end

function CABranchMixin:CHARACTER_ADVANCEMENT_PENDING_BUILD_UPDATED()
    self:Refresh()
end

function CABranchMixin:SetDirection(node, enabled)
    local suffix = enabled and "" or "-disabled"
    self.Left:SetAtlas("_ui-talentbranch-horizontal"..suffix)
    self.Right:SetAtlas("_ui-talentbranch-horizontal"..suffix)
    self.Up:SetAtlas("!ui-talentbranch-vertical"..suffix)
    self.Down:SetAtlas("!ui-talentbranch-vertical"..suffix)

    self.LeftArrow:SetAtlas("ui-talentbranch-arrow-left"..suffix)
    self.RightArrow:SetAtlas("ui-talentbranch-arrow-right"..suffix)
    self.UpArrow:SetAtlas("ui-talentbranch-arrow-up"..suffix)
    self.DownArrow:SetAtlas("ui-talentbranch-arrow-down"..suffix)
    self.OuterLeftArrow:SetAtlas("ui-talentbranch-arrow-left"..suffix)
    self.OuterRightArrow:SetAtlas("ui-talentbranch-arrow-right"..suffix)
    self.OuterUpArrow:SetAtlas("ui-talentbranch-arrow-up"..suffix)
    self.OuterDownArrow:SetAtlas("ui-talentbranch-arrow-down"..suffix)
    local left = node.left
    local right = node.right
    local up = node.up
    local down = node.down
    -- imagine a square taking up a full node, touching every talent around it
    -- 
    --     up    
    -- left + right
    --    down
    
    -- if a node moves right then down, then left + down will need to be enabled
    -- if a node moves straight down, then up will need to be enabled. 
    -- if a node moves straight right, then left will need to be enabled.

    local showLeft = right
    local showRight = left
    
    self.Left:SetShown(showLeft)
    self.Right:SetShown(showRight)

    if (left or right) then
        self.Up:SetShown(up)
        self.Down:SetShown(down)
    else
        -- otherwise this is a single up or down node
        -- so inverse
        self.Up:SetShown(down)
        self.Down:SetShown(up)
    end

    if left then
        if up then
            self.Center:SetAtlas("ui-talentbranch-bl"..suffix)
            self.Center:SetPointOffset(-1, -1)
            self.Center:Show()
        elseif down then
            self.Center:SetAtlas("ui-talentbranch-tl"..suffix)
            self.Center:SetPointOffset(-1, 1)
            self.Center:Show()
        elseif right then
            self.Right:SetPoint("LEFT", self, "CENTER", 0, 0)
            self.Left:SetPoint("RIGHT", self, "CENTER", 0, 0)
        end
    elseif right then
        if up then
            self.Center:SetAtlas("ui-talentbranch-br"..suffix)
            self.Center:SetPointOffset(1, -1)
            self.Center:Show()
        elseif down then
            self.Center:SetAtlas("ui-talentbranch-tr"..suffix)
            self.Center:SetPointOffset(1, 1)
            self.Center:Show()
        end
    elseif up and down then
        self.Up:SetPoint("BOTTOM", self, "CENTER", 0, 0)
        self.Down:SetPoint("TOP", self, "CENTER", 0, 0)
    end
end 

function CABranchMixin:SetNode(node, nodeID)
    self.node = node
    self.nodeID = nodeID
    self:Refresh()
end

function CABranchMixin:Refresh()
    if self.node and self.nodeID then
        local numRanks = 1
        local meetsRequirements = C_CharacterAdvancement.IsKnownID(self.nodeID) or
                C_CharacterAdvancement.IsPendingEntryID(self.nodeID) or
                C_CharacterAdvancement.CanAddByEntryID(self.nodeID, numRanks)
        self:SetDirection(self.node, meetsRequirements)
    end
end

function CABranchMixin:SetTargetNodeID(nodeID)
    self.nodeID = nodeID
end

function CABranchMixin:SetIsEndNode(node)
    local left = node.left
    local right = node.right
    local up = node.up
    local down = node.down
    local direction = node.direction 

    if direction == "left" then
        if up then
            self.OuterUpArrow:Show()
        elseif down then
            self.OuterDownArrow:Show()
        elseif left and right then
            self.OuterLeftArrow:Show()
        else
            self.Right:SetPoint("LEFT", self, "CENTER", HORIZONTAL_END_OFFSET, 0)
            self.LeftArrow:SetPoint("CENTER", self, "CENTER", HORIZONTAL_END_ARROW_OFFSET, 0)
            self.LeftArrow:Show()
        end
    elseif direction == "right" then
        if up then
            self.OuterUpArrow:Show()
        elseif down then
            self.OuterDownArrow:Show()
        elseif left and right then
            self.OuterRightArrow:Show()
        else
            self.Left:SetPoint("RIGHT", self, "CENTER", -HORIZONTAL_END_OFFSET, 0)
            self.RightArrow:SetPoint("CENTER", self, "CENTER", -HORIZONTAL_END_ARROW_OFFSET, 0)
            self.RightArrow:Show()
        end
    elseif direction == "up" then
        if up and down then
            self.OuterUpArrow:Show()
        else
            self.Down:SetPoint("TOP", self, "CENTER", 0, -VERTICAL_END_OFFSET)
            self.UpArrow:SetPoint("CENTER", self, "CENTER", 0, -VERTICAL_END_ARROW_OFFSET)
            self.UpArrow:Show()
        end
    elseif direction == "down" then
        if up and down then
            self.OuterDownArrow:Show()
        else
            self.Up:SetPoint("BOTTOM", self, "CENTER", 0, VERTICAL_END_OFFSET)
            self.DownArrow:SetPoint("CENTER", self, "CENTER", 0, VERTICAL_END_ARROW_OFFSET)
            self.DownArrow:Show()
        end
    end
end
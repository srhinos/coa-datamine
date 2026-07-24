
local function BuildHorizontalConnectionOrder(order, isSubNode, startColumn, endColumn, lastNode)
    local numColumns = math.abs(endColumn - startColumn)
    local isLeft = startColumn > endColumn
    local isRight = not isLeft
    local direction = isLeft and "left" or "right"
    local numNodes = numColumns  - 1
    if isSubNode then
        if lastNode then
            lastNode.left = isLeft
            lastNode.right = isRight
        end
    else
        -- this makes it so there is always 1 node
        -- unless its a corner, making this a subnode
        -- subnodes come after corner nodes and may not need a node
        numNodes = math.max(1, numNodes)
    end
    
    for i = 1, numNodes do
        if lastNode and (lastNode.direction == "left" or lastNode.direction == "right") then
            lastNode.left = lastNode.left or isLeft
            lastNode.right = lastNode.right or isRight
        end
        if lastNode and lastNode.left then
            isRight = true
        end

        if lastNode and lastNode.right then
            isLeft = true
        end

        if numColumns == 2 then
            -- 2 spaces need to use a full length connection
            isLeft = true
            isRight = true
        end
        lastNode = { left = isLeft, right = isRight, direction = direction }
        
        tinsert(order, lastNode)
    end
    
    return lastNode
end

local function BuildVerticalConnectionOrder(order, isSubNode, startRow, endRow, lastNode)
    local isUp = startRow > endRow
    local isDown = not isUp
    local direction = isUp and "up" or "down"
    local numRows = math.abs(endRow - startRow)
    local numNodes = numRows - 1
    if isSubNode then
        if lastNode then
            lastNode.up = isUp
            lastNode.down = isDown
        end
    else
        -- this makes it so there is always 1 node
        -- unless its a corner, making this a subnode
        -- subnodes come after corner nodes and may not need a node
        numNodes = math.max(1, numNodes)
    end
    
    for i = 1, numNodes do
        if lastNode and (lastNode.direction == "up" or lastNode.direction == "down") then
            lastNode.up = lastNode.up or isDown
            lastNode.down = lastNode.down or isUp
        end
        if lastNode and lastNode.up then
            isDown = true
        end

        if lastNode and lastNode.down then
            isUp = true
        end
        if numRows == 2 then
            -- 2 spaces need to use a full length connection
            isUp = true
            isDown = true
        end
        lastNode = { up = isUp, down = isDown, direction = direction }
        tinsert(order,  lastNode)
    end
    
    return lastNode
end

local function ResetBranchNode(pool, branchNode)
    branchNode:ClearAllPoints()
    branchNode:Hide()
    branchNode:Reset()
end

CAConnectedNodesMixin = {}

function CAConnectedNodesMixin:OnLoad()
    self.ConnectedNodes = {}
    self.NodeMap = {}
    self.FilledNodes = {}
    self.LinePool = CreateFramePool("Frame", self, "CATalentBranchTemplate", ResetBranchNode)
end

function CAConnectedNodesMixin:DebugConnectedNodes()
    for entryID, node in pairs(self.ConnectedNodes) do
        if not node.targets then
            print("Node with no targets: EntryID:", entryID)
        else
            for index, nodeTarget in ipairs(node.targets) do
                print(entryID, "FROM:", node.column, node.row, "TO:", nodeTarget.button.entry.ID, nodeTarget.column, nodeTarget.row)
            end
        end
    end
end

function CAConnectedNodesMixin:CanMakeHorizontalConnection(startColumn, endColumn, row)
    if startColumn > endColumn then
        for i = startColumn - 1, endColumn + 1, -1 do
            if self.FilledNodes[i] and self.FilledNodes[i][row] then
                return false
            end
        end
    else
        for i = startColumn + 1, endColumn - 1 do
            if self.FilledNodes[i] and self.FilledNodes[i][row] then
                return false
            end
        end
    end

    return true
end

function CAConnectedNodesMixin:CanMakeVerticalConnection(startRow, endRow, column)
    if startRow > endRow then
        for i = startRow - 1, endRow + 1, -1 do
            if self.FilledNodes[column] and self.FilledNodes[column][i] then
                return false
            end
        end
    else
        for i = startRow + 1, endRow - 1 do
            if self.FilledNodes[column] and self.FilledNodes[column][i] then
                return false
            end
        end
    end

    return true
end

function CAConnectedNodesMixin:GetConnectionOrder(startColumn, startRow, endColumn, endRow)
    local order = {}

    local differentColumns = startColumn ~= endColumn
    local differentRows = startRow ~= endRow
    
    local needsHorizontal = differentColumns
    local needsVertical = differentRows
    local lastNode
    
    -- check if we can go left/right then down/up
    if needsHorizontal then
        if self:CanMakeHorizontalConnection(startColumn, endColumn, startRow) then
            lastNode = BuildHorizontalConnectionOrder(order, false, startColumn, endColumn, lastNode)

            if needsVertical and self:CanMakeVerticalConnection(startColumn, endColumn, endRow) then
                needsVertical = false
                lastNode = BuildVerticalConnectionOrder(order, true, startRow, endRow, lastNode)
            end
            
            return not needsVertical and order or false
        end
    end

    -- check if we can go up/down then left/right
    if needsVertical then
        if self:CanMakeVerticalConnection(startColumn, endColumn, endRow) then
            lastNode = BuildVerticalConnectionOrder(order, false, startRow, endRow, lastNode)

            if needsHorizontal and self:CanMakeHorizontalConnection(startRow, endRow, endColumn) then
                needsHorizontal = false
                lastNode = BuildVerticalConnectionOrder(order, true, startRow, endRow, lastNode)
            end
            
            return not needsHorizontal and order or false
        end
    else
        return false
    end
    
    return order
end

function CAConnectedNodesMixin:DrawConnectedNodes()
    local frameLevel = self:GetFrameLevel() + 5
    for entryID, parentNode in pairs(self.ConnectedNodes) do
        for _, nodeTarget in ipairs(parentNode.targets) do
            local currentColumn = parentNode.column
            local currentRow = parentNode.row

            local otherButton = nodeTarget.button
            
            local targetColumn = nodeTarget.column
            local targetRow = nodeTarget.row
            local otherID = otherButton.entry.ID

            if not currentColumn or not currentRow then
                C_Logger.Error("Cannot draw connection [Parent-EntryID: %s] -> [Target-EntryID: %s]. Parent ID Does not exist. This means the Target ID has an invalid connected node.", entryID, otherButton.entry.ID)
            else
                local ConnectionOrder = self:GetConnectionOrder(currentColumn, currentRow, targetColumn, targetRow)

                --dprint("Connecting", button.entry.ID, currentColumn, currentRow, "to", otherID, targetColumn, targetRow)
                if ConnectionOrder then
                    local yStarting = self.normalFooter and 42 or 64

                    if C_Player:IsDefaultClass() then
                        yStarting = 56
                    end
                    
                    local x, y = 0, 0
                    local column, row
                    local branchNode
                    local numNodes = #ConnectionOrder
                    for index, node in ipairs(ConnectionOrder) do
                        branchNode = self.LinePool:Acquire()
                        branchNode:SetFrameLevel(frameLevel)
                        if node.direction == "left" then
                            currentColumn = currentColumn - 1
                        elseif node.direction == "right" then
                            currentColumn = currentColumn + 1
                        elseif node.direction == "up" then
                            currentRow = currentRow - 1
                        elseif node.direction == "down" then
                            currentRow = currentRow + 1
                        end
                        column = currentColumn
                        row = currentRow
                        --dprint("Connection", index, "IsLeft", node.left, "IsRight", node.right, "IsUp", node.up, "IsDown", node.down, "Direction", node.direction)
                        --dprint("Target Position:", column, row)

                        x = -58-26 + column * 52 + (self.shift or 0)-- -26 to center 4 rows under essence text 
                        --y = 42 + row * (self.normalFooter and 44 or 46)
                        y = -6 + yStarting + row * 44

                        if index == numNodes then
                            branchNode:SetIsEndNode(node)
                        end

                        branchNode:SetNode(node, otherID)

                        branchNode:ClearAndSetPoint("TOP", self, "TOP", x, -y+4)
                        branchNode:Show()
                    end
                else
                    -- no connection possible
                    C_Logger.Error("Cannot draw connection [EntryID: %s] -> [EntryID: %s]. No Possible Route.", entryID, otherButton.entry.ID)
                end
            end
        end
    end
end
CAConnectionBaseMixin = {}

function CAConnectionBaseMixin:OnLoad()
end

function CAConnectionBaseMixin:SetStartNode(node)
    self.startNode = node
    self:Build()
end 

function CAConnectionBaseMixin:SetEndNode(node)
    self.endNode = node
    self:Build()
end 

function CAConnectionBaseMixin:GetStartNode()
    return self.startNode
end

function CAConnectionBaseMixin:GetEndNode()
    return self.endNode
end

function CAConnectionBaseMixin:CanBuild()
    if not self:GetStartNode() or not self:GetEndNode() then
        self:Hide()
        return false
    end

    self:Show()
    return true
end

function CAConnectionBaseMixin:Build()
    if not self:CanBuild() then
        return
    end
end 

function CAConnectionBaseMixin:UpdateConnectionState()
end 
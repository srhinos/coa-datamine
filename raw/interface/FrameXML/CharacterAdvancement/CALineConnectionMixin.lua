CALineConnectionMixin = CreateFromMixins("CAConnectionBaseMixin")

function CALineConnectionMixin:OnLoad()
    CAConnectionBaseMixin.OnLoad(self)
    Mixin(self.Line1, "LineMixin")
    Mixin(self.Line2, "LineMixin")
    self.Line1:SetThickness(4)
    self.Line1:SetRelativePoint("BOTTOMLEFT")

    self.Line2:SetThickness(2)
    self.Line2:SetRelativePoint("BOTTOMLEFT")
    self.Arrow:SetFrameLevel(self:GetFrameLevel()+5)
end

function CALineConnectionMixin:Build()
    if not self:CanBuild() then
        return
    end
    
    local startNode = self:GetStartNode()
    local endNode = self:GetEndNode()
    
    local startX, startY = startNode.positionX, startNode.positionY
    local endX, endY = endNode.positionX, endNode.positionY
    
    -- positions are topleft not bottom left
    -- subtract from height to get bottom left y
    local height = self:GetParent():GetHeight()
    startY = startY + height
    endY = endY + height

    -- nodes are positioned at their top left so move x/y to centers
    local startWidth, startHeight = startNode:GetSize()
    local halfStartWidth, halfStartHeight = startWidth / 2, startHeight / 2
    startX = startX + halfStartWidth
    startY = startY - halfStartHeight

    local endWidth, endHeight = endNode:GetSize()
    local halfEndWidth, halfEndHeight = endWidth / 2, endHeight / 2
    endX = endX + halfEndWidth
    endY = endY - halfEndHeight
    
    -- size this connection frame to contain both positions
    local sizeX, sizeY = math.abs(startX - endX), math.abs(startY - endY)
    -- pad vertical / horizontal boxes
    self:SetSize(math.max(sizeX, 4), math.max(sizeY, 4))
    
    -- position bottom left at min point
    local left = math.min(startX, endX)
    local bottom = math.min(startY, endY)
    self:SetPoint("BOTTOMLEFT", left, bottom)

    -- shift so startx/y are relative to this connection frame
    startX = startX - left
    startY = startY - bottom
    endX = endX - left
    endY = endY - bottom

    -- draw lines
    local startPoint = Vector2D(startX, startY)
    local endPoint = Vector2D(endX, endY)
    self.Line1:SetStartPoint(startPoint)
    self.Line1:SetEndPoint(endPoint)
    self.Line1:Draw()
    
    self.Line2:SetStartPoint(startPoint)
    self.Line2:SetEndPoint(endPoint)
    self.Line2:Draw()

    -- get angle between start and end point
    -- rotate arrow to point at start node (visually the end node but connectedIDs are visually backwards)
    local degrees = startPoint:DegreesBetween(endPoint)
    local radians = math.rad(degrees-90)
    self.arrowAngle = radians
    

    local dirX = -math.sin(radians)
    local dirY = math.cos(radians)

    -- calc radius and offset by art 
    local edgeOffset = self:GetNodeArtOffset(radians)
    local offsetDistance = edgeOffset
    local radius = math.min(halfStartWidth, halfStartHeight)
    offsetDistance = offsetDistance + radius

    local offsetX = dirX * offsetDistance
    local offsetY = dirY * offsetDistance

    self.Arrow:SetPoint("CENTER", self, "BOTTOMLEFT", startX + offsetX, startY + offsetY)
    self.Arrow.Texture:SetRotation(self.arrowAngle)
end

function CALineConnectionMixin:UpdateConnectionState(state)
    local r, g, b, a

    if state == TalentButtonUtil.ConnectionState.Invalid then
        r, g, b, a = RED_FONT_COLOR:GetRGBA()
        self.Arrow.Texture:SetTexture("Interface\\TalentFrame\\talents-arrow-head-red")
    elseif state == TalentButtonUtil.ConnectionState.Gated then
        r, g, b, a = 0.2, 0.2, 0.2, 1
        self.Arrow.Texture:SetTexture("Interface\\TalentFrame\\talents-arrow-head-locked")
    elseif state == TalentButtonUtil.ConnectionState.Connected then
        r, g, b, a = 0.65, 0.54, 0.06, 1
        self.Arrow.Texture:SetTexture("Interface\\TalentFrame\\talents-arrow-head-yellow")
    elseif state == TalentButtonUtil.ConnectionState.NoConnection then
        -- should be unreachable
        r, g, b, a = 0.3, 0.3, 0.3, 1
        self.Arrow.Texture:SetTexture("Interface\\TalentFrame\\talents-arrow-head-gray")
    end
    self.Arrow.Texture:SetRotation(self.arrowAngle)
    self.Line2:SetVertexColor(r, g, b, a)
end

function CALineConnectionMixin:GetNodeArtOffset(angle)
    local visualShape = self:GetStartNode():GetShape()
    if visualShape == TalentButtonUtil.VisualShape.Choice then
        return self:GetChoiceEdgeDiameterOffset(angle)
    elseif visualShape == TalentButtonUtil.VisualShape.Circle then
        return self:GetCircleEdgeDiameterOffset(angle)
    elseif visualShape == TalentButtonUtil.VisualShape.Square then
        return self:GetSquareEdgeDiameterOffset(angle)
    else
        return 0
    end
end

local quarterRotation = math.pi / 2
local eighthRotation = quarterRotation / 2
local sixteenthRotation = eighthRotation / 2
function CALineConnectionMixin:GetCircleEdgeDiameterOffset(unused_angle)
    return TalentButtonUtil.CircleEdgeDiameterOffset
end

function CALineConnectionMixin:GetSquareEdgeDiameterOffset(angle)
    local progress = math.abs(angle % quarterRotation) - eighthRotation
    return Lerp(TalentButtonUtil.SquareEdgeMinDiameterOffset, TalentButtonUtil.SquareEdgeMaxDiameterOffset, progress)
end

function CALineConnectionMixin:GetChoiceEdgeDiameterOffset(angle)
    local progress = math.abs(angle % eighthRotation) - sixteenthRotation
    return Lerp(TalentButtonUtil.ChoiceEdgeMinDiameterOffset, TalentButtonUtil.ChoiceEdgeMaxDiameterOffset, progress)
end
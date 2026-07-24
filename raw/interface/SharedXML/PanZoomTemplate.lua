PanZoomMixin = {}

function PanZoomMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
end

function PanZoomMixin:OnShow()
    self:UpdateArea()
    self:Center()
end

function PanZoomMixin:OnSizeChanged()
    self:UpdateArea()
end 

function PanZoomMixin:UpdateArea()
    self.Area:SetSize(self:GetWidth(), self:GetHeight())
end 

function PanZoomMixin:Center()
    self:SetHorizontalScroll((self.Area:GetWidth() - self:GetWidth()) / 2)
    self:SetVerticalScroll((self.Area:GetHeight() - self:GetHeight()) / 2)
end

function PanZoomMixin:Reset()
    self:Center()
    self.Content:SetScale(1)
end

function PanZoomMixin:SetContent(content)
    self.Content = content
    self.Content:SetParent(self.Area)
    self.Content:ClearAndSetPoint("CENTER")
end

function PanZoomMixin:FitContent(contentWidth, contentHeight)
    local areaWidth, areaHeight = self.Area:GetSize()
    -- make a little smaller just so content fits better
    areaWidth = areaWidth - 64
    areaHeight = areaHeight - 64
    local scale = math.min(areaWidth / contentWidth, areaHeight / contentHeight)
    self.Content:SetScale(scale)
end

function PanZoomMixin:OnDragStart()
    CloseDropDownMenus()
    self.dragStartX, self.dragStartY = GetCursorPosition()
    self:SetScript("OnUpdate", self.DragUpdate)
end 

function PanZoomMixin:DragUpdate(elapsed)
    local x, y = GetCursorPosition()
    local dx = (x - self.dragStartX)
    local dy = (y - self.dragStartY)
    self.dragStartX, self.dragStartY = x, y
    
    self:SetHorizontalScroll(self:GetHorizontalScroll() - dx)
    self:SetVerticalScroll(self:GetVerticalScroll() + dy)
end

function PanZoomMixin:OnDragStop()
    self:SetScript("OnUpdate", nil)
end 

function PanZoomMixin:OnMouseWheel(delta)
    local scale  = self.Content:GetScale()
    scale = scale + (delta * 0.1)
    scale = math.clamp(scale, 0.1, 4)
    self.Content:SetScale(scale)
end
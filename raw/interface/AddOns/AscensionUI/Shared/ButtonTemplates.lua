function ItemButtonOnEnter(self)
    if (self.Item) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetHyperlink("|Hitem:"..self.Item.."|h[test]|h")
        GameTooltip:Show()
    end
end

function ItemButtonOnClick(self)
    if ( IsModifiedClick("CHATLINK") ) then
        if (self.Item) then
            local _, link = GetItemInfo("|Hitem:"..self.Item.."|h[test]|h")
            if ( link ) then
                ChatEdit_InsertLink(link);
            end
        end
        return
    end
end

function MagicButton_OnLoad(self)
    local leftHandled = false;
    local rightHandled = false;

    -- Find out where this button is anchored and adjust positions/separators as necessary
    for i=1, self:GetNumPoints() do
        local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint(i);

        if (relativeTo:GetObjectType() == "Button" and (point == "TOPLEFT" or point == "LEFT")) then

            if (offsetX == 0 and offsetY == 0) then
                self:SetPoint(point, relativeTo, relativePoint, 1, 0);
            end

            if (relativeTo.RightSeparator) then
                -- Modify separator to make it a Middle
                self.LeftSeparator = relativeTo.RightSeparator;
            else
                -- Add a Middle separator
                self.LeftSeparator = self:CreateTexture(self:GetName() and self:GetName().."_LeftSeparator" or nil, "BORDER");
                relativeTo.RightSeparator = self.LeftSeparator;
            end

            self.LeftSeparator:SetTexture("Interface\\FrameGeneral\\UI-Frame");
            self.LeftSeparator:SetTexCoord(0.00781250, 0.10937500, 0.75781250, 0.95312500);
            self.LeftSeparator:SetWidth(13);
            self.LeftSeparator:SetHeight(25);
            self.LeftSeparator:SetPoint("TOPRIGHT", self, "TOPLEFT", 5, 1);

            leftHandled = true;

        elseif (relativeTo:GetObjectType() == "Button" and (point == "TOPRIGHT" or point == "RIGHT")) then

            if (offsetX == 0 and offsetY == 0) then
                self:SetPoint(point, relativeTo, relativePoint, -1, 0);
            end

            if (relativeTo.LeftSeparator) then
                -- Modify separator to make it a Middle
                self.RightSeparator = relativeTo.LeftSeparator;
            else
                -- Add a Middle separator
                self.RightSeparator = self:CreateTexture(self:GetName() and self:GetName().."_RightSeparator" or nil, "BORDER");
                relativeTo.LeftSeparator = self.RightSeparator;
            end

            self.RightSeparator:SetTexture("Interface\\FrameGeneral\\UI-Frame");
            self.RightSeparator:SetTexCoord(0.00781250, 0.10937500, 0.75781250, 0.95312500);
            self.RightSeparator:SetWidth(13);
            self.RightSeparator:SetHeight(25);
            self.RightSeparator:SetPoint("TOPLEFT", self, "TOPRIGHT", -5, 1);

            rightHandled = true;

        elseif (point == "BOTTOMLEFT") then
            if (offsetX == 0 and offsetY == 0) then
                self:SetPoint(point, relativeTo, relativePoint, 4, 4);
            end
            leftHandled = true;
        elseif (point == "BOTTOMRIGHT") then
            if (offsetX == 0 and offsetY == 0) then
                self:SetPoint(point, relativeTo, relativePoint, -6, 4);
            end
            rightHandled = true;
        elseif (point == "BOTTOM") then
            if (offsetY == 0) then
                self:SetPoint(point, relativeTo, relativePoint, 0, 4);
            end
        end
    end

    -- If this button didn't have a left anchor, add the left border texture
    if (not leftHandled) then
        if (not self.LeftSeparator) then
            -- Add a Left border
            self.LeftSeparator = self:CreateTexture(self:GetName() and self:GetName().."_LeftSeparator" or nil, "BORDER");
            self.LeftSeparator:SetTexture("Interface\\FrameGeneral\\UI-Frame");
            self.LeftSeparator:SetTexCoord(0.24218750, 0.32812500, 0.63281250, 0.82812500);
            self.LeftSeparator:SetWidth(11);
            self.LeftSeparator:SetHeight(25);
            self.LeftSeparator:SetPoint("TOPRIGHT", self, "TOPLEFT", 6, 2);
        end
    end

    -- If this button didn't have a right anchor, add the right border texture
    if (not rightHandled) then
        if (not self.RightSeparator) then
            -- Add a Right border
            self.RightSeparator = self:CreateTexture(self:GetName() and self:GetName().."_RightSeparator" or nil, "BORDER");
            self.RightSeparator:SetTexture("Interface\\FrameGeneral\\UI-Frame");
            self.RightSeparator:SetTexCoord(0.90625000, 0.99218750, 0.00781250, 0.20312500);
            self.RightSeparator:SetWidth(11);
            self.RightSeparator:SetHeight(25);
            self.RightSeparator:SetPoint("TOPLEFT", self, "TOPRIGHT", -6, 2);
        end
    end
end

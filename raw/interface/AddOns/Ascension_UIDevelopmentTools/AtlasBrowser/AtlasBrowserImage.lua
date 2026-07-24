AtlasBrowserImageMixin = {}

local TextureXML = [[
<Texture file="%s">
    <Size x="%s" y="%s"/>
    <TexCoords left="%s" right="%s" top="%s" bottom="%s"/>
</Texture>]]

local TextureLUA = [[[%s] = {%s, %s, %s, %s, %s, %s, %s, %s},]]

local TexturePlain = [[
%s
Width: %s
Height: %s
Left: %s
Right: %s
Top: %s
Bottom: %s
H-Tile: %s
V-Tile: %s]]

function AtlasBrowserImageMixin:OnLoad()
    self.AtlasFramePool = CreateFramePool("Button", self, "AtlasBrowserAtlasFrameTemplate")
    local textureQueryUpdate = CreateFrame("Frame", nil, self)
    textureQueryUpdate:SetAllPoints(self.Image)
    textureQueryUpdate:SetScript("OnSizeChanged", function(queryFrame, w, h)
        if self.texture ~= queryFrame.lastTexture then
            queryFrame.lastTexture = self.texture
            local hasSize = w > 0 and h > 0
            local hasTexture = self.texture and self.atlases
            local textureIsSet = self.Image:GetTexture() == self.texture
            self:OnTextureLoaded(hasSize and hasTexture and textureIsSet)
        end
    end)
    self.Background = self:CreateTexture(nil, "BACKGROUND")
    self.Background:SetPoint("TOPLEFT", self.Image)
    self.Background:SetPoint("BOTTOMRIGHT", self.Image)
    self.Background:SetTexture(0.35, 0.35, 0.35, 0.75)
end

function AtlasBrowserImageMixin:SetTextureInfo(texture, atlases)
    if self.texture == texture then
        self.PanZoom:Reset()
        self.PanZoom:FitContent(self.Image:GetSize())
        return
    end
    self.PanZoom.Name:SetText(texture)
    self.texture = texture
    self.atlases = atlases
    self.AtlasFramePool:ReleaseAll()
    self.Image:SetTexture(texture)
    self.Image:SetSize(0, 0)
    self.PanZoom:Reset()
end

function AtlasBrowserImageMixin:OnTextureLoaded(isLoaded)
    if isLoaded then
        self.PanZoom:Reset()
        self.PanZoom:FitContent(self.Image:GetSize())

        for _, atlasName in ipairs(self.atlases) do
            local atlasFrame = self.AtlasFramePool:Acquire()
            atlasFrame:SetAtlasInfo(atlasName)
            atlasFrame:Show()
        end
    end
end

function AtlasBrowserImageMixin:GetDropDown()
    if not self.DropDown then
        self.DropDown = CreateFrame("Frame", "AtlasBrowserImageDropDown", self, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
    end
    return self.DropDown
end

function AtlasBrowserImageMixin:InitializeDropDown(dropdown, level, menuList)
    if not dropdown.atlas then return end

    local info = UIDropDownMenu_CreateInfo()
    info.text = "Copy Atlas to Clipboard"
    info.func = function()
        Internal_CopyToClipboard(dropdown.atlas)
    end
    UIDropDownMenu_AddButton(info, level)
    
    info.text = "Copy XML to Clipboard"
    info.func = function()
        local xml = TextureXML:format(self.texture,
                dropdown.atlasInfo.width,
                dropdown.atlasInfo.height,
                dropdown.atlasInfo.leftTexCoord,
                dropdown.atlasInfo.rightTexCoord,
                dropdown.atlasInfo.topTexCoord,
                dropdown.atlasInfo.bottomTexCoord)
        Internal_CopyToClipboard(xml)
    end
    UIDropDownMenu_AddButton(info, level)
    
    info.text = "Copy LUA To Clipboard"
    info.func = function()
        local lua = TextureLUA:format(dropdown.atlas,
                dropdown.atlasInfo.width,
                dropdown.atlasInfo.height,
                dropdown.atlasInfo.leftTexCoord,
                dropdown.atlasInfo.rightTexCoord,
                dropdown.atlasInfo.topTexCoord,
                dropdown.atlasInfo.bottomTexCoord,
                tostring(dropdown.atlasInfo.tilesHorizontally),
                tostring(dropdown.atlasInfo.tilesVertically))
        Internal_CopyToClipboard(lua)
    end
    UIDropDownMenu_AddButton(info, level)
    
    info.text = "Copy Plain Text to Clipboard"
    info.func = function()
        local plain = TexturePlain:format(dropdown.atlas,
                dropdown.atlasInfo.width,
                dropdown.atlasInfo.height,
                dropdown.atlasInfo.leftTexCoord,
                dropdown.atlasInfo.rightTexCoord,
                dropdown.atlasInfo.topTexCoord,
                dropdown.atlasInfo.bottomTexCoord,
                tostring(dropdown.atlasInfo.tilesHorizontally),
                tostring(dropdown.atlasInfo.tilesVertically))
        Internal_CopyToClipboard(plain)
    end
    UIDropDownMenu_AddButton(info, level)
end

function AtlasBrowserImageMixin:ShowDropDown(atlasFrame)
    local dropdown = self:GetDropDown()
    dropdown.atlasInfo = atlasFrame.atlasInfo
    dropdown.atlas = atlasFrame.atlas
    ToggleDropDownMenu(1, nil, dropdown, atlasFrame:GetName(), 0, 0)
end

AtlasBrowserAtlasFrameMixin = {}

function AtlasBrowserAtlasFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function AtlasBrowserAtlasFrameMixin:OnShow()
    self.callbackHandle = AtlasBrowser:RegisterCallbackWithHandle("SearchTextChanged", self.UpdateBorder, self)
end

function AtlasBrowserAtlasFrameMixin:OnHide()
    if self.callbackHandle then
        self.callbackHandle:Unregister()
        self.callbackHandle = nil
    end
end

function AtlasBrowserAtlasFrameMixin:SetAtlasInfo(atlas)
    local parent = self:GetParent().Image
    local atlasInfo = AtlasUtil:GetAtlasInfo(atlas)
    self.atlas = atlas
    self.atlasInfo = atlasInfo
    self:ClearAllPoints()
    
    local width, height = parent:GetSize()
    
    self:SetPoint("TOPLEFT", parent, "TOPLEFT", atlasInfo.leftTexCoord * width, -atlasInfo.topTexCoord * height);
    self:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", atlasInfo.rightTexCoord * width, -atlasInfo.bottomTexCoord * height);
    self:UpdateBorder()
end 

function AtlasBrowserAtlasFrameMixin:UpdateBorder()
    if AtlasBrowser:HasSearch() then
        if AtlasBrowser:MatchesSearch(self.atlas or "") then
            self:SetGreenBorder()
        else
            self:SetNotMatchingBorder()
        end
    else
        self:SetNormalBorder()
    end
end

function AtlasBrowserAtlasFrameMixin:SetGreenBorder()
    self:SetBorderColor(0, 1, 0, 0.6)
end

function AtlasBrowserAtlasFrameMixin:SetNormalBorder()
    self:SetBorderColor(1, 1, 1, 0.25)
end

function AtlasBrowserAtlasFrameMixin:SetNotMatchingBorder()
    self:SetBorderColor(1, 1, 1, 0.15)
end

function AtlasBrowserAtlasFrameMixin:SetBorderColor(r, g, b, a)
    self.Left:SetVertexColor(r, g, b, a)
    self.Right:SetVertexColor(r, g, b, a)
    self.Top:SetVertexColor(r, g, b, a)
    self.Bottom:SetVertexColor(r, g, b, a)
end

function AtlasBrowserAtlasFrameMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 0)
    GameTooltip:SetText(self.atlas, 0, 0.82, 1)
    GameTooltip:AddDoubleLine("Width:", self.atlasInfo.width, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("Height:", self.atlasInfo.height, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("Left:", self.atlasInfo.leftTexCoord, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("Right:", self.atlasInfo.rightTexCoord, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("Top:", self.atlasInfo.topTexCoord, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("Bottom:", self.atlasInfo.bottomTexCoord, 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("H-Tile:", tostring(self.atlasInfo.tilesHorizontally), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine("V-Tile:", tostring(self.atlasInfo.tilesVertically), 1, 0.82, 0, 1, 1, 1)
    
    GameTooltip:AddLine("<Click to copy atlas to clipboard>", 0, 1, 0, 1)
    GameTooltip:AddLine("<Right-Click for more>", 0, 1, 0, 1)
    GameTooltip:Show()
end 

function AtlasBrowserAtlasFrameMixin:OnLeave()
    GameTooltip:Hide()
end

function AtlasBrowserAtlasFrameMixin:OnDragStart()
    self:GetParent().PanZoom:OnDragStart()
end 

function AtlasBrowserAtlasFrameMixin:OnDragStop()
    self:GetParent().PanZoom:OnDragStop()
end

function AtlasBrowserAtlasFrameMixin:OnClick(button)
    CloseDropDownMenus()
    if button == "LeftButton" then
        local atlas = self.atlas
        if atlas then
            Internal_CopyToClipboard(atlas)
        end
        
        self.CopyFlash.Anim:Play()
    elseif button == "RightButton" then
        self:GetParent():ShowDropDown(self)
    end
end 
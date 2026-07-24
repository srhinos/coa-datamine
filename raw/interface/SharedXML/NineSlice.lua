local function GetNineSlicePiece(container, pieceName)
	if container.GetNineSlicePiece then
		local piece = container:GetNineSlicePiece(pieceName);
		if piece then
			return piece, true;
		end
	end

	local piece = container[pieceName];
	if piece then
		return piece, true;
	else
		piece = container:CreateTexture()
		container[pieceName] = piece;
		return piece, false;
	end
end

local function SetupTextureCoordinates(piece, setupInfo, pieceLayout, textureKit, userLayout)
	local left, right, top, bottom = 0, 1, 0, 1;

	local pieceMirrored = pieceLayout.mirrorLayout;
	if pieceMirrored == nil then
		pieceMirrored = userLayout and userLayout.mirrorLayout;
	end

	if pieceMirrored then
		if setupInfo.mirrorVertical then
			top, bottom = bottom, top;
		end

		if setupInfo.mirrorHorizontal then
			left, right = right, left;
		end
	end

	piece:ScaleTexCoord(left, right, top, bottom);
	if pieceLayout.color then
		piece:SetHorizTile(false)
		piece:SetVertTile(false)
	else
        local atlas = textureKit and pieceLayout.atlas:format(textureKit) or pieceLayout.atlas
        if AtlasUtil:AtlasExists(atlas) then
            local _, _, _, _, _, _, _, tileH, tileV = AtlasUtil:Unpack(atlas);
            piece:SetHorizTile(setupInfo.tileHorizontal and tileH);
            piece:SetVertTile(setupInfo.tileVertical and tileV);
        else
            piece:SetHorizTile(false);
            piece:SetVertTile(false);
        end
	end
end

local function SetupPieceVisuals(piece, setupInfo, pieceLayout, textureKit, userLayout, drawLayer)
	piece:SetBlendMode(pieceLayout.blendMode or userLayout.blendMode or "BLEND");

	if pieceLayout.width then
		piece:SetWidth(pieceLayout.width)
	end

	if pieceLayout.height then
		piece:SetHeight(pieceLayout.height)
	end

	if pieceLayout.color then
		piece:SetTexture(pieceLayout.color[1], pieceLayout.color[2], pieceLayout.color[3], pieceLayout.color[4] or 1)
	else
        if textureKit then
            local atlas = pieceLayout.atlas:format(textureKit)
            if AtlasUtil:AtlasExists(atlas) then
                piece:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
            end
		else
            if AtlasUtil:AtlasExists(pieceLayout.atlas) then
                piece:SetAtlas(pieceLayout.atlas, Const.TextureKit.UseAtlasSize)
            end
		end
	end

    SetupTextureCoordinates(piece, setupInfo, pieceLayout, textureKit, userLayout);
end

local function SetupCorner(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints();
	piece:SetPoint(pieceLayout.point or setupInfo.point, container, pieceLayout.relativePoint or setupInfo.point, pieceLayout.x, pieceLayout.y);
end

local function SetupEdge(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints();
	local userLayout = NineSliceUtil.GetLayout(container:GetAttribute("layoutType"));
	if userLayout and (userLayout.threeSliceVertical or userLayout.threeSliceHorizontal) then
		piece:SetPoint(setupInfo.point, container, setupInfo.point, pieceLayout.x, pieceLayout.y);
		piece:SetPoint(setupInfo.relativePoint, container, setupInfo.relativePoint, pieceLayout.x1, pieceLayout.y1);
	else
		piece:SetPoint(setupInfo.point, GetNineSlicePiece(container, setupInfo.relativePieces[1]), setupInfo.relativePoint, pieceLayout.x, pieceLayout.y);
		piece:SetPoint(setupInfo.relativePoint, GetNineSlicePiece(container, setupInfo.relativePieces[2]), setupInfo.point, pieceLayout.x1, pieceLayout.y1);
	end
end

local function SetupCenter(container, piece, setupInfo, pieceLayout)
	piece:ClearAllPoints();
	local userLayout = NineSliceUtil.GetLayout(container:GetAttribute("layoutType"));
	if userLayout and userLayout.threeSliceVertical then
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "TopEdge"), "BOTTOMLEFT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "BottomEdge"), "TOPRIGHT", pieceLayout.x1, pieceLayout.y1);
	elseif userLayout and userLayout.threeSliceHorizontal then
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "LeftEdge"), "TOPRIGHT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "RightEdge"), "BOTTOMLEFT", pieceLayout.x1, pieceLayout.y1);
	else
		piece:SetPoint("TOPLEFT", GetNineSlicePiece(container, "TopLeftCorner"), "BOTTOMRIGHT", pieceLayout.x, pieceLayout.y);
		piece:SetPoint("BOTTOMRIGHT", GetNineSlicePiece(container, "BottomRightCorner"), "TOPLEFT", pieceLayout.x1, pieceLayout.y1);
	end
end

-- Defines the order in which each piece should be set up, and how to do the setup.
--
-- Mirror types: As a texture memory and effort savings, many borders are assembled from a single topLeft corner, and top/left edges.
-- That's all that's required if everything is symmetrical (left edge is also superfluous, but allows for more detail variation)
-- The mirror flags specify which texture coords to flip relative to the piece that would use default texture coordinates: left = 0, top = 0, right = 1, bottom = 1
local nineSliceSetup =
{
	{ pieceName = "TopLeftCorner", point = "TOPLEFT", fn = SetupCorner, },
	{ pieceName = "TopRightCorner", point = "TOPRIGHT", mirrorHorizontal = true, fn = SetupCorner, },
	{ pieceName = "BottomLeftCorner", point = "BOTTOMLEFT", mirrorVertical = true, fn = SetupCorner, },
	{ pieceName = "BottomRightCorner", point = "BOTTOMRIGHT", mirrorHorizontal = true, mirrorVertical = true, fn = SetupCorner, },
	{ pieceName = "TopEdge", point = "TOPLEFT", relativePoint = "TOPRIGHT", relativePieces = { "TopLeftCorner", "TopRightCorner" }, fn = SetupEdge, tileHorizontal = true },
	{ pieceName = "BottomEdge", point = "BOTTOMLEFT", relativePoint = "BOTTOMRIGHT", relativePieces = { "BottomLeftCorner", "BottomRightCorner" }, mirrorVertical = true, tileHorizontal = true, fn = SetupEdge, },
	{ pieceName = "LeftEdge", point = "TOPLEFT", relativePoint = "BOTTOMLEFT", relativePieces = { "TopLeftCorner", "BottomLeftCorner" }, tileVertical = true, fn = SetupEdge, },
	{ pieceName = "RightEdge", point = "TOPRIGHT", relativePoint = "BOTTOMRIGHT", relativePieces = { "TopRightCorner", "BottomRightCorner" }, mirrorHorizontal = true, tileVertical = true, fn = SetupEdge, },
	{ pieceName = "Center", fn = SetupCenter, },
};

--------------------------------------------------
-- NINE SLICE UTILS
NineSliceUtil = {};

function NineSliceUtil.ApplyUniqueCornersLayout(self, textureKit)
	NineSliceUtil.ApplyLayout(self, NineSliceLayouts.UniqueCornersLayout, textureKit);
end

function NineSliceUtil.ApplyIdenticalCornersLayout(self, textureKit)
	NineSliceUtil.ApplyLayout(self, NineSliceLayouts.IdenticalCornersLayout, textureKit);
end

function NineSliceUtil.ApplyLayout(container, userLayout, textureKit, drawLayer)
	for pieceIndex, setup in ipairs(nineSliceSetup) do
		local pieceName = setup.pieceName;
		local pieceLayout = userLayout[pieceName];
		if pieceLayout then
			local piece, pieceAlreadyExisted = GetNineSlicePiece(container, pieceName);
			if not pieceAlreadyExisted then
				container[pieceName] = piece;
			end
			piece.ignoreInLayout = container.GetNineSliceIgnoreInLayout and container:GetNineSliceIgnoreInLayout() or true
			piece:SetDrawLayer(pieceLayout.layer or drawLayer or "BORDER");
			piece:SetBlendMode(pieceLayout.blendMode or "BLEND");

			-- Piece setup can change arbitrary properties, do it before changing the texture.
			setup.fn(container, piece, setup, pieceLayout);
			if userLayout.setupPieceVisualsFunction then
				userLayout.setupPieceVisualsFunction(container, piece, setup, pieceLayout, textureKit, userLayout, drawLayer);
			else
				SetupPieceVisuals(piece, setup, pieceLayout, textureKit, userLayout, drawLayer);
			end
		end
	end
end

function NineSliceUtil.DisableSharpening(container)
	for pieceIndex, setup in ipairs(nineSliceSetup) do
		local piece = GetNineSlicePiece(container, setup.pieceName);
		piece:SetTexelSnappingBias(0);
		piece:SetSnapToPixelGrid(false);
	end
end

function NineSliceUtil.ApplyLayoutByName(container, userLayoutName, textureKit)
	return NineSliceUtil.ApplyLayout(container, NineSliceUtil.GetLayout(userLayoutName), textureKit);
end

function NineSliceUtil.GetLayout(layoutName)
	return NineSliceLayouts[layoutName];
end

function NineSliceUtil.AddLayout(layoutName, layout)
	NineSliceLayouts[layoutName] = layout;
end

--------------------------------------------------
-- NINE SLICE PANEL MIXIN
 NineSlicePanelMixin = {};

function NineSlicePanelMixin:OnLoad()
	local parent = self:GetParent()
	if parent then
		if self:GetAttribute("useParentLevel") == true then
			self:SetFrameLevel(parent:GetFrameLevel())
		end

		parent:HookScript("OnLoad", function()
			self:LoadLayout()
		end)
	end
	self:LoadLayout()
end

function NineSlicePanelMixin:GetFrameLayoutType()
	return self:GetAttribute("layoutType") or self:GetParent() and self:GetParent():GetAttribute("layoutType")
end

function NineSlicePanelMixin:GetFrameDrawLayer()
	return self:GetAttribute("drawLayer") or self:GetParent() and self:GetParent():GetAttribute("drawLayer")
end

function NineSlicePanelMixin:GetFrameLayoutTextureKit()
	return self:GetAttribute("layoutTextureKit") or self:GetParent() and self:GetParent():GetAttribute("layoutTextureKit")
end

function NineSlicePanelMixin:LoadLayout()
	local layout = NineSliceUtil.GetLayout(self:GetFrameLayoutType());
	if layout then
		NineSliceUtil.ApplyLayout(self, layout, self:GetFrameLayoutTextureKit(), self:GetFrameDrawLayer());
	end
end

function NineSlicePanelMixin:SetLayout(layoutName)
	self:SetAttribute("layoutType", layoutName)
	self:LoadLayout()
end

function NineSlicePanelMixin:SetCenterColor(r, g, b, a)
	local center = self["Center"];
	if center then
		center:SetVertexColor(r, g, b, a or 1);
	end
end

function NineSlicePanelMixin:GetCenterColor()
	local center = self["Center"];
	if center then
		return center:GetVertexColor();
	end
end

function NineSlicePanelMixin:SetBorderColor(r, g, b, a)
	for _, section in ipairs(nineSliceSetup) do
		if section.pieceName ~= "Center" then
			local piece = self[section.pieceName];
			if piece then
				piece:SetVertexColor(r, g, b, a or 1);
			end
		end
	end
end

function NineSlicePanelMixin:GetBorderColor()
	-- return the vertex color of any valid piece
	for _, section in ipairs(nineSliceSetup) do
		if section.pieceName ~= "Center" then
			local piece = self[section.pieceName];
			if piece then
				return piece:GetVertexColor();
			end
		end
	end
end

function NineSlicePanelMixin:SetBorderBlendMode(blendMode)
	for _, section in ipairs(nineSliceSetup) do
		if section.pieceName ~= "Center" then
			local piece = self[section.pieceName];
			if piece then
				piece:SetBlendMode(blendMode);
			end
		end
	end
end

function NineSlicePanelMixin:HideNineSlicePiece(pieceName)
	local piece = self[pieceName];
	if piece then
		piece:Hide();
	end
end

function NineSlicePanelMixin:ShowNineSlicePiece(pieceName)
	local piece = self[pieceName];
	if piece then
		piece:Show();
	end
end

function NineSlicePanelMixin:SetNineSliceIgnoreInLayout(ignoreInLayout)
	self.nineSliceIgnoreInLayout = ignoreInLayout
	for _, section in ipairs(nineSliceSetup) do
		local piece = self[section.pieceName]
		if piece then
			piece.ignoreInLayout = ignoreInLayout
		end
	end
end 

function NineSlicePanelMixin:GetNineSliceIgnoreInLayout()
	return self.nineSliceIgnoreInLayout or self:GetAttribute("nineSliceIgnoreInLayout")
end
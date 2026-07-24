TextureUtil = {}

TextureUtil.MaskSize = {
	Large = 128,
	Small = 64,
}

TextureUtil.DefaultMask = "Small"

function SetClampedTextureRotation(texture, rotationDegrees)
	if (rotationDegrees ~= 0 and rotationDegrees ~= 90 and rotationDegrees ~= 180 and rotationDegrees ~= 270) then
		error("SetRotation: rotationDegrees must be 0, 90, 180, or 270");
		return;
	end

	if not (texture.rotationDegrees) then
		texture.origTexCoords = {texture:GetTexCoord()};
		texture.origWidth = texture:GetWidth();
		texture.origHeight = texture:GetHeight();
	end

	if (texture.rotationDegrees == rotationDegrees) then
		return;
	end

	texture.rotationDegrees = rotationDegrees;

	if (rotationDegrees == 0 or rotationDegrees == 180) then
		texture:SetWidth(texture.origWidth);
		texture:SetHeight(texture.origHeight);
	else
		texture:SetWidth(texture.origHeight);
		texture:SetHeight(texture.origWidth);
	end

	if (rotationDegrees == 0) then
		texture:SetTexCoord( texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[7], texture.origTexCoords[8] );
	elseif (rotationDegrees == 90) then
		texture:SetTexCoord( texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[5], texture.origTexCoords[6] );
	elseif (rotationDegrees == 180) then
		texture:SetTexCoord( texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[3], texture.origTexCoords[4],
											texture.origTexCoords[1], texture.origTexCoords[2] );
	elseif (rotationDegrees == 270) then
		texture:SetTexCoord( texture.origTexCoords[5], texture.origTexCoords[6],
											texture.origTexCoords[1], texture.origTexCoords[2],
											texture.origTexCoords[7], texture.origTexCoords[8],
											texture.origTexCoords[3], texture.origTexCoords[4] );
	end
end
TextureUtil.SetClampedTextureRotation = SetClampedTextureRotation

function ClearClampedTextureRotation(texture)
	if (texture.rotationDegrees) then
		SetClampedTextureRotation(texture, 0);
		texture.origTexCoords = nil;
		texture.origWidth = nil;
		texture.origHeight = nil;
	end
end
TextureUtil.ClearClampedTextureRotation = ClearClampedTextureRotation

function CreateSquareTextureMarkup(file, width, height, xOffset, yOffset) 
	if not height then height = width end
	return ("|T%s:%d:%d:%d:%d|t"):format(file, height, width, xOffset or 0, yOffset or 0)
end
TextureUtil.CreateSquareTextureMarkup = CreateSquareTextureMarkup

function CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom, xOffset, yOffset)
	return ("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
		  file
		, height
		, width
		, xOffset or 0
		, yOffset or 0
		, fileWidth
		, fileHeight
		, left * fileWidth
		, right * fileWidth
		, top * fileHeight
		, bottom * fileHeight
	);
end
TextureUtil.CreateTextureMarkup = CreateTextureMarkup

function CreateSimpleTextureMarkup(file, width, height, x, y)
	return ("|T%s:%d:%d:%d:%d|t"):format(file, height or width, width, x or 0, y or 0)
end
TextureUtil.CreateSimpleTextureMarkup = CreateSimpleTextureMarkup

function CreateAtlasMarkup(atlas, scale, xOffset, yOffset)
	local texture, width, height, left, right, top, bottom, tileH, tileV = AtlasUtil:Unpack(atlas)
	local fileWidth = width / (right - left)
	local fileHeight = height / (bottom - top)
	width = width * scale
	height = height * scale

	return ("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
	  texture
	, height
	, width
	, xOffset or 0
	, yOffset or 0
	, fileWidth
	, fileHeight
	, left * fileWidth
	, right * fileWidth
	, top * fileHeight
	, bottom * fileHeight
	);
end
TextureUtil.CreateAtlasMarkup = CreateAtlasMarkup

function CreateSizedAtlasMarkup(atlas, width, height, xOffset, yOffset)
	local texture, _, _, left, right, top, bottom, tileH, tileV = AtlasUtil:Unpack(atlas)
	local fileWidth = width / (right - left)
	local fileHeight = height / (bottom - top)

	return ("|T%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
			texture
	, height
	, width
	, xOffset or 0
	, yOffset or 0
	, fileWidth
	, fileHeight
	, left * fileWidth
	, right * fileWidth
	, top * fileHeight
	, bottom * fileHeight
	);
end
TextureUtil.CreateSizedAtlasMarkup = CreateSizedAtlasMarkup


function HideTextureOnElvUI(...)
	if IsAddOnLoaded("ElvUI") then
		for i = 1, select("#", ...) do
			local tex = select(i, ...)
			if not tex.elvui then
				tex.elvui = true
				tex:Hide()
				tex.SetShown = nop
				tex.Show = nop
				tex.SetTexture = nop
				tex.SetAtlas = nop
			end
		end
	end
end
TextureUtil.HideTextureOnElvUI = HideTextureOnElvUI

function TextureUtil.GetCoverTexCoords(width, height)
	local maxValue = math.max(width, height)

	local wDiff = maxValue - width
	local hDiff = maxValue - height


	local left = wDiff / maxValue
	left = left / 2
	local right = 1 - left

	local top = hDiff / maxValue
	top = top / 2
	local bottom = 1 - top
	return left, right, top, bottom
end

function TextureUtil.ZoomTexCoords(zoomPercent, left, right, top, bottom)
	local oneMinus = 1 - zoomPercent
	local newLeft = math.RemapToRange(zoomPercent, 0, 1, left, right)
	local newRight = math.RemapToRange(oneMinus, 0, 1, left, right)
	local newTop = math.RemapToRange(zoomPercent, 0, 1, top, bottom)
	local newBottom = math.RemapToRange(oneMinus, 0, 1, top, bottom)
	
	return newLeft, newRight, newTop, newBottom
end



function GetTexCoordsForRole(role)
	local textureHeight, textureWidth = 256, 256;
	local roleHeight, roleWidth = 67, 67;

	if ( role == "GUIDE" ) then
		return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "TANK" ) then
		return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "HEALER" ) then
		return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "DAMAGER" ) then
		return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	else
		return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	end
end

function GetTexCoordsForRoleSmallCircle(role)
	if ( role == "TANK" ) then
		return 0, 19/64, 22/64, 41/64;
	elseif ( role == "HEALER" ) then
		return 20/64, 39/64, 1/64, 20/64;
	elseif ( role == "DAMAGER" ) then
		return 20/64, 39/64, 22/64, 41/64;
	else
		return 20/64, 39/64, 22/64, 41/64;
	end
end

function GetBackgroundTexCoordsForRole(role)
	local textureHeight, textureWidth = 128, 256;
	local roleHeight, roleWidth = 75, 75;

	if ( role == "TANK" ) then
		return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "HEALER" ) then
		return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "DAMAGER" ) then
		return GetTexCoordsByGrid(3, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	else
		return GetTexCoordsByGrid(3, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	end
end

function TextureUtil.FitTextureToSize(width, height, imageWidth, imageHeight)
	local ratio = imageWidth / imageHeight
	local newWidth, newHeight = width, height
	if ratio > 1 then
		newHeight = width / ratio
	else
		newWidth = height * ratio
	end
	return newWidth, newHeight
end

function TextureUtil.FitTextureToWidth(width, imageWidth, imageHeight)
	local ratio = imageHeight/ imageWidth
	local newHeight = width / ratio
	return width, newHeight
end

function TextureUtil.FitTextureToHeight(height, imageWidth, imageHeight)
	local ratio = imageWidth / imageHeight
	local newWidth = height * ratio
	return newWidth, height
end

--"{T:file:width:height:fileWidth:fileHeight:left:right:top:bottom}"
--"{T:file:756:267:1024:512:135:891:122:389}"
function TextureUtil.ResolveCustomTextureTag(tag)
	local file, width, height, fileWidth, fileHeight, left, right, top, bottom = tag:match("{T:([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*):?([^:]*)}")
	if not file then
		return TextureUtil.ResolveCustomAtlasTag(tag)
	end
	
	width = tonumber(width)
	height = tonumber(height)
	fileWidth = tonumber(fileWidth)
	fileHeight = tonumber(fileHeight)
	left = tonumber(left) or 0
	right = tonumber(right) or 1
	top = tonumber(top) or 0
	bottom = tonumber(bottom) or 1

	if fileWidth and fileHeight then
		if left > 1 then
			left = left / fileWidth
		end

		if right > 1 then
			right = right / fileWidth
		end

		if top > 1 then
			top = top / fileHeight
		end

		if bottom > 1 then
			bottom = bottom / fileHeight
		end
	end
	
	return file, width, height, left, right, top, bottom
end

function TextureUtil.ResolveCustomAtlasTag(tag)
	local atlas, width, height = tag:match("{A:([^:]*):?([^:]*):?([^:]*):?}")
	if not atlas then
		return tag
	end

	if AtlasUtil:AtlasExists(atlas) then
		local texture, atlasWidth, atlasHeight, left, right, top, bottom, tileH, tileV = AtlasUtil:Unpack(atlas)
		return texture, width or atlasWidth, height or atlasHeight, left, right, top, bottom
	end

	return tag
end
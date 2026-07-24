local pow, floor, pi, sqrt, tinsert, ipairs, max, cos, sin = math.pow, math.floor, math.pi, sqrt, tinsert, ipairs, max, math.cos, math.sin

DrawUtil = {}

-- texture			- Texture
-- canvasFrame      - Canvas Frame (for anchoring)
-- startPoint       - Vector2D Start Coordinate
-- endPoint  		- Vector2D End Coordinate
-- lineWidth        - Width of line
-- relPoint			- Relative point on canvas to interpret coords (Default BOTTOMLEFT)
local function DrawLine(texture, canvasFrame, startPoint, endPoint, lineWidth, lineFactor, relPoint)
	if (not relPoint) then relPoint = "BOTTOMLEFT" end
	lineFactor = lineFactor * .5

	-- Determine dimensions and center point of line
	local dx, dy = endPoint.x - startPoint.x, endPoint.y - startPoint.y
	local cx, cy = (startPoint.x + endPoint.x) / 2, (startPoint.y + endPoint.y) / 2

	-- Normalize direction if necessary
	if (dx < 0) then
		dx, dy = -dx, -dy
	end

	-- Calculate actual length of line
	local lineLength = sqrt((dx * dx) + (dy * dy))

	-- Quick escape if it'sin zero length
	if (lineLength == 0) then
		texture:SetTexCoord(0, 0, 0, 0, 0, 0, 0, 0)
		texture:SetPoint("BOTTOMLEFT", canvasFrame, relPoint, cx, cy)
		texture:SetPoint("TOPRIGHT", canvasFrame, relPoint, cx, cy)
		return false
	end

	-- Sin and Cosine of rotation, and combination (for later)
	local sin, cos = -dy / lineLength, dx / lineLength
	local sinCos = sin * cos

	-- Calculate bounding box size and texture coordinates
	local boundingWidth, boundingHeight, bottomLeftX, bottomLeftY, topLeftX, topLeftY, topRightX, topRightY, bottomRightX, bottomRightY
	if (dy >= 0) then
		boundingWidth = ((lineLength * cos) - (lineWidth * sin)) * lineFactor
		boundingHeight = ((lineWidth * cos) - (lineLength * sin)) * lineFactor

		bottomLeftX = (lineWidth / lineLength) * sinCos
		bottomLeftY = sin * sin
		bottomRightY = (lineLength / lineWidth) * sinCos
		bottomRightX = 1 - bottomLeftY

		topLeftX = bottomLeftY
		topLeftY = 1 - bottomRightY
		topRightX = 1 - bottomLeftX
		topRightY = bottomRightX
	else
		boundingWidth = ((lineLength * cos) + (lineWidth * sin)) * lineFactor
		boundingHeight = ((lineWidth * cos) + (lineLength * sin)) * lineFactor

		bottomLeftX = sin * sin
		bottomLeftY = -(lineLength / lineWidth) * sinCos
		bottomRightX = 1 + (lineWidth / lineLength) * sinCos
		bottomRightY = bottomLeftX

		topLeftX = 1 - bottomRightX
		topLeftY = 1 - bottomLeftX
		topRightY = 1 - bottomLeftY
		topRightX = topLeftY
	end
	
	topLeftY = topLeftY - 0.02
	topRightY = topRightY - 0.02
	bottomLeftY = bottomLeftY + 0.02
	bottomRightY = bottomRightY + 0.02

	topLeftX = topLeftX + 0.02
	topRightX = topRightX - 0.02
	bottomLeftX = bottomLeftX + 0.02
	bottomRightX = bottomRightX - 0.02

	-- Set texture coordinates and anchors
	texture:ClearAllPoints()
	texture:SetTexCoord(topLeftX, topLeftY, bottomLeftX, bottomLeftY, topRightX, topRightY, bottomRightX, bottomRightY)
	texture:SetPoint("BOTTOMLEFT", canvasFrame, relPoint, cx - boundingWidth, cy - boundingHeight)
	texture:SetPoint("TOPRIGHT", canvasFrame, relPoint, cx + boundingWidth, cy + boundingHeight)

	return true
end

local function ReleaseTexture(pool, texture)
	if texture.startCap then
		DrawUtil.EraseCircle(texture.startCap)
		DrawUtil.EraseCircle(texture.endCap)
		texture.endCap = nil
		texture.startCap = nil
	end

	texture:SetParent(pool.parent)
	texture:ClearAllPoints()
	texture:Hide()
end

function DrawUtil.GetLineTexture(name, parent, layer)
	if not DrawUtil.linePool then
		DrawUtil.linePool = CreateTexturePool(UIParent or GlueParent, nil, nil, ReleaseTexture)
	end

	if parent then
		local tex = parent:CreateTexture(name, layer)
		Mixin(tex, LineMixin)
		return tex
	end

	local tex = DrawUtil.linePool:Acquire()
	if not tex.Draw then
		Mixin(tex, LineMixin)
	end

	return tex
end

function DrawUtil.EraseLine(tex)
	DrawUtil.linePool:Release(tex) -- we want to error if this pool hasn't been made yet.
end

function DrawUtil.GetCircleTexture()
	if not DrawUtil.circlePool then
		DrawUtil.circlePool = CreateTexturePool(UIParent or GlueParent, nil, nil, ReleaseTexture)
	end

	local tex = DrawUtil.circlePool:Acquire()
	if not tex.Draw then
		Mixin(tex, CircleMixin)
	end

	return tex
end

function DrawUtil.EraseCircle(tex)
	DrawUtil.circlePool:Release(tex) -- we want to error if this pool hasn't been made yet.
end

function DrawUtil.CreateLine(parent, name, layer)
	local line = DrawUtil.GetLineTexture(name, parent, layer)
	line:SetTexture("Interface\\Common\\White256x256")
	line:SetBlendMode("ALPHAKEY")

	line.SetColorTexture = line.SetVertexColor
	line.SetTexture = function(self, texture, ...)
		if type(texture) == "number" then
			self:SetVertexColor(texture, ...)
		end
	end
	return line
end


function DrawUtil.DrawLine(startPoint, endPoint, thickness, color, layer, lineFactor, canvas, relPoint)
	local line = DrawUtil.GetLineTexture()

	--!! This file MUST be a .tga for transparency! .blp textures that exceed their uv coordinates will be black !!--
	line:SetTexture("Interface\\Common\\White256x256")
	line:SetParent(canvas)
	line:SetDrawLayer(layer or "OVERLAY")
	line:SetBlendMode("ALPHAKEY")
	line:SetStartPoint(startPoint)
	line:SetEndPoint(endPoint)
	line:SetThickness(thickness)
	line:SetLineFactor(lineFactor or 1)
	line:SetRelativePoint(relPoint or "BOTTOMLEFT")
	if color then
		line:SetVertexColor(color:GetRGBA())
	else
		line:SetVertexColor(1, 1, 1, 1)
	end

	if not line:Draw() then
		DrawUtil.EraseLine(line)
		return
	end

	line.startCap = DrawUtil.DrawCircle(startPoint, thickness, color, layer, canvas, relPoint)
	line.endCap = DrawUtil.DrawCircle(endPoint, thickness, color, layer, canvas, relPoint)

	line:Show()

	return line
end

function DrawUtil.DrawCircle(point, size, color, layer, canvas, relPoint)
	local circle = self:GetCircleTexture()

	--!! This file MUST be a .tga for transparency! .blp textures that exceed their uv coordinates will be black !!--
	circle:SetTexture("Interface\\Common\\White256x256Circle")
	circle:SetParent(canvas)
	circle:SetDrawLayer(layer or "OVERLAY")
	circle:SetBlendMode("ALPHAKEY")
	circle:SetOrigin(point)
	circle:SetRelativePoint(relPoint or "BOTTOMLEFT")
	circle:SetSize(size, size)
	if color then
		circle:SetVertexColor(color:GetRGBA())
	else
		circle:SetVertexColor(1, 1, 1, 1)
	end

	circle:Draw()
	circle:Show()

	return circle
end

-- return if point a is left of b
local function isLeft(a, b)
	if a.x < b.x then return true end
	if a.x >= b.x then return false end
end

-- return if point c is left of line (a,b)
local function isLeftOfLine(a, b, c)
	local u1 = b.x - a.x
	local v1 = b.y - a.y
	local u2 = c.x - a.x
	local v2 = c.y - a.y
	return u1 * v2 - v1 * u2 < 0
end

local function makeHull(vertices)
	local left = 1
	for i = 2, #vertices do
		if isLeft(vertices[i], vertices[left]) then left = i end
	end

	local hull = {}
	local final = 1
	local tries = 0
	repeat
		table.insert(hull, left)
		final = 1
		for j = 2, #vertices do
			if left == final or isLeftOfLine(vertices[left], vertices[final], vertices[j]) then final = j end
		end
		left = final
		tries = tries + 1
	until final == hull[1] or tries > 100 --deadlocked here otherwise?!?

	local hullVertices = {}
	for _, index in ipairs(hull) do
		table.insert(hullVertices, vertices[index])
	end
	return hullVertices
end

local function smoothHull(hull, iterations, radius)
	local vertices = {}
	local r = radius * 10

	for i, vertex in ipairs(hull) do
		local x = vertex.x
		local y = vertex.y
		local numPoints = max(1, floor(iterations * radius))

		for j = 1, numPoints do
			local cx = x + r * cos(2 * pi / numPoints * j)
			local cy = y + r * sin(2 * pi / numPoints * j)
			tinsert(vertices, Vector2D(cx, cy))
		end
	end
	
	return vertices
end

function DrawUtil.DrawConvexHull(vertices, smoothRadius, thickness, color, layer, lineFactor, canvas, relPoint)
	assert(#vertices > 1, "DrawUtil:DrawConvexHull: Tried to draw a Convex Hull with less than 2 vertices")
	-- organize vertices
	local hull = makeHull(vertices)
	vertices = smoothHull(hull, 16, smoothRadius)
	hull = makeHull(vertices)

	local lines = {}
	for i, vertex in ipairs(hull) do
		local endVertex = hull[i + 1] or hull[1]
		local line = DrawUtil.DrawLine(vertex, endVertex, thickness, color, layer, lineFactor, canvas, relPoint)
		if line then
			tinsert(lines, line)
		end
	end

	if #lines > 0 then
		return lines
	end
end

function DrawUtil.DrawPolyHull(vertices, smoothRadius, thickness, color, layer, lineFactor, canvas, relPoint)
	vertices = smoothHull(vertices, 16, smoothRadius)
	
	local lines = {}
	for i, vertex in ipairs(vertices) do
		local endVertex = vertices[i + 1] or vertices[1]
		local line = DrawUtil.DrawLine(vertex, endVertex, thickness, color, layer, lineFactor, canvas, relPoint)
		if line then
			tinsert(lines, line)
		end
	end

	if #lines > 0 then
		return lines
	end
end

function DrawUtil.EraseHull(lines)
	for _, line in ipairs(lines) do
		DrawUtil.EraseLine(line)
	end
	
	wipe(lines)
end

--
-- Texture Mixin to function like a line from retail
--
LineMixin = {}

function LineMixin:SetStartPoint(vector)
	self.startPoint = vector
end

function LineMixin:SetEndPoint(vector)
	self.endPoint = vector
end

function LineMixin:SetThickness(thickness)
	self.thickness = thickness
end

function LineMixin:SetLineFactor(lineFactor)
	self.lineFactor = lineFactor
end

function LineMixin:SetRelativePoint(relPoint)
	self.relPoint = relPoint
end

function LineMixin:Draw()
	local parent = self:GetParent()
	self:ClearAllPoints()

	if self.startCap then
		self.startCap:Draw()
		self.endCap:Draw()
	end

	return DrawLine(self, parent, self.startPoint, self.endPoint, self.thickness or 32,
	                self.lineFactor or 1, self.relPoint)
end

--
-- Texture mixin to function like a LineMixin but for circles
--
CircleMixin = {}

function CircleMixin:SetOrigin(vector)
	self.origin = vector
end

function CircleMixin:SetRelativePoint(relPoint)
	self.relPoint = relPoint
end

function CircleMixin:Draw()
	self:ClearAndSetPoint("CENTER", self:GetParent(), self.relPoint or "BOTTOMLEFT", self.origin.x, self.origin.y)
end

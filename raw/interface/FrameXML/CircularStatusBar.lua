CircularStatusBarMixin = {}

function CircularStatusBarMixin:OnLoad()
    self.Wedge = self.ScrollFrame.Child:CreateTexture(nil, "ARTWORK")
    self.Wedge:SetPoint("BOTTOMRIGHT", self, "CENTER", 0, 0)
    self.ScrollFrame.Child:SetSize(self.ScrollFrame:GetSize())
	self.Textures = { self.TR, self.BR, self.BL, self.TL }
end

function CircularStatusBarMixin:SetTexture(texture)
	for _, tex in ipairs(self.Textures) do
        tex:SetTexture(texture)
    end

    self.Wedge:SetTexture(texture)
end

function CircularStatusBarMixin:SetDrawLayer(layer)
	for _, tex in ipairs(self.Textures) do
        tex:SetDrawLayer(layer)
    end

    self.Wedge:SetDrawLayer(layer)
end

function CircularStatusBarMixin:SetDesaturated(desaturate)
	for _, tex in ipairs(self.Textures) do
        tex:SetDesaturated(desaturate)
    end

    self.Wedge:SetDesaturated(desaturate)
end

function CircularStatusBarMixin:SetBlendMode(blendMode)
	for _, tex in ipairs(self.Textures) do
        tex:SetBlendMode(blendMode)
    end

    self.Wedge:SetBlendMode(blendMode)
end

function CircularStatusBarMixin:Show()
	for _, tex in ipairs(self.Textures) do
        tex:Show()
    end

    self.Wedge:Show()
end

function CircularStatusBarMixin:Hide()
	for _, tex in ipairs(self.Textures) do
        tex:Hide()
    end

    self.Wedge:Hide()
end

function CircularStatusBarMixin:SetShown(shown)
	for _, tex in ipairs(self.Textures) do
        tex:SetShown(shown)
    end

	self.Wedge:SetShown(shown)
end

local scaleWedge =  0.99703012303776
function CircularStatusBarMixin:UpdateWedgeSize()
    self.Wedge:SetWidth(self:GetWidth() * scaleWedge)
    self.Wedge:SetHeight(self:GetHeight() * scaleWedge)
end

function CircularStatusBarMixin:SetBackgroundOffset(region, offset)
	self.offset = offset
	self.Textures[1]:SetPoint("TOPRIGHT", region, offset, offset)
	self.Textures[2]:SetPoint("BOTTOMRIGHT", region, offset, -offset)
	self.Textures[3]:SetPoint("BOTTOMLEFT", region, -offset, -offset)
	self.Textures[4]:SetPoint("TOPLEFT", region, -offset, offset)
end

local function betweenAngles(low, high, needle1, needle2)
	if (low <= needle1 and needle1 <= high and low <= needle2 and needle2 <= high) then return true end

	needle1 = needle1 + 360
	needle2 = needle2 + 360

	if (low <= needle1 and needle1 <= high and low <= needle2 and needle2 <= high) then return true end

	return false
end

local function Transform(tx, x, y, angle) -- Translates texture to x, y and rotates around its center
    local c, s = cos(angle), sin(angle)

    local ULx, ULy = 0.5 + (x - 0.5) * c - (y - 0.5) * s, (0.5 + (y - 0.5) * c + (x - 0.5) * s)
    local LLx, LLy = 0.5 + (x - 0.5) * c - (y + 0.5) * s, (0.5 + (y + 0.5) * c + (x - 0.5) * s)
    local URx, URy = 0.5 + (x + 0.5) * c - (y - 0.5) * s, (0.5 + (y - 0.5) * c + (x + 0.5) * s)
    local LRx, LRy = 0.5 + (x + 0.5) * c - (y + 0.5) * s, (0.5 + (y + 0.5) * c + (x + 0.5) * s)
    tx:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
  end

local function animRotate(texture, degrees, anchor)
    if (not anchor) then
        anchor = "CENTER"
    end

    texture.degrees = degrees

    -- Something to rotate
    -- Create AnimationGroup and rotation animation
    if (not texture.animationGroup) then
        texture.animationGroup = texture:CreateAnimationGroup()
        texture.animationGroup:SetLooping("REPEAT")
    else
        texture.animationGroup:Stop()
    end

    texture.animationGroup.rotate = texture.animationGroup.rotate or texture.animationGroup:CreateAnimation("rotation")

    local rotate = texture.animationGroup.rotate
    rotate:SetOrigin(anchor, 0, 0)
    rotate:SetDegrees(degrees)
    rotate:SetDuration( 0 )
    rotate:SetEndDelay(15) -- 2147483647
    Transform(texture, -0.5, -0.5, -degrees)
    texture.animationGroup:Play()
  end

function CircularStatusBarMixin:SetProgress(startAngle, endAngle, progress, clockwise)
	local pAngle = (endAngle - startAngle) * progress + startAngle

	-- Show/hide necessary textures if we need to
	for i = 1, 4 do
		local quadrantAngle1
		local quadrantAngle2

		if (clockwise) then
			quadrantAngle2 = i * 90
			quadrantAngle1 = quadrantAngle2 - 90
		else
			quadrantAngle2 = (5 - i) * 90
			quadrantAngle1 = quadrantAngle2 - 90
		end

		if clockwise then
			if betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2) then
				self.Textures[i]:Show()
			else
				self.Textures[i]:Hide()
			end
		else
			if betweenAngles(startAngle, pAngle, quadrantAngle1, quadrantAngle2) then
				self.Textures[i]:Show()
			else
				self.Textures[i]:Hide()
			end
		end
	end

	-- Move scrollframe/wedge to the proper quadrant
	local quadrant = floor(pAngle % 360 / 90) + 1

	if (not clockwise) then
        quadrant = 5 - quadrant
    end

	local degree = pAngle
	if not clockwise then
        degree = -degree + 90
    end

    self.ScrollFrame:Hide()
    self.ScrollFrame:SetAllPoints(self.Textures[quadrant])
    self.ScrollFrame:Show()

    animRotate(self.Wedge, -degree, "BOTTOMRIGHT")
end

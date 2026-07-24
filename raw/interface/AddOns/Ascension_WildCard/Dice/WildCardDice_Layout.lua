-------------------------------------------------------------------------------
--                        Wildcard Dice Layout Engine                        --
-------------------------------------------------------------------------------
WildCardDiceLayout = {}

local BASE_WIDTH, BASE_HEIGHT = 128, 128
local Y_OFFSET_DEFAULT = -96

function WildCardDiceLayout:Initialize(diceFrame)
	self.frame = diceFrame
end

function WildCardDiceLayout:Reset()
	self.frame:ClearAllPoints()
	self.frame:SetHeight(BASE_HEIGHT)
	
	local parent = self.frame:GetParent() or UIParent
	self.frame:SetPoint("TOP", parent, "TOP", 0, Y_OFFSET_DEFAULT)
end

function WildCardDiceLayout:Expand()
	if self.frame:GetHeight() > BASE_HEIGHT then
		-- Already expanded, return early to prevent compounding offsets
		return
	end

	local numPoints = self.frame:GetNumPoints()
	if numPoints == 0 then
		self:Reset()
	end

	-- Retrieve exact 5-tuple layout parameters from WoW client API
	local point, relativeTo, relativePoint, xOfs, yOfs = self.frame:GetPoint(1)
	
	-- Fallback values if anchor was detached
	point = point or "TOP"
	relativeTo = relativeTo or self.frame:GetParent() or UIParent
	relativePoint = relativePoint or "TOP"
	xOfs = xOfs or 0
	yOfs = yOfs or Y_OFFSET_DEFAULT

	self.frame:ClearAllPoints()
	self.frame:SetHeight(BASE_HEIGHT + 128)
	self.frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + 64)
end

function WildCardDiceLayout:SetRapidRolling(parent)
	self.frame:ClearAllPoints()
	self.frame:SetParent(parent)
	self.frame:SetHeight(BASE_HEIGHT)
	self.frame:SetPoint("TOP", parent, "TOP", 0, Y_OFFSET_DEFAULT)
end

function WildCardDiceLayout:SetNotRapidRolling()
	self.frame:ClearAllPoints()
	self.frame:SetParent(UIParent)
	self.frame:SetHeight(BASE_HEIGHT)
	self.frame:SetPoint("TOP", UIParent, "TOP", 0, Y_OFFSET_DEFAULT)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
end

CompactRaidGroupMixin = {}

local MEMBERS_PER_RAID_GROUP = MEMBERS_PER_RAID_GROUP
local CreateFrame = CreateFrame
local GroupUtil_IsInRaid = GroupUtil.IsInRaid
local GetNumRaidMembers = GetNumRaidMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetCursorPosition = GetCursorPosition

function CompactRaidGroupMixin:OnLoad()
	self.title:Disable()
	
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self.applyFunc = self.ApplyFunctionToAllFrames
end

function CompactRaidGroupMixin:OnEvent(event, ...)
	self:UpdateUnits()
end

function CompactRaidGroupMixin:ApplyFunctionToAllFrames(updateSpecifier, func, ...)
	if updateSpecifier == "normal" or updateSpecifier == "all" then
		local name = self:GetName()
		for i=1, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[name.."Member"..i]
			func(unitFrame, ...)
		end
	elseif updateSpecifier == "group" then
		func(self, ...)
	end
end

function CompactRaidGroup_GenerateForGroup(groupIndex)
	local didCreate = false
	local frame = _G["CompactRaidGroup"..groupIndex]
	if (  not frame ) then
		frame = CreateFrame("Frame", "CompactRaidGroup"..groupIndex, UIParent, "CompactRaidGroupTemplate")
		frame:InitializeForGroup(groupIndex)
		frame:UpdateBorder()
		didCreate = true
	end
	return frame, didCreate
end

function CompactRaidGroupMixin:InitializeForGroup(groupIndex)
	self:SetID(groupIndex)
	local name = self:GetName()
	for i=1, MEMBERS_PER_RAID_GROUP do
		local unitFrame = _G[name.."Member"..i]
		unitFrame:SetUpFrame(DefaultCompactUnitFrameSetup)
		unitFrame:SetUpdateAllEvent("RAID_ROSTER_UPDATE")
	end
	self:UpdateUnits()
	self.title:SetFormattedText(GROUP_NUMBER, groupIndex)
end

function CompactRaidGroupMixin:UpdateUnits()
	local name = self:GetName()
	local groupIndex = self:GetID()
	local frameIndex = 1

	if GroupUtil_IsInRaid() then
		local unitFrame, subgroup, _
		for i=1, GetNumRaidMembers() do
			_, _, subgroup = GetRaidRosterInfo(i)
			if subgroup == groupIndex and frameIndex <= MEMBERS_PER_RAID_GROUP then
				unitFrame = _G[name.."Member"..frameIndex]
				unitFrame:SetUnit("raid"..i)
				frameIndex = frameIndex + 1
			end
		end
		
		for i=frameIndex, MEMBERS_PER_RAID_GROUP do
			unitFrame = _G[name.."Member"..i]
			unitFrame:SetUnit(nil)
		end
	end
end

function CompactRaidGroupMixin:UpdateLayout()
	local name = self:GetName()
	local totalHeight = self.title:GetHeight()
	local totalWidth = 0
	if CUF_HORIZONTAL_GROUPS then
		self.title:ClearAllPoints()
		self.title:SetPoint("TOPLEFT")
		
		local frame1 = _G[name.."Member1"]
		frame1:ClearAllPoints()
		frame1:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -self.title:GetHeight())
		
		for i=2, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[name.."Member"..i]
			unitFrame:ClearAllPoints()
			unitFrame:SetPoint("LEFT", _G[name.."Member"..(i-1)], "RIGHT", 0, 0)
		end
		totalHeight = totalHeight + _G[name.."Member1"]:GetHeight()
		totalWidth = totalWidth + _G[name.."Member1"]:GetWidth() * MEMBERS_PER_RAID_GROUP
	else
		self.title:ClearAllPoints()
		self.title:SetPoint("TOP")
		
		local frame1 = _G[name.."Member1"]
		frame1:ClearAllPoints()
		frame1:SetPoint("TOP", self, "TOP", 0, -self.title:GetHeight())
		
		for i=2, MEMBERS_PER_RAID_GROUP do
			local unitFrame = _G[name.."Member"..i]
			unitFrame:ClearAllPoints()
			unitFrame:SetPoint("TOP", _G[name.."Member"..(i-1)], "BOTTOM", 0, 0)
		end
		totalHeight = totalHeight + _G[name.."Member1"]:GetHeight() * MEMBERS_PER_RAID_GROUP
		totalWidth = totalWidth + _G[name.."Member1"]:GetWidth()
	end
	
	if self.borderFrame:IsShown() then
		totalWidth = totalWidth + 12
		totalHeight = totalHeight + 4
	end

	self:SetSize(totalWidth, totalHeight)
end

function CompactRaidGroupMixin:UpdateBorder()	
	if CUF_SHOW_BORDER then
		self.borderFrame:Show()
	else
		self.borderFrame:Hide()
	end
	self:UpdateLayout()
end

function CompactRaidGroupMixin:StartMoving()
	--Move the frame right onto the cursor.
	local cursorX, cursorY = GetCursorPosition()
	self:ClearAllPoints()
	self:SetPoint("TOP", UIParent, "BOTTOMLEFT", cursorX / UIParent:GetScale(), cursorY / UIParent:GetScale() + 10)

	self:StartMoving()
	MOVING_COMPACT_RAID_FRAME = self
end

function CompactRaidGroupMixin:StopMoving()
	self:StopMovingOrSizing()
	if MOVING_COMPACT_RAID_FRAME == self then
		MOVING_COMPACT_RAID_FRAME = nil
	end
end
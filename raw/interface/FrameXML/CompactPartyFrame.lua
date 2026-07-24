CompactPartyMixin = CreateFromMixins(CompactRaidGroupMixin)

function CompactPartyMixin:OnLoad()
	CompactRaidGroupMixin.OnLoad(self)
	self:UnregisterEvent("RAID_ROSTER_UPDATE")
	local name = self:GetName()
	local unitFrame = _G[name.."Member1"]
	unitFrame:SetUnit("player")
	unitFrame:SetUpFrame(DefaultCompactUnitFrameSetup)
	unitFrame:SetUpdateAllEvent("PARTY_MEMBERS_CHANGED")
	
	for i=2, MEMBERS_PER_RAID_GROUP do
		unitFrame = _G[name.."Member"..i]
		unitFrame:SetUnit("party"..(i-1))
		unitFrame:SetUpFrame(DefaultCompactUnitFrameSetup)
		unitFrame:SetUpdateAllEvent("PARTY_MEMBERS_CHANGED")
	end
	
	self.title:SetText(PARTY)
	self.title:Disable()
end

function CompactPartyFrame_Generate()
	local frame = CompactPartyFrame
	local didCreate = false
	if not frame then
		frame = CreateFrame("Frame", "CompactPartyFrame", UIParent, "CompactPartyFrameTemplate")
		frame:UpdateBorder(frame)
		didCreate = true
	end
	return frame, didCreate
end

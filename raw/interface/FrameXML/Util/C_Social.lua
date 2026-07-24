C_Social = {}

C_Hook:Register(C_Social, "FRIEND_METADATA_CHANGED")

function C_Social:FRIEND_METADATA_CHANGED()
	if FriendsFrame:IsShown() then
		FriendsList_Update()
	end
end

function C_Social:SetFriendAddedAs(name, addedAs)
	assert(type(addedAs) == "string")
	local id = tonumber(name)
	if id then
		name = GetFriendInfo(id)
	end
	
	if not name then return end
	
	dprint("Added Metadata for: ", name, "\"" .. name .. "\"")
	SetFriendsMetadata(name, name)
end

function C_Social:GetFriendAddedAs(name)
	local id = tonumber(name)
	if id then
		name = GetFriendInfo(id)
	end

	if not name then return end

	local addedAs = GetFriendsMetadata(name)
	if addedAs == name then return end
	return addedAs
end 
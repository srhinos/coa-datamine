C_NoviceNetwork = {}

function C_NoviceNetwork:IsNewcomer()
	if self.isNewcomer ~= nil then
		return self.isNewcomer
	end

	if HasJsonCacheData("MISC_PLAYER_DATA_PAYLOAD", 0) then
		local json = GetJsonCacheData("MISC_PLAYER_DATA_PAYLOAD", 0)
		if json then
			local jsonObject = C_Serialize:FromJSON(json)
			if jsonObject then
				self.isNewcomer = jsonObject.IsNewcomer
			end
		end
	end

	return self.isNewcomer
end
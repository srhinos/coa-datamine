--
-- Cache Query functions
--
C_Cache = {
	Queried = {},
	LastStatQuery = 0,
}

local listener = CreateFrame("Frame")

for _, v in pairs(Enum.CacheQueryGroup) do
	C_Cache.Queried[v] = {}
end

function C_Cache:QueryStat(group, bypassCooldown)
	if not group then return end

	if not issecure() then
		bypassCooldown = false
	end

	if not bypassCooldown and time() - self.LastStatQuery < 2 then return end
	self.LastStatQuery = time()

	RequestStatisticQuery(group)
end

function C_Cache:QueryAllStats(bypassCooldown)
	if not issecure() then
		bypassCooldown = false
	end

	if not bypassCooldown and time() - self.LastStatQuery < 2 then return end
	self.LastStatQuery = time()

	local group = Enum.StatQueryGroup.MeleeHit + Enum.StatQueryGroup.RangedHit + Enum.StatQueryGroup.SpellHit + Enum.StatQueryGroup.Expertise + Enum.StatQueryGroup.OffHandHit
	RequestStatisticQuery(group)
end

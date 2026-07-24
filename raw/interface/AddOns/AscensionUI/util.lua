local Addon = select(2, ...)
-------------------------------------------------------------------------------
--                                  Useful Globals                           --
-------------------------------------------------------------------------------
-- Consider moving these to FrameXML so they're loaded first and accessible in FrameXML files
local cacheLoaderTooltip = CreateFrame("GameTooltip", "CacheLoaderTooltip", UIParent, "GameTooltipTemplate")

function TryCacheItem(itemID)
	if not itemID then return end
	cacheLoaderTooltip:SetOwner(WorldFrame, "ACHOR_NONE")
	cacheLoaderTooltip:SetHyperlink("item:" .. itemID .. ":0:0:0:0:0:0:0")
	cacheLoaderTooltip:Hide()
end
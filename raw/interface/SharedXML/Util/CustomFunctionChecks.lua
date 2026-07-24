--
-- This script is used to prevent situations where an unshipped dll causes mass lua errors.
-- Mostly will only happen on dev servers.
--
if not GetInboxInvoiceQuantity then
    function GetInboxInvoiceQuantity(index)
        return 1
    end
end

--
-- DO NOT REMOVE
-- GlueXML needs this since they aren't reliable immediately after login
--
if not ClearJsonCache then
    function ClearJsonCache(category)
    end
end

if not GetJsonCacheData then
    function GetJsonCacheData(category, index)
    end
end

if not HasJsonCacheData then
    function HasJsonCacheData(category, index)
        return false
    end
end

if not C_RealmSelect then
    C_RealmSelect = {}
    local RealmInfo = {
        ["Thunderbluff - QA Development"] = { 0, 0, "Default", true, 3, 2, 0 },
        ["Fizzcrank - Hot Development"] = { 0, 0, "Default", true, 3, 9, 0 },
        ["Proudmoore - Development"] = { 0, 0, "Default", true, 3, 4, 0 },
        ["Uther - Development"] = { 0, 0, "Malganis", true, 3, 7, 0 },
        ["Archimonde - League 4"] = { 0, 0, "Archimonde", true, 1, 1, 93212 },
        ["Twisting Nether - Dev QA"] = { 0, 0, "Default", true, 3, 10, 0 },
        ["Freepick - Live QA"] = { 1, 0, "Area52", true, 3, 5, 0 },
        ["Daggerspine - PTR"] = { 1, 0, "Daggerspine", true, 2, 3, 13977865 },
        ["Area 52 - Free-Pick"] = { 1, 0, "Area52", true, 1, 3, 13977862 },
        ["Grizzly Hills - Wotlk Alpha"] = { 2, 0, "GrizzlyHills", true, 2, 1, 13977863 },
        ["Wildhammer - Season Live QA"] = { 0, 0, "Alar", true, 3, 8, 0 },
        ["Rexxar - CoA Alpha - Development"] = { 0, 11, "Rexxar", true, 2, 2, 13977864 },
        ["Thrall - Season 8"] = { 0, 4, "Thrall2", true, 1, 2, 13977866 },
        ["Akama - Deleaker Development"] = { 0, 0, "Default", true, 3, 11, 0 },
        ["Character Archive"] = { 0, 0, "Default", true, 3, 12, 0 },
        ["Moroes - Local Development"] = { 0, 0, "Default", true, 3, 1, 0 },
        ["WCR - QA"] = { 0, 0, "Malganis", true, 3, 1, 0 },
    }
    function C_RealmSelect.GetRealmInfo(realmName)
        if realmName == "League" then
            realmName = "Thrall - Season 8"
        end

        if RealmInfo[realmName] then
            return realmName, unpack(RealmInfo[realmName])
        end

        for name, info in pairs(RealmInfo) do
            if info[3] == realmName then
                return name, unpack(info)
            end
        end
    end
end 
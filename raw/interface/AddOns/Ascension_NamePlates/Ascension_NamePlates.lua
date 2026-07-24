local addonName, addonTable = ...

local IncompatibleAddOns = {
    "Kui_Nameplates",
    "TidyPlates_ThreatPlates",
    "PlateBuffs",
}

local Addon = LibStub("AceAddon-3.0"):NewAddon(addonName)
addonTable[1] = Addon
addonTable.Version = tonumber(GetAddOnMetadata(addonName, "Version"))

_G.AscensionNamePlates = Addon

local LAC = LibStub("LibAscensionConfig")

Addon.options = LAC:Group("Ascension NamePlates", nil, 1, LAC.ChildGroupType.Tab)

function Addon:OnInitialize()
    RunNextFrame(GenerateClosure(self.CheckAddOnCompatability, self))
    self.db = LibStub("AceDB-3.0"):New("Ascension_NamePlatesDB", LAC:BuildDefaultsTable("profile", self.options.args), true)
    self.db.RegisterCallback(self, "OnProfileChanged", "UpdateAll")
    self.db.RegisterCallback(self, "OnProfileCopied", "UpdateAll")
    self.db.RegisterCallback(self, "OnProfileReset", "UpdateAll")

    self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.options:UseDefaultGetSet(self.db.profile, GenerateClosure(self.UpdateAll, self))
    LAC:PrepareForOptionTable(self.options)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "Ascension NamePlates")
    self:UpdateAll()
end

function Addon:GetOption(option, ...)
    if select("#", ...) > 0 then
        local value = self.db.profile[option]
        for i = 1, select("#", ...) do
            if value == nil then
                return
            end
            value = value[select(i, ...)]
        end
        return value
    else
        return self.db.profile[option]
    end
end

function Addon:GetGeneralOption(option, ...)
    return self:GetOption("general", option, ...)
end

function Addon:GetFriendlyOption(option, ...)
    return self:GetOption("friendly", option, ...)
end

function Addon:GetEnemyOption(option, ...)
    return self:GetOption("enemy", option, ...)
end

function Addon:GetPlayerOption(option, ...)
    return self:GetOption("personal", option, ...)
end

function Addon:UpdateAll()
    local clickableHeight = self:GetGeneralOption("clickable", "height")
    local clickableWidth = self:GetGeneralOption("clickable", "width")
    if clickableHeight ~= C_CVar.GetNumber("nameplateWidth") or clickableWidth ~= C_CVar.GetNumber("nameplateHeight") then
        C_NamePlateManager.SetNamePlateSize(clickableWidth, clickableHeight)
    else
        C_NamePlateManager.RefreshNamePlateSize()
    end

    NamePlateDriverFrame:UpdateNamePlateOptions()
end

function Addon:CheckAddOnCompatability()
    for _, addon in ipairs(IncompatibleAddOns) do
        if select(4, GetAddOnInfo(addon)) then
            StaticPopup_Show("NAMEPLATE_ADDON_CONFLICT", addon, nil, addon)
            return
        end
    end
end
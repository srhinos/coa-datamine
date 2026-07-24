local addonName, addonTable = ...
local Addon = addonTable[1]
local LAC = LibStub("LibAscensionConfig")
local ACR = LibStub("AceConfigRegistry-3.0")

local HEALTH_FORMATS = {
    ["losthealth"] = "Missing",
    ["health"] = "Current",
    ["health-full"] = "Current / Max",
    ["perc"] = "Current Percent",
    ["perc-full"] = "Current / Max - Percent"
}

local QUEST_ICON_ANCHORS = {
    ["TOP"] = "Top",
    ["LEFT"] = "Left",
    ["RIGHT"] = "Right",
}

local general = LAC:Group("General", nil, 1, LAC.ChildGroupType.Tab)
Addon.options:AddChild("general", general)

local friendly = LAC:Group("Friendly", nil, 2, LAC.ChildGroupType.Tab)
Addon.options:AddChild("friendly", friendly)

local enemy = LAC:Group("Enemy", nil, 3, LAC.ChildGroupType.Tab)
Addon.options:AddChild("enemy", enemy)

local personal = LAC:Group("Personal", nil, 4, LAC.ChildGroupType.Tab)
Addon.options:AddChild("personal", personal)

do -- general
    -- .useClassicStyle
    general:AddChild("useClassicStyle", LAC:Toggle("Classic Style", "Use classic style textures.", false))
    -- general.clickable.
    -- .height
    -- .width
    -- .showBox
    -- .targetScale
    local sizeGroup = LAC:Group("Size", nil, nil, LAC.ChildGroupType.Inline)
    general:AddChild("clickable", sizeGroup)
    
    sizeGroup:AddChild("height", LAC:Range("Clickable-Height", "Controls the clickable area of the NamePlate.", C_CVar.GetDefaultNumber("nameplateHeight"), { min = C_CVar.GetMin("nameplateHeight"), max = C_CVar.GetMax("nameplateHeight"), step = 1 }))
    sizeGroup:AddChild("width", LAC:Range("Clickable-Width", "Controls the clickable area of the NamePlate.", C_CVar.GetDefaultNumber("nameplateWidth"), { min = C_CVar.GetMin("nameplateWidth"), max = C_CVar.GetMax("nameplateWidth"), step = 1 }))
    local showBox = LAC:Toggle("Show Clickable Box", "Draw a white box over the clickable area on all NamePlates", false)
    showBox.get = function() return C_CVar.GetBool("DrawNameplateClickBox") end
    showBox.set = function(_, value) C_CVar.Set("DrawNameplateClickBox", value) Addon:UpdateAll() end
    sizeGroup:AddChild("showBox", showBox)
    sizeGroup:AddChild("targetScale", LAC:Range("Target Scale", "Sets the scale of the NamePlate when it is the target.", 1.1, { min = 0.8, max = 1.4, step = 0.1 }))
end

local unitGroups = {
    friendly,
    enemy,
}
for _, group in ipairs(unitGroups) do
    -- group.name
    -- .font
    -- .fontSize
    -- .fontFlags
    local nameGroup = LAC:Group("Name", nil, nil, LAC.ChildGroupType.Inline)
    group:AddChild("name", nameGroup)
    nameGroup:AddChild("displayName", LAC:Toggle("Display Name", nil, true))
    LAC:AddFontControls(nameGroup, nil, 8, { softMin = 8, softMax = 18, step = 1 }, "NONE")
    
    -- group.health
    -- .width
    -- .height
    -- .textFormat
    -- .showTextFormat
    -- .font
    -- .fontSize
    -- .fontFlags
    -- .statusBar
    -- .usePrimaryStatColor
    -- .useClassColor
    -- .backgroundColor
    
    -- friendly only!!
    -- .nameOnly
    local healthGroup = LAC:Group("Health", nil, nil, LAC.ChildGroupType.Tab)
    group:AddChild("health", healthGroup)
    if group == friendly then
        healthGroup:AddChild("nameOnly", LAC:Toggle("Name Only", "Only show the name on the NamePlate (no health bar).", false))
        healthGroup:AddChild("div0", LAC:Divider())
    end
    healthGroup:AddChild("width", LAC:Range("Bar Width", "Sets the width of the NamePlate health bar.|n|nThis will not change the clickable area!", 110, { min = 40, max = 200, step = 1 }, nil, function() return Addon:GetGeneralOption("useClassicStyle") end))
    healthGroup:AddChild("height", LAC:Range("Bar Height", "Sets the width of the NamePlate health bar.|n|nThis will not change the clickable area!", 4, { min = 4, max = 60, step = 1 }, nil, function() return Addon:GetGeneralOption("useClassicStyle") end))
    healthGroup:AddChild("textFormat", LAC:Select("Text Format", nil, "perc", HEALTH_FORMATS))
    healthGroup:AddChild("showTextFormat", LAC:Toggle("Show Health Text", nil, false))
    healthGroup:AddChild("div1", LAC:Divider())
    LAC:AddFontControls(healthGroup, nil, 8, { softMin = 8, softMax = 18, step = 1 }, "NONE")
    healthGroup:AddChild("statusBar", LAC:SharedMediaStatusbar("Bar Texture", nil, "Blizzard2"))
    healthGroup:AddChild("div2", LAC:Divider())
    if IsHeroClass() then
        healthGroup:AddChild("usePrimaryStatColor", LAC:Toggle("Use Primary Stat Color", "Use the color of the player's primary stat for the health bar.", false))
    else
        healthGroup:AddChild("useClassColor", LAC:Toggle("Use Class Color", "Use the player's class color for the health bar.", true))
    end
    healthGroup:AddChild("div3", LAC:Divider())
    healthGroup:AddChild("backgroundColor", LAC:Color("Background Color", nil, true, { 0.2, 0.2, 0.2, 0.85 }))
    local function ResetColor()
        if group == friendly then
            Addon.db.profile.friendly.health.backgroundColor = Addon.db.defaults.profile.friendly.health.backgroundColor
        elseif group == enemy then
            Addon.db.profile.enemy.health.backgroundColor = Addon.db.defaults.profile.enemy.health.backgroundColor
        end
        ACR:NotifyChange(addonName)
        Addon:UpdateAll()
    end
    healthGroup:AddChild("resetBackground", LAC:Execute("Reset Background Color", nil, ResetColor, nil, nil, 1.5))
    
    -- group.castBar
    -- .enabled
    -- .font
    -- .fontSize
    -- .fontFlags
    -- .statusBar
    -- .height
    local castBarGroup = LAC:Group("Cast Bar", nil, nil, LAC.ChildGroupType.Tab)
    group:AddChild("castBar", castBarGroup)
    castBarGroup:AddChild("enabled", LAC:Toggle("Enabled", nil, group == enemy))
    castBarGroup:AddChild("div1", LAC:Divider())
    LAC:AddFontControls(castBarGroup, nil, 8, { softMin = 8, softMax = 18, step = 1 }, "NONE")
    castBarGroup:AddChild("statusBar", LAC:SharedMediaStatusbar("Bar Texture", nil, "Blizzard2"))
    castBarGroup:AddChild("height", LAC:Range("Height", nil, 10, { min = 4, max = 32, step = 1 }, nil, function() return Addon:GetGeneralOption("useClassicStyle") end))
    
    -- group.levelIndicator
    -- .showPlayerLevel
    -- .showNPCLevel
    local levelGroup = LAC:Group("Level Indicator", nil, nil, LAC.ChildGroupType.Tab, function() return Addon:GetGeneralOption("useClassicStyle") end)
    group:AddChild("levelIndicator", levelGroup)
    levelGroup:AddChild("showPlayerLevel", LAC:Toggle("Player Level", nil, true))
    levelGroup:AddChild("showNPCLevel", LAC:Toggle("NPC Level", nil, group == enemy))
    
    -- group.objectiveIcons
    -- .showQuestNPCs
    -- .showQuestObjectives
    -- .iconScale
    -- .anchor
    local objectiveGroup = LAC:Group("Objective Icons", nil, nil, LAC.ChildGroupType.Tab)
    group:AddChild("objectiveIcons", objectiveGroup)
    objectiveGroup:AddChild("showQuestNPCs", LAC:Toggle("Show Quest NPCs", "Show quest pick up and turn in icons", true))
    objectiveGroup:AddChild("showQuestObjectives", LAC:Toggle("Show Quest Objectives", "Show collect and kill quest objective icons", true))
    objectiveGroup:AddChild("iconScale", LAC:Range("Icon Scale", nil, 0.65, { min = 0.5, max = 2, step = 0.05 }))
    objectiveGroup:AddChild("anchor", LAC:Select("Icon Anchor", "Sets where the icon should appear next to the unit's name", "LEFT", QUEST_ICON_ANCHORS))
end

do -- personal
     -- personal.health
    -- .width
    -- .height
    -- .textFormat
    -- .showTextFormat
    -- .font
    -- .fontSize
    -- .fontFlags
    -- .statusBar
    -- .backgroundColor
    local healthGroup = LAC:Group("Health", nil, nil, LAC.ChildGroupType.Tab)
    personal:AddChild("health", healthGroup)
    healthGroup:AddChild("width", LAC:Range("Bar Width", "Sets the width of the NamePlate health bar.|n|nThis will not change the clickable area!", 80, { min = 40, max = 200, step = 1 }))
    healthGroup:AddChild("height", LAC:Range("Bar Height", "Sets the width of the NamePlate health bar.|n|nThis will not change the clickable area!", 8, { min = 4, max = 60, step = 1 }))
    healthGroup:AddChild("textFormat", LAC:Select("Text Format", nil, "perc", HEALTH_FORMATS))
    healthGroup:AddChild("showTextFormat", LAC:Toggle("Show Health Text", nil, false))
    healthGroup:AddChild("div1", LAC:Divider())
    LAC:AddFontControls(healthGroup, nil, 8, { softMin = 8, softMax = 18, step = 1 }, "NONE")
    healthGroup:AddChild("statusBar", LAC:SharedMediaStatusbar("Bar Texture", nil, "Blizzard2"))
    healthGroup:AddChild("div2", LAC:Divider())
    healthGroup:AddChild("backgroundColor", LAC:Color("Background Color", nil, true, { 0.2, 0.2, 0.2, 0.85 }))
    local function ResetColor()
        Addon.db.profile.personal.health.backgroundColor = Addon.db.defaults.profile.personal.health.backgroundColor
        ACR:NotifyChange(addonName)
        Addon:UpdateAll()
    end
    healthGroup:AddChild("resetBackground", LAC:Execute("Reset Background Color", nil, ResetColor, nil, nil, 1.5))
end

local CLASSIC_STYLE_FIXED_WIDTH = 110
local CLASSIC_STYLE_FIXED_HEIGHT = 12

local Addon = select(2, ...)[1]
local LSM = LibStub("LibSharedMedia-3.0")

NamePlateDriverMixin = {}

function NamePlateDriverMixin:OnLoad()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UNIT_FACTION")
    self:RegisterEvent("CVAR_UPDATE")
    
    EventRegistry:RegisterCallback("NamePlateManager.UnitAdded", self.NamePlateUnitAdded, self)
    EventRegistry:RegisterCallback("NamePlateManager.UnitRemoved", self.NamePlateUnitRemoved, self)

    C_NamePlateManager.SetEnableResizeNamePlates(true)
    self.pool = CreateFramePool("BUTTON", self, "NamePlateUnitFrameTemplate")
end

function NamePlateDriverMixin:GetUnitFrame(baseFrame, unit)
    local frame, isNew = self.pool:Acquire()
    if isNew then
        frame:SetParent(baseFrame)
        frame:EnableMouse(false)
        baseFrame:SetScript("OnSizeChanged", function(self, width, height)
            frame:SetSize(width, height)
        end)
        C_NamePlateManager.DisableBlizzPlate(unit)
        C_NamePlateManager.ApplyFPSIncrease(frame)
    end
    return frame
end

function NamePlateDriverMixin:SetNamePlateSize(width, height)
    if C_CVar.GetNumber("nameplateWidth") == width and C_CVar.GetNumber("nameplateHeight") == height then
        return
    end
    C_NamePlateManager.SetNamePlateSize(width, height)
    self:UpdateNamePlateOptions()
end

function NamePlateDriverMixin:UpdateNamePlateOptions()
    -- general settings
    local useClassicStyle = Addon:GetGeneralOption("useClassicStyle")
    
    -- enemy settings
    DefaultCompactNamePlateEnemyFrameOptions.nameplateTargetScale = Addon:GetGeneralOption("clickable", "targetScale")
    DefaultCompactNamePlateEnemyFrameOptions.useClassicStyle = useClassicStyle

    DefaultCompactNamePlateEnemyFrameOptions.displayName = Addon:GetEnemyOption("name", "displayName")
    DefaultCompactNamePlateEnemyFrameOptions.nameFont = LSM:Fetch("font", Addon:GetEnemyOption("name", "font"))
    DefaultCompactNamePlateEnemyFrameOptions.nameFontHeight = Addon:GetEnemyOption("name", "fontSize")
    DefaultCompactNamePlateEnemyFrameOptions.nameFontFlags = Addon:GetEnemyOption("name", "fontFlags")

    if useClassicStyle then
        DefaultCompactNamePlateEnemyFrameOptions.healthHeight = CLASSIC_STYLE_FIXED_HEIGHT
        DefaultCompactNamePlateEnemyFrameOptions.healthWidth = CLASSIC_STYLE_FIXED_WIDTH
    else
        DefaultCompactNamePlateEnemyFrameOptions.healthHeight = Addon:GetEnemyOption("health", "height")
        DefaultCompactNamePlateEnemyFrameOptions.healthWidth = Addon:GetEnemyOption("health", "width")
    end
    DefaultCompactNamePlateEnemyFrameOptions.healthText = Addon:GetEnemyOption("health", "textFormat")
    DefaultCompactNamePlateEnemyFrameOptions.displayStatusText = Addon:GetEnemyOption("health", "showTextFormat")
    DefaultCompactNamePlateEnemyFrameOptions.healthTextFont = LSM:Fetch("font", Addon:GetEnemyOption("health", "font"))
    DefaultCompactNamePlateEnemyFrameOptions.healthTextFontHeight = Addon:GetEnemyOption("health", "fontSize")
    DefaultCompactNamePlateEnemyFrameOptions.healthTextFontFlags = Addon:GetEnemyOption("health", "fontFlags")
    DefaultCompactNamePlateEnemyFrameOptions.healthStatusBar = LSM:Fetch("statusbar", Addon:GetEnemyOption("health", "statusBar"))
    DefaultCompactNamePlateEnemyFrameOptions.usePrimaryStatColor = Addon:GetEnemyOption("health", "usePrimaryStatColor")
    DefaultCompactNamePlateEnemyFrameOptions.useClassColors = Addon:GetEnemyOption("health", "useClassColor")
    DefaultCompactNamePlateEnemyFrameOptions.backgroundColor = Addon:GetEnemyOption("health", "backgroundColor")
    DefaultCompactNamePlateEnemyFrameOptions.nameOnly = false

    DefaultCompactNamePlateEnemyFrameOptions.hideCastbar = not Addon:GetEnemyOption("castBar", "enabled")
    DefaultCompactNamePlateEnemyFrameOptions.castBarFont = LSM:Fetch("font", Addon:GetEnemyOption("castBar", "font"))
    DefaultCompactNamePlateEnemyFrameOptions.castBarFontHeight = Addon:GetEnemyOption("castBar", "fontSize")
    DefaultCompactNamePlateEnemyFrameOptions.castBarFontFlags = Addon:GetEnemyOption("castBar", "fontFlags")
    DefaultCompactNamePlateEnemyFrameOptions.castBarStatusBar = LSM:Fetch("statusbar", Addon:GetEnemyOption("castBar", "statusBar"))
    if useClassicStyle then
        DefaultCompactNamePlateEnemyFrameOptions.castBarHeight = CLASSIC_STYLE_FIXED_HEIGHT
        DefaultCompactNamePlateEnemyFrameOptions.showPlayerLevel = true
        DefaultCompactNamePlateEnemyFrameOptions.showNPCLevel = true
        DefaultCompactNamePlateEnemyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 0)
    else
        DefaultCompactNamePlateEnemyFrameOptions.castBarHeight = Addon:GetEnemyOption("castBar", "height")
        DefaultCompactNamePlateEnemyFrameOptions.showPlayerLevel = Addon:GetEnemyOption("levelIndicator", "showPlayerLevel")
        DefaultCompactNamePlateEnemyFrameOptions.showNPCLevel = Addon:GetEnemyOption("levelIndicator", "showNPCLevel")
        DefaultCompactNamePlateEnemyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 0.6)
    end
    
    DefaultCompactNamePlateEnemyFrameOptions.showQuestNPCIcons = Addon:GetEnemyOption("objectiveIcons", "showQuestNPCs")
    DefaultCompactNamePlateEnemyFrameOptions.showQuestObjectives = Addon:GetEnemyOption("objectiveIcons", "showQuestObjectives")
    DefaultCompactNamePlateEnemyFrameOptions.questIconScale = Addon:GetEnemyOption("objectiveIcons", "iconScale") * 0.5
    DefaultCompactNamePlateEnemyFrameOptions.questIconAnchor = Addon:GetEnemyOption("objectiveIcons", "anchor")

    -- friendly settings
    DefaultCompactNamePlateFriendlyFrameOptions.nameplateTargetScale = Addon:GetGeneralOption("clickable", "targetScale")
    DefaultCompactNamePlateFriendlyFrameOptions.useClassicStyle = useClassicStyle

    DefaultCompactNamePlateFriendlyFrameOptions.displayName = Addon:GetFriendlyOption("name", "displayName")
    DefaultCompactNamePlateFriendlyFrameOptions.nameFont = LSM:Fetch("font", Addon:GetFriendlyOption("name", "font"))
    DefaultCompactNamePlateFriendlyFrameOptions.nameFontHeight = Addon:GetFriendlyOption("name", "fontSize")
    DefaultCompactNamePlateFriendlyFrameOptions.nameFontFlags = Addon:GetFriendlyOption("name", "fontFlags")

    if useClassicStyle then
        DefaultCompactNamePlateFriendlyFrameOptions.healthHeight = CLASSIC_STYLE_FIXED_HEIGHT
        DefaultCompactNamePlateFriendlyFrameOptions.healthWidth = CLASSIC_STYLE_FIXED_WIDTH
    else
        DefaultCompactNamePlateFriendlyFrameOptions.healthHeight = Addon:GetFriendlyOption("health", "height")
        DefaultCompactNamePlateFriendlyFrameOptions.healthWidth = Addon:GetFriendlyOption("health", "width")
    end
    DefaultCompactNamePlateFriendlyFrameOptions.healthText = Addon:GetFriendlyOption("health", "textFormat")
    DefaultCompactNamePlateFriendlyFrameOptions.displayStatusText = Addon:GetFriendlyOption("health", "showTextFormat")
    DefaultCompactNamePlateFriendlyFrameOptions.healthTextFont = LSM:Fetch("font", Addon:GetFriendlyOption("health", "font"))
    DefaultCompactNamePlateFriendlyFrameOptions.healthTextFontHeight = Addon:GetFriendlyOption("health", "fontSize")
    DefaultCompactNamePlateFriendlyFrameOptions.healthTextFontFlags = Addon:GetFriendlyOption("health", "fontFlags")
    DefaultCompactNamePlateFriendlyFrameOptions.healthStatusBar = LSM:Fetch("statusbar", Addon:GetFriendlyOption("health", "statusBar"))
    DefaultCompactNamePlateFriendlyFrameOptions.usePrimaryStatColor = Addon:GetFriendlyOption("health", "usePrimaryStatColor")
    DefaultCompactNamePlateFriendlyFrameOptions.useClassColors = Addon:GetFriendlyOption("health", "useClassColor")
    DefaultCompactNamePlateFriendlyFrameOptions.backgroundColor = Addon:GetFriendlyOption("health", "backgroundColor")
    DefaultCompactNamePlateFriendlyFrameOptions.nameOnly = Addon:GetFriendlyOption("health", "nameOnly")

    DefaultCompactNamePlateFriendlyFrameOptions.hideCastbar = not Addon:GetFriendlyOption("castBar", "enabled")
    DefaultCompactNamePlateFriendlyFrameOptions.castBarFont = LSM:Fetch("font", Addon:GetFriendlyOption("castBar", "font"))
    DefaultCompactNamePlateFriendlyFrameOptions.castBarFontHeight = Addon:GetFriendlyOption("castBar", "fontSize")
    DefaultCompactNamePlateFriendlyFrameOptions.castBarFontFlags = Addon:GetFriendlyOption("castBar", "fontFlags")
    DefaultCompactNamePlateFriendlyFrameOptions.castBarStatusBar = LSM:Fetch("statusbar", Addon:GetFriendlyOption("castBar", "statusBar"))
    if useClassicStyle then
        DefaultCompactNamePlateFriendlyFrameOptions.castBarHeight = CLASSIC_STYLE_FIXED_HEIGHT
        DefaultCompactNamePlateFriendlyFrameOptions.showPlayerLevel = true
        DefaultCompactNamePlateFriendlyFrameOptions.showNPCLevel = true
        DefaultCompactNamePlateFriendlyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 0)
    else
        DefaultCompactNamePlateFriendlyFrameOptions.castBarHeight = Addon:GetFriendlyOption("castBar", "height")
        DefaultCompactNamePlateFriendlyFrameOptions.showPlayerLevel = Addon:GetFriendlyOption("levelIndicator", "showPlayerLevel")
        DefaultCompactNamePlateFriendlyFrameOptions.showNPCLevel = Addon:GetFriendlyOption("levelIndicator", "showNPCLevel")
        DefaultCompactNamePlateFriendlyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 0.6)
    end

    DefaultCompactNamePlateFriendlyFrameOptions.showQuestNPCIcons = Addon:GetFriendlyOption("objectiveIcons", "showQuestNPCs")
    DefaultCompactNamePlateFriendlyFrameOptions.showQuestObjectives = Addon:GetFriendlyOption("objectiveIcons", "showQuestObjectives")
    DefaultCompactNamePlateFriendlyFrameOptions.questIconScale = Addon:GetFriendlyOption("objectiveIcons", "iconScale") * 0.5
    DefaultCompactNamePlateFriendlyFrameOptions.questIconAnchor = Addon:GetFriendlyOption("objectiveIcons", "anchor")

    -- player settings
    DefaultCompactNamePlatePlayerFrameOptions.healthHeight = Addon:GetPlayerOption("health", "height")
    DefaultCompactNamePlatePlayerFrameOptions.healthWidth = Addon:GetPlayerOption("health", "width")
    DefaultCompactNamePlatePlayerFrameOptions.healthText = Addon:GetPlayerOption("health", "textFormat")
    DefaultCompactNamePlatePlayerFrameOptions.displayStatusText = Addon:GetPlayerOption("health", "showTextFormat")
    DefaultCompactNamePlatePlayerFrameOptions.healthTextFont = LSM:Fetch("font", Addon:GetPlayerOption("health", "font"))
    DefaultCompactNamePlatePlayerFrameOptions.healthTextFontHeight = Addon:GetPlayerOption("health", "fontSize")
    DefaultCompactNamePlatePlayerFrameOptions.healthTextFontFlags = Addon:GetPlayerOption("health", "fontFlags")
    DefaultCompactNamePlatePlayerFrameOptions.healthStatusBar = LSM:Fetch("statusbar", Addon:GetPlayerOption("health", "statusBar"))
    DefaultCompactNamePlatePlayerFrameOptions.backgroundColor = Addon:GetPlayerOption("health", "backgroundColor")
    DefaultCompactNamePlatePlayerFrameOptions.nameOnly = false

    local drawClickBox = C_CVar.GetBool("DrawNameplateClickBox")
    for frame in C_NamePlateManager.EnumerateActiveNamePlates() do
        if drawClickBox then
            if not frame.ClickBoxDebug then
                frame.ClickBoxDebug = frame:CreateTexture(nil, "OVERLAY")
                frame.ClickBoxDebug:SetTexture(1, 1, 1, 0.5)
                frame.ClickBoxDebug:SetAllPoints()
            end
            frame.ClickBoxDebug:Show()
        elseif frame.ClickBoxDebug then
            frame.ClickBoxDebug:Hide()
        end
        frame.UnitFrame:SetUnit(frame.UnitFrame.unit)
        if frame.UnitFrame.unit then
            self:ApplyFrameOptions(frame.UnitFrame, frame.UnitFrame.unit)
        end
    end

    --[[if self.nameplateBar then
        self.nameplateBar:OnOptionsUpdated()
    end
    if self.nameplateManaBar then
        self.nameplateManaBar:OnOptionsUpdated()
    end
    self:SetupClassNameplateBars()]]
end

function NamePlateDriverMixin:ApplyFrameOptions(unitFrame, unit)
    if unit and UnitIsUnit(unit, "player") then
        unitFrame:SetUpFrame(DefaultCompactNamePlatePlayerFrameSetup)
    elseif unit and UnitIsFriend("player", unit) then
        unitFrame:SetUpFrame(DefaultCompactNamePlateFriendlyFrameSetup)
    else
        unitFrame:SetUpFrame(DefaultCompactNamePlateEnemyFrameSetup)
    end
end

local unitFrames = {}
function NamePlateDriverMixin:PLAYER_ENTERING_WORLD()
    RunNextFrame(function()
        self:UpdateNamePlateOptions()
        for np in C_NamePlateManager.EnumerateActiveNamePlates() do
            self:NamePlateUnitAdded(np._unit)
        end
    end)
end

function NamePlateDriverMixin:NamePlateUnitAdded(unit, nameplate)
    if not nameplate then
        return
    end
    local unitFrame = nameplate.UnitFrame
    if not unitFrame then
        unitFrame = self:GetUnitFrame(nameplate, unit)
        nameplate.UnitFrame = unitFrame
        EventRegistry:TriggerEvent("NamePlateDriver.UnitFrameCreated", nameplate)
    end

    unitFrames[unit] = unitFrame

    unitFrame:SetSize(C_NamePlateManager.GetNamePlateSize())
    if UnitIsUnit(unit, "player") then
        unitFrame:SetUpFrame(DefaultCompactNamePlatePlayerFrameSetup)
    elseif UnitIsFriend("player", unit) then
        unitFrame:SetUpFrame(DefaultCompactNamePlateFriendlyFrameSetup)
    else
        unitFrame:SetUpFrame(DefaultCompactNamePlateEnemyFrameSetup)
    end
    unitFrame:Show()
    unitFrame.BuffFrame:SetActive(true)
    unitFrame:SetUnit(unit)
    unitFrame:UpdateRaidTarget()
end

function NamePlateDriverMixin:NamePlateUnitRemoved(unit, nameplate)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame then
        return
    end
    unitFrame.BuffFrame:SetActive(false)
    unitFrame:SetUnit(nil)
    unitFrame:Hide()
end

function NamePlateDriverMixin:UNIT_FACTION(unit)
    if unitFrames[unit] then
        self:ApplyFrameOptions(unitFrames[unit], unit)
    end
end

function NamePlateDriverMixin:CVAR_UPDATE(name)
    if name == "SHOW_CLASS_COLOR_IN_V_KEY" or name == "SHOW_PRIMARY_STAT_IN_NAMEPLATE" or name == "USE_CLASSIC_NAMEPLATE_STYLE" then
        self:UpdateNamePlateOptions()
    end
end

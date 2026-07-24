local _, NPE = ...

NPE.openTips = {}

function NPE:ClearAllHelpTips()
    for system in pairs(NPE.openTips) do
        HelpTip:HideAllSystem(system)
    end
    
    wipe(NPE.openTips)
end

function NPE:ClearAllHelpTipsForSystem(system)
    HelpTip:HideAllSystem(system)
    NPE.openTips[system] = nil
end

function NPE:CreateHelpTip(tipInfo, system)
    if not tipInfo.system then
        tipInfo.system = system or "NPE"
    end

    if not tipInfo.strata then
        tipInfo.strata = "TOOLTIP"
    end
    
    NPE.openTips[tipInfo.system] = true
    
    local parent = _G[tipInfo.parent] or tipInfo.parent
    local relativeRegion = _G[tipInfo.relativeRegion] or tipInfo.relativeRegion

    if not parent then 
        return C_Logger.Error("NPE: Tried to add tip [%s:%s] with nil parent: %s", tipInfo.system or "nil", tipInfo.text or "nil", tipInfo.parent or "nil")
    end
    
    return {
        Show = function()
            HelpTip:Show(parent, tipInfo, relativeRegion)
        end,
        Hide = function()
            HelpTip:Acknowledge(parent, tipInfo.text)
        end
    }
end

function NPE:CreateStickyHelpTip(tipInfo, system)
    if not tipInfo.dontReleaseUntilAcknowledged then
        tipInfo.dontReleaseUntilAcknowledged = true
    end
    
    return NPE:CreateHelpTip(tipInfo, system)
end
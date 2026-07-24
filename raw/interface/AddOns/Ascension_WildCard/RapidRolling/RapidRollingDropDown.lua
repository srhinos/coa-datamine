-- RapidRollingDropDown.lua
-- Hero Architect bookmarked build dropdown menu logic for Rapid Rolling UI.

WildCardRapidRollingMixin = WildCardRapidRollingMixin or {}

function WildCardRapidRollingMixin:GenerateHeroArchitectImportDropDown(dropdown, level, menuList)
    level = level or 1
    if level == 1 then
        local info = UIDropDownMenu_CreateInfo()
        info.text = OPEN_HERO_ARCHITECT
        info.tooltipTitle = OPEN_HERO_ARCHITECT
        info.tooltipText = OPEN_HERO_ARCHITECT_TOOLTIP
        info.tooltipOnButton = true
        info.notCheckable = true
        info.func = function() 
            Collections:GoToTab(Collections.Tabs.HeroArchitect)
            BuildCreatorFrame:SelectCategory(Enum.BuildCategory.BuildDraftEndGamePvE)
        end
        UIDropDownMenu_AddButton(info, level)

        if C_BuildCreator.GetNumBookmarkedBuilds() <= 0 then
            info = UIDropDownMenu_CreateInfo()
            info.text = NO_RECENT_BUILDS
            info.tooltipTitle = NO_RECENT_BUILDS
            info.tooltipText = NO_RECENT_BUILDS_TOOLTIP
            info.tooltipOnButton = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
            return
        end
        
        for i = 1, 4 do
            local buildID = C_BuildCreator.GetBookmarkedBuildAtIndex(i)
            local build = C_BuildCreator.GetBuild(buildID)
            if build then
                info = UIDropDownMenu_CreateInfo()
                info.text = build.Name
                info.icon = "Interface\\Icons\\"..build.Icon
                info.notCheckable = true
                info.menuList = buildID
                info.hasArrow = true
                UIDropDownMenu_AddButton(info, level)
            else
                C_BuildCreator.QueryBuild(buildID)
            end
        end
        
    elseif level == 2 then
        local build = C_BuildCreator.GetBuild(menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.text = build and build.Name or UNKNOWN
        info.notCheckable = true
        info.isTitle = true
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = DESIRE_ALL_CORE_SPELLS
        info.tooltipTitle = DESIRE_ALL_CORE_SPELLS
        info.tooltipText = DESIRE_ALL_CORE_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.tooltipWhileDisabled = true
        info.disabled = not build or build.NumCoreSpells == 0
        info.func = function() self:DesireBuildCoreSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = DESIRE_ALL_OPTIMAL_SPELLS
        info.tooltipTitle = DESIRE_ALL_OPTIMAL_SPELLS
        info.tooltipText = DESIRE_ALL_OPTIMAL_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.tooltipWhileDisabled = true
        info.disabled = not build or build.NumOptimalSpells == 0
        info.func = function() self:DesireBuildOptimalSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = DESIRE_ALL_EMPOWERING_SPELLS
        info.tooltipTitle = DESIRE_ALL_EMPOWERING_SPELLS
        info.tooltipText = DESIRE_ALL_EMPOWERING_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.tooltipWhileDisabled = true
        info.disabled = not build or build.NumEmpoweringSpells == 0
        info.func = function() self:DesireBuildEmpoweringSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = DESIRE_ALL_SYNERGISTIC_SPELLS
        info.tooltipTitle = DESIRE_ALL_SYNERGISTIC_SPELLS
        info.tooltipText = DESIRE_ALL_SYNERGISTIC_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.tooltipWhileDisabled = true
        info.disabled = not build or build.NumSynergisticSpells == 0
        info.func = function() self:DesireBuildSynergisticSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = DESIRE_ALL_SPELLS
        info.tooltipTitle = DESIRE_ALL_SPELLS
        info.tooltipText = DESIRE_ALL_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:DesireBuildAllSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = UNDESIRE_ALL_SPELLS
        info.tooltipTitle = UNDESIRE_ALL_SPELLS
        info.tooltipText = UNDESIRE_ALL_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:StartUndesireAll(build) end
        UIDropDownMenu_AddButton(info, level)

        UIDropDownMenu_AddSpace(level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = LOCK_BUILD_SPELLS
        info.tooltipTitle = LOCK_BUILD_SPELLS
        info.tooltipText = LOCK_BUILD_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:LockBuildSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = LOCK_CORE_SPELLS
        info.tooltipTitle = LOCK_CORE_SPELLS
        info.tooltipText = LOCK_CORE_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:LockBuildCoreSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = LOCK_OPTIMAL_SPELLS
        info.tooltipTitle = LOCK_OPTIMAL_SPELLS
        info.tooltipText = LOCK_OPTIMAL_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:LockBuildOptimalSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = LOCK_EMPOWERING_SPELLS
        info.tooltipTitle = LOCK_EMPOWERING_SPELLS
        info.tooltipText = LOCK_EMPOWERING_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:LockBuildEmpoweringSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = LOCK_SYNERGISTIC_SPELLS
        info.tooltipTitle = LOCK_SYNERGISTIC_SPELLS
        info.tooltipText = LOCK_SYNERGISTIC_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:LockBuildSynergisticSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = UNLOCK_EMPOWERING_SPELLS
        info.tooltipTitle = UNLOCK_EMPOWERING_SPELLS
        info.tooltipText = UNLOCK_EMPOWERING_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:UnlockBuildEmpoweringSpells(build) end
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = UNLOCK_SYNERGISTIC_SPELLS
        info.tooltipTitle = UNLOCK_SYNERGISTIC_SPELLS
        info.tooltipText = UNLOCK_SYNERGISTIC_SPELLS_TOOLTIP
        info.tooltipOnButton = true
        info.disabled = not build
        info.tooltipWhileDisabled = true
        info.func = function() self:UnlockBuildSynergisticSpells(build) end
        UIDropDownMenu_AddButton(info, level)
    end
end

function WildCardRapidRollingMixin:ShowImportHint()
    local tip = {
        text = IMPORT_YOUR_ARCHITECT_BUILD,
        targetPoint = HelpTip.Point.TopEdgeCenter,
        parent = self.HeroArchitectImport,
        highlightTarget = HelpTip.TargetType.Box,
        buttonStyle = HelpTip.ButtonStyle.Close,
        strata = "TOOLTIP"
    }
    HelpTip:Show(tip.parent, tip)
end

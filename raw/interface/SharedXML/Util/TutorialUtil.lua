TutorialUtil = {}

function TutorialUtil.CanShowAnyTutorials()
    return C_CVar.GetNumber("tutorialLevel") >= 1
end

function TutorialUtil.HasPickedTutorialExperience()
    return C_CVar.GetNumber("tutorialLevel") and (C_CVar.GetNumber("tutorialLevel") ~= 0)
end

function TutorialUtil.SetTutorialExperience(level)
    C_CVar.Set("tutorialLevel", level)
    EventRegistry:TriggerEvent("TutorialSystem.ExperienceChanged", level)
    print("reportMetric "..tostring(level or 0))
    ReportMetric("StartingExperience", tostring(level or 0))
end

function TutorialUtil.GetTutorialExperience()
    return C_CVar.GetNumber("tutorialLevel")
end 

function TutorialUtil.CanChangeMentorStatus()
    local isMentor = C_Tutorial.IsMentorStatusActive()
    local canChangeMentor, reason = C_Tutorial.CanToggleMentorStatus(not isMentor)

    if canChangeMentor or isMentor then
        return canChangeMentor, reason
    end
    
    -- we arent a mentor and cant become one
    local incompleteTutorials = C_Tutorial.GetTutorialsRequiredForMentorStatus()
    local incompleteTutorialNames
    local name
    for _, tutorialID in ipairs(incompleteTutorials) do
        _, name = C_Tutorial.GetTutorialByID(tutorialID)
        if incompleteTutorialNames then
            incompleteTutorialNames = incompleteTutorialNames .. "|n"
        else
            incompleteTutorialNames = "|r"
        end
        incompleteTutorialNames = incompleteTutorialNames .. name
    end
    
    local incompleteTutorialsHeader =  NORMAL_FONT_COLOR_CODE .. MENTOR_REQUIRES_FOLLOWING_TUTORIALS
    return canChangeMentor, incompleteTutorialsHeader:format(incompleteTutorialNames or "|rUNKNOWN")
end 

function TutorialUtil.ConvertDynamicMentorIcon(atlas)
    if atlas then
        if atlas:startswith("dynamic_") then
            atlas = atlas:sub(9)
            if atlas == "factionsymbol" then
                atlas = UnitFactionGroup("player").."symbol"
            end
        end
    end
    return atlas
end

function TutorialUtil.CanOpenPathToAscension()
    local categories = C_Tutorial.GetCategories()
    local enabled = false
    for _, categoryID in ipairs(categories) do
        if C_Tutorial.IsCategoryEnabled(categoryID) then
            enabled = true
            break
        end
    end
    
    return enabled
end 
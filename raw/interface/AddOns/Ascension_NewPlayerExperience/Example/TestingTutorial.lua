local _, NPE = ...

local QUEST_TUTORIAL = "Quest Tutorial"
local MOVE_TUTORIAL = "Move Tutorial"

-------
--- Quest Tutorial
-------
do
    -- make a new tutorial object
    -- there can be multiple tutorial types as well as a generic one
    -- this is just a quest type as an example
    local myTutorial = NPE:NewQuestTutorial(QUEST_TUTORIAL, NPE.Const.NorthshireQuest1)
    
    -- register callbacks for when the tutorial starts and completes
    myTutorial:RegisterCallback("TutorialStarted", function()
        -- we accepted the quest
        print("Tutorial started")
        
        -- i want to skip mouse look tutorial if they already got the quest
        NPE:CompleteTutorial(MOVE_TUTORIAL)
    end)
    myTutorial:RegisterCallback("TutorialCompleted", function()
        -- we turned in the quest
        print("Tutorial completed")
    end)
    
    -- these callbacks exist for all tutorial types
    --  TutorialStarted
    --  TutorialFinished -- called when tutorial is completed or tutorial is stopped
    --  TutorialPaused
    --  TutorialResumed
    --  TutorialCompleted
    
    -- quest tutorials also have
    --  QuestAccepted
    --  QuestAbandoned
    --  QuestProgress
    --  QuestCompleted
    
    -- You can also set an OnTick function for a tutorial
    -- this is called every 'tick' (0.1s)
    -- myTutorial.OnTick = function(self) print("tick") end
    
    -- Add step 1 to complete the quest objective
    local step1 = myTutorial:AddStep()
    
    -- set a completion condition
    -- this is checked every 'tick' (0.1s)
    step1:SetCompletionCondition(function()
        return myTutorial:IsQuestReadyForTurnIn()
    end)
    
    -- register callbacks for when the step starts and completes
    -- step callbacks
    --  StepStarted
    --  StepCompleted
    --  StepFinished -- called when step is completed or step is stopped
    --  StepPaused
    --  StepResumed
    step1:RegisterCallback("StepStarted", function()
        print("Step 1 started, go complete the quest")
    
        -- maybe here you'd want to trigger a new tutorial
        -- of 'how to find a quest on the map'
        -- NPE:StartTutorial("Find Quest On Map", 0)
    end)
    
    step1:RegisterCallback("StepCompleted", function()
        -- completion condition was met
        print("Step 1 completed, go turn in the quest")
    end)
    
    step1:RegisterCallback("StepFinished", function()
        -- this step is done, either due to tutorial stopping or completion
    end)
    
    
    -- step 2 is to turn in the quest
    local step2 = myTutorial:AddStep()
    
    -- we dont have a completion condition since this is the last step
    -- any step could also have no condition and manually call
    -- myTutorial:StartNextStep() when you're ready
    
    -- register callbacks for when the step starts and completes
    step2:RegisterCallback("StepStarted", function()
        print("Step 2 started, go turn in the quest")
        
        -- maybe here you'd want to trigger a new tutorial
        -- of 'How to turn in a quest'
        -- NPE:StartTutorial(QUEST_TURN_IN, 0)
    end)
    
    step2:RegisterCallback("StepCompleted", function()
        -- the tutorial completes here.
        -- this is called before tutorial complete callback
        print("Step 2 completed, tutorial complete")
    end)
    
    step2:RegisterCallback("StepFinished", function()
        -- this step is done, either due to tutorial stopping or completion
        -- NPE:CompleteTutorial(QUEST_TURN_IN) -- end this tutorial as well since we did it
    end)
    
    NPE:AddTutorial(myTutorial)
end



-------
-- Move Tutorial
-------
do
    local moveTutorial = NPE:NewTutorial(MOVE_TUTORIAL)
    -- setting a min max level means this will setup/destroy based on player level
    moveTutorial:SetMinMaxLevel(1, 1)
    -- auto start will start this tutorial when it is setup
    moveTutorial:SetAutoStart(true)

    local step1 = moveTutorial:AddStep()
    step1:SetCompletionCondition(function(self)
        self.hasMouseLooked = self.hasMouseLooked or IsMouselooking()
        if self.hasMouseLooked then
            self.counter = (self.counter or 0) + 1
            -- 2 seconds after looking around since this is checked every 0.1s
            return self.counter > 10
        end
        
        return false
    end)

    step1:RegisterCallback("StepStarted", function()
        print("look around")
        -- show some frame instructing to look around
    end)

    step1:RegisterCallback("StepFinished", function()
        print("you looked around")
        -- finish showing frame
    end)

    local step2 = moveTutorial:AddStep()
    step2:SetCompletionCondition(function(self)
        if self.hasMoved then
            self.counter = (self.counter or 0) + 1
            -- 2 seconds after moving  around since this is checked every 0.1s
            return self.counter > 10
        end
        if not self.position then
            self.position = { GetCurrentPlayerPosition() }
        elseif self.position then
            local x, y, z = GetCurrentPlayerPosition()
            if x ~= self.position[1] or y ~= self.position[2] or z ~= self.position[3] then
                self.hasMoved = true
            end
        end
        
        return false
    end)

    step2:RegisterCallback("StepStarted", function()
        print("move around")
        -- show some frame instructing to move around
    end)

    step2:RegisterCallback("StepFinished", function()
        print("you moved")
        -- finish showing frame
    end)

    NPE:AddTutorial(moveTutorial)
end

local Addon = select(2, ...)
local TutorialSystem = {}
TutorialSystem.Tutorials = {}
Addon.TutorialSystem = TutorialSystem

TutorialSystem.Debug = false

function TutorialSystem:AddTutorial(name, play, stop)
    self.Tutorials[name] = {
        state = 0,
        playFunction = play,
        stopFunction = stop,
    }
end

function TutorialSystem:HasActiveTutorial()
	for _, tutorial in pairs(TutorialSystem.Tutorials) do
		if (tutorial.state == 1) then
			return true
		end
	end

	return false
end

function TutorialSystem:PlayTutorial(tutorial)
    if (self.Debug) then
        print("[TutorialSystem] HandleTutorial:", tutorial)
    end

    if not self.Tutorials[tutorial] then return end

	if (self:HasActiveTutorial()) then
		self.Tutorials[tutorial].state = 2

        if (self.Debug) then
            print("[TutorialSystem] Queued:", tutorial)
        end
	else
		self.Tutorials[tutorial].state = 1
		self.Tutorials[tutorial].playFunction()

        if (self.Debug) then
            print("[TutorialSystem] Play:", tutorial)
        end
	end
end

function TutorialSystem:PlayNextTutorial()
    if (self.Debug) then
        print("control")
    end

	for tut, data in pairs(self.Tutorials) do
		if (data.state == 2) then
			self:PlayTutorial(tut)
			return
		end
	end

    if (self.Debug) then
        print("[TutorialSystem] Finished Tutorial Queue")
    end
end

function TutorialSystem:FinishTutorial(tutorial)
    if not self.Tutorials[tutorial] then
        print("[TutorialSystem] Tried to finish tutorial but could not find an entry for", tutorial)
        return
    end
	self.Tutorials[tutorial].stopFunction()
	self.Tutorials[tutorial].state = 0

    if (self.Debug) then
        print("[TutorialSystem] Finished", tutorial)
    end

	self:PlayNextTutorial()
end
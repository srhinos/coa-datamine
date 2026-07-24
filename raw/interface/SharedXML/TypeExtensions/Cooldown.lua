if not GetCooldownMetatable then return end

local Cooldown = GetCooldownMetatable().__index

Cooldown.InternalSetCooldown = Cooldown.SetCooldown

local cooldownOnUpdate = function(self, elapsed)
    if self.paused and self.duration > 0 then
        self.start = self.start + elapsed
        self:InternalSetCooldown(self.start, self.duration)
    end
end

function Cooldown:Pause()
    if not self._pauseHooked then
        self._pauseHooked = true
        self:HookScript("OnUpdate", cooldownOnUpdate)
    end

    self.paused = true
end

function Cooldown:Resume()
    self.paused = nil
end 

function Cooldown:IsPaused()
    return self.paused
end 

function Cooldown:SetCooldown(start, duration)
    self.start = start
    self.duration = duration
    self:InternalSetCooldown(start, duration)
end

function Cooldown:Clear()
    self:SetCooldown(0, 0)
    self:Hide()
end

function Cooldown:GetCooldownDuration()
    return self.duration and self.duration * 1000
end

-- modRate isnt real so these are the same thing
Cooldown.GetCooldownDisplayDuration = Cooldown.GetCooldownDuration

function Cooldown:GetCooldownTimes()
    return self.start, self.duration and self.duration * 1000
end 

function Cooldown:SetDuration(duration)
    self:SetCooldown(GetTime(), duration)
end
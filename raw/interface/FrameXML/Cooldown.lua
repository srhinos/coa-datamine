function CooldownFrame_SetTimer(self, start, duration, enable)
    if enable == nil or type(enable) == "boolean" then
        enable = enable and 1 or 0;
    end
    if ( start > 0 and duration > 0 and enable > 0) then
        self:SetCooldown(start, duration);
    else
        self:Clear()
    end
end

function CooldownFrame_Set(self, start, duration, enable, forceShowDrawEdge)
    if enable == nil or type(enable) == "boolean" then
        enable = enable and 1 or 0;
    end
    if enable and enable ~= 0 and start > 0 and duration > 0 then
        self:SetDrawEdge(forceShowDrawEdge);
        self:SetCooldown(start, duration);
    else
        CooldownFrame_Clear(self);
    end
end

function CooldownFrame_SetDisplayAsPercentage(self, percentage)
    local seconds = 100;	-- any number, really
    self:Pause();
    self:SetCooldown(GetTime() - (seconds * Saturate(percentage)), seconds);
end

function CooldownFrame_Clear(self)
    self:Clear()
end
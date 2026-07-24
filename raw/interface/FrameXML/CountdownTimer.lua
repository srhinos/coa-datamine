CountdownTimerMixin = {}

TIMER_NUMBERS_SETS = {}
TIMER_NUMBERS_SETS["MythicPlus"] = { texture          = "Interface\\Timer\\BigTimerNumbers",
                                     w                = 256,
                                     h                = 170,
                                     texW             = 1024,
                                     texH             = 512,
                                     columns          = 4,
                                     texCoW           = 0.25,
                                     texCoH           = 0.33203125,
                                     numberHalfWidths = {
	                                     --0,       1,        2,         3,    4,       5,    6,         7,         8,         9,
	                                     0.2734375, 0.109375, 0.2578125, 0.25, 0.28125, 0.25, 0.2578125, 0.2265625, 0.2421875, 0.2421875,
                                     },
                                     soundThreshold   = 10,
                                     soundkitTick     = SOUNDKIT.UI_BATTLEGROUNDCOUNTDOWN_TIMER_90,
                                     soundkitFinish   = SOUNDKIT.UI_BATTLEGROUNDCOUNTDOWN_END,
                                     finishLogo       = "challenges",
}

TIMER_NUMBERS_SETS["Horde"] = table.Copy(TIMER_NUMBERS_SETS["MythicPlus"])
TIMER_NUMBERS_SETS["Horde"].finishLogo = "horde"

TIMER_NUMBERS_SETS["Alliance"] = table.Copy(TIMER_NUMBERS_SETS["MythicPlus"])
TIMER_NUMBERS_SETS["Alliance"].finishLogo = "alliance"

function CountdownTimerMixin:OnLoad()
	self:RegisterEvent("BATTLEGROUND_COUNTDOWN_STARTED")
	self:RegisterEvent("BATTLEGROUND_STARTED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function CountdownTimerMixin:StartTimer(seconds, style)
	self.endTime = GetTime() + seconds
	self.style = TIMER_NUMBERS_SETS[style or "MythicPlus"]
	self.Digit1:SetTexture(self.style.texture)
	self.Digit1:SetSize(self.style.w, self.style.h)
	self.Digit1Glow:SetTexture(self.style.texture .. "Glow")

	self.Digit2:SetTexture(self.style.texture)
	self.Digit2:SetSize(self.style.w, self.style.h)
	self.Digit2Glow:SetTexture(self.style.texture .. "Glow")

	self.timeDisplay = 0
	self:Show()
	self.ProgressBar:SetMinMaxValues(0, seconds)
	self:SetScript("OnUpdate", self.OnUpdate)
end

function CountdownTimerMixin:StopTimer()
	self:SetScript("OnUpdate", nil)
	self.timeDisplay = nil
	self.endTime = nil
	self.style = nil
	self:Hide()
end

function CountdownTimerMixin:StopAnimating()
	self.Digit1.Anim:Stop()
	self.Digit1Glow.Anim:Stop()
	self.Digit2.Anim:Stop()
	self.Digit2Glow.Anim:Stop()
end

function CountdownTimerMixin:FinishTimer()
	if self.style.soundkitFinish then
		PlaySound(self.style.soundkitFinish)
	end

	if self.style.finishLogo then
		self:StopAnimating()
		self.Digit2:Show()
		self.Digit2Glow:Show()
		self:SetScript("OnUpdate", nil)
		self.Digit2:SetTexture("Interface\\Timer\\"..self.style.finishLogo.."-Logo")
		self.Digit2:SetTexCoord(0, 1, 0, 1)
		self.Digit2:SetSize(256, 256)
		self.Digit2Glow:SetTexture("Interface\\Timer\\"..self.style.finishLogo.."Glow-Logo")
		self.Digit2Glow:SetTexCoord(0, 1, 0, 1)
		self.Digit2.LogoAnim:Play()
		self.Digit2Glow.Anim:Play()
	else
		self:StopTimer()
	end
end

function CountdownTimerMixin:OnUpdate()
	self.timeLeft = self.endTime - GetTime()

	if self.timeLeft <= 0 then
		self:FinishTimer()
		return
	end

	local seconds = ceil(self.timeLeft)
	if self.timeLeft > 10 then
		self:StopAnimating()
		self.Digit1:Hide()
		self.Digit1Glow:Hide()
		self.Digit2:Hide()
		self.Digit2Glow:Hide()
		self:SetProgressTimer(self.timeLeft)
	elseif self.timeDisplay ~= seconds then
		self.timeDisplay = seconds
		self.ProgressBar.FadeIn:Stop()
		self.ProgressBar:Hide()
		self:SetDigits(self.timeDisplay)
	end
end

function CountdownTimerMixin:SetDigits(seconds)
	self:StopAnimating()
	local tens = floor(seconds / 10)
	local ones = seconds % 10

	local l, r, t, b
	local offset = 0
	local hw = 0
	local doubleDigit = tens > 0

	-- Tens digit
	if doubleDigit then
		hw = self.style.numberHalfWidths[tens + 1] * self.style.w
		offset = offset + hw
		l = (tens % self.style.columns) * self.style.texCoW
		r = l + self.style.texCoW
		t = floor(tens / self.style.columns) * self.style.texCoH
		b = t + self.style.texCoH

		self.Digit1:SetTexCoord(l, r, t, b)
		self.Digit1Glow:SetTexCoord(l, r, t, b)
		self.Digit1:Show()
		self.Digit1Glow:Show()
		self.Digit1.Anim:Play()
		self.Digit1Glow.Anim:Play()
	else
		self.Digit1:Hide()
		self.Digit1Glow:Hide()
	end

	-- Ones digit
	hw = (hw + (self.style.numberHalfWidths[ones + 1] * self.style.w)) / 2
	offset = offset + hw
	l = (ones % self.style.columns) * self.style.texCoW
	r = l + self.style.texCoW
	t = floor(ones / self.style.columns) * self.style.texCoH
	b = t + self.style.texCoH

	if doubleDigit then
		self.Digit1:ClearAndSetPoint("CENTER", -hw, 0)
		self.Digit2:ClearAndSetPoint("CENTER", hw, 0)
	else
		self.Digit2:ClearAndSetPoint("CENTER", 0, 0)
	end
	self.Digit2:SetTexCoord(l, r, t, b)
	self.Digit2Glow:SetTexCoord(l, r, t, b)
	self.Digit2:Show()
	self.Digit2Glow:Show()
	self.Digit2.Anim:Play()
	self.Digit2Glow.Anim:Play()

	if self.style.soundkitTick then
		if not self.style.soundThreshold or seconds <= self.style.soundThreshold then
			PlaySound(self.style.soundkitTick)
		end
	end
end

function CountdownTimerMixin:SetProgressTimer(timeLeft)
	local minutes, seconds = floor(timeLeft/60), timeLeft % 60
	self.ProgressBar:SetValue(timeLeft)
	self.ProgressBar.Text:SetText(string.format("%d:%02d", minutes, seconds));
	

	if not self.ProgressBar:IsShown() then
		self.ProgressBar.FadeIn:Play()
	end
end 

function CountdownTimerMixin:BATTLEGROUND_COUNTDOWN_STARTED(seconds)
	self:StartTimer(seconds / 1000, C_PVP:GetBattlegroundFaction())
end

function CountdownTimerMixin:BATTLEGROUND_STARTED()
	if not self.timeLeft or self.timeLeft > 0 then
		self:StartTimer(0, C_PVP:GetBattlegroundFaction())
	end
end 

function CountdownTimerMixin:PLAYER_ENTERING_WORLD()
	self:StopTimer()
end 
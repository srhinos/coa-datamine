local AddonName, Addon = ...
Addon.Name = AddonName

Addon.AwTexPath = "Interface\\AddOns\\AwAddons\\Textures\\"
Addon.FramesToFade = {}

function Addon:BaseFrameFade(frame, dir)
	if not frame then return end

	frame.FadeTimer = 0
	frame.TimeToFade = frame.time or 0.5
	frame.FadeMode = dir
	tinsert(self.FramesToFade, frame)
end

function Addon:BaseFrameFadeIn(frame)
	frame.ForceLeaveFade = false
	self:BaseFrameFade(frame, "IN")
	frame:Show()
end

function Addon:BaseFrameFadeOut(frame)
	frame.ForceLeaveFade = false
	self:BaseFrameFade(frame, "OUT")
end

local fader = CreateFrame("Frame")
fader:SetScript("OnUpdate", function(self, dt)
	for i, frame in ipairs(Addon.FramesToFade) do
		frame.FadeTimer = frame.FadeTimer + dt
		if frame.FadeTimer < frame.TimeToFade and not frame.ForceLeaveFade then
			if frame.FadeMode == "IN" then
				frame:SetAlpha(frame.FadeTimer / frame.TimeToFade)
			elseif frame.FadeMode == "OUT" then
				frame:SetAlpha((frame.TimeToFade - frame.FadeTimer) / frame.TimeToFade)
			end
		elseif frame.ForceLeaveFade then
			frame.ForceLeaveFade = false
			tremove(Addon.FramesToFade, i)
		else
			if frame.FadeMode == "IN" then
				frame:SetAlpha(1)
			elseif frame.FadeMode == "OUT" then
				frame:SetAlpha(0)
				frame:Hide()
			end
			tremove(Addon.FramesToFade, i)
		end
	end
end)

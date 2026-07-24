local AddonName, Addon = ...
Addon.Name = AddonName
AscensionUI = Addon

AscensionUI.Libs = {
	Deflate = LibStub:GetLibrary("LibDeflate")
}

LibStub("AceSerializer-3.0"):Embed(AscensionUI)
--
-- Settings
--
Addon.AwTexPath = "Interface\\AddOns\\AwAddons\\Textures\\"
Addon.TexPath = "Interface\\AddOns\\AscensionUI\\Textures\\"

--
-- Event Functions
--
function AscensionUI:ADDON_LOADED(addon)
	if addon ~= self.Name then return end
	if not AscensionUI_DB then AscensionUI_DB = {} end
	if not AscensionUI_CDB then AscensionUI_CDB = {} end

	AscensionUI.DB = AscensionUI_DB
	AscensionUI.CDB = AscensionUI_CDB

	C_Hook:SendEvent("ASCENSIONUI_LOADED")
end

C_Hook:Register(AscensionUI, "ADDON_LOADED")
--
-- Ascension UI Functions
--

-- Frame Fading
Addon.FramesToFade = {}
function Addon:BaseFrameFade(frame, dir)
	if not frame then return end

	frame.FadeTimer = 0
	if frame.time then
		frame.TimeToFade = frame.time
	else
		frame.TimeToFade = 0.5
	end

	frame.FadeMode = dir
	tinsert(Addon.FramesToFade, frame)
end

function Addon:BaseFrameFadeIn(frame)
	frame.ForceLeaveFade = false
	self:BaseFrameFade(frame, "IN")
	frame:Show()
end

-- Define Globally for AIO stuff
BaseFrameFadeIn = function(...)
	Addon:BaseFrameFadeIn(...)
end

function Addon:BaseFrameFadeOut(frame)
	frame.ForceLeaveFade = false
	self:BaseFrameFade(frame, "OUT")
end

-- Define Globally for AIO Stuff
BaseFrameFadeOut = function(...)
	Addon:BaseFrameFadeOut(...)
end

local fader = CreateFrame("Frame")
fader:SetScript("OnUpdate", function(self, dt)
	for i, frame in ipairs(Addon.FramesToFade) do
		frame.FadeTimer = frame.FadeTimer + dt
		if frame.FadeTimer < frame.TimeToFade and not(frame.ForceLeaveFade) then
			if frame.FadeMode == "IN" then
				frame:SetAlpha(frame.FadeTimer / frame.TimeToFade)
			elseif frame.FadeMode == "OUT" then
				frame:SetAlpha((frame.TimeToFade - frame.FadeTimer) / frame.TimeToFade)
			end
		elseif (frame.ForceLeaveFade) then
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
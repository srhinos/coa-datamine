local sizeScale = 0.8
local longSide = 256 * sizeScale
local shortSide = 128 * sizeScale

CoASpellActivationOverlayMixin = {}

local specialLocations = {
	["LEFT(FLIPPED)"] = {
		LEFT = { hFlip = true },
	},
	["RIGHT(FLIPPED)"] = {
		RIGHT = {	hFlip = true },
	},
	["TOP(FLIPPED)"] = {
		TOP = { vFlip = true },
	},
	["BOTTOM(FLIPPED)"] = {
		BOTTOM = { vFlip = true },
	},
}

CoASpellActivationOverlayMixin.clockwiseLocations = {
	"LEFT",
	"TOP",
	"RIGHT",
}

local function ResetOverlay(pool, frame)
	local parent = frame:GetParent()
	if frame.spellID and frame.position then
		if parent.ActiveOverlays[frame.spellID] then
			parent.ActiveOverlays[frame.spellID][frame.position] = nil
		end
	end

	frame.Pulse:Stop()
	frame:ClearAllPoints()
	frame.spellID = nil
	frame.position = nil
	frame:Hide()
end

function CoASpellActivationOverlayMixin:OnLoad()
	self.ActiveOverlays = {}
	self.Overlays = CreateFramePool("Frame", self, "CoASpellActivationOverlayTemplate", ResetOverlay)

	if not IsCustomClass() then return end

	self:Initialize()
end

function CoASpellActivationOverlayMixin:Initialize()
	if C_CVar.GetBool("SpellActivationOverlayEnabled") then
		self.listening = true
		self:RegisterEvent("SPELL_ACTIVATION_SHOW")
		self:RegisterEvent("SPELL_ACTIVATION_HIDE")
		self:Show()
	else
		self.listening = false
		self:Hide()
	end

	self:RegisterEvent("CVAR_UPDATE")

	self:SetAlpha(tonumber(C_CVar.Get("SpellActivationOverlayAlpha")) or 1)
end

function CoASpellActivationOverlayMixin:CVAR_UPDATE(cvar)
	if cvar == "ENABLE_SPELL_ACTIVATION_OVERLAY" then
		local enabled = toboolean(C_CVar.Get("SpellActivationOverlayEnabled"))

		if enabled and not self.listening then
			self.listening = true
			self:RegisterEvent("SPELL_ACTIVATION_SHOW")
			self:RegisterEvent("SPELL_ACTIVATION_HIDE")
			self:Show()
		elseif not enabled and self.listening then
			self.listening = false
			self:UnregisterEvent("SPELL_ACTIVATION_SHOW")
			self:UnregisterEvent("SPELL_ACTIVATION_HIDE")
			self:HideAllOverlays()
			self:Hide()
		end
	elseif cvar == "SPELL_ACTIVATION_OVERLAY" then
		local val = C_CVar.Get("SpellActivationOverlayAlpha")
		self:SetAlpha(tonumber(val) or 1)
	end

end

function CoASpellActivationOverlayMixin:SPELL_ACTIVATION_SHOW(spellID, texture, position, scale, r, g, b)
	local vFlip, hFlip
	local specialLocation = specialLocations[position]
	if specialLocation then
		local location, info = next(specialLocation)
		vFlip = info.vFlip
		hFlip = info.hFlip
		position = location
	end
	
	self:ShowOverlay(spellID, texture, position, scale, r, g, b, vFlip, hFlip)
end

function CoASpellActivationOverlayMixin:SPELL_ACTIVATION_HIDE(spellID, position)
	self:HideOverlay(spellID, position)
end

function CoASpellActivationOverlayMixin:ShowOverlay(spellID, texture, position, scale, r, g, b, vFlip, hFlip)
	local overlay = self:GetOverlay(spellID, position)
	
	overlay:ClearAllPoints()
	
	local left, right, top, bottom = 0, 1, 0, 1

	if vFlip then
		top, bottom = bottom, top
	end

	if hFlip then
		left, right = right, left
	end
	
	overlay.Texture:SetTexCoord(left, right, top, bottom)
	
	local width, height
	if position == "CENTER" then
		width, height = longSide, longSide
		overlay:SetPoint("CENTER", self, "CENTER", 0, 0)
	elseif position == "LEFT" then
		width, height = shortSide, longSide
		overlay:SetPoint("RIGHT", self, "LEFT", 0, 0)
	elseif position == "RIGHT" then
		width, height = shortSide, longSide
		overlay:SetPoint("LEFT", self, "RIGHT", 0, 0)
	elseif position == "TOP" then
		width, height = longSide, shortSide
		overlay:SetPoint("BOTTOM", self, "TOP")
	elseif position == "BOTTOM" then
		width, height = longSide, shortSide
		overlay:SetPoint("TOP", self, "BOTTOM")
	elseif position == "TOPRIGHT" then
		width, height = shortSide, shortSide
		overlay:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0)
	elseif position == "TOPLEFT" then
		width, height = shortSide, shortSide
		overlay:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 0, 0)
	elseif position == "BOTTOMRIGHT" then
		width, height = shortSide, shortSide
		overlay:SetPoint("TOPLEFT", self, "BOTTOMRIGHT", 0, 0)
	elseif position == "BOTTOMLEFT" then
		width, height = shortSide, shortSide
		overlay:SetPoint("TOPRIGHT", self, "BOTTOMLEFT", 0, 0)
	else
		return
	end
	
	overlay:SetSize(width * scale, height * scale)
	
	overlay.Texture:SetTexture(texture)
	if r > 1 or g > 1 or b > 1 then
		r = r / 255
		g = g / 255
		b = b / 255
	end
	overlay.Texture:SetVertexColor(r, g, b)
	
	PlaySound(SOUNDKIT.UI_PETBATTLE_CAMERAROTATE)
	overlay:FrameFadeIn(0.1)
	overlay.Pulse:Play()
end

function CoASpellActivationOverlayMixin:HideOverlay(spellID, position)
	if not position then
		local overlays = self.ActiveOverlays[spellID]
		if overlays then
			for _, overlay in pairs(overlays) do
				overlay.Pulse:Pause()
				overlay:FrameFadeOut(0.1)
			end
		end
	else
		local overlay = self.ActiveOverlays[spellID] and self.ActiveOverlays[spellID][position]
		if overlay then
			overlay.Pulse:Stop()
			overlay:FrameFadeOut(0.1)
		end
	end
end

function CoASpellActivationOverlayMixin:HideAllOverlays()
	for spellID in pairs(self.ActiveOverlays) do
		self:HideOverlay(spellID)
	end
end

function CoASpellActivationOverlayMixin:GetOverlay(spellID, position)
	local overlay = self.ActiveOverlays[spellID] and self.ActiveOverlays[spellID][position]

	if overlay then
		return overlay
	end
	
	overlay = self.Overlays:Acquire()
	overlay.spellID = spellID
	overlay.position = position

	if not self.ActiveOverlays[spellID] then
		self.ActiveOverlays[spellID] = {}
	end

	self.ActiveOverlays[spellID][position] = overlay
	
	return overlay
end

function CoASpellActivationOverlayMixin:GetTotalShownLocations(spellID)
	local totalVisible = 0

	if not self.ActiveOverlays[spellID] then
		return totalVisible
	end

	for _, overlay in pairs(self.ActiveOverlays[spellID]) do
		totalVisible = totalVisible + 1
	end

	return totalVisible
end

function CoASpellActivationOverlayMixin:GetNextFreeClockwisePosition()
	for i = 1, #self.clockwiseLocations do
		local location = self.clockwiseLocations[i]

		local isBusy = false

		for spellID, overlays in pairs(self.ActiveOverlays) do
			for locationBusy, overlay in pairs(overlays) do
				if locationBusy == location then
					isBusy = true
					break
				end
			end

			if isBusy then
				break
			end
		end

		if not isBusy then
			return location
		end
	end
end

function CoASpellActivationOverlayMixin:HideNextCounterClockwise(spellID, totalToHide)
	if not self.ActiveOverlays[spellID] then
		return
	end

	local hidden = 0

	for i = #self.clockwiseLocations, 1, -1 do
		local location = self.clockwiseLocations[i]

		if self.ActiveOverlays[spellID][location] then
			self:HideOverlay(spellID, location)
			hidden = hidden + 1
		end

		if hidden >= totalToHide then
			break
		end
	end
end

--
-- Spell Overlay Mixin
--
CoASpellOverlayMixin = {}

function CoASpellOverlayMixin:FrameFadeOut(duration)
    if not self:IsVisible() then
        self:Show()
    end

    local fadeInfo = {}
    fadeInfo.mode = "OUT"
    fadeInfo.timeToFade = duration or 0.5
    fadeInfo.startAlpha = self:GetAlpha() or 1
    fadeInfo.endAlpha = 0
    fadeInfo.finishedFunc = GenerateClosure(CoASpellOverlayMixin.OnFadeOutFinished, self)

    UIFrameFade(self, fadeInfo)
end

function CoASpellOverlayMixin:OnFadeOutFinished()
	self:GetParent().Overlays:Release(self)
end 
local sizeScale = 0.8
local longSide = 256 * sizeScale
local shortSide = 128 * sizeScale

SpellActivationOverlayMixin = {}
SpellActivationOverlayMixin.OnEvent = OnEventToMethod

function SpellActivationOverlayMixin:OnLoad()
	self.overlaysInUse = {}
	self.overlayPool = CreateFramePool("FRAME", self, "SpellActivationOverlayTemplate")

	self:RegisterEvent("SHOW_SPELL_ACTIVATION_OVERLAY")
	self:RegisterEvent("HIDE_SPELL_ACTIVATION_OVERLAY")
	self:RegisterEvent("HIDE_ALL_SPELL_ACTIVATION_OVERLAYS")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("CVAR_UPDATE")

	self:SetSize(longSide, longSide)
	
	self:VARIABLES_LOADED()
end

function SpellActivationOverlayMixin:SHOW_SPELL_ACTIVATION_OVERLAY(overlayID)
	if SPELL_ACTIVATION_OVERLAY_ENABLED == "1" then
		if self.alpha > 0.01 then
			self:ShowAllOverlays(overlayID)
		end
	end
end

function SpellActivationOverlayMixin:HIDE_SPELL_ACTIVATION_OVERLAY(overlayID)
	if overlayID then
		self:HideOverlays(overlayID)
	end
end

function SpellActivationOverlayMixin:HIDE_ALL_SPELL_ACTIVATION_OVERLAYS()
	self:HideOverlays()
end

function SpellActivationOverlayMixin:VARIABLES_LOADED()
	self.alpha = C_CVar.GetNumber("SpellActivationOverlayAlpha")
end

function SpellActivationOverlayMixin:CVAR_UPDATE(cvar, value)
	if cvar == "SPELL_ACTIVATION_OVERLAY" then
		self.alpha = tonumber(value) or 1
	elseif cvar == "ENABLE_SPELL_ACTIVATION_OVERLAY" then
		if value == "1" then
			self:Show()
		else
			self:Hide()
			self:HideOverlays()
		end
	end
end

local complexLocationTypes = {
	[Enum.ScreenLocationType.LeftRight] = {
		Enum.ScreenLocationType.Left,
		Enum.ScreenLocationType.Right,
	},
	[Enum.ScreenLocationType.TopBottom] = {
		Enum.ScreenLocationType.Top,
		Enum.ScreenLocationType.Bottom,
	},
	[Enum.ScreenLocationType.LeftRightOutside] = {
		Enum.ScreenLocationType.LeftOutside,
		Enum.ScreenLocationType.RightOutside,
	},
}

function SpellActivationOverlayMixin:ShowAllOverlays(overlayID)
	local spellID, texturePath, locationType, scale, r, g, b, soundID = C_SpellActivationOverlay.GetSpellActivationOverlayInfo(overlayID)
	local locations = complexLocationTypes[locationType]
	if locations then
		for _, location in ipairs(locations) do
			self:ShowOverlay(spellID, texturePath, location, scale, r, g, b, soundID)
		end
	else
		self:ShowOverlay(spellID, texturePath, locationType, scale, r, g, b, soundID)
	end
end

local hFlippedPositions = {
	[Enum.ScreenLocationType.Right] = true,
	[Enum.ScreenLocationType.RightOutside] = true,
}

local vFlippedPositions = {
	[Enum.ScreenLocationType.Bottom] = true,
}

function SpellActivationOverlayMixin:ShowOverlay(spellID, texturePath, position, scale, r, g, b, soundID)
	local overlay = self:GetOverlay(spellID, position)
	overlay.spellID = spellID
	overlay.position = position

	overlay:ClearAllPoints()

	local texLeft, texRight, texTop, texBottom = 0, 1, 0, 1
	if vFlippedPositions[position] then
		texTop, texBottom = 1, 0
	end
	if hFlippedPositions[position] then
		texLeft, texRight = 1, 0
	end
	overlay.Texture:SetTexCoord(texLeft, texRight, texTop, texBottom)

	local width, height
	
	if position == Enum.ScreenLocationType.Center then
		width, height = longSide, longSide
		overlay:SetPoint("CENTER", self, "CENTER", 0, 0)
	elseif position == Enum.ScreenLocationType.Left then
		width, height = shortSide, longSide
		overlay:SetPoint("RIGHT", self, "LEFT", 0, 0)
	elseif position == Enum.ScreenLocationType.LeftOutside then
		width, height = shortSide, longSide
		overlay:SetPoint("RIGHT", self, "LEFT", -shortSide, 0)
	elseif position == Enum.ScreenLocationType.Right then
		width, height = shortSide, longSide
		overlay:SetPoint("LEFT", self, "RIGHT", 0, 0)
	elseif position == Enum.ScreenLocationType.RightOutside then
		width, height = shortSide, longSide
		overlay:SetPoint("LEFT", self, "RIGHT", shortSide, 0)
	elseif position == Enum.ScreenLocationType.Top then
		width, height = longSide, shortSide
		overlay:SetPoint("BOTTOM", self, "TOP")
	elseif position == Enum.ScreenLocationType.Bottom then
		width, height = longSide, shortSide
		overlay:SetPoint("TOP", self, "BOTTOM")
	elseif position == Enum.ScreenLocationType.TopRight then
		width, height = shortSide, shortSide
		overlay:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0)
	elseif position == Enum.ScreenLocationType.TopLeft then
		width, height = shortSide, shortSide
		overlay:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 0, 0)
	else
		return
	end

	overlay:SetSize(width * scale, height * scale)

	overlay.Texture:SetTexture(texturePath)
	overlay.Texture:SetVertexColor(r, g, b)

	overlay.AnimOut:Stop()--In case we're in the process of animating this out.
	overlay.AnimIn:Stop()
	overlay.Pulse:Stop()
	if soundID then
		PlaySound(soundID)
	end
	overlay:SetAlpha(self.alpha)
	overlay.AnimIn.Alpha:SetChange(self.alpha)
	overlay:Show()
end

function SpellActivationOverlayMixin:GetOverlay(spellID, position)
	if not self.overlaysInUse[spellID] then
		self.overlaysInUse[spellID] = {}
	end

	local overlayList = self.overlaysInUse[spellID]
	local overlay = overlayList[position]

	if not overlay then
		overlay = self.overlayPool:Acquire()
		overlayList[position] = overlay
	end

	return overlay
end

function SpellActivationOverlayMixin:HideOverlays(overlayID)
	local spellID = C_SpellActivationOverlay.GetSpellActivationOverlayInfo(overlayID)
	local overlayList = self.overlaysInUse[spellID]
	if overlayList then
		for _, overlay in pairs(overlayList) do
			overlay.Pulse:Pause()
			overlay.AnimOut:Play()
		end
	end
end

function SpellActivationOverlayMixin:HideAllOverlays()
	for spellID, _ in pairs(self.overlaysInUse) do
		self:HideOverlays(spellID)
	end
end

function SpellActivationOverlayMixin:ReleaseOverlay(overlay)
	self.overlaysInUse[overlay.spellID][overlay.position] = nil
	self.overlayPool:Release(overlay)
end

SpellActivationOverlayTextureMixin = {}

function SpellActivationOverlayTextureMixin:OnShow()
	self.AnimIn:Play()
end
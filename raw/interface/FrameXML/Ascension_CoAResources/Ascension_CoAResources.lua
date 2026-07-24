COA_RESOURCE_CUSTOMIZE_HELPER = COA_RESOURCE_CUSTOMIZE_HELPER or "Right click to customize menu\nDrag to move"

-- Per-character-realm, per-frame saved positions for the draggable CoA resource
-- displays (Orb, SegmentBar, Bar). Keyed by "Name-Realm" then by frame name.
COA_RESOURCE_POSITIONS = COA_RESOURCE_POSITIONS or {}
RegisterForSave("COA_RESOURCE_POSITIONS")

local SegmentTemplates = {
	TinkerScrap     = { -- TODO: cut out from here
		SingleBG   = "ScrapBG",
		Background = "ScrapFill10",
		Fill       = "ScrapFill10",
		ElementSize = 7,
	},
	FleshOrbs    = {
		Background = "KoXBarSegmentBg",
		Fill       = "KoXBarSegmentFill",
		ThreeSliceBG = {Left = "KoXBarBGLeft", Middle = "KoXBarBGMiddle", Right = "KoXBarBGRight"},
		ElementSize = 22,
	},
	SpiritCrystals = {
		SingleBG   = "RuneMasterRunesBG",
		ElementSize = 21,
		Background = "RuneMasterRune",
		Fill       = "RuneMasterRuneFill",
	},
	DoomVoid       = {
		SingleBG   = "CultistRuneBG",
		Background = "CultistRuneSegmentBG",
		Fill       = "CultistRuneSegmentFill",
		ElementSize = 19,
	},
	ReaperSoul     = {
		SingleBG   = "ReaperBG",
		Background = "ReaperSoulBG",
		Fill       = "ReaperSoulFull",
		ElementSize = 36,
	},
	RangerCombo    = {
		Background = "RangerBarSegmentBg",
		Fill       = "RangerBarSegmentFill",
		ThreeSliceBG = {Left = "RangerBarBGLeft", Middle = "RangerBarBGMiddle", Right = "RangerBarBGRight"},
		ElementSize = 13,
	},
	PyroEmber     = {
		SingleBG   = "PyroEmberBG",
		Background = "PyroEmber",
		Fill       = "PyroEmberGlow",
		ElementSize = 18,
	},
	Venomancer     = {
		SingleBG   = "VenomancerBG",
		Background = "VenomancerEmpty",
		Fill       = "VenomancerFilled",
		ElementSize = 16,
	},
	DHCharges	   = {
		Background = "DemonHunterSegmentBg",
		Fill       = "DemonHunterSegmentFill",
		SingleBG   = "DemonHunterBarBg",
		ElementSize = 16,
	},
}

local BarTemplates = {
	Insanity = {
		Border = "Interface\\UNITPOWERBARALT\\Onyxia_Horizontal_Frame",
		Color = CreateColor(0.6, 0.1, 0.8),
		Background = CreateColor(0.1, 0, 0.2),
		Text = "Insanity %d%%",
	},
	Static = {
		Border = "Interface\\UNITPOWERBARALT\\StoneDiamond_Horizontal_Frame",
		Color = CreateColor(0, 0.5, 0.7),
		Background = CreateColor(0.3, 0.3, 0.2),
		Text = "Static %d%%",
	}
}

local sizeOptions = {
	"50%",
	"75%",
	"100%",
	"125%",
	"150%",
}

--
-- CoA Resource Mixin
--
CoAResourceMixin = {}

function CoAResourceMixin.InitializeDropDown(self)
	local frame = self:GetParent()
	local info

	-- Show Text Always
	if frame.SetShowText then
		info = UIDropDownMenu_CreateInfo()

		info.text = ALWAYS_SHOW_TEXT
		info.checked = frame.AlwaysShowText
		info.func = function()
			frame:SetShowText(not frame.AlwaysShowText)
		end

		UIDropDownMenu_AddButton(info)
	end

	-- Lock / Unlock
	info = UIDropDownMenu_CreateInfo()

	info.text = frame.Locked and UNLOCK_FOCUS_FRAME or LOCK_FOCUS_FRAME
	info.checked = frame.Locked
	info.func = function()
		frame:SetLocked(not frame.Locked)
	end

	UIDropDownMenu_AddButton(info)

	-- Scale Title

	info = UIDropDownMenu_CreateInfo()

	info.text = "Scale"
	info.isTitle = true

	UIDropDownMenu_AddButton(info)

	-- Scale Options
	for i = 1, #sizeOptions do
		info = UIDropDownMenu_CreateInfo()
		info.text = sizeOptions[i]
		info.checked = frame.SizeOption == i
		info.func = function()
			frame:SetSizeOption(i)
		end
		UIDropDownMenu_AddButton(info)
	end
end

function CoAResourceMixin:OnClick(button)
	if button == "RightButton" then
		self:ShowDropDown()
	else
		HideDropDownMenu(1)
	end
end

function CoAResourceMixin:LoadCVars()
	self:SetLocked(C_CVar.GetBool(self.cvarLocked))
	self:SetSizeOption(C_CVar.GetNumber(self.cvarSize))
	if self.ON_CVARS_LOADED then
		self:ON_CVARS_LOADED()
	end
end

function CoAResourceMixin:SetLocked(locked)
	self.Locked = locked

	if locked then
		self:RegisterForDrag()
	else
		self:RegisterForDrag("LeftButton")
	end

	C_CVar.Set(self.cvarLocked, locked)
end

function CoAResourceMixin:SetSizeOption(index)
	self.SizeOption = index

	self:SetScale(0.25 + (self.SizeOption * 0.25))

	C_CVar.Set(self.cvarSize, index)
end

function CoAResourceMixin:ShowDropDown()
	HideDropDownMenu(1)
	ToggleDropDownMenu(1, nil, self.DropDown, "cursor")
end

-- Serialize the frame's first anchor into COA_RESOURCE_POSITIONS keyed by
-- "Name-Realm" / frame name. Call from OnDragStop after StopMovingOrSizing.
function CoAResourceMixin:SavePosition()
	local key = GetUnitRealmNameKey()
	local frameName = self:GetName()
	if not key or not frameName then return end

	local point, relativeTo, relativePoint, x, y = self:GetPoint(1)
	if not point then return end

	local relativeToName
	if type(relativeTo) == "table" then
		relativeToName = relativeTo:GetName() or "UIParent"
	elseif type(relativeTo) == "string" then
		relativeToName = relativeTo
	else
		relativeToName = "UIParent"
	end

	COA_RESOURCE_POSITIONS[key] = COA_RESOURCE_POSITIONS[key] or {}
	COA_RESOURCE_POSITIONS[key][frameName] = {
		point, relativeToName, relativePoint, x or 0, y or 0,
	}
end

-- Apply the saved anchor over whatever default the class lua has just set.
-- Returns true if a saved position was applied.
function CoAResourceMixin:RestorePosition()
	local key = GetUnitRealmNameKey()
	local frameName = self:GetName()
	if not key or not frameName then return false end

	local saved = COA_RESOURCE_POSITIONS[key] and COA_RESOURCE_POSITIONS[key][frameName]
	if not saved then return false end

	local point, relativeToName, relativePoint, x, y = unpack(saved)
	local relativeTo = (type(relativeToName) == "string" and _G[relativeToName]) or UIParent

	self:ClearAllPoints()
	self:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
	return true
end

--
-- CoA Resource Segment Mixin
--
CoAResourceSegmentBarMixin = {
	segments = {},
	maxValue = 1,
	value = 0,
	SizeOption = 3,
}

function CoAResourceSegmentBarMixin:OnLoad()
	self.cvarLocked = "coaResourceLocked"
	self.cvarSize = "coaResourceSize"
	Mixin(self, CoAResourceMixin)
	self:LoadCVars()
	self.pool = CreateFramePool("FRAME", self, "CoAResourceSegmentTemplate", function(framePool, frame)
		FramePool_HideAndClearAnchors(framePool, frame)
		tremoveItem(self.segments, frame)
	end)

	self:RegisterForClicks("AnyUp")

	self.DropDown.initialize = CoAResourceMixin.InitializeDropDown
	self.DropDown.displayMode = "MENU"
end

function CoAResourceSegmentBarMixin:ShowTemplate(template, value, maxValue, spellId)
	if spellId then
		self.tooltipTitle = GetSpellInfo(spellId)
	else
		self.tooltipTitle = nil
	end
	self.value = value
	self.maxValue = maxValue
	self:SetTemplate(template)
	self:RestorePosition()
	self:Show()
end

function CoAResourceSegmentBarMixin:HideTemplate(template)
	if type(template) == "table" and template.Background then
		if self.template == template then
			self.template = nil
			self:Hide()
		end
	else
		if self.template == SegmentTemplates[template] then
			self.template = nil
			self:Hide()
		end
	end
end

function CoAResourceSegmentBarMixin:SetTemplate(template)
	if not template then return end

	if type(template) == "table" and template.Background then
		self.template = template
	else
		self.template = SegmentTemplates[template]
	end

	if self.template and self.template.Background then
		self:Update()
	end
end

function CoAResourceSegmentBarMixin:SetMaxValue(value)
	self.maxValue = value
	self:Update()
end

function CoAResourceSegmentBarMixin:SetValue(value)
	self.value = value
	self:Update()
end

function CoAResourceSegmentBarMixin:Update()
	local elementSize = 30

	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
		else
			segment = self.pool:Acquire()
			tinsert(self.segments, segment)

			if i == 1 then
				segment:ClearAndSetPoint("LEFT")
			else
				segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 2, 0)
			end
		end

		segment:SetFrameLevel(self:GetFrameLevel()+self.maxValue-i+1)

		if self.template then
			if AtlasUtil:AtlasExists(self.template.Background) then
				segment.Background:ClearAllPoints()
				segment.Background:SetPoint("CENTER")
				segment.Background:SetAtlas(self.template.Background, Const.TextureKit.UseAtlasSize)
			else
				segment.Background:SetAllPoints()
				segment.Background:SetTexture(self.template.Background)
			end

			local fill = self.template.Fill

			if (type(fill) == "string") and AtlasUtil:AtlasExists(fill) then
				segment.Fill:ClearAllPoints()
				segment.Fill:SetPoint("CENTER")
				segment.Fill:SetAtlas(fill, Const.TextureKit.UseAtlasSize)
			else
				if type(fill) == "table" then
					-- 1 or less will be fill[1]
					-- anything above last index of fill will be #fill
					fill = fill[math.clamp(self.value, 1, #fill)]
				end

				segment.Fill:SetAllPoints()
				segment.Fill:SetTexture(fill)
			end

			elementSize = self.template.ElementSize or 30
			segment:SetSize(elementSize, elementSize)
		else
			segment.Background:SetTexture(0, 0, 0)
			segment.Fill:SetTexture(0, 1, 0)
		end

		segment.Fill:SetShown(i <= self.value)
		segment:Show()
	end

	while #self.segments > self.maxValue do
		self.pool:Release(self.segments[#self.segments])
	end

	-- TODO: To Mixins
	if self.template and self.template.ThreeSliceBG then
		self.BgLeft:SetAtlas(self.template.ThreeSliceBG.Left, Const.TextureKit.UseAtlasSize)
		self.BgRight:SetAtlas(self.template.ThreeSliceBG.Right, Const.TextureKit.UseAtlasSize)
		self.BgMiddle:SetAtlas(self.template.ThreeSliceBG.Middle, Const.TextureKit.UseAtlasSize)
		self.BgLeft:Show()
		self.BgRight:Show()
		self.BgMiddle:Show()
		self.Bg:Hide()
	elseif self.template and self.template.SingleBG then
		self.Bg:SetAtlas(self.template.SingleBG, Const.TextureKit.UseAtlasSize)
		self.Bg:Show()
		self.BgLeft:Hide()
		self.BgRight:Hide()
		self.BgMiddle:Hide()
	else
		self.Bg:Hide()
		self.BgLeft:Hide()
		self.BgRight:Hide()
		self.BgMiddle:Hide()
	end

	self:SetWidth(self.maxValue * elementSize)
	self:ApplyTemplateSpecificAdjustments()
end

-- TODO: To mixins
function CoAResourceSegmentBarMixin:ApplyTemplateSpecificAdjustments()
	--self:SetBackdrop(GameTooltip:GetBackdrop())
	
	if self.template == SegmentTemplates.RangerCombo then
		local elementSize = self.template.ElementSize

		self.BgLeft:ClearAndSetPoint("LEFT", 0, -3)
		self.BgRight:ClearAndSetPoint("RIGHT", 0, -3)
		
		self:SetWidth(self.maxValue*elementSize+100)

		if self.segments[1] then
			self.segments[1]:ClearAndSetPoint("LEFT", 28, 0)
			--self.segments[1]:ClearAndSetPoint("CENTER", -((elementSize/2)+1)*(self.maxValue-1), 0)
		end
	elseif self.template == SegmentTemplates.FleshOrbs then
		local elementSize = self.template.ElementSize

		self.BgLeft:ClearAndSetPoint("LEFT", 0, 0)
		self.BgRight:ClearAndSetPoint("RIGHT", 0, 0)

		self:SetWidth(self.maxValue*elementSize+100)

		if self.segments[1] then
			self.segments[1]:ClearAndSetPoint("LEFT", 68, 0)
		end

	elseif self.template == SegmentTemplates.DHCharges then
		self:SetWidth(162)
		local elementSize = self.template.ElementSize

		if (self.maxValue == 4) then
			elementSize = elementSize*2
		end

		if self.segments[1] then
			self.segments[1]:ClearAndSetPoint("CENTER", -((elementSize/2)+1)*(self.maxValue-1), 0)

			for _, segment in pairs(self.segments) do
				segment:SetSize(elementSize, elementSize)
			end
		end

	elseif self.template == SegmentTemplates.DoomVoid then
		self:SetHeight(48)
		self:SetWidth(182)

		for i = 1, self.maxValue do
			local segment

			if self.segments[i] then
				segment = self.segments[i]

				if i == 1 then
					self.segments[1]:ClearAndSetPoint("LEFT", 36, -4)
				elseif (i%2) == 0 then
					segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 2, 4)
				else
					segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 2, -4)
				end
			end
		end
	elseif self.template == SegmentTemplates.Venomancer then
		if self.segments[1] then
			local elementSize = self.template.ElementSize or 20
			self.segments[1]:ClearAndSetPoint("CENTER", -((elementSize/2)+1)*(self.maxValue-1), -8)
		end
	elseif self.template == SegmentTemplates.PyroEmber then
		local elementSize = self.template.ElementSize or 20

		for i = 1, self.maxValue do
			local segment

			if self.segments[i] then
				segment = self.segments[i]
			end

			if segment then
				if i == 1 then
					segment:ClearAndSetPoint("CENTER", -((elementSize/2)+1)*(self.maxValue-1), 4)
				elseif i <= math.ceil(self.maxValue/2) then
					segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 2, 4)
				else
					segment:ClearAndSetPoint("LEFT", self.segments[i - 1], "RIGHT", 2, -4)
				end
			end
		end
		--[[for i = 1, self.maxValue do
			local segment

			if self.segments[i] then
				segment = self.segments[i]

				if i <= self.value then
					segment.Background:SetVertexColor(1, 1, 1, 1)
				else
					segment.Background:SetVertexColor(0, 0, 0, 1)
				end

				segment.Fill:SetPoint("CENTER", 0, -4)
				segment.Fill:SetBlendMode("ADD")
			end
		end]]--
	end
end

--
-- CoA Resource Bar Mixin
CoAResourceBarMixin = {
	defaultFormat = "%d%%"
}

function CoAResourceBarMixin:OnLoad()
	self.cvarLocked = "coaResourceBarLocked"
	self.cvarSize = "coaResourceBarSize"
	self.cvarShowText = "coaResourceBarShowText"
	Mixin(self, CoAResourceMixin)
	self:LoadCVars()

	self.DropDown.initialize = CoAResourceMixin.InitializeDropDown
	self.DropDown.displayMode = "MENU"
end

function CoAResourceBarMixin:ON_CVARS_LOADED()
	self:SetShowText(C_CVar.GetBool(self.cvarShowText))
end

function CoAResourceBarMixin:ShowTemplate(template, value, maxValue)
	self:SetMinMaxValues(0, maxValue)
	self:SetValue(value)
	self:SetTemplate(template)
	self:RestorePosition()
	self:Show()
end

function CoAResourceBarMixin:SetTemplate(template)
	if not template then return end

	if type(template) == "table" and template.Border then
		self.template = template
	else
		self.template = BarTemplates[template]
	end

	if self.template and self.template.Border then
		self:Update()
	end
end

function CoAResourceBarMixin:SetShowText(show)
	self.AlwaysShowText = show
	self.Text:SetDrawLayer(show and "OVERLAY" or "HIGHLIGHT")

	C_CVar.Set(self.cvarShowText, show)
end

function CoAResourceBarMixin:Update()
	local pct = self:GetValue() / select(2, self:GetMinMaxValues())
	pct = math.clamp(pct, 0, 1) * 100

	if self.template then
		self.Border:SetTexture(self.template.Border)
		self:SetStatusBarColor(self.template.Color:GetRGBA())
		self.Text:SetText(format(self.template.Text, pct))
		if type(self.template.Background) == "string" then
			self.Background:SetTexture(self.template.Background)
		else
			self.Background:SetTexture(self.template.Background:GetRGBA())
		end
	else
		self.Border:SetTexture()
		self:SetStatusBarColor(1, 1, 1)
		self.Text:SetText(format(self.defaultFormat, pct))
		self.Background:SetTexture(0, 0, 0)
	end
end 
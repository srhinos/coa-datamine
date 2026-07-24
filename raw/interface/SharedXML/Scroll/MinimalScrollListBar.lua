
MinimalScrollListBarMixin = {
	minValue = 0,
	maxValue = 0,
	value = 0,
	valueStep = 1,
	percent = 0,
}

function MinimalScrollListBarMixin:OnLoad()
	MixinAndLoadSafe(self, CallbackRegistryMixin)
	self:GenerateCallbackEvents({ "OnValueChanged", "OnMinMaxValuesChanged", "OnOrientationChanged", "OnScrollStart", "OnScrollStop"})
	self.TrackMiddle:SetAtlas(self:GetAttribute("middleAtlas", Const.TextureKit.IgnoreAtlasSize), Const.TextureKit.UseAtlasSize)
	self.TrackBegin:SetAtlas(self:GetAttribute("beginAtlas", Const.TextureKit.IgnoreAtlasSize), Const.TextureKit.UseAtlasSize)
	self.TrackEnd:SetAtlas(self:GetAttribute("endAtlas", Const.TextureKit.IgnoreAtlasSize), Const.TextureKit.UseAtlasSize)
	self.Thumb:SetupEvents()
end

function MinimalScrollListBarMixin:GetThumbTexture()
	return self.Thumb
end

function MinimalScrollListBarMixin:GetMinMaxValues()
	return self.minValue, self.maxValue
end

function MinimalScrollListBarMixin:GetOrientation()
	return self.isHorizontal and "HORIZONTAL" or "VERTICAL"
end

function MinimalScrollListBarMixin:GetValue()
	return self.value
end

function MinimalScrollListBarMixin:GetValueStep()
	return self.valueStep
end

function MinimalScrollListBarMixin:SetMinMaxValues(minValue, maxValue)
	self.maxValue = max(0, maxValue)
	self.minValue = MClamp(minValue, 0, self.maxValue)
	self:TriggerEvent("OnMinMaxValuesChanged", self.minValue, self.maxValue)

	self:Update()
end

function MinimalScrollListBarMixin:SetOrientation(orientation)
	self.isHorizontal = orientation == "HORIZONTAL"
	self:TriggerEvent("OnOrientationChanged", self.isHorizontal and "HORIZONTAL" or "VERTICAL")
end

function MinimalScrollListBarMixin:SetValue(value)
	self.value = MClamp(value, self.minValue, self.maxValue)
	self:SetScrollPercentageInternal(MSaturate(self.value / self.maxValue))
	self:TriggerEvent("OnValueChanged", self.value)
	if HybridScrollFrame_IsPartOfHybridScroll(self) then
		HybridScrollFrame_OnValueChanged(self:GetParent(), self.value)
	elseif self:GetParent().SetVerticalScroll then
		self:GetParent():SetVerticalScroll(self.value)
	end
	self:Update()
end

function MinimalScrollListBarMixin:SetValueStep(valueStep)
	self.valueStep = MClamp(valueStep, 0, self.maxValue)
end

function MinimalScrollListBarMixin:ScrollToBegin()
	self:SetPercentage(0)
end

function MinimalScrollListBarMixin:Update()
	if self.maxValue <= 0 then
		self:SetScrollPercentageInternal(self.minValue)
	end
	
	local x, y = 0, 0
	
	local range = self:GetHeight()
	local thumbHeight = self.Thumb:GetHeight()
	
	range = range - thumbHeight
	
	local offset = math.RemapToRange(self.percent * self.maxValue, self.minValue, self.maxValue, 0, range)

	y = -offset

	if self.isHorizontal then
		x, y = y, x
	end

	self.Thumb:ClearAndSetPoint("TOP", x, y)
end

function MinimalScrollListBarMixin:SetScrollPercentageInternal(percent)
	self.percent = percent
	self.value = self.maxValue * percent
end

function MinimalScrollListBarMixin:SetPercentage(percent)
	self:SetScrollPercentageInternal(percent)
	self:TriggerEvent("OnValueChanged", self.value)
	if HybridScrollFrame_IsPartOfHybridScroll(self) then
		HybridScrollFrame_OnValueChanged(self:GetParent(), self.value)
	elseif self:GetParent().SetVerticalScroll then
	self:GetParent():SetVerticalScroll(self.value)
	end
	self:Update()
end

function MinimalScrollListBarMixin:GetStepPercent()
	return self.valueStep / self.maxValue
end

function MinimalScrollListBarMixin:GetPercentage()
	return self.percent
end

function MinimalScrollListBarMixin:DragThumb(delta)
	local offset

	if self.isHorizontal then
		offset = select(4, self.Thumb:GetPoint())
	else
		offset = select(5, self.Thumb:GetPoint())
	end
	
	offset = offset - delta
	local range = self:GetHeight()
	local thumbHeight = self.Thumb:GetHeight()

	range = range - thumbHeight
	
	local percent = MSaturate(  -offset / range)
	self:SetPercentage(percent)
end

function MinimalScrollListBarMixin:OnClick()
	local posX, posY = GetScaledCursorPosition(self)
	local isBelow

	if self.isHorizontal then
		isBelow = posX > self.Thumb:GetRight()
	else
		isBelow = posY > self.Thumb:GetBottom()
	end
	
	local distance, direction
	if isBelow then
		if self.isHorizontal then
			distance = posX - self.Thumb:GetRight()
		else
			distance = posY - self.Thumb:GetBottom()
		end
		direction = -1
	else
		if self.isHorizontal then
			distance = self.Thumb:GetLeft() - posX
		else
			distance = self.Thumb:GetTop() - posY
		end
		
		direction = 1
	end

	local range
	if self.isHorizontal then
		range = self:GetWidth()
	else
		range = self:GetHeight()
	end

	local step = range / 4 -- scroll 1/4th the page each click
	step = MClamp(step, 0, distance - (self.Thumb:GetHeight() / 2))
	self:DragThumb(step * direction)
end
--
-- Thumb Button
--
MinimalScrollListThumbMixin = CreateFromMixins(ButtonStateBehaviorMixin)

function MinimalScrollListThumbMixin:OnLoad()
	AttributesToKeyValues(self)
end

function MinimalScrollListThumbMixin:SetupEvents()
end

function MinimalScrollListThumbMixin:GetAtlas()
	if self:IsEnabled() then
		if self.down then
			return self.downMiddleTexture, self.downBeginTexture, self.downEndTexture
		elseif self.over then
			return self.overMiddleTexture, self.overBeginTexture, self.overEndTexture
		end
	end
	return self.upMiddleTexture, self.upBeginTexture, self.upEndTexture
end

function MinimalScrollListThumbMixin:UpdateAtlas()
	local midAtlas, beginAtlas, endAtlas = self:GetAtlas()

	self.Middle:SetAtlas(midAtlas, Const.TextureKit.UseAtlasSize)
	--self:OnSizeChanged(self.thumbTexture:GetSize())
	self.Begin:SetAtlas(beginAtlas, Const.TextureKit.UseAtlasSize)
	self.End:SetAtlas(endAtlas, Const.TextureKit.UseAtlasSize)

	--[[self.Begin:SetVertexColor(GREEN_FONT_COLOR:GetRGBA())
	self.End:SetVertexColor(RED_FONT_COLOR:GetRGBA())
	self.Middle:SetVertexColor(ITEM_QUALITY_COLORS[9]:GetRGBA())]]
end

function MinimalScrollListThumbMixin:OnShow()
	self:UpdateAtlas()
end

function MinimalScrollListThumbMixin:OnEnter()
	if ButtonStateBehaviorMixin.OnEnter(self) then
		self:UpdateAtlas()
	end
end

function MinimalScrollListThumbMixin:OnLeave()
	if ButtonStateBehaviorMixin.OnLeave(self) then
		self:UpdateAtlas()
	end
end

function MinimalScrollListThumbMixin:OnMouseDown()
	if ButtonStateBehaviorMixin.OnMouseDown(self) then
		self:UpdateAtlas()
	end

	self.cursorX, self.cursorY = GetScaledCursorPosition(self)
	self:SetScript("OnUpdate", self.OnUpdate)
	self:GetParent():TriggerEvent("OnScrollStart")
end

function MinimalScrollListThumbMixin:OnMouseUp()
	if ButtonStateBehaviorMixin.OnMouseUp(self) then
		self:UpdateAtlas()
	end
	
	self:SetScript("OnUpdate", nil)
	self:GetParent():TriggerEvent("OnScrollStop")
	self.cursorX, self.cursorY = nil, nil
end

function MinimalScrollListThumbMixin:OnEnable()
	self:UpdateAtlas()

	self.Middle:SetDesaturated(false)
	self.Begin:SetDesaturated(false)
	self.End:SetDesaturated(false)
end

function MinimalScrollListThumbMixin:OnDisable()
	ButtonStateBehaviorMixin.OnDisable(self)
	self:UpdateAtlas()

	self.Middle:SetDesaturated(true)
	self.Begin:SetDesaturated(true)
	self.End:SetDesaturated(true)

	self:SetScript("OnUpdate", nil)
	self.cursorX, self.cursorY = nil, nil
end

function MinimalScrollListThumbMixin:OnUpdate()
	local cursorX, cursorY = GetScaledCursorPosition(self)
	local delta
	
	if self:GetParent().isHorizontal then
		delta = self.cursorX - cursorX
	else
		delta = self.cursorY - cursorY
	end
	
	self:GetParent():DragThumb(delta)

	self.cursorX, self.cursorY = cursorX, cursorY
end

--
-- Proportional Scroll Thumb
--
ProportionalScrollListThumbMixin = CreateFromMixins(MinimalScrollListThumbMixin)

function ProportionalScrollListThumbMixin:OnShow()
	MinimalScrollListThumbMixin.OnShow(self)
	if HybridScrollFrame_IsPartOfHybridScroll(self) then
		HybridScrollFrame_SetDoNotHideScrollThumb(self:GetParent():GetParent(), true)
	end
end

function ProportionalScrollListThumbMixin:OnMinMaxValuesChanged(minValue, maxValue)
	local parentHeight = self:GetParent():GetHeight()
	local frameHeight = self:GetParent():GetParent():GetHeight()

	local percent = 1 + (maxValue / frameHeight)

	self:SetHeight(max(52, parentHeight / percent))
end

function ProportionalScrollListThumbMixin:SetupEvents()
	self:GetParent():RegisterCallback("OnMinMaxValuesChanged", self.OnMinMaxValuesChanged, self)
end

--
-- Stepper Buttons
--
MinimalScrollBarStepperScriptsMixin = CreateFromMixins(ButtonStateBehaviorMixin)

function MinimalScrollBarStepperScriptsMixin:OnLoad()
	AttributesToKeyValues(self)
	self:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
end

function MinimalScrollBarStepperScriptsMixin:GetAtlas()
	if self:IsEnabled() then
		if self.down then
			return self.downTexture
		elseif self.over then
			return self.overTexture
		end
	end
	return self.normalTexture
end

function MinimalScrollBarStepperScriptsMixin:OnShow()
	self:UpdateAtlas()
end

function MinimalScrollBarStepperScriptsMixin:UpdateAtlas()
	self.Texture:SetAtlas(self:GetAtlas(), Const.TextureKit.UseAtlasSize)
end

function MinimalScrollBarStepperScriptsMixin:OnEnter()
	if ButtonStateBehaviorMixin.OnEnter(self) then
		self:UpdateAtlas()
	end
end

function MinimalScrollBarStepperScriptsMixin:OnLeave()
	if ButtonStateBehaviorMixin.OnLeave(self) then
		self:UpdateAtlas()
	end
end

function MinimalScrollBarStepperScriptsMixin:OnMouseDown()
	if ButtonStateBehaviorMixin.OnMouseDown(self) then
		self:UpdateAtlas()
		self.Texture:SetPointOffset(1, -1)
	end
end

function MinimalScrollBarStepperScriptsMixin:OnMouseUp()
	if ButtonStateBehaviorMixin.OnMouseUp(self) then
		self:UpdateAtlas()
		self.Texture:ResetPointsOffset()
	end
end

function MinimalScrollBarStepperScriptsMixin:OnEnable()
	self:UpdateAtlas()
	self.Texture:SetDesaturated(false)
end

function MinimalScrollBarStepperScriptsMixin:OnDisable()
	ButtonStateBehaviorMixin.OnDisable(self)
	self:UpdateAtlas()

	self.Texture:SetDesaturated(true)
	self.Texture:ResetPointsOffset()
end

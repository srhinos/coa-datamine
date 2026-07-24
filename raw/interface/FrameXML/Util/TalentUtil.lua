TalentButtonUtil = {}

TalentButtonUtil.CircleEdgeDiameterOffset 		= 4.0
TalentButtonUtil.SquareEdgeMinDiameterOffset 	= 7.0
TalentButtonUtil.SquareEdgeMaxDiameterOffset 	= 9.0
TalentButtonUtil.ChoiceEdgeMinDiameterOffset 	= 5.0
TalentButtonUtil.ChoiceEdgeMaxDiameterOffset 	= 6.0

TalentButtonUtil.BaseVisualState = {
	Normal = 1,
	Gated = 2,
	Disabled = 3,
	Locked = 4,
	Selectable = 5,
	Maxed = 6,
	Invisible = 7,
	Invalid = 8,
}

TalentButtonUtil.ConnectionState = {
	Connected = 1,
	NoConnection = 2,
	Gated = 3,
	Invalid = 4,
}

TalentButtonUtil.VisualShape = {
	Circle = 1,
	Square = 2,
	Choice = 3,
}

local HoverAlphaByVisualState = {
	[TalentButtonUtil.BaseVisualState.Normal] = 1,
	[TalentButtonUtil.BaseVisualState.Gated] = 0.4,
	[TalentButtonUtil.BaseVisualState.Disabled] = 0.4,
	[TalentButtonUtil.BaseVisualState.Locked] = 0.4,
	[TalentButtonUtil.BaseVisualState.Selectable] = 1,
	[TalentButtonUtil.BaseVisualState.Maxed] = 1,
	[TalentButtonUtil.BaseVisualState.Invisible] = 0,
	[TalentButtonUtil.BaseVisualState.Invalid] = 0.4,
}

function TalentButtonUtil.GetHoverAlphaForVisualStyle(visualStyle)
	return HoverAlphaByVisualState[visualStyle]
end

function TalentButtonUtil.GetColorForBaseVisualState(visualState)
	if (visualState == TalentButtonUtil.BaseVisualState.Gated) or (visualState == TalentButtonUtil.BaseVisualState.Disabled) or (visualState == TalentButtonUtil.BaseVisualState.Locked) then
		return DISABLED_FONT_COLOR
	elseif visualState == TalentButtonUtil.BaseVisualState.Selectable then
		return GREEN_FONT_COLOR
	elseif visualState == TalentButtonUtil.BaseVisualState.Invalid then
		return RED_FONT_COLOR
	end

	return YELLOW_FONT_COLOR
end
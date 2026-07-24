HelpTips.GlueBits = { -- DO NOT REORDER THESE
	GetLauncherAddons = 0x1,
}


HelpTips["GET_ADDONS_ON_LAUNCHER"] = {
	parent                       = "CharacterSelectAddonsButton",
	text                         = GET_ADDONS_ON_LAUNCHER,
	textJustifyH                 = "CENTER",
	cvar                         = "GlueTipBitfield",
	cvarBit                      = HelpTips.GlueBits.GetLauncherAddons,
	targetPoint                  = HelpTip.Point.TopEdgeCenter,
	buttonStyle                  = HelpTip.ButtonStyle.Okay,
	alignment                    = HelpTip.Alignment.Left,
	highlightTarget              = HelpTip.TargetType.Box,
	acknowledgeOnHide            = false,
	dontReleaseUntilAcknowledged = true,
}
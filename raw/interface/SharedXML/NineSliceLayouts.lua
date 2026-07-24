NineSliceLayouts = {
	SimplePanelTemplate                      = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "UI-Frame-SimpleMetal-CornerTopLeft", x = -5, y = 0 },
		TopRightCorner    = { atlas = "UI-Frame-SimpleMetal-CornerTopLeft", x = 2, y = 0 },
		BottomLeftCorner  = { atlas = "UI-Frame-SimpleMetal-CornerTopLeft", x = -5, y = -3 },
		BottomRightCorner = { atlas = "UI-Frame-SimpleMetal-CornerTopLeft", x = 2, y = -3 },
		TopEdge           = { atlas = "_UI-Frame-SimpleMetal-EdgeTop" },
		BottomEdge        = { atlas = "_UI-Frame-SimpleMetal-EdgeTop" },
		LeftEdge          = { atlas = "!UI-Frame-SimpleMetal-EdgeLeft" },
		RightEdge         = { atlas = "!UI-Frame-SimpleMetal-EdgeLeft" }
	},

	PortraitFrameTemplate                    = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16 },
		TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16 },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3 },
		BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3 },
		TopEdge           = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = 0, y = 0, x1 = 0, y1 = 0 },
		BottomEdge        = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0 },
		LeftEdge          = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0 },
		RightEdge         = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0 }
	},

	PortraitFrameTemplateMinimizable         = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-PortraitMetal-CornerTopLeft", x = -13, y = 16 },
		TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRightDouble", x = 4, y = 16 },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -13, y = -3 },
		BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3 },
		TopEdge           = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop", x = 0, y = 0, x1 = 0, y1 = 0 },
		BottomEdge        = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom", x = 0, y = 0, x1 = 0, y1 = 0 },
		LeftEdge          = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft", x = 0, y = 0, x1 = 0, y1 = 0 },
		RightEdge         = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight", x = 0, y = 0, x1 = 0, y1 = 0 }
	},

	ButtonFrameTemplateNoPortrait            = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft", x = -12, y = 16 },
		TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRight", x = 4, y = 16 },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -12, y = -3 },
		BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3 },
		TopEdge           = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop" },
		BottomEdge        = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom" },
		LeftEdge          = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft" },
		RightEdge         = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight" }
	},

	ButtonFrameTemplateNoPortraitMinimizable = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopLeft", x = -12, y = 16 },
		TopRightCorner    = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerTopRightDouble", x = 4, y = 16 },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomLeft", x = -12, y = -3 },
		BottomRightCorner = { layer = "OVERLAY", atlas = "UI-Frame-Metal-CornerBottomRight", x = 4, y = -3 },
		TopEdge           = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeTop" },
		BottomEdge        = { layer = "OVERLAY", atlas = "_UI-Frame-Metal-EdgeBottom" },
		LeftEdge          = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeLeft" },
		RightEdge         = { layer = "OVERLAY", atlas = "!UI-Frame-Metal-EdgeRight" }
	},

	InsetFrameTemplate                       = {
		TopLeftCorner     = { subLevel = -5, atlas = "UI-Frame-InnerTopLeft" },
		TopRightCorner    = { subLevel = -5, atlas = "UI-Frame-InnerTopRight" },
		BottomLeftCorner  = { subLevel = -5, atlas = "UI-Frame-InnerBotLeftCorner", x = 0, y = -1 },
		BottomRightCorner = { subLevel = -5, atlas = "UI-Frame-InnerBotRight", x = 0, y = -1 },
		TopEdge           = { subLevel = -5, atlas = "_UI-Frame-InnerTopTile" },
		BottomEdge        = { subLevel = -5, atlas = "_UI-Frame-InnerBotTile" },
		LeftEdge          = { subLevel = -5, atlas = "!UI-Frame-InnerLeftTile" },
		RightEdge         = { subLevel = -5, atlas = "!UI-Frame-InnerRightTile" }
	},

	BFAMissionHorde                          = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "HordeFrame-Corner-TopLeft", x = -6, y = 6 },
		TopRightCorner    = { atlas = "HordeFrame-Corner-TopLeft", x = 6, y = 6 },
		BottomLeftCorner  = { atlas = "HordeFrame-Corner-TopLeft", x = -6, y = -6 },
		BottomRightCorner = { atlas = "HordeFrame-Corner-TopLeft", x = 6, y = -6 },
		TopEdge           = { atlas = "_HordeFrameTile-Top" },
		BottomEdge        = { atlas = "_HordeFrameTile-Top" },
		LeftEdge          = { atlas = "!HordeFrameTile-Left" },
		RightEdge         = { atlas = "!HordeFrameTile-Left" }
	},

	BFAMissionAlliance                       = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "AllianceFrameCorner-TopLeft", x = -6, y = 6 },
		TopRightCorner    = { atlas = "AllianceFrameCorner-TopLeft", x = 6, y = 6 },
		BottomLeftCorner  = { atlas = "AllianceFrameCorner-TopLeft", x = -6, y = -6 },
		BottomRightCorner = { atlas = "AllianceFrameCorner-TopLeft", x = 6, y = -6 },
		TopEdge           = { atlas = "_AllianceFrameTile-Top" },
		BottomEdge        = { atlas = "_AllianceFrameTile-Top" },
		LeftEdge          = { atlas = "!AllianceFrameTile-Left" },
		RightEdge         = { atlas = "!AllianceFrameTile-Left" }
	},

	CovenantMissionFrame                     = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "Oribos-NineSlice-CornerTopLeft", x = -6, y = 6 },
		TopRightCorner    = { atlas = "Oribos-NineSlice-CornerTopLeft", x = 6, y = 6 },
		BottomLeftCorner  = { atlas = "Oribos-NineSlice-CornerTopLeft", x = -6, y = -6 },
		BottomRightCorner = { atlas = "Oribos-NineSlice-CornerTopLeft", x = 6, y = -6 },
		TopEdge           = { atlas = "_Oribos-NineSlice-EdgeTop" },
		BottomEdge        = { atlas = "_Oribos-NineSlice-EdgeTop" },
		LeftEdge          = { atlas = "!Oribos-NineSlice-EdgeLeft" },
		RightEdge         = { atlas = "!Oribos-NineSlice-EdgeLeft" }
	},

	ThinGenericMetal                         = {
		TopLeftCorner     = { atlas = "UI-Frame-GenericMetal-Corner", x = -6, y = 6, mirrorLayout = true, width = 83, height = 83 },
		TopRightCorner    = { atlas = "UI-Frame-GenericMetal-Corner", x = 6, y = 6, mirrorLayout = true, width = 83, height = 83 },
		BottomLeftCorner  = { atlas = "UI-Frame-GenericMetal-Corner", x = -6, y = -6, mirrorLayout = true, width = 83, height = 83 },
		BottomRightCorner = { atlas = "UI-Frame-GenericMetal-Corner", x = 6, y = -6, mirrorLayout = true, width = 83, height = 83 },
		TopEdge           = { atlas = "_UI-Frame-GenericMetal-TileTop", width = 128, height = 15 },
		BottomEdge        = { atlas = "_UI-Frame-GenericMetal-TileBottom", width = 128, height = 15 },
		LeftEdge          = { atlas = "!UI-Frame-GenericMetal-TileLeft", width = 15, height = 128 },
		RightEdge         = { atlas = "!UI-Frame-GenericMetal-TileRight", width = 15, height = 128 }
	},

	GenericMetal                             = {
		TopLeftCorner     = { atlas = "UI-Frame-GenericMetal-Corner", x = -6, y = 6, mirrorLayout = true },
		TopRightCorner    = { atlas = "UI-Frame-GenericMetal-Corner", x = 6, y = 6, mirrorLayout = true },
		BottomLeftCorner  = { atlas = "UI-Frame-GenericMetal-Corner", x = -6, y = -6, mirrorLayout = true },
		BottomRightCorner = { atlas = "UI-Frame-GenericMetal-Corner", x = 6, y = -6, mirrorLayout = true },
		TopEdge           = { atlas = "_UI-Frame-GenericMetal-TileTop" },
		BottomEdge        = { atlas = "_UI-Frame-GenericMetal-TileBottom" },
		LeftEdge          = { atlas = "!UI-Frame-GenericMetal-TileLeft" },
		RightEdge         = { atlas = "!UI-Frame-GenericMetal-TileRight" }
	},

	ThinGenericMetal2                        = {
		TopLeftCorner     = { atlas = "GenericMetal2-NineSlice-CornerTopLeft", x = -10, y = 10, width = 32, height = 32 },
		TopRightCorner    = { atlas = "GenericMetal2-NineSlice-CornerTopRight", x = 10, y = 10, width = 32, height = 32 },
		BottomLeftCorner  = { atlas = "GenericMetal2-NineSlice-CornerBottomLeft", x = -10, y = -10, width = 32, height = 32 },
		BottomRightCorner = { atlas = "GenericMetal2-NineSlice-CornerBottomRight", x = 10, y = -10, width = 32, height = 32 },
		TopEdge           = { atlas = "_GenericMetal2-NineSlice-EdgeTop", width = 256, height = 32 },
		BottomEdge        = { atlas = "_GenericMetal2-NineSlice-EdgeBottom", width = 256, height = 32 },
		LeftEdge          = { atlas = "!GenericMetal2-NineSlice-EdgeLeft", width = 32, height = 256 },
		RightEdge         = { atlas = "!GenericMetal2-NineSlice-EdgeRight", width = 32, height = 256 }
	},

	GenericMetal2                            = {
		TopLeftCorner     = { atlas = "GenericMetal2-NineSlice-CornerTopLeft", },
		TopRightCorner    = { atlas = "GenericMetal2-NineSlice-CornerTopRight" },
		BottomLeftCorner  = { atlas = "GenericMetal2-NineSlice-CornerBottomLeft" },
		BottomRightCorner = { atlas = "GenericMetal2-NineSlice-CornerBottomRight" },
		TopEdge           = { atlas = "_GenericMetal2-NineSlice-EdgeTop" },
		BottomEdge        = { atlas = "_GenericMetal2-NineSlice-EdgeBottom" },
		LeftEdge          = { atlas = "!GenericMetal2-NineSlice-EdgeLeft" },
		RightEdge         = { atlas = "!GenericMetal2-NineSlice-EdgeRight" }
	},

	Dialog                                   = {
		TopLeftCorner     = { atlas = "UI-Frame-DiamondMetal-CornerTopLeft" },
		TopRightCorner    = { atlas = "UI-Frame-DiamondMetal-CornerTopRight" },
		BottomLeftCorner  = { atlas = "UI-Frame-DiamondMetal-CornerBottomLeft" },
		BottomRightCorner = { atlas = "UI-Frame-DiamondMetal-CornerBottomRight" },
		TopEdge           = { atlas = "_UI-Frame-DiamondMetal-EdgeTop" },
		BottomEdge        = { atlas = "_UI-Frame-DiamondMetal-EdgeBottom" },
		LeftEdge          = { atlas = "!UI-Frame-DiamondMetal-EdgeLeft" },
		RightEdge         = { atlas = "!UI-Frame-DiamondMetal-EdgeRight" }
	},

	WoodenNeutralFrameTemplate               = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "UI-Frame-Neutral-Corner", x = -6, y = 6 },
		TopRightCorner    = { atlas = "UI-Frame-Neutral-Corner", x = 6, y = 6 },
		BottomLeftCorner  = { atlas = "UI-Frame-Neutral-Corner", x = -6, y = -6 },
		BottomRightCorner = { atlas = "UI-Frame-Neutral-Corner", x = 6, y = -6 },
		TopEdge           = { atlas = "_UI-Frame-Neutral-TileTop" },
		BottomEdge        = { atlas = "_UI-Frame-Neutral-TileBottom", mirrorLayout = false },
		LeftEdge          = { atlas = "!UI-Frame-Neutral-TileLeft" },
		RightEdge         = { atlas = "!UI-Frame-Neutral-TileRight", mirrorLayout = false }
	},

	Runeforge                                = {
		TopLeftCorner     = { atlas = "UI-Frame-DiamondMetal-CornerTopLeft" },
		TopRightCorner    = { atlas = "UI-Frame-DiamondMetal-CornerTopRight" },
		BottomLeftCorner  = { atlas = "UI-Frame-DiamondMetal-CornerBottomLeft" },
		BottomRightCorner = { atlas = "UI-Frame-DiamondMetal-CornerBottomRight" },
		TopEdge           = { atlas = "_UI-Frame-DiamondMetal-EdgeTop" },
		BottomEdge        = { atlas = "_UI-Frame-DiamondMetal-EdgeBottom" },
		LeftEdge          = { atlas = "!UI-Frame-DiamondMetal-EdgeLeft" },
		RightEdge         = { atlas = "!UI-Frame-DiamondMetal-EdgeRight" }
	},

	AdventuresMissionComplete                = {
		TopLeftCorner     = { atlas = "AdventuresFrame-Corner-Small-TopLeft", mirrorLayout = true },
		TopRightCorner    = { atlas = "AdventuresFrame-Corner-Small-TopLeft", mirrorLayout = true },
		BottomLeftCorner  = { atlas = "AdventuresFrame-Corner-Small-TopLeft", mirrorLayout = true },
		BottomRightCorner = { atlas = "AdventuresFrame-Corner-Small-TopLeft", mirrorLayout = true },
		TopEdge           = { layer = "BACKGROUND", atlas = "_AdventuresFrame-Small-Top", x = -10, y = 3, x1 = 10, y1 = 3 },
		BottomEdge        = { layer = "BACKGROUND", atlas = "_AdventuresFrame-Small-Top", x = -10, y = -3, x1 = 10, y1 = -3, mirrorLayout = true },
		LeftEdge          = { layer = "BACKGROUND", atlas = "!AdventuresFrame-Right", x = -3, y = 10, x1 = -3, y1 = -10 },
		RightEdge         = { layer = "BACKGROUND", atlas = "!AdventuresFrame-Left", x = 3, y = 10, x1 = 3, y1 = -10 }
	},

	CharacterCreateDropdown                  = {
		TopLeftCorner     = { atlas = "CharacterCreateDropdown-NineSlice-CornerTopLeft", x = -30, y = 20 },
		TopRightCorner    = { atlas = "CharacterCreateDropdown-NineSlice-CornerTopRight", x = 30, y = 20 },
		BottomLeftCorner  = { atlas = "CharacterCreateDropdown-NineSlice-CornerBottomLeft", x = -30, y = -20 },
		BottomRightCorner = { atlas = "CharacterCreateDropdown-NineSlice-CornerBottomRight", x = 30, y = -20 },
		TopEdge           = { atlas = "_CharacterCreateDropdown-NineSlice-EdgeTop" },
		BottomEdge        = { atlas = "_CharacterCreateDropdown-NineSlice-EdgeBottom" },
		LeftEdge          = { atlas = "!CharacterCreateDropdown-NineSlice-EdgeLeft" },
		RightEdge         = { atlas = "!CharacterCreateDropdown-NineSlice-EdgeRight" },
		Center            = { atlas = "CharacterCreateDropdown-NineSlice-Center" }
	},

	ChatBubble                               = {
		TopLeftCorner     = { atlas = "ChatBubble-NineSlice-CornerTopLeft" },
		TopRightCorner    = { atlas = "ChatBubble-NineSlice-CornerTopRight" },
		BottomLeftCorner  = { atlas = "ChatBubble-NineSlice-CornerBottomLeft" },
		BottomRightCorner = { atlas = "ChatBubble-NineSlice-CornerBottomRight" },
		TopEdge           = { atlas = "_ChatBubble-NineSlice-EdgeTop" },
		BottomEdge        = { atlas = "_ChatBubble-NineSlice-EdgeBottom" },
		LeftEdge          = { atlas = "!ChatBubble-NineSlice-EdgeLeft" },
		RightEdge         = { atlas = "!ChatBubble-NineSlice-EdgeRight" },
		Center            = { atlas = "ChatBubble-NineSlice-Center" }
	},

	UniqueCornersLayout                      = {
		["TopRightCorner"]    = { atlas = "%s-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "%s-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "%s-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "%s-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_%s-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_%s-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!%s-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!%s-NineSlice-EdgeRight" },
		["Center"]            = { atlas = "%s-NineSlice-Center" }
	},

	UniqueCornersNoCenterLayout                      = {
		["TopRightCorner"]    = { atlas = "%s-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "%s-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "%s-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "%s-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_%s-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_%s-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!%s-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!%s-NineSlice-EdgeRight" },
	},

	ThreeSliceVerticalLayout =
	{
		threeSliceVertical = true,
		["TopEdge"] = { atlas = "%s-ThreeSlice-EdgeTop" },
		["BottomEdge"] = { atlas = "%s-ThreeSlice-EdgeBottom" },
		["Center"] = { atlas = "!%s-ThreeSlice-Center" },
	},

	ThreeSliceHorizontalLayout =
	{
		threeSliceHorizontal = true,
		["LeftEdge"] = { atlas = "%s-ThreeSlice-EdgeLeft" },
		["RightEdge"] = { atlas = "%s-ThreeSlice-EdgeRight" },
		["Center"] = { atlas = "_%s-ThreeSlice-Center" },
	},

	GMChatRequest                            = {
		["TopRightCorner"]    = { atlas = "GMChat-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "GMChat-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "GMChat-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "GMChat-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_GMChat-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_GMChat-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!GMChat-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!GMChat-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-NineSlice-Center", x = -2, y = 2, x1 = 2, y1 = -2 }
	},

	TooltipDefaultLayout                     = {
		["TopRightCorner"]    = { atlas = "Tooltip-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_Tooltip-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-NineSlice-Center", x = -2, y = 2, x1 = 2, y1 = -2 }
	},

	TooltipAzeriteLayout                     = {
		["TopRightCorner"]    = { atlas = "Tooltip-Azerite-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-Azerite-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-Azerite-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-Azerite-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-Azerite-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_Tooltip-Azerite-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-Azerite-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-Azerite-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-Azerite-NineSlice-Center", x = -18, y = 18, x1 = 18, y1 = -18 }
	},

	TooltipCorruptedLayout                   = {
		["TopRightCorner"]    = { atlas = "Tooltip-Corrupted-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-Corrupted-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-Corrupted-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-Corrupted-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-Corrupted-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_Tooltip-Corrupted-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-Corrupted-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-Corrupted-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-Corrupted-NineSlice-Center", x = -18, y = 18, x1 = 18, y1 = -18 }
	},

	TooltipMawLayout                         = {
		["TopRightCorner"]    = { atlas = "Tooltip-Maw-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-Maw-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-Maw-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-Maw-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-Maw-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_Tooltip-Maw-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-Maw-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-Maw-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-Maw-NineSlice-Center", x = -24, y = 24, x1 = 24, y1 = -24 }
	},

	TooltipGluesLayout                       = {
		["TopRightCorner"]    = { atlas = "Tooltip-Glues-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-Glues-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-Glues-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-Glues-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-Glues-NineSlice-EdgeTop", x = 0, y = -1, x1 = 0, y1 = -1 },
		["BottomEdge"]        = { atlas = "_Tooltip-Glues-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-Glues-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-Glues-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-Glues-NineSlice-Center", x = -8, y = 10, x1 = 8, y1 = -7 }
	},

	TooltipMixedLayout                       = {
		["TopRightCorner"]    = { atlas = "Tooltip-Glues-NineSlice-CornerTopRight" },
		["TopLeftCorner"]     = { atlas = "Tooltip-Glues-NineSlice-CornerTopLeft" },
		["BottomLeftCorner"]  = { atlas = "Tooltip-Glues-NineSlice-CornerBottomLeft" },
		["BottomRightCorner"] = { atlas = "Tooltip-Glues-NineSlice-CornerBottomRight" },
		["TopEdge"]           = { atlas = "_Tooltip-Glues-NineSlice-EdgeTop", x = 0, y = -1, x1 = 0, y1 = -1 },
		["BottomEdge"]        = { atlas = "_Tooltip-Glues-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!Tooltip-Glues-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!Tooltip-Glues-NineSlice-EdgeRight" },
		["Center"]            = { layer = "BACKGROUND", atlas = "Tooltip-NineSlice-Center", x = -8, y = 10, x1 = 8, y1 = -7 }
	},

	IdenticalCornersLayoutNoCenter           = {
		["TopRightCorner"]    = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["TopLeftCorner"]     = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["BottomLeftCorner"]  = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["TopEdge"]           = { atlas = "_%s-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_%s-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!%s-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!%s-NineSlice-EdgeRight" }
	},

	IdenticalCornersLayout                   = {
		["TopRightCorner"]    = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["TopLeftCorner"]     = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["BottomLeftCorner"]  = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true },
		["TopEdge"]           = { atlas = "_%s-NineSlice-EdgeTop" },
		["BottomEdge"]        = { atlas = "_%s-NineSlice-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!%s-NineSlice-EdgeLeft" },
		["RightEdge"]         = { atlas = "!%s-NineSlice-EdgeRight" },
		["Center"]            = { atlas = "%s-NineSlice-Center" }
	},

	HelpGlowHighlight                        = {
		blendMode             = "ADD",
		mirrorLayout          = true,
		["TopRightCorner"]    = { atlas = "GlowBorder-Corner" },
		["TopLeftCorner"]     = { atlas = "GlowBorder-Corner" },
		["BottomLeftCorner"]  = { atlas = "GlowBorder-Corner" },
		["BottomRightCorner"] = { atlas = "GlowBorder-Corner" },
		["TopEdge"]           = { atlas = "_GlowBorder-Top" },
		["BottomEdge"]        = { atlas = "_GlowBorder-Top" },
		["LeftEdge"]          = { atlas = "!GlowBorder-Left" },
		["RightEdge"]         = { atlas = "!GlowBorder-Left" },
	},

	NPEPopupLayout                           = {
		blendMode             = "BLEND",
		["TopLeftCorner"]     = { atlas = "UI-Frame-NewPlayerTutorial-CornerTopLeft-Small", x = -32, y = 32 },
		["TopRightCorner"]    = { atlas = "UI-Frame-NewPlayerTutorial-CornerTopRight-Small", x = 32, y = 32 },
		["BottomLeftCorner"]  = { atlas = "UI-Frame-NewPlayerTutorial-CornerBottomLeft-Small", x = -32, y = -32 },
		["BottomRightCorner"] = { atlas = "UI-Frame-NewPlayerTutorial-CornerBottomRight-Small", x = 32, y = -32 },
		["TopEdge"]           = { atlas = "_UI-Frame-NewPlayerTutorial-EdgeTop-Small" },
		["BottomEdge"]        = { atlas = "_UI-Frame-NewPlayerTutorial-EdgeBottom-Small" },
		["LeftEdge"]          = { atlas = "!UI-Frame-NewPlayerTutorial-EdgeLeft-Small" },
		["RightEdge"]         = { atlas = "!UI-Frame-NewPlayerTutorial-EdgeRight-Small" },
		["Center"]            = { atlas = "UI-Frame-NewPlayerTutorial-Center" }
	},

	NPEGiantPopupLayout                      = {
		blendMode             = "BLEND",
		["TopLeftCorner"]     = { atlas = "UI-Frame-NewPlayerTutorial-CornerTopLeft", x = -128, y = 128 },
		["TopRightCorner"]    = { atlas = "UI-Frame-NewPlayerTutorial-CornerTopRight", x = 128, y = 128 },
		["BottomLeftCorner"]  = { atlas = "UI-Frame-NewPlayerTutorial-CornerBottomLeft", x = -128, y = -128 },
		["BottomRightCorner"] = { atlas = "UI-Frame-NewPlayerTutorial-CornerBottomRight", x = 128, y = -128 },
		["TopEdge"]           = { atlas = "_UI-Frame-NewPlayerTutorial-EdgeTop" },
		["BottomEdge"]        = { atlas = "_UI-Frame-NewPlayerTutorial-EdgeBottom" },
		["LeftEdge"]          = { atlas = "!UI-Frame-NewPlayerTutorial-EdgeLeft" },
		["RightEdge"]         = { atlas = "!UI-Frame-NewPlayerTutorial-EdgeRight" },
		["Center"]            = { atlas = "UI-Frame-NewPlayerTutorial-Center" }
	},

	RockFrameTemplate                        = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "ui-frame-rock-corner", x = -6, y = 6 },
		TopRightCorner    = { atlas = "ui-frame-rock-corner", x = 6, y = 6 },
		BottomLeftCorner  = { atlas = "ui-frame-rock-corner", x = -6, y = -6 },
		BottomRightCorner = { atlas = "ui-frame-rock-corner", x = 6, y = -6 },
		TopEdge           = { atlas = "ui-frame-rock-top" },
		BottomEdge        = { atlas = "ui-frame-rock-bottom", mirrorLayout = false },
		LeftEdge          = { atlas = "ui-frame-rock-left" },
		RightEdge         = { atlas = "ui-frame-rock-right", mirrorLayout = false }
	},

	ThinRockFrameTemplate                    = {
		mirrorLayout      = true,
		TopLeftCorner     = { atlas = "ui-frame-rock-corner-small" },
		TopRightCorner    = { atlas = "ui-frame-rock-corner-small" },
		BottomLeftCorner  = { atlas = "ui-frame-rock-corner-small" },
		BottomRightCorner = { atlas = "ui-frame-rock-corner-small" },
		TopEdge           = { atlas = "ui-frame-rock-top-small" },
		BottomEdge        = { atlas = "ui-frame-rock-bottom-small", mirrorLayout = false },
		LeftEdge          = { atlas = "ui-frame-rock-left-small" },
		RightEdge         = { atlas = "ui-frame-rock-right-small", mirrorLayout = false }
	},

	BlueMenuLayout                           = {
		["TopRightCorner"]    = { layer = "BORDER", atlas = "bluemenu-tr" },
		["TopLeftCorner"]     = { layer = "BORDER", atlas = "bluemenu-tl" },
		["BottomLeftCorner"]  = { layer = "BORDER", atlas = "bluemenu-bl" },
		["BottomRightCorner"] = { layer = "BORDER", atlas = "bluemenu-br" },
		["TopEdge"]           = { layer = "BORDER", atlas = "_bluemenu-top" },
		["BottomEdge"]        = { layer = "BORDER", atlas = "_bluemenu-bottom" },
		["LeftEdge"]          = { layer = "BORDER", atlas = "!bluemenu-left" },
		["RightEdge"]         = { layer = "BORDER", atlas = "!bluemenu-right" },
		["Center"]            = { layer = "BACKGROUND", atlas = "bluemenu-bg", x = -64, y = 64, x1 = 64, y1 = -64 }
	},

	LegionFallGreenLayout                    = {
		["TopRightCorner"]    = { layer = "BORDER", atlas = "Legionfall_GreenTR" },
		["TopLeftCorner"]     = { layer = "BORDER", atlas = "Legionfall_GreenTL" },
		["BottomLeftCorner"]  = { layer = "BORDER", atlas = "Legionfall_GreenBL" },
		["BottomRightCorner"] = { layer = "BORDER", atlas = "Legionfall_GreenBR" },
		["TopEdge"]           = { layer = "BORDER", atlas = "_Legionfall_GreenTop" },
		["BottomEdge"]        = { layer = "BORDER", atlas = "_Legionfall_GreenBottom" },
		["LeftEdge"]          = { layer = "BORDER", atlas = "!Legionfall_GreenLeft" },
		["RightEdge"]         = { layer = "BORDER", atlas = "!Legionfall_GreenRight" },
	},

	LegionFallRedLayout                      = {
		["TopRightCorner"]    = { layer = "BORDER", atlas = "Legionfall_RedTR" },
		["TopLeftCorner"]     = { layer = "BORDER", atlas = "Legionfall_RedTL" },
		["BottomLeftCorner"]  = { layer = "BORDER", atlas = "Legionfall_RedBL" },
		["BottomRightCorner"] = { layer = "BORDER", atlas = "Legionfall_RedBR" },
		["TopEdge"]           = { layer = "BORDER", atlas = "_Legionfall_RedTop" },
		["BottomEdge"]        = { layer = "BORDER", atlas = "_Legionfall_RedBottom" },
		["LeftEdge"]          = { layer = "BORDER", atlas = "!Legionfall_RedLeft" },
		["RightEdge"]         = { layer = "BORDER", atlas = "!Legionfall_RedRight" },
	},

	LegionFallYellowLayout                   = {
		["TopRightCorner"]    = { layer = "BORDER", atlas = "Legionfall_YellowTR" },
		["TopLeftCorner"]     = { layer = "BORDER", atlas = "Legionfall_YellowTL" },
		["BottomLeftCorner"]  = { layer = "BORDER", atlas = "Legionfall_YellowBL" },
		["BottomRightCorner"] = { layer = "BORDER", atlas = "Legionfall_YellowBR" },
		["TopEdge"]           = { layer = "BORDER", atlas = "_Legionfall_YellowTop" },
		["BottomEdge"]        = { layer = "BORDER", atlas = "_Legionfall_YellowBottom" },
		["LeftEdge"]          = { layer = "BORDER", atlas = "!Legionfall_YellowLeft" },
		["RightEdge"]         = { layer = "BORDER", atlas = "!Legionfall_YellowRight" },
	},

	DraftGlowBorder                          = {
		mirrorLayout          = true,
		["TopRightCorner"]    = { layer = "BACKGROUND", atlas = "draft-border-tl" },
		["TopLeftCorner"]     = { layer = "BACKGROUND", atlas = "draft-border-tl" },
		["BottomLeftCorner"]  = { layer = "BACKGROUND", atlas = "draft-border-tl" },
		["BottomRightCorner"] = { layer = "BACKGROUND", atlas = "draft-border-tl" },
		["TopEdge"]           = { layer = "BACKGROUND", atlas = "_draft-border-h" },
		["BottomEdge"]        = { layer = "BACKGROUND", atlas = "_draft-border-h" },
		["LeftEdge"]          = { layer = "BACKGROUND", atlas = "!draft-border-v" },
		["RightEdge"]         = { layer = "BACKGROUND", atlas = "!draft-border-v" },
	},

	RealmBorderThin                          = {
		TopLeftCorner     = { atlas = "white2x2", x = -2, y = 2 },
		TopRightCorner    = { atlas = "white2x2", x = 2, y = 2 },
		BottomLeftCorner  = { atlas = "white2x2", x = -2, y = -2 },
		BottomRightCorner = { atlas = "white2x2", x = 2, y = -2 },
		TopEdge           = { atlas = "white2x2", y = 2 },
		BottomEdge        = { atlas = "white2x2", y = -2 },
		LeftEdge          = { atlas = "white2x2", x = -2 },
		RightEdge         = { atlas = "white2x2", x = 2 }
	},

	LargeShadowOverlay                       = {
		["TopRightCorner"]    = { atlas = "collections-shadow-topright" },
		["TopLeftCorner"]     = { atlas = "collections-shadow-topleft" },
		["BottomLeftCorner"]  = { atlas = "collections-shadow-botleft" },
		["BottomRightCorner"] = { atlas = "collections-shadow-botright" },
		["TopEdge"]           = { atlas = "_collections-shadow-top" },
		["BottomEdge"]        = { atlas = "_collections-shadow-bot" },
		["LeftEdge"]          = { atlas = "!collections-shadow-left" },
		["RightEdge"]         = { atlas = "!collections-shadow-right" },
	},

	ShadowOverlay                            = {
		["TopRightCorner"]    = { width = 72, height = 74, atlas = "collections-shadow-topright" },
		["TopLeftCorner"]     = { width = 72, height = 74, atlas = "collections-shadow-topleft" },
		["BottomLeftCorner"]  = { width = 72, height = 74, atlas = "collections-shadow-botleft" },
		["BottomRightCorner"] = { width = 72, height = 74, atlas = "collections-shadow-botright" },
		["TopEdge"]           = { width = 1, height = 74, atlas = "_collections-shadow-top" },
		["BottomEdge"]        = { width = 1, height = 74, atlas = "_collections-shadow-bot" },
		["LeftEdge"]          = { width = 72, height = 1, atlas = "!collections-shadow-left" },
		["RightEdge"]         = { width = 72, height = 1, atlas = "!collections-shadow-right" },
	},

	SmallShadowOverlay                       = {
		["TopRightCorner"]    = { atlas = "collections-shadow-small-topright" },
		["TopLeftCorner"]     = { atlas = "collections-shadow-small-topleft" },
		["BottomLeftCorner"]  = { atlas = "collections-shadow-small-botleft" },
		["BottomRightCorner"] = { atlas = "collections-shadow-small-botright" },
		["TopEdge"]           = { atlas = "_collections-shadow-small-top" },
		["BottomEdge"]        = { atlas = "_collections-shadow-small-bot" },
		["LeftEdge"]          = { atlas = "!collections-shadow-small-left" },
		["RightEdge"]         = { atlas = "!collections-shadow-small-right" },
	},

	GarrisonLandingLayout                    = {
		["TopRightCorner"]    = { atlas = "GarrLanding-upperright" },
		["TopLeftCorner"]     = { atlas = "GarrLanding-upperleft" },
		["BottomLeftCorner"]  = { atlas = "GarrLanding-lowerleft" },
		["BottomRightCorner"] = { atlas = "GarrLanding-lowerright" },
		["TopEdge"]           = { x = 0, x1 = 0, y = -1, y1 = -1, atlas = "GarrLanding-Top" },
		["BottomEdge"]        = { x = 0, x1 = 0, y = 1, y1 = 1, atlas = "GarLanding-Bottom" },
		["LeftEdge"]          = { x = 1, x1 = 1, y = 0, y1 = 0, atlas = "GarLanding-Left" },
		["RightEdge"]         = { x = -1, x1 = -1, y = 0, y1 = 0, atlas = "GarLanding-Right" },
	},

	GarrisonLandingSmallLayout               = {
		["TopRightCorner"]    = { width = 62, height = 48, atlas = "GarrLanding-upperright" },
		["TopLeftCorner"]     = { width = 62, height = 48, atlas = "GarrLanding-upperleft" },
		["BottomLeftCorner"]  = { width = 62, height = 48, atlas = "GarrLanding-lowerleft" },
		["BottomRightCorner"] = { width = 62, height = 48, atlas = "GarrLanding-lowerright" },
		["TopEdge"]           = { width = 124, height = 28, atlas = "GarrLanding-Top" },
		["BottomEdge"]        = { width = 124, height = 28, atlas = "GarLanding-Bottom", x = 0, x1 = 0, y = 1, y1 = 1 },
		["LeftEdge"]          = { width = 28, height = 67, atlas = "GarLanding-Left", x = 1, x1 = 1, y = 0, y1 = 0 },
		["RightEdge"]         = { width = 28, height = 67, atlas = "GarLanding-Right", x = -1, x1 = -1, y = 0, y1 = 0 },
	},

	GarrisonMissionHighlight                    = {
		["TopRightCorner"]    = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Highlight", mirrorLayout = true },
		["TopLeftCorner"]     = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Highlight", mirrorLayout = true },
		["BottomLeftCorner"]  = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Highlight", mirrorLayout = true },
		["BottomRightCorner"] = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Highlight", mirrorLayout = true },
		["TopEdge"]           = { blendMode = "ADD", atlas = "_GarrMission_TopBorder-Highlight" },
		["BottomEdge"]        = { blendMode = "ADD", atlas = "_GarrMission_TopBorder-Highlight", mirrorLayout = true  },
	},

	GarrisonMissionSelected                    = {
		["TopRightCorner"]    = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Select", mirrorLayout = true },
		["TopLeftCorner"]     = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Select", mirrorLayout = true },
		["BottomLeftCorner"]  = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Select", mirrorLayout = true },
		["BottomRightCorner"] = { blendMode = "ADD", atlas = "GarrMission_TopBorderCorner-Select", mirrorLayout = true },
		["TopEdge"]           = { blendMode = "ADD", atlas = "_GarrMission_TopBorder-Select" },
		["BottomEdge"]        = { blendMode = "ADD", atlas = "_GarrMission_TopBorder-Select", mirrorLayout = true  },
	},

	GarrisonMissionBorder                    = {
		["TopRightCorner"]    = { layer = "OVERLAY", atlas = "GarrMission_TopBorderCorner", mirrorLayout = true },
		["TopLeftCorner"]     = { layer = "OVERLAY", atlas = "GarrMission_TopBorderCorner", mirrorLayout = true },
		["BottomLeftCorner"]  = { layer = "OVERLAY", atlas = "GarrMission_TopBorderCorner", mirrorLayout = true },
		["BottomRightCorner"] = { layer = "OVERLAY", atlas = "GarrMission_TopBorderCorner", mirrorLayout = true },
		["TopEdge"]           = { layer = "OVERLAY", atlas = "_GarrMission_TopBorder" },
		["BottomEdge"]        = { layer = "OVERLAY", atlas = "_GarrMission_TopBorder", mirrorLayout = true  },
	},

	GarrisonMissionBackground                = {
		["TopEdge"]           = { atlas = "_GarrMission_MissionListTopHighlight" },
		["BottomEdge"]        = { atlas = "_GarrMission_Bg-BottomEdgeSmall" },
		["LeftEdge"]		  = { atlas = "!GarrMission_Bg-Edge" },
		["RightEdge"]         = { atlas = "!GarrMission_Bg-Edge", mirrorLayout = true  },
	},

	HordeFrameLayout                         = {
		TopLeftCorner     = { atlas = "UI-Frame-Horde-Corner", x = -6, y = 6, mirrorLayout = true },
		TopRightCorner    = { atlas = "UI-Frame-Horde-Corner", x = 6, y = 6, mirrorLayout = true },
		BottomLeftCorner  = { atlas = "UI-Frame-Horde-Corner", x = -6, y = -6, mirrorLayout = true },
		BottomRightCorner = { atlas = "UI-Frame-Horde-Corner", x = 6, y = -6, mirrorLayout = true },
		TopEdge           = { atlas = "_UI-Frame-Horde-TileTop" },
		BottomEdge        = { atlas = "_UI-Frame-Horde-TileBottom" },
		LeftEdge          = { atlas = "!UI-Frame-Horde-TileLeft" },
		RightEdge         = { atlas = "!UI-Frame-Horde-TileRight" }
	},

	AllianceFrameLayout                      = {
		TopLeftCorner     = { atlas = "UI-Frame-Alliance-Corner", x = -6, y = 6, mirrorLayout = true },
		TopRightCorner    = { atlas = "UI-Frame-Alliance-Corner", x = 6, y = 6, mirrorLayout = true },
		BottomLeftCorner  = { atlas = "UI-Frame-Alliance-Corner", x = -6, y = -6, mirrorLayout = true },
		BottomRightCorner = { atlas = "UI-Frame-Alliance-Corner", x = 6, y = -6, mirrorLayout = true },
		TopEdge           = { atlas = "_UI-Frame-Alliance-TileTop" },
		BottomEdge        = { atlas = "_UI-Frame-Alliance-TileBottom" },
		LeftEdge          = { atlas = "!UI-Frame-Alliance-TileLeft" },
		RightEdge         = { atlas = "!UI-Frame-Alliance-TileRight" }
	},

	ServicesFrameLayout                      = {
		TopLeftCorner     = { atlas = "services-popup-topleft", x = -17, y = 34 },
		TopRightCorner    = { atlas = "services-popup-topright", x = 17, y = 34 },
		BottomLeftCorner  = { atlas = "services-popup-botleft", x = -15, y = -15 },
		BottomRightCorner = { atlas = "services-popup-botright", x = 15, y = -15 },
		TopEdge           = { atlas = "services-popup-top" },
		BottomEdge        = { atlas = "services-popup-bot" },
		LeftEdge          = { atlas = "services-popup-left", x = 2, x1 = 0, y = 0, y1 = 0 },
		RightEdge         = { atlas = "services-popup-right", x = -2, x1 = 0, y = 0, y1 = 0 }
	},

	MechagonFrameLayout                      = {
		TopLeftCorner     = { atlas = "UI-Frame-Mechagon-Corner", x = -6, y = 6, mirrorLayout = true },
		TopRightCorner    = { atlas = "UI-Frame-Mechagon-Corner", x = 6, y = 6, mirrorLayout = true },
		BottomLeftCorner  = { atlas = "UI-Frame-Mechagon-Corner", x = -6, y = -6, mirrorLayout = true },
		BottomRightCorner = { atlas = "UI-Frame-Mechagon-Corner", x = 6, y = -6, mirrorLayout = true },
		TopEdge           = { atlas = "_UI-Frame-Mechagon-TileTop" },
		BottomEdge        = { atlas = "_UI-Frame-Mechagon-TileBottom" },
		LeftEdge          = { atlas = "!UI-Frame-Mechagon-TileLeft" },
		RightEdge         = { atlas = "!UI-Frame-Mechagon-TileRight" }
	},

	InnerPaperDollBorder	                    = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "Char-Corner-UpperLeft", },
		TopRightCorner    = { layer = "OVERLAY", atlas = "Char-Corner-UpperRight", },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "Char-Corner-LowerLeft", },
		BottomRightCorner = { layer = "OVERLAY", atlas = "Char-Corner-LowerRight", },
		TopEdge           = { layer = "OVERLAY", atlas = "_Char-Inner-Top", x = 0, y = 1 },
		BottomEdge        = { layer = "OVERLAY", atlas = "_Char-Inner-Bottom", x = 0, y = -1 },
		LeftEdge          = { layer = "OVERLAY", atlas = "!Char-Inner-Left", x = -1, y = 0 },
		RightEdge         = { layer = "OVERLAY", atlas = "!Char-Inner-Right", x = 1, y = 0 }
	},
	
	BuildCreatorBuildBorder = {
		TopLeftCorner     = { layer = "OVERLAY", atlas = "buildcreator-border-tl", x = -1, y = 1 },
		TopRightCorner    = { layer = "OVERLAY", atlas = "buildcreator-border-tr", x = 1, y = 1  },
		BottomLeftCorner  = { layer = "OVERLAY", atlas = "buildcreator-border-bl", x = -1, y = -1  },
		BottomRightCorner = { layer = "OVERLAY", atlas = "buildcreator-border-br", x = 1, y = -1  },
		TopEdge           = { layer = "OVERLAY", atlas = "_buildcreator-border-top", },
		BottomEdge        = { layer = "OVERLAY", atlas = "_buildcreator-border-bottom", },
		LeftEdge          = { layer = "OVERLAY", atlas = "!buildcreator-border-left", },
		RightEdge         = { layer = "OVERLAY", atlas = "!buildcreator-border-right", }
	},

	BuildCreatorBuildBorderHighlight = {
		TopLeftCorner     = { blendMode = "ADD", atlas = "buildcreator-border-tl-h", x = -1, y = 1 },
		TopRightCorner    = { blendMode = "ADD", atlas = "buildcreator-border-tr-h", x = 1, y = 1  },
		BottomLeftCorner  = { blendMode = "ADD", atlas = "buildcreator-border-bl-h", x = -1, y = -1  },
		BottomRightCorner = { blendMode = "ADD", atlas = "buildcreator-border-br-h", x = 1, y = -1  },
		TopEdge           = { blendMode = "ADD", atlas = "_buildcreator-border-top-h", },
		BottomEdge        = { blendMode = "ADD", atlas = "_buildcreator-border-bottom-h", },
		LeftEdge          = { blendMode = "ADD", atlas = "!buildcreator-border-left-h", },
		RightEdge         = { blendMode = "ADD", atlas = "!buildcreator-border-right-h", }
	},

	BuildCreatorBackgroundEdge = {
		TopLeftCorner     = { layer = "ARTWORK", atlas = "buildcreator-background-corner", mirrorLayout = true },
		TopRightCorner    = { layer = "ARTWORK", atlas = "buildcreator-background-corner", mirrorLayout = true },
		BottomLeftCorner  = { layer = "ARTWORK", atlas = "buildcreator-background-corner", mirrorLayout = true },
		BottomRightCorner = { layer = "ARTWORK", atlas = "buildcreator-background-corner", mirrorLayout = true },
		TopEdge           = { atlas = "_buildcreator-background-top",       x = -64, y = 0, x1 = 64, y1 = 0 },
		BottomEdge        = { atlas = "_buildcreator-background-bottom",    x = -64, y = 0, x1 = 64, y1 = 0 },
		LeftEdge          = { atlas = "!buildcreator-background-left",      x = 0, y = 64, x1 = 0, y1 = -64 },
		RightEdge         = { atlas = "!buildcreator-background-right",     x = 0, y = 64, x1 = 0, y1 = -64 },
	},
	
	HelpBoxGlow = {
		["TopRightCorner"]    = { blendMode = "ADD", atlas = "help-box-glow-topright", x=4, y=4 },
		["TopLeftCorner"]     = { blendMode = "ADD", atlas = "help-box-glow-topleft", x=-4, y=4 },
		["BottomLeftCorner"]  = { blendMode = "ADD", atlas = "help-box-glow-bottomleft", x=-4, y=-4 },
		["BottomRightCorner"] = { blendMode = "ADD", atlas = "help-box-glow-bottomright", x=4, y=-4 },
		["TopEdge"]           = { blendMode = "ADD", atlas = "_help-box-glow-top" },
		["BottomEdge"]        = { blendMode = "ADD", atlas = "_help-box-glow-bottom" },
		["LeftEdge"]          = { blendMode = "ADD", atlas = "!help-box-glow-left" },
		["RightEdge"]         = { blendMode = "ADD", atlas = "!help-box-glow-right" },
	},

	HelpBoxShadow = {
		["TopRightCorner"]    = { atlas = "help-box-shadow-topright" },
		["TopLeftCorner"]     = { atlas = "help-box-shadow-topleft" },
		["BottomLeftCorner"]  = { atlas = "help-box-shadow-bottomleft" },
		["BottomRightCorner"] = { atlas = "help-box-shadow-bottomright" },
		["TopEdge"]           = { atlas = "_help-box-shadow-top" },
		["BottomEdge"]        = { atlas = "_help-box-shadow-bottom" },
		["LeftEdge"]          = { atlas = "!help-box-shadow-left" },
		["RightEdge"]         = { atlas = "!help-box-shadow-right" },
	},
	
	GarrisonUI = {
		TopRightCorner		= { atlas = "Garr_WoodFrameCorner", mirrorLayout = true },
		TopLeftCorner		= { atlas = "Garr_WoodFrameCorner", mirrorLayout = true },
		BottomLeftCorner	= { atlas = "Garr_WoodFrameCorner", mirrorLayout = true },
		BottomRightCorner	= { atlas = "Garr_WoodFrameCorner", mirrorLayout = true },
		TopEdge				= { layer = "BACKGROUND", atlas = "_Garr_WoodFrameTile-Top", x=-54, y=0, x1=54, y1=0 },
		BottomEdge			= { layer = "BACKGROUND", atlas = "_Garr_WoodFrameTile-Bottom", x=-54, y=0, x1=54, y1=0 },
		LeftEdge			= { layer = "BACKGROUND", atlas = "!Garr_WoodFrameTile-Left", x=0, y=54, x1=0, y1=-54 },
		RightEdge			= { layer = "BACKGROUND", atlas = "!Garr_WoodFrameTile-Left", x=0, y=54, x1=0, y1=-54, mirrorLayout = true },
	},
	
	GarrisonMissionList = {
		TopRightCorner		= { layer = "ARTWORK", atlas = "Garr_InfoBoxMission-Corner", mirrorLayout = true },
		TopLeftCorner		= { layer = "ARTWORK", atlas = "Garr_InfoBoxMission-Corner", mirrorLayout = true },
		BottomLeftCorner	= { layer = "ARTWORK", atlas = "Garr_InfoBoxMission-Corner", mirrorLayout = true },
		BottomRightCorner	= { layer = "ARTWORK", atlas = "Garr_InfoBoxMission-Corner", mirrorLayout = true },
		TopEdge				= {atlas = "_Garr_InfoBoxMission-Top", x=-20, y=0, x1=20, y1=0 },
		BottomEdge			= {atlas = "_Garr_InfoBoxMission-Top", x=-20, y=0, x1=20, y1=0,  mirrorLayout = true },
		LeftEdge			= {atlas = "!Garr_InfoBoxMission-Left", x=0, y=20, x1=0, y1=-20 },
		RightEdge			= {atlas = "!Garr_InfoBoxMission-Left", x=0, y=20, x1=0, y1=-20, mirrorLayout = true },
	},
	
	InputBlockSoftEdges = {
		TopRightCorner		= { atlas = "ShadowBorder-Corner", mirrorLayout = true },
		TopLeftCorner		= { atlas = "ShadowBorder-Corner", mirrorLayout = true },
		BottomLeftCorner	= { atlas = "ShadowBorder-Corner", mirrorLayout = true },
		BottomRightCorner	= { atlas = "ShadowBorder-Corner", mirrorLayout = true },
		TopEdge				= { atlas = "_ShadowBorder-Top", },
		BottomEdge			= { atlas = "_ShadowBorder-Top", mirrorLayout = true },
		LeftEdge			= { atlas = "!ShadowBorder-Left", },
		RightEdge			= { atlas = "!ShadowBorder-Left", mirrorLayout = true },
		Center 				= { color = { 0, 0, 0, 1 } },
	},

	EditSelection = {
		TopRightCorner   	= { atlas = "editmode-actionbar-selected-nineslice-corner", mirrorLayout = true, x = 8, y = 8 },
		TopLeftCorner    	= { atlas = "editmode-actionbar-selected-nineslice-corner", mirrorLayout = true, x = -8, y = 8 },
		BottomLeftCorner 	= { atlas = "editmode-actionbar-selected-nineslice-corner", mirrorLayout = true,  x = -8, y = -8 },
		BottomRightCorner	= { atlas = "editmode-actionbar-selected-nineslice-corner", mirrorLayout = true, x = 8, y = -8 },
		TopEdge          	= { atlas = "_editmode-actionbar-selected-nineslice-edgetop" },
		BottomEdge       	= { atlas = "_editmode-actionbar-selected-nineslice-edgebottom" },
		LeftEdge         	= { atlas = "!editmode-actionbar-selected-nineslice-edgeleft" },
		RightEdge        	= { atlas = "!editmode-actionbar-selected-nineslice-edgeright" },
		Center			 	= { atlas = "editmode-actionbar-selected-nineslice-center", x = -8, y = 8, x1 = 8, y1 = -8 }
	},

	EditHighlight = {
		TopRightCorner   	= { atlas = "editmode-actionbar-highlight-nineslice-corner", mirrorLayout = true, x = 8, y = 8 },
		TopLeftCorner    	= { atlas = "editmode-actionbar-highlight-nineslice-corner", mirrorLayout = true, x = -8, y = 8 },
		BottomLeftCorner 	= { atlas = "editmode-actionbar-highlight-nineslice-corner", mirrorLayout = true,  x = -8, y = -8 },
		BottomRightCorner	= { atlas = "editmode-actionbar-highlight-nineslice-corner", mirrorLayout = true, x = 8, y = -8 },
		TopEdge          	= { atlas = "_editmode-actionbar-highlight-nineslice-edgetop" },
		BottomEdge       	= { atlas = "_editmode-actionbar-highlight-nineslice-edgebottom" },
		LeftEdge         	= { atlas = "!editmode-actionbar-highlight-nineslice-edgeleft" },
		RightEdge        	= { atlas = "!editmode-actionbar-highlight-nineslice-edgeright" },
		Center			 	= { atlas = "editmode-actionbar-highlight-nineslice-center", x = -8, y = 8, x1 = 8, y1 = -8 }
	}
};

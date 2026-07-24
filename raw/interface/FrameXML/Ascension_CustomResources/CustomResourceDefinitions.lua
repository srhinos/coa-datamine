CUSTOM_RESOURCE_DEFINITION = {}

function GetCustomResourceInfo(powerType)
	if not powerType then return end
	return CUSTOM_RESOURCE_DEFINITION[powerType]
end

function GetDefaultCustomResourceInfo()
	return CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.Default]
end
-- all
-- -- type: string -- type of resource display
-- -- backgroundAtlas: string -- Atlas name of the background texture
-- -- backgroundTexture: string -- Texture name of the background texture
-- -- showText: boolean -- show text overlay on resource
-- -- maxValue: number -- Maximum value of the resource
-- -- tooltipTitle: string -- Title line of tooltip for the resource
-- -- tooltipText: string -- Text line of tooltip for the resource

-- type: statusbar
-- -- color: CreateColor -- Color of the resource bar
-- -- barAtlas: string -- Atlas name of the fill texture
-- -- barTexture: string -- Texture name of the fill texture
-- -- backgroundColor: CreateColor -- Color of the background
-- -- sparkAtlas: string -- Atlas name of the spark texture
-- -- sparkTexture: string -- Texture name of the spark texture
-- -- isFlipbook: boolean -- Whether the fill texutre is a flipbook or not
-- -- flipbookDefintion: table -- Flipbook definition { atlas, frameWidth, frameHeight, frameCount, fps, oneShot }
-- -- backdrop: table -- Backdrop definition for SetBackdrop

-- type: segmented
-- -- segmentActiveAtlas: string, table -- Atlas name of the active segment atlas - exclusive with segmentActiveTexture
-- -- segmentActiveTexture string, table -- Texture name of the active segment texture - exclusive with segmentActiveAtlas
-- -- segmentInactiveAtlas: string, table -- Atlas name of the inactive segment atlas - exclusive with segmentInactiveTexture
-- -- segmentInactiveTexture: string, table -- Texture name of the inactive segment texture - exclusive with segmentInactiveAtlas
-- -- segmentUseAtlasSize: boolean -- Use the size of the atlas for the segment
-- -- segmentWidth: number, table -- Width of the segment - ignored if segmentUseAtlasSize is true
-- -- segmentHeight: number, table -- Height of the segment - ignored if segmentUseAtlasSize is true
-- -- segmentXOffset: number -- X offset of the first segment
-- -- segmentYOffset: number -- Y offset of the first segment
-- -- segmentSpacing: number -- Spacing between segments


-- Default (-1) fallback value
CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.Default] = {
	type = "statusbar",
	maxValue = 100,
	showText = true,
	color = HIGHLIGHT_FONT_COLOR,
	barAtlas = "ui-frame-bar-fill-white",
	backgroundColor = CreateColor(0, 0, 0, 0.9),
	tooltipTitle = "Undefined Resource",
	backdrop = {
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 12,
	}
}

CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.ShadowOrbs3] = {
	type = "segmented",
	maxValue = 3,
	backgroundAtlas = "shadoworbs-large-Frame",
	width = 159,
	height = 54,
	tooltipTitle = "Shadow Orbs %d/%d",

	segmentActiveAtlas = "shadoworbs-large-Orb",
	segmentInactiveAtlas = "shadoworbs-large-Orb-Bg",
	segmentWidth = 38,
	segmentHeight = 38,
	segmentXOffset = 26,
	segmentYOffset = 0,
	segmentSpacing = -5,
}

CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.ShadowOrbs5] = {
	type = "segmented",
	maxValue = 5,
	backgroundAtlas = "shadoworbs-small-Frame",
	width = 159,
	height = 45,
	tooltipTitle = "Shadow Orbs %d/%d",

	segmentActiveAtlas = "shadoworbs-small-Orb",
	segmentInactiveAtlas = "shadoworbs-small-Orb-Bg",
	segmentWidth = 28,
	segmentHeight = 28,
	segmentXOffset = 17,
	segmentYOffset = 0,
	segmentSpacing = -5,
}

CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.HolyPower3] = {
	type = "segmented",
	maxValue = 3,
	backgroundAtlas = "holy-power-bg",
	backgroundAtlasMax = "holy-power-bg-gold",
	width = 136,
	height = 39,
	tooltipTitle = "Holy Power %d/%d",

	segmentActiveAtlas = {
		"holy-power-rune-1",
		"holy-power-rune-2",
		"holy-power-rune-3",
	},
	segmentUseAtlasSize = true,
	segmentXOffset = 21,
	segmentYOffset = -11,
	segmentSpacing = 0,
}

CUSTOM_RESOURCE_DEFINITION[Enum.CustomPowerType.HolyPower5] = {
	type = "segmented",
	maxValue = 5,
	backgroundAtlas = "uf-holypower-runeholder",
	backgroundAtlasMax = "uf-holypower-runeholder-active",
	width = 150,
	height = 43,
	tooltipTitle = "Holy Power %d/%d",

	segmentActiveAtlas = {
		"uf-holypower-rune1-active",
		"uf-holypower-rune2-active",
		"uf-holypower-rune3-active",
		"uf-holypower-rune4-active",
		"uf-holypower-rune5-active",
	},
	segmentWidth = { 
		21,
		23,
		20,
		18,
		21,
	},
	segmentHeight = { 
		21,
		19,
		18,
		19,
		19,
	},
	segmentXOffset = 17,
	segmentYOffset = -11.5,
	segmentSpacing = 3,
}
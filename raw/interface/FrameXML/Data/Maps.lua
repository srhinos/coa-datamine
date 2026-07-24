WORLD_MAP_LEVELS = {}
WORLD_MAP_LEVELS["Azeroth"] = { 1, 60 }
WORLD_MAP_LEVELS["Kalimdor"] = { 1, 60 }
WORLD_MAP_LEVELS["Durotar"] = { 1, 20 }
WORLD_MAP_LEVELS["Mulgore"] = { 1, 20 }
WORLD_MAP_LEVELS["Barrens"] = { 10, 60 }
WORLD_MAP_LEVELS["Alterac"] = { 30, 60}
WORLD_MAP_LEVELS["Arathi"] = { 30, 60 }
WORLD_MAP_LEVELS["Badlands"] = { 35, 60 }
WORLD_MAP_LEVELS["BlastedLands"] = { 45, 60 }
WORLD_MAP_LEVELS["Tirisfal"] = { 1, 20 }
WORLD_MAP_LEVELS["Silverpine"] = { 10, 60 }
WORLD_MAP_LEVELS["WesternPlaguelands"] = { 51, 60 }
WORLD_MAP_LEVELS["EasternPlaguelands"] = { 53, 60 }
WORLD_MAP_LEVELS["Hilsbrad"] = { 20, 60 }
WORLD_MAP_LEVELS["Hinterlands"] = { 45, 60 }
WORLD_MAP_LEVELS["DunMorogh"] = { 1, 20 }
WORLD_MAP_LEVELS["SearingGorge"] = { 43, 60 }
WORLD_MAP_LEVELS["BurningSteppes"] = { 50, 60 }
WORLD_MAP_LEVELS["Elwynn"] = { 1, 20 }
WORLD_MAP_LEVELS["DeadwindPass"] = { 55, 60 }
WORLD_MAP_LEVELS["Scadeald"] = { 18, 60 }
WORLD_MAP_LEVELS["Palehorn"] = { 18, 60 }
WORLD_MAP_LEVELS["Duskwood"] = { 20, 60 }
WORLD_MAP_LEVELS["LochModan"] = { 10, 60 }
WORLD_MAP_LEVELS["Redridge"] = { 15, 60 }
WORLD_MAP_LEVELS["Stranglethorn"] = { 30, 60 }
WORLD_MAP_LEVELS["SwampOfSorrows"] = { 35, 60 }
WORLD_MAP_LEVELS["Westfall"] = { 10, 60 }
WORLD_MAP_LEVELS["Wetlands"] = { 20, 60 }
WORLD_MAP_LEVELS["Teldrassil"] = { 1, 20 }
WORLD_MAP_LEVELS["Darkshore"] = { 10, 60 }
WORLD_MAP_LEVELS["Ashenvale"] = { 18, 60 }
WORLD_MAP_LEVELS["ThousandNeedles"] = { 25, 60 }
WORLD_MAP_LEVELS["StonetalonMountains"] = { 15, 60 }
WORLD_MAP_LEVELS["Desolace"] = { 30, 60 }
WORLD_MAP_LEVELS["Feralas"] = { 40, 60 }
WORLD_MAP_LEVELS["Dustwallow"] = { 35, 60 }
WORLD_MAP_LEVELS["Tanaris"] = { 40, 60 }
WORLD_MAP_LEVELS["Aszhara"] = { 45, 60 }
WORLD_MAP_LEVELS["Felwood"] = { 48, 60 }
WORLD_MAP_LEVELS["UngoroCrater"] = { 48, 60 }
WORLD_MAP_LEVELS["Silithus"] = { 55, 60 }
WORLD_MAP_LEVELS["Winterspring"] = { 53, 60 }
WORLD_MAP_LEVELS["EversongWoods"] = { 1, 20 }
WORLD_MAP_LEVELS["Ghostlands"] = { 10, 60 }
WORLD_MAP_LEVELS["AzuremystIsle"] = { 1, 20 }
WORLD_MAP_LEVELS["Hellfire"] = { 58, 63 }
WORLD_MAP_LEVELS["Zangarmarsh"] = { 60, 64 }
WORLD_MAP_LEVELS["ShadowmoonValley"] = { 67, 70 }
WORLD_MAP_LEVELS["BladesEdgeMountains"] = { 65, 68 }
WORLD_MAP_LEVELS["BloodmystIsle"] = { 10, 60 }
WORLD_MAP_LEVELS["Nagrand"] = { 64, 67 }
WORLD_MAP_LEVELS["TerokkarForest"] = { 62, 65 }
WORLD_MAP_LEVELS["Netherstorm"] = { 67, 70 }
WORLD_MAP_LEVELS["Northrend"] = { 70, 80 }
WORLD_MAP_LEVELS["BoreanTundra"] = { 68, 72 }
WORLD_MAP_LEVELS["Dragonblight"] = { 71, 75 }
WORLD_MAP_LEVELS["GrizzlyHills"] = { 73, 75 }
WORLD_MAP_LEVELS["HowlingFjord"] = { 68, 72 }
WORLD_MAP_LEVELS["IcecrownGlacier"] = { 77, 80 }
WORLD_MAP_LEVELS["SholazarBasin"] = { 75, 80 }
WORLD_MAP_LEVELS["TheStormPeaks"] = { 77, 80 }
WORLD_MAP_LEVELS["ZulDrak"] = { 74, 77 }
WORLD_MAP_LEVELS["Sunwell"] = { 70, 70 }
WORLD_MAP_LEVELS["LakeWintergrasp"] = { 77, 80 }
WORLD_MAP_LEVELS["CrystalsongForest"] = { 77, 80 }
WORLD_MAP_LEVELS["HrothgarsLanding"] = { 77, 80 }


function GetMapLevelRange(fileName)
	if fileName and WORLD_MAP_LEVELS[fileName] then
		return unpack(WORLD_MAP_LEVELS[fileName])
	end
end
local flags = EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip)

-- Name and description in dbc_global_strings / symbol /av > search objecticon

-- Innkeeper Neutral/Cities

DB_MapPOI.CreatePOI("innkeeper-stormwind",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -8867.366211,
        673.990234,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-ironforge",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -4842.339844,
        -860.934021,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-darnassus",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        10127.900391,
        2224.790039,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-exodar",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -3746.66186,
        -11696.106445,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-orgrimmar",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        1633.126831,
        -4440.422363,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-undercity",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        1635.604248,
        222.772034,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-thunderbluff",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -1300.495239,
        38.068993,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-silvermoon",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        9683.318359,
        -7363.401367,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-silvermoon-two",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        9564.937500,
        -7220.576172,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-shattrath",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -1911.010010,
        5783.000000,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-shattrath-two",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -2182.295898,
        5400.833008,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-dalaran",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        5871.040039,
        493.264008,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("innkeeper-dalaran",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        5871.040039,
        493.264008,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("innkeeper-dalaran-two",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        5847.970215,
        635.434998,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("innkeeper-dalaran-three",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        5716.200195,
        681.836975,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("innkeeper-azzar-faire",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -1736.719971,
        -12046.449951,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "innkeeper",
        0.6,
        nil,
        909
)

-- Tanaris Innkeeper
DB_MapPOI.CreatePOI("Innkeeper-Tanaris",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -7146.733398,
        -3838.801514,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Tanaris Steamwheedle Port Innkeeper
DB_MapPOI.CreatePOI("Innkeeper-SteamwheedlePort",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -6984.109863,
        -4737.060059,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Silithus Innkeeper
DB_MapPOI.CreatePOI("Innkeeper-Silithus",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -6868.040039,
        729.914001,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Eastern Plaguelands
DB_MapPOI.CreatePOI("Innkeeper-Eplaguelands",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        2300.899902,
        -5345.089844,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Winterspring
DB_MapPOI.CreatePOI("Innkeeper-Winterspring",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        6687.750000,
        -4671.450195,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Thorium Point
DB_MapPOI.CreatePOI("Innkeeper-ThoriumPoint",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -6548.830078,
        -1218.160034,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Innkeeper Horde
DB_MapPOI.CreatePOI("innkeeper-mulgore",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -2365.370117,
        -347.309998,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-barrens-tauraio",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -2371.626709,
        -2120.821045,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-barrens-crossroads",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -526.806396,
        -2739.989746,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-stonetalon-mountains",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        893.651978,
        927.947021,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-ashenvale",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        2362.459473,
        -2614.470947,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-durotar",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        340.148987,
        -4686.2700,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-sunstrider-isle",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        9476.910156,
        -6859.209961,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-fairbreeze-village",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        8700.379883,
        -6638.359863,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-ghostlands",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        7553.370117,
        -6897.350098,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-tirisfal-glades",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        2269.510010,
        244.944000,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-silverpine-forest",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        510.915985,
        1636.469971,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

-- Thousand Needles
DB_MapPOI.CreatePOI("Innkeeper-TNeedles",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -5477.850098,
        -2460.429932,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Hillsbrad Foothills
DB_MapPOI.CreatePOI("Innkeeper-TarrenMill",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -9.826230,
        -938.625000,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Hillsbrad Foothills
DB_MapPOI.CreatePOI("Innkeeper-TarrenMill",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -9.826230,
        -938.625000,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Feralas
DB_MapPOI.CreatePOI("Innkeeper-CampMojache",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -4346.279785,
        264.605988,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Badlands
DB_MapPOI.CreatePOI("Innkeeper-Badlands",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -6649.170410,
        -2149.094727,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- The Hinterlands
DB_MapPOI.CreatePOI("Innkeeper-Hinterlands",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -621.592590,
        -4583.232910,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Swamp of Sorrows
DB_MapPOI.CreatePOI("Innkeeper-SOS",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -10487.299805,
        -3258.840088,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Desolace
DB_MapPOI.CreatePOI("Innkeeper-Desolace",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -1592.839966,
        3150.270020,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Innkeeper Alliance

-- Dustwallow Marsh
DB_MapPOI.CreatePOI("Innkeeper-DM",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -3616.129883,
        -4470.819824,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Hillsbrad Foothills
DB_MapPOI.CreatePOI("Innkeeper-SS",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -850.674988,
        -576.974976,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        0
)
-- The Hinterlands
DB_MapPOI.CreatePOI("Innkeeper-Hinterlandstwo",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        395.549316,
        -2100.839600,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        0
)

-- Ashenvale
DB_MapPOI.CreatePOI("Innkeeper-Ashenvale",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        2746.370117,
        -419.890015,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Feralas
DB_MapPOI.CreatePOI("Innkeeper-Feralastwo",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -4381.589844,
        3289.449951,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

-- Desolace
DB_MapPOI.CreatePOI("Innkeeper-Desolacetwo",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        257.791687,
        1254.107910,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-goldshire",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -9462.660156,
        16.191500,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-westfall",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -10653.400391,
        1166.520020,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-redridge-mountains",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -9215.330078,
        -2151.040039,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-duskwood",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -10515.000000,
        -1159.739990,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-dun-morogh",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -5601.600098,
        -531.203003,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-loch-modan",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -5378.009766,
        -2973.739990,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-wetlands",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -3826.840088,
        -833.809021,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("innkeeper-dolanaar",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        9742.689453,
        897.779358,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-darkshore",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        6409.669922,
        513.382996,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("innkeeper-azuremyst-isle",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -4129.430176,
        -12469.000000,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("innkeeper-bloodmyst-isle",
        MINIMAP_TRACKING_INNKEEPER,
        MINIMAP_TRACKING_INNKEEPER_DESC,
        -2059.199951,
        -11897.000000,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "innkeeper",
        0.6,
        nil,
        530
)


-- Sanguine Workbench
DB_MapPOI.CreatePOI("workbench-stormwind",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        -8862.899414,
        616.947327,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("workbench-orgrimmar",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        1742.633789,
        -4318.604492,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("workbench-ironforge",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        -4866.087891,
        -878.647583,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("workbench-darnassus",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        10166.886719,
        2578.441162,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("workbench-undercity",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        1636.165527,
        199.330872,
        -43.10198,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("workbench-thunderbluff",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        -1236.846680,
        113.437126,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("workbench-silvermoon",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        9572.036133,
        -7060.256348,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("workbench-exodar",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        -3691.738770,
        -11493.490234,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("workbench-dalaran",
        SPELL_FOCUS_OBJECT_1651,
        SPELL_FOCUS_OBJECT_1651_DESC,
        5760.812500,
        737.489746,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "vehicle-hammergold",
        0.5,
        nil,
        571
)

-- Mythic+ Services
DB_MapPOI.CreatePOI("mythicservice-stormwind",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        -8436.419922,
        399.553986,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("mythicservice-orgrimmar",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        1900.880005,
        -4141.290039,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("mythicservice-undercity",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        1544.099976,
        261.652008,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("mythicservice-ironforge",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        -4874.649902,
        -1040.219971,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("mythicservice-booty-bay",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        -14453.700195,
        450.992004,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("mythicservice-shattrath",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        -1853.890015,
        5427.649902,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("mythicservice-dalaran",
        MINIMAP_TRACKING_MYTHICVENDOR,
        MINIMAP_TRACKING_MYTHICVENDOR_DESC,
        5807.025879,
        659.095581,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "upgradeitem-32x32",
        0.5,
        nil,
        571
)

-- Tier Token Exchange
DB_MapPOI.CreatePOI("tokenexchange-stormwind",
        POI_TIER_TOKEN_EXCHANGE,
        POI_TIER_TOKEN_EXCHANGE_DESC,
        -8985.585938,
        555.764832,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "timewalkingvendor-32x32",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("tokenexchange-orgrimmar",
        POI_TIER_TOKEN_EXCHANGE,
        POI_TIER_TOKEN_EXCHANGE_DESC,
        1561.904175,
        -4408.138184,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "timewalkingvendor-32x32",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("tokenexchange-shattrath-aldor",
        POI_TIER_TOKEN_EXCHANGE,
        POI_TIER_TOKEN_EXCHANGE_DESC,
        -1732.967651,
        5820.188965,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "timewalkingvendor-32x32",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("tokenexchange-shattrath-scryer",
        POI_TIER_TOKEN_EXCHANGE,
        POI_TIER_TOKEN_EXCHANGE_DESC,
        -2273.301514,
        5574.696289,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "timewalkingvendor-32x32",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("tokenexchange-dalaran",
        POI_TIER_TOKEN_EXCHANGE,
        POI_TIER_TOKEN_EXCHANGE_DESC,
        5907.412109,
        737.568115,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "timewalkingvendor-32x32",
        0.45,
        nil,
        571
)

-- Heroes Callboard
DB_MapPOI.CreatePOI("callboard-barrens",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -442.536560,
        -2582.517090,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-westfall",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -10679.592773,
        1025.414429,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "warboard",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("callboard-stormwind",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -8825.550781,
        629.389832,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("callboard-ironforge",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -4899.702148,
        -963.564209,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("callboard-darnassus",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        9941.015625,
        2275.197021,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-exodar",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -3934.833008,
        -11634.648438,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("callboard-orgrimmar",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        1584.101196,
        -4422.290527,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-thunderbluff",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -1258.383423,
        70.345734,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-undercity",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        1558.452148,
        239.822388,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("callboard-silvermoon",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        9488.196289,
        -7270.505859,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("callboard-boot-bay",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -14369.781250,
        427.079468,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("callboard-tanaris",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -7192.427246,
        -3787.233887,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-ratchet",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -945.128235,
        -3699.032227,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-winterspring",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        6724.539062,
        -4660.925293,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("callboard-shattrath-horde",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -1919.585327,
        5458.989258,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("callboard-shattrath-alliance",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        -1808.115967,
        5399.984375,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("callboard-dalaran-horde",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        5888.581543,
        559.382874,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        571
)

DB_MapPOI.CreatePOI("callboard-dalaran-alliance",
        POI_CALLBOARD,
        POI_CALLBOARD_DESC,
        5737.488770,
        738.259949,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "warboard",
        0.45,
        nil,
        571
)

-- Honor and Arena Quatermaster
DB_MapPOI.CreatePOI("honorvendor-stormwind",
        POI_HONOR_VENDOR,
        POI_HONOR_VENDOR_DESC,
        -8773.740234,
        416.380981,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "allianceassaultsmapbanner",
        0.4,
        nil,
        0
)

DB_MapPOI.CreatePOI("honorvendor-orgrimmar",
        POI_HONOR_VENDOR,
        POI_HONOR_VENDOR_DESC,
        1637.056885,
        -4243.831543,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "hordeassaultsmapbanner",
        0.4,
        nil,
        1
)

-- Wildcard, Draft and Skill Card Service
DB_MapPOI.CreatePOI("draftvendor-stormwind",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        -8851.8037109375,
        638.12274169922,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        0,
        454
)

DB_MapPOI.CreatePOI("draftvendor-ironforge",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        -4915.859375,
        -974.931885,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        0,
        454
)

DB_MapPOI.CreatePOI("draftvendor-darnassus",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        9942.487305,
        2315.216797,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        1,
        454
)

DB_MapPOI.CreatePOI("draftvendor-exodar",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        -3913.600098,
        -11628.490234,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        530,
        454
)

DB_MapPOI.CreatePOI("draftvendor-orgrimmar",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        1657.1072998047,
        -4432.4375,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        1,
        454
)

DB_MapPOI.CreatePOI("draftvendor-thunderbluff",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        -1274.086670,
        120.500519,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        1,
        454
)

DB_MapPOI.CreatePOI("draftvendor-undercity",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        1576.945923,
        271.494324,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        0,
        454
)

DB_MapPOI.CreatePOI("draftvendor-silvermoon",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        9491.219727,
        -7305.401367,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        530,
        454
)

DB_MapPOI.CreatePOI("draftvendor-shattrath",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        -1809.510864,
        5305.564941,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        530,
        454
)

DB_MapPOI.CreatePOI("draftvendor-dalaran",
        POI_DRAFT_VENDOR,
        POI_DRAFT_VENDOR_DESC,
        5782.182129,
        634.766541,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "legionfallmapbanner",
        0.45,
        nil,
        571,
        454
)

-- Cosmetic and Recovery Services
DB_MapPOI.CreatePOI("etherealservices-stormwind",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -8801.412109375,
        668.78961181641,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("etherealservices-darnassus",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        9945.508789,
        2488.440186,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("etherealservices-ironforge",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -4968.819824,
        -910.854980,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("etherealservices-exodar",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -4017.938965,
        -11721.445312,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("etherealservices-orgrimmar",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        1679.0261230469,
        -4437.4584960938,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("etherealservices-thunderbluff",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -1210.209961,
        94.858704,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        1
)

DB_MapPOI.CreatePOI("etherealservices-undercity",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        1547.434570,
        185.782883,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        0
)

DB_MapPOI.CreatePOI("etherealservices-silvermoon",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        9623.045898,
        -7153.159668,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("etherealservices-silvermoon-tow",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        9666.706055,
        -7515.448242,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("etherealservices-shattrath",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -1999.829468,
        5359.770020,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("etherealservices-shattrath-two",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        -1732.593262,
        5497.327637,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        530
)

DB_MapPOI.CreatePOI("etherealservices-dalaran",
        POI_ETHEREAL_SERVICES,
        POI_ETHEREAL_SERVICES_DESC,
        5820.548828,
        492.120117,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-transmogrifier",
        0.45,
        nil,
        571
)

-- Build Reset Gabril Mewell
DB_MapPOI.CreatePOI("gabril-mewell",
        GABRIL_MEWELL,
        "",
        7799.080078125,
        -2443.6499023438,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-gabril-mewell",
        0.45,
        nil,
        1
)

-- Azzar Faire Pois test
DB_MapPOI.CreatePOI("mailbox-azzar",
        MINIMAP_TRACKING_MAILBOX,
        "",
        -1460.226318,
        -12071.519043,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mailbox",
        0.6,
        nil,
        909
)
DB_MapPOI.CreatePOI("mailbox-azzar2",
        MINIMAP_TRACKING_MAILBOX,
        "",
        -1722.390381,
        -12037.133057,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mailbox",
        0.6,
        nil,
        909
)

-- Banker
DB_MapPOI.CreatePOI("banker-orgrimmar",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        1601.956665,
        -4367.102051,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("banker-silvermoon",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        9783.420898,
        -7490.740723,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("banker-undercity",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        1605.992920,
        240.846542,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("banker-thunderbluff",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -1257.630005,
        19.557699,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("banker-stormwind",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -8935.269531,
        613.135010,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("banker-ironforge",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -4888.767090,
        -994.482056,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("banker-darnassus",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        9942.030273,
        2519.239990,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("banker-exodar",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -3920.056641,
        -11596.216797,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("banker-aldor",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -1718.142334,
        5484.661133,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("banker-scryer",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -2012.771729,
        5375.611816,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("banker-booty-bay",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -14421.900391,
        528.898010,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("banker-gadgetzan",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        -7205.840332,
        -3828.974365,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "banker",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("banker-dalaran-horde",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        5967.278809,
        613.716064,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        571
)

DB_MapPOI.CreatePOI("banker-dalaran-alliance",
        MINIMAP_TRACKING_BANKER,
        MINIMAP_TRACKING_BANKER_DESC,
        5640.949707,
        687.572144,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "banker",
        0.5,
        nil,
        571
)

-- Barber
DB_MapPOI.CreatePOI("barber-orgrimmar",
        MINIMAP_TRACKING_BARBER,
        MINIMAP_TRACKING_BARBER_DESC,
        1762.387695,
        -4345.450684,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "barbershop-32x32",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("barber-undercity",
        MINIMAP_TRACKING_BARBER,
        MINIMAP_TRACKING_BARBER_DESC,
        1574.428101,
        189.935181,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "barbershop-32x32",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("barber-stormwind",
        MINIMAP_TRACKING_BARBER,
        MINIMAP_TRACKING_BARBER_DESC,
        -8744.811523,
        655.308472,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "barbershop-32x32",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("barber-ironforge",
        MINIMAP_TRACKING_BARBER,
        MINIMAP_TRACKING_BARBER_DESC,
        -4829.971680,
        -919.988770,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "barbershop-32x32",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("barber-dalaran",
        MINIMAP_TRACKING_BARBER,
        MINIMAP_TRACKING_BARBER_DESC,
        5891.339844,
        635.432007,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "barbershop-32x32",
        0.5,
        nil,
        571
)

-- Millhouse Manastorm
DB_MapPOI.CreatePOI("manastorm-orgrimmar",
        MINIMAP_TRACKING_MANASTORM,
        MINIMAP_TRACKING_MANASTORM_DESC,
        1583.474243,
        -4395.760254,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "adventures-32x32",
        0.5,
        nil,
        1,
        411
)

DB_MapPOI.CreatePOI("manastorm-stormwind",
        MINIMAP_TRACKING_MANASTORM,
        MINIMAP_TRACKING_MANASTORM_DESC,
        -8889.685547,
        587.402649,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.EventRequired),
        "adventures-32x32",
        0.5,
        nil,
        0,
        411
)

-- Auctioneer
DB_MapPOI.CreatePOI("auctioneer-orgrimmar",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        1681.450562,
        -4464.546387,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("auctioneer-undercity",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        1610.680054,
        292.850006,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("auctioneer-thunderbluff",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -1224.823608,
        86.476784,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("auctioneer-silvermoon-one",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        9682.830078,
        -7524.370117,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("auctioneer-silvermoon-two",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        9641.820312,
        -7135.549805,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("auctioneer-undercity",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        1610.680054,
        292.850006,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("auctioneer-stormwind",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -8833.483398,
        664.168274,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("auctioneer-ironforge",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -4948.009766,
        -901.528015,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("auctioneer-darnassus",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        9863.736328,
        2340.614746,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("auctioneer-exodar",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -4025.489990,
        -11736.000000,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "auctioneer",
        0.5,
        nil,
        530
)

DB_MapPOI.CreatePOI("auctioneer-booty-bay",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -14417.929688,
        519.226379,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("auctioneer-gadgetzan",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -7192.790039,
        -3734.085449,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("auctioneer-steamwheedleport",
        MINIMAP_TRACKING_AUCTIONEER,
        MINIMAP_TRACKING_AUCTIONEER_DESC,
        -6878.919922,
        -4795.879883,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "auctioneer",
        0.5,
        nil,
        1
)

-- Challenger
DB_MapPOI.CreatePOI("challenger-orgrimmar",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        1553.204956,
        -4449.532715,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "poi-torghast",
        0.3,
        nil,
        1
)

DB_MapPOI.CreatePOI("challenger-valley-of-trials",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -601.892029,
        -4241.609863,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        1
)

DB_MapPOI.CreatePOI("challenger-camp-narache",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -2935.949951,
        -264.634003,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        1
)

DB_MapPOI.CreatePOI("challenger-sunstrider-isle",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        10361.200195,
        -6369.020020,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        530
)

DB_MapPOI.CreatePOI("challenger-tirisfal-glades",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        1660.258057,
        1691.892212,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        0
)

DB_MapPOI.CreatePOI("challenger-stormwind",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -8868.676758,
        568.466675,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        0
)

DB_MapPOI.CreatePOI("challenger-northshire-valley",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -8943.839844,
        -121.512383,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        0
)

DB_MapPOI.CreatePOI("challenger-coldridge-valley",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -6219.040039,
        337.871002,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        0
)

DB_MapPOI.CreatePOI("challenger-ammen-vale",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        -3973.649902,
        -13923.900391,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        530
)

DB_MapPOI.CreatePOI("challenger-shadowglen",
        MINIMAP_TRACKING_STONYTARK,
        MINIMAP_TRACKING_STONYTARK_DESC,
        10313.299805,
        819.546997,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "poi-torghast",
        0.3,
        nil,
        1
)

-- Sawmill
DB_MapPOI.CreatePOI("Sawmill-Elwynn-Forest",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -9545.330078,
        -1401.099976,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Stormwind",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -8298.108398,
        1119.301392,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Orgrimmar",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        1674.092651,
        -4069.131348,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Dun-Morogh",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -5765.702148,
        -1276.353149,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Durotar",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        745.155457,
        -4278.216797,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Stranglethorn-Vale-1",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -11989.666992,
        -549.956543,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Stranglethorn-Vale-2",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -11638.386719,
        -633.764160,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Western-Plaguelands",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        2887.013672,
        -1564.339233,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-GrizzlyHills-1",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        4180.872070,
        -2977.637207,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("Sawmill-GrizzlyHills-2",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        4287.412598,
        -3167.675293,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        571
)

DB_MapPOI.CreatePOI("Sawmill-Mulgore",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -2216.875977,
        -311.122406,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Teldrassil",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        9859.400391,
        987.619995,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Eversong-Woods",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        9572.593750,
        -6834.431641,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("Sawmill-Azuremyst-Isle",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -4193.305664,
        -12441.392578,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("Sawmill-Westfall",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -10644.599609,
        1114.700562,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Redridge-Mountains",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -9212.009766,
        -2713.989258,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-Theramore-Isle",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -3676.786377,
        -4373.960449,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Stonetalon-Mountains",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        1238.145142,
        6.119975,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("Sawmill-Tirisfal",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        2188.099121,
        266.035706,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("Sawmill-TarrenMill",
        MINIMAP_TRACKING_SAWMILL,
        MINIMAP_TRACKING_SAWMILL_DESC,
        -143.545715,
        -855.773865,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "lumber_tracking",
        0.6,
        nil,
        0
)

-- Outland Portal
DB_MapPOI.CreatePOI("outland-portal-orgrimmar",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        1472.137451,
        -4216.292480,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("outland-portal-undercity",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        1767.632690,
        55.886372,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        0
)


DB_MapPOI.CreatePOI("outland-portal-thunderbluff",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        -943.935242,
        274.811676,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("outland-portal-silvermoon",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        9984.299805,
        -7107.589844,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "mageportalhorde",
        0.6,
        nil,
        530
)

DB_MapPOI.CreatePOI("outland-portal-stormwind",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        -9006.859375,
        870.983704,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "mageportalhorde",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("outland-portal-ironforge",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        -4605.175293,
        -928.726868,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("outland-portal-darnassus",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        9660.458008,
        2508.487549,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        1
)

DB_MapPOI.CreatePOI("outland-portal-exodar",
        MINIMAP_TRACKING_PORTAL_BL,
        MINIMAP_TRACKING_PORTAL_BL_DESC,
        -4037.900391,
        -11555.793945,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalhorde",
        0.6,
        nil,
        530
)

-- Horde Zeppelin
-- Durotar West Tower > Borean Tundra > Thunder Bluff
DB_MapPOI.CreatePOI("zeppelin-durotar-W",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_DTW,
        1162.105469,
        -4156.489258,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.5,
        nil,
        1
)


-- Durotar West East > STV > Tirisfal Glades
DB_MapPOI.CreatePOI("zeppelin-durotar-E",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_DTE,
        1342.829712,
        -4648.950195,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.5,
        nil,
        1
)


-- Tirisfal Glades > Orgrimmar, STV & Howling Fjord.
DB_MapPOI.CreatePOI("zeppelin-Tirisfal",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_TGM,
        2075.361816,
        299.586853,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.5,
        nil,
        0
)


-- Stranglethorn Vale > Orgrimmar & Tirisfal Glades
DB_MapPOI.CreatePOI("zeppelin-STV-O",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_STV,
        -12476.496094,
        319.229492,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.4,
        nil,
        0
)

-- Thunderbluff > Orgrimmar
DB_MapPOI.CreatePOI("zeppelin-TB-O",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_DT,
        -1027.984741,
        357.532654,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.5,
        nil,
        1
)

-- Borean Tundra > Orgrimmar
DB_MapPOI.CreatePOI("zeppelin-BT-O",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_DT,
        2834.733643,
        6174.400391,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.4,
        nil,
        571
)

-- Alliance Boats/Ferry
-- Stormwind Boat > Auberdine
DB_MapPOI.CreatePOI("boat-SW-ad",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_AD,
        -8646.875977,
        1329.842529,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        0
)

-- Stormwind Boat > Borean Tundra
DB_MapPOI.CreatePOI("boat-SW-BT",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_ZEPPELIN_DESC_BT,
        -8290.591797,
        1405.350342,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        0
)

-- Howling Fjord > Tirisfal Glades
DB_MapPOI.CreatePOI("zeppelin-HF-TG",
        MINIMAP_TRACKING_ZEPPELIN,
        MINIMAP_TRACKING_ZEPPELIN_DESC_TG,
        1929.592041,
        -6306.661133,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "vehicle-air-horde",
        0.5,
        nil,
        571
)


-- Borean Tundra > Stormwind
DB_MapPOI.CreatePOI("boat-BT-SW",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_SW,
        2232.438477,
        5133.823730,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        571
)


-- Teldrassil> Darkshore
DB_MapPOI.CreatePOI("boat-TS-DS",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_DS,
        8548.287109,
        1021.011292,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        1
)

-- Darkshore > Teldrassil
DB_MapPOI.CreatePOI("boat-DS-TS",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_TD,
        6580.424316,
        768.529419,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        1
)


-- Darkshore > Stormwind
DB_MapPOI.CreatePOI("boat-DS-SW",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_SW,
        6419.496094,
        819.019531,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        1
)

-- Darkshore > Azuremyst Isles
DB_MapPOI.CreatePOI("boat-DS-AZ",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_AI,
        6541.164551,
        921.107239,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        1
)

-- Azuremyst Isles> Darkshore
DB_MapPOI.CreatePOI("boat-AZ-DS",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_DS,
        -4263.910156,
        -11333.952148,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        530
)

-- Wetlands > Dustwallow Marsh
DB_MapPOI.CreatePOI("boat-WL-DW",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_DM,
        -3897.170898,
        -599.227722,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        0
)

-- Dustwallow Marsh > Wetlands
DB_MapPOI.CreatePOI("boat-DW-WL",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_WL,
        -4006.913330,
        -4729.120605,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "flightmasterferry",
        0.5,
        nil,
        1
)

-- Ratchet > Booty Bay
DB_MapPOI.CreatePOI("boat-RT-BB",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_BB,
        -998.767944,
        -3825.943115,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "flightmasterferry",
        0.5,
        nil,
        1
)

-- Booty Bay > Ratchet
DB_MapPOI.CreatePOI("boat-BB-RT",
        MINIMAP_TRACKING_BOAT,
        MINIMAP_TRACKING_BOAT_DESC_RT,
        -14276.489258,
        577.471252,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "flightmasterferry",
        0.5,
        nil,
        0
)

-- Travel Portals
-- Alliance Cities/Zones
-- Wetlands > Darkshore
DB_MapPOI.CreatePOI("portal-WL-DS",
        MINIMAP_TRACKING_PORTAL,
        MINIMAP_TRACKING_PORTAL_DS,
        -3733.720215,
        -578.628296,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "mageportalalliance",
        0.6,
        nil,
        0
)

-- Darnassus > Stormwind
DB_MapPOI.CreatePOI("portal-DRS-SW",
        MINIMAP_TRACKING_PORTAL,
        MINIMAP_TRACKING_PORTAL_SW,
        9922.728516,
        2616.345703,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "mageportalalliance",
        0.6,
        nil,
        1
)

-- Horde Cities
-- Silvermoon City > Undercity
DB_MapPOI.CreatePOI("portal-SC-UC",
        MINIMAP_TRACKING_PORTAL,
        MINIMAP_TRACKING_PORTAL_UC,
        10031.313477,
        -6998.297363,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "mageportalalliance",
        0.6,
        nil,
        530
)

-- Undercity > Silvermoon City
DB_MapPOI.CreatePOI("portal-UC-SC",
        MINIMAP_TRACKING_PORTAL,
        MINIMAP_TRACKING_PORTAL_SC,
        1808.564087,
        348.812561,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.OnlyInCity, Enum.POIFlags.HasTooltip, Enum.POIFlags.HordeOnly),
        "mageportalalliance",
        0.6,
        nil,
        0
)

-- Deeprun Tram
-- Deeprun Tram IF > SW
DB_MapPOI.CreatePOI("Deeprun-tram-IF",
        DUNGEON_FLOOR_DEEPRUNTRAM1,
        DUNGEON_FLOOR_DEEPRUNTRAM1_DESC,
        -4838.758789,
        -1317.349487,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "vehicle-silvershardmines-minecart",
        0.5,
        nil,
        0
)

-- Deeprun Tram SW > IF
DB_MapPOI.CreatePOI("Deeprun-tram-SW",
        DUNGEON_FLOOR_DEEPRUNTRAM1,
        MINIMAP_TRACKING_PORTAL_IF,
        -8363.381836,
        535.214844,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.AllianceOnly),
        "vehicle-silvershardmines-minecart",
        0.5,
        nil,
        0
)

--
-- enchanting altars
--
DB_MapPOI.CreatePOI("mystic-altar-kara",
        ANCIENT_ENCHANTING_ALTAR,
        ANCIENT_ENCHANTING_ALTAR_HINT_KARA,
        -10941.6,
        -1871.67,
        -16.862,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.ShowOnMinimap, Enum.POIFlags.HasTooltip),
        188,
        1.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("mystic-altar-alterac",
        ANCIENT_ENCHANTING_ALTAR,
        ANCIENT_ENCHANTING_ALTAR_HINT_ALTERAC,
        36.21,
        342.62,
        48.905,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.ShowOnMinimap, Enum.POIFlags.HasTooltip),
        188,
        1.5,
        nil,
        0
)

DB_MapPOI.CreatePOI("mystic-altar-azshara",
        ANCIENT_ENCHANTING_ALTAR,
        ANCIENT_ENCHANTING_ALTAR_HINT_AZSHARA,
        4005.06,
        -4779.81,
        305.894,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.ShowOnMinimap, Enum.POIFlags.HasTooltip),
        188,
        1.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("mystic-altar-silithus",
        ANCIENT_ENCHANTING_ALTAR,
        ANCIENT_ENCHANTING_ALTAR_HINT_SILITHUS,
        -6808.13,
        1649.57,
        7.461,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.ShowOnMinimap, Enum.POIFlags.HasTooltip),
        188,
        1.5,
        nil,
        1
)

DB_MapPOI.CreatePOI("initial-point-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        5394.708496,
        -4697.562988,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5379.400391,
        -4723.151855,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        5448.384277,
        -4653.895508,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        5449.389160,
        -4717.130859,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        5448.375488,
        -4741.907227,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-4-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK4,
        "",
        5493.394531,
        -4706.640625,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        5476.557617,
        -4687.207031,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        5261.499512,
        -4680.468262,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5274.706543,
        -4701.034668,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        5175.955078,
        -4708.354492,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        5227.483398,
        -4747.626465,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        5256.114746,
        -4717.077148,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-mechagnomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        5250.214844,
        -4685.333984,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        5279.312012,
        -4405.557617,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5296.092285,
        -4395.605957,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        5278.911133,
        -4387.957031,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        5227.072266,
        -4318.294922,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        5158.250488,
        -4375.888184,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-4-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK4,
        "",
        5214.291992,
        -4440.897949,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        5261.972656,
        -4423.145508,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        5280.372070,
        -4148.907227,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5293.480957,
        -4124.354492,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        5261.811035,
        -4124.179688,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        5217.100098,
        -4095.910645,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        5167.125488,
        -4148.089355,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-4-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK4,
        "",
        5217.096191,
        -4200.448730,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        5262.222656,
        -4163.258301,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        5286.883789,
        -3849.472656,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5297.186035,
        -3832.566650,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        5217.918457,
        -3803.212646,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        5169.569336,
        -3850.071289,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        5217.922363,
        -3900.656006,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        5254.432617,
        -3870.794434,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        4982.856445,
        -3838.455811,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        4998.801758,
        -3830.615967,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        4921.590820,
        -3901.928467,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        4870.913574,
        -3851.842041,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        4921.609375,
        -3801.152832,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        4921.381348,
        -3852.714844,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        4984.728027,
        -4155.804688,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        5000.153809,
        -4135.359375,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        4921.760742,
        -4200.517578,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        4870.297852,
        -4148.609863,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        4921.487793,
        -4096.615234,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-darkiron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        4974.356934,
        -4148.482910,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        4996.769043,
        -4376.000000,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        4996.923828,
        -4347.997070,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        4974.611328,
        -4378.435547,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        4923.101562,
        -4327.022949,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        4869.081543,
        -4380.166992,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-4-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK4,
        "",
        4923.032227,
        -4432.433594,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-5-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK5,
        "",
        4952.968262,
        -4408.480957,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        4959.365234,
        -4378.438477,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("initial-point-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_START,
        "",
        4993.357422,
        -4698.703613,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "starting-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("exit-portal-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EXIT,
        "",
        4998.549805,
        -4679.746582,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-1-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK1,
        "",
        4915.107910,
        -4645.082520,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-2-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK2,
        "",
        4867.089355,
        -4695.733398,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("checkpoint-3-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_CHECK3,
        "",
        4918.540039,
        -4751.889648,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "checkpoint",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("finish-point-vertical-titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_FINISH,
        "",
        4967.481445,
        -4715.018555,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "finish-point",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_kultiran",
        MINIMAP_TRACKING_AZZAR_VERTICAL_KULTIRAN,
        "",
        5702.877441,
        -4704.628906,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_mechanomic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_MECHANOMIC,
        "",
        5707.178711,
        -4677.343750,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_titanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_TITANIC,
        "",
        5728.180176,
        -4659.351562,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_volcanic",
        MINIMAP_TRACKING_AZZAR_VERTICAL_VOLCANIC,
        "",
        5756.965820,
        -4660.731934,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_emerald",
        MINIMAP_TRACKING_AZZAR_VERTICAL_EMERALD,
        "",
        5777.699707,
        -4676.707520,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_naga",
        MINIMAP_TRACKING_AZZAR_VERTICAL_NAGA,
        "",
        5785.743164,
        -4704.895996,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_dark_iron",
        MINIMAP_TRACKING_AZZAR_VERTICAL_DARK_IRON,
        "",
        5768.725098,
        -4729.046875,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_zandalari",
        MINIMAP_TRACKING_AZZAR_VERTICAL_ZANDALARI,
        "",
        5742.458008,
        -4738.892578,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

DB_MapPOI.CreatePOI("portal_vertical_legion",
        MINIMAP_TRACKING_AZZAR_VERTICAL_LEGION,
        "",
        5716.019531,
        -4730.439941,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "exit-portal",
        0.6,
        nil,
        960
)

--DB_MapPOI.CreatePOI("broken-dreams",
--        MINIMAP_TRACKING_AZZAR_BROKEN_DREAMS,
--        MINIMAP_TRACKING_AZZAR_BROKEN_DREAMS_DESC,
--        -1859.584961,
--        -12059.031250,
--        0,
--        Enum.POIType.Townsfolk,
--        flags,
--        "poi-workorders",
--        0.6,
--        nil,
--        909
--)

DB_MapPOI.CreatePOI("azzar-faire-alliance",
        MINIMAP_TRACKING_AZZAR_FAIRE_ENTRACE,
        MINIMAP_TRACKING_AZZAR_FAIRE_ENTRACE_DESC,
        -8966.068359,
        408.924988,
        0,
        Enum.POIType.Townsfolk,
        flags,
        "azzar-faire",
        0.6,
        nil,
        0
)

DB_MapPOI.CreatePOI("azzar-faire-horde",
        MINIMAP_TRACKING_AZZAR_FAIRE_ENTRACE,
        MINIMAP_TRACKING_AZZAR_FAIRE_ENTRACE_DESC,
        1289.296875,
        -4338.187988,
        0,
        Enum.POIType.Townsfolk,
        EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip),
        "azzar-faire",
        0.6,
        nil,
        1
)



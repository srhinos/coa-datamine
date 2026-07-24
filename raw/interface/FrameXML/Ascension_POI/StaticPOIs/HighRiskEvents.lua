if not C_PVP:IsLegacyWarmode() then
    return
end

local flags = EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HighRiskOnly)
-- Herb Events
DB_MapPOI.CreatePOI("highrisk-herb-burningsteppes",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Dreadmaul Rock", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7765.802734375,
        -2626.4174804688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        0,
        1111
)

DB_MapPOI.CreatePOI("highrisk-herb-easternplaguelands",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Plaguewood", C_PVP:GetRequiredItemLevelForEvents()) end,
        3093.0808105469,
        -3428.7429199219,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        0,
        1117
)

DB_MapPOI.CreatePOI("highrisk-herb-westernplaguelands",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Ruins of Andorhal", C_PVP:GetRequiredItemLevelForEvents()) end,
        1452.2515869141,
        -1522.4396972656,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        0,
        1127
)

DB_MapPOI.CreatePOI("highrisk-herb-ungoro",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Terror Run", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7796.0146484375,
        -799.00280761719,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        1,
        1106
)

DB_MapPOI.CreatePOI("highrisk-herb-silithus",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Hive Ashi", C_PVP:GetRequiredItemLevelForEvents()) end,
        -6543.1264648438,
        999.37768554688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        1,
        1128
)

DB_MapPOI.CreatePOI("highrisk-herb-winterspring",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Hidden Grove", C_PVP:GetRequiredItemLevelForEvents()) end,
        7767.6845703125,
        -4804.0405273438,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        1,
        1134
)

DB_MapPOI.CreatePOI("highrisk-herb-winterspring2",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Owlwing Thicket", C_PVP:GetRequiredItemLevelForEvents()) end,
        5645.5756835938,
        -4987.947265625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        1,
        1134
)

DB_MapPOI.CreatePOI("highrisk-herb-azshara",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Shattered Strand", C_PVP:GetRequiredItemLevelForEvents()) end,
        3550.5798339844,
        -5630.5869140625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        1,
        1101
)


DB_MapPOI.CreatePOI("highrisk-herb-terokkar",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Tuurem", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2162.5122070313,
        4218.392578125,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        929
)

DB_MapPOI.CreatePOI("highrisk-herb-zangarmarsh",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Bloodscale Grounds & Bloodscale Enclave", C_PVP:GetRequiredItemLevelForEvents()) end,
        553.84020996094,
        6291.3627929688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        934
)

DB_MapPOI.CreatePOI("highrisk-herb-zangarmarsh2",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Bloodscale Grounds & Bloodscale Enclave", C_PVP:GetRequiredItemLevelForEvents()) end,
        519.06427001953,
        8143.435546875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        934
)

DB_MapPOI.CreatePOI("highrisk-herb-nagrand",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "The Spirit Fields", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2409.3669433594,
        8114.951171875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        939
)

DB_MapPOI.CreatePOI("highrisk-herb-bladesedge",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Raven's Wood", C_PVP:GetRequiredItemLevelForEvents()) end,
        3538.7563476563,
        7018.7036132813,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        944
)

DB_MapPOI.CreatePOI("highrisk-herb-shadowmoon",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Coilskar Point & Coilskar Cistern", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2980.4145507813,
        1726.9273681641,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        951
)

DB_MapPOI.CreatePOI("highrisk-herb-shadowmoon2",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "Coilskar Point & Coilskar Cistern", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2876.0991210938,
        1301.8514404297,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        951
)

DB_MapPOI.CreatePOI("highrisk-herb-netherstorm",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "The Ruins of Enkaat & The Arklon Ruins", C_PVP:GetRequiredItemLevelForEvents()) end,
        3443.7600097656,
        3680.3100585938,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        958
)

DB_MapPOI.CreatePOI("highrisk-herb-netherstorm2",
        EVENT_HR_MATERIALS_HERB,
        function() return format(EVENT_HR_MATERIALS_HERB_DESC, "The Ruins of Enkaat & The Arklon Ruins", C_PVP:GetRequiredItemLevelForEvents()) end,
        2754.0402832031,
        3160.0346679688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-herb",
        0.32,
        nil,
        530,
        958
)

-- Mining
DB_MapPOI.CreatePOI("highrisk-metal-burningsteppes",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Ruins of Thaurissan", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7896.94921875,
        -2184.50390625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        0,
        1112
)

DB_MapPOI.CreatePOI("highrisk-metal-easternplaguelands",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Noxious Glade", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7896.94921875,
        -2184.50390625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        0,
        1116
)

DB_MapPOI.CreatePOI("highrisk-metal-easternplaguelands",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Noxious Glade", C_PVP:GetRequiredItemLevelForEvents()) end,
        2725.3266601563,
        -5447.7514648438,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        0,
        1116
)

DB_MapPOI.CreatePOI("highrisk-metal-easternplaguelands2",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Fungal Vale", C_PVP:GetRequiredItemLevelForEvents()) end,
        2449.9458007813,
        -3734.2028808594,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        0,
        1116
)

DB_MapPOI.CreatePOI("highrisk-metal-westernplaguelands",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Weeping Cave", C_PVP:GetRequiredItemLevelForEvents()) end,
        2324.6069335938,
        -2337.5791015625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        0,
        1123
)

DB_MapPOI.CreatePOI("highrisk-metal-azshara",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Temple of Arkkoran", C_PVP:GetRequiredItemLevelForEvents()) end,
        3945.5124511719,
        -7215.1459960938,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        1,
        1102
)

DB_MapPOI.CreatePOI("highrisk-metal-ungoro",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Slithering Scar", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7896.1479492188,
        -1335.4304199219,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        1,
        1107
)

DB_MapPOI.CreatePOI("highrisk-metal-silithus",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Crystal Vale", C_PVP:GetRequiredItemLevelForEvents()) end,
        -6298.7690429688,
        1706.099609375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        1,
        1129
)

DB_MapPOI.CreatePOI("highrisk-metal-silithus",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Crystal Vale", C_PVP:GetRequiredItemLevelForEvents()) end,
        -6298.7690429688,
        1706.099609375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        1,
        1129
)

DB_MapPOI.CreatePOI("highrisk-metal-winterspring",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Frostwhisper Gorge", C_PVP:GetRequiredItemLevelForEvents()) end,
        5259.7299804688,
        -4781.0498046875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        1,
        1135
)

DB_MapPOI.CreatePOI("highrisk-metal-terokkar",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Bone Wastes", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3056.5642089844,
        4567.9291992188,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        930
)

DB_MapPOI.CreatePOI("highrisk-metal-terokkar",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Bone Wastes", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3056.5642089844,
        4567.9291992188,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        930
)

DB_MapPOI.CreatePOI("highrisk-metal-zangarmarsh",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Angro'rosh Grounds & Angro'rosh Stronghold", C_PVP:GetRequiredItemLevelForEvents()) end,
        1121.9118652344,
        8535.7587890625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        935
)

DB_MapPOI.CreatePOI("highrisk-metal-nagrand",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Southwind Cleft & Northwind Cleft", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2040.6423339844,
        7553.3862304688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        940
)

DB_MapPOI.CreatePOI("highrisk-metal-nagrand2",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Southwind Cleft & Northwind Cleft", C_PVP:GetRequiredItemLevelForEvents()) end,
        -1137.1417236328,
        8046.0502929688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        940
)

DB_MapPOI.CreatePOI("highrisk-metal-bladesedge",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Crystal Spine & Vortex Pinacle", C_PVP:GetRequiredItemLevelForEvents()) end,
        3941.2570800781,
        5412.7534179688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        945
)

DB_MapPOI.CreatePOI("highrisk-metal-bladesedge2",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Crystal Spine & Vortex Pinacle", C_PVP:GetRequiredItemLevelForEvents()) end,
        2292.7451171875,
        7107.8369140625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        945
)

DB_MapPOI.CreatePOI("highrisk-metal-shadowmoon",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "The Deathforge", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3351.1823730469,
        2000.5423583984,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        952
)

DB_MapPOI.CreatePOI("highrisk-metal-netherstorm",
        EVENT_HR_MATERIALS_METALS,
        function() return format(EVENT_HR_MATERIALS_METALS_DESC, "Forge Base: Gehenna and Oblivion", C_PVP:GetRequiredItemLevelForEvents()) end,
        4587.9975585938,
        3313.03515625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-metal",
        0.32,
        nil,
        530,
        959
)

-- skinning

DB_MapPOI.CreatePOI("highrisk-skinning-burningsteppes",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Creatures and Dragons", "Terror Wing Path", "Burning Steppes", C_PVP:GetRequiredItemLevelForEvents()) end,
        -8101.7504882813,
        -2941.3227539063,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        0,
        1113
)

DB_MapPOI.CreatePOI("highrisk-skinning-easternplaguelands",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Creatures", "Any Location", "The Eastern Plaguelands", C_PVP:GetRequiredItemLevelForEvents()) end,
        2180.4086914063,
        -4880.58203125,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        0,
        1118
)

DB_MapPOI.CreatePOI("highrisk-skinning-westernplaguelands",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Creatures", "Any Location", "The Western Plaguelands", C_PVP:GetRequiredItemLevelForEvents()) end,
        1834.8719482422,
        -2066.5234375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        0,
        1124
)

DB_MapPOI.CreatePOI("highrisk-skinning-azshara",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Hippogryphs", "The Northern area", "The Bitter Reaches", C_PVP:GetRequiredItemLevelForEvents()) end,
        4567.751953125,
        -7040.865234375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        1,
        1103
)

DB_MapPOI.CreatePOI("highrisk-skinning-ungoro",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Devilsaur", "The Marshlands", "Un'goro Crater", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7329.0932617188,
        -2099.1135253906,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        1,
        1108
)

DB_MapPOI.CreatePOI("highrisk-skinning-silithus",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Creatures", "Any Location", "Silithus", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7390.7670898438,
        1200.1636962891,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        1,
        1130
)

DB_MapPOI.CreatePOI("highrisk-skinning-winterspring",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "Frostsaber Rock", C_PVP:GetRequiredItemLevelForEvents()) end,
        7754.1865234375,
        -3849.2973632813,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        1,
        1136
)

DB_MapPOI.CreatePOI("highrisk-skinning-terokkar",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "Terokkar Forest", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2412.0114746094,
        3842.234375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        931
)

DB_MapPOI.CreatePOI("highrisk-skinning-zangarmarsh",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DETAILED_DESC, "Basilisks and Greater Sporebats", "The Western and Northwestern edge", "Zangarmarsh", C_PVP:GetRequiredItemLevelForEvents()) end,
        557.35418701172,
        8864.869140625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        936
)

DB_MapPOI.CreatePOI("highrisk-skinning-nagrand",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "Nagrand", C_PVP:GetRequiredItemLevelForEvents()) end,
        -1526.1950683594,
        6777.4516601563,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        941
)

DB_MapPOI.CreatePOI("highrisk-skinning-bladesedge",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "Razor Ridge & Bladed Gulch", C_PVP:GetRequiredItemLevelForEvents()) end,
        2514.7163085938,
        5218.9614257813,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        946
)

DB_MapPOI.CreatePOI("highrisk-skinning-shadowmoon",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "The Magma Fields", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3380.4975585938,
        2425.1865234375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        953
)

DB_MapPOI.CreatePOI("highrisk-skinning-netherstorm",
        EVENT_HR_MATERIALS_SKINNING,
        function() return format(EVENT_HR_MATERIALS_SKINNING_DESC, "Celestial Ridge", C_PVP:GetRequiredItemLevelForEvents()) end,
        4016.2770996094,
        1427.3724365234,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-skinning",
        0.32,
        nil,
        530,
        960
)

-- enchanting

DB_MapPOI.CreatePOI("highrisk-enchanting-burningsteppes",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Pillars of Ash and Blackrock Stronghold", C_PVP:GetRequiredItemLevelForEvents()) end,
        -8134.5537109375,
        -1808.9157714844,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        0,
        1114
)

DB_MapPOI.CreatePOI("highrisk-enchanting-burningsteppes2",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Pillars of Ash and Blackrock Stronghold", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7738.7963867188,
        -1532.1016845703,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        0,
        1114
)

DB_MapPOI.CreatePOI("highrisk-enchanting-easternplaguelands",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Tyr's Hand", C_PVP:GetRequiredItemLevelForEvents()) end,
        1657.1339111328,
        -5415.4428710938,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        0,
        1121
)

DB_MapPOI.CreatePOI("highrisk-enchanting-westernplaguelands",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Hearthglen", C_PVP:GetRequiredItemLevelForEvents()) end,
        2809.5673828125,
        -1548.9113769531,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        0,
        1125
)

DB_MapPOI.CreatePOI("highrisk-enchanting-azshara",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Lake Mennar", C_PVP:GetRequiredItemLevelForEvents()) end,
        2546.5302734375,
        -5264.0219726563,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        1,
        1104
)

DB_MapPOI.CreatePOI("highrisk-enchanting-ungoro",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Fire Plume Ridge", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7107.0024414063,
        -1371.5441894531,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        1,
        1109
)

DB_MapPOI.CreatePOI("highrisk-enchanting-silithus",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Hive Zora", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7363.1557617188,
        1733.5440673828,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        1,
        1131
)

DB_MapPOI.CreatePOI("highrisk-enchanting-winterspring",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Mazthoril", C_PVP:GetRequiredItemLevelForEvents()) end,
        6151.765625,
        -4200.0971679688,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        1,
        1137
)

DB_MapPOI.CreatePOI("highrisk-enchanting-terokkar",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Skettis", C_PVP:GetRequiredItemLevelForEvents()) end,
        -4112.3549804688,
        3314.9392089844,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        932
)

DB_MapPOI.CreatePOI("highrisk-enchanting-zangarmarsh",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Dead Mire", C_PVP:GetRequiredItemLevelForEvents()) end,
        616.91888427734,
        5335.6381835938,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        937
)

DB_MapPOI.CreatePOI("highrisk-enchanting-nagrand",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Twilight Ridge", C_PVP:GetRequiredItemLevelForEvents()) end,
        -1529.8958740234,
        9741.248046875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        942
)

DB_MapPOI.CreatePOI("highrisk-enchanting-bladesedge",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Forge Camp: Wrath & Forge Camp: Terror", C_PVP:GetRequiredItemLevelForEvents()) end,
        2987.5141601563,
        6958.3178710938,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        947
)

DB_MapPOI.CreatePOI("highrisk-enchanting-bladesedge2",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Forge Camp: Wrath & Forge Camp: Terror", C_PVP:GetRequiredItemLevelForEvents()) end,
        1413.1262207031,
        7252.5244140625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        947
)

DB_MapPOI.CreatePOI("highrisk-enchanting-shadowmoon",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Legion Hold & Illidari Point", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3226.802734375,
        2936.2731933594,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        954
)

DB_MapPOI.CreatePOI("highrisk-enchanting-shadowmoon2",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Legion Hold & Illidari Point", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3914.9809570313,
        2561.6181640625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        954
)

DB_MapPOI.CreatePOI("highrisk-enchanting-netherstorm",
        EVENT_HR_MATERIALS_ENCHANTING,
        function() return format(EVENT_HR_MATERIALS_ENCHANTING_DESC, "Manaforge Ultris", C_PVP:GetRequiredItemLevelForEvents()) end,
        3936.6437988281,
        2004.2694091797,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-enchanting",
        0.32,
        nil,
        530,
        961
)

-- Tailoring

DB_MapPOI.CreatePOI("highrisk-tailoring-burningsteppes",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Dracodar", C_PVP:GetRequiredItemLevelForEvents()) end,
        -8242.720703125,
        -998.38098144531,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        0,
        1115
)

DB_MapPOI.CreatePOI("highrisk-tailoring-easternplaguelands",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Zul'Mashar", C_PVP:GetRequiredItemLevelForEvents()) end,
        3261.5017089844,
        -4828.5283203125,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        0,
        1120
)

DB_MapPOI.CreatePOI("highrisk-tailoring-westernplaguelands",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Sorrow Hill", C_PVP:GetRequiredItemLevelForEvents()) end,
        1156.8416748047,
        -1720.4235839844,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        0,
        1126
)

DB_MapPOI.CreatePOI("highrisk-tailoring-azshara",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Ravencrest Monument", C_PVP:GetRequiredItemLevelForEvents()) end,
        2440.8491210938,
        -6839.912109375,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1105
)

DB_MapPOI.CreatePOI("highrisk-tailoring-ungoro",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Fungal Rock", C_PVP:GetRequiredItemLevelForEvents()) end,
        -6331.4306640625,
        -1902.2165527344,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1110
)

DB_MapPOI.CreatePOI("highrisk-tailoring-silithus",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "The Twilight Camp", C_PVP:GetRequiredItemLevelForEvents()) end,
        -6730.0932617188,
        1623.1931152344,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1132
)

DB_MapPOI.CreatePOI("highrisk-tailoring-silithus2",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "The Twilight Camp", C_PVP:GetRequiredItemLevelForEvents()) end,
        -7912.4311523438,
        1813.8275146484,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1132
)

DB_MapPOI.CreatePOI("highrisk-tailoring-winterspring",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Winterfall Village", C_PVP:GetRequiredItemLevelForEvents()) end,
        6837.4301757813,
        -5084.0400390625,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1138
)

DB_MapPOI.CreatePOI("highrisk-tailoring-winterspring2",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Winterfall Village", C_PVP:GetRequiredItemLevelForEvents()) end,
        6768.7612304688,
        -2520.7260742188,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        1,
        1138
)

DB_MapPOI.CreatePOI("highrisk-tailoring-terokkar",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Firewing Point & Bonechewer Ruins", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2367.30078125,
        3214.6628417969,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        933
)

DB_MapPOI.CreatePOI("highrisk-tailoring-terokkar2",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Firewing Point & Bonechewer Ruins", C_PVP:GetRequiredItemLevelForEvents()) end,
        -2924.75390625,
        3570.9594726563,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        933
)

DB_MapPOI.CreatePOI("highrisk-tailoring-zangarmarsh",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Feralfen Village", C_PVP:GetRequiredItemLevelForEvents()) end,
        -110.3570022583,
        7115.0698242188,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        938
)

DB_MapPOI.CreatePOI("highrisk-tailoring-nagrand",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Warmaul Hill", C_PVP:GetRequiredItemLevelForEvents()) end,
        -878.29174804688,
        8884.1904296875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        943
)

DB_MapPOI.CreatePOI("highrisk-tailoring-bladesedge",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Daggermaul Canyon", C_PVP:GetRequiredItemLevelForEvents()) end,
        2439.7912597656,
        6411.263671875,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        948
)

DB_MapPOI.CreatePOI("highrisk-tailoring-shadowmoon",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "The Ruins of Baa'ri", C_PVP:GetRequiredItemLevelForEvents()) end,
        -3311.7224121094,
        1051.6312255859,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        955
)

DB_MapPOI.CreatePOI("highrisk-tailoring-netherstorm",
        EVENT_HR_MATERIALS_TAILORING,
        function() return format(EVENT_HR_MATERIALS_TAILORING_DESC, "Manaforge Curuu & Sunfury Hold", C_PVP:GetRequiredItemLevelForEvents()) end,
        2390.3615722656,
        2593.3381347656,
        0,
        Enum.POIType.HighRiskEvent,
        flags,
        "hr-event-tailoring",
        0.32,
        nil,
        530,
        962
)

-- Bloodforged Gear

local gearFlags = EnumUtil.CombineMasks(Enum.POIFlags.HideOnContinent, Enum.POIFlags.HasTooltip, Enum.POIFlags.HighRiskOnly, Enum.POIFlags.HighRiskGearEvent)
DB_MapPOI.CreatePOI("highrisk-gear-silithus",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        -7852.3793945313,
        558.42742919922,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        1,
        1133
)

DB_MapPOI.CreatePOI("highrisk-gear-winterspring",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        4749.673828125,
        -4457.7504882813,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        1,
        1139
)

DB_MapPOI.CreatePOI("highrisk-gear-bladesedge",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        3548.7351074219,
        5236.0161132813,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        949
)

DB_MapPOI.CreatePOI("highrisk-gear-bladesedge2",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        1940.0101318359,
        5373.4565429688,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        950
)

DB_MapPOI.CreatePOI("highrisk-gear-shadowmoon",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        -3290.3210449219,
        366.76382446289,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        956
)

DB_MapPOI.CreatePOI("highrisk-gear-shadowmoon2",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        -3860.3374023438,
        394.23782348633,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        956
)

DB_MapPOI.CreatePOI("highrisk-gear-shadowmoon3",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        -5203.9477539063,
        216.22769165039,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        957
)

DB_MapPOI.CreatePOI("highrisk-gear-netherstorm",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        4001.1857910156,
        4011.8044433594,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        963
)

DB_MapPOI.CreatePOI("highrisk-gear-netherstorm2",
        EVENT_HR_MATERIALS_GEAR,
        EVENT_HR_MATERIALS_GEAR_DESC,
        2260.4450683594,
        2309.2670898438,
        0,
        Enum.POIType.HighRiskEvent,
        gearFlags,
        "hr-event-gear",
        0.32,
        nil,
        530,
        964
)
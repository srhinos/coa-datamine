# Client data catalog (generated)

**Generated file - never hand-edit.** Every line below is written by `python -m tools.build_catalog` from `raw/tables/`, which `python -m tools.decode_all` writes from the client's MPQ chain. An edit here is overwritten on the next run and, worse, becomes a hand-authored fact in a layer whose whole point is that it contains none.

## What is here

- **368 tables**, **7,467,563 rows**, **6,662 columns**, 131.8 MB stored (2.0 GB decoded)
- Columns are positional: `f0`, `f1`, ... `fN`. Nothing in this repo knows what a column means, so nothing here names one.
- Types are measured, not asserted: 507 float, 4,889 int, 444 string, 56 unknown, 766 zero. The evidence behind every call is in `raw/tables/<Table>/<Table>.colinfo.json` and `raw/_catalog/tables.json`.

## Finding things

```
python -m tools.find "Tide Lash"      # which table/column holds a string
python -m tools.find --id 133         # every table an integer appears in
python -m tools.find --joins-to Spell # which columns point at Spell.f0
```
The first two also scan `raw/content` (the .loc localization store) and `raw/cache` (the WDB query caches), because quest and item TEXT lives there and not in the DBC - `Quest` and `Item` carry no string column at all. Add `--layer tables` to restrict.

| file | what it answers |
| --- | --- |
| `raw/_catalog/tables.json` | every column of every table: inferred type, decode evidence, distinct/min/max/pctZero |
| `raw/_catalog/strings.json` | 444 string columns with sample values - grep it for text |
| `raw/_catalog/joins.json` | 1917 columns with 13800 candidate joins, each with the target's id density and a chance baseline; `byTarget` inverts them over 92 target tables |
| `raw/tables/index.json` | shard map, byte counts, source archive per table |
| `raw/README.md` | the other raw layers: content/.loc, Interface, WDB caches |

## Reading a row

Every record is one line of one shard, keyed positionally: `{"f0":133,"f136":"Fireball"}`. `f5i` is the raw int when `f5` decoded as a string, `f5s` the decoded string when `f5` decoded as an int - so a wrong type call loses nothing. `raw/tables/README.md` states the full rule.

## A warning this repo paid for

CoA ids collide across generations - the same ability exists under a catalog id, a trainer rank id and a live talent-node id, with the same name and no join table. A containment rate of 1.0 in `joins.json` is overlap, not identity, which is why every candidate ships with `targetDensity`, `lift` and `matched`. `lift` near 1.0 is chance. A high `lift` on a small `matched` is also chance - two values that happen to be ids score what eleven do. Read both before believing a join.

## Tables

Sorted by name. `size` is stored bytes; `key` is the f0 id space (distinct ids, and the share of its min..max range they occupy). `inbound` is how many columns elsewhere in the client join to this table's f0, and how many of those beat chance on at least 5 matched values - `python -m tools.find --joins-to <Table>` lists them. `text columns` are the string columns with the most distinct values, one real value each.

| table | rows | cols | size | key | inbound | shards | text columns |
| --- | ---: | ---: | ---: | --- | --- | --- | --- |
| **Achievement** | 22,618 | 62 | 650.6 KB | 22,618 @ 7% | 12 (9 strong) | `raw/tables/Achievement/*.jsonl.gz` | `f4` "No Threat" · `f21` Complete the "Hardcore - Artisan's Guild" cha… · `f43` Felforged Tome: Bounty I |
| **Achievement_Category** | 245 | 20 | 49.9 KB | 245 @ 0.31% | 3 (1 strong) | `raw/tables/Achievement_Category/*.jsonl` | `f2` A.B.Y.S.S. |
| **Achievement_Criteria** | 33,630 | 31 | 612.7 KB | 33,630 @ 11% | 9 (8 strong) | `raw/tables/Achievement_Criteria/*.jsonl.gz` | `f9` Band of the Earthshatterer |
| **AchievementRewards** | 1,663 | 4 | 65.0 KB | 1,663 @ 1.1% | 1 (1 strong) | `raw/tables/AchievementRewards/*.jsonl` | - |
| **AnimationData** | 1,792 | 8 | 170.7 KB | 1,792 @ 100% | - | `raw/tables/AnimationData/*.jsonl` | `f1` AdvFlyBackward |
| **AppearanceCategories** | 68 | 26 | 21.7 KB | 68 @ 100% | - | `raw/tables/AppearanceCategories/*.jsonl` | `f2` (DND) Summoned Felguard Weapon · `f22` Ability_Druid_AquaticForm · `f1` APPEARANCE_TYPE_COMPANION |
| **AppearanceDetails** | 17,297 | 21 | 107.9 KB | 17,297 @ 1.4% | 869 (837 strong) | `raw/tables/AppearanceDetails/*.jsonl.gz` | - |
| **Appearances** | 42,884 | 17 | 580.0 KB | 42,884 @ 6.7% | 146 (140 strong) | `raw/tables/Appearances/*.jsonl.gz` | `f2` APPEARANCE_DISPLAY_TYPE_ANIMATED_SPELL_VISUAL |
| **AreaGroup** | 304 | 8 | 19.5 KB | 304 @ 6.1% | 1 (1 strong) | `raw/tables/AreaGroup/*.jsonl` | - |
| **AreaPOI** | 847 | 54 | 457.4 KB | 847 @ 29% | - | `raw/tables/AreaPOI/*.jsonl` | `f18` Aerie Peak · `f35` Abyssal Shelf to Kil'Jaeden |
| **AreaTable** | 2,848 | 36 | 1.0 MB | 2,848 @ 19% | 8 (8 strong) | `raw/tables/AreaTable/*.jsonl` | `f11` 7th Legion Front |
| **AreaTrigger** | 1,484 | 10 | 227.3 KB | 1,484 @ 19% | - | `raw/tables/AreaTrigger/*.jsonl` | - |
| **AttackAnimKits** | 26 | 5 | 992 B | 26 @ 96% | - | `raw/tables/AttackAnimKits/*.jsonl` | - |
| **AttackAnimTypes** | 7 | 2 | 257 B | 7 @ 88% | - | `raw/tables/AttackAnimTypes/*.jsonl` | `f1` 1H_Main_Pierce |
| **AuctionHouse** | 8 | 21 | 1.7 KB | 8 @ 100% | - | `raw/tables/AuctionHouse/*.jsonl` | `f4` Alliance Auction House |
| **BankBagSlotPrices** | 12 | 2 | 267 B | 12 @ 100% | - | `raw/tables/BankBagSlotPrices/*.jsonl` | - |
| **BannedAddOns** | 102 | 11 | 10.6 KB | 102 @ 24% | - | `raw/tables/BannedAddOns/*.jsonl` | - |
| **BarberShopStyle** | 635 | 40 | 221.1 KB | 635 @ 32% | - | `raw/tables/BarberShopStyle/*.jsonl` | `f2` Blades |
| **BattlemasterList** | 73 | 32 | 23.0 KB | 73 @ 8.7% | - | `raw/tables/BattlemasterList/*.jsonl` | `f11` Airstrip Assault |
| **CameraShakes** | 89 | 8 | 7.7 KB | 89 @ 8.9% | - | `raw/tables/CameraShakes/*.jsonl` | - |
| **Cfg_Categories** | 41 | 21 | 19.5 KB | 41 @ 12% | - | `raw/tables/Cfg_Categories/*.jsonl` | `f4` Ascension Evolved · `f5` Ascension Evolved · `f6` Ascension Evolved |
| **Cfg_Configs** | 13 | 4 | 397 B | 13 @ 100% | - | `raw/tables/Cfg_Configs/*.jsonl` | - |
| **Challenge** | 297 | 53 | 310.3 KB | 297 @ 48% | - | `raw/tables/Challenge/*.jsonl` | `f7` Bring it On! · `f24` A MEGA curse hangs upon you! Every 3 seconds,… · `f42` ABILITY_HUNTER_BESTIALDISCIPLINE |
| **ChallengeConditions** | 354 | 10 | 44.7 KB | 354 @ 12% | - | `raw/tables/ChallengeConditions/*.jsonl` | `f5` CHALLENGE_CONDITIONS_TYPE_GROUP_SIZE |
| **ChallengeConditionTypes** | 18 | 73 | 16.6 KB | 18 @ 100% | - | `raw/tables/ChallengeConditionTypes/*.jsonl` | `f1` CHALLENGE_CONDITIONS_TYPE_ACCEPT_TRADE · `f2` Be prestige level %1$d · `f19` Accepting a trade from another player makes y… |
| **ChallengeFeatured** | 54 | 5 | 2.3 KB | 54 @ 100% | - | `raw/tables/ChallengeFeatured/*.jsonl` | - |
| **ChallengeGroupRewards** | 144 | 10 | 20.1 KB | 144 @ 22% | - | `raw/tables/ChallengeGroupRewards/*.jsonl` | `f4` EXPANSION_CLASSIC · `f5` CLASS_NONE |
| **ChallengeGroups** | 1,203 | 3 | 34.4 KB | 1,203 @ 22% | - | `raw/tables/ChallengeGroups/*.jsonl` | - |
| **ChallengeLevels** | 1,334 | 5 | 55.7 KB | 1,334 @ 27% | - | `raw/tables/ChallengeLevels/*.jsonl` | - |
| **ChallengeModifiers** | 2 | 8 | 128 B | 2 @ 100% | - | `raw/tables/ChallengeModifiers/*.jsonl` | - |
| **ChallengeModifierTypes** | 8 | 37 | 3.7 KB | 8 @ 100% | - | `raw/tables/ChallengeModifierTypes/*.jsonl` | `f1` CHALLENGE_MODIFIERS_TYPE_MOD_HEALING_DONE_PCT · `f2` Healing Done · `f19` None |
| **ChallengeRequirements** | 2,047 | 9 | 302.3 KB | 2,047 @ 13% | - | `raw/tables/ChallengeRequirements/*.jsonl` | `f4` CHALLENGE_REQUIREMENT_TYPE_COMPLETE_QUEST_BEF… |
| **ChallengeRequirementTypes** | 22 | 41 | 14.3 KB | 22 @ 100% | - | `raw/tables/ChallengeRequirementTypes/*.jsonl` | `f1` CHALLENGE_REQUIREMENT_TYPE_COMPLETE_NUM_QUEST… · `f2` %1$d \|4Life:Lives; · `f19` You must be in a party of \|cffffffff2\|r to at… |
| **ChallengeRewards** | 21,677 | 11 | 185.8 KB | 21,677 @ 35% | 3 (2 strong) | `raw/tables/ChallengeRewards/*.jsonl.gz` | `f5` CLASS_BARBARIAN · `f4` EXPANSION_CLASSIC |
| **ChallengeRules** | 3,646 | 5 | 344.2 KB | 3,646 @ 10% | - | `raw/tables/ChallengeRules/*.jsonl` | `f4` CHALLENGE_RULES_TYPE_CANNOT_DODGE_BLOCK_OR_PA… |
| **ChallengeRuleTypes** | 127 | 36 | 59.3 KB | 127 @ 100% | - | `raw/tables/ChallengeRuleTypes/*.jsonl` | `f1` CHALLENGE_RULES_TYPE_ALWAYS_HONORABLE_COMBAT · `f19` All quests can be completed while in a raid. · `f2` Always Honorable Combat |
| **ChallengeSpells** | 7,702 | 10 | 646.2 KB | 7,702 @ 25% | - | `raw/tables/ChallengeSpells/*.jsonl` | - |
| **CharacterAdvancement** | 7,820 | 173 | 557.0 KB | 7,820 @ 5.7% | 4 (4 strong) | `raw/tables/CharacterAdvancement/*.jsonl.gz` | `f47` "Stealth" · `f64` 5_archerskill02_Border · `f16` Epic |
| **CharacterAdvancementCategories** | 51 | 39 | 25.2 KB | 51 @ 98% | - | `raw/tables/CharacterAdvancementCategories/*.jsonl` | `f5` Area of Effect · `f4` Ability_Druid_CatForm · `f22` Area of Effect (AoE) abilities impact multipl… |
| **CharacterAdvancementClassTypes** | 46 | 23 | 10.0 KB | 46 @ 100% | - | `raw/tables/CharacterAdvancementClassTypes/*.jsonl` | `f1` Barbarian · `f6` Barbarian |
| **CharacterAdvancementEssence** | 5,440 | 9 | 384.2 KB | 5,440 @ 88% | - | `raw/tables/CharacterAdvancementEssence/*.jsonl` | - |
| **CharacterAdvancementTabTypes** | 94 | 19 | 17.1 KB | 94 @ 100% | - | `raw/tables/CharacterAdvancementTabTypes/*.jsonl` | `f1` Affliction · `f2` Affliction |
| **CharacterCreationArchetypeCategories** | 9 | 73 | 11.2 KB | 9 @ 75% | - | `raw/tables/CharacterCreationArchetypeCategories/*.jsonl` | `f19` ExperienceIconBattleHeal · `f21` Combat Healer · `f38` Combine spell and blade. |
| **CharacterCreationArchetypeDetails** | 1,120 | 28 | 309.7 KB | 1,120 @ 100% | - | `raw/tables/CharacterCreationArchetypeDetails/*.jsonl` | - |
| **CharacterCreationArchetypeRoles** | 3 | 71 | 3.5 KB | 3 @ 100% | - | `raw/tables/CharacterCreationArchetypeRoles/*.jsonl` | `f18` ExperienceIconDamage · `f19` Damage · `f36` Destroy your party's enemies. |
| **CharacterCreationArchetypes** | 56 | 157 | 172.5 KB | 56 @ 39% | - | `raw/tables/CharacterCreationArchetypes/*.jsonl` | `f2` 05901096-411d-4810-8e07-19c58128fdc8 · `f15` 5_bowshot_Border · `f19` Ascendant |
| **CharacterCreationClassDetails** | 464 | 28 | 120.3 KB | 464 @ 100% | - | `raw/tables/CharacterCreationClassDetails/*.jsonl` | - |
| **CharacterCreationClassGuideRoles** | 4 | 38 | 1.8 KB | 4 @ 100% | - | `raw/tables/CharacterCreationClassGuideRoles/*.jsonl` | `f1` DAMAGE · `f2` ExperienceIconDamage · `f3` Damage |
| **CharacterCreationClassGuideSubroleClasses** | 29 | 4 | 966 B | 29 @ 0.48% | 170 (45 strong) | `raw/tables/CharacterCreationClassGuideSubroleClasses/*.jsonl` | - |
| **CharacterCreationClassGuideSubroles** | 7 | 40 | 3.3 KB | 7 @ 100% | - | `raw/tables/CharacterCreationClassGuideSubroles/*.jsonl` | `f2` CASTER_DPS · `f3` CasterDPS · `f4` ExperienceIconFreepick |
| **CharacterCreationPetDetails** | 170 | 12 | 26.8 KB | 170 @ 94% | - | `raw/tables/CharacterCreationPetDetails/*.jsonl` | - |
| **CharacterCreationShapeshiftDetails** | 100 | 21 | 29.6 KB | 100 @ 100% | - | `raw/tables/CharacterCreationShapeshiftDetails/*.jsonl` | - |
| **CharacterFacialHairStyles** | 1,281 | 8 | 76.3 KB | 41 @ 66% | - | `raw/tables/CharacterFacialHairStyles/*.jsonl` | - |
| **CharBaseInfo** | 208 | 2 | 3.5 KB | 10 @ 91% | - | `raw/tables/CharBaseInfo/*.jsonl` | - |
| **CharHairGeosets** | 945 | 6 | 45.3 KB | 945 @ 60% | - | `raw/tables/CharHairGeosets/*.jsonl` | - |
| **CharHairTextures** | 93 | 8 | 5.7 KB | 93 @ 44% | - | `raw/tables/CharHairTextures/*.jsonl` | - |
| **CharSections** | 42,354 | 10 | 628.0 KB | 42,354 @ 64% | 9 (7 strong) | `raw/tables/CharSections/*.jsonl.gz` | `f4` Character\\BloodElf\\Female\\BloodElfFemaleFaceL… · `f5` Character\\BloodElf\\Female\\BloodElfFemaleFaceU… · `f6` Character\\Draenei2\\ScalpUpperHair00_09.blp |
| **CharStartOutfit** | 981 | 74 | 665.1 KB | 981 @ 96% | - | `raw/tables/CharStartOutfit/*.jsonl` | - |
| **CharTitles** | 190 | 37 | 74.1 KB | 190 @ 81% | - | `raw/tables/CharTitles/*.jsonl` | `f2` %s I · `f19` %s I |
| **CharVariations** | 40 | 6 | 1.8 KB | 20 @ 100% | - | `raw/tables/CharVariations/*.jsonl` | - |
| **ChatChannels** | 7 | 37 | 2.6 KB | 7 @ 27% | - | `raw/tables/ChatChannels/*.jsonl` | `f3` Ascension · `f20` Ascension |
| **ChatProfanity** | 5,233 | 3 | 260.1 KB | 5,233 @ 42% | 2 (2 strong) | `raw/tables/ChatProfanity/*.jsonl` | `f1` (五)Ｓ Ｆ |
| **ChrClasses** | 32 | 60 | 17.1 KB | 32 @ 100% | - | `raw/tables/ChrClasses/*.jsonl` | `f4` Barbarian · `f55` BARBARIAN |
| **ChrClassesRoles** | 32 | 11 | 2.6 KB | 32 @ 100% | - | `raw/tables/ChrClassesRoles/*.jsonl` | - |
| **ChrRaces** | 42 | 69 | 29.7 KB | 42 @ 67% | - | `raw/tables/ChrRaces/*.jsonl` | `f11` BloodElf · `f14` Blood Elf · `f6` Be |
| **ChrSpecs** | 101 | 65 | 91.7 KB | 101 @ 100% | - | `raw/tables/ChrSpecs/*.jsonl` | `f3` 5_axe_(3)_Border · `f29` Accursed · `f2` AFFLICTION |
| **CinematicCamera** | 17 | 7 | 2.6 KB | 17 @ 6.8% | - | `raw/tables/CinematicCamera/*.jsonl` | `f1` Cameras\\FlyByBloodElf.mdx |
| **CinematicSequences** | 15 | 10 | 1.1 KB | 15 @ 9% | - | `raw/tables/CinematicSequences/*.jsonl` | - |
| **CollectorCacheItems** | 14 | 26 | 3.0 KB | 14 @ 100% | - | `raw/tables/CollectorCacheItems/*.jsonl` | - |
| **CollectorCacheRarityRates** | 351 | 4 | 17.7 KB | 351 @ 100% | - | `raw/tables/CollectorCacheRarityRates/*.jsonl` | - |
| **CollectorCacheRarityTypes** | 8 | 19 | 1.3 KB | 8 @ 100% | - | `raw/tables/CollectorCacheRarityTypes/*.jsonl` | `f2` Artifact |
| **CollectorCacheTypes** | 1 | 38 | 375 B | 1 @ 100% | - | `raw/tables/CollectorCacheTypes/*.jsonl` | `f0` Draenor Jungle Tamer's Trove · `f4` Draenor Jungle Tamer's Trove |
| **Creature** | 127,178 | 23 | 2.8 MB | 127,178 @ 100% | 146 (0 strong) | `raw/tables/Creature/*.jsonl.gz` | `f2` Avion de Combate F-80 |
| **CreatureDisplayInfo** | 84,477 | 16 | 977.6 KB | 84,477 @ 8.6% | 16 (13 strong) | `raw/tables/CreatureDisplayInfo/*.jsonl.gz` | `f6` CamelMount_white · `f7` 18891 · `f8` ClockworkGnomeFeat_Dark |
| **CreatureDisplayInfoExtra** | 23,351 | 21 | 905.1 KB | 23,351 @ 2.8% | 11 (8 strong) | `raw/tables/CreatureDisplayInfoExtra/*.jsonl.gz` | `f20` 2bc78dd036d94c40cb2091c6a66c9a79.blp |
| **CreatureDisplayInfoGeosetData** | 18,935 | 4 | 727.4 KB | 18,935 @ 94% | 4 (4 strong) | `raw/tables/CreatureDisplayInfoGeosetData/*.jsonl` | - |
| **CreatureFamily** | 399 | 28 | 133.6 KB | 399 @ 46% | - | `raw/tables/CreatureFamily/*.jsonl` | `f10` Abomination · `f27` Interface/Icons/Ability_Hunter_Pet_Boar |
| **CreatureModelData** | 35,494 | 28 | 938.1 KB | 35,494 @ 3.9% | 13 (13 strong) | `raw/tables/CreatureModelData/*.jsonl.gz` | `f2` Creature\\IronDwarf\\IronDwarf.mdx |
| **CreatureMovementInfo** | 258 | 2 | 5.1 KB | 258 @ 26% | - | `raw/tables/CreatureMovementInfo/*.jsonl` | - |
| **CreatureSoundData** | 10,398 | 38 | 248.9 KB | 10,398 @ 2.1% | 111 (108 strong) | `raw/tables/CreatureSoundData/*.jsonl.gz` | - |
| **CreatureSpellData** | 803 | 9 | 64.5 KB | 803 @ 8.3% | - | `raw/tables/CreatureSpellData/*.jsonl` | - |
| **CreatureType** | 17 | 19 | 2.9 KB | 17 @ 100% | - | `raw/tables/CreatureType/*.jsonl` | `f1` Aberration |
| **CurrencyCategory** | 14 | 19 | 2.7 KB | 14 @ 29% | - | `raw/tables/CurrencyCategory/*.jsonl` | `f2` Ascension |
| **CurrencyTypes** | 69 | 4 | 2.6 KB | 69 @ 12% | - | `raw/tables/CurrencyTypes/*.jsonl` | - |
| **DanceMoves** | 24 | 24 | 7.0 KB | 24 @ 28% | - | `raw/tables/DanceMoves/*.jsonl` | `f5` All - Bow · `f6` Bow · `f3` Default fallback -EmoteTalkQuestion |
| **DeathThudLookups** | 45 | 5 | 1.9 KB | 45 @ 70% | - | `raw/tables/DeathThudLookups/*.jsonl` | - |
| **DeclinedWord** | 29,426 | 2 | 476.3 KB | 29,426 @ 89% | 14 (14 strong) | `raw/tables/DeclinedWord/*.jsonl.gz` | `f1` """Безумный"" Иона Стерлинг" |
| **DeclinedWordCases** | 141,956 | 4 | 2.8 MB | 141,956 @ 97% | 37 (0 strong) | `raw/tables/DeclinedWordCases/*.jsonl.gz` | `f3` """"Красавчика"" Дункана" |
| **DestructibleModelData** | 41 | 19 | 6.1 KB | 41 @ 95% | - | `raw/tables/DestructibleModelData/*.jsonl` | - |
| **DungeonEncounter** | 2,080 | 23 | 450.5 KB | 2,080 @ 5.6% | 1 (1 strong) | `raw/tables/DungeonEncounter/*.jsonl` | `f5` Admiral Seastomper |
| **DungeonEncounterExtra** | 2,080 | 4 | 81.0 KB | 2,048 @ 5.5% | 1 (1 strong) | `raw/tables/DungeonEncounterExtra/*.jsonl` | - |
| **DungeonMap** | 200 | 8 | 24.2 KB | 200 @ 6.7% | - | `raw/tables/DungeonMap/*.jsonl` | - |
| **DungeonMapChunk** | 2,696 | 5 | 143.5 KB | 2,696 @ 52% | - | `raw/tables/DungeonMapChunk/*.jsonl` | - |
| **DurabilityCosts** | 300 | 30 | 82.0 KB | 300 @ 100% | - | `raw/tables/DurabilityCosts/*.jsonl` | - |
| **DurabilityQuality** | 16 | 2 | 385 B | 16 @ 100% | - | `raw/tables/DurabilityQuality/*.jsonl` | - |
| **Emotes** | 466 | 7 | 41.0 KB | 466 @ 43% | - | `raw/tables/Emotes/*.jsonl` | `f1` ONESHOT_ATTACKUNARMED_VAR1 |
| **EmotesText** | 252 | 19 | 43.9 KB | 252 @ 56% | - | `raw/tables/EmotesText/*.jsonl` | `f1` ABSENT |
| **EmotesTextData** | 1,327 | 18 | 266.1 KB | 1,327 @ 95% | - | `raw/tables/EmotesTextData/*.jsonl` | `f1` %s blushes. |
| **EmotesTextSound** | 542 | 5 | 23.7 KB | 542 @ 98% | - | `raw/tables/EmotesTextSound/*.jsonl` | - |
| **EnchantEnchantSuggestions** | 380,008 | 4 | 2.6 MB | 380,008 @ 100% | 257 (0 strong) | `raw/tables/EnchantEnchantSuggestions/*.jsonl.gz` | - |
| **EnchantRoleSuggestions** | 0 | 4 | 0 B | - | - | `raw/tables/EnchantRoleSuggestions/*.jsonl` | - |
| **EnchantStatSuggestions** | 0 | 4 | 0 B | - | - | `raw/tables/EnchantStatSuggestions/*.jsonl` | - |
| **EnvironmentalDamage** | 6 | 3 | 154 B | 6 @ 100% | - | `raw/tables/EnvironmentalDamage/*.jsonl` | - |
| **Exhaustion** | 6 | 23 | 1.3 KB | 6 @ 100% | - | `raw/tables/Exhaustion/*.jsonl` | `f5` Normal |
| **ExtraActionButtons** | 28 | 10 | 5.3 KB | 28 @ 100% | - | `raw/tables/ExtraActionButtons/*.jsonl` | `f3` Amphora · `f4` brewmoonkeg · `f2` ACTION_TYPE_ITEM |
| **Faction** | 417 | 57 | 237.4 KB | 417 @ 19% | - | `raw/tables/Faction/*.jsonl` | `f23` Alliance Vanguard · `f40` A remnant of the once powerful elves living i… |
| **FactionGroup** | 4 | 20 | 758 B | 4 @ 100% | - | `raw/tables/FactionGroup/*.jsonl` | `f2` Alliance · `f3` Alliance |
| **FactionTemplate** | 871 | 14 | 97.8 KB | 871 @ 34% | - | `raw/tables/FactionTemplate/*.jsonl` | - |
| **FileData** | 13 | 3 | 1.1 KB | 13 @ 0.0036% | 33 (1 strong) | `raw/tables/FileData/*.jsonl` | `f1` LOGO_1024.AVI · `f2` INTERFACE\\CINEMATICS\\ |
| **FootprintTextures** | 6 | 2 | 363 B | 6 @ 86% | - | `raw/tables/FootprintTextures/*.jsonl` | `f1` textures\\Footsteps\\BareFootprint |
| **FootstepTerrainLookup** | 240 | 5 | 10.9 KB | 240 @ 1.2% | - | `raw/tables/FootstepTerrainLookup/*.jsonl` | - |
| **GameObjectArtKit** | 18 | 8 | 3.8 KB | 18 @ 15% | - | `raw/tables/GameObjectArtKit/*.jsonl` | `f4` World\\Expansion01\\Doodads\\Auchindoun\\Passived… · `f1` Bow_1H_Standard_A_01Black.blp · `f5` World\\Generic\\PassiveDoodads\\ParticleEmitters… |
| **GameObjectDisplayInfo** | 120,869 | 19 | 1.7 MB | 120,869 @ 11% | 6 (6 strong) | `raw/tables/GameObjectDisplayInfo/*.jsonl.gz` | `f1` ITEM\\OBJECTCOMPONENTS\\HEAD\\Helm_Leather_RaidR… |
| **GameObjectDisplayInfoAddon** | 106,834 | 2 | 532.2 KB | 106,834 @ 10% | 2 (2 strong) | `raw/tables/GameObjectDisplayInfoAddon/*.jsonl.gz` | `f1` ITEM\\OBJECTCOMPONENTS\\HEAD\\Helm_Robe_DungeonR… |
| **GameTables** | 87 | 3 | 4.7 KB | 87 @ 5.5% | - | `raw/tables/GameTables/*.jsonl` | `f0` AttackPower |
| **GameTips** | 169 | 18 | 53.1 KB | 169 @ 30% | - | `raw/tables/GameTips/*.jsonl` | `f1` \|cffffd100Tip:\|r <Shift>Clicking on an item b… |
| **GemProperties** | 668 | 5 | 28.7 KB | 668 @ 5.3% | - | `raw/tables/GemProperties/*.jsonl` | - |
| **GlobalStrings** | 14,344 | 20 | 465.7 KB | 14,344 @ 89% | 3 (3 strong) | `raw/tables/GlobalStrings/*.jsonl.gz` | `f2` ABANDON_PET · `f3` %s has left the raid group. |
| **GlyphProperties** | 362 | 4 | 14.1 KB | 362 @ 40% | - | `raw/tables/GlyphProperties/*.jsonl` | - |
| **GlyphSlot** | 10 | 3 | 236 B | 10 @ 38% | - | `raw/tables/GlyphSlot/*.jsonl` | - |
| **GMSurveyAnswers** | 45 | 20 | 8.0 KB | 45 @ 60% | - | `raw/tables/GMSurveyAnswers/*.jsonl` | `f3` 0 |
| **GMSurveyCurrentSurvey** | 9 | 2 | 144 B | 9 @ 100% | - | `raw/tables/GMSurveyCurrentSurvey/*.jsonl` | - |
| **GMSurveyQuestions** | 13 | 18 | 3.1 KB | 13 @ 93% | - | `raw/tables/GMSurveyQuestions/*.jsonl` | `f1` Based on this customer service experience, ho… |
| **GMSurveySurveys** | 2 | 11 | 172 B | 2 @ 50% | - | `raw/tables/GMSurveySurveys/*.jsonl` | - |
| **GMTicketCategory** | 38 | 18 | 6.5 KB | 38 @ 100% | - | `raw/tables/GMTicketCategory/*.jsonl` | `f1` <not set> |
| **GroundEffectDoodad** | 1,968 | 3 | 103.3 KB | 1,968 @ 33% | 4 (4 strong) | `raw/tables/GroundEffectDoodad/*.jsonl` | `f1` 10nrbmoss01.mdl |
| **GroundEffectTexture** | 38,436 | 11 | 211.2 KB | 38,436 @ 22% | 14 (13 strong) | `raw/tables/GroundEffectTexture/*.jsonl.gz` | - |
| **gtBarberShopCostBase** | 255 | 1 | 3.9 KB | - | - | `raw/tables/gtBarberShopCostBase/*.jsonl` | - |
| **gtChanceToMeleeCrit** | 3,200 | 1 | 93.2 KB | - | - | `raw/tables/gtChanceToMeleeCrit/*.jsonl` | - |
| **gtChanceToMeleeCritBase** | 32 | 1 | 891 B | - | - | `raw/tables/gtChanceToMeleeCritBase/*.jsonl` | - |
| **gtChanceToSpellCrit** | 3,200 | 1 | 84.5 KB | - | - | `raw/tables/gtChanceToSpellCrit/*.jsonl` | - |
| **gtChanceToSpellCritBase** | 32 | 1 | 808 B | - | - | `raw/tables/gtChanceToSpellCritBase/*.jsonl` | - |
| **gtCombatRatings** | 3,200 | 1 | 69.0 KB | - | - | `raw/tables/gtCombatRatings/*.jsonl` | - |
| **gtNPCManaCostScaler** | 100 | 1 | 2.5 KB | - | - | `raw/tables/gtNPCManaCostScaler/*.jsonl` | - |
| **gtOCTClassCombatRatingScalar** | 1,024 | 2 | 21.2 KB | 1,024 @ 100% | - | `raw/tables/gtOCTClassCombatRatingScalar/*.jsonl` | - |
| **gtOCTRegenHP** | 3,200 | 1 | 83.8 KB | - | - | `raw/tables/gtOCTRegenHP/*.jsonl` | - |
| **gtOCTRegenMP** | 3,200 | 1 | 38.1 KB | - | - | `raw/tables/gtOCTRegenMP/*.jsonl` | - |
| **gtRegenHPPerSpt** | 3,200 | 1 | 49.3 KB | - | - | `raw/tables/gtRegenHPPerSpt/*.jsonl` | - |
| **gtRegenMPPerSpt** | 3,200 | 1 | 70.4 KB | - | - | `raw/tables/gtRegenMPPerSpt/*.jsonl` | - |
| **HDCharacterFacialHairStyles** | 272 | 9 | 18.8 KB | 272 @ 100% | - | `raw/tables/HDCharacterFacialHairStyles/*.jsonl` | - |
| **HDCharHairGeosets** | 372 | 6 | 17.4 KB | 372 @ 27% | - | `raw/tables/HDCharHairGeosets/*.jsonl` | - |
| **HDCharSections** | 25,544 | 10 | 406.0 KB | 25,544 @ 39% | 4 (4 strong) | `raw/tables/HDCharSections/*.jsonl.gz` | `f5` Character\\BloodElf\\Female\\BloodElfFemaleFaceU… · `f4` Character\\BloodElf\\Female\\BloodElfFemaleFaceL… · `f6` Character\\Draenei\\ScalpUpperHair00_04.blp |
| **HDCreatureDisplayInfo** | 6,855 | 16 | 80.6 KB | 6,855 @ 0.73% | 1 (0 strong) | `raw/tables/HDCreatureDisplayInfo/*.jsonl.gz` | `f6` DragonSkin1Blue · `f7` Copper · `f8` DRAKESKINGREEN3 |
| **HDCreatureDisplayInfoExtra** | 14,169 | 21 | 425.0 KB | 14,169 @ 2.8% | 3 (2 strong) | `raw/tables/HDCreatureDisplayInfoExtra/*.jsonl.gz` | `f20` CreatureDisplayExtra-00023_HD.blp |
| **HDCreatureModelData** | 545 | 28 | 225.8 KB | 545 @ 0.054% | 3 (1 strong) | `raw/tables/HDCreatureModelData/*.jsonl` | `f2` CHARACTER\\Naga_\\Female\\Naga_Female.mdx |
| **HDEmotesTextSound** | 782 | 5 | 34.1 KB | 782 @ 94% | - | `raw/tables/HDEmotesTextSound/*.jsonl` | - |
| **HDHelmetGeosetVisData** | 66 | 8 | 5.3 KB | 66 @ 28% | - | `raw/tables/HDHelmetGeosetVisData/*.jsonl` | - |
| **HDSpellVisualEffectName** | 424 | 7 | 70.6 KB | 424 @ 0.053% | - | `raw/tables/HDSpellVisualEffectName/*.jsonl` | `f2` Item\\ObjectComponents\\Weapon\\Mace_1H_UlduarRa… · `f1` Blue Hunter\\\\\\'s Mark |
| **HDSpellVisualKitModelAttach** | 737 | 10 | 72.9 KB | 737 @ 0.12% | - | `raw/tables/HDSpellVisualKitModelAttach/*.jsonl` | - |
| **HelmetGeosetVisData** | 66 | 8 | 5.3 KB | 66 @ 28% | - | `raw/tables/HelmetGeosetVisData/*.jsonl` | - |
| **HolidayDescriptions** | 30 | 18 | 10.6 KB | 30 @ 4.1% | - | `raw/tables/HolidayDescriptions/*.jsonl` | `f1` A fishing tournament, competed along the coas… |
| **HolidayNames** | 28 | 18 | 5.3 KB | 28 @ 3.9% | - | `raw/tables/HolidayNames/*.jsonl` | `f1` Arena Frenzy |
| **Holidays** | 58 | 55 | 30.6 KB | 58 @ 8.7% | - | `raw/tables/Holidays/*.jsonl` | `f51` Calendar_Brewfest · `f37` Calendar_WinterVeil · `f38` Calendar_WinterVeil |
| **Item** | 563,335 | 8 | 2.8 MB | 563,335 @ 6.1% | 230 (203 strong) | `raw/tables/Item/*.jsonl.gz` | - |
| **ItemAddon** | 563,335 | 48 | 11.6 MB | 563,335 @ 100% | 263 (0 strong) | `raw/tables/ItemAddon/*.jsonl.gz` | `f2` (Backsheath) · `f19` @Mythic 19@Glows with the power of magiskull. |
| **ItemAppearances** | 202,903 | 3 | 1.2 MB | 202,903 @ 31% | 338 (331 strong) | `raw/tables/ItemAppearances/*.jsonl.gz` | - |
| **ItemBagFamily** | 16 | 18 | 2.7 KB | 16 @ 100% | - | `raw/tables/ItemBagFamily/*.jsonl` | `f1` Arrows |
| **ItemClass** | 18 | 20 | 3.5 KB | 18 @ 100% | - | `raw/tables/ItemClass/*.jsonl` | `f3` Armor |
| **ItemCondExtCosts** | 1,163 | 4 | 41.2 KB | 1,163 @ 75% | - | `raw/tables/ItemCondExtCosts/*.jsonl` | - |
| **ItemDisplayInfo** | 129,603 | 25 | 3.6 MB | 129,603 @ 76% | 261 (256 strong) | `raw/tables/ItemDisplayInfo/*.jsonl.gz` | `f5` Asc_LuckyCard_gold_Retribution_Aura · `f3` Cape_Mail_D_02IllidanRed · `f16` LEATHER_NORTHREND_C_01_SLEEVE_AL |
| **ItemDisplayInfoCollections** | 4,704 | 8 | 902.9 KB | 4,704 @ 94% | - | `raw/tables/ItemDisplayInfoCollections/*.jsonl` | `f5` armor_kirintor_c_01_buckle_red.blp · `f4` armor_butterfly_c_01_std_belt.mdx |
| **ItemExtendedCost** | 13,777 | 16 | 82.3 KB | 13,777 @ 21% | 70 (69 strong) | `raw/tables/ItemExtendedCost/*.jsonl.gz` | - |
| **ItemGroupSounds** | 29 | 5 | 1.2 KB | 29 @ 100% | - | `raw/tables/ItemGroupSounds/*.jsonl` | - |
| **ItemLimitCategory** | 2,629 | 20 | 556.9 KB | 2,629 @ 5.4% | - | `raw/tables/ItemLimitCategory/*.jsonl` | `f1` 5.0 QA PVP Test CC Break Trinket Crit |
| **ItemPetFood** | 8 | 18 | 1.3 KB | 8 @ 100% | - | `raw/tables/ItemPetFood/*.jsonl` | `f1` Bread |
| **ItemPurchaseGroup** | 1 | 26 | 234 B | 1 @ 100% | - | `raw/tables/ItemPurchaseGroup/*.jsonl` | - |
| **ItemRandomProperties** | 10,087 | 24 | 80.1 KB | 10,087 @ 46% | - | `raw/tables/ItemRandomProperties/*.jsonl.gz` | `f7` Of Precision · `f1` Of Precision |
| **ItemRandomSuffix** | 275 | 29 | 93.1 KB | 275 @ 100% | - | `raw/tables/ItemRandomSuffix/*.jsonl` | `f18` Agile Defender · `f1` of Arcane Might · `f22` of the Monkey |
| **ItemSet** | 2,347 | 53 | 101.3 KB | 2,347 @ 3.7% | 1 (1 strong) | `raw/tables/ItemSet/*.jsonl.gz` | `f1` Garments of Malevolent Possession |
| **ItemSetAppearances** | 1,603 | 3 | 52.7 KB | 1,603 @ 1.2% | 681 (661 strong) | `raw/tables/ItemSetAppearances/*.jsonl` | - |
| **ItemSpells** | 131,722 | 37 | 1.0 MB | 131,722 @ 100% | 124 (0 strong) | `raw/tables/ItemSpells/*.jsonl.gz` | - |
| **ItemStat** | 1,513,931 | 39 | 23.9 MB | 1,513,931 @ 95% | 450 (303 strong) | `raw/tables/ItemStat/*.jsonl.gz` | - |
| **ItemSubClass** | 121 | 44 | 51.5 KB | 17 @ 100% | - | `raw/tables/ItemSubClass/*.jsonl` | `f10` Alchemy · `f27` Bows |
| **ItemSubClassMask** | 4 | 19 | 772 B | 2 @ 67% | - | `raw/tables/ItemSubClassMask/*.jsonl` | `f2` Melee Weapon |
| **ItemVisualEffects** | 205 | 2 | 13.7 KB | 205 @ 2% | - | `raw/tables/ItemVisualEffects/*.jsonl` | `f1` Creature\\Turkey\\turkey.mdx |
| **ItemVisuals** | 227 | 6 | 12.2 KB | 227 @ 3.2% | 1 (1 strong) | `raw/tables/ItemVisuals/*.jsonl` | - |
| **Languages** | 17 | 18 | 2.8 KB | 17 @ 45% | - | `raw/tables/Languages/*.jsonl` | `f1` Common |
| **LanguageWords** | 1,663 | 3 | 72.3 KB | 1,663 @ 99% | - | `raw/tables/LanguageWords/*.jsonl` | `f2` . |
| **LFGActivities** | 322 | 23 | 71.5 KB | 322 @ 95% | - | `raw/tables/LFGActivities/*.jsonl` | `f4` Ahn'Qiraj Ruins |
| **LFGActivityCategories** | 16 | 20 | 2.7 KB | 16 @ 100% | - | `raw/tables/LFGActivityCategories/*.jsonl` | `f2` Arenas |
| **LFGActivityGroupType** | 5 | 19 | 819 B | 5 @ 100% | - | `raw/tables/LFGActivityGroupType/*.jsonl` | `f1` Dungeons |
| **LfgDungeonExpansion** | 28 | 8 | 1.9 KB | 28 @ 15% | - | `raw/tables/LfgDungeonExpansion/*.jsonl` | - |
| **LFGDungeonGroup** | 18 | 21 | 3.9 KB | 18 @ 100% | - | `raw/tables/LFGDungeonGroup/*.jsonl` | `f1` Burning Crusade Heroic |
| **LFGDungeons** | 431 | 49 | 216.4 KB | 431 @ 3.3% | - | `raw/tables/LFGDungeons/*.jsonl` | `f1` Ahn'Qiraj Ruins · `f28` AQTemple · `f32` Defeat Ahune, the Frost Lord, before he fully… |
| **Light** | 1,349 | 15 | 220.9 KB | 1,349 @ 1.3% | 310 (309 strong) | `raw/tables/Light/*.jsonl` | - |
| **LightFloatBand** | 6,834 | 34 | 59.1 KB | 6,834 @ 11% | 186 (186 strong) | `raw/tables/LightFloatBand/*.jsonl.gz` | - |
| **LightIntBand** | 20,503 | 34 | 273.9 KB | 20,503 @ 11% | 274 (271 strong) | `raw/tables/LightIntBand/*.jsonl.gz` | - |
| **LightParams** | 1,140 | 9 | 102.6 KB | 1,140 @ 11% | 8 (8 strong) | `raw/tables/LightParams/*.jsonl` | - |
| **LightSkybox** | 230 | 3 | 18.4 KB | 230 @ 1.5% | 4 (4 strong) | `raw/tables/LightSkybox/*.jsonl` | `f1` ENVIRONMENTS\\Stars\\Vendetta_Machinima.mdx |
| **LiquidMaterial** | 3 | 3 | 69 B | 3 @ 100% | - | `raw/tables/LiquidMaterial/*.jsonl` | - |
| **LiquidType** | 28 | 45 | 15.4 KB | 28 @ 15% | - | `raw/tables/LiquidType/*.jsonl` | `f1` Basic Procedural Water · `f15` XTEXTURES\\LavaOrange\\LavaOrange.%d.blp · `f16` XTextures\\procWater\\basicReflectionMap.blp |
| **LoadingScreens** | 159 | 4 | 21.2 KB | 159 @ 15% | - | `raw/tables/LoadingScreens/*.jsonl` | `f1` ABWinter · `f2` Interface\\Glues\\LoadingScreens\\LoadScreenAhnQ… |
| **LoadingScreenTaxiSplines** | 27 | 19 | 7.4 KB | 27 @ 33% | - | `raw/tables/LoadingScreenTaxiSplines/*.jsonl` | - |
| **LoadingScreenVariation** | 0 | 17 | 0 B | - | - | `raw/tables/LoadingScreenVariation/*.jsonl` | - |
| **Lock** | 453 | 33 | 118.6 KB | 453 @ 9.1% | - | `raw/tables/Lock/*.jsonl` | - |
| **LockType** | 25 | 53 | 13.9 KB | 25 @ 100% | - | `raw/tables/LockType/*.jsonl` | `f1` Arm Trap · `f35` Arm · `f18` Calcified Elven Gems |
| **MailTemplate** | 208 | 35 | 112.2 KB | 208 @ 99% | - | `raw/tables/MailTemplate/*.jsonl` | `f18` The orphans of Northrend need your help. For … · `f1` A Brew You'll Like |
| **Manastorm** | 1,025 | 9 | 83.9 KB | 1,025 @ 85% | - | `raw/tables/Manastorm/*.jsonl` | - |
| **ManastormMessages** | 291 | 39 | 142.7 KB | 291 @ 24% | - | `raw/tables/ManastormMessages/*.jsonl` | `f22` Unlocked Tinkertech Showdown in future Manast… · `f5` Admiral Seastomper Defeated! · `f4` 5_paladinskill48_Border |
| **ManastormModifiers** | 32,768 | 15 | 936.6 KB | 32,768 @ 100% | 44 (0 strong) | `raw/tables/ManastormModifiers/*.jsonl.gz` | - |
| **ManastormPlayerGroupModifiers** | 15 | 5 | 1.0 KB | 15 @ 100% | - | `raw/tables/ManastormPlayerGroupModifiers/*.jsonl` | - |
| **Map** | 374 | 66 | 265.0 KB | 374 @ 9.3% | 7 (7 strong) | `raw/tables/Map/*.jsonl` | `f1` ABWinter · `f5` 5ppl_snow_bg · `f23` A valley bordering Ashenvale Forest and the B… |
| **MapDifficulty** | 685 | 23 | 164.9 KB | 685 @ 91% | - | `raw/tables/MapDifficulty/*.jsonl` | `f3` Heroic Difficulty requires completion of the … · `f22` DUNGEON_DIFFICULTY_5PLAYER |
| **Material** | 8 | 5 | 325 B | 8 @ 100% | - | `raw/tables/Material/*.jsonl` | - |
| **MentorSpecializations** | 10 | 19 | 2.0 KB | 10 @ 100% | - | `raw/tables/MentorSpecializations/*.jsonl` | `f1` Bonus-ToastBanner · `f2` Arenas |
| **Movie** | 10 | 3 | 690 B | 10 @ 45% | - | `raw/tables/Movie/*.jsonl` | `f1` Interface\\Cinematics\\Logo |
| **MovieFileData** | 12 | 2 | 268 B | 12 @ 0.0034% | 33 (1 strong) | `raw/tables/MovieFileData/*.jsonl` | - |
| **MovieVariation** | 13 | 3 | 363 B | 13 @ 12% | - | `raw/tables/MovieVariation/*.jsonl` | - |
| **MysticEnchant** | 7,815 | 31 | 91.0 KB | 7,815 @ 0.45% | 934 (672 strong) | `raw/tables/MysticEnchant/*.jsonl.gz` | `f15` AFFLICTION · `f16` ARMS · `f3` RE_QUALITY_ARTIFACT |
| **MythicAffixes** | 13,409 | 16 | 75.3 KB | 13,409 @ 100% | 19 (0 strong) | `raw/tables/MythicAffixes/*.jsonl.gz` | - |
| **MythicKeystones** | 6,801 | 3 | 215.7 KB | 6,801 @ 0.24% | - | `raw/tables/MythicKeystones/*.jsonl` | - |
| **MythicPlusScaling** | 200 | 8 | 13.8 KB | 200 @ 100% | - | `raw/tables/MythicPlusScaling/*.jsonl` | - |
| **NameGen** | 6,232 | 4 | 324.4 KB | 6,232 @ 92% | - | `raw/tables/NameGen/*.jsonl` | `f1` Aadelia |
| **NamesProfanity** | 8,268 | 3 | 424.1 KB | 8,268 @ 44% | - | `raw/tables/NamesProfanity/*.jsonl` | `f1` 18년 |
| **NamesReserved** | 16,329 | 3 | 849.1 KB | 16,329 @ 53% | 2 (2 strong) | `raw/tables/NamesReserved/*.jsonl` | `f1` 18? |
| **NPCSounds** | 2,487 | 5 | 127.8 KB | 2,487 @ 0.5% | 97 (48 strong) | `raw/tables/NPCSounds/*.jsonl` | - |
| **NPCTrainer** | 13,111 | 4 | 519.1 KB | 13,111 @ 100% | 31 (0 strong) | `raw/tables/NPCTrainer/*.jsonl` | - |
| **ObjectEffect** | 160 | 12 | 20.4 KB | 160 @ 20% | - | `raw/tables/ObjectEffect/*.jsonl` | `f1` Attack Thrown |
| **ObjectEffectGroup** | 111 | 2 | 6.0 KB | 111 @ 13% | - | `raw/tables/ObjectEffectGroup/*.jsonl` | `f1` DeepRunTram_Loop |
| **ObjectEffectModifier** | 11 | 8 | 1.1 KB | 11 @ 8% | - | `raw/tables/ObjectEffectModifier/*.jsonl` | - |
| **ObjectEffectPackage** | 30 | 2 | 1.4 KB | 30 @ 6.1% | - | `raw/tables/ObjectEffectPackage/*.jsonl` | `f1` DeepRunTram |
| **ObjectEffectPackageElem** | 198 | 4 | 7.3 KB | 198 @ 26% | - | `raw/tables/ObjectEffectPackageElem/*.jsonl` | - |
| **ObjectSpawnVisibilitySettings** | 0 | 7 | 0 B | - | - | `raw/tables/ObjectSpawnVisibilitySettings/*.jsonl` | - |
| **OcclusionVolume** | 373 | 4 | 23.9 KB | 373 @ 37% | - | `raw/tables/OcclusionVolume/*.jsonl` | `f1` -- NO NAME -- |
| **OcclusionVolumePoints** | 1,529 | 5 | 132.2 KB | 1,529 @ 39% | - | `raw/tables/OcclusionVolumePoints/*.jsonl` | - |
| **OverrideSpellData** | 49 | 12 | 5.0 KB | 49 @ 5.7% | - | `raw/tables/OverrideSpellData/*.jsonl` | - |
| **Package** | 1 | 20 | 201 B | 1 @ 100% | - | `raw/tables/Package/*.jsonl` | `f1` INV_BOX_04 · `f3` Test Package |
| **PageTextMaterial** | 7 | 2 | 229 B | 7 @ 100% | - | `raw/tables/PageTextMaterial/*.jsonl` | `f1` Bronze |
| **PaperDollItemFrame** | 36 | 3 | 3.7 KB | 36 @ 3.2% | - | `raw/tables/PaperDollItemFrame/*.jsonl` | `f0` AmmoSlot · `f1` interface\\paperdoll\\UI-PaperDoll-Slot-Bag.blp |
| **ParticleColor** | 1,666 | 10 | 234.3 KB | 1,666 @ 8.4% | - | `raw/tables/ParticleColor/*.jsonl` | - |
| **PetitionType** | 2 | 3 | 102 B | 2 @ 100% | - | `raw/tables/PetitionType/*.jsonl` | `f0` Guild · `f1` Arena Team |
| **PetPersonality** | 2 | 24 | 468 B | 2 @ 67% | - | `raw/tables/PetPersonality/*.jsonl` | `f1` Personality: Standard |
| **PowerDisplay** | 7 | 6 | 525 B | 7 @ 4.9% | - | `raw/tables/PowerDisplay/*.jsonl` | `f2` AMMOSLOT |
| **PvpDifficulty** | 658 | 6 | 33.4 KB | 658 @ 95% | - | `raw/tables/PvpDifficulty/*.jsonl` | - |
| **Quest** | 18,561 | 29 | 142.3 KB | 18,561 @ 0.23% | 1045 (789 strong) | `raw/tables/Quest/*.jsonl.gz` | - |
| **QuestFactionReward** | 2 | 11 | 197 B | 2 @ 100% | - | `raw/tables/QuestFactionReward/*.jsonl` | - |
| **QuestInfo** | 11 | 18 | 1.8 KB | 11 @ 12% | - | `raw/tables/QuestInfo/*.jsonl` | `f1` Dungeon |
| **QuestSort** | 144 | 18 | 24.7 KB | 144 @ 24% | - | `raw/tables/QuestSort/*.jsonl` | `f1` Ahn'Qiraj War |
| **QuestSuperTrack** | 11,269 | 102 | 154.2 KB | 11,269 @ 34% | 98 (98 strong) | `raw/tables/QuestSuperTrack/*.jsonl.gz` | - |
| **QuestTemplateScaling** | 5,535 | 15 | 687.2 KB | 5,535 @ 0.33% | 90 (39 strong) | `raw/tables/QuestTemplateScaling/*.jsonl` | - |
| **QuestXP** | 100 | 11 | 10.9 KB | 100 @ 100% | - | `raw/tables/QuestXP/*.jsonl` | - |
| **RandPropPoints** | 300 | 16 | 41.7 KB | 300 @ 100% | - | `raw/tables/RandPropPoints/*.jsonl` | - |
| **Resistances** | 7 | 20 | 1.2 KB | 7 @ 100% | - | `raw/tables/Resistances/*.jsonl` | `f3` Arcane |
| **ScalingStatDistribution** | 163 | 22 | 30.7 KB | 163 @ 23% | - | `raw/tables/ScalingStatDistribution/*.jsonl` | - |
| **ScalingStatValues** | 80 | 24 | 16.9 KB | 80 @ 40% | - | `raw/tables/ScalingStatValues/*.jsonl` | - |
| **ScreenEffect** | 52 | 10 | 6.1 KB | 52 @ 0.52% | 1 (0 strong) | `raw/tables/ScreenEffect/*.jsonl` | `f1` Arthas Memory Events |
| **ScreenLocations** | 12 | 2 | 454 B | 12 @ 100% | - | `raw/tables/ScreenLocations/*.jsonl` | `f1` Bottom |
| **SealedCardCosts** | 101 | 25 | 21.3 KB | 101 @ 100% | - | `raw/tables/SealedCardCosts/*.jsonl` | - |
| **SeasonalAppearances** | 259 | 10 | 20.5 KB | 259 @ 71% | - | `raw/tables/SeasonalAppearances/*.jsonl` | - |
| **ServerMessages** | 9 | 18 | 1.8 KB | 9 @ 100% | - | `raw/tables/ServerMessages/*.jsonl` | `f1` [SERVER] %s |
| **SheatheSoundLookups** | 33 | 7 | 1.8 KB | 33 @ 100% | - | `raw/tables/SheatheSoundLookups/*.jsonl` | - |
| **SkillCard** | 7,726 | 12 | 103.7 KB | 7,726 @ 11% | - | `raw/tables/SkillCard/*.jsonl.gz` | `f5` SKILL_CARD_DEFAULT_GOLDEN · `f8` SKILL_CARD_COMMON · `f7` CLASS_HERO |
| **SkillCostsData** | 1,500 | 5 | 64.5 KB | 1,500 @ 100% | - | `raw/tables/SkillCostsData/*.jsonl` | - |
| **SkillLine** | 872 | 56 | 493.8 KB | 872 @ 7.4% | 2 (2 strong) | `raw/tables/SkillLine/*.jsonl` | `f3` !Ascension Manastorm Items · `f20` Armed with an axe, Woodcutters embark on a tr… · `f38` Emboss |
| **SkillLineAbility** | 38,542 | 14 | 265.3 KB | 38,542 @ 0.96% | 477 (389 strong) | `raw/tables/SkillLineAbility/*.jsonl.gz` | - |
| **SkillLineCategory** | 9 | 19 | 1.7 KB | 9 @ 100% | - | `raw/tables/SkillLineCategory/*.jsonl` | `f1` Armor Proficiencies |
| **SkillRaceClassInfo** | 230 | 8 | 15.8 KB | 230 @ 44% | - | `raw/tables/SkillRaceClassInfo/*.jsonl` | - |
| **SkillRaceClassInfo_335** | 0 | 8 | 0 B | - | - | `raw/tables/SkillRaceClassInfo_335/*.jsonl` | - |
| **SkillTiers** | 26 | 33 | 6.8 KB | 26 @ 12% | - | `raw/tables/SkillTiers/*.jsonl` | - |
| **SoundAmbience** | 242 | 3 | 7.8 KB | 242 @ 16% | - | `raw/tables/SoundAmbience/*.jsonl` | - |
| **SoundEmitters** | 632 | 10 | 111.6 KB | 632 @ 36% | - | `raw/tables/SoundEmitters/*.jsonl` | `f9` 451 - Russ Test Vol |
| **SoundEntries** | 45,868 | 30 | 2.2 MB | 45,868 @ 11% | 62 (60 strong) | `raw/tables/SoundEntries/*.jsonl.gz` | `f2` A_HELL_Legion01_Reinf02 · `f3` CAV_Chrono_Banish01.wav · `f4` DrakeadonWoundB.wav |
| **SoundEntriesAdvanced** | 18,810 | 24 | 146.9 KB | 18,810 @ 9.7% | 6 (4 strong) | `raw/tables/SoundEntriesAdvanced/*.jsonl.gz` | `f23` AC_BlackKnight_Aggro01 |
| **SoundFilter** | 20 | 2 | 1.0 KB | 20 @ 100% | - | `raw/tables/SoundFilter/*.jsonl` | `f1` Death Knight BloodElf Female |
| **SoundFilterElem** | 51 | 13 | 8.2 KB | 51 @ 100% | - | `raw/tables/SoundFilterElem/*.jsonl` | - |
| **SoundProviderPreferences** | 32 | 24 | 10.8 KB | 32 @ 36% | - | `raw/tables/SoundProviderPreferences/*.jsonl` | `f1` PRESET_ALLEY |
| **SoundSamplePreferences** | 2 | 17 | 304 B | 2 @ 100% | - | `raw/tables/SoundSamplePreferences/*.jsonl` | - |
| **SoundWaterType** | 12 | 4 | 399 B | 12 @ 41% | - | `raw/tables/SoundWaterType/*.jsonl` | - |
| **SpamMessages** | 133 | 2 | 18.2 KB | 133 @ 98% | - | `raw/tables/SpamMessages/*.jsonl` | `f1` (m\|rn)[^a-z]*(m\|rn)[^a-z]*[o0][^a-z]*[1li][^a… |
| **Spell** | 238,939 | 234 | 21.4 MB | 238,939 @ 1.7% | 157 (140 strong) | `raw/tables/Spell/*.jsonl.gz` | `f136` AB: Blackrock Depths (D1) (PHYS) (HP) · `f170` <Right click to apply this enchant to a piece… · `f187` A Knight of Decay is granting you $s2% increa… |
| **SpellActivationOverlays** | 1,369 | 14 | 231.1 KB | 1,369 @ 100% | - | `raw/tables/SpellActivationOverlays/*.jsonl` | `f2` Textures\\SpellActivationOverlays\\art_of_war · `f9` TRIGGER_TYPE_AURA_EXISTS |
| **SpellAddon** | 5,602 | 23 | 1.0 MB | 5,602 @ 0.35% | 767 (502 strong) | `raw/tables/SpellAddon/*.jsonl` | - |
| **SpellAffect** | 36,779 | 3 | 205.0 KB | 36,779 @ 0.4% | 368 (135 strong) | `raw/tables/SpellAffect/*.jsonl.gz` | - |
| **SpellAlternativeCost** | 0 | 3 | 0 B | - | - | `raw/tables/SpellAlternativeCost/*.jsonl` | - |
| **SpellAlternativePowerType** | 4 | 19 | 733 B | 4 @ 100% | - | `raw/tables/SpellAlternativePowerType/*.jsonl` | `f1` Holy Power (3) |
| **SpellCastTimes** | 71 | 4 | 2.7 KB | 71 @ 34% | - | `raw/tables/SpellCastTimes/*.jsonl` | - |
| **SpellCategory** | 5,189 | 2 | 97.5 KB | 5,189 @ 63% | 6 (6 strong) | `raw/tables/SpellCategory/*.jsonl` | - |
| **SpellChainEffects** | 6,636 | 45 | 338.1 KB | 6,636 @ 0.66% | 302 (155 strong) | `raw/tables/SpellChainEffects/*.jsonl.gz` | `f7` SPELLS\\TEXTURES\\Beam_SmokeGrey.blp |
| **SpellCharges** | 473 | 2 | 10.5 KB | 473 @ 0.022% | - | `raw/tables/SpellCharges/*.jsonl` | - |
| **SpellChargesCategory** | 108 | 3 | 3.0 KB | 108 @ 16% | - | `raw/tables/SpellChargesCategory/*.jsonl` | - |
| **SpellCustomAttr** | 58,583 | 11 | 375.7 KB | 58,583 @ 100% | 73 (0 strong) | `raw/tables/SpellCustomAttr/*.jsonl.gz` | - |
| **SpellDescriptionVariables** | 31 | 2 | 3.6 KB | 31 @ 17% | - | `raw/tables/SpellDescriptionVariables/*.jsonl` | `f1` $absorb=$?s58635[${$m1*$AR*0.01*(100+$58635m1… |
| **SpellDifficulty** | 3,810 | 5 | 228.5 KB | 3,810 @ 74% | - | `raw/tables/SpellDifficulty/*.jsonl` | - |
| **SpellDispelType** | 12 | 21 | 2.4 KB | 12 @ 100% | - | `raw/tables/SpellDispelType/*.jsonl` | `f1` All(M+C+D+P) · `f20` Curse |
| **SpellDuration** | 866 | 4 | 36.4 KB | 866 @ 65% | - | `raw/tables/SpellDuration/*.jsonl` | - |
| **SpellEffectCameraShakes** | 37 | 4 | 1.3 KB | 37 @ 35% | - | `raw/tables/SpellEffectCameraShakes/*.jsonl` | - |
| **SpellEnchantSuggestions** | 1,144,863 | 4 | 6.5 MB | 1,144,863 @ 100% | 400 (0 strong) | `raw/tables/SpellEnchantSuggestions/*.jsonl.gz` | - |
| **SpellFocusObject** | 435 | 18 | 77.9 KB | 435 @ 25% | 1 (1 strong) | `raw/tables/SpellFocusObject/*.jsonl` | `f1` Aerie Peak Town Center |
| **SpellIcon** | 16,361 | 2 | 218.7 KB | 16,361 @ 1.7% | 523 (509 strong) | `raw/tables/SpellIcon/*.jsonl.gz` | `f1` INTERFACE\\ICONS\\ability_mount_celestialhorse |
| **SpellItemEnchantment** | 18,035 | 38 | 261.4 KB | 18,035 @ 1.5% | 138 (130 strong) | `raw/tables/SpellItemEnchantment/*.jsonl.gz` | `f14` +10 Dodge Rating |
| **SpellItemEnchantmentCondition** | 49 | 16 | 7.2 KB | 49 @ 26% | - | `raw/tables/SpellItemEnchantmentCondition/*.jsonl` | - |
| **SpellMechanic** | 31 | 18 | 5.0 KB | 31 @ 100% | - | `raw/tables/SpellMechanic/*.jsonl` | `f1` asleep |
| **SpellMissile** | 170 | 15 | 29.6 KB | 170 @ 2.6% | - | `raw/tables/SpellMissile/*.jsonl` | - |
| **SpellMissileMotion** | 1,786 | 5 | 988.6 KB | 1,786 @ 1.7% | - | `raw/tables/SpellMissileMotion/*.jsonl` | `f1` 7.0 Suramar Catacombs - Thirst for Mana Missi… · `f2` local function sinapprox(v) local t1 = 1.1*v/… |
| **SpellRadius** | 318 | 4 | 12.5 KB | 318 @ 72% | - | `raw/tables/SpellRadius/*.jsonl` | - |
| **SpellRange** | 323 | 40 | 132.0 KB | 323 @ 73% | - | `raw/tables/SpellRange/*.jsonl` | `f6` 1 yards · `f23` 1 yards |
| **SpellRank** | 19,601 | 4 | 847.9 KB | 19,601 @ 100% | 29 (0 strong) | `raw/tables/SpellRank/*.jsonl` | - |
| **SpellRoleSuggestions** | 0 | 4 | 0 B | - | - | `raw/tables/SpellRoleSuggestions/*.jsonl` | - |
| **SpellRuneCost** | 476 | 5 | 19.2 KB | 476 @ 19% | 1 (1 strong) | `raw/tables/SpellRuneCost/*.jsonl` | - |
| **SpellShapeshiftForm** | 61 | 35 | 19.0 KB | 61 @ 97% | - | `raw/tables/SpellShapeshiftForm/*.jsonl` | `f2` Aquatic Form |
| **SpellSpellSuggestions** | 353,193 | 4 | 2.3 MB | 353,193 @ 100% | 268 (0 strong) | `raw/tables/SpellSpellSuggestions/*.jsonl.gz` | - |
| **SpellStatSuggestions** | 1,121 | 4 | 40.2 KB | 1,121 @ 100% | - | `raw/tables/SpellStatSuggestions/*.jsonl` | - |
| **SpellTags** | 488,662 | 3 | 2.6 MB | 488,662 @ 86% | 430 (413 strong) | `raw/tables/SpellTags/*.jsonl.gz` | - |
| **SpellTagTypes** | 200 | 61 | 124.6 KB | 200 @ 23% | - | `raw/tables/SpellTagTypes/*.jsonl` | `f44` Ability School: Frost · `f27` Ability Category · `f26` InterfaceIconsinv_misc_questionmark |
| **SpellVisual** | 23,104 | 32 | 282.4 KB | 23,104 @ 2.2% | 303 (297 strong) | `raw/tables/SpellVisual/*.jsonl.gz` | - |
| **SpellVisualEffectName** | 18,700 | 7 | 520.4 KB | 18,700 @ 0.54% | 365 (256 strong) | `raw/tables/SpellVisualEffectName/*.jsonl.gz` | `f1` 7fx_eonar_rainoffel_precast · `f2` SPELLS/cfx_mage_fireprecast_precastbase.m2 |
| **SpellVisualKit** | 29,541 | 38 | 411.5 KB | 29,541 @ 0.85% | 984 (885 strong) | `raw/tables/SpellVisualKit/*.jsonl.gz` | - |
| **SpellVisualKitAreaModel** | 17 | 3 | 1.1 KB | 17 @ 0.2% | 212 (52 strong) | `raw/tables/SpellVisualKitAreaModel/*.jsonl` | `f1` Spells\\ArcaneShot_Area.mdx |
| **SpellVisualKitModelAttach** | 7,867 | 10 | 825.0 KB | 7,867 @ 0.98% | 17 (13 strong) | `raw/tables/SpellVisualKitModelAttach/*.jsonl` | - |
| **SpellVisualPrecastTransitions** | 3 | 3 | 179 B | 3 @ 100% | - | `raw/tables/SpellVisualPrecastTransitions/*.jsonl` | `f1` LoadBow · `f2` HoldBow |
| **StableSlotPrices** | 4 | 2 | 81 B | 4 @ 100% | - | `raw/tables/StableSlotPrices/*.jsonl` | - |
| **Startup_Strings** | 9 | 19 | 2.4 KB | 9 @ 75% | - | `raw/tables/Startup_Strings/*.jsonl` | `f1` MSG_FRAMEXML_UI_CORRUPT · `f2` Ascension |
| **Stationery** | 7 | 4 | 409 B | 7 @ 10% | - | `raw/tables/Stationery/*.jsonl` | `f2` AUCTIONSTATIONERY |
| **StringLookups** | 9 | 2 | 536 B | 9 @ 100% | - | `raw/tables/StringLookups/*.jsonl` | `f1` Interface\\Buttons\\TalkToMe.mdx |
| **SummonProperties** | 217 | 6 | 10.3 KB | 217 @ 2.8% | - | `raw/tables/SummonProperties/*.jsonl` | - |
| **SuperTrack** | 9,763 | 8 | 217.6 KB | 9,763 @ 45% | 42 (42 strong) | `raw/tables/SuperTrack/*.jsonl.gz` | - |
| **Talent** | 2,368 | 23 | 458.7 KB | 2,368 @ 2.1% | 1 (0 strong) | `raw/tables/Talent/*.jsonl` | - |
| **TalentTab** | 37 | 24 | 9.0 KB | 37 @ 9% | - | `raw/tables/TalentTab/*.jsonl` | `f23` Conjurer · `f1` Acuity |
| **TaxiNodes** | 401 | 24 | 119.2 KB | 401 @ 90% | - | `raw/tables/TaxiNodes/*.jsonl` | `f5` Area 52, Netherstorm |
| **TaxiPath** | 947 | 4 | 35.4 KB | 947 @ 48% | - | `raw/tables/TaxiPath/*.jsonl` | - |
| **TaxiPathNode** | 23,314 | 11 | 560.2 KB | 23,314 @ 50% | 4 (3 strong) | `raw/tables/TaxiPathNode/*.jsonl.gz` | - |
| **TaxiTimes** | 1 | 4 | 30 B | 1 @ 100% | - | `raw/tables/TaxiTimes/*.jsonl` | - |
| **TeamContributionPoints** | 1,400 | 2 | 47.6 KB | 1,400 @ 100% | - | `raw/tables/TeamContributionPoints/*.jsonl` | - |
| **TerrainType** | 12 | 6 | 831 B | 12 @ 100% | - | `raw/tables/TerrainType/*.jsonl` | `f1` Dirt · `f5` Dirt |
| **TerrainTypeSounds** | 10 | 1 | 91 B | 10 @ 100% | - | `raw/tables/TerrainTypeSounds/*.jsonl` | - |
| **TimedDungeons** | 82 | 6 | 4.7 KB | 82 @ 2.5% | - | `raw/tables/TimedDungeons/*.jsonl` | - |
| **TokenTypes** | 61 | 57 | 86.9 KB | 61 @ 100% | - | `raw/tables/TokenTypes/*.jsonl` | `f1` TOKEN_TYPE_CALLBOARD_CACHE_POINTS · `f2` Callboard Cache Progress · `f19` Used to unlearn EITHER Abilities or Talents i… |
| **TotemCategory** | 40 | 20 | 8.2 KB | 40 @ 20% | - | `raw/tables/TotemCategory/*.jsonl` | `f1` Air Totem |
| **TransportAnimation** | 5,422 | 7 | 530.3 KB | 5,422 @ 3% | - | `raw/tables/TransportAnimation/*.jsonl` | - |
| **TransportPhysics** | 7 | 11 | 1.4 KB | 7 @ 11% | - | `raw/tables/TransportPhysics/*.jsonl` | - |
| **TransportRotation** | 227 | 7 | 21.5 KB | 227 @ 14% | - | `raw/tables/TransportRotation/*.jsonl` | - |
| **Tutorial** | 262 | 93 | 452.2 KB | 262 @ 83% | - | `raw/tables/Tutorial/*.jsonl` | `f54` {T:Interface\\Tutorials\\PtA\\129_1:1024:406:102… · `f37` Activate 3 Epic Mystic Enchants · `f35` Ability_Hunter_BeastCall |
| **TutorialCategories** | 3 | 18 | 503 B | 3 @ 60% | - | `raw/tables/TutorialCategories/*.jsonl` | `f1` Getting Started |
| **TutorialKeywords** | 483 | 65 | 528.2 KB | 483 @ 96% | - | `raw/tables/TutorialKeywords/*.jsonl` | `f40` A Mystic Scroll is an item that contains a po… · `f23` A Recipe teaches your character how to craft … · `f6` Active Enchant Slots |
| **TutorialObjectives** | 257 | 24 | 70.8 KB | 257 @ 20% | - | `raw/tables/TutorialObjectives/*.jsonl` | `f7` Activate a Mystic Enchant from your Enchant C… |
| **TutorialObjectiveTypes** | 2 | 19 | 361 B | 2 @ 100% | - | `raw/tables/TutorialObjectiveTypes/*.jsonl` | `f2` Achievement Criteria |
| **TutorialRewards** | 591 | 4 | 24.1 KB | 591 @ 72% | - | `raw/tables/TutorialRewards/*.jsonl` | - |
| **UICameraAppearanceChrRaces** | 240 | 5 | 9.8 KB | 240 @ 100% | - | `raw/tables/UICameraAppearanceChrRaces/*.jsonl` | - |
| **UICameraAppearanceWeapons** | 36 | 5 | 1.5 KB | 36 @ 100% | - | `raw/tables/UICameraAppearanceWeapons/*.jsonl` | - |
| **UICameras** | 271 | 10 | 48.5 KB | 271 @ 100% | - | `raw/tables/UICameras/*.jsonl` | - |
| **UISoundLookups** | 130 | 3 | 7.2 KB | 130 @ 77% | - | `raw/tables/UISoundLookups/*.jsonl` | `f2` ABILIITYPAGETURN |
| **UnitBlood** | 21 | 10 | 3.7 KB | 21 @ 100% | - | `raw/tables/UnitBlood/*.jsonl` | `f5` 0 · `f6` 0 · `f7` 0 |
| **UnitBloodLevels** | 21 | 4 | 666 B | 21 @ 100% | - | `raw/tables/UnitBloodLevels/*.jsonl` | - |
| **VanityCollection** | 10,671 | 77 | 320.6 KB | 10,671 @ 0.096% | 328 (127 strong) | `raw/tables/VanityCollection/*.jsonl.gz` | `f42` Available from the Webstore as part of the Sp… · `f3` Ardenwealdstagmount2-teal-Glow-IngameCollecti… · `f59` Available from the Trial Master's Rewards Ven… |
| **Vehicle** | 614 | 40 | 286.2 KB | 614 @ 7.5% | - | `raw/tables/Vehicle/*.jsonl` | `f29` Arrow.tga · `f30` Interface\\Vehicles\\Vehicle_Target_Base_01.blp · `f31` Interface\\Vehicles\\Vehicle_Target_01.mdx |
| **VehicleSeat** | 1,030 | 58 | 612.8 KB | 1,030 @ 10% | 8 (8 strong) | `raw/tables/VehicleSeat/*.jsonl` | - |
| **VehicleUIIndicator** | 21 | 2 | 1.8 KB | 21 @ 4.7% | - | `raw/tables/VehicleUIIndicator/*.jsonl` | `f1` Interface\\Vehicles\\SeatIndicator\\Vehicle-Bomb… |
| **VehicleUIIndSeat** | 35 | 5 | 2.5 KB | 35 @ 5.2% | - | `raw/tables/VehicleUIIndSeat/*.jsonl` | - |
| **VideoHardware** | 194 | 23 | 64.5 KB | 194 @ 28% | - | `raw/tables/VideoHardware/*.jsonl` | `f18` 4,1;5,1 · `f7` 4,1;5,1 · `f8` 4,1;5,1 |
| **VocalUISounds** | 641 | 7 | 38.1 KB | 641 @ 76% | - | `raw/tables/VocalUISounds/*.jsonl` | - |
| **WeaponImpactSounds** | 30 | 23 | 6.8 KB | 30 @ 34% | - | `raw/tables/WeaponImpactSounds/*.jsonl` | - |
| **WeaponSwingSounds2** | 6 | 4 | 192 B | 6 @ 100% | - | `raw/tables/WeaponSwingSounds2/*.jsonl` | - |
| **Weather** | 34 | 8 | 3.1 KB | 34 @ 31% | - | `raw/tables/Weather/*.jsonl` | `f7` Particles\\LeafBrown.blp |
| **WMOAreaTable** | 24,195 | 28 | 218.0 KB | 24,195 @ 45% | 1 (1 strong) | `raw/tables/WMOAreaTable/*.jsonl.gz` | `f11` Bandit Cave |
| **WorldChunkSounds** | 0 | 9 | 0 B | - | - | `raw/tables/WorldChunkSounds/*.jsonl` | - |
| **WorldMapArea** | 307 | 11 | 44.1 KB | 307 @ 10% | 1 (1 strong) | `raw/tables/WorldMapArea/*.jsonl` | `f3` AdtDevMap |
| **WorldMapContinent** | 4 | 14 | 619 B | 4 @ 100% | - | `raw/tables/WorldMapContinent/*.jsonl` | - |
| **WorldMapOverlay** | 1,068 | 17 | 186.2 KB | 1,068 @ 37% | - | `raw/tables/WorldMapOverlay/*.jsonl` | `f8` AmmenVale |
| **WorldMapTransforms** | 12 | 10 | 1.3 KB | 12 @ 100% | - | `raw/tables/WorldMapTransforms/*.jsonl` | - |
| **WorldSafeLocs** | 915 | 22 | 257.7 KB | 915 @ 13% | 1 (1 strong) | `raw/tables/WorldSafeLocs/*.jsonl` | `f5` AAA - Arena (Dev Test) |
| **WorldStateUI** | 265 | 63 | 190.5 KB | 265 @ 44% | - | `raw/tables/WorldStateUI/*.jsonl` | `f5` %3604w minutes until the battle for Light's H… · `f22` Alliance Reinforcements · `f4` Interface\\TARGETINGFRAME\\AzzarEvent |
| **WorldStateZoneSounds** | 42 | 8 | 2.8 KB | 17 @ 0.41% | - | `raw/tables/WorldStateZoneSounds/*.jsonl` | - |
| **WowError_Strings** | 13 | 19 | 2.7 KB | 13 @ 100% | - | `raw/tables/WowError_Strings/*.jsonl` | `f1` APP_TITLE · `f2` Can not connect to server |
| **ZoneIntroMusicTable** | 179 | 5 | 13.1 KB | 179 @ 3.6% | - | `raw/tables/ZoneIntroMusicTable/*.jsonl` | `f1` AhnQirajInteriorMainEntrance |
| **ZoneLight** | 19 | 7 | 1.8 KB | 19 @ 100% | - | `raw/tables/ZoneLight/*.jsonl` | `f1` Druk'Thar |
| **ZoneLightPoint** | 336 | 5 | 25.1 KB | 336 @ 3.5% | - | `raw/tables/ZoneLightPoint/*.jsonl` | - |
| **ZoneMusic** | 496 | 8 | 60.4 KB | 496 @ 19% | - | `raw/tables/ZoneMusic/*.jsonl` | `f1` Azzar Vertical Ascend - Legion Ascent |
| **ZoneStory** | 20 | 5 | 1.5 KB | 20 @ 100% | - | `raw/tables/ZoneStory/*.jsonl` | `f4` campaign_dracthyrawaken |

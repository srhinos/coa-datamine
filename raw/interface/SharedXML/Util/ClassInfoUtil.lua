ClassInfoUtil = {}

local HeroClassOrder = {
    "DEATHKNIGHT",
    "DRUID",
    "HUNTER",
    "MAGE",
    "PALADIN",
    "PRIEST",
    "ROGUE",
    "SHAMAN",
    "WARLOCK",
    "WARRIOR",
}
local function SortSpecOrder(a, b)
    if a[2] == b[2] then
        return a[1] < b[1]
    end
    
    return a[2] < b[2]
end
function ClassInfoUtil.GetClassSpecOrder(class)
    local specOrder = {}
    local classSpecOrder = {}
    if class == "HERO" then
        for _, class in ipairs(HeroClassOrder) do
            local specs = C_ClassInfo.GetAllSpecs(class)
            wipe(classSpecOrder)
            for _, spec in ipairs(specs) do
                local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
                tinsert(classSpecOrder, { class, spec, specInfo.SortOrder })
            end
            table.sort(classSpecOrder, SortSpecOrder)
            for _, specInfo in ipairs(classSpecOrder) do
                tinsert(specOrder, { specInfo[1], specInfo[2] })
            end
        end
    else
        local specs = C_ClassInfo.GetAllSpecs(class)
        for _, spec in ipairs(specs) do
            local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
            tinsert(classSpecOrder, { class, spec, specInfo.SortOrder })
        end
        table.sort(classSpecOrder, SortSpecOrder)
        for _, specInfo in ipairs(classSpecOrder) do
            tinsert(specOrder, { specInfo[1], specInfo[2] })
        end
    end
    
    return specOrder
end

function ClassInfoUtil.GetClassRoles(class)
	local roles = {}
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		roles.MeleeDPS = roles.MeleeDPS or specInfo.MeleeDPS
		roles.RangedDPS = roles.RangedDPS or specInfo.RangedDPS
		roles.CasterDPS = roles.CasterDPS or specInfo.CasterDPS
		roles.Healer = roles.Healer or specInfo.Healer
		roles.Tank = roles.Tank or specInfo.Tank
		roles.Support = roles.Support or specInfo.Support
	end
	
	return roles
end

function ClassInfoUtil.GetClassArmorProficiency(class)
	local armorTypes = {}
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		armorTypes.Cloth = armorTypes.Cloth or specInfo.Cloth
		armorTypes.Leather = armorTypes.Leather or specInfo.Leather
		armorTypes.Mail = armorTypes.Mail or specInfo.Mail
		armorTypes.Plate = armorTypes.Plate or specInfo.Plate
	end

	return armorTypes
end

function ClassInfoUtil.GetClassAverageComplexity(class)
	local difficulty, numSpecs = 0, 0
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		local difficultyRating = Enum.Complexity[specInfo.DifficultyRating]
		if difficultyRating then
			difficulty = difficulty + difficultyRating
			numSpecs = numSpecs + 1
		end
	end

	if numSpecs <= 0 then
		return Enum.Complexity.Normal
	end

	return math.floor(difficulty / numSpecs)
end

function ClassInfoUtil.GetClassPrimaryResources(class)
	local primaryResources = {}
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		for _, primaryResource in ipairs(specInfo.PrimaryResources) do
			primaryResources[primaryResource] = true
		end
	end
	
	return GetKeysArray(primaryResources)
end

function ClassInfoUtil.GetClassSecondaryResources(class)
	local secondaryResources = {}
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		for _, secondaryResource in ipairs(specInfo.SecondaryResources) do
			secondaryResources[secondaryResource] = true
		end
	end

	return GetKeysArray(secondaryResources)
end

function ClassInfoUtil.GetSpecInfoByIndex(class, index)
	local specs = C_ClassInfo.GetAllSpecs(class)
	return C_ClassInfo.GetSpecInfo(class, specs[index])
end

function ClassInfoUtil.GetSpecInfoByPassiveID(class, passiveID)
	local specs = C_ClassInfo.GetAllSpecs(class)
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		if specInfo.PassiveID == passiveID then
			return specInfo
		end
	end
end

function ClassInfoUtil.GetSpecName(class, spec)
	if not class or not spec then return spec or "" end
	local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
	return specInfo and specInfo.Name or spec or ""
end

function ClassInfoUtil.GetClassName(class)
	if not class then return "" end
	return LOCALIZED_CLASS_NAMES_MALE[class] or class or ""
end

function ClassInfoUtil.GetColoredClassName(class)
	if not class then return nil end
	local color = RAID_CLASS_COLORS[class]
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or class or ""
	if not color then
		return className
	end
	return color:WrapText(className)
end

function ClassInfoUtil.GetColoredSpecName(class, spec)
	if not class or not spec then return nil end
	local color = RAID_CLASS_COLORS[class]
	local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
	local specName = specInfo and specInfo.Name or spec or ""
	if not color then
		return specName
	end
	return color:WrapText(specName)
end

function ClassInfoUtil.GetColoredClassSpecName(class, spec)
	if not class or not spec then return nil end
	local color = RAID_CLASS_COLORS[class]
	local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
	local specName = specInfo and specInfo.Name or spec or ""
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or class or ""
	local combined = (specName ~= "" and className ~= "") and (specName .. " " .. className) or (specName .. className)
	if not color then
		return combined
	end
	return color:WrapText(combined)
end


function ClassInfoUtil.GetDefaultLootSpecID()
	local _, class = UnitClass("player")
	if class == "HERO" then
		local primaryStat = C_PrimaryStat:GetActivePrimaryStat()
		if not primaryStat then
			return 0, NONE
		end
		local _, _, icon, statName = C_PrimaryStat:GetPrimaryStatInfo(primaryStat)
		-- loot spec uses negative values for primary stats
		return -primaryStat, CreateSquareTextureMarkup(icon, 20) .. " " .. statName
	end
	local specs = C_ClassInfo.GetAllSpecs(class)
	local isCoA = IsCustomClass("player")
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		if isCoA and C_CharacterAdvancement.IsKnownID(specInfo.PassiveID) then
			return spec, CreateSquareTextureMarkup("Interface\\Icons\\"..specInfo.SpecFilename, 20) .. " " .. specInfo.Name
		end
	end
end

function ClassInfoUtil.HasLootSpec()
	return false
	--[[local _, class = UnitClass("player")
	if class == "HERO" then
		return C_PrimaryStat:GetActivePrimaryStat() ~= nil
	else
		-- at this time only Heroes get loot specs.
		return
	end
	
	-- NOT RUN
	local specs = C_ClassInfo.GetAllSpecs(class)
	local isCoA = IsCustomClass("player")
	for _, spec in ipairs(specs) do
		local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
		if isCoA and C_CharacterAdvancement.IsKnownID(specInfo.PassiveID) then
			return true
		end
	end]]
end

-- placeholder
if not C_ClassInfo.GetSpecInfoByID then
	function C_ClassInfo.GetSpecInfoByID(specID)
		for _, class in ipairs(CLASS_SORT_ORDER) do
			local specs = C_ClassInfo.GetAllSpecs(class)
			for _, spec in ipairs(specs) do
				local specInfo = C_ClassInfo.GetSpecInfo(class, spec)
				if specInfo.ID == specID then
					return specInfo
				end
			end
		end
	end
end

-- placeholder. Used in mystic enchants to define which class spec belongs to
if not C_ClassInfo.GetClassBySpecName then
	function C_ClassInfo.GetClassBySpecName(specName)
		for _, class in ipairs(CLASS_SORT_ORDER) do
			local specs = C_ClassInfo.GetAllSpecs(class)
			for _, spec in ipairs(specs) do
				if specName == spec then
					return class
				end
			end
		end
	end
end

--[[

TF = CreateFrame("FRAME", "TestFrame", UIParent)
TF:SetSize(100, 100)
TF:SetPoint("CENTER", 0, 0)
TF.rm = CreateFromMixins(DynamicRadialMenu)
TF.data = TF.rm:CreateTest(TF)

]]
DynamicRadialMenu = {}

-- Menu: category[] -> frame[]
-- srcData: category[] -> count

function DynamicRadialMenu:OnLoad()
    self.menu = {}
    self.srcData = {}
end

-- Returns available angle per quadrant
local function CalcAvail(r, dy)
    local r_dy = r - dy
    local dx = math.sqrt(r*r - r_dy*r_dy)
    local angle = math.atan(r_dy/dx)
    return math.deg(angle)
end

-- nihilianth - TODO: Change to support negative?
local function ClampAngle(angle)
    local angle_deg = math.deg(angle)
        if angle_deg > 360 then
            angle_deg = angle_deg % 360
        end
        return angle_deg
end

local function GetClipData(r, centerX, centerY, screenWidth, screenHeight)
    local margin = 0
    local clipData = {}
    clipData[1] = math.max(0, centerX + r - screenWidth) -- right
    clipData[2] = math.max(0, centerY + r - screenHeight) -- top
    clipData[3] = math.max(0,-centerX + r) -- left
    clipData[4] = math.max(0,-centerY + r) -- bottom
    return clipData
end

-- Returns a list of orbits: available angle and startAngle for each
local function GetOutOfBoundOrbits(frame, orbitStep, maxorbitCnt)
    local left, bottom, width, height = frame:GetBoundsRect()
    if not left or not bottom or not width or not height then return end -- nihilianth - TODO: verify
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()

    local centerX = math.floor(left + (width)/2 + 0.5)
    local centerY = math.floor(bottom+ (height)/2 + 0.5)

    --print("center", math.floor(centerX), math.floor(centerY), screenWidth, screenHeight)
    local r_big = math.sqrt(width*width*0.25 + height*height*0.25)

    local oobOrbits = {}
    local angleTaken = 0 -- taken angle in quadrant
    local startAngle = 0 -- start angle for first category

    -- FIXME: Do this properly
    for idx = 0, maxorbitCnt do
        local r = orbitStep[1] + orbitStep[2] * idx -- current orbit radius.
        local angle = 0

        -- Clips for each direction
        local clipData = GetClipData(r, centerX, centerY, screenWidth, screenHeight)

        angleTaken = 0
        startAngle = 0
        local angleMod = 0 -- base rotation (90° per quadrant)
        local clipCnt = 0 -- total number of clips (max. 2!!)

        for i, val in pairs(clipData) do
            if val > 0 then
                local taken = (90 - CalcAvail(r, val)) -- Available -> Taken per quadrant
                -- for startAngle and mod only last values are relevant
                startAngle = taken
                angleMod = (i-1) * 90
                angleTaken = angleTaken + taken
                clipCnt = clipCnt + 1
            end
        end

        if clipData[4] > 0 and clipData[1] > 0 then
            -- Bot + right clip: startAngle from first quadrant
            startAngle = angleTaken - startAngle
            --if startAngle > 360 then
            --    startAngle = startAngle - 360
            --end
        else
            startAngle = startAngle + angleMod -- rotate my quadrant#*90 degrees
        end

        if clipCnt == 1 then
            angleTaken = 2 * angleTaken -- symmetrical for single clip
        elseif clipCnt == 2 then
            angleTaken = angleTaken + 90 -- include corner
        end

        startAngle = startAngle % 360
        angleTaken = 360 - (angleTaken % 360) -- Taken -> Available (4 quadrants)
        oobOrbits[idx+1] = { available=angleTaken, start=startAngle} 

        --print("orbit: ", idx,"Clips: ", clipCnt, "Angle+: ", math.floor(startAngle), "°", "AngleAV: ", math.floor(angleTaken), "°", "AngleMod ", angleMod)
    end
    -- SetClampedToScreen
    -- Keeping this code in case drag bugs (main button overlapped)
    --[[
    local clamp_thresh = 35
    local clipData = GetClipData(clamp_thresh, centerX, centerY, screenWidth, screenHeight, 0)
    local titles = {"rigRem","topRem","lefRem","botRem"}
    for i, val in pairs(clipData) do
        if val > 0 then
            print ("clipping screen ", i, titles[i], val)
        end
    end

    point, relativeTo, relativePoint, xOfs, yOfs = MythicalBoonUI:GetPoint(1)
    -- TODO: Do it in array
    local clampX = 0
    local clampY = 0
    --print(point, xOfs - clipData[1] , yOfs)
    if clipData[1] > 0 then
        clampX = clampX - clipData[1]
    end
    if clipData[2] > 0 then
        clampY = clampY - clipData[2]
    end
    if clipData[3] > 0 then
        clampX = clampX + clipData[3]
    end
    if clipData[4] > 0 then
        clampY = clampY + clipData[4]
    end

    print(point, relativeTo, relativePoint, xOfs, yOfs)
    print(point, xOfs + clampX , yOfs + clampY)
    MythicalBoonUI:ClearAllPoints()
    MythicalBoonUI:SetPoint(point, math.floor(xOfs + clampX), math.floor(yOfs + clampY))
    ]]
    --return angleTaken, startAngle

    return oobOrbits
end

-- WIP? function: pre-calculate point positions
local function CalcOrbitsPerButton(oobRadiusData, config)
    if not oobRadiusData[2] then return end

    buttonsPerOrbit = {}
    
    local numSegments = #config.btnPerCategory
    availMod = {}
    --print("num", #oobRadiusData)
    for i=#oobRadiusData, 2, -1 do
        --local delta = oobRadiusData[i].available - oobRadiusData[i-1].available
        
        --orbitAvailDeg = oobRadiusData[curOrbit +1][1] - (oobRadiusData[curOrbit +1][1]  - oobRadiusData[curOrbit +2][1])* (ratio*0.5)
        local delta = oobRadiusData[i].available - oobRadiusData[i-1].available
        
        local ratio = config.radii[2] / (config.radii[1] * (1+1/i))
        local delta_eff = delta * ratio

        local avail = oobRadiusData[i-1].available + delta * (ratio)
        local start = oobRadiusData[i-1].start
        --print(format("%d, avail:%.2f start:%.2f delta:%.2f ratio%.2f", i-1, avail, start, delta, ratio))
        start = start - (start % 90) * ratio
        availMod[i-1] = {available=avail, start=start}
    end

    for i=1,2 do
        local orbitData = {
            radius = config.radii[1] + config.radii[2] * (i-1),
            availDeg = oobRadiusData[i].available,
            availMod = availMod[i].available,
            scale = oobRadiusData[i].available / 360,
            segmentMid = (oobRadiusData[1].available / numSegments) * 0.5,
            segmentWidth = 360 / #config.btnPerCategory
        }

        
        orbitData.len = orbitData.radius * math.rad(orbitData.availDeg)
        orbitData.cnt = orbitData.len / config.safeZone
        orbitData.req = config.safeZone * orbitData.cnt
        orbitData.mod = orbitData.len % config.safeZone

        orbitData.cnt_floor = math.floor(orbitData.len / config.safeZone)
        orbitData.cnt_floor2 = math.floor((orbitData.len / config.safeZone)+0.5)
        orbitData.cnt_floor3 = math.floor((orbitData.len / config.safeZone)+0.35)
        orbitData.starts = {}
        orbitData.startsMod = availMod[i].start
        for idx=0, numSegments-1 do
            tinsert(orbitData.starts, (orbitData.segmentWidth * idx) * orbitData.scale)
        end
        buttonsPerOrbit[i] = orbitData
        --[[
        local orbitData = {}
        orbitData.radius = config.radii[1] + config.radii[2] * (i-1)
        orbitData.availDeg = oobRadiusData[i].available
        orbitData.len = orbitData.radius * math.rad(orbitData.availDeg) 
        orbitData.cnt = orbitData.len / config.safeZone
        orbitData.segmentMid = (oobRadiusData[1].available / #config.btnPerCategory) * 0.5
        orbitData.segmentWidth = oobRadiusData[1].available / #config.btnPerCategory
        orbitData.scale = oobRadiusData[i].available / 360
        ]]
    end
    if DevTools_DumpCommand ~= nil then
        --DevTools_DumpCommand("buttonsPerOrbit")
    end

    local buttonAssignments = {}
    local usedSlots = {0, 0, 0}

    for orbitID, data in pairs(buttonsPerOrbit) do
        buttonAssignments[orbitID] = {}
        local btnPerCatOrbit = data.cnt / #config.btnPerCategory
        btnPerCatOrbit = math.floor(btnPerCatOrbit + 0.35)
        --print(format("Orbit: %d, cnt: %.2f, perCat: %.2f", orbitID, data.cnt, btnPerCatOrbit))
        --btnPerCatOrbit = math.min(btnPerCatOrbit, )
        --for categoryID, numButtons in pairs(config.btnPerCategory) do
        --    local itemID = BOON_ITEMS_GROUPED[categoryID][]
        --end
        if orbitID == 2 then
            break
        end
    end
    


    for i=0,2 do
        local orbitRadius = config.radii[1] + config.radii[2] * i
        local orbitAvailDeg = oobRadiusData[i+1].available
        local orbitLen = orbitRadius * math.rad(orbitAvailDeg) 
        local cnt = orbitLen / config.safeZone
        local orbitSeg = orbitAvailDeg / #config.btnPerCategory
        --local orbitCenter = (i+1) * orbitSeg - orbitSeg * 0.5
        local orbitCenter = (i+1) * orbitSeg - orbitSeg * 0.5
        --print(format("orbit %d orbitLen: %d avail: %d count: %f orbitSeg: %f", i, math.floor(orbitLen+0.5), orbitAvailDeg, cnt, orbitSeg))
    end
end

local function CreateRadialMenu(frame, config, callback)
    --print("CreateRadialMenu")
    if not config then return end
    local oobRadiusData = GetOutOfBoundOrbits(frame, config.radii, 10)
    -- if #oobRadiusData then
    --     CalcOrbitsPerButton(oobRadiusData, config)
    -- end
    local rmButtons = {}
    local maxCoords = {} -- top, bottom, left, right

    --config.angleLimit = 360
    --config.startAngle = 90

    local numCategories = #config.btnPerCategory
    local orbitAvailDeg = config.angleLimit and config.angleLimit or 360 -- base available orbit
    local segmentWidth_r = math.rad(orbitAvailDeg / numCategories) -- base segment width
    --local segmentWidth_r = math.rad(orbitAvailDeg / ((orbitAvailDeg == 360) and numCategories or (numCategories - 1))) -- length of cat segment in radian
    --print("avail",math.floor(orbitAvailDeg),"segment", rnddeg(segmentWidth_r), orbitAvailDeg / numCategories, numCategories, math.floor(config.startAngle))

    --nihilianth - TODO: is this needed?
    -- Get smallest available angle for first 3 orbits
    local minAvailDeg = 0
    local minAvailAngle = 0
    if oobRadiusData then
        for i=1,3 do
            if oobRadiusData[i].available < minAvailDeg then
                minAvailDeg = oobRadiusData[i].available
                minAvailAngle = oobRadiusData[i].start
            end
        end
    end

    local curOrbit = 0
    for categoryID, numButtons in pairs(config.btnPerCategory) do
        --print(categoryID, numButtons)
        rmButtons[categoryID] = {}

        curOrbit = 0
        local curOrbitCnt = 0
        local processedLastOrbit = 0
        local lastRem = 0
        for idx=0, numButtons - 1 do
            -- Get Clamped orbits and start Angles for out of bounds orbits
            if oobRadiusData then
                local index = math.max(curOrbit+1, 2) -- first will follow second
                orbitAvailDeg = oobRadiusData[index].available
                segmentWidth_r = math.rad(orbitAvailDeg / numCategories)
                config.startAngle = oobRadiusData[index].start

                local orb2 = config.radii[1] + config.radii[2] * index
                local orb1 = config.radii[1] + config.radii[2] * (curOrbit+1)
                local ratio = orb1/orb2
                --print(ratio)
                local delta = oobRadiusData[curOrbit+1].available - oobRadiusData[curOrbit+2].available
                if oobRadiusData[curOrbit +1].available == 360 and curOrbit+2 <= #oobRadiusData and delta < 180 then
                    --print("PRE startangle", math.floor(config.startAngle),"orbitAvailDeg", math.floor(orbitAvailDeg))
                    config.startAngle = config.startAngle - (config.startAngle % 90)*(ratio) -- nihilianth - TODO: verify this
                    --orbitAvailDeg = oobRadiusData[curOrbit +1][1] - (oobRadiusData[curOrbit +1][1]  - oobRadiusData[curOrbit +2][1])* (ratio*0.5)
                    local delta = oobRadiusData[curOrbit+1].available - oobRadiusData[curOrbit+2].available
                    orbitAvailDeg = oobRadiusData[curOrbit+2].available + delta * (ratio)
                    segmentWidth_r = math.rad(orbitAvailDeg / numCategories)
                    --print("startangle", math.floor(config.startAngle),"orbitAvailDeg", math.floor(orbitAvailDeg))
                end
                --config.startAngle = math.min(minAvailAngle, config.startAngle)
            else
                --print("No OOB data")
            end

            -- nihilianth - TODO: When segment width changes -> update
            local segmentMid_r = (categoryID) * segmentWidth_r - segmentWidth_r * 0.5 -- Center angle of the categories

            -- radius of current orbit
            local orbitRadius = config.radii[1] + config.radii[2] * curOrbit
            -- total length of the orbit
            local orbitLen = orbitRadius * math.rad(orbitAvailDeg) 
            
            -- length of the segment (active category)
            local orbitLenSegment = orbitLen / numCategories
            
            -- Safe zone in pixels -> radians on current orbit
            local safeZone_r = (config.safeZone / orbitLenSegment) * segmentWidth_r
            --print("safe_r", (config.safeZone / orbitLenSegment), rnddeg(segmentWidth_r), rnddeg(safeZone_r))
            
            -- Number of buttons that can be placed on this orbit
            -- try to clamp to remainder
            local segmentLenBtn_frac = (orbitLenSegment / config.safeZone)
            local orbitBtn_noclamp = math.floor(segmentLenBtn_frac+0.35)
            --[[ 
            -- nihilianth - FIXME: This is broken : check the remainder from last category to fill with buttons
            if lastRem and lastRem > 0 then
                --orbitBtn_noclamp = math.floor(segmentLenBtn_frac)
                print(type(orbitBtn_noclamp), type(segmentLenBtn_frac), type(lastRem), type(segmentLenBtn_frac + lastRem))
                
                local val = (segmentLenBtn_frac + lastRem)
                if orbitBtn_noclamp < val then
                    val = math.floor(val)
                    lastRem = segmentLenBtn_frac + lastRem - val
                    orbitBtn_noclamp = val
                end
            end
            ]]
            if (orbitLenSegment / config.safeZone) < 1 then
                --print("btn too close", (orbitLenSegment / config.safeZone))
            end

            -- Clamp the number, relevant for last data row centering
            local orbitBtnCnt = math.min(orbitBtn_noclamp, numButtons - processedLastOrbit)
            --lastRem = (orbitLenSegment / config.safeZone) - orbitBtn_noclamp

            if (segmentWidth_r < safeZone_r) then
                --print("Segment smaller than safeZone!", math.floor(lastRem*100), categoryID, idx, math.floor((segmentWidth_r/safeZone_r)*100))
            end
            
            -- Shift right and shift left to center
            local angle_r =math.rad(config.startAngle) + segmentMid_r  + math.min(safeZone_r, segmentWidth_r) * (curOrbitCnt - math.max(0, orbitBtnCnt-1)/2)
            --print("Angle", rnddeg(angle_r))
            -- nihilianth - TODO: limit by x and y?
            local x = orbitRadius * math.cos(angle_r)
            local y = orbitRadius * math.sin(angle_r)

            -- nihilianth - TODO: meh. also: better with just orbitRadius?
            -- top, bottom, left, right
            if not maxCoords[1] or y + config.safeZone > maxCoords[1] then
                maxCoords[1] = y + config.safeZone
            end
            if not maxCoords[2] or y - config.safeZone < maxCoords[2] then
                maxCoords[2] = y - config.safeZone
            end
            if not maxCoords[3] or x - config.safeZone < maxCoords[3] then
                maxCoords[3] = x - config.safeZone
            end
            if not maxCoords[4] or x + config.safeZone > maxCoords[4] then
                maxCoords[4] = x + config.safeZone
            end
            -- nihilianth - TODO: clamp to screen?

            --[[
            if false and orbitBtn_noclamp >= (numButtons - processedLastOrbit) then
                print("clamp at orbit: ", curOrbit, orbitBtn_noclamp, "->",(numButtons - 1 - processedLastOrbit))
                print("numButtons", numButtons)

                
                print("cat", categoryID, idx+1)
                print("Angle", math.deg(angle_r))
                print("segmentMid_r",math.deg(segmentMid_r))
                print("orbitBtn_noclamp", orbitBtn_noclamp)
                print("orbitBtnCnt", orbitBtnCnt)
                print("orbitBtnCnt mod",  (curOrbitCnt - math.min(0, orbitBtnCnt-1)/2))
                print("processedLastOrbit", processedLastOrbit)
            end
            ]]
            ----
            local btn = nil
            if callback then
                btn = callback(categoryID, idx+1, x, y, curOrbit, segmentWidth_r/safeZone_r)
            end

            if btn then
                rmButtons[categoryID][idx+1] = btn
            else
                rmButtons[categoryID][idx+1] = {x = x, y = y}
            end
            ----

            curOrbitCnt = curOrbitCnt + 1
            if curOrbitCnt >= orbitBtnCnt then
                curOrbitCnt = 0
                curOrbit = curOrbit + 1
                processedLastOrbit = processedLastOrbit + orbitBtnCnt
            end
        end
    end

    return rmButtons, maxCoords, curOrbit - 1
end

function DynamicRadialMenu:CreateTest(frame)
    local rmConfig = {}
    rmConfig.btnPerCategory = {} -- Number of buttons for each category
    rmConfig.radii = {100, 100} -- first row radius, other row radii
    rmConfig.safeZone = 120 -- Safe zone around buttons
    rmConfig.startAngle = 90 -- Angle of the first category
    rmConfig.catSafeZone = rmConfig.safeZone
    rmConfig.angleLimit = 360
    rmConfig.startAngle = 90

    rmConfig.btnPerCategory = {4, 5, 6, 2}
    -- for idx, data in pairs(BOON_ITEMS_GROUPED) do
    --     rmConfig.btnPerCategory[idx] = #data
    -- end

    local buttons, maxcoords, orbit = CreateRadialMenu(frame, rmConfig, nil)
    return buttons, maxcoords, orbit
end

function DynamicRadialMenu:Create(frame, config, callback)
    local buttons, maxcoords, orbit = CreateRadialMenu(frame, config, callback)
    return buttons, maxcoords, orbit
end

function DynamicRadialMenu:Update()
end

function DynamicRadialMenu:Show(withAnim)
end

function DynamicRadialMenu:Hide(withAnim)
end
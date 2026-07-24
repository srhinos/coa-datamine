function GetTexCellCoord(cellX, cellY, cellWidth, cellHeight, textureWidth, textureHeight)
    local left = ((cellX - 1) * cellWidth) / textureWidth
    local right = (cellX * cellWidth) / textureWidth

    local top = ((cellY - 1) * cellHeight) / textureHeight
    local bottom = (cellY * cellHeight) / textureHeight

    return left, right, top, bottom
end

function SetParentArray(frame, key, pos)
    if not frame or not frame.GetParent then return end
    
    local parent = frame:GetParent()
    if not parent then return end

    if not parent[key] then
        parent[key] = {}
    end

    if pos then
        tinsert(parent[key], pos, frame)
    else
        tinsert(parent[key], frame)
    end
    
    return parent[key]
end

function SetParentTableKey(frame, key, value)
    if not frame or not frame.GetParent then return end
    
    local parent = frame:GetParent()
    if not parent then return end

    if not parent[key] then
        parent[key] = {}
    end

    parent[key][value] = frame
    
    return parent[key]
end

function StringToGlobalTableEntry(str)
    if not str or str == "" then
        return nil
    end
    
    -- Split the string by dots
    local parts = {}
    for part in string.gmatch(str, "[^%.]+") do
        -- Check if part contains only valid characters (letters, numbers, underscore)
        if not string.match(part, "^[%w_]+$") then
            return nil
        end
        
        -- Check if part starts with a digit
        if string.match(part, "^%d") then
            return nil
        end
        
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        return nil
    end
    
    -- Build result
    local result = _G
    for i, key in ipairs(parts) do
        if type(result) ~= "table" then
            return nil
        end
        
        result = result[key]
        if result == nil then
            return nil
        end
    end
    
    return result
end

function CheckGlobalFromAttributeString(value)
    if type(value) == "string" then
        if value:startswith("global:") then
            return StringToGlobalTableEntry(strsub(value, 8))
        end
    end
    
    return value
end

function AttributesToKeyValues(self, ...)
    local objectType = self.GetObjectType and self:GetObjectType()
    if objectType and (objectType == "FontString" or objectType == "Texture") then
        -- attributes are already key values on fontstring / texture
        return
    end
    local numArgs = select("#", ...)
    if numArgs > 0 then
        for i = 1, numArgs do
            local name = select(i, ...)
            local value = self:GetAttribute(name)
            if value ~= nil then
                value = CheckGlobalFromAttributeString(value)
                self[name] = value
            end
            self:SetAttribute(name, nil)
        end
    else
        local attributes = self:GetAllAttributes()
        for key, value in pairs(attributes) do
            value = CheckGlobalFromAttributeString(value)
            self[key] = value
            self:SetAttribute(key, nil)
        end
    end
end

function UseParentLevel(frame)
    local parent = frame:GetParent()
    if parent then
        frame:SetFrameLevel(parent:GetFrameLevel())
    end
end

function OnEnterParent(self)
    if self.GetParent then
        local parent = self:GetParent()
        return parent and parent:CallScript("OnEnter")
    end
end

function OnLeaveParent(self)
    if self.GetParent then
        local parent = self:GetParent()
        return parent and parent:CallScript("OnLeave")
    end
end

function SetPercentagePoint(frame, point, parent, x, y, relativePoint)
    if type(parent) == "number" then
        x, y = parent, x
        parent = frame:GetParent()
    end
    local w, h = GetScreenSize()
    frame:SetPoint(point, parent, relativePoint or point, x * w, y * h)
end

function CreateFrames(parent, array, num, template)
    if not parent[array] then
        parent[array] = {}
    end

    while #parent[array] < num do
        local frame = CreateFrame("Frame", nil, parent, template)
        tinsert(parent[array], frame)
    end

    for i = num + 1, #parent[array] do
        parent[array][i]:Hide()
    end
end

function LineUpFrames(frames, maxPerRow, anchorPoint, anchor, relativePoint, width, spacing, distance)
    local num = #frames
    local numButtons = math.min(maxPerRow, num)
    local fullWidth = (width * numButtons) + (spacing * (numButtons - 1))
    local halfWidth = fullWidth / 2

    local numRows = math.floor((num + maxPerRow - 1) / maxPerRow) - 1
    local fullDistance = numRows * frames[1]:GetHeight() + (numRows + 1) * distance

    -- First frame
    frames[1]:ClearAllPoints()
    frames[1]:SetPoint(anchorPoint, anchor, relativePoint, -halfWidth, fullDistance)

    -- first row
    for i = 2, math.min(maxPerRow, #frames) do
        frames[i]:SetPoint("LEFT", frames[i-1], "RIGHT", spacing, 0)
    end

    -- n-rows after
    if (num > maxPerRow) then
        local currentExtraRow = 0
        local finished = false
        repeat
            local setFirst = false
            for i = (maxPerRow + (maxPerRow * currentExtraRow)) + 1, (maxPerRow + (maxPerRow * currentExtraRow)) + maxPerRow do
                if (not frames[i]) then
                    finished = true
                    break
                end
                if (not setFirst) then
                    frames[i]:SetPoint("TOPLEFT", frames[i - (maxPerRow + (maxPerRow * currentExtraRow))], "BOTTOMLEFT", 0, -distance)
                    setFirst = true
                else
                    frames[i]:SetPoint("LEFT", frames[i-1], "RIGHT", spacing, 0)
                end
            end
            currentExtraRow = currentExtraRow + 1
        until finished
    end
end

function NumberToK(number)
    if type(number) ~= "number" then
        number = tonumber(number)
    end
    
    if not number then return "" end
    
    if number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function NumberToM(number)
    if type(number) ~= "number" then
        number = tonumber(number)
    end
    
    if not number then return "" end
    
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    else
        return tostring(number)
    end
end

function ShortenNumber(number, noDecimal)
    if type(number) ~= "number" then
        number = tonumber(number)
    end
    
    if not number then return "" end
    
    if number >= 1000000 then
        if noDecimal then
            return string.format("%dM", number / 1000000)
        end
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        if noDecimal then
            return string.format("%dK", number / 1000)
        end
        return string.format("%.1fK", number / 1000)
    else
        return tostring(number)
    end
end

function SeparateBigNumber(number)
    if number < 1000 then
        return tostring(number)
    end

    local str = tostring(number)
    local formatted = str:reverse():gsub("(%d%d%d)", "%1,")
    formatted = formatted:reverse():gsub("^,", "")
    return formatted
end

function PassClickToParent(self, button)
    if not self.GetParent then return end
    local parent = self:GetParent()
    if not parent or not parent.Click then return end
    self:GetParent():Click(button)
end

-- Breaks large numbers up into comma separeted numbers
function BreakUpLargeNumbers(value)
    if not value then return end
    local number = tonumber(value)
    if not number then return end
    number = math.trunc(number, 2)
    if number < 0 and number > -1000 then return number end
    if number > 0 and number < 1000 then return number end

    local formatted = tostring(number)
    while true do
        local output, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        formatted = output
        if (k==0) then
            break
        end
    end
    return formatted
end

-- returns a money string but with the large numbers broken up into comma separated numbers
function BreakUpLargeMoneyString(money, noIcons)
	local goldString, silverString, copperString;
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = mod(money, COPPER_PER_SILVER)
	
	if ( ENABLE_COLORBLIND_MODE == "1" or noIcons ) then
		goldString = BreakUpLargeNumbers(gold)..GOLD_AMOUNT_SYMBOL;
		silverString = BreakUpLargeNumbers(silver)..SILVER_AMOUNT_SYMBOL;
		copperString = BreakUpLargeNumbers(copper)..COPPER_AMOUNT_SYMBOL;
	else
		goldString = format("%s|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t", BreakUpLargeNumbers(gold));
		silverString = format("%s|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t", BreakUpLargeNumbers(silver));
		copperString = format("%s|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t", BreakUpLargeNumbers(copper));
	end
	
	local moneyString = "";
	local separator = "";	
	if ( gold > 0 ) then
		moneyString = goldString;
		separator = " ";
	end
	if ( silver > 0 ) then
		moneyString = moneyString..separator..silverString;
		separator = " ";
	end
	if ( copper > 0 or moneyString == "" ) then
		moneyString = moneyString..separator..copperString;
	end
	
	return moneyString;
end

function GetRealmSpecificGlobalString(key, returnsDefault)
    if string.isNilOrEmpty(key) then
        return key
    end

    local realmID = GetRealmId and GetRealmId()
    -- 10/04/2025 change malfurion realmID to bronzebeard
    -- 8 = bronzebeard ptr 
    if realmID == 5 or realmID == 8 then
        realmID = 16
    end
    local text = realmID and _G[key.."_REALM_"..realmID] or _G[key]
    if text then
        return text
    end

    if returnsDefault then
        return key
    end
end
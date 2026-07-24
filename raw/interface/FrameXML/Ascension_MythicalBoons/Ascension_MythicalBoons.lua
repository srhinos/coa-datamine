
-- Feature Wishlist
--[[
- Show newly looted boon (as floating icon?) <- or animation on main button if at least one is looted
- Show boon expiring in (<2 min?)
- Display a frame when someone activates a boon
 (e.g. MB Activated: <Name> -> shorted bonus info)
- Show the total amount of boons in bags
- Track group's boons
]]

local SetButtonVisual = nil

local BoonCat = {
    SPELLS = 1,
    BUFFS = 2,
    DEFENSE = 3,
}

local BoonCatNames = {
    "Spells and Abilities",
    "Buffs",
    "Defense"
}

-- name, category, isMeleeOnly, spellID, effectSpellID
-- spellID matches itemID, kept for future changes only
-- TODO: don't look up by index?
local BOON_ITEMS = {
	[2104920] = { "Ascension",    BoonCat.SPELLS,      false,   2104920, 0},          -- Damage + Healing 20%    
	[2104921] = { "Infinity",     BoonCat.SPELLS,      false,   2104921, 0},          -- Cooldown + Cost 20%     
	[2104922] = { "Momentum",     BoonCat.BUFFS,       false,   2104922, 0},          -- Haste + Movement Speed  
	[2104923] = { "Inquisition",  BoonCat.DEFENSE,     false,   2104923, 2104924},    -- Damage Shield  -- Inquisition effect spell ID for tooptip     
	[2104925] = { "Sanctuary",    BoonCat.DEFENSE,     false,   2104925, 0},          -- Damage Taken 15%        
	[2104926] = { "Bountiful",    BoonCat.BUFFS,       false,   2104926, 0},          -- STATS 20%               
	[2104927] = { "Piercing",     BoonCat.BUFFS,       true,    2104927, 0},          -- ARP + EXP                
	[2104928] = { "Critical",     BoonCat.SPELLS,      false,   2104928, 0},          -- Crit 20%                
	[2104929] = { "Sanctified",   BoonCat.DEFENSE,     false,   2104929, 2104929},          -- 3% hpps                 
	[2104930] = { "Adaptation",   BoonCat.SPELLS,      true,    2104930, 0},          -- sp from ap 20%           
	[2104931] = { "Ruthlessness", BoonCat.BUFFS,       false,   2104931, 0},          -- crit damage / heal 20%  
	[2104932] = { "Wrathful",     BoonCat.BUFFS,       false,   2104932, 0},          -- SP + AP flat            
	[2104933] = { "Phasewalk",    BoonCat.DEFENSE,     false,   2104933, 2104933}           -- vanish
}

local BOON_STORAGE = {}
local PARSED_BUFF_TYPES = {}
local LAST_USED_BOON = 0
local MythicalBoonTooltip = CreateFrame("GameTooltip", "MythicalBoonTooltip", UIParent, "GameTooltipTemplate")

-- Helper Functions

local function InitOwnedBoons()
    BOON_STORAGE = {}
    for bag, bagData in pairs(C_InventoryState.Inventory) do
        for slot, slotData in pairs(bagData) do
            if BOON_ITEMS[slotData.item] ~= nil then
                if not BOON_STORAGE[slotData.item] then
                    BOON_STORAGE[slotData.item] = {}
                end
                tinsert(BOON_STORAGE[slotData.item], {bag=bag, slot=slot})
            end
        end
    end
end

--- *** VISUALS  *** 
-- Highlight by changing color Value
function MythicalBoonUI_SetButtonHighlight(btn, state)
    local color = CreateColor(btn.iconBorder:GetVertexColor())
    color:SetSaturation(state and 0.5 or 1)
    btn.iconBorder:SetVertexColor(color:GetRGBA())
    if btn.iconBorderHL then
        btn.iconBorderHL:SetVertexColor(color:GetRGBA())
    end
end
--- *** VISUALS END *** 


--- *** ANIMATIONS  *** 
--[[ damped sine wave
local t = (1-fraction) *10
local amplitude = self.bounceAmp and self.bounceAmp or 12
local y_off = self.origY and self.origY or 0
local y_rot = y_off + amplitude * math.exp(-t*0.75) * math.sin(2*math.pi*(t-0.5))
]]

-- TODO: make custom anim function?

local function dampedSineWave(A, d, t, phi, timeScale)
    local timeScale = timeScale and timeScale or 1
    return A * math.exp(-t * timeScale * d) * math.sin(2 * math.pi * (t * timeScale - phi))
end

local function MythicalBoonUI_PressedBounceAnim(self, fraction)
    local y_t = 1 + dampedSineWave(0.5, 0.75, fraction, 0.5, 2.5)
    return  y_t;
end

local function MythicalBoonUI_FizzleBounceAnim(self, fraction)
    local parent = self:GetParent()
    local frac_r = fraction * 2 * math.pi * 1.5 * 5
    local y_t = math.cos(frac_r) + 0.2 * math.cos(10*frac_r)
    self:ClearAllPoints()
    if (math.abs(y_t) < 0.6) then
        return "CENTER", 0, 0
    else
        return "CENTER", 0 + 5 * y_t, 0
    end
end

local MythicalAnims = 
{
    BTN_PRESSED = {
        totalTime = 0.5,
        updateFunc = "SetScale",
        getPosFunc = MythicalBoonUI_PressedBounceAnim,
    },
    BTN_FIZZLE = {
        totalTime = 0.5,
        updateFunc = "SetPoint",
        getPosFunc = MythicalBoonUI_FizzleBounceAnim,
    }
}

--[[
-- Deprecated
local function MythicalBoonUI_BounceAnim(self, fraction)
    local y = self.origY or 0
    local y_t = y + dampedSineWave(12, 0.75, fraction, 0.5, 10)
    return "CENTER", self.origX or 0, y_t
end

local MythicalBoonUIAnimTable = {
	totalTime = 3,
	updateFunc = "SetPoint",
	getPosFunc = MythicalBoonUI_BounceAnim,
}

local MythicalBoonPressedAnimTable2 = {
    totalTime = 0.5,
    updateFunc = "SetPoint",
    getPosFunc = function(self) return self:GetPoint(1) end, -- nihilianth - TODO: find a way around this
}

local function MythicalBoonHighlight_OnUpdateAnim(self, fraction)
    fraction = math.log(fraction + 1)
    return 0, 2241 - (2241-1331)*fraction
end

local MythicalBoonHighlightAnimTable = {
    totalTime = 0.5,
    updateFunc = "SetSequenceTime",
    getPosFunc = MythicalBoonHighlight_OnUpdateAnim, 
}


local function MythicalBoonUI_ActiveBounceAnim(self, fraction)
    if self.Cooldown:IsVisible() then
        --print("fixed to place")
        return "CENTER", self.origX, self.origY
    end
    
    local phase = math.pi * 2 * (self.itemID - 2104920) / 13 -- randomness
    --print(self.itemID - 2104920, rnddeg(phase))
    fraction = math.log(fraction+1)
    local frac_r = fraction * 2 * math.pi
    local amp = 5
    local y_t = 0.8 + 0.4 * math.cos(15*frac_r)
    return  "CENTER", self.origX + amp* y_t * math.sin(3*frac_r + phase), self.origY + amp* y_t * math.cos(3*frac_r + phase);
end

local MythicalBoonActiveAnimTable = {
    totalTime = 1,
    updateFunc = "SetPoint",
    getPosFunc = MythicalBoonUI_ActiveBounceAnim,
}

local MythicalBoonCooldownAnimTable = {
    totalTime = 1.5,
    updateFunc = "SetRotation",
    getPosFunc = function(self, fraction) return fraction * 2 * math.pi end
}
    
-- TODO: Replace this
local RotationAnimTable = {
    totalTime = 2,
    updateFunc = "SetRotation",
    getPosFunc = function(self, fraction) return fraction * 2 * math.pi end
}   

-- TODO: Replace this
local GrowAnimTable = {
    totalTime = 2,
    updateFunc = "SetSize",
    
    getPosFunc = function(self, fraction) local sz = 100 + fraction * (math.sqrt(2) - 1); return sz, sz end
}
local function MythicalBoonUI_ActiveBounceAnimFinished(self)
    SetButtonVisual(self:GetParent(), nil, "MythicalBoonUI_ActiveBounceAnimFinished")
end

local function MythicalBoonUI_ButtonAnimEnd(self)
    SetButtonVisual(self, nil, "MythicalBoonUI_ButtonAnimEnd")
end
]]

local function MythicalBoonUI_ButtonAnimEndParent(self)
    SetButtonVisual(self:GetParent(), nil, "MythicalBoonUI_ButtonAnimEndParent")
end

--- *** ANIMATIONS END *** 


--- *** RADIAL MENU ***

local function Calc(baseVal, dy)
    local r = baseVal / 2 
    local r_dy = r - dy
    local dx = math.sqrt(r*r - r_dy*r_dy)
    local angle = math.atan(r_dy/dx)
    return angle
end

--- *** SHORT DESC ***
-- Parse Spell descriptions to short form
local function ParseBoonDescriptions()
    for itemID, boonData in pairs(BOON_ITEMS) do
        Item:Query(itemID)
        local name = boonData[1]
        local cat = boonData[2]
        local meleeOnly = boonData[3]
        local spellID = boonData[4]
        local effectSpellID = boonData[5]

        local desc = C_Spell:GetSpellDescription(spellID)
        if desc == nil then desc = ""; print("no description for ", spellID) end
        local data = {}
        local percentage = nil
        local curIdx = nil
        -- Bonus names and percentage are colored
        for occurence in desc:gmatch("|c........([A-Za-z0-9, %%]+)|r") do
            if occurence:find("%%") or tonumber(occurence) then
                if curIdx ~= nil then
                    data[curIdx].bonus = occurence
                else
                    tinsert(data, {occurence}) -- add bonus as line
                end
            elseif occurence:find(" sec") then
                data.duration = occurence
            else
                if occurence:find(",") then
                    for occ_split in occurence:gmatch('([^,]+)') do
                        occ_split = occ_split:gsub("^%s*", "")
                        
                        if curIdx and not data[curIdx].bonus then
                            tinsert(data[curIdx], occ_split)
                        else
                            tinsert(data, {occ_split})
                            curIdx = #data
                        end
                    end
                else
                    if curIdx and not data[curIdx].bonus then
                        tinsert(data[curIdx], occurence)
                    else
                        tinsert(data, {occurence})
                        curIdx = #data
                    end
                end
            end
        end
        
        PARSED_BUFF_TYPES[itemID] = data
        --end

    end
end

--- *** SHORT DESC END***


--- *** BOON BUTTON ***

local BOON_BTN_CNT = 13
local BOON_BTN_RADIUS = 100
local BOON_BTNS = {}

local BOON_ITEMS_GROUPED = {}

local BtnVisualStates = 
{
    HIDDEN = 1,
    VISIBLE = 2,
    DISABLED = 3,
    ENABLED = 4,
    FIZZLE = 5,
    CLICKED = 6
}

local BtnVisualNames = 
{
    "HIDDEN",
    "VISIBLE",
    "DISABLED",
    "ENABLED",
    "FIZZLE",
    "CLICKED"
}

SetButtonVisual = function(btn, newState, src)
    local curState = nil
    local pendingState = 0 -- transition

    if btn.vState == nil then
        btn.vState = { state=BtnVisualStates.ENABLED, pending= 0 }
        curState = btn.vState.state
    else
        curState = btn.vState.state
        pendingState = btn.vState.pending
    end

    --print(btn:GetName(), BtnVisualNames[curState], BtnVisualNames[newState], src)

    if newState == nil then
        -- animation ended
        -- check for pending state
        if pendingState == 0 then
            newState = curState
        else
            newState = pendingState
        end
    elseif pendingState > 0 then
        -- pending state -> update too early
        return
    end

    local itemID = btn.itemID
    local isOwned = BOON_STORAGE[itemID] ~= nil
    local inCombat = MythicalBoonUI.inCombat --InCombatLockdown()
    local shortName = BOON_ITEMS[itemID][1]

    -- Gray out if not active
    local inactive = not isOwned and inCombat
    btn.icon:SetDesaturated(not isOwned)
    btn.iconBorder:SetDesaturated(not isOwned)
    btn.iconBorderHL:SetDesaturated(not isOwned)
    --btn:EnableMouse(not inactive)

    if newState == curState then
        --print(BOON_ITEMS[itemID][1], "same state", BtnVisualNames[curState], isOwned)
    end

    --print(format("%s: %s -> %s pending(%s)",shortName, BtnVisualNames[curState], BtnVisualNames[newState], pendingState and BtnVisualNames[pendingState] or "None"))

    if newState == BtnVisualStates.HIDDEN then
    elseif newState == BtnVisualStates.VISIBLE then
    elseif newState == BtnVisualStates.DISABLED then
    elseif newState == BtnVisualStates.ENABLED then
        btn.vState.pending = 0
        local itemCnt = 0
        if isOwned then
            itemCnt = #BOON_STORAGE[itemID]
            btn:SetAttribute("type", "item")
            btn:SetAttribute("item", format("%d %d", BOON_STORAGE[itemID][1].bag, BOON_STORAGE[itemID][1].slot))
            btn.iconBorderHL:Show()
            btn.iconBorder:Hide()
            btn.iconBorderHL.animActive:Play()
        else
            btn:SetAttribute("type", "")
            btn:SetAttribute("item", "")
            btn.iconBorderHL:Hide()
            btn.iconBorder:Show()
        end

        if itemCnt > 1 then
            btn.StackCount:SetText(tostring(itemCnt))
            btn.StackIcon:Show()
            btn.StackCount:Show()
        else
            btn.StackIcon:Hide()
            btn.StackCount:Hide()
        end
        
    elseif newState == BtnVisualStates.FIZZLE then
        btn.vState.pending = BtnVisualStates.ENABLED
        SetUpAnimation(btn.iconBorderHL, MythicalAnims.BTN_FIZZLE, nil, false)
        SetUpAnimation(btn.iconBorder, MythicalAnims.BTN_FIZZLE, nil, false)
        SetUpAnimation(btn.icon, MythicalAnims.BTN_FIZZLE, MythicalBoonUI_ButtonAnimEndParent, false)
        --PlaySound(10846)
    elseif newState == BtnVisualStates.CLICKED then
        if isOwned then
        else
            btn.iconBorderHL.animActive:Stop()
            btn.iconBorderHL.animInactive:Play()
            btn.vState.pending = BtnVisualStates.ENABLED
        end
        SetUpAnimation(btn, MythicalAnims.BTN_PRESSED, nil, false)
        --PlaySound(5044)
    else
    end

    if newState then
        btn.vState.state = newState
    else

    end
end

-- Combat -> centered shortened toltips or spell tooltip
-- otherwise: item tooltip
local function SetUpTooltips(self)
    local inCombat = MythicalBoonUI.inCombat--InCombatLockdown()
    local boonData = BOON_ITEMS[self.itemID]
    local spellNameShort = boonData[1]
    local boonCat = boonData[2]
    local ttSpellID = boonData[5]

    if inCombat then
        MythicalBoonTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, 0)
        if ttSpellID > 0 then
            MythicalBoonTooltip:SetHyperlink("spell:"..ttSpellID)
        else
            MythicalBoonTooltip:AddLine(spellNameShort)
            MythicalBoonTooltip:AddLine(BoonCatNames[boonCat])
            for itemID, data in ipairs(PARSED_BUFF_TYPES[self.itemID]) do
                if type(data) ~= "string" then
                    for idx, datum in ipairs(data) do
                        MythicalBoonTooltip:AddDoubleLine(datum, data.bonus, 1, 1, 1, 0, 1, 0)
                    end
                end
            end
            MythicalBoonTooltip:AddDoubleLine("Duration", PARSED_BUFF_TYPES[self.itemID].duration, 1,1,1, 0,1,0)
        end
        MythicalBoonTooltip:Show()
        GameTooltip:Hide()
    else
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 0, 0)
        local bag, slot = strmatch(self:GetAttribute("item"), "^(%d+)%s+(%d+)$")
        if bag ~= nil then
            GameTooltip:SetBagItem(tonumber(bag), tonumber(slot))
        elseif self.itemID ~= nil then
            GameTooltip:SetHyperlink("item:"..self.itemID)
        end
        MythicalBoonTooltip:Hide()
        GameTooltip:Show()
    end
end

function MythicalBoonBtn_OnEnter(self)
    MythicalBoonUI_SetButtonHighlight(self, true)
    SetUpTooltips(self)
end

function MythicalBoonBtn_OnLeave(self)
    MythicalBoonUI_SetButtonHighlight(self, false)
    GameTooltip:Hide()
    MythicalBoonTooltip:Hide()
end

function MythicalBoonBtn_InactiveOnFinished(self)
    SetButtonVisual(self:GetRegionParent():GetParent(), nil)
    self:GetRegionParent():Hide();
end

local function InitBoonButton(name, q)
    --print("InitBoonButton")
    local btn = CreateFrame("Button", name, MythicalBoonUI, "MythicalBoonBtn")
    SetPortraitToTexture(btn.icon, "Interface\\Icons\\spell_mage_focusingcrystal")
    btn.iconBorder:SetVertexColor(ITEM_QUALITY_COLORS[q]:GetRGBA())
    btn.iconBorderHL:SetVertexColor(ITEM_QUALITY_COLORS[q]:GetRGBA())
    btn.text:SetText("")
    btn.iconBorderHL:Hide()
    btn.Cooldown:Hide()
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn.StackIcon = btn:CreateTexture(name..".REStackFrame.BGIcon", "OVERLAY")
    btn.StackIcon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\CAOverhaul\\Tree_AmountOfSpells")
    btn.StackIcon:SetSize(32,32)
    btn.StackIcon:SetPoint("CENTER", 20, -15)

    btn.StackCount = btn:CreateFontString(name..".REStackFrame.Count", "OVERLAY")
    btn.StackCount:SetFontObject(NumberFontNormalYellow)
    btn.StackCount:SetSize(28,28)
    btn.StackCount:ClearAllPoints()
    btn.StackCount:SetPoint("CENTER", btn.StackIcon, 2, 0)
    btn.StackCount:SetText("0")
    btn.StackCount:SetJustifyH("CENTER")
    btn.StackCount:Hide()
    
    btn:HookScript("OnClick", function(self)
        local isOwned = BOON_STORAGE[self.itemID] ~= nil
        local start, duration, enable = GetItemCooldown(self.itemID)
        
        if isOwned and (duration == 0 or (GetTime() - start) < 0.01) then
            local data = BOON_STORAGE[self.itemID]
            if #data == 1 then
                BOON_STORAGE[self.itemID] = nil -- don't wait for bag update
            end

            if duration > 0 then
                for itemID, btn in pairs(BOON_BTNS) do
                    if not btn.Cooldown:IsVisible() and BOON_STORAGE[itemID] then
                        CooldownFrame_SetTimer(btn.Cooldown, start, duration, enable);
                    end
                end
            end
            
            SetButtonVisual(self, BtnVisualStates.CLICKED, "MythicalBoonBtn_OnClick")
        else
            SetButtonVisual(self, BtnVisualStates.FIZZLE, "MythicalBoonBtn_OnClick")
        end
    end)
    

    btn.itemID = nil
    btn.origX = x
    btn.origY = y
    btn:Hide()
    return btn
end

local function CreateBoonButtonCallback(category, index, x, y, orbit, segmentFkt)
    --print("CreateCallback", category, index, x, y)
    
    -- TODO: move this somewhere else?
    -- Get global index from local index for naming
    local curIdx = 0
    for cat, data in pairs(BOON_ITEMS_GROUPED) do
        if cat == category then
            break
        end
        curIdx = curIdx + #data 
    end

    local itemID = BOON_ITEMS_GROUPED[category][index]
    if not itemID then print("Invalid item ID") return end
    local data = BOON_ITEMS[itemID]
    
    local spellID = data[4]
    local spellName,_, spellIcon = GetSpellInfo(spellID)
    --print(category, index, curIdx, curIdx + index)
    local btn = BOON_BTNS[itemID] and BOON_BTNS[itemID] or InitBoonButton("MythicalBoonBtn"..(curIdx + index), category + 2)
    
    btn.itemID = itemID
    btn:Hide()
    btn.origX = x
    btn.origY = y
    
    btn.text:SetText(spellName:gsub("[%S ]+:.", ""))
    SetPortraitToTexture(btn.icon, spellIcon)
    -- Text and icon scaling (corners)
    if segmentFkt < 0.5 then
        btn.text:SetFontObject(GameFontNormal)
    elseif segmentFkt < 0.7 then
        btn:SetScale(segmentFkt*(5/7) + 0.5)
        btn.text:SetPoint("CENTER", 0, 0)
    elseif segmentFkt < 0.9 then
        btn.text:SetFontObject(GameFontNormalLarge)
        btn.text:SetPoint("CENTER", 0, -15)
    else
        btn.text:SetFontObject(GameFontNormalLarge)
        btn.text:SetPoint("CENTER", 0, -40)
        btn:SetScale(1)
    end

    btn.animIn:SetInitialOffset(-x, -y)
    --btn.AnimGroup.Trans0:SetOrder(math.min(5, index))
    --btn.AnimGroup.Alpha0:SetStartDelay(index * 0.1)
    btn.animIn.alpha:SetStartDelay(index * 0.05)
    btn.animIn.trans:SetStartDelay(index * 0.05)
    btn.animIn.trans:SetOffset(x, y)

    
    btn.animHide.trans:SetOffset(-x, -y)
    --btn.SetAlpha(0)
    btn:SetPoint("CENTER", x , y)
    BOON_BTNS[itemID] = btn

end

local MAX_COORDS = {0, 0, 0, 0}

local function UpdateButtons(dontShow)
    --print("UpdateButtons")
    
    if next(BOON_STORAGE) ~= nil and MythicalBoonUI.inCombat then
        MythicalBoonUI.MainBtn.iconBorder:Hide()
        MythicalBoonUI.MainBtn.iconBorderHL:Show()
        MythicalBoonUI.MainBtn.iconBorderHL.animActive:Play()
    else
        MythicalBoonUI.MainBtn.iconBorderHL.animActive:Stop()
        MythicalBoonUI.MainBtn.iconBorderHL:Hide()
        MythicalBoonUI.MainBtn.iconBorder:Show()
    end

    local rmConfig = {}
    rmConfig.btnPerCategory = {} -- Number of buttons for each category
    rmConfig.radii = {100, 100} -- first row radius, other row radii
    rmConfig.safeZone = 120 -- Safe zone around buttons
    rmConfig.startAngle = 90 -- Angle of the first category
    rmConfig.catSafeZone = rmConfig.safeZone
    rmConfig.angleLimit = 360
    rmConfig.startAngle = 90

    for idx, data in pairs(BOON_ITEMS_GROUPED) do
        rmConfig.btnPerCategory[idx] = #data
    end
    local buttons, maxcoords = MythicalBoonUI.RM:Create(MythicalBoonUI, rmConfig, CreateBoonButtonCallback)
    local shadowsize = math.max(math.abs(maxcoords[1] - maxcoords[2]), math.abs(maxcoords[3] - maxcoords[4])) * 1.5

    MythicalBoonUI.Shadow:SetSize(shadowsize, shadowsize)
    
    --local inCombat = InCombatLockdown()
    for itemID, btn in pairs(BOON_BTNS) do
        SetButtonVisual(btn, BtnVisualStates.ENABLED)
        
        --print(btn:GetName())
        if not dontShow and MythicalBoonUI.menuActive then
            btn:Show()
        end
        --[[
        local inactive = not BOON_STORAGE[itemID] and inCombat
        btn.icon:SetDesaturated(inactive)
        btn.iconBorder:SetDesaturated(inactive)
        btn:EnableMouse(not inactive)
        if not dontShow and menuActive then
            btn:Show()
        end]]
    end
    
    MAX_COORDS= maxcoords
    return buttons, maxcoords
    --print("UpdateBtnState")
end
--- *** BOON BUTTON END ***

--- *** FRAMES ***
-- Event handlers
local function MythicalBoonUI_ItemAddedRemoved(data)
    if not issecure() then
        --print("Insecure add")
        --securecall(print, "insecure add / removal")
        securecall(InitOwnedBoons)
        securecall(UpdateButtons)
        return
    end

  for _, event in ipairs(data) do
    local bag, slot, id, count = unpack(event)
    if BOON_ITEMS[id] ~= nil then
        InitOwnedBoons()
        UpdateButtons()
        --print("ADDED/REMOVED secure", issecure())
        break
    end
  end
end

local function SetMenuState(active)
    if active == MythicalBoonUI.menuActive then
        --print("same state")
        return
    end

    MythicalBoonUI.menuActive = active
    MythicalBoonUI:EnableMouse(active)

    if active then
        MythicalBoonUI.Shadow:Show()
        MythicalBoonUI.Shadow.animHide:Stop()
        MythicalBoonUI.Shadow.animIn:Play()
        MythicalBoonUI.MainBtn.text:Hide()
        InitOwnedBoons()
        UpdateButtons()
        -- TODO: implement this in UpdateButtons
        for itemID, btn in pairs(BOON_BTNS) do
            btn:Show()
            if BOON_STORAGE[itemID] ~= nil then
                --SetButtonState(btn, ButtonStates.ACTIVE)
            else
                --SetButtonState(btn, ButtonStates.INACTIVE)
            end
            
            --SetButtonVisual(btn, BtnVisualStates.ENABLED)

            if btn.animIn then
                btn.animIn:Play()
            else
                --print("No anim group :X")
            end
        end
    else
        for itemID, btn in pairs(BOON_BTNS) do
            --btn:Hide()
            btn.animIn:Stop()
            btn.animHide:Play()
        end
        
        MythicalBoonUI.Shadow.animIn:Stop()
        MythicalBoonUI.Shadow.animHide:Play()
        MythicalBoonUI.MainBtn.text:Show()
    end
end

function MythicalBoonMainBtn_OnEnter(self)
    --SetButtonHighlight(MythicalBoonMainBtn, true)
    SetMenuState(true)
end

function MythicalBoonUI_EnterCombat(unit)
    MythicalBoonUI.inCombat = true
    UpdateButtons()
end

function MythicalBoonUI_LeaveCombat(unit)
    MythicalBoonUI.inCombat = false
    UpdateButtons()
end

local updateSkip = 1
function MythicalBoonUI_OnUpdate(self)
    if self.menuActive == true then
        
        if not issecure() then
            --print("Insecure add")
            --securecall(print, "insecure update")
        end
        for itemID, btn in pairs(BOON_BTNS) do
            local start, duration, enable = GetItemCooldown(itemID)
            if duration > 0 and not btn.Cooldown:IsVisible() and BOON_STORAGE[itemID] then
                CooldownFrame_SetTimer(btn.Cooldown, start, duration, enable);
            elseif duration == 0 then
                if btn.Cooldown:IsVisible() then
                    btn.Cooldown:Hide()
                end
            end
        end

        if self.MainBtn:IsMouseOver(unpack(MAX_COORDS)) then
        else
            SetMenuState(false)
        end

        if updateSkip and updateSkip > 1 then
            if MythicalBoonUI.Dragged then
                UpdateButtons()
            end
            updateSkip = 1
            
        elseif updateSkip then
            updateSkip = updateSkip + 1
        end
    end
end

local function SetMythicalBoonUIState(enabled)
    if enabled and C_Realm.IsDevelopment() then
        MythicalBoonUI:Show()
    else
        MythicalBoonUI:Hide()
    end
end

function MythicalBoonUI_CvarUpdate(event)
    if event == "" then
        --SetMythicalBoonUIState(C_CVar:GetBool(""))
    end
end

function MythicalBoonUI_VariablesLoaded()
    --SetMythicalBoonUIState(C_CVar:GetBool(""))
end

function MythicalBoonUI_EnterWorld(self, event, isLogin, isReload)
    local instance, type = IsInInstance()
    local diff = GetDungeonDifficulty()
    if (instance == 1 and type == "party" and diff == 3) then
        securecall(MythicalBoonUI_VariablesLoaded)
    else
        MythicalBoonUI:Hide()
    end
end

local function InitMythicalBoons()
    ParseBoonDescriptions()

    C_Hook:Register(MythicalBoonUI, "CVAR_UPDATE", MythicalBoonUI_CvarUpdate)

    -- Generate grouped data
    for itemId, data in pairs(BOON_ITEMS) do
        local idx = data[2]
        if not BOON_ITEMS_GROUPED[idx] then
            BOON_ITEMS_GROUPED[idx] = {}
        end

        table.insert(BOON_ITEMS_GROUPED[idx], itemId)
    end

    MythicalBoonUI:SetScript("OnUpdate", MythicalBoonUI_OnUpdate)
    
    MythicalBoonUI:SetScript("OnShow", function(self)
        InitOwnedBoons()
        C_Hook:RegisterBucket(MythicalBoonUI, "NEW_BAG_ITEM_ADDED, BAG_ITEM_REMOVED", 0.1, MythicalBoonUI_ItemAddedRemoved)
        C_Hook:Register(MythicalBoonUI, "PLAYER_REGEN_DISABLED", MythicalBoonUI_EnterCombat)
        C_Hook:Register(MythicalBoonUI, "PLAYER_REGEN_ENABLED", MythicalBoonUI_LeaveCombat)
        C_Hook:Register(MythicalBoonUI, "PLAYER_ENTERING_WORLD", MythicalBoonUI_EnterWorld)
    end)
    
    MythicalBoonUI:SetScript("OnHide", function(self)
        C_Hook:Unregister("BAG_ITEM_REMOVED")
        C_Hook:Unregister("NEW_BAG_ITEM_ADDED")
        C_Hook:Unregister("PLAYER_REGEN_DISABLED")
        C_Hook:Unregister("PLAYER_REGEN_ENABLED")
    end)

    MythicalBoonUI.Shadow:Hide()
    
    MythicalBoonUI.MainBtn:RegisterForDrag("LeftButton")
    MythicalBoonUI.MainBtn:SetClampedToScreen(true)
    SetPortraitToTexture(MythicalBoonUI.MainBtn.icon, "Interface\\Icons\\spell_mage_focusingcrystal")
    MythicalBoonUI.MainBtn:SetScript("OnClick", function(self)
        --SetUpAnimation(self, MythicalBoonPressedAnimTable2, function() end, false)
        SetUpAnimation(self, MythicalAnims.BTN_PRESSED, nil, false)
    end)    
    
    InitOwnedBoons()
    local buttons, maxcoords = UpdateButtons(true)
    local sizeY = maxcoords[1] - maxcoords[2]
    local sizeX = maxcoords[4] - maxcoords[3]
    MythicalBoonUI:SetSize(sizeX, sizeY)
    MythicalBoonUI.Shadow:SetSize(sizeX, sizeY)
    
end
-- *** FRAMES END ***
function MythicalBoonUI_OnLoad(self)
    --print("MythicalBoonUI_OnLoad", self:GetName())
    self.inCombat = false
    self.menuActive = false
    self.RM = CreateFromMixinsAndLoad(DynamicRadialMenu)
    InitMythicalBoons()
end
--InitMythicalBoons()
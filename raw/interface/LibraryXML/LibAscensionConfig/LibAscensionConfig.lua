--
-- Ace Config Helper for Ascension.gg
--
local LibStub = _G.LibStub
local MAJOR = 'LibAscensionConfig'
local LAC = LibStub:NewAscensionLibrary(MAJOR)

if not LAC then
    return
end

function LAC:BuildDefaultsTable(scope, args)
    local defaults = {}
    local parent = defaults
    if args then
        defaults[scope] = {}
        parent = defaults[scope]
    else
        args = scope
    end

    for k, v in pairs(args) do
        if type(v) == "table" then
            if v.args then
                parent[k] = self:BuildDefaultsTable(v.args)
            elseif v.default ~= nil then
                parent[k] = v.default
                v.default = nil
            end
        end
    end

    return defaults
end

function LAC:PrepareForOptionTable(group)
    if group.args then
        for k, v in pairs(group.args) do
            group.nextOrder = nil
            if v.args then
                self:PrepareForOptionTable(v)
            end
        end
    end
end

function LAC:DefaultGetOptionFunction(db)
    return function(info, ...)
        local parent = db
        for i = 1, #info - 1 do
            parent = parent[info[i]]
        end
        
        local value = parent[info[#info]]
        if type(value) == "table" then
            return unpack(value)
        end
        return value
    end
end

function LAC:DefaultSetOptionFunction(db)
    return function(info, ...)
        local parent = db
        for i = 1, #info - 1 do
            parent = parent[info[i]]
        end
        if select("#", ...) > 1 then
            parent[info[#info]] = { ... }
        else
            parent[info[#info]] = ...
        end
    end
end

do -- group object
    local GroupMetaTable = {}
    
    function GroupMetaTable:AddChild(key, obj)
        if not obj.order then
            obj.order = self.nextOrder()
        end
        self.args[key] = obj
    end
    
    function GroupMetaTable:SetGetSet(get, set)
        self.get = get
        self.set = set
    end
    
    function GroupMetaTable:UseDefaultGetSet(db, setCallback)
        if setCallback then
            local setFunc = LAC:DefaultSetOptionFunction(db)
            self.set = function(...)
                setFunc(...)
                setCallback()
            end
        else
            self.set = LAC:DefaultSetOptionFunction(db)
        end
        self.get = LAC:DefaultGetOptionFunction(db)
    end

    function LAC:CreateGroupObject()
        local group = { type = 'group', args = {} }
        group.nextOrder = CreateCounter()
        setmetatable(group, { __index = GroupMetaTable })
        return group
    end
end

LAC.ChildGroupType = {
    Tab = "tab",
    Inline = "inline",
    Tree = "tree",
}

LAC.Width = {
    Double = "double",
    Half = "half",
    Full = "full",
    Normal = "normal",
}

local function insertWidth(opt, width)
    if type(width) == 'number' and width > 5 then
        opt.customWidth = width
    else
        opt.width = width
    end
end

local function insertConfirm(opt, confirm)
    local confirmType = type(confirm)
    if confirmType == 'boolean' then
        opt.confirm = true
    elseif confirmType == 'string' then
        opt.confirm = true
        opt.confirmText = confirm
    elseif confirmType == 'function' then
        opt.confirm = confirm
    end
end

-- returns a new table so it can be modified
function LAC:GetAnchorValues()
    return {
        TOPLEFT = "Top Left",
        TOP = "Top",
        TOPRIGHT = "Top Right",
        LEFT = "Left",
        CENTER = "Center",
        RIGHT = "Right",
        BOTTOMLEFT = "Bottom Left",
        BOTTOM = "Bottom",
        BOTTOMRIGHT = "Bottom Right",
    }
end

function LAC:Group(name, desc, order, childGroups, disabled, hidden, get, set, func)
    local group = self:CreateGroupObject()
    group.name = name
    group.desc = desc
    group.order = order
    if childGroups == LAC.ChildGroupType.Inline then
        group.inline = true
        group.childGroups = nil
    else
        group.inline = nil
        group.childGroups = childGroups
    end
    group.disabled = disabled
    group.hidden = hidden
    group.get = get
    group.set = set
    group.func = func
    return group
end

function LAC:Header(name, hidden)
    return { type = 'header', name = name or '', hidden = hidden }
end

function LAC:Color(name, desc, hasAlpha, default, width, disabled, hidden)
    local opt = { type = 'color', name = name, desc = desc, hasAlpha = hasAlpha, default = default, disabled = disabled, hidden = hidden }
    if width then insertWidth(opt, width) end
    return opt
end

function LAC:Description(name, fontSize, image, imageCoords, imageWidth, imageHeight, width, hidden)
    local opt = { type = 'description', name = name or '', fontSize = fontSize, image = image, imageCoords = imageCoords, imageWidth = imageWidth, imageHeight = imageHeight, hidden = hidden }
    if width then insertWidth(opt, width) end
    return opt
end

function LAC:Execute(name, desc, func, image, confirm, width, disabled, hidden)
    local opt = { type = 'execute', name = name, desc = desc, func = func, image = image, disabled = disabled, hidden = hidden }
    if width then insertWidth(opt, width) end
    if confirm then insertConfirm(opt, confirm) end
    return opt
end

function LAC:Input(name, desc, default, multiline, width, disabled, hidden, validate)
    local opt = { type = 'input', name = name, desc = desc, default = default, multiline = multiline, disabled = disabled, hidden = hidden, validate = validate }
    if width then insertWidth(opt, width) end
    return opt
end

function LAC:Select(name, desc, default, values, width, confirm, disabled, hidden)
    local opt = { type = 'select', name = name, desc = desc, values = values or {}, default = default, disabled = disabled, hidden = hidden }
    if width then insertWidth(opt, width) end
    if confirm then insertConfirm(opt, confirm) end
    return opt
end

function LAC:MultiSelect(name, desc, values, default, width, confirm, disabled, hidden)
    local opt = { type = 'multiselect', name = name, desc = desc, values = values or {}, default = default, disabled = disabled, hidden = hidden }
    if width then insertWidth(opt, width) end
    if confirm then insertConfirm(opt, confirm) end
    return opt
end

function LAC:Toggle(name, desc, default, tristate, confirm, width, disabled, hidden)
    local opt = { type = 'toggle', name = name, desc = desc, default = default, tristate = tristate, disabled = disabled, hidden = hidden }
    if width then insertWidth(opt, width) end
    if confirm then insertConfirm(opt, confirm) end
    return opt
end

-- Values are the following: key = value
-- min - min value
-- max - max value
-- softMin - 'soft' minimal value, used by the UI for a convenient limit while allowing manual input of values up to min/max
-- softMax - 'soft' maximal value, used by the UI for a convenient limit while allowing manual input of values up to min/max
-- step - step value: 'smaller than this will break the code' (default=no stepping limit)
-- bigStep - a more generally-useful step size. Support in UIs is optional.
-- isPercent (boolean) - represent e.g. 1.0 as 100%, etc. (default=false)

function LAC:Range(name, desc, default, values, width, disabled, hidden)
    local optionTable = { type = 'range', name = name, desc = desc, default = default, disabled = disabled, hidden = hidden }

    if width then insertWidth(optionTable, width) end
    if values and type(values) == 'table' then
        for key, value in pairs(values) do
            optionTable[key] = value
        end
    end

    return optionTable
end

function LAC:Spacer(width, hidden)
    local opt = { type = 'description', name = '', hidden = hidden }
    if width then insertWidth(opt, width) end
    return opt
end

local FontFlagValues = {
    NONE = 'None',
    OUTLINE = 'Outline',
    THICKOUTLINE = 'Thick',
    MONOCHROME = '|cffaaaaaaMono|r',
    MONOCHROMEOUTLINE = '|cffaaaaaaMono|r Outline',
    MONOCHROMETHICKOUTLINE = '|cffaaaaaaMono|r Thick',
}

function LAC:FontFlags(name, desc, default, width, disabled, hidden)
    local opt = { type = 'select', name = name, desc = desc, default = default, disabled = disabled, hidden = hidden, values = FontFlagValues }

    if width then insertWidth(opt, width) end

    return opt
end

function LAC:Divider()
    return self:Spacer('full')
end

local LSM = LibStub('LibSharedMedia-3.0', true)

if LSM and LibStub('AceGUISharedMediaWidgets-1.0', true) then
    local function SharedMediaSelect(controlType, name, desc, default, values, width, disabled, hidden)
        local opt = { type = 'select', dialogControl = controlType, name = name, desc = desc, default = default, values = values, disabled = disabled, hidden = hidden }

        if width then insertWidth(opt, width) end

        return opt
    end

    function LAC:SharedMediaFont(name, desc, default, width, disabled, hidden)
        return SharedMediaSelect('LSM30_Font', name, desc, default, function() return LSM:HashTable('font') end, width, disabled, hidden)
    end

    function LAC:SharedMediaSound(name, desc, default, width, disabled, hidden)
        return SharedMediaSelect('LSM30_Sound', name, desc, default, function() return LSM:HashTable('sound') end, width, disabled, hidden)
    end

    function LAC:SharedMediaStatusbar(name, desc, default, width, disabled, hidden)
        return SharedMediaSelect('LSM30_Statusbar', name, desc, default, function() return LSM:HashTable('statusbar') end, width, disabled, hidden)
    end

    function LAC:SharedMediaBackground(name, desc, default, width, disabled, hidden)
        return SharedMediaSelect('LSM30_Background', name, desc, default, function() return LSM:HashTable('background') end, width, disabled, hidden)
    end

    function LAC:SharedMediaBorder(name, desc, default, width, disabled, hidden)
        return SharedMediaSelect('LSM30_Border', name, desc, default, function() return LSM:HashTable('border') end, width, disabled, hidden)
    end

    function LAC:AddFontControls(group, defaultFont, defaultSize, sizeValues, defaultFlags, disabled, hidden)
        group:AddChild("font", self:SharedMediaFont("Font", nil, defaultFont or LSM.DefaultMedia.font or "Friz Quadrata TT", nil, disabled, hidden))
        sizeValues = sizeValues or { min = 8, max = 18, step = 1 }
        group:AddChild("fontSize", self:Range("Font Size", nil, defaultSize or 8, sizeValues, nil, disabled, hidden))
        group:AddChild("fontFlags", self:FontFlags("Font Flags", nil, defaultFlags or "NONE", nil, disabled, hidden))

        return group
    end
end 
function Mixin(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        for k, v in pairs(mixin) do
            target[k] = v
        end
    end

    return target
end

function MixinSafe(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        for k, v in pairs(mixin) do
            if not target[k] then
                target[k] = v
            end
        end
    end

    return target
end

function MixinAndLoad(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        for k, v in pairs(mixin) do
            target[k] = v
        end

        if mixin.OnLoad then
            mixin.OnLoad(target)
        end
    end

    return target
end

function MixinAndLoadSafe(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        for k, v in pairs(mixin) do
            if not target[k] then
                target[k] = v
            end
        end

        if mixin.OnLoad then
            mixin.OnLoad(target)
        end
    end

    return target
end

function MixinScriptsSafe(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        local hasScript = target.HasScript ~= nil
        for k, v in pairs(mixin) do
            if not target[k] then
                target[k] = v
            end
            if hasScript and target:HasScript(k) and not target:GetScript(k) then
                target:SetScript(k, v)
            end
        end
    end

    return target
end

function MixinScripts(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        local hasScript = target.HasScript ~= nil
        for k, v in pairs(mixin) do
            target[k] = v
            if hasScript and target:HasScript(k) then
                target:SetScript(k, v)
            end
        end
    end

    return target
end

function MixinAndLoadScriptsSafe(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        local hasScript = target.HasScript ~= nil
        for k, v in pairs(mixin) do
            if not target[k] then
                target[k] = v
            end
            if hasScript and target:HasScript(k) and not target:GetScript(k) then
                target:SetScript(k, v)
            end
        end

        if mixin.OnLoad then
            mixin.OnLoad(target)
        end
    end

    return target
end

function MixinAndLoadScripts(target, ...)
    for i = 1, select("#", ...) do
        local mixin = select(i, ...)
        if type(mixin) == "string" then
            mixin = _G[mixin]
        end

        assert(type(mixin) == "table", "Mixins must be a table or a string pointing to a global table. Got Name: "..(tostring(select(i, ...)) or "nil") .. " Type: " .. type(mixin))

        local hasScript = target.HasScript ~= nil
        for k, v in pairs(mixin) do
            target[k] = v
            if hasScript and target:HasScript(k) then
                target:SetScript(k, v)
            end
        end

        if mixin.OnLoad then
            mixin.OnLoad(target)
        end
    end

    return target
end

function CreateFromMixins(...)
    return Mixin({}, ...)
end

function CreateFromMixinsAndLoad(...)
    return MixinAndLoad({}, ...)
end

function CreateAndInitFromMixin(mixin, ...)
    local object = Mixin({}, mixin)
    if object.Init then
        object:Init(...)
    end
    
    return object
end
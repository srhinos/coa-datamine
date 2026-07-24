ErrorHandlerMixin = CreateFromMixins("CallbackRegistryMixin", "TabSystemMixin")
ErrorHandlerMixin.OnEvent = OnEventToMethod

ERRORHANDLER_SAVED = ERRORHANDLER_SAVED or {}
if not InGlue() then
    RegisterForSave("ERRORHANDLER_SAVED")
end

local ReadCustomWTF, WriteCustomWTF = ReadCustomWTF, WriteCustomWTF

ERROR_HANDLER_DATABASE = {
    errors = {
        current = {},
        previous = {},
    },
}


if InGlue() then
    local filename = InGlue() and "GlueErrorHandler" or "ErrorHandler"
    local file = ReadCustomWTF(filename)
    if not string.isNilOrEmpty(file) then
        file = C_Serialize:DeserializeDecompressFromPrint(file)
        if file then
            if file.errors and file.errors.current then
                ERROR_HANDLER_DATABASE = file
            end
        end
    end

    if ERROR_HANDLER_DATABASE.errors.current then
        ERROR_HANDLER_DATABASE.errors.previous = table.Copy(ERROR_HANDLER_DATABASE.errors.current)
        wipe(ERROR_HANDLER_DATABASE.errors.current)
    else
        ERROR_HANDLER_DATABASE.errors.current = {}
    end
else
    RegisterForSave("ERROR_HANDLER_DATABASE")
end


local MAX_UNIQUE_ERRORS = 100
local ERRORS_PER_SECOND = 10

function ErrorHandlerMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    CallbackRegistryMixin.OnLoad(self)
    TabSystemMixin.OnLoad(self)
    self:GenerateCallbackEvents({
        "CaptureStarted",
        "CapturePaused",
        "OnError",
    })
    self.Error.Text:SetFontObject(ConsoleFont)

    if not InGlue() then
        self:RegisterEvent("ADDON_ACTION_BLOCKED")
        self:RegisterEvent("ADDON_ACTION_FORBIDDEN")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_LOGIN")
    end
    _seterrorhandler(GenerateClosure(self.HandleError, self))

    self:SetTabTemplate("TabSystemTabTemplate")
    self:SetTabSelectedSound(SOUNDKIT.CHARACTER_SHEET_TAB)
    self:SetTabPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 2)
    self:RegisterCallback("OnTabSelected", self.OnTabSelected, self)

    self:AddTab(ERROR_HANDLER_CURRENT)
    self:AddTab(ERROR_HANDLER_PREVIOUS)
end

function ErrorHandlerMixin:OnDragStart()
    self:StartMoving()
end

function ErrorHandlerMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function ErrorHandlerMixin:OnShow()
    self:SelectFirstEnabledTab()
end

function ErrorHandlerMixin:CreateMinimapButton()
    local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
    local MinimapButton = ldb:NewDataObject("ErrorHandler", {
        type = "launcher",
        icon = "Interface\\Buttons\\ErrorHandler_NoError",
        minimapPos = 135,
    })
    
    self.MinimapButton = MinimapButton
    
    function MinimapButton.OnClick(minimapButton, button)
        if not button or button == "LeftButton" then
            if IsAltKeyDown() then
                ErrorHandler:ResetDB()
                return
            end
            if IsShiftKeyDown() then
                ReloadUI()
                return
            end
            ErrorHandler:SetShown(not ErrorHandler:IsShown())
        end
    end
    
    function MinimapButton.OnTooltipShow(tooltip)
        self:BuildTooltip(tooltip)
    end

    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end
    icon:Register("ErrorHandler", MinimapButton, ERRORHANDLER_SAVED)
end

function ErrorHandlerMixin:BuildTooltip(tooltip)
    local currentErrors = ERROR_HANDLER_DATABASE.errors.current
    if not currentErrors or #currentErrors == 0 then
        tooltip:AddLine(GREEN_FONT_COLOR:WrapText(ERROR_HANDLER_NO_ERRORS))
    else
        tooltip:AddLine(ERROR_HANDLER)
        local line = "%d. %s (x%d)"
        for index, error in next, currentErrors do
            tooltip:AddLine(line:format(index, self:ColorStack(error.message), error.counter), 0.5, 0.5, 0.5)
        end
        GameTooltip_AddSpacer(tooltip)
        tooltip:AddLine(ERROR_HANDLER_TOOLTIP_HINT, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true)
    end
end

function ErrorHandlerMixin:ShowNewestError()
    self.currentIndex = #ERROR_HANDLER_DATABASE.errors[self.tab]
    self:UpdateShownError()
end

function ErrorHandlerMixin:UpdateShownError()
    local error = ERROR_HANDLER_DATABASE.errors[self.tab][self.currentIndex]

    if not error then
        self.Error.Text:SetText(DISABLED_FONT_COLOR:WrapText(ERROR_HANDLER_NO_ERRORS))
    else
        self.Error.Text:SetText(self:FormatError(error))
    end

    -- this is stupid but i cannot find what keeps moving this back to the bottom. I have tried basically every idea possible.
    -- this should just force it to the top.
    Timer.NewTicker(0, function() self.Error:SetVerticalScroll(0) end, 5)
    self:UpdateButtons()
end

function ErrorHandlerMixin:PreviousError()
    local maxIndex = #ERROR_HANDLER_DATABASE.errors[self.tab]
    self.currentIndex = math.clamp(self.currentIndex - 1, 1, maxIndex)
    if self.currentIndex < maxIndex then
        self.isViewingPrevious = true
    end
    self:UpdateShownError()
end

function ErrorHandlerMixin:NextError()
    local maxIndex = #ERROR_HANDLER_DATABASE.errors[self.tab]
    self.currentIndex = math.clamp(self.currentIndex + 1, 1, maxIndex)
    if self.currentIndex == maxIndex then
        self.isViewingPrevious = false
    end
    self:UpdateShownError()
end

function ErrorHandlerMixin:CopyToClipboard()
    local error = ERROR_HANDLER_DATABASE.errors[self.tab][self.currentIndex]
    if error then
        local toCopy = tostring(error.message)
        if error.stack and not string.isNilOrEmpty(error.stack) then
            toCopy = toCopy .. "\n" .. tostring(error.stack)
        end
        if error.locals and not string.isNilOrEmpty(error.locals) then
            toCopy = toCopy .. "\n\nLocals (No Functions or Userdata):\n" .. error.locals
        end

        if InGlue() then
            toCopy = toCopy .. "\n\nGlue Screen: true"
        else
            toCopy = toCopy .. "\n\nRealm: "..GetRealmName()
            toCopy = toCopy .. "\nLocale: "..GetLocale()
        end
        Internal_CopyToClipboard(toCopy)
    end
end

function ErrorHandlerMixin:OnTabSelected(tabID, tab)
    self.isViewingPrevious = false
    if tabID == 1 then
        self.tab = "current"
    else
        self.tab = "previous"
    end
    self:ShowNewestError()
end

function ErrorHandlerMixin:ColorStack(ret)
    ret = tostring(ret) or "" -- Yes, it gets called with nonstring from somewhere /mikk
    ret = ret:gsub("[%.I]?[%.n]?[%.t]?[%.e]?[%.r]?[%.f]?[%.a][%.c][%.e]\\", "") -- Removes Interface\\ which can appear as "Interface\\" or "...face\\" or "...ce\\". Probably could just be "...\\"
    ret = ret:gsub("%.?%.?%.?\\?AddOns\\", "")
    ret = ret:gsub("|([^chHr])", "||%1"):gsub("|$", "||") -- Pipes
    ret = ret:gsub("<(.-)>", "|cffffcc00<%1|cffffcc00>|r") -- Things wrapped in <>
    ret = ret:gsub("%[(.-)%]", "|cffffcc00[%1|cffffcc00]|r") -- Things wrapped in []
    ret = ret:gsub("([\"])(.-)([\"])", "|cff88ff88%1%2|cff88ff88%3|r") -- Quotes
    ret = ret:gsub("([`'])(.-)([`'])", "|cfff73600%1%2|cfff73600%3|r") -- code block
    ret = ret:gsub(":(%d+)([%S\n])", ":|cfffc8a00%1|r%2") -- Line numbers
    ret = ret:gsub("([^\\]+%.lua)", "|cff88ccff%1|r") -- Lua files
    ret = ret:gsub("([^\\]+%.xml)", "|cff88ccff%1|r") -- xml files
    return ret
end

function ErrorHandlerMixin:ColorLocals(ret)
    ret = tostring(ret) or "" -- Yes, it gets called with nonstring from somewhere /mikk
    ret = ret:gsub("[%.I][%.n][%.t][%.e][%.r]face\\", "")
    ret = ret:gsub("%.?%.?%.?\\?AddOns\\", "")
    ret = ret:gsub("|(%a)", "||%1"):gsub("|$", "||") -- Pipes
    ret = ret:gsub("> %@(.-):(%d+)", "> @|cff88ccff%1|r:|cfffc8a00%2|r") -- Files/Line Numbers of locals
    ret = ret:gsub("(%s-)([%a_%(][%a_%d%*%)]+) = ", "%1|cff88ccff%2|r = ") -- Table keys
    ret = ret:gsub("= (%-?[%d%p]+)\n", "= |cff88ff88%1|r\n") -- locals: number
    ret = ret:gsub("= nil\n", "= |cff808080nil|r\n") -- locals: nil
    ret = ret:gsub("= true\n", "= |cff88ff88true|r\n") -- locals: true
    ret = ret:gsub("= false\n", "= |cff88ff88false|r\n") -- locals: false
    ret = ret:gsub("= <(.-)>", "= |cffff0000<%1|cffff0000>|r") -- Things wrapped in <>
    return ret
end

local errorFormat = "|cffffd100%d|r|cff808080x|r %s"
local errorFormatLocals = "|cffffd100%d|r|cff808080x|r %s\n\nLocals |cff808080(No Functions or Userdata)|r:\n%s"
function ErrorHandlerMixin:FormatError(error)
    if string.isNilOrEmpty(error.locals) then
        local s = self:ColorStack(tostring(error.message) .. (error.stack and "\n"..tostring(error.stack) or ""))
        if InGlue() then
            s = s .. "\n\nGlue Screen: true"
        else
            s = s .. "\n\nRealm: "..GetRealmName()
            s = s .. "\nLocale: "..GetLocale()
        end
        return errorFormat:format(error.counter or -1, s)
    else
        local s = self:ColorStack(tostring(error.message) .. (error.stack and "\n"..tostring(error.stack) or ""))
        local l = self:ColorLocals(tostring(error.locals))
        if InGlue() then
            l = l .. "\n\n|cffffd100Glue Screen|r: true"
        else
            l = l .. "\n\n|cffffd100Realm|r: "..GetRealmName()
            l = l .. "\n|cffffd100Locale|r: "..GetLocale()
        end
        return errorFormatLocals:format(error.counter or -1, s, l)
    end
end

function ErrorHandlerMixin:UpdateButtons()
    local maxErrors = #ERROR_HANDLER_DATABASE.errors[self.tab]
    self.PreviousButton:SetEnabled(self.currentIndex > 1)
    self.NextButton:SetEnabled(self.currentIndex < maxErrors)
    if maxErrors == 0 then
        BasicFrame_SetTitle(self, ERROR_HANDLER)
    else
        BasicFrame_SetTitle(self, format(ERROR_HANDLER .. " |cffffffff%d/%d|r", self.currentIndex, maxErrors))
    end
end

function ErrorHandlerMixin:SaveDB()
    if not InGlue() then
        return
    end
    local file = C_Serialize:SerializeCompressForPrint(ERROR_HANDLER_DATABASE)
    local filename = InGlue() and "GlueErrorHandler", "ErrorHandler"
    WriteCustomWTF(filename, file)
end

function ErrorHandlerMixin:ResetDB()
    wipe(ERROR_HANDLER_DATABASE)
    ERROR_HANDLER_DATABASE.errors = {
        current = {},
        previous = {}
    }
    if self.MinimapButton then
        self.MinimapButton.icon = "Interface\\Buttons\\ErrorHandler_NoError"
    end
    self:UpdateShownError()
    self:SaveDB()
end

function ErrorHandlerMixin:StoreError(errorObject)
    local db = ERROR_HANDLER_DATABASE.errors.current

    if not InGlue() and not self.initialized then
        self.temp = self.temp or {}
        db = self.temp
    end

    if db then
        db[#db + 1] = errorObject
        if #db > MAX_UNIQUE_ERRORS then
            table.remove(db, 1)
        end
    end

    if InGlue() then
        self:SaveDB()
    end

    if not self.isViewingPrevious then
        if self:IsShown() then
            self:ShowNewestError()
        end
    else
        if self:IsShown() then
            self:UpdateButtons()
        end
    end
end

function ErrorHandlerMixin:PLAYER_ENTERING_WORLD()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    if InGlue() or self.initialized then
        return
    end
    self.initialized = true
    if ERROR_HANDLER_DATABASE.errors.current then
        ERROR_HANDLER_DATABASE.errors.previous = table.Copy(ERROR_HANDLER_DATABASE.errors.current)
        wipe(ERROR_HANDLER_DATABASE.errors.current)
    else
        ERROR_HANDLER_DATABASE.errors.current = {}
    end

    if self.temp then
        for i = 1, #self.temp do
            self:StoreError(self.temp[i])
        end
    end
    
    self.temp = nil
end

function ErrorHandlerMixin:PLAYER_LOGIN()
    self:CreateMinimapButton()
end

do
    local badAddons = {}
    function ErrorHandlerMixin:ADDON_ACTION_BLOCKED(addonName, blockedFunction)
        local name = addonName or "<name>"
        if not badAddons[name] then
            badAddons[name] = true
            self:HandleError(ERROR_HANDLER_CALL_BLOCKED:format(name, blockedFunction or "<func>"))
        end
    end
    
    function ErrorHandlerMixin:ADDON_ACTION_FORBIDDEN(addonName, blockedFunction)
        local name = addonName or "<name>"
        if not badAddons[name] then
            badAddons[name] = true
            self:HandleError(ERROR_HANDLER_CALL_PROTECTED:format(name, blockedFunction or "<func>"))
        end
    end
end

--
-- Find Versions
--
do
    local function scanObject(o)
        local version, revision = nil, nil
        for k, v in next, o do
            if type(k) == "string" and (type(v) == "string" or type(v) == "number") then
                local low = k:lower()
                if not version and low:find("version") then
                    version = v
                elseif not revision and low:find("revision") then
                    revision = v
                end
            end
            if version and revision then break end
        end
        return version, revision
    end

    local matchCache = setmetatable({}, { __index = function(self, object)
        if type(object) ~= "string" or #object < 3 then return end
        local found = nil
        if not InGlue() then
            -- First see if it's a library
            if LibStub then
                local _, minor = LibStub(object, true)
                found = minor
            end
            -- Then see if we can get some addon metadata
            if not found and IsAddOnLoaded(object) then
                found = GetAddOnMetadata(object, "Version")
            end
        end
        -- Perhaps it's a global object?
        if not found then
            local o = _G[object] or _G[object:upper()]
            if type(o) == "table" then
                local v, r = scanObject(o)
                if v or r then
                    found = tostring(v) .. "." .. tostring(r)
                end
            elseif o then
                found = o
            end
        end
        if not found then
            found = _G[object:upper() .. "_VERSION"]
        end
        if type(found) == "string" or type(found) == "number" then
            self[object] = found
            return found
        end
    end })

    local tmp = {}
    local function replacer(start, object, tail)
        -- Have we matched this object before on the same line?
        -- (another pattern could re-match a previous match...)
        if tmp[object] then return end
        local found = matchCache[object]
        if found then
            tmp[object] = true
            return (type(start) == "string" and start or "") .. object .. "-" .. found .. (type(tail) == "string" and tail or "")
        end
    end

    local matchers = {
        "(\\)([^\\]+)(%.lua)",       -- \Anything-except-backslashes.lua
        "^()([^\\]+)(\\)",           -- Start-of-the-line-until-first-backslash\
        "()(%a+%-%d%.?%d?)()",       -- Anything-#.#, where .# is optional
        "()(Lib%u%a+%-?%d?%.?%d?)()" -- LibXanything-#.#, where X is any capital letter and -#.# is optional
    }
    function ErrorHandlerMixin:FindVersions(line)
        if not line or line:find("FrameXML\\") or line:find("GlueXML\\") or line:find("SharedXML\\") then return line end
        for i = 1, 4 do
            line = line:gsub(matchers[i], replacer)
        end
        wipe(tmp)
        return line
    end
end

function ErrorHandlerMixin:FetchFromDatabase(target)
    local db = ERROR_HANDLER_DATABASE.errors.current

    for i, err in next, db do
        if err.message == target then
            -- This error already exists
            err.counter = err.counter + 1
            err.session = sessionID

            return table.remove(db, i)
        end
    end
end

function ErrorHandlerMixin:FormatLocals(locals)
    return UIDevUtil.FormatLocals(locals)
end

do
    local tmp = {}
    local msgsAllowed = ERRORS_PER_SECOND
    local msgsAllowedLastTime = GetTime()
    local lastWarningTime = 0

    function ErrorHandlerMixin:HandleError(message, simple)
        if DevConsole then
            DevConsole:ErrorHandler(message)
        end
        -- Flood protection --
        msgsAllowed = msgsAllowed + (GetTime() - msgsAllowedLastTime) * ERRORS_PER_SECOND
        msgsAllowedLastTime = GetTime()
        if msgsAllowed < 1 then
            if not self.paused then
                if GetTime() > lastWarningTime + 10 then
                    SendSystemMessage(ERROR_HANDLER_STOPPED)
                    lastWarningTime = GetTime()
                end
                self.paused = true
                self:TriggerEvent("CapturePaused")
            end
            return
        end
        self.paused = false
        if msgsAllowed > ERRORS_PER_SECOND then
            msgsAllowed = ERRORS_PER_SECOND
        end
        msgsAllowed = msgsAllowed - 1

        -- Grab it --
        message = tostring(message)

        local looping = message:find("ErrorHandler") and true or nil
        if looping then
            print(message)
            return
        end

        local sanitizedMessage = self:FindVersions(message)

        -- Insert the error into the correct database if it's not there
        -- already. If it is, just increment the counter.
        local found = self:FetchFromDatabase(sanitizedMessage)
        -- XXX Note that fetchFromDatabase will set the error objects
        -- XXX session ID to the current one, if found - and it will also
        -- XXX increment the counter on it. This is probably wrong, it should
        -- XXX be done here instead, as "fetchFromDatabase" implies a simple
        -- XXX :Get procedure.

        local errorObject = found

        if not errorObject then
            -- Store the error
            if simple then
                errorObject = {
                    message = sanitizedMessage,
                    time = date("%Y/%m/%d %H:%M:%S"),
                    counter = 1,
                }
            else
                local currentStackHeight = GetCallstackHeight()
                local errorCallStackHeight = GetErrorCallstackHeight()
                local errorStackOffset = errorCallStackHeight and (errorCallStackHeight - 1)
                local debugStackLevel = currentStackHeight - (errorStackOffset or 0)
                local stack = debugstack(debugStackLevel)
                local locals = debuglocals(debugStackLevel)

                -- Scan for version numbers in the stack
                for line in stack:gmatch("(.-)\n") do
                    tmp[#tmp+1] = self:FindVersions(line)
                end
                
                errorObject = {
                    message = sanitizedMessage,
                    stack = table.concat(tmp, "\n"),
                    locals = locals and self:FormatLocals(locals),
                    time = date("%Y/%m/%d %H:%M:%S"),
                    counter = 1,
                }

                wipe(tmp)
            end
        end
        
        self:StoreError(errorObject)
        self:TriggerEvent("OnError", errorObject)
        if self.MinimapButton then
            self.MinimapButton.icon = "Interface\\Buttons\\ErrorHandler_Error"
        end

        if C_Realm.IsDevelopment() then
            UIErrorNotification:Show()
        elseif DevConsole then
            UIErrorNotification:Show()
        end
        
        if not InGlue() then
            if  C_CVar.GetBool("popupScriptErrors") then
                self:Show()
            end

            if not self.TimeSinceMessage then
                self.TimeSinceMessage = TimeSince:Create(-100)
            end

            if self.TimeSinceMessage:GreaterThan(30) then
                self.TimeSinceMessage:ResetToNow()
                SendSystemMessage(ERROR_HANDLER_NEW_ERROR)
            end
        end
    end
end

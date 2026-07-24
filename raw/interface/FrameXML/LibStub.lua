-- $Id: LibStub.lua 103 2014-10-16 03:02:50Z mikk $
-- LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/addons/libstub/ for more info
-- LibStub is hereby placed in the Public Domain
-- Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 3  -- Version 3 = Ascension Exclusive
local LibStub = _G[LIBSTUB_MAJOR]

local ascensionLibraries = {}

-- Check to see is this version of the stub is obsolete
if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or {libs = {}, minors = {} }
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR

	-- LibStub:NewLibrary(major, minor)
	-- major (string) - the major version of the library
	-- minor (string or number ) - the minor version of the library
	--
	-- returns nil if a newer or same version of the lib is already present
	-- returns empty library object or old library object if upgrade is needed
	function LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")

		if not IsLibraryLoaded(major) then
			LoadLibrary(major)
		end
		
		if ascensionLibraries[major] then
			return nil
		end

		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end
	
	function LibStub:NewAscensionLibrary(major)
		--dprint("NewAscensionLibrary", major, issecure())
		--if not issecure() then return end
		if ascensionLibraries[major] then
			return nil
		end
		ascensionLibraries[major] = true
		self.minors[major] = math.huge
		self.libs[major] = self.libs[major] or {}
		return self.libs[major]
	end

	-- LibStub:GetLibrary(major, [silent])
	-- major (string) - the major version of the library
	-- silent (boolean) - if true, library is optional, silently return nil if its not found
	--
	-- throws an error if the library can not be found (except silent is set)
	-- returns the library object if found
	function LibStub:GetLibrary(major, silent)
		if not IsLibraryLoaded(major) then
			LoadLibrary(major)
		end

		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end

	-- LibStub:IterateLibraries()
	--
	-- Returns an iterator for the currently registered libraries
	function LibStub:IterateLibraries()
		return pairs(self.libs)
	end

	setmetatable(LibStub, { __call = LibStub.GetLibrary })
end


-- donglestub slop 
-- astrolabe dependency 

--[[-------------------------------------------------------------------------
  James Whitehead II grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local major = "DongleStub"
local minor = math.huge

local g = getfenv(0)

if not g.DongleStub or g.DongleStub:IsNewerVersion(major, minor) then
    local lib = setmetatable({}, {
        __call = function(t,k)
            if not IsLibraryLoaded(k) then
                LoadLibrary(k)
            end
            if type(t.versions) == "table" and t.versions[k] then
                return t.versions[k].instance
            else
                error("Cannot find a library with name '"..tostring(k).."'", 2)
            end
        end
    })

    function lib:IsNewerVersion(major, minor)
        local versionData = self.versions and self.versions[major]

        -- If DongleStub versions have differing major version names
        -- such as DongleStub-Beta0 and DongleStub-1.0-RC2 then a second
        -- instance will be loaded, with older logic.  This code attempts
        -- to compensate for that by matching the major version against
        -- "^DongleStub", and handling the version check correctly.

        if major:match("^DongleStub") then
            local oldmajor,oldminor = self:GetVersion()
            if self.versions and self.versions[oldmajor] then
                return minor > oldminor
            else
                return true
            end
        end

        if not versionData then return true end
        local oldmajor,oldminor = versionData.instance:GetVersion()
        return minor > oldminor
    end

    local function NilCopyTable(src, dest)
        for k,v in pairs(dest) do dest[k] = nil end
        for k,v in pairs(src) do dest[k] = v end
    end

    function lib:RegisterAscension(newInstance, activate, deactivate)
        assert(type(newInstance.GetVersion) == "function",
                "Attempt to register a library with DongleStub that does not have a 'GetVersion' method.")
        local major, minor = newInstance:GetVersion()
        local oldNewVer = newInstance.GetVersion
        function newInstance:GetVersion()
            local major = oldNewVer()
            return major, math.huge
        end
        LibStub:NewAscensionLibrary(major)
        if not self.versions then self.versions = {} end

        -- New major version
        local versionData = {
            ["instance"] = newInstance,
            ["deactivate"] = deactivate,
        }

        self.versions[major] = versionData
        if type(activate) == "function" then
            table.insert(self.log, string.format("Activate: %s, %s", major, math.huge))
            activate(newInstance)
        end
        return newInstance
    end

    function lib:Register(newInstance, activate, deactivate)
        assert(type(newInstance.GetVersion) == "function",
                "Attempt to register a library with DongleStub that does not have a 'GetVersion' method.")

        local major,minor = newInstance:GetVersion()
        assert(type(major) == "string",
                "Attempt to register a library with DongleStub that does not have a proper major version.")
        assert(type(minor) == "number",
                "Attempt to register a library with DongleStub that does not have a proper minor version.")

        -- Generate a log of all library registrations
        if not self.log then self.log = {} end
        table.insert(self.log, string.format("Register: %s, %s", major, minor))

        if not self:IsNewerVersion(major, minor) then return false end
        if not self.versions then self.versions = {} end

        local versionData = self.versions[major]
        if not versionData then
            -- New major version
            versionData = {
                ["instance"] = newInstance,
                ["deactivate"] = deactivate,
            }

            self.versions[major] = versionData
            if type(activate) == "function" then
                table.insert(self.log, string.format("Activate: %s, %s", major, minor))
                activate(newInstance)
            end
            return newInstance
        end

        local oldDeactivate = versionData.deactivate
        local oldInstance = versionData.instance

        versionData.deactivate = deactivate

        local skipCopy
        if type(activate) == "function" then
            table.insert(self.log, string.format("Activate: %s, %s", major, minor))
            skipCopy = activate(newInstance, oldInstance)
        end

        -- Deactivate the old libary if necessary
        if type(oldDeactivate) == "function" then
            local major, minor = oldInstance:GetVersion()
            table.insert(self.log, string.format("Deactivate: %s, %s", major, minor))
            oldDeactivate(oldInstance, newInstance)
        end

        -- Re-use the old table, and discard the new one
        if not skipCopy then
            NilCopyTable(newInstance, oldInstance)
        end
        return oldInstance
    end

    function lib:GetVersion() return major,minor end

    local function Activate(new, old)
        -- This code ensures that we'll move the versions table even
        -- if the major version names are different, in the case of 
        -- DongleStub
        if not old then old = g.DongleStub end

        if old then
            new.versions = old.versions
            new.log = old.log
        end
        g.DongleStub = new
    end

    -- Actually trigger libary activation here
    local stub = g.DongleStub or lib
    lib = stub:Register(lib, Activate)
end


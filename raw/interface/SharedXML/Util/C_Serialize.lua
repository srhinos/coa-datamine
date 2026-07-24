C_Serialize = {}

-- C_Serialize is LibSerialize renamed to avoid conflicts with addons

--[[
Copyright (c) 2020 Ross Nichols
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
Credits:
The following projects served as inspiration for aspects of this project:
1. LibDeflate, by Haoqian He. https://github.com/SafeteeWoW/LibDeflate
    For the CreateReader/CreateWriter functions.
2. lua-MessagePack, by François Perrad. https://framagit.org/fperrad/lua-MessagePack
    For the mechanism for packing/unpacking floats and ints.
3. LibQuestieSerializer, by aero. https://github.com/AeroScripts/LibQuestieSerializer
    For the basis of the implementation, and initial inspiration.
]]


-- Latest version can be found at https://github.com/rossnichols/LibSerialize.

--[[
# C_Serialize
C_Serialize is a Lua library for efficiently serializing/deserializing arbitrary values.
It supports serializing nils, numbers, booleans, strings, and tables containing these types.
It is best paired with [LibDeflate](https://github.com/safeteeWow/LibDeflate), to compress
the serialized output and optionally encode it for World of Warcraft addon or chat channels.
IMPORTANT: if you decide not to compress the output and plan on transmitting over an addon
channel, it still needs to be encoded, but encoding via `LibDeflate:EncodeForWoWAddonChannel()`
or `LibCompress:GetAddonEncodeTable()` will likely inflate the size of the serialization
by a considerable amount. See the usage below for an alternative.
Note that serialization and compression are sensitive to the specifics of your data set.
You should experiment with the available libraries (C_Serialize, AceSerializer, LibDeflate,
LibCompress, etc.) to determine which combination works best for you.
## Usage:
```lua
-- With compression (recommended):
function MyAddon:Transmit(data)
    local serialized = C_Serialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
end
-- Without compression (custom codec):
MyAddon._codec = LibDeflate:CreateCodec("\000", "\255", "")
function MyAddon:Transmit(data)
    local serialized = C_Serialize:Serialize(data)
    local encoded = self._codec:Encode(serialized)
end
```
## API:
* **`C_Serialize:SerializeEx(opts, ...)`**
    Arguments:
    * `opts`: options (see below)
    * `...`: a variable number of serializable values
    Returns:
    * result: `...` serialized as a string
* **`C_Serialize:Serialize(...)`**
    Arguments:
    * `...`: a variable number of serializable values
    Returns:
    * `result`: `...` serialized as a string
    Calls `SerializeEx(opts, ...)` with the default options (see below)
* **`C_Serialize:Deserialize(input)`**
    Arguments:
    * `input`: a string previously returned from `C_Serialize:Serialize()`
    Returns:
    * `success`: a boolean indicating if deserialization was successful
    * `...`: the deserialized value(s), or a string containing the encountered Lua error
* **`C_Serialize:DeserializeValue(input)`**
    Arguments:
    * `input`: a string previously returned from `C_Serialize:Serialize()`
    Returns:
    * `...`: the deserialized value(s)
* **`C_Serialize:IsSerializableType(...)`**
    Arguments:
    * `...`: a variable number of values
    Returns:
    * `result`: true if all of the values' types are serializable.
    Note that if you pass a table, it will be considered serializable
    even if it contains unserializable keys or values. Only the types
    of the arguments are checked.
`Serialize()` will raise a Lua error if the input cannot be serialized.
This will occur if any of the following exceed 16777215: any string length,
any table key count, number of unique strings, number of unique tables.
It will also occur by default if any unserializable types are encountered,
though that behavior may be disabled (see options).
`Deserialize()` and `DeserializeValue()` are equivalent, except the latter
returns the deserialization result directly and will not catch any Lua
errors that may occur when deserializing invalid input.
Note that none of the serialization/deseriazation methods support reentrancy,
and modifying tables during the serialization process is unspecified and
should be avoided. Table serialization is multi-phased and assumes a consistent
state for the key/value pairs across the phases.
## Options:
The following serialization options are supported:
* `errorOnUnserializableType`: `boolean` (default true)
  * `true`: unserializable types will raise a Lua error
  * `false`: unserializable types will be ignored. If it's a table key or value,
     the key/value pair will be skipped. If it's one of the arguments to the
     call to SerializeEx(), it will be replaced with `nil`.
* `stable`: `boolean` (default false)
  * `true`: the resulting string will be stable, even if the input includes
     maps. This option comes with an extra memory usage and CPU time cost.
  * `false`: the resulting string will be unstable and will potentially differ
     between invocations if the input includes maps
* `filter`: `function(t, k, v) => boolean` (default nil)
  * If specified, the function will be called on every key/value pair in every
    table encountered during serialization. The function must return true for
    the pair to be serialized. It may be called multiple times on a table for
    the same key/value pair. See notes on reeentrancy and table modification.
If an option is unspecified in the table, then its default will be used.
This means that if an option `foo` defaults to true, then:
* `myOpts.foo = false`: option `foo` is false
* `myOpts.foo = nil`: option `foo` is true
## Customizing table serialization:
For any serialized table, C_Serialize will check for the presence of a
metatable key `__LibSerialize`. It will be interpreted as a table with
the following possible keys:
* `filter`: `function(t, k, v) => boolean`
  * If specified, the function will be called on every key/value pair in that
    table. The function must return true for the pair to be serialized. It may
    be called multiple times on a table for the same key/value pair. See notes
    on reeentrancy and table modification. If combined with the `filter` option,
    both functions must return true.
## Examples:
1. `C_Serialize:Serialize()` supports variadic arguments and arbitrary key types,
   maintaining a consistent internal table identity.
    ```lua
    local t = { "test", [false] = {} }
    t[ t[false] ] = "hello"
    local serialized = C_Serialize:Serialize(t, "extra")
    local success, tab, str = C_Serialize:Deserialize(serialized)
    assert(success)
    assert(tab[1] == "test")
    assert(tab[ tab[false] ] == "hello")
    assert(str == "extra")
    ```
2. Normally, unserializable types raise an error when encountered during serialization,
   but that behavior can be disabled in order to silently ignore them instead.
    ```lua
    local serialized = C_Serialize:SerializeEx(
        { errorOnUnserializableType = false },
        print, { a = 1, b = print })
    local success, fn, tab = C_Serialize:Deserialize(serialized)
    assert(success)
    assert(fn == nil)
    assert(tab.a == 1)
    assert(tab.b == nil)
    ```
3. Tables may reference themselves recursively and will still be serialized properly.
    ```lua
    local t = { a = 1 }
    t.t = t
    t[t] = "test"
    local serialized = C_Serialize:Serialize(t)
    local success, tab = C_Serialize:Deserialize(serialized)
    assert(success)
    assert(tab.t.t.t.t.t.t.a == 1)
    assert(tab[tab.t] == "test")
    ```
4. You may specify a global filter that applies to all tables encountered during
   serialization, and to individual tables via their metatable.
    ```lua
    local t = { a = 1, b = print, c = 3 }
    local nested = { a = 1, b = print, c = 3 }
    t.nested = nested
    setmetatable(nested, { __LibSerialize = {
        filter = function(t, k, v) return k ~= "c" end
    }})
    local opts = {
        filter = function(t, k, v) return C_Serialize:IsSerializableType(k, v) end
    }
    local serialized = C_Serialize:SerializeEx(opts, t)
    local success, tab = C_Serialize:Deserialize(serialized)
    assert(success)
    assert(tab.a == 1)
    assert(tab.b == nil)
    assert(tab.c == 3)
    assert(tab.nested.a == 1)
    assert(tab.nested.b == nil)
    assert(tab.nested.c == nil)
    ```
## Encoding format:
Every object is encoded as a type byte followed by type-dependent payload.
For numbers, the payload is the number itself, using a number of bytes
appropriate for the number. Small numbers can be embedded directly into
the type byte, optionally with an additional byte following for more
possible values. Negative numbers are encoded as their absolute value,
with the type byte indicating that it is negative. Floats are decomposed
into their eight bytes, unless serializing as a string is shorter.
For strings and tables, the length/count is also encoded so that the
payload doesn't need a special terminator. Small counts can be embedded
directly into the type byte, whereas larger counts are encoded directly
following the type byte, before the payload.
Strings are stored directly, with no transformations. Tables are stored
in one of three ways, depending on their layout:
* Array-like: all keys are numbers starting from 1 and increasing by 1.
    Only the table's values are encoded.
* Map-like: the table has no array-like keys.
    The table is encoded as key-value pairs.
* Mixed: the table has both map-like and array-like keys.
    The table is encoded first with the values of the array-like keys,
    followed by key-value pairs for the map-like keys. For this version,
    two counts are encoded, one each for the two different portions.
Strings and tables are also tracked as they are encountered, to detect reuse.
If a string or table is reused, it is encoded instead as an index into the
tracking table for that type. Strings must be >2 bytes in length to be tracked.
Tables may reference themselves recursively.
#### Type byte:
The type byte uses the following formats to implement the above:
* `NNNN NNN1`: a 7 bit non-negative int
* `CCCC TT10`: a 2 bit type index and 4 bit count (strlen, #tab, etc.)
    * Followed by the type-dependent payload
* `NNNN S100`: the lower four bits of a 12 bit int and 1 bit for its sign
    * Followed by a byte for the upper bits
* `TTTT T000`: a 5 bit type index
    * Followed by the type-dependent payload, including count(s) if needed
--]]
local SERIALIZATION_VERSION = 1
local DESERIALIZATION_VERSION = 2

local assert = assert
local error = error
local pcall = pcall
local print = print
local setmetatable = setmetatable
local getmetatable = getmetatable
local pairs = pairs
local ipairs = ipairs
local select = select
local unpack = unpack
local type = type
local tostring = tostring
local tonumber = tonumber
local max = math.max
local frexp = math.frexp
local ldexp = math.ldexp
local floor = math.floor
local math_modf = math.modf
local math_huge = math.huge
local strbyte = string.byte
local strchar = string.char
local strsub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local table_sort = table.sort
local gsub = string.gsub
local strfind = string.find
local match = string.match
local format = string.format
local huge = 1/0
local tiny = -1/0

local format = format

local defaultOptions = {
	errorOnUnserializableType = true,
	stable                    = false,
	filter                    = nil,
}

local canSerializeFnOptions = {
	errorOnUnserializableType = false
}


--[[---------------------------------------------------------------------------
    Helper functions.
--]]---------------------------------------------------------------------------

-- Returns the number of bytes required to store the value,
-- up to a maximum of three. Errors if three bytes is insufficient.
local function GetRequiredBytes(value)
	if value < 256 then return 1 end
	if value < 65536 then return 2 end
	if value < 16777216 then return 3 end
	error("Object limit exceeded")
end

-- Returns the number of bytes required to store the value,
-- though always returning seven if four bytes is insufficient.
-- Doubles have room for 53bit numbers, so seven bits max.
local function GetRequiredBytesNumber(value)
	if value < 256 then return 1 end
	if value < 65536 then return 2 end
	if value < 16777216 then return 3 end
	if value < 4294967296 then return 4 end
	return 7
end

-- Returns whether the value (a number) is NaN.
local function IsNaN(value)
	-- With floating point optimizations enabled all comparisons involving
	-- NaNs will return true. Without them, these will both return false.
	return (value < 0) == (value >= 0)
end

-- Returns whether the value (a number) is finite, as opposed to being a
-- NaN or infinity.
local function IsFinite(value)
	return value > -math_huge and value < math_huge and not IsNaN(value)
end

-- Returns whether the value (a number) is fractional,
-- as opposed to a whole number.
local function IsFractional(value)
	local _, fract = math_modf(value)
	return fract ~= 0
end

-- Returns whether the value (a number) needs to be represented as a floating
-- point number due to either being fractional or non-finite.
local function IsFloatingPoint(value)
	return IsFractional(value) or not IsFinite(value)
end

-- Returns true if the given table key is an integer that can reside in the
-- array section of a table (keys 1 through arrayCount).
local function IsArrayKey(k, arrayCount)
	return type(k) == "number" and k >= 1 and k <= arrayCount and not IsFloatingPoint(k)
end

-- Sort compare function which is used to sort table keys to ensure that the
-- serialization of maps is stable. We arbitrarily put strings first, then
-- numbers, and finally booleans.
local function StableKeySort(a, b)
	local aType = type(a)
	local bType = type(b)
	-- Put strings first
	if aType == "string" and bType == "string" then
		return a < b
	elseif aType == "string" then
		return true
	elseif bType == "string" then
		return false
	end
	-- Put numbers next
	if aType == "number" and bType == "number" then
		return a < b
	elseif aType == "number" then
		return true
	elseif bType == "number" then
		return false
	end
	-- Put booleans last
	if aType == "boolean" and bType == "boolean" then
		return (a and 1 or 0) < (b and 1 or 0)
	else
		error(("Unhandled sort type(s): %s, %s"):format(aType, bType))
	end
end

-- Prints args to the chat window. To enable debug statements,
-- do a find/replace in this file with "-- DebugPrint(" for "DebugPrint(",
-- or the reverse to disable them again.
local DebugPrint = function(...)
	print(...)
end


--[[---------------------------------------------------------------------------
    Helpers for reading/writing streams of bytes from/to a string
--]]---------------------------------------------------------------------------

-- Creates a writer to lazily construct a string over multiple writes.
-- Return values:
-- 1. WriteString(str)
-- 2. Flush()
local function CreateWriter()
	local bufferSize = 0
	local buffer = {}

	-- Write the entire string into the writer.
	local function WriteString(str)
		-- DebugPrint("Writing string:", str, #str)
		bufferSize = bufferSize + 1
		buffer[bufferSize] = str
	end

	-- Return a string built from the previous calls to WriteString.
	local function FlushWriter()
		local flushed = table_concat(buffer, "", 1, bufferSize)
		bufferSize = 0
		return flushed
	end

	return WriteString, FlushWriter
end

-- Creates a reader to sequentially read bytes from the input string.
-- Return values:
-- 1. ReadBytes(bytelen)
-- 2. ReaderBytesLeft()
local function CreateReader(input)
	local inputLen = #input
	local nextPos = 1

	-- Read some bytes from the reader.
	-- @param bytelen The number of bytes to be read.
	-- @return the bytes as a string
	local function ReadBytes(bytelen)
		local result = strsub(input, nextPos, nextPos + bytelen - 1)
		nextPos = nextPos + bytelen
		return result
	end

	local function ReaderBytesLeft()
		return inputLen - nextPos + 1
	end

	return ReadBytes, ReaderBytesLeft
end


--[[---------------------------------------------------------------------------
    Helpers for serializing/deserializing numbers (ints and floats)
--]]---------------------------------------------------------------------------

local function FloatToString(n)
	if IsNaN(n) then
		-- nan
		return strchar(0xFF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	end

	local sign = 0
	if n < 0.0 then
		sign = 0x80
		n = -n
	end
	local mant, expo = frexp(n)

	-- If n is infinity, mant will be infinity inside WoW, but NaN elsewhere.
	if (mant == math_huge or IsNaN(mant)) or expo > 0x400 then
		if sign == 0 then
			-- inf
			return strchar(0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
		else
			-- -inf
			return strchar(0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
		end
	elseif (mant == 0.0 and expo == 0) or expo < -0x3FE then
		-- zero
		return strchar(sign, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	else
		expo = expo + 0x3FE
		mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 53))
		return strchar(sign + floor(expo / 0x10),
					   (expo % 0x10) * 0x10 + floor(mant / 281474976710656),
					   floor(mant / 1099511627776) % 256,
					   floor(mant / 4294967296) % 256,
					   floor(mant / 16777216) % 256,
					   floor(mant / 65536) % 256,
					   floor(mant / 256) % 256,
					   mant % 256)
	end
end

local function StringToFloat(str)
	local b1, b2, b3, b4, b5, b6, b7, b8 = strbyte(str, 1, 8)
	local sign = b1 > 0x7F
	local expo = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
	local mant = ((((((b2 % 0x10) * 256 + b3) * 256 + b4) * 256 + b5) * 256 + b6) * 256 + b7) * 256 + b8
	if sign then
		sign = -1
	else
		sign = 1
	end
	local n
	if mant == 0 and expo == 0 then
		n = sign * 0.0
	elseif expo == 0x7FF then
		if mant == 0 then
			n = sign * math_huge
		else
			n = 0.0 / 0.0
		end
	else
		n = sign * ldexp(1.0 + mant / 4503599627370496.0, expo - 0x3FF)
	end
	return n
end

local function IntToString(n, required)
	if required == 1 then
		return strchar(n)
	elseif required == 2 then
		return strchar(floor(n / 256),
					   n % 256)
	elseif required == 3 then
		return strchar(floor(n / 65536),
					   floor(n / 256) % 256,
					   n % 256)
	elseif required == 4 then
		return strchar(floor(n / 16777216),
					   floor(n / 65536) % 256,
					   floor(n / 256) % 256,
					   n % 256)
	elseif required == 7 then
		return strchar(floor(n / 281474976710656) % 256,
					   floor(n / 1099511627776) % 256,
					   floor(n / 4294967296) % 256,
					   floor(n / 16777216) % 256,
					   floor(n / 65536) % 256,
					   floor(n / 256) % 256,
					   n % 256)
	end

	error("Invalid required bytes: " .. required)
end

local function StringToInt(str, required)
	if required == 1 then
		return strbyte(str)
	elseif required == 2 then
		local b1, b2 = strbyte(str, 1, 2)
		return b1 * 256 + b2
	elseif required == 3 then
		local b1, b2, b3 = strbyte(str, 1, 3)
		return (b1 * 256 + b2) * 256 + b3
	elseif required == 4 then
		local b1, b2, b3, b4 = strbyte(str, 1, 4)
		return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
	elseif required == 7 then
		local b1, b2, b3, b4, b5, b6, b7, b8 = 0, strbyte(str, 1, 7)
		return ((((((b1 * 256 + b2) * 256 + b3) * 256 + b4) * 256 + b5) * 256 + b6) * 256 + b7) * 256 + b8
	end

	error("Invalid required bytes: " .. required)
end


--[[---------------------------------------------------------------------------
    Internal functionality:
    The `LibSerializeInt` table contains internal, immutable state (functions, tables)
    that is copied to a new table each time serialization/deserialization is
    invoked, so that each invocation has its own state encapsulated. Copying the
    state is preferred to a metatable, since we don't want to pay the cost of the
    indirection overhead every time we access one of the copied keys.
--]]---------------------------------------------------------------------------

local LibSerializeInt = {}

local function CreateSerializer(opts)
	local state = {}

	-- Copy the state from LibSerializeInt.
	for k, v in pairs(LibSerializeInt) do
		state[k] = v
	end

	-- Initialize string/table reference storage.
	state._stringRefs = {}
	state._tableRefs = {}

	-- Create the writer functions.
	state._writeString, state._flushWriter = CreateWriter()

	-- Create a combined options table, starting with the defaults
	-- and then overwriting any user-supplied keys.
	state._opts = {}
	for k, v in pairs(defaultOptions) do
		state._opts[k] = v
	end
	for k, v in pairs(opts) do
		state._opts[k] = v
	end

	return state
end

local function CreateDeserializer(input)
	local state = {}

	-- Copy the state from LibSerializeInt.
	for k, v in pairs(LibSerializeInt) do
		state[k] = v
	end

	-- Initialize string/table reference storage.
	state._stringRefs = {}
	state._tableRefs = {}

	-- Create the reader functions.
	state._readBytes, state._readerBytesLeft = CreateReader(input)

	return state
end


--[[---------------------------------------------------------------------------
    Object reuse:
    As strings/tables are serialized or deserialized, they are stored in a lookup
    table in case they're encountered again, at which point they can be referenced
    by their index into their table rather than repeating the string contents.
--]]---------------------------------------------------------------------------

function LibSerializeInt:_AddReference(refs, value)
	local ref = #refs + 1
	refs[ref] = value
	refs[value] = ref
end


--[[---------------------------------------------------------------------------
    Read (deserialization) support.
--]]---------------------------------------------------------------------------

function LibSerializeInt:_ReadObject()
	local value = self:_ReadByte()

	if value % 2 == 1 then
		-- Number embedded in the top 7 bits.
		local num = (value - 1) / 2
		-- DebugPrint("Found embedded number (1byte):", value, num)
		return num
	end

	if value % 4 == 2 then
		-- Type with embedded count. Extract both.
		-- The type is in bits 3-4, count in 5-8.
		local typ = (value - 2) / 4
		local count = (typ - typ % 4) / 4
		typ = typ % 4
		-- DebugPrint("Found type with embedded count:", value, typ, count)
		return self._EmbeddedReaderTable[typ](self, count)
	end

	if value % 8 == 4 then
		-- Number embedded in the top 4 bits, plus an additional byte's worth (so 12 bits).
		-- If bit 4 is set, the number is negative.
		local packed = self:_ReadByte() * 256 + value
		local num
		if value % 16 == 12 then
			num = -(packed - 12) / 16
		else
			num = (packed - 4) / 16
		end
		-- DebugPrint("Found embedded number (2bytes):", value, packed, num)
		return num
	end

	-- Otherwise, the type index is embedded in the upper 5 bits.
	local typ = value / 8
	-- DebugPrint("Found type:", value, typ)
	return self._ReaderTable[typ](self)
end

function LibSerializeInt:_ReadTable(entryCount, value)
	-- DebugPrint("Extracting keys/values for table:", entryCount)

	if value == nil then
		value = {}
		self:_AddReference(self._tableRefs, value)
	end

	for _ = 1, entryCount do
		local k, v = self:_ReadPair(self._ReadObject)
		value[k] = v
	end

	return value
end

function LibSerializeInt:_ReadArray(entryCount, value)
	-- DebugPrint("Extracting values for array:", entryCount)

	if value == nil then
		value = {}
		self:_AddReference(self._tableRefs, value)
	end

	for i = 1, entryCount do
		value[i] = self:_ReadObject()
	end

	return value
end

function LibSerializeInt:_ReadMixed(arrayCount, mapCount)
	-- DebugPrint("Extracting values for mixed table:", arrayCount, mapCount)

	local value = {}
	self:_AddReference(self._tableRefs, value)

	self:_ReadArray(arrayCount, value)
	self:_ReadTable(mapCount, value)

	return value
end

function LibSerializeInt:_ReadString(len)
	-- DebugPrint("Reading string,", len)

	local value = self._readBytes(len)
	if len > 2 then
		self:_AddReference(self._stringRefs, value)
	end
	return value
end

function LibSerializeInt:_ReadByte()
	-- DebugPrint("Reading byte")

	return self:_ReadInt(1)
end

function LibSerializeInt:_ReadInt(required)
	-- DebugPrint("Reading int", required)

	return StringToInt(self._readBytes(required), required)
end

function LibSerializeInt:_ReadPair(fn, ...)
	local first = fn(self, ...)
	local second = fn(self, ...)
	return first, second
end

local embeddedIndexShift = 4
local embeddedCountShift = 16
LibSerializeInt._EmbeddedIndex = {
	STRING = 0,
	TABLE  = 1,
	ARRAY  = 2,
	MIXED  = 3,
}
LibSerializeInt._EmbeddedReaderTable = {
	[LibSerializeInt._EmbeddedIndex.STRING] = function(self, c) return self:_ReadString(c) end,
	[LibSerializeInt._EmbeddedIndex.TABLE]  = function(self, c) return self:_ReadTable(c) end,
	[LibSerializeInt._EmbeddedIndex.ARRAY]  = function(self, c) return self:_ReadArray(c) end,
	-- For MIXED, the 4-bit count contains two 2-bit counts that are one less than the true count.
	[LibSerializeInt._EmbeddedIndex.MIXED]  = function(self, c) return self:_ReadMixed((c % 4) + 1, floor(c / 4) + 1) end,
}

local readerIndexShift = 8
LibSerializeInt._ReaderIndex = {
	NIL              = 0,

	NUM_16_POS       = 1,
	NUM_16_NEG       = 2,
	NUM_24_POS       = 3,
	NUM_24_NEG       = 4,
	NUM_32_POS       = 5,
	NUM_32_NEG       = 6,
	NUM_64_POS       = 7,
	NUM_64_NEG       = 8,
	NUM_FLOAT        = 9,
	NUM_FLOATSTR_POS = 10,
	NUM_FLOATSTR_NEG = 11,

	BOOL_T           = 12,
	BOOL_F           = 13,

	STR_8            = 14,
	STR_16           = 15,
	STR_24           = 16,

	TABLE_8          = 17,
	TABLE_16         = 18,
	TABLE_24         = 19,

	ARRAY_8          = 20,
	ARRAY_16         = 21,
	ARRAY_24         = 22,

	MIXED_8          = 23,
	MIXED_16         = 24,
	MIXED_24         = 25,

	STRINGREF_8      = 26,
	STRINGREF_16     = 27,
	STRINGREF_24     = 28,

	TABLEREF_8       = 29,
	TABLEREF_16      = 30,
	TABLEREF_24      = 31,
}
LibSerializeInt._ReaderTable = {
	-- Nil
	[LibSerializeInt._ReaderIndex.NIL]              = function(self) return nil end,

	-- Numbers (ones requiring <=12 bits are handled separately)
	[LibSerializeInt._ReaderIndex.NUM_16_POS]       = function(self) return self:_ReadInt(2) end,
	[LibSerializeInt._ReaderIndex.NUM_16_NEG]       = function(self) return -self:_ReadInt(2) end,
	[LibSerializeInt._ReaderIndex.NUM_24_POS]       = function(self) return self:_ReadInt(3) end,
	[LibSerializeInt._ReaderIndex.NUM_24_NEG]       = function(self) return -self:_ReadInt(3) end,
	[LibSerializeInt._ReaderIndex.NUM_32_POS]       = function(self) return self:_ReadInt(4) end,
	[LibSerializeInt._ReaderIndex.NUM_32_NEG]       = function(self) return -self:_ReadInt(4) end,
	[LibSerializeInt._ReaderIndex.NUM_64_POS]       = function(self) return self:_ReadInt(7) end,
	[LibSerializeInt._ReaderIndex.NUM_64_NEG]       = function(self) return -self:_ReadInt(7) end,
	[LibSerializeInt._ReaderIndex.NUM_FLOAT]        = function(self) return StringToFloat(self._readBytes(8)) end,
	[LibSerializeInt._ReaderIndex.NUM_FLOATSTR_POS] = function(self) return tonumber(self._readBytes(self:_ReadByte())) end,
	[LibSerializeInt._ReaderIndex.NUM_FLOATSTR_NEG] = function(self) return -tonumber(self._readBytes(self:_ReadByte())) end,

	-- Booleans
	[LibSerializeInt._ReaderIndex.BOOL_T]           = function(self) return true end,
	[LibSerializeInt._ReaderIndex.BOOL_F]           = function(self) return false end,

	-- Strings (encoded as size + buffer)
	[LibSerializeInt._ReaderIndex.STR_8]            = function(self) return self:_ReadString(self:_ReadByte()) end,
	[LibSerializeInt._ReaderIndex.STR_16]           = function(self) return self:_ReadString(self:_ReadInt(2)) end,
	[LibSerializeInt._ReaderIndex.STR_24]           = function(self) return self:_ReadString(self:_ReadInt(3)) end,

	-- Tables (encoded as count + key/value pairs)
	[LibSerializeInt._ReaderIndex.TABLE_8]          = function(self) return self:_ReadTable(self:_ReadByte()) end,
	[LibSerializeInt._ReaderIndex.TABLE_16]         = function(self) return self:_ReadTable(self:_ReadInt(2)) end,
	[LibSerializeInt._ReaderIndex.TABLE_24]         = function(self) return self:_ReadTable(self:_ReadInt(3)) end,

	-- Arrays (encoded as count + values)
	[LibSerializeInt._ReaderIndex.ARRAY_8]          = function(self) return self:_ReadArray(self:_ReadByte()) end,
	[LibSerializeInt._ReaderIndex.ARRAY_16]         = function(self) return self:_ReadArray(self:_ReadInt(2)) end,
	[LibSerializeInt._ReaderIndex.ARRAY_24]         = function(self) return self:_ReadArray(self:_ReadInt(3)) end,

	-- Mixed arrays/maps (encoded as arrayCount + mapCount + arrayValues + key/value pairs)
	[LibSerializeInt._ReaderIndex.MIXED_8]          = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadByte)) end,
	[LibSerializeInt._ReaderIndex.MIXED_16]         = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadInt, 2)) end,
	[LibSerializeInt._ReaderIndex.MIXED_24]         = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadInt, 3)) end,

	-- Previously referenced strings
	[LibSerializeInt._ReaderIndex.STRINGREF_8]      = function(self) return self._stringRefs[self:_ReadByte()] end,
	[LibSerializeInt._ReaderIndex.STRINGREF_16]     = function(self) return self._stringRefs[self:_ReadInt(2)] end,
	[LibSerializeInt._ReaderIndex.STRINGREF_24]     = function(self) return self._stringRefs[self:_ReadInt(3)] end,

	-- Previously referenced tables
	[LibSerializeInt._ReaderIndex.TABLEREF_8]       = function(self) return self._tableRefs[self:_ReadByte()] end,
	[LibSerializeInt._ReaderIndex.TABLEREF_16]      = function(self) return self._tableRefs[self:_ReadInt(2)] end,
	[LibSerializeInt._ReaderIndex.TABLEREF_24]      = function(self) return self._tableRefs[self:_ReadInt(3)] end,
}


--[[---------------------------------------------------------------------------
    Write (serialization) support.
--]]---------------------------------------------------------------------------

-- Returns the appropriate function from the writer table for the object's type.
-- If the object's type isn't supported and opts.errorOnUnserializableType is true,
-- then an error will be raised.
function LibSerializeInt:_GetWriteFn(obj)
	local typ = type(obj)
	local writeFn = self._WriterTable[typ]
	if not writeFn and self._opts.errorOnUnserializableType then
		error(("Unhandled type: %s"):format(typ))
	end

	return writeFn
end

-- Returns true if all of the variadic arguments are serializable.
-- Note that _GetWriteFn will raise a Lua error if it finds an
-- unserializable type, unless this behavior is suppressed via options.
function LibSerializeInt:_CanSerialize(...)
	for i = 1, select("#", ...) do
		local obj = select(i, ...)
		local writeFn = self:_GetWriteFn(obj)
		if not writeFn then
			return false
		end
	end

	return true
end

-- Returns true if the table's key/value pair should be serialized.
-- Both filter functions (if present) must return true, and the
-- key/value types must be serializable. Note that _CanSerialize
-- will raise a Lua error if it finds an unserializable type, unless
-- this behavior is suppressed via options.
function LibSerializeInt:_ShouldSerialize(t, k, v, filterFn)
	return (not self._opts.filter or self._opts.filter(t, k, v)) and
			(not filterFn or filterFn(t, k, v)) and
			self:_CanSerialize(k, v)
end

-- Note that _GetWriteFn will raise a Lua error if it finds an
-- unserializable type, unless this behavior is suppressed via options.
function LibSerializeInt:_WriteObject(obj)
	local writeFn = self:_GetWriteFn(obj)
	if not writeFn then
		return false
	end

	writeFn(self, obj)
	return true
end

function LibSerializeInt:_WriteByte(value)
	self:_WriteInt(value, 1)
end

function LibSerializeInt:_WriteInt(n, threshold)
	self._writeString(IntToString(n, threshold))
end

-- Lookup tables to map the number of required bytes to the
-- appropriate reader table index.
local numberIndices = {
	[2] = LibSerializeInt._ReaderIndex.NUM_16_POS,
	[3] = LibSerializeInt._ReaderIndex.NUM_24_POS,
	[4] = LibSerializeInt._ReaderIndex.NUM_32_POS,
	[7] = LibSerializeInt._ReaderIndex.NUM_64_POS,
}
local stringIndices = {
	[1] = LibSerializeInt._ReaderIndex.STR_8,
	[2] = LibSerializeInt._ReaderIndex.STR_16,
	[3] = LibSerializeInt._ReaderIndex.STR_24,
}
local tableIndices = {
	[1] = LibSerializeInt._ReaderIndex.TABLE_8,
	[2] = LibSerializeInt._ReaderIndex.TABLE_16,
	[3] = LibSerializeInt._ReaderIndex.TABLE_24,
}
local arrayIndices = {
	[1] = LibSerializeInt._ReaderIndex.ARRAY_8,
	[2] = LibSerializeInt._ReaderIndex.ARRAY_16,
	[3] = LibSerializeInt._ReaderIndex.ARRAY_24,
}
local mixedIndices = {
	[1] = LibSerializeInt._ReaderIndex.MIXED_8,
	[2] = LibSerializeInt._ReaderIndex.MIXED_16,
	[3] = LibSerializeInt._ReaderIndex.MIXED_24,
}
local stringRefIndices = {
	[1] = LibSerializeInt._ReaderIndex.STRINGREF_8,
	[2] = LibSerializeInt._ReaderIndex.STRINGREF_16,
	[3] = LibSerializeInt._ReaderIndex.STRINGREF_24,
}
local tableRefIndices = {
	[1] = LibSerializeInt._ReaderIndex.TABLEREF_8,
	[2] = LibSerializeInt._ReaderIndex.TABLEREF_16,
	[3] = LibSerializeInt._ReaderIndex.TABLEREF_24,
}

LibSerializeInt._WriterTable = {
	["nil"]     = function(self)
		-- DebugPrint("Serializing nil")
		self:_WriteByte(readerIndexShift * self._ReaderIndex.NIL)
	end,
	["number"]  = function(self, num)
		if IsFloatingPoint(num) then
			-- DebugPrint("Serializing float:", num)
			-- Normally a float takes 8 bytes. See if it's cheaper to encode as a string.
			-- If we encode as a string, though, we'll need a byte for its length.
			--
			-- Note that we only string encode finite values due to potential differences
			-- in encode/decode behaviour with such representations in some
			-- environments.
			local sign = 0
			local numAbs = num
			if num < 0 then
				sign = readerIndexShift
				numAbs = -num
			end
			local asString = tostring(numAbs)
			if #asString < 7 and tonumber(asString) == numAbs and IsFinite(numAbs) then
				self:_WriteByte(sign + readerIndexShift * self._ReaderIndex.NUM_FLOATSTR_POS)
				self:_WriteByte(#asString, 1)
				self._writeString(asString)
			else
				self:_WriteByte(readerIndexShift * self._ReaderIndex.NUM_FLOAT)
				self._writeString(FloatToString(num))
			end
		elseif num > -4096 and num < 4096 then
			-- The type byte supports two modes by which a number can be embedded:
			-- A 1-byte mode for 7-bit numbers, and a 2-byte mode for 12-bit numbers.
			if num >= 0 and num < 128 then
				-- DebugPrint("Serializing embedded number (1byte):", num)
				self:_WriteByte(num * 2 + 1)
			else
				-- DebugPrint("Serializing embedded number (2bytes):", num)
				local sign = 0
				if num < 0 then
					sign = 8
					num = -num
				end
				num = num * 16 + sign + 4
				local upper, lower = floor(num / 256), num % 256
				self:_WriteByte(lower)
				self:_WriteByte(upper)
			end
		else
			-- DebugPrint("Serializing number:", num)
			local sign = 0
			if num < 0 then
				num = -num
				sign = readerIndexShift
			end
			local required = GetRequiredBytesNumber(num)
			self:_WriteByte(sign + readerIndexShift * numberIndices[required])
			self:_WriteInt(num, required)
		end
	end,
	["boolean"] = function(self, bool)
		-- DebugPrint("Serializing bool:", bool)
		self:_WriteByte(readerIndexShift * (bool and self._ReaderIndex.BOOL_T or self._ReaderIndex.BOOL_F))
	end,
	["string"]  = function(self, str)
		local ref = self._stringRefs[str]
		if ref then
			-- DebugPrint("Serializing string ref:", str)
			local required = GetRequiredBytes(ref)
			self:_WriteByte(readerIndexShift * stringRefIndices[required])
			self:_WriteInt(self._stringRefs[str], required)
		else
			local len = #str
			if len < 16 then
				-- Short lengths can be embedded directly into the type byte.
				-- DebugPrint("Serializing string, embedded count:", str, len)
				self:_WriteByte(embeddedCountShift * len + embeddedIndexShift * self._EmbeddedIndex.STRING + 2)
			else
				-- DebugPrint("Serializing string:", str, len)
				local required = GetRequiredBytes(len)
				self:_WriteByte(readerIndexShift * stringIndices[required])
				self:_WriteInt(len, required)
			end

			self._writeString(str)
			if len > 2 then
				self:_AddReference(self._stringRefs, str)
			end
		end
	end,
	["table"]   = function(self, tab)
		local ref = self._tableRefs[tab]
		if ref then
			-- DebugPrint("Serializing table ref:", tab)
			local required = GetRequiredBytes(ref)
			self:_WriteByte(readerIndexShift * tableRefIndices[required])
			self:_WriteInt(self._tableRefs[tab], required)
		else
			-- Add a reference before trying to serialize the table's contents,
			-- so that if the table recursively references itself, we can still
			-- properly serialize it.
			self:_AddReference(self._tableRefs, tab)

			local filter
			local mt = getmetatable(tab)
			if mt and type(mt) == "table" and mt.__LibSerialize then
				filter = mt.__LibSerialize.filter
			end

			-- First determine the "proper" length of the array portion of the table,
			-- which terminates at its first nil value. Note that some values in this
			-- range may not be serializable, which is fine - we'll handle them later.
			-- It's better to maximize the number of values that can be serialized
			-- without needing to also serialize their keys.
			local arrayCount, serializableArrayCount = 0, 0
			local entireArraySerializable = true
			local totalArraySerializable = 0
			for i, v in ipairs(tab) do
				arrayCount = i
				if self:_ShouldSerialize(tab, i, v, filter) then
					totalArraySerializable = totalArraySerializable + 1
					if entireArraySerializable then
						serializableArrayCount = i
					end
				else
					entireArraySerializable = false
				end
			end

			-- Consider the array portion as a series of zero or more serializable
			-- entries followed by zero or more entries that may or may not be
			-- serializable. For the latter portion, we can either write them in
			-- the array portion, padding the unserializable entries with nils,
			-- or just write them as key/value pairs in the map portion. We'll choose
			-- the former if there are more serializable entries in this portion than
			-- unserializable, or the latter if more are unserializable.
			if arrayCount - totalArraySerializable > totalArraySerializable - serializableArrayCount then
				arrayCount = serializableArrayCount
				entireArraySerializable = true
			end

			-- Next determine the count of all entries in the table whose keys are not
			-- included in the array portion, only counting keys that are serializable.
			local mapCount = 0
			local entireMapSerializable = true
			for k, v in pairs(tab) do
				if not IsArrayKey(k, arrayCount) then
					if self:_ShouldSerialize(tab, k, v, filter) then
						mapCount = mapCount + 1
					else
						entireMapSerializable = false
					end
				end
			end

			if mapCount == 0 then
				-- The table is an array. We can avoid writing the keys.
				if arrayCount < 16 then
					-- Short counts can be embedded directly into the type byte.
					-- DebugPrint("Serializing array, embedded count:", arrayCount)
					self:_WriteByte(embeddedCountShift * arrayCount + embeddedIndexShift * self._EmbeddedIndex.ARRAY + 2)
				else
					-- DebugPrint("Serializing array:", arrayCount)
					local required = GetRequiredBytes(arrayCount)
					self:_WriteByte(readerIndexShift * arrayIndices[required])
					self:_WriteInt(arrayCount, required)
				end

				for i = 1, arrayCount do
					local v = tab[i]
					if entireArraySerializable or self:_ShouldSerialize(tab, i, v, filter) then
						self:_WriteObject(v)
					else
						-- Since the keys are being omitted, write a `nil` entry
						-- for any values that shouldn't be serialized.
						self:_WriteObject(nil)
					end
				end
			elseif arrayCount ~= 0 then
				-- The table has both array and dictionary keys. We can still save space
				-- by writing the array values first without keys.

				if mapCount < 5 and arrayCount < 5 then
					-- Short counts can be embedded directly into the type byte.
					-- They have to be really short though, since we have two counts.
					-- Since neither can be zero (this is a mixed table),
					-- we can get away with not being able to represent 0.
					-- DebugPrint("Serializing mixed array-table, embedded counts:", arrayCount, mapCount)
					local combined = (mapCount - 1) * 4 + arrayCount - 1
					self:_WriteByte(embeddedCountShift * combined + embeddedIndexShift * self._EmbeddedIndex.MIXED + 2)
				else
					-- Use the max required bytes for the two counts.
					-- DebugPrint("Serializing mixed array-table:", arrayCount, mapCount)
					local required = max(GetRequiredBytes(mapCount), GetRequiredBytes(arrayCount))
					self:_WriteByte(readerIndexShift * mixedIndices[required])
					self:_WriteInt(arrayCount, required)
					self:_WriteInt(mapCount, required)
				end

				for i = 1, arrayCount do
					local v = tab[i]
					if entireArraySerializable or self:_ShouldSerialize(tab, i, v, filter) then
						self:_WriteObject(v)
					else
						-- Since the keys are being omitted, write a `nil` entry
						-- for any values that shouldn't be serialized.
						self:_WriteObject(nil)
					end
				end

				local mapCountWritten = 0
				if self._opts.stable then
					-- In order to ensure that the output is stable, we sort the map keys and write
					-- them in the sorted order.
					local mapKeys = {}
					for k, v in pairs(tab) do
						-- Exclude keys that have already been written via the previous loop.
						if not IsArrayKey(k, arrayCount) and (entireMapSerializable or self:_ShouldSerialize(tab, k, v, filter)) then
							table_insert(mapKeys, k)
						end
					end
					table_sort(mapKeys, StableKeySort)
					for _, k in ipairs(mapKeys) do
						self:_WriteObject(k)
						self:_WriteObject(tab[k])
						mapCountWritten = mapCountWritten + 1
					end
				else
					for k, v in pairs(tab) do
						-- Exclude keys that have already been written via the previous loop.
						if not IsArrayKey(k, arrayCount) and (entireMapSerializable or self:_ShouldSerialize(tab, k, v, filter)) then
							self:_WriteObject(k)
							self:_WriteObject(v)
							mapCountWritten = mapCountWritten + 1
						end
					end
				end
				assert(mapCount == mapCountWritten)
			else
				-- The table has only dictionary keys, so we'll write them all.
				if mapCount < 16 then
					-- Short counts can be embedded directly into the type byte.
					-- DebugPrint("Serializing table, embedded count:", mapCount)
					self:_WriteByte(embeddedCountShift * mapCount + embeddedIndexShift * self._EmbeddedIndex.TABLE + 2)
				else
					-- DebugPrint("Serializing table:", mapCount)
					local required = GetRequiredBytes(mapCount)
					self:_WriteByte(readerIndexShift * tableIndices[required])
					self:_WriteInt(mapCount, required)
				end

				if self._opts.stable then
					-- In order to ensure that the output is stable, we sort the map keys and write
					-- them in the sorted order.
					local mapKeys = {}
					for k, v in pairs(tab) do
						if entireMapSerializable or self:_ShouldSerialize(tab, k, v, filter) then
							table_insert(mapKeys, k)
						end
					end
					table_sort(mapKeys, StableKeySort)
					for _, k in ipairs(mapKeys) do
						self:_WriteObject(k)
						self:_WriteObject(tab[k])
					end
				else
					for k, v in pairs(tab) do
						if entireMapSerializable or self:_ShouldSerialize(tab, k, v, filter) then
							self:_WriteObject(k)
							self:_WriteObject(v)
						end
					end
				end
			end
		end
	end,
}


--[[---------------------------------------------------------------------------
    API support.
--]]---------------------------------------------------------------------------

local serializeTester = CreateSerializer(canSerializeFnOptions)

function C_Serialize:IsSerializableType(...)
	return serializeTester:_CanSerialize(canSerializeFnOptions, ...)
end

function C_Serialize:SerializeEx(opts, ...)
	local ser = CreateSerializer(opts)

	ser:_WriteByte(SERIALIZATION_VERSION)

	for i = 1, select("#", ...) do
		local input = select(i, ...)
		if not ser:_WriteObject(input) then
			-- An unserializable object was passed as an argument.
			-- Write nil into its slot so that we deserialize a
			-- consistent number of objects from the resulting string.
			ser:_WriteObject(nil)
		end
	end

	return ser._flushWriter()
end

function C_Serialize:Serialize(...)
	return self:SerializeEx(defaultOptions, ...)
end

function C_Serialize:DeserializeValue(input)
	local deser = CreateDeserializer(input)

	-- Since there's only one compression version currently,
	-- no extra work needs to be done to decode the data.
	local version = deser:_ReadByte()
	assert(version <= DESERIALIZATION_VERSION, "Unknown serialization version!")

	-- Since the objects we read may be nil, we need to explicitly
	-- track the number of results and assign by index so that we
	-- can call unpack() successfully at the end.
	local output = {}
	local outputSize = 0

	while deser._readerBytesLeft() > 0 do
		outputSize = outputSize + 1
		output[outputSize] = deser:_ReadObject()
	end

	if deser._readerBytesLeft() < 0 then
		error("Reader went past end of input")
	end

	return unpack(output, 1, outputSize)
end

function C_Serialize:Deserialize(input)
	return pcall(self.DeserializeValue, self, input)
end

function C_Serialize:SerializeCompressForPrint(input)
	local serialized = self:Serialize(input)
	if serialized then
		local compressed = C_Deflate:CompressDeflate(serialized)
		if compressed then
			return C_Deflate:EncodeForPrint(compressed)
		end
	end
end

function C_Serialize:DeserializeDecompressFromPrint(input)
	if type(input) ~= "string" then return end
	local decode = C_Deflate:DecodeForPrint(input)
	if decode then
		local decompress = C_Deflate:DecompressDeflate(decode)
		if decompress then
			return select(2, C_Serialize:Deserialize(decompress))
		end
	end
end


--[[---------------------------------------------------------------------------
    https://github.com/grafi-tt/lunajson
--]]---------------------------------------------------------------------------
-- Encoder
do
	local f_string_esc_pat = '[^ -!#-[%]^-\255]'

	local function newencoder()
		local v, nullv
		local i, builder, visited

		local function f_tostring(v)
			builder[i] = tostring(v)
			i = i+1
		end

		local radixmark = match(tostring(0.5), '[^0-9]')
		local delimmark = match(tostring(12345.12345), '[^0-9' .. radixmark .. ']')
		if radixmark == '.' then
			radixmark = nil
		end

		local radixordelim
		if radixmark or delimmark then
			radixordelim = true
			if radixmark and strfind(radixmark, '%W') then
				radixmark = '%' .. radixmark
			end
			if delimmark and strfind(delimmark, '%W') then
				delimmark = '%' .. delimmark
			end
		end

		local f_number = function(n)
			if tiny < n and n < huge then
				local s = format("%.17g", n)
				if radixordelim then
					if delimmark then
						s = gsub(s, delimmark, '')
					end
					if radixmark then
						s = gsub(s, radixmark, '.')
					end
				end
				builder[i] = s
				i = i+1
				return
			end
			error('invalid number')
		end

		local doencode

		local f_string_subst = {
			['"'] = '\\"',
			['\\'] = '\\\\',
			['\b'] = '\\b',
			['\f'] = '\\f',
			['\n'] = '\\n',
			['\r'] = '\\r',
			['\t'] = '\\t',
			__index = function(_, c)
				return format('\\u00%02X', strbyte(c))
			end
		}
		setmetatable(f_string_subst, f_string_subst)

		local function f_string(s)
			builder[i] = '"'
			if strfind(s, f_string_esc_pat) then
				s = gsub(s, f_string_esc_pat, f_string_subst)
			end
			builder[i+1] = s
			builder[i+2] = '"'
			i = i+3
		end

		local function f_table(o)
			if visited[o] then
				error("loop detected")
			end
			visited[o] = true

			local tmp = o[0]
			if type(tmp) == 'number' then -- arraylen available
				builder[i] = '['
				i = i+1
				for j = 1, tmp do
					doencode(o[j])
					builder[i] = ','
					i = i+1
				end
				if tmp > 0 then
					i = i-1
				end
				builder[i] = ']'

			else
				tmp = o[1]
				if tmp ~= nil then -- detected as array
					builder[i] = '['
					i = i+1
					local j = 2
					repeat
						doencode(tmp)
						tmp = o[j]
						if tmp == nil then
							break
						end
						j = j+1
						builder[i] = ','
						i = i+1
					until false
					builder[i] = ']'

				else -- detected as object
					builder[i] = '{'
					i = i+1
					local tmp = i
					for k, v in pairs(o) do
						if type(k) ~= 'string' then
							error("non-string key")
						end
						f_string(k)
						builder[i] = ':'
						i = i+1
						doencode(v)
						builder[i] = ','
						i = i+1
					end
					if i > tmp then
						i = i-1
					end
					builder[i] = '}'
				end
			end

			i = i+1
			visited[o] = nil
		end

		local dispatcher = {
			boolean = f_tostring,
			number = f_number,
			string = f_string,
			table = f_table,
			__index = function()
				error("invalid type value")
			end
		}
		setmetatable(dispatcher, dispatcher)

		function doencode(v)
			if v == nullv then
				builder[i] = 'null'
				i = i+1
				return
			end
			return dispatcher[type(v)](v)
		end

		local function encode(v_, nullv_)
			v, nullv = v_, nullv_
			i, builder, visited = 1, {}, {}

			doencode(v)
			return table_concat(builder)
		end

		return encode
	end
	
	C_Serialize.jsonEncoder = newencoder()
end

function C_Serialize:ToJSON(o)
	return self.jsonEncoder(o)
end

function C_Serialize:FromJSON(s)
	return DecodeJSON(s)
end

-- Helper function to read a json cache data quickly
function C_Serialize:FromJSONData(category, index)
	if type(category) ~= "string" then return end
	index = tonumber(index)
	if not index then index = 0 end

	if not HasJsonCacheData(category, index) then return end

	local json = GetJsonCacheData(category, index)
	if not json then return end

	return self:FromJSON(json)
end

-- Helper function to read a json cache category quickly
function C_Serialize:FromJSONCategory(category)
	if type(category) ~= "string" then return {} end

	local jsonArray = {}
	for _, json in ipairs(GetJsonCacheCategory(category)) do
		tinsert(jsonArray, self:FromJSON(json))
	end

	return jsonArray
end

--[[---------------------------------------------------------------------------
    lua-lzstring: lua lz string implementation https://github.com/benbiti/lua-lzstring/blob/master/lzstring.lua
--]]---------------------------------------------------------------------------
local keyStrBase64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
local keyStrUriSafe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$"
local baseReverseDic_keyStrBase64 = {}
local baseReverseDic_keyStrUriSafe = {}

for i = 0, string.len(keyStrBase64) - 1, 1 do
	baseReverseDic_keyStrBase64[string.char(string.byte(keyStrBase64, i + 1))] = i
end

for i = 0, string.len(keyStrUriSafe) - 1, 1 do
	baseReverseDic_keyStrUriSafe[string.char(string.byte(keyStrUriSafe, i + 1))] = i
end

local function GetBaseValueBase64(character)
	return baseReverseDic_keyStrBase64[character]
end

local function GetBaseValueURI(character)
	return baseReverseDic_keyStrUriSafe[character]
end

-- this needs a better name but whatever
local function f(i)
	if i >= 256 then
		local high = bit.rshift(i, 8)
		local low = bit.band(i, 0xff)
		return  string.char(high)..string.char(low)
	else
		return string.char(i)
	end
end

function C_Serialize:CompressForURI(uncompressedStr)
	if not uncompressedStr or uncompressedStr == '' then
		return ""
	end

	local length = string.len(uncompressedStr)
	local i
	local value
	context_dictionary = {}
	context_dictionaryToCreate = {}
	local context_c
	local context_wc
	local context_w = ''
	local context_enlargeIn = 2
	local context_dictSize = 3
	local context_numBits = 2
	local context_data = ''
	local context_data_val = 0
	local context_data_position = 0
	local ii

	for i = 0, length - 1, 1 do

		context_c = string.char(string.byte(uncompressedStr, i + 1))
		if not context_dictionary[context_c] then
			context_dictionary[context_c] = context_dictSize
			context_dictSize = context_dictSize + 1
			context_dictionaryToCreate[context_c] = 1
		end

		context_wc = context_w .. context_c

		if context_dictionary[context_wc] then
			context_w = context_wc
		else
			if context_dictionaryToCreate[context_w] then
				if string.byte(context_w) < 256 then
					for i = 0, context_numBits - 1, 1
					do
						context_data_val = bit.lshift(context_data_val, 1)
						if context_data_position == 6 - 1 then
							context_data_position = 0
							context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
							context_data_val = 0
						else
							context_data_position = context_data_position + 1
						end
					end

					value = string.byte(context_w)

					for i = 0, 8 - 1, 1
					do
						context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
						if context_data_position == 6 - 1 then
							context_data_position = 0
							context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
							context_data_val = 0
						else
							context_data_position = context_data_position + 1
						end
						value = bit.arshift(value, 1)
					end

				else
					value = 1
					for i = 0, context_numBits - 1, 1
					do
						context_data_val = bit.bor(bit.lshift(context_data_val, 1), value)
						if context_data_position == 6 - 1 then
							context_data_position = 0
							context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
							context_data_val = 0
						else
							context_data_position = context_data_position + 1
						end
						value = 0
					end

					value = string.byte(context_w)
					for i = 0, 16 - 1, 1
					do
						context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
						if context_data_position == 6 - 1 then
							context_data_position = 0
							context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
							context_data_val = 0
						else
							context_data_position = context_data_position + 1
						end
						value = bit.arshift(value, 1)
					end

				end

				context_enlargeIn = context_enlargeIn - 1
				if context_enlargeIn == 0 then
					context_enlargeIn = 2 ^ context_numBits
					context_numBits = context_numBits + 1
				end
				context_dictionaryToCreate[context_w] = nil

			else
				value = context_dictionary[context_w]
				for i = 0, context_numBits - 1, 1
				do
					context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
					if context_data_position == 6 - 1 then
						context_data_position = 0
						context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
						context_data_val = 0
					else
						context_data_position = context_data_position + 1
					end
					value = bit.arshift(value, 1)
				end

			end

			context_enlargeIn = context_enlargeIn - 1
			if context_enlargeIn == 0 then
				context_enlargeIn = 2 ^ context_numBits
				context_numBits = context_numBits + 1
			end
			-- Add wc to the dictionary
			context_dictionary[context_wc] = context_dictSize
			context_dictSize = context_dictSize + 1
			context_w = context_c

		end
	end

	-- Output the code for w.
	if context_w and context_wc ~= '' then
		if context_dictionaryToCreate[context_w] then
			if string.byte(context_w) < 256 then
				for i = 0, context_numBits - 1, 1
				do
					context_data_val = bit.lshift(context_data_val, 1)
					if context_data_position == 6 - 1 then
						context_data_position = 0
						context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
						context_data_val = 0
					else
						context_data_position = context_data_position + 1
					end
				end

				value = string.byte(context_w)

				for i = 0, 8 - 1, 1 do
					context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
					if context_data_position == 6 - 1 then
						context_data_position = 0
						context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
						context_data_val = 0
					else
						context_data_position = context_data_position + 1
					end
					value = bit.arshift(value, 1)
				end
			else
				value = 1
				for i = 0, context_numBits - 1, 1 do
					context_data_val = bit.bor(bit.lshift(context_data_val, 1), value)
					if context_data_position == 6 - 1 then
						context_data_position = 0
						context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
						context_data_val = 0
					else
						context_data_position = context_data_position + 1
					end
					value = 0
				end

				value = string.byte(context_w)
				for i = 0, 16 - 1, 1 do
					context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
					if context_data_position == 6 - 1 then
						context_data_position = 0
						context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
						context_data_val = 0
					else
						context_data_position = context_data_position + 1
					end
					value = bit.arshift(value, 1)
				end
			end

			context_enlargeIn = context_enlargeIn - 1
			if context_enlargeIn == 0 then
				context_enlargeIn = 2 ^ context_numBits
				context_numBits = context_numBits + 1
			end
			context_dictionaryToCreate[context_w] = nil
		else
			value = context_dictionary[context_w]
			for i = 0, context_numBits - 1, 1 do
				context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
				if context_data_position == 6 - 1 then
					context_data_position = 0
					context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
					context_data_val = 0
				else
					context_data_position = context_data_position + 1
				end
				value = bit.arshift(value, 1)
			end
		end
		context_enlargeIn = context_enlargeIn - 1
		if context_enlargeIn == 0 then
			context_enlargeIn = 2 ^ context_numBits
			context_numBits = context_numBits + 1
		end
	end

	-- Mark the end of the stream
	value = 2
	for i = 0, context_numBits - 1, 1 do
		context_data_val = bit.bor(bit.lshift(context_data_val, 1), bit.band(value, 1))
		if context_data_position == 6 - 1 then
			context_data_position = 0
			context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
			context_data_val = 0
		else
			context_data_position = context_data_position + 1
		end
		value = bit.arshift(value, 1)
	end

	--Flush the last char
	while 1 == 1 do
		context_data_val = bit.lshift(context_data_val, 1)
		if context_data_position == 6 - 1 then
			context_data = context_data .. string.char(string.byte(keyStrUriSafe, context_data_val + 1))
			break
		else
			context_data_position = context_data_position + 1
		end
	end

	return context_data
end

local DecData = {
	val      = '',
	position = 0,
	index    = 0,
}

function DecData:new(o, val, position, index)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.val = val or ''
	self.position = position or 0
	self.index = index or 0
	setmetatable(o, self)
	return o
end

function DecData:set_val(val)
	self.val = val
end

function DecData:set_position(position)
	self.position = position
end

function DecData:get_val()
	return self.val
end

function DecData:get_index()
	return self.index
end

function DecData:get_position()
	return self.position
end

function DecData:set_index(index)
	self.index = index
end

function C_Serialize:DecompressFromURI(inputStr)
	local length = strlen(inputStr)
	local dictionary = {}
	local next = 0
	local enlargeIn = 4
	local dictSize = 4
	local numBits = 3
	local entry = ''
	local result_index = 0
	local result = {}
	local w
	local bits
	local resb
	local maxpower
	local power
	local c
	local data = DecData:new(nil, GetBaseValueBase64(string.char(string.byte(inputStr, 1))), 32, 1)

	for i = 0, 3 - 1, 1 do
		dictionary[i] = f(i, 32)
	end

	local bits = 0
	local maxpower = 2 ^ 2
	local power = 1

	while power ~= maxpower do
		resb = bit.band(data:get_val(), data:get_position())
		data:set_position(bit.rshift(data:get_position(), 1))
		if data:get_position() == 0 then
			data:set_position(32)
			data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
			data:set_index(data:get_index() + 1)
		end

		if resb > 0 then
			bits = bit.bor(bits, 1 * power)
		else
			bits = bit.bor(bits, 0)
		end
		power = bit.lshift(power, 1)
	end

	next = bits
	if next == 0 then
		bits = 0
		-- why not use 256 ??
		maxpower = 2 ^ 8
		power = 1
		while power ~= maxpower
		do
			resb = bit.band(data:get_val(), data:get_position())
			data:set_position(bit.rshift(data:get_position(), 1))
			if data:get_position() == 0 then
				data:set_position(32)
				data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
				data:set_index(data:get_index() + 1)
			end

			if resb > 0 then
				bits = bit.bor(bits, 1 * power)
			else
				bits = bit.bor(bits, 0)
			end
			power = bit.lshift(power, 1)
		end
		c = f(bits, 32)
	elseif next == 1 then
		bits = 0
		maxpower = 2 ^ 16
		power = 1
		while power ~= maxpower
		do
			resb = bit.band(data:get_val(), data:get_position())
			data:set_position(bit.rshift(data:get_position(), 1))
			if data:get_position() == 0 then
				data:set_position(32)
				data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
				data:set_index(data:get_index() + 1)
			end

			if resb > 0 then
				bits = bit.bor(bits, 1 * power)
			else
				bits = bit.bor(bits, 0)
			end
			power = bit.lshift(power, 1)
		end
		c = f(bits, 32)
	elseif next == 2 then
		return ""
	end

	dictionary[3] = c
	w = c
	-- mock set??
	result[result_index] = w
	result_index = result_index + 1

	while 1 == 1
	do
		if data:get_index() > length then
			return ""
		end

		bits = 0
		maxpower = 2 ^ numBits
		power = 1

		while power ~= maxpower
		do
			resb = bit.band(data:get_val(), data:get_position())
			data:set_position(bit.rshift(data:get_position(), 1))
			if data:get_position() == 0 then
				data:set_position(32)
				data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
				data:set_index(data:get_index() + 1)
			end
			if resb > 0 then
				bits = bit.bor(bits, 1 * power)
			else
				bits = bit.bor(bits, 0)
			end
			power = bit.lshift(power, 1)
		end
		-- TODO: very strange here, c above is as char/string, here further is a int, rename "c" in the switch as "cc"
		local cc = bits
		if cc == 0 then
			bits = 0
			maxpower = 2 ^ 8
			power = 1
			while power ~= maxpower
			do
				resb = bit.band(data:get_val(), data:get_position())
				data:set_position(bit.rshift(data:get_position(), 1))
				if data:get_position() == 0 then
					data:set_position(32)
					data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
					data:set_index(data:get_index() + 1)
				end
				if resb > 0 then
					bits = bit.bor(bits, 1 * power)
				else
					bits = bit.bor(bits, 0)
				end
				power = bit.lshift(power, 1)
			end

			dictionary[dictSize] = f(bits, 32)
			dictSize = dictSize + 1
			cc = dictSize - 1
			enlargeIn = enlargeIn - 1

		elseif cc == 1 then
			bits = 0
			maxpower = 2 ^ 16
			power = 1
			while power ~= maxpower
			do
				resb = bit.band(data:get_val(), data:get_position())
				data:set_position(bit.rshift(data:get_position(), 1))
				if data:get_position() == 0 then
					data:set_position(32)
					data:set_val(GetBaseValueBase64(string.char(string.byte(inputStr, data:get_index() + 1))))
					data:set_index(data:get_index() + 1)
				end
				if resb > 0 then
					bits = bit.bor(bits, 1 * power)
				else
					bits = bit.bor(bits, 0)
				end
				power = bit.lshift(power, 1)
			end

			dictionary[dictSize] = f(bits, 32)
			dictSize = dictSize + 1
			cc = dictSize - 1
			enlargeIn = enlargeIn - 1

		elseif cc == 2 then
			local decomString = ''
			for key, value in pairs(result)
			do
				--print("key is",key, "value=",value)
				decomString = decomString .. value
			end
			return decomString
		end

		if enlargeIn == 0 then
			enlargeIn = 2 ^ numBits
			numBits = numBits + 1
		end

		if cc < tlen(dictionary) and dictionary[cc] ~= nil then
			entry = dictionary[cc]
		else
			if cc == dictSize then
				entry = w .. string.char(string.byte(w, 1))
			else
				return nil
			end
		end

		result[result_index] = entry
		result_index = result_index + 1
		--Add w+entry[0] to the dictionary
		dictionary[dictSize] = w .. string.char(string.byte(entry, 1))
		dictSize = dictSize + 1
		enlargeIn = enlargeIn - 1

		w = entry

		if enlargeIn == 0 then
			enlargeIn = 2 ^ numBits
			numBits = numBits + 1
		end
	end
end
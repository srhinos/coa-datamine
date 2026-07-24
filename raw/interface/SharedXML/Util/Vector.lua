Vector4D = {}
local Vector4DMixin = {}
Vector3D = {}
local Vector3DMixin = {}
Vector2D = {}
local Vector2DMixin = {}

local VectorMathPrototype = {}
local VectorMathMetatable = { __index = VectorMathPrototype, __metatable = true }

function VectorMathMetatable.__add(a, b)
	a = a:Clone()
	a.x = a.x + b.x
	a.y = a.y + b.y
	if a.z and b.z then
		a.z = a.z + b.z
	end
	if a.w and b.w then
		a.w = a.w + b.w
	end

	return a
end

function VectorMathMetatable.__sub(a, b)
	a = a:Clone()
	a.x = a.x - b.x
	a.y = a.y - b.y
	if a.z and b.z then
		a.z = a.z - b.z
	end
	if a.w and b.w then
		a.w = a.w - b.w
	end

	return a
end

function VectorMathMetatable.__mul(a, b)
	a = a:Clone()
	a.x = a.x * b.x
	a.y = a.y * b.y
	if a.z and b.z then
		a.z = a.z * b.z
	end
	if a.w and b.w then
		a.w = a.w * b.w
	end

	return a
end

function VectorMathMetatable.__div(a, b)
	a = a:Clone()
	a.x = b.x ~= 0 and a.x / b.x or 0
	a.y = b.y ~= 0 and a.y / b.y or 0
	if a.z and b.z then
		a.z = b.z ~= 0 and a.z / b.z or 0
	end
	if a.w and b.w then
		a.w = b.w ~= 0 and a.w / b.w or 0
	end

	return a
end

function VectorMathMetatable.__mod(a, b)
	a = a:Clone()
	a.x = b.x ~= 0 and a.x % b.x or 0
	a.y = b.y ~= 0 and a.y % b.y or 0
	if a.z and b.z then
		a.z = b.z ~= 0 and a.z % b.z or 0
	end
	if a.w and b.w then
		a.w = b.w ~= 0 and a.w % b.w or 0
	end

	return a
end

function VectorMathMetatable:__unm()
	local v = self:Clone()
	v.x = -v.x
	v.y = -v.y
	if self.z then
		v.z = -v.z
	end
	if self.w then
		v.w = -v.w
	end
	return v
end

function VectorMathMetatable.__concat(a, b)
	return tostring(a) .. b
end

function VectorMathMetatable.__eq(a, b)
	local eq = MApprox(a.x, b.x)
	eq = eq and MApprox(a.y, b.y)
	if a.z and b.z then
		eq = eq and MApprox(a.z, b.z)
	end
	if a.w and b.w then
		eq = eq and MApprox(a.w, b.w)
	end

	return eq
end

function VectorMathMetatable.__lt(a, b)
	local lt = a.x < b.x
	lt = lt and a.y < b.y
	if a.z and b.z then
		lt = lt and a.z < b.z
	end
	if a.w and b.w then
		lt = lt and a.w < b.w
	end

	return lt
end

function VectorMathMetatable.__le(a, b)
	local lt = a.x <= b.x
	lt = lt and a.y <= b.y
	if a.z and b.z then
		lt = lt and a.z <= b.z
	end
	if a.w and b.w then
		lt = lt and a.w <= b.w
	end

	return lt
end

function VectorMathMetatable:__tostring()
	if self.w then
		return format("<Vector4D(%s, %s, %s, %s)>", self.x, self.y, self.z, self.w)
	end
	if self.z then
		return format("<Vector3D(%s, %s, %s)>", self.x, self.y, self.z)
	end

	return format("<Vector2D(%s, %s)>", self.x, self.y)
end

function VectorMathPrototype:Dot(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end
	local value = self.x * vector.x + self.y * vector.y
	if self.z and vector.z then
		value = value + self.z * vector.z
	end

	if self.w and vector.w then
		value = value + self.w * vector.w
	end

	return value
end

function VectorMathPrototype:Cross(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end
	local rightX, rightY, rightZ = self.x, self.y, self.z or 0
	local leftX, leftY, leftZ = vector.x, vector.y, vector.z or 0

	return leftY * rightZ - leftZ * rightY,
	leftZ * rightX - leftX * rightZ,
	leftX * rightY - leftY * rightX
end

function VectorMathPrototype:LengthSquared()
	return self:Dot(self)
end

function VectorMathPrototype:Length()
	return sqrt(self:LengthSquared())
end

function VectorMathPrototype:Normalize()
	local len = self:Length()
	if len == 0 then return self end
	self.x = self.x / len
	self.y = self.y / len
	self.z = self.z and self.z / len
	self.w = self.w and self.w / len
	return self
end

function VectorMathPrototype:Normalized()
	local len = self:Length()
	local v = self:Clone()
	if len == 0 then return v end
	v.x = v.x / len
	v.y = v.y / len
	v.z = v.z and v.z / len
	v.w = v.w and v.w / len
	return v
end

function VectorMathPrototype:Scale(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
	self.z = self.z and self.z * scalar
	self.w = self.w and self.w * scalar
	return self
end

function VectorMathPrototype:RadiansBetween(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end

	return MDegToRad(self:DegreesBetween(vector))
end

function VectorMathPrototype:DegreesBetween(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end

	return atan2(vector.y - self.y, vector.x - self.x)
end

function VectorMathPrototype:Direction(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end

	return self:DistanceVector(vector):Normalize()
end

function VectorMathPrototype:Distance(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end

	return (vector - self):Length()
end

function VectorMathPrototype:DistanceVector(vector, ...)
	if type(vector) == "number" then
		local y, z, w = ...
		vector = { x = vector, y = y, z = z, w = w }
	end

	return (vector - self)
end

--
-- Vector 2D
--
local Vector2DMetatable = { __metatable = true, __mode = "kv" }
setmetatable(Vector2D, Vector2DMetatable)

function Vector2DMetatable:__call(x, y)
	local v = CreateFromMixins(Vector2DMixin)
	v:SetXY(x, y)
	setmetatable(v, VectorMathMetatable)
	return v
end

-- Mixin
function Vector2DMixin:SetXY(x, y)
	self.x = x
	self.y = y
end

function Vector2DMixin:GetXY()
	return self.x, self.y
end

function Vector2DMixin:Clone()
	return Vector2D(self.x, self.y)
end

--
-- Vector3D
--
local Vector3DMetatable = { __metatable = true, __mode = "kv" }
setmetatable(Vector3D, Vector3DMetatable)

function Vector3DMetatable:__call(x, y, z)
	local v = CreateFromMixins(Vector2DMixin, Vector3DMixin)
	v:SetXYZ(x, y, z)
	setmetatable(v, VectorMathMetatable)
	return v
end

-- Mixin
function Vector3DMixin:SetXYZ(x, y, z)
	self.x = x
	self.y = y
	self.z = z
end

function Vector3DMixin:GetXYZ()
	return self.x, self.y, self.z
end

function Vector3DMixin:Clone()
	return Vector3D(self.x, self.y, self.z)
end

--
-- Vector4D
--
local Vector4DMetatable = { __metatable = true, __mode = "kv" }
setmetatable(Vector4D, Vector4DMetatable)

function Vector4DMetatable:__call(x, y, z, w)
	local v = CreateFromMixins(Vector2DMixin, Vector3DMixin, Vector4DMixin)
	v:SetXYZW(x, y, z, w)
	setmetatable(v, VectorMathMetatable)
	return v
end

-- Mixin
function Vector4DMixin:SetXYZW(x, y, z, w)
	self.x = x
	self.y = y
	self.z = z
	self.w = w
end

function Vector4DMixin:GetXYZW()
	return self.x, self.y, self.z, self.w
end

function Vector4DMixin:Clone()
	return Vector4D(self.x, self.y, self.z, self.w)
end

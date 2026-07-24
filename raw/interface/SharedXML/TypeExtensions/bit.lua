function bit.tohex(x, n)
	n = n or 8
	local up
	if n <= 0 then
		if n == 0 then return '' end
		up = true
		n = - n
	end
	x = bit.band(x, 16^n-1)
	return ('%0'..n..(up and 'X' or 'x')):format(x)
end

function bit.rol(x, n)
	n = n % 32
	return bit.bor(bit.lshift(x, n), bit.rshift(x, 32-n))
end

function bit.ror(x, n)
	return bit.rol(x, -n)
end

function bit.test(x, y)
	return bit.band(x, y) ~= 0
end

function bit.contains(x, y)
	return bit.band(x, y) == y
end

byte = {}

function byte.lshift(x, n)
	return bit.lshift(x, n*4)
end

function byte.rshift(x, n)
	return bit.rshift(x, n*4)
end

function byte.rol(x, n)
	return bit.rol(x, n*4)
end

function byte.ror(x, n)
	return bit.ror(x, n*4)
end 
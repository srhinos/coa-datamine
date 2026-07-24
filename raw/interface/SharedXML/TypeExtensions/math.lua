-- Remaps a number to be the same distance from newMin and newMax as it was from currentMin and currentMax
function math.RemapToRange(value, currentMin, currentMax, newMin, newMax)
    if value == currentMin and value == currentMax then
        return newMin
    end

    return (value - currentMin) * (newMax - newMin) / (currentMax - currentMin) + newMin
end

-- Returns if a number is nearly equal to another number
function math.NearlyEquals(value, target, tolerance)
    if value == target then return true end
    if not tolerance then tolerance = 0.0000001 end

    if type(value) ~= "number" then return false end
    if type(target) ~= "number" then return false end

    local diff = abs(target - value)
    return diff < tolerance
end
MApprox = math.NearlyEquals

-- Interpolate between startValue and endValue based on amount
function math.lerp(startValue, endValue, a)
    if startValue == endValue then
        return startValue
    end
    return (startValue + (endValue - startValue) * a)
end
MLerp = math.lerp
Lerp = math.lerp

-- Clamps a value between minValue and maxValue
function math.clamp(value, minValue, maxValue)
    if not minValue then
        minValue = 0
        maxValue = 1
    end
    return min(max(minValue, value), max(minValue, maxValue))
end
MClamp = math.clamp
Clamp = math.clamp

-- Wraps a value to be between minValue and maxValue
function math.Wrap(value, minValue, maxValue)
    if value >= minValue and value <= maxValue then
        return value
    end

    local range = maxValue - minValue + 1

    value = (value - minValue) % range

    if value < 0 then
        return maxValue + value + 1
    end

    return minValue + value
end

function math.EaseIn(t, exp)
    exp = exp or 2
    return t ^ exp
end
EaseIn = math.EaseIn

function math.EaseOut(t, exp)
    exp = exp or 2
    return 1 - ((1 - t) ^ exp)
end
EaseOut = math.EaseOut

function math.EaseInOut(t, exp)
    return math.lerp(EaseIn(t), EaseOut(t, exp), t)
end
EaseInOut = math.EaseInOut

function math.round(value)
    if value < 0 then
        return ceil(value - .5)
    end
    return floor(value + .5)
end
MRound = math.round
Round = math.round

function math.trunc(num, digits)
    local mult = 10^(digits)
    return math.modf(num*mult)/mult
end
MTrunc = math.trunc

function math.radtodeg(rad)
    rad = rad * 180 / math.pi
    rad = rad < 0 and rad + 360 or rad
    return rad
end
MRadToDeg = math.radtodeg

function math.degtorad(deg)
    return deg * math.pi / 180
end
MDegToRad = math.degtorad

function math.saturate(value)
    return math.clamp(value, 0, 1)
end 
MSaturate = math.saturate
Saturate = math.saturate

function math.percentbetween(value, startValue, endValue)
    if startValue == endValue then
        return 0.0
    end
    return (value - startValue) / (endValue - startValue)
end
MPercentBetween = math.percentbetween

function math.clampedpercentbetween(value, startValue, endValue)
    return math.saturate(math.percentbetween(value, startValue, endValue))
end
MClampedPercentBetween = math.clampedpercentbetween

local securecall = securecall
function CreateCounter(initialCount)
    local count = initialCount or 0
    local counter = function()
        count = count + 1
        return count
    end
    return function()
        return securecall(counter)
    end
end

function RandomFloatInRange(minValue, maxValue)
    return math.lerp(minValue, maxValue, math.random());
end

local TARGET_FRAME_PER_SEC = 60.0;
function math.deltalerp(startValue, endValue, amount, timeSec)
    return math.lerp(startValue, endValue, math.saturate(amount * timeSec * TARGET_FRAME_PER_SEC))
end
MDeltaLerp = math.deltalerp
DeltaLerp = math.deltalerp
FrameDeltaLerp = math.deltalerp

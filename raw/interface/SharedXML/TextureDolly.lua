TextureDollyMixin = {}

function TextureDollyMixin:SetDollyStartColor(r, g, b, a)
	self.dollyStartR = r or 1
	self.dollyStartG = g or 1
	self.dollyStartB = b or 1
	self.dollyStartA = a or 1
end

function TextureDollyMixin:SetDollyEndColor(r, g, b, a)
	self.dollyEndR = r or 1
	self.dollyEndG = g or 1
	self.dollyEndB = b or 1
	self.dollyEndA = a or 1
end

function TextureDollyMixin:SetDollyStartCoords(left, right, top, bottom)
	self.dollyStartLeft = left
	self.dollyStartRight = right
	self.dollyStartTop = top
	self.dollyStartBottom = bottom
end

function TextureDollyMixin:SetDollyEndCoords(left, right, top, bottom)
	self.dollyEndLeft = left
	self.dollyEndRight = right
	self.dollyEndTop = top
	self.dollyEndBottom = bottom
end

function TextureDollyMixin:MarkDollyComplete(isAtStart)
	if self.finishedCallback then
		self:finishedCallback(isAtStart)
	end
end

function TextureDollyMixin:SetDollyFinishCallback(callback)
	self.finishedCallback = callback
end

function TextureDollyMixin:SetDollyTimeScale(timescale)
	self.dollyTimescale = timescale
end

function TextureDollyMixin:MoveDollyForward(elapsed)
	if not self.dollyTime then
		self.dollyTime = 0
	elseif self.dollyTime >= 1 then
		if self.dollyEndLeft then
			self:SetTexCoord(self.dollyEndLeft, self.dollyEndRight, self.dollyEndTop, self.dollyEndBottom)
		end
		if self.dollyEndR then
			self:SetVertexColor(self.dollyEndR, self.dollyEndG, self.dollyEndB, self.dollyEndA)
		end
		self.dollyTime = 1
		self:MarkDollyComplete(false)
		return
	end

	local t = EaseOut(self.dollyTime)
	if self.dollyEndLeft then
		local left = math.lerp(self.dollyStartLeft, self.dollyEndLeft, t)
		local right = math.lerp(self.dollyStartRight, self.dollyEndRight, t)
		local top = math.lerp(self.dollyStartTop, self.dollyEndTop, t)
		local bottom = math.lerp(self.dollyStartBottom, self.dollyEndBottom, t)
		self:SetTexCoord(left, right, top, bottom)
	end
	
	if self.dollyEndR then
		local r = math.lerp(self.dollyStartR, self.dollyEndR, t)
		local g = math.lerp(self.dollyStartG, self.dollyEndG, t)
		local b = math.lerp(self.dollyStartB, self.dollyEndB, t)
		local a = math.lerp(self.dollyStartA, self.dollyEndA, t)
		self:SetVertexColor(r, g, b, a)
	end


	self.dollyTime = self.dollyTime + elapsed * (self.dollyTimescale or 1)
end

function TextureDollyMixin:MoveDollyBackward(elapsed)
	if not self.dollyTime then
		self.dollyTime = 1
	elseif self.dollyTime <= 0 then
		if self.dollyStartLeft then
			self:SetTexCoord(self.dollyStartLeft, self.dollyStartRight, self.dollyStartTop, self.dollyStartBottom)
		end
		if self.dollyStartR then
			self:SetVertexColor(self.dollyStartR, self.dollyStartG, self.dollyStartB, self.dollyStartA)
		end
		self.dollyTime = 0
		self:MarkDollyComplete(true)
		return
	end

	local t = EaseOut(self.dollyTime)
	if self.dollyStartLeft then
		local left = math.lerp(self.dollyStartLeft, self.dollyEndLeft, t)
		local right = math.lerp(self.dollyStartRight, self.dollyEndRight, t)
		local top = math.lerp(self.dollyStartTop, self.dollyEndTop, t)
		local bottom = math.lerp(self.dollyStartBottom, self.dollyEndBottom, t)
		self:SetTexCoord(left, right, top, bottom)
	end

	if self.dollyEndR then
		local r = math.lerp(self.dollyStartR, self.dollyEndR, t)
		local g = math.lerp(self.dollyStartG, self.dollyEndG, t)
		local b = math.lerp(self.dollyStartB, self.dollyEndB, t)
		local a = math.lerp(self.dollyStartA, self.dollyEndA, t)
		self:SetVertexColor(r, g, b, a)
	end
	
	self.dollyTime = self.dollyTime - elapsed * (self.dollyTimescale or 1)
end 
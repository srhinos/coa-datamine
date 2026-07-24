C_Flipbook = {}

C_Flipbook.Updater = CreateFrame("Frame")
C_Flipbook.Updater.activeFlipbooks = {}

C_Flipbook.Updater:SetScript("OnUpdate", function(self, elapsed)
	for i = #self.activeFlipbooks, 1, -1 do
		local flipbook = self.activeFlipbooks[i]
		if flipbook.playing then
			if flipbook:IsVisible() then
				flipbook:Update(elapsed)
			end
		else
			tremove(self.activeFlipbooks, i)
		end
	end
end)

AtlasFlipbookMixin = CreateFromMixins(CallbackRegistryMixin)

function C_Flipbook:CreateAtlasFlipbook(texture, atlas, frameWidth, frameHeight, frameCount, fps, oneShot)
	local flipbook = texture.flipbook or MixinAndLoad(texture, AtlasFlipbookMixin)
	flipbook:SetOneShot(oneShot)
	flipbook:SetCoordInsets()
	flipbook:SetFrameSize(frameWidth, frameHeight)
	flipbook:SetFPS(fps)
	flipbook:SetFrameCount(frameCount)
	flipbook:SetAtlas(atlas)
	flipbook:Initialize()
	texture.flipbook = flipbook
	return flipbook
end

function AtlasFlipbookMixin:OnLoad()
	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({
		"OnPlay",
		"OnStop",
		"OnRepeat",
	})
end

function AtlasFlipbookMixin:Initialize()
	self.frame = 1
	self.Columns = floor(self.atlasInfo.width / self.frameWidth)
	self.Rows = floor(self.atlasInfo.height / self.frameHeight)
	self.CoordWidth = (self.atlasInfo.rightTexCoord - self.atlasInfo.leftTexCoord) / self.Columns
	self.CoordHeight = (self.atlasInfo.bottomTexCoord - self.atlasInfo.topTexCoord) / self.Rows
end

function AtlasFlipbookMixin:SetAtlas(atlas)
	self.atlasInfo = AtlasUtil:GetAtlasInfo(atlas)
end

function AtlasFlipbookMixin:SetFrameSize(width, height)
	self.frameWidth = width
	self.frameHeight = height
end

function AtlasFlipbookMixin:SetFrameCount(frames)
	self.frames = frames
end

function AtlasFlipbookMixin:SetFPS(fps)
	self.fps = 1 / fps
	self.throttle = 0
end

function AtlasFlipbookMixin:SetOneShot(oneShot)
	self.oneShot = oneShot
end

function AtlasFlipbookMixin:SetCoordInsets(left, right, top, bottom)
	self.insets = {
		left = left or 0,
		right = right or 0,
		top = top or 0,
		bottom = bottom or 0,
	}
end

function AtlasFlipbookMixin:Update(elapsed)
	if self.frames < 2 then
		dprint("Flipbook has less than 2 frames!", self.atlasInfo.filename, self:GetName() or self:GetParent():GetName() or tostring(self))
		self:Stop()
	end

	if self.throttle > self.fps or elapsed > self.fps then
		local frame = self.frame + floor(self.throttle / self.fps)

		-- check if we are done playing a one shot animation
		if frame > self.frames and self.oneShot then
			frame = self.frames
		else
			while frame > self.frames do
				frame = max(1, frame - self.frames)
			end
			self:TriggerEvent("OnRepeat")
		end
		self.throttle = mod(self.throttle, self.fps)

		local left = (mod(frame - 1, self.Columns) * self.CoordWidth) + self.atlasInfo.leftTexCoord
		local right = min(left + self.CoordWidth, self.atlasInfo.rightTexCoord)
		local top = ((ceil(frame / self.Columns) - 1) * self.CoordHeight) + self.atlasInfo.topTexCoord
		local bottom = min(top + self.CoordHeight, self.atlasInfo.bottomTexCoord)
		self:SetTexCoord(left + self.insets.left, right - self.insets.right, top + self.insets.top, bottom - self.insets.bottom)
		self.frame = frame

		if self.oneShot and self.frame >= self.frames then
			self:Stop()
		end
	else
		self.throttle = self.throttle + elapsed
	end
end 

function AtlasFlipbookMixin:Play()
	self.frame = 1
	if not self.playing then
		self.playing = true
		tinsert(C_Flipbook.Updater.activeFlipbooks, self)
		self:TriggerEvent("OnPlay", self.oneShot)
	end
end

function AtlasFlipbookMixin:Stop()
	if self.playing then
		self.playing = nil
		self:TriggerEvent("OnStop", self.oneShot)
	end
end 

-------------------------------------------------------------------------------
--                             Vertical FlipBook                             --
-------------------------------------------------------------------------------
AtlasVerticalFlipbookMixin = {}

function AtlasVerticalFlipbookMixin:SetFrame(frame)
	-- in wildcard atlases we go top -> bottom -> right
 	local left = ((ceil(frame / self.Rows) - 1) * self.CoordWidth) + self.atlasInfo.leftTexCoord
	local right = min(left + self.CoordWidth, self.atlasInfo.rightTexCoord)
	local top = (mod(frame - 1, self.Rows) * self.CoordHeight) + self.atlasInfo.topTexCoord
	local bottom = min(top + self.CoordHeight, self.atlasInfo.bottomTexCoord)
	self:SetTexCoord(left + self.insets.left, right - self.insets.right, top + self.insets.top, bottom - self.insets.bottom)
end

function AtlasVerticalFlipbookMixin:Update(elapsed)
    if not self.throttle or not self.fps then
        return
    end

	if (self.throttle >= self.fps) or (elapsed > self.fps) then
		local frame = self.frame

		self:SetFrame(frame)

		self.frame = frame + self.frameStep
		self.throttle = 0

		if (self.inverted) then
			if self.oneShot and self.frame < 1 then
				self:Stop()
			end
		else
			if self.oneShot and self.frame > self.frames then
				self:Stop()
			end
		end
	else
		self.throttle = self.throttle + elapsed
	end
end 

function AtlasVerticalFlipbookMixin:Play()
	local constFrameDelay = 1/120
	local frameRate = GetFramerate()*(self.playSpeed or 1)

	self.frameStep = math.max(math.floor((60/frameRate)+0.5), 1) * (self.inverted and (-1) or 1) -- to keep timings on FPS lower than 60
	self.fps = ((frameRate > 90) and constFrameDelay or 0)

	AtlasFlipbookMixin.Play(self)

	if (self.inverted) then
		self.frame = self.frames
	end
end

function AtlasVerticalFlipbookMixin:OnStop()
	if self.nextFlipBook then
		self:Hide()
		self:Update(1)
		self.nextFlipBook:Show()
		self.nextFlipBook:Play()
	elseif self.multiFlipBookParent then -- no next flip book, trigger stop
		self.multiFlipBookParent:TriggerEvent("OnFinished")
		self.frame = self.frames -- make sure we display last frame in flipbook
		self:Update(1)
	end
end

function AtlasVerticalFlipbookMixin:Init() -- needed to reset texture position in sequence to properly show 1st frame
	if self.inverted then
		self.frameStep = -1
		self.frame = self.frames
		self:Update(1)
		return
	end

	self.frameStep = 1
	self.frame = 1
	self:Update(1)
end

function AtlasVerticalFlipbookMixin:SetInverted(inverted)
	self.inverted = inverted
end

function AtlasVerticalFlipbookMixin:SetSpeed(speed)
	self.playSpeed = 1/speed
end
-------------------------------------------------------------------------------
--                  Flipbook Handler for multiple flip books                 --
-------------------------------------------------------------------------------
-- multi flip book mixin is used to control multiple textures and their flipbooks 
-- it is more efficient to have multiple textures with their atlases and settings rather
-- than use 1 texture and change its settings. Problem is fps drop using method :SetTexture

-- Works with AtlasVerticalFlipbookMixin (vertical mixin) 
-- TODO: Add support for AtlasFlipbookMixin if needed

-- USAGE Example:
-- AtlasMultiFlipBookMixin = CreateFromMixinsAndLoad(AtlasMultiFlipBookMixin)
-- AtlasMultiFlipBookMixin:Initialize(self, "ARTWORK")
-- AtlasMultiFlipBookMixin:SetSize(nil, 382, 382)
-- AtlasMultiFlipBookMixin:SetPoint(nil, "CENTER")
-- AtlasMultiFlipBookMixin:AddFlipBook("atlasInfo", width, height, totalFrames, fps)
-- AtlasMultiFlipBookMixin:Play()

AtlasMultiFlipBookMixin = CreateFromMixins(CallbackRegistryMixin) -- a controller for a bunch of textures + flipbooks

function AtlasMultiFlipBookMixin:OnLoad()
	self.parent = nil
	self.drawLayer = nil
	self.size = nil
	self.point = nil
	self.blendMode = nil
	self.textures = {}

	CallbackRegistryMixin.OnLoad(self)
	self:GenerateCallbackEvents({
		"OnPlay",
		"OnFinished",
	})
end

function AtlasMultiFlipBookMixin:Initialize(parent, drawLayer, blendMode)
	self.parent = parent
	self.drawLayer = drawLayer
end

function AtlasMultiFlipBookMixin:SetBlendMode(...)
	for _, texture in pairs(self.textures) do
		texture:SetBlendMode(...)
	end

	self.blendMode = ...
end

function AtlasMultiFlipBookMixin:GetTextureIndex(index)
	return self.textures[index]
end

-- TODO: Get rid of textureIndex
function AtlasMultiFlipBookMixin:SetSize(textureIndex, ...)
	for _, texture in pairs(self.textures) do
		texture:SetSize(...)
	end

	self.size = {...}
end

function AtlasMultiFlipBookMixin:SetPoint(textureIndex, ...)
	for _, texture in pairs(self.textures) do
		texture:SetPoint(...)
	end

	self.point = {...}
end

function AtlasMultiFlipBookMixin:SetSpeed(speed)
	for _, texture in pairs(self.textures) do
		texture:SetSpeed(speed)
	end
end

function AtlasMultiFlipBookMixin:Hide()
	for _, texture in pairs(self.textures) do
		texture:Hide()
	end
end

function AtlasMultiFlipBookMixin:Invert()
	for _, texture in pairs(self.textures) do
		texture:SetInverted(true)
	end
end

function AtlasMultiFlipBookMixin:AddFlipBook(atlas, width, height, frames, fps)
	local tID = (#self.textures)+1
	local oneShot = true
	local texture = self.parent:CreateTexture(nil, self.drawLayer or "OVERLAY")

	if (self.blendMode) then
		texture:SetBlendMode(self.blendMode)
	end

	if self.point then
		texture:SetPoint(unpack(self.point))
	end

	if self.size then
		texture:SetSize(unpack(self.size)) 
	end

	texture:SetAtlas(atlas)
	C_Flipbook:CreateAtlasFlipbook(texture, atlas, width, height, frames, fps, oneShot)
	MixinAndLoad(texture, AtlasVerticalFlipbookMixin)
	texture.multiFlipBookParent = self
	texture:RegisterCallback("OnStop", GenerateClosure(AtlasVerticalFlipbookMixin.OnStop, texture))

	if (tID > 1) then
		local prevTexture = self.textures[tID-1]
		prevTexture.nextFlipBook = texture
	end

	table.insert(self.textures, texture)
end

function AtlasMultiFlipBookMixin:Reset()
	for _, texture in pairs(self.textures) do
		texture:Init()
		texture:Hide()
	end
end

function AtlasMultiFlipBookMixin:Show()
	self:Reset()

	local _, texture = next(self.textures)
	
	if (texture) then
		texture:Show()
	end
end

function AtlasMultiFlipBookMixin:Play()
	self:Reset()

	local _, texture = next(self.textures)

	if (texture) then
		texture:Show()
		texture.flipbook:Play()
	end

	self:TriggerEvent("OnPlay")
end

function AtlasMultiFlipBookMixin:IsPlaying()
	for _, texture in pairs(self.textures) do
		if texture.playing then
			return true
		end
	end

	return false
end

function AtlasMultiFlipBookMixin:IsVisible()
	for _, texture in pairs(self.textures) do
		if texture:IsVisible() then
			return true
		end
	end

	return false
end

function AtlasMultiFlipBookMixin:Stop()
	for _, texture in pairs(self.textures) do
		texture.playing = nil
	end
end
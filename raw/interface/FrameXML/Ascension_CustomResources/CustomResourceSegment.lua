CustomResourceSegmentMixin = {}

function CustomResourceSegmentMixin:SetActiveAtlas(atlas, useAtlasSize)
	self.activeAtlas = atlas
	self.activeUseAtlasSize = useAtlasSize
	self.activeTexture = nil

	if self:IsShown() then
		self:Activate()
	end
end

function CustomResourceSegmentMixin:SetInactiveAtlas(atlas, useAtlasSize)
	self.inactiveAtlas = atlas
	self.inactiveUseAtlasSize = useAtlasSize
	self.inactiveTexture = nil

	if self:IsShown() then
		self:Deactivate()
	end
end

function CustomResourceSegmentMixin:SetActiveTexture(texture)
	self.activeTexture = texture
	self.activeUseAtlasSize = nil
	self.activeAtlas = nil

	if self:IsShown() then
		self:Activate()
	end
end

function CustomResourceSegmentMixin:SetInactiveTexture(texture)
	self.inactiveTexture = texture
	self.inactiveUseAtlasSize = nil
	self.inactiveAtlas = nil

	if self:IsShown() then
		self:Deactivate()
	end
end

function CustomResourceSegmentMixin:Activate()
	if self.isActive then return end
	self.isActive = true
	if self.activeAtlas then
		self.Icon:SetAtlas(self.activeAtlas, self.activeUseAtlasSize)
		if self.activeUseAtlasSize then
			self:SetSize(self.Icon:GetWidth(), self.Icon:GetHeight())
		end
	elseif self.activeTexture then
		self.Icon:SetTexCoord(0, 1, 0, 1)
		self.Icon:SetTexture(self.activeTexture)
	else
		self.Icon:SetTexture(nil)
		self.Icon:SetTexCoord(0, 1, 0, 1)
	end
end

function CustomResourceSegmentMixin:Deactivate()
	if not self.isActive then return end
	self.isActive = false
	if self.inactiveAtlas then
		self.Icon:SetAtlas(self.inactiveAtlas, self.inactiveUseAtlasSize)
		if self.inactiveUseAtlasSize then
			self:SetSize(self.Icon:GetWidth(), self.Icon:GetHeight())
		end
	elseif self.inactiveTexture then
		self.Icon:SetTexCoord(0, 1, 0, 1)
		self.Icon:SetTexture(self.inactiveTexture)
	else
		self.Icon:SetTexture(nil)
		self.Icon:SetTexCoord(0, 1, 0, 1)
	end
end

function CustomResourceSegmentMixin:UpdateVisual(index, value)
	if value >= index then
		self:Activate()
	else
		self:Deactivate()
	end
end
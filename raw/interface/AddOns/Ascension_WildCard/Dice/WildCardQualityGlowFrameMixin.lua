-------------------------------------------------------------------------------
--                         Quality Glow texture mixin                        --
-------------------------------------------------------------------------------
WildCardQualityGlowPieceMixin = {}

function WildCardQualityGlowPieceMixin:OnLoad()
	self:Layout()

	self.show = self.Show
	function self:Show() 
		self:show() 
		self.Glow.Breathing:Play()
		self.Glow:Show() 
	end

	self.hide = self.Hide
	function self:Hide() 
		self:hide() 
		self.Glow.Breathing:Stop()
		self.Glow:Hide() 
	end
end

function WildCardQualityGlowPieceMixin:Layout()
	self.Glow = self:GetParent():CreateTexture("OVERLAY")
	self.Glow:SetAtlas("WildCardGlowElement1", Const.TextureKit.UseAtlasSize)
	self.Glow:SetPoint("CENTER")
	self.Glow:SetBlendMode("ADD")

	self.Glow.Breathing = self.Glow:CreateAnimationGroup(nil)
	self.Glow.Breathing:SetLooping("REPEAT")

	self.Glow.Breathing.Alpha = self.Glow.Breathing:CreateAnimation("ALPHA")
	self.Glow.Breathing.Alpha:SetDuration(1.5)
	self.Glow.Breathing.Alpha:SetOrder(1)
	self.Glow.Breathing.Alpha:SetChange(-0.5)

	self.Glow.Breathing.Alpha2 = self.Glow.Breathing:CreateAnimation("ALPHA")
	self.Glow.Breathing.Alpha2:SetDuration(1.5)
	self.Glow.Breathing.Alpha2:SetOrder(2)
	self.Glow.Breathing.Alpha2:SetChange(0.5)

	self.Glow.Breathing:Play()
end

-------------------------------------------------------------------------------
--                        Quality Glow Advanced mixin                        --
-------------------------------------------------------------------------------
-- UNUSED. Advanced frame which allows to highlight each side of a dice via specific color
WildCardQualityGlowAdvancedMixin = {}
WildCardQualityGlowAdvancedMixin.MAX_TEXTURES = 5

WildCardQualityGlowAdvancedMixin.EnumGlowPieces = {
	[2] = {
		[2] = {"WildCardGlowPiece19", "WildCardGlowPiece28"},
		[4] = {"WildCardGlowPiece27", "WildCardGlowPiece33"},
		[5] = {"WildCardGlowPiece4", "WildCardGlowPiece41"},
		[3] = {"WildCardGlowPiece12", "WildCardGlowPiece49"},
		[1] = {"WildCardGlowPiece20", "WildCardGlowPiece57"},
	},
	[3] = {
		[2] = {"WildCardGlowPiece1", "WildCardGlowPiece10"},
		[4] = {"WildCardGlowPiece9", "WildCardGlowPiece18"},
		[5] = {"WildCardGlowPiece17", "WildCardGlowPiece26"},
		[3] = {"WildCardGlowPiece25", "WildCardGlowPiece3"},
		[1] = {"WildCardGlowPiece2", "WildCardGlowPiece11"},
	},
	[4] = {
		[2] = {"WildCardGlowPiece34", "WildCardGlowPiece43"},
		[4] = {"WildCardGlowPiece42", "WildCardGlowPiece51"},
		[5] = {"WildCardGlowPiece50", "WildCardGlowPiece59"},
		[3] = {"WildCardGlowPiece58", "WildCardGlowPiece44"},
		[1] = {"WildCardGlowPiece35", "WildCardGlowPiece52"},
	},
	[5] = {
		[2] = {"WildCardGlowPiece60", "WildCardGlowPiece6"},
		[4] = {"WildCardGlowPiece5", "WildCardGlowPiece14"},
		[5] = {"WildCardGlowPiece13", "WildCardGlowPiece22"},
		[3] = {"WildCardGlowPiece21", "WildCardGlowPiece30"},
		[1] = {"WildCardGlowPiece29", "WildCardGlowPiece7"},
	},
}
function WildCardQualityGlowAdvancedMixin:CalculateGlowForQuality(index, quality)
	return {WildCardQualityGlowAdvancedMixin.EnumGlowPieces[quality][index][1], WildCardQualityGlowAdvancedMixin.EnumGlowPieces[quality][index][2]}
end

function WildCardQualityGlowAdvancedMixin:OnLoad()
	self.textures = {}
	self:Layout()
	self:ReleaseAll()
end

function WildCardQualityGlowAdvancedMixin:SetQuality(quality, index)
	quality = quality or 1
	local color = ITEM_QUALITY_COLORS[quality]
	index = index or 1

	if not(color) or (quality and (quality < 2)) then
		self:ReleaseIndex(index)
		return
	else
		if self.textures[index] then
			self.textures[index].Glow:SetAtlas(WildCardQualityGlowAdvancedMixin:CalculateGlowForQuality(index, quality)[1], Const.TextureKit.UseAtlasSize)
			self.textures[index]:SetAtlas(WildCardQualityGlowAdvancedMixin:CalculateGlowForQuality(index, quality)[2], Const.TextureKit.UseAtlasSize)
			self.textures[index]:Show()
		end
	end
end

function WildCardQualityGlowAdvancedMixin:ShowGlow(index)
	index = index or 1

	if self.textures[index] then
		self.textures[index]:Show()
	end
end

function WildCardQualityGlowAdvancedMixin:ReleaseIndex(index)
	index = index or 1

	if self.textures[index] then
		self.textures[index]:Hide()
	end
end

function WildCardQualityGlowAdvancedMixin:ReleaseAll()
	for _, texture in pairs(self.textures) do
		texture:Hide()
	end
end

function WildCardQualityGlowAdvancedMixin:Layout()
	for i = 1, self.MAX_TEXTURES do
		local texture = self:CreateTexture("ARTWORK")
		texture:SetPoint("CENTER")
		MixinAndLoad(texture, WildCardQualityGlowPieceMixin)
		table.insert(self.textures, texture)
	end
end

-------------------------------------------------------------------------------
--                          Quality Glow Frame mixin                         --
-------------------------------------------------------------------------------
WildCardQualityGlowMixin = CreateFromMixins(WildCardQualityGlowAdvancedMixin)

WildCardQualityGlowMixin.GlowQualityEnum = {
	[2] = "WildCardGlowElement4",
	[3] = "WildCardGlowElement7",
	[4] = "WildCardGlowElement2",
	[5] = "WildCardGlowElement5",
}

WildCardQualityGlowMixin.TexQualityEnum = {
	[2] = "WildCardGlowElement6",
	[3] = "WildCardGlowElement1",
	[4] = "WildCardGlowElement9",
	[5] = "WildCardGlowElement3",
}

function WildCardQualityGlowMixin:OnLoad()
	self.MAX_TEXTURES = 1
	WildCardQualityGlowAdvancedMixin.OnLoad(self)
end

function WildCardQualityGlowMixin:SetQuality(quality)
	local color = ITEM_QUALITY_COLORS[quality]

	if not(color) or (quality and (quality < 2)) then
		self:ReleaseAll()
		return
	else
		self.textures[1].Glow:SetAtlas(WildCardQualityGlowMixin.GlowQualityEnum[quality], Const.TextureKit.UseAtlasSize)
		self.textures[1]:SetAtlas(WildCardQualityGlowMixin.TexQualityEnum[quality], Const.TextureKit.UseAtlasSize)
		self.textures[1]:Show()
	end
end
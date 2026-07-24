DraftCardNameMixin = {}

function DraftCardNameMixin:OnLoad()
	self.Background:SetAtlas("draft-card-name-background", Const.TextureKit.UseAtlasSize)
end

function DraftCardNameMixin:UpdateTextSize()
	local fontString = self:GetFontString()
	local height = fontString:GetStringHeight()
	local _, fontHeight = fontString:GetFont()
	if height > fontHeight then
		if self:GetNormalFontObject() ~= "GameFontNormalLarge" then
			self:SetNormalFontObject("GameFontNormalLarge")
		end
	else
		if self:GetNormalFontObject() ~= "GameFontNormalHuge" then
			self:SetNormalFontObject("GameFontNormalHuge")
		end
	end
end
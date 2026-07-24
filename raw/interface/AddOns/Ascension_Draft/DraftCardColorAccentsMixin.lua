DraftCardColorAccentsMixin = {}

DraftCardColorAccentsMixin.SpellGlowType = {
	Ability = 1,
	Talent = 2,
}

function DraftCardColorAccentsMixin:OnLoad()
	self.Artwork:SetAtlas("draft-card-colored-artwork", Const.TextureKit.UseAtlasSize)
	self.Artwork2:SetAtlas("draft-card-colored-artwork2", Const.TextureKit.UseAtlasSize)
	self.IconBorder:SetAtlas("draft-card-colored-icon-border", Const.TextureKit.UseAtlasSize)
	self.IconBorder2:SetAtlas("draft-card-colored-icon-border", Const.TextureKit.UseAtlasSize)
	self.AbilityGlow:SetAtlas("draft-card-colored-ability-glow", Const.TextureKit.UseAtlasSize)
	self.AbilityGlow2:SetAtlas("draft-card-colored-ability-glow", Const.TextureKit.UseAtlasSize)
	self.TalentGlow:SetAtlas("draft-card-colored-talent-glow", Const.TextureKit.UseAtlasSize)
	self.TalentGlow2:SetAtlas("draft-card-colored-talent-glow", Const.TextureKit.UseAtlasSize)
end

function DraftCardColorAccentsMixin:GetColoredElements()
	return {
		self.Artwork,
	    self.Artwork2,
	    self.IconBorder,
	    self.IconBorder2,
	    self.AbilityGlow,
	    self.AbilityGlow2,
	    self.TalentGlow,
	    self.TalentGlow2
	}
end

function DraftCardColorAccentsMixin:SetSpellGlowType(glowType)
	self.GlowType = glowType
	if glowType == DraftCardColorAccentsMixin.SpellGlowType.Ability then
		self.AbilityGlow:Show()
		self.AbilityGlow2:Show()
		self.TalentGlow:Hide()
		self.TalentGlow2:Hide()
	elseif glowType == DraftCardColorAccentsMixin.SpellGlowType.Talent then
		self.AbilityGlow:Hide()
		self.AbilityGlow2:Hide()
		self.TalentGlow:Show()
		self.TalentGlow2:Show()
	end
end 
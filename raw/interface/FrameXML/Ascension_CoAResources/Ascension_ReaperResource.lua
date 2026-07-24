if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "REAPER" then return end

local fillers = {
	"ReaperSoul1Shard",
	"ReaperSoul2Shards",
}

--
-- Controller
--
ClassMixinReaper = {}

function ClassMixinReaper:OnLoad()
	MixinAndLoad(CoAResourceSegmentBar, CoAResourceSegmentBarMixinReaper)
	CoAResourceSegmentBar:ShowTemplate("ReaperSoul", 0, 3, 500363)
end

function ClassMixinReaper:OnPlayerAura()

	if not CoAResourceSegmentBar.SetShards then
		return
	end
	
	local stacks = select(4, AuraUtil.GetBuff("player", 500363, true, AuraUtil.Predicate.MatchesSpellID))
	local stacksShards = select(4, AuraUtil.GetBuff("player", 805077, true, AuraUtil.Predicate.MatchesSpellID))

	local isSoulInfused = select(4, AuraUtil.GetBuff("player", 803031, true, AuraUtil.Predicate.MatchesSpellID))
	
	CoAResourceSegmentBar:SetSoulInfused(isSoulInfused and true or false)
	CoAResourceSegmentBar:SetShards(stacksShards or 0)
	CoAResourceSegmentBar:SetValue(stacks or 0)
end
--
-- Segment Bar
--
CoAResourceSegmentBarMixinReaper = {}

function CoAResourceSegmentBarMixinReaper:OnLoad()
	self:Layout()
	self.InfusedFlipbook:Init()
	self.InfusedFlipbook.fps = 0.01
end

function CoAResourceSegmentBarMixinReaper:SetShards(value)
	self.shards = value
end

function CoAResourceSegmentBarMixinReaper:GetShards(value)
	return self.shards or 0
end

function CoAResourceSegmentBarMixinReaper:Update()
	CoAResourceSegmentBarMixin.Update(self)
	self:SetWidth(162)

	local elementSize = self.template.ElementSize

	if self.segments[1] then
		self.segments[1]:ClearAndSetPoint("CENTER", -(elementSize/2)*(self.maxValue-1)-4, 0)
	end

	-- handle infused state
	for i = 1, self.maxValue do
		local segment

		if self.segments[i] then
			segment = self.segments[i]
		end

		if segment then
			if self:IsSoulInfused() then
				segment.Fill:SetAtlas("ReaperSoulInfused", Const.TextureKit.UseAtlasSize)
			else
				segment.Fill:SetAtlas("ReaperSoulFull", Const.TextureKit.UseAtlasSize)
			end
		end
	end

	if self:IsSoulInfused() then
		self.GlowBG:Show()
		self.InfusedFlipbook:Show()
		self:SetScript("OnUpdate", self.OnUpdateAtlas)
	else
		self.GlowBG:Hide()
		self.InfusedFlipbook:Hide()
		self:SetScript("OnUpdate", nil)
	end

	-- handle "shards" logic
	-- get next free soul
	if self:GetShards() == 0 then
		return
	end

	local nextSoul = self.segments[self.value + 1]

	if not(nextSoul) then
		return
	end

	nextSoul.Background:SetAtlas(fillers[self:GetShards()] or "ReaperSoul1Shard", Const.TextureKit.UseAtlasSize)
end

function CoAResourceSegmentBarMixinReaper:OnUpdateAtlas(elapsed)
	AtlasVerticalFlipbookMixin.Update(self.InfusedFlipbook, elapsed)

	if self.InfusedFlipbook.frame > self.InfusedFlipbook.frames then
		self.InfusedFlipbook.frame = 1
	end
end

function CoAResourceSegmentBarMixinReaper:IsSoulInfused()
	return self.isSoulInfused
end

function CoAResourceSegmentBarMixinReaper:SetSoulInfused(value)
	self.isSoulInfused = value
end

function CoAResourceSegmentBarMixinReaper:Layout()
	self.GlowBG = self:CreateTexture(nil, "Background")
	self.GlowBG:SetPoint("CENTER", 0, 0)
	self.GlowBG:SetAtlas("ReaperGlowBG", Const.TextureKit.UseAtlasSize)
	self.GlowBG:Hide()

	self.Bg:SetPoint("CENTER", 0, -8)
	self.Bg:SetDrawLayer("BORDER")

	self.InfusedFlipbook = self:CreateTexture(nil, "OVERLAY")
	self.InfusedFlipbook:SetSize(174*0.9, 174*0.8)
	self.InfusedFlipbook:SetPoint("CENTER", 0, -3)
	self.InfusedFlipbook:SetAtlas("ReaperInfusedFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.InfusedFlipbook, "ReaperInfusedFlipBook", 256, 256, 64, 60, false)
	self.InfusedFlipbook:SetDrawLayer("OVERLAY")
	self.InfusedFlipbook:SetBlendMode("ADD")
	self.InfusedFlipbook:Hide()
	MixinAndLoad(self.InfusedFlipbook, AtlasVerticalFlipbookMixin)
end
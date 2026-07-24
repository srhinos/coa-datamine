if not IsCustomClass() then return end

local class = C_Player:GetClass()

if class ~= "NECROMANCER" then return end

CoANecromancerMultiCastMixin = {}

function CoANecromancerMultiCastMixin:OnLoad()
	CoAResourceOrb:SetParent(self)
	self.ResourceBar = CoAResourceOrb
	self.ResourceBar.maxOverlayFrames = 48

	self:Layout()

	self.ResourceBar.ResourceFlipBook:Init()
	self.ResourceBar.ResourceFlipBook.fps = 0.05
	self.ResourceBar.ResourceOverlayFlipBook:Init()

	self.ResourceBar:SetSpellID(805011) -- TODO: to constants
	self.ResourceBar:RegisterForClicks("AnyUp")

	self:RegisterCallback("OnButtonsUpdated", function(self)
		local width = self.ResourceBar:GetWidth()+4

		if self.Buttons[1] then
			self.Buttons[1]:ClearAndSetPoint("LEFT", self.ResourceBar, "RIGHT", 12, -5)

			width = width + 38*(#self.Buttons)

			for i = 1, #self.Buttons do
				local button = self.Buttons[i]
				if not(button.Separator) then
					self:LayoutButtonNecromancer(button)
				end
			end
		end

		width = width

		self:SetWidth(width)
	end, self)

	self:RegisterCallback("OnSetShowText", function(self, show)
		self.ResourceBar.Text:SetDrawLayer(show and "OVERLAY" or "HIGHLIGHT")
	end, self)

	self:RegisterCallback("OnSetLocked", function(self, locked)
		if locked then
			self.ResourceBar:RegisterForDrag()
		else
			self.ResourceBar:RegisterForDrag("LeftButton")
		end
	end, self)

	self:RegisterCallback("OnResourceUpdated", function(self, progress, value, maxValue)
		self.ResourceBar:SetProgress(progress, value, maxValue)
	end, self)

	self.ResourceBar:SetScript("OnEnter", function()
		CoAMultiCastFlyoutButtonMixin.OnEnter(self.ResourceBar)
		GameTooltip:AddLine(COA_RESOURCE_CUSTOMIZE_HELPER, 0, 0.8, 1, true)
		GameTooltip:Show()
	end)

	self.ResourceBar:SetScript("OnClick", function(_, button)
		self:OnMouseUp(button)
	end)

	self.ResourceBar:RegisterForDrag("LeftButton")

	self.ResourceBar:SetScript("OnDragStart", function()
		self:StartMoving()
	end)

	self.ResourceBar:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		self:SavePosition()
	end)

	self:LoadCVars()
end

function CoANecromancerMultiCastMixin:LayoutButtonNecromancer(button) -- TODO: Replace via XML changable templates
	button.NormalTexture:SetVertexColor(0, 1, 1)

	button.Separator = button:CreateTexture(nil, "BACKGROUND")
	button.Separator:SetPoint("LEFT", -14, 0)
	button.Separator:SetAtlas("NecroBarDivider", Const.TextureKit.IgnoreAtlasSize)
	button.Separator:SetSize(19.2, 40.8)
end

function CoANecromancerMultiCastMixin:Layout()
	self:SetWidth(216)
	self:SetHeight(48)

	self.FlyoutFrame.middle:SetAtlas("TotemBarGreyBGMiddle", Const.TextureKit.IgnoreAtlasSize)
	self.FlyoutFrame.top:SetAtlas("TotemBarGreyBGTop", Const.TextureKit.IgnoreAtlasSize)
	self.FlyoutFrame.CloseButton.NormalTexture:SetAtlas("TotemBarGreyButtonDown", Const.TextureKit.IgnoreAtlasSize)
	self.FlyoutFrameOpenButton.normalTexture:SetAtlas("TotemBarGreyButtonUp", Const.TextureKit.IgnoreAtlasSize)

	self.BgLeft = self:CreateTexture(nil, "BACKGROUND")
	self.BgLeft:SetAtlas("NecroBarLeft", Const.TextureKit.IgnoreAtlasSize)
	self.BgLeft:SetSize(25.2, 54.6)
	self.BgLeft:SetPoint("LEFT", 0, 0)

	self.BgRight = self:CreateTexture(nil, "BACKGROUND")
	self.BgRight:SetAtlas("NecroBarRight", Const.TextureKit.IgnoreAtlasSize)
	self.BgRight:SetSize(25.2, 54.6)
	self.BgRight:SetPoint("RIGHT", 0, 0)

	self.BgMiddle = self:CreateTexture(nil, "BACKGROUND")
	self.BgMiddle:SetAtlas("NecroBarMiddle", Const.TextureKit.IgnoreAtlasSize)
	self.BgMiddle:SetPoint("TOPLEFT", self.BgLeft, "TOPRIGHT", 0, 0)
	self.BgMiddle:SetPoint("BOTTOMRIGHT", self.BgRight, "BOTTOMLEFT", 0, 0)

	self.ResourceBar:ClearAndSetPoint("LEFT", 0, 6)
	self.ResourceBar:SetFrameLevel(self:GetFrameLevel()+10)
	self.ResourceBar:Show()
	self.ResourceBar:SetScale(0.8)

	self.ResourceBar.ResourceFlipBook:ClearAllPoints()
	self.ResourceBar.ResourceFlipBook:SetSize(56, 56)
	self.ResourceBar.ResourceFlipBook:SetPoint("CENTER", 0, 0)
	self.ResourceBar.ResourceFlipBook:SetAtlas("NecroResourceFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceBar.ResourceFlipBook, "NecroResourceFlipBook", 128, 128, 64, 60, false)
	
	self.ResourceBar.ResourceOverlayFlipBook:ClearAllPoints()
	self.ResourceBar.ResourceOverlayFlipBook:SetSize(54, 54)
	self.ResourceBar.ResourceOverlayFlipBook:SetPoint("CENTER", -1, 0)
	self.ResourceBar.ResourceOverlayFlipBook:SetAtlas("NecroResourceOverlayFlipBook", Const.TextureKit.IgnoreAtlasSize)
	C_Flipbook:CreateAtlasFlipbook(self.ResourceBar.ResourceOverlayFlipBook, "NecroResourceOverlayFlipBook", 128, 128, self.ResourceBar.maxOverlayFrames, 60, false)

	self.ResourceBar.ArtWork:ClearAllPoints()
	self.ResourceBar.ArtWork:SetPoint("CENTER", -9, -9)
	self.ResourceBar.ArtWork:SetAtlas("NecroResourceArtwork", Const.TextureKit.UseAtlasSize)
	self.ResourceBar.ArtWork:SetSize(89, 89)

	self.ResourceBar.Text:SetFontObject(TextStatusBarTextLarge)
end

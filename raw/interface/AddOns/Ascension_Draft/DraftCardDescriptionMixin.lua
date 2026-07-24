DraftCardDescriptionMixin = {}

function DraftCardDescriptionMixin:OnLoad()
	self.scrollBarHideable = true
	UseParentLevel(self.TextFrame)
	ScrollFrame_OnLoad(self)
end

function DraftCardDescriptionMixin:OnMouseWheel(...)
	ScrollFrameTemplate_OnMouseWheel(self, ...)
end

function DraftCardDescriptionMixin:OnVerticalScroll(offset)
	local scrollbar = self.ScrollBar
	scrollbar:SetValue(offset)
	local _, max = scrollbar:GetMinMaxValues()

	if offset == 0 then
		_G[scrollbar:GetName().."ScrollUpButton"]:Disable()
	else
		_G[scrollbar:GetName().."ScrollUpButton"]:Enable()
	end

	if (scrollbar:GetValue() - max) == 0 then
		_G[scrollbar:GetName().."ScrollDownButton"]:Disable()
	else
		_G[scrollbar:GetName().."ScrollDownButton"]:Enable()
	end
end

function DraftCardDescriptionMixin:OnSizeChanged(width, height)
	local yRange = self.TextFrame.Text:GetStringHeight() - self:GetHeight()
	yRange = MClamp(yRange, 0, yRange)
	if math.floor(yRange) > 0 then
		self.TextFrame.Text:SetWidth(width - 24)
		self.TextFrame:SetWidth(width - 24)
		yRange = self.TextFrame.Text:GetStringHeight() - self:GetHeight()
	else
		self.TextFrame:SetWidth(width)
		self.TextFrame.Text:SetWidth(width)
	end
	ScrollFrame_OnScrollRangeChanged(self, nil, yRange)
end

function DraftCardDescriptionMixin:SetText(text)
	self.TextFrame.Text:SetText(text)
	local yRange = self.TextFrame.Text:GetStringHeight() - self:GetHeight()
	yRange = MClamp(yRange, 0, yRange)
	if math.floor(yRange) > 0 then
		local width = self:GetWidth()
		self.TextFrame.Text:SetWidth(width - 24)
		self.TextFrame:SetWidth(width - 24)
		yRange = self.TextFrame.Text:GetStringHeight() - self:GetHeight()
	end
	ScrollFrame_OnScrollRangeChanged(self, nil, yRange)
	self.ScrollBar:SetValue(0)
end

function DraftCardDescriptionMixin:SetArtwork(style)
	if style == DraftCardMixin.ArtworkStyle.Metal then
		self.Background:SetPoint("CENTER", 0, 13)
		self.Background:SetAtlas("draft-card-description-metal-background", Const.TextureKit.UseAtlasSize)
		self.ScrollBar.Background:SetAtlas("draft-card-description-metal-scrollbar-background", Const.TextureKit.UseAtlasSize)
	elseif style == DraftCardMixin.ArtworkStyle.Paper then
		self.Background:SetPoint("CENTER", 0, 4)
		self.Background:SetAtlas("draft-card-description-paper-background", Const.TextureKit.UseAtlasSize)
		self.ScrollBar.Background:SetAtlas("draft-card-description-paper-scrollbar-background", Const.TextureKit.UseAtlasSize)
	end
end
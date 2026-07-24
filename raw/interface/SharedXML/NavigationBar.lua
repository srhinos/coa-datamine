NavButtonMixin = {}

function NavButtonMixin:OnLoad()
	self.xoffset = 4
	self:SetNormalAtlas("navmenu-button")
	self:SetPushedAtlas("navmenu-button-pushed")
	self:SetHighlightAtlas("help-button-highlight")
	self.Selected:SetAtlas("help-button-selected", Const.TextureKit.IgnoreAtlasSize)
	self.ArrowUp:SetAtlas("navmenu-arrow", Const.TextureKit.IgnoreAtlasSize)
	self.ArrowDown:SetAtlas("navmenu-arrow-pushed", Const.TextureKit.IgnoreAtlasSize)
end 

function NavButtonMixin:OnMouseDown()
	if self:IsEnabled() then
		self.ArrowUp:Hide()
		self.ArrowDown:Show()
	end
end

function NavButtonMixin:OnMouseUp()
	self.ArrowDown:Hide()
	self.ArrowUp:Show()
end

function NavButtonMixin:OnEnable()
	self.ArrowDown:Hide()
	self.ArrowUp:Show()
end

function NavButtonMixin:OnDisable()
	self.ArrowDown:Hide()
	self.ArrowUp:Show()
end

function NavButtonMixin:PreClick()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON_50)
end 

function NavButtonMixin:OnClick()
	if self.data.click then
		self.data.click(self)
	end
end

function NavButtonMixin:SetLabel(text)
	self.Text:SetText(text)
	self:SetWidth(self.Text:GetStringWidth() + (self.data.list and 53 or 30))
end

function NavButtonMixin:ToggleDropDown()
	self:GetParent().DropDown.buttonOwner = self
	ToggleDropDownMenu(1, nil, self:GetParent().DropDown, self, 20, 3)
end

--
--  Navigation Bar Mixin
--
NavBarMixin = {}

function NavBarMixin:OnLoad()
	self.navButtonTemplate = "NavButtonTemplate"
	self.Background:SetAtlas("navmenu-background", Const.TextureKit.IgnoreAtlasSize)
	self.Overlay.Background:SetAtlas("navmenu-background-overlay", Const.TextureKit.IgnoreAtlasSize)
	self.OverflowButton:SetNormalAtlas("navmenu-overflow")
	self.OverflowButton:SetPushedAtlas("navmenu-overflow-pushed")
	self.OverflowButton:SetHighlightAtlas("navmenu-overflow")
	self.HomeButton:SetNormalAtlas("navmenu-home")
	self.HomeButton:SetPushedAtlas("navmenu-home-pushed")
	self.HomeButton:SetHighlightAtlas("navmenu-home-highlight")
end 

function NavBarMixin:SetNavButtonTemplate(template)
	self.navButtonTemplate = template
end

function NavBarMixin:SetHomeCallback(callback)
	self.homeCallback = callback
end

function NavBarMixin:SetHomeText(text)
	self.HomeButton.Text:SetText(text)
	self:ResizeHomeButton()
end

function NavBarMixin:ResizeHomeButton()
	local newWidth = min(128, self.HomeButton.Text:GetStringWidth()+50)
	local texCoordoffsetX = (newWidth/128)*0.25

	local right, top, bottom = select(5, AtlasUtil:Unpack("navmenu-home"))
	self.HomeButton:GetNormalTexture():SetTexCoord(right-texCoordoffsetX, right, top, bottom)
	right, top, bottom = select(5, AtlasUtil:Unpack("navmenu-home-pushed"))
	self.HomeButton:GetPushedTexture():SetTexCoord(right-texCoordoffsetX, right, top, bottom)
	right, top, bottom = select(5, AtlasUtil:Unpack("navmenu-home-highlight"))
	self.HomeButton:GetHighlightTexture():SetTexCoord(right-texCoordoffsetX, right, top, bottom)

	self.HomeButton:SetWidth(newWidth)
end

function NavBarMixin:InitializeDropDown(dropdown, level)
	local navButton = dropdown.buttonOwner
	if not navButton or not navButton.data.list then
		return
	end

	for _, entry in ipairs(navButton.data.list) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = entry.func
		info.owner = navButton
		info.notCheckable = true
		info.text = entry.text
		UIDropDownMenu_AddButton(info, level)
	end
end

function NavBarMixin:AddButton(buttonData)
	if not self.buttonPool then
		self.buttonPool = CreateFramePool("BUTTON", self, self.navButtonTemplate)
	end
	
	local button = self.buttonPool:Acquire()
	button.data = buttonData

	if not self.lastButton then
		self.lastButton = self.HomeButton
	end

	if self.lastButton.Selected then
		self.lastButton.Selected:Hide()
	end

	if button.Selected then
		button.Selected:Show()
	end
	
	button.parent = self.lastButton

	if buttonData.list then
		if not self.DropDown then
			self.DropDown = CreateFrame("Frame", "$parentDropDown", self, "UIDropDownMenuTemplate")
			UIDropDownMenu_Initialize(self.DropDown, GenerateClosure(self.InitializeDropDown, self), "MENU")
		end
		button.MenuArrowButton:Show()
	else
		button.MenuArrowButton:Hide()
	end
	
	button:SetLabel(buttonData.label)
	button:SetPoint("LEFT", self.lastButton, "RIGHT", self.lastButton.xoffset or 0, 0)
	
	local parent = button.parent
	local level = self:GetFrameLevel() + 1
	button:SetFrameLevel(level)
	while parent do
		level = level + 1
		parent:SetFrameLevel(level)
		parent = parent.parent
	end
	button:Show()
	self.lastButton = button
end 

function NavBarMixin:Clear()
	if self.buttonPool then
		self.buttonPool:ReleaseAll()
	end
	self.lastButton = self.HomeButton
end 
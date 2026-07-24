HelpMenuPanelMixin = {}

local function ResetUseItem(pool, item)
	FramePool_HideAndClearAnchors(pool, item)
	item:SetItem()
end

local function ResetButton(pool, button)
	FramePool_HideAndClearAnchors(pool, button)
	button.func = nil
	button:SetEnabledFunction()
	button:Enable()
end

local function ResetDoubleButton(pool, frame)
	FramePool_HideAndClearAnchors(pool, frame)
	frame.LeftButton.func = nil
	frame.LeftButton:SetEnabledFunction()
	frame.LeftButton:Enable()

	frame.RightButton.func = nil
	frame.RightButton:SetEnabledFunction()
	frame.RightButton:Enable()
end

local function ResetEditBox(pool, editBox)
	FramePool_HideAndClearAnchors(pool, editBox)
	editBox.Text:SetText("")
	editBox.Text:SetMaxLetters(0)
end

HelpMenuPanelMixin.Element = {
	Text = { frameType = "Frame", template = "HelpMenuTextElementTemplate" },
	Caption = { frameType = "Frame", template = "HelpMenuCaptionElementTemplate" },
	UseItem = { frameType = "Button", template = "HelpMenuUseItemElementTemplate", reset = ResetUseItem },
	Button = { frameType = "Button", template = "HelpMenuButtonElementTemplate", reset = ResetButton },
	DoubleButton = { frameType = "Frame", template = "HelpMenuDoubleButtonElementTemplate", reset = ResetDoubleButton },
	EditBox = { frameType = "ScrollFrame", template = "HelpMenuEditBoxElementTemplate", reset = ResetEditBox },
	ReadOnly = { frameType = "ScrollFrame", template = "HelpMenuReadOnlyElementTemplate", reset = ResetEditBox },
}

local PanelPool = CreateFramePoolCollection()

function HelpMenuPanelMixin:OnLoad()
	self.topPadding = 24
	self.elements = {}
	self.ScrollChild = self:GetParent()
	self.Pools = PanelPool
	self.Pools:SetResetDisallowedIfNew(true)
end

function HelpMenuPanelMixin:UpdateScrollSize()
	local height = self:GetHeight()
	self.ScrollChild:SetHeight(height)
end

function HelpMenuPanelMixin:SetGeneratorFunction(func)
	self.generatorFunction = func
end

function HelpMenuPanelMixin:RegenerateLayout()
	if not self:IsShown() then
		return
	end
	self.Pools:ReleaseAll()
	wipe(self.elements)
	self.ScrollChild:GetParent().ScrollBar:SetValue(0)
	if self.generatorFunction then
		tinsert(self.elements, self.topPadding)
		self.generatorFunction(self)
	end
	self:UpdateHeight()
end

function HelpMenuPanelMixin:OnHide()
	self.Pools:ReleaseAll()
	wipe(self.elements)
end

function HelpMenuPanelMixin:AddElement(elementType)
	local pool = self.Pools:GetOrCreatePool(elementType.frameType, self, elementType.template, elementType.reset)
	local frame = pool:Acquire()
	frame:SetParent(self)
	frame:SetFrameLevel(self:GetFrameLevel()+1)
	frame:SetPoint("TOP", self, "TOP", 0, 0)
	tinsert(self.elements, frame)
	frame:Show()
	return frame
end

function HelpMenuPanelMixin:AddSpacer(height)
	tinsert(self.elements, height)
end

function HelpMenuPanelMixin:UpdateHeight()
	local height = 0
	for _, element in ipairs(self.elements) do
		if type(element) == "number" then
			height = height + element
		else
			element:SetPoint("TOP", self, "TOP", 0, -height)
			height = height + element:UpdateHeight()
		end
	end

	if height <= 0 then
		height = 1
	end

	self:SetHeight(height)
	self.ScrollChild:SetHeight(height)
end

HelpMenuElementMixin = {}

function HelpMenuElementMixin:OnLoad()
	self.heightElements = {}
	self.padding = 0
end

function HelpMenuElementMixin:SetPadding(padding)
	self.padding = padding
end

function HelpMenuElementMixin:UpdateHeight()
	local height = self.padding
	for _, element in ipairs(self.heightElements) do
		height = height + element:GetHeight()
	end

	if height > 0 then
		self:SetHeight(height)
	end
	
	return self:GetHeight()
end

function HelpMenuElementMixin:AddHeightElement(element)
	tinsert(self.heightElements, element)
end

HelpMenuTextElementMixin = CreateFromMixins(HelpMenuElementMixin)

function HelpMenuTextElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	self:AddHeightElement(self.Text)
end

function HelpMenuTextElementMixin:SetText(text, fontObject, justifyH, justifyV, r, g, b)
	self.Text:SetText(text)
	self.Text:SetFontObject(fontObject or "PTFontHighlight2")
	self.Text:SetJustifyH(justifyH or "CENTER")
	self.Text:SetJustifyV(justifyV or "TOP")
	self.Text:SetTextColor(r or 1, g or 1, b or 1)
end

HelpMenuCaptionElementMixin = CreateFromMixins(HelpMenuElementMixin)

function HelpMenuCaptionElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	self:AddHeightElement(self.Text)
	self:AddHeightElement(self.Image)
	self:SetPadding(4)
end

function HelpMenuCaptionElementMixin:SetCaption(text, fontObject, justifyH, justifyV, r, g, b)
	self.Text:SetText(text)
	self.Text:SetFontObject(fontObject or "PTFontHighlight")
	self.Text:SetJustifyH(justifyH or "CENTER")
	self.Text:SetJustifyV(justifyV or "TOP")
	self.Text:SetTextColor(r or 1, g or 1, b or 1)
end

function HelpMenuCaptionElementMixin:SetImageAtlas(atlas, useAtlasSize)
	self.Image:SetAtlas(atlas, useAtlasSize)
end

function HelpMenuCaptionElementMixin:SetImage(image)
	self.Image:SetTexCoord(0, 1, 0, 1)
	self.Image:SetTexture(image)
end

function HelpMenuCaptionElementMixin:SetImageSize(width, height)
	self.Image:SetSize(width, height)
end

HelpMenuUseItemElementMixin = CreateFromMixins(HelpMenuElementMixin, CooldownItemIconTemplateMixin)

function HelpMenuUseItemElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	CooldownItemIconTemplateMixin.OnLoad(self)
	self:AddHeightElement(self.Icon)
	self:RegisterCallback("OnItemChanged", self.OnItemChanged, self)
end

function HelpMenuUseItemElementMixin:OnItemChanged(item)
	self.hasItem = GetItemCount(item:GetItemID()) > 0
	local label = item:GetLink()
	if not self.hasItem then
		label = label .. "\n" .. TOOLTIP_ITEM_NOT_IN_BAG
	end
	self.Text:SetText(label)
	self.Icon:SetDesaturated(not hasItem)
end

function HelpMenuUseItemElementMixin:OnClickHandler()
	if self.item and self.hasItem then
		UseItemByName(self.item:GetName())
		HideUIPanel(HelpMenuFrame)
	end
end

HelpMenuButtonElementMixin = CreateFromMixins(HelpMenuElementMixin)

function HelpMenuButtonElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	self:SetNormalAtlas("helpbutton")
	self:SetDisabledAtlas("helpbutton")
	self:GetDisabledTexture():SetDesaturated(true)
	self:SetPushedAtlas("helpbutton-pushed")
	self:SetHighlightAtlas("helpbutton-highlight")
end 

function HelpMenuButtonElementMixin:SetIconAtlas(iconAtlas)
	self.Icon:SetAtlas(iconAtlas, Const.TextureKit.UseAtlasSize)
end

function HelpMenuButtonElementMixin:SetFunction(func)
	self.func = func
end

function HelpMenuButtonElementMixin:OnClick()
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
	if self.func then
		self:func()
	end
end

function HelpMenuButtonElementMixin:UpdateEnabled()
	self:SetEnabled(not self.enabledFunc or self:enabledFunc())
end

function HelpMenuButtonElementMixin:SetEnabledFunction(func)
	self.enabledFunc = func
	if self.enabledFunc then
		self:SetScript("OnUpdate", self.UpdateEnabled)
	else
		self:SetScript("OnUpdate", nil)
	end
end

function HelpMenuButtonElementMixin:OnEnable()
	self.Icon:SetDesaturated(false)
end

function HelpMenuButtonElementMixin:OnDisable()
	self.Icon:SetDesaturated(true)
end

HelpMenuDoubleButtonElementMixin = CreateFromMixins(HelpMenuElementMixin)

function HelpMenuDoubleButtonElementMixin:GetLeftButton()
	return self.LeftButton
end

function HelpMenuDoubleButtonElementMixin:GetRightButton()
	return self.RightButton
end

HelpMenuEditBoxElementMixin = CreateFromMixins(HelpMenuElementMixin, BasicSharedScrollMixin)

function HelpMenuEditBoxElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	BasicSharedScrollMixin.OnLoad(self)
end

function HelpMenuEditBoxElementMixin:SetInstruction(instruction)
	self.Text.Instructions:SetText(instruction)
end

function HelpMenuEditBoxElementMixin:GetText()
	return self.Text:GetText()
end

function HelpMenuEditBoxElementMixin:SetText(text)
	return self.Text:SetText(text)
end

function HelpMenuEditBoxElementMixin:SetMaxLetters(letters)
	self.Text:SetMaxLetters(letters)
end


HelpMenuReadOnlyElementMixin = CreateFromMixins(HelpMenuElementMixin, BasicSharedScrollMixin)

function HelpMenuReadOnlyElementMixin:OnLoad()
	HelpMenuElementMixin.OnLoad(self)
	BasicSharedScrollMixin.OnLoad(self)
end

function HelpMenuReadOnlyElementMixin:GetText()
	return self.Text:GetText()
end

function HelpMenuReadOnlyElementMixin:SetText(text)
	self.Text:SetText(text)
end 
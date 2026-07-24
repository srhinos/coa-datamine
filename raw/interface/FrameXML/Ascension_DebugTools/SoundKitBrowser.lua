SoundKitBrowserMixin = {}

function SoundKitBrowserMixin:OnLoad()
	self.portrait:SetPortraitTexture("Interface\\ICONS\\INV_Misc_ArmorKit_16")
	self:RegisterForDrag("LeftButton")
	self.TitleText:SetText("Sound Kit Player")

	self.Player.Copy:Disable()
	self.Player.Play:Disable()

	tinsert(UISpecialFrames, self:GetName())
	self.List = {}
	self.FilteredList = {}

	for kitName, ids in pairs(SOUNDKIT) do
		local count = 1
		if type(ids) == "table" then
			count = #ids
		end
		local sound = {
			name = kitName,
			soundIDs = ids,
			count = count,
		}
		
		tinsert(self.List, sound)
	end
	
	table.sort(self.List, function(a, b)
		return a.name < b.name
	end)
	
	local scroll = self.Browser.Scroll
	scroll.scrollBar.doNotHide = true
	HybridScrollFrame_OnLoad(scroll)
	scroll.update = function()
		self:UpdateScroll()
	end

	HybridScrollFrame_CreateButtons(scroll, "SoundKitButtonTemplate")
	self:UpdateScroll()
end

function SoundKitBrowserMixin:UpdateScroll()
	local scroll = self.Browser.Scroll
	local offset = HybridScrollFrame_GetOffset(scroll)
	local buttons = scroll.buttons
	local numButtons = #buttons
	local buttonHeight = buttons[1]:GetHeight()
	local list = self.Search:GetText() ~= "" and self.FilteredList or self.List

	for i = 1, numButtons do
		local button = buttons[i]
		local index = offset + i

		if index <= #list then
			local sound = list[index]

			button.sound = sound
			button.parent = self
			button:SetID(index)

			if self.selected == sound then
				button.SelectedTexture:Show()
				button.Text:SetFontObject("GameFontHighlightSmall")
			else
				button.SelectedTexture:Hide()
				button.Text:SetFontObject("GameFontNormalSmall")
			end

			button.Text:SetText(button.sound.name)
			button.SubText:SetText(format("%d |4ID:IDs;", button.sound.count))
			button:Show()
		else
			button:Hide()
		end
	end

	HybridScrollFrame_Update(scroll, #list * buttonHeight, scroll:GetHeight())
end

function SoundKitBrowserMixin:Play()
	if self.selected then
		PlaySound(SOUNDKIT[self.selected.name])
	end
end

function SoundKitBrowserMixin:Copy()
	if self.selected then
		Internal_CopyToClipboard(format("PlaySound(SOUNDKIT.%s)", self.selected.name))
		self.Player.Copy.Flash:Play()
	end
end

function SoundKitBrowserMixin:UpdateSearch()
	self.Browser.Scroll.scrollBar:SetValue(0)
	local text = self.Search:GetText()
	wipe(self.FilteredList)

	if text ~= "" then
		text = text:lower()
		
		text = text:SplitToTable(" ")

		for _, sound in ipairs(self.List) do
			local name = sound.name:lower()
			local found = true

			for _, part in ipairs(text) do
				if not name:find(part) then
					found = false
					break
				end
			end

			if found then
				tinsert(self.FilteredList, sound)
			end
		end
	end
	self:UpdateScroll()
end

function SoundKitBrowserMixin:Select(sound)
	self.selected = sound
	self:UpdateScroll()
	
	self.Player.Title:SetText(sound.name)
	self.Player.Count:SetText(format("%d |4ID:IDs;", sound.count))

	self.Player.Copy:Enable()
	self.Player.Play:Enable()
end

SLASH_SOUNDKIT1, SLASH_SOUNDKIT2 = "/soundkit", "/skit"

SlashCmdList["SOUNDKIT"] = function() SoundKitBrowser:Show() end

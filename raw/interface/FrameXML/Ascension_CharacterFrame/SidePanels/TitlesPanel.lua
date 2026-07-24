TitlesPanelMixin = CreateFromMixins(ScrollListMixin)

local function TitleSort(a, b)
	return a.name < b.name
end

function TitlesPanelMixin:OnLoad()
	self.titles = {}
	if ScrollListMixin.OnLoad then
		-- doesnt exist right now but future proof
		ScrollListMixin.OnLoad(self)
	end

	self:SetGetNumResultsFunction(function() return #self.titles end)
	self:SetTemplate("TitlesPanelItemTemplate")
	self:SetCanSelect(false)
	self.Background:SetAtlas(GetCharacterFrameSidePanelBackgroundAtlas("player", Const.TextureKit.IgnoreAtlasSize))
end

function TitlesPanelMixin:OnShow()
	self:RegisterEvent("KNOWN_TITLES_UPDATE")
	self:RegisterEvent("UNIT_NAME_UPDATE")
	RunNextFrame(function() self:RefreshScrollFrame() end)
end

function TitlesPanelMixin:OnHide()
	self:UnregisterEvent("KNOWN_TITLES_UPDATE")
	self:UnregisterEvent("UNIT_NAME_UPDATE")
end

function TitlesPanelMixin:OnEvent(event, ...)
	if event == "KNOWN_TITLES_UPDATE" then
		self:RefreshScrollFrame()
	elseif event == "UNIT_NAME_UPDATE" then
		local unit = ...
		if unit == "player" then
			self:RefreshScrollFrame()
		end
	end
end

function TitlesPanelMixin:GetTitleInfo(index)
	return self.titles[index]
end

function TitlesPanelMixin:RefreshScrollFrame()
	wipe(self.titles)
	local currentTitle = GetCurrentTitle()
	for i = 1, GetNumTitles() do
		if IsTitleKnown(i) ~= 0 then
			tinsert(self.titles, { name = GetTitleName(i), id = i, active = currentTitle == i })
		end
	end
	
	table.sort(self.titles, TitleSort)
	tinsert(self.titles, 1, { name = NONE, id = 0, active = currentTitle == 0 })
	ScrollListMixin.RefreshScrollFrame(self)
end

--
-- Title Item
--
TitlePanelItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function TitlePanelItemMixin:Init()
	ScrollListItemBaseMixin.Init(self)
	self:SetNormalAtlas("Garr_CostBar")
	self.Active:SetAtlas("GarrMission_LevelUpBanner", Const.TextureKit.IgnoreAtlasSize)
end

function TitlePanelItemMixin:Update()
	local info = self:GetScrollList():GetTitleInfo(self.index)
	self.info = info
	self:SetText(info.name)
	self.Active:SetShown(info.active)
end

function TitlePanelItemMixin:OnSelected()
	SetCurrentTitle(self.info.id)
	PlaySound(SOUNDKIT.CHAT_SCROLL_BUTTON)
end

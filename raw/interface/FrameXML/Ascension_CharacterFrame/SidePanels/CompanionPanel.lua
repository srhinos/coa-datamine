CompanionPanelMixin = CreateFromMixins(ScrollListMixin)

function CompanionPanelMixin:OnLoad()
	self.companionType = "CRITTER"
	self.companions = {}
	self:SetTemplate("PetPaperDollCompanionItemTemplate")
	self:GetSelectedHighlight():SetAtlas("PetList-ButtonSelect", Const.TextureKit.IgnoreAtlasSize)
	self:SetGetNumResultsFunction(function()
		return #self.companions
	end)
end

function CompanionPanelMixin:RefreshCompanionList()
	wipe(self.companions)
	local numCompanions = GetNumCompanions(self.companionType)
	
	local searchText = self.SearchBox:GetText():trim()
	for i = 1, numCompanions do
		local displayID, name, spellID, icon, isSummoned = GetCompanionInfo(self.companionType, i)
		if searchText == "" or name:lower():find(searchText:lower(), 1, true) then
			tinsert(self.companions, { index = i, displayID = displayID, name = name, spellID = spellID, icon = icon, isSummoned = isSummoned })
		end
	end
	-- table is already sorted alphabetically
end

function CompanionPanelMixin:UpdateCompanionList(companionType, updateSelection)
	self.companionType = companionType
	if updateSelection then
		self.SearchBox:SetText("")
	end
	self:RefreshCompanionList()

	if GetNumCompanions(self.companionType) == 0 then
		AscensionPetPaperDollPanel:ShowNoCompanionsScreen(self.companionType)
		AscensionPetPaperDollPanel.CompanionTab.CompanionModel:ClearModel()
		self:RefreshScrollFrame()
		self:SetSelectedIndex()
		return
	else
		AscensionPetPaperDollPanel:HideNoCompanionsScreen()
	end
	if updateSelection then
		self:SetSelectedIndex(1, ScrollListMixin.UpdateType.AlwaysSimulateClick)
	else
		self:RefreshScrollFrame()
	end
end

function CompanionPanelMixin:GetCompanionByIndex(index)
	return self.companions[index]
end

function CompanionPanelMixin:DismissCompanion()
	DismissCompanion(self.companionType)
end

function CompanionPanelMixin:CallCompanion(index)
	CallCompanion(self.companionType, index)
end

function CompanionPanelMixin:PickupCompanion(index)
	PickupCompanion(self.companionType, index)
end

--
-- Companion Scroll Item
--
CompanionScrollItemMixin = CreateFromMixins(ScrollListItemBaseMixin)

function CompanionScrollItemMixin:Init(args)
	ScrollListItemBaseMixin.Init(self, args)
	self:RegisterForDrag("LeftButton")
	self:SetNormalAtlas("PetList-ButtonBackground")
	self:SetHighlightAtlas("PetList-ButtonHighlight")
	self.Icon:SetBorderTexture("Interface\\Buttons\\CheckButtonHilight")
	self.Icon:SetBorderBlendMode("ADD")
	self.Icon:SetBorderSize(32, 32)
	self.SummonButtonCallback = GenerateClosure(self.OnRightClick, self)
end

function CompanionScrollItemMixin:Update()
	local companion = self:GetScrollList():GetCompanionByIndex(self.index)
	self.companion = companion
	self.Icon:SetIcon(companion.icon)
	if companion.isSummoned then
		self.Icon:SetBorderColor(1, 1, 1, 1)
	else
		self.Icon:SetBorderColor(1, 1, 1, 0)
	end
	
	local name = companion.name
	self:SetText(name)

	if self:IsSelected() then
		self:OnSelected()
	end
end

function CompanionScrollItemMixin:OnEnter()
	if C_CVar.GetBool("showTooltipID") then
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.companion.name)
		GameTooltip:AddLine("|cfff73600ID|r |cfffc8a00"..self.companion.spellID.."|r")
		GameTooltip:AddLine("|cfff73600Index|r |cfffc8a00"..self.index.."|r")
		GameTooltip:Show()
	end
end

function CompanionScrollItemMixin:OnLeave()
	GameTooltip:Hide()
end

function CompanionScrollItemMixin:OnSelected()
	local modelFrame = AscensionPetPaperDollPanel.CompanionTab.CompanionModel
	modelFrame:SetDisplayInfo(self.companion.displayID)
	modelFrame:ResetValues()

	local overlay = modelFrame.Overlay
	overlay.Title:SetText(self.companion.name)
	overlay.Description:SetText(GetSpellDescription(self.companion.spellID))
	overlay.SummonButton:SetText(self.companion.isSummoned and PET_DISMISS or SUMMON)
	overlay.SummonButton.onClick = self.SummonButtonCallback
end

function CompanionScrollItemMixin:ToggleSummon()
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
	self:GetScrollList().SearchBox:ClearFocus()
	if self.companion.isSummoned then
		self:GetScrollList():DismissCompanion()
	else
		self:GetScrollList():CallCompanion(self.companion.index)
	end
end

function CompanionScrollItemMixin:OnDragStart()
	self:GetScrollList():PickupCompanion(self.companion.index)
end

function CompanionScrollItemMixin:OnClick(button)
	if IsModifiedClick("CHATLINK") then
		if MacroFrame and MacroFrame:IsShown() then
			local spellName = GetSpellInfo(self.companion.spellID)
			ChatEdit_InsertLink(spellName)
		else
			local spellLink = LinkUtil:GetSpellLink(self.companion.spellID)
			ChatEdit_InsertLink(spellLink)
		end
	else
		ScrollListItemBaseMixin.OnClick(self, button)
	end
end

CompanionScrollItemMixin.OnRightClick = CompanionScrollItemMixin.ToggleSummon
CompanionScrollItemMixin.OnDoubleClick = CompanionScrollItemMixin.ToggleSummon
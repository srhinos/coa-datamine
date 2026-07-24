ECSlotFrameMixin = {}

function ECSlotFrameMixin:OnLoad()
	self:Layout()

	self.tabs = {
		[Enum.ECSlotTabs.ReforgeTab] = self.ReforgeTab,
		[Enum.ECSlotTabs.SlotTab] = self.SlotTab,
		[Enum.ECSlotTabs.ArchitectTab] = self.ArchitectTab,
	}

	self:SetTab(Enum.ECSlotTabs.SlotTab)
end

function ECSlotFrameMixin:SetTab(id)
	for i = 1, #self.tabs do
		if (i == id) then
			BaseFrameFadeIn(self.tabs[i])
		else
			BaseFrameFadeOut(self.tabs[i])
		end
	end

	self.tab = id
end

function ECSlotFrameMixin:GetSelectedTab()
	return self.tab
end

function ECSlotFrameMixin:Layout()
	self.ReforgeTab = CreateFrame("FRAME", "$parent.ReforgeTab", self, "ShadowOverlaySmallTemplate")
	self.ReforgeTab:SetPoint("TOPLEFT")
	self.ReforgeTab:SetPoint("BOTTOMRIGHT")
	self.ReforgeTab:Hide()

	self.ReforgeTab.Inset = CreateFrame("FRAME", "$parent.ReforgeTab.Inset", self.ReforgeTab, "InsetFrameNoBGTemplate")
	self.ReforgeTab.Inset:SetPoint("TOPLEFT")
	self.ReforgeTab.Inset:SetPoint("BOTTOMRIGHT")
	self.ReforgeTab.Inset.NineSlice:SetFrameLevel(self.ReforgeTab.Inset:GetFrameLevel()+1)
	MixinAndLoadScripts(self.ReforgeTab, ECReforgeTabMixin)

	self.SlotTab = CreateFrame("FRAME", "$parent.SlotTab", self, "ShadowOverlaySmallTemplate")
	self.SlotTab:SetPoint("TOPLEFT")
	self.SlotTab:SetPoint("BOTTOMRIGHT", 0, 24)
	self.SlotTab:Hide()

	self.SlotTab.Inset = CreateFrame("FRAME", "$parent.SlotTab.Inset", self.SlotTab, "InsetFrameNoBGTemplate")
	self.SlotTab.Inset:SetPoint("TOPLEFT")
	self.SlotTab.Inset:SetPoint("BOTTOMRIGHT")
	self.SlotTab.Inset.NineSlice:SetFrameLevel(self.SlotTab.Inset:GetFrameLevel()+1)
	MixinAndLoadScripts(self.SlotTab, ECSlotTabMixin)

	self.ArchitectTab = CreateFrame("FRAME", "$parent.ArchitectTab", self, "ShadowOverlaySmallTemplate")
	self.ArchitectTab:SetPoint("TOPLEFT")
	self.ArchitectTab:SetPoint("BOTTOMRIGHT")
	self.ArchitectTab:Hide()

	self.ArchitectTab.Inset = CreateFrame("FRAME", "$parent.ArchitectTab.Inset", self.ArchitectTab, "InsetFrameNoBGTemplate")
	self.ArchitectTab.Inset:SetPoint("TOPLEFT")
	self.ArchitectTab.Inset:SetPoint("BOTTOMRIGHT")
	self.ArchitectTab.Inset.NineSlice:SetFrameLevel(self.ArchitectTab.Inset:GetFrameLevel()+1)
	MixinAndLoadScripts(self.ArchitectTab, ECArchitectTabMixin)
end
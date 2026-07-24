EquipmentManagerPanelMixin = CreateFromMixins(ScrollListMixin)

local function SortSets(a, b)
	if a.id == 0 then return true end
	if b.id == 0 then return false end
	return a.id > b.id
end

function EquipmentManagerPanelMixin:OnLoad()
	self.sets = {}
	if ScrollListMixin.OnLoad then
		-- doesnt exist right now but future proof
		ScrollListMixin.OnLoad(self)
	end
	
	self.IconSelector:SetIconCountProvider(GetEquipmentSetIconCount)
	self.IconSelector:SetIconProvider(GetEquipmentSetIconInfo)
	
	self.Background:SetAtlas("garrlanding-followerframe", Const.TextureKit.IgnoreAtlasSize)

	self:SetGetNumResultsFunction(function() return #self.sets end)
	self:SetTemplate("EquipmentSetItemTemplate")
	self:RegisterEvent("EQUIPMENT_SWAP_PENDING")
	self:RegisterEvent("EQUIPMENT_SWAP_FINISHED")

	self:SetSelectionCallback(GenerateClosure(self.OnSetSelected, self))
	self.IconSelector:SetFrameLevel(self:GetFrameLevel()+10)
end

function EquipmentManagerPanelMixin:OnShow()
	self:RegisterEvent("EQUIPMENT_SETS_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	RunNextFrame(function() self:RefreshScrollFrame() end)
	for slotID, slot in pairs(AscensionPaperDollPanel:GetItemSlots()) do
		slot:ShowPopoutButton()
	end
	self:UpdateButtons()
end

function EquipmentManagerPanelMixin:OnHide()
	self:UnregisterEvent("EQUIPMENT_SETS_CHANGED")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	StaticPopup_Hide("CONFIRM_DELETE_EQUIPMENT_SET")
	StaticPopup_Hide("CONFIRM_OVERWRITE_EQUIPMENT_SET")
	for slotID, slot in pairs(AscensionPaperDollPanel:GetItemSlots()) do
		slot:HidePopoutButton()
	end
end

function EquipmentManagerPanelMixin:OnSetSelected(index)
	self:UpdateButtons()
	self:RefreshScrollFrame()
end

function EquipmentManagerPanelMixin:UpdateButtons()
	local hasSelection = self:GetSelectedIndex() ~= nil
	self.EquipButton:SetEnabled(hasSelection)
	self.SaveButton:SetEnabled(hasSelection)
	local selectedButton = self:GetSelectedButton()
	for slotID, slot in pairs(AscensionPaperDollPanel:GetItemSlots()) do
		slot:SetIgnored(hasSelection and selectedButton.lockedSlots[slotID] ~= nil)
	end
end

function EquipmentManagerPanelMixin:EquipSelected()
	local button = self:GetSelectedButton()
	if button then
		EquipmentManager_EquipSet(button:GetText())
	end
end

function EquipmentManagerPanelMixin:SaveSelected()
	local button = self:GetSelectedButton()
	if button then
		button:SaveChanges()
	end
end

function EquipmentManagerPanelMixin:OnEvent(event, ...)
	if event == "EQUIPMENT_SWAP_PENDING" then
		self.swapPending = true
	elseif event == "EQUIPMENT_SWAP_FINISHED" then
		self.swapPending = false
	end
	self:RefreshScrollFrame()
end

function EquipmentManagerPanelMixin:HasPendingChange()
	return self.swapPending
end

function EquipmentManagerPanelMixin:OpenIconSelector(owner, name, icon, callback)
	RefreshEquipmentSetIconInfo()
	local iconSelector = self.IconSelector

	iconSelector:Hide()

	if iconSelector.owner then
		iconSelector.callback.Unregister()
	end

	iconSelector.owner = owner

	if callback then
		iconSelector.callback = iconSelector:RegisterCallbackWithHandle("OnTextAndIconChange", callback)
	else
		iconSelector.callback = iconSelector:RegisterCallbackWithHandle("OnTextAndIconChange", function(_, name, icon, iconIndex)
			if iconSelector.owner then
				iconSelector.owner:SetIcon(icon, iconIndex)
				iconSelector.owner:SetName(name)
				iconSelector.owner:SaveChanges()
			end
		end)
	end

	name = name or owner:GetText()
	icon = icon or owner.Icon:GetIcon()

	iconSelector:EditExisting(name or "", icon)
end

function EquipmentManagerPanelMixin:RefreshScrollFrame()
	wipe(self.sets)
	local numSets = GetNumEquipmentSets()
	for i = 1, numSets do
		local name, icon = GetEquipmentSetInfo(i)
		tinsert(self.sets, { name = name, icon = icon, id = i })
	end

	if numSets < MAX_EQUIPMENT_SETS_PER_PLAYER then
		tinsert(self.sets, { name = GREEN_FONT_COLOR:WrapText(EQUIPMENT_MANAGER_NEW_SET), icon = "Interface\\PaperDollInfoFrame\\Character-Plus-BG", id = 0 })
	end

	table.sort(self.sets, SortSets)
	ScrollListMixin.RefreshScrollFrame(self)
end

function EquipmentManagerPanelMixin:GetSetInfoByIndex(index)
	return self.sets[index]
end
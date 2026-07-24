local Addon = select(2, ...)
local Store = CreateFrame("FRAME", "StoreCollectionFrame", Collections, nil)
Addon.Store = Store

Store:Hide()
Store:SetScale(1.1)

local ItemLootQuery = {}

function CheckKnownItem(itemID)
	if not (itemID) then
		return false
	end

	if not (GetItemInfo(itemID)) then
		table.insert(ItemLootQuery, itemID)
	end

	return C_VanityCollection.IsCollectionItemOwned(itemID)
end

local LootQueryFrame = CreateFrame("FRAME")
LootQueryFrame.total = 20
LootQueryFrame.counter = 0

LootQueryFrame:SetScript("OnUpdate", function()
	if not (next(ItemLootQuery)) then
		LootQueryFrame.counter = LootQueryFrame.total -- to make next cache request instant
		return
	end

	LootQueryFrame.counter = LootQueryFrame.counter + 1

	if LootQueryFrame.counter < LootQueryFrame.total then
		return
	end

	--print("Cache request of "..ItemLootQuery[1]) -- DEBUG

	TryCacheItem(ItemLootQuery[1])
	table.remove(ItemLootQuery, 1)
	LootQueryFrame.counter = 0
end)

LootQueryFrame:Show()

-------------------------------------------------------------------------------
--                               Config Values                               --
-------------------------------------------------------------------------------
Store.Items = {}
Store.ItemsCurrent = {}
Store.TotalItems = 0
Store.KnownItems = 0
Store.Preview_Items = {}
Store.Preview_Creatures = {}
Store.Preview_Current = {}

Store.PageCount = 0
Store.MaxItemsPerPage = 9
Store.CurrentPage = 1

Store.ItemSelected = 0

Store.ItemInternal = 0

Store.GroupIcons = {
	[3]  = { Addon.AwTexPath .. "Collections\\category-icon-mounts", "Mounts" },
	[4]  = { Addon.AwTexPath .. "Collections\\category-icon-pets", "Pets" },
	[5]  = { Addon.AwTexPath .. "Collections\\category-icon-toys", "Toys" },
	[7]  = { Addon.AwTexPath .. "Collections\\category-icon-armor", "Appearances" },
	[8]  = { Addon.AwTexPath .. "Collections\\category-icon-weapons", "Weapons" },
	[15] = { Addon.AwTexPath .. "Collections\\category-icon-featured", "Ascension Exclusives" },
	[16] = { Addon.AwTexPath .. "Collections\\category-icon-weapons.blp", "Illusions" },
	[17] = { Addon.AwTexPath .. "Collections\\category-icon-druid.blp", "Incarnations" },
	[18] = { Addon.AwTexPath .. "Collections\\category-icon-pets.blp", "Pet Cosmetics" },
}

Store.DefaultPreviewTexture = Addon.AwTexPath .. "Collections\\PreviewItems\\Store_PreviewMain"
Store.DefaultArtworkTexture = Addon.AwTexPath .. "Collections\\StorePaperArtwork"

Store.SPBalance = 0
Store.DPBalance = 0

Store.SP_Cost_Current = 0
Store.BT_Cost_Current = 0
Store.DP_Cost_Current = 0

local VanityFilterFlags = {
	Owned = 0x1,
	Unowned = 0x2,
	Purchasable = 0x4,
	Deliverable = 0x8,
	Heirloom = 0x10,
	Manastorm = 0x20,
}

local function GetVanityItem(itemID)
	if VanityCollectionUtil then
		return VanityCollectionUtil.GetItem(itemID)
	end

	return itemID and C_VanityCollection.GetItem(itemID)
end

local function CacheVanityItem(item)
	if item and item.itemid then
		Store.Items[item.itemid] = item
	end
	return item
end

local function GetVanityItemCached(itemID)
	return Store.Items[itemID] or CacheVanityItem(GetVanityItem(itemID))
end

local function GetVanityDPPrice(item)
	if not item then
		return 0
	end

	if item.dpCost then
		return item.dpCost
	end

	return C_VanityCollection.GetDPPrice(item.itemid or item.itemID)
end
-------------------------------------------------------------------------------
--                                UI Scripts                                 --
-------------------------------------------------------------------------------

local function UpdatePageInfo(pagenum)
	Store.CollectionList.PageText:SetText("Page " .. pagenum .. "/" .. Store.PageCount)
end

local function StoreCollectionHideModelPreview()
	Store.ModelPreview_fake:Hide()
	Store.ModelPreview:Hide()
end

local function StoreCollectionHasOptionToPreview(itemID)
	local vanityItem = GetVanityItemCached(itemID)
	if not vanityItem then
		return false
	end

	-- FOR CREATURES
	if (vanityItem.creaturePreview > 0) then
		return true
	end

	Store.Preview_Items[itemID] = {}
	for _, contentId in ipairs(vanityItem.contentsPreview or {}) do
		tinsert(Store.Preview_Items[itemID], contentId)
	end

	if not (next(Store.Preview_Items[itemID])) then
		return false
	end

	return true
end

local function StoreCollectionGetPreviewData(itemID)
	local PreviewData = Store.Preview_Items[itemID]

	if not (PreviewData) then
		-- creatures will display only if there is no items preview.
		local vanityItem = GetVanityItemCached(itemID)
		PreviewData = vanityItem and vanityItem.creaturePreview
	end

	return PreviewData or {}
end

local function BuildButtonData(index, entry, qualitycolor, name, texture, isknown, group, dp_cost, sp_cost, bt_cost)
	local vanityItem = GetVanityItemCached(entry)
	if not vanityItem then
		return
	end

	local ArtWork = vanityItem.artwork
	local groupicon = Store.GroupIcons[group]

	SetPortraitToTexture(_G["StoreCollectionItemFrame" .. index .. ".Icon"], texture)
	_G["StoreCollection" .. index .. ".TextNormal"]:SetText(qualitycolor .. "[" .. name .. "]|r")

	_G["StoreCollectionItemFrame" .. index .. ".Button.SeasonalPointsCost"] = sp_cost
	_G["StoreCollectionItemFrame" .. index .. ".Button.BazaarTokenCost"] = bt_cost
	_G["StoreCollectionItemFrame" .. index .. ".Button.DonatePointsCost"] = dp_cost
	_G["StoreCollectionItemFrame" .. index .. ".Button.ItemInternal"] = entry
	_G["StoreCollectionItemFrame" .. index .. ".Button.Icon"] = texture
	_G["StoreCollectionItemFrame" .. index .. ".Button.ItemName"] = name
	_G["StoreCollectionItemFrame" .. index .. ".Button.ItemDescription"] = vanityItem.description

	if not (ArtWork) or (ArtWork == "") then
		ArtWork = Store.DefaultArtworkTexture
		_G["StoreCollectionItemFrame" .. index .. ".Button.ArtWorkPreview"] = Store.DefaultPreviewTexture
	else
		_G["StoreCollectionItemFrame" .. index .. ".Button.ArtWorkPreview"] = Addon.AwTexPath .. "Collections\\PreviewItems\\" .. ArtWork
		ArtWork = Addon.AwTexPath .. "Collections\\" .. ArtWork
	end

	_G["StoreCollectionItemFrame" .. index .. ".Button.ArtWork"] = ArtWork

	if not (groupicon) then
		groupicon = Addon.AwTexPath .. "Collections\\category-icon-featured"
	else
		groupicon = groupicon[1]
	end

	_G["StoreCollectionItemFrame" .. index .. ".GroupIcon"]:SetTexture(groupicon)

	if not (isknown) and group ~= Enum.VanityCategory.Consumable then
		_G["StoreCollectionItemFrame" .. index .. ".GroupIcon"]:SetVertexColor(0.4, 0.4, 0.4, 0.8)
		_G["StoreCollectionItemFrame" .. index .. ".Button.Item"] = 0
		_G["StoreCollectionItemFrame" .. index .. ".Icon"]:SetVertexColor(0.8, 0.8, 0.8, 0.8)
		_G["StoreCollectionItemFrame" .. index .. ".PrestigeTexture"]:SetVertexColor(1, 1, 1, 0.2)
		_G["StoreCollectionItemFrame" .. index .. ".RoundBG"]:SetVertexColor(1, 1, 1, 0.2)
		_G["StoreCollectionItemFrame" .. index .. ".Circle"]:SetVertexColor(0.5, 0.5, 0.5, 1)
		_G["StoreCollection" .. index .. ".TextNormal"]:SetVertexColor(1, 1, 1, 0.5)
	else
		_G["StoreCollectionItemFrame" .. index .. ".GroupIcon"]:SetVertexColor(1, 1, 1, 1)
		_G["StoreCollectionItemFrame" .. index .. ".Button.Item"] = group ~= Enum.VanityCategory.Consumable and entry or 0
		_G["StoreCollectionItemFrame" .. index .. ".Icon"]:SetVertexColor(1, 1, 1, 1)
		_G["StoreCollectionItemFrame" .. index .. ".PrestigeTexture"]:SetVertexColor(1, 1, 1, 1)
		_G["StoreCollectionItemFrame" .. index .. ".RoundBG"]:SetVertexColor(1, 1, 1, 1)
		_G["StoreCollectionItemFrame" .. index .. ".Circle"]:SetVertexColor(1, 1, 1, 1)
		_G["StoreCollection" .. index .. ".TextNormal"]:SetVertexColor(1, 1, 1, 1)
	end

	_G["StoreCollectionItemFrame" .. index].ExtraCostText2:Hide()
	_G["StoreCollectionItemFrame" .. index].ExtraCostIcon2:Hide()

	
	if bit.contains(Store.Items[entry].group, Enum.VanityCategory.AzzarFaire) then
    _G["StoreCollectionItemFrame" .. index .. ".BackgroundTexture"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreButtonBG_AzzarFaire")
		if sp_cost > 0 then
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText(sp_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")
		else
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText("")
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Hide()
		end

	elseif bit.contains(Store.Items[entry].group, Enum.VanityCategory.Seasonal) then
		_G["StoreCollectionItemFrame" .. index .. ".BackgroundTexture"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreButtonBG_Seasonal")
		if sp_cost > 0 then
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText(sp_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")
		else
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText("")
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Hide()
		end
	else
		_G["StoreCollectionItemFrame" .. index .. ".BackgroundTexture"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreButtonBG")
		if bt_cost > 0 and dp_cost > 0 then
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText(dp_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:SetTexture("Interface\\Store\\dp_icon")

			_G["StoreCollectionItemFrame" .. index].ExtraCostText2:SetText(bt_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostText2:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon2:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon2:SetTexture("Interface\\icons\\Spell_Shadow_Teleport")
		elseif bt_cost > 0 then
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText(bt_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:SetTexture("Interface\\icons\\Spell_Shadow_Teleport")
		elseif dp_cost > 0 then
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText(dp_cost)
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Show()
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:SetTexture("Interface\\Store\\dp_icon")
		else
			_G["StoreCollectionItemFrame" .. index].ExtraCostText:SetText("")
			_G["StoreCollectionItemFrame" .. index].ExtraCostIcon:Hide()
		end
	end

	if (StoreCollectionHasOptionToPreview(entry)) then
		_G["StoreCollectionItemFrame" .. index .. ".Button.PreviewData"] = StoreCollectionGetPreviewData(entry)
	else
		_G["StoreCollectionItemFrame" .. index .. ".Button.PreviewData"] = {}
	end

end

local function UpdateListButtons(pagenumber, listtodisplay)
	for i = 1, Store.MaxItemsPerPage do
		_G["StoreCollectionItemFrame" .. i]:Hide()
	end

	wipe(Store.ItemsCurrent)
	listtodisplay = listtodisplay or {}

	for _, item in ipairs(listtodisplay) do
		CacheVanityItem(item)
		tinsert(Store.ItemsCurrent, item)
	end

	local button_progress = 1

	--structure: {entry, name, quality, bannertext, group, description, icon, artwork, known}
	while (button_progress <= #listtodisplay) do
		local itemInfo = listtodisplay[button_progress]
		local itemID = itemInfo.itemid or itemInfo.itemID
		local ItemKnown = itemInfo.owned or C_VanityCollection.IsCollectionItemOwned(itemID)
		local ItemGroup = itemInfo.group
		local ItemDPCost = GetVanityDPPrice(itemInfo)
		local ItemSPCost = itemInfo.spCost
		local ItemBTCost = itemInfo.btCost

		local _, _, _, QualityColor = GetItemQualityColor(itemInfo.quality)
		local ItemName, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)

		if not (ItemName) then
			ItemName = itemInfo.name
		end

		texture = "Interface\\Icons\\" .. itemInfo.icon

		BuildButtonData(button_progress, itemID, QualityColor, ItemName, texture, ItemKnown, ItemGroup, ItemDPCost,
		                ItemSPCost, ItemBTCost)
		_G["StoreCollectionItemFrame" .. button_progress]:Show()

		button_progress = button_progress + 1
	end
end

local function GetStoreFlags(menu)
	local flags = 0
	menu = menu or Store.StoreTypeList.List

	if not menu then return 0 end

	for index, data in ipairs(menu) do
		if data.children then
			local subFlags = GetStoreFlags(data.children)
			flags = bit.bor(flags, subFlags)
		elseif data.flag and data.checked then
			flags = bit.bor(flags, data.flag)
		end
	end

	return flags
end

local function GetStoreFilterFlags()
	local filterFlags = 0
	if Store.StoreTypeList.Known then
		filterFlags = bit.bor(filterFlags, VanityFilterFlags.Owned)
	end
	if Store.StoreTypeList.Purchasable then
		filterFlags = bit.bor(filterFlags, VanityFilterFlags.Purchasable)
	end
	if Store.StoreTypeList.Heirloom then
		filterFlags = bit.bor(filterFlags, VanityFilterFlags.Heirloom)
	end
	if Store.StoreTypeList.Manastorm then
		filterFlags = bit.bor(filterFlags, VanityFilterFlags.Manastorm)
	end

	return filterFlags
end

local function QueryStoreItems(pagenumber)
	pagenumber = pagenumber or 1

	local offset = (pagenumber - 1) * Store.MaxItemsPerPage
	local result = C_VanityCollection.QueryItems(Store.SearchBox:GetText() or "", Store.StoreTypeList.Flags, GetStoreFilterFlags(), 1, offset, Store.MaxItemsPerPage) or {}

	return result.total or 0, result.items or {}
end

local function UpdateListInfo(pagenumber)
	if not (pagenumber) then
		pagenumber = 1
	end
	if (pagenumber < 1) then
		pagenumber = 1
	end

	local items
	Store.TotalItems, items = QueryStoreItems(pagenumber)
	Store.PageCount = math.ceil(Store.TotalItems / Store.MaxItemsPerPage)

	if (Store.PageCount < 1) then
		Store.PageCount = 1
	end

	if (pagenumber > Store.PageCount) then
		pagenumber = Store.PageCount
		Store.TotalItems, items = QueryStoreItems(pagenumber)
	end

	Store.CurrentPage = pagenumber
	UpdatePageInfo(Store.CurrentPage)

	if (pagenumber >= Store.PageCount) then
		Store.CollectionList.NextButton:Disable()
	else
		Store.CollectionList.NextButton:Enable()
	end

	if (pagenumber <= 1) then
		Store.CollectionList.PrevButton:Disable()
	else
		Store.CollectionList.PrevButton:Enable()
	end

	UpdateListButtons(pagenumber, items)
end

local function StoreCollectionListNextPage(self)
	PlaySound("igMainMenuContinue")
	Store.CurrentPage = Store.CurrentPage + 1
	UpdateListInfo(Store.CurrentPage)
end

local function StoreCollectionListPrevPage(self)
	PlaySound("igMainMenuContinue")
	Store.CurrentPage = Store.CurrentPage - 1
	UpdateListInfo(Store.CurrentPage)
end

local function GetGroupFlags(group)
	local flags = {}
	for enum, flag in pairs(Enum.VanityCategory) do
		if type(flag) == "table" then
			for subEnum, subFlag in pairs(flag) do
				if bit.band(subFlag, group) == subFlag then
					tinsert(flags, subFlag)
				end
			end
		else
			if bit.band(flag, group) == flag then
				tinsert(flags, flag)
			end
		end
	end

	return flags
end

local function BuildStoreList()
	Store.StoreTypeList.Flags = GetStoreFlags()

	if Store.StoreTypeList.Flags == 0 then
		Store.StoreTypeList.Flags = Enum.VanityCategory.All
	end

	if Store.StoreTypeList.Flags == Enum.VanityCategory.All then
		Store.StoreTypeList.ClearFiltersButton:Hide()
	else
		Store.StoreTypeList.ClearFiltersButton:Show()
	end

	UpdateListInfo()
	StoreCollectionHideModelPreview()
end

local function SearchForItem(self)
	SearchBoxTemplate_OnTextChanged(self)
	BuildStoreList()
end

function VanityCollectionUtil.OpenAndSearch(text)
	Collections:GoToTab(Collections.Tabs.Vanity)
	Store.StoreTypeList:ClearFilters(true)
	StoreCollectionHideModelPreview()
	Store.SearchBox:SetText(text)
end

function VanityCollectionUtil.OpenToCategory(category, searchText)
	Collections:GoToTab(Collections.Tabs.Vanity)
	Store.StoreTypeList:ClearFilters(true)
	StoreCollectionHideModelPreview()
	for _, filter in ipairs(Store.StoreTypeList.List) do
		if filter.flag == category then
			filter.checked = true
			break
		end
	end

	if searchText then
		Store.SearchBox:SetText(searchText)
	else
		Store.SearchBox:SetText("")
		BuildStoreList()
	end
end

local function StoreCollectionFrameModelPreviewFixModelPosition(self)
	local uiScale = 1
	if (GetCVar("useUiScale") == "1") then
		uiScale = GetCVar("uiScale")
	else
		SetCVar("uiScale", "1")
		uiScale = 1
	end -- resolution and uiscale fix
	self:SetPosition(0, 0, 1.65 / uiScale)
end

local function StoreCollectionFrameModelPreviewInitModel(self)
	if tonumber(Store.Preview_Current) then
		self.Creature = Store.Preview_Current
	elseif next(Store.Preview_Current) then
		self.Creature = nil
	end

	if (self.Creature) then
		self:SetDisplayInfo(self.Creature)
		self:SetCamera(0)
	else
		self:SetCamera(0)
		self:SetUnit("player")
		self:RefreshUnit()
	end

	self:SetFacing(self.DefaultFacing)
	self:SetModelScale(self.DefaultSize)
	StoreCollectionFrameModelPreviewFixModelPosition(self)
end

local function PaperModelPreviewInitModel(self)
	if tonumber(Store.Preview_Current) then
		self.Creature = Store.Preview_Current
	elseif next(Store.Preview_Current) then
		self.Creature = nil
	end

	if (self.Creature) then
		self:SetDisplayInfo(self.Creature)
		self:RefreshUnit()
	else
		self:SetUnit("player")
		self:RefreshUnit()
	end

	self:SetFacing(self.DefaultFacing)
	self:SetModelScale(self.DefaultSize)
	--StoreCollectionFrameModelPreviewFixModelPosition(self)
end

local function StoreCollectionFrameModelPreviewLoadItems()
	if not Store.ModelPreview.Creature and Store.Preview_Current and #Store.Preview_Current > 0 then
		for _, itemId in pairs(Store.Preview_Current) do
			local item = Item:CreateFromID(itemId)
			item:ContinueOnLoad(function(itemId)
				Store.ModelPreview:TryOn(itemId)
				Store.Paper.ModelPreview:TryOn(itemId)
			end)
		end
		Store.ModelPreview_fake.SpendPoints:Show()
	else
		Store.ModelPreview_fake.SpendPoints:Hide()
	end
end

local function PaperModelPreviewLoadItems()
	if not Store.Paper.ModelPreview.Creature and Store.Preview_Current and #Store.Preview_Current > 0 then
		for _, itemId in pairs(Store.Preview_Current) do
			local item = Item:CreateFromID(itemId)
			item:ContinueOnLoad(function(itemId)
				Store.Paper.ModelPreview:TryOn(itemId)
			end)
		end
	end
end

local function StoreCollectionPreviewButtonCheck()
	if tonumber(Store.Preview_Current) or (next(Store.Preview_Current)) then
		-- table is for items, value is for creatures
		--DISPLAY PREVIEW--
		Store.Paper.ItemPreview:Show()
		Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup:Stop()
		Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup:Play()
	else
		Store.Paper.ItemPreview:Hide()
	end
end

local function StorePaperPreviewModelCheck()
	if tonumber(Store.Preview_Current) or next(Store.Preview_Current) then
		Store.Paper.ArtWork:Hide()
		Store.Paper.ModelPreview:Update()
		Store.Paper.ModelPreview:Show()
	else
		Store.Paper.ArtWork:Show()
		Store.Paper.ModelPreview:Hide()
	end
end

local function StoreCollectionFrameShowPaper()
	Addon:BaseFrameFadeIn(Store.Paper)
	Addon:BaseFrameFadeIn(Store.Paper_fake)
	Store.Paper.Icon:Show()
	Store.Paper.GoldBG:Show()
	Store.Paper.Texture:Show()
	Store.Paper.LineUp:Show()
	Store.Paper.LineDown:Show()
	Store.Paper.DescText:Show()
	Store.Paper.BorderTex:Show()
	Store.Paper.LineDown.AnimationGroup:Stop()
	Store.Paper.LineDown.AnimationGroup:Play()
	StoreCollectionPreviewButtonCheck()
	StorePaperPreviewModelCheck()
end

local function StoreCollectionFrameHidePaper()
	Addon:BaseFrameFadeOut(Store.Paper)
	Addon:BaseFrameFadeOut(Store.Paper_fake)
	Store.Paper.Icon:Hide()
	Store.Paper.GoldBG:Hide()
	Store.Paper.Texture:Hide()
	Store.Paper.LineUp:Hide()
	Store.Paper.LineDown:Hide()
	Store.Paper.DescText:Hide()
	Store.Paper.BorderTex:Hide()
	Store.Paper.LineDown.AnimationGroup:Stop()
end

local function StoreCollectionShowModelPreview()
	StoreCollectionFrameModelPreviewInitModel(Store.ModelPreview)
	Store.ModelPreview_fake:Show()
end

local function LoadBannerRandomItem()
	local ItemInfo = C_VanityCollection.GetRandomItem and C_VanityCollection.GetRandomItem()
	if not ItemInfo then
		return false
	end

	CacheVanityItem(ItemInfo)
	local itemID = ItemInfo.itemid or ItemInfo.itemID
	local ItemName, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemID)
	if not (ItemName) then
		ItemName = ItemInfo.name
	end
	texture = "Interface\\Icons\\" .. ItemInfo.icon
	local ItemAddText = ItemInfo.description

	Store.Banner.Item = itemID
	Store.Banner.Icon:SetTexture(texture)
	Store.Banner.TitleText:SetText(strupper(ItemName))
	Store.Banner.TitleText_UNEDITED = ItemName
	Store.Banner.DescText:SetText(strupper(ItemAddText))
	return true
end

local function LoadItemFromBanner()
	if not (Store.Banner.Item) then
		return false
	end

	local item = GetVanityItemCached(Store.Banner.Item)
	if not item then
		return false
	end

	local ArtWork = item.artwork

	if not (ArtWork) or (ArtWork == "") then
		ArtWork = Store.DefaultArtworkTexture
		Store.ModelPreview.BGTex:SetTexture(Store.DefaultPreviewTexture)
	else
		if not (Store.ModelPreview.BGTex:SetTexture(Addon.AwTexPath .. "Collections\\PreviewItems\\" .. ArtWork)) then
			Store.ModelPreview.BGTex:SetTexture(Store.DefaultPreviewTexture)
		end
		ArtWork = Addon.AwTexPath .. "Collections\\" .. ArtWork
	end

	Store.Paper.Icon:SetNormalTexture(Store.Banner.Icon:GetTexture())
	Store.Paper.ArtWork:SetTexture(ArtWork)
	Store.Paper.TitleText:SetText(Store.Banner.TitleText_UNEDITED)
	Store.Paper.DescText:SetText(item.description)
	Store.ItemInternal = Store.Banner.Item
	local dpCost = GetVanityDPPrice(item)

	if (dpCost ~= 0) or (item.spCost ~= 0) or (item.btCost ~= 0)  then
		-- show buy option and cost
		Store.SP_Cost_Current = item.spCost
		Store.BT_Cost_Current = item.btCost
		Store.DP_Cost_Current = dpCost 
		Store.BuyStoreButton:Enable()
	else
		Store.BuyStoreButton:Disable()
	end

	if C_VanityCollection.IsCollectionItemOwned(Store.Banner.Item) then
		Store.ItemSelected = Store.Banner.Item
		Store.ActivateStoreButton:SetEnabled(not bit.contains(item.flags, Enum.VanityFlags.CannotBeDelivered))
		--Store.ModelPreview_fake.SpendPoints.MainButton:Enable()
		if dpCost > 0 and C_Config.GetBoolConfig("CONFIG_WEB_SHOP_ENABLED") then
			Store.BuyStoreButton:Enable()
		else
			Store.BuyStoreButton:Disable()
		end
	else
		Store.ItemSelected = 0
		Store.ActivateStoreButton:Disable()
		Store.ModelPreview_fake.SpendPoints.MainButton:Disable()
	end

	if (StoreCollectionHasOptionToPreview(Store.Banner.Item)) then
		Store.Preview_Current = StoreCollectionGetPreviewData(Store.Banner.Item)
	else
		Store.Preview_Current = {}
	end
	StoreCollectionHideModelPreview()

	StoreCollectionFrameShowPaper()
end

local function ActivateItem(self)
	PlaySound("igMainMenuOptionCheckBoxOn")
	if (Store.ItemSelected ~= 0) and (self:IsEnabled() == 1) then
		C_VanityCollection.RequestDelivery(Store.ItemSelected)
	end
end

local function BuyItem(dpOnlyPurchase)
	PlaySound("igMainMenuOptionCheckBoxOn")
	if (Store.ItemInternal ~= 0) then
		local costType
		local item = GetVanityItemCached(Store.ItemInternal)
		if not item then
			C_Logger.Error("Tried to purchase collection, but selected item was not found! ID: "..(Store.ItemInternal or "nil"))
			return
		end

		if item.spCost > 0 and not dpOnlyPurchase then
			costType = Enum.VanityCurrency.SeasonalPoints
		elseif item.btCost > 0 and not dpOnlyPurchase then
			costType = Enum.VanityCurrency.BazaarTokens
		elseif GetVanityDPPrice(item) > 0 then
			costType = Enum.VanityCurrency.DonationPoints
		end

		if not costType then
			C_Logger.Error("Tried to purchase collection item, but item has no spCost, btCost or dpCost! ID: "..Store.ItemInternal)
			return
		end

		if costType == Enum.VanityCurrency.DonationPoints then
			if C_VanityCollection.PurchaseWebShopItem(Store.ItemInternal) then
				Store.PurchasePendingInputBlocker:Show()
			else
				Store.PurchaseFailedInputBlocker:Show()
				Store.PurchaseFailedInputBlocker:SetText("Failed to purchase item.", "Client failed to purchase item.")
			end
		else
			C_VanityCollection.Purchase(Store.ItemInternal, costType)
		end
	end
end
-------------------------------------------------------------------------------
--                            Core Functions                                 --
-------------------------------------------------------------------------------
local function UpdateBalance(DP_Count, SP_Count)
	Store.SPBalance = SP_Count
	Store.DPBalance = DP_Count

	Store.SPCounter_Text:SetText(SP_Count)
	Store.DPCounter_Text:SetText(DP_Count)
end

local function Store_Init()
	Store.StoreTypeList.Known = true
	UpdateBalance(GetAscensionDonationPoints(), GetItemCount(ItemData.SEASONAL_POINTS))
	BuildStoreList()
	if C_VanityCollection.IsPurchaseInProgress() then
		Store.PurchasePendingInputBlocker:Show()
	end
end

local function UnlockNewItem(itemId)
	-- TODO: this is ugly, needs its own queue probably, but ok for now
	if WildCard then
		if WildCardDice:IsVisible() then
			return
		end
	end

	local itemData = GetVanityItemCached(itemId)
	if not itemData then return end
	if C_Player:GetLevel() <= 9 and bit.contains(itemData.flags or 0, 0x1000000) and C_GameMode:IsGameModeActive(Enum.GameMode.Draft, Enum.GameMode.WildCard) then
		return -- block tamed pet whistles when below lvl 9 playing draft or wildcard
	end
	Store_Init()
	PlaySound("LEVELUP")
	Store.Items[itemData.itemid] = itemData
	Store.Items[itemData.itemid].known = true
	BuildStoreList()
	if not (StoreNewItemInCollection:IsVisible()) then
		local ItemName, itemLink, _, _, _, _, _, _, _, texture = GetItemInfo(itemData.name)
		if not ItemName then
			ItemName = itemData.name
			itemLink = "[" .. itemData.name .. "]"
		end
		texture = "Interface\\Icons\\" .. itemData.icon

		SetPortraitToTexture(StoreNewItemInCollection.Main.Icon, texture)
		StoreNewItemInCollection.Main.TextNormal:SetText(strupper(ItemName))
		StoreNewItemInCollection.Main.TextAdd:SetText("|cffFFFFFFNew |rVanity Item|cffFFFFFF unlocked - " .. itemLink .. "|cffFFFFFF!|r")
		StoreNewItemInCollection.Main.AnimationGroup:Stop()
		StoreNewItemInCollection:Show()
		StoreNewItemInCollection.Main.AnimationGroup:Play()
	end
end

-------------------------------------------------------------------------------
--                           UI Frames and buttons                           --
-------------------------------------------------------------------------------
Store:SetSize(784, 512)
Store:SetPoint("BOTTOM", 0, 0)
Store:SetBackdrop({
	                  bgFile = Addon.AwTexPath .. "Collections\\StoreCollection",
	                  insets = {
		                  left   = -120,
		                  right  = -120,
		                  top    = -256,
		                  bottom = -256 }
                  })
Store:SetClampedToScreen(true)
Store:SetScript("OnShow", function(self)
	C_Quest:SendPathToAscensionEvent("ACTION_OPEN_THE_VANITY_COLLECTION")
	Store_Init(self)
end)

Store:SetScript("OnUpdate", function()
	if not (Store.ModelPreview:IsVisible()) and Store.ModelPreview_fake:IsVisible() then
		Store.ModelPreview.HackFix = Store.ModelPreview.HackFix + 1
		if (Store.ModelPreview.HackFix >= 5) then
			Store.ModelPreview:Show()
			Store.ModelPreview.HackFix = 0
		end
	end

	if not (Store.Banner:IsVisible()) then
		if LoadBannerRandomItem() then
			Store.Banner.AnimationGroup:Stop()
			Addon:BaseFrameFadeIn(Store.Banner)
			Store.Banner.AnimationGroup:Play()
		end
	end
end)

Store:SetScript("OnHide", function()
	StaticPopup_Hide("VANITY_PURCHASE")
	StaticPopup_Hide("VANITY_PURCHASE_MULTI")
end)

Store.CloseButton = CreateFrame("Button", "$parentCloseButton", Store, "UIPanelCloseButton")
Store.CloseButton:SetPoint("TOPRIGHT", -4, -1)
Store.CloseButton:EnableMouse(true)
Store.CloseButton:SetScript("OnMouseUp", function()
	PlaySound("igMainMenuClose")
	HideUIPanel(Collections)
end)

Store.TitleText = Store:CreateFontString("StoreCollectionFrameTitleText")
Store.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
Store.TitleText:SetFontObject(GameFontNormal)
Store.TitleText:SetPoint("TOP", 0, -11)
Store.TitleText:SetShadowOffset(1, -1)
Store.TitleText:SetText(VANITY_ITEM_COLLECTION)

Store.SearchBox = CreateFrame("EditBox", "$parentSearchBox", Store, "SearchBoxTemplate")
Store.SearchBox:SetSize(150, 20)
Store.SearchBox:SetPoint("TOPRIGHT", Store, -187, -35)
Store.SearchBox.Instructions:SetText(SEARCH)
Store.SearchBox:SetScript("OnTextChanged", SearchForItem)
Store.SearchBox:SetScript("OnEnterPressed", function(self)
	SearchForItem(self)
	EditBox_ClearFocus(self)
end)

Store.PurchasePendingInputBlocker = CreateFrame("Frame", "$parentPurchasePendingInputBlocker", Store, "InputBlockTextLoadingTemplate")
Store.PurchasePendingInputBlocker:SetPoint("TOPLEFT", 12, -60)
Store.PurchasePendingInputBlocker:SetPoint("BOTTOMRIGHT", -10, 28)
Store.PurchasePendingInputBlocker:Hide()
Store.PurchasePendingInputBlocker:SetText("Purchasing Item...")

Store.PurchaseFailedInputBlocker = CreateFrame("Frame", "$parentPurchaseFailedInputBlocker", Store, "InputBlockTextTemplate")
Store.PurchaseFailedInputBlocker:SetPoint("TOPLEFT", 12, -60)
Store.PurchaseFailedInputBlocker:SetPoint("BOTTOMRIGHT", -12, 28)
Store.PurchaseFailedInputBlocker:Hide()
Store.PurchaseFailedInputBlocker:SetText("Purchase Failed", "Unknown Error")

Store.PurchaseFailedInputBlocker.CloseButton = CreateFrame("Button", "$parentCloseButton", Store.PurchaseFailedInputBlocker, "SharedButtonTemplate")
Store.PurchaseFailedInputBlocker.CloseButton:SetText(CLOSE)
Store.PurchaseFailedInputBlocker.CloseButton:SetSize(120, 30)
Store.PurchaseFailedInputBlocker.CloseButton:SetPoint("CENTER", 0, -50)
Store.PurchaseFailedInputBlocker.CloseButton:SetScript("OnClick", function()
	Store.PurchaseFailedInputBlocker:Hide()
end)

Store.PurchaseSuccessInputBlocker = CreateFrame("Frame", "$parentPurchaseSuccessInputBlocker", Store, "InputBlockTextTemplate")
Store.PurchaseSuccessInputBlocker:SetPoint("TOPLEFT", 12, -60)
Store.PurchaseSuccessInputBlocker:SetPoint("BOTTOMRIGHT", -12, 28)
Store.PurchaseSuccessInputBlocker:Hide()
Store.PurchaseSuccessInputBlocker:SetText("Successfully Purchased Item!")

Store.PurchaseSuccessInputBlocker.CloseButton = CreateFrame("Button", "$parentCloseButton", Store.PurchaseSuccessInputBlocker, "SharedButtonTemplate")
Store.PurchaseSuccessInputBlocker.CloseButton:SetText(CLOSE)
Store.PurchaseSuccessInputBlocker.CloseButton:SetSize(120, 30)
Store.PurchaseSuccessInputBlocker.CloseButton:SetPoint("CENTER", 0, -50)
Store.PurchaseSuccessInputBlocker.CloseButton:SetScript("OnClick", function()
	Store.PurchaseSuccessInputBlocker:Hide()
end)

Store.SPCounter_BackgroundTexture = Store:CreateTexture(nil, "ARTWORK")
Store.SPCounter_BackgroundTexture:SetSize(110, 55)
Store.SPCounter_BackgroundTexture:SetTexture(Addon.AwTexPath .. "Collections\\DP_Counter")
Store.SPCounter_BackgroundTexture:SetPoint("CENTER", -115, 206)

Store.DPCounter_BackgroundTexture = Store:CreateTexture(nil, "ARTWORK")
Store.DPCounter_BackgroundTexture:SetSize(110, 55)
Store.DPCounter_BackgroundTexture:SetTexture(Addon.AwTexPath .. "Collections\\SP_Counter")
Store.DPCounter_BackgroundTexture:SetPoint("CENTER", -17, 206)

Store.SPCounter_Icon = Store:CreateTexture(nil, "OVERLAY")
Store.SPCounter_Icon:SetSize(21, 21)
Store.SPCounter_Icon:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")
Store.SPCounter_Icon:SetPoint("CENTER", -147.5, 210)
SetPortraitToTexture(Store.SPCounter_Icon, "Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")

Store.DPCounter_Icon = Store:CreateTexture(nil, "OVERLAY")
Store.DPCounter_Icon:SetSize(21, 21)
Store.DPCounter_Icon:SetTexture("Interface\\icons\\spell_frostfire_orb")
Store.DPCounter_Icon:SetPoint("CENTER", -49.5, 210)
SetPortraitToTexture(Store.DPCounter_Icon, "Interface\\Store\\dp_icon")

Store.SPCounter_Text = Store:CreateFontString("StoreCollectionFrameSPCounter_Text")
Store.SPCounter_Text:SetFontObject(NumberFontNormal)
Store.SPCounter_Text:SetPoint("CENTER", -110, 204.5)
Store.SPCounter_Text:SetShadowOffset(1, -1)
Store.SPCounter_Text:SetText("0")
Store.SPCounter_Text:SetJustifyH("CENTER")

Store.DPCounter_Text = Store:CreateFontString("StoreCollectionFrameDPCounter_Text")
Store.DPCounter_Text:SetFontObject(NumberFontNormal)
Store.DPCounter_Text:SetPoint("CENTER", -12, 204.5)
Store.DPCounter_Text:SetShadowOffset(1, -1)
Store.DPCounter_Text:SetText("0")
Store.DPCounter_Text:SetJustifyH("CENTER")

Store.SPCounterHintButton = CreateFrame("Button", "$parentSPCounterHintButton", Store, nil)
Store.SPCounterHintButton:SetWidth(38)
Store.SPCounterHintButton:SetHeight(38)
Store.SPCounterHintButton:SetPoint("CENTER", -147.5, 210)
Store.SPCounterHintButton:RegisterForClicks("AnyUp")
Store.SPCounterHintButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
Store.SPCounterHintButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:SetHyperlink("item:" .. ItemData.SEASONAL_POINTS)
	GameTooltip:Show()
end)

Store.SPCounterHintButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
	
Store.SPCounterHintButton:SetScript("OnClick", function()
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
	OpenStoreCollectionToCategory(Enum.VanityCategory.Seasonal)
end)

Store.DPCounterHintButton = CreateFrame("Button", "$parentDPCounterHintButton", Store, nil)
Store.DPCounterHintButton:SetWidth(38)
Store.DPCounterHintButton:SetHeight(38)
Store.DPCounterHintButton:SetPoint("CENTER", -49.5, 210)
Store.DPCounterHintButton:RegisterForClicks("AnyUp")
Store.DPCounterHintButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
Store.DPCounterHintButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:SetText("Donation Points", 1, 1, 1)
	GameTooltip:AddLine("Donation Points can be used to purchase vanity items from Ascension.\n\nYou can purchase more at:\n|cffFFFFFFhttps://ascension.gg/|r\nClick to open browser.", 1, 0.82, 0, true)
	GameTooltip:Show()
end)

Store.DPCounterHintButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

Store.DPCounterHintButton:SetScript("OnClick", function()
	PlaySound(SOUNDKIT.UCHATSCROLLBUTTON_70)
	OpenAscensionURL("store/payment/paypal")
end)

Store.StoreTypeList = CreateFrame("Button", "$parentDropdown", Store, "FilterDropDownMenuTemplate")
Store.StoreTypeList:SetPoint("TOPRIGHT", Store, "TOPRIGHT", -28, -34)

local function ResetFilter(group, clearKnown)
	for _, data in ipairs(group) do
		if data.children then
			ResetFilter(data.children)
		end

		if data.checked and (data.name ~= CA_FILTER_KNOWN or clearKnown) then
			data.checked = false
		end
	end
end

local function IsAnyFilterChecked(group)
	local checked = false
	for _, data in ipairs(group) do
		if data.children then
			checked = IsAnyFilterChecked(data.children)
			if checked then
				break
			end
		end

		if data.checked then
			checked = true
			break
		end
	end

	return checked
end

local function AreAllFiltersChecked(group)
	for _, data in ipairs(group) do
		if data.children then
			if not AreAllFiltersChecked(data.children) then
				return false
			end
		end

		if data.flag and not data.checked then
			return false
		end
	end

	return true
end

function Store.StoreTypeList:ClearFilters(clearKnown)
	if clearKnown then
		Store.StoreTypeList.Known = false
	end
	ResetFilter(self.List, clearKnown)
	BuildStoreList()
end

Store.StoreTypeList.List = {
	{ name = CA_FILTER_KNOWN, checked = true },
	{ name = ITEM_QUALITY7_SHORT, checked = false },
	{ name = MANASTORM, checked = false },
	{
		name     = APPEARANCES,
		children = {
			{
				name     = WEAPONS,
				children = {
					{ name = ALL, isAll = true },
					{ name = ITEM_SUBCLASS_2_0, flag = Enum.VanityCategory.Weapons.Axe1H },
					{ name = ITEM_SUBCLASS_2_1, flag = Enum.VanityCategory.Weapons.Axe2H },
					{ name = ITEM_SUBCLASS_2_7, flag = Enum.VanityCategory.Weapons.Sword1H },
					{ name = ITEM_SUBCLASS_2_8, flag = Enum.VanityCategory.Weapons.Sword2H },
					{ name = ITEM_SUBCLASS_2_4, flag = Enum.VanityCategory.Weapons.Mace1H },
					{ name = ITEM_SUBCLASS_2_5, flag = Enum.VanityCategory.Weapons.Mace2H },
					{ name = ITEM_SUBCLASS_2_10, flag = Enum.VanityCategory.Weapons.Staff },
					{ name = ITEM_SUBCLASS_2_15, flag = Enum.VanityCategory.Weapons.Dagger },
					{ name = ITEM_SUBCLASS_2_13, flag = Enum.VanityCategory.Weapons.Fist },
					{ name = ITEM_SUBCLASS_4_6, flag = Enum.VanityCategory.Weapons.Shield },
					{ name = INVTYPE_HOLDABLE, flag = Enum.VanityCategory.Weapons.OffHand },
					{ name = ITEM_SUBCLASS_2_6, flag = Enum.VanityCategory.Weapons.Polearm },
					{ name = ITEM_SUBCLASS_2_2, flag = Enum.VanityCategory.Weapons.Bow },
					{ name = ITEM_SUBCLASS_2_3, flag = Enum.VanityCategory.Weapons.Gun },
					{ name = ITEM_SUBCLASS_2_18, flag = Enum.VanityCategory.Weapons.Crossbow },
					{ name = ITEM_SUBCLASS_2_16, flag = Enum.VanityCategory.Weapons.Thrown },
					{ name = ITEM_SUBCLASS_2_19, flag = Enum.VanityCategory.Weapons.Wand },
					{ name = ITEM_SUBCLASS_2_20, flag = Enum.VanityCategory.Weapons.FishingPole },
				}
			},
			{
				name     = ARMOR,
				children = {
					{ name = ALL, isAll = true },
					{ name = INVTYPE_HEAD, flag = Enum.VanityCategory.Armor.Head },
					{ name = INVTYPE_SHOULDER, flag = Enum.VanityCategory.Armor.Shoulder },
					{ name = INVTYPE_CHEST, flag = Enum.VanityCategory.Armor.Chest },
					{ name = INVTYPE_WAIST, flag = Enum.VanityCategory.Armor.Waist },
					{ name = INVTYPE_LEGS, flag = Enum.VanityCategory.Armor.Legs },
					{ name = INVTYPE_FEET, flag = Enum.VanityCategory.Armor.Feet },
					{ name = INVTYPE_WRIST, flag = Enum.VanityCategory.Armor.Wrist },
					{ name = INVTYPE_HANDS, flag = Enum.VanityCategory.Armor.Hands },
					{ name = INVTYPE_CLOAK, flag = Enum.VanityCategory.Armor.Back },
					{ name = ITEM_SUBCLASS_4_1, flag = Enum.VanityCategory.Armor.Cloth },
					{ name = ITEM_SUBCLASS_4_2, flag = Enum.VanityCategory.Armor.Leather },
					{ name = ITEM_SUBCLASS_4_3, flag = Enum.VanityCategory.Armor.Mail },
					{ name = ITEM_SUBCLASS_4_4, flag = Enum.VanityCategory.Armor.Plate },
					{ name = APPEARANCE_TYPE_ITEM_SET, flag = Enum.VanityCategory.Armor.Sets },
				}
			},
			{
				name     = SPELLS,
				children = {
					{ name = ALL, isAll = true },
					{ name = SPELL_VISUALS, flag = Enum.VanityCategory.Spells.Visual },
					{ name = SPELL_EFFECTS, flag = Enum.VanityCategory.Spells.Effect },
					{ name = SPELL_INCARNATIONS, flag = Enum.VanityCategory.Spells.Incarnation },
				}
			},
			{
				name     = ITEM_CLASS_15,
				children = {
					{ name = ALL, isAll = true },
					{ name = INVTYPE_BODY, flag = Enum.VanityCategory.Miscellaneous.Shirt },
					{ name = INVTYPE_TABARD, flag = Enum.VanityCategory.Miscellaneous.Tabard },
					{ name = BACKPACKS, flag = Enum.VanityCategory.Miscellaneous.Backpack },
					{ name = ILLUSIONS, flag = Enum.VanityCategory.Miscellaneous.Illusion },
				}
			},
		}
	},
	{
		name     = TAMED_PETS,
		children = {
			{ name = ALL, isAll = true },
			{ name = COSMETICPETWHISTLESLOT, flag = Enum.VanityCategory.TamedPets.Whistle },
			{ name = COSMETICPETSTONESLOT, flag = Enum.VanityCategory.TamedPets.SummonStone },
			{ name = COSMETICPETVELLUMSLOT, flag = Enum.VanityCategory.TamedPets.Vellum },
			{ name = COSMETICPETWARHORNSLOT, flag = Enum.VanityCategory.TamedPets.Warhorn },
			{ name = COSMETICPETLODESTONESLOT, flag = Enum.VanityCategory.TamedPets.Lodestone },
		}
	},
	{ name = ITEM_CLASS_0, flag = Enum.VanityCategory.Consumable },
	{ name = CONVENIENCE_ITEMS, flag = Enum.VanityCategory.Convenience },
	{ name = MOUNTS, flag = Enum.VanityCategory.Mounts },
	{ name = COSMETIC_PETS, flag = Enum.VanityCategory.Pets },
	{ name = TOYS, flag = Enum.VanityCategory.Toys },
	{ name = SEASONAL, flag = Enum.VanityCategory.Seasonal },
	{ name = AZZAR_FAIRE, flag = Enum.VanityCategory.AzzarFaire },
}

if C_Realm.IsDevelopment() then
	tinsert(Store.StoreTypeList.List, 3, { name = PURCHASABLE, checked = false })
end

Store.StoreTypeList.Flags = 0

function Store.StoreTypeList.Init(self, level, menuList)
	if not level then
		level = 1
	end

	local info = UIDropDownMenu_CreateInfo()
	local menu = Store.StoreTypeList.List

	if level ~= 1 then
		menu = menuList
	end

	if not menu then return end

	for index, data in pairs(menu) do
		if data.children then
			for _, childData in ipairs(data.children) do
				childData.parent = data
			end
		end

		info.text = data.name
		info.disabled = nil
		info.hasArrow = data.children ~= nil
		info.menuList = info.hasArrow and data.children or nil
		info.checked = function()
			if data.name == CA_FILTER_KNOWN then
				return Store.StoreTypeList.Known
			end

			if data.isAll and menu then
				return AreAllFiltersChecked(menu)
			end

			if data.checked then
				return true
			end

			if data.children then
				return IsAnyFilterChecked(data.children)
			end

			return false
		end
		info.keepShownOnClick = true
		info.func = nil

		if data.flag or data.isAll then
			info.func = function(self, arg1, arg2, checked)
				if data.isAll and menu then
					for i, category in ipairs(menu) do
						category.checked = checked
						local parent = self:GetParent()
						local check = _G[parent:GetName() .. "Button" .. i .. "Check"]
						if check then
							check:SetShown(checked)
						end
					end
				end

				data.checked = checked

				if not checked then
					if menu and menu[1].isAll then
						_G[self:GetParent():GetName() .. "Button1Check"]:Hide()
					end
				else
					if menu and menu[1].isAll then
						_G[self:GetParent():GetName() .. "Button1Check"]:SetShown(AreAllFiltersChecked(menu))
					end
				end

				BuildStoreList()

				local parent = data.parent

				while parent do
					if parent.button then
						if checked then
							_G[parent.button:GetName() .. "Check"]:Show()
						elseif not IsAnyFilterChecked(parent.children) then
							_G[parent.button:GetName() .. "Check"]:Hide()
						end
					end
					parent = parent.parent
				end
			end
		elseif data.name == CA_FILTER_KNOWN then
			info.func = function(self, arg1, arg2, checked)
				data.checked = checked
				Store.StoreTypeList.Known = checked
				BuildStoreList()
			end
		elseif data.name == PURCHASABLE then
			info.func = function(self, arg1, arg2, checked)
				data.checked = checked
				Store.StoreTypeList.Purchasable = checked
				BuildStoreList()
			end
		elseif data.name == ITEM_QUALITY7_SHORT then
			info.func = function(self, arg1, arg2, checked)
				data.checked = checked
				Store.StoreTypeList.Heirloom = checked
				BuildStoreList()
			end
		elseif data.name == MANASTORM then
			info.func = function(self, arg1, arg2, checked)
				data.checked = checked
				Store.StoreTypeList.Manastorm = checked
				BuildStoreList()
			end
		elseif data.children then
			info.func = function(self)
				_G[self:GetName() .. "Check"]:SetShown(IsAnyFilterChecked(data.children))
			end
		end

		UIDropDownMenu_AddButton(info, level)

		local listName = "DropDownList" .. level
		data.button = _G[listName .. "Button" .. _G[listName].numButtons]
	end
end

Store.StoreTypeList:Initialize(Store.StoreTypeList.Init)

Store.ActivateStoreButton = CreateFrame("Button", "$parentActivateStoreButton", Store, "UIPanelButtonTemplate")
Store.ActivateStoreButton:SetWidth(118)
Store.ActivateStoreButton:SetHeight(21)
Store.ActivateStoreButton:SetPoint("BOTTOMLEFT", 180, 37)
Store.ActivateStoreButton:RegisterForClicks("AnyUp")
Store.ActivateStoreButton:SetText(VANITY_DELIVER)
Store.ActivateStoreButton:Disable()
Store.ActivateStoreButton:SetScript("OnMouseDown", ActivateItem)

Store.BuyStoreButton = CreateFrame("Button", "$parentBuyStoreButton", Store, "UIPanelButtonTemplate")
Store.BuyStoreButton:SetWidth(118)
Store.BuyStoreButton:SetHeight(21)
Store.BuyStoreButton:SetPoint("BOTTOMLEFT", 62, 37)
Store.BuyStoreButton:RegisterForClicks("AnyUp")
Store.BuyStoreButton:SetText(VANITY_PURCHASE)
Store.BuyStoreButton:Disable()
Store.BuyStoreButton:SetMotionScriptsWhileDisabled(true)
Store.BuyStoreButton:SetScript("OnClick", function(self)
	if Store.ItemInternal and Store.ItemInternal ~= 0 then
		local item = Item:CreateFromID(Store.ItemInternal)
		
		item:ContinueOnLoad(function(itemID)
			if Store.ItemInternal == itemID then
				Store:TryPurchaseSelectedItem()
			end
		end)
	end
end)

Store.BuyStoreButton:SetScript("OnEnter", function(self)
	local item = Store.ItemInternal and GetVanityItemCached(Store.ItemInternal)
	if item then
		if (item.spCost > 0) and not(IsSeasonalCollectionUnlocked()) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local passName = GetInstantItemLink(ItemData.SEASONAL_PASS)
			GameTooltip:AddLine(LOCKED_WITH_ITEM:format(passName), 1, 1, 1, 1)
			GameTooltip:AddLine(VISIT_SEASONAL_COLLECTION_TO_UNLOCK, 1, 0.82, 0, true)
			GameTooltip:AddLine(ITEM_ALSO_AVAILABLE_ON_AUCTIONHOUSE:format(passName), 1, 0.82, 0, true)
			GameTooltip:Show()
		end
	end
end)

Store.BuyStoreButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
-------------------------------------------------------------------------------
--                              Left side frame                              --
-------------------------------------------------------------------------------
Store.Banner = CreateFrame("FRAME", "$parentBanner", Store, nil)
Store.Banner:SetPoint("TOP", -235, -65)
Store.Banner:SetSize(280, 55)
Store.Banner:Hide()
Store.Banner:EnableMouse(true)

Store.Banner:SetScript("OnUpdate", function()
	if not (Store.Banner.HighlightTex.AnimG:IsPlaying()) then
		Store.Banner.HighlightTex.AnimG:Play()
	end
end)

Store.Banner:SetScript("OnMouseDown", LoadItemFromBanner)

Store.Banner.HighlightTex = Store.Banner:CreateTexture(nil, "BACKGROUND")
Store.Banner.HighlightTex:SetSize(140, 140)
Store.Banner.HighlightTex:SetTexture(Addon.AwTexPath .. "Collections\\DragonHighlight")
Store.Banner.HighlightTex:SetPoint("LEFT", -39, 0)
Store.Banner.HighlightTex:SetBlendMode("ADD")

Store.Banner.HighlightTex.AnimG = Store.Banner.HighlightTex:CreateAnimationGroup()
Store.Banner.HighlightTex.AnimG.Rotation = Store.Banner.HighlightTex.AnimG:CreateAnimation("Rotation")
Store.Banner.HighlightTex.AnimG.Rotation:SetDuration(20)
Store.Banner.HighlightTex.AnimG.Rotation:SetOrder(1)
Store.Banner.HighlightTex.AnimG.Rotation:SetEndDelay(0)
Store.Banner.HighlightTex.AnimG.Rotation:SetSmoothing("NONE")
Store.Banner.HighlightTex.AnimG.Rotation:SetDegrees(360)

Store.Banner.Glow = CreateFrame("Model", nil, Store.Banner)
Store.Banner.Glow:SetWidth(256);
Store.Banner.Glow:SetHeight(256);
Store.Banner.Glow:SetPoint("LEFT", -90, -5)
Store.Banner.Glow:SetModel("World\\Kalimdor\\silithus\\passivedoodads\\ahnqirajglow\\quirajglow.m2")
Store.Banner.Glow:SetModelScale(0.01)
Store.Banner.Glow:SetCamera(0)
Store.Banner.Glow:SetPosition(0.075, 0.09, 0)
Store.Banner.Glow:SetFacing(0)

Store.Banner.Icon = Store.Banner:CreateTexture(nil, "ARTWORK")
Store.Banner.Icon:SetSize(40, 40)
Store.Banner.Icon:SetTexture("Interface\\icons\\FoxMountIcon")
Store.Banner.Icon:SetPoint("LEFT", 10, 0)

Store.Banner.TitleText = Store.Banner:CreateFontString("$parentTitleText")
Store.Banner.TitleText:SetFont("Fonts\\FRIZQT__.ttf", 22)
Store.Banner.TitleText:SetFontObject(GameFontHighlight)
Store.Banner.TitleText:SetPoint("TOP", Store.Banner, "TOPLEFT", 164.5, -9)
Store.Banner.TitleText:SetShadowOffset(0, -1)
Store.Banner.TitleText:SetSize(220, 23)
Store.Banner.TitleText:SetText("MISTY FOX")
Store.Banner.TitleText:SetJustifyH("LEFT")

Store.Banner.DescText = Store.Banner:CreateFontString("$parentDescText")
Store.Banner.DescText:SetFont("Fonts\\FRIZQT__.ttf", 12)
Store.Banner.DescText:SetFontObject(GameFontNormal)
Store.Banner.DescText:SetPoint("TOP", Store.Banner, "TOPLEFT", 168.5, -31)
Store.Banner.DescText:SetShadowOffset(1, -1)
Store.Banner.DescText:SetSize(225, 13)
Store.Banner.DescText:SetText("YOU WON'T EVER GET LOST")
Store.Banner.DescText:SetJustifyH("LEFT")

Store.Banner.AnimationGroup = Store.Banner:CreateAnimationGroup()
Store.Banner.AnimationGroup.Rotation = Store.Banner.AnimationGroup:CreateAnimation("Translation")
Store.Banner.AnimationGroup.Rotation:SetStartDelay(0.15)
Store.Banner.AnimationGroup.Rotation:SetDuration(0)
Store.Banner.AnimationGroup.Rotation:SetOrder(1)
Store.Banner.AnimationGroup.Rotation:SetEndDelay(0)
Store.Banner.AnimationGroup.Rotation:SetSmoothing("OUT")
Store.Banner.AnimationGroup.Rotation:SetOffset(0, 30)

Store.Banner.AnimationGroup.Rotation2 = Store.Banner.AnimationGroup:CreateAnimation("Translation")
Store.Banner.AnimationGroup.Rotation2:SetDuration(1.2)
Store.Banner.AnimationGroup.Rotation2:SetOrder(2)
Store.Banner.AnimationGroup.Rotation2:SetEndDelay(15)
Store.Banner.AnimationGroup.Rotation2:SetSmoothing("OUT")
Store.Banner.AnimationGroup.Rotation2:SetOffset(0, -30)

Store.Banner.AnimationGroup.Rotation3 = Store.Banner.AnimationGroup:CreateAnimation("Translation")
Store.Banner.AnimationGroup.Rotation3:SetDuration(1.2)
Store.Banner.AnimationGroup.Rotation3:SetOrder(3)
Store.Banner.AnimationGroup.Rotation3:SetEndDelay(0)
Store.Banner.AnimationGroup.Rotation3:SetSmoothing("OUT")
Store.Banner.AnimationGroup.Rotation3:SetOffset(0, -30)

Store.Banner.AnimationGroup.Rotation3:SetScript("OnPlay", function()
	Addon:BaseFrameFadeOut(Store.Banner)
end)

Store.Paper = CreateFrame("FRAME", "$parentPaper", Store, nil)
Store.Paper:SetPoint("CENTER", -235, -41)
Store.Paper:SetSize(280, 305)

Store.Paper_fake = CreateFrame("FRAME", "$parentPaperFake", Store, nil)
Store.Paper_fake:SetPoint("CENTER", -235, -41)
Store.Paper_fake:SetSize(280, 305)
Store.Paper_fake:SetFrameLevel(Store.Paper:GetFrameLevel() + 1)

Store.Paper.Icon = CreateFrame("Button", "$parentIcon", Store.Paper_fake, nil)
Store.Paper.Icon:SetSize(40, 40)
Store.Paper.Icon:SetFrameLevel(Store.Paper:GetFrameLevel() + 2)
Store.Paper.Icon:SetPoint("BOTTOMLEFT", 14, 28)
Store.Paper.Icon:EnableMouse(true)
Store.Paper.Icon:SetNormalTexture("Interface\\icons\\FoxMountIcon")
Store.Paper.Icon:SetHighlightTexture("Interface\\BUTTONS\\ButtonHilight-Square")
Store.Paper.Icon:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink("item:" .. Store.ItemInternal .. ":0:0:0:0:0:0:0")
	GameTooltip:Show()
end)
Store.Paper.Icon:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
Store.Paper.Icon:Hide()

Store.Paper.ItemPreview = CreateFrame("Button", "$parentItemPreview", Store.Paper, nil)
Store.Paper.ItemPreview:SetSize(46, 46)
Store.Paper.ItemPreview:SetPoint("BOTTOMLEFT", 28, 10)
Store.Paper.ItemPreview:EnableMouse(true)
Store.Paper.ItemPreview:SetFrameLevel(Store.Paper:GetFrameLevel() + 10)
Store.Paper.ItemPreview:SetNormalTexture(Addon.AwTexPath .. "Collections\\PreviewButton")
Store.Paper.ItemPreview:SetHighlightTexture(Addon.AwTexPath .. "Collections\\PreviewButton_H")
Store.Paper.ItemPreview:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(PREVIEW_ITEMS, 1, 1, 1)
	GameTooltip:AddLine(PREVIEW_ITEMS_TOOLTIP, 1, 0.82, 0, true)
	GameTooltip:Show()
end)

Store.Paper.ItemPreview:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

Store.Paper.ItemPreview:SetScript("OnClick", function(self)
	StaticPopup_Hide("VANITY_PURCHASE")
	StaticPopup_Hide("VANITY_PURCHASE_MULTI")
	if not (Store.ModelPreview_fake:IsVisible()) then
		StoreCollectionShowModelPreview()
	else
		StoreCollectionHideModelPreview()
	end
end)

Store.Paper.ItemPreview:Hide()

Store.Paper.ItemPreview.HighLightAnimTex = Store.Paper:CreateTexture(nil, "OVERLAY")
Store.Paper.ItemPreview.HighLightAnimTex:SetSize(46, 46)
Store.Paper.ItemPreview.HighLightAnimTex:SetPoint("BOTTOMLEFT", 28, 10)
Store.Paper.ItemPreview.HighLightAnimTex:SetTexture(Addon.AwTexPath .. "Collections\\PreviewButton_H")
Store.Paper.ItemPreview.HighLightAnimTex:SetAlpha(0)
Store.Paper.ItemPreview.HighLightAnimTex:SetBlendMode("ADD")

Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup = Store.Paper.ItemPreview.HighLightAnimTex:CreateAnimationGroup()

Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha1 = Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup:CreateAnimation("Alpha")
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha1:SetDuration(0.3)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha1:SetStartDelay(0)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha1:SetOrder(1)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha1:SetChange(1)

Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha2 = Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup:CreateAnimation("Alpha")
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha2:SetDuration(0.7)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha2:SetStartDelay(0)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha2:SetOrder(2)
Store.Paper.ItemPreview.HighLightAnimTex.AnimationGroup.Alpha2:SetChange(-1)

Store.Paper.BorderTex = Store.Paper:CreateTexture(nil, "OVERLAY")
Store.Paper.BorderTex:SetSize(128, 64)
Store.Paper.BorderTex:SetPoint("BOTTOMLEFT", -30, 12)
Store.Paper.BorderTex:SetTexture(Addon.AwTexPath .. "progress\\LearnedSpell_TextureNormal")
Store.Paper.BorderTex:Hide()

Store.Paper.ArtWork = Store.Paper:CreateTexture(nil, "BACKGROUND")
Store.Paper.ArtWork:SetSize(256, 256)
Store.Paper.ArtWork:SetTexture(Store.DefaultArtworkTexture)
Store.Paper.ArtWork:SetPoint("CENTER", 0, 25)

Store.Paper.ModelPreview = CreateFrame("DressUpModel", "$parentModelPreview", Store.Paper)
Store.Paper.ModelPreview.MaxSize = 1.2
Store.Paper.ModelPreview.MinSize = 0.6
Store.Paper.ModelPreview.Creature = 101230
Store.Paper.ModelPreview.DefaultSize = 1
Store.Paper.ModelPreview.DefaultFacing = 0.75

Store.Paper.ModelPreview:SetSize(256, 216)
Store.Paper.ModelPreview:SetPoint("CENTER", 0, 25)
Store.Paper.ModelPreview:SetCreature(Store.Paper.ModelPreview.Creature)
Store.Paper.ModelPreview:RefreshUnit()
Store.Paper.ModelPreview:SetFacing(Store.Paper.ModelPreview.DefaultFacing)
Store.Paper.ModelPreview:SetCamera(1)
Store.Paper.ModelPreview:SetLight(1, 0, 0, -0.707, -0.707, 0.7, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 0.8)
Store.Paper.ModelPreview:SetModelScale(Store.Paper.ModelPreview.DefaultSize)
Store.Paper.ModelPreview:Hide()

Store.Paper.ModelPreview.ClickHandler = CreateFrame("Frame", nil, Store.Paper.ModelPreview)
Store.Paper.ModelPreview.ClickHandler:SetAllPoints()
Store.Paper.ModelPreview.ClickHandler:EnableMouse(true)
Store.Paper.ModelPreview.ClickHandler:EnableMouseWheel(true)

Store.Paper.ModelPreview.ClickHandler:SetScript("OnUpdate", function(self)
	if self.StartX then
		local x = GetCursorPosition()
		local diff = (x - self.StartX) * 0.01
		self.StartX = x
		self:GetParent():SetFacing(self:GetParent():GetFacing() + diff)
	end
end)

Store.Paper.ModelPreview.ClickHandler:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		self.StartX = GetCursorPosition()
	end
end)

Store.Paper.ModelPreview.ClickHandler:SetScript("OnMouseUp", function(self, button)
	if button == "LeftButton" then
		self.StartX = nil
	end
end)

Store.Paper.ModelPreview.ClickHandler:SetScript("OnMouseWheel", function(self, delta)
	local preview = self:GetParent()
	local scale = preview:GetModelScale()
	if scale >= preview.MaxSize and delta > 0 then
		return
	end

	if scale <= preview.MinSize and delta < 0 then
		return
	end

	preview:SetModelScale(scale + (delta * 0.05))
end)

Store.Paper.ModelPreview.Update = function(self)
	PaperModelPreviewInitModel(self)
	PaperModelPreviewLoadItems()
end

Store.Paper.ModelPreview:SetScript("OnShow", function(self)
	self:Update()
end)

Store.Paper.ModelPreview:SetScript("OnHide", function(self)
	self:Update()
end)

Store.Paper.GoldBG = Store.Paper:CreateTexture(nil, "BACKGROUND")
Store.Paper.GoldBG:SetTexture("Interface\\LevelUp\\LevelUpTex")
Store.Paper.GoldBG:SetSize(223, 115)
Store.Paper.GoldBG:SetPoint("BOTTOM", 0, 16)
Store.Paper.GoldBG:SetTexCoord(0.56054688, 0.99609375, 0.24218750, 0.46679688)
Store.Paper.GoldBG:SetVertexColor(1, 1, 1, 0)

Store.Paper.Texture = Store.Paper:CreateTexture(nil, "BACKGROUND", nil, 2)
Store.Paper.Texture:SetTexture("Interface\\LevelUp\\LevelUpTex")
Store.Paper.Texture:SetSize(284, 115)
Store.Paper.Texture:SetPoint("BOTTOM", 0, 14)
Store.Paper.Texture:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
Store.Paper.Texture:SetVertexColor(1, 1, 1, 0.6)

Store.Paper.LineUp = Store.Paper:CreateTexture(nil, "BORDER", nil, 2)
Store.Paper.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
Store.Paper.LineUp:SetSize(264, 7)
Store.Paper.LineUp:SetPoint("BOTTOM", 0, 75)
Store.Paper.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
Store.Paper.LineUp:SetVertexColor(1, 1, 1)

Store.Paper.LineDown = Store.Paper:CreateTexture(nil, "BORDER", nil, 2)
Store.Paper.LineDown:SetTexture("Interface\\LevelUp\\LevelUpTex")
Store.Paper.LineDown:SetSize(264, 7)
Store.Paper.LineDown:SetPoint("BOTTOM", 0, 14)
Store.Paper.LineDown:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
Store.Paper.LineDown:SetVertexColor(1, 1, 1)

local paperOverlayFrame = CreateFrame("Frame", nil, Store.Paper)
paperOverlayFrame:SetAllPoints()
paperOverlayFrame:SetFrameLevel(Store.Paper.ModelPreview:GetFrameLevel() + 1)

Store.Paper.DescText = paperOverlayFrame:CreateFontString(nil, "OVERLAY")
Store.Paper.DescText:SetFont("Fonts\\FRIZQT__.TTF", 11)
Store.Paper.DescText:SetFontObject(GameFontHighlight)
Store.Paper.DescText:SetPoint("BOTTOM", 0, 22)
Store.Paper.DescText:SetShadowOffset(0, -1)
Store.Paper.DescText:SetSize(160, 50)
Store.Paper.DescText:SetText(VANITY_WELCOME_SUBTEXT)

Store.Paper.TitleText = paperOverlayFrame:CreateFontString(nil, "OVERLAY")
Store.Paper.TitleText:SetFontObject(GameFontNormal)
Store.Paper.TitleText:SetFont("Fonts\\MORPHEUS.TTF", 18)
Store.Paper.TitleText:SetPoint("BOTTOM", Store.Paper.DescText, "TOP", 0, 4)
Store.Paper.TitleText:SetShadowOffset(1, -1)
Store.Paper.TitleText:SetSize(270, 0)
Store.Paper.TitleText:SetText(VANITY_WELCOME)

Store.Paper.CostText = paperOverlayFrame:CreateFontString("$parentCostText")
Store.Paper.CostText:SetFontObject("PTFontHighlightOutline3")
Store.Paper.CostText:SetPoint("BOTTOM", Store.Paper.TitleText, "TOP", 0, 8)
Store.Paper.CostText:SetSize(0, 18)

Store.Paper.CostIcon = paperOverlayFrame:CreateTexture("$parentCostIcon", "OVERLAY")
Store.Paper.CostIcon:SetPoint("RIGHT", Store.Paper.CostText, "LEFT", 0, -1)
Store.Paper.CostIcon:SetSize(16, 16)

Store.Paper.CostText2 = paperOverlayFrame:CreateFontString("$parentCostText2")
Store.Paper.CostText2:SetFontObject("PTFontHighlightOutline3")
Store.Paper.CostText2:SetPoint("BOTTOM", Store.Paper.CostText, "TOP", 0, 0)
Store.Paper.CostText2:SetSize(0, 18)

Store.Paper.CostIcon2 = paperOverlayFrame:CreateTexture("$parentCostIcon2", "OVERLAY")
Store.Paper.CostIcon2:SetPoint("RIGHT", Store.Paper.CostText2, "LEFT", 0, -1)
Store.Paper.CostIcon2:SetSize(16, 16)

Store.Paper.Texture.AnimationGroup = Store.Paper.Texture:CreateAnimationGroup()
Store.Paper.Texture.AnimationGroup.Grow = Store.Paper.Texture.AnimationGroup:CreateAnimation("Scale")
Store.Paper.Texture.AnimationGroup.Grow:SetScale(1.0, 0.001)
Store.Paper.Texture.AnimationGroup.Grow:SetDuration(0.0)
Store.Paper.Texture.AnimationGroup.Grow:SetStartDelay(0)
Store.Paper.Texture.AnimationGroup.Grow:SetOrder(1)
Store.Paper.Texture.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

Store.Paper.Texture.AnimationGroup.Grow = Store.Paper.Texture.AnimationGroup:CreateAnimation("Scale")
Store.Paper.Texture.AnimationGroup.Grow:SetScale(1.0, 1000.0)
Store.Paper.Texture.AnimationGroup.Grow:SetDuration(0.15)
Store.Paper.Texture.AnimationGroup.Grow:SetStartDelay(0.15)
Store.Paper.Texture.AnimationGroup.Grow:SetOrder(2)
Store.Paper.Texture.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

Store.Paper.LineUp.AnimationGroup = Store.Paper.LineUp:CreateAnimationGroup()
Store.Paper.LineUp.AnimationGroup.Grow = Store.Paper.LineUp.AnimationGroup:CreateAnimation("Scale")
Store.Paper.LineUp.AnimationGroup.Grow:SetScale(0.001, 1.0)
Store.Paper.LineUp.AnimationGroup.Grow:SetDuration(0.0)
Store.Paper.LineUp.AnimationGroup.Grow:SetStartDelay(0.15)
Store.Paper.LineUp.AnimationGroup.Grow:SetOrder(1)
Store.Paper.LineUp.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

Store.Paper.LineUp.AnimationGroup.Grow = Store.Paper.LineUp.AnimationGroup:CreateAnimation("Scale")
Store.Paper.LineUp.AnimationGroup.Grow:SetScale(1000.0, 1.0)
Store.Paper.LineUp.AnimationGroup.Grow:SetDuration(0.5)
Store.Paper.LineUp.AnimationGroup.Grow:SetOrder(2)
Store.Paper.LineUp.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

Store.Paper.LineDown.AnimationGroup = Store.Paper.LineDown:CreateAnimationGroup()
Store.Paper.LineDown.AnimationGroup.Grow = Store.Paper.LineDown.AnimationGroup:CreateAnimation("Scale")
Store.Paper.LineDown.AnimationGroup.Grow:SetScale(0.001, 1.0)
Store.Paper.LineDown.AnimationGroup.Grow:SetDuration(0.0)
Store.Paper.LineDown.AnimationGroup.Grow:SetStartDelay(0.15)
Store.Paper.LineDown.AnimationGroup.Grow:SetOrder(1)
Store.Paper.LineDown.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

Store.Paper.LineDown.AnimationGroup.Grow = Store.Paper.LineDown.AnimationGroup:CreateAnimation("Scale")
Store.Paper.LineDown.AnimationGroup.Grow:SetScale(1000.0, 1.0)
Store.Paper.LineDown.AnimationGroup.Grow:SetDuration(0.5)
Store.Paper.LineDown.AnimationGroup.Grow:SetOrder(2)
Store.Paper.LineDown.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)
Store.Paper.LineDown.AnimationGroup.Grow:SetScript("OnPlay", function()
	Store.Paper.Texture.AnimationGroup:Stop();
	Store.Paper.LineUp.AnimationGroup:Stop();

	Store.Paper.Texture.AnimationGroup:Play();
	Store.Paper.LineUp.AnimationGroup:Play();
end)
-------------------------------------------------------------------------------
--                             Collection itself                             --
-------------------------------------------------------------------------------

Store.CollectionList = CreateFrame("FRAME", "$parentCollectionList", Store, nil)
Store.CollectionList:SetPoint("CENTER", 150, -15)
Store.CollectionList:SetSize(470, 425)
Store.CollectionList:EnableMouseWheel(true)

Store.CollectionList:SetScript("OnMouseWheel", function(self, delta)
	if (Store.CollectionList.PrevButton:IsEnabled() == 1) and (delta == 1) then
		StoreCollectionListPrevPage(Store.CollectionList.PrevButton)
	elseif (Store.CollectionList.NextButton:IsEnabled() == 1) and (delta == -1) then
		StoreCollectionListNextPage(Store.CollectionList.NextButton)
	end
end)

Store.CollectionList.Glow = CreateFrame("Model", nil, Store.CollectionList)
Store.CollectionList.Glow:SetSize(470, 425)
Store.CollectionList.Glow:SetPoint("CENTER", 0, 0)
Store.CollectionList.Glow:SetModel("World\\Kalimdor\\orgrimmar\\passivedoodads\\orgrimmarbonfire\\orgrimmarfloatingembers.m2")
Store.CollectionList.Glow:SetModelScale(0.1)
Store.CollectionList.Glow:SetCamera(0)
Store.CollectionList.Glow:SetPosition(0.085, 0.21, 0)
Store.CollectionList.Glow:SetFacing(0)

Store.CollectionList.Glow2 = CreateFrame("Model", nil, Store.CollectionList)
Store.CollectionList.Glow2:SetSize(470, 425)
Store.CollectionList.Glow2:SetPoint("CENTER", 0, 0)
Store.CollectionList.Glow2:SetModel("World\\Kalimdor\\orgrimmar\\passivedoodads\\orgrimmarbonfire\\orgrimmarfloatingembers.m2")
Store.CollectionList.Glow2:SetModelScale(0.1)
Store.CollectionList.Glow2:SetCamera(0)
Store.CollectionList.Glow2:SetPosition(0.085, 0.21, 0)
Store.CollectionList.Glow2:SetFacing(0)

Store.CollectionList.TitleText = Store.CollectionList:CreateFontString("StoreCollectionListFrameTitleText")
Store.CollectionList.TitleText:SetFont("Fonts\\MORPHEUS.TTF", 14)
Store.CollectionList.TitleText:SetFontObject(GameFontNormal)
Store.CollectionList.TitleText:SetPoint("TOP", 0, -32)
Store.CollectionList.TitleText:SetShadowOffset(0, -1)
Store.CollectionList.TitleText:SetText(VANITY_ITEM_COLLECTION)

Store.CollectionList.PageText = Store.CollectionList:CreateFontString("StoreCollectionListFrameTitleText")
Store.CollectionList.PageText:SetFont("Fonts\\FRIZQT__.TTF", 12)
Store.CollectionList.PageText:SetFontObject(GameFontHighlight)
Store.CollectionList.PageText:SetPoint("BOTTOM", 0, 15)
Store.CollectionList.PageText:SetShadowOffset(0, -1)
Store.CollectionList.PageText:SetText("Page 1/1")

Store.CollectionList.NextButton = CreateFrame("Button", nil, Store.CollectionList, nil)
Store.CollectionList.NextButton:SetSize(26, 26)
Store.CollectionList.NextButton:SetPoint("BOTTOM", 150, 12)
Store.CollectionList.NextButton:EnableMouse(true)
Store.CollectionList.NextButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
Store.CollectionList.NextButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
Store.CollectionList.NextButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
Store.CollectionList.NextButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
Store.CollectionList.NextButton:SetScript("OnClick", StoreCollectionListNextPage)

Store.CollectionList.PrevButton = CreateFrame("Button", nil, Store.CollectionList, nil)
Store.CollectionList.PrevButton:SetSize(26, 26)
Store.CollectionList.PrevButton:SetPoint("BOTTOM", -150, 12)
Store.CollectionList.PrevButton:EnableMouse(true)
Store.CollectionList.PrevButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
Store.CollectionList.PrevButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
Store.CollectionList.PrevButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
Store.CollectionList.PrevButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
Store.CollectionList.PrevButton:SetScript("OnClick", StoreCollectionListPrevPage)

StoreCollectionItemFrame1 = CreateFrame("FRAME", "StoreCollectionItemFrame1", Store.CollectionList, nil)
StoreCollectionItemFrame1:SetPoint("CENTER", -152, 95)
StoreCollectionItemFrame1:SetSize(256, 128)

StoreCollectionItemFrame2 = CreateFrame("FRAME", "StoreCollectionItemFrame2", Store.CollectionList, nil)
StoreCollectionItemFrame2:SetPoint("CENTER", -2, 95)
StoreCollectionItemFrame2:SetSize(256, 128)

StoreCollectionItemFrame3 = CreateFrame("FRAME", "StoreCollectionItemFrame3", Store.CollectionList, nil)
StoreCollectionItemFrame3:SetPoint("CENTER", 148, 95)
StoreCollectionItemFrame3:SetSize(256, 128)

StoreCollectionItemFrame4 = CreateFrame("FRAME", "StoreCollectionItemFrame4", Store.CollectionList, nil)
StoreCollectionItemFrame4:SetPoint("CENTER", -152, -11)
StoreCollectionItemFrame4:SetSize(256, 128)

StoreCollectionItemFrame5 = CreateFrame("FRAME", "StoreCollectionItemFrame5", Store.CollectionList, nil)
StoreCollectionItemFrame5:SetPoint("CENTER", -2, -11)
StoreCollectionItemFrame5:SetSize(256, 128)

StoreCollectionItemFrame6 = CreateFrame("FRAME", "StoreCollectionItemFrame6", Store.CollectionList, nil)
StoreCollectionItemFrame6:SetPoint("CENTER", 148, -11)
StoreCollectionItemFrame6:SetSize(256, 128)

StoreCollectionItemFrame7 = CreateFrame("FRAME", "StoreCollectionItemFrame7", Store.CollectionList, nil)
StoreCollectionItemFrame7:SetPoint("CENTER", -152, -117)
StoreCollectionItemFrame7:SetSize(256, 128)

StoreCollectionItemFrame8 = CreateFrame("FRAME", "StoreCollectionItemFrame8", Store.CollectionList, nil)
StoreCollectionItemFrame8:SetPoint("CENTER", -2, -117)
StoreCollectionItemFrame8:SetSize(256, 128)

StoreCollectionItemFrame9 = CreateFrame("FRAME", "StoreCollectionItemFrame9", Store.CollectionList, nil)
StoreCollectionItemFrame9:SetPoint("CENTER", 148, -117)
StoreCollectionItemFrame9:SetSize(256, 128)

for i = 1, 9 do
	_G["StoreCollectionItemFrame" .. i .. ".BackgroundTexture"] = _G["StoreCollectionItemFrame" .. i]:CreateTexture(nil,
	                                                                                                                "BACKGROUND")
	_G["StoreCollectionItemFrame" .. i .. ".BackgroundTexture"]:SetSize(_G["StoreCollectionItemFrame" .. i]:GetSize())
	_G["StoreCollectionItemFrame" .. i .. ".BackgroundTexture"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreButtonBG")
	_G["StoreCollectionItemFrame" .. i .. ".BackgroundTexture"]:SetPoint("CENTER")

	_G["StoreCollectionItemFrame" .. i .. ".Button"] = CreateFrame("Button", nil, _G["StoreCollectionItemFrame" .. i],
	                                                               nil)
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:SetSize(131, 99)
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:SetPoint("CENTER", 0, 0)
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:EnableMouse(true)
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:SetHighlightTexture(Addon.AwTexPath .. "Collections\\StoreButtonBG_Highlight")
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:GetHighlightTexture():ClearAllPoints()
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:GetHighlightTexture():SetPoint("CENTER", 0, 0)
	_G["StoreCollectionItemFrame" .. i .. ".Button"]:GetHighlightTexture():SetSize(256, 128)

	_G["StoreCollectionItemFrame" .. i .. ".PrestigeTexture"] = _G["StoreCollectionItemFrame" .. i]:CreateTexture(nil,
	                                                                                                              "ARTWORK")
	_G["StoreCollectionItemFrame" .. i .. ".PrestigeTexture"]:SetSize(92, 92)
	_G["StoreCollectionItemFrame" .. i .. ".PrestigeTexture"]:SetTexture(Addon.AwTexPath .. "Collections\\prestige-icon-4")
	_G["StoreCollectionItemFrame" .. i .. ".PrestigeTexture"]:SetPoint("CENTER", 0, 10)

	_G["StoreCollectionItemFrame" .. i .. ".IconFrame"] = CreateFrame("FRAME", nil, _G["StoreCollectionItemFrame" .. i],
	                                                                  nil)
	_G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:SetPoint("CENTER")
	_G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:SetSize(_G["StoreCollectionItemFrame" .. i]:GetSize())

	_G["StoreCollectionItemFrame" .. i .. ".Icon"] = _G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:CreateTexture(nil,
	                                                                                                                   "BACKGROUND")
	_G["StoreCollectionItemFrame" .. i .. ".Icon"]:SetSize(40, 40)
	_G["StoreCollectionItemFrame" .. i .. ".Icon"]:SetTexture("Interface\\icons\\FoxMountIcon")
	_G["StoreCollectionItemFrame" .. i .. ".Icon"]:SetPoint("CENTER", 0, 11)
	SetPortraitToTexture(_G["StoreCollectionItemFrame" .. i .. ".Icon"], "Interface\\icons\\FoxMountIcon")

	_G["StoreCollectionItemFrame" .. i .. ".RoundBG"] = _G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:CreateTexture(nil,
	                                                                                                                      "BACKGROUND")
	_G["StoreCollectionItemFrame" .. i .. ".RoundBG"]:SetSize(128, 64)
	_G["StoreCollectionItemFrame" .. i .. ".RoundBG"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreCollectionRoundBG")
	_G["StoreCollectionItemFrame" .. i .. ".RoundBG"]:SetPoint("CENTER", 0, 10)

	_G["StoreCollectionItemFrame" .. i .. ".Circle"] = _G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:CreateTexture(nil,
	                                                                                                                     "ARTWORK")
	_G["StoreCollectionItemFrame" .. i .. ".Circle"]:SetSize(64, 64)
	_G["StoreCollectionItemFrame" .. i .. ".Circle"]:SetTexture(Addon.AwTexPath .. "Collections\\StoreCollectionRound")
	_G["StoreCollectionItemFrame" .. i .. ".Circle"]:SetPoint("CENTER", 0, 10)

	_G["StoreCollectionItemFrame" .. i .. ".GroupIcon"] = _G["StoreCollectionItemFrame" .. i .. ".IconFrame"]:CreateTexture(nil,
	                                                                                                                        "OVERLAY")
	_G["StoreCollectionItemFrame" .. i .. ".GroupIcon"]:SetSize(40, 40)
	_G["StoreCollectionItemFrame" .. i .. ".GroupIcon"]:SetTexture(Addon.AwTexPath .. "Collections\\category-icon-featured")
	_G["StoreCollectionItemFrame" .. i .. ".GroupIcon"]:SetPoint("CENTER", 0, -10)

	_G["StoreCollection" .. i .. ".TextNormal"] = _G["StoreCollectionItemFrame" .. i]:CreateFontString("StoreCollection" .. i .. "TextNormal")
	_G["StoreCollection" .. i .. ".TextNormal"]:SetSize(120, 22)
	_G["StoreCollection" .. i .. ".TextNormal"]:SetFont("Fonts\\FRIZQT__.TTF", 11)
	_G["StoreCollection" .. i .. ".TextNormal"]:SetFontObject(GameFontHighlight)
	_G["StoreCollection" .. i .. ".TextNormal"]:SetPoint("CENTER", 0, -30)
	_G["StoreCollection" .. i .. ".TextNormal"]:SetShadowOffset(0, -1)
	_G["StoreCollection" .. i .. ".TextNormal"]:SetText("[Misty Fox]")
	_G["StoreCollection" .. i .. ".TextNormal"]:SetJustifyH("CENTER")
	
	local parent = _G["StoreCollectionItemFrame" .. i]

	local extraCostIcon = parent:CreateTexture("$parentExtraCostIcon", "OVERLAY")
	parent.ExtraCostIcon = extraCostIcon
	extraCostIcon:SetSize(16, 16)
	extraCostIcon:SetPoint("LEFT", parent, "CENTER", -60, 37)
	extraCostIcon:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")
	
	local extraCostText = parent:CreateFontString("$parentExtraCostText", "OVERLAY")
	parent.ExtraCostText = extraCostText
	extraCostText:SetPoint("LEFT", extraCostIcon, "RIGHT", 0, 0)
	extraCostText:SetSize(100, 28)
	extraCostText:SetJustifyH("LEFT")
	extraCostText:SetFontObject("PTFontHighlightOutline3")
	extraCostText:SetText("")

	local extraCostIcon2 = parent:CreateTexture("$parentExtraCostIcon2", "OVERLAY")
	parent.ExtraCostIcon2 = extraCostIcon2
	extraCostIcon2:Hide()
	extraCostIcon2:SetSize(16, 16)
	extraCostIcon2:SetPoint("RIGHT", parent, "CENTER", 60, 37)
	extraCostIcon2:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")

	local extraCostText2 = parent:CreateFontString("$parentExtraCostText2", "OVERLAY")
	parent.ExtraCostText2 = extraCostText2
	extraCostText2:Hide()
	extraCostText2:SetPoint("RIGHT", extraCostIcon2, "LEFT", 0, 0)
	extraCostText2:SetSize(100, 28)
	extraCostText2:SetJustifyH("RIGHT")
	extraCostText2:SetFontObject("PTFontHighlightOutline3")
	extraCostText2:SetText("")

	_G["StoreCollectionItemFrame" .. i .. ".Button"]:SetScript("OnClick", function(self)
		PlaySound("igMainMenuOptionCheckBoxOn")
		StaticPopup_Hide("VANITY_PURCHASE")
		StaticPopup_Hide("VANITY_PURCHASE_MULTI")
		local icon = _G["StoreCollectionItemFrame" .. i .. ".Button.Icon"]
		local artwork = _G["StoreCollectionItemFrame" .. i .. ".Button.ArtWork"]
		local artworkModel = _G["StoreCollectionItemFrame" .. i .. ".Button.ArtWorkPreview"]
		local titleText = _G["StoreCollectionItemFrame" .. i .. ".Button.ItemName"]
		local descText = _G["StoreCollectionItemFrame" .. i .. ".Button.ItemDescription"]
		local spCost = _G["StoreCollectionItemFrame" .. i .. ".Button.SeasonalPointsCost"]
		local btCost = _G["StoreCollectionItemFrame" .. i .. ".Button.BazaarTokenCost"]
		local dpCost = _G["StoreCollectionItemFrame" .. i .. ".Button.DonatePointsCost"]
		local itemInternal = _G["StoreCollectionItemFrame" .. i .. ".Button.ItemInternal"]
		local item = _G["StoreCollectionItemFrame" .. i .. ".Button.Item"]
		local previewData = _G["StoreCollectionItemFrame" .. i .. ".Button.PreviewData"]

		if (IsModifiedClick("CHATLINK")) then
			local _, link = GetItemInfo(itemInternal)
			ChatEdit_InsertLink(link)
			return
		end

		Store.Paper.Icon:SetNormalTexture(icon)
		Store.Paper.ArtWork:SetTexture(artwork)
		Store.Paper.TitleText:SetText(titleText)
		Store.Paper.DescText:SetText(descText)
		Store.ItemInternal = itemInternal
		Store.Preview_Current = previewData

		if not (Store.ModelPreview.BGTex:SetTexture(artworkModel)) then
			Store.ModelPreview.BGTex:SetTexture(Store.DefaultPreviewTexture)
		end

		Store.Paper.CostText2:Hide()
		Store.Paper.CostIcon2:Hide()
		if (spCost ~= 0) or (dpCost ~= 0) or (btCost ~= 0) then
			-- show buy option and cost
			Store.SP_Cost_Current = spCost
			Store.BT_Cost_Current = btCost
			Store.DP_Cost_Current = dpCost
			if spCost > 0 then
				Store.Paper.CostText:SetText(spCost)
				Store.Paper.CostIcon:SetTexture("Interface\\icons\\inv_archaeology_70_demon_orbofinnerchaos")
				Store.Paper.CostText:Show()
				Store.Paper.CostIcon:Show()
			elseif btCost > 0 and dpCost > 0 then
				Store.Paper.CostText:SetText(dpCost)
				Store.Paper.CostIcon:SetTexture("Interface\\Store\\dp_icon")
				Store.Paper.CostText:Show()
				Store.Paper.CostIcon:Show()

				Store.Paper.CostText2:SetText(btCost)
				Store.Paper.CostIcon2:SetTexture("Interface\\icons\\Spell_Shadow_Teleport")
				Store.Paper.CostText2:Show()
				Store.Paper.CostIcon2:Show()
			elseif btCost > 0 then
				Store.Paper.CostText:SetText(btCost)
				Store.Paper.CostIcon:SetTexture("Interface\\icons\\Spell_Shadow_Teleport")
				Store.Paper.CostText:Show()
				Store.Paper.CostIcon:Show()
			elseif dpCost > 0 then
				Store.Paper.CostText:SetText(dpCost)
				Store.Paper.CostIcon:SetTexture("Interface\\Store\\dp_icon")
				Store.Paper.CostText:Show()
				Store.Paper.CostIcon:Show()
			else
				Store.Paper.CostText:Hide()
				Store.Paper.CostIcon:Hide()
			end
		else
			Store.Paper.CostText:Hide()
			Store.Paper.CostIcon:Hide()
			Store.BuyStoreButton:Disable()
		end
		local vanityItem = GetVanityItemCached(itemInternal)

		if itemInternal ~= 0 and vanityItem then
			local isOwned = C_VanityCollection.IsCollectionItemOwned(itemInternal)
			if IsSeasonalCollectionUnlocked() and vanityItem.spCost > 0 then
				Store.BuyStoreButton:SetEnabled(vanityItem.spCost <= GetItemCount(ItemData.SEASONAL_POINTS) and not isOwned)
			elseif vanityItem.btCost > 0 and dpCost > 0 then
				Store.BuyStoreButton:SetEnabled(dpCost <= GetAscensionDonationPoints() or vanityItem.btCost <= GetItemCount(ItemData.BAZAAR_TOKENS) and not isOwned)
			elseif vanityItem.btCost > 0 then
				Store.BuyStoreButton:SetEnabled(vanityItem.btCost <= GetItemCount(ItemData.BAZAAR_TOKENS) and not isOwned)
			elseif dpCost > 0 then
				Store.BuyStoreButton:SetEnabled(dpCost <= GetAscensionDonationPoints() and C_Config.GetBoolConfig("CONFIG_WEB_SHOP_ENABLED"))
			else
				Store.BuyStoreButton:Disable()
			end
			Item:CreateFromID(itemInternal):Query()
		else
			Store.BuyStoreButton:Disable()
		end

		if (item ~= 0) and vanityItem then
			Store.ItemSelected = item
			local cannotDeliver = bit.contains(vanityItem.flags, Enum.VanityFlags.CannotBeDelivered)
			Store.ActivateStoreButton:SetEnabled(not cannotDeliver)
		else
			Store.ItemSelected = 0
			Store.ActivateStoreButton:Disable()
			Store.ModelPreview_fake.SpendPoints.MainButton:Disable()
		end

		StoreCollectionHideModelPreview()
		StoreCollectionFrameShowPaper()
	end)

	_G["StoreCollectionItemFrame" .. i]:Hide()
end

local NewItemInCollection = CreateFrame("Button", "StoreNewItemInCollection", UIParent, nil)
NewItemInCollection:SetPoint("CENTER", UIParent, 0, 200)
NewItemInCollection:SetSize(512, 512)
NewItemInCollection:RegisterForClicks("AnyDown")
NewItemInCollection:SetFrameStrata("FULLSCREEN_DIALOG")
NewItemInCollection:Hide()

NewItemInCollection:SetScript("OnClick", function(self)
	tremoveItem(Addon.FramesToFade, self)
	self.Main.AnimationGroup:Stop()
	self.Main.Texture.AnimationGroup:Stop();
	self.Main.LineUp.AnimationGroup:Stop();
	self:Hide()
end)

NewItemInCollection.HighLightOfNewItem = CreateFrame("FRAME", nil, NewItemInCollection, nil)
NewItemInCollection.HighLightOfNewItem:SetPoint("CENTER", NewItemInCollection, 0, 40)
NewItemInCollection.HighLightOfNewItem:SetSize(256, 256)

NewItemInCollection.HighLightOfNewItem.HighlightTex = NewItemInCollection.HighLightOfNewItem:CreateTexture(nil,
                                                                                                           "ARTWORK")
NewItemInCollection.HighLightOfNewItem.HighlightTex:SetSize(256, 256)
NewItemInCollection.HighLightOfNewItem.HighlightTex:SetTexture(Addon.AwTexPath .. "Collections\\DragonHighlight")
NewItemInCollection.HighLightOfNewItem.HighlightTex:SetPoint("CENTER", 0, 0)
NewItemInCollection.HighLightOfNewItem.HighlightTex:SetBlendMode("ADD")

NewItemInCollection.HighLightOfNewItem.Glow = CreateFrame("Model", nil, NewItemInCollection.HighLightOfNewItem)
NewItemInCollection.HighLightOfNewItem.Glow:SetWidth(256);
NewItemInCollection.HighLightOfNewItem.Glow:SetHeight(256);
NewItemInCollection.HighLightOfNewItem.Glow:SetPoint("CENTER", 0, 0)
NewItemInCollection.HighLightOfNewItem.Glow:SetModel("World\\Kalimdor\\silithus\\passivedoodads\\ahnqirajglow\\quirajglow.m2")
NewItemInCollection.HighLightOfNewItem.Glow:SetModelScale(0.02)
NewItemInCollection.HighLightOfNewItem.Glow:SetCamera(0)
NewItemInCollection.HighLightOfNewItem.Glow:SetPosition(0.075, 0.09, 0)
NewItemInCollection.HighLightOfNewItem.Glow:SetFacing(0)

NewItemInCollection.Main = CreateFrame("FRAME", nil, NewItemInCollection, nil)
NewItemInCollection.Main:SetPoint("CENTER", 0, 25)
NewItemInCollection.Main:SetSize(256, 128)
NewItemInCollection.Main:SetAlpha(0)

NewItemInCollection.Main.PrestigeTexture = NewItemInCollection.Main:CreateTexture(nil, "BORDER", nil, 10)
NewItemInCollection.Main.PrestigeTexture:SetSize(92, 92)
NewItemInCollection.Main.PrestigeTexture:SetTexture(Addon.AwTexPath .. "Collections\\prestige-icon-4")
NewItemInCollection.Main.PrestigeTexture:SetPoint("CENTER", 0, 10)

NewItemInCollection.Main.Icon = NewItemInCollection.Main:CreateTexture(nil, "ARTWORK", nil, 2)
NewItemInCollection.Main.Icon:SetSize(40, 40)
NewItemInCollection.Main.Icon:SetTexture("Interface\\icons\\FoxMountIcon")
NewItemInCollection.Main.Icon:SetPoint("CENTER", 0, 11)
SetPortraitToTexture(NewItemInCollection.Main.Icon, "Interface\\icons\\FoxMountIcon")

NewItemInCollection.Main.RoundBG = NewItemInCollection.Main:CreateTexture(nil, "ARTWORK", nil, 2)
NewItemInCollection.Main.RoundBG:SetSize(128, 64)
NewItemInCollection.Main.RoundBG:SetTexture(Addon.AwTexPath .. "Collections\\StoreCollectionRoundBG")
NewItemInCollection.Main.RoundBG:SetPoint("CENTER", 0, 10)

NewItemInCollection.Main.Circle = NewItemInCollection.Main:CreateTexture(nil, "OVERLAY", nil, 1)
NewItemInCollection.Main.Circle:SetSize(64, 64)
NewItemInCollection.Main.Circle:SetTexture(Addon.AwTexPath .. "Collections\\StoreCollectionRound")
NewItemInCollection.Main.Circle:SetPoint("CENTER", 0, 10)

NewItemInCollection.Main.TextAdd = NewItemInCollection.Main:CreateFontString(nil, "OVERLAY")
NewItemInCollection.Main.TextAdd:SetSize(300, 20)
NewItemInCollection.Main.TextAdd:SetFont("Fonts\\FRIZQT__.TTF", 11)
NewItemInCollection.Main.TextAdd:SetFontObject(GameFontNormal)
NewItemInCollection.Main.TextAdd:SetPoint("CENTER", 0, -60)
NewItemInCollection.Main.TextAdd:SetShadowOffset(0, -1)
NewItemInCollection.Main.TextAdd:SetText("|cffFFFFFFYou have successfuly unlocked|r Vanity Item|cffFFFFFF!|r")

NewItemInCollection.Main.TextNormal = NewItemInCollection.Main:CreateFontString(nil, "OVERLAY")
NewItemInCollection.Main.TextNormal:SetSize(300, 20)
NewItemInCollection.Main.TextNormal:SetFont("Fonts\\FRIZQT__.TTF", 14)
NewItemInCollection.Main.TextNormal:SetFontObject(GameFontNormal)
NewItemInCollection.Main.TextNormal:SetPoint("CENTER", 0, -30)
NewItemInCollection.Main.TextNormal:SetShadowOffset(0, -1)
NewItemInCollection.Main.TextNormal:SetText("VANITY ITEM NAME")

NewItemInCollection.Main.Texture = NewItemInCollection.Main:CreateTexture(nil, "BACKGROUND", nil, 2)
NewItemInCollection.Main.Texture:SetTexture("Interface\\LevelUp\\LevelUpTex")
NewItemInCollection.Main.Texture:SetSize(284, 115)
NewItemInCollection.Main.Texture:SetPoint("CENTER", 0, 10)
NewItemInCollection.Main.Texture:SetTexCoord(0.00195313, 0.63867188, 0.03710938, 0.23828125)
NewItemInCollection.Main.Texture:SetVertexColor(1, 1, 1, 0.6)

NewItemInCollection.Main.LineUp = NewItemInCollection.Main:CreateTexture(nil, "BORDER", nil, 2)
NewItemInCollection.Main.LineUp:SetTexture("Interface\\LevelUp\\LevelUpTex")
NewItemInCollection.Main.LineUp:SetSize(264, 7)
NewItemInCollection.Main.LineUp:SetPoint("CENTER", 0, 15)
NewItemInCollection.Main.LineUp:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
NewItemInCollection.Main.LineUp:SetVertexColor(1, 1, 1)

NewItemInCollection.Main.LineDown = NewItemInCollection.Main:CreateTexture(nil, "BORDER", nil, 2)
NewItemInCollection.Main.LineDown:SetTexture("Interface\\LevelUp\\LevelUpTex")
NewItemInCollection.Main.LineDown:SetSize(264, 7)
NewItemInCollection.Main.LineDown:SetPoint("CENTER", 0, -46)
NewItemInCollection.Main.LineDown:SetTexCoord(0.00195313, 0.81835938, 0.01953125, 0.03320313)
NewItemInCollection.Main.LineDown:SetVertexColor(1, 1, 1)

NewItemInCollection.Main.Texture.AnimationGroup = NewItemInCollection.Main.Texture:CreateAnimationGroup()
NewItemInCollection.Main.Texture.AnimationGroup.Grow = NewItemInCollection.Main.Texture.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetScale(1.0, 0.001)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetDuration(0.0)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetStartDelay(0)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetOrder(1)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

NewItemInCollection.Main.Texture.AnimationGroup.Grow = NewItemInCollection.Main.Texture.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetScale(1.0, 1000.0)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetDuration(0.15)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetStartDelay(0.15)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetOrder(2)
NewItemInCollection.Main.Texture.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

NewItemInCollection.Main.LineUp.AnimationGroup = NewItemInCollection.Main.LineUp:CreateAnimationGroup()
NewItemInCollection.Main.LineUp.AnimationGroup.Grow = NewItemInCollection.Main.LineUp.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetScale(0.001, 1.0)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetDuration(0.0)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetStartDelay(0.15)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetOrder(1)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

NewItemInCollection.Main.LineUp.AnimationGroup.Grow = NewItemInCollection.Main.LineUp.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetScale(1000.0, 1.0)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetDuration(0.5)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetOrder(2)
NewItemInCollection.Main.LineUp.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

NewItemInCollection.Main.LineDown.AnimationGroup = NewItemInCollection.Main.LineDown:CreateAnimationGroup()
NewItemInCollection.Main.LineDown.AnimationGroup.Grow = NewItemInCollection.Main.LineDown.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetScale(0.001, 1.0)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetDuration(0.0)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetStartDelay(0.15)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetOrder(1)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)

NewItemInCollection.Main.LineDown.AnimationGroup.Grow = NewItemInCollection.Main.LineDown.AnimationGroup:CreateAnimation("Scale")
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetScale(1000.0, 1.0)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetDuration(0.5)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetOrder(2)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetOrigin("BOTTOM", 0, 0)
NewItemInCollection.Main.LineDown.AnimationGroup.Grow:SetScript("OnPlay", function()
	NewItemInCollection.Main.Texture.AnimationGroup:Stop();
	NewItemInCollection.Main.LineUp.AnimationGroup:Stop();

	NewItemInCollection.Main.Texture.AnimationGroup:Play();
	NewItemInCollection.Main.LineUp.AnimationGroup:Play();
end)

-------------------------------------------------------------------------------
--                       New Item unlocked animations                        --
-------------------------------------------------------------------------------
NewItemInCollection.HighLightOfNewItem.AnimationGroup = NewItemInCollection.HighLightOfNewItem:CreateAnimationGroup()
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation = NewItemInCollection.HighLightOfNewItem.AnimationGroup:CreateAnimation("Rotation")
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetStartDelay(0)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetDuration(6)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetOrder(1)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetEndDelay(0)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetSmoothing("NONE")
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetDegrees(90)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.Rotation:SetScript("OnPlay", function()
	PlaySound("igQuestListComplete")
	Addon:BaseFrameFadeIn(NewItemInCollection)
end)

NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut = NewItemInCollection.HighLightOfNewItem.AnimationGroup:CreateAnimation("Alpha")
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetStartDelay(0)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetDuration(3)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetOrder(2)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetEndDelay(0)
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetSmoothing("NONE")
NewItemInCollection.HighLightOfNewItem.AnimationGroup.AlphaFadeOut:SetChange(-1)

NewItemInCollection.HighLightOfNewItem.AnimationGroup:SetScript("OnStop", function()
	NewItemInCollection:Hide()
end)

NewItemInCollection.HighLightOfNewItem.AnimationGroup:SetScript("OnFinished", function()
	NewItemInCollection:Hide()
end)

NewItemInCollection.Main.AnimationGroup = NewItemInCollection.Main:CreateAnimationGroup()
NewItemInCollection.Main.AnimationGroup.Alpha = NewItemInCollection.Main.AnimationGroup:CreateAnimation("Alpha")
NewItemInCollection.Main.AnimationGroup.Alpha:SetStartDelay(0)
NewItemInCollection.Main.AnimationGroup.Alpha:SetDuration(1)
NewItemInCollection.Main.AnimationGroup.Alpha:SetOrder(1)
NewItemInCollection.Main.AnimationGroup.Alpha:SetEndDelay(5)
NewItemInCollection.Main.AnimationGroup.Alpha:SetSmoothing("NONE")
NewItemInCollection.Main.AnimationGroup.Alpha:SetChange(1)
NewItemInCollection.Main.AnimationGroup.Alpha:SetScript("OnPlay", function()
	NewItemInCollection.Main:Show()
	NewItemInCollection.Main.LineDown.AnimationGroup:Play()
	NewItemInCollection.HighLightOfNewItem.AnimationGroup:Play()
end)

NewItemInCollection.Main.AnimationGroup.AlphaFadeOut = NewItemInCollection.Main.AnimationGroup:CreateAnimation("Alpha")
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetStartDelay(0)
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetDuration(3)
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetOrder(2)
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetEndDelay(0)
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetSmoothing("NONE")
NewItemInCollection.Main.AnimationGroup.AlphaFadeOut:SetChange(-1)

NewItemInCollection.Main.AnimationGroup:SetScript("OnStop", function()
	NewItemInCollection.Main:Hide()
	NewItemInCollection.HighLightOfNewItem.AnimationGroup:Finish()
end)

NewItemInCollection.Main.AnimationGroup:SetScript("OnFinished", function()
	NewItemInCollection.Main:Hide()
	NewItemInCollection.HighLightOfNewItem.AnimationGroup:Finish()
end)

-------------------------------------------------------------------------------
--                              Preview Model                                --
-------------------------------------------------------------------------------
Store.ModelPreview = CreateFrame("DressUpModel", "$parentModelPreview", Store)
Store.ModelPreview.HackFix = 0
Store.ModelPreview.MaxSize = 1.2
Store.ModelPreview.MinSize = 0.6
Store.ModelPreview.Creature = 101230
Store.ModelPreview.DefaultSize = Store.ModelPreview.MaxSize - (Store.ModelPreview.MaxSize - Store.ModelPreview.MinSize) / 2
Store.ModelPreview.DefaultFacing = 0.75

Store.ModelPreview:SetSize(455, 410)
Store.ModelPreview:SetPoint("CENTER", 147, -15)
Store.ModelPreview:SetCreature(Store.ModelPreview.Creature)
Store.ModelPreview:RefreshUnit()
Store.ModelPreview:SetFacing(Store.ModelPreview.DefaultFacing)
Store.ModelPreview:SetCamera(0)
Store.ModelPreview:SetLight(1, 0, 0, -0.707, -0.707, 0.7, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 0.8);
Store.ModelPreview:SetModelScale(Store.ModelPreview.DefaultSize)
Store.ModelPreview:SetFrameLevel(Store:GetFrameLevel() + 11)

--StoreCollectionFrameModelPreviewFixModelPosition(Store.ModelPreview)

Store.ModelPreview:Hide()
Store.ModelPreview_fake = CreateFrame("Frame", "$parentModelPreviewFake", Store)
Store.ModelPreview_fake:SetSize(455, 410)
Store.ModelPreview_fake:SetPoint("CENTER", 147, -15)
Store.ModelPreview_fake:EnableMouse(true)
Store.ModelPreview_fake:EnableMouseWheel(true)
Store.ModelPreview_fake:Hide()
Store.ModelPreview_fake:SetFrameLevel(Store:GetFrameLevel() + 10)

Store.ModelPreview_fake.CloseButton = CreateFrame("Button", "$parentCloseButton", Store.ModelPreview_fake,
                                                  "UIPanelCloseButton")
Store.ModelPreview_fake.CloseButton:SetPoint("TOPRIGHT", 6, 6)
Store.ModelPreview_fake.CloseButton:EnableMouse(true)
Store.ModelPreview_fake.CloseButton:SetScript("OnMouseUp", function()
	PlaySound("igMainMenuClose")
	StoreCollectionHideModelPreview()
	StoreCollectionFrameShowPaper()
end)

--StoreCollectionFrameModelPreviewInitModel(Store.ModelPreview)

Store.ModelPreview.BGTex = Store.ModelPreview_fake:CreateTexture(nil, "BACKGROUND")
Store.ModelPreview.BGTex:SetSize(1024, 512)
Store.ModelPreview.BGTex:SetTexture(Addon.AwTexPath .. "Collections\\PreviewMounts\\MountPreview")
Store.ModelPreview.BGTex:SetPoint("CENTER", 1, 0)

Store.ModelPreview:SetScript("OnShow", function(self)
	StoreCollectionFrameModelPreviewFixModelPosition(self)
	self:SetFacing(Store.ModelPreview.DefaultFacing)
	self:SetModelScale(0.8)
	StoreCollectionFrameModelPreviewLoadItems()
end)
Store.ModelPreview:SetScript("OnHide", function(self)
	StoreCollectionFrameModelPreviewFixModelPosition(self)
	self:SetFacing(Store.ModelPreview.DefaultFacing)
	self:SetModelScale(Store.ModelPreview.DefaultSize)
	StoreCollectionFrameModelPreviewLoadItems()
end)

Store.ModelPreview_fake:SetScript("OnUpdate", function()
	if (ModelPreview_SELECT_ROTATION_START_X) then
		local x = GetCursorPosition();
		local diff = (x - ModelPreview_SELECT_ROTATION_START_X) * 0.01;
		ModelPreview_SELECT_ROTATION_START_X = GetCursorPosition();
		Store.ModelPreview:SetFacing((Store.ModelPreview:GetFacing() + diff));
	end
end)

Store.ModelPreview_fake:SetScript("OnMouseDown", function(self, button)
	if (button == "LeftButton") then
		ModelPreview_SELECT_ROTATION_START_X = GetCursorPosition();
		ModelPreview_SELECT_INITIAL_FACING = Store.ModelPreview:GetFacing();
	end
end)

Store.ModelPreview_fake:SetScript("OnMouseUp", function(self, button)
	if (button == "LeftButton") then
		ModelPreview_SELECT_ROTATION_START_X = nil
	end
end)

Store.ModelPreview_fake:SetScript("OnMouseWheel", function(self, delta)
	if Store.ModelPreview:GetModelScale() >= Store.ModelPreview.MaxSize and delta > 0 then
		return false
	end

	if Store.ModelPreview:GetModelScale() <= Store.ModelPreview.MinSize and delta < 0 then
		return false
	end
	Store.ModelPreview:SetModelScale(Store.ModelPreview:GetModelScale() + (delta * 0.05))
end)

Store.ModelPreview_fake.SpendPoints = CreateFrame("FRAME", "$parentSpendPoints", Store.ModelPreview_fake)
Store.ModelPreview_fake.SpendPoints:SetSize(256, 32)
Store.ModelPreview_fake.SpendPoints:SetPoint("BOTTOM", 0, -20)

Store.ModelPreview_fake.SpendPoints.BG = Store.ModelPreview_fake.SpendPoints:CreateTexture(nil, "ARTWORK")
Store.ModelPreview_fake.SpendPoints.BG:SetAllPoints()
Store.ModelPreview_fake.SpendPoints.BG:SetTexture(Addon.AwTexPath .. "enchant\\Enchant_RefundButton")

Store.ModelPreview_fake.SpendPoints.BG_2 = Store.ModelPreview_fake.SpendPoints:CreateTexture(nil, "BORDER")
Store.ModelPreview_fake.SpendPoints.BG_2:SetPoint("CENTER", 0, 63)
Store.ModelPreview_fake.SpendPoints.BG_2:SetSize(512, 128)
Store.ModelPreview_fake.SpendPoints.BG_2:SetTexture(Addon.AwTexPath .. "Collections\\ShadowPaladinBar_Horizontal_Bgnd")

Store.ModelPreview_fake.SpendPoints.Glow = CreateFrame("Model", nil, Store.ModelPreview_fake.SpendPoints)
Store.ModelPreview_fake.SpendPoints.Glow:SetWidth(256);
Store.ModelPreview_fake.SpendPoints.Glow:SetHeight(256);
Store.ModelPreview_fake.SpendPoints.Glow:SetPoint("CENTER", 0, 0)
Store.ModelPreview_fake.SpendPoints.Glow:SetModel("World\\Kalimdor\\silithus\\passivedoodads\\ahnqirajglow\\quirajglow_purple.m2")
Store.ModelPreview_fake.SpendPoints.Glow:SetModelScale(0.016)
Store.ModelPreview_fake.SpendPoints.Glow:SetCamera(0)
Store.ModelPreview_fake.SpendPoints.Glow:SetPosition(0.083, 0.095, 0)
Store.ModelPreview_fake.SpendPoints.Glow:SetFacing(0)

Store.ModelPreview_fake.SpendPoints.MainButton = CreateFrame("Button", nil, Store.ModelPreview_fake.SpendPoints,
                                                             "StaticPopupButtonTemplate")
Store.ModelPreview_fake.SpendPoints.MainButton:SetPoint("CENTER", 1, 1)
Store.ModelPreview_fake.SpendPoints.MainButton:EnableMouse(true)
Store.ModelPreview_fake.SpendPoints.MainButton:SetWidth(148)
Store.ModelPreview_fake.SpendPoints.MainButton:SetHeight(19)
Store.ModelPreview_fake.SpendPoints.MainButton:SetText("Transmogrify Items")
Store.ModelPreview_fake.SpendPoints.MainButton:Disable()
Store.ModelPreview_fake.SpendPoints.MainButton:SetScript("OnClick", function(self)
	if (Store.ItemSelected ~= 0) and (self:IsEnabled() == 1) then
		-- no ability to purchase atm
	end
end)
-------------------------------------------------------------------------------
--                     Disenchant Confirm Dialog Frame                       --
-------------------------------------------------------------------------------
function Store:TryPurchaseSelectedItem()

	local dpCost = C_VanityCollection.GetDPPrice(Store.ItemInternal)
	local _, link = GetItemInfo(Store.ItemInternal)
	local vanityItem = GetVanityItemCached(Store.ItemInternal)
	if not vanityItem then
		return
	end

	if vanityItem.spCost > 0 then
		if C_VanityCollection.IsCollectionItemOwned(Store.ItemInternal) then
			SendSystemMessage("You already own this item.")
			return
		end

		local spLink = select(2, GetItemInfo(ItemData.SEASONAL_POINTS)) or ITEM_QUALITY_COLORS[Enum.ItemQuality.Epic]:WrapText("[Seasonal Points]")
		local pointsText = vanityItem.spCost .. "x" .. spLink
		StaticPopup_Show("VANITY_PURCHASE",link, pointsText, {
			hasCurrency = GetItemCount(ItemData.SEASONAL_POINTS) >= vanityItem.spCost,
			purchase = GenerateClosure(BuyItem, false)
		})
	elseif vanityItem.btCost > 0 and dpCost > 0 then
		local btLink = select(2, GetItemInfo(ItemData.BAZAAR_TOKENS)) or ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]:WrapText("[Bazaar Tokens]")
		local btText = vanityItem.btCost .. "x" .. btLink

		local dpText = dpCost .. "x" .. ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]:WrapText("[Donation Points]")

		local currencyText = btText .. "\nor\n" .. dpText
		StaticPopup_Show("VANITY_PURCHASE_MULTI", link, currencyText, {
			hasCurrency1 = GetItemCount(ItemData.BAZAAR_TOKENS) >= vanityItem.btCost,
			purchase1 = GenerateClosure(BuyItem, false),
			hasCurrency2 = GetAscensionDonationPoints() >= dpCost and C_Config.GetBoolConfig("CONFIG_WEB_SHOP_ENABLED"),
			purchase2 = GenerateClosure(BuyItem, true)
		})
	elseif vanityItem.btCost > 0 then
		local btLink = select(2, GetItemInfo(ItemData.BAZAAR_TOKENS)) or ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]:WrapText("[Bazaar Tokens]")
		local pointsText = vanityItem.btCost .. "x" .. btLink
		StaticPopup_Show("VANITY_PURCHASE", link, pointsText, {
			hasCurrency = GetItemCount(ItemData.BAZAAR_TOKENS) >= vanityItem.btCost,
			purchase = GenerateClosure(BuyItem, false)
		})
	elseif dpCost > 0 then
		local pointsText = dpCost .. "x" .. ITEM_QUALITY_COLORS[Enum.ItemQuality.Vanity]:WrapText("[Donation Points]")
		StaticPopup_Show("VANITY_PURCHASE", link, pointsText, {
			hasCurrency = GetAscensionDonationPoints() >= dpCost and C_Config.GetBoolConfig("CONFIG_WEB_SHOP_ENABLED"),
			purchase = GenerateClosure(BuyItem, true)
		})
	end
end

--
-- Help Plates
--

Store.HelpPlateButton = CreateFrame("Button", "$parentHelpPlateButton", Store, "HelpPlateButtonTemplate")
Store.HelpPlateButton.HelpPlate = "VANITY_STORE"
Store.HelpPlateButton:SetPoint("TOPLEFT", 48, 16)
Store.HelpPlateButton:SetFrameLevel(500)

HelpPlate["VANITY_STORE"] = {
	cvar      = "HelpTipBitfield",
	cvarBit   = HelpTips.Bits.HelpPlate_Vanity,
	MainTip   = "VANITY_STORE_MAIN",
	{
		helpTip     = "VANITY_STORE_SEARCH",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFrameSearchBox", "TOPLEFT", -8, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFrameSearchBox", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER", "TOP" }
	},
	{
		helpTip     = "VANITY_STORE_CATEGORY",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFrameDropdown", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFrameDropdown", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER", "TOP" }
	},
	{
		helpTip     = "VANITY_STORE_BANNER",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFrameBanner", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFrameBanner", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip     = "VANITY_STORE_PREVIEW",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFramePaper", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFramePaper", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip     = "VANITY_STORE_COLLECTION",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFrameCollectionList", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFrameCollectionList", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
	{
		helpTip     = "VANITY_STORE_DELIVER",
		parent      = "StoreCollectionFrame",
		points      = {
			{ "TOPLEFT", "StoreCollectionFrameActivateStoreButton", "TOPLEFT", 0, 0 },
			{ "BOTTOMRIGHT", "StoreCollectionFrameActivateStoreButton", "BOTTOMRIGHT", 0, 0 },
		},
		flyoutPoint = { "CENTER" }
	},
}

HelpTips["VANITY_STORE_MAIN"] = {
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["VANITY_STORE_SEARCH"] = {
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["VANITY_STORE_CATEGORY"] = {
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["VANITY_STORE_BANNER"] = {
	targetPoint = HelpTip.Point.BottomEdgeCenter,
}

HelpTips["VANITY_STORE_PREVIEW"] = {
	targetPoint = HelpTip.Point.RightEdgeCenter,
}

HelpTips["VANITY_STORE_COLLECTION"] = {
	targetPoint = HelpTip.Point.LeftEdgeCenter,
}

HelpTips["VANITY_STORE_DELIVER"] = {
	targetPoint = HelpTip.Point.TopEdgeCenter,
}

--
-- Events
--
function Store:ASCENSION_STORE_COLLECTION_ITEM_LEARNED(itemId)
	if not self.ENTERED_WORLD then return end
	
	UnlockNewItem(itemId)
end

function Store:ASCENSION_CUSTOM_POINTS_SEASONAL_POINTS_VALUE_CHANGED(oldPoints, newPoints)
	UpdateBalance(GetAscensionDonationPoints(), newPoints)
end

function Store:WEB_SHOP_PURCHASE_ERROR(error)
	UpdateBalance(GetAscensionDonationPoints(), GetItemCount(ItemData.SEASONAL_POINTS))
	self.PurchasePendingInputBlocker:Hide()
	self.PurchaseFailedInputBlocker:Show()
	self.PurchaseFailedInputBlocker:SetText("Failed to purchase item.", error)
end

function Store:WEB_SHOP_PURCHASE_SUCCESS()
	UpdateBalance(GetAscensionDonationPoints(), GetItemCount(ItemData.SEASONAL_POINTS))
	self.PurchasePendingInputBlocker:Hide()
	self.PurchaseSuccessInputBlocker:Show()
end

function Store:PLAYER_ENTERING_WORLD()
	self.ENTERED_WORLD = true
end

Store:HookEvent("ASCENSION_STORE_COLLECTION_ITEM_LEARNED")
Store:HookEvent("ASCENSION_CUSTOM_POINTS_SEASONAL_POINTS_VALUE_CHANGED")
Store:RegisterEvent("PLAYER_ENTERING_WORLD")
Store:RegisterEvent("WEB_SHOP_PURCHASE_SUCCESS")
Store:RegisterEvent("WEB_SHOP_PURCHASE_ERROR")

Store:SetScript("OnEvent", OnEventToMethod)

if C_Realm.IsDevelopment() then
	function SlashCmdList.DEBUGSTORE(text)
		print("|cff00FF00Vanity Filter|r")
		print("|cffFFD100[Flags (Decimal)] = |r" .. Store.StoreTypeList.Flags)
		print("|cffFFD100[Flags (Hex)] = |r" .. format("0x%x", Store.StoreTypeList.Flags))
		print("|cffFFD100[Flags (Enum)] = {|r")
		local flags = {}
		for enum, flag in pairs(Enum.VanityCategory) do
			if type(flag) == "table" then
				for subEnum, subFlag in pairs(flag) do
					if bit.band(subFlag, Store.StoreTypeList.Flags) == subFlag then
						print("    Enum.VanityCategory." .. enum .. "." .. subEnum)
						tinsert(flags, subFlag)
					end
				end
			else
				if bit.band(flag, Store.StoreTypeList.Flags) == flag then
					print("    Enum.VanityCategory." .. enum)
					tinsert(flags, flag)
				end
			end
		end
		print("|cffFFD100}|r")

		if text and text ~= "" then
			local itemId = tonumber(text) or tonumber(text:match("item:(%d*)"))

			local info = itemId and GetVanityItemCached(itemId)
			if info then
				local name = GetItemInfo(itemId)
				print("|cffFFD100[Item] = |r" .. name)
				print("|cffFFD100[Group (Decimal)] = |r" .. info.group)
				print("|cffFFD100[Group (Hex)] = |r" .. format("0x%x", info.group))
				print("|cffFFD100[Group (Enum)] = {|r")
				for enum, flag in pairs(Enum.VanityCategory) do
					if type(flag) == "table" then
						for subEnum, subFlag in pairs(flag) do
							if bit.band(subFlag, info.group) == subFlag then
								print("    Enum.VanityCategory." .. enum .. "." .. subEnum)
							end
						end
					else
						if bit.band(flag, info.group) == flag then
							print("    Enum.VanityCategory." .. enum)
						end
					end
				end
				print("|cffFFD100}|r")

				local canShow = false
				for _, flag in ipairs(GetGroupFlags(info.group)) do
					if bit.band(Store.StoreTypeList.Flags, flag) == flag then
						print("|cffFFD100[Can Show] = |r |cff00FF00Yes")
						canShow = true
						break
					end
				end

				if not canShow then
					print("|cffFFD100[Can Show] = |r |cffFF0000No")
				end
			end
		end
	end

	SLASH_DEBUGSTORE1, SLASH_DEBUGSTORE2 = "/vanitydebug", "/vdb"
end 

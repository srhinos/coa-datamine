SeasonInfoMixin = {}

function SeasonInfoMixin:OnLoad()
end

function SeasonInfoMixin:SetInfo(icon, title, description)
	self.Icon:SetPortraitTexture("Interface\\Icons\\"..icon)
	self.IconBorder:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
	self.Title:SetText(title)
	self.Description:SetText(description)
end

function SeasonInfoMixin:SetItem(itemID)
	local item = Item:CreateFromID(itemID)

	if self.cancelToken then
		self.cancelToken()
		self.cancelToken = nil
	end

	self.cancelToken = item:CancelableContinueOnLoad(function()
		if not item:IsCached() then
			dprint("SeasonInfoMixin: could not cache", itemID)
			return
		end

		self.item = itemID
		self.Icon:SetPortraitTexture(GetItemIcon(itemID))
		self.Title:SetText(item:GetInfo())
	end)
end 
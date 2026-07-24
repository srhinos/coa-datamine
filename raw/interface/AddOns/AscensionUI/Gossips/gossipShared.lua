local Addon = select(2, ...)

Addon.SharedGossip = {}

local SharedGossip = Addon.SharedGossip

-- TODO: TO GLOBALSTRINGS
SharedGossip.DEFAULT_SPEC_NAMES = { 
	"Specialization I",
	"Specialization II",
	"Specialization III",
	"Specialization IV",
	"Specialization V",
	"Specialization VI",
	"Specialization VII",
	"Specialization VIII",
	"Specialization IX",
	"Specialization X",
	"Specialization XI",
	"Specialization XII",
	"Specialization XIII",
	"Specialization XIV",
	"Specialization XV",
	"Specialization XVI",
	"Specialization XVII",
	"Specialization XVIII",
	"Specialization XIX",
	"Specialization XX",
}

SharedGossip.DIGITS = {
	[0] = "services-number-0",
	[1] = "services-number-1",
	[2] = "services-number-2",
	[3] = "services-number-3",
	[4] = "services-number-4",
	[5] = "services-number-5",
	[6] = "services-number-6",
	[7] = "services-number-7",
	[8] = "services-number-8",
	[9] = "services-number-9",
}

SharedGossip.MAX_LEVEL = GetMaxLevel()
-------------------------------------------------------------------------------
--                                     UIs                                   --
-------------------------------------------------------------------------------
function SharedGossip:CreateDigit(parent) -- TODO: To its own file, shared with other gossips
	local digit = parent:CreateTexture(nil, "OVERLAY")
	digit:SetSize(53, 59)

	function digit:SetNumber(value)
		if (value > 9) or (value < 0) then
			return
		end

		self:SetAtlas(SharedGossip.DIGITS[value])
	end

	return digit
end

function SharedGossip:CreateDigitBox(name, parent) -- TODO: To its own file, shared with other gossips
	local frame = CreateFrame("FRAME", "$parent."..name, parent, nil)
	frame:SetHeight(64)
	--frame:SetBackdrop(GameTooltip:GetBackdrop())

	frame.max = 999999999
	frame.min = 0
	frame.digits = {}
	frame.digit_width = 53
	frame.digit_spacing = 27

	for i = 1, 9 do
		frame.digits[i] = SharedGossip:CreateDigit(frame)
	end

	function frame:OnValueChanged(value)
		-- set up for each
	end

	function frame:SetValue(value)
		if (value > self.max) or (value < self.min) then
			return
		end

		for _, v in pairs(self.digits) do
			v:Hide()
		end

		local number = {}
		local total = #tostring(value)

		self.value = value

		for i = total, 1, -1 do
			local digit = value%10
			value = math.floor(value/10)

			self.digits[i]:SetNumber(digit)
			self.digits[i]:Show()

			if (i == total) then
				frame.digits[i]:SetPoint("RIGHT")
			else
				frame.digits[i]:SetPoint("RIGHT", frame.digits[i+1], "LEFT", frame.digit_spacing, 0)
			end
		end

		self:SetWidth(self.digit_width + ((self.digit_width-self.digit_spacing)*(total-1)))
		self:OnValueChanged(self.value)
	end

	function frame:GetValue()
		return self.value
	end

	return frame
end

function SharedGossip:CreateMagic(parent)
	local magic = {}

	function magic:SetSize(x, y)
		self.magic:SetSize(x, y)

		self.magicAdd:SetSize(x, y)

		self.magicUnlock:SetSize(x, y)

		self.magicUnlockSplash:SetSize(x, y)
	end

	function magic:SetPoint(...)
		self.magic:SetPoint(...)
	end

	function magic:PlaySplash()
		self.magicUnlock.AnimAlpha:Stop()
		self.magicUnlock.AnimAlpha:Play()
		self.magicUnlockSplash.AnimSplash:Stop()
		self.magicUnlockSplash.AnimSplash:Play()
	end

	parent.magic = parent:CreateTexture(nil, "BACKGROUND")
	parent.magic:SetTexture("Interface\\darkmoon\\magic")
	parent.magic:SetWidth(600)
	parent.magic:SetHeight(600)
	--parent.magic:SetPoint("CENTER", parent.art, 0, 0)
	parent.magic:SetBlendMode("ADD")

	magic.magic = parent.magic

	-- rotation
	parent.magic.AnimG = parent.magic:CreateAnimationGroup()
	parent.magic.AnimG.Rotation = parent.magic.AnimG:CreateAnimation("Rotation")
	parent.magic.AnimG.Rotation:SetDuration(90)
	parent.magic.AnimG.Rotation:SetOrder(1)
	parent.magic.AnimG.Rotation:SetEndDelay(0)
	parent.magic.AnimG.Rotation:SetSmoothing("IN_OUT")
	parent.magic.AnimG.Rotation:SetDegrees(-360)

	parent.magic.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	parent.magic.AnimG:Play()

	-- breath
	parent.magic.AnimAlpha = parent.magic:CreateAnimationGroup()
	parent.magic.AnimAlpha.Alpha = parent.magic.AnimAlpha:CreateAnimation("Alpha")
	parent.magic.AnimAlpha.Alpha:SetDuration(2)
	parent.magic.AnimAlpha.Alpha:SetOrder(1)
	parent.magic.AnimAlpha.Alpha:SetEndDelay(0)
	parent.magic.AnimAlpha.Alpha:SetSmoothing("IN_OUT")
	parent.magic.AnimAlpha.Alpha:SetChange(-0.5)

	parent.magic.AnimAlpha.Alpha = parent.magic.AnimAlpha:CreateAnimation("Alpha")
	parent.magic.AnimAlpha.Alpha:SetDuration(2)
	parent.magic.AnimAlpha.Alpha:SetOrder(2)
	parent.magic.AnimAlpha.Alpha:SetEndDelay(0)
	parent.magic.AnimAlpha.Alpha:SetSmoothing("IN_OUT")
	parent.magic.AnimAlpha.Alpha:SetChange(0.5)

	parent.magic.AnimAlpha:SetScript("OnFinished", function(self)
		self:Play()
	end)

	parent.magic.AnimAlpha:Play()

	-- additional magic always visible
	parent.magicAdd = parent:CreateTexture(nil, "BORDER")
	parent.magicAdd:SetTexture("Interface\\darkmoon\\magic_add")
	parent.magicAdd:SetWidth(600)
	parent.magicAdd:SetHeight(600)
	parent.magicAdd:SetPoint("CENTER", parent.magic, 0, 0)
	parent.magicAdd:SetBlendMode("ADD")

	magic.magicAdd = parent.magicAdd

	-- rotation
	parent.magicAdd.AnimG = parent.magicAdd:CreateAnimationGroup()
	parent.magicAdd.AnimG.Rotation = parent.magicAdd.AnimG:CreateAnimation("Rotation")
	parent.magicAdd.AnimG.Rotation:SetDuration(60)
	parent.magicAdd.AnimG.Rotation:SetOrder(1)
	parent.magicAdd.AnimG.Rotation:SetEndDelay(0)
	parent.magicAdd.AnimG.Rotation:SetSmoothing("NONE")
	parent.magicAdd.AnimG.Rotation:SetDegrees(360)

	parent.magicAdd.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	parent.magicAdd.AnimG:Play()

	-- texture for unlock animation, sync with main art
	parent.magicUnlock = parent:CreateTexture(nil, "BACKGROUND")
	parent.magicUnlock:SetTexture("Interface\\darkmoon\\magic")
	parent.magicUnlock:SetWidth(600)
	parent.magicUnlock:SetHeight(600)
	parent.magicUnlock:SetPoint("CENTER", parent.magic, 0, 0)
	parent.magicUnlock:SetBlendMode("ADD")
	parent.magicUnlock:SetAlpha(0)

	magic.magicUnlock = parent.magicUnlock

	parent.magicUnlock.AnimG = parent.magicUnlock:CreateAnimationGroup()
	parent.magicUnlock.AnimG.Rotation = parent.magicUnlock.AnimG:CreateAnimation("Rotation")
	parent.magicUnlock.AnimG.Rotation:SetDuration(90)
	parent.magicUnlock.AnimG.Rotation:SetOrder(1)
	parent.magicUnlock.AnimG.Rotation:SetEndDelay(0)
	parent.magicUnlock.AnimG.Rotation:SetSmoothing("IN_OUT")
	parent.magicUnlock.AnimG.Rotation:SetDegrees(-360)

	parent.magicUnlock.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	parent.magicUnlock.AnimG:Play()

	-- unlock anim
	parent.magicUnlock.AnimAlpha = parent.magicUnlock:CreateAnimationGroup()
	parent.magicUnlock.AnimAlpha.Alpha = parent.magicUnlock.AnimAlpha:CreateAnimation("Alpha")
	parent.magicUnlock.AnimAlpha.Alpha:SetDuration(0.2)
	parent.magicUnlock.AnimAlpha.Alpha:SetOrder(1)
	parent.magicUnlock.AnimAlpha.Alpha:SetEndDelay(0)
	parent.magicUnlock.AnimAlpha.Alpha:SetSmoothing("IN")
	parent.magicUnlock.AnimAlpha.Alpha:SetChange(1)

	parent.magicUnlock.AnimAlpha.Alpha = parent.magicUnlock.AnimAlpha:CreateAnimation("Alpha")
	parent.magicUnlock.AnimAlpha.Alpha:SetDuration(2)
	parent.magicUnlock.AnimAlpha.Alpha:SetOrder(2)
	parent.magicUnlock.AnimAlpha.Alpha:SetEndDelay(0)
	parent.magicUnlock.AnimAlpha.Alpha:SetSmoothing("OUT")
	parent.magicUnlock.AnimAlpha.Alpha:SetChange(-1)

	-- to play
	--parent.magicUnlock.AnimAlpha:Stop()
	--parent.magicUnlock.AnimAlpha:Play()
	--parent.magicUnlockSplash.AnimSplash:Stop()
	--parent.magicUnlockSplash.AnimSplash:Play()

	parent.magicUnlockSplash = parent:CreateTexture(nil, "BACKGROUND")
	parent.magicUnlockSplash:SetTexture("Interface\\darkmoon\\magic")
	parent.magicUnlockSplash:SetWidth(600)
	parent.magicUnlockSplash:SetHeight(600)
	parent.magicUnlockSplash:SetPoint("CENTER", parent.magic, 0, 0)
	parent.magicUnlockSplash:SetBlendMode("ADD")
	parent.magicUnlockSplash:SetAlpha(0)

	magic.magicUnlockSplash = parent.magicUnlockSplash

	parent.magicUnlockSplash.AnimG = parent.magicUnlockSplash:CreateAnimationGroup()
	parent.magicUnlockSplash.AnimG.Rotation = parent.magicUnlockSplash.AnimG:CreateAnimation("Rotation")
	parent.magicUnlockSplash.AnimG.Rotation:SetDuration(30)
	parent.magicUnlockSplash.AnimG.Rotation:SetOrder(1)
	parent.magicUnlockSplash.AnimG.Rotation:SetEndDelay(0)
	parent.magicUnlockSplash.AnimG.Rotation:SetSmoothing("NONE")
	parent.magicUnlockSplash.AnimG.Rotation:SetDegrees(-360)

	parent.magicUnlockSplash.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	parent.magicUnlockSplash.AnimG:Play()

	-- unlock anim
	parent.magicUnlockSplash.AnimSplash = parent.magicUnlockSplash:CreateAnimationGroup()

	parent.magicUnlockSplash.AnimSplash.Scale0 = parent.magicUnlockSplash.AnimSplash:CreateAnimation("Scale")
	parent.magicUnlockSplash.AnimSplash.Scale0:SetScale(1.5, 1.5)
	parent.magicUnlockSplash.AnimSplash.Scale0:SetDuration(2)
	parent.magicUnlockSplash.AnimSplash.Scale0:SetOrder(2)
	parent.magicUnlockSplash.AnimSplash.Scale0:SetSmoothing("OUT")

	parent.magicUnlockSplash.AnimSplash.Alpha = parent.magicUnlockSplash.AnimSplash:CreateAnimation("Alpha")
	parent.magicUnlockSplash.AnimSplash.Alpha:SetDuration(0.2)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetOrder(1)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetEndDelay(0)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetSmoothing("IN")
	parent.magicUnlockSplash.AnimSplash.Alpha:SetChange(1)

	parent.magicUnlockSplash.AnimSplash.Alpha = parent.magicUnlockSplash.AnimSplash:CreateAnimation("Alpha")
	parent.magicUnlockSplash.AnimSplash.Alpha:SetDuration(2)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetOrder(2)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetEndDelay(0)
	parent.magicUnlockSplash.AnimSplash.Alpha:SetSmoothing("OUT")
	parent.magicUnlockSplash.AnimSplash.Alpha:SetChange(-1)

	return magic
end

function SharedGossip:CreateItemRing(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent, nil)
	frame:SetWidth(64)
	frame:SetHeight(64)
	frame:EnableMouse(true)
	--frame:SetBackdrop(GameTooltip:GetBackdrop())

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontHighlightLarge)
	frame.title:SetPoint("TOP", 0, -64)
	frame.title:SetText("Marks of Ascension")

	frame.icon = frame:CreateTexture(nil, "BORDER")
    frame.icon:SetPoint("LEFT", 4, 0)
    frame.icon:SetSize(48, 48)
   	SetPortraitToTexture(frame.icon, "Interface\\ICONS\\ability_mage_timewarp")

    frame.ring = frame:CreateTexture(nil, "ARTWORK")
    frame.ring:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
    frame.ring:SetPoint("CENTER", frame.icon, 0, -2)
    frame.ring:SetSize(56, 56)

    frame.glow = frame:CreateTexture(nil, "BACKGROUND")
    frame.glow:SetAtlas("services-ring-large-glowspin", Const.TextureKit.IgnoreAtlasSize)
    frame.glow:SetSize(128, 128)
    frame.glow:SetPoint("CENTER", frame.icon, 0, 0)

    frame.Highlight = frame:CreateTexture(nil, "OVERLAY")
    frame.Highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    frame.Highlight:SetSize(56, 56)
    frame.Highlight:SetPoint("CENTER", frame.icon, 0, 0)
    frame.Highlight:SetBlendMode("ADD")
    frame.Highlight:Hide()

	frame.glow.AnimG = frame.glow:CreateAnimationGroup()
	frame.glow.AnimG.Rotation = frame.glow.AnimG:CreateAnimation("Rotation")
	frame.glow.AnimG.Rotation:SetDuration(60)
	frame.glow.AnimG.Rotation:SetOrder(1)
	frame.glow.AnimG.Rotation:SetEndDelay(0)
	frame.glow.AnimG.Rotation:SetSmoothing("NONE")
	frame.glow.AnimG.Rotation:SetDegrees(-360)

	frame.glow.AnimG:SetScript("OnFinished", function(self)
		self:Play()
	end)

	frame.glow.AnimG:Play()

	function frame:SetItem(itemID)
	    local item = Item:CreateFromID(itemID)

	    if self.cancelToken then
	        self.cancelToken()
	        self.cancelToken = nil
	    end

	    self.cancelToken = item:CancelableContinueOnLoad(function()
	        if not item:IsCached() then
	            dprint("Tried to cache Item", itemID, "but it doesn't exist?")
	            return
	        end

			self.tokenType = nil
			self.tokenName = nil
			self.tokenTooltip = nil
	        self.item = itemID
	        SetPortraitToTexture(self.icon, GetItemIcon(self.item))
	        self.title:SetText(item:GetInfo())
	    end)
	end

	function frame:SetToken(tokenType, setTitle)
		if self.cancelToken then
			self.cancelToken()
			self.cancelToken = nil
		end

		local name, description, tooltip, icon = C_Token.GetTokenInfo(tokenType)
		self.item = nil
		self.tokenType = tokenType
		self.tokenName = name
		self.tokenTooltip = tooltip or description

		if icon then
			SetPortraitToTexture(self.icon, icon)
		end

		if setTitle then
			self.title:SetText(name or "")
		end
	end

    frame:SetScript("OnEnter", function(self)
    	self.Highlight:Show()
    	if (self.item) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:"..self.item)
			GameTooltip:Show()
		elseif (self.tokenType) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if (self.tokenName) then
				GameTooltip:AddLine(self.tokenName, 1, 1, 1, 1)
			end
			if (self.tokenTooltip) then
				GameTooltip:AddLine(self.tokenTooltip, 1, 0.82, 0, 1)
			end
			GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self)
		self.Highlight:Hide()
		GameTooltip:Hide()
	end)

	return frame
end

-- TODO: make even more global than this
function SharedGossip:OnEnterDisplayTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")

	if (button.tooltipTitle) then
		GameTooltip:AddLine(button.tooltipTitle, 1, 1, 1, 1)
	end

	if (button.tooltipText) then
		GameTooltip:AddLine(button.tooltipText, 1, 0.82, 0, 1, 1)
	end

	GameTooltip:Show()
end

function SharedGossip:CreateTab(name, parent)
	if not(parent.tabs) then
		parent.tabs = {}
	end

	local btn = CreateFrame("BUTTON", name, parent)
	table.insert(parent.tabs, btn)

    btn:SetSize(190, 39)

    btn.highlight = btn:CreateTexture(nil, "OVERLAY")
    btn.highlight:SetSize(186, 36)
    btn.highlight:SetPoint("CENTER", 0, 2)
    btn.highlight:SetAtlas("store-category-selected", Const.TextureKit.IgnoreAtlasSize)
    btn.highlight:SetBlendMode("ADD")
    btn.highlight:Hide()

    btn.checked = btn:CreateTexture(nil, "OVERLAY")
    btn.checked:SetSize(186, 36)
    btn.checked:SetPoint("CENTER", 0, 2)
    btn.checked:SetAtlas("store-category-hover", Const.TextureKit.IgnoreAtlasSize)
    btn.checked:SetBlendMode("ADD")
    btn.checked:Hide()

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetPoint("CENTER", 0, 0)
    btn.bg:SetAtlas("store-category", Const.TextureKit.IgnoreAtlasSize)
    btn.bg:SetSize(190, 39)

    btn.icon = btn:CreateTexture(nil, "BORDER")
    btn.icon:SetSize(26, 26)
    btn.icon:SetPoint("LEFT", 6, 3)
    SetPortraitToTexture(btn.icon, "Interface\\Icons\\inv_custom_trainerBook")

    btn.iconBorder = btn:CreateTexture(nil, "ARTWORK")
    btn.iconBorder:SetSize(44, 44)
    btn.iconBorder:SetPoint("LEFT", -3, 2)
    btn.iconBorder:SetAtlas("category-icon-ring", Const.TextureKit.IgnoreAtlasSize)

    btn.text = btn:CreateFontString(nil, "ARTWORK")
    btn.text:SetJustifyH("LEFT")
    btn.text:SetJustifyV("CENTER")
    btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 12, 0)

    btn.text:SetWordWrap(true)
    btn.text:SetNonSpaceWrap(true)
    btn.text:SetFontObject(GameFontNormal)
    btn.text:SetText("Category Name")

    function btn:Enable()
		self.disabled = false

		self.bg:SetDesaturated(false)
		self.icon:SetDesaturated(false)
		self.iconBorder:SetDesaturated(false)
		self.text:SetFontObject(GameFontNormal)
	end

	function btn:Disable()
		self.disabled = true

		self.bg:SetDesaturated(true)
		self.icon:SetDesaturated(true)
		self.iconBorder:SetDesaturated(true)
		self.text:SetFontObject(GameFontDisable)
	end

    btn:SetScript("OnEnter", function(self)
    	SharedGossip:OnEnterDisplayTooltip(self)

		if self.disabled and (self.disableLine) then
			GameTooltip:AddLine(self.disableLine, 1, 0, 0, 1)
			GameTooltip:Show()
		elseif not(self.disabled) then
			self.text:SetFontObject(GameFontHighlight)
		end

    	self.highlight:Show()
	end)

	btn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		if not(self.disabled) then
			self.text:SetFontObject(GameFontNormal)
		end
		self.highlight:Hide()
	end)

	btn:SetScript("OnMouseDown", function(self)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", 14, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.text:SetPoint("LEFT", self.icon, "RIGHT", 12, 0)
	end)

    return btn
end

function SharedGossip:AddCurrency(name, parent)
	local frame = CreateFrame("FRAME", "$parent."..name, parent)
	frame:SetWidth(parent:GetWidth())
	frame:SetHeight(32)
	frame:EnableMouse(true)

	frame.title = frame:CreateFontString(nil)
	frame.title:SetFontObject(GameFontNormalSmall)
	frame.title:SetPoint("LEFT", 8, 0)
	frame.title:SetText("Marks of Ascension")

	frame.icon = frame:CreateTexture(nil, "BORDER")
    frame.icon:SetPoint("RIGHT", -8, 0)
    frame.icon:SetSize(20, 20)

	frame.total = frame:CreateFontString(nil)
	frame.total:SetFontObject(GameFontHighlight)
	frame.total:SetPoint("RIGHT", frame.icon, "LEFT", -4, 0)
	frame.total:SetText("12345")

	frame.highlight = frame:CreateTexture(nil, "OVERLAY")
	frame.highlight:SetAtlas("auctionhouse-ui-row-select", Const.TextureKit.IgnoreAtlasSize)
	frame.highlight:SetPoint("TOPLEFT")
	frame.highlight:SetPoint("BOTTOMRIGHT")
	frame.highlight:SetBlendMode("ADD")
	frame.highlight:Hide()

    --[[frame.ring = frame:CreateTexture(nil, "ARTWORK")
    frame.ring:SetAtlas("services-cover-ring", Const.TextureKit.IgnoreAtlasSize)
    frame.ring:SetPoint("CENTER", frame.icon, 0, -2)
    frame.ring:SetSize(56, 56)]]--

    function frame:BAG_UPDATE()
    	if not(self.item) then
    		return
    	end

    	self.total:SetText(GetItemCount(self.item))
    end

	function frame:SetItem(itemID)
	    local item = Item:CreateFromID(itemID)

	    if self.cancelToken then
	        self.cancelToken()
	        self.cancelToken = nil
	    end

	    self.cancelToken = item:CancelableContinueOnLoad(function()
	        if not item:IsCached() then
	            dprint("Tried to cache Item", itemID, "but it doesn't exist?")
	            return
	        end

			self.item = itemID
			self.icon:SetTexture(GetItemIcon(self.item))
			self.title:SetText(item:GetInfo())
			self:BAG_UPDATE()
	    end)
	end

    frame:SetScript("OnEnter", function(self)
    	if (self.item) then
    		self.highlight:Show()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink("item:"..self.item)
			GameTooltip:Show()
		end
	end)

	frame:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		self.highlight:Hide()
	end)

	frame:SetScript("OnShow", function(self)
		self:HookEvent("BAG_UPDATE")
		self:BAG_UPDATE()
	end)

	frame:SetScript("OnHide", function(self)
		self:UnhookEvent("BAG_UPDATE")
	end)

    return frame
end

function SharedGossip:CreateTabMenuTemplate(parent)
	parent.Tabs = CreateFrame("FRAME", "$parent.Tabs", parent, "InsetFrameTemplate")
	parent.Tabs:SetPoint("BOTTOMLEFT", 4, 6)
	parent.Tabs:SetSize(202, 436)

	parent.Tabs.cornerTopLeft = parent.Tabs:CreateTexture(nil, "ARTWORK")
	parent.Tabs.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.Tabs.cornerTopLeft:SetSize(73, 74)
	parent.Tabs.cornerTopLeft:SetPoint("TOPLEFT")

	parent.Tabs.cornerTopRight = parent.Tabs:CreateTexture(nil, "ARTWORK")
	parent.Tabs.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.Tabs.cornerTopRight:SetSize(73, 74)
	parent.Tabs.cornerTopRight:SetPoint("TOPRIGHT")
	parent.Tabs.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)
		
	parent.Tabs.shadowTop = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
	parent.Tabs.shadowTop:SetAlpha(0.6)

	parent.Tabs.cornerBottomLeft = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.Tabs.cornerBottomLeft:SetSize(73, 74)
	parent.Tabs.cornerBottomLeft:SetPoint("BOTTOMLEFT")
	parent.Tabs.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)

	parent.Tabs.cornerBottomRight = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.Tabs.cornerBottomRight:SetSize(73, 74)
	parent.Tabs.cornerBottomRight:SetPoint("BOTTOMRIGHT")
	parent.Tabs.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)

	parent.Tabs.shadowBottom = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
	parent.Tabs.shadowBottom:SetAlpha(0.6)

	parent.Tabs.shadowLeft = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
	parent.Tabs.shadowLeft:SetAlpha(0.6)

	parent.Tabs.shadowRight = parent.Tabs:CreateTexture(nil, "OVERLAY")
	parent.Tabs.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
	parent.Tabs.shadowRight:SetAlpha(0.6)

	parent.Tabs.shadowTop:SetPoint("TOPLEFT", parent.Tabs.cornerTopLeft, "TOPRIGHT")
	parent.Tabs.shadowTop:SetPoint("BOTTOMRIGHT", parent.Tabs.cornerTopRight, "BOTTOMLEFT")

	parent.Tabs.shadowBottom:SetPoint("TOPLEFT", parent.Tabs.cornerBottomLeft, "TOPRIGHT")
	parent.Tabs.shadowBottom:SetPoint("BOTTOMRIGHT", parent.Tabs.cornerBottomRight, "BOTTOMLEFT")

	parent.Tabs.shadowLeft:SetPoint("TOPLEFT", parent.Tabs.cornerTopLeft, "BOTTOMLEFT")
	parent.Tabs.shadowLeft:SetPoint("BOTTOMRIGHT", parent.Tabs.cornerBottomLeft, "TOPRIGHT")

	parent.Tabs.shadowRight:SetPoint("TOPLEFT", parent.Tabs.cornerTopRight, "BOTTOMLEFT")
	parent.Tabs.shadowRight:SetPoint("BOTTOMRIGHT", parent.Tabs.cornerBottomRight, "TOPRIGHT")

	function parent.Tabs:AddCurrency(name)
		return SharedGossip:AddCurrency(name, self)
	end

	return parent.Tabs
end

function SharedGossip:CreateContent(parent)
	parent.content = CreateFrame("FRAME", "$parent.content", parent, "InsetFrameTemplate")
	parent.content:SetSize(573,436)
	parent.content:SetPoint("BOTTOMRIGHT",-5,6)

	-- shadow for inner left window
	parent.content.cornerTopLeft = parent.content:CreateTexture(nil, "ARTWORK")
	parent.content.cornerTopLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.content.cornerTopLeft:SetSize(147, 149)
	parent.content.cornerTopLeft:SetPoint("TOPLEFT")

	parent.content.cornerTopRight = parent.content:CreateTexture(nil, "ARTWORK")
	parent.content.cornerTopRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.content.cornerTopRight:SetSize(147, 149)
	parent.content.cornerTopRight:SetPoint("TOPRIGHT")
	parent.content.cornerTopRight:SetTexCoord(0.464844, 0.181641, 0.416016, 0.703125)

	parent.content.shadowTop = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.shadowTop:SetTexture("Interface\\COMMON\\ShadowOverlay-Top")
	parent.content.shadowTop:SetAlpha(0.6)

	parent.content.cornerBottomLeft = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.cornerBottomLeft:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.content.cornerBottomLeft:SetSize(147, 149)
	parent.content.cornerBottomLeft:SetPoint("BOTTOMLEFT")
	parent.content.cornerBottomLeft:SetTexCoord(0.181641, 0.464844, 0.703125, 0.416016)

	parent.content.cornerBottomRight = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.cornerBottomRight:SetAtlas("collections-background-shadow-large", Const.TextureKit.IgnoreAtlasSize)
	parent.content.cornerBottomRight:SetSize(147, 149)
	parent.content.cornerBottomRight:SetPoint("BOTTOMRIGHT")
	parent.content.cornerBottomRight:SetTexCoord(0.464844, 0.181641, 0.703125, 0.416016)

	parent.content.shadowBottom = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.shadowBottom:SetTexture("Interface\\COMMON\\ShadowOverlay-Bottom")
	parent.content.shadowBottom:SetAlpha(0.6)
	
	parent.content.shadowLeft = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.shadowLeft:SetTexture("Interface\\COMMON\\ShadowOverlay-left")
	parent.content.shadowLeft:SetAlpha(0.6)

	parent.content.shadowRight = parent.content:CreateTexture(nil, "OVERLAY")
	parent.content.shadowRight:SetTexture("Interface\\COMMON\\ShadowOverlay-Right")
	parent.content.shadowRight:SetAlpha(0.6)

	parent.content.shadowTop:SetPoint("TOPLEFT", parent.content.cornerTopLeft, "TOPRIGHT")
	parent.content.shadowTop:SetPoint("BOTTOMRIGHT", parent.content.cornerTopRight, "BOTTOMLEFT")

	parent.content.shadowBottom:SetPoint("TOPLEFT", parent.content.cornerBottomLeft, "TOPRIGHT")
	parent.content.shadowBottom:SetPoint("BOTTOMRIGHT", parent.content.cornerBottomRight, "BOTTOMLEFT")

	parent.content.shadowLeft:SetPoint("TOPLEFT", parent.content.cornerTopLeft, "BOTTOMLEFT")
	parent.content.shadowLeft:SetPoint("BOTTOMRIGHT", parent.content.cornerBottomLeft, "TOPRIGHT")

	parent.content.shadowRight:SetPoint("TOPLEFT", parent.content.cornerTopRight, "BOTTOMLEFT")
	parent.content.shadowRight:SetPoint("BOTTOMRIGHT", parent.content.cornerBottomRight, "TOPRIGHT")

	return parent.content
end

function SharedGossip:CreateTimer(parent)
	parent.total = parent:CreateFontString(nil, "OVERLAY")
	parent.total:SetFontObject(GameFontHighlightSmall)
	parent.total:SetJustifyH("RIGHT")
	parent.total:SetPoint("RIGHT", -4, 0)
	parent.total:SetText("")

	parent.timer = CreateFromMixins("gossipTimer")
	parent.timer.parent = parent

	function parent.timer:FormatNumber(number)
		if number < 10 then
			number = "0"..number
		end

		return number
 	end

	function parent.timer:onTickFunction()
		local days, hours, minutes, seconds = self:GetTimeValues()

		if (days > 0) then
		  	self.parent.total:SetText(SecondsToTime(self.endTime, true, true, 2))
		else
			hours = self:FormatNumber(hours)
			minutes = self:FormatNumber(minutes)
			seconds = self:FormatNumber(seconds)
			self.parent.total:SetText(hours..":"..minutes..":"..seconds)
		end
	end

	return parent.total, parent.timer
end
-------------------------------------------------------------------------------
--                                 Main class                                --
-------------------------------------------------------------------------------
-- TODO: Gossip with multiple pages solution

function SharedGossip:CreateGossipFrame(name, template)
	template = template or "PortraitFrameTemplate"

	local frame = CreateFrame("FRAME", name, UIParent, template)
	frame.DIGITS = self.DIGITS -- TODO: find better fix
	frame.DEFAULT_SPEC_NAMES = self.DEFAULT_SPEC_NAMES  -- TODO: find better fix
	frame.MAX_LEVEL = self.MAX_LEVEL -- TODO: find better fix
	-- set up for each
	-- structure:
	-- {hook = {event = "PLAYER_MONEY", triggerOnShow = boolean}}
	-- hooked methods should behave as . declared methods
	frame.hooks = {}

	-- do not edit
	-- filled by SetGossipOption(button, option, editOnClick) method
	frame.gossipButtons = {}

	-- set up for each
	-- example: { ["hand of fate reversal"] = "REVERSAL", ...}
	frame.internalGossipOptions = {}

	-- set up for each
	-- structure:
	-- { OPTION_NAME = optionID, ... }
	-- set options' values to 0 by default (means not active). Use frame:DefineGossipOption(gossipButtonText) to set up proper option ID
	-- example: {REVERSAL = 0, ...}
	frame.gossipOptions = {}

	-- filled only for gossips with right panel which has tabs. Call frame:CreateTab(name) to create
	frame.tabs = {}

	-- code scans for active and available quests by itself
	frame.activeQuests = {}
	frame.availableQuests = {}
	-- questList includes both active and available quests in the end
	frame.questList = {}

	-- set up for each if needed
	-- this gossip option gonna be called next gossip hello if set up
	frame.delayedOption = nil

	frame:SetFrameStrata("DIALOG")
	
	frame:SetScript("OnHide", function(self)
		for _, hook in pairs(self.hooks) do
			C_Hook:Unregister(self, hook.event)
		end

		CloseGossip()
	end)

	function frame:ScanGossipText(text)
		-- set up for each
	end

	function frame:FormatGossipOptionText(text)
		-- set up for each
		-- in this method you can edit option text before 
		-- activating scan from internalGossipOptions
		-- for example remove icons, take some info from button text and such
		-- example: return string.gsub(text, "^|.*|.", "") -- will return text without icon/color in the start of text
		return text
	end

	function frame:ScanQuestIDs()

		if next(self.activeQuests) then
			local questIDs = GetActiveGossipQuestIds()
			for i = 1, #self.activeQuests do
				local ID = questIDs[i]
				if (ID) then
					self.activeQuests[i].ID = ID
				end
			end
		end

		if next(self.availableQuests) then
			local questIDs = GetAvailableGossipQuestIds()
			for i = 1, #self.availableQuests do
				local ID = questIDs[i]
				if (ID) then
					self.availableQuests[i].ID = ID
				end
			end
		end
	end

	function frame:ScanGossipActiveQuests(...)
		--dprint(self:GetName()..": ScanGossipActiveQuests")
		local name, level, isTrivial, isComplete, buttonIndex
		local buttonIndex = 1

		for i=1, select("#", ...), 4 do
			name = select(i, ...)
			--level = select(i+1, ...) -- not used 
			--isTrivial = select(i+2, ...) -- not used 
			isComplete = select(i+3, ...)

			table.insert(self.activeQuests, {ID = nil, name = name, isComplete = isComplete, buttonIndex = buttonIndex, isActive = true})

			buttonIndex = buttonIndex + 1
		end
	end

	function frame:ScanGossipAvailableQuests(...)
		--dprint(self:GetName()..": ScanGossipAvailableQuests")
		local name, level, isTrivial, isDaily, isRepeatable, buttonIndex
		local buttonIndex = 1

		for i=1, select("#", ...), 5 do
			name = select(i, ...)
			--level = select(i+1, ...) -- not used 
			--isTrivial = select(i+2, ...) -- not used 
			isDaily = select(i+3, ...)
			--isRepeatable = select(i+4, ...) -- not used 
			table.insert(self.availableQuests, {ID = nil, name = name, isDaily = isDaily, buttonIndex = buttonIndex, isActive = false})

			buttonIndex = buttonIndex + 1
		end
	end

	function frame:ScanGossipQuests()
		self.activeQuests = {}
		self.availableQuests = {}

		if (GetNumGossipAvailableQuests() ~= 0) then
			self:ScanGossipAvailableQuests(GetGossipAvailableQuests())
		end

		if (GetNumGossipActiveQuests() ~= 0) then
			self:ScanGossipActiveQuests(GetGossipActiveQuests())
		end

		self:ScanQuestIDs()
	end

	function frame:UpdateQuestButtons()
		-- merge quest list
		local questList = {unpack(self.activeQuests)}

		if (next(self.availableQuests)) then
			for i = 1, #self.availableQuests do
				table.insert(questList, self.availableQuests[i])
			end
		end

		self.questList = questList or {}
		-- set up for each
	end

	function frame:DefineGossipOption(text, buttonIndex)
		local optionInternal = self.internalGossipOptions[text]

		if (optionInternal) then
			self.gossipOptions[optionInternal] = buttonIndex
		else
			dprint(self:GetName()..": Gossip option "..text.." not found")
		end
	end

	function frame:ScanGossipOptions(...)
		for k, v in pairs(self.gossipOptions) do
			self.gossipOptions[k] = 0
		end

		local buttonIndex = 1

		for i=1, select("#", ...), 2 do
			local text = string.lower(select(i, ...))
			text = self:FormatGossipOptionText(text)
			-- TODO: Rework it so string lower happens after defining gossip option probably
			self:DefineGossipOption(text, buttonIndex, select(i, ...))

			buttonIndex = buttonIndex + 1
		end
	end

	function frame:LoadGossipButton(btn) -- checks if option is found in gossip 
		local gossipOption = btn.gossipOption

		if not(gossipOption) then
			dprint(self:GetName()..": No option for button "..btn:GetName().." remove from gossip button list")
			return
		end

		local option = self.gossipOptions[gossipOption]

		if not(option) then
			dprint(self:GetName()..": option "..gossipOption.." does not exist, remove from list")
			return
		end

		return option
	end

	function frame:UpdateGossipButtons()
		for _, btn in pairs(self.gossipButtons) do
			local option = self:LoadGossipButton(btn)

			if option and option ~= 0 then
				btn:Enable()
			else
				btn:Disable()
			end
		end
	end

	function frame:ClickGossipOption(button)
		if (button.gossipOption) then
			local option = frame.gossipOptions[button.gossipOption]
			if (option and (option ~= 0) ) then
				dprint("|cffFFFF00["..frame:GetName()..":ClickGossipOption] Select "..button.gossipOption)
				SelectGossipOption(option)
			end
		end
	end

	function frame:ClickGossipOptionOrGoBackAndSetDelayed(button)
		if not(button.gossipOption) then
			return
		end

		if (self.gossipOptions["BACK"] and self.gossipOptions["BACK"] ~= 0) then
			self.delayedOption = button.gossipOption
			SelectGossipOption(frame.gossipOptions["BACK"])
			return
		end

		self:ClickGossipOption(button)
	end

	function frame:CheckForDelayedOption()
		if (self.delayedOption) then
			self:ClickGossipOption({gossipOption = self.delayedOption})
			self.delayedOption = nil
		end
	end

	 -- to not to check for gossip option each time button status changes from external
	 -- button will be impossible to enable if gossip option not found
	function frame:SyncButtonWithGossipOption(button)
		button.EnableOld = button.Enable

		function button:Enable()
			local option = frame.gossipOptions[self.gossipOption]

			if (option and (option ~= 0) ) then
				self:EnableOld()
			end
		end
	end

	function frame:SetGossipOption(button, option, editOnClick)
		button.gossipOption = option
		table.insert(self.gossipButtons, button)

		local onClick = button:GetScript("OnClick")
		button.onClick = onClick

		if (editOnClick) then
			button:SetScript("OnClick", function(self, ...)
				if (self.onClick) then
					self:onClick(self, ...)
				end
				
				frame:ClickGossipOption(self, ...)
			end)
		end
	end

	function frame:ScanGossip()
		dprint(self:GetName()..": ScanGossip") -- DEBUG

		local targetName = UnitName("NPC")

		if (targetName) then
			if (self.portrait) then
				SetPortraitTexture(self.portrait, "NPC")
			end

			if (self.TitleText) then
				self.TitleText:SetText(targetName)
			end
		end
		
		self:ScanGossipText(string.lower(GetGossipText()))
		self:ScanGossipQuests()
		self:ScanGossipOptions(GetGossipOptions())
		self:UpdateGossipButtons()
		self:UpdateQuestButtons()
		self:CheckForDelayedOption()

		for _, hook in pairs(self.hooks) do
			C_Hook:Register(self, hook.event)
			if (hook.triggerOnShow) then
				self[hook.event]()
			end
		end
	end

	function frame.OnGossipShow()
		C_Gossip:SilentHideGossip()
		ShowUIPanel(frame)
		frame:ScanGossip()
	end

	function frame.OnGossipHide()
		C_Gossip:RestoreGossip()
		HideUIPanel(frame)
	end

	function frame:RegisterGossip(npc)
		self.NPC = npc

		if (type(self.NPC) == "table") then
			for _, npc in pairs(self.NPC) do
				C_Gossip:RedirectNPC(npc, self.OnGossipShow, self.OnGossipHide)
			end
		elseif (type(self.NPC) == "number") then
			C_Gossip:RedirectNPC(self.NPC, self.OnGossipShow, self.OnGossipHide)
		end
	end

	UIPanelWindows[frame:GetName()] = { area = "center", pushable = 0, whileDead = 1, allowOtherPanels = true, dontCloseForNonCenterPanels = true }

	return frame
end

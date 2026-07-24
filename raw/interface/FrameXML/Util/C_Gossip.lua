C_Gossip = {
	_redirectNPC = {
		show = {},
		hide = {},
	},
	_redirectItem = {
		show = {},
		hide = {},
	},
	_hookNPC = {
		show = {},
		hide = {},
		generateHandle = CreateCounter(),
	},
	_hookItem = {
		show = {},
		hide = {},
		generateHandle = CreateCounter(),
	}
}

function C_Gossip:MakeGroup(...)
	return {...}
end

function C_Gossip:RedirectNPC(id, show, hide)
	self._redirectNPC.show[id] = show
	self._redirectNPC.hide[id] = hide
end

function C_Gossip:RemoveRedirectNPC(id)
	self._redirectNPC.show[id] = nil
	self._redirectNPC.hide[id] = nil
end

function C_Gossip:RemoveRedirectNPCs(group)
	for _, id in ipairs(group) do
		self:RemoveRedirectNPC(id)
	end
end

function C_Gossip:RedirectNPCs(group, show, hide)
	for _, id in ipairs(group) do
		self:RedirectNPC(id, show, hide)
	end
end

function C_Gossip:HookNPC(id, show, hide)
	local hooks = self._hookNPC
	local handle = hooks.generateHandle()
	if show then
		hooks.show[id] = hooks.show[id] or {}
		hooks.show[id][handle] = show
	end

	if hide then
		hooks.hide[id] = hooks.hide[id] or {}
		hooks.hide[id][handle] = hide
	end
	
	return handle
end

function C_Gossip:HookNPCs(group, show, hide)
	local hooks = self._hookNPC
	local handle = hooks.generateHandle()

	for _, id in ipairs(group) do
		if show then
			hooks.show[id] = hooks.show[id] or {}
			hooks.show[id][handle] = show
		end

		if hide then
			hooks.hide[id] = hooks.hide[id] or {}
			hooks.hide[id][handle] = hide
		end
	end
	
	return handle
end

function C_Gossip:RemoveHookNPC(handle)
	for npc in pairs(self._hookNPC.show) do
		npc[handle] = nil
	end

	for npc in pairs(self._hookNPC.hide) do
		npc[handle] = nil
	end
end

function C_Gossip:CheckNPCShow(id)
	if self._redirectNPC.show[id] then
		securecall(self._redirectNPC.show[id])
		return true
	end
	
	return false
end

function C_Gossip:CheckNPCHide(id)
	if self._redirectNPC.hide[id] then
		securecall(self._redirectNPC.hide[id])
		return true
	end

	return false
end

function C_Gossip:CheckHookNPCShow(id)
	if self._hookNPC.show[id] then
		for _, func in pairs(self._hookNPC.show[id]) do
			func()
		end
	end
end

function C_Gossip:CheckHookNPCHide(id)
	if self._hookNPC.hide[id] then
		for _, func in pairs(self._hookNPC.hide[id]) do
			func()
		end
	end
end

function C_Gossip:RedirectItem(id, show, hide)
	self._redirectItem.show[id] = show
	self._redirectItem.hide[id] = hide
end

function C_Gossip:RemoveRedirectItem(id)
	self._redirectItem.show[id] = nil
	self._redirectItem.hide[id] = nil
end

function C_Gossip:RemoveRedirectItems(group)
	for _, id in ipairs(group) do
		self:RemoveRedirectItem(id)
	end
end

function C_Gossip:HookItem(id, show, hide)
	local hooks = self._hookItem
	local handle = hooks.generateHandle()
	if show then
		hooks.show[id] = hooks.show[id] or {}
		hooks.show[id][handle] = show
	end

	if hide then
		hooks.show[id] = hooks.show[id] or {}
		hooks.show[id][handle] = show
	end

	return handle
end

function C_Gossip:HookItems(group, show, hide)
	local hooks = self._hookItem
	local handle = hooks.generateHandle()

	for _, id in ipairs(group) do
		if show then
			hooks.show[id] = hooks.show[id] or {}
			hooks.show[id][handle] = show
		end

		if hide then
			hooks.show[id] = hooks.show[id] or {}
			hooks.show[id][handle] = show
		end
	end

	return handle
end

function C_Gossip:RemoveHookItem(handle)
	for item in pairs(self._hookItem.show) do
		item[handle] = nil
	end

	for item in pairs(self._hookItem.hide) do
		item[handle] = nil
	end
end

function C_Gossip:RedirectItems(group, show, hide)
	for _, id in ipairs(group) do
		self:RedirectItem(id, show, hide)
	end
end

function C_Gossip:CheckItemShow(id)
	if self._redirectItem.show[id] then
		securecall(self._redirectItem.show[id])
		return true
	end

	return false
end

function C_Gossip:CheckItemHide(id)
	if self._redirectItem.hide[id] then
		securecall(self._redirectItem.hide[id])
		return true
	end

	return false
end

function C_Gossip:CheckHookItemShow(id)
	if self._hookItem.show[id] then
		for _, func in pairs(self._hookItem.show[id]) do
			func()
		end
	end
end

function C_Gossip:CheckHookItemHide(id)
	if self._hookItem.hide[id] then
		for _, func in pairs(self._hookItem.hide[id]) do
			func()
		end
	end
end

function C_Gossip:SilentHideGossip()
	if not self.savedPos then
		self.savedPos = {}
	else
		wipe(self.savedPos)
	end

	for i = 1, GossipFrame:GetNumPoints() do
		tinsert(self.savedPos, { GossipFrame:GetPoint(i) })
	end
	
	GossipFrame:ClearAllPoints()
end

function C_Gossip:RestoreGossip()
	if not self.savedPos or #self.savedPos == 0 then
		return
	end

	for _, point in pairs(self.savedPos) do
		GossipFrame:SetPoint(unpack(point))
	end

	wipe(self.savedPos)
end

function C_Gossip:GOSSIP_SHOW()
	local npcID = GetCreatureIDFromUnit("npc")
	
	if npcID then
		-- handle hooks
		if self.currentHookNPC and self.currentHookNPC ~= npcID then
			self:CheckHookNPCHide(self.currentHookNPC)
			self.currentHookNPC = nil
		end

		if self:CheckHookNPCShow(npcID) then
			self.currentHookNPC = npcID
		end
		
		-- handle redirectors
		if self.currentNPC and self.currentNPC ~= npcID then
			self:CheckNPCHide(self.currentNPC)
			self.currentNPC = nil
		end

		if self:CheckNPCShow(npcID) then
			self.currentNPC = npcID
			return
		end
	else
		-- cleanup hooks / redirectors if needed
		if self.currentHookNPC then
			self:CheckHookNPCHide(self.currentHookNPC)
			self.currentHookNPC = nil
		end

		if self.currentNPC then
			self:CheckNPCHide(self.currentNPC)
			self.currentNPC = nil
		end
	end

	local itemID, timeSinceUsed = C_Item:GetLastUsedItemID()
	if timeSinceUsed:LessThan(0.1) or self.currentItem == itemID then
		-- handle hooks
		if self.currentHookItem and self.currentHookItem ~= itemID then
			self:CheckHookItemHide(self.currentHookItem)
			self.currentHookItem = nil
		end

		if self:CheckHookItemShow(itemID) then
			self.currentHookItem = itemID
		end

		-- handle redirectors
		if self.currentItem and self.currentItem ~= itemID then
			self:CheckItemHide(self.currentItem)
			self.currentItem = nil
		end

		if self:CheckItemShow(itemID) then
			self.currentItem = itemID
			return
		end
	else
		if self.currentHookItem then
			self:CheckHookItemHide(self.currentHookItem)
			self.currentHookItem = nil
		end

		if self.currentItem then
			self:CheckItemHide(self.currentItem)
			self.currentItem = nil
		end
	end

	-- if there is only a non-gossip option, then go to it directly
	if (GetNumGossipAvailableQuests() == 0) and (GetNumGossipActiveQuests() == 0) and (GetNumGossipOptions() == 1) and not ForceGossip() then
		local _, gossipType = GetGossipOptions()
		if ( gossipType ~= "gossip" ) then
			SelectGossipOption(1)
			return
		end
	end

	if self.savedPos and #self.savedPos > 0 then
		self:RestoreGossip()
	end

	if not GossipFrame:IsShown() then
		ShowUIPanel(GossipFrame)
		if not GossipFrame:IsShown() then
			CloseGossip()
			return
		end
	end
	GossipFrameUpdate()
end 

function C_Gossip:GOSSIP_CLOSED()
	if self.currentNPC then
		local id = self.currentNPC
		self.currentNPC = nil
		if self:CheckNPCHide(id) then
			CloseGossip()
			return
		end
	end

	if self.currentItem then
		local id = self.currentItem
		self.currentItem = nil
		if self:CheckItemHide(id) then
			CloseGossip()
			return
		end
	end

	if GossipFrame:IsShown() then
		HideUIPanel(GossipFrame)
	end
	CloseGossip()
end 

C_Hook:Register(C_Gossip, "GOSSIP_SHOW, GOSSIP_CLOSED")
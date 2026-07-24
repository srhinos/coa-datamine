SocketKeystoneFrameMixin = {}

function SocketKeystoneFrameMixin:SetKeystone()
	local keystoneID = C_Keystones.GetKeystoneInInventoryItemID()
	if not keystoneID then
		dprint("Couldn't find keystone to activate!")
		return
	end

	local keystoneInfo = C_MythicPlus.GetKeystoneInfo(keystoneID)

	self.Keystone.Information.LevelText:SetFormattedText("+%d", keystoneInfo.keystoneLevel)
	local dungeonName = GetLFGDungeonInfo(keystoneInfo.dungeonID)
	self.Keystone.Information.DungeonText:SetText(dungeonName:gsub(" %- ", "|n"):gsub(": ", "|n"))

	local affixCount = MClamp(#keystoneInfo.affixIDs + 3, 3, 8)

	for index, button in ipairs(self.AffixButtons) do
		-- show health / spell damage / melee damage first
		if index < 4 then
			button:SetStaticAffix(keystoneInfo, index)
		else
			button:SetAffix(keystoneInfo.affixIDs[index-3])
		end
	end
	
	if not self:IsShown() then
		self:Show()
	end

	self.Background:SetAtlas("mythic-keystone-backdrop-"..affixCount)
	self.DialGlow:SetAtlas("mythic-keystone-dial-glow-"..affixCount, Const.TextureKit.UseAtlasSize)
	self.DialGlow:Hide()
	self.Dial.Animation:Play()
	PlaySound(SOUNDKIT.GO_CHALLENGEMODE_PEDESTAL_OPEN01_80)
end
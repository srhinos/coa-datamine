BuildDraftSelectRoleMixin = {}

function BuildDraftSelectRoleMixin:OnShow()
	self.ConfirmButton:Disable()

	for _, button in ipairs(self.Buttons) do
		button:SetSelected(false)
	end
end

function BuildDraftSelectRoleMixin:SetRole(mask)
	self.role = mask
	self.ConfirmButton:SetEnabled(self.role ~= nil)
	for _, button in ipairs(self.Buttons) do
		button:SetSelected(self.role == button.roleMask)
	end
end

function BuildDraftSelectRoleMixin:ConfirmRoles()
	if not self.role then return end

	local roleStr = ""
	local buildRole
	
	if self.role == Enum.LFGRoles.Tank then
		roleStr = ROLE_COLORS["TANK"]:WrapText(TANK)
		buildRole = "PLAYER_ROLE_TANK"
	elseif self.role == Enum.LFGRoles.Damager then
		roleStr = ROLE_COLORS["DAMAGE"]:WrapText(DAMAGER)
		buildRole = "PLAYER_ROLE_DAMAGE"
	elseif self.role == Enum.LFGRoles.Healer then
		roleStr = ROLE_COLORS["HEALER"]:WrapText(HEALER)
		buildRole = "PLAYER_ROLE_HEALER"
	end
	
	local callback = function()
		C_BuildDraft.SelectRole(buildRole)
		self:Hide()
	end

	StaticPopup_Show("BUILD_DRAFT_SELECT_ROLES_CONFIRM", roleStr, nil, callback)
end
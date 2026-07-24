local function ToggleFStack(msg)
	if InGlue() then
		if FStackTooltip:IsShown() then
			FStackTooltip:Hide()
		else
			FStackTooltip:SetOwner(GlueParent)
			FStackTooltip:SetFrameStack(toboolean(msg))
		end

	else
		UIParentLoadAddOn("Blizzard_DebugTools")
		FrameStackTooltip_Toggle(toboolean(msg))
	end
end

DevConsole:RegisterCommand("fstack", "Shows the frame stack", ToggleFStack)
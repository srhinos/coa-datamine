local frame
function ShowExtensionError()
	if not frame then
		frame = CreateFrame("Frame", "ExtensionErrorFrame", UIParent, "ExtensionErrorFrameTemplate")
	end

	frame:Show()
	Timer.After(0.4, function()
		PlaySound(5495) -- boat docking sound
	end)
end

C_Hook:Register("ExtensionError", "PLAYER_ENTERING_WORLD", function()
	if not IsExtensionsLoaded or not IsExtensionsLoaded() then
		ShowExtensionError()
	else
		C_Hook:Unregister("ExtensionError")
	end
end)

ExtensionErrorFrameMixin = {
	Images = {
		[2] = "launcher-open-settings",
		[3] = "launcher-open-game-dir",
		[6] = "launcher-repair",
		[7] = "icon-help-button",
	}
}

function ExtensionErrorFrameMixin:SetImage(id)
	if self.Images[id] then
		self.Content.Image:SetAtlas(self.Images[id], Const.TextureKit.UseAtlasSize)
		self.Content.Image:Show()
	end
end

function ExtensionErrorFrameMixin:ClearImage()
	self.Content.Image:Hide()
end

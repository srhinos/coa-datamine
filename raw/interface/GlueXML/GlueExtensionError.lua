local Panels = {
    {
        title = "Critical Game Files are Missing!",
        body = "Your game installation is missing critical files required to play!|n|nThis likely has occurred due to a |cffffd100false-positive|r from your antivirus software|n|cff00d1ffWindows Defender also counts!|r|n|nPlease follow the steps provided to resolve this issue!",
    },
    {
        title = "Navigate to your anti-virus software",
        body = "For Windows Defender you can find this by doing the following:|n|n1) Press the Windows Key|n|n2) Type |cffffd100Windows Security|r|n|n3) Click on |cffffd100Virus & threat protection|r",
    },
    {
        title = "Allow Ascension files in your anti-virus",
        body = "For Windows Defender:|n|n1) Click on |cffffd100Protection history|r|n|n2) Look for a recent |cffffd100Threat Blocked|r event|n2a) It should say something about |cff00d1ffExtensions.dll or Wacatac.B!ml|r!|n|n3) Click on the |cffffd100Actions|r button|n|n7) Click on |cffffd100Allow|r"
    },
    {
        atlas = "launcher-open-settings",
        title = "Open the Launcher Settings",
        body = "In your Ascension Launcher|nlocate the |cffffd100Settings Gear Icon|r|nin the top right corner",
    },
    {
        atlas = "launcher-repair",
        title = "Shut down the Game Client and Repair",
        body = "|cff00d1ffExit the Game|r|n|nClick on Repair Client|n|nThe game will launch itself after the repair is complete.",
        showCloseButton = true,
    },
    {
        title = "Alternate Solutions",
        body = "You may try adding an exception for the Ascension Game Folder.|n|nFor Windows Defender:|n|n1) Under Virus & threat protection settings select |cffffd100Manage Settings|r|n|n2) Under Exclusions select |cffffd100Add or remove exclusions|r|n|n3) Select add an exclusion, and add the Ascension Game Folder|n|n3a) If you cannot find the Game Folder, on the launcher select the |cffffd100settings gear icon|r and click |cffffd100Open Game Directory|r|n|n4) Repair the client again.",
        showCloseButton = true,
    },
    {
        atlas = "discord-support-ticket",
        title = "If you continue to have issues",
        body = "Please visit our discord server at |cffffd100discord.gg/customwow|r|n|nFollow instructions in the |cffffd100#support-ticket|r channel to get help from our staff."
    }
}
--launcher-open-settings
--launcher-repair
--discord-support-ticket
GlueExtensionErrorMixin = {}

function GlueExtensionErrorMixin:OnShow()
    GlueDialog:UnregisterAllEvents()
    GlueDialog:Hide()
    if GMAccountLoginDropDown then
        GMAccountLoginDropDown:Hide()
    end

    self.Display.Progress:SetMinMaxValues(0, #Panels)
    self:SetPanel(1)
end

function GlueExtensionErrorMixin:UpdateButtonStates()
    self.Display.NextButton:SetEnabled(Panels[self.index + 1] ~= nil)
    self.Display.BackButton:SetEnabled(Panels[self.index - 1] ~= nil)
end

function GlueExtensionErrorMixin:OnKeyDown(key)
    if key == "R" then
        ConsoleExec("reloadui")
    end
end 

function GlueExtensionErrorMixin:SetImage(atlas)
    if atlas then
        self.Display.HintImage:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
        self.Display.HintImage:Show()
        self.Display.Body:SetJustifyH("LEFT")
        self.Display.Body:SetWidth(248)
    else
        self.Display.HintImage:Hide()
        self.Display.Body:SetJustifyH("CENTER")
        self.Display.Body:SetWidth(482)
    end
end

function GlueExtensionErrorMixin:SetTitle(text)
    self.Display.Title:SetText(text)
end

function GlueExtensionErrorMixin:SetBody(text)
    self.Display.Body:SetText(text)
end

function GlueExtensionErrorMixin:SetPanel(index)
    self.index = index
    local panel = Panels[self.index]
    self:SetImage(panel.atlas)
    self:SetTitle(panel.title)
    self:SetBody(panel.body)
    if panel.showCloseButton then
        self.Display.CloseButton:Show()
    else
        self.Display.CloseButton:Hide()
    end
    self:UpdateButtonStates()
    self.Display.Progress:SetValue(self.index)
    self.Display.Progress.Text:SetText(self.index .. "/" .. #Panels)
end

function GlueExtensionErrorMixin:OnBack()
    if Panels[self.index - 1] then
        self:SetPanel(self.index - 1)
    end
end 

function GlueExtensionErrorMixin:OnNext()
    if Panels[self.index + 1] then
        self:SetPanel(self.index + 1)
    end
end 
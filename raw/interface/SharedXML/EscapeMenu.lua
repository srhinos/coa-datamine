local SECTION_SPACING = 16

EscapeMenuMixin = {}

EscapeMenuSection = {
    Help = 1,
    Options = 2,
    AddOns = 3,
    Quit = 4,
}

function EscapeMenuMixin:OnLoad()
    self.minHeight = 248
    self.sections = {
        [EscapeMenuSection.Help] = {},
        [EscapeMenuSection.Options] = {},
        [EscapeMenuSection.AddOns] = {},
        [EscapeMenuSection.Quit] = {},
    }

    self:AddSharedButtons()

    if InGlue() then
        self:AddGlueButtons()
    else
        self:AddGameButtons()
    end
end

function EscapeMenuMixin:AddSharedButtons()
    -- Quit Section -- 
    -- Close Button Always First
    self:AddButton(CLOSE, EscapeMenuSection.Quit, nil, nil, true)

    self:AddButton(EXIT_GAME, EscapeMenuSection.Quit, function()
        if InGlue() then
            QuitGame()
        else
            Quit()
        end
    end, nil, true)

    self.LogoutButton = self:AddButton(LOGOUT, EscapeMenuSection.Quit, function()
        Logout()
    end, nil, true)
    
    -- Options Section -- 
    self:AddButton(VIDEOOPTIONS_MENU, EscapeMenuSection.Options, function()
        VideoOptionsFrame.lastFrame = self
        ShowUIPanel(VideoOptionsFrame)
    end, nil, true)

    self.SoundOptions = self:AddButton(VOICE_SOUND, EscapeMenuSection.Options, function()
        AudioOptionsFrame.lastFrame = self
        ShowUIPanel(AudioOptionsFrame)
    end, nil, true)
    
    self.AddSharedButtons = nop
end

function EscapeMenuMixin:AddGlueButtons()
    -- Quit Section -- 
    self.ChangeRealm = self:AddButton(CHANGE_REALM, EscapeMenuSection.Quit, function()
        RequestRealmList(1)
    end, nil, true)
    
    -- Help Section --
    if ToggleDevConsoleButton then
        self:AddButton("Dev Console", EscapeMenuSection.Help, function()
            ToggleDevConsoleButton:Click()
        end, nil, true)
    end
    
    -- Options Section --
    self:AddButton(MANAGE_ACCOUNT, EscapeMenuSection.Options, function()
        LaunchURL(AUTH_NO_TIME_URL)
    end)

    self:AddButton(COMMUNITY_SITE, EscapeMenuSection.Options, function()
        LaunchURL(COMMUNITY_URL)
    end)
    
    -- AddOns Section --
    self.ResetButton = self:AddButton(RESET_SETTINGS, EscapeMenuSection.AddOns, function()
        GlueDialog_Show("RESET_SERVER_SETTINGS");
    end)
    
    self.AddGlueButtons = nop
    self.AddGameButtons = nop
end

function EscapeMenuMixin:AddGameButtons()
    -- Help Section --
    self:AddButton(GM_HELP_LABEL, EscapeMenuSection.Help, function()
        ToggleHelpFrame()
    end, nil, true)
    
    self:AddButton(JOIN_DISCORD, EscapeMenuSection.Help, function()
        if DiscordFeaturesEnabled() then
            DiscordOpenGuildInvite("customwow")
        else
            local url = "https://discord.gg/customwow"
            StaticPopup_Show("OPEN_URL_DISCORD", url, nil, url)
        end
    end, nil, true)
    
    -- Options Section --
    self:AddButton(UIOPTIONS_MENU, EscapeMenuSection.Options, function()
        ShowUIPanel(InterfaceOptionsFrame)
        InterfaceOptionsFrame.lastFrame = self
    end, nil, true)

    if IsMacClient() then
        self:AddButton(MAC_OPTIONS, EscapeMenuSection.Options, function()
            ShowUIPanel(MacOptionsFrame)
        end, nil, true)
    end
    
    -- AddOns Section --
    self:AddButton(KEY_BINDINGS, EscapeMenuSection.AddOns, function()
        KeyBindingFrame_LoadUI()
        KeyBindingFrame.mode = 1
        ShowUIPanel(KeyBindingFrame)
    end, nil, true)
    
    self:AddButton(QUICK_KEYBINDING, EscapeMenuSection.AddOns, function()
        ToggleQuickKeybindMode()
    end, nil, true)
    
    self:AddButton(MACROS, EscapeMenuSection.AddOns, function()
        ShowMacroFrame()
    end, nil, true)
    
    self:AddButton(ADDONS, EscapeMenuSection.AddOns, function()
        ShowAddonsPanel()
    end, nil, true)
    
    self.AddGlueButtons = nop
    self.AddGameButtons = nop
end

function EscapeMenuMixin:OnShow()
    self:RefreshLayout()
    PlaySound("igMainMenuOpen")

    if InGlue() then
        self.Background:SetSize(GetScreenWidth(), GetScreenHeight())
        self.Background.FadeIn:Play()
        self.LogoutButton:SetEnabled(IsConnectedToServer() == 1)
        self.ChangeRealm:SetEnabled(IsConnectedToServer() == 1)
        self.ResetButton:SetEnabled(IsConnectedToServer() ~= 1)
    else
        UpdateMicroButtons()
        Disable_BagButtons()
        VoiceChat_Toggle()
        self.Background:Hide()
    end
end

function EscapeMenuMixin:OnHide()
    self.Background.FadeIn:Stop()
    PlaySound("igMainMenuClose")

    if not InGlue() then
        UpdateMicroButtons()
        Enable_BagButtons()
    end
end

local buttonCounter = CreateCounter()
function EscapeMenuMixin:AddButton(text, section, callback, index, hideEscapeMenu)
    if not issecure() then
        section = EscapeMenuSection.AddOns
    end
    assert(self.sections[section], "Invalid Section for EscapeMenu:AddButton() " .. section)

    local button = CreateFrame("Button", "$parentButton" .. buttonCounter(), self, "EscapeMenuButtonTemplate")
    if index and index > 0 then
        tinsert(self.sections[section], index, button)
    else
        tinsert(self.sections[section], button)
    end

    button:SetText(text)
    button.callback = callback
    button.hideEscapeMenu = hideEscapeMenu

    if self:IsShown() then
        self:RefreshLayout()
    end
    
    return button
end

function EscapeMenuMixin:RemoveButton(text)
    for section, buttons in pairs(self.sections) do
        for i, button in ipairs(buttons) do
            if button:GetText() == text then
                tremove(buttons, i)
                button:Hide()
                button:ClearAllPoints()
                return
            end
        end
    end
end

function EscapeMenuMixin:RefreshLayout()
    local nextTop = 24
    local shouldAddSpacer = false
    for _, button in ipairs(self.sections[EscapeMenuSection.Help]) do
        button:ClearAndSetPoint("TOP", self, "TOP", 0, -nextTop)
        nextTop = nextTop + button:GetHeight() + 2
        shouldAddSpacer = true
    end

    if shouldAddSpacer then
        nextTop = nextTop + SECTION_SPACING
    end

    shouldAddSpacer = false
    for _, button in ipairs(self.sections[EscapeMenuSection.Options]) do
        button:ClearAndSetPoint("TOP", self, "TOP", 0, -nextTop)
        nextTop = nextTop + button:GetHeight() + 2
        shouldAddSpacer = true
    end
    
    if shouldAddSpacer then
        nextTop = nextTop + SECTION_SPACING
    end

    shouldAddSpacer = false
    for _, button in ipairs(self.sections[EscapeMenuSection.AddOns]) do
        button:ClearAndSetPoint("TOP", self, "TOP", 0, -nextTop)
        nextTop = nextTop + button:GetHeight() + 2
        shouldAddSpacer = true
    end

    if shouldAddSpacer then
        nextTop = nextTop + SECTION_SPACING
    end
    
    local nextBottom = 16
    -- quit buttons build from bottom up
    for i, button in ipairs(self.sections[EscapeMenuSection.Quit]) do
        button:ClearAndSetPoint("BOTTOM", self, "BOTTOM", 0, nextBottom)
        nextBottom = nextBottom + button:GetHeight() + (i == 1 and 16 or 2) -- 1st button is always close button
    end

    local height = nextTop + nextBottom
    self:SetHeight(max(height, self.minHeight))
end 
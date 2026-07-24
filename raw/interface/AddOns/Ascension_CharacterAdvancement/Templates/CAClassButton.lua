CAClassButtonMixin = {}

function CAClassButtonMixin:OnLoad()
    self.Overlay:Hide()

    self:SetHighlightFontObject(GameFontHighlightOutline)
    self:SetNormalFontObject(GameFontNormalOutline)
    self:SetPushedTextOffset(1, -1)

    self.Text:SetDrawLayer("OVERLAY")
    self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 6, 0)

    self.tabPointsPool = CreateFramePool("Button", self, "ClassPointsTemplate")

    -- to work with CATalentGateCounterMixin
    self.GateText = self.Icon.ClassPoints.Text
end

function CAClassButtonMixin:SetClass(classFile)
    self.classFile = classFile
    self.classDBC = CharacterAdvancementUtil.GetClassDBCByFile(classFile)
    self.topTab = nil
    self.Icon:SetIconAtlas("class-round-"..classFile)
    self:SetText(LOCALIZED_CLASS_NAMES_MALE[classFile])
    self:UpdateSpellCounts()

    if self.Text:GetStringHeight() > 12 then
        self:SetHighlightFontObject(GameFontHighlightOutlineSmall)
        self:SetNormalFontObject(GameFontNormalOutlineSmall)
    end

    local color = RAID_CLASS_COLORS[classFile]

    if color then
        self.Background:SetVertexColor(color.r, color.g, color.b)
    end
end

function CAClassButtonMixin:UpdateSpellCounts()
    self.tabPointsPool:ReleaseAll()
    self.Text:Show()
    --self.Shadow:Hide()
    self.Icon.ClassPoints:Hide()

    if C_CVar.GetBool("previewCharacterAdvancementChanges") then
        local tabs = CHARACTER_ADVANCEMENT_CLASS_SPEC_ORDER[self.classFile]
        local class = CharacterAdvancementUtil.GetClassDBCByFile(self.classFile)

        local totalButtons = 0
        local firstButton, button

        local classPoints = C_CharacterAdvancement.GetClassPointInvestment(class, 0) or 0

        if classPoints and (classPoints > 0) then
            --self.Shadow:Show()
            self.Icon.ClassPoints:Show()
            self.Icon.ClassPoints:SetText(classPoints)

            self.tooltipTitle, self.tooltipText = CATalentGateCounterMixin.DefineTooltip(self, "CLASS", class)
        else
            self.tooltipTitle = nil
            self.tooltipText = nil
        end

        for i = 1, 3 do
            local tab = tabs[i]

            if tab then
                local spec = CharacterAdvancementUtil.GetSpecDBCByFile(tab)
                local spentOnTab = C_CharacterAdvancement.GetTabTEInvestment(class, spec, 0) or 0

                if spentOnTab > 0 then

                    if self.topTab then
                        if self.topTab.spentOnTab < spentOnTab then
                            self.topTab = {tab = tab, spentOnTab = spentOnTab}
                        end
                    else
                        self.topTab = {tab = tab, spentOnTab = spentOnTab}
                    end
                
                    local icon = CATalentGateCounterMixin:DefineIcon("TAB", class, spec)
                    local prevButton = button

                    button = self.tabPointsPool:Acquire()
                    button.GateText = button.Count
                    button:Show()
                    button:SetIcon(icon)
                    button.Count:SetText(spentOnTab)
                    button.tooltipTitle, button.tooltipText = CATalentGateCounterMixin.DefineTooltip(button, "TAB", class, spec)
                    button:SetScript("OnEnter", CATalentGateCounterMixin.OnEnter)
                    button:SetScript("OnClick", function()
                        CharacterAdvancement:SelectClass(self.classFile, tab)
                    end)

                    totalButtons = totalButtons + 1

                    if prevButton then
                        button:SetPoint("LEFT", prevButton, "RIGHT", 5, 0)
                    else
                        firstButton = button
                    end
                end
            end
        end

        if firstButton then
            self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 8, 8)
            --firstButton:SetPoint("BOTTOM", -(19/2)*(totalButtons-1), 8)
            firstButton:SetPoint("LEFT", self.Icon, "RIGHT", 8, -8)
        else
            self.Text:SetPoint("LEFT", self.Icon, "RIGHT", 8, 0)
        end
    end
end

function CAClassButtonMixin:OnEnter()
    CATalentGateCounterMixin.OnEnter(self)
end

function CAClassButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function CAClassButtonMixin:OnClick()
    PlaySound(SOUNDKIT.CHARACTER_SHEET_TAB)
    CharacterAdvancement:SelectClass(self.classFile, self.topTab and self.topTab.tab or nil)
end 

function CAClassButtonMixin:OnSelected()
    self.Overlay:Show()
end

function CAClassButtonMixin:OnDeSelected()
    self.Overlay:Hide()
end

function CAClassButtonMixin:OnCountLeave()
    GameTooltip:Hide()
    self:UnlockHighlight()
end 
ScenarioObjectiveMixin = {}

function ScenarioObjectiveMixin:OnLoad()
    self.IconFlash:SetAtlas("bonusobjectives-bar-starburst", Const.TextureKit.IgnoreAtlasSize)
    self.Sheen:SetAtlas("bonusobjectives-bar-sheen", Const.TextureKit.IgnoreAtlasSize)
end

function ScenarioObjectiveMixin:SetObjective(label, progress, progressMax)
    self:SetLabel(label)
    self:SetMaximumProgress(progressMax)
    self:SetProgress(progress)
end

function ScenarioObjectiveMixin:SetLabel(label)
    self.Label = label
    self.Text:SetText(label)
end

function ScenarioObjectiveMixin:SetProgress(progress)
    progress = MClamp(progress, 0, self.progressMax or 0)

    if progress == self.progressMax and self.progress == progress then
        -- exit if we're already at max progress
        return false
    end

    self.progress = progress
    if self.progressMax then
        if self.progress < self.progressMax then
            self.CompletedTime = nil
            self.Icon:SetTexture("Interface\\Scenarios\\scenarioicon-combat")
            self.Text:SetFontObject("PTFontHighlight")
            self.Counter:SetFontObject("PTFontHighlight")
        else
            self.progress = self.progressMax
            self.Icon:SetTexture("Interface\\Scenarios\\scenarioicon-check")
            self.Text:SetFontObject("PTFontDisable")
            self.Counter:SetFontObject("PTFontDisable")
            self.IconFlash.Anim:Play()
            self.Sheen.Anim:Play()
        end

        self.Counter:SetFormattedText("%d/%d", self.progress, self.progressMax)
    else
        self.Icon:SetTexture("Interface\\Scenarios\\scenarioicon-combat")
        self.Counter:SetFormattedText("%d", self.progress)
        self.Text:SetFontObject("PTFontHighlight")
        self.Counter:SetFontObject("PTFontHighlight")
    end

    self:SetLabel(self.Label)
    return true
end

function ScenarioObjectiveMixin:SetMaximumProgress(progressMax)
    self.progressMax = progressMax
    if self.progress then
        self:SetProgress(self.progress)
    end
end

--
-- Status Bar Objective
--

ScenarioStatusBarObjectiveMixin = CreateFromMixins(ScenarioObjectiveMixin)

function ScenarioStatusBarObjectiveMixin:OnLoad()
    ScenarioObjectiveMixin.OnLoad(self)
    self.StatusBar:SetStatusBarFlipbookAtlas("quality-barfill-flipbook-t4-x2", 374, 54, 60, 30, true)
    self.Text:SetPoint("RIGHT")
    self.Counter:Hide()
end

function ScenarioStatusBarObjectiveMixin:SetProgress(progress)
    progress = MClamp(progress, 0, self.progressMax or 0)
    local needUpdate = self.progress ~= progress
    if not needUpdate then return false end

    ScenarioObjectiveMixin.SetProgress(self, progress)

    if self.progressMax and needUpdate then
        self.StatusBar:SetValue(self.progress)
        if self.progress > 0 then
            self.StatusBar:PlayFlipbook()
            self.StatusBar.Glow.Anim:Stop()
            self.StatusBar.Glow.Anim:Play()
        end
        self.StatusBar:SetFormattedText("%2.2f%%", (self.progress / self.progressMax) * 100)
    end
    
    return true
end

function ScenarioStatusBarObjectiveMixin:SetMaximumProgress(progressMax)
    ScenarioObjectiveMixin.SetMaximumProgress(self, progressMax)
    self.StatusBar:SetMinMaxValues(0, progressMax)
end

--
-- Expandable Objective
--
ScenarioExpandableObjectiveMixin = CreateFromMixins(ScenarioObjectiveMixin)

function ScenarioExpandableObjectiveMixin:OnLoad()
    ScenarioObjectiveMixin.OnLoad(self)
    self.subObjectives = {}
    self.buttons = {}
end

function ScenarioExpandableObjectiveMixin:SetSubObjective(label, progress, progressMax)
    for _, subObjective in ipairs(self.subObjectives) do
        if subObjective.label == label then
            subObjective.progress = progress
            subObjective.progressMax = progressMax

            self:UpdateSubObjectives()
            return
        end
    end

    tinsert(self.subObjectives, { label = label, progress = progress, progressMax = progressMax })
    self:UpdateSubObjectives()
end

function ScenarioExpandableObjectiveMixin:RemoveSubObjective(label)
    for i, subObjective in ipairs(self.subObjectives) do
        if subObjective.label == label then
            table.remove(self.subObjectives, i)
            self:UpdateSubObjectives()
            return
        end
    end
end

function ScenarioExpandableObjectiveMixin:ClearSubObjectives()
    wipe(self.subObjectives)
    self:UpdateSubObjectives()
end

function ScenarioExpandableObjectiveMixin:SetSubObjectiveTemplate(template)
    self.subObjectiveTemplate = template
end

function ScenarioExpandableObjectiveMixin:UpdateSubObjectives()
    local height = 16
    for i = 1, max(#self.subObjectives, #self.buttons) do
        local objective = self.subObjectives[i]
        local button = self.buttons[i]

        if objective then
            if not button then
                button = CreateFrame("Frame", "$parentSubObjective"..i, self, self.subObjectiveTemplate or "ScenarioTextObjectiveTemplate")
                tinsert(self.buttons, button)
                button:SetWidth(220)
            end
            button:ClearAndSetPoint("TOPRIGHT", 0, -i * 16)
            button:SetObjective(objective.label, objective.progress, objective.progressMax)
            if self.isExpanded then
                button:Show()
                height = height + button:GetHeight()
            else
                button:Hide()
            end
        elseif button then
            button:Hide()
        end
    end

    self:SetHeight(height)
end

function ScenarioExpandableObjectiveMixin:LockExpanded()
    self.CollapseExpandButton:Hide()
    if self.isExpanded then return end
    self:Expand()
end

function ScenarioExpandableObjectiveMixin:UnlockExpanded()
    self.CollapseExpandButton:Show()
end

function ScenarioExpandableObjectiveMixin:Expand()
    self.isExpanded = true
    local texture = self.CollapseExpandButton:GetNormalTexture()
    texture:SetTexCoord(0, 0.5, 0.5, 1)
    texture = self.CollapseExpandButton:GetPushedTexture()
    texture:SetTexCoord(0.5, 1, 0.5, 1)
    self:UpdateSubObjectives()
end

function ScenarioExpandableObjectiveMixin:Collapse()
    self.isExpanded = false
    local texture = self.CollapseExpandButton:GetNormalTexture()
    texture:SetTexCoord(0, 0.5, 0, 0.5)
    texture = self.CollapseExpandButton:GetPushedTexture()
    texture:SetTexCoord(0.5, 1, 0, 0.5)
    self:UpdateSubObjectives()
end

function ScenarioExpandableObjectiveMixin:ToggleExpand()
    if self.isExpanded then
        self:Collapse()
    else
        self:Expand()
    end
end
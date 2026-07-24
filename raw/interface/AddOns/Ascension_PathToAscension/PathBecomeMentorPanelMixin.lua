PathBecomeMentorPanelMixin = {}

function PathBecomeMentorPanelMixin:OnLoad()
    self.Icon:SetAtlas("newplayerhelp-guide", Const.TextureKit.IgnoreAtlasSize)
    self:RegisterEvent("TOGGLE_MENTOR_STATUS_RESULT")
    self:RegisterEvent("ADD_MENTOR_SPECIALIZATION_RESULT")
    self:RegisterEvent("REMOVE_MENTOR_SPECIALIZATION_RESULT")
    self.specButtons = {}
    self:SetupSpecializations()

    self.Overlay:SetCenterColor(0, 0, 0, 0.95)
    self.Overlay:SetBorderColor(0, 0, 0, 0.95)
    self.Overlay.SubText:SetWidth(self:GetWidth() - 40)
    self.Overlay:SetFrameLevel(self:GetFrameLevel() + 20)
end

function PathBecomeMentorPanelMixin:SetupSpecializations()
    local specializations = C_Tutorial.GetMentorSpecializations() 
    local numSpecializations = #specializations
    local half = math.ceil(numSpecializations / 2)
    
    local x = -120
    local y, name, atlas
    for i = 1, numSpecializations do
        local specID = specializations[i]
        x = i <= half and 32 or 206
        y = i <= half and 36 * (i - 1) or 36 * (i - 1 - half)
        local button = CreateFrame("CheckButton", "$parentSpecialization"..i, self, "PTAMentorSpecializationTemplate", specID)
        
        tinsert(self.specButtons, button)

        button:SetChecked(C_Tutorial.GetMentorSpecializationActive(specID))
        button:SetPoint("TOPLEFT", self.SpecLabel, "BOTTOMLEFT", x, -y)
        name, atlas =  C_Tutorial.GetMentorSpecializationInfo(specID)
        atlas = TutorialUtil.ConvertDynamicMentorIcon(atlas)
        if atlas then
            button:SetText(name .. " " .. CreateAtlasMarkup(atlas, 1, 0, 0))
        else
            button:SetText(name)
        end
    end
end

function PathBecomeMentorPanelMixin:RefreshSpecButtons()
    for i, button in ipairs(self.specButtons) do
        button:SetChecked(C_Tutorial.GetMentorSpecializationActive(i))
    end
end

function PathBecomeMentorPanelMixin:OnEvent(event, ...)
    if event == "TOGGLE_MENTOR_STATUS_RESULT" then
        self:UpdateButton()
        self.BecomeMentorButton:Enable()
    elseif event == "ADD_MENTOR_SPECIALIZATION_RESULT" or event == "REMOVE_MENTOR_SPECIALIZATION_RESULT" then
        self:RefreshSpecButtons()
    end
end

function PathBecomeMentorPanelMixin:OnShow()
    local canBecomeMentor, reason = TutorialUtil.CanChangeMentorStatus()
    self.Overlay:SetShown(not canBecomeMentor)
    if not canBecomeMentor then
        self.Overlay.SubText:SetText(reason)
        self.Overlay.Title:SetPoint("CENTER", 0, self.Overlay.SubText:GetStringHeight() / 2)
    end
    
    self:UpdateButton()
    --self.BecomeMentorButton:SetEnabled(canBecomeMentor)
end 

function PathBecomeMentorPanelMixin:UpdateButton()
    local isMentor = C_Tutorial.IsMentorStatusActive()
    self.BecomeMentorButton:SetText(isMentor and DISABLE_MENTOR or ENABLE_MENTOR)
end

function PathBecomeMentorPanelMixin:ClickBecomeMentor()
    C_Tutorial.ToggleMentorStatus(not C_Tutorial.IsMentorStatusActive())
    self.BecomeMentorButton:Disable()
end
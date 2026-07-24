CreateTicketPanelMixin = {}

local TICKET_STEP = {
    ChooseAffectedCharacter = 1,
    AssignPriority = 2,
    AssignCategory = 3,
    DescribeIssue = 4,
    Finalize = 5,
}

function CreateTicketPanelMixin:OnLoad()
    self.DescribeIssue.Title.Instructions:SetFontObject("GameFontDisable")
    self.DescribeIssue.Content.Text:SetMaxLetters(2048)
    self.DescribeIssue.Content.Text:SetFontObject("ChatFontNormal")
    self.DescribeIssue.Content.Text.Instructions:SetFontObject("GameFontDisable")
    self.DescribeIssue.Content.Text.Instructions:SetText(HELPFRAME_OPENTICKET_INSTRUCTION)
    self.DescribeIssue.Content.Text:SetScript("OnTextChanged", function(editBox)
        InputBoxInstructions_OnTextChanged(editBox)
        ScrollingEdit_OnTextChanged(editBox, editBox:GetParent())
        self:UpdateNextButton()
    end)

    self.DescribeIssue.Content.Text:SetScript("OnEnterPressed", function(editBox)
        if self.ButtonContainer.NextButton:IsEnabled() == 1 then
            editBox:ClearFocus()
            self:OnNext()
        end
    end)
    
    self.ChooseAffectedCharacter.CharacterList.Background:SetAtlas("auctionhouse-background-sell-right", Const.TextureKit.IgnoreAtlasSize)
    self.ChooseAffectedCharacter.CharacterList:SetTemplate("TicketCharacterChoiceTemplate")
    self.ChooseAffectedCharacter.CharacterList:SetSelectedHighlightAtlas("auctionhouse-ui-row-select")
    self.ChooseAffectedCharacter.CharacterList:SetSelectedHighlightBlendMode("ADD")
    self.ChooseAffectedCharacter.CharacterList:SetGetNumResultsFunction(function() return (C_AccountInfo.GetNumCharacters and C_AccountInfo.GetNumCharacters() or 1) + 2 end)
    self.ChooseAffectedCharacter.CharacterList:SetSelectionCallback(function(index)
        self.selectedCharacter = index
        self:UpdateNextButton()
    end)
end 

function CreateTicketPanelMixin:Clear()
    self.DescribeIssue.Title:SetText("")
    self.DescribeIssue.Content.Text:SetText("")
    self.ticketPriority = nil
    self.ticketCategory = nil
    self.selectedCharacter = nil
    self.ChooseAffectedCharacter.CharacterList:SetSelectedIndex(nil, ScrollListMixin.UpdateType.Always)
    self:UpdateNextButton()
end

function CreateTicketPanelMixin:OnShow()
    self:SetCurrentStep(TICKET_STEP.ChooseAffectedCharacter)
    -- select current character by default
    self.ChooseAffectedCharacter.CharacterList:SetSelectedIndex(3, ScrollListMixin.UpdateType.Always)
end

function CreateTicketPanelMixin:SetCurrentStep(currentStep)
    self.currentStep = currentStep
    self:Layout()
end

function CreateTicketPanelMixin:UpdateNextButton()
    local enabled = true
    if self.currentStep == TICKET_STEP.ChooseAffectedCharacter then
        enabled = self.selectedCharacter ~= nil

    elseif self.currentStep == TICKET_STEP.DescribeIssue then
        local contentLength = (self.DescribeIssue.Content.Text:GetText() or ""):len()
        local titleLength = (self.DescribeIssue.Title:GetText() or ""):len()
        enabled = contentLength >= 3 and titleLength >= 3
    end
    
    self.ButtonContainer.NextButton:SetEnabled(enabled)
end

function CreateTicketPanelMixin:GetSelectedCharacterName()
    if self.selectedCharacter == 1 then
        return TICKET_AFFECTED_CHARACTER_NONE_SHORT
    elseif self.selectedCharacter == 2 then
        return TICKET_AFFECTED_CHARACTER_ALL_SHORT
    elseif self.selectedCharacter then
        return C_AccountInfo.GetCharacterAtIndex(self.selectedCharacter - 2).CharacterName
    end
    
    return ""
end

function CreateTicketPanelMixin:GetSelectedCharacterNameInternal()
    if self.selectedCharacter == 1 then
        return "AFFECTED_CHARACTERS_NONE"
    elseif self.selectedCharacter == 2 then
        return "AFFECTED_CHARACTERS_ALL"
    elseif self.selectedCharacter then
        return C_AccountInfo.GetCharacterAtIndex(self.selectedCharacter - 2).CharacterName
    end

    return ""
end

function CreateTicketPanelMixin:Layout()
    local showSubmit = self.currentStep == TICKET_STEP.Finalize
    local showBack = self.currentStep > 1
    local showNext = self.currentStep < TICKET_STEP.Finalize
    
    self.ChooseAffectedCharacter:SetShown(self.currentStep == TICKET_STEP.ChooseAffectedCharacter)
    self.AssignPriority:SetShown(self.currentStep == TICKET_STEP.AssignPriority)
    self.AssignCategory:SetShown(self.currentStep == TICKET_STEP.AssignCategory)
    self.DescribeIssue:SetShown(self.currentStep == TICKET_STEP.DescribeIssue)
    self.Finalize:SetShown(self.currentStep == TICKET_STEP.Finalize)

    if self.currentStep == TICKET_STEP.AssignPriority then
        self.ticketPriority = nil
    elseif self.currentStep == TICKET_STEP.AssignCategory then
        self.ticketCategory = nil
    elseif self.currentStep == TICKET_STEP.Finalize then
        self.Finalize.Title:SetText(self.DescribeIssue.Title:GetText())
        self.Finalize.AffectedCharacter:SetText(self:GetSelectedCharacterName())
        self.Finalize.Content:SetText(self.DescribeIssue.Content.Text:GetText())
        self.Finalize.Content:ResetToTop()
        self.Finalize.Priority:SetText(_G["PLAYER_TICKET_PRIORITY_"..(self.ticketPriority or Enum.TicketPriority.Medium)])
    end

    self:UpdateButtons(showBack, showNext, showSubmit)
    self:UpdateNextButton()
end

function CreateTicketPanelMixin:UpdateButtons(showBack, showNext, showSubmit)
    self.ButtonContainer.BackButton:SetShown(showBack)
    self.ButtonContainer.NextButton:SetShown(showNext)
    self.ButtonContainer.SubmitButton:SetShown(showSubmit)
    if showSubmit then
        self:UpdateSubmitButton()
    else
        self.ButtonContainer.CannotCreateReason:Hide()
    end
    self.ButtonContainer:Layout()
end

function CreateTicketPanelMixin:OnNext()
    self:SetCurrentStep(self.currentStep + 1)
end

function CreateTicketPanelMixin:OnBack()
    self:SetCurrentStep(self.currentStep - 1)
end

function CreateTicketPanelMixin:SubmitTicket()
    local priority = self.ticketPriority or Enum.TicketPriority.Medium
    local category = self.ticketCategory or Enum.TicketCategory.Other
    local title = self.DescribeIssue.Title:GetText()
    local content = self.DescribeIssue.Content.Text:GetText()
    local characterName = self:GetSelectedCharacterNameInternal()

    if C_PlayerTicket.CreateTicket(priority, category, title, content, characterName) then
        self:GetParent():ShowLoading()
    else
        self:GetParent():ShowError(PLAYER_TICKET_ERROR_UNKNOWN)
    end
end

function CreateTicketPanelMixin:UpdateSubmitButton()
    local priority = self.ticketPriority or Enum.TicketPriority.Medium
    local category = self.ticketCategory or Enum.TicketCategory.Other
    local title = self.DescribeIssue.Title:GetText()
    local content = self.DescribeIssue.Content.Text:GetText()
    local characterName = self:GetSelectedCharacterNameInternal()

    local canCreate, reason = C_PlayerTicket.CanCreateTicket(priority, category, title, content, characterName)

    self.ButtonContainer.SubmitButton:SetEnabled(canCreate)
    if reason then
        self.ButtonContainer.CannotCreateReason:SetText(_G[reason] or reason)
        self.ButtonContainer.CannotCreateReason:Show()
    else
        self.ButtonContainer.CannotCreateReason:Hide()
    end
end

function CreateTicketPanelMixin:SelectTicketPriority(priority)
    self.ticketPriority = priority
    self:OnNext()
end

function CreateTicketPanelMixin:SelectTicketCategory(category)
    self.ticketCategory = category
    self:OnNext()
end 
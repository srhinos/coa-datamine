PollQuestionMixin = {}
PollQuestionMixin.OnEvent = OnEventToMethod

PollQuestionMixin.VisualState = {
    CanSubmit = 1,
    Answered = 2,
    Unanswered = 3,
}

PollQuestionMixin.Mode = {
    OpenEnded = "openended",
    Grid = "grid",
    DropDown = "dropdown",
    RatingScale = "ratingscale",
}

PollQuestionMixin.QuestionType = {
    None = "NONE",
    ChooseOne = "PLAYER_POLL_CHOOSE_ONE",
    MultipleChoice = "PLAYER_POLL_MULTIPLE_CHOICE",
    RatingScale = "PLAYER_POLL_RATING_SCALE",
    OptionalChoice = "PLAYER_POLL_OPTIONAL_CHOICE",
}

local DROPDOWN_CHOICE_THRESHOLD = 6

function PollQuestionMixin:OnLoad()
    self.ChoicePool = CreateFramePool("Button", self.Answers, "PollQuestionChoiceTemplate")
    self.RatingScalePool = CreateFramePool("Button", self.RatingScale, "PollRatingScaleChoiceTemplate")
    self.RatingScaleLinePool = CreateTexturePool(self.RatingScale, "BACKGROUND")
    self.selectedIndices = {}
    self.isEditingOpenEndedAnswer = false

    local frameLevel = self:GetFrameLevel()
    self.Loading:SetFrameLevel(frameLevel + 20)
    self.LargeAdditionalInfo:SetFrameLevel(frameLevel + 5)
    self.Answers.alwaysUpdateLayout = true

    self.LargeAdditionalInfo.ScrollFrame.Text:HookScript("OnTextChanged", function(editBox)
        if editBox:HasFocus() then
            self.AdditionalInfo:SetText(editBox:GetText())
        end
    end)

    self.AdditionalInfo:HookScript("OnTextChanged", function(editBox)
        if editBox:HasFocus() then
            self.LargeAdditionalInfo.ScrollFrame.Text:SetText(editBox:GetText())
        end
    end)

    self.OpenEndedComment.ScrollFrame.Text:HookScript("OnTextChanged", function()
        if self.isOpenEnded then
            self:Update()
        end
    end)

    self.AdditionalInfo:SetMaxBytes(2048)
    self.LargeAdditionalInfo.ScrollFrame.Text:SetMaxBytes(2048)
    self.OpenEndedComment.ScrollFrame.Text:SetMaxBytes(2048)
    self.OpenEndedComment:Hide()

    self.ChoiceDropDown:SetDropDownWidth(180)
    self.ChoiceDropDown:SetJustify("LEFT")
    self.ChoiceDropDown:SetMenuHeight(200)
    self.ChoiceDropDown:SetSelectionCallback(function(value, index, option, multiList)
        if self.allowMultiple then
            self.selectedIndices = {}
            for _, i in ipairs(multiList or {}) do
                self.selectedIndices[i] = true
            end
            self:SyncCheckboxes()
            self:Update()
        else
            self:UpdateSelectedChoice(index)
        end
    end)
    self.ChoiceDropDown:Hide()

    self.Background:SetAtlas("poll-background")
    self:RegisterEvent("PLAYER_POLL_ANSWER_RESULT")
end

function PollQuestionMixin:SetQuestionIndex(index)
    self.LargeAdditionalInfo:Hide()
    self.Loading:Hide()
    self.questionIndex = index
    self.ChoicePool:ReleaseAll()
    self.RatingScalePool:ReleaseAll()
    self.selectedIndex = nil
    self.selectedIndices = {}
    self.isEditingOpenEndedAnswer = false

    local title, questionText, questionContext, feedbackText, feedbackPrompt = C_PlayerPoll.GetQuestionInfo(index)
    BasicFrame_SetTitle(self:GetParent(), title)

    if string.isNilOrEmpty(questionContext) then
        self.QuestionContext:Hide()
    else
        self.QuestionContext:Show()
        self.QuestionContext:SetText(questionContext)
    end

    self.Question:SetText(questionText)

    local numChoices = C_PlayerPoll.GetNumQuestionChoices(index)
    local questionType = C_PlayerPoll.GetQuestionType and C_PlayerPoll.GetQuestionType(index)
    if questionType == nil or questionType == "" then
        questionType = PollQuestionMixin.QuestionType.ChooseOne
    end
    self.questionType = questionType
    self.allowMultiple = false
    self.questionMode = self:ResolveQuestionMode(questionType, numChoices)
    self.isOpenEnded = self.questionMode == PollQuestionMixin.Mode.OpenEnded

    self.AdditionalInfo:SetText(feedbackText or "")
    self.AdditionalInfo.Instructions:SetText(feedbackPrompt)
    self.AdditionalInfo.Instructions:SetWordWrap(false)
    self.LargeAdditionalInfo.ScrollFrame.Text:SetText(feedbackText or "")
    self.LargeAdditionalInfo.ScrollFrame.Text.Instructions:SetText(feedbackPrompt)
    self.OpenEndedComment.ScrollFrame.Text:SetText(feedbackText or "")
    self.OpenEndedComment.ScrollFrame.Text.Instructions:SetText(feedbackPrompt)

    self:ApplyOpenEndedLayout()

    if self.questionMode == PollQuestionMixin.Mode.RatingScale then
        self:PopulateRatingScaleChoices(index, numChoices)
    else
        self:PopulateGridChoices(index, numChoices)
    end

    self:SyncCheckboxes()
    self:Update()
end

function PollQuestionMixin:ResolveQuestionMode(questionType, numChoices)
    if numChoices == 0 then
        return PollQuestionMixin.Mode.OpenEnded
    end

    if questionType == PollQuestionMixin.QuestionType.RatingScale then
        return PollQuestionMixin.Mode.RatingScale
    end

    if questionType == PollQuestionMixin.QuestionType.MultipleChoice then
        return PollQuestionMixin.Mode.DropDown
    end

    if questionType == PollQuestionMixin.QuestionType.ChooseOne
        or questionType == PollQuestionMixin.QuestionType.OptionalChoice
        or questionType == PollQuestionMixin.QuestionType.None then
        if numChoices > DROPDOWN_CHOICE_THRESHOLD then
            return PollQuestionMixin.Mode.DropDown
        end
        return PollQuestionMixin.Mode.Grid
    end

    return PollQuestionMixin.Mode.Grid
end

function PollQuestionMixin:PopulateGridChoices(index, numChoices)
    local largestTextWidth = 0
    local layoutIndex = CreateCounter(3)
    for i = 1, numChoices do
        local choice = self.ChoicePool:Acquire()
        local choiceText, isSelected = C_PlayerPoll.GetQuestionChoiceInfo(index, i)
        choice:SetMultiSelectStyle(self.allowMultiple)
        choice:SetQuestionIndex(index)
        choice:SetIndex(i)
        local textWidth = choice:SetText(choiceText)
        if textWidth and textWidth > largestTextWidth then
            largestTextWidth = textWidth
        end
        if isSelected then
            if self.allowMultiple then
                self.selectedIndices[i] = true
            elseif not self.selectedIndex then
                self.selectedIndex = i
            end
        end
        choice.layoutIndex = layoutIndex()
        choice:Show()
    end

    for choice in self.ChoicePool:EnumerateActive() do
        choice:ApplyTextWidth(largestTextWidth)
    end

    self.Answers:MarkDirty()
    return largestTextWidth
end

function PollQuestionMixin:PopulateRatingScaleChoices(index, numChoices)
    local largestTextWidth = 0
    local layoutIndex = CreateCounter(3)
    local choices = {}
    for i = 1, numChoices do
        local choice = self.RatingScalePool:Acquire()
        local choiceText, isSelected = C_PlayerPoll.GetQuestionChoiceInfo(index, i)
        choice:SetQuestionIndex(index)
        choice:SetIndex(i)
        local textWidth = choice:SetText(choiceText)
        if textWidth and textWidth > largestTextWidth then
            largestTextWidth = textWidth
        end
        if isSelected and not self.selectedIndex then
            self.selectedIndex = i
        end
        choice.layoutIndex = layoutIndex()
        choice:Show()
        choices[#choices + 1] = choice
    end

    for _, choice in ipairs(choices) do
        choice:ApplyTextWidth(largestTextWidth)
    end

    self.RatingScale:MarkDirty()
    self.RatingScale:Layout()

    self:RebuildRatingScaleConnectors(choices)
end

function PollQuestionMixin:RebuildRatingScaleConnectors(choices)
    self.RatingScaleLinePool:ReleaseAll()
    for i = 1, #choices - 1 do
        local line = self.RatingScaleLinePool:Acquire()
        line:SetTexture("Interface\\Buttons\\WHITE8x8")
        line:SetVertexColor(0.75, 0.65, 0.45, 0.75)
        line:SetHeight(2)
        line:ClearAllPoints()
        line:SetPoint("LEFT", choices[i].CheckButton, "RIGHT", -4, 0)
        line:SetPoint("RIGHT", choices[i + 1].CheckButton, "LEFT", 4, 0)
        line:Show()
    end
end

function PollQuestionMixin:GetQuestionIndex()
    return self.questionIndex
end

function PollQuestionMixin:ApplyOpenEndedLayout()
    local mode = self.questionMode
    local openEnded = mode == PollQuestionMixin.Mode.OpenEnded
    local dropdown = mode == PollQuestionMixin.Mode.DropDown
    local grid = mode == PollQuestionMixin.Mode.Grid
    local ratingScale = mode == PollQuestionMixin.Mode.RatingScale

    local parent = self:GetParent()
    local overviewShown = parent and parent.QuestionList and parent.QuestionList:IsShown()

    self.AdditionalInfo:SetShown(not openEnded)
    self.ToggleLargeCommentButton:SetShown(not openEnded)
    self.OpenEndedComment:SetShown(openEnded and not overviewShown)
    self.Answers:SetShown(grid)
    self.RatingScale:SetShown(ratingScale and not overviewShown)
    self.ChoiceDropDown:SetShown(dropdown and not overviewShown)

    self.ChoiceDropDown:SetMultiSelect(dropdown and self.allowMultiple)

    self.SubmitButton:ClearAllPoints()
    if openEnded then
        self.SubmitButton:SetPoint("TOP", self, "BOTTOM", 0, -8)
    else
        self.SubmitButton:SetPoint("TOPLEFT", self, "BOTTOM", 4, -8)
    end

    if dropdown then
        self:RefreshChoiceDropDown()
    end
end

function PollQuestionMixin:RefreshChoiceDropDown()
    local questionIndex = self.questionIndex
    local options = {}
    for i = 1, C_PlayerPoll.GetNumQuestionChoices(questionIndex) do
        local choiceText = C_PlayerPoll.GetQuestionChoiceInfo(questionIndex, i)
        options[i] = { text = choiceText, value = i }
    end
    self.ChoiceDropDown:SetOptions(options)
    if self.allowMultiple then
        local list = {}
        for idx in pairs(self.selectedIndices) do
            list[#list + 1] = idx
        end
        self.ChoiceDropDown:SetSelectedIndices(list, true)
    else
        self.ChoiceDropDown:SetSelectedIndex(self.selectedIndex, true)
    end
end

function PollQuestionMixin:OnChoiceClicked(index)
    if self.allowMultiple then
        self.selectedIndices = self.selectedIndices or {}
        if self.selectedIndices[index] then
            self.selectedIndices[index] = nil
        else
            self.selectedIndices[index] = true
        end
        self:SyncCheckboxes()
        self:Update()
    else
        local newSelection = (self.selectedIndex == index) and nil or index
        self:UpdateSelectedChoice(newSelection)
    end
end

function PollQuestionMixin:UpdateSelectedChoice(index)
    self.selectedIndex = index
    self:SyncCheckboxes()
    self:Update()
end

function PollQuestionMixin:SyncCheckboxes()
    for choice in self.ChoicePool:EnumerateActive() do
        local idx = choice:GetIndex()
        if self.allowMultiple then
            choice:SetChecked(self.selectedIndices[idx] and true or false)
        else
            choice:SetChecked(idx == self.selectedIndex)
        end
    end

    for choice in self.RatingScalePool:EnumerateActive() do
        choice:SetChecked(choice:GetIndex() == self.selectedIndex)
    end

    if self.questionMode == PollQuestionMixin.Mode.DropDown then
        if self.allowMultiple then
            local list = {}
            for idx in pairs(self.selectedIndices or {}) do
                list[#list + 1] = idx
            end
            self.ChoiceDropDown:SetSelectedIndices(list, true)
        else
            self.ChoiceDropDown:SetSelectedIndex(self.selectedIndex, true)
        end
    end
end

function PollQuestionMixin:HasAnyAnswer()
    if self.allowMultiple then
        return self.selectedIndices and next(self.selectedIndices) ~= nil
    end
    return self.selectedIndex ~= nil
end

function PollQuestionMixin:GetAnswerPayload()
    if self.allowMultiple then
        local list = {}
        for idx in pairs(self.selectedIndices or {}) do
            list[#list + 1] = idx
        end
        table.sort(list)
        return list
    end
    return self.selectedIndex
end

function PollQuestionMixin:GetFeedbackText()
    if self.isOpenEnded then
        return self.OpenEndedComment.ScrollFrame.Text:GetText():trim()
    end
    return self.AdditionalInfo:GetText():trim()
end

function PollQuestionMixin:Update()
    local feedbackText = self:GetFeedbackText()
    local answerPayload = self:GetAnswerPayload()
    local hasAnswer = self:HasAnyAnswer()
    local hasFeedbackText = not string.isNilOrEmpty(feedbackText)

    local canSubmit = C_PlayerPoll.CanSubmitAnswer(self.questionIndex, answerPayload, feedbackText)
    local canChangeAnswer = C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex)

    self.SubmitButton:SetEnabled(canSubmit)
    self.ChangeAnswerButton:SetEnabled(canChangeAnswer)

    if self.isOpenEnded then
        if self.isEditingOpenEndedAnswer then
            if canSubmit then
                self:SetVisualState(PollQuestionMixin.VisualState.CanSubmit)
            else
                self:SetVisualState(PollQuestionMixin.VisualState.Unanswered)
            end
        elseif canSubmit then
            self:SetVisualState(PollQuestionMixin.VisualState.CanSubmit)
        elseif hasFeedbackText then
            self:SetVisualState(PollQuestionMixin.VisualState.Answered)
        elseif canChangeAnswer then
            self:SetVisualState(PollQuestionMixin.VisualState.Unanswered)
        else
            self:SetVisualState(PollQuestionMixin.VisualState.Answered)
        end
    elseif canSubmit and hasAnswer then
        self:SetVisualState(PollQuestionMixin.VisualState.CanSubmit)
    elseif canChangeAnswer and not hasAnswer then
        self:SetVisualState(PollQuestionMixin.VisualState.Unanswered)
    else
        self:SetVisualState(PollQuestionMixin.VisualState.Answered)
    end
end

function PollQuestionMixin:SetVisualState(state)
    local showActiveBorder = false
    local canSubmitAnswer = false
    local canChangeAnswer = false
    if state == PollQuestionMixin.VisualState.CanSubmit then
        showActiveBorder = true
        canSubmitAnswer  = true
    elseif state == PollQuestionMixin.VisualState.Answered then
        if C_PlayerPoll.CanChangeQuestionChoice(self.questionIndex) then
            canChangeAnswer = true
        end
    elseif state == PollQuestionMixin.VisualState.Unanswered then
        canSubmitAnswer = true
    end

    self.ThankYou:ClearAllPoints()
    self.ChangeAnswerButton:ClearAllPoints()
    if self.isOpenEnded and self.questionType == PollQuestionMixin.QuestionType.OptionalChoice then
        self.ChangeAnswerButton:SetPoint("BOTTOM", self.OpenEndedComment, "TOP", 0, 8)
        self.ThankYou:SetPoint("BOTTOM", self.ChangeAnswerButton, "TOP", 0, 14)
    else
        self.ThankYou:SetPoint("BOTTOM", 0, 48)
        self.ChangeAnswerButton:SetPoint("BOTTOM", 0, 8)
    end

    self.ThankYou:SetShown(not canSubmitAnswer)
    self.ChangeAnswerButton:SetShown(not canSubmitAnswer and canChangeAnswer)
    self.AdditionalInfo:SetEnabled(canSubmitAnswer)
    self.ToggleLargeCommentButton:SetEnabled(canSubmitAnswer)
    self.OpenEndedComment.ScrollFrame.Text:SetEnabled(canSubmitAnswer)
    self.ChoiceDropDown:SetEnabled(canSubmitAnswer)
    for choice in self.ChoicePool:EnumerateActive() do
        choice:SetEnabled(canSubmitAnswer)
        choice:SetAlpha(canSubmitAnswer and 1 or 0.7)
    end
    for choice in self.RatingScalePool:EnumerateActive() do
        choice:SetEnabled(canSubmitAnswer)
        choice:SetAlpha(canSubmitAnswer and 1 or 0.7)
    end

    if canSubmitAnswer then
        self.Background:SetVertexColor(0.9, 0.9, 0.9)
        self.Question:SetAlpha(1)
        self.QuestionContext:SetAlpha(1)
        self.AdditionalInfo:SetAlpha(1)
        self.ToggleLargeCommentButton:SetAlpha(1)
        self.OpenEndedComment:SetAlpha(1)
    else
        self.Background:SetVertexColor(0.4, 0.4, 0.4)
        self.Question:SetAlpha(0.7)
        self.QuestionContext:SetAlpha(0.7)
        self.AdditionalInfo:SetAlpha(0.7)
        self.ToggleLargeCommentButton:SetAlpha(0.7)
        self.OpenEndedComment:SetAlpha(0.7)
    end
end

function PollQuestionMixin:RemoveAnswer()
    PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
    if self.isOpenEnded and self.questionType == PollQuestionMixin.QuestionType.OptionalChoice then
        self.isEditingOpenEndedAnswer = true
        self:Update()
        self.OpenEndedComment.ScrollFrame.Text:SetFocus()
    elseif self.allowMultiple then
        self.selectedIndices = {}
        self:SyncCheckboxes()
        self:Update()
    else
        self:UpdateSelectedChoice(nil)
    end
end

function PollQuestionMixin:Submit()
    local additionalInfo = self:GetFeedbackText()
    local answerPayload = self:GetAnswerPayload()
    if C_PlayerPoll.CanSubmitAnswer(self.questionIndex, answerPayload, additionalInfo) then
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
        C_PlayerPoll.SubmitAnswer(self.questionIndex, answerPayload, additionalInfo)
        self.Loading:Show()
        return true
    end
end

function PollQuestionMixin:ToggleLargeComment()
    self.LargeAdditionalInfo:SetShown(not self.LargeAdditionalInfo:IsShown())

    if self.LargeAdditionalInfo:IsShown() then
        self.LargeAdditionalInfo.ScrollFrame.Text:SetText(self.AdditionalInfo:GetText())
        self.LargeAdditionalInfo.ScrollFrame.Text:SetFocus()
    end
end

function PollQuestionMixin:PLAYER_POLL_ANSWER_RESULT(result)
    if result and result:endswith("_OK") then
        PlaySound(SOUNDKIT.UI_QUEST_OBJECTIVECOMPLETE_01)
        self.isEditingOpenEndedAnswer = false
    end
    self.Loading:Hide()
    self:Update()
    self:GetParent():GoToNextAnswerableQuestion()
end

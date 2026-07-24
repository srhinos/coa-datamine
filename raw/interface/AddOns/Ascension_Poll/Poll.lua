PollFrameMixin = {}

function PollFrameMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    tinsert(UISpecialFrames, self:GetName())

    self.QuestionList:SetGetNumResultsFunction(C_PlayerPoll.GetNumQuestions)
    self.QuestionList:SetTemplate("PollQuestionListItemTemplate")
    self.QuestionList:SetSelectedHighlightTexture(nil)
    self.QuestionList:SetFrameLevel(self:GetFrameLevel() + 5)
    self.QuestionList.Shadow:SetPoint("TOPLEFT", self.Question, "TOPLEFT", 5, -3)
    self.QuestionList.Shadow:SetPoint("BOTTOMRIGHT", self.Question, "BOTTOMRIGHT", -5, 2)

    self.QuestionList:HookScript("OnShow", function()
        self.Question.OpenEndedComment:Hide()
        self.Question.ChoiceDropDown:Hide()
        self.Question.RatingScale:Hide()
    end)
    self.QuestionList:HookScript("OnHide", function()
        self.Question:ApplyOpenEndedLayout()
    end)
end

function PollFrameMixin:OnDragStart()
    self:StartMoving()
end
function PollFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
end

function PollFrameMixin:OnShow()
    PlaySound(SOUNDKIT.QUESTLOGOPENA)
    self:GoToFirstAnswerableQuestion()
    self:UpdateNavigationButtons()
end

function PollFrameMixin:OnHide()
    PlaySound(SOUNDKIT.QUESTLOGCLOSEA)
end

function PollFrameMixin:GoToFirstAnswerableQuestion()
    for i = 1, C_PlayerPoll.GetNumQuestions() do
        if C_PlayerPoll.CanChangeQuestionChoice(i) then
            local questionType = C_PlayerPoll.GetQuestionType and C_PlayerPoll.GetQuestionType(i)
            local _, _, _, feedbackText = C_PlayerPoll.GetQuestionInfo(i)
            local hasSelectedAnswer =
                questionType == PollQuestionMixin.QuestionType.OptionalChoice and not string.isNilOrEmpty(feedbackText)
            for j = 1, C_PlayerPoll.GetNumQuestionChoices(i) do
                local _, isSelected = C_PlayerPoll.GetQuestionChoiceInfo(i, j)
                if isSelected then
                    hasSelectedAnswer = true
                    break
                end
            end
            if not hasSelectedAnswer then
                self:SetSelectedQuestion(i)
                return
            end
        end
    end

    -- didnt find a question to go to
    self:SetSelectedQuestion(1)
end

function PollFrameMixin:GoToNextAnswerableQuestion()
    for i = self.Question:GetQuestionIndex(), C_PlayerPoll.GetNumQuestions() do
        if C_PlayerPoll.CanChangeQuestionChoice(i) then
            local questionType = C_PlayerPoll.GetQuestionType and C_PlayerPoll.GetQuestionType(i)
            local _, _, _, feedbackText = C_PlayerPoll.GetQuestionInfo(i)
            local hasSelectedAnswer =
                questionType == PollQuestionMixin.QuestionType.OptionalChoice and not string.isNilOrEmpty(feedbackText)
            for j = 1, C_PlayerPoll.GetNumQuestionChoices(i) do
                local _, isSelected = C_PlayerPoll.GetQuestionChoiceInfo(i, j)
                if isSelected then
                    hasSelectedAnswer = true
                    break
                end
            end
            if not hasSelectedAnswer then
                self:SetSelectedQuestion(i)
                return
            end
        end
    end
end

function PollFrameMixin:UpdateNavigationButtons()
    local currentQuestionIndex = self.Question:GetQuestionIndex() or 1
    local numQuestions = C_PlayerPoll.GetNumQuestions()
    if numQuestions > 1 then
        self.NextQuestionButton:Show()
        self.PreviousQuestionButton:Show()
        self.Page:Show()
        self.NextQuestionButton:SetEnabled(currentQuestionIndex < numQuestions)
        self.PreviousQuestionButton:SetEnabled(currentQuestionIndex > 1)

        self.Page:SetFormattedText("%s/%s", currentQuestionIndex, numQuestions)
    else
        self.NextQuestionButton:Hide()
        self.PreviousQuestionButton:Hide()
        self.Page:Hide()
    end
end

function PollFrameMixin:UpdateSize()
    local questionHeight = self.Question:GetHeight()
    self:SetHeight(questionHeight + 120)
end

function PollFrameMixin:SetSelectedQuestion(index)
    self.Question:SetQuestionIndex(index)
    self:UpdateNavigationButtons()
end

function PollFrameMixin:NextQuestion()
    if self.Question:Submit() then
        return
    end

    local numQuestions = C_PlayerPoll.GetNumQuestions()
    local currentQuestionIndex = self.Question:GetQuestionIndex() or 1
    if currentQuestionIndex < numQuestions then
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
        self:SetSelectedQuestion(currentQuestionIndex + 1)
    end
end

function PollFrameMixin:PreviousQuestion()
    local currentQuestionIndex = self.Question:GetQuestionIndex() or 1
    if currentQuestionIndex > 1 then
        PlaySound(SOUNDKIT.UCHATSCROLLBUTTON)
        self:SetSelectedQuestion(currentQuestionIndex - 1)
    end
end

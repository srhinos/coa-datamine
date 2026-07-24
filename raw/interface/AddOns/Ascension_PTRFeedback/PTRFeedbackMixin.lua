PTRFeedbackMixin = CreateFromMixins("BackdropTemplateMixin")

function PTRFeedbackMixin:OnLoad()
    self:RegisterForDrag("LeftButton")
    self:SetShown(C_Realm.IsPTR())
end

function PTRFeedbackMixin:OnDragStart()
    self:StartMoving()
end 

function PTRFeedbackMixin:OnDragStop()
    self:StopMovingOrSizing()
end 

function PTRFeedbackMixin:ReportBug()
    AscensionHelpUI_LoadUI()
    BugReportFrame:SetShown(not BugReportFrame:IsShown())
end

function PTRFeedbackMixin:SubmitFeedback()
    AscensionHelpUI_LoadUI()
    FeedbackFrame:SetShown(not FeedbackFrame:IsShown())
end 
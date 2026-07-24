ToastContainerMixin = {}

function ToastContainerMixin:OnLoad()
    self.toastPool = CreateFramePoolCollection()
    EventRegistry:RegisterCallback("ToastNotification.Complete", self.OnNotificationComplete, self)
    self.activeToasts = {}
    self.openPositions = { 1, 2, 3, 4, 5, 6 }
end

function ToastContainerMixin:CanAddToast()
    return self.toastPool:GetNumActive() < C_CVar.GetNumber("lootToastMaximum")
end

function ToastContainerMixin:GetActiveToastForNotification(notification)
    for _, toast in ipairs(self.activeToasts) do
        if toast:CanCombineNotification(notification) then
            return toast
        end
    end
end

function ToastContainerMixin:GetToastForNotification(template, notification)
    local toast = self:GetActiveToastForNotification(notification)

    if not toast then
        local pool = self.toastPool:GetOrCreatePool("BUTTON", self, template)
        toast = pool:Acquire()
        tinsert(self.activeToasts, toast)
    end
    
    return toast
end

function ToastContainerMixin:AddToast(style, notification)
    local toast = self:GetToastForNotification(style.template, notification)
    toast:SetStyle(style)
    toast:SetNotification(notification)
    if toast:IsShown() then
        toast:PauseFadeOut()
        toast:ResumeFadeOut()
    else
        toast:Show()
    end
    self:UpdatePositions()
end

function ToastContainerMixin:UpdatePositions()
    for i, toast in ipairs(self.activeToasts) do
        if not toast.position then
            toast.position = tremove(self.openPositions, 1)
            if not toast.position then
                toast.position = 7 -- ????
            end
            toast:SetPoint("BOTTOM", self, "BOTTOM", 0, ((toast.position - 1) * 106))
        end
    end
end

function ToastContainerMixin:OnNotificationComplete(toast)
    tinsert(self.openPositions, toast.position)
    table.sort(self.openPositions)
    toast.position = nil
    tremoveItem(self.activeToasts, toast)
    self.toastPool:Release(toast)
    self:UpdatePositions()
end
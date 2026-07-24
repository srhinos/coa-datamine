RandomModeLevelingRewardMixin = {}

function RandomModeLevelingRewardMixin:OnLoad()
    self.Separator:SetAtlas("ui-frame-bar-bordertick", Const.TextureKit.IgnoreAtlasSize)
    self.LevelPlate:SetAtlas("collections-levelplate-black", Const.TextureKit.UseAtlasSize)
end

function RandomModeLevelingRewardMixin:SetLevel(level)
    self.Separator:Show()
    self.LevelPlate:Show()
    self.Items:Show()
    self.Icon:Hide()
    self.Level:SetText(level)
    
    self.CanClaim = UnitLevel("player") >= level
    if self.CanClaim then
        self.Level:SetTextColor(1, 1, 1)
    else
        self.Level:SetTextColor(1, 0, 0)
    end
end

function RandomModeLevelingRewardMixin:SetRewards(rewards, claimed)
    local i = 1
    for item, count in pairs(rewards) do
        local button = self.Items["Reward"..i]
        button:SetItem(item, count)
        button:SetClaimed(claimed)
        button:Show()
        
        i = i + 1
        if i > 2 then
            break
        end
    end
    
    for j = i, 2 do
        self.Items["Reward"..j]:Hide()
    end

    self.Items:MarkDirty()
end

function RandomModeLevelingRewardMixin:SetEndCap()
    self.Separator:Hide()
    self.LevelPlate:Hide()
    self.Items:Hide()
    self.Icon:Show()
    self.Level:SetText("")
end 

function RandomModeLevelingRewardMixin:OnEnter()
    if self.Icon:IsShown() then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(LEVELING_SPECIAL_MSG)
        GameTooltip:Show()
    end
end 

function RandomModeLevelingRewardMixin:OnLeave()
    GameTooltip:Hide()
end 
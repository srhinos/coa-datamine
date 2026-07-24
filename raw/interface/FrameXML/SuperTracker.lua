SuperTrackerMixin = {}

function SuperTrackerMixin:OnLoad()
    self.mouseToNavVec = Vector2D(0, 0)
    self.indicatorVec = Vector2D(0, 0)
    self.circularVec = Vector2D(0, 0)

    self.Icon:SetAtlas("Navigation-Tracked-Icon", Const.TextureKit.UseAtlasSize)

    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

function SuperTrackerMixin:OnEvent(event, ...)
    if event == "SUPER_TRACKING_CHANGED" then
        if C_SuperTrack.IsSuperTrackingAnything() then
            self:Show()
        else
            self:Hide()
        end
    end
end

function SuperTrackerMixin:OnShow()
    self:UpdateIcon()
    Minimap_UpdateSuperTrackPOI(Minimap)
end

function SuperTrackerMixin:OnHide()
    Minimap_UpdateSuperTrackPOI(Minimap)
end

function SuperTrackerMixin:OnUpdate(dt)
    if self:CheckIsTracking() then
        local x, y, distance = C_SuperTrack.GetSuperTrackedPosition()
        self:UpdatePosition(x, y)
        self:UpdateDistanceText(distance)
        self:UpdateAlpha(dt, distance)
        self:UpdateIcon()
        Minimap_UpdateSuperTrackPOI(Minimap)
    end
end

function SuperTrackerMixin:CheckIsTracking()
    if C_SuperTrack.IsSuperTrackingAnything() then
        return true
    else
        self:Hide()
        return false
    end
end

do
    local navStateToTargetAlpha =
    {
        [Enum.NavigationState.Invalid] = 0.0,
        [Enum.NavigationState.Occluded] = 0.6,
        [Enum.NavigationState.InRange] = 1.0,
        [Enum.NavigationState.Disabled] = 0.0,
        [Enum.NavigationState.InRadius] = 0.1,
    };

    function SuperTrackerMixin:GetTargetAlphaBaseValue(distance)
        local state = C_SuperTrack.GetTargetState()
        if distance then
            if distance > 1500 then
                -- dont show too far
                state = Enum.NavigationState.Invalid
            elseif state == Enum.NavigationState.InRange then
                if distance > 727 then
                    -- 727 = mediumish farclip value
                    state = Enum.NavigationState.Occluded
                end
            end
        end
        return navStateToTargetAlpha[state]
    end

    function SuperTrackerMixin:GetTargetAlpha(dt, distance)
        if not SuperTrackerUtil.HasValidScreenPosition() then
            return 0
        end

        local additionalFade = 1.0

        if self:IsMouseOver() then
            additionalFade = 0.5
        end

        return MDeltaLerp(self:GetAlpha(), self:GetTargetAlphaBaseValue(distance) * additionalFade, 0.1, dt)
    end

    function SuperTrackerMixin:SetTargetAlphaForState(state, alpha)
        navStateToTargetAlpha[state] = alpha
    end

    function SuperTrackerMixin:UpdateAlpha(dt, distance)
        self:SetAlpha(self:GetTargetAlpha(dt, distance))
    end
end

function SuperTrackerMixin:UpdatePosition(x, y)
    SuperTrackerUtil.PositionSuperTracker(self, x, y)
end

local function GetDistanceString(distance)
    if not distance then
        return "0"
    end
    distance = math.ceil(distance)
    if distance < 1000 then
        return tostring(distance)
    else
        return AbbreviateNumbers(distance)
    end
end

function SuperTrackerMixin:UpdateDistanceText(distance)
    if self.distance ~= distance then
        self.DistanceText:SetText(IN_GAME_NAVIGATION_RANGE:format(GetDistanceString(distance)))
        self.distance = distance
    end
end

function SuperTrackerMixin:UpdateIconSize()
    self.navFrameRadius = math.max(self.Icon:GetSize())
    self.navFrameRadiusSq = self.navFrameRadius * self.navFrameRadius
end

local iconLookup = {
    [Enum.SuperTrackingType.Quest] = "Navigation-Tracked-Icon",
    [Enum.SuperTrackingType.Position] = "Waypoint-MapPin-Tracked",
    [Enum.SuperTrackingType.Corpse] = "Navigation-Tombstone-Icon",
};

function SuperTrackerMixin:UpdateIcon()
    local superTrackingType = SuperTrackerUtil.GetHighestPrioritySuperTrackingType() or Enum.SuperTrackingType.Quest
    local atlas = iconLookup[superTrackingType] or "Navigation-Tracked-Icon"
    self.Icon:SetAtlas(atlas, Const.TextureKit.UseAtlasSize)
    self:UpdateIconSize()
end

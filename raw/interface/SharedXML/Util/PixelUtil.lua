PixelUtil = {};

function PixelUtil.GetPixelToUIUnitFactor()
    local physicalWidth, physicalHeight = GetScreenResolution();
    return 768.0 / physicalHeight;
end

function PixelUtil.GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
    if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
        return 0;
    end

    local uiUnitFactor = PixelUtil.GetPixelToUIUnitFactor();
    local numPixels = math.round((uiUnitSize * layoutScale) / uiUnitFactor);
    if minPixels then
        if uiUnitSize < 0.0 then
            if numPixels > -minPixels then
                numPixels = -minPixels;
            end
        else
            if numPixels < minPixels then
                numPixels = minPixels;
            end
        end
    end

    return numPixels * uiUnitFactor / layoutScale;
end

function PixelUtil.ConvertPixelsToUI(desiredPixels, layoutScale)
    return PixelUtil.GetNearestPixelSize(desiredPixels, layoutScale);
end

local function GetRegionEffectiveScale(region)
    if region.GetEffectiveScale then
        return region:GetEffectiveScale()
    else
        local parent = region.GetParent and region:GetParent();
        return parent and parent:GetEffectiveScale() or 1.0;
    end
end

function PixelUtil.ConvertPixelsToUIForRegion(desiredPixels, region)
    return PixelUtil.GetNearestPixelSize(desiredPixels, GetRegionEffectiveScale(region));
end

function PixelUtil.SetWidth(region, width, minPixels)
    region:SetWidth(PixelUtil.GetNearestPixelSize(width, GetRegionEffectiveScale(region), minPixels));
end

function PixelUtil.SetHeight(region, height, minPixels)
    region:SetHeight(PixelUtil.GetNearestPixelSize(height, GetRegionEffectiveScale(region), minPixels));
end

function PixelUtil.SetSize(region, width, height, minWidthPixels, minHeightPixels)
    PixelUtil.SetWidth(region, width, minWidthPixels);
    PixelUtil.SetHeight(region, height, minHeightPixels);
end

function PixelUtil.SetPoint(region, point, relativeTo, relativePoint, offsetX, offsetY, minOffsetXPixels, minOffsetYPixels)
    region:SetPoint(point, relativeTo, relativePoint,
            PixelUtil.GetNearestPixelSize(offsetX, GetRegionEffectiveScale(region), minOffsetXPixels),
            PixelUtil.GetNearestPixelSize(offsetY, GetRegionEffectiveScale(region), minOffsetYPixels)
    );
end

function PixelUtil.SetStatusBarValue(statusBar, value)
    local width = statusBar:GetWidth();
    if width and width > 0.0 then
        local min, max = statusBar:GetMinMaxValues();
        local percent = MClampedPercentBetween(value, min, max);
        if percent == 0.0 or percent == 1.0 then
            statusBar:SetValue(value);
        else
            local numPixels = PixelUtil.GetNearestPixelSize(statusBar:GetWidth() * percent, GetRegionEffectiveScale(statusBar));
            local roundedValue = MLerp(min, max, numPixels / width);
            statusBar:SetValue(roundedValue);
        end
    else
        statusBar:SetValue(value);
    end
end
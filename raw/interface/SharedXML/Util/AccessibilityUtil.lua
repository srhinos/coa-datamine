AccessibilityUtil = {}

function AccessibilityUtil.IsColorBlind()
    return ENABLE_COLORBLIND_MODE == "1"
end

function AccessibilityUtil.GetAbilityEssenceMarkup()
    if AccessibilityUtil.IsColorBlind() then
        return ABILITY_ESSENCE_ABBR
    else
        return MARKUP_AE_ICON
    end
end

function AccessibilityUtil.GetTalentEssenceMarkup()
    if AccessibilityUtil.IsColorBlind() then
        return TALENT_ESSENCE_ABBR
    else
        return MARKUP_TE_ICON
    end
end

function AccessibilityUtil.GetRarityGemMarkup(quality, short)
    if AccessibilityUtil.IsColorBlind() then
        if short then
            return _G["ITEM_QUALITY".. quality .. "_SHORT"]
        end
        return _G["ITEM_QUALITY".. quality .. "_DESC"]
    else
        return _G["MARKUP_RARITY_GEM"..quality]
    end
end

function AccessibilityUtil.GetClassPointsMarkup(class)
    if AccessibilityUtil.IsColorBlind() then
        return LOCALIZED_CLASS_NAMES_MALE[class:upper()] or ""
    else
        return "|TInterface\\Icons\\classicon_"..(class and class:lower() or "")..":18:18|t"
    end
end
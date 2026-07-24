if not GetGameTooltipMetatable then return end

local Tooltip = GetGameTooltipMetatable().__index

-- runs str.match on each line, returning whatever the result is if any
function Tooltip:Match(match)
    for i = 1, self:NumLines() do
        local line = _G[self:GetName() .. "TextLeft" .. i]:GetText()

        if line and line ~= "" then
            local value = line:match(match)
            if value then
                return value
            end
        end
    end
end

function Tooltip:GetItemMysticEnchant()
    local link = select(2, self:GetItem())
    if not link then return end
    local itemID = GetItemInfoFromHyperlink(link)
    if not itemID then return end
    local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
    if not enchant then return end

    return enchant.SpellID, enchant
end

function Tooltip:SetAffix(affixID)
    affixID = affixID and tonumber(affixID)
    assert(affixID and affixID > 0, "GameTooltip:SetAffix(affixID) affixID is not a number or not greater than 0")

    local name, rank = GetSpellInfo(affixID)
    if not name then return end

    self:AddDoubleLine(name, rank, 1, 1, 1, 0.5, 0.5, 0.5)
    local desc, extraLines = GetSpellDescription(affixID)
    if desc then
        local r, g, b = NORMAL_FONT_COLOR:GetRGB()
        self:AddLine(desc, r, g, b, true)
    end

    if extraLines then
        for _, line in ipairs(extraLines) do
            local text, r, g, b = unpack(line)
            self:AddLine(text, r, g, b, true)
        end
    end

    if IsGMClient then
        self:AddLine(ASCENSION_PRIMARY_COLOR:WrapText("ID ") .. ASCENSION_SECONDARY_COLOR:WrapText(affixID))
    end
end

local function TooltipSaveLines(tooltip, numLines)
    local leftText = {}
    local rightText = {}

    -- store all the lines we have
    for i = 1, numLines do
        local right = _G[tooltip:GetName() .. "TextRight" .. i]
        if right:GetText() and right:GetText():len() > 0 then
            local rr, rg, rb = right:GetTextColor()
            rightText[i] = { right:GetText(), rr, rg, rb }

            -- if there is right text there has to be left, even if empty
            local left = _G[tooltip:GetName() .. "TextLeft" .. i]
            local lr, lg, lb = left:GetTextColor()
            leftText[i] = { left:GetText(), lr, lg, lb }
        else
            local left = _G[tooltip:GetName() .. "TextLeft" .. i]
            if left then
                local lr, lg, lb = left:GetTextColor()
                leftText[i] = { left:GetText(), lr, lg, lb }
            end
        end
    end

    return leftText, rightText
end

function Tooltip:InsertLine(text, lineNum, r, g, b, wrapText)
    local numLines = self:NumLines()
    local leftText, rightText = TooltipSaveLines(self, numLines)

    -- insert lines
    local offset = 0
    for i = 1, numLines + 1 do
        offset = offset + 1
        if i == lineNum then
            local line = _G[self:GetName() .. "TextLeft" .. i]
            if line then
                line:SetText(text)
                line:SetTextColor(r, g, b)
                local right = _G[self:GetName() .. "TextRight" .. i]
                if right and right:GetText() then
                    right:SetText("")
                end
            else
                self:AddLine(text, r, g, b, wrapText)
            end
            offset = offset - 1
        else
            local left = leftText[offset]
            local right = rightText[offset]

            if right then
                local rText, rr, rg, rb = unpack(right)
                local lText, lr, lg, lb = unpack(left)
                if i <= numLines then
                    local line = _G[self:GetName() .. "TextLeft" .. i]
                    line:SetText(lText)
                    line:SetTextColor(lr, lg, lb)
                    local rightLine = _G[self:GetName() .. "TextRight" .. i]
                    rightLine:SetText(rText)
                    rightLine:SetTextColor(rr, rg, rb)
                else
                    self:AddDoubleLine(lText, rText, lr, lg, lb, rr, rg, rb)
                end
            elseif left then
                local lText, lr, lg, lb = unpack(left)
                if i <= numLines then
                    local line = _G[self:GetName() .. "TextLeft" .. i]
                    line:SetText(lText)
                    line:SetTextColor(lr, lg, lb)
                    local rightLine = _G[self:GetName() .. "TextRight" .. i]
                    if rightLine and rightLine:GetText() then
                        rightLine:SetText("")
                    end
                else
                    self:AddLine(lText, lr, lg, lb, true)
                end
            end
        end
    end
end

function Tooltip:InsertLines(lines, count)
    local numLines = self:NumLines()
    local leftText, rightText = TooltipSaveLines(self, numLines)

    -- insert lines
    local offset = 0
    for i = 1, numLines + count do
        offset = offset + 1
        if lines[i] then
            local text, r, g, b = unpack(lines[i])
            local line = _G[self:GetName() .. "TextLeft" .. i]
            if line then
                line:SetText(text)
                line:SetTextColor(r, g, b)
                local right = _G[self:GetName() .. "TextRight" .. i]
                if right and right:GetText() then
                    right:SetText("")
                end
            else
                self:AddLine(text, r, g, b)
            end
            offset = offset - 1
        else
            local left = leftText[offset]
            local right = rightText[offset]

            if right then
                local rText, rr, rg, rb = unpack(right)
                local lText, lr, lg, lb = unpack(left)
                if i <= numLines then
                    local line = _G[self:GetName() .. "TextLeft" .. i]
                    line:SetText(lText)
                    line:SetTextColor(lr, lg, lb)
                    local rightLine = _G[self:GetName() .. "TextRight" .. i]
                    rightLine:SetText(rText)
                    rightLine:SetTextColor(rr, rg, rb)
                else
                    self:AddDoubleLine(lText, rText, lr, lg, lb, rr, rg, rb)
                end
            elseif left then
                local lText, lr, lg, lb = unpack(left)
                if i <= numLines then
                    local line = _G[self:GetName() .. "TextLeft" .. i]
                    line:SetText(lText)
                    line:SetTextColor(lr, lg, lb)
                    local rightLine = _G[self:GetName() .. "TextRight" .. i]
                    if rightLine and rightLine:GetText() then
                        rightLine:SetText("")
                    end
                else
                    self:AddLine(lText, lr, lg, lb, true)
                end
            end
        end
    end
end

function Tooltip:SetToken(tokenType)
    local token = TokenUtil.CreateFromTokenType(tokenType)
    local quality = ITEM_QUALITY_COLORS[Enum.ItemQuality.Common]
    self:AddDoubleLine(token:GetName(), format(COUNT_S, token:GetCount()), quality.r, quality.g, quality.b, DISABLED_FONT_COLOR.r, DISABLED_FONT_COLOR.g, DISABLED_FONT_COLOR.b)
    self:AddLine(token:GetTooltip(), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)

    if IsGMClient then
        self:AddLine(ASCENSION_PRIMARY_COLOR:WrapText("TokenType ") .. ASCENSION_SECONDARY_COLOR:WrapText(tokenType))
    end

    self:Show()
end

function Tooltip:SetSpellByID(spellID)
    -- for some reason GameTooltip specifically cannot use SetSpellByID
    self:SetHyperlink("spell:" .. spellID)
end
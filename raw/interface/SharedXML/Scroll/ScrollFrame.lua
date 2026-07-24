-- returns ScrollBar, ScrollBarScrollUpButton, ScrollBarScrollDownButton, ThumbTexture, Top, Bottom, Middle, Track, ScrollChildFrame
-- local scrollBar, scrollUpButton, scrollDownButton, thumbTexture, top, bottom, middle, track, scrollChildFrame = ScrollFrame_GetScrollElements(self)
function ScrollFrame_GetScrollElements(self)
    local name = self:GetName()
    if name then
        return _G[name.."ScrollBar"],
        _G[name.."ScrollBarScrollUpButton"],
        _G[name.."ScrollBarScrollDownButton"],
        _G[name.."ScrollBarThumbTexture"] or _G[name.."ScrollBarThumb"],
        _G[name.."Top"],
        _G[name.."Bottom"],
        _G[name.."Middle"],
        _G[name.."Track"],
        _G[name.."ScrollChildFrame"]
    else
        return self.ScrollBar,
        self.ScrollBar.ScrollUpButton,
        self.ScrollBar.ScrollDownButton,
        self.ScrollBar.ThumbTexture or self.ScrollBar.Thumb,
        self.ScrollBar.Top,
        self.ScrollBar.Bottom,
        self.ScrollBar.Middle,
        self.ScrollBar.Track,
        self.ScrollChildFrame
    end
end

function ScrollFrameTemplate_OnMouseWheel(self, value, scrollBar)
    scrollBar = scrollBar or ScrollFrame_GetScrollElements(self)
    if ( value > 0 ) then
        scrollBar:SetValue(scrollBar:GetValue() - (scrollBar:GetHeight() / 2));
    else
        scrollBar:SetValue(scrollBar:GetValue() + (scrollBar:GetHeight() / 2));
    end
end

function ScrollFrameTemplate_OnMouseWheelVariable(self, value, scrollBar, dist)
    scrollBar = scrollBar or ScrollFrame_GetScrollElements(self)
    if ( value > 0 ) then
        scrollBar:SetValue(scrollBar:GetValue() - dist);
    else
        scrollBar:SetValue(scrollBar:GetValue() + dist);
    end
end

-- Function to handle the update of manually calculated scrollframes.  Used mostly for listings with an indeterminate number of items
function FauxScrollFrame_Update(frame, numItems, numToDisplay, valueStep, button, smallWidth, bigWidth, highlightFrame, smallHighlightWidth, bigHighlightWidth, alwaysShowScrollBar )
    local scrollBar, scrollUpButton, scrollDownButton, thumbTexture, top, bottom, middle, track, scrollChildFrame = ScrollFrame_GetScrollElements(frame)
    local showScrollBar;
    if ( numItems > numToDisplay or alwaysShowScrollBar ) then
        frame:Show();
        showScrollBar = 1;
    else
        scrollBar:SetValue(0);
        frame:Hide();
    end
    if ( frame:IsShown() ) then
        local scrollFrameHeight = 0;
        local scrollChildHeight = 0;

        if ( numItems > 0 ) then
            scrollFrameHeight = (numItems - numToDisplay) * valueStep;
            scrollChildHeight = numItems * valueStep;
            if ( scrollFrameHeight < 0 ) then
                scrollFrameHeight = 0;
            end
            scrollChildFrame:Show();
        else
            scrollChildFrame:Hide();
        end
        scrollBar:SetMinMaxValues(0, scrollFrameHeight);
        scrollBar:SetValueStep(valueStep);
        scrollChildFrame:SetHeight(scrollChildHeight);

        -- Arrow button handling
        if ( scrollBar:GetValue() == 0 ) then
            scrollUpButton:Disable();
        else
            scrollUpButton:Enable();
        end
        if ((scrollBar:GetValue() - scrollFrameHeight) == 0) then
            scrollDownButton:Disable();
        else
            scrollDownButton:Enable();
        end

        -- Shrink because scrollbar is shown
        if ( highlightFrame ) then
            highlightFrame:SetWidth(smallHighlightWidth);
        end
        if ( button ) then
            for i=1, numToDisplay do
                _G[button..i]:SetWidth(smallWidth);
            end
        end
    else
        -- Widen because scrollbar is hidden
        if ( highlightFrame ) then
            highlightFrame:SetWidth(bigHighlightWidth);
        end
        if ( button ) then
            for i=1, numToDisplay do
                _G[button..i]:SetWidth(bigWidth);
            end
        end
    end
    return showScrollBar;
end

function FauxScrollFrame_OnVerticalScroll(self, value, itemHeight, updateFunction)
    local scrollbar = ScrollFrame_GetScrollElements(self)
    scrollbar:SetValue(value);
    self.offset = floor((value / itemHeight) + 0.5);
    if ( updateFunction ) then
        updateFunction(self);
    end
end

function FauxScrollFrame_GetOffset(frame)
    return frame.offset or 0
end

function FauxScrollFrame_SetOffset(frame, offset)
    frame.offset = offset;
end

-- Scrollframe functions

function ScrollFrame_OnLoad(self)
    local scrollBar, scrollUpButton, scrollDownButton = ScrollFrame_GetScrollElements(self)
    scrollDownButton:Disable();
    scrollUpButton:Disable();

    scrollBar:SetMinMaxValues(0, 0);
    scrollBar:SetValue(0);
    self.offset = 0;

    if ( self.scrollBarHideable or self.neverShowScroll ) then
        scrollBar:Hide();
        scrollDownButton:Hide();
        scrollUpButton:Hide();
    else
        scrollDownButton:Disable();
        scrollUpButton:Disable();
        scrollDownButton:Show();
        scrollUpButton:Show();
    end
end

function ScrollFrame_OnScrollRangeChanged(self, xrange, yrange)
    local scrollBar, scrollUpButton, scrollDownButton, thumbTexture, top, bottom, middle, track = ScrollFrame_GetScrollElements(self)
    if ( not yrange ) then
        yrange = self:GetVerticalScrollRange();
    end
    local value = scrollBar:GetValue();

    if yrange <= 0 then
        yrange = 0
    end

    if ( value > yrange ) then
        value = yrange;
    end
    if value < 0 then
        value = 0
    end
    scrollBar:SetMinMaxValues(0, yrange);

    if self.scrollToBottom then
        value = yrange;
    elseif self.scrollToTop then
        value = 0;
    end
    scrollBar:SetValue(value);
    if ( floor(yrange) == 0 ) or self.neverShowScroll then
        if ( self.scrollBarHideable or self.neverShowScroll ) then
            scrollBar:Hide();
            scrollDownButton:Hide();
            scrollUpButton:Hide();
            if ( self.haveTrack ) then
                track:Hide();
            end
        else
            scrollDownButton:Disable();
            scrollUpButton:Disable();
            scrollDownButton:Show();
            scrollUpButton:Show();
        end
        thumbTexture:Hide();
    else
        scrollDownButton:Show();
        scrollUpButton:Show();
        scrollBar:Show();
        thumbTexture:Show();
        if ( self.haveTrack ) then
            track:Show();
        end
        -- The 0.005 is to account for precision errors
        if ( yrange - value > 0.005 ) then
            scrollDownButton:Enable();
        else
            scrollDownButton:Disable();
        end
    end

    -- Hide/show scrollframe borders
    if ( top and bottom and self.scrollBarHideable ) then
        if ( self:GetVerticalScrollRange() == 0 ) then
            top:Hide();
            bottom:Hide();
        else
            top:Show();
            bottom:Show();
        end
    end
    if ( middle and self.scrollBarHideable ) then
        if ( self:GetVerticalScrollRange() == 0 ) then
            middle:Hide();
        else
            middle:Show();
        end
    end
end

function ScrollFrame_OnVerticalScroll(self, offset)
    local scrollBar, scrollUpButton, scrollDownButton = ScrollFrame_GetScrollElements(self)
    scrollBar:SetValue(offset);
    local min;
    local max;
    min, max = scrollBar:GetMinMaxValues();

    scrollUpButton:SetEnabled(offset > 0)
    scrollDownButton:SetEnabled((scrollBar:GetValue() - max) ~= 0)
end

function ScrollFrame_ScrollToTop(self)
    local scrollBar = ScrollFrame_GetScrollElements(self)
    local min = scrollBar:GetMinMaxValues()
    scrollBar:SetValue(min)
end

function ScrollFrame_ScrollToBottom(self)
    local scrollBar = ScrollFrame_GetScrollElements(self)
    local _, max = scrollBar:GetMinMaxValues()
    scrollBar:SetValue(max)
end

function ScrollingEdit_OnTextChanged(self, scrollFrame)
    -- force an update when the text changes
    self.handleCursorChange = true;
    ScrollingEdit_OnUpdate(self, 0, scrollFrame);
end

function ScrollingEdit_OnCursorChanged(self, x, y, w, h)
    self.cursorOffset = y;
    self.cursorHeight = h;
    self.handleCursorChange = true;
end

-- NOTE: If your edit box never shows partial lines of text, then this function will not work when you use
-- your mouse to move the edit cursor. You need the edit box to cut lines of text so that you can use your
-- mouse to highlight those partially-seen lines; otherwise you won't be able to use the mouse to move the
-- cursor above or below the current scroll area of the edit box.
function ScrollingEdit_OnUpdate(self, elapsed, scrollFrame)
    local height, range, scroll, size, cursorOffset;
    if ( self.handleCursorChange ) then
        if ( not scrollFrame ) then
            scrollFrame = self:GetParent();
        end
        height = scrollFrame:GetHeight();
        range = scrollFrame:GetVerticalScrollRange();
        scroll = scrollFrame:GetVerticalScroll();
        size = height + range;
        cursorOffset = -(self.cursorOffset or 0);

        if ( math.floor(height) <= 0 or math.floor(range) <= 0 ) then
            --Frame has no area, nothing to calculate.
            return;
        end

        while ( cursorOffset < scroll ) do
            scroll = (scroll - (height / 2));
            if ( scroll < 0 ) then
                scroll = 0;
            end
            scrollFrame:SetVerticalScroll(scroll);
        end

        while ( (cursorOffset + self.cursorHeight) > (scroll + height) and scroll < range ) do
            scroll = (scroll + (height / 2));
            if ( scroll > range ) then
                scroll = range;
            end
            scrollFrame:SetVerticalScroll(scroll);
        end

        self.handleCursorChange = false;
    end
end
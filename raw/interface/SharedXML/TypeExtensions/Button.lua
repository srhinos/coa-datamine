local Button = GetButtonMetatable().__index
local CheckButton = GetCheckButtonMetatable().__index

-- SetEnabled(enable)
local function SetEnabled(self, enable)
    if enable then
        self:Enable()
    else
        self:Disable()
    end
end

Button.SetEnabled = SetEnabled
CheckButton.SetEnabled = SetEnabled

-- SetXAtlas(atlas, useAtlasSize)
local ButtonTex = {
    "Normal",
    "Pushed",
    "Disabled",
    "Highlight",
    "Checked",
}

for _, tex in ipairs(ButtonTex) do
    local func = function(self, atlas, useAtlasSize)
        local get = self["Get" .. tex .. "Texture"]
        local set = self["Set" .. tex .. "Texture"]
        if not get(self) then
            set(self, "Interface\\Buttons\\WHITE8x8") -- just some arbitrary texture to setup the texture object
        end
        get(self):SetAtlas(atlas, useAtlasSize)
    end

    if tex == "Checked" then
        CheckButton["Set" .. tex .. "Atlas"] = func
    else
        CheckButton["Set" .. tex .. "Atlas"] = func
        Button["Set" .. tex .. "Atlas"] = func
    end
end

-- deprecated
function CheckButton:GetBoolValue()
    return self:GetChecked() and true or false
end

function CheckButton:GetCheckedBool()
    return self:GetChecked() and true or false
end

function CheckButton:InvertCheck()
    self:SetChecked(not self:GetChecked())
end
-- Model -> PlayerModel -> [DressUpModel, TabardModel]
local Model = GetModelMetatable().__index
local PlayerModel = GetPlayerModelMetatable and GetPlayerModelMetatable().__index or {}
local DressUpModel = GetDressUpModelMetatable and GetDressUpModelMetatable().__index or {}
local TabardModel = GetTabardModelMetatable and GetTabardModelMetatable().__index or {}

local function SetDisplayInfo(self, id, callback)
    if self.cancelToken then
        self.cancelToken()
    end
    if not id then
        return self:ClearModel()
    end
    local creature = Creature:CreateFromID(id)
    if creature:IsCached() then
        self:SetCreature(id)
        if callback then
            RunNextFrame(function()
                callback(id, true)
            end)
        end
    else
        self.cancelToken = creature:CancelableContinueOnLoad(function(creatureID)
            self:SetCreature(id)
            if callback then callback(creatureID, false) end
        end)
    end
end
PlayerModel.SetDisplayInfo = SetDisplayInfo
DressUpModel.SetDisplayInfo = SetDisplayInfo
TabardModel.SetDisplayInfo = SetDisplayInfo

local camSq = 1567.09284983 -- sqrt(1366^2 + 768^2)
local function ApplyUICamera(self, cameraID, refresh)
    if not refresh and self.cameraID == cameraID then return end
    self.cameraID = cameraID
    local x, y, z, facing, anim = C_UICamera.GetCameraInfo(cameraID)
    if x and y and z and facing then
        local scale = self:GetEffectiveScale() - (self:GetEffectiveScale() - UIParent:GetScale())
        local width, height = GetScreenSize(scale)

        local square = math.sqrt(width * width + height * height)
        local diff = (camSq / square) * self:GetModelScale()

        self:SetPosition(x * diff, y * diff, z * diff)
        self:SetFacing(facing)
        self:StopSequence()

        if anim and anim > 0 then
            self:PlaySequence(anim, true)
        else
            self:SetSequence(3)
        end

        if x ~= 0 then
            self.unscaleFactor = x / (x * diff)
        elseif y ~= 0 then
            self.unscaleFactor = y / (y * diff)
        elseif z ~= 0 then
            self.unscaleFactor = z / (z * diff)
        else
            self.unscaleFactor = 1
        end
    end
end
PlayerModel.ApplyUICamera = ApplyUICamera
DressUpModel.ApplyUICamera = ApplyUICamera
TabardModel.ApplyUICamera = ApplyUICamera

local function GetUnscaledPosition(self)
    if self.unscaleFactor then
        local x, y, z = self:GetPosition()
        return x * self.unscaleFactor, y * self.unscaleFactor, z * self.unscaleFactor
    end

    return self:GetPosition()
end
PlayerModel.GetUnscaledPosition = GetUnscaledPosition
DressUpModel.GetUnscaledPosition = GetUnscaledPosition
TabardModel.GetUnscaledPosition = GetUnscaledPosition

local function PlaySequence(self, sequence, looping)
    if self.PlayingSequence then return end

    if not self.sequenceHooked then
        self:HookScript("OnAnimFinished", function(self)
            if not self.PlayingSequence then return end

            if self.sequenceLooping then
                self.sequenceTime = 0
            else
                self:StopSequence()
            end
        end)

        self:HookScript("OnUpdate", function(self, elapsed)
            if not self.PlayingSequence then return end

            if self.sequenceTime > 1e100 then
                self.sequenceTime = 0
            end

            self:SetSequenceTime(self.PlayingSequence, self.sequenceTime)
            if not self.freezeSequence then
                self.sequenceTime = self.sequenceTime + elapsed * 1000
            end
        end)

        self.sequenceHooked = true
    end

    self.sequenceLooping = looping
    self.sequenceTime = 0
    self.PlayingSequence = sequence
    self.freezeSequence = nil
end
PlayerModel.PlaySequence = PlaySequence
DressUpModel.PlaySequence = PlaySequence
TabardModel.PlaySequence = PlaySequence

local function FreezeSequence(self, time)
    if not self.PlayingSequence then return end
    if not time then time = self.sequenceTime end

    if self.sequenceHooked then
        self.sequenceTime = time
        self.freezeSequence = true
        self:SetSequenceTime(self.PlayingSequence, time)
    end
end
PlayerModel.FreezeSequence = FreezeSequence
DressUpModel.FreezeSequence = FreezeSequence
TabardModel.FreezeSequence = FreezeSequence

local function StopSequence(self, sequence)
    if not self.PlayingSequence then return end
    -- allows conditional stopping on only a certain sequence
    if sequence and sequence ~= self.PlayingSequence then return end
    self.PlayingSequence = nil
    self.freezeSequence = nil
end
PlayerModel.StopSequence = StopSequence
DressUpModel.StopSequence = StopSequence
TabardModel.StopSequence = StopSequence

local function GetPlayingSequence(self)
    return self.PlayingSequence
end
PlayerModel.GetPlayingSequence = GetPlayingSequence
DressUpModel.GetPlayingSequence = GetPlayingSequence
TabardModel.GetPlayingSequence = GetPlayingSequence
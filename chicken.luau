local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Plr = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local Window = Library:CreateWindow({
    Title = "Ye",
    Footer = "v0.05",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true
})

local MainTab = Window:AddTab({Name = "Main", Icon = "house"})
local VisualsTab = Window:AddTab({Name = "Visuals(soon) ", Icon = "eye"})
local ExploitTab = Window:AddTab({Name = "Exploits", Icon = "bug"})

local SpHackGroupbox = ExploitTab:AddLeftGroupbox("Speed Hack")
local PGroupbox = MainTab:AddLeftGroupbox("Player")
local ProximityGroupbox = MainTab:AddRightGroupbox("ProximityPrompts")

local EspTabbox = VisualsTab:AddLeftTabbox("ESP")
local EspOpt = EspTabbox:AddTab("ESP")
local EspSet = EspTabbox:AddTab("Settings")

local DashSpeedEnabled = false
local DashSpeedValue = 30
local DashSpeedDelay = 2
local DashFreezeTime = 0.1
local CurrentSpeed = 4
local SpeedEnabled = false
local NoClipEnabled = false
local JumpEnabled = false
local InstantInteract = false
local AlwaysVisible = false

local ProximityPrompts = {}
local PromptOriginals = {}

local function applyToPrompt(prompt)
    local orig = PromptOriginals[prompt]
    if not (prompt and orig) then return end
    local desiredHold = InstantInteract and 0 or orig.HoldDuration
    local desiredLOS  = AlwaysVisible and false or orig.RequiresLineOfSight
    if prompt.HoldDuration ~= desiredHold then
        prompt.HoldDuration = desiredHold
    end
    if prompt.RequiresLineOfSight ~= desiredLOS then
        prompt.RequiresLineOfSight = desiredLOS
    end
end

local function registerPrompt(prompt)
    if not prompt or PromptOriginals[prompt] then return end
    PromptOriginals[prompt] = {
        HoldDuration = prompt.HoldDuration,
        RequiresLineOfSight = prompt.RequiresLineOfSight
    }
    table.insert(ProximityPrompts, prompt)
    prompt.Destroying:Once(function()
        PromptOriginals[prompt] = nil
        for i, p in ipairs(ProximityPrompts) do
            if p == prompt then
                table.remove(ProximityPrompts, i)
                break
            end
        end
    end)
    applyToPrompt(prompt)
end

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("ProximityPrompt") then
        registerPrompt(obj)
    end
end

game.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") then
        registerPrompt(obj)
    end
end)

local function refreshAllPrompts()
    for _, prompt in ipairs(ProximityPrompts) do
        applyToPrompt(prompt)
    end
end

SpHackGroupbox:AddSlider("DashDelaySlider", {
    Text = "Dash Bypass Speed Delay",
    Default = 0.2,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(val)
        DashSpeedDelay = val
    end
})

SpHackGroupbox:AddSlider("DashSpeedSlider", {
    Text = "Dash Bypass Speed",
    Default = 28,
    Min = 0,
    Max = 80,
    Rounding = 1,
    Compact = false,
    Callback = function(val)
        DashSpeedValue = val
    end
})

SpHackGroupbox:AddSlider("DashFreezeSlider", {
    Text = "Dash Bypass Speed Freeze Time",
    Default = 0.1,
    Min = 0,
    Max = 12,
    Rounding = 1,
    Compact = false,
    Callback = function(val)
        DashFreezeTime = val
    end
})

SpHackGroupbox:AddToggle("DashBypassToggle", {
    Text = "Enable Dash Bypass",
    Default = false,
    Tooltip = "Enable Speed Boost",
    Callback = function(state)
        DashSpeedEnabled = state
        if state and Plr.Character then
            DashSpeedBypass(Plr.Character)
        end
    end
})

PGroupbox:AddSlider("SpeedSlider", {
    Text = "Speed Boost",
    Default = 4,
    Min = 0,
    Max = 12,
    Rounding = 1,
    Compact = false,
    Callback = function(val)
        CurrentSpeed = val
    end
})

PGroupbox:AddToggle("SpeedBoostToggle", {
    Text = "Enable Speed Boost",
    Default = false,
    Tooltip = "Enable Speed Boost",
    Callback = function(val)
        SpeedEnabled = val
        checkLoop()
    end
})

PGroupbox:AddToggle("NoClipToggle", {
    Text = "NoClip",
    Default = false,
    Tooltip = "Enables Noclip",
    Callback = function(val)
        NoClipEnabled = val
        checkLoop()
    end
})

PGroupbox:AddToggle("JumpToggle", {
    Text = "Enable Jump",
    Default = false,
    Tooltip = "Enables Jump",
    Callback = function(val)
        JumpEnabled = val
        checkLoop()
    end
})

ProximityGroupbox:AddToggle("InstantToggle", {
    Text = "Instant Interact",
    Default = false,
    Tooltip = "Removes hold duration",
    Callback = function(val)
        InstantInteract = val
        refreshAllPrompts()
    end
})

ProximityGroupbox:AddToggle("VisibleToggle", {
    Text = "Visible Through Walls",
    Default = false,
    Tooltip = "Makes prompts visible behind walls",
    Callback = function(val)
        AlwaysVisible = val
        refreshAllPrompts()
    end
})

local originalCollisions = {}
local loopConnection

local function startFeatureLoop(character)
    if loopConnection then loopConnection:Disconnect() end
    loopConnection = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then
            loopConnection:Disconnect()
            loopConnection = nil
            return
        end
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            if SpeedEnabled then
                character:SetAttribute("SpeedBoost", CurrentSpeed)
            else
                character:SetAttribute("SpeedBoost", 0)
            end
            character:SetAttribute("CanJump", JumpEnabled)
        end
        for part, original in pairs(originalCollisions) do
            if part and part:IsA("BasePart") then
                if NoClipEnabled then
                    part.CanCollide = false
                else
                    part.CanCollide = original
                end
            end
        end
        if not SpeedEnabled and not NoClipEnabled and not JumpEnabled then
            loopConnection:Disconnect()
            loopConnection = nil
        end
    end)
end

function checkLoop()
    if (SpeedEnabled or NoClipEnabled or JumpEnabled) and not loopConnection then
        if Plr.Character then
            startFeatureLoop(Plr.Character)
        end
    end
end

local function applyPlayerFeatures(character)
    originalCollisions = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end
    character.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end)
end

function DashSpeedBypass(character)
    coroutine.wrap(function()
        local root = character:WaitForChild("HumanoidRootPart")
        local hum = character:WaitForChild("Humanoid")
        local friction = 0.4
        while character and character.Parent do
            if DashSpeedEnabled then
                character:SetAttribute("SpeedBoost", DashSpeedValue)
                local savedVel = root.AssemblyLinearVelocity
                if DashFreezeTime > 0 then
                    root.Anchored = true
                    task.wait(DashFreezeTime)
                    root.Anchored = false
                    root.AssemblyLinearVelocity = savedVel
                end
                while hum.MoveDirection.Magnitude == 0 and DashSpeedEnabled and character and character.Parent do
                    local vel = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
                    RunService.Heartbeat:Wait()
                end
                local elapsed = 0
                while elapsed < DashSpeedDelay and DashSpeedEnabled and character and character.Parent do
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude == 0 then
                        local vel = root.AssemblyLinearVelocity
                        root.AssemblyLinearVelocity = Vector3.new(
                            vel.X * friction,
                            vel.Y,
                            vel.Z * friction
                        )
                    end
                    local dt = RunService.Heartbeat:Wait()
                    elapsed = elapsed + dt
                end
            else
                character:SetAttribute("SpeedBoost", 0)
            end
            RunService.Heartbeat:Wait()
        end
    end)()
end

if Plr.Character then
    applyPlayerFeatures(Plr.Character)
    checkLoop()
    DashSpeedBypass(Plr.Character)
end

Plr.CharacterAdded:Connect(function(char)
    applyPlayerFeatures(char)
    checkLoop()
    DashSpeedBypass(char)
end)
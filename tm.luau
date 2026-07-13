local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local debugp = false
_G.DisableToolLimit = _G.DisableToolLimit or false
_G.FullPlace = _G.FullPlace or false

local function dlog(...)
    if debugp then print("[DEBUG]", ...) end
end

local QuestConditions = require(ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("QuestConditions"))
local ChallengeConditions = require(ReplicatedStorage:WaitForChild("Scripts"):WaitForChild("ChallengeConditions"))
local GetBlockInfo = require(ReplicatedStorage.Scripts:WaitForChild("GetBlockInfo"))

local b_item, b_rot, b_target, b_hit, b_surface, b_cfs, b_con = nil, CFrame.new(), nil, nil, nil, {}, {}
local s_box, s_handles, s_con, s_sz, s_cf, s_drag, s_lock = nil, nil, {}, nil, CFrame.new(), false, false
local t_box, t_mh, t_ah, t_con, t_sel, t_cts, t_drag, t_lock = nil, nil, nil, {}, {}, {}, false, false
local t_val = 0

local function isZone(p, z)
    if _G.DisableToolLimit then return true end
    if not z then return false end
    local pos, pos2, sz = p.Position, z.Position, z.Size
    local x, y, zx = sz.X, sz.Y, sz.Z
    if z.Rotation.Y > 89 and z.Rotation.Y < 91 or z.Rotation.Y < -89 and z.Rotation.Y > -91 then
        x, zx = sz.Z, sz.X
    end
    return pos.X > pos2.X - x/2 and pos.X < pos2.X + x/2 and pos.Z > pos2.Z - zx/2 and pos.Z < pos2.Z + zx/2
end

local function camLock(state)
    if state then
        if t_lock then return end
        t_lock = true
        Camera.CameraType = Enum.CameraType.Scriptable
        local sub = Camera.CameraSubject
        if sub:IsA("Humanoid") then sub = sub.RootPart end
        local p1 = sub.CFrame.p - Camera.CFrame.p
        local r1 = Camera.CFrame - Camera.CFrame.p
        RunService:BindToRenderStep("camLockTrowel", Enum.RenderPriority.Camera.Value, function()
            Camera.CFrame = r1 + sub.CFrame.p - p1
        end)
    else
        RunService:UnbindFromRenderStep("camLockTrowel")
        Camera.CameraType = Enum.CameraType.Custom
        t_lock = false
    end
end

local function cleanToolScripts(tool)
    for _, scr in ipairs(tool:GetDescendants()) do
        if scr:IsA("LocalScript") then
            scr.Disabled = true
        end
    end
end

local function playsound(id, parent, pitch)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.PlaybackSpeed = pitch or 1
    s.Parent = parent
    s.Volume = 0.5
    s:Play()
    Debris:AddItem(s, 1)
end

local function b_can(p)
    if _G.DisableToolLimit then return true, "" end
    local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
    if not isZone(p.PrimaryPart, zone) then return false, "Out of bounds" end
    local q1, q2 = QuestConditions(zone, p.PrimaryPart.CFrame, b_item.Name, 1, LocalPlayer)
    local c1, c2 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
    local r1, r2 = ChallengeConditions.itemRestriction(LocalPlayer, b_item.Name)
    if zone and q1 and not c1 and not r1 then return true, "" end
    return false, q2 or c2 or r2
end

local function b_updcf(p1)
    if tyranny or not Mouse.Target or not b_item then return end
    local part = b_item:FindFirstChild("2ndPlacement") and b_item.SecondaryPart or b_item
    if not p1 then
        b_target, b_hit, b_surface = Mouse.Target, Mouse.Hit, Mouse.TargetSurface
    end
    local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
    local baseCF = b_target.CFrame * CFrame.new(b_target.Size * 0.5)
    part:SetPrimaryPartCFrame(baseCF * b_rot)
    
    if not b_item:FindFirstChild("CanPlace") then
        local cp = Instance.new("BoolValue", b_item)
        cp.Name = "CanPlace"
        cp.Value = true
    end
    
    local ok = b_can(part)
    b_item.CanPlace.Value = ok
    if not ok and not _G.DisableToolLimit then
        for _, v in ipairs(b_item:GetDescendants()) do
            if v:IsA("BasePart") then v.BrickColor = BrickColor.Red() end
        end
    end
end

local function b_place(p1)
    if not b_item or not b_item:FindFirstChild("CanPlace") then return end
    if not b_item.CanPlace.Value and not _G.DisableToolLimit then return end
    
    local tool = LocalPlayer.Character:FindFirstChild("BuildingTool") or LocalPlayer.Backpack:FindFirstChild("BuildingTool")
    local rf = tool and tool:FindFirstChild("RF")
    if not rf then return end
    
    local selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
    local amountLabel = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[selected].AmountText
    local currentStock = tonumber(amountLabel.Text) or 0
    
    if currentStock <= 0 and not _G.DisableToolLimit then
        playsound("rbxassetid://9114223191", b_item.PrimaryPart, 5)
        return
    end
    
    local loopCount = (_G.FullPlace and currentStock > 0) and currentStock or 1
    
    task.spawn(function()
        for i = 1, loopCount do
            playsound("rbxassetid://9114223191", b_item.PrimaryPart, 1)
            local cf = b_item.PrimaryPart.CFrame
            local rel = b_target and b_target.CFrame:toObjectSpace(cf) or nil
            local anc = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
            
            rf:InvokeServer(b_item.Name, LocalPlayer.Data:FindFirstChild(b_item.Name).Value, b_target, rel, anc, cf, nil)
            if _G.FullPlace and i < loopCount then
                task.wait(0.2)
                if not b_item then break end
            end
        end
    end)
end

local function b_eq()
    local tool = LocalPlayer.Character:FindFirstChild("BuildingTool")
    if not tool then return end
    cleanToolScripts(tool)
    
    local selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
    b_item = ReplicatedStorage.BuildingParts:FindFirstChild(selected):Clone()
    b_item.Parent = workspace
    Mouse.TargetFilter = b_item
    
    table.insert(b_con, UserInputService.InputBegan:Connect(function(io, gpe)
        if gpe then return end
        if io.UserInputType == Enum.UserInputType.MouseButton1 then b_place() end
    end))
    table.insert(b_con, UserInputService.InputChanged:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseMovement then b_updcf() end
    end))
end

local function b_uneq()
    if b_item then b_item:Destroy() b_item = nil end
    for _, c in ipairs(b_con) do c:Disconnect() end
    b_con = {}
end

local function s_can(p)
    if v16 then return false end
    local v, _, v2 = GetBlockInfo(p, LocalPlayer)
    if v2 and string.find(v.Name, "Block") then return true, v end
    return false
end

local function s_eq()
    local tool = LocalPlayer.Character:FindFirstChild("ScalingTool")
    if not tool then return end
    cleanToolScripts(tool)
    
    s_box = Instance.new("SelectionBox", workspace)
    s_box.Color3 = Color3.fromRGB(172, 109, 0)
    
    table.insert(s_con, UserInputService.InputChanged:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseMovement and not s_drag then
            local tar = Mouse.Target
            if tar and tar.Parent then
                local ok, model = s_can(tar)
                if ok then s_box.Adornee = model else s_box.Adornee = nil end
            else
                s_box.Adornee = nil
            end
        end
    end))
    
    table.insert(s_con, UserInputService.InputBegan:Connect(function(io, gpe)
        if gpe then return end
        if io.UserInputType == Enum.UserInputType.MouseButton1 and s_box.Adornee then
            s_drag = true
            local adornee = s_box.Adornee
            local part = adornee.PrimaryPart
            
            s_handles = Instance.new("Handles", LocalPlayer.PlayerGui)
            s_handles.Adornee = part
            s_handles.Style = Enum.HandlesStyle.Resize
            
            local startCF = part.CFrame
            local startSize = part.Size
            
            s_handles.MouseButton1Down:Connect(function() camLock(true) end)
            s_handles.MouseDrag:Connect(function(face, delta)
                local inc = tonumber(LocalPlayer.PlayerGui.ScaleToolDisplayGui.BlockImage.More.Scale.TextBox.Text) or 1
                if inc ~= 0 then delta = delta - delta % inc end
                
                local nSize = startSize + Vector3.FromNormalId(face) * delta
                local nCF = startCF * CFrame.new(Vector3.FromNormalId(face) * (delta / 2))
                
                part.Size = Vector3.new(math.max(nSize.X, 0.05), math.max(nSize.Y, 0.05), math.max(nSize.Z, 0.05))
                part.CFrame = nCF
            end)
            
            s_handles.MouseButton1Up:Connect(function()
                camLock(false)
                s_handles:Destroy()
                s_handles = nil
                s_drag = false
                tool.RF:InvokeServer(adornee, part.Size, part.CFrame)
            end)
        end
    end))
end

local function s_uneq()
    if s_box then s_box:Destroy() s_box = nil end
    if s_handles then s_handles:Destroy() s_handles = nil end
    for _, c in ipairs(s_con) do c:Disconnect() end
    s_con = {}
    camLock(false)
end

local function t_getModels()
    local res = {}
    for k in pairs(t_sel) do table.insert(res, k) end
    return res
end

local function t_clear()
    for _, v in pairs(t_sel) do v:Destroy() end
    t_sel = {}
    t_val = 0
    t_cts = {}
end

local function t_add(p)
    local sb = Instance.new("SelectionBox", p)
    sb.Color3 = Color3.fromRGB(0, 126, 158)
    sb.Adornee = p
    t_sel[p] = sb
end

local function t_bbox()
    local models = t_getModels()
    if #models < 1 then
        if t_box then t_box:Destroy() t_box = nil end
        return
    end
    if not t_box then
        t_box = Instance.new("Part", workspace)
        t_box.Anchored = true
        t_box.Transparency = 1
        t_box.CanCollide = false
        local sb = Instance.new("SelectionBox", t_box)
        sb.Adornee = t_box
    end
    local minX, minY, minZ = 1/0, 1/0, 1/0
    local maxX, maxY, maxZ = -1/0, -1/0, -1/0
    for _, m in ipairs(models) do
        if m.PrimaryPart then
            local p = m.PrimaryPart.Position
            minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
            minY, maxY = math.min(minY, p.Y), math.max(maxY, p.Y)
            minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
        end
    end
    t_box.Size = Vector3.new(maxX - minX + 4, maxY - minY + 4, maxZ - minZ + 4)
    t_box.Position = Vector3.new((minX + maxX)/2, (minY + maxY)/2, (minZ + maxZ)/2)
end

local function t_eq()
    local tool = LocalPlayer.Character:FindFirstChild("TrowelTool")
    if not tool then return end
    cleanToolScripts(tool)
    
    table.insert(t_con, UserInputService.InputBegan:Connect(function(io, gpe)
        if gpe then return end
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            local tar = Mouse.Target
            if tar and tar.Parent then
                local m, _, ok = GetBlockInfo(tar, LocalPlayer)
                if ok and m then
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        if t_sel[m] then t_sel[m]:Destroy() t_sel[m] = nil else t_add(m) end
                    else
                        t_clear()
                        t_add(m)
                    end
                    t_bbox()
                end
            end
        end
    end))
end

local function t_uneq()
    t_clear()
    if t_box then t_box:Destroy() t_box = nil end
    for _, c in ipairs(t_con) do c:Disconnect() end
    t_con = {}
end

local function monitorCharacter()
    LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.1)
                if child.Name == "BuildingTool" then b_eq()
                elseif child.Name == "ScalingTool" then s_eq()
                elseif child.Name == "TrowelTool" then t_eq() end
            end
        end)
        char.ChildRemoved:Connect(function(child)
            if child.Name == "BuildingTool" then b_uneq()
            elseif child.Name == "ScalingTool" then s_uneq()
            elseif child.Name == "TrowelTool" then t_uneq() end
        end)
    end)
end

task.spawn(monitorCharacter)
dlog("Systems initialized smoothly")
print("I RAN")

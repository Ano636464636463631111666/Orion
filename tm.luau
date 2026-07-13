local debugp = false
local function dprint(...) if debugp then print("[DEBUG]", ...) end end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)

_G.DisableToolLimit = _G.DisableToolLimit or false
_G.FullPlace = _G.FullPlace or false

local b_item, b_name, b_lastCF, b_placing = nil, "WoodBlock", nil, false
local b_target, b_hit, b_surface, b_rot = nil, nil, nil, CFrame.new()
local b_conns = {}

local s_box, s_handles, s_size, s_vol = nil, nil, nil, 1
local s_conns = {}
local s_camLocked = false

local t_box, t_move, t_rot, t_sel, t_counts, t_val = nil, nil, nil, {}, {}, 0
local t_conns = {}
local t_camLocked, t_dragging, t_down, t_startPos = false, false, false, Vector2.new()

local function cleanConns(t)
    for k, v in pairs(t) do
        if typeof(v) == "RBXScriptConnection" then v:Disconnect() end
        t[k] = nil
    end
end

local function getBlockValue(p)
    if string.find(p.Name, "Block") and ReplicatedStorage.BuildingParts:FindFirstChild(p.Name) then
        local sz1 = ReplicatedStorage.BuildingParts[p.Name].PrimaryPart.Size
        return math.max((p.PrimaryPart.Size.X * p.PrimaryPart.Size.Y * p.PrimaryPart.Size.Z) / (sz1.X * sz1.Y * sz1.Z), 1)
    end
    return 1
end

local function isPartInZone(p, zone)
    if not zone then return false end
    local pos = typeof(p) == "CFrame" and p.Position or p.Position
    local zpos, zsz = zone.Position, zone.Size
    local x, z = zsz.X, zsz.Z
    if zone.Rotation.Y > 89 and zone.Rotation.Y < 91 or zone.Rotation.Y < -89 and zone.Rotation.Y > -91 then
        x, z = zsz.Z, zsz.X
    end
    return pos.X > zpos.X - x/2 and pos.X < zpos.X + x/2 and pos.Z > zpos.Z - z/2 and pos.Z < zpos.Z + z/2
end

local function camLock(state, flagRef)
    if state then
        Camera.CameraType = Enum.CameraType.Scriptable
        local sub = Camera.CameraSubject
        if sub:IsA("Humanoid") then sub = sub.RootPart end
        local diff = sub.CFrame.p - Camera.CFrame.p
        local rot = Camera.CFrame - Camera.CFrame.p
        RS:BindToRenderStep("camLockRef", 200, function()
            Camera.CFrame = rot + sub.CFrame.p - diff
        end)
    else
        RS:UnbindFromRenderStep("camLockRef")
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function playClick(parent, pitch)
    local tool = LocalPlayer.Backpack:FindFirstChild("BuildingTool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("BuildingTool"))
    local sound = tool biography and tool:FindFirstChild("ClickSound")
    if sound then
        local c = sound:Clone()
        c.PlaybackSpeed = pitch or 1
        c.Parent = parent
        c:Play()
        Debris:AddItem(c, 1)
    end
end

local function updateBuildGui()
    local bg = LocalPlayer.PlayerGui:FindFirstChild("BuildGui")
    if not bg then return end
    local sBox = bg.SearchFrame.SearchBox
    local txt = string.lower(sBox.Text):match("^%s*(.-)%s*$")
    for _, item in ipairs(bg.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()) do
        if ReplicatedStorage.BuildingParts:FindFirstChild(item.Name) then
            local t = string.match(item.TypeIcon.Image, "%d+") == "4597411234" and "Block" or "Special"
            local amt = LocalPlayer.Data[item.Name].Value
            if amt == 0 or (bg.SearchFrame.OnlyBlocks.Value and t ~= "Block") then
                item.Visible = false
            else
                item.Visible = true
            end
        end
    end
end

local function normToVec(id, part)
    if id == Enum.NormalId.Top then return Vector3.new(0,1,0), part.Size.Y
    elseif id == Enum.NormalId.Bottom then return Vector3.new(0,-1,0), part.Size.Y
    elseif id == Enum.NormalId.Front then return Vector3.new(0,0,-1), part.Size.Z
    elseif id == Enum.NormalId.Back then return Vector3.new(0,0,1), part.Size.Z
    elseif id == Enum.NormalId.Right then return Vector3.new(1,0,0), part.Size.X
    end
    return Vector3.new(-1,0,0), part.Size.X
end

local function b_updateCF(p1)
    if not Mouse.Target or not b_item then return end
    local part = b_item:FindFirstChild("2ndPlacement") and b_item.SecondaryPart or b_item
    if not p1 then
        b_target, b_hit, b_surface = Mouse.Target, Mouse.Hit, Mouse.TargetSurface
    end
    local inv = (b_target.CFrame - b_target.Position):Inverse()
    if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then inv = CFrame.new() end
    local nv, ext = normToVec(b_surface, b_target)
    local baseCF = b_target.CFrame * CFrame.new(nv * (ext / 2))
    part:SetPrimaryPartCFrame(baseCF * inv * b_rot)
    
    local wv = (b_target.CFrame - b_target.Position):PointToWorldSpace(nv)
    local sz = part.PrimaryPart.Size
    local r, u, l = math.abs(part.PrimaryPart.CFrame.RightVector:Dot(wv)), math.abs(part.PrimaryPart.CFrame.UpVector:Dot(wv)), math.abs(part.PrimaryPart.CFrame.LookVector:Dot(wv))
    local finalCF = baseCF * CFrame.new(nv * (r*(sz.X/2) + u*(sz.Y/2) + l*(sz.Z/2)))
    
    local localHit = b_target.CFrame:PointToObjectSpace(b_hit.p)
    local offset = localHit - Vector3.new(b_surface==Enum.NormalId.Left or b_surface==Enum.NormalId.Right and localHit.X or 0, b_surface==Enum.NormalId.Top or b_surface==Enum.NormalId.Bottom and localHit.Y or 0, b_surface==Enum.NormalId.Front or b_surface==Enum.NormalId.Back and localHit.Z or 0)
    local snap = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
    if snap ~= 0 then offset = Vector3.new(math.floor(offset.X*(1/snap)+0.5)/(1/snap), math.floor(offset.Y*(1/snap)+0.5)/(1/snap), math.floor(offset.Z*(1/snap)+0.5)/(1/snap)) end
    part:SetPrimaryPartCFrame(finalCF * CFrame.new(offset) * inv * b_rot)
end

local function b_place()
    if b_placing or not b_item then return end
    b_placing = true
    task.spawn(function() task.wait() b_placing = false end)
    
    local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
    local inZone = isPartInZone(b_item.PrimaryPart, zone)
    
    if not _G.DisableToolLimit then
        if not inZone then return end
        local pass = QuestConditions(zone, b_item.PrimaryPart.CFrame, b_item.Name, 1, LocalPlayer)
        if not pass then return end
    end
    
    local tool = LocalPlayer.Character:FindFirstChild("BuildingTool") or LocalPlayer.Backpack:FindFirstChild("BuildingTool")
    if not tool then return end
    
    local function executePlacement()
        local cspace = b_target and b_target.CFrame:toObjectSpace(b_item.PrimaryPart.CFrame) or nil
        local anc = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
        playClick(b_item.PrimaryPart, 1)
        tool.RF:InvokeServer(b_item.Name, LocalPlayer.Data:FindFirstChild(b_item.Name).Value, b_target, cspace, anc, b_item.PrimaryPart.CFrame, nil)
    end

    if _G.FullPlace then
        local amt = LocalPlayer.Data[b_item.Name].Value
        task.spawn(function()
            for i = 1, amt do
                executePlacement()
                task.wait(0.2)
                if not b_item then break end
            end
        end)
    else
        executePlacement()
    end
end

local function b_equip()
    b_item = ReplicatedStorage.BuildingParts[b_name]:Clone()
    for _, v in ipairs(b_item:GetDescendants()) do
        if v:IsA("BasePart") then v.Transparency = 0.5 v.CanCollide = false v.CanQuery = false v.Anchored = true end
    end
    b_item.Parent = workspace
    Mouse.TargetFilter = b_item
    
    table.insert(b_conns, UIS.InputChanged:Connect(function(io) if io.UserInputType == Enum.UserInputType.MouseMovement then b_updateCF() end end))
    table.insert(b_conns, UIS.InputBegan:Connect(function(io, gpe)
        if gpe then return end
        if io.KeyCode == Enum.KeyCode.R then b_rot = b_rot * CFrame.Angles(0, math.rad(90), 0) b_updateCF(true)
        elseif io.KeyCode == Enum.KeyCode.T then b_rot = b_rot * CFrame.Angles(math.rad(90), 0, 0) b_updateCF(true)
        elseif io.UserInputType == Enum.UserInputType.MouseButton1 then b_place() end
    end))
    updateBuildGui()
end

local function s_updateInfo()
    if not s_box or not s_box.Adornee then return end
    local p = s_box.Adornee.Parent
    local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
    local sum = 0
    for _, group in ipairs(workspace.Blocks:GetChildren()) do
        for _, block in ipairs(group:GetChildren()) do
            if block.Name == p.Name and block.PrimaryPart and isPartInZone(block.PrimaryPart, zone) then
                sum = sum + getBlockValue(block)
            end
        end
    end
    local gui = LocalPlayer.PlayerGui:FindFirstChild("ScaleToolDisplayGui")
    if gui then
        gui.BlockImage.AmountText.Text = tostring(math.floor(LocalPlayer.Data[p.Name].Value - sum))
        gui.BlockImage.SizeDisplay.Text = string.format("%.2f,%.2f,%.2f", s_box.Adornee.Size.X, s_box.Adornee.Size.Y, s_box.Adornee.Size.Z)
    end
end

local function s_equip()
    s_box = Instance.new("SelectionBox")
    s_box.Color3, s_box.SurfaceColor3, s_box.SurfaceTransparency = Color3.fromRGB(172,109,0), Color3.fromRGB(172,172,0), 0.5
    s_box.Parent = workspace
    
    table.insert(s_conns, UIS.InputChanged:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseMovement and not s_camLocked then
            local t = Mouse.Target
            local valid, info = false, nil
            if t and t.Parent then valid, info = GetBlockInfo(t, LocalPlayer) end
            s_box.Adornee = (valid and string.find(info.Name, "Block")) and info.PrimaryPart or nil
            if s_box.Adornee then s_updateInfo() end
        end
    end))
    
    table.insert(s_conns, UIS.InputBegan:Connect(function(io, gpe)
        if gpe or not s_box.Adornee or io.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        s_camLocked = true
        local part = s_box.Adornee
        local origCF, origSz = part.CFrame, part.Size
        local tool = LocalPlayer.Character:FindFirstChild("ScalingTool") or LocalPlayer.Backpack:FindFirstChild("ScalingTool")
        
        if not s_handles then
            s_handles = Instance.new("Handles", LocalPlayer.PlayerGui)
            s_handles.Style, s_handles.Color3 = Enum.HandlesStyle.Resize, Color3.fromRGB(172,78,1)
            s_handles.Adornee = part
            
            s_handles.MouseDrag:Connect(function(face, delta)
                local snap = tonumber(LocalPlayer.PlayerGui.ScaleToolDisplayGui.BlockImage.More.Scale.TextBox.Text) or 1
                if snap ~= 0 then delta = delta - delta % snap end
                
                local ns = origSz
                if face == Enum.NormalId.Right or face == Enum.NormalId.Left then ns = origSz + Vector3.new(delta,0,0)
                elseif face == Enum.NormalId.Top or face == Enum.NormalId.Bottom then ns = origSz + Vector3.new(0,delta,0)
                else ns = origSz + Vector3.new(0,0,delta) end
                
                ns = Vector3.new(math.max(ns.X, 0.05), math.max(ns.Y, 0.05), math.max(ns.Z, 0.05))
                
                if not _G.DisableToolLimit then
                    local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                    if not isPartInZone(part.CFrame, zone) then return end
                end
                
                part.Size = ns
                s_updateInfo()
            end)
            
            s_handles.MouseButton1Up:Connect(function()
                s_camLocked = false
                if s_handles then s_handles:Destroy() s_handles = nil end
                if tool then tool.RF:InvokeServer(part.Parent, part.Size, part.CFrame) end
                s_updateInfo()
            end)
        end
    end))
end

local function t_getBB(list, baseCF)
    local minX, minY, minZ = 1/0, 1/0, 1/0
    local maxX, maxY, maxZ = -1/0, -1/0, -1/0
    for _, model in ipairs(list) do
        if model.PrimaryPart then
            local rel = baseCF:toObjectSpace(model.PrimaryPart.CFrame)
            local s = model.PrimaryPart.Size
            minX = math.min(minX, rel.X - s.X/2) maxX = math.max(maxX, rel.X + s.X/2)
            minY = math.min(minY, rel.Y - s.Y/2) maxY = math.max(maxY, rel.Y + s.Y/2)
            minZ = math.min(minZ, rel.Z - s.Z/2) maxZ = math.max(maxZ, rel.Z + s.Z/2)
        end
    end
    local sz = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ)
    return baseCF * CFrame.new((maxX+minX)/2, (maxY+minY)/2, (maxZ+minZ)/2), sz
end

local function t_updateBB()
    local list = {}
    for k in pairs(t_sel) do table.insert(list, k) end
    if #list < 1 then
        if t_box then t_box:Destroy() t_box = nil end
        if t_move then t_move:Destroy() t_move = nil end
        if t_rot then t_rot:Destroy() t_rot = nil end
        return
    end
    if not t_box then
        t_box = Instance.new("Part", workspace)
        t_box.Name, t_box.Anchored, t_box.CanCollide, t_box.Transparency = "TrowelBB", true, false, 1
        local sb = Instance.new("SelectionBox", t_box)
        sb.Adornee, sb.LineThickness = t_box, 0.02
    end
    local prim = list[#list].PrimaryPart
    local cf, sz = t_getBB(list, prim.CFrame - prim.Position)
    t_box.Size, t_box.CFrame = sz, cf
    
    local mode = LocalPlayer.PlayerGui.TrowelToolDisplayGui.Mode.Value
    if mode == "Move" or mode == "Clone" or mode == "Mirror" then
        if t_rot then t_rot:Destroy() t_rot = nil end
        if not t_move then
            t_move = Instance.new("Handles", LocalPlayer.PlayerGui)
            t_move.Adornee = t_box
            t_move.MouseDrag:Connect(function(face, delta)
                local snap = tonumber(LocalPlayer.PlayerGui.TrowelToolDisplayGui.ModeImage.More.Scale.TextBox.Text) or 1
                if snap ~= 0 then delta = delta - delta % snap end
                local dir = Vector3.FromNormalId(face)
                t_box.CFrame = cf * CFrame.new(dir * delta)
            end)
            t_move.MouseButton1Up:Connect(function()
                local tool = LocalPlayer.Character:FindFirstChild("TrowelTool") or LocalPlayer.Backpack:FindFirstChild("TrowelTool")
                if tool then tool.OperationRF:InvokeServer(list, cf, t_box.CFrame, mode) end
                t_updateBB()
            end)
        end
    elseif mode == "Rotate" then
        if t_move then t_move:Destroy() t_move = nil end
        if not t_rot then
            t_rot = Instance.new("ArcHandles", LocalPlayer.PlayerGui)
            t_rot.Adornee = t_box
            t_rot.MouseDrag:Connect(function(axis, angle)
                t_box.CFrame = cf * CFrame.fromAxisAngle(Vector3.FromAxis(axis), angle)
            end)
            t_rot.MouseButton1Up:Connect(function()
                local tool = LocalPlayer.Character:FindFirstChild("TrowelTool") or LocalPlayer.Backpack:FindFirstChild("TrowelTool")
                if tool then tool.OperationRF:InvokeServer(list, cf, t_box.CFrame, mode) end
                t_updateBB()
            end)
        end
    end
end

local function t_equip()
    table.insert(t_conns, UIS.InputBegan:Connect(function(io, gpe)
        if gpe then return end
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            t_down, t_startPos = true, Vector2.new(Mouse.X, Mouse.Y)
            local t = Mouse.Target
            local valid, info = false, nil
            if t and t.Parent then valid, info = GetBlockInfo(t, LocalPlayer) end
            if valid and info then
                if t_sel[info] then t_sel[info]:Destroy() t_sel[info] = nil else
                    local sb = Instance.new("SelectionBox", info)
                    sb.Adornee, sb.Color3 = info, Color3.fromRGB(0,126,158)
                    t_sel[info] = sb
                end
                t_updateBB()
            end
        end
    end))
    table.insert(t_conns, UIS.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then t_down = false end
    end))
end

local function masterLoop()
    while true do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local bTool = LocalPlayer.Backpack:FindFirstChild("BuildingTool") or char:FindFirstChild("BuildingTool")
            local sTool = LocalPlayer.Backpack:FindFirstChild("ScalingTool") or char:FindFirstChild("ScalingTool")
            local tTool = LocalPlayer.Backpack:FindFirstChild("TrowelTool") or char:FindFirstChild("TrowelTool")
            
            if bTool and bTool:FindFirstChild("LocalScript") then bTool.LocalScript.Disabled = true end
            if sTool and sTool:FindFirstChild("ScaleLocalScript") then sTool.ScaleLocalScript.Disabled = true end
            if tTool and tTool:FindFirstChild("TrowelLocalScript") then tTool.TrowelLocalScript.Disabled = true end
            
            if bTool and #b_conns == 0 and bTool.Parent == char then b_equip() end
            if sTool and #s_conns == 0 and sTool.Parent == char then s_equip() end
            if tTool and #t_conns == 0 and tTool.Parent == char then t_equip() end
            
            if bTool and bTool.Parent == LocalPlayer.Backpack and #b_conns > 0 then cleanConns(b_conns) if b_item then b_item:Destroy() b_item = nil end end
            if sTool and sTool.Parent == LocalPlayer.Backpack and #s_conns > 0 then cleanConns(s_conns) if s_box then s_box:Destroy() s_box = nil end end
            if tTool and tTool.Parent == LocalPlayer.Backpack and #t_conns > 0 then cleanConns(t_conns) t_updateBB() end
        end
        task.wait(0.5)
    end
end

task.spawn(masterLoop)
dprint("Death-resistant tool engine activated.")

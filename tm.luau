local debugp = true
_G.DisableToolLimit = _G.DisableToolLimit or false
_G.FullPlace = _G.FullPlace or false

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local function dprint(...)
    if debugp then
        print("[ToolBypass Debug]:", ...)
    end
end

local function normalIdToNormalVector(p1, p2)
    if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
    if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
    if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
    if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
    if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
    return Vector3.new(-1, 0, 0), p2.Size.X
end

local function roundVectorToBase(p1, p2)
    local v1 = 1 / p2
    local v2 = p1 * v1 + Vector3.new(0.5, 0.5, 0.5)
    return Vector3.new(math.floor(v2.X), math.floor(v2.Y), (math.floor(v2.Z))) / v1
end

local function GetBoundingBox(p1, p2)
    local abs = math.abs
    local v1 = (1 / 0)
    local v2 = (-1 / 0)
    local v3 = (-1 / 0)
    local v4 = (-1 / 0)
    local v5 = (1 / 0)
    local v6 = (1 / 0)
    for i = 1, #p1 do
        local PrimaryPart = p1[i].PrimaryPart
        if PrimaryPart then
            local v7 = p2:toObjectSpace(PrimaryPart.CFrame)
            local Size = PrimaryPart.Size
            local X = Size.X
            local Y = Size.Y
            local Z = Size.Z
            local v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19 = v7:components()
            local v20 = 0.5 * (abs(v11) * X + abs(v12) * Y + abs(v13) * Z)
            local v21 = 0.5 * (abs(v14) * X + abs(v15) * Y + abs(v16) * Z)
            local v22 = 0.5 * (abs(v17) * X + abs(v18) * Y + abs(v19) * Z)
            if v8 - v20 < v5 then v5 = v8 - v20 end
            if v9 - v21 < v6 then v6 = v9 - v21 end
            if v10 - v22 < v1 then v1 = v10 - v22 end
            if v2 < v8 + v20 then v2 = v8 + v20 end
            if v3 < v9 + v21 then v3 = v9 + v21 end
            if v4 < v10 + v22 then v4 = v10 + v22 end
        end
    end
    local v23 = Vector3.new(v5, v6, v1)
    local v24 = Vector3.new(v2, v3, v4)
    return p2 - p2.p + p2:pointToWorldSpace((v24 + v23) / 2), v24 - v23
end

local function hookBuildTool(tool)
    dprint("Hooking BuildTool:", tool:GetFullName())
    local localScript = tool:FindFirstChildOfClass("LocalScript")
    if localScript then localScript.Disabled = true end

    local v1 = LocalPlayer:GetMouse()
    local CurrentCamera = workspace.CurrentCamera
    local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
    local v3, v4, v5, v6, v7, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26
    local v8 = CFrame.new()

    local function changeTransparency(p1, p2)
        local v1 = p1:GetDescendants()
        for i = 1, #v1 do
            if v1[i]:IsA("BasePart") then
                if CollectionService:HasTag(v1[i], "NoTransparency") then
                    v1[i].Transparency = 0
                    continue
                end
                if CollectionService:HasTag(v1[i], "FullTransparency") then
                    v1[i].Transparency = 1
                    continue
                end
                v1[i].Transparency = p2
            end
        end
    end

    local function WeldTogether(p1, p2, p3, p4)
        if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then return end
        local v1 = Instance.new(p3 or "Weld")
        v1.Part0 = p1
        v1.Part1 = p2
        v1.C0 = CFrame.new()
        v1.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
        v1.Parent = p4 or p1
        return v1
    end

    local function prepareItem()
        v1.TargetFilter = v3
        changeTransparency(v3, 0.5)
        local v12 = v3:GetDescendants()
        for i = 1, #v12 do
            if v12[i]:IsA("BasePart") then
                v12[i].Anchored = true
                v12[i].CanCollide = false
                v12[i].CanQuery = false
                if v12[i] ~= v3.PrimaryPart then
                    WeldTogether(v3.PrimaryPart, v12[i])
                end
            end
        end
    end

    local function isSpeedBuild()
        local SpeedBuild = LocalPlayer.OtherData:FindFirstChild("SpeedBuild")
        if SpeedBuild and SpeedBuild.Value then return true end
        return nil
    end

    local function getType(p1)
        local v1 = string.match(p1.TypeIcon.Image, "%d+")
        if v1 == "4597411234" then return "Block" end
        if v1 == "4597402658" then return "Decoration" end
        return "Special"
    end

    local function fitBuildScroll()
        local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
        local v1 = ScrollingFrame.BlocksFrame:GetChildren()
        local v2, v3 = nil, nil
        for i = 1, #v1 do
            if v1[i]:IsA("GuiObject") and v1[i].Visible then
                if not v2 or v2 < v1[i].AbsolutePosition.Y then v2 = v1[i].AbsolutePosition.Y end
                if not v3 or v1[i].AbsolutePosition.Y < v3 then v3 = v1[i].AbsolutePosition.Y end
            end
        end
        if v3 and v2 then
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, v2 - v3 + 100)
            return
        end
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end

    local function setSpeedBuildGuiLook()
        local SpeedBuildToggle = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle
        if isSpeedBuild() then
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565249"
        else
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565059"
        end
    end

    local function updateBuildGui()
        local v1 = LocalPlayer
        local v2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2 and LocalPlayer.Settings.ShareBlocks.Value then v1 = v2 end
        local v3 = v1.Name
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        local SearchFrame = BuildGui.SearchFrame
        local v4 = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
        local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v5 = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()
        for i = 1, #v5 do
            local v6 = v5[i]
            if ReplicatedStorage.BuildingParts:FindFirstChild(v6.Name) then
                local v8 = getType(v6)
                local v9 = game.Players:FindFirstChild(v3).Data[v6.Name].Value
                local v10 = string.split(v6.Tags.Value, " ")
                local v11 = false
                if SearchFrame.OnlySearch.Value then
                    local ok, result = pcall(function()
                        return game:GetService("LocalizationService"):GetTranslatorForPlayerAsync(game.Players.LocalPlayer)
                    end)
                    if ok then
                        local v13 = string.lower((result:Translate(TagsFrame.Parent.BlockName, v6.BlockName.Value)))
                        if string.find(v13, v4) or string.find(v4, v13) then v11 = true end
                        if not v11 then
                            for j = 1, #v10 do
                                local v15 = string.lower((result:Translate(TagsFrame, v10[j])))
                                if string.find(v15, v4) or string.find(v4, v15) then
                                    v11 = true
                                    break
                                end
                            end
                        end
                    end
                end
                if v9 == 0 or SearchFrame.OnlyBlocks.Value and v8 ~= "Block" or (SearchFrame.OnlyDecorations.Value and v8 ~= "Decoration" or SearchFrame.OnlySpecial.Value and v8 ~= "Special") then
                    v6.Visible = false
                else
                    if SearchFrame.OnlySearch.Value and not v11 then
                        v6.Visible = false
                        continue
                    end
                    v6.Visible = true
                end
            end
        end
        fitBuildScroll()
        setSpeedBuildGuiLook()
    end

    local function resetRotation()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v8 = CFrame.new()
        else
            local v1 = workspace
            local v2 = v1[tostring(LocalPlayer.TeamColor) .. "Zone"]
            v8 = (v2.CFrame - v2.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
        end
    end

    local function isPartInZone(p1, p2)
        local Position = p1.Position
        local Position2 = p2.Position
        local Size = p2.Size
        local X, Y, Z = Size.X, Size.Y, Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return Position.X > Position2.X - X / 2 and (Position.X < Position2.X + X / 2 and (Position.Z > Position2.Z - Z / 2 and Position.Z < Position2.Z + Z / 2))
    end

    local function canPlace(p1)
        if _G.DisableToolLimit then return true, "" end
        local v2 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v32 = isPartInZone(p1.PrimaryPart, v2)
        local v4 = if v32 then nil else "Out of bounds"
        local v5, v6 = QuestConditions(v2, p1.PrimaryPart.CFrame, v3.Name, 1, LocalPlayer)
        local v7, v8 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
        local v9, v10 = ChallengeConditions.itemRestriction(LocalPlayer, v3.Name)
        return if v32 then if v5 then not v7 and not v9 else v5 else v32, if v4 then v4 elseif v6 then v6 elseif v8 then v8 else v10
    end

    local function updateBlockCF(p1)
        if not v1.Target then return end
        local v12 = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
        if not p1 then
            v5 = v1.Target
            v6 = v1.Hit
            v7 = v1.TargetSurface
        end
        local v2 = v8
        local v32 = (v5.CFrame - v5.Position):Inverse()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v32 = CFrame.new(0, 0, 0)
        end
        local v52, v62 = normalIdToNormalVector(v7, v5)
        local v82 = v5.CFrame * CFrame.new(v52 * (v62 / 2))
        v12:SetPrimaryPartCFrame(v82 * v32 * v2)
        local v9 = (v5.CFrame - v5.Position):PointToWorldSpace(v52)
        local v10 = v12.PrimaryPart.CFrame.RightVector:Dot(v9)
        local v112 = v12.PrimaryPart.CFrame.UpVector:Dot(v9)
        local v122 = v12.PrimaryPart.CFrame.LookVector:Dot(v9)
        local v13 = math.abs(v10)
        local v14 = math.abs(v112)
        local v15 = math.abs(v122)
        v12:SetPrimaryPartCFrame(v82 * v32:Inverse() * v2:Inverse())
        local v17 = v82 * CFrame.new(v52 * (v13 * (v12.PrimaryPart.Size.X / 2) + v14 * (v12.PrimaryPart.Size.Y / 2) + v15 * (v12.PrimaryPart.Size.Z / 2)))
        local v18 = v5.CFrame:PointToObjectSpace(v6.p)
        local v19 = if v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom then v18 - Vector3.new(0, v18.Y, 0) elseif v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back then v18 - Vector3.new(0, 0, v18.Z) else v18 - Vector3.new(v18.X, 0, 0)
        local v20 = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
        if v20 ~= 0 then v19 = roundVectorToBase(v19, v20) end
        v12:SetPrimaryPartCFrame(v17 * CFrame.new(v19) * v32 * v2)
        if not v3:FindFirstChild("CanPlace") then
            local CanPlace = Instance.new("BoolValue")
            CanPlace.Name = "CanPlace"
            CanPlace.Value = true
            CanPlace.Parent = v3
        end
        local v22 = canPlace(v12)
        if v3.CanPlace.Value or not v22 then
            if not v3.CanPlace.Value or v22 then return end
            v3.CanPlace.Value = false
            v11 = {}
            local v23 = v3:GetDescendants()
            for i = 1, #v23 do
                if v23[i]:IsA("BasePart") then
                    table.insert(v11, v23[i].Color)
                    v23[i].BrickColor = BrickColor.Red()
                end
            end
        else
            v3.CanPlace.Value = true
            local v25 = v3:GetDescendants()
            local count = 1
            for j = 1, #v25 do
                if v25[j]:IsA("BasePart") then
                    v25[j].Color = v11[count]
                    count = count + 1
                end
            end
            if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
        end
    end

    local function itemChanged()
        local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
        local v12 = ReplicatedStorage.BuildingParts:FindFirstChild(Selected)
        updateBuildGui()
        local v22 = v3.PrimaryPart.CFrame
        v3:Destroy()
        v3 = v12:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(v22.p) * v12.PrimaryPart.CFrame.Rotation)
        resetRotation()
        prepareItem()
        updateBlockCF()
        v3.Parent = workspace
        local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v32 = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
        local v42 = TagsFrame:GetChildren()
        local TextLabel = TagsFrame.TextLabel
        for i = 1, #v32 do
            local v52 = TextLabel:Clone()
            v52.Text = string.lower(v32[i])
            v52.Parent = TextLabel.Parent
        end
        for j = 1, #v42 do v42[j]:Destroy() end
        TagsFrame.Parent.BlockName.Text = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].BlockName.Value
        TagsFrame.Parent.StrengthFrame.TextLabel.Text = tostring(ReplicatedStorage.BuildingParts[Selected].Health.Value)
    end

    local function rotateY()
        v8 = v8 * CFrame.Angles(0, math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0)
        updateBlockCF(true)
    end

    local function rotateX()
        v8 = v8 * CFrame.Angles(math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0, 0)
        updateBlockCF(true)
    end

    local function toggleSpeedBuild()
        if v26 then return end
        v26 = true
        task.spawn(function() task.wait(0.2) v26 = false end)
        local SpeedBuildToggle = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle
        if string.match(SpeedBuildToggle.Image, "%d+") == "4603565059" then
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565249"
            workspace.UpdateSpeedBuildStats:FireServer(true)
        else
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565059"
            workspace.UpdateSpeedBuildStats:FireServer(false)
        end
    end

    local function placeBlock(p1)
        if v25 or not v3 then return end
        if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
        local v22, v32 = canPlace(v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3)
        if not v22 then
            local OutOfBoundsBG = Instance.new("BillboardGui")
            OutOfBoundsBG.Name = "OutOfBoundsBG"
            OutOfBoundsBG.AlwaysOnTop = true
            OutOfBoundsBG.Adornee = v3
            OutOfBoundsBG.MaxDistance = 1000
            OutOfBoundsBG.Size = UDim2.new(8, 0, 2, 0)
            OutOfBoundsBG.StudsOffset = Vector3.new(0, 3, 0)
            OutOfBoundsBG.ClipsDescendants = false
            OutOfBoundsBG.ZIndexBehavior = Enum.ZIndexBehavior.Global
            OutOfBoundsBG.LightInfluence = 0
            local TextLabel = Instance.new("TextLabel")
            TextLabel.BackgroundTransparency = 1
            TextLabel.Size = UDim2.new(1, 0, 1, 0)
            TextLabel.Font = Enum.Font.Arcade
            TextLabel.Text = v32
            TextLabel.TextColor3 = Color3.fromRGB(255, 106, 106)
            TextLabel.TextScaled = true
            TextLabel.TextWrapped = true
            TextLabel.TextStrokeTransparency = 0
            TextLabel.TextStrokeColor3 = Color3.fromRGB(91, 32, 32)
            TextLabel.Parent = OutOfBoundsBG
            OutOfBoundsBG.Parent = v3
            Debris:AddItem(OutOfBoundsBG, 1.5)
            return
        end

        v25 = true
        task.spawn(function() task.wait() v25 = false end)

        local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
        local AmountText = v52.AmountText
        local MaxText = v52.MaxText
        local actualCount = tonumber(AmountText.Text) or 0

        if actualCount <= 0 and not _G.DisableToolLimit then
            local v62 = tool:WaitForChild("ClickSound"):Clone()
            v62.Parent = v3.PrimaryPart
            Debris:AddItem(v62, 0.3)
            v62.PlaybackSpeed = 5
            v62:Play()
            LocalPlayer.PlayerGui.BuildGui.SearchFrame.ClearFilter:Invoke()
            local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
            ScrollingFrame.CanvasPosition = ScrollingFrame.CanvasPosition + Vector2.new(0, v52.AbsolutePosition.Y - 252 + (251 - LocalPlayer.PlayerGui.BuildGui.InventoryFrame.AbsolutePosition.Y))
            if not MaxText.Visible then
                AmountText.Visible = false
                MaxText.Visible = true
                task.wait(0.5)
                AmountText.Visible = true
                MaxText.Visible = false
            end
        else
            local v92 = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"
            if v92 then
                local v102 = v3:FindFirstChild("2ndPlacement")
                if not v102 then
                    local v112 = Instance.new("BoolValue")
                    v112.Name = "2ndPlacement"
                    v112.Parent = v3
                    updateBlockCF()
                    return
                end
                v102:Destroy()
            end
            local v122 = if v92 then v3.SecondaryPart.PrimaryPart.CFrame else v92
            
            local function playSound()
                local v152 = tool:WaitForChild("ClickSound"):Clone()
                v152.Parent = v3.PrimaryPart
                Debris:AddItem(v152, 1)
                v152.PlaybackSpeed = 1
                v152:Play()
            end
            
            playSound()
            changeTransparency(v3, 0)
            Debris:AddItem(v3, 10)
            local v132 = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
            local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
            if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
                resetRotation()
            end
            local v162 = v3
            v3 = v3:Clone()
            changeTransparency(v3, 0.5)
            v3.Parent = workspace
            v1.TargetFilter = v3
            local v172 = v162:GetDescendants()
            for i = 1, #v172 do
                if v172[i]:IsA("BasePart") then v172[i].CanQuery = true end
            end
            local v192 = v5

            local function fireServerPlacement()
                local dataVal = LocalPlayer.Data:FindFirstChild(v162.Name) and LocalPlayer.Data:FindFirstChild(v162.Name).Value or 1
                tool:WaitForChild("RF"):InvokeServer(v162.Name, dataVal, v192, v132, Anchor, v162.PrimaryPart.CFrame, v122)
            end

            fireServerPlacement()

            if _G.FullPlace then
                local loops = math.max(1, actualCount - 1)
                if _G.DisableToolLimit and loops < 1 then loops = 100 end
                task.spawn(function()
                    for i = 1, loops do
                        if not _G.FullPlace then break end
                        fireServerPlacement()
                        task.wait(0.2)
                    end
                end)
            end

            v162:Destroy()
            updateBlockCF(p1)
            updateBuildGui()
        end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement or p1.KeyCode == Enum.KeyCode.Thumbstick1 or p1.KeyCode == Enum.KeyCode.Thumbstick2 then
            updateBlockCF()
        end
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.Keyboard then
            if p1.KeyCode == Enum.KeyCode.R then rotateY() return end
            if p1.KeyCode == Enum.KeyCode.T then rotateX() end
        else
            if p1.UserInputType == Enum.UserInputType.MouseButton1 then placeBlock() return end
            if p1.UserInputType == Enum.UserInputType.Touch then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                if isSpeedBuild() then v10 = v1.Hit else updateBlockCF() end
                return
            end
            if p1.UserInputType == Enum.UserInputType.Gamepad1 then
                if p1.KeyCode == Enum.KeyCode.ButtonR2 then placeBlock() return end
                if p1.KeyCode == Enum.KeyCode.ButtonX then rotateY() return end
                if p1.KeyCode == Enum.KeyCode.ButtonY then rotateX() end
            end
        end
    end

    local function inputEnded(p1, p2)
        if p2 or (p1.UserInputType ~= Enum.UserInputType.Touch or not (isSpeedBuild() and (v1.Hit.p - v10.p).Magnitude < 1)) then return end
        updateBlockCF()
        placeBlock(true)
    end

    local function eq()
        if LocalPlayer.Character.Humanoid.Health <= 0 then return end
        v3 = ReplicatedStorage.BuildingParts.WoodBlock:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(-50, -12, -720))
        itemChanged(v4 or "WoodBlock")
        v12 = UserInputService.InputChanged:Connect(inputChanged)
        v13 = UserInputService.InputBegan:Connect(inputBegan)
        v14 = UserInputService.InputEnded:Connect(inputEnded)
        v16 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.MouseButton1Click:Connect(rotateY)
        v17 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.MouseButton1Click:Connect(rotateX)
        v15 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Place.MouseButton1Click:Connect(function()
            if v9 == v3.PrimaryPart.CFrame and not (if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope") then return end
            v9 = v3.PrimaryPart.CFrame
            placeBlock(true)
        end)
        v18 = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.MouseButton1Click:Connect(toggleSpeedBuild)
        v19 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected:GetPropertyChangedSignal("Value"):Connect(itemChanged)
        v20 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyBlocks:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v21 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyDecorations:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v22 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySpecial:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v23 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySearch:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v24 = LocalPlayer.Character.Humanoid.Died:Connect(function()
            if v12 then v12:Disconnect() end
            if v13 then v13:Disconnect() end
            if v14 then v14:Disconnect() end
            if v15 then v15:Disconnect() end
            if v16 then v16:Disconnect() end
            if v17 then v17:Disconnect() end
            if v18 then v18:Disconnect() end
            if v19 then v19:Disconnect() end
            if v20 then v20:Disconnect() end
            if v21 then v21:Disconnect() end
            if v22 then v22:Disconnect() end
            if v23 then v23:Disconnect() end
            if v24 then v24:Disconnect() end
        end)
        updateBuildGui()
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        BuildGui.InventoryFrame.Visible = true
        BuildGui.ScaleButton.Visible = true
        BuildGui.SearchFrame.Visible = true
        if workspace.Challenge.Teams:FindFirstChild(LocalPlayer.Team.Name) then
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        else
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(132, 132, 132)
        end
    end

    local function uneq()
        v4 = v3.Name
        if v3 then v3:Destroy() end
        if v12 then v12:Disconnect() v12 = nil end
        if v13 then v13:Disconnect() v13 = nil end
        if v14 then v14:Disconnect() v14 = nil end
        if v15 then v15:Disconnect() v15 = nil end
        if v16 then v16:Disconnect() v16 = nil end
        if v17 then v17:Disconnect() v17 = nil end
        if v18 then v18:Disconnect() v18 = nil end
        if v19 then v19:Disconnect() v19 = nil end
        if v20 then v20:Disconnect() v20 = nil end
        if v21 then v21:Disconnect() v21 = nil end
        if v22 then v22:Disconnect() v22 = nil end
        if v23 then v23:Disconnect() v23 = nil end
        if v24 then v24:Disconnect() v24 = nil end
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        BuildGui.InventoryFrame.Visible = false
        BuildGui.Clear.Visible = false
        BuildGui.ScaleButton.Visible = false
        BuildGui.SearchFrame.Visible = false
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function hookScalingTool(tool)
    dprint("Hooking ScalingTool:", tool:GetFullName())
    local localScript = tool:FindFirstChildOfClass("LocalScript")
    if localScript then localScript.Disabled = true end

    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
    local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)
    local CurrentCamera = workspace.CurrentCamera
    local v1 = LocalPlayer:GetMouse()
    local v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14
    local v15 = 1
    local v16 = false
    local v17 = false

    local function lockCameraRotation()
        v17 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
        local v122 = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v22 = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v22 + CameraSubject.CFrame.p - v122
        end)
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v17 = false
    end

    local function checkToLockCameraRotation()
        if v17 then return end
        lockCameraRotation()
    end

    local function checkToUnlockCameraRotation()
        if not v17 then return end
        unlockCameraRotation()
    end

    local function isPartInZone(p1, p2)
        local v122 = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X, Y, Z = Size.X, Size.Y, Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v122.X > Position.X - X / 2 and (v122.X < Position.X + X / 2 and (v122.Z > Position.Z - Z / 2 and v122.Z < Position.Z + Z / 2))
    end

    local function roundToNearestThousands(p1)
        return math.floor(p1 * 1000 + 0.5) / 1000
    end

    local function canSelect(p1)
        if v16 then return false, p1 end
        local v122, _, v22 = GetBlockInfo(p1, LocalPlayer)
        if v22 and string.find(v122.Name, "Block") then return true, v122 end
        return false
    end

    local function updateBlocks()
        local v122 = LocalPlayer
        local v22 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v22 and LocalPlayer.Settings.ShareBlocks.Value then v122 = v22 end
        local v52 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v62 = v4.Adornee.Parent.Name
        v13 = game.Players:FindFirstChild(v122.Name).Data:FindFirstChild(v62).Value
        local v72 = workspace.Blocks:GetChildren()
        local sum = 0
        for i = 1, #v72 do
            local v82 = v72[i]:GetChildren()
            for j = 1, #v82 do
                local v92 = v82[j]
                local _, _2, v102 = GetBlockInfo(v92, LocalPlayer)
                if v102 and (v92.Name == v62 and (v92.PrimaryPart and isPartInZone(v92.PrimaryPart, v52))) then
                    sum = sum + math.max(v92.PrimaryPart.Size.X * v92.PrimaryPart.Size.Y * v92.PrimaryPart.Size.Z / v15, 1)
                end
            end
        end
        v14 = sum
        v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
        v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(v62).Image
        v12.Parent = LocalPlayer.PlayerGui
    end

    local function updateBlocksSoft(p1, p2)
        local v122 = LocalPlayer
        local v22 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v22 and LocalPlayer.Settings.ShareBlocks.Value then v122 = v22 end
        v13 = game.Players:FindFirstChild(v122.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
        v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)
        local v72 = math.floor(v13 - v14)
        v12.BlockImage.AmountText.Text = tostring(v72)
        return v72
    end

    local function mouseMove(p1)
        local Target = v1.Target
        if not (Target and Target.Parent) then v2.Adornee = nil return end
        local v122, v22 = canSelect(Target)
        if v4 and (v2.Adornee and v4.Adornee == v2.Adornee.PrimaryPart) then v2.Adornee = nil end
        if v4 and (v22 and (v22:IsA("Model") and v4.Adornee == v22.PrimaryPart)) then v2.Adornee = nil return end
        if v2.Adornee == v22 then return end
        if v122 then
            v2.Adornee = v22
            local Size = v22.PrimaryPart.Size
            v2.LineThickness = math.min(Size.X, Size.Y, Size.Z, 2) / 13.334
            if p1 then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = false
            end
        else
            v2.Adornee = nil
            if not p1 then return end
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        end
    end

    local function active(p1)
        if not v2 then return end
        local Adornee = v2.Adornee
        if Adornee == nil then return end
        local v122, v22 = canSelect(Adornee)
        if v122 then
            local Size = v22.PrimaryPart.Size
            local Size2 = ReplicatedStorage.BuildingParts:FindFirstChild(v22.Name).PrimaryPart.Size
            v15 = Size2.X * Size2.Y * Size2.Z
            if v4 then v4.Adornee = v22.PrimaryPart else
                v4 = Instance.new("Handles")
                v4.Adornee = v22.PrimaryPart
                v4.Style = Enum.HandlesStyle.Resize
                v4.Color3 = Color3.fromRGB(172, 78, 1)
                v4.Parent = LocalPlayer.PlayerGui
            end
            local v32, v42, v52, v62 = nil, nil, nil, nil
            if v7 then v7:Disconnect() v7 = nil end
            v7 = v4.MouseButton1Down:Connect(function()
                v16 = true
                v32 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                v4.Adornee:BreakJoints()
                v4.Adornee.Anchored = true
                if not p1 then return end
                checkToLockCameraRotation()
            end)
            local SizeDisplay = v12.BlockImage.SizeDisplay
            SizeDisplay.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
            if v8 then v8:Disconnect() v8 = nil end
            v8 = v4.MouseDrag:Connect(function(p12, p2)
                local v132 = tonumber(v12.BlockImage.More.Scale.TextBox.Text)
                if v132 ~= 0 then p2 = p2 - p2 % v132 end
                if p12 == Enum.NormalId.Right then
                    if v52.X + p2 <= 0.05 then
                        local v23 = v52.X % v132
                        if v132 == 0 then v23 = 0.05 end
                        if v23 < 0.05 then v23 = v132 end
                        v62 = Vector3.new(v23, v52.Y, v52.Z)
                        v42 = v32 * CFrame.new(-(v52.X - v62.X) / 2, 0, 0)
                    else
                        v42 = v32 * CFrame.new(p2 / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2, 0, 0)
                    end
                elseif p12 == Enum.NormalId.Left then
                    if v52.X + p2 <= 0.05 then
                        local v43 = v52.X % v132
                        if v132 == 0 then v43 = 0.05 end
                        if v43 <= 0.05 then v43 = v132 end
                        v62 = Vector3.new(v43, v52.Y, v52.Z)
                        v42 = v32 * CFrame.new(-(-(v52.X - v62.X)) / 2, 0, 0)
                    else
                        v42 = v32 * CFrame.new(-p2 / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2, 0, 0)
                    end
                elseif p12 == Enum.NormalId.Top then
                    if v52.Y + p2 <= 0.05 then
                        local v63 = v52.Y % v132
                        if v132 == 0 then v63 = 0.05 end
                        if v63 <= 0.05 then v63 = v132 end
                        v62 = Vector3.new(v52.X, v63, v52.Z)
                        v42 = v32 * CFrame.new(0, -(v52.Y - v62.Y) / 2, 0)
                    else
                        v42 = v32 * CFrame.new(0, p2 / 2, 0)
                        v62 = v52 + Vector3.new(0, p2, 0)
                    end
                elseif p12 == Enum.NormalId.Bottom then
                    if v52.Y + p2 <= 0.05 then
                        local v83 = v52.Y % v132
                        if v132 == 0 then v83 = 0.05 end
                        if v83 <= 0.05 then v83 = v132 end
                        v62 = Vector3.new(v52.X, v83, v52.Z)
                        v42 = v32 * CFrame.new(0, -(-(v52.Y - v62.Y)) / 2, 0)
                    else
                        v42 = v32 * CFrame.new(0, -p2 / 2, 0)
                        v62 = v52 + Vector3.new(0, p2, 0)
                    end
                elseif p12 == Enum.NormalId.Back then
                    if v52.Z + p2 <= 0.05 then
                        local v103 = v52.Z % v132
                        if v132 == 0 then v103 = 0.05 end
                        if v103 <= 0.05 then v103 = v132 end
                        v62 = Vector3.new(v52.X, v52.Y, v103)
                        v42 = v32 * CFrame.new(0, 0, -(v52.Z - v62.Z) / 2)
                    else
                        v42 = v32 * CFrame.new(0, 0, p2 / 2)
                        v62 = v52 + Vector3.new(0, 0, p2)
                    end
                elseif p12 == Enum.NormalId.Front then
                    if v52.Z + p2 <= 0.05 then
                        local v123 = v52.Z % v132
                        if v132 == 0 then v123 = 0.05 end
                        if v123 <= 0.05 then v123 = v132 end
                        v62 = Vector3.new(v52.X, v52.Y, v123)
                        v42 = v32 * CFrame.new(0, 0, -(-(v52.Z - v62.Z)) / 2)
                    else
                        v42 = v32 * CFrame.new(0, 0, -p2 / 2)
                        v62 = v52 + Vector3.new(0, 0, p2)
                    end
                end
                v62 = Vector3.new(math.max(v62.X, 0.05), math.max(v62.Y, 0.05), (math.max(v62.Z, 0.05)))
                local v172 = Size
                local v192 = v62.X * v62.Y * v62.Z / v15 - v172.X * v172.Y * v172.Z / v15
                local v212 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local v222 = _G.DisableToolLimit or (isPartInZone(v42 * CFrame.new(v62.X / 2, 0, 0), v212) and (isPartInZone(v42 * CFrame.new(-v62.X / 2, 0, 0), v212) and (isPartInZone(v42 * CFrame.new(0, v62.Y / 2, 0), v212) and (isPartInZone(v42 * CFrame.new(0, -v62.Y / 2, 0), v212) and (isPartInZone(v42 * CFrame.new(0, 0, v62.Z / 2), v212) and (isPartInZone(v42 * CFrame.new(0, 0, -v62.Z / 2), v212) and (QuestConditions(v212, v42 * CFrame.new(v62.X / 2, 0, 0), "", v192, LocalPlayer) and (QuestConditions(v212, v42 * CFrame.new(-v62.X / 2, 0, 0), "", v192, LocalPlayer) and (QuestConditions(v212, v42 * CFrame.new(0, v62.Y / 2, 0), "", v192, LocalPlayer) and (QuestConditions(v212, v42 * CFrame.new(0, -v62.Y / 2, 0), "", v192, LocalPlayer) and (QuestConditions(v212, v42 * CFrame.new(0, 0, v62.Z / 2), "", v192, LocalPlayer) and QuestConditions(v212, v42 * CFrame.new(0, 0, -v62.Z / 2), "", v192, LocalPlayer))))))))))))
                local v232 = updateBlocksSoft(v4.Adornee.Size, v62)
                local v24 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, v192)
                if _G.DisableToolLimit or (v232 >= 0 and (v222 and not v24)) then
                    if v4.Adornee.Size == v62 then return end
                    v4.Adornee:BreakJoints()
                    v4.Adornee.CFrame = v42 or v32
                    v4.Adornee.Size = v62 or v52
                    v12.BlockImage.SizeDisplay.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
                    return
                end
                updateBlocksSoft(v62, v4.Adornee.Size)
                local AmountText = v12.BlockImage.AmountText
                local MaxText = v12.BlockImage.MaxText
                local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                if v24 then RestrictionMetFrame.Visible = true else MaxText.Visible = true AmountText.Visible = false end
                local v322 = tool:WaitForChild("ClickSound"):Clone()
                v322.Parent = v4.Adornee
                Debris:AddItem(v322, 0.3)
                v322.PlaybackSpeed = 5
                v322:Play()
                if not v24 then
                    task.wait(0.5)
                    MaxText.Visible = false
                    AmountText.Visible = true
                    return
                end
                task.wait(3)
                RestrictionMetFrame.Visible = false
            end)
            if v6 then v6:Disconnect() v6 = nil end
            v6 = v4.MouseButton1Up:Connect(function()
                v32 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v123, v23 = tool:WaitForChild("RF"):InvokeServer(v4.Adornee.Parent, v52, v32)
                Size = v52
                if v123 then
                    v22.PrimaryPart.Size = v123
                    v22.PrimaryPart.CFrame = v23
                    updateBlocks()
                end
                v16 = false
                if not p1 then return end
                checkToUnlockCameraRotation()
            end)
            if v5 then v5:Disconnect() v5 = nil end
            v5 = tool.Unequipped:Connect(function()
                v32 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v123, v23 = tool:WaitForChild("RF"):InvokeServer(v4.Adornee.Parent, v52, v32)
                Size = v52
                if not v123 then
                    v16 = false
                    if v5 then v5:Disconnect() v5 = nil end
                    return
                end
                v22.PrimaryPart.Size = v123
                v22.PrimaryPart.CFrame = v23
                v16 = false
                if v5 then v5:Disconnect() v5 = nil end
            end)
            updateBlocks()
        end
        mouseMove()
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then active() return end
        if p1.UserInputType == Enum.UserInputType.Touch then mouseMove(true) return end
        if p1.UserInputType == Enum.UserInputType.Gamepad1 and p1.KeyCode == Enum.KeyCode.ButtonR2 then active() end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement or p1.KeyCode == Enum.KeyCode.Thumbstick1 or p1.KeyCode == Enum.KeyCode.Thumbstick2 then
            mouseMove(false)
        end
    end

    local function died()
        if v2 then v2:Destroy() v2 = nil end
        if v3 then v3:Disconnect() v3 = nil end
        if v11 then v11:Disconnect() v11 = nil end
        if v9 then v9:Disconnect() v9 = nil end
        if v10 then v10:Disconnect() v10 = nil end
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        if not v4 then v12.BlockImage.Visible = false checkToUnlockCameraRotation() return end
        if v4 then v4:Destroy() v4 = nil end
        v12.BlockImage.Visible = false
        checkToUnlockCameraRotation()
    end

    local function eq()
        v12 = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScaleToolDisplayGui")
        v12.BlockImage.SizeDisplay.Text = ""
        v3 = LocalPlayer.Character.Humanoid.Died:Connect(died)
        v9 = UserInputService.InputChanged:Connect(inputChanged)
        v10 = UserInputService.InputBegan:Connect(inputBegan)
        v11 = LocalPlayer.PlayerGui:WaitForChild("TabletToolGui"):WaitForChild("Frame"):WaitForChild("Place").MouseButton1Down:Connect(function()
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
            active(true)
        end)
        v2 = Instance.new("SelectionBox", workspace)
        v2.Color3 = Color3.fromRGB(172, 109, 0)
        v2.SurfaceColor3 = Color3.fromRGB(172, 172, 0)
        v2.SurfaceTransparency = 0.5
        v12.BlockImage.Visible = true
    end

    local function uneq()
        died()
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function hookTrowelTool(tool)
    dprint("Hooking TrowelTool:", tool:GetFullName())
    local localScript = tool:FindFirstChildOfClass("LocalScript")
    if localScript then localScript.Disabled = true end

    local GetBlockInfo = require(ReplicatedStorage.Scripts.Scripts:FindFirstChild("GetBlockInfo") or ReplicatedStorage.Scripts.GetBlockInfo)
    local CurrentCamera = workspace.CurrentCamera
    local v1 = LocalPlayer:GetMouse()
    local v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v24, v29
    local t = {}
    local t2 = {}
    local v14 = false
    local v15 = false
    local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
    local v16, v17, v18, v20, v19, v21, v22, v26, v29
    local v23 = false
    local v25 = false
    local v27 = false
    local v28 = false
    local v30 = 0

    local function isMobilePlayer()
        return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
    end

    local function doingShiftSelect()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()
    end

    local function getSelectedModels()
        local t22 = {}
        for k, v in pairs(t) do table.insert(t22, k) end
        return t22
    end

    local function getBlockValue(p1)
        local v12 = p1.Name
        local v22
        if string.find(v12, "Block") then
            local Size = ReplicatedStorage.BuildingParts[v12].PrimaryPart.Size
            local Size2 = p1.PrimaryPart.Size
            v22 = math.max(Size2.X * Size2.Y * Size2.Z / (Size.X * Size.Y * Size.Z), 1)
        else
            v22 = 1
        end
        return v22
    end

    local function updateBlockDisplayImage(p1)
        if v9.ModeImage.MaxText.Visible then return end
        local v12, v22, v32 = nil, true, true
        for k, v in pairs(t2) do
            v22 = false
            if v12 then v32 = true break end
            v12 = k
            v32 = false
        end
        if v22 then v9.ModeImage.Image = "" v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0) return end
        if v32 then
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
        else
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v12].Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local function clearSelected()
        for k, v in pairs(t) do v:Destroy() end
        t = {}
        v30 = 0
        v9.ModeImage.AmountText.Text = "0"
        t2 = {}
        updateBlockDisplayImage()
    end

    local function removeBoundingBox()
        if v11 then v11:Destroy() v11 = nil end
        if v12 then v12:Destroy() v12 = nil end
        if v13 then v13:Destroy() v13 = nil end
    end

    local function addSelection(p1)
        local TrowelSB = Instance.new("SelectionBox")
        TrowelSB.Name = "TrowelSB"
        TrowelSB.SurfaceTransparency = 0.5
        TrowelSB.Color3 = Color3.fromRGB(0, 126, 158)
        local _, v12 = p1:GetBoundingBox()
        TrowelSB.LineThickness = math.min(v12.X, v12.Y, v12.Z, 2) / 50
        TrowelSB.Parent = p1
        TrowelSB.Adornee = p1
        TrowelSB:SetAttribute("Created", os.clock())
        t[p1] = TrowelSB
        v30 = v30 + getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
        t2[p1.Name] = if t2[p1.Name] then t2[p1.Name] + 1 else 1
        updateBlockDisplayImage()
    end

    local function removeSelection(p1)
        local v12 = t[p1]
        if v12 then v12:Destroy() end
        if not v9.ModeImage.MaxText.Visible then
            if t2[p1.Name] then
                t2[p1.Name] = t2[p1.Name] - 1
                if t2[p1.Name] <= 0 then t2[p1.Name] = nil end
            end
            updateBlockDisplayImage(p1.Name)
        end
        t[p1] = nil
        v30 = v30 - getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
    end

    local function isPartInZone(p1, p2)
        local v12 = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X, Y, Z = Size.X, Size.Y, Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v12.X > Position.X - X / 2 and (v12.X < Position.X + X / 2 and (v12.Z > Position.Z - Z / 2 and v12.Z < Position.Z + Z / 2))
    end

    local function lockCameraRotation()
        v15 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
        local v12 = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v22 = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v22 + CameraSubject.CFrame.p - v12
        end)
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v15 = false
    end

    local function checkToLockCameraRotation()
        if v15 then return end
        lockCameraRotation()
    end

    local function checkToUnlockCameraRotation()
        if not v15 then return end
        unlockCameraRotation()
    end

    local function updateHandles()
        if not (v12 and v13) then return end
        v12.Visible = false
        v13.Visible = false
        local v122 = isMobilePlayer() or not doingShiftSelect()
        if v11 then v11:FindFirstChild("SelectionBox") end
        local Mode = v9.Mode.Value
        if Mode == "Move" then
            v12.Color3 = Color3.fromRGB(13, 105, 172)
            v12.Visible = v122
            v12.Style = "Movement"
            return
        end
        if Mode == "Rotate" then v13.Visible = v122 return end
        if Mode == "Clone" then
            v12.Color3 = Color3.fromRGB(20, 255, 169)
            v12.Visible = v122
            v12.Style = "Movement"
            return
        end
        if Mode ~= "Mirror" then return end
        v12.Color3 = Color3.fromRGB(248, 37, 255)
        v12.Visible = v122
        v12.Style = "Resize"
    end

    local function mouseMove()
        if v10 then v10.Color3 = Color3.fromRGB(0, 134, 171) end
        local Target = v1.Target
        if not Target or (not Target.Parent or isMobilePlayer()) then v3.Adornee = nil return end
        local v12, _, v22 = GetBlockInfo(Target, LocalPlayer)
        local v32 = doingShiftSelect()
        v3.Visible = true
        if v32 then
            if t[v12] then
                t[v12].Color3 = Color3.fromRGB(175, 0, 0)
                v10 = t[v12]
                v3.Visible = false
            end
        else
            if v3.Adornee and t[v3.Adornee] then v3.Adornee = nil end
            if t[v12] then v3.Visible = false end
        end
        if v22 then
            v3.Adornee = v12
            local _2, v42 = v12:GetBoundingBox()
            v3.LineThickness = math.min(v42.X, v42.Y, v42.Z, 2) / 13.334
        else
            v3.Adornee = nil
        end
    end

    local function updateBoundingBox()
        if not v11 then
            v11 = Instance.new("Part")
            v11.Name = "TrowelBoundingBox"
            v11.Anchored = true
            v11.CanCollide = false
            v11.CanTouch = false
            v11.CanQuery = false
            v11.Transparency = 1
            v11.Size = Vector3.new()
            v1.TargetFilter = v11
            v11.Parent = workspace
            local SelectionBox = Instance.new("SelectionBox")
            SelectionBox.LineThickness = 0.002
            SelectionBox.Adornee = v11
            SelectionBox.Parent = v11
        end
        local SelectionBox = v11.SelectionBox
        local Mode = v9.Mode.Value
        if Mode == "Clone" then SelectionBox.Color3 = Color3.fromRGB(20, 255, 169)
        elseif Mode == "Mirror" then SelectionBox.Color3 = Color3.fromRGB(248, 37, 255)
        else SelectionBox.Color3 = Color3.fromRGB(13, 105, 172) end

        if not v12 then
            v12 = Instance.new("Handles")
            v12.Name = "MoveHandle"
            v12.Adornee = v11
            v12.Visible = false
            v12.Style = Enum.HandlesStyle.Movement
            v12.Parent = LocalPlayer.PlayerGui
            if v17 then v17:Disconnect() v17 = nil end
            v17 = v12.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v12.Adornee.CFrame
                v11:BreakJoints()
                v12.Faces = Faces.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            if v16 then v16:Disconnect() v16 = nil end
            v16 = v12.MouseButton1Up:Connect(function(p1)
                local v122 = v22
                v22 = v12.Adornee.CFrame
                v14 = false
                v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                local Mode2 = v9.Mode.Value
                if v122 == v22 and Mode2 ~= "Mirror" then return end
                if Mode2 == "Mirror" then
                    local v23 = nil
                    if p1 == Enum.NormalId.Right then v23 = Vector3.new(v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Left then v23 = Vector3.new(-v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Top then v23 = Vector3.new(0, v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Bottom then v23 = Vector3.new(0, -v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Back then v23 = Vector3.new(0, 0, v11.size.Z / 2)
                    elseif p1 == Enum.NormalId.Front then v23 = Vector3.new(0, 0, -v11.size.Z / 2) end
                    v22 = CFrame.new((v122 * CFrame.new(v23)).p, v122.p)
                end
                performServerOperatoin(v122, v22)
            end)
            if v18 then v18:Disconnect() v18 = nil end
            v18 = v12.MouseDrag:Connect(function(p1, p2)
                if v9.Mode.Value == "Mirror" then return end
                local v122 = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v122 ~= 0 then p2 = p2 - p2 % v122 end
                local v23 = nil
                if p1 == Enum.NormalId.Right then v23 = v22 * CFrame.new(p2, 0, 0)
                elseif p1 == Enum.NormalId.Left then v23 = v22 * CFrame.new(-p2, 0, 0)
                elseif p1 == Enum.NormalId.Top then v23 = v22 * CFrame.new(0, p2, 0)
                elseif p1 == Enum.NormalId.Bottom then v23 = v22 * CFrame.new(0, -p2, 0)
                elseif p1 == Enum.NormalId.Back then v23 = v22 * CFrame.new(0, 0, p2)
                elseif p1 == Enum.NormalId.Front then v23 = v22 * CFrame.new(0, 0, -p2) end
                local v42 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not _G.DisableToolLimit and not (isPartInZone(v23 * CFrame.new(Size.X / 2, 0, 0), v42) and (isPartInZone(v23 * CFrame.new(-Size.X / 2, 0, 0), v42) and (isPartInZone(v23 * CFrame.new(0, Size.Y / 2, 0), v42) and (isPartInZone(v23 * CFrame.new(0, -Size.Y / 2, 0), v42) and (isPartInZone(v23 * CFrame.new(0, 0, Size.Z / 2), v42) and (isPartInZone(v23 * CFrame.new(0, 0, -Size.Z / 2), v42) and (QuestConditions(v42, v23 * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v42, v23 * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v42, v23 * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v42, v23 * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v42, v23 * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v42, v23 * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then return end
                v11.CFrame = if v23 then v23 else v22
            end)
            v13 = Instance.new("ArcHandles")
            v13.Name = "RotateHandle"
            v13.Adornee = v11
            v13.Visible = false
            v13.Parent = LocalPlayer.PlayerGui
            if v20 then v20:Disconnect() v20 = nil end
            v20 = v13.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v13.Adornee.CFrame
                v11:BreakJoints()
                v13.Axes = Axes.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            if v19 then v19:Disconnect() v19 = nil end
            v19 = v13.MouseButton1Up:Connect(function(p1)
                local v122 = v22
                v22 = v13.Adornee.CFrame
                v14 = false
                v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                if v122 == v22 then return end
                performServerOperatoin(v122, v22)
            end)
            v21 = v13.MouseDrag:Connect(function(p1, p2, p3)
                if math.deg(p2) < -180 then p2 = p2 + 6.283185307179586
                elseif math.deg(p2) > 180 then p2 = p2 - 6.283185307179586 end
                local v122 = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v122 ~= 0 then p2 = math.rad(v122 * math.round(math.deg(p2) / v122)) end
                local v52 = nil
                if p1 == Enum.Axis.X then v52 = v22 * CFrame.Angles(p2, 0, 0)
                elseif p1 == Enum.Axis.Y then v52 = v22 * CFrame.Angles(0, p2, 0)
                elseif p1 == Enum.Axis.Z then v52 = v22 * CFrame.Angles(0, 0, p2) end
                local v72 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not _G.DisableToolLimit and not (isPartInZone(v52 * CFrame.new(Size.X / 2, 0, 0), v72) and (isPartInZone(v52 * CFrame.new(-Size.X / 2, 0, 0), v72) and (isPartInZone(v52 * CFrame.new(0, Size.Y / 2, 0), v72) and (isPartInZone(v52 * CFrame.new(0, -Size.Y / 2, 0), v72) and (isPartInZone(v52 * CFrame.new(0, 0, Size.Z / 2), v72) and (isPartInZone(v52 * CFrame.new(0, 0, -Size.Z / 2), v72) and (QuestConditions(v72, v52 * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v72, v52 * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v72, v52 * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v72, v52 * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v72, v52 * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v72, v52 * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then return end
                v11.CFrame = if v52 then v52 else v22
            end)
        end
        local v152 = getSelectedModels()
        local v22 = #v152
        if v22 < 1 then removeBoundingBox() else
            table.sort(v152, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then return true end
            end)
            local PrimaryPart = v152[v22].PrimaryPart
            local v42, v52 = GetBoundingBox(v152, PrimaryPart.CFrame - PrimaryPart.Position)
            v11.Size = v52
            v11.CFrame = v42
        end
    end

    function performServerOperatoin(p1, p2)
        v23 = true
        local Mode = v9.Mode.Value
        local v12 = getSelectedModels()
        if (Mode == "Clone" or Mode == "Mirror") and not _G.DisableToolLimit then
            local tbl = {}
            local sum = 0
            for i = 1, #v12 do
                local v222 = v12[i]
                local v32 = v222.Name
                local v42 = getBlockValue(v222)
                if tbl[v32] then tbl[v32] = tbl[v32] + v42 else tbl[v32] = v42 end
                sum = sum + v42
            end
            local v52 = LocalPlayer
            local v62 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
            if v62 and LocalPlayer.Settings.ShareBlocks.Value then v52 = v62 end
            local v72 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, sum)
            for k, v in pairs(tbl) do
                if v52.Data:FindFirstChild(k) and v52.Data[k].Value < v52.Data[k].Used.Value + v or v72 then
                    v23 = false
                    local AmountText = v9.ModeImage.AmountText
                    local MaxText = v9.ModeImage.MaxText
                    local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                    local v82 = true
                    if v72 then if RestrictionMetFrame.Visible then v82 = false else RestrictionMetFrame.Visible = true end
                    elseif MaxText.Visible then v82 = false else
                        MaxText.Visible = true
                        AmountText.Visible = false
                        v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[k].Image
                    end
                    local v92 = tool:WaitForChild("ClickSound"):Clone()
                    v92.Parent = script
                    Debris:AddItem(v92, 0.3)
                    v92.PlaybackSpeed = 5
                    v92:Play()
                    updateBoundingBox()
                    if not v82 then return end
                    if v72 then task.wait(3) RestrictionMetFrame.Visible = false else
                        task.wait(3)
                        MaxText.Visible = false
                        AmountText.Visible = true
                        t2 = {}
                        v9.ModeImage.Image = ""
                        local v102 = getSelectedModels()
                        for j = 1, #v102 do t2[v102[j].Name] = true end
                        updateBlockDisplayImage()
                    end
                    return
                end
            end
        end
        if v12 then v12:Destroy() end
        if v13 then v13:Destroy() end
        if Mode == "Clone" then
            table.sort(v12, function(p12, p22)
                if p12.TrowelSB:GetAttribute("Created") > p22.TrowelSB:GetAttribute("Created") then return true end
            end)
        end
        local v112 = tool:WaitForChild("OperationRF"):InvokeServer(v12, p1, p2, v9.Mode.Value) or {}
        local v122 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0
        if Mode == "Clone" then
            v9.SetModeEvent:Fire("Move")
            clearSelected()
            if v122 then
                for k = 1, #v112 do
                    local v132, _, v142 = GetBlockInfo(v112[k], LocalPlayer)
                    if v142 then addSelection(v132) end
                end
            end
        end
        if not v122 then clearSelected() end
        removeBoundingBox()
        if not v122 then v23 = false return end
        updateBoundingBox()
        updateHandles()
        v23 = false
    end

    local function active(p1)
        if not v3 or (v23 or v14) then return end
        local v122 = doingShiftSelect()
        local Adornee = v3.Adornee
        if p1 then
            Adornee = nil
            local v22, _, v32 = GetBlockInfo(v1.Target, LocalPlayer)
            if v32 and v22 then Adornee = v22 end
        end
        if Adornee == nil then if v122 then return end clearSelected() updateBoundingBox() else
            local v42, _, v52 = GetBlockInfo(Adornee, LocalPlayer)
            if not v52 then return end
            if v122 then
                if t[v42] then removeSelection(v42) else addSelection(v42) end
            else
                clearSelected()
                addSelection(v42)
            end
            updateBoundingBox()
            updateHandles()
            mouseMove()
        end
    end

    local function checkForDragSelection(p1, p2, p3)
        local v122 = v25 and not p1 or (if p1 then v27 else p1)
        if not v122 then return end
        local SelectionBox = v9.SelectionBox
        local v22 = if p1 and p2 then p2 else v26
        local v32 = if p1 and p3 then p3 else Vector2.new(v1.X, v1.Y)
        SelectionBox.Position = UDim2.new(0, v22.X, 0, v22.Y)
        SelectionBox.Size = UDim2.new(0, v32.X - v22.X, 0, v32.Y - v22.Y)
        if v28 or (v14 or not v22) then return end
        if not p1 and (v32 - v22).Magnitude < 24 then return end
        v28 = true
        if p1 then checkToLockCameraRotation() end
        SelectionBox.Visible = true
        while v122 do
            v3.Visible = false
            if not doingShiftSelect() or p1 then clearSelected() end
            local v52 = math.min(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v72 = math.max(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v92 = math.min(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v112 = math.max(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v123 = workspace.Blocks:GetChildren()
            for i = 1, #v123 do
                local v132 = v123[i]:GetChildren()
                for j = 1, #v132 do
                    local v142 = v132[j]
                    local _, _2, v152 = GetBlockInfo(v142, LocalPlayer)
                    if v142.PrimaryPart and v152 then
                        local v162, v172 = CurrentCamera:WorldToScreenPoint(v142.PrimaryPart.Position)
                        if v172 and (v92 < v162.X and (v162.X < v72 and (v52 < v162.Y and (v162.Y < v112 and not v142:FindFirstChild("TrowelSB"))))) then
                            addSelection(v142)
                        end
                    end
                end
            end
            task.wait()
            v122 = v25 and not p1 or (if p1 then v27 else p1)
        end
        SelectionBox.Visible = false
        if v3 then v3.Visible = true end
        updateBoundingBox()
        updateHandles()
        if not p1 then v28 = false return end
        checkToUnlockCameraRotation()
        v28 = false
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then
            v25 = true
            v26 = Vector2.new(v1.X, v1.Y)
            active()
            return
        end
        if p1.UserInputType == Enum.UserInputType.Touch then
            if not v14 then mouseMove() active(true) end
        elseif p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 and not GuiService.SelectedObject then
                v25 = true
                v26 = Vector2.new(v1.X, v1.Y)
                active()
            end
        else
            if isMobilePlayer() or not doingShiftSelect() then return end
            updateHandles()
        end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement or p1.KeyCode == Enum.KeyCode.Thumbstick1 or p1.KeyCode == Enum.KeyCode.Thumbstick2 then
            checkForDragSelection()
            mouseMove()
        end
    end

    local function inputEnded(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 or (p1.UserInputType == Enum.UserInputType.Gamepad1 and p1.KeyCode == Enum.KeyCode.ButtonR2) then
            v25 = false
            return
        end
        if not isMobilePlayer() and doingShiftSelect() then updateHandles() end
    end

    local function inputTouchPinch(p1, p2, p3, p4, p5)
        if p5 then return end
        local v12 = p1[1]
        local v22 = p1[2]
        local v31
        if p4 == Enum.UserInputState.Begin then v31 = (v22 - v12).Magnitude end
        if not v31 or (v31 < 120) then return end
        v27 = if p4 == Enum.UserInputState.Begin then true else p4 == Enum.UserInputState.Change
        checkForDragSelection(true, v12, v22)
    end

    local function modeChanged()
        if v12 and v13 then updateBoundingBox() updateHandles() end
    end

    local function cleanUp()
        if workspace:FindFirstChild("SelectionBox") then
            workspace.SelectionBox:Destroy()
            if v3 then v3:Destroy() v3 = nil end
        end
        if workspace:FindFirstChild("TrowelBoundingBox") then
            workspace.TrowelBoundingBox:Destroy()
            removeBoundingBox()
        end
        local v12 = workspace.Blocks:GetChildren()
        for i = 1, #v12 do
            local v22 = v12[i]:GetChildren()
            for j = 1, #v22 do
                local v32 = v22[j]
                if v32:FindFirstChild("TrowelSB") then v32.TrowelSB:Destroy() end
            end
        end
        for k, v in pairs(t) do v:Destroy() end
        t = {}
    end

    local function died()
        if v3 then v3:Destroy() v3 = nil end
        if v4 then v4:Disconnect() v4 = nil end
        if v5 then v5:Disconnect() v5 = nil end
        if v6 then v6:Disconnect() v6 = nil end
        if v7 then v7:Disconnect() v7 = nil end
        if v8 then v8:Disconnect() v8 = nil end
        if v24 then v24:Disconnect() v24 = nil end
        if v29 then v29:Disconnect() v29 = nil end
        ContextActionService:UnbindAction("TrowelToolShiftSelect")
        if v23 then
            v9.ModeImage.Visible = false
            v9.ModeButton.Visible = false
            checkToUnlockCameraRotation()
            return
        end
        clearSelected()
        removeBoundingBox()
        v9.ModeImage.Visible = false
        v9.ModeButton.Visible = false
        checkToUnlockCameraRotation()
    end

    local function eq()
        cleanUp()
        v9 = LocalPlayer.PlayerGui.TrowelToolDisplayGui
        v4 = LocalPlayer.Character.Humanoid.Died:Connect(died)
        v5 = UserInputService.InputChanged:Connect(inputChanged)
        v6 = UserInputService.InputBegan:Connect(inputBegan)
        v7 = UserInputService.InputEnded:Connect(inputEnded)
        v8 = UserInputService.TouchPinch:Connect(inputTouchPinch)
        v24 = v9.Mode:GetPropertyChangedSignal("Value"):Connect(modeChanged)
        v29 = LocalPlayer.Settings.ShareBlocks:GetPropertyChangedSignal("Value"):Connect(function()
            clearSelected()
            removeBoundingBox()
        end)
        ContextActionService:BindAction("TrowelToolShiftSelect", updateHandles, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.ButtonL2)
        v3 = Instance.new("SelectionBox")
        v3.Color3 = Color3.fromRGB(0, 134, 171)
        v3.SurfaceColor3 = Color3.fromRGB(0, 97, 171)
        v3.SurfaceTransparency = 1
        v3.Parent = workspace
        v9.ModeImage.Visible = true
        v9.ModeButton.Visible = true
    end

    local function uneq()
        died()
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function scanAndHookTools()
    local targetBackpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local targetCharacter = LocalPlayer.Character

    local toolList = {}
    if targetBackpack then
        for _, item in ipairs(targetBackpack:GetChildren()) do table.insert(toolList, item) end
    end
    if targetCharacter then
        for _, item in ipairs(targetCharacter:GetChildren()) do table.insert(toolList, item) end
    end

    for _, tool in ipairs(toolList) do
        if tool:IsA("Tool") and not tool:GetAttribute("Hooked") then
            if tool.Name == "BuildingTool" then
                hookBuildTool(tool)
                tool:SetAttribute("Hooked", true)
            elseif tool.Name == "ScalingTool" then
                hookScalingTool(tool)
                tool:SetAttribute("Hooked", true)
            elseif tool.Name == "TrowelTool" then
                hookTrowelTool(tool)
                tool:SetAttribute("Hooked", true)
            end
        end
    end
end

LocalPlayer.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then
        task.wait(0.1)
        scanAndHookTools()
        child.ChildAdded:Connect(function() task.wait(0.1) scanAndHookTools() end)
    end
end)

local currentBackpack = LocalPlayer:FindFirstChildOfClass("Backpack")
if currentBackpack then
    currentBackpack.ChildAdded:Connect(function() task.wait(0.1) scanAndHookTools() end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    dprint("Character spawned/respawned")
    task.wait(0.5)
    scanAndHookTools()
    local backpack = LocalPlayer:WaitForChild("Backpack", 5)
    if backpack then
        scanAndHookTools()
        backpack.ChildAdded:Connect(function() task.wait(0.1) scanAndHookTools() end)
    end
end)

scanAndHookTools()
dprint("System loaded successfully")
    local v3 = nil
    local v4 = nil
    local v5 = nil
    local v6 = nil
    local v7 = nil
    local v8 = CFrame.new()
    local v9 = nil
    local v10 = nil
    local v11 = nil
    local v12 = nil
    local v13 = nil
    local v14 = nil
    local v15 = nil
    local v16 = nil
    local v17 = nil
    local v18 = nil
    local v19 = nil
    local v20 = nil
    local v21 = nil
    local v22 = nil
    local v23 = nil
    local v24 = nil
    local v25 = false
    local v26 = false

    local function isSpeedBuild()
        local SpeedBuild = LocalPlayer.OtherData:FindFirstChild("SpeedBuild")
        if SpeedBuild and SpeedBuild.Value then
            return true
        end
        return nil
    end

    local function setSpeedBuildGuiLook()
        local SpeedBuildToggle = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle
        if isSpeedBuild() then
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565249"
        else
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565059"
        end
    end

    local function fitBuildScroll()
        local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
        local v1_all = ScrollingFrame.BlocksFrame:GetChildren()
        local v2_val = nil
        local v3_val = nil
        for i = 1, #v1_all do
            if v1_all[i]:IsA("GuiObject") and v1_all[i].Visible then
                if not v2_val or v2_val < v1_all[i].AbsolutePosition.Y then
                    v2_val = v1_all[i].AbsolutePosition.Y
                end
                if not v3_val or v1_all[i].AbsolutePosition.Y < v3_val then
                    v3_val = v1_all[i].AbsolutePosition.Y
                end
            end
        end
        if v3_val and v2_val then
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, v2_val - v3_val + 100)
            return
        end
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end

    local function getType(p1)
        local v1_match = string.match(p1.TypeIcon.Image, "%d+")
        if v1_match == "4597411234" then
            return "Block"
        end
        if v1_match == "4597402658" then
            return "Decoration"
        end
        return "Special"
    end

    local function updateBuildGui()
        local v1_p = LocalPlayer
        local v2_p = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2_p and LocalPlayer.Settings.ShareBlocks.Value then
            v1_p = v2_p
        end
        local v3_n = v1_p.Name
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        local SearchFrame = BuildGui.SearchFrame
        local v4_txt = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
        local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v5_all = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()
        for i = 1, #v5_all do
            local v6_b = v5_all[i]
            if game.ReplicatedStorage.BuildingParts:FindFirstChild(v6_b.Name) then
                local v8_t = getType(v6_b)
                local v9_v = game.Players:FindFirstChild(v3_n).Data[v6_b.Name].Value
                local v10_s = string.split(v6_b.Tags.Value, " ")
                local v11_f = false
                if SearchFrame.OnlySearch.Value then
                    local ok, result = pcall(function()
                        return LocalizationService:GetTranslatorForPlayerAsync(game.Players.LocalPlayer)
                    end)
                    if ok then
                        local v13_tr = string.lower((result:Translate(TagsFrame.Parent.BlockName, v6_b.BlockName.Value)))
                        if string.find(v13_tr, v4_txt) or string.find(v4_txt, v13_tr) then
                            v11_f = true
                        end
                        if not v11_f then
                            for j = 1, #v10_s do
                                local v15_tr = string.lower((result:Translate(TagsFrame, v10_s[j])))
                                if string.find(v15_tr, v4_txt) or string.find(v4_txt, v15_tr) then
                                    v11_f = true
                                    break
                                end
                            end
                        end
                    end
                end
                if v9_v == 0 or SearchFrame.OnlyBlocks.Value and v8_t ~= "Block" or (SearchFrame.OnlyDecorations.Value and v8_t ~= "Decoration" or SearchFrame.OnlySpecial.Value and v8_t ~= "Special") then
                    v6_b.Visible = false
                else
                    if SearchFrame.OnlySearch.Value and not v11_f then
                        v6_b.Visible = false
                        continue
                    end
                    v6_b.Visible = true
                end
            end
        end
        fitBuildScroll()
        setSpeedBuildGuiLook()
    end

    local function toggleSpeedBuild()
        if v26 then return end
        v26 = true
        task.spawn(function()
            task.wait(0.2)
            v26 = false
        end)
        local SpeedBuildToggle = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle
        if string.match(SpeedBuildToggle.Image, "%d+") == "4603565059" then
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565249"
            workspace.UpdateSpeedBuildStats:FireServer(true)
        else
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565059"
            workspace.UpdateSpeedBuildStats:FireServer(false)
        end
    end

    local function isPartInZone(p1, p2)
        local Position = p1.Position
        local Position2 = p2.Position
        local Size = p2.Size
        local X = Size.X
        local Y = Size.Y
        local Z = Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return Position.X > Position2.X - X / 2 and (Position.X < Position2.X + X / 2 and (Position.Z > Position2.Z - Z / 2 and Position.Z < Position2.Z + Z / 2))
    end

    local function canPlace(p1)
        if _G.DisableToolLimit then
            return true, nil
        end
        local v2_z = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v32 = isPartInZone(p1.PrimaryPart, v2_z)
        local v4_b = if v32 then nil else "Out of bounds"
        local v5_q, v6_q = QuestConditions(v2_z, p1.PrimaryPart.CFrame, v3.Name, 1, LocalPlayer)
        local v7_c, v8_c = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
        local v9_i, v10_i = ChallengeConditions.itemRestriction(LocalPlayer, v3.Name)
        return if v32 then if v5_q then not v7_c and not v9_i else v5_q else v32, if v4_b then v4_b elseif v6_q then v6_q elseif v8_c then v8_c else v10_i
    end

    local function roundVectorToBase(p1, p2)
        local v1_v = 1 / p2
        local v2_v = p1 * v1_v + Vector3.new(0.5, 0.5, 0.5)
        return Vector3.new(math.floor(v2_v.X), math.floor(v2_v.Y), (math.floor(v2_v.Z))) / v1_v
    end

    local function normalIdToNormalVector(p1, p2)
        if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
        if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
        if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
        return Vector3.new(-1, 0, 0), p2.Size.X
    end

    local function updateBlockCF(p1)
        if not Mouse.Target then return end
        local v12_p = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
        if not p1 then
            v5 = Mouse.Target
            v6 = Mouse.Hit
            v7 = Mouse.TargetSurface
        end
        local v2_cf = v8
        local v32 = (v5.CFrame - v5.Position):Inverse()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v32 = CFrame.new(0, 0, 0)
        end
        local v52, v62 = normalIdToNormalVector(v7, v5)
        local v82 = v5.CFrame * CFrame.new(v52 * (v62 / 2))
        v12_p:SetPrimaryPartCFrame(v82 * v32 * v2_cf)
        local v9_v = (v5.CFrame - v5.Position):PointToWorldSpace(v52)
        local v10_v = v12_p.PrimaryPart.CFrame.RightVector:Dot(v9_v)
        local v112 = v12_p.PrimaryPart.CFrame.UpVector:Dot(v9_v)
        local v122 = v12_p.PrimaryPart.CFrame.LookVector:Dot(v9_v)
        local v13_v = math.abs(v10_v)
        local v14_v = math.abs(v112)
        local v15_v = math.abs(v122)
        v12_p:SetPrimaryPartCFrame(v82 * v32:Inverse() * v2_cf:Inverse())
        local v17_v = v82 * CFrame.new(v52 * (v13_v * (v12_p.PrimaryPart.Size.X / 2) + v14_v * (v12_p.PrimaryPart.Size.Y / 2) + v15_v * (v12_p.PrimaryPart.Size.Z / 2)))
        local v18_v = v5.CFrame:PointToObjectSpace(v6.p)
        local v19_v = if v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom then v18_v - Vector3.new(0, v18_v.Y, 0) elseif v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back then v18_v - Vector3.new(0, 0, v18_v.Z) else v18_v - Vector3.new(v18_v.X, 0, 0)
        local v20_v = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
        if v20_v ~= 0 then
            v19_v = roundVectorToBase(v19_v, v20_v)
        end
        v12_p:SetPrimaryPartCFrame(v17_v * CFrame.new(v19_v) * v32 * v2_cf)
        if not v3:FindFirstChild("CanPlace") then
            local CanPlace = Instance.new("BoolValue")
            CanPlace.Name = "CanPlace"
            CanPlace.Value = true
            CanPlace.Parent = v3
        end
        local v22_v = canPlace(v12_p)
        if v3.CanPlace.Value or not v22_v then
            if not v3.CanPlace.Value or v22_v then return end
            v3.CanPlace.Value = false
            v11 = {}
            local v23_v = v3:GetDescendants()
            for i = 1, #v23_v do
                if v23_v[i]:IsA("BasePart") then
                    table.insert(v11, v23_v[i].Color)
                    v23_v[i].BrickColor = BrickColor.Red()
                end
            end
        else
            v3.CanPlace.Value = true
            local v25_v = v3:GetDescendants()
            local count = 1
            for j = 1, #v25_v do
                if v25_v[j]:IsA("BasePart") then
                    v25_v[j].Color = v11[count]
                    count = count + 1
                end
            end
            if v3:FindFirstChild("OutOfBoundsBG") then
                v3.OutOfBoundsBG:Destroy()
            end
        end
    end

    local function changeTransparency(p1, p2)
        local v1_all = p1:GetDescendants()
        for i = 1, #v1_all do
            if v1_all[i]:IsA("BasePart") then
                if CollectionService:HasTag(v1_all[i], "NoTransparency") then
                    v1_all[i].Transparency = 0
                    continue
                end
                if CollectionService:HasTag(v1_all[i], "FullTransparency") then
                    v1_all[i].Transparency = 1
                    continue
                end
                v1_all[i].Transparency = p2
            end
        end
    end

    local function WeldTogether(p1, p2, p3, p4)
        if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then return end
        local v1_w = Instance.new(p3 or "Weld")
        v1_w.Part0 = p1
        v1_w.Part1 = p2
        v1_w.C0 = CFrame.new()
        v1_w.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
        v1_w.Parent = p4 or p1
        return v1_w
    end

    local function prepareItem()
        Mouse.TargetFilter = v3
        changeTransparency(v3, 0.5)
        local v12_all = v3:GetDescendants()
        for i = 1, #v12_all do
            if v12_all[i]:IsA("BasePart") then
                v12_all[i].Anchored = true
                v12_all[i].CanCollide = false
                v12_all[i].CanQuery = false
                if v12_all[i] ~= v3.PrimaryPart then
                    WeldTogether(v3.PrimaryPart, v12_all[i])
                end
            end
        end
    end

    local function resetRotation()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v8 = CFrame.new()
        else
            local v1_w = workspace
            local v2_w = v1_w[tostring(LocalPlayer.TeamColor) .. "Zone"]
            v8 = (v2_w.CFrame - v2_w.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
        end
    end

    local function itemChanged(p1)
        local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
        local v1_b = game.ReplicatedStorage.BuildingParts:FindFirstChild(Selected)
        updateBuildGui()
        local v2_cf = v3.PrimaryPart.CFrame
        v3:Destroy()
        v3 = v1_b:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(v2_cf.p) * v1_b.PrimaryPart.CFrame.Rotation)
        resetRotation()
        prepareItem()
        updateBlockCF()
        v3.Parent = workspace
        local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v32 = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
        local v4_all = TagsFrame:GetChildren()
        local TextLabel = TagsFrame.TextLabel
        for i = 1, #v32 do
            local v5_t = TextLabel:Clone()
            v5_t.Text = string.lower(v32[i])
            v5_t.Parent = TextLabel.Parent
        end
        for j = 1, #v4_all do
            v4_all[j]:Destroy()
        end
        TagsFrame.Parent.BlockName.Text = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].BlockName.Value
        TagsFrame.Parent.StrengthFrame.TextLabel.Text = tostring(game.ReplicatedStorage.BuildingParts[Selected].Health.Value)
    end

    local function placeBlock(p1)
        if v25 or not v3 then return end
        if v3:FindFirstChild("OutOfBoundsBG") then
            v3.OutOfBoundsBG:Destroy()
        end
        local v22_c, v32_c = canPlace(v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3)
        if not v22_c then
            local OutOfBoundsBG = Instance.new("BillboardGui")
            OutOfBoundsBG.Name = "OutOfBoundsBG"
            OutOfBoundsBG.AlwaysOnTop = true
            OutOfBoundsBG.Adornee = v3
            OutOfBoundsBG.MaxDistance = 1000
            OutOfBoundsBG.Size = UDim2.new(8, 0, 2, 0)
            OutOfBoundsBG.StudsOffset = Vector3.new(0, 3, 0)
            OutOfBoundsBG.ClipsDescendants = false
            OutOfBoundsBG.ZIndexBehavior = Enum.ZIndexBehavior.Global
            OutOfBoundsBG.LightInfluence = 0
            local TextLabel = Instance.new("TextLabel")
            TextLabel.BackgroundTransparency = 1
            TextLabel.Size = UDim2.new(1, 0, 1, 0)
            TextLabel.Font = Enum.Font.Arcade
            TextLabel.Text = v32_c
            TextLabel.TextColor3 = Color3.fromRGB(255, 106, 106)
            TextLabel.TextScaled = true
            TextLabel.TextWrapped = true
            TextLabel.TextStrokeTransparency = 0
            TextLabel.TextStrokeColor3 = Color3.fromRGB(91, 32, 32)
            TextLabel.Parent = OutOfBoundsBG
            OutOfBoundsBG.Parent = v3
            Debris:AddItem(OutOfBoundsBG, 1.5)
            return
        end
        v25 = true
        task.spawn(function()
            task.wait()
            v25 = false
        end)
        local v52_b = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
        local AmountText = v52_b.AmountText
        local MaxText = v52_b.MaxText
-- yoyoyoyoyoyoyyoyoyoyoyoyoyoyyoyoyoyoyoyoyoyoyoyoyyoyoyo
        if (tonumber(AmountText.Text) or 0) <= 0 and not _G.DisableToolLimit then
            local v6_s = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone() or LocalScript:FindFirstChild("ClickSound") and LocalScript.ClickSound:Clone()
            if v6_s then
                v6_s.Parent = v3.PrimaryPart
                Debris:AddItem(v6_s, 0.3)
                v6_s.PlaybackSpeed = 5
                v6_s:Play()
            end
            LocalPlayer.PlayerGui.BuildGui.SearchFrame.ClearFilter:Invoke()
            local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
            ScrollingFrame.CanvasPosition = ScrollingFrame.CanvasPosition + Vector2.new(0, v52_b.AbsolutePosition.Y - 252 + (251 - LocalPlayer.PlayerGui.BuildGui.InventoryFrame.AbsolutePosition.Y))
            if not MaxText.Visible then
                AmountText.Visible = false
                MaxText.Visible = true
                task.wait(0.5)
                AmountText.Visible = true
                MaxText.Visible = false
            end
        else
            local v9_v = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"
            if v9_v then
                local v10_v = v3:FindFirstChild("2ndPlacement")
                if not v10_v then
                    local v11_v = Instance.new("BoolValue")
                    v11_v.Name = "2ndPlacement"
                    v11_v.Parent = v3
                    updateBlockCF()
                    return
                end
                v10_v:Destroy()
            end
            local v122_v = if v9_v then v3.SecondaryPart.PrimaryPart.CFrame else v9_v
            changeTransparency(v3, 0)
            Debris:AddItem(v3, 10)
            local v13_v = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
            local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
            local v15_s = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone() or script:FindFirstChild("ClickSound") and script.ClickSound:Clone()
            if v15_s then
                v15_s.Parent = v3.PrimaryPart
                Debris:AddItem(v15_s, 1)
                v15_s.PlaybackSpeed = 1
                v15_s:Play()
            end
            if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
                resetRotation()
            end
            local v16_v = v3
            v3 = v3:Clone()
            changeTransparency(v3, 0.5)
            v3.Parent = workspace
            Mouse.TargetFilter = v3
            local v17_all = v16_v:GetDescendants()
            for i = 1, #v17_all do
                local v18_v = v17_all[i]
                if v18_v:IsA("BasePart") then
                    v18_v.CanQuery = true
                end
            end
            local v19_v = v5
            updateBlockCF(p1)
            updateBuildGui()
            if not v9_v then
                tool.RF:InvokeServer(v16_v.Name, LocalPlayer.Data:FindFirstChild(v16_v.Name).Value, v19_v, v13_v, Anchor, v16_v.PrimaryPart.CFrame, v122_v)
                v16_v:Destroy()
                return
            end
            local v20_v = game.ReplicatedStorage.BuildingParts[v3.Name]
            v3.SecondaryPart.PrimaryPart.CFrame = v3.PrimaryPart.CFrame * v20_v.PrimaryPart.CFrame:ToObjectSpace(v20_v.SecondaryPart.PrimaryPart.CFrame)
            tool.RF:InvokeServer(v16_v.Name, LocalPlayer.Data:FindFirstChild(v16_v.Name).Value, v19_v, v13_v, Anchor, v16_v.PrimaryPart.CFrame, v122_v)
            v16_v:Destroy()
        end
    end

    local function rotateY()
        v8 = v8 * CFrame.Angles(0, math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0)
        updateBlockCF(true)
    end

    local function rotateX()
        v8 = v8 * CFrame.Angles(math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0, 0)
        updateBlockCF(true)
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement then
            updateBlockCF()
            return
        end
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
        updateBlockCF()
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.Keyboard then
            if p1.KeyCode == Enum.KeyCode.R then rotateY() return end
            if p1.KeyCode == Enum.KeyCode.T then rotateX() end
        else
            if p1.UserInputType == Enum.UserInputType.MouseButton1 then placeBlock() return end
            if p1.UserInputType == Enum.UserInputType.Touch then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                if isSpeedBuild() then v10 = Mouse.Hit else updateBlockCF() end
                return
            end
            if p1.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
            if p1.KeyCode == Enum.KeyCode.ButtonR2 then placeBlock() return end
            if p1.KeyCode == Enum.KeyCode.ButtonX then rotateY() return end
            if p1.KeyCode ~= Enum.KeyCode.ButtonY then return end
            rotateX()
        end
    end

    local function inputEnded(p1, p2)
        if p2 or (p1.UserInputType ~= Enum.UserInputType.Touch or not (isSpeedBuild() and (Mouse.Hit.p - v10.p).Magnitude < 1)) then return end
        updateBlockCF()
        placeBlock(true)
    end

    local function uneq()
        v4 = v3.Name
        if v3 then v3:Destroy() end
        if v12 then v12:Disconnect() v12 = nil end
        if v13 then v13:Disconnect() v13 = nil end
        if v14 then v14:Disconnect() v14 = nil end
        if v15 then v15:Disconnect() v15 = nil end
        if v16 then v16:Disconnect() v16 = nil end
        if v17 then v17:Disconnect() v17 = nil end
        if v18 then v18:Disconnect() v18 = nil end
        if v19 then v19:Disconnect() v19 = nil end
        if v20 then v20:Disconnect() v20 = nil end
        if v21 then v21:Disconnect() v21 = nil end
        if v22 then v22:Disconnect() v22 = nil end
        if v23 then v23:Disconnect() v23 = nil end
        if v24 then v24:Disconnect() v24 = nil end
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        BuildGui.InventoryFrame.Visible = false
        BuildGui.Clear.Visible = false
        BuildGui.ScaleButton.Visible = false
        BuildGui.SearchFrame.Visible = false
    end

    local function eq()
        if LocalPlayer.Character.Humanoid.Health <= 0 then return end
        v3 = game.ReplicatedStorage.BuildingParts.WoodBlock:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(-50, -12, -720))
        itemChanged(v4 or "WoodBlock")
        v12 = UserInputService.InputChanged:Connect(inputChanged)
        v13 = UserInputService.InputBegan:Connect(inputBegan)
        v14 = UserInputService.InputEnded:Connect(inputEnded)
        v16 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.MouseButton1Click:Connect(rotateY)
        v17 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.MouseButton1Click:Connect(rotateX)
        v15 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Place.MouseButton1Click:Connect(function()
            if v9 == v3.PrimaryPart.CFrame and not (if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope") then return end
            v9 = v3.PrimaryPart.CFrame
            placeBlock(true)
        end)
        v18 = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.MouseButton1Click:Connect(toggleSpeedBuild)
        v19 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected:GetPropertyChangedSignal("Value"):Connect(itemChanged)
        v20 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyBlocks:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v21 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyDecorations:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v22 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySpecial:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v23 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySearch:GetPropertyChangedSignal("Value"):Connect(function()
            updateBuildGui()
            LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
        end)
        v24 = LocalPlayer.Character.Humanoid.Died:Connect(uneq)
        updateBuildGui()
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        BuildGui.InventoryFrame.Visible = true
        BuildGui.ScaleButton.Visible = true
        BuildGui.SearchFrame.Visible = true
        if workspace:FindFirstChild("Challenge") and workspace.Challenge:FindFirstChild("Teams") and workspace.Challenge.Teams:FindFirstChild(LocalPlayer.Team.Name) then
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        else
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(132, 132, 132)
        end
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function setupScalingTool(tool)
    cleanOriginalScripts(tool, "ScaleLocalScript")
    
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)

    local v2 = nil
    local v3 = nil
    local v4 = nil
    local v5 = nil
    local v6 = nil
    local v7 = nil
    local v8 = nil
    local v9 = nil
    local v10 = nil
    local v11 = nil
    local v12 = nil
    local v13 = nil
    local v14 = nil
    local v15 = nil
    local v16 = false
    local v17 = false

    local function isPartInZone(p1, p2)
        local v1_pos = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X = Size.X
        local Y = Size.Y
        local Z = Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v1_pos.X > Position.X - X / 2 and (v1_pos.X < Position.X + X / 2 and (v1_pos.Z > Position.Z - Z / 2 and v1_pos.Z < Position.Z + Z / 2))
    end

    local function canSelect(p1)
        if v16 then return false, p1 end
        local v1_bi, _, v2_bi = GetBlockInfo(p1, LocalPlayer)
        if v2_bi and string.find(v1_bi.Name, "Block") then
            return true, v1_bi
        end
        return false
    end

    local function updateBlocks()
        local v1_p = LocalPlayer
        local v2_p = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2_p and LocalPlayer.Settings.ShareBlocks.Value then
            v1_p = v2_p
        end
        local v5_z = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v6_n = v4.Adornee.Parent.Name
        v13 = game.Players:FindFirstChild(v1_p.Name).Data:FindFirstChild(v6_n).Value
        local v7_all = workspace.Blocks:GetChildren()
        local sum = 0
        for i = 1, #v7_all do
            local v8_all = v7_all[i]:GetChildren()
            for j = 1, #v8_all do
                local v9_b = v8_all[j]
                local _, _2, v10_b = GetBlockInfo(v9_b, LocalPlayer)
                if v10_b and (v9_b.Name == v6_n and (v9_b.PrimaryPart and isPartInZone(v9_b.PrimaryPart, v5_z))) then
                    sum = sum + math.max(v9_b.PrimaryPart.Size.X * v9_b.PrimaryPart.Size.Y * v9_b.PrimaryPart.Size.Z / v15, 1)
                end
            end
        end
        v14 = sum
        v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
        v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(v6_n).Image
        v12.Parent = LocalPlayer.PlayerGui
    end

    local function updateBlocksSoft(p1, p2)
        local v1_p = LocalPlayer
        local v2_p = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2_p and LocalPlayer.Settings.ShareBlocks.Value then
            v1_p = v2_p
        end
        v13 = game.Players:FindFirstChild(v1_p.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
        v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)
        local v7_val = math.floor(v13 - v14)
        v12.BlockImage.AmountText.Text = tostring(v7_val)
        return v7_val
    end

    local function roundToNearestThousands(p1)
        return math.floor(p1 * 1000 + 0.5) / 1000
    end

    local function lockCameraRotation()
        v17 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then
            CameraSubject = CameraSubject.RootPart
        end
        local v1_cf = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2_cf = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2_cf + CameraSubject.CFrame.p - v1_cf
        end)
    end

    local function checkToLockCameraRotation()
        if v17 then return end
        lockCameraRotation()
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v17 = false
    end

    local function checkToUnlockCameraRotation()
        if not v17 then return end
        unlockCameraRotation()
    end

    local function mouseMove(p1)
        local Target = Mouse.Target
        if not (Target and Target.Parent) then
            v2.Adornee = nil
            return
        end
        local v12_s, v22_s = canSelect(Target)
        if v4 and (v2.Adornee and v4.Adornee == v2.Adornee.PrimaryPart) then
            v2.Adornee = nil
        end
        if v4 and (v22_s and (v22_s:IsA("Model") and v4.Adornee == v22_s.PrimaryPart)) then
            v2.Adornee = nil
            return
        end
        if v2.Adornee == v22_s then return end
        if v12_s then
            v2.Adornee = v22_s
            local Size = v22_s.PrimaryPart.Size
            v2.LineThickness = math.min(Size.X, Size.Y, Size.Z, 2) / 13.334
            if p1 then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = false
            end
        else
            v2.Adornee = nil
            if not p1 then return end
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        end
    end

    local function active(p1)
        if not v2 then return end
        local Adornee = v2.Adornee
        if Adornee == nil then return end
        local v1_s, v22_s = canSelect(Adornee)
        if v1_s then
            local Size = v22_s.PrimaryPart.Size
            local Size2 = game.ReplicatedStorage.BuildingParts:FindFirstChild(v22_s.Name).PrimaryPart.Size
            v15 = Size2.X * Size2.Y * Size2.Z
            if v4 then
                v4.Adornee = v22_s.PrimaryPart
            else
                v4 = Instance.new("Handles")
                v4.Adornee = v22_s.PrimaryPart
                v4.Style = Enum.HandlesStyle.Resize
                v4.Color3 = Color3.fromRGB(172, 78, 1)
                v4.Parent = LocalPlayer.PlayerGui
            end
            local v3_cf = nil
            local v42 = nil
            local v52 = nil
            local v62 = nil
            if v7 then v7:Disconnect() v7 = nil end
            v7 = v4.MouseButton1Down:Connect(function()
                v16 = true
                v3_cf = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                v4.Adornee:BreakJoints()
                v4.Adornee.Anchored = true
                if not p1 then return end
                checkToLockCameraRotation()
            end)
            local SizeDisplay = v12.BlockImage.SizeDisplay
            local v72 = roundToNearestThousands
            local X = v4.Adornee.Size.X
            local v82 = tostring(v72(X))
            local v9_v = roundToNearestThousands
            local Y = v4.Adornee.Size.Y
            local v10_v = tostring(v9_v(Y))
            local v11_v = roundToNearestThousands
            local Z = v4.Adornee.Size.Z
            SizeDisplay.Text = v82 .. "," .. v10_v .. "," .. tostring(v11_v(Z))
            if v8 then v8:Disconnect() v8 = nil end
            v8 = v4.MouseDrag:Connect(function(p1_d, p2_d)
                local v1_sc = tonumber(v12.BlockImage.More.Scale.TextBox.Text)
                if v1_sc ~= 0 then p2_d = p2_d - p2_d % v1_sc end
                if p1_d == Enum.NormalId.Right then
                    if v52.X + p2_d <= 0.05 then
                        local v2_m = v52.X % v1_sc
                        if v1_sc == 0 then v2_m = 0.05 end
                        if v2_m < 0.05 then v2_m = v1_sc end
                        v62 = Vector3.new(v2_m, v52.Y, v52.Z)
                        v42 = v3_cf * CFrame.new(-(v52.X - v62.X) / 2, 0, 0)
                    else
                        v42 = v3_cf * CFrame.new(p2_d / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2_d, 0, 0)
                    end
                elseif p1_d == Enum.NormalId.Left then
                    if v52.X + p2_d <= 0.05 then
                        local v43 = v52.X % v1_sc
                        if v1_sc == 0 then v43 = 0.05 end
                        if v43 <= 0.05 then v43 = v1_sc end
                        v62 = Vector3.new(v43, v52.Y, v52.Z)
                        v42 = v3_cf * CFrame.new(-(-(v52.X - v62.X)) / 2, 0, 0)
                    else
                        v42 = v3_cf * CFrame.new(-p2_d / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2_d, 0, 0)
                    end
                elseif p1_d == Enum.NormalId.Top then
                    if v52.Y + p2_d <= 0.05 then
                        local v6_m = v52.Y % v1_sc
                        if v1_sc == 0 then v6_m = 0.05 end
                        if v6_m <= 0.05 then v6_m = v1_sc end
                        v62 = Vector3.new(v52.X, v6_m, v52.Z)
                        v42 = v3_cf * CFrame.new(0, -(v52.Y - v62.Y) / 2, 0)
                    else
                        v42 = v3_cf * CFrame.new(0, p2_d / 2, 0)
                        v62 = v52 + Vector3.new(0, p2_d, 0)
                    end
                elseif p1_d == Enum.NormalId.Bottom then
                    if v52.Y + p2_d <= 0.05 then
                        local v8_m = v52.Y % v1_sc
                        if v1_sc == 0 then v8_m = 0.05 end
                        if v8_m <= 0.05 then v8_m = v1_sc end
                        v62 = Vector3.new(v52.X, v8_m, v52.Z)
                        v42 = v3_cf * CFrame.new(0, -(-(v52.Y - v62.Y)) / 2, 0)
                    else
                        v42 = v3_cf * CFrame.new(0, -p2_d / 2, 0)
                        v62 = v52 + Vector3.new(0, p2_d, 0)
                    end
                elseif p1_d == Enum.NormalId.Back then
                    if v52.Z + p2_d <= 0.05 then
                        local v10_m = v52.Z % v1_sc
                        if v1_sc == 0 then v10_m = 0.05 end
                        if v10_m <= 0.05 then v10_m = v1_sc end
                        v62 = Vector3.new(v52.X, v52.Y, v10_m)
                        v42 = v3_cf * CFrame.new(0, 0, -(v52.Z - v62.Z) / 2)
                    else
                        v42 = v3_cf * CFrame.new(0, 0, p2_d / 2)
                        v62 = v52 + Vector3.new(0, 0, p2_d)
                    end
                elseif p1_d == Enum.NormalId.Front then
                    if v52.Z + p2_d <= 0.05 then
                        local v122_m = v52.Z % v1_sc
                        if v1_sc == 0 then v122_m = 0.05 end
                        if v122_m <= 0.05 then v122_m = v1_sc end
                        v62 = Vector3.new(v52.X, v52.Y, v122_m)
                        v42 = v3_cf * CFrame.new(0, 0, -(-(v52.Z - v62.Z)) / 2)
                    else
                        v42 = v3_cf * CFrame.new(0, 0, -p2_d / 2)
                        v62 = v52 + Vector3.new(0, 0, p2_d)
                    end
                end
                v62 = Vector3.new(math.max(v62.X, 0.05), math.max(v62.Y, 0.05), (math.max(v62.Z, 0.05)))
                local v17_m = Size
                local v19_m = v62.X * v62.Y * v62.Z / v15 - v17_m.X * v17_m.Y * v17_m.Z / v15
                local v21_m = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local v22_m = isPartInZone(v42 * CFrame.new(v62.X / 2, 0, 0), v21_m) and (isPartInZone(v42 * CFrame.new(-v62.X / 2, 0, 0), v21_m) and (isPartInZone(v42 * CFrame.new(0, v62.Y / 2, 0), v21_m) and (isPartInZone(v42 * CFrame.new(0, -v62.Y / 2, 0), v21_m) and (isPartInZone(v42 * CFrame.new(0, 0, v62.Z / 2), v21_m) and (isPartInZone(v42 * CFrame.new(0, 0, -v62.Z / 2), v21_m) and (QuestConditions(v21_m, v42 * CFrame.new(v62.X / 2, 0, 0), "", v19_m, LocalPlayer) and (QuestConditions(v21_m, v42 * CFrame.new(-v62.X / 2, 0, 0), "", v19_m, LocalPlayer) and (QuestConditions(v21_m, v42 * CFrame.new(0, v62.Y / 2, 0), "", v19_m, LocalPlayer) and (QuestConditions(v21_m, v42 * CFrame.new(0, -v62.Y / 2, 0), "", v19_m, LocalPlayer) and (QuestConditions(v21_m, v42 * CFrame.new(0, 0, v62.Z / 2), "", v19_m, LocalPlayer) and QuestConditions(v21_m, v42 * CFrame.new(0, 0, -v62.Z / 2), "", v19_m, LocalPlayer))))))))))) and true or false
                local v23_m = updateBlocksSoft(v4.Adornee.Size, v62)
                local v24_m = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, v19_m)
                
                if (v23_m >= 0 and (v22_m and not v24_m)) or _G.DisableToolLimit then
                    if v4.Adornee.Size == v62 then return end
                    v4.Adornee:BreakJoints()
                    v4.Adornee.CFrame = v42 or v3_cf
                    v4.Adornee.Size = v62 or v52
                    local v28 = tostring(roundToNearestThousands(v4.Adornee.Size.X))
                    local v30 = tostring(roundToNearestThousands(v4.Adornee.Size.Y))
                    v12.BlockImage.SizeDisplay.Text = v28 .. "," .. v30 .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
                    return
                end
                updateBlocksSoft(v62, v4.Adornee.Size)
                local AmountText = v12.BlockImage.AmountText
                local MaxText = v12.BlockImage.MaxText
                local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                if v24_m then
                    RestrictionMetFrame.Visible = true
                else
                    MaxText.Visible = true
                    AmountText.Visible = false
                end
                local v32_s = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone() or script:FindFirstChild("ClickSound") and script.ClickSound:Clone()
                if v32_s then
                    v32_s.Parent = v4.Adornee
                    Debris:AddItem(v32_s, 0.3)
                    v32_s.PlaybackSpeed = 5
                    v32_s:Play()
                end
                if not v24_m then
                    task.wait(0.5)
                    MaxText.Visible = false
                    AmountText.Visible = true
                    return
                end
                task.wait(3)
                RestrictionMetFrame.Visible = false
            end)
            if v6 then v6:Disconnect() v6 = nil end
            v6 = v4.MouseButton1Up:Connect(function()
                v3_cf = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v1_r, v2_r = tool.RF:InvokeServer(v4.Adornee.Parent, v52, v3_cf)
                Size = v52
                if v1_r then
                    v22_s.PrimaryPart.Size = v1_r
                    v22_s.PrimaryPart.CFrame = v2_r
                    updateBlocks()
                end
                v16 = false
                if not p1 then return end
                checkToUnlockCameraRotation()
            end)
            if v5 then v5:Disconnect() v5 = nil end
            v5 = tool.Unequipped:Connect(function()
                v3_cf = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v1_r, v2_r = tool.RF:InvokeServer(v4.Adornee.Parent, v52, v3_cf)
                Size = v52
                if not v1_r then
                    v16 = false
                    if v5 then v5:Disconnect() v5 = nil end
                    return
                end
                v22_s.PrimaryPart.Size = v1_r
                v22_s.PrimaryPart.CFrame = v2_r
                v16 = false
                if v5 then v5:Disconnect() v5 = nil end
            end)
            updateBlocks()
        end
        mouseMove()
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then active() return end
        if p1.UserInputType == Enum.UserInputType.Touch then mouseMove(true) return end
        if p1.UserInputType ~= Enum.UserInputType.Gamepad1 or p1.KeyCode ~= Enum.KeyCode.ButtonR2 then return end
        active()
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType ~= Enum.UserInputType.MouseMovement and (p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2) then return end
        mouseMove(false)
    end

    local function uneq()
        if v2 then v2:Destroy() v2 = nil end
        if v3 then v3:Disconnect() v3 = nil end
        if v11 then v11:Disconnect() v11 = nil end
        if v9 then v9:Disconnect() v9 = nil end
        if v10 then v10:Disconnect() v10 = nil end
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = true
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = true
        LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = true
        if not v4 then
            v12.BlockImage.Visible = false
            checkToUnlockCameraRotation()
            return
        end
        if v4 then v4:Destroy() v4 = nil end
        v12.BlockImage.Visible = false
        checkToUnlockCameraRotation()
    end

    local function died()
        uneq()
    end

    local function eq()
        v12 = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScaleToolDisplayGui")
        v12.BlockImage.SizeDisplay.Text = ""
        v3 = game.Players.LocalPlayer.Character.Humanoid.Died:Connect(died)
        v9 = UserInputService.InputChanged:Connect(inputChanged)
        v10 = UserInputService.InputBegan:Connect(inputBegan)
        v11 = LocalPlayer.PlayerGui:WaitForChild("TabletToolGui"):WaitForChild("Frame"):WaitForChild("Place").MouseButton1Down:Connect(function()
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
            active(true)
        end)
        v2 = Instance.new("SelectionBox", workspace)
        v2.Color3 = Color3.fromRGB(172, 109, 0)
        v2.SurfaceColor3 = Color3.fromRGB(172, 172, 0)
        v2.SurfaceTransparency = 0.5
        v12.BlockImage.Visible = true
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function setupTrowelTool(tool)
    cleanOriginalScripts(tool, "TrowelLocalScript")
    
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)

    local v3 = nil
    local v4 = nil
    local v5 = nil
    local v6 = nil
    local v7 = nil
    local v8 = nil
    local v9 = nil
    local t = {}
    local t2 = {}
    local v10 = nil
    local v11 = nil
    local v12 = nil
    local v13 = nil
    local v14 = false
    local v15 = false
    local v16 = nil
    local v17 = nil
    local v18 = nil
    local v19 = nil
    local v20 = nil
    local v21 = nil
    local v22 = nil
    local v23 = false
    local v24 = nil
    local v25 = false
    local v26 = nil
    local v27 = false
    local v28 = false
    local v29 = nil
    local v30 = 0

    local function isMobilePlayer()
        return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
    end

    local function getSelectedModels()
        local t2_m = {}
        for k, v in pairs(t) do table.insert(t2_m, k) end
        return t2_m
    end

    local function getBlockValue(p1)
        local v1_n = p1.Name
        local v2_v
        if string.find(v1_n, "Block") then
            local Size = game.ReplicatedStorage.BuildingParts[v1_n].PrimaryPart.Size
            local Size2 = p1.PrimaryPart.Size
            v2_v = math.max(Size2.X * Size2.Y * Size2.Z / (Size.X * Size.Y * Size.Z), 1)
        else
            v2_v = 1
        end
        return v2_v
    end

    local function updateBlockDisplayImage(p1)
        if v9.ModeImage.MaxText.Visible then return end
        local v1_i = nil
        local v2_i = true
        local v3_i = true
        for k, v in pairs(t2) do
            v2_i = false
            if v1_i then v3_i = true break end
            v1_i = k
            v3_i = false
        end
        if v2_i then
            v9.ModeImage.Image = ""
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
            return
        end
        if v3_i then
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
        else
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v1_i].Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local function clearSelected()
        for k, v in pairs(t) do v:Destroy() end
        t = {}
        v30 = 0
        v9.ModeImage.AmountText.Text = "0"
        t2 = {}
        updateBlockDisplayImage()
    end

    local function addSelection(p1)
        local TrowelSB = Instance.new("SelectionBox")
        TrowelSB.Name = "TrowelSB"
        TrowelSB.SurfaceTransparency = 0.5
        TrowelSB.Color3 = Color3.fromRGB(0, 126, 158)
        local _, v1_b = p1:GetBoundingBox()
        TrowelSB.LineThickness = math.min(v1_b.X, v1_b.Y, v1_b.Z, 2) / 50
        TrowelSB.Parent = p1
        TrowelSB.Adornee = p1
        TrowelSB:SetAttribute("Created", tick())
        t[p1] = TrowelSB
        v30 = v30 + getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
        t2[p1.Name] = if t2[p1.Name] then t2[p1.Name] + 1 or 1 else 1
        updateBlockDisplayImage()
    end

    local function removeSelection(p1)
        local v1_s = t[p1]
        if v1_s then v1_s:Destroy() end
        if not v9.ModeImage.MaxText.Visible then
            if t2[p1.Name] then
                local v2_m = t2
                local v3_m = p1.Name
                v2_m[v3_m] = v2_m[v3_m] + -1
                if t2[p1.Name] <= 0 then t2[p1.Name] = nil end
            end
            updateBlockDisplayImage(p1.Name)
        end
        t[p1] = nil
        v30 = v30 - getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
    end

    local function isPartInZone(p1, p2)
        local v1_p = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X = Size.X
        local Y = Size.Y
        local Z = Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v1_p.X > Position.X - X / 2 and (v1_p.X < Position.X + X / 2 and (v1_p.Z > Position.Z - Z / 2 and v1_p.Z < Position.Z + Z / 2))
    end

    local function doingShiftSelect()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or (UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or (UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or (UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()))))
    end

    local function lockCameraRotation()
        v15 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
        local v1_c = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2_c = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2_c + CameraSubject.CFrame.p - v1_c
        end)
    end

    local function checkToLockCameraRotation()
        if v15 then return end
        lockCameraRotation()
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v15 = false
    end

    local function checkToUnlockCameraRotation()
        if not v15 then return end
        unlockCameraRotation()
    end

    local function removeBoundingBox()
        if v11 then v11:Destroy() v11 = nil end
        if v12 then v12:Destroy() v12 = nil end
        if v13 then v13:Destroy() v13 = nil end
    end

    local function GetBoundingBox(p1, p2)
        local abs = math.abs
        local v1_b = (1 / 0)
        local v2_b = (-1 / 0)
        local v3_b = (-1 / 0)
        local v4_b = (-1 / 0)
        local v5_b = (1 / 0)
        local v6_b = (1 / 0)
        for i = 1, #p1 do
            local PrimaryPart = p1[i].PrimaryPart
            if PrimaryPart then
                local v7_b = p2:toObjectSpace(PrimaryPart.CFrame)
                local Size = PrimaryPart.Size
                local X = Size.X
                local Y = Size.Y
                local Z = Size.Z
                local v8_b, v9_b, v10_b, v11_b, v12_b, v13_b, v14_b, v15_b, v16_b, v17_b, v18_b, v19_b = v7_b:components()
                local v20_b = 0.5 * (abs(v11_b) * X + abs(v12_b) * Y + abs(v13_b) * Z)
                local v21_b = 0.5 * (abs(v14_b) * X + abs(v15_b) * Y + abs(v16_b) * Z)
                local v22_b = 0.5 * (abs(v17_b) * X + abs(v18_b) * Y + abs(v19_b) * Z)
                if v8_b - v20_b < v5_b then v5_b = v8_b - v20_b end
                if v9_b - v21_b < v6_b then v6_b = v9_b - v21_b end
                if v10_b - v22_b < v1_b then v1_b = v10_b - v22_b end
                if v2_b < v8_b + v20_b then v2_b = v8_b + v20_b end
                if v3_b < v9_b + v21_b then v3_b = v9_b + v21_b end
                if v4_b < v10_b + v22_b then v4_b = v10_b + v22_b end
            end
        end
        local v23_b = Vector3.new(v5_b, v6_b, v1_b)
        local v24_b = Vector3.new(v2_b, v3_b, v4_b)
        return p2 - p2.p + p2:pointToWorldSpace((v24_b + v23_b) / 2), v24_b - v23_b
    end

    local function updateBoundingBox()
        if not v11 then
            v11 = Instance.new("Part")
            v11.Name = "TrowelBoundingBox"
            v11.Anchored = true
            v11.CanCollide = false
            v11.CanTouch = false
            v11.CanQuery = false
            v11.Transparency = 1
            v11.Size = Vector3.new()
            Mouse.TargetFilter = v11
            v11.Parent = workspace
            local SelectionBox = Instance.new("SelectionBox")
            SelectionBox.LineThickness = 0.002
            SelectionBox.Adornee = v11
            SelectionBox.Parent = v11
        end
        local SelectionBox = v11.SelectionBox
        local Mode = v9.Mode.Value
        if Mode == "Clone" then SelectionBox.Color3 = Color3.fromRGB(20, 255, 169)
        elseif Mode == "Mirror" then SelectionBox.Color3 = Color3.fromRGB(248, 37, 255)
        else SelectionBox.Color3 = Color3.fromRGB(13, 105, 172) end
        
        if not v12 then
            v12 = Instance.new("Handles")
            v12.Name = "MoveHandle"
            v12.Adornee = v11
            v12.Visible = false
            v12.Style = Enum.HandlesStyle.Movement
            v12.Parent = LocalPlayer.PlayerGui
            if v17 then v17:Disconnect() v17 = nil end
            v17 = v12.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v12.Adornee.CFrame
                v11:BreakJoints()
                v12.Faces = Faces.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            if v16 then v16:Disconnect() v16 = nil end
            v16 = v12.MouseButton1Up:Connect(function(p1)
                local v1_cf = v22
                v22 = v12.Adornee.CFrame
                v14 = false
                v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                local Mode_u = v9.Mode.Value
                if v1_cf == v22 and Mode_u ~= "Mirror" then return end
                if Mode_u == "Mirror" then
                    local v2_v = nil
                    if p1 == Enum.NormalId.Right then v2_v = Vector3.new(v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Left then v2_v = Vector3.new(-v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Top then v2_v = Vector3.new(0, v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Bottom then v2_v = Vector3.new(0, -v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Back then v2_v = Vector3.new(0, 0, v11.size.Z / 2)
                    elseif p1 == Enum.NormalId.Front then v2_v = Vector3.new(0, 0, -v11.size.Z / 2) end
                    v22 = CFrame.new((v1_cf * CFrame.new(v2_v)).p, v1_cf.p)
                end
                performServerOperatoin(v1_cf, v22)
            end)
            if v18 then v18:Disconnect() v18 = nil end
            v18 = v12.MouseDrag:Connect(function(p1, p2)
                if v9.Mode.Value == "Mirror" then return end
                local v1_s = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v1_s ~= 0 then p2 = p2 - p2 % v1_s end
                local v2_v = nil
                if p1 == Enum.NormalId.Right then v2_v = v22 * CFrame.new(p2, 0, 0)
                elseif p1 == Enum.NormalId.Left then v2_v = v22 * CFrame.new(-p2, 0, 0)
                elseif p1 == Enum.NormalId.Top then v2_v = v22 * CFrame.new(0, p2, 0)
                elseif p1 == Enum.NormalId.Bottom then v2_v = v22 * CFrame.new(0, -p2, 0)
                elseif p1 == Enum.NormalId.Back then v2_v = v22 * CFrame.new(0, 0, p2)
                elseif p1 == Enum.NormalId.Front then v2_v = v22 * CFrame.new(0, 0, -p2) end
                
                if _G.DisableToolLimit then
                    v11.CFrame = if v2_v then v2_v else v22
                    return
                end
                
                local v4_z = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not (isPartInZone(v2_v * CFrame.new(Size.X / 2, 0, 0), v4_z) and (isPartInZone(v2_v * CFrame.new(-Size.X / 2, 0, 0), v4_z) and (isPartInZone(v2_v * CFrame.new(0, Size.Y / 2, 0), v4_z) and (isPartInZone(v2_v * CFrame.new(0, -Size.Y / 2, 0), v4_z) and (isPartInZone(v2_v * CFrame.new(0, 0, Size.Z / 2), v4_z) and (isPartInZone(v2_v * CFrame.new(0, 0, -Size.Z / 2), v4_z) and (QuestConditions(v4_z, v2_v * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v4_z, v2_v * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v4_z, v2_v * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v4_z, v2_v * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v4_z, v2_v * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v4_z, v2_v * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then return end
                v11.CFrame = if v2_v then v2_v else v22
            end)
            v13 = Instance.new("ArcHandles")
            v13.Name = "RotateHandle"
            v13.Adornee = v11
            v13.Visible = false
            v13.Parent = LocalPlayer.PlayerGui
            if v20 then v20:Disconnect() v20 = nil end
            v20 = v13.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v13.Adornee.CFrame
                v11:BreakJoints()
                v13.Axes = Axes.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            if v19 then v19:Disconnect() v19 = nil end
            v19 = v13.MouseButton1Up:Connect(function(p1)
                local v1_cf = v22
                v22 = v13.Adornee.CFrame
                v14 = false
                v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                if v1_cf == v22 then return end
                performServerOperatoin(v1_cf, v22)
            end)
            v21 = v13.MouseDrag:Connect(function(p1, p2, p3)
                if math.deg(p2) < -180 then p2 = p2 + 6.283185307179586
                elseif math.deg(p2) > 180 then p2 = p2 - 6.283185307179586 end
                local v1_s = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v1_s ~= 0 then p2 = math.rad(v1_s * math.round(math.deg(p2) / v1_s)) end
                local v5_v = nil
                if p1 == Enum.Axis.X then v5_v = v22 * CFrame.Angles(p2, 0, 0)
                elseif p1 == Enum.Axis.Y then v5_v = v22 * CFrame.Angles(0, p2, 0)
                elseif p1 == Enum.Axis.Z then v5_v = v22 * CFrame.Angles(0, 0, p2) end
                
                if _G.DisableToolLimit then
                    v11.CFrame = if v5_v then v5_v else v22
                    return
                end
                
                local v7_z = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not (isPartInZone(v5_v * CFrame.new(Size.X / 2, 0, 0), v7_z) and (isPartInZone(v5_v * CFrame.new(-Size.X / 2, 0, 0), v7_z) and (isPartInZone(v5_v * CFrame.new(0, Size.Y / 2, 0), v7_z) and (isPartInZone(v5_v * CFrame.new(0, -Size.Y / 2, 0), v7_z) and (isPartInZone(v5_v * CFrame.new(0, 0, Size.Z / 2), v7_z) and (isPartInZone(v5_v * CFrame.new(0, 0, -Size.Z / 2), v7_z) and (QuestConditions(v7_z, v5_v * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v7_z, v5_v * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v7_z, v5_v * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v7_z, v5_v * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v7_z, v5_v * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v7_z, v5_v * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then return end
                v11.CFrame = if v5_v then v5_v else v22
            end)
        end
        local v15_all = getSelectedModels()
        local v2_c = #v15_all
        if v2_c < 1 then removeBoundingBox()
        else
            table.sort(v15_all, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then return true end
            end)
            local PrimaryPart = v15_all[v2_c].PrimaryPart
            local v4_b, v5_b = GetBoundingBox(v15_all, PrimaryPart.CFrame - PrimaryPart.Position)
            v11.Size = v5_b
            v11.CFrame = v4_b
        end
    end

    local function updateHandles()
        if not (v12 and v13) then return end
        v12.Visible = false
        v13.Visible = false
        local v1_s = isMobilePlayer() or not doingShiftSelect()
        if v11 then v11:FindFirstChild("SelectionBox") end
        local Mode = v9.Mode.Value
        if Mode == "Move" then
            v12.Color3 = Color3.fromRGB(13, 105, 172)
            v12.Visible = v1_s
            v12.Style = "Movement"
            return
        end
        if Mode == "Rotate" then v13.Visible = v1_s return end
        if Mode == "Clone" then
            v12.Color3 = Color3.fromRGB(20, 255, 169)
            v12.Visible = v1_s
            v12.Style = "Movement"
            return
        end
        if Mode ~= "Mirror" then return end
        v12.Color3 = Color3.fromRGB(248, 37, 255)
        v12.Visible = v1_s
        v12.Style = "Resize"
    end

    function performServerOperatoin(p1, p2)
        v23 = true
        local Mode = v9.Mode.Value
        local v1_all = getSelectedModels()
        if Mode == "Clone" or Mode == "Mirror" then
            local tbl = {}
            local sum = 0
            for i = 1, #v1_all do
                local v22_m = v1_all[i]
                local v3_n = v22_m.Name
                local v4_v = getBlockValue(v22_m)
                if tbl[v3_n] then tbl[v3_n] = tbl[v3_n] + v4_v else tbl[v3_n] = v4_v end
                sum = sum + v4_v
            end
            local v5_p = LocalPlayer
            local v6_p = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
            if v6_p and LocalPlayer.Settings.ShareBlocks.Value then v5_p = v6_p end
            local v7_c = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, sum)
            
            if not _G.DisableToolLimit then
                for k, v in pairs(tbl) do
                    if v5_p.Data:FindFirstChild(k) and v5_p.Data[k].Value < v5_p.Data[k].Used.Value + v or v7_c then
                        v23 = false
                        local AmountText = v9.ModeImage.AmountText
                        local MaxText = v9.ModeImage.MaxText
                        local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                        local v8_b = true
                        if v7_c then if RestrictionMetFrame.Visible then v8_b = false else RestrictionMetFrame.Visible = true end
                        elseif MaxText.Visible then v8_b = false
                        else
                            MaxText.Visible = true
                            AmountText.Visible = false
                            v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[k].Image
                        end
                        local v92 = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone() or script:FindFirstChild("ClickSound") and script.ClickSound:Clone()
                        if v92 then
                            v92.Parent = script
                            Debris:AddItem(v92, 0.3)
                            v92.PlaybackSpeed = 5
                            v92:Play()
                        end
                        updateBoundingBox()
                        if not v8_b then return end
                        if v7_c then task.wait(3) RestrictionMetFrame.Visible = false
                        else
                            task.wait(3)
                            MaxText.Visible = false
                            AmountText.Visible = true
                            t2 = {}
                            v9.ModeImage.Image = ""
                            local v10_v = getSelectedModels()
                            for j = 1, #v10_v do t2[v10_v[j].Name] = true end
                            updateBlockDisplayImage()
                        end
                        return
                    end
                end
            end
        end
        if v12 then v12:Destroy() end
        if v13 then v13:Destroy() end
        if Mode == "Clone" then
            table.sort(v1_all, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") > p2.TrowelSB:GetAttribute("Created") then return true end
            end)
        end
        local v11_all = tool.OperationRF:InvokeServer(v1_all, p1, p2, v9.Mode.Value) or {}
        local v122_v = LocalPlayer.Character and (tool.Parent and (if tool.Parent == LocalPlayer.Character then LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 else false))
        if Mode == "Clone" then
            v9.SetModeEvent:Fire("Move")
            clearSelected()
            if v122_v then
                for k = 1, #v11_all do
                    local v132, _, v14_b = GetBlockInfo(v11_all[k], LocalPlayer)
                    if v14_b then addSelection(v132) end
                end
            end
        end
        if not v122_v then clearSelected() end
        removeBoundingBox()
        if not v122_v then v23 = false return end
        updateBoundingBox()
        updateHandles()
        v23 = false
    end

    local function mouseMove()
        if v10 then v10.Color3 = Color3.fromRGB(0, 134, 171) end
        local Target = Mouse.Target
        if not Target or (not Target.Parent or isMobilePlayer()) then v3.Adornee = nil return end
        local v12_b, _, v2_b = GetBlockInfo(Target, LocalPlayer)
        local v32 = doingShiftSelect()
        v3.Visible = true
        if v32 then
            if t[v12_b] then t[v12_b].Color3 = Color3.fromRGB(175, 0, 0) v10 = t[v12_b] v3.Visible = false end
        else
            if v3.Adornee and t[v3.Adornee] then v3.Adornee = nil end
            if t[v12_b] then v3.Visible = false end
        end
        if v2_b then
            v3.Adornee = v12_b
            local _2, v4_b = v12_b:GetBoundingBox()
            v3.LineThickness = math.min(v4_b.X, v4_b.Y, v4_b.Z, 2) / 13.334
        else v3.Adornee = nil end
    end

    local function checkForDragSelection(p1, p2, p3)
        local v12_d = v25 and not p1 or (if p1 then v27 else p1)
        if not v12_d then return end
        local SelectionBox = v9.SelectionBox
        local v2_p = if p1 and p2 then p2 else v26
        local v32 = if p1 and p3 then p3 else Vector2.new(Mouse.X, Mouse.Y)
        SelectionBox.Position = UDim2.new(0, v2_p.X, 0, v2_p.Y)
        SelectionBox.Size = UDim2.new(0, v32.X - v2_p.X, 0, v32.Y - v2_p.Y)
        if v28 or (v14 or not v2_p) then return end
        if not p1 and (v32 - v2_p).Magnitude < 24 then return end
        v28 = true
        if p1 then checkToLockCameraRotation() end
        SelectionBox.Visible = true
        while v12_d do
            v3.Visible = false
            if not doingShiftSelect() or p1 then clearSelected() end
            local v5_d = math.min(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v7_d = math.max(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v92 = math.min(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v11_d = math.max(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v122_d = workspace.Blocks:GetChildren()
            for i = 1, #v122_d do
                local v13_d = v122_d[i]:GetChildren()
                for j = 1, #v13_d do
                    local v142 = v13_d[j]
                    local _, _2, v15_b = GetBlockInfo(v142, LocalPlayer)
                    if v142.PrimaryPart and v15_b then
                        local v16_p, v17_p = CurrentCamera:WorldToScreenPoint(v142.PrimaryPart.Position)
                        if v17_p and (v92 < v16_p.X and (v16_p.X < v7_d and (v5_d < v16_p.Y and (v16_p.Y < v11_d and not v142:FindFirstChild("TrowelSB"))))) then
                            addSelection(v142)
                        end
                    end
                end
            end
            task.wait()
            v12_d = v25 and not p1 or (if p1 then v27 else p1)
        end
        SelectionBox.Visible = false
        if v3 then v3.Visible = true end
        updateBoundingBox()
        updateHandles()
        if not p1 then v28 = false return end
        checkToUnlockCameraRotation()
        v28 = false
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then
            v25 = true
            v26 = Vector2.new(Mouse.X, Mouse.Y)
            active()
            return
        end
        if p1.UserInputType == Enum.UserInputType.Touch then
            if not v14 then mouseMove() active(true) end
        elseif p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 and not GuiService.SelectedObject then
                v25 = true
                v26 = Vector2.new(Mouse.X, Mouse.Y)
                active()
            end
        else
            if isMobilePlayer() or not doingShiftSelect() then return end
            updateHandles()
        end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement then checkForDragSelection() mouseMove() return end
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
        checkForDragSelection()
        mouseMove()
    end

    local function inputEnded(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then v25 = false return end
        if p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 then v25 = false end
        else
            if isMobilePlayer() or doingShiftSelect() then return end
            updateHandles()
        end
    end

    local v31 = nil
    local function inputTouchPinch(p1, p2, p3, p4, p5)
        if p5 then return end
        local v1_p = p1[1]
        local v2_p = p1[2]
        if p4 == Enum.UserInputState.Begin then v31 = (v2_p - v1_p).Magnitude end
        if not (v31 < 120) then return end
        v27 = if p4 == Enum.UserInputState.Begin then true else p4 == Enum.UserInputState.Change
        checkForDragSelection(true, v1_p, v2_p)
    end

    local function modeChanged()
        if v12 and v13 then updateBoundingBox() updateHandles() end
    end

    local function cleanUp()
        if workspace:FindFirstChild("SelectionBox") then
            workspace.SelectionBox:Destroy()
            if v3 then v3:Destroy() v3 = nil end
        end
        if workspace:FindFirstChild("TrowelBoundingBox") then
            workspace.TrowelBoundingBox:Destroy()
            if v11 then removeBoundingBox() end
        end
        local v1_all = workspace.Blocks:GetChildren()
        for i = 1, #v1_all do
            local v2_c = v1_all[i]:GetChildren()
            for j = 1, #v2_c do
                local v32 = v2_c[j]
                if v32:FindFirstChild("TrowelSB") then v32.TrowelSB:Destroy() end
            end
        end
        for k, v in pairs(t) do v:Destroy() end
        t = {}
    end

    local function uneq()
        v25 = false
        v14 = false
        if v3 then v3:Destroy() v3 = nil end
        if v4 then v4:Disconnect() v4 = nil end
        if v5 then v5:Disconnect() v5 = nil end
        if v6 then v6:Disconnect() v6 = nil end
        if v7 then v7:Disconnect() v7 = nil end
        if v8 then v8:Disconnect() v8 = nil end
        if v24 then v24:Disconnect() v24 = nil end
        if v29 then v29:Disconnect() v29 = nil end
        ContextActionService:UnbindAction("TrowelToolShiftSelect")
        if v23 then
            v9.ModeImage.Visible = false
            v9.ModeButton.Visible = false
            checkToUnlockCameraRotation()
            return
        end
        clearSelected()
        removeBoundingBox()
        v9.ModeImage.Visible = false
        v9.ModeButton.Visible = false
        checkToUnlockCameraRotation()
    end

    local function died()
        uneq()
        clearSelected()
        removeBoundingBox()
    end

    local function eq()
        cleanUp()
        v9 = LocalPlayer.PlayerGui.TrowelToolDisplayGui
        v4 = LocalPlayer.Character.Humanoid.Died:Connect(died)
        v5 = UserInputService.InputChanged:Connect(inputChanged)
        v6 = UserInputService.InputBegan:Connect(inputBegan)
        v7 = UserInputService.InputEnded:Connect(inputEnded)
        v8 = UserInputService.TouchPinch:Connect(inputTouchPinch)
        v24 = v9.Mode:GetPropertyChangedSignal("Value"):Connect(modeChanged)
        v29 = LocalPlayer.Settings.ShareBlocks:GetPropertyChangedSignal("Value"):Connect(function()
            clearSelected()
            removeBoundingBox()
        end)
        ContextActionService:BindAction("TrowelToolShiftSelect", updateHandles, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.ButtonL2)
        v3 = Instance.new("SelectionBox")
        v3.Color3 = Color3.fromRGB(0, 134, 171)
        v3.SurfaceColor3 = Color3.fromRGB(0, 97, 171)
        v3.SurfaceTransparency = 1
        v3.Parent = workspace
        v9.ModeImage.Visible = true
        v9.ModeButton.Visible = true
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local processedTools = {}

local function processTool(tool)
    if processedTools[tool] then return end
    if tool.Name == "BuildingTool" then
        processedTools[tool] = true
        dprint("Setting up BuildingTool modification")
        setupBuildingTool(tool)
    elseif tool.Name == "ScalingTool" then
        processedTools[tool] = true
        dprint("Setting up ScalingTool modification")
        setupScalingTool(tool)
    elseif tool.Name == "TrowelTool" then
        processedTools[tool] = true
        dprint("Setting up TrowelTool modification")
        setupTrowelTool(tool)
    end
end

local function scanInventory()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local character = LocalPlayer.Character
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            processTool(item)
        end
    end
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                processTool(item)
            end
        end
    end
end

LocalPlayer.ChildAdded:Connect(function(child)
    if child:IsA("Backpack") then
        child.ChildAdded:Connect(processTool)
    end
end)

local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
if backpack then
    backpack.ChildAdded:Connect(processTool)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            processTool(child)
        end
    end)
    task.wait(0.5)
    scanInventory()
end)

task.spawn(function()
    while true do
        scanInventory()
        task.wait(1)
    end
end)

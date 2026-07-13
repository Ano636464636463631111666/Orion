local debugp = false
local function dprint(...)
    if debugp then print("[DEBUG]", ...) end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")

local LocalPlayer = Players.LocalPlayer

_G.DisableToolLimit = _G.DisableToolLimit or false
_G.FullPlace = _G.FullPlace or false

local function setupBuildTool(tool)
    local localScript = tool:FindFirstChildOfClass("LocalScript")
    if localScript then localScript.Disabled = true end
    
    local v1 = LocalPlayer:GetMouse()
    local v2 = tool
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local v3, v4, v5, v6, v7, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26
    local v8 = CFrame.new()

    local function isPartInZone(p1, p2)
        if _G.DisableToolLimit then return true end
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
        if _G.DisableToolLimit then return true, nil end
        local v2z = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v32 = isPartInZone(p1.PrimaryPart, v2z)
        local v4z = if v32 then nil else "Out of bounds"
        local v5z, v6z = QuestConditions(v2z, p1.PrimaryPart.CFrame, v3.Name, 1, LocalPlayer)
        local v7z, v8z = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
        local v9z, v10z = ChallengeConditions.itemRestriction(LocalPlayer, v3.Name)
        return if v32 then if v5z then not v7z and not v9z else v5z else v32, if v4z then v4z elseif v6z then v6z elseif v8z then v8z else v10z
    end

    local function roundVectorToBase(p1, p2)
        local rv1 = 1 / p2
        local rv2 = p1 * rv1 + Vector3.new(0.5, 0.5, 0.5)
        return Vector3.new(math.floor(rv2.X), math.floor(rv2.Y), (math.floor(rv2.Z))) / rv1
    end

    local function normalIdToNormalVector(p1, p2)
        if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
        if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
        if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
        return Vector3.new(-1, 0, 0), p2.Size.X
    end

    local function changeTransparency(p1, p2)
        local tr1 = p1:GetDescendants()
        for i = 1, #tr1 do
            if tr1[i]:IsA("BasePart") then
                if CollectionService:HasTag(tr1[i], "NoTransparency") then tr1[i].Transparency = 0 continue end
                if CollectionService:HasTag(tr1[i], "FullTransparency") then tr1[i].Transparency = 1 continue end
                tr1[i].Transparency = p2
            end
        end
    end

    local function updateBlockCF(p1)
        if not v1.Target then return end
        local v12b = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
        if not p1 then
            v5 = v1.Target
            v6 = v1.Hit
            v7 = v1.TargetSurface
        end
        local v2b = v8
        local v32b = (v5.CFrame - v5.Position):Inverse()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v32b = CFrame.new(0, 0, 0)
        end
        local v52b, v62b = normalIdToNormalVector(v7, v5)
        local v82b = v5.CFrame * CFrame.new(v52b * (v62b / 2))
        v12b:SetPrimaryPartCFrame(v82b * v32b * v2b)
        local v9b = (v5.CFrame - v5.Position):PointToWorldSpace(v52b)
        local v10b = v12b.PrimaryPart.CFrame.RightVector:Dot(v9b)
        local v112b = v12b.PrimaryPart.CFrame.UpVector:Dot(v9b)
        local v122b = v12b.PrimaryPart.CFrame.LookVector:Dot(v9b)
        local v13b = math.abs(v10b)
        local v14b = math.abs(v112b)
        local v15b = math.abs(v122b)
        v12b:SetPrimaryPartCFrame(v82b * v32b:Inverse() * v2b:Inverse())
        local v17b = v82b * CFrame.new(v52b * (v13b * (v12b.PrimaryPart.Size.X / 2) + v14b * (v12b.PrimaryPart.Size.Y / 2) + v15b * (v12b.PrimaryPart.Size.Z / 2)))
        local v18b = v5.CFrame:PointToObjectSpace(v6.p)
        local v19b = if v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom then v18b - Vector3.new(0, v18b.Y, 0) elseif v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back then v18b - Vector3.new(0, 0, v18b.Z) else v18b - Vector3.new(v18b.X, 0, 0)
        local v20b = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
        if v20b ~= 0 then v19b = roundVectorToBase(v19b, v20b) end
        v12b:SetPrimaryPartCFrame(v17b * CFrame.new(v19b) * v32b * v2b)
        if not v3:FindFirstChild("CanPlace") then
            local CanPlace = Instance.new("BoolValue")
            CanPlace.Name = "CanPlace"
            CanPlace.Value = true
            CanPlace.Parent = v3
        end
        local v22b = canPlace(v12b)
        if v3.CanPlace.Value or not v22b then
            if not v3.CanPlace.Value or v22b then return end
            v3.CanPlace.Value = false
            v11 = {}
            local v23b = v3:GetDescendants()
            for i = 1, #v23b do
                if v23b[i]:IsA("BasePart") then
                    table.insert(v11, v23b[i].Color)
                    v23b[i].BrickColor = BrickColor.Red()
                end
            end
        else
            v3.CanPlace.Value = true
            local v25b = v3:GetDescendants()
            local count = 1
            for j = 1, #v25b do
                if v25b[j]:IsA("BasePart") then
                    v25b[j].Color = v11[count]
                    count = count + 1
                end
            end
            if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
        end
    end

    local function WeldTogether(p1, p2, p3, p4)
        if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then return end
        local w1 = Instance.new(p3 or "Weld")
        w1.Part0 = p1
        w1.Part1 = p2
        w1.C0 = CFrame.new()
        w1.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
        w1.Parent = p4 or p1
        return w1
    end

    local function prepareItem()
        v1.TargetFilter = v3
        changeTransparency(v3, 0.5)
        local v12p = v3:GetDescendants()
        for i = 1, #v12p do
            if v12p[i]:IsA("BasePart") then
                v12p[i].Anchored = true
                v12p[i].CanCollide = false
                v12p[i].CanQuery = false
                if v12p[i] ~= v3.PrimaryPart then WeldTogether(v3.PrimaryPart, v12p[i]) end
            end
        end
    end

    local function isSpeedBuild()
        local SpeedBuild = LocalPlayer.OtherData:FindFirstChild("SpeedBuild")
        if SpeedBuild and SpeedBuild.Value then return true end
        return nil
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
        local f1 = ScrollingFrame.BlocksFrame:GetChildren()
        local f2, f3 = nil, nil
        for i = 1, #f1 do
            if f1[i]:IsA("GuiObject") and f1[i].Visible then
                if not f2 or f2 < f1[i].AbsolutePosition.Y then f2 = f1[i].AbsolutePosition.Y end
                if not f3 or f1[i].AbsolutePosition.Y < f3 then f3 = f1[i].AbsolutePosition.Y end
            end
        end
        if f3 and f2 then
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, f2 - f3 + 100)
            return
        end
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end

    local function getType(p1)
        local gt1 = string.match(p1.TypeIcon.Image, "%d+")
        if gt1 == "4597411234" then return "Block" end
        if gt1 == "4597402658" then return "Decoration" end
        return "Special"
    end

    local function updateBuildGui()
        local u1 = LocalPlayer
        local u2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if u2 and LocalPlayer.Settings.ShareBlocks.Value then u1 = u2 end
        local u3 = u1.Name
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        local SearchFrame = BuildGui.SearchFrame
        local u4 = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
        local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local u5 = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()
        for i = 1, #u5 do
            local u6 = u5[i]
            if game.ReplicatedStorage.BuildingParts:FindFirstChild(u6.Name) then
                local u8 = getType(u6)
                local u9 = game.Players:FindFirstChild(u3).Data[u6.Name].Value
                local u10 = string.split(u6.Tags.Value, " ")
                local u11 = false
                if SearchFrame.OnlySearch.Value then
                    local ok, result = pcall(function() return LocalizationService:GetTranslatorForPlayerAsync(game.Players.LocalPlayer) end)
                    if ok then
                        local u13 = string.lower((result:Translate(TagsFrame.Parent.BlockName, u6.BlockName.Value)))
                        if string.find(u13, u4) or string.find(u4, u13) then u11 = true end
                        if not u11 then
                            for j = 1, #u10 do
                                local u15 = string.lower((result:Translate(TagsFrame, u10[j])))
                                if string.find(u15, u4) or string.find(u4, u15) then u11 = true break end
                            end
                        end
                    end
                end
                if (u9 == 0 and not _G.DisableToolLimit) or SearchFrame.OnlyBlocks.Value and u8 ~= "Block" or (SearchFrame.OnlyDecorations.Value and u8 ~= "Decoration" or SearchFrame.OnlySpecial.Value and u8 ~= "Special") then
                    u6.Visible = false
                else
                    if SearchFrame.OnlySearch.Value and not u11 then u6.Visible = false continue end
                    u6.Visible = true
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
            local r1 = workspace
            local r2 = r1[tostring(LocalPlayer.TeamColor) .. "Zone"]
            v8 = (r2.CFrame - r2.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
        end
    end

    local function itemChanged(forcedName)
        local Selected = forcedName or LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
        local ic1 = game.ReplicatedStorage.BuildingParts:FindFirstChild(Selected)
        updateBuildGui()
        local ic2 = v3 and v3.PrimaryPart and v3.PrimaryPart.CFrame or CFrame.new()
        if v3 then v3:Destroy() end
        v3 = ic1:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(ic2.p) * ic1.PrimaryPart.CFrame.Rotation)
        resetRotation()
        prepareItem()
        updateBlockCF()
        v3.Parent = workspace
        local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local ic32 = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
        local ic4 = TagsFrame:GetChildren()
        local TextLabel = TagsFrame.TextLabel
        for i = 1, #ic32 do
            local ic5 = TextLabel:Clone()
            ic5.Text = string.lower(ic32[i])
            ic5.Parent = TextLabel.Parent
        end
        for j = 1, #ic4 do ic4[j]:Destroy() end
        TagsFrame.Parent.BlockName.Text = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].BlockName.Value
        TagsFrame.Parent.StrengthFrame.TextLabel.Text = tostring(game.ReplicatedStorage.BuildingParts[Selected].Health.Value)
    end

    local function rotateY()
        v8 = v8 * CFrame.Angles(0, math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0)
        updateBlockCF(true)
    end

    local function rotateX()
        v8 = v8 * CFrame.Angles(math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0, 0)
        updateBlockCF(true)
    end

    local function executePlacement(p1)
        local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
        local v9b = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"
        if v9b then
            local v10b = v3:FindFirstChild("2ndPlacement")
            if not v10b then
                local v11b = Instance.new("BoolValue")
                v11b.Name = "2ndPlacement"
                v11b.Parent = v3
                updateBlockCF()
                return
            end
            v10b:Destroy()
        end
        local v122 = if v9b then v3.SecondaryPart.PrimaryPart.CFrame else v9b
        changeTransparency(v3, 0)
        game.Debris:AddItem(v3, 10)
        local v13b = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
        local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
        local v15b = v2.ClickSound:Clone()
        v15b.Parent = v3.PrimaryPart
        game.Debris:AddItem(v15b, 1)
        v15b.PlaybackSpeed = 1
        v15b:Play()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then resetRotation() end
        local v16b = v3
        v3 = v3:Clone()
        changeTransparency(v3, 0.5)
        v3.Parent = workspace
        v1.TargetFilter = v3
        local v17b = v16b:GetDescendants()
        for i = 1, #v17b do
            if v17b[i]:IsA("BasePart") then v17b[i].CanQuery = true end
        end
        local v19b = v5
        updateBlockCF(p1)
        updateBuildGui()
        if not v9b then
            v2.RF:InvokeServer(v16b.Name, LocalPlayer.Data:FindFirstChild(v16b.Name).Value, v19b, v13b, Anchor, v16b.PrimaryPart.CFrame, v122)
            v16b:Destroy()
            return
        end
        local v20b = game.ReplicatedStorage.BuildingParts[v3.Name]
        v3.SecondaryPart.PrimaryPart.CFrame = v3.PrimaryPart.CFrame * v20b.PrimaryPart.CFrame:ToObjectSpace(v20b.SecondaryPart.PrimaryPart.CFrame)
        v2.RF:InvokeServer(v16b.Name, LocalPlayer.Data:FindFirstChild(v16b.Name).Value, v19b, v13b, Anchor, v16b.PrimaryPart.CFrame, v122)
        v16b:Destroy()
    end

    local function placeBlock(p1)
        if v25 or not v3 then return end
        if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
        local v22b, v32b = canPlace(v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3)
        if not v22b then
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
            TextLabel.Text = v32b
            TextLabel.TextColor3 = Color3.fromRGB(255, 106, 106)
            TextLabel.TextScaled = true
            TextLabel.TextWrapped = true
            TextLabel.TextStrokeTransparency = 0
            TextLabel.TextStrokeColor3 = Color3.fromRGB(91, 32, 32)
            TextLabel.Parent = OutOfBoundsBG
            OutOfBoundsBG.Parent = v3
            game.Debris:AddItem(OutOfBoundsBG, 1.5)
            return
        end
        v25 = true
        task.spawn(function() task.wait() v25 = false end)
        
        local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
        local AmountText = v52.AmountText
        local currentAmount = tonumber(AmountText.Text) or 0
        
        if currentAmount <= 0 and not _G.DisableToolLimit then
            local v6b = v2.ClickSound:Clone()
            v6b.Parent = v3.PrimaryPart
            game.Debris:AddItem(v6b, 0.3)
            v6b.PlaybackSpeed = 5
            v6b:Play()
            LocalPlayer.PlayerGui.BuildGui.SearchFrame.ClearFilter:Invoke()
            local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
            ScrollingFrame.CanvasPosition = ScrollingFrame.CanvasPosition + Vector2.new(0, v52.AbsolutePosition.Y - 252 + (251 - LocalPlayer.PlayerGui.BuildGui.InventoryFrame.AbsolutePosition.Y))
            if not v52.MaxText.Visible then
                AmountText.Visible = false
                v52.MaxText.Visible = true
                task.wait(0.5)
                AmountText.Visible = true
                v52.MaxText.Visible = false
            end
        else
            if _G.FullPlace and currentAmount > 1 then
                task.spawn(function()
                    for i = 1, currentAmount do
                        if not v3 then break end
                        executePlacement(p1)
                        task.wait(0.2)
                    end
                end)
            else
                executePlacement(p1)
            end
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
            if p1.KeyCode == Enum.KeyCode.R then rotateY() elseif p1.KeyCode == Enum.KeyCode.T then rotateX() end
        else
            if p1.UserInputType == Enum.UserInputType.MouseButton1 then placeBlock()
            elseif p1.UserInputType == Enum.UserInputType.Touch then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                if isSpeedBuild() then v10 = v1.Hit else updateBlockCF() end
            elseif p1.UserInputType == Enum.UserInputType.Gamepad1 then
                if p1.KeyCode == Enum.KeyCode.ButtonR2 then placeBlock() elseif p1.KeyCode == Enum.KeyCode.ButtonX then rotateY() elseif p1.KeyCode == Enum.KeyCode.ButtonY then rotateX() end
            end
        end
    end

    local function inputEnded(p1, p2)
        if p2 or (p1.UserInputType ~= Enum.UserInputType.Touch or not (isSpeedBuild() and (v1.Hit.p - v10.p).Magnitude < 1)) then return end
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
        dprint("Build tool unequipped")
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
        v19 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected:GetPropertyChangedSignal("Value"):Connect(function() itemChanged() end)
        v20 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyBlocks:GetPropertyChangedSignal("Value"):Connect(function() updateBuildGui() LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0) end)
        v21 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlyDecorations:GetPropertyChangedSignal("Value"):Connect(function() updateBuildGui() LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0) end)
        v22 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySpecial:GetPropertyChangedSignal("Value"):Connect(function() updateBuildGui() LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0) end)
        v23 = LocalPlayer.PlayerGui.BuildGui.SearchFrame.OnlySearch:GetPropertyChangedSignal("Value"):Connect(function() updateBuildGui() LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.CanvasPosition = Vector2.new(0, 0) end)
        v24 = LocalPlayer.Character.Humanoid.Died:Connect(uneq)
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
        dprint("Build tool equipped")
    end

    v2.Equipped:Connect(eq)
    v2.Unequipped:Connect(uneq)
end

local function setupScalingTool(tool)
    local localScript = tool:FindFirstChildOfClass("LocalScript") or tool:FindFirstChild("ScaleLocalScript")
    if localScript then localScript.Disabled = true end

    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local CurrentCamera = workspace.CurrentCamera
    local v1 = LocalPlayer:GetMouse()
    local v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15
    local v16 = false
    local v17 = false

    local function isPartInZone(p1, p2)
        if _G.DisableToolLimit then return true end
        local v1z = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X, Y, Z = Size.X, Size.Y, Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then X = Size.Z Z = Size.X end
        return v1z.X > Position.X - X / 2 and (v1z.X < Position.X + X / 2 and (v1z.Z > Position.Z - Z / 2 and v1z.Z < Position.Z + Z / 2))
    end

    local function canSelect(p1)
        if v16 then return false, p1 end
        local v1b, _, v2b = GetBlockInfo(p1, LocalPlayer)
        if _G.DisableToolLimit then return true, v1b or p1 end
        if v2b and string.find(v1b.Name, "Block") then return true, v1b end
        return false
    end

    local function updateBlocks()
        local u1 = LocalPlayer
        local u2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if u2 and LocalPlayer.Settings.ShareBlocks.Value then u1 = u2 end
        local v5b = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v6b = v4.Adornee.Parent.Name
        v13 = game.Players:FindFirstChild(u1.Name).Data:FindFirstChild(v6b).Value
        local v7b = workspace.Blocks:GetChildren()
        local sum = 0
        for i = 1, #v7b do
            local v8b = v7b[i]:GetChildren()
            for j = 1, #v8b do
                local v9b = v8b[j]
                local _, _2, v10b = GetBlockInfo(v9b, LocalPlayer)
                if v10b and (v9b.Name == v6b and (v9b.PrimaryPart and isPartInZone(v9b.PrimaryPart, v5b))) then
                    sum = sum + math.max(v9b.PrimaryPart.Size.X * v9b.PrimaryPart.Size.Y * v9b.PrimaryPart.Size.Z / v15, 1)
                end
            end
        end
        v14 = sum
        v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
        v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(v6b).Image
        v12.Parent = LocalPlayer.PlayerGui
    end

    local function updateBlocksSoft(p1, p2)
        local u1 = LocalPlayer
        local u2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if u2 and LocalPlayer.Settings.ShareBlocks.Value then u1 = u2 end
        v13 = game.Players:FindFirstChild(u1.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
        v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)
        local v7b = math.floor(v13 - v14)
        v12.BlockImage.AmountText.Text = tostring(v7b)
        return v7b
    end

    local function lockCameraRotation()
        v17 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
        local v1c = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2c = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2c + CameraSubject.CFrame.p - v1c
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

    local function mouseMove(p1)
        local Target = v1.Target
        if not (Target and Target.Parent) then v2.Adornee = nil return end
        local v12m, v22m = canSelect(Target)
        if v4 and (v2.Adornee and v4.Adornee == v2.Adornee.PrimaryPart) then v2.Adornee = nil end
        if v4 and (v22m and (v22m:IsA("Model") and v4.Adornee == v22m.PrimaryPart)) then v2.Adornee = nil return end
        if v2.Adornee == v22m then return end
        if v12m then
            v2.Adornee = v22m
            local Size = v22m.PrimaryPart and v22m.PrimaryPart.Size or Vector3.new(2,2,2)
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

    local function activeHandle(p1)
        if not v2 then return end
        local Adornee = v2.Adornee
        if Adornee == nil then return end
        local v1a, v22a = canSelect(Adornee)
        if v1a then
            local Size = v22a.PrimaryPart and v22a.PrimaryPart.Size or Vector3.new(2,2,2)
            local partData = game.ReplicatedStorage.BuildingParts:FindFirstChild(v22a.Name)
            local Size2 = partData and partData.PrimaryPart and partData.PrimaryPart.Size or Vector3.new(2,2,2)
            v15 = Size2.X * Size2.Y * Size2.Z
            if v4 then v4.Adornee = v22a.PrimaryPart or v22a else
                v4 = Instance.new("Handles")
                v4.Adornee = v22a.PrimaryPart or v22a
                v4.Style = Enum.HandlesStyle.Resize
                v4.Color3 = Color3.fromRGB(172, 78, 1)
                v4.Parent = LocalPlayer.PlayerGui
            end
            local v3a, v42a, v52a, v62a = nil, nil, nil, nil
            if v7 then v7:Disconnect() v7 = nil end
            v7 = v4.MouseButton1Down:Connect(function()
                v16 = true
                v3a = v4.Adornee.CFrame
                v52a = v4.Adornee.Size
                v4.Adornee:BreakJoints()
                v4.Adornee.Anchored = true
                if not p1 then return end
                checkToLockCameraRotation()
            end)
            local SizeDisplay = v12.BlockImage.SizeDisplay
            SizeDisplay.Text = tostring(v4.Adornee.Size.X) .. "," .. tostring(v4.Adornee.Size.Y) .. "," .. tostring(v4.Adornee.Size.Z)
            if v8 then v8:Disconnect() v8 = nil end
            v8 = v4.MouseDrag:Connect(function(p1m, p2m)
                local v1m = tonumber(v12.BlockImage.More.Scale.TextBox.Text) or 1
                if v1m ~= 0 then p2m = p2m - p2m % v1m end
                if p1m == Enum.NormalId.Right then
                    if v52a.X + p2m <= 0.05 then
                        local vr = v52a.X % v1m
                        if v1m == 0 then vr = 0.05 end
                        if vr < 0.05 then vr = v1m end
                        v62a = Vector3.new(vr, v52a.Y, v52a.Z)
                        v42a = v3a * CFrame.new(-(v52a.X - v62a.X) / 2, 0, 0)
                    else v42a = v3a * CFrame.new(p2m / 2, 0, 0) v62a = v52a + Vector3.new(p2m, 0, 0) end
                elseif p1m == Enum.NormalId.Left then
                    if v52a.X + p2m <= 0.05 then
                        local vl = v52a.X % v1m
                        if v1m == 0 then vl = 0.05 end
                        if vl <= 0.05 then vl = v1m end
                        v62a = Vector3.new(vl, v52a.Y, v52a.Z)
                        v42a = v3a * CFrame.new(-(-(v52a.X - v62a.X)) / 2, 0, 0)
                    else v42a = v3a * CFrame.new(-p2m / 2, 0, 0) v62a = v52a + Vector3.new(p2m, 0, 0) end
                elseif p1m == Enum.NormalId.Top then
                    if v52a.Y + p2m <= 0.05 then
                        local vt = v52a.Y % v1m
                        if v1m == 0 then vt = 0.05 end
                        if vt <= 0.05 then vt = v1m end
                        v62a = Vector3.new(v52a.X, vt, v52a.Z)
                        v42a = v3a * CFrame.new(0, -(v52a.Y - v62a.Y) / 2, 0)
                    else v42a = v3a * CFrame.new(0, p2m / 2, 0) v62a = v52a + Vector3.new(0, p2m, 0) end
                elseif p1m == Enum.NormalId.Bottom then
                    if v52a.Y + p2m <= 0.05 then
                        local vb = v52a.Y % v1m
                        if v1m == 0 then vb = 0.05 end
                        if vb <= 0.05 then vb = v1m end
                        v62a = Vector3.new(v52a.X, vb, v52a.Z)
                        v42a = v3a * CFrame.new(0, -(-(v52a.Y - v62a.Y)) / 2, 0)
                    else v42a = v3a * CFrame.new(0, -p2m / 2, 0) v62a = v52a + Vector3.new(0, p2m, 0) end
                elseif p1m == Enum.NormalId.Back then
                    if v52a.Z + p2m <= 0.05 then
                        local vbk = v52a.Z % v1m
                        if v1m == 0 then vbk = 0.05 end
                        if vbk <= 0.05 then vbk = v1m end
                        v62a = Vector3.new(v52a.X, v52a.Y, vbk)
                        v42a = v3a * CFrame.new(0, 0, -(v52a.Z - v62a.Z) / 2)
                    else v42a = v3a * CFrame.new(0, 0, p2m / 2) v62a = v52a + Vector3.new(0, 0, p2m) end
                elseif p1m == Enum.NormalId.Front then
                    if v52a.Z + p2m <= 0.05 then
                        local vf = v52a.Z % v1m
                        if v1m == 0 then vf = 0.05 end
                        if vf <= 0.05 then vf = v1m end
                        v62a = Vector3.new(v52a.X, v52a.Y, vf)
                        v42a = v3a * CFrame.new(0, 0, -(-(v52a.Z - v62a.Z)) / 2)
                    else v42a = v3a * CFrame.new(0, 0, -p2m / 2) v62a = v52a + Vector3.new(0, 0, p2m) end
                end
                v62a = Vector3.new(math.max(v62a.X, 0.05), math.max(v62a.Y, 0.05), (math.max(v62a.Z, 0.05)))
                local v19a = v62a.X * v62a.Y * v62a.Z / v15 - Size.X * Size.Y * Size.Z / v15
                local v21a = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local v22a = _G.DisableToolLimit or (isPartInZone(v42a * CFrame.new(v62a.X / 2, 0, 0), v21a) and isPartInZone(v42a * CFrame.new(-v62a.X / 2, 0, 0), v21a))
                local v23a = updateBlocksSoft(v4.Adornee.Size, v62a)
                local v24a = not _G.DisableToolLimit and ChallengeConditions.blockLimitChallengeReached(LocalPlayer, v19a)
                if _G.DisableToolLimit or (v23a >= 0 and v22a and not v24a) then
                    if v4.Adornee.Size == v62a then return end
                    v4.Adornee:BreakJoints()
                    v4.Adornee.CFrame = v42a or v3a
                    v4.Adornee.Size = v62a or v52a
                    v12.BlockImage.SizeDisplay.Text = tostring(v4.Adornee.Size.X) .. "," .. tostring(v4.Adornee.Size.Y) .. "," .. tostring(v4.Adornee.Size.Z)
                    return
                end
                updateBlocksSoft(v62a, v4.Adornee.Size)
                if v24a then LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame.Visible = true else v12.BlockImage.MaxText.Visible = true v12.BlockImage.AmountText.Visible = false end
                local v32a = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone()
                if v32a then v32a.Parent = v4.Adornee game.Debris:AddItem(v32a, 0.3) v32a.PlaybackSpeed = 5 v32a:Play() end
                if not v24a then task.wait(0.5) v12.BlockImage.MaxText.Visible = false v12.BlockImage.AmountText.Visible = true return end
                task.wait(3)
                LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame.Visible = false
            end)
            if v6 then v6:Disconnect() v6 = nil end
            v6 = v4.MouseButton1Up:Connect(function()
                v3a = v4.Adornee.CFrame
                v52a = v4.Adornee.Size
                local v1r, v2r = tool.RF:InvokeServer(v4.Adornee.Parent, v52a, v3a)
                Size = v52a
                if v1r then v22a.PrimaryPart.Size = v1r v22a.PrimaryPart.CFrame = v2r updateBlocks() end
                v16 = false
                if not p1 then return end
                checkToUnlockCameraRotation()
            end)
            if v5 then v5:Disconnect() v5 = nil end
            v5 = tool.Unequipped:Connect(function()
                v3a = v4.Adornee.CFrame
                v52a = v4.Adornee.Size
                local v1r, v2r = tool.RF:InvokeServer(v4.Adornee.Parent, v52a, v3a)
                Size = v52a
                if v1r and v22a and v22a.PrimaryPart then v22a.PrimaryPart.Size = v1r v22a.PrimaryPart.CFrame = v2r end
                v16 = false
                if v5 then v5:Disconnect() v5 = nil end
            end)
            updateBlocks()
        end
        mouseMove()
    end

    local function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then activeHandle()
        elseif p1.UserInputType == Enum.UserInputType.Touch then mouseMove(true)
        elseif p1.UserInputType == Enum.UserInputType.Gamepad1 and p1.KeyCode == Enum.KeyCode.ButtonR2 then activeHandle() end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement or p1.KeyCode == Enum.KeyCode.Thumbstick1 or p1.KeyCode == Enum.KeyCode.Thumbstick2 then
            mouseMove(false)
        end
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
        if v4 then v4:Destroy() v4 = nil end
        v12.BlockImage.Visible = false
        checkToUnlockCameraRotation()
        dprint("Scale tool unequipped")
    end

    local function eq()
        v12 = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScaleToolDisplayGui")
        v12.BlockImage.SizeDisplay.Text = ""
        v3 = LocalPlayer.Character.Humanoid.Died:Connect(uneq)
        v9 = UserInputService.InputChanged:Connect(inputChanged)
        v10 = UserInputService.InputBegan:Connect(inputBegan)
        v11 = LocalPlayer.PlayerGui:WaitForChild("TabletToolGui"):WaitForChild("Frame"):WaitForChild("Place").MouseButton1Down:Connect(function()
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
            activeHandle(true)
        end)
        v2 = Instance.new("SelectionBox", workspace)
        v2.Color3 = Color3.fromRGB(172, 109, 0)
        v2.SurfaceColor3 = Color3.fromRGB(172, 172, 0)
        v2.SurfaceTransparency = 0.5
        v12.BlockImage.Visible = true
        dprint("Scale tool equipped")
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function setupTrowelTool(tool)
    local localScript = tool:FindFirstChildOfClass("LocalScript") or tool:FindFirstChild("TrowelLocalScript")
    if localScript then localScript.Disabled = true end

    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local v1 = LocalPlayer:GetMouse()
    local CurrentCamera = workspace.CurrentCamera
    local v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v24, v26, v29
    local t, t2 = {}, {}
    local v14, v15, v23, v25, v27, v28 = false, false, false, false, false, false
    local v30 = 0
    local v31 = nil

    local function isMobilePlayer() return UserInputService:GetLastInputType() == Enum.UserInputType.Touch end
    local function getSelectedModels() local r = {} for k, v in pairs(t) do table.insert(r, k) end return r end

    local function getBlockValue(p1)
        if _G.DisableToolLimit then return 1 end
        local v1b = p1.Name
        if string.find(v1b, "Block") then
            local Size = game.ReplicatedStorage.BuildingParts[v1b].PrimaryPart.Size
            local Size2 = p1.PrimaryPart.Size
            return math.max(Size2.X * Size2.Y * Size2.Z / (Size.X * Size.Y * Size.Z), 1)
        end
        return 1
    end

    local function updateBlockDisplayImage(p1)
        if v9.ModeImage.MaxText.Visible then return end
        local v1i = nil
        local v2i, v3i = true, true
        for k, v in pairs(t2) do
            v2i = false
            if v1i then v3i = true break end
            v1i = k
            v3i = false
        end
        if v2i then v9.ModeImage.Image = "" v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0) return end
        if v3i then
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
        else
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v1i].Image
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
        local _, v1b = p1:GetBoundingBox()
        TrowelSB.LineThickness = math.min(v1b.X, v1b.Y, v1b.Z, 2) / 50
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
        local v1b = t[p1]
        if v1b then v1b:Destroy() end
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
        if _G.DisableToolLimit then return true end
        local v1z = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X, Y, Z = Size.X, Size.Y, Size.Z
        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then X = Size.Z Z = Size.X end
        return v1z.X > Position.X - X / 2 and (v1z.X < Position.X + X / 2 and (v1z.Z > Position.Z - Z / 2 and v1z.Z < Position.Z + Z / 2))
    end

    local function doingShiftSelect()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()
    end

    local function lockCameraRotation()
        v15 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
        local v1c = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2c = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2c + CameraSubject.CFrame.p - v1c
        end)
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v15 = false
    end

    local function checkToLockCameraRotation() if v15 then return end lockCameraRotation() end
    local function checkToUnlockCameraRotation() if not v15 then return end unlockCameraRotation() end

    local function GetBoundingBox(p1, p2)
        local abs = math.abs
        local v1b, v2b, v3b, v4b, v5b, v6b = (1 / 0), (-1 / 0), (-1 / 0), (-1 / 0), (1 / 0), (1 / 0)
        for i = 1, #p1 do
            local PrimaryPart = p1[i].PrimaryPart
            if PrimaryPart then
                local v7b = p2:toObjectSpace(PrimaryPart.CFrame)
                local Size = PrimaryPart.Size
                local X, Y, Z = Size.X, Size.Y, Size.Z
                local v8b, v9b, v10b, v11b, v12b, v13b, v14b, v15b, v16b, v17b, v18b, v19b = v7b:components()
                local v20b = 0.5 * (abs(v11b) * X + abs(v12b) * Y + abs(v13b) * Z)
                local v21b = 0.5 * (abs(v14b) * X + abs(v15b) * Y + abs(v16b) * Z)
                local v22b = 0.5 * (abs(v17b) * X + abs(v18b) * Y + abs(v19b) * Z)
                if v8b - v20b < v5b then v5b = v8b - v20b end
                if v9b - v21b < v6b then v6b = v9b - v21b end
                if v10b - v22b < v1b then v1b = v10b - v22b end
                if v2b < v8b + v20b then v2b = v8b + v20b end
                if v3b < v9b + v21b then v3b = v9b + v21b end
                if v4b < v10b + v22b then v4b = v10b + v22b end
            end
        end
        local v23b = Vector3.new(v5b, v6b, v1b)
        local v24b = Vector3.new(v2b, v3b, v4b)
        return p2 - p2.p + p2:pointToWorldSpace((v24b + v23b) / 2), v24b - v23b
    end

    local function removeBoundingBox()
        if v11 then v11:Destroy() v11 = nil end
        if v12 then v12:Destroy() v12 = nil end
        if v13 then v13:Destroy() v13 = nil end
    end

    local function updateHandles()
        if not (v12 and v13) then return end
        v12.Visible = false
        v13.Visible = false
        local v1h = isMobilePlayer() or not doingShiftSelect()
        if v11 then v11:FindFirstChild("SelectionBox") end
        local Mode = v9.Mode.Value
        if Mode == "Move" then v12.Color3 = Color3.fromRGB(13, 105, 172) v12.Visible = v1h v12.Style = "Movement" return end
        if Mode == "Rotate" then v13.Visible = v1h return end
        if Mode == "Clone" then v12.Color3 = Color3.fromRGB(20, 255, 169) v12.Visible = v1h v12.Style = "Movement" return end
        if Mode ~= "Mirror" then return end
        v12.Color3 = Color3.fromRGB(248, 37, 255) v12.Visible = v1h v12.Style = "Resize"
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
            v17 = v12.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v12.Adornee.CFrame
                v11:BreakJoints()
                v12.Faces = Faces.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            v16 = v12.MouseButton1Up:Connect(function(p1)
                local v1o = v22
                v22 = v12.Adornee.CFrame
                v14 = false
                v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                local Mode2 = v9.Mode.Value
                if v1o == v22 and Mode2 ~= "Mirror" then return end
                if Mode2 == "Mirror" then
                    local v2o = nil
                    if p1 == Enum.NormalId.Right then v2o = Vector3.new(v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Left then v2o = Vector3.new(-v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Top then v2o = Vector3.new(0, v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Bottom then v2o = Vector3.new(0, -v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Back then v2o = Vector3.new(0, 0, v11.size.Z / 2)
                    elseif p1 == Enum.NormalId.Front then v2o = Vector3.new(0, 0, -v11.size.Z / 2) end
                    v22 = CFrame.new((v1o * CFrame.new(v2o)).p, v1o.p)
                end
                performServerOperatoin(v1o, v22)
            end)
            v18 = v12.MouseDrag:Connect(function(p1, p2)
                if v9.Mode.Value == "Mirror" then return end
                local v1o = tonumber(v9.ModeImage.More.Scale.TextBox.Text) or 1
                if v1o ~= 0 then p2 = p2 - p2 % v1o end
                local v2o = nil
                if p1 == Enum.NormalId.Right then v2o = v22 * CFrame.new(p2, 0, 0)
                elseif p1 == Enum.NormalId.Left then v2o = v22 * CFrame.new(-p2, 0, 0)
                elseif p1 == Enum.NormalId.Top then v2o = v22 * CFrame.new(0, p2, 0)
                elseif p1 == Enum.NormalId.Bottom then v2o = v22 * CFrame.new(0, -p2, 0)
                elseif p1 == Enum.NormalId.Back then v2o = v22 * CFrame.new(0, 0, p2)
                elseif p1 == Enum.NormalId.Front then v2o = v22 * CFrame.new(0, 0, -p2) end
                local v4o = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not _G.DisableToolLimit and not (isPartInZone(v2o * CFrame.new(Size.X / 2, 0, 0), v4o)) then return end
                v11.CFrame = if v2o then v2o else v22
            end)
            v13 = Instance.new("ArcHandles")
            v13.Name = "RotateHandle"
            v13.Adornee = v11
            v13.Visible = false
            v13.Parent = LocalPlayer.PlayerGui
            v20 = v13.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v13.Adornee.CFrame
                v11:BreakJoints()
                v13.Axes = Axes.new(p1)
                if isMobilePlayer() then checkToLockCameraRotation() end
                for k, v in pairs(t) do v.Visible = false end
                v3.Visible = false
            end)
            v19 = v13.MouseButton1Up:Connect(function(p1)
                local v1o = v22
                v22 = v13.Adornee.CFrame
                v14 = false
                v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do v.Visible = true end
                v3.Visible = true
                if v1o == v22 then return end
                performServerOperatoin(v1o, v22)
            end)
            v21 = v13.MouseDrag:Connect(function(p1, p2, p3)
                if math.deg(p2) < -180 then p2 = p2 + 6.283185307179586 elseif math.deg(p2) > 180 then p2 = p2 - 6.283185307179586 end
                local v1o = tonumber(v9.ModeImage.More.Scale.TextBox.Text) or 1
                if v1o ~= 0 then p2 = math.rad(v1o * math.round(math.deg(p2) / v1o)) end
                local v5o = nil
                if p1 == Enum.Axis.X then v5o = v22 * CFrame.Angles(p2, 0, 0)
                elseif p1 == Enum.Axis.Y then v5o = v22 * CFrame.Angles(0, p2, 0)
                elseif p1 == Enum.Axis.Z then v5o = v22 * CFrame.Angles(0, 0, p2) end
                local v7o = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local Size = v11.Size
                if not _G.DisableToolLimit and not (isPartInZone(v5o * CFrame.new(Size.X / 2, 0, 0), v7o)) then return end
                v11.CFrame = if v5o then v5o else v22
            end)
        end
        local v15o = getSelectedModels()
        local v2b = #v15o
        if v2b < 1 then removeBoundingBox() else
            table.sort(v15o, function(p1, p2) if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then return true end end)
            local PrimaryPart = v15o[v2b].PrimaryPart
            if PrimaryPart then
                local v4b, v5b = GetBoundingBox(v15o, PrimaryPart.CFrame - PrimaryPart.Position)
                v11.Size = v5b
                v11.CFrame = v4b
            end
        end
    end

    function performServerOperatoin(p1, p2)
        v23 = true
        local Mode = v9.Mode.Value
        local v1o = getSelectedModels()
        if (Mode == "Clone" or Mode == "Mirror") and not _G.DisableToolLimit then
            local tbl = {}
            local sum = 0
            for i = 1, #v1o do
                local v22b = v1o[i]
                local v3b = v22b.Name
                local v4b = getBlockValue(v22b)
                if tbl[v3b] then tbl[v3b] = tbl[v3b] + v4b else tbl[v3b] = v4b end
                sum = sum + v4b
            end
            local v5b = LocalPlayer
            local v6b = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
            if v6b and LocalPlayer.Settings.ShareBlocks.Value then v5b = v6b end
            local v7b = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, sum)
            for k, v in pairs(tbl) do
                if v5b.Data:FindFirstChild(k) and v5b.Data[k].Value < v5b.Data[k].Used.Value + v or v7b then
                    v23 = false
                    local AmountText = v9.ModeImage.AmountText
                    local MaxText = v9.ModeImage.MaxText
                    local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                    local v8b = true
                    if v7b then if RestrictionMetFrame.Visible then v8b = false else RestrictionMetFrame.Visible = true end
                    elseif MaxText.Visible then v8b = false else
                        MaxText.Visible = true
                        AmountText.Visible = false
                        v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[k].Image
                    end
                    local v92 = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone()
                    if v92 then v92.Parent = script game.Debris:AddItem(v92, 0.3) v92.PlaybackSpeed = 5 v92:Play() end
                    updateBoundingBox()
                    if not v8b then return end
                    if v7b then task.wait(3) RestrictionMetFrame.Visible = false else
                        task.wait(3) MaxText.Visible = false AmountText.Visible = true t2 = {} v9.ModeImage.Image = ""
                        local v10b = getSelectedModels()
                        for j = 1, #v10b do t2[v10b[j].Name] = true end
                        updateBlockDisplayImage()
                    end
                    return
                end
            end
        end
        if v12 then v12:Destroy() end
        if v13 then v13:Destroy() end
        if Mode == "Clone" then
            table.sort(v1o, function(pa, pb) if pa.TrowelSB:GetAttribute("Created") > pb.TrowelSB:GetAttribute("Created") then return true end end)
        end
        local v11b = tool.OperationRF:InvokeServer(v1o, p1, p2, v9.Mode.Value) or {}
        local v122 = LocalPlayer.Character and (tool.Parent and (if tool.Parent == LocalPlayer.Character then LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 else false))
        if Mode == "Clone" then
            v9.SetModeEvent:Fire("Move")
            clearSelected()
            if v122 then
                for k = 1, #v11b do
                    local v132, _, v14b = GetBlockInfo(v11b[k], LocalPlayer)
                    if v14b then addSelection(v132) end
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

    local function mouseMove()
        if v10 then v10.Color3 = Color3.fromRGB(0, 134, 171) end
        local Target = v1.Target
        if not Target or (not Target.Parent or isMobilePlayer()) then v3.Adornee = nil return end
        local v12m, _, v2m = GetBlockInfo(Target, LocalPlayer)
        local v32m = doingShiftSelect()
        v3.Visible = true
        if v32m then
            if t[v12m] then t[v12m].Color3 = Color3.fromRGB(175, 0, 0) v10 = t[v12m] v3.Visible = false end
        else
            if v3.Adornee and t[v3.Adornee] then v3.Adornee = nil end
            if t[v12m] then v3.Visible = false end
        end
        if v2m or _G.DisableToolLimit then
            v3.Adornee = v12m
            local _, v4b = v12m:GetBoundingBox()
            v3.LineThickness = math.min(v4b.X, v4b.Y, v4b.Z, 2) / 13.334
        else v3.Adornee = nil end
    end

    local function activeHandle(p1)
        if not v3 or (v23 or v14) then return end
        local v12a = doingShiftSelect()
        local Adornee = v3.Adornee
        if p1 then
            Adornee = nil
            local v2a, _, v32a = GetBlockInfo(v1.Target, LocalPlayer)
            if (v32a or _G.DisableToolLimit) and v2a then Adornee = v2a end
        end
        if Adornee == nil then
            if v12a then return end
            clearSelected()
            updateBoundingBox()
        else
            local v4a, _, v5a = GetBlockInfo(Adornee, LocalPlayer)
            if not v5a and not _G.DisableToolLimit then return end
            if v12a then if t[v4a or Adornee] then removeSelection(v4a or Adornee) else addSelection(v4a or Adornee) end
            else clearSelected() addSelection(v4a or Adornee) end
            updateBoundingBox()
            updateHandles()
            mouseMove()
        end
    end

    local function checkForDragSelection(p1, p2, p3)
        local v12d = v25 and not p1 or (if p1 then v27 else p1)
        if not v12d then return end
        local SelectionBox = v9.SelectionBox
        local v2d = if p1 and p2 then p2 else v26
        local v32d = if p1 and p3 then p3 else Vector2.new(v1.X, v1.Y)
        SelectionBox.Position = UDim2.new(0, v2d.X, 0, v2d.Y)
        SelectionBox.Size = UDim2.new(0, v32d.X - v2d.X, 0, v32d.Y - v2d.Y)
        if v28 or (v14 or not v2d) then return end
        if not p1 and (v32d - v2d).Magnitude < 24 then return end
        v28 = true
        if p1 then checkToLockCameraRotation() end
        SelectionBox.Visible = true
        while v12d do
            v3.Visible = false
            if not doingShiftSelect() or p1 then clearSelected() end
            local v5d = math.min(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v7d = math.max(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v92d = math.min(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v11d = math.max(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v122d = workspace.Blocks:GetChildren()
            for i = 1, #v122d do
                local v13d = v122d[i]:GetChildren()
                for j = 1, #v13d do
                    local v142d = v13d[j]
                    local _, _2, v15d = GetBlockInfo(v142d, LocalPlayer)
                    if v142d.PrimaryPart and (v15d or _G.DisableToolLimit) then
                        local v16d, v17d = CurrentCamera:WorldToScreenPoint(v142d.PrimaryPart.Position)
                        if v17d and (v92d < v16d.X and (v16d.X < v7d and (v5d < v16d.Y and (v16d.Y < v11d and not v142d:FindFirstChild("TrowelSB"))))) then
                            addSelection(v142d)
                        end
                    end
                end
            end
            task.wait()
            v12d = v25 and not p1 or (if p1 then v27 else p1)
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
            v25 = true v26 = Vector2.new(v1.X, v1.Y) activeHandle()
        elseif p1.UserInputType == Enum.UserInputType.Touch then
            if not v14 then mouseMove() activeHandle(true) end
        elseif p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 and not game:GetService("GuiService").SelectedObject then
                v25 = true v26 = Vector2.new(v1.X, v1.Y) activeHandle()
            end
        else
            if isMobilePlayer() or not doingShiftSelect() then return end
            updateHandles()
        end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement or p1.KeyCode == Enum.KeyCode.Thumbstick1 or p1.KeyCode == Enum.KeyCode.Thumbstick2 then
            checkForDragSelection() mouseMove()
        end
    end

    local function inputEnded(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 or (p1.UserInputType == Enum.UserInputType.Gamepad1 and p1.KeyCode == Enum.KeyCode.ButtonR2) then
            v25 = false
        else
            if isMobilePlayer() or doingShiftSelect() then return end
            updateHandles()
        end
    end

    local function modeChanged() if v12 and v13 then updateBoundingBox() updateHandles() end end

    local function uneq()
        v25 = false v14 = false
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
            v9.ModeImage.Visible = false v9.ModeButton.Visible = false
            checkToUnlockCameraRotation()
            return
        end
        clearSelected() removeBoundingBox()
        v9.ModeImage.Visible = false v9.ModeButton.Visible = false
        checkToUnlockCameraRotation()
        dprint("Trowel tool unequipped")
    end

    local function eq()
        v9 = LocalPlayer.PlayerGui.TrowelToolDisplayGui
        v4 = LocalPlayer.Character.Humanoid.Died:Connect(uneq)
        v5 = UserInputService.InputChanged:Connect(inputChanged)
        v6 = UserInputService.InputBegan:Connect(inputBegan)
        v7 = UserInputService.InputEnded:Connect(inputEnded)
        v24 = v9.Mode:GetPropertyChangedSignal("Value"):Connect(modeChanged)
        v29 = LocalPlayer.Settings.ShareBlocks:GetPropertyChangedSignal("Value"):Connect(function() clearSelected() removeBoundingBox() end)
        ContextActionService:BindAction("TrowelToolShiftSelect", updateHandles, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl, Enum.KeyCode.ButtonL2)
        v3 = Instance.new("SelectionBox")
        v3.Color3 = Color3.fromRGB(0, 134, 171)
        v3.SurfaceColor3 = Color3.fromRGB(0, 97, 171)
        v3.SurfaceTransparency = 1
        v3.Parent = workspace
        v9.ModeImage.Visible = true v9.ModeButton.Visible = true
        dprint("Trowel tool equipped")
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function hookTools(container)
    for _, tool in ipairs(container:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name == "BuildingTool" then
                setupBuildTool(tool)
            elseif tool.Name == "ScalingTool" then
                setupScalingTool(tool)
            elseif tool.Name == "TrowelTool" then
                setupTrowelTool(tool)
            end
        end
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        task.wait(0.1)
        hookTools(LocalPlayer.Backpack)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local backpack = LocalPlayer:WaitForChild("Backpack")
    task.wait(0.5)
    hookTools(backpack)
end)

hookTools(LocalPlayer.Backpack)
if LocalPlayer.Character then
    hookTools(LocalPlayer.Character)
end
dprint("All tools initialized and hooks applied successfully")
	local function normalIdToNormalVector(p1, p2)
		if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
		if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
		if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
		if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
		if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
		return Vector3.new(-1, 0, 0), p2.Size.X
	end

	local function roundVectorToBase(p1, p2)
		local v = 1 / p2
		return Vector3.new(math.floor(p1.X * v + 0.5), math.floor(p1.Y * v + 0.5), math.floor(p1.Z * v + 0.5)) / v
	end

	local function updateBlockCF(p1)
		if not v1.Target or not v3 then return end
		local v12 = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
		if not p1 then v5 = v1.Target v6 = v1.Hit v7 = v1.TargetSurface end
		local v32 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value and CFrame.new() or (v5.CFrame - v5.Position):Inverse()
		local v52, v62 = normalIdToNormalVector(v7, v5)
		local v82 = v5.CFrame * CFrame.new(v52 * (v62 / 2))
		v12:SetPrimaryPartCFrame(v82 * v32 * v8)
		local v9 = (v5.CFrame - v5.Position):PointToWorldSpace(v52)
		local v13 = math.abs(v12.PrimaryPart.CFrame.RightVector:Dot(v9))
		local v14 = math.abs(v12.PrimaryPart.CFrame.UpVector:Dot(v9))
		local v15 = math.abs(v12.PrimaryPart.CFrame.LookVector:Dot(v9))
		v12:SetPrimaryPartCFrame(v82 * v32:Inverse() * v8:Inverse())
		local v17 = v82 * CFrame.new(v52 * (v13 * (v12.PrimaryPart.Size.X / 2) + v14 * (v12.PrimaryPart.Size.Y / 2) + v15 * (v12.PrimaryPart.Size.Z / 2)))
		local v18 = v5.CFrame:PointToObjectSpace(v6.p)
		local v19 = (v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom) and v18 - Vector3.new(0, v18.Y, 0) or ((v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back) and v18 - Vector3.new(0, 0, v18.Z) or v18 - Vector3.new(v18.X, 0, 0))
		local v20 = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
		if v20 ~= 0 then v19 = roundVectorToBase(v19, v20) end
		v12:SetPrimaryPartCFrame(v17 * CFrame.new(v19) * v32 * v8)
		if v3:FindFirstChild("CanPlace") then v3.CanPlace.Value = true end
	end

	local function updateBuildGui()
		local BuildGui = LocalPlayer.PlayerGui:FindFirstChild("BuildGui")
		if not BuildGui then return end
		for _, v in ipairs(BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()) do
			if ReplicatedStorage.BuildingParts:FindFirstChild(v.Name) then v.Visible = true end
		end
	end

	local function rotateY() v8 = v8 * CFrame.Angles(0, math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0) updateBlockCF(true) end
	local function rotateX() v8 = v8 * CFrame.Angles(math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0, 0) updateBlockCF(true) end

	local function placeBlock(p1)
		if v25 or not v3 then return end
		v25 = true task.spawn(function() task.wait() v25 = false end)
		local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
		local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
		local amt = tonumber(v52.AmountText.Text) or 0
		if amt <= 0 and not _G.DisableToolLimit then
			local s = v2:FindFirstChild("ClickSound") and v2.ClickSound:Clone() or Instance.new("Sound")
			s.Parent = v3.PrimaryPart Debris:AddItem(s, 0.3) s.PlaybackSpeed = 5 s:Play()
			return
		end
		local s = v2:FindFirstChild("ClickSound") and v2.ClickSound:Clone() or Instance.new("Sound")
		s.Parent = v3.PrimaryPart Debris:AddItem(s, 1) s.PlaybackSpeed = 1 s:Play()
		local v9 = (v3.Name == "Spring" or v3.Name == "Bar" or v3.Name == "Rope")
		if v9 and not v3:FindFirstChild("2ndPlacement") then
			local b = Instance.new("BoolValue", v3) b.Name = "2ndPlacement" updateBlockCF() return
		elseif v9 then
			local sec = v3:FindFirstChild("2ndPlacement") if sec then sec:Destroy() end
		end
		local v122 = v9 and v3.SecondaryPart.PrimaryPart.CFrame or nil
		local v13 = v5 and v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) or nil
		local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
		local v16 = v3 v3 = v3:Clone() changeTransparency(v3, 0.5) v3.Parent = workspace v1.TargetFilter = v3
		updateBlockCF(p1) updateBuildGui()
		
		local loops = (_G.FullPlace and amt > 0) and amt or 1
		task.spawn(function()
			for i = 1, loops do
				v2.RF:InvokeServer(v16.Name, LocalPlayer.Data:FindFirstChild(v16.Name).Value, v5, v13, Anchor, v16.PrimaryPart.CFrame, v122)
				if loops > 1 and i < loops then task.wait(0.2) end
			end
			v16:Destroy()
		end)
	end

	local function itemChanged()
		local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
		local v122 = ReplicatedStorage.BuildingParts:FindFirstChild(Selected) if not v122 then return end
		local v22 = v3 and v3.PrimaryPart.CFrame or CFrame.new()
		if v3 then v3:Destroy() end
		v3 = v122:Clone() v3:SetPrimaryPartCFrame(CFrame.new(v22.p) * v122.PrimaryPart.CFrame.Rotation)
		v8 = CFrame.new() v1.TargetFilter = v3 changeTransparency(v3, 0.5)
		for _, b in ipairs(v3:GetDescendants()) do if b:IsA("BasePart") then b.Anchored = true b.CanCollide = false b.CanQuery = false end end
		updateBlockCF() v3.Parent = workspace
	end

	local function inputBegan(p1, p2)
		if p2 then return end
		if p1.UserInputType == Enum.UserInputType.Keyboard then
			if p1.KeyCode == Enum.KeyCode.R then rotateY() elseif p1.KeyCode == Enum.KeyCode.T then rotateX() end
		elseif p1.UserInputType == Enum.UserInputType.MouseButton1 then
			placeBlock()
		end
	end

	v2.Equipped:Connect(function()
		v3 = ReplicatedStorage.BuildingParts.WoodBlock:Clone() itemChanged()
		v12 = UserInputService.InputChanged:Connect(function(p) if p.UserInputType == Enum.UserInputType.MouseMovement then updateBlockCF() end end)
		v13 = UserInputService.InputBegan:Connect(inputBegan)
		v19 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected:GetPropertyChangedSignal("Value"):Connect(itemChanged)
		LocalPlayer.PlayerGui.BuildGui.InventoryFrame.Visible = true
	end)
	v2.Unequipped:Connect(function()
		if v3 then v3:Destroy() v3 = nil end
		if v12 then v12:Disconnect() end if v13 then v13:Disconnect() end if v19 then v19:Disconnect() end
		LocalPlayer.PlayerGui.BuildGui.InventoryFrame.Visible = false
	end)
end

-- SCALE TOOL MOD
local function runScale(tool)
	cleanScripts(tool)
	local v1 = LocalPlayer:GetMouse()
	local RunService = game:GetService("RunService")
	local CurrentCamera = workspace.CurrentCamera
	local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)
	local v2, v4, v7, v8, v5, v12
	local v16, v17 = false, false

	local function canSelect(p1)
		if v16 then return false end
		local v, _, v22 = GetBlockInfo(p1, LocalPlayer)
		if v22 and string.find(v.Name, "Block") then return true, v end
		return false
	end

	local function active()
		if not v2 or not v2.Adornee then return end
		local ok, v22 = canSelect(v2.Adornee)
		if not ok then return end
		local Size = v22.PrimaryPart.Size
		local Size2 = ReplicatedStorage.BuildingParts:FindFirstChild(v22.Name).PrimaryPart.Size
		local v15 = Size2.X * Size2.Y * Size2.Z
		v4 = v4 or Instance.new("Handles", LocalPlayer.PlayerGui)
		v4.Adornee = v22.PrimaryPart v4.Style = Enum.HandlesStyle.Resize v4.Color3 = Color3.fromRGB(172, 78, 1)
		local v3, v52, v42, v62
		if v7 then v7:Disconnect() end
		v7 = v4.MouseButton1Down:Connect(function() v16 = true v3 = v4.Adornee.CFrame v52 = v4.Adornee.Size v4.Adornee:BreakJoints() v4.Adornee.Anchored = true end)
		if v8 then v8:Disconnect() end
		v8 = v4.MouseDrag:Connect(function(p1, p2)
			local inc = tonumber(v12.BlockImage.More.Scale.TextBox.Text) or 1
			if inc ~= 0 then p2 = p2 - p2 % inc end
			if p1 == Enum.NormalId.Right then v42 = v3 * CFrame.new(p2 / 2, 0, 0) v62 = v52 + Vector3.new(p2, 0, 0)
			elseif p1 == Enum.NormalId.Left then v42 = v3 * CFrame.new(-p2 / 2, 0, 0) v62 = v52 + Vector3.new(p2, 0, 0)
			elseif p1 == Enum.NormalId.Top then v42 = v3 * CFrame.new(0, p2 / 2, 0) v62 = v52 + Vector3.new(0, p2, 0)
			elseif p1 == Enum.NormalId.Bottom then v42 = v3 * CFrame.new(0, -p2 / 2, 0) v62 = v52 + Vector3.new(0, p2, 0)
			elseif p1 == Enum.NormalId.Back then v42 = v3 * CFrame.new(0, 0, p2 / 2) v62 = v52 + Vector3.new(0, 0, p2)
			elseif p1 == Enum.NormalId.Front then v42 = v3 * CFrame.new(0, 0, -p2 / 2) v62 = v52 + Vector3.new(0, 0, p2) end
			v62 = Vector3.new(math.max(v62.X, 0.05), math.max(v62.Y, 0.05), math.max(v62.Z, 0.05))
			local curAmt = tonumber(v12.BlockImage.AmountText.Text) or 0
			if curAmt >= 0 or _G.DisableToolLimit then
				v4.Adornee.CFrame = v42 v4.Adornee.Size = v62
				v12.BlockImage.SizeDisplay.Text = string.format("%.3f,%.3f,%.3f", v62.X, v62.Y, v62.Z)
			else
				local s = tool:FindFirstChild("ClickSound") and tool.ClickSound:Clone() or Instance.new("Sound")
				s.Parent = v4.Adornee Debris:AddItem(s, 0.3) s.PlaybackSpeed = 5 s:Play()
			end
		end)
		if v6 then v6:Disconnect() end
		v6 = v4.MouseButton1Up:Connect(function()
			local r1, r2 = tool.RF:InvokeServer(v4.Adornee.Parent, v4.Adornee.Size, v4.Adornee.CFrame)
			if r1 then v22.PrimaryPart.Size = r1 v22.PrimaryPart.CFrame = r2 end
			v16 = false
		end)
	end

	local function mouseMove()
		if not v1.Target or not v1.Target.Parent then v2.Adornee = nil return end
		local ok, v22 = canSelect(v1.Target)
		if ok then v2.Adornee = v22 v2.LineThickness = math.min(v22.PrimaryPart.Size.X, v22.PrimaryPart.Size.Y, v22.PrimaryPart.Size.Z, 2) / 13.334 end
	end

	tool.Equipped:Connect(function()
		v12 = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScaleToolDisplayGui")
		v2 = Instance.new("SelectionBox", workspace) v2.Color3 = Color3.fromRGB(172, 109, 0) v2.SurfaceTransparency = 0.5
		v5 = UserInputService.InputBegan:Connect(function(p, g) if not g and p.UserInputType == Enum.UserInputType.MouseButton1 then active() end end)
		RunService:BindToRenderStep("scaleMouseMove", 200, mouseMove)
	end)
	tool.Unequipped:Connect(function()
		if v2 then v2:Destroy() end if v4 then v4:Destroy() v4 = nil end
		if v5 then v5:Disconnect() end RunService:UnbindFromRenderStep("scaleMouseMove")
	end)
end

-- TROWEL TOOL MOD
local function runTrowel(tool)
	cleanScripts(tool)
	local v1 = LocalPlayer:GetMouse()
	local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)
	local v3, v9, v11, v12, v13, v5, v6, v22
	local t, t2, v23, v14 = {}, {}, false, false

	local function clearSelected()
		for k, v in pairs(t) do v:Destroy() end
		t, t2 = {}, {} if v9 then v9.ModeImage.AmountText.Text = "0" end
	end

	local function addSelection(p1)
		local sb = Instance.new("SelectionBox", p1) sb.Name = "TrowelSB" sb.SurfaceTransparency = 0.5 sb.Color3 = Color3.fromRGB(0, 126, 158)
		local _, s = p1:GetBoundingBox() sb.LineThickness = math.min(s.X, s.Y, s.Z, 2) / 50 sb.Adornee = p1 sb:SetAttribute("Created", tick())
		t[p1] = sb t2[p1.Name] = (t2[p1.Name] or 0) + 1
		if v9 then v9.ModeImage.AmountText.Text = tostring(#game:GetService("HttpService"):JSONEncode(t2)) end
	end

	local function GetBoundingBox(p1, p2)
		local abs = math.abs local min, max = Vector3.new(1/0, 1/0, 1/0), Vector3.new(-1/0, -1/0, -1/0)
		for _, v in ipairs(p1) do
			if v.PrimaryPart then
				local rel = p2:toObjectSpace(v.PrimaryPart.CFrame) local s = v.PrimaryPart.Size
				local _,_,_, m11,m12,m13,m21,m22,m23,m31,m32,m33 = rel:components()
				local x = 0.5 * (abs(m11)*s.X + abs(m12)*s.Y + abs(m13)*s.Z)
				local y = 0.5 * (abs(m21)*s.X + abs(m22)*s.Y + abs(m23)*s.Z)
				local z = 0.5 * (abs(m31)*s.X + abs(m32)*s.Y + abs(m33)*s.Z)
				min = Vector3.new(math.min(min.X, rel.X-x), math.min(min.Y, rel.Y-y), math.min(min.Z, rel.Z-z))
				max = Vector3.new(math.max(max.X, rel.X+x), math.max(max.Y, rel.Y+y), math.max(max.Z, rel.Z+z))
			end
		end
		return p2 - p2.p + p2:pointToWorldSpace((max + min) / 2), max - min
	end

	local function updateBoundingBox()
		if not v11 then
			v11 = Instance.new("Part", workspace) v11.Name = "TrowelBoundingBox" v11.Anchored = true v11.Transparency = 1 v11.CanCollide = false
			local sb = Instance.new("SelectionBox", v11) sb.LineThickness = 0.002 sb.Adornee = v11
		end
		local models = {} for k in pairs(t) do table.insert(models, k) end
		if #models < 1 then if v11 then v11:Destroy() v11 = nil end return end
		table.sort(models, function(a, b) return (a:FindFirstChild("TrowelSB") and a.TrowelSB:GetAttribute("Created") or 0) < (b:FindFirstChild("TrowelSB") and b.TrowelSB:GetAttribute("Created") or 0) end)
		local prim = models[#models].PrimaryPart
		local c, s = GetBoundingBox(models, prim.CFrame - prim.Position)
		v11.Size = s v11.CFrame = c
	end

	local function performServerOperation(p1, p2)
		v23 = true local mode = v9.Mode.Value local models = {} for k in pairs(t) do table.insert(models, k) end
		if mode == "Clone" then
			table.sort(models, function(a, b) return a.TrowelSB:GetAttribute("Created") > b.TrowelSB:GetAttribute("Created") end)
		end
		if v12 then v12:Destroy() v12 = nil end if v13 then v13:Destroy() v13 = nil end
		local res = tool.OperationRF:InvokeServer(models, p1, p2, mode) or {}
		if mode == "Clone" then
			v9.SetModeEvent:Fire("Move") clearSelected()
			for _, m in ipairs(res) do local ok, _, v15 = GetBlockInfo(m, LocalPlayer) if v15 then addSelection(ok) end end
		end
		updateBoundingBox() v23 = false
	end

	local function active(p1)
		if v23 or v14 then return end
		local Target = v1.Target local ok, b, v15 = GetBlockInfo(Target, LocalPlayer)
		if v15 and b then clearSelected() addSelection(b) updateBoundingBox() end
		if v11 and not v12 then
			v12 = Instance.new("Handles", LocalPlayer.PlayerGui) v12.Adornee = v11 v12.Style = Enum.HandlesStyle.Movement
			v12.MouseButton1Down:Connect(function() v14 = true v22 = v11.CFrame end)
			v12.MouseDrag:Connect(function(p1, p2)
				local inc = tonumber(v9.ModeImage.More.Scale.TextBox.Text) or 1
				if inc ~= 0 then p2 = p2 - p2 % inc end
				if p1 == Enum.NormalId.Right then v11.CFrame = v22 * CFrame.new(p2, 0, 0)
				elseif p1 == Enum.NormalId.Left then v11.CFrame = v22 * CFrame.new(-p2, 0, 0)
				elseif p1 == Enum.NormalId.Top then v11.CFrame = v22 * CFrame.new(0, p2, 0)
				elseif p1 == Enum.NormalId.Bottom then v11.CFrame = v22 * CFrame.new(0, -p2, 0)
				elseif p1 == Enum.NormalId.Back then v11.CFrame = v22 * CFrame.new(0, 0, p2)
				elseif p1 == Enum.NormalId.Front then v11.CFrame = v22 * CFrame.new(0, 0, -p2) end
			end)
			v12.MouseButton1Up:Connect(function() v14 = false performServerOperation(v22, v11.CFrame) end)
		end
	end

	tool.Equipped:Connect(function()
		v9 = LocalPlayer.PlayerGui.TrowelToolDisplayGui
		v3 = Instance.new("SelectionBox", workspace) v3.Color3 = Color3.fromRGB(0, 134, 171)
		v5 = UserInputService.InputBegan:Connect(function(p, g) if not g and p.UserInputType == Enum.UserInputType.MouseButton1 then active() end end)
		v6 = UserInputService.InputChanged:Connect(function(p)
			if p.UserInputType == Enum.UserInputType.MouseMovement and v3 then
				local ok, b, v15 = GetBlockInfo(v1.Target, LocalPlayer)
				if v15 then v3.Adornee = b else v3.Adornee = nil end
			end
		end)
	end)
	tool.Unequipped:Connect(function()
		clearSelected() if v3 then v3:Destroy() end if v11 then v11:Destroy() end
		if v12 then v12:Destroy() end if v5 then v5:Disconnect() end if v6 then v6:Disconnect() end
	end)
end

-- PERSISTENCE & MONITOR LOOP
task.spawn(function()
	while true do
		local bp = LocalPlayer:FindFirstChild("Backpack")
		local char = LocalPlayer.Character
		if bp or (char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0) then
			local bTool = bp:FindFirstChild("BuildingTool") or (char and char:FindFirstChild("BuildingTool"))
			local sTool = bp:FindFirstChild("ScalingTool") or (char and char:FindFirstChild("ScalingTool"))
			local tTool = bp:FindFirstChild("TrowelTool") or (char and char:FindFirstChild("TrowelTool"))
			
			if bTool and not bTool:GetAttribute("Hooked") then
				bTool:SetAttribute("Hooked", true) runBuild(bTool) dprint("Hooked BuildingTool")
			end
			if sTool and not sTool:GetAttribute("Hooked") then
				sTool:SetAttribute("Hooked", true) runScale(sTool) dprint("Hooked ScalingTool")
			end
			if tTool and not tTool:GetAttribute("Hooked") then
				tTool:SetAttribute("Hooked", true) runTrowel(tTool) dprint("Hooked TrowelTool")
			end
		end
		task.wait(1)
	end
end)

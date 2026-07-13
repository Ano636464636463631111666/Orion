local debugp = false
local running = true
local activeTools = {}

local function dprint(...)
    if debugp then
        print(...)
    end
end

local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = game.Players.LocalPlayer

local function setupBuildingTool(tool, originalScript)
    local v1 = LocalPlayer:GetMouse()
    local CurrentCamera = workspace.CurrentCamera
    local v2 = tool
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
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
    local v25 = nil
    local v26 = nil

    local function changeTransparency(p1, p2)
        local connections = p1:GetDescendants()
        for i = 1, #connections do
            if connections[i]:IsA("BasePart") then
                if CollectionService:HasTag(connections[i], "NoTransparency") then
                    connections[i].Transparency = 0
                    continue
                end
                if CollectionService:HasTag(connections[i], "FullTransparency") then
                    connections[i].Transparency = 1
                    continue
                end
                connections[i].Transparency = p2
            end
        end
    end

    local function canPlace(p1)
        return true, ""
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

    local function roundVectorToBase(p1, p2)
        local base = 1 / p2
        local rounded = p1 * base + Vector3.new(0.5, 0.5, 0.5)
        return Vector3.new(math.floor(rounded.X), math.floor(rounded.Y), (math.floor(rounded.Z))) / base
    end

    local function normalIdToNormalVector(p1, p2)
        if p1 == Enum.NormalId.Top then
            return Vector3.new(0, 1, 0), p2.Size.Y
        end
        if p1 == Enum.NormalId.Bottom then
            return Vector3.new(0, -1, 0), p2.Size.Y
        end
        if p1 == Enum.NormalId.Front then
            return Vector3.new(0, 0, -1), p2.Size.Z
        end
        if p1 == Enum.NormalId.Back then
            return Vector3.new(0, 0, 1), p2.Size.Z
        end
        if p1 == Enum.NormalId.Right then
            return Vector3.new(1, 0, 0), p2.Size.X
        end
        return Vector3.new(-1, 0, 0), p2.Size.X
    end

    local function WeldTogether(p1, p2, p3, p4)
        if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then
            return
        end
        local weld = Instance.new(p3 or "Weld")
        weld.Part0 = p1
        weld.Part1 = p2
        weld.C0 = CFrame.new()
        weld.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
        weld.Parent = p4 or p1
        return weld
    end

    local function prepareItem()
        v1.TargetFilter = v3
        changeTransparency(v3, 0.5)
        local descendants = v3:GetDescendants()
        for i = 1, #descendants do
            if descendants[i]:IsA("BasePart") then
                descendants[i].Anchored = true
                descendants[i].CanCollide = false
                descendants[i].CanQuery = false
                if descendants[i] ~= v3.PrimaryPart then
                    WeldTogether(v3.PrimaryPart, descendants[i])
                end
            end
        end
    end

    local function getType(p1)
        local id = string.match(p1.TypeIcon.Image, "%d+")
        if id == "4597411234" then
            return "Block"
        end
        if id == "4597402658" then
            return "Decoration"
        end
        return "Special"
    end

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
        local children = ScrollingFrame.BlocksFrame:GetChildren()
        local maxVal = nil
        local minVal = nil
        for i = 1, #children do
            if children[i]:IsA("GuiObject") and children[i].Visible then
                if not maxVal or maxVal < children[i].AbsolutePosition.Y then
                    maxVal = children[i].AbsolutePosition.Y
                end
                if not minVal or children[i].AbsolutePosition.Y < minVal then
                    minVal = children[i].AbsolutePosition.Y
                end
            end
        end
        if minVal and maxVal then
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, maxVal - minVal + 100)
            return
        end
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end

    local function updateBuildGui()
        local targetPlayer = LocalPlayer
        local leader = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if leader and LocalPlayer.Settings.ShareBlocks.Value then
            targetPlayer = leader
        end
        local name = targetPlayer.Name
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        local SearchFrame = BuildGui.SearchFrame
        local text = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
        local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local items = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()
        for i = 1, #items do
            local item = items[i]
            if game.ReplicatedStorage.BuildingParts:FindFirstChild(item.Name) then
                local bType = getType(item)
                local count = game.Players:FindFirstChild(name).Data[item.Name].Value
                local tags = string.split(item.Tags.Value, " ")
                local match = false
                if SearchFrame.OnlySearch.Value then
                    local ok, result = pcall(function()
                        return LocalizationService:GetTranslatorForPlayerAsync(game.Players.LocalPlayer)
                    end)
                    if ok then
                        local translatedName = string.lower((result:Translate(TagsFrame.Parent.BlockName, item.BlockName.Value)))
                        if string.find(translatedName, text) or string.find(text, translatedName) then
                            match = true
                        end
                        if not match then
                            for j = 1, #tags do
                                local translatedTag = string.lower((result:Translate(TagsFrame, tags[j])))
                                if string.find(translatedTag, text) or string.find(text, translatedTag) then
                                    match = true
                                    break
                                end
                            end
                        end
                    end
                end
                if count == 0 or SearchFrame.OnlyBlocks.Value and bType ~= "Block" or (SearchFrame.OnlyDecorations.Value and bType ~= "Decoration" or SearchFrame.OnlySpecial.Value and bType ~= "Special") then
                    item.Visible = false
                else
                    if SearchFrame.OnlySearch.Value and not match then
                        item.Visible = false
                        continue
                    end
                    item.Visible = true
                end
            end
        end
        fitBuildScroll()
        setSpeedBuildGuiLook()
    end

    local function updateBlockCF(p1)
        if not v1.Target then
            return
        end
        local part = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
        if not p1 then
            v5 = v1.Target
            v6 = v1.Hit
            v7 = v1.TargetSurface
        end
        local rot = v8
        local inverse = (v5.CFrame - v5.Position):Inverse()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            inverse = CFrame.new(0, 0, 0)
        end
        local dir, size = normalIdToNormalVector(v7, v5)
        local baseCF = v5.CFrame * CFrame.new(dir * (size / 2))
        part:SetPrimaryPartCFrame(baseCF * inverse * rot)
        local worldDir = (v5.CFrame - v5.Position):PointToWorldSpace(dir)
        local dotR = part.PrimaryPart.CFrame.RightVector:Dot(worldDir)
        local dotU = part.PrimaryPart.CFrame.UpVector:Dot(worldDir)
        local dotL = part.PrimaryPart.CFrame.LookVector:Dot(worldDir)
        local absR = math.abs(dotR)
        local absU = math.abs(dotU)
        local absL = math.abs(dotL)
        part:SetPrimaryPartCFrame(baseCF * inverse:Inverse() * rot:Inverse())
        local offsetCF = baseCF * CFrame.new(dir * (absR * (part.PrimaryPart.Size.X / 2) + absU * (part.PrimaryPart.Size.Y / 2) + absL * (part.PrimaryPart.Size.Z / 2)))
        local objSpace = v5.CFrame:PointToObjectSpace(v6.p)
        local roundSpace = if v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom then objSpace - Vector3.new(0, objSpace.Y, 0) elseif v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back then objSpace - Vector3.new(0, 0, objSpace.Z) else objSpace - Vector3.new(objSpace.X, 0, 0)
        local grid = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
        if grid ~= 0 then
            roundSpace = roundVectorToBase(roundSpace, grid)
        end
        part:SetPrimaryPartCFrame(offsetCF * CFrame.new(roundSpace) * inverse * rot)
        if not v3:FindFirstChild("CanPlace") then
            local CanPlace = Instance.new("BoolValue")
            CanPlace.Name = "CanPlace"
            CanPlace.Value = true
            CanPlace.Parent = v3
        end
        v3.CanPlace.Value = true
        if v3:FindFirstChild("OutOfBoundsBG") then
            v3.OutOfBoundsBG:Destroy()
        end
    end

    local function resetRotation()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v8 = CFrame.new()
        else
            local zone = workspace[tostring(LocalPlayer.TeamColor) .. "Zone"]
            v8 = (zone.CFrame - zone.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
        end
    end

    local function itemChanged()
        local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
        local item = game.ReplicatedStorage.BuildingParts:FindFirstChild(Selected)
        updateBuildGui()
        local cf = v3.PrimaryPart.CFrame
        v3:Destroy()
        v3 = item:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(cf.p) * item.PrimaryPart.CFrame.Rotation)
        resetRotation()
        prepareItem()
        updateBlockCF()
        v3.Parent = workspace
        local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local list = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
        local children = TagsFrame:GetChildren()
        local TextLabel = TagsFrame.TextLabel
        for i = 1, #list do
            local label = TextLabel:Clone()
            label.Text = string.lower(list[i])
            label.Parent = TextLabel.Parent
        end
        for j = 1, #children do
            children[j]:Destroy()
        end
        TagsFrame.Parent.BlockName.Text = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].BlockName.Value
        TagsFrame.Parent.StrengthFrame.TextLabel.Text = tostring(game.ReplicatedStorage.BuildingParts[Selected].Health.Value)
    end

    local function placeBlock(p1)
        if v25 or not v3 then
            return
        end
        if v3:FindFirstChild("OutOfBoundsBG") then
            v3.OutOfBoundsBG:Destroy()
        end
        v25 = true
        task.spawn(function()
            task.wait()
            v25 = false
        end)
        local clickSoundSrc = tool:FindFirstChild("ClickSound") or originalScript:FindFirstChild("ClickSound")
        local isSpecialType = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"
        if isSpecialType then
            local secondPl = v3:FindFirstChild("2ndPlacement")
            if not secondPl then
                local val = Instance.new("BoolValue")
                val.Name = "2ndPlacement"
                val.Parent = v3
                updateBlockCF()
                return
            end
            secondPl:Destroy()
        end
        local secondaryCF = if isSpecialType then v3.SecondaryPart.PrimaryPart.CFrame else isSpecialType
        changeTransparency(v3, 0)
        game.Debris:AddItem(v3, 10)
        local objSpaceCF = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
        local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
        if clickSoundSrc then
            local sound = clickSoundSrc:Clone()
            sound.Parent = v3.PrimaryPart
            game.Debris:AddItem(sound, 1)
            sound.PlaybackSpeed = 1
            sound:Play()
        end
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            resetRotation()
        end
        local oldV3 = v3
        v3 = v3:Clone()
        changeTransparency(v3, 0.5)
        v3.Parent = workspace
        v1.TargetFilter = v3
        local descendants = oldV3:GetDescendants()
        for i = 1, #descendants do
            if descendants[i]:IsA("BasePart") then
                descendants[i].CanQuery = true
            end
        end
        local targetPart = v5
        updateBlockCF(p1)
        updateBuildGui()
        if not isSpecialType then
            v2.RF:InvokeServer(oldV3.Name, LocalPlayer.Data:FindFirstChild(oldV3.Name).Value, targetPart, objSpaceCF, Anchor, oldV3.PrimaryPart.CFrame, secondaryCF)
            oldV3:Destroy()
            return
        end
        local baseItem = game.ReplicatedStorage.BuildingParts[v3.Name]
        v3.SecondaryPart.PrimaryPart.CFrame = v3.PrimaryPart.CFrame * baseItem.PrimaryPart.CFrame:ToObjectSpace(baseItem.SecondaryPart.PrimaryPart.CFrame)
        v2.RF:InvokeServer(oldV3.Name, LocalPlayer.Data:FindFirstChild(oldV3.Name).Value, targetPart, objSpaceCF, Anchor, oldV3.PrimaryPart.CFrame, secondaryCF)
        oldV3:Destroy()
    end

    local function toggleSpeedBuild()
        if v26 then
            return
        end
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
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then
            return
        end
        updateBlockCF()
    end

    local function inputBegan(p1, p2)
        if p2 then
            return
        end
        if p1.UserInputType == Enum.UserInputType.Keyboard then
            if p1.KeyCode == Enum.KeyCode.R then
                rotateY()
                return
            end
            if p1.KeyCode == Enum.KeyCode.T then
                rotateX()
            end
        else
            if p1.UserInputType == Enum.UserInputType.MouseButton1 then
                placeBlock()
                return
            end
            if p1.UserInputType == Enum.UserInputType.Touch then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                if isSpeedBuild() then
                    v10 = v1.Hit
                else
                    updateBlockCF()
                end
                return
            end
            if p1.UserInputType ~= Enum.UserInputType.Gamepad1 then
                return
            end
            if p1.KeyCode == Enum.KeyCode.ButtonR2 then
                placeBlock()
                return
            end
            if p1.KeyCode == Enum.KeyCode.ButtonX then
                rotateY()
                return
            end
            if p1.KeyCode ~= Enum.KeyCode.ButtonY then
                return
            end
            rotateX()
        end
    end

    local function inputEnded(p1, p2)
        if p2 or (p1.UserInputType ~= Enum.UserInputType.Touch or not (isSpeedBuild() and (v1.Hit.p - v10.p).Magnitude < 1)) then
            return
        end
        updateBlockCF()
        placeBlock(true)
    end

    local function uneq()
        v4 = v3.Name
        v3:Destroy()
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
        if LocalPlayer.Character.Humanoid.Health <= 0 then
            return
        end
        v3 = game.ReplicatedStorage.BuildingParts.WoodBlock:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(-50, -12, -720))
        itemChanged(v4 or "WoodBlock")
        v12 = UserInputService.InputChanged:Connect(inputChanged)
        v13 = UserInputService.InputBegan:Connect(inputBegan)
        v14 = UserInputService.InputEnded:Connect(inputEnded)
        v16 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.MouseButton1Click:Connect(rotateY)
        v17 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.MouseButton1Click:Connect(rotateX)
        v15 = LocalPlayer.PlayerGui.TabletToolGui.Frame.Place.MouseButton1Click:Connect(function()
            if v9 == v3.PrimaryPart.CFrame and not (if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope") then
                return
            end
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
        if workspace.Challenge.Teams:FindFirstChild(LocalPlayer.Team.Name) then
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        else
            BuildGui.InventoryFrame.MoreFrame.AnchorBlock.toggle.BackgroundColor3 = Color3.fromRGB(132, 132, 132)
        end
    end

    activeTools[tool] = {
        c1 = tool.Equipped:Connect(eq),
        c2 = tool.Unequipped:Connect(uneq),
        original = originalScript
    }
end

local function setupScalingTool(tool, originalScript)
    local v1 = LocalPlayer:GetMouse()
    local CurrentCamera = workspace.CurrentCamera
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
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

    local function canSelect(p1)
        if v16 then
            return false, p1
        end
        local info, _, tag = GetBlockInfo(p1, LocalPlayer)
        if tag and string.find(info.Name, "Block") then
            return true, info
        end
        return false
    end

    local function isPartInZone(p1, p2)
        return true
    end

    local function updateBlocksSoft(p1, p2)
        local targetPlayer = LocalPlayer
        local leader = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if leader and LocalPlayer.Settings.ShareBlocks.Value then
            targetPlayer = leader
        end
        v13 = game.Players:FindFirstChild(targetPlayer.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
        v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)
        local remaining = math.floor(v13 - v14)
        v12.BlockImage.AmountText.Text = tostring(remaining)
        return remaining
    end

    local function updateBlocks()
        local targetPlayer = LocalPlayer
        local leader = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if leader and LocalPlayer.Settings.ShareBlocks.Value then
            targetPlayer = leader
        end
        local zone = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local name = v4.Adornee.Parent.Name
        v13 = game.Players:FindFirstChild(targetPlayer.Name).Data:FindFirstChild(name).Value
        local blocks = workspace.Blocks:GetChildren()
        local sum = 0
        for i = 1, #blocks do
            local children = blocks[i]:GetChildren()
            for j = 1, #children do
                local block = children[j]
                local _, _, tag = GetBlockInfo(block, LocalPlayer)
                if tag and (block.Name == name and block.PrimaryPart) then
                    sum = sum + math.max(block.PrimaryPart.Size.X * block.PrimaryPart.Size.Y * block.PrimaryPart.Size.Z / v15, 1)
                end
            end
        end
        v14 = sum
        v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
        v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(name).Image
        v12.Parent = LocalPlayer.PlayerGui
    end

    local function roundToNearestThousands(p1)
        return math.floor(p1 * 1000 + 0.5) / 1000
    end

    local function lockCameraRotation()
        v17 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local subject = CurrentCamera.CameraSubject
        if subject:IsA("Humanoid") then
            subject = subject.RootPart
        end
        local offset = subject.CFrame.p - CurrentCamera.CFrame.p
        local rotation = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = rotation + subject.CFrame.p - offset
        end)
    end

    local function checkToLockCameraRotation()
        if v17 then
            return
        end
        lockCameraRotation()
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v17 = false
    end

    local function checkToUnlockCameraRotation()
        if not v17 then
            return
        end
        unlockCameraRotation()
    end

    local function mouseMove(p1)
        local target = v1.Target
        if not (target and target.Parent) then
            v2.Adornee = nil
            return
        end
        local match, model = canSelect(target)
        if v4 and (v2.Adornee and v4.Adornee == v2.Adornee.PrimaryPart) then
            v2.Adornee = nil
        end
        if v4 and (model and (model:IsA("Model") and v4.Adornee == model.PrimaryPart)) then
            v2.Adornee = nil
            return
        end
        if v2.Adornee == model then
            return
        end
        if match then
            v2.Adornee = model
            local size = model.PrimaryPart.Size
            v2.LineThickness = math.min(size.X, size.Y, size.Z, 2) / 13.334
            if p1 then
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = false
                LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = false
                end
        else
            v2.Adornee = nil
            if not p1 then
                return
            end
            LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        end
    end

    local function active(p1)
        if not v2 then
            return
        end
        local adornee = v2.Adornee
        if adornee == nil then
            return
        end
        local match, model = canSelect(adornee)
        if match then
            local size = model.PrimaryPart.Size
            local targetSize = game.ReplicatedStorage.BuildingParts:FindFirstChild(model.Name).PrimaryPart.Size
            v15 = targetSize.X * targetSize.Y * targetSize.Z
            if v4 then
                v4.Adornee = model.PrimaryPart
            else
                v4 = Instance.new("Handles")
                v4.Adornee = model.PrimaryPart
                v4.Style = Enum.HandlesStyle.Resize
                v4.Color3 = Color3.fromRGB(172, 78, 1)
                v4.Parent = LocalPlayer.PlayerGui
            end
            local oldCF = nil
            local oldSize = nil
            local targetCF = nil
            local targetResize = nil
            if v7 then
                v7:Disconnect()
                v7 = nil
            end
            v7 = v4.MouseButton1Down:Connect(function()
                v16 = true
                oldCF = v4.Adornee.CFrame
                oldSize = v4.Adornee.Size
                v4.Adornee:BreakJoints()
                v4.Adornee.Anchored = true
                if not p1 then
                    return
                end
                checkToLockCameraRotation()
            end)
            local display = v12.BlockImage.SizeDisplay
            display.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
            if v8 then
                v8:Disconnect()
                v8 = nil
            end
            v8 = v4.MouseDrag:Connect(function(face, distance)
                local step = tonumber(v12.BlockImage.More.Scale.TextBox.Text)
                if step ~= 0 then
                    distance = distance - distance % step
                end
                if face == Enum.NormalId.Right then
                    if oldSize.X + distance <= 0.05 then
                        local rem = oldSize.X % step
                        if step == 0 then rem = 0.05 end
                        if rem < 0.05 then rem = step end
                        targetResize = Vector3.new(rem, oldSize.Y, oldSize.Z)
                        targetCF = oldCF * CFrame.new(-(oldSize.X - targetResize.X) / 2, 0, 0)
                    else
                        targetCF = oldCF * CFrame.new(distance / 2, 0, 0)
                        targetResize = oldSize + Vector3.new(distance, 0, 0)
                    end
                elseif face == Enum.NormalId.Left then
                    if oldSize.X + distance <= 0.05 then
                        local rem = oldSize.X % step
                        if step == 0 then rem = 0.05 end
                        if rem <= 0.05 then rem = step end
                        targetResize = Vector3.new(rem, oldSize.Y, oldSize.Z)
                        targetCF = oldCF * CFrame.new(-(-(oldSize.X - targetResize.X)) / 2, 0, 0)
                    else
                        targetCF = oldCF * CFrame.new(-distance / 2, 0, 0)
                        targetResize = oldSize + Vector3.new(distance, 0, 0)
                    end
                elseif face == Enum.NormalId.Top then
                    if oldSize.Y + distance <= 0.05 then
                        local rem = oldSize.Y % step
                        if step == 0 then rem = 0.05 end
                        if rem <= 0.05 then rem = step end
                        targetResize = Vector3.new(oldSize.X, rem, oldSize.Z)
                        targetCF = oldCF * CFrame.new(0, -(oldSize.Y - targetResize.Y) / 2, 0)
                    else
                        targetCF = oldCF * CFrame.new(0, distance / 2, 0)
                        targetResize = oldSize + Vector3.new(0, distance, 0)
                    end
                elseif face == Enum.NormalId.Bottom then
                    if oldSize.Y + distance <= 0.05 then
                        local rem = oldSize.Y % step
                        if step == 0 then rem = 0.05 end
                        if rem <= 0.05 then rem = step end
                        targetResize = Vector3.new(oldSize.X, rem, oldSize.Z)
                        targetCF = oldCF * CFrame.new(0, -(-(oldSize.Y - targetResize.Y)) / 2, 0)
                    else
                        targetCF = oldCF * CFrame.new(0, -distance / 2, 0)
                        targetResize = oldSize + Vector3.new(0, distance, 0)
                    end
                elseif face == Enum.NormalId.Back then
                    if oldSize.Z + distance <= 0.05 then
                        local rem = oldSize.Z % step
                        if step == 0 then rem = 0.05 end
                        if rem <= 0.05 then rem = step end
                        targetResize = Vector3.new(oldSize.X, oldSize.Y, rem)
                        targetCF = oldCF * CFrame.new(0, 0, -(oldSize.Z - targetResize.Z) / 2)
                    else
                        targetCF = oldCF * CFrame.new(0, 0, distance / 2)
                        targetResize = oldSize + Vector3.new(0, 0, distance)
                    end
                elseif face == Enum.NormalId.Front then
                    if oldSize.Z + distance <= 0.05 then
                        local rem = oldSize.Z % step
                        if step == 0 then rem = 0.05 end
                        if rem <= 0.05 then rem = step end
                        targetResize = Vector3.new(oldSize.X, oldSize.Y, rem)
                        targetCF = oldCF * CFrame.new(0, 0, -(-(oldSize.Z - targetResize.Z)) / 2)
                    else
                        targetCF = oldCF * CFrame.new(0, 0, -distance / 2)
                        targetResize = oldSize + Vector3.new(0, 0, distance)
                    end
                end
                targetResize = Vector3.new(math.max(targetResize.X, 0.05), math.max(targetResize.Y, 0.05), (math.max(targetResize.Z, 0.05)))
                updateBlocksSoft(v4.Adornee.Size, targetResize)
                if v4.Adornee.Size == targetResize then
                    return
                end
                v4.Adornee:BreakJoints()
                v4.Adornee.CFrame = targetCF or oldCF
                v4.Adornee.Size = targetResize or oldSize
                display.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
            end)
            if v6 then
                v6:Disconnect()
                v6 = nil
            end
            v6 = v4.MouseButton1Up:Connect(function()
                oldCF = v4.Adornee.CFrame
                oldSize = v4.Adornee.Size
                local matchModel, resultCF = tool.RF:InvokeServer(v4.Adornee.Parent, oldSize, oldCF)
                size = oldSize
                if matchModel then
                    model.PrimaryPart.Size = matchModel
                    model.PrimaryPart.CFrame = resultCF
                    updateBlocks()
                end
                v16 = false
                if not p1 then
                    return
                end
                checkToUnlockCameraRotation()
            end)
            if v5 then
                v5:Disconnect()
                v5 = nil
            end
            v5 = tool.Unequipped:Connect(function()
                oldCF = v4.Adornee.CFrame
                oldSize = v4.Adornee.Size
                local matchModel, resultCF = tool.RF:InvokeServer(v4.Adornee.Parent, oldSize, oldCF)
                size = oldSize
                if not matchModel then
                    v16 = false
                    v5:Disconnect()
                    v5 = nil
                    return
                end
                model.PrimaryPart.Size = matchModel
                model.PrimaryPart.CFrame = resultCF
                v16 = false
                v5:Disconnect()
                v5 = nil
            end)
            updateBlocks()
        end
        mouseMove()
    end

    local function inputBegan(p1, p2)
        if p2 then
            return
        end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then
            active()
            return
        end
        if p1.UserInputType == Enum.UserInputType.Touch then
            mouseMove(true)
            return
        end
        if p1.UserInputType ~= Enum.UserInputType.Gamepad1 or p1.KeyCode ~= Enum.KeyCode.ButtonR2 then
            return
        end
        active()
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType ~= Enum.UserInputType.MouseMovement and (p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2) then
            return
        end
        mouseMove(false)
    end

    local function uneq()
        v2:Destroy()
        v2 = nil
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
        v4:Destroy()
        v4 = nil
        v12.BlockImage.Visible = false
        checkToUnlockCameraRotation()
    end

    local function died()
        uneq()
        tool:Destroy()
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

    activeTools[tool] = {
        c1 = tool.Equipped:connect(eq),
        c2 = tool.Unequipped:connect(uneq),
        original = originalScript
    }
end

local function setupTrowelTool(tool, originalScript)
    local v1 = LocalPlayer:GetMouse()
    local v2 = tool
    local CurrentCamera = workspace.CurrentCamera
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
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
        local list = {}
        for k, v in pairs(t) do
            table.insert(list, k)
        end
        return list
    end

    local function isPartInZone(p1, p2)
        return true
    end

    local function getBlockValue(p1)
        local name = p1.Name
        local val
        if string.find(name, "Block") then
            local size1 = game.ReplicatedStorage.BuildingParts[name].PrimaryPart.Size
            local size2 = p1.PrimaryPart.Size
            val = math.max(size2.X * size2.Y * size2.Z / (size1.X * size1.Y * size1.Z), 1)
        else
            val = 1
        end
        return val
    end

    local function updateBlockDisplayImage(p1)
        if v9.ModeImage.MaxText.Visible then
            return
        end
        local current = nil
        local isCleared = true
        local multiple = true
        for k, v in pairs(t2) do
            isCleared = false
            if current then
                multiple = true
                break
            end
            current = k
            multiple = false
        end
        if isCleared then
            v9.ModeImage.Image = ""
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
            return
        end
        if multiple then
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
        else
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[current].Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    local function clearSelected()
        for k, v in pairs(t) do
            v:Destroy()
        end
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
        local _, bounds = p1:GetBoundingBox()
        TrowelSB.LineThickness = math.min(bounds.X, bounds.Y, bounds.Z, 2) / 50
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
        local box = t[p1]
        if box then
            box:Destroy()
        end
        if not v9.ModeImage.MaxText.Visible then
            if t2[p1.Name] then
                t2[p1.Name] = t2[p1.Name] + -1
                if t2[p1.Name] <= 0 then
                    t2[p1.Name] = nil
                end
            end
            updateBlockDisplayImage(p1.Name)
        end
        t[p1] = nil
        v30 = v30 - getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
    end

    local function doingShiftSelect()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or (UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or (UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or (UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()))))
    end

    local function lockCameraRotation()
        v15 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local subject = CurrentCamera.CameraSubject
        if subject:IsA("Humanoid") then
            subject = subject.RootPart
        end
        local offset = subject.CFrame.p - CurrentCamera.CFrame.p
        local rotation = CurrentCamera.CFrame - CurrentCamera.CFrame.p
        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = rotation + subject.CFrame.p - offset
        end)
    end

    local function checkToLockCameraRotation()
        if v15 then
            return
        end
        lockCameraRotation()
    end

    local function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v15 = false
    end

    local function checkToUnlockCameraRotation()
        if not v15 then
            return
        end
        unlockCameraRotation()
    end

    local function removeBoundingBox()
        if v11 then
            v11:Destroy()
            v11 = nil
        end
        if v12 then
            v12:Destroy()
            v12 = nil
        end
        if not v13 then
            return
        end
        v13:Destroy()
        v13 = nil
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
                local relative = p2:toObjectSpace(PrimaryPart.CFrame)
                local Size = PrimaryPart.Size
                local X = Size.X
                local Y = Size.Y
                local Z = Size.Z
                local v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19 = relative:components()
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

    local function updateHandles()
        if not (v12 and v13) then
            return
        end
        v12.Visible = false
        v13.Visible = false
        local visible = isMobilePlayer() or not doingShiftSelect()
        if v11 then
            v11:FindFirstChild("SelectionBox")
        end
        local Mode = v9.Mode.Value
        if Mode == "Move" then
            v12.Color3 = Color3.fromRGB(13, 105, 172)
            v12.Visible = visible
            v12.Style = "Movement"
            return
        end
        if Mode == "Rotate" then
            v13.Visible = visible
            return
        end
        if Mode == "Clone" then
            v12.Color3 = Color3.fromRGB(20, 255, 169)
            v12.Visible = visible
            v12.Style = "Movement"
            return
        end
        if Mode ~= "Mirror" then
            return
        end
        v12.Color3 = Color3.fromRGB(248, 37, 255)
        v12.Visible = visible
        v12.Style = "Resize"
    end

    local function performServerOperatoin(p1, p2)
        v23 = true
        local Mode = v9.Mode.Value
        local selected = getSelectedModels()
        v12:Destroy()
        v13:Destroy()
        if Mode == "Clone" then
            table.sort(selected, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") > p2.TrowelSB:GetAttribute("Created") then
                    return true
                end
            end)
        end
        local result = v2.OperationRF:InvokeServer(selected, p1, p2, v9.Mode.Value) or {}
        local active = LocalPlayer.Character and (v2.Parent and (if v2.Parent == LocalPlayer.Character then LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 else false))
        if Mode == "Clone" then
            v9.SetModeEvent:Fire("Move")
            clearSelected()
            if active then
                for k = 1, #result do
                    local item, _, tag = GetBlockInfo(result[k], LocalPlayer)
                    if tag then
                        addSelection(item)
                    end
                end
            end
        end
        if not active then
            clearSelected()
        end
        removeBoundingBox()
        if not active then
            v23 = false
            return
        end
        updateBoundingBox()
        updateHandles()
        v23 = false
    end

    function updateBoundingBox()
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
        if Mode == "Clone" then
            SelectionBox.Color3 = Color3.fromRGB(20, 255, 169)
        elseif Mode == "Mirror" then
            SelectionBox.Color3 = Color3.fromRGB(248, 37, 255)
        else
            SelectionBox.Color3 = Color3.fromRGB(13, 105, 172)
        end
        if not v12 then
            v12 = Instance.new("Handles")
            v12.Name = "MoveHandle"
            v12.Adornee = v11
            v12.Visible = false
            v12.Style = Enum.HandlesStyle.Movement
            v12.Parent = LocalPlayer.PlayerGui
            if v17 then
                v17:Disconnect()
                v17 = nil
            end
            v17 = v12.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v12.Adornee.CFrame
                v11:BreakJoints()
                v12.Faces = Faces.new(p1)
                if isMobilePlayer() then
                    checkToLockCameraRotation()
                end
                for k, v in pairs(t) do
                    v.Visible = false
                end
                v3.Visible = false
            end)
            if v16 then
                v16:Disconnect()
                v16 = nil
            end
            v16 = v12.MouseButton1Up:Connect(function(p1)
                local oldPos = v22
                v22 = v12.Adornee.CFrame
                v14 = false
                v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do
                    v.Visible = true
                end
                v3.Visible = true
                local currentMode = v9.Mode.Value
                if oldPos == v22 and currentMode ~= "Mirror" then
                    return
                end
                if currentMode == "Mirror" then
                    local offset = nil
                    if p1 == Enum.NormalId.Right then
                        offset = Vector3.new(v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Left then
                        offset = Vector3.new(-v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Top then
                        offset = Vector3.new(0, v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Bottom then
                        offset = Vector3.new(0, -v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Back then
                        offset = Vector3.new(0, 0, v11.size.Z / 2)
                    elseif p1 == Enum.NormalId.Front then
                        offset = Vector3.new(0, 0, -v11.size.Z / 2)
                    end
                    v22 = CFrame.new((oldPos * CFrame.new(offset)).p, oldPos.p)
                end
                performServerOperatoin(oldPos, v22)
            end)
            if v18 then
                v18:Disconnect()
                v18 = nil
            end
            v8 = v12.MouseDrag:Connect(function(face, distance)
                if v9.Mode.Value == "Mirror" then
                    return
                end
                local step = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if step ~= 0 then
                    distance = distance - distance % step
                end
                local target = nil
                if face == Enum.NormalId.Right then
                    target = v22 * CFrame.new(distance, 0, 0)
                elseif face == Enum.NormalId.Left then
                    target = v22 * CFrame.new(-distance, 0, 0)
                elseif face == Enum.NormalId.Top then
                    target = v22 * CFrame.new(0, distance, 0)
                elseif face == Enum.NormalId.Bottom then
                    target = v22 * CFrame.new(0, -distance, 0)
                elseif face == Enum.NormalId.Back then
                    target = v22 * CFrame.new(0, 0, distance)
                elseif face == Enum.NormalId.Front then
                    target = v22 * CFrame.new(0, 0, -distance)
                end
                v11.CFrame = if target then target else v22
            end)
            v13 = Instance.new("ArcHandles")
            v13.Name = "RotateHandle"
            v13.Adornee = v11
            v13.Visible = false
            v13.Parent = LocalPlayer.PlayerGui
            if v20 then
                v20:Disconnect()
                v20 = nil
            end
            v20 = v13.MouseButton1Down:Connect(function(p1)
                v14 = true
                v22 = v13.Adornee.CFrame
                v11:BreakJoints()
                v13.Axes = Axes.new(p1)
                if isMobilePlayer() then
                    checkToLockCameraRotation()
                end
                for k, v in pairs(t) do
                    v.Visible = false
                end
                v3.Visible = false
            end)
            if v19 then
                v19:Disconnect()
                v19 = nil
            end
            v19 = v13.MouseButton1Up:Connect(function(p1)
                local oldRot = v22
                v22 = v13.Adornee.CFrame
                v14 = false
                v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
                checkToUnlockCameraRotation()
                for k, v in pairs(t) do
                    v.Visible = true
                end
                v3.Visible = true
                if oldRot == v22 then
                    return
                end
                performServerOperatoin(oldRot, v22)
            end)
            v21 = v13.MouseDrag:Connect(function(axis, angle, p3)
                if math.deg(angle) < -180 then
                    angle = angle + 6.283185307179586
                elseif math.deg(angle) > 180 then
                    angle = angle - 6.283185307179586
                end
                local step = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if step ~= 0 then
                    angle = math.rad(step * math.round(math.deg(angle) / step))
                end
                local target = nil
                if axis == Enum.Axis.X then
                    target = v22 * CFrame.Angles(angle, 0, 0)
                elseif axis == Enum.Axis.Y then
                    target = v22 * CFrame.Angles(0, angle, 0)
                elseif axis == Enum.Axis.Z then
                    target = v22 * CFrame.Angles(0, 0, angle)
                end
                v11.CFrame = if target then target else v22
            end)
        end
        local selected = getSelectedModels()
        local count = #selected
        if count < 1 then
            removeBoundingBox()
        else
            table.sort(selected, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then
                    return true
                end
            end)
            local primary = selected[count].PrimaryPart
            local center, size = GetBoundingBox(selected, primary.CFrame - primary.Position)
            v11.Size = size
            v11.CFrame = center
        end
    end

    local function mouseMove()
        if v10 then
            v10.Color3 = Color3.fromRGB(0, 134, 171)
        end
        local target = v1.Target
        if not target or (not target.Parent or isMobilePlayer()) then
            v3.Adornee = nil
            return
        end
        local item, _, tag = GetBlockInfo(target, LocalPlayer)
        local shifting = doingShiftSelect()
        v3.Visible = true
        if shifting then
            if t[item] then
                t[item].Color3 = Color3.fromRGB(175, 0, 0)
                v10 = t[item]
                v3.Visible = false
            end
        else
            if v3.Adornee and t[v3.Adornee] then
                v3.Adornee = nil
            end
            if t[item] then
                v3.Visible = false
            end
        end
        if tag then
            v3.Adornee = item
            local _, size = item:GetBoundingBox()
            v3.LineThickness = math.min(size.X, size.Y, size.Z, 2) / 13.334
        else
            v3.Adornee = nil
        end
    end

    local function checkForDragSelection(p1, p2, p3)
        local dragging = v25 and not p1 or (if p1 then v27 else p1)
        if not dragging then
            return
        end
        local box = v9.SelectionBox
        local pos1 = if p1 and p2 then p2 else v26
        local pos2 = if p1 and p3 then p3 else Vector2.new(v1.X, v1.Y)
        box.Position = UDim2.new(0, pos1.X, 0, pos1.Y)
        box.Size = UDim2.new(0, pos2.X - pos1.X, 0, pos2.Y - pos1.Y)
        if v28 or (v14 or not pos1) then
            return
        end
        if not p1 and (pos2 - pos1).Magnitude < 24 then
            return
        end
        v28 = true
        if p1 then
            checkToLockCameraRotation()
        end
        box.Visible = true
        while dragging do
            v3.Visible = false
            if not doingShiftSelect() or p1 then
                clearSelected()
            end
            local minY = math.min(box.Position.Y.Offset, box.Position.Y.Offset + box.Size.Y.Offset)
            local maxX = math.max(box.Position.X.Offset, box.Position.X.Offset + box.Size.X.Offset)
            local minX = math.min(box.Position.X.Offset, box.Position.X.Offset + box.Size.X.Offset)
            local maxY = math.max(box.Position.Y.Offset, box.Position.Y.Offset + box.Size.Y.Offset)
            local blocks = workspace.Blocks:GetChildren()
            for i = 1, #blocks do
                local list = blocks[i]:GetChildren()
                for j = 1, #list do
                    local child = list[j]
                    local _, _, tag = GetBlockInfo(child, LocalPlayer)
                    if child.PrimaryPart and tag then
                        local screenPos, visible = CurrentCamera:WorldToScreenPoint(child.PrimaryPart.Position)
                        if visible and (minX < screenPos.X and (screenPos.X < maxX and (minY < screenPos.Y and (screenPos.Y < maxY and not child:FindFirstChild("TrowelSB"))))) then
                            addSelection(child)
                        end
                    end
                end
            end
            task.wait()
            dragging = v25 and not p1 or (if p1 then v27 else p1)
        end
        box.Visible = false
        if v3 then
            v3.Visible = true
        end
        updateBoundingBox()
        updateHandles()
        if not p1 then
            v28 = false
            return
        end
        checkToUnlockCameraRotation()
        v28 = false
    end

    local function activeToolLogic(p1)
        if not v3 or (v23 or v14) then
            return
        end
        local shifting = doingShiftSelect()
        local adornee = v3.Adornee
        if p1 then
            adornee = nil
            local item, _, tag = GetBlockInfo(v1.Target, LocalPlayer)
            if tag and item then
                adornee = item
            end
        end
        if adornee == nil then
            if shifting then
                return
            end
            clearSelected()
            updateBoundingBox()
        else
            local item, _, tag = GetBlockInfo(adornee, LocalPlayer)
            if not tag then
                return
            end
            if shifting then
                if t[item] then
                    removeSelection(item)
                else
                    addSelection(item)
                end
            else
                clearSelected()
                addSelection(item)
            end
            updateBoundingBox()
            updateHandles()
            mouseMove()
        end
    end

    local function inputBegan(p1, p2)
        if p2 then
            return
        end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then
            v25 = true
            v26 = Vector2.new(v1.X, v1.Y)
            activeToolLogic()
            return
        end
        if p1.UserInputType == Enum.UserInputType.Touch then
            if not v14 then
                mouseMove()
                activeToolLogic(true)
            end
        elseif p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 and not GuiService.SelectedObject then
                v25 = true
                v26 = Vector2.new(v1.X, v1.Y)
                activeToolLogic()
            end
        else
            if isMobilePlayer() or not doingShiftSelect() then
                return
            end
            updateHandles()
        end
    end

    local function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement then
            checkForDragSelection()
            mouseMove()
            return
        end
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then
            return
        end
        checkForDragSelection()
        mouseMove()
    end

    local function inputEnded(p1, p2)
        if p2 then
            return
        end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then
            v25 = false
            return
        end
        if p1.UserInputType == Enum.UserInputType.Gamepad1 then
            if p1.KeyCode == Enum.KeyCode.ButtonR2 then
                v25 = false
            end
        else
            if isMobilePlayer() or doingShiftSelect() then
                return
            end
            updateHandles()
        end
    end

    local v31 = nil
    local function inputTouchPinch(p1, p2, p3, p4, p5)
        if p5 then
            return
        end
        local touch1 = p1[1]
        local touch2 = p1[2]
        if p4 == Enum.UserInputState.Begin then
            v31 = (touch2 - touch1).Magnitude
        end
        if not (v31 < 120) then
            return
        end
        v27 = if p4 == Enum.UserInputState.Begin then true else p4 == Enum.UserInputState.Change
        checkForDragSelection(true, touch1, touch2)
    end

    local function modeChanged()
        if v12 and v13 then
            updateBoundingBox()
            updateHandles()
        end
    end

    local function cleanUp()
        if workspace:FindFirstChild("SelectionBox") then
            workspace.SelectionBox:Destroy()
            if v3 then
                v3:Destroy()
                v3 = nil
            end
        end
        if workspace:FindFirstChild("TrowelBoundingBox") then
            workspace.TrowelBoundingBox:Destroy()
            if v11 then
                removeBoundingBox()
            end
        end
        local list = workspace.Blocks:GetChildren()
        for i = 1, #list do
            local items = list[i]:GetChildren()
            for j = 1, #items do
                local item = items[j]
                if item:FindFirstChild("TrowelSB") then
                    item.TrowelSB:Destroy()
                end
            end
        end
        for k, v in pairs(t) do
            v:Destroy()
        end
        t = {}
    end

    local function uneq()
        v25 = false
        v14 = false
        v3:Destroy()
        v3 = nil
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
        v2:Destroy()
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

    activeTools[tool] = {
        c1 = tool.Equipped:connect(eq),
        c2 = tool.Unequipped:connect(uneq),
        original = originalScript
    }
end

local function handleToolInjection(tool)
    if not running then return end
    if activeTools[tool] then return end

    local bScript = tool:FindFirstChild("LocalScript")
    local sScript = tool:FindFirstChild("ScaleLocalScript")
    local tScript = tool:FindFirstChild("TrowelLocalScript")

    if tool.Name == "BuildingTool" and bScript then
        dprint("Injecting BuildingTool")
        bScript.Disabled = true
        setupBuildingTool(tool, bScript)
    elseif tool.Name == "ScalingTool" and sScript then
        dprint("Injecting ScalingTool")
        sScript.Disabled = true
        setupScalingTool(tool, sScript)
    elseif tool.Name == "TrowelTool" and tScript then
        dprint("Injecting TrowelTool")
        tScript.Disabled = true
        setupTrowelTool(tool, tScript)
    end
end

local function monitorInstance(container)
    local conn = container.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            handleToolInjection(child)
        end
    end)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("Tool") then
            handleToolInjection(child)
        end
    end
    return conn
end

local backpackConn = monitorInstance(LocalPlayer:WaitForChild("Backpack"))
local characterConn = nil

local function onCharacter(char)
    if characterConn then characterConn:Disconnect() end
    characterConn = monitorInstance(char)
end

if LocalPlayer.Character then
    onCharacter(LocalPlayer.Character)
end
local charAddedConn = LocalPlayer.CharacterAdded:Connect(onCharacter)

function unloadtoolmod()
    running = false
    dprint("Unloading tool mods")
    if backpackConn then backpackConn:Disconnect() end
    if characterConn then characterConn:Disconnect() end
    if charAddedConn then charAddedConn:Disconnect() end

    for tool, data in pairs(activeTools) do
        if data.c1 then data.c1:Disconnect() end
        if data.c2 then data.c2:Disconnect() end
        if data.original and data.original.Parent then
            data.original.Disabled = false
        end
    end
    table.clear(activeTools)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local LocalizationService = game:GetService("LocalizationService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local debugp = false

local function dprint(...)
	if debugp then
		print(...)
	end
end

_G.DisableToolLimit = false
_G.FullPlace = false

local function cleanToolScripts(tool)
	for _, child in pairs(tool:GetChildren()) do
		if child:IsA("LocalScript") then
			child.Disabled = true
			Debris:AddItem(child, 0)
		end
	end
end

local function handleBuildingTool(v2)
	cleanToolScripts(v2)
	dprint("Initializing modified BuildingTool")

	local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
	local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
	local v1 = LocalPlayer:GetMouse()
	local CurrentCamera = workspace.CurrentCamera
	local v3, v4, v5, v6, v7, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v26
	local v8 = CFrame.new()

	local function normalIdToNormalVector(p1, p2)
		if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
		if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
		if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
		if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
		if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
		return Vector3.new(-1, 0, 0), p2.Size.X
	end

	local function roundVectorToBase(p1, p2)
		local val = 1 / p2
		local v2_ = p1 * val + Vector3.new(0.5, 0.5, 0.5)
		return Vector3.new(math.floor(v2_.X), math.floor(v2_.Y), (math.floor(v2_.Z))) / val
	end

	local function changeTransparency(p1, p2)
		local v1_ = p1:GetDescendants()
		for i = 1, #v1_ do
			if v1_[i]:IsA("BasePart") then
				if CollectionService:HasTag(v1_[i], "NoTransparency") then
					v1_[i].Transparency = 0
					continue
				end
				if CollectionService:HasTag(v1_[i], "FullTransparency") then
					v1_[i].Transparency = 1
					continue
				end
				v1_[i].Transparency = p2
			end
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
			return true, ""
		end
		local v2_ = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
		local v32 = isPartInZone(p1.PrimaryPart, v2_)
		local v4_ = if v32 then nil else "Out of bounds"
		local v5_, v6_ = QuestConditions(v2_, p1.PrimaryPart.CFrame, v3.Name, 1, LocalPlayer)
		local v7_, v8_ = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
		local v9_, v10_ = ChallengeConditions.itemRestriction(LocalPlayer, v3.Name)
		return if v32 then if v5_ then not v7_ and not v9_ else v5_ else v32, if v4_ then v4_ elseif v6_ then v6_ elseif v8_ then v8_ else v10_
	end

	local function getType(p1)
		local v1_ = string.match(p1.TypeIcon.Image, "%d+")
		if v1_ == "4597411234" then return "Block" end
		if v1_ == "4597402658" then return "Decoration" end
		return "Special"
	end

	local function isSpeedBuild()
		local SpeedBuild = LocalPlayer.OtherData:FindFirstChild("SpeedBuild")
		if SpeedBuild and SpeedBuild.Value then return true end
		return nil
	end

	local function fitBuildScroll()
		local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
		local v1_ = ScrollingFrame.BlocksFrame:GetChildren()
		local v2_ = nil
		local v3_ = nil
		for i = 1, #v1_ do
			if v1_[i]:IsA("GuiObject") and v1_[i].Visible then
				if not v2_ or v2_ < v1_[i].AbsolutePosition.Y then v2_ = v1_[i].AbsolutePosition.Y end
				if not v3_ or v1_[i].AbsolutePosition.Y < v3_ then v3_ = v1_[i].AbsolutePosition.Y end
			end
		end
		if v3_ and v2_ then
			ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, v2_ - v3_ + 100)
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
		local v1_ = LocalPlayer
		local v2_ = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
		if v2_ and LocalPlayer.Settings.ShareBlocks.Value then v1_ = v2_ end
		local v3_ = v1_.Name
		local BuildGui = LocalPlayer.PlayerGui.BuildGui
		local SearchFrame = BuildGui.SearchFrame
		local v4_ = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
		local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
		local v5_ = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()
		for i = 1, #v5_ do
			local v6_ = v5_[i]
			if ReplicatedStorage.BuildingParts:FindFirstChild(v6_.Name) then
				local v8_ = getType(v6_)
				local v9_ = game.Players:FindFirstChild(v3_).Data[v6_.Name].Value
				local v10_ = string.split(v6_.Tags.Value, " ")
				local v11_ = false
				if SearchFrame.OnlySearch.Value then
					local ok, result = pcall(function()
						return LocalizationService:GetTranslatorForPlayerAsync(game.Players.LocalPlayer)
					end)
					if ok then
						local v13_ = string.lower((result:Translate(TagsFrame.Parent.BlockName, v6_.BlockName.Value)))
						if string.find(v13_, v4_) or string.find(v4_, v13_) then v11_ = true end
						if not v11_ then
							for j = 1, #v10_ do
								local v15_ = string.lower((result:Translate(TagsFrame, v10_[j])))
								if string.find(v15_, v4_) or string.find(v4_, v15_) then
									v11_ = true
									break
								end
							end
						end
					end
				end
				if v9_ == 0 or SearchFrame.OnlyBlocks.Value and v8_ ~= "Block" or (SearchFrame.OnlyDecorations.Value and v8_ ~= "Decoration" or SearchFrame.OnlySpecial.Value and v8_ ~= "Special") then
					v6_.Visible = false
				else
					if SearchFrame.OnlySearch.Value and not v11_ then
						v6_.Visible = false
						continue
					end
					v6_.Visible = true
				end
			end
		end
		fitBuildScroll()
		setSpeedBuildGuiLook()
	end

	local function updateBlockCF(p1)
		if not v1.Target then return end
		local v12_ = v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3
		if not p1 then
			v5 = v1.Target
			v6 = v1.Hit
			v7 = v1.TargetSurface
		end
		local v2_ = v8
		local v32 = (v5.CFrame - v5.Position):Inverse()
		if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
			v32 = CFrame.new(0, 0, 0)
		end
		local v52, v62 = normalIdToNormalVector(v7, v5)
		local v82 = v5.CFrame * CFrame.new(v52 * (v62 / 2))
		v12_:SetPrimaryPartCFrame(v82 * v32 * v2_)
		local v9_ = (v5.CFrame - v5.Position):PointToWorldSpace(v52)
		local v10_ = v12_.PrimaryPart.CFrame.RightVector:Dot(v9_)
		local v112 = v12_.PrimaryPart.CFrame.UpVector:Dot(v9_)
		local v122 = v12_.PrimaryPart.CFrame.LookVector:Dot(v9_)
		local v13_ = math.abs(v10_)
		local v14_ = math.abs(v112)
		local v15_ = math.abs(v122)
		v12_:SetPrimaryPartCFrame(v82 * v32:Inverse() * v2_:Inverse())
		local v17_ = v82 * CFrame.new(v52 * (v13_ * (v12_.PrimaryPart.Size.X / 2) + v14_ * (v12_.PrimaryPart.Size.Y / 2) + v15_ * (v12_.PrimaryPart.Size.Z / 2)))
		local v18_ = v5.CFrame:PointToObjectSpace(v6.p)
		local v19_ = if v7 == Enum.NormalId.Top or v7 == Enum.NormalId.Bottom then v18_ - Vector3.new(0, v18_.Y, 0) elseif v7 == Enum.NormalId.Front or v7 == Enum.NormalId.Back then v18_ - Vector3.new(0, 0, v18_.Z) else v18_ - Vector3.new(v18_.X, 0, 0)
		local v20_ = tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Move.TextLabel.Text) or 1
		if v20_ ~= 0 then v19_ = roundVectorToBase(v19_, v20_) end
		v12_:SetPrimaryPartCFrame(v17_ * CFrame.new(v19_) * v32 * v2_)
		if not v3:FindFirstChild("CanPlace") then
			local CanPlace = Instance.new("BoolValue")
			CanPlace.Name = "CanPlace"
			CanPlace.Value = true
			CanPlace.Parent = v3
		end
		local v22_ = canPlace(v12_)
		if _G.DisableToolLimit or v3.CanPlace.Value or not v22_ then
			if not _G.DisableToolLimit and (not v3.CanPlace.Value or v22_) then return end
			if not _G.DisableToolLimit then
				v3.CanPlace.Value = false
				v11 = {}
				local v23_ = v3:GetDescendants()
				for i = 1, #v23_ do
					if v23_[i]:IsA("BasePart") then
						table.insert(v11, v23_[i].Color)
						v23_[i].BrickColor = BrickColor.Red()
					end
				end
			else
				v3.CanPlace.Value = true
				if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
			end
		else
			v3.CanPlace.Value = true
			local v25_ = v3:GetDescendants()
			local count = 1
			for j = 1, #v25_ do
				if v25_[j]:IsA("BasePart") then
					v25_[j].Color = v11[count]
					count = count + 1
				end
			end
			if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end
		end
	end

	local function resetRotation()
		if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
			v8 = CFrame.new()
		else
			local v1_ = workspace
			local v2_ = v1_[tostring(LocalPlayer.TeamColor) .. "Zone"]
			v8 = (v2_.CFrame - v2_.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
		end
	end

	local function WeldTogether(p1, p2, p3, p4)
		if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then return end
		local v1_ = Instance.new(p3 or "Weld")
		v1_.Part0 = p1
		v1_.Part1 = p2
		v1_.C0 = CFrame.new()
		v1_.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
		v1_.Parent = p4 or p1
		return v1_
	end

	local function prepareItem()
		v1.TargetFilter = v3
		changeTransparency(v3, 0.5)
		local v12_ = v3:GetDescendants()
		for i = 1, #v12_ do
			if v12_[i]:IsA("BasePart") then
				v12_[i].Anchored = true
				v12_[i].CanCollide = false
				v12_[i].CanQuery = false
				if v12_[i] ~= v3.PrimaryPart then WeldTogether(v3.PrimaryPart, v12_[i]) end
			end
		end
	end

	local function itemChanged(p1)
		local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
		local v1_ = ReplicatedStorage.BuildingParts:FindFirstChild(Selected)
		updateBuildGui()
		local v2_ = v3.PrimaryPart.CFrame
		v3:Destroy()
		v3 = v1_:Clone()
		v3:SetPrimaryPartCFrame(CFrame.new(v2_.p) * v1_.PrimaryPart.CFrame.Rotation)
		resetRotation()
		prepareItem()
		updateBlockCF()
		v3.Parent = workspace
		local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
		local v32 = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
		local v4_ = TagsFrame:GetChildren()
		local TextLabel = TagsFrame.TextLabel
		for i = 1, #v32 do
			local v5_ = TextLabel:Clone()
			v5_.Text = string.lower(v32[i])
			v5_.Parent = TextLabel.Parent
		end
		for j = 1, #v4_ do v4_[j]:Destroy() end
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

	local function placeBlock(p1)
		if v25 or not v3 then return end
		if v3:FindFirstChild("OutOfBoundsBG") then v3.OutOfBoundsBG:Destroy() end

		local v22_, v32 = canPlace(v3:FindFirstChild("2ndPlacement") and v3.SecondaryPart or v3)
		if not _G.DisableToolLimit and not v22_ then
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
		task.spawn(function()
			task.wait()
			v25 = false
		end)

		local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
		local AmountText = v52.AmountText
		local MaxText = v52.MaxText
		local blockCount = tonumber(AmountText.Text) or 0

		if not _G.DisableToolLimit and blockCount <= 0 then
			local v6_ = v2.ClickSound:Clone()
			v6_.Parent = v3.PrimaryPart
			Debris:AddItem(v6_, 0.3)
			v6_.PlaybackSpeed = 5
			v6_:Play()
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
			local v9_ = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"
			if v9_ then
				local v10_ = v3:FindFirstChild("2ndPlacement")
				if not v10_ then
					local v11_ = Instance.new("BoolValue")
					v11_.Name = "2ndPlacement"
					v11_.Parent = v3
					updateBlockCF()
					return
				end
				v10_:Destroy()
			end

			local v122 = if v9_ then v3.SecondaryPart.PrimaryPart.CFrame else v9_
			changeTransparency(v3, 0)
			Debris:AddItem(v3, 10)

			local v13_ = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
			local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value

			local v15_ = v2.ClickSound:Clone()
			v15_.Parent = v3.PrimaryPart
			Debris:AddItem(v15_, 1)
			v15_.PlaybackSpeed = 1
			v15_:Play()

			if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
				resetRotation()
			end

			local v16_ = v3
			v3 = v3:Clone()
			changeTransparency(v3, 0.5)
			v3.Parent = workspace
			v1.TargetFilter = v3

			local v17_ = v16_:GetDescendants()
			for i = 1, #v17_ do
				if v17_[i]:IsA("BasePart") then v17_[i].CanQuery = true end
			end

			local v19_ = v5
			updateBlockCF(p1)
			updateBuildGui()

			local originalDataValue = LocalPlayer.Data:FindFirstChild(v16_.Name).Value

			if _G.FullPlace then
				local loops = math.max(1, blockCount)
				task.spawn(function()
					for i = 1, loops do
						if not v9_ then
							v2.RF:InvokeServer(v16_.Name, originalDataValue, v19_, v13_, Anchor, v16_.PrimaryPart.CFrame, v122)
						else
							v2.RF:InvokeServer(v16_.Name, originalDataValue, v19_, v13_, Anchor, v16_.PrimaryPart.CFrame, v122)
						end
						if i < loops then task.wait(0.2) end
					end
					v16_:Destroy()
				end)
			else
				if not v9_ then
					v2.RF:InvokeServer(v16_.Name, originalDataValue, v19_, v13_, Anchor, v16_.PrimaryPart.CFrame, v122)
					v16_:Destroy()
				else
					local v20_ = ReplicatedStorage.BuildingParts[v3.Name]
					v3.SecondaryPart.PrimaryPart.CFrame = v3.PrimaryPart.CFrame * v20_.PrimaryPart.CFrame:ToObjectSpace(v20_.SecondaryPart.PrimaryPart.CFrame)
					v2.RF:InvokeServer(v16_.Name, originalDataValue, v19_, v13_, Anchor, v16_.PrimaryPart.CFrame, v122)
					v16_:Destroy()
				end
			end
		end
	end

	local function uneq()
		if not v3 then return end
		v4 = v3.Name
		v3:Destroy()
		v12:Disconnect()
		v12 = nil
		v13:Disconnect()
		v13 = nil
		v14:Disconnect()
		v14 = nil
		v15:Disconnect()
		v15 = nil
		v16:Disconnect()
		v16 = nil
		v17:Disconnect()
		v17 = nil
		v18:Disconnect()
		v18 = nil
		v19:Disconnect()
		v19 = nil
		v20:Disconnect()
		v20 = nil
		v21:Disconnect()
		v21 = nil
		v22:Disconnect()
		v22 = nil
		v23:Disconnect()
		v23 = nil
		v24:Disconnect()
		v24 = nil
		LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
		local BuildGui = LocalPlayer.PlayerGui.BuildGui
		BuildGui.InventoryFrame.Visible = false
		BuildGui.Clear.Visible = false
		BuildGui.ScaleButton.Visible = false
		BuildGui.SearchFrame.Visible = false
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
			if p1.KeyCode == Enum.KeyCode.R then
				rotateY()
				return
			end
			if p1.KeyCode == Enum.KeyCode.T then rotateX() end
		else
			if p1.UserInputType == Enum.UserInputType.MouseButton1 then
				placeBlock()
				return
			end
			if p1.UserInputType == Enum.UserInputType.Touch then
				LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
				if isSpeedBuild() then v10 = v1.Hit else updateBlockCF() end
				return
			end
			if p1.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
			if p1.KeyCode == Enum.KeyCode.ButtonR2 then
				placeBlock()
				return
			end
			if p1.KeyCode == Enum.KeyCode.ButtonX then
				rotateY()
				return
			end
			if p1.KeyCode ~= Enum.KeyCode.ButtonY then return end
			rotateX()
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
			if not _G.DisableToolLimit and v9 == v3.PrimaryPart.CFrame and not (if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope") then return end
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

	v2.Equipped:Connect(eq)
	v2.Unequipped:Connect(uneq)
end

local function handleScalingTool(v2)
	cleanToolScripts(v2)
	dprint("Initializing modified ScalingTool")

	local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
	local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
	local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)
	local CurrentCamera = workspace.CurrentCamera
	local v1 = LocalPlayer:GetMouse()
	local v2_ = nil
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
		if v16 then return false, p1 end
		local v1_, _, v22 = GetBlockInfo(p1, LocalPlayer)
		if _G.DisableToolLimit and v1_ then return true, v1_ end
		if v22 and string.find(v1_.Name, "Block") then return true, v1_ end
		return false
	end

	local function isPartInZone(p1, p2)
		local v1_ = if typeof(p1) == "CFrame" then p1.Position else p1.Position
		local Position = p2.Position
		local Size = p2.Size
		local X = Size.X
		local Y = Size.Y
		local Z = Size.Z
		if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
			X = Size.Z
			Z = Size.X
		end
		return v1_.X > Position.X - X / 2 and (v1_.X < Position.X + X / 2 and (v1_.Z > Position.Z - Z / 2 and v1_.Z < Position.Z + Z / 2))
	end

	local function updateBlocks()
		local v1_ = LocalPlayer
		local v22 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
		if v22 and LocalPlayer.Settings.ShareBlocks.Value then v1_ = v22 end
		local v5_ = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
		local v6_ = v4.Adornee.Parent.Name
		v13 = game.Players:FindFirstChild(v1_.Name).Data:FindFirstChild(v6_).Value
		local v7_ = workspace.Blocks:GetChildren()
		local sum = 0
		for i = 1, #v7_ do
			local v8_ = v7_[i]:GetChildren()
			for j = 1, #v8_ do
				local v9_ = v8_[j]
				local _, _2, v10_ = GetBlockInfo(v9_, LocalPlayer)
				if v10_ and (v9_.Name == v6_ and (v9_.PrimaryPart and isPartInZone(v9_.PrimaryPart, v5_))) then
					sum = sum + math.max(v9_.PrimaryPart.Size.X * v9_.PrimaryPart.Size.Y * v9_.PrimaryPart.Size.Z / v15, 1)
				end
			end
		end
		v14 = sum
		v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
		v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(v6_).Image
		v12.Parent = LocalPlayer.PlayerGui
	end

	local function updateBlocksSoft(p1, p2)
		local v1_ = LocalPlayer
		local v22 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
		if v22 and LocalPlayer.Settings.ShareBlocks.Value then v1_ = v22 end
		v13 = game.Players:FindFirstChild(v1_.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
		v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)
		local v7_ = math.floor(v13 - v14)
		v12.BlockImage.AmountText.Text = tostring(v7_)
		return v7_
	end

	local function roundToNearestThousands(p1)
		return math.floor(p1 * 1000 + 0.5) / 1000
	end

	local function lockCameraRotation()
		v17 = true
		CurrentCamera.CameraType = Enum.CameraType.Scriptable
		local CameraSubject = CurrentCamera.CameraSubject
		if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
		local v1_ = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
		local v22 = CurrentCamera.CFrame - CurrentCamera.CFrame.p
		RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
			CurrentCamera.CFrame = v22 + CameraSubject.CFrame.p - v1_
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
		local Target = v1.Target
		if not (Target and Target.Parent) then
			v2_.Adornee = nil
			return
		end
		local v12_, v22_ = canSelect(Target)
		if v4 and (v2_.Adornee and v4.Adornee == v2_.Adornee.PrimaryPart) then v2_.Adornee = nil end
		if v4 and (v22_ and (v22_:IsA("Model") and v4.Adornee == v22_.PrimaryPart)) then
			v2_.Adornee = nil
			return
		end
		if v2_.Adornee == v22_ then return end
		if v12_ then
			v2_.Adornee = v22_
			local Size = v22_.PrimaryPart.Size
			v2_.LineThickness = math.min(Size.X, Size.Y, Size.Z, 2) / 13.334
			if p1 then
				LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = true
				LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = false
				LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = false
				LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = false
			end
		else
			v2_.Adornee = nil
			if not p1 then return end
			LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
		end
	end

	local function active(p1)
		if not v2_ then return end
		local Adornee = v2_.Adornee
		if Adornee == nil then return end
		local v1_, v22_ = canSelect(Adornee)
		if v1_ then
			local Size = v22_.PrimaryPart.Size
			local Size2 = ReplicatedStorage.BuildingParts:FindFirstChild(v22_.Name).PrimaryPart.Size
			v15 = Size2.X * Size2.Y * Size2.Z
			if v4 then
				v4.Adornee = v22_.PrimaryPart
			else
				v4 = Instance.new("Handles")
				v4.Adornee = v22_.PrimaryPart
				v4.Style = Enum.HandlesStyle.Resize
				v4.Color3 = Color3.fromRGB(172, 78, 1)
				v4.Parent = LocalPlayer.PlayerGui
			end
			local v3_ = nil
			local v42 = nil
			local v52 = nil
			if v7 then
				v7:Disconnect()
				v7 = nil
			end
			v7 = v4.MouseButton1Down:Connect(function()
				v16 = true
				v3_ = v4.Adornee.CFrame
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
			local v9_ = roundToNearestThousands
			local Y = v4.Adornee.Size.Y
			local v10_ = tostring(v9_(Y))
			local v11_ = roundToNearestThousands
			local Z = v4.Adornee.Size.Z
			SizeDisplay.Text = v82 .. "," .. v10_ .. "," .. tostring(v11_(Z))
			if v8 then
				v8:Disconnect()
				v8 = nil
			end
			v8 = v4.MouseDrag:Connect(function(p1_, p2)
				local v1__ = tonumber(v12.BlockImage.More.Scale.TextBox.Text)
				if v1__ ~= 0 then p2 = p2 - p2 % v1__ end
				if p1_ == Enum.NormalId.Right then
					if v52.X + p2 <= 0.05 then
						local v23_ = v52.X % v1__
						if v1__ == 0 then v23_ = 0.05 end
						if v23_ < 0.05 then v23_ = v1__ end
						v6 = Vector3.new(v23_, v52.Y, v52.Z)
						v42 = v3_ * CFrame.new(-(v52.X - v6.X) / 2, 0, 0)
					else
						v42 = v3_ * CFrame.new(p2 / 2, 0, 0)
						v6 = v52 + Vector3.new(p2, 0, 0)
					end
				elseif p1_ == Enum.NormalId.Left then
					if v52.X + p2 <= 0.05 then
						local v43 = v52.X % v1__
						if v1__ == 0 then v43 = 0.05 end
						if v43 <= 0.05 then v43 = v1__ end
						v6 = Vector3.new(v43, v52.Y, v52.Z)
						v42 = v3_ * CFrame.new(-(-(v52.X - v6.X)) / 2, 0, 0)
					else
						v42 = v3_ * CFrame.new(-p2 / 2, 0, 0)
						v6 = v52 + Vector3.new(p2, 0, 0)
					end
				elseif p1_ == Enum.NormalId.Top then
					if v52.Y + p2 <= 0.05 then
						local v6_ = v52.Y % v1__
						if v1__ == 0 then v6_ = 0.05 end
						if v6_ <= 0.05 then v6_ = v1__ end
						v6 = Vector3.new(v52.X, v6_, v52.Z)
						v42 = v3_ * CFrame.new(0, -(v52.Y - v6.Y) / 2, 0)
					else
						v42 = v3_ * CFrame.new(0, p2 / 2, 0)
						v6 = v52 + Vector3.new(0, p2, 0)
					end
				elseif p1_ == Enum.NormalId.Bottom then
					if v52.Y + p2 <= 0.05 then
						local v8_ = v52.Y % v1__
						if v1__ == 0 then v8_ = 0.05 end
						if v8_ <= 0.05 then v8_ = v1__ end
						v6 = Vector3.new(v52.X, v8_, v52.Z)
						v42 = v3_ * CFrame.new(0, -(-(v52.Y - v6.Y)) / 2, 0)
					else
						v42 = v3_ * CFrame.new(0, -p2 / 2, 0)
						v6 = v52 + Vector3.new(0, -p2, 0)
					end
				elseif p1_ == Enum.NormalId.Back then
					if v52.Z + p2 <= 0.05 then
						local v10_ = v52.Z % v1__
						if v1__ == 0 then v10_ = 0.05 end
						if v10_ <= 0.05 then v10_ = v1__ end
						v6 = Vector3.new(v52.X, v52.Y, v10_)
						v42 = v3_ * CFrame.new(0, 0, -(v52.Z - v6.Z) / 2)
					else
						v42 = v3_ * CFrame.new(0, 0, p2 / 2)
						v6 = v52 + Vector3.new(0, 0, p2)
					end
				elseif p1_ == Enum.NormalId.Front then
					if v52.Z + p2 <= 0.05 then
						local v122 = v52.Z % v1__
						if v1__ == 0 then v122 = 0.05 end
						if v122 <= 0.05 then v122 = v1__ end
						v6 = Vector3.new(v52.X, v52.Y, v122)
						v42 = v3_ * CFrame.new(0, 0, -(-(v52.Z - v6.Z)) / 2)
					else
						v42 = v3_ * CFrame.new(0, 0, -p2 / 2)
						v6 = v52 + Vector3.new(0, 0, p2)
					end
				end
				v6 = Vector3.new(math.max(v6.X, 0.05), math.max(v6.Y, 0.05), (math.max(v6.Z, 0.05)))
				local v17_ = Size
				local v19_ = v6.X * v6.Y * v6.Z / v15 - v17_.X * v17_.Y * v17_.Z / v15
				local v21 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
				local v22 = _G.DisableToolLimit or (isPartInZone(v42 * CFrame.new(v6.X / 2, 0, 0), v21) and (isPartInZone(v42 * CFrame.new(-v6.X / 2, 0, 0), v21) and (isPartInZone(v42 * CFrame.new(0, v6.Y / 2, 0), v21) and (isPartInZone(v42 * CFrame.new(0, -v6.Y / 2, 0), v21) and (isPartInZone(v42 * CFrame.new(0, 0, v6.Z / 2), v21) and (isPartInZone(v42 * CFrame.new(0, 0, -v6.Z / 2), v21) and (QuestConditions(v21, v42 * CFrame.new(v6.X / 2, 0, 0), "", v19_, LocalPlayer) and (QuestConditions(v21, v42 * CFrame.new(-v6.X / 2, 0, 0), "", v19_, LocalPlayer) and (QuestConditions(v21, v42 * CFrame.new(0, v6.Y / 2, 0), "", v19_, LocalPlayer) and (QuestConditions(v21, v42 * CFrame.new(0, -v6.Y / 2, 0), "", v19_, LocalPlayer) and (QuestConditions(v21, v42 * CFrame.new(0, 0, v6.Z / 2), "", v19_, LocalPlayer) and QuestConditions(v21, v42 * CFrame.new(0, 0, -v6.Z / 2), "", v19_, LocalPlayer))))))))))))
				local v23 = updateBlocksSoft(v4.Adornee.Size, v6)
				local v24 = not _G.DisableToolLimit and ChallengeConditions.blockLimitChallengeReached(LocalPlayer, v19_)
				if _G.DisableToolLimit or (v23 >= 0 and v22 and not v24) then
					if v4.Adornee.Size == v6 then return end
					v4.Adornee:BreakJoints()
					v4.Adornee.CFrame = v42 or v3_
					v4.Adornee.Size = v6 or v52
					local v28 = tostring(roundToNearestThousands(v4.Adornee.Size.X))
					local v30 = tostring(roundToNearestThousands(v4.Adornee.Size.Y))
					v12.BlockImage.SizeDisplay.Text = v28 .. "," .. v30 .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
					return
				end
				updateBlocksSoft(v6, v4.Adornee.Size)
				local AmountText = v12.BlockImage.AmountText
				local MaxText = v12.BlockImage.MaxText
				local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
				if v24 then RestrictionMetFrame.Visible = true else MaxText.Visible = true AmountText.Visible = false end
				local v32 = v2.ClickSound:Clone()
				v32.Parent = v4.Adornee
				Debris:AddItem(v32, 0.3)
				v32.PlaybackSpeed = 5
				v32:Play()
				if not v24 then
					task.wait(0.5)
					MaxText.Visible = false
					AmountText.Visible = true
					return
				end
				task.wait(3)
				RestrictionMetFrame.Visible = false
			end)
			if v6 then
				v6:Disconnect()
				v6 = nil
			end
			v6 = v4.MouseButton1Up:Connect(function()
				v3_ = v4.Adornee.CFrame
				v52 = v4.Adornee.Size
				local v1__, v23_ = v2.RF:InvokeServer(v4.Adornee.Parent, v52, v3_)
				Size = v52
				if v1__ then
					v22_.PrimaryPart.Size = v1__
					v22_.PrimaryPart.CFrame = v23_
					updateBlocks()
				end
				v16 = false
				if not p1 then return end
				checkToUnlockCameraRotation()
			end)
			if v5 then
				v5:Disconnect()
				v5 = nil
			end
			v5 = v2.Unequipped:Connect(function()
				v3_ = v4.Adornee.CFrame
				v52 = v4.Adornee.Size
				local v1__, v23_ = v2.RF:InvokeServer(v4.Adornee.Parent, v52, v3_)
				Size = v52
				if not v1__ then
					v16 = false
					v5:Disconnect()
					v5 = nil
					return
				end
				v22_.PrimaryPart.Size = v1__
				v22_.PrimaryPart.CFrame = v23_
				v16 = false
				v5:Disconnect()
				v5 = nil
			end)
			updateBlocks()
		end
		mouseMove()
	end

	local function uneq()
		if v2_ then v2_:Destroy() v2_ = nil end
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

	local function inputBegan(p1, p2)
		if p2 then return end
		if p1.UserInputType == Enum.UserInputType.MouseButton1 then
			active()
			return
		end
		if p1.UserInputType == Enum.UserInputType.Touch then
			mouseMove(true)
			return
		end
		if p1.UserInputType ~= Enum.UserInputType.Gamepad1 or p1.KeyCode ~= Enum.KeyCode.ButtonR2 then return end
		active()
	end

	local function inputChanged(p1, p2)
		if p1.UserInputType ~= Enum.UserInputType.MouseMovement and (p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2) then return end
		mouseMove(false)
	end

	local function died()
		uneq()
		v2:Destroy()
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
		v2_ = Instance.new("SelectionBox", workspace)
		v2_.Color3 = Color3.fromRGB(172, 109, 0)
		v2_.SurfaceColor3 = Color3.fromRGB(172, 172, 0)
		v2_.SurfaceTransparency = 0.5
		v12.BlockImage.Visible = true
	end

	v2.Equipped:connect(eq)
	v2.Unequipped:connect(uneq)
end

local function handleTrowelTool(v2)
	cleanToolScripts(v2)
	dprint("Initializing modified TrowelTool")

	local GetBlockInfo = require(ReplicatedStorage.Scripts.GetBlockInfo)
	local v1 = LocalPlayer:GetMouse()
	local CurrentCamera = workspace.CurrentCamera
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
	local QuestConditions = require(ReplicatedStorage.Scripts.QuestConditions)
	local ChallengeConditions = require(ReplicatedStorage.Scripts.ChallengeConditions)
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
		local t2_ = {}
		for k, v in pairs(t) do table.insert(t2_, k) end
		return t2_
	end

	local function getBlockValue(p1)
		local v1_ = p1.Name
		local v2_
		if string.find(v1_, "Block") then
			local Size = ReplicatedStorage.BuildingParts[v1_].PrimaryPart.Size
			local Size2 = p1.PrimaryPart.Size
			v2_ = math.max(Size2.X * Size2.Y * Size2.Z / (Size.X * Size.Y * Size.Z), 1)
		else
			v2_ = 1
		end
		return v2_
	end

	local function updateBlockDisplayImage(p1)
		if v9.ModeImage.MaxText.Visible then return end
		local v1_ = nil
		local v2_ = true
		local v3_ = true
		for k, v in pairs(t2) do
			v2_ = false
			if v1_ then v3_ = true break end
			v1_ = k
			v3_ = false
		end
		if v2_ then
			v9.ModeImage.Image = ""
			v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
			return
		end
		if v3_ then
			v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
			v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
		else
			v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v1_].Image
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
		local _, v1_ = p1:GetBoundingBox()
		TrowelSB.LineThickness = math.min(v1_.X, v1_.Y, v1_.Z, 2) / 50
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
		local v1_ = t[p1]
		if v1_ then v1_:Destroy() end
		if not v9.ModeImage.MaxText.Visible then
			if t2[p1.Name] then
				local v2_ = t2
				local v3_ = p1.Name
				v2_[v3_] = v2_[v3_] + -1
				if t2[p1.Name] <= 0 then t2[p1.Name] = nil end
			end
			updateBlockDisplayImage(p1.Name)
		end
		t[p1] = nil
		v30 = v30 - getBlockValue(p1)
		v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
	end

	local function isPartInZone(p1, p2)
		local v1_ = if typeof(p1) == "CFrame" then p1.Position else p1.Position
		local Position = p2.Position
		local Size = p2.Size
		local X = Size.X
		local Y = Size.Y
		local Z = Size.Z
		if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
			X = Size.Z
			Z = Size.X
		end
		return v1_.X > Position.X - X / 2 and (v1_.X < Position.X + X / 2 and (v1_.Z > Position.Z - Z / 2 and v1_.Z < Position.Z + Z / 2))
	end

	local function doingShiftSelect()
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or (UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or (UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or (UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()))))
	end

	local function lockCameraRotation()
		v15 = true
		CurrentCamera.CameraType = Enum.CameraType.Scriptable
		local CameraSubject = CurrentCamera.CameraSubject
		if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end
		local v1_ = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
		local v2_ = CurrentCamera.CFrame - CurrentCamera.CFrame.p
		RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
			CurrentCamera.CFrame = v2_ + CameraSubject.CFrame.p - v1_
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
		if not v13 then return end
		v13:Destroy()
		v13 = nil
	end

	local function updateHandles()
		if not (v12 and v13) then return end
		v12.Visible = false
		v13.Visible = false
		local v1_ = isMobilePlayer() or not doingShiftSelect()
		if v11 then v11:FindFirstChild("SelectionBox") end
		local Mode = v9.Mode.Value
		if Mode == "Move" then
			v12.Color3 = Color3.fromRGB(13, 105, 172)
			v12.Visible = v1_
			v12.Style = "Movement"
			return
		end
		if Mode == "Rotate" then
			v13.Visible = v1_
			return
		end
		if Mode == "Clone" then
			v12.Color3 = Color3.fromRGB(20, 255, 169)
			v12.Visible = v1_
			v12.Style = "Movement"
			return
		end
		if Mode ~= "Mirror" then return end
		v12.Color3 = Color3.fromRGB(248, 37, 255)
		v12.Visible = v1_
		v12.Style = "Resize"
	end

	local function GetBoundingBox(p1, p2)
		local abs = math.abs
		local v1_ = (1 / 0)
		local v2_ = (-1 / 0)
		local v3_ = (-1 / 0)
		local v4_ = (-1 / 0)
		local v5_ = (1 / 0)
		local v6_ = (1 / 0)
		for i = 1, #p1 do
			local PrimaryPart = p1[i].PrimaryPart
			if PrimaryPart then
				local v7_ = p2:toObjectSpace(PrimaryPart.CFrame)
				local Size = PrimaryPart.Size
				local X = Size.X
				local Y = Size.Y
				local Z = Size.Z
				local v8_, v9_, v10_, v11_, v12_, v13_, v14_, v15_, v16_, v17_, v18_, v19_ = v7_:components()
				local v20 = 0.5 * (abs(v11_) * X + abs(v12_) * Y + abs(v13_) * Z)
				local v21_ = 0.5 * (abs(v14_) * X + abs(v15_) * Y + abs(v16_) * Z)
				local v22_ = 0.5 * (abs(v17_) * X + abs(v18_) * Y + abs(v19_) * Z)
				if v8_ - v20 < v5_ then v5_ = v8_ - v20 end
				if v9_ - v21_ < v6_ then v6_ = v9_ - v21_ end
				if v10_ - v22_ < v1_ then v1_ = v10_ - v22_ end
				if v2_ < v8_ + v20 then v2_ = v8_ + v20 end
				if v3_ < v9_ + v21_ then v3_ = v9_ + v21_ end
				if v4_ < v10_ + v22_ then v4_ = v10_ + v22_ end
			end
		end
		local v23_ = Vector3.new(v5_, v6_, v1_)
		local v24_ = Vector3.new(v2_, v3_, v4_)
		return p2 - p2.p + p2:pointToWorldSpace((v24_ + v23_) / 2), v24_ - v23_
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
				if isMobilePlayer() then checkToLockCameraRotation() end
				for k, v in pairs(t) do v.Visible = false end
				v3.Visible = false
			end)
			if v16 then
				v16:Disconnect()
				v16 = nil
			end
			v16 = v12.MouseButton1Up:Connect(function(p1)
				local v1_ = v22
				v22 = v12.Adornee.CFrame
				v14 = false
				v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
				checkToUnlockCameraRotation()
				for k, v in pairs(t) do v.Visible = true end
				v3.Visible = true
				local Mode_ = v9.Mode.Value
				if v1_ == v22 and Mode_ ~= "Mirror" then return end
				if Mode_ == "Mirror" then
					local v2_ = nil
					if p1 == Enum.NormalId.Right then
						v2_ = Vector3.new(v11.size.X / 2, 0, 0)
					elseif p1 == Enum.NormalId.Left then
						v2_ = Vector3.new(-v11.size.X / 2, 0, 0)
					elseif p1 == Enum.NormalId.Top then
						v2_ = Vector3.new(0, v11.size.Y / 2, 0)
					elseif p1 == Enum.NormalId.Bottom then
						v2_ = Vector3.new(0, -v11.size.Y / 2, 0)
					elseif p1 == Enum.NormalId.Back then
						v2_ = Vector3.new(0, 0, v11.size.Z / 2)
					elseif p1 == Enum.NormalId.Front then
						v2_ = Vector3.new(0, 0, -v11.size.Z / 2)
					end
					v22 = CFrame.new((v1_ * CFrame.new(v2_)).p, v1_.p)
				end
				performServerOperatoin(v1_, v22)
			end)
			if v18 then
				v18:Disconnect()
				v18 = nil
			end
			v18 = v12.MouseDrag:Connect(function(p1, p2)
				if v9.Mode.Value == "Mirror" then return end
				local v1_ = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
				if v1_ ~= 0 then p2 = p2 - p2 % v1_ end
				local v2_ = nil
				if p1 == Enum.NormalId.Right then
					v2_ = v22 * CFrame.new(p2, 0, 0)
				elseif p1 == Enum.NormalId.Left then
					v2_ = v22 * CFrame.new(-p2, 0, 0)
				elseif p1 == Enum.NormalId.Top then
					v2_ = v22 * CFrame.new(0, p2, 0)
				elseif p1 == Enum.NormalId.Bottom then
					v2_ = v22 * CFrame.new(0, -p2, 0)
				elseif p1 == Enum.NormalId.Back then
					v2_ = v22 * CFrame.new(0, 0, p2)
				elseif p1 == Enum.NormalId.Front then
					v2_ = v22 * CFrame.new(0, 0, -p2)
				end
				local v4_ = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
				local Size = v11.Size
				if not _G.DisableToolLimit and not (isPartInZone(v2_ * CFrame.new(Size.X / 2, 0, 0), v4_) and (isPartInZone(v2_ * CFrame.new(-Size.X / 2, 0, 0), v4_) and (isPartInZone(v2_ * CFrame.new(0, Size.Y / 2, 0), v4_) and (isPartInZone(v2_ * CFrame.new(0, -Size.Y / 2, 0), v4_) and (isPartInZone(v2_ * CFrame.new(0, 0, Size.Z / 2), v4_) and (isPartInZone(v2_ * CFrame.new(0, 0, -Size.Z / 2), v4_) and (QuestConditions(v4_, v2_ * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v4_, v2_ * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v4_, v2_ * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v4_, v2_ * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v4_, v2_ * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v4_, v2_ * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then
					return
				end
				v11.CFrame = if v2_ then v2_ else v22
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
				if isMobilePlayer() then checkToLockCameraRotation() end
				for k, v in pairs(t) do v.Visible = false end
				v3.Visible = false
			end)
			if v19 then
				v19:Disconnect()
				v19 = nil
			end
			v19 = v13.MouseButton1Up:Connect(function(p1)
				local v1_ = v22
				v22 = v13.Adornee.CFrame
				v14 = false
				v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
				checkToUnlockCameraRotation()
				for k, v in pairs(t) do v.Visible = true end
				v3.Visible = true
				if v1_ == v22 then return end
				performServerOperatoin(v1_, v22)
			end)
			v21 = v13.MouseDrag:Connect(function(p1, p2, p3)
				if math.deg(p2) < -180 then
					p2 = p2 + 6.283185307179586
				elseif math.deg(p2) > 180 then
					p2 = p2 - 6.283185307179586
				end
				local v1_ = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
				if v1_ ~= 0 then p2 = math.rad(v1_ * math.round(math.deg(p2) / v1_)) end
				local v5_ = nil
				if p1 == Enum.Axis.X then
					v5_ = v22 * CFrame.Angles(p2, 0, 0)
				elseif p1 == Enum.Axis.Y then
					v5_ = v22 * CFrame.Angles(0, p2, 0)
				elseif p1 == Enum.Axis.Z then
					v5_ = v22 * CFrame.Angles(0, 0, p2)
				end
				local v7_ = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
				local Size = v11.Size
				if not _G.DisableToolLimit and not (isPartInZone(v5_ * CFrame.new(Size.X / 2, 0, 0), v7_) and (isPartInZone(v5_ * CFrame.new(-Size.X / 2, 0, 0), v7_) and (isPartInZone(v5_ * CFrame.new(0, Size.Y / 2, 0), v7_) and (isPartInZone(v5_ * CFrame.new(0, -Size.Y / 2, 0), v7_) and (isPartInZone(v5_ * CFrame.new(0, 0, Size.Z / 2), v7_) and (isPartInZone(v5_ * CFrame.new(0, 0, -Size.Z / 2), v7_) and (QuestConditions(v7_, v5_ * CFrame.new(Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v7_, v5_ * CFrame.new(-Size.X / 2, 0, 0), "", 0, LocalPlayer) and (QuestConditions(v7_, v5_ * CFrame.new(0, Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v7_, v5_ * CFrame.new(0, -Size.Y / 2, 0), "", 0, LocalPlayer) and (QuestConditions(v7_, v5_ * CFrame.new(0, 0, Size.Z / 2), "", 0, LocalPlayer) and QuestConditions(v7_, v5_ * CFrame.new(0, 0, -Size.Z / 2), "", 0, LocalPlayer)))))))))))) then
					return
				end
				v11.CFrame = if v5_ then v5_ else v22
			end)
		end
		local v15_ = getSelectedModels()
		local v2_ = #v15_
		if v2_ < 1 then
			removeBoundingBox()
		else
			table.sort(v15_, function(p1, p2)
				if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then return true end
			end)
			local PrimaryPart = v15_[v2_].PrimaryPart
			local v4_, v5_ = GetBoundingBox(v15_, PrimaryPart.CFrame - PrimaryPart.Position)
			v11.Size = v5_
			v11.CFrame = v4_
		end
	end

	function performServerOperatoin(p1, p2)
		v23 = true
		local Mode = v9.Mode.Value
		local v1_ = getSelectedModels()
		if not _G.DisableToolLimit and (Mode == "Clone" or Mode == "Mirror") then
			local tbl = {}
			local sum = 0
			for i = 1, #v1_ do
				local v22_ = v1_[i]
				local v3_ = v22_.Name
				local v4_ = getBlockValue(v22_)
				if tbl[v3_] then tbl[v3_] = tbl[v3_] + v4_ else tbl[v3_] = v4_ end
				sum = sum + v4_
			end
			local v5_ = LocalPlayer
			local v6_ = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
			if v6_ and LocalPlayer.Settings.ShareBlocks.Value then v5_ = v6_ end
			local v7_ = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, sum)
			for k, v in pairs(tbl) do
				if v5_.Data:FindFirstChild(k) and v5_.Data[k].Value < v5_.Data[k].Used.Value + v or v7_ then
					v23 = false
					local AmountText = v9.ModeImage.AmountText
					local MaxText = v9.ModeImage.MaxText
					local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
					local v8_ = true
					if v7_ then
						if RestrictionMetFrame.Visible then v8_ = false else RestrictionMetFrame.Visible = true end
					elseif MaxText.Visible then
						v8_ = false
					else
						MaxText.Visible = true
						AmountText.Visible = false
						v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
						v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[k].Image
					end
					local v92 = v2.ClickSound:Clone()
					v92.Parent = script
					Debris:AddItem(v92, 0.3)
					v92.PlaybackSpeed = 5
					v92:Play()
					updateBoundingBox()
					if not v8_ then return end
					if v7_ then
						task.wait(3)
						RestrictionMetFrame.Visible = false
					else
						task.wait(3)
						MaxText.Visible = false
						AmountText.Visible = true
						t2 = {}
						v9.ModeImage.Image = ""
						local v10_ = getSelectedModels()
						for j = 1, #v10_ do t2[v10_[j].Name] = true end
						updateBlockDisplayImage()
					end
					return
				end
			end
		end
		if v12 then v12:Destroy() end
		if v13 then v13:Destroy() end
		if Mode == "Clone" then
			table.sort(v1_, function(p1_, p2_)
				if p1_.TrowelSB:GetAttribute("Created") > p2_.TrowelSB:GetAttribute("Created") then return true end
			end)
		end
		local v11_ = v2.OperationRF:InvokeServer(v1_, p1, p2, v9.Mode.Value) or {}
		local v122 = LocalPlayer.Character and (v2.Parent and (if v2.Parent == LocalPlayer.Character then LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 else false))
		if Mode == "Clone" then
			v9.SetModeEvent:Fire("Move")
			clearSelected()
			if v122 then
				for k = 1, #v11_ do
					local v132, _, v14_ = GetBlockInfo(v11_[k], LocalPlayer)
					if v14_ then addSelection(v132) end
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
		if not Target or (not Target.Parent or isMobilePlayer()) then
			v3.Adornee = nil
			return
		end
		local v12_, _, v2_ = GetBlockInfo(Target, LocalPlayer)
		local v32 = doingShiftSelect()
		v3.Visible = true
		if v32 then
			if t[v12_] then
				t[v12_].Color3 = Color3.fromRGB(175, 0, 0)
				v10 = t[v12_]
				v3.Visible = false
			end
		else
			if v3.Adornee and t[v3.Adornee] then v3.Adornee = nil end
			if t[v12_] then v3.Visible = false end
		end
		if _G.DisableToolLimit or v2_ then
			v3.Adornee = v12_
			local _2, v4_ = v12_:GetBoundingBox()
			v3.LineThickness = math.min(v4_.X, v4_.Y, v4_.Z, 2) / 13.334
		else
			v3.Adornee = nil
		end
	end

	local function active(p1)
		if not v3 or (v23 or v14) then return end
		local v12_ = doingShiftSelect()
		local Adornee = v3.Adornee
		if p1 then
			Adornee = nil
			local v2_, _, v32 = GetBlockInfo(v1.Target, LocalPlayer)
			if _G.DisableToolLimit and v2_ then Adornee = v2_
			elseif v32 and v2_ then Adornee = v2_ end
		end
		if Adornee == nil then
			if v12_ then return end
			clearSelected()
			updateBoundingBox()
		else
			local v4_, _, v5_ = GetBlockInfo(Adornee, LocalPlayer)
			if not _G.DisableToolLimit and not v5_ then return end
			if v12_ then
				if t[v4_] then removeSelection(v4_) else addSelection(v4_) end
			else
				clearSelected()
				addSelection(v4_)
			end
			updateBoundingBox()
			updateHandles()
			mouseMove()
		end
	end

	local function checkForDragSelection(p1, p2, p3)
		local v12_ = v25 and not p1 or (if p1 then v27 else p1)
		if not v12_ then return end
		local SelectionBox = v9.SelectionBox
		local v2_ = if p1 and p2 then p2 else v26
		local v32 = if p1 and p3 then p3 else Vector2.new(v1.X, v1.Y)
		SelectionBox.Position = UDim2.new(0, v2_.X, 0, v2_.Y)
		SelectionBox.Size = UDim2.new(0, v32.X - v2_.X, 0, v32.Y - v2_.Y)
		if v28 or (v14 or not v2_) then return end
		if not p1 and (v32 - v2_).Magnitude < 24 then return end
		v28 = true
		if p1 then checkToLockCameraRotation() end
		SelectionBox.Visible = true
		while v12_ do
			v3.Visible = false
			if not doingShiftSelect() or p1 then clearSelected() end
			local v5_ = math.min(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
			local v7_ = math.max(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
			local v92 = math.min(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
			local v11_ = math.max(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
			local v122 = workspace.Blocks:GetChildren()
			for i = 1, #v122 do
				local v13_ = v122[i]:GetChildren()
				for j = 1, #v13_ do
					local v142 = v13_[j]
					local _, _2, v15_ = GetBlockInfo(v142, LocalPlayer)
					if _G.DisableToolLimit or (v142.PrimaryPart and v15_) then
						local v16_, v17_ = CurrentCamera:WorldToScreenPoint(v142.PrimaryPart.Position)
						if v17_ and (v92 < v16_.X and (v16_.X < v7_ and (v5_ < v16_.Y and (v16_.Y < v11_ and not v142:FindFirstChild("TrowelSB"))))) then
							addSelection(v142)
						end
					end
				end
			end
			task.wait()
			v12_ = v25 and not p1 or (if p1 then v27 else p1)
		end
		SelectionBox.Visible = false
		if v3 then v3.Visible = true end
		updateBoundingBox()
		updateHandles()
		if not p1 then v28 = false return end
		checkToUnlockCameraRotation()
		v28 = false
	end

	local function inputTouchPinch(p1, p2, p3, p4, p5)
		if p5 then return end
		local v1_ = p1[1]
		local v2_ = p1[2]
		if p4 == Enum.UserInputState.Begin then v31 = (v2_ - v1_).Magnitude end
		if not (v31 < 120) then return end
		v27 = if p4 == Enum.UserInputState.Begin then true else p4 == Enum.UserInputState.Change
		checkForDragSelection(true, v1_, v2_)
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
			if not v14 then
				mouseMove()
				active(true)
			end
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
		if p1.UserInputType == Enum.UserInputType.MouseMovement then
			checkForDragSelection()
			mouseMove()
			return
		end
		if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
		checkForDragSelection()
		mouseMove()
	end

	local function inputEnded(p1, p2)
		if p2 then return end
		if p1.UserInputType == Enum.UserInputType.MouseButton1 then
			v25 = false
			return
		end
		if p1.UserInputType == Enum.UserInputType.Gamepad1 then
			if p1.KeyCode == Enum.KeyCode.ButtonR2 then v25 = false end
		else
			if isMobilePlayer() or doingShiftSelect() then return end
			updateHandles()
		end
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
			if v3 then v3:Destroy() v3 = nil end
		end
		if workspace:FindFirstChild("TrowelBoundingBox") then
			workspace.TrowelBoundingBox:Destroy()
			if v11 then removeBoundingBox() end
		end
		local v1_ = workspace.Blocks:GetChildren()
		for i = 1, #v1_ do
			local v2_ = v1_[i]:GetChildren()
			for j = 1, #v2_ do
				local v32 = v2_[j]
				if v32:FindFirstChild("TrowelSB") then v32.TrowelSB:Destroy() end
			end
		end
		for k, v in pairs(t) do v:Destroy() end
		t = {}
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

	v2.Equipped:connect(eq)
	v2.Unequipped:connect(uneq)
end

local function scan(child)
	if child:IsA("Tool") then
		if child.Name == "BuildingTool" then
			handleBuildingTool(child)
		elseif child.Name == "ScalingTool" then
			handleScalingTool(child)
		elseif child.Name == "TrowelTool" then
			handleTrowelTool(child)
		end
	end
end

LocalPlayer.Backpack.ChildAdded:Connect(scan)

if LocalPlayer.Character then
	LocalPlayer.Character.ChildAdded:Connect(scan)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	char.ChildAdded:Connect(scan)
end)

for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
	scan(v)
end

if LocalPlayer.Character then
	for _, v in pairs(LocalPlayer.Character:GetChildren()) do
		scan(v)
	end
end
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

    local function playSound(parent, speed)
        local snd = clickSound and clickSound:Clone()
        if not snd then
            snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://4597411234"
        end
        snd.Parent = parent
        game.Debris:AddItem(snd, 1)
        snd.PlaybackSpeed = speed
        snd:Play()
    end

    function eq()
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

    function uneq()
        if not v3 then return end
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

    function placeBlock(p1)
        if v25 or not v3 then
            return
        end

        if v3:FindFirstChild("OutOfBoundsBG") then
            v3.OutOfBoundsBG:Destroy()
        end

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
            game.Debris:AddItem(OutOfBoundsBG, 1.5)
            return
        end

        v25 = true
        task.spawn(function()
            task.wait()
            v25 = false
        end)

        local v52 = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v3.Name]
        local AmountText = v52.AmountText
        local MaxText = v52.MaxText
        local blockCount = tonumber(AmountText.Text) or 0

        if blockCount <= 0 and not _G.DisableToolLimit then
            playSound(v3.PrimaryPart, 5)
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
            local v9 = if v3.Name == "Spring" or v3.Name == "Bar" then true else v3.Name == "Rope"

            if v9 then
                local v10 = v3:FindFirstChild("2ndPlacement")
                if not v10 then
                    local v11 = Instance.new("BoolValue")
                    v11.Name = "2ndPlacement"
                    v11.Parent = v3
                    updateBlockCF()
                    return
                end
                v10:Destroy()
            end

            local v122 = if v9 then v3.SecondaryPart.PrimaryPart.CFrame else v9

            changeTransparency(v3, 0)
            game.Debris:AddItem(v3, 10)

            local v13 = if v5 then v5.CFrame:toObjectSpace(v3.PrimaryPart.CFrame) else nil
            local Anchor = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.AnchorBlock.Anchor.Value
            
            playSound(v3.PrimaryPart, 1)

            if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
                resetRotation()
            end

            local v16 = v3
            v3 = v3:Clone()
            changeTransparency(v3, 0.5)
            v3.Parent = workspace
            v1.TargetFilter = v3

            local v17 = v16:GetDescendants()
            for i = 1, #v17 do
                local v18 = v17[i]
                if v18:IsA("BasePart") then
                    v18.CanQuery = true
                end
            end

            local v19 = v5
            updateBlockCF(p1)
            updateBuildGui()

            local bName = v16.Name
            local bDataVal = LocalPlayer.Data:FindFirstChild(bName).Value
            local bV122 = v122

            if _G.FullPlace then
                local loopCount = blockCount
                if loopCount <= 0 and _G.DisableToolLimit then loopCount = 1 end
                
                task.spawn(function()
                    for i = 1, loopCount do
                        if not v9 then
                            v2.RF:InvokeServer(bName, bDataVal, v19, bV13, Anchor, v16.PrimaryPart.CFrame, bV122)
                        else
                            local v20 = game.ReplicatedStorage.BuildingParts[bName]
                            v16.SecondaryPart.PrimaryPart.CFrame = v16.PrimaryPart.CFrame * v20.PrimaryPart.CFrame:ToObjectSpace(v20.SecondaryPart.PrimaryPart.CFrame)
                            v2.RF:InvokeServer(bName, bDataVal, v19, bV13, Anchor, v16.PrimaryPart.CFrame, bV122)
                        end
                        if i < loopCount then task.wait(0.2) end
                    end
                    v16:Destroy()
                end)
            else
                if not v9 then
                    v2.RF:InvokeServer(bName, bDataVal, v19, bV13, Anchor, v16.PrimaryPart.CFrame, bV122)
                    v16:Destroy()
                    return
                end

                local v20 = game.ReplicatedStorage.BuildingParts[bName]
                v16.SecondaryPart.PrimaryPart.CFrame = v16.PrimaryPart.CFrame * v20.PrimaryPart.CFrame:ToObjectSpace(v20.SecondaryPart.PrimaryPart.CFrame)
                v2.RF:InvokeServer(bName, bDataVal, v19, bV13, Anchor, v16.PrimaryPart.CFrame, bV122)
                v16:Destroy()
            end
        end
    end

    function updateBlockCF(p1)
        if not v1.Target then
            return
        end

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

        if v20 ~= 0 then
            v19 = roundVectorToBase(v19, v20)
        end

        v12:SetPrimaryPartCFrame(v17 * CFrame.new(v19) * v32 * v2)

        if not v3:FindFirstChild("CanPlace") then
            local CanPlace = Instance.new("BoolValue")
            CanPlace.Name = "CanPlace"
            CanPlace.Value = true
            CanPlace.Parent = v3
        end

        local v22 = canPlace(v12)

        if v3.CanPlace.Value or not v22 then
            if not v3.CanPlace.Value or v22 then
                return
            end

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

            if v3:FindFirstChild("OutOfBoundsBG") then
                v3.OutOfBoundsBG:Destroy()
            end
        end
    end

    function changeTransparency(p1, p2)
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

    function canPlace(p1)
        if _G.DisableToolLimit then
            return true, nil
        end
        local v2 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v32 = isPartInZone(p1.PrimaryPart, v2)
        local v4 = if v32 then nil else "Out of bounds"
        local v5, v6 = QuestConditions(v2, p1.PrimaryPart.CFrame, v3.Name, 1, LocalPlayer)
        local v7, v8 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, 1)
        local v9, v10 = ChallengeConditions.itemRestriction(LocalPlayer, v3.Name)

        return if v32 then if v5 then not v7 and not v9 else v5 else v32, if v4 then v4 elseif v6 then v6 elseif v8 then v8 else v10
    end

    function isPartInZone(p1, p2)
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

    function roundVectorToBase(p1, p2)
        local v1 = 1 / p2
        local v2 = p1 * v1 + Vector3.new(0.5, 0.5, 0.5)
        return Vector3.new(math.floor(v2.X), math.floor(v2.Y), (math.floor(v2.Z))) / v1
    end

    function normalIdToNormalVector(p1, p2)
        if p1 == Enum.NormalId.Top then return Vector3.new(0, 1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Bottom then return Vector3.new(0, -1, 0), p2.Size.Y end
        if p1 == Enum.NormalId.Front then return Vector3.new(0, 0, -1), p2.Size.Z end
        if p1 == Enum.NormalId.Back then return Vector3.new(0, 0, 1), p2.Size.Z end
        if p1 == Enum.NormalId.Right then return Vector3.new(1, 0, 0), p2.Size.X end
        return Vector3.new(-1, 0, 0), p2.Size.X
    end

    function prepareItem()
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

    function WeldTogether(p1, p2, p3, p4)
        if p1:FindFirstChild("NoWelds") or p2:FindFirstChild("NoWelds") then return end
        local v1 = Instance.new(p3 or "Weld")
        v1.Part0 = p1
        v1.Part1 = p2
        v1.C0 = CFrame.new()
        v1.C1 = p2.CFrame:toObjectSpace(p1.CFrame)
        v1.Parent = p4 or p1
        return v1
    end

    function itemChanged()
        local Selected = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.Selected.Value
        local v1 = game.ReplicatedStorage.BuildingParts:FindFirstChild(Selected)

        updateBuildGui()
        local v2 = v3.PrimaryPart.CFrame

        v3:Destroy()
        v3 = v1:Clone()
        v3:SetPrimaryPartCFrame(CFrame.new(v2.p) * v1.PrimaryPart.CFrame.Rotation)
        resetRotation()
        prepareItem()
        updateBlockCF()
        v3.Parent = workspace

        local TagsFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v32 = string.split(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].Tags.Value, " ")
        local v4 = TagsFrame:GetChildren()
        local TextLabel = TagsFrame.TextLabel

        for i = 1, #v32 do
            local v5 = TextLabel:Clone()
            v5.Text = string.lower(v32[i])
            v5.Parent = TextLabel.Parent
        end

        for j = 1, #v4 do
            v4[j]:Destroy()
        end

        TagsFrame.Parent.BlockName.Text = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[Selected].BlockName.Value
        TagsFrame.Parent.StrengthFrame.TextLabel.Text = tostring(game.ReplicatedStorage.BuildingParts[Selected].Health.Value)
    end

    function resetRotation()
        if LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.RelativeRotation.RelativeRotation.Value then
            v8 = CFrame.new()
        else
            local v1 = workspace
            local v2 = v1[tostring(LocalPlayer.TeamColor) .. "Zone"]
            v8 = (v2.CFrame - v2.Position) * (v3.PrimaryPart.CFrame - v3.PrimaryPart.Position)
        end
    end

    function updateBuildGui()
        local v1 = LocalPlayer
        local v2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)

        if v2 and LocalPlayer.Settings.ShareBlocks.Value then
            v1 = v2
        end

        local v3 = v1.Name
        local BuildGui = LocalPlayer.PlayerGui.BuildGui
        local SearchFrame = BuildGui.SearchFrame
        local v4 = string.lower(SearchFrame.SearchBox.Text):match("^%s*(.-)%s*$")
        local TagsFrame = BuildGui.InventoryFrame.MoreFrame.TagsFrame
        local v5 = BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:GetChildren()

        for i = 1, #v5 do
            local v6 = v5[i]

            if game.ReplicatedStorage.BuildingParts:FindFirstChild(v6.Name) then
                local v8 = getType(v6)
                local v9 = game.Players:FindFirstChild(v3).Data[v6.Name].Value
                local v10 = string.split(v6.Tags.Value, " ")
                local v11 = false

                if SearchFrame.OnlySearch.Value then
                    local ok, result = pcall(function()
                        return LocalizationService:GetTranslatorForPlayerAsync(game.Players.LocalPlayer)
                    end)

                    if ok then
                        local v13 = string.lower((result:Translate(TagsFrame.Parent.BlockName, v6.BlockName.Value)))
                        if string.find(v13, v4) or string.find(v4, v13) then
                            v11 = true
                        end

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

    function fitBuildScroll()
        local ScrollingFrame = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame
        local v1 = ScrollingFrame.BlocksFrame:GetChildren()
        local v2 = nil
        local v3 = nil

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

    function getType(p1)
        local v1 = string.match(p1.TypeIcon.Image, "%d+")
        if v1 == "4597411234" then return "Block" end
        if v1 == "4597402658" then return "Decoration" end
        return "Special"
    end

    function isSpeedBuild()
        local SpeedBuild = LocalPlayer.OtherData:FindFirstChild("SpeedBuild")
        if SpeedBuild and SpeedBuild.Value then return true end
        return nil
    end

    function toggleSpeedBuild()
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

    function setSpeedBuildGuiLook()
        local SpeedBuildToggle = LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle
        if isSpeedBuild() then
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565249"
        else
            SpeedBuildToggle.Image = "http://www.roblox.com/asset/?id=4603565059"
        end
    end

    function rotateY()
        v8 = v8 * CFrame.Angles(0, math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0)
        updateBlockCF(true)
    end

    function rotateX()
        v8 = v8 * CFrame.Angles(math.rad(tonumber(LocalPlayer.PlayerGui.BuildGui.InventoryFrame.MoreFrame.Rotate.TextLabel.Text) or 90), 0, 0)
        updateBlockCF(true)
    end

    function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement then
            updateBlockCF()
            return
        end
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
        updateBlockCF()
    end

    function inputBegan(p1, p2)
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
            if p1.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
            if p1.KeyCode == Enum.KeyCode.ButtonR2 then placeBlock() return end
            if p1.KeyCode == Enum.KeyCode.ButtonX then rotateY() return end
            if p1.KeyCode ~= Enum.KeyCode.ButtonY then return end
            rotateX()
        end
    end

    function inputEnded(p1, p2)
        if p2 or (p1.UserInputType ~= Enum.UserInputType.Touch or not (isSpeedBuild() and (v1.Hit.p - v10.p).Magnitude < 1)) then return end
        updateBlockCF()
        placeBlock(true)
    end

    v2.Equipped:Connect(eq)
    v2.Unequipped:Connect(uneq)
end

local function setupScalingTool(tool)
    if hookedTools[tool] then return end
    hookedTools[tool] = true
    dprint("Hooking ScalingTool")

    local localScript = tool:FindFirstChild("ScaleLocalScript")
    local clickSound = localScript and localScript:FindFirstChild("ClickSound")
    if localScript then
        localScript.Disabled = true
    end

    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local CurrentCamera = workspace.CurrentCamera
    local v1 = LocalPlayer:GetMouse()
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

    local function playSound(parent, speed)
        local snd = clickSound and clickSound:Clone()
        if not snd then
            snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://4597411234"
        end
        snd.Parent = parent
        game.Debris:AddItem(snd, 1)
        snd.PlaybackSpeed = speed
        snd:Play()
    end

    function canSelect(p1)
        if v16 then return false, p1 end
        local v1, _, v2 = GetBlockInfo(p1, LocalPlayer)
        if v2 and string.find(v1.Name, "Block") then return true, v1 end
        return false
    end

    function updateBlocks()
        local v1 = LocalPlayer
        local v2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2 and LocalPlayer.Settings.ShareBlocks.Value then v1 = v2 end

        local v5 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
        local v6 = v4.Adornee.Parent.Name
        v13 = game.Players:FindFirstChild(v1.Name).Data:FindFirstChild(v6).Value

        local v7 = workspace.Blocks:GetChildren()
        local sum = 0
        for i = 1, #v7 do
            local v8 = v7[i]:GetChildren()
            for j = 1, #v8 do
                local v9 = v8[j]
                local _, _2, v10 = GetBlockInfo(v9, LocalPlayer)
                if v10 and (v9.Name == v6 and (v9.PrimaryPart and isPartInZone(v9.PrimaryPart, v5))) then
                    sum = sum + math.max(v9.PrimaryPart.Size.X * v9.PrimaryPart.Size.Y * v9.PrimaryPart.Size.Z / v15, 1)
                end
            end
        end

        v14 = sum
        v12.BlockImage.AmountText.Text = tostring((math.floor(v13 - sum)))
        v12.BlockImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame:FindFirstChild(v6).Image
        v12.Parent = LocalPlayer.PlayerGui
    end

    function updateBlocksSoft(p1, p2)
        local v1 = LocalPlayer
        local v2 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
        if v2 and LocalPlayer.Settings.ShareBlocks.Value then v1 = v2 end

        v13 = game.Players:FindFirstChild(v1.Name).Data:FindFirstChild(v4.Adornee.Parent.Name).Value
        v14 = v14 + (p2.X * p2.Y * p2.Z / v15 - p1.X * p1.Y * p1.Z / v15)

        local v7 = math.floor(v13 - v14)
        v12.BlockImage.AmountText.Text = tostring(v7)
        return v7
    end

    function roundToNearestThousands(p1)
        return math.floor(p1 * 1000 + 0.5) / 1000
    end

    function active(p1)
        if not v2 then return end
        local Adornee = v2.Adornee
        if Adornee == nil then return end

        local v1, v22 = canSelect(Adornee)
        if v1 then
            local Size = v22.PrimaryPart.Size
            local Size2 = game.ReplicatedStorage.BuildingParts:FindFirstChild(v22.Name).PrimaryPart.Size
            v15 = Size2.X * Size2.Y * Size2.Z

            if v4 then
                v4.Adornee = v22.PrimaryPart
            else
                v4 = Instance.new("Handles")
                v4.Adornee = v22.PrimaryPart
                v4.Style = Enum.HandlesStyle.Resize
                v4.Color3 = Color3.fromRGB(172, 78, 1)
                v4.Parent = LocalPlayer.PlayerGui
            end

            local v3 = nil
            local v42 = nil
            local v52 = nil
            local v62 = nil

            if v7 then v7:Disconnect() v7 = nil end
            v7 = v4.MouseButton1Down:Connect(function()
                v16 = true
                v3 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                v4.Adornee:BreakJoints()
                v4.Adornee.Anchored = true
                if not p1 then return end
                checkToLockCameraRotation()
            end)

            local SizeDisplay = v12.BlockImage.SizeDisplay
            SizeDisplay.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))

            if v8 then v8:Disconnect() v8 = nil end
            v8 = v4.MouseDrag:Connect(function(p1, p2)
                local v1 = tonumber(v12.BlockImage.More.Scale.TextBox.Text)
                if v1 ~= 0 then p2 = p2 - p2 % v1 end

                if p1 == Enum.NormalId.Right then
                    if v52.X + p2 <= 0.05 then
                        local v2 = v52.X % v1
                        if v1 == 0 then v2 = 0.05 end
                        if v2 < 0.05 then v2 = v1 end
                        v62 = Vector3.new(v2, v52.Y, v52.Z)
                        v42 = v3 * CFrame.new(-(v52.X - v62.X) / 2, 0, 0)
                    else
                        v42 = v3 * CFrame.new(p2 / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2, 0, 0)
                    end
                elseif p1 == Enum.NormalId.Left then
                    if v52.X + p2 <= 0.05 then
                        local v43 = v52.X % v1
                        if v1 == 0 then v43 = 0.05 end
                        if v43 <= 0.05 then v43 = v1 end
                        v62 = Vector3.new(v43, v52.Y, v52.Z)
                        v42 = v3 * CFrame.new(-(-(v52.X - v62.X)) / 2, 0, 0)
                    else
                        v42 = v3 * CFrame.new(-p2 / 2, 0, 0)
                        v62 = v52 + Vector3.new(p2, 0, 0)
                    end
                elseif p1 == Enum.NormalId.Top then
                    if v52.Y + p2 <= 0.05 then
                        local v6 = v52.Y % v1
                        if v1 == 0 then v6 = 0.05 end
                        if v6 <= 0.05 then v6 = v1 end
                        v62 = Vector3.new(v52.X, v6, v52.Z)
                        v42 = v3 * CFrame.new(0, -(v52.Y - v62.Y) / 2, 0)
                    else
                        v42 = v3 * CFrame.new(0, p2 / 2, 0)
                        v62 = v52 + Vector3.new(0, p2, 0)
                    end
                elseif p1 == Enum.NormalId.Bottom then
                    if v52.Y + p2 <= 0.05 then
                        local v8 = v52.Y % v1
                        if v1 == 0 then v8 = 0.05 end
                        if v8 <= 0.05 then v8 = v1 end
                        v62 = Vector3.new(v52.X, v8, v52.Z)
                        v42 = v3 * CFrame.new(0, -(-(v52.Y - v62.Y)) / 2, 0)
                    else
                        v42 = v3 * CFrame.new(0, -p2 / 2, 0)
                        v62 = v52 + Vector3.new(0, -p2, 0)
                    end
                elseif p1 == Enum.NormalId.Back then
                    if v52.Z + p2 <= 0.05 then
                        local v10 = v52.Z % v1
                        if v1 == 0 then v10 = 0.05 end
                        if v10 <= 0.05 then v10 = v1 end
                        v62 = Vector3.new(v52.X, v52.Y, v10)
                        v42 = v3 * CFrame.new(0, 0, -(v52.Z - v62.Z) / 2)
                    else
                        v42 = v3 * CFrame.new(0, 0, p2 / 2)
                        v62 = v52 + Vector3.new(0, 0, p2)
                    end
                elseif p1 == Enum.NormalId.Front then
                    if v52.Z + p2 <= 0.05 then
                        local v122 = v52.Z % v1
                        if v1 == 0 then v122 = 0.05 end
                        if v122 <= 0.05 then v122 = v1 end
                        v62 = Vector3.new(v52.X, v52.Y, v122)
                        v42 = v3 * CFrame.new(0, 0, -(-(v52.Z - v62.Z)) / 2)
                    else
                        v42 = v3 * CFrame.new(0, 0, -p2 / 2)
                        v62 = v52 + Vector3.new(0, 0, p2)
                    end
                end

                v62 = Vector3.new(math.max(v62.X, 0.05), math.max(v62.Y, 0.05), (math.max(v62.Z, 0.05)))
                local v17 = Size
                local v19 = v62.X * v62.Y * v62.Z / v15 - v17.X * v17.Y * v17.Z / v15
                local v21 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                local v22 = isPartInZone(v42 * CFrame.new(v62.X / 2, 0, 0), v21) and (isPartInZone(v42 * CFrame.new(-v62.X / 2, 0, 0), v21) and (isPartInZone(v42 * CFrame.new(0, v62.Y / 2, 0), v21) and (isPartInZone(v42 * CFrame.new(0, -v62.Y / 2, 0), v21) and (isPartInZone(v42 * CFrame.new(0, 0, v62.Z / 2), v21) and (isPartInZone(v42 * CFrame.new(0, 0, -v62.Z / 2), v21))))))
                local v23 = updateBlocksSoft(v4.Adornee.Size, v62)
                local v24 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, v19)

                if _G.DisableToolLimit or (v23 >= 0 and (v22 and not v24)) then
                    if v4.Adornee.Size == v62 then return end
                    v4.Adornee:BreakJoints()
                    v4.Adornee.CFrame = v42 or v3
                    v4.Adornee.Size = v62 or v52
                    v12.BlockImage.SizeDisplay.Text = tostring(roundToNearestThousands(v4.Adornee.Size.X)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Y)) .. "," .. tostring(roundToNearestThousands(v4.Adornee.Size.Z))
                    return
                end

                updateBlocksSoft(v62, v4.Adornee.Size)
                local AmountText = v12.BlockImage.AmountText
                local MaxText = v12.BlockImage.MaxText
                local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame

                if v24 then RestrictionMetFrame.Visible = true else MaxText.Visible = true AmountText.Visible = false end
                playSound(v4.Adornee, 5)

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
                v3 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v1, v2 = tool.RF:InvokeServer(v4.Adornee.Parent, v52, v3)
                Size = v52
                if v1 then v22.PrimaryPart.Size = v1 v22.PrimaryPart.CFrame = v2 updateBlocks() end
                v16 = false
                if not p1 then return end
                checkToUnlockCameraRotation()
            end)

            if v5 then v5:Disconnect() v5 = nil end
            v5 = tool.Unequipped:Connect(function()
                v3 = v4.Adornee.CFrame
                v52 = v4.Adornee.Size
                local v1, v2 = tool.RF:InvokeServer(v4.Adornee.Parent, v52, v3)
                Size = v52
                if not v1 then v16 = false v5:Disconnect() v5 = nil return end
                v22.PrimaryPart.Size = v1 v22.PrimaryPart.CFrame = v2 v16 = false v5:Disconnect() v5 = nil
            end)
            updateBlocks()
        end
        mouseMove()
    end

    function uneq()
        if v2 then v2:Destroy() v2 = nil end
        if v3 then v3:Disconnect() v3 = nil end
        if v11 then v11:Disconnect() v11 = nil end
        if v9 then v9:Disconnect() v9 = nil end
        if v10 then v10:Disconnect() v10 = nil end
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Visible = false
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Turn.Visible = true
        LocalPlayer.PlayerGui.TabletToolGui.Frame.Rotate.Visible = true
        LocalPlayer.PlayerGui.TabletToolGui.Frame.SpeedBuildToggle.Visible = true

        if not v4 then if v12 then v12.BlockImage.Visible = false end checkToUnlockCameraRotation() return end
        v4:Destroy() v4 = nil
        if v12 then v12.BlockImage.Visible = false end
        checkToUnlockCameraRotation()
    end

    function eq()
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

    function mouseMove(p1)
        local Target = v1.Target
        if not (Target and Target.Parent) then v2.Adornee = nil return end

        local v12, v22 = canSelect(Target)
        if v4 and (v2.Adornee and v4.Adornee == v2.Adornee.PrimaryPart) then v2.Adornee = nil end
        if v4 and (v22 and (v22:IsA("Model") and v4.Adornee == v22.PrimaryPart)) then v2.Adornee = nil return end
        if v2.Adornee == v22 then return end

        if v12 then
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

    function inputBegan(p1, p2)
        if p2 then return end
        if p1.UserInputType == Enum.UserInputType.MouseButton1 then active() return end
        if p1.UserInputType == Enum.UserInputType.Touch then mouseMove(true) return end
        if p1.UserInputType ~= Enum.UserInputType.Gamepad1 or p1.KeyCode ~= Enum.KeyCode.ButtonR2 then return end
        active()
    end

    function inputChanged(p1, p2)
        if p1.UserInputType ~= Enum.UserInputType.MouseMovement and (p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2) then return end
        mouseMove(false)
    end

    function checkToLockCameraRotation()
        if v17 then return end
        lockCameraRotation()
    end

    function lockCameraRotation()
        v17 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end

        local v1 = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2 = CurrentCamera.CFrame - CurrentCamera.CFrame.p

        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2 + CameraSubject.CFrame.p - v1
        end)
    end

    function checkToUnlockCameraRotation()
        if not v17 then return end
        unlockCameraRotation()
    end

    function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v17 = false
    end

    function died()
        uneq()
        tool:Destroy()
    end

    function isPartInZone(p1, p2)
        local v1 = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X = Size.X
        local Y = Size.Y
        local Z = Size.Z

        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v1.X > Position.X - X / 2 and (v1.X < Position.X + X / 2 and (v1.Z > Position.Z - Z / 2 and v1.Z < Position.Z + Z / 2))
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function setupTrowelTool(tool)
    if hookedTools[tool] then return end
    hookedTools[tool] = true
    dprint("Hooking TrowelTool")

    local localScript = tool:FindFirstChild("TrowelLocalScript")
    local clickSound = localScript and localScript:FindFirstChild("ClickSound")
    if localScript then
        localScript.Disabled = true
    end

    local UserInputService = game:GetService("UserInputService")
    local ContextActionService = game:GetService("ContextActionService")
    local RunService = game:GetService("RunService")
    local GuiService = game:GetService("GuiService")
    local GetBlockInfo = require(game.ReplicatedStorage.Scripts.GetBlockInfo)
    local v1 = LocalPlayer:GetMouse()
    local v2 = tool
    local CurrentCamera = workspace.CurrentCamera
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
    local QuestConditions = require(game.ReplicatedStorage.Scripts.QuestConditions)
    local ChallengeConditions = require(game.ReplicatedStorage.Scripts.ChallengeConditions)
    local v23 = false
    local v24 = nil
    local v25 = false
    local v26 = nil
    local v27 = false
    local v28 = false
    local v29 = nil
    local v30 = 0

    local function playSound(parent, speed)
        local snd = clickSound and clickSound:Clone()
        if not snd then
            snd = Instance.new("Sound")
            snd.SoundId = "rbxassetid://4597411234"
        end
        snd.Parent = parent
        game.Debris:AddItem(snd, 1)
        snd.PlaybackSpeed = speed
        snd:Play()
    end

    function isMobilePlayer()
        return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
    end

    function getSelectedModels()
        local t2 = {}
        for k, v in pairs(t) do table.insert(t2, k) end
        return t2
    end

    function clearSelected()
        for k, v in pairs(t) do v:Destroy() end
        t = {}
        v30 = 0
        if v9 then v9.ModeImage.AmountText.Text = "0" end
        t2 = {}
        updateBlockDisplayImage()
    end

    function addSelection(p1)
        local TrowelSB = Instance.new("SelectionBox")
        TrowelSB.Name = "TrowelSB"
        TrowelSB.SurfaceTransparency = 0.5
        TrowelSB.Color3 = Color3.fromRGB(0, 126, 158)

        local _, v1 = p1:GetBoundingBox()
        TrowelSB.LineThickness = math.min(v1.X, v1.Y, v1.Z, 2) / 50
        TrowelSB.Parent = p1
        TrowelSB.Adornee = p1
        TrowelSB:SetAttribute("Created", tick())
        t[p1] = TrowelSB
        v30 = v30 + getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
        t2[p1.Name] = if t2[p1.Name] then t2[p1.Name] + 1 or 1 else 1
        updateBlockDisplayImage()
    end

    function removeSelection(p1)
        local v1 = t[p1]
        if v1 then v1:Destroy() end

        if not v9.ModeImage.MaxText.Visible then
            if t2[p1.Name] then
                local v2 = t2
                local v3 = p1.Name
                v2[v3] = v2[v3] + -1
                if t2[p1.Name] <= 0 then t2[p1.Name] = nil end
            end
            updateBlockDisplayImage(p1.Name)
        end

        t[p1] = nil
        v30 = v30 - getBlockValue(p1)
        v9.ModeImage.AmountText.Text = tostring((math.ceil(v30)))
    end

    function updateBlockDisplayImage(p1)
        if v9.ModeImage.MaxText.Visible then return end
        local v1 = nil
        local v2 = true
        local v3 = true

        for k, v in pairs(t2) do
            v2 = false
            if v1 then v3 = true break end
            v1 = k
            v3 = false
        end

        if v2 then v9.ModeImage.Image = "" v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0) return end
        if v3 then
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame.WoodBlock.Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
        else
            v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[v1].Image
            v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    function isPartInZone(p1, p2)
        local v1 = if typeof(p1) == "CFrame" then p1.Position else p1.Position
        local Position = p2.Position
        local Size = p2.Size
        local X = Size.X
        local Y = Size.Y
        local Z = Size.Z

        if p2.Rotation.Y > 89 and p2.Rotation.Y < 91 or p2.Rotation.Y < -89 and p2.Rotation.Y > -91 then
            X = Size.Z
            Z = Size.X
        end
        return v1.X > Position.X - X / 2 and (v1.X < Position.X + X / 2 and (v1.Z > Position.Z - Z / 2 and v1.Z < Position.Z + Z / 2))
    end

    function active(p1)
        if not v3 or (v23 or v14) then return end
        local v12 = doingShiftSelect()
        local Adornee = v3.Adornee

        if p1 then
            Adornee = nil
            local v2, _, v32 = GetBlockInfo(v1.Target, LocalPlayer)
            if v32 and v2 then Adornee = v2 end
        end

        if Adornee == nil then
            if v12 then return end
            clearSelected()
            updateBoundingBox()
        else
            local v4, _, v5 = GetBlockInfo(Adornee, LocalPlayer)
            if not v5 then return end

            if v12 then
                if t[v4] then removeSelection(v4) else addSelection(v4) end
            else
                clearSelected()
                addSelection(v4)
            end
            updateBoundingBox()
            updateHandles()
            mouseMove()
        end
    end

    function GetBoundingBox(p1, p2)
        local abs = math.abs
        local v1 = (1 / 0) local v2 = (-1 / 0) local v3 = (-1 / 0)
        local v4 = (-1 / 0) local v5 = (1 / 0) local v6 = (1 / 0)

        for i = 1, #p1 do
            local PrimaryPart = p1[i].PrimaryPart
            if PrimaryPart then
                local v7 = p2:toObjectSpace(PrimaryPart.CFrame)
                local Size = PrimaryPart.Size
                local X = Size.X local Y = Size.Y local Z = Size.Z
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

    function performServerOperatoin(p1, p2)
        v23 = true
        local Mode = v9.Mode.Value
        local v1 = getSelectedModels()

        if (Mode == "Clone" or Mode == "Mirror") and not _G.DisableToolLimit then
            local tbl = {}
            local sum = 0
            for i = 1, #v1 do
                local v22 = v1[i]
                local v3 = v22.Name
                local v4 = getBlockValue(v22)
                if tbl[v3] then tbl[v3] = tbl[v3] + v4 else tbl[v3] = v4 end
                sum = sum + v4
            end

            local v5 = LocalPlayer
            local v6 = game.Players:FindFirstChild(LocalPlayer.Team.TeamLeader.Value)
            if v6 and LocalPlayer.Settings.ShareBlocks.Value then v5 = v6 end

            local v7 = ChallengeConditions.blockLimitChallengeReached(LocalPlayer, sum)
            for k, v in pairs(tbl) do
                if v5.Data:FindFirstChild(k) and v5.Data[k].Value < v5.Data[k].Used.Value + v or v7 then
                    v23 = false
                    local AmountText = v9.ModeImage.AmountText
                    local MaxText = v9.ModeImage.MaxText
                    local RestrictionMetFrame = LocalPlayer.PlayerGui.BattleTimerGui.RestrictionMetFrame
                    local v8 = true

                    if v7 then
                        if RestrictionMetFrame.Visible then v8 = false else RestrictionMetFrame.Visible = true end
                    elseif MaxText.Visible then
                        v8 = false
                    else
                        MaxText.Visible = true
                        AmountText.Visible = false
                        v9.ModeImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        v9.ModeImage.Image = LocalPlayer.PlayerGui.BuildGui.InventoryFrame.ScrollingFrame.BlocksFrame[k].Image
                    end

                    playSound(script, 5)
                    updateBoundingBox()

                    if not v8 then return end
                    if v7 then
                        task.wait(3)
                        RestrictionMetFrame.Visible = false
                    else
                        task.wait(3)
                        MaxText.Visible = false
                        AmountText.Visible = true
                        t2 = {}
                        v9.ModeImage.Image = ""
                        local v10 = getSelectedModels()
                        for j = 1, #v10 do t2[v10[j].Name] = true end
                        updateBlockDisplayImage()
                    end
                    return
                end
            end
        end

        if v12 then v12:Destroy() v12 = nil end
        if v13 then v13:Destroy() v13 = nil end

        if Mode == "Clone" then
            table.sort(v1, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") > p2.TrowelSB:GetAttribute("Created") then return true end
            end)
        end

        local v11 = v2.OperationRF:InvokeServer(v1, p1, p2, v9.Mode.Value) or {}
        local v122 = LocalPlayer.Character and (v2.Parent and (if v2.Parent == LocalPlayer.Character then LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health > 0 else false))

        if Mode == "Clone" then
            v9.SetModeEvent:Fire("Move")
            clearSelected()
            if v122 then
                for k = 1, #v11 do
                    local v132, _, v14 = GetBlockInfo(v11[k], LocalPlayer)
                    if v14 then addSelection(v132) end
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
                if v3 then v3.Visible = false end
            end)

            if v16 then v16:Disconnect() v16 = nil end
            v16 = v12.MouseButton1Up:Connect(function(p1)
                local v1 = v22
                v22 = v12.Adornee.CFrame
                v14 = false
                v12.Faces = Faces.new(Enum.NormalId.Back, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top)
                checkToUnlockCameraRotation()

                for k, v in pairs(t) do v.Visible = true end
                if v3 then v3.Visible = true end

                local Mode = v9.Mode.Value
                if v1 == v22 and Mode ~= "Mirror" then return end

                if Mode == "Mirror" then
                    local v2 = nil
                    if p1 == Enum.NormalId.Right then v2 = Vector3.new(v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Left then v2 = Vector3.new(-v11.size.X / 2, 0, 0)
                    elseif p1 == Enum.NormalId.Top then v2 = Vector3.new(0, v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Bottom then v2 = Vector3.new(0, -v11.size.Y / 2, 0)
                    elseif p1 == Enum.NormalId.Back then v2 = Vector3.new(0, 0, v11.size.Z / 2)
                    elseif p1 == Enum.NormalId.Front then v2 = Vector3.new(0, 0, -v11.size.Z / 2) end
                    v22 = CFrame.new((v1 * CFrame.new(v2)).p, v1.p)
                end
                performServerOperatoin(v1, v22)
            end)

            if v18 then v18:Disconnect() v18 = nil end
            v18 = v12.MouseDrag:Connect(function(p1, p2)
                if v9.Mode.Value == "Mirror" then return end
                local v1 = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v1 ~= 0 then p2 = p2 - p2 % v1 end

                local v2 = nil
                if p1 == Enum.NormalId.Right then v2 = v22 * CFrame.new(p2, 0, 0)
                elseif p1 == Enum.NormalId.Left then v2 = v22 * CFrame.new(-p2, 0, 0)
                elseif p1 == Enum.NormalId.Top then v2 = v22 * CFrame.new(0, p2, 0)
                elseif p1 == Enum.NormalId.Bottom then v2 = v22 * CFrame.new(0, -p2, 0)
                elseif p1 == Enum.NormalId.Back then v2 = v22 * CFrame.new(0, 0, p2)
                elseif p1 == Enum.NormalId.Front then v2 = v22 * CFrame.new(0, 0, -p2) end

                if not _G.DisableToolLimit then
                    local v4 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                    local Size = v11.Size
                    if not (isPartInZone(v2 * CFrame.new(Size.X / 2, 0, 0), v4) and (isPartInZone(v2 * CFrame.new(-Size.X / 2, 0, 0), v4) and (isPartInZone(v2 * CFrame.new(0, Size.Y / 2, 0), v4) and (isPartInZone(v2 * CFrame.new(0, -Size.Y / 2, 0), v4) and (isPartInZone(v2 * CFrame.new(0, 0, Size.Z / 2), v4) and (isPartInZone(v2 * CFrame.new(0, 0, -Size.Z / 2), v4))))))) then
                        return
                    end
                end
                v11.CFrame = if v2 then v2 else v22
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
                if v3 then v3.Visible = false end
            end)

            if v19 then v19:Disconnect() v19 = nil end
            v19 = v13.MouseButton1Up:Connect(function(p1)
                local v1 = v22
                v22 = v13.Adornee.CFrame
                v14 = false
                v13.Axes = Axes.new(Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z)
                checkToUnlockCameraRotation()

                for k, v in pairs(t) do v.Visible = true end
                if v3 then v3.Visible = true end

                if v1 == v22 then return end
                performServerOperatoin(v1, v22)
            end)

            v21 = v13.MouseDrag:Connect(function(p1, p2, p3)
                if math.deg(p2) < -180 then p2 = p2 + 6.283185307179586
                elseif math.deg(p2) > 180 then p2 = p2 - 6.283185307179586 end

                local v1 = tonumber(v9.ModeImage.More.Scale.TextBox.Text)
                if v1 ~= 0 then p2 = math.rad(v1 * math.round(math.deg(p2) / v1)) end

                local v5 = nil
                if p1 == Enum.Axis.X then v5 = v22 * CFrame.Angles(p2, 0, 0)
                elseif p1 == Enum.Axis.Y then v5 = v22 * CFrame.Angles(0, p2, 0)
                elseif p1 == Enum.Axis.Z then v5 = v22 * CFrame.Angles(0, 0, p2) end

                if not _G.DisableToolLimit then
                    local v7 = workspace:FindFirstChild(tostring(LocalPlayer.TeamColor) .. "Zone")
                    local Size = v11.Size
                    if not (isPartInZone(v5 * CFrame.new(Size.X / 2, 0, 0), v7) and (isPartInZone(v5 * CFrame.new(-Size.X / 2, 0, 0), v7) and (isPartInZone(v5 * CFrame.new(0, Size.Y / 2, 0), v7) and (isPartInZone(v5 * CFrame.new(0, -Size.Y / 2, 0), v7) and (isPartInZone(v5 * CFrame.new(0, 0, Size.Z / 2), v7) and (isPartInZone(v5 * CFrame.new(0, 0, -Size.Z / 2), v7))))))) then
                        return
                    end
                end
                v11.CFrame = if v5 then v5 else v22
            end)
        end

        local v15 = getSelectedModels()
        local v2 = #v15

        if v2 < 1 then
            removeBoundingBox()
        else
            table.sort(v15, function(p1, p2)
                if p1.TrowelSB:GetAttribute("Created") < p2.TrowelSB:GetAttribute("Created") then return true end
            end)

            local PrimaryPart = v15[v2].PrimaryPart
            local v4, v5 = GetBoundingBox(v15, PrimaryPart.CFrame - PrimaryPart.Position)
            v11.Size = v5
            v11.CFrame = v4
        end
    end

    function removeBoundingBox()
        if v11 then v11:Destroy() v11 = nil end
        if v12 then v12:Destroy() v12 = nil end
        if v13 then v13:Destroy() v13 = nil end
    end

    function uneq()
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

    function updateHandles()
        if not (v12 and v13) then return end
        v12.Visible = false
        v13.Visible = false

        local v1 = isMobilePlayer() or not doingShiftSelect()
        if v11 then v11:FindFirstChild("SelectionBox") end

        local Mode = v9.Mode.Value
        if Mode == "Move" then
            v12.Color3 = Color3.fromRGB(13, 105, 172)
            v12.Visible = v1
            v12.Style = "Movement"
            return
        end
        if Mode == "Rotate" then v13.Visible = v1 return end
        if Mode == "Clone" then
            v12.Color3 = Color3.fromRGB(20, 255, 169)
            v12.Visible = v1
            v12.Style = "Movement"
            return
        end
        if Mode ~= "Mirror" then return end
        v12.Color3 = Color3.fromRGB(248, 37, 255)
        v12.Visible = v1
        v12.Style = "Resize"
    end

    function modeChanged()
        if v12 and v13 then
            updateBoundingBox()
            updateHandles()
        end
    end

    function eq()
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

    function cleanUp()
        if workspace:FindFirstChild("SelectionBox") then
            workspace.SelectionBox:Destroy()
            if v3 then v3:Destroy() v3 = nil end
        end

        if workspace:FindFirstChild("TrowelBoundingBox") then
            workspace.TrowelBoundingBox:Destroy()
            if v11 then removeBoundingBox() end
        end

        local v1 = workspace.Blocks:GetChildren()
        for i = 1, #v1 do
            local v2 = v1[i]:GetChildren()
            for j = 1, #v2 do
                local v32 = v2[j]
                if v32:FindFirstChild("TrowelSB") then v32.TrowelSB:Destroy() end
            end
        end

        for k, v in pairs(t) do v:Destroy() end
        t = {}
    end

    function checkToLockCameraRotation()
        if v15 then return end
        lockCameraRotation()
    end

    function lockCameraRotation()
        v15 = true
        CurrentCamera.CameraType = Enum.CameraType.Scriptable
        local CameraSubject = CurrentCamera.CameraSubject
        if CameraSubject:IsA("Humanoid") then CameraSubject = CameraSubject.RootPart end

        local v1 = CameraSubject.CFrame.p - CurrentCamera.CFrame.p
        local v2 = CurrentCamera.CFrame - CurrentCamera.CFrame.p

        RunService:BindToRenderStep("cameraRotationLock", Enum.RenderPriority.Camera.Value, function()
            CurrentCamera.CFrame = v2 + CameraSubject.CFrame.p - v1
        end)
    end

    function checkToUnlockCameraRotation()
        if not v15 then return end
        unlockCameraRotation()
    end

    function unlockCameraRotation()
        RunService:UnbindFromRenderStep("cameraRotationLock")
        CurrentCamera.CameraType = Enum.CameraType.Custom
        v15 = false
    end

    function inputBegan(p1, p2)
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

    function inputChanged(p1, p2)
        if p1.UserInputType == Enum.UserInputType.MouseMovement then checkForDragSelection() mouseMove() return end
        if p1.KeyCode ~= Enum.KeyCode.Thumbstick1 and p1.KeyCode ~= Enum.KeyCode.Thumbstick2 then return end
        checkForDragSelection()
        mouseMove()
    end

    function inputEnded(p1, p2)
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
    function inputTouchPinch(p1, p2, p3, p4, p5)
        if p5 then return end
        local v1 = p1[1]
        local v2 = p1[2]

        if p4 == Enum.UserInputState.Begin then v31 = (v2 - v1).Magnitude end
        if not (v31 < 120) then return end

        v27 = if p4 == Enum.UserInputState.Begin then true else p4 == Enum.UserInputState.Change
        checkForDragSelection(true, v1, v2)
    end

    function doingShiftSelect()
        return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or (UserInputService:IsKeyDown(Enum.KeyCode.RightShift) or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or (UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or (UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonL2) or isMobilePlayer()))))
    end

    function checkForDragSelection(p1, p2, p3)
        local v12 = v25 and not p1 or (if p1 then v27 else p1)
        if not v12 then return end

        local SelectionBox = v9.SelectionBox
        local v2 = if p1 and p2 then p2 else v26
        local v32 = if p1 and p3 then p3 else Vector2.new(v1.X, v1.Y)

        SelectionBox.Position = UDim2.new(0, v2.X, 0, v2.Y)
        SelectionBox.Size = UDim2.new(0, v32.X - v2.X, 0, v32.Y - v2.Y)

        if v28 or (v14 or not v2) then return end
        if not p1 and (v32 - v2).Magnitude < 24 then return end

        v28 = true
        if p1 then checkToLockCameraRotation() end
        SelectionBox.Visible = true

        while v12 do
            if v3 then v3.Visible = false end
            if not doingShiftSelect() or p1 then clearSelected() end

            local v5 = math.min(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v7 = math.max(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v92 = math.min(SelectionBox.Position.X.Offset, SelectionBox.Position.X.Offset + SelectionBox.Size.X.Offset)
            local v11 = math.max(SelectionBox.Position.Y.Offset, SelectionBox.Position.Y.Offset + SelectionBox.Size.Y.Offset)
            local v122 = workspace.Blocks:GetChildren()

            for i = 1, #v122 do
                local v13 = v122[i]:GetChildren()
                for j = 1, #v13 do
                    local v142 = v13[j]
                    local _, _2, v15 = GetBlockInfo(v142, LocalPlayer)
                    if v142.PrimaryPart and v15 then
                        local v16, v17 = CurrentCamera:WorldToScreenPoint(v142.PrimaryPart.Position)
                        if v17 and (v92 < v16.X and (v16.X < v7 and (v5 < v16.Y and (v16.Y < v11 and not v142:FindFirstChild("TrowelSB"))))) then
                            addSelection(v142)
                        end
                    end
                end
            end

            task.wait()
            v12 = v25 and not p1 or (if p1 then v27 else p1)
        end

        SelectionBox.Visible = false
        if v3 then v3.Visible = true end

        updateBoundingBox()
        updateHandles()

        if not p1 then v28 = false return end
        checkToUnlockCameraRotation()
        v28 = false
    end

    function mouseMove()
        if v10 then v10.Color3 = Color3.fromRGB(0, 134, 171) end
        local Target = v1.Target

        if not Target or (not Target.Parent or isMobilePlayer()) then
            if v3 then v3.Adornee = nil end
            return
        end

        local v12, _, v2 = GetBlockInfo(Target, LocalPlayer)
        local v32 = doingShiftSelect()

        if v3 then v3.Visible = true end

        if v32 then
            if t[v12] then
                t[v12].Color3 = Color3.fromRGB(175, 0, 0)
                v10 = t[v12]
                if v3 then v3.Visible = false end
            end
        else
            if v3 and v3.Adornee and t[v3.Adornee] then v3.Adornee = nil end
            if t[v12] and v3 then v3.Visible = false end
        end

        if v2 then
            if v3 then
                v3.Adornee = v12
                local _2, v4 = v12:GetBoundingBox()
                v3.LineThickness = math.min(v4.X, v4.Y, v4.Z, 2) / 13.334
            end
        else
            if v3 then v3.Adornee = nil end
        end
    end

    function died()
        uneq()
        clearSelected()
        removeBoundingBox()
        tool:Destroy()
    end

    function getBlockValue(p1)
        local v1 = p1.Name
        local v2
        if string.find(v1, "Block") then
            local Size = game.ReplicatedStorage.BuildingParts[v1].PrimaryPart.Size
            local Size2 = p1.PrimaryPart.Size
            v2 = math.max(Size2.X * Size2.Y * Size2.Z / (Size.X * Size.Y * Size.Z), 1)
        else
            v2 = 1
        end
        return v2
    end

    tool.Equipped:Connect(eq)
    tool.Unequipped:Connect(uneq)
end

local function scanAndHook()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")

    local list = {}
    if char then for _, c in ipairs(char:GetChildren()) do table.insert(list, c) end end
    if bp then for _, c in ipairs(bp:GetChildren()) do table.insert(list, c) end end

    for _, item in ipairs(list) do
        if item:IsA("Tool") then
            if item.Name == "BuildingTool" then
                setupBuildingTool(item)
            elseif item.Name == "ScalingTool" then
                setupScalingTool(item)
            elseif item.Name == "TrowelTool" then
                setupTrowelTool(item)
            end
        end
    end
end

local function onCharacterAdded(char)
    dprint("Character detected monitoring tools")
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then task.defer(scanAndHook) end
    end)
    
    local bp = LocalPlayer:WaitForChild("Backpack", 5)
    if bp then
        bp.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then task.defer(scanAndHook) end
        end)
    end
    task.defer(scanAndHook)
end

if LocalPlayer.Character then
    task.spawn(onCharacterAdded, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

task.spawn(function()
    while true do
        scanAndHook()
        task.wait(1)
    end
end)

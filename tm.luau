local debugp = false
_G.DisableToolLimit = _G.DisableToolLimit or false
_G.FullPlace = _G.FullPlace or false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dprint = function(...) if debugp then print("[DEBUG]", ...) end end

local function cleanScripts(tool)
	for _, s in ipairs(tool:GetDescendants()) do
		if s:IsA("LocalScript") then s.Disabled = true dprint("Disabled original script:", s.Name) end
	end
end

-- BUILD TOOL MOD
local function runBuild(tool)
	cleanScripts(tool)
	local v1 = LocalPlayer:GetMouse()
	local CurrentCamera = workspace.CurrentCamera
	local v2 = tool
	local v3, v4, v5, v6, v7, v9, v10, v11, v25, v26
	local v12, v13, v14, v16, v17, v15, v18, v19, v20, v21, v22, v23, v24
	local v8 = CFrame.new()

	local function changeTransparency(p1, p2)
		for _, v in ipairs(p1:GetDescendants()) do
			if v:IsA("BasePart") then v.Transparency = p2 end
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

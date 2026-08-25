--!strict
-- Inclinação direcional, sprint cinematográfico e passos por material adaptados do Quirkbound.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local rootFolder = ReplicatedStorage:WaitForChild("RPGEnhancements")
local Maid = require(rootFolder:WaitForChild("QuirkMaid"))
local config = require(rootFolder:WaitForChild("EnhancementConfig")).Presentation
local maid = nil
local nextFootstep = 0

local donorSounds = {
	Grass = "rbxassetid://507863105", LeafyGrass = "rbxassetid://507863105", Mud = "rbxassetid://507863105",
	Sand = "rbxassetid://265653329", Snow = "rbxassetid://510932495", Metal = "rbxassetid://6876957898",
	DiamondPlate = "rbxassetid://6876957898", Wood = "rbxassetid://507863457", WoodPlanks = "rbxassetid://507863457",
	Concrete = "rbxassetid://5761648082", Rock = "rbxassetid://5761648082", Slate = "rbxassetid://5761648082",
	Plastic = "rbxassetid://7326203155", SmoothPlastic = "rbxassetid://7326203155", Glass = "rbxassetid://9117949159",
}

local function setFov(value: number)
	local camera = workspace.CurrentCamera
	if camera then TweenService:Create(camera, TweenInfo.new(.24, Enum.EasingStyle.Quad), {FieldOfView = value}):Play() end
end

local function initialize(character: Model)
	if maid then maid:Destroy() end
	maid = Maid.new()
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then return end
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	local rootJoint = root:FindFirstChild("RootJoint") or (torso and torso:FindFirstChild("Waist"))
	local neck = torso and torso:FindFirstChild("Neck")
	local rootOrigin = rootJoint and rootJoint.C0
	local neckOrigin = neck and neck.C0
	local accumulator = 0

	maid:Mark(RunService.RenderStepped:Connect(function(dt)
		if not character.Parent or humanoid.Health <= 0 then return end
		accumulator += dt
		if accumulator < 1 / 45 then return end
		local alpha = 1 - math.exp(-10 * accumulator)
		accumulator = 0
		local localMove = root.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		if rootJoint and rootOrigin then
			local pitch, roll = -localMove.Z * math.rad(7), -localMove.X * math.rad(11)
			rootJoint.C0 = rootJoint.C0:Lerp(rootOrigin * CFrame.Angles(pitch, 0, roll), alpha)
		end
		if neck and neckOrigin then neck.C0 = neck.C0:Lerp(neckOrigin * CFrame.Angles(localMove.Z * math.rad(4), 0, localMove.X * math.rad(6)), alpha) end
		if humanoid.MoveDirection.Magnitude < .1 or humanoid.FloorMaterial == Enum.Material.Air then return end
		local now = os.clock()
		if now < nextFootstep then return end
		nextFootstep = now + math.clamp(8 / math.max(10, humanoid.WalkSpeed), .21, .48)
		local soundId = donorSounds[humanoid.FloorMaterial.Name]
		if soundId then
			local step = Instance.new("Sound")
			step.SoundId, step.Volume, step.PlaybackSpeed, step.RollOffMaxDistance = soundId, .19, .92 + math.random() * .17, 32
			step.Parent = root
			step:Play()
			Debris:AddItem(step, 1.5)
		end
	end))

	maid:Mark(humanoid.Died:Connect(function() setFov(config.NormalFOV) end))
	maid:Mark(player:GetAttributeChangedSignal("Sprinting"):Connect(function() setFov(if player:GetAttribute("Sprinting") then config.SprintFOV else config.NormalFOV) end))
	maid:Mark(player:GetAttributeChangedSignal("Dashing"):Connect(function()
		if player:GetAttribute("Dashing") then setFov(config.DashFOV)
		else setFov(if player:GetAttribute("Sprinting") then config.SprintFOV else config.NormalFOV) end
	end))
	setFov(config.NormalFOV)
end

player.CharacterAdded:Connect(function(character) task.defer(initialize, character) end)
if player.Character then task.defer(initialize, player.Character) end

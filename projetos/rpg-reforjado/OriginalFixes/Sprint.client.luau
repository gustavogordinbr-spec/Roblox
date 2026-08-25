--!strict
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SprintEvent")
local track, movingConnection, running = nil, nil, false

local function animationForCharacter(character: Model)
	if track then pcall(function() track:Stop(.1) end); track = nil end
	if movingConnection then movingConnection:Disconnect() end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	local animator = humanoid:WaitForChild("Animator", 5)
	if not animator then return end
	local imported = ReplicatedStorage:FindFirstChild("RPGEnhancements")
	local assets = imported and imported:FindFirstChild("Animations")
	local animation = (assets and assets:FindFirstChild("QuirkSprint")) or ReplicatedStorage.Animations:FindFirstChild("Run")
	if animation then
		local ok, result = pcall(function() return animator:LoadAnimation(animation) end)
		if ok and result then track = result; track.Priority = Enum.AnimationPriority.Movement; track.Looped = true end
	end
	movingConnection = humanoid.Running:Connect(function(speed)
		if not track then return end
		if running and speed > 2 and not track.IsPlaying then pcall(function() track:Play(.14) end)
		elseif (not running or speed <= 2) and track.IsPlaying then track:Stop(.14) end
	end)
end

local function setRequested(value: boolean)
	if running == value then return end
	if value and (player:GetAttribute("Energia") or 0) < 10 then return end
	running = value
	remote:FireServer(value)
	if not value and track and track.IsPlaying then track:Stop(.15) end
end

ContextActionService:BindAction("RPGSprint", function(_, state)
	if state == Enum.UserInputState.Begin then setRequested(true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then setRequested(false) end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("RPGSprint", "CORRER")
ContextActionService:SetPosition("RPGSprint", UDim2.fromScale(.8, .62))

player:GetAttributeChangedSignal("Sprinting"):Connect(function()
	if player:GetAttribute("Sprinting") ~= true then running = false; if track and track.IsPlaying then track:Stop(.12) end end
end)
player.CharacterAdded:Connect(function(character) running = false; task.defer(animationForCharacter, character) end)
if player.Character then task.defer(animationForCharacter, player.Character) end

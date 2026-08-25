--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tool, player = script.Parent, Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("Combo")
local fallback = script:WaitForChild("Anims", 8)
local imported = ReplicatedStorage:WaitForChild("RPGEnhancements", 10)
local animations = imported and imported:WaitForChild("Animations", 6)
local combo, availableAt, resetVersion = 0, 0, 0

local function attack()
	local now = os.clock()
	if now < availableAt then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator or humanoid.Health <= 0 then return end
	combo = combo % 5 + 1
	availableAt = now + .37
	resetVersion += 1
	local currentVersion = resetVersion
	local animation = animations and animations:FindFirstChild("QuirkFist" .. combo)
	if not animation and fallback then animation = fallback:FindFirstChild(if combo % 2 == 0 then "Melee2" else "Melee1") end
	if animation then
		local ok, clip = pcall(function() return animator:LoadAnimation(animation) end)
		if ok and clip then clip.Priority = Enum.AnimationPriority.Action; pcall(function() clip:Play(.07, 1, 1.12) end) end
	end
	local limb = if combo % 2 == 1 then (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")) else (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	limb = limb or character:FindFirstChild("HumanoidRootPart")
	if limb then remote:FireServer(limb, "Combo" .. combo) end
	local swing = script:FindFirstChild("Swing")
	if swing and swing:IsA("Sound") then swing.PlaybackSpeed = .94 + math.random() * .14; swing:Play() end
	task.delay(1.3, function() if resetVersion == currentVersion then combo = 0 end end)
end

Tool.Activated:Connect(attack)
Tool.Unequipped:Connect(function() combo = 0; resetVersion += 1 end)

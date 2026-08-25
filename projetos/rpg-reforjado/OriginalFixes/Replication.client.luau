--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Destruction")
local breakerModule = ReplicatedStorage:FindFirstChild("VoxBreaker")
local breaker = nil
if breakerModule then local ok, value = pcall(require, breakerModule); if ok then breaker = value end end
local lastEffect = 0

remote.OnClientEvent:Connect(function(attacker: Player)
	if not breaker or typeof(attacker) ~= "Instance" or not attacker:IsA("Player") then return end
	local now = os.clock()
	if now - lastEffect < .45 then return end
	local root = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	local localRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not localRoot or (root.Position - localRoot.Position).Magnitude > 80 then return end
	lastEffect = now
	local ok, pieces = pcall(function() return breaker:CreateHitbox(Vector3.new(3, 3, 3), root.CFrame, Enum.PartType.Ball, 2.5, 20) end)
	if not ok or type(pieces) ~= "table" then return end
	for index, piece in ipairs(pieces) do
		if index > 18 then break end
		if piece:IsA("BasePart") then
			piece.Anchored, piece.CanCollide = false, false
			piece.AssemblyLinearVelocity = Vector3.new(math.random(-22, 22), math.random(12, 28), math.random(-22, 22))
			piece.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
			TweenService:Create(piece, TweenInfo.new(1.1, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
			Debris:AddItem(piece, 1.3)
		end
	end
end)

--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyBrain = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnemyBrain"))
local model = script.Parent
local humanoid = model:FindFirstChildOfClass("Humanoid")
if not humanoid then return end
local level = math.max(1, tonumber(model:GetAttribute("Level")) or tonumber(model:GetAttribute("EnemyLevel")) or 1)
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local attacks = {}

for _, name in ipairs({"AttackAnim", "AttackAnim1"}) do
	local animation = script:FindFirstChild(name)
	if animation and animation:IsA("Animation") then
		local ok, clip = pcall(function() return animator:LoadAnimation(animation) end)
		if ok then table.insert(attacks, clip) end
	end
end

EnemyBrain.Bind(model, {
	AggroRange = 48, LeashRange = 100, ChaseSpeed = 17, WalkSpeed = 10,
	BaseDamage = 28 + level * 7, AttackCooldown = .95, AttackAnimations = attacks,
	Tier = "Elite", AssistRange = 31, PatrolRadius = 20, MemorySeconds = 7,
})

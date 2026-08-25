--!strict
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local model = script.Parent
local humanoid = model:FindFirstChildOfClass("Humanoid")
local root = model:FindFirstChild("HumanoidRootPart")
if not humanoid or not root then return end
local origin, attackAt, movedAt, wanderAt, lastPath = root.Position, 0, 0, 0, 0
local level = math.max(1, tonumber(model:GetAttribute("Level")) or tonumber(model:GetAttribute("EnemyLevel")) or 1)
local damage = 32 + level * 8
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
local clips, combo = {}, 0

for _, name in ipairs({"AttackAnim", "AttackAnim1", "IdleAnim", "WalkAnim"}) do
	local animation = script:FindFirstChild(name)
	if animation and animation:IsA("Animation") then local ok, clip = pcall(function() return animator:LoadAnimation(animation) end); if ok then clips[name] = clip end end
end

local function nearest()
	local best, distance = nil, 44
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
			local measured = (targetRoot.Position - root.Position).Magnitude
			if measured < distance then best, distance = character, measured end
		end
	end
	return best, distance
end

local function attack(character: Model)
	local now = os.clock()
	if now - attackAt < 1 then return end
	local target = character:FindFirstChildOfClass("Humanoid")
	local targetRoot = character:FindFirstChild("HumanoidRootPart")
	if not target or not targetRoot or target.Health <= 0 or (targetRoot.Position - root.Position).Magnitude > 5 then return end
	attackAt = now
	combo = combo % 2 + 1
	local clip = clips[if combo == 1 then "AttackAnim" else "AttackAnim1"]
	if clip then pcall(function() clip:Play(.08) end) end
	task.delay(.18, function()
		if humanoid.Health <= 0 or target.Health <= 0 or (targetRoot.Position - root.Position).Magnitude > 7 then return end
		local amount = damage
		if character:GetAttribute("Blocking") then amount = math.floor(amount * .32) end
		local previous = target:FindFirstChild("LastAttacker")
		if previous then previous:Destroy() end
		local marker = Instance.new("ObjectValue"); marker.Name = "LastAttacker"; marker.Value = model; marker.Parent = target; Debris:AddItem(marker, 3)
		target:TakeDamage(math.max(1, amount))
	end)
end

while humanoid.Health > 0 and model.Parent do
	local now = os.clock()
	local target, distance = nearest()
	if (root.Position - origin).Magnitude > 90 then target = nil; humanoid:MoveTo(origin) end
	if target and distance <= 4.5 then
		humanoid.WalkSpeed = 13
		attack(target)
	elseif target then
		humanoid.WalkSpeed = 16
		local targetRoot = target:FindFirstChild("HumanoidRootPart")
		if targetRoot and now - movedAt > .3 then humanoid:MoveTo(targetRoot.Position); movedAt = now end
		local walk = clips.WalkAnim
		if walk and not walk.IsPlaying then pcall(function() walk:Play(.15) end) end
	elseif now > wanderAt then
		wanderAt = now + math.random(4, 7)
		humanoid.WalkSpeed = 9
		local destination = origin + Vector3.new(math.random(-18, 18), 0, math.random(-18, 18))
		local ok = pcall(function()
			local path = PathfindingService:CreatePath()
			path:ComputeAsync(root.Position, destination)
			local points = path:GetWaypoints()
			if path.Status == Enum.PathStatus.Success and #points > 0 then humanoid:MoveTo(points[#points].Position) else humanoid:MoveTo(destination) end
		end)
		if not ok then humanoid:MoveTo(destination) end
	end
	task.wait(.16)
end

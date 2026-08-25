--!strict
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local event = ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("Combo")
local config = require(ReplicatedStorage:WaitForChild("RPGEnhancements"):WaitForChild("EnhancementConfig")).Combat
local lastAttack, chains = {}, {}

local function markCreator(humanoid: Humanoid, player: Player)
	local existing = humanoid:FindFirstChild("creator")
	if existing then existing:Destroy() end
	local marker = Instance.new("ObjectValue")
	marker.Name, marker.Value, marker.Parent = "creator", player, humanoid
	Debris:AddItem(marker, 4)
end

local function findTargets(character: Model, root: BasePart): {Humanoid}
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}
	params.MaxParts = 32
	local box = root.CFrame * CFrame.new(0, 0, -config.HitboxSize.Z * 0.42)
	local unique, result = {}, {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(box, config.HitboxSize, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local target = model and model:FindFirstChildOfClass("Humanoid")
		local targetRoot = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		if target and targetRoot and target.Health > 0 and not unique[target] then
			local targetPlayer = Players:GetPlayerFromCharacter(model)
			if (config.PvPEnabled or not targetPlayer) and (targetRoot.Position - root.Position).Magnitude <= config.Reach + 3 then
				unique[target] = true
				table.insert(result, target)
			end
		end
	end
	return result
end

event.OnServerEvent:Connect(function(player: Player, requestedLimb: any, comboName: any)
	if typeof(comboName) ~= "string" or not string.match(comboName, "^Combo[1-5]$") then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local attacker = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not attacker or attacker.Health <= 0 then return end
	if typeof(requestedLimb) ~= "Instance" or not requestedLimb:IsA("BasePart") or not requestedLimb:IsDescendantOf(character) then return end
	local now = os.clock()
	if now - (lastAttack[player] or 0) < config.AttackCooldown then return end
	lastAttack[player] = now
	local chain = chains[player]
	local step = if chain and now - chain.Time <= config.ComboReset then math.min(chain.Step + 1, 5) else 1
	chains[player] = {Step = step, Time = now}
	player:SetAttribute("InCombatUntil", now + 6)
	local hits = 0
	for _, target in ipairs(findTargets(character, root)) do
		if hits >= 3 then break end
		local base = math.max(8, tonumber(player:GetAttribute("DanoBaseFisico")) or 10)
		local damage = base * ({1, 1.08, 1.16, 1.25, 1.45})[step]
		local targetModel = target.Parent
		local defense = tonumber(targetModel and targetModel:GetAttribute("Defesa")) or 0
		damage *= 100 / (100 + math.max(0, defense))
		local critical = math.random() < math.clamp(tonumber(player:GetAttribute("CriticoChance")) or .05, 0, .75)
		if critical then damage *= math.clamp(tonumber(player:GetAttribute("CriticoMultiplicador")) or 1.5, 1, 3) end
		if targetModel and targetModel:GetAttribute("Blocking") then damage *= 1 - config.BlockReduction end
		markCreator(target, player)
		target:TakeDamage(math.max(1, math.floor(damage)))
		hits += 1
		local hitSound = script:FindFirstChild("Hit")
		if hitSound and hitSound:IsA("Sound") then local sound = hitSound:Clone(); sound.Parent = root; sound:Play(); Debris:AddItem(sound, 2) end
		local notify = ReplicatedStorage.Remotes:FindFirstChild("RPGNotification")
		if notify and critical then notify:FireClient(player, "CRÍTICO!", tostring(math.floor(damage)) .. " de dano", "critical") end
	end
	if hits > 0 then
		local counter = player:FindFirstChild("Combo")
		if counter and counter:IsA("IntValue") then counter.Value += hits end
		if step == 5 then
			local destruction = ReplicatedStorage:FindFirstChild("Destruction")
			if destruction and destruction:IsA("RemoteEvent") then
				for _, observer in ipairs(Players:GetPlayers()) do
					local observerRoot = observer.Character and observer.Character:FindFirstChild("HumanoidRootPart")
					if observerRoot and (observerRoot.Position - root.Position).Magnitude <= 80 then destruction:FireClient(observer, player) end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) lastAttack[player], chains[player] = nil, nil end)

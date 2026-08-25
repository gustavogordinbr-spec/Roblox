--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local EnemyBrain = {}
local active = {}
local defaults = {
	AggroRange = 42, AttackRange = 4.6, AttackCooldown = 1.1, LeashRange = 88,
	MemorySeconds = 5, ThinkInterval = .2, PathInterval = 1.1, AssistRange = 27,
	BaseDamage = 20, PatrolRadius = 18, WalkSpeed = 10, ChaseSpeed = 16,
	Tier = "Normal", AttackAnimations = {},
}

local function configuration(overrides)
	local values = table.clone(defaults)
	for key, value in pairs(overrides or {}) do values[key] = value end
	return values
end

local function setState(state, name: string)
	if state.mode ~= name then state.mode = name; state.model:SetAttribute("AIState", name) end
end

local function targetParts(character: Model?)
	if not character then return nil, nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return nil, nil end
	return root, humanoid
end

local function visible(state, root: BasePart): boolean
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {state.model}
	local hit = workspace:Raycast(state.root.Position + Vector3.new(0, 1, 0), root.Position - state.root.Position, parameters)
	return not hit or hit.Instance:IsDescendantOf(root.Parent)
end

local function chooseTarget(state)
	local selected, score = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local root, humanoid = targetParts(player.Character)
		if root and humanoid then
			local distance = (root.Position - state.root.Position).Magnitude
			local remembered = state.target == player.Character and os.clock() - state.lastSeen <= state.settings.MemorySeconds
			if distance <= state.settings.AggroRange + (if remembered then 15 else 0) and (remembered or visible(state, root)) then
				local threat = state.threat[player.UserId] or 0
				local candidate = distance - math.min(threat, 22) - (1 - humanoid.Health / math.max(1, humanoid.MaxHealth)) * 5
				if candidate < score then selected, score = player.Character, candidate end
			end
		end
	end
	return selected
end

local function move(state, destination: Vector3, now: number)
	if now - state.lastPath < state.settings.PathInterval then
		if now - state.lastMove > .28 then state.humanoid:MoveTo(destination); state.lastMove = now end
		return
	end
	state.lastPath = now
	local direct = (destination - state.root.Position).Magnitude < 9
	if direct then state.humanoid:MoveTo(destination); state.lastMove = now; return end
	local ok, path = pcall(function()
		local computed = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 5})
		computed:ComputeAsync(state.root.Position, destination)
		return computed
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		local points = path:GetWaypoints()
		local point = points[math.min(3, #points)]
		if point then
			if point.Action == Enum.PathWaypointAction.Jump then state.humanoid.Jump = true end
			state.humanoid:MoveTo(point.Position)
			state.lastMove = now
			return
		end
	end
	state.humanoid:MoveTo(destination)
	state.lastMove = now
end

local function alertAllies(state, character: Model)
	if os.clock() - state.lastAlert < 3 then return end
	state.lastAlert = os.clock()
	for _, ally in ipairs(CollectionService:GetTagged("RPGEnemy")) do
		local allyState = active[ally]
		if allyState and allyState ~= state and (allyState.root.Position - state.root.Position).Magnitude <= state.settings.AssistRange then
			allyState.target, allyState.lastSeen = character, os.clock()
			setState(allyState, "Alertado")
		end
	end
end

local function attack(state, character: Model, now: number)
	if now - state.lastAttack < state.settings.AttackCooldown then return end
	local root, humanoid = targetParts(character)
	if not root or not humanoid or (root.Position - state.root.Position).Magnitude > state.settings.AttackRange + .8 then return end
	state.lastAttack = now
	state.combo += 1
	local heavy = state.settings.Tier ~= "Normal" and state.combo % 4 == 0
	setState(state, if heavy then "PreparandoGolpe" else "Atacando")
	state.model:SetAttribute("AttackTelegraph", heavy)
	local clips = state.settings.AttackAnimations
	local clip = if #clips > 0 then clips[(state.combo - 1) % #clips + 1] else nil
	if clip then pcall(function() clip:Play(.1) end) end
	task.delay(if heavy then .46 else .18, function()
		state.model:SetAttribute("AttackTelegraph", false)
		if state.humanoid.Health <= 0 or humanoid.Health <= 0 or not root.Parent then return end
		if (root.Position - state.root.Position).Magnitude > state.settings.AttackRange + (if heavy then 2.4 else 1.6) then return end
		local player = Players:GetPlayerFromCharacter(character)
		if character:GetAttribute("IsDashing") or (player and player:GetAttribute("Dashing")) then return end
		local defense = if player then math.clamp((tonumber(player:GetAttribute("Defesa")) or 0) / 260, 0, .48) else 0
		local damage = state.settings.BaseDamage * (if heavy then 1.65 else 1) * (1 - defense)
		if character:GetAttribute("Blocking") then damage *= if heavy then .57 else .32 end
		local previous = humanoid:FindFirstChild("LastAttacker")
		if previous then previous:Destroy() end
		local marker = Instance.new("ObjectValue")
		marker.Name, marker.Value, marker.Parent = "LastAttacker", state.model, humanoid
		Debris:AddItem(marker, 3)
		humanoid:TakeDamage(math.max(1, math.floor(damage + .5)))
	end)
end

local function think(state)
	local now = os.clock()
	local homeDistance = (state.root.Position - state.origin).Magnitude
	if homeDistance > state.settings.LeashRange then
		state.target, state.lastKnown = nil, nil
		state.humanoid.WalkSpeed = state.settings.ChaseSpeed
		setState(state, "Retornando")
		move(state, state.origin, now)
		return
	end
	local target = chooseTarget(state)
	if target then
		state.target = target
		local root = targetParts(target)
		if root and visible(state, root) then state.lastSeen, state.lastKnown = now, root.Position end
		if root then
			local distance = (root.Position - state.root.Position).Magnitude
			alertAllies(state, target)
			if distance <= state.settings.AttackRange then
				state.humanoid.WalkSpeed = state.settings.WalkSpeed
				attack(state, target, now)
				if now - state.lastStrafe > 1.7 then
					state.lastStrafe = now
					local side = state.root.CFrame.RightVector * (if state.combo % 2 == 0 then 3 else -3)
					state.humanoid:MoveTo(state.root.Position + side)
				end
			else
				setState(state, "Perseguindo")
				state.humanoid.WalkSpeed = state.settings.ChaseSpeed
				local velocity = root.AssemblyLinearVelocity
				move(state, root.Position + Vector3.new(velocity.X, 0, velocity.Z) * .23, now)
			end
		end
	elseif state.lastKnown and now - state.lastSeen < state.settings.MemorySeconds then
		setState(state, "Investigando")
		state.humanoid.WalkSpeed = state.settings.WalkSpeed + 2
		move(state, state.lastKnown, now)
	else
		state.target, state.lastKnown = nil, nil
		state.humanoid.WalkSpeed = state.settings.WalkSpeed
		if now >= state.nextPatrol then
			state.nextPatrol = now + math.random(4, 8)
			setState(state, "Patrulhando")
			move(state, state.origin + Vector3.new(math.random(-state.settings.PatrolRadius, state.settings.PatrolRadius), 0, math.random(-state.settings.PatrolRadius, state.settings.PatrolRadius)), now)
		end
	end
	if now - state.lastStuckCheck > 2 then
		if state.target and (state.root.Position - state.lastPosition).Magnitude < 1.2 then state.humanoid.Jump = true; state.lastPath = 0 end
		state.lastPosition, state.lastStuckCheck = state.root.Position, now
	end
end

function EnemyBrain.Bind(model: Model, overrides)
	if active[model] then return active[model] end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then return nil end
	local state = {
		model = model, humanoid = humanoid, root = root, origin = root.Position,
		settings = configuration(overrides), threat = {}, target = nil, lastKnown = nil,
		mode = "Vigilante", lastSeen = 0, lastAttack = 0, lastMove = 0, lastPath = 0,
		lastAlert = 0, lastStrafe = 0, lastStuckCheck = 0, lastPosition = root.Position,
		nextPatrol = os.clock() + math.random(2, 5), combo = 0, previousHealth = humanoid.Health,
	}
	active[model] = state
	model:SetAttribute("AIState", "Vigilante")
	if not CollectionService:HasTag(model, "RPGEnemy") then CollectionService:AddTag(model, "RPGEnemy") end
	humanoid.HealthChanged:Connect(function(health)
		local lost = state.previousHealth - health
		state.previousHealth = health
		if lost <= 0 then return end
		local marker = humanoid:FindFirstChild("creator")
		local player = marker and marker.Value
		if player and player:IsA("Player") then
			state.threat[player.UserId] = (state.threat[player.UserId] or 0) + lost * .34
			state.target, state.lastSeen = player.Character, os.clock()
		end
	end)
	humanoid.Died:Once(function() active[model] = nil; model:SetAttribute("AIState", "Derrotado") end)
	task.spawn(function()
		while active[model] == state and model.Parent and humanoid.Health > 0 do
			local ok, message = pcall(think, state)
			if not ok then warn("[RPG/IA]", model.Name, message) end
			task.wait(state.settings.ThinkInterval)
		end
		active[model] = nil
	end)
	return state
end

function EnemyBrain.Unbind(model: Model)
	active[model] = nil
end

return EnemyBrain

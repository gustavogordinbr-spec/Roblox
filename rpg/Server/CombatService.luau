--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))
local Items = require(Shared:WaitForChild("ItemDefinitions"))
local Abilities = require(Shared:WaitForChild("AbilityDefinitions"))

local CombatService = {}
local profiles
local progression
local inventory
local quests
local parties
local notify
local sync
local cooldowns = {}
local registeredEnemies = {}

function CombatService.Init(profileService, progressionService, inventoryService, questService, partyService, notifier, synchronize)
	profiles, progression, inventory, quests, parties, notify, sync = profileService, progressionService, inventoryService, questService, partyService, notifier, synchronize
end

local function rootOf(model)
	return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function eligibleEnemy(target)
	return target and target:IsA("Model") and target.Parent and target:FindFirstChildOfClass("Humanoid")
		and not Players:GetPlayerFromCharacter(target)
		and (target:GetAttribute("RPGEnemy") == true or CollectionService:HasTag(target, "RPGEnemy"))
end

function CombatService.GetDamage(player, baseDamage)
	local profile = profiles.Get(player)
	if not profile then return 0 end
	local weapon = Items[profile.Equipped.Weapon]
	local weaponPower = weapon and weapon.Power or 0
	local damage = baseDamage + profile.Attributes.Strength * 1.6 + weaponPower + profile.Level * 1.2
	local critical = Random.new():NextNumber() < math.clamp(profile.Attributes.Luck * 0.006, 0, 0.35)
	return math.floor(if critical then damage * 1.65 else damage), critical
end

local function rewardDefeat(enemy, lastAttacker)
	if enemy:GetAttribute("RPGRewarded") then return end
	enemy:SetAttribute("RPGRewarded", true)
	local enemyLevel = enemy:GetAttribute("RPGLevel") or 1
	local rank = enemy:GetAttribute("RPGRank") or "Normal"
	local multiplier = if rank == "Boss" then 6 elseif rank == "Elite" then 2.5 else 1
	local enemyRoot = rootOf(enemy)
	for _, member in ipairs(parties.GetMembers(lastAttacker)) do
		local memberRoot = rootOf(member.Character)
		local profile = profiles.Get(member)
		if profile and memberRoot and enemyRoot and (memberRoot.Position - enemyRoot.Position).Magnitude <= 120 then
			local partyBonus = 1 + math.max(0, #parties.GetMembers(lastAttacker) - 1) * Config.PartyExperienceBonus
			local xp = math.floor((30 + enemyLevel * 18) * multiplier * partyBonus)
			local gold = math.floor((12 + enemyLevel * 7) * multiplier)
			profile.Gold += gold
			profile.Kills += 1
			if rank == "Boss" then profile.BossKills += 1 end
			progression.AddXP(member, xp, enemy.Name)
			quests.Progress(member, "Kill", rank, 1)
			if Random.new():NextNumber() < 0.48 + profile.Attributes.Luck * 0.003 then inventory.Add(member, "IronOre", Random.new():NextInteger(1, 2)) end
			if rank ~= "Normal" and Random.new():NextNumber() < 0.72 then inventory.Add(member, "AuroraShard", 1) end
			if rank == "Boss" then inventory.Add(member, "BossCore", 1) end
			notify(member, "Reward", "+" .. tostring(gold) .. " ouro · " .. enemy.Name .. " derrotado")
			sync(member)
		end
	end
end

function CombatService.RegisterEnemy(model, level, rank)
	if not model or registeredEnemies[model] then return end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	registeredEnemies[model] = true
	model:SetAttribute("RPGEnemy", true)
	model:SetAttribute("RPGLevel", level or math.max(1, math.floor(humanoid.MaxHealth / 100)))
	model:SetAttribute("RPGRank", rank or (if humanoid.MaxHealth >= 1500 then "Boss" elseif humanoid.MaxHealth >= 500 then "Elite" else "Normal"))
	humanoid.Died:Connect(function()
		local userId = model:GetAttribute("RPGLastAttacker")
		local attacker = userId and Players:GetPlayerByUserId(userId)
		if attacker then rewardDefeat(model, attacker) end
	end)
end

function CombatService.Attack(player, target, attackType)
	if not eligibleEnemy(target) then return false end
	local character = player.Character
	local playerRoot, targetRoot = rootOf(character), rootOf(target)
	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not playerRoot or not targetRoot or not humanoid or humanoid.Health <= 0 then return false end
	local maxRange = if attackType == "Heavy" then 16 else 13
	if (playerRoot.Position - targetRoot.Position).Magnitude > maxRange then return false end
	local key = tostring(player.UserId) .. "_attack"
	local delay = if attackType == "Heavy" then 1.2 else 0.42
	if cooldowns[key] and os.clock() - cooldowns[key] < delay then return false end
	cooldowns[key] = os.clock()
	if attackType == "Heavy" then
		local stamina = character:GetAttribute("RPGStamina") or 0
		if stamina < 18 then return false end
		character:SetAttribute("RPGStamina", stamina - 18)
	end
	local damage, critical = CombatService.GetDamage(player, if attackType == "Heavy" then 28 else 13)
	target:SetAttribute("RPGLastAttacker", player.UserId)
	humanoid:TakeDamage(damage)
	character:SetAttribute("RPGCombatUntil", os.clock() + Config.CombatTagSeconds)
	notify(player, "Damage", tostring(damage) .. (if critical then " CRÍTICO" else ""))
	return true
end

function CombatService.UseAbility(player, abilityId, target)
	local profile = profiles.Get(player)
	local ability = Abilities[abilityId]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not profile or not ability or not character or not humanoid or not profile.UnlockedAbilities[abilityId] then return false end
	local key = tostring(player.UserId) .. "_" .. abilityId
	if cooldowns[key] and os.clock() - cooldowns[key] < ability.Cooldown then return false end
	local mana = character:GetAttribute("RPGMana") or 0
	if mana < ability.Mana then notify(player, "Warning", "Foco insuficiente."); return false end
	cooldowns[key] = os.clock()
	character:SetAttribute("RPGMana", mana - ability.Mana)
	local playerRoot = rootOf(character)
	if ability.Kind == "Heal" then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + ability.Amount + profile.Attributes.Intelligence * 2)
	elseif ability.Kind == "PartyHeal" then
		for _, member in ipairs(parties.GetMembers(player)) do
			local memberRoot = rootOf(member.Character)
			local memberHumanoid = member.Character and member.Character:FindFirstChildOfClass("Humanoid")
			if memberRoot and playerRoot and memberHumanoid and (memberRoot.Position - playerRoot.Position).Magnitude <= ability.Range then
				memberHumanoid.Health = math.min(memberHumanoid.MaxHealth, memberHumanoid.Health + ability.Amount + profile.Attributes.Intelligence * 2)
			end
		end
	elseif ability.Kind == "Shield" then
		character:SetAttribute("RPGShield", (character:GetAttribute("RPGShield") or 0) + ability.Amount)
	elseif ability.Kind == "Dash" and playerRoot then
		local destination = playerRoot.Position + playerRoot.CFrame.LookVector * ability.Distance
		local result = workspace:Raycast(playerRoot.Position, playerRoot.CFrame.LookVector * ability.Distance)
		if result then destination = result.Position - playerRoot.CFrame.LookVector * 3 end
		character:PivotTo(CFrame.new(destination, destination + playerRoot.CFrame.LookVector))
	elseif ability.Kind == "Damage" and eligibleEnemy(target) and playerRoot and rootOf(target) then
		if (playerRoot.Position - rootOf(target).Position).Magnitude <= ability.Range then
			local damage = CombatService.GetDamage(player, ability.Damage + profile.Attributes.Intelligence)
			target:SetAttribute("RPGLastAttacker", player.UserId)
			target:FindFirstChildOfClass("Humanoid"):TakeDamage(damage)
			notify(player, "Damage", tostring(damage) .. " · " .. ability.Name)
		end
	elseif ability.Kind == "Area" and playerRoot then
		for enemy in pairs(registeredEnemies) do
			local enemyRoot = rootOf(enemy)
			local enemyHumanoid = enemy.Parent and enemy:FindFirstChildOfClass("Humanoid")
			if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 and (enemyRoot.Position - playerRoot.Position).Magnitude <= ability.Range then
				local damage = CombatService.GetDamage(player, ability.Damage + profile.Attributes.Intelligence)
				enemy:SetAttribute("RPGLastAttacker", player.UserId)
				enemyHumanoid:TakeDamage(damage)
			end
		end
	end
	notify(player, "Ability", ability.Name .. " ativada.")
	sync(player)
	return true
end

return CombatService

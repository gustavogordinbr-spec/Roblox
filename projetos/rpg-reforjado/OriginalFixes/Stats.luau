--!strict
local GameConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GameConfig"))
local Base, Scaling, Movement = GameConfig.BaseStats, GameConfig.Scaling, GameConfig.Movement
local Progression, Factors, Caps = GameConfig.Progression, GameConfig.Factors, GameConfig.SoftCap
local Combat, Regen = GameConfig.Combat, GameConfig.Regeneration
local Stats = {Modifiers = {}, Hooks = {AntesDerivados = {}, DepoisDerivados = {}}}

function Stats.AddModifier(player: Player, stat: string, id: string, value: any)
	if not player or type(stat) ~= "string" or type(id) ~= "string" then return end
	Stats.Modifiers[player] = Stats.Modifiers[player] or {}
	Stats.Modifiers[player][stat] = Stats.Modifiers[player][stat] or {}
	Stats.Modifiers[player][stat][id] = value
end

function Stats.RemoveModifier(player: Player, stat: string, id: string)
	local group = Stats.Modifiers[player] and Stats.Modifiers[player][stat]
	if group then group[id] = nil end
end

function Stats.ClearModifiers(player: Player) Stats.Modifiers[player] = nil end
function Stats.CleanupPlayer(player: Player) Stats.Modifiers[player] = nil end

local function modifiers(player: Player, stat: string, value: number): number
	local group = Stats.Modifiers[player] and Stats.Modifiers[player][stat]
	if not group then return value end
	local flat, multiplier, percent = 0, 1, 0
	for _, adjustment in pairs(group) do
		if type(adjustment) == "number" then flat += adjustment
		elseif type(adjustment) == "table" then flat += tonumber(adjustment.flat) or 0; multiplier *= tonumber(adjustment.mult) or 1; percent += tonumber(adjustment.percent) or 0 end
	end
	return math.max(0, (value + flat) * multiplier * (1 + percent / 100))
end

function Stats.RegisterHook(kind: string, callback: (...any) -> ())
	if Stats.Hooks[kind] and type(callback) == "function" then table.insert(Stats.Hooks[kind], callback) end
end

local function callHooks(kind: string, ...: any)
	for _, hook in ipairs(Stats.Hooks[kind]) do local ok, err = pcall(hook, ...); if not ok then warn("[RPG/Stats] Hook:", err) end end
end

local function softCap(value: number, limit: number, smooth: number): number
	return if value <= limit then value else limit + (value - limit) ^ smooth
end

function Stats.CalcularBase(level: number, multipliers: {[string]: number}?, limiter: number?)
	level = math.max(1, tonumber(level) or 1)
	local scale, result = math.clamp(tonumber(limiter) or 100, 1, 100) / 100, {}
	for stat, base in pairs(Base) do
		local value = base * level ^ (Scaling[stat] or 1) * ((multipliers and multipliers[stat]) or 1)
		result[stat] = softCap(value * scale, Caps.BaseStatLimit, Caps.BaseStatSmooth)
	end
	result.PoderBruto = softCap(level ^ Caps.PoderBrutoExponent, Caps.PoderBrutoLimit, Caps.PoderBrutoSmooth) * scale
	return result
end

function Stats.CalcularDerivados(values: {[string]: number}, player: Player, context: {[string]: any}?)
	context = context or {}
	callHooks("AntesDerivados", player, values, context)
	local strength, agility = math.max(0, values.Forca or 0), math.max(0, values.Agilidade or 0)
	local vitality, energy = math.max(0, values.Vitalidade or 0), math.max(0, values.Energia or 0)
	local luck, power = math.max(0, values.Sorte or 0), math.max(.001, values.PoderBruto or 1)
	local health = vitality * Factors.VidaPerVitalidade + strength * Factors.VidaPerForca + power * Factors.VidaPerPoderBruto
	local stamina = energy * Factors.EnergyPerEnergia + agility * Factors.EnergyPerAgilidade + power * Factors.EnergyPerPoderBruto
	local walk = modifiers(player, "VelocidadeWalk", Movement.WalkBase + agility * Movement.WalkAgilidade)
	walk = math.clamp(walk, Movement.VelocidadeMin, Movement.VelocidadeMax)
	local sprint = modifiers(player, "VelocidadeSprint", walk + Movement.SprintBaseBonus + agility * Movement.SprintAgilidade)
	sprint = math.clamp(sprint, walk + 2, Movement.SprintMax)
	local result = {
		VidaMax = math.max(1, math.floor(modifiers(player, "VidaMax", health))),
		EnergiaMax = math.max(1, math.floor(modifiers(player, "EnergiaMax", stamina))),
		VelocidadeWalk = walk,
		VelocidadeSprint = sprint,
		JumpPower = math.floor(modifiers(player, "JumpPower", Movement.JumpPowerBase + vitality * Movement.JumpPowerVitalidade)),
		DanoBaseFisico = math.max(1, math.floor(modifiers(player, "DanoBaseFisico", strength ^ Factors.DanoBaseExp * power ^ Factors.DanoPoderBrutoExp))),
		DanoBaseMagico = math.max(1, math.floor(modifiers(player, "DanoBaseMagico", energy ^ Factors.MagiaBaseExp * power ^ Factors.MagiaPoderBrutoExp))),
		Defesa = math.floor(modifiers(player, "Defesa", vitality ^ Factors.DefesaVitalidadeExp + power * Factors.DefesaPoderBrutoMult)),
		CriticoChance = math.clamp(modifiers(player, "CriticoChance", Combat.CriticoChanceBase + luck * Combat.CriticoChancePerSorte), 0, 1),
		CriticoMultiplicador = math.max(1, modifiers(player, "CriticoMultiplicador", Combat.CriticoMultiplicadorBase + strength * Combat.CriticoMultiplicadorPerForca)),
		VidaRegen = modifiers(player, "VidaRegen", Regen.VidaRegenBase + vitality * Regen.VidaRegenPerVitalidade),
		EnergiaRegen = modifiers(player, "EnergiaRegen", Regen.EnergyRegenBase + energy * Regen.EnergyRegenPerEnergia),
		PoderTotal = math.floor(power * 100),
	}
	callHooks("DepoisDerivados", player, result, context)
	return result
end

function Stats.CalcularDanoFisicoBruto(values: {[string]: number}, race: {[string]: number}?, class: {[string]: number}?)
	return math.floor(math.max(0, (values.Forca or 0) ^ Factors.DanoBaseExp * math.max(.001, values.PoderBruto or 1) ^ Factors.DanoPoderBrutoExp * ((race and race.Dano) or 1) * ((class and class.Dano) or 1)))
end

function Stats.CalcularDanoMagicoBruto(values: {[string]: number}, race: {[string]: number}?, class: {[string]: number}?)
	return math.floor(math.max(0, (values.Energia or 0) ^ Factors.MagiaBaseExp * math.max(.001, values.PoderBruto or 1) ^ Factors.MagiaPoderBrutoExp * ((race and race.DanoMagico) or 1) * ((class and class.DanoMagico) or 1)))
end

function Stats.XPnecessario(level: number): number
	level = math.max(1, math.floor(tonumber(level) or 1))
	if level >= Progression.HardCapLevel then return math.huge end
	local multiplier = 1
	-- TierMultiplier é um dicionário, portanto ipairs não percorria nenhum tier.
	for _, key in ipairs({"Tier1", "Tier2", "Tier3"}) do
		local tier = Progression.TierMultiplier[key]
		if tier and level <= tier.MaxLevel then multiplier = tier.Multiplier; break end
	end
	return math.max(1, math.floor(Progression.BaseXP * level ^ Progression.GrowthRate * multiplier))
end

function Stats.CalcularSubidas(currentLevel: number, currentXP: number): (number, number)
	local level = math.clamp(math.floor(tonumber(currentLevel) or 1), 1, Progression.HardCapLevel)
	local xp = tonumber(currentXP) or 0
	if xp ~= xp or xp == math.huge or xp == -math.huge then xp = 0 end
	xp = math.max(0, xp)
	while level < Progression.HardCapLevel do
		local needed = Stats.XPnecessario(level)
		if xp < needed then break end
		xp -= needed
		level += 1
	end
	local remaining = if level >= Progression.HardCapLevel then 0 else math.floor(xp)
	return level, remaining
end

function Stats.LevelComLimitador(level: number, percent: number?)
	return math.max(1, math.floor(math.max(1, tonumber(level) or 1) * math.clamp(tonumber(percent) or 100, 1, 100) / 100))
end

function Stats.ValidarLimitador(value: any): (boolean, string?)
	if type(value) ~= "number" or value ~= value then return false, "O limitador deve ser um número." end
	if value < 1 or value > 100 then return false, "O limitador deve estar entre 1% e 100%." end
	return true, nil
end

function Stats.AddAttributeSafe(player: Player, name: string, value: number)
	if not player or type(name) ~= "string" or type(value) ~= "number" or value ~= value or value == 0 then return end
	local current = player:GetAttribute(name)
	if current == nil or type(current) == "number" then player:SetAttribute(name, (current or 0) + value) end
end

return Stats

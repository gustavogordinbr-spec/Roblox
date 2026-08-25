--!strict
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local progression = GameConfig.Progression
local XPConfig = {
	BaseXP = progression.BaseXP or 120,
	GrowthRate = progression.GrowthRate or 1.22,
	SoftCap = progression.SoftCapLevel or 50,
	HardCap = math.min(GameConfig.MaxLevel or 300, progression.HardCapLevel or 300),
	TierMultiplier = {Early = 1.0, Mid = 1.15, Late = 1.35},
}

function XPConfig.XPParaLevel(level: any): number
	level = if type(level) == "number" and level == level then math.max(1, math.floor(level)) else 1
	if level >= XPConfig.HardCap then return math.huge end
	local multiplier = if level <= 20 then XPConfig.TierMultiplier.Early elseif level <= XPConfig.SoftCap then XPConfig.TierMultiplier.Mid else XPConfig.TierMultiplier.Late
	return math.max(1, math.floor(XPConfig.BaseXP * level ^ XPConfig.GrowthRate * multiplier))
end

function XPConfig.CalcularSubidas(levelAtual: any, xpAtual: any): (number, number)
	local level = math.clamp(math.floor(tonumber(levelAtual) or 1), 1, XPConfig.HardCap)
	local xp = tonumber(xpAtual) or 0
	if xp ~= xp or xp == math.huge or xp == -math.huge then xp = 0 end
	xp = math.max(0, xp)
	while level < XPConfig.HardCap do
		local required = XPConfig.XPParaLevel(level)
		if xp < required then break end
		xp -= required
		level += 1
	end
	if level >= XPConfig.HardCap then xp = 0 end
	return level, math.floor(xp)
end

function XPConfig.LevelComLimitador(levelReal: any, limitPercent: any): number
	local percent = math.clamp(tonumber(limitPercent) or 100, 1, 100)
	return math.max(1, math.floor((tonumber(levelReal) or 1) * percent / 100))
end

function XPConfig.ValidarLimitador(valor: any): (boolean, string?)
	if type(valor) ~= "number" or valor ~= valor then return false, "O limitador deve ser um número." end
	if valor < 1 or valor > 100 then return false, "O limitador deve estar entre 1% e 100%." end
	return true, nil
end

return XPConfig

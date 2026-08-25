--!strict
local Players = game:GetService("Players")
local TICK, REGEN_DELAY = .25, 1.35
local lastUse, observed = {}, {}

_G.RegistrarUsoEnergia = function(player: Player) lastUse[player] = os.clock() end

Players.PlayerRemoving:Connect(function(player) lastUse[player], observed[player] = nil, nil end)

while task.wait(TICK) do
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local energy, maximum = player:GetAttribute("Energia"), player:GetAttribute("EnergiaMax")
		if type(energy) ~= "number" or type(maximum) ~= "number" or maximum <= 0 then continue end
		local previous = observed[player]
		if previous and energy < previous - .5 then lastUse[player] = now end
		observed[player] = energy
		if player:GetAttribute("Sprinting") or now - (lastUse[player] or 0) < REGEN_DELAY or energy >= maximum then continue end
		local rate = math.max(2, tonumber(player:GetAttribute("EnergiaRegen")) or 4)
		local restored = math.min(maximum, energy + rate * TICK)
		if restored ~= energy then player:SetAttribute("Energia", restored); observed[player] = restored end
	end
end

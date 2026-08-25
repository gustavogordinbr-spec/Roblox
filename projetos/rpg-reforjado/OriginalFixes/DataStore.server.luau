--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local STORE_NAME, VERSION, RETRIES, AUTOSAVE_INTERVAL = "RPG_PLAYER_DATA", 4, 4, 75
local cache, loadedSafely, saving = {}, {}, {}

local template = {
	Meta = {Version = VERSION, FirstJoin = 0, LastSave = 0},
	Identidade = {Raca = "Humano", Classe = "Noone"},
	Progressao = {Level = 1, XP = 0, AttributePoints = 0, PlayerRank = "D", AllocatedStats = {}},
	Moedas = {Dinheiro = 0},
	Config = {VelocidadeMax = 16},
	Flags = {LimitadorAtivo = false, CompletedQuests = {}},
}

local function deepCopy(value: any, seen: {[any]: any}?): any
	if type(value) ~= "table" then return value end
	local visited = seen or {}
	if visited[value] then return visited[value] end
	local result = {}
	visited[value] = result
	for key, item in pairs(value) do result[deepCopy(key, visited)] = deepCopy(item, visited) end
	return result
end

local function reconcile(defaults: {[any]: any}, data: {[any]: any})
	for key, default in pairs(defaults) do
		if data[key] == nil or type(data[key]) ~= type(default) then
			data[key] = deepCopy(default)
		elseif type(default) == "table" then
			reconcile(default, data[key])
		end
	end
end

local function retry(action: () -> any): (boolean, any)
	local last
	for attempt = 1, RETRIES do
		local ok, result = pcall(action)
		if ok then return true, result end
		last = result
		if attempt < RETRIES then task.wait(math.min(2 ^ (attempt - 1), 8)) end
	end
	return false, last
end

local function setIfValid(player: Player, name: string, value: any, fallback: any)
	if type(value) ~= type(fallback) then value = fallback end
	player:SetAttribute(name, value)
end

local function load(player: Player)
	if cache[player] then return end
	local store = DataStoreService:GetDataStore(STORE_NAME)
	local ok, saved = retry(function() return store:GetAsync("Player_" .. player.UserId) end)
	local data = if ok and type(saved) == "table" then deepCopy(saved) else deepCopy(template)
	reconcile(template, data)
	data.Meta.Version = VERSION
	if data.Meta.FirstJoin == 0 then data.Meta.FirstJoin = os.time() end
	cache[player] = data
	loadedSafely[player] = ok
	if not ok then warn("[RPG/Data] Carregamento indisponível; salvamento protegido para", player.Name, saved) end
	setIfValid(player, "Raca", data.Identidade.Raca, "Humano")
	setIfValid(player, "Classe", data.Identidade.Classe, "Noone")
	setIfValid(player, "Level", math.max(1, tonumber(data.Progressao.Level) or 1), 1)
	setIfValid(player, "XP", math.max(0, tonumber(data.Progressao.XP) or 0), 0)
	setIfValid(player, "AttributePoints", math.max(0, tonumber(data.Progressao.AttributePoints) or 0), 0)
	setIfValid(player, "PlayerRank", data.Progressao.PlayerRank, "D")
	setIfValid(player, "Dinheiro", math.max(0, tonumber(data.Moedas.Dinheiro) or 0), 0)
	setIfValid(player, "VelocidadeMax", tonumber(data.Config.VelocidadeMax) or 16, 16)
	setIfValid(player, "LimitadorAtivo", data.Flags.LimitadorAtivo, false)
	for stat, value in pairs(data.Progressao.AllocatedStats) do
		if type(stat) == "string" and type(value) == "number" then player:SetAttribute("Allocated_" .. stat, math.clamp(value, 0, 250)) end
	end
	for questId, completed in pairs(data.Flags.CompletedQuests) do
		if completed == true and type(questId) == "string" then player:SetAttribute(questId .. "_AlreadyCompleted", true) end
	end
	player:SetAttribute("RPGDataLoaded", true)
end

local function snapshot(player: Player)
	local data = cache[player]
	if not data then return nil end
	data.Meta.Version, data.Meta.LastSave = VERSION, os.time()
	data.Identidade.Raca = player:GetAttribute("Raca") or "Humano"
	data.Identidade.Classe = player:GetAttribute("Classe") or "Noone"
	data.Progressao.Level = math.max(1, player:GetAttribute("Level") or 1)
	data.Progressao.XP = math.max(0, player:GetAttribute("XP") or 0)
	data.Progressao.AttributePoints = math.max(0, player:GetAttribute("AttributePoints") or 0)
	data.Progressao.PlayerRank = player:GetAttribute("PlayerRank") or "D"
	data.Moedas.Dinheiro = math.max(0, player:GetAttribute("Dinheiro") or 0)
	data.Config.VelocidadeMax = player:GetAttribute("VelocidadeMax") or 16
	data.Flags.LimitadorAtivo = player:GetAttribute("LimitadorAtivo") == true
	for _, stat in ipairs({"Forca", "Agilidade", "Vitalidade", "Energia", "Sorte"}) do
		data.Progressao.AllocatedStats[stat] = math.max(0, player:GetAttribute("Allocated_" .. stat) or 0)
	end
	for index = 1, 16 do
		local id = string.format("quest_%03d", index)
		if player:GetAttribute(id .. "_AlreadyCompleted") then data.Flags.CompletedQuests[id] = true end
	end
	return deepCopy(data)
end

local function save(player: Player): boolean
	if saving[player] or not cache[player] then return false end
	if not loadedSafely[player] then
		if not RunService:IsStudio() then warn("[RPG/Data] Perfil não salvo para evitar sobrescrever dados existentes:", player.Name) end
		return false
	end
	local data = snapshot(player)
	if not data then return false end
	saving[player] = true
	local store = DataStoreService:GetDataStore(STORE_NAME)
	local ok, err = retry(function()
		return store:UpdateAsync("Player_" .. player.UserId, function(previous)
			if type(previous) == "table" and type(previous.Meta) == "table" and (tonumber(previous.Meta.LastSave) or 0) > data.Meta.LastSave then return previous end
			return data
		end)
	end)
	saving[player] = nil
	if not ok then warn("[RPG/Data] Falha ao salvar", player.Name, err) end
	return ok
end

Players.PlayerAdded:Connect(load)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end
Players.PlayerRemoving:Connect(function(player)
	save(player)
	cache[player], loadedSafely[player], saving[player] = nil, nil, nil
end)

task.spawn(function()
	while task.wait(AUTOSAVE_INTERVAL) do
		for _, player in ipairs(Players:GetPlayers()) do task.spawn(save, player) end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do task.spawn(save, player) end
	local deadline = os.clock() + 20
	while next(saving) and os.clock() < deadline do task.wait(0.15) end
end)

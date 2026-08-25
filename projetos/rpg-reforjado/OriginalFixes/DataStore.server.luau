--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local STORE_NAME, VERSION, RETRIES, AUTOSAVE_INTERVAL = "RPG_PLAYER_DATA", 5, 4, 60
local cache, loadedSafely, saving = {}, {}, {}

local template = {
	Meta = {Version = VERSION, FirstJoin = 0, LastSave = 0},
	Identidade = {
		Raca = "Unassigned", Classe = "Noone", RaceAssigned = false,
		Appearance = {HairStyle = "Original", HairColor = "Castanho", EyeColor = "Castanho", SkinTone = "Original", Outfit = "Aventureiro", ShowAura = true, ShowRaceCosmetics = true, ShowWings = true, ShowHorns = true},
	},
	Progressao = {Level = 1, XP = 0, PlayerRank = "D"},
	Moedas = {Dinheiro = 0},
	Config = {VelocidadeMax = 16},
	Flags = {LimitadorAtivo = false, CompletedQuests = {}, ActiveQuestId = "", ActiveQuestProgress = 0, RaceSpins = 3, RacePityEpic = 0, RacePityLegendary = 0, TotalRaceSpins = 0, LastRaceGift = 0, CustomizationComplete = false},
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
	setIfValid(player, "Raca", data.Identidade.Raca, "Unassigned")
	setIfValid(player, "Classe", data.Identidade.Classe, "Noone")
	setIfValid(player, "RaceAssigned", data.Identidade.RaceAssigned, false)
	setIfValid(player, "Level", math.max(1, tonumber(data.Progressao.Level) or 1), 1)
	setIfValid(player, "XP", math.max(0, tonumber(data.Progressao.XP) or 0), 0)
	setIfValid(player, "PlayerRank", data.Progressao.PlayerRank, "D")
	setIfValid(player, "Dinheiro", math.max(0, tonumber(data.Moedas.Dinheiro) or 0), 0)
	setIfValid(player, "VelocidadeMax", tonumber(data.Config.VelocidadeMax) or 16, 16)
	setIfValid(player, "LimitadorAtivo", data.Flags.LimitadorAtivo, false)
	setIfValid(player, "RaceSpins", math.max(0, tonumber(data.Flags.RaceSpins) or 0), 0)
	setIfValid(player, "RacePityEpic", math.max(0, tonumber(data.Flags.RacePityEpic) or 0), 0)
	setIfValid(player, "RacePityLegendary", math.max(0, tonumber(data.Flags.RacePityLegendary) or 0), 0)
	setIfValid(player, "TotalRaceSpins", math.max(0, tonumber(data.Flags.TotalRaceSpins) or 0), 0)
	setIfValid(player, "LastRaceGift", math.max(0, tonumber(data.Flags.LastRaceGift) or 0), 0)
	setIfValid(player, "CustomizationComplete", data.Flags.CustomizationComplete, false)
	for name, default in pairs(template.Identidade.Appearance) do
		local value = data.Identidade.Appearance[name]
		setIfValid(player, "Appearance_" .. name, value, default)
	end
	if type(data.Flags.ActiveQuestId) == "string" and data.Flags.ActiveQuestId ~= "" then
		player:SetAttribute("RestoredQuestId", data.Flags.ActiveQuestId)
		player:SetAttribute("RestoredQuestProgress", math.max(0, tonumber(data.Flags.ActiveQuestProgress) or 0))
	end
	for questId, completed in pairs(data.Flags.CompletedQuests) do
		if completed == true and type(questId) == "string" then
			player:SetAttribute(questId .. "_AlreadyCompleted", true)
			player:SetAttribute(string.gsub(questId, "^quest_", "Quest_") .. "_Completed", true)
		end
	end
	player:SetAttribute("RPGDataLoaded", true)
end

local function snapshot(player: Player)
	local data = cache[player]
	if not data then return nil end
	data.Meta.Version, data.Meta.LastSave = VERSION, os.time()
	data.Identidade.Raca = player:GetAttribute("Raca") or "Unassigned"
	data.Identidade.Classe = player:GetAttribute("Classe") or "Noone"
	data.Identidade.RaceAssigned = player:GetAttribute("RaceAssigned") == true
	for name, default in pairs(template.Identidade.Appearance) do
		local value = player:GetAttribute("Appearance_" .. name)
		data.Identidade.Appearance[name] = if type(value) == type(default) then value else default
	end
	data.Progressao.Level = math.max(1, player:GetAttribute("Level") or 1)
	data.Progressao.XP = math.max(0, player:GetAttribute("XP") or 0)
	data.Progressao.PlayerRank = player:GetAttribute("PlayerRank") or "D"
	data.Moedas.Dinheiro = math.max(0, player:GetAttribute("Dinheiro") or 0)
	data.Config.VelocidadeMax = player:GetAttribute("VelocidadeMax") or 16
	data.Flags.LimitadorAtivo = player:GetAttribute("LimitadorAtivo") == true
	data.Flags.ActiveQuestId = player:GetAttribute("ActiveQuestId") or ""
	data.Flags.ActiveQuestProgress = math.max(0, tonumber(player:GetAttribute("ActiveQuestProgress")) or 0)
	data.Flags.RaceSpins = math.max(0, tonumber(player:GetAttribute("RaceSpins")) or 0)
	data.Flags.RacePityEpic = math.max(0, tonumber(player:GetAttribute("RacePityEpic")) or 0)
	data.Flags.RacePityLegendary = math.max(0, tonumber(player:GetAttribute("RacePityLegendary")) or 0)
	data.Flags.TotalRaceSpins = math.max(0, tonumber(player:GetAttribute("TotalRaceSpins")) or 0)
	data.Flags.LastRaceGift = math.max(0, tonumber(player:GetAttribute("LastRaceGift")) or 0)
	data.Flags.CustomizationComplete = player:GetAttribute("CustomizationComplete") == true
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

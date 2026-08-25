--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local enhancements = ReplicatedStorage:WaitForChild("RPGEnhancements")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("CustomizationAction")
local feedback = remotes:WaitForChild("CustomizationFeedback")
local Races = require(ReplicatedStorage.Modules:WaitForChild("Racas"))
local Appearance = require(enhancements:WaitForChild("CharacterAppearance"))
local settings = require(enhancements:WaitForChild("EnhancementConfig")).Customization
local random = Random.new()
local lastRoll, lastUpdate, watchers, scheduled = {}, {}, {}, {}

local function weightedRace(epicPity: number, legendaryPity: number): (string, any)
	local pool, total = {}, 0
	for _, rarity in ipairs(Races.RarityOrder) do
		local allowed = if legendaryPity >= settings.GuaranteedLegendaryAt - 1
			then rarity == "Lendaria" or rarity == "Secreta"
			elseif epicPity >= settings.GuaranteedEpicAt - 1
			then rarity == "Epica" or rarity == "Lendaria" or rarity == "Secreta"
			else true
		if allowed then total += Races.RarityWeights[rarity]; table.insert(pool, {Name = rarity, Ceiling = total}) end
	end
	local chosen, roll = pool[#pool].Name, random:NextNumber(0, total)
	for _, entry in ipairs(pool) do if roll < entry.Ceiling then chosen = entry.Name; break end end
	local options = Races.GetRacesByRarity(chosen)
	local name = options[random:NextInteger(1, #options)]
	return name, Races.Get(name)
end

local function piece(folder: Folder, body: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, shape: string?, material: Enum.Material?): BasePart
	local item = Instance.new(if shape == "Wedge" then "WedgePart" else "Part")
	item.Name, item.Size, item.Color, item.Material = name, size, color, material or Enum.Material.SmoothPlastic
	item.CanCollide, item.CanTouch, item.CanQuery, item.Massless, item.CastShadow = false, false, false, true, false
	if item:IsA("Part") and shape == "Ball" then item.Shape = Enum.PartType.Ball end
	item.CFrame, item.Parent = body.CFrame * offset, folder
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = body, item, item
	return item
end

local function horns(folder: Folder, head: BasePart, color: Color3, height: number)
	for _, side in ipairs({-1, 1}) do
		piece(folder, head, "Chifre", Vector3.new(.2, height, .24), CFrame.new(side * .38, .57 + height * .28, -.04) * CFrame.Angles(0, 0, -side * .27), color, "Wedge")
	end
end

local function ears(folder: Folder, head: BasePart, color: Color3, feral: boolean)
	for _, side in ipairs({-1, 1}) do
		local position = if feral then CFrame.new(side * .34, .71, -.03) * CFrame.Angles(0, 0, -side * .22) else CFrame.new(side * .57, .04, .04) * CFrame.Angles(0, 0, side * .8)
		piece(folder, head, if feral then "OrelhaFeral" else "OrelhaElfica", if feral then Vector3.new(.32, .38, .2) else Vector3.new(.17, .42, .2), position, color, "Wedge")
	end
end

local function wings(folder: Folder, torso: BasePart, color: Color3, ethereal: boolean)
	for _, side in ipairs({-1, 1}) do
		for index = 1, 2 do
			local size = Vector3.new(.85 - index * .12, 1.1 - index * .18, .13)
			local offset = CFrame.new(side * (.75 + index * .29), .18 - index * .12, .62 + index * .05) * CFrame.Angles(.08, side * .23, side * (.45 + index * .13))
			local wing = piece(folder, torso, "Asa", size, offset, color, "Wedge", if ethereal then Enum.Material.Neon else Enum.Material.Fabric)
			wing.Transparency = if ethereal then .24 else .07
		end
	end
end

local function tail(folder: Folder, torso: BasePart, color: Color3)
	for index = 1, 4 do
		local width = .25 - index * .026
		piece(folder, torso, "Cauda", Vector3.new(width, .42, width), CFrame.new(0, -.64 - index * .18, .53 + index * .16) * CFrame.Angles(.42, 0, 0), color)
	end
end

local function halo(folder: Folder, head: BasePart, color: Color3)
	for index = 1, 10 do
		local angle = index * math.pi * 2 / 10
		piece(folder, head, "Aureola", Vector3.new(.1, .1, .33), CFrame.new(math.cos(angle) * .58, 1.05, math.sin(angle) * .58) * CFrame.Angles(0, -angle, 0), color, nil, Enum.Material.Neon)
	end
end

local bodyNames = {Head = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true, Torso = true, UpperTorso = true, LowerTorso = true, LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true, LeftHand = true, RightHand = true, LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true, LeftFoot = true, RightFoot = true}

local function decorate(player: Player, character: Model)
	if not character.Parent then return end
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local lower = character:FindFirstChild("LowerTorso") or torso
	if not head or not torso or not lower or not head:IsA("BasePart") or not torso:IsA("BasePart") or not lower:IsA("BasePart") then return end
	local old = character:FindFirstChild("RPGCosmetics")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "RPGCosmetics", character
	local raceName = player:GetAttribute("Raca") or "Humano"
	local accent = Appearance.RaceAccents[raceName] or Appearance.RaceAccents.Humano
	local hairColor = Appearance.HairColors[player:GetAttribute("Appearance_HairColor")] or Appearance.HairColors.Castanho
	local eyeColor = Appearance.EyeColors[player:GetAttribute("Appearance_EyeColor")] or Appearance.EyeColors.Castanho
	local style = player:GetAttribute("Appearance_HairStyle") or "Original"
	local toneName = player:GetAttribute("Appearance_SkinTone") or "Original"
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and bodyNames[part.Name] then
			if part:GetAttribute("RPGSkinOriginal") == nil then part:SetAttribute("RPGSkinOriginal", part.Color) end
			part.Color = if toneName == "Original" then part:GetAttribute("RPGSkinOriginal") else Appearance.SkinTones[toneName] or part.Color
		elseif part:IsA("Accessory") and (part.AccessoryType == Enum.AccessoryType.Hair or string.find(string.lower(part.Name), "hair", 1, true)) then
			local handle = part:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				if handle:GetAttribute("RPGSavedTransparency") == nil then handle:SetAttribute("RPGSavedTransparency", handle.Transparency) end
				handle.Transparency = if style == "Original" then handle:GetAttribute("RPGSavedTransparency") else 1
			end
		end
	end
	if style ~= "Original" then
		piece(folder, head, "Cabelo", Vector3.new(1.08, .49, 1.08), CFrame.new(0, .39, 0), hairColor, "Ball")
		if style == "Longo" or style == "Ondulado" then piece(folder, head, "CabeloLongo", Vector3.new(.95, if style == "Longo" then 1.2 else .72, .3), CFrame.new(0, if style == "Longo" then -.08 else .04, .43), hairColor) end
		if style == "Moicano" then piece(folder, head, "Moicano", Vector3.new(.19, .39, .9), CFrame.new(0, .78, 0), hairColor, "Wedge") end
		if style == "Preso" then piece(folder, head, "RaboDeCavalo", Vector3.new(.34, .52, .34), CFrame.new(0, .25, .61) * CFrame.Angles(.35, 0, 0), hairColor, "Ball") end
		piece(folder, head, "Franja", Vector3.new(.93, .2, .19), CFrame.new(0, .35, -.46), hairColor)
	end
	for _, side in ipairs({-1, 1}) do piece(folder, head, "OlhoArcano", Vector3.new(.075, .075, .035), CFrame.new(side * .19, .04, -.515), eyeColor, "Ball", Enum.Material.Neon) end
	local outfit = Appearance.Outfits[player:GetAttribute("Appearance_Outfit")] or Appearance.Outfits.Aventureiro
	piece(folder, torso, "Manto", Vector3.new(1.12, 1.46, .09), CFrame.new(0, -.22, .56), outfit.Primary, nil, Enum.Material.Fabric)
	piece(folder, torso, "Fivela", Vector3.new(.22, .2, .09), CFrame.new(0, -.57, -.56), outfit.Secondary, nil, Enum.Material.Metal)

	if player:GetAttribute("Appearance_ShowRaceCosmetics") ~= false then
		if raceName == "Humano" then
			piece(folder, torso, "Medalhao", Vector3.new(.2, .2, .1), CFrame.new(0, .38, -.56), accent, "Ball", Enum.Material.Metal)
		elseif raceName == "Elfyn" or raceName == "Sylvani" then
			ears(folder, head, head.Color, false)
			for _, side in ipairs({-1, 1}) do piece(folder, head, "Folha", Vector3.new(.15, .32, .11), CFrame.new(side * .35, .59, -.23) * CFrame.Angles(0, 0, side * .5), accent, "Wedge") end
		elseif raceName == "Durgan" then
			for index = -1, 1 do piece(folder, head, "Barba", Vector3.new(.2, .44, .18), CFrame.new(index * .2, -.49 - math.abs(index) * .03, -.43), hairColor, "Ball") end
			for _, side in ipairs({-1, 1}) do piece(folder, torso, "Runa", Vector3.new(.22, .13, .09), CFrame.new(side * .43, .45, -.56), accent, nil, Enum.Material.Neon) end
		elseif raceName == "Feralkin" then ears(folder, head, hairColor, true); tail(folder, lower, hairColor)
		elseif raceName == "Stoneborn" then
			for _, side in ipairs({-1, 1}) do piece(folder, torso, "Cristal", Vector3.new(.38, .65, .32), CFrame.new(side * .72, .34, .13) * CFrame.Angles(0, 0, side * .42), accent, "Wedge", Enum.Material.Slate) end
		elseif raceName == "Nightborn" then if player:GetAttribute("Appearance_ShowHorns") ~= false then horns(folder, head, accent, .56) end
		elseif raceName == "Tidecaller" then for _, side in ipairs({-1, 1}) do piece(folder, head, "Barbatana", Vector3.new(.15, .43, .35), CFrame.new(side * .56, .03, .05) * CFrame.Angles(0, 0, side * .56), accent, "Wedge") end
		elseif raceName == "Draconian" then
			if player:GetAttribute("Appearance_ShowHorns") ~= false then horns(folder, head, accent, .69) end
			tail(folder, lower, accent)
			if player:GetAttribute("Appearance_ShowWings") ~= false then wings(folder, torso, accent, false) end
		elseif raceName == "Celestial" then halo(folder, head, accent); if player:GetAttribute("Appearance_ShowWings") ~= false then wings(folder, torso, Color3.fromRGB(237, 228, 190), true) end
		elseif raceName == "Abyssal" then
			if player:GetAttribute("Appearance_ShowHorns") ~= false then horns(folder, head, accent, .78) end
			tail(folder, lower, accent)
			if player:GetAttribute("Appearance_ShowWings") ~= false then wings(folder, torso, accent:Lerp(Color3.new(0, 0, 0), .33), false) end
		elseif raceName == "Voidborn" then
			halo(folder, head, accent)
			if player:GetAttribute("Appearance_ShowHorns") ~= false then horns(folder, head, accent:Lerp(Color3.new(0, 0, 0), .3), .7) end
			for index = 1, 3 do piece(folder, torso, "FragmentoVazio", Vector3.new(.21, .37, .17), CFrame.new((index - 2) * .48, .67 + index * .12, .65), accent, "Wedge", Enum.Material.Neon) end
		end
	end
	if player:GetAttribute("Appearance_ShowAura") ~= false and raceName ~= "Humano" then
		local carrier = piece(folder, torso, "AuraRacial", Vector3.new(.1, .1, .1), CFrame.new(0, -.45, 0), accent)
		carrier.Transparency = 1
		local attachment = Instance.new("Attachment", carrier)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name, emitter.Color, emitter.LightEmission = "ParticulasDaLinhagem", ColorSequence.new(accent), .48
		emitter.Rate, emitter.Lifetime, emitter.Speed, emitter.SpreadAngle = 5, NumberRange.new(.65, 1.1), NumberRange.new(.3, .8), Vector2.new(35, 35)
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .1), NumberSequenceKeypoint.new(.5, .17), NumberSequenceKeypoint.new(1, 0)})
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .3), NumberSequenceKeypoint.new(1, 1)})
		emitter.Texture, emitter.Parent = "rbxasset://textures/particles/sparkles_main.dds", attachment
	end
end

local function schedule(player: Player)
	if scheduled[player] then return end
	scheduled[player] = true
	task.delay(.08, function()
		scheduled[player] = nil
		if player.Parent and player.Character then
			local ok, message = pcall(decorate, player, player.Character)
			if not ok then warn("[RPG/Visual]", player.Name, message) end
		end
	end)
end

local function roll(player: Player)
	local now = os.clock()
	if now - (lastRoll[player] or 0) < settings.RaceSpinCooldown then return end
	local spins = math.max(0, tonumber(player:GetAttribute("RaceSpins")) or 0)
	local paid = spins == 0
	if paid and (tonumber(player:GetAttribute("Dinheiro")) or 0) < settings.RaceSpinCost then
		feedback:FireClient(player, {Type = "Error", Message = "São necessárias " .. settings.RaceSpinCost .. " moedas do jogo."})
		return
	end
	lastRoll[player] = now
	if paid then player:SetAttribute("Dinheiro", player:GetAttribute("Dinheiro") - settings.RaceSpinCost) else player:SetAttribute("RaceSpins", spins - 1) end
	local epic = math.max(0, tonumber(player:GetAttribute("RacePityEpic")) or 0)
	local legendary = math.max(0, tonumber(player:GetAttribute("RacePityLegendary")) or 0)
	local race, definition = weightedRace(epic, legendary)
	local rarity = definition.Raridade
	player:SetAttribute("RacePityEpic", if rarity == "Epica" or rarity == "Lendaria" or rarity == "Secreta" then 0 else epic + 1)
	player:SetAttribute("RacePityLegendary", if rarity == "Lendaria" or rarity == "Secreta" then 0 else legendary + 1)
	player:SetAttribute("TotalRaceSpins", (tonumber(player:GetAttribute("TotalRaceSpins")) or 0) + 1)
	player:SetAttribute("Raca", race)
	player:SetAttribute("RaceAssigned", true)
	feedback:FireClient(player, {Type = "RaceRolled", Race = race, Rarity = rarity, Passive = definition.Passiva, FreeSpins = player:GetAttribute("RaceSpins"), Paid = paid})
	schedule(player)
end

action.OnServerEvent:Connect(function(player: Player, kind: any, payload: any)
	if not player:GetAttribute("RPGDataLoaded") or type(kind) ~= "string" then return end
	if kind == "RollRace" then roll(player); return end
	if kind == "FinishCreation" then player:SetAttribute("CustomizationComplete", true); return end
	if kind ~= "UpdateAppearance" or type(payload) ~= "table" then return end
	local now = os.clock()
	if now - (lastUpdate[player] or 0) < settings.UpdateCooldown then return end
	local option, value = payload.Option, payload.Value
	if type(option) ~= "string" or not Appearance.IsValid(option, value) then return end
	lastUpdate[player] = now
	player:SetAttribute("Appearance_" .. option, value)
	schedule(player)
end)

local function setup(player: Player)
	if watchers[player] then return end
	if not player:GetAttribute("RPGDataLoaded") then
		local connection
		connection = player:GetAttributeChangedSignal("RPGDataLoaded"):Connect(function()
			if player:GetAttribute("RPGDataLoaded") then connection:Disconnect(); setup(player) end
		end)
		return
	end
	watchers[player] = {}
	local existing = player:GetAttribute("Raca")
	if not player:GetAttribute("RaceAssigned") then
		local race, definition
		if type(existing) == "string" and existing ~= "Humano" and Races.Get(existing) then race, definition = existing, Races.Get(existing) else race, definition = weightedRace(0, 0) end
		player:SetAttribute("Raca", race)
		player:SetAttribute("RaceAssigned", true)
		feedback:FireClient(player, {Type = "BirthRace", Race = race, Rarity = definition.Raridade, Passive = definition.Passiva})
	end
	local lastGift, today = tonumber(player:GetAttribute("LastRaceGift")) or 0, os.time()
	if lastGift == 0 then player:SetAttribute("LastRaceGift", today)
	elseif today - lastGift >= 86400 then
		local days = math.clamp(math.floor((today - lastGift) / 86400), 1, 3)
		player:SetAttribute("RaceSpins", math.min(settings.MaximumFreeSpins, (tonumber(player:GetAttribute("RaceSpins")) or 0) + days * settings.DailyRaceSpins))
		player:SetAttribute("LastRaceGift", today)
	end
	table.insert(watchers[player], player.CharacterAdded:Connect(function(character) character:WaitForChild("Humanoid", 10); task.wait(.35); schedule(player) end))
	table.insert(watchers[player], player:GetAttributeChangedSignal("Raca"):Connect(function()
		player:SetAttribute("XPBonus", if player:GetAttribute("Raca") == "Humano" then 1.06 else 1)
		schedule(player)
	end))
	player:SetAttribute("XPBonus", if player:GetAttribute("Raca") == "Humano" then 1.06 else 1)
	if player.Character then task.defer(schedule, player) end
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do task.defer(setup, player) end
Players.PlayerRemoving:Connect(function(player)
	for _, connection in ipairs(watchers[player] or {}) do connection:Disconnect() end
	watchers[player], scheduled[player], lastRoll[player], lastUpdate[player] = nil, nil, nil, nil
end)

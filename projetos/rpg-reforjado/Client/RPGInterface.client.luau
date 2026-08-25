--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local action = remotes:WaitForChild("RPGAction")
local customize = remotes:WaitForChild("CustomizationAction")
local customizationFeedback = remotes:WaitForChild("CustomizationFeedback")
local questsRemote = remotes:WaitForChild("StartQuest")
local enhancements = ReplicatedStorage:WaitForChild("RPGEnhancements")
local Classes = require(ReplicatedStorage.Modules:WaitForChild("Classes"))
local Races = require(ReplicatedStorage.Modules:WaitForChild("Racas"))
local Quests = require(ReplicatedStorage.Modules:WaitForChild("QuestService"))
local Appearance = require(enhancements:WaitForChild("CharacterAppearance"))
local settings = require(enhancements:WaitForChild("EnhancementConfig")).Customization
local ink = {night = Color3.fromRGB(31, 24, 19), wood = Color3.fromRGB(63, 46, 33), panel = Color3.fromRGB(77, 57, 41), paper = Color3.fromRGB(224, 204, 165), faded = Color3.fromRGB(165, 144, 112), gold = Color3.fromRGB(200, 160, 89), ivory = Color3.fromRGB(242, 223, 183), rust = Color3.fromRGB(143, 66, 50), moss = Color3.fromRGB(88, 128, 86), blue = Color3.fromRGB(93, 125, 150), shadow = Color3.fromRGB(48, 35, 27)}

local legacy = playerGui:FindFirstChild("RPGEnhancedInterface")
if legacy then legacy:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "MedievalCharacterCodex", false, false, 18
gui.ZIndexBehavior, gui.Parent = Enum.ZIndexBehavior.Sibling, playerGui

local function create(className: string, properties: {[string]: any}, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in pairs(properties) do instance[key] = value end
	instance.Parent = parent
	return instance
end

local function edge(parent: Instance, radius: number?, border: Color3?)
	create("UICorner", {CornerRadius = UDim.new(0, radius or 3)}, parent)
	if border then create("UIStroke", {Color = border, Transparency = .18, Thickness = 1.15}, parent) end
end

local function text(parent: Instance, value: string, size: UDim2, position: UDim2, fontSize: number, color: Color3?, centered: boolean?): TextLabel
	return create("TextLabel", {BackgroundTransparency = 1, Size = size, Position = position, Text = value, Font = Enum.Font.Antique, TextSize = fontSize, TextColor3 = color or ink.ivory, TextXAlignment = if centered then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, parent)
end

local function ornament(parent: Instance, position: UDim2, width: number)
	create("Frame", {BorderSizePixel = 0, BackgroundColor3 = ink.gold, BackgroundTransparency = .22, Size = UDim2.fromOffset(width, 1), Position = position}, parent)
end

local modal = create("Frame", {Name = "CodiceMedieval", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(800, 555), BackgroundColor3 = ink.night, BorderSizePixel = 0, Visible = false}, gui)
edge(modal, 5, ink.gold)
create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(74, 52, 36), Color3.fromRGB(36, 27, 22)), Rotation = 90}, modal)
local scale = create("UIScale", {Scale = 1}, modal)
local header = create("Frame", {Size = UDim2.new(1, -22, 0, 79), Position = UDim2.fromOffset(11, 7), BackgroundTransparency = 1}, modal)
local heading = text(header, "CÓDICE DO AVENTUREIRO", UDim2.new(1, -68, 0, 33), UDim2.fromOffset(14, 7), 23, ink.gold)
local subtitle = text(header, "Escreva o destino da sua linhagem.", UDim2.new(1, -65, 0, 20), UDim2.fromOffset(15, 43), 14, ink.faded)
ornament(header, UDim2.new(0, 12, 1, -5), 740)
local close = create("TextButton", {Text = "×", Font = Enum.Font.Antique, TextSize = 29, TextColor3 = ink.paper, Size = UDim2.fromOffset(35, 35), Position = UDim2.new(1, -46, 0, 15), BackgroundColor3 = ink.shadow}, header)
edge(close, 3, ink.gold)
local sidebar = create("Frame", {Size = UDim2.new(0, 166, 1, -122), Position = UDim2.fromOffset(15, 96), BackgroundColor3 = ink.shadow, BorderSizePixel = 0}, modal)
edge(sidebar, 3, ink.gold)
create("UIPadding", {PaddingTop = UDim.new(0, 9), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, sidebar)
create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)
local content = create("ScrollingFrame", {Name = "Pergaminho", Size = UDim2.new(1, -202, 1, -123), Position = UDim2.fromOffset(190, 97), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = ink.gold, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, modal)
create("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, content)
create("UIPadding", {PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 9)}, content)
text(modal, "V · APARÊNCIA       J · CONTRATOS       C · CLASSES       E · ATRIBUTOS", UDim2.new(1, -32, 0, 18), UDim2.new(0, 16, 1, -24), 10, ink.faded, true)

local openSeal = create("TextButton", {Name = "SeloDoAventureiro", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(48, 48), BackgroundColor3 = ink.rust, Text = "✠", TextSize = 28, Font = Enum.Font.Antique, TextColor3 = ink.ivory, AutoButtonColor = true}, gui)
edge(openSeal, 24, ink.gold)
local tabButtons, activeTab, previewModel, previewFrame, previewCamera, rolling = {}, "Aparência", nil, nil, nil, false

local function card(height: number): Frame
	local row = create("Frame", {Size = UDim2.new(1, -5, 0, height), BackgroundColor3 = ink.panel, BackgroundTransparency = .1, BorderSizePixel = 0}, content)
	edge(row, 3, Color3.fromRGB(140, 110, 71))
	return row
end

local function button(parent: Instance, caption: string, size: UDim2, position: UDim2, color: Color3, callback: () -> ()): TextButton
	local value = create("TextButton", {Text = caption, Font = Enum.Font.Antique, TextSize = 12, TextColor3 = ink.ivory, Size = size, Position = position, BackgroundColor3 = color, BorderSizePixel = 0, AutoButtonColor = true}, parent)
	edge(value, 3, ink.gold)
	value.Activated:Connect(callback)
	return value
end

local function clear()
	previewFrame, previewCamera, previewModel = nil, nil, nil
	for _, child in ipairs(content:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
	content.CanvasPosition = Vector2.zero
end

local function updateAppearance(option: string, value: any)
	customize:FireServer("UpdateAppearance", {Option = option, Value = value})
end

local function appearanceValue(option: string): any
	local value = player:GetAttribute("Appearance_" .. option)
	return if value == nil then Appearance.Defaults[option] else value
end

local function preview(row: Frame)
	previewFrame = create("ViewportFrame", {Size = UDim2.fromOffset(210, 185), Position = UDim2.fromOffset(11, 9), BackgroundColor3 = ink.shadow, Ambient = Color3.fromRGB(169, 150, 123), LightColor = Color3.fromRGB(255, 222, 161), LightDirection = Vector3.new(-1, -1, -1)}, row)
	edge(previewFrame, 3, ink.gold)
	previewCamera = Instance.new("Camera")
	previewCamera.FieldOfView, previewCamera.Parent, previewFrame.CurrentCamera = 33, previewFrame, previewCamera
	local world = Instance.new("WorldModel", previewFrame)
	local character = player.Character
	if character then
		local archivable = character.Archivable
		character.Archivable = true
		local ok, clone = pcall(function() return character:Clone() end)
		character.Archivable = archivable
		if ok and clone then
			for _, object in ipairs(clone:GetDescendants()) do if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ParticleEmitter") then object:Destroy() end end
			clone:PivotTo(CFrame.new())
			clone.Parent, previewModel = world, clone
			local _, size = clone:GetBoundingBox()
			local center = Vector3.new(0, math.clamp(size.Y * .24, 1, 2.6), 0)
			previewCamera.CFrame = CFrame.new(center + Vector3.new(0, .2, math.max(7.5, size.Y * 1.65)), center)
		end
	end
	local race = player:GetAttribute("Raca") or "Desconhecida"
	local definition = Races.Get(race)
	text(row, player.DisplayName, UDim2.new(1, -245, 0, 25), UDim2.fromOffset(234, 19), 20, ink.ivory)
	text(row, race .. " · " .. (if definition then definition.Raridade else ""), UDim2.new(1, -245, 0, 20), UDim2.fromOffset(235, 51), 14, Appearance.RaceAccents[race] or ink.gold)
	text(row, "NÍVEL " .. (player:GetAttribute("Level") or 1) .. "  ·  ORDEM " .. (player:GetAttribute("PlayerRank") or "D"), UDim2.new(1, -245, 0, 18), UDim2.fromOffset(235, 83), 12, ink.faded)
	text(row, "Classe: " .. (if player:GetAttribute("Classe") == "Noone" then "Aventureiro" else player:GetAttribute("Classe") or "Aventureiro"), UDim2.new(1, -245, 0, 18), UDim2.fromOffset(235, 106), 12, ink.paper)
	text(row, if definition then definition.Passiva else "Sua linhagem está sendo revelada...", UDim2.new(1, -245, 0, 18), UDim2.fromOffset(235, 131), 12, ink.gold)
	button(row, "SELAR APARÊNCIA", UDim2.fromOffset(163, 29), UDim2.new(1, -174, 1, -41), ink.moss, function() customize:FireServer("FinishCreation"); modal.Visible = false end)
end

local function selector(title: string, option: string, values: {string})
	local row = card(67)
	text(row, title, UDim2.fromOffset(240, 18), UDim2.fromOffset(13, 9), 13, ink.gold)
	local current = appearanceValue(option)
	local width = math.max(58, math.floor(535 / math.max(1, #values)))
	for index, name in ipairs(values) do
		local selected = name == current
		button(row, name, UDim2.fromOffset(width - 5, 25), UDim2.fromOffset(12 + (index - 1) * width, 34), if selected then ink.rust else ink.shadow, function() updateAppearance(option, name) end)
	end
end

local function colorSelector(title: string, option: string, values: {[string]: Color3})
	local row = card(75)
	text(row, title .. "  —  " .. tostring(appearanceValue(option)), UDim2.new(1, -25, 0, 18), UDim2.fromOffset(13, 8), 13, ink.gold)
	for index, name in ipairs(Appearance.GetSortedKeys(values)) do
		local swatch = create("TextButton", {Size = UDim2.fromOffset(30, 25), Position = UDim2.fromOffset(13 + (index - 1) * 38, 36), BackgroundColor3 = values[name], Text = if name == appearanceValue(option) then "✦" else "", Font = Enum.Font.Antique, TextSize = 16, TextColor3 = ink.ivory, BorderSizePixel = 0}, row)
		edge(swatch, 2, if name == appearanceValue(option) then ink.gold else ink.shadow)
		swatch.Activated:Connect(function() updateAppearance(option, name) end)
	end
end

local function showAppearance()
	heading.Text, subtitle.Text = "CÓDICE DA APARÊNCIA", "Molde o semblante, as vestes e os símbolos da sua linhagem."
	local portrait = card(205)
	preview(portrait)
	selector("ESTILO DO CABELO", "HairStyle", Appearance.HairStyles)
	colorSelector("TINTURA DO CABELO", "HairColor", Appearance.HairColors)
	colorSelector("COR DOS OLHOS", "EyeColor", Appearance.EyeColors)
	colorSelector("TOM DE PELE", "SkinTone", Appearance.SkinTones)
	selector("VESTIMENTA", "Outfit", Appearance.GetSortedKeys(Appearance.Outfits))
	local row = card(77)
	text(row, "SÍMBOLOS DA LINHAGEM", UDim2.fromOffset(320, 20), UDim2.fromOffset(13, 8), 13, ink.gold)
	for index, item in ipairs({{"Aura", "ShowAura"}, {"Adornos", "ShowRaceCosmetics"}, {"Asas", "ShowWings"}, {"Chifres", "ShowHorns"}}) do
		local enabled = appearanceValue(item[2]) ~= false
		button(row, (if enabled then "✓ " else "○ ") .. item[1], UDim2.fromOffset(119, 26), UDim2.fromOffset(13 + (index - 1) * 130, 37), if enabled then ink.moss else ink.shadow, function() updateAppearance(item[2], not enabled) end)
	end
end

local function buffLabel(name: string): string
	local aliases = {Vida = "Vida", Energia = "Energia", Forca = "Força", Agilidade = "Agilidade", Vitalidade = "Vitalidade", Sorte = "Sorte", Defesa = "Defesa", Dano = "Dano físico", DanoMagico = "Dano mágico", CriticoChance = "Crítico", VidaRegen = "Regeneração de vida", EnergiaRegen = "Regeneração de energia"}
	return aliases[name] or name
end

local function progressBar(row: Frame, y: number, caption: string, current: number, maximum: number, color: Color3)
	text(row, caption, UDim2.fromOffset(360, 17), UDim2.fromOffset(14, y), 12, ink.paper)
	text(row, current .. " / " .. maximum, UDim2.fromOffset(92, 17), UDim2.new(1, -106, 0, y), 11, ink.gold, true)
	local track = create("Frame", {Size = UDim2.new(1, -29, 0, 7), Position = UDim2.fromOffset(14, y + 20), BackgroundColor3 = ink.shadow, BorderSizePixel = 0}, row)
	edge(track, 2)
	local fill = create("Frame", {Size = UDim2.new(math.clamp(current / math.max(1, maximum), 0, 1), 0, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0}, track)
	edge(fill, 2)
end

local function showLineage()
	heading.Text, subtitle.Text = "LIVRO DAS LINHAGENS", "Todo aventureiro nasce com uma raça; o destino pode ser consultado novamente."
	local name = player:GetAttribute("Raca") or "Humano"
	local race = Races.Get(name) or Races.Get("Humano")
	local accent = Appearance.RaceAccents[name] or ink.gold
	local crest = card(139)
	text(crest, "✠   " .. string.upper(name), UDim2.new(1, -22, 0, 34), UDim2.fromOffset(14, 10), 23, accent)
	text(crest, race.Raridade .. "  ·  " .. race.Afinidade .. "  ·  " .. race.Passiva, UDim2.new(1, -25, 0, 21), UDim2.fromOffset(15, 47), 13, ink.gold)
	text(crest, race.Descricao, UDim2.new(1, -27, 0, 37), UDim2.fromOffset(15, 75), 12, ink.paper)
	local buffs = Races.GetBuffs(name)
	local attributes = card(36 + math.ceil(#buffs / 2) * 27)
	text(attributes, "BÊNÇÃOS E LIMITAÇÕES DA LINHAGEM", UDim2.new(1, -22, 0, 19), UDim2.fromOffset(13, 8), 13, ink.gold)
	for index, entry in ipairs(buffs) do
		local col, row = (index - 1) % 2, math.floor((index - 1) / 2)
		local sign = if entry.Percent > 0 then "+" else ""
		text(attributes, sign .. entry.Percent .. "%  " .. buffLabel(entry.Stat), UDim2.fromOffset(265, 21), UDim2.fromOffset(15 + col * 268, 33 + row * 25), 12, if entry.Percent >= 0 then ink.paper else Color3.fromRGB(221, 126, 111))
	end
	local odds = card(104)
	text(odds, "PROBABILIDADES REVELADAS", UDim2.new(1, -25, 0, 18), UDim2.fromOffset(13, 8), 13, ink.gold)
	for index, rarity in ipairs(Races.RarityOrder) do
		local col, row = (index - 1) % 3, math.floor((index - 1) / 3)
		text(odds, rarity .. "  " .. Races.RarityWeights[rarity] .. "%", UDim2.fromOffset(174, 21), UDim2.fromOffset(14 + col * 177, 34 + row * 26), 12, Appearance.RarityColors[rarity])
	end
	local fate = card(177)
	progressBar(fate, 10, "Garantia de linhagem épica", player:GetAttribute("RacePityEpic") or 0, settings.GuaranteedEpicAt, Appearance.RarityColors.Epica)
	progressBar(fate, 52, "Garantia de linhagem lendária", player:GetAttribute("RacePityLegendary") or 0, settings.GuaranteedLegendaryAt, Appearance.RarityColors.Lendaria)
	local spins = player:GetAttribute("RaceSpins") or 0
	text(fate, spins .. " consulta(s) gratuita(s)  ·  +" .. settings.DailyRaceSpins .. " por dia", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(14, 99), 12, ink.paper)
	local price = if spins > 0 then "CONSULTAR O DESTINO · GRÁTIS" else "CONSULTAR O DESTINO · " .. settings.RaceSpinCost .. " OURO"
	button(fate, price, UDim2.new(1, -28, 0, 33), UDim2.fromOffset(14, 129), ink.rust, function() if not rolling then rolling = true; customize:FireServer("RollRace"); task.delay(2.4, function() rolling = false end) end end)
	local footer = card(49)
	text(footer, "Somente moedas conquistadas no jogo. Nenhum Robux é necessário.", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(11, 7), 11, ink.faded, true)
end

local function showStats()
	heading.Text, subtitle.Text = "ATRIBUTOS DO AVENTUREIRO", "Os atributos evoluem automaticamente com nível, classe e linhagem."
	local summary = card(75)
	text(summary, "NÍVEL " .. (player:GetAttribute("Level") or 1) .. "  ·  " .. (player:GetAttribute("Raca") or "Humano"), UDim2.new(1, -20, 0, 26), UDim2.fromOffset(14, 8), 19, ink.gold)
	text(summary, "Progressão automática — sem distribuição manual de pontos.", UDim2.new(1, -20, 0, 19), UDim2.fromOffset(15, 43), 12, ink.paper)
	for index, item in ipairs({{"Forca", "FORÇA", "Poder dos golpes e dano físico"}, {"Agilidade", "AGILIDADE", "Deslocamento e habilidade corporal"}, {"Vitalidade", "VITALIDADE", "Vida máxima e vigor"}, {"EnergiaBase", "ENERGIA", "Reserva arcana e poder mágico"}, {"Sorte", "SORTE", "Chance de acertos críticos"}, {"Defesa", "DEFESA", "Resistência aos ataques recebidos"}}) do
		local row = card(62)
		row.LayoutOrder = index
		text(row, item[2], UDim2.fromOffset(235, 18), UDim2.fromOffset(14, 8), 13, ink.ivory)
		text(row, item[3], UDim2.fromOffset(410, 18), UDim2.fromOffset(14, 35), 11, ink.faded)
		text(row, tostring(math.floor(tonumber(player:GetAttribute(item[1])) or 0)), UDim2.fromOffset(78, 30), UDim2.new(1, -92, 0, 14), 20, ink.gold, true)
	end
	local derived = card(78)
	text(derived, "DANO FÍSICO  " .. math.floor(player:GetAttribute("DanoBaseFisico") or 0) .. "     DANO MÁGICO  " .. math.floor(player:GetAttribute("DanoBaseMagico") or 0), UDim2.new(1, -25, 0, 21), UDim2.fromOffset(14, 12), 12, ink.paper)
	text(derived, "CRÍTICO  " .. math.floor((player:GetAttribute("CriticoChance") or 0) * 100 + .5) .. "%     PASSIVA  " .. tostring(player:GetAttribute("RacePassive") or "—"), UDim2.new(1, -25, 0, 21), UDim2.fromOffset(14, 43), 12, ink.gold)
end

local function showClasses()
	heading.Text, subtitle.Text = "ORDENS E CLASSES", "A primeira vocação é gratuita; novas escolhas custam 150 moedas."
	local selected = player:GetAttribute("Classe") or "Noone"
	for index, entry in ipairs(Classes.GetSorted()) do
		local data, row = entry.Data, card(93)
		row.LayoutOrder = index
		text(row, entry.Name, UDim2.new(1, -115, 0, 23), UDim2.fromOffset(14, 8), 16, ink.ivory)
		text(row, data.Tipo .. "  ·  " .. (data.Raridade or "Comum") .. "  ·  " .. (data.Habilidade or ""), UDim2.new(1, -25, 0, 19), UDim2.fromOffset(15, 34), 11, ink.gold)
		text(row, data.Descricao, UDim2.new(1, -115, 0, 20), UDim2.fromOffset(15, 60), 11, ink.faded)
		local current = selected == entry.Name
		button(row, if current then "ATIVA" else "JURAR", UDim2.fromOffset(89, 30), UDim2.new(1, -101, 0, 31), if current then ink.moss else ink.rust, function() if not current then action:FireServer("SelectClass", entry.Name) end end)
	end
end

local function showQuests()
	heading.Text, subtitle.Text = "QUADRO DE CONTRATOS", "Missões e progresso permanecem guardados entre suas jornadas."
	local ids = {}
	for id in pairs(Quests.Quests) do table.insert(ids, id) end
	table.sort(ids)
	for index, id in ipairs(ids) do
		local quest, row = Quests.Quests[id], card(107)
		row.LayoutOrder = index
		local completed = player:GetAttribute(id .. "_AlreadyCompleted") == true
		local underway = player:GetAttribute("ActiveQuestId") == id
		local locked = (player:GetAttribute("Level") or 1) < quest.MinLevel
		text(row, "✠  [" .. quest.Rank .. "]  " .. quest.Name, UDim2.new(1, -116, 0, 22), UDim2.fromOffset(13, 9), 14, ink.ivory)
		text(row, quest.Description, UDim2.new(1, -23, 0, 19), UDim2.fromOffset(14, 35), 11, ink.paper)
		local progress = if underway then "  ·  " .. (player:GetAttribute("ActiveQuestProgress") or 0) .. "/" .. quest.Amount else ""
		text(row, "+" .. quest.Reward.XP .. " XP   ·   " .. quest.Reward.Dinheiro .. " OURO   ·   NÍVEL " .. quest.MinLevel .. progress, UDim2.new(1, -108, 0, 20), UDim2.fromOffset(14, 73), 11, ink.gold)
		local caption = if completed then "CUMPRIDA" elseif underway then "EM CURSO" elseif locked then "NÍVEL " .. quest.MinLevel else "ACEITAR"
		button(row, caption, UDim2.fromOffset(97, 29), UDim2.new(1, -107, 0, 65), if completed then ink.moss elseif locked then ink.shadow else ink.rust, function() if not completed and not underway and not locked then questsRemote:FireServer(id) end end)
	end
end

local render
render = function(tab: string)
	activeTab = tab
	clear()
	for name, tabButton in pairs(tabButtons) do tabButton.BackgroundColor3 = if name == tab then ink.rust else ink.panel end
	if tab == "Aparência" then showAppearance()
	elseif tab == "Linhagem" then showLineage()
	elseif tab == "Atributos" then showStats()
	elseif tab == "Missões" then showQuests()
	else showClasses() end
end

for index, name in ipairs({"Aparência", "Linhagem", "Atributos", "Missões", "Classes"}) do
	local item = create("TextButton", {Size = UDim2.new(1, 0, 0, 43), BackgroundColor3 = ink.panel, Text = name, TextColor3 = ink.ivory, Font = Enum.Font.Antique, TextSize = 14, AutoButtonColor = false, LayoutOrder = index}, sidebar)
	edge(item, 3, ink.gold)
	item.Activated:Connect(function() render(name) end)
	tabButtons[name] = item
end

local function open(tab: string)
	if modal.Visible and activeTab == tab then modal.Visible = false; return end
	modal.Visible = true
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local target = math.max(.36, math.min(1, (viewport.X - 22) / 800, (viewport.Y - 45) / 555))
	scale.Scale = target * .96
	TweenService:Create(scale, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target}):Play()
	render(tab)
end
close.Activated:Connect(function() modal.Visible = false end)
openSeal.Activated:Connect(function() open("Aparência") end)

local notices = create("Frame", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, .08), Size = UDim2.fromOffset(370, 220), BackgroundTransparency = 1}, gui)
create("UIListLayout", {Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Center}, notices)
local function toast(title: any, message: any, kind: any)
	local accent = if kind == "success" then ink.moss elseif kind == "critical" then ink.rust else ink.gold
	local row = create("Frame", {Size = UDim2.fromOffset(346, 58), BackgroundColor3 = ink.shadow, BackgroundTransparency = .06, BorderSizePixel = 0}, notices)
	edge(row, 3, ink.gold)
	create("Frame", {Size = UDim2.new(0, 4, 1, -14), Position = UDim2.fromOffset(0, 7), BorderSizePixel = 0, BackgroundColor3 = accent}, row)
	text(row, tostring(title), UDim2.fromOffset(313, 20), UDim2.fromOffset(13, 7), 14, accent)
	text(row, tostring(message or ""), UDim2.fromOffset(313, 20), UDim2.fromOffset(13, 31), 11, ink.paper)
	task.delay(3.6, function() if row.Parent then TweenService:Create(row, TweenInfo.new(.2), {BackgroundTransparency = 1}):Play(); task.wait(.22); row:Destroy() end end)
end

remotes:WaitForChild("RPGNotification").OnClientEvent:Connect(toast)
remotes:WaitForChild("LevelUp").OnClientEvent:Connect(function(level: number)
	toast("NÍVEL " .. tostring(level) .. " ALCANÇADO", "Seus atributos e poderes cresceram automaticamente.", "success")
end)
customizationFeedback.OnClientEvent:Connect(function(result)
	if type(result) ~= "table" then return end
	if result.Type == "Error" then rolling = false; toast("Destino indisponível", result.Message, "warning")
	elseif result.Type == "RaceRolled" then
		rolling = false
		toast("A linhagem respondeu", tostring(result.Race) .. " · " .. tostring(result.Rarity) .. " · " .. tostring(result.Passive), "success")
		if modal.Visible then render("Linhagem") end
	elseif result.Type == "BirthRace" then toast("Sua linhagem despertou", tostring(result.Race) .. " · " .. tostring(result.Passive), "success") end
end)

local redrawQueued = false
local function redraw()
	if not modal.Visible or redrawQueued then return end
	redrawQueued = true
	task.delay(.16, function() redrawQueued = false; if modal.Visible then render(activeTab) end end)
end
for _, name in ipairs({"PlayerRank", "Classe", "Raca", "Level", "ActiveQuestId", "ActiveQuestProgress", "RaceSpins", "RacePityEpic", "RacePityLegendary", "Forca", "Agilidade", "Vitalidade", "EnergiaBase", "Sorte", "Defesa"}) do player:GetAttributeChangedSignal(name):Connect(redraw) end
for option in pairs(Appearance.Defaults) do player:GetAttributeChangedSignal("Appearance_" .. option):Connect(redraw) end
player.CharacterAdded:Connect(function() task.delay(.8, redraw) end)

UserInputService.InputBegan:Connect(function(input, consumed)
	if consumed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Q then action:FireServer("Dash")
	elseif input.KeyCode == Enum.KeyCode.F then action:FireServer("Block", true)
	elseif input.KeyCode == Enum.KeyCode.V then open("Aparência")
	elseif input.KeyCode == Enum.KeyCode.E then open("Atributos")
	elseif input.KeyCode == Enum.KeyCode.J then open("Missões")
	elseif input.KeyCode == Enum.KeyCode.C then open("Classes")
	elseif input.KeyCode == Enum.KeyCode.Escape and modal.Visible then modal.Visible = false end
end)
UserInputService.InputEnded:Connect(function(input) if input.KeyCode == Enum.KeyCode.F then action:FireServer("Block", false) end end)
RunService.RenderStepped:Connect(function(dt)
	if modal.Visible and activeTab == "Aparência" and previewModel and previewModel.Parent then previewModel:PivotTo(previewModel:GetPivot() * CFrame.Angles(0, dt * .43, 0)) end
end)

local function resize()
	local camera = workspace.CurrentCamera
	if camera then scale.Scale = math.max(.36, math.min(1, (camera.ViewportSize.X - 22) / 800, (camera.ViewportSize.Y - 45) / 555)) end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
resize()
local function offerCreation()
	if player:GetAttribute("RPGDataLoaded") and player:GetAttribute("CustomizationComplete") ~= true then task.delay(.7, function() if not modal.Visible then open("Aparência") end end) end
end
player:GetAttributeChangedSignal("RPGDataLoaded"):Connect(offerCreation)
offerCreation()

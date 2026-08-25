--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local screen = script.Parent
local main = screen:WaitForChild("MainFrame", 12)
if not main or not main:IsA("GuiObject") then warn("[RPG/HUD] MainFrame não encontrado."); return end
local XPConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("XPConfig"))

local function child(parent: Instance, name: string, timeout: number?): Instance?
	return parent:FindFirstChild(name) or parent:WaitForChild(name, timeout or 5)
end

local hpBackground, energyBackground, xpBackground = child(main, "HPBar"), child(main, "EnergyBar"), child(main, "XPBar")
local hpFill = hpBackground and child(hpBackground, "Fill")
local energyFill = energyBackground and child(energyBackground, "Fill")
local xpFill = xpBackground and child(xpBackground, "Fill")
local levelLabel, moneyLabel = child(main, "LevelLabel"), child(main, "MoneyLabel")
if not hpFill or not energyFill or not xpFill then warn("[RPG/HUD] Barras originais incompletas."); return end

screen.ResetOnSpawn = false
main.BackgroundColor3 = Color3.fromRGB(13, 17, 29)
main.BackgroundTransparency = .12
local corner = main:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = main
local outline = main:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
outline.Color, outline.Transparency, outline.Thickness, outline.Parent = Color3.fromRGB(122, 104, 255), .56, 1, main

local function decorateBar(background: Instance, fill: Instance, color: Color3, title: string)
	if not background:IsA("GuiObject") or not fill:IsA("GuiObject") then return end
	background.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
	background.BackgroundTransparency = .08
	fill.BackgroundColor3 = color
	for _, object in ipairs({background, fill}) do
		local radius = object:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
		radius.CornerRadius, radius.Parent = UDim.new(1, 0), object
	end
	local gradient = fill:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), .2)), ColorSequenceKeypoint.new(1, color)})
	gradient.Parent = fill
	local label = background:FindFirstChild("RPGValue") or Instance.new("TextLabel")
	label.Name, label.BackgroundTransparency, label.Size = "RPGValue", 1, UDim2.fromScale(1, 1)
	label.Font, label.TextSize, label.TextColor3, label.TextStrokeTransparency, label.ZIndex = Enum.Font.GothamMedium, 10, Color3.fromRGB(240, 243, 252), .8, 5
	label.Text = title
	label.Parent = background
end

decorateBar(hpBackground, hpFill, Color3.fromRGB(241, 94, 108), "VIDA")
decorateBar(energyBackground, energyFill, Color3.fromRGB(99, 172, 255), "ENERGIA")
decorateBar(xpBackground, xpFill, Color3.fromRGB(173, 117, 255), "EXPERIÊNCIA")
for _, label in ipairs({levelLabel, moneyLabel}) do
	if label and label:IsA("TextLabel") then label.Font = Enum.Font.GothamBold; label.TextColor3 = Color3.fromRGB(236, 239, 255) end
end

local activeTweens, healthConnection, maxConnection = {}, nil, nil
local lowHealth = false
local function tweenBar(fill: GuiObject, ratio: number)
	if ratio ~= ratio or ratio == math.huge then ratio = 0 end
	local percent = math.clamp(ratio, 0, 1)
	local previous = activeTweens[fill]
	if previous then previous:Cancel() end
	local animation = TweenService:Create(fill, TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(percent, 0, 1, 0)})
	activeTweens[fill] = animation
	animation:Play()
end

local function compact(value: number): string
	if value >= 1000000 then return string.format("%.1fM", value / 1000000) end
	if value >= 1000 then return string.format("%.1fK", value / 1000) end
	return tostring(math.floor(value))
end

local function refresh()
	local level = math.max(1, tonumber(player:GetAttribute("Level")) or 1)
	local rank = player:GetAttribute("PlayerRank") or "D"
	if levelLabel and levelLabel:IsA("TextLabel") then levelLabel.Text = "LV " .. level .. "  ·  RANK " .. rank end
	if moneyLabel and moneyLabel:IsA("TextLabel") then moneyLabel.Text = "✦ " .. compact(math.max(0, player:GetAttribute("Dinheiro") or 0)) end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local max = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(humanoid.Health / max, 0, 1)
		tweenBar(hpFill, ratio)
		lowHealth = ratio <= .25 and humanoid.Health > 0
		local value = hpBackground:FindFirstChild("RPGValue")
		if value then value.Text = "VIDA  " .. compact(humanoid.Health) .. " / " .. compact(max) end
	end
	local maximum = math.max(1, tonumber(player:GetAttribute("EnergiaMax")) or 1)
	local energy = math.clamp(tonumber(player:GetAttribute("Energia")) or 0, 0, maximum)
	tweenBar(energyFill, energy / maximum)
	local energyValue = energyBackground:FindFirstChild("RPGValue")
	if energyValue then energyValue.Text = "ENERGIA  " .. compact(energy) .. " / " .. compact(maximum) end
	local xp = math.max(0, tonumber(player:GetAttribute("XP")) or 0)
	local needed = XPConfig.XPParaLevel(level)
	local capped = needed == math.huge
	tweenBar(xpFill, if capped then 1 else xp / math.max(1, needed))
	local xpValue = xpBackground:FindFirstChild("RPGValue")
	if xpValue then xpValue.Text = if capped then "NÍVEL MÁXIMO" else "XP  " .. compact(xp) .. " / " .. compact(needed) end
end

local function onCharacter(character: Model)
	if healthConnection then healthConnection:Disconnect() end
	if maxConnection then maxConnection:Disconnect() end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	healthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(refresh)
	maxConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refresh)
	refresh()
end

player.CharacterAdded:Connect(onCharacter)
for _, name in ipairs({"Energia", "EnergiaMax", "XP", "Level", "Dinheiro", "PlayerRank"}) do player:GetAttributeChangedSignal(name):Connect(refresh) end
if player.Character then task.defer(onCharacter, player.Character) end

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	if not lowHealth then if hpFill.BackgroundColor3 ~= Color3.fromRGB(241, 94, 108) then hpFill.BackgroundColor3 = Color3.fromRGB(241, 94, 108) end; return end
	elapsed += dt
	hpFill.BackgroundColor3 = Color3.fromRGB(241, 94, 108):Lerp(Color3.fromRGB(129, 43, 55), math.sin(elapsed * 7) * .5 + .5)
end)
refresh()

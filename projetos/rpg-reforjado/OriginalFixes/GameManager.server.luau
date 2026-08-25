--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local event = ServerStorage:FindFirstChild("BossMorto")
if not event or not event:IsA("BindableEvent") then warn("[RPG/Boss] Evento BossMorto indisponível."); return end

event.Event:Connect(function(player: Player, boss: Model?)
	if not player or not player:IsA("Player") then return end
	local door = workspace:FindFirstChild("PortaDoCastelo", true)
	if door and door:IsA("BasePart") then
		door.CanCollide = false
		TweenService:Create(door, TweenInfo.new(1.1, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
	end
	local notification = ReplicatedStorage.Remotes:FindFirstChild("RPGNotification")
	if notification then notification:FireAllClients("CHEFE DERROTADO", player.Name .. " venceu " .. (boss and boss.Name or "o guardião") .. "!", "legendary") end
end)

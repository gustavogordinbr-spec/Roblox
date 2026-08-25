--!strict
local Players = game:GetService("Players")
local sequence = {}

local function setup(player: Player)
	local combo = player:FindFirstChild("Combo")
	if not combo then combo = Instance.new("IntValue"); combo.Name = "Combo"; combo.Parent = player end
	combo.Value = 0
	combo.Changed:Connect(function(value)
		sequence[player] = (sequence[player] or 0) + 1
		local version = sequence[player]
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		local screen = playerGui and playerGui:FindFirstChild("HitGui")
		local label = screen and screen:FindFirstChild("HitGui")
		if label and label:IsA("TextLabel") then label.Visible = value > 0; label.Text = tostring(value) .. " HITS" end
		if value > 0 then task.delay(4, function() if sequence[player] == version and combo.Parent then combo.Value = 0 end end) end
	end)
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do task.defer(setup, player) end
Players.PlayerRemoving:Connect(function(player) sequence[player] = nil end)

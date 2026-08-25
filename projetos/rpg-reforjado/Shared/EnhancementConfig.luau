--!strict
return {
	Version = "2.0.0",
	Combat = {AttackCooldown = 0.32, ComboReset = 1.35, Reach = 8, HitboxSize = Vector3.new(7, 6, 8), DashCooldown = 2.4, DashCost = 24, DashPower = 58, BlockReduction = 0.68, PvPEnabled = false},
	Sprint = {MinimumEnergy = 10, DrainPerSecond = 12, Tick = 0.2},
	Progression = {PointsPerLevel = 3, ClassChangeCost = 150, MaximumAllocatedPerStat = 250},
	Presentation = {NormalFOV = 72, SprintFOV = 82, DashFOV = 89, AccentColor = Color3.fromRGB(122, 104, 255), GoldColor = Color3.fromRGB(255, 199, 95)},
	Ranks = {{Minimum = 120, Name = "S"}, {Minimum = 70, Name = "A"}, {Minimum = 35, Name = "B"}, {Minimum = 15, Name = "C"}, {Minimum = 1, Name = "D"}},
}

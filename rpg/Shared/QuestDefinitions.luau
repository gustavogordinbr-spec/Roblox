--!strict
return {
	FirstSteps = { Name = "Primeiros Passos", Description = "Explore a cidade e converse com o Guia dos Heróis.", Type = "Talk", Target = "Guide", Amount = 1, MinLevel = 1, XP = 100, Gold = 100, Items = { HealthPotion = 3 }, Story = true },
	StreetPatrol = { Name = "Patrulha das Ruas", Description = "Derrote 4 ameaças para proteger a cidade.", Type = "Kill", Target = "Any", Amount = 4, MinLevel = 1, XP = 180, Gold = 140, Items = { IronOre = 2 }, Story = true },
	TrainingDay = { Name = "Dia de Treinamento", Description = "Derrote 8 inimigos e prove seu valor.", Type = "Kill", Target = "Any", Amount = 8, MinLevel = 2, XP = 320, Gold = 230, Items = { HealthPotion = 2 }, Story = true },
	HeroSupplies = { Name = "Suprimentos de Herói", Description = "Consiga 5 minérios de ferro durante suas aventuras.", Type = "Collect", Target = "IronOre", Amount = 5, MinLevel = 3, XP = 260, Gold = 180, Items = { ManaPotion = 2 }, Story = false },
	FirstElite = { Name = "A Primeira Ameaça", Description = "Derrote um inimigo de elite.", Type = "Kill", Target = "Elite", Amount = 1, MinLevel = 5, XP = 550, Gold = 380, Items = { AuroraShard = 2 }, Story = true },
	ProtectTheCity = { Name = "Proteja a Cidade", Description = "Derrote 15 inimigos em qualquer região.", Type = "Kill", Target = "Any", Amount = 15, MinLevel = 6, XP = 700, Gold = 450, Items = { SteelSword = 1 }, Story = true },
	AuroraResearch = { Name = "Pesquisa da Aurora", Description = "Encontre 4 fragmentos da Aurora.", Type = "Collect", Target = "AuroraShard", Amount = 4, MinLevel = 8, XP = 620, Gold = 500, Items = { GreaterHealthPotion = 2 }, Story = true },
	BossHunt = { Name = "Caçada ao Chefe", Description = "Derrote um chefe com ou sem ajuda do seu grupo.", Type = "Kill", Target = "Boss", Amount = 1, MinLevel = 10, XP = 1250, Gold = 1000, Items = { BossCore = 1 }, Story = true },
	DailyPatrol = { Name = "Patrulha Diária", Description = "Derrote 6 ameaças e mantenha a cidade segura.", Type = "Kill", Target = "Any", Amount = 6, MinLevel = 1, XP = 240, Gold = 170, Items = { HealthPotion = 2 }, Daily = true },
	DailyElite = { Name = "Contrato de Elite", Description = "Derrote 2 inimigos de elite.", Type = "Kill", Target = "Elite", Amount = 2, MinLevel = 7, XP = 650, Gold = 420, Items = { AuroraShard = 1 }, Daily = true },
	DailyMaterials = { Name = "Coleta Urgente", Description = "Reúna 3 minérios de ferro.", Type = "Collect", Target = "IronOre", Amount = 3, MinLevel = 2, XP = 200, Gold = 150, Items = { StaminaPotion = 2 }, Daily = true },
	LegendAwakens = { Name = "Nasce uma Lenda", Description = "Derrote 3 chefes e torne-se referência entre os heróis.", Type = "Kill", Target = "Boss", Amount = 3, MinLevel = 20, XP = 4200, Gold = 3000, Items = { HeroMantle = 1 }, Story = true },
}

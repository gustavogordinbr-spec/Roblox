--!strict
-- Classes originais expandidas: os nomes existentes permanecem compatíveis.
local Classes = {}

Classes.Lista = {
	Blademaster = {Tipo = "Fisica", Raridade = "Comum", Multiplicadores = {Forca = 1.1, Agilidade = 1.08, Dano = 1.15}, Habilidade = "CorteAscendente", Escala = "Forca", Custo = 20, Cooldown = 6, Descricao = "Mestre da lâmina que encadeia cortes precisos."},
	Ravager = {Tipo = "Fisica", Raridade = "Rara", Multiplicadores = {Forca = 1.25, Vitalidade = 1.06, Dano = 1.2}, Habilidade = "FuriaDestrutiva", Escala = "Forca", Custo = 30, Cooldown = 10, Descricao = "Berserker que transforma pressão em dano bruto."},
	IronKnight = {Tipo = "Fisica", Raridade = "Comum", Multiplicadores = {Vitalidade = 1.25, Forca = 1.05, Defesa = 1.2}, Habilidade = "PosturaDefensiva", Escala = "Vitalidade", Custo = 25, Cooldown = 12, Descricao = "Guardião de armadura pesada e defesa exemplar."},
	ShadowSlayer = {Tipo = "Fisica", Raridade = "Rara", Multiplicadores = {Agilidade = 1.22, Dano = 1.1, CriticoChance = 1.15}, Habilidade = "GolpeSilencioso", Escala = "Agilidade", Custo = 20, Cooldown = 5, Descricao = "Assassino veloz especializado em golpes críticos."},
	Vanguard = {Tipo = "Fisica", Raridade = "Comum", Multiplicadores = {Forca = 1.12, Vitalidade = 1.12, Defesa = 1.08}, Habilidade = "Investida", Escala = "Forca", Custo = 18, Cooldown = 7, Descricao = "Guerreiro equilibrado que abre caminho na linha de frente."},
	Duelist = {Tipo = "Fisica", Raridade = "Rara", Multiplicadores = {Agilidade = 1.2, Sorte = 1.12, CriticoChance = 1.2}, Habilidade = "EstocadaPerfeita", Escala = "Agilidade", Custo = 22, Cooldown = 6, Descricao = "Espadachim de precisão, esquiva e contra-ataques."},
	BeastHunter = {Tipo = "Fisica", Raridade = "Rara", Multiplicadores = {Forca = 1.12, Agilidade = 1.14, Dano = 1.1}, Habilidade = "MarcaDaPresa", Escala = "Agilidade", Custo = 24, Cooldown = 9, Descricao = "Caçador de monstros especializado em rastrear elites."},
	Arcanist = {Tipo = "Magica", Raridade = "Comum", Multiplicadores = {Energia = 1.22, DanoMagico = 1.25}, Habilidade = "ExplosaoArcana", Escala = "Energia", Custo = 35, Cooldown = 8, Descricao = "Manipula energia arcana para devastar inimigos."},
	Spellweaver = {Tipo = "Magica", Raridade = "Rara", Multiplicadores = {Energia = 1.16, Agilidade = 1.08, CooldownReduction = 1.1}, Habilidade = "TecelagemMistica", Escala = "Energia", Custo = 30, Cooldown = 7, Descricao = "Encadeia feitiços velozes e controla o campo."},
	Pyromancer = {Tipo = "Magica", Raridade = "Rara", Multiplicadores = {Energia = 1.15, DanoMagico = 1.28, Forca = 1.04}, Habilidade = "ChamaAbissal", Escala = "Energia", Custo = 38, Cooldown = 10, Descricao = "Conjura fogo destrutivo e mantém os oponentes sob pressão."},
	FrostWarden = {Tipo = "Magica", Raridade = "Rara", Multiplicadores = {Energia = 1.16, Vitalidade = 1.13, Defesa = 1.1}, Habilidade = "PrisãoGlacial", Escala = "Energia", Custo = 32, Cooldown = 11, Descricao = "Controlador de gelo com excelente resistência."},
	StormCaller = {Tipo = "Magica", Raridade = "Epica", Multiplicadores = {Energia = 1.2, Agilidade = 1.16, DanoMagico = 1.2}, Habilidade = "LancaTrovao", Escala = "Energia", Custo = 40, Cooldown = 9, Descricao = "Canaliza relâmpagos em ataques rápidos e explosivos."},
	Cleric = {Tipo = "Suporte", Raridade = "Comum", Multiplicadores = {Energia = 1.15, Vitalidade = 1.14, Defesa = 1.06}, Habilidade = "LuzRestauradora", Escala = "Energia", Custo = 28, Cooldown = 12, Descricao = "Sacerdote que combina sustentação e proteção."},
	Warden = {Tipo = "Suporte", Raridade = "Rara", Multiplicadores = {Vitalidade = 1.22, Energia = 1.08, Defesa = 1.15}, Habilidade = "BarreiraAntiga", Escala = "Vitalidade", Custo = 26, Cooldown = 13, Descricao = "Protetor que ergue barreiras e segura grupos."},
	Soulbinder = {Tipo = "Suporte", Raridade = "Epica", Multiplicadores = {Energia = 1.2, Sorte = 1.14, DanoMagico = 1.12}, Habilidade = "VinculoEspiritual", Escala = "Energia", Custo = 34, Cooldown = 11, Descricao = "Manipula vínculos espirituais e enfraquece alvos."},
	Runeblade = {Tipo = "Hibrida", Raridade = "Epica", Multiplicadores = {Forca = 1.13, Energia = 1.16, Dano = 1.08, DanoMagico = 1.12}, Habilidade = "LaminaRunica", Escala = "Todas", Custo = 35, Cooldown = 9, Descricao = "Fundiu esgrima e magia em uma mesma arte."},
	NightReaper = {Tipo = "Hibrida", Raridade = "Epica", Multiplicadores = {Agilidade = 1.18, Energia = 1.12, CriticoChance = 1.2}, Habilidade = "ColheitaSombria", Escala = "Agilidade", Custo = 36, Cooldown = 10, Descricao = "Ceifador sombrio que alterna mobilidade e magia."},
	Dragonheart = {Tipo = "Unica", Raridade = "Lendaria", Multiplicadores = {Forca = 1.22, Vitalidade = 1.18, Energia = 1.12, Dano = 1.18}, Habilidade = "RugidoDraconico", Escala = "Forca", Custo = 50, Cooldown = 20, Descricao = "Portador do poder ancestral dos dragões."},
	VoidWalker = {Tipo = "Unica", Raridade = "Lendaria", Multiplicadores = {Energia = 1.24, Agilidade = 1.18, DanoMagico = 1.2}, Habilidade = "RupturaDoVazio", Escala = "Energia", Custo = 52, Cooldown = 22, Descricao = "Dobra o vazio e atravessa a linha inimiga."},
	Avatar = {Tipo = "Unica", Raridade = "Mitica", Multiplicadores = {Vida = 1.2, Energia = 1.2, Forca = 1.2, Agilidade = 1.2, Vitalidade = 1.15, Dano = 1.3}, Habilidade = "Manifestacao", Escala = "Todas", Custo = 60, Cooldown = 30, Descricao = "Encarnação excepcional de todos os caminhos de combate."},
}

function Classes.Get(nome: any)
	return type(nome) == "string" and Classes.Lista[nome] or nil
end

function Classes.GetClassesByType(tipo: string)
	local results = {}
	for name, data in pairs(Classes.Lista) do
		if data.Tipo == tipo then table.insert(results, name) end
	end
	table.sort(results)
	return results
end

function Classes.GetSorted()
	local results = {}
	for name, data in pairs(Classes.Lista) do table.insert(results, {Name = name, Data = data}) end
	table.sort(results, function(a, b) return a.Name < b.Name end)
	return results
end

return Classes

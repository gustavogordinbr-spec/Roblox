--!strict
local Racas = {}

Racas.Lista = {
	Humano = {Raridade = "Comum", Multiplicadores = {Vida = 1.04, Energia = 1, Forca = 1, Agilidade = 1, Vitalidade = 1, Sorte = 1.06}, LimitadorPercent = 100, Descricao = "Versátil, equilibrado e adaptável.", Passiva = "Espírito Adaptável", Afinidade = "Equilíbrio", Visual = {"Medalhao"}},
	Elfyn = {Raridade = "Comum", Multiplicadores = {Vida = .95, Energia = 1.08, Forca = .95, Agilidade = 1.13, Vitalidade = .95, CriticoChance = 1.06}, LimitadorPercent = 100, Descricao = "Ágil, atento e naturalmente afinado com magia.", Passiva = "Passos Silvestres", Afinidade = "Agilidade", Visual = {"OrelhasElficas", "CoroaFolhas"}},
	Durgan = {Raridade = "Comum", Multiplicadores = {Vida = 1.15, Energia = .9, Forca = 1.08, Agilidade = .92, Vitalidade = 1.18, Defesa = 1.08}, LimitadorPercent = 100, Descricao = "Robusto, persistente e nascido para a linha de frente.", Passiva = "Sangue da Montanha", Afinidade = "Resistência", Visual = {"BarbaTrancada", "RunasOmbro"}},
	Feralkin = {Raridade = "Incomum", Multiplicadores = {Forca = 1.12, Agilidade = 1.18, Vitalidade = .96, Sorte = 1.05, CriticoChance = 1.1}, LimitadorPercent = 100, Descricao = "Instintos aguçados e movimentação predatória.", Passiva = "Instinto de Caça", Afinidade = "Crítico", Visual = {"OrelhasFerais", "CaudaFeral"}},
	Sylvani = {Raridade = "Incomum", Multiplicadores = {Energia = 1.15, Agilidade = 1.08, Vitalidade = 1.03, Sorte = 1.08, VidaRegen = 1.18}, LimitadorPercent = 100, Descricao = "Povo da floresta, íntimo da magia natural.", Passiva = "Benção das Raízes", Afinidade = "Regeneração", Visual = {"CoroaFolhas", "OrelhasElficas"}},
	Stoneborn = {Raridade = "Rara", Multiplicadores = {Vida = 1.2, Forca = 1.1, Vitalidade = 1.24, Agilidade = .87, Defesa = 1.18}, LimitadorPercent = 100, Descricao = "Corpo mineral de resistência extraordinária.", Passiva = "Pele de Obsidiana", Afinidade = "Defesa", Visual = {"OmbreirasPedra", "CristaisCostas"}},
	Nightborn = {Raridade = "Rara", Multiplicadores = {Energia = 1.12, Agilidade = 1.2, Sorte = 1.12, Vitalidade = .94, CriticoChance = 1.18}, LimitadorPercent = 100, Descricao = "Filho da noite, veloz e preciso.", Passiva = "Véu Noturno", Afinidade = "Crítico", Visual = {"ChifresSombrios", "MarcasOlhos"}},
	Tidecaller = {Raridade = "Rara", Multiplicadores = {Energia = 1.2, Vitalidade = 1.08, Agilidade = 1.05, DanoMagico = 1.1, EnergiaRegen = 1.2}, LimitadorPercent = 100, Descricao = "Herdeiro do oceano e de sua magia restauradora.", Passiva = "Maré Renovadora", Afinidade = "Energia", Visual = {"Barbatanas", "CristaisAgua"}},
	Draconian = {Raridade = "Epica", Multiplicadores = {Vida = 1.16, Forca = 1.2, Energia = 1.1, Vitalidade = 1.15, Dano = 1.14}, LimitadorPercent = 100, Descricao = "Sangue de dragão pulsando sob escamas ancestrais.", Passiva = "Coração Dracônico", Afinidade = "Dano físico", Visual = {"ChifresDragao", "CaudaDragao", "AsasDragao"}},
	Celestial = {Raridade = "Epica", Multiplicadores = {Energia = 1.25, Vitalidade = 1.13, Sorte = 1.16, DanoMagico = 1.12, VidaRegen = 1.2}, LimitadorPercent = 100, Descricao = "Essência luminosa e afinidade espiritual elevada.", Passiva = "Graça Astral", Afinidade = "Magia", Visual = {"Aureola", "AsasCelestiais"}},
	Abyssal = {Raridade = "Lendaria", Multiplicadores = {Forca = 1.2, Energia = 1.23, Vitalidade = 1.12, Dano = 1.16, DanoMagico = 1.12}, LimitadorPercent = 100, Descricao = "Poder profundo forjado no abismo.", Passiva = "Pacto Abissal", Afinidade = "Poder híbrido", Visual = {"ChifresAbissais", "CaudaAbissal", "AsasAbissais"}},
	Voidborn = {Raridade = "Secreta", Multiplicadores = {Vida = 1.5, Energia = 1.5, Forca = 1.4, Agilidade = 1.2, Vitalidade = 1.5, Dano = 1.18, EnergiaRegen = 1.25}, LimitadorPercent = 100, Descricao = "Entidade raríssima nascida entre realidades.", Passiva = "Singularidade", Afinidade = "Todos os atributos", Visual = {"AureolaVazio", "ChifresVazio", "FragmentosVazio"}},
}

Racas.RarityWeights = {Comum = 48, Incomum = 27, Rara = 16, Epica = 7, Lendaria = 1.7, Secreta = .3}
Racas.RarityOrder = {"Comum", "Incomum", "Rara", "Epica", "Lendaria", "Secreta"}

function Racas.Get(nome: any)
	return type(nome) == "string" and Racas.Lista[nome] or nil
end

function Racas.GetRacesByRarity(raridade: string)
	local results = {}
	for name, data in pairs(Racas.Lista) do
		if data.Raridade == raridade then table.insert(results, name) end
	end
	table.sort(results)
	return results
end

function Racas.GetSorted()
	local order = {}
	for index, rarity in ipairs(Racas.RarityOrder) do order[rarity] = index end
	local result = {}
	for name, data in pairs(Racas.Lista) do table.insert(result, {Name = name, Data = data}) end
	table.sort(result, function(a, b)
		local first, second = order[a.Data.Raridade] or 99, order[b.Data.Raridade] or 99
		return if first == second then a.Name < b.Name else first < second
	end)
	return result
end

function Racas.GetBuffs(nome: string)
	local race = Racas.Get(nome)
	if not race then return {} end
	local result = {}
	for stat, multiplier in pairs(race.Multiplicadores) do
		local percent = math.floor((multiplier - 1) * 100 + (if multiplier >= 1 then .5 else -.5))
		if percent ~= 0 then table.insert(result, {Stat = stat, Percent = percent}) end
	end
	table.sort(result, function(a, b) return a.Percent > b.Percent end)
	return result
end

return Racas

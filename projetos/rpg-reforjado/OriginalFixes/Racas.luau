--!strict
local Racas = {}

Racas.Lista = {
	Humano = {Raridade = "Comum", Multiplicadores = {Vida = 1, Energia = 1, Forca = 1, Agilidade = 1, Vitalidade = 1, Sorte = 1}, LimitadorPercent = 100, Descricao = "Versátil, equilibrado e adaptável."},
	Elfyn = {Raridade = "Comum", Multiplicadores = {Vida = .95, Energia = 1.08, Forca = .95, Agilidade = 1.13, Vitalidade = .95}, LimitadorPercent = 100, Descricao = "Ágil, atento e naturalmente afinado com magia."},
	Durgan = {Raridade = "Comum", Multiplicadores = {Vida = 1.15, Energia = .9, Forca = 1.08, Agilidade = .92, Vitalidade = 1.18}, LimitadorPercent = 100, Descricao = "Robusto, persistente e nascido para a linha de frente."},
	Feralkin = {Raridade = "Incomum", Multiplicadores = {Forca = 1.12, Agilidade = 1.18, Vitalidade = .96, Sorte = 1.05}, LimitadorPercent = 100, Descricao = "Instintos aguçados e movimentação predatória."},
	Sylvani = {Raridade = "Incomum", Multiplicadores = {Energia = 1.15, Agilidade = 1.08, Vitalidade = 1.03, Sorte = 1.08}, LimitadorPercent = 100, Descricao = "Povo da floresta, íntimo da magia natural."},
	Stoneborn = {Raridade = "Rara", Multiplicadores = {Vida = 1.2, Forca = 1.1, Vitalidade = 1.24, Agilidade = .87, Defesa = 1.12}, LimitadorPercent = 100, Descricao = "Corpo mineral de resistência extraordinária."},
	Nightborn = {Raridade = "Rara", Multiplicadores = {Energia = 1.12, Agilidade = 1.2, Sorte = 1.12, Vitalidade = .94}, LimitadorPercent = 100, Descricao = "Filho da noite, veloz e preciso."},
	Tidecaller = {Raridade = "Rara", Multiplicadores = {Energia = 1.2, Vitalidade = 1.08, Agilidade = 1.05, DanoMagico = 1.1}, LimitadorPercent = 100, Descricao = "Herdeiro do oceano e de sua magia restauradora."},
	Draconian = {Raridade = "Epica", Multiplicadores = {Vida = 1.16, Forca = 1.2, Energia = 1.1, Vitalidade = 1.15}, LimitadorPercent = 100, Descricao = "Sangue de dragão pulsando sob escamas ancestrais."},
	Celestial = {Raridade = "Epica", Multiplicadores = {Energia = 1.25, Vitalidade = 1.13, Sorte = 1.16, DanoMagico = 1.12}, LimitadorPercent = 100, Descricao = "Essência luminosa e afinidade espiritual elevada."},
	Abyssal = {Raridade = "Lendaria", Multiplicadores = {Forca = 1.2, Energia = 1.23, Vitalidade = 1.12, Dano = 1.1}, LimitadorPercent = 100, Descricao = "Poder profundo forjado no abismo."},
	Voidborn = {Raridade = "Secreta", Multiplicadores = {Vida = 1.5, Energia = 1.5, Forca = 1.4, Agilidade = 1.2, Vitalidade = 1.5}, LimitadorPercent = 100, Descricao = "Entidade raríssima nascida entre realidades."},
}

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

return Racas

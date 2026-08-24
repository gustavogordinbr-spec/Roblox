--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("AuroraRPG"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("GameConfig"))

local PartyService = {}
local parties = {}
local membership = {}
local invitations = {}
local notify
local sync

function PartyService.Init(notifier, synchronize)
	notify, sync = notifier, synchronize
end

function PartyService.GetMembers(player)
	local partyId = membership[player.UserId]
	local party = partyId and parties[partyId]
	return if party then party.Members else { player }
end

function PartyService.GetSnapshot(player)
	local partyId = membership[player.UserId]
	local party = partyId and parties[partyId]
	if not party then return nil end
	local members = {}
	for _, member in ipairs(party.Members) do
		table.insert(members, { UserId = member.UserId, Name = member.DisplayName, Leader = member == party.Leader })
	end
	return { LeaderId = party.Leader.UserId, Members = members }
end

local function syncParty(party)
	for _, member in ipairs(party.Members) do sync(member) end
end

function PartyService.Invite(player, targetName)
	local target
	for _, candidate in ipairs(Players:GetPlayers()) do
		if candidate.Name:lower() == tostring(targetName):lower() or candidate.DisplayName:lower() == tostring(targetName):lower() then target = candidate; break end
	end
	if not target or target == player then return false, "Jogador não encontrado." end
	if membership[target.UserId] then return false, "O jogador já está em um grupo." end
	local partyId = membership[player.UserId]
	if partyId and (parties[partyId].Leader ~= player or #parties[partyId].Members >= Config.MaxPartySize) then
		return false, "Somente o líder pode convidar e o grupo não pode estar cheio."
	end
	invitations[target.UserId] = { From = player, Expires = os.clock() + 45 }
	notify(target, "PartyInvite", player.DisplayName .. " convidou você para um grupo.")
	notify(player, "Party", "Convite enviado para " .. target.DisplayName .. ".")
	sync(target)
	return true
end

function PartyService.Accept(player)
	local invitation = invitations[player.UserId]
	if not invitation or invitation.Expires < os.clock() or not invitation.From.Parent then return false end
	local leader = invitation.From
	local partyId = membership[leader.UserId]
	if not partyId then
		partyId = tostring(leader.UserId) .. "_" .. tostring(os.time())
		parties[partyId] = { Leader = leader, Members = { leader } }
		membership[leader.UserId] = partyId
	end
	local party = parties[partyId]
	if #party.Members >= Config.MaxPartySize then return false end
	table.insert(party.Members, player)
	membership[player.UserId] = partyId
	invitations[player.UserId] = nil
	notify(player, "Party", "Você entrou no grupo de " .. leader.DisplayName .. ".")
	syncParty(party)
	return true
end

function PartyService.Leave(player)
	local partyId = membership[player.UserId]
	local party = partyId and parties[partyId]
	if not party then return false end
	for index, member in ipairs(party.Members) do
		if member == player then table.remove(party.Members, index); break end
	end
	membership[player.UserId] = nil
	if #party.Members <= 1 then
		for _, member in ipairs(party.Members) do membership[member.UserId] = nil; sync(member) end
		parties[partyId] = nil
	elseif party.Leader == player then
		party.Leader = party.Members[1]
		syncParty(party)
	else
		syncParty(party)
	end
	sync(player)
	return true
end

return PartyService

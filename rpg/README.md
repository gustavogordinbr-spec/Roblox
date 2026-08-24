# Quirkbound: Ascensão dos Heróis

Camada de RPG adicionada de forma não destrutiva ao mapa original de Quirkbound.
Os mapas, poderes, personagens personalizados, animações, modelos, efeitos e scripts existentes são preservados.

## Conteúdo adicionado

- 6 classes: Guardião, Combatente, Arcanista, Patrulheiro, Socorrista e Infiltrador.
- 24 habilidades com recarga, custo de foco, dano, cura, escudos e mobilidade.
- 5 atributos: força, vitalidade, agilidade, inteligência e sorte.
- Níveis de 1 a 100, experiência, renome e pontos de atributo.
- 18 itens com raridades, equipamentos, consumíveis e materiais.
- 12 missões de história, coleta, combate, chefes e contratos diários.
- 9 receitas para forja, alquimia e criação de relíquias.
- 12 conquistas com cristais, títulos e progresso persistente.
- Grupos cooperativos de até 5 jogadores e bônus de experiência.
- Inventário, compra, venda, crafting e recompensa diária.
- Identificação automática de NPCs e inimigos já existentes.
- Interface própria para computador e celular.
- Salvamento automático com DataStore e validação de ações no servidor.
- Configuração `ProceduralVoxelWorldEnabled = false` para controlar a geração voxel.

## Organização no Roblox Studio

    ReplicatedStorage
      AuroraRPG
        Shared
          GameConfig
          ClassDefinitions
          ItemDefinitions
          AbilityDefinitions
          QuestDefinitions
          RarityDefinitions
          RegionDefinitions
          RecipeDefinitions
          AchievementDefinitions
        Remotes
          Action
          StateChanged
          Notification
          RequestState

    ServerScriptService
      AuroraRPG
        AuroraRPGBootstrap
        Services
          ProfileService
          ProgressionService
          InventoryService
          QuestService
          PartyService
          CombatService
          NPCService
          WorldService
          CraftingService
          AchievementService

    StarterPlayer
      StarterPlayerScripts
        AuroraRPGClient

## Controles

- **M** abre e fecha o menu completo de RPG.
- **Clique esquerdo** ataca um inimigo reconhecido pelo sistema.
- **F** executa um ataque pesado.
- **1, 2, 3 e 4** ativam habilidades desbloqueadas.
- Em dispositivos móveis, o botão **RPG** abre o menu.

## Salvamento no Roblox Studio

Para testar o salvamento persistente, publique a experiência e ative
**Game Settings → Security → Enable Studio Access to API Services**.
Sem essa opção, os jogadores ainda recebem um perfil temporário para testes.

## Integração de inimigos e NPCs

O sistema verifica primeiro as pastas existentes `Workspace.World.Entities`,
`Workspace.World.Interactable`, `Workspace.World.MissionsObjects`, `Workspace.Alive`
e similares. Também aceita as tags `RPGEnemy` e `RPGNPC` do `CollectionService`.

Para configurar um NPC manualmente, adicione um atributo `RPGRole` com um dos valores:

- `Enemy`: combate, experiência, ouro e drops.
- `QuestGiver`: interação e missões.
- `Merchant`: acesso ao comércio.

Inimigos também podem receber os atributos `RPGLevel` e `RPGRank`, usando
`Normal`, `Elite` ou `Boss`.

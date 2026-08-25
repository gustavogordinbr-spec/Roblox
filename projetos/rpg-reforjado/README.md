# RPG Reforjado: melhoria integrada do jogo original

Este projeto corrige o conteúdo existente de `rpg.rbxl` sem substituir o mapa,
os NPCs, as interfaces originais ou as 16 missões já presentes.

## Melhorias

- Combate validado no servidor, hitbox por sobreposição, combo de cinco golpes,
  dano baseado em atributos, crítico, defesa e proteção contra remotes inválidos.
- Correção da colisão entre `Energia` como recurso e como atributo-base:
  `EnergiaBase` agora representa o atributo, enquanto `Energia` permanece a barra.
- Regeneração econômica, sprint com gasto de energia e velocidade autoritativa,
  esquiva com cooldown, bloqueio e efeitos voxel limitados.
- Progressão, cap de nível e tiers de XP corrigidos; os atributos crescem
  automaticamente e proporcionalmente ao nível, à classe e à raça, sem pontos
  manuais. Subir de nível também recupera parte da vida e da energia.
- 16 contratos de ranks D/C/B/A/S, requisitos claros, recompensas corrigidas,
  prevenção de progresso duplicado e restauração da missão ativa ao reconectar.
- Compatibilidade com a espada e o bandido originais: `DanoBase` volta a causar
  dano, SwordScripts duplicados não duplicam golpes e recompensas configuradas
  como `Money` passam a virar `Dinheiro`.
- Inteligência artificial com patrulhamento, visão, memória, investigação,
  pathfinding, perseguição preditiva, ameaça, cooperação entre inimigos, retorno
  à área de origem, movimentação lateral e golpes pesados de elites e chefes.
- Proteção durante esquiva/bloqueio e reaparecimento automático dos inimigos.
- Salvamento profundo, migração segura, autosave e proteção contra sobrescrita
  quando o carregamento do DataStore falha.
- 20 classes jogáveis e 12 raças realmente funcionais; multiplicadores de classe
  e linhagem alteram vida, energia, dano, defesa, crítico e regeneração.
- Cada jogador nasce com uma raça aleatória. O códice mostra raridade, passiva,
  bônus, penalidades e chances; oferece 3 consultas iniciais, +1 por dia,
  proteção contra azar e novas consultas por 120 moedas obtidas no próprio jogo.
- Aparência persistente com 6 penteados, 12 cores de cabelo, 10 cores de olhos,
  10 tons de pele, 7 vestimentas e pré-visualização tridimensional.
- Cosméticos raciais visíveis para todos: orelhas, folhas, runas, cristais,
  chifres, barbatanas, asas, caudas, auréolas e auras configuráveis.
- HUD e contratos redesenhados em estilo medieval: madeira, pergaminho, bronze,
  tipografia clássica e códice acessível por um pequeno selo. O hub moderno e a
  barra inferior foram removidos.
- Recursos aproveitados de Quirkbound: biblioteca Maid, movimento direcional,
  inclinação corporal, passos por material e animações de combate/corrida.

## Atalhos

| Tecla | Ação |
| --- | --- |
| `Shift` | Correr |
| `Q` | Esquiva |
| `F` | Defender |
| `V` | Personalização e linhagem |
| `E` | Atributos automáticos |
| `J` | Missões |
| `C` | Classes |

Os IDs de animação importados pertencem aos assets encontrados no Quirkbound.
Caso Roblox restrinja algum asset por propriedade, publique uma cópia sob a sua
conta/grupo e atualize o `AnimationId` correspondente.

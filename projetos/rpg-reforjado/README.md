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
- Progressão, cap de nível e tiers de XP corrigidos; pontos de atributo por nível,
  ranks D/C/B/A/S e 16 missões com requisitos e persistência.
- Compatibilidade com a espada e o bandido originais: `DanoBase` volta a causar
  dano, SwordScripts duplicados não duplicam golpes e recompensas configuradas
  como `Money` passam a virar `Dinheiro`.
- Inteligência artificial de inimigos otimizada, proteção durante bloqueio e
  reaparecimento automático dos goblins para permitir concluir as missões.
- Salvamento profundo, migração segura, autosave e proteção contra sobrescrita
  quando o carregamento do DataStore falha.
- 20 classes jogáveis e 12 raças; os multiplicadores de classe agora realmente
  alteram dano, defesa, crítico e atributos derivados.
- HUD original modernizado, quadro de missões, seletor de classes, ficha de
  personagem, notificações, atalhos de combate e controles responsivos.
- Recursos aproveitados de Quirkbound: biblioteca Maid, movimento direcional,
  inclinação corporal, passos por material e animações de combate/corrida.

## Atalhos

| Tecla | Ação |
| --- | --- |
| `Shift` | Correr |
| `Q` | Esquiva |
| `F` | Defender |
| `E` | Atributos |
| `J` | Missões |
| `C` | Classes |

Os IDs de animação importados pertencem aos assets encontrados no Quirkbound.
Caso Roblox restrinja algum asset por propriedade, publique uma cópia sob a sua
conta/grupo e atualize o `AnimationId` correspondente.

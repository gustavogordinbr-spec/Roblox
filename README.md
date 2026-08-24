# AURORA FRATURADA
## RPG de ação cooperativo para Roblox

> Um mundo de fantasia que se quebrou em ilhas suspensas depois de uma tempestade de energia antiga. Cada região muda conforme os jogadores exploram, limpam fendas, derrotam chefes e recuperam fragmentos da Aurora.

## Visão do jogo

**Aurora Fraturada** é um RPG de ação multiplayer em terceira pessoa, com combate rápido, exploração de mundo semiaberto e progressão baseada em escolhas de estilo de luta — não em classes presas.

O objetivo é criar um RPG que pareça grande e vivo sem depender de um mapa enorme carregado de uma vez. O mundo é formado por regiões conectadas, cada uma com vilas seguras, masmorras, eventos, monstros e segredos. A base técnica será uma experiência Roblox .rbxl, organizada para receber sistemas e conteúdo sem precisar reescrever o jogo inteiro.

## Os pilares

1. **Combate que recompensa habilidade** — esquiva, bloqueio, contra-ataque, alcance e leitura do inimigo importam.
2. **Construção de personagem livre** — o jogador combina arma, origem, afinidade e habilidades; não escolhe uma classe definitiva.
3. **Exploração cooperativa** — atividades funcionam sozinho, mas chefes, fendas e masmorras ficam mais interessantes em grupo.
4. **Mundo que muda** — eventos e regiões tomadas por corrupção alteram inimigos, recompensas e caminhos.
5. **Progresso justo** — cosméticos e conveniência nunca compram dano, nível ou chance de vitória.

## Fantasia e história

Há séculos, a **Aurora** era uma força que mantinha o céu, a natureza e a magia conectados. Uma guerra tentou usá-la como arma e causou a **Fratura**: partes do continente foram erguidas para o céu e outras foram consumidas por névoa.

O jogador é um **Vínculo**, alguém capaz de tocar fragmentos da Aurora sem ser destruído. Ele começa em **Vila Lúmen**, a última cidade protegida, e passa a recuperar territórios, salvar sobreviventes e descobrir quem causou a Fratura — e por quê.

A história deve ser apresentada por missões, cenas curtas, NPCs memoráveis e decisões de campanha. Nenhuma escolha deve apagar conteúdo importante; elas mudam relações, diálogos, recompensas secundárias e o estado visual de algumas regiões.

## Loop principal

1. Receber ou descobrir uma missão em uma região.
2. Explorar, lutar, coletar materiais e encontrar eventos.
3. Derrotar inimigos, elites ou um chefe.
4. Ganhar experiência, itens, recursos e reputação.
5. Melhorar arma, afinidade ou habilidades.
6. Liberar nova região, masmorra, desafio ou parte da história.
7. Voltar mais forte para lidar com fendas e chefes em grupo.

## Combate

O combate será em tempo real, com sensação de ação e decisões simples de entender.

### Ações universais

- Ataque leve: sequência rápida e segura.
- Ataque pesado: quebra guarda, causa mais impacto e abre inimigos.
- Esquiva: usa vigor; tem janela curta de invencibilidade.
- Bloqueio: reduz dano e consome postura.
- Contra-ataque: bloqueio no tempo certo atordoa inimigos vulneráveis.
- Salto e ataque aéreo: útil contra certos monstros e para movimentação.
- Habilidades: quatro espaços ativos, com custo e recarga.
- Suprema: habilidade forte carregada por combate e objetivos.

### Recursos

| Recurso | Função |
|---|---|
| Vida | chega a zero = derrota temporária |
| Vigor | esquiva, corrida, ataques pesados |
| Postura | defesa; quando zerada, o personagem fica vulnerável |
| Foco | uso de habilidades e efeitos especiais |
| Carga Aurora | alimenta a Suprema |

O servidor será sempre a autoridade de dano, alcance, esquiva, inventário e recompensas. O cliente só cuida de input, câmera, animações e efeitos visuais.

## Construção do personagem

Em vez de classes rígidas, o jogador monta uma identidade de combate com quatro partes:

| Parte | Exemplos | Papel |
|---|---|---|
| Arma | espada, lança, manoplas, arco, grimório | ataques básicos e movimento |
| Afinidade | brasa, maré, vento, pedra, eclipse | efeitos e habilidades |
| Origem | guardião, errante, arcanista, caçador | bônus inicial e narrativa |
| Relíquias | amuletos e artefatos | modificadores de build |

Exemplo: uma pessoa pode usar **lança + vento + caçador**, criando uma build móvel que marca inimigos e acerta de longe. Mais tarde, pode trocar de arma e testar outro estilo sem apagar o personagem.

## Mundo inicial

### 1. Vila Lúmen — hub seguro

- NPCs, loja, forja, missões, grupo e quadro de fendas.
- Personalização visual e ponto de encontro dos jogadores.
- Não terá combate PvP.

### 2. Bosque de Cinzas — primeira região

- Floresta corrompida, ruínas e rios rasos.
- Ensina combate, coleta, eventos e mini-chefes.
- Chefe: **Cervo Carbonizado**, guardião transformado pela Fratura.

### 3. Falésias do Vento Partido

- Penhascos, pontes quebradas, cavernas e ilhas pequenas.
- Introduz plataformas, inimigos aéreos e eventos de escolta.
- Masmorra: **Observatório Caído**.

### 4. Cidade Submersa de Nereia

- Ruínas inundadas, canais e mecanismos antigos.
- Combina puzzles leves, criaturas aquáticas e escolhas de facção.
- Chefe de região: **A Voz do Abismo**.

As regiões futuras podem ser adicionadas sem quebrar as já existentes.

## Conteúdo multiplayer

- Grupos de até 4 jogadores.
- Partida pública, convite de amigos ou solo.
- Eventos de mundo: fendas, caravana, invasão e caça de elite.
- Masmorras com salas, objetivos e chefe final.
- Reanimação de aliados e escalonamento de vida dos inimigos por grupo.
- PvP apenas em modos opcionais separados e nunca necessário para evoluir.

## Progressão

A progressão deve fazer o jogador sentir evolução sem virar números impossíveis.

- **Nível de Vínculo:** libera regiões, habilidades e equipamentos.
- **Maestria de arma:** melhora domínio de cada tipo de arma.
- **Afinidade:** libera variações elementais e passivos.
- **Reputação:** abre missões, lojas e cosméticos por região.
- **Relíquias:** alteram a forma de jogar, não apenas o dano.
- **Dificuldades de masmorra:** desafio maior com recompensas melhores.

## Inimigos e chefes

Cada inimigo precisa de uma função clara: avançar, pressionar, atirar, controlar área, proteger ou curar.

Chefes devem ter:

- ataques reconhecíveis antes de acontecerem;
- fases curtas que mudam o combate;
- pontos de fraqueza e oportunidades de contra-ataque;
- recompensas únicas;
- escalonamento para solo e grupo.

## Direção visual e áudio

- Fantasia estilizada, limpa e legível — formas marcantes, sem excesso de partículas.
- Contraste forte entre áreas seguras, natureza viva e corrupção.
- Efeitos visuais bonitos, mas com limite de partículas para mobile.
- Música mais calma na exploração e intensa em chefes/fendas.
- Interface escura, simples e rápida; prioridade para vida, vigor, habilidades e objetivos.

## Escopo da primeira versão jogável (MVP)

A primeira versão não deve tentar ser o jogo completo. Ela precisa provar que o combate e a exploração são divertidos.

- Vila Lúmen pequena.
- Bosque de Cinzas completo.
- 1 arma: espada.
- 2 afinidades: brasa e vento.
- 6 inimigos comuns, 2 elites e 1 chefe.
- Missões principais e repetíveis.
- Grupo de até 4 jogadores.
- Inventário básico, drops e forja simples.
- Salvamento de nível, itens e progresso de missão.
- 1 evento de fenda.
- Interface funcional para PC e mobile.

Quando essa versão estiver divertida e estável, entram novas armas, regiões, masmorras, relíquias e narrativa.

## Organização proposta no Roblox Studio

    ReplicatedStorage
      Shared
        Configs
        Remotes
        Types
        Modules
    ServerScriptService
      Services
        PlayerDataService
        CombatService
        InventoryService
        QuestService
        EnemyService
        WorldEventService
        PartyService
    ServerStorage
      EnemyTemplates
      ItemTemplates
      RegionData
    StarterPlayer
      StarterPlayerScripts
        Controllers
    StarterGui
      UI
    Workspace
      Regions
        LumemVillage
        AshenWoods
      Spawners
      Dungeons

## Regras técnicas desde o início

- Usar --!strict em novos scripts.
- Deixar dados de armas, inimigos, itens e missões em tabelas/configurações, não espalhados em scripts.
- Não confiar no cliente para dano, dinheiro, itens, XP ou teleporte.
- Validar todo RemoteEvent/RemoteFunction no servidor.
- Separar lógica de jogo, dados e efeitos visuais.
- Criar logs e testes simples para combate, inventário, missão e salvamento.
- Otimizar para PC e celular: streaming, distância de renderização, pooling de efeitos e IA por raio.
- Salvar dados com estrutura versionada para permitir atualizações futuras.

## Próximo marco

Criar o arquivo .rbxl inicial com a estrutura acima, um mapa de teste em Vila Lúmen, personagem com espada, um inimigo de treino e o ciclo completo:

**entrar > atacar > receber recompensa > salvar > sair > entrar novamente com o progresso mantido.**

Esse é o primeiro pedaço que precisa ficar sólido antes de crescer o mundo.

## Implementação atual: Quirkbound RPG

A pasta [rpg](rpg/README.md) contém a camada completa de RPG integrada ao mapa original Quirkbound, com classes, habilidades, progressão, inventário, missões, crafting, conquistas, grupos multiplayer e interface.

O arquivo `.rbxl` preserva todos os modelos e efeitos do mapa original. Os scripts versionados neste repositório correspondem à versão incorporada ao arquivo.

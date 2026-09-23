# One of Us

Metroidvania 2D de exploração vertical, desenvolvido em Godot 4 para a unidade curricular de
**Projeto de Jogo 2D** (Mestrado em Desenvolvimento de Jogos Digitais, Universidade de Aveiro).
Tema: *Destroy Yourself*.

Um humano cai nos esgotos de uma metrópole distópica, onde vivem duas sociedades de mutantes em
guerra. Para voltar à superfície tem de se mutar: injetar o ADN da facção que o acolheu e
substituir o próprio corpo, parte a parte. A árvore de progressão é literalmente o corpo do
protagonista — ficar mais forte e ficar menos humano são a mesma ação.

> ⚠️ **Estado: pré-produção.** O projeto está configurado mas ainda não tem gameplay. Correr o
> projeto abre uma janela vazia.

## Como abrir

O projeto Godot **não está na raiz do repositório** — está na subpasta `Projeto/`.

1. Instalar o **Godot 4.7.x** (versão standard, não .NET — o projeto é GDScript puro).
2. No Project Manager, *Import* → escolher `Projeto/project.godot`.
3. F5 corre a cena principal (`res://scenes/main.tscn`), F6 corre a cena aberta.

Na primeira abertura o Godot gera a pasta `Projeto/.godot/` com a cache de importação. Essa pasta
não é versionada e pode ser apagada sem perder trabalho.

## Estrutura

```
.                      raiz do repositório
├── LICENSE
├── README.md
└── Projeto/           raiz do projeto Godot
    ├── project.godot
    ├── scenes/        cenas do jogo
    │   ├── levels/    salas e níveis
    │   ├── actors/    jogador, inimigos, NPCs
    │   └── ui/        menus e HUD
    ├── scripts/
    │   └── components/  componentes reutilizáveis (HealthComponent, Hitbox, Hurtbox…)
    ├── resources/     ficheiros .tres de dados e balanceamento
    └── assets/        sprites, audio, fonts
```

## Decisões de arquitetura

Esta secção existe para que qualquer pessoa da equipa perceba **porquê**, e não só o quê.

### Renderer: Compatibility, não Forward+

O projeto usa `gl_compatibility` em desktop **e** em mobile. A unidade curricular tem como alvo
móvel e desktop, e o Forward+ (Vulkan) não corre em hardware Android mais antigo nem na web.
Tudo o que o Forward+ acrescenta sobre o Compatibility — SDFGI, SSAO, volumetrics — é
exclusivamente 3D, portanto num jogo 2D a troca não custa nada visualmente.

Quem alterar isto tem de alterar as **duas** definições: `rendering/renderer/rendering_method` e
`rendering/renderer/rendering_method.mobile`. Mudar só a primeira faz com que as builds Android
voltem silenciosamente ao renderer Mobile.

### Resolução: viewport 1920×1080, janela de teste 1280×720

A arte é **2D ilustrada, não pixel art**, por isso não há restrições de escala inteira nem
necessidade de filtro Nearest. Uma base de 1920×1080 faz com que 1 pixel de arte corresponda a 1
pixel num monitor Full HD, o que simplifica dimensionar sprites e cenários.

O modo de stretch é `canvas_items` com aspeto `expand`: em ecrãs de rácio diferente mostra-se mais
(ou menos) mundo na horizontal, em vez de aparecerem barras pretas. É a escolha certa para
telemóveis, cujos rácios variam muito (16:9, 19.5:9, 20:9).

### Input: ações nomeadas com teclas físicas

Nenhum script deve ler teclas diretamente. Tudo passa pelo Input Map, com `Input.get_axis()` e
`Input.is_action_just_pressed()`. Isto permite remapear controlos sem tocar em código de gameplay.

As teclas estão registadas como **físicas** (`physical_keycode`): a tecla identificada pela sua
posição no teclado, não pela letra impressa. Assim o WASD continua a ser WASD num teclado AZERTY
francês ou QWERTZ alemão — relevante porque o jogo vai ser testado em máquinas que não são as
nossas.

| Ação | Teclado | Comando |
|---|---|---|
| `move_left` / `move_right` | A / D, setas | stick esquerdo (eixo 0) |
| `move_up` / `move_down` | W / S, setas | stick esquerdo (eixo 1) |
| `jump` | Espaço | A / Cross |
| `attack_light` | J | X / Square |
| `attack_heavy` | K | Y / Triangle |
| `dash` | Shift | RB / R1 |
| `interact` | E | B / Circle |
| `pause` | Escape | Start |

### Camadas de colisão

Estão todas nomeadas em Project Settings ▸ Layer Names ▸ 2D Physics. Usar sempre o nome no
Inspector, nunca o número no código.

| # | Nome | # | Nome |
|---|---|---|---|
| 1 | `world` | 6 | `player_hurtbox` |
| 2 | `player` | 7 | `enemy_hurtbox` |
| 3 | `enemy` | 8 | `interactable` |
| 4 | `player_hitbox` | 9 | `one_way_platform` |
| 5 | `enemy_hitbox` | 10 | `camera_bounds` |

Separar *hitbox* (o que causa dano) de *hurtbox* (o que recebe dano) permite que um ataque
atravesse um inimigo sem o empurrar, e que inimigos se atinjam uns aos outros se quisermos.

## Convenções de código

- **GDScript com tipagem estática** em variáveis, parâmetros e retornos. Não é estilo: o Godot
  gera bytecode mais rápido para código tipado.
- **Composição, não herança.** Comportamentos como vida, dano ou movimento vivem em nós-componente
  reutilizáveis, não numa cadeia de subclasses.
- **"Call down, signal up":** um nó pai pode chamar métodos dos filhos; um filho comunica para cima
  por sinal. Nunca `get_node("../..")`.
- Valores de balanceamento em `@export` ou em `Resource`, nunca constantes no meio da lógica.
- Nomes em inglês; `snake_case` para ficheiros, funções e variáveis; `PascalCase` para classes e nós.
- Física e movimento em `_physics_process()`, visuais em `_process()`.

## Git

- `*.import` e `*.uid` **são versionados.** Sem eles, quem clonar o repositório reimporta tudo e as
  referências entre recursos partem-se.
- `Projeto/.godot/` não é versionado: é cache local, regenerada na primeira abertura.
- `export_presets.cfg` é versionado (presets partilhados); `export_credentials.cfg` não é
  (contém chaves de assinatura).
- Nunca mover nem renomear recursos fora do editor. O painel FileSystem do Godot atualiza as
  referências e os UIDs; o explorador de ficheiros do sistema não.

## Licença

Ver [LICENSE](LICENSE).

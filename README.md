# P2D

Aventura de plataformas 2D, desenvolvida em Godot 4 para a unidade curricular de
**Projeto de Jogo 2D** (Mestrado em Desenvolvimento de Jogos Digitais, Universidade de Aveiro).
Tema: *Destroy Yourself*. Título por decidir.

Um homem que se acha tão justo como Job acorda no inferno e tem de subir sete pecados sem poder
atacar, enquanto cada demónio lhe oferece um atalho e o jogo toma nota do que ele aceita.

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
    ├── tests/         testes que correm sem janela (ver abaixo)
    └── assets/        sprites, audio, fonts
```

Os testes de `Projeto/tests/` correm sem janela, a partir da raiz do repositório, e terminam com
código 0 se passarem e 1 se falharem (`godot` é o executável do Godot 4.7):

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_height.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_movement_stats.gd
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

## Player

Cena em `scenes/actors/player.tscn`, com o script `scripts/player.gd`. É um `CharacterBody2D`
com uma caixa de colisão de 48 × 96 px e a origem nos pés: para pôr o player num nível, a origem
fica na linha do chão. Está na camada `player` e colide com `world` e `one_way_platform`.

**Sensação: fast paced.** Uma velocidade só, sem botão de correr. O player arranca quase logo e
para depois de um deslize curto. O peso da personagem vem da apresentação (aterragem, som,
câmara), não de controlos lentos. As variações de velocidade vêm do jogo: o crucifixo e a preguiça
abrandam.

Os valores afinam-se no Inspector, no recurso `resources/player_movement_stats.tres`. Mudá-lo muda
o player em todas as cenas. A coluna "Na prática" diz o que o jogo faz, frame a frame, a 60 frames
por segundo.

| Valor | Agora | Na prática |
|---|---|---|
| Max Run Speed | 720 px/s | atravessa o ecrã em cerca de 2,7 s |
| Time To Max Speed | 0,1 s | anda 42 px até chegar à velocidade máxima |
| Time To Stop | 0,15 s | desliza 48 px depois de largar a tecla |
| Fall Gravity | 7850 px/s² | chega à queda máxima em cerca de 0,18 s |
| Max Fall Speed | 1400 px/s | a velocidade máxima a cair |
| Jump Height | 240 px | 2,5 alturas do player; o salto chega exatamente a esta altura |
| Time To Peak | 0,35 s | do chão ao topo, arredondado a frames inteiros (1/60 s); a descer é mais rápido, cerca de 0,27 s |
| Min Jump Height | 80 px | o salto mais baixo: um toque rápido sobe cerca de 88 px, menos do que a altura do player |

Para quem desenha níveis: a sala `scenes/levels/test_room.tscn` (F6) serve para experimentar o
movimento. O salto sobe entre cerca de 88 px, com um toque rápido, e 240 px, com o botão seguro até
ao topo; quanto mais tempo se segura, mais alto. Largar o botão a subir torna a gravidade mais
forte, e é isso que encurta o salto. O dano de queda, quando houver SP, mede-se pela altura da
queda, porque a velocidade a cair tem máximo.

Para quem fizer molas, empurrões para cima ou plataformas que sobem: a subir sem o botão de saltar
carregado, o player trava como num salto curto, mesmo que a subida não venha de um salto. Ao sair de
uma plataforma que se move, o `CharacterBody2D` soma por omissão a velocidade dela à do player, por
isso também conta. Quando a primeira destas coisas entrar, o player tem de passar a distinguir as
duas subidas.

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

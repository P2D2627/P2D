# P2D

Aventura de plataformas 2D desenvolvida em Godot 4 para a unidade curricular de
**Projeto de Jogo 2D** (Mestrado em Desenvolvimento de Jogos Digitais, Universidade de Aveiro).
Tema: *Destroy Yourself*. Título por decidir.

Um homem que se considera tão justo como Job acorda no inferno e tem de subir sete níveis, um por
pecado capital, sem poder atacar. Cada demónio oferece-lhe um atalho, e o jogo regista o que ele
aceita.

> **Estado:** a personagem jogável já anda, salta e tem controlo no ar, desliza nas paredes e salta
> delas, e o salto tolera pedidos ligeiramente fora de tempo. Existe apenas uma sala de teste: ainda
> não há níveis, câmara, arte nem som.

Este documento tem duas partes. A primeira descreve, para toda a equipa, o que já pode ser
experimentado e as medidas que servem o desenho de níveis. A segunda, "Para quem programa",
documenta a organização técnica do projeto.

## Experimentar

1. Instalar o Godot 4.7.x, versão standard (não a versão .NET).
2. No Project Manager, importar `Projeto/project.godot`. O projeto Godot encontra-se na subpasta
   `Projeto/`, e não na raiz do repositório.
3. Abrir `scenes/levels/test_room.tscn` e premir F6. A sala tem um bloco elevado, com duas bordas,
   para experimentar os saltos a partir de uma borda, e uma chaminé de 120 px entre a parede
   esquerda e um pilar suspenso, por baixo do qual se entra a andar. A tecla F5 abre a cena
   principal, que ainda está vazia.

| Ação | Teclado | Comando |
|---|---|---|
| Andar | A / D ou setas | stick esquerdo |
| Saltar | Espaço | A / Cross |
| Deslizar numa parede | no ar, A / D ou setas contra a parede | stick esquerdo contra a parede |
| Saltar de uma parede | no ar, Espaço encostado à parede | A / Cross encostado à parede |

## Mecânicas implementadas

A personagem mede 48 px de largura e 96 px de altura, e estas duas dimensões servem de unidade às
medidas desta secção. Todos os valores foram medidos no jogo, cuja física corre a 60 passos por
segundo, seja qual for o monitor.

### Deslocação horizontal

A personagem tem uma única velocidade, 720 px/s, sem botão de corrida, e percorre a largura de um
ecrã Full HD (1920 px) em menos de 3 segundos. Atinge essa velocidade em 0,1 s e, quando a tecla é libertada, desliza 48 px (uma
largura) até parar. A sensação de peso fica a cargo da apresentação (animação de aterragem, som e
câmara), para que os controlos se mantenham rápidos. As reduções de velocidade resultam de
elementos do jogo, como o crucifixo e o nível da preguiça.

### Queda

A velocidade de queda aumenta até um máximo de 1400 px/s, atingido após uma queda de 143 px, cerca
de uma altura e meia. Como a velocidade de queda é limitada, o dano de queda, quando for
implementado, será calculado a partir da altura de onde a personagem cai.

### Salto de altura variável

Com o botão premido até ao ponto mais alto, o salto atinge 240 px, duas vezes e meia a altura da
personagem. Com o botão largado logo, o salto mínimo sobe 88 px; com o botão premido durante 0,1 s,
sobe 153 px. Entre estes valores, a altura depende do tempo durante o qual o botão é mantido. A subida demora 0,35 s e a descida cerca de
0,25 s, o que evita que o salto pareça flutuar.

O salto é definido pela altura e pelo tempo até ao ponto mais alto, a partir dos quais se calculam
a gravidade e a velocidade inicial (Pittman, 2016). Assim, o salto completo atinge exatamente a
altura definida. Libertar o botão durante a subida aumenta a gravidade, o que encurta o salto.

### Controlo aéreo

Durante o salto ou a queda, a personagem pode mudar de direção com 70 % da aceleração que tem no
chão. Acelerar, travar e inverter o sentido demoram, por isso, cerca de uma vez e meia o tempo
correspondente no chão. Ao largar a direção a meio de um salto em corrida, a personagem desliza
71 px até parar, contra 48 px no chão.

O controlo aéreo permite corrigir um salto mal calculado. O jogo avalia o jogador pelas escolhas
que faz, e mortes causadas pelos controlos levariam a aceitar atalhos por frustração. O valor de
70 % é provisório e será afinado quando existirem câmara e níveis.

### Tolerâncias do salto

Um salto pedido uma fração de segundo fora de tempo é aceite. O objetivo é que um salto que o
jogador sente como dado a tempo não falhe sem razão aparente, o que se confundiria com falta de
resposta dos controlos; o efeito será confirmado em playtest. As tolerâncias beneficiam também quem
reage mais devagar.

- Tolerância de borda (*coyote time*): durante 0,07 s (4 passos de física) depois de sair de uma
  plataforma sem saltar, a personagem ainda pode saltar. A correr, o último salto aceite parte com a
  parte de trás do corpo 37 a 48 px para lá da borda, conforme o ponto de onde a corrida começa.
- Tolerância de aterragem (*jump buffer*): um salto pedido até 0,07 s antes de aterrar fica guardado
  e é executado no primeiro instante em contacto com o chão. A altura continua a depender do tempo
  durante o qual o botão é mantido: um toque dado antes da aterragem produz o salto mínimo.

Durante a tolerância de borda, a gravidade continua a atuar, para que a personagem não pareça
caminhar no ar. Por isso, o último salto aceite parte 13 px abaixo da borda e sobe 227 px acima
dela, menos 13 px do que um salto dado na borda. Os dois tempos são provisórios e serão afinados
quando existirem câmara e níveis.

### Paredes

No ar, encostada a uma parede, a personagem pode deslizar e saltar da parede.

O deslize começa quando o jogador empurra a personagem contra a parede e mantém-se sem que a
direção continue premida. Termina quando o jogador empurra para o lado oposto, salta, chega ao chão
ou a parede acaba. Na descida, a velocidade fica limitada a 350 px/s, um quarto da velocidade
máxima de queda: se a personagem cair mais depressa, trava de imediato para esse valor; se cair
mais devagar, como no topo de um salto, continua a acelerar até ele. A 350 px/s, desce uma altura
do corpo em 0,28 s. Na subida, não há travão. Dispensar a direção premida durante o deslize segue
as Game Accessibility Guidelines (s.d.-a), que recomendam não obrigar o jogador a manter teclas
premidas.

O salto da parede é dado com a tecla de saltar sempre que a personagem toca numa parede no ar,
empurrando-a ou não. A personagem sai para o lado oposto à parede, à velocidade máxima da corrida e
com a altura de um salto completo (240 px). Como a direção do salto é sempre a de afastamento da
parede, numa chaminé basta premir a tecla de saltar, o que mantém os controlos simples (Game
Accessibility Guidelines, s.d.-b). Durante 0,2 s após o salto, a corrida não responde, e a
personagem afasta-se 144 px da parede. É este bloqueio que impede a subida de uma parede isolada:
mesmo com a melhor combinação de teclas, cada salto devolve a personagem à mesma parede 96 px mais
abaixo. Entre duas paredes próximas, numa chaminé, a subida não tem limite; na chaminé da sala de
teste, com 120 px de largura, cada salto sobe 90 px premindo apenas a tecla de saltar. A regra de
que uma parede isolada não se sobe por saltos da parede aguarda a confirmação do grupo.

Tal como na borda de uma plataforma, existe uma tolerância: durante 0,07 s depois de largar uma
parede, a tecla de saltar ainda produz o salto da parede. Os valores do deslize e do bloqueio são
provisórios e serão afinados quando existirem câmara e níveis.

## Medidas para o desenho de níveis

| Medida | Valor | Em dimensões da personagem |
|---|---|---|
| Altura do salto completo (altura máxima dos pés) | 240 px | 2,5 alturas |
| Altura do salto com o botão premido durante 0,1 s | 153 px | 1,6 alturas |
| Altura do salto mínimo, com o botão largado logo | 88 px | menos de 1 altura |
| Vão mais largo que um salto em corrida atravessa, de borda a borda | 479 a 490 px | 10 larguras |
| Vão mais largo, com o salto dado no último instante da tolerância de borda | 520 a 531 px | 11 larguras |
| Altura máxima, acima da borda, do salto dado no último instante da tolerância de borda | 227 px | 2,4 alturas |
| Tempo no ar num salto completo | 0,6 s | |
| Distância de travagem no chão | 48 px | 1 largura |
| Distância de travagem no ar | 71 px | 1,5 larguras |
| Queda até à velocidade máxima | 143 px | 1,5 alturas |
| Altura máxima de um salto completo junto a uma parede seguido de um salto da parede | 475 px | 4,9 alturas |
| Distância à parede no ponto mais alto desse salto, com a direção para fora | 252 px | 5,3 larguras |
| Distância de um salto da parede, com a direção para fora, até voltar à altura de partida | 444 px | 9,3 larguras |
| Chaminé mais larga que se sobe premindo apenas a tecla de saltar ao tocar na parede | 222 px | 4,6 larguras |
| Chaminé mais larga que se sobe premindo a tecla 0,07 s depois de tocar na parede | 178 px | 3,7 larguras |
| Chaminé mais larga que se sobe com a melhor combinação de teclas | 480 px | 10 larguras |
| Subida por salto numa chaminé de 120 px, premindo apenas a tecla de saltar | 90 px | quase 1 altura |
| Descida por salto numa parede isolada, com a melhor combinação de teclas | 96 px | 1 altura |
| Tempo de deslize por cada altura do corpo | 0,28 s | |

- Os vãos máximos variam alguns píxeis com o ponto de onde a corrida começa, porque a física avança
  em passos de 1/60 s; foram medidos a partir de 12 pontos de partida, e a tabela dá o menor e o
  maior valor.
- Longe de paredes, uma plataforma a 240 px só é alcançável com um salto completo. Os níveis devem
  deixar margem.
- A personagem ainda consegue saltar com parte do corpo fora da plataforma, e os vãos medidos já
  contam com isso.
- A tolerância de borda é uma margem para o jogador, e não alcance para o nível. Um vão que deva ser
  sempre transponível não deve passar de 431 px: o menor vão máximo medido (479 px) menos uma
  largura do corpo, para que o salto ainda passe se for dado até uma largura antes da borda. Um vão
  que deva ser intransponível deve medir pelo menos 579 px: o maior vão medido com a tolerância
  (531 px) mais uma largura do corpo.
- Se uma opção de acessibilidade vier a alargar a tolerância de borda, o limite dos vãos
  intransponíveis terá de subir: com 0,2 s, o máximo permitido no Inspector, o vão chega aos 559 px.
- As medidas das paredes não dependem do ponto de partida, porque cada salto da parede define as
  duas velocidades da personagem.
- Uma parede que a personagem consiga tocar durante um salto aumenta a altura alcançável. Uma
  plataforma que deva ser sempre alcançável com a ajuda de uma parede não deve ficar a mais de
  379 px acima do ponto de partida: a altura medida (475 px) menos uma altura do corpo. Uma
  plataforma que deva ser inalcançável, havendo uma parede ao alcance de um salto, deve ficar a pelo
  menos 571 px: a altura medida mais uma altura do corpo.
- A altura medida junto a uma parede supõe que o jogador larga a tecla de saltar durante um só passo
  de física (1/60 s) antes de a premir para o salto da parede. Nesse passo, a personagem ainda sobe
  sem o botão premido e fica sujeita à gravidade do salto curto, razão pela qual a altura não chega
  ao dobro de um salto completo (480 px). Largando a tecla durante 4 passos (0,07 s), a altura
  máxima desce para 458 px e, durante 6 passos (0,1 s), para 446 px. Com o salto da parede dado até
  0,07 s fora do melhor momento, e a tecla largada durante um só passo, a personagem chega aos
  462 px. Todos estes valores ficam entre os dois limites anteriores (379 e 571 px).
- Uma chaminé que deva ser sempre subida não deve passar de 174 px de largura: a maior largura
  medida premindo apenas a tecla de saltar (222 px) menos uma largura do corpo. Premir a tecla
  0,07 s depois de tocar na parede reduz essa largura para 178 px, valor que a margem cobre. Uma
  chaminé que não deva ser subida deve medir pelo menos 528 px: a maior largura medida com a melhor
  combinação de teclas (480 px) mais uma largura do corpo. Entre 174 e 528 px, a subida depende da
  perícia do jogador, pelo que estas larguras devem ficar fora do caminho obrigatório, reservadas a
  desafios opcionais.
- Uma parede isolada não se sobe por saltos da parede, qualquer que seja a sua altura: cada
  salto devolve a personagem à parede 96 px mais abaixo. O topo dessa parede alcança-se como o de
  uma plataforma, com um salto normal; uma parede de 200 px, por exemplo, sobe-se assim.
- A câmara ainda não existe, e os valores serão afinados. Após cada afinação, as medidas voltam a
  ser obtidas com o `measure_movement.gd` (ver "Testes e medidas").
- Os níveis podem vir a ser construídos com tiles ou com cenário pintado. Quando o tamanho do tile
  for definido, estas medidas serão convertidas em tiles.

## Afinação do movimento

Os valores do movimento estão reunidos no ficheiro `player_movement_stats.tres`, na pasta
`resources/` do projeto Godot (`Projeto/resources/` no repositório). Abre-se no painel FileSystem
do Godot e edita-se no Inspector. As alterações aplicam-se à personagem em todas as cenas.

| Campo no Inspector | Valor atual | O que controla |
|---|---|---|
| Max Run Speed | 720 px/s | a velocidade horizontal |
| Time To Max Speed | 0,1 s | o tempo de aceleração |
| Time To Stop | 0,15 s | o tempo de travagem e, por consequência, o deslize |
| Air Control | 0,7 | a fração da aceleração e da travagem do chão que se mantém no ar (1: igual ao chão; 0: nenhuma, e empurrar para o lado oposto deixa de soltar a personagem de uma parede) |
| Fall Gravity | 7850 px/s² | a aceleração da queda |
| Max Fall Speed | 1400 px/s | a velocidade máxima de queda |
| Jump Height | 240 px | a altura do salto completo |
| Time To Peak | 0,35 s | o tempo até ao ponto mais alto do salto |
| Min Jump Height | 80 px | a altura do salto mínimo; um toque sobe alguns px acima deste valor |
| Coyote Time | 0,07 s | o tempo, depois de sair de uma plataforma sem saltar ou de largar uma parede, durante o qual o salto ainda é aceite (0 desliga) |
| Jump Buffer Time | 0,07 s | o tempo durante o qual um salto pedido no ar fica guardado à espera de ser possível (0 desliga) |
| Wall Slide Speed | 350 px/s | a velocidade máxima de descida no deslize; a subida ao longo da parede não é travada |
| Wall Jump Lock Time | 0,2 s | o tempo, depois de um salto da parede, durante o qual a corrida não responde; com 0,15 s ou menos, uma parede isolada passa a poder ser subida |

## Referências

- Game Accessibility Guidelines. (s.d.-a). *Avoid / provide alternatives to requiring buttons to be
  held down*. https://gameaccessibilityguidelines.com/avoid-provide-alternatives-to-requiring-buttons-to-be-held-down/
- Game Accessibility Guidelines. (s.d.-b). *Ensure controls are as simple as possible, or provide a
  simpler alternative*. https://gameaccessibilityguidelines.com/ensure-controls-are-as-simple-as-possible-or-provide-a-simpler-alternative/
- Nystrom, R. (2014). *Game Programming Patterns* (capítulo "State"). Edição de autor.
  https://gameprogrammingpatterns.com/state.html
- Pittman, K. (2016). *Math for Game Programmers: Building A Better Jump*. Game Developers
  Conference. https://www.gdcvault.com/play/1023559/Math-for-Game-Programmers-Building

## Para quem programa

### Estrutura

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
    ├── tests/         testes e medidas que correm sem janela
    │   └── support/   preparação comum aos testes
    └── assets/        sprites, audio, fonts
```

Na primeira abertura, o Godot gera a pasta `Projeto/.godot/` com a cache de importação. Esta pasta
não é versionada e pode ser apagada sem perda de trabalho.

### Testes e medidas

Os scripts de `Projeto/tests/` correm sem janela, a partir da raiz do repositório (`godot` designa
o executável do Godot 4.7). Os testes terminam com o código 0 quando passam e 1 quando falham:

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_height.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_air_control.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_movement_stats.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_coyote_time.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_buffer.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_slide.gd
godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_jump.gd
```

Os testes mais recentes estendem `tests/support/player_test.gd`, que reúne a preparação comum:
plataformas, uma personagem com uma cópia própria dos valores do `.tres` e a escrita dos resultados.
Esse ficheiro não é um teste e não se corre sozinho.

O `measure_movement.gd` não verifica resultados: imprime as medidas da secção "Medidas para o
desenho de níveis", com os valores que estiverem no `.tres`. As medidas junto das bordas correm a
partir de 12 pontos de partida, 1 px entre cada um, que cobrem um passo de física à velocidade
máxima, e imprimem o menor e o maior valor.

```
godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_movement.gd
```

### A personagem por dentro

A cena é `scenes/actors/player.tscn`, com o script `scripts/player.gd`: um `CharacterBody2D` com uma
caixa de colisão de 48 × 96 px e a origem nos pés, pelo que, num nível, a origem fica na linha do
chão. Está na camada `player` e colide com `world` e `one_way_platform`. Os valores vêm de um
recurso `PlayerMovementStats` (`scripts/player_movement_stats.gd`), guardado em
`resources/player_movement_stats.tres`.

A lógica organiza-se numa máquina de estados com três estados, definida por um `enum` no
`player.gd`: no chão (`ON_FLOOR`), no ar (`IN_AIR`) e na parede (`ON_WALL`). Cada estado tem a sua
função de física, e o estado só muda em `_update_state()`, no início de cada passo de física, a
partir do resultado do último `move_and_slide()`. O chão tem prioridade. Para entrar no estado da
parede é preciso empurrar a personagem contra ela, mas para permanecer nele não, pelo que o estado
termina quando a personagem deixa de tocar na parede ou aterra. Preferiu-se o `enum` a um nó por
estado (padrão State) porque os três estados partilham a gravidade, a corrida e os contadores.
Segue-se a ordem proposta por Nystrom (2014): primeiro o `enum`, e o padrão State quando um estado
passar a ter dados que só nele fazem sentido, como agarrar bordas. As animações vão depender do
estado e da velocidade; as que tocam uma só vez (início do salto, aterragem, salto da parede) vão
ser disparadas por sinais.

- O salto define-se pelo Jump Height e pelo Time To Peak, as grandezas com que se afina, e a
  gravidade e a velocidade inicial calculam-se a partir delas (Pittman, 2016). O tempo arredonda-se
  a passos de física inteiros e a velocidade inicial leva uma correção de meio passo, para que o
  salto completo acabe exatamente na altura definida.
- O salto curto resulta de uma gravidade mais forte enquanto a personagem sobe sem o botão premido.
  Preferiu-se esta solução a cortar a velocidade de uma vez, porque a subida não trava de repente e
  a altura acompanha o tempo de botão durante a subida toda.
- No ar, a aceleração e a travagem do chão são multiplicadas pelo Air Control. Preferiu-se um
  multiplicador a dois tempos próprios para o ar: um valor chega até um playtest pedir dois, e um
  multiplicador combina com outros fatores, como um corte do controlo logo a seguir a um wall jump.
- As tolerâncias do salto são dois contadores de passos de física. O da tolerância de borda enche-se
  em cada passo no chão e esvazia-se no ar; o da tolerância de aterragem enche-se quando o botão é
  premido. O salto ocorre no passo em que há um pedido guardado e a personagem pode saltar, e
  esvazia os dois contadores, pelo que cada pedido produz um único salto. Os tempos convertem-se em
  passos inteiros, como o tempo até ao ponto mais alto, e os testes verificam os limites passo a
  passo. Preferiram-se contadores no script a nós `Timer` para que a contagem fique no mesmo código
  que decide o salto.
- O `is_on_floor()` reflete o último `move_and_slide()`. Por isso, o passo da descolagem ainda usa
  o controlo do chão, e o da aterragem ainda usa o do ar; o `test_air_control.gd` verifica-o.
- A parede deteta-se com `is_on_wall()` e `get_wall_normal()`, também a partir do último
  `move_and_slide()`. A normal indica o lado da parede e, por isso, a direção do salto da parede.
- O deslize não altera a gravidade: no estado da parede, a velocidade de descida é limitada ao Wall
  Slide Speed em cada passo, e a subida não é afetada.
- O salto da parede reutiliza o salto do chão, com a mesma altura, e acrescenta a velocidade máxima
  da corrida no sentido oposto à última parede tocada. Não é um estado: um contador de bloqueio
  anula o controlo da corrida durante o Wall Jump Lock Time, e é esse bloqueio que impede a subida
  de uma parede isolada. O `test_wall_jump.gd` verifica-o.
- A tolerância de parede é um contador como o da tolerância de borda, com o mesmo tempo (Coyote
  Time). Enche-se em cada passo no ar em que a personagem toca numa parede, guardando o lado dela,
  e esvazia-se nos passos seguintes. Quando as duas tolerâncias estão ativas, prevalece o salto da
  parede. Qualquer salto esvazia as tolerâncias e o pedido guardado, pelo que cada pedido continua
  a produzir um único salto.

Molas, empurrões para cima e plataformas que sobem exigem cuidado. A subir sem o botão de saltar
premido, a personagem trava como num salto curto, mesmo que a subida não resulte de um salto. Ao
sair de uma plataforma em movimento, o `CharacterBody2D` soma por omissão a velocidade da
plataforma à da personagem, o que produz o mesmo efeito. Quando o primeiro destes elementos for
implementado, a personagem terá de distinguir as duas subidas.

No respawn, a solução mais simples é criar uma instância nova da personagem. Reutilizar a mesma e
repor os contadores não chega: o `is_on_floor()` e o `is_on_wall()` só se atualizam no
`move_and_slide()` seguinte e, até lá, voltam a encher as tolerâncias. Com a personagem reposta no
ar, premir a tecla de saltar logo a seguir produz um salto e, se a personagem tinha morrido
encostada a uma parede, um salto da parede; com uma instância nova, não há salto em nenhum dos dois
casos. Se o respawn vier a reutilizar a personagem, deve ser um método do player, com um teste que
cubra estes dois casos.

### Decisões técnicas

Esta secção regista o motivo de cada decisão técnica.

#### Renderer: Compatibility em vez de Forward+

O projeto usa `gl_compatibility` em desktop e em mobile. A unidade curricular tem como alvo móvel e
desktop, e o Forward+ (Vulkan) não corre em hardware Android mais antigo nem na web. O que o
Forward+ acrescenta (SDFGI, SSAO, volumetrics) aplica-se apenas a 3D, pelo que um jogo 2D não perde
nada com a troca.

Uma alteração do renderer obriga a mudar as duas definições, `rendering/renderer/rendering_method` e
`rendering/renderer/rendering_method.mobile`. Mudar apenas a primeira faz com que as builds Android
voltem, sem aviso, ao renderer Mobile.

#### Resolução: viewport 1920×1080, janela de teste 1280×720

A arte é 2D ilustrada, e não pixel art, pelo que não há restrições de escala inteira nem filtro
Nearest. Com 1920×1080, um pixel de arte corresponde a um pixel num monitor Full HD, o que
simplifica o dimensionamento de sprites e cenários. O modo de stretch é `canvas_items` com aspeto
`expand`: em ecrãs com outra proporção mostra-se mais ou menos mundo na horizontal, sem barras
pretas, o que serve os telemóveis (16:9, 19.5:9, 20:9).

#### Input: ações nomeadas com teclas físicas

Nenhum script lê teclas diretamente. Todo o input passa pelo Input Map, com `Input.get_axis()` e
`Input.is_action_just_pressed()`, para que os controlos possam ser remapeados sem alterar o código
de gameplay. As teclas estão registadas como físicas (`physical_keycode`): contam pela posição no
teclado, e não pela letra impressa, pelo que o WASD se mantém num teclado AZERTY ou QWERTZ.

| Ação | Teclado | Comando |
|---|---|---|
| `move_left` / `move_right` | A / D, setas | stick esquerdo (eixo 0) |
| `move_up` / `move_down` | W / S, setas | stick esquerdo (eixo 1) |
| `jump` | Espaço | A / Cross |
| `interact` | E | B / Circle |
| `pause` | Escape | Start |

#### Camadas de colisão

As camadas estão nomeadas em Project Settings ▸ Layer Names ▸ 2D Physics. No Inspector usa-se
sempre o nome, e nunca o número no código.

| # | Nome | # | Nome |
|---|---|---|---|
| 1 | `world` | 6 | `player_hurtbox` |
| 2 | `player` | 7 | `enemy_hurtbox` |
| 3 | `enemy` | 8 | `interactable` |
| 4 | `player_hitbox` | 9 | `one_way_platform` |
| 5 | `enemy_hitbox` | 10 | `camera_bounds` |

A separação entre *hitbox* (o que causa dano) e *hurtbox* (o que recebe dano) permite que um ataque
atravesse um inimigo sem o empurrar e, se for desejado, que os inimigos se atinjam entre si.

### Convenções de código

- GDScript com tipagem estática em variáveis, parâmetros e retornos. O código tipado gera bytecode
  mais rápido.
- Composição em vez de herança: comportamentos como vida, dano ou movimento vivem em nós-componente
  reutilizáveis, e não numa cadeia de subclasses.
- "Call down, signal up": um nó pai pode chamar métodos dos filhos, e um filho comunica para cima
  por sinal. Nunca `get_node("../..")`.
- Valores de balanceamento em `@export` ou em `Resource`, e nunca como constantes no meio da lógica.
- Nomes em inglês; `snake_case` para ficheiros, funções e variáveis; `PascalCase` para classes e
  nós.
- Física e movimento em `_physics_process()`; elementos visuais em `_process()`.

### Git

- Os ficheiros `*.import` e `*.uid` são versionados. Sem eles, quem clonar o repositório reimporta
  tudo e as referências entre recursos deixam de funcionar.
- `Projeto/.godot/` não é versionado: é uma cache local, regenerada na primeira abertura.
- `export_presets.cfg` é versionado (presets partilhados); `export_credentials.cfg` não é, porque
  contém chaves de assinatura.
- Recursos movem-se e renomeiam-se apenas no painel FileSystem do Godot, que atualiza as
  referências e os UIDs. O explorador de ficheiros do sistema não o faz.

## Licença

Ver [LICENSE](LICENSE).
